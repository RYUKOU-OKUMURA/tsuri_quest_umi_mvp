extends "res://src/ui/screen_base.gd"

const FishingSpotMapViewScript = preload("res://src/ui/components/fishing_spot_map_view.gd")

const HEADER_FRAME_PATH := "res://assets/showcase/fishing_spots/map_header_frame.png"
const DETAIL_FRAME_PATH := "res://assets/showcase/fishing_spots/map_detail_frame.png"
const DETAIL_ICON_SHEET_PATH := "res://assets/showcase/fishing_spots/map_detail_icon_sheet.png"
const FOOTER_FRAME_PATH := "res://assets/showcase/fishing_spots/map_footer_frame.png"
const ROUTE_CHIP_FRAME_PATH := "res://assets/showcase/fishing_spots/map_route_chip_frame.png"
const ROUTE_CHIP_FRAME_LOCKED_PATH := "res://assets/showcase/fishing_spots/map_route_chip_frame_locked.png"
const THUMB_BASE_PATH := "res://assets/showcase/fishing_spots/thumbs"
const DETAIL_ICON_SIZE := 96.0
const ROUTE_CHIP_SIZE := Vector2(214.0, 50.0)

var _selected_spot_id: String = GameData.DEFAULT_FISHING_SPOT_ID
var _continue_trip := false
var _trip_stats: Dictionary = {}

var _map_view: FishingSpotMapView
var _message_label: Label
var _detail_title_label: Label
var _detail_unlock_label: Label
var _detail_description_label: Label
var _detail_thumbnail: TextureRect
var _detail_depth_value_label: Label
var _detail_fish_value_label: Label
var _detail_bait_value_label: Label
var _detail_hint_value_label: Label
var _action_button: Button
var _progress_box: GridContainer

var _header_frame: Texture2D
var _detail_frame: Texture2D
var _detail_icon_sheet: Texture2D
var _footer_frame: Texture2D
var _route_chip_frame: Texture2D
var _route_chip_frame_locked: Texture2D


func _build_screen() -> void:
	_resolve_route_state()
	_load_assets()
	add_gradient_background(Color("#08223a"), Color("#030d18"))

	var root := make_root_margin(10)
	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 8)
	root.add_child(layout)

	_build_header(layout)

	var body := HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	layout.add_child(body)

	_build_map_panel(body)
	_build_detail_panel(body)
	_build_footer(layout)
	_focus_spot(_selected_spot_id, false)


func _resolve_route_state() -> void:
	var incoming_stats = route_payload.get("trip_stats", {})
	if typeof(incoming_stats) == TYPE_DICTIONARY:
		_trip_stats = incoming_stats.duplicate(true)
	_continue_trip = (
		bool(route_payload.get("from_fishing", false))
		or bool(route_payload.get("continue_trip", false))
		or not _trip_stats.is_empty()
	)
	var requested_id := String(
		route_payload.get(
			"current_spot_id",
			route_payload.get("spot_id", GameData.DEFAULT_FISHING_SPOT_ID)
		)
	)
	var requested_spot := GameData.get_fishing_spot(requested_id)
	if requested_spot.is_empty():
		requested_id = GameData.DEFAULT_FISHING_SPOT_ID
	if not GameData.is_fishing_spot_unlocked(requested_id, PlayerProgress.level):
		requested_id = GameData.DEFAULT_FISHING_SPOT_ID
	_selected_spot_id = requested_id


func _load_assets() -> void:
	_header_frame = _load_texture_if_exists(HEADER_FRAME_PATH)
	_detail_frame = _load_texture_if_exists(DETAIL_FRAME_PATH)
	_detail_icon_sheet = _load_texture_if_exists(DETAIL_ICON_SHEET_PATH)
	_footer_frame = _load_texture_if_exists(FOOTER_FRAME_PATH)
	_route_chip_frame = _load_texture_if_exists(ROUTE_CHIP_FRAME_PATH)
	_route_chip_frame_locked = _load_texture_if_exists(ROUTE_CHIP_FRAME_LOCKED_PATH)


func _header_subtitle() -> String:
	var trip_text := "　釣行継続中：ポイント変更" if _continue_trip else ""
	return "Lv.%d　%s　所持金 %d G%s" % [
		PlayerProgress.level,
		String(GameData.get_rod(PlayerProgress.equipped_rod_id).get("name", "入門竿")),
		PlayerProgress.money,
		trip_text,
	]


