extends "res://src/ui/screen_base.gd"
## 調理フローの STATUS_SUMMARY。
# `reference/cooking_flow/05_status_summary_concept.png` を基準にした全画面サマリー。
signal closed

const GaugeBarScript = preload("res://src/ui/components/gauge_bar.gd")

const COOKING_BG := "res://assets/showcase/cooking/cooking_room_bg.png"
const STATUS_CARD_FRAME := "res://assets/showcase/cooking/status_card_frame.png"
const DISH_FEATURE_AJI := "res://assets/showcase/cooking/dish_feature_aji_shioyaki.png"
const DISH_ICON_SHEET := "res://assets/showcase/cooking/dish_icon_sheet.png"


class StatusBackdropVisual:
	extends Control

	func _draw() -> void:
		var sky := Color("#8bd3f7")
		var sea := Color("#126998")
		var wood := Color("#4a2c18")
		var wall := Color("#6a4a2b")
		draw_rect(Rect2(0.0, 78.0, size.x * 0.46, 180.0), sky)
		draw_rect(Rect2(0.0, 174.0, size.x * 0.46, 84.0), sea)
		for i in range(5):
			var x := 34.0 + float(i) * 104.0
			draw_rect(Rect2(x, 150.0 - float(i % 2) * 22.0, 24.0, 78.0), Color("#75533a"))
			draw_rect(Rect2(x - 24.0, 222.0, 86.0, 13.0), Color("#3b2618"))
		for i in range(7):
			var p := Vector2(78.0 + float(i) * 74.0, 112.0 + float(i % 3) * 11.0)
			draw_arc(p, 13.0, 0.15, PI - 0.15, 10, Color(1.0, 1.0, 1.0, 0.54), 2.0)
		draw_rect(Rect2(size.x * 0.46, 78.0, size.x * 0.54, 180.0), Color("#332015"))
		for i in range(7):
			var x := size.x * 0.49 + float(i) * 78.0
			draw_rect(Rect2(x, 100.0 + float(i % 2) * 16.0, 48.0, 80.0), wall)
			draw_rect(Rect2(x - 8.0, 94.0 + float(i % 2) * 16.0, 64.0, 10.0), wood)
		for i in range(4):
			var x := size.x * 0.63 + float(i) * 92.0
			draw_line(Vector2(x, 88.0), Vector2(x, 154.0), Color("#18110c"), 4.0)
			draw_arc(Vector2(x, 167.0), 22.0, 0.0, PI, 20, Color("#19110c"), 5.0)
		var lamp := Vector2(size.x - 116.0, 148.0)
		draw_line(lamp + Vector2(0.0, -76.0), lamp + Vector2(0.0, -20.0), Color("#20140b"), 4.0)
		draw_circle(lamp, 31.0, Color(1.0, 0.72, 0.25, 0.34))
		draw_circle(lamp, 17.0, Color(1.0, 0.82, 0.38, 0.62))
		draw_rect(Rect2(0.0, 258.0, size.x, size.y - 258.0), Color(0.03, 0.10, 0.18, 0.42))


