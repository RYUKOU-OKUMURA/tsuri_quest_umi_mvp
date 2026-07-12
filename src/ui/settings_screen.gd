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
var _fullscreen_button: Button
var _return_button: Button
var _delete_button: Button
var _delete_summary_label: Label
var _delete_status_label: Label
var _delete_modal_layer: Control
var _delete_confirm_panel: Control
var _delete_final_panel: Control
var _delete_modal_title: Label
var _delete_confirm_detail: Label
var _delete_final_detail: Label
var _delete_continue_button: Button
var _delete_confirm_cancel_button: Button
var _delete_commit_button: Button
var _delete_final_cancel_button: Button
var _return_screen_id := "title"
var _target_slot_id := PlayerProgress.DEFAULT_SAVE_SLOT
var _delete_stage := 0
var _delete_api_call_count := 0
var _loading := false
var _fullscreen := false
static var _last_display_fullscreen := false


func _build_screen() -> void:
	_return_screen_id = String(route_payload.get("return_screen_id", "title"))
	if _return_screen_id != "title" and _return_screen_id != "harbor":
		_return_screen_id = "title"
	_target_slot_id = _resolve_target_slot_id()
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
	_place(panel, Rect2(180.0, 144.0, 920.0, 430.0))

	var heading := make_screen_label("サウンド", 26, Palette.TEXT_BONE, true, 2, Palette.TEXT_OUTLINE_DARK)
	heading.name = "SettingsAudioHeading"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_in(panel, heading, Rect2(70.0, 28.0, 420.0, 40.0))
	_build_fullscreen_toggle(panel)
	_bgm_slider = _build_volume_row(panel, "BGM音量", 72.0, BGM_BUS)
	_bgm_value_label = panel.get_node("BGM_Value") as Label
	_se_slider = _build_volume_row(panel, "SE音量", 142.0, SE_BUS)
	_se_value_label = panel.get_node("SE_Value") as Label
	_build_delete_block(panel)

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
	_build_delete_modals()
	_wire_focus()
	_apply_loaded_settings()
	_refresh_delete_summary()
	_bgm_slider.call_deferred("grab_focus")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _delete_stage == 2:
			_show_delete_confirm()
		elif _delete_stage == 1:
			_close_delete_modals()
		else:
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


func _build_fullscreen_toggle(parent: Control) -> void:
	_fullscreen_button = make_button("フルスクリーン: オフ", _toggle_fullscreen, 0.0, false)
	_fullscreen_button.name = "SettingsFullscreenButton"
	_fullscreen_button.custom_minimum_size = Vector2.ZERO
	_fullscreen_button.focus_mode = Control.FOCUS_ALL
	var button_style := ShowcaseAssetsScript.texture_style(
		COMMON_BUTTON_PATH,
		Vector4(46.0, 24.0, 46.0, 24.0),
		Vector4(16.0, 8.0, 16.0, 8.0)
	)
	if button_style != null:
		_fullscreen_button.add_theme_stylebox_override("normal", button_style)
		_fullscreen_button.add_theme_stylebox_override("hover", button_style)
		_fullscreen_button.add_theme_stylebox_override("pressed", button_style)
		_fullscreen_button.add_theme_stylebox_override("focus", button_style)
	_fullscreen_button.add_theme_color_override("font_color", Palette.TEXT_BONE)
	_fullscreen_button.add_theme_color_override("font_hover_color", Palette.GOLD_BRIGHT)
	_fullscreen_button.add_theme_color_override("font_pressed_color", Palette.GOLD_BRIGHT)
	_fullscreen_button.add_theme_color_override("font_focus_color", Palette.GOLD_BRIGHT)
	_fullscreen_button.add_theme_color_override("font_outline_color", Palette.TEXT_OUTLINE_DARK)
	_fullscreen_button.add_theme_constant_override("outline_size", 2)
	_fullscreen_button.mouse_entered.connect(_on_fullscreen_hover.bind(true))
	_fullscreen_button.mouse_exited.connect(_on_fullscreen_hover.bind(false))
	_fullscreen_button.button_down.connect(_on_fullscreen_pressed.bind(true))
	_fullscreen_button.button_up.connect(_on_fullscreen_pressed.bind(false))
	_fullscreen_button.focus_entered.connect(_on_fullscreen_focus.bind(true))
	_fullscreen_button.focus_exited.connect(_on_fullscreen_focus.bind(false))
	_place_in(parent, _fullscreen_button, Rect2(500.0, 10.0, 350.0, 58.0))


