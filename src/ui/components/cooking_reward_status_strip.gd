extends HBoxContainer
## 調理報酬パネル下部のステータスストリップ（Lv/効果中の料理/クーラー/所持金）

const GaugeBarScript = preload("res://src/ui/components/gauge_bar.gd")

var _secondary := false
var _status_level_label: Label
var _status_level_exp_label: Label
var _status_level_bar: GaugeBar
var _status_meal_label: Label
var _status_meal_icon: TextureRect
var _status_cooler_label: Label
var _status_money_label: Label


func _init() -> void:
	name = "RewardStatusStrip"
	custom_minimum_size = Vector2(0.0, 62.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 7)

	_status_level_label = _status_strip_card(self, "RewardStatusLevelCard", "プレイヤーLv.", Palette.GOLD_BRIGHT, "level")
	_status_meal_label = _status_strip_card(self, "RewardStatusMealCard", "効果中の料理", Palette.GAUGE_GREEN_HI, "meal")
	_status_cooler_label = _status_strip_card(self, "RewardStatusCoolerCard", "クーラーボックス", Palette.GAUGE_CYAN_HI, "cooler")
	_status_money_label = _status_strip_card(self, "RewardStatusMoneyCard", "所持金", Palette.GOLD_BRIGHT, "money")
	var meal_card := CookingAssets.card_from_label(_status_meal_label)
	if meal_card != null:
		meal_card.custom_minimum_size = Vector2(340.0, 50.0)


func _draw() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var rect := Rect2(Vector2(0.0, 2.0), Vector2(size.x, size.y - 4.0))
	var base_alpha := 0.15 if _secondary else 0.09
	draw_rect(rect, Color(Palette.COOKING_REWARD_DARK_BACKDROP, base_alpha))
	var top_alpha := 0.13 if _secondary else 0.18
	draw_line(
		Vector2(20.0, 5.0),
		Vector2(size.x - 20.0, 5.0),
		Color(Palette.COOKING_REWARD_ACCENT_BONUS, top_alpha),
		2.0
	)
	if _secondary:
		draw_line(
			Vector2(34.0, size.y - 5.0),
			Vector2(size.x - 34.0, size.y - 5.0),
			Color(Palette.COOKING_REWARD_CARD_FRAME_BORDER, 0.30),
			2.0
		)


func set_secondary(value: bool) -> void:
	_secondary = value
	queue_redraw()
	for label in [_status_level_label, _status_meal_label, _status_cooler_label, _status_money_label]:
		var card := CookingAssets.card_from_label(label)
		if card != null:
			card.queue_redraw()


func set_emphasis(is_primary: bool) -> void:
	var tint := Color.WHITE if is_primary else Palette.COOKING_REWARD_STATUS_SECONDARY_TINT
	custom_minimum_size = Vector2(0.0, 62.0 if is_primary else 56.0)
	queue_redraw()
	for label in [_status_level_label, _status_meal_label, _status_cooler_label, _status_money_label]:
		var card := CookingAssets.card_from_label(label)
		if card == null:
			continue
		card.custom_minimum_size = Vector2(card.custom_minimum_size.x, 58.0 if is_primary else 52.0)
		card.modulate = tint
		card.queue_redraw()


func refresh(result: Dictionary) -> void:
	if _status_level_label == null:
		return
	var snapshot := Dictionary(result.get("status_snapshot", {}))
	var level := int(snapshot.get("level", PlayerProgress.level))
	var exp := int(snapshot.get("exp", PlayerProgress.exp))
	var next_exp := int(snapshot.get("exp_max", PlayerProgress.exp_to_next_level()))
	var fish_total := int(snapshot.get("fish_total", _total_fish_count()))
	var money := int(snapshot.get("money", PlayerProgress.money))
	_status_level_label.text = "Lv.%d" % level
	if _status_level_exp_label != null:
		_status_level_exp_label.text = "%d/%d" % [
			exp,
			next_exp,
		]
	if _status_level_bar != null:
		_status_level_bar.max_value = maxf(1.0, float(next_exp))
		_status_level_bar.set_value(clampf(float(exp), 0.0, _status_level_bar.max_value))
	var buff := Dictionary(result.get("buff", {}))
	if _status_meal_icon != null:
		_status_meal_icon.texture = CookingAssets.featured_dish_texture_or_icon(String(buff.get("recipe_id", "salt_grill")))
	_status_meal_label.text = "%s / あと1回" % String(buff.get("name", result.get("dish_name", "料理")))
	_status_cooler_label.text = "%d / 20" % fish_total
	_status_money_label.text = "%s G" % _format_number(money)