class StatusIconVisual:
	extends Control

	var mode := "player"
	var accent := Color.WHITE

	func configure(next_mode: String, next_accent: Color) -> void:
		mode = next_mode.to_lower()
		accent = next_accent
		queue_redraw()

	func _draw() -> void:
		match mode:
			"cooler":
				_draw_cooler()
			"gold":
				_draw_gold()
			"time":
				_draw_clock()
			"ready":
				_draw_ready()
			_:
				_draw_player()

	func _draw_player() -> void:
		var center := size * 0.5
		draw_ellipse(center + Vector2(0.0, 45.0), 48.0, 10.0, Color(0.0, 0.0, 0.0, 0.25))
		draw_rect(Rect2(center.x - 45.0, center.y + 5.0, 90.0, 48.0), Color("#17324d"))
		draw_rect(Rect2(center.x - 45.0, center.y + 5.0, 90.0, 9.0), Color("#2c5f8c"))
		draw_circle(center + Vector2(0.0, -22.0), 34.0, Color("#f2b889"))
		draw_rect(Rect2(center.x - 37.0, center.y - 58.0, 74.0, 17.0), Color("#1d4771"))
		draw_rect(Rect2(center.x - 26.0, center.y - 72.0, 52.0, 15.0), Color("#234f7c"))
		draw_circle(center + Vector2(-13.0, -24.0), 3.0, Color("#1d160f"))
		draw_circle(center + Vector2(13.0, -24.0), 3.0, Color("#1d160f"))
		draw_arc(center + Vector2(0.0, -12.0), 13.0, 0.12, PI - 0.12, 14, Color("#6a2a1c"), 3.0)
		draw_line(center + Vector2(-28.0, -1.0), center + Vector2(-45.0, 36.0), Color("#234f7c"), 8.0)
		draw_line(center + Vector2(28.0, -1.0), center + Vector2(45.0, 36.0), Color("#234f7c"), 8.0)

	func _draw_ready() -> void:
		_draw_player()
		var rod_color := Color("#c9944d")
		var base := size * 0.5 + Vector2(42.0, 42.0)
		draw_line(base, base + Vector2(32.0, -92.0), rod_color, 3.0)
		draw_arc(base + Vector2(44.0, -92.0), 18.0, PI * 0.1, PI * 1.35, 16, Color("#fff1c7"), 2.0)

	func _draw_cooler() -> void:
		var center := size * 0.5
		draw_ellipse(center + Vector2(0.0, 52.0), 58.0, 10.0, Color(0.0, 0.0, 0.0, 0.25))
		draw_rect(Rect2(center.x - 58.0, center.y - 10.0, 116.0, 70.0), Color("#1b5d8d"))
		draw_rect(Rect2(center.x - 58.0, center.y - 10.0, 116.0, 17.0), Color("#eef4fa"))
		draw_rect(Rect2(center.x - 42.0, center.y - 30.0, 84.0, 22.0), Color("#d7e3ef"))
		draw_line(center + Vector2(-42.0, -19.0), center + Vector2(42.0, -19.0), Color("#6b8298"), 4.0)
		draw_rect(Rect2(center.x - 21.0, center.y + 12.0, 42.0, 19.0), Color("#f0f6fb"))
		draw_line(center + Vector2(-12.0, 47.0), center + Vector2(12.0, 47.0), Color("#083354"), 3.0)
		for i in range(4):
			draw_ellipse(center + Vector2(-34.0 + float(i) * 23.0, 2.0), 14.0, 5.0, Color("#b7c2c9"))

	func _draw_gold() -> void:
		var center := size * 0.5
		draw_ellipse(center + Vector2(0.0, 56.0), 62.0, 10.0, Color(0.0, 0.0, 0.0, 0.22))
		for i in range(10):
			var x := center.x - 46.0 + float((i * 23) % 92)
			var y := center.y + 32.0 - float(i / 3) * 16.0
			draw_circle(Vector2(x, y), 15.0, Color("#d9941f"))
			draw_circle(Vector2(x - 2.0, y - 3.0), 11.0, Color("#ffd86b"))
			draw_arc(Vector2(x, y), 12.0, 0.0, TAU, 18, Color("#8b5515"), 2.0)
		draw_rect(Rect2(center.x + 22.0, center.y - 12.0, 46.0, 58.0), Color("#7b4b20"))
		draw_rect(Rect2(center.x + 15.0, center.y - 18.0, 60.0, 13.0), Color("#b97a31"))

	func _draw_clock() -> void:
		var center := size * 0.5
		draw_ellipse(center + Vector2(0.0, 56.0), 52.0, 9.0, Color(0.0, 0.0, 0.0, 0.22))
		draw_circle(center + Vector2(0.0, 4.0), 54.0, Color("#c59035"))
		draw_circle(center + Vector2(0.0, 4.0), 46.0, Color("#fff1cf"))
		draw_arc(center + Vector2(0.0, 4.0), 47.0, 0.0, TAU, 42, Color("#5b3516"), 3.0)
		draw_line(center + Vector2(0.0, 4.0), center + Vector2(0.0, -27.0), Color("#2a2118"), 4.0)
		draw_line(center + Vector2(0.0, 4.0), center + Vector2(26.0, 20.0), Color("#2a2118"), 4.0)
		draw_circle(center + Vector2(0.0, 4.0), 5.0, Color("#2a2118"))
		draw_arc(center + Vector2(-33.0, -48.0), 16.0, PI * 0.2, PI * 1.35, 14, Color("#c59035"), 5.0)
		draw_arc(center + Vector2(33.0, -48.0), 16.0, PI * -0.35, PI * 0.8, 14, Color("#c59035"), 5.0)


