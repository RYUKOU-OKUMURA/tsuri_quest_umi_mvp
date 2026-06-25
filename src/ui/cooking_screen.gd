extends "res://src/ui/screen_base.gd"

const GaugeBarScript = preload("res://src/ui/components/gauge_bar.gd")
const LevelUpPanelScript = preload("res://src/ui/components/level_up_panel.gd")
const CookingRewardPanelScript = preload("res://src/ui/components/cooking_reward_panel.gd")
const CookingStatusPanelScript = preload("res://src/ui/components/cooking_status_panel.gd")

const COOKING_BG := "res://assets/showcase/cooking/cooking_room_bg.png"
const FISH_ICON_SHEET := "res://assets/showcase/cooking/fish_icon_sheet.png"
const DISH_ICON_SHEET := "res://assets/showcase/cooking/dish_icon_sheet.png"
const DISH_FEATURE_AJI := "res://assets/showcase/cooking/dish_feature_aji_shioyaki.png"

const FISH_ICON_INDEX := {
	"aji": 0,
	"mejina": 1,
	"kasago": 2,
	"isaki": 3,
	"saba": 4,
	"boss_kurodai": 5,
}

const RECIPE_ICON_INDEX := {
	"salt_grill": 0,
	"sashimi": 1,
	"simmered": 2,
	"soup": 3,
	"fry": 4,
}

enum FlowState { COOK_SELECT, MEAL_RESULT, EXP_GAIN }

var _flow_state := FlowState.COOK_SELECT
var _selected_fish_id: String = ""
var _selected_recipe_id: String = ""
var _preview_suppress_level_overlay := false

var _level_label: Label
var _money_label: Label
var _exp_bar: GaugeBar
var _exp_label: Label
var _fish_box: VBoxContainer
var _recipe_grid: GridContainer
var _dish_title: Label
var _dish_subtitle: Label
var _dish_image: TextureRect
var _material_value: Label
var _exp_value: Label
var _buff_value: Label
var _stock_value: Label
var _overwrite_note: Label
var _cook_button: Button
var _result_title: Label
var _result_body: HBoxContainer
var _status_button: Button

var _fish_cards: Dictionary = {}
var _recipe_cards: Dictionary = {}
var _pending_level_up: Dictionary = {}


func configure(payload: Dictionary) -> void:
	super.configure(payload)
	_preview_suppress_level_overlay = bool(payload.get("suppress_level_overlay", false))


func _build_screen() -> void:
	_add_cooking_background()
	var root := make_root_margin(10)
	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 8)
	root.add_child(layout)

	_build_header(layout)
	_build_cook_select(layout)
	_build_result_summary(layout)

	_refresh_all()
	_show_status_summary()


func _add_cooking_background() -> void:
	var bg_tex := load(COOKING_BG) as Texture2D
	if bg_tex != null:
		var bg := TextureRect.new()
		bg.texture = bg_tex
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
		move_child(bg, 0)
	else:
		add_gradient_background(Color("#2a2418"), Color("#14110b"))

	var glaze := ColorRect.new()
	glaze.color = Color(0.03, 0.06, 0.10, 0.34)
	glaze.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glaze.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glaze)
	move_child(glaze, 1)


func _build_header(layout: VBoxContainer) -> void:
	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 64)
	header.add_theme_constant_override("separation", 8)
	layout.add_child(header)

	var title_card := _panel_box(Color("#25170e"), Color("#70451f"), Color("#f0c06b"), 6)
	title_card.custom_minimum_size = Vector2(278, 0)
	header.add_child(title_card)
	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", 10)
	title_card.add_child(title_row)
	var title := make_shadow_label("調理場", 30, Palette.GOLD_BRIGHT, 4)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_row.add_child(title)

	var status_card := _panel_box(Color("#0d2338"), Color("#70451f"), Color("#dba75b"), 6)
	status_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(status_card)
	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 12)
	status_card.add_child(status_row)
	_level_label = make_shadow_label("", 21, Palette.TEXT_BONE, 3)
	_level_label.custom_minimum_size = Vector2(158, 0)
	status_row.add_child(_level_label)
	_exp_bar = GaugeBarScript.new()
	_exp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_exp_bar.show_value = false
	_exp_bar.custom_minimum_size = Vector2(0, 24)
	_exp_bar.set_colors(Palette.GAUGE_CYAN, Palette.GAUGE_CYAN_HI)
	status_row.add_child(_exp_bar)
	_exp_label = make_shadow_label("", 17, Palette.TEXT_BONE, 2)
	_exp_label.custom_minimum_size = Vector2(126, 0)
	_exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_row.add_child(_exp_label)

	var money_card := _panel_box(Color("#0d2338"), Color("#70451f"), Color("#dba75b"), 6)
	money_card.custom_minimum_size = Vector2(210, 0)
	header.add_child(money_card)
	_money_label = make_shadow_label("", 22, Palette.GOLD_BRIGHT, 3)
	_money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_money_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	money_card.add_child(_money_label)

	var back := make_button("港へ", func() -> void: navigate("harbor"), 96, false)
	back.custom_minimum_size = Vector2(90, 52)
	header.add_child(back)


