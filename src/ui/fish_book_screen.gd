extends "res://src/ui/screen_base.gd"

const FightFishAssets = preload("res://src/ui/fight_fish_assets.gd")
const GameFontsScript = preload("res://src/ui/game_fonts.gd")
const PlayerStatusBarScript = preload("res://src/ui/components/player_status_bar.gd")
const RarityStylesScript = preload("res://src/ui/rarity_styles.gd")

const FISH_BOOK_BG_PATH := "res://assets/showcase/fish_book/fish_book_bg.png"
const FISH_BOOK_BOOK_FRAME_PATH := "res://assets/showcase/fish_book/fish_book_book_frame.png"
const FISH_BOOK_HEADER_FRAME_PATH := "res://assets/showcase/fish_book/fish_book_header_frame.png"
const FISH_BOOK_TITLE_SIGN_PATH := "res://assets/showcase/fish_book/fish_book_title_sign.png"
const FISH_BOOK_MAIN_FRAME_PATH := "res://assets/showcase/fish_book/fish_book_main_frame.png"
const FISH_BOOK_DETAIL_FRAME_PATH := "res://assets/showcase/fish_book/fish_book_detail_frame.png"
const FISH_BOOK_DETAIL_PAPER_PATH := "res://assets/showcase/fish_book/fish_book_detail_paper.png"
const FISH_BOOK_FOOTER_FRAME_PATH := "res://assets/showcase/fish_book/fish_book_footer_frame.png"
const FISH_BOOK_THUMB_BASE_PATH := "res://assets/showcase/fish_book/thumbs"
const FISH_BOOK_CARD_FRAME_PATH := "res://assets/showcase/fish_book/fish_book_card_frame.png"
const FISH_BOOK_CARD_SELECTED_FRAME_PATH := "res://assets/showcase/fish_book/fish_book_card_selected_frame.png"
const FISH_BOOK_CARD_LOCKED_FRAME_PATH := "res://assets/showcase/fish_book/fish_book_card_locked_frame.png"
const COMMON_STATUS_BAR_PATH := "res://assets/showcase/common/status_bar_frame.png"
const COMMON_DETAIL_ICON_SHEET_PATH := "res://assets/showcase/common/detail_icon_sheet.png"
const COMMON_FOOTER_ICON_SHEET_PATH := "res://assets/showcase/common/footer_icon_sheet.png"
const COMMON_BADGE_FRAME_PATH := "res://assets/showcase/common/badge_frame.png"
const COMMON_DETAIL_ROW_FRAME_PATH := "res://assets/showcase/common/detail_row_frame.png"
const COMMON_BUTTON_PATH := "res://assets/showcase/common/button_frame.png"
const COMMON_BUTTON_HOVER_PATH := "res://assets/showcase/common/button_frame_hover.png"
const COMMON_BUTTON_PRIMARY_PATH := "res://assets/showcase/common/button_frame_primary.png"
const COMMON_PARCHMENT_CARD_PATH := "res://assets/showcase/common/parchment_card.png"
const FISH_BOOK_ICON_SIZE := 96.0

const FILTERS := [
	{"id": "all", "label": "全魚", "icon": 1},
	{"id": "harbor", "label": "港内", "icon": 2},
	{"id": "sand", "label": "砂浜", "icon": 0},
	{"id": "rock", "label": "岩礁", "icon": 3},
	{"id": "offshore", "label": "沖", "icon": 0},
	{"id": "rare", "label": "レア", "icon": 3},
]

var _active_filter := "all"
var _selected_fish_id := ""
var _fish_card_buttons: Dictionary = {}
var _filter_buttons: Dictionary = {}

var _found_label: Label
var _player_status_bar: PlayerStatusBar
var _grid: GridContainer
var _detail_no_label: Label
var _detail_name_label: Label
var _detail_rarity_label: Label
var _detail_portrait: TextureRect
var _detail_portrait_shadow: TextureRect
var _detail_count_label: Label
var _detail_best_label: Label
var _detail_habitat_label: Label
var _detail_bait_label: Label
var _detail_behavior_label: Label
var _detail_spots: Control
var _detail_icon_sheet: Texture2D
var _footer_icon_sheet: Texture2D
var _portrait_crop_cache: Dictionary = {}


func _build_screen() -> void:
	_detail_icon_sheet = _load_texture_if_exists(COMMON_DETAIL_ICON_SHEET_PATH)
	_footer_icon_sheet = _load_texture_if_exists(COMMON_FOOTER_ICON_SHEET_PATH)
	_build_background()
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_build_book_backplate(root)
	_build_header(root)
	_build_book_grid(root)
	_build_detail_panel(root)
	_build_footer(root)
	_ensure_valid_selection()
	_refresh_all()


func _build_background() -> void:
	var bg := _texture_rect(FISH_BOOK_BG_PATH)
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	move_child(bg, 0)

	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.07, 0.10, 0.42)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)


func _build_book_backplate(root: Control) -> void:
	var frame := _texture_rect(FISH_BOOK_BOOK_FRAME_PATH)
	_place_control(root, frame, 0.018, 0.018, 0.982, 0.982)


