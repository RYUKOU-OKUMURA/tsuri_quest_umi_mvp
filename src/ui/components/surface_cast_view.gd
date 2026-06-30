class_name SurfaceCastView
extends Control
## 水上キャストビュー。READY〜BITE 中に「空・海面・桟橋・釣り人・浮標」を描画する。
# FIGHT 以降は fishing_screen が underwater_view とのクロスフェードを担当し、
# 本ビューは modulate.a を下げて退場する（自身は visible 制御せず modulate のみ）。

const SEA_LIGHT := Color("#22b7df")
const SEA_MAIN := Color("#1286c7")
const SEA_DEEP_CAST := Color("#075789")
const SKY_HIGH := Color("#64c9f4")
const SKY_LOW := Color("#d7f7ff")
const CLOUD_SHADOW := Color("#bde9f6")
const ISLAND_GREEN := Color("#257843")
const ISLAND_DARK := Color("#15512f")
const DOCK_DARK := Color("#4d2b14")
const DOCK_MID := Color("#8b5527")
const DOCK_HI := Color("#d29b4a")
const LINE_COLOR := Color(1.0, 1.0, 1.0, 0.82)
const SURFACE_BG_PATH := "res://assets/showcase/surface/surface_cast_bg.png"
const SURFACE_COLOR_GRADE_PATH := "res://assets/showcase/surface/surface_color_grade.png"
const SURFACE_DOCK_FOREGROUND_PATH := "res://assets/showcase/surface/surface_dock_foreground.png"
const SURFACE_AMBIENCE_PATH := "res://assets/showcase/surface/surface_foreground_ambience.png"
const SURFACE_ANGLER_IDLE_PATH := "res://assets/showcase/surface/surface_angler_idle.png"
const SURFACE_ANGLER_CAST_PATH := "res://assets/showcase/surface/surface_angler_cast.png"
const SURFACE_BOBBER_PATH := "res://assets/showcase/surface/surface_bobber.png"
const SURFACE_FISH_SHADOW_PATH := "res://assets/showcase/surface/surface_fish_shadow.png"
const SURFACE_SPLASH_PATH := "res://assets/showcase/surface/surface_splash.png"

var simulator: FishingSimulator
var fish_data: Dictionary = {}
var _time: float = 0.0
var _last_state: int = -1
var _bobber_dip: float = 0.0
var _splash: float = 0.0
var _hit_flash: float = 0.0
var _cast_flight: float = 0.0
var _approach_glow: float = 0.0
var _waiting_ring: float = 0.0
var _surface_bg: Texture2D
var _surface_color_grade: Texture2D
var _surface_dock_foreground: Texture2D
var _surface_ambience: Texture2D
var _surface_angler_idle: Texture2D
var _surface_angler_cast: Texture2D
var _surface_bobber: Texture2D
var _surface_fish_shadow: Texture2D
var _surface_splash: Texture2D


func bind_simulator(value: FishingSimulator) -> void:
	simulator = value
	fish_data = simulator.fish_data
	_last_state = -1
	_bobber_dip = 0.0
	_splash = 0.0
	_hit_flash = 0.0
	_cast_flight = 0.0
	_approach_glow = 0.0
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_load_surface_assets()


func _process(delta: float) -> void:
	_time += delta
	var state := _state()
	if simulator != null and state != _last_state:
		_on_state_changed(state)
		_last_state = state

	var biting := state == FishingSimulator.State.BITE
	_bobber_dip = lerpf(
		_bobber_dip, 1.0 if biting else 0.0, 1.0 - exp((-14.0 if biting else -6.0) * delta)
	)
	var approach_target := 1.0 if state == FishingSimulator.State.APPROACH or biting else 0.24 if state == FishingSimulator.State.WAITING else 0.08
	_approach_glow = lerpf(_approach_glow, approach_target, 1.0 - exp(-5.0 * delta))
	_splash = maxf(_splash - delta * 1.85, 0.0)
	_hit_flash = maxf(_hit_flash - delta * 2.6, 0.0)
	_cast_flight = maxf(_cast_flight - delta * 2.15, 0.0)
	_waiting_ring = fmod(_waiting_ring + delta * 0.58, 1.0)
	queue_redraw()


