class_name FightHud
extends Control
## 水中ファイト専用の下部HUD。
# 参照画像の「一枚の操作盤」に寄せるため、ゲージ・深度・操作ヒントをまとめて描画する。

signal main_action_pressed
signal reel_changed(active: bool)
signal give_line_changed(active: bool)
signal harbor_pressed

const FightFontsScript = preload("res://src/ui/fight_fonts.gd")
const HUD_FRAME_PATH := "res://assets/showcase/underwater/fight_hud_frame.png"
const ICON_SHEET_PATH := "res://assets/showcase/underwater/fight_icon_sheet.png"
const ICON_TENSION := 4
const ICON_STAMINA := 5
const ICON_BAIT := 6

var simulator: FishingSimulator
var fish_data: Dictionary = {}
var trip_stats: Dictionary = {}

var _hud_frame: Texture2D
var _icons: Texture2D

var _main_rect := Rect2()
var _reel_rect := Rect2()
var _give_rect := Rect2()
var _harbor_rect := Rect2()
var _reeling := false
var _giving := false


func bind(value: FishingSimulator, fish: Dictionary, stats: Dictionary) -> void:
	simulator = value
	fish_data = fish.duplicate(true)
	trip_stats = stats.duplicate(true)
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(0.0, 178.0)
	if ResourceLoader.exists(HUD_FRAME_PATH):
		_hud_frame = load(HUD_FRAME_PATH) as Texture2D
	if ResourceLoader.exists(ICON_SHEET_PATH):
		_icons = load(ICON_SHEET_PATH) as Texture2D


func _process(_delta: float) -> void:
	if simulator != null:
		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse := event as InputEventMouseButton
	if mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	var pos := mouse.position
	if mouse.pressed:
		if _reel_rect.has_point(pos):
			_reeling = true
			reel_changed.emit(true)
			accept_event()
		elif _give_rect.has_point(pos):
			_giving = true
			give_line_changed.emit(true)
			accept_event()
		elif _main_rect.has_point(pos):
			main_action_pressed.emit()
			accept_event()
		elif _harbor_rect.has_point(pos):
			harbor_pressed.emit()
			accept_event()
	else:
		if _reeling:
			_reeling = false
			reel_changed.emit(false)
			accept_event()
		if _giving:
			_giving = false
			give_line_changed.emit(false)
			accept_event()


func _draw() -> void:
	var font := FightFontsScript.bold(get_theme_default_font())
	var rect := Rect2(Vector2.ZERO, size)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return

	if _hud_frame != null:
		draw_texture_rect(_hud_frame, rect, false, Color.WHITE)
	else:
		_draw_panel(rect, Color("#08223b"), Palette.GOLD_DEEP, Palette.GOLD)

	var gap := 10.0
	var top := Rect2(gap, gap, size.x - gap * 2.0, minf(92.0, size.y * 0.54))
	var bottom := Rect2(gap, top.end.y + gap, size.x - gap * 2.0, size.y - top.size.y - gap * 2.0)
	if _hud_frame != null:
		top = Rect2(size.x * 0.014, size.y * 0.065, size.x * 0.972, size.y * 0.455)
		bottom = Rect2(size.x * 0.014, size.y * 0.552, size.x * 0.972, size.y * 0.388)

	var depth_w := clampf(size.x * 0.14, 150.0, 190.0)
	if _hud_frame != null:
		depth_w = clampf(size.x * 0.210, 165.0, 205.0)
	var left_w := (top.size.x - depth_w - gap * 2.0) * (0.44 if _hud_frame == null else 0.50)
	var right_w := top.size.x - depth_w - left_w - gap * 2.0
	var tension_rect := Rect2(top.position, Vector2(left_w, top.size.y))
	var depth_rect := Rect2(Vector2(tension_rect.end.x + gap, top.position.y), Vector2(depth_w, top.size.y))
	var stamina_rect := Rect2(Vector2(depth_rect.end.x + gap, top.position.y), Vector2(right_w, top.size.y))

	_draw_tension(font, tension_rect)
	_draw_depth(font, depth_rect)
	_draw_stamina(font, stamina_rect)
	_draw_bottom_controls(font, bottom)


