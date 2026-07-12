extends ScreenBase

const HarborBackdropScript = preload("res://src/ui/components/harbor_backdrop.gd")
const FightFishAssets = preload("res://src/ui/fight_fish_assets.gd")
const PlayerStatusBarScript = preload("res://src/ui/components/player_status_bar.gd")

const HARBOR_TOP_FRAME_PATH := "res://assets/showcase/harbor/harbor_top_frame.png"
const HARBOR_INFO_FISH_CARD_PATH := "res://assets/showcase/harbor/harbor_info_fish_card.png"
const HARBOR_TIME_SLOT_BTN_LOCKED_PATH := "res://assets/showcase/harbor/harbor_time_slot_btn_locked.png"
const HARBOR_TIME_SLOT_ICON_ASA_PATH := "res://assets/showcase/harbor/harbor_time_slot_icon_asa.png"
const HARBOR_TIME_SLOT_ICON_DAY_PATH := "res://assets/showcase/harbor/harbor_time_slot_icon_day.png"
const HARBOR_TIME_SLOT_ICON_NIGHT_PATH := "res://assets/showcase/harbor/harbor_time_slot_icon_night.png"
const COMMON_PARCHMENT_CARD_PATH := "res://assets/showcase/common/parchment_card.png"
const COMMON_HARBOR_COMMAND_DARK_FRAME_PATH := "res://assets/showcase/common/harbor_command_dark_frame.svg"
const COMMON_HARBOR_COMMAND_CTA_PATH := "res://assets/showcase/common/harbor_command_cta.png"
const HARBOR_COMMAND_ICON_SHEET_PATH := "res://assets/showcase/common/harbor_command_icon_sheet.svg"

const COMMAND_ICON_DEPARTURE := 0
const COMMAND_ICON_QUEST := 1
const COMMAND_ICON_COOKING := 2
const COMMAND_ICON_MARKET := 3
const COMMAND_ICON_SHOP := 4
const COMMAND_ICON_SHIPYARD := 5
const COMMAND_ICON_SHARK := 6
const COMMAND_ICON_STATUS := 7
const COMMAND_ICON_BOOK := 8
const COMMAND_ICON_BACK := 9
const COMMAND_ICON_WEATHER := 10
const COMMAND_ICON_PIN := 11
const COMMAND_ICON_GUIDE := 12
const COMMAND_ICON_RUMOR := 13
const COMMAND_ICON_LOCK := 14
var _status_label: Label
var _play_time_label: Label
var _context_label: Label
var _player_status_bar
var _buff_name_label: Label
var _facility_detail_title_label: Label
var _facility_detail_body_label: Label
var _meal_effect_row_label: Label
var _location_label: Label
var _plan_guide_label: Label
var _plan_weather_label: Label
var _plan_pin_row: Control
var _plan_pin_label: Label
var _plan_rumor_row: Control
var _plan_rumor_icon: TextureRect
var _plan_rumor_eyebrow_label: Label
var _plan_rumor_label: Label
var _time_slot_zone_root: Control
var _info_board_root: Control
var _info_board_slots: Array[Dictionary] = []
var _time_slot_buttons: Dictionary = {}
var _time_slot_icons: Dictionary = {}
var _time_slot_grade_overlay: ColorRect
var _meal_effect_panel: Control
var _route_buttons: Dictionary = {}
var _settings_button: Button
var _notification_badges: Dictionary = {}
var _lock_icons: Dictionary = {}
var _hero_target_slot: Dictionary = {}
var _secondary_target_slots: Array[Dictionary] = []
var _command_board_root: Control
var _operation_board_root: Control
var _footer_root: Control
var _top_bar_root: Control


func _build_screen() -> void:
	var backdrop := HarborBackdropScript.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	move_child(backdrop, 0)
	_build_time_slot_grade_overlay()
	var screen_scrim := ColorRect.new()
	screen_scrim.name = "HarborScreenScrim"
	screen_scrim.color = Palette.HARBOR_BACKDROP_FRAME
	screen_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(screen_scrim)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_build_top_bar(root)
	_build_main_panel(root)
	_build_facility_menu(root)
	_build_footer(root)
	_refresh_labels()


func _build_top_bar(root: Control) -> void:
	var top := Control.new()
	_top_bar_root = top
	top.name = "HarborTopBar"
	_place_control_px(root, top, Rect2(32.0, 24.0, 1216.0, 80.0))
	var frame := _texture_rect(HARBOR_TOP_FRAME_PATH)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top.add_child(frame)

	var accent := ColorRect.new()
	accent.color = Palette.HARBOR_FACILITY_ACCENT_PRIMARY
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control_px(top, accent, Rect2(22.0, 15.0, 2.0, 50.0))

	_location_label = _harbor_label("南の島・港", 30, Palette.HARBOR_LOCATION_TEXT, true, 3, Palette.HARBOR_LOCATION_OUTLINE)
	_location_label.name = "HarborLocationTitle"
	_location_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_location_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control_px(top, _location_label, Rect2(36.0, 3.0, 360.0, 38.0))

	_context_label = _harbor_label("HARBOR COMMAND", 11, Palette.HARBOR_CONTEXT_TEXT, true, 1, Palette.HARBOR_LABEL_OUTLINE)
	_context_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_context_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control_px(top, _context_label, Rect2(38.0, 41.0, 320.0, 22.0))

	_add_vertical_rule(top, 446.0)
	_add_vertical_rule(top, 658.0)
	_add_vertical_rule(top, 942.0)

	_player_status_bar = PlayerStatusBarScript.new()
	_player_status_bar.name = "HarborPlayerStatusBar"
	_player_status_bar.use_harbor_command_layout()
	_place_control_px(top, _player_status_bar, Rect2(446.0, 0.0, 770.0, 80.0))


func _build_main_panel(root: Control) -> void:
	_command_board_root = Control.new()
	_command_board_root.name = "HarborCommandBoard"
	_command_board_root.clip_contents = true
	_place_control_px(root, _command_board_root, Rect2(40.0, 120.0, 788.0, 512.0))
	var fill := ColorRect.new()
	fill.color = _with_alpha(Palette.DARK_PANEL_DEEP, 0.86)
	fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_command_board_root.add_child(fill)
	var frame := _nine_patch_rect(COMMON_HARBOR_COMMAND_DARK_FRAME_PATH, Vector4(12.0, 12.0, 12.0, 12.0))
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_command_board_root.add_child(frame)

	_build_info_board(_command_board_root)
	_build_departure_plan_card(_command_board_root)
	_build_time_slot_zone(_command_board_root)


