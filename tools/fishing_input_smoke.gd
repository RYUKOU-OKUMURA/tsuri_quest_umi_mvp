extends Node

const FishingScreenScript = preload("res://src/ui/fishing_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")

const DESIGN_SIZE := Vector2(1280.0, 720.0)
const EVIDENCE_READY := "2026-07-15_input_ready_focus.png"
const EVIDENCE_DANGER := "2026-07-15_input_danger_ready_focus.png"
const EVIDENCE_FIGHT := "2026-07-15_input_fight_focus.png"
const EVIDENCE_QUIT := "2026-07-15_input_quit_focus.png"
const EVIDENCE_FANFARE := "2026-07-15_input_fanfare_focus.png"

var _screen: Variant
var _failed := false
var _navigation_events: Array[String] = []


func _ready() -> void:
	get_tree().root.theme = ThemeFactory.build_theme()
	await _verify_ready_focus_and_decision()
	await _verify_danger_lure_focus_contract()
	await _verify_state_keys_modal_and_mouse()
	await _verify_fanfare_focus_contract()
	if _failed:
		return
	print("fishing_input_smoke: ok")
	get_tree().quit(0)


func _verify_ready_focus_and_decision() -> void:
	_screen = await _make_screen({"spot_id": "harbor_pier"})
	var targets: Array[Control] = _screen._fight_hud.keyboard_focus_targets()
	_expect(targets.size() == 3, "normal READY should expose main/change/harbor keyboard targets")
	_expect(
		get_viewport().gui_get_focus_owner() == _screen._fight_hud.main_focus_target(),
		"normal READY should focus the main cast action"
	)
	_expect(_has_visible_common_focus(_screen._fight_hud.main_focus_target()), "READY main action should show common focus")
	await _capture(EVIDENCE_READY, false)

	await _send_key(KEY_TAB)
	_expect(get_viewport().gui_get_focus_owner() == targets[1], "Tab should reach change-spot from READY main")
	_navigation_events.clear()
	await _send_key(KEY_ENTER)
	_expect(_navigation_events == ["fishing_spots"], "Enter on change-spot should navigate exactly once")
	await _send_key(KEY_TAB)
	_expect(get_viewport().gui_get_focus_owner() == targets[2], "Tab should reach harbor from change-spot")
	_navigation_events.clear()
	await _send_key(KEY_ENTER)
	_expect(_navigation_events == ["harbor"], "Enter on harbor should navigate exactly once")

	_screen._fight_hud.main_focus_target().grab_focus()
	await _send_key(KEY_ENTER)
	_expect(_screen._simulator.state == FishingSimulator.State.CASTING, "Enter on READY main focus should cast")
	await _free_screen()

	_screen = await _make_screen({"spot_id": "harbor_pier"})
	await _send_key(KEY_E)
	_expect(_screen._simulator.state == FishingSimulator.State.CASTING, "E shortcut should cast from READY")
	await _free_screen()


