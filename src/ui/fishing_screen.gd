extends "res://src/ui/screen_base.gd"

const FishingSimulatorScript = preload("res://src/core/fishing_simulator.gd")
const UnderwaterViewScript = preload("res://src/ui/components/underwater_view.gd")

var _simulator
var _trip_stats: Dictionary = {}
var _current_fish: Dictionary = {}
var _result_recorded: bool = false

var _target_option: OptionButton
var _main_action_button: Button
var _reel_button: Button
var _give_button: Button
var _message_label: Label
var _state_label: Label
var _fish_info_label: Label
var _tension_bar: ProgressBar
var _fish_stamina_bar: ProgressBar
var _player_energy_bar: ProgressBar
var _distance_label: Label
var _safe_zone_label: Label
var _view

var _result_overlay: ColorRect
var _result_title: Label
var _result_details: Label
var _retry_button: Button


func _build_screen() -> void:
	add_background(Color("#061627"))
	_trip_stats = PlayerProgress.begin_fishing_trip()
	_simulator = FishingSimulatorScript.new()
	_simulator.state_changed.connect(_on_state_changed)
	_simulator.message_changed.connect(_on_message_changed)
	_simulator.fight_finished.connect(_on_fight_finished)

	var root := make_root_margin(12)
	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 10)
	root.add_child(layout)

	var meal_text := "食事効果なし"
	if not Dictionary(_trip_stats.get("meal_buff", {})).is_empty():
		var meal_buff: Dictionary = _trip_stats["meal_buff"]
		meal_text = (
			"%s：%s" % [String(meal_buff.get("name", "料理")), String(meal_buff.get("text", ""))]
		)
	layout.add_child(
		make_header(
			"南の島・沖　水中ファイト",
			(
				"Lv.%d　%s　｜　%s"
				% [PlayerProgress.level, String(_trip_stats.get("rod_name", "入門竿")), meal_text]
			)
		)
	)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	layout.add_child(body)

	var left_column := VBoxContainer.new()
	left_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_column.size_flags_stretch_ratio = 1.55
	left_column.add_theme_constant_override("separation", 8)
	body.add_child(left_column)

	var water_panel := make_panel(true)
	water_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	water_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_column.add_child(water_panel)
	_view = UnderwaterViewScript.new()
	_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	water_panel.add_child(_view)

	var message_panel := make_panel(true)
	message_panel.custom_minimum_size = Vector2(0, 60)
	left_column.add_child(message_panel)
	_message_label = make_label("", 21, Color("#fff0b5"))
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_panel.add_child(_message_label)

	var info_panel := make_panel()
	info_panel.custom_minimum_size = Vector2(335, 0)
	info_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(info_panel)
	var info_box := VBoxContainer.new()
	info_box.add_theme_constant_override("separation", 10)
	info_panel.add_child(info_box)
	var info_title := make_label("狙う魚", 27)
	info_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_box.add_child(info_title)

	_target_option = OptionButton.new()
	_target_option.custom_minimum_size = Vector2(300, 48)
	_target_option.add_item("通常魚を狙う", 0)
	_target_option.add_item("港のぬしを狙う（Lv.5〜）", 1)
	if PlayerProgress.level < GameData.BOSS_UNLOCK_LEVEL:
		_target_option.get_popup().set_item_disabled(1, true)
	_target_option.item_selected.connect(_on_target_mode_changed)
	info_box.add_child(_target_option)

	_fish_info_label = make_label("", 18)
	_fish_info_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info_box.add_child(_fish_info_label)

	var separator := HSeparator.new()
	info_box.add_child(separator)
	_state_label = make_label("状態：準備", 20)
	info_box.add_child(_state_label)
	_distance_label = make_label("距離：-- m　水深：-- m", 18)
	info_box.add_child(_distance_label)
	_safe_zone_label = make_label("安全域：--", 17)
	info_box.add_child(_safe_zone_label)
	var back_button := make_button("港へ戻る", func() -> void: navigate("harbor"), 300)
	info_box.add_child(back_button)

	var hud := make_panel(true)
	hud.custom_minimum_size = Vector2(0, 140)
	layout.add_child(hud)
	var hud_box := VBoxContainer.new()
	hud_box.add_theme_constant_override("separation", 7)
	hud.add_child(hud_box)

	var gauge_row := HBoxContainer.new()
	gauge_row.add_theme_constant_override("separation", 18)
	hud_box.add_child(gauge_row)
	var tension_column := _make_gauge_column("テンション")
	_tension_bar = tension_column["bar"]
	gauge_row.add_child(tension_column["root"])
	var fish_column := _make_gauge_column("魚の体力")
	_fish_stamina_bar = fish_column["bar"]
	gauge_row.add_child(fish_column["root"])
	var energy_column := _make_gauge_column("プレイヤー体力")
	_player_energy_bar = energy_column["bar"]
	gauge_row.add_child(energy_column["root"])

	var control_row := HBoxContainer.new()
	control_row.alignment = BoxContainer.ALIGNMENT_CENTER
	control_row.add_theme_constant_override("separation", 12)
	hud_box.add_child(control_row)
	_main_action_button = make_button("仕掛けを投げる", _on_main_action_pressed, 245)
	control_row.add_child(_main_action_button)
	_reel_button = make_button("巻く［Space］", func() -> void: pass, 210)
	_reel_button.button_down.connect(func() -> void: _simulator.set_reeling(true))
	_reel_button.button_up.connect(func() -> void: _simulator.set_reeling(false))
	_reel_button.mouse_exited.connect(func() -> void: _simulator.set_reeling(false))
	control_row.add_child(_reel_button)
	_give_button = make_button("糸を出す［Shift］", func() -> void: pass, 225)
	_give_button.button_down.connect(func() -> void: _simulator.set_giving_line(true))
	_give_button.button_up.connect(func() -> void: _simulator.set_giving_line(false))
	_give_button.mouse_exited.connect(func() -> void: _simulator.set_giving_line(false))
	control_row.add_child(_give_button)

	_create_result_overlay()
	_prepare_new_attempt()
	_update_ui()


