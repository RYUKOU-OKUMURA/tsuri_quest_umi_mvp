extends "res://src/ui/screen_base.gd"

var _fish_list: ItemList
var _detail_label: Label
var _money_label: Label
var _result_label: Label
var _sell_one_button: Button
var _sell_all_button: Button
var _selected_fish_id: String = ""


func _build_screen() -> void:
	add_background(Color("#163348"))
	var root := make_root_margin(18)
	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 14)
	root.add_child(layout)

	layout.add_child(make_header("魚市場", "釣った魚を売って、より強い釣具をそろえよう"))

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
	var title := make_label("クーラーボックス", 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list_box.add_child(title)
	_fish_list = ItemList.new()
	_fish_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_fish_list.item_selected.connect(_on_fish_selected)
	list_box.add_child(_fish_list)

	var detail_panel := make_panel()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(detail_panel)
	var detail_box := VBoxContainer.new()
	detail_box.add_theme_constant_override("separation", 15)
	detail_panel.add_child(detail_box)
	var detail_title := make_label("査定", 28)
	detail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_box.add_child(detail_title)
	_detail_label = make_label("売る魚を選んでください。", 21)
	_detail_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_box.add_child(_detail_label)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 14)
	detail_box.add_child(buttons)
	_sell_one_button = make_button("1匹売る", _sell_one, 220)
	buttons.add_child(_sell_one_button)
	_sell_all_button = make_button("全部売る", _sell_all, 220)
	buttons.add_child(_sell_all_button)
	detail_box.add_child(make_button("港へ戻る", func() -> void: navigate("harbor"), 460))

	var result_panel := make_panel(true)
	result_panel.custom_minimum_size = Vector2(0, 82)
	layout.add_child(result_panel)
	_result_label = make_label("魚は料理にも使えます。売る量を考えて選びましょう。", 19, Color("#e9f6ff"))
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_panel.add_child(_result_label)

	_refresh()


func _refresh() -> void:
	_money_label.text = "所持金　%d G" % PlayerProgress.money
	_fish_list.clear()
	_selected_fish_id = ""
	var first_index := -1
	for fish_id in GameData.get_all_fish_ids():
		var count := PlayerProgress.fish_count(fish_id)
		if count <= 0:
			continue
		var fish := GameData.get_fish(fish_id)
		var index := _fish_list.item_count
		_fish_list.add_item(
			"%s　× %d　（1匹 %d G）" % [String(fish["name"]), count, int(fish["sell_price"])]
		)
		_fish_list.set_item_metadata(index, fish_id)
		if first_index < 0:
			first_index = index
	if first_index >= 0:
		_fish_list.select(first_index)
		_on_fish_selected(first_index)
	else:
		_detail_label.text = "売れる魚がありません。\n釣り場で魚を釣ってきましょう。"
		_sell_one_button.disabled = true
		_sell_all_button.disabled = true


func _on_fish_selected(index: int) -> void:
	_selected_fish_id = String(_fish_list.get_item_metadata(index))
	var fish := GameData.get_fish(_selected_fish_id)
	var count := PlayerProgress.fish_count(_selected_fish_id)
	var total := count * int(fish["sell_price"])
	_detail_label.text = (
		"%s\n\n%s\n\n所持数：%d匹\n1匹の売値：%d G\n全部売った場合：%d G\n\n食経験値の素材として残すか、装備資金に換えるかを選ぼう。"
		% [
			String(fish["name"]),
			String(fish["habitat"]),
			count,
			int(fish["sell_price"]),
			total,
		]
	)
	_sell_one_button.disabled = count <= 0
	_sell_all_button.disabled = count <= 0


func _sell_one() -> void:
	_sell_amount(1)


func _sell_all() -> void:
	_sell_amount(PlayerProgress.fish_count(_selected_fish_id))


func _sell_amount(amount: int) -> void:
	if _selected_fish_id.is_empty() or amount <= 0:
		return
	var fish := GameData.get_fish(_selected_fish_id)
	var result := PlayerProgress.sell_fish(_selected_fish_id, amount)
	if bool(result.get("ok", false)):
		_result_label.text = (
			"%sを%d匹売って、%d Gを受け取った。"
			% [
				String(fish["name"]),
				amount,
				int(result.get("income", 0)),
			]
		)
	else:
		_result_label.text = String(result.get("message", "売却できませんでした。"))
	_refresh()
