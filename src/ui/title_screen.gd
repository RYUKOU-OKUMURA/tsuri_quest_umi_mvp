extends ScreenBase

const TitleBackdropScript = preload("res://src/ui/components/title_backdrop.gd")
const FightFishAssets = preload("res://src/ui/fight_fish_assets.gd")

const TITLE_LOGO_FRAME_PATH := "res://assets/showcase/title/title_logo_frame.png"
const TITLE_MENU_FRAME_PATH := "res://assets/showcase/title/title_menu_frame.png"
const TITLE_BUTTON_PRIMARY_PATH := "res://assets/showcase/title/title_button_primary.png"
const TITLE_BUTTON_PRIMARY_HOVER_PATH := "res://assets/showcase/title/title_button_primary_hover.png"
const TITLE_BUTTON_PRIMARY_PRESSED_PATH := "res://assets/showcase/title/title_button_primary_pressed.png"
const TITLE_BUTTON_SECONDARY_PATH := "res://assets/showcase/title/title_button_secondary.png"
const TITLE_BUTTON_SECONDARY_HOVER_PATH := "res://assets/showcase/title/title_button_secondary_hover.png"
const TITLE_BUTTON_DISABLED_PATH := "res://assets/showcase/title/title_button_disabled.png"
const TITLE_BAIT_PATH := "res://assets/showcase/common/nav_fishing_icon.png"

var _confirm_reset: ConfirmationDialog
var _slot_buttons: Array[Button] = []
var _slot_status_label: Label
var _continue_button: Button
var _new_button: Button
var _selected_slot_id := PlayerProgress.DEFAULT_SAVE_SLOT


func _build_screen() -> void:
	var backdrop := TitleBackdropScript.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	move_child(backdrop, 0)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_build_logo(root)
	_build_fish_feature(root)
	_build_menu(root)
	_build_version(root)
	_build_reset_dialog()


