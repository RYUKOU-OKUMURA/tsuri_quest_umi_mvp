extends ScreenBase

const FightFishAssets = preload("res://src/ui/fight_fish_assets.gd")
const HarborBackdropScript = preload("res://src/ui/components/harbor_backdrop.gd")
const PlayerStatusBarScript = preload("res://src/ui/components/player_status_bar.gd")

const COMMON_ACTION_BUTTON_PATH := "res://assets/showcase/common/action_button_frame.png"
const COMMON_BUTTON_PATH := "res://assets/showcase/common/button_frame.png"
const COMMON_BUTTON_HOVER_PATH := "res://assets/showcase/common/button_frame_hover.png"
const COMMON_BUTTON_PRIMARY_PATH := "res://assets/showcase/common/button_frame_primary.png"
const COMMON_CARD_FRAME_PATH := "res://assets/showcase/common/card_frame.png"
const QUEST_BOARD_WOOD_PATH := "res://assets/showcase/quest_board/quest_board_wood_panel.png"
const QUEST_NOTICE_CARD_PATH := "res://assets/showcase/quest_board/quest_notice_card.png"
const QUEST_ACTION_BUTTON_MIN_HEIGHT := 54.0
const QUEST_ACTION_BUTTON_SAFE_BOTTOM := 0.905
const QUEST_ACTION_BUTTON_STYLE_VERTICAL_MARGIN := 14.0

var _player_status_bar: PlayerStatusBar
var _quest_cards: Array[Dictionary] = []
var _message_label: Label
var _completed_label: Label
var _reward_note_label: Label
var _return_button: Button


func _build_screen() -> void:
	PlayerProgress.ensure_quest_board()
	set_common_cancel_handler(func() -> void: navigate("harbor"))

	var backdrop := HarborBackdropScript.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	move_child(backdrop, 0)

	var shade := ColorRect.new()
	shade.name = "QuestBoardBackdropShade"
	shade.color = _alpha(Palette.DARK_PANEL_DEEP, 0.34)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var root := Control.new()
	root.name = "QuestBoardRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_build_header(root)
	_build_board(root)
	_build_footer(root)
	_refresh()


func _build_header(root: Control) -> void:
	var header := _anchored_control(root, 0.025, 0.027, 0.975, 0.158)
	header.name = "QuestBoardHeader"
	_add_framed_panel(header, Palette.DARK_PANEL, Palette.GOLD, true)

	var title := _quest_label("依頼ボード", 36, Palette.TEXT_BONE, true, 3)
	title.name = "QuestBoardTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(header, title, 0.040, 0.120, 0.420, 0.610)

	var subtitle := _quest_label("掲示中の依頼は常に進行中。達成した札から報酬を受け取れます。", 15, Palette.FOAM, false, 1)
	subtitle.name = "QuestBoardSubtitle"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(header, subtitle, 0.043, 0.585, 0.560, 0.880)

	_player_status_bar = PlayerStatusBarScript.new()
	_player_status_bar.name = "QuestBoardPlayerStatusBar"
	_place_control(header, _player_status_bar, 0.585, 0.150, 0.965, 0.850)


func _build_board(root: Control) -> void:
	var board := _anchored_control(root, 0.035, 0.182, 0.965, 0.832)
	board.name = "QuestBoardPanel"
	_add_wood_board(board)

	var slot_width := 0.300
	var gap := 0.026
	for index in range(3):
		var left := 0.035 + float(index) * (slot_width + gap)
		var card := _build_quest_card(board, index, left, 0.080, left + slot_width, 0.920)
		_quest_cards.append(card)


