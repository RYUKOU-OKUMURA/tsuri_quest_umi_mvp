extends Node

const FishBookScreenScript = preload("res://src/ui/fish_book_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const ProbeCommon = preload("res://tools/e11_probe_common.gd")

var _failed := false
var _navigation_count := 0
var _last_route := ""


func _ready() -> void:
	var capture_state := OS.get_environment("TSURI_FISH_BOOK_INPUT_CAPTURE_STATE").strip_edges()
	var evidence_dir := OS.get_environment("TSURI_FISH_BOOK_INPUT_EVIDENCE_DIR").strip_edges()
	if not evidence_dir.is_empty() and capture_state not in ["default", "nushi"]:
		push_error("fish_book_input_smoke: 証拠captureは1 process 1状態（default / nushi）で実行してください")
		get_tree().quit(2)
		return
	if capture_state == "default":
		await _verify_default_focus_graph()
	elif capture_state == "nushi":
		await _verify_sparse_filter_rebuild_and_return()
	else:
		await _verify_default_focus_graph()
		await _verify_keyboard_selection_and_scroll()
		await _verify_sparse_filter_rebuild_and_return()
		await _verify_mouse_regression()
		await _verify_cancel_once()
	if _failed:
		return
	print("fish_book_input_smoke: ok")
	get_tree().quit(0)


func _verify_default_focus_graph() -> void:
	_seed_progress()
	var screen: Variant = await _make_screen()
	var selected := screen._fish_card_buttons.get(screen._selected_fish_id) as Button
	var expected_count: int = screen._filtered_fish_ids().size() + screen.FILTERS.size() + 1
	_expect(selected != null, "selected fish card should exist")
	_expect(_focus_owner() == selected, "selected visible fish card should receive initial focus")
	_expect(screen.keyboard_focus_candidates().size() == expected_count, "all cards, seven filters, and return should join the graph")
	for control in screen.keyboard_focus_candidates():
		_expect(ProbeCommon.has_distinct_focus_style(control), "every keyboard target should expose a distinct focus style")
	var indicator := selected.get_node_or_null(ScreenBase.COMMON_FOCUS_INDICATOR_NAME) as Panel
	_expect(indicator != null and indicator.visible, "initial card focus should be visible at runtime")

	var reached := {}
	for _step in range(expected_count):
		var owner := _focus_owner()
		if owner != null:
			reached[owner.get_instance_id()] = true
		await _send_key_action(&"ui_focus_next")
	_expect(reached.size() == expected_count, "Tab should reach every enabled fish-book operation")
	_expect(_focus_owner() == selected, "Tab graph should close back to the initial card")
	await _capture(screen, "default_card_focus")
	await _free_screen(screen)


func _verify_keyboard_selection_and_scroll() -> void:
	_seed_progress()
	var screen: Variant = await _make_screen()
	var ids: Array[String] = screen._filtered_fish_ids()
	_expect(ids.size() > 12, "default catalog should exercise scrolling")
	var initial_id: String = screen._selected_fish_id
	await _send_key_action(&"ui_right")
	var target := _focus_owner() as Button
	_expect(target != null and target.has_meta("fish_book_card"), "Right should move to the next card")
	var target_id := String(target.get_meta("fish_book_card", ""))
	_expect(target_id != initial_id, "Right should change the focused card")
	var pressed_count := [0]
	var rebuilt_card_count := [0]
	target.pressed.connect(func() -> void: pressed_count[0] += 1)
	screen._grid.child_entered_tree.connect(func(_child: Node) -> void: rebuilt_card_count[0] += 1)
	await _send_key_action_with_echo(&"ui_accept")
	_expect(pressed_count[0] == 1, "one Enter including echo should select a card exactly once")
	_expect(rebuilt_card_count[0] == ids.size(), "one Enter including echo should rebuild the card set exactly once")
	_expect(screen._selected_fish_id == target_id, "Enter should keep the existing fish-selection contract")
	_expect(_focus_owner() == screen._fish_card_buttons.get(target_id), "card rebuild should recover focus to the selected replacement card")

	for _step in range(18):
		await _send_key_action(&"ui_down")
	var scroller := screen._fish_scroll as ScrollContainer
	_expect(scroller.scroll_vertical > 0, "keyboard card traversal should scroll the catalog to keep focus visible")
	var focused := _focus_owner()
	_expect(focused != null and scroller.get_global_rect().intersects(focused.get_global_rect()), "focused card should remain inside the visible scroll viewport")
	await _free_screen(screen)


func _verify_sparse_filter_rebuild_and_return() -> void:
	_seed_progress(false)
	var screen: Variant = await _make_screen()
	var all_count: int = screen._filtered_fish_ids().size()
	var all_rect: Rect2 = screen._fish_scroll.get_global_rect()
	var return_rect: Rect2 = screen._return_button.get_global_rect()
	var nushi := screen._filter_buttons.get("nushi") as Button
	_expect(nushi != null, "nushi filter should exist")
	nushi.grab_focus()
	await _settle()
	var pressed_count := [0]
	nushi.pressed.connect(func() -> void: pressed_count[0] += 1)
	await _send_key_action_with_echo(&"ui_accept")
	_expect(pressed_count[0] == 1, "one Enter including echo should activate a filter exactly once")
	_expect(screen._active_filter == "nushi", "nushi filter should become active")
	_expect(screen._filtered_fish_ids().size() > 0 and screen._filtered_fish_ids().size() < all_count, "uncaught nushi state should use a sparse but safe card set")
	_expect(_focus_owner() == nushi, "filter-triggered card rebuild should retain the live filter focus")
	_expect(screen._selected_fish_id != "" and screen._fish_card_buttons.has(screen._selected_fish_id), "sparse rebuild should recover a valid card selection")
	_expect(screen._fish_scroll.get_global_rect() == all_rect and screen._return_button.get_global_rect() == return_rect, "all-to-sparse transition should preserve frozen anchors")
	await _capture(screen, "uncaught_nushi_filter_focus")

	for _step in range(6):
		await _send_key_action(&"ui_left")
	var all_filter := screen._filter_buttons.get("all") as Button
	_expect(_focus_owner() == all_filter, "Left should traverse all seven filter tabs")
	await _send_key_action(&"ui_accept")
	_expect(screen._active_filter == "all", "keyboard should restore the all-fish state")
	_expect(_focus_owner() == all_filter, "A-to-B-to-A filter rebuild should recover the original live tab")
	_expect(screen._filtered_fish_ids().size() == all_count, "A-to-B-to-A should restore the full card set")
	_expect(screen._fish_scroll.get_global_rect() == all_rect and screen._return_button.get_global_rect() == return_rect, "A-to-B-to-A should restore frozen anchors exactly")

	await _send_key_action(&"ui_left")
	_expect(_focus_owner() == screen._return_button, "Left from the first filter should reach return")
	await _send_key_action(&"ui_right")
	_expect(_focus_owner() == all_filter, "Right from return should re-enter the filter row")
	await _free_screen(screen)


func _verify_mouse_regression() -> void:
	_seed_progress()
	var screen: Variant = await _make_screen()
	var rare := screen._filter_buttons.get("rare") as Button
	await _click_control(rare)
	_expect(screen._active_filter == "rare", "mouse should continue activating filter tabs")
	var rare_ids: Array[String] = screen._filtered_fish_ids()
	_expect(not rare_ids.is_empty(), "rare mouse filter should expose cards")
	var card := screen._fish_card_buttons.get(rare_ids[0]) as Button
	await _click_control(card)
	_expect(screen._selected_fish_id == rare_ids[0], "mouse should continue selecting fish cards after a rebuild")
	await _free_screen(screen)


func _verify_cancel_once() -> void:
	_seed_progress()
	_reset_route()
	var screen: Variant = await _make_screen()
	await _send_key_action_with_echo(&"ui_cancel")
	_expect(_navigation_count == 1 and _last_route == "harbor", "one Escape press including echo should navigate to harbor exactly once")
	await _free_screen(screen)


func _seed_progress(include_caught_nushi := true) -> void:
	PlayerProgress.level = 7
	PlayerProgress.money = 12840
	PlayerProgress.equipped_rod_id = "starter"
	PlayerProgress.caught_counts = {
		"aji": 12,
		"saba": 8,
		"kasago": 6,
		"mebaru": 7,
		"madai": 4,
	}
	if include_caught_nushi:
		PlayerProgress.caught_counts["nushi_shallow_sand"] = 1
	PlayerProgress.best_sizes = {
		"aji": 34.2,
		"saba": 38.6,
		"kasago": 26.4,
		"mebaru": 24.1,
		"madai": 48.2,
	}
	PlayerProgress.spot_caught_counts = {
		"harbor_pier": {"aji": 12, "mebaru": 2},
		"rock_breakwater": {"kasago": 6, "mebaru": 5},
		"outer_tide": {"saba": 8},
		"south_reef": {"madai": 4},
	}


func _make_screen() -> Variant:
	var screen := FishBookScreenScript.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({})
	screen.size = Vector2(1280.0, 720.0)
	screen.navigate_requested.connect(_capture_route)
	add_child(screen)
	await _settle()
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


func _send_key_action_with_echo(action: StringName) -> void:
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
	_expect(control != null and is_instance_valid(control), "mouse target should remain live")
	if control == null or not is_instance_valid(control):
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
	var up := down.duplicate() as InputEventMouseButton
	up.button_mask = 0
	up.pressed = false
	get_viewport().push_input(up, true)
	await _settle()


func _capture(screen: Control, stem: String) -> void:
	var output_dir := OS.get_environment("TSURI_FISH_BOOK_INPUT_EVIDENCE_DIR").strip_edges()
	if output_dir.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(output_dir)
	await get_tree().process_frame
	await get_tree().process_frame
	RenderingServer.force_draw(false)
	await get_tree().process_frame
	RenderingServer.force_draw(false)
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	_expect(image != null and image.get_size() == Vector2i(1280, 720), "focus evidence should be an actual 1280x720 viewport capture")
	if image == null:
		return
	var path := output_dir.path_join("2026-07-16_input_%s.png" % stem)
	_expect(image.save_png(path) == OK, "focus evidence should be written")
	_expect(screen.is_inside_tree(), "capture should come from the live screen")


func _focus_owner() -> Control:
	return get_viewport().gui_get_focus_owner()


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _free_screen(screen: Node) -> void:
	if screen != null and is_instance_valid(screen):
		screen.queue_free()
	await _settle()
	get_viewport().gui_release_focus()


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error("fish_book_input_smoke: %s" % message)
	get_tree().quit(1)
