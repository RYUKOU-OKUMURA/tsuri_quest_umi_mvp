extends GridContainer
## 調理報酬パネルの報酬カード群（基本EXP/初回/合計/次回効果/成長）。

const CookingRewardVisualsScript = preload("res://src/ui/components/cooking_reward_visuals.gd")
const RewardIconVisual = CookingRewardVisualsScript.RewardIconVisual
const RewardTotalPeakGlowVisual = CookingRewardVisualsScript.RewardTotalPeakGlowVisual
const RewardValuePlateVisual = CookingRewardVisualsScript.RewardValuePlateVisual
const RewardBuffSignalVisual = CookingRewardVisualsScript.RewardBuffSignalVisual

var _preview_state := ""
var _exp_card: PanelContainer
var _base_label: Label
var _bonus_label: Label
var _total_label: Label
var _buff_label: Label
var _growth_label: Label


func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("h_separation", 8)
	add_theme_constant_override("v_separation", 8)
	draw.connect(_draw_reward_grid_backdrop)
	_build_cards()


func set_preview_state(value: String) -> void:
	_preview_state = value
	queue_redraw()
	_queue_reward_card_redraws()


func show_meal_result(result: Dictionary, buff_text: String) -> void:
	visible = true
	columns = 4
	queue_redraw()
	_exp_card.visible = false
	_base_label.text = "+%d EXP" % int(result.get("base_exp", 0))
	if bool(result.get("first_time", false)):
		_bonus_label.text = "+%d EXP" % int(result.get("first_bonus", 0))
	else:
		_bonus_label.text = "記録済み"
	_total_label.text = "+%d EXP" % int(result.get("total_exp", 0))
	_buff_label.text = buff_text
	set_growth_visible(false)
	apply_meal_reward_hierarchy()


func show_exp_gain(result: Dictionary, buff_text: String) -> void:
	visible = false
	columns = 5
	_exp_card.visible = false
	set_growth_visible(true)
	_base_label.text = "料理の経験値 +%d EXP" % int(result.get("base_exp", 0))
	if bool(result.get("first_time", false)):
		_bonus_label.text = "初めて食べた料理！\n+%d EXP" % int(result.get("first_bonus", 0))
	else:
		_bonus_label.text = "記録済み。\n今回は基本EXPのみ。"
	_total_label.text = "今回の合計 +%d EXP" % int(result.get("total_exp", 0))
	_buff_label.text = buff_text


func set_growth_text(text: String) -> void:
	if _growth_label != null:
		_growth_label.text = text


func set_growth_visible(value: bool) -> void:
	var card := CookingAssets.card_from_label(_growth_label)
	if card == null:
		return
	card.visible = value


func set_reward_cards_height(height: float) -> void:
	for label in [_base_label, _bonus_label, _total_label, _buff_label, _growth_label]:
		var card := CookingAssets.card_from_label(label)
		if card != null:
			card.custom_minimum_size = Vector2(0.0, height)
	if _exp_card != null:
		_exp_card.custom_minimum_size = Vector2(280.0, height)


func apply_meal_reward_hierarchy() -> void:
	_set_reward_label_style(_base_label, 34, Palette.GAUGE_CYAN_HI, 4)
	_set_reward_label_style(_bonus_label, 34, Palette.GOLD_BRIGHT, 4)
	_set_reward_label_style(_total_label, 48, Palette.GOLD_BRIGHT, 6)
	_set_reward_label_style(_buff_label, 18, Palette.GAUGE_GREEN_HI, 3)
	_set_reward_card_modulate(_base_label, Palette.COOKING_REWARD_CARD_BASE_MODULATE)
	_set_reward_card_modulate(_bonus_label, Palette.COOKING_REWARD_CARD_BONUS_MODULATE)
	_set_reward_card_modulate(_total_label, Palette.COOKING_REWARD_CARD_TOTAL_MODULATE)
	_set_reward_card_modulate(_buff_label, Palette.COOKING_REWARD_CARD_BUFF_MODULATE)