func _status_strip_card(
	parent: HBoxContainer, card_name: String, title: String, accent: Color, icon_mode: String
) -> Label:
	var card := PanelContainer.new()
	card.name = card_name
	card.add_theme_stylebox_override(
		"panel",
		CookingAssets.texture_style_box(
			CookingAssets.REWARD_CARD_FRAME,
			24,
			CookingAssets.compact_style_box(
				Palette.COOKING_REWARD_CARD_FRAME_FILL,
				Palette.COOKING_REWARD_CARD_FRAME_BORDER,
				Palette.GOLD_DEEP,
				3,
				4
			),
			8.0,
			5.0
		)
	)
	card.custom_minimum_size = Vector2(_status_card_min_width(icon_mode), 58.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.draw.connect(func() -> void: _draw_status_card_backdrop(card, icon_mode, accent))
	parent.add_child(card)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 6)
	card.add_child(row)

	var icon_shell := _status_icon_shell(icon_mode, accent)
	row.add_child(icon_shell)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 2)
	row.add_child(text_box)

	var title_label := ScreenBase.make_shadow_label(title, 12, Palette.TEXT_BONE, 1)
	title_label.custom_minimum_size = Vector2(0.0, 14.0)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_label.clip_text = true
	text_box.add_child(title_label)

	var value := ScreenBase.make_shadow_label("", _status_value_font_size(icon_mode), accent, 2)
	value.custom_minimum_size = Vector2(0.0, _status_value_height(icon_mode))
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.autowrap_mode = TextServer.AUTOWRAP_OFF
	value.clip_text = true
	text_box.add_child(value)

	if icon_mode == "level":
		var exp_row := HBoxContainer.new()
		exp_row.name = "RewardStatusLevelExpRow"
		exp_row.add_theme_constant_override("separation", 5)
		exp_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_box.add_child(exp_row)
		_status_level_bar = GaugeBarScript.new()
		_status_level_bar.name = "RewardStatusLevelExpBar"
		_status_level_bar.show_value = false
		_status_level_bar.critical_threshold = 0.0
		_status_level_bar.custom_minimum_size = Vector2(84.0, 9.0)
		_status_level_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_status_level_bar.set_colors(Palette.GAUGE_CYAN, Palette.GAUGE_CYAN_HI)
		exp_row.add_child(_status_level_bar)
		_status_level_exp_label = ScreenBase.make_shadow_label("", 11, Palette.TEXT_BONE, 1)
		_status_level_exp_label.name = "RewardStatusLevelExpText"
		_status_level_exp_label.custom_minimum_size = Vector2(76.0, 0.0)
		_status_level_exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_status_level_exp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_status_level_exp_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		_status_level_exp_label.clip_text = true
		exp_row.add_child(_status_level_exp_label)

	return value


func _status_icon_shell(icon_mode: String, accent: Color) -> PanelContainer:
	var shell := CookingAssets.compact_panel_box(
		Palette.COOKING_REWARD_ICON_SHELL_FILL,
		Palette.COOKING_REWARD_ICON_SHELL_BORDER,
		accent,
		2
	)
	shell.custom_minimum_size = Vector2(54.0, 0.0)
	shell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var icon := TextureRect.new()
	icon.name = _status_icon_node_name(icon_mode)
	icon.texture = _status_icon_texture(icon_mode)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell.add_child(icon)
	if icon_mode == "meal":
		_status_meal_icon = icon
	return shell


