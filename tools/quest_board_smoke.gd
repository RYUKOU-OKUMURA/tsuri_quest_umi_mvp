extends Node

const QuestBoardScreen = preload("res://src/ui/quest_board_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const CUISINE_COVERAGE_SEED_START := 2026071100
const CUISINE_COVERAGE_SEED_COUNT_PER_FISH := 256

var _failed := false


func _ready() -> void:
	if OS.get_environment("QUEST_BOARD_SMOKE_FORCE_FAILURE") == "1":
		_expect(false, "forced quest board smoke failure")
	if _failed:
		get_tree().quit(1)
		return
	_seed_progress()
	_verify_board_generation()
	_verify_delivery_flow()
	_verify_record_flow()
	_verify_insufficient_delivery()
	_verify_shokunin_reward()
	_verify_save_type_normalization()
	_verify_legacy_quest_repair()
	await _verify_screen_build()
	await _verify_full_condition_text_layout()

	if _failed:
		get_tree().quit(1)
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


func _verify_legacy_quest_repair() -> void:
	var valid_quest := {
		"template_id": "bulk_common",
		"kind": "delivery",
		"fish_id": "aji",
		"count": 5.0,
		"reward_money": 960.0,
		"text": "アジを5匹届けてほしい",
		"legacy_progress": 2,
	}
	var second_valid_quest := {
		"template_id": "size_record",
		"kind": "record",
		"fish_id": "mejina",
		"target_size_cm": 45.5,
		"posted_best_cm": 40.25,
		"reward_money": 1200.0,
		"text": "45.5cm以上のメジナを見せてほしい",
	}
	PlayerProgress._apply_save_data(
		{
			"level": 30,
			"owned_boats": ["skiff", "offshore_boat", "bluewater_boat"],
			"quest_board": [
				valid_quest,
				{"kind": "delivery", "fish_id": "unknown_fish", "text": "unknown"},
				second_valid_quest,
				{"kind": "delivery", "fish_id": "nekozame", "text": "shark"},
				{"kind": "record", "fish_id": "nushi_deep_ocean", "text": "boss"},
			],
		}
	)
	_expect_eq(PlayerProgress.quest_board.size(), 3, "legacy quest repair should refill three slots")
	var preserved := PlayerProgress.quest_board[0]
	_expect_eq(String(preserved.get("template_id", "")), "bulk_common", "valid quest id should stay")
	_expect_eq(int(preserved.get("count", 0)), 5, "valid quest progress requirement should stay")
	_expect_eq(int(preserved.get("reward_money", 0)), 960, "valid quest reward should stay")
	_expect_eq(int(preserved.get("legacy_progress", 0)), 2, "unknown valid quest fields should stay")
	var second_preserved := PlayerProgress.quest_board[1]
	_expect_eq(String(second_preserved.get("template_id", "")), "size_record", "second valid quest id")
	_expect_eq(String(second_preserved.get("fish_id", "")), "mejina", "valid quest order should stay")
	_expect_eq(float(second_preserved.get("target_size_cm", 0.0)), 45.5, "record target should stay")
	_expect_eq(float(second_preserved.get("posted_best_cm", 0.0)), 40.25, "posted progress should stay")
	_expect_eq(int(second_preserved.get("reward_money", 0)), 1200, "second reward should stay")
	for quest in PlayerProgress.quest_board:
		_expect_valid_quest(quest)


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
	screen.size = Vector2(viewport.size)
	viewport.add_child(screen)
	await get_tree().process_frame
	await get_tree().process_frame
	_expect_eq(PlayerProgress.quest_board.size(), 3, "quest board screen should fill board to three quests")
	var action := screen.find_child("QuestActionButton1", true, false) as Button
	_expect(action != null, "quest board screen should expose first action button")
	if action != null:
		_expect(not action.disabled, "ready delivery should enable first action button")
		_assert_action_button_layout(screen, action)
	var return_button := screen.find_child("QuestBoardReturnButton", true, false) as Button
	_expect(return_button != null, "quest board screen should expose return button")
	var wood := screen.find_child("QuestBoardWood", true, false) as TextureRect
	var notice := screen.find_child("QuestBoardTexturePanel", true, false) as TextureRect
	_expect(wood != null and wood.texture != null, "quest board should load the authored wood texture")
	_expect(notice != null and notice.texture != null, "quest card should load the authored notice texture")
	if wood != null and wood.texture != null:
		_expect_eq(wood.texture.get_size(), Vector2(1280.0, 512.0), "authored wood texture size")
	if notice != null and notice.texture != null:
		_expect_eq(notice.texture.get_size(), Vector2(384.0, 432.0), "authored notice texture size")
	_expect(FileAccess.file_exists(QuestBoardScreen.QUEST_BOARD_WOOD_PATH), "authored wood path should exist")
	_expect(FileAccess.file_exists(QuestBoardScreen.QUEST_NOTICE_CARD_PATH), "authored notice path should exist")
	viewport.queue_free()
	await get_tree().process_frame


func _verify_full_condition_text_layout() -> void:
	_seed_progress()
	var template_ids: Array[String] = []
	for template_id_variant in GameData.quest_template_weights(PlayerProgress.level).keys():
		template_ids.append(String(template_id_variant))
	template_ids.sort()
	_expect(not template_ids.is_empty(), "active quest templates should exist")
	for template_id in template_ids:
		_seed_progress()
		if template_id == "cuisine":
			await _verify_all_production_cuisine_condition_texts()
			continue
		var quest := _longest_production_quest_for_template(template_id)
		_expect(not quest.is_empty(), "%s should generate a production quest" % template_id)
		if not quest.is_empty():
			await _expect_generated_quest_text_fits(template_id, quest)


func _longest_production_quest_for_template(template_id: String) -> Dictionary:
	var template := GameData.get_quest_template(template_id)
	var rarity := String(template.get("rarity", ""))
	var source_context := _quest_context(template_id)
	var candidates: Array[String] = GameData._quest_candidate_fish_ids(source_context, rarity)
	var longest_quest := {}
	for fish_id in candidates:
		var context := source_context.duplicate(true)
		context["exclude_fish_ids"] = _all_except(candidates, fish_id)
		var quest := GameData.generate_quest(context)
		if quest.is_empty():
			continue
		if String(quest.get("text", "")).length() > String(longest_quest.get("text", "")).length():
			longest_quest = quest
	return longest_quest


func _verify_all_production_cuisine_condition_texts() -> void:
	var context := _quest_context("cuisine")
	# 本番生成器と同じ候補カタログを直接参照し、料理名×魚の全組合せを期待値にする。
	var options: Array[Dictionary] = GameData._quest_cuisine_options(context)
	_expect(not options.is_empty(), "cuisine should expose production options")
	var expected_keys: Dictionary = {}
	for option in options:
		expected_keys[_cuisine_option_key(option)] = true
	_expect_eq(expected_keys.size(), options.size(), "production cuisine options should not duplicate recipe/fish pairs")

	var production_quests := _collect_all_production_cuisine_quests(context, expected_keys)
	print(
		"quest_board_smoke: deterministic cuisine coverage=%d/%d" % [
			production_quests.size(),
			expected_keys.size(),
		]
	)
	_expect_eq(
		production_quests.size(),
		expected_keys.size(),
		"deterministic production seeds should cover every cuisine recipe/fish pair"
	)
	var first_key := _cuisine_option_key(options[0]) if not options.is_empty() else ""
	var first_quest: Dictionary = production_quests.get(first_key, {})
	var harness := await _make_quest_layout_harness(first_quest)
	var screen := harness["screen"] as QuestBoardScreen
	for option in options:
		var key := _cuisine_option_key(option)
		_expect(production_quests.has(key), "production cuisine output should include %s" % key)
		if production_quests.has(key):
			var quest: Dictionary = production_quests[key]
			_expect_eq(String(quest.get("recipe_id", "")), String(option.get("recipe_id", "")), "cuisine recipe id should match production option")
			_expect_eq(String(quest.get("fish_id", "")), String(option.get("fish_id", "")), "cuisine fish id should match production option")
			_expect_quest_text_in_screen("cuisine", quest, screen)
	var viewport := harness["viewport"] as SubViewport
	viewport.queue_free()
	await get_tree().process_frame


func _collect_all_production_cuisine_quests(context: Dictionary, expected_keys: Dictionary) -> Dictionary:
	var quests_by_option: Dictionary = {}
	var original_rng_state := GameData._rng.state
	var candidates: Array[String] = GameData._quest_candidate_fish_ids(context)
	var expected_by_fish: Dictionary = {}
	for key_variant in expected_keys.keys():
		var key := String(key_variant)
		var fish_id := key.get_slice(":", 1)
		if not expected_by_fish.has(fish_id):
			expected_by_fish[fish_id] = {}
		expected_by_fish[fish_id][key] = true
	var fish_ids: Array[String] = []
	for fish_id_variant in expected_by_fish.keys():
		fish_ids.append(String(fish_id_variant))
	fish_ids.sort()
	for fish_index in fish_ids.size():
		var fish_id := fish_ids[fish_index]
		var expected_for_fish: Dictionary = expected_by_fish[fish_id]
		var fish_context := context.duplicate(true)
		fish_context["exclude_fish_ids"] = _all_except(candidates, fish_id)
		var found_for_fish: Dictionary = {}
		for offset in range(CUISINE_COVERAGE_SEED_COUNT_PER_FISH):
			GameData._rng.seed = CUISINE_COVERAGE_SEED_START + fish_index * CUISINE_COVERAGE_SEED_COUNT_PER_FISH + offset
			var quest := GameData.generate_quest(fish_context)
			var key := _cuisine_option_key(quest)
			if expected_for_fish.has(key):
				quests_by_option[key] = quest
				found_for_fish[key] = true
			if found_for_fish.size() == expected_for_fish.size():
				break
		if quests_by_option.size() == expected_keys.size():
			break
	GameData._rng.state = original_rng_state
	return quests_by_option


func _cuisine_option_key(option: Dictionary) -> String:
	return "%s:%s" % [String(option.get("recipe_id", "")), String(option.get("fish_id", ""))]


func _all_except(values: Array[String], retained_value: String) -> Array[String]:
	var excluded: Array[String] = []
	for value in values:
		if value != retained_value:
			excluded.append(value)
	return excluded


func _expect_generated_quest_text_fits(template_id: String, quest: Dictionary) -> void:
	var harness := await _make_quest_layout_harness(quest)
	var screen := harness["screen"] as QuestBoardScreen
	_expect_quest_text_in_screen(template_id, quest, screen)
	var viewport := harness["viewport"] as SubViewport
	viewport.queue_free()
	await get_tree().process_frame


func _make_quest_layout_harness(initial_quest: Dictionary = {}) -> Dictionary:
	var board: Array[Dictionary] = []
	if not initial_quest.is_empty():
		board.append(initial_quest.duplicate(true))
	PlayerProgress.quest_board = board
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var screen := QuestBoardScreen.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({})
	screen.size = Vector2(viewport.size)
	viewport.add_child(screen)
	await get_tree().process_frame
	await get_tree().process_frame
	return {"viewport": viewport, "screen": screen}


func _expect_quest_text_in_screen(template_id: String, quest: Dictionary, screen: QuestBoardScreen) -> void:
	var body := screen.find_child("QuestText", true, false) as Label
	_expect(body != null, "%s should expose condition text" % template_id)
	if body != null:
		body.text = String(quest.get("text", ""))
		_expect_eq(body.text, String(quest.get("text", "")), "%s should keep the production condition text" % template_id)
		_expect(body.get_line_count() <= 3, "%s condition should fit within three lines" % template_id)
		_expect(
			body.get_visible_line_count() == body.get_line_count(),
			"%s condition should not be clipped or ellipsized" % template_id
		)


func _assert_action_button_layout(screen: QuestBoardScreen, action: Button) -> void:
	var card := screen.find_child("QuestCard1", true, false) as Control
	var progress_title := screen.find_child("QuestProgressTitle", true, false) as Label
	var progress_text := screen.find_child("QuestProgressText", true, false) as Label
	var progress_track := screen.find_child("QuestProgressTrack", true, false) as Panel
	var reward := screen.find_child("QuestReward", true, false) as Label
	_expect(
		card != null and progress_title != null and progress_text != null and progress_track != null and reward != null,
		"action button should have all lower-card anchors"
	)
	if card == null or progress_title == null or progress_text == null or progress_track == null or reward == null:
		return
	var style := action.get_theme_stylebox("normal") as StyleBoxTexture
	_expect(style != null, "action button should use a texture style")
	if style == null:
		return
	var required_height := (
		style.texture_margin_top
		+ style.texture_margin_bottom
		+ action.get_theme_font_size("font_size")
		+ action.get_theme_constant("outline_size") * 2
	)
	_expect(action.size.y + 0.5 >= QuestBoardScreen.QUEST_ACTION_BUTTON_MIN_HEIGHT, "action button should reserve its minimum height")
	_expect(action.size.y + 0.5 >= required_height, "action button should fit text and vertical texture margins")
	var action_rect := action.get_global_rect()
	var progress_title_rect := progress_title.get_global_rect()
	var progress_text_rect := progress_text.get_global_rect()
	var progress_track_rect := progress_track.get_global_rect()
	var reward_rect := reward.get_global_rect()
	var card_rect := card.get_global_rect()
	_expect(
		progress_title_rect.size.y + 0.5 >= progress_title.get_minimum_size().y,
		"progress title should reserve its minimum line height: rect=%s minimum=%s" % [
			progress_title_rect,
			progress_title.get_minimum_size(),
		]
	)
	_expect(
		progress_text_rect.size.y + 0.5 >= progress_text.get_minimum_size().y,
		"progress text should reserve its minimum line height: rect=%s minimum=%s" % [
			progress_text_rect,
			progress_text.get_minimum_size(),
		]
	)
	_expect(
		progress_text_rect.end.y <= progress_track_rect.position.y,
		"progress text should clear the track: text=%s track=%s" % [progress_text_rect, progress_track_rect]
	)
	_expect(
		progress_title_rect.end.y <= progress_track_rect.position.y,
		"progress title should clear the track: title=%s track=%s" % [progress_title_rect, progress_track_rect]
	)
	_expect(
		progress_track_rect.end.y <= reward_rect.position.y,
		"progress track should clear the reward: track=%s reward=%s" % [progress_track_rect, reward_rect]
	)
	_expect(
		action_rect.position.y + 1.0 >= reward_rect.end.y,
		"action button should not overlap the reward: action=%s reward=%s" % [action_rect, reward_rect]
	)
	_expect(
		action_rect.end.y <= card_rect.position.y + card_rect.size.y * QuestBoardScreen.QUEST_ACTION_BUTTON_SAFE_BOTTOM + 1.0,
		"action button should clear the quest card lower frame"
	)


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
	printerr("quest_board_smoke failure: %s" % message)
	push_error(message)


func _expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	_expect(actual == expected, "%s got=%s expected=%s" % [message, str(actual), str(expected)])
