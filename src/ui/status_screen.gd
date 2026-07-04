extends ScreenBase

const FightFishAssets = preload("res://src/ui/fight_fish_assets.gd")
const GaugeBarScript = preload("res://src/ui/components/gauge_bar.gd")
const HarborBackdropScript = preload("res://src/ui/components/harbor_backdrop.gd")
const PlayerStatusBarScript = preload("res://src/ui/components/player_status_bar.gd")
const RarityStylesScript = preload("res://src/ui/rarity_styles.gd")

const COMMON_ACTION_BUTTON_PATH := "res://assets/showcase/common/action_button_frame.png"
const COMMON_BUTTON_PATH := "res://assets/showcase/common/button_frame.png"
const COMMON_BUTTON_HOVER_PATH := "res://assets/showcase/common/button_frame_hover.png"
const COMMON_BUTTON_PRIMARY_PATH := "res://assets/showcase/common/button_frame_primary.png"
const COMMON_CARD_FRAME_PATH := "res://assets/showcase/common/card_frame.png"
const COMMON_CARD_SELECTED_FRAME_PATH := "res://assets/showcase/common/card_selected_frame.png"
const COMMON_PARCHMENT_CARD_PATH := "res://assets/showcase/common/parchment_card.png"
const ICON_FISH_BOOK_PATH := "res://assets/showcase/common/nav_status_icon.png"
const ICON_COOKING_PATH := "res://assets/showcase/common/nav_cooking_icon.png"

var _player_status_bar: PlayerStatusBar
var _player_panel: Control
var _summary_panel: Control
var _inventory_panel: Control
var _fish_book_button: Button
var _cooking_button: Button
var _return_button: Button
var _message_label: Label


func _build_screen() -> void:
	var backdrop := HarborBackdropScript.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	move_child(backdrop, 0)

	var shade := ColorRect.new()
	shade.name = "StatusBackdropShade"
	shade.color = _alpha(Palette.DARK_PANEL_DEEP, 0.30)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var root := Control.new()
	root.name = "StatusRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_build_header(root)
	_build_player_panel(root)
	_build_summary_panel(root)
	_build_inventory_panel(root)
	_build_footer(root)


func _build_header(root: Control) -> void:
	var header := _anchored_control(root, 0.025, 0.027, 0.975, 0.160)
	header.name = "StatusHeader"
	_add_framed_backdrop(header, true)

	var wheel := _status_label("◎", 38, Palette.GOLD_BRIGHT, true, 2)
	wheel.name = "StatusHeaderIcon"
	wheel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wheel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(header, wheel, 0.020, 0.130, 0.075, 0.800)

	var title := _status_label("ステータス", 36, Palette.TEXT_BONE, true, 3)
	title.name = "StatusTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(header, title, 0.085, 0.100, 0.430, 0.610)

	var subtitle := _status_label("成長状況、所持品、釣果を確認できます", 15, Palette.FOAM, false, 1)
	subtitle.name = "StatusSubtitle"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(header, subtitle, 0.088, 0.565, 0.450, 0.880)

	_player_status_bar = PlayerStatusBarScript.new()
	_player_status_bar.name = "StatusPlayerStatusBar"
	_place_control(header, _player_status_bar, 0.530, 0.150, 0.965, 0.850)


