extends "res://src/ui/screen_base.gd"

var _fish_list: ItemList
var _recipe_list: ItemList
var _detail_label: Label
var _cook_button: Button
var _result_label: Label
var _exp_bar: ProgressBar
var _exp_label: Label
var _level_label: Label
var _selected_fish_id: String = ""
var _selected_recipe_id: String = ""


func _build_screen() -> void:
	add_gradient_background(Color("#2a2418"), Color("#14110b"))
	var root := make_root_margin(16)
	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 12)
	root.add_child(layout)

	layout.add_child(make_header("調理場", "魚を料理して食べると、食経験値と次の釣行用バフを獲得"))

	var level_panel := make_panel(true)
	level_panel.custom_minimum_size = Vector2(0, 72)
	layout.add_child(level_panel)
	var level_row := HBoxContainer.new()
	level_row.add_theme_constant_override("separation", 16)
	level_panel.add_child(level_row)
	_level_label = make_label("", 24, Color("#ffe5a6"))
	_level_label.custom_minimum_size = Vector2(210, 0)
	level_row.add_child(_level_label)
	_exp_bar = ProgressBar.new()
	_exp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_exp_bar.custom_minimum_size = Vector2(0, 32)
	_exp_bar.show_percentage = false
	level_row.add_child(_exp_bar)
	_exp_label = make_label("", 18, Color("#eaf6ff"))
	_exp_label.custom_minimum_size = Vector2(170, 0)
	_exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	level_row.add_child(_exp_label)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	layout.add_child(body)

	var fish_panel := make_panel()
	fish_panel.custom_minimum_size = Vector2(270, 0)
	fish_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(fish_panel)
	var fish_box := VBoxContainer.new()
	fish_box.add_theme_constant_override("separation", 8)
	fish_panel.add_child(fish_box)
	var fish_title := make_label("所持している魚", 24)
	fish_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fish_box.add_child(fish_title)
	_fish_list = ItemList.new()
	_fish_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_fish_list.custom_minimum_size = Vector2(245, 340)
	_fish_list.item_selected.connect(_on_fish_selected)
	fish_box.add_child(_fish_list)

	var recipe_panel := make_panel()
	recipe_panel.custom_minimum_size = Vector2(330, 0)
	recipe_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(recipe_panel)
	var recipe_box := VBoxContainer.new()
	recipe_box.add_theme_constant_override("separation", 8)
	recipe_panel.add_child(recipe_box)
	var recipe_title := make_label("料理を選ぶ", 24)
	recipe_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	recipe_box.add_child(recipe_title)
	_recipe_list = ItemList.new()
	_recipe_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_recipe_list.custom_minimum_size = Vector2(305, 340)
	_recipe_list.item_selected.connect(_on_recipe_selected)
	recipe_box.add_child(_recipe_list)

	var detail_panel := make_panel()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(detail_panel)
	var detail_box := VBoxContainer.new()
	detail_box.add_theme_constant_override("separation", 12)
	detail_panel.add_child(detail_box)
	var detail_title := make_label("料理の詳細", 26)
	detail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_box.add_child(detail_title)
	_detail_label = make_label("魚と料理を選んでください。", 19)
	_detail_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_box.add_child(_detail_label)
	_cook_button = make_button("調理して食べる", _cook_selected, 340)
	_cook_button.disabled = true
	detail_box.add_child(_cook_button)
	var back_button := make_button("港へ戻る", func() -> void: navigate("harbor"), 340)
	detail_box.add_child(back_button)

	var result_panel := make_panel(true)
	result_panel.custom_minimum_size = Vector2(0, 92)
	layout.add_child(result_panel)
	_result_label = make_label("魚を選ぶと作れる料理が表示されます。", 19, Color("#eaf6ff"))
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_panel.add_child(_result_label)

	_refresh_all()


func _refresh_all() -> void:
	_refresh_exp()
	_rebuild_fish_list()


func _refresh_exp() -> void:
	_level_label.text = "プレイヤー Lv.%d" % PlayerProgress.level
	if PlayerProgress.level >= GameData.MAX_LEVEL:
		_exp_bar.max_value = 1.0
		_exp_bar.value = 1.0
		_exp_label.text = "MAX LEVEL"
	else:
		_exp_bar.max_value = maxf(1.0, float(PlayerProgress.exp_to_next_level()))
		_exp_bar.value = PlayerProgress.exp
		_exp_label.text = "%d / %d EXP" % [PlayerProgress.exp, PlayerProgress.exp_to_next_level()]


