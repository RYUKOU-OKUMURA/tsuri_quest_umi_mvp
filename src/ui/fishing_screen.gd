extends ScreenBase

const FishingSimulatorScript = preload("res://src/core/fishing_simulator.gd")
const SurfaceCastViewScript = preload("res://src/ui/components/surface_cast_view.gd")
const FightSidebarScript = preload("res://src/ui/components/fight_sidebar.gd")
const FightHudScript = preload("res://src/ui/components/fight_hud.gd")
const FightStatusBarScript = preload("res://src/ui/components/fight_status_bar.gd")

var _simulator: FishingSimulator
var _trip_stats: Dictionary = {}
var _current_fish: Dictionary = {}
var _result_recorded: bool = false
var _spot_id: String = GameData.DEFAULT_FISHING_SPOT_ID
var _spot: Dictionary = {}

var _info_title_label: Label
var _spot_panel: PanelContainer
var _spot_summary_label: Label
var _spot_detail_label: Label
var _message_panel: PanelContainer
var _message_label: Label
var _state_label: Label
var _action_label: Label
var _fish_info_label: Label
var _distance_label: Label
var _depth_label: Label
var _safe_zone_label: Label
var _view: UnderwaterView
var _surface_view: SurfaceCastView
var _fight_sidebar: FightSidebar
var _fight_hud: FightHud
var _fight_status_bar: FightStatusBar

var _result_overlay: ColorRect
var _result_title: Label
var _result_details: Label
var _retry_button: Button
var _quit_overlay: ColorRect
var _quit_title: Label
var _quit_details: Label
var _quit_confirm_button: Button
var _quit_target := "harbor"


func _build_screen() -> void:
	add_gradient_background(Color("#0c243a"), Color("#04101e"))
	_resolve_selected_spot()
	_resolve_trip_stats()
	_apply_spot_to_trip_stats()
	_simulator = FishingSimulatorScript.new()
	_simulator.state_changed.connect(_on_state_changed)
	_simulator.message_changed.connect(_on_message_changed)
	_simulator.fight_finished.connect(_on_fight_finished)

	var root := make_root_margin(6)
	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 2)
	root.add_child(layout)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 5)
	layout.add_child(body)

	var left_column := VBoxContainer.new()
	left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_column.size_flags_stretch_ratio = 1.52
	left_column.add_theme_constant_override("separation", 2)
	body.add_child(left_column)

	_fight_status_bar = FightStatusBarScript.new()
	_fight_status_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fight_status_bar.bind(_simulator, _trip_stats)
	left_column.add_child(_fight_status_bar)

	var water_panel := make_panel(true)
	water_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	water_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	water_panel.clip_contents = true
	left_column.add_child(water_panel)
	_view = UnderwaterView.new()
	_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	water_panel.add_child(_view)
	# 水上キャストビューを手前に重ねる（READY〜BITE 表示、FIGHT 以降は淡出）
	_surface_view = SurfaceCastViewScript.new()
	_surface_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_surface_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	water_panel.add_child(_surface_view)

	var message_layer := Control.new()
	message_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	message_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	water_panel.add_child(message_layer)
	_message_panel = make_panel(true)
	_message_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_message_panel.visible = false
	_message_panel.anchor_left = 0.18
	_message_panel.anchor_top = 1.0
	_message_panel.anchor_right = 0.82
	_message_panel.anchor_bottom = 1.0
	_message_panel.offset_left = 0.0
	_message_panel.offset_top = -54.0
	_message_panel.offset_right = 0.0
	_message_panel.offset_bottom = -12.0
	message_layer.add_child(_message_panel)
	_message_label = make_body_label("", 18, Color("#fff0b5"), 2, Color("#0a1622"))
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message_panel.add_child(_message_label)

	_fight_hud = FightHudScript.new()
	_fight_hud.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fight_hud.custom_minimum_size = Vector2(0.0, 224.0)
	_fight_hud.main_action_pressed.connect(_on_main_action_pressed)
	_fight_hud.reel_changed.connect(func(active: bool) -> void: _simulator.set_reeling(active))
	_fight_hud.give_line_changed.connect(func(active: bool) -> void: _simulator.set_giving_line(active))
	_fight_hud.harbor_pressed.connect(_request_harbor_return)
	_fight_hud.change_spot_pressed.connect(_request_spot_change)
	left_column.add_child(_fight_hud)

	var info_panel := MarginContainer.new()
	info_panel.custom_minimum_size = Vector2(326, 0)
	info_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_panel.size_flags_stretch_ratio = 0.0
	info_panel.clip_contents = true
	info_panel.add_theme_constant_override("margin_left", 0)
	info_panel.add_theme_constant_override("margin_top", 0)
	info_panel.add_theme_constant_override("margin_right", 0)
	info_panel.add_theme_constant_override("margin_bottom", 0)
	body.add_child(info_panel)
	var info_box := VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_box.add_theme_constant_override("separation", 6)
	info_panel.add_child(info_box)
	_info_title_label = make_label("釣り場", 24, Color("#22354a"))
	_info_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_box.add_child(_info_title_label)

	_spot_panel = make_panel()
	_spot_panel.custom_minimum_size = Vector2(0, 96)
	info_box.add_child(_spot_panel)
	var spot_box := VBoxContainer.new()
	spot_box.add_theme_constant_override("separation", 3)
	_spot_panel.add_child(spot_box)
	_spot_summary_label = make_label(_spot_summary_text(), 17, Palette.TEXT_DARK)
	_spot_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_spot_summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spot_box.add_child(_spot_summary_label)
	_spot_detail_label = make_label(_spot_detail_text(), 13, Palette.TEXT_BODY)
	_spot_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_spot_detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spot_box.add_child(_spot_detail_label)

	_fight_sidebar = FightSidebarScript.new()
	_fight_sidebar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fight_sidebar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_box.add_child(_fight_sidebar)

	_create_result_overlay()
	_create_quit_overlay()
	_prepare_new_attempt()
	_update_ui()


