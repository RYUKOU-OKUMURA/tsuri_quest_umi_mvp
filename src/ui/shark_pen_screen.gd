extends ScreenBase

const FightFishAssets = preload("res://src/ui/fight_fish_assets.gd")
const PlayerStatusBarScript = preload("res://src/ui/components/player_status_bar.gd")

const COMMON_ACTION_BUTTON_PATH := "res://assets/showcase/common/action_button_frame.png"
const SHARK_ROW_COUNT := 10

var _player_status_bar: PlayerStatusBar
var _aquarium_layer: Control
var _selected_shark_label: Label
var _selected_shark_note: Label
var _shark_rows: Dictionary = {}
var _food_rows: Dictionary = {}
var _feed_button: Button
var _return_button: Button
var _message_label: Label
var _feed_preview_label: Label
var _food_list: HBoxContainer
var _selected_shark_id := ""
var _selected_food_id := ""


func _build_screen() -> void:
	add_gradient_background(Palette.SEA_DEEP, Palette.DARK_PANEL_DEEP)
	var shade := ColorRect.new()
	shade.name = "SharkPenBackdropShade"
	shade.color = _alpha(Palette.DARK_PANEL_DEEP, 0.34)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var root := Control.new()
	root.name = "SharkPenRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_selected_shark_id = _initial_shark_id()
	_selected_food_id = _initial_food_id(_selected_shark_id)
	_build_header(root)
	_build_aquarium(root)
	_build_roster(root)
	_build_feed_panel(root)
	_refresh_all()


func _build_header(root: Control) -> void:
	var header := _anchored_control(root, 0.026, 0.028, 0.974, 0.150)
	header.name = "SharkPenHeader"
	_add_panel(header, Palette.DARK_PANEL, Palette.GOLD, 7, 3, true)

	var title := _pen_label("サメの生簀", 34, Palette.TEXT_BONE, true, 3)
	title.name = "SharkPenTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(header, title, 0.026, 0.120, 0.360, 0.600)

	var subtitle := _pen_label("危険海域で出会ったサメに餌をあたえ、なつき度を育てる", 15, Palette.FOAM, false, 1)
	subtitle.name = "SharkPenSubtitle"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(header, subtitle, 0.028, 0.580, 0.520, 0.900)

	_player_status_bar = PlayerStatusBarScript.new()
	_player_status_bar.name = "SharkPenPlayerStatusBar"
	_place_control(header, _player_status_bar, 0.585, 0.150, 0.965, 0.850)


func _build_aquarium(root: Control) -> void:
	var aquarium := _anchored_control(root, 0.034, 0.176, 0.595, 0.775)
	aquarium.name = "SharkPenAquariumPanel"
	aquarium.clip_contents = true
	_add_panel(aquarium, Palette.BLUE_PANEL, Palette.GOLD, 7, 3, true)

	var water := TextureRect.new()
	water.name = "SharkPenAquariumWater"
	water.texture = _gradient_texture(Palette.SEA_MID, Palette.SEA_DEEP)
	water.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	water.stretch_mode = TextureRect.STRETCH_SCALE
	water.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(aquarium, water, 0.012, 0.014, 0.988, 0.988)

	var title := _pen_label("水槽ビュー", 20, Palette.TEXT_BONE, true, 2)
	title.name = "SharkPenAquariumTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(aquarium, title, 0.030, 0.035, 0.420, 0.120)

	_add_current_arc(aquarium, 0.18)
	_add_current_arc(aquarium, 0.42)
	_add_current_arc(aquarium, 0.68)

	_aquarium_layer = Control.new()
	_aquarium_layer.name = "SharkPenAquariumFishLayer"
	_aquarium_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(aquarium, _aquarium_layer, 0.050, 0.135, 0.950, 0.855)

	var bottom := ColorRect.new()
	bottom.name = "SharkPenAquariumBottomStrip"
	bottom.color = _alpha(Palette.DARK_PANEL_DEEP, 0.88)
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(aquarium, bottom, 0.018, 0.858, 0.982, 0.970)

	_selected_shark_label = _pen_label("", 17, Palette.TEXT_BONE, true, 2)
	_selected_shark_label.name = "SharkPenSelectedShark"
	_selected_shark_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_selected_shark_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(aquarium, _selected_shark_label, 0.040, 0.865, 0.620, 0.925)

	_selected_shark_note = _pen_label("", 13, Palette.FOAM, false, 1)
	_selected_shark_note.name = "SharkPenSelectedNote"
	_selected_shark_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_selected_shark_note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(aquarium, _selected_shark_note, 0.040, 0.915, 0.880, 0.970)