func _build_cook_select(layout: VBoxContainer) -> void:
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	layout.add_child(body)

	var fish_panel := _panel_box(Color("#10283d"), Color("#5e391a"), Color("#e4b461"), 6)
	fish_panel.custom_minimum_size = Vector2(276, 0)
	fish_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(fish_panel)
	var fish_layout := VBoxContainer.new()
	fish_layout.add_theme_constant_override("separation", 6)
	fish_panel.add_child(fish_layout)
	var fish_title := make_shadow_label("所持している魚", 22, Palette.TEXT_BONE, 3)
	fish_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fish_layout.add_child(fish_title)
	_fish_box = VBoxContainer.new()
	_fish_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_fish_box.add_theme_constant_override("separation", 6)
	fish_layout.add_child(_fish_box)

	var recipe_panel := _panel_box(Color("#ead9b2"), Color("#5e391a"), Color("#e6b561"), 6)
	recipe_panel.custom_minimum_size = Vector2(420, 0)
	recipe_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(recipe_panel)
	var recipe_layout := VBoxContainer.new()
	recipe_layout.add_theme_constant_override("separation", 6)
	recipe_panel.add_child(recipe_layout)
	var recipe_title := make_label("料理を選ぶ", 23, Color("#2e2419"), 1, Color("#fff3ce"))
	recipe_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	recipe_layout.add_child(recipe_title)
	_recipe_grid = GridContainer.new()
	_recipe_grid.columns = 2
	_recipe_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_recipe_grid.add_theme_constant_override("h_separation", 7)
	_recipe_grid.add_theme_constant_override("v_separation", 7)
	recipe_layout.add_child(_recipe_grid)

	var detail_panel := _panel_box(Color("#f4e7c8"), Color("#5e391a"), Color("#e6b561"), 6)
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(detail_panel)
	var detail_layout := VBoxContainer.new()
	detail_layout.add_theme_constant_override("separation", 6)
	detail_panel.add_child(detail_layout)
	_dish_title = make_label("料理を選んでください", 25, Color("#2a2118"), 1, Color("#fff4d4"))
	_dish_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_layout.add_child(_dish_title)
	_dish_subtitle = make_label("", 15, Color("#59422b"))
	_dish_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_layout.add_child(_dish_subtitle)
	_dish_image = TextureRect.new()
	_dish_image.custom_minimum_size = Vector2(0, 142)
	_dish_image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dish_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dish_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail_layout.add_child(_dish_image)
	var detail_grid := GridContainer.new()
	detail_grid.columns = 2
	detail_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_grid.add_theme_constant_override("h_separation", 6)
	detail_grid.add_theme_constant_override("v_separation", 6)
	detail_layout.add_child(detail_grid)
	_material_value = _add_detail_tile(detail_grid, "材料", "")
	_stock_value = _add_detail_tile(detail_grid, "所持数", "")
	_exp_value = _add_detail_tile(detail_grid, "食経験値", "")
	_buff_value = _add_detail_tile(detail_grid, "食事効果", "")
	_overwrite_note = make_label("", 13, Color("#624b31"))
	_overwrite_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_overwrite_note.clip_text = true
	_overwrite_note.custom_minimum_size = Vector2(0, 18)
	detail_layout.add_child(_overwrite_note)
	_cook_button = make_button("調理する", _cook_selected, 300, true)
	_cook_button.custom_minimum_size = Vector2(286, 50)
	_cook_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	detail_layout.add_child(_cook_button)


