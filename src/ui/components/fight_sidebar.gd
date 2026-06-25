class_name FightSidebar
extends Control
## 水中ファイト看板画面の右サイドバー。
# 魚カード、行動カード、タックルカードをまとめて描画し、参照画像の情報密度に寄せる。

const FightFontsScript = preload("res://src/ui/fight_fonts.gd")
const FISH_SHEET_PATH := "res://assets/showcase/underwater/kurodai_showcase_sheet.png"
const FISH_CARD_PORTRAIT_PATH := "res://assets/showcase/underwater/kurodai_card_portrait.png"
const SIDEBAR_FRAME_PATH := "res://assets/showcase/underwater/sidebar_frame.png"
const ICON_SHEET_PATH := "res://assets/showcase/underwater/fight_icon_sheet.png"
const ACTION_CARD_ICON_PATH := "res://assets/showcase/underwater/fight_action_card_icon.png"
const TACKLE_CARD_ICON_PATH := "res://assets/showcase/underwater/fight_tackle_card_icon.png"
const FISH_FRAME_COUNT := 4
const ICON_ACTION := 7
const ICON_TACKLE := 8

var simulator: FishingSimulator
var fish_data: Dictionary = {}
var trip_stats: Dictionary = {}

var _fish_sheet: Texture2D
var _fish_card_portrait: Texture2D
var _sidebar_frame: Texture2D
var _icons: Texture2D
var _action_card_icon: Texture2D
var _tackle_card_icon: Texture2D


func bind(value: FishingSimulator, fish: Dictionary, stats: Dictionary) -> void:
	simulator = value
	fish_data = fish.duplicate(true)
	trip_stats = stats.duplicate(true)
	queue_redraw()


func set_fish(fish: Dictionary, stats: Dictionary) -> void:
	fish_data = fish.duplicate(true)
	trip_stats = stats.duplicate(true)
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(FISH_SHEET_PATH):
		_fish_sheet = load(FISH_SHEET_PATH) as Texture2D
	if ResourceLoader.exists(FISH_CARD_PORTRAIT_PATH):
		_fish_card_portrait = load(FISH_CARD_PORTRAIT_PATH) as Texture2D
	if ResourceLoader.exists(SIDEBAR_FRAME_PATH):
		_sidebar_frame = load(SIDEBAR_FRAME_PATH) as Texture2D
	if ResourceLoader.exists(ICON_SHEET_PATH):
		_icons = load(ICON_SHEET_PATH) as Texture2D
	if ResourceLoader.exists(ACTION_CARD_ICON_PATH):
		_action_card_icon = load(ACTION_CARD_ICON_PATH) as Texture2D
	if ResourceLoader.exists(TACKLE_CARD_ICON_PATH):
		_tackle_card_icon = load(TACKLE_CARD_ICON_PATH) as Texture2D


func _process(_delta: float) -> void:
	if simulator != null:
		queue_redraw()


func _draw() -> void:
	var font := FightFontsScript.bold(get_theme_default_font())
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return

	var header := Rect2(0.0, 0.0, w, 30.0)
	var fish_card := Rect2()
	var action_card := Rect2()
	var tackle_card := Rect2()
	if _sidebar_frame != null:
		draw_texture_rect(_sidebar_frame, Rect2(Vector2.ZERO, size), false, Color.WHITE)
		header = Rect2(w * 0.055, h * 0.030, w * 0.89, h * 0.075)
		fish_card = Rect2(w * 0.060, h * 0.125, w * 0.88, h * 0.440)
		action_card = Rect2(w * 0.055, h * 0.600, w * 0.89, h * 0.190)
		tackle_card = Rect2(w * 0.055, h * 0.810, w * 0.89, h * 0.165)
	else:
		var gap := 7.0
		var action_h := clampf(h * 0.22, 86.0, 102.0)
		var tackle_h := clampf(h * 0.24, 92.0, 112.0)
		var fish_h := maxf(170.0, h - header.size.y - action_h - tackle_h - gap * 3.0)
		fish_card = Rect2(0.0, header.end.y + gap, w, fish_h)
		action_card = Rect2(0.0, fish_card.end.y + gap, w, action_h)
		tackle_card = Rect2(0.0, action_card.end.y + gap, w, tackle_h)

	_draw_header(font, header)
	_draw_fish_card(font, fish_card)
	_draw_action_card(font, action_card)
	_draw_tackle_card(font, tackle_card)