func _on_state_changed(state: int) -> void:
	if state == FishingSimulator.State.CASTING:
		_cast_flight = 1.0
		_waiting_ring = 0.0
	elif state == FishingSimulator.State.BITE:
		_splash = 1.0
		_hit_flash = 1.0
		Juicer.add_trauma(0.45)
		Juicer.hit_stop(0.04)


func _draw() -> void:
	draw_set_transform(Juicer.get_offset())
	if _surface_bg != null:
		_draw_asset_scene()
		return
	var horizon := roundf(size.y * 0.43)
	_draw_sky(horizon)
	_draw_far_islands(horizon)
	_draw_sea(horizon)
	_draw_fish_shadow(horizon)
	_draw_dock()
	_draw_angler()
	_draw_line_and_bobber(horizon)
	_draw_hit_flash()
	_draw_frame()


func _load_surface_assets() -> void:
	_surface_bg = _load_texture_if_exists(SURFACE_BG_PATH)
	_surface_color_grade = _load_texture_if_exists(SURFACE_COLOR_GRADE_PATH)
	_surface_dock_foreground = _load_texture_if_exists(SURFACE_DOCK_FOREGROUND_PATH)
	_surface_ambience = _load_texture_if_exists(SURFACE_AMBIENCE_PATH)
	_surface_angler_idle = _load_texture_if_exists(SURFACE_ANGLER_IDLE_PATH)
	_surface_angler_cast = _load_texture_if_exists(SURFACE_ANGLER_CAST_PATH)
	_surface_bobber = _load_texture_if_exists(SURFACE_BOBBER_PATH)
	_surface_fish_shadow = _load_texture_if_exists(SURFACE_FISH_SHADOW_PATH)
	_surface_splash = _load_texture_if_exists(SURFACE_SPLASH_PATH)


func _load_texture_if_exists(path: String) -> Texture2D:
	if ResourceLoader.exists(path) or FileAccess.file_exists(path):
		return load(path) as Texture2D
	return null


func _draw_asset_scene() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var horizon := _asset_horizon()
	_draw_cover_texture(_surface_bg, rect, Color.WHITE, Vector2(0.5, 0.50))
	_draw_asset_fish_shadow(horizon)
	if _surface_dock_foreground != null:
		_draw_cover_texture(_surface_dock_foreground, rect, Color.WHITE, Vector2(0.5, 0.50))
	if _surface_ambience != null:
		_draw_cover_texture(_surface_ambience, rect, Color(1.0, 1.0, 1.0, 0.62), Vector2(0.5, 0.50))
	_draw_asset_angler()
	_draw_asset_line_and_bobber(horizon)
	if _surface_color_grade != null:
		_draw_cover_texture(_surface_color_grade, rect, Color(1.0, 1.0, 1.0, 0.64), Vector2(0.5, 0.50))
	_draw_hit_flash()
	_draw_frame()


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


func _asset_horizon() -> float:
	return roundf(size.y * 0.41)


func _draw_asset_fish_shadow(horizon: float) -> void:
	if simulator == null or _surface_fish_shadow == null:
		return
	var state := _state()
	if state == FishingSimulator.State.READY and _approach_glow < 0.12:
		return
	var bobber := _bobber_target_position(horizon)
	var water_h := size.y - horizon
	var progress := clampf(simulator.visual_position.x / 0.61, 0.0, 1.0)
	if state == FishingSimulator.State.WAITING:
		progress = 0.18 + sin(_time * 0.74) * 0.04
	elif state == FishingSimulator.State.APPROACH:
		progress = maxf(progress, 0.62)
	elif state == FishingSimulator.State.BITE:
		progress = 1.0
	var fish_x := lerpf(size.x * 0.19, bobber.x - size.x * 0.060, progress)
	var fish_y := horizon + water_h * (0.31 + 0.14 * clampf(simulator.visual_position.y, 0.0, 1.0))
	if state == FishingSimulator.State.BITE:
		fish_y = bobber.y + size.y * 0.050
	var alpha := 0.18 + _approach_glow * 0.52
	if state == FishingSimulator.State.BITE:
		alpha = 0.82
	var draw_w := size.x * (0.145 + _approach_glow * 0.034)
	var draw_h := draw_w * (_surface_fish_shadow.get_height() / float(_surface_fish_shadow.get_width()))
	var dst := Rect2(Vector2(fish_x - draw_w * 0.50, fish_y - draw_h * 0.50), Vector2(draw_w, draw_h))
	draw_texture_rect(_surface_fish_shadow, dst, false, Color(1.0, 1.0, 1.0, alpha))
	if state == FishingSimulator.State.APPROACH or state == FishingSimulator.State.BITE:
		var wake := Vector2(fish_x, fish_y).lerp(bobber + Vector2(-8.0, 12.0), 0.62)
		_draw_ellipse_outline(wake, size.x * 0.042, size.y * 0.011, Color(1.0, 1.0, 1.0, 0.18 + _approach_glow * 0.14), 34, 1.5)