func _build_cards() -> void:
	_exp_card = CookingAssets.panel_box(
		Palette.COOKING_REWARD_PANEL_FILL,
		Palette.COOKING_REWARD_CARD_FRAME_BORDER,
		Palette.GOLD_DEEP,
		5
	)
	_exp_card.custom_minimum_size = Vector2(280.0, 112.0)
	_exp_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_exp_card)
	var exp_layout := VBoxContainer.new()
	exp_layout.add_theme_constant_override("separation", 4)
	_exp_card.add_child(exp_layout)
	var exp_title := ScreenBase.make_shadow_label("食経験値を獲得！", 23, Palette.TEXT_BONE, 3)
	exp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exp_layout.add_child(exp_title)
	var exp_summary := ScreenBase.make_shadow_label("中央ゲージで加算中", 20, Palette.GAUGE_CYAN_HI, 3)
	exp_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exp_summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	exp_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	exp_summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
	exp_layout.add_child(exp_summary)

	_base_label = _reward_line("基本EXP", "exp", Palette.GAUGE_CYAN_HI)
	_bonus_label = _reward_line("初回ボーナス", "bonus", Palette.GOLD_BRIGHT)
	_total_label = _reward_line("合計獲得", "total", Palette.GAUGE_GREEN_HI)
	_buff_label = _reward_line("次の釣行", "buff", Palette.GAUGE_GREEN_HI)
	_growth_label = _reward_line("成長", "growth", Palette.GAUGE_RED_HI)


func _reward_line(title: String, icon_mode: String, accent: Color) -> Label:
	var card := CookingAssets.compact_panel_box(
		Palette.COOKING_SUMMARY_CARD_FILL,
		Palette.COOKING_SUMMARY_CARD_BORDER,
		Palette.COOKING_SUMMARY_CARD_INNER,
		4
	)
	card.name = _reward_card_node_name(icon_mode)
	card.add_theme_stylebox_override(
		"panel",
		CookingAssets.texture_style_box(
			CookingAssets.REWARD_CARD_FRAME,
			22,
			CookingAssets.compact_style_box(
				Palette.COOKING_REWARD_CARD_FRAME_FILL,
				Palette.COOKING_REWARD_CARD_FRAME_BORDER,
				Palette.GOLD_DEEP,
				4,
				5
			),
			8.0,
			5.0
		)
	)
	card.custom_minimum_size = Vector2(0.0, 112.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.draw.connect(func() -> void: _draw_reward_card_backdrop(card, icon_mode))
	add_child(card)
	if icon_mode == "total":
		var peak_glow := RewardTotalPeakGlowVisual.new()
		peak_glow.name = "RewardTotalPeakGlow"
		peak_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		card.add_child(peak_glow)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 5)
	card.add_child(box)
	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", 4)
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(title_row)
	var icon := RewardIconVisual.new()
	icon.configure(icon_mode, accent)
	icon.custom_minimum_size = Vector2(38.0, 32.0)
	title_row.add_child(icon)
	var title_label := ScreenBase.make_shadow_label(title, 16, Palette.TEXT_BONE, 2)
	title_label.custom_minimum_size = Vector2(0.0, 26.0)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_label.clip_text = true
	title_row.add_child(title_label)
	if icon_mode == "buff":
		var value_stack := Control.new()
		value_stack.custom_minimum_size = Vector2(0.0, 66.0)
		value_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
		box.add_child(value_stack)
		var plate := RewardValuePlateVisual.new()
		plate.name = "RewardBuffEffectPlate"
		plate.configure(icon_mode, accent)
		plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		value_stack.add_child(plate)
		var value_row := HBoxContainer.new()
		value_row.add_theme_constant_override("separation", 7)
		value_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		value_row.offset_left = 8.0
		value_row.offset_top = 5.0
		value_row.offset_right = -10.0
		value_row.offset_bottom = -5.0
		value_stack.add_child(value_row)
		var signal_visual := RewardBuffSignalVisual.new()
		signal_visual.name = "RewardBuffSignal"
		signal_visual.custom_minimum_size = Vector2(66.0, 56.0)
		value_row.add_child(signal_visual)
		var buff_value := ScreenBase.make_shadow_label("", 14, accent, 2)
		buff_value.custom_minimum_size = Vector2(0.0, 52.0)
		buff_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buff_value.size_flags_vertical = Control.SIZE_EXPAND_FILL
		buff_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		buff_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		buff_value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		buff_value.clip_text = false
		value_row.add_child(buff_value)
		return buff_value
	var value_stack := Control.new()
	value_stack.custom_minimum_size = Vector2(0.0, 66.0)
	value_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(value_stack)
	var plate := RewardValuePlateVisual.new()
	plate.configure(icon_mode, accent)
	plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	value_stack.add_child(plate)
	var value_label := ScreenBase.make_shadow_label("", 16, accent, 3)
	value_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	value_label.offset_left = 8.0
	value_label.offset_right = -8.0
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	value_label.clip_text = true
	value_stack.add_child(value_label)
	return value_label


