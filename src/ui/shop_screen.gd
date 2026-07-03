extends "res://src/ui/screen_base.gd"

var _shop_list: ItemList
var _list_title_label: Label
var _detail_title_label: Label
var _detail_label: Label
var _money_label: Label
var _action_button: Button
var _result_label: Label
var _shop_mode: String = "rod"
var _selected_item_id: String = "starter"


func _build_screen() -> void:
	add_gradient_background(Color("#3a2a1c"), Color("#1a1208"))
	var root := make_root_margin(18)
	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 14)
	root.add_child(layout)

	layout.add_child(make_header("釣具店", "竿と仕掛けをそろえ、狙う魚に合わせて装備を変える"))

	var money_panel := make_panel(true)
	money_panel.custom_minimum_size = Vector2(0, 68)
	layout.add_child(money_panel)
	_money_label = make_label("", 26, Color("#ffe7a7"))
	_money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_money_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	money_panel.add_child(_money_label)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	layout.add_child(body)

	var list_panel := make_panel()
	list_panel.custom_minimum_size = Vector2(430, 0)
	list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(list_panel)
	var list_box := VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 10)
	list_panel.add_child(list_box)
	var mode_row := HBoxContainer.new()
	mode_row.add_theme_constant_override("separation", 8)
	list_box.add_child(mode_row)
	mode_row.add_child(make_button("竿", func() -> void: _set_shop_mode("rod"), 0, true))
	mode_row.add_child(make_button("仕掛け", func() -> void: _set_shop_mode("rig"), 0, true))
	_list_title_label = make_label("販売中の竿", 26)
	_list_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list_box.add_child(_list_title_label)
	_shop_list = ItemList.new()
	_shop_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_shop_list.item_selected.connect(_on_item_selected)
	list_box.add_child(_shop_list)

	var detail_panel := make_panel()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(detail_panel)
	var detail_box := VBoxContainer.new()
	detail_box.add_theme_constant_override("separation", 14)
	detail_panel.add_child(detail_box)
	_detail_title_label = make_label("竿の詳細", 28)
	_detail_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_box.add_child(_detail_title_label)
	_detail_label = make_label("品を選んでください。", 21)
	_detail_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_box.add_child(_detail_label)
	_action_button = make_button("購入する", _buy_or_equip, 450)
	detail_box.add_child(_action_button)
	detail_box.add_child(make_button("港へ戻る", func() -> void: navigate("harbor"), 450))

	var result_panel := make_panel(true)
	result_panel.custom_minimum_size = Vector2(0, 82)
	layout.add_child(result_panel)
	_result_label = make_label("船は港の船着き場で購入できます。釣具店では竿と仕掛けを整えます。", 19, Color("#e9f6ff"))
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_panel.add_child(_result_label)

	_refresh()


func _refresh() -> void:
	_money_label.text = (
		"所持金　%d G　｜　竿：%s　｜　仕掛け：%s"
		% [
			PlayerProgress.money,
			String(GameData.get_rod(PlayerProgress.equipped_rod_id).get("name", "入門竿")),
			String(GameData.get_rig(PlayerProgress.equipped_rig_id).get("name", "サビキ仕掛け")),
		]
	)
	_list_title_label.text = "販売中の竿" if _shop_mode == "rod" else "販売中の仕掛け"
	_detail_title_label.text = "竿の詳細" if _shop_mode == "rod" else "仕掛けの詳細"
	_shop_list.clear()
	var first_index := -1
	var selected_index := 0
	if _shop_mode == "rod":
		for rod_id in GameData.get_all_rod_ids():
			var rod := GameData.get_rod(rod_id)
			var marker := (
				"［装備中］"
				if rod_id == PlayerProgress.equipped_rod_id
				else ("［所持］" if rod_id in PlayerProgress.owned_rods else "%d G" % int(rod["price"]))
			)
			var index := _shop_list.item_count
			_shop_list.add_item("%s　%s" % [String(rod["name"]), marker])
			_shop_list.set_item_metadata(index, rod_id)
			if first_index < 0:
				first_index = index
			if rod_id == _selected_item_id:
				selected_index = index
	else:
		for rig_id in GameData.get_all_rig_ids():
			var rig := GameData.get_rig(rig_id)
			var marker := _rig_marker(rig_id, rig)
			var index := _shop_list.item_count
			_shop_list.add_item("%s　%s" % [String(rig["name"]), marker])
			_shop_list.set_item_metadata(index, rig_id)
			if first_index < 0:
				first_index = index
			if rig_id == _selected_item_id:
				selected_index = index
	if first_index >= 0:
		_shop_list.select(selected_index)
		_on_item_selected(selected_index)


