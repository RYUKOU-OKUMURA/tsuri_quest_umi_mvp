extends Node

const QuestBoardScreen = preload("res://src/ui/quest_board_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")

var _failed := false


func _ready() -> void:
	_seed_progress()
	_verify_board_generation()
	_verify_delivery_flow()
	_verify_record_flow()
	_verify_insufficient_delivery()
	_verify_shokunin_reward()
	_verify_save_type_normalization()
	await _verify_screen_build()
	await _verify_full_condition_text_layout()

	if _failed:
		return
	print("quest_board_smoke: ok")
	get_tree().quit(0)


func _seed_progress() -> void:
	PlayerProgress.reset_game()
	PlayerProgress.level = 9
	PlayerProgress.money = 1000
	PlayerProgress.owned_boats = ["skiff", "offshore_boat", "bluewater_boat"]
	PlayerProgress.inventory = {}
	PlayerProgress.best_sizes = {}
	PlayerProgress.quest_board = []
	PlayerProgress.quest_completed_count = 0
	PlayerProgress.owned_rigs = [GameData.DEFAULT_RIG_ID]
	PlayerProgress.equipped_rig_id = GameData.DEFAULT_RIG_ID
	PlayerProgress._remember_current_titles()


func _verify_board_generation() -> void:
	var board := GameData.generate_quest_board(_quest_context(), 3)
	_expect(board.size() == 3, "quest board should generate three quests")
	var fish_ids: Array[String] = []
	for quest in board:
		_expect_valid_quest(quest)
		var fish_id := String(quest.get("fish_id", ""))
		_expect(not fish_ids.has(fish_id), "generated quests should not duplicate fish id")
		fish_ids.append(fish_id)

	for _i in range(40):
		var quest := GameData.generate_quest(_quest_context())
		_expect_valid_quest(quest)


func _verify_delivery_flow() -> void:
	_seed_progress()
	var quest := GameData.generate_quest(_quest_context("bulk_common"))
	_expect(not quest.is_empty(), "bulk_common quest should generate")
	var fish_id := String(quest.get("fish_id", ""))
	var count := int(quest.get("count", 0))
	PlayerProgress.quest_board = [quest]
	PlayerProgress.inventory[fish_id] = count
	var money_before := PlayerProgress.money
	var result := PlayerProgress.deliver_quest(0)
	_expect(bool(result.get("ok", false)), "delivery quest should complete")
	_expect_eq(PlayerProgress.fish_count(fish_id), 0, "delivery should consume fish")
	_expect_eq(
		PlayerProgress.money,
		money_before + int(quest.get("reward_money", 0)),
		"delivery should add reward money"
	)
	_expect_eq(PlayerProgress.quest_completed_count, 1, "delivery should increment quest count")
	_expect(PlayerProgress.quest_board.size() == 3, "delivery should keep board filled")
	_expect(
		String(PlayerProgress.quest_board[0].get("fish_id", "")) != fish_id,
		"replacement should avoid the completed fish"
	)


func _verify_record_flow() -> void:
	_seed_progress()
	var quest := GameData.generate_quest(_quest_context("size_record"))
	_expect(not quest.is_empty(), "size_record quest should generate")
	var fish_id := String(quest.get("fish_id", ""))
	PlayerProgress.quest_board = [quest]
	PlayerProgress.best_sizes[fish_id] = float(quest.get("target_size_cm", 0.0))
	var inventory_before := PlayerProgress.inventory.duplicate(true)
	var result := PlayerProgress.deliver_quest(0)
	_expect(bool(result.get("ok", false)), "record quest should complete")
	_expect(PlayerProgress.inventory == inventory_before, "record quest should not consume fish")
	_expect_eq(PlayerProgress.quest_completed_count, 1, "record quest should increment quest count")


func _verify_insufficient_delivery() -> void:
	_seed_progress()
	var quest := GameData.generate_quest(_quest_context("bulk_common"))
	var fish_id := String(quest.get("fish_id", ""))
	PlayerProgress.quest_board = [quest]
	PlayerProgress.inventory[fish_id] = maxi(0, int(quest.get("count", 0)) - 1)
	var money_before := PlayerProgress.money
	var result := PlayerProgress.deliver_quest(0)
	_expect(not bool(result.get("ok", false)), "insufficient delivery should fail")
	_expect_eq(PlayerProgress.money, money_before, "failed delivery should not add money")
	_expect_eq(PlayerProgress.quest_completed_count, 0, "failed delivery should not increment count")
	_expect(
		String(PlayerProgress.quest_board[0].get("fish_id", "")) == fish_id,
		"failed delivery should keep the original quest"
	)


