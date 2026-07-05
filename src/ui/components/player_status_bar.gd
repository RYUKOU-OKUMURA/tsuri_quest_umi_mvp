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
	var slots := _slot_rects(rect, font, values)
	for index in range(mini(values.size(), slots.size())):
		_draw_slot(font, slots[index], index, String(values[index]))


func _status_values() -> Array[String]:
	var rod_name := String(GameData.get_rod(PlayerProgress.equipped_rod_id).get("name", "入門竿"))
	return [
		"Lv.%d" % PlayerProgress.level,
		_short_rod_name(rod_name),
		"%s G" % ScreenBase.format_money(PlayerProgress.money),
	]


func _slot_rects(rect: Rect2, font: Font, values: Array[String]) -> Array[Rect2]:
	var pad_x := maxf(10.0, rect.size.x * 0.018)
	var y := rect.position.y + rect.size.y * 0.14
	var h := rect.size.y * 0.72
	var w := rect.size.x - pad_x * 2.0
	var icon_size := clampf(h * 0.72, 28.0, 38.0)
	var lv_text_w := font.get_string_size(String(values[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	var money_text_w := font.get_string_size(String(values[2]), HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	var lv_w := clampf(icon_size + lv_text_w + 24.0, w * 0.18, w * 0.24)
	var money_w := clampf(icon_size + money_text_w + 24.0, w * 0.34, minf(w * 0.48, 184.0))
	var rod_w := maxf(w - lv_w - money_w, w * 0.24)
	if lv_w + rod_w + money_w > w:
		rod_w = maxf(w - lv_w - money_w, 0.0)
	return [
		Rect2(rect.position.x + pad_x, y, lv_w, h),
		Rect2(rect.position.x + pad_x + lv_w, y, rod_w, h),
		Rect2(rect.position.x + pad_x + lv_w + rod_w, y, w - lv_w - rod_w, h),
	]


func _draw_slot(font: Font, rect: Rect2, icon_index: int, text: String) -> void:
	var icon_size := clampf(rect.size.y * 0.72, 28.0, 38.0)
	if icon_index == 2 and rect.size.x < 150.0:
		icon_size = clampf(rect.size.y * 0.62, 24.0, 32.0)
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
	if icon_index == 2:
		font_size = _fit_font_size(font, text, 17, 13, max_width)
	var display := text if icon_index == 2 else _fit_text(font, text, font_size, max_width)
	draw_string_outline(font, Vector2(text_x, baseline), display, HORIZONTAL_ALIGNMENT_LEFT, max_width, font_size, 2, Palette.TEXT_OUTLINE_DARK)
	draw_string(font, Vector2(text_x, baseline), display, HORIZONTAL_ALIGNMENT_LEFT, max_width, font_size, Palette.TEXT_BONE)


func _draw_icon(icon_index: int, rect: Rect2) -> void:
	if _icons != null:
		var cell_w := float(_icons.get_width()) / 3.0
		var src := Rect2(float(icon_index) * cell_w, 0.0, cell_w, float(_icons.get_height()))
		draw_texture_rect_region(_icons, rect, src, Palette.PLAYER_STATUS_ICON_MODULATE)
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


func _fit_font_size(font: Font, text: String, base_size: int, minimum_size: int, max_width: float) -> int:
	for size in range(base_size, minimum_size - 1, -1):
		if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x <= max_width:
			return size
	return minimum_size


func _short_rod_name(rod_name: String) -> String:
	if rod_name.begins_with("港の"):
		rod_name = rod_name.substr(2)
	var parts := rod_name.split("・")
	if parts.size() >= 2:
		return String(parts[1])
	return rod_name