func _set_shop_mode(mode: String) -> void:
	_shop_mode = mode
	_selected_item_id = "starter" if _shop_mode == "rod" else GameData.DEFAULT_RIG_ID
	_refresh()


func _on_item_selected(index: int) -> void:
	var metadata = _shop_list.get_item_metadata(index)
	_selected_item_id = String(metadata)
	if _shop_mode == "rod":
		_show_rod_detail(_selected_item_id)
	else:
		_show_rig_detail(_selected_item_id)


func _show_rod_detail(rod_id: String) -> void:
	var rod := GameData.get_rod(rod_id)
	var reel_percent := int(round((float(rod["reel_multiplier"]) - 1.0) * 100.0))
	var line_percent := int(round(float(rod["line_limit_bonus"]) * 100.0))
	_detail_label.text = (
		"%s\n\n%s\n\n価格：%d G\n巻力補正：+%d%%\nライン切断限界：+%d%%\n技量補正：+%d\n\n高性能な竿は操作を不要にするのではなく、安全に判断できる余裕を広げます。"
		% [
			String(rod["name"]),
			String(rod["description"]),
			int(rod["price"]),
				reel_percent,
				line_percent,
				int(rod["technique_bonus"]),
			]
	)
	if rod_id == PlayerProgress.equipped_rod_id:
		_action_button.text = "装備中"
		_action_button.disabled = true
	elif rod_id in PlayerProgress.owned_rods:
		_action_button.text = "装備する"
		_action_button.disabled = false
	else:
		_action_button.text = "%d Gで購入" % int(rod["price"])
		_action_button.disabled = PlayerProgress.money < int(rod["price"])


func _show_rig_detail(rig_id: String) -> void:
	var rig := GameData.get_rig(rig_id)
	var bait_types: Array[String] = []
	for bait_variant in Array(rig.get("bait_types", [])):
		bait_types.append(String(bait_variant))
	var unlock_level := int(rig.get("unlock_level", 1))
	_detail_label.text = (
		"%s\n\n%s\n\n価格：%d G\n解放：Lv.%d\n対応エサ：%s\n\n狙う魚の好物と仕掛けが合うと、その魚の反応が強くなります。"
		% [
			String(rig["name"]),
			String(rig["description"]),
			int(rig["price"]),
			unlock_level,
			"、".join(PackedStringArray(bait_types)),
		]
	)
	if rig_id == PlayerProgress.equipped_rig_id:
		_action_button.text = "装備中"
		_action_button.disabled = true
	elif PlayerProgress.level < unlock_level:
		_action_button.text = "Lv.%dで解放" % unlock_level
		_action_button.disabled = true
	elif rig_id in PlayerProgress.owned_rigs:
		_action_button.text = "装備する"
		_action_button.disabled = false
	else:
		_action_button.text = "%d Gで購入" % int(rig["price"])
		_action_button.disabled = PlayerProgress.money < int(rig["price"])


func _rig_marker(rig_id: String, rig: Dictionary) -> String:
	if rig_id == PlayerProgress.equipped_rig_id:
		return "［装備中］"
	if rig_id in PlayerProgress.owned_rigs:
		return "［所持］"
	var unlock_level := int(rig.get("unlock_level", 1))
	if PlayerProgress.level < unlock_level:
		return "Lv.%d" % unlock_level
	return "%d G" % int(rig["price"])


func _buy_or_equip() -> void:
	var result := (
		PlayerProgress.buy_or_equip_rod(_selected_item_id)
		if _shop_mode == "rod"
		else PlayerProgress.buy_or_equip_rig(_selected_item_id)
	)
	_result_label.text = String(result.get("message", "処理できませんでした。"))
	_refresh()