func _draw_asset_angler() -> void:
	var state := _state()
	var texture := _surface_angler_cast if state == FishingSimulator.State.CASTING and _cast_flight > 0.18 else _surface_angler_idle
	if texture == null:
		_draw_angler()
		return
	var rect := _angler_rect()
	var bob := sin(_time * 2.7) * size.y * 0.0025
	draw_texture_rect(texture, Rect2(rect.position + Vector2(0.0, bob), rect.size), false, Color.WHITE)


func _draw_asset_line_and_bobber(horizon: float) -> void:
	var rod_tip := _rod_tip_asset()
	var bobber := _bobber_position(horizon, rod_tip)
	var target := _bobber_target_position(horizon)
	var mid := Vector2((rod_tip.x + bobber.x) * 0.5, (rod_tip.y + bobber.y) * 0.5 + size.y * 0.040 + _bobber_dip * size.y * 0.028)
	draw_polyline(PackedVector2Array([rod_tip + Vector2(0.8, 0.8), mid + Vector2(0.8, 0.8), bobber + Vector2(0.8, 0.8)]), Color(0.02, 0.08, 0.12, 0.22), 2.2, false)
	draw_polyline(PackedVector2Array([rod_tip, mid, bobber]), LINE_COLOR, 1.5, false)

	if _cast_flight <= 0.42:
		_draw_bobber_ripples(target, horizon)
	if _splash > 0.0 or _state() == FishingSimulator.State.BITE:
		_draw_asset_bite_splash(target)
	_draw_asset_bobber(bobber)


func _draw_asset_bobber(pos: Vector2) -> void:
	if _surface_bobber == null:
		_draw_bobber(pos)
		return
	var draw_h := size.y * 0.088
	var draw_w := draw_h * (_surface_bobber.get_width() / float(_surface_bobber.get_height()))
	var dst := Rect2(pos - Vector2(draw_w * 0.50, draw_h * 0.42), Vector2(draw_w, draw_h))
	draw_texture_rect(_surface_bobber, dst, false, Color.WHITE)


func _draw_asset_bite_splash(center: Vector2) -> void:
	if _surface_splash == null:
		_draw_bite_splash(center, _asset_horizon())
		return
	var burst := _splash
	if _state() == FishingSimulator.State.BITE:
		burst = maxf(burst, 0.48 + 0.22 * sin(_time * 18.0))
	var draw_w := size.x * (0.145 + (1.0 - clampf(_splash, 0.0, 1.0)) * 0.040)
	var draw_h := draw_w * (_surface_splash.get_height() / float(_surface_splash.get_width()))
	var dst := Rect2(center - Vector2(draw_w * 0.50, draw_h * 0.63), Vector2(draw_w, draw_h))
	draw_texture_rect(_surface_splash, dst, false, Color(1.0, 1.0, 1.0, clampf(burst, 0.0, 1.0)))


func _angler_rect() -> Rect2:
	var rect_w := size.x * 0.255
	var rect_h := rect_w * 160.0 / 260.0
	var rect_size := Vector2(rect_w, rect_h)
	var rect_pos := Vector2(size.x * 0.585, size.y * 0.390)
	return Rect2(rect_pos, rect_size)


func _rod_tip_asset() -> Vector2:
	var rect := _angler_rect()
	var casting := _state() == FishingSimulator.State.CASTING and _cast_flight > 0.18
	var tip := Vector2(31.0, 18.0) if casting else Vector2(47.0, 33.0)
	return rect.position + Vector2(rect.size.x * tip.x / 260.0, rect.size.y * tip.y / 160.0)