func _build_roster(root: Control) -> void:
	var roster := _anchored_control(root, 0.613, 0.176, 0.966, 0.775)
	roster.name = "SharkPenRosterPanel"
	_add_panel(roster, Palette.DARK_PANEL, Palette.GOLD, 7, 3, true)

	var title := _pen_label("サメ選択", 20, Palette.TEXT_BONE, true, 2)
	title.name = "SharkPenRosterTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(roster, title, 0.055, 0.035, 0.480, 0.115)

	var ids := GameData.get_raiseable_shark_ids()
	var top := 0.130
	var row_h := 0.071
	var gap := 0.012
	for index in range(mini(SHARK_ROW_COUNT, ids.size())):
		var shark_id := ids[index]
		var button := Button.new()
		button.name = "SharkPenSharkRow_%s" % shark_id
		button.set_meta("shark_id", shark_id)
		button.focus_mode = Control.FOCUS_ALL
		button.clip_contents = true
		button.pressed.connect(func() -> void: _select_shark(shark_id))
		_apply_blank_button_skin(button)
		_place_control(roster, button, 0.055, top + float(index) * (row_h + gap), 0.945, top + float(index) * (row_h + gap) + row_h)

		var name_label := _pen_label("", 13, Palette.TEXT_BONE, true, 1)
		name_label.name = "SharkPenRowName_%s" % shark_id
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place_control(button, name_label, 0.035, 0.100, 0.330, 0.900)

		var track := Panel.new()
		track.name = "SharkPenRowGaugeTrack_%s" % shark_id
		track.mouse_filter = Control.MOUSE_FILTER_IGNORE
		track.add_theme_stylebox_override("panel", _flat_style(Palette.GAUGE_TRACK, Palette.GAUGE_TRACK_BORDER, 3, 1))
		_place_control(button, track, 0.360, 0.310, 0.820, 0.690)

		var fill := ColorRect.new()
		fill.name = "SharkPenRowGaugeFill_%s" % shark_id
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		track.add_child(fill)

		var value_label := _pen_label("", 13, Palette.TEXT_BONE, true, 1)
		value_label.name = "SharkPenRowBond_%s" % shark_id
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place_control(button, value_label, 0.835, 0.100, 0.975, 0.900)

		_shark_rows[shark_id] = {
			"button": button,
			"name": name_label,
			"track": track,
			"fill": fill,
			"value": value_label,
		}


func _build_feed_panel(root: Control) -> void:
	var feed := _anchored_control(root, 0.034, 0.807, 0.772, 0.955)
	feed.name = "SharkPenFeedPanel"
	_add_panel(feed, Palette.DARK_PANEL, Palette.GOLD, 7, 3, true)

	var title := _pen_label("餌やり", 20, Palette.TEXT_BONE, true, 2)
	title.name = "SharkPenFeedTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(feed, title, 0.025, 0.080, 0.130, 0.380)

	_feed_preview_label = _pen_label("", 14, Palette.FOAM, false, 1)
	_feed_preview_label.name = "SharkPenFeedPreview"
	_feed_preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_feed_preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(feed, _feed_preview_label, 0.145, 0.075, 0.740, 0.380)

	var scroll := ScrollContainer.new()
	scroll.name = "SharkPenFoodScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_place_control(feed, scroll, 0.025, 0.440, 0.800, 0.895)

	_food_list = HBoxContainer.new()
	_food_list.name = "SharkPenFoodList"
	_food_list.add_theme_constant_override("separation", 10)
	scroll.add_child(_food_list)

	_feed_button = _textured_button("あたえる", _feed_selected)
	_feed_button.name = "SharkPenFeedButton"
	_place_control(feed, _feed_button, 0.825, 0.405, 0.970, 0.900)

	var footer := _anchored_control(root, 0.792, 0.807, 0.966, 0.955)
	footer.name = "SharkPenFooter"
	_add_panel(footer, Palette.DARK_PANEL, Palette.GOLD, 7, 3, true)
	_message_label = _pen_label("", 14, Palette.FOAM, false, 1)
	_message_label.name = "SharkPenMessage"
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place_control(footer, _message_label, 0.055, 0.080, 0.945, 0.460)

	_return_button = make_return_button(func() -> void: navigate("harbor"), 0.0)
	_return_button.name = "SharkPenReturnButton"
	_return_button.add_theme_font_override("font", GameFontsScript.extra_bold(get_theme_default_font()))
	_return_button.add_theme_font_size_override("font_size", 22)
	_place_control(footer, _return_button, 0.105, 0.505, 0.895, 0.900)


