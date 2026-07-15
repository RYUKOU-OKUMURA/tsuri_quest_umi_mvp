extends ScreenBase

const SHIPYARD_BG_PATH := "res://assets/showcase/shipyard/shipyard_purchase_bg.png"
const OFFSHORE_SPOT_TOTAL := 3
const BOAT_CARD_IDS := [&"skiff", &"offshore_boat", &"bluewater_boat"]

var _background_rect: TextureRect
var _selected_boat_id := ""
var _top_level_label: Label
var _top_money_label: Label
var _top_boat_label: Label
var _top_rank_label: Label
var _title_label: Label
var _boat_card_labels: Dictionary = {}
var _boat_card_status_labels: Dictionary = {}
var _boat_card_price_labels: Dictionary = {}
var _boat_card_range_labels: Dictionary = {}
var _boat_card_rank_labels: Dictionary = {}
var _boat_card_frames: Dictionary = {}
var _boat_card_buttons: Dictionary = {}
var _detail_status_label: Label
var _detail_name_label: Label
var _detail_range_label: Label
var _detail_rank_label: Label
var _detail_unlock_label: Label
var _detail_type_label: Label
var _price_label: Label
var _shortage_label: Label
var _buy_button: Button
var _route_title_label: Label
var _route_status_label: Label
var _route_locked_label: Label
var _route_after_label: Label
var _route_hint_label: Label
var _footer_label: Label
var _return_button: Button
var _keyboard_focus_initialized := false


func _build_screen() -> void:
	_background_rect = _texture_rect(SHIPYARD_BG_PATH)
	_background_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_background_rect.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(_background_rect)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_selected_boat_id = _default_boat_id()
	_build_top_bar(root)
	_build_boat_cards(root)
	_build_center_detail(root)
	_build_route_panel(root)
	_build_footer(root)
	_refresh()
	_configure_keyboard_focus()
	set_common_cancel_handler(_return_to_harbor)


func _build_top_bar(root: Control) -> void:
	var place_label := _shipyard_label("船着き場", 20, Palette.SHIPYARD_TOP_TEXT, true, 3)
	place_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	place_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(root, place_label, 0.072, 0.014, 0.178, 0.063)

	_top_level_label = _shipyard_label("", 19, Palette.SHIPYARD_TOP_TEXT, true, 3)
	_top_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_top_level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(root, _top_level_label, 0.222, 0.014, 0.274, 0.063)

	_top_money_label = _shipyard_label("", 19, Palette.SHIPYARD_TOP_TEXT, true, 3)
	_top_money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_top_money_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(root, _top_money_label, 0.374, 0.014, 0.488, 0.063)

	_top_boat_label = _shipyard_label("", 17, Palette.SHIPYARD_TOP_TEXT, true, 3)
	_top_boat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_top_boat_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(root, _top_boat_label, 0.565, 0.014, 0.652, 0.063)

	_top_rank_label = _shipyard_label("", 17, Palette.SHIPYARD_TOP_TEXT, true, 3)
	_top_rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_top_rank_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(root, _top_rank_label, 0.906, 0.014, 0.965, 0.063)


