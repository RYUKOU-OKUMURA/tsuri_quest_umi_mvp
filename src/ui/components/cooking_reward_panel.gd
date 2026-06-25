extends "res://src/ui/screen_base.gd"
## 調理後の MEAL_RESULT / EXP_GAIN を担う報酬オーバーレイ。
# 料理を食べた結果、EXP、初回ボーナス、次回バフを一拍置いて見せる。
signal closed

const GaugeBarScript = preload("res://src/ui/components/gauge_bar.gd")

const DISH_FEATURE_AJI := "res://assets/showcase/cooking/dish_feature_aji_shioyaki.png"
const DISH_ICON_SHEET := "res://assets/showcase/cooking/dish_icon_sheet.png"
const MEAL_RESULT_FRAME := "res://assets/showcase/cooking/meal_result_frame.png"

var _dialog: PanelContainer
var _header_title: Label
var _dish_title: Label
var _dish_image: TextureRect
var _exp_bar: GaugeBar
var _exp_label: Label
var _base_label: Label
var _bonus_label: Label
var _total_label: Label
var _buff_label: Label
var _growth_label: Label
var _confirm_button: Button
var _flow_step_cards: Array[PanelContainer] = []
var _flow_step_labels: Array[Label] = []

var _target_exp := 0.0
var _target_max := 1.0


func _build_screen() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.50)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_dialog = PanelContainer.new()
	_dialog.custom_minimum_size = Vector2(860.0, 0.0)
	_dialog.add_theme_stylebox_override(
		"panel",
		_texture_style_box(
			MEAL_RESULT_FRAME,
			34,
			_style_box(Color("#10283f"), Color("#5e391a"), Palette.GOLD_BRIGHT, 6, 8),
			22.0,
			16.0
		)
	)
	center.add_child(_dialog)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	_dialog.add_child(root)

	_header_title = make_shadow_label("いただきます！", 34, Palette.GOLD_BRIGHT, 4)
	_header_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_header_title)

	var flow_row := HBoxContainer.new()
	flow_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	flow_row.alignment = BoxContainer.ALIGNMENT_CENTER
	flow_row.add_theme_constant_override("separation", 8)
	root.add_child(flow_row)
	_add_flow_step(flow_row, "1 食事")
	_add_flow_step(flow_row, "2 EXP")
	_add_flow_step(flow_row, "3 成長")

	var main := HBoxContainer.new()
	main.add_theme_constant_override("separation", 14)
	root.add_child(main)

	var dish_card := _panel_box(Color("#f2e4c2"), Color("#6c4420"), Palette.GOLD_BRIGHT, 5)
	dish_card.custom_minimum_size = Vector2(330.0, 0.0)
	main.add_child(dish_card)
	var dish_box := VBoxContainer.new()
	dish_box.add_theme_constant_override("separation", 8)
	dish_card.add_child(dish_box)
	_dish_title = make_label("", 24, Color("#2a2118"), 1, Color("#fff4d4"))
	_dish_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dish_box.add_child(_dish_title)
	_dish_image = TextureRect.new()
	_dish_image.custom_minimum_size = Vector2(0.0, 190.0)
	_dish_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dish_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dish_box.add_child(_dish_image)
	var dish_note := make_label("料理を食べて、体に力が湧いてきた。", 17, Color("#4f3b25"))
	dish_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dish_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dish_box.add_child(dish_note)

	var reward_box := VBoxContainer.new()
	reward_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_box.add_theme_constant_override("separation", 8)
	main.add_child(reward_box)

	var exp_card := _panel_box(Color("#0f2238"), Color("#07121e"), Palette.GOLD_DEEP, 5)
	exp_card.custom_minimum_size = Vector2(0.0, 128.0)
	reward_box.add_child(exp_card)
	var exp_layout := VBoxContainer.new()
	exp_layout.add_theme_constant_override("separation", 7)
	exp_card.add_child(exp_layout)
	var exp_title := make_shadow_label("食経験値を獲得！", 23, Palette.TEXT_BONE, 3)
	exp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exp_layout.add_child(exp_title)
	_exp_bar = GaugeBarScript.new()
	_exp_bar.show_value = false
	_exp_bar.custom_minimum_size = Vector2(0.0, 32.0)
	_exp_bar.set_colors(Palette.GAUGE_CYAN, Palette.GAUGE_CYAN_HI)
	exp_layout.add_child(_exp_bar)
	_exp_label = make_shadow_label("", 32, Palette.GOLD_BRIGHT, 4)
	_exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exp_layout.add_child(_exp_label)

	_base_label = _reward_line(reward_box, "基本EXP", Palette.GAUGE_CYAN_HI)
	_bonus_label = _reward_line(reward_box, "初回ボーナス", Palette.GOLD_BRIGHT)
	_total_label = _reward_line(reward_box, "合計獲得", Palette.GAUGE_GREEN_HI)
	_buff_label = _reward_line(reward_box, "次の釣行", Palette.GAUGE_GREEN_HI)
	_growth_label = _reward_line(reward_box, "成長", Palette.GAUGE_RED_HI)

	_confirm_button = make_button("OK", _close, 280.0, true)
	_confirm_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(_confirm_button)


