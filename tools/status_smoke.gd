extends Node

const StatusScreenScript = preload("res://src/ui/status_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")

var _screen: Variant
var _navigated_to := ""
var _payload: Dictionary = {}
var _failed := false


func _ready() -> void:
	_seed_progress()
	_screen = _make_screen()
	await get_tree().process_frame
	await get_tree().process_frame

	_expect(_screen._player_status_bar != null, "player status bar should be present")
	_expect(_screen._player_panel != null, "player panel should be present")
	_expect(_screen._summary_panel != null, "catch summary panel should be present")
	_expect(_screen._inventory_panel != null, "inventory panel should be present")
	_expect(_screen._fish_book_button != null, "fish book navigation should be present")
	_expect(_screen._cooking_button != null, "cooking navigation should be present")
	_expect(_screen._return_button != null, "harbor return button should be present")
	_expect(_screen._discovered_fish_count() == 4, "discovered fish count should match seeded progress")
	_expect(_screen._total_catch_count() == 21, "total catch count should match seeded progress")
	_expect(_screen._recorded_spot_count() == 3, "recorded spot count should match seeded progress")
	var earned_titles := GameData.compute_earned_titles(PlayerProgress.title_stats_snapshot())
	_expect(earned_titles.has("total_10"), "seeded progress should earn total_10 title")
	_expect(not earned_titles.has("total_100"), "seeded progress should not earn total_100 title")
	_expect(_find_named(_screen, "StatusExpValue") != null, "EXP value label should be present")
	_expect(_find_named(_screen, "StatusCompletionValue") != null, "completion value label should be present")
	_expect(_find_named(_screen, "StatusTitleStrip") != null, "title strip should be present")
	_expect(_find_label_containing(_screen, "称号 1 / 31") != null, "title count should be visible")
	_expect(_find_label_containing(_screen, "駆け出し釣り人") != null, "earned title should be visible")
	_expect(_find_label_containing(_screen, "？？？ 累計100匹釣る") != null, "locked title hint should be visible")
	_expect(_find_named(_screen, "StatusRecentFish_aji") != null, "recent fish cards should be present")
	_expect(_find_named(_screen, "StatusCoolerSlot_0") != null, "cooler item slots should be present")
	_expect(_find_label_containing(_screen, "カジキ竿・蒼槍（装備中）") != null, "equipped marlin rod should be visible in owned rods")
	_expect(_find_named(_screen, "FishBookGrid") == null, "old fish book grid must not remain in status")
	_expect(_buttons_with_meta(_screen, "fish_book_card").is_empty(), "status must not contain full fish book cards")

	_screen._fish_book_button.pressed.emit()
	_expect(_navigated_to == "fish_book", "fish book button should navigate to fish_book")
	_navigated_to = ""

	_screen._cooking_button.pressed.emit()
	_expect(_navigated_to == "cooking", "cooking button should navigate to cooking")
	_navigated_to = ""

	_screen._return_button.pressed.emit()
	_expect(_navigated_to == "harbor", "return button should navigate to harbor")

	if _failed:
		return
	print("status_smoke: ok")
	get_tree().quit(0)


func _seed_progress() -> void:
	PlayerProgress.level = 4
	PlayerProgress.exp = 52
	PlayerProgress.money = 12840
	PlayerProgress.equipped_rod_id = "marlin"
	PlayerProgress.owned_rods = ["starter", "iso", "offshore", "big_game", "marlin"]
	PlayerProgress.owned_boats = ["skiff"]
	PlayerProgress.caught_counts = {
		"aji": 12,
		"mejina": 5,
		"kasago": 3,
		"saba": 1,
	}
	PlayerProgress.best_sizes = {
		"aji": 34.2,
		"mejina": 44.2,
		"kasago": 26.4,
		"saba": 38.6,
	}
	PlayerProgress.inventory = {
		"aji": 1,
		"kasago": 2,
		"saba": 3,
	}
	PlayerProgress.spot_caught_counts = {
		"harbor_pier": {"aji": 12},
		"rock_breakwater": {"mejina": 5, "kasago": 3},
		"outer_tide": {"saba": 1},
	}
	PlayerProgress.pending_buff = {
		"recipe_id": "salt_grill",
		"name": "アジの塩焼き",
		"stat": "max_energy",
		"value": 0.05,
		"text": "次の釣行で最大体力 +5%",
	}
	PlayerProgress.eaten_recipes = {
		"aji:salt_grill": 2,
		"mejina:simmered": 1,
	}


func _make_screen(payload: Dictionary = {}) -> Control:
	var screen := StatusScreenScript.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure(payload)
	screen.size = Vector2(1280.0, 720.0)
	screen.navigate_requested.connect(
		func(screen_id: String, payload: Dictionary) -> void:
			_navigated_to = screen_id
			_payload = payload.duplicate(true)
	)
	add_child(screen)
	return screen


func _find_named(root: Node, node_name: String) -> Node:
	if root.name == node_name:
		return root
	for child in root.get_children():
		var found := _find_named(child, node_name)
		if found != null:
			return found
	return null


func _find_label_containing(root: Node, text: String) -> Label:
	if root is Label and String((root as Label).text).contains(text):
		return root as Label
	for child in root.get_children():
		var found := _find_label_containing(child, text)
		if found != null:
			return found
	return null


func _buttons_with_meta(root: Node, meta_name: String) -> Array[Button]:
	var buttons: Array[Button] = []
	_collect_buttons_with_meta(root, meta_name, buttons)
	return buttons


func _collect_buttons_with_meta(node: Node, meta_name: String, buttons: Array[Button]) -> void:
	for child in node.get_children():
		if child is Button and bool(child.get_meta(meta_name, false)):
			buttons.append(child as Button)
		_collect_buttons_with_meta(child, meta_name, buttons)


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
