extends Node

const FishingSimulatorScript = preload("res://src/core/fishing_simulator.gd")
const FightHudScript = preload("res://src/ui/components/fight_hud.gd")

var _failed := false


func _ready() -> void:
	var fish: Dictionary = GameData.get_fish("isaki")
	var stats := {
		"max_energy": 100.0,
		"reel_power": 5.6,
		"energy_regen": 14.0,
		"bite_window_bonus": 0.0,
		"safe_min": 0.22,
		"safe_max": 0.72,
		"line_break_limit": 1.0,
		"rod_name": "港の入門竿",
	}

	_verify_reveal_only_after_hook(fish, stats)
	_verify_bite_escape_stays_unknown(fish, stats)
	_verify_shark_lure_messages_stay_unknown(fish, stats)
	_verify_shark_lure_hud_text()
	if _failed:
		return
	print("fishing_reveal_smoke: ok")
	get_tree().quit(0)


func _verify_reveal_only_after_hook(fish: Dictionary, stats: Dictionary) -> void:
	var simulator: FishingSimulator = FishingSimulatorScript.new()
	simulator.prepare(fish, stats)
	_expect(not simulator.fish_revealed, "prepare must keep fish unrevealed")
	_expect(simulator.state == FishingSimulator.State.READY, "prepare must start at READY")

	_expect(simulator.cast(), "cast should start the attempt")
	_expect(not simulator.fish_revealed, "cast must keep fish unrevealed")
	_advance_until_bite(simulator)
	_expect(simulator.state == FishingSimulator.State.BITE, "attempt should reach BITE")
	_expect(not simulator.fish_revealed, "BITE must keep fish unrevealed")

	_expect(simulator.hook(), "hook should enter FIGHT")
	_expect(simulator.state == FishingSimulator.State.FIGHT, "hook must set state to FIGHT")
	_expect(simulator.fish_revealed, "hook must reveal the fish")


func _verify_bite_escape_stays_unknown(fish: Dictionary, stats: Dictionary) -> void:
	var simulator: FishingSimulator = FishingSimulatorScript.new()
	simulator.prepare(fish, stats)
	_expect(simulator.cast(), "cast should start the escape attempt")
	_advance_until_bite(simulator)
	_expect(not simulator.fish_revealed, "BITE must be unrevealed before timeout")

	simulator.tick(simulator.bite_time_left() + 0.2)
	_expect(simulator.state == FishingSimulator.State.ESCAPED, "bite timeout should escape")
	_expect(not simulator.fish_revealed, "BITE escape must not reveal the fish")


func _verify_shark_lure_messages_stay_unknown(fish: Dictionary, stats: Dictionary) -> void:
	var lure_stats := stats.duplicate(true)
	lure_stats["spot_id"] = "danger_reef"
	lure_stats["shark_lure_fish_id"] = "aji"
	lure_stats["shark_lure_fish_name"] = "マアジ"
	var simulator: FishingSimulator = FishingSimulatorScript.new()
	simulator.prepare(fish, lure_stats)
	_expect(simulator.cast(), "cast should start the lure attempt")
	_advance_until_state(simulator, FishingSimulator.State.APPROACH)
	_expect(simulator.state == FishingSimulator.State.APPROACH, "lure attempt should reach APPROACH")
	_expect(
		simulator.action_message.contains("餌のマアジ"),
		"APPROACH message should name the bait fish"
	)
	_expect(not simulator.action_message.contains(String(fish.get("name", ""))), "APPROACH message must not reveal hooked fish")
	_advance_until_state(simulator, FishingSimulator.State.BITE)
	_expect(simulator.state == FishingSimulator.State.BITE, "lure attempt should reach BITE")
	_expect(
		simulator.action_message.contains("マアジに何かが食いついた"),
		"BITE message should make bait fish the subject"
	)
	_expect(not simulator.fish_revealed, "lure BITE must keep fish unrevealed")
	_expect(not simulator.action_message.contains(String(fish.get("name", ""))), "BITE message must not reveal hooked fish")


func _verify_shark_lure_hud_text() -> void:
	var hud: FightHud = FightHudScript.new()
	hud.trip_stats = {
		"spot_id": "danger_reef",
		"shark_lure_fish_id": "aji",
		"shark_lure_fish_name": "マアジ",
		"rig_bait_types": ["小魚"],
	}
	_expect(hud._rig_bait_text() == "餌魚：マアジ", "danger reef lure HUD should show bait fish name")
	hud.trip_stats["spot_id"] = "harbor_pier"
	_expect(hud._rig_bait_text() == "対応餌：小魚", "non-danger spot should keep rig bait category")
	hud.free()


func _advance_until_bite(simulator: FishingSimulator) -> void:
	_advance_until_state(simulator, FishingSimulator.State.BITE)


func _advance_until_state(simulator: FishingSimulator, target_state: int) -> void:
	for _index in range(90):
		simulator.tick(0.10)
		if simulator.state == target_state:
			return
	_expect(false, "simulator did not reach state %d" % target_state)


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