func show_reward(result: Dictionary, exp_before: int, exp_after: int, exp_max: int, leveled: bool) -> void:
	var dish_name := String(result.get("dish_name", "料理"))
	_header_title.text = "ごちそうさま！ 成長へつながった" if leveled else "ごちそうさま！ 食経験値を獲得"
	_dish_title.text = "%sを食べた！" % dish_name
	_dish_image.texture = _featured_dish_texture(String(Dictionary(result.get("buff", {})).get("recipe_id", "")))

	_target_max = maxf(1.0, float(exp_max))
	_target_exp = clampf(float(exp_after), 0.0, _target_max)
	_exp_bar.max_value = _target_max
	_exp_bar.set_value(clampf(float(exp_before), 0.0, _target_max))
	_exp_label.text = "+%d EXP" % int(result.get("total_exp", 0))
	_base_label.text = "料理の経験値 +%d EXP" % int(result.get("base_exp", 0))

	if bool(result.get("first_time", false)):
		_bonus_label.text = "初めて食べた料理！ 追加 +%d EXP" % int(result.get("first_bonus", 0))
	else:
		_bonus_label.text = "記録済み。今回は基本EXPのみ。"
	_total_label.text = "今回の合計 +%d EXP" % int(result.get("total_exp", 0))

	var buff := Dictionary(result.get("buff", {}))
	_buff_label.text = String(buff.get("text", "次の釣行で効果を得る"))
	_growth_label.text = "LEVEL UP! 能力上昇へ" if leveled else "次のレベルまで %d EXP" % maxi(0, exp_max - exp_after)
	_confirm_button.text = "成長を見る" if leveled else "OK"
	_refresh_flow_steps(leveled)
	_present()


func preview_accept() -> void:
	_close()


func _add_flow_step(parent: HBoxContainer, text: String) -> void:
	var card := _panel_box(Color("#17324d"), Color("#07121e"), Palette.GOLD_DEEP, 3)
	card.custom_minimum_size = Vector2(150.0, 34.0)
	parent.add_child(card)
	var label := make_shadow_label(text, 17, Palette.TEXT_BONE, 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card.add_child(label)
	_flow_step_cards.append(card)
	_flow_step_labels.append(label)


func _refresh_flow_steps(leveled: bool) -> void:
	_set_flow_step(0, "1 食事 完了", Color("#f2e4c2"), Palette.GOLD_BRIGHT, Color("#2a2118"))
	_set_flow_step(1, "2 EXP 加算中", Color("#14385a"), Palette.GAUGE_CYAN_HI, Palette.TEXT_BONE)
	if leveled:
		_set_flow_step(2, "3 成長 解放", Color("#5a1f26"), Palette.GAUGE_RED_HI, Palette.GOLD_BRIGHT)
	else:
		_set_flow_step(2, "3 成長 進行中", Color("#17324d"), Palette.GOLD_DEEP, Palette.TEXT_BONE)


func _set_flow_step(index: int, text: String, fill: Color, border: Color, text_color: Color) -> void:
	if index < 0 or index >= _flow_step_cards.size():
		return
	var card := _flow_step_cards[index]
	var label := _flow_step_labels[index]
	card.add_theme_stylebox_override("panel", _style_box(fill, border, Palette.GOLD_BRIGHT, 3, 5))
	label.text = text
	label.add_theme_color_override("font_color", text_color)


func _reward_line(parent: VBoxContainer, title: String, accent: Color) -> Label:
	var card := _panel_box(Color("#f2e4c2"), Color("#60401f"), Color("#d7a456"), 4)
	card.custom_minimum_size = Vector2(0.0, 58.0)
	parent.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var title_label := make_label(title, 17, Color("#60411f"))
	title_label.custom_minimum_size = Vector2(130.0, 0.0)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(title_label)
	var value_label := make_label("", 20, accent, 1, Color("#1d160f"))
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(value_label)
	return value_label


func _present() -> void:
	_dialog.modulate.a = 0.0
	_dialog.scale = Vector2(0.86, 0.86)
	await get_tree().process_frame
	_dialog.pivot_offset = _dialog.size * 0.5
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(_dialog, "scale", Vector2.ONE, 0.28)
	tw.parallel().tween_property(_dialog, "modulate:a", 1.0, 0.16)
	tw.tween_callback(_animate_exp)
	Juicer.add_trauma(0.18)


func _animate_exp() -> void:
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.tween_method(
		func(v: float) -> void:
			_exp_bar.set_value(v),
		_exp_bar.value,
		_target_exp,
		0.55
	)
	tw.tween_callback(_pulse_exp_label)


func _pulse_exp_label() -> void:
	_exp_label.pivot_offset = _exp_label.size * 0.5
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(_exp_label, "scale", Vector2(1.12, 1.12), 0.12)
	tw.tween_property(_exp_label, "scale", Vector2.ONE, 0.18)


func _close() -> void:
	_dialog.pivot_offset = _dialog.size * 0.5
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(_dialog, "scale", Vector2(0.88, 0.88), 0.14)
	tw.parallel().tween_property(_dialog, "modulate:a", 0.0, 0.14)
	tw.tween_callback(
		func() -> void:
			closed.emit()
			queue_free()
	)


func _panel_box(fill: Color, border: Color, inner: Color, border_width: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style_box(fill, border, inner, border_width, 5))
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
	sb.expand_margin_left = 6.0
	sb.expand_margin_top = 6.0
	sb.expand_margin_right = 6.0
	sb.expand_margin_bottom = 6.0
	sb.content_margin_left = content_x
	sb.content_margin_top = content_y
	sb.content_margin_right = content_x
	sb.content_margin_bottom = content_y
	return sb


func _featured_dish_texture(recipe_id: String) -> Texture2D:
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
