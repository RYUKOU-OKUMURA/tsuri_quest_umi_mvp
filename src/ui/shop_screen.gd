extends "res://src/ui/screen_base.gd"

const GameFontsScript = preload("res://src/ui/game_fonts.gd")
const PlayerStatusBarScript = preload("res://src/ui/components/player_status_bar.gd")

const BG_PATH := "res://assets/showcase/tackle_shop/shop_bg.png"
const HEADER_FRAME_PATH := "res://assets/showcase/tackle_shop/shop_header_frame.png"
const TITLE_SIGN_PATH := "res://assets/showcase/tackle_shop/shop_title_sign.png"
const DETAIL_FRAME_PATH := "res://assets/showcase/tackle_shop/shop_detail_frame.png"
const NOTICE_FRAME_PATH := "res://assets/showcase/tackle_shop/shop_notice_frame.png"
const CARD_FRAME_PATH := "res://assets/showcase/tackle_shop/shop_card_frame.png"
const CARD_SELECTED_FRAME_PATH := "res://assets/showcase/tackle_shop/shop_card_selected_frame.png"
const TAB_FRAME_PATH := "res://assets/showcase/tackle_shop/shop_tab_frame.png"
const TAB_ACTIVE_FRAME_PATH := "res://assets/showcase/tackle_shop/shop_tab_active_frame.png"
const ITEM_ICON_SHEET_PATH := "res://assets/showcase/tackle_shop/shop_item_icon_sheet.png"
const BAIT_ICON_SHEET_PATH := "res://assets/showcase/tackle_shop/shop_bait_icon_sheet.png"
const ACTION_BUTTON_FRAME_PATH := "res://assets/showcase/common/action_button_frame.png"

const HEADER_RECT := Rect2(18.0, 14.0, 1244.0, 88.0)
const LIST_RECT := Rect2(34.0, 118.0, 724.0, 500.0)
const DETAIL_RECT := Rect2(784.0, 118.0, 462.0, 500.0)
const NOTICE_RECT := Rect2(34.0, 636.0, 724.0, 60.0)
const FOOTER_ACTION_RECT := Rect2(784.0, 636.0, 222.0, 60.0)
const FOOTER_RETURN_RECT := Rect2(1024.0, 636.0, 222.0, 60.0)
const CARD_SIZE := Vector2(220.0, 144.0)
const CARD_GAP := Vector2(12.0, 18.0)
const ICON_CELL := 96.0
const BAIT_CELL := 64.0

const ROD_ICON_INDEX := {
	"starter": 0,
	"iso": 1,
	"offshore": 2,
}

const RIG_ICON_INDEX := {
	"sabiki": 3,
	"uki": 4,
	"chokusen": 5,
	"nomase": 6,
	"jigging": 7,
	"kani": 8,
}

const BAIT_ICON_INDEX := {
	"アミエビ": 0,
	"オキアミ": 1,
	"練りエサ": 2,
	"イソメ": 3,
	"貝": 4,
	"アサリ": 5,
	"小魚": 6,
	"大型ルアー": 7,
	"岩ガニ": 8,
}

var _shop_mode := "rod"
var _selected_item_id := "starter"
var _result_message := "竿と仕掛けをそろえ、狙う魚に合わせて装備を変えます。"

var _item_icon_sheet: Texture2D
var _bait_icon_sheet: Texture2D

var _status_bar: Control
var _rig_status_label: Label
var _rod_tab_button: Button
var _rig_tab_button: Button
var _cards_layer: Control
var _detail_icon: TextureRect
var _detail_title_label: Label
var _detail_status_label: Label
var _detail_description_label: Label
var _detail_stats_box: Control
var _detail_bait_box: HBoxContainer
var _detail_hint_label: Label
var _action_button: Button
var _return_button: Button
var _result_label: Label
var _detail_stat_row_index := 0


func _build_screen() -> void:
	_load_assets()
	_build_background()

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	_build_header(root)
	_build_item_panel(root)
	_build_detail_panel(root)
	_build_footer(root)
	_refresh()


