extends Node

const TitleScreenScript = preload("res://src/ui/title_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")

var _failed := false


func _ready() -> void:
	if not _isolated_home_is_safe():
		push_error("title_input_smoke: 専用の隔離HOME以外からの実行を拒否しました")
		get_tree().quit(2)
		return
	PlayerProgress._sandbox_mode = true
	_reset_fixture()
	await _verify_normal_and_modal_input()
	await _verify_storage_blocked_focus()
	await _verify_future_guard_focus()
	await _verify_invalid_artifact_focus()
	await _verify_occupied_overwrite_focus()
	_reset_fixture()
	if _failed:
		get_tree().quit(1)
		return
	print("title_input_smoke: ok")
	get_tree().quit(0)


func _verify_normal_and_modal_input() -> void:
	_reset_fixture()
	var screen := await _make_screen()
	_expect(_focus_owner() == screen._slot_buttons[0], "empty title should focus selected slot 1")
	_expect(screen.keyboard_focus_candidates().size() == 5, "empty title should skip disabled continue")

	await _send_action(&"ui_down")
	_expect(_focus_owner() == screen._slot_buttons[1], "down should move slot 1 to slot 2")
	await _send_action(&"ui_down")
	_expect(_focus_owner() == screen._slot_buttons[2], "down should move slot 2 to slot 3")
	await _send_action(&"ui_down")
	_expect(_focus_owner() == screen._new_button, "empty title should skip disabled continue")
	await _send_action(&"ui_down")
	_expect(_focus_owner() == screen._settings_button, "down should reach settings")
	await _send_action(&"ui_focus_next")
	_expect(_focus_owner() == screen._slot_buttons[0], "Tab should close the title focus cycle")
	await _send_action(&"ui_focus_prev")
	_expect(_focus_owner() == screen._settings_button, "Shift+Tab should reverse the title focus cycle")

	await _mouse_click(screen._slot_buttons[1])
	_expect(screen._selected_slot_id == 2, "mouse click should keep slot selection working")
	screen._new_button.grab_focus()
	await _send_action(&"ui_accept")
	_expect(screen._modal_layer.visible, "Enter on new game should open difficulty modal")
	_expect(
		_focus_owner() == screen._difficulty_buttons[GameData.DEFAULT_DIFFICULTY_ID],
		"difficulty modal should focus the default choice"
	)
	_expect(screen.keyboard_focus_candidates().size() == 4, "difficulty modal should own four focus targets")
	_expect(_background_has_no_focus_mode(screen), "difficulty modal should block background focus")
	await _send_action(&"ui_cancel")
	_expect(not screen._modal_layer.visible, "Escape should close difficulty modal once")
	_expect(_focus_owner() == screen._new_button, "difficulty cancel should restore new-game focus")

	await _mouse_click(screen._new_button)
	_expect(screen._modal_layer.visible, "mouse click should still open difficulty modal")
	await _mouse_click(screen._difficulty_cancel_button)
	_expect(not screen._modal_layer.visible, "mouse click should still close difficulty modal")
	_expect(_focus_owner() == screen._new_button, "mouse cancel should restore caller focus")
	await _free_screen(screen)


func _verify_storage_blocked_focus() -> void:
	_reset_fixture()
	PlayerProgress._save_storage_ready = false
	PlayerProgress._save_storage_block_message = "入力smoke: 再起動してください"
	var screen := await _make_screen()
	_expect(_focus_owner() == screen._settings_button, "storage blocked should focus the only safe action")
	_expect(screen.keyboard_focus_candidates() == [screen._settings_button], "storage blocked should expose settings only")
	for button in screen._slot_buttons + [screen._continue_button, screen._new_button]:
		_expect(button.focus_mode == Control.FOCUS_NONE, "storage blocked should remove disabled action from focus")
	await _send_action(&"ui_down")
	_expect(_focus_owner() == screen._settings_button, "storage blocked focus should remain on settings")
	await _free_screen(screen)
	PlayerProgress._save_storage_ready = true
	PlayerProgress._save_storage_block_message = ""


func _verify_future_guard_focus() -> void:
	_reset_fixture()
	_write_slot_main(1, {"version": PlayerProgress.SAVE_VERSION + 1, "level": 8})
	var screen := await _make_screen()
	_expect(_focus_owner() == screen._slot_buttons[0], "future guard should focus the guarded slot safely")
	_expect(screen._continue_button.disabled and screen._new_button.disabled, "future guard should disable destructive actions")
	_expect(not screen.keyboard_focus_candidates().has(screen._continue_button), "future guard should skip continue")
	_expect(not screen.keyboard_focus_candidates().has(screen._new_button), "future guard should skip new game")
	await _verify_available_cycle(screen)
	await _free_screen(screen)


func _verify_invalid_artifact_focus() -> void:
	_reset_fixture()
	_write_slot_main(1, {"version": PlayerProgress.SAVE_VERSION, "level": {}})
	var screen := await _make_screen()
	_expect(_focus_owner() == screen._slot_buttons[0], "invalid artifact should focus the affected slot safely")
	_expect(screen._continue_button.disabled and screen._new_button.disabled, "invalid artifact should disable destructive actions")
	_expect(not screen.keyboard_focus_candidates().has(screen._continue_button), "invalid artifact should skip continue")
	_expect(not screen.keyboard_focus_candidates().has(screen._new_button), "invalid artifact should skip new game")
	await _verify_available_cycle(screen)
	await _free_screen(screen)


