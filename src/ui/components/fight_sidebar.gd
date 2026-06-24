class_name FightSidebar
extends Control
## 水中ファイト看板画面の右サイドバー。
# 魚カード、行動カード、タックルカードをまとめて描画し、参照画像の情報密度に寄せる。

const FISH_SHEET_PATH := "res://assets/showcase/underwater/kurodai_showcase_sheet.png"
const FISH_FRAME_COUNT := 4

var simulator: FishingSimulator
var fish_data: Dictionary = {}
var trip_stats: Dictionary = {}

var _fish_sheet: Texture2D


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


func _process(_delta: float) -> void:
	if simulator != null:
		queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return

	var gap := 7.0
	var header := Rect2(0.0, 0.0, w, 30.0)
	var action_h := clampf(h * 0.22, 86.0, 102.0)
	var tackle_h := clampf(h * 0.24, 92.0, 112.0)
	var fish_h := maxf(170.0, h - header.size.y - action_h - tackle_h - gap * 3.0)
	var fish_card := Rect2(0.0, header.end.y + gap, w, fish_h)
	var action_card := Rect2(0.0, fish_card.end.y + gap, w, action_h)
	var tackle_card := Rect2(0.0, action_card.end.y + gap, w, tackle_h)

	_draw_header(font, header)
	_draw_fish_card(font, fish_card)
	_draw_action_card(font, action_card)
	_draw_tackle_card(font, tackle_card)


func _draw_header(font: Font, rect: Rect2) -> void:
	_draw_panel(rect, Palette.DARK_PANEL, Palette.GOLD, Palette.GOLD_BRIGHT)
	_draw_text(font, "釣り中の魚", rect.position + Vector2(14.0, 23.0), 18, Palette.TEXT_BONE, 3)
	_draw_text(font, "1/1匹", rect.position + Vector2(rect.size.x - 62.0, 23.0), 16, Palette.GOLD_BRIGHT, 2)


func _draw_fish_card(font: Font, rect: Rect2) -> void:
	_draw_panel(rect, Palette.PARCHMENT, Palette.WOOD_DARK, Palette.GOLD)
	var inner := rect.grow(-10.0)
	var fish_name := String(fish_data.get("name", "クロダイ"))
	var rarity := String(fish_data.get("rarity", "レア"))
	var no_text := "No.028"
	_draw_text(font, no_text, inner.position + Vector2(0.0, 24.0), 15, Color("#6b6153"), 0)
	_draw_text(font, _display_fish_name(fish_name), inner.position + Vector2(86.0, 26.0), 22, Palette.TEXT_DARK, 0)
	_draw_rarity_tag(font, Rect2(inner.position + Vector2(inner.size.x - 70.0, 5.0), Vector2(62.0, 24.0)), rarity)

	var fish_rect := Rect2(
		inner.position + Vector2(14.0, 34.0),
		Vector2(inner.size.x - 28.0, maxf(92.0, rect.size.y * 0.37))
	)
	_draw_fish_portrait(fish_rect)
	var divider_y := fish_rect.end.y + 6.0
	draw_line(inner.position + Vector2(8.0, divider_y), inner.position + Vector2(inner.size.x - 8.0, divider_y), Color("#c9b486"), 1.0)
	var estimate := (float(fish_data.get("size_min", 0.0)) + float(fish_data.get("size_max", 0.0))) * 0.5
	_draw_text(font, "推定 %.1f cm" % estimate, inner.position + Vector2(42.0, divider_y + 27.0), 23, Color("#2b2117"), 0)
	var desc_y := divider_y + 48.0
	draw_line(inner.position + Vector2(8.0, desc_y - 10.0), inner.position + Vector2(inner.size.x - 8.0, desc_y - 10.0), Color("#d6c299"), 1.0)
	_draw_detail_line(font, "岩場や海藻の周りに潜む警戒心の強い魚。", inner.position + Vector2(16.0, desc_y), inner.size.x - 28.0)
	_draw_detail_line(font, "好むエサ：オキアミ・カニ", inner.position + Vector2(16.0, desc_y + 21.0), inner.size.x - 28.0)



func _draw_action_card(font: Font, rect: Rect2) -> void:
	_draw_panel(rect, Color("#0d3a62"), Palette.GOLD, Palette.GOLD_BRIGHT)
	_draw_text(font, "魚の行動", rect.position + Vector2(14.0, 26.0), 18, Palette.TEXT_BONE, 3)
	var body := Rect2(rect.position + Vector2(10.0, 34.0), rect.size - Vector2(20.0, 42.0))
	_draw_panel(body, Color("#f3e8cd"), Palette.WOOD_DARK, Palette.GOLD)
	var action := "待機"
	var message := "ラインを見ながら、テンションを保とう。"
	if simulator != null:
		action = simulator.action_name
		message = simulator.action_message
	_draw_action_icon(body.position + Vector2(32.0, body.size.y * 0.48))
	_draw_text(font, "%s！" % action, body.position + Vector2(74.0, 31.0), 20, Color("#2b2117"), 0)
	_draw_wrapped(font, message, body.position + Vector2(74.0, 48.0), body.size.x - 82.0, 13, Palette.TEXT_DARK, 1)