func _load_assets() -> void:
	_item_icon_sheet = ShowcaseAssetsScript.load_texture(ITEM_ICON_SHEET_PATH)
	_bait_icon_sheet = ShowcaseAssetsScript.load_texture(BAIT_ICON_SHEET_PATH)


func _build_background() -> void:
	var bg := ShowcaseAssetsScript.texture_rect(BG_PATH)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)


func _build_header(parent: Control) -> void:
	var header := _texture_panel(parent, HEADER_RECT, HEADER_FRAME_PATH)
	header.name = "TackleShopHeader"

	var sign := ShowcaseAssetsScript.texture_rect(TITLE_SIGN_PATH)
	_place_control(header, sign, Rect2(18.0, -2.0, 430.0, 88.0))

	var title := _make_text("釣具店", 38, Palette.TEXT_OUTLINE_LIGHT, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, 2)
	title.add_theme_color_override("font_color", Palette.GOLD_BRIGHT)
	_place_control(header, title, Rect2(94.0, 10.0, 260.0, 58.0))

	var subtitle := _make_text("竿と仕掛けを整える", 16, Palette.TEXT_BONE, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, 1)
	_place_control(header, subtitle, Rect2(390.0, 18.0, 220.0, 24.0))

	_rig_status_label = _make_text("", 17, Palette.TEXT_BONE, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, 1)
	_place_control(header, _rig_status_label, Rect2(390.0, 48.0, 230.0, 28.0))

	_status_bar = PlayerStatusBarScript.new()
	_status_bar.name = "TackleShopPlayerStatusBar"
	_place_control(header, _status_bar, Rect2(638.0, 15.0, 584.0, 60.0))


func _build_item_panel(parent: Control) -> void:
	var panel := Control.new()
	panel.name = "TackleShopItemPanel"
	panel.clip_contents = true
	_place_control(parent, panel, LIST_RECT)

	_rod_tab_button = _make_tab_button("rod", "竿")
	_place_control(panel, _rod_tab_button, Rect2(14.0, 4.0, 168.0, 50.0))
	_rig_tab_button = _make_tab_button("rig", "仕掛け")
	_place_control(panel, _rig_tab_button, Rect2(194.0, 4.0, 168.0, 50.0))

	var caption := _make_text("商品を選ぶ", 22, Palette.TEXT_BONE, HORIZONTAL_ALIGNMENT_RIGHT, VERTICAL_ALIGNMENT_CENTER, 1)
	_place_control(panel, caption, Rect2(420.0, 8.0, 280.0, 42.0))

	_cards_layer = Control.new()
	_cards_layer.name = "TackleShopCards"
	_cards_layer.clip_contents = true
	_place_control(panel, _cards_layer, Rect2(0.0, 68.0, LIST_RECT.size.x, LIST_RECT.size.y - 72.0))


func _build_detail_panel(parent: Control) -> void:
	var panel := _texture_panel(parent, DETAIL_RECT, DETAIL_FRAME_PATH)
	panel.name = "TackleShopDetailPanel"
	panel.clip_contents = true

	var heading := _make_text("品物の詳細", 18, Palette.GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, 1)
	_place_control(panel, heading, Rect2(30.0, 16.0, 180.0, 28.0))

	_detail_icon = TextureRect.new()
	_detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_detail_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_detail_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(panel, _detail_icon, Rect2(28.0, 64.0, 108.0, 108.0))

	_detail_title_label = _make_text("", 27, Palette.GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, 2)
	_place_control(panel, _detail_title_label, Rect2(152.0, 54.0, 276.0, 44.0))

	_detail_status_label = _make_text("", 16, Palette.TEXT_BONE, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, 1)
	_place_control(panel, _detail_status_label, Rect2(154.0, 96.0, 270.0, 26.0))

	_detail_description_label = _make_text("", 17, Palette.TEXT_BONE, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, 1)
	_detail_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place_control(panel, _detail_description_label, Rect2(154.0, 128.0, 276.0, 92.0))

	var stat_heading := _make_text("性能", 18, Palette.GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, 1)
	_place_control(panel, stat_heading, Rect2(30.0, 226.0, 180.0, 26.0))

	_detail_stats_box = Control.new()
	_place_control(panel, _detail_stats_box, Rect2(30.0, 258.0, 402.0, 120.0))

	_detail_bait_box = HBoxContainer.new()
	_detail_bait_box.add_theme_constant_override("separation", 6)
	_place_control(panel, _detail_bait_box, Rect2(30.0, 386.0, 402.0, 42.0))

	_detail_hint_label = _make_text("", 16, Palette.TEXT_BONE, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, 1)
	_detail_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place_control(panel, _detail_hint_label, Rect2(30.0, 432.0, 402.0, 50.0))


