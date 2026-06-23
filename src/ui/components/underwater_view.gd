class_name UnderwaterView
extends Control

var simulator: FishingSimulator
var fish_data: Dictionary = {}
var _time: float = 0.0


func bind_simulator(value: FishingSimulator) -> void:
	simulator = value
	fish_data = simulator.fish_data
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(760, 290)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	_draw_water_background()
	_draw_seabed()
	_draw_background_fish()
	_draw_bubbles()
	if simulator == null or fish_data.is_empty():
		return
	_draw_line_and_bait()
	_draw_target_fish()


func _draw_water_background() -> void:
	var top_color := Color("#187fbd")
	var bottom_color := Color("#082c58")
	var strips := 18
	for index in range(strips):
		var ratio := float(index) / float(strips - 1)
		var strip_color := top_color.lerp(bottom_color, ratio)
		var strip_height := size.y / float(strips)
		draw_rect(Rect2(0.0, index * strip_height, size.x, strip_height + 1.0), strip_color)

	var ray_color := Color(0.75, 0.94, 1.0, 0.09)
	for index in range(6):
		var x := size.x * (0.08 + float(index) * 0.16)
		var sway := sin(_time * 0.35 + float(index)) * 28.0
		var points := PackedVector2Array(
			[
				Vector2(x - 18.0, 0.0),
				Vector2(x + 18.0, 0.0),
				Vector2(x + 95.0 + sway, size.y * 0.88),
				Vector2(x + 42.0 + sway, size.y * 0.88),
			]
		)
		draw_colored_polygon(points, ray_color)

	draw_line(Vector2(0.0, 4.0), Vector2(size.x, 4.0), Color(0.85, 0.98, 1.0, 0.65), 3.0)
	for index in range(11):
		var wave_y := 10.0 + float(index % 3) * 5.0
		var wave_x := float(index) * size.x / 10.0 + sin(_time + index) * 8.0
		draw_line(
			Vector2(wave_x - 24.0, wave_y),
			Vector2(wave_x + 24.0, wave_y),
			Color(0.75, 0.95, 1.0, 0.30),
			2.0
		)


func _draw_seabed() -> void:
	var base_y := size.y * 0.86
	var sand_points := PackedVector2Array(
		[
			Vector2(0.0, base_y + 10.0),
			Vector2(size.x * 0.15, base_y - 8.0),
			Vector2(size.x * 0.34, base_y + 5.0),
			Vector2(size.x * 0.52, base_y - 4.0),
			Vector2(size.x * 0.72, base_y + 8.0),
			Vector2(size.x, base_y - 6.0),
			Vector2(size.x, size.y),
			Vector2(0.0, size.y),
		]
	)
	draw_colored_polygon(sand_points, Color("#9ab68c"))

	for index in range(13):
		var px := fmod(float(index * 107 + 31), maxf(1.0, size.x))
		var py := base_y + 16.0 + float((index * 19) % 45)
		var radius := 3.0 + float(index % 4)
		draw_circle(Vector2(px, py), radius, Color("#6a806e"))

	_draw_rock(Vector2(size.x * 0.08, base_y - 4.0), 48.0)
	_draw_rock(Vector2(size.x * 0.93, base_y + 4.0), 62.0)
	_draw_rock(Vector2(size.x * 0.84, base_y + 12.0), 31.0)

	for index in range(8):
		var x := size.x * (0.14 + float(index) * 0.105)
		var height := 25.0 + float((index * 13) % 34)
		var sway := sin(_time * 1.4 + float(index)) * 4.0
		draw_line(
			Vector2(x, base_y + 10.0), Vector2(x + sway, base_y - height), Color("#2d816c"), 4.0
		)


func _draw_rock(center: Vector2, radius: float) -> void:
	draw_circle(center, radius, Color("#31525e"))
	draw_circle(center + Vector2(-radius * 0.18, -radius * 0.18), radius * 0.72, Color("#456c71"))
	draw_circle(
		center + Vector2(-radius * 0.28, -radius * 0.28),
		radius * 0.30,
		Color(0.45, 0.72, 0.70, 0.30)
	)


func _draw_background_fish() -> void:
	for index in range(9):
		var base_x := (
			fmod(_time * (8.0 + float(index)) + float(index) * 121.0, size.x + 100.0) - 50.0
		)
		var y := size.y * (0.18 + float(index % 4) * 0.11)
		var scale_value := 0.55 + float(index % 3) * 0.18
		_draw_small_fish(Vector2(base_x, y), scale_value, Color(0.02, 0.17, 0.28, 0.45))


func _draw_small_fish(center: Vector2, scale_value: float, color: Color) -> void:
	draw_circle(center, 8.0 * scale_value, color)
	var tail := PackedVector2Array(
		[
			center + Vector2(-7.0, 0.0) * scale_value,
			center + Vector2(-16.0, -8.0) * scale_value,
			center + Vector2(-16.0, 8.0) * scale_value,
		]
	)
	draw_colored_polygon(tail, color)