func _build_player_panel(root: Control) -> void:
	_player_panel = _section_panel(root, 0.035, 0.178, 0.292, 0.848, "プレイヤー", 0)
	_player_panel.name = "StatusPlayerPanel"

	var stats := PlayerProgress.get_base_stats()
	var exp_required := PlayerProgress.exp_to_next_level()
	var exp_ratio := 1.0 if exp_required <= 0 else clampf(float(PlayerProgress.exp) / float(exp_required), 0.0, 1.0)

	var exp_title := _status_label("食経験値", 16, Palette.TEXT_BODY, true)
	exp_title.name = "StatusExpTitle"
	exp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	exp_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(_player_panel, exp_title, 0.090, 0.120, 0.450, 0.165)

	var exp_value := _status_label(_exp_text(), 16, Palette.TEXT_DARK, true)
	exp_value.name = "StatusExpValue"
	exp_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	exp_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(_player_panel, exp_value, 0.465, 0.120, 0.890, 0.165)

	var exp_bar := GaugeBarScript.new()
	exp_bar.name = "StatusExpGauge"
	exp_bar.show_value = false
	exp_bar.critical_threshold = 0.0
	exp_bar.min_value = 0.0
	exp_bar.max_value = 1.0
	exp_bar.value = exp_ratio
	exp_bar.set_colors(Palette.GAUGE_CYAN, Palette.GAUGE_CYAN_HI)
	_place_control(_player_panel, exp_bar, 0.090, 0.178, 0.890, 0.214)

	var stat_rows := [
		{"label": "最大体力", "value": "%d" % int(round(float(stats["max_energy"])))},
		{"label": "巻力", "value": "%.1f" % float(stats["reel_power"])},
		{"label": "技量", "value": "%d" % int(stats["technique"])},
		{"label": "集中力", "value": "%d" % int(stats["focus"])},
		{
			"label": "安全域",
			"value": "%d〜%d%%" % [
				int(round(float(stats["safe_min"]) * 100.0)),
				int(round(float(stats["safe_max"]) * 100.0)),
			],
		},
	]
	var row_top := 0.255
	for row in stat_rows:
		_add_stat_row(_player_panel, row_top, String(row["label"]), String(row["value"]))
		row_top += 0.072

	_add_equipment_card(_player_panel, 0.638, "装備中の竿", String(stats["rod_name"]))
	_add_equipment_card(_player_panel, 0.744, "船", _best_boat_text())
	_add_meal_effect_card(_player_panel)


func _build_summary_panel(root: Control) -> void:
	_summary_panel = _section_panel(root, 0.302, 0.178, 0.660, 0.848, "釣果サマリー", 1)
	_summary_panel.name = "StatusCatchSummaryPanel"

	var found := _discovered_fish_count()
	var total := GameData.get_all_fish_ids().size()
	var total_catches := _total_catch_count()
	var max_record := _best_size_record()
	var max_label := "--.- cm"
	if not max_record.is_empty():
		max_label = "%.1f cm" % float(max_record.get("size", 0.0))
	var spot_count := _recorded_spot_count()

	var badge := _summary_badge()
	_place_control(_summary_panel, badge, 0.070, 0.116, 0.310, 0.352)

	var metrics := [
		{"label": "発見済み魚種", "value": "%d / %d 種類" % [found, total]},
		{"label": "釣った総数", "value": "%d 匹" % total_catches},
		{"label": "最大サイズ記録", "value": max_label},
		{"label": "記録釣り場", "value": "%d 箇所" % spot_count},
	]
	var metric_top := 0.125
	for metric in metrics:
		_add_metric_row(_summary_panel, metric_top, String(metric["label"]), String(metric["value"]))
		metric_top += 0.068

	var recent_title := _status_label("最近釣れた魚", 17, Palette.TEXT_BODY, true)
	recent_title.name = "StatusRecentFishTitle"
	recent_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	recent_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(_summary_panel, recent_title, 0.070, 0.385, 0.500, 0.430)
	_add_rule(_summary_panel, 0.070, 0.432, 0.930, _alpha(Palette.WOOD_DARK, 0.32), 1.0)

	var fish_ids := _recent_fish_ids(4)
	for index in range(4):
		var left := 0.070 + float(index) * 0.220
		var right := left + 0.195
		if index < fish_ids.size():
			_add_recent_fish_card(_summary_panel, Rect2(left, 0.455, right - left, 0.230), fish_ids[index])
		else:
			_add_empty_fish_card(_summary_panel, Rect2(left, 0.455, right - left, 0.230))

	var completion_title := _status_label("図鑑コンプリート率", 17, Palette.TEXT_BODY, true)
	completion_title.name = "StatusCompletionTitle"
	completion_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	completion_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(_summary_panel, completion_title, 0.070, 0.735, 0.520, 0.785)

	var completion_ratio := 0.0 if total <= 0 else float(found) / float(total)
	var completion_bar := GaugeBarScript.new()
	completion_bar.name = "StatusCompletionGauge"
	completion_bar.show_value = false
	completion_bar.critical_threshold = 0.0
	completion_bar.min_value = 0.0
	completion_bar.max_value = 1.0
	completion_bar.value = completion_ratio
	completion_bar.set_colors(Palette.GAUGE_CYAN, Palette.GAUGE_GREEN_HI)
	_place_control(_summary_panel, completion_bar, 0.070, 0.805, 0.780, 0.850)

	var completion_value := _status_label("%d%%" % int(round(completion_ratio * 100.0)), 25, Palette.TEXT_DARK, true)
	completion_value.name = "StatusCompletionValue"
	completion_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	completion_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(_summary_panel, completion_value, 0.800, 0.780, 0.930, 0.870)