func _draw_sky(horizon: float) -> void:
	var bands := 20
	for i in bands:
		var t := float(i) / float(bands - 1)
		var col := SKY_HIGH.lerp(SKY_LOW, t)
		var h := horizon / float(bands) + 1.0
		draw_rect(Rect2(0.0, roundf(i * h), size.x, ceilf(h)), col)

	var sun := Vector2(size.x * 0.79, horizon * 0.27)
	for i in range(9):
		var a := float(i) * TAU / 9.0 + 0.18
		var from := sun + Vector2(cos(a), sin(a)) * 34.0
		var to := sun + Vector2(cos(a), sin(a)) * (78.0 + float(i % 3) * 14.0)
		draw_line(from, to, Color(1.0, 0.96, 0.72, 0.18), 3.0)
	draw_circle(sun, 52.0, Color(1.0, 0.96, 0.70, 0.12))
	draw_circle(sun, 29.0, Color("#fff4a8"))
	draw_circle(sun + Vector2(-7.0, -8.0), 14.0, Color(1.0, 1.0, 1.0, 0.50))

	_draw_pixel_cloud(Vector2(size.x * 0.17 + sin(_time * 0.18) * 6.0, horizon * 0.28), 1.15)
	_draw_pixel_cloud(Vector2(size.x * 0.31 + sin(_time * 0.16 + 2.0) * 4.0, horizon * 0.44), 0.62)
	_draw_pixel_cloud(Vector2(size.x * 0.66 + sin(_time * 0.14 + 3.0) * 5.0, horizon * 0.39), 0.72)
	_draw_pixel_cloud(Vector2(size.x * 0.94 + sin(_time * 0.16 + 1.0) * 6.0, horizon * 0.33), 0.90)

	for i in range(5):
		var bird := Vector2(size.x * (0.36 + float(i) * 0.09), horizon * (0.22 + float(i % 3) * 0.12))
		_draw_bird(bird + Vector2(sin(_time * 0.7 + i) * 8.0, 0.0), 0.75 + float(i % 2) * 0.2)


func _draw_pixel_cloud(center: Vector2, scale_value: float) -> void:
	var unit := 8.0 * scale_value
	var pieces := [
		[-5, 1, 4, 2],
		[-3, -1, 4, 3],
		[0, -2, 5, 4],
		[3, -1, 4, 3],
		[5, 1, 3, 2],
		[-1, 1, 6, 2],
	]
	for p in pieces:
		var rect := Rect2(
			roundf(center.x + float(p[0]) * unit * 0.62),
			roundf(center.y + float(p[1]) * unit * 0.52),
			float(p[2]) * unit,
			float(p[3]) * unit
		)
		draw_rect(Rect2(rect.position + Vector2(0.0, unit * 0.34), rect.size), CLOUD_SHADOW, true)
		draw_rect(rect, Color(1.0, 1.0, 1.0, 0.94), true)
	draw_rect(Rect2(center.x - unit * 1.5, center.y + unit * 1.5, unit * 7.0, unit * 0.55), Color(1.0, 1.0, 1.0, 0.48), true)


func _draw_bird(pos: Vector2, scale_value: float) -> void:
	var c := Color("#1a4050", 0.70)
	draw_line(pos + Vector2(-7.0, 0.0) * scale_value, pos, c, 2.0)
	draw_line(pos, pos + Vector2(7.0, -1.5) * scale_value, c, 2.0)


