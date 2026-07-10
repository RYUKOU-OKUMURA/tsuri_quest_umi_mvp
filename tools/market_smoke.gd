extends Node

const MarketScreenScript = preload("res://src/ui/market_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")

const EXPANDED_VIEWPORT := Vector2i(2124, 1507)
const DESIGN_SIZE := Vector2(1280.0, 720.0)

var _screen: Variant
var _navigated_to := ""
var _payload: Dictionary = {}
var _failed := false


func _ready() -> void:
	_test_batch_api()
	_seed_progress()
	_screen = await _make_screen(EXPANDED_VIEWPORT)

	_expect(_screen._design_canvas != null, "fixed design canvas should be present")
	_expect(_screen._design_canvas.size == DESIGN_SIZE, "design canvas should keep 1280x720 logical size")
	var expected_scale := minf(float(EXPANDED_VIEWPORT.x) / DESIGN_SIZE.x, float(EXPANDED_VIEWPORT.y) / DESIGN_SIZE.y)
	_expect(absf(_screen._design_canvas.scale.x - expected_scale) < 0.002, "design canvas should scale uniformly in expanded viewports")
	_expect(_find_item_lists(_screen).is_empty(), "old ItemList must not remain")
	_expect(_screen._row_nodes.size() == 7, "market should render seven fixed inventory rows")
	_expect(_screen._fish_ids.size() >= 8, "seed should exercise paged inventory")
	_expect(String((_screen._row_nodes[0]["name_label"] as Label).text).length() > 0, "row fish name should be populated")
	_expect(String(_screen._detail_title_label.text).length() > 0, "detail fish name should be populated")
	_expect(_screen._next_page_button.disabled == false, "next page should be available with more than seven fish")

	_screen._set_quantity("aji", 99)
	_expect_eq(int(_screen._sell_quantities.get("aji", 0)), 3, "quantity should clamp to owned count")
	_screen._set_quantity("aji", -4)
	_expect_eq(int(_screen._sell_quantities.get("aji", 0)), 0, "negative quantity should remove order")

	_screen._set_quantity("aji", 2)
	_screen._set_quantity("saba", 2)
	_screen._show_confirm_overlay()
	_expect(_screen._confirm_overlay.visible, "confirm overlay should open for selected fish")
	_expect(_screen._confirm_overlay.z_index > _screen._normal_detail_label.z_index, "confirm overlay should draw above market detail labels")
	_expect(String(_screen._confirm_body_label.text).contains("最後の1匹"), "last-fish warning should be shown")
	_screen._confirm_sell()
	_expect_eq(PlayerProgress.fish_count("aji"), 1, "batch sell should subtract aji")
	_expect_eq(PlayerProgress.fish_count("saba"), 0, "batch sell should subtract final saba")
	var screen_expected_income := int(GameData.get_fish("aji").get("sell_price", 0)) * 2 + int(GameData.get_fish("saba").get("sell_price", 0)) * 2
	_expect_eq(PlayerProgress.money, 1000 + screen_expected_income, "batch sell should add income once")
	_expect(_screen._confirm_overlay.visible == false, "confirm overlay should close after sale")

	_screen._select_all_fish()
	_screen._show_confirm_overlay()
	_expect(_screen._confirm_overlay.visible, "select all should create a sellable cart")
	_screen._confirm_sell()
	_expect(_screen._fish_ids.is_empty(), "selling everything should leave the market empty")
	_expect(String(_screen._detail_title_label.text).contains("査定台は空です"), "empty state should update detail title")
	_expect(_screen._inventory_empty_panel.visible, "empty inventory panel should be visible")
	_expect(_screen._inventory_empty_panel.position.y + _screen._inventory_empty_panel.size.y >= _screen._row_rect(6).end.y, "empty inventory panel should cover the final row area")
	_expect(_screen._detail_fish_image.texture == null, "empty state should clear the fish tray")
	_expect(_screen._empty_detail_label.visible, "empty state should display the dedicated detail message")
	_expect(not _screen._normal_detail_label.visible, "empty state should hide the normal detail bars")
	_expect(_screen._empty_detail_label.position == _screen.EMPTY_DETAIL_RECT.position and _screen._empty_detail_label.size == _screen.EMPTY_DETAIL_RECT.size, "empty detail message should cover the tray and placeholder bars")
	_expect(String(_screen._empty_detail_label.text).contains("次の釣果を待っています"), "empty state should explain the next action")

	PlayerProgress.inventory = {"aji": 1}
	_screen._refresh()
	await _tick()
	_expect(not _screen._inventory_empty_panel.visible, "inventory panel should hide after fish return")
	_expect(_screen._detail_fish_image.texture != null, "fish tray should return after fish return")
	_expect(not _screen._empty_detail_label.visible, "empty detail message should hide after fish return")
	_expect(_screen._normal_detail_label.visible, "normal detail message should return after fish return")
	PlayerProgress.inventory = {}
	_screen._refresh()
	await _tick()
	_expect(_screen._empty_detail_label.visible, "empty detail message should return after fish are sold again")

	_screen._return_button.pressed.emit()
	_expect(_navigated_to == "harbor", "return button should navigate to harbor")

	if _failed:
		return
	print("market_smoke: ok")
	get_tree().quit(0)