func _build_inventory_panel(root: Control) -> void:
	_inventory_panel = _section_panel(root, 0.670, 0.178, 0.965, 0.848, "所持品・料理", 2)
	_inventory_panel.name = "StatusInventoryPanel"

	var cooler_title := _mini_section_label(_inventory_panel, 0.105, "クーラーボックス")
	cooler_title.name = "StatusCoolerTitle"
	_add_cooler_grid(_inventory_panel)

	var rods_title := _mini_section_label(_inventory_panel, 0.455, "所持している竿")
	rods_title.name = "StatusOwnedRodsTitle"
	_add_owned_rods(_inventory_panel)

	var meals_title := _mini_section_label(_inventory_panel, 0.625, "料理・食事効果ログ")
	meals_title.name = "StatusMealLogTitle"
	_add_meal_log(_inventory_panel)


func _build_footer(root: Control) -> void:
	var footer := _anchored_control(root, 0.035, 0.868, 0.965, 0.970)
	footer.name = "StatusFooter"
	_add_framed_backdrop(footer, true)

	_message_label = _status_label("魚図鑑や料理へ移動しても、成長と所持品の状態は保持されます。", 15, Palette.FOAM, false, 1)
	_message_label.name = "StatusFooterMessage"
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(footer, _message_label, 0.030, 0.160, 0.420, 0.820)

	_fish_book_button = _textured_button("魚図鑑", func() -> void: navigate("fish_book"), false)
	_fish_book_button.name = "StatusFishBookButton"
	_fish_book_button.set_meta("status_nav", "fish_book")
	_add_button_icon(_fish_book_button, ICON_FISH_BOOK_PATH, false)
	_place_control(footer, _fish_book_button, 0.445, 0.170, 0.610, 0.830)

	_cooking_button = _textured_button("料理・食事", func() -> void: navigate("cooking"), false)
	_cooking_button.name = "StatusCookingButton"
	_cooking_button.set_meta("status_nav", "cooking")
	_add_button_icon(_cooking_button, ICON_COOKING_PATH, false)
	_place_control(footer, _cooking_button, 0.635, 0.170, 0.795, 0.830)

	_return_button = make_return_button(func() -> void: navigate("harbor"), 0.0)
	_return_button.name = "StatusReturnButton"
	_return_button.set_meta("status_nav", "harbor")
	_return_button.add_theme_font_override("font", GameFontsScript.extra_bold(get_theme_default_font()))
	_return_button.add_theme_font_size_override("font_size", 24)
	_place_control(footer, _return_button, 0.815, 0.120, 0.975, 0.880)


