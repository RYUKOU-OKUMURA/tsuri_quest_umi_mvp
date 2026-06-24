class_name SurfaceCastView
extends Control
## 水上キャストビュー。READY〜BITE 中に「空・海面・桟橋・釣り人・浮標」を描画する。
# BITE で浮標が沈んで水しぶきを上げ、Juicer で画面を揺らす。
# FIGHT 以降は fishing_screen が underwater_view とのクロスフェードを担当し、
# 本ビューは modulate.a を下げて退場する（自身は visible 制御せず modulate のみ）。
var simulator: FishingSimulator
var fish_data: Dictionary = {}
var _time: float = 0.0
var _last_state: int = -1
var _bobber_dip: float = 0.0   # BITE で増える浮標の沈み量(0..1)
var _splash: float = 0.0       # 水しぶき(0..1)


func bind_simulator(value: FishingSimulator) -> void:
	simulator = value
	fish_data = simulator.fish_data
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true


func _process(delta: float) -> void:
	_time += delta
	var biting := simulator != null and simulator.state == FishingSimulator.State.BITE
	_bobber_dip = lerpf(
		_bobber_dip, 1.0 if biting else 0.0, 1.0 - exp((-14.0 if biting else -6.0) * delta)
	)
	if biting:
		_splash = 1.0
	_splash = maxf(_splash - delta * 1.6, 0.0)
	if simulator != null and simulator.state != _last_state:
		_on_state_changed(simulator.state)
		_last_state = simulator.state
	queue_redraw()


func _on_state_changed(state: int) -> void:
	# アタリ（BITE）の瞬間に短い揺れと停止で「来た！」を演出
	if state == FishingSimulator.State.BITE:
		Juicer.add_trauma(0.45)
		Juicer.hit_stop(0.04)


func _draw() -> void:
	draw_set_transform(Juicer.get_offset())
	var horizon := size.y * 0.46
	_draw_sky(horizon)
	_draw_sea(horizon)
	_draw_dock()
	_draw_angler()
	_draw_line_and_bobber(horizon)
	_draw_frame()


func _draw_sky(horizon: float) -> void:
	var bands := 16
	for i in bands:
		var t := float(i) / float(bands - 1)
		var col := Palette.SKY_TOP.lerp(Palette.SKY_HORIZON, t)
		var h := horizon / float(bands) + 1.0
		draw_rect(Rect2(0.0, i * (horizon / float(bands)), size.x, h), col)
	# 太陽＋ハレーション
	var sun := Vector2(size.x * 0.80, horizon * 0.38)
	draw_circle(sun, 46.0, Color(1.0, 0.96, 0.80, 0.16))
	draw_circle(sun, 30.0, Color(1.0, 0.96, 0.80, 0.9))
	# 流れる雲
	for i in 3:
		var cx := fmod(_time * 6.0 + float(i) * 260.0, size.x + 240.0) - 120.0
		var cy := horizon * (0.16 + float(i) * 0.13)
		_draw_cloud(Vector2(cx, cy), 1.0)


func _draw_cloud(center: Vector2, s: float) -> void:
	var col := Color(1.0, 1.0, 1.0, 0.86)
	_draw_ellipse(center, 22.0 * s, 10.0 * s, col)
	_draw_ellipse(center + Vector2(18.0 * s, 2.0 * s), 16.0 * s, 8.0 * s, col)
	_draw_ellipse(center + Vector2(-18.0 * s, 3.0 * s), 14.0 * s, 7.0 * s, col)


func _draw_sea(horizon: float) -> void:
	var bands := 14
	for i in bands:
		var t := float(i) / float(bands - 1)
		var col := Palette.SEA_SHALLOW.lerp(Palette.SEA_MID, t)
		var h := (size.y - horizon) / float(bands) + 1.0
		draw_rect(
			Rect2(0.0, horizon + i * ((size.y - horizon) / float(bands)), size.x, h), col
		)
	# 水平線ハイライト
	draw_rect(Rect2(0.0, horizon - 2.0, size.x, 3.0), Color(1.0, 1.0, 1.0, 0.5))
	# 波の筋
	for i in 22:
		var y := horizon + 8.0 + float(i % 6) * ((size.y - horizon) / 7.0)
		var x := (
			fmod(float(i) * 97.0 + _time * (10.0 + float(i % 3) * 4.0), size.x + 80.0) - 40.0
		)
		var w := 18.0 + float(i % 4) * 8.0
		draw_line(
			Vector2(x, y), Vector2(x + w, y), Color(1.0, 1.0, 1.0, 0.16 + 0.1 * sin(_time + i)), 2.0
		)
	# きらめき
	for i in 12:
		var sx := fmod(float(i) * 153.0 + _time * 14.0, size.x)
		var sy := horizon + 6.0 + float(i % 4) * ((size.y - horizon) * 0.18)
		var tw: float = 0.4 + 0.6 * abs(sin(_time * 2.0 + i))
		draw_circle(Vector2(sx, sy), 1.6, Color(1.0, 1.0, 1.0, 0.6 * tw))


