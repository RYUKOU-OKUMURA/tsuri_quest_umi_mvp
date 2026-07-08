extends Control
## E5時間帯の釣行READY / 釣果ファンファーレ / 逃走リザルト比較用キャプチャ。

const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const FishingScreen = preload("res://src/ui/fishing_screen.gd")

const VW := Vector2i(1280, 720)
const DEFAULT_OUT := "/tmp/tsuri_fishing_time_slot.png"


func _ready() -> void:
	PlayerProgress.level = GameData.MAX_LEVEL
	PlayerProgress.money = 12450
	PlayerProgress.selected_time_slot_id = _time_slot_id()

	var mode := OS.get_environment("TSURI_FISHING_TIME_SLOT_MODE").strip_edges()
	match mode:
		"fanfare":
			await _capture_fanfare()
		"escape":
			await _capture_escape()
		_:
			await _capture_ready()


func _capture_ready() -> void:
	var vp := SubViewport.new()
	vp.size = VW
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var screen := FishingScreen.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({"continue_trip": true, "trip_stats": _trip_stats(), "spot_id": GameData.DEFAULT_FISHING_SPOT_ID})
	screen.size = Vector2(VW)
	vp.add_child(screen)

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout
	await get_tree().process_frame

	_save_viewport(vp, DEFAULT_OUT)


func _capture_fanfare() -> void:
	var vp := SubViewport.new()
	vp.size = VW
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var screen := FishingScreen.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({"continue_trip": true, "trip_stats": _trip_stats(), "spot_id": GameData.DEFAULT_FISHING_SPOT_ID})
	screen.size = Vector2(VW)
	vp.add_child(screen)
	await get_tree().process_frame
	await get_tree().process_frame

	screen._current_fish = GameData.get_fish("aji")
	screen._simulator.result_size_cm = 24.5
	screen._on_fight_finished(true, "釣り上げ成功")
	await get_tree().process_frame
	await get_tree().create_timer(0.55).timeout
	await get_tree().process_frame

	_save_viewport(vp, "/tmp/tsuri_fishing_time_slot_fanfare.png")


func _capture_escape() -> void:
	var vp := SubViewport.new()
	vp.size = VW
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var screen := FishingScreen.new()
	screen.theme = ThemeFactory.build_theme()
	screen.configure({"continue_trip": true, "trip_stats": _trip_stats(), "spot_id": GameData.DEFAULT_FISHING_SPOT_ID})
	screen.size = Vector2(VW)
	vp.add_child(screen)
	await get_tree().process_frame
	await get_tree().process_frame

	screen._current_fish = GameData.get_fish("aji")
	screen._on_fight_finished(false, "ラインが切れた")
	await get_tree().process_frame
	await get_tree().create_timer(0.20).timeout
	await get_tree().process_frame

	_save_viewport(vp, "/tmp/tsuri_fishing_time_slot_escape.png")


func _save_viewport(vp: SubViewport, default_out: String) -> void:
	var out := OS.get_environment("TSURI_FISHING_TIME_SLOT_OUT").strip_edges()
	if out.is_empty():
		out = default_out
	var texture := vp.get_texture()
	if texture == null:
		push_error("viewport texture was null for %s" % out)
		get_tree().quit(1)
		return
	var img := texture.get_image()
	if img == null or img.get_width() <= 0 or img.get_height() <= 0:
		push_error("viewport image was empty for %s" % out)
		get_tree().quit(1)
		return
	img.save_png(out)
	print(out)
	get_tree().quit()


func _time_slot_id() -> String:
	var requested := OS.get_environment("TSURI_FISHING_TIME_SLOT_ID").strip_edges()
	if GameData.TIME_SLOTS.has(requested):
		return requested
	return GameData.DEFAULT_TIME_SLOT_ID


func _trip_stats() -> Dictionary:
	var environment := GameData.get_fishing_environment(GameData.DEFAULT_FISHING_ENVIRONMENT_ID)
	var time_slot := GameData.get_time_slot(_time_slot_id())
	var stats := PlayerProgress.get_base_stats()
	stats["meal_buff"] = {}
	stats["environment_id"] = String(environment.get("id", GameData.DEFAULT_FISHING_ENVIRONMENT_ID))
	stats["weather_id"] = String(environment.get("weather_id", "sunny"))
	stats["weather_label"] = String(environment.get("weather_label", "快晴"))
	stats["wind_id"] = String(environment.get("wind_id", "weak"))
	stats["wind_label"] = String(environment.get("wind_label", "風 弱"))
	stats["surface_bgm_key"] = String(environment.get("surface_bgm_key", "calm"))
	stats["time_slot_id"] = String(time_slot.get("id", GameData.DEFAULT_TIME_SLOT_ID))
	stats["time_slot_label"] = String(time_slot.get("name", "日中"))
	stats["time_slot_grade"] = String(time_slot.get("grade", "none"))
	var bgm_override := String(time_slot.get("surface_bgm_key_override", ""))
	if not bgm_override.strip_edges().is_empty():
		stats["surface_bgm_key"] = bgm_override
	stats["trip_fired_event_ids"] = ["bird_swarm", "driftwood", "bottle_mail"]
	stats["bird_swarm_hits_remaining"] = 0
	stats["rig_id"] = GameData.DEFAULT_RIG_ID
	stats["rig_name"] = String(GameData.get_rig(GameData.DEFAULT_RIG_ID).get("name", "サビキ仕掛け"))
	stats["rig_bait_types"] = GameData.rig_bait_types(GameData.DEFAULT_RIG_ID)
	return stats