func _wire_focus() -> void:
	_bgm_slider.focus_neighbor_bottom = _bgm_slider.get_path_to(_se_slider)
	_se_slider.focus_neighbor_top = _se_slider.get_path_to(_bgm_slider)
	_se_slider.focus_neighbor_bottom = _se_slider.get_path_to(_fullscreen_button)
	_fullscreen_button.focus_neighbor_top = _fullscreen_button.get_path_to(_se_slider)
	_fullscreen_button.focus_neighbor_bottom = _fullscreen_button.get_path_to(_delete_button)
	_delete_button.focus_neighbor_top = _delete_button.get_path_to(_fullscreen_button)
	_delete_button.focus_neighbor_bottom = _delete_button.get_path_to(_return_button)
	_return_button.focus_neighbor_top = _return_button.get_path_to(_delete_button)


func _build_delete_block(parent: Control) -> void:
	var heading := make_screen_label("セーブデータ", 24, Palette.TEXT_BONE, true, 2, Palette.TEXT_OUTLINE_DARK)
	heading.name = "SettingsSlotDeleteHeading"
	_place_in(parent, heading, Rect2(70.0, 215.0, 260.0, 38.0))
	_delete_summary_label = make_screen_label("", 19, Palette.TEXT_BONE, true, 2, Palette.TEXT_OUTLINE_DARK)
	_delete_summary_label.name = "SettingsSlotDeleteSummary"
	_delete_summary_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_in(parent, _delete_summary_label, Rect2(72.0, 252.0, 520.0, 52.0))
	_delete_button = make_button("このスロットを削除", _show_delete_confirm, 260)
	_delete_button.name = "SettingsSlotDeleteButton"
	_delete_button.custom_minimum_size = Vector2.ZERO
	_place_in(parent, _delete_button, Rect2(610.0, 250.0, 240.0, 58.0))
	_delete_status_label = make_screen_label("", 15, Palette.TEXT_BONE, false, 2, Palette.TEXT_OUTLINE_DARK)
	_delete_status_label.name = "SettingsSlotDeleteStatus"
	_delete_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_delete_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place_in(parent, _delete_status_label, Rect2(72.0, 350.0, 778.0, 48.0))


func _build_delete_modals() -> void:
	_delete_modal_layer = Control.new()
	_delete_modal_layer.name = "SettingsSlotDeleteModalLayer"
	_delete_modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_delete_modal_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_delete_modal_layer.visible = false
	add_child(_delete_modal_layer)
	var scrim := ColorRect.new()
	scrim.color = Palette.DARK_PANEL_DEEP
	scrim.color.a = 0.82
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	_delete_modal_layer.add_child(scrim)
	_delete_confirm_panel = _make_delete_modal_panel("SettingsSlotDeleteConfirm1")
	_delete_final_panel = _delete_confirm_panel
	_delete_modal_title = make_screen_label("セーブデータを削除しますか？", 28, Palette.GOLD_BRIGHT, true, 3, Palette.TEXT_OUTLINE_DARK)
	_delete_modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_delete_modal_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_in(_delete_confirm_panel, _delete_modal_title, Rect2(70.0, 40.0, 600.0, 54.0))
	_delete_confirm_detail = _make_delete_modal_content(_delete_confirm_panel)
	_delete_continue_button = make_button("内容を確認する", _show_delete_final, 280)
	_delete_continue_button.name = "SettingsSlotDeleteContinue"
	_delete_continue_button.custom_minimum_size = Vector2.ZERO
	_place_in(_delete_confirm_panel, _delete_continue_button, Rect2(365.0, 330.0, 280.0, 62.0))
	_delete_confirm_cancel_button = make_button("やめる", _close_delete_modals, 240, true)
	_delete_confirm_cancel_button.name = "SettingsSlotDeleteCancel1"
	_delete_confirm_cancel_button.custom_minimum_size = Vector2.ZERO
	_place_in(_delete_confirm_panel, _delete_confirm_cancel_button, Rect2(95.0, 330.0, 240.0, 62.0))
	_delete_final_detail = _make_delete_modal_content(_delete_final_panel)
	_delete_final_detail.visible = false
	_delete_commit_button = make_button("削除する", _commit_delete, 240)
	_delete_commit_button.name = "SettingsSlotDeleteCommit"
	_delete_commit_button.custom_minimum_size = Vector2.ZERO
	_delete_commit_button.visible = false
	_place_in(_delete_final_panel, _delete_commit_button, Rect2(405.0, 330.0, 240.0, 62.0))
	_delete_final_cancel_button = make_button("確認1へ戻る", _show_delete_confirm, 280, true)
	_delete_final_cancel_button.name = "SettingsSlotDeleteCancel2"
	_delete_final_cancel_button.custom_minimum_size = Vector2.ZERO
	_delete_final_cancel_button.visible = false
	_place_in(_delete_final_panel, _delete_final_cancel_button, Rect2(95.0, 330.0, 280.0, 62.0))


