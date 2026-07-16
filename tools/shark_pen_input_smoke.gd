extends Node

const SharkPenScreenScript = preload("res://src/ui/shark_pen_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const ProbeCommon = preload("res://tools/e11_probe_common.gd")

const DESIGN_SIZE := Vector2(1280.0, 720.0)
const NORMAL_EVIDENCE := "2026-07-16_input_normal_initial_focus.png"
const LOCKED_EVIDENCE := "2026-07-16_input_locked_empty_return_focus.png"

var _failed := false
var _navigation_events: Array[String] = []
var _active_viewport: SubViewport


func _ready() -> void:
	if not _isolated_home_is_safe():
		push_error("shark_pen_input_smoke: 専用の隔離HOME以外からの実行を拒否しました")
		get_tree().quit(2)
		return
	PlayerProgress._sandbox_mode = true
	get_tree().root.theme = ThemeFactory.build_theme()
	await _verify_normal_focus_graph_and_keyboard()
	await _verify_last_stock_focus_recovery()
	await _verify_locked_empty_singleton()
	await _verify_mouse_regression()
	await _verify_cancel_once()
	if _failed:
		return
	print("shark_pen_input_smoke: ok")
	get_tree().quit(0)


func _verify_normal_focus_graph_and_keyboard() -> void:
	_seed_normal_progress()
	var screen: Variant = await _make_screen({"selected_shark_id": "nekozame"})
	var shark_a := _shark_button(screen, "nekozame")
	var shark_b := _shark_button(screen, "inuzame")
	var food_buttons: Array[Button] = screen._food_focus_buttons()
	_expect(_active_viewport.gui_get_focus_owner() == shark_a, "selected caught shark should receive initial focus")
	_expect(shark_a.focus_mode == Control.FOCUS_ALL and shark_b.focus_mode == Control.FOCUS_ALL, "caught sharks should join focus")
	_expect(_shark_button(screen, "dochizame").focus_mode == Control.FOCUS_NONE, "uncaught sharks should leave focus")
	_expect(not screen._feed_button.disabled and screen._feed_button.focus_mode == Control.FOCUS_ALL, "enabled feed should join focus")
	_expect(food_buttons.size() == 3, "normal fixture should expose three real food cards")
	var expected: Array[Control] = [shark_a, shark_b]
	for button in food_buttons:
		expected.append(button)
	expected.append(screen._feed_button)
	expected.append(screen._return_button)
	_expect(screen.keyboard_focus_candidates() == expected, "Tab order should be sharks, foods, feed, return")
	for control in expected:
		_expect(ProbeCommon.has_distinct_focus_style(control), "%s should expose a distinct focus style" % control.name)
	_expect_closed_graph(expected)
	await _capture_evidence(NORMAL_EVIDENCE)

	var visited := {}
	for _step in range(expected.size()):
		var owner := _active_viewport.gui_get_focus_owner() as Control
		if owner != null:
			visited[owner] = true
		await _send_key(KEY_TAB)
	_expect(visited.size() == expected.size(), "Tab should visit every enabled operation exactly within one cycle")
	_expect(_active_viewport.gui_get_focus_owner() == shark_a, "Tab should close back to initial shark")
	await _send_key(KEY_TAB, true)
	_expect(_active_viewport.gui_get_focus_owner() == screen._return_button, "Shift+Tab should reverse the closed cycle")

	shark_a.grab_focus()
	await _send_key(KEY_DOWN)
	_expect(_active_viewport.gui_get_focus_owner() == shark_b, "Down should move through caught sharks and skip locked rows")
	await _send_key(KEY_DOWN)
	_expect(_active_viewport.gui_get_focus_owner() == food_buttons[0], "Down from final caught shark should reach first food")
	for index in range(1, food_buttons.size()):
		await _send_key(KEY_RIGHT)
		_expect(_active_viewport.gui_get_focus_owner() == food_buttons[index], "Right should move through food cards")
	await _send_key(KEY_RIGHT)
	_expect(_active_viewport.gui_get_focus_owner() == screen._feed_button, "Right from final food should reach feed")
	await _send_key(KEY_RIGHT)
	_expect(_active_viewport.gui_get_focus_owner() == screen._return_button, "Right from feed should reach return")
	await _send_key(KEY_UP)
	_expect(_active_viewport.gui_get_focus_owner() == shark_b, "Up from return should return to the nearest caught shark")

	var shark_press_count := [0]
	shark_b.pressed.connect(func() -> void: shark_press_count[0] += 1)
	await _send_key_with_echo(KEY_ENTER)
	_expect(shark_press_count[0] == 1, "Enter including echo should select one shark exactly once")
	_expect(screen._selected_shark_id == "inuzame", "Enter should select the focused shark")
	_expect(_active_viewport.gui_get_focus_owner() == shark_b, "shark refresh should preserve shark identity")
	_expect(ProbeCommon.has_distinct_focus_style(shark_b), "shark refresh should preserve the common focus style")
	shark_a.grab_focus()
	await _send_key(KEY_ENTER)
	_expect(screen._selected_shark_id == "nekozame", "shark B-to-A should restore the original semantic selection")
	_expect(_active_viewport.gui_get_focus_owner() == shark_a, "shark B-to-A should restore semantic focus")
	_expect(ProbeCommon.has_distinct_focus_style(shark_a), "shark B-to-A should retain the common focus style")

	var original_food_id: String = screen._selected_food_id
	food_buttons = screen._food_focus_buttons()
	var alternate_food := food_buttons[1]
	var alternate_food_id := String(alternate_food.get_meta("fish_id", ""))
	var food_press_count := [0]
	alternate_food.pressed.connect(func() -> void: food_press_count[0] += 1)
	alternate_food.grab_focus()
	await _send_key_with_echo(KEY_KP_ENTER)
	_expect(food_press_count[0] == 1, "keypad Enter including echo should select one food exactly once")
	_expect(screen._selected_food_id == alternate_food_id, "keypad Enter should select the focused food")
	_expect(_active_viewport.gui_get_focus_owner() == _food_button(screen, alternate_food_id), "food rebuild should preserve selected food identity")
	var original_food := _food_button(screen, original_food_id)
	original_food.grab_focus()
	await _send_key(KEY_ENTER)
	_expect(screen._selected_food_id == original_food_id, "food B-to-A should restore the original semantic selection")
	_expect(_active_viewport.gui_get_focus_owner() == _food_button(screen, original_food_id), "food B-to-A should restore semantic focus")

	var stock_before := PlayerProgress.fish_count(original_food_id)
	var feed_press_count := [0]
	screen._feed_button.pressed.connect(func() -> void: feed_press_count[0] += 1)
	screen._feed_button.grab_focus()
	await _send_key_with_echo(KEY_ENTER)
	_expect(feed_press_count[0] == 1, "Enter including echo should feed exactly once")
	_expect(PlayerProgress.fish_count(original_food_id) == stock_before - 1, "keyboard feed should consume one fish")
	_expect(_active_viewport.gui_get_focus_owner() == screen._feed_button, "still-enabled feed should retain semantic focus")
	await _free_screen(screen)


func _verify_last_stock_focus_recovery() -> void:
	_seed_last_stock_progress()
	var screen: Variant = await _make_screen({"selected_shark_id": "nekozame"})
	var selected_shark := _shark_button(screen, "nekozame")
	_expect(screen._food_rows.size() == 1 and not screen._feed_button.disabled, "last-stock fixture should start feedable")
	var feed_press_count := [0]
	screen._feed_button.pressed.connect(func() -> void: feed_press_count[0] += 1)
	screen._feed_button.grab_focus()
	await _send_key_with_echo(KEY_ENTER)
	_expect(feed_press_count[0] == 1, "last stock should be consumed by one keyboard feed")
	_expect(PlayerProgress.fish_count("mahaze") == 0, "last stock should reach zero")
	_expect(screen._food_rows.is_empty(), "last stock should rebuild the food list to empty")
	_expect(screen._feed_button.disabled and screen._feed_button.focus_mode == Control.FOCUS_NONE, "disabled post-feed CTA should leave focus")
	_expect(_active_viewport.gui_get_focus_owner() == selected_shark, "disabled post-feed CTA should fall back to selected caught shark")
	_expect(ProbeCommon.has_distinct_focus_style(selected_shark), "post-feed fallback should retain the common focus style")
	_expect(screen.keyboard_focus_candidates() == [selected_shark, screen._return_button], "post-feed graph should contain only shark and return")
	_expect_closed_graph(screen.keyboard_focus_candidates())
	await _free_screen(screen)


func _verify_locked_empty_singleton() -> void:
	_seed_locked_empty_progress()
	var screen: Variant = await _make_screen()
	_expect(screen.keyboard_focus_candidates() == [screen._return_button], "locked empty state should expose return only")
	_expect(_active_viewport.gui_get_focus_owner() == screen._return_button, "locked empty state should focus safe return")
	for shark_id in GameData.get_raiseable_shark_ids():
		_expect(_shark_button(screen, shark_id).focus_mode == Control.FOCUS_NONE, "locked shark %s should stay outside focus" % shark_id)
	_expect(screen._feed_button.disabled and screen._feed_button.focus_mode == Control.FOCUS_NONE, "empty feed should stay outside focus")
	_expect_closed_graph(screen.keyboard_focus_candidates())
	for keycode in [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_TAB]:
		await _send_key(keycode)
		_expect(_active_viewport.gui_get_focus_owner() == screen._return_button, "singleton graph should remain on return")
	await _capture_evidence(LOCKED_EVIDENCE)
	await _free_screen(screen)


func _verify_mouse_regression() -> void:
	_seed_normal_progress()
	var screen: Variant = await _make_screen({"selected_shark_id": "nekozame"})
	await _click_control(_shark_button(screen, "inuzame"))
	_expect(screen._selected_shark_id == "inuzame", "mouse should still select shark rows")
	var foods: Array[Button] = screen._food_focus_buttons()
	var target_food: Button = foods.back()
	var target_food_id := String(target_food.get_meta("fish_id", ""))
	await _click_control(target_food)
	_expect(screen._selected_food_id == target_food_id, "mouse should still select food cards")
	var stock_before := PlayerProgress.fish_count(target_food_id)
	await _click_control(screen._feed_button)
	_expect(PlayerProgress.fish_count(target_food_id) == stock_before - 1, "one mouse feed should consume one fish")
	_navigation_events.clear()
	await _click_control(screen._return_button)
	_expect(_navigation_events == ["harbor"], "mouse return should navigate exactly once")
	await _free_screen(screen)


func _verify_cancel_once() -> void:
	_seed_locked_empty_progress()
	var screen: Variant = await _make_screen()
	_navigation_events.clear()
	await _push_key(KEY_ESCAPE, true)
	await _push_key(KEY_ESCAPE, true, true)
	await _push_key(KEY_ESCAPE, false)
	await _settle()
	_expect(_navigation_events == ["harbor"], "Escape press including echo should navigate exactly once")
	await _free_screen(screen)


func _seed_base_progress() -> void:
	PlayerProgress.reset_game()
	PlayerProgress.level = 30
	PlayerProgress.exp = 120
	PlayerProgress.money = 23450
	PlayerProgress.owned_rods = ["starter", "iso", "offshore", "big_game"]
	PlayerProgress.equipped_rod_id = "big_game"
	PlayerProgress.inventory = {}
	PlayerProgress.caught_counts = {}
	PlayerProgress.shark_bonds = {}
	PlayerProgress._remember_current_titles()


func _seed_normal_progress() -> void:
	_seed_base_progress()
	PlayerProgress.inventory = {"mahaze": 3, "aji": 3, "buri": 3, "nekozame": 1}
	PlayerProgress.caught_counts = {"nekozame": 1, "inuzame": 1, "mahaze": 3, "aji": 3, "buri": 3}
	PlayerProgress.shark_bonds = {"nekozame": 24, "inuzame": 40}


func _seed_last_stock_progress() -> void:
	_seed_base_progress()
	PlayerProgress.inventory = {"mahaze": 1}
	PlayerProgress.caught_counts = {"nekozame": 1, "mahaze": 1}
	PlayerProgress.shark_bonds = {"nekozame": 24}


func _seed_locked_empty_progress() -> void:
	_seed_base_progress()


func _make_screen(payload: Dictionary = {}) -> Variant:
	_navigation_events.clear()
	_active_viewport = SubViewport.new()
	_active_viewport.name = "SharkPenInputViewport"
	_active_viewport.size = Vector2i(DESIGN_SIZE)
	_active_viewport.disable_3d = true
	_active_viewport.transparent_bg = false
	_active_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_active_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_active_viewport)
	var screen := SharkPenScreenScript.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure(payload)
	screen.size = DESIGN_SIZE
	screen.navigate_requested.connect(
		func(screen_id: String, _payload: Dictionary) -> void:
			_navigation_events.append(screen_id)
	)
	_active_viewport.add_child(screen)
	await _settle()
	return screen


