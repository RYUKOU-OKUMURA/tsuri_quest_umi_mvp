class_name FightSidebar
extends Control
## 水中ファイト看板画面の右サイドバー。
# 魚カード、行動カード、タックルカードをまとめて描画し、参照画像の情報密度に寄せる。

const FightFontsScript = preload("res://src/ui/fight_fonts.gd")
const FightFishAssetsScript = preload("res://src/ui/fight_fish_assets.gd")
const SIDEBAR_FRAME_PATH := "res://assets/showcase/underwater/sidebar_frame.png"
const ICON_SHEET_PATH := "res://assets/showcase/underwater/fight_icon_sheet.png"
const ACTION_CARD_ICON_PATH := "res://assets/showcase/underwater/fight_action_card_icon.png"
const TACKLE_CARD_ICON_PATH := "res://assets/showcase/underwater/fight_tackle_card_icon.png"
const FISH_FRAME_COUNT := 4
const ICON_ACTION := 7
const ICON_TACKLE := 8

var simulator: FishingSimulator
var fish_data: Dictionary = {}
var trip_stats: Dictionary = {}

var _fish_sheet: Texture2D
var _fish_card_portrait: Texture2D
var _sidebar_frame: Texture2D
var _icons: Texture2D
var _action_card_icon: Texture2D
var _tackle_card_icon: Texture2D


func bind(value: FishingSimulator, fish: Dictionary, stats: Dictionary) -> void:
	simulator = value
	fish_data = fish.duplicate(true)
	trip_stats = stats.duplicate(true)
	_load_fish_assets_for_current_fish()
	queue_redraw()


func set_fish(fish: Dictionary, stats: Dictionary) -> void:
	fish_data = fish.duplicate(true)
	trip_stats = stats.duplicate(true)
	_load_fish_assets_for_current_fish()
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_load_fish_assets_for_current_fish()
	if ResourceLoader.exists(SIDEBAR_FRAME_PATH):
		_sidebar_frame = load(SIDEBAR_FRAME_PATH) as Texture2D
	if ResourceLoader.exists(ICON_SHEET_PATH):
		_icons = load(ICON_SHEET_PATH) as Texture2D
	if ResourceLoader.exists(ACTION_CARD_ICON_PATH):
		_action_card_icon = load(ACTION_CARD_ICON_PATH) as Texture2D
	if ResourceLoader.exists(TACKLE_CARD_ICON_PATH):
		_tackle_card_icon = load(TACKLE_CARD_ICON_PATH) as Texture2D


func _load_fish_assets_for_current_fish() -> void:
	_fish_sheet = _load_texture_if_exists(FightFishAssetsScript.sheet_path(fish_data))
	if _fish_sheet == null:
		_fish_sheet = _load_texture_if_exists(FightFishAssetsScript.LEGACY_SHEET_PATH)
	_fish_card_portrait = _load_texture_if_exists(FightFishAssetsScript.card_portrait_path(fish_data))
	if _fish_card_portrait == null:
		_fish_card_portrait = _load_texture_if_exists(FightFishAssetsScript.LEGACY_CARD_PORTRAIT_PATH)


func _load_texture_if_exists(path: String) -> Texture2D:
	if ResourceLoader.exists(path) or FileAccess.file_exists(path):
		return load(path) as Texture2D
	return null


func _process(_delta: float) -> void:
	if simulator != null:
		queue_redraw()


func _draw() -> void:
	var font := FightFontsScript.bold(get_theme_default_font())
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return

	var header := Rect2(0.0, 0.0, w, 30.0)
	var fish_card := Rect2()
	var action_card := Rect2()
	var tackle_card := Rect2()
	if _sidebar_frame != null:
		draw_texture_rect(_sidebar_frame, Rect2(Vector2.ZERO, size), false, Color.WHITE)
		header = Rect2(w * 0.0148, h * 0.0117, w * 0.9705, h * 0.0771)
		fish_card = Rect2(w * 0.0177, h * 0.0918, w * 0.9646, h * 0.4883)
		action_card = Rect2(w * 0.0148, h * 0.5918, w * 0.9705, h * 0.1953)
		tackle_card = Rect2(w * 0.0148, h * 0.8008, w * 0.9705, h * 0.1875)
	else:
		var gap := 7.0
		var action_h := clampf(h * 0.22, 86.0, 102.0)
		var tackle_h := clampf(h * 0.24, 92.0, 112.0)
		var fish_h := maxf(170.0, h - header.size.y - action_h - tackle_h - gap * 3.0)
		fish_card = Rect2(0.0, header.end.y + gap, w, fish_h)
		action_card = Rect2(0.0, fish_card.end.y + gap, w, action_h)
		tackle_card = Rect2(0.0, action_card.end.y + gap, w, tackle_h)

	_draw_header(font, header)
	_draw_fish_card(font, fish_card)
	_draw_action_card(font, action_card)
	_draw_tackle_card(font, tackle_card)


