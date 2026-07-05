extends ScreenBase

const ROD_BACKPLATE_PATH := "res://assets/showcase/tackle_shop/shop_rod_backplate.png"
const RIG_BACKPLATE_PATH := "res://assets/showcase/tackle_shop/shop_rig_backplate.png"
const ITEM_ICON_SHEET_PATH := "res://assets/showcase/tackle_shop/shop_item_icon_sheet.png"
const DETAIL_ITEM_SHEET_PATH := "res://assets/showcase/tackle_shop/shop_detail_item_sheet.png"
const BAIT_ICON_SHEET_PATH := "res://assets/showcase/tackle_shop/shop_bait_icon_sheet.png"

const DESIGN_SIZE := Vector2(1280.0, 720.0)
const ICON_CELL := 128.0
const DETAIL_CELL_SIZE := Vector2(384.0, 224.0)
const BAIT_CELL := 64.0

const TITLE_RECT := Rect2(92.0, 18.0, 198.0, 42.0)
const SUBTITLE_RECT := Rect2(334.0, 18.0, 102.0, 28.0)
const LV_RECT := Rect2(552.0, 29.0, 90.0, 28.0)
const ROD_STATUS_RECT := Rect2(722.0, 29.0, 120.0, 28.0)
const MONEY_RECT := Rect2(886.0, 29.0, 144.0, 28.0)
const RIG_STATUS_RECT := Rect2(1058.0, 29.0, 150.0, 28.0)

const ROD_TAB_RECT := Rect2(82.0, 642.0, 96.0, 58.0)
const RIG_TAB_RECT := Rect2(182.0, 642.0, 124.0, 58.0)
const RESULT_RECT := Rect2(314.0, 646.0, 540.0, 42.0)
const FOOTER_ACTION_RECT := Rect2(888.0, 568.0, 294.0, 48.0)
const FOOTER_RETURN_RECT := Rect2(958.0, 650.0, 196.0, 44.0)

const CARD_SLOT_RECTS := [
	Rect2(216.0, 88.0, 192.0, 250.0),
	Rect2(414.0, 88.0, 192.0, 250.0),
	Rect2(612.0, 88.0, 192.0, 250.0),
	Rect2(216.0, 344.0, 192.0, 250.0),
	Rect2(414.0, 344.0, 192.0, 250.0),
	Rect2(612.0, 344.0, 192.0, 250.0),
]
const ROD_CARD_NAME_RECTS := [
	Rect2(248.0, 114.0, 144.0, 28.0),
	Rect2(431.0, 113.0, 144.0, 28.0),
	Rect2(613.0, 114.0, 144.0, 28.0),
	Rect2(235.0, 349.0, 152.0, 28.0),
	Rect2(421.0, 351.0, 152.0, 28.0),
	Rect2(608.0, 351.0, 152.0, 28.0),
]
const RIG_CARD_NAME_RECTS := [
	Rect2(245.0, 122.0, 150.0, 28.0),
	Rect2(433.0, 122.0, 150.0, 28.0),
	Rect2(620.0, 122.0, 150.0, 28.0),
	Rect2(245.0, 357.0, 150.0, 28.0),
	Rect2(433.0, 357.0, 150.0, 28.0),
	Rect2(621.0, 357.0, 150.0, 28.0),
]
const ROD_CARD_STATUS_RECTS := [
	Rect2(262.0, 293.0, 128.0, 30.0),
	Rect2(446.0, 293.0, 128.0, 30.0),
	Rect2(630.0, 293.0, 128.0, 30.0),
	Rect2(251.0, 536.0, 128.0, 30.0),
	Rect2(442.0, 536.0, 128.0, 30.0),
	Rect2(626.0, 536.0, 128.0, 30.0),
]
const RIG_CARD_STATUS_RECTS := [
	Rect2(249.0, 293.0, 106.0, 30.0),
	Rect2(436.0, 293.0, 106.0, 30.0),
	Rect2(624.0, 293.0, 106.0, 30.0),
	Rect2(249.0, 532.0, 106.0, 30.0),
	Rect2(436.0, 532.0, 106.0, 30.0),
	Rect2(624.0, 532.0, 106.0, 30.0),
]
const CARD_SLOT_INDEX := {
	"starter": 0,
	"iso": 1,
	"offshore": 2,
	"big_game": 3,
	"marlin": 4,
	"sabiki": 0,
	"uki": 1,
	"chokusen": 2,
	"nomase": 3,
	"jigging": 4,
	"kani": 5,
}

