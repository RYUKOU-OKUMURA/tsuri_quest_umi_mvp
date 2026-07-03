extends Node

const ShopScreenScript = preload("res://src/ui/shop_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")

const EXPANDED_VIEWPORT := Vector2i(2124, 1507)
const DESIGN_SIZE := Vector2(1280.0, 720.0)

var _screen: Variant
var _navigated_to := ""
var _payload: Dictionary = {}
var _failed := false


func _ready() -> void:
	_seed_progress()
	_screen = await _make_screen(EXPANDED_VIEWPORT)

	_expect(_screen._cards_layer != null, "card layer should be present")
	_expect(_screen._detail_title_label != null, "detail title should be present")
	_expect(_screen._action_button != null, "action button should be present")
	_expect(_screen._return_button != null, "return button should be present")
	_expect(_screen._design_canvas != null, "fixed design canvas should be present")
	_expect(_screen._design_canvas.size == DESIGN_SIZE, "design canvas should keep 1280x720 logical size")
	var expected_scale := minf(float(EXPANDED_VIEWPORT.x) / DESIGN_SIZE.x, float(EXPANDED_VIEWPORT.y) / DESIGN_SIZE.y)
	_expect(absf(_screen._design_canvas.scale.x - expected_scale) < 0.002, "design canvas should scale uniformly in expanded viewports")
	_expect(absf(_screen._design_canvas.scale.y - expected_scale) < 0.002, "design canvas y scale should match x scale")
	_expect(_screen._design_canvas.position.y > 100.0, "expanded viewport should letterbox instead of stretching the shop art")
	_expect(_find_item_lists(_screen).is_empty(), "old ItemList must not remain")
	_expect(_card_buttons(_screen, "rod").size() == GameData.get_all_rod_ids().size(), "rod cards should match rod data")
	_expect(_card_button(_screen, "rod", "big_game") != null, "big_game rod card should be present")
	_expect(_card_button(_screen, "rod", "marlin") != null, "marlin rod card should be present")
	_expect(_card_buttons(_screen, "rig").is_empty(), "rig cards should not render while rod tab is active")

	await _click_control(_card_button(_screen, "rod", "iso"))
	_expect(_screen._selected_item_id == "iso", "rod card selection should update selected item")
	_expect(not _screen._action_button.disabled, "affordable unowned rod should be purchasable")
	await _click_control(_screen._action_button)
	_expect("iso" in PlayerProgress.owned_rods, "purchased rod should be owned")
	_expect(PlayerProgress.equipped_rod_id == "iso", "purchased rod should be equipped")
	_expect(PlayerProgress.money == 150, "rod purchase should subtract money")

	PlayerProgress.money = 10000
	await _click_control(_card_button(_screen, "rod", "marlin"))
	_expect(not _screen._action_button.disabled, "marlin rod should be purchasable when affordable")
	await _click_control(_screen._action_button)
	_expect("marlin" in PlayerProgress.owned_rods, "marlin rod should be owned after purchase")
	_expect(PlayerProgress.equipped_rod_id == "marlin", "marlin rod should equip after purchase")
	_expect(PlayerProgress.money == 1000, "marlin purchase should subtract money")

	PlayerProgress.money = 3000
	await _click_control(_card_button(_screen, "rod", "big_game"))
	_expect(_screen._action_button.disabled, "unaffordable big_game rod should disable action")
	_expect(_screen._detail_status_label.text.contains("所持金"), "unaffordable rod should explain money shortage")

	PlayerProgress.money = 150
	await _click_control(_screen._rig_tab_button)
	_expect(_screen._shop_mode == "rig", "clicking rig tab should switch shop mode")
	_expect(_card_buttons(_screen, "rig").size() == GameData.get_all_rig_ids().size(), "rig cards should match rig data")
	_expect(_card_buttons(_screen, "rod").is_empty(), "rod cards should not render while rig tab is active")

	await _click_control(_screen._rod_tab_button)
	_expect(_screen._shop_mode == "rod", "clicking rod tab should switch shop mode back")
	await _click_control(_screen._rig_tab_button)
	_expect(_screen._shop_mode == "rig", "rig tab should remain clickable after returning from rod tab")

	await _click_control(_card_button(_screen, "rig", "chokusen"))
	_expect(_screen._action_button.disabled, "unaffordable rig should disable action")
	_expect(_screen._detail_status_label.text.contains("所持金"), "unaffordable rig should explain money shortage")

	PlayerProgress.money = 1000
	_screen._refresh()
	await _tick()
	_expect(not _screen._action_button.disabled, "affordable rig should enable action")
	await _click_control(_screen._action_button)
	_expect("chokusen" in PlayerProgress.owned_rigs, "purchased rig should be owned")
	_expect(PlayerProgress.equipped_rig_id == "chokusen", "purchased rig should be equipped")

	await _click_control(_card_button(_screen, "rig", "nomase"))
	_expect(_screen._action_button.disabled, "level-locked rig should disable action")
	_expect(_screen._action_button.text.contains("Lv.4"), "level-locked rig should show unlock level")

	await _click_control(_screen._return_button)
	_expect(_navigated_to == "harbor", "return button should navigate to harbor")

	if _failed:
		return
	print("tackle_shop_smoke: ok")
	get_tree().quit(0)


