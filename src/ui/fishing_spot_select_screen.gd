extends "res://src/ui/screen_base.gd"

const FishingSpotMapViewScript = preload("res://src/ui/components/fishing_spot_map_view.gd")
const PlayerStatusBarScript = preload("res://src/ui/components/player_status_bar.gd")

const HEADER_FRAME_PATH := "res://assets/showcase/fishing_spots/map_header_frame.png"
const TITLE_SIGN_PATH := "res://assets/showcase/fishing_spots/map_title_sign.png"
const DETAIL_FRAME_PATH := "res://assets/showcase/fishing_spots/map_detail_frame.png"
const DETAIL_ICON_SHEET_PATH := "res://assets/showcase/fishing_spots/map_detail_icon_sheet.png"
const FOOTER_FRAME_PATH := "res://assets/showcase/fishing_spots/map_footer_frame.png"
const FOOTER_ICON_SHEET_PATH := "res://assets/showcase/fishing_spots/map_footer_icon_sheet.png"
const THUMB_BASE_PATH := "res://assets/showcase/fishing_spots/thumbs"
const MAP_BGM_VOLUME_DB := -12.0
const MAP_BGM_PATH_BY_SPOT := {
	"harbor_pier": "res://assets/audio/港外・潮目.mp3",
	"shallow_sand": "res://assets/audio/砂浜・かけあがり.mp3",
	"rock_breakwater": "res://assets/audio/岩礁・消波ブロック.mp3",
	"outer_tide": "res://assets/audio/港外・潮目.mp3",
	"south_reef": "res://assets/audio/岩礁・消波ブロック.mp3",
	"bluewater_route": "res://assets/audio/外海・回遊ルート.mp3",
	"deep_ocean": "res://assets/audio/外海・回遊ルート.mp3",
	"harbor_boulder": "res://assets/audio/港外・潮目.mp3",
}
const DETAIL_ICON_SIZE := 96.0
const FOOTER_ICON_SIZE := 96.0
const COMPLETION_SLOT_SIZE := Vector2(220.0, 44.0)
const DETAIL_FRAME_SOURCE_SIZE := Vector2(520.0, 760.0)

var _selected_spot_id: String = GameData.DEFAULT_FISHING_SPOT_ID
var _continue_trip := false
var _trip_stats: Dictionary = {}

var _map_view: FishingSpotMapView
var _message_label: Label
var _message_detail_label: Label
var _detail_title_label: Label
var _detail_unlock_label: Label
var _detail_description_label: Label
var _detail_thumbnail: TextureRect
var _detail_depth_value_label: Label
var _detail_fish_value_label: Label
var _detail_bait_value_label: Label
var _detail_hint_value_label: Label
var _detail_rig_value_label: Label
var _rig_cycle_button: Button
var _action_button: Button
var _footer_completion_value_label: Label
var _footer_completion_fill: ColorRect
var _footer_completion_back: ColorRect

var _header_frame: Texture2D
var _title_sign_frame: Texture2D
var _detail_frame: Texture2D
var _detail_icon_sheet: Texture2D
var _footer_frame: Texture2D
var _footer_icon_sheet: Texture2D


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
	if not PlayerProgress.can_access_fishing_spot(requested_id):
		requested_id = GameData.DEFAULT_FISHING_SPOT_ID
	_selected_spot_id = requested_id


func _load_assets() -> void:
	_header_frame = _load_texture_if_exists(HEADER_FRAME_PATH)
	_title_sign_frame = _load_texture_if_exists(TITLE_SIGN_PATH)
	_detail_frame = _load_texture_if_exists(DETAIL_FRAME_PATH)
	_detail_icon_sheet = _load_texture_if_exists(DETAIL_ICON_SHEET_PATH)
	_footer_frame = _load_texture_if_exists(FOOTER_FRAME_PATH)
	_footer_icon_sheet = _load_texture_if_exists(FOOTER_ICON_SHEET_PATH)