func _refresh_all() -> void:
	if _selected_shark_id.is_empty():
		_selected_shark_id = _initial_shark_id()
	if _selected_food_id.is_empty() or PlayerProgress.fish_count(_selected_food_id) <= 0:
		_selected_food_id = _initial_food_id(_selected_shark_id)
	_refresh_aquarium()
	_refresh_roster()
	_refresh_food_list()
	_refresh_feed_state()
	if _player_status_bar != null:
		_player_status_bar.refresh()


func _refresh_aquarium() -> void:
	for child in _aquarium_layer.get_children():
		child.queue_free()
	var shark := GameData.get_fish(_selected_shark_id)
	var caught := _is_shark_caught(_selected_shark_id)
	var bond := _shark_bond(_selected_shark_id)
	if caught:
		_add_fish_sprite(_selected_shark_id, Rect2(0.085, 0.260, 0.820, 0.740), 1.0)
		var support_ids := _support_swimmers(_selected_shark_id)
		if support_ids.size() > 0:
			_add_fish_sprite(support_ids[0], Rect2(0.430, 0.055, 0.520, 0.255), 0.80)
		if support_ids.size() > 1:
			_add_fish_sprite(support_ids[1], Rect2(0.025, 0.600, 0.380, 0.860), 0.78)
		_selected_shark_label.text = "選択中：%s　なつき度 %d/100" % [String(shark.get("name", _selected_shark_id)), bond]
		_selected_shark_note.text = "完全成長" if bond >= 100 else "好物をあたえると大きくなつきます。"
	else:
		var locked := _pen_label("まだ生簀に迎えていません", 26, Palette.TEXT_BONE, true, 3)
		locked.name = "SharkPenAquariumLocked"
		locked.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		locked.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_place_control(_aquarium_layer, locked, 0.060, 0.300, 0.940, 0.620)
		_selected_shark_label.text = "未捕獲：%s" % String(shark.get("name", _selected_shark_id))
		_selected_shark_note.text = "危険海域で釣り上げると、生簀へ直行します。"


func _refresh_roster() -> void:
	for shark_id_variant in _shark_rows.keys():
		var shark_id := String(shark_id_variant)
		var row: Dictionary = _shark_rows[shark_id]
		var button := row["button"] as Button
		var name_label := row["name"] as Label
		var value_label := row["value"] as Label
		var fill := row["fill"] as ColorRect
		var shark := GameData.get_fish(shark_id)
		var caught: bool = _is_shark_caught(shark_id)
		var selected: bool = shark_id == _selected_shark_id
		var bond := _shark_bond(shark_id)
		button.disabled = not caught
		_apply_row_skin(button, selected, caught)
		name_label.text = String(shark.get("name", shark_id)) if caught else "？？？"
		name_label.add_theme_color_override("font_color", Palette.TEXT_DARK if selected else Palette.TEXT_BONE)
		value_label.text = "完" if bond >= 100 else str(bond) if caught else "未"
		value_label.add_theme_color_override("font_color", Palette.TEXT_DARK if selected else Palette.TEXT_BONE)
		fill.color = Palette.GAUGE_GREEN if bond >= 100 else Palette.GAUGE_AMBER
		fill.anchor_left = 0.0
		fill.anchor_top = 0.0
		fill.anchor_right = clampf(float(bond) / 100.0, 0.0, 1.0)
		fill.anchor_bottom = 1.0
		fill.offset_left = 0.0
		fill.offset_top = 0.0
		fill.offset_right = 0.0
		fill.offset_bottom = 0.0


