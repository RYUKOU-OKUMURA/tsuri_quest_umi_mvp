extends Control
## ステータス/図鑑画面のキャプチャツール（SubViewport オフスクリーン描画）。
# 一部の魚を発見済みに捏造してカードが埋まるようにする（保存しないのでディスク不変）。
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const StatusScreen = preload("res://src/ui/status_screen.gd")
const NORMAL_OUT := "/tmp/tsuri_status_normal.png"
const HARD_OUT := "/tmp/tsuri_status_hard.png"
const LONG_OUT := "/tmp/tsuri_status_long_content.png"
const OVERLAY_OUT := "/tmp/tsuri_status_title_overlay.png"
const VW := Vector2i(1280, 720)


func _ready() -> void:
	var vp := SubViewport.new()
	vp.size = VW
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	# 捏造：参照に近い状態へ（add_child 前＝_build_screen 実行前に行う）
	PlayerProgress.level = 12
	var difficulty_id := OS.get_environment("TSURI_STATUS_DIFFICULTY")
	PlayerProgress.difficulty_id = difficulty_id if difficulty_id in ["normal", "hard"] else "normal"
	PlayerProgress.exp = 1450
	PlayerProgress.money = 12450
	PlayerProgress.equipped_rod_id = "iso"
	PlayerProgress.owned_rods = ["starter", "iso"]
	if OS.get_environment("TSURI_STATUS_LONG_CONTENT") == "1":
		PlayerProgress.equipped_rod_id = "marlin"
		PlayerProgress.owned_rods = ["starter", "iso", "offshore", "big_game", "marlin"]
	PlayerProgress.owned_boats = ["skiff"]
	PlayerProgress.pending_buff = {
		"recipe_id": "salt_grill",
		"name": "磯の活力丼",
		"stat": "max_energy",
		"value": 0.25,
		"text": "体力 +25 / 安全域 +10%",
	}
	PlayerProgress.caught_counts.clear()
	PlayerProgress.best_sizes.clear()
	PlayerProgress.inventory.clear()
	PlayerProgress.spot_caught_counts.clear()
	PlayerProgress.eaten_recipes.clear()
	var ids := GameData.get_all_fish_ids()
	var seeded_counts := {
		"aji": {"count": 12, "best": 34.2, "stock": 1, "spot": "harbor_pier"},
		"mejina": {"count": 6, "best": 44.2, "stock": 1, "spot": "rock_breakwater"},
		"kasago": {"count": 4, "best": 26.4, "stock": 2, "spot": "rock_breakwater"},
		"saba": {"count": 3, "best": 38.6, "stock": 3, "spot": "outer_tide"},
		"iwashi": {"count": 3, "best": 21.5, "stock": 3, "spot": "harbor_pier"},
		"hirame": {"count": 1, "best": 52.7, "stock": 1, "spot": "shallow_sand"},
		"suzuki": {"count": 1, "best": 62.4, "stock": 1, "spot": "outer_tide"},
		"boss_kurodai": {"count": 1, "best": 52.0, "stock": 0, "spot": "harbor_boulder"},
	}
	for fish_id in seeded_counts.keys():
		if not ids.has(fish_id):
			continue
		var data: Dictionary = seeded_counts[fish_id]
		PlayerProgress.caught_counts[fish_id] = int(data["count"])
		PlayerProgress.best_sizes[fish_id] = float(data["best"])
		var stock := int(data["stock"])
		if stock > 0:
			PlayerProgress.inventory[fish_id] = stock
		var spot_id := String(data["spot"])
		var spot_counts: Dictionary = PlayerProgress.spot_caught_counts.get(spot_id, {})
		spot_counts[fish_id] = int(data["count"])
		PlayerProgress.spot_caught_counts[spot_id] = spot_counts
	PlayerProgress.eaten_recipes = {
		"aji:salt_grill": 3,
		"mejina:simmered": 2,
		"kasago:soup": 1,
	}

	var s := StatusScreen.new()
	s.theme = ThemeFactory.build_theme()
	s.configure({})
	s.size = Vector2(VW)
	vp.add_child(s)

	await get_tree().process_frame
	await get_tree().process_frame
	if OS.get_environment("TSURI_STATUS_TITLE_OVERLAY") == "1":
		s._set_title_overlay_visible(true)
	await get_tree().create_timer(0.4).timeout

	var img := vp.get_texture().get_image()
	if not _is_rendered_image_valid(img):
		img.save_png("/tmp/tsuri_status_invalid.png")
		push_error("ステータス画面が空描画または黒矩形を含む不正captureになりました。")
		get_tree().quit(1)
		return
	var out := NORMAL_OUT
	if OS.get_environment("TSURI_STATUS_TITLE_OVERLAY") == "1":
		out = OVERLAY_OUT
	elif OS.get_environment("TSURI_STATUS_LONG_CONTENT") == "1":
		out = LONG_OUT
	elif PlayerProgress.difficulty_id == "hard":
		out = HARD_OUT
	img.save_png(out)
	get_tree().quit()


func _is_rendered_image_valid(image: Image) -> bool:
	if image == null or image.is_empty() or image.get_size() != VW:
		return false
	var sampled := 0
	var near_black := 0
	var transparent := 0
	for y in range(0, image.get_height(), 4):
		for x in range(0, image.get_width(), 4):
			var pixel := image.get_pixel(x, y)
			sampled += 1
			if pixel.a < 0.9:
				transparent += 1
			if maxf(pixel.r, maxf(pixel.g, pixel.b)) <= 0.03:
				near_black += 1
	return transparent == 0 and near_black <= int(sampled * 0.01)