class HeaderMarkVisual:
	extends Control

	var mode := "wheel"

	func configure(next_mode: String) -> void:
		mode = next_mode
		queue_redraw()

	func _draw() -> void:
		if mode == "anchor":
			_draw_anchor()
		else:
			_draw_wheel()

	func _draw_wheel() -> void:
		var center := size * 0.5
		var gold := Palette.GOLD_BRIGHT
		draw_circle(center, 25.0, Color("#4c2b0b"))
		draw_circle(center, 20.0, Color("#10283f"))
		draw_arc(center, 24.0, 0.0, TAU, 36, gold, 3.0)
		draw_arc(center, 10.0, 0.0, TAU, 24, gold, 3.0)
		for i in range(8):
			var a := TAU * float(i) / 8.0
			var inner := center + Vector2(cos(a), sin(a)) * 9.0
			var outer := center + Vector2(cos(a), sin(a)) * 33.0
			draw_line(inner, outer, gold, 3.0)
			draw_circle(outer, 4.0, gold)

	func _draw_anchor() -> void:
		var center := size * 0.5
		var gold := Palette.GOLD_BRIGHT
		draw_arc(center + Vector2(0.0, -24.0), 9.0, 0.0, TAU, 22, gold, 3.0)
		draw_line(center + Vector2(0.0, -13.0), center + Vector2(0.0, 28.0), gold, 5.0)
		draw_line(center + Vector2(-20.0, -1.0), center + Vector2(20.0, -1.0), gold, 4.0)
		draw_arc(center + Vector2(0.0, 18.0), 28.0, 0.15, PI - 0.15, 28, gold, 4.0)
		draw_polygon(
			PackedVector2Array(
				[
					center + Vector2(-27.0, 17.0),
					center + Vector2(-40.0, 18.0),
					center + Vector2(-31.0, 30.0),
				]
			),
			PackedColorArray([gold, gold, gold])
		)
		draw_polygon(
			PackedVector2Array(
				[
					center + Vector2(27.0, 17.0),
					center + Vector2(40.0, 18.0),
					center + Vector2(31.0, 30.0),
				]
			),
			PackedColorArray([gold, gold, gold])
		)


var _exp_bar: GaugeBar
var _header_exp_bar: GaugeBar
var _header_level_label: Label
var _header_exp_label: Label
var _level_label: Label
var _next_exp_label: Label
var _stats_box: VBoxContainer
var _meal_badge: Label
var _meal_image: TextureRect
var _meal_name_label: Label
var _meal_effect_label: Label
var _meal_hint_label: Label
var _cooler_count_label: Label
var _money_label: Label
var _play_label: Label
var _footer_message_label: Label


func _build_screen() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_add_status_background()

	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 18)
	root.add_theme_constant_override("margin_top", 8)
	root.add_theme_constant_override("margin_right", 18)
	root.add_theme_constant_override("margin_bottom", 8)
	add_child(root)

	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 6)
	root.add_child(layout)

	_build_header(layout)
	_build_cards(layout)
	_build_footer(layout)


