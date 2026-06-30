extends "res://src/ui/screen_base.gd"

const HarborBackdropScript = preload("res://src/ui/components/harbor_backdrop.gd")

var _message_label: Label


func _build_screen() -> void:
	var backdrop := HarborBackdropScript.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	move_child(backdrop, 0)

	var wash := ColorRect.new()
	wash.color = Color(0.02, 0.11, 0.18, 0.38)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)

	var root := make_root_margin(18)
	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 12)
	root.add_child(layout)

	layout.add_child(
		make_header(
			"釣り場を選ぶ",
			"Lv.%d　%s　所持金 %d G" % [
				PlayerProgress.level,
				String(GameData.get_rod(PlayerProgress.equipped_rod_id).get("name", "入門竿")),
				PlayerProgress.money,
			]
		)
	)

	var body := HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	layout.add_child(body)

	_build_overview_panel(body)
	_build_spot_grid(body)
	_build_footer(layout)


func _build_overview_panel(parent: Control) -> void:
	var panel := make_panel(true)
	panel.custom_minimum_size = Vector2(315.0, 0.0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 11)
	panel.add_child(box)

	var title := make_label("今日の海況", 27, Palette.TEXT_BONE, 2, Palette.TEXT_OUTLINE_DARK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var unlocked_count := GameData.get_unlocked_fishing_spot_ids(PlayerProgress.level).size()
	var total_count := GameData.get_all_fishing_spot_ids().size()
	var summary := make_label(
		"解放ポイント：%d / %d\n潮位：満ち始め\n天候：快晴\n風：弱" % [unlocked_count, total_count],
		20,
		Color("#eaf6ff"),
		1,
		Palette.TEXT_OUTLINE_DARK
	)
	summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(summary)

	var line := HSeparator.new()
	box.add_child(line)

	var unlocked_title := make_label("次に広がる釣り場", 20, Palette.GOLD_BRIGHT, 1, Palette.TEXT_OUTLINE_DARK)
	box.add_child(unlocked_title)

	var next_text := _next_unlock_text()
	var next_label := make_label(next_text, 17, Color("#d8e8f5"), 1, Palette.TEXT_OUTLINE_DARK)
	next_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(next_label)

	var back := make_button("港へ戻る", func() -> void: navigate("harbor"), 0)
	back.size_flags_vertical = Control.SIZE_SHRINK_END
	box.add_child(back)


func _build_spot_grid(parent: Control) -> void:
	var panel := make_panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var title := make_label("ポイント一覧", 26, Palette.TEXT_DARK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("hseparation", 10)
	grid.add_theme_constant_override("vseparation", 10)
	scroll.add_child(grid)

	for spot_id in GameData.get_all_fishing_spot_ids():
		grid.add_child(_make_spot_card(GameData.get_fishing_spot(spot_id)))


func _build_footer(parent: Control) -> void:
	var panel := make_panel(true)
	panel.custom_minimum_size = Vector2(0.0, 72.0)
	parent.add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)

	_message_label = make_label("狙う魚に合わせてポイントを選ぶ。未解放ポイントはレベル到達後に出航できます。", 18, Color("#eaf6ff"), 1)
	_message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_message_label)

	var default_button := make_button(
		"港内・堤防へ",
		func() -> void: _select_spot(GameData.DEFAULT_FISHING_SPOT_ID),
		190,
		true
	)
	row.add_child(default_button)


func _make_spot_card(spot: Dictionary) -> Button:
	var spot_id := String(spot.get("id", GameData.DEFAULT_FISHING_SPOT_ID))
	var unlocked := GameData.is_fishing_spot_unlocked(spot_id, PlayerProgress.level)
	var boss_spot := bool(spot.get("boss_spot", false))
	var button := Button.new()
	button.text = ""
	button.disabled = not unlocked
	button.custom_minimum_size = Vector2(0.0, 174.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if unlocked else Control.CURSOR_ARROW
	_apply_spot_card_style(button, unlocked, boss_spot)
	if unlocked:
		button.pressed.connect(_select_spot.bind(spot_id))

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	button.add_child(margin)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 5)
	margin.add_child(box)

	var name_row := HBoxContainer.new()
	name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_theme_constant_override("separation", 8)
	box.add_child(name_row)

	var name_label := make_label(String(spot.get("name", spot_id)), 21, _card_title_color(unlocked, boss_spot), 1 if unlocked else 0)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_child(name_label)

	var badge := make_label(_unlock_badge_text(spot, unlocked), 14, _badge_color(unlocked, boss_spot), 1 if unlocked else 0)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_child(badge)

	var description := make_label(String(spot.get("description", "")), 14, _card_body_color(unlocked), 0)
	description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(description)

	var depth := make_label("水深目安：%s" % _depth_range_text(spot), 14, _card_body_color(unlocked), 0)
	depth.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(depth)

	var featured := make_label("狙い：%s" % _featured_fish_text(spot), 14, _card_body_color(unlocked), 0)
	featured.mouse_filter = Control.MOUSE_FILTER_IGNORE
	featured.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(featured)

	var bait := make_label("エサ：%s" % _bait_text(spot), 14, _card_body_color(unlocked), 0)
	bait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(bait)

	if not unlocked:
		var lock := make_label("Lv.%dで解放" % int(spot.get("unlock_level", 1)), 18, Color("#6a4a2b"), 0)
		lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(lock)
	return button


