class_name UITextures
extends RefCounted
## 9スライス ウィンドウスキンをコードで procedural 生成。
## アート未着手でも「JRPG装飾枠」を実現し、後で PNG に差し替え可能。
## 64x64、外周に焼き込み影・ベベル・金縁・角の鋲。texture_margin = MARGIN で9スライス。

const SIZE := 64
const MARGIN := 10          # texture_margin（9スライスの枠幅）
const SHADOW_ALPHA := 0.34

static var _cache := {}
static var _icon_cache := {}

static func _config(variant: String) -> Dictionary:
	match variant:
		"dark":
			return {"fill": Palette.DARK_PANEL, "outer": Palette.DARK_PANEL_DEEP, "inner": Palette.GOLD, "stud": Palette.GOLD_BRIGHT}
		"blue":
			return {"fill": Palette.BLUE_PANEL, "outer": Color("#0e2a45"), "inner": Palette.GOLD, "stud": Palette.GOLD_BRIGHT}
		"dialog":
			return {"fill": Palette.DARK_PANEL, "outer": Palette.GOLD_DEEP, "inner": Palette.GOLD_BRIGHT, "stud": Palette.GOLD}
		"button_normal":
			return {"fill": Palette.WOOD, "outer": Palette.WOOD_DARK, "inner": Palette.GOLD, "stud": Palette.GOLD_BRIGHT}
		"button_hover":
			return {"fill": Palette.WOOD_HOVER, "outer": Palette.WOOD_DARK, "inner": Palette.GOLD_BRIGHT, "stud": Color.WHITE}
		"button_pressed":
			return {"fill": Palette.WOOD_PRESSED, "outer": Color("#3a2410"), "inner": Color("#d29a4f"), "stud": Palette.GOLD}
		"button_gold":
			return {"fill": Palette.GOLD, "outer": Palette.GOLD_DEEP, "inner": Palette.GOLD_BRIGHT, "stud": Color.WHITE}
		_:  # parchment (default)
			return {"fill": Palette.PARCHMENT, "outer": Palette.WOOD_DARK, "inner": Palette.GOLD, "stud": Palette.GOLD_BRIGHT}


static func get_skin(variant: String) -> ImageTexture:
	if _cache.has(variant):
		return _cache[variant]
	var cfg := _config(variant)
	var img := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))
	var content := Rect2i(MARGIN, MARGIN, SIZE - MARGIN * 2, SIZE - MARGIN * 2)
	_draw_shadow(img, content)
	img.fill_rect(content, cfg.fill)
	_bevel(img, content, cfg.fill)
	_rect_outline(img, content, cfg.inner, 1)
	var frame := content.grow(3)
	_rect_outline(img, frame, cfg.outer, 2)
	for corner in [Vector2i(MARGIN - 2, MARGIN - 2), Vector2i(SIZE - MARGIN - 1, MARGIN - 2), Vector2i(MARGIN - 2, SIZE - MARGIN - 1), Vector2i(SIZE - MARGIN - 1, SIZE - MARGIN - 1)]:
		_stud(img, corner, cfg.stud)
	var tex := ImageTexture.create_from_image(img)
	_cache[variant] = tex
	return tex


# content の外側に MARGIN 幅の焼き込み影（外側へ薄くなる）。
static func _draw_shadow(img: Image, content: Rect2i) -> void:
	for i in range(1, MARGIN + 1):
		var r := content.grow(i)
		var a := SHADOW_ALPHA * (1.0 - float(i) / float(MARGIN + 1))
		_rect_outline(img, r, Color(0.0, 0.0, 0.0, a), 1)


static func _bevel(img: Image, content: Rect2i, fill: Color) -> void:
	var hi := fill.lightened(0.10)
	var lo := fill.darkened(0.12)
	img.fill_rect(Rect2i(content.position.x, content.position.y, content.size.x, 2), hi)
	img.fill_rect(Rect2i(content.position.x, content.position.y, 2, content.size.y), hi)
	img.fill_rect(Rect2i(content.position.x, content.position.y + content.size.y - 2, content.size.x, 2), lo)
	img.fill_rect(Rect2i(content.position.x + content.size.x - 2, content.position.y, 2, content.size.y), lo)


