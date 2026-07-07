class_name FightHud
extends Control
## 水中ファイト専用の下部HUD。
# 参照画像の「一枚の操作盤」に寄せるため、ゲージ・深度・操作ヒントをまとめて描画する。

signal main_action_pressed
signal reel_changed(active: bool)
signal give_line_changed(active: bool)
signal harbor_pressed
signal change_spot_pressed
signal shark_lure_previous_pressed
signal shark_lure_next_pressed

const GameFontsScript = preload("res://src/ui/game_fonts.gd")
const FightFishAssetsScript = preload("res://src/ui/fight_fish_assets.gd")
const HUD_FRAME_PATH := "res://assets/showcase/underwater/fight_hud_frame.png"
const ICON_SHEET_PATH := "res://assets/showcase/underwater/fight_icon_sheet.png"
const HUD_BAIT_ICON_PATH := "res://assets/showcase/underwater/hud_bait_icon.png"
const HUD_TENSION_ICON_PATH := "res://assets/showcase/underwater/hud_tension_icon.png"
const HUD_STAMINA_ICON_PATH := "res://assets/showcase/underwater/hud_stamina_icon.png"
const HUD_KEY_PLUS_PATH := "res://assets/showcase/underwater/hud_key_plus.png"
const HUD_KEY_MINUS_PATH := "res://assets/showcase/underwater/hud_key_minus.png"
const COMMON_ACTION_BUTTON_PATH := "res://assets/showcase/common/action_button_frame.png"
const COMMON_BUTTON_PATH := "res://assets/showcase/common/button_frame.png"
const COMMON_BUTTON_PRIMARY_PATH := "res://assets/showcase/common/button_frame_primary.png"
const COMMON_CARD_FRAME_PATH := "res://assets/showcase/common/card_frame.png"
const COMMON_PARCHMENT_CARD_PATH := "res://assets/showcase/common/parchment_card.png"
const DEFAULT_HUD_HEIGHT := 224.0
const FIGHT_SLIM_HUD_HEIGHT := 140.0
const ICON_TENSION := 4
const ICON_STAMINA := 5
const ICON_BAIT := 6
const KIT_ACTION_MARGINS := Vector4(36.0, 18.0, 36.0, 18.0)
const KIT_BUTTON_MARGINS := Vector4(42.0, 22.0, 42.0, 22.0)
const KIT_KEY_CAP_MARGINS := Vector4(28.0, 14.0, 28.0, 14.0)
const KIT_CARD_MARGINS := Vector4(30.0, 30.0, 30.0, 30.0)
const KIT_PARCHMENT_MARGINS := Vector4(34.0, 16.0, 34.0, 16.0)

var simulator: FishingSimulator
var fish_data: Dictionary = {}
var trip_stats: Dictionary = {}
var shark_lure_selector: Dictionary = {}

var _hud_frame: Texture2D
var _icons: Texture2D
var _bait_icon: Texture2D
var _tension_icon: Texture2D
var _stamina_icon: Texture2D
var _key_plus_icon: Texture2D
var _key_minus_icon: Texture2D
var _common_action_button_frame: Texture2D
var _common_button_frame: Texture2D
var _common_button_primary_frame: Texture2D
var _common_card_frame: Texture2D
var _common_parchment_card: Texture2D

var _main_rect := Rect2()
var _reel_rect := Rect2()
var _give_rect := Rect2()
var _harbor_rect := Rect2()
var _change_spot_rect := Rect2()
var _lure_prev_rect := Rect2()
var _lure_next_rect := Rect2()
var _reeling := false
var _giving := false
var _lure_portrait: Texture2D
var _lure_portrait_id := ""


func bind(value: FishingSimulator, fish: Dictionary, stats: Dictionary) -> void:
	simulator = value
	fish_data = fish.duplicate(true)
	trip_stats = stats.duplicate(true)
	queue_redraw()


func set_shark_lure_selector(data: Dictionary) -> void:
	shark_lure_selector = data.duplicate(true)
	var fish_id := String(shark_lure_selector.get("fish_id", ""))
	if fish_id.is_empty():
		_lure_portrait = null
		_lure_portrait_id = ""
	elif fish_id != _lure_portrait_id:
		var fish: Dictionary = shark_lure_selector.get("fish", {})
		_lure_portrait = _load_texture_if_exists(FightFishAssetsScript.card_portrait_path(fish))
		_lure_portrait_id = fish_id
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(0.0, DEFAULT_HUD_HEIGHT)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if ResourceLoader.exists(HUD_FRAME_PATH):
		_hud_frame = load(HUD_FRAME_PATH) as Texture2D
	if ResourceLoader.exists(ICON_SHEET_PATH):
		_icons = load(ICON_SHEET_PATH) as Texture2D
	if ResourceLoader.exists(HUD_BAIT_ICON_PATH):
		_bait_icon = load(HUD_BAIT_ICON_PATH) as Texture2D
	if ResourceLoader.exists(HUD_TENSION_ICON_PATH):
		_tension_icon = load(HUD_TENSION_ICON_PATH) as Texture2D
	if ResourceLoader.exists(HUD_STAMINA_ICON_PATH):
		_stamina_icon = load(HUD_STAMINA_ICON_PATH) as Texture2D
	if ResourceLoader.exists(HUD_KEY_PLUS_PATH):
		_key_plus_icon = load(HUD_KEY_PLUS_PATH) as Texture2D
	if ResourceLoader.exists(HUD_KEY_MINUS_PATH):
		_key_minus_icon = load(HUD_KEY_MINUS_PATH) as Texture2D
	if ResourceLoader.exists(COMMON_ACTION_BUTTON_PATH):
		_common_action_button_frame = load(COMMON_ACTION_BUTTON_PATH) as Texture2D
	if ResourceLoader.exists(COMMON_BUTTON_PATH):
		_common_button_frame = load(COMMON_BUTTON_PATH) as Texture2D
	if ResourceLoader.exists(COMMON_BUTTON_PRIMARY_PATH):
		_common_button_primary_frame = load(COMMON_BUTTON_PRIMARY_PATH) as Texture2D
	if ResourceLoader.exists(COMMON_CARD_FRAME_PATH):
		_common_card_frame = load(COMMON_CARD_FRAME_PATH) as Texture2D
	if ResourceLoader.exists(COMMON_PARCHMENT_CARD_PATH):
		_common_parchment_card = load(COMMON_PARCHMENT_CARD_PATH) as Texture2D


func _load_texture_if_exists(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if ResourceLoader.exists(path) or FileAccess.file_exists(path):
		return load(path) as Texture2D
	return null


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
		elif _lure_prev_rect.has_point(pos):
			shark_lure_previous_pressed.emit()
			accept_event()
		elif _lure_next_rect.has_point(pos):
			shark_lure_next_pressed.emit()
			accept_event()
		elif _main_rect.has_point(pos):
			main_action_pressed.emit()
			accept_event()
		elif _change_spot_rect.has_point(pos):
			change_spot_pressed.emit()
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
	var font := GameFontsScript.bold(get_theme_default_font())
	var rect := Rect2(Vector2.ZERO, size)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return

	var state := _simulator_state()
	if state == FishingSimulator.State.READY:
		_draw_ready_bar_background(rect)
		var ready_rect := Rect2(size.x * 0.014, size.y * 0.070, size.x * 0.972, size.y * 0.840)
		_draw_ready_controls(font, ready_rect)
		return

	if state == FishingSimulator.State.FIGHT or _is_intermediate_state(state):
		_draw_fight_bar_background(rect)
	elif _hud_frame != null:
		draw_texture_rect(_hud_frame, rect, false, Color.WHITE)
	else:
		_draw_panel(rect, Palette.FIGHT_HUD_FALLBACK_PANEL_FILL, Palette.GOLD_DEEP, Palette.GOLD)

	if state == FishingSimulator.State.FIGHT:
		var fight_rect := Rect2(size.x * 0.014, size.y * 0.085, size.x * 0.972, size.y * 0.83)
		if _hud_frame == null:
			fight_rect = rect.grow(-10.0)
		_draw_fight_slim_controls(font, fight_rect)
		return
	if _is_intermediate_state(state):
		var intermediate_rect := Rect2(size.x * 0.014, size.y * 0.085, size.x * 0.972, size.y * 0.83)
		if _hud_frame == null:
			intermediate_rect = rect.grow(-10.0)
		_draw_intermediate_slim_controls(font, intermediate_rect)
		return

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


func _draw_fight_slim_controls(font: Font, rect: Rect2) -> void:
	var gap := 10.0
	var action_w := clampf(rect.size.x * 0.34, 360.0, 430.0)
	var side_w := (rect.size.x - action_w - gap * 2.0) * 0.5
	var tension_rect := Rect2(rect.position, Vector2(side_w, rect.size.y))
	var action_rect := Rect2(Vector2(tension_rect.end.x + gap, rect.position.y), Vector2(action_w, rect.size.y))
	var stamina_rect := Rect2(Vector2(action_rect.end.x + gap, rect.position.y), Vector2(side_w, rect.size.y))

	_main_rect = Rect2()
	_lure_prev_rect = Rect2()
	_lure_next_rect = Rect2()
	_change_spot_rect = Rect2()
	_harbor_rect = Rect2()
	_reel_rect = Rect2()
	_give_rect = Rect2()

	_draw_tension(font, tension_rect)
	_draw_fight_action_zone(font, action_rect)
	_draw_stamina(font, stamina_rect)


func _draw_intermediate_slim_controls(font: Font, rect: Rect2) -> void:
	var gap := 10.0
	var action_w := clampf(rect.size.x * 0.36, 380.0, 470.0)
	var side_w := (rect.size.x - action_w - gap * 2.0) * 0.5
	var depth_rect := Rect2(rect.position, Vector2(side_w, rect.size.y))
	var action_rect := Rect2(Vector2(depth_rect.end.x + gap, rect.position.y), Vector2(action_w, rect.size.y))
	var status_rect := Rect2(Vector2(action_rect.end.x + gap, rect.position.y), Vector2(side_w, rect.size.y))

	_reel_rect = Rect2()
	_give_rect = Rect2()
	_lure_prev_rect = Rect2()
	_lure_next_rect = Rect2()
	_change_spot_rect = Rect2()
	_harbor_rect = Rect2()
	_main_rect = Rect2()

	_draw_intermediate_depth_panel(font, depth_rect)
	_draw_intermediate_action_panel(font, action_rect)
	_draw_intermediate_status_panel(font, status_rect)


func _draw_fight_bar_background(rect: Rect2) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Palette.FIGHT_HUD_FALLBACK_PANEL_FILL, 0.96)
	style.border_color = Color(Palette.GOLD_DEEP, 0.92)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.shadow_color = Color(Color.BLACK, 0.32)
	style.shadow_size = 2
	draw_style_box(style, rect.grow(-2.0))
	draw_rect(rect.grow(-7.0), Color(Palette.GOLD_BRIGHT, 0.10), false, 1.0)


