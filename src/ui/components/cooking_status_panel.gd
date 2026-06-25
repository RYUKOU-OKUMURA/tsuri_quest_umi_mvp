extends "res://src/ui/screen_base.gd"
## 調理フローの STATUS_SUMMARY。
# 調理中に、成長・食事効果・所持状況をカードで確認するための要約オーバーレイ。
signal closed

const GaugeBarScript = preload("res://src/ui/components/gauge_bar.gd")
const STATUS_CARD_FRAME := "res://assets/showcase/cooking/status_card_frame.png"
const DISH_FEATURE_AJI := "res://assets/showcase/cooking/dish_feature_aji_shioyaki.png"
const DISH_ICON_SHEET := "res://assets/showcase/cooking/dish_icon_sheet.png"

var _dialog: PanelContainer
var _exp_bar: GaugeBar
var _exp_label: Label
var _stats_grid: GridContainer
var _meal_image: TextureRect
var _meal_label: Label
var _cooler_label: Label
var _money_label: Label
var _play_label: Label


func _build_screen() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.48)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_dialog = PanelContainer.new()
	_dialog.custom_minimum_size = Vector2(900.0, 0.0)
	_dialog.add_theme_stylebox_override(
		"panel", _style_box(Color("#f2e4c2"), Color("#5e391a"), Palette.GOLD_BRIGHT, 6, 8)
	)
	center.add_child(_dialog)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	_dialog.add_child(root)

	var title := make_label("ステータス要約", 32, Color("#2a2118"), 1, Color("#fff4d4"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	root.add_child(top)

	var player_card := _panel_box(Color("#10283f"), Color("#07121e"), Palette.GOLD_DEEP, 4)
	player_card.custom_minimum_size = Vector2(360.0, 154.0)
	top.add_child(player_card)
	var player_box := VBoxContainer.new()
	player_box.add_theme_constant_override("separation", 8)
	player_card.add_child(player_box)
	_exp_label = make_shadow_label("", 27, Palette.TEXT_BONE, 3)
	_exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_box.add_child(_exp_label)
	_exp_bar = GaugeBarScript.new()
	_exp_bar.show_value = false
	_exp_bar.custom_minimum_size = Vector2(0.0, 32.0)
	_exp_bar.set_colors(Palette.GAUGE_CYAN, Palette.GAUGE_CYAN_HI)
	player_box.add_child(_exp_bar)
	var rod := make_label("", 18, Palette.TEXT_BONE, 2)
	rod.name = "RodLabel"
	rod.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_box.add_child(rod)

	_stats_grid = GridContainer.new()
	_stats_grid.columns = 2
	_stats_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stats_grid.add_theme_constant_override("h_separation", 8)
	_stats_grid.add_theme_constant_override("v_separation", 8)
	top.add_child(_stats_grid)

	var bottom := GridContainer.new()
	bottom.columns = 2
	bottom.add_theme_constant_override("h_separation", 10)
	bottom.add_theme_constant_override("v_separation", 10)
	root.add_child(bottom)
	_meal_label = _meal_card(bottom)
	_cooler_label = _summary_card(bottom, "クーラーボックス", Palette.GAUGE_CYAN_HI)
	_money_label = _summary_card(bottom, "所持金", Palette.GOLD_BRIGHT)
	_play_label = _summary_card(bottom, "プレイ時間", Palette.TEXT_BONE)

	var ok := make_button("閉じる", _close, 240.0, true)
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(ok)


func show_summary() -> void:
	var stats := PlayerProgress.get_base_stats()
	_exp_label.text = "プレイヤー Lv.%d" % PlayerProgress.level
	if PlayerProgress.level >= GameData.MAX_LEVEL:
		_exp_bar.max_value = 1.0
		_exp_bar.set_value(1.0)
	else:
		_exp_bar.max_value = maxf(1.0, float(PlayerProgress.exp_to_next_level()))
		_exp_bar.set_value(float(PlayerProgress.exp))
	var rod_label := _dialog.find_child("RodLabel", true, false) as Label
	if rod_label != null:
		rod_label.text = "装備中：%s" % String(stats.get("rod_name", "港の入門竿"))

	_clear_container(_stats_grid)
	_stats_grid.add_child(_stat_card("最大体力", "%d" % int(round(float(stats.get("max_energy", 0)))), Palette.GAUGE_RED_HI))
	_stats_grid.add_child(_stat_card("巻力", "%.1f" % float(stats.get("reel_power", 0)), Palette.GAUGE_CYAN_HI))
	_stats_grid.add_child(_stat_card("技量", "%d" % int(stats.get("technique", 0)), Palette.GOLD_BRIGHT))
	_stats_grid.add_child(_stat_card("集中力", "%d" % int(stats.get("focus", 0)), Color("#d9b7ff")))

	if PlayerProgress.pending_buff.is_empty():
		_meal_image.texture = null
		_meal_label.text = "なし\n次の料理で準備"
	else:
		_meal_image.texture = _meal_texture(String(PlayerProgress.pending_buff.get("recipe_id", "")))
		_meal_label.text = "%s\n%s" % [
			String(PlayerProgress.pending_buff.get("name", "料理")),
			String(PlayerProgress.pending_buff.get("text", "")),
		]
	_cooler_label.text = "%d 匹 / %d 種" % [_total_fish_count(), _owned_fish_kinds()]
	_money_label.text = "%d G" % PlayerProgress.money
	_play_label.text = format_play_time(PlayerProgress.play_seconds)
	_present()


func _meal_card(parent: GridContainer) -> Label:
	var card := _texture_panel_box(
		STATUS_CARD_FRAME,
		24,
		_style_box(Color("#10283f"), Color("#07121e"), Palette.GOLD_DEEP, 4, 5),
		16.0,
		10.0
	)
	card.custom_minimum_size = Vector2(420.0, 86.0)
	parent.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	_meal_image = TextureRect.new()
	_meal_image.custom_minimum_size = Vector2(102.0, 60.0)
	_meal_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_meal_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(_meal_image)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 2)
	row.add_child(box)
	var title_label := make_shadow_label("効果中の料理", 17, Palette.GOLD_BRIGHT, 2)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title_label)
	var value := make_label("", 18, Palette.GAUGE_GREEN_HI, 2)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(value)
	return value


