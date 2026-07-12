class_name SettingsScreen
extends ScreenBase

const SETTINGS_PATH := "user://settings.json"
const SETTINGS_VERSION := 1
const DEFAULT_BGM_VOLUME := 80
const DEFAULT_SE_VOLUME := 80
const BGM_BUS := &"BGM"
const SE_BUS := &"SE"
const COMMON_PANEL_PATH := "res://assets/showcase/common/card_frame.png"
const COMMON_BUTTON_PATH := "res://assets/showcase/common/action_button_frame.png"

var _bgm_slider: HSlider
var _se_slider: HSlider
var _bgm_value_label: Label
var _se_value_label: Label
var _return_button: Button
var _return_screen_id := "title"
var _loading := false


func _build_screen() -> void:
	_return_screen_id = String(route_payload.get("return_screen_id", "title"))
	if _return_screen_id != "title" and _return_screen_id != "harbor":
		_return_screen_id = "title"
	add_gradient_background(Palette.SEA_DEEP, Palette.SCREEN_BG_DEFAULT)
	var scrim := ColorRect.new()
	scrim.color = Palette.DARK_PANEL_DEEP
	scrim.color.a = 0.52
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)

	var title := make_screen_label("せってい", 36, Palette.GOLD_BRIGHT, true, 3, Palette.TEXT_OUTLINE_DARK)
	title.name = "SettingsTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(title, Rect2(360.0, 42.0, 560.0, 56.0))
	var subtitle := make_screen_label("音の大きさを調整できます", 18, Palette.TEXT_BONE, false, 2, Palette.TEXT_OUTLINE_DARK)
	subtitle.name = "SettingsSubtitle"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(subtitle, Rect2(360.0, 98.0, 560.0, 36.0))

	var panel := NinePatchRect.new()
	panel.name = "SettingsAudioPanel"
	panel.texture = load(COMMON_PANEL_PATH)
	panel.patch_margin_left = 46
	panel.patch_margin_top = 40
	panel.patch_margin_right = 46
	panel.patch_margin_bottom = 40
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place(panel, Rect2(220.0, 168.0, 840.0, 360.0))

	var heading := make_screen_label("サウンド", 26, Palette.TEXT_BONE, true, 2, Palette.TEXT_OUTLINE_DARK)
	heading.name = "SettingsAudioHeading"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_in(panel, heading, Rect2(70.0, 42.0, 700.0, 44.0))
	_bgm_slider = _build_volume_row(panel, "BGM音量", 108.0, BGM_BUS)
	_bgm_value_label = panel.get_node("BGM_Value") as Label
	_se_slider = _build_volume_row(panel, "SE音量", 210.0, SE_BUS)
	_se_value_label = panel.get_node("SE_Value") as Label

	var hint := make_screen_label("↑↓ 項目を選ぶ　←→ 音量を変える　Esc / B 戻る", 16, Palette.TEXT_BONE, false, 2, Palette.TEXT_OUTLINE_DARK)
	hint.name = "SettingsInputHint"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place(hint, Rect2(84.0, 626.0, 720.0, 50.0))
	_return_button = make_return_button(_return_to_origin, 220.0)
	_return_button.name = "SettingsReturnButton"
	_return_button.text = "タイトルへ戻る" if _return_screen_id == "title" else "港へ戻る"
	_return_button.custom_minimum_size = Vector2.ZERO
	_place(_return_button, Rect2(920.0, 616.0, 276.0, 60.0))
	_wire_focus()
	_apply_loaded_settings()
	_bgm_slider.call_deferred("grab_focus")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_return_to_origin()


func _build_volume_row(parent: Control, caption: String, y: float, bus_name: StringName) -> HSlider:
	var prefix := "BGM" if bus_name == BGM_BUS else "SE"
	var label := make_screen_label(caption, 22, Palette.TEXT_BONE, true, 2, Palette.TEXT_OUTLINE_DARK)
	label.name = "%s_Label" % prefix
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_in(parent, label, Rect2(72.0, y, 190.0, 58.0))
	var slider := HSlider.new()
	slider.name = "%s_Slider" % prefix
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 5.0
	slider.custom_minimum_size = Vector2.ZERO
	slider.focus_mode = Control.FOCUS_ALL
	slider.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	slider.value_changed.connect(_on_volume_changed.bind(bus_name))
	_place_in(parent, slider, Rect2(262.0, y + 5.0, 390.0, 48.0))
	var value_label := make_screen_label("100%", 22, Palette.TEXT_BONE, true, 2, Palette.TEXT_OUTLINE_DARK)
	value_label.name = "%s_Value" % prefix
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_in(parent, value_label, Rect2(672.0, y, 96.0, 58.0))
	return slider