func _build_result_summary(layout: VBoxContainer) -> void:
	var result_panel := _panel_box(Color("#0f2338"), Color("#5e391a"), Color("#e3b15e"), 6)
	result_panel.custom_minimum_size = Vector2(0, 94)
	layout.add_child(result_panel)
	var result_layout := VBoxContainer.new()
	result_layout.add_theme_constant_override("separation", 4)
	result_panel.add_child(result_layout)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 10)
	result_layout.add_child(title_row)
	_result_title = make_shadow_label("", 18, Palette.GOLD_BRIGHT, 3)
	_result_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_row.add_child(_result_title)
	_status_button = make_button("詳細", _show_status_overlay, 100, false)
	_status_button.custom_minimum_size = Vector2(92, 34)
	title_row.add_child(_status_button)
	_result_body = HBoxContainer.new()
	_result_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_result_body.add_theme_constant_override("separation", 6)
	result_layout.add_child(_result_body)


func _add_detail_tile(parent: GridContainer, title: String, value: String) -> Label:
	var tile := _panel_box(Color("#fff0cf"), Color("#8b5b2c"), Color("#e6b561"), 3)
	tile.custom_minimum_size = Vector2(0, 58)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(tile)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	tile.add_child(box)
	var title_label := make_label(title, 13, Color("#6a4a2b"))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title_label)
	var value_label := make_label(value, 17, Color("#2a2118"), 1, Color("#fff2cf"))
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.clip_text = true
	box.add_child(value_label)
	return value_label


func _refresh_all() -> void:
	_refresh_header()
	_rebuild_fish_cards()


func _refresh_header() -> void:
	_level_label.text = "プレイヤー Lv.%d" % PlayerProgress.level
	_money_label.text = "%d G" % PlayerProgress.money
	if PlayerProgress.level >= GameData.MAX_LEVEL:
		_exp_bar.max_value = 1.0
		_exp_bar.set_value(1.0)
		_exp_label.text = "MAX"
	else:
		var next := PlayerProgress.exp_to_next_level()
		_exp_bar.max_value = maxf(1.0, float(next))
		_exp_bar.set_value(float(PlayerProgress.exp))
		_exp_label.text = "%d / %d" % [PlayerProgress.exp, next]


func _rebuild_fish_cards() -> void:
	_clear_container(_fish_box)
	_fish_cards.clear()
	var first_id := ""
	for fish_id in GameData.get_all_fish_ids():
		var count := PlayerProgress.fish_count(fish_id)
		if count <= 0:
			continue
		if first_id.is_empty():
			first_id = fish_id
		_fish_box.add_child(_make_fish_card(fish_id, count))
	if first_id.is_empty():
		_selected_fish_id = ""
		_selected_recipe_id = ""
		_rebuild_recipe_cards()
		_refresh_detail()
		return
	if _selected_fish_id.is_empty() or PlayerProgress.fish_count(_selected_fish_id) <= 0:
		_selected_fish_id = first_id
	_rebuild_recipe_cards()
	_refresh_fish_card_styles()


func _make_fish_card(fish_id: String, count: int) -> PanelContainer:
	var fish := GameData.get_fish(fish_id)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 56)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.gui_input.connect(
		func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				_select_fish(fish_id)
	)
	_fish_cards[fish_id] = card
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)
	var icon := TextureRect.new()
	icon.texture = _fish_icon(fish_id)
	icon.custom_minimum_size = Vector2(74, 40)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var name := make_label(String(fish.get("name", fish_id)), 18, Color("#241b12"), 1, Color("#fff2ca"))
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(name)
	var amount := make_label("× %d" % count, 18, Color("#241b12"), 1, Color("#fff2ca"))
	amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(amount)
	return card


func _select_fish(fish_id: String) -> void:
	if _selected_fish_id == fish_id:
		return
	_selected_fish_id = fish_id
	_selected_recipe_id = ""
	_rebuild_recipe_cards()
	_refresh_fish_card_styles()
	_show_status_summary()


func _refresh_fish_card_styles() -> void:
	for fish_id in _fish_cards.keys():
		var selected := String(fish_id) == _selected_fish_id
		var card := _fish_cards[fish_id] as PanelContainer
		if card != null:
			card.add_theme_stylebox_override(
				"panel",
				_style_box(
					Color("#ffefbd") if selected else Color("#ead9b4"),
					Color("#f4c96e") if selected else Color("#6a421f"),
					Color("#ffffff") if selected else Color("#c29250"),
					4,
					6
				)
			)


