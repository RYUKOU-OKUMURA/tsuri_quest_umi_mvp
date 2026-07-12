extends Node

const SettingsScreenScript = preload("res://src/ui/settings_screen.gd")
const TitleScreenScript = preload("res://src/ui/title_screen.gd")
const HarborScreenScript = preload("res://src/ui/harbor_screen.gd")
const MainScript = preload("res://src/main.gd")
const ScreenBaseScript = preload("res://src/ui/screen_base.gd")
const CatchFanfareScript = preload("res://src/ui/components/catch_fanfare.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const IsolationGuard = preload("res://tools/settings_isolation_guard.gd")
const BGM_FIXTURE := "res://assets/audio/opening_bgm.mp3"
const SE_FIXTURE := "res://assets/audio/逃げられた.mp3"

var _failed := false
var _route_id := ""
var _route_payload: Dictionary = {}


func _ready() -> void:
	var raw_home_probe := OS.get_environment("TSURI_QA_REJECT_RAW_HOME_PROBE")
	if not raw_home_probe.is_empty():
		if IsolationGuard.raw_absolute_path_is_unambiguous(raw_home_probe):
			push_error("settings_smoke: rejection-only raw HOME probeが曖昧pathを拒否しませんでした")
			get_tree().quit(1)
		else:
			get_tree().quit(2)
		return
	if (
		OS.get_environment("TSURI_SETTINGS_SMOKE_ALLOW") != "1"
		or not _isolated_home_matches()
	):
		push_error("settings_smoke: 隔離runner以外からの実行を拒否しました")
		get_tree().quit(2)
		return
	PlayerProgress._sandbox_mode = false
	_cleanup_test_artifacts()
	_verify_bus_layout()
	await _verify_player_bus_connections()
	await _verify_defaults_and_input_contract()
	await _verify_slider_bus_save_reload_restore()
	_verify_corruption_recovery()
	await _verify_title_and_harbor_routes()
	await _verify_slot_target_and_confirmation_flow()
	await _verify_guarded_and_invalid_artifacts_are_deletable()
	await _verify_tmp_only_and_partial_delete_retries()
	await _verify_delete_success_file_integration()
	await _verify_delete_failure_stays_on_screen()
	await _verify_storage_blocked_message_priority()
	_cleanup_test_artifacts()
	if _failed:
		get_tree().quit(1)
		return
	print("settings_smoke: ok")
	get_tree().quit(0)


func _isolated_home_matches() -> bool:
	var raw_expected := OS.get_environment("TSURI_QA_ISOLATED_HOME")
	var raw_actual := OS.get_environment("HOME")
	if not IsolationGuard.raw_absolute_path_is_unambiguous(raw_expected) or not IsolationGuard.raw_absolute_path_is_unambiguous(raw_actual):
		return false
	var expected := raw_expected.simplify_path()
	var actual := raw_actual.simplify_path()
	var token := OS.get_environment("TSURI_QA_RUN_TOKEN")
	var sentinel_path := expected.path_join(".tsuri_settings_qa_guard")
	var user_data_path := ProjectSettings.globalize_path("user://").simplify_path()
	return (
		not expected.is_empty()
		and not token.is_empty()
		and expected.is_absolute_path()
		and actual.is_absolute_path()
		and expected == actual
		and _write_targets_have_physical_ancestors(expected, user_data_path)
		and (user_data_path == expected or user_data_path.begins_with(expected + "/"))
		and FileAccess.file_exists(sentinel_path)
		and _read_guard_token(sentinel_path) == token
	)


func _read_guard_token(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func _write_targets_have_physical_ancestors(expected: String, user_data_path: String) -> bool:
	var paths: Array[String] = [
		expected,
		user_data_path,
		ProjectSettings.globalize_path(SettingsScreenScript.SETTINGS_PATH).get_base_dir().simplify_path(),
		ProjectSettings.globalize_path(PlayerProgress.SAVE_SLOT_ROOT).simplify_path(),
	]
	for slot_id in range(1, PlayerProgress.SAVE_SLOT_COUNT + 1):
		var slot_root := ProjectSettings.globalize_path("%s/%d" % [PlayerProgress.SAVE_SLOT_ROOT, slot_id]).simplify_path()
		paths.append(slot_root)
		for file_name in [PlayerProgress.SAVE_FILE_NAME, PlayerProgress.SAVE_BACKUP_FILE_NAME, PlayerProgress.SAVE_TMP_FILE_NAME]:
			paths.append(slot_root.path_join(file_name).get_base_dir())
	for path in paths:
		if not _existing_path_ancestors_are_physical(path):
			return false
	return true


func _existing_path_ancestors_are_physical(path: String) -> bool:
	var current := "/"
	for component in path.trim_prefix("/").split("/", false):
		var parent_dir := DirAccess.open(current)
		if parent_dir == null or parent_dir.is_link(component):
			return false
		current = current.path_join(component)
		if not DirAccess.dir_exists_absolute(current) and not FileAccess.file_exists(current):
			return true
	return true


func _verify_bus_layout() -> void:
	var bgm_index := AudioServer.get_bus_index(&"BGM")
	var se_index := AudioServer.get_bus_index(&"SE")
	_expect(bgm_index >= 0, "BGM bus should exist")
	_expect(se_index >= 0, "SE bus should exist")
	_expect(AudioServer.get_bus_send(bgm_index) == &"Master", "BGM bus should send to Master")
	_expect(AudioServer.get_bus_send(se_index) == &"Master", "SE bus should send to Master")


func _verify_player_bus_connections() -> void:
	var main := MainScript.new()
	add_child(main)
	await _settle()
	main.play_app_bgm(BGM_FIXTURE)
	_expect(main._app_bgm_player != null and main._app_bgm_player.bus == &"BGM", "main app BGM player should use BGM bus")
	main.stop_app_bgm()
	await _free_node(main)
	var base := ScreenBaseScript.new()
	add_child(base)
	await _settle()
	base.play_screen_bgm(BGM_FIXTURE)
	_expect(base._screen_bgm_player != null and base._screen_bgm_player.bus == &"BGM", "screen BGM player should use BGM bus")
	base.play_screen_sfx(SE_FIXTURE)
	var sfx_player := base.get_node_or_null("ScreenSFXPlayer") as AudioStreamPlayer
	_expect(sfx_player != null and sfx_player.bus == &"SE", "screen SFX player should use SE bus")
	await _free_node(base)
	var fanfare := CatchFanfareScript.new()
	add_child(fanfare)
	await _settle()
	_expect(fanfare._audio_player != null and fanfare._audio_player.bus == &"SE", "catch fanfare should use SE bus")
	await _free_node(fanfare)


func _verify_defaults_and_input_contract() -> void:
	var screen: Variant = await _make_settings({"return_screen_id": "title"})
	_expect(int(screen._bgm_slider.value) == SettingsScreenScript.DEFAULT_BGM_VOLUME, "missing file should use default BGM")
	_expect(int(screen._se_slider.value) == SettingsScreenScript.DEFAULT_SE_VOLUME, "missing file should use default SE")
	_expect(screen._bgm_value_label.text == "80%", "default BGM percentage should be visible")
	_expect(screen._se_value_label.text == "80%", "default SE percentage should be visible")
	_expect(screen._return_button.text == "タイトルへ戻る", "title entry should restore title return label")
	_expect(screen._bgm_slider.focus_neighbor_bottom == screen._bgm_slider.get_path_to(screen._se_slider), "BGM focus should lead to SE")
	_expect(screen._se_slider.focus_neighbor_bottom == screen._se_slider.get_path_to(screen._return_button), "empty slot focus graph should skip slot delete")
	_expect(get_viewport().gui_get_focus_owner() == screen._bgm_slider, "BGM slider should own initial focus")
	var initial_bgm: float = screen._bgm_slider.value
	await _send_action("ui_right")
	_expect(screen._bgm_slider.value > initial_bgm, "ui_right should change the focused BGM slider")
	await _send_action("ui_down")
	_expect(get_viewport().gui_get_focus_owner() == screen._se_slider, "ui_down should move focus from BGM to SE")
	_reset_route()
	await _send_action("ui_cancel")
	_expect(_route_id == "title", "ui_cancel should return to title entry")
	_expect(screen.find_child("Fullscreen", true, false) == null, "fullscreen UI is outside this slice")
	_expect(screen._target_slot_id == 1, "invalid or missing title target should use safe slot 1")
	_expect(screen._delete_button.disabled, "empty slot delete should be disabled")
	screen._se_slider.grab_focus()
	await _send_action("ui_down")
	_expect(get_viewport().gui_get_focus_owner() == screen._return_button, "empty slot focus should skip disabled delete")
	await _free_node(screen)


func _verify_slider_bus_save_reload_restore() -> void:
	var screen: Variant = await _make_settings({"return_screen_id": "harbor"})
	screen._bgm_slider.value = 35
	screen._se_slider.value = 0
	await get_tree().process_frame
	var bgm_index := AudioServer.get_bus_index(&"BGM")
	var se_index := AudioServer.get_bus_index(&"SE")
	_expect(not AudioServer.is_bus_mute(bgm_index), "positive BGM value should not mute bus")
	_expect(absf(db_to_linear(AudioServer.get_bus_volume_db(bgm_index)) - 0.35) < 0.01, "BGM slider should update BGM bus")
	_expect(AudioServer.is_bus_mute(se_index), "zero SE value should mute SE bus")
	var saved := SettingsScreenScript.load_settings()
	_expect(int(saved["bgm_volume"]) == 35 and int(saved["se_volume"]) == 0, "slider changes should persist")
	await _free_node(screen)
	var restored: Variant = await _make_settings({"return_screen_id": "harbor"})
	_expect(int(restored._bgm_slider.value) == 35, "recreated screen should restore BGM slider")
	_expect(int(restored._se_slider.value) == 0, "recreated screen should restore SE slider")
	_expect(restored._return_button.text == "港へ戻る", "harbor entry should restore harbor return label")
	await _free_node(restored)


func _verify_corruption_recovery() -> void:
	_write_raw("{ broken")
	var broken := SettingsScreenScript.load_settings()
	_expect(broken == SettingsScreenScript.default_settings(), "broken JSON should recover defaults")
	_write_raw(JSON.stringify({"version": 1, "bgm_volume": "loud", "se_volume": 200}))
	var invalid := SettingsScreenScript.load_settings()
	_expect(invalid == SettingsScreenScript.default_settings(), "invalid types and range should recover defaults")
	_write_raw(JSON.stringify({"version": {}, "bgm_volume": 40, "se_volume": 60}))
	var invalid_version := SettingsScreenScript.load_settings()
	_expect(invalid_version == SettingsScreenScript.default_settings(), "non-numeric version should recover defaults")
	_expect(FileAccess.file_exists(SettingsScreenScript.SETTINGS_PATH), "recovery should leave a normalized settings file")


func _verify_title_and_harbor_routes() -> void:
	var title := TitleScreenScript.new()
	title.theme = ThemeFactory.build_theme()
	title.navigate_requested.connect(_capture_route)
	add_child(title)
	await _settle()
	_expect(title._settings_button != null, "title should expose settings button")
	title._select_slot(2)
	title._settings_button.grab_focus()
	await _send_action("ui_accept")
	_expect(_route_id == "settings" and String(_route_payload.get("return_screen_id", "")) == "title", "title route should carry title return payload")
	_expect(int(_route_payload.get("target_slot_id", 0)) == 2, "title route should carry the selected slot")
	await _free_node(title)
	_reset_route()
	var harbor := HarborScreenScript.new()
	PlayerProgress.set_active_save_slot(3, false)
	harbor.theme = ThemeFactory.build_theme()
	harbor.navigate_requested.connect(_capture_route)
	add_child(harbor)
	await _settle()
	_expect(harbor._settings_button != null, "harbor should expose settings button")
	harbor._settings_button.grab_focus()
	await _send_action("ui_accept")
	_expect(_route_id == "settings" and String(_route_payload.get("return_screen_id", "")) == "harbor", "harbor route should carry harbor return payload")
	await _free_node(harbor)
	PlayerProgress.set_active_save_slot(1, false)


func _verify_slot_target_and_confirmation_flow() -> void:
	_write_slot_artifact(2, "main", {"version": 1, "level": 12, "play_seconds": 9180.0})
	var screen: Variant = await _make_settings({"return_screen_id": "title", "target_slot_id": 2})
	_expect(screen._target_slot_id == 2, "title payload should select slot 2")
	_expect(not screen._delete_button.disabled, "occupied slot should allow delete")
	_expect(screen._se_slider.focus_neighbor_bottom == screen._se_slider.get_path_to(screen._delete_button), "occupied slot focus should include delete")
	_expect("スロット2" in screen._delete_summary_label.text, "normal summary should show slot number")
	_expect("Lv.12" in screen._delete_summary_label.text, "normal summary should show level")
	_expect("2時間33分" in screen._delete_summary_label.text, "normal summary should show play time")
	await _press_button(screen._delete_button)
	_expect(screen._delete_api_call_count == 0, "confirmation 1 must not call delete API")
	_expect(screen._delete_stage == 1, "delete entry should open confirmation 1")
	_expect(get_viewport().gui_get_focus_owner() == screen._delete_confirm_cancel_button, "confirmation 1 should focus safe cancel")
	_expect(FileAccess.file_exists(_slot_artifact_path(2, "main")), "confirmation 1 must not delete")
	await _send_action("ui_cancel")
	_expect(screen._delete_stage == 0, "ui_cancel should return confirmation 1 to normal")
	_expect(get_viewport().gui_get_focus_owner() == screen._delete_button, "confirmation 1 cancel should restore delete focus")
	await _press_button(screen._delete_button)
	await _press_button(screen._delete_continue_button)
	_expect(screen._delete_api_call_count == 0, "confirmation 2 display must not call delete API")
	_expect(screen._delete_stage == 2, "continue should open confirmation 2")
	_expect(get_viewport().gui_get_focus_owner() == screen._delete_final_cancel_button, "confirmation 2 should focus safe back")
	_expect("スロット2" in screen._delete_final_detail.text and "Lv.12" in screen._delete_final_detail.text, "confirmation 2 should repeat the summary")
	await _send_action("ui_cancel")
	_expect(screen._delete_stage == 1, "ui_cancel should return confirmation 2 to confirmation 1")
	_expect(get_viewport().gui_get_focus_owner() == screen._delete_confirm_cancel_button, "confirmation 2 cancel should restore confirmation 1 safe focus")
	await _free_node(screen)
	PlayerProgress.active_save_slot = 3
	var harbor_screen: Variant = await _make_settings({"return_screen_id": "harbor", "target_slot_id": 1})
	_expect(harbor_screen._target_slot_id == 3, "harbor entry should ignore payload target and use active slot")
	await _free_node(harbor_screen)
	var invalid_screen: Variant = await _make_settings({"return_screen_id": "title", "target_slot_id": 999})
	_expect(invalid_screen._target_slot_id == PlayerProgress.DEFAULT_SAVE_SLOT, "invalid title target should fall back without selecting another slot")
	await _free_node(invalid_screen)
	PlayerProgress.active_save_slot = 1


func _verify_guarded_and_invalid_artifacts_are_deletable() -> void:
	var fixtures := [
		{"label": "future", "slot": 1, "raw": JSON.stringify({"version": PlayerProgress.SAVE_VERSION + 1, "level": 99})},
		{"label": "unknown", "slot": 2, "raw": JSON.stringify({"version": "mystery", "level": 99})},
		{"label": "invalid", "slot": 3, "raw": "[]"},
	]
	for fixture in fixtures:
		var slot_id := int(fixture["slot"])
		_write_slot_raw(slot_id, "main", String(fixture["raw"]))
		var screen: Variant = await _make_settings({"return_screen_id": "title", "target_slot_id": slot_id})
		_expect(not screen._delete_button.disabled, "%s artifact should remain deletable" % fixture["label"])
		await _press_button(screen._delete_button)
		await _press_button(screen._delete_continue_button)
		_expect(screen._delete_api_call_count == 0, "%s artifact should not delete before final commit" % fixture["label"])
		await _press_button(screen._delete_commit_button)
		_expect(screen._delete_api_call_count == 1, "%s artifact should call delete API exactly once" % fixture["label"])
		_expect(not FileAccess.file_exists(_slot_artifact_path(slot_id, "main")), "%s artifact should be deleted" % fixture["label"])
		await _free_node(screen)


func _verify_delete_success_file_integration() -> void:
	for slot_id in range(1, PlayerProgress.SAVE_SLOT_COUNT + 1):
		for artifact in ["main", "backup", "tmp"]:
			_write_slot_artifact(slot_id, artifact, {"version": 1, "level": slot_id + 4, "play_seconds": 3600.0 * slot_id, "marker": "%d-%s" % [slot_id, artifact]})
	SettingsScreenScript.save_settings({"bgm_volume": 35, "se_volume": 60})
	var other_hashes := {}
	for slot_id in [1, 3]:
		for artifact in ["main", "backup", "tmp"]:
			other_hashes["%d-%s" % [slot_id, artifact]] = _file_hash(_slot_artifact_path(slot_id, artifact))
	PlayerProgress.set_active_save_slot(2, false)
	var screen: Variant = await _make_settings({"return_screen_id": "title", "target_slot_id": 2})
	var settings_hash := _file_hash(SettingsScreenScript.SETTINGS_PATH)
	await _press_button(screen._delete_button)
	await _press_button(screen._delete_continue_button)
	_reset_route()
	await _press_button(screen._delete_commit_button)
	_expect(screen._delete_api_call_count == 1, "successful final confirmation should call delete API exactly once")
	_expect(_route_id == "title", "successful deletion should route to title")
	for artifact in ["main", "backup", "tmp"]:
		_expect(not FileAccess.file_exists(_slot_artifact_path(2, artifact)), "target %s should be deleted" % artifact)
	for slot_id in [1, 3]:
		for artifact in ["main", "backup", "tmp"]:
			_expect(_file_hash(_slot_artifact_path(slot_id, artifact)) == other_hashes["%d-%s" % [slot_id, artifact]], "other slot artifact must stay byte-identical")
	_expect(_file_hash(SettingsScreenScript.SETTINGS_PATH) == settings_hash, "settings.json must stay byte-identical")
	PlayerProgress.save_game()
	_expect(not FileAccess.file_exists(_slot_artifact_path(2, "main")), "active deleted slot must stay suppressed from auto-save regeneration")
	await _free_node(screen)
	PlayerProgress.set_active_save_slot(1, false)


func _verify_delete_failure_stays_on_screen() -> void:
	_write_slot_artifact(1, "main", {"version": 1, "level": 9, "play_seconds": 7200.0})
	PlayerProgress._delete_failure_injection_stage = "main"
	var screen: Variant = await _make_settings({"return_screen_id": "title", "target_slot_id": 1})
	await _press_button(screen._delete_button)
	await _press_button(screen._delete_continue_button)
	_reset_route()
	await _press_button(screen._delete_commit_button)
	_expect(_route_id.is_empty(), "failed deletion should not navigate")
	_expect(screen._delete_stage == 0 and not screen._delete_modal_layer.visible, "failed deletion should return to normal settings")
	_expect(not screen._delete_status_label.text.is_empty(), "failed deletion should show backend message or reason")
	_expect(not screen._delete_button.disabled, "failed deletion should stay retryable")
	_expect(get_viewport().gui_get_focus_owner() == screen._delete_button, "failed deletion should restore safe retry focus")
	_expect(FileAccess.file_exists(_slot_artifact_path(1, "main")), "failed deletion should leave the failed artifact")
	PlayerProgress._delete_failure_injection_stage = ""
	await _free_node(screen)


func _verify_tmp_only_and_partial_delete_retries() -> void:
	_write_slot_artifact(1, "tmp", {"version": 1, "marker": "tmp-only"})
	var tmp_only: Variant = await _make_settings({"return_screen_id": "title", "target_slot_id": 1})
	_expect(not tmp_only._delete_button.disabled, "tmp-only slot should be deletable")
	await _press_button(tmp_only._delete_button)
	await _press_button(tmp_only._delete_continue_button)
	await _press_button(tmp_only._delete_commit_button)
	_expect(not FileAccess.file_exists(_slot_artifact_path(1, "tmp")), "tmp-only artifact should be deleted")
	await _free_node(tmp_only)

	for stage in ["main", "backup", "tmp"]:
		for artifact in ["main", "backup", "tmp"]:
			_write_slot_artifact(1, artifact, {"version": 1, "marker": "%s-%s" % [stage, artifact]})
		PlayerProgress._delete_failure_injection_stage = stage
		var screen: Variant = await _make_settings({"return_screen_id": "title", "target_slot_id": 1})
		await _press_button(screen._delete_button)
		await _press_button(screen._delete_continue_button)
		await _press_button(screen._delete_commit_button)
		_expect(not screen._delete_button.disabled, "%s failure should leave retry enabled" % stage)
		_expect(bool(PlayerProgress.save_slot_artifact_status(1).get("any_artifact", false)), "%s failure should report remaining artifact" % stage)
		PlayerProgress._delete_failure_injection_stage = ""
		await _press_button(screen._delete_button)
		await _press_button(screen._delete_continue_button)
		await _press_button(screen._delete_commit_button)
		_expect(not bool(PlayerProgress.save_slot_artifact_status(1).get("any_artifact", true)), "%s retry should remove every artifact" % stage)
		await _free_node(screen)


func _verify_storage_blocked_message_priority() -> void:
	var previous_ready: bool = PlayerProgress._save_storage_ready
	PlayerProgress._save_storage_ready = false
	var screen: Variant = await _make_settings({"return_screen_id": "title", "target_slot_id": 1})
	_expect(screen._delete_button.disabled, "storage-blocked delete should be disabled")
	_expect(screen._delete_status_label.text == PlayerProgress.save_storage_block_message(), "storage-blocked message should take priority over empty-slot text")
	await _free_node(screen)
	PlayerProgress._save_storage_ready = previous_ready


func _make_settings(payload: Dictionary) -> Variant:
	var screen := SettingsScreenScript.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure(payload)
	screen.navigate_requested.connect(_capture_route)
	add_child(screen)
	await _settle()
	return screen


func _capture_route(screen_id: String, payload: Dictionary) -> void:
	_route_id = screen_id
	_route_payload = payload.duplicate(true)


func _reset_route() -> void:
	_route_id = ""
	_route_payload.clear()


func _settle() -> void:
	await get_tree().process_frame


func _press_button(button: Button) -> void:
	button.pressed.emit()
	await _settle()


func _send_action(action: StringName) -> void:
	var pressed := InputEventAction.new()
	pressed.action = action
	pressed.pressed = true
	Input.parse_input_event(pressed)
	await get_tree().process_frame
	var released := InputEventAction.new()
	released.action = action
	released.pressed = false
	Input.parse_input_event(released)
	await get_tree().process_frame
	await get_tree().process_frame


func _free_node(node: Node) -> void:
	node.queue_free()
	await get_tree().process_frame


func _remove_settings_file() -> void:
	if FileAccess.file_exists(SettingsScreenScript.SETTINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SettingsScreenScript.SETTINGS_PATH))


func _cleanup_test_artifacts() -> void:
	PlayerProgress._delete_failure_injection_stage = ""
	for slot_id in range(1, PlayerProgress.SAVE_SLOT_COUNT + 1):
		for artifact in ["main", "backup", "tmp"]:
			var path := _slot_artifact_path(slot_id, artifact)
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
	_remove_settings_file()


func _write_raw(text: String) -> void:
	var file := FileAccess.open(SettingsScreenScript.SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		_expect(false, "settings fixture should be writable")
		return
	file.store_string(text)


func _slot_artifact_path(slot_id: int, artifact: String) -> String:
	var filename := PlayerProgress.SAVE_FILE_NAME
	if artifact == "backup":
		filename = PlayerProgress.SAVE_BACKUP_FILE_NAME
	elif artifact == "tmp":
		filename = PlayerProgress.SAVE_TMP_FILE_NAME
	return "%s/%d/%s" % [PlayerProgress.SAVE_SLOT_ROOT, slot_id, filename]


func _write_slot_artifact(slot_id: int, artifact: String, data: Dictionary) -> void:
	_write_slot_raw(slot_id, artifact, JSON.stringify(data))


func _write_slot_raw(slot_id: int, artifact: String, text: String) -> void:
	var path := _slot_artifact_path(slot_id, artifact)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_expect(false, "slot fixture should be writable: %s" % path)
		return
	file.store_string(text)


func _file_hash(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_sha256(path)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("settings_smoke: %s" % message)
