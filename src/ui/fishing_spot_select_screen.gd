extends "res://src/ui/screen_base.gd"

const FishingSpotMapViewScript = preload("res://src/ui/components/fishing_spot_map_view.gd")

const DETAIL_FRAME_PATH := "res://assets/showcase/fishing_spots/map_detail_frame.png"
const FOOTER_FRAME_PATH := "res://assets/showcase/fishing_spots/map_footer_frame.png"
const CARD_FRAME_PATH := "res://assets/showcase/fishing_spots/map_spot_card_frame.png"
const CARD_FRAME_LOCKED_PATH := "res://assets/showcase/fishing_spots/map_spot_card_frame_locked.png"

var _selected_spot_id: String = GameData.DEFAULT_FISHING_SPOT_ID
var _continue_trip := false
var _trip_stats: Dictionary = {}

var _map_view: FishingSpotMapView
var _message_label: Label
var _detail_title_label: Label
var _detail_unlock_label: Label
var _detail_description_label: Label
var _detail_info_label: Label
var _action_button: Button
var _cards_box: HBoxContainer

var _detail_frame: Texture2D
var _footer_frame: Texture2D
var _card_frame: Texture2D
var _card_frame_locked: Texture2D


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

	layout.add_child(make_header("釣り場を選ぶ", _header_subtitle()))

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
	_detail_frame = _load_texture_if_exists(DETAIL_FRAME_PATH)
	_footer_frame = _load_texture_if_exists(FOOTER_FRAME_PATH)
	_card_frame = _load_texture_if_exists(CARD_FRAME_PATH)
	_card_frame_locked = _load_texture_if_exists(CARD_FRAME_LOCKED_PATH)


func _header_subtitle() -> String:
	var trip_text := "　釣行継続中：ポイント変更" if _continue_trip else ""
	return "Lv.%d　%s　所持金 %d G%s" % [
		PlayerProgress.level,
		String(GameData.get_rod(PlayerProgress.equipped_rod_id).get("name", "入門竿")),
		PlayerProgress.money,
		trip_text,
	]


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
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 27)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 27)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	_detail_title_label = make_label("", 28, Palette.TEXT_BONE, 2, Palette.TEXT_OUTLINE_DARK)
	_detail_title_label.custom_minimum_size = Vector2(0.0, 70.0)
	_detail_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_detail_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_detail_title_label)

	_detail_unlock_label = make_label("", 16, Palette.GOLD_DEEP)
	_detail_unlock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_unlock_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_detail_unlock_label)

	_detail_description_label = make_label("", 16, Color("#2f2114"))
	_detail_description_label.custom_minimum_size = Vector2(0.0, 84.0)
	_detail_description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_detail_description_label)

	_detail_info_label = make_label("", 18, Color("#1d1209"))
	_detail_info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_info_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_info_label.add_theme_constant_override("line_spacing", 8)
	box.add_child(_detail_info_label)

	var button_box := VBoxContainer.new()
	button_box.size_flags_vertical = Control.SIZE_SHRINK_END
	button_box.add_theme_constant_override("separation", 10)
	box.add_child(button_box)

	_action_button = make_button("ここで釣る", func() -> void: _select_spot(_selected_spot_id), 0, true)
	_action_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_box.add_child(_action_button)

	var back := make_button("港へ戻る", func() -> void: navigate("harbor"), 0)
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_box.add_child(back)


func _build_footer(parent: Control) -> void:
	var panel := Control.new()
	panel.custom_minimum_size = Vector2(0.0, 142.0)
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
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 14)
	margin.add_child(row)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(scroll)

	_cards_box = HBoxContainer.new()
	_cards_box.add_theme_constant_override("separation", 10)
	scroll.add_child(_cards_box)

	var message_box := VBoxContainer.new()
	message_box.custom_minimum_size = Vector2(300.0, 0.0)
	message_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	message_box.add_theme_constant_override("separation", 6)
	row.add_child(message_box)

	var guide := make_label("航路メモ", 17, Palette.TEXT_BONE, 1, Palette.TEXT_OUTLINE_DARK)
	guide.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_box.add_child(guide)

	_message_label = make_label("", 15, Color("#eaf6ff"), 1, Palette.TEXT_OUTLINE_DARK)
	_message_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	message_box.add_child(_message_label)


func _rebuild_spot_cards() -> void:
	if _cards_box == null:
		return
	for child in _cards_box.get_children():
		child.queue_free()
	for spot_id in GameData.get_all_fishing_spot_ids():
		_cards_box.add_child(_make_spot_card(GameData.get_fishing_spot(spot_id)))


