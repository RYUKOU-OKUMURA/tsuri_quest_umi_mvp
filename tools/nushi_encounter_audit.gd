extends Node

const AuditTablePrinter = preload("res://tools/audit_table_printer.gd")

const ROLL_TRIALS := 5000
const WRONG_CONDITION_TRIALS := 300

var _failed := false


func _ready() -> void:
	GameData._rng.seed = 20260706
	var rows: Array[Array] = []
	var audited_spot_ids: Array[String] = GameData.NORMAL_FISHING_SPOT_IDS.duplicate()
	audited_spot_ids.append("danger_reef")
	for spot_id in audited_spot_ids:
		var spot := GameData.get_fishing_spot(spot_id)
		var nushi: Dictionary = spot.get("nushi", {})
		_expect_true(not nushi.is_empty(), "%s should define nushi section" % spot_id)
		if nushi.is_empty():
			continue
		var fish_id := String(nushi["fish_id"])
		var env_id := String(nushi["environment_id"])
		var rig_id := String(nushi["rig_id"])
		var fish := GameData.get_fish(fish_id)
		_expect_true(not fish.is_empty(), "%s should resolve nushi fish" % fish_id)
		_expect_true(bool(fish.get("nushi", false)), "%s should be marked nushi" % fish_id)
		_expect_eq(String(fish.get("base_fish_id", "")) != "", true, "%s should have base_fish_id" % fish_id)
		_expect_eq(GameData.get_all_fish_ids().has(fish_id), false, "%s should stay out of normal fish list" % fish_id)

		var candidate := GameData.nushi_candidate(spot_id, env_id, rig_id, "", GameData.MAX_LEVEL)
		_expect_eq(String(candidate.get("id", "")), fish_id, "%s matching candidate" % spot_id)
		_expect_true(
			GameData.nushi_candidate(spot_id, "sunny_calm", rig_id, "", GameData.MAX_LEVEL).is_empty()
			or env_id == "sunny_calm",
			"%s wrong environment should block nushi" % spot_id
		)
		_expect_true(
			GameData.nushi_candidate(spot_id, env_id, "sabiki", "", GameData.MAX_LEVEL).is_empty()
			or rig_id == "sabiki",
			"%s wrong rig should block nushi" % spot_id
		)
		_expect_true(
			GameData.nushi_candidate(spot_id, env_id, rig_id, "", int(fish.get("min_level", 1)) - 1).is_empty(),
			"%s low level should block nushi" % spot_id
		)

		var hits := _roll_hits(spot_id, env_id, rig_id, fish_id, ROLL_TRIALS)
		var rate := 100.0 * float(hits) / float(ROLL_TRIALS)
		var wrong_hits := _roll_hits(spot_id, "sunny_calm", rig_id, fish_id, WRONG_CONDITION_TRIALS)
		if env_id == "sunny_calm":
			wrong_hits = _roll_hits(spot_id, env_id, "sabiki", fish_id, WRONG_CONDITION_TRIALS)
		rows.append([spot_id, fish_id, env_id, rig_id, hits, "%.2f%%" % rate, wrong_hits])
		_expect_true(rate >= 3.0 and rate <= 5.2, "%s nushi rate out of range: %.2f%%" % [spot_id, rate])
		_expect_eq(wrong_hits, 0, "%s wrong condition nushi hits" % spot_id)

	AuditTablePrinter.print_table(
		"nushi_encounter_audit: condition-gated nushi rate",
		["Spot", "Nushi", "Env", "Rig", "Hits", "Rate", "WrongHits"],
		rows
	)
	if _failed:
		get_tree().quit(1)
		return
	print("nushi_encounter_audit: ok")
	get_tree().quit(0)


func _roll_hits(spot_id: String, env_id: String, rig_id: String, fish_id: String, trials: int) -> int:
	var hits := 0
	for _index in range(trials):
		var rolled := GameData.roll_hooked_fish(GameData.MAX_LEVEL, spot_id, rig_id, env_id, "")
		if String(rolled.get("id", "")) == fish_id:
			hits += 1
	return hits


func _expect_true(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)


func _expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	_expect_true(actual == expected, "%s got=%s expected=%s" % [message, str(actual), str(expected)])
