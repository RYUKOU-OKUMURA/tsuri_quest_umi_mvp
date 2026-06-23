class_name GaugeBar
extends Control
## グラデ塗り／丸端／ドロップシャドウ／アウトライン付き数値を持つ再利用ゲージ。
## juice: 表示値の指数補間（追従）＋ゴースト（減少時の遅れバー）＋ダメージ点滅＋危険域グロー。

var fill_from := Color("#3cbf78")
var fill_to := Color("#9ff0c0")
var track_color := Color(0.03, 0.10, 0.18, 0.88)
var label_text := ""
var show_value := true
var critical_threshold := 0.25   # この割合以下で危険域グロー

var min_value: float = 0.0
var max_value: float = 100.0
var value: float = 100.0

var _displayed: float = 100.0   # 値へ滑らかに追従
var _ghost: float = 100.0       # 減少時に遅れて下がる残像
var _flash: float = 0.0         # ダメージ点滅(0..1)
var _time: float = 0.0
var _gradient: GradientTexture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0.0, 30.0)
	_displayed = value
	_ghost = value
	_rebuild_gradient()


func set_colors(from: Color, to: Color) -> void:
	fill_from = from
	fill_to = to
	_rebuild_gradient()
	queue_redraw()


func set_value(new_value: float) -> void:
	var clamped := clampf(new_value, min_value, max_value)
	if clamped < value - 0.5:
		_flash = 1.0   # 減少＝ダメージ点滅
	value = clamped


func set_ratio(ratio: float) -> void:
	set_value(min_value + clampf(ratio, 0.0, 1.0) * (max_value - min_value))


func ratio() -> float:
	var span := maxf(max_value - min_value, 0.0001)
	return (value - min_value) / span


func _process(delta: float) -> void:
	_time += delta
	# 表示値を値へ指数補間（フレームレート非依存）
	_displayed = lerpf(_displayed, value, 1.0 - exp(-14.0 * delta))
	# ゴースト：上昇は即座、下降はゆっくり
	if value >= _ghost:
		_ghost = value
	else:
		_ghost = lerpf(_ghost, value, 1.0 - exp(-4.0 * delta))
	_flash = maxf(_flash - delta * 2.5, 0.0)
	queue_redraw()


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

	var span := maxf(max_value - min_value, 0.0001)
	var r_disp := clampf((_displayed - min_value) / span, 0.0, 1.0)
	var r_ghost := clampf((_ghost - min_value) / span, 0.0, 1.0)

	# 落ち影
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

	var inset_y := 3.0

	# ゴースト（残像）：表示値より多い分を白っぽく残す
	if r_ghost > r_disp + 0.005:
		var ghost_w := maxf(bar_rect.size.x * r_ghost - 6.0, radius)
		var ghost_rect := Rect2(3.0, inset_y, ghost_w, bar_rect.size.y - inset_y * 2.0)
		draw_rect(ghost_rect, Color(1.0, 1.0, 1.0, 0.35), false, 2.0)

	# 塗り（グラデ・丸端）
	if r_disp > 0.0:
		var fill_w := maxf(bar_rect.size.x * r_disp - 6.0, radius)
		var fill_rect := Rect2(3.0, inset_y, fill_w, bar_rect.size.y - inset_y * 2.0)
		draw_texture_rect(_gradient, fill_rect, false)
		# 上面ハイライト
		var highlight := Rect2(fill_rect.position.x + 2.0, fill_rect.position.y + 1.0, fill_rect.size.x - 4.0, 2.0)
		draw_rect(highlight, Color(1.0, 1.0, 1.0, 0.35), false, 1.0)
		# ダメージ点滅
		if _flash > 0.0:
			draw_rect(fill_rect, Color(1.0, 1.0, 1.0, _flash * 0.6), false, 2.0)

	# 危険域グロー（点滅）
	if r_disp > 0.0 and r_disp < critical_threshold:
		var pulse := 0.35 + 0.35 * sin(_time * 8.0)
		draw_rect(
			Rect2(2.0, 2.0, bar_rect.size.x - 4.0, bar_rect.size.y - 4.0),
			Color(1.0, 0.35, 0.35, pulse),
			false,
			2.0
		)

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
