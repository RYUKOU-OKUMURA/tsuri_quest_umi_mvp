class_name PlayerStatusBar
extends Control

const GameFontsScript = preload("res://src/ui/game_fonts.gd")
const ShowcaseAssetsScript = preload("res://src/ui/showcase_assets.gd")

const FRAME_PATH := "res://assets/showcase/common/status_bar_frame.png"
const ICON_SHEET_PATH := "res://assets/showcase/common/status_icon_sheet.png"

var _frame: Texture2D
var _icons: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0.0, 60.0)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_frame = ShowcaseAssetsScript.load_texture(FRAME_PATH)
	_icons = ShowcaseAssetsScript.load_texture(ICON_SHEET_PATH)


func refresh() -> void:
	queue_redraw()


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var rect := Rect2(Vector2.ZERO, size)
	if _frame != null:
		draw_texture_rect(_frame, rect, false)
	else:
		_draw_fallback_frame(rect)

	var font := GameFontsScript.extra_bold(get_theme_default_font())
	var values := _status_values()
	var slots := _slot_rects(rect)
	for index in range(mini(values.size(), slots.size())):
		_draw_slot(font, slots[index], index, String(values[index]))


func _status_values() -> Array[String]:
	var rod_name := String(GameData.get_rod(PlayerProgress.equipped_rod_id).get("name", "入門竿"))
	return [
		"Lv.%d" % PlayerProgress.level,
		_short_rod_name(rod_name),
		"%s G" % _format_money(PlayerProgress.money),
	]


func _slot_rects(rect: Rect2) -> Array[Rect2]:
	var pad_x := maxf(10.0, rect.size.x * 0.018)
	var y := rect.position.y + rect.size.y * 0.14
	var h := rect.size.y * 0.72
	var w := rect.size.x - pad_x * 2.0
	var lv_w := w * 0.25
	var rod_w := w * 0.43
	return [
		Rect2(rect.position.x + pad_x, y, lv_w, h),
		Rect2(rect.position.x + pad_x + lv_w, y, rod_w, h),
		Rect2(rect.position.x + pad_x + lv_w + rod_w, y, w - lv_w - rod_w, h),
	]


func _draw_slot(font: Font, rect: Rect2, icon_index: int, text: String) -> void:
	var icon_size := clampf(rect.size.y * 0.72, 28.0, 38.0)
	var icon_rect := Rect2(
		rect.position + Vector2(6.0, (rect.size.y - icon_size) * 0.5),
		Vector2(icon_size, icon_size)
	)
	_draw_icon(icon_index, icon_rect)
	var text_x := icon_rect.end.x + 8.0
	var baseline := rect.position.y + rect.size.y * 0.63
	var max_width := rect.end.x - text_x - 4.0
	var font_size := 19
	if rect.size.x < 145.0:
		font_size = 17
	var display := _fit_text(font, text, font_size, max_width)
	draw_string_outline(font, Vector2(text_x, baseline), display, HORIZONTAL_ALIGNMENT_LEFT, max_width, font_size, 2, Palette.TEXT_OUTLINE_DARK)
	draw_string(font, Vector2(text_x, baseline), display, HORIZONTAL_ALIGNMENT_LEFT, max_width, font_size, Palette.TEXT_BONE)


func _draw_icon(icon_index: int, rect: Rect2) -> void:
	if _icons != null:
		var cell_w := float(_icons.get_width()) / 3.0
		var src := Rect2(float(icon_index) * cell_w, 0.0, cell_w, float(_icons.get_height()))
		draw_texture_rect_region(_icons, rect, src, Color(1.0, 1.0, 1.0, 0.95))
		return
	draw_circle(rect.get_center(), minf(rect.size.x, rect.size.y) * 0.42, Palette.GOLD)


func _draw_fallback_frame(rect: Rect2) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.DARK_PANEL
	style.border_color = Palette.GOLD
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	draw_style_box(style, rect)


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


func _short_rod_name(rod_name: String) -> String:
	var parts := rod_name.split("・")
	if parts.size() >= 2:
		return String(parts[1])
	return rod_name