func _verify_danger_lure_focus_contract() -> void:
	PlayerProgress.level = GameData.MAX_LEVEL
	PlayerProgress.owned_boats = ["bluewater_boat"]
	PlayerProgress.sea_chart_fragments = 3
	PlayerProgress.inventory = {}
	_screen = await _make_screen({"spot_id": "danger_reef"})
	var single_targets: Array[Control] = _screen._fight_hud.keyboard_focus_targets()
	_expect(single_targets.size() == 3, "one danger lure candidate should skip both arrow targets")
	_expect(_screen._fight_hud._lure_prev_rect == Rect2(), "disabled previous lure hit rect should be empty")
	_expect(_screen._fight_hud._lure_next_rect == Rect2(), "disabled next lure hit rect should be empty")
	var selection_before := String(_screen._selected_shark_lure_fish_id)
	await _send_key(KEY_RIGHT)
	_expect(String(_screen._selected_shark_lure_fish_id) == selection_before, "one lure candidate should ignore arrow input")
	await _free_screen()

	PlayerProgress.inventory = {"aji": 1}
	_screen = await _make_screen({"spot_id": "danger_reef", "shark_lure_fish_id": "aji"})
	var danger_targets: Array[Control] = _screen._fight_hud.keyboard_focus_targets()
	_expect(danger_targets.size() == 5, "multiple danger lure candidates should expose arrows and READY actions")
	_expect(_screen._fight_hud._lure_prev_rect.size.x > 0.0, "enabled previous lure should keep its mouse hit rect")
	var selected_before := String(_screen._selected_shark_lure_fish_id)
	await _send_key(KEY_RIGHT)
	_expect(String(_screen._selected_shark_lure_fish_id) != selected_before, "right arrow should cycle the selected lure")
	await _send_key(KEY_LEFT)
	_expect(String(_screen._selected_shark_lure_fish_id) == selected_before, "left arrow should restore the selected lure")
	danger_targets[0].grab_focus()
	await get_tree().process_frame
	_expect(_has_visible_common_focus(danger_targets[0]), "danger lure arrow should show common focus")
	var previous_press_count := [0]
	_screen._fight_hud.shark_lure_previous_pressed.connect(func() -> void: previous_press_count[0] += 1)
	await _send_key(KEY_ENTER)
	_expect(previous_press_count[0] == 1, "Enter on focused lure arrow should emit exactly once")
	_expect(
		String(_screen._selected_shark_lure_fish_id) != selected_before,
		"Enter on focused lure arrow should change the selected lure once"
	)
	danger_targets[0].grab_focus()
	await get_tree().process_frame
	_expect(_has_visible_common_focus(danger_targets[0]), "danger evidence should restore focus to the tested lure arrow")
	await _capture(EVIDENCE_DANGER, false)
	await _free_screen()