func _draw_fight_action_zone(font: Font, rect: Rect2) -> void:
	_draw_ready_panel(rect, Color(Palette.FIGHT_HUD_PANEL_BLUE_FILL, 0.88), Palette.FIGHT_HUD_PANEL_BLUE_BORDER, Palette.GOLD)
	var depth_chip := Rect2(
		rect.position + Vector2(rect.size.x * 0.5 - 72.0, 7.0),
		Vector2(144.0, 28.0)
	)
	_draw_fight_depth_chip(font, depth_chip)
	var gap := 8.0
	var button_y := rect.position.y + 42.0
	var button_h := rect.size.y - 52.0
	var button_w := (rect.size.x - 26.0 - gap) * 0.5
	_reel_rect = Rect2(rect.position + Vector2(13.0, button_y - rect.position.y), Vector2(button_w, button_h))
	_give_rect = Rect2(Vector2(_reel_rect.end.x + gap, button_y), Vector2(button_w, button_h))
	_draw_fight_action_button(font, _reel_rect, "Space", "巻く", _is_reeling_active())
	_draw_fight_action_button(font, _give_rect, "Shift", "糸を出す", _is_giving_active())


func _draw_intermediate_depth_panel(font: Font, rect: Rect2) -> void:
	_draw_ready_panel(rect, Color(Palette.FIGHT_HUD_PANEL_BLUE_FILL, 0.86), Palette.FIGHT_HUD_PANEL_BLUE_BORDER, Palette.GOLD)
	_draw_text(font, "タナ（深さ）", rect.position + Vector2(16.0, 31.0), 18, Palette.TEXT_BONE, 1)
	var depth := 0.0
	if simulator != null:
		depth = simulator.depth
	var value := "%.1fm" % depth
	var value_size := 32
	var value_w := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, value_size).x
	_draw_text(font, value, rect.position + Vector2((rect.size.x - value_w) * 0.5, 74.0), value_size, Palette.FIGHT_HUD_DEPTH_VALUE_TEXT, 1)
	var arrow_x := rect.end.x - 26.0
	_draw_triangle(Vector2(arrow_x, rect.position.y + 43.0), 8.0, Palette.FIGHT_HUD_DEPTH_UP_ARROW, true)
	_draw_triangle(Vector2(arrow_x, rect.position.y + 70.0), 8.0, Palette.FIGHT_HUD_DEPTH_DOWN_ARROW, false)


func _draw_intermediate_action_panel(font: Font, rect: Rect2) -> void:
	_draw_ready_panel(rect, Color(Palette.FIGHT_HUD_PANEL_BLUE_FILL, 0.90), Palette.FIGHT_HUD_PANEL_BLUE_BORDER, Palette.GOLD)
	var bite := _simulator_state() == FishingSimulator.State.BITE
	var title := "アタリ発生" if bite else _intermediate_title()
	var title_size := 17
	var title_w := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x
	_draw_text(font, title, rect.position + Vector2((rect.size.x - title_w) * 0.5, 29.0), title_size, Palette.TEXT_BONE, 1)
	var button := Rect2(rect.position + Vector2(28.0, 42.0), Vector2(rect.size.x - 56.0, rect.size.y - 54.0))
	if bite:
		_main_rect = button
	_draw_intermediate_hook_button(font, button, bite)


func _draw_intermediate_hook_button(font: Font, rect: Rect2, enabled: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Palette.FIGHT_HUD_KEY_ENTER_FILL, 0.96 if enabled else 0.46)
	style.border_color = Palette.FIGHT_HUD_KEY_BORDER_ACTIVE if enabled else Color(Palette.FIGHT_HUD_KEY_BORDER, 0.46)
	style.set_border_width_all(2 if enabled else 1)
	style.set_corner_radius_all(7)
	style.shadow_color = Color(Color.BLACK, 0.30 if enabled else 0.16)
	style.shadow_size = 3 if enabled else 1
	draw_style_box(style, rect)
	draw_line(rect.position + Vector2(12.0, 7.0), rect.position + Vector2(rect.size.x - 12.0, 7.0), Color(Color.WHITE, 0.15 if enabled else 0.05), 1.0)
	var key_rect := Rect2(rect.position + Vector2(22.0, rect.size.y * 0.5 - 13.0), Vector2(82.0, 26.0))
	_draw_keyboard_key_cap(font, key_rect, "E / Enter", false, enabled)
	var label := "アワセ"
	var label_size := 29
	var label_color := Palette.TEXT_BONE if enabled else Color(Palette.TEXT_BONE, 0.58)
	var label_w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size).x
	_draw_text(font, label, rect.position + Vector2((rect.size.x - label_w) * 0.5 + 44.0, rect.size.y * 0.5 + 10.0), label_size, label_color, 2 if enabled else 1)


func _draw_intermediate_status_panel(font: Font, rect: Rect2) -> void:
	_draw_ready_panel(rect, Palette.PARCHMENT, Palette.WOOD_DARK, Palette.GOLD)
	var status := _intermediate_status_label()
	_draw_text(font, "反応", rect.position + Vector2(16.0, 28.0), 17, Palette.FIGHT_HUD_DARK_INK, 0)
	_draw_text_fit(font, status, rect.position + Vector2(68.0, 31.0), rect.size.x - 84.0, 22, 15, Palette.FIGHT_HUD_DARK_INK, 0)
	var note_font := GameFontsScript.regular(get_theme_default_font())
	_draw_text_fit(note_font, _intermediate_note_text(), rect.position + Vector2(16.0, 61.0), rect.size.x - 32.0, 14, 10, Palette.FIGHT_HUD_HINT_NOTE, 0)
	_draw_text_fit(note_font, _rig_bait_text(), rect.position + Vector2(16.0, 89.0), rect.size.x - 32.0, 13, 10, Palette.FIGHT_HUD_DARK_INK, 0)


func _draw_fight_depth_chip(font: Font, rect: Rect2) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Palette.FIGHT_HUD_MENU_BUTTON_FRAME_FILL, 0.92)
	style.border_color = Color(Palette.FIGHT_HUD_MENU_BUTTON_BORDER, 0.86)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.shadow_color = Color(Color.BLACK, 0.26)
	style.shadow_size = 2
	draw_style_box(style, rect)
	var depth := 0.0
	if simulator != null:
		depth = simulator.depth
	var text := "タナ %.1fm" % depth
	var text_size := 16
	var text_w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x
	_draw_text(font, text, rect.position + Vector2((rect.size.x - text_w) * 0.5 - 7.0, 20.0), text_size, Palette.TEXT_BONE, 1)
	var arrow_x := rect.end.x - 16.0
	_draw_triangle(Vector2(arrow_x, rect.position.y + 9.0), 5.0, Palette.FIGHT_HUD_DEPTH_UP_ARROW, true)
	_draw_triangle(Vector2(arrow_x, rect.position.y + 19.0), 5.0, Palette.FIGHT_HUD_DEPTH_DOWN_ARROW, false)