func _summary_card(parent: GridContainer, title: String, accent: Color) -> Label:
	var card := _texture_panel_box(
		STATUS_CARD_FRAME,
		24,
		_style_box(Color("#10283f"), Color("#07121e"), Palette.GOLD_DEEP, 4, 5),
		16.0,
		10.0
	)
	card.custom_minimum_size = Vector2(420.0, 86.0)
	parent.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	card.add_child(box)
	var title_label := make_shadow_label(title, 17, Palette.GOLD_BRIGHT, 2)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title_label)
	var value := make_label("", 20, accent, 2)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(value)
	return value


func _stat_card(title: String, value: String, accent: Color) -> PanelContainer:
	var card := _texture_panel_box(
		STATUS_CARD_FRAME,
		24,
		_style_box(Color("#f8edcf"), Color("#60401f"), Color("#d7a456"), 4, 5),
		14.0,
		8.0
	)
	card.custom_minimum_size = Vector2(250.0, 70.0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	card.add_child(box)
	var name := make_label(title, 15, Color("#60411f"))
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(name)
	var amount := make_label(value, 25, accent, 1, Color("#1d160f"))
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(amount)
	return card


func _present() -> void:
	_dialog.modulate.a = 0.0
	_dialog.scale = Vector2(0.9, 0.9)
	await get_tree().process_frame
	_dialog.pivot_offset = _dialog.size * 0.5
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(_dialog, "scale", Vector2.ONE, 0.24)
	tw.parallel().tween_property(_dialog, "modulate:a", 1.0, 0.14)


func _close() -> void:
	closed.emit()
	_dialog.pivot_offset = _dialog.size * 0.5
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(_dialog, "scale", Vector2(0.9, 0.9), 0.12)
	tw.parallel().tween_property(_dialog, "modulate:a", 0.0, 0.12)
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