func _draw_reward_grid_backdrop() -> void:
	if _preview_state != "MEAL_RESULT":
		return
	var s := size
	if s.x <= 0.0 or s.y <= 0.0:
		return
	var top := 4.0
	var bottom := s.y - 4.0
	var band := Rect2(Vector2(4.0, top), Vector2(s.x - 8.0, maxf(0.0, bottom - top)))
	draw_rect(band, Color(Palette.COOKING_REWARD_GRID_BACKDROP, 0.16))
	draw_line(
		Vector2(16.0, top + 4.0),
		Vector2(s.x - 16.0, top + 4.0),
		Color(Palette.COOKING_REWARD_ACCENT_BONUS, 0.22),
		2.0
	)
	draw_line(
		Vector2(16.0, bottom - 2.0),
		Vector2(s.x - 16.0, bottom - 2.0),
		Color(Palette.COOKING_REWARD_ACCENT_FALLBACK, 0.16),
		2.0
	)
	for i in range(6):
		var p := Vector2(
			s.x * (0.08 + float(i) * 0.17),
			top + 10.0 + float(i % 2) * 12.0
		)
		var sparkle := Color(Palette.COOKING_REWARD_ACCENT_BONUS, 0.25 if i % 2 == 0 else 0.14)
		draw_line(p + Vector2(-3.0, 0.0), p + Vector2(3.0, 0.0), sparkle, 1.3)
		draw_line(p + Vector2(0.0, -3.0), p + Vector2(0.0, 3.0), sparkle, 1.3)


func _draw_reward_card_backdrop(card: Control, icon_mode: String) -> void:
	var s := card.size
	if s.x <= 0.0 or s.y <= 0.0:
		return
	var center := Vector2(s.x * 0.50, s.y * 0.67)
	if _preview_state == "MEAL_RESULT":
		_draw_reward_award_well(card, icon_mode)
	_draw_reward_header_ribbon(card, icon_mode)
	match icon_mode:
		"exp":
			_draw_reward_exp_backdrop(card, center)
		"bonus":
			_draw_reward_bonus_backdrop(card, center)
		"total":
			_draw_reward_total_backdrop(card, center)
		"buff":
			_draw_reward_buff_backdrop(card, center)
		"growth":
			_draw_reward_growth_backdrop(card, center)