func _draw_far_islands(horizon: float) -> void:
	var left_base := horizon - 2.0
	var left := PackedVector2Array([
		Vector2(0.0, left_base),
		Vector2(size.x * 0.05, horizon - 34.0),
		Vector2(size.x * 0.13, horizon - 54.0),
		Vector2(size.x * 0.21, horizon - 31.0),
		Vector2(size.x * 0.27, left_base),
	])
	draw_colored_polygon(left, ISLAND_DARK)
	var left_hi := PackedVector2Array([
		Vector2(0.0, left_base - 3.0),
		Vector2(size.x * 0.07, horizon - 27.0),
		Vector2(size.x * 0.15, horizon - 43.0),
		Vector2(size.x * 0.23, left_base - 2.0),
	])
	draw_colored_polygon(left_hi, ISLAND_GREEN)
	for i in range(5):
		var x := size.x * (0.055 + float(i) * 0.035)
		_draw_palm(Vector2(x, horizon - 28.0 - float(i % 2) * 8.0), 0.55)

	var right_base := horizon - 1.0
	var right := PackedVector2Array([
		Vector2(size.x * 0.86, right_base),
		Vector2(size.x * 0.90, horizon - 31.0),
		Vector2(size.x * 0.97, horizon - 48.0),
		Vector2(size.x, horizon - 30.0),
		Vector2(size.x, right_base),
	])
	draw_colored_polygon(right, Color("#17634a"))
	draw_line(Vector2(0.0, horizon), Vector2(size.x, horizon), Color(1.0, 1.0, 1.0, 0.58), 2.0)


func _draw_palm(base: Vector2, scale_value: float) -> void:
	draw_line(base, base + Vector2(5.0, -28.0) * scale_value, Color("#75491f"), 3.0 * scale_value)
	var top := base + Vector2(5.0, -28.0) * scale_value
	for i in range(5):
		var a := -2.75 + float(i) * 0.62
		draw_line(top, top + Vector2(cos(a), sin(a)) * 22.0 * scale_value, Color("#0f5f34"), 3.0 * scale_value)


func _draw_sea(horizon: float) -> void:
	var sea_h := size.y - horizon
	var bands := 18
	for i in bands:
		var t := float(i) / float(bands - 1)
		var col := SEA_LIGHT.lerp(SEA_MAIN, minf(t * 1.15, 1.0)).lerp(SEA_DEEP_CAST, maxf(0.0, t - 0.42))
		var h := sea_h / float(bands) + 1.0
		draw_rect(Rect2(0.0, horizon + i * (sea_h / float(bands)), size.x, h), col)
	draw_rect(Rect2(0.0, horizon - 2.0, size.x, 4.0), Color(1.0, 1.0, 1.0, 0.50))

	var sun_x := size.x * 0.79
	for i in range(18):
		var t := float(i) / 18.0
		var y := horizon + 10.0 + sea_h * 0.012 * float(i) + sea_h * t * 0.34
		var half := 28.0 + t * 132.0
		var alpha := 0.24 * (1.0 - t)
		draw_line(Vector2(sun_x - half, y), Vector2(sun_x + half, y), Color(1.0, 1.0, 1.0, alpha), 2.0)

	for i in range(42):
		var lane := i % 9
		var y := horizon + 10.0 + float(lane) * (sea_h / 11.0) + sin(_time * 0.8 + i) * 2.0
		var x := fmod(float(i) * 83.0 + _time * (16.0 + float(i % 4) * 5.0), size.x + 90.0) - 45.0
		var w := 20.0 + float(i % 5) * 12.0
		var alpha: float = 0.10 + 0.10 * abs(sin(_time * 1.4 + float(i)))
		draw_line(Vector2(x, y), Vector2(x + w, y), Color(1.0, 1.0, 1.0, alpha), 2.0)

	for i in range(22):
		var sx := fmod(float(i) * 127.0 + _time * 20.0, size.x)
		var sy := horizon + 18.0 + float((i * 11) % 100) / 100.0 * sea_h * 0.46
		var tw: float = 0.45 + 0.55 * abs(sin(_time * 2.4 + float(i)))
		draw_rect(Rect2(roundf(sx), roundf(sy), 3.0, 2.0), Color(1.0, 1.0, 1.0, 0.58 * tw), true)


