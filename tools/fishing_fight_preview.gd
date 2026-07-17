extends Control
## 水中ファイト看板画面のキャプチャツール。
# 既存の釣り画面をファイト中に進め、素材ベースの UnderwaterView を PNG 保存する。
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const FishingScreen = preload("res://src/ui/fishing_screen.gd")
const DEFAULT_OUT := "/tmp/tsuri_fishing_fight.png"
const VW := Vector2i(1280, 720)


func _ready() -> void:
	var out := OS.get_environment("TSURI_FIGHT_CAPTURE_OUT")
	if out.is_empty():
		out = DEFAULT_OUT
	if FileAccess.file_exists(out):
		var remove_error := DirAccess.remove_absolute(out)
		if remove_error != OK:
			push_warning("Failed to remove stale fight capture: %s" % out)
	PlayerProgress.level = max(PlayerProgress.level, GameData.BOSS_UNLOCK_LEVEL)
	PlayerProgress.money = 12450

	var vp := SubViewport.new()
	vp.size = VW
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var s := FishingScreen.new()
	s.theme = ThemeFactory.build_theme()
	s.configure({"spot_id": GameData.BOSS_FISHING_SPOT_ID})
	s.size = Vector2(VW)
	vp.add_child(s)

	await get_tree().process_frame
	await get_tree().process_frame
	_configure_capture_environment(s)

	# ファイト画面を直接確認するため、通常の待ち時間を飛ばして状態を作る。
	var requested_fish_id := OS.get_environment("TSURI_FIGHT_FISH_ID")
	var showcase_fish := GameData.get_fish(requested_fish_id).duplicate(true) if not requested_fish_id.is_empty() else {}
	if showcase_fish.is_empty():
		showcase_fish = GameData.get_fish("boss_kurodai").duplicate(true)
		showcase_fish["name"] = "クロダイ"
		showcase_fish["rarity"] = "レア"
		showcase_fish["boss"] = false
		showcase_fish["size_min"] = 40.2
		showcase_fish["size_max"] = 48.2
		showcase_fish["start_distance"] = 38.0
		showcase_fish["start_depth"] = 18.0
	var fixture_name := OS.get_environment("TSURI_FIGHT_FISH_NAME").strip_edges()
	if not fixture_name.is_empty():
		showcase_fish["name"] = fixture_name
	var fixture_rarity := OS.get_environment("TSURI_FIGHT_RARITY").strip_edges()
	if not fixture_rarity.is_empty():
		showcase_fish["rarity"] = fixture_rarity
	var capture_visual_position := Vector2(
		_env_float("TSURI_FIGHT_VISUAL_X", 0.42),
		_env_float("TSURI_FIGHT_VISUAL_Y", 0.46)
	)
	var capture_visual_direction := 1.0 if _env_float("TSURI_FIGHT_VISUAL_DIRECTION", 1.0) >= 0.0 else -1.0
	s._current_fish = showcase_fish
	s._simulator.prepare(showcase_fish, s._trip_stats)
	s._view.bind_simulator(s._simulator)
	s._surface_view.bind_simulator(s._simulator)
	s._fight_sidebar.bind(s._simulator, showcase_fish, s._trip_stats)
	s._fight_floating_card.bind(s._simulator, showcase_fish, s._trip_stats)
	s._fight_hud.bind(s._simulator, showcase_fish, s._trip_stats)
	s._simulator.cast()
	for _i in range(80):
		s._simulator.tick(0.08)
		if s._simulator.state == FishingSimulator.State.BITE:
			break
	s._simulator.hook()
	s._simulator.action_name = "突進"
	s._simulator.visual_position = capture_visual_position
	s._simulator.visual_direction = capture_visual_direction
	s._simulator.depth = 18.6
	s._simulator.tension = 0.66
	s._view._fish_flash = 0.96
	s._view.modulate.a = 1.0
	s._surface_view.modulate.a = 0.0

	# Keep the comparison capture locked to the intended hit moment.
	s.set_process(false)
	s._view.set_process(false)
	s._fight_sidebar.set_process(false)
	s._fight_floating_card.set_process(false)
	s._fight_hud.set_process(false)
	s._fight_status_bar.set_process(false)
	s._simulator.action_name = "突進"
	var fixture_action := OS.get_environment("TSURI_FIGHT_ACTION_MESSAGE").strip_edges()
	s._simulator.action_message = fixture_action if not fixture_action.is_empty() else "一気に深く潜ろうとしている！ラインを緩めず耐えよう！"
	if OS.get_environment("TSURI_FIGHT_CARD_STATE") == "unrevealed":
		s._simulator.fish_revealed = false
	s._simulator.visual_position = capture_visual_position
	s._simulator.visual_direction = capture_visual_direction
	s._simulator.depth = 18.6
	s._simulator.tension = 0.66
	s._view._fish_flash = 0.88
	s._view._time = 1.25
	# Standard and focus evidence share every fixture value. The focus variant
	# changes only the semantic owner/common ring.
	var capture_focus := OS.get_environment("TSURI_FIGHT_FOCUS") == "1"
	s._view.queue_redraw()
	s._fight_sidebar.queue_redraw()
	s._fight_floating_card.queue_redraw()
	s._fight_hud.queue_redraw()
	s._fight_status_bar.queue_redraw()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var fight_focus_targets: Array[Control] = s._fight_hud.keyboard_focus_targets()
	if capture_focus and not fight_focus_targets.is_empty():
		fight_focus_targets[0].grab_focus()
	else:
		vp.gui_release_focus()
	for focus_target in fight_focus_targets:
		var indicator := focus_target.get_node_or_null("CommonFocusIndicator") as Control
		if indicator != null:
			indicator.visible = capture_focus and focus_target == fight_focus_targets[0]
			indicator.queue_redraw()
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if capture_focus:
		var expected_focus := fight_focus_targets[0] if not fight_focus_targets.is_empty() else null
		if vp.gui_get_focus_owner() != expected_focus:
			push_error("FIGHT focus capture did not retain the reel focus owner")
			get_tree().quit(1)
			return

	var img := vp.get_texture().get_image()
	if img == null:
		push_error("SubViewport get_image() returned null; run with a real display driver or use /tmp/tsuri_fishing_fight_static.png from tools/build_fight_full_static_compare.py")
		get_tree().quit(1)
		return
	img.save_png(out)
	get_tree().quit()


func _configure_capture_environment(screen) -> void:
	var weather_id := OS.get_environment("TSURI_FIGHT_WEATHER_ID").strip_edges()
	if weather_id.is_empty():
		weather_id = "partly_cloudy"
	var weather_labels := {
		"sunny": "快晴",
		"partly_cloudy": "晴れ曇り",
		"cloudy": "曇り",
		"rain": "小雨",
		"fog": "霧",
	}
	screen._trip_stats["weather_id"] = weather_id
	screen._trip_stats["weather_label"] = String(weather_labels.get(weather_id, "晴れ曇り"))
	screen._trip_stats["wind_id"] = "weak"
	screen._trip_stats["wind_label"] = "風 弱"
	screen._fight_status_bar.bind(screen._simulator, screen._trip_stats)


func _env_float(name: String, fallback: float) -> float:
	var text := OS.get_environment(name).strip_edges()
	if text.is_empty() or not text.is_valid_float():
		return fallback
	return float(text)