func _draw_bubbles() -> void:
	for index in range(22):
		var speed := 13.0 + float(index % 5) * 4.0
		var x := fmod(float(index * 83 + 17), maxf(1.0, size.x))
		x += sin(_time * 0.7 + float(index)) * 11.0
		var y := size.y - fmod(_time * speed + float(index * 37), size.y + 30.0)
		var radius := 1.5 + float(index % 4)
		draw_arc(Vector2(x, y), radius, 0.0, TAU, 12, Color(0.75, 0.95, 1.0, 0.48), 1.2)


func _draw_line_and_bait() -> void:
	var line_origin := Vector2(size.x * 0.78, -4.0)
	var bait_position := Vector2(
		size.x * 0.65, clampf(float(fish_data.get("start_depth", 8.0)) / 25.0, 0.30, 0.80) * size.y
	)
	if (
		simulator.state == FishingSimulator.State.FIGHT
		or simulator.state == FishingSimulator.State.CAUGHT
	):
		var fish_center := Vector2(
			simulator.visual_position.x * size.x, simulator.visual_position.y * size.y
		)
		var fish_scale := 1.35 if bool(fish_data.get("boss", false)) else 1.0
		bait_position = fish_center + Vector2(56.0 * fish_scale * simulator.visual_direction, 4.0)
	elif simulator.state == FishingSimulator.State.READY:
		bait_position = Vector2(size.x * 0.67, size.y * 0.22)

	draw_line(line_origin, bait_position, Color(0.92, 0.98, 1.0, 0.90), 2.0)
	draw_circle(bait_position, 6.0, Color("#e88b35"))
	draw_circle(bait_position + Vector2(3.0, -2.0), 2.0, Color("#ffd37a"))
	draw_arc(bait_position + Vector2(7.0, 5.0), 7.0, 0.2, 2.4, 12, Color("#d8e7ef"), 2.0)


func _draw_target_fish() -> void:
	var center := Vector2(
		simulator.visual_position.x * size.x, simulator.visual_position.y * size.y
	)
	var boss_scale := 1.42 if bool(fish_data.get("boss", false)) else 1.0
	var stamina_scale := lerpf(0.92, 1.04, simulator.fish_stamina_ratio())
	var scale_value := boss_scale * stamina_scale
	var direction := simulator.visual_direction
	var body_color := Color.from_string(String(fish_data.get("color", "#8aa7b5")), Color("#8aa7b5"))
	var dark_color := body_color.darkened(0.28)
	var light_color := body_color.lightened(0.20)

	var body_points := PackedVector2Array()
	for index in range(28):
		var angle := TAU * float(index) / 28.0
		var point := Vector2(cos(angle) * 78.0, sin(angle) * 39.0)
		point.x *= direction * scale_value
		point.y *= scale_value
		body_points.append(center + point)
	draw_colored_polygon(body_points, body_color)

	var tail_base := center + Vector2(-72.0 * direction * scale_value, 0.0)
	var tail := PackedVector2Array(
		[
			tail_base,
			tail_base + Vector2(-42.0 * direction, -31.0) * scale_value,
			tail_base + Vector2(-34.0 * direction, 0.0) * scale_value,
			tail_base + Vector2(-42.0 * direction, 31.0) * scale_value,
		]
	)
	draw_colored_polygon(tail, dark_color)

	var top_fin := PackedVector2Array(
		[
			center + Vector2(-24.0 * direction, -31.0) * scale_value,
			center + Vector2(2.0 * direction, -61.0) * scale_value,
			center + Vector2(31.0 * direction, -30.0) * scale_value,
		]
	)
	draw_colored_polygon(top_fin, dark_color)

	var side_fin := PackedVector2Array(
		[
			center + Vector2(4.0 * direction, 5.0) * scale_value,
			center + Vector2(-21.0 * direction, 31.0) * scale_value,
			center + Vector2(25.0 * direction, 18.0) * scale_value,
		]
	)
	draw_colored_polygon(side_fin, light_color)

	for index in range(5):
		var stripe_x := -35.0 + float(index) * 18.0
		var stripe_start := center + Vector2(stripe_x * direction, -26.0) * scale_value
		var stripe_end := center + Vector2((stripe_x + 5.0) * direction, 25.0) * scale_value
		draw_line(stripe_start, stripe_end, Color(dark_color, 0.46), 4.0 * scale_value)

	var eye_position := center + Vector2(48.0 * direction, -10.0) * scale_value
	draw_circle(eye_position, 7.0 * scale_value, Color("#f4d769"))
	draw_circle(eye_position + Vector2(1.5 * direction, 0.0), 3.2 * scale_value, Color("#101c25"))
	var mouth_start := center + Vector2(72.0 * direction, 7.0) * scale_value
	draw_line(
		mouth_start,
		mouth_start + Vector2(12.0 * direction, 2.0) * scale_value,
		Color("#152631"),
		2.2 * scale_value
	)
