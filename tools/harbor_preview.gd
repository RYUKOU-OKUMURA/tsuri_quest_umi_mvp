extends Control
## 港メニューの実画面キャプチャ用ツール。

const HarborScreenScript = preload("res://src/ui/harbor_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const DEFAULT_OUT := "/tmp/tsuri_harbor_screen.png"


func _ready() -> void:
	theme = ThemeFactory.build_theme()
	_setup_preview_progress()
	if OS.get_environment("TSURI_HARBOR_NO_MEAL") == "1":
		PlayerProgress.pending_buff = {}
	var screen := HarborScreenScript.new()
	screen.configure({})
	add_child(screen)
	await get_tree().process_frame
	await get_tree().process_frame
	await _apply_header_interaction_state(screen)
	await get_tree().create_timer(1.0).timeout
	RenderingServer.force_draw(false, 0.0)
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	if not _is_rendered_image_valid(img):
		push_error("港画面が空描画または黒矩形を含む不正captureになりました")
		get_tree().quit(1)
		return
	var out := OS.get_environment("TSURI_HARBOR_OUT").strip_edges()
	if out.is_empty():
		out = DEFAULT_OUT
	img.save_png(out)
	print(out)
	get_tree().quit()


func _is_rendered_image_valid(image: Image) -> bool:
	if image == null or image.is_empty() or image.get_size() != Vector2i(1280, 720):
		return false
	var sampled := 0
	var near_black := 0
	for y in range(0, image.get_height(), 8):
		for x in range(0, image.get_width(), 8):
			var pixel := image.get_pixel(x, y)
			sampled += 1
			if maxf(pixel.r, maxf(pixel.g, pixel.b)) <= 0.02:
				near_black += 1
	return near_black <= int(sampled * 0.55)


func _apply_header_interaction_state(screen) -> void:
	var state := OS.get_environment("TSURI_HARBOR_HEADER_STATE").strip_edges()
	var button := screen._settings_button as Button
	if button == null:
		return
	Input.warp_mouse(Vector2(20.0, 700.0))
	await get_tree().process_frame
	if state == "focus":
		button.grab_focus()
		await get_tree().process_frame
		return
	if state == "hover" or state == "pressed":
		var style_name := "hover" if state == "hover" else "pressed"
		button.add_theme_stylebox_override("normal", button.get_theme_stylebox(style_name))
		await get_tree().process_frame


func _setup_preview_progress() -> void:
	var level_override := int(OS.get_environment("TSURI_HARBOR_LEVEL"))
	var seed := OS.get_environment("TSURI_HARBOR_SEED")
	if seed == "legacy_compare":
		_setup_legacy_compare_progress(level_override)
		return
	if seed == "departure_spacing_compare":
		_setup_departure_spacing_compare_progress(level_override)
		return
	PlayerProgress.level = level_override if level_override > 0 else 30
	PlayerProgress.exp = 0
	PlayerProgress.money = 50080
	PlayerProgress.inventory = {
		"aji": 3,
		"iwashi": 4,
		"saba": 5,
		"madai": 3,
		"hirame": 2,
		"kihada": 1,
		"kasago": 2,
	}
	PlayerProgress.equipped_rod_id = "big_game"
	PlayerProgress.play_seconds = 3178.0
	PlayerProgress.owned_boats = ["bluewater_boat"]
	PlayerProgress.sea_chart_fragments = 3
	PlayerProgress.eaten_recipes = {"shioyaki": 1}
	PlayerProgress.quest_board = [
		{
			"kind": "delivery",
			"fish_id": "aji",
			"count": 1,
			"reward_money": 500,
			"text": "港の食堂へアジを届けてほしい",
		}
	]
	PlayerProgress.caught_counts = {"aji": 12, "iwashi": 3}
	_fix_rumor_to_single_harbor_nushi()
	PlayerProgress.shark_bonds = {}
	var time_slot_id := OS.get_environment("TSURI_HARBOR_TIME_SLOT_ID").strip_edges()
	if not time_slot_id.is_empty() and GameData.is_time_slot_unlocked(time_slot_id, PlayerProgress.level):
		PlayerProgress.selected_time_slot_id = time_slot_id
	else:
		PlayerProgress.selected_time_slot_id = GameData.DEFAULT_TIME_SLOT_ID
	PlayerProgress.pending_buff = {
		"name": "カサゴの塩焼き",
		"text": "次の釣行で最大体力 +5%",
	}


func _setup_legacy_compare_progress(level_override: int) -> void:
	# 司令盤刷新前に保存したbefore画像と、同一データ条件でafterを撮るための固定seed。
	PlayerProgress.level = level_override if level_override > 0 else 20
	PlayerProgress.exp = 306
	PlayerProgress.money = 12450
	PlayerProgress.inventory = {"aji": 2, "mejina": 1, "saba": 2, "madai": 1, "hirame": 1}
	PlayerProgress.equipped_rod_id = "offshore"
	PlayerProgress.play_seconds = 22441.0
	PlayerProgress.owned_boats = []
	PlayerProgress.sea_chart_fragments = 0
	PlayerProgress.eaten_recipes = {}
	PlayerProgress.quest_board = []
	PlayerProgress.caught_counts = {}
	_fix_rumor_to_single_harbor_nushi()
	PlayerProgress.shark_bonds = {}
	var time_slot_id := OS.get_environment("TSURI_HARBOR_TIME_SLOT_ID").strip_edges()
	if not time_slot_id.is_empty() and GameData.is_time_slot_unlocked(time_slot_id, PlayerProgress.level):
		PlayerProgress.selected_time_slot_id = time_slot_id
	else:
		PlayerProgress.selected_time_slot_id = GameData.DEFAULT_TIME_SLOT_ID
	PlayerProgress.pending_buff = {
		"name": "カサゴの塩焼き",
		"text": "次の釣行で最大体力 +5%",
	}


func _setup_departure_spacing_compare_progress(level_override: int) -> void:
	# ユーザー提示の食事効果なしbeforeと同じ密度で、余白再配分だけを比較する固定seed。
	PlayerProgress.level = level_override if level_override > 0 else 30
	PlayerProgress.exp = 0
	PlayerProgress.money = 50080
	PlayerProgress.inventory = {"aji": 5, "iwashi": 5, "madai": 3, "hirame": 2, "kihada": 1, "kasago": 4}
	PlayerProgress.equipped_rod_id = "big_game"
	PlayerProgress.play_seconds = 3220.0
	PlayerProgress.owned_boats = ["bluewater_boat"]
	PlayerProgress.sea_chart_fragments = 3
	PlayerProgress.eaten_recipes = {"shioyaki": 1}
	PlayerProgress.quest_board = [
		{"kind": "delivery", "fish_id": "sappa", "count": 99, "reward_money": 500, "text": "サッパを届ける"},
		{"kind": "delivery", "fish_id": "mejina", "count": 99, "reward_money": 500, "text": "メジナを届ける"},
		{"kind": "delivery", "fish_id": "murasoi", "count": 99, "reward_money": 500, "text": "ムラソイを届ける"},
	]
	PlayerProgress.caught_counts = {"nekozame": 1}
	_fix_rumor_to_single_harbor_nushi("nushi_outer_tide")
	PlayerProgress.shark_bonds = {}
	var time_slot_id := OS.get_environment("TSURI_HARBOR_TIME_SLOT_ID").strip_edges()
	if not time_slot_id.is_empty() and GameData.is_time_slot_unlocked(time_slot_id, PlayerProgress.level):
		PlayerProgress.selected_time_slot_id = time_slot_id
	else:
		PlayerProgress.selected_time_slot_id = GameData.DEFAULT_TIME_SLOT_ID
	PlayerProgress.pending_buff = {}


func _fix_rumor_to_single_harbor_nushi(rumor_override := "") -> void:
	# 保存済みbeforeと時間帯ごとの目撃談まで一致させ、比較文言を決定的にする。
	var time_slot_id := OS.get_environment("TSURI_HARBOR_TIME_SLOT_ID").strip_edges()
	var rumor_nushi_id := rumor_override
	if rumor_nushi_id.is_empty():
		rumor_nushi_id = "nushi_bluewater_route"
		if time_slot_id == "asa_mazume":
			rumor_nushi_id = "nushi_shallow_sand"
		elif time_slot_id == "night":
			rumor_nushi_id = "nushi_outer_tide"
	PlayerProgress.caught_counts.erase(rumor_nushi_id)
	for spot_id in GameData.NORMAL_FISHING_SPOT_IDS:
		var nushi: Dictionary = GameData.get_fishing_spot(spot_id).get("nushi", {})
		var nushi_id := String(nushi.get("fish_id", ""))
		if not nushi_id.is_empty() and nushi_id != rumor_nushi_id:
			PlayerProgress.caught_counts[nushi_id] = 1
