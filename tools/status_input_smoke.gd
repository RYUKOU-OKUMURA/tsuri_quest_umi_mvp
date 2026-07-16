extends Node

const StatusScreenScript = preload("res://src/ui/status_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const ProbeCommon = preload("res://tools/e11_probe_common.gd")

const DESIGN_SIZE := Vector2(1280.0, 720.0)
const INITIAL_EVIDENCE := "2026-07-16_input_initial_focus.png"
const OVERLAY_EVIDENCE := "2026-07-16_input_overlay_focus.png"

var _failed := false
var _navigation_events: Array[String] = []
var _active_viewport: SubViewport


func _ready() -> void:
	get_tree().root.theme = ThemeFactory.build_theme()
	await _verify_normal_keyboard_contract()
	await _verify_keyboard_routes_once()
	await _verify_mouse_regression()
	await _verify_default_cancel_once()
	await _verify_normal_hard_anchor_parity()
	if _failed:
		return
	print("status_input_smoke: ok")
	get_tree().quit(0)


func _verify_normal_keyboard_contract() -> void:
	_seed_progress("normal")
	var screen: Variant = await _make_screen()
	var candidates: Array[Control] = screen.keyboard_focus_candidates()
	var expected: Array[Control] = [
		screen._title_list_button,
		screen._fish_book_button,
		screen._cooking_button,
		screen._return_button,
	]
	_expect(candidates == expected, "default focus graph should keep title, fish book, cooking, and return in contract order")
	_expect(_focus_owner() == screen._title_list_button, "title list should receive safe initial focus")
	_expect(_has_visible_common_focus(screen._title_list_button), "initial focus should be visibly distinct")
	for control in candidates:
		_expect(ProbeCommon.has_distinct_focus_style(control), "%s should expose a distinct focus style" % control.name)
	_expect_closed_graph(candidates)
	_expect_directionally_connected(candidates)

	var visited := {}
	for _index in range(candidates.size()):
		var owner := _focus_owner()
		if owner != null:
			visited[owner.get_instance_id()] = true
		await _send_key(KEY_TAB)
	_expect(visited.size() == candidates.size(), "Tab should reach all four status operations")
	_expect(_focus_owner() == screen._title_list_button, "Tab should close back to title list")
	for expected_owner in [screen._return_button, screen._cooking_button, screen._fish_book_button, screen._title_list_button]:
		await _send_key(KEY_TAB, true)
		_expect(_focus_owner() == expected_owner, "Shift+Tab should follow the reverse closed order")

	var frozen_rects := _frozen_rects(screen)
	await _capture_evidence(INITIAL_EVIDENCE)
	var open_count := [0]
	screen._title_list_button.pressed.connect(func() -> void: open_count[0] += 1)
	await _send_key_with_echo(KEY_ENTER)
	_expect(open_count[0] == 1, "one Enter press including echo should open title overlay exactly once")
	_expect(screen._title_overlay.visible, "title overlay should open from keyboard")
	_expect(_focus_owner() == screen._title_overlay_close_button, "overlay should focus only its safe close action")
	_expect(screen.keyboard_focus_candidates() == [screen._title_overlay_close_button], "overlay should trap focus to close")
	_expect(screen._title_list_button.focus_mode == Control.FOCUS_NONE, "overlay should remove background controls from focus")
	_expect_closed_graph(screen.keyboard_focus_candidates())
	_expect(
		_frozen_rects(screen) == frozen_rects,
		"opening overlay should preserve all frozen screen rectangles: before=%s after=%s" % [frozen_rects, _frozen_rects(screen)]
	)
	await _capture_evidence(OVERLAY_EVIDENCE)

	_navigation_events.clear()
	await _click_position(screen._fish_book_button.get_global_rect().get_center())
	_expect(_navigation_events.is_empty(), "overlay should block background mouse navigation")
	_expect(screen._title_overlay.visible, "background click should not dismiss title overlay")
	await _push_key(KEY_ESCAPE, true)
	await _push_key(KEY_ESCAPE, true, true)
	await _push_key(KEY_ESCAPE, false)
	await _settle()
	_expect(not screen._title_overlay.visible, "overlay Escape should close only the overlay")
	_expect(_navigation_events.is_empty(), "overlay Escape should not navigate")
	_expect(_focus_owner() == screen._title_list_button, "overlay Escape should restore opener focus")
	_expect(_frozen_rects(screen) == frozen_rects, "A-to-B-to-A overlay transition should restore frozen rectangles")

	await _send_key(KEY_ENTER)
	_expect(screen._title_overlay.visible, "restored opener should reopen the overlay")
	var close_count := [0]
	screen._title_overlay_close_button.pressed.connect(func() -> void: close_count[0] += 1)
	await _send_key_with_echo(KEY_ENTER)
	_expect(close_count[0] == 1, "one Enter press including echo should close title overlay exactly once")
	_expect(not screen._title_overlay.visible, "overlay close Enter should return to default state")
	_expect(_navigation_events.is_empty(), "overlay close Enter should not navigate")
	_expect(_focus_owner() == screen._title_list_button, "overlay close Enter should restore opener focus")
	await _free_screen(screen)


func _verify_keyboard_routes_once() -> void:
	_seed_progress("normal")
	var screen: Variant = await _make_screen()
	for entry in [
		{"control": screen._fish_book_button, "route": "fish_book"},
		{"control": screen._cooking_button, "route": "cooking"},
		{"control": screen._return_button, "route": "harbor"},
	]:
		_navigation_events.clear()
		(entry["control"] as Button).grab_focus()
		await _send_key_with_echo(KEY_ENTER)
		_expect(_navigation_events == [entry["route"]], "%s keyboard route should fire exactly once" % entry["route"])
	await _free_screen(screen)


func _verify_mouse_regression() -> void:
	_seed_progress("normal")
	var screen: Variant = await _make_screen()
	await _click_control(screen._title_list_button)
	_expect(screen._title_overlay.visible, "mouse should continue opening the title overlay")
	await _click_control(screen._title_overlay_close_button)
	_expect(not screen._title_overlay.visible, "mouse should continue closing the title overlay")
	_expect(_focus_owner() == screen._title_list_button, "mouse modal close should restore opener focus")
	for entry in [
		{"control": screen._fish_book_button, "route": "fish_book"},
		{"control": screen._cooking_button, "route": "cooking"},
		{"control": screen._return_button, "route": "harbor"},
	]:
		_navigation_events.clear()
		await _click_control(entry["control"] as Control)
		_expect(_navigation_events == [entry["route"]], "%s mouse route should remain unchanged" % entry["route"])
	await _free_screen(screen)


func _verify_default_cancel_once() -> void:
	_seed_progress("normal")
	var screen: Variant = await _make_screen()
	_navigation_events.clear()
	await _push_key(KEY_ESCAPE, true)
	await _push_key(KEY_ESCAPE, true, true)
	await _push_key(KEY_ESCAPE, false)
	await _settle()
	_expect(_navigation_events == ["harbor"], "default Escape press including echo should navigate to harbor exactly once")
	await _free_screen(screen)


func _verify_normal_hard_anchor_parity() -> void:
	_seed_progress("normal")
	var normal_screen: Variant = await _make_screen()
	var normal_rects := _frozen_rects(normal_screen)
	await _free_screen(normal_screen)
	_seed_progress("hard")
	var hard_screen: Variant = await _make_screen()
	_expect(_frozen_rects(hard_screen) == normal_rects, "normal and hard should preserve the same frozen anchors")
	_expect(_focus_owner() == hard_screen._title_list_button, "hard status should keep the same safe initial focus")
	_expect_closed_graph(hard_screen.keyboard_focus_candidates())
	await _free_screen(hard_screen)


func _seed_progress(difficulty_id: String) -> void:
	PlayerProgress.difficulty_id = difficulty_id
	PlayerProgress.level = 4
	PlayerProgress.exp = 52
	PlayerProgress.money = 12840
	PlayerProgress.equipped_rod_id = "marlin"
	PlayerProgress.owned_rods = ["starter", "iso", "offshore", "big_game", "marlin"]
	PlayerProgress.owned_boats = ["skiff"]
	PlayerProgress.caught_counts = {"aji": 12, "mejina": 5, "kasago": 3, "saba": 1}
	PlayerProgress.best_sizes = {"aji": 34.2, "mejina": 44.2, "kasago": 26.4, "saba": 38.6}
	PlayerProgress.inventory = {"aji": 2, "mejina": 1}
	PlayerProgress.spot_caught_counts = {
		"harbor_pier": {"aji": 12},
		"rock_breakwater": {"mejina": 5, "kasago": 3},
		"outer_tide": {"saba": 1},
	}
	PlayerProgress.pending_buff = {}
	PlayerProgress.eaten_recipes = {}


func _make_screen() -> Variant:
	_navigation_events.clear()
	_active_viewport = SubViewport.new()
	_active_viewport.name = "StatusInputViewport"
	_active_viewport.size = Vector2i(DESIGN_SIZE)
	_active_viewport.disable_3d = true
	_active_viewport.transparent_bg = false
	_active_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_active_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_active_viewport)
	var screen := StatusScreenScript.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({})
	screen.size = DESIGN_SIZE
	screen.navigate_requested.connect(
		func(screen_id: String, _payload: Dictionary) -> void:
			_navigation_events.append(screen_id)
	)
	_active_viewport.add_child(screen)
	await _settle()
	await _settle()
	return screen