func _build_boat_cards(root: Control) -> void:
	var cards := [
		{"id": "skiff", "rect": Rect2(0.022, 0.124, 0.231, 0.221)},
		{"id": "offshore_boat", "rect": Rect2(0.022, 0.365, 0.231, 0.221)},
		{"id": "bluewater_boat", "rect": Rect2(0.022, 0.606, 0.231, 0.221)},
	]
	for card in cards:
		var boat_id := String(card["id"])
		var rect: Rect2 = card["rect"]
		var holder := _anchored_control(
			root,
			rect.position.x,
			rect.position.y,
			rect.position.x + rect.size.x,
			rect.position.y + rect.size.y
		)
		var select_frame := Panel.new()
		select_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		select_frame.add_theme_stylebox_override("panel", _selection_style())
		select_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		holder.add_child(select_frame)
		_boat_card_frames[boat_id] = select_frame

		var status_plate := Panel.new()
		status_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		status_plate.add_theme_stylebox_override("panel", _status_badge_style(Palette.SHIPYARD_BADGE_FILL, Palette.SHIPYARD_BADGE_BORDER))
		_place_control(holder, status_plate, 0.355, 0.052, 0.600, 0.172)

		var status := _shipyard_label("", 11, Palette.SHIPYARD_BADGE_TEXT, true, 1, Palette.SHIPYARD_BADGE_TEXT_OUTLINE)
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_place_control(holder, status, 0.362, 0.055, 0.592, 0.168)
		_boat_card_status_labels[boat_id] = status

		var price_plate := Panel.new()
		price_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		price_plate.add_theme_stylebox_override("panel", _status_badge_style(Palette.SHIPYARD_PRICE_PLATE_FILL, Palette.SHIPYARD_PRICE_PLATE_BORDER))
		_place_control(holder, price_plate, 0.615, 0.052, 0.930, 0.172)

		var price := _shipyard_label("", 13, Palette.SHIPYARD_PRICE_TEXT, true, 0)
		price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_place_control(holder, price, 0.628, 0.055, 0.915, 0.168)
		_boat_card_price_labels[boat_id] = price

		var name_plate := Panel.new()
		name_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_plate.add_theme_stylebox_override("panel", _status_badge_style(Color(Palette.SHIPYARD_NAME_PLATE_FILL, 0.92), Palette.SHIPYARD_NAME_PLATE_BORDER))
		_place_control(holder, name_plate, 0.120, 0.705, 0.885, 0.840)

		var name := _shipyard_label("", 17, Palette.SHIPYARD_NAME_TEXT, true, 2, Palette.SHIPYARD_LABEL_OUTLINE)
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_place_control(holder, name, 0.145, 0.706, 0.860, 0.836)
		_boat_card_labels[boat_id] = name

		var rank := _shipyard_label("", 12, Palette.SHIPYARD_CARD_META_TEXT, true, 0)
		rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rank.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_place_control(holder, rank, 0.115, 0.846, 0.305, 0.938)
		_boat_card_rank_labels[boat_id] = rank

		var range := _shipyard_label("", 12, Palette.SHIPYARD_CARD_META_TEXT, true, 0)
		range.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		range.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_place_control(holder, range, 0.315, 0.846, 0.890, 0.938)
		_boat_card_range_labels[boat_id] = range

		var hit := _transparent_button(func() -> void: _select_boat(boat_id))
		hit.set_meta("shipyard_boat_card", boat_id)
		_place_control(holder, hit, 0.0, 0.0, 1.0, 1.0)
		_boat_card_buttons[boat_id] = hit


func _build_center_detail(root: Control) -> void:
	_title_label = _shipyard_label("船着き場", 32, Palette.SHIPYARD_TITLE_TEXT, true, 0)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(root, _title_label, 0.362, 0.138, 0.635, 0.202)

	var detail_band := Panel.new()
	detail_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_band.add_theme_stylebox_override("panel", _status_badge_style(Color(Palette.SHIPYARD_NAME_PLATE_FILL, 0.94), Palette.SHIPYARD_DETAIL_BAND_BORDER))
	_place_control(root, detail_band, 0.318, 0.640, 0.650, 0.696)

	var detail_status_plate := Panel.new()
	detail_status_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_status_plate.add_theme_stylebox_override("panel", _status_badge_style(Color(Palette.SHIPYARD_BADGE_FILL, 0.92), Palette.SHIPYARD_BADGE_BORDER))
	_place_control(root, detail_status_plate, 0.322, 0.602, 0.442, 0.637)

	_detail_status_label = _shipyard_label("", 13, Palette.SHIPYARD_DETAIL_TEXT, true, 1, Palette.SHIPYARD_LABEL_OUTLINE)
	_detail_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(root, _detail_status_label, 0.323, 0.604, 0.440, 0.635)

	_detail_name_label = _shipyard_label("", 20, Palette.SHIPYARD_DETAIL_TEXT, true, 2)
	_detail_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(root, _detail_name_label, 0.333, 0.646, 0.503, 0.688)

	_detail_rank_label = _shipyard_label("", 15, Palette.SHIPYARD_DETAIL_META_TEXT, true, 0)
	_detail_rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_rank_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(root, _detail_rank_label, 0.363, 0.721, 0.421, 0.752)

	_detail_unlock_label = _shipyard_label("", 15, Palette.SHIPYARD_DETAIL_META_TEXT, true, 0)
	_detail_unlock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_unlock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(root, _detail_unlock_label, 0.476, 0.721, 0.534, 0.752)

	_detail_type_label = _shipyard_label("", 15, Palette.SHIPYARD_DETAIL_META_TEXT, true, 0)
	_detail_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_type_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(root, _detail_type_label, 0.592, 0.721, 0.648, 0.752)

	_price_label = _shipyard_label("", 20, Palette.SHIPYARD_TOP_TEXT, true, 3)
	_price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(root, _price_label, 0.354, 0.800, 0.466, 0.855)

	_shortage_label = _shipyard_label("", 13, Palette.SHIPYARD_SHORTAGE_TEXT, true, 1, Palette.SHIPYARD_LABEL_OUTLINE)
	_shortage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shortage_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(root, _shortage_label, 0.354, 0.858, 0.474, 0.888)

	_buy_button = _image_text_button("", _buy_selected_boat, 19)
	_buy_button.set_meta("shipyard_buy_button", true)
	_place_control(root, _buy_button, 0.545, 0.794, 0.654, 0.862)

	_detail_range_label = _shipyard_label("", 15, Palette.SHIPYARD_DETAIL_RANGE_TEXT, true, 1, Palette.SHIPYARD_LABEL_OUTLINE)
	_detail_range_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_range_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(root, _detail_range_label, 0.493, 0.646, 0.640, 0.688)


