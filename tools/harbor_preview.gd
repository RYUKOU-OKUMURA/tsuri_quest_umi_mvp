extends Control
## 港メニューの実画面キャプチャ用ツール。

const HarborScreenScript = preload("res://src/ui/harbor_screen.gd")
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const OUT := "/tmp/tsuri_harbor_screen.png"


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
	img.save_png(OUT)
	print(OUT)
	get_tree().quit()


func _setup_preview_progress() -> void:
	PlayerProgress.level = 8
	PlayerProgress.exp = 306
	PlayerProgress.money = 12450
	PlayerProgress.inventory = {"aji": 2, "mejina": 1, "saba": 2, "madai": 1, "hirame": 1}
	PlayerProgress.equipped_rod_id = "offshore"
	PlayerProgress.play_seconds = 22441.0
	PlayerProgress.pending_buff = {
		"name": "カサゴの塩焼き",
		"text": "次の釣行で最大体力 +5%",
	}
