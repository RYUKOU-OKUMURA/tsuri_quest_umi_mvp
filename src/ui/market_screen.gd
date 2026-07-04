extends ScreenBase

const PlayerStatusBarScript = preload("res://src/ui/components/player_status_bar.gd")
const FightFishAssets = preload("res://src/ui/fight_fish_assets.gd")

const BACKPLATE_PATH := "res://assets/showcase/fish_market/fish_market_backplate.png"
const DESIGN_SIZE := Vector2(1280.0, 720.0)
const VISIBLE_ROW_COUNT := 7

const TITLE_RECT := Rect2(150.0, 30.0, 170.0, 52.0)
const STATUS_RECT := Rect2(384.0, 25.0, 810.0, 58.0)
const INVENTORY_TITLE_RECT := Rect2(198.0, 135.0, 244.0, 40.0)
const PAGE_PREV_RECT := Rect2(466.0, 136.0, 44.0, 36.0)
const PAGE_LABEL_RECT := Rect2(514.0, 136.0, 64.0, 36.0)
const PAGE_NEXT_RECT := Rect2(582.0, 136.0, 44.0, 36.0)
const ROW_START_Y := 198.0
const ROW_STEP_Y := 66.0
const ROW_HEIGHT := 62.0

const DETAIL_TITLE_RECT := Rect2(760.0, 142.0, 338.0, 40.0)
const DETAIL_FISH_RECT := Rect2(772.0, 198.0, 312.0, 166.0)
const DETAIL_RARITY_RECT := Rect2(1138.0, 154.0, 62.0, 30.0)
const DETAIL_BODY_RECT := Rect2(790.0, 388.0, 360.0, 58.0)
const DETAIL_PRICE_RECT := Rect2(724.0, 456.0, 140.0, 26.0)
const DETAIL_COUNT_RECT := Rect2(888.0, 456.0, 144.0, 26.0)
const DETAIL_SUBTOTAL_RECT := Rect2(1056.0, 456.0, 150.0, 26.0)

const CART_TITLE_RECT := Rect2(790.0, 526.0, 238.0, 32.0)
const CART_SELECT_ALL_RECT := Rect2(1040.0, 526.0, 118.0, 32.0)
const CART_TOTAL_RECT := Rect2(792.0, 626.0, 188.0, 34.0)
const CART_ACTION_RECT := Rect2(1008.0, 612.0, 190.0, 50.0)
const RETURN_RECT := Rect2(52.0, 666.0, 132.0, 40.0)
const CART_THUMB_START := Vector2(736.0, 572.0)
const CART_THUMB_STEP := 76.0
const CART_THUMB_SIZE := Vector2(58.0, 52.0)

var _letterbox_backdrop: ColorRect
var _design_canvas: Control
var _backplate: TextureRect
var _status_bar: Control
var _title_label: Label
var _inventory_title_label: Label
var _page_label: Label
var _prev_page_button: Button
var _next_page_button: Button
var _row_nodes: Array = []
var _inventory_empty_panel: Control
var _detail_title_label: Label
var _detail_fish_image: TextureRect
var _detail_rarity_label: Label
var _detail_body_label: Label
var _detail_price_label: Label
var _detail_count_label: Label
var _detail_subtotal_label: Label
var _cart_title_label: Label
var _cart_total_label: Label
var _select_all_button: Button
var _cart_action_button: Button
var _return_button: Button
var _cart_thumbs: Array[TextureRect] = []
var _confirm_overlay: Control
var _confirm_title_label: Label
var _confirm_body_label: Label
var _confirm_cancel_button: Button
var _confirm_sell_button: Button

var _fish_ids: Array[String] = []
var _selected_fish_id := ""
var _sell_quantities: Dictionary = {}
var _scroll_offset := 0
var _last_message := "売る数を選んでください。"


