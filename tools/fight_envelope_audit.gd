extends Node

const AuditTablePrinter = preload("res://tools/audit_table_printer.gd")

const TRIALS_PER_CASE := 80
const DELTA := 0.08
const MAX_PRE_FIGHT_SECONDS := 12.0
const MAX_FIGHT_SECONDS := 210.0

const FISH_CASES: Array[Dictionary] = [
	{"id": "nushi_probe_400", "label": "S400/P1.60", "stamina": 400.0, "power": 1.60, "speed": 1.00},
	{"id": "nushi_probe_550", "label": "S550/P1.80", "stamina": 550.0, "power": 1.80, "speed": 0.98},
	{"id": "nushi_probe_736", "label": "S736/P2.00", "stamina": 736.0, "power": 2.00, "speed": 0.95},
]
const PLAYER_LEVELS: Array[int] = [10, 30, 50]

var _failed := false


func _ready() -> void:
	var rows: Array[Array] = []
	for fish_case in FISH_CASES:
		for level_value in PLAYER_LEVELS:
			var result := _run_case(fish_case, level_value)
			rows.append(
				[
					String(fish_case["label"]),
					level_value,
					String(result["rod"]),
					int(result["wins"]),
					"%.1f%%" % float(result["win_rate"]),
					"%.1f%%" % float(result["line_break_rate"]),
					"%.1f%%" % float(result["slack_rate"]),
					"%.1f" % float(result["avg_seconds"]),
					"%.1f" % float(result["p90_seconds"]),
					int(result["timeouts"]),
				]
			)
			_check_envelope(result, String(fish_case["label"]), level_value)

	AuditTablePrinter.print_table(
		"fight_envelope_audit: nushi-class fight envelope",
		[
			"Fish",
			"Lv",
			"Rod",
			"Wins",
			"WinRate",
			"LineBreak",
			"Slack",
			"AvgSec",
			"P90Sec",
			"Timeout",
		],
		rows
	)

	if _failed:
		get_tree().quit(1)
		return
	print("fight_envelope_audit: ok")
	get_tree().quit(0)


func _run_case(fish_case: Dictionary, level_value: int) -> Dictionary:
	var wins := 0
	var line_breaks := 0
	var slack_escapes := 0
	var timeouts := 0
	var durations: Array[float] = []
	var stats := _stats_for_level(level_value)
	var fish := _fish_for_case(fish_case)
	for trial in range(TRIALS_PER_CASE):
		var result := _run_trial(fish, stats, level_value * 1000 + trial)
		if bool(result["caught"]):
			wins += 1
		elif String(result["reason"]).contains("ライン"):
			line_breaks += 1
		elif String(result["reason"]).contains("緩み"):
			slack_escapes += 1
		elif bool(result["timeout"]):
			timeouts += 1
		durations.append(float(result["seconds"]))
	durations.sort()
	return {
		"level": level_value,
		"rod": String(stats["rod_name"]),
		"wins": wins,
		"win_rate": 100.0 * float(wins) / float(TRIALS_PER_CASE),
		"line_break_rate": 100.0 * float(line_breaks) / float(TRIALS_PER_CASE),
		"slack_rate": 100.0 * float(slack_escapes) / float(TRIALS_PER_CASE),
		"timeouts": timeouts,
		"avg_seconds": _average(durations),
		"p90_seconds": durations[int(floor(float(durations.size() - 1) * 0.90))],
	}


func _run_trial(fish: Dictionary, stats: Dictionary, seed_value: int) -> Dictionary:
	var simulator := FishingSimulator.new()
	simulator.prepare(fish, stats)
	simulator._rng.seed = seed_value
	simulator.cast()

	var elapsed := 0.0
	while elapsed < MAX_PRE_FIGHT_SECONDS:
		if simulator.state == FishingSimulator.State.BITE:
			simulator.hook()
		if simulator.state == FishingSimulator.State.FIGHT:
			break
		simulator.tick(DELTA)
		elapsed += DELTA

	var fight_elapsed := 0.0
	while simulator.state == FishingSimulator.State.FIGHT and fight_elapsed < MAX_FIGHT_SECONDS:
		_apply_auto_control(simulator)
		simulator.tick(DELTA)
		fight_elapsed += DELTA

	var caught := simulator.state == FishingSimulator.State.CAUGHT
	var timeout := simulator.state == FishingSimulator.State.FIGHT
	if timeout:
		simulator.set_reeling(false)
		simulator.set_giving_line(false)
	return {
		"caught": caught,
		"timeout": timeout,
		"reason": "timeout" if timeout else String(simulator.action_message),
		"seconds": fight_elapsed,
	}


func _apply_auto_control(simulator: FishingSimulator) -> void:
	var safe_min := simulator.safe_min()
	var safe_max := simulator.safe_max()
	var break_limit := simulator.line_break_limit()
	var tension := simulator.tension
	var energy_ratio := simulator.player_energy_ratio()
	if tension >= break_limit - 0.08:
		simulator.set_giving_line(true)
		return
	if tension <= safe_min + 0.035:
		simulator.set_reeling(energy_ratio > 0.06)
		return
	if tension >= safe_max + 0.080:
		simulator.set_giving_line(true)
		return
	if energy_ratio < 0.10 and tension > safe_min + 0.080:
		simulator.set_reeling(false)
		simulator.set_giving_line(false)
		return
	if tension < safe_max + 0.030:
		simulator.set_reeling(true)
		return
	simulator.set_reeling(energy_ratio > 0.18)


func _stats_for_level(level_value: int) -> Dictionary:
	PlayerProgress.level = level_value
	PlayerProgress.equipped_rod_id = _appropriate_rod_id(level_value)
	var stats := PlayerProgress.get_base_stats()
	stats["spot_depth_range"] = [15.0, 25.0]
	return stats


func _appropriate_rod_id(level_value: int) -> String:
	if level_value >= 30:
		return "marlin"
	return "big_game"


func _fish_for_case(fish_case: Dictionary) -> Dictionary:
	return {
		"id": String(fish_case["id"]),
		"name": String(fish_case["label"]),
		"rarity": "レア",
		"boss": true,
		"size_min": 100.0,
		"size_max": 180.0,
		"stamina": float(fish_case["stamina"]),
		"power": float(fish_case["power"]),
		"speed": float(fish_case["speed"]),
		"start_distance": 48.0,
		"start_depth": 18.0,
		"motion": {"wave_amp": 0.020, "wave_freq": 2.6, "dash_shift": 0.070, "turn_shift": 0.050, "dive_shift": 0.060},
		"action_profile": {"dash": 0.42, "dive": 0.24, "turn": 0.16, "rest": 0.18},
	}


func _average(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for value in values:
		total += value
	return total / float(values.size())


func _check_envelope(result: Dictionary, fish_label: String, level_value: int) -> void:
	if level_value != 50:
		return
	var win_rate := float(result["win_rate"])
	var p90_seconds := float(result["p90_seconds"])
	_expect_true(win_rate > 0.0, "%s Lv%d should be catchable with appropriate gear" % [fish_label, level_value])
	_expect_true(p90_seconds <= 180.0, "%s Lv%d p90 fight should fit within 3 minutes" % [fish_label, level_value])


func _expect_true(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)