func _build_route_panel(root: Control) -> void:
	_route_title_label = _shipyard_label("", 19, Palette.SHIPYARD_CARD_META_TEXT, true, 0)
	_route_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_route_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(root, _route_title_label, 0.746, 0.140, 0.956, 0.184)

	_route_hint_label = _shipyard_label("", 14, Palette.SHIPYARD_TOP_TEXT, true, 2)
	_route_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_route_hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_route_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place_control(root, _route_hint_label, 0.755, 0.200, 0.955, 0.272)

	var current_plate := Panel.new()
	current_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	current_plate.add_theme_stylebox_override("panel", _status_badge_style(Color(Palette.SHIPYARD_NAME_PLATE_FILL, 0.92), Palette.SHIPYARD_ROUTE_CURRENT_BORDER))
	_place_control(root, current_plate, 0.758, 0.824, 0.874, 0.858)

	var after_plate := Panel.new()
	after_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	after_plate.add_theme_stylebox_override("panel", _status_badge_style(Color(Palette.SHIPYARD_ROUTE_AFTER_FILL, 0.92), Palette.SHIPYARD_DETAIL_BAND_BORDER))
	_place_control(root, after_plate, 0.889, 0.824, 0.965, 0.858)

	_route_status_label = _shipyard_label("", 13, Palette.SHIPYARD_ROUTE_CURRENT_TEXT, true, 1, Palette.SHIPYARD_LABEL_OUTLINE)
	_route_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_route_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(root, _route_status_label, 0.759, 0.825, 0.873, 0.856)

	_route_after_label = _shipyard_label("", 13, Palette.SHIPYARD_DETAIL_RANGE_TEXT, true, 1, Palette.SHIPYARD_LABEL_OUTLINE)
	_route_after_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_route_after_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(root, _route_after_label, 0.890, 0.825, 0.964, 0.856)

	_route_locked_label = _shipyard_label("", 15, Palette.SHIPYARD_TOP_TEXT, true, 2)
	_route_locked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_route_locked_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(root, _route_locked_label, 0.898, 0.857, 0.976, 0.895)


func _build_footer(root: Control) -> void:
	_return_button = _image_text_button("港へ戻る", _return_to_harbor, 20)
	_return_button.set_meta("shipyard_return", true)
	_place_control(root, _return_button, 0.842, 0.912, 0.976, 0.976)

	_footer_label = _shipyard_label("", 18, Palette.SHIPYARD_FOOTER_TEXT, true, 0)
	_footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_footer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_footer_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place_control(root, _footer_label, 0.270, 0.912, 0.768, 0.976)


