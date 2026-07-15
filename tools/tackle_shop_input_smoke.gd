extends Node

const ShopScreenScript = preload("res://src/ui/shop_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")

const DESIGN_SIZE := Vector2(1280.0, 720.0)
const EVIDENCE_FILE := "2026-07-15_input_card_focus.png"

var _screen: Variant
var _navigation_events: Array[String] = []
var _failed := false


func _ready() -> void:
	get_tree().root.theme = ThemeFactory.build_theme()
	_seed_progress()
	_screen = ShopScreenScript.new()
	_screen.theme = ThemeFactory.build_theme()
	_screen.configure({})
	_screen.size = DESIGN_SIZE
	_screen.navigate_requested.connect(
		func(screen_id: String, _payload: Dictionary) -> void:
			_navigation_events.append(screen_id)
	)
	add_child(_screen)
	await _settle()

	await _verify_initial_focus_and_disabled_skip()
	await _verify_mouse_purchase_and_focus_restore()
	await _verify_tab_and_card_rebuild_focus()
	await _verify_cancel_and_mouse_return()

	if _failed:
		return
	print("tackle_shop_input_smoke: ok")
	get_tree().quit(0)


func _verify_initial_focus_and_disabled_skip() -> void:
	var starter := _card_button("starter")
	_expect(starter != null, "starter card should exist")
	_expect(get_viewport().gui_get_focus_owner() == starter, "selected starter card should receive safe initial focus")
	_expect(_has_visible_common_focus(starter), "initial card should show the common focus ring")
	_expect(_screen._action_button.disabled, "equipped starter action should be disabled")
	_expect(_screen._action_button.focus_mode == Control.FOCUS_NONE, "disabled action should leave the focus graph")
	var available: Array[Control] = _screen.keyboard_focus_candidates()
	_expect(not available.has(_screen._action_button), "disabled action should not be a keyboard candidate")
	_expect(available.size() == 8, "rod default should expose 2 tabs, 5 cards, and return")
	_expect_closed_graph(available)

	var visited := {}
	for _index in range(available.size()):
		var owner := get_viewport().gui_get_focus_owner()
		_expect(owner != null and owner != _screen._action_button, "Tab traversal should skip disabled action")
		if owner != null:
			visited[_screen._control_focus_identity(owner)] = true
		await _send_key(KEY_TAB)
	_expect(visited.size() == available.size(), "Tab traversal should reach every enabled shop control")
	_expect(get_viewport().gui_get_focus_owner() == starter, "Tab traversal should close back to initial card")
	await _send_key(KEY_TAB, true)
	_expect(get_viewport().gui_get_focus_owner() == _screen._rig_tab_button, "Shift+Tab should move to the previous enabled control without touching disabled action")
	starter.grab_focus()
	await get_tree().process_frame
	await _capture_evidence()


func _verify_mouse_purchase_and_focus_restore() -> void:
	await _click_control(_card_button("iso"))
	_expect(_screen._selected_item_id == "iso", "mouse click should select the iso rod")
	var iso := _card_button("iso")
	_expect(get_viewport().gui_get_focus_owner() == iso, "card rebuild should restore focus to the mouse-selected item")
	_expect(_has_visible_common_focus(iso), "rebuilt selected card should retain visible focus")
	_expect(not _screen._action_button.disabled, "affordable iso rod should enable the action")

	_screen._action_button.grab_focus()
	_screen._refresh()
	await _settle()
	_expect(get_viewport().gui_get_focus_owner() == _screen._action_button, "refresh should retain enabled action focus")
	_expect_closed_graph(_screen.keyboard_focus_candidates())
	await _send_key(KEY_ENTER)
	_expect(PlayerProgress.money == 150, "Enter on action should purchase exactly once")
	_expect(PlayerProgress.equipped_rod_id == "iso", "purchased rod should be equipped")
	_expect(_screen._action_button.disabled, "equipped action should become disabled after purchase")
	_expect(_screen._action_button.focus_mode == Control.FOCUS_NONE, "newly disabled action should leave the graph")
	iso = _card_button("iso")
	_expect(get_viewport().gui_get_focus_owner() == iso, "disabled focused action should fall back to selected card")
	_expect_closed_graph(_screen.keyboard_focus_candidates())

	_screen._refresh()
	await _settle()
	iso = _card_button("iso")
	_expect(get_viewport().gui_get_focus_owner() == iso, "card focus should survive an explicit rebuild")