func _select_spot(spot_id: String) -> void:
	if not GameData.is_fishing_spot_unlocked(spot_id, PlayerProgress.level):
		_message_label.text = "%s は Lv.%d で解放されます。" % [
			String(GameData.get_fishing_spot(spot_id).get("name", spot_id)),
			int(GameData.get_fishing_spot(spot_id).get("unlock_level", 1)),
		]
		return
	navigate("fishing", {"spot_id": spot_id})


func _apply_spot_card_style(button: Button, unlocked: bool, boss_spot: bool) -> void:
	var normal := _button_style(
		Color("#fff0c8") if unlocked else Color("#c8bea5"),
		Palette.GOLD_DEEP if not boss_spot else Color("#8e4f38"),
		2
	)
	var hover := _button_style(
		Color("#fff7df") if unlocked else Color("#c8bea5"),
		Palette.GOLD_BRIGHT if not boss_spot else Color("#d87b4e"),
		3
	)
	var pressed := _button_style(
		Color("#e6d0a2") if unlocked else Color("#c8bea5"),
		Palette.WOOD_DARK,
		2
	)
	var disabled := _button_style(Color("#b4ad9e"), Color("#756957"), 1)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)


func _button_style(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(6)
	style.shadow_color = Color(0.02, 0.03, 0.04, 0.28)
	style.shadow_size = 4
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	return style


func _depth_range_text(spot: Dictionary) -> String:
	var range: Array = spot.get("depth_range", [0.0, 0.0])
	if range.size() < 2:
		return "--.-m"
	return "%.1f〜%.1fm" % [float(range[0]), float(range[1])]


func _featured_fish_text(spot: Dictionary) -> String:
	var names: Array[String] = []
	for fish_id_variant in Array(spot.get("featured_fish", [])):
		var fish := GameData.get_fish(String(fish_id_variant))
		if fish.is_empty():
			continue
		names.append(String(fish.get("name", fish_id_variant)))
		if names.size() >= 5:
			break
	return "、".join(PackedStringArray(names))


func _bait_text(spot: Dictionary) -> String:
	var baits: Array[String] = []
	for bait_variant in Array(spot.get("recommended_baits", [])):
		baits.append(String(bait_variant))
	return "、".join(PackedStringArray(baits))


func _unlock_badge_text(spot: Dictionary, unlocked: bool) -> String:
	if not unlocked:
		return "LOCK"
	if bool(spot.get("boss_spot", false)):
		return "ぬし"
	return "Lv.%d" % int(spot.get("unlock_level", 1))


func _next_unlock_text() -> String:
	var lines: Array[String] = []
	for spot_id in GameData.get_all_fishing_spot_ids():
		var spot := GameData.get_fishing_spot(spot_id)
		var unlock_level := int(spot.get("unlock_level", 1))
		if unlock_level > PlayerProgress.level:
			lines.append("Lv.%d　%s" % [unlock_level, String(spot.get("name", spot_id))])
		if lines.size() >= 4:
			break
	if lines.is_empty():
		return "すべての釣り場を解放済み。終盤の大物とぬしを狙える。"
	return "\n".join(PackedStringArray(lines))


func _card_title_color(unlocked: bool, boss_spot: bool) -> Color:
	if not unlocked:
		return Color("#5f5a50")
	return Color("#6a2718") if boss_spot else Palette.TEXT_DARK


func _card_body_color(unlocked: bool) -> Color:
	return Palette.TEXT_BODY if unlocked else Color("#5f5a50")


func _badge_color(unlocked: bool, boss_spot: bool) -> Color:
	if not unlocked:
		return Color("#5f5a50")
	return Color("#ba3f2c") if boss_spot else Palette.GOLD_DEEP