func _draw_fight_action_button(font: Font, rect: Rect2, key: String, label: String, active: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Palette.FIGHT_HUD_KEY_SPACE_FILL if key == "Space" else Palette.FIGHT_HUD_KEY_SHIFT_FILL, 0.94)
	if active:
		style.bg_color = style.bg_color.lightened(0.18)
	style.border_color = Palette.FIGHT_HUD_KEY_BORDER_ACTIVE if active else Color(Palette.FIGHT_HUD_KEY_BORDER, 0.90)
	style.set_border_width_all(2 if active else 1)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(Color.BLACK, 0.30)
	style.shadow_size = 3
	draw_style_box(style, rect)
	draw_line(rect.position + Vector2(10.0, 6.0), rect.position + Vector2(rect.size.x - 10.0, 6.0), Color(Color.WHITE, 0.14), 1.0)
	var key_rect := Rect2(rect.position + Vector2(12.0, rect.size.y * 0.5 - 13.0), Vector2(_keyboard_key_width(key), 26.0))
	_draw_keyboard_key_cap(font, key_rect, key, active, true)
	var label_size := 24 if label.length() <= 2 else 20
	var label_w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size).x
	var label_x := key_rect.end.x + maxf(8.0, (rect.end.x - key_rect.end.x - label_w) * 0.5)
	while label_x + label_w > rect.end.x - 8.0 and label_size > 17:
		label_size -= 1
		label_w = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size).x
	if label_x + label_w > rect.end.x - 8.0:
		label_x = rect.end.x - label_w - 8.0
	_draw_text(font, label, Vector2(label_x, rect.position.y + rect.size.y * 0.5 + 9.0), label_size, Palette.TEXT_BONE, 2)


func _draw_tension(font: Font, rect: Rect2) -> void:
	_draw_panel(rect, Palette.FIGHT_HUD_PANEL_DARK_FILL, Palette.FIGHT_HUD_PANEL_DARK_BORDER, Palette.GOLD_DEEP)
	var title_y := 25.0 if _hud_frame == null else 26.0
	var bar_y := 42.0 if _hud_frame == null else 43.0
	var icon_size := 34.0 if _hud_frame == null else 24.0
	var title_size := 19 if _hud_frame == null else 18
	var tension_icon_rect := Rect2(rect.position + Vector2(12.0, title_y - icon_size + 8.0), Vector2(icon_size, icon_size))
	if _hud_frame != null and _tension_icon != null:
		_draw_tension_texture_icon(tension_icon_rect)
	else:
		_draw_hud_icon(ICON_TENSION, tension_icon_rect, Palette.FIGHT_HUD_TENSION_ICON, Palette.FIGHT_STATUS_ICON_MODULATE_SOFT)
	_draw_text(font, "テンション", rect.position + Vector2(48.0 if _hud_frame == null else 40.0, title_y), title_size, Palette.TEXT_BONE, 1 if _hud_frame != null else 3)
	var ratio := 0.0
	var safe_min := 0.30
	var safe_max := 0.74
	if simulator != null:
		ratio = clampf(simulator.tension / maxf(simulator.line_break_limit(), 0.01), 0.0, 1.0)
		safe_min = simulator.safe_min()
		safe_max = simulator.safe_max()
	var bar := Rect2(rect.position + Vector2(24.0, bar_y), Vector2(rect.size.x - 58.0, 26.0 if _hud_frame == null else 24.0))
	_draw_segment_gauge(bar, ratio, safe_min, safe_max, true)
	var label_size := 16 if _hud_frame == null else 14
	var right_label_margin := 24.0 if _hud_frame == null else 34.0
	_draw_text(font, "ゆるい", rect.position + Vector2(24.0, rect.size.y - 8.0), label_size, Palette.FIGHT_HUD_TENSION_LOOSE_TEXT, 1 if _hud_frame != null else 2)
	var tight := "きつい"
	var tight_w := font.get_string_size(tight, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size).x
	_draw_text(font, tight, rect.position + Vector2(rect.size.x - tight_w - right_label_margin, rect.size.y - 8.0), label_size, Palette.FIGHT_HUD_TENSION_TIGHT_TEXT, 1 if _hud_frame != null else 2)


func _draw_depth(font: Font, rect: Rect2) -> void:
	_draw_panel(rect, Palette.FIGHT_HUD_PANEL_BLUE_FILL, Palette.FIGHT_HUD_PANEL_BLUE_BORDER, Palette.GOLD)
	var title_y := 22.0 if _hud_frame == null else 24.0
	var title := "タナ（深さ）"
	var title_size := 17 if _hud_frame == null else 15
	var title_w := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x
	var text_center_w := rect.size.x - (40.0 if _hud_frame != null else 0.0)
	_draw_text(font, title, rect.position + Vector2((text_center_w - title_w) * 0.5, title_y), title_size, Palette.TEXT_BONE, 1 if _hud_frame != null else 3)
	var depth := 0.0
	if simulator != null:
		depth = simulator.depth
	var value := "%.1fm" % depth
	var value_size := 34 if _hud_frame == null else 30
	var value_w := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, value_size).x
	_draw_text(font, value, rect.position + Vector2((text_center_w - value_w) * 0.5, 59.0 if _hud_frame == null else 63.0), value_size, Palette.FIGHT_HUD_DEPTH_VALUE_TEXT, 1 if _hud_frame != null else 4)
	var cx := rect.position.x + rect.size.x - (17.0 if _hud_frame != null else 22.0)
	var arrow_radius := 11.0 if _hud_frame != null else 14.0
	_draw_triangle(Vector2(cx, rect.position.y + 34.0), arrow_radius, Palette.FIGHT_HUD_DEPTH_UP_ARROW, true)
	_draw_triangle(Vector2(cx, rect.position.y + 72.0), arrow_radius, Palette.FIGHT_HUD_DEPTH_DOWN_ARROW, false)


func _draw_stamina(font: Font, rect: Rect2) -> void:
	_draw_panel(rect, Palette.FIGHT_HUD_PANEL_DARK_FILL, Palette.FIGHT_HUD_PANEL_DARK_BORDER, Palette.GOLD_DEEP)
	var title_y := 25.0 if _hud_frame == null else 26.0
	var bar_y := 42.0 if _hud_frame == null else 43.0
	var icon_size := 34.0 if _hud_frame == null else 24.0
	var title_size := 19 if _hud_frame == null else 18
	var stamina_icon_rect := Rect2(rect.position + Vector2(12.0, title_y - icon_size + 8.0), Vector2(icon_size, icon_size))
	if _hud_frame != null and _stamina_icon != null:
		_draw_texture_icon(_stamina_icon, stamina_icon_rect)
	else:
		_draw_hud_icon(ICON_STAMINA, stamina_icon_rect, Palette.FIGHT_HUD_STAMINA_ICON, Palette.FIGHT_STATUS_ICON_MODULATE_SOFT)
	_draw_text(font, "魚の体力", rect.position + Vector2(48.0 if _hud_frame == null else 40.0, title_y), title_size, Palette.TEXT_BONE, 1 if _hud_frame != null else 3)
	var ratio := 1.0
	if simulator != null:
		ratio = simulator.fish_stamina_ratio()
	var bar := Rect2(rect.position + Vector2(24.0, bar_y), Vector2(rect.size.x - (48.0 if _hud_frame == null else 58.0), 26.0 if _hud_frame == null else 24.0))
	_draw_segment_gauge(bar, ratio, 0.0, 1.0, false)
	var label_size := 16 if _hud_frame == null else 14
	var right_label_margin := 24.0 if _hud_frame == null else 34.0
	_draw_text(font, "弱い", rect.position + Vector2(24.0, rect.size.y - 8.0), label_size, Palette.TEXT_BONE, 1 if _hud_frame != null else 2)
	var strong := "強い"
	var strong_w := font.get_string_size(strong, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size).x
	_draw_text(font, strong, rect.position + Vector2(rect.size.x - strong_w - right_label_margin, rect.size.y - 8.0), label_size, Palette.TEXT_BONE, 1 if _hud_frame != null else 2)