func _draw_reward_award_well(card: Control, icon_mode: String) -> void:
	var s := card.size
	var accent := _reward_card_draw_accent(icon_mode)
	var well := Rect2(Vector2(13.0, 45.0), Vector2(maxf(12.0, s.x - 26.0), maxf(24.0, s.y - 58.0)))
	card.draw_rect(well, Color(Palette.COOKING_REWARD_DEEP_INK, 0.28))
	var fill := accent
	fill.a = 0.10 if icon_mode == "total" else 0.07
	card.draw_rect(Rect2(well.position + Vector2(4.0, 4.0), well.size - Vector2(8.0, 8.0)), fill)
	var rim := accent
	rim.a = 0.32 if icon_mode == "total" else 0.20
	card.draw_line(well.position + Vector2(6.0, 1.0), well.position + Vector2(well.size.x - 6.0, 1.0), rim, 2.0)
	card.draw_line(
		well.position + Vector2(6.0, well.size.y - 1.0),
		well.position + Vector2(well.size.x - 6.0, well.size.y - 1.0),
		Color(Palette.COOKING_REWARD_CARD_FRAME_BORDER, 0.68),
		2.0
	)
	if icon_mode == "total":
		card.draw_ellipse(
			well.get_center(),
			well.size.x * 0.34,
			well.size.y * 0.40,
			Color(Palette.COOKING_REWARD_ACCENT_TOTAL, 0.12)
		)


func _draw_reward_header_ribbon(card: Control, icon_mode: String) -> void:
	var s := card.size
	var accent := _reward_card_draw_accent(icon_mode)
	var ribbon := Rect2(Vector2(13.0, 8.0), Vector2(maxf(12.0, s.x - 26.0), 30.0))
	card.draw_rect(ribbon, Color(Palette.COOKING_REWARD_DEEP_INK, 0.78))
	card.draw_rect(
		Rect2(ribbon.position + Vector2(3.0, 3.0), ribbon.size - Vector2(6.0, 6.0)),
		Color(Palette.COOKING_REWARD_CARD_FRAME_FILL, 0.54)
	)
	var top_line := accent
	top_line.a = 0.62 if icon_mode == "total" else 0.46
	card.draw_line(ribbon.position + Vector2(5.0, 2.0), ribbon.position + Vector2(ribbon.size.x - 5.0, 2.0), top_line, 2.0)
	card.draw_line(
		ribbon.position + Vector2(5.0, ribbon.size.y - 2.0),
		ribbon.position + Vector2(ribbon.size.x - 5.0, ribbon.size.y - 2.0),
		Color(Palette.COOKING_REWARD_CARD_FRAME_BORDER, 0.82),
		2.0
	)
	for side in [-1.0, 1.0]:
		var x := ribbon.position.x if side < 0.0 else ribbon.end.x
		var notch := PackedVector2Array(
			[
				Vector2(x, ribbon.position.y + 5.0),
				Vector2(x + side * 10.0, ribbon.position.y + 14.0),
				Vector2(x, ribbon.position.y + ribbon.size.y - 5.0),
			]
		)
		var notch_color := accent
		notch_color.a = 0.42
		card.draw_colored_polygon(notch, notch_color)
	for i in range(3):
		var x := ribbon.position.x + 18.0 + float(i) * 12.0
		var slash := accent
		slash.a = 0.28
		card.draw_line(Vector2(x, ribbon.position.y + 6.0), Vector2(x - 8.0, ribbon.end.y - 6.0), slash, 1.4)
	if icon_mode == "total":
		var glow := Color(Palette.COOKING_REWARD_ACCENT_TOTAL, 0.16)
		card.draw_ellipse(ribbon.get_center() + Vector2(0.0, 2.0), ribbon.size.x * 0.28, 10.0, glow)


func _reward_card_draw_accent(icon_mode: String) -> Color:
	match icon_mode:
		"exp":
			return Palette.COOKING_REWARD_ACCENT_EXP
		"bonus":
			return Palette.COOKING_REWARD_ACCENT_BONUS
		"total":
			return Palette.COOKING_REWARD_ACCENT_TOTAL
		"buff":
			return Palette.COOKING_REWARD_ACCENT_BUFF
		"growth":
			return Palette.COOKING_REWARD_ACCENT_GROWTH
		_:
			return Palette.COOKING_REWARD_ACCENT_FALLBACK


