class_name FishingSpotMapView
extends Control

signal spot_focused(spot_id: String)
signal spot_selected(spot_id: String)
signal locked_spot_pressed(spot_id: String)

const GameFontsScript = preload("res://src/ui/game_fonts.gd")

const MAP_BG_PATH := "res://assets/showcase/fishing_spots/map_bg.png"
const MAP_GRADE_PATH := "res://assets/showcase/fishing_spots/map_color_grade.png"
const MARKER_SHEET_PATH := "res://assets/showcase/fishing_spots/map_marker_sheet.png"
const SPOT_MARKER_SHEET_PATH := "res://assets/showcase/fishing_spots/map_spot_marker_sheet.png"
const MARKER_CELL_SIZE := 128.0

const MARKER_NORMAL := 0
const MARKER_SELECTED := 1
const MARKER_LOCKED := 2
const MARKER_BOSS := 3

const SPOT_MARKER_ORDER := [
	"harbor_pier",
	"shallow_sand",
	"rock_breakwater",
	"outer_tide",
	"south_reef",
	"bluewater_route",
	"deep_ocean",
	"danger_reef",
	"harbor_boulder",
]

const SPOT_POINTS := {
	"harbor_pier": Vector2(0.255, 0.505),
	"shallow_sand": Vector2(0.330, 0.335),
	"rock_breakwater": Vector2(0.455, 0.500),
	"outer_tide": Vector2(0.620, 0.300),
	"south_reef": Vector2(0.300, 0.735),
	"bluewater_route": Vector2(0.700, 0.525),
	"deep_ocean": Vector2(0.765, 0.770),
	"danger_reef": Vector2(0.870, 0.435),
	"harbor_boulder": Vector2(0.435, 0.620),
}

const LABEL_OFFSETS := {
	"harbor_pier": Vector2(0.0, 46.0),
	"shallow_sand": Vector2(-88.0, -34.0),
	"rock_breakwater": Vector2(96.0, 8.0),
	"outer_tide": Vector2(0.0, 48.0),
	"south_reef": Vector2(-70.0, 50.0),
	"bluewater_route": Vector2(0.0, 50.0),
	"deep_ocean": Vector2(0.0, 50.0),
	"danger_reef": Vector2(-84.0, -52.0),
	"harbor_boulder": Vector2(86.0, 32.0),
}

const ROUTES := [
	["harbor_pier", "shallow_sand"],
	["harbor_pier", "rock_breakwater"],
	["rock_breakwater", "outer_tide"],
	["harbor_pier", "south_reef"],
	["harbor_pier", "harbor_boulder"],
	["outer_tide", "bluewater_route"],
	["bluewater_route", "deep_ocean"],
	["bluewater_route", "danger_reef"],
]

const ROUTE_PATHS := {
	"harbor_pier": [],
	"shallow_sand": [["harbor_pier", "shallow_sand"]],
	"rock_breakwater": [["harbor_pier", "rock_breakwater"]],
	"outer_tide": [["harbor_pier", "rock_breakwater"], ["rock_breakwater", "outer_tide"]],
	"south_reef": [["harbor_pier", "south_reef"]],
	"bluewater_route": [["harbor_pier", "rock_breakwater"], ["rock_breakwater", "outer_tide"], ["outer_tide", "bluewater_route"]],
	"deep_ocean": [["harbor_pier", "rock_breakwater"], ["rock_breakwater", "outer_tide"], ["outer_tide", "bluewater_route"], ["bluewater_route", "deep_ocean"]],
	"danger_reef": [["harbor_pier", "rock_breakwater"], ["rock_breakwater", "outer_tide"], ["outer_tide", "bluewater_route"], ["bluewater_route", "danger_reef"]],
	"harbor_boulder": [["harbor_pier", "harbor_boulder"]],
}

var player_level := 1
var selected_spot_id := GameData.DEFAULT_FISHING_SPOT_ID

var _map_bg: Texture2D
var _map_grade: Texture2D
var _marker_sheet: Texture2D
var _spot_marker_sheet: Texture2D
var _hovered_spot_id := ""
var _animation_time := 0.0
var _redraw_accumulator := 0.0