func _draw_dock() -> void:
	var top := size.y * 0.74
	# デッキ板
	var deck := PackedVector2Array(
		[
			Vector2(size.x, top),
			Vector2(size.x * 0.60, top),
			Vector2(size.x * 0.64, top + 16.0),
			Vector2(size.x, top + 16.0),
		]
	)
	draw_colored_polygon(deck, Palette.WOOD)
	# 支え柱
	for i in 4:
		var px := size.x * (0.66 + float(i) * 0.09)
		draw_rect(Rect2(px, top + 14.0, 12.0, size.y - (top + 14.0)), Palette.WOOD_DARK)
	# 板の継ぎ目
	for i in 5:
		var lx := size.x * 0.60 + float(i) * (size.x * 0.40 / 5.0) + 6.0
		draw_line(Vector2(lx, top), Vector2(lx + 4.0, top + 16.0), Palette.WOOD_DARK, 1.5)


func _draw_angler() -> void:
	var base_y := size.y * 0.74
	var p := Vector2(size.x * 0.69, base_y)
	# 足元の影
	_draw_ellipse(p + Vector2(0.0, 2.0), 18.0, 5.0, Color(0.0, 0.0, 0.0, 0.25))
	# 胴体（服）
	draw_rect(Rect2(p.x - 7.0, p.y - 32.0, 14.0, 26.0), Color("#3a4a5e"))
	draw_rect(Rect2(p.x - 7.0, p.y - 10.0, 14.0, 4.0), Color("#2a3848"))  # 腰帯
	# 頭（肌）
	draw_circle(p + Vector2(0.0, -38.0), 8.0, Color("#e8c39a"))
	# 麦わら帽子
	draw_circle(p + Vector2(0.0, -42.0), 9.5, Color("#e3c987"))
	draw_arc(p + Vector2(0.0, -42.0), 9.5, 0.0, PI, 10, Color("#bda15c"), 2.0)
	# 竿（斜め左上へ）
	var rod_base := p + Vector2(-5.0, -28.0)
	var rod_tip := p + Vector2(-50.0, -58.0)
	draw_line(rod_base, rod_tip, Color("#6a4a28"), 3.0)
	draw_circle(rod_tip, 2.0, Color("#3a2410"))


func _draw_line_and_bobber(horizon: float) -> void:
	var base_y := size.y * 0.74
	var rod_tip := Vector2(size.x * 0.69, base_y) + Vector2(-50.0, -58.0)
	var bx := size.x * 0.40
	var surface_y := horizon + (size.y - horizon) * 0.12
	var bob_y := surface_y + _bobber_dip * 42.0 + sin(_time * 3.0) * 1.5
	# 糸（たるみ付き）
	var mid := Vector2((rod_tip.x + bx) * 0.5, (rod_tip.y + bob_y) * 0.5 + 8.0)
	draw_polyline(
		PackedVector2Array([rod_tip, mid, Vector2(bx, bob_y)]), Color(1.0, 1.0, 1.0, 0.7), 1.5, false
	)
	# 浮標（赤／白）
	draw_circle(Vector2(bx, bob_y), 5.5, Color("#e0533b"))
	draw_circle(Vector2(bx, bob_y - 2.5), 4.5, Color("#fff0b5"))
	# 水しぶき（BITE）
	if _splash > 0.0:
		for i in 9:
			var ang := -PI * 0.5 + (float(i) / 8.0 - 0.5) * PI * 0.9
			var r := (1.0 - _splash) * 30.0
			var sp := Vector2(bx, surface_y) + Vector2(cos(ang), sin(ang)) * r
			draw_circle(sp, 2.2, Color(1.0, 1.0, 1.0, _splash * 0.85))
		_draw_ellipse(
			Vector2(bx, surface_y), 16.0 * (1.0 - _splash * 0.3), 4.5, Color(1.0, 1.0, 1.0, _splash * 0.3)
		)


func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color, points := 28) -> void:
	var arr := PackedVector2Array()
	arr.resize(points)
	for i in points:
		var angle := TAU * float(i) / float(points)
		arr[i] = center + Vector2(cos(angle) * rx, sin(angle) * ry)
	draw_colored_polygon(arr, color)


func _draw_frame() -> void:
	for i in 6:
		var alpha := 0.22 - float(i) * 0.03
		var inset := float(i) * 2.0
		draw_rect(
			Rect2(inset, inset, size.x - inset * 2.0, size.y - inset * 2.0),
			Color(0.0, 0.03, 0.08, alpha),
			false,
			1.0
		)
