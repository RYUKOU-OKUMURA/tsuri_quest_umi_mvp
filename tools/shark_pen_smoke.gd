extends Node

var _failed := false


func _ready() -> void:
	_verify_shark_catch_goes_to_pen()
	_verify_feed_shark_loop()
	_verify_feed_shark_failure_paths()
	_verify_shark_raised_title()
	_verify_save_type_normalization()
	_verify_shark_exclusion_from_market_and_cooking()
	_verify_legacy_shark_quest_rejected()

	if _failed:
		return
	print("shark_pen_smoke: ok")
	get_tree().quit(0)


func _verify_shark_catch_goes_to_pen() -> void:
	_seed_clean_progress()
	var result := PlayerProgress.record_catch("nekozame", 92.0, "danger_reef")
	_expect(bool(result.get("ok", true)), "record_catch should return a result")
	_expect(bool(result.get("sent_to_shark_pen", false)), "shark catch should be marked as pen transfer")
	_expect_eq(PlayerProgress.fish_count("nekozame"), 0, "shark catch must not enter inventory")
	_expect_eq(int(PlayerProgress.caught_counts.get("nekozame", 0)), 1, "shark catch should update caught count")
	_expect_eq(int(PlayerProgress.shark_bonds.get("nekozame", -1)), 0, "shark catch should initialize bond")
	var spot_counts: Dictionary = PlayerProgress.spot_caught_counts.get("danger_reef", {})
	_expect_eq(int(spot_counts.get("nekozame", 0)), 1, "shark catch should update spot count")


func _verify_feed_shark_loop() -> void:
	_seed_clean_progress()
	PlayerProgress.record_catch("nekozame", 92.0, "danger_reef")
	PlayerProgress.inventory["mahaze"] = 2
	var exp_before := PlayerProgress.exp
	var result := PlayerProgress.feed_shark("nekozame", "mahaze")
	_expect(bool(result.get("ok", false)), "feeding favorite fish should succeed")
	_expect(bool(result.get("favorite", false)), "mahaze should be a favorite for nekozame")
	_expect_eq(PlayerProgress.fish_count("mahaze"), 1, "feeding should consume one fish")
	_expect_eq(int(PlayerProgress.shark_bonds.get("nekozame", 0)), 8, "favorite feeding should add 8 bond")
	_expect_eq(int(result.get("exp_gain", 0)), 36, "favorite feeding should grant food_exp x2")
	_expect_eq(PlayerProgress.exp, exp_before + 36, "feeding EXP should be added to player")
	PlayerProgress.inventory["madai"] = 1
	var non_favorite := PlayerProgress.feed_shark("nekozame", "madai")
	_expect(bool(non_favorite.get("ok", false)), "feeding non-favorite fish should succeed")
	_expect(not bool(non_favorite.get("favorite", true)), "madai should not be favorite for nekozame")
	_expect_eq(int(non_favorite.get("bond_gain", 0)), 3, "non-favorite feeding should add 3 bond")
	var expected_non_favorite_exp := int(
		round(
			float(GameData.get_fish("madai").get("food_exp", 0))
			* GameData.SHARK_DEFAULT_EXP_MULTIPLIER
		)
	)
	_expect_eq(
		int(non_favorite.get("exp_gain", 0)),
		expected_non_favorite_exp,
		"non-favorite feeding should grant food_exp x1.5"
	)


func _verify_feed_shark_failure_paths() -> void:
	_seed_clean_progress()
	PlayerProgress.inventory["aji"] = 1
	var uncaught := PlayerProgress.feed_shark("nekozame", "aji")
	_expect(not bool(uncaught.get("ok", false)), "feeding uncaught shark should fail")
	PlayerProgress.record_catch("nekozame", 92.0, "danger_reef")
	var no_food := PlayerProgress.feed_shark("nekozame", "mahaze")
	_expect(not bool(no_food.get("ok", false)), "feeding unavailable fish should fail")
	PlayerProgress.inventory["inuzame"] = 1
	var shark_food := PlayerProgress.feed_shark("nekozame", "inuzame")
	_expect(not bool(shark_food.get("ok", false)), "feeding shark as food should fail")