func _build_screen() -> void:
	_build_fixed_canvas()
	_build_backplate(_design_canvas)

	var root := Control.new()
	root.name = "FishMarketOverlay"
	root.z_index = 100
	root.position = Vector2.ZERO
	root.size = DESIGN_SIZE
	root.custom_minimum_size = DESIGN_SIZE
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	_design_canvas.add_child(root)

	_build_header(root)
	_build_inventory(root)
	_build_detail(root)
	_build_cart(root)
	_build_confirm_overlay(root)
	_layout_design_canvas()
	_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_design_canvas()


func _build_fixed_canvas() -> void:
	_letterbox_backdrop = ColorRect.new()
	_letterbox_backdrop.name = "FishMarketLetterboxBackdrop"
	_letterbox_backdrop.color = Palette.TEXT_OUTLINE_DARK
	_letterbox_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_letterbox_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_letterbox_backdrop)

	_design_canvas = Control.new()
	_design_canvas.name = "FishMarketDesignCanvas"
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
	_backplate.name = "FishMarketBackplate"
	_backplate.texture = ShowcaseAssetsScript.load_texture(BACKPLATE_PATH)
	_backplate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_backplate.stretch_mode = TextureRect.STRETCH_SCALE
	_backplate.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_backplate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backplate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(_backplate)


func _build_header(parent: Control) -> void:
	_title_label = _market_label("魚市場", 30, Palette.TEXT_BONE, 3)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_place(parent, _title_label, TITLE_RECT)

	_status_bar = PlayerStatusBarScript.new()
	_status_bar.name = "FishMarketPlayerStatusBar"
	_place(parent, _status_bar, STATUS_RECT)


func _build_inventory(parent: Control) -> void:
	_inventory_title_label = _market_label("クーラーボックス", 24, Palette.TEXT_DARK, 0)
	_inventory_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(parent, _inventory_title_label, INVENTORY_TITLE_RECT)

	_prev_page_button = _market_button("前", _change_page.bind(-1), false, 15)
	_prev_page_button.name = "MarketPrevPageButton"
	_place(parent, _prev_page_button, PAGE_PREV_RECT)

	_page_label = _market_label("1/1", 15, Palette.TEXT_DARK, 0)
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(parent, _page_label, PAGE_LABEL_RECT)

	_next_page_button = _market_button("次", _change_page.bind(1), false, 15)
	_next_page_button.name = "MarketNextPageButton"
	_place(parent, _next_page_button, PAGE_NEXT_RECT)

	for row_index in range(VISIBLE_ROW_COUNT):
		_build_inventory_row(parent, row_index)
	_build_inventory_empty_panel(parent)