func _draw_bottom_controls(font: Font, rect: Rect2) -> void:
	var gap := 10.0
	var bait_w := rect.size.x * (0.27 if _hud_frame == null else 0.265)
	var menu_w := rect.size.x * (0.24 if _hud_frame == null else 0.175)
	var hint_w := rect.size.x - bait_w - menu_w - gap * 2.0
	var bait := Rect2(rect.position, Vector2(bait_w, rect.size.y))
	var hint := Rect2(Vector2(bait.end.x + gap, rect.position.y), Vector2(hint_w, rect.size.y))
	var menu := Rect2(Vector2(hint.end.x + gap, rect.position.y), Vector2(menu_w, rect.size.y))
	var key_slots := _hint_key_slots(hint)
	_main_rect = Rect2()
	_reel_rect = Rect2()
	_give_rect = Rect2()
	_lure_prev_rect = Rect2()
	_lure_next_rect = Rect2()
	if _can_reel_controls():
		_reel_rect = key_slots[0]
		_give_rect = key_slots[1]
	var menu_button_gap := 6.0
	var menu_button_h := (menu.size.y - 20.0 - menu_button_gap) * 0.5
	_change_spot_rect = Rect2(menu.position + Vector2(9.0, 10.0), Vector2(menu.size.x - 18.0, menu_button_h))
	_harbor_rect = Rect2(
		menu.position + Vector2(9.0, 10.0 + menu_button_h + menu_button_gap),
		Vector2(menu.size.x - 18.0, menu_button_h)
	)

	_draw_panel(bait, Palette.PARCHMENT, Palette.WOOD_DARK, Palette.GOLD)
	var bait_text_x := 16.0
	var bait_label_size := 17 if _hud_frame == null else 15
	var bait_label_color := Palette.FIGHT_HUD_BAIT_LABEL_FRAME_TEXT if _hud_frame != null else Palette.FIGHT_HUD_BAIT_LABEL_FALLBACK_TEXT
	var bait_label_outline := 1 if _hud_frame != null else 0
	_draw_text(font, "使用中のエサ", bait.position + Vector2(bait_text_x, 19.0), bait_label_size, bait_label_color, bait_label_outline)
	if _bait_icon != null:
		_draw_bait_texture_icon(
			Rect2(bait.position + Vector2(46.0, bait.size.y * 0.5 - 30.0 + (2.0 if _hud_frame != null else 4.0)), Vector2(68.0, 62.0))
		)
	elif _icons != null:
		var bait_icon_size := 42.0 if _hud_frame != null else 46.0
		_draw_sheet_icon(
			ICON_BAIT,
			Rect2(bait.position + Vector2(58.0, bait.size.y * 0.5 - bait_icon_size * 0.5 + (5.0 if _hud_frame != null else 5.0)), Vector2(bait_icon_size, bait_icon_size))
		)
	else:
		_draw_bait_icon(bait.position + Vector2(82.0 if _hud_frame == null else 95.0, bait.size.y * 0.62))
	_draw_text(font, _rig_name_text(), bait.position + Vector2(116.0, bait.size.y * (0.56 if _hud_frame != null else 0.66)), 18 if _hud_frame != null else 19, Palette.FIGHT_HUD_DARK_INK, 0)
	_draw_text(font, _rig_bait_text(), bait.position + Vector2(116.0, bait.size.y * (0.74 if _hud_frame != null else 0.92)), 14 if _hud_frame != null else 16, Palette.FIGHT_HUD_DARK_INK, 0)

	_draw_panel(hint, Palette.PARCHMENT, Palette.WOOD_DARK, Palette.GOLD)
	var hint_title := "操作のヒント"
	if _hud_frame != null:
		var hint_title_size := 16
		var hint_title_w := font.get_string_size(hint_title, HORIZONTAL_ALIGNMENT_LEFT, -1, hint_title_size).x
		_draw_text(font, hint_title, hint.position + Vector2((hint.size.x - hint_title_w) * 0.5, 21.0), hint_title_size, Palette.TEXT_BONE, 1)
	else:
		_draw_text(font, hint_title, hint.position + Vector2(18.0, 21.0), 18, Palette.FIGHT_HUD_BAIT_LABEL_FALLBACK_TEXT, 0)
	_draw_operation_hints(font, key_slots)

	_draw_panel(menu, Palette.FIGHT_HUD_PANEL_BLUE_FILL, Palette.FIGHT_HUD_PANEL_BLUE_BORDER, Palette.GOLD)
	_draw_menu_button(_change_spot_rect)
	_draw_menu_button(_harbor_rect)
	if _hud_frame != null:
		_draw_menu_row(font, _change_spot_rect.position + Vector2(25.0, _change_spot_rect.size.y * 0.62), "+", "釣り場変更")
		_draw_menu_row(font, _harbor_rect.position + Vector2(25.0, _harbor_rect.size.y * 0.62), "-", "港へ戻る")
	else:
		_draw_key_row(font, _change_spot_rect.position + Vector2(12.0, _change_spot_rect.size.y * 0.62), "+", "釣り場変更")
		_draw_key_row(font, _harbor_rect.position + Vector2(12.0, _harbor_rect.size.y * 0.62), "-", "港へ戻る")


func _draw_ready_controls(font: Font, rect: Rect2) -> void:
	var gap := 12.0
	var menu_w := clampf(rect.size.x * 0.205, 185.0, 225.0)
	var lure_w := clampf(rect.size.x * 0.405, 365.0, 440.0)
	var cast_w := rect.size.x - lure_w - menu_w - gap * 2.0
	var lure_rect := Rect2(rect.position, Vector2(lure_w, rect.size.y))
	var cast_rect := Rect2(Vector2(lure_rect.end.x + gap, rect.position.y), Vector2(cast_w, rect.size.y))
	var menu_rect := Rect2(Vector2(cast_rect.end.x + gap, rect.position.y), Vector2(menu_w, rect.size.y))
	_main_rect = Rect2()
	_reel_rect = Rect2()
	_give_rect = Rect2()
	_lure_prev_rect = Rect2()
	_lure_next_rect = Rect2()
	_change_spot_rect = Rect2()
	_harbor_rect = Rect2()

	if bool(shark_lure_selector.get("danger", false)):
		_draw_ready_shark_lure_panel(font, lure_rect)
	else:
		_draw_ready_bait_panel(font, lure_rect)
	_draw_ready_cast_panel(font, cast_rect)
	_draw_ready_menu_panel(font, menu_rect)
	_draw_ready_zone_divider(lure_rect.end.x + gap * 0.5, rect.position.y + 8.0, rect.size.y - 16.0)
	_draw_ready_zone_divider(cast_rect.end.x + gap * 0.5, rect.position.y + 8.0, rect.size.y - 16.0)


func _draw_ready_shark_lure_panel(font: Font, rect: Rect2) -> void:
	var title_font := GameFontsScript.extra_bold(font)
	_draw_text_center(title_font, "サメ餌魚", Rect2(rect.position + Vector2(0.0, 0.0), Vector2(rect.size.x, 34.0)), 24, Palette.GOLD_BRIGHT, 2)
	var inner := rect.grow(-5.0)
	var count := int(shark_lure_selector.get("candidate_count", 0))
	var arrows_enabled := count > 1
	var arrow_w := 42.0
	var card_y := inner.position.y + 48.0
	var card_h := inner.size.y - 70.0
	var arrow_h := minf(106.0, card_h)
	var arrow_y := card_y + (card_h - arrow_h) * 0.5
	_lure_prev_rect = Rect2(inner.position + Vector2(0.0, arrow_y - inner.position.y), Vector2(arrow_w, arrow_h))
	_lure_next_rect = Rect2(Vector2(inner.end.x - arrow_w, arrow_y), Vector2(arrow_w, arrow_h))
	_draw_ready_arrow(font, _lure_prev_rect, "◀", arrows_enabled)
	_draw_ready_arrow(font, _lure_next_rect, "▶", arrows_enabled)

	var card := Rect2(
		Vector2(_lure_prev_rect.end.x + 9.0, card_y),
		Vector2(_lure_next_rect.position.x - _lure_prev_rect.end.x - 18.0, card_h)
	)
	_draw_ready_card_frame(card)
	var fish_id := String(shark_lure_selector.get("fish_id", ""))
	if fish_id.is_empty():
		var empty_icon := Rect2(card.position + Vector2(18.0, 18.0), Vector2(minf(card.size.x * 0.36, 96.0), card.size.y - 36.0))
		_draw_ready_bait_asset(empty_icon)
		var empty_text_x := empty_icon.end.x + 14.0
		var empty_text_w := card.end.x - empty_text_x - 16.0
		_draw_text_fit(title_font, "餌魚なし", Vector2(empty_text_x, card.position.y + 48.0), empty_text_w, 25, 17, Palette.FIGHT_HUD_DARK_INK, 0)
		_draw_text_fit(GameFontsScript.regular(font), "通常サメ狙い", Vector2(empty_text_x, card.position.y + 75.0), empty_text_w, 15, 11, Palette.FIGHT_HUD_HINT_NOTE, 0)
		return

	var fish: Dictionary = shark_lure_selector.get("fish", {})
	var fish_name := String(fish.get("name", fish_id))
	var inventory_count := int(shark_lure_selector.get("count", 0))
	var remaining := int(shark_lure_selector.get("remaining", 0))
	var total_charges := int(shark_lure_selector.get("total_charges", 0))
	var left_w := clampf(card.size.x * 0.58, 150.0, 176.0)
	var name_rect := Rect2(card.position + Vector2(12.0, card.size.y - 39.0), Vector2(left_w, 20.0))
	var portrait := Rect2(
		card.position + Vector2(10.0, 15.0),
		Vector2(left_w + 4.0, maxf(52.0, name_rect.position.y - card.position.y - 18.0))
	)
	if _lure_portrait != null:
		_draw_texture_icon(_lure_portrait, portrait)
	else:
		_draw_ready_bait_asset(portrait)
	_draw_text_center_fit(title_font, fish_name, name_rect, 14, 10, Palette.FIGHT_HUD_DARK_INK, 0)
	var right_x := name_rect.end.x + 12.0
	var right_rect := Rect2(
		Vector2(right_x, card.position.y + 14.0),
		Vector2(maxf(1.0, card.end.x - right_x - 14.0), maxf(1.0, name_rect.position.y - card.position.y - 20.0))
	)
	var count_rect := Rect2(right_rect.position, Vector2(right_rect.size.x, 34.0))
	_draw_text_right_fit(title_font, "x%d" % inventory_count, count_rect, 30, 20, Palette.FIGHT_HUD_DARK_INK, 0)
	var charge_text := "投げると1匹つかう"
	var stock_empty_note := false
	if remaining > 0:
		charge_text = "あと%d回" % remaining
		if inventory_count <= 0:
			stock_empty_note = true
	var charge_font := GameFontsScript.regular(font)
	var footer_note := ""
	if total_charges > 1:
		var pips_w := maxf(1.0, minf(74.0, right_rect.size.x))
		var pips := Rect2(Vector2(right_rect.position.x, card.position.y + 58.0), Vector2(pips_w, 20.0))
		var displayed_charges := remaining if remaining > 0 else total_charges if inventory_count > 0 else 0
		_draw_lure_charge_pips(font, pips, displayed_charges, total_charges)
		if remaining > 0:
			var charge_text_w := card.end.x - pips.end.x - 24.0
			if charge_text_w >= 44.0:
				_draw_text_fit(charge_font, charge_text, Vector2(pips.end.x + 8.0, card.position.y + 74.0), charge_text_w, 15, 10, Palette.FIGHT_HUD_DARK_INK, 0)
				if stock_empty_note:
					footer_note = "在庫0"
			else:
				footer_note = "%s（在庫0）" % charge_text if stock_empty_note else charge_text
		else:
			footer_note = charge_text
	else:
		footer_note = charge_text
	if not footer_note.is_empty():
		_draw_text_center(charge_font, footer_note, Rect2(Vector2(rect.position.x + 18.0, rect.end.y - 30.0), Vector2(rect.size.x - 36.0, 22.0)), 16, Palette.TEXT_BONE, 1)