func configure(initial_spot_id: String, level: int) -> void:
	selected_spot_id = initial_spot_id
	player_level = level
	queue_redraw()


func set_selected_spot(spot_id: String) -> void:
	selected_spot_id = spot_id
	queue_redraw()


func set_player_level(level: int) -> void:
	player_level = level
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_map_bg = ShowcaseAssets.load_texture(MAP_BG_PATH)
	_map_grade = ShowcaseAssets.load_texture(MAP_GRADE_PATH)
	_marker_sheet = ShowcaseAssets.load_texture(MARKER_SHEET_PATH)
	_spot_marker_sheet = ShowcaseAssets.load_texture(SPOT_MARKER_SHEET_PATH)


func _process(delta: float) -> void:
	_animation_time = fmod(_animation_time + delta, 60.0)
	if not is_visible_in_tree():
		return
	_redraw_accumulator += delta
	if _redraw_accumulator >= 1.0 / 24.0:
		_redraw_accumulator = 0.0
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		var hover_id := _spot_at_position(motion.position)
		if hover_id != _hovered_spot_id:
			_hovered_spot_id = hover_id
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not hover_id.is_empty() else Control.CURSOR_ARROW
			queue_redraw()
		return
	if not event is InputEventMouseButton:
		return
	var mouse := event as InputEventMouseButton
	if mouse.button_index != MOUSE_BUTTON_LEFT or not mouse.pressed:
		return
	var spot_id := _spot_at_position(mouse.position)
	if spot_id.is_empty():
		return
	spot_focused.emit(spot_id)
	if _spot_accessible(spot_id):
		spot_selected.emit(spot_id)
	else:
		locked_spot_pressed.emit(spot_id)
	accept_event()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	draw_rect(rect, Palette.MAP_CANVAS_BG, true)
	var map_rect := _content_rect()
	if _map_bg != null:
		draw_texture_rect_region(_map_bg, map_rect, _texture_source_region(_map_bg), Color.WHITE)
	else:
		draw_rect(map_rect, Palette.MAP_CANVAS_FALLBACK, true)
	if _map_grade != null:
		draw_texture_rect_region(_map_grade, map_rect, _texture_source_region(_map_grade), Color(Color.WHITE, 0.70))
	_draw_chart_overlay(map_rect)
	_draw_depth_contours(map_rect)
	_draw_environment_symbols(map_rect)
	_draw_routes(map_rect)
	_draw_markers(map_rect)
	_draw_edge_shade(map_rect)
	draw_rect(map_rect, Color(Palette.MAP_CHART_BORDER, 0.52), false, 2.0)


func _draw_chart_overlay(map_rect: Rect2) -> void:
	var grid_color := Color(Palette.MAP_GRID, 0.075)
	for index in range(1, 8):
		var x := map_rect.position.x + map_rect.size.x * float(index) / 8.0
		draw_line(Vector2(x, map_rect.position.y + 8.0), Vector2(x, map_rect.end.y - 8.0), grid_color, 1.0)
	for index in range(1, 5):
		var y := map_rect.position.y + map_rect.size.y * float(index) / 5.0
		draw_line(Vector2(map_rect.position.x + 8.0, y), Vector2(map_rect.end.x - 8.0, y), grid_color, 1.0)

	var tick_color := Color(Palette.MAP_TICK, 0.30)
	for index in range(0, 17):
		var x := map_rect.position.x + map_rect.size.x * float(index) / 16.0
		draw_line(Vector2(x, map_rect.position.y), Vector2(x, map_rect.position.y + 9.0), tick_color, 1.0)
		draw_line(Vector2(x, map_rect.end.y - 9.0), Vector2(x, map_rect.end.y), tick_color, 1.0)
	for index in range(0, 10):
		var y := map_rect.position.y + map_rect.size.y * float(index) / 9.0
		draw_line(Vector2(map_rect.position.x, y), Vector2(map_rect.position.x + 9.0, y), tick_color, 1.0)
		draw_line(Vector2(map_rect.end.x - 9.0, y), Vector2(map_rect.end.x, y), tick_color, 1.0)

	var rose_center := map_rect.position + Vector2(map_rect.size.x * 0.895, map_rect.size.y * 0.155)
	var rose_r := clampf(map_rect.size.x * 0.043, 28.0, 42.0)
	draw_circle(rose_center, rose_r, Color(Palette.MAP_COMPASS_WASH, 0.24))
	draw_circle(rose_center, rose_r, Color(Palette.MAP_COMPASS_GOLD, 0.28), false, 1.5)
	draw_line(rose_center + Vector2(0.0, -rose_r * 0.90), rose_center + Vector2(0.0, rose_r * 0.90), Color(Palette.MAP_COMPASS_GOLD, 0.36), 1.4)
	draw_line(rose_center + Vector2(-rose_r * 0.90, 0.0), rose_center + Vector2(rose_r * 0.90, 0.0), Color(Palette.MAP_COMPASS_GOLD, 0.30), 1.2)
	draw_colored_polygon(
		PackedVector2Array([
			rose_center + Vector2(0.0, -rose_r * 0.82),
			rose_center + Vector2(-rose_r * 0.16, -rose_r * 0.10),
			rose_center + Vector2(rose_r * 0.16, -rose_r * 0.10),
		]),
		Color(Palette.MAP_COMPASS_NORTH, 0.50)
	)
	draw_colored_polygon(
		PackedVector2Array([
			rose_center + Vector2(0.0, rose_r * 0.82),
			rose_center + Vector2(-rose_r * 0.14, rose_r * 0.10),
			rose_center + Vector2(rose_r * 0.14, rose_r * 0.10),
		]),
		Color(Palette.MAP_COMPASS_SOUTH, 0.35)
	)


