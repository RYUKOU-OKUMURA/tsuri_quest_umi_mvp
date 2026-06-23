extends Control
## 調理画面＋レベルアップ演出のキャプチャツール。
# headlessでも描画できるよう SubViewport でオフスクリーン描画する。
# PlayerProgress の進行/所持魚を一時的に捏造（保存しないのでディスク不変）。
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const CookingScreen = preload("res://src/ui/cooking_screen.gd")
const LevelUpPanelScript = preload("res://src/ui/components/level_up_panel.gd")
const OUT := "/tmp/tsuri_cooking.png"
const VW := Vector2i(1280, 720)


func _ready() -> void:
	theme = ThemeFactory.build_theme()

	# 捏造：レベル4・EXP半分・魚3種（保存しないのでディスクは不変）
	PlayerProgress.level = 4
	PlayerProgress.exp = int(float(PlayerProgress.exp_to_next_level()) * 0.5)
	PlayerProgress.inventory.clear()
	var fish_ids := GameData.get_all_fish_ids()
	if not fish_ids.is_empty():
		PlayerProgress.inventory[fish_ids[0]] = 4
	if fish_ids.size() > 1:
		PlayerProgress.inventory[fish_ids[1]] = 2
	if fish_ids.size() > 2:
		PlayerProgress.inventory[fish_ids[2]] = 1

	var vp := SubViewport.new()
	vp.size = VW
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ONCE
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var s := CookingScreen.new()
	# SubViewport は別テーマコンテキストになるため、画面自身にテーマを設定して子孫へ継承させる
	s.theme = ThemeFactory.build_theme()
	s.configure({})
	s.size = Vector2(VW)
	vp.add_child(s)

	await get_tree().process_frame
	await get_tree().process_frame

	# 能力差分が見えるよう、1レベル前の旧statsを捏造して演出を表示
	var new_stats := PlayerProgress.get_base_stats()
	var old_level := maxi(1, PlayerProgress.level - 1)
	var old_stats := {
		"max_energy": float(new_stats["max_energy"]) - 5.0,
		"reel_power": float(new_stats["reel_power"]) - 0.58,
		"technique": int(new_stats["technique"]) - 1,
		"focus": int(new_stats["focus"]) - 1,
	}
	var panel := LevelUpPanelScript.new()
	s.add_child(panel)
	panel.show_level_up(old_level, PlayerProgress.level, old_stats, new_stats)

	await get_tree().create_timer(0.7).timeout
	await get_tree().process_frame

	var img := vp.get_texture().get_image()
	if img == null:
		push_error("SubViewport get_image() returned null")
		get_tree().quit(1)
		return
	img.save_png(OUT)
	get_tree().quit()
