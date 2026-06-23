extends "res://src/ui/screen_base.gd"

var _rod_list: ItemList
var _detail_label: Label
var _money_label: Label
var _action_button: Button
var _result_label: Label
var _selected_rod_id: String = "starter"


func _build_screen() -> void:
	add_gradient_background(Color("#3a2a1c"), Color("#1a1208"))
	var root := make_root_margin(18)
	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 14)
	root.add_child(layout)

	layout.add_child(make_header("釣具店", "魚を売って装備を更新すると、大型魚とのファイトが安定する"))

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
	var title := make_label("販売中の竿", 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list_box.add_child(title)
	_rod_list = ItemList.new()
	_rod_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_rod_list.item_selected.connect(_on_rod_selected)
	list_box.add_child(_rod_list)

	var detail_panel := make_panel()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(detail_panel)
	var detail_box := VBoxContainer.new()
	detail_box.add_theme_constant_override("separation", 14)
	detail_panel.add_child(detail_box)
	var detail_title := make_label("装備の詳細", 28)
	detail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_box.add_child(detail_title)
	_detail_label = make_label("竿を選んでください。", 21)
	_detail_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_box.add_child(_detail_label)
	_action_button = make_button("購入する", _buy_or_equip, 450)
	detail_box.add_child(_action_button)
	detail_box.add_child(make_button("港へ戻る", func() -> void: navigate("harbor"), 450))

	var result_panel := make_panel(true)
	result_panel.custom_minimum_size = Vector2(0, 82)
	layout.add_child(result_panel)
	_result_label = make_label("竿の強さとプレイヤーレベルの両方が、ぬし攻略に影響します。", 19, Color("#e9f6ff"))
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_panel.add_child(_result_label)

	_refresh()


func _refresh() -> void:
	_money_label.text = (
		"所持金　%d G　｜　装備中：%s"
		% [
			PlayerProgress.money,
			String(GameData.get_rod(PlayerProgress.equipped_rod_id).get("name", "入門竿")),
		]
	)
	_rod_list.clear()
	var first_index := -1
	var selected_index := 0
	for rod_id in GameData.get_all_rod_ids():
		var rod := GameData.get_rod(rod_id)
		var marker := (
			"［装備中］"
			if rod_id == PlayerProgress.equipped_rod_id
			else ("［所持］" if rod_id in PlayerProgress.owned_rods else "%d G" % int(rod["price"]))
		)
		var index := _rod_list.item_count
		_rod_list.add_item("%s　%s" % [String(rod["name"]), marker])
		_rod_list.set_item_metadata(index, rod_id)
		if first_index < 0:
			first_index = index
		if rod_id == _selected_rod_id:
			selected_index = index
	if first_index >= 0:
		_rod_list.select(selected_index)
		_on_rod_selected(selected_index)


func _on_rod_selected(index: int) -> void:
	_selected_rod_id = String(_rod_list.get_item_metadata(index))
	var rod := GameData.get_rod(_selected_rod_id)
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
	if _selected_rod_id == PlayerProgress.equipped_rod_id:
		_action_button.text = "装備中"
		_action_button.disabled = true
	elif _selected_rod_id in PlayerProgress.owned_rods:
		_action_button.text = "装備する"
		_action_button.disabled = false
	else:
		_action_button.text = "%d Gで購入" % int(rod["price"])
		_action_button.disabled = PlayerProgress.money < int(rod["price"])


func _buy_or_equip() -> void:
	var result := PlayerProgress.buy_or_equip_rod(_selected_rod_id)
	_result_label.text = String(result.get("message", "処理できませんでした。"))
	_refresh()