func _draw_edge_shade(map_rect: Rect2) -> void:
	var edge := 26.0
	draw_rect(Rect2(map_rect.position, Vector2(map_rect.size.x, edge)), Color(Palette.MAP_OVERLAY_DARK, 0.22), true)
	draw_rect(Rect2(Vector2(map_rect.position.x, map_rect.end.y - edge), Vector2(map_rect.size.x, edge)), Color(Palette.MAP_OVERLAY_DARK, 0.24), true)
	draw_rect(Rect2(map_rect.position, Vector2(edge, map_rect.size.y)), Color(Palette.MAP_OVERLAY_DARK, 0.20), true)
	draw_rect(Rect2(Vector2(map_rect.end.x - edge, map_rect.position.y), Vector2(edge, map_rect.size.y)), Color(Palette.MAP_OVERLAY_DARK, 0.20), true)


func _draw_depth_contours(map_rect: Rect2) -> void:
	var shallow := Color(Palette.MAP_CONTOUR_SHALLOW, 0.20)
	var reef := Color(Palette.MAP_CONTOUR_REEF, 0.16)
	var ocean := Color(Palette.MAP_CONTOUR_OCEAN, 0.12)
	_draw_contour(
		map_rect,
		[
			Vector2(0.135, 0.175),
			Vector2(0.255, 0.145),
			Vector2(0.375, 0.230),
			Vector2(0.455, 0.360),
			Vector2(0.420, 0.505),
			Vector2(0.300, 0.615),
			Vector2(0.155, 0.565),
		],
		shallow,
		1.4
	)
	_draw_contour(
		map_rect,
		[
			Vector2(0.185, 0.235),
			Vector2(0.305, 0.225),
			Vector2(0.405, 0.315),
			Vector2(0.395, 0.440),
			Vector2(0.275, 0.515),
			Vector2(0.175, 0.470),
		],
		Color(Palette.MAP_CONTOUR_INNER, 0.16),
		1.0
	)
	_draw_contour(
		map_rect,
		[
			Vector2(0.185, 0.690),
			Vector2(0.315, 0.630),
			Vector2(0.425, 0.690),
			Vector2(0.392, 0.810),
			Vector2(0.238, 0.835),
		],
		reef,
		1.2
	)
	_draw_contour(
		map_rect,
		[
			Vector2(0.565, 0.245),
			Vector2(0.650, 0.185),
			Vector2(0.760, 0.245),
			Vector2(0.800, 0.390),
			Vector2(0.742, 0.555),
			Vector2(0.645, 0.610),
		],
		ocean,
		1.1
	)
	_draw_contour(
		map_rect,
		[
			Vector2(0.735, 0.615),
			Vector2(0.825, 0.690),
			Vector2(0.885, 0.810),
			Vector2(0.820, 0.915),
			Vector2(0.710, 0.850),
		],
		ocean,
		1.0
	)