func _build_header(parent: Control) -> void:
	var panel := Control.new()
	panel.custom_minimum_size = Vector2(0.0, 88.0)
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

	if _title_sign_frame != null:
		var title_sign := TextureRect.new()
		title_sign.texture = _title_sign_frame
		title_sign.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		title_sign.stretch_mode = TextureRect.STRETCH_SCALE
		title_sign.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		title_sign.position = Vector2(-4.0, -10.0)
		title_sign.size = Vector2(490.0, 104.0)
		title_sign.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(title_sign)
	else:
		var title_plate := PanelContainer.new()
		title_plate.position = Vector2(18.0, 12.0)
		title_plate.size = Vector2(430.0, 72.0)
		title_plate.add_theme_stylebox_override("panel", _header_title_plate_style())
		panel.add_child(title_plate)

	var title := make_shadow_label("釣り場を選ぶ", 38, Color("#241107"), 2, Color("#f5d98d"), Color("#6a3d18"))
	title.z_index = 20
	title.position = Vector2(142.0, 10.0)
	title.size = Vector2(320.0, 66.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	panel.add_child(title)

	var status_rect := Rect2(Vector2(650.0, 15.0), Vector2(596.0, 60.0))
	var status_bar := PlayerStatusBarScript.new()
	status_bar.name = "FishingSpotPlayerStatusBar"
	status_bar.z_index = 20
	status_bar.position = status_rect.position
	status_bar.size = status_rect.size
	panel.add_child(status_bar)


func _add_header_status(parent: Control, rect: Rect2, caption: String, value: String) -> Label:
	var box := PanelContainer.new()
	box.position = rect.position
	box.size = rect.size
	box.add_theme_stylebox_override("panel", _header_status_style())
	parent.add_child(box)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 0)
	box.add_child(layout)

	var caption_label := make_label(caption, 11, Color("#b8c4cf"), 1, Palette.TEXT_OUTLINE_DARK)
	caption_label.custom_minimum_size = Vector2(0.0, 18.0)
	caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(caption_label)

	var rule := ColorRect.new()
	rule.custom_minimum_size = Vector2(0.0, 1.0)
	rule.color = Color("#d4a85b", 0.42)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(rule)

	var value_label := make_label(value, 17, Palette.TEXT_BONE, 1, Palette.TEXT_OUTLINE_DARK)
	value_label.custom_minimum_size = Vector2(0.0, 31.0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.clip_text = true
	value_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	layout.add_child(value_label)
	return value_label


func _add_rivet(parent: Control, position: Vector2) -> void:
	var rivet := PanelContainer.new()
	rivet.position = position
	rivet.size = Vector2(8.0, 8.0)
	rivet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rivet.add_theme_stylebox_override("panel", _rivet_style())
	parent.add_child(rivet)


func _rivet_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#614224", 0.96)
	style.border_color = Color("#e8c176", 0.72)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style


func _header_title_plate_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#d7b36d", 0.94)
	style.border_color = Color("#8a5728", 0.92)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 6
	style.content_margin_bottom = 5
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.30)
	style.shadow_size = 4
	style.shadow_offset = Vector2(2.0, 2.0)
	return style


func _header_status_group_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#041b2e", 0.36)
	style.border_color = Color("#d0a65a", 0.46)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.16)
	style.shadow_size = 2
	style.shadow_offset = Vector2(1.0, 1.0)
	return style


func _header_status_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#052d49", 0.88)
	style.border_color = Color("#d1a458", 0.80)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 3
	style.content_margin_bottom = 4
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.20)
	style.shadow_size = 2
	style.shadow_offset = Vector2(1.0, 1.0)
	return style


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
	panel.custom_minimum_size = Vector2(370.0, 0.0)
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

	_detail_title_label = make_label("", 24, Palette.TEXT_BONE, 2, Palette.TEXT_OUTLINE_DARK)
	_detail_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_detail_title_label.clip_text = true
	_detail_title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_add_detail_frame_child(panel, _detail_title_label, Rect2(44.0, 31.0, 432.0, 60.0))

	_detail_unlock_label = make_label("", 12, Palette.TEXT_BONE, 1, Palette.TEXT_OUTLINE_DARK)
	_detail_unlock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_unlock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_detail_unlock_label.clip_text = true
	_detail_unlock_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_add_detail_frame_child(panel, _detail_unlock_label, Rect2(44.0, 88.0, 432.0, 24.0))

	var thumb_clip := Control.new()
	thumb_clip.clip_contents = true
	_add_detail_frame_child(panel, thumb_clip, Rect2(44.0, 112.0, 432.0, 157.0))

	_detail_thumbnail = TextureRect.new()
	_detail_thumbnail.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_detail_thumbnail.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_detail_thumbnail.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_detail_thumbnail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_detail_thumbnail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	thumb_clip.add_child(_detail_thumbnail)

	_detail_description_label = make_label("", 12, Color("#2f2114"))
	_detail_description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_detail_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_description_label.clip_text = true
	_add_detail_frame_child(panel, _detail_description_label, Rect2(44.0, 287.0, 432.0, 67.0))

	_detail_depth_value_label = _make_detail_row(panel, 0, "水深", 32.0)
	_apply_detail_frame_rect(_detail_row_panel(_detail_depth_value_label), Rect2(44.0, 366.0, 432.0, 46.0))
	_detail_fish_value_label = _make_detail_row(panel, 1, "狙い", 58.0, true, 14)
	_apply_detail_frame_rect(_detail_row_panel(_detail_fish_value_label), Rect2(44.0, 415.0, 432.0, 96.0))
	_detail_bait_value_label = _make_detail_row(panel, 2, "エサ", 32.0)
	_apply_detail_frame_rect(_detail_row_panel(_detail_bait_value_label), Rect2(44.0, 514.0, 432.0, 46.0))

	_make_rig_control_row(panel)
	_apply_detail_frame_rect(_detail_row_panel(_detail_rig_value_label), Rect2(44.0, 563.0, 432.0, 44.0))

	_action_button = make_button("ここで釣る", func() -> void: _select_spot(_selected_spot_id), 0, true)
	_apply_button_style(_action_button, _detail_primary_button_style(false), _detail_primary_button_style(true), _detail_primary_button_pressed_style())
	_action_button.add_theme_font_size_override("font_size", 21)
	_add_detail_frame_child(panel, _action_button, Rect2(38.0, 613.0, 444.0, 56.0))

	var back := make_return_button(func() -> void: navigate("harbor"), 0.0)
	back.add_theme_font_size_override("font_size", 20)
	_add_detail_frame_child(panel, back, Rect2(38.0, 675.0, 444.0, 77.0))