const DETAIL_TITLE_RECT := Rect2(878.0, 106.0, 304.0, 30.0)
const DETAIL_STATUS_RECT := Rect2(878.0, 140.0, 304.0, 24.0)
const DETAIL_DESCRIPTION_RECT := Rect2(888.0, 166.0, 288.0, 62.0)
const DETAIL_ART_RECT := Rect2(848.0, 196.0, 340.0, 184.0)
const DETAIL_ICON_RECT := Rect2(856.0, 386.0, 40.0, 40.0)
const DETAIL_STATS_RECT := Rect2(902.0, 380.0, 264.0, 98.0)
const DETAIL_BAIT_RECT := Rect2(902.0, 486.0, 286.0, 34.0)
const DETAIL_HINT_RECT := Rect2(902.0, 520.0, 270.0, 38.0)

const ITEM_ICON_INDEX := {
	"starter": 0,
	"iso": 1,
	"offshore": 2,
	"big_game": 3,
	"marlin": 4,
	"sabiki": 5,
	"uki": 6,
	"chokusen": 7,
	"nomase": 8,
	"jigging": 9,
	"kani": 10,
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
var _result_message := "装備を整えます。"

var _item_icon_sheet: Texture2D
var _detail_item_sheet: Texture2D
var _bait_icon_sheet: Texture2D

var _letterbox_backdrop: ColorRect
var _design_canvas: Control
var _backplate: TextureRect
var _title_label: Label
var _subtitle_label: Label
var _lv_label: Label
var _rod_status_label: Label
var _money_label: Label
var _rig_status_label: Label
var _rod_tab_button: Button
var _rig_tab_button: Button
var _cards_layer: Control
var _detail_art: TextureRect
var _detail_icon: TextureRect
var _detail_title_label: Label
var _detail_status_label: Label
var _detail_description_label: Label
var _detail_stats_box: Control
var _detail_bait_box: Control
var _detail_hint_label: Label
var _action_button: Button
var _return_button: Button
var _result_label: Label
var _detail_stat_row_index := 0


func _build_screen() -> void:
	_load_assets()
	_build_fixed_canvas()
	_build_backplate(_design_canvas)

	var root := Control.new()
	root.name = "TackleShopOverlay"
	root.position = Vector2.ZERO
	root.size = DESIGN_SIZE
	root.custom_minimum_size = DESIGN_SIZE
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	_design_canvas.add_child(root)

	_build_cards(root)
	_build_header_overlay(root)
	_build_tabs(root)
	_build_detail_overlay(root)
	_build_footer(root)
	_layout_design_canvas()
	_refresh()


func _load_assets() -> void:
	_item_icon_sheet = _load_tackle_texture(ITEM_ICON_SHEET_PATH)
	_detail_item_sheet = _load_tackle_texture(DETAIL_ITEM_SHEET_PATH)
	_bait_icon_sheet = _load_tackle_texture(BAIT_ICON_SHEET_PATH)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_design_canvas()


func _build_fixed_canvas() -> void:
	_letterbox_backdrop = ColorRect.new()
	_letterbox_backdrop.name = "TackleShopLetterboxBackdrop"
	_letterbox_backdrop.color = Palette.TEXT_OUTLINE_DARK
	_letterbox_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_letterbox_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_letterbox_backdrop)

	_design_canvas = Control.new()
	_design_canvas.name = "TackleShopDesignCanvas"
	_design_canvas.position = Vector2.ZERO
	_design_canvas.size = DESIGN_SIZE
	_design_canvas.custom_minimum_size = DESIGN_SIZE
	_design_canvas.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_design_canvas)


func _layout_design_canvas() -> void:
	if _design_canvas == null:
		return
	var available := size
	if available.x <= 1.0 or available.y <= 1.0:
		available = get_viewport_rect().size
	var scale_factor := minf(available.x / DESIGN_SIZE.x, available.y / DESIGN_SIZE.y)
	if scale_factor <= 0.0:
		scale_factor = 1.0
	var scaled_size := DESIGN_SIZE * scale_factor
	_design_canvas.position = ((available - scaled_size) * 0.5).floor()
	_design_canvas.size = DESIGN_SIZE
	_design_canvas.scale = Vector2(scale_factor, scale_factor)