func _section_panel(parent: Control, left: float, top: float, right: float, bottom: float, title: String, icon_index: int) -> Control:
	var panel := _anchored_control(parent, left, top, right, bottom)
	panel.clip_contents = true
	_add_paper_backdrop(panel)

	var ribbon := Panel.new()
	ribbon.name = "StatusSectionRibbon_%s" % title
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ribbon.add_theme_stylebox_override("panel", _dark_plate_style())
	_place_control(panel, ribbon, 0.055, 0.028, 0.690, 0.105)

	var icon := _status_label(_section_icon(icon_index), 20, Palette.GOLD_BRIGHT, true, 1)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(panel, icon, 0.070, 0.038, 0.145, 0.098)

	var title_label := _status_label(title, 21, Palette.TEXT_BONE, true, 2)
	title_label.name = "StatusSectionTitle_%s" % title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(panel, title_label, 0.155, 0.034, 0.660, 0.100)
	return panel


func _add_paper_backdrop(parent: Control) -> void:
	var shadow := Panel.new()
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.add_theme_stylebox_override("panel", _outer_panel_style())
	shadow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(shadow)

	var paper := _texture_rect(COMMON_PARCHMENT_CARD_PATH)
	paper.modulate = _alpha(Palette.PARCHMENT, 0.96)
	_place_control(parent, paper, 0.018, 0.022, 0.982, 0.978)

	var wash := ColorRect.new()
	wash.color = _alpha(Palette.PARCHMENT_DEEP, 0.18)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(parent, wash, 0.035, 0.052, 0.965, 0.950)


func _add_framed_backdrop(parent: Control, dark: bool) -> void:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _header_style() if dark else _outer_panel_style())
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(panel)


func _add_stat_row(parent: Control, top: float, label_text: String, value_text: String) -> void:
	var row := Panel.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_stylebox_override("panel", _row_style())
	_place_control(parent, row, 0.080, top, 0.895, top + 0.054)

	var label := _status_label(label_text, 16, Palette.TEXT_BODY, false)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(row, label, 0.040, 0.0, 0.560, 1.0)

	var value := _status_label(value_text, 17, Palette.TEXT_DARK, true)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(row, value, 0.560, 0.0, 0.960, 1.0)


