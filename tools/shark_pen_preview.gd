extends Control
## サメの生簀画面の1280x720表示確認用キャプチャ。

const SharkPenScreen = preload("res://src/ui/shark_pen_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")

const VW := Vector2i(1280, 720)
const OUT := "/tmp/tsuri_shark_pen.png"
const SELECTED_HOVER_OUT := "/tmp/tsuri_shark_pen_selected_hover.png"

var _had_capture_error := false


func _ready() -> void:
	_seed_progress()
	await _capture_plain(OUT)
	await _capture_selected_hover(SELECTED_HOVER_OUT)
	print("shark_pen_preview:")
	print(OUT)
	print(SELECTED_HOVER_OUT)
	get_tree().quit(1 if _had_capture_error else 0)


func _seed_progress() -> void:
	PlayerProgress.reset_game()
	PlayerProgress.level = 50
	PlayerProgress.exp = 0
	PlayerProgress.money = 128400
	PlayerProgress.owned_rods = ["starter", "iso", "offshore", "big_game", "marlin"]
	PlayerProgress.equipped_rod_id = "marlin"
	PlayerProgress.owned_boats = ["skiff", "offshore_boat", "deep_sea_boat"]
	PlayerProgress.inventory = {
		"kihada": 2,
		"nushi_deep_ocean": 1,
		"mahaze": 8,
		"buri": 3,
		"kasago": 5,
		"nekozame": 1,
	}
	PlayerProgress.caught_counts = {
		"nekozame": 2,
		"inuzame": 1,
		"dochizame": 1,
		"hoshizame": 1,
		"eporetto": 1,
		"darumazame": 1,
		"shumokuzame": 1,
		"hohojirozame": 1,
		"megalodon": 1,
		"kihada": 2,
		"nushi_deep_ocean": 1,
		"mahaze": 8,
		"buri": 3,
		"kasago": 5,
	}
	PlayerProgress.shark_bonds = {
		"nekozame": 100,
		"inuzame": 76,
		"dochizame": 64,
		"hoshizame": 100,
		"eporetto": 42,
		"darumazame": 18,
		"fujikujira": 0,
		"shumokuzame": 35,
		"hohojirozame": 12,
		"megalodon": 84,
	}
	PlayerProgress._remember_current_titles()


func _capture_plain(out_path: String) -> void:
	var screen: Control = await _make_screen(VW)
	await _capture_screen(screen, out_path)


func _capture_selected_hover(out_path: String) -> void:
	var screen: Control = await _make_screen(VW)
	var selected := screen._shark_rows.get("megalodon", {}) as Dictionary
	var button := selected.get("button") as Button
	if button == null:
		_had_capture_error = true
		push_error("selected hover target was not built")
		return
	button.grab_focus()
	var motion := InputEventMouseMotion.new()
	motion.position = button.get_global_rect().get_center()
	motion.global_position = motion.position
	var vp := screen.get_parent() as SubViewport
	vp.push_input(motion)
	await get_tree().process_frame
	await get_tree().process_frame
	await _capture_screen(screen, out_path)


func _make_screen(viewport_size: Vector2i) -> Control:
	var vp := SubViewport.new()
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.size = viewport_size
	add_child(vp)
	await get_tree().process_frame
	await get_tree().process_frame

	var screen := SharkPenScreen.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({"selected_shark_id": "megalodon"})
	screen.size = Vector2(viewport_size)
	vp.add_child(screen)

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	return screen


func _capture_screen(screen: Control, out_path: String) -> void:
	await get_tree().create_timer(0.35).timeout
	RenderingServer.force_draw()
	await get_tree().process_frame

	var vp := screen.get_parent() as SubViewport
	if FileAccess.file_exists(out_path):
		DirAccess.remove_absolute(out_path)
	var img := vp.get_texture().get_image()
	if img == null or img.is_empty():
		_had_capture_error = true
		push_error("SubViewport get_image() returned null for %s" % out_path)
	else:
		img.save_png(out_path)
	vp.queue_free()
	await get_tree().process_frame