func _build_backplate(parent: Control) -> void:
	_backplate = TextureRect.new()
	_backplate.texture = _load_tackle_texture(ROD_BACKPLATE_PATH)
	_backplate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_backplate.stretch_mode = TextureRect.STRETCH_SCALE
	_backplate.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_backplate.position = Vector2.ZERO
	_backplate.size = DESIGN_SIZE
	_backplate.custom_minimum_size = DESIGN_SIZE
	_backplate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(_backplate)


func _build_header_overlay(parent: Control) -> void:
	_title_label = _make_text("釣具店", 28, Palette.GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, 2)
	_place_at_rect(parent, _title_label, TITLE_RECT)

	_subtitle_label = _make_text("装備を整える", 14, Palette.TEXT_BONE, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, 1)
	_place_at_rect(parent, _subtitle_label, SUBTITLE_RECT)

	_lv_label = _make_text("", 17, Palette.TEXT_BONE, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, 1)
	_place_at_rect(parent, _lv_label, LV_RECT)

	_rod_status_label = _make_text("", 16, Palette.TEXT_BONE, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, 1)
	_place_at_rect(parent, _rod_status_label, ROD_STATUS_RECT)

	_money_label = _make_text("", 16, Palette.GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, 1)
	_place_at_rect(parent, _money_label, MONEY_RECT)

	_rig_status_label = _make_text("", 15, Palette.TEXT_BONE, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, 1)
	_place_at_rect(parent, _rig_status_label, RIG_STATUS_RECT)


func _build_tabs(parent: Control) -> void:
	_rod_tab_button = _make_transparent_button("竿", func() -> void: _set_shop_mode("rod"))
	_rod_tab_button.name = "TackleShopRodTab"
	_rod_tab_button.set_meta("shop_tab", "rod")
	_place_at_rect(parent, _rod_tab_button, ROD_TAB_RECT)

	_rig_tab_button = _make_transparent_button("仕掛け", func() -> void: _set_shop_mode("rig"))
	_rig_tab_button.name = "TackleShopRigTab"
	_rig_tab_button.set_meta("shop_tab", "rig")
	_place_at_rect(parent, _rig_tab_button, RIG_TAB_RECT)


func _build_cards(parent: Control) -> void:
	_cards_layer = Control.new()
	_cards_layer.name = "TackleShopCards"
	_cards_layer.clip_contents = false
	_cards_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	_place_at_rect(parent, _cards_layer, Rect2(Vector2.ZERO, Vector2(1280.0, 720.0)))


func _build_detail_overlay(parent: Control) -> void:
	_detail_title_label = _make_text("", 23, Palette.GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, 2)
	_apply_label_font(_detail_title_label, "extra_bold")
	_place_at_rect(parent, _detail_title_label, DETAIL_TITLE_RECT)

	_detail_status_label = _make_text("", 15, Palette.TEXT_BONE, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, 1)
	_apply_label_font(_detail_status_label, "bold")
	_place_at_rect(parent, _detail_status_label, DETAIL_STATUS_RECT)

	_detail_description_label = _make_text("", 15, Palette.TEXT_DARK, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, 0)
	_apply_label_font(_detail_description_label, "bold")
	_detail_description_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_place_at_rect(parent, _detail_description_label, DETAIL_DESCRIPTION_RECT)

	_detail_art = TextureRect.new()
	_detail_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_detail_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_detail_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_at_rect(parent, _detail_art, DETAIL_ART_RECT)

	_detail_icon = TextureRect.new()
	_detail_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_detail_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_detail_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_icon.modulate = Palette.TACKLE_DETAIL_ICON_MODULATE
	_place_at_rect(parent, _detail_icon, DETAIL_ICON_RECT)

	_detail_stats_box = Control.new()
	_place_at_rect(parent, _detail_stats_box, DETAIL_STATS_RECT)

	_detail_bait_box = Control.new()
	_place_at_rect(parent, _detail_bait_box, DETAIL_BAIT_RECT)

	_detail_hint_label = _make_text("", 14, Palette.TEXT_DARK, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP, 0)
	_detail_hint_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_detail_hint_label.visible = false
	_place_at_rect(parent, _detail_hint_label, DETAIL_HINT_RECT)