func _draw_tension(font: Font, rect: Rect2) -> void:
	_draw_panel(rect, Color("#0b1828"), Color("#122f4f"), Palette.GOLD_DEEP)
	var title_y := 25.0 if _hud_frame == null else 26.0
	var bar_y := 42.0 if _hud_frame == null else 43.0
	var icon_size := 34.0 if _hud_frame == null else 24.0
	var title_size := 19 if _hud_frame == null else 18
	_draw_hud_icon(ICON_TENSION, Rect2(rect.position + Vector2(12.0, title_y - icon_size + 8.0), Vector2(icon_size, icon_size)), Color("#ff5b63"), Color(1.0, 1.0, 1.0, 0.86))
	_draw_text(font, "テンション", rect.position + Vector2(48.0 if _hud_frame == null else 40.0, title_y), title_size, Palette.TEXT_BONE, 3)
	var ratio := 0.0
	var safe_min := 0.30
	var safe_max := 0.74
	if simulator != null:
		ratio = clampf(simulator.tension / maxf(simulator.line_break_limit(), 0.01), 0.0, 1.0)
		safe_min = simulator.safe_min()
		safe_max = simulator.safe_max()
	var bar := Rect2(rect.position + Vector2(24.0, bar_y), Vector2(rect.size.x - 58.0, 26.0 if _hud_frame == null else 24.0))
	_draw_segment_gauge(bar, ratio, safe_min, safe_max, true)
	var label_size := 16 if _hud_frame == null else 15
	var right_label_margin := 24.0 if _hud_frame == null else 34.0
	_draw_text(font, "ゆるい", rect.position + Vector2(24.0, rect.size.y - 8.0), label_size, Color("#72f47d"), 2)
	var tight := "きつい"
	var tight_w := font.get_string_size(tight, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size).x
	_draw_text(font, tight, rect.position + Vector2(rect.size.x - tight_w - right_label_margin, rect.size.y - 8.0), label_size, Color("#ff823e"), 2)


func _draw_depth(font: Font, rect: Rect2) -> void:
	_draw_panel(rect, Color("#0b355f"), Color("#08213c"), Palette.GOLD)
	var title_y := 22.0 if _hud_frame == null else 24.0
	var title := "タナ（深さ）"
	var title_size := 17 if _hud_frame == null else 15
	var title_w := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x
	var text_center_w := rect.size.x - (24.0 if _hud_frame != null else 0.0)
	_draw_text(font, title, rect.position + Vector2((text_center_w - title_w) * 0.5, title_y), title_size, Palette.TEXT_BONE, 3)
	var depth := 0.0
	if simulator != null:
		depth = simulator.depth
	var value := "%.1fm" % depth
	var value_size := 34 if _hud_frame == null else 32
	var value_w := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, value_size).x
	_draw_text(font, value, rect.position + Vector2((text_center_w - value_w) * 0.5, 59.0 if _hud_frame == null else 64.0), value_size, Color("#eaf6ff"), 4)
	var cx := rect.position.x + rect.size.x - 22.0
	_draw_triangle(Vector2(cx, rect.position.y + 34.0), 14.0, Color("#29baf7"), true)
	_draw_triangle(Vector2(cx, rect.position.y + 70.0), 14.0, Color("#ff6b3e"), false)


func _draw_stamina(font: Font, rect: Rect2) -> void:
	_draw_panel(rect, Color("#0b1828"), Color("#122f4f"), Palette.GOLD_DEEP)
	var title_y := 25.0 if _hud_frame == null else 26.0
	var bar_y := 42.0 if _hud_frame == null else 43.0
	var icon_size := 34.0 if _hud_frame == null else 24.0
	var title_size := 19 if _hud_frame == null else 18
	_draw_hud_icon(ICON_STAMINA, Rect2(rect.position + Vector2(12.0, title_y - icon_size + 8.0), Vector2(icon_size, icon_size)), Color("#6cc8ff"), Color(1.0, 1.0, 1.0, 0.86))
	_draw_text(font, "魚の体力", rect.position + Vector2(48.0 if _hud_frame == null else 40.0, title_y), title_size, Palette.TEXT_BONE, 3)
	var ratio := 1.0
	if simulator != null:
		ratio = simulator.fish_stamina_ratio()
	var bar := Rect2(rect.position + Vector2(24.0, bar_y), Vector2(rect.size.x - (48.0 if _hud_frame == null else 58.0), 26.0 if _hud_frame == null else 24.0))
	_draw_segment_gauge(bar, ratio, 0.0, 1.0, false)
	var label_size := 16 if _hud_frame == null else 15
	var right_label_margin := 24.0 if _hud_frame == null else 34.0
	_draw_text(font, "弱い", rect.position + Vector2(24.0, rect.size.y - 8.0), label_size, Color("#fff1c7"), 2)
	var strong := "強い"
	var strong_w := font.get_string_size(strong, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size).x
	_draw_text(font, strong, rect.position + Vector2(rect.size.x - strong_w - right_label_margin, rect.size.y - 8.0), label_size, Color("#fff1c7"), 2)