func _add_status_background() -> void:
	var bg_tex := load(COOKING_BG) as Texture2D
	if bg_tex != null:
		var bg := TextureRect.new()
		bg.texture = bg_tex
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
	else:
		add_gradient_background(Color("#17314c"), Color("#071322"))

	var scene := StatusBackdropVisual.new()
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scene)
	scene.queue_redraw()

	var wash := ColorRect.new()
	wash.color = Color(0.02, 0.06, 0.11, 0.34)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)


func _build_header(parent: VBoxContainer) -> void:
	var header := _panel_box(Color("#0a2744"), Color("#06111e"), Palette.GOLD_BRIGHT, 5)
	header.custom_minimum_size = Vector2(0.0, 72.0)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(header)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	header.add_child(row)

	var wheel := HeaderMarkVisual.new()
	wheel.configure("wheel")
	wheel.custom_minimum_size = Vector2(72.0, 0.0)
	row.add_child(wheel)

	var title := make_shadow_label("ステータス", 38, Palette.TEXT_BONE, 4)
	title.custom_minimum_size = Vector2(220.0, 0.0)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(title)

	var subtitle := make_shadow_label("調理の成果を確認できます", 18, Palette.TEXT_BONE, 2)
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(subtitle)

	var exp_box := _panel_box(Color("#10283f"), Color("#07121e"), Palette.GOLD_DEEP, 3)
	exp_box.custom_minimum_size = Vector2(376.0, 0.0)
	row.add_child(exp_box)
	var exp_row := HBoxContainer.new()
	exp_row.add_theme_constant_override("separation", 10)
	exp_box.add_child(exp_row)
	_header_level_label = make_shadow_label("", 22, Palette.TEXT_BONE, 3)
	_header_level_label.custom_minimum_size = Vector2(72.0, 0.0)
	_header_level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	exp_row.add_child(_header_level_label)
	var exp_title := make_shadow_label("EXP", 17, Palette.TEXT_BONE, 2)
	exp_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	exp_row.add_child(exp_title)
	_header_exp_bar = GaugeBarScript.new()
	_header_exp_bar.show_value = false
	_header_exp_bar.custom_minimum_size = Vector2(0.0, 20.0)
	_header_exp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header_exp_bar.set_colors(Palette.GAUGE_CYAN, Palette.GAUGE_CYAN_HI)
	exp_row.add_child(_header_exp_bar)
	_header_exp_label = make_shadow_label("", 16, Palette.TEXT_BONE, 2)
	_header_exp_label.custom_minimum_size = Vector2(92.0, 0.0)
	_header_exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_header_exp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	exp_row.add_child(_header_exp_label)

	var anchor := HeaderMarkVisual.new()
	anchor.configure("anchor")
	anchor.custom_minimum_size = Vector2(72.0, 0.0)
	row.add_child(anchor)


func _build_cards(parent: VBoxContainer) -> void:
	var cards := HBoxContainer.new()
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("separation", 10)
	parent.add_child(cards)

	_build_player_card(cards)
	_build_meal_card(cards)
	_build_cooler_card(cards)
	_build_money_card(cards)
	_build_play_card(cards)


func _build_player_card(parent: HBoxContainer) -> void:
	var card := _status_card(parent, "プレイヤー")
	var portrait := _portrait_box("PLAYER", Palette.GAUGE_CYAN_HI)
	portrait.custom_minimum_size = Vector2(0.0, 112.0)
	card.add_child(portrait)
	_level_label = make_shadow_label("", 42, Color("#2a2118"), 2)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(_level_label)
	_next_exp_label = make_label("", 16, Color("#24486a"), 1, Color("#fff4d4"))
	_next_exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(_next_exp_label)
	_exp_bar = GaugeBarScript.new()
	_exp_bar.show_value = false
	_exp_bar.custom_minimum_size = Vector2(0.0, 18.0)
	_exp_bar.set_colors(Palette.GAUGE_CYAN, Palette.GAUGE_CYAN_HI)
	card.add_child(_exp_bar)
	_stats_box = VBoxContainer.new()
	_stats_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stats_box.add_theme_constant_override("separation", 2)
	card.add_child(_stats_box)


