extends Control
## 一時的なテーマ確認ツール。枠/ボタン/フォント/ゲージを描画しPNG保存して終了。
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const GaugeBarScript = preload("res://src/ui/components/gauge_bar.gd")


func _ready() -> void:
	theme = ThemeFactory.build_theme()
	_bg()
	# 羊皮紙パネル + ボタン
	var p := PanelContainer.new()
	p.position = Vector2(120, 120)
	p.size = Vector2(440, 300)
	add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	p.add_child(vb)
	var t := Label.new()
	t.text = "釣りクエスト ～海釣り編～"
	t.add_theme_font_size_override("font_size", 28)
	vb.add_child(t)
	var b := Label.new()
	b.text = "水中ファイト／調理／図鑑"
	vb.add_child(b)
	var btn := Button.new()
	btn.text = "港へ出発する"
	vb.add_child(btn)
	var gold := Button.new()
	gold.theme_type_variation = "GoldButton"
	gold.text = "仕掛けを投げる"
	vb.add_child(gold)
	# ダークパネル（ヘッダ）
	var d := PanelContainer.new()
	d.theme_type_variation = "DarkPanel"
	d.position = Vector2(600, 120)
	d.size = Vector2(380, 120)
	add_child(d)
	var dl := Label.new()
	dl.text = "南の島・沖　水中ファイト"
	dl.add_theme_color_override("font_color", Palette.TEXT_BONE)
	d.add_theme_font_size_override("font_size", 24)
	d.add_child(dl)
	# ゲージ3種（緑=安全, 黄=警戒, 赤=危険＋ゴースト）
	var g1 := GaugeBarScript.new()
	g1.position = Vector2(120, 460)
	g1.size = Vector2(440, 34)
	g1.set_colors(Palette.GAUGE_GREEN, Palette.GAUGE_GREEN_HI)
	add_child(g1)
	var g2 := GaugeBarScript.new()
	g2.position = Vector2(120, 510)
	g2.size = Vector2(440, 34)
	g2.set_colors(Palette.GAUGE_AMBER, Palette.GAUGE_AMBER_HI)
	add_child(g2)
	var g3 := GaugeBarScript.new()
	g3.position = Vector2(120, 560)
	g3.size = Vector2(440, 34)
	g3.set_colors(Palette.GAUGE_RED, Palette.GAUGE_RED_HI)
	add_child(g3)
	await get_tree().process_frame
	await get_tree().process_frame
	g1.set_ratio(0.74)
	g2.set_ratio(0.45)
	g3.set_ratio(1.0)
	await get_tree().process_frame
	await get_tree().process_frame
	g3.set_ratio(0.18)   # 危険域 + ゴースト
	await get_tree().process_frame
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png("/tmp/tsuri_theme_preview.png")
	get_tree().quit()


func _bg() -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, Palette.SKY_TOP)
	gradient.set_color(1, Palette.SEA_DEEP)
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill_from = Vector2(0.0, 0.0)
	tex.fill_to = Vector2(0.0, 1.0)
	tex.width = 64
	tex.height = 64
	var bg := TextureRect.new()
	bg.texture = tex
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
