extends Control
## 釣り場マップ画面の1280x720表示確認用キャプチャ。

const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const FishingSpotSelectScreen = preload("res://src/ui/fishing_spot_select_screen.gd")

const VW := Vector2i(1280, 720)
const OUT_DEFAULT := "/tmp/tsuri_fishing_spot_map.png"
const OUT_CONTINUE := "/tmp/tsuri_fishing_spot_map_continue.png"


func _ready() -> void:
	PlayerProgress.level = 9
	PlayerProgress.money = 12450
	PlayerProgress.equipped_rod_id = "seabreeze_rod"

	await _capture({"spot_id": "bluewater_route"}, OUT_DEFAULT)
	await _capture(
		{
			"from_fishing": true,
			"current_spot_id": "outer_tide",
			"trip_stats": {
				"spot_id": "outer_tide",
				"spot_name": "港外・潮目",
				"max_energy": 123.0,
			},
		},
		OUT_CONTINUE
	)

	print("fishing_spot_map_preview:")
	print(OUT_DEFAULT)
	print(OUT_CONTINUE)
	get_tree().quit()


func _capture(payload: Dictionary, out_path: String) -> void:
	var vp := SubViewport.new()
	vp.size = VW
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var screen := FishingSpotSelectScreen.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure(payload)
	screen.size = Vector2(VW)
	vp.add_child(screen)

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout

	if FileAccess.file_exists(out_path):
		DirAccess.remove_absolute(out_path)
	var img := vp.get_texture().get_image()
	if img == null:
		push_error("SubViewport get_image() returned null for %s" % out_path)
	else:
		img.save_png(out_path)
	vp.queue_free()
	await get_tree().process_frame
