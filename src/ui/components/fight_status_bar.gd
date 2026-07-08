class_name FightStatusBar
extends Control
## 水中ファイト画面上部の専用ステータスバー。
# 生成フレーム素材を敷き、時計・天候・所持金・現在地点/水深の文字だけを重ねる。

const GameFontsScript = preload("res://src/ui/game_fonts.gd")
const FRAME_PATH := "res://assets/showcase/underwater/top_status_frame.png"
const TOP_ICON_SHEET_PATH := "res://assets/showcase/underwater/top_status_icon_sheet.png"
const WEATHER_ICON_SHEET_PATH := "res://assets/showcase/underwater/weather_status_icon_sheet.png"
const ICON_SHEET_PATH := "res://assets/showcase/underwater/fight_icon_sheet.png"
const ICON_TIME := 0
const ICON_WEATHER := 1
const ICON_WIND := 2
const ICON_COIN := 3
const WEATHER_ICON_COUNT := 5
const WEATHER_ICON_INDEX := {
	"sunny": 0,
	"partly_cloudy": 1,
	"cloudy": 2,
	"rain": 3,
	"fog": 4,
}

var simulator: FishingSimulator
var trip_stats: Dictionary = {}

var _frame: Texture2D
var _top_icons: Texture2D
var _weather_icons: Texture2D
var _icons: Texture2D


func bind(value: FishingSimulator, stats: Dictionary = {}) -> void:
	simulator = value
	trip_stats = stats.duplicate(true)
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0.0, 76.0)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if ResourceLoader.exists(FRAME_PATH):
		_frame = load(FRAME_PATH) as Texture2D
	if ResourceLoader.exists(TOP_ICON_SHEET_PATH):
		_top_icons = load(TOP_ICON_SHEET_PATH) as Texture2D
	if ResourceLoader.exists(WEATHER_ICON_SHEET_PATH):
		_weather_icons = load(WEATHER_ICON_SHEET_PATH) as Texture2D
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

	var font := GameFontsScript.bold(get_theme_default_font())
	var regular_font := GameFontsScript.regular(get_theme_default_font())
	var slots := _slot_rects(rect)
	_draw_status_icon(slots[0], ICON_TIME)
	_draw_weather_status_icon(slots[1])
	_draw_status_icon(slots[2], ICON_COIN)
	_draw_status_slot(font, regular_font, slots[0], "時間帯", _time_slot_label(), false)
	_draw_status_slot(font, regular_font, slots[1], _weather_label(), _wind_label(), false)
	_draw_status_slot(font, regular_font, slots[2], "所持金", "%s G" % ScreenBase.format_money(PlayerProgress.money), false)
	var depth := 0.0
	var depth_range: Array = trip_stats.get("spot_depth_range", [])
	if depth_range.size() >= 2:
		depth = float(depth_range[1])
	elif simulator != null:
		depth = simulator.depth
	_draw_status_slot(font, regular_font, slots[3], _spot_title(), "水深 %.1fm" % depth, true)


func _slot_rects(rect: Rect2) -> Array[Rect2]:
	var w := rect.size.x
	var y := rect.position.y + rect.size.y * 0.08
	var h := rect.size.y * 0.84
	return [
		Rect2(rect.position.x + w * 0.000, y, w * 0.235, h),
		Rect2(rect.position.x + w * 0.235, y, w * 0.300, h),
		Rect2(rect.position.x + w * 0.535, y, w * 0.250, h),
		Rect2(rect.position.x + w * 0.785, y, w * 0.215, h),
	]


func _draw_status_slot(font: Font, regular_font: Font, rect: Rect2, title: String, body: String, dark: bool) -> void:
	if dark:
		_draw_centered_dark_slot(font, regular_font, rect, title, body)
		return
	var icon_space := clampf(rect.size.y * 0.96, 60.0, 68.0)
	var text_x := rect.position.x + icon_space
	var max_width := rect.end.x - text_x - 10.0
	var title_size := 15 if dark else 14
	var body_size := 24 if not dark else 20
	if rect.size.x < 230.0:
		body_size = 22
	var title_color := Palette.FIGHT_STATUS_TITLE_TEXT if not dark else Palette.GOLD_BRIGHT
	var body_color := Palette.FIGHT_STATUS_BODY_TEXT if not dark else Palette.FIGHT_STATUS_LIGHT_TEXT
	var outline := 0 if not dark else 3
	var title_y := rect.position.y + rect.size.y * 0.40
	var body_y := rect.position.y + rect.size.y * 0.72
	if not dark and body.begins_with("風"):
		var inline_y := rect.position.y + rect.size.y * 0.57
		_draw_text_clipped(font, title, Vector2(text_x - 2.0, inline_y), 21, body_color, max_width, outline)
		var weather_width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 21).x
		var wind_icon_size := 21.0
		var wind_x := text_x - 2.0 + weather_width + 14.0
		_draw_top_sheet_icon(
			ICON_WIND,
			Rect2(Vector2(wind_x, rect.position.y + (rect.size.y - wind_icon_size) * 0.5 + 1.0), Vector2(wind_icon_size, wind_icon_size)),
			Palette.FIGHT_STATUS_ICON_MODULATE_SOFT
		)
		_draw_text_clipped(font, body, Vector2(wind_x + 26.0, inline_y), 19, Palette.FIGHT_STATUS_WIND_TEXT, max_width - (wind_x - text_x) - 26.0, outline)
		return
	if not dark and title == "所持金":
		var amount_y := rect.position.y + rect.size.y * 0.57
		_draw_text_clipped(font, body, Vector2(text_x - 2.0, amount_y), 24, body_color, max_width + 2.0, outline)
		return
	_draw_text_clipped(font, title, Vector2(text_x, title_y), title_size, title_color, max_width, outline)
	_draw_text_clipped(font, body, Vector2(text_x, body_y), body_size, body_color, max_width, outline)