func _draw_fish_shadow(horizon: float) -> void:
	if simulator == null:
		return
	var state := _state()
	if state == FishingSimulator.State.READY and _approach_glow < 0.10:
		return
	var bobber := _bobber_target_position(horizon)
	var water_h := size.y - horizon
	var fish_x := lerpf(size.x * 0.20, bobber.x - size.x * 0.055, clampf(simulator.visual_position.x / 0.61, 0.0, 1.0))
	if state == FishingSimulator.State.WAITING:
		fish_x += sin(_time * 0.95) * 16.0
	var fish_y := horizon + water_h * (0.30 + 0.18 * clampf(simulator.visual_position.y, 0.0, 1.0))
	var alpha := 0.10 + _approach_glow * 0.25
	var center := Vector2(fish_x, fish_y)
	_draw_ellipse(center, 45.0, 14.0, Color("#062c3d", alpha), 36)
	var tail := PackedVector2Array([
		center + Vector2(-35.0, 0.0),
		center + Vector2(-63.0, -17.0),
		center + Vector2(-59.0, 15.0),
	])
	draw_colored_polygon(tail, Color("#062c3d", alpha * 0.86))
	for i in range(3):
		var bubble := center + Vector2(-72.0 - float(i) * 11.0 + sin(_time * 2.0 + i) * 4.0, -20.0 + float(i) * 11.0)
		draw_circle(bubble, 2.3 + float(i) * 0.6, Color(1.0, 1.0, 1.0, _approach_glow * 0.35))
	if state == FishingSimulator.State.APPROACH or state == FishingSimulator.State.BITE:
		var lead := center.lerp(bobber + Vector2(-8.0, 18.0), 0.55)
		draw_line(lead + Vector2(-18.0, 0.0), lead + Vector2(18.0, 0.0), Color(1.0, 1.0, 1.0, 0.16 + _approach_glow * 0.13), 2.0)


func _draw_dock() -> void:
	var top := roundf(size.y * 0.69)
	var deck := PackedVector2Array([
		Vector2(size.x, top - 7.0),
		Vector2(size.x * 0.62, top - 7.0),
		Vector2(size.x * 0.68, size.y),
		Vector2(size.x, size.y),
	])
	draw_colored_polygon(deck, DOCK_MID)
	draw_colored_polygon(PackedVector2Array([
		Vector2(size.x, top - 10.0),
		Vector2(size.x * 0.62, top - 10.0),
		Vector2(size.x * 0.64, top + 12.0),
		Vector2(size.x, top + 12.0),
	]), DOCK_HI)

	for i in range(10):
		var x_top := size.x * 0.63 + float(i) * size.x * 0.042
		var x_bottom := size.x * 0.69 + float(i) * size.x * 0.052
		draw_line(Vector2(x_top, top - 7.0), Vector2(x_bottom, size.y), DOCK_DARK, 2.0)
	for i in range(8):
		var y := top + 10.0 + float(i) * 21.0
		var left_x := lerpf(size.x * 0.64, size.x * 0.69, float(i) / 8.0)
		draw_line(Vector2(left_x, y), Vector2(size.x, y - 4.0), Color("#6f3d1c"), 2.0)

	for i in range(5):
		var x := size.x * (0.67 + float(i) * 0.075)
		_draw_post(Vector2(x, top + 6.0 + float(i % 2) * 4.0), 1.0)
	for i in range(3):
		var px := size.x * (0.71 + float(i) * 0.11)
		draw_rect(Rect2(px, top + 28.0, 12.0, size.y - top), DOCK_DARK, true)
		draw_rect(Rect2(px + 1.0, top + 28.0, 3.0, size.y - top), Color("#a06a31", 0.65), true)

	_draw_dock_props(Vector2(size.x * 0.88, top + 32.0))


func _draw_post(base: Vector2, scale_value: float) -> void:
	draw_rect(Rect2(base.x - 6.0 * scale_value, base.y - 46.0 * scale_value, 12.0 * scale_value, 54.0 * scale_value), DOCK_DARK, true)
	draw_rect(Rect2(base.x - 3.0 * scale_value, base.y - 44.0 * scale_value, 4.0 * scale_value, 48.0 * scale_value), DOCK_HI, true)
	draw_circle(base + Vector2(0.0, -49.0) * scale_value, 8.0 * scale_value, Color("#b77b34"))
	draw_circle(base + Vector2(-2.0, -52.0) * scale_value, 3.0 * scale_value, Color("#f0c36c"))


