extends Node

const SettingsScreenScript = preload("res://src/ui/settings_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const ProbeCommon = preload("res://tools/e11_probe_common.gd")
const DESIGN_SIZE := Vector2(1280.0, 720.0)
const EVIDENCE_BGM := "2026-07-15_input_bgm_focus.png"
const EVIDENCE_FULLSCREEN := "2026-07-15_input_fullscreen_focus.png"
const CAPTURE_BGM_FOCUS := &"bgm_focus"
const CAPTURE_FULLSCREEN_FOCUS := &"fullscreen_focus"

var _failed := false
var _navigation_count := 0
var _last_route := ""


func _ready() -> void:
	if not _isolated_home_is_safe():
		push_error("settings_input_smoke: 専用の隔離HOME以外からの実行を拒否しました")
		get_tree().quit(2)
		return
	_verify_capture_contract_self_check()
	if _failed:
		get_tree().quit(1)
		return
	PlayerProgress._sandbox_mode = false
	_reset_fixture()
	SettingsScreenScript.apply_display_settings(SettingsScreenScript.default_settings())
	await _verify_empty_slot_focus_and_controls()
	await _verify_occupied_slot_modal_contract()
	_reset_fixture()
	SettingsScreenScript.apply_display_settings(SettingsScreenScript.default_settings())
	if _failed:
		get_tree().quit(1)
		return
	print("settings_input_smoke: ok")
	get_tree().quit(0)


func _verify_empty_slot_focus_and_controls() -> void:
	_reset_fixture()
	var screen: Variant = await _make_screen()
	var expected: Array[Control] = [
		screen._bgm_slider,
		screen._se_slider,
		screen._fullscreen_button,
		screen._return_button,
	]
	_expect(screen._delete_button.disabled, "empty slot should disable delete")
	_expect(screen._delete_button.focus_mode == Control.FOCUS_NONE, "empty slot delete should leave focus")
	_expect(screen.keyboard_focus_candidates() == expected, "empty slot should expose BGM/SE/fullscreen/return in order")
	_expect(_focus_owner() == screen._bgm_slider, "settings should focus BGM initially")
	for control in [screen._bgm_slider, screen._se_slider, screen._fullscreen_button]:
		_expect(ProbeCommon.has_distinct_focus_style(control), "%s should have a distinct focus signature" % control.name)
		var indicator := control.get_node_or_null(ScreenBase.COMMON_FOCUS_INDICATOR_NAME) as Panel
		_expect(indicator != null, "%s should own the common focus indicator" % control.name)
	_expect(_common_focus_indicator_is_visible(screen._bgm_slider), "focused BGM slider should show the common ring")
	await _capture(EVIDENCE_BGM, screen._bgm_slider, CAPTURE_BGM_FOCUS)

	var bgm_before: float = screen._bgm_slider.value
	await _send_key_action(&"ui_right")
	_expect(screen._bgm_slider.value == bgm_before + screen._bgm_slider.step, "Right should raise BGM by one step")
	await _send_key_action(&"ui_left")
	_expect(screen._bgm_slider.value == bgm_before, "Left should restore BGM by one step")
	var se_before: float = screen._se_slider.value
	screen._se_slider.grab_focus()
	_expect(_common_focus_indicator_is_visible(screen._se_slider), "focused SE slider should show the common ring")
	await _send_key_action(&"ui_right")
	_expect(screen._se_slider.value == se_before + screen._se_slider.step, "Right should raise SE by one step")
	await _send_key_action(&"ui_left")
	_expect(screen._se_slider.value == se_before, "Left should restore SE by one step")
	screen._bgm_slider.grab_focus()

	await _send_key_action(&"ui_focus_next")
	_expect(_focus_owner() == screen._se_slider, "Tab should move BGM to SE")
	await _send_key_action(&"ui_focus_next")
	_expect(_focus_owner() == screen._fullscreen_button, "Tab should move SE to fullscreen")
	_expect(_common_focus_indicator_is_visible(screen._fullscreen_button), "focused fullscreen should show the common ring")
	await _capture(EVIDENCE_FULLSCREEN, screen._fullscreen_button, CAPTURE_FULLSCREEN_FOCUS)
	await _send_key_action(&"ui_focus_next")
	_expect(_focus_owner() == screen._return_button, "empty slot Tab should skip delete and reach return")
	await _send_key_action(&"ui_focus_next")
	_expect(_focus_owner() == screen._bgm_slider, "empty slot Tab should close the focus cycle")
	await _send_key_action(&"ui_up")
	_expect(_focus_owner() == screen._return_button, "Up should reverse the focus cycle")
	await _send_key_action(&"ui_down")
	_expect(_focus_owner() == screen._bgm_slider, "Down should restore the first focus target")

	var fullscreen_count := [0]
	screen._fullscreen_button.pressed.connect(func() -> void: fullscreen_count[0] += 1)
	screen._fullscreen_button.grab_focus()
	await _send_key_action(&"ui_accept")
	_expect(fullscreen_count[0] == 1 and screen._fullscreen, "one Enter should enable fullscreen exactly once")
	screen._fullscreen_button.grab_focus()
	await _send_key_action(&"ui_accept")
	_expect(fullscreen_count[0] == 2 and not screen._fullscreen, "second Enter should restore windowed exactly once")
	await _mouse_click(screen._fullscreen_button)
	_expect(screen._fullscreen, "mouse click should keep fullscreen toggle working")
	await _mouse_click(screen._fullscreen_button)
	_expect(not screen._fullscreen, "second mouse click should restore windowed")

	_reset_route()
	await _send_cancel_with_echo()
	_expect(_navigation_count == 1 and _last_route == "title", "one Escape press including echo should return once")
	await _free_screen(screen)


func _verify_occupied_slot_modal_contract() -> void:
	_reset_fixture()
	_write_slot_artifact(1, {"version": PlayerProgress.SAVE_VERSION, "level": 12, "play_seconds": 9180.0})
	var screen: Variant = await _make_screen()
	var expected: Array[Control] = [
		screen._bgm_slider,
		screen._se_slider,
		screen._fullscreen_button,
		screen._delete_button,
		screen._return_button,
	]
	_expect(not screen._delete_button.disabled, "occupied slot should enable delete")
	_expect(screen.keyboard_focus_candidates() == expected, "occupied slot should include delete in the documented order")
	for control in expected:
		_expect(ProbeCommon.has_distinct_focus_style(control), "%s should keep a distinct focus signature" % control.name)

	for index in range(1, expected.size()):
		await _send_key_action(&"ui_focus_next")
		_expect(_focus_owner() == expected[index], "occupied Tab order should reach %s" % expected[index].name)
	await _send_key_action(&"ui_focus_next")
	_expect(_focus_owner() == screen._bgm_slider, "occupied Tab should close the focus cycle")

	var delete_open_count := [0]
	screen._delete_button.pressed.connect(func() -> void: delete_open_count[0] += 1)
	screen._delete_button.grab_focus()
	await _send_key_action(&"ui_accept")
	_expect(delete_open_count[0] == 1, "one Enter should open delete confirmation exactly once")
	_expect(screen._delete_stage == 1 and screen._delete_modal_layer.visible, "Enter should open confirmation 1")
	_expect(_focus_owner() == screen._delete_confirm_cancel_button, "confirmation 1 should focus safe cancel")
	_expect(_background_focus_is_blocked(screen), "confirmation 1 should block every background focus target")
	_expect(ProbeCommon.has_distinct_focus_style(screen._delete_confirm_cancel_button), "confirmation 1 safe focus should be visible")
	await _send_key_action(&"ui_accept")
	_expect(screen._delete_stage == 0 and not screen._delete_modal_layer.visible, "Enter on safe cancel should close confirmation 1")
	_expect(_focus_owner() == screen._delete_button, "safe cancel should restore delete focus")

	await _send_key_action(&"ui_accept")
	_expect(screen._delete_stage == 1, "delete focus Enter should reopen confirmation 1")
	await _send_key_action(&"ui_focus_next")
	_expect(_focus_owner() == screen._delete_continue_button, "confirmation 1 Tab should reach continue")
	await _send_key_action(&"ui_accept")
	_expect(screen._delete_stage == 2, "continue Enter should open confirmation 2")
	_expect(_focus_owner() == screen._delete_final_cancel_button, "confirmation 2 should focus safe back")
	_expect(_background_focus_is_blocked(screen), "confirmation 2 should keep background focus blocked")
	await _send_key_action(&"ui_cancel")
	_expect(screen._delete_stage == 1, "confirmation 2 Escape should return to confirmation 1")
	_expect(_focus_owner() == screen._delete_confirm_cancel_button, "confirmation 2 Escape should restore safe cancel")
	await _send_key_action(&"ui_cancel")
	_expect(screen._delete_stage == 0 and not screen._delete_modal_layer.visible, "confirmation 1 Escape should close modal")
	_expect(_focus_owner() == screen._delete_button, "modal Escape should restore delete focus")

	await _mouse_click(screen._delete_button)
	_expect(screen._delete_stage == 1, "mouse delete should keep opening confirmation 1")
	await _mouse_click(screen._delete_confirm_cancel_button)
	_expect(screen._delete_stage == 0 and _focus_owner() == screen._delete_button, "mouse cancel should close and restore delete focus")
	await _free_screen(screen)


func _make_screen() -> Variant:
	var screen := SettingsScreenScript.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({"return_screen_id": "title", "target_slot_id": 1})
	screen.size = DESIGN_SIZE
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
	var event := _keyboard_event_for_action(action)
	_expect(event != null, "%s should have a real keyboard event" % action)
	if event == null:
		return
	var pressed := event.duplicate() as InputEventKey
	pressed.pressed = true
	pressed.echo = false
	get_viewport().push_input(pressed, true)
	await get_tree().process_frame
	var released := event.duplicate() as InputEventKey
	released.pressed = false
	released.echo = false
	get_viewport().push_input(released, true)
	await _settle()


func _send_cancel_with_echo() -> void:
	var event := _keyboard_event_for_action(&"ui_cancel")
	_expect(event != null, "ui_cancel should have a real keyboard event")
	if event == null:
		return
	var pressed := event.duplicate() as InputEventKey
	pressed.pressed = true
	pressed.echo = false
	get_viewport().push_input(pressed, true)
	await get_tree().process_frame
	var echo := pressed.duplicate() as InputEventKey
	echo.echo = true
	get_viewport().push_input(echo, true)
	await get_tree().process_frame
	var released := event.duplicate() as InputEventKey
	released.pressed = false
	released.echo = false
	get_viewport().push_input(released, true)
	await _settle()


func _keyboard_event_for_action(action: StringName) -> InputEventKey:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return event as InputEventKey
	return null


func _mouse_click(control: Control) -> void:
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


func _capture(file_name: String, expected_focus: Control, state: StringName) -> void:
	var output_dir := OS.get_environment("TSURI_SETTINGS_INPUT_EVIDENCE_DIR").strip_edges()
	if output_dir.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(output_dir)
	await _settle()
	await get_tree().create_timer(0.45).timeout
	var image: Image
	var capture_attempt := 0
	var missing_anchors: Array[String] = []
	for attempt in range(12):
		capture_attempt = attempt + 1
		_expect(_focus_owner() == expected_focus, "evidence capture should preserve expected focus: %s" % file_name)
		if _failed:
			return
		RenderingServer.force_draw(false, 0.0)
		await get_tree().process_frame
		RenderingServer.force_draw(false, 0.0)
		image = get_viewport().get_texture().get_image()
		missing_anchors = _missing_capture_anchors(image, state)
		if missing_anchors.is_empty():
			break
		await get_tree().process_frame
	_expect(image != null and not image.is_empty(), "evidence capture requires a real display renderer")
	if _failed:
		return
	_expect(image.get_size() == Vector2i(1280, 720), "evidence must be exact 1280x720")
	if _failed:
		return
	_expect(
		missing_anchors.is_empty(),
		"evidence capture is missing required regions for %s: %s" % [file_name, ", ".join(missing_anchors)]
	)
	if _failed:
		return
	_expect(_capture_contract_rejects_missing_regions(image, state), "capture missing-region self-check failed: %s" % file_name)
	if _failed:
		return
	print(
		"settings_input_capture[%s]: attempt=%d anchors=%s"
		% [file_name, capture_attempt, _format_capture_anchor_counts(image, state)]
	)
	# 不透明なQA証拠はRGB8へ正規化し、decoderごとのalpha合成差を避ける。
	var evidence_image: Image = image.duplicate()
	evidence_image.convert(Image.FORMAT_RGB8)
	var error := evidence_image.save_png(output_dir.path_join(file_name))
	_expect(error == OK, "failed to save evidence: %s" % file_name)


func _missing_capture_anchors(image: Image, state: StringName) -> Array[String]:
	var missing: Array[String] = []
	if image == null or image.is_empty() or image.get_size() != Vector2i(1280, 720):
		missing.append("frame_size")
		return missing
	if not _frame_samples_are_opaque(image):
		missing.append("frame_opacity")
	for anchor in _capture_anchor_specs(state):
		var count := _capture_anchor_count(image, anchor)
		var mode := StringName(anchor["mode"])
		if mode == &"maximum":
			var maximum := int(anchor["maximum"])
			if not _capture_anchor_passes(count, anchor):
				missing.append("%s=%d>%d" % [anchor["name"], count, maximum])
		else:
			var minimum := int(anchor["minimum"])
			if not _capture_anchor_passes(count, anchor):
				missing.append("%s=%d<%d" % [anchor["name"], count, minimum])
	return missing


func _capture_anchor_specs(state: StringName) -> Array[Dictionary]:
	var anchors: Array[Dictionary] = [
		_bright_anchor("title", Rect2i(360, 42, 560, 56), 0.30, 80),
		_bright_anchor("panel_left", Rect2i(185, 145, 80, 70), 0.18, 300),
		_bright_anchor("panel_right", Rect2i(1040, 145, 45, 70), 0.18, 200),
		_bright_anchor("bgm_row", Rect2i(245, 214, 205, 62), 0.30, 80),
		_bright_anchor("se_row", Rect2i(245, 284, 205, 62), 0.30, 60),
		_bright_anchor("delete_block", Rect2i(245, 352, 330, 90), 0.30, 120),
		_bright_anchor("footer", Rect2i(240, 488, 790, 62), 0.22, 600),
		_bright_anchor("return_button", Rect2i(920, 616, 276, 60), 0.25, 300),
		_bright_anchor("fullscreen_button", Rect2i(690, 160, 330, 46), 0.25, 500),
	]
	if state == CAPTURE_BGM_FOCUS:
		anchors.append(_focus_anchor("bgm_focus_top", Rect2i(442, 221, 390, 4), 1000))
		anchors.append(_focus_anchor("bgm_focus_left", Rect2i(442, 221, 4, 48), 100))
		anchors.append(_inactive_focus_anchor("fullscreen_focus_absent", Rect2i(680, 154, 350, 4), 16))
	else:
		anchors.append(_focus_anchor("fullscreen_focus_top", Rect2i(680, 154, 350, 4), 1000))
		anchors.append(_focus_anchor("fullscreen_focus_left", Rect2i(680, 154, 4, 58), 100))
		anchors.append(_inactive_focus_anchor("bgm_focus_absent", Rect2i(442, 221, 390, 4), 16))
	return anchors


func _bright_anchor(name: String, rect: Rect2i, threshold: float, minimum: int) -> Dictionary:
	return {"name": name, "rect": rect, "mode": &"minimum", "kind": &"bright", "threshold": threshold, "minimum": minimum}


func _focus_anchor(name: String, rect: Rect2i, minimum: int) -> Dictionary:
	return {"name": name, "rect": rect, "mode": &"minimum", "kind": &"focus", "minimum": minimum}


func _inactive_focus_anchor(name: String, rect: Rect2i, maximum: int) -> Dictionary:
	return {"name": name, "rect": rect, "mode": &"maximum", "kind": &"focus", "maximum": maximum}


func _capture_anchor_count(image: Image, anchor: Dictionary) -> int:
	var rect: Rect2i = anchor["rect"]
	var count := 0
	if StringName(anchor["kind"]) == &"focus":
		for y in range(rect.position.y, rect.end.y):
			for x in range(rect.position.x, rect.end.x):
				if _pixel_matches_focus_color(image.get_pixel(x, y)):
					count += 1
		return count
	var threshold := float(anchor["threshold"])
	for y in range(rect.position.y, rect.end.y, 2):
		for x in range(rect.position.x, rect.end.x, 2):
			var pixel := image.get_pixel(x, y)
			if pixel.a > 0.99 and pixel.get_luminance() > threshold:
				count += 1
	return count


func _capture_anchor_passes(count: int, anchor: Dictionary) -> bool:
	if StringName(anchor["mode"]) == &"maximum":
		return count <= int(anchor["maximum"])
	return count >= int(anchor["minimum"])


func _pixel_matches_focus_color(pixel: Color) -> bool:
	return (
		pixel.a > 0.99
		and absf(pixel.r - Palette.GOLD_BRIGHT.r) <= 0.01
		and absf(pixel.g - Palette.GOLD_BRIGHT.g) <= 0.01
		and absf(pixel.b - Palette.GOLD_BRIGHT.b) <= 0.01
	)


func _frame_samples_are_opaque(image: Image) -> bool:
	for y in range(0, 720, 4):
		for x in range(0, 1280, 4):
			if image.get_pixel(x, y).a <= 0.99:
				return false
	return true


func _format_capture_anchor_counts(image: Image, state: StringName) -> String:
	var parts: PackedStringArray = []
	for anchor in _capture_anchor_specs(state):
		parts.append("%s:%d" % [anchor["name"], _capture_anchor_count(image, anchor)])
	return "|".join(parts)


func _capture_contract_rejects_missing_regions(image: Image, state: StringName) -> bool:
	for anchor in _capture_anchor_specs(state):
		var fixture: Image = image.duplicate()
		var rect: Rect2i = anchor["rect"]
		if StringName(anchor["mode"]) == &"maximum":
			fixture.fill_rect(rect, Palette.GOLD_BRIGHT)
		else:
			fixture.fill_rect(rect, Color.BLACK)
		if _capture_anchor_passes(_capture_anchor_count(fixture, anchor), anchor):
			return false
		if _missing_capture_anchors(fixture, state).is_empty():
			return false
	return true


func _verify_capture_contract_self_check() -> void:
	for state in [CAPTURE_BGM_FOCUS, CAPTURE_FULLSCREEN_FOCUS]:
		var complete := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
		complete.fill(Palette.SEA_DEEP)
		for anchor in _capture_anchor_specs(state):
			var rect: Rect2i = anchor["rect"]
			if StringName(anchor["mode"]) == &"maximum":
				continue
			complete.fill_rect(rect, Palette.GOLD_BRIGHT if StringName(anchor["kind"]) == &"focus" else Color.WHITE)
		_expect(_missing_capture_anchors(complete, state).is_empty(), "synthetic complete capture should pass: %s" % state)
		if _failed:
			return
		var background_only := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
		background_only.fill(Palette.SEA_DEEP)
		_expect(not _missing_capture_anchors(background_only, state).is_empty(), "background-only capture must fail: %s" % state)
		if _failed:
			return
		_expect(_capture_contract_rejects_missing_regions(complete, state), "every missing anchor fixture must fail: %s" % state)
		if _failed:
			return


func _common_focus_indicator_is_visible(control: Control) -> bool:
	var indicator := control.get_node_or_null(ScreenBase.COMMON_FOCUS_INDICATOR_NAME) as Panel
	return control.has_focus() and indicator != null and indicator.visible


func _background_focus_is_blocked(screen: Variant) -> bool:
	for control in [
		screen._bgm_slider,
		screen._se_slider,
		screen._fullscreen_button,
		screen._delete_button,
		screen._return_button,
	]:
		if control.focus_mode != Control.FOCUS_NONE:
			return false
	return true


func _focus_owner() -> Control:
	return get_viewport().gui_get_focus_owner()


func _free_screen(screen: Node) -> void:
	if screen != null and is_instance_valid(screen):
		screen.queue_free()
	await _settle()
	get_viewport().gui_release_focus()


func _settle() -> void:
	for _frame in range(4):
		await get_tree().process_frame


func _reset_fixture() -> void:
	PlayerProgress._save_storage_ready = true
	PlayerProgress._save_storage_block_message = ""
	PlayerProgress._delete_failure_injection_stage = ""
	PlayerProgress.active_save_slot = PlayerProgress.DEFAULT_SAVE_SLOT
	for slot_id in range(1, PlayerProgress.SAVE_SLOT_COUNT + 1):
		for path in PlayerProgress._slot_save_paths(slot_id):
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var settings_path := ProjectSettings.globalize_path(SettingsScreenScript.SETTINGS_PATH)
	if FileAccess.file_exists(SettingsScreenScript.SETTINGS_PATH):
		DirAccess.remove_absolute(settings_path)


func _write_slot_artifact(slot_id: int, data: Dictionary) -> void:
	var path: String = PlayerProgress._slot_save_paths(slot_id)[0]
	var absolute := ProjectSettings.globalize_path(path)
	var error := DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	_expect(error == OK or error == ERR_ALREADY_EXISTS, "slot fixture directory should be writable")
	var file := FileAccess.open(path, FileAccess.WRITE)
	_expect(file != null, "slot fixture should open")
	if file == null:
		return
	file.store_string(JSON.stringify(data, "\t"))
	var write_error := file.get_error()
	file.close()
	_expect(write_error == OK, "slot fixture should be written")


func _isolated_home_is_safe() -> bool:
	var raw_home := OS.get_environment("HOME")
	var home := raw_home.simplify_path()
	var user_data := ProjectSettings.globalize_path("user://").simplify_path()
	var manual_home := (
		OS.get_environment("TSURI_SETTINGS_INPUT_SMOKE_ALLOW") == "1"
		and home.begins_with("/private/tmp/tsuri_settings_input_smoke_")
	)
	var release_home := (
		(home.begins_with("/private/tmp/") or home.begins_with("/private/var/folders/"))
		and home.get_file().begins_with("test_")
		and home.get_base_dir().get_file().begins_with("tsuri_release_verify_home_")
	)
	if (
		not (manual_home or release_home)
		or raw_home != raw_home.strip_edges()
		or raw_home.contains("..")
		or not user_data.begins_with(home + "/")
	):
		return false
	return _existing_path_ancestors_are_physical(home) and _existing_path_ancestors_are_physical(user_data)


func _existing_path_ancestors_are_physical(path: String) -> bool:
	var current := "/"
	for component in path.trim_prefix("/").split("/", false):
		var parent := DirAccess.open(current)
		if parent == null or parent.is_link(component):
			return false
		current = current.path_join(component)
		if not DirAccess.dir_exists_absolute(current) and not FileAccess.file_exists(current):
			return true
	return true


func _expect(condition: bool, message: String) -> void:
	if condition or _failed:
		return
	_failed = true
	push_error("settings_input_smoke: %s" % message)