func _draw_header(font: Font, rect: Rect2) -> void:
	_draw_panel(rect, Palette.DARK_PANEL, Palette.GOLD, Palette.GOLD_BRIGHT)
	var title_size := 18 if _sidebar_frame == null else 19
	_draw_text(font, "釣り中の魚", rect.position + Vector2(14.0, rect.size.y * 0.68), title_size, Palette.TEXT_BONE, 3)
	_draw_text(font, "1/1匹", rect.position + Vector2(rect.size.x - 66.0, rect.size.y * 0.68), 16, Palette.GOLD_BRIGHT, 2)


func _draw_fish_card(font: Font, rect: Rect2) -> void:
	_draw_panel(rect, Palette.PARCHMENT, Palette.WOOD_DARK, Palette.GOLD)
	var compact_card := _sidebar_frame != null or rect.size.y <= 300.0
	var inner := rect.grow(-10.0 if _sidebar_frame == null else -12.0)
	var fish_name := String(fish_data.get("name", "クロダイ"))
	var rarity := String(fish_data.get("rarity", "レア"))
	var no_text := "No.028"
	if compact_card:
		_draw_paper_plaque(Rect2(inner.position + Vector2(2.0, 6.0), Vector2(inner.size.x - 4.0, 34.0)))
		_draw_text(font, no_text, inner.position + Vector2(10.0, 28.0), 14, Color("#6b6153"), 0)
		_draw_text(font, _display_fish_name(fish_name), inner.position + Vector2(92.0, 29.0), 21, Palette.TEXT_DARK, 0)
		_draw_rarity_tag(font, Rect2(inner.position + Vector2(inner.size.x - 58.0, 11.0), Vector2(50.0, 22.0)), rarity)
	else:
		_draw_text(font, no_text, inner.position + Vector2(0.0, 26.0), 14, Color("#6b6153"), 0)
		_draw_text(font, _display_fish_name(fish_name), inner.position + Vector2(74.0, 28.0), 20, Palette.TEXT_DARK, 0)
		_draw_rarity_tag(font, Rect2(inner.position + Vector2(inner.size.x - 52.0, 8.0), Vector2(48.0, 22.0)), rarity)

	var fish_rect := Rect2(
		inner.position + Vector2(6.0, 52.0 if compact_card else 46.0),
		Vector2(
			inner.size.x - 12.0,
			maxf(82.0, rect.size.y * (0.46 if compact_card else 0.37))
		)
	)
	_draw_fish_portrait(fish_rect)
	var divider_y := fish_rect.end.y + (6.0 if _sidebar_frame != null else 6.0)
	draw_line(Vector2(inner.position.x + 8.0, divider_y), Vector2(inner.end.x - 8.0, divider_y), Color("#c9b486"), 1.0)
	var estimate := (float(fish_data.get("size_min", 0.0)) + float(fish_data.get("size_max", 0.0))) * 0.5
	var estimate_size := 21 if _sidebar_frame != null else 23
	_draw_centered_text(font, "推定 %.1f cm" % estimate, Rect2(inner.position.x, divider_y + 8.0, inner.size.x, 30.0), estimate_size, Color("#2b2117"), 0)
	var desc_y := divider_y + (49.0 if compact_card else 44.0)
	draw_line(Vector2(inner.position.x + 8.0, desc_y - 10.0), Vector2(inner.end.x - 8.0, desc_y - 10.0), Color("#d6c299"), 1.0)
	var detail_gap := 16.0 if compact_card else 21.0
	var detail_font := get_theme_default_font()
	_draw_detail_line(detail_font, "岩場周りで警戒心が強い。", Vector2(inner.position.x + 15.0, desc_y), inner.size.x - 26.0)
	_draw_detail_line(detail_font, "エサ：オキアミ・カニ", Vector2(inner.position.x + 15.0, desc_y + detail_gap), inner.size.x - 26.0)
	if _sidebar_frame == null:
		_draw_detail_line(detail_font, "生息域：沿岸の岩場・堤防周り", Vector2(inner.position.x + 16.0, desc_y + detail_gap * 2.0), inner.size.x - 28.0)



