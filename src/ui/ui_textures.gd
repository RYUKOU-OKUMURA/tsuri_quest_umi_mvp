class_name UITextures
extends RefCounted
## 装飾なし StyleBoxFlat と procedural 魚アイコン生成。

static var _icon_cache := {}


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
	img.fill(Color.TRANSPARENT)
	var dark := color.darkened(0.42)
	var light := color.lightened(0.32)
	_fill_ellipse(img, 10, 18, 6, 13, dark)   # 尾（縦長）
	_fill_ellipse(img, 36, 18, 28, 14, dark)  # 輪郭
	_fill_ellipse(img, 36, 18, 26, 12, color) # 胴
	_fill_ellipse(img, 32, 6, 6, 4, dark)     # 背びれ
	_fill_ellipse(img, 38, 23, 18, 4, Color(light.r, light.g, light.b, 0.55))  # 腹ハイライト
	_set_px(img, 50, 14, Color.WHITE)
	_set_px(img, 51, 14, Color.WHITE)
	_set_px(img, 50, 15, Palette.UI_FISH_ICON_EYE_DARK)
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
