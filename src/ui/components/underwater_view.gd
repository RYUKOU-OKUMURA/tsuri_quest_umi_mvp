class_name UnderwaterView
extends Control

const FightFontsScript = preload("res://src/ui/fight_fonts.gd")
const SHOWCASE_BG_PATH := "res://assets/showcase/underwater/underwater_battle_bg.png"
const SHOWCASE_COLOR_GRADE_PATH := "res://assets/showcase/underwater/underwater_color_grade.png"
const SHOWCASE_SEABED_DETAIL_PATH := "res://assets/showcase/underwater/underwater_seabed_detail.png"
const SHOWCASE_FG_AMBIENCE_PATH := "res://assets/showcase/underwater/underwater_foreground_ambience.png"
const SHOWCASE_FISH_SHEET_PATH := "res://assets/showcase/underwater/kurodai_showcase_sheet.png"
const SHOWCASE_HIT_BURST_PATH := "res://assets/showcase/underwater/hit_burst.png"
const SHOWCASE_FISH_FRAME_COUNT := 4

var simulator: FishingSimulator
var fish_data: Dictionary = {}
var _time: float = 0.0
var _last_state: int = -1
var _fish_flash: float = 0.0
var _badge_style: StyleBoxFlat
var _meter_track: StyleBoxFlat
var _meter_fill: StyleBoxFlat
var _showcase_bg: Texture2D
var _showcase_color_grade: Texture2D
var _showcase_seabed_detail: Texture2D
var _showcase_fg_ambience: Texture2D
var _showcase_fish_sheet: Texture2D
var _showcase_hit_burst: Texture2D


func bind_simulator(value: FishingSimulator) -> void:
	simulator = value
	fish_data = simulator.fish_data
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_load_showcase_assets()


func _process(delta: float) -> void:
	_time += delta
	_fish_flash = maxf(_fish_flash - delta * 3.0, 0.0)
	if simulator != null and simulator.state != _last_state:
		_on_view_state_changed(simulator.state)
		_last_state = simulator.state
	queue_redraw()


func _on_view_state_changed(state: int) -> void:
	# アワセ(FIGHT開始)と釣り上げで画面を揺らす
	if state == FishingSimulator.State.FIGHT or state == FishingSimulator.State.CAUGHT:
		Juicer.add_trauma(0.55)
		Juicer.hit_stop(0.05)
		_fish_flash = 1.0
	elif state == FishingSimulator.State.ESCAPED:
		# バラシ：弱めの揺れ＋短い停止で「逃した！」衝撃を演出
		Juicer.add_trauma(0.35)
		Juicer.hit_stop(0.04)


func _draw() -> void:
	draw_set_transform(Juicer.get_offset())
	if _showcase_bg != null:
		_draw_showcase_background()
		_draw_showcase_ambience()
	else:
		_draw_water_background()
	_draw_depth_scale()
	if _showcase_bg == null:
		_draw_seabed()
		_draw_background_fish()
	_draw_bubbles()
	if simulator == null or fish_data.is_empty():
		_draw_frame()
		return
	_draw_line_and_bait()
	_draw_target_fish()
	_draw_hit_burst()
	_draw_fight_overlay()
	_draw_frame()


func _load_showcase_assets() -> void:
	_showcase_bg = _load_texture_if_exists(SHOWCASE_BG_PATH)
	_showcase_color_grade = _load_texture_if_exists(SHOWCASE_COLOR_GRADE_PATH)
	_showcase_seabed_detail = _load_texture_if_exists(SHOWCASE_SEABED_DETAIL_PATH)
	_showcase_fg_ambience = _load_texture_if_exists(SHOWCASE_FG_AMBIENCE_PATH)
	_showcase_fish_sheet = _load_texture_if_exists(SHOWCASE_FISH_SHEET_PATH)
	_showcase_hit_burst = _load_texture_if_exists(SHOWCASE_HIT_BURST_PATH)


func _load_texture_if_exists(path: String) -> Texture2D:
	if ResourceLoader.exists(path) or FileAccess.file_exists(path):
		return load(path) as Texture2D
	return null


func _draw_showcase_background() -> void:
	_draw_cover_texture(_showcase_bg, Rect2(Vector2.ZERO, size), Color.WHITE)
	if _showcase_color_grade != null:
		_draw_cover_texture(_showcase_color_grade, Rect2(Vector2.ZERO, size), Color.WHITE)
	if _showcase_seabed_detail != null:
		_draw_cover_texture(_showcase_seabed_detail, Rect2(Vector2.ZERO, size), Color.WHITE)
	# 背景PNGに重ねる軽い水中の揺らぎ。主素材を邪魔しない密度に抑える。
	for index in range(6):
		var y := size.y * (0.12 + float(index) * 0.085)
		var x := fmod(_time * (8.0 + index) + float(index) * 121.0, size.x + 90.0) - 45.0
		draw_line(Vector2(x, y), Vector2(x + 34.0, y + sin(_time + index) * 2.0), Color(0.74, 0.94, 1.0, 0.13), 2.0)


