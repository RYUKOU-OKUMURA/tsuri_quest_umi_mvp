extends Control
## 水上キャスト画面の READY〜BITE 状態を連続キャプチャする確認ツール。

const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const FishingScreen = preload("res://src/ui/fishing_screen.gd")

const VW := Vector2i(1280, 720)
const DEFAULT_OUT_PREFIX := "/tmp/tsuri_fishing_surface"
const PIXEL_REGRESSION_FISH_ID := "aji"
const PIXEL_REGRESSION_FISH_SIZE_CM := 24.5
const PIXEL_REGRESSION_ENVIRONMENT_ID := "sunny_calm"
const PIXEL_REGRESSION_TIME_SLOT_ID := "daytime"


func _ready() -> void:
	PlayerProgress.level = GameData.MAX_LEVEL
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
	if OS.get_environment("TSURI_SURFACE_STATE_PIXEL_REGRESSION") == "1":
		_fix_pixel_regression_fish(screen)

	var out_prefix := OS.get_environment("TSURI_SURFACE_STATE_OUT_PREFIX").strip_edges()
	if out_prefix.is_empty():
		out_prefix = DEFAULT_OUT_PREFIX
	var out_ready := "%s_ready.png" % out_prefix
	var out_casting := "%s_casting.png" % out_prefix
	var out_waiting := "%s_waiting.png" % out_prefix
	var out_approach := "%s_approach.png" % out_prefix
	var out_bite := "%s_bite.png" % out_prefix

	await _settle()
	await _capture(vp, screen, out_ready)

	screen._on_main_action_pressed()
	await get_tree().create_timer(0.16).timeout
	await _settle()
	await _capture(vp, screen, out_casting)

	var reached := await _wait_until(screen, FishingSimulator.State.WAITING, 3.2)
	if not reached:
		get_tree().quit(1)
		return
	await get_tree().create_timer(0.26).timeout
	await _settle()
	print("capture waiting state=%d" % screen._simulator.state)
	await _capture(vp, screen, out_waiting)

	reached = await _wait_until(screen, FishingSimulator.State.APPROACH, 5.2)
	if not reached:
		get_tree().quit(1)
		return
	await get_tree().create_timer(0.38).timeout
	await _settle()
	print("capture approach state=%d" % screen._simulator.state)
	await _capture(vp, screen, out_approach)

	reached = await _wait_until(screen, FishingSimulator.State.BITE, 4.2)
	if not reached:
		get_tree().quit(1)
		return
	await get_tree().create_timer(0.10).timeout
	await _settle()
	print("capture bite state=%d" % screen._simulator.state)
	await _capture(vp, screen, out_bite)

	print("fishing_surface_states_preview:")
	print(out_ready)
	print(out_casting)
	print(out_waiting)
	print(out_approach)
	print(out_bite)
	get_tree().quit()


func _fix_pixel_regression_fish(screen: Control) -> void:
	# GameDataの抽選RNGを跨がず、base/TIPを同一の魚辞書と表示サイズで比較する。
	var fish := GameData.get_fish(PIXEL_REGRESSION_FISH_ID).duplicate(true)
	if fish.is_empty():
		push_error("pixel regression fish is missing: %s" % PIXEL_REGRESSION_FISH_ID)
		get_tree().quit(1)
		return
	fish["size_min"] = PIXEL_REGRESSION_FISH_SIZE_CM
	fish["size_max"] = PIXEL_REGRESSION_FISH_SIZE_CM
	screen._current_fish = fish
	screen._prepare_simulator_with_current_fish()
	screen._refresh_fish_info()