func _add_equipment_card(parent: Control, top: float, label_text: String, value_text: String) -> void:
	var card := Panel.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", _sub_card_style())
	_place_control(parent, card, 0.080, top, 0.895, top + 0.084)

	var title := _status_label(label_text, 13, Palette.TEXT_BODY, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(card, title, 0.045, 0.090, 0.955, 0.390)

	var value := _status_label(value_text, 16, Palette.TEXT_DARK, true)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(card, value, 0.045, 0.390, 0.955, 0.900)


func _add_meal_effect_card(parent: Control) -> void:
	var card := Panel.new()
	card.name = "StatusNextMealCard"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_theme_stylebox_override("panel", _sub_card_style())
	_place_control(parent, card, 0.080, 0.852, 0.895, 0.946)

	var title := _status_label("次の釣行の食事効果", 13, Palette.TEXT_BODY, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(card, title, 0.045, 0.080, 0.955, 0.360)

	var text := "なし"
	if not PlayerProgress.pending_buff.is_empty():
		text = String(PlayerProgress.pending_buff.get("name", "料理"))
	var value := _status_label(text, 15, Palette.TEXT_DARK, true)
	value.name = "StatusNextMealValue"
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(card, value, 0.045, 0.380, 0.955, 0.890)


func _summary_badge() -> Control:
	var badge := Control.new()
	badge.name = "StatusSummaryBadge"
	var disk := Panel.new()
	disk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	disk.add_theme_stylebox_override("panel", _round_badge_style())
	disk.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	badge.add_child(disk)

	var fish_ids := _recent_fish_ids(1)
	if not fish_ids.is_empty():
		var fish := GameData.get_fish(fish_ids[0])
		var portrait := TextureRect.new()
		portrait.texture = _fish_portrait_texture(fish)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place_control(badge, portrait, 0.040, 0.050, 0.960, 0.830)
	else:
		var mark := _status_label("釣", 42, Palette.GOLD_BRIGHT, true, 2)
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_place_control(badge, mark, 0.0, 0.0, 1.0, 0.870)

	var anchor := _status_label("記録", 13, Palette.TEXT_BONE, true, 1)
	anchor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	anchor.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(badge, anchor, 0.250, 0.760, 0.750, 1.020)
	return badge


func _add_metric_row(parent: Control, top: float, label_text: String, value_text: String) -> void:
	var row := Panel.new()
	row.name = "StatusMetric_%s" % label_text
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_stylebox_override("panel", _row_style())
	_place_control(parent, row, 0.365, top, 0.930, top + 0.052)

	var label := _status_label(label_text, 14, Palette.TEXT_BODY, false)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(row, label, 0.040, 0.0, 0.565, 1.0)

	var value := _status_label(value_text, 17, Palette.TEXT_DARK, true)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(row, value, 0.545, 0.0, 0.960, 1.0)


func _add_recent_fish_card(parent: Control, ratios: Rect2, fish_id: String) -> void:
	var fish := GameData.get_fish(fish_id)
	var card := _card_container(parent, ratios, "StatusRecentFish_%s" % fish_id)
	var portrait := TextureRect.new()
	portrait.texture = _fish_portrait_texture(fish)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(card, portrait, 0.030, 0.105, 0.970, 0.515)

	var name := _status_label(String(fish.get("name", fish_id)), 15, Palette.TEXT_DARK, true)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(card, name, 0.050, 0.515, 0.950, 0.650)

	var rarity := String(fish.get("rarity", ""))
	var badge := Panel.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_stylebox_override("panel", _rarity_badge_style(rarity))
	_place_control(card, badge, 0.090, 0.655, 0.560, 0.790)
	var rarity_label := _status_label(rarity, 10, RarityStylesScript.text_color(rarity), true, 1)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(badge, rarity_label, 0.0, 0.0, 1.0, 1.0)

	var count := int(PlayerProgress.caught_counts.get(fish_id, 0))
	var best := float(PlayerProgress.best_sizes.get(fish_id, 0.0))
	var detail := _status_label("%d匹 / %.1fcm" % [count, best], 11, Palette.TEXT_BODY, true)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(card, detail, 0.050, 0.800, 0.950, 0.960)


func _add_empty_fish_card(parent: Control, ratios: Rect2) -> void:
	var card := _card_container(parent, ratios, "StatusRecentFishEmpty")
	var empty := _status_label("未記録", 14, Palette.TEXT_BODY, true)
	empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(card, empty, 0.0, 0.0, 1.0, 1.0)


func _add_cooler_grid(parent: Control) -> void:
	var ids := _inventory_fish_ids(8)
	for index in range(8):
		var col := index % 4
		var row := index / 4
		var left := 0.070 + float(col) * 0.220
		var top := 0.160 + float(row) * 0.132
		var card := _card_container(parent, Rect2(left, top, 0.192, 0.112), "StatusCoolerSlot_%d" % index)
		if index >= ids.size():
			var empty := _status_label("空", 12, Palette.TEXT_BODY, true)
			empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			_place_control(card, empty, 0.0, 0.0, 1.0, 1.0)
			continue
		var fish_id := ids[index]
		var fish := GameData.get_fish(fish_id)
		var portrait := TextureRect.new()
		portrait.texture = _fish_portrait_texture(fish)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place_control(card, portrait, 0.010, 0.030, 0.990, 0.620)
		var label := _status_label("%s ×%d" % [String(fish.get("name", fish_id)), PlayerProgress.fish_count(fish_id)], 10, Palette.TEXT_DARK, true)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_place_control(card, label, 0.025, 0.650, 0.975, 0.960)


func _add_owned_rods(parent: Control) -> void:
	var rods: Array[String] = []
	if PlayerProgress.equipped_rod_id in PlayerProgress.owned_rods:
		rods.append(PlayerProgress.equipped_rod_id)
	for rod_id in PlayerProgress.owned_rods:
		if rod_id not in rods:
			rods.append(rod_id)
	if rods.is_empty():
		var empty := _status_label("まだありません", 14, Palette.TEXT_BODY, false)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_place_control(parent, empty, 0.070, 0.505, 0.930, 0.570)
		return

	var max_rows := mini(rods.size(), 2)
	for index in range(max_rows):
		var rod_id := rods[index]
		var rod := GameData.get_rod(rod_id)
		var equipped := rod_id == PlayerProgress.equipped_rod_id
		var value := "%s%s" % [String(rod.get("name", rod_id)), "（装備中）" if equipped else ""]
		_add_log_row(parent, 0.500 + float(index) * 0.060, value, equipped)


func _add_meal_log(parent: Control) -> void:
	var rows := _meal_log_rows(3)
	if rows.is_empty():
		var empty := _status_label("まだありません", 14, Palette.TEXT_BODY, false)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_place_control(parent, empty, 0.070, 0.710, 0.930, 0.825)
		return

	for index in range(rows.size()):
		_add_log_row(parent, 0.680 + float(index) * 0.077, String(rows[index]), index == 0 and not PlayerProgress.pending_buff.is_empty())


func _add_log_row(parent: Control, top: float, text: String, accent := false) -> void:
	var row := Panel.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_stylebox_override("panel", _log_row_style(accent))
	_place_control(parent, row, 0.070, top, 0.930, top + 0.052)

	var dot := Panel.new()
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.add_theme_stylebox_override("panel", _dot_style(Palette.GAUGE_GREEN if accent else Palette.TEXT_BODY))
	_place_control(row, dot, 0.032, 0.300, 0.062, 0.700)

	var label := _status_label(text, 13, Palette.TEXT_DARK if accent else Palette.TEXT_BODY, accent)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(row, label, 0.085, 0.0, 0.960, 1.0)


func _mini_section_label(parent: Control, top: float, text: String) -> Label:
	var title := _status_label(text, 15, Palette.TEXT_BODY, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(parent, title, 0.070, top, 0.930, top + 0.045)
	_add_rule(parent, 0.070, top + 0.047, 0.930, _alpha(Palette.WOOD_DARK, 0.30), 1.0)
	return title


func _card_container(parent: Control, ratios: Rect2, node_name: String) -> Control:
	var card := Control.new()
	card.name = node_name
	card.clip_contents = true
	_place_control(parent, card, ratios.position.x, ratios.position.y, ratios.position.x + ratios.size.x, ratios.position.y + ratios.size.y)
	var frame := _texture_rect(COMMON_CARD_FRAME_PATH)
	frame.modulate = _alpha(Palette.PARCHMENT, 0.98)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_child(frame)
	return card


func _textured_button(text: String, callback: Callable, primary := false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0.0, 50.0)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(callback)
	button.add_theme_font_override("font", GameFontsScript.extra_bold(get_theme_default_font()))
	button.add_theme_font_size_override("font_size", 21 if not primary else 23)
	button.add_theme_color_override("font_color", Palette.TEXT_BONE if primary else Palette.TEXT_DARK)
	button.add_theme_color_override("font_hover_color", Palette.GOLD_BRIGHT if primary else Palette.TEXT_DARK)
	button.add_theme_color_override("font_pressed_color", Palette.GOLD_BRIGHT if primary else Palette.TEXT_DARK)
	button.add_theme_color_override("font_outline_color", Palette.TEXT_OUTLINE_DARK if primary else Palette.GOLD_BRIGHT)
	button.add_theme_constant_override("outline_size", 2 if primary else 1)
	var normal_path := COMMON_BUTTON_PRIMARY_PATH if primary else COMMON_BUTTON_PATH
	var hover_path := COMMON_BUTTON_PRIMARY_PATH if primary else COMMON_BUTTON_HOVER_PATH
	var normal := _texture_style(normal_path, Vector4(44.0, 24.0, 44.0, 24.0))
	var hover := _texture_style(hover_path, Vector4(44.0, 24.0, 44.0, 24.0))
	if normal != null:
		button.add_theme_stylebox_override("normal", normal)
	if hover != null:
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("focus", hover)
		button.add_theme_stylebox_override("pressed", hover)
	_wire_button_juice(button)
	return button


func _add_button_icon(button: Button, path: String, primary: bool) -> void:
	var texture := ShowcaseAssets.load_texture(path)
	if texture == null:
		return
	var icon := TextureRect.new()
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.modulate = _alpha(Palette.TEXT_BONE, 0.92) if primary else _alpha(Palette.GOLD_BRIGHT, 0.82)
	_place_control(button, icon, 0.060, 0.210, 0.230, 0.790)


func _status_label(text: String, font_size: int, color: Color, bold := false, outline := 0) -> Label:
	return make_screen_label(text, font_size, color, bold, outline)


func _section_icon(index: int) -> String:
	match index:
		0:
			return "⚓"
		1:
			return "◆"
		2:
			return "□"
		_:
			return "◆"


func _exp_text() -> String:
	var required := PlayerProgress.exp_to_next_level()
	if required <= 0:
		return "MAX"
	return "%d / %d" % [PlayerProgress.exp, required]


func _best_boat_text() -> String:
	var boat := PlayerProgress.get_best_boat()
	if boat.is_empty():
		return "なし"
	return String(boat.get("name", "船"))


func _discovered_fish_count() -> int:
	var found := 0
	for fish_id in GameData.get_all_fish_ids():
		if int(PlayerProgress.caught_counts.get(fish_id, 0)) > 0:
			found += 1
	return found


func _total_catch_count() -> int:
	var total := 0
	for fish_id in GameData.get_all_fish_ids():
		total += int(PlayerProgress.caught_counts.get(fish_id, 0))
	return total


func _recorded_spot_count() -> int:
	var count := 0
	for spot_id in PlayerProgress.spot_caught_counts.keys():
		var spot_counts = PlayerProgress.spot_caught_counts[spot_id]
		if typeof(spot_counts) == TYPE_DICTIONARY and not Dictionary(spot_counts).is_empty():
			count += 1
	return count


func _best_size_record() -> Dictionary:
	var best := 0.0
	var best_id := ""
	for fish_id in GameData.get_all_fish_ids():
		var size := float(PlayerProgress.best_sizes.get(fish_id, 0.0))
		if size > best:
			best = size
			best_id = fish_id
	if best_id.is_empty():
		return {}
	return {"fish_id": best_id, "size": best}


func _recent_fish_ids(limit: int) -> Array[String]:
	var ids: Array[String] = []
	for fish_id in GameData.get_all_fish_ids():
		if int(PlayerProgress.caught_counts.get(fish_id, 0)) > 0:
			ids.append(fish_id)
	ids.sort_custom(
		func(a: String, b: String) -> bool:
			var count_a := int(PlayerProgress.caught_counts.get(a, 0))
			var count_b := int(PlayerProgress.caught_counts.get(b, 0))
			if count_a == count_b:
				return String(GameData.get_fish(a).get("fish_no", "")) < String(GameData.get_fish(b).get("fish_no", ""))
			return count_a > count_b
	)
	if ids.size() > limit:
		ids.resize(limit)
	return ids


func _inventory_fish_ids(limit: int) -> Array[String]:
	var ids: Array[String] = []
	for fish_id in GameData.get_all_fish_ids():
		if PlayerProgress.fish_count(fish_id) > 0:
			ids.append(fish_id)
	ids.sort_custom(
		func(a: String, b: String) -> bool:
			var count_a := PlayerProgress.fish_count(a)
			var count_b := PlayerProgress.fish_count(b)
			if count_a == count_b:
				return String(GameData.get_fish(a).get("fish_no", "")) < String(GameData.get_fish(b).get("fish_no", ""))
			return count_a > count_b
	)
	if ids.size() > limit:
		ids.resize(limit)
	return ids


func _meal_log_rows(limit: int) -> Array[String]:
	var rows: Array[String] = []
	if not PlayerProgress.pending_buff.is_empty():
		rows.append("%s / 次の釣行で発動" % String(PlayerProgress.pending_buff.get("name", "料理")))
	for dish_key_variant in PlayerProgress.eaten_recipes.keys():
		if rows.size() >= limit:
			break
		var dish_key := String(dish_key_variant)
		var parts := dish_key.split(":")
		if parts.size() != 2:
			continue
		var fish := GameData.get_fish(parts[0])
		var recipe := GameData.get_recipe(parts[1])
		if fish.is_empty() or recipe.is_empty():
			continue
		rows.append(
			"%sの%s × %d"
			% [
				String(fish.get("name", parts[0])),
				String(recipe.get("name", parts[1])),
				int(PlayerProgress.eaten_recipes[dish_key]),
			]
		)
	if rows.size() > limit:
		rows.resize(limit)
	return rows


func _fish_portrait_texture(fish: Dictionary) -> Texture2D:
	var texture := ShowcaseAssets.load_texture(FightFishAssets.card_portrait_path(fish))
	if texture != null:
		return texture
	return UITextures.get_fish_icon(Palette.SEA_MID)


func _texture_rect(path: String) -> TextureRect:
	return ShowcaseAssetsScript.texture_rect(path)


func _texture_style(path: String, margins: Vector4) -> StyleBoxTexture:
	return ShowcaseAssetsScript.texture_style(path, margins)

func _add_rule(parent: Control, left: float, y: float, right: float, color: Color, thickness: float) -> void:
	var rule := ColorRect.new()
	rule.color = color
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rule.anchor_left = left
	rule.anchor_top = y
	rule.anchor_right = right
	rule.anchor_bottom = y
	rule.offset_left = 0.0
	rule.offset_top = 0.0
	rule.offset_right = 0.0
	rule.offset_bottom = thickness
	parent.add_child(rule)


func _alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)


func _outer_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _alpha(Palette.WOOD_DARK, 0.94)
	style.border_color = Palette.GOLD_DEEP
	style.set_border_width_all(3)
	style.set_corner_radius_all(5)
	style.shadow_color = _alpha(Palette.DARK_PANEL_DEEP, 0.45)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0.0, 3.0)
	return style


func _header_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _alpha(Palette.DARK_PANEL, 0.96)
	style.border_color = Palette.GOLD_DEEP
	style.set_border_width_all(3)
	style.set_corner_radius_all(5)
	style.shadow_color = _alpha(Palette.DARK_PANEL_DEEP, 0.45)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0.0, 3.0)
	return style