# Rect2i の縁を幅 w で塗る（上下左右の帯）。
static func _rect_outline(img: Image, r: Rect2i, color: Color, w: int) -> void:
	var x0 := maxi(r.position.x, 0)
	var y0 := maxi(r.position.y, 0)
	var x1 := mini(r.position.x + r.size.x, SIZE)
	var y1 := mini(r.position.y + r.size.y, SIZE)
	if x1 <= x0 or y1 <= y0:
		return
	img.fill_rect(Rect2i(x0, y0, x1 - x0, w), color)
	img.fill_rect(Rect2i(x0, y1 - w, x1 - x0, w), color)
	img.fill_rect(Rect2i(x0, y0, w, y1 - y0), color)
	img.fill_rect(Rect2i(x1 - w, y0, w, y1 - y0), color)


static func _stud(img: Image, center: Vector2i, color: Color) -> void:
	img.fill_rect(Rect2i(center.x - 1, center.y - 1, 3, 3), color)


# ── 装飾なしのシンプルな角丸 StyleBoxFlat（ゲージ背景等の細部用） ──
static func flat_style(background: Color, border: Color, width: int, radius: int, shadow: bool = false, shadow_size: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10.0
	style.content_margin_top = 8.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 8.0
	if shadow and shadow_size > 0:
		style.shadow_color = Palette.SHADOW
		style.shadow_size = shadow_size
		style.shadow_offset = Vector2(0.0, maxf(float(shadow_size) * 0.45, 3.0))
	return style


# ── 魚図鑑アイコン（procedural）。色1つから楕円魚を生成しキャッシュする。 ──
static func get_fish_icon(color: Color) -> ImageTexture:
	if _icon_cache.has(color):
		return _icon_cache[color]
	var img := Image.create_empty(64, 36, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))
	var dark := color.darkened(0.42)
	var light := color.lightened(0.32)
	_fill_ellipse(img, 10, 18, 6, 13, dark)   # 尾（縦長）
	_fill_ellipse(img, 36, 18, 28, 14, dark)  # 輪郭
	_fill_ellipse(img, 36, 18, 26, 12, color) # 胴
	_fill_ellipse(img, 32, 6, 6, 4, dark)     # 背びれ
	_fill_ellipse(img, 38, 23, 18, 4, Color(light.r, light.g, light.b, 0.55))  # 腹ハイライト
	_set_px(img, 50, 14, Color(1.0, 1.0, 1.0, 1.0))
	_set_px(img, 51, 14, Color(1.0, 1.0, 1.0, 1.0))
	_set_px(img, 50, 15, Color(0.05, 0.05, 0.05, 1.0))
	var tex := ImageTexture.create_from_image(img)
	_icon_cache[color] = tex
	return tex


static func _fill_ellipse(img: Image, cx: int, cy: int, rx: float, ry: float, color: Color) -> void:
	for y in range(cy - int(ry) - 1, cy + int(ry) + 2):
		for x in range(cx - int(rx) - 1, cx + int(rx) + 2):
			var dx := (float(x) - float(cx)) / rx
			var dy := (float(y) - float(cy)) / ry
			if dx * dx + dy * dy <= 1.0:
				_set_px(img, x, y, color)


static func _set_px(img: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
		return
	if color.a >= 0.999:
		img.set_pixel(x, y, color)
		return
	var bg := img.get_pixel(x, y)
	var a := color.a
	img.set_pixel(
		x,
		y,
		Color(
			lerpf(bg.r, color.r, a),
			lerpf(bg.g, color.g, a),
			lerpf(bg.b, color.b, a),
			minf(bg.a + a * (1.0 - bg.a), 1.0)
		)
	)
