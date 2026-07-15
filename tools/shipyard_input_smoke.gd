extends Node

const ShipyardScreenScript = preload("res://src/ui/shipyard_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const ProbeCommon = preload("res://tools/e11_probe_common.gd")

var _failed := false
var _navigation_count := 0
var _last_route := ""


func _ready() -> void:
	await _verify_insufficient_and_keyboard_graph()
	await _verify_purchasable_and_purchase_focus_fallback()
	await _verify_all_owned_state()
	await _verify_cancel_once()
	await _verify_mouse_regression()
	if _failed:
		return
	print("shipyard_input_smoke: ok")
	get_tree().quit(0)


func _verify_insufficient_and_keyboard_graph() -> void:
	_seed_progress(500, [])
	var screen: Variant = await _make_screen()
	var skiff := screen._boat_card_buttons.get("skiff") as Button
	var offshore := screen._boat_card_buttons.get("offshore_boat") as Button
	var bluewater := screen._boat_card_buttons.get("bluewater_boat") as Button
	_expect(screen._buy_button.disabled, "insufficient state should disable purchase")
	_expect(screen._buy_button.focus_mode == Control.FOCUS_NONE, "disabled purchase should leave the focus graph")
	_expect(get_viewport().gui_get_focus_owner() == skiff, "first unowned boat should receive safe initial focus")
	_expect(screen.keyboard_focus_candidates().size() == 4, "insufficient state should expose three cards and return")
	_expect(ProbeCommon.has_distinct_focus_style(skiff), "common focus style should differ from shipyard normal style")
	var focus_style := skiff.get_theme_stylebox("focus") as StyleBoxFlat
	_expect(
		focus_style != null
		and focus_style.border_color == Palette.GOLD_BRIGHT
		and focus_style.border_width_left == 4,
		"shipyard should retain the common 4px gold focus signature after local styling"
	)
	var focus_indicator := skiff.get_node_or_null(ScreenBase.COMMON_FOCUS_INDICATOR_NAME) as Panel
	_expect(focus_indicator != null and focus_indicator.visible, "focused card should expose the visible common focus indicator")
	await _send_key_action("ui_down")
	_expect(get_viewport().gui_get_focus_owner() == offshore, "down should move skiff to offshore")
	await _send_key_action("ui_down")
	_expect(get_viewport().gui_get_focus_owner() == bluewater, "down should move offshore to bluewater")
	await _send_key_action("ui_down")
	_expect(get_viewport().gui_get_focus_owner() == screen._return_button, "down should skip disabled purchase and reach return")
	var select_count := [0]
	offshore.pressed.connect(func() -> void: select_count[0] += 1)
	offshore.grab_focus()
	await _send_key_action("ui_accept")
	_expect(select_count[0] == 1, "one Enter should select one boat exactly once")
	_expect(screen._selected_boat_id == "offshore_boat", "Enter should select the focused boat card")
	await _free_screen(screen)


func _verify_purchasable_and_purchase_focus_fallback() -> void:
	_seed_progress(10000, [])
	var screen: Variant = await _make_screen()
	var skiff := screen._boat_card_buttons.get("skiff") as Button
	var offshore := screen._boat_card_buttons.get("offshore_boat") as Button
	_expect(not screen._buy_button.disabled, "enough money should enable purchase")
	_expect(screen.keyboard_focus_candidates().size() == 5, "purchasable state should expose all five operations")
	var reached: Dictionary = {}
	skiff.grab_focus()
	for _step in range(5):
		var owner: Control = get_viewport().gui_get_focus_owner()
		if owner != null:
			reached[owner] = true
		await _send_key_action("ui_focus_next")
	_expect(reached.size() == 5, "Tab should reach all three cards, purchase, and return")

	offshore.grab_focus()
	await _send_key_action("ui_accept")
	_expect(screen._selected_boat_id == "offshore_boat", "purchase transition fixture should select a non-default boat")
	var buy_count := [0]
	screen._buy_button.pressed.connect(func() -> void: buy_count[0] += 1)
	screen._buy_button.grab_focus()
	await _send_key_action("ui_accept")
	await _settle()
	_expect(buy_count[0] == 1, "one Enter should trigger purchase exactly once")
	_expect(PlayerProgress.has_boat("offshore_boat"), "keyboard purchase should register the selected boat")
	_expect(PlayerProgress.money == 1800, "keyboard purchase should subtract the price once")
	_expect(screen._buy_button.disabled, "successful purchase should disable the purchase button")
	_expect(screen._buy_button.focus_mode == Control.FOCUS_NONE, "disabled purchase should be removed from keyboard focus")
	_expect(get_viewport().gui_get_focus_owner() == offshore, "purchase disable transition should return focus to the selected non-default card")
	_expect(screen.keyboard_focus_candidates().size() == 4, "owned state should keep only safe enabled operations")
	await _free_screen(screen)


func _verify_all_owned_state() -> void:
	_seed_progress(999999, ["skiff", "offshore_boat", "bluewater_boat"])
	var screen: Variant = await _make_screen()
	var bluewater := screen._boat_card_buttons.get("bluewater_boat") as Button
	_expect(screen._selected_boat_id == "bluewater_boat", "all-owned state should select the final registered boat")
	_expect(screen._buy_button.disabled, "all-owned state should disable purchase")
	_expect(get_viewport().gui_get_focus_owner() == bluewater, "all-owned state should focus its selected enabled card")
	_expect(screen.keyboard_focus_candidates().size() == 4, "all-owned state should skip purchase but retain cards and return")
	await _send_key_action("ui_down")
	_expect(get_viewport().gui_get_focus_owner() == screen._return_button, "all-owned arrow graph should skip disabled purchase")
	await _free_screen(screen)


func _verify_cancel_once() -> void:
	_seed_progress(500, [])
	_reset_route()
	var screen: Variant = await _make_screen()
	var pressed := _keyboard_event_for_action("ui_cancel")
	_expect(pressed != null, "ui_cancel should have a real keyboard event")
	if pressed != null:
		pressed.pressed = true
		pressed.echo = false
		get_viewport().push_input(pressed, true)
		await get_tree().process_frame
		var echo := pressed.duplicate() as InputEventKey
		echo.echo = true
		get_viewport().push_input(echo, true)
		await get_tree().process_frame
		var released := pressed.duplicate() as InputEventKey
		released.pressed = false
		released.echo = false
		get_viewport().push_input(released, true)
		await _settle()
	_expect(_navigation_count == 1 and _last_route == "harbor", "one Escape press including echo should navigate once")
	await _free_screen(screen)


func _verify_mouse_regression() -> void:
	_seed_progress(999999, [])
	_reset_route()
	var screen: Variant = await _make_screen()
	var offshore := screen._boat_card_buttons.get("offshore_boat") as Button
	await _click_control(offshore)
	_expect(screen._selected_boat_id == "offshore_boat", "mouse click should continue selecting boat cards")
	var price: int = int(GameData.get_boat("offshore_boat").get("price", 0))
	var money_before: int = PlayerProgress.money
	await _click_control(screen._buy_button)
	_expect(PlayerProgress.has_boat("offshore_boat"), "mouse click should continue purchasing boats")
	_expect(PlayerProgress.money == money_before - price, "one mouse click should subtract the purchase price once")
	await _click_control(screen._return_button)
	_expect(_navigation_count == 1 and _last_route == "harbor", "mouse return should navigate to harbor once")
	await _free_screen(screen)


func _seed_progress(money: int, boats: Array) -> void:
	PlayerProgress.level = 5
	PlayerProgress.exp = 0
	PlayerProgress.money = money
	PlayerProgress.owned_boats.assign(boats)
	PlayerProgress.equipped_rod_id = "starter"


func _make_screen() -> Variant:
	var screen := ShipyardScreenScript.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({})
	screen.size = Vector2(1280.0, 720.0)
	screen.navigate_requested.connect(_capture_route)
	add_child(screen)
	await _settle()
	return screen


func _capture_route(screen_id: String, _payload: Dictionary) -> void:
	_navigation_count += 1
	_last_route = screen_id


func _reset_route() -> void:
	_navigation_count = 0
	_last_route = ""


func _send_key_action(action: StringName) -> void:
	var pressed := _keyboard_event_for_action(action)
	_expect(pressed != null, "%s should have a real keyboard event" % action)
	if pressed == null:
		return
	pressed.pressed = true
	pressed.echo = false
	get_viewport().push_input(pressed, true)
	await get_tree().process_frame
	var released := pressed.duplicate() as InputEventKey
	released.pressed = false
	released.echo = false
	get_viewport().push_input(released, true)
	await _settle()


func _keyboard_event_for_action(action: StringName) -> InputEventKey:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return event.duplicate() as InputEventKey
	return null


func _click_control(control: Control) -> void:
	var position := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	get_viewport().push_input(motion, true)
	var down := InputEventMouseButton.new()
	down.position = position
	down.global_position = position
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	get_viewport().push_input(down, true)
	var up := down.duplicate() as InputEventMouseButton
	up.pressed = false
	get_viewport().push_input(up, true)
	await _settle()


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _free_screen(screen: Node) -> void:
	screen.queue_free()
	await _settle()


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error("shipyard_input_smoke: %s" % message)
	get_tree().quit(1)
