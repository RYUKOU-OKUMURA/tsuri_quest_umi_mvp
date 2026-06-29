class_name TitleBackdrop
extends Control

const TITLE_BG_PATH := "res://assets/showcase/title/title_ocean_bg.png"
const TITLE_GRADE_PATH := "res://assets/showcase/title/title_color_grade.png"
const UNDERWATER_AMBIENCE_PATH := "res://assets/showcase/underwater/underwater_foreground_ambience.png"

var _time := 0.0
var _title_bg: Texture2D
var _title_grade: Texture2D
var _underwater_ambience: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_title_bg = _load_texture_if_exists(TITLE_BG_PATH)
	_title_grade = _load_texture_if_exists(TITLE_GRADE_PATH)
	_underwater_ambience = _load_texture_if_exists(UNDERWATER_AMBIENCE_PATH)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if _title_bg != null:
		_draw_cover_texture(_title_bg, rect, Color.WHITE, Vector2(0.5, 0.5))
	else:
		_draw_fallback_gradient()
	if _underwater_ambience != null:
		_draw_cover_texture(_underwater_ambience, rect, Color(1.0, 1.0, 1.0, 0.22), Vector2(0.5, 0.55))
	_draw_surface_glints()
	_draw_bubbles()
	_draw_drifting_fish()
	if _title_grade != null:
		_draw_cover_texture(_title_grade, rect, Color.WHITE, Vector2(0.5, 0.5))
	_draw_edge_frame()


func _load_texture_if_exists(path: String) -> Texture2D:
	if ResourceLoader.exists(path) or FileAccess.file_exists(path):
		return load(path) as Texture2D
	return null


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
	var strips := 26
	for index in range(strips):
		var ratio := float(index) / float(strips - 1)
		var color := Palette.SKY_TOP.lerp(Palette.SEA_DEEP, ratio)
		draw_rect(Rect2(0.0, size.y * ratio, size.x, size.y / strips + 1.0), color)


func _draw_surface_glints() -> void:
	var surface_y := size.y * 0.415
	for index in range(16):
		var x := fmod(float(index * 139) + _time * (16.0 + float(index % 5) * 1.7), size.x + 140.0) - 70.0
		var y := surface_y + sin(_time * 0.85 + float(index) * 0.58) * 8.0
		var length := 28.0 + float(index % 4) * 13.0
		var alpha := 0.16 + 0.08 * sin(_time * 1.7 + float(index))
		draw_line(Vector2(x, y), Vector2(x + length, y + sin(_time + index) * 2.0), Color(1.0, 0.96, 0.72, alpha), 2.0)

	for ray in range(7):
		var x := size.x * (0.10 + float(ray) * 0.13)
		var sway := sin(_time * 0.28 + float(ray)) * 18.0
		var points := PackedVector2Array(
			[
				Vector2(x - 18.0, size.y * 0.40),
				Vector2(x + 24.0, size.y * 0.40),
				Vector2(x + 76.0 + sway, size.y * 0.92),
				Vector2(x + 22.0 + sway, size.y * 0.92),
			]
		)
		draw_colored_polygon(points, Color(0.75, 0.98, 1.0, 0.055))


func _draw_bubbles() -> void:
	var columns: Array[float] = [0.075, 0.19, 0.63, 0.83, 0.94]
	for column in range(columns.size()):
		var base_x := size.x * columns[column]
		for index in range(9):
			var speed := 15.0 + float((index + column) % 5) * 4.2
			var y := size.y - fmod(_time * speed + float(index * 71 + column * 37), size.y * 0.66)
			if y < size.y * 0.42:
				continue
			var x := base_x + sin(_time * 0.45 + float(index) * 0.73) * (7.0 + column * 1.5)
			var radius := 1.8 + float(index % 4) * 0.8
			var alpha := 0.18 + float(index % 3) * 0.035
			draw_arc(Vector2(x, y), radius, 0.0, TAU, 12, Color(0.84, 0.98, 1.0, alpha), 1.0)
			if radius > 2.7:
				draw_circle(Vector2(x - radius * 0.30, y - radius * 0.30), 0.6, Color(1.0, 1.0, 1.0, alpha * 0.62))


func _draw_drifting_fish() -> void:
	for index in range(11):
		var row := index % 3
		var x := fmod(float(index * 173) - _time * (8.0 + float(row) * 2.1), size.x + 150.0) - 70.0
		var y := size.y * (0.53 + float(row) * 0.09) + sin(_time * 0.55 + float(index)) * 5.0
		var scale := 0.55 + float(index % 4) * 0.10
		var alpha := 0.10 + float(row) * 0.025
		_draw_small_fish(Vector2(x, y), scale, Color(0.0, 0.12, 0.18, alpha))


func _draw_small_fish(pos: Vector2, scale: float, color: Color) -> void:
	var body := PackedVector2Array(
		[
			pos + Vector2(-15.0, 0.0) * scale,
			pos + Vector2(-4.0, -6.0) * scale,
			pos + Vector2(13.0, -4.0) * scale,
			pos + Vector2(19.0, 0.0) * scale,
			pos + Vector2(13.0, 4.0) * scale,
			pos + Vector2(-4.0, 6.0) * scale,
		]
	)
	draw_colored_polygon(body, color)
	draw_colored_polygon(
		PackedVector2Array(
			[
				pos + Vector2(-16.0, 0.0) * scale,
				pos + Vector2(-27.0, -7.0) * scale,
				pos + Vector2(-24.0, 0.0) * scale,
				pos + Vector2(-27.0, 7.0) * scale,
			]
		),
		color
	)


func _draw_edge_frame() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.05, 0.10, 0.36), false, 6.0)
	draw_line(Vector2(0.0, 2.0), Vector2(size.x, 2.0), Color(1.0, 0.90, 0.55, 0.16), 2.0)
