class_name FightStatusBar
extends Control
## 水中ファイト画面上部の専用ステータスバー。
# 生成フレーム素材を敷き、時計・天候・所持金・現在地点/水深の文字だけを重ねる。

const FightFontsScript = preload("res://src/ui/fight_fonts.gd")
const FRAME_PATH := "res://assets/showcase/underwater/top_status_frame.png"
const TOP_ICON_SHEET_PATH := "res://assets/showcase/underwater/top_status_icon_sheet.png"
const ICON_SHEET_PATH := "res://assets/showcase/underwater/fight_icon_sheet.png"
const ICON_TIME := 0
const ICON_WEATHER := 1
const ICON_WIND := 2
const ICON_COIN := 3

var simulator: FishingSimulator

var _frame: Texture2D
var _top_icons: Texture2D
var _icons: Texture2D


func bind(value: FishingSimulator) -> void:
	simulator = value
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0.0, 76.0)
	if ResourceLoader.exists(FRAME_PATH):
		_frame = load(FRAME_PATH) as Texture2D
	if ResourceLoader.exists(TOP_ICON_SHEET_PATH):
		_top_icons = load(TOP_ICON_SHEET_PATH) as Texture2D
	if ResourceLoader.exists(ICON_SHEET_PATH):
		_icons = load(ICON_SHEET_PATH) as Texture2D


func _process(_delta: float) -> void:
	if simulator != null:
		queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return

	if _frame != null:
		draw_texture_rect(_frame, rect, false, Color.WHITE)
	else:
		_draw_fallback_frame(rect)

	var font := FightFontsScript.bold(get_theme_default_font())
	var slots := _slot_rects(rect)
	_draw_status_icon(slots[0], ICON_TIME)
	_draw_status_icon(slots[1], ICON_WEATHER)
	_draw_status_icon(slots[2], ICON_COIN)
	_draw_status_slot(font, slots[0], "AM", "08:47", false)
	_draw_status_slot(font, slots[1], "快晴", "風 弱", false)
	_draw_status_slot(font, slots[2], "所持金", "%s G" % _format_money(PlayerProgress.money), false)
	var depth := 0.0
	if simulator != null:
		depth = simulator.depth
	_draw_status_slot(font, slots[3], "南の島・沖", "水深 %.1fm" % depth, true)


func _slot_rects(rect: Rect2) -> Array[Rect2]:
	var w := rect.size.x
	var y := rect.position.y + rect.size.y * 0.08
	var h := rect.size.y * 0.84
	return [
		Rect2(rect.position.x + w * 0.000, y, w * 0.245, h),
		Rect2(rect.position.x + w * 0.245, y, w * 0.310, h),
		Rect2(rect.position.x + w * 0.555, y, w * 0.270, h),
		Rect2(rect.position.x + w * 0.825, y, w * 0.175, h),
	]


func _draw_status_slot(font: Font, rect: Rect2, title: String, body: String, dark: bool) -> void:
	if dark:
		_draw_centered_dark_slot(font, rect, title, body)
		return
	var icon_space := clampf(rect.size.y * 0.96, 60.0, 68.0)
	var text_x := rect.position.x + icon_space
	var max_width := rect.end.x - text_x - 10.0
	var title_size := 15 if dark else 14
	var body_size := 24 if not dark else 21
	if rect.size.x < 230.0:
		body_size = 22
	var title_color := Color("#6d4d25") if not dark else Palette.GOLD_BRIGHT
	var body_color := Color("#21170f") if not dark else Color("#eaf6ff")
	var outline := 0 if not dark else 3
	var title_y := rect.position.y + rect.size.y * 0.40
	var body_y := rect.position.y + rect.size.y * 0.72
	if not dark and title == "AM":
		var am_y := rect.position.y + rect.size.y * 0.64
		_draw_text_clipped(font, title, Vector2(text_x - 1.0, am_y), 15, title_color, max_width, outline)
		_draw_text_clipped(font, body, Vector2(text_x + 31.0, am_y + 4.0), 32, body_color, max_width - 31.0, outline)
		return
	if not dark and title == "快晴":
		var inline_y := rect.position.y + rect.size.y * 0.66
		_draw_text_clipped(font, title, Vector2(text_x - 1.0, inline_y), 24, body_color, max_width, outline)
		var wind_icon_size := 28.0
		var wind_x := text_x + 71.0
		_draw_top_sheet_icon(
			ICON_WIND,
			Rect2(Vector2(wind_x, rect.position.y + (rect.size.y - wind_icon_size) * 0.5 + 1.0), Vector2(wind_icon_size, wind_icon_size)),
			Color(1.0, 1.0, 1.0, 0.92)
		)
		_draw_text_clipped(font, body, Vector2(wind_x + 31.0, inline_y), 23, Color("#173f32"), max_width - (wind_x - text_x) - 31.0, outline)
		return
	if not dark and title == "所持金":
		var amount_y := rect.position.y + rect.size.y * 0.68
		_draw_text_clipped(font, body, Vector2(text_x - 1.0, amount_y + 1.0), 32, body_color, max_width + 2.0, outline)
		return
	_draw_text_clipped(font, title, Vector2(text_x, title_y), title_size, title_color, max_width, outline)
	_draw_text_clipped(font, body, Vector2(text_x, body_y), body_size, body_color, max_width, outline)