func _build_quest_card(parent: Control, index: int, left: float, top: float, right: float, bottom: float) -> Dictionary:
	var card := _anchored_control(parent, left, top, right, bottom)
	card.name = "QuestCard%d" % (index + 1)
	card.clip_contents = true
	_add_texture_panel(card, QUEST_NOTICE_CARD_PATH)

	var index_label := _quest_label("依頼札 %d" % (index + 1), 20, Palette.TEXT_DARK, true, 0, Palette.TEXT_OUTLINE_DARK, Color.TRANSPARENT)
	index_label.name = "QuestCardIndex"
	index_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	index_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(card, index_label, 0.075, 0.050, 0.520, 0.122)

	var type_label := _quest_label("", 14, Palette.TEXT_BONE, true, 1)
	type_label.name = "QuestKind"
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_add_chip(card, 0.690, 0.055, 0.915, 0.128)
	_place_control(card, type_label, 0.690, 0.055, 0.915, 0.128)

	var portrait := ShowcaseAssetsScript.texture_rect("", TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	portrait.name = "QuestFishPortrait"
	_place_control(card, portrait, 0.078, 0.168, 0.310, 0.370)
	_add_portrait_backdrop(card, 0.078, 0.168, 0.310, 0.370)
	card.move_child(portrait, card.get_child_count() - 1)

	var fish_name := _quest_label("", 23, Palette.TEXT_DARK, true, 0, Palette.TEXT_OUTLINE_DARK, Color.TRANSPARENT)
	fish_name.name = "QuestFishName"
	fish_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	fish_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(card, fish_name, 0.340, 0.168, 0.912, 0.240)

	var body := _quest_label("", 18, Palette.TEXT_DARK, true, 0, Palette.TEXT_OUTLINE_DARK, Color.TRANSPARENT)
	body.name = "QuestText"
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# 主条件は依頼札の最優先情報。魚名・肖像の下へ全幅3行分を確保し、通常データで省略させない。
	_place_control(card, body, 0.078, 0.375, 0.912, 0.570)

	var progress_title := _quest_label("進捗", 14, Palette.TEXT_BODY, true, 0, Palette.TEXT_OUTLINE_DARK, Color.TRANSPARENT)
	progress_title.name = "QuestProgressTitle"
	progress_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	progress_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(card, progress_title, 0.078, 0.575, 0.250, 0.630)

	var progress_text := _quest_label("", 16, Palette.TEXT_DARK, true, 0, Palette.TEXT_OUTLINE_DARK, Color.TRANSPARENT)
	progress_text.name = "QuestProgressText"
	progress_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	progress_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(card, progress_text, 0.390, 0.575, 0.912, 0.630)

	var progress_track := Panel.new()
	progress_track.name = "QuestProgressTrack"
	progress_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_track.add_theme_stylebox_override("panel", _flat_style(Palette.DARK_PANEL_DEEP, Palette.WOOD_DARK, 5, 1))
	_place_control(card, progress_track, 0.078, 0.648, 0.912, 0.677)

	var progress_fill := ColorRect.new()
	progress_fill.name = "QuestProgressFill"
	progress_fill.color = Palette.GAUGE_GREEN_HI
	progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_track.add_child(progress_fill)

	var reward := _quest_label("", 18, Palette.TEXT_DARK, true, 0, Palette.TEXT_OUTLINE_DARK, Color.TRANSPARENT)
	reward.name = "QuestReward"
	reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	reward.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(card, reward, 0.078, 0.681, 0.912, 0.736)

	var button := _textured_button("", Callable(self, "_complete_quest").bind(index))
	button.name = "QuestActionButton%d" % (index + 1)
	button.set_meta("quest_index", index)
	_place_control(card, button, 0.210, 0.765, 0.790, QUEST_ACTION_BUTTON_SAFE_BOTTOM)

	return {
		"root": card,
		"type_label": type_label,
		"portrait": portrait,
		"fish_name": fish_name,
		"body": body,
		"progress_text": progress_text,
		"progress_fill": progress_fill,
		"reward": reward,
		"button": button,
	}


func _build_footer(root: Control) -> void:
	var footer := _anchored_control(root, 0.035, 0.858, 0.965, 0.970)
	footer.name = "QuestBoardFooter"
	_add_framed_panel(footer, Palette.DARK_PANEL, Palette.GOLD, true)

	_completed_label = _quest_label("", 17, Palette.TEXT_BONE, true, 2)
	_completed_label.name = "QuestCompletedCount"
	_completed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_completed_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(footer, _completed_label, 0.030, 0.135, 0.285, 0.490)

	_reward_note_label = _quest_label("", 15, Palette.FOAM, false, 1)
	_reward_note_label.name = "QuestRewardNote"
	_reward_note_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_reward_note_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(footer, _reward_note_label, 0.030, 0.510, 0.500, 0.850)

	_message_label = _quest_label("", 15, Palette.TEXT_BONE, false, 1)
	_message_label.name = "QuestBoardMessage"
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(footer, _message_label, 0.520, 0.160, 0.780, 0.840)

	_return_button = make_return_button(func() -> void: navigate("harbor"), 0.0)
	_return_button.name = "QuestBoardReturnButton"
	_return_button.add_theme_font_override("font", GameFontsScript.extra_bold(get_theme_default_font()))
	_return_button.add_theme_font_size_override("font_size", 23)
	_place_control(footer, _return_button, 0.815, 0.160, 0.975, 0.840)


func _refresh() -> void:
	var focus_owner := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	var retained_slot := _quest_action_slot(focus_owner)
	var retained_return := focus_owner == _return_button
	var had_managed_focus := retained_slot >= 0 or retained_return
	PlayerProgress.ensure_quest_board()
	for index in range(_quest_cards.size()):
		_refresh_card(index)
	_completed_label.text = "依頼達成数：%d件" % PlayerProgress.quest_completed_count
	if "shokunin" in PlayerProgress.owned_rigs:
		_reward_note_label.text = "限定報酬：職人仕掛けを所持中"
	else:
		var remaining := maxi(0, 10 - PlayerProgress.quest_completed_count)
		_reward_note_label.text = "あと%d件で限定仕掛け" % remaining
	if _message_label.text.is_empty():
		_message_label.text = "達成済みの札だけ納品・報告できます。"
	if _player_status_bar != null:
		_player_status_bar.refresh()
	_sync_keyboard_focus_context(retained_slot, retained_return, had_managed_focus)


func _refresh_card(index: int) -> void:
	var card := _quest_cards[index]
	var quest := {}
	if index < PlayerProgress.quest_board.size():
		quest = PlayerProgress.quest_board[index]
	var progress := PlayerProgress.quest_progress(index)
	var fish_id := String(quest.get("fish_id", ""))
	var fish := GameData.get_fish(fish_id)
	var fish_name := String(fish.get("name", fish_id))
	var kind := String(progress.get("kind", quest.get("kind", "delivery")))
	var completed := bool(progress.get("completed", false))
	var action_label := String(progress.get("action_label", "納品"))

	var type_label := card["type_label"] as Label
	type_label.text = "記録" if kind == "record" else "納品"
	(card["fish_name"] as Label).text = fish_name if not fish_name.is_empty() else "未掲示"
	(card["body"] as Label).text = String(quest.get("text", "依頼を準備中です。"))
	(card["progress_text"] as Label).text = String(progress.get("progress_text", "--"))
	(card["reward"] as Label).text = "報酬：%s G" % ScreenBase.format_money(int(quest.get("reward_money", 0)))

	var portrait := card["portrait"] as TextureRect
	portrait.texture = ShowcaseAssetsScript.load_texture(FightFishAssets.card_portrait_path({"id": fish_id}))

	var ratio := _progress_ratio(progress)
	var progress_fill := card["progress_fill"] as ColorRect
	progress_fill.color = Palette.GAUGE_GREEN_HI if completed else Palette.GAUGE_AMBER
	progress_fill.anchor_left = 0.0
	progress_fill.anchor_top = 0.0
	progress_fill.anchor_right = ratio
	progress_fill.anchor_bottom = 1.0
	progress_fill.offset_left = 0.0
	progress_fill.offset_top = 0.0
	progress_fill.offset_right = 0.0
	progress_fill.offset_bottom = 0.0

	var button := card["button"] as Button
	button.text = action_label if completed else "未達成"
	button.disabled = not completed
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if completed else Control.CURSOR_ARROW


func _sync_keyboard_focus_context(
	retained_slot: int = -1,
	retained_return := false,
	had_managed_focus := false
) -> void:
	var action_buttons := _quest_action_buttons()
	var preferred: Control = null
	if retained_return:
		preferred = _return_button
	elif retained_slot >= 0:
		var retained := action_buttons[retained_slot]
		if not retained.disabled:
			preferred = retained
		else:
			preferred = _next_enabled_action(retained_slot, action_buttons)
	elif not had_managed_focus:
		preferred = _next_enabled_action(-1, action_buttons)
	if preferred == null:
		preferred = _return_button

	var candidates: Array[Control] = []
	for button in action_buttons:
		candidates.append(button)
	candidates.append(_return_button)
	_clear_keyboard_focus_graph(candidates)
	setup_keyboard_focus(candidates, preferred)
	_link_keyboard_focus_graph(keyboard_focus_candidates())


func _quest_action_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	for card in _quest_cards:
		buttons.append(card["button"] as Button)
	return buttons


func _quest_action_slot(control: Control) -> int:
	if control == null or not is_instance_valid(control):
		return -1
	for index in range(_quest_cards.size()):
		if control == _quest_cards[index]["button"]:
			return index
	return -1


func _next_enabled_action(after_slot: int, action_buttons: Array[Button]) -> Button:
	if action_buttons.is_empty():
		return null
	for offset in range(1, action_buttons.size() + 1):
		var index := (after_slot + offset) % action_buttons.size()
		if not action_buttons[index].disabled:
			return action_buttons[index]
	return null


func _clear_keyboard_focus_graph(controls: Array[Control]) -> void:
	for control in controls:
		control.focus_neighbor_left = NodePath()
		control.focus_neighbor_right = NodePath()
		control.focus_neighbor_top = NodePath()
		control.focus_neighbor_bottom = NodePath()
		control.focus_next = NodePath()
		control.focus_previous = NodePath()


func _link_keyboard_focus_graph(available: Array[Control]) -> void:
	if available.is_empty():
		return
	for index in range(available.size()):
		var control := available[index]
		var previous := available[(index - 1 + available.size()) % available.size()]
		var next := available[(index + 1) % available.size()]
		control.focus_previous = control.get_path_to(previous)
		control.focus_next = control.get_path_to(next)

	var enabled_actions: Array[Control] = []
	for control in available:
		if control != _return_button:
			enabled_actions.append(control)
	if enabled_actions.is_empty():
		_set_focus_neighbors(_return_button, _return_button, _return_button, _return_button, _return_button)
		return

	for index in range(enabled_actions.size()):
		var action := enabled_actions[index]
		var left := enabled_actions[(index - 1 + enabled_actions.size()) % enabled_actions.size()]
		var right := enabled_actions[(index + 1) % enabled_actions.size()]
		_set_focus_neighbors(action, left, right, _return_button, _return_button)
	_set_focus_neighbors(
		_return_button,
		enabled_actions.back(),
		enabled_actions.front(),
		enabled_actions.back(),
		enabled_actions.front()
	)


func _set_focus_neighbors(
	control: Control,
	left: Control,
	right: Control,
	top: Control,
	bottom: Control
) -> void:
	control.focus_neighbor_left = control.get_path_to(left)
	control.focus_neighbor_right = control.get_path_to(right)
	control.focus_neighbor_top = control.get_path_to(top)
	control.focus_neighbor_bottom = control.get_path_to(bottom)


func _complete_quest(index: int) -> void:
	var result := PlayerProgress.deliver_quest(index)
	_message_label.text = String(result.get("message", "依頼を確認しました。"))
	if bool(result.get("rig_awarded", false)):
		_message_label.text += " 職人仕掛けを受け取った。"
	var new_titles: Array = Array(result.get("new_titles", []))
	if new_titles.size() > 0:
		_message_label.text += " 新しい称号を獲得。"
	_refresh()


func _progress_ratio(progress: Dictionary) -> float:
	var target := float(progress.get("target", 0.0))
	if target <= 0.0:
		return 0.0
	return clampf(float(progress.get("current", 0.0)) / target, 0.0, 1.0)


func _add_wood_board(parent: Control) -> void:
	var texture := ShowcaseAssetsScript.texture_rect(QUEST_BOARD_WOOD_PATH)
	texture.name = "QuestBoardWood"
	texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(texture)


func _add_texture_panel(parent: Control, path: String) -> void:
	var texture := ShowcaseAssetsScript.texture_rect(path)
	texture.name = "QuestBoardTexturePanel"
	texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(texture)


func _add_framed_panel(parent: Control, fill: Color, border: Color, shadow := false) -> void:
	var panel := Panel.new()
	panel.name = "QuestBoardFrame"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _flat_style(fill, border, 7, 2, shadow))
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(panel)


