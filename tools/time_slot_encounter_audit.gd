extends Node

const AuditTablePrinter = preload("res://tools/audit_table_printer.gd")

var _failed := false


func _ready() -> void:
	var rows: Array[Array] = []
	_check_catalog()
	_check_direct_modifiers(rows)
	_check_encounter_weight_ratios(rows)
	AuditTablePrinter.print_table(
		"time_slot_encounter_audit: time slot modifiers",
		["Case", "Fish", "Spot", "Expected", "Actual"],
		rows
	)
	if _failed:
		get_tree().quit(1)
		return
	print("time_slot_encounter_audit: ok")
	get_tree().quit(0)


func _check_catalog() -> void:
	_expect_eq(GameData.get_all_time_slot_ids(), ["asa_mazume", "daytime", "night"], "time slot order")
	_expect_eq(String(GameData.get_time_slot("").get("id", "")), GameData.DEFAULT_TIME_SLOT_ID, "empty slot fallback")
	_expect(GameData.is_time_slot_unlocked("daytime", 1), "daytime should be unlocked at Lv1")
	_expect(not GameData.is_time_slot_unlocked("asa_mazume", 11), "asa_mazume should require Lv12")
	_expect(GameData.is_time_slot_unlocked("asa_mazume", 12), "asa_mazume should unlock at Lv12")
	_expect(not GameData.is_time_slot_unlocked("night", 14), "night should require Lv15")
	_expect(GameData.is_time_slot_unlocked("night", 15), "night should unlock at Lv15")


func _check_direct_modifiers(rows: Array[Array]) -> void:
	_expect_modifier(rows, "daytime", "aji", "", 1.0)
	_expect_modifier(rows, "asa_mazume", "aji", "", 1.30)
	_expect_modifier(rows, "asa_mazume", "kaiwari", "", 1.12)
	_expect_modifier(rows, "asa_mazume", "kihada", "", 1.30)
	_expect_modifier(rows, "night", "tachiuo", "", 2.20)
	_expect_modifier(rows, "night", "kinmedai", "", 1.60)


func _check_encounter_weight_ratios(rows: Array[Array]) -> void:
	_expect_weight_ratio(rows, "asa_mazume", "aji", 1.30)
	_expect_weight_ratio(rows, "asa_mazume", "kaiwari", 1.12)
	_expect_weight_ratio(rows, "night", "tachiuo", 2.20)
	_expect_weight_ratio(rows, "night", "kinmedai", 1.60)


func _expect_modifier(
	rows: Array[Array],
	time_slot_id: String,
	fish_id: String,
	spot_id: String,
	expected: float
) -> void:
	var actual := GameData.fishing_time_slot_fish_modifier(time_slot_id, fish_id)
	rows.append([time_slot_id, fish_id, spot_id, "%.2f" % expected, "%.2f" % actual])
	_expect_approx(actual, expected, "%s %s modifier" % [time_slot_id, fish_id])


func _expect_weight_ratio(
	rows: Array[Array],
	time_slot_id: String,
	fish_id: String,
	expected: float
) -> void:
	var spot_id := _first_spot_for_fish(fish_id)
	_expect(not spot_id.is_empty(), "%s should be allowed by a normal spot" % fish_id)
	if spot_id.is_empty():
		return
	var base_weights := GameData.encounter_weights(
		GameData.MAX_LEVEL, spot_id, "", "", {}, GameData.DEFAULT_TIME_SLOT_ID
	)
	var slot_weights := GameData.encounter_weights(
		GameData.MAX_LEVEL, spot_id, "", "", {}, time_slot_id
	)
	var base := float(base_weights.get(fish_id, 0.0))
	var actual := 0.0 if base <= 0.0 else float(slot_weights.get(fish_id, 0.0)) / base
	rows.append([time_slot_id, fish_id, spot_id, "%.2f" % expected, "%.2f" % actual])
	_expect_approx(actual, expected, "%s %s encounter ratio" % [time_slot_id, fish_id])


func _first_spot_for_fish(fish_id: String) -> String:
	for spot_id in GameData.NORMAL_FISHING_SPOT_IDS:
		var spot := GameData.get_fishing_spot(spot_id)
		var allowed: Array = spot.get("allowed_fish", [])
		if allowed.has(fish_id):
			return spot_id
	return ""


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)


func _expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	_expect(actual == expected, "%s got=%s expected=%s" % [message, str(actual), str(expected)])


func _expect_approx(actual: float, expected: float, message: String) -> void:
	_expect(absf(actual - expected) <= 0.01, "%s got=%.3f expected=%.3f" % [message, actual, expected])