func _rebuild_recipe_cards() -> void:
	_clear_container(_recipe_grid)
	_recipe_cards.clear()
	if _selected_fish_id.is_empty():
		return
	var entries := _recipe_entries_for_fish(_selected_fish_id)
	var first_available := ""
	var selected_available := false
	for entry in entries:
		var recipe := Dictionary(entry.get("recipe", {}))
		var recipe_id := String(recipe.get("id", ""))
		var locked := bool(entry.get("locked", false))
		if first_available.is_empty() and not locked:
			first_available = recipe_id
		if recipe_id == _selected_recipe_id and not locked:
			selected_available = true
		_recipe_grid.add_child(_make_recipe_card(recipe, locked))
	if _selected_recipe_id.is_empty() or not selected_available:
		_selected_recipe_id = first_available
	_refresh_recipe_card_styles()
	_refresh_detail()


func _recipe_entries_for_fish(fish_id: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for recipe_id_variant in GameData.RECIPES.keys():
		var recipe_id := String(recipe_id_variant)
		var recipe := GameData.get_recipe(recipe_id)
		var allowed = recipe.get("allowed_fish", [])
		if fish_id not in allowed:
			continue
		entries.append(
			{
				"recipe": recipe,
				"locked": PlayerProgress.level < int(recipe.get("unlock_level", 1)),
			}
		)
	entries.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return int(Dictionary(a.get("recipe", {})).get("unlock_level", 1)) < int(Dictionary(b.get("recipe", {})).get("unlock_level", 1))
	)
	return entries