func _draw_bottom_controls(font: Font, rect: Rect2) -> void:
	var gap := 10.0
	var bait_w := rect.size.x * (0.28 if _hud_frame == null else 0.265)
	var menu_w := rect.size.x * (0.20 if _hud_frame == null else 0.190)
	var hint_w := rect.size.x - bait_w - menu_w - gap * 2.0
	var bait := Rect2(rect.position, Vector2(bait_w, rect.size.y))
	var hint := Rect2(Vector2(bait.end.x + gap, rect.position.y), Vector2(hint_w, rect.size.y))
	var menu := Rect2(Vector2(hint.end.x + gap, rect.position.y), Vector2(menu_w, rect.size.y))
	_main_rect = bait
	var key_slots := _hint_key_slots(hint)
	_reel_rect = key_slots[0]
	_give_rect = key_slots[1]
	_harbor_rect = Rect2(menu.position, menu.size)

	_draw_panel(bait, Palette.PARCHMENT, Palette.WOOD_DARK, Palette.GOLD)
	var bait_text_x := 16.0
	var bait_label_size := 17 if _hud_frame == null else 15
	_draw_text(font, "使用中のエサ", bait.position + Vector2(bait_text_x, 22.0), bait_label_size, Color("#6a4c2b"), 0)
	if _icons != null:
		var bait_icon_size := 42.0 if _hud_frame != null else 46.0
		_draw_sheet_icon(
			ICON_BAIT,
			Rect2(bait.position + Vector2(58.0, bait.size.y * 0.5 - bait_icon_size * 0.5 + (2.0 if _hud_frame != null else 5.0)), Vector2(bait_icon_size, bait_icon_size))
		)
	else:
		_draw_bait_icon(bait.position + Vector2(82.0 if _hud_frame == null else 95.0, bait.size.y * 0.62))
	_draw_text(font, "オキアミ", bait.position + Vector2(118.0, bait.size.y * (0.62 if _hud_frame != null else 0.66)), 20, Color("#2b2117"), 0)
	_draw_text(font, "× 17", bait.position + Vector2(124.0, bait.size.y * (0.86 if _hud_frame != null else 0.92)), 19, Color("#2b2117"), 0)

	_draw_panel(hint, Palette.PARCHMENT, Palette.WOOD_DARK, Palette.GOLD)
	_draw_text(font, "操作のヒント", hint.position + Vector2(18.0, 25.0), 18, Color("#6a4c2b"), 0)
	if _hud_frame != null:
		_draw_key_hint_compact(font, key_slots[0], "A", "巻く", "リールを巻く")
		_draw_key_hint_compact(font, key_slots[1], "B", "緩める", "ラインを出す")
		_draw_key_hint_compact(font, key_slots[2], "L/R", "調整", "テンション")
	else:
		_draw_key_hint(font, _reel_rect, "A", "巻く")
		_draw_key_hint(font, _give_rect, "B", "緩める")
		_draw_key_hint(font, key_slots[2], "L/R", "調整")

	_draw_panel(menu, Color("#0b355f"), Color("#08213c"), Palette.GOLD)
	_draw_key_row(font, menu.position + Vector2(22.0, menu.size.y * 0.42), "+", "ポーズ")
	_draw_key_row(font, menu.position + Vector2(22.0, menu.size.y * 0.78), "-", "港へ戻る")


