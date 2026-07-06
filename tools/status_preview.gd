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

	# 捏造：参照に近い状態へ（add_child 前＝_build_screen 実行前に行う）
	PlayerProgress.level = 12
	PlayerProgress.exp = 1450
	PlayerProgress.money = 12450
	PlayerProgress.equipped_rod_id = "iso"
	PlayerProgress.owned_rods = ["starter", "iso"]
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
	img.save_png(OUT)
	get_tree().quit()
