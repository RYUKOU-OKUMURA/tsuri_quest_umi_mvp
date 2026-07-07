extends Node

const AuditTablePrinter = preload("res://tools/audit_table_printer.gd")

var _failed := false


func _ready() -> void:
	_check_lure_weight_tables()
	_check_lure_charges()
	_check_megalodon_gate()
	_check_megalodon_roll_route()
	_check_megalodon_metadata()
	if _failed:
		get_tree().quit(1)
		return
	print("shark_lure_audit: ok")
	get_tree().quit(0)


func _check_lure_weight_tables() -> void:
	var no_bait_weights := GameData.encounter_weights(GameData.MAX_LEVEL, "danger_reef")
	_expect(not no_bait_weights.has("shumokuzame"), "shumokuzame should not appear without bait")
	_expect(not no_bait_weights.has("hohojirozame"), "hohojirozame should not appear without bait")

	var small_bottom_bait := GameData.get_fish("mahaze")
	var small_modifiers := GameData.shark_lure_weights(small_bottom_bait)
	_expect_eq(float(small_modifiers.get("nekozame", 0.0)), 3.0, "bottom common bait should boost nekozame")
	_expect(not small_modifiers.has("shumokuzame"), "bottom common bait should not unlock shumokuzame")
	var small_weights := GameData.encounter_weights(
		GameData.MAX_LEVEL, "danger_reef", "", "", small_modifiers
	)
	_expect(not small_weights.has("shumokuzame"), "non-pelagic bait should not add shumokuzame")
	_expect(not small_weights.has("hohojirozame"), "cheap bait should not add hohojirozame")

	var pelagic_bait := GameData.get_fish("buri")
	var pelagic_modifiers := GameData.shark_lure_weights(pelagic_bait)
	_expect_eq(float(pelagic_modifiers.get("shumokuzame", 0.0)), 3.0, "bird swarm bait should boost shumokuzame")
	_expect_eq(float(pelagic_modifiers.get("hohojirozame", 0.0)), 3.0, "large bait should boost hohojirozame")
	var pelagic_weights := GameData.encounter_weights(
		GameData.MAX_LEVEL, "danger_reef", "", "", pelagic_modifiers
	)
	_expect(float(pelagic_weights.get("shumokuzame", 0.0)) > 0.0, "pelagic bait should add shumokuzame")
	_expect(float(pelagic_weights.get("hohojirozame", 0.0)) > 0.0, "large bait should add hohojirozame")

	AuditTablePrinter.print_table(
		"shark_lure_audit: danger_reef lure comparison",
		["Case", "Nekozame", "Shumoku", "Hohojiro", "Total"],
		[
			[
				"none",
				"%.2f" % float(no_bait_weights.get("nekozame", 0.0)),
				"%.2f" % float(no_bait_weights.get("shumokuzame", 0.0)),
				"%.2f" % float(no_bait_weights.get("hohojirozame", 0.0)),
				"%.2f" % _total_weight(no_bait_weights),
			],
			[
				"mahaze",
				"%.2f" % float(small_weights.get("nekozame", 0.0)),
				"%.2f" % float(small_weights.get("shumokuzame", 0.0)),
				"%.2f" % float(small_weights.get("hohojirozame", 0.0)),
				"%.2f" % _total_weight(small_weights),
			],
			[
				"buri",
				"%.2f" % float(pelagic_weights.get("nekozame", 0.0)),
				"%.2f" % float(pelagic_weights.get("shumokuzame", 0.0)),
				"%.2f" % float(pelagic_weights.get("hohojirozame", 0.0)),
				"%.2f" % _total_weight(pelagic_weights),
			],
		]
		)


func _check_lure_charges() -> void:
	_expect_eq(GameData.shark_lure_charges_for({}), 0, "empty bait should have no shark lure charges")
	_expect_eq(
		GameData.shark_lure_charges_for(GameData.get_fish("nekozame")),
		0,
		"shark bait should have no shark lure charges"
	)
	_expect_eq(
		GameData.shark_lure_charges_for(GameData.get_fish("aji")),
		1,
		"common bait should have 1 shark lure charge"
	)
	_expect_eq(
		GameData.shark_lure_charges_for(GameData.get_fish("kaiwari")),
		2,
		"uncommon bait should have 2 shark lure charges"
	)
	_expect_eq(
		GameData.shark_lure_charges_for(GameData.get_fish("kihada")),
		3,
		"rare bait should have 3 shark lure charges"
	)
	_expect_eq(
		GameData.shark_lure_charges_for(GameData.get_fish("boss_kurodai")),
		5,
		"rarity nushi bait should have 5 shark lure charges"
	)
	_expect_eq(
		GameData.shark_lure_charges_for(GameData.get_fish("nushi_deep_ocean")),
		5,
		"nushi flag bait should have 5 shark lure charges"
	)