func _resolve_selected_spot() -> void:
	var requested_id := String(route_payload.get("spot_id", GameData.DEFAULT_FISHING_SPOT_ID))
	if (
		not bool(route_payload.get("continue_trip", false))
		and not GameData.is_fishing_spot_unlocked(requested_id, PlayerProgress.level)
	):
		requested_id = GameData.DEFAULT_FISHING_SPOT_ID
	_spot = GameData.get_fishing_spot(requested_id)
	if _spot.is_empty():
		_spot = GameData.get_fishing_spot(GameData.DEFAULT_FISHING_SPOT_ID)
	_spot_id = String(_spot.get("id", GameData.DEFAULT_FISHING_SPOT_ID))


func _resolve_trip_stats() -> void:
	var incoming_stats = route_payload.get("trip_stats", {})
	if bool(route_payload.get("continue_trip", false)) and typeof(incoming_stats) == TYPE_DICTIONARY:
		var stats_dict: Dictionary = incoming_stats
		if not stats_dict.is_empty():
			_trip_stats = stats_dict.duplicate(true)
			return
	_trip_stats = PlayerProgress.begin_fishing_trip()


func _apply_spot_to_trip_stats() -> void:
	_trip_stats["spot_id"] = _spot_id
	_trip_stats["spot_name"] = String(_spot.get("name", "港内・堤防"))
	_trip_stats["spot_short_name"] = String(_spot.get("short_name", _trip_stats["spot_name"]))
	_trip_stats["spot_depth_range"] = _spot.get("depth_range", [0.0, 0.0])
	_trip_stats["spot_featured_fish"] = _spot.get("featured_fish", [])
	_trip_stats["spot_recommended_baits"] = _spot.get("recommended_baits", [])
	_trip_stats["spot_boss"] = bool(_spot.get("boss_spot", false))