func _verify_state_keys_modal_and_mouse() -> void:
	_screen = await _make_screen({"spot_id": "harbor_pier"})
	await _send_key(KEY_ENTER)
	_expect(_screen._simulator.state == FishingSimulator.State.CASTING, "READY Enter should enter CASTING")
	await _send_key(KEY_ENTER)
	_expect(_screen._simulator.state != FishingSimulator.State.FIGHT, "CASTING Enter must not hook early")
	_advance_until_state(FishingSimulator.State.WAITING)
	_expect(_screen._simulator.state == FishingSimulator.State.WAITING, "attempt should reach WAITING")
	_expect(_screen._fight_hud.keyboard_focus_targets().is_empty(), "WAITING should expose no focus candidates")
	_expect(get_viewport().gui_get_focus_owner() == null, "WAITING should retain no stale focus owner")
	await _send_key(KEY_ENTER)
	_expect(_screen._simulator.state == FishingSimulator.State.WAITING, "WAITING Enter must not hook early")
	_advance_until_state(FishingSimulator.State.APPROACH)
	_expect(_screen._simulator.state == FishingSimulator.State.APPROACH, "attempt should reach APPROACH")
	_expect(_screen._fight_hud.keyboard_focus_targets().is_empty(), "APPROACH should expose no focus candidates")
	_expect(get_viewport().gui_get_focus_owner() == null, "APPROACH should retain no stale focus owner")
	await _send_key(KEY_ENTER)
	_expect(_screen._simulator.state == FishingSimulator.State.APPROACH, "APPROACH Enter must not hook early")
	_advance_until_bite()
	_expect(_screen._simulator.state == FishingSimulator.State.BITE, "attempt should reach BITE")
	await _wait_for_hit_stop()
	_expect(
		get_viewport().gui_get_focus_owner() == _screen._fight_hud.main_focus_target(),
		"BITE should restore focus to the hook action"
	)
	await _send_key(KEY_ENTER)
	_expect(
		_screen._simulator.state == FishingSimulator.State.FIGHT,
		"BITE Enter should enter FIGHT once (actual=%d)" % _screen._simulator.state
	)
	await _wait_for_hit_stop()
	var fight_targets: Array[Control] = _screen._fight_hud.keyboard_focus_targets()
	_expect(fight_targets.size() == 2, "FIGHT should expose reel and give-line focus targets")
	_expect(get_viewport().gui_get_focus_owner() == fight_targets[0], "FIGHT should focus reel first")
	await _capture(EVIDENCE_FIGHT, true)

	await _push_key(KEY_SPACE, true)
	_expect(_screen._simulator.reeling, "Space press should start reeling")
	await _push_key(KEY_SPACE, true, true)
	_expect(_screen._simulator.reeling, "Space echo should not release or duplicate the held action")
	await _push_key(KEY_SPACE, false)
	_expect(not _screen._simulator.reeling, "Space release should stop reeling")
	await _push_key(KEY_SHIFT, true)
	_expect(_screen._simulator.giving_line, "Shift press should start giving line")
	await _push_key(KEY_SHIFT, false)
	_expect(not _screen._simulator.giving_line, "Shift release should stop giving line")

	var reel_center: Vector2 = _screen._fight_hud.global_position + _screen._fight_hud._reel_rect.get_center()
	await _push_mouse(reel_center, true)
	_expect(_screen._simulator.reeling, "mouse down on reel should preserve held-action contract")
	await _push_mouse(reel_center, false)
	_expect(not _screen._simulator.reeling, "mouse up on reel should release held action")

	_navigation_events.clear()
	await _send_key(KEY_ESCAPE)
	_expect(_screen._quit_overlay.visible, "FIGHT Escape should open quit confirmation")
	_expect(get_viewport().gui_get_focus_owner() == _screen._quit_cancel_button, "quit modal should focus safe continue")
	_expect(not _screen._quit_title.text.strip_edges().is_empty(), "quit modal title should be populated")
	_expect(not _screen._quit_details.text.strip_edges().is_empty(), "quit modal details should be populated")
	_expect(
		_screen._quit_title.is_visible_in_tree() and _screen._quit_title.size.y >= 44.0,
		"quit modal title should retain its visible layout height"
	)
	_expect(
		_screen._quit_details.is_visible_in_tree() and _screen._quit_details.size.y >= 56.0,
		"quit modal details should retain its visible layout height"
	)
	_expect(
		_screen._quit_title.get_visible_line_count() == _screen._quit_title.get_line_count(),
		"quit modal title should show every line"
	)
	_expect(
		_screen._quit_details.get_visible_line_count() == _screen._quit_details.get_line_count(),
		"quit modal details should show every line"
	)
	await _push_key(KEY_SPACE, true)
	_expect(not _screen._simulator.reeling, "quit modal should block background Space input")
	await _push_key(KEY_SPACE, false)
	await _capture(EVIDENCE_QUIT, true)
	await _send_key(KEY_ENTER)
	_expect(not _screen._quit_overlay.visible, "Enter on safe initial modal focus should close confirmation")
	_expect(_navigation_events.is_empty(), "safe modal action must not navigate")
	_expect(get_viewport().gui_get_focus_owner() == fight_targets[0], "closing modal should restore the FIGHT context")

	await _send_key(KEY_ESCAPE)
	await _send_key(KEY_TAB)
	_expect(get_viewport().gui_get_focus_owner() == _screen._quit_confirm_button, "Tab should reach destructive modal action")
	await _send_key(KEY_ENTER)
	_expect(_navigation_events == ["harbor"], "modal confirm should navigate exactly once")
	await _free_screen()


