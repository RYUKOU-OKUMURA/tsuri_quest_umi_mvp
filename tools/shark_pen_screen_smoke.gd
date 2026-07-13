extends Node

const SharkPenScreenScript = preload("res://src/ui/shark_pen_screen.gd")
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
	_expect(_screen._shark_rows.size() == 10, "shark roster should have 10 rows")
	_expect(_screen._food_rows.has("mahaze"), "food list should include valid inventory fish")
	_expect(not _screen._food_rows.has("nekozame"), "food list should exclude shark inventory entries")
	_expect(_screen._return_button != null, "return button should be present")
	_expect(_screen._feed_button != null, "feed button should be present")
	var tank_water := _screen.find_child("SharkPenAquariumWater", true, false) as TextureRect
	_expect(tank_water != null and tank_water.texture != null, "authored tank background should be visible")
	_expect(_screen.find_children("SharkPenCurrentLine", "ColorRect", true, false).is_empty(), "runtime tank lines should be removed")

	_screen._select_shark("nekozame")
	_screen._select_food("mahaze")
	await get_tree().process_frame
	_expect(
		String(_screen._feed_preview_label.text).contains("EXP +36"),
		"normal favorite preview should show 36 EXP"
	)
	PlayerProgress.difficulty_id = "hard"
	_screen._refresh_feed_state()
	_expect(
		String(_screen._feed_preview_label.text).contains("EXP +45"),
		"hard favorite preview should show 45 EXP"
	)
	_expect_selected_hover_matches_normal(_screen._shark_rows["nekozame"]["button"] as Button, "selected shark row")
	_expect_selected_hover_matches_normal(_screen._food_rows["mahaze"]["button"] as Button, "selected food row")
	var before_stock := PlayerProgress.fish_count("mahaze")
	var before_bond := int(PlayerProgress.shark_bonds.get("nekozame", 0))
	var before_exp := PlayerProgress.exp
	_screen._feed_selected()
	await get_tree().process_frame
	_expect(PlayerProgress.fish_count("mahaze") == before_stock - 1, "feeding should consume one fish")
	_expect(int(PlayerProgress.shark_bonds.get("nekozame", 0)) == before_bond + GameData.SHARK_FAVORITE_BOND_GAIN, "favorite feeding should add favorite bond")
	_expect(PlayerProgress.exp == before_exp + 45, "hard feeding should grant the previewed 45 EXP")
	_expect(String(_screen._message_label.text).contains("好物"), "favorite feeding message should mention favorite")
	_expect(String(_screen._message_label.text).contains("EXP +45"), "hard feed result should match preview")
	PlayerProgress.difficulty_id = GameData.DEFAULT_DIFFICULTY_ID

	_screen._select_food("buri")
	await get_tree().process_frame
	var depleted_stock := PlayerProgress.fish_count("buri")
	PlayerProgress.inventory["buri"] = 0
	_screen._feed_selected()
	await get_tree().process_frame
	_expect(String(_screen._message_label.text).contains("持っていません"), "zero-stock feed should show failure")
	_expect(PlayerProgress.fish_count("buri") == 0, "zero-stock feed should not mutate stock")
	PlayerProgress.inventory["buri"] = depleted_stock
	_screen._selected_food_id = "nekozame"
	_screen._feed_selected()
	await get_tree().process_frame
	_expect(String(_screen._message_label.text).contains("サメは餌にできません"), "shark-as-food feed should show failure")
	_expect(PlayerProgress.fish_count("nekozame") == 1, "shark-as-food rejection should not consume stock")

	_screen._select_shark("hohojirozame")
	await get_tree().process_frame
	_expect(not _screen._can_feed_selected(), "uncaught shark should not be feedable")
	_screen._feed_selected()
	await get_tree().process_frame
	_expect(String(_screen._message_label.text).contains("まだ"), "uncaught shark feed should fail with message")

	_screen._return_button.pressed.emit()
	_expect(_navigated_to == "harbor", "return button should navigate to harbor")

	if _failed:
		return
	print("shark_pen_screen_smoke: ok")
	get_tree().quit(0)


func _seed_progress() -> void:
	PlayerProgress.reset_game()
	PlayerProgress.level = 30
	PlayerProgress.exp = 120
	PlayerProgress.money = 23450
	PlayerProgress.owned_rods = ["starter", "iso", "offshore", "big_game"]
	PlayerProgress.equipped_rod_id = "big_game"
	PlayerProgress.inventory = {
		"mahaze": 3,
		"aji": 2,
		"buri": 1,
		"nekozame": 1,
	}
	PlayerProgress.caught_counts = {
		"nekozame": 1,
		"inuzame": 1,
		"mahaze": 3,
		"aji": 2,
		"buri": 1,
	}
	PlayerProgress.shark_bonds = {
		"nekozame": 24,
		"inuzame": 100,
	}
	PlayerProgress._remember_current_titles()


func _make_screen(payload: Dictionary = {}) -> Control:
	var screen := SharkPenScreenScript.new()
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


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)


func _expect_selected_hover_matches_normal(button: Button, label: String) -> void:
	var normal := button.get_theme_stylebox("normal") as StyleBoxFlat
	var hover := button.get_theme_stylebox("hover") as StyleBoxFlat
	var focus := button.get_theme_stylebox("focus") as StyleBoxFlat
	_expect(normal != null and hover != null and focus != null, "%s should define selected state styles" % label)
	if _failed:
		return
	_expect(hover.bg_color == normal.bg_color, "%s hover should keep selected text readable" % label)
	_expect(focus.bg_color == normal.bg_color, "%s focus should keep selected text readable" % label)
