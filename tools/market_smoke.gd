extends Node

const MarketScreenScript = preload("res://src/ui/market_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")

const EXPANDED_VIEWPORT := Vector2i(2124, 1507)
const DESIGN_SIZE := Vector2(1280.0, 720.0)
const DETAIL_TRAY_DECORATION_RECT := Rect2(738.0, 184.0, 380.0, 188.0)
const DETAIL_RARITY_DECORATION_RECT := Rect2(1138.0, 152.0, 62.0, 90.0)
const DETAIL_LOWER_DECORATION_RECT := Rect2(724.0, 382.0, 494.0, 104.0)

var _screen: Variant
var _navigated_to := ""
var _payload: Dictionary = {}
var _failed := false


func _ready() -> void:
	_test_batch_api()
	await _test_saturating_cart_flow()
	_seed_progress()
	_screen = await _make_screen(EXPANDED_VIEWPORT)

	_expect(_screen._design_canvas != null, "fixed design canvas should be present")
	_expect(_screen._design_canvas.size == DESIGN_SIZE, "design canvas should keep 1280x720 logical size")
	_expect(_screen._market_asset_slots.size() == 6, "market should render six decomposed asset slots")
	_expect(_screen.find_child("FishMarketBackplate", true, false) == null, "legacy monolithic backplate node must not remain")
	for slot: TextureRect in _screen._market_asset_slots:
		_expect(slot.texture != null, "%s should load its decomposed texture" % slot.name)
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
	_expect(String(_screen._empty_detail_label.text).contains("査定台は空です"), "empty state should update the dedicated message")
	_expect(_screen._inventory_empty_panel.visible, "empty inventory panel should be visible")
	var inventory_cover := _control_rect(_screen._inventory_empty_panel)
	for row_index in range(_screen._row_nodes.size()):
		var row: Dictionary = _screen._row_nodes[row_index]
		var row_residual := _control_rect(row["highlight"] as Control)
		row_residual = row_residual.merge(_control_rect(row["pointer"] as Control))
		row_residual = row_residual.merge(_control_rect(row["select_button"] as Control))
		_expect_rect_contains(inventory_cover, row_residual, "empty inventory cover must contain row %d in both axes" % row_index)
		for key in row.keys():
			var control := row[key] as Control
			_expect(control == null or not control.visible, "empty inventory must hide row %d control %s" % [row_index, key])
	_expect(_screen._detail_fish_image.texture == null and not _screen._detail_fish_image.visible, "empty state should remove the fish tray")
	_expect(_screen._empty_detail_label.visible, "empty state should display the dedicated detail message")
	_expect(not _screen._detail_title_label.visible, "empty state should hide the normal detail title")
	_expect(not _screen._detail_rarity_label.visible, "empty state should hide the normal rarity label")
	_expect(not _screen._normal_detail_label.visible, "empty state should hide the normal detail body")
	_expect(not _screen._detail_price_label.visible and not _screen._detail_count_label.visible and not _screen._detail_subtotal_label.visible, "empty state should hide the normal detail prices")
	var detail_cover := _control_rect(_screen._empty_detail_label)
	_expect_rect_contains(detail_cover, _control_rect(_screen._detail_title_label), "empty detail cover must contain the detail title")
	_expect_rect_contains(detail_cover, _control_rect(_screen._detail_fish_image), "empty detail cover must contain the fish tray")
	_expect_rect_contains(detail_cover, _control_rect(_screen._detail_rarity_label), "empty detail cover must contain the rarity frame")
	_expect_rect_contains(detail_cover, _control_rect(_screen._normal_detail_label), "empty detail cover must contain the detail body")
	_expect_rect_contains(detail_cover, _control_rect(_screen._detail_price_label), "empty detail cover must contain the unit price")
	_expect_rect_contains(detail_cover, _control_rect(_screen._detail_count_label), "empty detail cover must contain the owned count")
	_expect_rect_contains(detail_cover, _control_rect(_screen._detail_subtotal_label), "empty detail cover must contain the selected total")
	_expect_rect_contains(detail_cover, DETAIL_TRAY_DECORATION_RECT, "empty detail cover must contain the ice tray and leaf decoration")
	_expect_rect_contains(detail_cover, DETAIL_RARITY_DECORATION_RECT, "empty detail cover must contain the rarity frame and diamonds")
	_expect_rect_contains(detail_cover, DETAIL_LOWER_DECORATION_RECT, "empty detail cover must contain the price frame, coin, and wave decoration")
	_expect(String(_screen._empty_detail_label.text).contains("次の釣果を待っています"), "empty state should explain the next action")

	PlayerProgress.inventory = {"aji": 1}
	_screen._refresh()
	await _tick()
	_expect(not _screen._inventory_empty_panel.visible, "inventory panel should hide after fish return")
	_expect(_screen._detail_fish_image.texture != null and _screen._detail_fish_image.visible, "fish tray should return after fish return")
	_expect(not _screen._empty_detail_label.visible, "empty detail message should hide after fish return")
	_expect(_screen._detail_title_label.visible and _screen._detail_rarity_label.visible, "normal detail header should return after fish return")
	_expect(_screen._normal_detail_label.visible, "normal detail message should return after fish return")
	_expect(_screen._detail_price_label.visible and _screen._detail_count_label.visible and _screen._detail_subtotal_label.visible, "normal detail prices should return after fish return")
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
	var quote := PlayerProgress.quote_fish_sale({"aji": 2, "saba": 1, "madai": 0})
	_expect(bool(quote.get("ok", false)), "quote_fish_sale should accept positive orders")
	_expect_eq(int(quote.get("income", 0)), expected_income, "quote_fish_sale should report normal income")
	_expect_eq(int(quote.get("amount", 0)), 3, "quote_fish_sale should report normal amount")
	_expect_eq(int(quote.get("types", 0)), 2, "quote_fish_sale should report normal fish types")
	_expect_eq(PlayerProgress.money, 500, "quote_fish_sale should not mutate money")
	_expect_eq(PlayerProgress.fish_count("aji"), 3, "quote_fish_sale should not mutate inventory")
	var result := PlayerProgress.sell_fish_batch({"aji": 2, "saba": 1, "madai": 0})
	_expect(bool(result.get("ok", false)), "sell_fish_batch should accept positive orders")
	_expect_eq(int(result.get("income", 0)), int(quote.get("income", 0)), "sell_fish_batch should match quoted income")
	_expect_eq(int(result.get("total_amount", 0)), int(quote.get("amount", 0)), "sell_fish_batch should match quoted amount")
	_expect_eq(PlayerProgress.money, 500 + expected_income, "sell_fish_batch should add money")
	_expect_eq(PlayerProgress.fish_count("aji"), 1, "sell_fish_batch should subtract aji")
	var failed := PlayerProgress.sell_fish_batch({"saba": 99})
	_expect(not bool(failed.get("ok", false)), "sell_fish_batch should reject unavailable orders")