func _refresh() -> void:
	var best_boat := PlayerProgress.get_best_boat()
	var best_rank := PlayerProgress.best_boat_rank()
	var current_boat := "船なし" if best_boat.is_empty() else String(best_boat.get("short_name", best_boat.get("name", "船")))
	_top_level_label.text = "%d" % PlayerProgress.level
	_top_money_label.text = "%s G" % ScreenBase.format_money(maxi(PlayerProgress.money, 0))
	_top_boat_label.text = current_boat
	_top_rank_label.text = "%d / 3" % best_rank

	for boat_id in GameData.get_all_boat_ids():
		var boat := GameData.get_boat(boat_id)
		var name_label: Label = _boat_card_labels.get(boat_id)
		var status_label: Label = _boat_card_status_labels.get(boat_id)
		var price_label: Label = _boat_card_price_labels.get(boat_id)
		var rank_label: Label = _boat_card_rank_labels.get(boat_id)
		var range_label: Label = _boat_card_range_labels.get(boat_id)
		var frame: Panel = _boat_card_frames.get(boat_id)
		if name_label != null:
			name_label.text = String(boat.get("name", boat_id))
		if status_label != null:
			status_label.text = _boat_card_status_text(boat_id)
			status_label.add_theme_color_override("font_color", _boat_status_color(boat_id))
		if price_label != null:
			price_label.text = _boat_card_price_text(boat_id)
		if rank_label != null:
			rank_label.text = "R%d" % int(boat.get("rank", 0))
		if range_label != null:
			range_label.text = _boat_compact_range_text(int(boat.get("rank", 0)))
		if frame != null:
			frame.visible = boat_id == _selected_boat_id

	_refresh_detail()


func _refresh_detail() -> void:
	var boat := GameData.get_boat(_selected_boat_id)
	if boat.is_empty():
		return
	var rank := int(boat.get("rank", 0))
	var price := int(boat.get("price", 0))
	var owned := PlayerProgress.has_boat(_selected_boat_id)
	var can_buy := PlayerProgress.money >= price and not owned
	var selected_after_rank := maxi(PlayerProgress.best_boat_rank(), rank)
	var unlocked_names := _boat_access_spot_names(rank)

	_title_label.text = "船着き場"
	_detail_status_label.text = _boat_card_status_text(_selected_boat_id)
	_detail_status_label.add_theme_color_override("font_color", _boat_status_color(_selected_boat_id))
	_detail_name_label.text = String(boat.get("name", "船"))
	_detail_rank_label.text = "Rank %d" % rank
	_detail_unlock_label.text = "%d航路" % unlocked_names.size()
	_detail_type_label.text = "恒久"
	_detail_range_label.text = String(boat.get("access_text", "出航範囲未設定")).replace("出航可能", "").strip_edges()
	_price_label.text = "登録済み" if owned else "%s G" % ScreenBase.format_money(maxi(price, 0))
	_shortage_label.text = "" if owned or can_buy else "あと %s G" % ScreenBase.format_money(maxi(price - PlayerProgress.money, 0))
	_route_title_label.text = "航路図　%s" % String(boat.get("short_name", "船"))
	_route_status_label.text = "現在 %d/%d" % [_accessible_offshore_count(PlayerProgress.best_boat_rank()), OFFSHORE_SPOT_TOTAL]
	_route_locked_label.text = "未達 %d" % maxi(0, OFFSHORE_SPOT_TOTAL - _accessible_offshore_count(PlayerProgress.best_boat_rank()))
	_route_after_label.text = "購入後 %d/%d" % [_accessible_offshore_count(selected_after_rank), OFFSHORE_SPOT_TOTAL]
	_route_hint_label.text = _route_hint_text(rank)

	if owned:
		_buy_button.text = "登録済み"
		_buy_button.disabled = true
	elif can_buy:
		_buy_button.text = "購入"
		_buy_button.disabled = false
	else:
		_buy_button.text = "資金不足"
		_buy_button.disabled = true

	if owned:
		_footer_label.text = "%sは登録済み。釣り場マップで対象の沖釣り場へ出航できます。" % String(boat.get("short_name", "船"))
	elif can_buy:
		_footer_label.text = "%sを購入すると、%sへ出航できるようになります。" % [
			String(boat.get("short_name", "船")),
			"、".join(PackedStringArray(unlocked_names)),
		]
	else:
		_footer_label.text = "あと %s G で%sを購入できます。魚市場で釣果を売って資金を作ろう。" % [
			ScreenBase.format_money(maxi(price - PlayerProgress.money, 0)),
			String(boat.get("short_name", "船")),
		]

	if _keyboard_focus_initialized:
		refresh_keyboard_focus()
		_refresh_keyboard_navigation()