func _draw_action_card(font: Font, rect: Rect2) -> void:
	_draw_panel(rect, Color("#0d3a62"), Palette.GOLD, Palette.GOLD_BRIGHT)
	_draw_text(font, "魚の行動", rect.position + Vector2(16.0, 25.0), 19 if _sidebar_frame != null else 18, Palette.TEXT_BONE, 3)
	var body := Rect2(rect.position + Vector2(10.0, 33.0), rect.size - Vector2(20.0, 42.0))
	if _sidebar_frame != null:
		body = Rect2(rect.position + Vector2(14.0, rect.size.y * 0.225), rect.size - Vector2(28.0, rect.size.y * 0.285))
	else:
		_draw_panel(body, Color("#f3e8cd"), Palette.WOOD_DARK, Palette.GOLD)
	var action := "待機"
	var message := "ラインを見ながら、テンションを保とう。"
	if simulator != null:
		action = simulator.action_name
		message = simulator.action_message
	var icon_size := 42.0 if _sidebar_frame != null else 58.0
	var text_x := 62.0 if _sidebar_frame != null else 78.0
	if _sidebar_frame != null:
		icon_size = 56.0
		text_x = 78.0
	_draw_action_icon(body.position + Vector2(33.0, body.size.y * 0.57), icon_size)
	_draw_text(font, "%s！" % action, body.position + Vector2(text_x, 34.0), 25 if _sidebar_frame != null else 20, Color("#2b2117"), 0)
	if _sidebar_frame != null:
		_draw_action_message(font, message, body.position + Vector2(text_x, 47.0), body.size.x - text_x - 6.0)
	else:
		_draw_wrapped(font, message, body.position + Vector2(72.0, 36.0), body.size.x - 82.0, 11, Palette.TEXT_DARK, 2)


func _draw_tackle_card(font: Font, rect: Rect2) -> void:
	_draw_panel(rect, Color("#0d3a62"), Palette.GOLD, Palette.GOLD_BRIGHT)
	_draw_text(font, "タックル", rect.position + Vector2(14.0, 24.0), 19 if _sidebar_frame != null else 18, Palette.TEXT_BONE, 3)
	var body := Rect2(rect.position + Vector2(10.0, 32.0), rect.size - Vector2(20.0, 38.0))
	if _sidebar_frame != null:
		body = Rect2(rect.position + Vector2(14.0, rect.size.y * 0.225), rect.size - Vector2(28.0, rect.size.y * 0.285))
	else:
		_draw_panel(body, Palette.PARCHMENT, Palette.WOOD_DARK, Palette.GOLD)
	var rod_name := _short_rod_name(String(trip_stats.get("rod_name", "港の入門竿")))
	var has_tackle_icon := _tackle_card_icon != null or _icons != null
	var icon_reserved_width := 12.0
	if has_tackle_icon:
		icon_reserved_width = 66.0
	var text_offset := Vector2(14.0, 22.0) if _sidebar_frame != null else Vector2(12.0, 14.0)
	var text_width := body.size.x - icon_reserved_width - text_offset.x
	var lines: Array[String] = [
		"ロッド：%s" % rod_name,
		"糸3号・チヌ針",
	]
	var tackle_font_size := 20 if _sidebar_frame != null else 12
	var tackle_line_gap := 24.0 if _sidebar_frame != null else 16.0
	for i in range(lines.size()):
		_draw_wrapped(font, lines[i], body.position + text_offset + Vector2(0.0, float(i) * tackle_line_gap), text_width, tackle_font_size, Palette.TEXT_DARK, 1, tackle_font_size + 3.0)
	if _tackle_card_icon != null or _icons != null:
		var icon_rect := Rect2(body.end - Vector2(94.0, 76.0), Vector2(88.0, 70.0)) if _sidebar_frame != null else Rect2(body.end - Vector2(50.0, 50.0), Vector2(40.0, 40.0))
		_draw_tackle_icon(icon_rect)
	else:
		_draw_simple_rod(body.position + Vector2(body.size.x - 62.0, body.size.y - 24.0))


func _draw_panel(rect: Rect2, fill: Color, border: Color, highlight: Color) -> void:
	if _sidebar_frame != null:
		return
	draw_rect(rect, Color(0.0, 0.0, 0.0, 0.28), true)
	draw_rect(rect.grow(-3.0), fill, true)
	draw_rect(rect.grow(-3.0), border, false, 2.0)
	draw_rect(rect.grow(-6.0), Color(highlight.r, highlight.g, highlight.b, 0.55), false, 1.0)
	for corner in [
		rect.position + Vector2(8.0, 8.0),
		rect.position + Vector2(rect.size.x - 9.0, 8.0),
		rect.position + Vector2(8.0, rect.size.y - 9.0),
		rect.position + Vector2(rect.size.x - 9.0, rect.size.y - 9.0),
	]:
		draw_rect(Rect2(corner - Vector2(2.0, 2.0), Vector2(4.0, 4.0)), Palette.GOLD_BRIGHT, true)


