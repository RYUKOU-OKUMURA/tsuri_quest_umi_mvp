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
	clip_contents = true


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	_draw_water_background()
	_draw_depth_scale()
	_draw_seabed()
	_draw_background_fish()
	_draw_bubbles()
	if simulator == null or fish_data.is_empty():
		_draw_frame()
		return
	_draw_line_and_bait()
	_draw_target_fish()
	_draw_fight_overlay()
	_draw_frame()


func _draw_water_background() -> void:
	var top_color := Color("#1a8fd0")
	var mid_color := Color("#0e5f9c")
	var bottom_color := Color("#062847")
	var strips := 20
	for index in range(strips):
		var ratio := float(index) / float(strips - 1)
		var strip_color := top_color.lerp(mid_color, clampf(ratio * 1.4, 0.0, 1.0))
		strip_color = strip_color.lerp(bottom_color, clampf((ratio - 0.35) / 0.65, 0.0, 1.0))
		var strip_height := size.y / float(strips)
		draw_rect(Rect2(0.0, index * strip_height, size.x, strip_height + 1.0), strip_color)

	var ray_color := Color(0.78, 0.95, 1.0, 0.11)
	for index in range(5):
		var x := size.x * (0.10 + float(index) * 0.18)
		var sway := sin(_time * 0.35 + float(index)) * 22.0
		var points := PackedVector2Array(
			[
				Vector2(x - 14.0, 0.0),
				Vector2(x + 14.0, 0.0),
				Vector2(x + 78.0 + sway, size.y * 0.86),
				Vector2(x + 34.0 + sway, size.y * 0.86),
			]
		)
		draw_colored_polygon(points, ray_color)

	draw_line(Vector2(0.0, 3.0), Vector2(size.x, 3.0), Color(0.88, 0.98, 1.0, 0.72), 3.0)
	for index in range(9):
		var wave_y := 8.0 + float(index % 3) * 4.0
		var wave_x := float(index) * size.x / 8.0 + sin(_time + index) * 6.0
		draw_line(
			Vector2(wave_x - 20.0, wave_y),
			Vector2(wave_x + 20.0, wave_y),
			Color(0.78, 0.95, 1.0, 0.28),
			2.0
		)