func _refresh_food_list() -> void:
	for child in _food_list.get_children():
		child.queue_free()
	_food_rows = {}
	var options := _food_options(_selected_shark_id)
	if options.is_empty():
		var empty := _pen_label("餌にできる魚がありません", 15, Palette.TEXT_BONE, true, 1)
		empty.name = "SharkPenFoodEmpty"
		empty.custom_minimum_size = Vector2(240.0, 42.0)
		_food_list.add_child(empty)
		return
	for fish_id in options:
		_add_food_card(fish_id)


func _add_food_card(fish_id: String) -> void:
	var fish := GameData.get_fish(fish_id)
	var favorite := GameData.is_favorite_food(_selected_shark_id, fish)
	var selected := fish_id == _selected_food_id
	var button := Button.new()
	button.name = "SharkPenFoodRow_%s" % fish_id
	button.set_meta("fish_id", fish_id)
	button.custom_minimum_size = Vector2(132.0, 42.0)
	button.focus_mode = Control.FOCUS_ALL
	button.clip_contents = true
	button.pressed.connect(func() -> void: _select_food(fish_id))
	_apply_food_skin(button, selected, favorite)
	_food_list.add_child(button)

	var name_label := _pen_label(String(fish.get("name", fish_id)), 13, Palette.TEXT_DARK if selected else Palette.TEXT_BONE, true, 1 if not selected else 0)
	name_label.name = "SharkPenFoodName_%s" % fish_id
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(button, name_label, 0.070, 0.080, 0.670, 0.920)

	var count_label := _pen_label("x%d" % PlayerProgress.fish_count(fish_id), 13, Palette.TEXT_DARK if selected else Palette.TEXT_BONE, true, 1 if not selected else 0)
	count_label.name = "SharkPenFoodCount_%s" % fish_id
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(button, count_label, 0.695, 0.080, 0.950, 0.920)

	if favorite:
		var badge := Panel.new()
		badge.name = "SharkPenFavoriteBadge_%s" % fish_id
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_theme_stylebox_override("panel", _flat_style(Palette.GOLD_BRIGHT, Palette.GOLD_DEEP, 8, 1))
		_place_control(button, badge, 0.045, 0.600, 0.160, 0.920)
	_food_rows[fish_id] = {"button": button, "favorite": favorite}


func _refresh_feed_state() -> void:
	var can_feed := _can_feed_selected()
	_feed_button.disabled = not can_feed
	if _selected_food_id.is_empty():
		_feed_preview_label.text = "餌魚を選んでください。"
		return
	var food := GameData.get_fish(_selected_food_id)
	var favorite := GameData.is_favorite_food(_selected_shark_id, food)
	var bond_gain := GameData.SHARK_FAVORITE_BOND_GAIN if favorite else GameData.SHARK_DEFAULT_BOND_GAIN
	var exp_multiplier := GameData.SHARK_FAVORITE_EXP_MULTIPLIER if favorite else GameData.SHARK_DEFAULT_EXP_MULTIPLIER
	var exp_gain := int(round(float(food.get("food_exp", 0)) * exp_multiplier))
	var status := "好物" if favorite else "通常"
	_feed_preview_label.text = "%s：なつき度 +%d / EXP +%d" % [status, bond_gain, exp_gain]
	if _message_label.text.is_empty():
		_message_label.text = "サメと餌魚を選んでください。"


func _select_shark(shark_id: String) -> void:
	if not GameData.is_raiseable_shark_id(shark_id):
		return
	_selected_shark_id = shark_id
	_selected_food_id = _initial_food_id(_selected_shark_id)
	_refresh_all()


func _select_food(fish_id: String) -> void:
	if not _is_valid_food_id(fish_id):
		return
	_selected_food_id = fish_id
	_refresh_all()


