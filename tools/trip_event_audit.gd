extends Node

const AuditTablePrinter = preload("res://tools/audit_table_printer.gd")

const ROLL_TRIALS := 100000
const DISTRIBUTION_TOLERANCE := 0.005

const EXPECTED_TRIP_EVENT_WEIGHTS: Dictionary = {
	"none": 0.86,
	"bird_swarm": 0.06,
	"driftwood": 0.05,
	"bottle_mail": 0.03,
}

const EXPECTED_DRIFTWOOD_WEIGHTS: Dictionary = {
	"miss": 0.50,
	"small_loot": 0.45,
	"treasure": 0.05,
}

const EXCLUDED_EVENT_IDS: Array[String] = ["bird_swarm", "driftwood", "bottle_mail"]
const BIRD_SWARM_SPOT_ID := "bluewater_route"
const BIRD_SWARM_SAMPLE_FISH := "iwashi"
const BIRD_SWARM_CONTROL_FISH := "aji"
const BIRD_SWARM_MULTIPLIER := 2.5

var _failed := false


func _ready() -> void:
	GameData._rng.seed = 20260706
	_check_static_trip_event_table()
	_check_trip_event_distribution()
	_check_excluded_trip_events()
	_check_driftwood_distribution()
	_check_bird_swarm_weight_modifiers()
	_check_sea_chart_fragments()

	if _failed:
		get_tree().quit(1)
		return
	print("trip_event_audit: ok")
	get_tree().quit(0)


func _check_static_trip_event_table() -> void:
	var table := GameData.trip_event_table()
	var rows: Array[Array] = []
	var total_weight := 0.0
	for event in table:
		var event_id := String(event.get("id", ""))
		var weight := float(event.get("weight", 0.0))
		total_weight += weight
		var expected := float(EXPECTED_TRIP_EVENT_WEIGHTS.get(event_id, -1.0))
		var status := "PASS" if is_equal_approx(weight, expected) else "FAIL"
		if status == "FAIL":
			_expect_true(false, "trip_event_table weight mismatch for %s" % event_id)
		rows.append([event_id, weight, expected, status])
	rows.append(["TOTAL", total_weight, 1.0, "PASS" if is_equal_approx(total_weight, 1.0) else "FAIL"])
	_expect_true(is_equal_approx(total_weight, 1.0), "trip_event_table total weight should be 1.0")
	AuditTablePrinter.print_table(
		"trip_event_audit: static trip event weights",
		["EventID", "Weight", "Expected", "Status"],
		rows
	)


func _check_trip_event_distribution() -> void:
	var counts := _count_trip_events([])
	var rows: Array[Array] = []
	for event_id in ["none", "bird_swarm", "driftwood", "bottle_mail"]:
		var expected_rate := float(EXPECTED_TRIP_EVENT_WEIGHTS[event_id])
		var actual_rate := float(counts.get(event_id, 0)) / float(ROLL_TRIALS)
		var delta := absf(actual_rate - expected_rate)
		var status := "PASS" if delta <= DISTRIBUTION_TOLERANCE else "FAIL"
		if status == "FAIL":
			_expect_true(
				false,
				"trip event distribution %s rate %.4f expected %.4f tolerance %.4f"
				% [event_id, actual_rate, expected_rate, DISTRIBUTION_TOLERANCE]
			)
		rows.append(
			[
				event_id,
				counts.get(event_id, 0),
				expected_rate,
				actual_rate,
				delta,
				DISTRIBUTION_TOLERANCE,
				status,
			]
		)
	AuditTablePrinter.print_table(
		"trip_event_audit: roll_trip_event([]) distribution (%d trials, tolerance ±%.3f)"
		% [ROLL_TRIALS, DISTRIBUTION_TOLERANCE],
		["EventID", "Hits", "Expected", "Actual", "Delta", "Tolerance", "Status"],
		rows
	)


func _check_excluded_trip_events() -> void:
	var counts := _count_trip_events(EXCLUDED_EVENT_IDS)
	var none_hits := int(counts.get("none", 0))
	var non_none_hits := ROLL_TRIALS - none_hits
	var redirected_weight := 0.0
	for event_id in EXCLUDED_EVENT_IDS:
		redirected_weight += float(EXPECTED_TRIP_EVENT_WEIGHTS[event_id])
	var expected_none_rate := float(EXPECTED_TRIP_EVENT_WEIGHTS["none"]) + redirected_weight
	var actual_none_rate := float(none_hits) / float(ROLL_TRIALS)

	var rows: Array[Array] = [
		[
			"none",
			none_hits,
			expected_none_rate,
			actual_none_rate,
			"PASS" if non_none_hits == 0 else "FAIL",
		],
		[
			"non-none",
			non_none_hits,
			0.0,
			float(non_none_hits) / float(ROLL_TRIALS),
			"PASS" if non_none_hits == 0 else "FAIL",
		],
		[
			"redirected_weight",
			redirected_weight,
			0.14,
			redirected_weight,
			"PASS" if is_equal_approx(redirected_weight, 0.14) else "FAIL",
		],
	]
	_expect_eq(non_none_hits, 0, "excluded trip events should always roll none")
	_expect_true(
		is_equal_approx(expected_none_rate, 1.0),
		"excluded weights should redirect all mass to none"
	)
	AuditTablePrinter.print_table(
		"trip_event_audit: excluded events redirect to none (%d trials)"
		% ROLL_TRIALS,
		["Metric", "Hits", "ExpectedRate", "ActualRate", "Status"],
		rows
	)