func _verify_shark_raised_title() -> void:
	_seed_clean_progress()
	PlayerProgress.level = 30
	for shark_id in GameData.get_normal_shark_ids():
		PlayerProgress.caught_counts[shark_id] = 1
		PlayerProgress.shark_bonds[shark_id] = 100
	PlayerProgress.shark_bonds["inuzame"] = 92
	PlayerProgress.inventory["aji"] = 1
	PlayerProgress._remember_current_titles()
	var emitted_title_ids: Array[String] = []
	PlayerProgress.titles_earned.connect(
		func(title_ids: Array[String]) -> void:
			for title_id in title_ids:
				emitted_title_ids.append(title_id)
	)
	var result := PlayerProgress.feed_shark("inuzame", "aji")
	_expect(bool(result.get("ok", false)), "feeding last shark should succeed")
	_expect_eq(int(PlayerProgress.shark_bonds.get("inuzame", 0)), 100, "bond should clamp to 100")
	_expect(bool(result.get("completed", false)), "result should mark bond completion")
	_expect(Array(result.get("new_titles", [])).has("shark_raised_all"), "raising all sharks should award title")
	_expect(emitted_title_ids.has("shark_raised_all"), "title signal should emit shark_raised_all")


func _verify_save_type_normalization() -> void:
	PlayerProgress._apply_save_data(
		{
			"level": 30.0,
			"shark_bonds": {
				"nekozame": 8.0,
				"inuzame": 120.0,
				"nushi_danger_reef": 100.0,
			},
		}
	)
	_expect_eq(int(PlayerProgress.shark_bonds.get("nekozame", 0)), 8, "shark bond should normalize to int")
	_expect_eq(int(PlayerProgress.shark_bonds.get("inuzame", 0)), 100, "shark bond should clamp to 100")
	_expect(not PlayerProgress.shark_bonds.has("nushi_danger_reef"), "non-raiseable shark should not persist in bonds")


func _verify_shark_exclusion_from_market_and_cooking() -> void:
	_seed_clean_progress()
	PlayerProgress.inventory["nekozame"] = 1
	_expect(not GameData.get_all_sellable_fish_ids().has("nekozame"), "shark should not be sellable")
	_expect(not GameData.get_all_cookable_fish_ids().has("nekozame"), "shark should not be cookable")
	var sell_result := PlayerProgress.sell_fish("nekozame", 1)
	_expect(not bool(sell_result.get("ok", false)), "selling shark should fail even if old save has stock")
	var cook_result := PlayerProgress.cook_and_eat("nekozame", "sashimi")
	_expect(not bool(cook_result.get("ok", false)), "cooking shark should fail even if old save has stock")


func _verify_legacy_shark_quest_rejected() -> void:
	_seed_clean_progress()
	PlayerProgress.inventory["nekozame"] = 1
	PlayerProgress._apply_save_data(
		{
			"level": 30,
			"inventory": {"nekozame": 1},
			"owned_boats": ["skiff", "offshore_boat", "bluewater_boat"],
			"quest_board": [
				{
					"template_id": "bulk_common",
					"kind": "delivery",
					"fish_id": "nekozame",
					"count": 1,
					"reward_money": 1000,
					"text": "ネコザメを1匹届けてほしい",
				},
			],
		}
	)
	_expect_eq(PlayerProgress.quest_board.size(), 3, "legacy shark quest should be removed and refilled")
	for quest in PlayerProgress.quest_board:
		_expect(
			String(quest.get("fish_id", "")) != "nekozame",
			"repaired quest board should not retain a shark target"
		)
	_expect_eq(PlayerProgress.fish_count("nekozame"), 1, "quest repair should not consume old shark stock")


func _seed_clean_progress() -> void:
	PlayerProgress.level = 30
	PlayerProgress.exp = 0
	PlayerProgress.money = 500
	PlayerProgress.inventory = {}
	PlayerProgress.caught_counts = {}
	PlayerProgress.spot_caught_counts = {}
	PlayerProgress.best_sizes = {}
	PlayerProgress.eaten_recipes = {}
	PlayerProgress.quest_board = []
	PlayerProgress.quest_completed_count = 0
	PlayerProgress.sea_chart_fragments = 3
	PlayerProgress.shark_bonds = {}
	PlayerProgress._remember_current_titles()


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)


func _expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	_expect(actual == expected, "%s: expected %s, got %s" % [message, str(expected), str(actual)])