func _build_inventory_row(parent: Control, row_index: int) -> void:
	var rect := _row_rect(row_index)
	var row: Dictionary = {}

	var highlight := ColorRect.new()
	highlight.name = "MarketRowHighlight_%d" % row_index
	highlight.z_index = 5
	highlight.color = _with_alpha(Palette.GAUGE_CYAN_HI, 0.34)
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(parent, highlight, Rect2(rect.position - Vector2(6.0, 2.0), rect.size + Vector2(12.0, 4.0)))
	row["highlight"] = highlight

	var pointer := ColorRect.new()
	pointer.name = "MarketRowPointer_%d" % row_index
	pointer.z_index = 25
	pointer.color = _with_alpha(Palette.GAUGE_CYAN_HI, 0.95)
	pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(parent, pointer, Rect2(58.0, rect.position.y + 14.0, 8.0, 34.0))
	row["pointer"] = pointer

	var select_button := _market_button("", _select_visible_row.bind(row_index), false, 1)
	select_button.name = "MarketRowSelect_%d" % row_index
	select_button.set_meta("market_row_select", true)
	_make_button_transparent(select_button)
	_place(parent, select_button, Rect2(rect.position, Vector2(510.0, rect.size.y)))
	row["select_button"] = select_button

	var fish_image := TextureRect.new()
	fish_image.name = "MarketRowFish_%d" % row_index
	fish_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fish_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fish_image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	fish_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(parent, fish_image, Rect2(88.0, rect.position.y + 6.0, 78.0, 50.0))
	row["fish_image"] = fish_image

	var name_panel := _market_field_panel(Palette.PARCHMENT_DEEP, Palette.SAND_DEEP, 0.74)
	_place(parent, name_panel, Rect2(188.0, rect.position.y + 12.0, 144.0, 30.0))
	row["name_panel"] = name_panel

	var count_panel := _market_field_panel(Palette.PARCHMENT, Palette.SAND_DEEP, 0.88)
	_place(parent, count_panel, Rect2(386.0, rect.position.y + 15.0, 62.0, 28.0))
	row["count_panel"] = count_panel

	var price_panel := _market_field_panel(Palette.PARCHMENT, Palette.GOLD_DEEP, 0.88)
	_place(parent, price_panel, Rect2(456.0, rect.position.y + 15.0, 64.0, 28.0))
	row["price_panel"] = price_panel

	var quantity_panel := _market_field_panel(Palette.PARCHMENT_DEEP, Palette.SAND_DEEP, 0.86)
	_place(parent, quantity_panel, Rect2(556.0, rect.position.y + 14.0, 48.0, 34.0))
	row["quantity_panel"] = quantity_panel

	var name_label := _market_label("", 17, Palette.TEXT_DARK, 0)
	_place(parent, name_label, Rect2(190.0, rect.position.y + 9.0, 150.0, 26.0))
	row["name_label"] = name_label

	var meta_label := _market_label("", 12, Palette.TEXT_BODY, 0)
	_place(parent, meta_label, Rect2(190.0, rect.position.y + 35.0, 160.0, 18.0))
	row["meta_label"] = meta_label

	var count_label := _market_label("", 15, Palette.TEXT_DARK, 0)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(parent, count_label, Rect2(386.0, rect.position.y + 17.0, 62.0, 25.0))
	row["count_label"] = count_label

	var price_label := _market_label("", 14, Palette.TEXT_DARK, 0)
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(parent, price_label, Rect2(456.0, rect.position.y + 17.0, 64.0, 25.0))
	row["price_label"] = price_label

	var minus_button := _market_button("-", _adjust_visible_row.bind(row_index, -1), false, 18)
	minus_button.name = "MarketRowMinus_%d" % row_index
	minus_button.set_meta("market_quantity_button", true)
	_place(parent, minus_button, Rect2(524.0, rect.position.y + 14.0, 28.0, 34.0))
	row["minus_button"] = minus_button

	var quantity_label := _market_label("0", 18, Palette.TEXT_DARK, 0)
	quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(parent, quantity_label, Rect2(556.0, rect.position.y + 14.0, 48.0, 34.0))
	row["quantity_label"] = quantity_label

	var plus_button := _market_button("+", _adjust_visible_row.bind(row_index, 1), false, 18)
	plus_button.name = "MarketRowPlus_%d" % row_index
	plus_button.set_meta("market_quantity_button", true)
	_place(parent, plus_button, Rect2(608.0, rect.position.y + 14.0, 28.0, 34.0))
	row["plus_button"] = plus_button

	var all_button := _market_button("全", _set_visible_row_all.bind(row_index), false, 16)
	all_button.name = "MarketRowAll_%d" % row_index
	all_button.set_meta("market_quantity_button", true)
	_place(parent, all_button, Rect2(640.0, rect.position.y + 14.0, 28.0, 34.0))
	row["all_button"] = all_button

	_row_nodes.append(row)


