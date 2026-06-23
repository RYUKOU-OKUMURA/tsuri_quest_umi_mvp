extends Control
## 実画面のキャプチャ用ツール。TargetScreen を差し替えて各画面をPNG保存する。
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const TargetScreen = preload("res://src/ui/title_screen.gd")
const OUT := "/tmp/tsuri_screen.png"


func _ready() -> void:
	theme = ThemeFactory.build_theme()
	var s := TargetScreen.new()
	s.configure({})
	add_child(s)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png(OUT)
	get_tree().quit()