func _seed_progress() -> void:
	PlayerProgress.level = 2
	PlayerProgress.exp = 0
	PlayerProgress.money = 1000
	PlayerProgress.owned_rods = ["starter"]
	PlayerProgress.equipped_rod_id = "starter"
	PlayerProgress.owned_rigs = [GameData.DEFAULT_RIG_ID]
	PlayerProgress.equipped_rig_id = GameData.DEFAULT_RIG_ID
	PlayerProgress.owned_boats = []
	PlayerProgress.inventory = {}
	PlayerProgress.caught_counts = {}
	PlayerProgress.spot_caught_counts = {}
	PlayerProgress.best_sizes = {}
	PlayerProgress.pending_buff = {}


func _make_screen(viewport_size: Vector2i, payload: Dictionary = {}) -> Control:
	var viewport := SubViewport.new()
	viewport.name = "TackleShopSmokeViewport"
	viewport.size = viewport_size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)

	var screen := ShopScreenScript.new()
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
	return screen


func _card_buttons(root: Node, mode: String) -> Array[Button]:
	var buttons: Array[Button] = []
	_collect_card_buttons(root, mode, buttons)
	return buttons


func _card_button(root: Node, mode: String, item_id: String) -> Button:
	for button in _card_buttons(root, mode):
		if String(button.get_meta("shop_item_id", "")) == item_id:
			return button
	return null


func _collect_card_buttons(node: Node, mode: String, buttons: Array[Button]) -> void:
	for child in node.get_children():
		if child is Button and bool(child.get_meta("shop_item_card", false)):
			if String(child.get_meta("shop_mode", "")) == mode:
				buttons.append(child as Button)
		_collect_card_buttons(child, mode, buttons)


func _find_item_lists(root: Node) -> Array[ItemList]:
	var lists: Array[ItemList] = []
	_collect_item_lists(root, lists)
	return lists


func _collect_item_lists(node: Node, lists: Array[ItemList]) -> void:
	for child in node.get_children():
		if child is ItemList:
			lists.append(child as ItemList)
		_collect_item_lists(child, lists)


func _click_control(control: Control) -> void:
	if control == null:
		_fail("click target should exist.")
		return
	var rect := control.get_global_rect()
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		_fail("click target '%s' should have a non-zero rect, got %s." % [control.name, rect])
		return
	var position := rect.get_center()
	var viewport := control.get_viewport()
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	viewport.push_input(motion, true)
	var down := InputEventMouseButton.new()
	down.position = position
	down.global_position = position
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	viewport.push_input(down, true)
	var up := InputEventMouseButton.new()
	up.position = position
	up.global_position = position
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	viewport.push_input(up, true)
	await _tick()


func _tick() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)


func _fail(message: String) -> void:
	_failed = true
	push_error(message)
	get_tree().quit(1)