func _draw_tackle_card(font: Font, rect: Rect2) -> void:
	_draw_panel(rect, Color("#0d3a62"), Palette.GOLD, Palette.GOLD_BRIGHT)
	_draw_text(font, "タックル", rect.position + Vector2(14.0, 26.0), 18, Palette.TEXT_BONE, 3)
	var body := Rect2(rect.position + Vector2(10.0, 32.0), rect.size - Vector2(20.0, 38.0))
	_draw_panel(body, Palette.PARCHMENT, Palette.WOOD_DARK, Palette.GOLD)
	var rod_name := String(trip_stats.get("rod_name", "港の入門竿"))
	var lines: Array[String] = [
		"ロッド：%s" % rod_name,
		"ライン：ナイロン 3号",
		"ハリス：フロロ 2号",
	]
	for i in range(lines.size()):
		_draw_text(font, lines[i], body.position + Vector2(12.0, 22.0 + float(i) * 17.0), 13, Palette.TEXT_DARK, 0)
	_draw_simple_rod(body.position + Vector2(body.size.x - 62.0, body.size.y - 24.0))


func _draw_panel(rect: Rect2, fill: Color, border: Color, highlight: Color) -> void:
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


func _draw_text(font: Font, text: String, baseline: Vector2, font_size: int, color: Color, outline: int) -> void:
	if outline > 0:
		draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline, Color(0.0, 0.0, 0.0, 0.65))
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw_wrapped(font: Font, text: String, pos: Vector2, max_width: float, font_size: int, color: Color, max_lines: int) -> void:
	var line := ""
	var lines: Array[String] = []
	for i in range(text.length()):
		var next := line + text[i]
		if font.get_string_size(next, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > max_width and not line.is_empty():
			lines.append(line)
			line = text[i]
		else:
			line = next
	if not line.is_empty():
		lines.append(line)
	var count := mini(lines.size(), max_lines)
	for i in range(count):
		_draw_text(font, lines[i], pos + Vector2(0.0, float(i) * (font_size + 5.0) + float(font_size)), font_size, color, 0)


func _draw_bullet(font: Font, text: String, pos: Vector2, max_width: float) -> void:
	draw_circle(pos + Vector2(2.0, -3.0), 4.0, Color("#49c75a"))
	_draw_wrapped(font, text, pos + Vector2(14.0, -15.0), max_width - 14.0, 13, Palette.TEXT_DARK, 1)


func _draw_detail_line(font: Font, text: String, pos: Vector2, max_width: float) -> void:
	draw_circle(pos + Vector2(3.0, 10.0), 4.0, Color("#49c75a"))
	_draw_wrapped(font, text, pos + Vector2(14.0, 0.0), max_width - 14.0, 13, Palette.TEXT_DARK, 1)


func _draw_rarity_tag(font: Font, rect: Rect2, rarity: String) -> void:
	draw_rect(rect, Color("#8e4f77"), true)
	draw_rect(rect, Color("#e7b4d1"), false, 1.0)
	var text_width := font.get_string_size(rarity, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	_draw_text(font, rarity, rect.position + Vector2((rect.size.x - text_width) * 0.5, 17.0), 13, Color.WHITE, 1)


func _draw_fish_portrait(rect: Rect2) -> void:
	if _fish_sheet == null:
		var color := Color.from_string(String(fish_data.get("color", "#394956")), Color("#394956"))
		draw_texture_rect(UITextures.get_fish_icon(color), rect, false)
		return
	var frame_w := float(_fish_sheet.get_width()) / float(FISH_FRAME_COUNT)
	var frame_h := float(_fish_sheet.get_height())
	var tex_size := Vector2(frame_w, frame_h)
	var scale := minf(rect.size.x / tex_size.x, rect.size.y / tex_size.y)
	var draw_size := tex_size * scale
	var draw_rect := Rect2(rect.position + (rect.size - draw_size) * 0.5, draw_size)
	draw_texture_rect_region(_fish_sheet, draw_rect, Rect2(0.0, 0.0, frame_w, frame_h), Color.WHITE)


func _draw_action_icon(center: Vector2) -> void:
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


func _display_fish_name(name: String) -> String:
	if name.find("クロダイ") >= 0:
		return "クロダイ"
	return name
