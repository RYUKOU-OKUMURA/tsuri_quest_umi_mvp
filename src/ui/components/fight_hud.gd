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
const ICON_TENSION := 4
const ICON_STAMINA := 5
const ICON_BAIT := 6

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
	custom_minimum_size = Vector2(0.0, 224.0)
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

	if _hud_frame != null:
		draw_texture_rect(_hud_frame, rect, false, Color.WHITE)
	else:
		_draw_panel(rect, Palette.FIGHT_HUD_FALLBACK_PANEL_FILL, Palette.GOLD_DEEP, Palette.GOLD)

	if _simulator_state() == FishingSimulator.State.READY:
		var ready_rect := Rect2(size.x * 0.014, size.y * 0.065, size.x * 0.972, size.y * 0.875)
		if _hud_frame == null:
			ready_rect = rect.grow(-10.0)
		_draw_ready_controls(font, ready_rect)
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
	var gap := 10.0
	var menu_w := rect.size.x * (0.175 if _hud_frame != null else 0.210)
	var lure_w := rect.size.x * (0.405 if _hud_frame != null else 0.375)
	var cast_w := rect.size.x - lure_w - menu_w - gap * 2.0
	var lure_rect := Rect2(rect.position, Vector2(lure_w, rect.size.y))
	var cast_rect := Rect2(Vector2(lure_rect.end.x + gap, rect.position.y), Vector2(cast_w, rect.size.y))
	var menu_rect := Rect2(Vector2(cast_rect.end.x + gap, rect.position.y), Vector2(menu_w, rect.size.y))
	_main_rect = Rect2()
	_reel_rect = Rect2()
	_give_rect = Rect2()
	_lure_prev_rect = Rect2()
	_lure_next_rect = Rect2()

	if bool(shark_lure_selector.get("danger", false)):
		_draw_ready_shark_lure_panel(font, lure_rect)
	else:
		_draw_ready_bait_panel(font, lure_rect)
	_draw_ready_cast_panel(font, cast_rect)
	_draw_ready_menu_panel(font, menu_rect)


func _draw_ready_shark_lure_panel(font: Font, rect: Rect2) -> void:
	_draw_ready_panel(rect, Palette.PARCHMENT, Palette.WOOD_DARK, Palette.GOLD)
	var inner := rect.grow(-10.0)
	_draw_text(font, "サメ餌魚", inner.position + Vector2(6.0, 21.0), 17 if _hud_frame != null else 18, Palette.FIGHT_HUD_DARK_INK, 0)
	var count := int(shark_lure_selector.get("candidate_count", 0))
	var arrows_enabled := count > 1
	var arrow_w := 34.0
	_lure_prev_rect = Rect2(inner.position + Vector2(2.0, 42.0), Vector2(arrow_w, inner.size.y - 54.0))
	_lure_next_rect = Rect2(Vector2(inner.end.x - arrow_w - 2.0, inner.position.y + 42.0), Vector2(arrow_w, inner.size.y - 54.0))
	_draw_ready_arrow(font, _lure_prev_rect, "<", arrows_enabled)
	_draw_ready_arrow(font, _lure_next_rect, ">", arrows_enabled)

	var card := Rect2(
		Vector2(_lure_prev_rect.end.x + 8.0, inner.position.y + 34.0),
		Vector2(_lure_next_rect.position.x - _lure_prev_rect.end.x - 16.0, inner.size.y - 40.0)
	)
	_draw_ready_panel(card, Color(Palette.PARCHMENT_DEEP, 0.92), Palette.GOLD_DEEP, Palette.GOLD_BRIGHT)
	var fish_id := String(shark_lure_selector.get("fish_id", ""))
	if fish_id.is_empty():
		_draw_bait_icon(card.position + Vector2(56.0, card.size.y * 0.57))
		_draw_text(font, "餌魚なし", card.position + Vector2(112.0, 42.0), 22, Palette.FIGHT_HUD_DARK_INK, 0)
		_draw_text(font, "通常サメ狙い", card.position + Vector2(112.0, 66.0), 14, Palette.FIGHT_HUD_HINT_NOTE, 0)
		return

	var fish: Dictionary = shark_lure_selector.get("fish", {})
	var fish_name := String(fish.get("name", fish_id))
	var inventory_count := int(shark_lure_selector.get("count", 0))
	var remaining := int(shark_lure_selector.get("remaining", 0))
	var total_charges := int(shark_lure_selector.get("total_charges", 0))
	var portrait := Rect2(card.position + Vector2(14.0, 17.0), Vector2(86.0, card.size.y - 30.0))
	_draw_ready_panel(portrait, Color(Palette.FIGHT_HUD_PANEL_BLUE_FILL, 0.82), Palette.GOLD_DEEP, Palette.GOLD)
	if _lure_portrait != null:
		_draw_texture_icon(_lure_portrait, portrait.grow(-5.0))
	else:
		_draw_bait_icon(portrait.position + portrait.size * 0.5)
	_draw_text_fit(font, fish_name, card.position + Vector2(112.0, 35.0), card.size.x - 126.0, 21, 15, Palette.FIGHT_HUD_DARK_INK, 0)
	_draw_text(font, "所持 x%d" % inventory_count, card.position + Vector2(112.0, 58.0), 14, Palette.FIGHT_HUD_HINT_NOTE, 0)
	var charge_text := "投げると1匹つかう"
	if remaining > 0:
		charge_text = "あと%d回" % remaining
		if inventory_count <= 0:
			charge_text = "%s（在庫0）" % charge_text
	elif total_charges > 1:
		charge_text = "1匹で最大%d回" % total_charges
	_draw_text_fit(font, charge_text, card.position + Vector2(112.0, 82.0), card.size.x - 126.0, 15, 11, Palette.FIGHT_HUD_DARK_INK, 0)
	if total_charges > 1:
		var pips := Rect2(card.position + Vector2(112.0, 96.0), Vector2(card.size.x - 126.0, 16.0))
		var displayed_charges := remaining if remaining > 0 else total_charges if inventory_count > 0 else 0
		_draw_lure_charge_pips(font, pips, displayed_charges, total_charges)