func _build_header(parent: Control) -> void:
	var panel := Control.new()
	panel.custom_minimum_size = Vector2(0.0, 84.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.clip_contents = true
	parent.add_child(panel)

	if _header_frame != null:
		var frame := TextureRect.new()
		frame.texture = _header_frame
		frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frame.stretch_mode = TextureRect.STRETCH_SCALE
		frame.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(frame)
	else:
		var fallback := make_panel(true)
		fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(fallback)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 28)
	margin.add_child(row)

	var title_box := VBoxContainer.new()
	title_box.custom_minimum_size = Vector2(390.0, 0.0)
	title_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 0)
	row.add_child(title_box)

	var title := make_label("釣り場を選ぶ", 28, Palette.TEXT_BONE, 3, Palette.TEXT_OUTLINE_DARK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	title_box.add_child(title)

	var subtitle_text := "航路図から出航先を指定"
	if _continue_trip:
		subtitle_text = "釣行継続中：ポイント変更"
	var subtitle := make_label(subtitle_text, 14, Color("#15304a"))
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_child(subtitle)

	var status_row := HBoxContainer.new()
	status_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	status_row.add_theme_constant_override("separation", 10)
	row.add_child(status_row)
	status_row.add_child(_make_header_status_cell("Lv.", "%d" % PlayerProgress.level))
	status_row.add_child(_make_header_status_cell("装備", String(GameData.get_rod(PlayerProgress.equipped_rod_id).get("name", "入門竿"))))
	status_row.add_child(_make_header_status_cell("所持金", "%d G" % PlayerProgress.money))


func _make_header_status_cell(title: String, value: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 0)
	var title_label := make_label(title, 12, Color("#96cde8"), 1, Palette.TEXT_OUTLINE_DARK)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(title_label)
	var value_label := make_label(value, 16, Palette.TEXT_BONE, 2, Palette.TEXT_OUTLINE_DARK)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	value_label.clip_text = true
	value_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(value_label)
	return box


func _build_map_panel(parent: Control) -> void:
	var panel := make_panel(true)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.clip_contents = true
	parent.add_child(panel)

	_map_view = FishingSpotMapViewScript.new()
	_map_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_view.configure(_selected_spot_id, PlayerProgress.level)
	_map_view.spot_focused.connect(func(spot_id: String) -> void: _focus_spot(spot_id))
	_map_view.spot_selected.connect(func(spot_id: String) -> void: _focus_spot(spot_id))
	_map_view.locked_spot_pressed.connect(_show_locked_message)
	panel.add_child(_map_view)


func _build_detail_panel(parent: Control) -> void:
	var panel := Control.new()
	panel.custom_minimum_size = Vector2(360.0, 0.0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.clip_contents = true
	parent.add_child(panel)

	if _detail_frame != null:
		var frame := TextureRect.new()
		frame.texture = _detail_frame
		frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frame.stretch_mode = TextureRect.STRETCH_SCALE
		frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(frame)
	else:
		var fallback := ColorRect.new()
		fallback.color = Color("#ead3a0")
		fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(fallback)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)

	_detail_title_label = make_label("", 24, Palette.TEXT_BONE, 2, Palette.TEXT_OUTLINE_DARK)
	_detail_title_label.custom_minimum_size = Vector2(0.0, 42.0)
	_detail_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_detail_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_title_label.clip_text = true
	_detail_title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(_detail_title_label)

	_detail_unlock_label = make_label("", 13, Palette.TEXT_BONE, 1, Palette.TEXT_OUTLINE_DARK)
	_detail_unlock_label.custom_minimum_size = Vector2(0.0, 18.0)
	_detail_unlock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_unlock_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_detail_unlock_label)

	var thumb_clip := Control.new()
	thumb_clip.custom_minimum_size = Vector2(0.0, 78.0)
	thumb_clip.clip_contents = true
	thumb_clip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(thumb_clip)

	_detail_thumbnail = TextureRect.new()
	_detail_thumbnail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_detail_thumbnail.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_detail_thumbnail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_detail_thumbnail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb_clip.add_child(_detail_thumbnail)

	_detail_description_label = make_label("", 12, Color("#2f2114"))
	_detail_description_label.custom_minimum_size = Vector2(0.0, 36.0)
	_detail_description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(_detail_description_label)

	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	rows.add_theme_constant_override("separation", 2)
	box.add_child(rows)
	_detail_depth_value_label = _make_detail_row(rows, 0, "水深")
	_detail_fish_value_label = _make_detail_row(rows, 1, "狙い")
	_detail_bait_value_label = _make_detail_row(rows, 2, "エサ")
	_detail_hint_value_label = _make_detail_row(rows, 3, "気配")

	var button_box := VBoxContainer.new()
	button_box.size_flags_vertical = Control.SIZE_SHRINK_END
	button_box.add_theme_constant_override("separation", 4)
	box.add_child(button_box)

	_action_button = make_button("ここで釣る", func() -> void: _select_spot(_selected_spot_id), 0, true)
	_action_button.custom_minimum_size.y = 34.0
	_action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_box.add_child(_action_button)

	var back := make_button("港へ戻る", func() -> void: navigate("harbor"), 0)
	back.custom_minimum_size.y = 32.0
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_box.add_child(back)