func _build_footer(parent: Control) -> void:
	_result_label = _make_text(_result_message, 18, Palette.TEXT_BONE, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, 2)
	_apply_label_font(_result_label, "bold")
	_place_at_rect(parent, _result_label, RESULT_RECT)

	_action_button = _make_transparent_button("購入する", _buy_or_equip)
	_action_button.name = "TackleShopActionButton"
	_action_button.add_theme_font_size_override("font_size", 20)
	_place_at_rect(parent, _action_button, FOOTER_ACTION_RECT)

	_return_button = _make_transparent_button("港へ戻る", func() -> void: navigate("harbor"))
	_return_button.name = "TackleShopReturnButton"
	_return_button.set_meta("shop_nav", "harbor")
	_return_button.add_theme_font_size_override("font_size", 16)
	_place_at_rect(parent, _return_button, FOOTER_RETURN_RECT)


func _refresh() -> void:
	_ensure_selected_item()
	_refresh_backplate()
	_refresh_header()
	_refresh_tabs()
	_rebuild_cards()
	_refresh_detail()
	_result_label.text = _result_message


func _refresh_backplate() -> void:
	if _backplate == null:
		return
	_backplate.texture = _load_tackle_texture(ROD_BACKPLATE_PATH if _shop_mode == "rod" else RIG_BACKPLATE_PATH)


func _refresh_header() -> void:
	var rod := GameData.get_rod(PlayerProgress.equipped_rod_id)
	var rig := GameData.get_rig(PlayerProgress.equipped_rig_id)
	_subtitle_label.text = "竿を選ぶ" if _shop_mode == "rod" else "仕掛けを選ぶ"
	_lv_label.text = "Lv.%d" % PlayerProgress.level
	_rod_status_label.text = _short_equipment_name(String(rod.get("name", "入門竿")))
	_money_label.text = "%s G" % ScreenBase.format_money(PlayerProgress.money)
	_rig_status_label.text = _short_equipment_name(String(rig.get("name", "サビキ仕掛け")))


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

	for item_id_variant in _current_item_ids():
		var item_id := String(item_id_variant)
		var card := _make_item_card(item_id)
		_place_at_rect(_cards_layer, card, _card_rect(item_id))
		_add_card_labels(_cards_layer, item_id)


func _make_item_card(item_id: String) -> Button:
	var selected := item_id == _selected_item_id
	var button := Button.new()
	button.name = "ShopCard_%s" % item_id
	button.text = ""
	button.focus_mode = Control.FOCUS_ALL
	button.clip_contents = false
	button.set_meta("shop_item_card", true)
	button.set_meta("shop_item_id", item_id)
	button.set_meta("shop_mode", _shop_mode)
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_transparent_button_style(button)
	button.pressed.connect(func() -> void: _select_item(item_id))

	if selected:
		var highlight := ColorRect.new()
		highlight.name = "ShopCardHighlight_%s" % item_id
		highlight.color = Palette.TACKLE_CARD_SELECTION_WASH
		highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
		highlight.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		button.add_child(highlight)
		var frame := Panel.new()
		frame.name = "ShopCardSelectionFrame_%s" % item_id
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_theme_stylebox_override("panel", _selection_style())
		frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		button.add_child(frame)
	return button


func _add_card_labels(parent: Control, item_id: String) -> void:
	var data := _item_data(item_id)
	var status := _item_status(item_id)
	var name_rect := _card_name_rect(item_id)
	var status_rect := _card_status_rect(item_id)
	var name_size := 15
	var status_size := 16

	var title_text := String(data.get("name", ""))
	var title := _make_text(title_text, _fit_card_text_size(title_text, name_size, 13, name_rect.size.x), Palette.GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, 2)
	_apply_label_font(title, "extra_bold")
	title.name = "ShopCardName_%s" % item_id
	title.set_meta("shop_item_id", item_id)
	title.set_meta("shop_label_role", "name")
	title.z_index = 30
	_place_at_rect(parent, title, name_rect)

	var status_text := String(status.get("card", ""))
	var status_label := _make_text(status_text, _fit_card_text_size(status_text, status_size, 13, status_rect.size.x), _status_color(String(status.get("kind", ""))), HORIZONTAL_ALIGNMENT_CENTER, VERTICAL_ALIGNMENT_CENTER, 2)
	_apply_label_font(status_label, "extra_bold")
	status_label.name = "ShopCardStatus_%s" % item_id
	status_label.set_meta("shop_item_id", item_id)
	status_label.set_meta("shop_label_role", "status")
	status_label.z_index = 30
	_place_at_rect(parent, status_label, status_rect)


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
	_detail_art.texture = _detail_item_icon(_selected_item_id)
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
	_add_stat_row("切断限界", "+%d%%" % line_percent)
	_add_stat_row("技量補正", "+%d" % int(rod.get("technique_bonus", 0)))
	_add_stat_row("価格", "%s G" % ScreenBase.format_money(int(rod.get("price", 0))))
	_detail_hint_label.text = ""


