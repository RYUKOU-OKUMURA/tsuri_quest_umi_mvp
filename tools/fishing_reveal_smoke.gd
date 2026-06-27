extends Node

const FishingSimulatorScript = preload("res://src/core/fishing_simulator.gd")

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


func _advance_until_bite(simulator: FishingSimulator) -> void:
	for _index in range(90):
		simulator.tick(0.10)
		if simulator.state == FishingSimulator.State.BITE:
			return
	_expect(false, "simulator did not reach BITE")


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