func _draw_header(font: Font, rect: Rect2) -> void:
	_draw_panel(rect, Palette.DARK_PANEL, Palette.GOLD, Palette.GOLD_BRIGHT)
	var title_size := 18
	var title_outline := 3 if _sidebar_frame == null else 1
	var count_outline := 2 if _sidebar_frame == null else 1
	var baseline_y := rect.size.y * (0.62 if _sidebar_frame != null else 0.68)
	var title_text := "釣り中の魚" if _fish_is_revealed() else "未確認の魚影"
	_draw_text(font, title_text, rect.position + Vector2(14.0, baseline_y), title_size, Palette.TEXT_BONE, title_outline)
	var count_text := "1/1 匹" if _fish_is_revealed() else "未確認"
	var count_size := 16
	var count_w := font.get_string_size(count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, count_size).x
	_draw_text(font, count_text, rect.position + Vector2(rect.size.x - count_w - 14.0, baseline_y), count_size, Palette.GOLD_BRIGHT, count_outline)


func _draw_fish_card(font: Font, rect: Rect2) -> void:
	_draw_panel(rect, Palette.PARCHMENT, Palette.WOOD_DARK, Palette.GOLD)
	if not _fish_is_revealed():
		_draw_unknown_fish_card(font, rect)
		return
	var compact_card := _sidebar_frame != null or rect.size.y <= 300.0
	var inner := rect.grow(-10.0 if _sidebar_frame == null else -12.0)
	var fish_name := String(fish_data.get("name", "クロダイ"))
	var rarity := String(fish_data.get("rarity", "レア"))
	var no_text := String(fish_data.get("fish_no", "No.---"))
	var preferred_bait := String(fish_data.get("preferred_bait", "オキアミ"))
	if compact_card:
		var title_plaque := Rect2(inner.position + Vector2(7.0, 8.0), Vector2(inner.size.x - 14.0, 28.0))
		var rarity_rect := Rect2(inner.position + Vector2(inner.size.x - 58.0, 11.0), Vector2(48.0, 20.0))
		var name_rect := Rect2(title_plaque.position + Vector2(62.0, 0.0), Vector2(rarity_rect.position.x - title_plaque.position.x - 72.0, title_plaque.size.y))
		draw_line(Vector2(title_plaque.position.x + 8.0, title_plaque.end.y + 3.0), Vector2(title_plaque.end.x - 8.0, title_plaque.end.y + 3.0), Color("#c9b486", 0.62), 1.0)
		_draw_text(font, no_text, inner.position + Vector2(17.0, 27.0), 14, Color("#665d50"), 0)
		_draw_centered_baseline_text(font, _display_fish_name(fish_name), name_rect, inner.position.y + 28.0, 20, Palette.TEXT_DARK, 0)
		_draw_rarity_tag(font, rarity_rect, rarity)
	else:
		_draw_text(font, no_text, inner.position + Vector2(0.0, 26.0), 14, Color("#6b6153"), 0)
		_draw_text(font, _display_fish_name(fish_name), inner.position + Vector2(74.0, 28.0), 20, Palette.TEXT_DARK, 0)
		_draw_rarity_tag(font, Rect2(inner.position + Vector2(inner.size.x - 52.0, 8.0), Vector2(48.0, 22.0)), rarity)

	var fish_rect := Rect2(
		inner.position + Vector2(6.0, 44.0 if compact_card else 46.0),
		Vector2(
			inner.size.x - 12.0,
			maxf(82.0, rect.size.y * (0.425 if compact_card else 0.37))
		)
	)
	_draw_fish_portrait(fish_rect)
	var divider_y := fish_rect.end.y + (3.0 if _sidebar_frame != null else 6.0)
	draw_line(Vector2(inner.position.x + 8.0, divider_y), Vector2(inner.end.x - 8.0, divider_y), Color("#c9b486"), 1.0)
	var estimate := (float(fish_data.get("size_min", 0.0)) + float(fish_data.get("size_max", 0.0))) * 0.5
	if compact_card:
		_draw_estimate_line(font, estimate, Rect2(inner.position.x, divider_y + 7.0, inner.size.x, 32.0))
	else:
		_draw_centered_text(font, "推定 %.1f cm" % estimate, Rect2(inner.position.x, divider_y + 8.0, inner.size.x, 30.0), 23, Color("#2b2117"), 0)
	var desc_y := divider_y + (52.0 if compact_card else 44.0)
	draw_line(Vector2(inner.position.x + 8.0, desc_y - 12.0), Vector2(inner.end.x - 8.0, desc_y - 12.0), Color("#d6c299"), 1.0)
	var detail_gap := 16.0 if compact_card else 21.0
	var detail_font := FightFontsScript.regular(get_theme_default_font())
	var behavior := String(fish_data.get("behavior", "ラインを見ながら、テンションを保とう。"))
	var habitat := String(fish_data.get("habitat", "沿岸"))
	if compact_card:
		_draw_info_paragraph(detail_font, behavior, Vector2(inner.position.x + 15.0, desc_y), inner.size.x - 26.0)
		_draw_detail_line(detail_font, "好むエサ：%s" % preferred_bait, Vector2(inner.position.x + 15.0, desc_y + 35.0), inner.size.x - 26.0)
		_draw_detail_line(detail_font, "主な生息域：%s" % habitat, Vector2(inner.position.x + 15.0, desc_y + 52.0), inner.size.x - 26.0)
	else:
		_draw_detail_line(detail_font, behavior, Vector2(inner.position.x + 15.0, desc_y), inner.size.x - 26.0)
		_draw_detail_line(detail_font, "エサ：%s" % preferred_bait, Vector2(inner.position.x + 15.0, desc_y + detail_gap), inner.size.x - 26.0)
		_draw_detail_line(detail_font, "生息域：%s" % habitat, Vector2(inner.position.x + 16.0, desc_y + detail_gap * 2.0), inner.size.x - 28.0)


