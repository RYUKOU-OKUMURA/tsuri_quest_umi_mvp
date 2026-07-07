extends Control
## 水上キャスト画面の READY〜BITE 状態を連続キャプチャする確認ツール。

const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const FishingScreen = preload("res://src/ui/fishing_screen.gd")

const VW := Vector2i(1280, 720)
const DEFAULT_OUT_PREFIX := "/tmp/tsuri_fishing_surface"


func _ready() -> void:
	PlayerProgress.money = 12450

	var vp := SubViewport.new()
	vp.size = VW
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var screen := FishingScreen.new()
	screen.theme = ThemeFactory.build_theme()
	var config := _preview_config()
	screen.configure(config)
	screen.size = Vector2(VW)
	vp.add_child(screen)

	var out_prefix := OS.get_environment("TSURI_SURFACE_STATE_OUT_PREFIX").strip_edges()
	if out_prefix.is_empty():
		out_prefix = DEFAULT_OUT_PREFIX
	var out_ready := "%s_ready.png" % out_prefix
	var out_casting := "%s_casting.png" % out_prefix
	var out_waiting := "%s_waiting.png" % out_prefix
	var out_approach := "%s_approach.png" % out_prefix
	var out_bite := "%s_bite.png" % out_prefix

	await _settle()
	_save(vp, out_ready)

	screen._simulator.cast()
	await get_tree().create_timer(0.16).timeout
	await _settle()
	_save(vp, out_casting)

	var reached := await _wait_until(screen, FishingSimulator.State.WAITING, 3.2)
	if not reached:
		get_tree().quit(1)
		return
	await get_tree().create_timer(0.26).timeout
	await _settle()
	print("capture waiting state=%d" % screen._simulator.state)
	_save(vp, out_waiting)

	reached = await _wait_until(screen, FishingSimulator.State.APPROACH, 5.2)
	if not reached:
		get_tree().quit(1)
		return
	await get_tree().create_timer(0.38).timeout
	await _settle()
	print("capture approach state=%d" % screen._simulator.state)
	_save(vp, out_approach)

	reached = await _wait_until(screen, FishingSimulator.State.BITE, 4.2)
	if not reached:
		get_tree().quit(1)
		return
	await get_tree().create_timer(0.10).timeout
	await _settle()
	print("capture bite state=%d" % screen._simulator.state)
	_save(vp, out_bite)

	print("fishing_surface_states_preview:")
	print(out_ready)
	print(out_casting)
	print(out_waiting)
	print(out_approach)
	print(out_bite)
	get_tree().quit()


func _preview_config() -> Dictionary:
	var config := {}
	var spot_id := OS.get_environment("TSURI_SURFACE_STATE_SPOT_ID").strip_edges()
	var environment_id := OS.get_environment("TSURI_SURFACE_STATE_ENVIRONMENT_ID").strip_edges()
	var lure_fish_id := OS.get_environment("TSURI_SURFACE_STATE_SHARK_LURE_FISH_ID").strip_edges()
	if not spot_id.is_empty():
		config["spot_id"] = spot_id
	if spot_id.is_empty() and environment_id.is_empty() and lure_fish_id.is_empty():
		return config

	var environment := GameData.get_fishing_environment(
		environment_id if not environment_id.is_empty() else GameData.DEFAULT_FISHING_ENVIRONMENT_ID
	)
	var stats := _trip_stats_for_environment(environment)
	if spot_id == "danger_reef" or not lure_fish_id.is_empty():
		var nomase := GameData.get_rig("nomase")
		if not nomase.is_empty():
			stats["rig_id"] = "nomase"
			stats["rig_name"] = String(nomase.get("name", "泳がせ仕掛け"))
			stats["rig_bait_types"] = GameData.rig_bait_types("nomase")
	if not lure_fish_id.is_empty():
		var lure_fish := GameData.get_fish(lure_fish_id)
		if not lure_fish.is_empty() and not bool(lure_fish.get("shark", false)):
			stats["shark_lure_fish_id"] = lure_fish_id
			stats["shark_lure_fish_name"] = String(lure_fish.get("name", lure_fish_id))
	config["continue_trip"] = true
	config["trip_stats"] = stats
	return config


func _trip_stats_for_environment(environment: Dictionary) -> Dictionary:
	var stats := PlayerProgress.get_base_stats()
	stats["meal_buff"] = {}
	stats["environment_id"] = String(environment.get("id", GameData.DEFAULT_FISHING_ENVIRONMENT_ID))
	stats["weather_id"] = String(environment.get("weather_id", "sunny"))
	stats["weather_label"] = String(environment.get("weather_label", "快晴"))
	stats["wind_id"] = String(environment.get("wind_id", "weak"))
	stats["wind_label"] = String(environment.get("wind_label", "風 弱"))
	stats["surface_bgm_key"] = String(environment.get("surface_bgm_key", "calm"))
	stats["trip_fired_event_ids"] = ["bird_swarm", "driftwood", "bottle_mail"]
	stats["bird_swarm_hits_remaining"] = 0
	var rig := GameData.get_rig(GameData.DEFAULT_RIG_ID)
	stats["rig_id"] = GameData.DEFAULT_RIG_ID
	stats["rig_name"] = String(rig.get("name", "サビキ仕掛け"))
	stats["rig_bait_types"] = GameData.rig_bait_types(GameData.DEFAULT_RIG_ID)
	return stats


func _wait_until(screen: Node, target_state: int, timeout: float) -> bool:
	var elapsed := 0.0
	while elapsed < timeout:
		if screen._simulator.state == target_state:
			return true
		await get_tree().create_timer(0.05).timeout
		elapsed += 0.05
	push_error("Timed out waiting for fishing state %d, current=%d" % [target_state, screen._simulator.state])
	return false


func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.05).timeout
	await get_tree().process_frame


func _save(vp: SubViewport, out_path: String) -> void:
	if FileAccess.file_exists(out_path):
		DirAccess.remove_absolute(out_path)
	var img := vp.get_texture().get_image()
	if img == null:
		push_error("SubViewport get_image() returned null for %s" % out_path)
		return
	img.save_png(out_path)
