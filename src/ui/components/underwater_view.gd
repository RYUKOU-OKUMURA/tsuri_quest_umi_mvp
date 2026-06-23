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

	var font := get_theme_default_font()
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
		var marker := Vector2(panel_width - 10.0, current_y)
		draw_circle(marker, 9.0, Color(1.0, 0.80, 0.40, 0.22))
		draw_circle(marker, 5.0, Color("#ffd37a"))
		draw_circle(marker, 2.4, Color("#fff3cf"))
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


func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color, points := 28) -> void:
	var arr := PackedVector2Array()
	arr.resize(points)
	for index in range(points):
		var angle := TAU * float(index) / float(points)
		arr[index] = center + Vector2(cos(angle) * rx, sin(angle) * ry)
	draw_colored_polygon(arr, color)


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
	var light_color := body_color.lightened(0.28)
	var dark_color := body_color.darkened(0.34)
	var darker_color := body_color.darkened(0.55)
	var belly_color := body_color.lightened(0.42)

	var rx := 78.0 * scale_value
	var ry := 39.0 * scale_value

	# テンション圏のオーラ
	if simulator.state == FishingSimulator.State.FIGHT:
		draw_circle(center, 94.0 * scale_value, Color(0.45, 0.88, 1.0, 0.10))

	# 尾びれ・背びれは胴体の奥に
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

	# 暗い縁取りで水中のコントラストを確保
	_draw_ellipse(center, rx + 4.0, ry + 4.0, darker_color)

	# 胴体：上下グラデーションの帯塗り（楕円クリップ相当）
	var bands := 26
	var band_h := (2.0 * ry) / float(bands)
	for index in range(bands):
		var t := (float(index) + 0.5) / float(bands)
		var yc := (t - 0.5) * 2.0 * ry
		var norm := t * 2.0 - 1.0
		var half := rx * sqrt(maxf(0.0, 1.0 - norm * norm))
		var col := light_color.lerp(dark_color, t)
		var top := center.y + yc - band_h * 0.5
		var bottom := center.y + yc + band_h * 0.5 + 1.0
		draw_colored_polygon(
			PackedVector2Array(
				[
					Vector2(center.x - half, top),
					Vector2(center.x + half, top),
					Vector2(center.x + half, bottom),
					Vector2(center.x - half, bottom),
				]
			),
			col
		)

	# 腹のハイライト
	_draw_ellipse(
		center + Vector2(6.0 * direction, 12.0) * scale_value,
		rx * 0.60,
		ry * 0.42,
		Color(belly_color, 0.50)
	)

	# 鱗ドット
	for row in range(2):
		for col in range(5):
			var sx := (-30.0 + float(col) * 14.0) * direction
			var sy := -16.0 + float(row) * 12.0
			draw_circle(
				center + Vector2(sx, sy) * scale_value, 2.6 * scale_value, Color(light_color, 0.22)
			)

	# 胸びれ（手前）
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
		draw_line(stripe_start, stripe_end, Color(dark_color, 0.42), 4.0 * scale_value)

	# エラ線
	var gill_pos := center + Vector2(30.0 * direction, -2.0) * scale_value
	draw_arc(gill_pos, 15.0 * scale_value, 1.15, 1.99, 10, Color(dark_color, 0.55), 2.2)

	# 目（強調ハイライト付き）
	var eye_position := center + Vector2(48.0 * direction, -10.0) * scale_value
	draw_circle(eye_position, 8.0 * scale_value, Color("#fff4cf"))
	draw_circle(eye_position, 6.0 * scale_value, Color("#23120a"))
	draw_circle(
		eye_position + Vector2(-2.2 * direction, -2.2) * scale_value,
		2.0 * scale_value,
		Color("#ffffff")
	)

	# 口
	var mouth_start := center + Vector2(70.0 * direction, 7.0) * scale_value
	draw_polyline(
		PackedVector2Array(
			[
				mouth_start,
				mouth_start + Vector2(7.0 * direction, 3.0) * scale_value,
				mouth_start + Vector2(14.0 * direction, 1.0) * scale_value,
			]
		),
		Color("#152631"),
		2.4 * scale_value,
		false
	)