func _draw_ready_arrow(font: Font, rect: Rect2, label: String, enabled: bool) -> void:
	if not _draw_kit_frame(_common_button_frame, rect, KIT_BUTTON_MARGINS, Color(Color.WHITE, 1.0 if enabled else 0.46)):
		_draw_ready_panel(rect, Palette.PARCHMENT, Palette.WOOD_DARK, Palette.GOLD)
	var text_size := 25
	var text_w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x
	var color := Palette.FIGHT_HUD_DARK_INK if enabled else Color(Palette.FIGHT_HUD_DARK_INK, 0.42)
	_draw_text(font, label, rect.position + Vector2((rect.size.x - text_w) * 0.5, rect.size.y * 0.5 + 8.0), text_size, color, 1 if enabled else 0)


func _draw_ready_bait_panel(font: Font, rect: Rect2) -> void:
	var title_font := GameFontsScript.extra_bold(font)
	_draw_text_center(title_font, "使用中のエサ", Rect2(rect.position, Vector2(rect.size.x, 34.0)), 23, Palette.GOLD_BRIGHT, 2)
	var card := Rect2(rect.position + Vector2(22.0, 44.0), Vector2(rect.size.x - 44.0, rect.size.y - 52.0))
	_draw_ready_card_frame(card)
	var portrait := Rect2(card.position + Vector2(18.0, 18.0), Vector2(minf(card.size.x * 0.36, 128.0), card.size.y - 36.0))
	_draw_ready_bait_asset(portrait)
	var text_x := portrait.end.x + 16.0
	var text_w := card.end.x - text_x - 18.0
	_draw_text_fit(title_font, _rig_name_text(), Vector2(text_x, card.position.y + 56.0), text_w, 27, 16, Palette.FIGHT_HUD_DARK_INK, 0)
	_draw_text_fit(GameFontsScript.regular(font), _rig_bait_text(), Vector2(text_x, card.position.y + 86.0), text_w, 16, 12, Palette.FIGHT_HUD_HINT_NOTE, 0)


func _draw_ready_cast_panel(font: Font, rect: Rect2) -> void:
	_main_rect = Rect2(rect.position + Vector2(12.0, 12.0), Vector2(rect.size.x - 24.0, rect.size.y - 24.0))
	if not _draw_kit_frame(_common_action_button_frame, _main_rect, KIT_ACTION_MARGINS):
		_draw_ready_panel(_main_rect, Color(Palette.FIGHT_HUD_PANEL_BLUE_FILL, 0.84), Palette.FIGHT_HUD_PANEL_BLUE_BORDER, Palette.GOLD)
	var key_rect := Rect2(
		_main_rect.position + Vector2((_main_rect.size.x - 124.0) * 0.5, 16.0),
		Vector2(124.0, 34.0)
	)
	_draw_ready_key_cap(font, key_rect, "E / Enter")
	var label := "投げる"
	var label_font := GameFontsScript.extra_bold(font)
	var label_size := 52
	while label_size > 34 and label_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size).x > _main_rect.size.x - 48.0:
		label_size -= 2
	var label_rect := Rect2(_main_rect.position + Vector2(0.0, 44.0), Vector2(_main_rect.size.x, _main_rect.size.y - 58.0))
	_draw_text_center(label_font, label, label_rect, label_size, Palette.TEXT_BONE, 3)


func _draw_ready_menu_panel(font: Font, rect: Rect2) -> void:
	var gap := 10.0
	var button_h := (rect.size.y - 28.0 - gap) * 0.5
	_change_spot_rect = Rect2(rect.position + Vector2(8.0, 14.0), Vector2(rect.size.x - 16.0, button_h))
	_harbor_rect = Rect2(
		rect.position + Vector2(8.0, 14.0 + button_h + gap),
		Vector2(rect.size.x - 16.0, button_h)
	)
	_draw_ready_menu_button(_change_spot_rect)
	_draw_ready_menu_button(_harbor_rect)
	_draw_ready_menu_row(font, _change_spot_rect, "+", "釣り場変更")
	_draw_ready_menu_row(font, _harbor_rect, "-", "港へ戻る")


func _draw_ready_bar_background(rect: Rect2) -> void:
	if _draw_kit_frame(_common_button_primary_frame, rect.grow(-2.0), KIT_BUTTON_MARGINS):
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Palette.FIGHT_HUD_FALLBACK_PANEL_FILL, 0.96)
	style.border_color = Color(Palette.GOLD_DEEP, 0.92)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.shadow_color = Color(Color.BLACK, 0.32)
	style.shadow_size = 2
	draw_style_box(style, rect.grow(-2.0))


func _draw_ready_card_frame(rect: Rect2) -> void:
	var drew := _draw_kit_frame(_common_parchment_card, rect, KIT_PARCHMENT_MARGINS)
	if _common_card_frame != null:
		drew = _draw_kit_frame(_common_card_frame, rect, KIT_CARD_MARGINS, Color(Color.WHITE, 0.96)) or drew
	if not drew:
		_draw_ready_panel(rect, Palette.PARCHMENT, Palette.WOOD_DARK, Palette.GOLD)


func _draw_ready_menu_button(rect: Rect2) -> void:
	if _draw_kit_frame(_common_button_primary_frame, rect, KIT_BUTTON_MARGINS):
		return
	_draw_menu_button(rect)


func _draw_ready_menu_row(font: Font, rect: Rect2, key: String, label: String) -> void:
	var center_y := rect.position.y + rect.size.y * 0.5
	var icon_rect := Rect2(Vector2(rect.position.x + 16.0, center_y - 13.0), Vector2(26.0, 26.0))
	var key_texture := _key_plus_icon if key == "+" else _key_minus_icon
	if key_texture != null:
		_draw_texture_icon(key_texture, icon_rect)
	else:
		draw_circle(icon_rect.position + icon_rect.size * 0.5, 13.0, Palette.FIGHT_HUD_MENU_KEY_BORDER)
		draw_circle(icon_rect.position + icon_rect.size * 0.5, 10.5, Palette.FIGHT_HUD_MENU_KEY_FILL)
		var key_w := font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		_draw_text(font, key, Vector2(icon_rect.position.x + (icon_rect.size.x - key_w) * 0.5, icon_rect.position.y + 19.0), 18, Palette.FIGHT_HUD_DARK_INK, 0)
	var label_font := GameFontsScript.extra_bold(font)
	var label_size := 17
	var label_x := icon_rect.end.x + 9.0
	var max_w := rect.end.x - label_x - 6.0
	while label_size > 13 and label_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size).x > max_w:
		label_size -= 1
	_draw_text(label_font, label, Vector2(label_x, center_y + 7.0), label_size, Palette.TEXT_BONE, 1)


func _draw_ready_zone_divider(x: float, top: float, height: float) -> void:
	draw_line(Vector2(x, top), Vector2(x, top + height), Color(Palette.GOLD_DEEP, 0.58), 1.2)
	draw_line(Vector2(x + 1.5, top + 7.0), Vector2(x + 1.5, top + height - 7.0), Color(Palette.FIGHT_HUD_PANEL_BLUE_BORDER, 0.44), 1.0)


func _draw_ready_bait_asset(target: Rect2) -> void:
	if _bait_icon != null:
		_draw_bait_texture_icon(target)
		return
	_draw_hud_icon(ICON_BAIT, target, Palette.FIGHT_HUD_BAIT_ICON_MID)


func _draw_ready_key_cap(font: Font, key_rect: Rect2, key: String) -> void:
	if not _draw_kit_frame(_common_button_primary_frame, key_rect, KIT_KEY_CAP_MARGINS):
		_draw_keyboard_key_cap(font, key_rect, key, false, true)
		return
	var key_font := GameFontsScript.bold(font)
	_draw_text_center(key_font, key, key_rect.grow(-3.0), 13, Palette.TEXT_BONE, 1)