func _draw_depth_scale() -> void:
	var panel_width := 54.0
	var panel_color := Color(0.02, 0.08, 0.16, 0.42)
	draw_rect(Rect2(0.0, 0.0, panel_width, size.y), panel_color)
	var divider_color := Color(0.55, 0.82, 0.95, 0.35)
	draw_line(Vector2(panel_width, 0.0), Vector2(panel_width, size.y), divider_color, 1.0)

	var font := ThemeDB.fallback_font
	var font_size := 13
	var max_depth := 25.0
	if not fish_data.is_empty():
		max_depth = maxf(float(fish_data.get("start_depth", 8.0)) + 12.0, 18.0)
	for depth_mark in [0, 5, 10, 15, 20]:
		if float(depth_mark) > max_depth + 2.0:
			continue
		var y := lerpf(28.0, size.y * 0.82, float(depth_mark) / max_depth)
		draw_line(
			Vector2(8.0, y), Vector2(panel_width - 6.0, y), Color(0.65, 0.86, 0.98, 0.35), 1.0
		)
		draw_string(
			font,
			Vector2(10.0, y - 3.0),
			"%dm" % depth_mark,
			HORIZONTAL_ALIGNMENT_LEFT,
			int(panel_width - 12.0),
			font_size,
			Color(0.82, 0.94, 1.0, 0.82)
		)

	if simulator != null and simulator.state == FishingSimulator.State.FIGHT:
		var current_y := lerpf(28.0, size.y * 0.82, clampf(simulator.depth / max_depth, 0.0, 1.0))
		draw_circle(Vector2(panel_width - 10.0, current_y), 4.0, Color("#ffd37a"))
		draw_string(
			font,
			Vector2(10.0, current_y + 4.0),
			"現 %.0fm" % simulator.depth,
			HORIZONTAL_ALIGNMENT_LEFT,
			int(panel_width - 12.0),
			font_size,
			Color("#ffe7a8")
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
	for index in range(7):
		var base_x := (
			fmod(_time * (8.0 + float(index)) + float(index) * 121.0, size.x + 100.0) - 50.0
		)
		var y := size.y * (0.20 + float(index % 4) * 0.12)
		if base_x < 62.0:
			continue
		var scale_value := 0.55 + float(index % 3) * 0.18
		_draw_small_fish(Vector2(base_x, y), scale_value, Color(0.02, 0.17, 0.28, 0.38))


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
	for index in range(18):
		var speed := 13.0 + float(index % 5) * 4.0
		var x := 62.0 + fmod(float(index * 83 + 17), maxf(1.0, size.x - 62.0))
		x += sin(_time * 0.7 + float(index)) * 9.0
		var y := size.y - fmod(_time * speed + float(index * 37), size.y + 30.0)
		var radius := 1.5 + float(index % 4)
		draw_arc(Vector2(x, y), radius, 0.0, TAU, 12, Color(0.75, 0.95, 1.0, 0.42), 1.2)


func _draw_line_and_bait() -> void:
	var line_origin := Vector2(size.x * 0.82, 2.0)
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

	draw_line(line_origin, bait_position, Color(0.92, 0.98, 1.0, 0.88), 2.0)
	draw_circle(bait_position, 6.0, Color("#e88b35"))
	draw_circle(bait_position + Vector2(3.0, -2.0), 2.0, Color("#ffd37a"))
	draw_arc(bait_position + Vector2(7.0, 5.0), 7.0, 0.2, 2.4, 12, Color("#d8e7ef"), 2.0)


func _draw_target_fish() -> void:
	if simulator.state == FishingSimulator.State.READY:
		return
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

	if simulator.state == FishingSimulator.State.FIGHT:
		draw_circle(center, 92.0 * scale_value, Color(0.45, 0.88, 1.0, 0.10))

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


func _draw_fight_overlay() -> void:
	if simulator.state != FishingSimulator.State.FIGHT:
		return

	var badge_width := minf(220.0, size.x * 0.28)
	var badge_rect := Rect2(size.x - badge_width - 14.0, 12.0, badge_width, 54.0)
	draw_rect(badge_rect, Color(0.03, 0.10, 0.18, 0.72))
	draw_rect(badge_rect, Color(0.55, 0.82, 0.95, 0.45), false, 2.0)

	var font := ThemeDB.fallback_font
	var fish_name := String(fish_data.get("name", "魚"))
	draw_string(
		font,
		badge_rect.position + Vector2(10.0, 22.0),
		fish_name,
		HORIZONTAL_ALIGNMENT_LEFT,
		int(badge_rect.size.x - 20.0),
		15,
		Color("#ffe7a8")
	)
	draw_string(
		font,
		badge_rect.position + Vector2(10.0, 42.0),
		"行動：%s" % simulator.action_name,
		HORIZONTAL_ALIGNMENT_LEFT,
		int(badge_rect.size.x - 20.0),
		13,
		Color("#d8ecff")
	)

	var distance_ratio := clampf(
		simulator.distance / maxf(simulator.initial_distance, 0.01), 0.0, 1.0
	)
	var meter_rect := Rect2(68.0, size.y - 24.0, size.x - 84.0, 8.0)
	draw_rect(meter_rect, Color(0.02, 0.08, 0.14, 0.55))
	draw_rect(
		Rect2(
			meter_rect.position.x, meter_rect.position.y, meter_rect.size.x * distance_ratio, 8.0
		),
		Color(0.45, 0.88, 1.0, 0.75)
	)
	draw_string(
		font,
		Vector2(68.0, size.y - 28.0),
		"距離 %.1fm" % simulator.distance,
		HORIZONTAL_ALIGNMENT_LEFT,
		int(size.x - 84.0),
		12,
		Color(0.82, 0.94, 1.0, 0.85)
	)


func _draw_frame() -> void:
	draw_rect(Rect2(0.0, 0.0, size.x, size.y), Color(0.01, 0.05, 0.12, 0.18), false, 2.0)
	for index in range(8):
		var alpha := 0.22 - float(index) * 0.025
		var inset := float(index) * 2.0
		var frame_rect := Rect2(inset, inset, size.x - inset * 2.0, size.y - inset * 2.0)
		draw_rect(frame_rect, Color(0.0, 0.03, 0.08, alpha), false, 1.0)
