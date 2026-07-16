extends Node

const HarborScreenScript = preload("res://src/ui/harbor_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const ProbeCommon = preload("res://tools/e11_probe_common.gd")

const EVIDENCE_DEFAULT := "2026-07-16_input_default_focus.png"
const EVIDENCE_LOCKED := "2026-07-16_input_locked_time_focus.png"
const EVIDENCE_UNLOCKED := "2026-07-16_input_unlocked_time_focus.png"

var _failed := false
var _navigation_count := 0
var _last_route := ""
var _last_payload: Dictionary = {}


func _ready() -> void:
	var capture_state := OS.get_environment("TSURI_HARBOR_INPUT_CAPTURE").strip_edges()
	if not capture_state.is_empty():
		await _capture_fixture(capture_state)
		if _failed:
			return
		print("harbor_input_smoke: capture ok")
		get_tree().quit(0)
		return
	await _verify_low_level_disabled_skip()
	await _verify_dynamic_unlock_and_restore()
	await _verify_keyboard_activation_once()
	await _verify_mouse_route_and_time_regression()
	await _verify_cancel_none_contract()
	if _failed:
		return
	print("harbor_input_smoke: ok")
	get_tree().quit(0)


func _verify_low_level_disabled_skip() -> void:
	_seed_progress(1)
	var screen := await _make_screen()
	var cta := screen._route_buttons.get("fishing_spots") as Button
	var daytime := screen._time_slot_buttons.get("daytime") as Button
	var asa := screen._time_slot_buttons.get("asa_mazume") as Button
	var night := screen._time_slot_buttons.get("night") as Button
	_expect(_focus_owner() == cta, "Lv1 harbor should keep the departure CTA as initial focus")
	_expect(asa.disabled and night.disabled, "Lv1 should lock morning and night")
	_expect(asa.focus_mode == Control.FOCUS_NONE, "locked morning should leave the focus graph")
	_expect(night.focus_mode == Control.FOCUS_NONE, "locked night should leave the focus graph")
	_expect(daytime.focus_mode == Control.FOCUS_ALL, "enabled daytime should stay in the focus graph")
	_expect(ProbeCommon.has_distinct_focus_style(cta), "initial CTA should have a visible focus signature")
	_expect(ProbeCommon.has_distinct_focus_style(daytime), "enabled time slot should have a visible focus signature")

	await _send_action(&"ui_left")
	_expect(_focus_owner() == daytime, "Left from CTA should skip both locked slots and reach daytime")
	_expect(_visible_focus_style(daytime), "daytime focus should be visible at actual runtime")
	await _send_action(&"ui_right")
	_expect(_focus_owner() == cta, "Right from the only enabled time slot should return to CTA")

	var expected := _enabled_controls(screen)
	var reached := {}
	for _step in range(expected.size()):
		var owner := _focus_owner()
		if owner != null:
			reached[owner.get_instance_id()] = true
		await _send_action(&"ui_focus_next")
	_expect(reached.size() == expected.size(), "Tab should reach every enabled route/time/system/record control")
	for control in expected:
		_expect(reached.has(control.get_instance_id()), "Tab should not isolate enabled control: %s" % control.name)
		_expect(not (control is BaseButton and (control as BaseButton).disabled), "Tab should never reach a disabled control")
	await _free_screen(screen)


func _verify_dynamic_unlock_and_restore() -> void:
	_seed_progress(1)
	var screen := await _make_screen()
	var cta := screen._route_buttons.get("fishing_spots") as Button
	var asa := screen._time_slot_buttons.get("asa_mazume") as Button
	var daytime := screen._time_slot_buttons.get("daytime") as Button
	var night := screen._time_slot_buttons.get("night") as Button
	var frozen_rects := _time_slot_rects(screen)
	var locked_graph := _time_slot_graph(screen)

	PlayerProgress.level = 15
	screen._refresh_labels()
	await _settle()
	_expect(not asa.disabled and not night.disabled, "Lv15 refresh should unlock every time slot")
	_expect(asa.focus_mode == Control.FOCUS_ALL and night.focus_mode == Control.FOCUS_ALL, "newly unlocked slots should rejoin focus")
	_expect(_time_slot_rects(screen) == frozen_rects, "unlock should not move any frozen time-slot rectangle")
	cta.grab_focus()
	await _send_action(&"ui_left")
	_expect(_focus_owner() == night, "CTA left should reach the rightmost enabled time slot")
	await _send_action(&"ui_left")
	_expect(_focus_owner() == daytime, "time-slot graph should continue through daytime")
	await _send_action(&"ui_left")
	_expect(_focus_owner() == asa, "time-slot graph should reach newly unlocked morning")
	_expect(_visible_focus_style(asa), "newly unlocked morning should expose visible focus")

	PlayerProgress.level = 1
	screen._refresh_labels()
	await _settle()
	_expect(asa.disabled and night.disabled, "A to B to A refresh should restore both locks")
	_expect(asa.focus_mode == Control.FOCUS_NONE and night.focus_mode == Control.FOCUS_NONE, "relocked slots should leave focus again")
	_expect(_focus_owner() == cta, "relocking the focused morning slot should fall back to the safe CTA")
	_expect(_time_slot_rects(screen) == frozen_rects, "A to B to A should restore every frozen rectangle")
	_expect(_time_slot_graph(screen) == locked_graph, "A to B to A should restore the locked focus graph")
	await _free_screen(screen)


func _capture_fixture(capture_state: String) -> void:
	var file_name := ""
	match capture_state:
		"default":
			_seed_progress(1)
			file_name = EVIDENCE_DEFAULT
		"locked":
			_seed_progress(1)
			file_name = EVIDENCE_LOCKED
		"unlocked":
			_seed_progress(15)
			file_name = EVIDENCE_UNLOCKED
		_:
			_expect(false, "unknown capture state: %s" % capture_state)
			return
	var screen := await _make_screen()
	var cta := screen._route_buttons.get("fishing_spots") as Button
	if capture_state == "locked":
		await _send_action(&"ui_left")
		_expect(_focus_owner() == screen._time_slot_buttons.get("daytime"), "locked capture should focus daytime")
	elif capture_state == "unlocked":
		cta.grab_focus()
		await _send_action(&"ui_right")
		_expect(_focus_owner() == screen._time_slot_buttons.get("asa_mazume"), "unlocked capture should focus morning")
	else:
		_expect(_focus_owner() == cta, "default capture should focus CTA")
	await _capture(file_name)
	await _free_screen(screen)


func _verify_keyboard_activation_once() -> void:
	_seed_progress(15)
	_reset_route()
	var screen := await _make_screen()
	var market := screen._route_buttons.get("market") as Button
	var market_pressed := [0]
	market.pressed.connect(func() -> void: market_pressed[0] += 1)
	market.grab_focus()
	await _send_action_with_echo(&"ui_accept")
	_expect(market_pressed[0] == 1, "one Enter including echo should press a route exactly once")
	_expect(_navigation_count == 1 and _last_route == "market", "one Enter should navigate to market exactly once")

	var night := screen._time_slot_buttons.get("night") as Button
	var night_pressed := [0]
	night.pressed.connect(func() -> void: night_pressed[0] += 1)
	night.grab_focus()
	await _send_action_with_echo(&"ui_accept")
	_expect(night_pressed[0] == 1, "one Enter including echo should press a time slot exactly once")
	_expect(PlayerProgress.selected_time_slot_id == "night", "keyboard Enter should keep the existing time selection contract")
	await _free_screen(screen)


func _verify_mouse_route_and_time_regression() -> void:
	_seed_progress(15)
	_reset_route()
	var screen := await _make_screen()
	var asa := screen._time_slot_buttons.get("asa_mazume") as Button
	await _click_control(asa)
	_expect(PlayerProgress.selected_time_slot_id == "asa_mazume", "real mouse click should still select morning")
	var quest := screen._route_buttons.get("quest_board") as Button
	await _click_control(quest)
	_expect(_navigation_count == 1 and _last_route == "quest_board", "real mouse click should navigate a route exactly once")
	await _free_screen(screen)


func _verify_cancel_none_contract() -> void:
	_seed_progress(1)
	_reset_route()
	var screen := await _make_screen()
	await _send_action_with_echo(&"ui_cancel")
	_expect(_navigation_count == 0 and _last_route.is_empty(), "harbor cancel:none should keep Escape side-effect free")
	await _free_screen(screen)


func _enabled_controls(screen: Control) -> Array[Control]:
	var result: Array[Control] = []
	result.append(screen._settings_button)
	for route_id in screen._route_buttons:
		var route := screen._route_buttons.get(route_id) as Button
		if route.focus_mode != Control.FOCUS_NONE and not route.disabled:
			result.append(route)
	for time_slot_id in GameData.get_all_time_slot_ids():
		var time_slot := screen._time_slot_buttons.get(time_slot_id) as Button
		if time_slot.focus_mode != Control.FOCUS_NONE and not time_slot.disabled:
			result.append(time_slot)
	return result


func _time_slot_rects(screen: Control) -> Dictionary:
	var result := {}
	for time_slot_id in GameData.get_all_time_slot_ids():
		var button := screen._time_slot_buttons.get(time_slot_id) as Button
		result[time_slot_id] = button.get_global_rect()
	return result


func _time_slot_graph(screen: Control) -> Dictionary:
	var result := {}
	var cta := screen._route_buttons.get("fishing_spots") as Button
	for time_slot_id in GameData.get_all_time_slot_ids():
		var button := screen._time_slot_buttons.get(time_slot_id) as Button
		result[time_slot_id] = {
			"focus_mode": button.focus_mode,
			"left": button.focus_neighbor_left,
			"right": button.focus_neighbor_right,
		}
	result["cta"] = {
		"left": cta.focus_neighbor_left,
		"right": cta.focus_neighbor_right,
	}
	return result


func _seed_progress(level: int) -> void:
	PlayerProgress.level = level
	PlayerProgress.exp = 0
	PlayerProgress.money = 50080
	PlayerProgress.inventory = {}
	PlayerProgress.equipped_rod_id = "big_game"
	PlayerProgress.play_seconds = 3178.0
	PlayerProgress.selected_time_slot_id = GameData.DEFAULT_TIME_SLOT_ID
	PlayerProgress.pending_buff = {}
	PlayerProgress.caught_counts = {}
	PlayerProgress.quest_board = []
	PlayerProgress.eaten_recipes = {"shioyaki": 1}
	PlayerProgress.owned_boats = ["bluewater_boat"]
	PlayerProgress.sea_chart_fragments = 3
	PlayerProgress.shark_bonds = {}


func _make_screen() -> Control:
	var screen := HarborScreenScript.new()
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


func _reset_route() -> void:
	_navigation_count = 0
	_last_route = ""
	_last_payload = {}


func _send_action(action: StringName) -> void:
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


func _send_action_with_echo(action: StringName) -> void:
	var pressed := _keyboard_event_for_action(action)
	_expect(pressed != null, "%s should have a real keyboard event" % action)
	if pressed == null:
		return
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


func _keyboard_event_for_action(action: StringName) -> InputEventKey:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return event.duplicate() as InputEventKey
	return null


func _click_control(control: Control) -> void:
	_expect(control != null, "mouse target should exist")
	if control == null:
		return
	var position := control.get_global_rect().get_center()
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
	await get_tree().process_frame
	var up := down.duplicate() as InputEventMouseButton
	up.button_mask = 0
	up.pressed = false
	get_viewport().push_input(up, true)
	await _settle()


func _capture(file_name: String) -> void:
	var output_dir := OS.get_environment("TSURI_HARBOR_INPUT_EVIDENCE_DIR").strip_edges()
	if output_dir.is_empty():
		return
	var make_error := DirAccess.make_dir_recursive_absolute(output_dir)
	_expect(make_error == OK or make_error == ERR_ALREADY_EXISTS, "evidence directory should be writable")
	RenderingServer.force_draw(true)
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	_expect(image != null and image.get_size() == Vector2i(1280, 720), "focus evidence should be an exact 1280x720 runtime capture")
	if image == null:
		return
	_expect(image.save_png(output_dir.path_join(file_name)) == OK, "focus evidence should be saved: %s" % file_name)


func _visible_focus_style(control: Control) -> bool:
	return control.has_focus() and ProbeCommon.has_distinct_focus_style(control)


func _focus_owner() -> Control:
	return get_viewport().gui_get_focus_owner()


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame


func _free_screen(screen: Control) -> void:
	if screen != null and is_instance_valid(screen):
		screen.queue_free()
	await _settle()
	get_viewport().gui_release_focus()


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error("harbor_input_smoke: %s" % message)
	get_tree().quit(1)