func _verify_shokunin_reward() -> void:
	_seed_progress()
	var quest := GameData.generate_quest(_quest_context("bulk_common"))
	var fish_id := String(quest.get("fish_id", ""))
	PlayerProgress.quest_board = [quest]
	PlayerProgress.inventory[fish_id] = int(quest.get("count", 0))
	PlayerProgress.quest_completed_count = 9
	var result := PlayerProgress.deliver_quest(0)
	_expect(bool(result.get("ok", false)), "10th delivery should complete")
	_expect(bool(result.get("rig_awarded", false)), "10th completion should award shokunin rig")
	_expect("shokunin" in PlayerProgress.owned_rigs, "shokunin rig should be owned")
	_expect(bool(GameData.get_rig("shokunin").get("shop_hidden", false)), "shokunin rig should be shop hidden")
	_expect_eq(PlayerProgress.quest_completed_count, 10, "quest count should reach 10")


func _verify_save_type_normalization() -> void:
	PlayerProgress._apply_save_data(
		{
			"quest_completed_count": 2.0,
			"quest_board": [
				{
					"template_id": "bulk_common",
					"kind": "delivery",
					"fish_id": "aji",
					"count": 5.0,
					"reward_money": 960.0,
					"text": "アジを5匹届けてほしい",
				},
			],
		}
	)
	_expect_eq(PlayerProgress.quest_completed_count, 2, "quest count should normalize to int")
	_expect_eq(
		typeof(PlayerProgress.quest_board[0].get("count", 0)),
		TYPE_INT,
		"quest count field should normalize to int"
	)
	_expect_eq(
		typeof(PlayerProgress.quest_board[0].get("reward_money", 0)),
		TYPE_INT,
		"quest reward field should normalize to int"
	)


func _verify_screen_build() -> void:
	_seed_progress()
	var quest := GameData.generate_quest(_quest_context("bulk_common"))
	var fish_id := String(quest.get("fish_id", ""))
	PlayerProgress.quest_board = [quest]
	PlayerProgress.inventory[fish_id] = int(quest.get("count", 0))
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var screen := QuestBoardScreen.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({})
	viewport.add_child(screen)
	await get_tree().process_frame
	await get_tree().process_frame
	_expect_eq(PlayerProgress.quest_board.size(), 3, "quest board screen should fill board to three quests")
	var action := screen.find_child("QuestActionButton1", true, false) as Button
	_expect(action != null, "quest board screen should expose first action button")
	if action != null:
		_expect(not action.disabled, "ready delivery should enable first action button")
	var return_button := screen.find_child("QuestBoardReturnButton", true, false) as Button
	_expect(return_button != null, "quest board screen should expose return button")
	viewport.queue_free()
	await get_tree().process_frame


func _verify_full_condition_text_layout() -> void:
	_seed_progress()
	var fish_id := _longest_quest_fish_id()
	_expect(not fish_id.is_empty(), "longest quest fish should exist")
	var fish_name := String(GameData.get_fish(fish_id).get("name", fish_id))
	var recipe_name := _longest_recipe_name()
	var cases := [
		{
			"template_id": "bulk_common",
			"kind": "delivery",
			"text": "%sを5匹届けてほしい" % fish_name,
		},
		{
			"template_id": "bulk_uncommon",
			"kind": "delivery",
			"text": "%sを3匹。上物を頼む" % fish_name,
		},
		{
			"template_id": "cuisine",
			"kind": "delivery",
			"text": "%sにする%sを1匹" % [recipe_name, fish_name],
		},
		{
			"template_id": "size_record",
			"kind": "record",
			"text": "35cm以上の%sを釣り上げてくれ" % fish_name,
		},
		{
			"template_id": "rare_order",
			"kind": "delivery",
			"text": "%sを探している。金は弾む" % fish_name,
		},
	]
	for case_data_variant in cases:
		var case_data: Dictionary = case_data_variant
		PlayerProgress.quest_board = [
			_build_long_text_quest(case_data, fish_id),
			_build_long_text_quest({"template_id": "bulk_common", "kind": "delivery", "text": "アジを3匹届けてほしい"}, "aji"),
			_build_long_text_quest({"template_id": "bulk_common", "kind": "delivery", "text": "メジナを3匹届けてほしい"}, "mejina"),
		]
		await _expect_first_quest_text_fits(String(case_data["template_id"]), String(case_data["text"]))