func _preview_config() -> Dictionary:
	var config := {}
	var spot_id := OS.get_environment("TSURI_SURFACE_STATE_SPOT_ID").strip_edges()
	var environment_id := OS.get_environment("TSURI_SURFACE_STATE_ENVIRONMENT_ID").strip_edges()
	var time_slot_id := OS.get_environment("TSURI_SURFACE_STATE_TIME_SLOT_ID").strip_edges()
	var lure_fish_id := OS.get_environment("TSURI_SURFACE_STATE_SHARK_LURE_FISH_ID").strip_edges()
	var lure_count_text := OS.get_environment("TSURI_SURFACE_STATE_SHARK_LURE_COUNT").strip_edges()
	var lure_remaining_text := OS.get_environment("TSURI_SURFACE_STATE_SHARK_LURE_REMAINING").strip_edges()
	if OS.get_environment("TSURI_SURFACE_STATE_PIXEL_REGRESSION") == "1":
		environment_id = PIXEL_REGRESSION_ENVIRONMENT_ID
		time_slot_id = PIXEL_REGRESSION_TIME_SLOT_ID
	var lure_count := maxi(0, int(lure_count_text))
	var lure_remaining := maxi(0, int(lure_remaining_text))
	if not spot_id.is_empty():
		config["spot_id"] = spot_id
	if spot_id.is_empty() and environment_id.is_empty() and time_slot_id.is_empty() and lure_fish_id.is_empty():
		return config

	var environment := GameData.get_fishing_environment(
		environment_id if not environment_id.is_empty() else GameData.DEFAULT_FISHING_ENVIRONMENT_ID
	)
	var stats := _trip_stats_for_environment(environment)
	if not time_slot_id.is_empty():
		var time_slot := GameData.get_time_slot(time_slot_id)
		stats["time_slot_id"] = String(time_slot.get("id", GameData.DEFAULT_TIME_SLOT_ID))
		stats["time_slot_label"] = String(time_slot.get("name", "日中"))
		stats["time_slot_grade"] = String(time_slot.get("grade", "none"))
		var bgm_override := String(time_slot.get("surface_bgm_key_override", ""))
		if not bgm_override.strip_edges().is_empty():
			stats["surface_bgm_key"] = bgm_override
	if spot_id == "danger_reef" or not lure_fish_id.is_empty():
		var nomase := GameData.get_rig("nomase")
		if not nomase.is_empty():
			stats["rig_id"] = "nomase"
			stats["rig_name"] = String(nomase.get("name", "泳がせ仕掛け"))
			stats["rig_bait_types"] = GameData.rig_bait_types("nomase")
	if not lure_fish_id.is_empty():
		var lure_fish := GameData.get_fish(lure_fish_id)
		if not lure_fish.is_empty() and not bool(lure_fish.get("shark", false)):
			PlayerProgress.inventory[lure_fish_id] = lure_count if not lure_count_text.is_empty() else max(1, PlayerProgress.fish_count(lure_fish_id))
			stats["shark_lure_fish_id"] = lure_fish_id
			stats["shark_lure_fish_name"] = String(lure_fish.get("name", lure_fish_id))
			if not lure_remaining_text.is_empty() and lure_remaining > 0:
				stats["shark_lure_charges"] = {lure_fish_id: lure_remaining}
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
	stats["time_slot_id"] = GameData.DEFAULT_TIME_SLOT_ID
	stats["time_slot_label"] = String(GameData.get_time_slot(GameData.DEFAULT_TIME_SLOT_ID).get("name", "日中"))
	stats["time_slot_grade"] = "none"
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


func _capture(vp: SubViewport, screen: Control, out_path: String) -> void:
	# base/TIPの画素回帰では到達時刻やJuicer shakeを状態差にしない。
	var surface_view = screen._surface_view
	# base/TIP全画面pixel回帰では、未確認魚カードが実時間を参照する
	# sonar pulseを既知魚カードへ固定し、無関係な時計差分を除く。
	if OS.get_environment("TSURI_SURFACE_STATE_PIXEL_REGRESSION") == "1":
		screen._simulator.fish_revealed = true
		screen._fight_sidebar.queue_redraw()
	var fixed_depths := {
		FishingSimulator.State.READY: 0.0,
		FishingSimulator.State.CASTING: 4.0,
		FishingSimulator.State.WAITING: 7.0,
		FishingSimulator.State.APPROACH: 12.0,
		FishingSimulator.State.BITE: 18.0,
	}
	var fixed_visual_x := {
		FishingSimulator.State.READY: 0.0,
		FishingSimulator.State.CASTING: 0.08,
		FishingSimulator.State.WAITING: 0.16,
		FishingSimulator.State.APPROACH: 0.68,
		FishingSimulator.State.BITE: 1.0,
	}
	screen.set_process(false)
	screen._simulator.depth = float(fixed_depths.get(screen._simulator.state, 0.0))
	screen._simulator.visual_position = Vector2(float(fixed_visual_x.get(screen._simulator.state, 0.0)), 0.46)
	surface_view.set_process(false)
	surface_view._time = 1.25
	surface_view._waiting_ring = 0.33
	surface_view._bobber_dip = 1.0 if screen._simulator.state == FishingSimulator.State.BITE else 0.0
	surface_view._splash = 0.72 if screen._simulator.state == FishingSimulator.State.BITE else 0.0
	surface_view._hit_flash = 0.0
	surface_view._cast_flight = 0.52 if screen._simulator.state == FishingSimulator.State.CASTING else 0.0
	surface_view._approach_glow = 1.0 if screen._simulator.state in [FishingSimulator.State.APPROACH, FishingSimulator.State.BITE] else 0.24
	Juicer._trauma = 0.0
	Juicer._time = 0.0
	surface_view.queue_redraw()
	screen.queue_redraw()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	if FileAccess.file_exists(out_path):
		DirAccess.remove_absolute(out_path)
	var img := vp.get_texture().get_image()
	if img == null:
		push_error("SubViewport get_image() returned null for %s" % out_path)
		return
	img.save_png(out_path)
	surface_view.set_process(true)
	screen.set_process(true)
