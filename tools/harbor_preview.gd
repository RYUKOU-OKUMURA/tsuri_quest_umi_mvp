extends Control
## 港メニューの実画面キャプチャ用ツール。

const HarborScreenScript = preload("res://src/ui/harbor_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const DEFAULT_OUT := "/tmp/tsuri_harbor_screen.png"


func _ready() -> void:
	theme = ThemeFactory.build_theme()
	_setup_preview_progress()
	var screen := HarborScreenScript.new()
	screen.configure({})
	add_child(screen)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.35).timeout
	var img := get_viewport().get_texture().get_image()
	var out := OS.get_environment("TSURI_HARBOR_OUT").strip_edges()
	if out.is_empty():
		out = DEFAULT_OUT
	img.save_png(out)
	print(out)
	get_tree().quit()


func _setup_preview_progress() -> void:
	var level_override := int(OS.get_environment("TSURI_HARBOR_LEVEL"))
	if OS.get_environment("TSURI_HARBOR_SEED") == "legacy_compare":
		_setup_legacy_compare_progress(level_override)
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


func _fix_rumor_to_single_harbor_nushi() -> void:
	# 保存済みbeforeと時間帯ごとの目撃談まで一致させ、比較文言を決定的にする。
	var time_slot_id := OS.get_environment("TSURI_HARBOR_TIME_SLOT_ID").strip_edges()
	var rumor_nushi_id := "nushi_bluewater_route"
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
