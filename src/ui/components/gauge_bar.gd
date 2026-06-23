class_name GaugeBar
extends Control
## グラデ塗り／丸端／ドロップシャドウ／アウトライン付き数値を持つ再利用ゲージ。
## 暗背景のHUDで使うことを想定し、視認性を稼ぐために装飾を盛っている。

var fill_from := Color("#3cbf78")
var fill_to := Color("#9ff0c0")
var track_color := Color(0.03, 0.10, 0.18, 0.88)
var label_text := ""
var show_value := true

var min_value: float = 0.0
var max_value: float = 100.0
var value: float = 100.0

var _gradient: GradientTexture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0.0, 30.0)
	_rebuild_gradient()


func set_colors(from: Color, to: Color) -> void:
	fill_from = from
	fill_to = to
	_rebuild_gradient()
	queue_redraw()


func set_value(new_value: float) -> void:
	value = clampf(new_value, min_value, max_value)
	queue_redraw()


func set_ratio(ratio: float) -> void:
	set_value(min_value + clampf(ratio, 0.0, 1.0) * (max_value - min_value))


func ratio() -> float:
	var span := maxf(max_value - min_value, 0.0001)
	return (value - min_value) / span


func _rebuild_gradient() -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, fill_from)
	gradient.set_color(1, fill_to)
	if _gradient == null:
		_gradient = GradientTexture2D.new()
		_gradient.fill_from = Vector2(0.0, 0.0)
		_gradient.fill_to = Vector2(1.0, 0.0)
		_gradient.width = 128
		_gradient.height = 16
	_gradient.gradient = gradient


func _draw() -> void:
	var bar_rect := Rect2(Vector2.ZERO, Vector2(size.x, size.y))
	var radius := minf(bar_rect.size.y * 0.5, 12.0)

	# 落ち影（塗りは透明にしてシャドウのみ描画）
	var shadow_style := StyleBoxFlat.new()
	shadow_style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	shadow_style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	shadow_style.shadow_size = 6
	shadow_style.shadow_offset = Vector2(0.0, 3.0)
	shadow_style.set_corner_radius_all(int(radius))
	draw_style_box(shadow_style, bar_rect)

	# 軌道（背景溝）
	var track_style := StyleBoxFlat.new()
	track_style.bg_color = track_color
	track_style.border_color = Color(1.0, 1.0, 1.0, 0.12)
	track_style.set_border_width_all(1)
	track_style.set_corner_radius_all(int(radius))
	draw_style_box(track_style, bar_rect)

	# 塗り（グラデ・丸端・高さは少し細めに）
	var r := ratio()
	if r > 0.0:
		var inset_y := 3.0
		var fill_rect := Rect2(
			3.0,
			inset_y,
			maxf(bar_rect.size.x * r - 6.0, radius),
			bar_rect.size.y - inset_y * 2.0
		)
		draw_texture_rect(_gradient, fill_rect, false)
		# 上面のハイライトで立体感
		var highlight := Rect2(fill_rect.position.x + 2.0, fill_rect.position.y + 1.0, fill_rect.size.x - 4.0, 2.0)
		draw_rect(highlight, Color(1.0, 1.0, 1.0, 0.35), false, 1.0)

	# 数値（アウトライン付き）
	if show_value:
		var font := get_theme_default_font()
		var text := "%d%%" % int(round(value))
		var font_size := 14
		var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
		var pos := Vector2(bar_rect.size.x - text_width - 10.0, bar_rect.size.y * 0.5 + font_size * 0.34)
		draw_string_outline(
			font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color(0.0, 0.0, 0.0, 0.65)
		)
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