func _frozen_rects(screen: Variant) -> Dictionary:
	return {
		"header": screen.get_node("StatusRoot/StatusHeader").get_global_rect(),
		"player": screen._player_panel.get_global_rect(),
		"summary": screen._summary_panel.get_global_rect(),
		"inventory": screen._inventory_panel.get_global_rect(),
		"footer": screen.get_node("StatusRoot/StatusFooter").get_global_rect(),
		"title_list": screen._title_list_button.get_global_rect(),
		"fish_book": screen._fish_book_button.get_global_rect(),
		"cooking": screen._cooking_button.get_global_rect(),
		"return": screen._return_button.get_global_rect(),
	}


func _expect_closed_graph(available: Array[Control]) -> void:
	_expect(not available.is_empty(), "focus graph should contain enabled controls")
	for control in available:
		for path in [
			control.focus_neighbor_left,
			control.focus_neighbor_right,
			control.focus_neighbor_top,
			control.focus_neighbor_bottom,
			control.focus_next,
			control.focus_previous,
		]:
			_expect(not path.is_empty(), "%s should have a closed focus neighbor" % control.name)
			if path.is_empty():
				continue
			var target := control.get_node_or_null(path) as Control
			_expect(target != null and available.has(target), "%s neighbor should resolve to an enabled candidate" % control.name)