func _make_recipe_card(recipe: Dictionary, locked: bool) -> PanelContainer:
	var recipe_id := String(recipe.get("id", ""))
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(198, 108)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	if not locked:
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		card.gui_input.connect(
			func(event: InputEvent) -> void:
				if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					_select_recipe(recipe_id)
		)
	_recipe_cards[recipe_id] = {"card": card, "locked": locked}

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	card.add_child(box)
	var title := make_label(String(recipe.get("name", "")), 16, Color("#251c12"), 1, Color("#fff3cf"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var image := TextureRect.new()
	image.texture = _recipe_icon(recipe_id if not locked else "locked")
	image.custom_minimum_size = Vector2(0, 48)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.modulate = Color(0.46, 0.42, 0.36, 0.82) if locked else Color.WHITE
	box.add_child(image)
	var footer_text := ""
	if locked:
		footer_text = "Lv.%dで解放" % int(recipe.get("unlock_level", 1))
	else:
		var dish_key := "%s:%s" % [_selected_fish_id, recipe_id]
		var exp_amount := GameData.recipe_exp(_selected_fish_id, recipe_id)
		footer_text = "%d EXP%s" % [
			exp_amount,
			" / 初回" if not PlayerProgress.eaten_recipes.has(dish_key) else "",
		]
	var footer := make_label(footer_text, 13, Color("#49351f"), 1, Color("#fff4cf"))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(footer)
	return card


func _select_recipe(recipe_id: String) -> void:
	if _selected_recipe_id == recipe_id:
		return
	_selected_recipe_id = recipe_id
	_refresh_recipe_card_styles()
	_refresh_detail()
	_show_status_summary()


func _refresh_recipe_card_styles() -> void:
	for recipe_id in _recipe_cards.keys():
		var entry := Dictionary(_recipe_cards[recipe_id])
		var card := entry.get("card") as PanelContainer
		var locked := bool(entry.get("locked", false))
		var selected := String(recipe_id) == _selected_recipe_id
		if card == null:
			continue
		var fill := Color("#ffedbb") if selected else Color("#ead7ad")
		if locked:
			fill = Color("#8c8069")
		card.add_theme_stylebox_override(
			"panel",
			_style_box(
				fill,
				Color("#f2c86d") if selected else Color("#7b5027"),
				Color("#fff6d4") if selected else Color("#c59a59"),
				4,
				6
			)
		)


func _refresh_detail() -> void:
	var fish := GameData.get_fish(_selected_fish_id)
	var recipe := GameData.get_recipe(_selected_recipe_id)
	if fish.is_empty() or recipe.is_empty():
		_dish_title.text = "魚と料理を選んでください"
		_dish_subtitle.text = "クーラーボックスに魚がいない場合は、先に釣り場へ向かいましょう。"
		_dish_image.texture = null
		_material_value.text = "-"
		_stock_value.text = "-"
		_exp_value.text = "-"
		_buff_value.text = "-"
		_overwrite_note.text = ""
		_cook_button.disabled = true
		return
	var base_exp := GameData.recipe_exp(_selected_fish_id, _selected_recipe_id)
	var dish_key := "%s:%s" % [_selected_fish_id, _selected_recipe_id]
	var first_time := not PlayerProgress.eaten_recipes.has(dish_key)
	var total_exp := base_exp * 2 if first_time else base_exp
	var count := PlayerProgress.fish_count(_selected_fish_id)
	_dish_title.text = "%sの%s" % [String(fish["name"]), String(recipe["name"])]
	_dish_subtitle.text = String(recipe.get("description", ""))
	_dish_image.texture = _featured_dish_texture(_selected_recipe_id)
	_material_value.text = "%s ×1" % String(fish["name"])
	_stock_value.text = "%d → %d" % [count, maxi(0, count - 1)]
	_exp_value.text = "+%d EXP%s" % [total_exp, "（初回込み）" if first_time else ""]
	_buff_value.text = String(recipe.get("buff_text", ""))
	_overwrite_note.text = "食事効果は次の釣行で発動し、既存効果を上書き。"
	_cook_button.disabled = count <= 0


func _cook_selected() -> void:
	if _selected_fish_id.is_empty() or _selected_recipe_id.is_empty():
		return
	var level_before := PlayerProgress.level
	var stats_before := PlayerProgress.get_base_stats()
	var exp_before := PlayerProgress.exp
	var exp_max_before := PlayerProgress.exp_to_next_level()
	var result := PlayerProgress.cook_and_eat(_selected_fish_id, _selected_recipe_id)
	if not bool(result.get("ok", false)):
		_show_error_result(String(result.get("message", "調理できませんでした。")))
		return

	var leveled_to: Array = result.get("leveled_to", [])
	_refresh_all()
	var leveled := not leveled_to.is_empty()
	var reward_exp_after := exp_max_before if leveled else PlayerProgress.exp
	_show_meal_result(result, leveled)
	_show_reward_overlay(
		result, exp_before, reward_exp_after, exp_max_before, level_before, stats_before, leveled
	)
	Juicer.add_trauma(0.16)


func preview_cook_selected() -> void:
	_cook_selected()


func preview_show_meal_result(result: Dictionary, leveled: bool) -> void:
	_refresh_header()
	_refresh_detail()
	_show_meal_result(result, leveled)


func preview_show_reward_result(result: Dictionary, exp_before: int, exp_after: int, exp_max: int, leveled: bool) -> void:
	_refresh_header()
	_refresh_detail()
	_show_meal_result(result, leveled)
	_show_reward_overlay(result, exp_before, exp_after, exp_max, PlayerProgress.level - 1, {}, leveled)


func preview_accept_reward_overlay() -> bool:
	for child in get_children():
		if child.get_script() == CookingRewardPanelScript:
			child.preview_accept()
			return true
	return false


func preview_has_level_up_overlay() -> bool:
	for child in get_children():
		if child.get_script() == LevelUpPanelScript:
			return true
	return false


func preview_show_status_overlay() -> void:
	_refresh_header()
	_refresh_detail()
	_show_status_summary()
	_show_status_overlay()


func _show_error_result(message: String) -> void:
	_flow_state = FlowState.MEAL_RESULT
	_result_title.text = "調理できませんでした"
	_clear_container(_result_body)
	_result_body.add_child(_summary_card("確認", message, Palette.GAUGE_RED_HI))


func _show_status_summary() -> void:
	if _flow_state != FlowState.COOK_SELECT:
		_flow_state = FlowState.COOK_SELECT
	_result_title.text = "現在の準備"
	_clear_container(_result_body)
	var active_meal := "なし"
	if not PlayerProgress.pending_buff.is_empty():
		active_meal = "%s / %s" % [
			String(PlayerProgress.pending_buff.get("name", "料理")),
			String(PlayerProgress.pending_buff.get("text", "")),
		]
	_result_body.add_child(_summary_card("効果中の料理", active_meal, Palette.GAUGE_GREEN_HI))
	_result_body.add_child(
		_summary_card("クーラーボックス", "%d 匹" % _total_fish_count(), Palette.GAUGE_CYAN_HI)
	)
	_result_body.add_child(_summary_card("所持金", "%d G" % PlayerProgress.money, Palette.GOLD_BRIGHT))
	_result_body.add_child(
		_summary_card(
			"プレイヤー",
			"Lv.%d / %s" % [PlayerProgress.level, PlayerProgress.get_base_stats().get("rod_name", "")],
			Palette.TEXT_BONE
		)
	)


func _show_status_overlay() -> void:
	var panel := CookingStatusPanelScript.new()
	add_child(panel)
	panel.show_summary()


func _show_meal_result(result: Dictionary, leveled: bool) -> void:
	_flow_state = FlowState.MEAL_RESULT if not leveled else FlowState.EXP_GAIN
	_result_title.text = "%sを食べた！" % String(result.get("dish_name", "料理"))
	_clear_container(_result_body)
	_result_body.add_child(
		_summary_card("食経験値", "+%d EXP" % int(result.get("total_exp", 0)), Palette.GAUGE_CYAN_HI)
	)
	var first_text := "+%d EXP" % int(result.get("first_bonus", 0)) if bool(result.get("first_time", false)) else "記録済み"
	_result_body.add_child(_summary_card("初回ボーナス", first_text, Palette.GOLD_BRIGHT))
	var buff := Dictionary(result.get("buff", {}))
	_result_body.add_child(_summary_card("次の釣行", String(buff.get("text", "")), Palette.GAUGE_GREEN_HI))
	var remaining_exp := maxi(0, PlayerProgress.exp_to_next_level() - PlayerProgress.exp)
	_result_body.add_child(
		_summary_card("成長", "LEVEL UP!" if leveled else "次のレベルまで %d" % remaining_exp, Palette.GAUGE_RED_HI if leveled else Palette.TEXT_BONE)
	)


func _show_reward_overlay(
	result: Dictionary,
	exp_before: int,
	exp_after: int,
	exp_max: int,
	level_before: int,
	stats_before: Dictionary,
	leveled: bool
) -> void:
	var panel := CookingRewardPanelScript.new()
	add_child(panel)
	panel.show_reward(result, exp_before, exp_after, exp_max, leveled)
	if leveled and not _preview_suppress_level_overlay:
		_pending_level_up = {
			"level_from": level_before,
			"level_to": PlayerProgress.level,
			"old_stats": stats_before,
			"new_stats": PlayerProgress.get_base_stats(),
		}
		panel.closed.connect(_show_pending_level_up)
	else:
		_pending_level_up = {}


func _show_pending_level_up() -> void:
	if _pending_level_up.is_empty():
		return
	var payload := _pending_level_up.duplicate(true)
	_pending_level_up = {}
	_show_level_up(
		int(payload.get("level_from", PlayerProgress.level)),
		int(payload.get("level_to", PlayerProgress.level)),
		Dictionary(payload.get("old_stats", {})),
		Dictionary(payload.get("new_stats", {}))
	)


func _summary_card(title: String, value: String, accent: Color) -> PanelContainer:
	var card := _panel_box(Color("#f2e4c2"), Color("#60401f"), Color("#d7a456"), 5)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 50)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	card.add_child(box)
	var title_label := make_label(title, 13, Color("#614525"))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title_label)
	var value_label := make_label(value, 16, accent, 1, Color("#1d160f"))
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(value_label)
	return card