func _make_detail_row(parent: Control, icon_index: int, title: String) -> Label:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0.0, 31.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _detail_row_style())
	parent.add_child(panel)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(24.0, 24.0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _detail_icon(icon_index)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	var title_label := make_label(title, 12, Color("#775126"))
	title_label.custom_minimum_size = Vector2(34.0, 0.0)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(title_label)

	var value_label := make_label("", 13, Color("#1d1209"))
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	value_label.clip_text = true
	value_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(value_label)
	return value_label


func _detail_row_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#ead8ad", 0.94)
	style.border_color = Color("#876036", 0.30)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 5
	style.content_margin_right = 5
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	return style


func _build_footer(parent: Control) -> void:
	var panel := Control.new()
	panel.custom_minimum_size = Vector2(0.0, 134.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)

	if _footer_frame != null:
		var frame := TextureRect.new()
		frame.texture = _footer_frame
		frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frame.stretch_mode = TextureRect.STRETCH_SCALE
		frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(frame)
	else:
		var fallback := ColorRect.new()
		fallback.color = Color("#082842")
		fallback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(fallback)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	_progress_box = GridContainer.new()
	_progress_box.columns = 4
	_progress_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_progress_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_progress_box.add_theme_constant_override("h_separation", 8)
	_progress_box.add_theme_constant_override("v_separation", 8)
	row.add_child(_progress_box)

	var message_box := VBoxContainer.new()
	message_box.custom_minimum_size = Vector2(264.0, 0.0)
	message_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	message_box.add_theme_constant_override("separation", 4)
	row.add_child(message_box)

	var guide := make_label("調査メモ", 14, Palette.TEXT_BONE, 1, Palette.TEXT_OUTLINE_DARK)
	guide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_box.add_child(guide)

	_message_label = make_label("", 12, Color("#eaf6ff"), 1, Palette.TEXT_OUTLINE_DARK)
	_message_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_label.add_theme_constant_override("line_spacing", 1)
	_message_label.clip_text = true
	message_box.add_child(_message_label)


func _rebuild_completion_entries() -> void:
	if _progress_box == null:
		return
	for child in _progress_box.get_children():
		child.queue_free()
	for spot_id in GameData.get_all_fishing_spot_ids():
		_progress_box.add_child(_make_completion_entry(GameData.get_fishing_spot(spot_id)))


func _make_completion_entry(spot: Dictionary) -> Control:
	var spot_id := String(spot.get("id", GameData.DEFAULT_FISHING_SPOT_ID))
	var unlocked := GameData.is_fishing_spot_unlocked(spot_id, PlayerProgress.level)
	var selected := spot_id == _selected_spot_id
	var completion := _spot_completion_counts(spot)
	var entry := Control.new()
	entry.clip_contents = true
	entry.custom_minimum_size = ROUTE_CHIP_SIZE
	entry.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	entry.mouse_filter = Control.MOUSE_FILTER_IGNORE
	entry.set_meta("spot_progress_entry", true)
	entry.set_meta("spot_id", spot_id)
	entry.set_meta("locked", not unlocked)
	entry.set_meta("caught_species", int(completion.get("caught", 0)))
	entry.set_meta("target_species", int(completion.get("total", 0)))

	var frame_texture := _route_chip_frame if unlocked else _route_chip_frame_locked
	if frame_texture != null:
		var frame := TextureRect.new()
		frame.texture = frame_texture
		frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frame.stretch_mode = TextureRect.STRETCH_SCALE
		frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		entry.add_child(frame)
	else:
		_add_route_chip_fallback(entry, unlocked)
	_add_route_chip_body_wash(entry, unlocked)

	var title := _card_label(String(spot.get("name", spot_id)), 14, Color("#fff2d2") if unlocked else Color("#d5cec1"), 1)
	title.position = Vector2(12.0, 4.0)
	title.size = Vector2(ROUTE_CHIP_SIZE.x - 68.0, 20.0)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	entry.add_child(title)

	var badge_text := "表示中" if selected else _completion_badge_text(spot, unlocked, completion)
	var badge := _card_label(badge_text, 12, Palette.GOLD_BRIGHT if selected else (Palette.GOLD_DEEP if unlocked else Color("#6b5740")), 1 if selected else 0)
	badge.position = Vector2(ROUTE_CHIP_SIZE.x - 60.0, 5.0)
	badge.size = Vector2(48.0, 18.0)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	entry.add_child(badge)

	var body_color := Color("#23170d") if unlocked else Color("#4f4941")
	var summary_text := _completion_summary_text(spot, unlocked, completion)
	var summary := _card_label(summary_text, 11, body_color)
	summary.position = Vector2(14.0, 28.0)
	summary.size = Vector2(ROUTE_CHIP_SIZE.x - 28.0, 14.0)
	summary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	entry.add_child(summary)

	_add_completion_bar(entry, unlocked, selected, float(completion.get("ratio", 0.0)))
	return entry


func _add_route_chip_fallback(parent: Control, unlocked: bool) -> void:
	var body := ColorRect.new()
	body.color = Color("#ebd5a7") if unlocked else Color("#b7b0a0")
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(body)

	var header := ColorRect.new()
	header.color = Color("#0a3b57") if unlocked else Color("#4b514f")
	header.anchor_left = 0.0
	header.anchor_top = 0.0
	header.anchor_right = 1.0
	header.anchor_bottom = 0.0
	header.offset_left = 5.0
	header.offset_top = 5.0
	header.offset_right = -5.0
	header.offset_bottom = 25.0
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(header)


func _add_route_chip_body_wash(parent: Control, unlocked: bool) -> void:
	var wash := ColorRect.new()
	wash.color = Color("#f7e6ba", 0.20) if unlocked else Color("#d6cfba", 0.16)
	wash.anchor_left = 0.0
	wash.anchor_top = 0.0
	wash.anchor_right = 1.0
	wash.anchor_bottom = 1.0
	wash.offset_left = 8.0
	wash.offset_top = 29.0
	wash.offset_right = -8.0
	wash.offset_bottom = -6.0
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(wash)


func _add_completion_bar(parent: Control, unlocked: bool, selected: bool, ratio: float) -> void:
	var back := ColorRect.new()
	back.color = Color("#5c5143", 0.52) if unlocked else Color("#736d63", 0.44)
	back.position = Vector2(14.0, 43.0)
	back.size = Vector2(ROUTE_CHIP_SIZE.x - 28.0, 4.0)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(back)

	var fill := ColorRect.new()
	fill.color = Palette.GOLD_BRIGHT if selected else Color("#d39135")
	fill.position = back.position
	fill.size = Vector2(back.size.x * clampf(ratio, 0.0, 1.0), back.size.y)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(fill)


func _card_label(text: String, font_size: int, color: Color, outline: int = 0) -> Label:
	var label := make_label(text, font_size, color, outline, Palette.TEXT_OUTLINE_DARK)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return label


func _focus_spot(spot_id: String, update_message: bool = true) -> void:
	if GameData.get_fishing_spot(spot_id).is_empty():
		return
	_selected_spot_id = spot_id
	if _map_view != null:
		_map_view.set_selected_spot(spot_id)
	_refresh_detail()
	_rebuild_completion_entries()
	if update_message or (_message_label != null and _message_label.text.is_empty()):
		var spot := GameData.get_fishing_spot(spot_id)
		if GameData.is_fishing_spot_unlocked(spot_id, PlayerProgress.level):
			_message_label.text = "%s を航路図で指定中。右の「ここで釣る」から出航できます。" % String(spot.get("name", spot_id))
		else:
			_show_locked_message(spot_id)


func _refresh_detail() -> void:
	var spot := GameData.get_fishing_spot(_selected_spot_id)
	if spot.is_empty():
		return
	var unlocked := GameData.is_fishing_spot_unlocked(_selected_spot_id, PlayerProgress.level)
	var boss_spot := bool(spot.get("boss_spot", false))
	_detail_title_label.text = String(spot.get("name", _selected_spot_id))
	_detail_title_label.add_theme_font_size_override("font_size", 22 if _detail_title_label.text.length() >= 9 else 24)
	if unlocked:
		_detail_unlock_label.text = "解放済み　%s" % ("ぬし専用" if boss_spot else "通常ポイント")
		_detail_unlock_label.add_theme_color_override("font_color", Color("#f2cf7d") if not boss_spot else Color("#ffb58d"))
	else:
		_detail_unlock_label.text = "未解放　Lv.%dで出航可能" % int(spot.get("unlock_level", 1))
		_detail_unlock_label.add_theme_color_override("font_color", Color("#ffb0a0"))
	if _detail_thumbnail != null:
		_detail_thumbnail.texture = _thumbnail_for_spot(_selected_spot_id)
	_detail_description_label.text = String(spot.get("description", ""))
	_detail_depth_value_label.text = _depth_range_text(spot)
	_detail_fish_value_label.text = _featured_fish_text(spot, 4)
	_detail_bait_value_label.text = _bait_text(spot)
	_detail_hint_value_label.text = "ぬしの気配" if boss_spot else _rare_hint_text(spot)
	if _action_button != null:
		_action_button.disabled = not unlocked
		_action_button.text = "ここで釣る" if unlocked else "Lv.%dで解放" % int(spot.get("unlock_level", 1))


func _select_spot(spot_id: String) -> void:
	if not GameData.is_fishing_spot_unlocked(spot_id, PlayerProgress.level):
		_show_locked_message(spot_id)
		return
	var payload := {"spot_id": spot_id}
	if _continue_trip:
		payload["continue_trip"] = true
		payload["trip_stats"] = _trip_stats.duplicate(true)
	navigate("fishing", payload)


func _show_locked_message(spot_id: String) -> void:
	if _message_label == null:
		return
	var spot := GameData.get_fishing_spot(spot_id)
	_message_label.text = "%s は Lv.%d で解放されます。現在は出航できません。" % [
		String(spot.get("name", spot_id)),
		int(spot.get("unlock_level", 1)),
	]


func _depth_range_text(spot: Dictionary) -> String:
	var range: Array = spot.get("depth_range", [0.0, 0.0])
	if range.size() < 2:
		return "--.-m"
	return "%.1f〜%.1fm" % [float(range[0]), float(range[1])]


func _featured_fish_text(spot: Dictionary, limit: int = 5) -> String:
	var names: Array[String] = []
	for fish_id_variant in Array(spot.get("featured_fish", [])):
		var fish := GameData.get_fish(String(fish_id_variant))
		if fish.is_empty():
			continue
		names.append(String(fish.get("name", fish_id_variant)))
		if names.size() >= limit:
			break
	return "、".join(PackedStringArray(names))


func _bait_text(spot: Dictionary) -> String:
	var baits: Array[String] = []
	for bait_variant in Array(spot.get("recommended_baits", [])):
		baits.append(String(bait_variant))
	return "、".join(PackedStringArray(baits))


func _spot_completion_counts(spot: Dictionary) -> Dictionary:
	var spot_id := String(spot.get("id", GameData.DEFAULT_FISHING_SPOT_ID))
	var target_fish := Array(spot.get("featured_fish", []))
	var spot_counts: Dictionary = {}
	var loaded_spot_counts = PlayerProgress.spot_caught_counts.get(spot_id, {})
	if typeof(loaded_spot_counts) == TYPE_DICTIONARY:
		spot_counts = loaded_spot_counts

	var caught := 0
	for fish_id_variant in target_fish:
		var fish_id := String(fish_id_variant)
		if int(spot_counts.get(fish_id, 0)) > 0:
			caught += 1
	var total := target_fish.size()
	var ratio := 0.0 if total <= 0 else float(caught) / float(total)
	return {
		"caught": caught,
		"total": total,
		"ratio": ratio,
	}


func _completion_badge_text(spot: Dictionary, unlocked: bool, completion: Dictionary) -> String:
	if not unlocked:
		return "LOCK"
	if bool(spot.get("boss_spot", false)):
		return "%d/%d" % [int(completion.get("caught", 0)), int(completion.get("total", 0))]
	return "%d%%" % int(round(float(completion.get("ratio", 0.0)) * 100.0))


func _completion_summary_text(spot: Dictionary, unlocked: bool, completion: Dictionary) -> String:
	if not unlocked:
		return "未解放 Lv.%d" % int(spot.get("unlock_level", 1))
	return "達成度 %d/%d 種" % [
		int(completion.get("caught", 0)),
		int(completion.get("total", 0)),
	]


func _rare_hint_text(spot: Dictionary) -> String:
	var unlock_level := int(spot.get("unlock_level", 1))
	if unlock_level >= 6:
		return "大物の回遊あり"
	if unlock_level >= 4:
		return "レア魚の気配"
	return "安定した反応"


func _detail_icon(icon_index: int) -> Texture2D:
	if _detail_icon_sheet == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = _detail_icon_sheet
	atlas.region = Rect2(Vector2(DETAIL_ICON_SIZE * float(icon_index), 0.0), Vector2(DETAIL_ICON_SIZE, DETAIL_ICON_SIZE))
	return atlas


func _thumbnail_for_spot(spot_id: String) -> Texture2D:
	var path := "%s/%s.png" % [THUMB_BASE_PATH, spot_id]
	return _load_texture_if_exists(path)


func _load_texture_if_exists(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null