func _draw_contour(map_rect: Rect2, normalized_points: Array, color: Color, width: float) -> void:
	var points := PackedVector2Array()
	for point in normalized_points:
		points.append(_map_normalized_point(map_rect, point))
	if points.size() >= 2:
		draw_polyline(points, color, width, true)


func _draw_environment_symbols(map_rect: Rect2) -> void:
	var font := GameFontsScript.bold(get_theme_default_font())
	_draw_tide_stream(
		map_rect,
		[
			Vector2(0.555, 0.245),
			Vector2(0.615, 0.190),
			Vector2(0.705, 0.215),
			Vector2(0.768, 0.330),
		],
		Color(Palette.MAP_CURRENT_BLUE, 0.23),
		1.6
	)
	_draw_tide_stream(
		map_rect,
		[
			Vector2(0.620, 0.465),
			Vector2(0.706, 0.515),
			Vector2(0.765, 0.650),
			Vector2(0.840, 0.780),
		],
		Color(Palette.MAP_CURRENT_GOLD, 0.26),
		1.8
	)
	_draw_tide_stream(
		map_rect,
		[
			Vector2(0.160, 0.620),
			Vector2(0.255, 0.675),
			Vector2(0.395, 0.675),
			Vector2(0.462, 0.590),
		],
		Color(Palette.MAP_CURRENT_GREEN, 0.18),
		1.2
	)
	_draw_reef_marks(map_rect, [Vector2(0.260, 0.700), Vector2(0.315, 0.755), Vector2(0.370, 0.715)], Color(Palette.MAP_REEF_MARK, 0.30))
	_draw_reef_marks(map_rect, [Vector2(0.430, 0.465), Vector2(0.480, 0.520), Vector2(0.405, 0.590)], Color(Palette.MAP_REEF_MARK_WARM, 0.28))
	_draw_depth_label(font, map_rect, "5m", Vector2(0.270, 0.245), Color(Palette.MAP_CONTOUR_INNER, 0.35))
	_draw_depth_label(font, map_rect, "10m", Vector2(0.540, 0.340), Color(Palette.MAP_DEPTH_LABEL, 0.28))
	_draw_depth_label(font, map_rect, "20m", Vector2(0.750, 0.455), Color(Palette.MAP_DEPTH_LABEL, 0.28))
	_draw_depth_label(font, map_rect, "潮流", Vector2(0.690, 0.235), Color(Palette.MAP_DEPTH_LABEL, 0.32))
	_draw_depth_label(font, map_rect, "岩礁帯", Vector2(0.325, 0.815), Color(Palette.MAP_DEPTH_LABEL_REEF, 0.30))


func _draw_tide_stream(map_rect: Rect2, normalized_points: Array, color: Color, width: float) -> void:
	var points := PackedVector2Array()
	for point in normalized_points:
		points.append(_map_normalized_point(map_rect, point))
	if points.size() < 2:
		return
	draw_polyline(points, Color(Color.BLACK, color.a * 0.28), width + 2.0, false)
	draw_polyline(points, color, width, false)
	for index in range(points.size() - 1):
		var from_point := points[index]
		var to_point := points[index + 1]
		if from_point.distance_to(to_point) < 18.0:
			continue
		_draw_current_arrow(from_point.lerp(to_point, 0.58), to_point - from_point, color)


func _draw_current_arrow(center: Vector2, direction_delta: Vector2, color: Color) -> void:
	var length := direction_delta.length()
	if length <= 0.0:
		return
	var direction := direction_delta / length
	var normal := Vector2(-direction.y, direction.x)
	var tip := center + direction * 8.0
	var tail := center - direction * 5.0
	draw_line(tail, tip, color, 1.3)
	draw_line(tip, tip - direction * 6.0 + normal * 4.0, color, 1.2)
	draw_line(tip, tip - direction * 6.0 - normal * 4.0, color, 1.2)