func _build_meal_card(parent: HBoxContainer) -> void:
	var card := _status_card(parent, "効果中の料理")
	_meal_badge = make_shadow_label("", 17, Palette.GAUGE_GREEN_HI, 2)
	_meal_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(_meal_badge)
	_meal_image = TextureRect.new()
	_meal_image.custom_minimum_size = Vector2(0.0, 134.0)
	_meal_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_meal_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card.add_child(_meal_image)
	_meal_name_label = make_label("", 28, Color("#2a2118"), 1, Color("#fff4d4"))
	_meal_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(_meal_name_label)
	_meal_effect_label = make_label("", 18, Palette.GAUGE_GREEN_HI, 2)
	_meal_effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_meal_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(_meal_effect_label)
	_meal_hint_label = _note_box(card, "")


func _build_cooler_card(parent: HBoxContainer) -> void:
	var card := _status_card(parent, "クーラーボックス")
	var visual := _portrait_box("COOLER", Palette.GAUGE_CYAN_HI)
	visual.custom_minimum_size = Vector2(0.0, 156.0)
	card.add_child(visual)
	_cooler_count_label = make_shadow_label("", 40, Color("#2a2118"), 2)
	_cooler_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(_cooler_count_label)
	_note_box(card, "釣った魚を保存できます\n容量を増やすと、より多くの魚を持ち帰れます")
	var extend := make_button("拡張する", func() -> void: pass, 156.0, false)
	extend.custom_minimum_size = Vector2(150.0, 34.0)
	extend.disabled = true
	extend.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.add_child(extend)


func _build_money_card(parent: HBoxContainer) -> void:
	var card := _status_card(parent, "所持金")
	var visual := _portrait_box("GOLD", Palette.GOLD_BRIGHT)
	visual.custom_minimum_size = Vector2(0.0, 160.0)
	card.add_child(visual)
	_money_label = make_shadow_label("", 39, Color("#2a2118"), 2)
	_money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(_money_label)
	_note_box(card, "釣り具の購入や\nクーラーボックスの拡張に使用します")


func _build_play_card(parent: HBoxContainer) -> void:
	var card := _status_card(parent, "プレイ時間")
	var visual := _portrait_box("TIME", Palette.TEXT_BONE)
	visual.custom_minimum_size = Vector2(0.0, 160.0)
	card.add_child(visual)
	_play_label = make_shadow_label("", 35, Color("#2a2118"), 2)
	_play_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(_play_label)
	_note_box(card, "冒険の記録です\nたくさん釣って、強くなろう！")


func _build_footer(parent: VBoxContainer) -> void:
	var footer := _panel_box(Color("#08213a"), Color("#06111e"), Palette.GOLD_DEEP, 4)
	footer.custom_minimum_size = Vector2(0.0, 84.0)
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(footer)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	footer.add_child(row)
	var portrait := _portrait_box("READY", Palette.GAUGE_GREEN_HI)
	portrait.custom_minimum_size = Vector2(120.0, 0.0)
	row.add_child(portrait)
	_footer_message_label = make_shadow_label("", 22, Palette.TEXT_BONE, 3)
	_footer_message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_footer_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_footer_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(_footer_message_label)
	var back := make_button("港へ戻る", _close, 190.0, true)
	back.custom_minimum_size = Vector2(178.0, 48.0)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(back)