func _check_driftwood_distribution() -> void:
	var counts: Dictionary = {}
	for _index in range(ROLL_TRIALS):
		var outcome := GameData.roll_driftwood_outcome()
		var outcome_id := String(outcome.get("id", ""))
		counts[outcome_id] = int(counts.get(outcome_id, 0)) + 1

	var rows: Array[Array] = []
	for outcome_id in ["miss", "small_loot", "treasure"]:
		var expected_rate := float(EXPECTED_DRIFTWOOD_WEIGHTS[outcome_id])
		var actual_rate := float(counts.get(outcome_id, 0)) / float(ROLL_TRIALS)
		var delta := absf(actual_rate - expected_rate)
		var status := "PASS" if delta <= DISTRIBUTION_TOLERANCE else "FAIL"
		if status == "FAIL":
			_expect_true(
				false,
				"driftwood outcome %s rate %.4f expected %.4f tolerance %.4f"
				% [outcome_id, actual_rate, expected_rate, DISTRIBUTION_TOLERANCE]
			)
		rows.append(
			[
				outcome_id,
				counts.get(outcome_id, 0),
				expected_rate,
				actual_rate,
				delta,
				DISTRIBUTION_TOLERANCE,
				status,
			]
		)
	AuditTablePrinter.print_table(
		"trip_event_audit: roll_driftwood_outcome() distribution (%d trials, tolerance ±%.3f)"
		% [ROLL_TRIALS, DISTRIBUTION_TOLERANCE],
		["OutcomeID", "Hits", "Expected", "Actual", "Delta", "Tolerance", "Status"],
		rows
	)


func _check_bird_swarm_weight_modifiers() -> void:
	var player_level := GameData.MAX_LEVEL
	var base_weights := GameData.encounter_weights(player_level, BIRD_SWARM_SPOT_ID)
	var boosted_weights := GameData.encounter_weights(
		player_level,
		BIRD_SWARM_SPOT_ID,
		"",
		"",
		GameData.bird_swarm_fish_weight_modifiers()
	)
	var sample_base := float(base_weights.get(BIRD_SWARM_SAMPLE_FISH, 0.0))
	var sample_boosted := float(boosted_weights.get(BIRD_SWARM_SAMPLE_FISH, 0.0))
	var sample_ratio := sample_boosted / sample_base if sample_base > 0.0 else 0.0
	var control_base := float(base_weights.get(BIRD_SWARM_CONTROL_FISH, 0.0))
	var control_boosted := float(boosted_weights.get(BIRD_SWARM_CONTROL_FISH, 0.0))
	var control_ratio := control_boosted / control_base if control_base > 0.0 else 0.0

	var rows: Array[Array] = []
	for fish_id in GameData.BIRD_SWARM_FISH_IDS:
		var before := float(base_weights.get(fish_id, 0.0))
		var after := float(boosted_weights.get(fish_id, 0.0))
		if before <= 0.0:
			continue
		var ratio := after / before
		var status := "PASS" if is_equal_approx(ratio, BIRD_SWARM_MULTIPLIER) else "FAIL"
		if status == "FAIL":
			_expect_true(false, "bird swarm modifier ratio mismatch for %s" % fish_id)
		rows.append([fish_id, before, after, ratio, BIRD_SWARM_MULTIPLIER, status])

	var control_status := "PASS" if is_equal_approx(control_ratio, 1.0) else "FAIL"
	if control_status == "FAIL":
		_expect_true(false, "bird swarm modifier should not affect control fish %s" % BIRD_SWARM_CONTROL_FISH)
	rows.append(
		[
			BIRD_SWARM_CONTROL_FISH,
			control_base,
			control_boosted,
			control_ratio,
			1.0,
			control_status,
		]
	)
	_expect_true(sample_base > 0.0, "%s should appear at %s" % [BIRD_SWARM_SAMPLE_FISH, BIRD_SWARM_SPOT_ID])
	_expect_true(
		is_equal_approx(sample_ratio, BIRD_SWARM_MULTIPLIER),
		"sample fish weight should be x%.1f" % BIRD_SWARM_MULTIPLIER
	)
	AuditTablePrinter.print_table(
		"trip_event_audit: bird_swarm encounter weight modifiers (%s)"
		% BIRD_SWARM_SPOT_ID,
		["FishID", "BaseWeight", "BoostedWeight", "Ratio", "ExpectedRatio", "Status"],
		rows
	)


func _check_sea_chart_fragments() -> void:
	_expect_true(PlayerProgress.is_sandbox_mode(), "trip_event_audit should run in sandbox mode")
	PlayerProgress.sea_chart_fragments = 0
	var rows: Array[Array] = []
	var expected_values: Array[int] = [1, 2, 3, 3]
	for call_index in range(expected_values.size()):
		var before := PlayerProgress.sea_chart_fragments
		var gained := PlayerProgress.add_sea_chart_fragments(1)
		var after := PlayerProgress.sea_chart_fragments
		var expected := expected_values[call_index]
		var status := "PASS" if after == expected and gained == expected - before else "FAIL"
		if status == "FAIL":
			_expect_true(
				false,
				"sea_chart_fragments call %d got=%d expected=%d" % [call_index + 1, after, expected]
			)
		rows.append([call_index + 1, before, gained, after, expected, status])
	AuditTablePrinter.print_table(
		"trip_event_audit: sea_chart_fragments progression (sandbox)",
		["Call", "Before", "Gained", "After", "Expected", "Status"],
		rows
	)


func _count_trip_events(already_fired: Array[String]) -> Dictionary:
	var counts: Dictionary = {}
	for _index in range(ROLL_TRIALS):
		var event := GameData.roll_trip_event(already_fired)
		var event_id := String(event.get("id", ""))
		counts[event_id] = int(counts.get(event_id, 0)) + 1
	return counts


func _expect_true(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)


func _expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	_expect_true(actual == expected, "%s got=%s expected=%s" % [message, str(actual), str(expected)])
