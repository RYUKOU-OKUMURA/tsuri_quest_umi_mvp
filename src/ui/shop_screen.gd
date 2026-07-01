extends "res://src/ui/screen_base.gd"

var _shop_list: ItemList
var _detail_label: Label
var _money_label: Label
var _action_button: Button
var _result_label: Label
var _selected_item_type: String = "rod"
var _selected_item_id: String = "starter"


func _build_screen() -> void:
	add_gradient_background(Color("#3a2a1c"), Color("#1a1208"))
	var root := make_root_margin(18)
	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 14)
	root.add_child(layout)

	layout.add_child(make_header("釣具店", "魚を売って竿や船をそろえると、遠い釣り場と大型魚に挑める"))

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
	var title := make_label("販売中の品", 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list_box.add_child(title)
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
	var detail_title := make_label("装備の詳細", 28)
	detail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_box.add_child(detail_title)
	_detail_label = make_label("品を選んでください。", 21)
	_detail_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_box.add_child(_detail_label)
	_action_button = make_button("購入する", _buy_or_equip, 450)
	detail_box.add_child(_action_button)
	detail_box.add_child(make_button("港へ戻る", func() -> void: navigate("harbor"), 450))

	var result_panel := make_panel(true)
	result_panel.custom_minimum_size = Vector2(0, 82)
	layout.add_child(result_panel)
	_result_label = make_label("竿はファイトを安定させ、船は沖の釣り場へ向かう手段になります。", 19, Color("#e9f6ff"))
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_panel.add_child(_result_label)

	_refresh()


func _refresh() -> void:
	var best_boat := PlayerProgress.get_best_boat()
	var boat_name := "船なし" if best_boat.is_empty() else String(best_boat.get("short_name", best_boat.get("name", "船")))
	_money_label.text = (
		"所持金　%d G　｜　装備中：%s　｜　船：%s"
		% [
			PlayerProgress.money,
			String(GameData.get_rod(PlayerProgress.equipped_rod_id).get("name", "入門竿")),
			boat_name,
		]
	)
	_shop_list.clear()
	var first_index := -1
	var selected_index := 0
	_add_section_item("竿")
	for rod_id in GameData.get_all_rod_ids():
		var rod := GameData.get_rod(rod_id)
		var marker := (
			"［装備中］"
			if rod_id == PlayerProgress.equipped_rod_id
			else ("［所持］" if rod_id in PlayerProgress.owned_rods else "%d G" % int(rod["price"]))
		)
		var index := _shop_list.item_count
		_shop_list.add_item("%s　%s" % [String(rod["name"]), marker])
		_shop_list.set_item_metadata(index, {"type": "rod", "id": rod_id})
		if first_index < 0:
			first_index = index
		if _selected_item_type == "rod" and rod_id == _selected_item_id:
			selected_index = index
	_add_section_item("船")
	for boat_id in GameData.get_all_boat_ids():
		var boat := GameData.get_boat(boat_id)
		var marker := "［所持］" if PlayerProgress.has_boat(boat_id) else "%d G" % int(boat["price"])
		var index := _shop_list.item_count
		_shop_list.add_item("%s　%s" % [String(boat["name"]), marker])
		_shop_list.set_item_metadata(index, {"type": "boat", "id": boat_id})
		if first_index < 0:
			first_index = index
		if _selected_item_type == "boat" and boat_id == _selected_item_id:
			selected_index = index
	if first_index >= 0:
		_shop_list.select(selected_index)
		_on_item_selected(selected_index)


func _add_section_item(title: String) -> void:
	var index := _shop_list.item_count
	_shop_list.add_item("── %s ──" % title)
	_shop_list.set_item_disabled(index, true)
	_shop_list.set_item_selectable(index, false)


func _on_item_selected(index: int) -> void:
	var metadata = _shop_list.get_item_metadata(index)
	if typeof(metadata) != TYPE_DICTIONARY:
		return
	var item: Dictionary = metadata
	_selected_item_type = String(item.get("type", "rod"))
	_selected_item_id = String(item.get("id", "starter"))
	if _selected_item_type == "boat":
		_show_boat_detail(_selected_item_id)
	else:
		_show_rod_detail(_selected_item_id)


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


func _show_boat_detail(boat_id: String) -> void:
	var boat := GameData.get_boat(boat_id)
	_detail_label.text = (
		"%s\n\n%s\n\n価格：%d G\n航行ランク：%d\n出航範囲：%s\n\n船は沖の釣り場へ向かうための恒久装備です。購入後は装備切り替えなしで利用できます。"
		% [
			String(boat["name"]),
			String(boat["description"]),
			int(boat["price"]),
			int(boat["rank"]),
			_boat_access_spot_text(int(boat["rank"])),
		]
	)
	if PlayerProgress.has_boat(boat_id):
		_action_button.text = "所持済み"
		_action_button.disabled = true
	else:
		_action_button.text = "%d Gで購入" % int(boat["price"])
		_action_button.disabled = PlayerProgress.money < int(boat["price"])


func _boat_access_spot_text(rank: int) -> String:
	var names: Array[String] = []
	for spot_id in GameData.get_all_fishing_spot_ids():
		var spot := GameData.get_fishing_spot(spot_id)
		var required_rank := int(spot.get("required_boat_rank", GameData.NO_BOAT_RANK))
		if required_rank > GameData.NO_BOAT_RANK and required_rank <= rank:
			names.append(String(spot.get("short_name", spot.get("name", spot_id))))
	if names.is_empty():
		return "港周辺のみ"
	return "、".join(PackedStringArray(names))


func _buy_or_equip() -> void:
	var result := (
		PlayerProgress.buy_boat(_selected_item_id)
		if _selected_item_type == "boat"
		else PlayerProgress.buy_or_equip_rod(_selected_item_id)
	)
	_result_label.text = String(result.get("message", "処理できませんでした。"))
	_refresh()