func _draw_reef_marks(map_rect: Rect2, normalized_points: Array, color: Color) -> void:
	for point in normalized_points:
		var center := _map_normalized_point(map_rect, point)
		var size_a := 7.0
		var size_b := 4.0
		draw_line(center + Vector2(-size_a, -size_b), center + Vector2(size_a, size_b), Color(Color.BLACK, color.a * 0.35), 2.1)
		draw_line(center + Vector2(-size_a, size_b), center + Vector2(size_a, -size_b), Color(Color.BLACK, color.a * 0.35), 2.1)
		draw_line(center + Vector2(-size_a, -size_b), center + Vector2(size_a, size_b), color, 1.0)
		draw_line(center + Vector2(-size_a, size_b), center + Vector2(size_a, -size_b), color, 1.0)


func _draw_depth_label(font: Font, map_rect: Rect2, text: String, normalized: Vector2, color: Color) -> void:
	var font_size := 12
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var pos := _map_normalized_point(map_rect, normalized)
	var baseline := pos + Vector2(-text_size.x * 0.5, text_size.y * 0.35)
	draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 2, Color(Color.BLACK, color.a * 0.45))
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw_routes(map_rect: Rect2) -> void:
	var selected_path := _selected_route_key_map()
	for pair in ROUTES:
		var from_id := String(pair[0])
		var to_id := String(pair[1])
		if not SPOT_POINTS.has(from_id) or not SPOT_POINTS.has(to_id):
			continue
		var from_point := _map_point(map_rect, from_id)
		var to_point := _map_point(map_rect, to_id)
		var selected_route := bool(selected_path.get(_route_key(from_id, to_id), false))
		if selected_spot_id == GameData.DEFAULT_FISHING_SPOT_ID:
			selected_route = from_id == selected_spot_id or to_id == selected_spot_id
		var both_unlocked := _spot_accessible(from_id) and _spot_accessible(to_id)
		var color := Color(Palette.MAP_ROUTE_SELECTED, 0.88) if selected_route else Color(Palette.MAP_ROUTE_IDLE, 0.34)
		if not both_unlocked and not selected_route:
			color = Color(Palette.MAP_ROUTE_LOCKED, 0.28)
		var width := 3.2 if selected_route else 1.7
		if selected_route:
			var pulse := 0.5 + 0.5 * sin(_animation_time * TAU * 0.72)
			draw_line(from_point, to_point, Color(Palette.MAP_ROUTE_SELECTED, 0.12 + pulse * 0.06), width + 8.0)
			_draw_route_bearing_marks(from_point, to_point, pulse)
		_draw_dotted_line(from_point, to_point, color, width, 13.0, 10.0)


func _selected_route_key_map() -> Dictionary:
	var result: Dictionary = {}
	for pair in Array(ROUTE_PATHS.get(selected_spot_id, [])):
		if pair.size() < 2:
			continue
		result[_route_key(String(pair[0]), String(pair[1]))] = true
	return result


func _route_key(from_id: String, to_id: String) -> String:
	return "%s>%s" % [from_id, to_id]


func _draw_route_bearing_marks(from_point: Vector2, to_point: Vector2, pulse: float) -> void:
	var delta := to_point - from_point
	var length := delta.length()
	if length <= 1.0:
		return
	var direction := delta / length
	var normal := Vector2(-direction.y, direction.x)
	for ratio in [0.30, 0.50, 0.70]:
		var center := from_point.lerp(to_point, float(ratio))
		draw_line(
			center - normal * 6.5,
			center + normal * 6.5,
			Color(Palette.MAP_ROUTE_BEARING, 0.30 + pulse * 0.10),
			1.2
		)


