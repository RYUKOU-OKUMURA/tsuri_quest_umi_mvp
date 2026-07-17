extends Node

const StatusScreenScript = preload("res://src/ui/status_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")

var _screen: Variant
var _navigated_to := ""
var _payload: Dictionary = {}
var _failed := false
var _inventory_nushi_id := ""
var _inventory_shark_id := ""


func _ready() -> void:
	_seed_progress()
	PlayerProgress.difficulty_id = "normal"
	_screen = _make_screen()
	await get_tree().process_frame
	await get_tree().process_frame

	_expect(_screen._player_status_bar != null, "player status bar should be present")
	_expect(_find_label_containing(_screen, "難易度: ふつう") != null, "status should show the normal difficulty name once")
	_expect(_count_labels_containing(_screen, "難易度:") == 1, "status should not duplicate difficulty information")
	_expect(_screen._player_panel != null, "player panel should be present")
	_expect(_screen._summary_panel != null, "catch summary panel should be present")
	_expect(_find_named(_screen, "StatusPlayerFishingPortrait") != null, "player fishing portrait should be present in summary medallion")
	_expect(_screen._inventory_panel != null, "inventory panel should be present")
	_expect(_find_named(_screen, "StatusScreenShell") != null, "authored status screen shell should be present")
	_expect(_count_named(_screen, "StatusPaperFrame") == 3, "all three status panes should use the shared screen-local paper frame")
	_expect(_count_named(_screen, "StatusDarkFrame") == 2, "header and footer should use the shared screen-local dark frame")
	_verify_r5b_frame_contract()
	_expect(_screen._fish_book_button != null, "fish book navigation should be present")
	_expect(_screen._cooking_button != null, "cooking navigation should be present")
	_expect(_screen._return_button != null, "harbor return button should be present")
	_expect(_screen._discovered_fish_count() == 4, "discovered fish count should match seeded progress")
	_expect(_screen._total_catch_count() == 21, "total catch count should match seeded progress")
	_expect(_screen._recorded_spot_count() == 3, "recorded spot count should match seeded progress")
	_verify_inventory_domain_contract()
	var earned_titles := GameData.compute_earned_titles(PlayerProgress.title_stats_snapshot())
	_expect(earned_titles.has("total_10"), "seeded progress should earn total_10 title")
	_expect(not earned_titles.has("total_100"), "seeded progress should not earn total_100 title")
	_expect(_find_named(_screen, "StatusExpValue") != null, "EXP value label should be present")
	_expect(_find_named(_screen, "StatusCompletionValue") != null, "completion value label should be present")
	_expect(_find_named(_screen, "StatusTitleStrip") != null, "title strip should be present")
	_expect(_find_named(_screen, "StatusTitleListButton") != null, "title list button should be present")
	_expect(_find_label_containing(_screen, "称号 1 / 31") != null, "title count should be visible")
	_expect(_find_label_containing(_screen, "駆け出し釣り人") != null, "earned title should be visible")
	_expect(_find_label_containing(_screen, "？？？ 累計100匹釣る") != null, "locked title hint should be visible")
	_expect(_find_named(_screen, "StatusTitleOverlay") != null, "title overlay should be present")
	_expect(not _screen._title_overlay.visible, "title overlay should start hidden")
	_screen._title_list_button.pressed.emit()
	await get_tree().process_frame
	_expect(_screen._title_overlay.visible, "title overlay should open from title strip")
	_expect(_title_row_count(_screen) == 31, "title overlay should list all titles")
	_expect(_find_named(_screen, "StatusTitleRow_total_10") != null, "earned title row should exist")
	_expect(_find_named(_screen, "StatusTitleRow_total_100") != null, "locked title row should exist")
	_expect(_find_label_containing(_screen, "累計100匹釣る") != null, "locked title hint should be visible in overlay")
	_screen._set_title_overlay_visible(false)
	await get_tree().process_frame
	_expect(_find_named(_screen, "StatusRecentFish_aji") != null, "recent fish cards should be present")
	_expect(_find_named(_screen, "StatusCoolerSlot_0") != null, "cooler item slots should be present")
	var nushi_name := String(GameData.get_fish(_inventory_nushi_id).get("name", _inventory_nushi_id))
	_expect(
		_find_label_containing(_screen, "アジ ×2") != null,
		"cooler should show the normal inventory fish count"
	)
	_expect(
		_find_label_containing(_screen, "%s ×1" % nushi_name) != null,
		"cooler should show inventory nushi"
	)
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

	PlayerProgress.difficulty_id = "hard"
	var hard_screen := _make_screen()
	await get_tree().process_frame
	_expect(_find_label_containing(hard_screen, "難易度: むずかしい") != null, "status should show the hard difficulty name")
	_expect(_count_labels_containing(hard_screen, "難易度:") == 1, "hard status should show difficulty exactly once")
	hard_screen.queue_free()

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
	_inventory_nushi_id = GameData.get_all_nushi_fish_ids()[0]
	_inventory_shark_id = GameData.get_normal_shark_ids()[0]
	PlayerProgress.inventory = {
		"aji": 2,
		"saba": -3,
		"unknown_inventory_fish": 8,
	}
	PlayerProgress.inventory[_inventory_nushi_id] = 1
	PlayerProgress.inventory[_inventory_shark_id] = 4
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