func _draw_ready_arrow(font: Font, rect: Rect2, label: String, enabled: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Palette.FIGHT_HUD_MENU_BUTTON_FRAME_FILL, 0.82 if enabled else 0.34)
	style.border_color = Color(Palette.FIGHT_HUD_MENU_BUTTON_BORDER, 0.82 if enabled else 0.28)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.shadow_color = Color(Color.BLACK, 0.20)
	style.shadow_size = 1
	draw_style_box(style, rect)
	var text_size := 22
	var text_w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size).x
	var color := Palette.TEXT_BONE if enabled else Color(Palette.TEXT_BONE, 0.38)
	_draw_text(font, label, rect.position + Vector2((rect.size.x - text_w) * 0.5, rect.size.y * 0.5 + 8.0), text_size, color, 1 if enabled else 0)


func _draw_ready_bait_panel(font: Font, rect: Rect2) -> void:
	_draw_ready_panel(rect, Palette.PARCHMENT, Palette.WOOD_DARK, Palette.GOLD)
	var icon_center := rect.position + Vector2(82.0, rect.size.y * 0.58)
	_draw_text(font, "使用中のエサ", rect.position + Vector2(18.0, 27.0), 18, Palette.FIGHT_HUD_DARK_INK, 0)
	if _bait_icon != null:
		_draw_bait_texture_icon(Rect2(icon_center - Vector2(42.0, 38.0), Vector2(84.0, 76.0)))
	else:
		_draw_bait_icon(icon_center)
	_draw_text_fit(font, _rig_name_text(), rect.position + Vector2(142.0, 68.0), rect.size.x - 160.0, 24, 16, Palette.FIGHT_HUD_DARK_INK, 0)
	_draw_text_fit(font, _rig_bait_text(), rect.position + Vector2(142.0, 96.0), rect.size.x - 160.0, 16, 12, Palette.FIGHT_HUD_HINT_NOTE, 0)


func _draw_ready_cast_panel(font: Font, rect: Rect2) -> void:
	_draw_ready_panel(rect, Color(Palette.FIGHT_HUD_PANEL_BLUE_FILL, 0.84), Palette.FIGHT_HUD_PANEL_BLUE_BORDER, Palette.GOLD)
	var title := "仕掛け投入"
	var title_size := 17
	var title_w := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x
	_draw_text(font, title, rect.position + Vector2((rect.size.x - title_w) * 0.5, 30.0), title_size, Palette.TEXT_BONE, 1)
	_main_rect = Rect2(rect.position + Vector2(34.0, 46.0), Vector2(rect.size.x - 68.0, rect.size.y - 66.0))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Palette.FIGHT_HUD_KEY_ENTER_FILL, 0.96)
	style.border_color = Palette.FIGHT_HUD_KEY_BORDER_ACTIVE
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(Color.BLACK, 0.28)
	style.shadow_size = 3
	draw_style_box(style, _main_rect)
	draw_line(_main_rect.position + Vector2(14.0, 7.0), _main_rect.position + Vector2(_main_rect.size.x - 14.0, 7.0), Color(Color.WHITE, 0.18), 1.0)
	var key_rect := Rect2(_main_rect.position + Vector2(22.0, _main_rect.size.y * 0.5 - 13.0), Vector2(78.0, 26.0))
	_draw_keyboard_key_cap(font, key_rect, "E / Enter", false, true)
	var label := "投げる"
	var label_size := 30
	var label_w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size).x
	_draw_text(font, label, _main_rect.position + Vector2((_main_rect.size.x - label_w) * 0.5 + 42.0, _main_rect.size.y * 0.5 + 10.0), label_size, Palette.TEXT_BONE, 2)


func _draw_ready_menu_panel(font: Font, rect: Rect2) -> void:
	_draw_ready_panel(rect, Palette.FIGHT_HUD_PANEL_BLUE_FILL, Palette.FIGHT_HUD_PANEL_BLUE_BORDER, Palette.GOLD)
	var gap := 8.0
	var button_h := (rect.size.y - 22.0 - gap) * 0.5
	_change_spot_rect = Rect2(rect.position + Vector2(10.0, 11.0), Vector2(rect.size.x - 20.0, button_h))
	_harbor_rect = Rect2(
		rect.position + Vector2(10.0, 11.0 + button_h + gap),
		Vector2(rect.size.x - 20.0, button_h)
	)
	_draw_menu_button(_change_spot_rect)
	_draw_menu_button(_harbor_rect)
	_draw_menu_row(font, _change_spot_rect.position + Vector2(25.0, _change_spot_rect.size.y * 0.62), "+", "釣り場変更")
	_draw_menu_row(font, _harbor_rect.position + Vector2(25.0, _harbor_rect.size.y * 0.62), "-", "港へ戻る")


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
	var fitted_size := font_size
	while (
		fitted_size > min_size
		and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted_size).x > max_width
	):
		fitted_size -= 1
	_draw_text(font, text, baseline, fitted_size, color, outline)


func _draw_lure_charge_pips(_font: Font, rect: Rect2, remaining: int, total: int) -> void:
	var pip_count := clampi(total, 0, 5)
	if pip_count <= 1:
		return
	var gap := 5.0
	var size := minf(12.0, (rect.size.x - gap * float(pip_count - 1)) / float(pip_count))
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


func _can_reel_controls() -> bool:
	return _simulator_state() == FishingSimulator.State.FIGHT


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