func _verify_tab_and_card_rebuild_focus() -> void:
	_screen._rig_tab_button.grab_focus()
	await _send_key(KEY_ENTER)
	_expect(_screen._shop_mode == "rig", "Enter on rig tab should switch mode")
	_expect(get_viewport().gui_get_focus_owner() == _screen._rig_tab_button, "tab focus should survive mode rebuild")
	_expect_closed_graph(_screen.keyboard_focus_candidates())

	var uki := _card_button("uki")
	_expect(uki != null, "uki rig card should exist")
	uki.grab_focus()
	await _send_key(KEY_ENTER)
	_expect(_screen._selected_item_id == "uki", "Enter on card should select it once")
	uki = _card_button("uki")
	_expect(get_viewport().gui_get_focus_owner() == uki, "card Enter rebuild should restore the same semantic focus")
	_expect(_has_visible_common_focus(uki), "rig card should show common focus after rebuild")

	_screen._refresh()
	await _settle()
	uki = _card_button("uki")
	_expect(get_viewport().gui_get_focus_owner() == uki, "rig card focus should survive explicit refresh")
	await _click_control(_screen._rod_tab_button)
	_expect(_screen._shop_mode == "rod", "real mouse click should switch back to rod mode")
	_expect(get_viewport().gui_get_focus_owner() == _screen._rod_tab_button, "mouse tab focus should survive rebuild")


func _verify_cancel_and_mouse_return() -> void:
	_navigation_events.clear()
	await _push_key(KEY_ESCAPE, true)
	await _push_key(KEY_ESCAPE, true, true)
	await _push_key(KEY_ESCAPE, false)
	_expect(_navigation_events == ["harbor"], "Escape press and echo should navigate to harbor exactly once")

	_navigation_events.clear()
	await _click_control(_screen._return_button)
	_expect(_navigation_events == ["harbor"], "real mouse click on return should navigate exactly once")


func _card_button(item_id: String) -> Button:
	return _screen._card_buttons.get(item_id) as Button


func _expect_closed_graph(available: Array[Control]) -> void:
	_expect(not available.is_empty(), "focus graph should have enabled controls")
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
			_expect(target != null and available.has(target), "%s focus neighbor should resolve to an enabled candidate" % control.name)


func _has_visible_common_focus(control: Control) -> bool:
	if control == null or not control.has_focus():
		return false
	var indicator := control.get_node_or_null("CommonFocusIndicator") as Control
	return indicator != null and indicator.visible


func _send_key(keycode: Key, shift := false) -> void:
	await _push_key(keycode, true, false, shift)
	await _push_key(keycode, false, false, shift)


func _push_key(keycode: Key, pressed: bool, echo := false, shift := false) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = pressed
	event.echo = echo
	event.shift_pressed = shift
	get_viewport().push_input(event)
	await get_tree().process_frame


func _click_control(control: Control) -> void:
	if control == null:
		_expect(false, "mouse click target should exist")
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
	var up := InputEventMouseButton.new()
	up.position = position
	up.global_position = position
	up.button_index = MOUSE_BUTTON_LEFT
	up.button_mask = 0
	up.pressed = false
	get_viewport().push_input(up, true)
	await _settle()


func _capture_evidence() -> void:
	var output_dir := OS.get_environment("TSURI_TACKLE_SHOP_INPUT_EVIDENCE_DIR").strip_edges()
	if output_dir.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(output_dir)
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	_expect(image != null and image.get_size() == Vector2i(1280, 720), "evidence should be an exact 1280x720 runtime capture")
	if _failed:
		return
	var error := image.save_png(output_dir.path_join(EVIDENCE_FILE))
	_expect(error == OK, "focus evidence PNG should be saved")


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame


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


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
