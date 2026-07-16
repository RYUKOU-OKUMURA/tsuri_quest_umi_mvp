extends Node

const MarketScreenScript = preload("res://src/ui/market_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const ProbeCommon = preload("res://tools/e11_probe_common.gd")

const DESIGN_SIZE := Vector2(1280.0, 720.0)
const INITIAL_EVIDENCE := "2026-07-16_input_initial_focus.png"
const MODAL_EVIDENCE := "2026-07-16_input_modal_focus.png"
const EMPTY_EVIDENCE := "2026-07-16_input_empty_focus.png"

var _failed := false
var _navigation_events: Array[String] = []
var _active_viewport: SubViewport


func _ready() -> void:
	get_tree().root.theme = ThemeFactory.build_theme()
	await _verify_normal_keyboard_contract()
	await _verify_sell_to_empty_and_restock_graph()
	await _verify_mouse_regression()
	await _verify_normal_cancel_once()
	if _failed:
		return
	print("market_input_smoke: ok")
	get_tree().quit(0)


func _verify_normal_keyboard_contract() -> void:
	_seed_progress({
		"aji": 3,
		"saba": 2,
		"madai": 1,
		"kasago": 2,
		"mejina": 2,
		"iwashi": 4,
		"hirame": 1,
		"kawahagi": 1,
	})
	var screen: Variant = await _make_screen()
	var row_zero := screen._row_nodes[0] as Dictionary
	var row_one := screen._row_nodes[1] as Dictionary
	var initial := row_zero["select_button"] as Button
	_expect(_active_viewport.gui_get_focus_owner() == initial, "selected first row should receive safe initial focus")
	_expect(_has_visible_common_focus(initial), "normal initial focus should be visibly distinct")
	_expect(screen._prev_page_button.focus_mode == Control.FOCUS_NONE, "disabled previous page should leave the graph")
	_expect((row_zero["minus_button"] as Button).focus_mode == Control.FOCUS_NONE, "zero quantity minus should leave the graph")
	_expect(screen._cart_action_button.focus_mode == Control.FOCUS_NONE, "empty cart CTA should leave the graph")
	var available: Array[Control] = screen.keyboard_focus_candidates()
	_expect(available.size() == 24, "paged normal state should expose 24 enabled operations")
	for control in available:
		_expect(ProbeCommon.has_distinct_focus_style(control), "%s should keep a distinct visible focus style" % control.name)
	_expect_closed_graph(available)
	await _capture_evidence(INITIAL_EVIDENCE)

	await _send_key(KEY_DOWN)
	_expect(_active_viewport.gui_get_focus_owner() == row_one["select_button"], "Down should move to the next visible fish row")
	await _send_key(KEY_UP)
	_expect(_active_viewport.gui_get_focus_owner() == initial, "Up should restore the previous fish row")
	await _send_key(KEY_RIGHT)
	_expect(_active_viewport.gui_get_focus_owner() == row_zero["plus_button"], "Right should reach the enabled row quantity operation")

	var visited := {}
	initial.grab_focus()
	for _index in range(available.size()):
		var owner := _active_viewport.gui_get_focus_owner() as Control
		_expect(owner != null and not (owner is BaseButton and (owner as BaseButton).disabled), "Tab should never reach disabled controls")
		if owner != null:
			visited[screen._control_focus_identity(owner)] = true
		await _send_key(KEY_TAB)
	_expect(visited.size() == available.size(), "Tab should reach every enabled normal-state operation")
	_expect(_active_viewport.gui_get_focus_owner() == initial, "normal Tab graph should close back to initial focus")

	var row_select_count := [0]
	(row_one["select_button"] as Button).pressed.connect(func() -> void: row_select_count[0] += 1)
	(row_one["select_button"] as Button).grab_focus()
	await _send_key_with_echo(KEY_ENTER)
	_expect(row_select_count[0] == 1, "one Enter press including echo should select a row exactly once")
	_expect(screen._selected_fish_id == screen._visible_fish_id(1), "keyboard row selection should update the selected fish")

	row_zero = screen._row_nodes[0] as Dictionary
	var plus := row_zero["plus_button"] as Button
	var fish_id: String = screen._visible_fish_id(0)
	var plus_count := [0]
	plus.pressed.connect(func() -> void: plus_count[0] += 1)
	plus.grab_focus()
	await _send_key_with_echo(KEY_ENTER)
	_expect(plus_count[0] == 1, "one Enter press including echo should adjust quantity exactly once")
	_expect(int(screen._sell_quantities.get(fish_id, 0)) == 1, "keyboard quantity should increase by one")
	_expect(screen._cart_action_button.focus_mode == Control.FOCUS_ALL, "enabled CTA should join the graph")
	_expect(ProbeCommon.has_distinct_focus_style(screen._cart_action_button), "M3 CTA focus texture should remain visibly distinct")
	_expect_closed_graph(screen.keyboard_focus_candidates())

	var show_count := [0]
	screen._cart_action_button.pressed.connect(func() -> void: show_count[0] += 1)
	screen._cart_action_button.grab_focus()
	await _send_key_with_echo(KEY_ENTER)
	_expect(show_count[0] == 1, "one Enter press including echo should open confirm exactly once")
	_expect(screen._confirm_overlay.visible, "keyboard CTA should open the sell confirmation")
	_expect(_active_viewport.gui_get_focus_owner() == screen._confirm_cancel_button, "modal should prefer the safe cancel action")
	_expect(_has_visible_common_focus(screen._confirm_cancel_button), "modal safe action should show visible focus")
	_expect(screen.keyboard_focus_candidates() == [screen._confirm_cancel_button, screen._confirm_sell_button], "modal should trap focus to its two actions")
	_expect(screen._cart_action_button.focus_mode == Control.FOCUS_NONE, "modal should remove background CTA from focus")
	_expect_closed_graph(screen.keyboard_focus_candidates())
	await _capture_evidence(MODAL_EVIDENCE)

	await _push_key(KEY_ESCAPE, true)
	await _push_key(KEY_ESCAPE, true, true)
	await _push_key(KEY_ESCAPE, false)
	await _settle()
	_expect(not screen._confirm_overlay.visible, "modal Escape should dismiss only the modal")
	_expect(_navigation_events.is_empty(), "modal Escape should not navigate to harbor")
	_expect(_active_viewport.gui_get_focus_owner() == screen._cart_action_button, "modal Escape should restore the prior background focus")

	await _send_key(KEY_ENTER)
	_expect(screen._confirm_overlay.visible, "restored CTA should reopen the modal")
	var cancel_count := [0]
	screen._confirm_cancel_button.pressed.connect(func() -> void: cancel_count[0] += 1)
	await _send_key_with_echo(KEY_ENTER)
	_expect(cancel_count[0] == 1 and not screen._confirm_overlay.visible, "modal cancel Enter should fire exactly once and restore normal state")
	_expect(_active_viewport.gui_get_focus_owner() == screen._cart_action_button, "modal cancel should restore CTA focus")

	var money_before: int = PlayerProgress.money
	var count_before: int = PlayerProgress.fish_count(fish_id)
	await _send_key(KEY_ENTER)
	screen._confirm_sell_button.grab_focus()
	var sell_count := [0]
	screen._confirm_sell_button.pressed.connect(func() -> void: sell_count[0] += 1)
	await _send_key_with_echo(KEY_ENTER)
	var price: int = int(GameData.get_fish(fish_id).get("sell_price", 0))
	_expect(sell_count[0] == 1, "modal sell Enter should fire exactly once")
	_expect(PlayerProgress.fish_count(fish_id) == count_before - 1, "keyboard sale should subtract one selected fish")
	_expect(PlayerProgress.money == money_before + price, "keyboard sale should add income exactly once")
	_expect(not screen._confirm_overlay.visible, "successful keyboard sale should close the modal")
	_expect(_active_viewport.gui_get_focus_owner() == screen._selected_row_button(), "disabled post-sale CTA should fall back to the selected row")
	_expect_closed_graph(screen.keyboard_focus_candidates())
	await _free_screen(screen)


func _verify_sell_to_empty_and_restock_graph() -> void:
	_seed_progress({"aji": 1})
	var screen: Variant = await _make_screen()
	var row := screen._row_nodes[0] as Dictionary
	(row["plus_button"] as Button).grab_focus()
	await _send_key(KEY_ENTER)
	screen._cart_action_button.grab_focus()
	await _send_key(KEY_ENTER)
	screen._confirm_sell_button.grab_focus()
	await _send_key(KEY_ENTER)
	_expect(PlayerProgress.fish_count("aji") == 0 and screen._fish_ids.is_empty(), "single-fish sale should reach the empty state")
	_expect(screen._inventory_empty_panel.visible and screen._empty_detail_label.visible, "empty state should keep its accepted visual contract")
	_expect(screen.keyboard_focus_candidates() == [screen._return_button], "empty state should exclude every disabled batch and row operation")
	_expect(_active_viewport.gui_get_focus_owner() == screen._return_button, "empty state should fall back to the safe return action")
	_expect(_has_visible_common_focus(screen._return_button), "empty return fallback should remain visibly focused")
	await _capture_evidence(EMPTY_EVIDENCE)

	PlayerProgress.inventory = {"aji": 1}
	screen._refresh()
	await _settle()
	_expect(screen.keyboard_focus_candidates().size() == 5, "restock should restore row select, plus, all, select-all, and return")
	_expect(_active_viewport.gui_get_focus_owner() == screen._return_button, "restock should preserve the still-valid semantic return focus")
	_expect_closed_graph(screen.keyboard_focus_candidates())
	PlayerProgress.inventory = {}
	screen._refresh()
	await _settle()
	_expect(screen.keyboard_focus_candidates() == [screen._return_button], "empty-restock-empty should restore the singleton safe graph")
	_expect(_active_viewport.gui_get_focus_owner() == screen._return_button, "empty-restock-empty should restore return focus")
	await _free_screen(screen)


func _verify_mouse_regression() -> void:
	_seed_progress({"aji": 2, "saba": 2})
	var screen: Variant = await _make_screen()
	var row_one := screen._row_nodes[1] as Dictionary
	await _click_control(row_one["select_button"] as Button)
	var fish_id: String = screen._visible_fish_id(1)
	_expect(screen._selected_fish_id == fish_id, "mouse click should continue selecting fish rows")
	await _click_control(row_one["plus_button"] as Button)
	_expect(int(screen._sell_quantities.get(fish_id, 0)) == 1, "mouse click should continue adjusting quantity")
	var money_before: int = PlayerProgress.money
	var count_before: int = PlayerProgress.fish_count(fish_id)
	await _click_control(screen._cart_action_button)
	_expect(screen._confirm_overlay.visible, "mouse CTA should continue opening confirmation")
	await _click_control(screen._confirm_sell_button)
	_expect(PlayerProgress.fish_count(fish_id) == count_before - 1, "mouse sale should continue subtracting selected fish once")
	_expect(PlayerProgress.money > money_before, "mouse sale should continue adding income")
	_navigation_events.clear()
	await _click_control(screen._return_button)
	_expect(_navigation_events == ["harbor"], "mouse return should navigate to harbor exactly once")
	await _free_screen(screen)


func _verify_normal_cancel_once() -> void:
	_seed_progress({})
	var screen: Variant = await _make_screen()
	_navigation_events.clear()
	await _push_key(KEY_ESCAPE, true)
	await _push_key(KEY_ESCAPE, true, true)
	await _push_key(KEY_ESCAPE, false)
	await _settle()
	_expect(_navigation_events == ["harbor"], "normal Escape press including echo should navigate exactly once")
	await _free_screen(screen)


func _seed_progress(inventory: Dictionary) -> void:
	PlayerProgress.level = 3
	PlayerProgress.exp = 0
	PlayerProgress.money = 1000
	PlayerProgress.owned_rods = ["starter"]
	PlayerProgress.equipped_rod_id = "starter"
	PlayerProgress.owned_rigs = [GameData.DEFAULT_RIG_ID]
	PlayerProgress.equipped_rig_id = GameData.DEFAULT_RIG_ID
	PlayerProgress.owned_boats = []
	PlayerProgress.inventory = inventory.duplicate(true)
	PlayerProgress.caught_counts = inventory.duplicate(true)
	PlayerProgress.spot_caught_counts = {}
	PlayerProgress.best_sizes = {}
	PlayerProgress.pending_buff = {}


func _make_screen() -> Variant:
	_navigation_events.clear()
	_active_viewport = SubViewport.new()
	_active_viewport.name = "MarketInputViewport"
	_active_viewport.size = Vector2i(DESIGN_SIZE)
	_active_viewport.disable_3d = true
	_active_viewport.transparent_bg = false
	_active_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_active_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_active_viewport)
	var screen := MarketScreenScript.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({})
	screen.size = DESIGN_SIZE
	screen.navigate_requested.connect(
		func(screen_id: String, _payload: Dictionary) -> void:
			_navigation_events.append(screen_id)
	)
	_active_viewport.add_child(screen)
	await _settle()
	return screen


func _expect_closed_graph(available: Array[Control]) -> void:
	_expect(not available.is_empty(), "focus graph should contain enabled controls")
	if available.size() <= 1:
		return
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


func _has_visible_common_focus(control: Control) -> bool:
	if control == null or not control.has_focus():
		return false
	var indicator := control.get_node_or_null(ScreenBase.COMMON_FOCUS_INDICATOR_NAME) as Control
	return indicator != null and indicator.visible


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
	control.get_viewport().push_input(motion, true)
	var down := InputEventMouseButton.new()
	down.position = position
	down.global_position = position
	down.button_index = MOUSE_BUTTON_LEFT
	down.button_mask = MOUSE_BUTTON_MASK_LEFT
	down.pressed = true
	control.get_viewport().push_input(down, true)
	await get_tree().process_frame
	var up := down.duplicate() as InputEventMouseButton
	up.button_mask = 0
	up.pressed = false
	control.get_viewport().push_input(up, true)
	await _settle()


func _capture_evidence(file_name: String) -> void:
	var output_dir := OS.get_environment("TSURI_MARKET_INPUT_EVIDENCE_DIR").strip_edges()
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


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error("market_input_smoke: %s" % message)
	get_tree().quit(1)
