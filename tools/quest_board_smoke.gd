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


func _quest_context(template_id: String = "") -> Dictionary:
	var context := {
		"player_level": PlayerProgress.level,
		"owned_boats": PlayerProgress.owned_boats.duplicate(true),
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
