extends ScreenBase

const HarborBackdropScript = preload("res://src/ui/components/harbor_backdrop.gd")
const FightFishAssets = preload("res://src/ui/fight_fish_assets.gd")

const HARBOR_TOP_FRAME_PATH := "res://assets/showcase/harbor/harbor_top_frame.png"
const HARBOR_MAIN_FRAME_PATH := "res://assets/showcase/harbor/harbor_main_frame.png"
const HARBOR_MENU_FRAME_PATH := "res://assets/showcase/harbor/harbor_menu_frame.png"
const HARBOR_FOOTER_FRAME_PATH := "res://assets/showcase/harbor/harbor_footer_frame.png"
const HARBOR_SCENE_WINDOW_PATH := "res://assets/showcase/harbor/harbor_scene_window.png"
const HARBOR_PARCHMENT_CARD_PATH := "res://assets/showcase/harbor/harbor_parchment_card.png"
const HARBOR_BUTTON_PATH := "res://assets/showcase/harbor/harbor_facility_card.png"
const HARBOR_BUTTON_HOVER_PATH := "res://assets/showcase/harbor/harbor_facility_card_hover.png"
const HARBOR_BUTTON_PRIMARY_PATH := "res://assets/showcase/harbor/harbor_facility_card_primary.png"
const ICON_FISHING_PATH := "res://assets/showcase/common/nav_fishing_icon.png"
const ICON_COOKING_PATH := "res://assets/showcase/common/nav_cooking_icon.png"
const ICON_MARKET_PATH := "res://assets/showcase/common/nav_market_icon.png"
const ICON_SHOP_PATH := "res://assets/showcase/common/nav_shop_icon.png"
const ICON_SHIPYARD_PATH := "res://assets/showcase/common/nav_shipyard_icon.png"
const ICON_STATUS_PATH := "res://assets/showcase/common/nav_status_icon.png"
const ICON_TITLE_PATH := "res://assets/showcase/common/nav_title_icon.png"
const ICON_QUEST_PATH := "res://assets/showcase/common/nav_status_icon.png"

var _status_label: Label
var _context_label: Label
var _top_level_label: Label
var _top_money_label: Label
var _top_rod_label: Label
var _top_exp_label: Label
var _buff_name_label: Label
var _buff_text_label: Label
var _facility_detail_title_label: Label
var _facility_detail_body_label: Label
var _preparation_body_label: Label
var _shark_lure_button: Button
var _selected_shark_lure_fish_id := ""
var _time_slot_buttons: Dictionary = {}
var _time_slot_grade_overlay: ColorRect


func _build_screen() -> void:
	_resolve_shark_lure_selection()
	var backdrop := HarborBackdropScript.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	move_child(backdrop, 0)
	_build_time_slot_grade_overlay()

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_build_top_bar(root)
	_build_main_panel(root)
	_build_facility_menu(root)
	_build_footer(root)
	_refresh_labels()


func _build_top_bar(root: Control) -> void:
	var top := _anchored_control(root, 0.020, 0.028, 0.980, 0.150)
	var frame := _texture_rect(HARBOR_TOP_FRAME_PATH)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top.add_child(frame)

	var location := _harbor_label("南の島・港", 32, Palette.HARBOR_LOCATION_TEXT, true, 4, Palette.HARBOR_LOCATION_OUTLINE)
	location.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	location.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(top, location, 0.026, 0.15, 0.265, 0.67)

	_context_label = _harbor_label("", 15, Palette.HARBOR_CONTEXT_TEXT, false, 2, Palette.HARBOR_LABEL_OUTLINE)
	_context_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_context_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(top, _context_label, 0.030, 0.62, 0.395, 0.92)

	_top_level_label = _top_metric(top, 0.395, 0.145, 0.485, 0.825, "Lv.1")
	_top_exp_label = _top_metric(top, 0.495, 0.145, 0.660, 0.825, "EXP 0 / 60")
	_top_money_label = _top_metric(top, 0.670, 0.145, 0.810, 0.825, "500 G")
	_top_rod_label = _top_metric(top, 0.820, 0.145, 0.972, 0.825, "入門竿")