func _draw_paper_plaque(rect: Rect2) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#fff3d7")
	style.border_color = Color("#b89b64")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.shadow_color = Color(0.24, 0.14, 0.05, 0.18)
	style.shadow_size = 2
	draw_style_box(style, rect)
	draw_line(rect.position + Vector2(10.0, 8.0), Vector2(rect.end.x - 10.0, rect.position.y + 8.0), Color(1.0, 1.0, 1.0, 0.45), 1.0)


func _draw_text(font: Font, text: String, baseline: Vector2, font_size: int, color: Color, outline: int) -> void:
	if outline > 0:
		draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline, Color(0.0, 0.0, 0.0, 0.65))
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw_centered_text(font: Font, text: String, rect: Rect2, font_size: int, color: Color, outline: int) -> void:
	var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_draw_text(font, text, rect.position + Vector2((rect.size.x - text_width) * 0.5, font_size), font_size, color, outline)


func _draw_wrapped(
	font: Font,
	text: String,
	pos: Vector2,
	max_width: float,
	font_size: int,
	color: Color,
	max_lines: int,
	line_gap: float = -1.0
) -> void:
	var line := ""
	var lines: Array[String] = []
	var closing_marks := "、。！？…）」』"
	for i in range(text.length()):
		var char := text[i]
		var next := line + char
		if font.get_string_size(next, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > max_width and not line.is_empty():
			if closing_marks.contains(char):
				lines.append(next)
				line = ""
			else:
				lines.append(line)
				line = char
		else:
			line = next
	if not line.is_empty():
		lines.append(line)
	var count := mini(lines.size(), max_lines)
	var gap := line_gap if line_gap > 0.0 else float(font_size + 5)
	for i in range(count):
		_draw_text(font, lines[i], pos + Vector2(0.0, float(i) * gap + float(font_size)), font_size, color, 0)


func _draw_action_message(font: Font, text: String, pos: Vector2, max_width: float) -> void:
	var first_stop := text.find("！")
	var font_size := 16 if _sidebar_frame != null else 13
	var gap := 16.0 if _sidebar_frame != null else 16.0
	if first_stop > 0 and first_stop < text.length() - 1:
		var first := text.left(first_stop + 1)
		var second := text.substr(first_stop + 1)
		_draw_wrapped(font, first, pos, max_width, font_size, Palette.TEXT_DARK, 1, gap)
		_draw_wrapped(font, second, pos + Vector2(0.0, gap), max_width, font_size, Palette.TEXT_DARK, 1, gap)
		return
	_draw_wrapped(font, text, pos, max_width, font_size, Palette.TEXT_DARK, 2, gap)


func _draw_bullet(font: Font, text: String, pos: Vector2, max_width: float) -> void:
	draw_circle(pos + Vector2(2.0, -3.0), 4.0, Color("#49c75a"))
	_draw_wrapped(font, text, pos + Vector2(14.0, -15.0), max_width - 14.0, 13, Palette.TEXT_DARK, 1)


func _draw_detail_line(font: Font, text: String, pos: Vector2, max_width: float) -> void:
	draw_circle(pos + Vector2(3.0, 10.0), 4.3, Color("#49c75a"))
	var font_size := 14
	if _sidebar_frame != null:
		font_size = 14
	elif max_width < 260.0:
		font_size = 13
	_draw_wrapped(font, text, pos + Vector2(15.0, -1.0), max_width - 15.0, font_size, Palette.TEXT_DARK, 1)


func _draw_rarity_tag(font: Font, rect: Rect2, rarity: String) -> void:
	draw_rect(rect, Color("#8e4f77"), true)
	draw_rect(rect, Color("#e7b4d1"), false, 1.0)
	var text_width := font.get_string_size(rarity, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	_draw_text(font, rarity, rect.position + Vector2((rect.size.x - text_width) * 0.5, 17.0), 13, Color.WHITE, 1)


func _draw_fish_portrait(rect: Rect2) -> void:
	if _fish_card_portrait != null:
		var tex_size := _fish_card_portrait.get_size()
		var scale := minf(rect.size.x / tex_size.x, rect.size.y / tex_size.y)
		var draw_size := tex_size * scale
		var draw_rect := Rect2(rect.position + (rect.size - draw_size) * 0.5, draw_size)
		draw_texture_rect(_fish_card_portrait, draw_rect, false, Color.WHITE)
		return
	if _fish_sheet == null:
		var color := Color.from_string(String(fish_data.get("color", "#394956")), Color("#394956"))
		draw_texture_rect(UITextures.get_fish_icon(color), rect, false)
		return
	var frame_w := float(_fish_sheet.get_width()) / float(FISH_FRAME_COUNT)
	var frame_h := float(_fish_sheet.get_height())
	var src := Rect2(36.0, 45.0, frame_w - 73.0, frame_h - 50.0)
	var tex_size := src.size
	var scale := minf(rect.size.x / tex_size.x, rect.size.y / tex_size.y)
	var draw_size := tex_size * scale
	var draw_rect := Rect2(rect.position + (rect.size - draw_size) * 0.5, draw_size)
	draw_texture_rect_region(_fish_sheet, draw_rect, src, Color.WHITE)


func _draw_action_icon(center: Vector2, size_value: float = 58.0) -> void:
	if _action_card_icon != null:
		_draw_texture_centered(_action_card_icon, center, Vector2(size_value, size_value))
		return
	if _icons != null:
		_draw_sheet_icon(ICON_ACTION, Rect2(center - Vector2(size_value, size_value) * 0.5, Vector2(size_value, size_value)))
		return
	draw_arc(center, 26.0, -2.7, -0.5, 16, Color("#22354a"), 2.0)
	draw_polygon(
		PackedVector2Array([
			center + Vector2(-7.0, 0.0),
			center + Vector2(14.0, -8.0),
			center + Vector2(22.0, 0.0),
			center + Vector2(14.0, 8.0),
		]),
		PackedColorArray([Color("#174f7a")])
	)
	draw_polygon(
		PackedVector2Array([
			center + Vector2(-7.0, 0.0),
			center + Vector2(-19.0, -9.0),
			center + Vector2(-19.0, 9.0),
		]),
		PackedColorArray([Color("#0d3a62")])
	)
	for i in range(3):
		var splash := center + Vector2(-18.0 + float(i) * 12.0, 30.0 + float(i % 2) * 4.0)
		draw_line(splash + Vector2(-6.0, 0.0), splash + Vector2(6.0, 0.0), Color("#35aee0"), 2.0)


func _draw_simple_rod(base: Vector2) -> void:
	draw_line(base + Vector2(-46.0, 22.0), base + Vector2(4.0, -42.0), Color("#2b2117"), 4.0)
	draw_line(base + Vector2(-43.0, 20.0), base + Vector2(1.0, -39.0), Palette.GOLD_BRIGHT, 1.0)
	draw_circle(base + Vector2(-18.0, 8.0), 9.0, Color("#22354a"))
	draw_circle(base + Vector2(-18.0, 8.0), 5.0, Palette.GOLD)


func _draw_tackle_icon(rect: Rect2) -> void:
	if _tackle_card_icon != null:
		_draw_texture_centered(_tackle_card_icon, rect.position + rect.size * 0.5, rect.size)
		return
	if _icons == null:
		return
	_draw_sheet_icon(ICON_TACKLE, rect)


func _draw_texture_centered(texture: Texture2D, center: Vector2, max_size: Vector2) -> void:
	var tex_size := texture.get_size()
	var scale := minf(max_size.x / tex_size.x, max_size.y / tex_size.y)
	var draw_size := tex_size * scale
	var rect := Rect2(center - draw_size * 0.5, draw_size)
	draw_texture_rect(texture, rect, false, Color.WHITE)


func _display_fish_name(name: String) -> String:
	if name.find("クロダイ") >= 0:
		return "クロダイ"
	return name


func _short_rod_name(name: String) -> String:
	if name.length() > 7:
		return name.left(7)
	return name


func _draw_sheet_icon(icon_index: int, target: Rect2) -> void:
	if _icons == null:
		return
	var cell_w := float(_icons.get_width()) / 3.0
	var cell_h := float(_icons.get_height()) / 3.0
	var col := icon_index % 3
	var row := icon_index / 3
	var src := Rect2(float(col) * cell_w, float(row) * cell_h, cell_w, cell_h)
	draw_texture_rect_region(_icons, target, src, Color.WHITE)