func _draw_reward_exp_backdrop(card: Control, center: Vector2) -> void:
	var cyan := Color(Palette.COOKING_REWARD_ACCENT_EXP, 0.18)
	var green := Color(Palette.COOKING_REWARD_ACCENT_EXP_GREEN, 0.20)
	card.draw_ellipse(center + Vector2(0.0, 22.0), 66.0, 12.0, Color(Color.BLACK, 0.16))
	card.draw_arc(
		center + Vector2(0.0, 8.0), 30.0, 0.0, PI, 28, Color(Palette.TEXT_BONE, 0.72), 7.0
	)
	card.draw_arc(
		center + Vector2(0.0, 5.0),
		24.0,
		0.0,
		PI,
		24,
		Color(Palette.COOKING_SMALL_ICON_MEAL_FILL, 0.74),
		7.0
	)
	for x in [-35.0, 35.0]:
		card.draw_line(center + Vector2(x, 14.0), center + Vector2(x, -22.0), green, 5.0)
		card.draw_polygon(
			PackedVector2Array(
				[
					center + Vector2(x, -30.0),
					center + Vector2(x - 9.0, -14.0),
					center + Vector2(x + 9.0, -14.0),
				]
			),
			PackedColorArray([green, green, green])
		)
	for i in range(6):
		var p := center + Vector2(-55.0 + float(i) * 22.0, -22.0 + float(i % 2) * 42.0)
		card.draw_line(p + Vector2(-4.0, 0.0), p + Vector2(4.0, 0.0), cyan, 2.0)
		card.draw_line(p + Vector2(0.0, -4.0), p + Vector2(0.0, 4.0), cyan, 2.0)


func _draw_reward_bonus_backdrop(card: Control, center: Vector2) -> void:
	var gold := Color(Palette.COOKING_REWARD_ACCENT_BONUS, 0.22)
	var red := Color(Palette.COOKING_REWARD_BONUS_FLAG, 0.48)
	card.draw_ellipse(center + Vector2(0.0, 23.0), 64.0, 11.0, Color(Color.BLACK, 0.15))
	card.draw_rect(
		Rect2(center.x - 44.0, center.y + 4.0, 88.0, 18.0),
		Color(Palette.COOKING_REWARD_BONUS_TABLE, 0.42)
	)
	card.draw_rect(Rect2(center.x - 5.0, center.y - 30.0, 10.0, 40.0), red)
	card.draw_polygon(
		PackedVector2Array(
			[
				center + Vector2(5.0, -28.0),
				center + Vector2(54.0, -16.0),
				center + Vector2(5.0, -2.0),
			]
		),
		PackedColorArray([gold, gold, gold])
	)
	for x in [-30.0, 0.0, 30.0]:
		card.draw_arc(
			center + Vector2(x, 7.0), 18.0, PI, TAU, 18, Color(Palette.TEXT_BONE, 0.72), 7.0
		)


func _draw_reward_total_backdrop(card: Control, center: Vector2) -> void:
	var gold := Color(Palette.COOKING_REWARD_ACCENT_BONUS, 0.28)
	var hot := Color(Palette.COOKING_REWARD_ACCENT_TOTAL, 0.22)
	for i in range(16):
		var a := TAU * float(i) / 16.0
		var inner := center + Vector2(cos(a), sin(a)) * 18.0
		var outer := center + Vector2(cos(a), sin(a)) * (70.0 if i % 2 == 0 else 52.0)
		card.draw_line(inner, outer, hot, 4.0 if i % 2 == 0 else 2.0)
	var points := PackedVector2Array()
	for i in range(10):
		var radius := 34.0 if i % 2 == 0 else 15.0
		var a := -PI * 0.5 + TAU * float(i) / 10.0
		points.append(center + Vector2(cos(a), sin(a)) * radius)
	var colors := PackedColorArray()
	for _i in range(points.size()):
		colors.append(gold)
	card.draw_polygon(points, colors)
	card.draw_circle(center, 13.0, Color(Palette.TEXT_BONE, 0.22))