func _test_batch_api() -> void:
	PlayerProgress.money = 500
	PlayerProgress.inventory = {"aji": 3, "saba": 2}
	var expected_income := int(GameData.get_fish("aji").get("sell_price", 0)) * 2 + int(GameData.get_fish("saba").get("sell_price", 0))
	var result := PlayerProgress.sell_fish_batch({"aji": 2, "saba": 1, "madai": 0})
	_expect(bool(result.get("ok", false)), "sell_fish_batch should accept positive orders")
	_expect_eq(int(result.get("income", 0)), expected_income, "sell_fish_batch should report total income")
	_expect_eq(int(result.get("total_amount", 0)), 3, "sell_fish_batch should report total amount")
	_expect_eq(PlayerProgress.money, 500 + expected_income, "sell_fish_batch should add money")
	_expect_eq(PlayerProgress.fish_count("aji"), 1, "sell_fish_batch should subtract aji")
	var failed := PlayerProgress.sell_fish_batch({"saba": 99})
	_expect(not bool(failed.get("ok", false)), "sell_fish_batch should reject unavailable orders")


func _seed_progress() -> void:
	PlayerProgress.level = 3
	PlayerProgress.exp = 0
	PlayerProgress.money = 1000
	PlayerProgress.owned_rods = ["starter", "iso"]
	PlayerProgress.equipped_rod_id = "iso"
	PlayerProgress.owned_rigs = [GameData.DEFAULT_RIG_ID]
	PlayerProgress.equipped_rig_id = GameData.DEFAULT_RIG_ID
	PlayerProgress.owned_boats = []
	PlayerProgress.inventory = {
		"aji": 3,
		"saba": 2,
		"madai": 1,
		"kasago": 2,
		"mejina": 2,
		"iwashi": 4,
		"hirame": 1,
		"kawahagi": 1,
	}
	PlayerProgress.caught_counts = {
		"aji": 4,
		"saba": 2,
		"madai": 1,
		"kasago": 2,
		"mejina": 2,
		"iwashi": 4,
		"hirame": 1,
		"kawahagi": 1,
	}
	PlayerProgress.best_sizes = {}
	PlayerProgress.spot_caught_counts = {}
	PlayerProgress.pending_buff = {}


func _make_screen(viewport_size: Vector2i, payload: Dictionary = {}) -> Control:
	var viewport := SubViewport.new()
	viewport.name = "MarketSmokeViewport"
	viewport.size = viewport_size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)

	var screen := MarketScreenScript.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure(payload)
	screen.size = Vector2(viewport_size)
	screen.navigate_requested.connect(
		func(screen_id: String, payload: Dictionary) -> void:
			_navigated_to = screen_id
			_payload = payload.duplicate(true)
	)
	viewport.add_child(screen)
	await _tick()
	await _tick()
	return screen


func _find_item_lists(root: Node) -> Array[ItemList]:
	var lists: Array[ItemList] = []
	_collect_item_lists(root, lists)
	return lists


func _collect_item_lists(node: Node, lists: Array[ItemList]) -> void:
	for child in node.get_children():
		if child is ItemList:
			lists.append(child as ItemList)
		_collect_item_lists(child, lists)


func _tick() -> void:
	await get_tree().process_frame


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)


func _expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	_expect(actual == expected, "%s got=%s expected=%s" % [message, str(actual), str(expected)])