func _build_footer(parent: Control) -> void:
	var notice := _texture_panel(parent, NOTICE_RECT, NOTICE_FRAME_PATH)
	notice.name = "TackleShopNotice"
	_result_label = _make_text(_result_message, 18, Palette.TEXT_BONE, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, 1)
	_place_control(notice, _result_label, Rect2(18.0, 8.0, NOTICE_RECT.size.x - 36.0, NOTICE_RECT.size.y - 16.0))

	_action_button = make_button("購入する", _buy_or_equip, 0.0, true)
	_action_button.name = "TackleShopActionButton"
	_apply_action_button_style(_action_button, true)
	_place_control(parent, _action_button, FOOTER_ACTION_RECT)

	_return_button = make_return_button(func() -> void: navigate("harbor"), 0.0)
	_return_button.name = "TackleShopReturnButton"
	_return_button.set_meta("shop_nav", "harbor")
	_place_control(parent, _return_button, FOOTER_RETURN_RECT)


func _refresh() -> void:
	_ensure_selected_item()
	if _status_bar != null and _status_bar.has_method("refresh"):
		_status_bar.refresh()
	var rig := GameData.get_rig(PlayerProgress.equipped_rig_id)
	_rig_status_label.text = "仕掛け：%s" % String(rig.get("name", "サビキ仕掛け"))
	_refresh_tabs()
	_rebuild_cards()
	_refresh_detail()
	_result_label.text = _result_message


func _ensure_selected_item() -> void:
	var ids := _current_item_ids()
	if ids.is_empty():
		_selected_item_id = ""
		return
	if _selected_item_id not in ids:
		_selected_item_id = ids[0]


func _refresh_tabs() -> void:
	_style_tab_button(_rod_tab_button, _shop_mode == "rod")
	_style_tab_button(_rig_tab_button, _shop_mode == "rig")


func _rebuild_cards() -> void:
	for child in _cards_layer.get_children():
		child.queue_free()

	var ids := _current_item_ids()
	for index in range(ids.size()):
		var item_id := String(ids[index])
		var col := index % 3
		var row := index / 3
		var rect := Rect2(
			Vector2(float(col) * (CARD_SIZE.x + CARD_GAP.x), float(row) * (CARD_SIZE.y + CARD_GAP.y)),
			CARD_SIZE
		)
		var card := _make_item_card(item_id)
		_place_control(_cards_layer, card, rect)


func _make_item_card(item_id: String) -> Button:
	var selected := item_id == _selected_item_id
	var button := Button.new()
	button.name = "ShopCard_%s" % item_id
	button.text = ""
	button.focus_mode = Control.FOCUS_ALL
	button.clip_contents = true
	button.set_meta("shop_item_card", true)
	button.set_meta("shop_item_id", item_id)
	button.set_meta("shop_mode", _shop_mode)
	_apply_card_style(button, selected)
	button.pressed.connect(func() -> void: _select_item(item_id))

	var icon := TextureRect.new()
	icon.texture = _item_icon(item_id)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(button, icon, Rect2(12.0, 18.0, 70.0, 70.0))

	var data := _item_data(item_id)
	var title := _make_text(String(data.get("name", "")), 16, Palette.TEXT_DARK, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, 0)
	_place_control(button, title, Rect2(86.0, 18.0, 128.0, 32.0))

	var status := _item_status(item_id)
	var status_label := _make_text(String(status.get("card", "")), 15, _status_color(String(status.get("kind", ""))), HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, 1)
	_place_control(button, status_label, Rect2(86.0, 54.0, 128.0, 26.0))

	var note := _card_note(item_id)
	var note_label := _make_text(note, 14, Palette.TEXT_BODY, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, 0)
	note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place_control(button, note_label, Rect2(18.0, 100.0, 184.0, 34.0))
	return button