func _build_inventory_empty_panel(parent: Control) -> void:
	_inventory_empty_panel = PanelContainer.new()
	_inventory_empty_panel.name = "MarketInventoryEmptyPanel"
	_inventory_empty_panel.z_index = 28
	_inventory_empty_panel.visible = false
	var empty_style := _panel_style(Palette.PARCHMENT, Palette.GOLD_DEEP, 2, 8)
	empty_style.bg_color = Palette.PARCHMENT
	_inventory_empty_panel.add_theme_stylebox_override("panel", empty_style)
	_place(parent, _inventory_empty_panel, Rect2(86.0, 204.0, 582.0, 422.0))

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	_inventory_empty_panel.add_child(box)

	var title := _market_label("クーラーボックスは空です", 25, Palette.TEXT_DARK, 0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.custom_minimum_size = Vector2(0.0, 42.0)
	box.add_child(title)

	var body := _market_label("釣った魚がここに並びます。\nまずは釣り場へ向かいましょう。", 18, Palette.TEXT_BODY, 0)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.custom_minimum_size = Vector2(0.0, 72.0)
	box.add_child(body)


func _build_detail(parent: Control) -> void:
	_detail_title_label = _market_label("査定中", 25, Palette.TEXT_DARK, 0)
	_detail_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(parent, _detail_title_label, DETAIL_TITLE_RECT)

	_detail_fish_image = TextureRect.new()
	_detail_fish_image.name = "MarketDetailFishImage"
	_detail_fish_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_fish_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_detail_fish_image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_detail_fish_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(parent, _detail_fish_image, DETAIL_FISH_RECT)

	_detail_rarity_label = _market_label("", 13, Palette.TEXT_BONE, 1)
	_detail_rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(parent, _detail_rarity_label, DETAIL_RARITY_RECT)

	_detail_body_label = _market_label("", 16, Palette.TEXT_BONE, 1)
	_detail_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place(parent, _detail_body_label, DETAIL_BODY_RECT)

	_detail_price_label = _market_label("", 14, Palette.TEXT_BONE, 1)
	_detail_price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(parent, _detail_price_label, DETAIL_PRICE_RECT)

	_detail_count_label = _market_label("", 14, Palette.TEXT_BONE, 1)
	_detail_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(parent, _detail_count_label, DETAIL_COUNT_RECT)

	_detail_subtotal_label = _market_label("", 14, Palette.TEXT_BONE, 1)
	_detail_subtotal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(parent, _detail_subtotal_label, DETAIL_SUBTOTAL_RECT)


func _build_cart(parent: Control) -> void:
	_cart_title_label = _market_label("", 15, Palette.TEXT_BONE, 1)
	_cart_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_place(parent, _cart_title_label, CART_TITLE_RECT)

	_select_all_button = _market_button("全部選択", _select_all_fish, false, 15)
	_select_all_button.name = "MarketSelectAllButton"
	_select_all_button.set_meta("market_select_all", true)
	_place(parent, _select_all_button, CART_SELECT_ALL_RECT)

	for index in range(6):
		var thumb := TextureRect.new()
		thumb.name = "MarketCartThumb_%d" % index
		thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		thumb.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place(
			parent,
			thumb,
			Rect2(CART_THUMB_START + Vector2(CART_THUMB_STEP * float(index), 0.0), CART_THUMB_SIZE)
		)
		_cart_thumbs.append(thumb)

	_cart_total_label = _market_label("", 20, Palette.TEXT_DARK, 0)
	_cart_total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(parent, _cart_total_label, CART_TOTAL_RECT)

	_cart_action_button = _market_button("まとめて売る", _show_confirm_overlay, true, 21)
	_cart_action_button.name = "MarketSellBatchButton"
	_cart_action_button.set_meta("market_sell_batch", true)
	_place(parent, _cart_action_button, CART_ACTION_RECT)

	_return_button = _market_button("港へ戻る", func() -> void: navigate("harbor"), false, 15)
	_return_button.name = "MarketReturnButton"
	_return_button.set_meta("harbor_return", true)
	_place(parent, _return_button, RETURN_RECT)


func _build_confirm_overlay(parent: Control) -> void:
	_confirm_overlay = Control.new()
	_confirm_overlay.name = "MarketConfirmOverlay"
	_confirm_overlay.visible = false
	_confirm_overlay.position = Vector2.ZERO
	_confirm_overlay.size = DESIGN_SIZE
	_confirm_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(_confirm_overlay)

	var dim := ColorRect.new()
	dim.color = _with_alpha(Palette.TEXT_OUTLINE_DARK, 0.68)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_confirm_overlay.add_child(dim)

	var panel := PanelContainer.new()
	panel.position = Vector2(360.0, 190.0)
	panel.size = Vector2(560.0, 300.0)
	panel.add_theme_stylebox_override("panel", _panel_style(Palette.DARK_PANEL, Palette.GOLD, 3, 8))
	_confirm_overlay.add_child(panel)

	_confirm_title_label = _market_label("売却確認", 28, Palette.GOLD_BRIGHT, 2)
	_confirm_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_place(_confirm_overlay, _confirm_title_label, Rect2(396.0, 214.0, 488.0, 42.0))

	_confirm_body_label = _market_label("", 20, Palette.TEXT_BONE, 1)
	_confirm_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm_body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(_confirm_overlay, _confirm_body_label, Rect2(410.0, 268.0, 460.0, 116.0))

	_confirm_cancel_button = _market_button("戻る", _hide_confirm_overlay, false, 18)
	_confirm_cancel_button.name = "MarketConfirmCancelButton"
	_place(_confirm_overlay, _confirm_cancel_button, Rect2(430.0, 414.0, 160.0, 46.0))

	_confirm_sell_button = _market_button("売却する", _confirm_sell, true, 19)
	_confirm_sell_button.name = "MarketConfirmSellButton"
	_place(_confirm_overlay, _confirm_sell_button, Rect2(690.0, 414.0, 180.0, 46.0))


func _refresh() -> void:
	_rebuild_fish_ids()
	_clamp_scroll_offset()
	_prune_quantities()
	_resolve_selected_fish()
	_refresh_status()
	_refresh_inventory()
	_refresh_detail()
	_refresh_cart()


func _rebuild_fish_ids() -> void:
	_fish_ids.clear()
	for fish_id in GameData.get_all_fish_ids():
		if PlayerProgress.fish_count(fish_id) > 0:
			_fish_ids.append(fish_id)


func _clamp_scroll_offset() -> void:
	var max_offset := maxi(0, _fish_ids.size() - VISIBLE_ROW_COUNT)
	_scroll_offset = clampi(_scroll_offset, 0, max_offset)


func _prune_quantities() -> void:
	for key in _sell_quantities.keys():
		var fish_id := String(key)
		var count := PlayerProgress.fish_count(fish_id)
		if count <= 0:
			_sell_quantities.erase(fish_id)
		else:
			_sell_quantities[fish_id] = clampi(int(_sell_quantities[fish_id]), 0, count)
			if int(_sell_quantities[fish_id]) <= 0:
				_sell_quantities.erase(fish_id)


func _resolve_selected_fish() -> void:
	if _fish_ids.is_empty():
		_selected_fish_id = ""
		_scroll_offset = 0
		return
	if _selected_fish_id.is_empty() or not _fish_ids.has(_selected_fish_id):
		_selected_fish_id = _fish_ids[_scroll_offset]
	var selected_index := _fish_ids.find(_selected_fish_id)
	if selected_index < _scroll_offset:
		_scroll_offset = selected_index
	elif selected_index >= _scroll_offset + VISIBLE_ROW_COUNT:
		_scroll_offset = selected_index - VISIBLE_ROW_COUNT + 1
	_clamp_scroll_offset()


func _refresh_status() -> void:
	if _status_bar != null and _status_bar.has_method("refresh"):
		_status_bar.call("refresh")


func _refresh_inventory() -> void:
	_inventory_title_label.text = "クーラーボックス"
	var total_pages := maxi(1, int(ceil(float(_fish_ids.size()) / float(VISIBLE_ROW_COUNT))))
	var current_page := 1 if _fish_ids.is_empty() else int(floor(float(_scroll_offset) / float(VISIBLE_ROW_COUNT))) + 1
	_page_label.text = "%d/%d" % [current_page, total_pages]
	_prev_page_button.disabled = _scroll_offset <= 0
	_next_page_button.disabled = _scroll_offset + VISIBLE_ROW_COUNT >= _fish_ids.size()
	if _inventory_empty_panel != null:
		_inventory_empty_panel.visible = _fish_ids.is_empty()

	for row_index in range(VISIBLE_ROW_COUNT):
		var fish_id := _visible_fish_id(row_index)
		var row: Dictionary = _row_nodes[row_index]
		var visible := not fish_id.is_empty()
		for key in row.keys():
			var control := row[key] as Control
			if control != null:
				control.visible = visible or key == "highlight"
		var highlight := row["highlight"] as ColorRect
		highlight.visible = visible and fish_id == _selected_fish_id
		var pointer := row["pointer"] as ColorRect
		pointer.visible = visible and fish_id == _selected_fish_id
		if not visible:
			continue
		var fish := GameData.get_fish(fish_id)
		var count := PlayerProgress.fish_count(fish_id)
		var price := int(fish.get("sell_price", 0))
		var quantity := int(_sell_quantities.get(fish_id, 0))

		(row["select_button"] as Button).set_meta("fish_id", fish_id)
		(row["fish_image"] as TextureRect).texture = ShowcaseAssetsScript.load_texture(FightFishAssets.card_portrait_path(fish))
		(row["name_label"] as Label).text = String(fish.get("name", fish_id))
		var rarity := String(fish.get("rarity", ""))
		var meta_label := row["meta_label"] as Label
		meta_label.text = rarity
		meta_label.add_theme_color_override("font_color", _row_rarity_color(rarity))
		(row["count_label"] as Label).text = "x%d" % count
		(row["price_label"] as Label).text = ScreenBase.format_money(price)
		(row["quantity_label"] as Label).text = str(quantity)
		(row["minus_button"] as Button).disabled = quantity <= 0
		(row["plus_button"] as Button).disabled = quantity >= count
		(row["all_button"] as Button).disabled = quantity >= count

	if _fish_ids.is_empty():
		_last_message = "売れる魚がありません。"


func _refresh_detail() -> void:
	if _selected_fish_id.is_empty():
		_detail_title_label.text = "売れる魚がありません"
		_detail_fish_image.texture = null
		_detail_rarity_label.text = ""
		_detail_body_label.text = "釣った魚はここで売却できます。\n釣り場へ向かいましょう。"
		_detail_price_label.text = "-"
		_detail_count_label.text = "-"
		_detail_subtotal_label.text = "-"
		return

	var fish := GameData.get_fish(_selected_fish_id)
	var count := PlayerProgress.fish_count(_selected_fish_id)
	var price := int(fish.get("sell_price", 0))
	var quantity := int(_sell_quantities.get(_selected_fish_id, 0))
	_detail_title_label.text = String(fish.get("name", _selected_fish_id))
	_detail_fish_image.texture = ShowcaseAssetsScript.load_texture(FightFishAssets.card_portrait_path(fish))
	var rarity := String(fish.get("rarity", ""))
	_detail_rarity_label.text = rarity
	_detail_rarity_label.add_theme_color_override("font_color", RarityStyles.text_color(rarity))
	_detail_body_label.text = "%s\n%s" % [
		String(fish.get("habitat", "")),
		"料理素材に残すか、装備資金へ。",
	]
	_detail_price_label.text = "単価 %s G" % ScreenBase.format_money(price)
	_detail_count_label.text = "所持 %d匹" % count
	_detail_subtotal_label.text = "選択 %s G" % ScreenBase.format_money(price * quantity)


func _refresh_cart() -> void:
	var summary := _cart_summary()
	var total_amount := int(summary["amount"])
	var total_income := int(summary["income"])
	var type_count := int(summary["types"])
	_cart_total_label.text = "%s G" % ScreenBase.format_money(total_income)
	_select_all_button.disabled = _fish_ids.is_empty()
	_cart_action_button.disabled = total_amount <= 0
	_cart_action_button.text = "まとめて売る" if total_amount <= 0 else "売却 %d匹" % total_amount

	if total_amount > 0:
		_last_message = "%d種 %d匹 / %s G" % [type_count, total_amount, ScreenBase.format_money(total_income)]
	var selected := _selected_order_ids()
	for index in range(_cart_thumbs.size()):
		var thumb := _cart_thumbs[index]
		if index < selected.size():
			thumb.texture = ShowcaseAssetsScript.load_texture(FightFishAssets.card_portrait_path(GameData.get_fish(selected[index])))
			thumb.modulate.a = 1.0
		else:
			thumb.texture = null
			thumb.modulate.a = 0.55
	_cart_title_label.text = _last_message


func _visible_fish_id(row_index: int) -> String:
	var index := _scroll_offset + row_index
	if index < 0 or index >= _fish_ids.size():
		return ""
	return _fish_ids[index]


func _row_rect(row_index: int) -> Rect2:
	return Rect2(72.0, ROW_START_Y + ROW_STEP_Y * float(row_index), 590.0, ROW_HEIGHT)


func _select_visible_row(row_index: int) -> void:
	var fish_id := _visible_fish_id(row_index)
	if fish_id.is_empty():
		return
	_selected_fish_id = fish_id
	_refresh()


func _adjust_visible_row(row_index: int, delta: int) -> void:
	var fish_id := _visible_fish_id(row_index)
	if fish_id.is_empty():
		return
	_selected_fish_id = fish_id
	_set_quantity(fish_id, int(_sell_quantities.get(fish_id, 0)) + delta)


func _set_visible_row_all(row_index: int) -> void:
	var fish_id := _visible_fish_id(row_index)
	if fish_id.is_empty():
		return
	_selected_fish_id = fish_id
	_set_quantity(fish_id, PlayerProgress.fish_count(fish_id))


func _set_quantity(fish_id: String, amount: int) -> void:
	var count := PlayerProgress.fish_count(fish_id)
	var next_amount := clampi(amount, 0, count)
	if next_amount <= 0:
		_sell_quantities.erase(fish_id)
	else:
		_sell_quantities[fish_id] = next_amount
	_refresh()


func _select_all_fish() -> void:
	for fish_id in _fish_ids:
		_sell_quantities[fish_id] = PlayerProgress.fish_count(fish_id)
	_last_message = "クーラーボックス内の魚をすべて売却候補に入れました。"
	_refresh()


func _change_page(delta: int) -> void:
	if _fish_ids.is_empty():
		return
	_scroll_offset = clampi(_scroll_offset + delta * VISIBLE_ROW_COUNT, 0, maxi(0, _fish_ids.size() - VISIBLE_ROW_COUNT))
	_selected_fish_id = _fish_ids[_scroll_offset]
	_refresh()


func _show_confirm_overlay() -> void:
	var summary := _cart_summary()
	var total_amount := int(summary["amount"])
	if total_amount <= 0:
		_last_message = "売る魚を選んでください。"
		_refresh_cart()
		return
	var body := "%d種類・%d匹を売却します。\n受け取り: %s G" % [
		int(summary["types"]),
		total_amount,
		ScreenBase.format_money(int(summary["income"])),
	]
	if _has_last_fish_warning():
		body += "\n\n選んだ中に最後の1匹が含まれています。料理素材としては残りません。"
	_confirm_body_label.text = body
	_confirm_overlay.visible = true


func _hide_confirm_overlay() -> void:
	_confirm_overlay.visible = false


func _confirm_sell() -> void:
	var result := PlayerProgress.sell_fish_batch(_sell_quantities)
	_confirm_overlay.visible = false
	if bool(result.get("ok", false)):
		_last_message = "売却完了 +%s G" % ScreenBase.format_money(int(result.get("income", 0)))
		_sell_quantities.clear()
		_rebuild_fish_ids()
		_scroll_offset = 0
		_selected_fish_id = ""
	else:
		_last_message = String(result.get("message", "売却できませんでした。"))
	_refresh()


func _cart_summary() -> Dictionary:
	var income := 0
	var amount := 0
	var types := 0
	for key in _sell_quantities.keys():
		var fish_id := String(key)
		var quantity := int(_sell_quantities[fish_id])
		if quantity <= 0:
			continue
		var fish := GameData.get_fish(fish_id)
		if fish.is_empty():
			continue
		types += 1
		amount += quantity
		income += int(fish.get("sell_price", 0)) * quantity
	return {
		"income": income,
		"amount": amount,
		"types": types,
	}


func _selected_order_ids() -> Array[String]:
	var selected: Array[String] = []
	for fish_id in GameData.get_all_fish_ids():
		if int(_sell_quantities.get(fish_id, 0)) > 0:
			selected.append(fish_id)
	return selected


func _has_last_fish_warning() -> bool:
	for key in _sell_quantities.keys():
		var fish_id := String(key)
		var quantity := int(_sell_quantities[fish_id])
		if quantity > 0 and quantity >= PlayerProgress.fish_count(fish_id):
			return true
	return false


func _market_label(text: String, font_size: int, color: Color, outline: int = 0) -> Label:
	var label := make_screen_label(text, font_size, color, true, outline, Palette.TEXT_OUTLINE_DARK, Color(0.0, 0.0, 0.0, 0.0), true)
	label.z_index = 30
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _market_button(text: String, callback: Callable, primary: bool = false, font_size: int = 18) -> Button:
	var button := Button.new()
	button.z_index = 20
	button.text = text
	button.pressed.connect(callback)
	button.add_theme_font_override("font", GameFontsScript.bold(get_theme_default_font()))
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Palette.TEXT_BONE if not primary else Palette.TEXT_DARK)
	button.add_theme_color_override("font_hover_color", Palette.GOLD_BRIGHT if not primary else Palette.TEXT_DARK)
	button.add_theme_color_override("font_pressed_color", Palette.GOLD_BRIGHT if not primary else Palette.TEXT_DARK)
	button.add_theme_color_override("font_disabled_color", _with_alpha(Palette.TEXT_BONE, 0.45))
	button.add_theme_color_override("font_outline_color", Palette.TEXT_OUTLINE_DARK)
	button.add_theme_constant_override("outline_size", 1 if not primary else 0)
	var normal := _button_style(primary, false)
	var hover := _button_style(primary, true)
	var pressed := _button_style(primary, true)
	var disabled := _button_style(primary, false)
	disabled.bg_color = _with_alpha(Palette.DARK_PANEL_DEEP, 0.28)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", hover)
	_wire_button_juice(button)
	return button


