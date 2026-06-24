extends Control
## 釣り画面（水上キャストビュー）のキャプチャツール（SubViewport オフスクリーン描画）。
# READY 状態で水上ビュー（空・海・桟橋・釣り人・浮標）が表示されることを確認する。
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const FishingScreen = preload("res://src/ui/fishing_screen.gd")
const OUT := "/tmp/tsuri_fishing.png"
const VW := Vector2i(1280, 720)


func _ready() -> void:
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

	# _process で modulate（水上 a=1／水中 a=0）が整うまで待つ
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout

	var img := vp.get_texture().get_image()
	img.save_png(OUT)
	get_tree().quit()
