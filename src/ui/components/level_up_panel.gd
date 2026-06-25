extends "res://src/ui/screen_base.gd"
## 調理フローの LEVEL_UP_OVERLAY。
# レベル遷移、能力上昇、Lv.5 解放を一画面の報酬ピークとして見せる。
signal closed

const LEVEL_UP_FRAME := "res://assets/showcase/cooking/level_up_frame.png"

var _dialog: PanelContainer
var _level_line: Label
var _stats_box: VBoxContainer
var _unlock_card: PanelContainer
var _unlock_title: Label
var _unlock_body: Label


func _build_screen() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.58)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	_add_burst_layer()

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_dialog = PanelContainer.new()
	_dialog.custom_minimum_size = Vector2(760.0, 0.0)
	_dialog.add_theme_stylebox_override(
		"panel",
		_texture_style_box(
			LEVEL_UP_FRAME,
			36,
			_style_box(Color("#10233a"), Color("#7b4b20"), Palette.GOLD_BRIGHT, 6, 8),
			22.0,
			18.0
		)
	)
	center.add_child(_dialog)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	_dialog.add_child(box)

	var title := make_shadow_label("LEVEL UP!", 52, Palette.GOLD_BRIGHT, 5)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	_level_line = make_shadow_label("", 34, Palette.TEXT_BONE, 4)
	_level_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_level_line)

	_stats_box = VBoxContainer.new()
	_stats_box.add_theme_constant_override("separation", 6)
	_stats_box.custom_minimum_size = Vector2(650.0, 0.0)
	_stats_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_stats_box)

	_unlock_card = _panel_box(Color("#f2e4c2"), Color("#70451f"), Palette.GOLD_BRIGHT, 5)
	_unlock_card.custom_minimum_size = Vector2(650.0, 88.0)
	_unlock_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_unlock_card)
	var unlock_layout := HBoxContainer.new()
	unlock_layout.add_theme_constant_override("separation", 12)
	_unlock_card.add_child(unlock_layout)
	var unlock_icon := _badge_box("BOSS", Palette.GAUGE_RED_HI, Color("#fff1c7"))
	unlock_icon.custom_minimum_size = Vector2(70.0, 0.0)
	unlock_layout.add_child(unlock_icon)
	var unlock_text := VBoxContainer.new()
	unlock_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unlock_layout.add_child(unlock_text)
	_unlock_title = make_label("", 22, Color("#2a2118"), 1, Color("#fff4d4"))
	unlock_text.add_child(_unlock_title)
	_unlock_body = make_label("", 17, Color("#4d3924"))
	_unlock_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	unlock_text.add_child(_unlock_body)

	var ok := make_button("OK", _close, 260.0, true)
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(ok)


func show_level_up(
	level_from: int, level_to: int, old_stats: Dictionary, new_stats: Dictionary
) -> void:
	_level_line.text = "Lv.%d   ->   Lv.%d" % [level_from, level_to]
	_rebuild_stats(old_stats, new_stats)
	var boss_unlocked := (
		level_from < GameData.BOSS_UNLOCK_LEVEL and level_to >= GameData.BOSS_UNLOCK_LEVEL
	)
	_unlock_card.visible = boss_unlocked
	if boss_unlocked:
		_unlock_title.text = "港のぬしに挑戦できるようになった！"
		_unlock_body.text = "Lv.%d到達。港の大岩周辺で、ぬしとの本格ファイトが解放されます。" % GameData.BOSS_UNLOCK_LEVEL
	_present()


func _rebuild_stats(old_stats: Dictionary, new_stats: Dictionary) -> void:
	_clear_container(_stats_box)
	var rows := [
		{
			"icon": "HP",
			"name": "最大体力",
			"old": int(round(float(old_stats.get("max_energy", 0)))),
			"new": int(round(float(new_stats.get("max_energy", 0)))),
			"fmt": "%d",
			"color": Palette.GAUGE_RED_HI,
		},
		{
			"icon": "PWR",
			"name": "巻力",
			"old": float(old_stats.get("reel_power", 0)),
			"new": float(new_stats.get("reel_power", 0)),
			"fmt": "%.1f",
			"color": Palette.GAUGE_CYAN_HI,
		},
		{
			"icon": "TEC",
			"name": "技量",
			"old": int(old_stats.get("technique", 0)),
			"new": int(new_stats.get("technique", 0)),
			"fmt": "%d",
			"color": Palette.GOLD_BRIGHT,
		},
		{
			"icon": "FOC",
			"name": "集中力",
			"old": int(old_stats.get("focus", 0)),
			"new": int(new_stats.get("focus", 0)),
			"fmt": "%d",
			"color": Color("#d9b7ff"),
		},
	]
	for row in rows:
		_stats_box.add_child(_stat_row(row))