func _draw_segment_gauge(rect: Rect2, ratio: float, safe_min: float, safe_max: float, warm: bool) -> void:
	if _hud_frame == null:
		draw_rect(rect.grow(3.0), Color(0.0, 0.0, 0.0, 0.35), true)
		draw_rect(rect, Color("#07101b"), true)
		draw_rect(rect, Color("#0f2a43"), false, 2.0)
	var segments := 18
	var gap := 1.5 if _hud_frame != null else 2.0
	var seg_w := (rect.size.x - gap * float(segments - 1)) / float(segments)
	if _hud_frame != null:
		draw_rect(rect.grow(2.0), Color(0.0, 0.0, 0.0, 0.22), true)
		draw_rect(rect, Color(0.0, 0.0, 0.0, 0.18), true)
	for i in range(segments):
		var start := float(i) / float(segments)
		var filled := start < ratio
		var color := Color("#172534")
		if filled:
			if warm:
				color = Color("#25d755").lerp(Color("#f1d94f"), clampf(start / 0.55, 0.0, 1.0))
				color = color.lerp(Color("#d95524"), clampf((start - 0.55) / 0.45, 0.0, 1.0))
			else:
				color = Color("#21d34a").lerp(Color("#16c6b5"), start)
		var seg := Rect2(rect.position + Vector2(float(i) * (seg_w + gap), 3.0), Vector2(seg_w, rect.size.y - 6.0))
		if _hud_frame != null:
			var alpha := 1.0 if filled else 0.32
			var seg_color := Color(color.r, color.g, color.b, alpha)
			draw_rect(seg, seg_color, true)
			draw_rect(Rect2(seg.position, Vector2(seg.size.x, maxf(1.0, seg.size.y * 0.24))), Color(1.0, 1.0, 1.0, 0.16 if filled else 0.05), true)
			draw_rect(Rect2(Vector2(seg.position.x, seg.end.y - 2.0), Vector2(seg.size.x, 2.0)), Color(0.0, 0.0, 0.0, 0.20), true)
			draw_rect(seg, Color(1.0, 1.0, 1.0, 0.10 if filled else 0.045), false, 1.0)
		else:
			draw_rect(seg, color, true)
			draw_rect(seg, Color(1.0, 1.0, 1.0, 0.13), false, 1.0)
	if warm:
		for marker in [safe_min, safe_max]:
			var tick_x := rect.position.x + rect.size.x * clampf(marker, 0.0, 1.0)
			draw_line(Vector2(tick_x, rect.position.y + 1.0), Vector2(tick_x, rect.end.y - 1.0), Color(1.0, 1.0, 1.0, 0.30), 1.0)
		var x := rect.position.x + rect.size.x * clampf(ratio, 0.0, 1.0)
		var marker_color := Color("#fff8df")
		draw_line(Vector2(x + 2.0, rect.position.y - 2.0), Vector2(x + 2.0, rect.end.y + 4.0), Color(0.0, 0.0, 0.0, 0.34), 2.0)
		draw_line(Vector2(x, rect.position.y - 3.0), Vector2(x, rect.end.y + 4.0), marker_color, 2.0)
		_draw_triangle(Vector2(x, rect.position.y - 8.0), 7.0, marker_color, false)


func _draw_panel(rect: Rect2, fill: Color, border: Color, highlight: Color) -> void:
	if _hud_frame != null:
		return
	draw_rect(rect, Color(0.0, 0.0, 0.0, 0.32), true)
	var body := rect.grow(-3.0)
	draw_rect(body, fill, true)
	draw_rect(body, border, false, 2.0)
	draw_rect(body.grow(-4.0), Color(highlight.r, highlight.g, highlight.b, 0.42), false, 1.0)
	for corner in [
		body.position + Vector2(8.0, 8.0),
		body.position + Vector2(body.size.x - 8.0, 8.0),
		body.position + Vector2(8.0, body.size.y - 8.0),
		body.position + Vector2(body.size.x - 8.0, body.size.y - 8.0),
	]:
		draw_circle(corner, 2.2, highlight)


func _draw_text(font: Font, text: String, baseline: Vector2, font_size: int, color: Color, outline: int) -> void:
	if outline > 0:
		draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline, Color(0.0, 0.0, 0.0, 0.7))
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw_icon_badge(center: Vector2, color: Color) -> void:
	draw_circle(center, 11.0, Color(0.0, 0.0, 0.0, 0.42))
	draw_circle(center, 8.0, color)
	draw_circle(center + Vector2(-2.0, -2.0), 2.5, Color(1.0, 1.0, 1.0, 0.55))


func _draw_hud_icon(icon_index: int, rect: Rect2, fallback_color: Color, modulate: Color = Color.WHITE) -> void:
	if _icons == null:
		_draw_icon_badge(rect.position + rect.size * 0.5, fallback_color)
		return
	_draw_sheet_icon(icon_index, rect, modulate)


func _draw_sheet_icon(icon_index: int, target: Rect2, modulate: Color = Color.WHITE) -> void:
	if _icons == null:
		return
	var cell_w := float(_icons.get_width()) / 3.0
	var cell_h := float(_icons.get_height()) / 3.0
	var col := icon_index % 3
	var row := icon_index / 3
	var src := Rect2(float(col) * cell_w, float(row) * cell_h, cell_w, cell_h)
	draw_texture_rect_region(_icons, target, src, modulate)


func _draw_triangle(center: Vector2, radius: float, color: Color, up: bool) -> void:
	var sign := -1.0 if up else 1.0
	draw_colored_polygon(
		PackedVector2Array([
			center + Vector2(0.0, sign * radius),
			center + Vector2(-radius * 0.82, -sign * radius * 0.55),
			center + Vector2(radius * 0.82, -sign * radius * 0.55),
		]),
		color
	)