func _make_delete_modal_panel(node_name: String) -> NinePatchRect:
	var panel := NinePatchRect.new()
	panel.name = node_name
	panel.texture = load(COMMON_PANEL_PATH)
	panel.patch_margin_left = 46
	panel.patch_margin_top = 40
	panel.patch_margin_right = 46
	panel.patch_margin_bottom = 40
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_place_in(_delete_modal_layer, panel, Rect2(270.0, 130.0, 740.0, 460.0))
	return panel


func _make_delete_modal_content(panel: Control) -> Label:
	var detail := make_screen_label("", 20, Palette.TEXT_BONE, true, 2, Palette.TEXT_OUTLINE_DARK)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place_in(panel, detail, Rect2(72.0, 102.0, 596.0, 210.0))
	return detail


func _resolve_target_slot_id() -> int:
	var fallback := PlayerProgress.active_save_slot
	if _return_screen_id == "title":
		fallback = PlayerProgress.DEFAULT_SAVE_SLOT
		var payload_value: Variant = route_payload.get("target_slot_id", fallback)
		if payload_value is int or payload_value is float:
			var number := float(payload_value)
			if (
				is_finite(number)
				and is_equal_approx(number, round(number))
				and int(number) >= 1
				and int(number) <= PlayerProgress.SAVE_SLOT_COUNT
			):
				fallback = int(number)
	if fallback < 1 or fallback > PlayerProgress.SAVE_SLOT_COUNT:
		fallback = PlayerProgress.DEFAULT_SAVE_SLOT
	return fallback


func _refresh_delete_summary(message := "") -> void:
	var summary := PlayerProgress.save_slot_summary(_target_slot_id)
	var artifact_status := PlayerProgress.save_slot_artifact_status(_target_slot_id)
	_delete_summary_label.text = _summary_line(summary)
	var storage_blocked := bool(summary.get("storage_blocked", false))
	var has_artifact := bool(artifact_status.get("any_artifact", false))
	_delete_button.disabled = storage_blocked or not has_artifact
	_delete_button.focus_mode = Control.FOCUS_NONE if _delete_button.disabled else Control.FOCUS_ALL
	if not _delete_button.disabled:
		_fullscreen_button.focus_neighbor_bottom = _fullscreen_button.get_path_to(_delete_button)
		_return_button.focus_neighbor_top = _return_button.get_path_to(_delete_button)
	else:
		_fullscreen_button.focus_neighbor_bottom = _fullscreen_button.get_path_to(_return_button)
		_return_button.focus_neighbor_top = _return_button.get_path_to(_fullscreen_button)
	if not message.is_empty():
		_delete_status_label.text = message
	elif storage_blocked:
		_delete_status_label.text = String(summary.get("storage_block_message", "セーブデータを確認できません。ゲームを再起動してください。"))
	elif not has_artifact:
		_delete_status_label.text = "このスロットは空です。削除するデータはありません。"
	elif bool(summary.get("future_guarded", false)):
		_delete_status_label.text = "新しい版のデータです。内容は読まずに削除できます。"
	elif bool(summary.get("invalid_artifact", false)):
		_delete_status_label.text = "読み込めないデータです。確認後に削除できます。"
	else:
		_delete_status_label.text = "削除すると元に戻せません。二段階で確認します。"


