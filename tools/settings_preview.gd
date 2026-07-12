extends Control

const SettingsScreenScript = preload("res://src/ui/settings_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const IsolationGuard = preload("res://tools/settings_isolation_guard.gd")
const DESIGN_SIZE := Vector2i(1280, 720)
const STATES := ["normal", "confirm1", "confirm2", "failure", "hover", "pressed", "focus", "fullscreen_hover", "fullscreen_pressed", "fullscreen_focus", "fullscreen_on"]
var _capture_size := DESIGN_SIZE


func _ready() -> void:
	var raw_home_probe := OS.get_environment("TSURI_QA_REJECT_RAW_HOME_PROBE")
	if not raw_home_probe.is_empty():
		if IsolationGuard.raw_absolute_path_is_unambiguous(raw_home_probe):
			push_error("settings_preview: rejection-only raw HOME probeが曖昧pathを拒否しませんでした")
			get_tree().quit(1)
		else:
			get_tree().quit(2)
		return
	var state := OS.get_environment("TSURI_SETTINGS_PREVIEW_STATE")
	if (
		OS.get_environment("TSURI_SETTINGS_PREVIEW_ALLOW") != "1"
		or not _isolated_home_matches()
		or state not in STATES
	):
		push_error("settings_preview: 隔離wrapper以外からの実行を拒否しました")
		get_tree().quit(2)
		return
	_cleanup_preview_artifacts()
	SettingsScreenScript.save_settings({"bgm_volume": 80, "se_volume": 80, "fullscreen": state == "fullscreen_on"})
	PlayerProgress._sandbox_mode = false
	PlayerProgress._save_storage_ready = true
	_write_preview_save()

	_capture_size = _parse_capture_size(OS.get_environment("TSURI_SETTINGS_PREVIEW_WINDOW"))
	if OS.get_environment("TSURI_SETTINGS_SCREEN_HOLD") == "1":
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	get_window().size = _capture_size
	if OS.get_environment("TSURI_SETTINGS_SCREEN_HOLD") == "1":
		get_window().position = Vector2i(0, 62)
	get_window().grab_focus()
	var screen := SettingsScreenScript.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({"return_screen_id": "harbor"})
	screen.size = Vector2(DESIGN_SIZE)
	add_child(screen)
	if state == "fullscreen_on":
		var loaded_settings := SettingsScreenScript.load_settings()
		if not bool(loaded_settings.get("fullscreen", false)) or not screen._fullscreen or screen._fullscreen_button.text != "フルスクリーン: オン":
			push_error("fullscreen_on previewが保存値からオン文言を復元できませんでした")
			get_tree().quit(1)
			return
		# 実保存・実読込・window_set_mode(true)まで通した後、preview隔離内だけwindowedへ戻し、capture viewportを1280x720へ固定する。
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		get_window().size = _capture_size
		print("settings_preview[fullscreen_on]: saved fullscreen=true; windowed capture override")
	await get_tree().process_frame
	await get_tree().process_frame
	match state:
		"confirm1":
			screen._show_delete_confirm()
		"confirm2":
			screen._show_delete_confirm()
			screen._show_delete_final()
		"failure":
			screen._refresh_delete_summary("削除できませんでした。もう一度お試しください。")
			screen._delete_button.grab_focus()
		"hover":
			_apply_button_skin(screen._delete_button, "hover")
		"pressed":
			_apply_button_skin(screen._delete_button, "pressed")
		"focus":
			screen._delete_button.grab_focus()
		"fullscreen_hover":
			screen._on_fullscreen_hover(true)
		"fullscreen_pressed":
			screen._on_fullscreen_pressed(true)
		"fullscreen_focus":
			screen._fullscreen_button.grab_focus()
	var expected_focus: Control = screen._fullscreen_button if state == "fullscreen_focus" else (screen._delete_button if state == "failure" or state == "focus" else null)
	if state == "failure" or state == "focus" or state == "fullscreen_focus":
		await get_tree().process_frame
		if get_viewport().gui_get_focus_owner() != expected_focus:
			push_error("設定previewの削除ボタンfocusを確立できませんでした: %s" % state)
			get_tree().quit(1)
			return
	if _capture_size == DESIGN_SIZE:
		var output_path := OS.get_environment("TSURI_SETTINGS_PREVIEW_OUTPUT")
		if output_path.is_empty():
			output_path = "/tmp/tsuri_settings_%s.png" % state
		await _save_capture(get_viewport(), output_path, state, expected_focus)
	else:
		if OS.get_environment("TSURI_SETTINGS_SCREEN_HOLD") != "1":
			push_error("解像度matrixは非headless実画面capture専用です")
			get_tree().quit(2)
			return
	if OS.get_environment("TSURI_SETTINGS_SCREEN_HOLD") == "1":
		print("settings_preview window position=%s size=%s" % [get_window().position, get_window().size])
		await get_tree().create_timer(5.0).timeout

	screen.queue_free()
	await get_tree().process_frame
	_cleanup_preview_artifacts()
	print("settings_preview[%s]: ok" % state)
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


func _save_capture(viewport: Viewport, path: String, state: String, expected_focus: Control) -> void:
	await _settle_capture()
	if expected_focus != null and viewport.gui_get_focus_owner() != expected_focus:
		push_error("設定previewのcapture直前focusが不正です: %s" % state)
		get_tree().quit(1)
		return
	var image: Image
	for _attempt in range(8):
		RenderingServer.force_draw(false, 0.0)
		await get_tree().process_frame
		if expected_focus != null and viewport.gui_get_focus_owner() != expected_focus:
			push_error("設定previewのtexture取得直前focusが不正です: %s" % state)
			get_tree().quit(1)
			return
		image = viewport.get_texture().get_image()
		if _capture_looks_complete(image, state):
			break
		await get_tree().process_frame
	if not _capture_looks_complete(image, state) or not _full_frame_is_complete(image):
		push_error("設定画面の%s captureに失敗しました: %s" % [_capture_size, path])
		get_tree().quit(1)
		return
	image.save_png(path)


func _capture_looks_complete(image: Image, state: String) -> bool:
	if image == null or image.is_empty() or image.get_size() != _capture_size:
		return false
	var content := _expected_content_rect()
	var shell_complete := (
		_pixel_is_opaque_and_bright(image.get_pixel(int(content.position.x + 20.0), int(content.position.y + 20.0)), 0.005)
		and _pixel_is_opaque_and_bright(image.get_pixel(int(content.end.x - 20.0), int(content.end.y - 20.0)), 0.005)
	)
	if not shell_complete:
		return false
	if _non_black_sample_count(image) < 9000:
		return false
	if state == "confirm1" or state == "confirm2":
		return (
			_region_has_bright_pixel(image, _mapped_rect(Rect2(275.0, 135.0, 90.0, 55.0)), 0.25)
			and _region_has_bright_pixel(image, _mapped_rect(Rect2(450.0, 275.0, 380.0, 120.0)), 0.35)
		)
	return (
		_region_has_bright_pixel(image, _mapped_rect(Rect2(560.0, 45.0, 160.0, 55.0)), 0.30)
		and _region_has_bright_pixel(image, _mapped_rect(Rect2(185.0, 145.0, 80.0, 55.0)), 0.25)
		and _region_has_bright_pixel(image, _mapped_rect(Rect2(735.0, 160.0, 300.0, 58.0)), 0.25)
		and _region_has_bright_pixel(image, _mapped_rect(Rect2(245.0, 225.0, 720.0, 220.0)), 0.35)
	)


func _region_has_bright_pixel(image: Image, rect: Rect2i, threshold: float) -> bool:
	for y in range(rect.position.y, rect.end.y, 4):
		for x in range(rect.position.x, rect.end.x, 4):
			if _pixel_is_opaque_and_bright(image.get_pixel(x, y), threshold):
				return true
	return false


func _non_black_sample_count(image: Image) -> int:
	var count := 0
	var content := _expected_content_rect()
	for y in range(int(content.position.y), int(content.end.y), 8):
		for x in range(int(content.position.x), int(content.end.x), 8):
			if _pixel_is_opaque_and_bright(image.get_pixel(x, y), 0.008):
				count += 1
	return count


func _pixel_is_opaque_and_bright(pixel: Color, luminance: float) -> bool:
	return pixel.a > 0.99 and pixel.get_luminance() > luminance


func _full_frame_is_complete(image: Image) -> bool:
	var content := _expected_content_rect()
	var visible_pixels := 0
	var content_visible_pixels := 0
	var bar_pixels := 0
	for y in range(_capture_size.y):
		for x in range(_capture_size.x):
			var pixel := image.get_pixel(x, y)
			if pixel.a <= 0.99:
				return false
			var luminance := pixel.get_luminance()
			var inside := content.has_point(Vector2(x, y))
			visible_pixels += int(luminance > 0.008)
			content_visible_pixels += int(inside and luminance > 0.008)
			bar_pixels += int(not inside and luminance < 0.04)
	var expected_content_area := int(content.size.x * content.size.y)
	var expected_bar_area := _capture_size.x * _capture_size.y - expected_content_area
	return (
		visible_pixels >= int(expected_content_area * 0.70)
		and content_visible_pixels >= int(expected_content_area * 0.70)
		and bar_pixels >= int(expected_bar_area * 0.98)
	)


func _parse_capture_size(raw: String) -> Vector2i:
	if raw.is_empty():
		return DESIGN_SIZE
	var parts := raw.to_lower().split("x", false)
	if parts.size() != 2:
		return DESIGN_SIZE
	var width := int(parts[0])
	var height := int(parts[1])
	return Vector2i(width, height) if width >= DESIGN_SIZE.x / 2 and height >= DESIGN_SIZE.y / 2 else DESIGN_SIZE


func _expected_content_rect() -> Rect2:
	var scale := minf(float(_capture_size.x) / DESIGN_SIZE.x, float(_capture_size.y) / DESIGN_SIZE.y)
	var content_size := Vector2(DESIGN_SIZE) * scale
	return Rect2((Vector2(_capture_size) - content_size) * 0.5, content_size)


func _mapped_rect(design_rect: Rect2) -> Rect2i:
	var content := _expected_content_rect()
	var scale := content.size.x / float(DESIGN_SIZE.x)
	return Rect2i(
		Vector2i(
			floori(content.position.x + design_rect.position.x * scale),
			floori(content.position.y + design_rect.position.y * scale)
		),
		Vector2i(ceili(design_rect.size.x * scale), ceili(design_rect.size.y * scale))
	)


func _settle_capture() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.45).timeout