func _spot_summary_text() -> String:
	var name := String(_spot.get("name", "港内・堤防"))
	var role := "ぬし専用" if bool(_spot.get("boss_spot", false)) else "通常ポイント"
	return "%s　%s" % [name, role]


func _spot_detail_text() -> String:
	return (
		"水深 %s\n狙い：%s\nエサ：%s"
		% [
			_depth_range_text(_spot),
			_featured_fish_text(_spot),
			_bait_text(_spot),
		]
	)


func _depth_range_text(spot: Dictionary) -> String:
	var range: Array = spot.get("depth_range", [0.0, 0.0])
	if range.size() < 2:
		return "--.-m"
	return "%.1f〜%.1fm" % [float(range[0]), float(range[1])]


func _featured_fish_text(spot: Dictionary) -> String:
	var names: Array[String] = []
	for fish_id_variant in Array(spot.get("featured_fish", [])):
		var fish := GameData.get_fish(String(fish_id_variant))
		if fish.is_empty():
			continue
		names.append(String(fish.get("name", fish_id_variant)))
		if names.size() >= 4:
			break
	return "、".join(PackedStringArray(names))


func _bait_text(spot: Dictionary) -> String:
	var baits: Array[String] = []
	for bait_variant in Array(spot.get("recommended_baits", [])):
		baits.append(String(bait_variant))
	return "、".join(PackedStringArray(baits))


func _create_result_overlay() -> void:
	_result_overlay = ColorRect.new()
	_result_overlay.color = Color(0.0, 0.0, 0.0, 0.72)
	_result_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_result_overlay.visible = false
	add_child(_result_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_overlay.add_child(center)
	var panel := make_panel()
	panel.custom_minimum_size = Vector2(620, 340)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(560, 0)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	_result_title = make_label("", 36, Color("#7b431e"))
	_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_result_title)
	_result_details = make_label("", 19)
	_result_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_result_details)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	_retry_button = make_button("もう一度挑戦", _retry, 0)
	_retry_button.custom_minimum_size = Vector2(200, 50)
	row.add_child(_retry_button)
	var harbor_button := make_button("港へ戻る", func() -> void: navigate("harbor"), 0)
	harbor_button.custom_minimum_size = Vector2(200, 50)
	row.add_child(harbor_button)


func _create_quit_overlay() -> void:
	_quit_overlay = ColorRect.new()
	_quit_overlay.color = Color(0.0, 0.0, 0.0, 0.66)
	_quit_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_quit_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_quit_overlay.visible = false
	add_child(_quit_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_quit_overlay.add_child(center)
	var panel := make_panel()
	panel.custom_minimum_size = Vector2(560, 260)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(500, 0)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)

	_quit_title = make_label("港へ戻る", 32, Color("#7b431e"))
	_quit_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_quit_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_quit_title)

	_quit_details = make_label("", 19)
	_quit_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_quit_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quit_details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(_quit_details)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var cancel_button := make_button("続ける", _hide_harbor_confirm, 180)
	row.add_child(cancel_button)
	_quit_confirm_button = make_button("港へ戻る", _confirm_quit_action, 180, true)
	row.add_child(_quit_confirm_button)


func _process(delta: float) -> void:
	if _simulator == null:
		return
	if _quit_overlay != null and _quit_overlay.visible:
		return
	_simulator.tick(delta)
	_update_ui()
	_update_view_visibility(delta)


