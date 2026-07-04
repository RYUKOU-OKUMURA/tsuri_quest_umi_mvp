extends Control
## 天候別の水上READY画面を1280x720でキャプチャする。

const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const FishingScreen = preload("res://src/ui/fishing_screen.gd")

const VW := Vector2i(1280, 720)
const ENVIRONMENT_IDS: Array[String] = [
	"sunny_calm",
	"partly_cloudy",
	"cloudy",
	"rain",
	"fog",
]


func _ready() -> void:
	var out_dir := OS.get_environment("TSURI_SURFACE_WEATHER_OUT_DIR")
	if out_dir.strip_edges().is_empty():
		out_dir = "/tmp"
	PlayerProgress.level = 6
	PlayerProgress.money = 750
	PlayerProgress.owned_rods = ["starter"]
	PlayerProgress.equipped_rod_id = "starter"
	PlayerProgress.owned_rigs = [GameData.DEFAULT_RIG_ID]
	PlayerProgress.equipped_rig_id = GameData.DEFAULT_RIG_ID
	PlayerProgress.owned_boats = ["skiff", "offshore_boat"]

	for environment_id in ENVIRONMENT_IDS:
		var ok := await _capture_environment(environment_id, out_dir)
		if not ok:
			get_tree().quit(1)
			return
	await get_tree().process_frame
	await get_tree().process_frame
	print("surface_weather_preview: ok")
	get_tree().quit(0)


func _capture_environment(environment_id: String, out_dir: String) -> bool:
	var environment := GameData.get_fishing_environment(environment_id)
	var weather_id := String(environment.get("weather_id", "sunny"))
	var out_path := "%s/tsuri_surface_weather_%s.png" % [out_dir, weather_id]
	if FileAccess.file_exists(out_path):
		DirAccess.remove_absolute(out_path)

	var vp := SubViewport.new()
	vp.size = VW
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var stats := _trip_stats_for_environment(environment)
	var screen := FishingScreen.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({
		"spot_id": "rock_breakwater",
		"continue_trip": true,
		"trip_stats": stats,
	})
	screen.size = Vector2(VW)
	vp.add_child(screen)

	await get_tree().process_frame
	await get_tree().process_frame
	if screen._surface_view != null:
		screen._surface_view.modulate.a = 1.0
	if screen._view != null:
		screen._view.modulate.a = 0.0
	screen.queue_redraw()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw

	var img := vp.get_texture().get_image()
	if img == null:
		push_error("surface weather capture failed: %s" % environment_id)
		screen.queue_free()
		vp.queue_free()
		await get_tree().process_frame
		return false
	img.save_png(out_path)
	screen.queue_free()
	vp.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	return true


func _trip_stats_for_environment(environment: Dictionary) -> Dictionary:
	var stats := PlayerProgress.get_base_stats()
	stats["meal_buff"] = {}
	stats["environment_id"] = String(environment.get("id", GameData.DEFAULT_FISHING_ENVIRONMENT_ID))
	stats["weather_id"] = String(environment.get("weather_id", "sunny"))
	stats["weather_label"] = String(environment.get("weather_label", "快晴"))
	stats["wind_id"] = String(environment.get("wind_id", "weak"))
	stats["wind_label"] = String(environment.get("wind_label", "風 弱"))
	stats["surface_bgm_key"] = String(environment.get("surface_bgm_key", "calm"))
	var rig := GameData.get_rig(GameData.DEFAULT_RIG_ID)
	stats["rig_id"] = GameData.DEFAULT_RIG_ID
	stats["rig_name"] = String(rig.get("name", "サビキ仕掛け"))
	stats["rig_bait_types"] = GameData.rig_bait_types(GameData.DEFAULT_RIG_ID)
	return stats