func _select_item(item_id: String) -> void:
	_selected_item_id = item_id
	_refresh()


func _set_shop_mode(mode: String) -> void:
	if _shop_mode == mode:
		return
	_shop_mode = mode
	_selected_item_id = "starter" if _shop_mode == "rod" else GameData.DEFAULT_RIG_ID
	_result_message = "竿を選びます。" if _shop_mode == "rod" else "仕掛けを選びます。"
	_refresh()


func _refresh_detail() -> void:
	if _selected_item_id.is_empty():
		return
	var data := _item_data(_selected_item_id)
	var status := _item_status(_selected_item_id)
	_detail_icon.texture = _item_icon(_selected_item_id)
	_detail_title_label.text = String(data.get("name", ""))
	_detail_status_label.text = String(status.get("detail", ""))
	_detail_description_label.text = String(data.get("description", ""))

	_clear_children(_detail_stats_box)
	_clear_children(_detail_bait_box)
	_detail_stat_row_index = 0
	if _shop_mode == "rod":
		_refresh_rod_detail(data)
	else:
		_refresh_rig_detail(data)

	var action_text := String(status.get("action", "購入する"))
	_action_button.text = action_text
	_action_button.disabled = bool(status.get("disabled", false))


func _refresh_rod_detail(rod: Dictionary) -> void:
	var reel_percent := int(round((float(rod.get("reel_multiplier", 1.0)) - 1.0) * 100.0))
	var line_percent := int(round(float(rod.get("line_limit_bonus", 0.0)) * 100.0))
	_add_stat_row("巻力補正", "+%d%%" % reel_percent)
	_add_stat_row("ライン切断限界", "+%d%%" % line_percent)
	_add_stat_row("技量補正", "+%d" % int(rod.get("technique_bonus", 0)))
	_add_stat_row("価格", "%s G" % _format_money(int(rod.get("price", 0))))
	_detail_hint_label.text = "強い引きでも判断できる余裕を広げます。"


func _refresh_rig_detail(rig: Dictionary) -> void:
	var bait_types := _rig_bait_types(rig)
	_add_stat_row("解放", "Lv.%d" % int(rig.get("unlock_level", 1)))
	_add_stat_row("価格", "%s G" % _format_money(int(rig.get("price", 0))))
	_add_stat_row("対応エサ", " / ".join(PackedStringArray(bait_types)))
	_add_stat_row("代表魚", _representative_fish_text(bait_types))
	for bait in bait_types:
		_detail_bait_box.add_child(_make_bait_chip(bait))
	_detail_hint_label.text = "好物と対応エサが合うと反応が強くなります。"


func _add_stat_row(caption: String, value: String) -> void:
	var row_label := _make_text("%s：%s" % [caption, value], 16, Palette.TEXT_BONE, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, 1)
	_place_control(_detail_stats_box, row_label, Rect2(0.0, float(_detail_stat_row_index) * 30.0, 402.0, 26.0))
	_detail_stat_row_index += 1