func _draw_dock_props(base: Vector2) -> void:
	draw_circle(base + Vector2(0.0, 8.0), 15.0, Color("#533018"))
	draw_circle(base + Vector2(0.0, 8.0), 10.0, Color("#9b642d"))
	draw_rect(Rect2(base.x - 18.0, base.y - 22.0, 36.0, 30.0), Color("#7b491f"), true)
	draw_rect(Rect2(base.x - 15.0, base.y - 19.0, 30.0, 6.0), Color("#c68a3d"), true)
	for i in range(3):
		draw_arc(base + Vector2(-54.0 + float(i) * 5.0, 18.0 + float(i) * 2.0), 15.0 + float(i) * 4.0, -0.2, TAU - 0.2, 24, Color("#3a2715"), 3.0)


func _draw_angler() -> void:
	var base_y := roundf(size.y * 0.69)
	var p := Vector2(size.x * 0.72, base_y - 2.0)
	_draw_ellipse(p + Vector2(0.0, 5.0), 23.0, 6.0, Color(0.0, 0.0, 0.0, 0.28))

	var bob := sin(_time * 3.0) * 1.2
	var body := p + Vector2(0.0, bob)
	draw_rect(Rect2(body.x - 9.0, body.y - 35.0, 18.0, 28.0), Color("#244a63"), true)
	draw_rect(Rect2(body.x - 9.0, body.y - 35.0, 18.0, 6.0), Color("#2f6f91"), true)
	draw_rect(Rect2(body.x - 12.0, body.y - 10.0, 9.0, 18.0), Color("#202f3b"), true)
	draw_rect(Rect2(body.x + 3.0, body.y - 10.0, 9.0, 18.0), Color("#202f3b"), true)
	draw_circle(body + Vector2(0.0, -44.0), 10.5, Color("#e7b689"))
	draw_rect(Rect2(body.x - 7.0, body.y - 52.0, 14.0, 6.0), Color("#6b3a1e"), true)
	draw_rect(Rect2(body.x - 3.0, body.y - 43.0, 2.0, 2.0), Color("#101018"), true)
	draw_rect(Rect2(body.x + 5.0, body.y - 43.0, 2.0, 2.0), Color("#101018"), true)

	var rod_base := body + Vector2(-7.0, -29.0)
	var rod_tip := _rod_tip()
	draw_line(body + Vector2(-9.0, -28.0), rod_base + Vector2(-13.0, -12.0), Color("#e7b689"), 5.0)
	draw_line(rod_base + Vector2(-13.0, -12.0), rod_base + Vector2(-35.0, -28.0), Color("#e7b689"), 4.0)
	draw_polyline(PackedVector2Array([rod_base, body + Vector2(-31.0, -45.0), rod_tip]), Color("#5a3418"), 4.0, false)
	draw_polyline(PackedVector2Array([rod_base + Vector2(1.0, -1.0), body + Vector2(-31.0, -46.0), rod_tip]), Color("#d39a42"), 1.5, false)
	draw_circle(rod_tip, 2.4, Color("#27170b"))


func _draw_line_and_bobber(horizon: float) -> void:
	var rod_tip := _rod_tip()
	var bobber := _bobber_position(horizon, rod_tip)
	var target := _bobber_target_position(horizon)

	var mid := Vector2((rod_tip.x + bobber.x) * 0.5, (rod_tip.y + bobber.y) * 0.5 + 16.0 + _bobber_dip * 12.0)
	draw_polyline(PackedVector2Array([rod_tip, mid, bobber]), LINE_COLOR, 1.6, false)

	if _cast_flight <= 0.42:
		_draw_bobber_ripples(target, horizon)
	_draw_bobber(bobber)
	if _splash > 0.0 or _state() == FishingSimulator.State.BITE:
		_draw_bite_splash(target, horizon)


func _rod_tip() -> Vector2:
	var base_y := roundf(size.y * 0.69)
	var p := Vector2(size.x * 0.72, base_y - 2.0)
	return p + Vector2(-71.0, -76.0)


func _bobber_target_position(horizon: float) -> Vector2:
	var surface_y := horizon + (size.y - horizon) * 0.22
	return Vector2(size.x * 0.405, surface_y + sin(_time * 3.1) * 1.8 + _bobber_dip * 40.0)


func _bobber_position(horizon: float, rod_tip: Vector2) -> Vector2:
	var target := _bobber_target_position(horizon)
	if _cast_flight <= 0.0:
		return target
	var t := clampf(1.0 - _cast_flight, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - t, 3.0)
	var arc := sin(eased * PI) * -78.0
	return rod_tip.lerp(target, eased) + Vector2(0.0, arc)