func _stat_row(row: Dictionary) -> PanelContainer:
	var old_value = row["old"]
	var new_value = row["new"]
	var delta := float(new_value) - float(old_value)
	var panel := _panel_box(Color("#17324d"), Color("#07121e"), Palette.GOLD_DEEP, 3)
	panel.custom_minimum_size = Vector2(0.0, 48.0)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 12)
	panel.add_child(line)

	var icon := _badge_box(String(row["icon"]), row["color"], Palette.TEXT_BONE)
	icon.custom_minimum_size = Vector2(46.0, 0.0)
	line.add_child(icon)

	var name := make_label(String(row["name"]), 20, Palette.TEXT_BONE, 2)
	name.custom_minimum_size = Vector2(150.0, 0.0)
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(name)

	var fmt := String(row["fmt"])
	var old_text := fmt % old_value
	var new_text := fmt % new_value
	var values := make_shadow_label("%s  ->  %s" % [old_text, new_text], 24, Palette.TEXT_BONE, 3)
	values.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	values.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	values.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(values)

	var gain_text := "%.1f" % delta if fmt == "%.1f" else "%d" % int(round(delta))
	var gain := make_shadow_label("+%s" % gain_text, 22, Palette.GAUGE_GREEN_HI, 3)
	if absf(delta) < 0.01:
		gain.text = "-"
	gain.custom_minimum_size = Vector2(100.0, 0.0)
	gain.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	gain.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(gain)
	return panel


func _badge_box(text: String, fill: Color, text_color: Color) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override(
		"panel",
		_style_box(fill.darkened(0.18), Color("#07121e"), Palette.GOLD_BRIGHT, 2, 4)
	)
	var label := make_shadow_label(text, 17, text_color, 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	badge.add_child(label)
	return badge


func _add_burst_layer() -> void:
	var burst := Control.new()
	burst.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(burst)
	burst.draw.connect(
		func() -> void:
			var center := burst.size * 0.5
			for i in range(28):
				var a := TAU * float(i) / 28.0
				var inner := center + Vector2(cos(a), sin(a)) * 185.0
				var outer := center + Vector2(cos(a), sin(a)) * 360.0
				var color := Palette.GOLD_BRIGHT
				color.a = 0.18 if i % 2 == 0 else 0.08
				burst.draw_line(inner, outer, color, 4.0)
	)
	burst.queue_redraw()


func _present() -> void:
	_dialog.modulate.a = 0.0
	_dialog.scale = Vector2(0.82, 0.82)
	await get_tree().process_frame
	_dialog.pivot_offset = _dialog.size * 0.5
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(_dialog, "scale", Vector2.ONE, 0.34)
	tw.parallel().tween_property(_dialog, "modulate:a", 1.0, 0.18)
	Juicer.add_trauma(0.45)
	Juicer.hit_stop(0.05)


func _close() -> void:
	closed.emit()
	_dialog.pivot_offset = _dialog.size * 0.5
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(_dialog, "scale", Vector2(0.86, 0.86), 0.16)
	tw.parallel().tween_property(_dialog, "modulate:a", 0.0, 0.16)
	tw.tween_callback(queue_free)


func _clear_container(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


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
	sb.expand_margin_left = 7.0
	sb.expand_margin_top = 7.0
	sb.expand_margin_right = 7.0
	sb.expand_margin_bottom = 7.0
	sb.content_margin_left = content_x
	sb.content_margin_top = content_y
	sb.content_margin_right = content_x
	sb.content_margin_bottom = content_y
	return sb