func _verify_inventory_domain_contract() -> void:
	var inventory_ids := GameData.get_all_inventory_fish_ids()
	var cookable_ids := GameData.get_all_cookable_fish_ids()
	var inventory_nushi_ids: Array[String] = []
	for nushi_id in GameData.get_all_nushi_fish_ids():
		if not bool(GameData.get_fish(nushi_id).get("shark", false)):
			inventory_nushi_ids.append(nushi_id)
	_expect(
		inventory_ids.slice(0, cookable_ids.size()) == cookable_ids,
		"inventory domain should keep the existing normal non-shark order"
	)
	_expect(
		inventory_ids.slice(cookable_ids.size()) == inventory_nushi_ids,
		"inventory domain should append non-shark nushi in fishing-spot order"
	)
	var unique_ids: Dictionary = {}
	for fish_id in inventory_ids:
		unique_ids[fish_id] = true
	_expect(unique_ids.size() == inventory_ids.size(), "inventory domain should not contain duplicates")
	_expect(inventory_ids.has(_inventory_nushi_id), "inventory domain should include nushi")
	_expect(not inventory_ids.has(_inventory_shark_id), "inventory domain should exclude sharks")
	_expect(not cookable_ids.has(_inventory_nushi_id), "nushi should remain outside the cookable domain")
	_expect(
		GameData.inventory_fish_total(PlayerProgress.inventory) == 3,
		"inventory total should include normal fish and nushi only"
	)
	_expect(
		GameData.inventory_fish_kind_count(PlayerProgress.inventory) == 2,
		"inventory kinds should include normal fish and nushi only"
	)


func _verify_r5b_frame_contract() -> void:
	var frames: Array[Node] = []
	_collect_named(_screen, "StatusPaperFrame", frames)
	_collect_named(_screen, "StatusDarkFrame", frames)
	for frame_node in frames:
		_expect(frame_node is Panel, "R5-B frame node should remain a Panel")
		if not frame_node is Panel:
			continue
		var frame := frame_node as Panel
		var style := frame.get_theme_stylebox("panel")
		_expect(style is StyleBoxTexture, "%s should render an authored 9-slice texture" % frame.name)
		if not style is StyleBoxTexture:
			continue
		var texture_style := style as StyleBoxTexture
		_expect(
			texture_style.texture_margin_left + texture_style.texture_margin_right < frame.size.x,
			"%s horizontal frame margins should leave a content well" % frame.name
		)
		_expect(
			texture_style.texture_margin_top + texture_style.texture_margin_bottom < frame.size.y,
			"%s vertical frame margins should leave a content well" % frame.name
		)


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


func _count_labels_containing(root: Node, text: String) -> int:
	var count := 1 if root is Label and String((root as Label).text).contains(text) else 0
	for child in root.get_children():
		count += _count_labels_containing(child, text)
	return count


func _count_named(root: Node, node_name: String) -> int:
	var count := 1 if root.name == node_name else 0
	for child in root.get_children():
		count += _count_named(child, node_name)
	return count


func _collect_named(root: Node, node_name: String, output: Array[Node]) -> void:
	if root.name == node_name:
		output.append(root)
	for child in root.get_children():
		_collect_named(child, node_name, output)


func _buttons_with_meta(root: Node, meta_name: String) -> Array[Button]:
	var buttons: Array[Button] = []
	_collect_buttons_with_meta(root, meta_name, buttons)
	return buttons


func _title_row_count(root: Node) -> int:
	var count := 0
	for child in root.get_children():
		if child.name.begins_with("StatusTitleRow_"):
			count += 1
		count += _title_row_count(child)
	return count


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