func _draw_bait_icon(center: Vector2) -> void:
	draw_arc(center, 18.0, -0.8, 2.7, 18, Color("#8d2e1e"), 6.0)
	draw_circle(center + Vector2(-10.0, -5.0), 9.0, Color("#f08b42"))
	draw_circle(center + Vector2(2.0, 3.0), 8.0, Color("#f3a04c"))
	draw_circle(center + Vector2(-12.0, -8.0), 2.0, Color("#fff2ce"))


func _draw_key_hint(font: Font, rect: Rect2, key: String, label: String) -> void:
	if _hud_frame == null:
		draw_rect(rect, Color(0.0, 0.0, 0.0, 0.07), true)
		draw_rect(rect, Color("#c8b27f"), false, 1.0)
	_draw_key_row(font, rect.position + Vector2(14.0, 20.0), key, label)


func _draw_key_hint_compact(font: Font, rect: Rect2, key: String, label: String, note: String) -> void:
	var key_w := 36.0 if key.length() <= 1 else 54.0
	var key_rect := Rect2(rect.position + Vector2(8.0, 4.0), Vector2(key_w, 27.0))
	draw_rect(key_rect, Color("#253247"), true)
	draw_rect(key_rect, Color("#0d1524"), false, 2.0)
	draw_rect(key_rect.grow(-2.0), Color("#d5b56b"), false, 1.0)
	draw_line(key_rect.position + Vector2(4.0, 4.0), key_rect.position + Vector2(key_rect.size.x - 4.0, 4.0), Color(1.0, 1.0, 1.0, 0.20), 1.0)
	var key_size := 16
	var key_text_w := font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, key_size).x
	_draw_text(font, key, key_rect.position + Vector2((key_rect.size.x - key_text_w) * 0.5, 20.0), key_size, Color.WHITE, 1)
	var label_size := 18
	var label_pos := key_rect.position + Vector2(key_rect.size.x + 8.0, 20.0)
	var label_w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size).x
	var label_plate := Rect2(label_pos + Vector2(-4.0, -18.0), Vector2(label_w + 10.0, 21.0))
	draw_rect(label_plate, Color("#f5e6c5"), true)
	draw_rect(label_plate, Color(0.54, 0.37, 0.18, 0.32), false, 1.0)
	_draw_text(font, label, label_pos, label_size, Color("#2b2117"), 0)
	var note_size := 11
	var note_x := minf(label_pos.x, rect.end.x - font.get_string_size(note, HORIZONTAL_ALIGNMENT_LEFT, -1, note_size).x - 5.0)
	_draw_text(font, note, Vector2(note_x, key_rect.position.y + 36.0), note_size, Color("#5a4327"), 0)


func _draw_key_row(font: Font, pos: Vector2, key: String, label: String) -> void:
	var key_rect := Rect2(pos + Vector2(0.0, -14.0), Vector2(28.0 if key.length() <= 1 else 46.0, 24.0))
	draw_rect(key_rect, Color("#26344a"), true)
	draw_rect(key_rect, Palette.GOLD, false, 1.0)
	var key_size := 15
	var key_w := font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, key_size).x
	_draw_text(font, key, key_rect.position + Vector2((key_rect.size.x - key_w) * 0.5, 17.0), key_size, Color.WHITE, 1)
	_draw_text(font, label, pos + Vector2(key_rect.size.x + 8.0, 3.0), 16, Color("#2b2117") if key != "+" and key != "-" else Palette.TEXT_BONE, 0 if key != "+" and key != "-" else 2)


func _hint_key_slots(hint: Rect2) -> Array[Rect2]:
	if _hud_frame == null:
		return [
			Rect2(hint.position + Vector2(8.0, 30.0), Vector2(hint.size.x * 0.30, hint.size.y - 34.0)),
			Rect2(hint.position + Vector2(hint.size.x * 0.35, 30.0), Vector2(hint.size.x * 0.30, hint.size.y - 34.0)),
			Rect2(hint.position + Vector2(hint.size.x - 128.0, 30.0), Vector2(120.0, 30.0)),
		]
	var slot_gap := 10.0
	var slot_w := (hint.size.x - 40.0 - slot_gap * 2.0) / 3.0
	var slot_y := hint.position.y + 27.0
	var slot_h := 43.0
	var x0 := hint.position.x + 19.0
	return [
		Rect2(Vector2(x0, slot_y), Vector2(slot_w, slot_h)),
		Rect2(Vector2(x0 + slot_w + slot_gap, slot_y), Vector2(slot_w, slot_h)),
		Rect2(Vector2(x0 + (slot_w + slot_gap) * 2.0, slot_y), Vector2(slot_w, slot_h)),
	]