func _draw_showcase_ambience() -> void:
	if _showcase_fg_ambience != null:
		_draw_cover_texture(_showcase_fg_ambience, Rect2(Vector2.ZERO, size), Color(1.0, 1.0, 1.0, 0.86))
	else:
		_draw_showcase_fish_schools()
		_draw_showcase_bubble_columns()
	_draw_showcase_light_specks()


func _draw_showcase_fish_schools() -> void:
	for index in range(18):
		var row := index % 3
		var col := index / 3
		var drift := fmod(_time * (5.0 + float(row) * 1.6) + float(col) * 42.0, size.x + 120.0)
		var x := size.x * 0.18 + drift - 80.0
		var y := size.y * (0.22 + float(row) * 0.075) + sin(_time * 0.7 + float(index)) * 3.0
		if x < 54.0 or x > size.x - 28.0:
			continue
		var scale_value := 0.42 + float((index + row) % 4) * 0.08
		var alpha := 0.16 + float(row) * 0.035
		_draw_small_fish(Vector2(x, y), scale_value, Color(0.01, 0.12, 0.22, alpha))


func _draw_showcase_bubble_columns() -> void:
	var column_ratios: Array[float] = [0.08, 0.18, 0.84, 0.93]
	for column in range(4):
		var base_x: float = size.x * column_ratios[column]
		for index in range(11):
			var speed := 10.0 + float((index + column) % 5) * 3.5
			var y := size.y - fmod(_time * speed + float(index * 43 + column * 61), size.y + 42.0)
			var x: float = base_x + sin(_time * 0.45 + float(index) * 0.8 + float(column)) * (9.0 + float(column % 2) * 5.0)
			var radius := 1.6 + float((index + column) % 4) * 0.75
			var alpha := 0.22 + float(index % 3) * 0.045
			draw_arc(Vector2(x, y), radius, 0.0, TAU, 12, Color(0.78, 0.96, 1.0, alpha), 1.0)
			if radius > 2.4:
				draw_circle(Vector2(x - radius * 0.30, y - radius * 0.30), 0.65, Color(1.0, 1.0, 1.0, alpha * 0.75))


func _draw_showcase_light_specks() -> void:
	for index in range(42):
		var x := 52.0 + fmod(float(index * 97 + 23), maxf(1.0, size.x - 80.0))
		var y := size.y * 0.10 + fmod(float(index * 53 + 11) + _time * (4.0 + float(index % 5)), size.y * 0.66)
		var pulse := 0.5 + 0.5 * sin(_time * 1.7 + float(index) * 0.9)
		var alpha := 0.08 + pulse * 0.11
		draw_circle(Vector2(x, y), 0.75 + float(index % 3) * 0.25, Color(0.84, 0.98, 1.0, alpha))
		if index % 9 == 0:
			draw_line(Vector2(x - 2.0, y), Vector2(x + 2.0, y), Color(0.90, 1.0, 1.0, alpha * 0.8), 1.0)


func _draw_cover_texture(texture: Texture2D, target_rect: Rect2, modulate: Color) -> void:
	if texture == null:
		return
	var tex_size := texture.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	var scale := maxf(target_rect.size.x / tex_size.x, target_rect.size.y / tex_size.y)
	var draw_size := tex_size * scale
	var draw_pos := target_rect.position + (target_rect.size - draw_size) * 0.5
	draw_texture_rect(texture, Rect2(draw_pos, draw_size), false, modulate)