func _make_bait_chip(bait: String) -> Control:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(122.0, 34.0)
	chip.add_theme_stylebox_override("panel", _chip_style())
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	chip.add_child(row)

	var icon := TextureRect.new()
	icon.texture = _bait_icon(bait)
	icon.custom_minimum_size = Vector2(24.0, 24.0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	var label := _make_text(bait, 13, Palette.TEXT_BONE, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, 1)
	label.custom_minimum_size = Vector2(78.0, 24.0)
	row.add_child(label)
	return chip


func _buy_or_equip() -> void:
	var result := (
		PlayerProgress.buy_or_equip_rod(_selected_item_id)
		if _shop_mode == "rod"
		else PlayerProgress.buy_or_equip_rig(_selected_item_id)
	)
	_result_message = String(result.get("message", "処理できませんでした。"))
	_refresh()


func _current_item_ids() -> Array[String]:
	return GameData.get_all_rod_ids() if _shop_mode == "rod" else GameData.get_all_rig_ids()


func _item_data(item_id: String) -> Dictionary:
	return GameData.get_rod(item_id) if _shop_mode == "rod" else GameData.get_rig(item_id)


func _item_status(item_id: String) -> Dictionary:
	if _shop_mode == "rod":
		var rod := GameData.get_rod(item_id)
		var price := int(rod.get("price", 0))
		if item_id == PlayerProgress.equipped_rod_id:
			return {"card": "装備中", "detail": "いま装備している竿です", "kind": "equipped", "action": "装備中", "disabled": true}
		if item_id in PlayerProgress.owned_rods:
			return {"card": "所持", "detail": "購入済みです", "kind": "owned", "action": "装備する", "disabled": false}
		if PlayerProgress.money < price:
			return {"card": "%s G" % _format_money(price), "detail": "所持金が足りません", "kind": "locked", "action": "所持金不足", "disabled": true}
		return {"card": "%s G" % _format_money(price), "detail": "購入できます", "kind": "price", "action": "%s Gで購入" % _format_money(price), "disabled": false}

	var rig := GameData.get_rig(item_id)
	var unlock_level := int(rig.get("unlock_level", 1))
	var price := int(rig.get("price", 0))
	if item_id == PlayerProgress.equipped_rig_id:
		return {"card": "装備中", "detail": "いま装備している仕掛けです", "kind": "equipped", "action": "装備中", "disabled": true}
	if PlayerProgress.level < unlock_level:
		return {"card": "Lv.%d" % unlock_level, "detail": "Lv.%dで解放されます" % unlock_level, "kind": "locked", "action": "Lv.%dで解放" % unlock_level, "disabled": true}
	if item_id in PlayerProgress.owned_rigs:
		return {"card": "所持", "detail": "購入済みです", "kind": "owned", "action": "装備する", "disabled": false}
	if PlayerProgress.money < price:
		return {"card": "%s G" % _format_money(price), "detail": "所持金が足りません", "kind": "locked", "action": "所持金不足", "disabled": true}
	return {"card": "%s G" % _format_money(price), "detail": "購入できます", "kind": "price", "action": "%s Gで購入" % _format_money(price), "disabled": false}


func _card_note(item_id: String) -> String:
	if _shop_mode == "rod":
		var rod := GameData.get_rod(item_id)
		var reel_percent := int(round((float(rod.get("reel_multiplier", 1.0)) - 1.0) * 100.0))
		var technique := int(rod.get("technique_bonus", 0))
		return "巻力 +%d%% / 技量 +%d" % [reel_percent, technique]
	var rig := GameData.get_rig(item_id)
	return "対応: %s" % " / ".join(PackedStringArray(_rig_bait_types(rig)))


func _rig_bait_types(rig: Dictionary) -> Array[String]:
	var bait_types: Array[String] = []
	for bait_variant in Array(rig.get("bait_types", [])):
		bait_types.append(String(bait_variant))
	return bait_types


func _representative_fish_text(bait_types: Array[String]) -> String:
	var names: Array[String] = []
	for fish_id in GameData.get_all_fish_ids():
		var fish := GameData.get_fish(fish_id)
		if String(fish.get("preferred_bait", "")) in bait_types:
			var name := String(fish.get("name", ""))
			if not name.is_empty() and name not in names:
				names.append(name)
		if names.size() >= 3:
			break
	if names.is_empty():
		return "調査中"
	return "、".join(PackedStringArray(names))


func _item_icon(item_id: String) -> Texture2D:
	var index := int(ROD_ICON_INDEX.get(item_id, RIG_ICON_INDEX.get(item_id, 0)))
	return ShowcaseAssetsScript.atlas_icon_from_texture(_item_icon_sheet, ICON_CELL, index)


func _bait_icon(bait: String) -> Texture2D:
	var index := int(BAIT_ICON_INDEX.get(bait, 0))
	return ShowcaseAssetsScript.atlas_icon_from_texture(_bait_icon_sheet, BAIT_CELL, index)


func _make_tab_button(mode: String, label_text: String) -> Button:
	var button := Button.new()
	button.text = label_text
	button.focus_mode = Control.FOCUS_ALL
	button.set_meta("shop_tab", mode)
	button.pressed.connect(func() -> void: _set_shop_mode(mode))
	button.add_theme_font_override("font", GameFontsScript.extra_bold(get_theme_default_font()))
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Palette.TEXT_BONE)
	button.add_theme_color_override("font_hover_color", Palette.GOLD_BRIGHT)
	button.add_theme_color_override("font_pressed_color", Palette.GOLD_BRIGHT)
	button.add_theme_color_override("font_outline_color", Palette.TEXT_OUTLINE_DARK)
	button.add_theme_constant_override("outline_size", 2)
	return button