func _feed_selected() -> void:
	var result := PlayerProgress.feed_shark(_selected_shark_id, _selected_food_id)
	if bool(result.get("ok", false)):
		var food := GameData.get_fish(_selected_food_id)
		var shark := GameData.get_fish(_selected_shark_id)
		var favorite_text := "好物！ " if bool(result.get("favorite", false)) else ""
		_message_label.text = "%s%sに%sをあたえた。なつき度 +%d / EXP +%d" % [
			favorite_text,
			String(shark.get("name", _selected_shark_id)),
			String(food.get("name", _selected_food_id)),
			int(result.get("bond_gain", 0)),
			int(result.get("exp_gain", 0)),
		]
		if bool(result.get("completed", false)):
			_message_label.text += " 完全成長！"
	else:
		_message_label.text = String(result.get("message", "餌やりできません。"))
	_refresh_all()


func _initial_shark_id() -> String:
	var ids := GameData.get_raiseable_shark_ids()
	var requested := String(route_payload.get("selected_shark_id", ""))
	if ids.has(requested) and _is_shark_caught(requested):
		return requested
	for shark_id in ids:
		if _is_shark_caught(shark_id):
			return shark_id
	return ids[0] if not ids.is_empty() else ""


func _initial_food_id(shark_id: String) -> String:
	var options := _food_options(shark_id)
	return options[0] if not options.is_empty() else ""


func _food_options(shark_id: String) -> Array[String]:
	var ids: Array[String] = []
	for key in PlayerProgress.inventory.keys():
		var fish_id := String(key)
		if _is_valid_food_id(fish_id):
			ids.append(fish_id)
	ids.sort_custom(
		func(a: String, b: String) -> bool:
			var fish_a := GameData.get_fish(a)
			var fish_b := GameData.get_fish(b)
			var favorite_a := GameData.is_favorite_food(shark_id, fish_a)
			var favorite_b := GameData.is_favorite_food(shark_id, fish_b)
			if favorite_a != favorite_b:
				return favorite_a
			var exp_a := int(fish_a.get("food_exp", 0))
			var exp_b := int(fish_b.get("food_exp", 0))
			if exp_a != exp_b:
				return exp_a > exp_b
			return String(fish_a.get("name", a)) < String(fish_b.get("name", b))
	)
	return ids


func _is_valid_food_id(fish_id: String) -> bool:
	if PlayerProgress.fish_count(fish_id) <= 0:
		return false
	var fish := GameData.get_fish(fish_id)
	return not fish.is_empty() and not bool(fish.get("shark", false))


func _can_feed_selected() -> bool:
	return (
		not _selected_shark_id.is_empty()
		and _is_shark_caught(_selected_shark_id)
		and not _selected_food_id.is_empty()
		and _is_valid_food_id(_selected_food_id)
	)


func _is_shark_caught(shark_id: String) -> bool:
	return int(PlayerProgress.caught_counts.get(shark_id, 0)) > 0


func _shark_bond(shark_id: String) -> int:
	return clampi(int(PlayerProgress.shark_bonds.get(shark_id, 0)), 0, 100)


func _support_swimmers(selected_id: String) -> Array[String]:
	var ids: Array[String] = []
	for shark_id in GameData.get_raiseable_shark_ids():
		if shark_id == selected_id:
			continue
		if _is_shark_caught(shark_id):
			ids.append(shark_id)
	return ids


func _add_fish_sprite(fish_id: String, ratios: Rect2, modulate_alpha: float) -> void:
	var fish := GameData.get_fish(fish_id)
	var sheet := ShowcaseAssetsScript.load_texture(FightFishAssets.sheet_path(fish))
	if sheet == null:
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(Vector2.ZERO, Vector2(float(sheet.get_width()) / 4.0, float(sheet.get_height())))
	var rect := TextureRect.new()
	rect.name = "SharkPenSwimmer_%s" % fish_id
	rect.texture = atlas
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rect.modulate = Color(1.0, 1.0, 1.0, modulate_alpha)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(
		_aquarium_layer,
		rect,
		ratios.position.x,
		ratios.position.y,
		ratios.position.x + ratios.size.x,
		ratios.position.y + ratios.size.y
	)


