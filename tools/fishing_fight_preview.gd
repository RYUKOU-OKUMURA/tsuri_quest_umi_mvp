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
	s._current_fish = showcase_fish
	s._simulator.prepare(showcase_fish, s._trip_stats)
	s._view.bind_simulator(s._simulator)
	s._surface_view.bind_simulator(s._simulator)
	s._fight_sidebar.bind(s._simulator, showcase_fish, s._trip_stats)
	s._fight_hud.bind(s._simulator, showcase_fish, s._trip_stats)
	s._simulator.cast()
	for _i in range(80):
		s._simulator.tick(0.08)
		if s._simulator.state == FishingSimulator.State.BITE:
			break
	s._simulator.hook()
	s._simulator.action_name = "突進"
	s._simulator.visual_position = Vector2(0.42, 0.46)
	s._simulator.visual_direction = 1.0
	s._simulator.depth = 18.6
	s._simulator.tension = 0.66
	s._view._fish_flash = 0.96
	s._view.modulate.a = 1.0
	s._surface_view.modulate.a = 0.0

	# Keep the comparison capture locked to the intended hit moment.
	s.set_process(false)
	s._view.set_process(false)
	s._fight_sidebar.set_process(false)
	s._fight_hud.set_process(false)
	s._fight_status_bar.set_process(false)
	s._simulator.action_name = "突進"
	s._simulator.action_message = "一気に深く潜ろうとしている！ラインを緩めず耐えよう！"
	s._simulator.visual_position = Vector2(0.42, 0.46)
	s._simulator.visual_direction = 1.0
	s._simulator.depth = 18.6
	s._simulator.tension = 0.66
	s._view._fish_flash = 0.88
	s._view.queue_redraw()
	s._fight_sidebar.queue_redraw()
	s._fight_hud.queue_redraw()
	s._fight_status_bar.queue_redraw()
	await get_tree().process_frame
	await get_tree().process_frame

	var img := vp.get_texture().get_image()
	if img == null:
		push_error("SubViewport get_image() returned null; run with a real display driver or use /tmp/tsuri_fishing_fight_static.png from tools/build_fight_full_static_compare.py")
		get_tree().quit(1)
		return
	img.save_png(out)
	get_tree().quit()