func _verify_fanfare_focus_contract() -> void:
	_screen = await _make_screen({"spot_id": "harbor_pier"})
	var continue_count := [0]
	_screen._catch_fanfare.continue_requested.connect(func() -> void: continue_count[0] += 1)
	_screen._catch_fanfare.play(GameData.get_fish("aji"), 24.5, {"record_broken": true, "previous_best_cm": 20.0})
	await _settle()
	var fanfare_targets: Array[Control] = _screen._catch_fanfare.keyboard_focus_targets()
	_expect(fanfare_targets.size() == 2, "fanfare should expose continue and harbor buttons")
	_expect(get_viewport().gui_get_focus_owner() == fanfare_targets[0], "fanfare should focus continue first")
	if not OS.get_environment("TSURI_FISHING_INPUT_FIGHT_EVIDENCE_DIR").strip_edges().is_empty():
		await get_tree().create_timer(1.15).timeout
	await _capture(EVIDENCE_FANFARE, true)
	await _send_key(KEY_TAB)
	_expect(get_viewport().gui_get_focus_owner() == fanfare_targets[1], "Tab should reach fanfare harbor action")
	_navigation_events.clear()
	await _send_key(KEY_ENTER)
	_expect(_navigation_events == ["harbor"], "fanfare harbor Enter should navigate exactly once")
	_expect(not _screen._catch_fanfare.is_playing(), "fanfare should close after harbor decision")

	_screen._catch_fanfare.play(GameData.get_fish("aji"), 20.0, {})
	await _settle()
	await _push_key(KEY_SPACE, true)
	await _push_key(KEY_SPACE, true, true)
	await _push_key(KEY_SPACE, false)
	_expect(continue_count[0] == 1, "fanfare Space shortcut should fire continue exactly once")
	_expect(_screen._simulator.state == FishingSimulator.State.READY, "fanfare continue should restore READY")

	_screen._catch_fanfare.play(GameData.get_fish("aji"), 20.0, {})
	await _settle()
	_navigation_events.clear()
	await _send_key(KEY_ESCAPE)
	_expect(_navigation_events == ["harbor"], "fanfare Escape should navigate to harbor exactly once")
	_expect(not _screen._catch_fanfare.is_playing(), "fanfare Escape should close the decision screen")
	await _free_screen()


func _make_screen(payload: Dictionary) -> Variant:
	var screen := FishingScreenScript.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure(payload)
	screen.size = DESIGN_SIZE
	screen.navigate_requested.connect(func(screen_id: String, _payload: Dictionary) -> void: _navigation_events.append(screen_id))
	add_child(screen)
	await _settle()
	return screen


func _free_screen() -> void:
	if _screen != null and is_instance_valid(_screen):
		remove_child(_screen)
		_screen.queue_free()
	_screen = null
	await get_tree().process_frame
	await get_tree().process_frame


func _advance_until_bite() -> void:
	for _index in range(120):
		_screen._simulator.tick(0.10)
		if _screen._simulator.state == FishingSimulator.State.BITE:
			return
	_expect(false, "simulator did not reach BITE")


func _advance_until_state(target_state: int) -> void:
	for _index in range(240):
		if _screen._simulator.state == target_state:
			return
		_screen._simulator.tick(0.05)
	_expect(false, "simulator did not reach state %d" % target_state)


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


func _push_mouse(position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = position
	event.global_position = position
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	get_viewport().push_input(event, true)
	await get_tree().process_frame


func _wait_for_hit_stop() -> void:
	for _index in range(120):
		await get_tree().process_frame
		if not get_tree().paused:
			return
	_expect(false, "bite hit-stop did not release")


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame


func _has_visible_common_focus(control: Control) -> bool:
	if control == null or not control.has_focus():
		return false
	var indicator := control.get_node_or_null("CommonFocusIndicator") as Control
	return indicator != null and indicator.visible


func _capture(file_name: String, underwater: bool) -> void:
	var environment_key := (
		"TSURI_FISHING_INPUT_FIGHT_EVIDENCE_DIR"
		if underwater
		else "TSURI_FISHING_INPUT_SURFACE_EVIDENCE_DIR"
	)
	var output_dir := OS.get_environment(environment_key).strip_edges()
	if output_dir.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(output_dir)
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	_expect(image != null, "evidence capture requires a real display renderer")
	if _failed:
		return
	_expect(image.get_width() == 1280 and image.get_height() == 720, "evidence must be exact 1280x720")
	if _failed:
		return
	var error := image.save_png(output_dir.path_join(file_name))
	_expect(error == OK, "failed to save evidence: %s" % file_name)


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error(message)
	get_tree().quit(1)
