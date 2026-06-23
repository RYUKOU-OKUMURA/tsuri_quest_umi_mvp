extends Control
## 9スライススキン各変体の描画検証（ピクセルサンプリングで確定）。
# host.theme を設定し、各 panel/button が金縁／金塗りを含むかをピクセル距離で判定して印字。
# analyze_image の判断揺れを排除するため、画像解析ではなく実ピクセル値で検証する。
const ThemeFactory = preload("res://src/ui/ui_theme.gd")
const OUT := "/tmp/tsuri_skins.png"
const VW := Vector2i(1000, 560)


func _ready() -> void:
	var vp := SubViewport.new()
	vp.size = VW
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var host := Control.new()
	host.theme = ThemeFactory.build_theme()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.size = Vector2(VW)
	vp.add_child(host)

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 16)
	host.add_child(col)

	var nodes: Array = []
	for v in ["default", "DarkPanel", "JRPGDialog"]:
		var p := PanelContainer.new()
		p.name = "panel_" + v
		if v != "default":
			p.theme_type_variation = v
		p.custom_minimum_size = Vector2(460, 64)
		var l := Label.new()
		l.text = "  %s" % v
		p.add_child(l)
		col.add_child(p)
		nodes.append(p)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	col.add_child(row)
	for cfg in [["Normal", ""], ["GoldButton", "GoldButton"]]:
		var b := Button.new()
		b.name = "btn_" + cfg[0]
		b.text = cfg[0]
		if cfg[1] != "":
			b.theme_type_variation = cfg[1]
		b.custom_minimum_size = Vector2(210, 58)
		row.add_child(b)
		nodes.append(b)

	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout

	var img := vp.get_texture().get_image()
	img.save_png(OUT)

	# 各ノード矩形内の「金色みピクセル」数と最も明るい赤成分を印字
	var gold := Vector3(Palette.GOLD.r, Palette.GOLD.g, Palette.GOLD.b)
	var gold_deep := Vector3(Palette.GOLD_DEEP.r, Palette.GOLD_DEEP.g, Palette.GOLD_DEEP.b)
	var gold_bright := Vector3(Palette.GOLD_BRIGHT.r, Palette.GOLD_BRIGHT.g, Palette.GOLD_BRIGHT.b)
	for node in nodes:
		var ctrl := node as Control
		var r: Rect2 = ctrl.get_global_rect()
		var hits := 0
		var brightest := 0.0
		for yi in range(int(r.position.y), int(r.position.y + r.size.y), 2):
			for xi in range(int(r.position.x), int(r.position.x + r.size.x), 2):
				if xi < 0 or yi < 0 or xi >= VW.x or yi >= VW.y:
					continue
				var px: Color = img.get_pixel(xi, yi)
				brightest = maxf(brightest, px.r)
				var v := Vector3(px.r, px.g, px.b)
				if (
					v.distance_to(gold) < 0.22
					or v.distance_to(gold_deep) < 0.22
					or v.distance_to(gold_bright) < 0.22
				):
					hits += 1
		print("NODE=%-22s rect=[%d,%d,%d,%d] goldish=%d brightest_r=%.2f" % [ctrl.name, int(r.position.x), int(r.position.y), int(r.size.x), int(r.size.y), hits, brightest])

	get_tree().quit()