func _input(event: InputEvent) -> void:
	if _simulator == null or not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if _quit_overlay != null and _quit_overlay.visible:
		if key_event.pressed and not key_event.echo:
			if key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER:
				_confirm_quit_action()
				get_viewport().set_input_as_handled()
			elif key_event.keycode == KEY_ESCAPE:
				_hide_harbor_confirm()
				get_viewport().set_input_as_handled()
		return
	if _result_overlay != null and _result_overlay.visible:
		return
	if key_event.keycode == KEY_SPACE:
		_simulator.set_reeling(key_event.pressed)
		get_viewport().set_input_as_handled()
	elif key_event.keycode == KEY_SHIFT:
		_simulator.set_giving_line(key_event.pressed)
		get_viewport().set_input_as_handled()
	elif (
		key_event.pressed
		and not key_event.echo
		and (key_event.keycode == KEY_E or key_event.keycode == KEY_ENTER)
	):
		_on_main_action_pressed()
		get_viewport().set_input_as_handled()
	elif (
		key_event.pressed
		and not key_event.echo
		and (
			key_event.keycode == KEY_ESCAPE
			or key_event.keycode == KEY_MINUS
			or key_event.keycode == KEY_KP_SUBTRACT
		)
	):
		_request_harbor_return()
		get_viewport().set_input_as_handled()
	elif (
		key_event.pressed
		and not key_event.echo
		and (
			key_event.keycode == KEY_PLUS
			or key_event.keycode == KEY_KP_ADD
		)
	):
		_request_spot_change()
		get_viewport().set_input_as_handled()


func _prepare_new_attempt() -> void:
	_result_recorded = false
	_result_overlay.visible = false
	if _quit_overlay != null:
		_quit_overlay.visible = false
	if bool(_spot.get("boss_spot", false)):
		_current_fish = GameData.get_fish("boss_kurodai")
	else:
		_current_fish = GameData.roll_normal_fish(PlayerProgress.level, _spot_id)
	_simulator.prepare(_current_fish, _trip_stats)
	_view.bind_simulator(_simulator)
	_surface_view.bind_simulator(_simulator)
	_fight_sidebar.bind(_simulator, _current_fish, _trip_stats)
	_fight_hud.bind(_simulator, _current_fish, _trip_stats)
	# 新規挑戦時は水上ビューから（水中は淡出状態で待機）
	_view.modulate.a = 0.0
	_surface_view.modulate.a = 1.0
	_refresh_fish_info()


func _refresh_fish_info() -> void:
	if _fight_sidebar != null:
		_fight_sidebar.set_fish(_current_fish, _trip_stats)


func _sync_fish_info_scroll_size() -> void:
	pass


func _on_main_action_pressed() -> void:
	match _simulator.state:
		FishingSimulator.State.READY:
			_simulator.cast()
		FishingSimulator.State.BITE:
			_simulator.hook()


func _request_harbor_return() -> void:
	if _simulator == null:
		navigate("harbor")
		return
	if _result_overlay != null and _result_overlay.visible:
		return
	if _simulator.state == FishingSimulator.State.READY:
		navigate("harbor")
		return
	_quit_target = "harbor"
	if _quit_title != null:
		_quit_title.text = "港へ戻る"
	if _quit_confirm_button != null:
		_quit_confirm_button.text = "港へ戻る"
	_simulator.set_reeling(false)
	_simulator.set_giving_line(false)
	if _quit_details != null:
		_quit_details.text = _harbor_return_message()
	if _quit_overlay != null:
		_quit_overlay.visible = true


func _request_spot_change() -> void:
	if _simulator == null:
		_navigate_to_spot_select()
		return
	if _result_overlay != null and _result_overlay.visible:
		return
	if _simulator.state == FishingSimulator.State.READY:
		_navigate_to_spot_select()
		return
	_quit_target = "fishing_spots"
	if _quit_title != null:
		_quit_title.text = "釣り場を変える"
	if _quit_confirm_button != null:
		_quit_confirm_button.text = "釣り場選択へ"
	_simulator.set_reeling(false)
	_simulator.set_giving_line(false)
	if _quit_details != null:
		_quit_details.text = _spot_change_message()
	if _quit_overlay != null:
		_quit_overlay.visible = true