func _rebuild_fish_list() -> void:
	_fish_list.clear()
	_selected_fish_id = ""
	_selected_recipe_id = ""
	var first_index := -1
	for fish_id in GameData.get_all_fish_ids():
		var count := PlayerProgress.fish_count(fish_id)
		if count <= 0:
			continue
		var fish := GameData.get_fish(fish_id)
		var index := _fish_list.item_count
		_fish_list.add_item("%s　× %d" % [String(fish["name"]), count])
		_fish_list.set_item_metadata(index, fish_id)
		if first_index < 0:
			first_index = index

	if first_index >= 0:
		_fish_list.select(first_index)
		_on_fish_selected(first_index)
	else:
		_recipe_list.clear()
		_detail_label.text = "クーラーボックスに魚がいません。\nまずは釣り場で魚を釣ってきましょう。"
		_cook_button.disabled = true


func _on_fish_selected(index: int) -> void:
	_selected_fish_id = String(_fish_list.get_item_metadata(index))
	_rebuild_recipe_list()


func _rebuild_recipe_list() -> void:
	_recipe_list.clear()
	_selected_recipe_id = ""
	var recipes := GameData.get_recipes_for_fish(_selected_fish_id, PlayerProgress.level)
	for recipe in recipes:
		var recipe_id := String(recipe["id"])
		var exp_amount := GameData.recipe_exp(_selected_fish_id, recipe_id)
		var dish_key := "%s:%s" % [_selected_fish_id, recipe_id]
		var first_mark := "★初回" if not PlayerProgress.eaten_recipes.has(dish_key) else ""
		var index := _recipe_list.item_count
		_recipe_list.add_item("%s　%d EXP　%s" % [String(recipe["name"]), exp_amount, first_mark])
		_recipe_list.set_item_metadata(index, recipe_id)

	if _recipe_list.item_count > 0:
		_recipe_list.select(0)
		_on_recipe_selected(0)
	else:
		_detail_label.text = "現在のレベルで作れる料理がありません。"
		_cook_button.disabled = true


func _on_recipe_selected(index: int) -> void:
	_selected_recipe_id = String(_recipe_list.get_item_metadata(index))
	_refresh_detail()


func _refresh_detail() -> void:
	var fish := GameData.get_fish(_selected_fish_id)
	var recipe := GameData.get_recipe(_selected_recipe_id)
	if fish.is_empty() or recipe.is_empty():
		_cook_button.disabled = true
		return
	var base_exp := GameData.recipe_exp(_selected_fish_id, _selected_recipe_id)
	var dish_key := "%s:%s" % [_selected_fish_id, _selected_recipe_id]
	var first_time := not PlayerProgress.eaten_recipes.has(dish_key)
	var total_exp := base_exp * 2 if first_time else base_exp
	var detail_format := (
		"%sの%s\n\n%s\n\n必要な材料：%s ×1\n"
		+ "所持数：%d → %d\n\n獲得食経験値：%d EXP%s\n\n"
		+ "食事効果：%s\n\n"
		+ "※食事効果は次の釣行開始時に消費され、既存の効果を上書きします。"
	)
	_detail_label.text = (
		detail_format
		% [
			String(fish["name"]),
			String(recipe["name"]),
			String(recipe["description"]),
			String(fish["name"]),
			PlayerProgress.fish_count(_selected_fish_id),
			maxi(0, PlayerProgress.fish_count(_selected_fish_id) - 1),
			total_exp,
			"（初回ボーナス込み）" if first_time else "",
			String(recipe["buff_text"]),
		]
	)
	_cook_button.disabled = PlayerProgress.fish_count(_selected_fish_id) <= 0


func _cook_selected() -> void:
	if _selected_fish_id.is_empty() or _selected_recipe_id.is_empty():
		return
	var result := PlayerProgress.cook_and_eat(_selected_fish_id, _selected_recipe_id)
	if not bool(result.get("ok", false)):
		_result_label.text = String(result.get("message", "調理できませんでした。"))
		return

	var level_text := ""
	var leveled_to: Array = result.get("leveled_to", [])
	if not leveled_to.is_empty():
		level_text = "\nLEVEL UP！ Lv.%d になった！" % int(leveled_to.back())
		if int(leveled_to.back()) == GameData.BOSS_UNLOCK_LEVEL:
			level_text += "\n港のぬしに挑戦できるようになった！"
	_result_label.text = (
		"%sを食べた！　食経験値 +%d%s\n%s%s"
		% [
			String(result.get("dish_name", "料理")),
			int(result.get("total_exp", 0)),
			"（初めて食べた料理ボーナス！）" if bool(result.get("first_time", false)) else "",
			String(Dictionary(result.get("buff", {})).get("text", "")),
			level_text,
		]
	)
	_refresh_all()