func _refresh_rig_detail(rig: Dictionary) -> void:
	var bait_types := _rig_bait_types(rig)
	_add_stat_row("解放", "Lv.%d" % int(rig.get("unlock_level", 1)))
	_add_stat_row("価格", "%s G" % ScreenBase.format_money(int(rig.get("price", 0))))
	_add_stat_row("対応エサ", " / ".join(PackedStringArray(bait_types)))
	_add_stat_row("代表魚", _representative_fish_text(bait_types))
	for index in range(bait_types.size()):
		var chip := _make_bait_chip(String(bait_types[index]))
		_place_at_rect(_detail_bait_box, chip, Rect2(float(index) * 96.0, 0.0, 88.0, 32.0))
	_detail_hint_label.text = ""


func _add_stat_row(caption: String, value: String) -> void:
	var row_label := _make_text("%s：%s" % [caption, value], 15, Palette.TEXT_DARK, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, 0)
	_apply_label_font(row_label, "bold")
	_place_at_rect(_detail_stats_box, row_label, Rect2(0.0, float(_detail_stat_row_index) * 24.0, DETAIL_STATS_RECT.size.x, 22.0))
	_detail_stat_row_index += 1


func _make_bait_chip(bait: String) -> Control:
	var chip := Control.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := Panel.new()
	bg.add_theme_stylebox_override("panel", _chip_style())
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	chip.add_child(bg)

	var icon := TextureRect.new()
	icon.texture = _bait_icon(bait)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_at_rect(chip, icon, Rect2(4.0, 4.0, 24.0, 24.0))

	var label := _make_text(bait, 11, Palette.TEXT_BONE, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_CENTER, 1)
	_place_at_rect(chip, label, Rect2(30.0, 4.0, 54.0, 24.0))
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
			return {"card": "%s G" % ScreenBase.format_money(price), "detail": "所持金が足りません", "kind": "locked", "action": "所持金不足", "disabled": true}
		return {"card": "%s G" % ScreenBase.format_money(price), "detail": "購入できます", "kind": "price", "action": "%s Gで購入" % ScreenBase.format_money(price), "disabled": false}

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
		return {"card": "%s G" % ScreenBase.format_money(price), "detail": "所持金が足りません", "kind": "locked", "action": "所持金不足", "disabled": true}
	return {"card": "%s G" % ScreenBase.format_money(price), "detail": "購入できます", "kind": "price", "action": "%s Gで購入" % ScreenBase.format_money(price), "disabled": false}


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


func _item_icon_index(item_id: String) -> int:
	return int(ITEM_ICON_INDEX.get(item_id, 0))


func _item_icon(item_id: String) -> Texture2D:
	return ShowcaseAssetsScript.atlas_icon_from_texture(_item_icon_sheet, ICON_CELL, _item_icon_index(item_id))


func _detail_item_icon(item_id: String) -> Texture2D:
	return _atlas_texture(_detail_item_sheet, DETAIL_CELL_SIZE, _item_icon_index(item_id))


func _bait_icon(bait: String) -> Texture2D:
	var index := int(BAIT_ICON_INDEX.get(bait, 0))
	return ShowcaseAssetsScript.atlas_icon_from_texture(_bait_icon_sheet, BAIT_CELL, index)


func _atlas_texture(sheet: Texture2D, cell_size: Vector2, icon_index: int) -> Texture2D:
	if sheet == null or icon_index < 0:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(Vector2(cell_size.x * float(icon_index), 0.0), cell_size)
	return atlas


func _card_rect(item_id: String) -> Rect2:
	var index := _card_slot_index(item_id)
	if index < 0 or index >= CARD_SLOT_RECTS.size():
		return Rect2()
	return CARD_SLOT_RECTS[index]