func _add_current_arc(parent: Control, center_y: float) -> void:
	var line := ColorRect.new()
	line.name = "SharkPenCurrentLine"
	line.color = _alpha(Palette.GAUGE_CYAN_HI, 0.34)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(parent, line, 0.085, center_y, 0.915, center_y + 0.006)


func _add_panel(parent: Control, fill: Color, border: Color, radius: int, border_width := 2, shadow := false) -> void:
	var panel := Panel.new()
	panel.name = "SharkPenFrame"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _flat_style(fill, border, radius, border_width, shadow))
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(panel)


func _apply_row_skin(button: Button, selected: bool, caught: bool) -> void:
	var fill := Palette.PARCHMENT if selected else Palette.THEME_DIALOG_FILL if caught else _alpha(Palette.DARK_PANEL_DEEP, 0.72)
	var border := Palette.GOLD_BRIGHT if selected else Palette.GAUGE_TRACK_BORDER
	var normal := _flat_style(fill, border, 5, 2 if selected else 1)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", _flat_style(Palette.BLUE_PANEL, Palette.GOLD, 5, 1))
	button.add_theme_stylebox_override("focus", _flat_style(Palette.BLUE_PANEL, Palette.GOLD, 5, 1))
	button.add_theme_stylebox_override("pressed", _flat_style(Palette.PARCHMENT_DEEP, Palette.GOLD_BRIGHT, 5, 2))
	button.add_theme_stylebox_override("disabled", normal)


func _apply_food_skin(button: Button, selected: bool, favorite: bool) -> void:
	var fill := Palette.PARCHMENT if selected else Palette.THEME_DIALOG_FILL
	var border := Palette.GOLD_BRIGHT if selected or favorite else Palette.GAUGE_TRACK_BORDER
	var normal := _flat_style(fill, border, 5, 2 if selected else 1)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", _flat_style(Palette.BLUE_PANEL, Palette.GOLD, 5, 1))
	button.add_theme_stylebox_override("focus", _flat_style(Palette.BLUE_PANEL, Palette.GOLD, 5, 1))
	button.add_theme_stylebox_override("pressed", _flat_style(Palette.PARCHMENT_DEEP, Palette.GOLD_BRIGHT, 5, 2))


func _apply_blank_button_skin(button: Button) -> void:
	button.text = ""
	button.add_theme_font_override("font", GameFontsScript.bold(get_theme_default_font()))
	button.add_theme_color_override("font_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_hover_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_pressed_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_disabled_color", Color.TRANSPARENT)


func _textured_button(text: String, callback: Callable) -> Button:
	var button := make_button(text, callback, 0.0, false)
	var normal := ShowcaseAssetsScript.texture_style(COMMON_ACTION_BUTTON_PATH, Vector4(46.0, 24.0, 46.0, 24.0))
	if normal != null:
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", normal)
		button.add_theme_stylebox_override("pressed", normal)
		button.add_theme_stylebox_override("focus", normal)
		button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_font_override("font", GameFontsScript.extra_bold(get_theme_default_font()))
	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_color_override("font_color", Palette.TEXT_BONE)
	button.add_theme_color_override("font_hover_color", Palette.GOLD_BRIGHT)
	button.add_theme_color_override("font_pressed_color", Palette.GOLD_BRIGHT)
	button.add_theme_color_override("font_disabled_color", Palette.THEME_BUTTON_DISABLED_TEXT)
	button.add_theme_color_override("font_outline_color", Palette.TEXT_OUTLINE_DARK)
	button.add_theme_constant_override("outline_size", 2)
	return button


func _pen_label(text: String, font_size: int, color: Color, bold := false, outline := 0) -> Label:
	return make_screen_label(text, font_size, color, bold, outline, Palette.TEXT_OUTLINE_DARK, Palette.SHADOW, true)


func _flat_style(fill: Color, border: Color, radius: int, border_width := 1, shadow := false) -> StyleBoxFlat:
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


func _gradient_texture(top_color: Color, bottom_color: Color) -> Texture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, top_color)
	gradient.set_color(1, bottom_color)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(0.0, 1.0)
	texture.width = 64
	texture.height = 64
	return texture


func _alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)