func _draw_fight_overlay() -> void:
	if simulator.state != FishingSimulator.State.FIGHT:
		return

	var font := get_theme_default_font()

	# 魚名バッジ：角丸＋影＋金縁
	var badge_width := minf(240.0, size.x * 0.30)
	var badge_rect := Rect2(size.x - badge_width - 14.0, 12.0, badge_width, 58.0)
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(0.04, 0.12, 0.22, 0.84)
	badge_style.border_color = Color("#d1aa63")
	badge_style.set_border_width_all(2)
	badge_style.set_corner_radius_all(10)
	badge_style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	badge_style.shadow_size = 8
	draw_style_box(badge_style, badge_rect)

	var fish_name := String(fish_data.get("name", "魚"))
	var name_pos := badge_rect.position + Vector2(12.0, 23.0)
	var name_w := int(badge_rect.size.x - 24.0)
	draw_string_outline(font, name_pos, fish_name, HORIZONTAL_ALIGNMENT_LEFT, name_w, 16, 3, Color(0.0, 0.0, 0.0, 0.6))
	draw_string(font, name_pos, fish_name, HORIZONTAL_ALIGNMENT_LEFT, name_w, 16, Color("#ffe7a8"))
	var action_pos := badge_rect.position + Vector2(12.0, 43.0)
	draw_string_outline(font, action_pos, "行動：%s" % simulator.action_name, HORIZONTAL_ALIGNMENT_LEFT, name_w, 13, 2, Color(0.0, 0.0, 0.0, 0.55))
	draw_string(font, action_pos, "行動：%s" % simulator.action_name, HORIZONTAL_ALIGNMENT_LEFT, name_w, 13, Color("#d8ecff"))

	# 距離メーター：丸端のトラック＋塗り＋グロー
	var distance_ratio := clampf(
		simulator.distance / maxf(simulator.initial_distance, 0.01), 0.0, 1.0
	)
	var meter_rect := Rect2(68.0, size.y - 26.0, size.x - 84.0, 10.0)
	var track_style := StyleBoxFlat.new()
	track_style.bg_color = Color(0.02, 0.08, 0.14, 0.6)
	track_style.set_corner_radius_all(5)
	draw_style_box(track_style, meter_rect)
	if distance_ratio > 0.0:
		var fill_style := StyleBoxFlat.new()
		fill_style.bg_color = Color(0.45, 0.88, 1.0, 0.9)
		fill_style.set_corner_radius_all(5)
		var fill_rect := Rect2(meter_rect.position, Vector2(meter_rect.size.x * distance_ratio, meter_rect.size.y))
		draw_style_box(fill_style, fill_rect)
		draw_rect(
			Rect2(fill_rect.position.x + 3.0, fill_rect.position.y + 1.5, fill_rect.size.x - 6.0, 1.5),
			Color(1.0, 1.0, 1.0, 0.6),
			false
		)
	var label_pos := Vector2(68.0, size.y - 30.0)
	draw_string_outline(font, label_pos, "距離 %.1fm" % simulator.distance, HORIZONTAL_ALIGNMENT_LEFT, int(size.x - 84.0), 13, 2, Color(0.0, 0.0, 0.0, 0.6))
	draw_string(font, label_pos, "距離 %.1fm" % simulator.distance, HORIZONTAL_ALIGNMENT_LEFT, int(size.x - 84.0), 13, Color(0.86, 0.96, 1.0, 0.95))


func _draw_frame() -> void:
	draw_rect(Rect2(0.0, 0.0, size.x, size.y), Color(0.01, 0.05, 0.12, 0.18), false, 2.0)
	for index in range(8):
		var alpha := 0.22 - float(index) * 0.025
		var inset := float(index) * 2.0
		var frame_rect := Rect2(inset, inset, size.x - inset * 2.0, size.y - inset * 2.0)
		draw_rect(frame_rect, Color(0.0, 0.03, 0.08, alpha), false, 1.0)