func _build_long_text_quest(case_data: Dictionary, fish_id: String) -> Dictionary:
	var is_record := String(case_data.get("kind", "delivery")) == "record"
	return {
		"template_id": String(case_data.get("template_id", "bulk_common")),
		"kind": String(case_data.get("kind", "delivery")),
		"fish_id": fish_id,
		"count": 5,
		"target_size_cm": 35.0 if is_record else 0.0,
		"posted_best_cm": 20.0 if is_record else 0.0,
		"reward_money": 1000,
		"text": String(case_data.get("text", "")),
	}


func _expect_first_quest_text_fits(template_id: String, expected_text: String) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var screen := QuestBoardScreen.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({})
	viewport.add_child(screen)
	await get_tree().process_frame
	await get_tree().process_frame
	var body := screen.find_child("QuestText", true, false) as Label
	_expect(body != null, "%s should expose condition text" % template_id)
	if body != null:
		_expect_eq(body.text, expected_text, "%s should keep the full condition text" % template_id)
		_expect(body.get_line_count() <= 3, "%s condition should fit within three lines" % template_id)
		_expect(
			body.get_visible_line_count() == body.get_line_count(),
			"%s condition should not be clipped or ellipsized" % template_id
		)
	viewport.queue_free()
	await get_tree().process_frame


func _longest_quest_fish_id() -> String:
	var longest_id := ""
	var longest_name := ""
	var seen_ids: Array[String] = []
	for spot_id in GameData.FISHING_SPOT_ORDER:
		var spot := GameData.get_fishing_spot(spot_id)
		for fish_id_variant in Array(spot.get("allowed_fish", [])):
			var fish_id := String(fish_id_variant)
			if seen_ids.has(fish_id):
				continue
			seen_ids.append(fish_id)
			var fish := GameData.get_fish(fish_id)
			if fish.is_empty() or bool(fish.get("shark", false)) or bool(fish.get("nushi", false)) or bool(fish.get("boss", false)):
				continue
			var fish_name := String(fish.get("name", fish_id))
			if fish_name.length() > longest_name.length():
				longest_id = fish_id
				longest_name = fish_name
	return longest_id


func _longest_recipe_name() -> String:
	var longest_name := ""
	for recipe_id_variant in GameData.RECIPES.keys():
		var recipe := GameData.get_recipe(String(recipe_id_variant))
		var recipe_name := String(recipe.get("name", ""))
		if recipe_name.length() > longest_name.length():
			longest_name = recipe_name
	return longest_name


func _quest_context(template_id: String = "") -> Dictionary:
	var context := {
		"player_level": PlayerProgress.level,
		"owned_boats": PlayerProgress.owned_boats.duplicate(true),
		"sea_chart_fragments": PlayerProgress.sea_chart_fragments,
		"existing_quests": PlayerProgress.quest_board.duplicate(true),
		"best_sizes": PlayerProgress.best_sizes.duplicate(true),
	}
	if not template_id.is_empty():
		context["template_id"] = template_id
	return context


func _expect_valid_quest(quest: Dictionary) -> void:
	_expect(not quest.is_empty(), "quest should not be empty")
	var fish_id := String(quest.get("fish_id", ""))
	var fish := GameData.get_fish(fish_id)
	_expect(not fish.is_empty(), "quest fish should exist: %s" % fish_id)
	_expect(not bool(fish.get("shark", false)), "quest should not target shark fish: %s" % fish_id)
	_expect(not bool(fish.get("nushi", false)), "quest should not target nushi fish: %s" % fish_id)
	_expect(not bool(fish.get("boss", false)), "quest should not target boss fish: %s" % fish_id)
	_expect(not GameData.NUSHI_FISH.has(fish_id), "quest should not target NUSHI_FISH: %s" % fish_id)


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)


func _expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	_expect(actual == expected, "%s got=%s expected=%s" % [message, str(actual), str(expected)])