func _style_tab_button(button: Button, active: bool) -> void:
	if button == null:
		return
	var style := _texture_style(TAB_ACTIVE_FRAME_PATH if active else TAB_FRAME_PATH, Vector4(28.0, 18.0, 28.0, 18.0), Vector4(16.0, 8.0, 16.0, 8.0))
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)
	button.add_theme_color_override("font_color", Palette.GOLD_BRIGHT if active else Palette.TEXT_BONE)


func _apply_card_style(button: Button, selected: bool) -> void:
	var style := _texture_style(CARD_SELECTED_FRAME_PATH if selected else CARD_FRAME_PATH, Vector4(24.0, 24.0, 24.0, 24.0), Vector4(12.0, 10.0, 12.0, 10.0))
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)
	button.add_theme_color_override("font_color", Palette.TEXT_DARK)


func _apply_action_button_style(button: Button, primary: bool) -> void:
	var style := _texture_style(ACTION_BUTTON_FRAME_PATH, Vector4(46.0, 24.0, 46.0, 24.0), Vector4(18.0, 8.0, 18.0, 8.0))
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)
	button.add_theme_stylebox_override("disabled", style)
	button.add_theme_font_override("font", GameFontsScript.extra_bold(get_theme_default_font()))
	button.add_theme_font_size_override("font_size", 20 if primary else 18)
	button.add_theme_color_override("font_color", Palette.GOLD_BRIGHT if primary else Palette.TEXT_BONE)
	button.add_theme_color_override("font_disabled_color", Palette.PARCHMENT_DEEP)


func _texture_panel(parent: Control, rect: Rect2, path: String) -> Control:
	var panel := Control.new()
	_place_control(parent, panel, rect)
	var texture := ShowcaseAssetsScript.texture_rect(path)
	texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(texture)
	return panel


func _texture_style(path: String, margins: Vector4, content_margins: Vector4) -> StyleBox:
	var style := ShowcaseAssetsScript.texture_style(path, margins, content_margins)
	if style != null:
		return style
	return _flat_style()


func _flat_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.DARK_PANEL
	style.border_color = Palette.GOLD
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.content_margin_left = 10.0
	style.content_margin_top = 8.0
	style.content_margin_right = 10.0
	style.content_margin_bottom = 8.0
	return style


func _chip_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.BLUE_PANEL
	style.border_color = Palette.GOLD_DEEP
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 6.0
	style.content_margin_top = 4.0
	style.content_margin_right = 6.0
	style.content_margin_bottom = 4.0
	return style


func _make_text(
	text: String,
	font_size: int,
	color: Color,
	h_align: HorizontalAlignment,
	v_align: VerticalAlignment,
	outline: int = 0
) -> Label:
	var label := make_label(text, font_size, color, outline, Palette.TEXT_OUTLINE_DARK)
	label.horizontal_alignment = h_align
	label.vertical_alignment = v_align
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 20
	return label


func _place_control(parent: Control, child: Control, rect: Rect2) -> void:
	child.position = rect.position
	child.size = rect.size
	child.custom_minimum_size = rect.size
	parent.add_child(child)


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		child.queue_free()


func _status_color(kind: String) -> Color:
	match kind:
		"equipped":
			return Palette.GOLD_BRIGHT
		"owned":
			return Palette.GAUGE_GREEN_HI
		"locked":
			return Palette.GAUGE_RED_HI
		_:
			return Palette.TEXT_BONE


func _format_money(value: int) -> String:
	var raw := str(value)
	var result := ""
	var count := 0
	for index in range(raw.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = raw[index] + result
		count += 1
	return result