func _make_spot_card(spot: Dictionary) -> Button:
	var spot_id := String(spot.get("id", GameData.DEFAULT_FISHING_SPOT_ID))
	var unlocked := GameData.is_fishing_spot_unlocked(spot_id, PlayerProgress.level)
	var selected := spot_id == _selected_spot_id
	var button := Button.new()
	button.text = ""
	button.disabled = not unlocked
	button.clip_contents = true
	button.custom_minimum_size = Vector2(238.0, 104.0)
	button.set_meta("spot_card", true)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if unlocked else Control.CURSOR_ARROW
	_apply_card_button_style(button, selected, unlocked)
	if unlocked:
		button.pressed.connect(func() -> void: _focus_spot(spot_id))

	var frame := TextureRect.new()
	frame.texture = _card_frame if unlocked else _card_frame_locked
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(frame)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 13)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_right", 13)
	margin.add_theme_constant_override("margin_bottom", 8)
	button.add_child(margin)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)

	var title := make_label(String(spot.get("name", spot_id)), 15, Color("#fff2d2") if unlocked else Color("#d5cec1"), 1, Palette.TEXT_OUTLINE_DARK)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.clip_text = true
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(title)

	var body_color := Color("#23170d") if unlocked else Color("#4f4941")
	var depth := make_label("水深 %s" % _depth_range_text(spot), 13, body_color)
	depth.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(depth)

	var featured := make_label("狙い %s" % _featured_fish_text(spot, 3), 13, body_color)
	featured.mouse_filter = Control.MOUSE_FILTER_IGNORE
	featured.clip_text = true
	box.add_child(featured)

	var badge_text := "選択中" if selected else _unlock_badge_text(spot, unlocked)
	var badge := make_label(badge_text, 12, Palette.GOLD_DEEP if unlocked else Color("#6b5740"))
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(badge)
	return button


func _focus_spot(spot_id: String, update_message: bool = true) -> void:
	if GameData.get_fishing_spot(spot_id).is_empty():
		return
	_selected_spot_id = spot_id
	if _map_view != null:
		_map_view.set_selected_spot(spot_id)
	_refresh_detail()
	_rebuild_spot_cards()
	if update_message:
		var spot := GameData.get_fishing_spot(spot_id)
		if GameData.is_fishing_spot_unlocked(spot_id, PlayerProgress.level):
			_message_label.text = "%s を選択中。右の「ここで釣る」から出航できます。" % String(spot.get("name", spot_id))
		else:
			_show_locked_message(spot_id)


func _refresh_detail() -> void:
	var spot := GameData.get_fishing_spot(_selected_spot_id)
	if spot.is_empty():
		return
	var unlocked := GameData.is_fishing_spot_unlocked(_selected_spot_id, PlayerProgress.level)
	var boss_spot := bool(spot.get("boss_spot", false))
	_detail_title_label.text = String(spot.get("name", _selected_spot_id))
	if unlocked:
		_detail_unlock_label.text = "解放済み　%s" % ("ぬし専用" if boss_spot else "通常ポイント")
		_detail_unlock_label.add_theme_color_override("font_color", Color("#6e3f13") if not boss_spot else Color("#8c2d23"))
	else:
		_detail_unlock_label.text = "未解放　Lv.%dで出航可能" % int(spot.get("unlock_level", 1))
		_detail_unlock_label.add_theme_color_override("font_color", Color("#8c2d23"))
	_detail_description_label.text = String(spot.get("description", ""))
	_detail_info_label.text = "水深　%s\n狙い　%s\nエサ　%s\n気配　%s" % [
		_depth_range_text(spot),
		_featured_fish_text(spot, 5),
		_bait_text(spot),
		"ぬしの気配" if boss_spot else _rare_hint_text(spot),
	]
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


func _apply_card_button_style(button: Button, selected: bool, unlocked: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.border_color = Color("#ffe07a", 0.95) if selected else Color(0.0, 0.0, 0.0, 0.0)
	style.set_border_width_all(3 if selected else 0)
	style.set_corner_radius_all(8)
	var hover := style.duplicate() as StyleBoxFlat
	hover.border_color = Color("#fff0a4", 0.98) if unlocked else style.border_color
	hover.set_border_width_all(3 if unlocked or selected else 0)
	var disabled := style.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.0, 0.0, 0.0, 0.08)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("disabled", disabled)


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


func _unlock_badge_text(spot: Dictionary, unlocked: bool) -> String:
	if not unlocked:
		return "LOCK"
	if bool(spot.get("boss_spot", false)):
		return "ぬし"
	return "Lv.%d" % int(spot.get("unlock_level", 1))


func _rare_hint_text(spot: Dictionary) -> String:
	var unlock_level := int(spot.get("unlock_level", 1))
	if unlock_level >= 6:
		return "大物の回遊あり"
	if unlock_level >= 4:
		return "レア魚の気配"
	return "安定した反応"


func _load_texture_if_exists(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null