func _draw_ready_panel(rect: Rect2, fill: Color, border: Color, highlight: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(Color.BLACK, 0.24)
	style.shadow_size = 2
	draw_style_box(style, rect)
	draw_rect(rect.grow(-5.0), Color(highlight, 0.18), false, 1.0)


func _draw_text_fit(
	font: Font,
	text: String,
	baseline: Vector2,
	max_width: float,
	font_size: int,
	min_size: int,
	color: Color,
	outline: int
) -> void:
	var fitted_size := _fit_font_size(font, text, font_size, min_size, max_width)
	var display := _fit_text(font, text, fitted_size, max_width)
	_draw_text_clipped(font, display, baseline, fitted_size, color, max_width, outline)


func _draw_text_center_fit(
	font: Font,
	text: String,
	rect: Rect2,
	font_size: int,
	min_size: int,
	color: Color,
	outline: int
) -> void:
	var fitted_size := _fit_font_size(font, text, font_size, min_size, rect.size.x)
	var display := _fit_text(font, text, fitted_size, rect.size.x)
	var ascent := font.get_ascent(fitted_size)
	var descent := font.get_descent(fitted_size)
	var baseline := rect.position + Vector2(0.0, (rect.size.y - ascent - descent) * 0.5 + ascent)
	if outline > 0:
		draw_string_outline(font, baseline, display, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, fitted_size, outline, Palette.FIGHT_HUD_TEXT_OUTLINE)
	draw_string(font, baseline, display, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, fitted_size, color)


func _draw_text_right_fit(
	font: Font,
	text: String,
	rect: Rect2,
	font_size: int,
	min_size: int,
	color: Color,
	outline: int
) -> void:
	var fitted_size := _fit_font_size(font, text, font_size, min_size, rect.size.x)
	var display := _fit_text(font, text, fitted_size, rect.size.x)
	var ascent := font.get_ascent(fitted_size)
	var descent := font.get_descent(fitted_size)
	var baseline := rect.position + Vector2(0.0, (rect.size.y - ascent - descent) * 0.5 + ascent)
	if outline > 0:
		draw_string_outline(font, baseline, display, HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x, fitted_size, outline, Palette.FIGHT_HUD_TEXT_OUTLINE)
	draw_string(font, baseline, display, HORIZONTAL_ALIGNMENT_RIGHT, rect.size.x, fitted_size, color)


func _fit_font_size(font: Font, text: String, base_size: int, minimum_size: int, max_width: float) -> int:
	for size_value in range(base_size, minimum_size - 1, -1):
		if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_value).x <= max_width:
			return size_value
	return minimum_size


func _fit_text(font: Font, text: String, font_size: int, max_width: float) -> String:
	if max_width <= 0.0:
		return ""
	if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= max_width:
		return text
	var ellipsis := "..."
	if font.get_string_size(ellipsis, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > max_width:
		return ""
	var result := text
	while result.length() > 0:
		result = result.left(result.length() - 1)
		var candidate := result + ellipsis
		if font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= max_width:
			return candidate
	return ellipsis


func _draw_text_clipped(
	font: Font,
	text: String,
	baseline: Vector2,
	font_size: int,
	color: Color,
	max_width: float,
	outline: int
) -> void:
	if text.is_empty() or max_width <= 0.0:
		return
	if outline > 0:
		draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, max_width, font_size, outline, Palette.FIGHT_HUD_TEXT_OUTLINE)
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, max_width, font_size, color)


func _draw_text_center(font: Font, text: String, rect: Rect2, font_size: int, color: Color, outline: int) -> void:
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var ascent := font.get_ascent(font_size)
	var descent := font.get_descent(font_size)
	var baseline := rect.position + Vector2(
		(rect.size.x - text_size.x) * 0.5,
		(rect.size.y - ascent - descent) * 0.5 + ascent
	)
	_draw_text(font, text, baseline, font_size, color, outline)


func _draw_kit_frame(texture: Texture2D, rect: Rect2, margins: Vector4, modulate: Color = Color.WHITE) -> bool:
	if texture == null or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return false
	var tex_size := texture.get_size()
	var left_src := minf(margins.x, tex_size.x * 0.45)
	var top_src := minf(margins.y, tex_size.y * 0.45)
	var right_src := minf(margins.z, tex_size.x - left_src)
	var bottom_src := minf(margins.w, tex_size.y - top_src)
	var left_dst := minf(left_src, rect.size.x * 0.5)
	var top_dst := minf(top_src, rect.size.y * 0.5)
	var right_dst := minf(right_src, rect.size.x - left_dst)
	var bottom_dst := minf(bottom_src, rect.size.y - top_dst)
	var src_x := [0.0, left_src, tex_size.x - right_src]
	var src_y := [0.0, top_src, tex_size.y - bottom_src]
	var src_w := [left_src, maxf(0.0, tex_size.x - left_src - right_src), right_src]
	var src_h := [top_src, maxf(0.0, tex_size.y - top_src - bottom_src), bottom_src]
	var dst_x := [rect.position.x, rect.position.x + left_dst, rect.end.x - right_dst]
	var dst_y := [rect.position.y, rect.position.y + top_dst, rect.end.y - bottom_dst]
	var dst_w := [left_dst, maxf(0.0, rect.size.x - left_dst - right_dst), right_dst]
	var dst_h := [top_dst, maxf(0.0, rect.size.y - top_dst - bottom_dst), bottom_dst]
	for row in range(3):
		for col in range(3):
			if src_w[col] <= 0.0 or src_h[row] <= 0.0 or dst_w[col] <= 0.0 or dst_h[row] <= 0.0:
				continue
			draw_texture_rect_region(
				texture,
				Rect2(Vector2(dst_x[col], dst_y[row]), Vector2(dst_w[col], dst_h[row])),
				Rect2(Vector2(src_x[col], src_y[row]), Vector2(src_w[col], src_h[row])),
				modulate
			)
	return true


func _draw_lure_charge_pips(_font: Font, rect: Rect2, remaining: int, total: int) -> void:
	var pip_count := clampi(total, 0, 5)
	if pip_count <= 1:
		return
	var gap := 5.0
	var size := minf(16.0, (rect.size.x - gap * float(pip_count - 1)) / float(pip_count))
	if size <= 0.0:
		return
	for index in range(pip_count):
		var center := rect.position + Vector2(float(index) * (size + gap) + size * 0.5, size * 0.5)
		var filled := index < remaining
		var color := Palette.GOLD_BRIGHT if filled else Color(Palette.WOOD_DARK, 0.28)
		draw_colored_polygon(
			PackedVector2Array([
				center + Vector2(0.0, -size * 0.52),
				center + Vector2(size * 0.52, 0.0),
				center + Vector2(0.0, size * 0.52),
				center + Vector2(-size * 0.52, 0.0),
			]),
			color
		)
		draw_polyline(
			PackedVector2Array([
				center + Vector2(0.0, -size * 0.52),
				center + Vector2(size * 0.52, 0.0),
				center + Vector2(0.0, size * 0.52),
				center + Vector2(-size * 0.52, 0.0),
				center + Vector2(0.0, -size * 0.52),
			]),
			Palette.GOLD_DEEP,
			1.0
		)


func _draw_segment_gauge(rect: Rect2, ratio: float, safe_min: float, safe_max: float, warm: bool) -> void:
	if _hud_frame == null:
		draw_rect(rect.grow(3.0), Palette.FIGHT_HUD_GAUGE_BACK_SHADOW, true)
		draw_rect(rect, Palette.FIGHT_HUD_GAUGE_TRACK_DARK, true)
		draw_rect(rect, Palette.FIGHT_HUD_GAUGE_TRACK_BORDER, false, 2.0)
	var segments := 18
	var gap := 1.5 if _hud_frame != null else 2.0
	var seg_w := (rect.size.x - gap * float(segments - 1)) / float(segments)
	if _hud_frame != null:
		draw_rect(rect.grow(2.0), Palette.FIGHT_HUD_GAUGE_FRAME_SHADOW, true)
		draw_rect(rect, Color(Palette.FIGHT_HUD_GAUGE_FRAME_TRACK, 0.74), true)
	for i in range(segments):
		var start := float(i) / float(segments)
		var filled := start < ratio
		var color := Palette.FIGHT_HUD_GAUGE_SEGMENT_EMPTY
		if filled:
			if warm:
				color = Palette.FIGHT_HUD_GAUGE_SEGMENT_GREEN.lerp(Palette.FIGHT_HUD_GAUGE_SEGMENT_YELLOW, clampf(start / 0.55, 0.0, 1.0))
				color = color.lerp(Palette.FIGHT_HUD_GAUGE_SEGMENT_RED, clampf((start - 0.55) / 0.45, 0.0, 1.0))
			else:
				color = Palette.FIGHT_HUD_GAUGE_STAMINA_GREEN.lerp(Palette.FIGHT_HUD_GAUGE_STAMINA_CYAN, start)
		var seg := Rect2(rect.position + Vector2(float(i) * (seg_w + gap), 2.0), Vector2(seg_w, rect.size.y - 4.0))
		if _hud_frame != null:
			var alpha := 0.94 if filled else 0.78
			var seg_color := Color(color.r, color.g, color.b, alpha)
			draw_rect(seg, seg_color, true)
			draw_rect(Rect2(seg.position, Vector2(seg.size.x, maxf(1.0, seg.size.y * 0.22))), Color(Color.WHITE, 0.10 if filled else 0.018), true)
			draw_rect(Rect2(Vector2(seg.position.x, seg.end.y - 2.0), Vector2(seg.size.x, 2.0)), Color(Color.BLACK, 0.16 if filled else 0.22), true)
		else:
			draw_rect(seg, color, true)
			draw_rect(seg, Color(Color.WHITE, 0.13), false, 1.0)
	if warm:
		for marker in [safe_min, safe_max]:
			var tick_x := rect.position.x + rect.size.x * clampf(marker, 0.0, 1.0)
			draw_line(Vector2(tick_x, rect.position.y + 2.0), Vector2(tick_x, rect.end.y - 2.0), Color(Color.WHITE, 0.18), 1.0)
		var x := rect.position.x + rect.size.x * clampf(ratio, 0.0, 1.0)
		var marker_color := Color(Palette.TEXT_BONE, 0.86)
		draw_line(Vector2(x + 1.5, rect.position.y - 1.0), Vector2(x + 1.5, rect.end.y + 3.0), Palette.FIGHT_SIDEBAR_PANEL_SHADOW, 2.0)
		draw_line(Vector2(x, rect.position.y - 2.0), Vector2(x, rect.end.y + 3.0), marker_color, 1.5)
		_draw_triangle(Vector2(x, rect.position.y - 7.0), 6.0, marker_color, false)