func _draw_reward_buff_backdrop(card: Control, center: Vector2) -> void:
	var green := Color(Palette.COOKING_REWARD_ACCENT_BUFF, 0.23)
	var cyan := Color(Palette.COOKING_REWARD_ACCENT_EXP, 0.22)
	card.draw_circle(center + Vector2(-20.0, 4.0), 32.0, Color(Palette.COOKING_REWARD_BUFF_FIELD, 0.46))
	card.draw_circle(
		center + Vector2(-20.0, 4.0), 24.0, Color(Palette.COOKING_SMALL_ICON_BUFF_BACKING, 0.44)
	)
	var fish := PackedVector2Array(
		[
			center + Vector2(-45.0, 1.0),
			center + Vector2(-30.0, -13.0),
			center + Vector2(-4.0, -7.0),
			center + Vector2(8.0, 0.0),
			center + Vector2(-4.0, 8.0),
			center + Vector2(-30.0, 14.0),
		]
	)
	card.draw_colored_polygon(fish, cyan)
	card.draw_colored_polygon(
		PackedVector2Array(
			[
				center + Vector2(5.0, -7.0),
				center + Vector2(28.0, -22.0),
				center + Vector2(21.0, 0.0),
				center + Vector2(28.0, 22.0),
				center + Vector2(5.0, 8.0),
			]
		),
		Color(Palette.COOKING_REWARD_BUFF_FISH_TAIL, 0.22)
	)
	for x in [34.0, 54.0]:
		card.draw_line(center + Vector2(x, 24.0), center + Vector2(x, -24.0), green, 5.0)
		card.draw_polygon(
			PackedVector2Array(
				[
					center + Vector2(x, -31.0),
					center + Vector2(x - 9.0, -15.0),
					center + Vector2(x + 9.0, -15.0),
				]
			),
			PackedColorArray([green, green, green])
		)


func _draw_reward_growth_backdrop(card: Control, center: Vector2) -> void:
	var red := Color(Palette.COOKING_REWARD_ACCENT_GROWTH, 0.24)
	var gold := Color(Palette.COOKING_REWARD_ACCENT_BONUS, 0.22)
	card.draw_line(center + Vector2(0.0, 34.0), center + Vector2(0.0, -34.0), red, 9.0)
	card.draw_polygon(
		PackedVector2Array(
			[
				center + Vector2(0.0, -45.0),
				center + Vector2(-26.0, -12.0),
				center + Vector2(26.0, -12.0),
			]
		),
		PackedColorArray([gold, gold, gold])
	)
	card.draw_arc(center + Vector2(0.0, 12.0), 30.0, 0.0, TAU, 30, gold, 4.0)


func _reward_card_node_name(icon_mode: String) -> String:
	match icon_mode:
		"exp":
			return "RewardCardBaseExp"
		"bonus":
			return "RewardCardFirstBonus"
		"total":
			return "RewardCardTotalExp"
		"buff":
			return "RewardCardNextEffect"
		"growth":
			return "RewardCardGrowth"
		_:
			return "RewardCard"


func _set_reward_label_style(label: Label, font_size: int, color: Color, outline: int) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", outline)


func _set_reward_card_modulate(label: Label, color: Color) -> void:
	var card := CookingAssets.card_from_label(label)
	if card != null:
		card.modulate = color


func _queue_reward_card_redraws() -> void:
	for label in [_base_label, _bonus_label, _total_label, _buff_label, _growth_label]:
		var card := CookingAssets.card_from_label(label)
		if card != null:
			card.queue_redraw()