func _add_detail_frame_child(parent: Control, child: Control, frame_rect: Rect2) -> void:
	parent.add_child(child)
	_apply_detail_frame_rect(child, frame_rect)


func _apply_detail_frame_rect(control: Control, frame_rect: Rect2) -> void:
	var end := frame_rect.position + frame_rect.size
	control.anchor_left = frame_rect.position.x / DETAIL_FRAME_SOURCE_SIZE.x
	control.anchor_top = frame_rect.position.y / DETAIL_FRAME_SOURCE_SIZE.y
	control.anchor_right = end.x / DETAIL_FRAME_SOURCE_SIZE.x
	control.anchor_bottom = end.y / DETAIL_FRAME_SOURCE_SIZE.y
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0


func _detail_row_panel(value_label: Label) -> Control:
	return value_label.get_parent().get_parent() as Control


func _apply_button_style(button: Button, normal: StyleBox, hover: StyleBox, pressed: StyleBox) -> void:
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("pressed", pressed)


func _detail_primary_button_style(hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#073a5b", 0.98) if not hovered else Color("#0b4a70", 1.0)
	style.border_color = Palette.GOLD_BRIGHT
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0.0, 2.0)
	return style


func _detail_primary_button_pressed_style() -> StyleBoxFlat:
	var style := _detail_primary_button_style(false)
	style.bg_color = Color("#052d49", 1.0)
	style.shadow_size = 1
	style.shadow_offset = Vector2(0.0, 1.0)
	return style


func _detail_secondary_button_style(hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#d9bf83", 0.98) if not hovered else Color("#ead49a", 1.0)
	style.border_color = Color("#8b5a25", 0.94)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.22)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0.0, 2.0)
	return style


func _detail_secondary_button_pressed_style() -> StyleBoxFlat:
	var style := _detail_secondary_button_style(false)
	style.bg_color = Color("#b98749", 0.98)
	style.shadow_size = 1
	style.shadow_offset = Vector2(0.0, 1.0)
	return style


func _make_detail_row(
	parent: Control,
	icon_index: int,
	title: String,
	row_height: float = 36.0,
	multiline_value: bool = false,
	value_font_size: int = 17
) -> Label:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0.0, row_height)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _detail_row_style())
	parent.add_child(panel)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(26.0, 26.0)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _detail_icon(icon_index)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	var title_label := make_label(title, 16, Color("#6e4a24"))
	title_label.custom_minimum_size = Vector2(46.0, 0.0)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(title_label)

	var value_label := make_label("", value_font_size, Color("#1b1008"))
	value_label.custom_minimum_size = Vector2(0.0, 40.0 if multiline_value else 0.0)
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP if multiline_value else VERTICAL_ALIGNMENT_CENTER
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if multiline_value else TextServer.AUTOWRAP_OFF
	value_label.clip_text = true
	value_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING if multiline_value else TextServer.OVERRUN_TRIM_ELLIPSIS
	if multiline_value:
		value_label.max_lines_visible = 2
	value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(value_label)
	return value_label


func _make_rig_control_row(parent: Control) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0.0, 40.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _detail_row_style())
	parent.add_child(panel)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	var title_label := make_label("仕掛け", 16, Color("#6e4a24"))
	title_label.custom_minimum_size = Vector2(60.0, 0.0)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(title_label)

	_detail_rig_value_label = make_label("", 15, Color("#1b1008"))
	_detail_rig_value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_rig_value_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_rig_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_detail_rig_value_label.clip_text = true
	_detail_rig_value_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_detail_rig_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_detail_rig_value_label)

	_rig_cycle_button = Button.new()
	_rig_cycle_button.text = "切替"
	_rig_cycle_button.custom_minimum_size = Vector2(82.0, 0.0)
	_rig_cycle_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_rig_cycle_button.pressed.connect(_cycle_owned_rig)
	_apply_button_style(_rig_cycle_button, _detail_secondary_button_style(false), _detail_secondary_button_style(true), _detail_secondary_button_pressed_style())
	_rig_cycle_button.add_theme_font_size_override("font_size", 14)
	row.add_child(_rig_cycle_button)


func _detail_row_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#ead8ad", 0.72)
	style.border_color = Color("#876036", 0.18)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