func _draw_panel(rect: Rect2, fill: Color, border: Color, highlight: Color) -> void:
	if _hud_frame != null:
		return
	draw_rect(rect, Palette.FIGHT_HUD_PANEL_SHADOW, true)
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


func _draw_menu_button(rect: Rect2) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Palette.FIGHT_HUD_MENU_BUTTON_FRAME_FILL, 0.86) if _hud_frame != null else Palette.FIGHT_HUD_MENU_BUTTON_FILL
	style.border_color = Color(Palette.FIGHT_HUD_MENU_BUTTON_BORDER, 0.88)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.shadow_color = Palette.FIGHT_SIDEBAR_PANEL_SHADOW
	style.shadow_size = 2
	draw_style_box(style, rect)
	draw_line(rect.position + Vector2(7.0, 4.0), rect.position + Vector2(rect.size.x - 7.0, 4.0), Color(Color.WHITE, 0.12), 1.0)


func _draw_text(font: Font, text: String, baseline: Vector2, font_size: int, color: Color, outline: int) -> void:
	if outline > 0:
		draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline, Palette.FIGHT_HUD_TEXT_OUTLINE)
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw_icon_badge(center: Vector2, color: Color) -> void:
	draw_circle(center, 11.0, Palette.FIGHT_HUD_BADGE_SHADOW)
	draw_circle(center, 8.0, color)
	draw_circle(center + Vector2(-2.0, -2.0), 2.5, Palette.FIGHT_HUD_BADGE_HIGHLIGHT)


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


func _draw_bait_texture_icon(target: Rect2) -> void:
	if _bait_icon == null:
		return
	var texture_size := _bait_icon.get_size()
	var scale := minf(target.size.x / texture_size.x, target.size.y / texture_size.y)
	var draw_size := texture_size * scale
	var draw_rect := Rect2(target.position + (target.size - draw_size) * 0.5, draw_size)
	draw_texture_rect(_bait_icon, draw_rect, false, Color.WHITE)


func _draw_tension_texture_icon(target: Rect2) -> void:
	if _tension_icon == null:
		return
	_draw_texture_icon(_tension_icon, target)


func _draw_texture_icon(texture: Texture2D, target: Rect2) -> void:
	_draw_texture_icon_modulated(texture, target, Color.WHITE)


func _draw_texture_icon_modulated(texture: Texture2D, target: Rect2, modulate: Color) -> void:
	var texture_size := texture.get_size()
	var scale := minf(target.size.x / texture_size.x, target.size.y / texture_size.y)
	var draw_size := texture_size * scale
	var draw_rect := Rect2(target.position + (target.size - draw_size) * 0.5, draw_size)
	draw_texture_rect(texture, draw_rect, false, modulate)


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
	draw_arc(center, 18.0, -0.8, 2.7, 18, Palette.FIGHT_HUD_BAIT_ICON_DARK, 6.0)
	draw_circle(center + Vector2(-10.0, -5.0), 9.0, Palette.FIGHT_HUD_BAIT_ICON_MID)
	draw_circle(center + Vector2(2.0, 3.0), 8.0, Palette.FIGHT_HUD_BAIT_ICON_LIGHT)
	draw_circle(center + Vector2(-12.0, -8.0), 2.0, Palette.FIGHT_HUD_BAIT_ICON_SHINE)


func _draw_operation_hints(font: Font, key_slots: Array[Rect2]) -> void:
	var state := _simulator_state()
	var fight_enabled := state == FishingSimulator.State.FIGHT
	_draw_keyboard_hint(
		font,
		key_slots[0],
		"Space",
		"巻く",
		"長押し",
		_is_reeling_active(),
		fight_enabled
	)
	_draw_keyboard_hint(
		font,
		key_slots[1],
		"Shift",
		"糸を出す",
		"長押し",
		_is_giving_active(),
		fight_enabled
	)
	match state:
		FishingSimulator.State.READY:
			_main_rect = key_slots[2]
			_draw_keyboard_hint(font, key_slots[2], "E / Enter", "投げる", "仕掛け投入", false, true, true)
		FishingSimulator.State.BITE:
			_main_rect = key_slots[2]
			_draw_keyboard_hint(font, key_slots[2], "E / Enter", "アワセる", "食いつき中", false, true, true)
		FishingSimulator.State.FIGHT:
			_draw_safe_zone_hint(font, key_slots[2])
		FishingSimulator.State.CASTING, FishingSimulator.State.WAITING, FishingSimulator.State.APPROACH:
			_draw_status_hint(font, key_slots[2], "反応待ち", "魚影を待つ")
		_:
			_draw_status_hint(font, key_slots[2], "結果確認", "次の操作へ")


func _draw_keyboard_hint(
	font: Font,
	rect: Rect2,
	key: String,
	label: String,
	note: String,
	active: bool = false,
	enabled: bool = true,
	accent: bool = false
) -> void:
	var key_rect := Rect2(rect.position + Vector2(6.0, 4.0), Vector2(_keyboard_key_width(key), 23.0))
	_draw_keyboard_key_cap(font, key_rect, key, active, enabled or accent)
	var label_size := 17 if _hud_frame != null else 16
	if key == "E / Enter":
		label_size = 16
	var label_color := Palette.FIGHT_STATUS_BODY_TEXT if enabled or accent else Color(Palette.FIGHT_HUD_HINT_DISABLED_LABEL, 0.78)
	var note_color := Palette.FIGHT_HUD_HINT_NOTE if enabled or accent else Color(Palette.FIGHT_HUD_HINT_DISABLED_NOTE, 0.62)
	var label_x := key_rect.end.x + 6.0
	var label_baseline := key_rect.position.y + 17.0
	var label_w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size).x
	if label_x + label_w > rect.end.x - 2.0:
		label_x = key_rect.position.x
		label_baseline = key_rect.position.y + 38.0
	_draw_text(font, label, Vector2(label_x, label_baseline), label_size, label_color, 0)
	var note_font := GameFontsScript.regular(get_theme_default_font())
	var note_size := 10 if _hud_frame != null else 11
	var note_text := note
	var note_pos := Vector2(key_rect.position.x, key_rect.position.y + 38.0)
	if label_baseline > key_rect.position.y + 24.0:
		note_pos = Vector2(label_x + label_w + 5.0, label_baseline)
	var available_w := rect.end.x - note_pos.x - 2.0
	while note_font.get_string_size(note_text, HORIZONTAL_ALIGNMENT_LEFT, -1, note_size).x > available_w and note_size > 8:
		note_size = max(8, note_size - 1)
	_draw_text(note_font, note_text, note_pos, note_size, note_color, 0)


func _draw_keyboard_key_cap(font: Font, key_rect: Rect2, key: String, active: bool, enabled: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Palette.FIGHT_HUD_KEY_SPACE_FILL, 0.92 if enabled else 0.45)
	if key == "Shift":
		style.bg_color = Color(Palette.FIGHT_HUD_KEY_SHIFT_FILL, 0.92 if enabled else 0.45)
	elif key == "E / Enter":
		style.bg_color = Color(Palette.FIGHT_HUD_KEY_ENTER_FILL, 0.96 if enabled else 0.48)
	if active:
		style.bg_color = style.bg_color.lightened(0.18)
	style.border_color = Color(Palette.FIGHT_HUD_KEY_BORDER, 0.86 if enabled else 0.36)
	if active:
		style.border_color = Palette.FIGHT_HUD_KEY_BORDER_ACTIVE
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.shadow_color = Color(Color.BLACK, 0.24 if enabled else 0.10)
	style.shadow_size = 1
	draw_style_box(style, key_rect)
	draw_line(
		key_rect.position + Vector2(6.0, 4.0),
		key_rect.position + Vector2(key_rect.size.x - 6.0, 4.0),
		Color(Color.WHITE, 0.15 if enabled else 0.05),
		1.0
	)
	var key_size := 11 if key != "E / Enter" else 10
	var key_w := font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, key_size).x
	var text_color := Palette.FIGHT_HUD_KEY_TEXT if enabled else Color(Palette.FIGHT_HUD_KEY_TEXT, 0.55)
	_draw_text(font, key, key_rect.position + Vector2((key_rect.size.x - key_w) * 0.5, 16.0), key_size, text_color, 1 if enabled else 0)