func _test_saturating_cart_flow() -> void:
	var max_safe := PlayerProgress.MAX_SAFE_JSON_INTEGER
	var overflow_sell_amount := 1281023894007608
	var remaining_amount := max_safe - overflow_sell_amount
	PlayerProgress.money = 500
	PlayerProgress.inventory = {
		"nushi_deep_ocean": overflow_sell_amount,
		"aji": remaining_amount,
	}

	var boundary_screen := await _make_screen(Vector2i(DESIGN_SIZE))
	boundary_screen._select_all_fish()
	var summary: Dictionary = boundary_screen._cart_summary()
	_expect(bool(summary.get("ok", false)), "MAX_SAFE cart quote should be valid")
	_expect_eq(int(summary.get("income", 0)), max_safe, "MAX_SAFE cart income should saturate")
	_expect_eq(int(summary.get("amount", 0)), max_safe, "MAX_SAFE cart amount should remain safe")
	_expect_eq(int(summary.get("types", 0)), 2, "MAX_SAFE cart should count selected fish types")
	_expect_eq(PlayerProgress.money, 500, "MAX_SAFE cart quote should not mutate money")
	_expect_eq(PlayerProgress.fish_count("nushi_deep_ocean"), overflow_sell_amount, "MAX_SAFE cart quote should not mutate inventory")
	_expect_eq(String(boundary_screen._detail_subtotal_label.text), "選択 %s G" % ScreenBase.format_money(max_safe), "detail subtotal should render the safe quote")
	_expect_eq(String(boundary_screen._cart_total_label.text), "%s G" % ScreenBase.format_money(max_safe), "cart total should render the safe quote")
	_expect_eq(String(boundary_screen._cart_action_button.text), "売却 %d匹" % max_safe, "cart action should render the safe amount")

	boundary_screen._show_confirm_overlay()
	_expect(boundary_screen._confirm_overlay.visible, "MAX_SAFE cart confirm overlay should open")
	var confirm_body := String(boundary_screen._confirm_body_label.text)
	_expect(confirm_body.contains("%d匹" % max_safe), "confirm overlay should render the safe amount")
	_expect(confirm_body.contains("%s G" % ScreenBase.format_money(max_safe)), "confirm overlay should render the safe income")

	var result: Dictionary = boundary_screen._confirm_sell()
	_expect(bool(result.get("ok", false)), "MAX_SAFE cart should sell successfully")
	_expect_eq(int(result.get("income", 0)), int(summary.get("income", 0)), "confirmed income should match the displayed quote")
	_expect_eq(int(result.get("total_amount", 0)), int(summary.get("amount", 0)), "confirmed amount should match the displayed quote")
	_expect_eq(PlayerProgress.money, max_safe, "confirmed sale should saturate money")
	_expect_eq(PlayerProgress.fish_count("nushi_deep_ocean"), 0, "confirmed sale should subtract the high-price fish")
	_expect_eq(PlayerProgress.fish_count("aji"), 0, "confirmed sale should subtract the remaining fish")

	boundary_screen.get_parent().queue_free()
	await _tick()


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


func _control_rect(control: Control) -> Rect2:
	return Rect2(control.position, control.size)


func _expect_rect_contains(cover: Rect2, target: Rect2, message: String) -> void:
	var contains_horizontally := cover.position.x <= target.position.x and cover.end.x >= target.end.x
	var contains_vertically := cover.position.y <= target.position.y and cover.end.y >= target.end.y
	_expect(contains_horizontally and contains_vertically, "%s: cover=%s target=%s" % [message, cover, target])


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)


func _expect_eq(actual: Variant, expected: Variant, message: String) -> void:
	_expect(actual == expected, "%s got=%s expected=%s" % [message, str(actual), str(expected)])