func _build_footer(parent: Control) -> void:
	var panel := Control.new()
	panel.custom_minimum_size = Vector2(0.0, 104.0)
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

	var notebook := _make_footer_button("釣り手帳", _footer_icon(0), _show_notebook_hint, true)
	notebook.position = Vector2(22.0, 20.0)
	notebook.size = Vector2(220.0, 64.0)
	panel.add_child(notebook)

	var progress_panel := PanelContainer.new()
	progress_panel.position = Vector2(260.0, 22.0)
	progress_panel.size = Vector2(290.0, 60.0)
	progress_panel.add_theme_stylebox_override("panel", _footer_info_panel_style())
	panel.add_child(progress_panel)

	var progress_title := make_label("達成度", 15, Color("#f3dca5"), 1, Palette.TEXT_OUTLINE_DARK)
	progress_title.position = Vector2(282.0, 30.0)
	progress_title.size = Vector2(82.0, 20.0)
	progress_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(progress_title)

	_footer_completion_value_label = make_label("", 21, Palette.TEXT_BONE, 2, Palette.TEXT_OUTLINE_DARK)
	_footer_completion_value_label.position = Vector2(392.0, 27.0)
	_footer_completion_value_label.size = Vector2(86.0, 26.0)
	_footer_completion_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_footer_completion_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(_footer_completion_value_label)

	_footer_completion_back = ColorRect.new()
	_footer_completion_back.color = Color("#1a2020", 0.92)
	_footer_completion_back.position = Vector2(282.0, 60.0)
	_footer_completion_back.size = Vector2(180.0, 9.0)
	_footer_completion_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_footer_completion_back)

	_footer_completion_fill = ColorRect.new()
	_footer_completion_fill.color = Palette.GOLD_BRIGHT
	_footer_completion_fill.position = _footer_completion_back.position
	_footer_completion_fill.size = Vector2(0.0, 9.0)
	_footer_completion_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_footer_completion_fill)

	var chest := TextureRect.new()
	chest.texture = _footer_icon(1)
	chest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chest.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	chest.position = Vector2(488.0, 33.0)
	chest.size = Vector2(42.0, 42.0)
	chest.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(chest)

	var hint_panel := PanelContainer.new()
	hint_panel.position = Vector2(570.0, 22.0)
	hint_panel.size = Vector2(500.0, 60.0)
	hint_panel.add_theme_stylebox_override("panel", _footer_info_panel_style())
	panel.add_child(hint_panel)

	var hint_icon := TextureRect.new()
	hint_icon.texture = _footer_icon(2)
	hint_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hint_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hint_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	hint_icon.position = Vector2(590.0, 34.0)
	hint_icon.size = Vector2(30.0, 30.0)
	hint_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(hint_icon)

	_message_label = make_label("", 15, Color("#f8e3ae"), 1, Palette.TEXT_OUTLINE_DARK)
	_message_label.position = Vector2(628.0, 28.0)
	_message_label.size = Vector2(420.0, 24.0)
	_message_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_message_label.clip_text = true
	_message_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(_message_label)

	_message_detail_label = make_label("", 15, Color("#f8e3ae"), 1, Palette.TEXT_OUTLINE_DARK)
	_message_detail_label.position = Vector2(628.0, 52.0)
	_message_detail_label.size = Vector2(420.0, 24.0)
	_message_detail_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_message_detail_label.clip_text = true
	_message_detail_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_message_detail_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(_message_detail_label)

	var menu := _make_footer_button("メニュー", _footer_icon(3), _show_menu_hint, false)
	menu.position = Vector2(1104.0, 20.0)
	menu.size = Vector2(138.0, 64.0)
	panel.add_child(menu)


func _make_footer_button(text: String, icon: Texture2D, callback: Callable, primary: bool) -> Button:
	var button := Button.new()
	button.text = ""
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_color_override("font_color", Palette.TEXT_BONE if primary else Color("#2c1b0f"))
	button.add_theme_color_override("font_hover_color", Palette.TEXT_BONE if primary else Color("#241308"))
	button.add_theme_color_override("font_pressed_color", Palette.TEXT_BONE if primary else Color("#241308"))
	_apply_button_style(button, _footer_button_style(primary, false), _footer_button_style(primary, true), _footer_button_pressed_style(primary))
	button.pressed.connect(callback)

	var icon_rect := TextureRect.new()
	icon_rect.texture = icon
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if primary:
		icon_rect.position = Vector2(20.0, 12.0)
		icon_rect.size = Vector2(42.0, 42.0)
	else:
		icon_rect.position = Vector2(11.0, 17.0)
		icon_rect.size = Vector2(30.0, 30.0)
	button.add_child(icon_rect)

	var label_color := Palette.TEXT_BONE
	var label_outline := Palette.TEXT_OUTLINE_DARK
	var label := make_label(text, 22 if primary else 18, label_color, 2, label_outline)
	label.position = Vector2(76.0, 0.0) if primary else Vector2(42.0, 0.0)
	label.size = Vector2(130.0, 64.0) if primary else Vector2(92.0, 64.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(label)
	return button


func _footer_button_style(primary: bool, hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if primary:
		style.bg_color = Color("#073957", 0.98) if not hovered else Color("#0a4a70", 1.0)
		style.border_color = Palette.GOLD_BRIGHT
	else:
		style.bg_color = Color("#282a27", 0.98) if not hovered else Color("#373a35", 1.0)
		style.border_color = Color("#d0a65a", 0.96)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 16
	style.content_margin_right = 14
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.26)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0.0, 2.0)
	return style