func _draw_safe_zone_hint(font: Font, rect: Rect2) -> void:
	var gauge := Rect2(rect.position + Vector2(6.0, 9.0), Vector2(58.0, 12.0))
	draw_rect(gauge.grow(1.5), Color(Color.BLACK, 0.20), true)
	draw_rect(gauge, Color(Palette.FIGHT_HUD_SAFE_GAUGE_TRACK, 0.86), true)
	var segments := 5
	var gap := 1.5
	var seg_w := (gauge.size.x - gap * float(segments - 1)) / float(segments)
	for i in range(segments):
		var seg := Rect2(gauge.position + Vector2(float(i) * (seg_w + gap), 2.0), Vector2(seg_w, gauge.size.y - 4.0))
		var color := Palette.FIGHT_HUD_SAFE_GAUGE_FILL_DARK
		if i >= 1 and i <= 3:
			color = Palette.FIGHT_HUD_SAFE_GAUGE_FILL
		draw_rect(seg, color, true)
		draw_rect(Rect2(seg.position, Vector2(seg.size.x, 2.0)), Color(Color.WHITE, 0.08), true)
	_draw_text(font, "安全域", rect.position + Vector2(72.0, 19.0), 16 if _hud_frame != null else 15, Palette.FIGHT_STATUS_BODY_TEXT, 0)
	var note_font := GameFontsScript.regular(get_theme_default_font())
	_draw_text(note_font, "緑ゲージを保つ", rect.position + Vector2(6.0, 40.0), 10 if _hud_frame != null else 11, Palette.FIGHT_HUD_HINT_NOTE, 0)


func _draw_status_hint(font: Font, rect: Rect2, label: String, note: String) -> void:
	var dot := rect.position + Vector2(14.0, 16.0)
	draw_circle(dot + Vector2(1.0, 1.0), 5.0, Color(Color.BLACK, 0.18))
	draw_circle(dot, 4.5, Color(Palette.FIGHT_HUD_STATUS_DOT, 0.70))
	_draw_text(font, label, rect.position + Vector2(26.0, 20.0), 16 if _hud_frame != null else 15, Color(Palette.FIGHT_HUD_HINT_DISABLED_LABEL, 0.86), 0)
	var note_font := GameFontsScript.regular(get_theme_default_font())
	_draw_text(note_font, note, rect.position + Vector2(8.0, 40.0), 10 if _hud_frame != null else 11, Color(Palette.FIGHT_HUD_HINT_DISABLED_NOTE, 0.72), 0)


func _keyboard_key_width(key: String) -> float:
	match key:
		"Space":
			return 58.0
		"Shift":
			return 54.0
		"E / Enter":
			return 76.0
	return 44.0


func _simulator_state() -> int:
	if simulator == null:
		return FishingSimulator.State.READY
	return simulator.state


func _is_intermediate_state(state: int) -> bool:
	return (
		state == FishingSimulator.State.CASTING
		or state == FishingSimulator.State.WAITING
		or state == FishingSimulator.State.APPROACH
		or state == FishingSimulator.State.BITE
	)


func _can_reel_controls() -> bool:
	return _simulator_state() == FishingSimulator.State.FIGHT


func _intermediate_title() -> String:
	match _simulator_state():
		FishingSimulator.State.CASTING:
			return "仕掛け投入"
		FishingSimulator.State.WAITING:
			return "反応待ち"
		FishingSimulator.State.APPROACH:
			return "魚影接近"
	return "待機中"


func _intermediate_status_label() -> String:
	match _simulator_state():
		FishingSimulator.State.CASTING:
			return "投入中"
		FishingSimulator.State.WAITING:
			return "探索中"
		FishingSimulator.State.APPROACH:
			return "魚影あり"
		FishingSimulator.State.BITE:
			return "食いついた"
	return "待機中"


func _intermediate_note_text() -> String:
	match _simulator_state():
		FishingSimulator.State.CASTING:
			return "タナへ沈めている"
		FishingSimulator.State.WAITING:
			return "水面と糸を見る"
		FishingSimulator.State.APPROACH:
			return "まだ正体は見せない"
		FishingSimulator.State.BITE:
			return "すぐにアワセよう"
	return "次の反応を待つ"


func _rig_name_text() -> String:
	var rig_name := String(trip_stats.get("rig_name", "サビキ仕掛け"))
	if rig_name.ends_with("仕掛け"):
		rig_name = rig_name.trim_suffix("仕掛け")
	return rig_name


func _rig_bait_text() -> String:
	var lure_name := _shark_lure_fish_name()
	if not lure_name.is_empty():
		var fish_id := String(trip_stats.get("shark_lure_fish_id", ""))
		var charges: Dictionary = trip_stats.get("shark_lure_charges", {})
		var remaining := int(charges.get(fish_id, 0))
		if remaining > 0:
			return "餌魚：%s（あと%d回）" % [lure_name, remaining]
		return "餌魚：%s" % lure_name
	var bait_types: Array[String] = []
	for bait_variant in Array(trip_stats.get("rig_bait_types", [])):
		bait_types.append(String(bait_variant))
	if bait_types.is_empty():
		return "対応餌：--"
	return "対応餌：%s" % "、".join(PackedStringArray(bait_types))


func _shark_lure_fish_name() -> String:
	if String(trip_stats.get("spot_id", "")) != "danger_reef":
		return ""
	var fish_id := String(trip_stats.get("shark_lure_fish_id", ""))
	if fish_id.is_empty():
		return ""
	return String(trip_stats.get("shark_lure_fish_name", fish_id)).strip_edges()


func _is_reeling_active() -> bool:
	return _reeling or (simulator != null and simulator.reeling)


func _is_giving_active() -> bool:
	return _giving or (simulator != null and simulator.giving_line)


func _draw_key_row(font: Font, pos: Vector2, key: String, label: String) -> void:
	var key_rect := Rect2(pos + Vector2(0.0, -14.0), Vector2(28.0 if key.length() <= 1 else 46.0, 24.0))
	draw_rect(key_rect, Palette.FIGHT_HUD_KEY_ROW_FILL, true)
	draw_rect(key_rect, Palette.GOLD, false, 1.0)
	var key_size := 15
	var key_w := font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, key_size).x
	_draw_text(font, key, key_rect.position + Vector2((key_rect.size.x - key_w) * 0.5, 17.0), key_size, Color.WHITE, 1)
	var label_size := 14 if label.length() >= 6 else 16
	_draw_text(font, label, pos + Vector2(key_rect.size.x + 8.0, 3.0), label_size, Palette.FIGHT_HUD_DARK_INK if key != "+" and key != "-" else Palette.TEXT_BONE, 0 if key != "+" and key != "-" else 2)


func _draw_menu_row(font: Font, pos: Vector2, key: String, label: String) -> void:
	var center := pos + Vector2(0.0, -2.0)
	var key_texture := _key_texture(key)
	if _hud_frame != null and key_texture != null:
		_draw_texture_icon(key_texture, Rect2(center - Vector2(12.0, 12.0), Vector2(24.0, 24.0)))
	else:
		draw_circle(center + Vector2(1.5, 2.0), 11.5, Palette.FIGHT_SIDEBAR_PANEL_SHADOW)
		draw_circle(center, 10.0, Palette.FIGHT_HUD_MENU_KEY_FILL)
		draw_circle(center, 10.0, Palette.FIGHT_HUD_MENU_KEY_BORDER, false, 1.0)
		draw_line(center + Vector2(-5.5, -5.5), center + Vector2(5.5, -5.5), Palette.FIGHT_HUD_MENU_KEY_HIGHLIGHT, 1.0)
		var key_size := 16
		var key_w := font.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, key_size).x
		_draw_text(font, key, Vector2(center.x - key_w * 0.5, center.y + 5.0), key_size, Palette.FIGHT_HUD_DARK_INK, 0)
	var label_size := 14 if label.length() >= 6 else 15
	_draw_text(font, label, pos + Vector2(28.0, 4.0), label_size, Palette.TEXT_BONE, 1)


func _key_texture(key: String) -> Texture2D:
	match key:
		"+":
			return _key_plus_icon
		"-":
			return _key_minus_icon
	return null


func _hint_key_slots(hint: Rect2) -> Array[Rect2]:
	if _hud_frame == null:
		return [
			Rect2(hint.position + Vector2(8.0, 30.0), Vector2(hint.size.x * 0.30, hint.size.y - 34.0)),
			Rect2(hint.position + Vector2(hint.size.x * 0.35, 30.0), Vector2(hint.size.x * 0.30, hint.size.y - 34.0)),
			Rect2(hint.position + Vector2(hint.size.x - 128.0, 30.0), Vector2(120.0, 30.0)),
		]
	var slot_gap := 0.0
	var slot_w := (hint.size.x - 44.0) / 3.0
	var slot_y := hint.position.y + 31.0
	var slot_h := 48.0
	var x0 := hint.position.x + 22.0
	return [
		Rect2(Vector2(x0, slot_y), Vector2(slot_w, slot_h)),
		Rect2(Vector2(x0 + slot_w + slot_gap, slot_y), Vector2(slot_w, slot_h)),
		Rect2(Vector2(x0 + (slot_w + slot_gap) * 2.0, slot_y), Vector2(slot_w, slot_h)),
	]