func _configure_keyboard_focus() -> void:
	var candidates: Array[Control] = []
	for boat_id in BOAT_CARD_IDS:
		var card_button := _boat_card_buttons.get(String(boat_id)) as Button
		if card_button != null:
			candidates.append(card_button)
	candidates.append(_buy_button)
	candidates.append(_return_button)
	var preferred := _boat_card_buttons.get(_selected_boat_id) as Button
	setup_keyboard_focus(candidates, preferred)
	_keyboard_focus_initialized = true
	_refresh_keyboard_navigation()


func _refresh_keyboard_navigation() -> void:
	var available := keyboard_focus_candidates()
	if available.is_empty():
		return
	for control in available:
		control.focus_neighbor_left = NodePath()
		control.focus_neighbor_right = NodePath()
		control.focus_neighbor_top = NodePath()
		control.focus_neighbor_bottom = NodePath()
	var count := available.size()
	for index in range(count):
		var control := available[index]
		control.focus_next = control.get_path_to(available[(index + 1) % count])
		control.focus_previous = control.get_path_to(available[(index - 1 + count) % count])

	var skiff := _boat_card_buttons.get("skiff") as Button
	var offshore := _boat_card_buttons.get("offshore_boat") as Button
	var bluewater := _boat_card_buttons.get("bluewater_boat") as Button
	var primary := _buy_button if available.has(_buy_button) else _return_button
	_set_direction_neighbors(skiff, _return_button, primary, _return_button, offshore)
	_set_direction_neighbors(offshore, skiff, primary, skiff, bluewater)
	_set_direction_neighbors(bluewater, offshore, primary, offshore, primary)
	if primary == _buy_button:
		_set_direction_neighbors(_buy_button, bluewater, _return_button, bluewater, _return_button)
		_set_direction_neighbors(_return_button, _buy_button, skiff, _buy_button, skiff)
	else:
		_set_direction_neighbors(_return_button, bluewater, skiff, bluewater, skiff)


func _set_direction_neighbors(
	control: Control,
	left: Control,
	right: Control,
	top: Control,
	bottom: Control
) -> void:
	if control == null or control.focus_mode == Control.FOCUS_NONE:
		return
	control.focus_neighbor_left = control.get_path_to(left)
	control.focus_neighbor_right = control.get_path_to(right)
	control.focus_neighbor_top = control.get_path_to(top)
	control.focus_neighbor_bottom = control.get_path_to(bottom)


func _return_to_harbor() -> void:
	navigate("harbor")


func _select_boat(boat_id: String) -> void:
	if GameData.get_boat(boat_id).is_empty():
		return
	_selected_boat_id = boat_id
	_refresh()


func _buy_selected_boat() -> void:
	var focus_fallback := _boat_card_buttons.get(_selected_boat_id) as Button
	var result := PlayerProgress.buy_boat(_selected_boat_id)
	_footer_label.text = String(result.get("message", "購入できませんでした。"))
	_refresh()
	if bool(result.get("ok", false)) and focus_fallback != null:
		focus_fallback.call_deferred("grab_focus")


func _default_boat_id() -> String:
	for boat_id in GameData.get_all_boat_ids():
		if not PlayerProgress.has_boat(boat_id):
			return boat_id
	var ids := GameData.get_all_boat_ids()
	return ids[ids.size() - 1] if not ids.is_empty() else ""


func _boat_card_status_text(boat_id: String) -> String:
	var boat := GameData.get_boat(boat_id)
	if PlayerProgress.has_boat(boat_id):
		return "登録済み"
	var price := int(boat.get("price", 0))
	if PlayerProgress.money >= price:
		return "購入可能"
	return "資金不足"