func _build_main_panel(root: Control) -> void:
	var main := _anchored_control(root, 0.026, 0.170, 0.660, 0.882)
	var frame := _texture_rect(HARBOR_MAIN_FRAME_PATH)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.add_child(frame)

	var scene := _texture_rect(HARBOR_SCENE_WINDOW_PATH)
	scene.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_place_control(main, scene, 0.060, 0.068, 0.940, 0.432)

	var scene_shadow := ColorRect.new()
	scene_shadow.color = Palette.HARBOR_SCENE_SHADOW
	scene_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(main, scene_shadow, 0.060, 0.068, 0.940, 0.432)

	var scene_title := _harbor_label("潮風が吹く、小さな漁港", 34, Palette.HARBOR_SCENE_TITLE, true, 4, Palette.HARBOR_SCENE_TITLE_OUTLINE)
	scene_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(main, scene_title, 0.090, 0.104, 0.910, 0.205)

	var scene_text := _harbor_label(
		"沖では魚影が濃くなっている。\n釣った魚は市場で売るか、調理場で食べて成長できる。\n準備ができたら海へ出よう。",
		17,
		Palette.HARBOR_SCENE_TEXT,
		false,
		2,
		Palette.HARBOR_SCENE_TEXT_OUTLINE
	)
	scene_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	scene_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place_control(main, scene_text, 0.130, 0.215, 0.870, 0.415)

	_build_preparation_card(main)
	_build_buff_card(main)


