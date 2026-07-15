extends ScreenBase

const FishingSimulatorScript = preload("res://src/core/fishing_simulator.gd")
const SurfaceCastViewScript = preload("res://src/ui/components/surface_cast_view.gd")
const FightSidebarScript = preload("res://src/ui/components/fight_sidebar.gd")
const FightHudScript = preload("res://src/ui/components/fight_hud.gd")
const FightStatusBarScript = preload("res://src/ui/components/fight_status_bar.gd")
const CatchFanfareScript = preload("res://src/ui/components/catch_fanfare.gd")

const FISHING_BGM_VOLUME_DB := -9.0
const FISHING_BGM_PATH_BY_SURFACE_KEY := {
	"calm": "res://assets/audio/海辺（さざなみ）.mp3",
	"windy": "res://assets/audio/海辺（少し風が強い）.mp3",
}
const FIGHT_BGM_PATH_NORMAL := "res://assets/audio/水中ファイト通常.mp3"
const BITE_SFX_PATH := "res://assets/audio/アタリ_ヒット音.mp3"
const ESCAPED_SFX_PATH := "res://assets/audio/逃げられた.mp3"
const FISHING_SFX_VOLUME_DB := -2.0
const TRIP_EVENT_MESSAGE_DURATION := 3.5
const SHARK_AMBUSH_REASON := "巨大な影が食らいついた！ 獲物を横取りされた……"
const SHARK_AMBUSH_FLASH_DURATION := 0.34

var _simulator: FishingSimulator
var _trip_stats: Dictionary = {}
var _current_fish: Dictionary = {}
var _result_recorded: bool = false
var _spot_id: String = GameData.DEFAULT_FISHING_SPOT_ID
var _spot: Dictionary = {}
var _selected_shark_lure_fish_id := ""
var _shark_ambush_plan: Dictionary = {}
var _shark_ambush_triggered := false
var _shark_ambush_flash_timer := 0.0

var _info_panel: MarginContainer
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
var _screen_time_slot_grade_overlay: ColorRect
var _time_slot_grade_overlay: ColorRect
var _time_slot_vignette: FishingTimeSlotVignette
var _fight_sidebar: FightSidebar
var _fight_floating_card: FightSidebar
var _fight_hud: FightHud
var _fight_status_bar: FightStatusBar
var _catch_fanfare: CatchFanfare

var _result_overlay: ColorRect
var _result_title: Label
var _result_details: Label
var _retry_button: Button
var _result_harbor_button: Button
var _quit_overlay: ColorRect
var _quit_title: Label
var _quit_details: Label
var _quit_cancel_button: Button
var _quit_confirm_button: Button
var _quit_target := "harbor"
var _focus_before_modal: Control
var _shark_ambush_flash: ColorRect
var _nushi_omen_shown := false
var _trip_event_message: String = ""
var _trip_event_message_timer: float = 0.0


func _build_screen() -> void:
	add_gradient_background(Palette.FISHING_BG_TOP, Palette.FISHING_BG_BOTTOM)
	_resolve_selected_spot()
	_resolve_trip_stats()
	_apply_spot_to_trip_stats()
	_ensure_trip_environment()
	_ensure_trip_time_slot()
	_build_screen_time_slot_grade_overlay()
	_ensure_trip_rig()
	_play_fishing_bgm()
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
	_build_time_slot_grade_overlay(water_panel)
	_build_time_slot_vignette(water_panel)

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
	_message_label = make_body_label("", 18, Palette.FISHING_MESSAGE_TEXT, 2, Palette.FISHING_MESSAGE_OUTLINE)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# 単一行メッセージ帯。autowrap+clip_text+trim の組み合わせだと
	# 高さ計算が潰れて文字が描画されないため、折り返しとトリムを無効化する
	_message_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_message_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_message_label.custom_minimum_size = Vector2(0.0, 26.0)
	_message_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_message_panel.add_child(_message_label)

	_fight_floating_card = FightSidebarScript.new()
	_fight_floating_card.set_floating_card(true)
	_fight_floating_card.visible = false
	_fight_floating_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fight_floating_card.anchor_left = 1.0
	_fight_floating_card.anchor_top = 0.0
	_fight_floating_card.anchor_right = 1.0
	_fight_floating_card.anchor_bottom = 0.0
	_fight_floating_card.offset_left = -306.0
	_fight_floating_card.offset_top = 16.0
	_fight_floating_card.offset_right = -18.0
	_fight_floating_card.offset_bottom = 136.0
	message_layer.add_child(_fight_floating_card)

	_fight_hud = FightHudScript.new()
	_fight_hud.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fight_hud.custom_minimum_size = Vector2(0.0, FightHudScript.DEFAULT_HUD_HEIGHT)
	_fight_hud.main_action_pressed.connect(_on_main_action_pressed)
	_fight_hud.reel_changed.connect(func(active: bool) -> void: _simulator.set_reeling(active))
	_fight_hud.give_line_changed.connect(func(active: bool) -> void: _simulator.set_giving_line(active))
	_fight_hud.harbor_pressed.connect(_request_harbor_return)
	_fight_hud.change_spot_pressed.connect(_request_spot_change)
	_fight_hud.shark_lure_previous_pressed.connect(func() -> void: _cycle_selected_shark_lure(-1))
	_fight_hud.shark_lure_next_pressed.connect(func() -> void: _cycle_selected_shark_lure(1))
	left_column.add_child(_fight_hud)

	_info_panel = MarginContainer.new()
	_info_panel.custom_minimum_size = Vector2(326, 0)
	_info_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_info_panel.size_flags_stretch_ratio = 0.0
	_info_panel.clip_contents = true
	_info_panel.add_theme_constant_override("margin_left", 0)
	_info_panel.add_theme_constant_override("margin_top", 0)
	_info_panel.add_theme_constant_override("margin_right", 0)
	_info_panel.add_theme_constant_override("margin_bottom", 0)
	body.add_child(_info_panel)
	var info_box := VBoxContainer.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_box.add_theme_constant_override("separation", 6)
	_info_panel.add_child(info_box)
	_info_title_label = make_label("釣り場", 24, Palette.TEXT_BONE, 2, Palette.TEXT_OUTLINE_DARK)
	_info_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# autowrap+trim の組み合わせだと最小サイズが潰れて描画されないため無効化する
	_info_title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_info_title_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_info_title_label.custom_minimum_size = Vector2(0.0, 30.0)
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
	_spot_summary_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_spot_summary_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_spot_summary_label.custom_minimum_size = Vector2(0.0, 22.0)
	spot_box.add_child(_spot_summary_label)
	_spot_detail_label = make_label(_spot_detail_text(), 13, Palette.TEXT_BODY)
	_spot_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_spot_detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_spot_detail_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_spot_detail_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_spot_detail_label.custom_minimum_size = Vector2(0.0, 60.0)
	spot_box.add_child(_spot_detail_label)

	_fight_sidebar = FightSidebarScript.new()
	_fight_sidebar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fight_sidebar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_box.add_child(_fight_sidebar)

	_create_result_overlay()
	_create_quit_overlay()
	_create_shark_ambush_flash()
	_create_catch_fanfare()
	_prepare_new_attempt()
	_update_ui()