func _draw_unknown_fish_card(font: Font, rect: Rect2) -> void:
	var compact_card := _sidebar_frame != null or rect.size.y <= 300.0
	var inner := rect.grow(-10.0 if _sidebar_frame == null else -12.0)
	var regular_font := FightFontsScript.regular(get_theme_default_font())
	var title_plaque := Rect2(inner.position + Vector2(7.0, 8.0), Vector2(inner.size.x - 14.0, 28.0))
	var state_rect := Rect2(inner.position + Vector2(inner.size.x - 74.0, 11.0), Vector2(64.0, 20.0))
	var title_rect := Rect2(title_plaque.position + Vector2(62.0, 0.0), Vector2(state_rect.position.x - title_plaque.position.x - 72.0, title_plaque.size.y))
	draw_line(Vector2(title_plaque.position.x + 8.0, title_plaque.end.y + 3.0), Vector2(title_plaque.end.x - 8.0, title_plaque.end.y + 3.0), Color("#c9b486", 0.62), 1.0)
	_draw_text(font, "魚影", inner.position + Vector2(17.0, 27.0), 14, Color("#665d50"), 0)
	_draw_centered_baseline_text(font, "未確認の魚影", title_rect, inner.position.y + 28.0, 19, Palette.TEXT_DARK, 0)
	_draw_unknown_state_tag(font, state_rect, _unknown_short_status())

	var signal_rect := Rect2(
		inner.position + Vector2(6.0, 44.0 if compact_card else 46.0),
		Vector2(
			inner.size.x - 12.0,
			maxf(82.0, rect.size.y * (0.425 if compact_card else 0.37))
		)
	)
	_draw_unknown_signal_art(font, signal_rect)
	var divider_y := signal_rect.end.y + (3.0 if _sidebar_frame != null else 6.0)
	draw_line(Vector2(inner.position.x + 8.0, divider_y), Vector2(inner.end.x - 8.0, divider_y), Color("#c9b486"), 1.0)
	_draw_unknown_reaction_line(font, Rect2(inner.position.x, divider_y + 7.0, inner.size.x, 32.0))
	var desc_y := divider_y + (37.0 if compact_card else 36.0)
	draw_line(Vector2(inner.position.x + 8.0, desc_y - 12.0), Vector2(inner.end.x - 8.0, desc_y - 12.0), Color("#d6c299"), 1.0)
	_draw_wrapped(regular_font, _unknown_description(), Vector2(inner.position.x + 15.0, desc_y), inner.size.x - 26.0, 13, Color("#1b1109"), 1, 15.0)
	_draw_detail_line(regular_font, "狙い：%s" % _target_mode_text(), Vector2(inner.position.x + 15.0, desc_y + 22.0), inner.size.x - 26.0)
	_draw_detail_line(regular_font, "タナ：%s / エサ：オキアミ" % _current_depth_text(), Vector2(inner.position.x + 15.0, desc_y + 38.0), inner.size.x - 26.0)