func _status_card_min_width(icon_mode: String) -> float:
	match icon_mode:
		"level":
			return 250.0
		"meal":
			return 340.0
		"cooler":
			return 252.0
		"money":
			return 236.0
		_:
			return 220.0


func _status_value_font_size(icon_mode: String) -> int:
	match icon_mode:
		"level":
			return 24
		"meal":
			return 16
		"cooler":
			return 22
		"money":
			return 22
		_:
			return 19


func _status_value_height(icon_mode: String) -> float:
	match icon_mode:
		"level":
			return 24.0
		"meal":
			return 20.0
		_:
			return 25.0


func _status_icon_node_name(icon_mode: String) -> String:
	match icon_mode:
		"level":
			return "RewardStatusLevelIcon"
		"meal":
			return "RewardStatusMealIcon"
		"cooler":
			return "RewardStatusCoolerIcon"
		"money":
			return "RewardStatusMoneyIcon"
		_:
			return "RewardStatusIcon"


func _status_icon_texture(icon_mode: String) -> Texture2D:
	match icon_mode:
		"level":
			return load(CookingAssets.PLAYER_STATUS_PORTRAIT) as Texture2D
		"meal":
			return load(CookingAssets.DISH_FEATURE_AJI) as Texture2D
		"cooler":
			return load(CookingAssets.STATUS_COOLER_ART) as Texture2D
		"money":
			return load(CookingAssets.STATUS_MONEY_ART) as Texture2D
		_:
			return null


func _draw_status_card_backdrop(card: Control, icon_mode: String, accent: Color) -> void:
	var rect := Rect2(Vector2.ZERO, card.size)
	var alpha_scale := 0.52 if _secondary else 1.0
	var glow := accent
	glow.a = 0.10 * alpha_scale
	card.draw_rect(Rect2(Vector2(10.0, rect.size.y - 15.0), Vector2(rect.size.x - 20.0, 5.0)), glow)
	var shine := Color(Palette.COOKING_REWARD_SHINE, 0.11 * alpha_scale)
	card.draw_line(Vector2(14.0, 12.0), Vector2(rect.size.x - 18.0, 8.0), shine, 2.0)
	if not _secondary:
		for i in range(3):
			var p := Vector2(rect.size.x * (0.55 + float(i) * 0.14), 13.0 + float(i % 2) * 21.0)
			var sparkle := accent
			sparkle.a = 0.30
			card.draw_line(p + Vector2(-3.0, 0.0), p + Vector2(3.0, 0.0), sparkle, 1.4)
			card.draw_line(p + Vector2(0.0, -3.0), p + Vector2(0.0, 3.0), sparkle, 1.4)
	if icon_mode == "money":
		for i in range(3):
			var x := rect.size.x - 34.0 + float(i) * 7.0
			card.draw_circle(
				Vector2(x, rect.size.y - 15.0),
				5.0,
				Color(Palette.COOKING_REWARD_MONEY_COIN, 0.28 * alpha_scale)
			)
	elif icon_mode == "cooler":
		card.draw_rect(
			Rect2(rect.size.x - 50.0, rect.size.y - 18.0, 34.0, 5.0),
			Color(Palette.COOKING_REWARD_ACCENT_EXP, 0.18 * alpha_scale)
		)
	elif icon_mode == "meal":
		card.draw_arc(
			Vector2(rect.size.x - 32.0, rect.size.y - 13.0),
			13.0,
			0.0,
			PI,
			16,
			Color(Palette.TEXT_BONE, 0.28 * alpha_scale),
			3.0
		)
	else:
		card.draw_circle(
			Vector2(rect.size.x - 30.0, rect.size.y - 15.0),
			8.0,
			Color(Palette.COOKING_REWARD_ACCENT_EXP, 0.16 * alpha_scale)
		)


func _total_fish_count() -> int:
	var total := 0
	for fish_id in GameData.get_all_fish_ids():
		total += PlayerProgress.fish_count(fish_id)
	return total


func _format_number(value: int) -> String:
	var raw := str(value)
	var result := ""
	var count := 0
	for index in range(raw.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = raw[index] + result
		count += 1
	return result