func _check_megalodon_gate() -> void:
	var unlocked_bonds := _complete_shark_bonds()
	var incomplete_bonds := _complete_shark_bonds()
	incomplete_bonds["nekozame"] = 99
	var nushi_bait := GameData.get_fish("nushi_deep_ocean")
	var high_value_bait := GameData.get_fish("kihada")
	var cheap_bait := GameData.get_fish("mahaze")
	_expect(
		GameData.can_encounter_megalodon(GameData.MAX_LEVEL, "danger_reef", unlocked_bonds, nushi_bait),
		"megalodon should be eligible with Lv50, all bonds, and non-shark nushi bait"
	)
	_expect(
		GameData.can_encounter_megalodon(GameData.MAX_LEVEL, "danger_reef", unlocked_bonds, high_value_bait),
		"megalodon should be eligible with high-value non-shark bait"
	)
	_expect(
		not GameData.can_encounter_megalodon(49, "danger_reef", unlocked_bonds, nushi_bait),
		"megalodon should require Lv50"
	)
	_expect(
		not GameData.can_encounter_megalodon(GameData.MAX_LEVEL, "danger_reef", incomplete_bonds, nushi_bait),
		"megalodon should require all normal shark bonds"
	)
	_expect(
		not GameData.can_encounter_megalodon(GameData.MAX_LEVEL, "deep_ocean", unlocked_bonds, nushi_bait),
		"megalodon should require danger_reef"
	)
	_expect(
		not GameData.can_encounter_megalodon(GameData.MAX_LEVEL, "danger_reef", unlocked_bonds, cheap_bait),
		"megalodon should require nushi-grade bait"
	)
	var hit_plan := GameData.megalodon_encounter_plan(
		0.0, GameData.MAX_LEVEL, "danger_reef", unlocked_bonds, nushi_bait
	)
	var miss_plan := GameData.megalodon_encounter_plan(
		0.5, GameData.MAX_LEVEL, "danger_reef", unlocked_bonds, nushi_bait
	)
	_expect(bool(hit_plan.get("eligible", false)), "eligible megalodon plan should report eligible")
	_expect(bool(hit_plan.get("active", false)), "low random roll should trigger megalodon")
	_expect(not bool(miss_plan.get("active", false)), "high random roll should miss megalodon chance")
	_expect_eq(float(hit_plan.get("chance", 0.0)), GameData.MEGALODON_ENCOUNTER_CHANCE, "megalodon chance mismatch")


func _check_megalodon_roll_route() -> void:
	var unlocked_bonds := _complete_shark_bonds()
	var nushi_bait := GameData.get_fish("nushi_deep_ocean")
	var cheap_bait := GameData.get_fish("mahaze")
	var eligible_hits := 0
	for seed in range(1, 1001):
		GameData._rng.seed = seed
		var rolled := GameData.roll_hooked_fish(
			GameData.MAX_LEVEL, "danger_reef", "", "", "", {}, unlocked_bonds, nushi_bait
		)
		if String(rolled.get("id", "")) == "megalodon":
			eligible_hits += 1
	_expect(eligible_hits > 0, "eligible roll route should be able to hook megalodon")

	for seed in range(1, 201):
		GameData._rng.seed = seed
		var low_level_roll := GameData.roll_hooked_fish(
			49, "danger_reef", "", "", "", {}, unlocked_bonds, nushi_bait
		)
		_expect(
			String(low_level_roll.get("id", "")) != "megalodon",
			"low level roll route should not hook megalodon"
		)
		GameData._rng.seed = seed
		var cheap_bait_roll := GameData.roll_hooked_fish(
			GameData.MAX_LEVEL, "danger_reef", "", "", "", {}, unlocked_bonds, cheap_bait
		)
		_expect(
			String(cheap_bait_roll.get("id", "")) != "megalodon",
			"cheap bait roll route should not hook megalodon"
		)


func _check_megalodon_metadata() -> void:
	var megalodon := GameData.get_fish("megalodon")
	_expect(not megalodon.is_empty(), "megalodon fish data should exist")
	_expect(bool(megalodon.get("shark", false)), "megalodon should be a shark")
	_expect(bool(megalodon.get("boss", false)), "megalodon should be boss fish")
	_expect(not GameData.can_shark_ambush("danger_reef", megalodon), "megalodon should not allow ambush")
	var reward := GameData.get_boss_first_clear_reward("megalodon")
	_expect_eq(int(reward.get("money", 0)), 10000, "megalodon first clear reward should be 10000G")


func _complete_shark_bonds() -> Dictionary:
	var bonds: Dictionary = {}
	for shark_id in GameData.get_normal_shark_ids():
		bonds[shark_id] = 100
	return bonds


func _total_weight(weights: Dictionary) -> float:
	var total := 0.0
	for fish_id in weights.keys():
		total += float(weights[fish_id])
	return total


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)


func _expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	_expect(actual == expected, "%s: expected %s, got %s" % [message, str(expected), str(actual)])
