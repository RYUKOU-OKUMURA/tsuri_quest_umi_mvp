class_name HarborBackdrop
extends Control

const HARBOR_BG_PATH := "res://assets/showcase/harbor/harbor_hub_bg.png"
const HARBOR_GRADE_PATH := "res://assets/showcase/harbor/harbor_color_grade.png"

var _time := 0.0
var _harbor_bg: Texture2D
var _harbor_grade: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_harbor_bg = ShowcaseAssets.load_texture(HARBOR_BG_PATH)
	_harbor_grade = ShowcaseAssets.load_texture(HARBOR_GRADE_PATH)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return

	if _harbor_bg != null:
		_draw_cover_texture(_harbor_bg, rect, Color.WHITE, Vector2(0.5, 0.52))
	else:
		_draw_fallback_gradient()
	_draw_sun_glints()
	_draw_harbor_air()
	if _harbor_grade != null:
		_draw_cover_texture(_harbor_grade, rect, Color.WHITE, Vector2(0.5, 0.5))
	_draw_edge_frame()


func _draw_cover_texture(texture: Texture2D, target_rect: Rect2, modulate: Color, align := Vector2(0.5, 0.5)) -> void:
	if texture == null:
		return
	var tex_size := texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	var scale := maxf(target_rect.size.x / tex_size.x, target_rect.size.y / tex_size.y)
	var draw_size := tex_size * scale
	var draw_pos := target_rect.position + Vector2(
		(target_rect.size.x - draw_size.x) * align.x,
		(target_rect.size.y - draw_size.y) * align.y
	)
	draw_texture_rect(texture, Rect2(draw_pos, draw_size), false, modulate)


func _draw_fallback_gradient() -> void:
	var strips := 28
	for index in range(strips):
		var ratio := float(index) / float(strips - 1)
		var color := Palette.HARBOR_BACKDROP_SKY_TOP.lerp(Palette.HARBOR_BACKDROP_SEA_DEEP, ratio)
		draw_rect(Rect2(0.0, size.y * ratio, size.x, size.y / strips + 1.0), color)


func _draw_sun_glints() -> void:
	var water_y := size.y * 0.50
	for index in range(18):
		var x := fmod(float(index * 151) + _time * (18.0 + float(index % 4) * 2.6), size.x + 160.0) - 80.0
		var y := water_y + sin(_time * 0.75 + float(index) * 0.67) * 14.0 + float(index % 3) * 10.0
		var length := 34.0 + float(index % 5) * 18.0
		var alpha := 0.12 + 0.07 * sin(_time * 1.2 + float(index))
		draw_line(Vector2(x, y), Vector2(x + length, y + 2.0), Color(Palette.HARBOR_BACKDROP_GLINT, alpha), 2.0)


func _draw_harbor_air() -> void:
	for index in range(7):
		var x := fmod(float(index * 211) - _time * (10.0 + float(index % 3) * 2.0), size.x + 120.0) - 60.0
		var y := size.y * (0.18 + float(index % 3) * 0.055) + sin(_time * 0.32 + float(index)) * 4.0
		var scale := 0.65 + float(index % 4) * 0.14
		_draw_gull(Vector2(x, y), scale, Palette.HARBOR_BACKDROP_GULL)

	for index in range(9):
		var base_x := size.x * (0.18 + float(index) * 0.083)
		var y := size.y * (0.54 + float(index % 4) * 0.045)
		var pulse := 0.35 + 0.25 * sin(_time * 1.1 + float(index))
		draw_circle(Vector2(base_x, y), 1.4 + pulse, Palette.HARBOR_BACKDROP_AIR)


func _draw_gull(pos: Vector2, scale: float, color: Color) -> void:
	draw_line(pos, pos + Vector2(-10.0, 3.0) * scale, color, 1.6)
	draw_line(pos, pos + Vector2(10.0, 3.0) * scale, color, 1.6)


func _draw_edge_frame() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Palette.HARBOR_BACKDROP_FRAME, false, 6.0)
	draw_line(Vector2(0.0, 2.0), Vector2(size.x, 2.0), Palette.HARBOR_BACKDROP_TOP_LINE, 2.0)