func _dark_plate_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _alpha(Palette.DARK_PANEL, 0.96)
	style.border_color = Palette.GOLD_DEEP
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	return style


func _row_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _alpha(Palette.PARCHMENT, 0.42)
	style.border_color = _alpha(Palette.WOOD_DARK, 0.22)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	return style


func _sub_card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _alpha(Palette.PARCHMENT_DEEP, 0.34)
	style.border_color = _alpha(Palette.WOOD_DARK, 0.30)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style


func _round_badge_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _alpha(Palette.SEA_MID, 0.48)
	style.border_color = Palette.GOLD_DEEP
	style.set_border_width_all(3)
	style.set_corner_radius_all(80)
	style.shadow_color = _alpha(Palette.DARK_PANEL_DEEP, 0.35)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0.0, 3.0)
	return style


func _rarity_badge_style(rarity: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = RarityStylesScript.badge_color(rarity)
	style.border_color = RarityStylesScript.border_color(rarity)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	return style


func _log_row_style(accent: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _alpha(Palette.GAUGE_GREEN_HI if accent else Palette.PARCHMENT, 0.28 if accent else 0.34)
	style.border_color = _alpha(Palette.GAUGE_GREEN if accent else Palette.WOOD_DARK, 0.42 if accent else 0.20)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style


func _dot_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Palette.TEXT_OUTLINE_DARK
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	return style