func show_summary() -> void:
	var stats := PlayerProgress.get_base_stats()
	_header_level_label.text = "Lv.%d" % PlayerProgress.level
	_level_label.text = "Lv.%d" % PlayerProgress.level
	var next_exp := PlayerProgress.exp_to_next_level()
	if PlayerProgress.level >= GameData.MAX_LEVEL:
		_header_exp_bar.max_value = 1.0
		_header_exp_bar.set_value(1.0)
		_exp_bar.max_value = 1.0
		_exp_bar.set_value(1.0)
		_header_exp_label.text = "MAX"
		_next_exp_label.text = "EXP MAX"
	else:
		_header_exp_bar.max_value = maxf(1.0, float(next_exp))
		_header_exp_bar.set_value(float(PlayerProgress.exp))
		_exp_bar.max_value = maxf(1.0, float(next_exp))
		_exp_bar.set_value(float(PlayerProgress.exp))
		_header_exp_label.text = "%d / %d" % [PlayerProgress.exp, next_exp]
		_next_exp_label.text = "次のレベルまで %d EXP" % maxi(0, next_exp - PlayerProgress.exp)

	_clear_container(_stats_box)
	_stats_box.add_child(_stat_line("体力", "%d" % int(round(float(stats.get("max_energy", 0)))), Palette.GAUGE_RED_HI))
	_stats_box.add_child(_stat_line("攻撃力", "%.1f" % float(stats.get("reel_power", 0)), Palette.GAUGE_CYAN_HI))
	_stats_box.add_child(_stat_line("防御力", "%d" % int(stats.get("technique", 0)), Palette.GOLD_BRIGHT))
	_stats_box.add_child(_stat_line("素早さ", "%d" % int(stats.get("focus", 0)), Color("#b98cff")))
	_stats_box.add_child(_stat_line("運", "%d" % (PlayerProgress.level + _owned_fish_kinds() + 5), Palette.GAUGE_GREEN_HI))

	if PlayerProgress.pending_buff.is_empty():
		_meal_badge.text = "効果なし"
		_meal_image.texture = null
		_meal_name_label.text = "料理なし"
		_meal_effect_label.text = "次の料理で準備"
		_meal_hint_label.text = "魚を料理すると\n次の釣行で効果が発動します"
	else:
		var recipe_id := String(PlayerProgress.pending_buff.get("recipe_id", ""))
		_meal_badge.text = "効果中！ あと 1回"
		_meal_image.texture = _meal_texture(recipe_id)
		_meal_name_label.text = String(PlayerProgress.pending_buff.get("name", "料理"))
		_meal_effect_label.text = _effect_summary(String(PlayerProgress.pending_buff.get("text", "")))
		_meal_hint_label.text = "次回の釣行で\n%s" % _effect_sentence(String(PlayerProgress.pending_buff.get("text", "")))

	_cooler_count_label.text = "%d / 20" % _total_fish_count()
	_money_label.text = "%d G" % PlayerProgress.money
	_play_label.text = format_play_time(PlayerProgress.play_seconds)
	if PlayerProgress.level >= GameData.BOSS_UNLOCK_LEVEL:
		_footer_message_label.text = (
			"Lv.%d到達！ 港のぬしに挑めます！\n"
			+ "効果中の料理を活かして、次の釣りへ向かおう！"
		) % PlayerProgress.level
	else:
		_footer_message_label.text = "うまい料理で力がみなぎってきた！\n次の釣りもがんばろう！"
	_present()


func _status_card(parent: HBoxContainer, title: String) -> VBoxContainer:
	var panel := _texture_panel_box(
		STATUS_CARD_FRAME,
		24,
		_style_box(Color("#f2e4c2"), Color("#60401f"), Palette.GOLD_BRIGHT, 5, 5),
		14.0,
		12.0
	)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0.0, 0.0)
	parent.add_child(panel)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 7)
	panel.add_child(box)

	var title_label := make_shadow_label(title, 20, Palette.TEXT_BONE, 3)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.custom_minimum_size = Vector2(0.0, 34.0)
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	box.add_child(title_label)
	return box


func _portrait_box(text: String, accent: Color) -> PanelContainer:
	var panel := _panel_box(Color("#10283f"), Color("#07121e"), accent, 3)
	var visual := StatusIconVisual.new()
	visual.configure(text, accent)
	visual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	visual.size_flags_vertical = Control.SIZE_EXPAND_FILL
	visual.custom_minimum_size = Vector2(0.0, 48.0)
	panel.add_child(visual)
	return panel


