extends Control
## ステータス/図鑑画面のキャプチャツール（SubViewport オフスクリーン描画）。
# 一部の魚を発見済みに捏造してカードが埋まるようにする（保存しないのでディスク不変）。
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const StatusScreen = preload("res://src/ui/status_screen.gd")
const OUT := "/tmp/tsuri_status.png"
const VW := Vector2i(1280, 720)


func _ready() -> void:
	var vp := SubViewport.new()
	vp.size = VW
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	# 捏造：いくつか発見済みに（add_child 前＝_build_screen 実行前に行う）
	PlayerProgress.caught_counts.clear()
	PlayerProgress.best_sizes.clear()
	var ids := GameData.get_all_fish_ids()
	if ids.size() > 0:
		PlayerProgress.caught_counts[ids[0]] = 12
		PlayerProgress.best_sizes[ids[0]] = 23.5
	if ids.size() > 1:
		PlayerProgress.caught_counts[ids[1]] = 5
		PlayerProgress.best_sizes[ids[1]] = 31.0
	if ids.size() > 2:
		PlayerProgress.caught_counts[ids[2]] = 3
		PlayerProgress.best_sizes[ids[2]] = 28.2
	for fid in ids:
		if bool(GameData.get_fish(fid).get("boss", false)):
			PlayerProgress.caught_counts[fid] = 1
			PlayerProgress.best_sizes[fid] = 52.0

	var s := StatusScreen.new()
	s.theme = ThemeFactory.build_theme()
	s.configure({})
	s.size = Vector2(VW)
	vp.add_child(s)

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout

	var img := vp.get_texture().get_image()
	img.save_png(OUT)
	get_tree().quit()
