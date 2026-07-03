extends Control
## 釣具店画面の1280x720表示確認用キャプチャ。

const ShopScreen = preload("res://src/ui/shop_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")

const VW := Vector2i(1280, 720)
const VW_EXPANDED := Vector2i(2124, 1507)
const OUT_ROD := "/tmp/tsuri_tackle_shop_rod.png"
const OUT_RIG := "/tmp/tsuri_tackle_shop_rig.png"
const OUT_ROD_EXPANDED := "/tmp/tsuri_tackle_shop_rod_expanded.png"
const OUT_RIG_EXPANDED := "/tmp/tsuri_tackle_shop_rig_expanded.png"

var _had_capture_error := false


func _ready() -> void:
	_seed_progress()
	await _capture("rod", OUT_ROD, VW)
	await _capture("rig", OUT_RIG, VW)
	await _capture("rod", OUT_ROD_EXPANDED, VW_EXPANDED)
	await _capture("rig", OUT_RIG_EXPANDED, VW_EXPANDED)

	print("tackle_shop_preview:")
	print(OUT_ROD)
	print(OUT_RIG)
	print(OUT_ROD_EXPANDED)
	print(OUT_RIG_EXPANDED)
	get_tree().quit(1 if _had_capture_error else 0)


func _seed_progress() -> void:
	PlayerProgress.level = 3
	PlayerProgress.exp = 42
	PlayerProgress.money = 5400
	PlayerProgress.owned_rods = ["starter", "iso", "offshore"]
	PlayerProgress.equipped_rod_id = "offshore"
	PlayerProgress.owned_rigs = [GameData.DEFAULT_RIG_ID, "uki", "chokusen"]
	PlayerProgress.equipped_rig_id = "chokusen"
	PlayerProgress.owned_boats = []
	PlayerProgress.inventory = {}
	PlayerProgress.caught_counts = {
		"aji": 8,
		"mejina": 3,
		"kasago": 2,
	}
	PlayerProgress.spot_caught_counts = {}
	PlayerProgress.best_sizes = {}
	PlayerProgress.pending_buff = {}


func _capture(mode: String, out_path: String, viewport_size: Vector2i) -> void:
	var vp := SubViewport.new()
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.size = viewport_size
	add_child(vp)
	await get_tree().process_frame
	await get_tree().process_frame

	var screen := ShopScreen.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({})
	screen.size = Vector2(viewport_size)
	vp.add_child(screen)

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	if mode == "rig":
		screen._set_shop_mode("rig")
		screen._select_item("jigging")
	else:
		screen._select_item("marlin")
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.45).timeout
	RenderingServer.force_draw()
	await get_tree().process_frame

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