func _shark_button(screen: Variant, shark_id: String) -> Button:
	return screen._shark_rows[shark_id]["button"] as Button


func _food_button(screen: Variant, food_id: String) -> Button:
	return screen._food_rows[food_id]["button"] as Button


func _expect_closed_graph(available: Array[Control]) -> void:
	_expect(not available.is_empty(), "focus graph should contain at least one enabled operation")
	for control in available:
		for path in [
			control.focus_neighbor_left,
			control.focus_neighbor_right,
			control.focus_neighbor_top,
			control.focus_neighbor_bottom,
			control.focus_next,
			control.focus_previous,
		]:
			_expect(not path.is_empty(), "%s should have no open focus edge" % control.name)
			if path.is_empty():
				continue
			var target := control.get_node_or_null(path) as Control
			_expect(target != null and available.has(target), "%s edge should resolve inside the enabled graph" % control.name)


func _send_key(keycode: Key, shift := false) -> void:
	await _push_key(keycode, true, false, shift)
	await _push_key(keycode, false, false, shift)
	await _settle()


func _send_key_with_echo(keycode: Key) -> void:
	await _push_key(keycode, true)
	await _push_key(keycode, true, true)
	await _push_key(keycode, false)
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
	var position := control.get_global_rect().get_center()
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
	var output_dir := OS.get_environment("TSURI_SHARK_PEN_INPUT_EVIDENCE_DIR").strip_edges()
	if output_dir.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(output_dir)
	await get_tree().create_timer(0.5).timeout
	RenderingServer.force_draw()
	await get_tree().process_frame
	var image := _active_viewport.get_texture().get_image()
	_expect(image != null and image.get_size() == Vector2i(1280, 720), "%s should be an exact 1280x720 runtime capture" % file_name)
	if _failed:
		return
	var error := image.save_png(output_dir.path_join(file_name))
	_expect(error == OK, "%s should be saved" % file_name)


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame


func _free_screen(screen: Node) -> void:
	var viewport := screen.get_parent()
	viewport.queue_free()
	await _settle()
	_active_viewport = null


func _isolated_home_is_safe() -> bool:
	var raw_home := OS.get_environment("HOME")
	var home := raw_home.simplify_path()
	var user_data := ProjectSettings.globalize_path("user://").simplify_path()
	var manual_home := (
		OS.get_environment("TSURI_SHARK_PEN_INPUT_SMOKE_ALLOW") == "1"
		and (home.begins_with("/private/tmp/tsuri_shark_pen_input_smoke_") or home.begins_with("/tmp/tsuri_shark_pen_input_smoke_"))
	)
	var release_home := (
		(home.begins_with("/private/tmp/") or home.begins_with("/private/var/folders/") or home.begins_with("/tmp/"))
		and home.get_file().begins_with("test_")
		and home.get_base_dir().get_file().begins_with("tsuri_release_verify_home_")
	)
	return (
		(manual_home or release_home)
		and raw_home == raw_home.strip_edges()
		and not raw_home.contains("..")
		and user_data.begins_with(home + "/")
	)


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error("shark_pen_input_smoke: %s" % message)
	get_tree().quit(1)