func _apply_button_skin(button: Button, state: StringName) -> void:
	button.add_theme_stylebox_override("normal", button.get_theme_stylebox(state))
	var color_name := StringName("font_%s_color" % state)
	if button.has_theme_color(color_name):
		button.add_theme_color_override("font_color", button.get_theme_color(color_name))


func _write_preview_save() -> void:
	var slot_id := PlayerProgress.DEFAULT_SAVE_SLOT
	PlayerProgress.active_save_slot = slot_id
	var path := "%s/%d/%s" % [PlayerProgress.SAVE_SLOT_ROOT, slot_id, PlayerProgress.SAVE_FILE_NAME]
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("設定preview用saveを作成できません")
		return
	file.store_string(JSON.stringify({"version": 1, "level": 12, "play_seconds": 9180.0}))


func _cleanup_preview_artifacts() -> void:
	for artifact_path in [
		"%s/%d/%s" % [PlayerProgress.SAVE_SLOT_ROOT, PlayerProgress.DEFAULT_SAVE_SLOT, PlayerProgress.SAVE_FILE_NAME],
		"%s/%d/%s" % [PlayerProgress.SAVE_SLOT_ROOT, PlayerProgress.DEFAULT_SAVE_SLOT, PlayerProgress.SAVE_BACKUP_FILE_NAME],
		"%s/%d/%s" % [PlayerProgress.SAVE_SLOT_ROOT, PlayerProgress.DEFAULT_SAVE_SLOT, PlayerProgress.SAVE_TMP_FILE_NAME],
		SettingsScreenScript.SETTINGS_PATH,
	]:
		if FileAccess.file_exists(artifact_path):
			DirAccess.remove_absolute(artifact_path)
