extends Node

const FishBookScreenScript = preload("res://src/ui/fish_book_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")

var _screen: Variant
var _navigated_to := ""
var _payload: Dictionary = {}
var _failed := false


func _ready() -> void:
	_seed_progress()
	_screen = _make_screen()
	await get_tree().process_frame

	_expect(_screen._grid != null, "fish book grid should be present")
	_expect(_screen._detail_name_label != null, "fish detail name label should be present")
	_expect(_screen._detail_spots != null, "fish detail spot strip should be present")
	_expect(_screen._found_label.text.contains("6/"), "found count should reflect caught fish and nushi base page")
	_expect(_screen._player_status_bar._status_values()[1] == "蒼槍", "status bar should shorten long rod names")
	_expect(_screen._player_status_bar._status_values()[2] == "123,456 G", "status bar should format long money values")
	_expect(_screen._selected_fish_id == "aji", "first discovered fish should be selected")
	_expect(_screen._detail_name_label.text == "アジ", "discovered detail should show fish name")
	_expect(_screen._detail_habitat_label.text != "？？？", "discovered detail should show habitat")
	_expect(_screen._detail_spots.get_child_count() > 0, "discovered fish should show spot strip entries")

	_screen._select_fish("boss_kurodai")
	_expect(_screen._detail_name_label.text == "港のぬし・大岩クロダイ", "long boss fish name should be shown in full")
	_expect(_screen._detail_rarity_label.text == "ぬし", "boss rarity should be shown")

	_screen._select_fish("mejina")
	_expect(_screen._detail_name_label.text == "？？？？？", "undiscovered fish name should be hidden")
	_expect(_screen._detail_habitat_label.text.contains("まだ釣ったことがない"), "undiscovered detail should be hidden")

	_screen._set_filter("rare")
	_expect(_screen._active_filter == "rare", "rare filter should become active")
	_expect(_screen._filtered_fish_ids().has("madai"), "rare filter should include madai")
	_expect(_screen._selected_fish_id == "madai", "rare filter should select discovered rare fish")
	_expect(_screen._detail_name_label.text == "マダイ", "rare discovered fish should show detail")

	_screen._set_filter("nushi")
	_expect(_screen._active_filter == "nushi", "nushi filter should become active")
	_expect(_screen._filtered_fish_ids().has("hirame"), "nushi filter should include nushi base fish")
	_screen._select_fish("hirame")
	_expect(_screen._detail_name_label.text == "ヒラメ", "caught nushi should reveal base fish detail")
	_expect(_screen._detail_nushi_label.visible, "caught nushi should show nushi record row")
	_expect(_screen._detail_nushi_label.text.contains("砂底の座布団"), "nushi record row should name the nushi")

	_screen._set_filter("all")
	_screen._select_fish("medai")
	_expect(_screen._detail_name_label.text == "メダイ", "expanded fish should show detail")
	_expect(_screen._detail_spots.get_child_count() > 0, "expanded fish should show spot strip entries")

	PlayerProgress.caught_counts = {}
	PlayerProgress.best_sizes = {}
	PlayerProgress.spot_caught_counts = {}
	_screen._active_filter = "all"
	_screen._selected_fish_id = ""
	_screen._ensure_valid_selection()
	_screen._refresh_all()
	await get_tree().process_frame
	_expect(_screen._found_label.text.contains("0/"), "empty progress should show zero discovered fish")
	_expect(_screen._detail_name_label.text == "？？？？？", "empty progress detail should stay hidden")

	var return_button := _find_return_button(_screen)
	_expect(return_button != null, "return button should exist")
	if return_button != null:
		return_button.pressed.emit()
	_expect(_navigated_to == "harbor", "return button should navigate to harbor")

	if _failed:
		return
	print("fish_book_smoke: ok")
	get_tree().quit(0)


func _seed_progress() -> void:
	PlayerProgress.level = 4
	PlayerProgress.money = 123456
	PlayerProgress.equipped_rod_id = "marlin"
	PlayerProgress.caught_counts = {
		"aji": 12,
		"saba": 8,
		"madai": 2,
		"medai": 1,
		"boss_kurodai": 1,
		"nushi_shallow_sand": 1,
	}
	PlayerProgress.best_sizes = {
		"aji": 34.2,
		"saba": 38.6,
		"madai": 48.2,
		"medai": 72.4,
		"boss_kurodai": 88.8,
		"nushi_shallow_sand": 188.4,
	}
	PlayerProgress.spot_caught_counts = {
		"harbor_pier": {"aji": 12},
		"outer_tide": {"saba": 8},
		"south_reef": {"madai": 2},
		"deep_ocean": {"medai": 1},
		"harbor_boulder": {"boss_kurodai": 1},
	}


func _make_screen(payload: Dictionary = {}) -> Control:
	var screen := FishBookScreenScript.new()
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


func _find_return_button(root: Node) -> Button:
	for child in root.get_children():
		if child is Button and bool(child.get_meta("fish_book_return", false)):
			return child as Button
		var nested := _find_return_button(child)
		if nested != null:
			return nested
	return null


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