func _boat_card_price_text(boat_id: String) -> String:
	var boat := GameData.get_boat(boat_id)
	if PlayerProgress.has_boat(boat_id):
		return "所持"
	return "%s G" % ScreenBase.format_money(maxi(int(boat.get("price", 0)), 0))


func _boat_compact_range_text(rank: int) -> String:
	var names := _boat_access_spot_names(rank)
	if names.is_empty():
		return "港周辺"
	return "到達 %s" % " / ".join(PackedStringArray(names))


func _boat_status_color(boat_id: String) -> Color:
	if PlayerProgress.has_boat(boat_id):
		return Palette.SHIPYARD_STATUS_OWNED_TEXT
	var boat := GameData.get_boat(boat_id)
	if PlayerProgress.money >= int(boat.get("price", 0)):
		return Palette.SHIPYARD_STATUS_READY_TEXT
	return Palette.SHIPYARD_STATUS_SHORTAGE_TEXT


func _boat_access_spot_names(rank: int) -> Array[String]:
	var names: Array[String] = []
	for spot_id in GameData.get_all_fishing_spot_ids():
		var spot := GameData.get_fishing_spot(spot_id)
		var required_rank := int(spot.get("required_boat_rank", GameData.NO_BOAT_RANK))
		if required_rank > GameData.NO_BOAT_RANK and required_rank <= rank:
			names.append(String(spot.get("short_name", spot.get("name", spot_id))))
	return names


func _accessible_offshore_count(rank: int) -> int:
	var count := 0
	for spot_id in GameData.get_all_fishing_spot_ids():
		var spot := GameData.get_fishing_spot(spot_id)
		var required_rank := int(spot.get("required_boat_rank", GameData.NO_BOAT_RANK))
		if required_rank > GameData.NO_BOAT_RANK and required_rank <= rank:
			count += 1
	return count


func _route_hint_text(rank: int) -> String:
	var names := _boat_access_spot_names(rank)
	if names.is_empty():
		return "港周辺の航路のみ"
	return "この船で到達: %s" % "、".join(PackedStringArray(names))

func _texture_rect(path: String) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = ShowcaseAssets.load_texture(path)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _transparent_button(callback: Callable) -> Button:
	var button := Button.new()
	button.text = ""
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_apply_empty_button_style(button)
	button.pressed.connect(callback)
	return button


func _image_text_button(text: String, callback: Callable, font_size: int) -> Button:
	var button := _transparent_button(callback)
	button.text = text
	button.add_theme_font_override("font", GameFontsScript.bold(get_theme_default_font()))
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Palette.SHIPYARD_BUTTON_TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Palette.SHIPYARD_BUTTON_PRESSED_TEXT)
	button.add_theme_color_override("font_disabled_color", Palette.SHIPYARD_BUTTON_DISABLED_TEXT)
	button.add_theme_color_override("font_outline_color", Palette.SHIPYARD_LABEL_OUTLINE)
	button.add_theme_constant_override("outline_size", 3)
	return button


func _apply_empty_button_style(button: Button) -> void:
	for style_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(style_name, StyleBoxEmpty.new())


func _selection_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.SHIPYARD_SELECTION_FILL
	style.border_color = Palette.SHIPYARD_SELECTION_BORDER
	style.set_border_width_all(3)
	style.set_corner_radius_all(4)
	style.shadow_color = Color(Palette.SHIPYARD_SELECTION_SHADOW, 0.28)
	style.shadow_size = 6
	style.shadow_offset = Vector2.ZERO
	return style


func _status_badge_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.content_margin_left = 6.0
	style.content_margin_top = 2.0
	style.content_margin_right = 6.0
	style.content_margin_bottom = 2.0
	style.shadow_color = Palette.SHIPYARD_STYLE_SHADOW
	style.shadow_size = 3
	style.shadow_offset = Vector2(0.0, 1.0)
	return style


func _shipyard_label(
	text: String,
	font_size: int,
	color: Color,
	bold := false,
	outline := 0,
	outline_color := Palette.SHIPYARD_LABEL_OUTLINE
) -> Label:
	return make_screen_label(text, font_size, color, bold, outline, outline_color, Palette.SHIPYARD_LABEL_SHADOW, true)