func _make_gauge_column(title: String) -> Dictionary:
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := make_label(title, 17, Color("#eaf5ff"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(label)
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 100.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(260, 30)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(bar)
	return {"root": root, "bar": bar}


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
	panel.custom_minimum_size = Vector2(650, 360)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	_result_title = make_label("", 40, Color("#7b431e"))
	_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_result_title)
	_result_details = make_label("", 21)
	_result_details.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_result_details)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	box.add_child(row)
	_retry_button = make_button("もう一度挑戦", _retry, 230)
	row.add_child(_retry_button)
	row.add_child(make_button("港へ戻る", func() -> void: navigate("harbor"), 230))


func _process(delta: float) -> void:
	if _simulator == null:
		return
	_simulator.tick(delta)
	_update_ui()


func _input(event: InputEvent) -> void:
	if _simulator == null or not event is InputEventKey:
		return
	var key_event := event as InputEventKey
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


func _on_target_mode_changed(_index: int) -> void:
	_prepare_new_attempt()


func _prepare_new_attempt() -> void:
	_result_recorded = false
	_result_overlay.visible = false
	if _target_option.selected == 1 and PlayerProgress.level >= GameData.BOSS_UNLOCK_LEVEL:
		_current_fish = GameData.get_fish("boss_kurodai")
	else:
		_current_fish = GameData.roll_normal_fish(PlayerProgress.level)
	_simulator.prepare(_current_fish, _trip_stats)
	_view.bind_simulator(_simulator)
	_refresh_fish_info()


func _refresh_fish_info() -> void:
	_fish_info_label.text = (
		"[ %s ]\n%s\n\n生息域：%s\n\n特徴：%s\n\n推定サイズ：%.0f〜%.0f cm\n売値：%d G"
		% [
			String(_current_fish.get("rarity", "")),
			String(_current_fish.get("name", "不明な魚")),
			String(_current_fish.get("habitat", "不明")),
			String(_current_fish.get("behavior", "")),
			float(_current_fish.get("size_min", 0.0)),
			float(_current_fish.get("size_max", 0.0)),
			int(_current_fish.get("sell_price", 0)),
		]
	)


func _on_main_action_pressed() -> void:
	match _simulator.state:
		FishingSimulator.State.READY:
			_simulator.cast()
		FishingSimulator.State.BITE:
			_simulator.hook()


func _on_state_changed(_new_state: int) -> void:
	_update_ui()


func _on_message_changed(message: String) -> void:
	_message_label.text = message


func _on_fight_finished(caught: bool, reason: String) -> void:
	if caught:
		if not _result_recorded:
			PlayerProgress.record_catch(String(_current_fish["id"]), _simulator.result_size_cm)
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
	_message_label.text = _simulator.action_message
	_state_label.text = "状態：%s　｜　行動：%s" % [_simulator.state_label(), _simulator.action_name]
	_distance_label.text = "距離：%.1f m　｜　水深：%.1f m" % [_simulator.distance, _simulator.depth]
	_safe_zone_label.text = (
		"安全テンション域：%d〜%d%%　切断限界：%d%%"
		% [
			int(round(_simulator.safe_min() * 100.0)),
			int(round(_simulator.safe_max() * 100.0)),
			int(round(_simulator.line_break_limit() * 100.0)),
		]
	)
	_tension_bar.value = clampf(
		_simulator.tension / _simulator.line_break_limit() * 100.0, 0.0, 100.0
	)
	_fish_stamina_bar.value = _simulator.fish_stamina_ratio() * 100.0
	_player_energy_bar.value = _simulator.player_energy_ratio() * 100.0

	var fighting: bool= _simulator.state == FishingSimulator.State.FIGHT
	_reel_button.disabled = not fighting
	_give_button.disabled = not fighting
	_target_option.disabled = _simulator.state != FishingSimulator.State.READY
	match _simulator.state:
		FishingSimulator.State.READY:
			_main_action_button.text = "仕掛けを投げる［Enter］"
			_main_action_button.disabled = false
		FishingSimulator.State.BITE:
			_main_action_button.text = "今だ！ アワセる［E］"
			_main_action_button.disabled = false
		_:
			_main_action_button.text = "ファイト中" if fighting else "魚を待っています"
			_main_action_button.disabled = true
