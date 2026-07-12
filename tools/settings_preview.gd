extends Control

const SettingsScreenScript = preload("res://src/ui/settings_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const OUT := "/tmp/tsuri_settings.png"
const VW := Vector2i(1280, 720)


func _ready() -> void:
	SettingsScreenScript.save_settings({"bgm_volume": 80, "se_volume": 65})
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
	await get_tree().create_timer(1.0).timeout
	RenderingServer.force_draw(false, 0.0)
	await get_tree().process_frame
	var image := viewport.get_texture().get_image()
	if image == null or image.is_empty() or image.get_size() != VW:
		push_error("設定画面の1280x720 captureに失敗しました")
		get_tree().quit(1)
		return
	image.save_png(OUT)
	get_tree().quit(0)