func _resolve_selected_spot() -> void:
	var requested_id := String(route_payload.get("spot_id", GameData.DEFAULT_FISHING_SPOT_ID))
	if (
		not bool(route_payload.get("continue_trip", false))
		and not PlayerProgress.can_access_fishing_spot(requested_id)
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
			_init_trip_event_state()
			_resolve_initial_shark_lure_selection()
			return
	_trip_stats = PlayerProgress.begin_fishing_trip()
	_init_trip_event_state()
	_resolve_initial_shark_lure_selection()


func _resolve_initial_shark_lure_selection() -> void:
	_selected_shark_lure_fish_id = ""
	if _spot_id != "danger_reef":
		return
	for fish_id_variant in [
		route_payload.get("shark_lure_fish_id", ""),
		_trip_stats.get("shark_lure_fish_id", ""),
	]:
		var fish_id := _valid_shark_lure_selection_id(String(fish_id_variant))
		if not fish_id.is_empty():
			_selected_shark_lure_fish_id = fish_id
			return


func _init_trip_event_state() -> void:
	if not _trip_stats.has("trip_fired_event_ids"):
		_trip_stats["trip_fired_event_ids"] = []
	if not _trip_stats.has("bird_swarm_hits_remaining"):
		_trip_stats["bird_swarm_hits_remaining"] = 0
	if typeof(_trip_stats.get("shark_lure_charges", {})) != TYPE_DICTIONARY:
		_trip_stats["shark_lure_charges"] = {}


func _trip_fired_event_ids() -> Array[String]:
	var ids: Array[String] = []
	for id_variant in Array(_trip_stats.get("trip_fired_event_ids", [])):
		ids.append(String(id_variant))
	return ids


func _apply_spot_to_trip_stats() -> void:
	_trip_stats["spot_id"] = _spot_id
	_trip_stats["spot_name"] = String(_spot.get("name", "港内・堤防"))
	_trip_stats["spot_short_name"] = String(_spot.get("short_name", _trip_stats["spot_name"]))
	_trip_stats["spot_depth_range"] = _spot.get("depth_range", [0.0, 0.0])
	_trip_stats["spot_featured_fish"] = _spot.get("featured_fish", [])
	_trip_stats["spot_recommended_baits"] = _spot.get("recommended_baits", [])
	_trip_stats["spot_boss"] = bool(_spot.get("boss_spot", false))


func _ensure_trip_environment() -> void:
	var environment_id := String(_trip_stats.get("environment_id", GameData.DEFAULT_FISHING_ENVIRONMENT_ID))
	var environment := GameData.get_fishing_environment(environment_id)
	if String(_trip_stats.get("environment_id", "")).strip_edges().is_empty():
		_trip_stats["environment_id"] = String(environment.get("id", GameData.DEFAULT_FISHING_ENVIRONMENT_ID))
	if String(_trip_stats.get("weather_id", "")).strip_edges().is_empty():
		_trip_stats["weather_id"] = String(environment.get("weather_id", "sunny"))
	if String(_trip_stats.get("weather_label", "")).strip_edges().is_empty():
		_trip_stats["weather_label"] = String(environment.get("weather_label", "快晴"))
	if String(_trip_stats.get("wind_id", "")).strip_edges().is_empty():
		_trip_stats["wind_id"] = String(environment.get("wind_id", "weak"))
	if String(_trip_stats.get("wind_label", "")).strip_edges().is_empty():
		_trip_stats["wind_label"] = String(environment.get("wind_label", "風 弱"))
	if String(_trip_stats.get("surface_bgm_key", "")).strip_edges().is_empty():
		_trip_stats["surface_bgm_key"] = String(environment.get("surface_bgm_key", "calm"))


func _ensure_trip_time_slot() -> void:
	var time_slot_id := String(_trip_stats.get("time_slot_id", PlayerProgress.selected_time_slot_id))
	var time_slot := GameData.get_time_slot(time_slot_id)
	time_slot_id = String(time_slot.get("id", GameData.DEFAULT_TIME_SLOT_ID))
	if not GameData.is_time_slot_unlocked(time_slot_id, PlayerProgress.level):
		time_slot_id = GameData.DEFAULT_TIME_SLOT_ID
		time_slot = GameData.get_time_slot(time_slot_id)
	_trip_stats["time_slot_id"] = time_slot_id
	_trip_stats["time_slot_label"] = String(time_slot.get("name", "日中"))
	_trip_stats["time_slot_grade"] = String(time_slot.get("grade", "none"))
	var bgm_override := String(time_slot.get("surface_bgm_key_override", ""))
	if not bgm_override.strip_edges().is_empty():
		_trip_stats["surface_bgm_key"] = bgm_override


func _ensure_trip_rig() -> void:
	var rig_id := String(_trip_stats.get("rig_id", ""))
	if rig_id.strip_edges().is_empty() or GameData.get_rig(rig_id).is_empty():
		rig_id = PlayerProgress.equipped_rig_id
	var rig := GameData.get_rig(rig_id)
	if rig.is_empty():
		rig_id = GameData.DEFAULT_RIG_ID
		rig = GameData.get_rig(rig_id)
	_trip_stats["rig_id"] = rig_id
	_trip_stats["rig_name"] = String(rig.get("name", "サビキ仕掛け"))
	_trip_stats["rig_bait_types"] = GameData.rig_bait_types(rig_id)


func _play_fishing_bgm() -> void:
	var bgm_key := String(_trip_stats.get("surface_bgm_key", "calm"))
	var path := String(FISHING_BGM_PATH_BY_SURFACE_KEY.get(bgm_key, FISHING_BGM_PATH_BY_SURFACE_KEY["calm"]))
	play_screen_bgm(path, FISHING_BGM_VOLUME_DB)


func _play_fight_bgm() -> void:
	play_screen_bgm(_fight_bgm_path(), FISHING_BGM_VOLUME_DB)


func _fight_bgm_path() -> String:
	return FIGHT_BGM_PATH_NORMAL


func _build_screen_time_slot_grade_overlay() -> void:
	_screen_time_slot_grade_overlay = ColorRect.new()
	_screen_time_slot_grade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen_time_slot_grade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen_time_slot_grade_overlay.color = _screen_time_slot_grade_color()
	add_child(_screen_time_slot_grade_overlay)


func _build_time_slot_grade_overlay(parent: Control) -> void:
	_time_slot_grade_overlay = ColorRect.new()
	_time_slot_grade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_time_slot_grade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_time_slot_grade_overlay.color = _time_slot_grade_color()
	parent.add_child(_time_slot_grade_overlay)


func _build_time_slot_vignette(parent: Control) -> void:
	_time_slot_vignette = FishingTimeSlotVignette.new()
	_time_slot_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_time_slot_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_time_slot_vignette.grade = String(_trip_stats.get("time_slot_grade", "none"))
	parent.add_child(_time_slot_vignette)


func _screen_time_slot_grade_color() -> Color:
	match String(_trip_stats.get("time_slot_grade", "none")):
		"warm":
			return Palette.FISHING_TIME_GRADE_EDGE_WARM
		"cool":
			return Palette.FISHING_TIME_GRADE_EDGE_COOL
	return Palette.FISHING_TIME_GRADE_CLEAR


func _time_slot_grade_color() -> Color:
	match String(_trip_stats.get("time_slot_grade", "none")):
		"warm":
			return Palette.FISHING_TIME_GRADE_WARM
		"cool":
			return Palette.FISHING_TIME_GRADE_COOL
	return Palette.FISHING_TIME_GRADE_CLEAR


func _result_overlay_dim_color() -> Color:
	match String(_trip_stats.get("time_slot_grade", "none")):
		"warm":
			return Palette.FISHING_RESULT_OVERLAY_DIM_WARM
		"cool":
			return Palette.FISHING_RESULT_OVERLAY_DIM_COOL
	return Palette.FISHING_RESULT_OVERLAY_DIM


func _spot_summary_text() -> String:
	var name := String(_spot.get("name", "港内・堤防"))
	var role := "ぬし専用" if bool(_spot.get("boss_spot", false)) else "通常ポイント"
	return "%s　%s" % [name, role]


func _spot_detail_text() -> String:
	var rig_line := "仕掛け：%s" % _rig_summary_text()
	var lure_summary := _shark_lure_summary_text()
	if not lure_summary.is_empty():
		rig_line = "%s / 餌魚:%s" % [rig_line, lure_summary]
	return (
		"水深 %s\n狙い：%s\n%s"
		% [
			_depth_range_text(_spot),
			_featured_fish_text(_spot),
			rig_line,
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


func _rig_summary_text() -> String:
	var rig_name := String(_trip_stats.get("rig_name", "サビキ仕掛け"))
	var bait_types: Array[String] = []
	for bait_variant in Array(_trip_stats.get("rig_bait_types", [])):
		bait_types.append(String(bait_variant))
	if bait_types.is_empty():
		return rig_name
	return "%s（%s）" % [rig_name, "、".join(PackedStringArray(bait_types))]


func _shark_lure_summary_text() -> String:
	if _spot_id != "danger_reef":
		return ""
	if not _selected_shark_lure_fish_id.is_empty():
		var selected_fish := GameData.get_fish(_selected_shark_lure_fish_id)
		if not selected_fish.is_empty():
			return String(selected_fish.get("name", _selected_shark_lure_fish_id))
	return ""


func _create_result_overlay() -> void:
	_result_overlay = ColorRect.new()
	_result_overlay.color = _result_overlay_dim_color()
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
	_result_title = make_label("", 36, Palette.FISHING_RESULT_TITLE_TEXT)
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
	_result_harbor_button = make_button("港へ戻る", func() -> void: navigate("harbor"), 0)
	_result_harbor_button.custom_minimum_size = Vector2(200, 50)
	row.add_child(_result_harbor_button)


func _create_quit_overlay() -> void:
	_quit_overlay = ColorRect.new()
	_quit_overlay.color = Palette.FISHING_QUIT_OVERLAY_DIM
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

	_quit_title = make_label("港へ戻る", 32, Palette.FISHING_RESULT_TITLE_TEXT)
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
	_quit_cancel_button = make_button("続ける", _hide_harbor_confirm, 180)
	row.add_child(_quit_cancel_button)
	_quit_confirm_button = make_button("港へ戻る", _confirm_quit_action, 180, true)
	row.add_child(_quit_confirm_button)


func _create_shark_ambush_flash() -> void:
	_shark_ambush_flash = ColorRect.new()
	_shark_ambush_flash.color = Palette.FISHING_AMBUSH_FLASH_CLEAR
	_shark_ambush_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shark_ambush_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shark_ambush_flash.z_index = 90
	_shark_ambush_flash.visible = false
	add_child(_shark_ambush_flash)


func _create_catch_fanfare() -> void:
	_catch_fanfare = CatchFanfareScript.new()
	_catch_fanfare.z_index = 80
	_catch_fanfare.focus_context_changed.connect(func(_active: bool) -> void: _sync_keyboard_focus_context())
	_catch_fanfare.continue_requested.connect(_on_catch_fanfare_continue_requested)
	_catch_fanfare.harbor_requested.connect(_on_catch_fanfare_harbor_requested)
	add_child(_catch_fanfare)


func _process(delta: float) -> void:
	if _simulator == null:
		return
	_update_shark_ambush_flash(delta)
	if _trip_event_message_timer > 0.0:
		_trip_event_message_timer = maxf(0.0, _trip_event_message_timer - delta)
		if _trip_event_message_timer <= 0.0:
			_trip_event_message = ""
			_update_ui()
	if _quit_overlay != null and _quit_overlay.visible:
		return
	if _catch_fanfare != null and _catch_fanfare.is_playing():
		return
	_simulator.tick(delta)
	_check_shark_ambush()
	_update_ui()
	_update_view_visibility(delta)


func _input(event: InputEvent) -> void:
	if _simulator == null or not event is InputEventKey:
		return
	if _catch_fanfare != null and _catch_fanfare.is_playing():
		return
	var key_event := event as InputEventKey
	if _quit_overlay != null and _quit_overlay.visible:
		if key_event.pressed and not key_event.echo:
			if key_event.keycode == KEY_ESCAPE:
				_hide_harbor_confirm()
				get_viewport().set_input_as_handled()
		return
	if _result_overlay != null and _result_overlay.visible:
		return
	if key_event.keycode == KEY_SPACE and _simulator.state == FishingSimulator.State.FIGHT:
		if not key_event.echo:
			_simulator.set_reeling(key_event.pressed)
		get_viewport().set_input_as_handled()
	elif key_event.keycode == KEY_SHIFT and _simulator.state == FishingSimulator.State.FIGHT:
		if not key_event.echo:
			_simulator.set_giving_line(key_event.pressed)
		get_viewport().set_input_as_handled()
	elif (
		key_event.pressed
		and not key_event.echo
		and _can_change_selected_shark_lure()
		and (key_event.keycode == KEY_LEFT or key_event.keycode == KEY_RIGHT)
	):
		_cycle_selected_shark_lure(-1 if key_event.keycode == KEY_LEFT else 1)
		get_viewport().set_input_as_handled()
	elif (
		key_event.pressed
		and not key_event.echo
		and _simulator.state in [FishingSimulator.State.READY, FishingSimulator.State.BITE]
		and key_event.keycode == KEY_E
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


func _sync_keyboard_focus_context(preferred_override: Control = null) -> void:
	if not is_inside_tree():
		return
	var targets: Array[Control] = []
	var preferred: Control = null
	if _catch_fanfare != null and _catch_fanfare.is_playing():
		targets = _catch_fanfare.keyboard_focus_targets()
		preferred = _catch_fanfare.preferred_keyboard_focus_target()
	elif _quit_overlay != null and _quit_overlay.visible:
		targets = [_quit_cancel_button, _quit_confirm_button]
		preferred = _quit_cancel_button
	elif _result_overlay != null and _result_overlay.visible:
		targets = [_retry_button, _result_harbor_button]
		preferred = _retry_button
	elif _fight_hud != null:
		targets = _fight_hud.keyboard_focus_targets()
		preferred = _fight_hud.preferred_keyboard_focus_target()
	if preferred_override != null and targets.has(preferred_override):
		preferred = preferred_override
	_link_keyboard_focus_cycle(targets)
	setup_keyboard_focus(targets, preferred)


func _link_keyboard_focus_cycle(targets: Array[Control]) -> void:
	for control in targets:
		if control == null:
			continue
		control.focus_neighbor_left = NodePath()
		control.focus_neighbor_right = NodePath()
		control.focus_neighbor_top = NodePath()
		control.focus_neighbor_bottom = NodePath()
		control.focus_next = NodePath()
		control.focus_previous = NodePath()
	if targets.size() <= 1:
		return
	for index in targets.size():
		var control := targets[index]
		var previous := targets[(index - 1 + targets.size()) % targets.size()]
		var next := targets[(index + 1) % targets.size()]
		var previous_path := control.get_path_to(previous)
		var next_path := control.get_path_to(next)
		control.focus_neighbor_left = previous_path
		control.focus_neighbor_top = previous_path
		control.focus_previous = previous_path
		control.focus_neighbor_right = next_path
		control.focus_neighbor_bottom = next_path
		control.focus_next = next_path


func _remember_gameplay_focus() -> void:
	_focus_before_modal = null
	if _fight_hud == null:
		return
	var owner := get_viewport().gui_get_focus_owner()
	if owner != null and _fight_hud.keyboard_focus_targets().has(owner):
		_focus_before_modal = owner


func _prepare_new_attempt() -> void:
	_result_recorded = false
	_result_overlay.visible = false
	_shark_ambush_plan = {}
	_shark_ambush_triggered = false
	if _quit_overlay != null:
		_quit_overlay.visible = false
	_play_fishing_bgm()
	if _delays_hook_roll_until_cast():
		_current_fish = {}
	else:
		_current_fish = _roll_hooked_fish_for_current_cast()
		_prepare_shark_ambush_plan()
	_prepare_simulator_with_current_fish()
	# 新規挑戦時は水上ビューから（水中は淡出状態で待機）
	_view.modulate.a = 0.0
	_surface_view.modulate.a = 1.0
	_refresh_fish_info()
	_sync_keyboard_focus_context()


func _prepare_simulator_with_current_fish() -> void:
	_prepare_current_fish_in_simulator()
	_view.bind_simulator(_simulator)
	_surface_view.bind_simulator(_simulator)
	_fight_sidebar.bind(_simulator, _current_fish, _trip_stats)
	if _fight_floating_card != null:
		_fight_floating_card.bind(_simulator, _current_fish, _trip_stats)
	_fight_hud.bind(_simulator, _current_fish, _trip_stats)
	_sync_ready_shark_lure_selector()


func _prepare_current_fish_in_simulator() -> void:
	var simulator_fish := _current_fish.duplicate(true)
	if simulator_fish.has("stamina"):
		var stamina_multiplier := float(
			PlayerProgress.difficulty().get("fish_stamina_multiplier", 1.0)
		)
		simulator_fish["stamina"] = float(simulator_fish["stamina"]) * stamina_multiplier
	_simulator.prepare(simulator_fish, _trip_stats)


func _delays_hook_roll_until_cast() -> bool:
	return _spot_id == "danger_reef" and not bool(_spot.get("boss_spot", false))


func _roll_hooked_fish_for_current_cast() -> Dictionary:
	if bool(_spot.get("boss_spot", false)):
		return GameData.get_fish("boss_kurodai")
	var extra_modifiers := _trip_extra_fish_weight_modifiers()
	var fish := GameData.roll_hooked_fish(
		PlayerProgress.level,
		_spot_id,
		String(_trip_stats.get("rig_id", PlayerProgress.equipped_rig_id)),
		String(_trip_stats.get("environment_id", GameData.DEFAULT_FISHING_ENVIRONMENT_ID)),
		String(_trip_stats.get("time_slot_id", "")),
		extra_modifiers,
		PlayerProgress.shark_bonds,
		_trip_shark_lure_fish_data()
	)
	if int(_trip_stats.get("bird_swarm_hits_remaining", 0)) > 0:
		_trip_stats["bird_swarm_hits_remaining"] = int(_trip_stats.get("bird_swarm_hits_remaining", 0)) - 1
	return fish


func _refresh_fish_info() -> void:
	if _fight_sidebar != null:
		_fight_sidebar.set_fish(_current_fish, _trip_stats)
	if _fight_floating_card != null:
		_fight_floating_card.set_fish(_current_fish, _trip_stats)


func _trip_extra_fish_weight_modifiers() -> Dictionary:
	var modifiers: Dictionary = {}
	if int(_trip_stats.get("bird_swarm_hits_remaining", 0)) > 0:
		_merge_fish_weight_modifiers(modifiers, GameData.bird_swarm_fish_weight_modifiers())
	var lure_fish := _trip_shark_lure_fish_data()
	if not lure_fish.is_empty():
		_merge_fish_weight_modifiers(modifiers, GameData.shark_lure_weights(lure_fish))
	return modifiers


func _merge_fish_weight_modifiers(target: Dictionary, source: Dictionary) -> void:
	for fish_id_variant in source.keys():
		var fish_id := String(fish_id_variant)
		var multiplier := float(source[fish_id_variant])
		if target.has(fish_id):
			target[fish_id] = float(target[fish_id]) * multiplier
		else:
			target[fish_id] = multiplier


func _trip_shark_lure_fish_data() -> Dictionary:
	if _spot_id != "danger_reef":
		return {}
	var fish_id := String(_trip_stats.get("shark_lure_fish_id", ""))
	if fish_id.is_empty():
		return {}
	var fish := GameData.get_fish(fish_id)
	if bool(fish.get("shark", false)):
		return {}
	return fish


func _valid_shark_lure_selection_id(fish_id: String) -> String:
	if fish_id.strip_edges().is_empty():
		return ""
	var fish := GameData.get_fish(fish_id)
	if fish.is_empty() or bool(fish.get("shark", false)):
		return ""
	if PlayerProgress.fish_count(fish_id) <= 0 and _shark_lure_remaining_charges(fish_id) <= 0:
		return ""
	return fish_id


func _can_change_selected_shark_lure() -> bool:
	return (
		_spot_id == "danger_reef"
		and _simulator != null
		and _simulator.state == FishingSimulator.State.READY
	)


func _cycle_selected_shark_lure(direction: int) -> void:
	if not _can_change_selected_shark_lure():
		return
	var candidates := _shark_lure_candidate_ids()
	if candidates.is_empty():
		candidates.append("")
	if candidates.size() <= 1:
		return
	var current_index := candidates.find(_selected_shark_lure_fish_id)
	if current_index < 0:
		current_index = 0
	var next_index := current_index + direction
	while next_index < 0:
		next_index += candidates.size()
	while next_index >= candidates.size():
		next_index -= candidates.size()
	_selected_shark_lure_fish_id = candidates[next_index]
	_refresh_ready_lure_selection_display()


func _shark_lure_candidate_ids() -> Array[String]:
	var ids: Array[String] = [""]
	var seen: Dictionary = {"": true}
	for fish_id_variant in PlayerProgress.inventory.keys():
		var fish_id := _valid_shark_lure_selection_id(String(fish_id_variant))
		if fish_id.is_empty() or seen.has(fish_id):
			continue
		ids.append(fish_id)
		seen[fish_id] = true
	for fish_id_variant in _shark_lure_charges().keys():
		var fish_id := _valid_shark_lure_selection_id(String(fish_id_variant))
		if fish_id.is_empty() or seen.has(fish_id):
			continue
		ids.append(fish_id)
		seen[fish_id] = true
	return ids


func _refresh_ready_lure_selection_display() -> void:
	if _spot_detail_label != null:
		_spot_detail_label.text = _spot_detail_text()
	_sync_ready_shark_lure_selector()
	_update_ui()
	_sync_keyboard_focus_context()


func _sync_ready_shark_lure_selector() -> void:
	if _fight_hud == null:
		return
	_fight_hud.set_shark_lure_selector(_ready_shark_lure_selector_data())


func _ready_shark_lure_selector_data() -> Dictionary:
	var data: Dictionary = {
		"danger": _spot_id == "danger_reef",
		"candidate_count": 0,
		"fish_id": _selected_shark_lure_fish_id,
		"fish": {},
		"count": 0,
		"remaining": 0,
		"total_charges": 0,
	}
	if _spot_id != "danger_reef":
		return data
	data["candidate_count"] = _shark_lure_candidate_ids().size()
	if _selected_shark_lure_fish_id.is_empty():
		return data
	var fish := GameData.get_fish(_selected_shark_lure_fish_id)
	if fish.is_empty() or bool(fish.get("shark", false)):
		return data
	data["fish"] = fish
	data["count"] = PlayerProgress.fish_count(_selected_shark_lure_fish_id)
	data["remaining"] = _shark_lure_remaining_charges(_selected_shark_lure_fish_id)
	data["total_charges"] = GameData.shark_lure_charges_for(fish)
	return data


func _shark_lure_charges() -> Dictionary:
	var charges_variant = _trip_stats.get("shark_lure_charges", {})
	if typeof(charges_variant) != TYPE_DICTIONARY:
		charges_variant = {}
		_trip_stats["shark_lure_charges"] = charges_variant
	return charges_variant


func _shark_lure_remaining_charges(fish_id: String) -> int:
	if fish_id.is_empty():
		return 0
	return maxi(0, int(_shark_lure_charges().get(fish_id, 0)))


func _set_shark_lure_remaining_charges(fish_id: String, remaining: int) -> void:
	if fish_id.is_empty():
		return
	var charges := _shark_lure_charges()
	if remaining <= 0:
		charges.erase(fish_id)
	else:
		charges[fish_id] = remaining
	_trip_stats["shark_lure_charges"] = charges


func _set_effective_shark_lure(fish_id: String, fish: Dictionary) -> void:
	_trip_stats["shark_lure_fish_id"] = fish_id
	_trip_stats["shark_lure_fish_name"] = String(fish.get("name", fish_id))


func _clear_effective_shark_lure() -> void:
	_trip_stats.erase("shark_lure_fish_id")
	_trip_stats.erase("shark_lure_fish_name")


func _apply_selected_shark_lure_for_cast() -> bool:
	if _spot_id != "danger_reef":
		return true
	var fish_id := _selected_shark_lure_fish_id
	if fish_id.is_empty():
		_clear_effective_shark_lure()
		return true
	var fish := GameData.get_fish(fish_id)
	if fish.is_empty() or bool(fish.get("shark", false)):
		_selected_shark_lure_fish_id = ""
		_show_trip_event_message("餌魚がありません")
		return false
	var remaining := _shark_lure_remaining_charges(fish_id)
	if remaining > 0:
		_set_shark_lure_remaining_charges(fish_id, remaining - 1)
		_set_effective_shark_lure(fish_id, fish)
		if PlayerProgress.fish_count(fish_id) <= 0 and _shark_lure_remaining_charges(fish_id) <= 0:
			_selected_shark_lure_fish_id = ""
		return true
	if PlayerProgress.fish_count(fish_id) <= 0:
		_selected_shark_lure_fish_id = ""
		_show_trip_event_message("餌魚がありません")
		return false
	var consume_result := PlayerProgress.consume_fish_for_shark_lure(fish_id)
	if not bool(consume_result.get("ok", false)):
		_selected_shark_lure_fish_id = ""
		_show_trip_event_message(String(consume_result.get("message", "餌魚がありません")))
		return false
	var charges_total := GameData.shark_lure_charges_for(fish)
	_set_shark_lure_remaining_charges(fish_id, maxi(0, charges_total - 1))
	_set_effective_shark_lure(fish_id, fish)
	if PlayerProgress.fish_count(fish_id) <= 0 and _shark_lure_remaining_charges(fish_id) <= 0:
		_selected_shark_lure_fish_id = ""
	return true


func _prepare_shark_ambush_plan() -> void:
	if not GameData.can_shark_ambush(_spot_id, _current_fish):
		return
	_shark_ambush_plan = GameData.shark_ambush_plan(randf(), randf())


func _check_shark_ambush() -> void:
	if _shark_ambush_triggered or _shark_ambush_plan.is_empty():
		return
	if not bool(_shark_ambush_plan.get("active", false)):
		return
	if _simulator == null or _simulator.state != FishingSimulator.State.FIGHT:
		return
	if _simulator.fish_stamina_ratio() > float(_shark_ambush_plan.get("threshold", 0.0)):
		return
	_shark_ambush_triggered = true
	_show_shark_ambush_flash()
	_simulator.force_escape(SHARK_AMBUSH_REASON)


func _show_shark_ambush_flash() -> void:
	_shark_ambush_flash_timer = SHARK_AMBUSH_FLASH_DURATION
	if _shark_ambush_flash == null:
		return
	_shark_ambush_flash.color = Palette.FISHING_AMBUSH_FLASH
	_shark_ambush_flash.visible = true


func _update_shark_ambush_flash(delta: float) -> void:
	if _shark_ambush_flash == null or _shark_ambush_flash_timer <= 0.0:
		return
	_shark_ambush_flash_timer = maxf(0.0, _shark_ambush_flash_timer - delta)
	var ratio := _shark_ambush_flash_timer / SHARK_AMBUSH_FLASH_DURATION
	_shark_ambush_flash.color = Palette.FISHING_AMBUSH_FLASH.lerp(
		Palette.FISHING_AMBUSH_FLASH_CLEAR,
		1.0 - clampf(ratio, 0.0, 1.0)
	)
	if _shark_ambush_flash_timer <= 0.0:
		_shark_ambush_flash.visible = false


func _on_main_action_pressed() -> void:
	match _simulator.state:
		FishingSimulator.State.READY:
			if _delays_hook_roll_until_cast():
				_cast_delayed_shark_lure_attempt()
			else:
				_nushi_omen_shown = true
				_simulator.cast()
		FishingSimulator.State.BITE:
			_simulator.hook()


func _cast_delayed_shark_lure_attempt() -> void:
	if not _apply_selected_shark_lure_for_cast():
		_update_ui()
		return
	_current_fish = _roll_hooked_fish_for_current_cast()
	_prepare_shark_ambush_plan()
	_prepare_simulator_with_current_fish()
	_nushi_omen_shown = true
	_simulator.cast()
	_update_ui()


func _request_harbor_return() -> void:
	if _simulator == null:
		navigate("harbor")
		return
	if _result_overlay != null and _result_overlay.visible:
		return
	if _simulator.state == FishingSimulator.State.READY:
		navigate("harbor")
		return
	_remember_gameplay_focus()
	_quit_target = "harbor"
	if _quit_title != null:
		_quit_title.text = "港へ戻る"
	if _quit_confirm_button != null:
		_quit_confirm_button.text = "港へ戻る"
	_simulator.set_reeling(false)
	_simulator.set_giving_line(false)
	if _quit_details != null:
		_quit_details.text = _harbor_return_message()
	if _fight_hud != null:
		_fight_hud.release_held_actions()
	if _quit_overlay != null:
		_quit_overlay.visible = true
	_sync_keyboard_focus_context()


func _request_spot_change() -> void:
	if _simulator == null:
		_navigate_to_spot_select()
		return
	if _result_overlay != null and _result_overlay.visible:
		return
	if _simulator.state == FishingSimulator.State.READY:
		_navigate_to_spot_select()
		return
	_remember_gameplay_focus()
	_quit_target = "fishing_spots"
	if _quit_title != null:
		_quit_title.text = "釣り場を変える"
	if _quit_confirm_button != null:
		_quit_confirm_button.text = "釣り場選択へ"
	_simulator.set_reeling(false)
	_simulator.set_giving_line(false)
	if _quit_details != null:
		_quit_details.text = _spot_change_message()
	if _fight_hud != null:
		_fight_hud.release_held_actions()
	if _quit_overlay != null:
		_quit_overlay.visible = true
	_sync_keyboard_focus_context()


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
	var restore_target := _focus_before_modal
	_focus_before_modal = null
	_sync_keyboard_focus_context(restore_target)


func _confirm_quit_action() -> void:
	if _quit_overlay != null:
		_quit_overlay.visible = false
	_focus_before_modal = null
	_sync_keyboard_focus_context()
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


func _on_state_changed(new_state: int) -> void:
	if new_state == FishingSimulator.State.WAITING:
		_roll_and_apply_trip_event()
	_update_bgm_for_state(new_state)
	_update_ui()
	_sync_keyboard_focus_context()


func _update_bgm_for_state(state: int) -> void:
	if state == FishingSimulator.State.FIGHT:
		_play_fight_bgm()
	elif state == FishingSimulator.State.BITE:
		_play_fishing_bgm()
		play_screen_sfx(BITE_SFX_PATH, FISHING_SFX_VOLUME_DB)
	elif state != FishingSimulator.State.FIGHT:
		_play_fishing_bgm()


func _on_message_changed(message: String) -> void:
	_set_message_text(message)


func _on_fight_finished(caught: bool, reason: String) -> void:
	if caught:
		var catch_result: Dictionary = {}
		if not _result_recorded:
			catch_result = PlayerProgress.record_catch(
				String(_current_fish["id"]),
				_simulator.result_size_cm,
				_spot_id
			)
			_result_recorded = true
		_add_favorite_bait_discovery(catch_result)
		if _catch_fanfare != null:
			_result_overlay.visible = false
			_catch_fanfare.play(_current_fish, _simulator.result_size_cm, catch_result, _trip_stats)
			_sync_keyboard_focus_context()
			return
	else:
		if reason == SHARK_AMBUSH_REASON:
			_result_title.text = "横取りされた……"
			_result_details.text = "%s\n\n危険海域では、弱った獲物にサメが寄ってくることがある。" % reason
		else:
			_result_title.text = "逃げられた……"
			_result_details.text = "%s\n\nテンションの安全域を保ち、魚の突進時は糸を出そう。" % reason
		_retry_button.text = "再挑戦"
		play_screen_sfx(ESCAPED_SFX_PATH, FISHING_SFX_VOLUME_DB)
	_result_overlay.visible = true
	_sync_keyboard_focus_context()


func _on_catch_fanfare_continue_requested() -> void:
	_retry()


func _on_catch_fanfare_harbor_requested() -> void:
	navigate("harbor")


func _add_favorite_bait_discovery(catch_result: Dictionary) -> void:
	var fish_id := String(_current_fish.get("id", ""))
	if fish_id.is_empty() or fish_id == "megalodon":
		return
	if not bool(_current_fish.get("shark", false)):
		return
	var lure_fish := _trip_shark_lure_fish_data()
	if lure_fish.is_empty():
		return
	if not GameData.is_favorite_food(fish_id, lure_fish):
		return
	var shark_name := String(_current_fish.get("name", fish_id))
	var lure_fish_id := String(lure_fish.get("id", ""))
	var lure_name := String(
		_trip_stats.get("shark_lure_fish_name", lure_fish.get("name", lure_fish_id))
	).strip_edges()
	if lure_name.is_empty():
		lure_name = lure_fish_id
	catch_result["favorite_bait_discovery_text"] = "%sは%sが大好物みたいだ！" % [shark_name, lure_name]


func _retry() -> void:
	_prepare_new_attempt()


func _update_ui() -> void:
	if _simulator == null:
		return
	_update_fight_hud_height()
	var message := _simulator.action_message
	if _trip_event_message_timer > 0.0 and not _trip_event_message.is_empty():
		message = _trip_event_message
	elif _simulator.state == FishingSimulator.State.READY and _should_show_nushi_omen():
		message = "……ヌシの気配がする。"
	_set_message_text(message)

	var show_fight_overlay := _should_show_floating_fight_card()
	var show_spot_panel := _simulator.state == FishingSimulator.State.READY
	if _info_panel != null:
		_info_panel.visible = _simulator.state == FishingSimulator.State.READY
	if _fight_floating_card != null:
		_fight_floating_card.visible = show_fight_overlay
	if _info_title_label != null:
		_info_title_label.visible = show_spot_panel
	if _spot_panel != null:
		_spot_panel.visible = show_spot_panel


func _update_fight_hud_height() -> void:
	if _fight_hud == null or _simulator == null:
		return
	var target_height := FightHudScript.DEFAULT_HUD_HEIGHT
	if _should_use_slim_hud():
		target_height = FightHudScript.FIGHT_SLIM_HUD_HEIGHT
	if is_equal_approx(_fight_hud.custom_minimum_size.y, target_height):
		return
	_fight_hud.custom_minimum_size = Vector2(0.0, target_height)
	_fight_hud.queue_redraw()


func _should_use_slim_hud() -> bool:
	if _simulator == null:
		return false
	return _should_show_floating_fight_card()


func _should_show_floating_fight_card() -> bool:
	if _simulator == null:
		return false
	return (
		_simulator.state == FishingSimulator.State.CASTING
		or _simulator.state == FishingSimulator.State.WAITING
		or _simulator.state == FishingSimulator.State.APPROACH
		or _simulator.state == FishingSimulator.State.BITE
		or _simulator.state == FishingSimulator.State.FIGHT
	)


func _set_message_text(message: String) -> void:
	if _message_label == null:
		return
	_message_label.text = message
	if _message_panel != null:
		var has_text := not message.strip_edges().is_empty()
		var show_message := has_text
		if _simulator != null:
			var trip_event_active := (
				_trip_event_message_timer > 0.0
				and not _trip_event_message.is_empty()
				and message == _trip_event_message
			)
			var ready_nushi_omen := _simulator.state == FishingSimulator.State.READY and message == "……ヌシの気配がする。"
			show_message = has_text and (
				_simulator.state != FishingSimulator.State.READY
				or ready_nushi_omen
				or trip_event_active
			)
			if (
				_simulator.state == FishingSimulator.State.CASTING
				or _simulator.state == FishingSimulator.State.WAITING
			):
				show_message = has_text and trip_event_active
			elif (
				_simulator.state == FishingSimulator.State.APPROACH
				or _simulator.state == FishingSimulator.State.BITE
				or _simulator.state == FishingSimulator.State.FIGHT
			):
				show_message = false
		_message_panel.visible = show_message


func _roll_and_apply_trip_event() -> void:
	var event := GameData.roll_trip_event(_trip_fired_event_ids())
	var event_id := String(event.get("id", "none"))
	if event_id == "none":
		return
	var fired := _trip_fired_event_ids()
	fired.append(event_id)
	_trip_stats["trip_fired_event_ids"] = fired
	match event_id:
		"bird_swarm":
			_trip_stats["bird_swarm_hits_remaining"] = int(event.get("hits_remaining", 0))
			if _surface_view != null:
				_surface_view.play_bird_swarm()
			_show_trip_event_message(String(event.get("message", "")))
		"driftwood":
			_apply_driftwood_event()
		"bottle_mail":
			_apply_bottle_mail_event(event)


func _apply_driftwood_event() -> void:
	var outcome := GameData.roll_driftwood_outcome()
	var money := int(outcome.get("money", 0))
	if money > 0:
		PlayerProgress.gain_trip_event_money(money)
	_show_trip_event_message(String(outcome.get("message", "")))


func _apply_bottle_mail_event(event: Dictionary) -> void:
	var fragment_max := int(event.get("fragment_max", PlayerProgress.SEA_CHART_FRAGMENT_MAX))
	var gained := PlayerProgress.gain_trip_event_sea_chart_fragment()
	var message := ""
	if gained > 0:
		var after := PlayerProgress.sea_chart_fragments
		if after >= fragment_max:
			message = String(event.get("complete_message", ""))
		else:
			message = String(event.get("fragment_message", "")).replace("{n}", str(after))
	else:
		var money := int(event.get("fallback_money", 0))
		if money > 0:
			PlayerProgress.gain_trip_event_money(money)
		message = String(event.get("fallback_message", "")).replace("{money}", str(money))
		if message.strip_edges().is_empty() and money > 0:
			message = "+%d G" % money
	_show_trip_event_message(message)


func _show_trip_event_message(text: String, duration: float = TRIP_EVENT_MESSAGE_DURATION) -> void:
	var trimmed := text.strip_edges()
	if trimmed.is_empty():
		return
	_trip_event_message = trimmed
	_trip_event_message_timer = maxf(duration, 0.1)
	_set_message_text(trimmed)


func _should_show_nushi_omen() -> bool:
	if _nushi_omen_shown:
		return false
	if bool(_spot.get("boss_spot", false)):
		return false
	return not GameData.nushi_candidate(
		_spot_id,
		String(_trip_stats.get("environment_id", GameData.DEFAULT_FISHING_ENVIRONMENT_ID)),
		String(_trip_stats.get("rig_id", PlayerProgress.equipped_rig_id)),
		String(_trip_stats.get("time_slot_id", "")),
		PlayerProgress.level
	).is_empty()


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


class FishingTimeSlotVignette extends Control:
	const VIGNETTE_IMAGE_SIZE := Vector2i(96, 54)
	# 縁からこの割合（min辺基準）までを減光域とする。旧帯状実装の max_span と同じ値。
	const VIGNETTE_EDGE_SPAN_RATIO := 0.40

	var grade: String = "none":
		set(value):
			grade = value
			_vignette_texture = null
			queue_redraw()

	var _vignette_texture: ImageTexture

	func _draw() -> void:
		var tint := Color.WHITE
		var strength := 0.0
		match grade:
			"warm":
				tint = Palette.FISHING_TIME_VIGNETTE_WARM
				strength = Palette.FISHING_TIME_VIGNETTE_WARM_STRENGTH
			"cool":
				tint = Palette.FISHING_TIME_VIGNETTE_COOL
				strength = Palette.FISHING_TIME_VIGNETTE_COOL_STRENGTH
			_:
				return
		if strength <= 0.0 or size.x <= 0.0 or size.y <= 0.0:
			return
		if _vignette_texture == null:
			_vignette_texture = _build_vignette_texture(tint, strength)
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		draw_texture_rect(_vignette_texture, Rect2(Vector2.ZERO, size), false)

	# 低解像度Imageへ per-pixel でビネット alpha（縁からの距離の2乗カーブ）を書き込み、
	# linear filter の拡大描画で滑らかなグラデーションにする（PNGは追加しない）。
	static func _build_vignette_texture(tint: Color, strength: float) -> ImageTexture:
		var width := VIGNETTE_IMAGE_SIZE.x
		var height := VIGNETTE_IMAGE_SIZE.y
		var span := float(mini(width, height)) * VIGNETTE_EDGE_SPAN_RATIO
		var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
		for y in range(height):
			var edge_y := minf(float(y) + 0.5, float(height) - (float(y) + 0.5))
			var ty := clampf(1.0 - edge_y / span, 0.0, 1.0)
			var falloff_y := ty * ty
			for x in range(width):
				var edge_x := minf(float(x) + 0.5, float(width) - (float(x) + 0.5))
				var tx := clampf(1.0 - edge_x / span, 0.0, 1.0)
				var falloff_x := tx * tx
				# 辺では単軸の2乗カーブ、四隅では両軸が合成されて濃くなる
				var falloff := 1.0 - (1.0 - falloff_x) * (1.0 - falloff_y)
				image.set_pixel(x, y, Color(tint.r, tint.g, tint.b, strength * falloff))
		return ImageTexture.create_from_image(image)