func _draw_markers(map_rect: Rect2) -> void:
	var font := GameFontsScript.bold(get_theme_default_font())
	for spot_id in GameData.get_all_fishing_spot_ids():
		if not SPOT_POINTS.has(spot_id):
			continue
		var center := _map_point(map_rect, spot_id)
		var access := _spot_access_status(spot_id)
		var unlocked := bool(access.get("ok", false))
		var lock_reason := String(access.get("reason", ""))
		var spot := GameData.get_fishing_spot(spot_id)
		var boss_spot := bool(spot.get("boss_spot", false))
		var selected := spot_id == selected_spot_id
		var marker_index := MARKER_NORMAL
		var marker_row := 0
		if not unlocked:
			marker_index = MARKER_LOCKED
			marker_row = 3 if lock_reason == "chart" else 2
		elif boss_spot:
			marker_index = MARKER_BOSS
		if selected and unlocked:
			marker_index = MARKER_SELECTED
			marker_row = 1
		var marker_size := clampf(map_rect.size.x * (0.080 if selected else 0.060), 52.0, 88.0)
		if _hovered_spot_id == spot_id:
			marker_size *= 1.07
		var target := Rect2(center - Vector2(marker_size, marker_size) * 0.5, Vector2(marker_size, marker_size))
		if selected and unlocked:
			_draw_selected_marker_ping(center, marker_size)
		_draw_spot_marker(spot_id, marker_row, marker_index, target)
		_draw_spot_chip(font, map_rect, spot, access, center, unlocked, selected, boss_spot)


func _draw_selected_marker_ping(center: Vector2, marker_size: float) -> void:
	var pulse := 0.5 + 0.5 * sin(_animation_time * TAU * 0.86)
	var radius := marker_size * (0.50 + pulse * 0.08)
	draw_circle(center, radius, Color(Palette.MAP_PING_GLOW, 0.14 + pulse * 0.09), false, 3.0)
	draw_circle(center, marker_size * 0.68, Color(Palette.MAP_PING_RING, 0.16), false, 1.8)
	draw_circle(center, marker_size * 0.82, Color(Palette.MAP_PING_GLOW, 0.08), false, 1.1)
	var spin := fmod(_animation_time * 1.35, TAU)
	for offset in [0.0, PI]:
		draw_arc(
			center,
			marker_size * 0.78,
			spin + offset,
			spin + offset + PI * 0.46,
			18,
			Color(Palette.MAP_PING_ARC, 0.38),
			1.8,
			true
		)
	var tick := marker_size * 0.93
	var tick_inner := marker_size * 0.76
	for direction in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		draw_line(center + direction * tick_inner, center + direction * tick, Color(Palette.MAP_ROUTE_SELECTED, 0.30), 1.3)


func _draw_spot_marker(spot_id: String, marker_row: int, fallback_marker_index: int, target: Rect2) -> void:
	if _spot_marker_sheet == null:
		_draw_marker(fallback_marker_index, target)
		return
	var marker_col := SPOT_MARKER_ORDER.find(spot_id)
	if marker_col < 0:
		_draw_marker(fallback_marker_index, target)
		return
	var src := Rect2(
		Vector2(MARKER_CELL_SIZE * float(marker_col), MARKER_CELL_SIZE * float(marker_row)),
		Vector2(MARKER_CELL_SIZE, MARKER_CELL_SIZE)
	)
	draw_texture_rect_region(_spot_marker_sheet, target, src, Color.WHITE)


func _draw_marker(marker_index: int, target: Rect2) -> void:
	if _marker_sheet == null:
		draw_circle(target.get_center(), target.size.x * 0.42, Palette.MAP_ACTION_HOVER)
		draw_circle(target.get_center(), target.size.x * 0.42, Palette.GOLD, false, 2.0)
		return
	var src := Rect2(Vector2(MARKER_CELL_SIZE * float(marker_index), 0.0), Vector2(MARKER_CELL_SIZE, MARKER_CELL_SIZE))
	draw_texture_rect_region(_marker_sheet, target, src, Color.WHITE)


