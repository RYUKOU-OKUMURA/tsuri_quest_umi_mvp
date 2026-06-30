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
]

var player_level := 1
var selected_spot_id := GameData.DEFAULT_FISHING_SPOT_ID

var _map_bg: Texture2D
var _map_grade: Texture2D
var _marker_sheet: Texture2D
var _spot_marker_sheet: Texture2D
var _hovered_spot_id := ""


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
	_map_bg = _load_texture_if_exists(MAP_BG_PATH)
	_map_grade = _load_texture_if_exists(MAP_GRADE_PATH)
	_marker_sheet = _load_texture_if_exists(MARKER_SHEET_PATH)
	_spot_marker_sheet = _load_texture_if_exists(SPOT_MARKER_SHEET_PATH)


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
	if GameData.is_fishing_spot_unlocked(spot_id, player_level):
		spot_selected.emit(spot_id)
	else:
		locked_spot_pressed.emit(spot_id)
	accept_event()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	draw_rect(rect, Color("#04111f"), true)
	var map_rect := _content_rect()
	if _map_bg != null:
		draw_texture_rect(_map_bg, map_rect, false, Color.WHITE)
	else:
		draw_rect(map_rect, Color("#0b4564"), true)
	if _map_grade != null:
		draw_texture_rect(_map_grade, map_rect, false, Color(1.0, 1.0, 1.0, 0.70))
	_draw_routes(map_rect)
	_draw_markers(map_rect)
	draw_rect(map_rect, Color(0.94, 0.78, 0.38, 0.52), false, 2.0)


func _draw_routes(map_rect: Rect2) -> void:
	for pair in ROUTES:
		var from_id := String(pair[0])
		var to_id := String(pair[1])
		if not SPOT_POINTS.has(from_id) or not SPOT_POINTS.has(to_id):
			continue
		var from_point := _map_point(map_rect, from_id)
		var to_point := _map_point(map_rect, to_id)
		var selected_route := from_id == selected_spot_id or to_id == selected_spot_id
		var both_unlocked := (
			GameData.is_fishing_spot_unlocked(from_id, player_level)
			and GameData.is_fishing_spot_unlocked(to_id, player_level)
		)
		var color := Color("#ffe070", 0.88) if selected_route else Color("#f6e5b0", 0.48)
		if not both_unlocked and not selected_route:
			color = Color("#a99c87", 0.36)
		var width := 3.4 if selected_route else 2.0
		if selected_route:
			draw_line(from_point, to_point, Color("#ffe070", 0.18), width + 8.0)
		_draw_dotted_line(from_point, to_point, color, width, 14.0, 10.0)


func _draw_markers(map_rect: Rect2) -> void:
	var font := GameFontsScript.bold(get_theme_default_font())
	for spot_id in GameData.get_all_fishing_spot_ids():
		if not SPOT_POINTS.has(spot_id):
			continue
		var center := _map_point(map_rect, spot_id)
		var unlocked := GameData.is_fishing_spot_unlocked(spot_id, player_level)
		var spot := GameData.get_fishing_spot(spot_id)
		var boss_spot := bool(spot.get("boss_spot", false))
		var selected := spot_id == selected_spot_id
		var marker_index := MARKER_NORMAL
		var marker_row := 0
		if not unlocked:
			marker_index = MARKER_LOCKED
			marker_row = 2
		elif boss_spot:
			marker_index = MARKER_BOSS
		if selected and unlocked:
			marker_index = MARKER_SELECTED
			marker_row = 1
		var marker_size := clampf(map_rect.size.x * (0.072 if selected else 0.061), 52.0, 82.0)
		if _hovered_spot_id == spot_id:
			marker_size *= 1.07
		var target := Rect2(center - Vector2(marker_size, marker_size) * 0.5, Vector2(marker_size, marker_size))
		_draw_spot_marker(spot_id, marker_row, marker_index, target)
		_draw_spot_chip(font, map_rect, spot, center, unlocked, selected, boss_spot)


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
		draw_circle(target.get_center(), target.size.x * 0.42, Color("#0b4a70"))
		draw_circle(target.get_center(), target.size.x * 0.42, Palette.GOLD, false, 2.0)
		return
	var src := Rect2(Vector2(MARKER_CELL_SIZE * float(marker_index), 0.0), Vector2(MARKER_CELL_SIZE, MARKER_CELL_SIZE))
	draw_texture_rect_region(_marker_sheet, target, src, Color.WHITE)


func _draw_spot_chip(
	font: Font,
	map_rect: Rect2,
	spot: Dictionary,
	center: Vector2,
	unlocked: bool,
	selected: bool,
	boss_spot: bool
) -> void:
	var spot_id := String(spot.get("id", ""))
	var name := String(spot.get("short_name", spot.get("name", spot_id)))
	var extra := "Lv.%d" % int(spot.get("unlock_level", 1))
	if not unlocked:
		extra = "LOCK Lv.%d" % int(spot.get("unlock_level", 1))
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
	var fill := Color("#f0d79a", 0.92) if unlocked else Color("#b9afa0", 0.84)
	var border := Color("#ffd967", 0.98) if selected else Color("#5e3a1c", 0.82)
	if boss_spot and unlocked:
		border = Color("#d9764d", 0.98)
	draw_rect(chip_rect.grow(2.0), Color(0.0, 0.0, 0.0, 0.32), true)
	draw_rect(chip_rect, fill, true)
	draw_rect(chip_rect, border, false, 2.0)
	var name_pos := chip_rect.position + Vector2((chip_rect.size.x - name_w) * 0.5, 21.0)
	_draw_text(font, name, name_pos, font_size, Color("#24170d") if unlocked else Color("#554b42"), 1)
	if not unlocked or boss_spot:
		var extra_pos := chip_rect.position + Vector2((chip_rect.size.x - extra_w) * 0.5, 36.0)
		_draw_text(font, extra, extra_pos, 12, Color("#842a24") if not unlocked else Color("#6d2a1d"), 0)


func _draw_dotted_line(from_point: Vector2, to_point: Vector2, color: Color, width: float, dash: float, gap: float) -> void:
	var delta := to_point - from_point
	var length := delta.length()
	if length <= 0.0:
		return
	var direction := delta / length
	var cursor := 0.0
	while cursor < length:
		var end_cursor := minf(cursor + dash, length)
		draw_line(from_point + direction * cursor, from_point + direction * end_cursor, Color(0.0, 0.0, 0.0, color.a * 0.34), width + 2.0)
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


func _map_point(map_rect: Rect2, spot_id: String) -> Vector2:
	var normalized: Vector2 = SPOT_POINTS.get(spot_id, Vector2.ZERO)
	return map_rect.position + Vector2(map_rect.size.x * normalized.x, map_rect.size.y * normalized.y)


func _content_rect() -> Rect2:
	var target_aspect := 16.0 / 9.0
	var draw_size := size
	if draw_size.x <= 0.0 or draw_size.y <= 0.0:
		return Rect2(Vector2.ZERO, Vector2.ZERO)
	var width := draw_size.x
	var height := width / target_aspect
	if height > draw_size.y:
		height = draw_size.y
		width = height * target_aspect
	return Rect2((draw_size - Vector2(width, height)) * 0.5, Vector2(width, height))


func _draw_text(font: Font, text: String, baseline: Vector2, font_size: int, color: Color, outline: int) -> void:
	if outline > 0:
		draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline, Color(0.0, 0.0, 0.0, 0.62))
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _load_texture_if_exists(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null
