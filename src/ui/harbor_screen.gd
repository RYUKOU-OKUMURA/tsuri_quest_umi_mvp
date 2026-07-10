extends ScreenBase

const HarborBackdropScript = preload("res://src/ui/components/harbor_backdrop.gd")
const FightFishAssets = preload("res://src/ui/fight_fish_assets.gd")

const HARBOR_TOP_FRAME_PATH := "res://assets/showcase/harbor/harbor_top_frame.png"
const HARBOR_MAIN_FRAME_PATH := "res://assets/showcase/harbor/harbor_main_frame.png"
const HARBOR_MENU_FRAME_PATH := "res://assets/showcase/harbor/harbor_menu_frame.png"
const HARBOR_FOOTER_FRAME_PATH := "res://assets/showcase/harbor/harbor_footer_frame.png"
const HARBOR_INFO_BOARD_FRAME_PATH := "res://assets/showcase/harbor/harbor_info_board_frame.png"
const HARBOR_INFO_FISH_CARD_PATH := "res://assets/showcase/harbor/harbor_info_fish_card.png"
const HARBOR_PLAN_PANEL_PATH := "res://assets/showcase/harbor/harbor_plan_panel.png"
const HARBOR_PLAN_ICON_GUIDE_PATH := "res://assets/showcase/harbor/harbor_plan_icon_guide.png"
const HARBOR_PLAN_ICON_PIN_PATH := "res://assets/showcase/harbor/harbor_plan_icon_pin.png"
const HARBOR_PLAN_ICON_RUMOR_PATH := "res://assets/showcase/harbor/harbor_plan_icon_rumor.png"
const HARBOR_TIME_SLOT_BTN_NORMAL_PATH := "res://assets/showcase/harbor/harbor_time_slot_btn_normal.png"
const HARBOR_TIME_SLOT_BTN_SELECTED_PATH := "res://assets/showcase/harbor/harbor_time_slot_btn_selected.png"
const HARBOR_TIME_SLOT_BTN_LOCKED_PATH := "res://assets/showcase/harbor/harbor_time_slot_btn_locked.png"
const HARBOR_TIME_SLOT_ICON_ASA_PATH := "res://assets/showcase/harbor/harbor_time_slot_icon_asa.png"
const HARBOR_TIME_SLOT_ICON_DAY_PATH := "res://assets/showcase/harbor/harbor_time_slot_icon_day.png"
const HARBOR_TIME_SLOT_ICON_NIGHT_PATH := "res://assets/showcase/harbor/harbor_time_slot_icon_night.png"
const HARBOR_WEATHER_STUB_ICON_PATH := "res://assets/showcase/harbor/harbor_weather_stub_icon.png"
const HARBOR_BUTTON_PATH := "res://assets/showcase/harbor/harbor_facility_card.png"
const HARBOR_BUTTON_HOVER_PATH := "res://assets/showcase/harbor/harbor_facility_card_hover.png"
const HARBOR_BUTTON_PRIMARY_PATH := "res://assets/showcase/harbor/harbor_facility_card_primary.png"
const ICON_FISHING_PATH := "res://assets/showcase/common/nav_fishing_icon.png"
const ICON_COOKING_PATH := "res://assets/showcase/common/nav_cooking_icon.png"
const ICON_MARKET_PATH := "res://assets/showcase/common/nav_market_icon.png"
const ICON_SHOP_PATH := "res://assets/showcase/common/nav_shop_icon.png"
const ICON_SHIPYARD_PATH := "res://assets/showcase/common/nav_shipyard_icon.png"
const ICON_STATUS_PATH := "res://assets/showcase/common/nav_status_icon.png"
const ICON_TITLE_PATH := "res://assets/showcase/common/nav_title_icon.png"
const ICON_QUEST_PATH := "res://assets/showcase/common/nav_quest_icon.png"
const ICON_LOCK_PATH := "res://assets/showcase/common/nav_lock_icon.png"

var _status_label: Label
var _context_label: Label
var _top_level_label: Label
var _top_money_label: Label
var _top_rod_label: Label
var _top_exp_label: Label
var _buff_name_label: Label
var _facility_detail_title_label: Label
var _facility_detail_body_label: Label
var _preparation_body_label: Label
var _meal_effect_row_label: Label
var _plan_rows_root: Control
var _plan_guide_label: Label
var _plan_weather_label: Label
var _plan_pin_row: Control
var _plan_pin_label: Label
var _plan_rumor_row: Control
var _plan_rumor_label: Label
var _time_slot_zone_root: Control
var _info_board_root: Control
var _info_board_slots: Array[Dictionary] = []
var _time_slot_buttons: Dictionary = {}
var _time_slot_icons: Dictionary = {}
var _time_slot_grade_overlay: ColorRect


func _build_screen() -> void:
	var backdrop := HarborBackdropScript.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	move_child(backdrop, 0)
	_build_time_slot_grade_overlay()

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
	var top := _anchored_control(root, 0.020, 0.028, 0.980, 0.150)
	var frame := _texture_rect(HARBOR_TOP_FRAME_PATH)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top.add_child(frame)

	var location := _harbor_label("南の島・港", 32, Palette.HARBOR_LOCATION_TEXT, true, 4, Palette.HARBOR_LOCATION_OUTLINE)
	location.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	location.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(top, location, 0.026, 0.15, 0.265, 0.67)

	_context_label = _harbor_label("", 15, Palette.HARBOR_CONTEXT_TEXT, false, 2, Palette.HARBOR_LABEL_OUTLINE)
	_context_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_context_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(top, _context_label, 0.030, 0.62, 0.395, 0.92)

	_top_level_label = _top_metric(top, 0.395, 0.145, 0.485, 0.825, "Lv.1")
	_top_exp_label = _top_metric(top, 0.495, 0.145, 0.660, 0.825, "EXP 0 / 60")
	_top_money_label = _top_metric(top, 0.670, 0.145, 0.810, 0.825, "500 G")
	_top_rod_label = _top_metric(top, 0.820, 0.145, 0.972, 0.825, "入門竿")


