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
	PlayerProgress.level = level_override if level_override > 0 else 20
	PlayerProgress.exp = 306
	PlayerProgress.money = 12450
	PlayerProgress.inventory = {"aji": 2, "mejina": 1, "saba": 2, "madai": 1, "hirame": 1}
	PlayerProgress.equipped_rod_id = "offshore"
	PlayerProgress.play_seconds = 22441.0
	var time_slot_id := OS.get_environment("TSURI_HARBOR_TIME_SLOT_ID").strip_edges()
	if not time_slot_id.is_empty() and GameData.is_time_slot_unlocked(time_slot_id, PlayerProgress.level):
		PlayerProgress.selected_time_slot_id = time_slot_id
	else:
		PlayerProgress.selected_time_slot_id = GameData.DEFAULT_TIME_SLOT_ID
	PlayerProgress.pending_buff = {
		"name": "カサゴの塩焼き",
		"text": "次の釣行で最大体力 +5%",
	}