func _verify_occupied_overwrite_focus() -> void:
	_reset_fixture()
	_write_slot_main(1, {
		"version": PlayerProgress.SAVE_VERSION,
		"level": 12,
		"money": 12450,
		"play_seconds": 45240.0,
		"difficulty_id": "normal",
	})
	var screen := await _make_screen()
	_expect(_focus_owner() == screen._slot_buttons[0], "occupied title should focus selected slot 1")
	_expect(not screen._continue_button.disabled and not screen._new_button.disabled, "occupied title should enable both actions")

	screen._new_button.grab_focus()
	await _send_action(&"ui_accept")
	var default_button: Button = screen._difficulty_buttons[GameData.DEFAULT_DIFFICULTY_ID]
	var accept_count := [0]
	default_button.pressed.connect(func() -> void: accept_count[0] += 1)
	await _send_action(&"ui_accept")
	_expect(accept_count[0] == 1, "one Enter press should fire difficulty decision once")
	_expect(screen._overwrite_panel.visible, "occupied slot should open overwrite confirmation")
	_expect(_focus_owner() == screen._overwrite_cancel_button, "overwrite confirmation should initially focus cancel")
	_expect(screen.keyboard_focus_candidates().size() == 2, "overwrite modal should own confirm and cancel only")
	_expect(_background_has_no_focus_mode(screen), "overwrite modal should block background focus")
	await _send_action(&"ui_left")
	_expect(_focus_owner() == screen._overwrite_confirm_button, "overwrite left should reach confirm")
	await _send_action(&"ui_right")
	_expect(_focus_owner() == screen._overwrite_cancel_button, "overwrite right should return to cancel")
	await _send_action(&"ui_cancel")
	_expect(not screen._modal_layer.visible, "Escape should close overwrite confirmation")
	_expect(_focus_owner() == screen._new_button, "overwrite cancel should restore caller focus")
	await _free_screen(screen)


func _verify_available_cycle(screen: Control) -> void:
	var expected: Array[Control] = screen.keyboard_focus_candidates()
	var reached := {}
	for _step in range(expected.size()):
		var owner := _focus_owner()
		if owner != null:
			reached[owner.get_instance_id()] = true
		await _send_action(&"ui_down")
	for control in expected:
		_expect(reached.has(control.get_instance_id()), "focus cycle should reach every enabled title action")
		_expect(not (control is BaseButton and control.disabled), "focus cycle should never include disabled action")


func _make_screen() -> Control:
	var screen := TitleScreenScript.new()
	screen.theme = ThemeFactory.build_theme()
	add_child(screen)
	for _frame in range(4):
		await get_tree().process_frame
	return screen


func _free_screen(screen: Control) -> void:
	if screen != null and is_instance_valid(screen):
		screen.queue_free()
	for _frame in range(2):
		await get_tree().process_frame
	get_viewport().gui_release_focus()


func _send_action(action: StringName) -> void:
	var template := _keyboard_event_for_action(action)
	_expect(template != null, "%s should have a keyboard event" % action)
	if template == null:
		return
	var pressed := template.duplicate() as InputEventKey
	pressed.pressed = true
	pressed.echo = false
	get_viewport().push_input(pressed)
	await get_tree().process_frame
	var released := template.duplicate() as InputEventKey
	released.pressed = false
	released.echo = false
	get_viewport().push_input(released)
	await get_tree().process_frame


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
	var pressed := InputEventMouseButton.new()
	pressed.button_index = MOUSE_BUTTON_LEFT
	pressed.button_mask = MOUSE_BUTTON_MASK_LEFT
	pressed.position = position
	pressed.global_position = position
	pressed.pressed = true
	get_viewport().push_input(pressed, true)
	var released := pressed.duplicate() as InputEventMouseButton
	released.button_mask = 0
	released.pressed = false
	get_viewport().push_input(released, true)
	await get_tree().process_frame
	await get_tree().process_frame


func _background_has_no_focus_mode(screen: Control) -> bool:
	for button in screen._slot_buttons + [screen._continue_button, screen._new_button, screen._settings_button]:
		if button.focus_mode != Control.FOCUS_NONE:
			return false
	return true


func _focus_owner() -> Control:
	return get_viewport().gui_get_focus_owner()


func _reset_fixture() -> void:
	PlayerProgress._save_storage_ready = true
	PlayerProgress._save_storage_block_message = ""
	PlayerProgress.active_save_slot = PlayerProgress.DEFAULT_SAVE_SLOT
	for slot_id in range(1, PlayerProgress.SAVE_SLOT_COUNT + 1):
		for path in PlayerProgress._slot_save_paths(slot_id):
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)


func _write_slot_main(slot_id: int, data: Dictionary) -> void:
	var path := PlayerProgress._slot_save_paths(slot_id)[0]
	var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	_expect(error == OK or error == ERR_ALREADY_EXISTS, "fixture directory should be writable")
	var file := FileAccess.open(path, FileAccess.WRITE)
	_expect(file != null, "fixture save should open")
	if file == null:
		return
	file.store_string(JSON.stringify(data, "\t"))
	var write_error := file.get_error()
	file.close()
	_expect(write_error == OK, "fixture save should be written")


func _isolated_home_is_safe() -> bool:
	var raw_home := OS.get_environment("HOME")
	var home := raw_home.simplify_path()
	var user_data := ProjectSettings.globalize_path("user://").simplify_path()
	var manual_home := (
		OS.get_environment("TSURI_TITLE_INPUT_SMOKE_ALLOW") == "1"
		and home.begins_with("/private/tmp/tsuri_title_input_smoke_")
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
	if condition:
		return
	_failed = true
	push_error("title_input_smoke: %s" % message)