func _expect_directionally_connected(available: Array[Control]) -> void:
	for start in available:
		var reached := {start.get_instance_id(): true}
		var pending: Array[Control] = [start]
		while not pending.is_empty():
			var control := pending.pop_front() as Control
			for path in [
				control.focus_neighbor_left,
				control.focus_neighbor_right,
				control.focus_neighbor_top,
				control.focus_neighbor_bottom,
			]:
				var target := control.get_node_or_null(path) as Control
				if target != null and not reached.has(target.get_instance_id()):
					reached[target.get_instance_id()] = true
					pending.append(target)
		_expect(reached.size() == available.size(), "%s directional graph should reach all enabled operations" % start.name)


func _has_visible_common_focus(control: Control) -> bool:
	if control == null or not control.has_focus():
		return false
	var indicator := control.get_node_or_null(ScreenBase.COMMON_FOCUS_INDICATOR_NAME) as Control
	return indicator != null and indicator.visible


func _focus_owner() -> Control:
	return _active_viewport.gui_get_focus_owner() as Control if _active_viewport != null else null


func _send_key(keycode: Key, shift := false) -> void:
	await _push_key(keycode, true, false, shift)
	await _push_key(keycode, false, false, shift)
	await _settle()


func _send_key_with_echo(keycode: Key) -> void:
	await _push_key(keycode, true)
	await _push_key(keycode, true, true)
	await _push_key(keycode, false)
	await get_tree().create_timer(0.15).timeout
	await _settle()


func _push_key(keycode: Key, pressed: bool, echo := false, shift := false) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = pressed
	event.echo = echo
	event.shift_pressed = shift
	_active_viewport.push_input(event, true)
	await get_tree().process_frame


func _click_control(control: Control) -> void:
	_expect(control != null, "mouse target should exist")
	if control == null:
		return
	await _click_position(control.get_global_rect().get_center())


func _click_position(position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	_active_viewport.push_input(motion, true)
	var down := InputEventMouseButton.new()
	down.position = position
	down.global_position = position
	down.button_index = MOUSE_BUTTON_LEFT
	down.button_mask = MOUSE_BUTTON_MASK_LEFT
	down.pressed = true
	_active_viewport.push_input(down, true)
	await get_tree().process_frame
	var up := down.duplicate() as InputEventMouseButton
	up.button_mask = 0
	up.pressed = false
	_active_viewport.push_input(up, true)
	await _settle()


func _capture_evidence(file_name: String) -> void:
	var output_dir := OS.get_environment("TSURI_STATUS_INPUT_EVIDENCE_DIR").strip_edges()
	if output_dir.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(output_dir)
	await get_tree().process_frame
	RenderingServer.force_draw(false)
	await get_tree().process_frame
	RenderingServer.force_draw(false)
	await get_tree().process_frame
	var image := _active_viewport.get_texture().get_image()
	_expect(image != null and image.get_size() == Vector2i(DESIGN_SIZE), "focus evidence should be an actual 1280x720 viewport capture")
	if image == null or image.get_size() != Vector2i(DESIGN_SIZE):
		return
	var output_path := output_dir.path_join(file_name)
	_expect(image.save_png(output_path) == OK and FileAccess.file_exists(output_path), "focus evidence should be saved to QA evidence")


func _free_screen(screen: Control) -> void:
	if screen != null and is_instance_valid(screen):
		screen.queue_free()
	await _settle()
	if _active_viewport != null and is_instance_valid(_active_viewport):
		_active_viewport.queue_free()
	await _settle()
	_active_viewport = null


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