func _summary_line(summary: Dictionary) -> String:
	var level_text := "Lv.%d" % int(summary.get("level", 1))
	if bool(summary.get("future_guarded", false)) or bool(summary.get("invalid_artifact", false)):
		level_text = "Lv.不明"
	return "対象: スロット%d　%s　%s" % [
		_target_slot_id,
		level_text,
		_format_play_time(float(summary.get("play_seconds", 0.0))),
	]


func _format_play_time(seconds: float) -> String:
	var total_minutes := int(maxf(0.0, seconds) / 60.0)
	var hours := int(total_minutes / 60)
	var minutes := total_minutes % 60
	return "%d時間%02d分" % [hours, minutes] if hours > 0 else "%d分" % minutes


func _delete_detail(final_step: bool) -> String:
	var summary := PlayerProgress.save_slot_summary(_target_slot_id)
	var warning := "この操作は取り消せません。" if not final_step else "本当に削除します。元には戻せません。"
	return "%s\n\n%s" % [_summary_line(summary), warning]


func _show_delete_confirm() -> void:
	if _delete_button.disabled:
		return
	_delete_stage = 1
	_set_background_focus_enabled(false)
	_delete_modal_layer.visible = true
	_delete_modal_title.text = "セーブデータを削除しますか？"
	_delete_confirm_detail.visible = true
	_delete_continue_button.visible = true
	_delete_confirm_cancel_button.visible = true
	_delete_final_detail.visible = false
	_delete_commit_button.visible = false
	_delete_final_cancel_button.visible = false
	_delete_confirm_detail.text = _delete_detail(false)
	_delete_confirm_cancel_button.grab_focus()


func _show_delete_final() -> void:
	_delete_stage = 2
	_delete_modal_title.text = "最終確認"
	_delete_confirm_detail.visible = false
	_delete_continue_button.visible = false
	_delete_confirm_cancel_button.visible = false
	_delete_final_detail.visible = true
	_delete_commit_button.visible = true
	_delete_final_cancel_button.visible = true
	_delete_final_detail.text = _delete_detail(true)
	_delete_final_cancel_button.grab_focus()


func _close_delete_modals() -> void:
	_delete_stage = 0
	_delete_modal_layer.visible = false
	_set_background_focus_enabled(true)
	_delete_button.grab_focus()


func _set_background_focus_enabled(enabled: bool) -> void:
	var mode := Control.FOCUS_ALL if enabled else Control.FOCUS_NONE
	_bgm_slider.focus_mode = mode
	_se_slider.focus_mode = mode
	_fullscreen_button.focus_mode = mode
	_delete_button.focus_mode = mode if not _delete_button.disabled else Control.FOCUS_NONE
	_return_button.focus_mode = mode


func _commit_delete() -> void:
	_delete_api_call_count += 1
	var result := PlayerProgress.delete_save_slot(_target_slot_id)
	if bool(result.get("ok", false)):
		navigate("title")
		return
	_delete_stage = 0
	_delete_modal_layer.visible = false
	_set_background_focus_enabled(true)
	var message := String(result.get("message", "")).strip_edges()
	if message.is_empty():
		message = _delete_reason_message(String(result.get("reason", "unknown")))
	_refresh_delete_summary(message)
	_delete_button.grab_focus()


func _delete_reason_message(reason: String) -> String:
	match reason:
		"invalid_slot":
			return "削除するスロットを確認できませんでした。"
		"sandbox_mode":
			return "この環境ではセーブデータを削除できません。"
		"storage_blocked":
			return "セーブデータを確認できません。ゲームを再起動してください。"
		_:
			return "削除できませんでした（%s）。もう一度お試しください。" % reason


func _apply_loaded_settings() -> void:
	_loading = true
	var settings := load_settings()
	_bgm_slider.value = int(settings["bgm_volume"])
	_se_slider.value = int(settings["se_volume"])
	_fullscreen = bool(settings["fullscreen"])
	_refresh_fullscreen_button()
	_update_value_label(BGM_BUS, _bgm_slider.value)
	_update_value_label(SE_BUS, _se_slider.value)
	apply_to_audio_buses(settings)
	apply_display_settings(settings)
	_loading = false