func _footer_button_pressed_style(primary: bool) -> StyleBoxFlat:
	var style := _footer_button_style(primary, false)
	style.bg_color = Color("#052b43", 0.98) if primary else Color("#1e201e", 0.98)
	style.shadow_size = 1
	style.shadow_offset = Vector2(0.0, 1.0)
	return style


func _footer_info_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#062d46", 0.96)
	style.border_color = Color("#d6aa5a", 0.76)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _show_notebook_hint() -> void:
	if _message_label == null:
		return
	_message_label.text = "釣り手帳"
	if _message_detail_label != null:
		_message_detail_label.text = "釣った魚の記録と達成度を確認します。"


func _show_menu_hint() -> void:
	if _message_label == null:
		return
	_message_label.text = "メニュー"
	if _message_detail_label != null:
		_message_detail_label.text = "設定や手帳を開く準備中です。"


func _memo_line_style(primary: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#073753", 0.96) if primary else Color("#062f49", 0.92)
	style.border_color = Color("#d0a65a", 0.45 if primary else 0.24)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 9
	style.content_margin_right = 9
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	return style


func _memo_frame_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#e7d4aa", 0.66)
	style.border_color = Color("#d0a65a", 0.50)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


func _make_ledger_header_chip(parent: Control, width: float, strong: bool) -> Label:
	var chip := PanelContainer.new()
	chip.custom_minimum_size = Vector2(width, 0.0)
	chip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	chip.add_theme_stylebox_override("panel", _ledger_header_chip_style(strong))
	parent.add_child(chip)

	var label := make_label("", 11, Palette.GOLD_BRIGHT if strong else Color("#e4d1a2"), 1, Palette.TEXT_OUTLINE_DARK)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	chip.add_child(label)
	return label


func _ledger_header_chip_style(strong: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0b405f", 0.96) if strong else Color("#133f50", 0.72)
	style.border_color = Color("#efca6e", 0.72) if strong else Color("#c99d54", 0.36)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	return style


func _ledger_header_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#073957", 0.94)
	style.border_color = Color("#d0a65a", 0.52)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style


func _ledger_body_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#e7d4aa", 0.78)
	style.border_color = Color("#d0a65a", 0.42)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


func _memo_header_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#073957", 0.94)
	style.border_color = Color("#d0a65a", 0.48)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style


func _rebuild_completion_entries() -> void:
	return


func _make_completion_entry(spot: Dictionary) -> Control:
	var spot_id := String(spot.get("id", GameData.DEFAULT_FISHING_SPOT_ID))
	var unlocked := GameData.is_fishing_spot_unlocked(spot_id, PlayerProgress.level)
	var selected := spot_id == _selected_spot_id
	var completion := _spot_completion_counts(spot)
	var entry := Control.new()
	entry.clip_contents = true
	entry.custom_minimum_size = COMPLETION_SLOT_SIZE
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.mouse_filter = Control.MOUSE_FILTER_IGNORE
	entry.set_meta("spot_progress_entry", true)
	entry.set_meta("spot_id", spot_id)
	entry.set_meta("locked", not unlocked)
	entry.set_meta("caught_species", int(completion.get("caught", 0)))
	entry.set_meta("target_species", int(completion.get("total", 0)))

	_add_completion_slot_fallback(entry, unlocked, selected)

	var title_color := Color("#1d140b") if unlocked else Color("#5c554a")
	var title := _card_label(String(spot.get("short_name", spot.get("name", spot_id))), 12, title_color, 0)
	title.position = Vector2(12.0, 4.0)
	title.size = Vector2(112.0, 15.0)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	entry.add_child(title)

	var badge_color := Color("#7b4c15") if unlocked else Color("#6b5740")
	if selected and unlocked:
		badge_color = Color("#4f3518")
	var badge := _card_label(_completion_badge_text(spot, unlocked, completion), 11, badge_color, 0)
	badge.position = Vector2(158.0, 4.0)
	badge.size = Vector2(48.0, 15.0)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	entry.add_child(badge)

	var body_color := Color("#23170d") if unlocked else Color("#4f4941")
	var summary_text := _completion_summary_text(spot, unlocked, completion)
	var summary := _card_label(summary_text, 11, body_color)
	summary.position = Vector2(12.0, 24.0)
	summary.size = Vector2(88.0, 15.0)
	summary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	entry.add_child(summary)

	_add_completion_bar(entry, unlocked, selected, float(completion.get("ratio", 0.0)))
	return entry


func _add_completion_slot_fallback(parent: Control, unlocked: bool, selected: bool) -> void:
	var frame := PanelContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", _completion_entry_style(unlocked, selected))
	parent.add_child(frame)

	var body := ColorRect.new()
	body.color = Color("#f5e5bc", 0.16) if unlocked else Color("#5d605a", 0.16)
	if selected and unlocked:
		body.color = Color("#ffe070", 0.11)
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(body)

	var top_rule := ColorRect.new()
	top_rule.color = Color("#073957", 0.58) if unlocked else Color("#4b514f", 0.42)
	if selected and unlocked:
		top_rule.color = Palette.GOLD_BRIGHT
	top_rule.anchor_left = 0.0
	top_rule.anchor_top = 0.0
	top_rule.anchor_right = 1.0
	top_rule.anchor_bottom = 0.0
	top_rule.offset_left = 8.0
	top_rule.offset_top = 2.0
	top_rule.offset_right = -8.0
	top_rule.offset_bottom = 4.0
	top_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(top_rule)

	var rule := ColorRect.new()
	rule.color = Color("#7d5831", 0.35)
	rule.anchor_left = 0.0
	rule.anchor_top = 1.0
	rule.anchor_right = 1.0
	rule.anchor_bottom = 1.0
	rule.offset_left = 7.0
	rule.offset_right = -7.0
	rule.offset_top = -2.0
	rule.offset_bottom = -1.0
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(rule)

	if selected and unlocked:
		var accent := ColorRect.new()
		accent.color = Palette.GOLD_BRIGHT
		accent.anchor_left = 0.0
		accent.anchor_top = 0.0
		accent.anchor_right = 0.0
		accent.anchor_bottom = 1.0
		accent.offset_left = 2.0
		accent.offset_right = 5.0
		accent.offset_top = 3.0
		accent.offset_bottom = -3.0
		accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(accent)


func _completion_entry_style(unlocked: bool, selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#ead5a7", 0.04) if unlocked else Color("#4f514d", 0.08)
	style.border_color = Color("#6d4b28", 0.24) if unlocked else Color("#4d463d", 0.20)
	if selected and unlocked:
		style.bg_color = Color("#f3cf66", 0.10)
		style.border_color = Color("#f4cf72", 0.86)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


func _add_completion_marks(parent: Control, unlocked: bool, caught: int, total: int) -> void:
	var marks := mini(total, 5)
	if marks <= 0:
		return
	var start_x := 14.0
	var y := 60.0
	for index in range(marks):
		var mark := ColorRect.new()
		mark.position = Vector2(start_x + float(index) * 8.0, y)
		mark.size = Vector2(5.0, 5.0)
		var filled := unlocked and index < caught
		mark.color = Color("#d89132") if filled else Color("#82796b", 0.55)
		if not unlocked:
			mark.color = Color("#6f6a61", 0.50)
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(mark)


func _add_completion_bar(parent: Control, unlocked: bool, selected: bool, ratio: float) -> void:
	var back := ColorRect.new()
	back.color = Color("#5c5143", 0.52) if unlocked else Color("#736d63", 0.44)
	back.position = Vector2(104.0, 31.0)
	back.size = Vector2(100.0, 5.0)
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
	_refresh_ledger_header()
	_play_map_bgm_for_spot(spot_id)
	if update_message or (_message_label != null and _message_label.text.is_empty()):
		var spot := GameData.get_fishing_spot(spot_id)
		if PlayerProgress.can_access_fishing_spot(spot_id):
			_set_survey_message(spot)
		else:
			_show_locked_message(spot_id)


func _play_map_bgm_for_spot(spot_id: String) -> void:
	var path := String(MAP_BGM_PATH_BY_SPOT.get(spot_id, MAP_BGM_PATH_BY_SPOT[GameData.DEFAULT_FISHING_SPOT_ID]))
	play_screen_bgm(path, MAP_BGM_VOLUME_DB)


func _refresh_ledger_header() -> void:
	var total := _ledger_completion_counts()
	var caught := int(total.get("caught", 0))
	var target := int(total.get("total", 0))
	if _footer_completion_value_label != null:
		_footer_completion_value_label.text = "%d / %d" % [caught, target]
	if _footer_completion_fill != null and _footer_completion_back != null:
		var ratio := 0.0 if target <= 0 else float(caught) / float(target)
		_footer_completion_fill.size = Vector2(_footer_completion_back.size.x * clampf(ratio, 0.0, 1.0), _footer_completion_back.size.y)


func _ledger_completion_counts() -> Dictionary:
	var caught := 0
	var total := 0
	for spot_id in GameData.get_all_fishing_spot_ids():
		if not PlayerProgress.can_access_fishing_spot(spot_id):
			continue
		var completion := _spot_completion_counts(GameData.get_fishing_spot(spot_id))
		caught += int(completion.get("caught", 0))
		total += int(completion.get("total", 0))
	return {
		"caught": caught,
		"total": total,
	}


func _refresh_detail() -> void:
	var spot := GameData.get_fishing_spot(_selected_spot_id)
	if spot.is_empty():
		return
	var access := PlayerProgress.fishing_spot_access_status(_selected_spot_id)
	var accessible := bool(access.get("ok", false))
	var boss_spot := bool(spot.get("boss_spot", false))
	_detail_title_label.text = String(spot.get("name", _selected_spot_id))
	_detail_title_label.add_theme_font_size_override("font_size", 22 if _detail_title_label.text.length() >= 9 else 24)
	if accessible:
		_detail_unlock_label.text = "解放済み　%s" % ("ぬし専用" if boss_spot else "通常ポイント")
		_detail_unlock_label.add_theme_color_override("font_color", Color("#f2cf7d") if not boss_spot else Color("#ffb58d"))
	else:
		_detail_unlock_label.text = String(access.get("message", "出航不可"))
		_detail_unlock_label.add_theme_color_override("font_color", Color("#ffb0a0"))
	if _detail_thumbnail != null:
		_detail_thumbnail.texture = _thumbnail_for_spot(_selected_spot_id)
	_detail_description_label.text = String(spot.get("description", ""))
	_detail_depth_value_label.text = _depth_range_text(spot)
	_detail_fish_value_label.text = _featured_fish_text(spot, 4, 2)
	_detail_bait_value_label.text = _bait_text_with_match(spot)
	if _detail_rig_value_label != null:
		_detail_rig_value_label.text = _equipped_rig_text()
	if _rig_cycle_button != null:
		var owned_rig_ids := _valid_owned_rig_ids()
		_rig_cycle_button.disabled = owned_rig_ids.size() <= 1
		_rig_cycle_button.text = "切替" if owned_rig_ids.size() > 1 else "所持1"
	if _detail_hint_value_label != null:
		_detail_hint_value_label.text = (
			String(access.get("detail", ""))
			if not accessible
			else (_boss_hint_text() if boss_spot else _rare_hint_text(spot))
		)
	if _action_button != null:
		_action_button.disabled = not accessible
		_action_button.text = String(access.get("button_text", "ここで釣る"))


func _select_spot(spot_id: String) -> void:
	if not PlayerProgress.can_access_fishing_spot(spot_id):
		_show_locked_message(spot_id)
		return
	var payload := {"spot_id": spot_id}
	if _continue_trip:
		payload["continue_trip"] = true
		var stats := _trip_stats.duplicate(true)
		_apply_current_rig_to_stats(stats)
		payload["trip_stats"] = stats
	navigate("fishing", payload)


func _show_locked_message(spot_id: String) -> void:
	if _message_label == null:
		return
	var spot := GameData.get_fishing_spot(spot_id)
	_message_label.text = String(spot.get("name", spot_id))
	if _message_detail_label != null:
		var access := PlayerProgress.fishing_spot_access_status(spot_id)
		_message_detail_label.text = String(access.get("message", "出航不可"))


func _set_survey_message(spot: Dictionary) -> void:
	if _message_label == null:
		return
	var completion := _spot_completion_counts(spot)
	var spot_id := String(spot.get("id", GameData.DEFAULT_FISHING_SPOT_ID))
	_message_label.text = "%s　達成度 %d/%d種" % [
		String(spot.get("short_name", spot.get("name", spot_id))),
		int(completion.get("caught", 0)),
		int(completion.get("total", 0)),
	]
	if _message_detail_label != null:
		_message_detail_label.text = _survey_missing_text(spot)


func _depth_range_text(spot: Dictionary) -> String:
	var range: Array = spot.get("depth_range", [0.0, 0.0])
	if range.size() < 2:
		return "--.-m"
	return "%.1f〜%.1fm" % [float(range[0]), float(range[1])]


func _featured_fish_text(spot: Dictionary, limit: int = 5, names_per_line: int = 0) -> String:
	var names: Array[String] = []
	for fish_id_variant in Array(spot.get("featured_fish", [])):
		var fish := GameData.get_fish(String(fish_id_variant))
		if fish.is_empty():
			continue
		names.append(String(fish.get("name", fish_id_variant)))
		if names.size() >= limit:
			break
	if names_per_line <= 0 or names.size() <= names_per_line:
		return "、".join(PackedStringArray(names))
	var lines: Array[String] = []
	var line: Array[String] = []
	for index in range(names.size()):
		line.append(names[index])
		if line.size() >= names_per_line or index == names.size() - 1:
			lines.append("、".join(PackedStringArray(line)))
			line.clear()
	return "\n".join(PackedStringArray(lines))


func _bait_text(spot: Dictionary) -> String:
	var baits: Array[String] = []
	for bait_variant in Array(spot.get("recommended_baits", [])):
		baits.append(String(bait_variant))
	return "、".join(PackedStringArray(baits))


func _bait_text_with_match(spot: Dictionary) -> String:
	var base := _bait_text(spot)
	var match_text := "◎おすすめ一致" if _rig_matches_spot(spot) else "相性ふつう"
	if base.strip_edges().is_empty():
		return match_text
	return "%s　%s" % [base, match_text]


func _equipped_rig_text() -> String:
	var rig := GameData.get_rig(PlayerProgress.equipped_rig_id)
	if rig.is_empty():
		return "サビキ仕掛け"
	var bait_types: Array[String] = []
	for bait_variant in Array(rig.get("bait_types", [])):
		bait_types.append(String(bait_variant))
	return "%s / %s" % [String(rig.get("name", "サビキ仕掛け")), "、".join(PackedStringArray(bait_types))]


func _cycle_owned_rig() -> void:
	var owned_rig_ids := _valid_owned_rig_ids()
	if owned_rig_ids.size() <= 1:
		return
	var current_index := owned_rig_ids.find(PlayerProgress.equipped_rig_id)
	var next_index := 0 if current_index < 0 else (current_index + 1) % owned_rig_ids.size()
	var result := PlayerProgress.buy_or_equip_rig(owned_rig_ids[next_index])
	if _message_label != null:
		_message_label.text = "仕掛けを変更"
	if _message_detail_label != null:
		_message_detail_label.text = String(result.get("message", "仕掛けを切り替えました。"))
	_refresh_detail()


func _valid_owned_rig_ids() -> Array[String]:
	var ids: Array[String] = []
	for rig_id_variant in PlayerProgress.owned_rigs:
		var rig_id := String(rig_id_variant)
		if GameData.get_rig(rig_id).is_empty() or rig_id in ids:
			continue
		ids.append(rig_id)
	if ids.is_empty():
		ids.append(GameData.DEFAULT_RIG_ID)
	return ids


func _rig_matches_spot(spot: Dictionary) -> bool:
	for bait_variant in Array(spot.get("recommended_baits", [])):
		if GameData.rig_supports_bait(PlayerProgress.equipped_rig_id, String(bait_variant)):
			return true
	return false


func _apply_current_rig_to_stats(stats: Dictionary) -> void:
	var rig := GameData.get_rig(PlayerProgress.equipped_rig_id)
	if rig.is_empty():
		rig = GameData.get_rig(GameData.DEFAULT_RIG_ID)
		stats["rig_id"] = GameData.DEFAULT_RIG_ID
	else:
		stats["rig_id"] = PlayerProgress.equipped_rig_id
	stats["rig_name"] = String(rig.get("name", "サビキ仕掛け"))
	stats["rig_bait_types"] = GameData.rig_bait_types(String(stats["rig_id"]))


func _boss_hint_text() -> String:
	if int(PlayerProgress.caught_counts.get("boss_kurodai", 0)) > 0:
		return "討伐済み・再挑戦可"
	return "ぬしの気配"


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
		return "Lv.%d" % int(spot.get("unlock_level", 1))
	if bool(spot.get("boss_spot", false)):
		return "%d/%d" % [int(completion.get("caught", 0)), int(completion.get("total", 0))]
	return "%d%%" % int(round(float(completion.get("ratio", 0.0)) * 100.0))


func _completion_summary_text(spot: Dictionary, unlocked: bool, completion: Dictionary) -> String:
	if not unlocked:
		return "未解放"
	return "記録 %d/%d 種" % [
		int(completion.get("caught", 0)),
		int(completion.get("total", 0)),
	]


func _survey_message_text(spot: Dictionary) -> String:
	var completion := _spot_completion_counts(spot)
	var spot_id := String(spot.get("id", GameData.DEFAULT_FISHING_SPOT_ID))
	return "%s\n達成度 %d/%d 種　%s" % [
		String(spot.get("name", spot_id)),
		int(completion.get("caught", 0)),
		int(completion.get("total", 0)),
		_survey_missing_text(spot),
	]


func _survey_missing_text(spot: Dictionary) -> String:
	var spot_id := String(spot.get("id", GameData.DEFAULT_FISHING_SPOT_ID))
	var missing: Array[String] = []
	var spot_counts: Dictionary = {}
	var loaded_spot_counts = PlayerProgress.spot_caught_counts.get(spot_id, {})
	if typeof(loaded_spot_counts) == TYPE_DICTIONARY:
		spot_counts = loaded_spot_counts
	for fish_id_variant in Array(spot.get("featured_fish", [])):
		var fish_id := String(fish_id_variant)
		if int(spot_counts.get(fish_id, 0)) > 0:
			continue
		var fish := GameData.get_fish(fish_id)
		missing.append(String(fish.get("name", fish_id)) if not fish.is_empty() else fish_id)
		if missing.size() >= 3:
			break
	if missing.is_empty():
		return "未記録なし"
	return "未記録: %s" % "、".join(PackedStringArray(missing))


func _rare_hint_text(spot: Dictionary) -> String:
	var unlock_level := int(spot.get("unlock_level", 1))
	if unlock_level >= 6:
		return "大物の回遊あり"
	if unlock_level >= 4:
		return "レア魚の気配"
	return "安定した反応"


func _detail_icon(icon_index: int) -> Texture2D:
	return _atlas_icon(_detail_icon_sheet, DETAIL_ICON_SIZE, icon_index)


func _footer_icon(icon_index: int) -> Texture2D:
	return _atlas_icon(_footer_icon_sheet, FOOTER_ICON_SIZE, icon_index)


func _atlas_icon(sheet: Texture2D, cell_size: float, icon_index: int) -> Texture2D:
	if sheet == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(Vector2(cell_size * float(icon_index), 0.0), Vector2(cell_size, cell_size))
	return atlas


func _thumbnail_for_spot(spot_id: String) -> Texture2D:
	var path := "%s/%s.png" % [THUMB_BASE_PATH, spot_id]
	return _load_texture_if_exists(path)


func _load_texture_if_exists(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	var absolute_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(absolute_path):
		var image := Image.new()
		var err := image.load(absolute_path)
		if err == OK:
			return ImageTexture.create_from_image(image)
	return null