func _wire_focus() -> void:
	_bgm_slider.focus_neighbor_bottom = _bgm_slider.get_path_to(_se_slider)
	_se_slider.focus_neighbor_top = _se_slider.get_path_to(_bgm_slider)
	_se_slider.focus_neighbor_bottom = _se_slider.get_path_to(_return_button)
	_return_button.focus_neighbor_top = _return_button.get_path_to(_se_slider)


func _apply_loaded_settings() -> void:
	_loading = true
	var settings := load_settings()
	_bgm_slider.value = int(settings["bgm_volume"])
	_se_slider.value = int(settings["se_volume"])
	_update_value_label(BGM_BUS, _bgm_slider.value)
	_update_value_label(SE_BUS, _se_slider.value)
	apply_to_audio_buses(settings)
	_loading = false


func _on_volume_changed(value: float, bus_name: StringName) -> void:
	_update_value_label(bus_name, value)
	_set_bus_volume(bus_name, value)
	if _loading:
		return
	save_settings({
		"version": SETTINGS_VERSION,
		"bgm_volume": int(round(_bgm_slider.value)),
		"se_volume": int(round(_se_slider.value)),
	})


func _update_value_label(bus_name: StringName, value: float) -> void:
	var label := _bgm_value_label if bus_name == BGM_BUS else _se_value_label
	if label != null:
		label.text = "%d%%" % int(round(value))


func _return_to_origin() -> void:
	navigate(_return_screen_id)


func _place(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size
	add_child(control)


func _place_in(parent: Control, control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size
	parent.add_child(control)


static func default_settings() -> Dictionary:
	return {
		"version": SETTINGS_VERSION,
		"bgm_volume": DEFAULT_BGM_VOLUME,
		"se_volume": DEFAULT_SE_VOLUME,
	}


static func load_settings() -> Dictionary:
	var defaults := default_settings()
	if not FileAccess.file_exists(SETTINGS_PATH):
		save_settings(defaults)
		return defaults
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return defaults
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		save_settings(defaults)
		return defaults
	var parsed: Variant = json.data
	if not parsed is Dictionary:
		save_settings(defaults)
		return defaults
	var source: Dictionary = parsed
	var normalized := default_settings()
	var valid := true
	for key in ["bgm_volume", "se_volume"]:
		var value: Variant = source.get(key, null)
		if not (value is int or value is float):
			valid = false
			continue
		var number := float(value)
		if not is_finite(number) or number < 0.0 or number > 100.0:
			valid = false
			continue
		normalized[key] = int(round(number))
	var version_value: Variant = source.get("version", null)
	if not (version_value is int or version_value is float):
		valid = false
	else:
		var version_number := float(version_value)
		if not is_finite(version_number) or not is_equal_approx(version_number, round(version_number)) or int(version_number) != SETTINGS_VERSION:
			valid = false
	if not valid:
		save_settings(defaults)
		return defaults
	if source.size() != normalized.size():
		save_settings(normalized)
	return normalized


static func save_settings(settings: Dictionary) -> bool:
	var normalized := default_settings()
	normalized["bgm_volume"] = clampi(int(settings.get("bgm_volume", DEFAULT_BGM_VOLUME)), 0, 100)
	normalized["se_volume"] = clampi(int(settings.get("se_volume", DEFAULT_SE_VOLUME)), 0, 100)
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("設定を保存できません: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(normalized, "\t"))
	return true


static func apply_to_audio_buses(settings: Dictionary) -> void:
	_set_bus_volume(BGM_BUS, float(settings.get("bgm_volume", DEFAULT_BGM_VOLUME)))
	_set_bus_volume(SE_BUS, float(settings.get("se_volume", DEFAULT_SE_VOLUME)))


static func _set_bus_volume(bus_name: StringName, percent: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	var normalized := clampf(percent, 0.0, 100.0) / 100.0
	AudioServer.set_bus_mute(index, normalized <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(normalized) if normalized > 0.0 else -80.0)