func _card_name_rect(item_id: String) -> Rect2:
	var index := _card_slot_index(item_id)
	var rects := RIG_CARD_NAME_RECTS if _shop_mode == "rig" else ROD_CARD_NAME_RECTS
	if index < 0 or index >= rects.size():
		return Rect2()
	return rects[index]


func _card_status_rect(item_id: String) -> Rect2:
	var index := _card_slot_index(item_id)
	var rects := RIG_CARD_STATUS_RECTS if _shop_mode == "rig" else ROD_CARD_STATUS_RECTS
	if index < 0 or index >= rects.size():
		return Rect2()
	return rects[index]


func _card_slot_index(item_id: String) -> int:
	return int(CARD_SLOT_INDEX.get(item_id, -1))


func _fit_card_text_size(text: String, base_size: int, minimum_size: int, width: float) -> int:
	var effective := base_size
	if text.length() >= 9:
		effective -= 1
	if text.length() >= 12:
		effective -= 1
	if width < 132.0:
		effective -= 1
	return maxi(minimum_size, effective)


func _make_transparent_button(label_text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label_text
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_transparent_button_style(button)
	button.add_theme_font_override("font", GameFontsScript.extra_bold(get_theme_default_font()))
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Palette.GOLD_BRIGHT)
	button.add_theme_color_override("font_hover_color", Palette.GOLD_BRIGHT)
	button.add_theme_color_override("font_pressed_color", Palette.TEXT_BONE)
	button.add_theme_color_override("font_disabled_color", Palette.PARCHMENT_DEEP)
	button.add_theme_color_override("font_outline_color", Palette.TEXT_OUTLINE_DARK)
	button.add_theme_constant_override("outline_size", 2)
	button.pressed.connect(callback)
	return button


func _style_tab_button(button: Button, active: bool) -> void:
	if button == null:
		return
	button.modulate = Palette.TACKLE_TAB_ACTIVE_MODULATE if active else Palette.TACKLE_TAB_INACTIVE_MODULATE
	button.add_theme_color_override("font_color", Palette.GOLD_BRIGHT if active else Palette.TEXT_BONE)
	var normal := _tab_button_style(active, false)
	var hover := _tab_button_style(active, true)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", hover)


func _apply_transparent_button_style(button: Button) -> void:
	var normal := _empty_style()
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", normal)
	button.add_theme_stylebox_override("pressed", normal)
	button.add_theme_stylebox_override("focus", normal)
	button.add_theme_stylebox_override("disabled", normal)


func _empty_style() -> StyleBoxEmpty:
	return StyleBoxEmpty.new()


func _tab_button_style(active: bool, hover: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Palette.DARK_PANEL, 0.60 if active else (0.28 if hover else 0.0))
	style.border_color = Color(Palette.GOLD_BRIGHT, 0.86 if active else (0.46 if hover else 0.0))
	style.set_border_width_all(2 if active or hover else 0)
	style.set_corner_radius_all(6)
	return style


func _selection_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.TACKLE_SELECTION_FILL
	style.border_color = Color(Palette.GOLD_BRIGHT, 0.82)
	style.set_border_width_all(3)
	style.set_corner_radius_all(5)
	return style


func _chip_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Palette.DARK_PANEL, 0.92)
	style.border_color = Palette.GOLD_DEEP
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style


func _apply_label_font(label: Label, weight: String) -> void:
	var fallback := get_theme_default_font()
	match weight:
		"extra_bold":
			label.add_theme_font_override("font", GameFontsScript.extra_bold(fallback))
		"bold":
			label.add_theme_font_override("font", GameFontsScript.bold(fallback))
		_:
			label.add_theme_font_override("font", GameFontsScript.regular(fallback))


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


func _place_at_rect(parent: Control, child: Control, rect: Rect2) -> void:
	child.position = rect.position
	child.size = rect.size
	child.custom_minimum_size = rect.size
	parent.add_child(child)


func _load_tackle_texture(path: String) -> Texture2D:
	var imported := ShowcaseAssetsScript.load_texture(path)
	if imported != null:
		return imported
	var absolute_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(absolute_path):
		var image := Image.new()
		if image.load(absolute_path) == OK:
			return ImageTexture.create_from_image(image)
	return null


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


func _short_equipment_name(name: String) -> String:
	if name.begins_with("港の"):
		name = name.substr(2)
	var parts := name.split("・")
	if parts.size() >= 2:
		return String(parts[1])
	return name