func _draw_water_background() -> void:
	var top_color := Palette.SEA_SHALLOW
	var mid_color := Palette.SEA_MID
	var bottom_color := Palette.SEA_DEEP
	var strips := 20
	for index in range(strips):
		var ratio := float(index) / float(strips - 1)
		var strip_color := top_color.lerp(mid_color, clampf(ratio * 1.4, 0.0, 1.0))
		strip_color = strip_color.lerp(bottom_color, clampf((ratio - 0.35) / 0.65, 0.0, 1.0))
		var strip_height := size.y / float(strips)
		draw_rect(Rect2(0.0, index * strip_height, size.x, strip_height + 1.0), strip_color)

	var ray_color := Color(0.82, 0.97, 1.0, 0.15)
	for index in range(7):
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
	var panel_width := 44.0
	var panel_color := Color(0.02, 0.08, 0.16, 0.24)
	draw_rect(Rect2(0.0, 0.0, panel_width, size.y), panel_color)
	var divider_color := Color(0.55, 0.82, 0.95, 0.18)
	draw_line(Vector2(panel_width, 0.0), Vector2(panel_width, size.y), divider_color, 1.0)

	var font := FightFontsScript.regular(get_theme_default_font())
	var font_size := 12
	var max_depth := 25.0
	if not fish_data.is_empty():
		max_depth = maxf(float(fish_data.get("start_depth", 8.0)) + 12.0, 18.0)
	for depth_mark in [0, 5, 10, 15, 20]:
		if float(depth_mark) > max_depth + 2.0:
			continue
		var y := lerpf(28.0, size.y * 0.82, float(depth_mark) / max_depth)
		draw_line(
			Vector2(8.0, y), Vector2(panel_width - 7.0, y), Color(0.65, 0.86, 0.98, 0.18), 1.0
		)
		draw_string(
			font,
			Vector2(8.0, y - 3.0),
			"%dm" % depth_mark,
			HORIZONTAL_ALIGNMENT_LEFT,
			int(panel_width - 10.0),
			font_size,
			Color(0.82, 0.94, 1.0, 0.58)
		)

	if simulator != null and simulator.state == FishingSimulator.State.FIGHT:
		var current_y := lerpf(28.0, size.y * 0.82, clampf(simulator.depth / max_depth, 0.0, 1.0))
		var marker := Vector2(panel_width - 8.0, current_y)
		draw_circle(marker, 7.0, Color(1.0, 0.80, 0.40, 0.18))
		draw_circle(marker, 3.8, Color("#ffd37a"))
		draw_circle(marker, 1.8, Color("#fff3cf"))
		draw_string(
			font,
			Vector2(8.0, current_y + 4.0),
			"現 %.0fm" % simulator.depth,
			HORIZONTAL_ALIGNMENT_LEFT,
			int(panel_width - 10.0),
			font_size,
			Color("#ffe7a8", 0.78)
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
	draw_colored_polygon(sand_points, Palette.SAND)

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
		var fish_scale := 1.10 if bool(fish_data.get("boss", false)) else 1.0
		var forward_offset := 56.0 * fish_scale
		var vertical_offset := 4.0
		if _showcase_fish_sheet != null:
			var fish_draw_size := _showcase_fish_draw_size()
			forward_offset = fish_draw_size.x * 0.55
			vertical_offset = -fish_draw_size.y * 0.04
		bait_position = fish_center + Vector2(forward_offset * simulator.visual_direction, vertical_offset)
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
	if _showcase_fish_sheet != null:
		_draw_showcase_target_fish(center, scale_value, direction)
		return
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

	# ヒットフラッシュ（アワセ時など）
	if _fish_flash > 0.0:
		_draw_ellipse(center, rx, ry, Color(1.0, 1.0, 1.0, _fish_flash * 0.6))


func _draw_showcase_target_fish(center: Vector2, scale_value: float, direction: float) -> void:
	var frame_w := float(_showcase_fish_sheet.get_width()) / float(SHOWCASE_FISH_FRAME_COUNT)
	var frame_h := float(_showcase_fish_sheet.get_height())
	var draw_size := _showcase_fish_draw_size(scale_value)
	var frame_index := _showcase_fish_frame_index()
	var src := Rect2(frame_w * float(frame_index), 0.0, frame_w, frame_h)
	var dst := Rect2(-draw_size * 0.5, draw_size)

	_draw_ellipse(center + Vector2(0.0, draw_size.y * 0.30), draw_size.x * 0.34, draw_size.y * 0.11, Color(0.0, 0.0, 0.0, 0.18), 28)
	if simulator.state == FishingSimulator.State.FIGHT:
		draw_circle(center, draw_size.x * 0.34, Color(0.44, 0.89, 1.0, 0.10))

	draw_set_transform(Juicer.get_offset() + center, 0.0, Vector2(direction, 1.0))
	draw_texture_rect_region(_showcase_fish_sheet, dst, src, Color.WHITE)
	if _fish_flash > 0.0:
		draw_texture_rect_region(_showcase_fish_sheet, dst, src, Color(1.0, 1.0, 1.0, _fish_flash * 0.52))
	draw_set_transform(Juicer.get_offset())


func _showcase_fish_draw_size(scale_value := -1.0) -> Vector2:
	if _showcase_fish_sheet == null:
		return Vector2.ZERO
	var frame_w := float(_showcase_fish_sheet.get_width()) / float(SHOWCASE_FISH_FRAME_COUNT)
	var frame_h := float(_showcase_fish_sheet.get_height())
	var boss_ratio := 1.42 if bool(fish_data.get("boss", false)) else 1.0
	var effective_scale := scale_value
	if effective_scale < 0.0 and simulator != null:
		effective_scale = boss_ratio * lerpf(0.92, 1.04, simulator.fish_stamina_ratio())
	elif effective_scale < 0.0:
		effective_scale = boss_ratio
	var stamina_scale := clampf(effective_scale / boss_ratio, 0.90, 1.06)
	var target_width_ratio := 0.54 if bool(fish_data.get("boss", false)) else 0.55
	var draw_width := size.x * target_width_ratio * stamina_scale
	return Vector2(draw_width, draw_width * frame_h / frame_w)


func _showcase_fish_frame_index() -> int:
	if simulator.state == FishingSimulator.State.CAUGHT or simulator.state == FishingSimulator.State.ESCAPED:
		return 3
	if _fish_flash > 0.45:
		return 2
	match simulator.action_name:
		"突進", "潜水":
			return 2
		"休む":
			return 3
		"反転", "方向転換":
			return 1
		_:
			return int(floor(_time * 5.0)) % 2


func _draw_hit_burst() -> void:
	if _fish_flash <= 0.02 or simulator == null:
		return
	var alpha := clampf(_fish_flash, 0.0, 1.0)
	var burst_center := Vector2(size.x * 0.50, size.y * 0.835)
	if _showcase_hit_burst != null:
		var tex_size := _showcase_hit_burst.get_size()
		var scale := clampf(size.x / 1500.0, 0.42, 0.58)
		var draw_size := tex_size * scale
		var draw_rect := Rect2(burst_center - draw_size * 0.5, draw_size)
		draw_texture_rect(_showcase_hit_burst, draw_rect, false, Color(1.0, 1.0, 1.0, alpha))
	var font := FightFontsScript.bold(get_theme_default_font())
	var text := "ヒット！"
	var font_size := int(clampf(size.y * 0.16, 48.0, 76.0))
	var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
	var pos := burst_center + Vector2(-text_width * 0.5, font_size * 0.20)
	draw_string_outline(font, pos + Vector2(3.0, 4.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 8, Color(0.0, 0.0, 0.0, 0.58))
	draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 8, Color("#4d2408"))
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#ffe36e"))


func _draw_fight_overlay() -> void:
	if simulator.state != FishingSimulator.State.FIGHT:
		return

	var font := get_theme_default_font()

	# 水中画面は魚と背景を主役にし、詳細情報は右パネルとHUDに寄せる。
	var distance_ratio := clampf(
		simulator.distance / maxf(simulator.initial_distance, 0.01), 0.0, 1.0
	)
	var meter_rect := Rect2(68.0, size.y - 26.0, size.x - 84.0, 10.0)
	if _meter_track == null:
		_meter_track = StyleBoxFlat.new()
		_meter_track.bg_color = Color(0.02, 0.08, 0.14, 0.26)
		_meter_track.set_corner_radius_all(5)
		_meter_fill = StyleBoxFlat.new()
		_meter_fill.bg_color = Color(0.52, 0.94, 1.0, 0.58)
		_meter_fill.set_corner_radius_all(5)
	draw_style_box(_meter_track, meter_rect)
	if distance_ratio > 0.0:
		var fill_rect := Rect2(meter_rect.position, Vector2(meter_rect.size.x * distance_ratio, meter_rect.size.y))
		draw_style_box(_meter_fill, fill_rect)
		draw_rect(
			Rect2(fill_rect.position.x + 3.0, fill_rect.position.y + 1.5, fill_rect.size.x - 6.0, 1.5),
			Color(1.0, 1.0, 1.0, 0.38),
			false
		)
	var label_pos := Vector2(68.0, size.y - 30.0)
	draw_string_outline(font, label_pos, "距離 %.1fm" % simulator.distance, HORIZONTAL_ALIGNMENT_LEFT, int(size.x - 84.0), 12, 2, Color(0.0, 0.0, 0.0, 0.46))
	draw_string(font, label_pos, "距離 %.1fm" % simulator.distance, HORIZONTAL_ALIGNMENT_LEFT, int(size.x - 84.0), 12, Color(0.86, 0.96, 1.0, 0.72))


func _draw_frame() -> void:
	draw_rect(Rect2(0.0, 0.0, size.x, size.y), Color(0.01, 0.05, 0.12, 0.18), false, 2.0)
	for index in range(8):
		var alpha := 0.22 - float(index) * 0.025
		var inset := float(index) * 2.0
		var frame_rect := Rect2(inset, inset, size.x - inset * 2.0, size.y - inset * 2.0)
		draw_rect(frame_rect, Color(0.0, 0.03, 0.08, alpha), false, 1.0)