func _draw_unknown_signal_art(font: Font, rect: Rect2) -> void:
	var paper_glow := Rect2(rect.position + Vector2(4.0, 5.0), rect.size - Vector2(8.0, 10.0))
	draw_rect(paper_glow, Color("#e6d5ad", 0.18), true)
	draw_rect(paper_glow, Color("#a97a37", 0.14), false, 1.0)
	for index in range(5):
		var y := paper_glow.position.y + paper_glow.size.y * (0.16 + float(index) * 0.17)
		draw_line(
			Vector2(paper_glow.position.x + 12.0, y),
			Vector2(paper_glow.end.x - 12.0, y + sin(float(index) * 1.6) * 2.0),
			Color("#8b744b", 0.10),
			1.0
		)
	var center := paper_glow.position + paper_glow.size * Vector2(0.50, 0.48)
	var pulse := 0.0
	if simulator != null:
		pulse = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 360.0)
	for index in range(4):
		var radius := (22.0 + float(index) * 18.0) * (0.94 + pulse * 0.06)
		var alpha := 0.20 - float(index) * 0.035
		draw_arc(center, radius, 0.0, TAU, 48, Color("#207f9a", alpha), 1.3)
	draw_line(center + Vector2(-78.0, 0.0), center + Vector2(78.0, 0.0), Color("#1b6b83", 0.20), 1.0)
	draw_line(center + Vector2(0.0, -46.0), center + Vector2(0.0, 46.0), Color("#1b6b83", 0.16), 1.0)
	var shadow_center := center + Vector2(sin(Time.get_ticks_msec() / 420.0) * 4.0, 5.0)
	_draw_ellipse(shadow_center, rect.size.x * 0.18, rect.size.y * 0.11, Color("#122f3a", 0.28), 36)
	var tail := PackedVector2Array([
		shadow_center + Vector2(-rect.size.x * 0.13, 0.0),
		shadow_center + Vector2(-rect.size.x * 0.22, -rect.size.y * 0.09),
		shadow_center + Vector2(-rect.size.x * 0.22, rect.size.y * 0.09),
	])
	draw_colored_polygon(tail, Color("#102a33", 0.24))
	var lure := center + Vector2(rect.size.x * 0.20, -rect.size.y * 0.11)
	draw_line(lure + Vector2(0.0, -40.0), lure, Color("#4d6c72", 0.35), 1.1)
	draw_circle(lure, 5.0, Color("#c0783e", 0.82))
	draw_circle(lure + Vector2(2.0, -1.5), 1.8, Color("#ffe0a2", 0.82))
	var status := _unknown_reaction_label()
	var status_size := 17
	var status_width := font.get_string_size(status, HORIZONTAL_ALIGNMENT_LEFT, -1, status_size).x
	_draw_text(font, status, Vector2(center.x - status_width * 0.5, paper_glow.end.y - 10.0), status_size, Color("#31404a"), 0)


func _draw_unknown_reaction_line(font: Font, rect: Rect2) -> void:
	var regular_font := FightFontsScript.regular(get_theme_default_font())
	var label := "反応"
	var value := _unknown_reaction_label()
	var label_size := 16
	var value_size := 24
	var gap := 8.0
	var label_w := regular_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size).x
	var value_w := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, value_size).x
	var total_w := label_w + gap + value_w
	var x := rect.position.x + (rect.size.x - total_w) * 0.5
	var baseline := rect.position.y + 24.0
	_draw_text(regular_font, label, Vector2(x, baseline - 1.0), label_size, Color("#3f2f22"), 0)
	x += label_w + gap
	_draw_text(font, value, Vector2(x, baseline), value_size, _unknown_reaction_color(), 0)


func _draw_unknown_state_tag(font: Font, rect: Rect2, text: String) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#3f6f78")
	style.border_color = Color("#a6d6d9")
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.shadow_color = Color(0.06, 0.12, 0.14, 0.25)
	style.shadow_size = 1
	draw_style_box(style, rect)
	draw_line(rect.position + Vector2(4.0, 3.0), Vector2(rect.end.x - 4.0, rect.position.y + 3.0), Color(1.0, 1.0, 1.0, 0.30), 1.0)
	var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	_draw_text(font, text, rect.position + Vector2((rect.size.x - text_width) * 0.5, 16.0), 12, Color.WHITE, 1)



func _draw_action_card(font: Font, rect: Rect2) -> void:
	_draw_panel(rect, Color("#0d3a62"), Palette.GOLD, Palette.GOLD_BRIGHT)
	var title_x := 16.0
	if _sidebar_frame != null:
		_draw_action_header_icon(Rect2(rect.position + Vector2(14.0, 6.0), Vector2(22.0, 22.0)))
		title_x = 40.0
	var title := "魚の行動" if _fish_is_revealed() else "今の状況"
	_draw_text(font, title, rect.position + Vector2(title_x, 25.0), 18, Palette.TEXT_BONE, 1 if _sidebar_frame != null else 3)
	var body := Rect2(rect.position + Vector2(10.0, 33.0), rect.size - Vector2(20.0, 42.0))
	if _sidebar_frame != null:
		body = Rect2(rect.position + Vector2(8.5, rect.size.y * 0.170), rect.size - Vector2(17.0, rect.size.y * 0.205))
	else:
		_draw_panel(body, Color("#f3e8cd"), Palette.WOOD_DARK, Palette.GOLD)
	var action := "待機"
	var message := "ラインを見ながら、テンションを保とう。"
	if simulator != null:
		if _fish_is_revealed():
			action = simulator.action_name
			message = simulator.action_message
		else:
			action = _unknown_action_title()
			message = _unknown_action_message()
	var icon_size := 42.0 if _sidebar_frame != null else 58.0
	var text_x := 62.0 if _sidebar_frame != null else 78.0
	if _sidebar_frame != null:
		icon_size = 78.0
		text_x = 90.0
	_draw_action_icon(body.position + Vector2(42.0, body.size.y * 0.57), icon_size)
	_draw_text(font, "%s！" % action, body.position + Vector2(text_x, 31.0), 21 if _sidebar_frame != null else 20, Color("#22180f"), 0)
	if _sidebar_frame != null:
		_draw_action_message(font, message, body.position + Vector2(text_x, 49.0), body.size.x - text_x - 4.0)
	else:
		_draw_wrapped(font, message, body.position + Vector2(72.0, 36.0), body.size.x - 82.0, 11, Palette.TEXT_DARK, 2)