func _build_info_board(main: Control) -> void:
	_info_board_root = Control.new()
	_info_board_root.name = "HarborTargetBoard"
	_info_board_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control_px(main, _info_board_root, Rect2(20.0, 14.0, 748.0, 192.0))

	var title := _harbor_label("本日の狙い目", 20, Palette.HARBOR_SCENE_TITLE, true, 2, Palette.HARBOR_SCENE_TITLE_OUTLINE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control_px(_info_board_root, title, Rect2(0.0, 0.0, 240.0, 34.0))
	var priority_caption := _harbor_label("TARGET PRIORITY", 10, Palette.HARBOR_CONTEXT_TEXT, true, 0)
	priority_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	priority_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control_px(_info_board_root, priority_caption, Rect2(520.0, 0.0, 228.0, 34.0))
	var rule := ColorRect.new()
	rule.color = _with_alpha(Palette.GOLD, 0.42)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control_px(_info_board_root, rule, Rect2(0.0, 32.0, 748.0, 1.0))

	_info_board_slots.clear()
	_secondary_target_slots.clear()
	_hero_target_slot = _build_target_slot(_info_board_root, Rect2(0.0, 38.0, 364.0, 154.0), true, 0)
	_info_board_slots.append(_hero_target_slot)
	for entry in [
		{"rect": Rect2(376.0, 38.0, 180.0, 154.0), "index": 1},
		{"rect": Rect2(568.0, 38.0, 180.0, 154.0), "index": 2},
	]:
		var target_rect: Rect2 = entry["rect"]
		var secondary := _build_target_slot(_info_board_root, target_rect, false, int(entry["index"]))
		_secondary_target_slots.append(secondary)
		_info_board_slots.append(secondary)


func _build_target_slot(parent: Control, rect: Rect2, hero: bool, index: int) -> Dictionary:
	var slot := Control.new()
	slot.name = "HarborHeroTarget" if hero else "HarborSecondaryTarget%d" % index
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.clip_contents = true
	_place_control_px(parent, slot, rect)

	var frame: Control
	if hero:
		frame = _nine_patch_rect(COMMON_HARBOR_COMMAND_DARK_FRAME_PATH, Vector4(12.0, 12.0, 12.0, 12.0))
	else:
		frame = _nine_patch_rect(HARBOR_INFO_FISH_CARD_PATH, Vector4(40.0, 38.0, 40.0, 38.0))
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	slot.add_child(frame)

	var portrait_clip := Control.new()
	portrait_clip.name = "PortraitClip"
	portrait_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_clip.clip_contents = true
	_place_control_px(
		slot,
		portrait_clip,
		Rect2(8.0, 8.0, 238.0, 138.0) if hero else Rect2(8.0, 7.0, 164.0, 88.0)
	)
	var portrait := _icon_rect("")
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_clip.add_child(portrait)

	var name_label := _harbor_label(
		"",
		26 if hero else 18,
		Palette.HARBOR_MENU_HEADER if hero else Palette.HARBOR_PARCHMENT_TITLE,
		true,
		2 if hero else 0,
		Palette.HARBOR_MENU_OUTLINE
	)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if hero else HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control_px(
		slot,
		name_label,
		Rect2(250.0, 54.0, 104.0, 34.0) if hero else Rect2(12.0, 98.0, 156.0, 28.0)
	)

	var badge_panel := Panel.new()
	badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge_panel.add_theme_stylebox_override(
		"panel",
		_make_flat_panel_style(Palette.HARBOR_INFO_BADGE_QUEST_FILL, Color.TRANSPARENT, 8, 0)
	)
	_place_control_px(
		slot,
		badge_panel,
		Rect2(246.0, 16.0, 108.0, 24.0) if hero else Rect2(16.0, 126.0, 148.0, 20.0)
	)
	var badge_label := _harbor_label("", 11 if hero else 10, Palette.HARBOR_INFO_BADGE_QUEST_TEXT, true, 1, Palette.HARBOR_LABEL_OUTLINE)
	badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	badge_panel.add_child(badge_label)

	var detail_label: Label = null
	var candidate_label: Label = null
	if hero:
		var accent := ColorRect.new()
		accent.color = Palette.HARBOR_FACILITY_ACCENT_PRIMARY
		accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place_control_px(slot, accent, Rect2(6.0, 8.0, 4.0, 138.0))
		detail_label = _harbor_label("", 11, Palette.HARBOR_CONTEXT_TEXT, true, 0)
		detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		detail_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_place_control_px(slot, detail_label, Rect2(250.0, 89.0, 104.0, 25.0))
		var mini_rule := ColorRect.new()
		mini_rule.color = _with_alpha(Palette.GOLD, 0.45)
		mini_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place_control_px(slot, mini_rule, Rect2(250.0, 112.0, 104.0, 1.0))
		candidate_label = _harbor_label("", 11, Palette.HARBOR_DETAIL_BODY_SECONDARY, true, 0)
		candidate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		candidate_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_place_control_px(slot, candidate_label, Rect2(250.0, 116.0, 104.0, 24.0))

	return {
		"slot": slot,
		"portrait": portrait,
		"name_label": name_label,
		"badge_panel": badge_panel,
		"badge_label": badge_label,
		"detail_label": detail_label,
		"candidate_label": candidate_label,
		"hero": hero,
		"index": index,
	}


func _build_departure_plan_card(main: Control) -> void:
	var card := Control.new()
	card.name = "HarborDepartureIntel"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control_px(main, card, Rect2(20.0, 210.0, 748.0, 198.0))

	var title := _harbor_label("出港情報", 20, Palette.HARBOR_SCENE_TITLE, true, 2, Palette.HARBOR_SCENE_TITLE_OUTLINE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control_px(card, title, Rect2(0.0, 0.0, 120.0, 34.0))
	var rule := ColorRect.new()
	rule.color = _with_alpha(Palette.GOLD, 0.35)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control_px(card, rule, Rect2(94.0, 20.0, 654.0, 1.0))

	var guide_row := _build_departure_intel_card(card, Rect2(0.0, 34.0, 270.0, 78.0), COMMAND_ICON_GUIDE, "ガイド")
	_plan_guide_label = guide_row["label"] as Label
	var weather_row := _build_departure_intel_card(card, Rect2(278.0, 34.0, 270.0, 78.0), COMMAND_ICON_WEATHER, "天気の気配")
	_plan_weather_label = weather_row["label"] as Label
	var pin_row := _build_departure_intel_card(card, Rect2(556.0, 34.0, 192.0, 78.0), COMMAND_ICON_PIN, "狙いポイント")
	_plan_pin_row = pin_row["row"] as Control
	_plan_pin_label = pin_row["label"] as Label
	var rumor_row := _build_departure_intel_card(card, Rect2(0.0, 120.0, 748.0, 78.0), COMMAND_ICON_RUMOR, "港の目撃談")
	_plan_rumor_row = rumor_row["row"] as Control
	_plan_rumor_icon = rumor_row["icon"] as TextureRect
	_plan_rumor_eyebrow_label = rumor_row["eyebrow_label"] as Label
	_plan_rumor_label = rumor_row["label"] as Label


func _build_departure_intel_card(
	parent: Control, rect: Rect2, icon_index: int, eyebrow: String
) -> Dictionary:
	var row := Control.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control_px(parent, row, rect)
	var panel := _nine_patch_rect(COMMON_PARCHMENT_CARD_PATH, Vector4(34.0, 16.0, 34.0, 16.0))
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.add_child(panel)
	var icon := _command_icon_rect(icon_index)
	icon.modulate = Palette.HARBOR_PARCHMENT_TITLE
	_place_control_px(row, icon, Rect2(12.0, 23.0, 32.0, 32.0))
	var eyebrow_label := _harbor_label(eyebrow, 11, Palette.HARBOR_PARCHMENT_TITLE, true, 0)
	eyebrow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	eyebrow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	eyebrow_label.clip_text = false
	eyebrow_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_place_control_px(row, eyebrow_label, Rect2(52.0, 10.0, rect.size.x - 64.0, 20.0))
	var label := _harbor_label("", 15, Palette.HARBOR_BUFF_NAME, true, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = false
	label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_place_control_px(row, label, Rect2(52.0, 32.0, rect.size.x - 64.0, rect.size.y - 38.0))
	return {"row": row, "icon": icon, "eyebrow_label": eyebrow_label, "label": label}


func _build_time_slot_zone(main: Control) -> void:
	_time_slot_zone_root = Control.new()
	_time_slot_zone_root.name = "HarborTimeAndMeal"
	_time_slot_zone_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control_px(main, _time_slot_zone_root, Rect2(20.0, 412.0, 748.0, 88.0))

	var time_label := _harbor_label("時間帯", 12, Palette.HARBOR_SCENE_TITLE, true, 2, Palette.HARBOR_SCENE_TITLE_OUTLINE)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control_px(_time_slot_zone_root, time_label, Rect2(0.0, 44.0, 66.0, 44.0))

	_build_time_slot_selector(_time_slot_zone_root)

	_meal_effect_panel = Control.new()
	_meal_effect_panel.name = "HarborMealEffect"
	_meal_effect_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control_px(_time_slot_zone_root, _meal_effect_panel, Rect2(0.0, 0.0, 748.0, 36.0))
	var meal_frame := _nine_patch_rect(COMMON_HARBOR_COMMAND_DARK_FRAME_PATH, Vector4(12.0, 12.0, 12.0, 12.0))
	meal_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_meal_effect_panel.add_child(meal_frame)
	var meal_accent := ColorRect.new()
	meal_accent.color = Palette.HARBOR_INFO_BADGE_UNCAUGHT_FILL
	meal_accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control_px(_meal_effect_panel, meal_accent, Rect2(1.0, 2.0, 5.0, 32.0))
	_meal_effect_row_label = _harbor_label("食事効果", 11, Palette.HARBOR_SCENE_TEXT, true, 1, Palette.HARBOR_SCENE_TEXT_OUTLINE)
	_meal_effect_row_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_meal_effect_row_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control_px(_meal_effect_panel, _meal_effect_row_label, Rect2(20.0, 4.0, 82.0, 28.0))

	_buff_name_label = _harbor_label("", 13, Palette.HARBOR_SCENE_TEXT, true, 1, Palette.HARBOR_SCENE_TEXT_OUTLINE)
	_buff_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_buff_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control_px(_meal_effect_panel, _buff_name_label, Rect2(108.0, 4.0, 620.0, 28.0))


func _make_plan_row_button(text: String, callback: Callable) -> Button:
	var button := make_button(text, callback, 0.0, false)
	# 行の高さ（約38px）が make_button の最小高 50px を下回るため、行からのはみ出しを防ぐ。
	button.custom_minimum_size = Vector2.ZERO
	button.add_theme_font_size_override("font_size", 13)
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return button


func _build_time_slot_selector(card: Control) -> void:
	var ids := GameData.get_all_time_slot_ids()
	var rects := [
		Rect2(72.0, 44.0, 216.0, 44.0),
		Rect2(296.0, 44.0, 216.0, 44.0),
		Rect2(520.0, 44.0, 228.0, 44.0),
	]
	for index in range(ids.size()):
		var time_slot_id := String(ids[index])
		var button := _make_plan_row_button("", _select_time_slot.bind(time_slot_id))
		button.name = "HarborTimeSlot_%s" % time_slot_id
		button.set_meta("harbor_time_slot_id", time_slot_id)
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_font_size_override("font_size", 16)
		_apply_time_slot_button_defaults(button)
		_time_slot_buttons[time_slot_id] = button
		var icon := _icon_rect(_time_slot_icon_path(time_slot_id))
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place_control_px(button, icon, Rect2(10.0, 7.0, 30.0, 30.0))
		_time_slot_icons[time_slot_id] = icon
		if index < rects.size():
			_place_control_px(card, button, rects[index])


func _apply_time_slot_button_defaults(button: Button) -> void:
	button.add_theme_font_override("font", GameFontsScript.bold(get_theme_default_font()))
	button.add_theme_constant_override("outline_size", 1)
	_apply_time_slot_button_colors(button, false, false)


func _apply_time_slot_button_colors(button: Button, selected: bool, locked: bool) -> void:
	var dark_text := Palette.HARBOR_PARCHMENT_TITLE
	if locked:
		button.add_theme_color_override("font_color", Palette.HARBOR_BUFF_BODY)
		button.add_theme_color_override("font_hover_color", Palette.HARBOR_BUFF_BODY)
		button.add_theme_color_override("font_pressed_color", Palette.HARBOR_BUFF_BODY)
		button.add_theme_color_override("font_disabled_color", Palette.HARBOR_BUFF_BODY)
		button.add_theme_color_override("font_outline_color", Palette.HARBOR_LABEL_OUTLINE)
		return
	if selected:
		button.add_theme_color_override("font_color", dark_text)
		button.add_theme_color_override("font_hover_color", dark_text)
		button.add_theme_color_override("font_pressed_color", dark_text)
		button.add_theme_color_override("font_outline_color", Palette.HARBOR_SCENE_TITLE_OUTLINE)
		return
	button.add_theme_color_override("font_color", Palette.HARBOR_DETAIL_BODY_SECONDARY)
	button.add_theme_color_override("font_hover_color", Palette.HARBOR_MENU_HEADER)
	button.add_theme_color_override("font_pressed_color", Palette.HARBOR_MENU_HEADER)
	button.add_theme_color_override("font_disabled_color", Palette.HARBOR_DETAIL_BODY_SECONDARY)
	button.add_theme_color_override("font_outline_color", Palette.HARBOR_LABEL_OUTLINE)


func _time_slot_icon_path(time_slot_id: String) -> String:
	match time_slot_id:
		"asa_mazume":
			return HARBOR_TIME_SLOT_ICON_ASA_PATH
		"night":
			return HARBOR_TIME_SLOT_ICON_NIGHT_PATH
		_:
			return HARBOR_TIME_SLOT_ICON_DAY_PATH


func _beginner_guide_text() -> String:
	if PlayerProgress.level > PlayerProgress.GROWTH_SOFT_CAP:
		return ""
	if PlayerProgress.eaten_recipes.is_empty():
		return "まずは調理場で魚を食べてみよう"
	if _has_incomplete_quest():
		return "依頼ボードで魚を届けよう"
	return ""


func _has_incomplete_quest() -> bool:
	for index in range(PlayerProgress.quest_board.size()):
		var progress := PlayerProgress.quest_progress(index)
		if progress.is_empty() or bool(progress.get("completed", true)):
			continue
		return true
	return false


## 「今すぐ納品・報告できる依頼が1件以上あるか」。quest_board_screen.gdの
## 納品ボタン活性条件（`_refresh_card` の `button.disabled = not completed`）と同じ
## `PlayerProgress.quest_progress(index).completed` を読むだけで、判定ロジックの複製はしない。
func _has_deliverable_quest() -> bool:
	for index in range(PlayerProgress.quest_board.size()):
		var progress := PlayerProgress.quest_progress(index)
		if not progress.is_empty() and bool(progress.get("completed", false)):
			return true
	return false


## クーラーボックス（インベントリ）内の魚の総数。フッター表示（`_refresh_labels`）と
## 右メニューの通知バッジ／ヒント判定で共有する。
func _cooler_fish_total() -> int:
	var total := 0
	for count in PlayerProgress.inventory.values():
		total += int(count)
	return total


## 右メニュー詳細パネルのデフォルト表示（コンテキストヒント）。優先度:
## 1. 納品できる依頼がある → 依頼ボードへ誘導
## 2. クーラーボックスに魚がいる → 魚市場へ誘導
## 3. 該当なし → 従来どおり釣り場への案内
## 新しい保存状態は作らず、既存状態の読み取りのみで決める純粋関数。
func _facility_menu_hint() -> Dictionary:
	if _has_deliverable_quest():
		return {
			"title": "つぎのおすすめ",
			"body": "納品できる依頼がある。依頼ボードへ",
			"primary": true,
		}
	var cooler_total := _cooler_fish_total()
	if cooler_total > 0:
		return {
			"title": "つぎのおすすめ",
			"body": "クーラーボックスに%d匹。魚市場で売ろう" % cooler_total,
			"primary": true,
		}
	return {
		"title": "釣り場へ向かう",
		"body": "狙う魚に合わせてポイントを選ぶ",
		"primary": true,
	}


func _unlocked_normal_spot_ids() -> Array[String]:
	var ids: Array[String] = []
	for spot_id in GameData.NORMAL_FISHING_SPOT_IDS:
		if PlayerProgress.can_access_fishing_spot(spot_id):
			ids.append(spot_id)
	return ids


func _harbor_highlight_candidates(max_count := 3) -> Array:
	var spot_ids := _unlocked_normal_spot_ids()
	var merged: Array = []
	var seen_fish: Dictionary = {}
	for bucket in [
		_collect_quest_candidates(spot_ids),
		_collect_time_boost_candidates(spot_ids),
		_collect_uncaught_candidates(spot_ids),
	]:
		for candidate in bucket:
			var fish_id := String(candidate.get("fish_id", ""))
			if fish_id.is_empty() or seen_fish.has(fish_id):
				continue
			seen_fish[fish_id] = true
			merged.append(candidate)
			if merged.size() >= max_count:
				return merged
	return merged


func _collect_quest_candidates(spot_ids: Array[String]) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for index in range(PlayerProgress.quest_board.size()):
		var progress := PlayerProgress.quest_progress(index)
		if progress.is_empty():
			continue
		var deliverable := bool(progress.get("completed", false))
		var fish_id := String(progress.get("fish_id", ""))
		if fish_id.is_empty():
			continue
		var best_spot_id := ""
		var best_weight := 0.0
		for spot_id in spot_ids:
			var weights := GameData.encounter_weights(
				PlayerProgress.level, spot_id, "", "", {}, PlayerProgress.selected_time_slot_id
			)
			var weight := float(weights.get(fish_id, 0.0))
			if weight > best_weight:
				best_weight = weight
				best_spot_id = spot_id
		if best_spot_id.is_empty():
			continue
		var fish_name := String(GameData.get_fish(fish_id).get("name", fish_id))
		var spot_name := String(GameData.get_fishing_spot(best_spot_id).get("name", best_spot_id))
		candidates.append(
			{
				"fish_id": fish_id,
				"spot_id": best_spot_id,
				"reason": "quest",
				"reason_label": "依頼",
				"deliverable": deliverable,
				"hint_text": "依頼の%sは%sが狙い目だ" % [fish_name, spot_name],
			}
		)
	return candidates


func _collect_time_boost_candidates(spot_ids: Array[String]) -> Array[Dictionary]:
	var raw_candidates: Array[Dictionary] = []
	for spot_id in spot_ids:
		var weights_with := GameData.encounter_weights(
			PlayerProgress.level, spot_id, "", "", {}, PlayerProgress.selected_time_slot_id
		)
		var weights_without := GameData.encounter_weights(PlayerProgress.level, spot_id)
		for fish_id_variant in weights_with.keys():
			var fish_id := String(fish_id_variant)
			var base_weight := float(weights_without.get(fish_id, 0.0))
			if base_weight <= 0.0:
				continue
			var boost := float(weights_with[fish_id]) / base_weight
			if boost <= 1.0:
				continue
			raw_candidates.append(
				{
					"fish_id": fish_id,
					"spot_id": spot_id,
					"boost": boost,
					"uncaught": int(PlayerProgress.caught_counts.get(fish_id, 0)) <= 0,
				}
			)
	if raw_candidates.is_empty():
		return []
	var has_uncaught := false
	for candidate in raw_candidates:
		if bool(candidate["uncaught"]):
			has_uncaught = true
			break
	var filtered: Array[Dictionary] = []
	if has_uncaught:
		for candidate in raw_candidates:
			if bool(candidate["uncaught"]):
				filtered.append(candidate)
	else:
		filtered = raw_candidates
	filtered.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			if float(a["boost"]) != float(b["boost"]):
				return float(a["boost"]) > float(b["boost"])
			return String(a["fish_id"]) < String(b["fish_id"])
	)
	var time_slot_name := String(
		GameData.get_time_slot(PlayerProgress.selected_time_slot_id).get("name", "")
	)
	var reason_label := time_slot_name if not time_slot_name.is_empty() else "時間帯"
	var candidates: Array[Dictionary] = []
	for candidate in filtered:
		var fish_id := String(candidate["fish_id"])
		var spot_id := String(candidate["spot_id"])
		var spot_name := String(GameData.get_fishing_spot(spot_id).get("name", spot_id))
		var fish_name := String(GameData.get_fish(fish_id).get("name", fish_id))
		candidates.append(
			{
				"fish_id": fish_id,
				"spot_id": spot_id,
				"reason": "time_boost",
				"reason_label": reason_label,
				"hint_text": "%sは%sで%sが活発なようだ" % [time_slot_name, spot_name, fish_name],
			}
		)
	return candidates


func _collect_uncaught_candidates(spot_ids: Array[String]) -> Array[Dictionary]:
	var weighted: Array[Dictionary] = []
	for spot_id in spot_ids:
		var weights := GameData.encounter_weights(
			PlayerProgress.level, spot_id, "", "", {}, PlayerProgress.selected_time_slot_id
		)
		for fish_id_variant in weights.keys():
			var fish_id := String(fish_id_variant)
			if int(PlayerProgress.caught_counts.get(fish_id, 0)) > 0:
				continue
			var weight := float(weights[fish_id])
			if weight <= 0.0:
				continue
			weighted.append(
				{
					"fish_id": fish_id,
					"spot_id": spot_id,
					"weight": weight,
				}
			)
	if weighted.is_empty():
		return []
	weighted.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			if float(a["weight"]) != float(b["weight"]):
				return float(a["weight"]) > float(b["weight"])
			return String(a["fish_id"]) < String(b["fish_id"])
	)
	var candidates: Array[Dictionary] = []
	for entry in weighted:
		var fish_id := String(entry["fish_id"])
		var spot_id := String(entry["spot_id"])
		var spot_name := String(GameData.get_fishing_spot(spot_id).get("name", spot_id))
		var fish_name := String(GameData.get_fish(fish_id).get("name", fish_id))
		candidates.append(
			{
				"fish_id": fish_id,
				"spot_id": spot_id,
				"reason": "uncaught",
				"reason_label": "まだ見ぬ魚",
				"hint_text": "%sで%sの姿を見かけたそうだ" % [spot_name, fish_name],
			}
		)
	return candidates


func _megalodon_omen_text() -> String:
	if int(PlayerProgress.caught_counts.get("megalodon", 0)) > 0:
		return ""
	if not GameData.is_megalodon_unlocked(PlayerProgress.level, PlayerProgress.shark_bonds):
		return ""
	return "生簀のサメたちが、深海の何かに怯えている……\nヌシ級の餌魚を危険海域へ捧げよう"


func _nushi_hint_text() -> String:
	var candidates: Array[String] = []
	for spot_id in GameData.NORMAL_FISHING_SPOT_IDS:
		var spot := GameData.get_fishing_spot(spot_id)
		var nushi: Dictionary = spot.get("nushi", {})
		var fish_id := String(nushi.get("fish_id", ""))
		if fish_id.is_empty():
			continue
		if int(PlayerProgress.caught_counts.get(fish_id, 0)) <= 0:
			var hint := String(nushi.get("hint", ""))
			if not hint.is_empty():
				candidates.append(hint)
	if candidates.is_empty():
		return ""
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return candidates[rng.randi_range(0, candidates.size() - 1)]


func _refresh_preparation_card() -> void:
	if _plan_guide_label == null or _plan_weather_label == null or _plan_pin_label == null or _plan_rumor_label == null:
		return
	_plan_guide_label.text = _departure_guide_summary()
	_plan_weather_label.text = "雨・潮目が立ちやすい"
	var pin_text := ""
	var candidates := _harbor_highlight_candidates(1)
	if not candidates.is_empty():
		var spot_id := String(candidates[0].get("spot_id", ""))
		if not spot_id.is_empty():
			var spot_name := String(GameData.get_fishing_spot(spot_id).get("name", spot_id))
			pin_text = spot_name
	_plan_pin_label.text = pin_text
	_plan_pin_row.visible = not pin_text.is_empty()
	var rumor_text := _megalodon_omen_text()
	if rumor_text.is_empty():
		rumor_text = _nushi_hint_text()
	if rumor_text.is_empty():
		_plan_rumor_row.visible = false
	else:
		_plan_rumor_label.text = rumor_text.replace("\n", "　")
		_plan_rumor_row.visible = true


func _departure_guide_summary() -> String:
	var beginner := _beginner_guide_text()
	if not beginner.is_empty():
		return beginner
	var candidates := _harbor_highlight_candidates(1)
	if candidates.is_empty():
		return "時間帯で出現率が変わる"
	var candidate: Dictionary = candidates[0]
	var fish_id := String(candidate.get("fish_id", ""))
	var fish_name := String(GameData.get_fish(fish_id).get("name", fish_id))
	match String(candidate.get("reason", "")):
		"quest":
			return "%sを依頼で狙おう" % fish_name
		"time_boost":
			return "%sで出現率アップ" % String(candidate.get("reason_label", "時間帯"))
		"uncaught":
			return "まだ見ぬ魚の目撃あり"
	return "時間帯で出現率が変わる"


func _refresh_info_board() -> void:
	if _info_board_root == null:
		return
	var candidates := _harbor_highlight_candidates(3)
	for index in range(_info_board_slots.size()):
		var slot_data: Dictionary = _info_board_slots[index]
		var slot := slot_data.get("slot", null) as Control
		var portrait := slot_data.get("portrait", null) as TextureRect
		var name_label := slot_data.get("name_label", null) as Label
		var badge_panel := slot_data.get("badge_panel", null) as Panel
		var badge_label := slot_data.get("badge_label", null) as Label
		var detail_label := slot_data.get("detail_label", null) as Label
		var candidate_label := slot_data.get("candidate_label", null) as Label
		var hero := bool(slot_data.get("hero", false))
		if slot == null or portrait == null or name_label == null or badge_panel == null or badge_label == null:
			continue
		if index >= candidates.size():
			slot.visible = false
			continue
		slot.visible = true
		var candidate: Dictionary = candidates[index]
		var fish_id := String(candidate.get("fish_id", ""))
		var fish_data := GameData.get_fish(fish_id)
		portrait.texture = _load_texture_if_exists(FightFishAssets.card_portrait_path(fish_data))
		name_label.text = String(fish_data.get("name", fish_id))
		_fit_label_font(name_label, name_label.text, 26 if hero else 18, 12 if hero else 13, 104.0 if hero else 156.0)
		var reason := String(candidate.get("reason", ""))
		var reason_label := String(candidate.get("reason_label", ""))
		var reason_summary := reason_label
		var detail_text := "目撃情報あり"
		match reason:
			"quest":
				reason_summary = "依頼対象"
				detail_text = "納品できる依頼あり" if bool(candidate.get("deliverable", false)) else "依頼対象の魚"
			"time_boost":
				reason_summary = "%sで出やすい" % reason_label
				detail_text = "出現率アップ"
			"uncaught":
				reason_summary = "目撃情報あり"
		if hero:
			badge_label.text = "最優先・%s" % ("依頼" if reason == "quest" else reason_label)
		else:
			badge_label.text = reason_summary
		if detail_label != null:
			detail_label.text = detail_text
		if candidate_label != null:
			candidate_label.text = "候補 %d / %d" % [index + 1, candidates.size()]
		var badge_fill := Palette.HARBOR_INFO_BADGE_UNCAUGHT_FILL
		var badge_text := Palette.HARBOR_INFO_BADGE_UNCAUGHT_TEXT
		match reason:
			"quest":
				badge_fill = Palette.HARBOR_INFO_BADGE_QUEST_FILL
				badge_text = Palette.HARBOR_INFO_BADGE_QUEST_TEXT
			"time_boost":
				badge_fill = Palette.HARBOR_INFO_BADGE_BOOST_FILL
				badge_text = Palette.HARBOR_INFO_BADGE_BOOST_TEXT
		badge_panel.add_theme_stylebox_override(
			"panel",
			_make_flat_panel_style(badge_fill, Color.TRANSPARENT, 5, 0)
		)
		badge_label.add_theme_color_override("font_color", badge_text)


func _select_time_slot(time_slot_id: String) -> void:
	if not PlayerProgress.select_time_slot(time_slot_id):
		return
	_refresh_labels()


func _refresh_time_slot_buttons() -> void:
	for time_slot_id in GameData.get_all_time_slot_ids():
		var button := _time_slot_buttons.get(time_slot_id, null) as Button
		if button == null:
			continue
		var time_slot := GameData.get_time_slot(time_slot_id)
		var label := String(time_slot.get("name", time_slot_id))
		var unlock_level := int(time_slot.get("unlock_level", 1))
		var locked := not GameData.is_time_slot_unlocked(time_slot_id, PlayerProgress.level)
		var selected := PlayerProgress.selected_time_slot_id == time_slot_id
		button.disabled = locked
		if locked:
			button.text = "Lv.%dで解放" % unlock_level
		else:
			button.text = label
		_apply_time_slot_button_colors(button, selected, locked)
		var style_path := COMMON_HARBOR_COMMAND_DARK_FRAME_PATH
		if locked:
			style_path = HARBOR_TIME_SLOT_BTN_LOCKED_PATH
		elif selected:
			style_path = COMMON_HARBOR_COMMAND_CTA_PATH
		var style := _make_time_slot_button_style(style_path)
		if style != null:
			_apply_interactive_button_styles(button, style, "time")
		var icon := _time_slot_icons.get(time_slot_id, null) as TextureRect
		if icon != null:
			icon.modulate = Palette.HARBOR_ICON_MODULATE if not locked else Palette.HARBOR_LOCKED_ICON_MODULATE


func _has_caught_raiseable_shark() -> bool:
	for shark_id in GameData.get_raiseable_shark_ids():
		if int(PlayerProgress.caught_counts.get(shark_id, 0)) > 0:
			return true
	return false


func _can_open_shark_pen() -> bool:
	return PlayerProgress.level >= 30 and _has_caught_raiseable_shark()


func _open_shark_pen() -> void:
	if not _can_open_shark_pen():
		_set_facility_detail("サメの生簀", "Lv.30／危険海域で解放", false)
		return
	navigate("shark_pen")


func _facility_menu_items() -> Array[Dictionary]:
	var shark_pen_locked := not _can_open_shark_pen()
	var shark_pen_detail := "捕獲したサメを育てる" if not shark_pen_locked else "Lv.30／危険海域で解放"
	var quest_badge := _has_deliverable_quest()
	var market_badge := _cooler_fish_total() > 0
	return [
		{
			"id": "fishing_spots",
			"title": "釣り場へ向かう",
			"body": "狙う魚に合わせてポイントを選ぶ",
			"icon_index": COMMAND_ICON_DEPARTURE,
			"callback": func() -> void: navigate("fishing_spots"),
			"primary": true,
			"locked": false,
			"section": "departure",
		},
		{
			"id": "quest_board",
			"title": "依頼ボード",
			"body": "釣果を届けて報酬を受け取る",
			"icon_index": COMMAND_ICON_QUEST,
			"callback": func() -> void: navigate("quest_board"),
			"primary": false,
			"locked": false,
			"section": "facility",
			"badge": quest_badge,
		},
		{
			"id": "cooking",
			"title": "調理場",
			"body": "魚を料理して食事にする",
			"icon_index": COMMAND_ICON_COOKING,
			"callback": func() -> void: navigate("cooking"),
			"primary": false,
			"locked": false,
			"section": "facility",
		},
		{
			"id": "market",
			"title": "魚市場",
			"body": "釣果を売って資金にする",
			"icon_index": COMMAND_ICON_MARKET,
			"callback": func() -> void: navigate("market"),
			"primary": false,
			"locked": false,
			"section": "facility",
			"badge": market_badge,
		},
		{
			"id": "shop",
			"title": "釣具店",
			"body": "竿を購入・装備する",
			"icon_index": COMMAND_ICON_SHOP,
			"callback": func() -> void: navigate("shop"),
			"primary": false,
			"locked": false,
			"section": "facility",
		},
		{
			"id": "shipyard",
			"title": "船着き場",
			"body": "船を購入して沖へ出る",
			"icon_index": COMMAND_ICON_SHIPYARD,
			"callback": func() -> void: navigate("shipyard"),
			"primary": false,
			"locked": false,
			"section": "facility",
		},
		{
			"id": "shark_pen",
			"title": "サメの生簀",
			"body": shark_pen_detail,
			"icon_index": COMMAND_ICON_SHARK,
			"callback": _open_shark_pen,
			"primary": false,
			"locked": shark_pen_locked,
			"section": "facility",
		},
		{
			"id": "status",
			"title": "ステータス",
			"body": "成長と装備を確認する",
			"icon_index": COMMAND_ICON_STATUS,
			"callback": func() -> void: navigate("status"),
			"primary": false,
			"locked": false,
			"section": "record",
		},
		{
			"id": "fish_book",
			"title": "魚図鑑",
			"body": "釣った魚の記録を見る",
			"icon_index": COMMAND_ICON_BOOK,
			"callback": func() -> void: navigate("fish_book"),
			"primary": false,
			"locked": false,
			"section": "record",
		},
		{
			"id": "title",
			"title": "タイトルへ戻る",
			"body": "進行を保存して戻る",
			"icon_index": COMMAND_ICON_BACK,
			"callback": _return_to_title,
			"primary": false,
			"locked": false,
			"section": "system",
		},
	]


func _build_facility_menu(root: Control) -> void:
	_operation_board_root = Control.new()
	_operation_board_root.name = "HarborOperationBoard"
	_operation_board_root.clip_contents = true
	_place_control_px(root, _operation_board_root, Rect2(844.0, 120.0, 396.0, 512.0))
	var fill := ColorRect.new()
	fill.color = _with_alpha(Palette.DARK_PANEL_DEEP, 0.86)
	fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_operation_board_root.add_child(fill)
	var frame := _nine_patch_rect(COMMON_HARBOR_COMMAND_DARK_FRAME_PATH, Vector4(12.0, 12.0, 12.0, 12.0))
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_operation_board_root.add_child(frame)

	_route_buttons.clear()
	_notification_badges.clear()
	_lock_icons.clear()
	var items := _facility_menu_items()

	var header := _harbor_label("港メニュー", 20, Palette.HARBOR_MENU_HEADER, true, 2, Palette.HARBOR_MENU_OUTLINE)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control_px(_operation_board_root, header, Rect2(20.0, 8.0, 170.0, 36.0))

	_settings_button = make_button("", func() -> void: navigate("settings", {"return_screen_id": "harbor"}))
	_settings_button.name = "HarborSettingsButton"
	_settings_button.custom_minimum_size = Vector2.ZERO
	_apply_command_button_skin(_settings_button, "compact")
	_place_control_px(_operation_board_root, _settings_button, Rect2(220.0, 20.0, 76.0, 28.0))
	_add_compact_command_content(_settings_button, "設定", 76.0)
	_build_command_route_button(
		_operation_board_root,
		_menu_item_by_id(items, "title"),
		Rect2(304.0, 20.0, 72.0, 28.0),
		"compact"
	)
	_build_command_route_button(
		_operation_board_root,
		_menu_item_by_id(items, "fishing_spots"),
		Rect2(20.0, 56.0, 356.0, 64.0),
		"cta"
	)

	_build_section_rule(_operation_board_root, "施設", 128.0)
	var facility_layout := [
		{"id": "quest_board", "rect": Rect2(20.0, 152.0, 174.0, 58.0)},
		{"id": "cooking", "rect": Rect2(202.0, 152.0, 174.0, 58.0)},
		{"id": "market", "rect": Rect2(20.0, 218.0, 174.0, 58.0)},
		{"id": "shop", "rect": Rect2(202.0, 218.0, 174.0, 58.0)},
		{"id": "shipyard", "rect": Rect2(20.0, 284.0, 174.0, 58.0)},
		{"id": "shark_pen", "rect": Rect2(202.0, 284.0, 174.0, 58.0)},
	]
	for entry in facility_layout:
		var route_rect: Rect2 = entry["rect"]
		_build_command_route_button(
			_operation_board_root,
			_menu_item_by_id(items, String(entry["id"])),
			route_rect,
			"tile"
		)

	_build_section_rule(_operation_board_root, "記録", 350.0)
	_build_command_route_button(
		_operation_board_root,
		_menu_item_by_id(items, "status"),
		Rect2(20.0, 374.0, 174.0, 42.0),
		"record"
	)
	_build_command_route_button(
		_operation_board_root,
		_menu_item_by_id(items, "fish_book"),
		Rect2(202.0, 374.0, 174.0, 42.0),
		"record"
	)
	_build_recommendation_panel(_operation_board_root, Rect2(20.0, 424.0, 356.0, 68.0))
	_wire_command_focus()
	var hint := _facility_menu_hint()
	_set_facility_detail(String(hint.get("title", "")), String(hint.get("body", "")), bool(hint.get("primary", true)))
	var primary := _route_buttons.get("fishing_spots", null) as Button
	if primary != null:
		primary.call_deferred("grab_focus")


func _menu_item_by_id(items: Array[Dictionary], id: String) -> Dictionary:
	for item in items:
		if String(item.get("id", "")) == id:
			return item
	return {}


func _build_section_rule(parent: Control, text: String, y: float) -> void:
	var label := _harbor_label(text, 11, Palette.HARBOR_CONTEXT_TEXT, true, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control_px(parent, label, Rect2(20.0, y, 54.0, 20.0))
	var rule := ColorRect.new()
	rule.color = _with_alpha(Palette.GOLD, 0.30)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control_px(parent, rule, Rect2(68.0, y + 10.0, 308.0, 1.0))


func _build_command_route_button(
	parent: Control, item: Dictionary, rect: Rect2, role: String
) -> Button:
	var id := String(item.get("id", ""))
	var title_text := String(item.get("title", ""))
	var body_text := String(item.get("body", ""))
	var callback: Callable = item.get("callback", Callable())
	var locked := bool(item.get("locked", false))
	var primary := bool(item.get("primary", false))
	var button := make_button("", callback)
	button.name = "HarborRoute_%s" % id
	button.set_meta("harbor_route_id", id)
	button.custom_minimum_size = Vector2.ZERO
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.clip_contents = true
	_apply_command_button_skin(button, role)
	_place_control_px(parent, button, rect)
	_route_buttons[id] = button
	if id == "fishing_spots":
		button.mouse_entered.connect(_restore_facility_hint)
		button.focus_entered.connect(_restore_facility_hint)
	else:
		button.mouse_entered.connect(func() -> void: _set_facility_detail(title_text, body_text, primary))
		button.focus_entered.connect(func() -> void: _set_facility_detail(title_text, body_text, primary))
	button.mouse_exited.connect(_restore_facility_hint)
	button.focus_exited.connect(_restore_facility_hint)

	var icon_index := int(item.get("icon_index", COMMAND_ICON_DEPARTURE))
	var text_color := Palette.HARBOR_FACILITY_PRIMARY_TEXT
	if role == "cta" or role == "compact":
		text_color = Palette.HARBOR_BUFF_NAME if role == "cta" else Palette.HARBOR_DETAIL_BODY_SECONDARY
	if locked:
		button.self_modulate = Palette.HARBOR_FACILITY_LOCKED_MODULATE
		text_color = Palette.HARBOR_DETAIL_BODY_SECONDARY

	if role == "cta":
		var icon_plate := Panel.new()
		icon_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_plate.add_theme_stylebox_override(
			"panel",
			_make_flat_panel_style(Palette.DARK_PANEL_DEEP, Palette.GOLD_DEEP, 8, 1)
		)
		_place_control_px(button, icon_plate, Rect2(8.0, 8.0, 48.0, 48.0))
		var icon := _command_icon_rect(icon_index)
		icon.modulate = Palette.GOLD_BRIGHT
		_place_control_px(button, icon, Rect2(16.0, 16.0, 32.0, 32.0))
		var caption := _harbor_label("出港する", 10, Palette.HARBOR_PARCHMENT_TITLE, true, 0)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_place_control_px(button, caption, Rect2(74.0, 8.0, 210.0, 20.0))
		var title := _harbor_label(title_text, 22, Palette.HARBOR_BUFF_NAME, true, 0)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_place_control_px(button, title, Rect2(74.0, 25.0, 244.0, 31.0))
		var arrow := _harbor_label("→", 25, Palette.HARBOR_PARCHMENT_TITLE, true, 0)
		arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_place_control_px(button, arrow, Rect2(318.0, 12.0, 28.0, 40.0))
	elif role == "compact":
		var compact_text := "タイトル" if id == "title" else title_text
		_add_compact_command_content(button, compact_text, rect.size.x)
	else:
		var icon_size := 24.0 if role == "record" else 26.0
		var icon_x := 10.0 if role == "record" else 15.0
		var icon_y := (rect.size.y - icon_size) * 0.5
		if role == "tile":
			var icon_plate := Panel.new()
			icon_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon_plate.add_theme_stylebox_override(
				"panel",
				_make_flat_panel_style(Palette.DARK_PANEL_DEEP, Palette.GOLD_DEEP, 7, 1)
			)
			_place_control_px(button, icon_plate, Rect2(8.0, 9.0, 40.0, 40.0))
			icon_x = 15.0
			icon_y = 16.0
		var icon := _command_icon_rect(icon_index)
		icon.modulate = Palette.HARBOR_FACILITY_LOCKED_MODULATE if locked else Palette.GOLD_BRIGHT
		_place_control_px(button, icon, Rect2(icon_x, icon_y, icon_size, icon_size))
		var title_x := 44.0 if role == "record" else 61.0
		var title := _harbor_label(title_text, 14 if role == "record" else 15, text_color, true, 1, Palette.HARBOR_MENU_OUTLINE)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_place_control_px(button, title, Rect2(title_x, 4.0, rect.size.x - title_x - 8.0, rect.size.y - 8.0))

	if locked:
		var lock_icon := _command_icon_rect(COMMAND_ICON_LOCK)
		lock_icon.modulate = Palette.GOLD_BRIGHT
		_place_control_px(button, lock_icon, Rect2(rect.size.x - 30.0, 9.0, 20.0, 20.0))
		_lock_icons[id] = lock_icon

	if bool(item.get("badge", false)):
		var badge_dot := Panel.new()
		badge_dot.name = "FacilityMenuBadge_%s" % title_text
		badge_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge_dot.add_theme_stylebox_override(
			"panel",
			_make_flat_panel_style(Palette.HARBOR_MENU_BADGE_FILL, Palette.HARBOR_MENU_BADGE_BORDER, 7, 2)
		)
		_place_control_px(parent, badge_dot, Rect2(rect.end.x - 18.0, rect.position.y + 4.0, 14.0, 14.0))
		_notification_badges[id] = badge_dot
	return button


func _add_compact_command_content(button: Button, text: String, width: float) -> Label:
	var label := _harbor_label(text, 12, Palette.HARBOR_DETAIL_BODY_SECONDARY, true, 0)
	label.name = "HarborCompactLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control_px(button, label, Rect2(6.0, 1.0, width - 12.0, 26.0))
	return label


func _build_recommendation_panel(parent: Control, rect: Rect2) -> void:
	var panel := Control.new()
	panel.name = "HarborRecommendation"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.clip_contents = true
	_place_control_px(parent, panel, rect)
	var frame := _nine_patch_rect(COMMON_HARBOR_COMMAND_DARK_FRAME_PATH, Vector4(12.0, 12.0, 12.0, 12.0))
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(frame)
	var accent := ColorRect.new()
	accent.color = Palette.HARBOR_FACILITY_ACCENT_PRIMARY
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control_px(panel, accent, Rect2(1.0, 2.0, 5.0, 64.0))
	_facility_detail_title_label = _harbor_label("", 12, Palette.HARBOR_MENU_HEADER, true, 1, Palette.HARBOR_MENU_OUTLINE)
	_facility_detail_title_label.name = "HarborRecommendationTitle"
	_facility_detail_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_facility_detail_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control_px(panel, _facility_detail_title_label, Rect2(18.0, 5.0, 320.0, 22.0))
	_facility_detail_body_label = _harbor_label("", 13, Palette.HARBOR_DETAIL_BODY_TEXT, true, 1, Palette.HARBOR_LABEL_OUTLINE)
	_facility_detail_body_label.name = "HarborRecommendationBody"
	_facility_detail_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_facility_detail_body_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control_px(panel, _facility_detail_body_label, Rect2(18.0, 27.0, 320.0, 34.0))


func _restore_facility_hint() -> void:
	var hint := _facility_menu_hint()
	_set_facility_detail(String(hint.get("title", "")), String(hint.get("body", "")), bool(hint.get("primary", true)))


func _wire_command_focus() -> void:
	var cta := _route_buttons.get("fishing_spots", null) as Button
	var title := _route_buttons.get("title", null) as Button
	var quest := _route_buttons.get("quest_board", null) as Button
	var cooking := _route_buttons.get("cooking", null) as Button
	var market := _route_buttons.get("market", null) as Button
	var shop := _route_buttons.get("shop", null) as Button
	var shipyard := _route_buttons.get("shipyard", null) as Button
	var shark := _route_buttons.get("shark_pen", null) as Button
	var status := _route_buttons.get("status", null) as Button
	var book := _route_buttons.get("fish_book", null) as Button
	_link_focus_horizontal(_settings_button, title)
	_link_focus_vertical(_settings_button, cta)
	_link_focus_vertical(title, cta)
	_link_focus_vertical(cta, quest)
	_link_focus_horizontal(quest, cooking)
	_link_focus_horizontal(market, shop)
	_link_focus_horizontal(shipyard, shark)
	_link_focus_horizontal(status, book)
	_link_focus_vertical(quest, market)
	_link_focus_vertical(market, shipyard)
	_link_focus_vertical(shipyard, status)
	_link_focus_vertical(cooking, shop)
	_link_focus_vertical(shop, shark)
	_link_focus_vertical(shark, book)
	var asa := _time_slot_buttons.get("asa_mazume", null) as Button
	var daytime := _time_slot_buttons.get("daytime", null) as Button
	var night := _time_slot_buttons.get("night", null) as Button
	_link_focus_horizontal(asa, daytime)
	_link_focus_horizontal(daytime, night)
	if cta != null and night != null:
		cta.focus_neighbor_left = cta.get_path_to(night)
		night.focus_neighbor_right = night.get_path_to(cta)


func _link_focus_horizontal(left: Control, right: Control) -> void:
	if left == null or right == null:
		return
	left.focus_neighbor_right = left.get_path_to(right)
	right.focus_neighbor_left = right.get_path_to(left)


func _link_focus_vertical(top: Control, bottom: Control) -> void:
	if top == null or bottom == null:
		return
	top.focus_neighbor_bottom = top.get_path_to(bottom)
	bottom.focus_neighbor_top = bottom.get_path_to(top)


func _set_facility_detail(title_text: String, body_text: String, primary := false) -> void:
	if _facility_detail_title_label == null or _facility_detail_body_label == null:
		return
	_facility_detail_title_label.text = title_text
	_facility_detail_body_label.text = body_text
	_facility_detail_title_label.add_theme_color_override("font_color", Palette.HARBOR_MENU_HEADER if primary else Palette.HARBOR_DETAIL_TITLE_SECONDARY)
	_facility_detail_body_label.add_theme_color_override("font_color", Palette.HARBOR_DETAIL_BODY_TEXT if primary else Palette.HARBOR_DETAIL_BODY_SECONDARY)


func _build_footer(root: Control) -> void:
	_footer_root = Control.new()
	_footer_root.name = "HarborFooter"
	_footer_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control_px(root, _footer_root, Rect2(40.0, 648.0, 1200.0, 48.0))
	var frame := _nine_patch_rect(COMMON_HARBOR_COMMAND_DARK_FRAME_PATH, Vector4(12.0, 12.0, 12.0, 12.0))
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_footer_root.add_child(frame)

	_status_label = _harbor_label("", 16, Palette.HARBOR_FOOTER_TEXT, true, 1, Palette.HARBOR_LABEL_OUTLINE)
	_status_label.name = "HarborCoolerStatus"
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control_px(_footer_root, _status_label, Rect2(24.0, 3.0, 500.0, 42.0))
	_play_time_label = _harbor_label("", 15, Palette.HARBOR_FOOTER_TEXT, true, 1, Palette.HARBOR_LABEL_OUTLINE)
	_play_time_label.name = "HarborPlayTime"
	_play_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_play_time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control_px(_footer_root, _play_time_label, Rect2(720.0, 3.0, 456.0, 42.0))


func _refresh_labels() -> void:
	_refresh_preparation_card()
	_refresh_info_board()
	var normalized_time_slot_id := String(
		GameData.get_time_slot(PlayerProgress.selected_time_slot_id).get("id", GameData.DEFAULT_TIME_SLOT_ID)
	)
	if not GameData.is_time_slot_unlocked(normalized_time_slot_id, PlayerProgress.level):
		normalized_time_slot_id = GameData.DEFAULT_TIME_SLOT_ID
	PlayerProgress.selected_time_slot_id = normalized_time_slot_id
	_refresh_time_slot_buttons()
	_refresh_time_slot_grade_overlay()
	var fish_total := _cooler_fish_total()
	if _player_status_bar != null:
		_player_status_bar.refresh()
	_context_label.text = "HARBOR COMMAND"
	_status_label.text = "クーラーボックス　%d匹" % fish_total
	_play_time_label.text = "プレイ時間　%s" % format_play_time(PlayerProgress.play_seconds)
	var has_pending_buff := not PlayerProgress.pending_buff.is_empty()
	_apply_meal_dependent_departure_layout(has_pending_buff)
	if _meal_effect_panel != null:
		_meal_effect_panel.visible = has_pending_buff
	if _meal_effect_row_label != null:
		_meal_effect_row_label.visible = has_pending_buff
	if _buff_name_label != null:
		_buff_name_label.visible = has_pending_buff
	if not has_pending_buff:
		if _buff_name_label != null:
			_buff_name_label.text = ""
	else:
		var buff_name := String(PlayerProgress.pending_buff.get("name", "料理"))
		var buff_text := String(PlayerProgress.pending_buff.get("text", ""))
		_buff_name_label.text = buff_name if buff_text.is_empty() else "%s　%s" % [buff_name, buff_text]
		_buff_name_label.add_theme_color_override("font_color", Palette.HARBOR_DETAIL_BODY_TEXT)


func _apply_meal_dependent_departure_layout(has_pending_buff: bool) -> void:
	if _plan_rumor_row == null:
		return
	var expanded := not has_pending_buff
	var rumor_height := 114.0 if expanded else 78.0
	var content_shift := 18.0 if expanded else 0.0
	_plan_rumor_row.size = Vector2(748.0, rumor_height)
	if _plan_rumor_icon != null:
		_plan_rumor_icon.position = Vector2(12.0, 23.0 + content_shift)
	if _plan_rumor_eyebrow_label != null:
		_plan_rumor_eyebrow_label.position = Vector2(52.0, 10.0 + content_shift)
	if _plan_rumor_label != null:
		_plan_rumor_label.position = Vector2(52.0, 32.0 + content_shift)
		_plan_rumor_label.size = Vector2(684.0, rumor_height - 38.0 - content_shift)


func _build_time_slot_grade_overlay() -> void:
	_time_slot_grade_overlay = ColorRect.new()
	_time_slot_grade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_time_slot_grade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_time_slot_grade_overlay)
	_refresh_time_slot_grade_overlay()


func _refresh_time_slot_grade_overlay() -> void:
	if _time_slot_grade_overlay == null:
		return
	var time_slot := GameData.get_time_slot(PlayerProgress.selected_time_slot_id)
	match String(time_slot.get("grade", "none")):
		"warm":
			_time_slot_grade_overlay.color = Palette.HARBOR_TIME_GRADE_WARM
		"cool":
			_time_slot_grade_overlay.color = Palette.HARBOR_TIME_GRADE_COOL
		_:
			_time_slot_grade_overlay.color = Palette.FISHING_TIME_GRADE_CLEAR


func _return_to_title() -> void:
	PlayerProgress.save_game()
	navigate("title")


func _add_vertical_rule(parent: Control, x: float) -> void:
	var rule := ColorRect.new()
	rule.color = _with_alpha(Palette.THEME_PANEL_INNER_GOLD, 0.40)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control_px(parent, rule, Rect2(x, 14.0, 1.0, 52.0))


func _place_control_px(parent: Control, control: Control, rect: Rect2) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.end.x
	control.offset_bottom = rect.end.y
	parent.add_child(control)


func _nine_patch_rect(path: String, margins: Vector4) -> NinePatchRect:
	var rect := NinePatchRect.new()
	rect.texture = _load_texture_if_exists(path)
	rect.patch_margin_left = int(margins.x)
	rect.patch_margin_top = int(margins.y)
	rect.patch_margin_right = int(margins.z)
	rect.patch_margin_bottom = int(margins.w)
	rect.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_STRETCH
	rect.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_STRETCH
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _command_icon_rect(icon_index: int) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = ShowcaseAssetsScript.atlas_icon(HARBOR_COMMAND_ICON_SHEET_PATH, 32.0, icon_index)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func _with_alpha(color: Color, alpha: float) -> Color:
	var result := color
	result.a = alpha
	return result


func _fit_label_font(label: Label, text: String, base_size: int, minimum_size: int, max_width: float) -> void:
	var font := GameFontsScript.extra_bold(get_theme_default_font())
	var outline := label.get_theme_constant("outline_size")
	var text_budget := maxf(max_width - float(outline * 2), 1.0)
	for font_size in range(base_size, minimum_size - 1, -1):
		if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x <= text_budget:
			label.add_theme_font_size_override("font_size", font_size)
			return
	label.add_theme_font_size_override("font_size", minimum_size)


func _apply_command_button_skin(button: Button, role: String) -> void:
	var style: StyleBoxTexture
	if role == "cta":
		style = _make_time_slot_button_style(COMMON_HARBOR_COMMAND_CTA_PATH)
	else:
		style = ShowcaseAssetsScript.texture_style(
			COMMON_HARBOR_COMMAND_DARK_FRAME_PATH,
			Vector4(12.0, 12.0, 12.0, 12.0),
			Vector4.ZERO
		)
	if style == null:
		return
	_apply_interactive_button_styles(button, style, role)
	button.add_theme_font_override("font", GameFontsScript.bold(get_theme_default_font()))
	button.add_theme_color_override("font_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_hover_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_pressed_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_disabled_color", Color.TRANSPARENT)
	button.add_theme_constant_override("outline_size", 0)
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func _apply_interactive_button_styles(button: Button, normal_style: StyleBoxTexture, role: String) -> void:
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override(
		"hover",
		_tinted_texture_style(normal_style, Palette.HARBOR_COMMAND_HOVER_MODULATE)
	)
	button.add_theme_stylebox_override(
		"pressed",
		_tinted_texture_style(normal_style, Palette.HARBOR_COMMAND_PRESSED_MODULATE)
	)
	button.add_theme_stylebox_override("focus", _make_command_focus_style(role))
	button.add_theme_stylebox_override("disabled", normal_style)


func _tinted_texture_style(source: StyleBoxTexture, tint: Color) -> StyleBoxTexture:
	var style := source.duplicate() as StyleBoxTexture
	style.modulate_color = tint
	return style


func _make_command_focus_style(role: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Palette.GOLD_BRIGHT
	var border_width := 3 if role == "cta" else 2
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	var radius := 10 if role == "cta" else 8
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style

func _texture_rect(path: String) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = _load_texture_if_exists(path)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _icon_rect(path: String) -> TextureRect:
	var icon := _texture_rect(path)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon


func _load_texture_if_exists(path: String) -> Texture2D:
	return ShowcaseAssetsScript.load_texture(path)


func _harbor_label(
	text: String,
	font_size: int,
	color: Color,
	bold := false,
	outline := 0,
	outline_color := Palette.HARBOR_LABEL_OUTLINE
) -> Label:
	return make_screen_label(text, font_size, color, bold, outline, outline_color, Palette.HARBOR_LABEL_SHADOW)


func _make_time_slot_button_style(path: String) -> StyleBoxTexture:
	var texture := _load_texture_if_exists(path)
	if texture == null:
		return null
	var style := StyleBoxTexture.new()
	style.texture = texture
	var margins := (
		Vector4(12.0, 12.0, 12.0, 12.0)
		if path == COMMON_HARBOR_COMMAND_DARK_FRAME_PATH
		else Vector4(18.0, 12.0, 18.0, 12.0)
	)
	style.texture_margin_left = margins.x
	style.texture_margin_top = margins.y
	style.texture_margin_right = margins.z
	style.texture_margin_bottom = margins.w
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.content_margin_left = 34.0
	style.content_margin_top = 4.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 4.0
	return style


func _make_flat_panel_style(
	bg_color: Color,
	border_color: Color,
	radius: int,
	border_width := 1
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.content_margin_left = 6.0
	style.content_margin_top = 4.0
	style.content_margin_right = 6.0
	style.content_margin_bottom = 4.0
	return style
