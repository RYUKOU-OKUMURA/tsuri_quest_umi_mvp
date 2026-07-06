extends Node

const AuditTablePrinter = preload("res://tools/audit_table_printer.gd")

const EXPECTED_EXP_REQUIREMENTS: Array[int] = [
	0,
	60,
	85,
	115,
	150,
	190,
	235,
	285,
	340,
	400,
	460,
	520,
	580,
	640,
	700,
	770,
	840,
	910,
	980,
	1050,
	1130,
	1210,
	1290,
	1370,
	1450,
	1540,
	1630,
	1720,
	1810,
	1900,
	2000,
	2100,
	2200,
	2300,
	2400,
	2500,
	2600,
	2700,
	2800,
	2900,
	3050,
	3200,
	3350,
	3500,
	3650,
	3800,
	3950,
	4100,
	4250,
	4400,
	0,
]

var _failed := false


func _ready() -> void:
	_check_level_constants()
	_check_legacy_level_stats()
	_check_growth_soft_caps()
	_print_level_curve()

	if _failed:
		get_tree().quit(1)
		return
	print("level_curve_audit: ok")
	get_tree().quit(0)


func _check_level_constants() -> void:
	_expect_eq(GameData.MAX_LEVEL, 50, "MAX_LEVEL")
	_expect_eq(PlayerProgress.EXP_REQUIREMENTS.size(), GameData.MAX_LEVEL + 1, "EXP table size")
	for index in range(EXPECTED_EXP_REQUIREMENTS.size()):
		_expect_eq(
			PlayerProgress.EXP_REQUIREMENTS[index],
			EXPECTED_EXP_REQUIREMENTS[index],
			"EXP_REQUIREMENTS[%d]" % index
		)
	_expect_eq(PlayerProgress.EXP_REQUIREMENTS[GameData.MAX_LEVEL], 0, "MAX level next EXP")


func _check_legacy_level_stats() -> void:
	for level_value in range(1, 11):
		var actual := _stats_for_level(level_value)
		var expected := _legacy_stats_for_level(level_value)
		for key in [
			"max_energy",
			"reel_power",
			"technique",
			"focus",
			"energy_regen",
			"bite_window_bonus",
			"safe_min",
			"safe_max",
			"line_break_limit",
		]:
			_expect_eq(actual[key], expected[key], "Lv%d %s legacy parity" % [level_value, key])


func _check_growth_soft_caps() -> void:
	_expect_eq(_growth_for_level(10), 9.0, "Lv10 growth")
	_expect_eq(_growth_for_level(30), 16.0, "Lv30 growth")
	_expect_eq(_growth_for_level(50), 18.0, "Lv50 growth")
	var level_30 := _stats_for_level(30)
	var level_50 := _stats_for_level(50)
	_expect_eq(float(level_30["max_energy"]), 180.0, "Lv30 max_energy")
	_expect_eq(float(level_50["max_energy"]), 190.0, "Lv50 max_energy")
	_expect_true(
		float(level_50["reel_power"]) < float(level_30["reel_power"]) * 1.08,
		"Lv50 reel_power should stay near Lv30"
	)


func _print_level_curve() -> void:
	var rows: Array[Array] = []
	var total_exp := 0
	for level_value in range(1, GameData.MAX_LEVEL + 1):
		var stats := _stats_for_level(level_value)
		rows.append(
			[
				level_value,
				PlayerProgress.EXP_REQUIREMENTS[level_value],
				total_exp,
				_growth_for_level(level_value),
				stats["max_energy"],
				stats["reel_power"],
				stats["technique"],
				stats["focus"],
				stats["energy_regen"],
				stats["bite_window_bonus"],
				stats["safe_min"],
				stats["safe_max"],
				stats["line_break_limit"],
				stats["rod_name"],
			]
		)
		total_exp += PlayerProgress.EXP_REQUIREMENTS[level_value]
	AuditTablePrinter.print_table(
		"level_curve_audit: Lv1-50 EXP and base stats",
		[
			"Lv",
			"NextEXP",
			"TotalEXP",
			"Growth",
			"MaxEnergy",
			"ReelPower",
			"Technique",
			"Focus",
			"Regen",
			"BiteBonus",
			"SafeMin",
			"SafeMax",
			"LineLimit",
			"Rod",
		],
		rows
	)


func _stats_for_level(level_value: int) -> Dictionary:
	PlayerProgress.level = level_value
	PlayerProgress.equipped_rod_id = "starter"
	return PlayerProgress.get_base_stats()


func _growth_for_level(level_value: int) -> float:
	PlayerProgress.level = level_value
	return PlayerProgress.growth_points()


func _legacy_stats_for_level(level_value: int) -> Dictionary:
	var rod := GameData.get_rod("starter")
	var technique_points := (level_value - 1) + int(rod.get("technique_bonus", 0))
	return {
		"max_energy": 100.0 + float(level_value - 1) * 5.0,
		"reel_power": (5.6 + float(level_value - 1) * 0.58)
		* float(rod.get("reel_multiplier", 1.0)),
		"technique": technique_points,
		"focus": level_value - 1,
		"energy_regen": 14.0 + float(level_value - 1) * 0.45,
		"bite_window_bonus": float(level_value - 1) * 0.025,
		"safe_min": maxf(0.10, 0.22 - float(technique_points) * 0.007),
		"safe_max": minf(0.88, 0.72 + float(technique_points) * 0.010),
		"line_break_limit": 1.0 + float(rod.get("line_limit_bonus", 0.0)),
	}


func _expect_true(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)


func _expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	_expect_true(actual == expected, "%s got=%s expected=%s" % [message, str(actual), str(expected)])