func _build_logo(root: Control) -> void:
	var logo_layer := _anchored_control(root, 0.055, 0.090, 0.720, 0.375)
	logo_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var logo_frame := _texture_rect(TITLE_LOGO_FRAME_PATH)
	logo_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	logo_layer.add_child(logo_frame)

	var title := make_shadow_label("釣りクエスト", 66, Palette.TITLE_LOGO_TEXT, 7, Palette.TITLE_LOGO_OUTLINE, Palette.TITLE_LOGO_SHADOW)
	_apply_title_font(title, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	_place_control(logo_layer, title, 0.12, 0.18, 0.88, 0.49)

	var subtitle := make_shadow_label("海釣り編", 30, Palette.TITLE_SUBTITLE_TEXT, 4, Palette.TITLE_SUBTITLE_OUTLINE, Palette.TITLE_SUBTITLE_SHADOW)
	_apply_title_font(subtitle, true)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_OFF
	_place_control(logo_layer, subtitle, 0.18, 0.50, 0.82, 0.67)

	var concept := make_shadow_label("港で支度し、釣って、料理して、強くなる。", 18, Palette.TITLE_CONCEPT_TEXT, 2, Palette.TITLE_CONCEPT_OUTLINE, Palette.TITLE_CONCEPT_SHADOW)
	_apply_title_font(concept, false)
	concept.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	concept.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	concept.autowrap_mode = TextServer.AUTOWRAP_OFF
	concept.clip_text = true
	_place_control(logo_layer, concept, 0.14, 0.70, 0.86, 0.84)


func _build_fish_feature(root: Control) -> void:
	var feature := _anchored_control(root, 0.050, 0.555, 0.430, 0.930)
	feature.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var fish_texture := _load_texture_if_exists(FightFishAssets.card_portrait_path({"id": "boss_kurodai"}))
	if fish_texture != null:
		var fish := TextureRect.new()
		fish.texture = fish_texture
		fish.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fish.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fish.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		fish.modulate = Palette.TITLE_FEATURE_FISH_MODULATE
		fish.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fish.offset_top = -18.0
		fish.offset_bottom = -18.0
		feature.add_child(fish)

	var caption := make_shadow_label("次の大物が、海の底で待っている。", 18, Palette.TITLE_FEATURE_CAPTION, 2, Palette.TITLE_FEATURE_OUTLINE, Palette.TITLE_FEATURE_SHADOW)
	_apply_title_font(caption, false)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.anchor_left = 0.0
	caption.anchor_top = 0.82
	caption.anchor_right = 1.0
	caption.anchor_bottom = 1.0
	caption.offset_left = 10.0
	caption.offset_top = 0.0
	caption.offset_right = -10.0
	caption.offset_bottom = 0.0
	feature.add_child(caption)


func _build_menu(root: Control) -> void:
	var menu := _anchored_control(root, 0.550, 0.395, 0.960, 0.925)
	var menu_frame := _texture_rect(TITLE_MENU_FRAME_PATH)
	menu_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(menu_frame)

	var bait_texture := _load_texture_if_exists(TITLE_BAIT_PATH)
	if bait_texture != null:
		var bait := TextureRect.new()
		bait.texture = bait_texture
		bait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		bait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_place_control(menu, bait, 0.285, 0.075, 0.355, 0.175)

	var header := make_shadow_label("セーブスロット", 24, Palette.TEXT_BONE, 2, Palette.TITLE_MENU_OUTLINE, Palette.TITLE_MENU_SHADOW)
	_apply_title_font(header, true)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.autowrap_mode = TextServer.AUTOWRAP_OFF
	header.clip_text = true
	_place_control(menu, header, 0.13, 0.070, 0.91, 0.185)

	_slot_buttons = []
	for slot_index in range(PlayerProgress.SAVE_SLOT_COUNT):
		var slot_id := slot_index + 1
		var slot_button := make_button("", Callable(self, "_select_slot").bind(slot_id), 430)
		slot_button.custom_minimum_size = Vector2.ZERO
		slot_button.clip_text = true
		_slot_buttons.append(slot_button)
		_place_control(
			menu,
			slot_button,
			0.105,
			0.215 + 0.102 * float(slot_index),
			0.895,
			0.300 + 0.102 * float(slot_index)
		)

	_slot_status_label = make_label("", 14, Palette.TITLE_SAVE_STATUS)
	_apply_title_font(_slot_status_label, false)
	_slot_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_slot_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_slot_status_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_slot_status_label.clip_text = true
	_place_control(menu, _slot_status_label, 0.105, 0.535, 0.895, 0.595)

	_selected_slot_id = PlayerProgress.active_save_slot

	_continue_button = make_button("つづきから", _continue_selected_slot, 430)
	_continue_button.custom_minimum_size = Vector2.ZERO
	_apply_title_button_skin(_continue_button, false)
	_place_control(menu, _continue_button, 0.105, 0.615, 0.895, 0.735)

	_new_button = make_button("", _on_new_game_pressed, 430, true)
	_new_button.custom_minimum_size = Vector2.ZERO
	_apply_title_button_skin(_new_button, true)
	_place_control(menu, _new_button, 0.105, 0.765, 0.895, 0.885)

	_refresh_slot_ui()


func _build_version(root: Control) -> void:
	var version_label := make_shadow_label("MVP Prototype v0.1 / Godot 4.7", 14, Palette.TITLE_VERSION_TEXT, 1, Palette.TITLE_VERSION_OUTLINE, Palette.TITLE_MENU_SHADOW)
	_apply_title_font(version_label, false)
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_label.anchor_left = 0.550
	version_label.anchor_top = 0.925
	version_label.anchor_right = 0.960
	version_label.anchor_bottom = 0.980
	version_label.offset_left = 0.0
	version_label.offset_top = 0.0
	version_label.offset_right = 0.0
	version_label.offset_bottom = 0.0
	root.add_child(version_label)


func _build_reset_dialog() -> void:
	_confirm_reset = ConfirmationDialog.new()
	_confirm_reset.title = "セーブデータの初期化"
	_confirm_reset.dialog_text = "現在の進行を消して、最初から始めます。よろしいですか？"
	_confirm_reset.ok_button_text = "最初から始める"
	_confirm_reset.cancel_button_text = "キャンセル"
	_confirm_reset.confirmed.connect(_start_new_game)
	add_child(_confirm_reset)

func _texture_rect(path: String) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = _load_texture_if_exists(path)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _load_texture_if_exists(path: String) -> Texture2D:
	if ResourceLoader.exists(path) or FileAccess.file_exists(path):
		return load(path) as Texture2D
	return null


func _apply_title_font(label: Label, bold: bool) -> void:
	var fallback := get_theme_default_font()
	var font := GameFontsScript.extra_bold(fallback) if bold else GameFontsScript.regular(fallback)
	label.add_theme_font_override("font", font)


func _apply_title_button_skin(button: Button, primary: bool) -> void:
	var normal_path := TITLE_BUTTON_PRIMARY_PATH if primary else TITLE_BUTTON_SECONDARY_PATH
	var hover_path := TITLE_BUTTON_PRIMARY_HOVER_PATH if primary else TITLE_BUTTON_SECONDARY_HOVER_PATH
	var pressed_path := TITLE_BUTTON_PRIMARY_PRESSED_PATH if primary else TITLE_BUTTON_SECONDARY_PATH
	var normal := _make_button_style(normal_path)
	var hover := _make_button_style(hover_path)
	var pressed := _make_button_style(pressed_path)
	var disabled := _make_button_style(TITLE_BUTTON_DISABLED_PATH)
	if normal == null or hover == null or pressed == null or disabled == null:
		return
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_font_override("font", GameFontsScript.bold(get_theme_default_font()))
	button.add_theme_color_override("font_color", Palette.TITLE_BUTTON_TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Palette.GOLD_BRIGHT)
	button.add_theme_color_override("font_disabled_color", Palette.TITLE_BUTTON_DISABLED_TEXT)
	button.add_theme_color_override("font_outline_color", Palette.TITLE_BUTTON_OUTLINE)
	button.add_theme_constant_override("outline_size", 2)
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	button.clip_text = true


func _make_button_style(path: String) -> StyleBoxTexture:
	var texture := _load_texture_if_exists(path)
	if texture == null:
		return null
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 42
	style.texture_margin_top = 24
	style.texture_margin_right = 42
	style.texture_margin_bottom = 24
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.content_margin_left = 28.0
	style.content_margin_top = 10.0
	style.content_margin_right = 28.0
	style.content_margin_bottom = 10.0
	return style


func _select_slot(slot_id: int) -> void:
	if PlayerProgress.is_save_storage_blocked():
		show_common_notification(PlayerProgress.save_storage_block_message())
		_refresh_slot_ui()
		return
	_selected_slot_id = clampi(slot_id, 1, PlayerProgress.SAVE_SLOT_COUNT)
	_refresh_slot_ui()


func _refresh_slot_ui() -> void:
	var storage_blocked := PlayerProgress.is_save_storage_blocked()
	for index in range(_slot_buttons.size()):
		var slot_id := index + 1
		var summary := PlayerProgress.save_slot_summary(slot_id)
		var selected := slot_id == _selected_slot_id
		var button := _slot_buttons[index]
		button.text = _slot_button_text(summary)
		button.disabled = storage_blocked
		_apply_title_button_skin(button, selected)
	var active_summary := PlayerProgress.save_slot_summary(_selected_slot_id)
	var has_save := bool(active_summary.get("has_save", false))
	var future_guarded := bool(active_summary.get("future_guarded", false))
	var invalid_artifact := bool(active_summary.get("invalid_artifact", false))
	_slot_status_label.text = _slot_status_text(active_summary)
	_continue_button.disabled = storage_blocked or not has_save or future_guarded or invalid_artifact
	_new_button.disabled = storage_blocked or future_guarded or invalid_artifact
	_new_button.text = (
		"セーブを確認できません（再起動）"
		if storage_blocked
		else "このスロットは利用できません"
		if future_guarded or invalid_artifact
		else ("最初から" if has_save else "ゲームを始める")
	)


func _slot_button_text(summary: Dictionary) -> String:
	var slot_id := int(summary.get("slot_id", 1))
	if bool(summary.get("storage_blocked", false)):
		return "スロット%d　利用不可（再起動）" % slot_id
	if bool(summary.get("future_guarded", false)):
		return "スロット%d　新しい版（対応版が必要）" % slot_id
	if bool(summary.get("invalid_artifact", false)):
		return "スロット%d　セーブ破損（利用不可）" % slot_id
	if not bool(summary.get("has_save", false)):
		return "スロット%d　空き" % slot_id
	return "スロット%d　Lv.%d　%s" % [
		slot_id,
		int(summary.get("level", 1)),
		_format_play_time(float(summary.get("play_seconds", 0.0))),
	]


func _slot_status_text(summary: Dictionary) -> String:
	var slot_id := int(summary.get("slot_id", 1))
	if bool(summary.get("storage_blocked", false)):
		return "セーブデータを確認できません。ゲームを再起動してください"
	if bool(summary.get("future_guarded", false)):
		return "スロット%d　%s" % [slot_id, future_save_guard_message()]
	if bool(summary.get("invalid_artifact", false)):
		return "スロット%d　%s" % [slot_id, String(summary.get("invalid_message", "セーブを読み込めません"))]
	if not bool(summary.get("has_save", false)):
		return "スロット%dを選択中　新しく始められます" % slot_id
	return "スロット%dを選択中　最終保存 %s　%s" % [
		slot_id,
		_format_updated_time(int(summary.get("updated_unix", 0))),
		_format_play_time(float(summary.get("play_seconds", 0.0))),
	]


func _format_play_time(seconds: float) -> String:
	var total_minutes := int(maxf(0.0, seconds) / 60.0)
	var hours := int(total_minutes / 60)
	var minutes := total_minutes % 60
	if hours > 0:
		return "%d時間%02d分" % [hours, minutes]
	return "%d分" % minutes


func _format_updated_time(unix_time: int) -> String:
	if unix_time <= 0:
		return "未保存"
	var date := Time.get_datetime_dict_from_unix_time(unix_time)
	return "%02d/%02d %02d:%02d" % [
		int(date.get("month", 1)),
		int(date.get("day", 1)),
		int(date.get("hour", 0)),
		int(date.get("minute", 0)),
	]


func _on_new_game_pressed() -> void:
	if PlayerProgress.is_save_storage_blocked():
		show_common_notification(PlayerProgress.save_storage_block_message())
		_refresh_slot_ui()
		return
	if PlayerProgress.is_future_save_version_guarded(_selected_slot_id):
		_refresh_slot_ui()
		return
	var summary := PlayerProgress.save_slot_summary(_selected_slot_id)
	if bool(summary.get("invalid_artifact", false)):
		show_common_notification(String(summary.get("invalid_message", "セーブを読み込めません")))
		_refresh_slot_ui()
		return
	if PlayerProgress.has_save_file(_selected_slot_id):
		_confirm_reset.dialog_text = "スロット%dの進行を消して、最初から始めます。よろしいですか？" % _selected_slot_id
		_confirm_reset.popup_centered(Vector2i(620, 220))
	else:
		_start_new_game()


func _continue_selected_slot() -> void:
	if PlayerProgress.is_save_storage_blocked():
		show_common_notification(PlayerProgress.save_storage_block_message())
		_refresh_slot_ui()
		return
	var summary := PlayerProgress.save_slot_summary(_selected_slot_id)
	if bool(summary.get("invalid_artifact", false)):
		show_common_notification(String(summary.get("invalid_message", "セーブを読み込めません")))
		_refresh_slot_ui()
		return
	if not PlayerProgress.set_active_save_slot(_selected_slot_id):
		_refresh_slot_ui()
		return
	navigate("harbor")


func _start_new_game() -> void:
	if PlayerProgress.is_save_storage_blocked():
		show_common_notification(PlayerProgress.save_storage_block_message())
		_refresh_slot_ui()
		return
	var summary := PlayerProgress.save_slot_summary(_selected_slot_id)
	if bool(summary.get("invalid_artifact", false)):
		show_common_notification(String(summary.get("invalid_message", "セーブを読み込めません")))
		_refresh_slot_ui()
		return
	if not PlayerProgress.set_active_save_slot(_selected_slot_id, false):
		_refresh_slot_ui()
		return
	if not PlayerProgress.reset_game():
		_refresh_slot_ui()
		return
	navigate("harbor")