func _build_header(root: Control) -> void:
	var header := _anchored_control(root, 0.018, 0.020, 0.982, 0.154)

	var found_bar := _texture_rect(COMMON_STATUS_BAR_PATH)
	_place_control(header, found_bar, 0.022, 0.188, 0.276, 0.820)
	_found_label = _book_label("発見済み 0/0", 22, Color("#fff2c6"), true, 2, Color("#07131d"))
	_found_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_found_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(header, _found_label, 0.034, 0.230, 0.264, 0.770)

	var sign := _texture_rect(FISH_BOOK_TITLE_SIGN_PATH)
	_place_control(header, sign, 0.345, -0.045, 0.655, 1.020)
	var title := _book_label("魚図鑑", 42, Color("#fff0aa"), true, 4, Color("#2a1608"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(header, title, 0.385, 0.130, 0.615, 0.820)

	_player_status_bar = PlayerStatusBarScript.new()
	_player_status_bar.name = "FishBookPlayerStatusBar"
	_player_status_bar.z_index = 20
	_place_control(header, _player_status_bar, 0.642, 0.188, 0.978, 0.820)


func _build_book_grid(root: Control) -> void:
	var left := _anchored_control(root, 0.030, 0.165, 0.596, 0.872)
	var fill := ColorRect.new()
	fill.color = _alpha(Palette.WOOD_DARK, 0.78)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(left, fill, 0.018, 0.028, 0.982, 0.965)

	var frame := _texture_rect(FISH_BOOK_MAIN_FRAME_PATH)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	left.add_child(frame)

	var header_wash := _label_plate(_alpha(Palette.PARCHMENT_DEEP, 0.22))
	_place_control(left, header_wash, 0.050, 0.040, 0.935, 0.100)
	_add_rule(left, 0.065, 0.100, 0.920, _alpha(Palette.GOLD_DEEP, 0.24), 1.0)

	var title_plate := _label_plate(_alpha(Palette.WOOD_DARK, 0.88))
	_place_control(left, title_plate, 0.052, 0.036, 0.272, 0.102)

	var title := _book_label("魚の記録", 22, Palette.TEXT_BONE, true, 2, Palette.TEXT_OUTLINE_LIGHT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(left, title, 0.070, 0.035, 0.285, 0.105)

	var hint := _book_label("発見した魚の写し絵と釣果", 13, Palette.TEXT_BONE, false, 1, Palette.TEXT_OUTLINE_LIGHT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(left, hint, 0.330, 0.044, 0.920, 0.102)

	var scroll := ScrollContainer.new()
	scroll.name = "FishBookScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_style_scrollbar(scroll)
	_place_control(left, scroll, 0.047, 0.105, 0.955, 0.970)

	_grid = GridContainer.new()
	_grid.name = "FishBookGrid"
	_grid.columns = 3
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("hseparation", 6)
	_grid.add_theme_constant_override("vseparation", 3)
	scroll.add_child(_grid)


func _build_detail_panel(root: Control) -> void:
	var detail := _anchored_control(root, 0.602, 0.165, 0.970, 0.872)
	var page_paper := _texture_rect(FISH_BOOK_DETAIL_PAPER_PATH)
	_place_control(detail, page_paper, 0.044, 0.032, 0.958, 0.968)

	var frame := _texture_rect(FISH_BOOK_DETAIL_FRAME_PATH)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	detail.add_child(frame)

	var header_wash := _label_plate(_alpha(Palette.PARCHMENT_DEEP, 0.92))
	_place_control(detail, header_wash, 0.082, 0.052, 0.918, 0.150)
	_add_rule(detail, 0.095, 0.126, 0.905, _alpha(Palette.GOLD_DEEP, 0.30), 1.0)

	var number_plate := _label_plate(_alpha(Palette.WOOD_DARK, 0.88))
	_place_control(detail, number_plate, 0.082, 0.052, 0.318, 0.118)

	_detail_no_label = _book_label("No.000", 18, Palette.GOLD_BRIGHT, true, 1, Palette.TEXT_OUTLINE_DARK)
	_detail_no_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_detail_no_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(detail, _detail_no_label, 0.098, 0.058, 0.308, 0.108)

	_detail_name_label = _book_label("アジ", 36, Color("#2a1a0c"), true, 0)
	_detail_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(detail, _detail_name_label, 0.265, 0.068, 0.756, 0.150)

	var detail_badge := _texture_rect(COMMON_BADGE_FRAME_PATH)
	_place_control(detail, detail_badge, 0.760, 0.066, 0.940, 0.150)
	_detail_rarity_label = _book_label("コモン", 16, Color.WHITE, true, 2, Color("#07131d"))
	_detail_rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_rarity_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(detail, _detail_rarity_label, 0.762, 0.072, 0.928, 0.145)

	_detail_portrait_shadow = _portrait_rect(Color(0.18, 0.105, 0.040, 0.20))
	_detail_portrait = _portrait_rect(_portrait_paper_tint())
	var portrait_bg := ColorRect.new()
	portrait_bg.color = Color("#f5e4ba", 0.84)
	portrait_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(detail, portrait_bg, 0.090, 0.155, 0.920, 0.505)
	var portrait_paper := _texture_rect(COMMON_PARCHMENT_CARD_PATH)
	portrait_paper.modulate = Color(1.0, 0.98, 0.88, 0.76)
	_place_control(detail, portrait_paper, 0.078, 0.145, 0.935, 0.510)
	_add_rule(detail, 0.095, 0.160, 0.915, Color("#7e5a2b", 0.45), 2.0)
	_add_rule(detail, 0.095, 0.505, 0.915, Color("#7e5a2b", 0.35), 1.0)
	var detail_portrait_clip := _portrait_clip()
	_place_control(detail, detail_portrait_clip, 0.095, 0.175, 0.915, 0.490)
	_add_specimen_rule(detail_portrait_clip, 0.030, 0.245, 0.970, 0.252, _alpha(Palette.GOLD_DEEP, 0.12))
	_add_specimen_rule(detail_portrait_clip, 0.030, 0.485, 0.970, 0.492, _alpha(Palette.GOLD_DEEP, 0.12))
	_add_specimen_rule(detail_portrait_clip, 0.030, 0.725, 0.970, 0.732, _alpha(Palette.GOLD_DEEP, 0.12))
	_add_specimen_rule(detail_portrait_clip, 0.075, 0.125, 0.080, 0.870, _alpha(Palette.WOOD_DARK, 0.10))
	_place_control(detail_portrait_clip, _detail_portrait_shadow, 0.012, 0.036, 1.012, 1.036)
	_place_control(detail_portrait_clip, _detail_portrait, 0.0, 0.0, 1.0, 1.0)
	var specimen_wash := _label_plate(_alpha(Palette.PARCHMENT, 0.08))
	_place_control(detail_portrait_clip, specimen_wash, 0.0, 0.0, 1.0, 1.0)

	_detail_count_label = _book_label("釣果 0匹", 27, Color("#2b1b0d"), true, 0)
	_detail_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(detail, _detail_count_label, 0.090, 0.522, 0.500, 0.590)

	_detail_best_label = _book_label("最大 --.-cm", 21, Color("#2b1b0d"), true, 0)
	_detail_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_best_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(detail, _detail_best_label, 0.510, 0.530, 0.910, 0.585)

	_add_rule(detail, 0.095, 0.602, 0.910, Color("#7e5a2b", 0.30), 1.0)
	_detail_habitat_label = _detail_row(detail, 0.620, "生息地")
	_detail_bait_label = _detail_row(detail, 0.695, "好物")
	_detail_behavior_label = _detail_row(detail, 0.770, "行動")

	var spot_band_wash := _label_plate(_alpha(Palette.PARCHMENT_DEEP, 0.90))
	_place_control(detail, spot_band_wash, 0.086, 0.824, 0.915, 0.882)
	_add_rule(detail, 0.100, 0.826, 0.900, _alpha(Palette.GOLD_DEEP, 0.26), 1.0)
	var spot_title_plate := _label_plate(_alpha(Palette.WOOD_DARK, 0.88))
	_place_control(detail, spot_title_plate, 0.090, 0.834, 0.545, 0.884)

	var spot_title := _book_label("よく釣れる場所", 18, Palette.TEXT_BONE, true, 2, Palette.TEXT_OUTLINE_LIGHT)
	spot_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	spot_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(detail, spot_title, 0.090, 0.838, 0.560, 0.888)

	_detail_spots = Control.new()
	_detail_spots.name = "FishBookSpotStrip"
	_place_control(detail, _detail_spots, 0.088, 0.885, 0.915, 0.970)


func _detail_row(parent: Control, top: float, label_text: String) -> Label:
	var row_frame := _texture_rect(COMMON_DETAIL_ROW_FRAME_PATH)
	row_frame.modulate = Color(1.0, 1.0, 1.0, 0.40)
	_place_control(parent, row_frame, 0.082, top - 0.010, 0.918, top + 0.063)

	var plate := _label_plate(Color("#6b4521"))
	_place_control(parent, plate, 0.090, top, 0.235, top + 0.055)

	var title := _book_label(label_text, 16, Color("#fff4ce"), true, 1, Color("#2a1608"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(parent, title, 0.090, top, 0.235, top + 0.055)

	var value := _book_label("", 16, Color("#3f2b17"), false, 0)
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	value.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_place_control(parent, value, 0.270, top - 0.001, 0.902, top + 0.068)
	return value


func _build_footer(root: Control) -> void:
	var footer := _anchored_control(root, 0.024, 0.890, 0.976, 0.975)

	var x := 0.032
	for filter in FILTERS:
		var filter_id := String(filter["id"])
		var button := _textured_button(String(filter["label"]), _set_filter.bind(filter_id), false)
		button.name = "FishBookFilter_%s" % filter_id
		button.set_meta("fish_book_filter", filter_id)
		_filter_buttons[filter_id] = button
		_add_button_icon(button, _detail_icon(int(filter.get("icon", -1))), false)
		_place_control(footer, button, x, 0.155, x + 0.122, 0.850)
		x += 0.125

	var back := make_return_button(func() -> void: navigate("harbor"), 0.0)
	back.name = "FishBookReturnButton"
	back.set_meta("fish_book_return", true)
	back.add_theme_font_size_override("font_size", 21)
	_add_button_icon(back, _footer_icon(1), true)
	_place_control(footer, back, 0.792, 0.112, 0.964, 0.885)


func _refresh_all() -> void:
	_refresh_header()
	_rebuild_grid()
	_refresh_detail()
	_refresh_filter_buttons()


func _refresh_header() -> void:
	var total := GameData.get_all_fish_ids().size()
	var found := 0
	for fish_id in GameData.get_all_fish_ids():
		if _is_discovered(fish_id):
			found += 1
	_found_label.text = "発見済み  %d/%d" % [found, total]
	if _player_status_bar != null:
		_player_status_bar.refresh()


func _rebuild_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()
	_fish_card_buttons.clear()
	for fish_id in _filtered_fish_ids():
		var fish := GameData.get_fish(fish_id)
		if fish.is_empty():
			continue
		var card := _make_fish_card(fish)
		_grid.add_child(card)
		_fish_card_buttons[fish_id] = card


func _make_fish_card(fish: Dictionary) -> Button:
	var fish_id := String(fish.get("id", ""))
	var discovered := _is_discovered(fish_id)
	var selected := fish_id == _selected_fish_id
	var button := Button.new()
	button.name = "FishBookCard_%s" % fish_id
	button.text = ""
	button.custom_minimum_size = Vector2(204.0, 106.0)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.clip_contents = true
	button.set_meta("fish_book_card", fish_id)
	button.pressed.connect(_select_fish.bind(fish_id))
	_apply_card_skin(button, discovered, selected)
	_silence_button_text(button)
	_wire_button_juice(button)

	var portrait_field := Panel.new()
	portrait_field.add_theme_stylebox_override("panel", _card_portrait_field_style(discovered))
	portrait_field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(button, portrait_field, 0.070, 0.190, 0.930, 0.615)

	var no_plate := _label_plate(Color("#6b4521", 0.80) if discovered else _alpha(Palette.WOOD_DARK, 0.72))
	no_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(button, no_plate, 0.055, 0.052, 0.300, 0.178)

	var no_label := _book_label(String(fish.get("fish_no", "No.---")), 12, Palette.TEXT_BONE, true, 2, Color("#281607"))
	no_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	no_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	no_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(button, no_label, 0.055, 0.052, 0.390, 0.175)

	var name_text := String(fish.get("name", fish_id)) if discovered else "？？？？？"
	var name_color := Color("#3a230e")
	if not discovered:
		name_color = Palette.TEXT_OUTLINE_LIGHT
	var name_label := _book_label(name_text, 16, name_color, true, 0, Color("#2b1708"))
	name_label.add_theme_font_size_override("font_size", _card_name_font_size(name_text))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(button, name_label, 0.292, 0.048, 0.940, 0.185)

	var portrait_texture := _fish_card_portrait_texture(fish)
	var portrait := _portrait_rect(_alpha(Palette.WOOD_DARK, 0.62) if not discovered else _portrait_paper_tint())
	portrait.texture = portrait_texture
	var portrait_clip := _portrait_clip()
	_place_control(button, portrait_clip, 0.080, 0.198, 0.920, 0.602)
	if discovered:
		var portrait_shadow := _portrait_rect(Color(0.18, 0.105, 0.040, 0.16))
		portrait_shadow.texture = portrait_texture
		_place_control(portrait_clip, portrait_shadow, 0.014, 0.036, 1.014, 1.036)
	_place_control(portrait_clip, portrait, 0.0, 0.0, 1.0, 1.0)

	if not discovered:
		var sealed_wash := _label_plate(_alpha(Palette.PARCHMENT, 0.18))
		sealed_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place_control(button, sealed_wash, 0.070, 0.190, 0.930, 0.615)

		var mark := _book_label("？", 42, _alpha(Palette.GOLD_DEEP, 0.88), true, 2, Palette.TEXT_OUTLINE_LIGHT)
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place_control(button, mark, 0.385, 0.275, 0.615, 0.600)
		var lock_plate := _label_plate(_alpha(Palette.PARCHMENT_DEEP, 0.94))
		lock_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place_control(button, lock_plate, 0.615, 0.635, 0.930, 0.790)
		var lock_rule := _label_plate(_alpha(Palette.WOOD_DARK, 0.34))
		lock_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place_control(button, lock_rule, 0.640, 0.635, 0.910, 0.654)
		var lock := _book_label("未発見", 12, Palette.TEXT_OUTLINE_LIGHT, true, 0)
		lock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place_control(button, lock, 0.640, 0.630, 0.930, 0.790)
		return button

	var rarity := String(fish.get("rarity", ""))
	var badge_bg := _label_plate(_rarity_badge_color(rarity))
	badge_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(button, badge_bg, 0.060, 0.610, 0.438, 0.765)
	var rarity_label := _book_label(rarity, _rarity_font_size(rarity, false), Color.WHITE, true, 1, Color("#07131d"))
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rarity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(button, rarity_label, 0.066, 0.618, 0.424, 0.755)

	var count := int(PlayerProgress.caught_counts.get(fish_id, 0))
	var best := float(PlayerProgress.best_sizes.get(fish_id, 0.0))
	var stat_strip := ColorRect.new()
	stat_strip.color = _alpha(Palette.PARCHMENT_DEEP, 0.90)
	stat_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(button, stat_strip, 0.070, 0.765, 0.930, 0.945)
	var divider := ColorRect.new()
	divider.color = Color("#7c592a", 0.34)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(button, divider, 0.080, 0.778, 0.920, 0.788)
	var stat_color := Color("#2d1d0d")
	var count_label := _book_label("釣果 %d匹" % count, 12, stat_color, true, 0)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(button, count_label, 0.065, 0.796, 0.460, 0.940)

	var best_label := _book_label("最大 %.1fcm" % best, 12, stat_color, true, 0)
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	best_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	best_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(button, best_label, 0.430, 0.796, 0.930, 0.940)
	return button


func _refresh_detail() -> void:
	var fish := GameData.get_fish(_selected_fish_id)
	if fish.is_empty():
		_detail_no_label.text = "No.---"
		_detail_name_label.text = "魚を選択"
		_detail_rarity_label.text = ""
		_detail_portrait.texture = null
		_detail_portrait_shadow.texture = null
		_detail_count_label.text = "釣果 --"
		_detail_best_label.text = "最大 --.-cm"
		_detail_habitat_label.text = ""
		_detail_bait_label.text = ""
		_detail_behavior_label.text = ""
		_rebuild_spot_strip([])
		return

	var fish_id := String(fish.get("id", ""))
	var discovered := _is_discovered(fish_id)
	var rarity := String(fish.get("rarity", ""))
	_detail_no_label.text = String(fish.get("fish_no", "No.---"))
	_detail_name_label.text = String(fish.get("name", fish_id)) if discovered else "？？？？？"
	_detail_name_label.add_theme_font_size_override("font_size", _detail_name_font_size(_detail_name_label.text))
	_detail_rarity_label.text = rarity if discovered else "未発見"
	_detail_rarity_label.add_theme_font_size_override("font_size", _rarity_font_size(_detail_rarity_label.text, true))
	_detail_rarity_label.add_theme_color_override("font_color", _rarity_text_color(rarity) if discovered else Color("#e8d0a0"))
	var detail_texture := _fish_detail_portrait_texture(fish) if discovered else _fish_portrait_texture(fish, true)
	_detail_portrait.texture = detail_texture
	_detail_portrait_shadow.texture = detail_texture if discovered else null
	_detail_portrait.modulate = _portrait_paper_tint() if discovered else Color(0.04, 0.035, 0.03, 0.70)

	var count := int(PlayerProgress.caught_counts.get(fish_id, 0))
	var best := float(PlayerProgress.best_sizes.get(fish_id, 0.0))
	_detail_count_label.text = "釣果  %d匹" % count if discovered else "釣果  未記録"
	_detail_best_label.text = "最大  %.1fcm" % best if discovered else "最大  --.-cm"
	_detail_habitat_label.text = String(fish.get("habitat", "")) if discovered else "まだ釣ったことがない魚。記録すると詳細が開きます。"
	_detail_bait_label.text = String(fish.get("preferred_bait", "")) if discovered else "？？？"
	_detail_behavior_label.text = String(fish.get("behavior", "")) if discovered else "釣り場で出会うまで行動は不明。"
	_rebuild_spot_strip(_spot_ids_for_fish(fish_id) if discovered else [])


func _rebuild_spot_strip(spot_ids: Array) -> void:
	for child in _detail_spots.get_children():
		child.queue_free()
	if spot_ids.is_empty():
		var empty := _book_label("記録後に表示されます", 15, Color("#6b5331"), true, 0)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_place_control(_detail_spots, empty, 0.0, 0.0, 1.0, 1.0)
		return

	var count := mini(spot_ids.size(), 4)
	for index in range(count):
		var spot := GameData.get_fishing_spot(spot_ids[index])
		var item_left := float(index) / 4.0 + 0.010
		var item_right := item_left + 0.225
		var card := Control.new()
		card.name = "FishBookSpot_%s" % String(spot.get("id", "spot"))
		_place_control(_detail_spots, card, item_left, 0.0, item_right, 1.0)

		var card_bg := Panel.new()
		card_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_bg.add_theme_stylebox_override("panel", _spot_record_card_style())
		_place_control(card, card_bg, 0.0, 0.0, 1.0, 1.0)

		var thumb := _texture_rect("%s/%s.png" % [FISH_BOOK_THUMB_BASE_PATH, String(spot.get("id", ""))])
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		thumb.modulate = Color(1.0, 0.965, 0.860, 0.92)
		_place_control(card, thumb, 0.045, 0.055, 0.955, 0.680)

		var thumb_wash := _label_plate(_alpha(Palette.PARCHMENT, 0.12))
		_place_control(card, thumb_wash, 0.045, 0.055, 0.955, 0.680)
		var label_bg := _label_plate(_alpha(Palette.PARCHMENT_DEEP, 0.96))
		_place_control(card, label_bg, 0.045, 0.700, 0.955, 0.955)
		var label_rule := _label_plate(_alpha(Palette.WOOD_DARK, 0.34))
		_place_control(card, label_rule, 0.080, 0.700, 0.920, 0.718)

		var label := _book_label(String(spot.get("short_name", spot.get("name", ""))), 13, Palette.TEXT_OUTLINE_LIGHT, true, 0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_place_control(card, label, 0.055, 0.700, 0.945, 0.955)


func _set_filter(filter_id: String) -> void:
	if _active_filter == filter_id:
		return
	_active_filter = filter_id
	_ensure_valid_selection()
	_refresh_all()


func _select_fish(fish_id: String) -> void:
	_selected_fish_id = fish_id
	_refresh_all()


func _ensure_valid_selection() -> void:
	var ids := _filtered_fish_ids()
	if ids.is_empty():
		_selected_fish_id = ""
		return
	if ids.has(_selected_fish_id):
		return
	for fish_id in ids:
		if _is_discovered(fish_id):
			_selected_fish_id = fish_id
			return
	_selected_fish_id = ids[0]


func _filtered_fish_ids() -> Array[String]:
	var ids: Array[String] = []
	for fish_id in GameData.get_all_fish_ids():
		var fish := GameData.get_fish(fish_id)
		if _fish_matches_filter(fish):
			ids.append(fish_id)
	return ids


func _fish_matches_filter(fish: Dictionary) -> bool:
	if fish.is_empty():
		return false
	var fish_id := String(fish.get("id", ""))
	match _active_filter:
		"all":
			return true
		"rare":
			return RarityStylesScript.is_rare_or_boss(fish)
		"harbor":
			return _spot_group_has_fish(["harbor_pier", "harbor_boulder"], fish_id)
		"sand":
			return _spot_group_has_fish(["shallow_sand"], fish_id) or String(fish.get("habitat", "")).contains("砂")
		"rock":
			var habitat := String(fish.get("habitat", ""))
			return _spot_group_has_fish(["rock_breakwater", "south_reef"], fish_id) or habitat.contains("岩") or habitat.contains("根")
		"offshore":
			return _spot_group_has_fish(["outer_tide", "bluewater_route", "deep_ocean"], fish_id)
		_:
			return true


func _spot_group_has_fish(spot_ids: Array, fish_id: String) -> bool:
	for spot_id in spot_ids:
		var spot := GameData.get_fishing_spot(spot_id)
		if Array(spot.get("featured_fish", [])).has(fish_id):
			return true
		if Array(spot.get("allowed_fish", [])).has(fish_id):
			return true
	return false


func _spot_ids_for_fish(fish_id: String) -> Array[String]:
	var featured: Array[String] = []
	var allowed: Array[String] = []
	for spot_id in GameData.get_all_fishing_spot_ids():
		var spot := GameData.get_fishing_spot(spot_id)
		if Array(spot.get("featured_fish", [])).has(fish_id):
			featured.append(spot_id)
		elif Array(spot.get("allowed_fish", [])).has(fish_id):
			allowed.append(spot_id)
	var result := featured
	for spot_id in allowed:
		if not result.has(spot_id):
			result.append(spot_id)
	return result


func _is_discovered(fish_id: String) -> bool:
	return int(PlayerProgress.caught_counts.get(fish_id, 0)) > 0


func _fish_portrait_texture(fish: Dictionary, crop_to_fish := false) -> Texture2D:
	var path := FightFishAssets.card_portrait_path(fish)
	var texture := _load_texture_if_exists(path)
	if texture == null:
		texture = UITextures.get_fish_icon(Color.from_string(String(fish.get("color", "#8aa7b5")), Color("#8aa7b5")))
	if crop_to_fish:
		return _cropped_portrait_texture(texture)
	return texture


func _fish_card_portrait_texture(fish: Dictionary) -> Texture2D:
	var texture := _fish_portrait_texture(fish, false)
	return _cropped_portrait_texture(texture, 0.012, 0.025, 0.070, 2)


func _fish_detail_portrait_texture(fish: Dictionary) -> Texture2D:
	var path := FightFishAssets.sheet_path(fish)
	var key := "detail_frame:%s" % path
	if _portrait_crop_cache.has(key):
		return _portrait_crop_cache[key]
	var sheet := _load_texture_if_exists(path)
	if sheet == null:
		var fallback := _fish_portrait_texture(fish, true)
		_portrait_crop_cache[key] = fallback
		return fallback
	var image := sheet.get_image()
	if image == null or image.is_empty():
		var fallback := _fish_portrait_texture(fish, true)
		_portrait_crop_cache[key] = fallback
		return fallback
	var frame_width := int(image.get_width() / 4)
	if frame_width <= 0:
		var fallback := _fish_portrait_texture(fish, true)
		_portrait_crop_cache[key] = fallback
		return fallback
	var frame := image.get_region(Rect2i(0, 0, frame_width, image.get_height()))
	frame.flip_x()
	var texture := ImageTexture.create_from_image(frame)
	var cropped := _cropped_portrait_texture(texture)
	_portrait_crop_cache[key] = cropped
	return cropped


func _refresh_filter_buttons() -> void:
	for filter_id in _filter_buttons.keys():
		var button := _filter_buttons[filter_id] as Button
		_apply_filter_button_skin(button, String(filter_id) == _active_filter)


func _apply_card_skin(button: Button, discovered: bool, selected: bool) -> void:
	var normal: StyleBox
	if selected:
		normal = _texture_style(FISH_BOOK_CARD_SELECTED_FRAME_PATH, Vector4(30, 28, 30, 28))
	elif discovered:
		normal = _texture_style(FISH_BOOK_CARD_FRAME_PATH, Vector4(26, 24, 26, 24))
	else:
		normal = _texture_style(FISH_BOOK_CARD_LOCKED_FRAME_PATH, Vector4(26, 24, 26, 24))
	var hover := _texture_style(FISH_BOOK_CARD_SELECTED_FRAME_PATH, Vector4(30, 28, 30, 28))
	if normal != null:
		button.add_theme_stylebox_override("normal", normal)
	if hover != null:
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("focus", hover)
		button.add_theme_stylebox_override("pressed", hover)


func _apply_filter_button_skin(button: Button, selected: bool) -> void:
	var normal_path := COMMON_BUTTON_PRIMARY_PATH if selected else COMMON_BUTTON_PATH
	var hover_path := COMMON_BUTTON_PRIMARY_PATH if selected else COMMON_BUTTON_HOVER_PATH
	var normal := _texture_style(normal_path, Vector4(44, 24, 44, 24))
	var hover := _texture_style(hover_path, Vector4(44, 24, 44, 24))
	if normal != null:
		button.add_theme_stylebox_override("normal", normal)
	if hover != null:
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("focus", hover)
		button.add_theme_stylebox_override("pressed", hover)
	var font_color := Color("#fff8d8") if selected else Color("#2b1809")
	var outline_color := Color("#2a1406") if selected else Color("#ffe5a6")
	var shadow_color := Color(0.0, 0.0, 0.0, 0.35) if selected else Color(1.0, 0.86, 0.48, 0.28)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_outline_color", outline_color)
	button.add_theme_color_override("font_shadow_color", shadow_color)
	button.add_theme_constant_override("outline_size", 3 if selected else 1)
	button.add_theme_constant_override("shadow_offset_x", 1)
	button.add_theme_constant_override("shadow_offset_y", 2)
	button.add_theme_constant_override("shadow_outline_size", 1)


func _textured_button(text: String, callback: Callable, primary := false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0.0, 50.0)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(callback)
	button.add_theme_font_override("font", GameFontsScript.extra_bold(get_theme_default_font()))
	button.add_theme_font_size_override("font_size", 24 if primary else 21)
	var font_color := Color("#fff8d8") if primary else Color("#2b1809")
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_outline_color", Color("#2a1406") if primary else Color("#ffe5a6"))
	button.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.35) if primary else Color(1.0, 0.86, 0.48, 0.28))
	button.add_theme_constant_override("outline_size", 3 if primary else 1)
	button.add_theme_constant_override("shadow_offset_x", 1)
	button.add_theme_constant_override("shadow_offset_y", 2)
	button.add_theme_constant_override("shadow_outline_size", 1)
	_apply_filter_button_skin(button, primary)
	_wire_button_juice(button)
	return button


func _add_button_icon(button: Button, texture: Texture2D, primary: bool) -> void:
	if texture == null:
		return
	var icon := TextureRect.new()
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.modulate = Color(1.0, 0.94, 0.72, 0.95) if primary else Color(1.0, 0.96, 0.78, 0.85)
	if primary:
		_place_control(button, icon, 0.055, 0.170, 0.240, 0.830)
	else:
		_place_control(button, icon, 0.055, 0.235, 0.245, 0.770)


func _style_scrollbar(scroll: ScrollContainer) -> void:
	var vbar := scroll.get_v_scroll_bar()
	if vbar == null:
		return
	vbar.custom_minimum_size = Vector2(10.0, 0.0)
	var track := UITextures.flat_style(Color("#211407", 0.58), Color("#c28d2d", 0.48), 1, 5)
	var grabber := UITextures.flat_style(Color("#d7a238"), Color("#4d2b0d"), 1, 5, true, 2)
	var grabber_hot := UITextures.flat_style(Color("#ffd06b"), Color("#5b3210"), 1, 5, true, 2)
	vbar.add_theme_stylebox_override("scroll", track)
	vbar.add_theme_stylebox_override("scroll_focus", track)
	vbar.add_theme_stylebox_override("grabber", grabber)
	vbar.add_theme_stylebox_override("grabber_highlight", grabber_hot)
	vbar.add_theme_stylebox_override("grabber_pressed", grabber_hot)


func _header_chip(parent: Control, left: float, top: float, right: float, bottom: float, value: String, font_size := 17) -> Label:
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.035, 0.018, 0.62)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(parent, bg, left, top, right, bottom)
	var label := _book_label(value, font_size, Color("#fff4c7"), true, 2, Color("#06131d"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(parent, label, left + 0.006, top + 0.030, right - 0.006, bottom - 0.030)
	return label


func _book_label(
	text: String,
	font_size: int,
	color: Color,
	bold := false,
	outline := 0,
	outline_color := Color("#07131d")
) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if outline > 0:
		label.add_theme_color_override("font_outline_color", outline_color)
		label.add_theme_constant_override("outline_size", outline)
		label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.25))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		label.add_theme_constant_override("shadow_outline_size", 1)
	var fallback := get_theme_default_font()
	label.add_theme_font_override("font", GameFontsScript.bold(fallback) if bold else GameFontsScript.regular(fallback))
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return label


func _silence_button_text(button: Button) -> void:
	button.add_theme_color_override("font_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_hover_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_pressed_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_disabled_color", Color.TRANSPARENT)
	button.add_theme_constant_override("outline_size", 0)


func _texture_rect(path: String) -> TextureRect:
	return ShowcaseAssetsScript.texture_rect(path)


func _texture_style(path: String, margins: Vector4) -> StyleBoxTexture:
	return ShowcaseAssetsScript.texture_style(path, margins)


func _portrait_rect(tint: Color) -> TextureRect:
	var rect := TextureRect.new()
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.modulate = tint
	return rect


func _portrait_paper_tint() -> Color:
	return Color(1.0, 0.965, 0.880, 1.0)


func _detail_icon(icon_index: int) -> Texture2D:
	return _atlas_icon(_detail_icon_sheet, FISH_BOOK_ICON_SIZE, icon_index)


func _footer_icon(icon_index: int) -> Texture2D:
	return _atlas_icon(_footer_icon_sheet, FISH_BOOK_ICON_SIZE, icon_index)


func _atlas_icon(sheet: Texture2D, cell_size: float, icon_index: int) -> Texture2D:
	if sheet == null or icon_index < 0:
		return null
	return ShowcaseAssetsScript.atlas_icon_from_texture(sheet, cell_size, icon_index)


func _load_texture_if_exists(path: String) -> Texture2D:
	return ShowcaseAssetsScript.load_texture(path)


func _portrait_clip() -> Control:
	var clip := Control.new()
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return clip


func _cropped_portrait_texture(
	texture: Texture2D,
	pad_x_ratio := 0.035,
	pad_y_ratio := 0.060,
	alpha_threshold := 0.035,
	min_pad := 8
) -> Texture2D:
	if texture == null:
		return null
	var base_key := texture.resource_path
	if base_key.is_empty():
		base_key = str(texture.get_instance_id())
	var key := "%s:%s:%s:%s:%s" % [base_key, str(pad_x_ratio), str(pad_y_ratio), str(alpha_threshold), str(min_pad)]
	if _portrait_crop_cache.has(key):
		return _portrait_crop_cache[key]
	var image := texture.get_image()
	if image == null or image.is_empty():
		_portrait_crop_cache[key] = texture
		return texture
	var width := image.get_width()
	var height := image.get_height()
	var min_x := width
	var min_y := height
	var max_x := -1
	var max_y := -1
	for y in range(height):
		for x in range(width):
			if image.get_pixel(x, y).a > alpha_threshold:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		_portrait_crop_cache[key] = texture
		return texture
	var fish_width := max_x - min_x + 1
	var fish_height := max_y - min_y + 1
	var pad_x := maxi(min_pad, int(round(float(fish_width) * pad_x_ratio)))
	var pad_y := maxi(min_pad, int(round(float(fish_height) * pad_y_ratio)))
	var region := Rect2(
		maxi(0, min_x - pad_x),
		maxi(0, min_y - pad_y),
		mini(width, max_x + pad_x + 1) - maxi(0, min_x - pad_x),
		mini(height, max_y + pad_y + 1) - maxi(0, min_y - pad_y)
	)
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	_portrait_crop_cache[key] = atlas
	return atlas


func _anchored_control(parent: Control, left: float, top: float, right: float, bottom: float) -> Control:
	var control := Control.new()
	_place_control(parent, control, left, top, right, bottom)
	return control


func _place_control(parent: Control, control: Control, left: float, top: float, right: float, bottom: float) -> void:
	control.anchor_left = left
	control.anchor_top = top
	control.anchor_right = right
	control.anchor_bottom = bottom
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0
	parent.add_child(control)


func _rarity_text_color(rarity: String) -> Color:
	return RarityStylesScript.text_color(rarity)


func _rarity_badge_color(rarity: String) -> Color:
	return RarityStylesScript.badge_color(rarity)


func _card_name_font_size(text: String) -> int:
	var length := text.length()
	if length >= 11:
		return 10
	if length >= 8:
		return 12
	if length >= 5:
		return 14
	return 16


func _detail_name_font_size(text: String) -> int:
	var length := text.length()
	if length >= 11:
		return 21
	if length >= 8:
		return 25
	if length >= 5:
		return 31
	return 36


func _rarity_font_size(rarity: String, detail: bool) -> int:
	if rarity.length() >= 5:
		return 14 if detail else 11
	return 16 if detail else 12


func _alpha(color: Color, alpha: float) -> Color:
	var result := color
	result.a = alpha
	return result


func _short_rod_name(rod_name: String) -> String:
	var parts := rod_name.split("・")
	if parts.size() >= 2:
		return String(parts[1])
	return rod_name


func _paper_wash() -> TextureRect:
	var gradient := Gradient.new()
	gradient.set_color(0, Color("#f2dfb0", 0.78))
	gradient.set_color(1, Color("#d7b979", 0.44))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(1.0, 1.0)
	texture.width = 64
	texture.height = 64
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return rect


func _label_plate(color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _add_specimen_rule(parent: Control, left: float, top: float, right: float, bottom: float, color: Color) -> void:
	var rule := _label_plate(color)
	_place_control(parent, rule, left, top, right, bottom)


func _spot_record_card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _alpha(Palette.PARCHMENT, 0.78)
	style.border_color = _alpha(Palette.WOOD_DARK, 0.56)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 4.0
	style.content_margin_top = 4.0
	style.content_margin_right = 4.0
	style.content_margin_bottom = 4.0
	return style


func _card_portrait_field_style(discovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _alpha(Palette.PARCHMENT if discovered else Palette.PARCHMENT_DEEP, 0.78 if discovered else 0.58)
	style.border_color = _alpha(Palette.WOOD_DARK, 0.42 if discovered else 0.34)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 2.0
	style.content_margin_top = 2.0
	style.content_margin_right = 2.0
	style.content_margin_bottom = 2.0
	return style


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


func _format_money(value: int) -> String:
	var raw := str(value)
	var result := ""
	var count := 0
	for index in range(raw.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = raw[index] + result
		count += 1
	return result