func _draw_tackle_card(font: Font, rect: Rect2) -> void:
	_draw_panel(rect, Color("#0d3a62"), Palette.GOLD, Palette.GOLD_BRIGHT)
	_draw_text(font, "タックル", rect.position + Vector2(14.0, 24.0), 18, Palette.TEXT_BONE, 1 if _sidebar_frame != null else 3)
	var body := Rect2(rect.position + Vector2(10.0, 32.0), rect.size - Vector2(20.0, 38.0))
	if _sidebar_frame != null:
		body = Rect2(rect.position + Vector2(8.5, rect.size.y * 0.167), rect.size - Vector2(17.0, rect.size.y * 0.209))
	else:
		_draw_panel(body, Palette.PARCHMENT, Palette.WOOD_DARK, Palette.GOLD)
	var rod_name := _short_rod_name(String(trip_stats.get("rod_name", "港の入門竿")))
	var has_tackle_icon := _tackle_card_icon != null or _icons != null
	var icon_reserved_width := 12.0
	if has_tackle_icon:
		icon_reserved_width = 104.0 if _sidebar_frame != null else 66.0
	var text_offset := Vector2(14.0, 12.0) if _sidebar_frame != null else Vector2(12.0, 14.0)
	var text_width := body.size.x - icon_reserved_width - text_offset.x
	var lines: Array[String] = []
	if _sidebar_frame != null:
		lines = [
			"ロッド：%s" % rod_name,
			"リール：スピニング4000番",
			"ライン：ナイロン3号",
			"ハリス：フロロ2号",
			"針：チヌ針",
		]
	else:
		lines = [
			"ロッド：%s" % rod_name,
			"糸3号・チヌ針",
		]
	var tackle_font_size := 13 if _sidebar_frame != null else 12
	var tackle_line_gap := 13.6 if _sidebar_frame != null else 16.0
	var tackle_font := FightFontsScript.regular(get_theme_default_font()) if _sidebar_frame != null else font
	var tackle_text_color := Color("#1d1209") if _sidebar_frame != null else Palette.TEXT_DARK
	for i in range(lines.size()):
		var line_font := FightFontsScript.bold(tackle_font) if _sidebar_frame != null and i == 0 else tackle_font
		var line_color := Color("#160d07") if _sidebar_frame != null and i == 0 else tackle_text_color
		_draw_wrapped(line_font, lines[i], body.position + text_offset + Vector2(0.0, float(i) * tackle_line_gap), text_width, tackle_font_size, line_color, 1, tackle_font_size + 2.0)
	if _tackle_card_icon != null or _icons != null:
		var icon_rect := Rect2(body.end - Vector2(122.0, 90.0), Vector2(118.0, 86.0)) if _sidebar_frame != null else Rect2(body.end - Vector2(50.0, 50.0), Vector2(40.0, 40.0))
		_draw_tackle_icon(icon_rect)
	else:
		_draw_simple_rod(body.position + Vector2(body.size.x - 62.0, body.size.y - 24.0))


func _draw_panel(rect: Rect2, fill: Color, border: Color, highlight: Color) -> void:
	if _sidebar_frame != null:
		return
	draw_rect(rect, Color(0.0, 0.0, 0.0, 0.28), true)
	draw_rect(rect.grow(-3.0), fill, true)
	draw_rect(rect.grow(-3.0), border, false, 2.0)
	draw_rect(rect.grow(-6.0), Color(highlight.r, highlight.g, highlight.b, 0.55), false, 1.0)
	for corner in [
		rect.position + Vector2(8.0, 8.0),
		rect.position + Vector2(rect.size.x - 9.0, 8.0),
		rect.position + Vector2(8.0, rect.size.y - 9.0),
		rect.position + Vector2(rect.size.x - 9.0, rect.size.y - 9.0),
	]:
		draw_rect(Rect2(corner - Vector2(2.0, 2.0), Vector2(4.0, 4.0)), Palette.GOLD_BRIGHT, true)


func _draw_text(font: Font, text: String, baseline: Vector2, font_size: int, color: Color, outline: int) -> void:
	if outline > 0:
		draw_string_outline(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline, Color(0.0, 0.0, 0.0, 0.65))
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw_centered_text(font: Font, text: String, rect: Rect2, font_size: int, color: Color, outline: int) -> void:
	var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_draw_text(font, text, rect.position + Vector2((rect.size.x - text_width) * 0.5, font_size), font_size, color, outline)


func _draw_centered_baseline_text(font: Font, text: String, rect: Rect2, baseline_y: float, font_size: int, color: Color, outline: int) -> void:
	var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_draw_text(font, text, Vector2(rect.position.x + (rect.size.x - text_width) * 0.5, baseline_y), font_size, color, outline)