func _add_chip(parent: Control, left: float, top: float, right: float, bottom: float) -> void:
	var chip := Panel.new()
	chip.name = "QuestKindChip"
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_theme_stylebox_override("panel", _flat_style(Palette.WOOD, Palette.WOOD_DARK, 4, 1))
	_place_control(parent, chip, left, top, right, bottom)


func _add_portrait_backdrop(parent: Control, left: float, top: float, right: float, bottom: float) -> void:
	var panel := Panel.new()
	panel.name = "QuestFishPortraitBackdrop"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _flat_style(Palette.PARCHMENT_DEEP, Palette.WOOD_DARK, 5, 1))
	_place_control(parent, panel, left, top, right, bottom)


func _textured_button(text: String, callback: Callable) -> Button:
	var button := make_button(text, callback, 0.0, false)
	button.custom_minimum_size.y = QUEST_ACTION_BUTTON_MIN_HEIGHT
	button.clip_text = true
	var normal := ShowcaseAssetsScript.texture_style(
		COMMON_BUTTON_PATH,
		Vector4(42.0, QUEST_ACTION_BUTTON_STYLE_VERTICAL_MARGIN, 42.0, QUEST_ACTION_BUTTON_STYLE_VERTICAL_MARGIN)
	)
	var hover := ShowcaseAssetsScript.texture_style(
		COMMON_BUTTON_HOVER_PATH,
		Vector4(42.0, QUEST_ACTION_BUTTON_STYLE_VERTICAL_MARGIN, 42.0, QUEST_ACTION_BUTTON_STYLE_VERTICAL_MARGIN)
	)
	var pressed := ShowcaseAssetsScript.texture_style(
		COMMON_BUTTON_PRIMARY_PATH,
		Vector4(42.0, QUEST_ACTION_BUTTON_STYLE_VERTICAL_MARGIN, 42.0, QUEST_ACTION_BUTTON_STYLE_VERTICAL_MARGIN)
	)
	var disabled := ShowcaseAssetsScript.texture_style(
		COMMON_ACTION_BUTTON_PATH,
		Vector4(46.0, QUEST_ACTION_BUTTON_STYLE_VERTICAL_MARGIN, 46.0, QUEST_ACTION_BUTTON_STYLE_VERTICAL_MARGIN)
	)
	if normal != null:
		button.add_theme_stylebox_override("normal", normal)
	if hover != null:
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("focus", hover)
	if pressed != null:
		button.add_theme_stylebox_override("pressed", pressed)
	if disabled != null:
		button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_font_override("font", GameFontsScript.extra_bold(get_theme_default_font()))
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Palette.TEXT_BONE)
	button.add_theme_color_override("font_hover_color", Palette.GOLD_BRIGHT)
	button.add_theme_color_override("font_pressed_color", Palette.GOLD_BRIGHT)
	button.add_theme_color_override("font_disabled_color", Palette.THEME_BUTTON_DISABLED_TEXT)
	button.add_theme_color_override("font_outline_color", Palette.TEXT_OUTLINE_DARK)
	button.add_theme_constant_override("outline_size", 2)
	return button


func _quest_label(
	text: String,
	font_size: int,
	color: Color,
	bold := false,
	outline := 0,
	outline_color: Color = Palette.TEXT_OUTLINE_DARK,
	shadow_color: Color = Palette.SHADOW
) -> Label:
	return make_screen_label(text, font_size, color, bold, outline, outline_color, shadow_color, true)


func _flat_style(
	fill: Color,
	border: Color,
	radius: int,
	border_width := 1,
	shadow := false
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 8.0
	style.content_margin_top = 6.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 6.0
	if shadow:
		style.shadow_color = Palette.SHADOW
		style.shadow_size = 5
		style.shadow_offset = Vector2(0.0, 3.0)
	return style


func _alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)
