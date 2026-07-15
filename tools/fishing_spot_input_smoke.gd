extends Node

const FishingSpotScreenScript = preload("res://src/ui/fishing_spot_select_screen.gd")
const FishingSpotMapViewScript = preload("res://src/ui/components/fishing_spot_map_view.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const ProbeCommon = preload("res://tools/e11_probe_common.gd")

var _failed := false
var _navigation_count := 0
var _last_route := ""
var _last_payload: Dictionary = {}


func _ready() -> void:
	await _verify_default_focus_graph()
	await _verify_enabled_rig_accept()
	await _verify_primary_accept_once()
	await _verify_cancel_once()
	await _verify_mouse_spot_regression()
	if _failed:
		return
	print("fishing_spot_input_smoke: ok")
	get_tree().quit(0)


func _verify_default_focus_graph() -> void:
	_seed_progress(1, [GameData.DEFAULT_RIG_ID])
	var screen: Variant = await _make_screen()
	var expected: Array[Control] = [
		screen._action_button,
		screen._return_button,
		screen._notebook_button,
		screen._menu_button,
	]
	_expect(screen._rig_cycle_button.disabled, "one owned rig should disable rig cycling")
	_expect(screen._rig_cycle_button.focus_mode == Control.FOCUS_NONE, "disabled rig action should leave the focus graph")
	_expect(screen.keyboard_focus_candidates() == expected, "default graph should contain only four enabled operations")
	_expect(_focus_owner() == screen._action_button, "safe primary action should receive initial focus")
	for control in expected:
		_expect(ProbeCommon.has_distinct_focus_style(control), "every enabled operation should have a distinct focus style")
	var focus_style := screen._action_button.get_theme_stylebox("focus") as StyleBoxFlat
	_expect(
		focus_style != null
		and focus_style.border_color == Palette.GOLD_BRIGHT
		and focus_style.border_width_left == 4,
		"primary action should use the common 4px gold focus signature"
	)
	var indicator := screen._action_button.get_node_or_null(ScreenBase.COMMON_FOCUS_INDICATOR_NAME) as Panel
	_expect(indicator != null and indicator.visible, "initial focus should be visible at actual runtime")

	await _send_key_action(&"ui_down")
	_expect(_focus_owner() == screen._return_button, "down should move primary action to return")
	await _send_key_action(&"ui_down")
	_expect(_focus_owner() == screen._notebook_button, "down should reach notebook")
	await _send_key_action(&"ui_down")
	_expect(_focus_owner() == screen._menu_button, "down should reach menu")
	await _send_key_action(&"ui_down")
	_expect(_focus_owner() == screen._action_button, "down should close the graph without reaching disabled rig")
	await _send_key_action(&"ui_up")
	_expect(_focus_owner() == screen._menu_button, "up should reverse the closed graph")
	await _send_key_action(&"ui_right")
	_expect(_focus_owner() == screen._action_button, "right should advance the closed graph")
	await _send_key_action(&"ui_left")
	_expect(_focus_owner() == screen._menu_button, "left should reverse the closed graph")
	await _send_key_action(&"ui_focus_next")
	_expect(_focus_owner() == screen._action_button, "Tab should advance the closed graph")
	await _send_key_action(&"ui_focus_prev")
	_expect(_focus_owner() == screen._menu_button, "Shift+Tab should reverse the closed graph")

	screen._action_button.grab_focus()
	await _settle()
	await _capture_if_requested()
	await _free_screen(screen)


func _verify_enabled_rig_accept() -> void:
	_seed_progress(3, [GameData.DEFAULT_RIG_ID, "chokusen"])
	var screen: Variant = await _make_screen()
	_expect(not screen._rig_cycle_button.disabled, "two owned rigs should enable rig cycling")
	_expect(screen.keyboard_focus_candidates().size() == 5, "enabled rig state should expose all five operations")
	var reached := {}
	screen._rig_cycle_button.grab_focus()
	for _step in range(5):
		var owner := _focus_owner()
		if owner != null:
			reached[owner.get_instance_id()] = true
		await _send_key_action(&"ui_focus_next")
	_expect(reached.size() == 5, "Tab should reach every enabled operation")

	var press_count := [0]
	screen._rig_cycle_button.pressed.connect(func() -> void: press_count[0] += 1)
	screen._rig_cycle_button.grab_focus()
	await _send_key_action(&"ui_accept")
	_expect(press_count[0] == 1, "one Enter should activate rig cycling exactly once")
	_expect(PlayerProgress.equipped_rig_id == "chokusen", "keyboard rig cycling should keep the existing action contract")
	await _free_screen(screen)


func _verify_primary_accept_once() -> void:
	_seed_progress(1, [GameData.DEFAULT_RIG_ID])
	_reset_route()
	var screen: Variant = await _make_screen()
	var press_count := [0]
	screen._action_button.pressed.connect(func() -> void: press_count[0] += 1)
	screen._action_button.grab_focus()
	await _send_key_action(&"ui_accept")
	_expect(press_count[0] == 1, "one Enter should activate the primary action exactly once")
	_expect(_navigation_count == 1 and _last_route == "fishing", "primary Enter should navigate to fishing exactly once")
	_expect(String(_last_payload.get("spot_id", "")) == GameData.DEFAULT_FISHING_SPOT_ID, "primary Enter should keep the selected spot payload")
	await _free_screen(screen)


func _verify_cancel_once() -> void:
	_seed_progress(1, [GameData.DEFAULT_RIG_ID])
	_reset_route()
	var screen: Variant = await _make_screen()
	var pressed := _keyboard_event_for_action(&"ui_cancel")
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
	_expect(_navigation_count == 1 and _last_route == "harbor", "one Escape press including echo should navigate to harbor exactly once")
	await _free_screen(screen)


func _verify_mouse_spot_regression() -> void:
	_seed_progress(1, [GameData.DEFAULT_RIG_ID])
	var screen: Variant = await _make_screen()
	screen._action_button.grab_focus()
	await _click_map_spot(screen._map_view, "danger_reef")
	_expect(screen._selected_spot_id == "danger_reef", "mouse should continue focusing a locked map spot")
	_expect(screen._action_button.disabled, "locked mouse spot should keep the existing disabled action state")
	_expect(screen._action_button.focus_mode == Control.FOCUS_NONE, "locked action should leave the focus graph")
	_expect(_focus_owner() == screen._return_button, "locked mouse spot should move focus to a safe enabled fallback")
	_expect(screen._message_label.text == String(GameData.get_fishing_spot("danger_reef").get("name", "")), "locked mouse spot should keep the lock message contract")

	await _click_map_spot(screen._map_view, GameData.DEFAULT_FISHING_SPOT_ID)
	_expect(screen._selected_spot_id == GameData.DEFAULT_FISHING_SPOT_ID, "mouse should continue selecting an accessible map spot")
	_expect(not screen._action_button.disabled, "accessible mouse spot should restore the primary action")
	_expect(screen._action_button.focus_mode == Control.FOCUS_ALL, "restored primary action should rejoin the focus graph")
	_expect(screen.keyboard_focus_candidates().size() == 4, "restored graph should still exclude the disabled rig action")
	await _free_screen(screen)


func _seed_progress(level: int, rigs: Array) -> void:
	PlayerProgress.level = level
	PlayerProgress.exp = 0
	PlayerProgress.money = 1000
	PlayerProgress.owned_boats = []
	PlayerProgress.owned_rigs.assign(rigs)
	PlayerProgress.equipped_rig_id = String(rigs[0]) if not rigs.is_empty() else GameData.DEFAULT_RIG_ID
	PlayerProgress.sea_chart_fragments = 0
	PlayerProgress.inventory = {}


func _make_screen() -> Variant:
	var screen := FishingSpotScreenScript.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({})
	screen.size = Vector2(1280.0, 720.0)
	screen.navigate_requested.connect(_capture_route)
	add_child(screen)
	await _settle()
	await _settle()
	return screen


func _capture_route(screen_id: String, payload: Dictionary) -> void:
	_navigation_count += 1
	_last_route = screen_id
	_last_payload = payload.duplicate(true)


# 実製品と同じく親AppがBGMを所有し、入力fixture内にfallback playerを残さない。
func play_app_bgm(_path: String, _volume_db: float) -> void:
	pass


func stop_app_bgm(_path: String) -> void:
	pass


func _reset_route() -> void:
	_navigation_count = 0
	_last_route = ""
	_last_payload = {}


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


func _click_map_spot(map_view: Control, spot_id: String) -> void:
	var normalized: Vector2 = FishingSpotMapViewScript.SPOT_POINTS.get(spot_id, Vector2.ZERO)
	var position := map_view.get_global_rect().position + normalized * map_view.size
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	get_viewport().push_input(motion, true)
	var down := InputEventMouseButton.new()
	down.position = position
	down.global_position = position
	down.button_index = MOUSE_BUTTON_LEFT
	down.button_mask = MOUSE_BUTTON_MASK_LEFT
	down.pressed = true
	get_viewport().push_input(down, true)
	var up := down.duplicate() as InputEventMouseButton
	up.button_mask = 0
	up.pressed = false
	get_viewport().push_input(up, true)
	await _settle()


func _capture_if_requested() -> void:
	var output_path := OS.get_environment("TSURI_FISHING_SPOT_INPUT_CAPTURE")
	if output_path.is_empty():
		return
	RenderingServer.force_draw(false)
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	_expect(image != null and image.get_size() == Vector2i(1280, 720), "focus evidence should be an actual 1280x720 viewport capture")
	if image == null:
		return
	var error := image.save_png(output_path)
	_expect(error == OK, "focus evidence should be written")


func _focus_owner() -> Control:
	return get_viewport().gui_get_focus_owner()


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _free_screen(screen: Node) -> void:
	if screen != null and is_instance_valid(screen):
		if screen.has_method("stop_screen_bgm"):
			screen.call("stop_screen_bgm")
			await _settle()
		screen.queue_free()
	await _settle()
	get_viewport().gui_release_focus()


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error("fishing_spot_input_smoke: %s" % message)
	get_tree().quit(1)