func _draw_spot_chip(
	font: Font,
	map_rect: Rect2,
	spot: Dictionary,
	access: Dictionary,
	center: Vector2,
	unlocked: bool,
	selected: bool,
	boss_spot: bool
) -> void:
	var spot_id := String(spot.get("id", ""))
	var name := String(spot.get("short_name", spot.get("name", spot_id)))
	var extra := "Lv.%d" % int(spot.get("unlock_level", 1))
	if not unlocked:
		extra = _locked_chip_text(spot, access)
	elif boss_spot:
		extra = "ぬし"
	var font_size := 16 if selected else 14
	if not unlocked:
		font_size = 13
	var name_w := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var extra_w := font.get_string_size(extra, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	var chip_w := maxf(name_w, extra_w) + 25.0
	var chip_h := 42.0 if not unlocked or boss_spot else 30.0
	var offset: Vector2 = LABEL_OFFSETS.get(spot_id, Vector2(0.0, 46.0))
	var chip_pos := center + offset - Vector2(chip_w * 0.5, chip_h * 0.5)
	chip_pos.x = clampf(chip_pos.x, map_rect.position.x + 8.0, map_rect.end.x - chip_w - 8.0)
	chip_pos.y = clampf(chip_pos.y, map_rect.position.y + 8.0, map_rect.end.y - chip_h - 8.0)
	var chip_rect := Rect2(chip_pos, Vector2(chip_w, chip_h))
	var fill := Color(Palette.MAP_CHIP_FILL, 0.92) if unlocked else Color(Palette.MAP_CHIP_FILL_LOCKED, 0.84)
	var border := Color(Palette.MAP_CHIP_BORDER_SELECTED, 0.92) if selected else Color(Palette.MAP_CHIP_BORDER, 0.76)
	if boss_spot and unlocked:
		border = Color(Palette.MAP_CHIP_BORDER_BOSS, 0.98)
	_draw_spot_chip_leader(center, chip_rect, selected, unlocked)
	draw_rect(chip_rect.grow(2.0), Color(Color.BLACK, 0.25), true)
	draw_rect(chip_rect, fill, true)
	draw_line(chip_rect.position + Vector2(4.0, 4.0), chip_rect.position + Vector2(chip_rect.size.x - 4.0, 4.0), Color(Palette.MAP_CHIP_HIGHLIGHT, 0.42), 1.0)
	draw_line(chip_rect.position + Vector2(4.0, chip_rect.size.y - 4.0), chip_rect.position + Vector2(chip_rect.size.x - 4.0, chip_rect.size.y - 4.0), Color(Palette.MAP_CHIP_SHADOW_LINE, 0.20), 1.0)
	for corner in [
		chip_rect.position + Vector2(4.0, 4.0),
		Vector2(chip_rect.end.x - 4.0, chip_rect.position.y + 4.0),
		Vector2(chip_rect.position.x + 4.0, chip_rect.end.y - 4.0),
		chip_rect.end - Vector2(4.0, 4.0),
	]:
		draw_circle(corner, 1.6, Color(Palette.MAP_CHIP_RIVET, 0.42))
	draw_rect(chip_rect, border, false, 1.4 if not selected else 1.8)
	if selected:
		draw_rect(chip_rect.grow(3.0), Color(Palette.MAP_ROUTE_SELECTED, 0.13), false, 1.0)
	var name_pos := chip_rect.position + Vector2((chip_rect.size.x - name_w) * 0.5, 21.0)
	_draw_text(font, name, name_pos, font_size, Palette.MAP_CHIP_TEXT if unlocked else Palette.MAP_CHIP_TEXT_LOCKED, 1)
	if not unlocked or boss_spot:
		var extra_pos := chip_rect.position + Vector2((chip_rect.size.x - extra_w) * 0.5, 36.0)
		_draw_text(font, extra, extra_pos, 12, Palette.MAP_CHIP_LOCKED_TEXT if not unlocked else Palette.MAP_CHIP_BOSS_TEXT, 0)


func _locked_chip_text(spot: Dictionary, access: Dictionary) -> String:
	var reason := String(access.get("reason", ""))
	if reason == "chart":
		return "海図 %d/%d" % [
			int(access.get("sea_chart_fragments", 0)),
			int(access.get("required_sea_chart_fragments", GameData.SEA_CHART_REQUIRED_FRAGMENTS)),
		]
	if reason == "boat":
		return "船ランク%d" % int(access.get("required_boat_rank", GameData.NO_BOAT_RANK))
	return "LOCK Lv.%d" % int(spot.get("unlock_level", 1))


func _draw_spot_chip_leader(center: Vector2, chip_rect: Rect2, selected: bool, unlocked: bool) -> void:
	var edge := Vector2(
		clampf(center.x, chip_rect.position.x, chip_rect.end.x),
		clampf(center.y, chip_rect.position.y, chip_rect.end.y)
	)
	if center.y < chip_rect.position.y:
		edge.y = chip_rect.position.y
	elif center.y > chip_rect.end.y:
		edge.y = chip_rect.end.y
	elif center.x < chip_rect.position.x:
		edge.x = chip_rect.position.x
	elif center.x > chip_rect.end.x:
		edge.x = chip_rect.end.x
	else:
		edge = chip_rect.get_center()
	var line_color := Color(Palette.MAP_CHIP_LEADER, 0.50 if unlocked else 0.28)
	if selected:
		line_color = Color(Palette.MAP_ROUTE_SELECTED, 0.70)
	draw_line(center, edge, Color(Color.BLACK, line_color.a * 0.45), 3.0)
	draw_line(center, edge, line_color, 1.2 if not selected else 1.6)


func _draw_dotted_line(from_point: Vector2, to_point: Vector2, color: Color, width: float, dash: float, gap: float) -> void:
	var delta := to_point - from_point
	var length := delta.length()
	if length <= 0.0:
		return
	var direction := delta / length
	var cursor := 0.0
	while cursor < length:
		var end_cursor := minf(cursor + dash, length)
		draw_line(from_point + direction * cursor, from_point + direction * end_cursor, Color(Color.BLACK, color.a * 0.34), width + 2.0)
		draw_line(from_point + direction * cursor, from_point + direction * end_cursor, color, width)
		cursor += dash + gap


func _spot_at_position(position: Vector2) -> String:
	var map_rect := _content_rect()
	var nearest_id := ""
	var nearest_dist := INF
	for spot_id in GameData.get_all_fishing_spot_ids():
		if not SPOT_POINTS.has(spot_id):
			continue
		var center := _map_point(map_rect, spot_id)
		var radius := clampf(map_rect.size.x * 0.048, 42.0, 64.0)
		var dist := center.distance_to(position)
		if dist <= radius and dist < nearest_dist:
			nearest_id = spot_id
			nearest_dist = dist
	return nearest_id


func _spot_access_status(spot_id: String) -> Dictionary:
	return GameData.fishing_spot_access_status(
		spot_id,
		player_level,
		PlayerProgress.owned_boats,
		PlayerProgress.sea_chart_fragments
	)


func _spot_accessible(spot_id: String) -> bool:
	return bool(_spot_access_status(spot_id).get("ok", false))


func _map_point(map_rect: Rect2, spot_id: String) -> Vector2:
	var normalized: Vector2 = SPOT_POINTS.get(spot_id, Vector2.ZERO)
	return _map_normalized_point(map_rect, normalized)


func _map_normalized_point(map_rect: Rect2, normalized: Vector2) -> Vector2:
	var source_view := _source_view_rect()
	var visible_x := (normalized.x - source_view.position.x) / source_view.size.x
	var visible_y := (normalized.y - source_view.position.y) / source_view.size.y
	return map_rect.position + Vector2(map_rect.size.x * visible_x, map_rect.size.y * visible_y)


func _content_rect() -> Rect2:
	var draw_size := size
	if draw_size.x <= 0.0 or draw_size.y <= 0.0:
		return Rect2(Vector2.ZERO, Vector2.ZERO)
	return Rect2(Vector2.ZERO, draw_size)


func _source_view_rect() -> Rect2:
	var target_aspect := 16.0 / 9.0
	if size.x <= 0.0 or size.y <= 0.0:
		return Rect2(Vector2.ZERO, Vector2.ONE)
	var view_aspect := size.x / size.y
	if view_aspect > target_aspect:
		var visible_h := target_aspect / view_aspect
		return Rect2(Vector2(0.0, (1.0 - visible_h) * 0.5), Vector2(1.0, visible_h))
	var visible_w := view_aspect / target_aspect
	return Rect2(Vector2((1.0 - visible_w) * 0.5, 0.0), Vector2(visible_w, 1.0))


func _texture_source_region(texture: Texture2D) -> Rect2:
	var source_view := _source_view_rect()
	var texture_size := Vector2(float(texture.get_width()), float(texture.get_height()))
	return Rect2(source_view.position * texture_size, source_view.size * texture_size)


func _draw_text(font: Font, text: String, baseline: Vector2, font_size: int, color: Color, outline: int) -> void:
	if outline > 0:
		draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline, Color(Color.BLACK, 0.62))
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
