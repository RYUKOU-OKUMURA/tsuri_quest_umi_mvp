extends Control
## 水中ファイト看板画面のキャプチャツール。
# 既存の釣り画面をファイト中に進め、素材ベースの UnderwaterView を PNG 保存する。
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const FishingScreen = preload("res://src/ui/fishing_screen.gd")
const OUT := "/tmp/tsuri_fishing_fight.png"
const VW := Vector2i(1280, 720)


func _ready() -> void:
	PlayerProgress.level = max(PlayerProgress.level, GameData.BOSS_UNLOCK_LEVEL)

	var vp := SubViewport.new()
	vp.size = VW
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var s := FishingScreen.new()
	s.theme = ThemeFactory.build_theme()
	s.configure({})
	s.size = Vector2(VW)
	vp.add_child(s)

	await get_tree().process_frame
	await get_tree().process_frame

	# ファイト画面を直接確認するため、通常の待ち時間を飛ばして状態を作る。
	s._target_option.select(1)
	s._prepare_new_attempt()
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

	await get_tree().create_timer(0.12).timeout
	s._view._fish_flash = 0.88
	await get_tree().process_frame

	var img := vp.get_texture().get_image()
	if img == null:
		push_error("SubViewport get_image() returned null")
		get_tree().quit(1)
		return
	img.save_png(OUT)
	get_tree().quit()