func _draw_estimate_line(font: Font, value: float, rect: Rect2) -> void:
	var regular_font := FightFontsScript.regular(get_theme_default_font())
	var label := "推定"
	var number := "%.1f" % value
	var unit := " cm"
	var label_size := 16
	var number_size := 26
	var unit_size := 16
	var gap := 6.5
	var label_w := regular_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, label_size).x
	var number_w := font.get_string_size(number, HORIZONTAL_ALIGNMENT_LEFT, -1, number_size).x
	var unit_w := regular_font.get_string_size(unit, HORIZONTAL_ALIGNMENT_LEFT, -1, unit_size).x
	var total_w := label_w + gap + number_w + unit_w
	var x := rect.position.x + (rect.size.x - total_w) * 0.5
	var baseline := rect.position.y + 25.0
	_draw_text(regular_font, label, Vector2(x, baseline - 1.0), label_size, Color("#3f2f22"), 0)
	x += label_w + gap
	_draw_text(font, number, Vector2(x, baseline), number_size, Color("#21170f"), 0)
	x += number_w
	_draw_text(regular_font, unit, Vector2(x, baseline - 1.0), unit_size, Color("#3f2f22"), 0)


func _draw_wrapped(
	font: Font,
	text: String,
	pos: Vector2,
	max_width: float,
	font_size: int,
	color: Color,
	max_lines: int,
	line_gap: float = -1.0
) -> void:
	var line := ""
	var lines: Array[String] = []
	var closing_marks := "、。！？…）」』"
	for i in range(text.length()):
		var char := text[i]
		var next := line + char
		if font.get_string_size(next, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > max_width and not line.is_empty():
			if closing_marks.contains(char):
				lines.append(next)
				line = ""
			else:
				lines.append(line)
				line = char
		else:
			line = next
	if not line.is_empty():
		lines.append(line)
	var count := mini(lines.size(), max_lines)
	var gap := line_gap if line_gap > 0.0 else float(font_size + 5)
	for i in range(count):
		_draw_text(font, lines[i], pos + Vector2(0.0, float(i) * gap + float(font_size)), font_size, color, 0)


func _draw_action_message(font: Font, text: String, pos: Vector2, max_width: float) -> void:
	var first_stop := text.find("！")
	var font_size := 15 if _sidebar_frame != null else 13
	var gap := 16.0 if _sidebar_frame != null else 16.0
	if first_stop > 0 and first_stop < text.length() - 1:
		var first := text.left(first_stop + 1).strip_edges().replace("潜ろうとしている", "潜る")
		var second := text.substr(first_stop + 1).strip_edges()
		_draw_wrapped(font, first, pos, max_width, font_size, Palette.TEXT_DARK, 1, gap)
		_draw_wrapped(font, second, pos + Vector2(0.0, gap), max_width, font_size, Palette.TEXT_DARK, 1, gap)
		return
	_draw_wrapped(font, text, pos, max_width, font_size, Palette.TEXT_DARK, 2, gap)


func _draw_bullet(font: Font, text: String, pos: Vector2, max_width: float) -> void:
	draw_circle(pos + Vector2(2.0, -3.0), 4.0, Color("#49c75a"))
	_draw_wrapped(font, text, pos + Vector2(14.0, -15.0), max_width - 14.0, 13, Palette.TEXT_DARK, 1)


func _draw_info_paragraph(font: Font, text: String, pos: Vector2, max_width: float) -> void:
	var font_size := 14
	var gap := 16.0 if _sidebar_frame != null else float(font_size + 3)
	_draw_wrapped(font, text, pos, max_width, font_size, Color("#1b1109"), 2, gap)


func _draw_detail_line(font: Font, text: String, pos: Vector2, max_width: float) -> void:
	draw_circle(pos + Vector2(3.0, 10.0), 4.4 if _sidebar_frame != null else 4.3, Color("#3fbd50"))
	var font_size := 14
	if _sidebar_frame != null:
		font_size = 14
	elif max_width < 260.0:
		font_size = 13
	_draw_wrapped(font, text, pos + Vector2(15.0, -1.0), max_width - 15.0, font_size, Color("#1b1109"), 1)


func _fish_is_revealed() -> bool:
	return simulator != null and bool(simulator.fish_revealed)


func _unknown_short_status() -> String:
	if simulator == null:
		return "未確認"
	match simulator.state:
		FishingSimulator.State.READY:
			return "準備中"
		FishingSimulator.State.CASTING:
			return "投入"
		FishingSimulator.State.WAITING:
			return "探索中"
		FishingSimulator.State.APPROACH:
			return "魚影"
		FishingSimulator.State.BITE:
			return "アタリ"
		FishingSimulator.State.ESCAPED:
			return "消失"
		_:
			return "未確認"


func _unknown_reaction_label() -> String:
	if simulator == null:
		return "反応待ち"
	match simulator.state:
		FishingSimulator.State.READY:
			return "準備中"
		FishingSimulator.State.CASTING:
			return "仕掛け投入"
		FishingSimulator.State.WAITING:
			return "気配を探知中"
		FishingSimulator.State.APPROACH:
			return "魚影あり"
		FishingSimulator.State.BITE:
			return "強いアタリ"
		FishingSimulator.State.ESCAPED:
			return "反応消失"
		_:
			return "反応待ち"


func _unknown_reaction_color() -> Color:
	if simulator == null:
		return Color("#31525e")
	match simulator.state:
		FishingSimulator.State.BITE:
			return Color("#b45122")
		FishingSimulator.State.APPROACH:
			return Color("#1f7a6f")
		FishingSimulator.State.ESCAPED:
			return Color("#68727a")
		_:
			return Color("#31525e")


func _unknown_description() -> String:
	if simulator == null:
		return "仕掛けへの反応を見ながら、魚影が見える瞬間を待とう。"
	match simulator.state:
		FishingSimulator.State.READY:
			return "狙いを決めて仕掛けを投げると、水中の反応を探り始める。"
		FishingSimulator.State.CASTING:
			return "仕掛けがタナへ沈んでいる。魚影はまだ確認できない。"
		FishingSimulator.State.WAITING:
			return "水面と糸の変化を見ながら、魚の気配を探っている。"
		FishingSimulator.State.APPROACH:
			return "エサの近くに魚影がある。正体はまだ水中で確認できない。"
		FishingSimulator.State.BITE:
			return "何かが食いついた。アワセるまで魚の正体は分からない。"
		FishingSimulator.State.ESCAPED:
			return "魚影を確認する前に反応が消えた。次のアタリを待とう。"
		_:
			return "仕掛けへの反応を見ながら、魚影が見える瞬間を待とう。"


func _unknown_action_title() -> String:
	if simulator == null:
		return "反応待ち"
	match simulator.state:
		FishingSimulator.State.READY:
			return "準備"
		FishingSimulator.State.CASTING:
			return "投入"
		FishingSimulator.State.WAITING:
			return "探索"
		FishingSimulator.State.APPROACH:
			return "接近"
		FishingSimulator.State.BITE:
			return "アタリ"
		FishingSimulator.State.ESCAPED:
			return "消失"
		_:
			return "反応待ち"


func _unknown_action_message() -> String:
	if simulator == null:
		return "水面と糸の変化から反応を読もう。"
	match simulator.state:
		FishingSimulator.State.READY:
			return "狙いを決めて仕掛けを投げよう。"
		FishingSimulator.State.CASTING:
			return "仕掛けを投入した。タナまで沈めよう。"
		FishingSimulator.State.WAITING:
			return "水中の反応を探っている。"
		FishingSimulator.State.APPROACH:
			return "魚影がエサへ近づいている。"
		FishingSimulator.State.BITE:
			return "食いついた！すぐにアワセよう。"
		FishingSimulator.State.ESCAPED:
			return "反応が消えた。正体は分からないままだ。"
		_:
			return "水面と糸の変化から反応を読もう。"


func _target_mode_text() -> String:
	if bool(fish_data.get("boss", false)):
		return "港のぬし狙い"
	return "通常魚狙い"


func _current_depth_text() -> String:
	if simulator == null:
		return "--.-m"
	return "%.1fm" % simulator.depth


func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color, points := 28) -> void:
	var arr := PackedVector2Array()
	arr.resize(points)
	for index in range(points):
		var angle := TAU * float(index) / float(points)
		arr[index] = center + Vector2(cos(angle) * rx, sin(angle) * ry)
	draw_colored_polygon(arr, color)