func _draw_centered_dark_slot(font: Font, rect: Rect2, title: String, body: String) -> void:
	var title_size := 15
	var body_size := 24
	var title_width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x
	var body_width := font.get_string_size(body, HORIZONTAL_ALIGNMENT_LEFT, -1, body_size).x
	_draw_text_clipped(
		font,
		title,
		Vector2(rect.position.x + (rect.size.x - title_width) * 0.5, rect.position.y + rect.size.y * 0.37),
		title_size,
		Palette.GOLD_BRIGHT,
		rect.size.x,
		3
	)
	_draw_text_clipped(
		font,
		body,
		Vector2(rect.position.x + (rect.size.x - body_width) * 0.5, rect.position.y + rect.size.y * 0.74),
		body_size,
		Color("#eaf6ff"),
		rect.size.x,
		3
	)


func _draw_status_icon(rect: Rect2, icon_index: int) -> void:
	if _top_icons == null and _icons == null:
		return
	var icon_size := clampf(rect.size.y * 0.62, 40.0, 46.0)
	var icon_rect := Rect2(
		rect.position + Vector2(11.0, (rect.size.y - icon_size) * 0.5 + 1.0),
		Vector2(icon_size, icon_size)
	)
	_draw_top_sheet_icon(icon_index, icon_rect, Color(1.0, 1.0, 1.0, 0.96))


func _draw_top_sheet_icon(icon_index: int, target: Rect2, modulate: Color = Color.WHITE) -> void:
	if _top_icons != null:
		var cell_w := float(_top_icons.get_width()) / 4.0
		var src := Rect2(float(icon_index) * cell_w, 0.0, cell_w, float(_top_icons.get_height()))
		draw_texture_rect_region(_top_icons, target, src, modulate)
		return
	_draw_sheet_icon(icon_index, target, modulate)


func _draw_sheet_icon(icon_index: int, target: Rect2, modulate: Color = Color.WHITE) -> void:
	if _icons == null:
		return
	var cell_w := float(_icons.get_width()) / 3.0
	var cell_h := float(_icons.get_height()) / 3.0
	var col := icon_index % 3
	var row := icon_index / 3
	var src := Rect2(float(col) * cell_w, float(row) * cell_h, cell_w, cell_h)
	draw_texture_rect_region(_icons, target, src, modulate)


func _draw_text_clipped(
	font: Font,
	text: String,
	baseline: Vector2,
	font_size: int,
	color: Color,
	max_width: float,
	outline: int
) -> void:
	var display := _fit_text(font, text, font_size, max_width)
	if outline > 0:
		draw_string_outline(
			font,
			baseline,
			display,
			HORIZONTAL_ALIGNMENT_LEFT,
			max_width,
			font_size,
			outline,
			Color(0.0, 0.0, 0.0, 0.7)
		)
	draw_string(font, baseline, display, HORIZONTAL_ALIGNMENT_LEFT, max_width, font_size, color)


func _fit_text(font: Font, text: String, font_size: int, max_width: float) -> String:
	if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= max_width:
		return text
	var ellipsis := "..."
	var result := text
	while result.length() > 0:
		result = result.left(result.length() - 1)
		var candidate := result + ellipsis
		if font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= max_width:
			return candidate
	return ellipsis


func _format_money(value: int) -> String:
	var raw := str(value)
	var result := ""
	var count := 0
	for index in range(raw.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = raw[index] + result
		count += 1
	return result


func _draw_fallback_frame(rect: Rect2) -> void:
	draw_rect(rect, Color("#071523"), true)
	draw_rect(rect.grow(-2.0), Palette.GOLD_DEEP, false, 2.0)
	for slot in _slot_rects(rect):
		var fill := Palette.PARCHMENT if slot.position.x < rect.position.x + rect.size.x * 0.70 else Color("#102c4b")
		draw_rect(slot.grow(-3.0), fill, true)
		draw_rect(slot.grow(-3.0), Palette.GOLD, false, 2.0)
