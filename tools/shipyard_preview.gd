extends Control
## 船着き場画面の1280x720表示確認用キャプチャ。

const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const ShipyardScreen = preload("res://src/ui/shipyard_screen.gd")

const OUT := "/tmp/tsuri_shipyard_screen.png"
const VW := Vector2i(1280, 720)


func _ready() -> void:
	theme = ThemeFactory.build_theme()
	_setup_preview_progress()
	var vp := SubViewport.new()
	vp.size = VW
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var screen := ShipyardScreen.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({})
	screen.size = Vector2(VW)
	vp.add_child(screen)

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout

	if FileAccess.file_exists(OUT):
		DirAccess.remove_absolute(OUT)
	var img := vp.get_texture().get_image()
	if img == null:
		push_error("SubViewport get_image() returned null for %s" % OUT)
	else:
		img.save_png(OUT)
	print(OUT)
	get_tree().quit()


func _setup_preview_progress() -> void:
	PlayerProgress.level = 6
	PlayerProgress.exp = 132
	PlayerProgress.money = 12450
	PlayerProgress.owned_boats = ["skiff"]
	PlayerProgress.equipped_rod_id = "offshore"