func _draw_rarity_tag(font: Font, rect: Rect2, rarity: String) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#96517e")
	style.border_color = Color("#ddb3ce")
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.shadow_color = Color(0.18, 0.07, 0.12, 0.28)
	style.shadow_size = 1
	draw_style_box(style, rect)
	draw_line(rect.position + Vector2(4.0, 3.0), Vector2(rect.end.x - 4.0, rect.position.y + 3.0), Color(1.0, 0.88, 0.96, 0.35), 1.0)
	draw_line(rect.position + Vector2(4.0, rect.size.y - 3.0), Vector2(rect.end.x - 4.0, rect.end.y - 3.0), Color(0.32, 0.12, 0.22, 0.45), 1.0)
	var text_width := font.get_string_size(rarity, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	_draw_text(font, rarity, rect.position + Vector2((rect.size.x - text_width) * 0.5, 17.0), 13, Color.WHITE, 1)


func _draw_fish_portrait(rect: Rect2) -> void:
	if _fish_card_portrait != null:
		var tex_size := _fish_card_portrait.get_size()
		var scale := minf(rect.size.x / tex_size.x, rect.size.y / tex_size.y)
		if _sidebar_frame != null:
			scale *= 0.88
		var draw_size := tex_size * scale
		var draw_rect := Rect2(rect.position + (rect.size - draw_size) * 0.5, draw_size)
		if _sidebar_frame != null:
			draw_rect.position += Vector2(-9.0, -15.0)
		draw_texture_rect(_fish_card_portrait, draw_rect, false, Color.WHITE)
		return
	if _fish_sheet == null:
		var color := Color.from_string(String(fish_data.get("color", "#394956")), Color("#394956"))
		draw_texture_rect(UITextures.get_fish_icon(color), rect, false)
		return
	var frame_w := float(_fish_sheet.get_width()) / float(FISH_FRAME_COUNT)
	var frame_h := float(_fish_sheet.get_height())
	var src := Rect2(36.0, 45.0, frame_w - 73.0, frame_h - 50.0)
	var tex_size := src.size
	var scale := minf(rect.size.x / tex_size.x, rect.size.y / tex_size.y)
	var draw_size := tex_size * scale
	var draw_rect := Rect2(rect.position + (rect.size - draw_size) * 0.5, draw_size)
	draw_texture_rect_region(_fish_sheet, draw_rect, src, Color.WHITE)


func _draw_action_icon(center: Vector2, size_value: float = 58.0) -> void:
	if _action_card_icon != null:
		_draw_texture_centered(_action_card_icon, center, Vector2(size_value, size_value))
		return
	if _icons != null:
		_draw_sheet_icon(ICON_ACTION, Rect2(center - Vector2(size_value, size_value) * 0.5, Vector2(size_value, size_value)))
		return
	draw_arc(center, 26.0, -2.7, -0.5, 16, Color("#22354a"), 2.0)
	draw_polygon(
		PackedVector2Array([
			center + Vector2(-7.0, 0.0),
			center + Vector2(14.0, -8.0),
			center + Vector2(22.0, 0.0),
			center + Vector2(14.0, 8.0),
		]),
		PackedColorArray([Color("#174f7a")])
	)
	draw_polygon(
		PackedVector2Array([
			center + Vector2(-7.0, 0.0),
			center + Vector2(-19.0, -9.0),
			center + Vector2(-19.0, 9.0),
		]),
		PackedColorArray([Color("#0d3a62")])
	)
	for i in range(3):
		var splash := center + Vector2(-18.0 + float(i) * 12.0, 30.0 + float(i % 2) * 4.0)
		draw_line(splash + Vector2(-6.0, 0.0), splash + Vector2(6.0, 0.0), Color("#35aee0"), 2.0)


func _draw_action_header_icon(rect: Rect2) -> void:
	if _action_card_icon != null:
		_draw_texture_centered(_action_card_icon, rect.position + rect.size * 0.5, rect.size)
		return
	if _icons != null:
		_draw_sheet_icon(ICON_ACTION, rect)


func _draw_simple_rod(base: Vector2) -> void:
	draw_line(base + Vector2(-46.0, 22.0), base + Vector2(4.0, -42.0), Color("#2b2117"), 4.0)
	draw_line(base + Vector2(-43.0, 20.0), base + Vector2(1.0, -39.0), Palette.GOLD_BRIGHT, 1.0)
	draw_circle(base + Vector2(-18.0, 8.0), 9.0, Color("#22354a"))
	draw_circle(base + Vector2(-18.0, 8.0), 5.0, Palette.GOLD)


func _draw_tackle_icon(rect: Rect2) -> void:
	if _tackle_card_icon != null:
		_draw_texture_centered(_tackle_card_icon, rect.position + rect.size * 0.5, rect.size)
		return
	if _icons == null:
		return
	_draw_sheet_icon(ICON_TACKLE, rect)


func _draw_texture_centered(texture: Texture2D, center: Vector2, max_size: Vector2) -> void:
	var tex_size := texture.get_size()
	var scale := minf(max_size.x / tex_size.x, max_size.y / tex_size.y)
	var draw_size := tex_size * scale
	var rect := Rect2(center - draw_size * 0.5, draw_size)
	draw_texture_rect(texture, rect, false, Color.WHITE)


func _draw_texture_region_centered(texture: Texture2D, src: Rect2, center: Vector2, max_size: Vector2) -> void:
	var scale := minf(max_size.x / src.size.x, max_size.y / src.size.y)
	var draw_size := src.size * scale
	var rect := Rect2(center - draw_size * 0.5, draw_size)
	draw_texture_rect_region(texture, rect, src, Color.WHITE)


func _display_fish_name(name: String) -> String:
	if name.find("クロダイ") >= 0:
		return "クロダイ"
	return name


func _short_rod_name(name: String) -> String:
	if name.length() > 7:
		return name.left(7)
	return name


func _draw_sheet_icon(icon_index: int, target: Rect2) -> void:
	if _icons == null:
		return
	var cell_w := float(_icons.get_width()) / 3.0
	var cell_h := float(_icons.get_height()) / 3.0
	var col := icon_index % 3
	var row := icon_index / 3
	var src := Rect2(float(col) * cell_w, float(row) * cell_h, cell_w, cell_h)
	draw_texture_rect_region(_icons, target, src, Color.WHITE)