func _draw_centered_dark_slot(font: Font, regular_font: Font, rect: Rect2, title: String, body: String) -> void:
	var title_size := 14
	var depth_label_size := 16
	var depth_value_size := 19
	var title_width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x
	_draw_text_clipped(
		font,
		title,
		Vector2(rect.position.x + (rect.size.x - title_width) * 0.5, rect.position.y + rect.size.y * 0.33),
		title_size,
		Palette.GOLD_BRIGHT,
		rect.size.x,
		1
	)
	var depth_value := body.replace("水深 ", "")
	var label := "水深"
	var gap := 8.0
	var label_width := regular_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, depth_label_size).x
	var value_width := font.get_string_size(depth_value, HORIZONTAL_ALIGNMENT_LEFT, -1, depth_value_size).x
	var total_width := label_width + gap + value_width
	var baseline := rect.position.y + rect.size.y * 0.75
	var x := rect.position.x + (rect.size.x - total_width) * 0.5
	_draw_text_clipped(regular_font, label, Vector2(x, baseline), depth_label_size, Palette.FIGHT_STATUS_DEPTH_LABEL_TEXT, label_width + 2.0, 1)
	_draw_text_clipped(font, depth_value, Vector2(x + label_width + gap, baseline), depth_value_size, Palette.FIGHT_STATUS_LIGHT_TEXT, value_width + 2.0, 1)


func _draw_status_icon(rect: Rect2, icon_index: int) -> void:
	if _top_icons == null and _icons == null:
		return
	var icon_size := clampf(rect.size.y * 0.64, 38.0, 44.0)
	var icon_rect := Rect2(
		rect.position + Vector2(10.0, (rect.size.y - icon_size) * 0.5 + 1.0),
		Vector2(icon_size, icon_size)
	)
	_draw_top_sheet_icon(icon_index, icon_rect, Palette.FIGHT_STATUS_ICON_MODULATE)


func _draw_weather_status_icon(rect: Rect2) -> void:
	var icon_size := clampf(rect.size.y * 0.64, 38.0, 44.0)
	var icon_rect := Rect2(
		rect.position + Vector2(10.0, (rect.size.y - icon_size) * 0.5 + 1.0),
		Vector2(icon_size, icon_size)
	)
	if _weather_icons == null:
		_draw_top_sheet_icon(ICON_WEATHER, icon_rect, Palette.FIGHT_STATUS_ICON_MODULATE)
		return
	var cell_w := float(_weather_icons.get_width()) / float(WEATHER_ICON_COUNT)
	var src := Rect2(float(_weather_icon_index()) * cell_w, 0.0, cell_w, float(_weather_icons.get_height()))
	draw_texture_rect_region(_weather_icons, icon_rect, src, Palette.FIGHT_STATUS_ICON_MODULATE)


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
			Palette.FIGHT_STATUS_TEXT_OUTLINE
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


func _weather_id() -> String:
	var weather_id := String(trip_stats.get("weather_id", "sunny"))
	if weather_id.strip_edges().is_empty():
		return "sunny"
	return weather_id


func _weather_icon_index() -> int:
	var weather_id := _weather_id()
	if not WEATHER_ICON_INDEX.has(weather_id):
		return WEATHER_ICON_INDEX["sunny"]
	return int(WEATHER_ICON_INDEX[weather_id])


func _weather_label() -> String:
	var label := String(trip_stats.get("weather_label", "快晴"))
	if label.strip_edges().is_empty():
		return "快晴"
	return label


func _wind_label() -> String:
	var label := String(trip_stats.get("wind_label", "風 弱"))
	if label.strip_edges().is_empty():
		return "風 弱"
	return label


func _time_slot_label() -> String:
	var label := String(trip_stats.get("time_slot_label", "日中"))
	if label.strip_edges().is_empty():
		return "日中"
	return label


func _spot_title() -> String:
	var name := String(trip_stats.get("spot_name", "南の島・沖"))
	if name.strip_edges().is_empty():
		return "南の島・沖"
	return name


func _draw_fallback_frame(rect: Rect2) -> void:
	draw_rect(rect, Palette.FIGHT_STATUS_FALLBACK_DARK, true)
	draw_rect(rect.grow(-2.0), Palette.GOLD_DEEP, false, 2.0)
	for slot in _slot_rects(rect):
		var fill := Palette.PARCHMENT if slot.position.x < rect.position.x + rect.size.x * 0.70 else Palette.FIGHT_STATUS_FALLBACK_WATER
		draw_rect(slot.grow(-3.0), fill, true)
		draw_rect(slot.grow(-3.0), Palette.GOLD, false, 2.0)