func _on_volume_changed(value: float, bus_name: StringName) -> void:
	_update_value_label(bus_name, value)
	_set_bus_volume(bus_name, value)
	if _loading:
		return
	_persist_current_settings()


func _toggle_fullscreen() -> void:
	var previous := _fullscreen
	_fullscreen = not previous
	if not _persist_current_settings():
		_fullscreen = previous
		_refresh_fullscreen_button()
		return
	apply_display_settings({"fullscreen": _fullscreen})
	_refresh_fullscreen_button()


func _persist_current_settings() -> bool:
	return save_settings({
		"version": SETTINGS_VERSION,
		"bgm_volume": int(round(_bgm_slider.value)),
		"se_volume": int(round(_se_slider.value)),
		"fullscreen": _fullscreen,
	})


func _refresh_fullscreen_button() -> void:
	if _fullscreen_button == null:
		return
	_fullscreen_button.text = "フルスクリーン: オン" if _fullscreen else "フルスクリーン: オフ"


func _on_fullscreen_hover(active: bool) -> void:
	if _fullscreen_button == null or _fullscreen_button.has_focus():
		return
	_fullscreen_button.self_modulate = Palette.GOLD_BRIGHT if active else Palette.TACKLE_TAB_ACTIVE_MODULATE


func _on_fullscreen_pressed(active: bool) -> void:
	if _fullscreen_button == null or _fullscreen_button.has_focus():
		return
	_fullscreen_button.self_modulate = Palette.GOLD if active else Palette.TACKLE_TAB_ACTIVE_MODULATE


func _on_fullscreen_focus(active: bool) -> void:
	if _fullscreen_button == null:
		return
	_fullscreen_button.self_modulate = Palette.TEXT_BONE if active else Palette.TACKLE_TAB_ACTIVE_MODULATE


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
		"fullscreen": false,
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
	var fullscreen_value: Variant = source.get("fullscreen", false)
	if not fullscreen_value is bool:
		valid = false
	else:
		normalized["fullscreen"] = fullscreen_value
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
	if not _settings_match_normalized(source, normalized):
		save_settings(normalized)
	return normalized


static func _settings_match_normalized(source: Dictionary, normalized: Dictionary) -> bool:
	if source.size() != normalized.size():
		return false
	for key in normalized.keys():
		if not source.has(key):
			return false
		var source_value: Variant = source[key]
		var normalized_value: Variant = normalized[key]
		if normalized_value is bool:
			if not source_value is bool or source_value != normalized_value:
				return false
		elif normalized_value is int or normalized_value is float:
			if not (source_value is int or source_value is float) or not is_equal_approx(float(source_value), float(normalized_value)):
				return false
		elif source_value != normalized_value:
			return false
	return true


static func save_settings(settings: Dictionary) -> bool:
	var normalized := default_settings()
	normalized["bgm_volume"] = clampi(int(settings.get("bgm_volume", DEFAULT_BGM_VOLUME)), 0, 100)
	normalized["se_volume"] = clampi(int(settings.get("se_volume", DEFAULT_SE_VOLUME)), 0, 100)
	normalized["fullscreen"] = bool(settings.get("fullscreen", false))
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("設定を保存できません: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(normalized, "\t"))
	return true


static func apply_to_audio_buses(settings: Dictionary) -> void:
	_set_bus_volume(BGM_BUS, float(settings.get("bgm_volume", DEFAULT_BGM_VOLUME)))
	_set_bus_volume(SE_BUS, float(settings.get("se_volume", DEFAULT_SE_VOLUME)))


static func apply_display_settings(settings: Dictionary) -> void:
	var fullscreen := bool(settings.get("fullscreen", false))
	_last_display_fullscreen = fullscreen
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)


static func _set_bus_volume(bus_name: StringName, percent: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	var normalized := clampf(percent, 0.0, 100.0) / 100.0
	AudioServer.set_bus_mute(index, normalized <= 0.0)
	AudioServer.set_bus_volume_db(index, linear_to_db(normalized) if normalized > 0.0 else -80.0)