func _button_style(primary: bool, hover: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _with_alpha(Palette.GOLD if primary else Palette.DARK_PANEL_DEEP, 0.92 if primary else 0.72)
	if hover:
		style.bg_color = _with_alpha(Palette.GOLD_BRIGHT if primary else Palette.BLUE_PANEL, 0.96 if primary else 0.86)
	style.border_color = Palette.GOLD_DEEP if primary else Palette.GOLD
	style.set_border_width_all(1 if not primary else 3)
	style.set_corner_radius_all(5)
	style.shadow_color = _with_alpha(Palette.TEXT_OUTLINE_DARK, 0.28 if primary else 0.18)
	style.shadow_size = 4 if primary else 2
	style.shadow_offset = Vector2(0.0, 2.0)
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style


func _market_field_panel(bg: Color, border: Color, alpha: float) -> Panel:
	var panel := Panel.new()
	panel.z_index = 12
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = _with_alpha(bg, alpha)
	style.border_color = _with_alpha(border, 0.82)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.shadow_color = _with_alpha(Palette.TEXT_OUTLINE_DARK, 0.12)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0.0, 1.0)
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _row_rarity_color(rarity: String) -> Color:
	match rarity:
		"アンコモン":
			return Palette.RARITY_UNCOMMON_BADGE
		"レア":
			return Palette.RARITY_RARE_BADGE
		"ぬし":
			return Palette.GOLD_DEEP
		_:
			return Palette.TEXT_BODY


func _make_button_transparent(button: Button) -> void:
	var empty := StyleBoxEmpty.new()
	button.add_theme_stylebox_override("normal", empty)
	button.add_theme_stylebox_override("hover", empty)
	button.add_theme_stylebox_override("pressed", empty)
	button.add_theme_stylebox_override("disabled", empty)
	button.add_theme_stylebox_override("focus", empty)


func _panel_style(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _with_alpha(bg, 0.96)
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style


func _place(parent: Control, child: Control, rect: Rect2) -> void:
	child.position = rect.position
	child.size = rect.size
	child.custom_minimum_size = rect.size
	parent.add_child(child)


func _with_alpha(color: Color, alpha: float) -> Color:
	var result := color
	result.a = alpha
	return result