func _show_level_up(
	level_from: int, level_to: int, old_stats: Dictionary, new_stats: Dictionary
) -> void:
	var panel := LevelUpPanelScript.new()
	add_child(panel)
	panel.show_level_up(level_from, level_to, old_stats, new_stats)


func _total_fish_count() -> int:
	var total := 0
	for fish_id in GameData.get_all_fish_ids():
		total += PlayerProgress.fish_count(fish_id)
	return total


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
	sb.content_margin_left = 12.0
	sb.content_margin_top = 8.0
	sb.content_margin_right = 12.0
	sb.content_margin_bottom = 8.0
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0.0, 2.0)
	sb.anti_aliasing = false
	return sb


func _atlas(path: String, index: int, columns: int, rows: int) -> Texture2D:
	var tex := load(path) as Texture2D
	if tex == null:
		return null
	var cell_w := float(tex.get_width()) / float(columns)
	var cell_h := float(tex.get_height()) / float(rows)
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	var row := int(index / columns)
	atlas.region = Rect2(
		float(index % columns) * cell_w,
		float(row) * cell_h,
		cell_w,
		cell_h
	)
	return atlas


func _fish_icon(fish_id: String) -> Texture2D:
	return _atlas(FISH_ICON_SHEET, int(FISH_ICON_INDEX.get(fish_id, 0)), 1, 6)


func _recipe_icon(recipe_id: String) -> Texture2D:
	var idx := 5 if recipe_id == "locked" else int(RECIPE_ICON_INDEX.get(recipe_id, 0))
	return _atlas(DISH_ICON_SHEET, idx, 3, 2)


func _featured_dish_texture(recipe_id: String) -> Texture2D:
	if recipe_id == "salt_grill":
		return load(DISH_FEATURE_AJI) as Texture2D
	return _recipe_icon(recipe_id)
