extends Control

const SettingsScreenScript = preload("res://src/ui/settings_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const VW := Vector2i(1280, 720)


func _ready() -> void:
	SettingsScreenScript.save_settings({"bgm_volume": 80, "se_volume": 65})
	PlayerProgress._sandbox_mode = false
	PlayerProgress._save_storage_ready = true
	_write_preview_save()
	await _capture("/tmp/tsuri_settings_normal.png", 0)
	await _capture("/tmp/tsuri_settings_confirm1.png", 1)
	await _capture("/tmp/tsuri_settings_confirm2.png", 2)
	await _capture("/tmp/tsuri_settings_failure.png", 3)
	get_tree().quit(0)


func _capture(path: String, state: int) -> void:
	var viewport := SubViewport.new()
	viewport.size = VW
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var screen := SettingsScreenScript.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({"return_screen_id": "harbor"})
	screen.size = Vector2(VW)
	viewport.add_child(screen)
	await get_tree().process_frame
	await get_tree().process_frame
	if state >= 1 and state <= 2:
		screen._show_delete_confirm()
	if state == 2:
		screen._show_delete_final()
	if state == 3:
		screen._refresh_delete_summary("削除できませんでした。もう一度お試しください。")
		screen._delete_button.grab_focus()
	await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	RenderingServer.force_draw(false, 0.0)
	await get_tree().process_frame
	var image := viewport.get_texture().get_image()
	if image == null or image.is_empty() or image.get_size() != VW:
		push_error("設定画面の1280x720 captureに失敗しました: %s" % path)
		get_tree().quit(1)
		return
	image.save_png(path)
	viewport.queue_free()
	await get_tree().process_frame


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