func _note_box(parent: VBoxContainer, text: String) -> Label:
	var panel := _panel_box(Color("#fff1cf"), Color("#b5813a"), Color("#e0b667"), 2)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var label := make_label(text, 16, Color("#3f2d1a"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(label)
	return label


func _stat_line(title: String, value: String, accent: Color) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0.0, 26.0)
	row.add_theme_constant_override("separation", 6)
	var icon := _panel_box(accent.darkened(0.25), Color("#4b3017"), Palette.GOLD_BRIGHT, 1)
	icon.custom_minimum_size = Vector2(24.0, 22.0)
	row.add_child(icon)
	var name := make_label(title, 17, Color("#2a2118"))
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(name)
	var amount := make_label(value, 18, Color("#2a2118"), 1, Color("#fff4d4"))
	amount.custom_minimum_size = Vector2(54.0, 0.0)
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(amount)
	return row


func _effect_summary(text: String) -> String:
	if text.contains("最大体力"):
		return "効果：体力アップ【中】"
	if text.contains("巻"):
		return "効果：攻撃力アップ【中】"
	return "効果：釣行サポート【中】"


func _effect_sentence(text: String) -> String:
	var cleaned := text
	if cleaned.begins_with("次の釣行で"):
		cleaned = cleaned.trim_prefix("次の釣行で")
	return cleaned


func _present() -> void:
	modulate.a = 0.0
	await get_tree().process_frame
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "modulate:a", 1.0, 0.18)


func _close() -> void:
	closed.emit()
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "modulate:a", 0.0, 0.12)
	tw.tween_callback(queue_free)


func _total_fish_count() -> int:
	var total := 0
	for fish_id in GameData.get_all_fish_ids():
		total += PlayerProgress.fish_count(fish_id)
	return total


func _owned_fish_kinds() -> int:
	var kinds := 0
	for fish_id in GameData.get_all_fish_ids():
		if PlayerProgress.fish_count(fish_id) > 0:
			kinds += 1
	return kinds


func _clear_container(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _panel_box(fill: Color, border: Color, inner: Color, border_width: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style_box(fill, border, inner, border_width, 5))
	return panel


func _texture_panel_box(
	path: String, margin: int, fallback: StyleBox, content_x: float, content_y: float
) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel", _texture_style_box(path, margin, fallback, content_x, content_y)
	)
	return panel


func _style_box(fill: Color, border: Color, inner: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border.lerp(inner, 0.18)
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 14.0
	sb.content_margin_top = 10.0
	sb.content_margin_right = 14.0
	sb.content_margin_bottom = 10.0
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0.0, 3.0)
	sb.anti_aliasing = false
	return sb


func _meal_texture(recipe_id: String) -> Texture2D:
	if recipe_id == "salt_grill":
		return load(DISH_FEATURE_AJI) as Texture2D
	return _recipe_icon(recipe_id)


func _recipe_icon(recipe_id: String) -> Texture2D:
	var icon_index := 0
	match recipe_id:
		"sashimi":
			icon_index = 1
		"simmered":
			icon_index = 2
		"soup":
			icon_index = 3
		"fry":
			icon_index = 4
	var tex := load(DISH_ICON_SHEET) as Texture2D
	if tex == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	var cell_w := float(tex.get_width()) / 3.0
	var cell_h := float(tex.get_height()) / 2.0
	atlas.region = Rect2(float(icon_index % 3) * cell_w, float(int(icon_index / 3)) * cell_h, cell_w, cell_h)
	return atlas


func _texture_style_box(
	path: String, margin: int, fallback: StyleBox, content_x: float, content_y: float
) -> StyleBox:
	var tex := load(path) as Texture2D
	if tex == null:
		return fallback
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = margin
	sb.texture_margin_top = margin
	sb.texture_margin_right = margin
	sb.texture_margin_bottom = margin
	sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	sb.expand_margin_left = 5.0
	sb.expand_margin_top = 5.0
	sb.expand_margin_right = 5.0
	sb.expand_margin_bottom = 5.0
	sb.content_margin_left = content_x
	sb.content_margin_top = content_y
	sb.content_margin_right = content_x
	sb.content_margin_bottom = content_y
	return sb