func _build_main_panel(root: Control) -> void:
	var main := _anchored_control(root, 0.026, 0.170, 0.660, 0.882)
	var frame := _texture_rect(HARBOR_MAIN_FRAME_PATH)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.add_child(frame)

	_build_info_board(main)
	_build_departure_plan_card(main)
	_build_time_slot_zone(main)


func _build_info_board(main: Control) -> void:
	# 掲示板へ縦を譲るため、情報板は少し圧縮（完成イメージ v4 の面積配分）。
	_info_board_root = _anchored_control(main, 0.050, 0.035, 0.950, 0.305)
	var board_frame := _texture_rect(HARBOR_INFO_BOARD_FRAME_PATH)
	board_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_info_board_root.add_child(board_frame)

	var title := _harbor_label("本日の狙い目", 22, Palette.HARBOR_SCENE_TITLE, true, 3, Palette.HARBOR_SCENE_TITLE_OUTLINE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(_info_board_root, title, 0.050, 0.020, 0.950, 0.150)

	_info_board_slots.clear()
	var slot_left := 0.055
	var slot_width := 0.285
	var slot_gap := 0.025
	for index in range(3):
		var left := slot_left + float(index) * (slot_width + slot_gap)
		var slot := _anchored_control(_info_board_root, left, 0.160, left + slot_width, 0.970)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var card_bg := _texture_rect(HARBOR_INFO_FISH_CARD_PATH)
		card_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		slot.add_child(card_bg)

		var portrait := _icon_rect("")
		_place_control(slot, portrait, 0.080, 0.030, 0.920, 0.600)

		var name_label := _harbor_label("", 15, Palette.HARBOR_PARCHMENT_TITLE, true, 0)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.clip_text = true
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_place_control(slot, name_label, 0.050, 0.610, 0.950, 0.750)

		var badge_panel := Panel.new()
		badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge_panel.add_theme_stylebox_override(
			"panel",
			_make_flat_panel_style(Palette.HARBOR_INFO_BADGE_QUEST_FILL, Color.TRANSPARENT, 6, 0)
		)
		_place_control(slot, badge_panel, 0.100, 0.760, 0.900, 0.960)

		var badge_label := _harbor_label("", 12, Palette.HARBOR_INFO_BADGE_QUEST_TEXT, true, 1, Palette.HARBOR_LABEL_OUTLINE)
		badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge_label.clip_text = true
		badge_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_place_control(badge_panel, badge_label, 0.050, 0.080, 0.950, 0.920)

		_info_board_slots.append(
			{
				"slot": slot,
				"portrait": portrait,
				"name_label": name_label,
				"badge_panel": badge_panel,
				"badge_label": badge_label,
			}
		)


func _build_departure_plan_card(main: Control) -> void:
	# 時間帯を下端へ寄せた分、掲示板を縦に広げて行間・文字を読みやすくする。
	# 紙面は AI 一点物 PNG（StyleBoxFlat wash / ColorRect 区切りは使わない）。
	var card := _anchored_control(main, 0.050, 0.320, 0.950, 0.805)
	var panel := _texture_rect(HARBOR_PLAN_PANEL_PATH)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_child(panel)

	# ヘッダー帯は素材側。タイトルは runtime（日本語焼き込み禁止）。
	var title := _harbor_label("出港プラン", 17, Palette.HARBOR_SCENE_TITLE, true, 2, Palette.HARBOR_SCENE_TITLE_OUTLINE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(card, title, 0.095, 0.025, 0.940, 0.155)

	_preparation_body_label = _harbor_label("", 16, Palette.HARBOR_BUFF_BODY, true, 0)
	_preparation_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_preparation_body_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_preparation_body_label.clip_text = true
	_preparation_body_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_preparation_body_label.visible = false
	_place_control(card, _preparation_body_label, 0.100, 0.180, 0.950, 0.950)

	_plan_rows_root = _anchored_control(card, 0.040, 0.175, 0.960, 0.960)
	_plan_rows_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 4行を等間隔で広げ、余白を行の読みやすさに使う（区切り線は紙面の罫線に任せる）。
	var guide_row := _build_plan_content_row(_plan_rows_root, 0.000, 0.240, HARBOR_PLAN_ICON_GUIDE_PATH)
	_plan_guide_label = guide_row["label"] as Label
	var weather_row := _build_plan_content_row(_plan_rows_root, 0.250, 0.490, HARBOR_WEATHER_STUB_ICON_PATH)
	_plan_weather_label = weather_row["label"] as Label
	_plan_weather_label.text = "今日は雨の気配……潮目が立ちやすい"
	var pin_row := _build_plan_content_row(_plan_rows_root, 0.500, 0.740, HARBOR_PLAN_ICON_PIN_PATH)
	_plan_pin_row = pin_row["row"] as Control
	_plan_pin_label = pin_row["label"] as Label
	var rumor_row := _build_plan_content_row(_plan_rows_root, 0.750, 0.990, HARBOR_PLAN_ICON_RUMOR_PATH, true)
	_plan_rumor_row = rumor_row["row"] as Control
	_plan_rumor_label = rumor_row["label"] as Label


func _build_plan_content_row(
	parent: Control, top: float, bottom: float, icon_path: String, allow_wrap := false
) -> Dictionary:
	var row := _anchored_control(parent, 0.000, top, 1.000, bottom)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := _icon_rect(icon_path)
	_place_control(row, icon, 0.015, 0.080, 0.105, 0.920)
	var label := _harbor_label("", 16, Palette.HARBOR_BUFF_BODY, true, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if allow_wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.clip_text = false
		label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	else:
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_place_control(row, label, 0.125, 0.060, 0.980, 0.940)
	return {"row": row, "label": label}


func _build_time_slot_zone(main: Control) -> void:
	# 完成イメージどおり下端へ寄せ、ゾーン内の上下空きを潰す。
	_time_slot_zone_root = _anchored_control(main, 0.050, 0.820, 0.950, 0.985)
	_time_slot_zone_root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# メイン枠の暗い地の上なので、羊皮紙用の茶ではなく明るいラベル色を使う。
	var time_label := _harbor_label("時間帯", 12, Palette.HARBOR_SCENE_TITLE, true, 2, Palette.HARBOR_SCENE_TITLE_OUTLINE)
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(_time_slot_zone_root, time_label, 0.015, 0.020, 0.145, 0.280)

	# ボタンをゾーンの大半に密着させ、下の食事効果だけ薄く残す。
	_build_time_slot_selector(_time_slot_zone_root, 0.040, 0.700)

	_meal_effect_row_label = _harbor_label("食事効果", 11, Palette.HARBOR_SCENE_TEXT, true, 1, Palette.HARBOR_SCENE_TEXT_OUTLINE)
	_meal_effect_row_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_meal_effect_row_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(_time_slot_zone_root, _meal_effect_row_label, 0.015, 0.740, 0.145, 0.980)

	_buff_name_label = _harbor_label("", 12, Palette.HARBOR_SCENE_TEXT, false, 1, Palette.HARBOR_SCENE_TEXT_OUTLINE)
	_buff_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_buff_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_buff_name_label.clip_text = true
	_buff_name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_place_control(_time_slot_zone_root, _buff_name_label, 0.155, 0.740, 0.985, 0.980)


func _make_plan_row_button(text: String, callback: Callable) -> Button:
	var button := make_button(text, callback, 0.0, false)
	# 行の高さ（約38px）が make_button の最小高 50px を下回るため、行からのはみ出しを防ぐ。
	button.custom_minimum_size = Vector2.ZERO
	button.add_theme_font_size_override("font_size", 13)
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return button


func _build_time_slot_selector(card: Control, top: float, bottom: float) -> void:
	var ids := GameData.get_all_time_slot_ids()
	var left := 0.170
	var right := 0.980
	var gap := 0.016
	var width := (right - left - gap * float(ids.size() - 1)) / float(ids.size())
	for index in range(ids.size()):
		var time_slot_id := String(ids[index])
		var button := _make_plan_row_button("", _select_time_slot.bind(time_slot_id))
		button.add_theme_font_size_override("font_size", 16)
		_apply_time_slot_button_defaults(button)
		_time_slot_buttons[time_slot_id] = button
		var icon := _icon_rect(_time_slot_icon_path(time_slot_id))
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place_control(button, icon, 0.040, 0.100, 0.340, 0.900)
		_time_slot_icons[time_slot_id] = icon
		var x0 := left + float(index) * (width + gap)
		_place_control(card, button, x0, top, x0 + width, bottom)


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
	button.add_theme_color_override("font_color", dark_text)
	button.add_theme_color_override("font_hover_color", dark_text)
	button.add_theme_color_override("font_pressed_color", dark_text)
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


func _preparation_card_text() -> String:
	var megalodon_omen := _megalodon_omen_text()
	if not megalodon_omen.is_empty():
		return megalodon_omen
	var lines: Array[String] = []
	var guide_text := _beginner_guide_text()
	lines.append(guide_text if not guide_text.is_empty() else _target_hint_text())
	lines.append("今日は雨の気配……潮目が立ちやすい")
	var third_parts: Array[String] = []
	var candidates := _harbor_highlight_candidates(1)
	if not candidates.is_empty():
		var spot_id := String(candidates[0].get("spot_id", ""))
		if not spot_id.is_empty():
			var spot_name := String(GameData.get_fishing_spot(spot_id).get("name", spot_id))
			third_parts.append("狙いポイント：%s" % spot_name)
	var nushi_hint := _nushi_hint_text()
	if not nushi_hint.is_empty():
		third_parts.append("目撃談：%s" % nushi_hint)
	if not third_parts.is_empty():
		lines.append("　".join(third_parts))
	return "\n".join(lines)


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
		if progress.is_empty() or bool(progress.get("completed", true)):
			continue
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


func _quest_target_hint_text() -> String:
	for candidate in _harbor_highlight_candidates(3):
		if String(candidate.get("reason", "")) == "quest":
			return String(candidate.get("hint_text", ""))
	return ""


func _time_slot_boost_hint_text() -> String:
	for candidate in _harbor_highlight_candidates(3):
		if String(candidate.get("reason", "")) == "time_boost":
			return String(candidate.get("hint_text", ""))
	return ""


func _uncaught_sighting_hint_text() -> String:
	for candidate in _harbor_highlight_candidates(3):
		if String(candidate.get("reason", "")) == "uncaught":
			return String(candidate.get("hint_text", ""))
	return ""


func _target_hint_text() -> String:
	var candidates := _harbor_highlight_candidates(1)
	if candidates.is_empty():
		return "海は穏やか。どこへ出ても釣り日和だ"
	return String(candidates[0].get("hint_text", "海は穏やか。どこへ出ても釣り日和だ"))


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
	if _preparation_body_label != null:
		_preparation_body_label.text = _preparation_card_text()
	var megalodon_omen := not _megalodon_omen_text().is_empty()
	if _plan_rows_root != null:
		_plan_rows_root.visible = not megalodon_omen
	if _preparation_body_label != null:
		_preparation_body_label.visible = megalodon_omen
	if megalodon_omen:
		return
	var guide_text := _beginner_guide_text()
	_plan_guide_label.text = guide_text if not guide_text.is_empty() else _target_hint_text()
	_plan_weather_label.text = "今日は雨の気配……潮目が立ちやすい"
	var pin_text := ""
	var candidates := _harbor_highlight_candidates(1)
	if not candidates.is_empty():
		var spot_id := String(candidates[0].get("spot_id", ""))
		if not spot_id.is_empty():
			var spot_name := String(GameData.get_fishing_spot(spot_id).get("name", spot_id))
			pin_text = "狙いポイント：%s" % spot_name
	_plan_pin_label.text = pin_text
	_plan_pin_row.visible = not pin_text.is_empty()
	var rumor_text := _nushi_hint_text()
	if rumor_text.is_empty():
		_plan_rumor_row.visible = false
	else:
		_plan_rumor_label.text = "目撃談：%s" % rumor_text
		_plan_rumor_row.visible = true


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
		var reason := String(candidate.get("reason", ""))
		badge_label.text = String(candidate.get("reason_label", ""))
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
		var style_path := HARBOR_TIME_SLOT_BTN_NORMAL_PATH
		if locked:
			style_path = HARBOR_TIME_SLOT_BTN_LOCKED_PATH
		elif selected:
			style_path = HARBOR_TIME_SLOT_BTN_SELECTED_PATH
		var style := _make_time_slot_button_style(style_path)
		if style != null:
			button.add_theme_stylebox_override("normal", style)
			button.add_theme_stylebox_override("hover", style)
			button.add_theme_stylebox_override("pressed", style)
			button.add_theme_stylebox_override("focus", style)
			button.add_theme_stylebox_override("disabled", style)
		var icon := _time_slot_icons.get(time_slot_id, null) as TextureRect
		if icon != null:
			icon.modulate = Palette.HARBOR_ICON_MODULATE if not locked else Color(0.72, 0.72, 0.72, 0.72)


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


## 右メニュー「A案: セクション見出し付き4グループ」のレイアウト定数。
## メニュー枠は約383x513px（root比率 0.675-0.974 / 0.170-0.882）。
## 値はメニュー矩形の高さに対する比率で、pxコメントはメニュー高513pxでの目安。
const FACILITY_MENU_CONTENT_TOP := 0.128          # 施設ヘッダー直下の開始位置
const FACILITY_MENU_ROW_GAP := 0.0098             # ボタン間ギャップ 約5px
const FACILITY_MENU_SECTION_GAP_BEFORE := 0.0117  # 見出し直前の空き 約6px
const FACILITY_MENU_SECTION_GAP_AFTER := 0.0059   # 見出し直後の空き 約3px
const FACILITY_MENU_HEADING_HEIGHT := 0.0273      # 見出し行 約14px
const FACILITY_MENU_DEPARTURE_HEIGHT := 0.0702    # primary行 約36px
const FACILITY_MENU_NORMAL_HEIGHT := 0.0526       # 通常行 約27px
const FACILITY_MENU_SYSTEM_HEIGHT := 0.0468      # システム小型ボタン 約24px
const FACILITY_MENU_DETAIL_GAP := 0.0156          # 最終行と詳細パネルの空き 約8px（最低でも約4pxの可視ギャップを保証）
const FACILITY_MENU_DETAIL_MIN_HEIGHT := 0.1000   # 詳細パネル最低高さ（2行本文が収まる目安）
const FACILITY_MENU_DETAIL_BOTTOM_MARGIN := 0.0156 # 詳細パネル下端とメニュー枠下端の余白

## セクション定義（表示順・見出しテキスト・ボタン高さ）。空文字は見出しなし。
const FACILITY_MENU_SECTION_DEFS := {
	"departure": {"heading": "", "height": FACILITY_MENU_DEPARTURE_HEIGHT},
	"facility": {"heading": "施設", "height": FACILITY_MENU_NORMAL_HEIGHT},
	"record": {"heading": "記録", "height": FACILITY_MENU_NORMAL_HEIGHT},
	"system": {"heading": "システム", "height": FACILITY_MENU_SYSTEM_HEIGHT},
}


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
			"icon_path": ICON_FISHING_PATH,
			"callback": func() -> void: navigate("fishing_spots"),
			"primary": true,
			"locked": false,
			"section": "departure",
		},
		{
			"id": "quest_board",
			"title": "依頼ボード",
			"body": "釣果を届けて報酬を受け取る",
			"icon_path": ICON_QUEST_PATH,
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
			"icon_path": ICON_COOKING_PATH,
			"callback": func() -> void: navigate("cooking"),
			"primary": false,
			"locked": false,
			"section": "facility",
		},
		{
			"id": "market",
			"title": "魚市場",
			"body": "釣果を売って資金にする",
			"icon_path": ICON_MARKET_PATH,
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
			"icon_path": ICON_SHOP_PATH,
			"callback": func() -> void: navigate("shop"),
			"primary": false,
			"locked": false,
			"section": "facility",
		},
		{
			"id": "shipyard",
			"title": "船着き場",
			"body": "船を購入して沖へ出る",
			"icon_path": ICON_SHIPYARD_PATH,
			"callback": func() -> void: navigate("shipyard"),
			"primary": false,
			"locked": false,
			"section": "facility",
		},
		{
			"id": "shark_pen",
			"title": "サメの生簀",
			"body": shark_pen_detail,
			"icon_path": FightFishAssets.card_portrait_path({"id": "nekozame"}),
			"callback": _open_shark_pen,
			"primary": false,
			"locked": shark_pen_locked,
			"section": "facility",
		},
		{
			"id": "status",
			"title": "ステータス",
			"body": "成長と装備を確認する",
			"icon_path": ICON_STATUS_PATH,
			"callback": func() -> void: navigate("status"),
			"primary": false,
			"locked": false,
			"section": "record",
		},
		{
			"id": "fish_book",
			"title": "魚図鑑",
			"body": "釣った魚の記録を見る",
			"icon_path": FightFishAssets.card_portrait_path({"id": "aji"}),
			"callback": func() -> void: navigate("fish_book"),
			"primary": false,
			"locked": false,
			"section": "record",
		},
		{
			"id": "title",
			"title": "タイトルへ戻る",
			"body": "進行を保存して戻る",
			"icon_path": ICON_TITLE_PATH,
			"callback": _return_to_title,
			"primary": false,
			"locked": false,
			"section": "system",
		},
	]


func _build_facility_menu(root: Control) -> void:
	var menu := _anchored_control(root, 0.675, 0.170, 0.974, 0.882)
	var frame := _texture_rect(HARBOR_MENU_FRAME_PATH)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(frame)

	var header := _harbor_label("港の施設", 27, Palette.HARBOR_MENU_HEADER, true, 3, Palette.HARBOR_MENU_OUTLINE)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(menu, header, 0.100, 0.030, 0.900, 0.120)

	var content_bottom := _build_facility_menu_rows(menu, _facility_menu_items())
	_build_facility_detail_panel(menu, content_bottom)
	var hint := _facility_menu_hint()
	_set_facility_detail(String(hint.get("title", "")), String(hint.get("body", "")), bool(hint.get("primary", true)))


## セクション定義から行位置を動的算出して配置する（row_step*indexのハードコード復活は禁止）。
## 戻り値はセクション全体を配置し終えた後のy位置（詳細パネルの起点計算に使う）。
## 縦が足りない場合は「ギャップ→行高」の順で比例圧縮して必ず枠内に収める。
## 詳細パネルを最終ボタンの上へ食い込ませる方向のフォールバックは行わない。
func _build_facility_menu_rows(menu: Control, items: Array[Dictionary]) -> float:
	var grouped: Dictionary = {}
	var section_order: Array[String] = []
	for item in items:
		var section_id := String(item.get("section", "facility"))
		if not grouped.has(section_id):
			grouped[section_id] = []
			section_order.append(section_id)
		(grouped[section_id] as Array).append(item)

	# 1パス目: 必要な高さを集計し、圧縮係数（ギャップ優先→行高）を決める。
	var rows_height := 0.0
	var headings_height := 0.0
	var gaps_total := 0.0
	for section_id in section_order:
		var section_def: Dictionary = FACILITY_MENU_SECTION_DEFS.get(
			section_id, {"heading": "", "height": FACILITY_MENU_NORMAL_HEIGHT}
		)
		if not String(section_def.get("heading", "")).is_empty():
			headings_height += FACILITY_MENU_HEADING_HEIGHT
			gaps_total += FACILITY_MENU_SECTION_GAP_BEFORE + FACILITY_MENU_SECTION_GAP_AFTER
		var count := (grouped[section_id] as Array).size()
		rows_height += float(section_def.get("height", FACILITY_MENU_NORMAL_HEIGHT)) * float(count)
		gaps_total += FACILITY_MENU_ROW_GAP * float(maxi(count - 1, 0))

	var available := (
		1.0
		- FACILITY_MENU_CONTENT_TOP
		- FACILITY_MENU_DETAIL_GAP
		- FACILITY_MENU_DETAIL_MIN_HEIGHT
		- FACILITY_MENU_DETAIL_BOTTOM_MARGIN
	)
	var gap_scale := 1.0
	var height_scale := 1.0
	var solid_height := rows_height + headings_height
	if solid_height + gaps_total > available and gaps_total > 0.0:
		gap_scale = clampf((available - solid_height) / gaps_total, 0.0, 1.0)
	if solid_height + gaps_total * gap_scale > available and solid_height > 0.0:
		height_scale = clampf((available - gaps_total * gap_scale) / solid_height, 0.5, 1.0)

	# 2パス目: 圧縮係数を反映して配置。
	var y := FACILITY_MENU_CONTENT_TOP
	for section_id in section_order:
		var section_def: Dictionary = FACILITY_MENU_SECTION_DEFS.get(
			section_id, {"heading": "", "height": FACILITY_MENU_NORMAL_HEIGHT}
		)
		var heading_text := String(section_def.get("heading", ""))
		if not heading_text.is_empty():
			y += FACILITY_MENU_SECTION_GAP_BEFORE * gap_scale
			_build_section_heading(menu, y, heading_text, FACILITY_MENU_HEADING_HEIGHT * height_scale)
			y += FACILITY_MENU_HEADING_HEIGHT * height_scale + FACILITY_MENU_SECTION_GAP_AFTER * gap_scale

		var row_height := float(section_def.get("height", FACILITY_MENU_NORMAL_HEIGHT)) * height_scale
		var section_items: Array = grouped[section_id]
		for index in range(section_items.size()):
			var item: Dictionary = section_items[index]
			_build_facility_button(
				menu,
				y,
				String(item["title"]),
				String(item["body"]),
				String(item["icon_path"]),
				item["callback"] as Callable,
				bool(item["primary"]),
				row_height,
				bool(item["locked"]),
				bool(item.get("badge", false))
			)
			y += row_height
			if index < section_items.size() - 1:
				y += FACILITY_MENU_ROW_GAP * gap_scale
	return y


## セクション見出し（暗めブロンズのラベル＋右側の薄い同系ヘアライン1px）。日本語はruntime描画のみ。
## メニュー内部のクリーム地に対して暗色文字で置くため、アウトラインは付けない。
func _build_section_heading(menu: Control, top: float, text: String, height := FACILITY_MENU_HEADING_HEIGHT) -> void:
	var row := _anchored_control(menu, 0.088, top, 0.912, top + height)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var label := _harbor_label(text, 12, Palette.HARBOR_MENU_SECTION_LABEL, true, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# 字間広め（見出しは装飾でなくグループ境界を示す情報）。FontVariationでグリフ間隔を広げる。
	var spaced_font := FontVariation.new()
	spaced_font.base_font = GameFontsScript.bold(get_theme_default_font())
	spaced_font.spacing_glyph = 2
	label.add_theme_font_override("font", spaced_font)
	label.clip_text = true
	_place_control(row, label, 0.0, 0.0, 0.320, 1.0)

	var hairline := ColorRect.new()
	hairline.color = Palette.HARBOR_MENU_SECTION_HAIRLINE
	hairline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(row, hairline, 0.345, 0.460, 1.0, 0.540)


func _build_facility_detail_panel(parent: Control, content_bottom: float) -> void:
	# MIN_HEIGHT の確保は行側の圧縮（_build_facility_menu_rows）が担う。
	# パネルを最終行の上へ動かすことは重なり禁止のため行わない。
	var panel_top := content_bottom + FACILITY_MENU_DETAIL_GAP
	var panel_bottom := 1.0 - FACILITY_MENU_DETAIL_BOTTOM_MARGIN

	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 本文が想定外に折り返してもパネル外（メニュー枠外）へ漏れないよう保険で切り抜く。
	panel.clip_contents = true
	panel.add_theme_stylebox_override(
		"panel",
		_make_flat_panel_style(Palette.HARBOR_DETAIL_PANEL_FILL, Palette.HARBOR_DETAIL_PANEL_BORDER, 8, 2)
	)
	_place_control(parent, panel, 0.088, panel_top, 0.912, panel_bottom)

	_facility_detail_title_label = _harbor_label("", 15, Palette.HARBOR_MENU_HEADER, true, 2, Palette.HARBOR_MENU_OUTLINE)
	_facility_detail_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_facility_detail_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_facility_detail_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(panel, _facility_detail_title_label, 0.055, 0.090, 0.945, 0.400)

	_facility_detail_body_label = _harbor_label("", 13, Palette.HARBOR_DETAIL_BODY_TEXT, false, 1, Palette.HARBOR_LABEL_OUTLINE)
	_facility_detail_body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_facility_detail_body_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_facility_detail_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_facility_detail_body_label.clip_text = false
	_facility_detail_body_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_facility_detail_body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(panel, _facility_detail_body_label, 0.055, 0.420, 0.945, 0.920)


func _build_facility_button(
	parent: Control,
	top: float,
	title_text: String,
	body_text: String,
	icon_path: String,
	callback: Callable,
	primary := false,
	height := 0.108,
	locked := false,
	badge := false
) -> void:
	# ボタン内の各要素比率（ボタンのローカル矩形に対する 0.0-1.0 の相対位置）。値は現行から不変。
	const BUTTON_H_MARGIN := 0.088
	const BUTTON_H_MARGIN_RIGHT := 0.912
	const ACCENT_LEFT := 0.023
	const ACCENT_TOP := 0.230
	const ACCENT_RIGHT := 0.039
	const ACCENT_BOTTOM := 0.770
	const ICON_PLATE_LEFT := 0.055
	const ICON_PLATE_TOP := 0.160
	const ICON_PLATE_RIGHT := 0.165
	const ICON_PLATE_BOTTOM := 0.840
	const ICON_LEFT := 0.070
	const ICON_TOP := 0.210
	const ICON_RIGHT := 0.150
	const ICON_BOTTOM := 0.790
	const TITLE_LEFT := 0.205
	const TITLE_TOP := 0.120
	const TITLE_RIGHT_UNLOCKED := 0.900
	const TITLE_RIGHT_WITH_LOCK_ICON := 0.775
	const TITLE_BOTTOM := 0.880
	const TITLE_FONT_SIZE_COMPACT := 19
	const TITLE_FONT_SIZE_NORMAL := 21
	const TITLE_FONT_SIZE_SMALL := 16
	const COMPACT_HEIGHT_THRESHOLD := 0.064
	const SMALL_HEIGHT_THRESHOLD := 0.050
	# ロック錠前アイコン（右端。旧8px条件テキストの代わり。解放条件は詳細パネルのbodyへ集約）。
	# 縦0.18-0.82（27px行で約17px）。減光の影響を受けず視認できるサイズを確保する。
	const LOCK_ICON_LEFT := 0.790
	const LOCK_ICON_TOP := 0.180
	const LOCK_ICON_RIGHT := 0.905
	const LOCK_ICON_BOTTOM := 0.820
	# 通知バッジ（直径11pxの丸。ボタン右上角に完全収まる固定px矩形）。
	# `parent`（メニュー）へ配置しボタンのclip_contentsの影響を受けないようにする。
	const BADGE_DIAMETER := 11.0
	const BADGE_INSET_RIGHT := 5.0
	const BADGE_INSET_TOP := 4.0

	var button := make_button("", callback)
	button.custom_minimum_size = Vector2.ZERO
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.focus_mode = Control.FOCUS_ALL
	button.clip_contents = true
	_apply_facility_button_skin(button, primary)
	if locked:
		# ロック中はスキンのみ減光（self_modulate。子の錠前アイコンへは伝播させない）。
		# 解放条件は詳細パネルのbodyへ集約（行内の8pxテキストは廃止）。
		button.self_modulate = Palette.HARBOR_FACILITY_LOCKED_MODULATE
	_place_control(parent, button, BUTTON_H_MARGIN, top, BUTTON_H_MARGIN_RIGHT, top + height)
	button.mouse_entered.connect(func() -> void: _set_facility_detail(title_text, body_text, primary))
	button.focus_entered.connect(func() -> void: _set_facility_detail(title_text, body_text, primary))

	var accent := Panel.new()
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	accent.add_theme_stylebox_override(
		"panel",
		_make_flat_panel_style(Palette.HARBOR_FACILITY_ACCENT_PRIMARY if primary else Palette.HARBOR_FACILITY_ACCENT_SECONDARY, Color.TRANSPARENT, 3, 0)
	)
	if locked:
		accent.modulate = Palette.HARBOR_FACILITY_LOCKED_MODULATE
	_place_control(button, accent, ACCENT_LEFT, ACCENT_TOP, ACCENT_RIGHT, ACCENT_BOTTOM)

	var icon_plate := Panel.new()
	icon_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_plate.add_theme_stylebox_override(
		"panel",
		_make_flat_panel_style(
			Palette.HARBOR_FACILITY_ICON_PRIMARY_FILL if primary else Palette.HARBOR_FACILITY_ICON_SECONDARY_FILL,
			Palette.HARBOR_FACILITY_ICON_PRIMARY_BORDER if primary else Palette.HARBOR_FACILITY_ICON_SECONDARY_BORDER,
			6,
			1
		)
	)
	if locked:
		icon_plate.modulate = Palette.HARBOR_FACILITY_LOCKED_MODULATE
	_place_control(button, icon_plate, ICON_PLATE_LEFT, ICON_PLATE_TOP, ICON_PLATE_RIGHT, ICON_PLATE_BOTTOM)

	var icon := _icon_rect(icon_path)
	# ロック中はメインアイコンも個別に減光する（錠前アイコンには適用しない）。
	icon.modulate = Palette.HARBOR_FACILITY_LOCKED_MODULATE if locked else Palette.HARBOR_ICON_MODULATE
	_place_control(button, icon, ICON_LEFT, ICON_TOP, ICON_RIGHT, ICON_BOTTOM)

	var title_font_size := TITLE_FONT_SIZE_NORMAL
	if height < COMPACT_HEIGHT_THRESHOLD:
		title_font_size = TITLE_FONT_SIZE_SMALL if height < SMALL_HEIGHT_THRESHOLD else TITLE_FONT_SIZE_COMPACT
	var title_color := (
		Palette.HARBOR_DETAIL_BODY_SECONDARY
		if locked
		else (Palette.HARBOR_FACILITY_PRIMARY_TEXT if primary else Palette.HARBOR_FACILITY_SECONDARY_TEXT)
	)
	var title := _harbor_label(title_text, title_font_size, title_color, true, 2 if primary else 1, Palette.HARBOR_FACILITY_PRIMARY_OUTLINE if primary else Palette.HARBOR_FACILITY_SECONDARY_OUTLINE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.clip_text = true
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(button, title, TITLE_LEFT, TITLE_TOP, TITLE_RIGHT_WITH_LOCK_ICON if locked else TITLE_RIGHT_UNLOCKED, TITLE_BOTTOM)

	if locked:
		var lock_icon := _icon_rect(ICON_LOCK_PATH)
		lock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place_control(button, lock_icon, LOCK_ICON_LEFT, LOCK_ICON_TOP, LOCK_ICON_RIGHT, LOCK_ICON_BOTTOM)

	if badge:
		# ボタンではなくメニュー（parent）の子にして clip_contents の影響を避ける。
		# アンカーをボタン右上角の1点（BUTTON_H_MARGIN_RIGHT, top）に固定し、
		# offsetで直径11pxの丸をボタン内側へ収める（px指定なのでボタン高さに依存しない）。
		var badge_dot := Panel.new()
		# add_child() は同名衝突時に既定で読みにくい内部名（@Panel@id等）へ差し替えるため、
		# 行ごとに一意な名前を明示して衝突を避ける（複数バッジ同時表示時の取得・カウント対策）。
		badge_dot.name = "FacilityMenuBadge_%s" % title_text
		badge_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge_dot.anchor_left = BUTTON_H_MARGIN_RIGHT
		badge_dot.anchor_right = BUTTON_H_MARGIN_RIGHT
		badge_dot.anchor_top = top
		badge_dot.anchor_bottom = top
		badge_dot.offset_left = -(BADGE_INSET_RIGHT + BADGE_DIAMETER)
		badge_dot.offset_right = -BADGE_INSET_RIGHT
		badge_dot.offset_top = BADGE_INSET_TOP
		badge_dot.offset_bottom = BADGE_INSET_TOP + BADGE_DIAMETER
		badge_dot.add_theme_stylebox_override(
			"panel",
			_make_flat_panel_style(Palette.HARBOR_MENU_BADGE_FILL, Palette.HARBOR_MENU_BADGE_BORDER, 6, 2)
		)
		parent.add_child(badge_dot)


func _set_facility_detail(title_text: String, body_text: String, primary := false) -> void:
	if _facility_detail_title_label == null or _facility_detail_body_label == null:
		return
	_facility_detail_title_label.text = title_text
	_facility_detail_body_label.text = body_text
	_facility_detail_title_label.add_theme_color_override("font_color", Palette.HARBOR_MENU_HEADER if primary else Palette.HARBOR_DETAIL_TITLE_SECONDARY)
	_facility_detail_body_label.add_theme_color_override("font_color", Palette.HARBOR_DETAIL_BODY_TEXT if primary else Palette.HARBOR_DETAIL_BODY_SECONDARY)


func _build_footer(root: Control) -> void:
	var footer := _anchored_control(root, 0.026, 0.902, 0.974, 0.974)
	var frame := _texture_rect(HARBOR_FOOTER_FRAME_PATH)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	footer.add_child(frame)

	_status_label = _harbor_label("", 17, Palette.HARBOR_FOOTER_TEXT, false, 2, Palette.HARBOR_LABEL_OUTLINE)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(footer, _status_label, 0.035, 0.050, 0.965, 0.950)


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
	var next_text := (
		"MAX"
		if PlayerProgress.level >= GameData.MAX_LEVEL
		else "%d / %d EXP" % [PlayerProgress.exp, PlayerProgress.exp_to_next_level()]
	)
	var rod_name := String(GameData.get_rod(PlayerProgress.equipped_rod_id).get("name", "入門竿"))
	_top_level_label.text = "Lv.%d" % PlayerProgress.level
	_top_exp_label.text = "EXP %s" % next_text.replace(" EXP", "")
	_top_money_label.text = "%s G" % ScreenBase.format_money(PlayerProgress.money)
	_top_rod_label.text = rod_name
	_context_label.text = "時間帯：%s" % String(
		GameData.get_time_slot(PlayerProgress.selected_time_slot_id).get("name", "日中")
	)
	_status_label.text = (
		"クーラーボックス：%d匹　｜　プレイ時間：%s"
		% [
			fish_total,
			format_play_time(PlayerProgress.play_seconds),
		]
	)
	var has_pending_buff := not PlayerProgress.pending_buff.is_empty()
	if _meal_effect_row_label != null:
		_meal_effect_row_label.visible = has_pending_buff
	_buff_name_label.visible = has_pending_buff
	if not has_pending_buff:
		_buff_name_label.text = ""
	else:
		var buff_name := String(PlayerProgress.pending_buff.get("name", "料理"))
		var buff_text := String(PlayerProgress.pending_buff.get("text", ""))
		_buff_name_label.text = buff_name if buff_text.is_empty() else "%s（%s）" % [buff_name, buff_text]
		_buff_name_label.add_theme_color_override("font_color", Palette.GOLD_BRIGHT)
		_buff_name_label.add_theme_font_size_override("font_size", 14)


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


func _top_metric(parent: Control, left: float, top: float, right: float, bottom: float, value: String) -> Label:
	var label := _harbor_label(value, 17, Palette.HARBOR_TOP_METRIC_TEXT, true, 2, Palette.HARBOR_LABEL_OUTLINE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(parent, label, left, top, right, bottom)
	return label

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
	if ResourceLoader.exists(path) or FileAccess.file_exists(path):
		return load(path) as Texture2D
	return null


func _harbor_label(
	text: String,
	font_size: int,
	color: Color,
	bold := false,
	outline := 0,
	outline_color := Palette.HARBOR_LABEL_OUTLINE
) -> Label:
	return make_screen_label(text, font_size, color, bold, outline, outline_color, Palette.HARBOR_LABEL_SHADOW)


func _apply_facility_button_skin(button: Button, primary: bool) -> void:
	var normal_path := HARBOR_BUTTON_PRIMARY_PATH if primary else HARBOR_BUTTON_PATH
	var hover_path := HARBOR_BUTTON_PRIMARY_PATH if primary else HARBOR_BUTTON_HOVER_PATH
	var normal := _make_button_style(normal_path)
	var hover := _make_button_style(hover_path)
	if normal == null or hover == null:
		return
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_font_override("font", GameFontsScript.bold(get_theme_default_font()))
	button.add_theme_color_override("font_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_hover_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_pressed_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_disabled_color", Color.TRANSPARENT)
	button.add_theme_constant_override("outline_size", 0)
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func _make_time_slot_button_style(path: String) -> StyleBoxTexture:
	var texture := _load_texture_if_exists(path)
	if texture == null:
		return null
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 18
	style.texture_margin_top = 12
	style.texture_margin_right = 18
	style.texture_margin_bottom = 12
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.content_margin_left = 34.0
	style.content_margin_top = 4.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 4.0
	return style


func _make_button_style(path: String) -> StyleBoxTexture:
	var texture := _load_texture_if_exists(path)
	if texture == null:
		return null
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 50
	style.texture_margin_top = 28
	style.texture_margin_right = 50
	style.texture_margin_bottom = 28
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.content_margin_left = 22.0
	style.content_margin_top = 8.0
	style.content_margin_right = 22.0
	style.content_margin_bottom = 8.0
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