func _draw_bobber(pos: Vector2) -> void:
	draw_line(pos + Vector2(0.0, -18.0), pos + Vector2(0.0, 11.0), Color("#54311a", 0.85), 1.3)
	draw_circle(pos + Vector2(0.0, 5.0), 7.0, Color("#c33428"))
	draw_circle(pos + Vector2(0.0, 0.0), 6.2, Color("#fff1b7"))
	draw_rect(Rect2(pos.x - 3.0, pos.y + 1.0, 6.0, 7.0), Color("#e0422e"), true)
	draw_circle(pos + Vector2(-2.0, -2.0), 2.2, Color(1.0, 1.0, 1.0, 0.76))


func _draw_bobber_ripples(center: Vector2, horizon: float) -> void:
	var water_scale := clampf((center.y - horizon) / maxf(1.0, size.y - horizon), 0.0, 1.0)
	for i in range(3):
		var phase := fmod(_waiting_ring + float(i) * 0.30, 1.0)
		var rx := 12.0 + phase * (34.0 + water_scale * 18.0)
		var ry := 4.0 + phase * 10.0
		var alpha := (1.0 - phase) * 0.34
		_draw_ellipse_outline(center + Vector2(0.0, 4.0), rx, ry, Color(1.0, 1.0, 1.0, alpha), 32, 1.4)
	if _cast_flight > 0.0:
		_draw_ellipse_outline(center + Vector2(0.0, 4.0), 44.0 * (1.0 - _cast_flight), 12.0 * (1.0 - _cast_flight), Color(1.0, 1.0, 1.0, 0.42 * (1.0 - _cast_flight)), 32, 1.8)


func _draw_bite_splash(center: Vector2, _horizon: float) -> void:
	var burst := _splash
	if _state() == FishingSimulator.State.BITE:
		burst = maxf(burst, 0.38 + 0.18 * sin(_time * 18.0))
	var ring_scale := 1.0 - clampf(_splash, 0.0, 1.0)
	_draw_ellipse_outline(center + Vector2(0.0, 8.0), 23.0 + ring_scale * 38.0, 7.0 + ring_scale * 13.0, Color(1.0, 1.0, 1.0, 0.45 * burst), 36, 2.0)
	for i in range(13):
		var ang := -PI * 0.5 + (float(i) / 12.0 - 0.5) * PI * 1.10
		var r := (1.0 - _splash) * 38.0 + 6.0 + float(i % 3) * 3.0
		var sp := center + Vector2(cos(ang), sin(ang)) * r
		draw_circle(sp, 2.2 + float(i % 2), Color(1.0, 1.0, 1.0, 0.72 * burst))


func _draw_hit_flash() -> void:
	if _hit_flash <= 0.0:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 0.96, 0.72, 0.10 * _hit_flash), true)


func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color, points := 28) -> void:
	var arr := PackedVector2Array()
	arr.resize(points)
	for i in points:
		var angle := TAU * float(i) / float(points)
		arr[i] = center + Vector2(cos(angle) * rx, sin(angle) * ry)
	draw_colored_polygon(arr, color)


func _draw_ellipse_outline(center: Vector2, rx: float, ry: float, color: Color, points := 36, width := 1.0) -> void:
	if rx <= 0.0 or ry <= 0.0:
		return
	var arr := PackedVector2Array()
	arr.resize(points + 1)
	for i in range(points + 1):
		var angle := TAU * float(i) / float(points)
		arr[i] = center + Vector2(cos(angle) * rx, sin(angle) * ry)
	draw_polyline(arr, color, width, false)


func _state() -> int:
	if simulator == null:
		return FishingSimulator.State.READY
	return simulator.state


func _draw_frame() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#072235"), false, 3.0)
	draw_rect(Rect2(5.0, 5.0, size.x - 10.0, size.y - 10.0), Color("#5dbde2", 0.44), false, 1.0)
	draw_rect(Rect2(10.0, 10.0, size.x - 20.0, size.y - 20.0), Color(0.0, 0.03, 0.08, 0.18), false, 1.0)