func _build_preparation_card(main: Control) -> void:
	var card := _anchored_control(main, 0.066, 0.452, 0.934, 0.704)
	var frame := _texture_rect(HARBOR_PARCHMENT_CARD_PATH)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_child(frame)

	var icon := _icon_rect(ICON_FISHING_PATH)
	_place_control(card, icon, 0.030, 0.145, 0.112, 0.575)

	var title := _harbor_label("今日の支度", 15, Palette.HARBOR_PARCHMENT_TITLE, true, 0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(card, title, 0.140, 0.070, 0.930, 0.270)

	_preparation_body_label = _harbor_label("", 16, Palette.HARBOR_PARCHMENT_BODY, true, 0)
	_preparation_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_preparation_body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_preparation_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preparation_body_label.clip_text = true
	_place_control(card, _preparation_body_label, 0.140, 0.285, 0.675, 0.555)

	_shark_lure_button = make_button("", _cycle_shark_lure_fish, 0.0, false)
	_shark_lure_button.add_theme_font_size_override("font_size", 13)
	_place_control(card, _shark_lure_button, 0.700, 0.215, 0.940, 0.555)
	_build_time_slot_selector(card)


func _build_buff_card(main: Control) -> void:
	var card := _anchored_control(main, 0.066, 0.735, 0.934, 0.895)
	var frame := _texture_rect(HARBOR_PARCHMENT_CARD_PATH)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_child(frame)

	var icon := _icon_rect(ICON_COOKING_PATH)
	_place_control(card, icon, 0.030, 0.160, 0.118, 0.840)

	var title := _harbor_label("次の釣行の食事効果", 15, Palette.HARBOR_PARCHMENT_TITLE, true, 0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(card, title, 0.145, 0.100, 0.930, 0.365)

	_buff_name_label = _harbor_label("", 20, Palette.HARBOR_BUFF_NAME, true, 0)
	_buff_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_buff_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(card, _buff_name_label, 0.145, 0.345, 0.930, 0.635)

	_buff_text_label = _harbor_label("", 15, Palette.HARBOR_BUFF_BODY, false, 0)
	_buff_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_buff_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(card, _buff_text_label, 0.145, 0.625, 0.930, 0.900)


func _build_time_slot_selector(card: Control) -> void:
	var label := _harbor_label("時間帯", 13, Palette.HARBOR_PARCHMENT_TITLE, true, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(card, label, 0.140, 0.655, 0.255, 0.900)
	var ids := GameData.get_all_time_slot_ids()
	var left := 0.270
	var right := 0.940
	var gap := 0.012
	var width := (right - left - gap * float(ids.size() - 1)) / float(ids.size())
	for index in range(ids.size()):
		var time_slot_id := String(ids[index])
		var button := make_button("", _select_time_slot.bind(time_slot_id), 0.0, false)
		button.add_theme_font_size_override("font_size", 12)
		button.clip_text = true
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_time_slot_buttons[time_slot_id] = button
		var x0 := left + float(index) * (width + gap)
		_place_control(card, button, x0, 0.625, x0 + width, 0.915)


func _preparation_card_text() -> String:
	var megalodon_omen := _megalodon_omen_text()
	if not megalodon_omen.is_empty():
		return megalodon_omen
	var hint := _nushi_hint_text()
	if hint.is_empty():
		return "釣る → 売る／料理する → 強化\n餌魚は危険海域で投げるときに使う"
	return "釣る → 売る／料理する → 強化\n目撃談：%s" % hint


func _megalodon_omen_text() -> String:
	if int(PlayerProgress.caught_counts.get("megalodon", 0)) > 0:
		return ""
	if not GameData.is_megalodon_unlocked(PlayerProgress.level, PlayerProgress.shark_bonds):
		return ""
	return "生簀のサメたちが、深海の何かに怯えている……\nヌシ級の餌魚を危険海域へ捧げよう"


func _nushi_hint_text() -> String:
	var candidates: Array[String] = []
	for spot_id in GameData.NORMAL_FISHING_SPOT_IDS:
		var spot := GameData.get_fishing_spot(spot_id)
		var nushi: Dictionary = spot.get("nushi", {})
		var fish_id := String(nushi.get("fish_id", ""))
		if fish_id.is_empty():
			continue
		if int(PlayerProgress.caught_counts.get(fish_id, 0)) <= 0:
			var hint := String(nushi.get("hint", ""))
			if not hint.is_empty():
				candidates.append(hint)
	if candidates.is_empty():
		return ""
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return candidates[rng.randi_range(0, candidates.size() - 1)]


func _resolve_shark_lure_selection() -> void:
	_selected_shark_lure_fish_id = String(route_payload.get("shark_lure_fish_id", ""))
	if not _eligible_shark_lure_fish_ids().has(_selected_shark_lure_fish_id):
		_selected_shark_lure_fish_id = ""


func _refresh_preparation_card() -> void:
	if _preparation_body_label != null:
		_preparation_body_label.text = _preparation_card_text()
	if _shark_lure_button == null:
		return
	var unlocked := PlayerProgress.can_access_fishing_spot("danger_reef")
	var ids := _eligible_shark_lure_fish_ids()
	if not unlocked:
		_selected_shark_lure_fish_id = ""
		_shark_lure_button.text = "危険海域で解放"
		_shark_lure_button.disabled = true
		return
	if ids.is_empty():
		_selected_shark_lure_fish_id = ""
		_shark_lure_button.text = "餌魚なし"
		_shark_lure_button.disabled = true
		return
	_shark_lure_button.disabled = false
	if _selected_shark_lure_fish_id.is_empty():
		_shark_lure_button.text = "餌魚を選ぶ"
		return
	var fish := GameData.get_fish(_selected_shark_lure_fish_id)
	var count := PlayerProgress.fish_count(_selected_shark_lure_fish_id)
	_shark_lure_button.text = "%s x%d" % [String(fish.get("name", _selected_shark_lure_fish_id)), count]


func _select_time_slot(time_slot_id: String) -> void:
	if not PlayerProgress.select_time_slot(time_slot_id):
		return
	_refresh_labels()


func _refresh_time_slot_buttons() -> void:
	for time_slot_id in GameData.get_all_time_slot_ids():
		var button := _time_slot_buttons.get(time_slot_id, null) as Button
		if button == null:
			continue
		var time_slot := GameData.get_time_slot(time_slot_id)
		var label := String(time_slot.get("name", time_slot_id))
		var unlock_level := int(time_slot.get("unlock_level", 1))
		var locked := not GameData.is_time_slot_unlocked(time_slot_id, PlayerProgress.level)
		var selected := PlayerProgress.selected_time_slot_id == time_slot_id
		button.disabled = locked
		button.theme_type_variation = "GoldButton" if selected and not locked else ""
		if locked:
			button.text = "Lv.%dで解放" % unlock_level
		elif selected:
			button.text = "%s 選択中" % label
		else:
			button.text = label


func _cycle_shark_lure_fish() -> void:
	var ids := _eligible_shark_lure_fish_ids()
	if ids.is_empty() or not PlayerProgress.can_access_fishing_spot("danger_reef"):
		return
	var current_index := ids.find(_selected_shark_lure_fish_id)
	if current_index < 0:
		_selected_shark_lure_fish_id = ids[0]
	elif current_index >= ids.size() - 1:
		_selected_shark_lure_fish_id = ""
	else:
		_selected_shark_lure_fish_id = ids[current_index + 1]
	_refresh_preparation_card()


func _eligible_shark_lure_fish_ids() -> Array[String]:
	var ids: Array[String] = []
	for fish_id_variant in PlayerProgress.inventory.keys():
		var fish_id := String(fish_id_variant)
		if PlayerProgress.fish_count(fish_id) <= 0:
			continue
		var fish := GameData.get_fish(fish_id)
		if fish.is_empty() or bool(fish.get("shark", false)):
			continue
		ids.append(fish_id)
	ids.sort_custom(
		func(a: String, b: String) -> bool:
			var fish_a := GameData.get_fish(a)
			var fish_b := GameData.get_fish(b)
			var price_a := int(fish_a.get("sell_price", 0))
			var price_b := int(fish_b.get("sell_price", 0))
			if price_a == price_b:
				return String(fish_a.get("name", a)) < String(fish_b.get("name", b))
			return price_a > price_b
	)
	return ids


func _fishing_spots_payload() -> Dictionary:
	if _selected_shark_lure_fish_id.is_empty():
		return {}
	return {"shark_lure_fish_id": _selected_shark_lure_fish_id}


func _has_caught_raiseable_shark() -> bool:
	for shark_id in GameData.get_raiseable_shark_ids():
		if int(PlayerProgress.caught_counts.get(shark_id, 0)) > 0:
			return true
	return false


func _can_open_shark_pen() -> bool:
	return PlayerProgress.level >= 30 and _has_caught_raiseable_shark()


func _open_shark_pen() -> void:
	if not _can_open_shark_pen():
		_set_facility_detail("サメの生簀", "Lv.30／危険海域で解放", false)
		return
	navigate("shark_pen")


func _build_facility_menu(root: Control) -> void:
	var menu := _anchored_control(root, 0.675, 0.170, 0.974, 0.882)
	var frame := _texture_rect(HARBOR_MENU_FRAME_PATH)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(frame)

	var header := _harbor_label("港の施設", 27, Palette.HARBOR_MENU_HEADER, true, 3, Palette.HARBOR_MENU_OUTLINE)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(menu, header, 0.100, 0.030, 0.900, 0.120)

	_build_facility_detail_panel(menu)

	var button_height := 0.058
	var row_step := 0.064
	var row_top := 0.126
	var shark_pen_locked := not _can_open_shark_pen()
	var shark_pen_detail := "捕獲したサメを育てる" if not shark_pen_locked else "Lv.30／危険海域で解放"
	_build_facility_button(menu, row_top + row_step * 0.0, "釣り場へ向かう", "狙う魚に合わせてポイントを選ぶ", ICON_FISHING_PATH, func() -> void: navigate("fishing_spots", _fishing_spots_payload()), true, button_height)
	_build_facility_button(menu, row_top + row_step * 1.0, "サメの生簀", shark_pen_detail, FightFishAssets.card_portrait_path({"id": "nekozame"}), _open_shark_pen, false, button_height, shark_pen_locked)
	_build_facility_button(menu, row_top + row_step * 2.0, "依頼ボード", "釣果を届けて報酬を受け取る", ICON_QUEST_PATH, func() -> void: navigate("quest_board"), false, button_height)
	_build_facility_button(menu, row_top + row_step * 3.0, "調理場", "魚を料理して食事にする", ICON_COOKING_PATH, func() -> void: navigate("cooking"), false, button_height)
	_build_facility_button(menu, row_top + row_step * 4.0, "魚市場", "釣果を売って資金にする", ICON_MARKET_PATH, func() -> void: navigate("market"), false, button_height)
	_build_facility_button(menu, row_top + row_step * 5.0, "釣具店", "竿を購入・装備する", ICON_SHOP_PATH, func() -> void: navigate("shop"), false, button_height)
	_build_facility_button(menu, row_top + row_step * 6.0, "船着き場", "船を購入して沖へ出る", ICON_SHIPYARD_PATH, func() -> void: navigate("shipyard"), false, button_height)
	_build_facility_button(menu, row_top + row_step * 7.0, "ステータス", "成長と装備を確認する", ICON_STATUS_PATH, func() -> void: navigate("status"), false, button_height)
	_build_facility_button(menu, row_top + row_step * 8.0, "魚図鑑", "釣った魚の記録を見る", FightFishAssets.card_portrait_path({"id": "aji"}), func() -> void: navigate("fish_book"), false, button_height)
	_build_facility_button(menu, row_top + row_step * 9.0, "タイトルへ戻る", "進行を保存して戻る", ICON_TITLE_PATH, _return_to_title, false, button_height)
	_set_facility_detail("釣り場へ向かう", "狙う魚に合わせてポイントを選ぶ", true)


func _build_facility_detail_panel(parent: Control) -> void:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override(
		"panel",
		_make_flat_panel_style(Palette.HARBOR_DETAIL_PANEL_FILL, Palette.HARBOR_DETAIL_PANEL_BORDER, 8, 2)
	)
	_place_control(parent, panel, 0.088, 0.802, 0.912, 0.956)

	_facility_detail_title_label = _harbor_label("", 15, Palette.HARBOR_MENU_HEADER, true, 2, Palette.HARBOR_MENU_OUTLINE)
	_facility_detail_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_facility_detail_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_facility_detail_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(panel, _facility_detail_title_label, 0.055, 0.100, 0.945, 0.430)

	_facility_detail_body_label = _harbor_label("", 13, Palette.HARBOR_DETAIL_BODY_TEXT, false, 1, Palette.HARBOR_LABEL_OUTLINE)
	_facility_detail_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_facility_detail_body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_facility_detail_body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(panel, _facility_detail_body_label, 0.055, 0.440, 0.945, 0.850)


func _build_facility_button(
	parent: Control,
	top: float,
	title_text: String,
	body_text: String,
	icon_path: String,
	callback: Callable,
	primary := false,
	height := 0.108,
	locked := false
) -> void:
	var button := make_button("", callback)
	button.custom_minimum_size = Vector2.ZERO
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.focus_mode = Control.FOCUS_ALL
	button.clip_contents = true
	_apply_facility_button_skin(button, primary)
	_place_control(parent, button, 0.088, top, 0.912, top + height)
	button.mouse_entered.connect(func() -> void: _set_facility_detail(title_text, body_text, primary))
	button.focus_entered.connect(func() -> void: _set_facility_detail(title_text, body_text, primary))

	var accent := Panel.new()
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	accent.add_theme_stylebox_override(
		"panel",
		_make_flat_panel_style(Palette.HARBOR_FACILITY_ACCENT_PRIMARY if primary else Palette.HARBOR_FACILITY_ACCENT_SECONDARY, Color.TRANSPARENT, 3, 0)
	)
	_place_control(button, accent, 0.023, 0.230, 0.039, 0.770)

	var icon_plate := Panel.new()
	icon_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_plate.add_theme_stylebox_override(
		"panel",
		_make_flat_panel_style(
			Palette.HARBOR_FACILITY_ICON_PRIMARY_FILL if primary else Palette.HARBOR_FACILITY_ICON_SECONDARY_FILL,
			Palette.HARBOR_FACILITY_ICON_PRIMARY_BORDER if primary else Palette.HARBOR_FACILITY_ICON_SECONDARY_BORDER,
			6,
			1
		)
	)
	_place_control(button, icon_plate, 0.055, 0.160, 0.165, 0.840)

	var icon := _icon_rect(icon_path)
	icon.modulate = Palette.HARBOR_ICON_MODULATE
	_place_control(button, icon, 0.070, 0.210, 0.150, 0.790)

	var title_font_size := 19 if height < 0.064 else 21
	var title_color := (
		Palette.HARBOR_DETAIL_BODY_SECONDARY
		if locked
		else (Palette.HARBOR_FACILITY_PRIMARY_TEXT if primary else Palette.HARBOR_FACILITY_SECONDARY_TEXT)
	)
	var title := _harbor_label(title_text, title_font_size, title_color, true, 2 if primary else 1, Palette.HARBOR_FACILITY_PRIMARY_OUTLINE if primary else Palette.HARBOR_FACILITY_SECONDARY_OUTLINE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(button, title, 0.205, 0.120, 0.560 if locked else 0.900, 0.880)

	if locked:
		var lock := _harbor_label(body_text, 8, Palette.HARBOR_DETAIL_BODY_SECONDARY, true, 1, Palette.HARBOR_LABEL_OUTLINE)
		lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lock.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lock.clip_text = true
		lock.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place_control(button, lock, 0.545, 0.160, 0.930, 0.840)


func _set_facility_detail(title_text: String, body_text: String, primary := false) -> void:
	if _facility_detail_title_label == null or _facility_detail_body_label == null:
		return
	_facility_detail_title_label.text = title_text
	_facility_detail_body_label.text = body_text
	_facility_detail_title_label.add_theme_color_override("font_color", Palette.HARBOR_MENU_HEADER if primary else Palette.HARBOR_DETAIL_TITLE_SECONDARY)
	_facility_detail_body_label.add_theme_color_override("font_color", Palette.HARBOR_DETAIL_BODY_TEXT if primary else Palette.HARBOR_DETAIL_BODY_SECONDARY)


func _build_footer(root: Control) -> void:
	var footer := _anchored_control(root, 0.026, 0.902, 0.974, 0.974)
	var frame := _texture_rect(HARBOR_FOOTER_FRAME_PATH)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	footer.add_child(frame)

	_status_label = _harbor_label("", 17, Palette.HARBOR_FOOTER_TEXT, false, 2, Palette.HARBOR_LABEL_OUTLINE)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(footer, _status_label, 0.035, 0.050, 0.965, 0.950)


func _refresh_labels() -> void:
	_refresh_preparation_card()
	var normalized_time_slot_id := String(
		GameData.get_time_slot(PlayerProgress.selected_time_slot_id).get("id", GameData.DEFAULT_TIME_SLOT_ID)
	)
	if not GameData.is_time_slot_unlocked(normalized_time_slot_id, PlayerProgress.level):
		normalized_time_slot_id = GameData.DEFAULT_TIME_SLOT_ID
	PlayerProgress.selected_time_slot_id = normalized_time_slot_id
	_refresh_time_slot_buttons()
	_refresh_time_slot_grade_overlay()
	var fish_total := 0
	for count in PlayerProgress.inventory.values():
		fish_total += int(count)
	var next_text := (
		"MAX"
		if PlayerProgress.level >= GameData.MAX_LEVEL
		else "%d / %d EXP" % [PlayerProgress.exp, PlayerProgress.exp_to_next_level()]
	)
	var rod_name := String(GameData.get_rod(PlayerProgress.equipped_rod_id).get("name", "入門竿"))
	_top_level_label.text = "Lv.%d" % PlayerProgress.level
	_top_exp_label.text = "EXP %s" % next_text.replace(" EXP", "")
	_top_money_label.text = "%s G" % ScreenBase.format_money(PlayerProgress.money)
	_top_rod_label.text = rod_name
	_context_label.text = "時間帯：%s　潮位：満ち始め　風：弱" % String(
		GameData.get_time_slot(PlayerProgress.selected_time_slot_id).get("name", "日中")
	)
	_status_label.text = (
		"クーラーボックス：%d匹　｜　食経験値：%s　｜　プレイ時間：%s"
		% [
			fish_total,
			next_text,
			format_play_time(PlayerProgress.play_seconds),
		]
	)
	if PlayerProgress.pending_buff.is_empty():
		_buff_name_label.text = "食事効果：なし"
		_buff_text_label.text = "調理場で料理を食べると、次の釣行が有利になる。"
	else:
		_buff_name_label.text = String(PlayerProgress.pending_buff.get("name", "料理"))
		_buff_text_label.text = String(PlayerProgress.pending_buff.get("text", ""))


func _build_time_slot_grade_overlay() -> void:
	_time_slot_grade_overlay = ColorRect.new()
	_time_slot_grade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_time_slot_grade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_time_slot_grade_overlay)
	_refresh_time_slot_grade_overlay()


func _refresh_time_slot_grade_overlay() -> void:
	if _time_slot_grade_overlay == null:
		return
	var time_slot := GameData.get_time_slot(PlayerProgress.selected_time_slot_id)
	match String(time_slot.get("grade", "none")):
		"warm":
			_time_slot_grade_overlay.color = Palette.HARBOR_TIME_GRADE_WARM
		"cool":
			_time_slot_grade_overlay.color = Palette.HARBOR_TIME_GRADE_COOL
		_:
			_time_slot_grade_overlay.color = Palette.FISHING_TIME_GRADE_CLEAR


func _return_to_title() -> void:
	PlayerProgress.save_game()
	navigate("title")


func _top_metric(parent: Control, left: float, top: float, right: float, bottom: float, value: String) -> Label:
	var label := _harbor_label(value, 17, Palette.HARBOR_TOP_METRIC_TEXT, true, 2, Palette.HARBOR_LABEL_OUTLINE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(parent, label, left, top, right, bottom)
	return label

func _texture_rect(path: String) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = _load_texture_if_exists(path)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _icon_rect(path: String) -> TextureRect:
	var icon := _texture_rect(path)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon


func _load_texture_if_exists(path: String) -> Texture2D:
	if ResourceLoader.exists(path) or FileAccess.file_exists(path):
		return load(path) as Texture2D
	return null


func _harbor_label(
	text: String,
	font_size: int,
	color: Color,
	bold := false,
	outline := 0,
	outline_color := Palette.HARBOR_LABEL_OUTLINE
) -> Label:
	return make_screen_label(text, font_size, color, bold, outline, outline_color, Palette.HARBOR_LABEL_SHADOW)


func _apply_facility_button_skin(button: Button, primary: bool) -> void:
	var normal_path := HARBOR_BUTTON_PRIMARY_PATH if primary else HARBOR_BUTTON_PATH
	var hover_path := HARBOR_BUTTON_PRIMARY_PATH if primary else HARBOR_BUTTON_HOVER_PATH
	var normal := _make_button_style(normal_path)
	var hover := _make_button_style(hover_path)
	if normal == null or hover == null:
		return
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_font_override("font", GameFontsScript.bold(get_theme_default_font()))
	button.add_theme_color_override("font_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_hover_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_pressed_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_disabled_color", Color.TRANSPARENT)
	button.add_theme_constant_override("outline_size", 0)
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func _make_button_style(path: String) -> StyleBoxTexture:
	var texture := _load_texture_if_exists(path)
	if texture == null:
		return null
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 50
	style.texture_margin_top = 28
	style.texture_margin_right = 50
	style.texture_margin_bottom = 28
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.content_margin_left = 22.0
	style.content_margin_top = 8.0
	style.content_margin_right = 22.0
	style.content_margin_bottom = 8.0
	return style


func _make_flat_panel_style(
	bg_color: Color,
	border_color: Color,
	radius: int,
	border_width := 1
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.content_margin_left = 6.0
	style.content_margin_top = 4.0
	style.content_margin_right = 6.0
	style.content_margin_bottom = 4.0
	return style