func _harbor_return_message() -> String:
	if _simulator != null and _simulator.state == FishingSimulator.State.FIGHT:
		return "ファイトを中断すると魚は逃げます。港へ戻りますか？"
	return "釣りを中断して港へ戻りますか？"


func _spot_change_message() -> String:
	if _simulator != null and _simulator.state == FishingSimulator.State.FIGHT:
		return "ファイトを中断すると魚は逃げます。釣り場を変えますか？"
	return "釣りを中断して釣り場を変えますか？"


func _hide_harbor_confirm() -> void:
	if _quit_overlay != null:
		_quit_overlay.visible = false


func _confirm_harbor_return() -> void:
	_quit_target = "harbor"
	_confirm_quit_action()


func _confirm_quit_action() -> void:
	if _quit_overlay != null:
		_quit_overlay.visible = false
	if _quit_target == "fishing_spots":
		_navigate_to_spot_select()
		return
	navigate("harbor")


func _navigate_to_spot_select() -> void:
	navigate("fishing_spots", {
		"from_fishing": true,
		"current_spot_id": _spot_id,
		"trip_stats": _trip_stats.duplicate(true),
	})


func _on_state_changed(_new_state: int) -> void:
	_update_ui()


func _on_message_changed(message: String) -> void:
	_set_message_text(message)


func _on_fight_finished(caught: bool, reason: String) -> void:
	if caught:
		if not _result_recorded:
			PlayerProgress.record_catch(String(_current_fish["id"]), _simulator.result_size_cm, _spot_id)
			_result_recorded = true
		_result_title.text = "釣り上げ成功！"
		_result_details.text = (
			"%s\n大きさ %.1f cm\nクーラーボックスに入れた。\n港で売るか、料理して食べよう。"
			% [
				String(_current_fish["name"]),
				_simulator.result_size_cm,
			]
		)
		_retry_button.text = "続けて釣る"
	else:
		_result_title.text = "逃げられた……"
		_result_details.text = "%s\n\nテンションの安全域を保ち、魚の突進時は糸を出そう。" % reason
		_retry_button.text = "再挑戦"
	_result_overlay.visible = true


func _retry() -> void:
	_prepare_new_attempt()


func _update_ui() -> void:
	if _simulator == null:
		return
	_set_message_text(_simulator.action_message)

	var show_spot_panel := _simulator.state == FishingSimulator.State.READY
	if _info_title_label != null:
		_info_title_label.visible = show_spot_panel
	if _spot_panel != null:
		_spot_panel.visible = show_spot_panel


func _set_message_text(message: String) -> void:
	if _message_label == null:
		return
	_message_label.text = message
	if _message_panel != null:
		var show_message := not message.strip_edges().is_empty()
		if _simulator != null:
			show_message = show_message and _simulator.state != FishingSimulator.State.READY
			if (
				_simulator.state == FishingSimulator.State.CASTING
				or _simulator.state == FishingSimulator.State.WAITING
				or _simulator.state == FishingSimulator.State.APPROACH
				or _simulator.state == FishingSimulator.State.BITE
				or _simulator.state == FishingSimulator.State.FIGHT
			):
				show_message = false
		_message_panel.visible = show_message


# 水上キャストビュー／水中ビューのクロスフェード。
# FIGHT 以降（CAUGHT/ESCAPED 含む）は水中、それ以外は水上を表示する。
func _update_view_visibility(delta: float) -> void:
	var underwater := (
		_simulator.state == FishingSimulator.State.FIGHT
		or _simulator.state == FishingSimulator.State.CAUGHT
		or (_simulator.state == FishingSimulator.State.ESCAPED and _simulator.fish_revealed)
	)
	var k := 1.0 - exp(-10.0 * delta)
	_surface_view.modulate.a = lerpf(_surface_view.modulate.a, 0.0 if underwater else 1.0, k)
	_view.modulate.a = lerpf(_view.modulate.a, 1.0 if underwater else 0.0, k)
