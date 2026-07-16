extends ScreenBase

const FightFishAssets = preload("res://src/ui/fight_fish_assets.gd")
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
const FILTER_TAB_X0 := 0.032
const FILTER_TAB_STEP := 0.1065
const FILTER_TAB_WIDTH := 0.104

const FILTERS := [
	{"id": "all", "label": "全魚", "icon": 1},
	{"id": "harbor", "label": "港内", "icon": 2},
	{"id": "sand", "label": "砂浜", "icon": 0},
	{"id": "rock", "label": "岩礁", "icon": 3},
	{"id": "offshore", "label": "沖", "icon": 0},
	{"id": "rare", "label": "レア", "icon": 3},
	{"id": "nushi", "label": "ヌシ", "icon": 3},
]

var _active_filter := "all"
var _selected_fish_id := ""
var _fish_card_buttons: Dictionary = {}
var _filter_buttons: Dictionary = {}

var _found_label: Label
var _found_progress_fill: ColorRect
var _player_status_bar: PlayerStatusBar
var _fish_scroll: ScrollContainer
var _grid: GridContainer
var _return_button: Button
var _detail_no_label: Label
var _detail_name_label: Label
var _detail_rarity_label: Label
var _detail_portrait: TextureRect
var _detail_portrait_shadow: TextureRect
var _detail_portrait_underprints: Array[TextureRect] = []
var _detail_count_label: Label
var _detail_best_label: Label
var _detail_nushi_label: Label
var _detail_nushi_accent: Panel
var _detail_habitat_label: Label
var _detail_bait_label: Label
var _detail_behavior_label: Label
var _detail_spots: Control
var _detail_icon_sheet: Texture2D
var _footer_icon_sheet: Texture2D
var _portrait_crop_cache: Dictionary = {}
var _keyboard_focus_initialized := false


func _build_screen() -> void:
	_detail_icon_sheet = ShowcaseAssets.load_texture(COMMON_DETAIL_ICON_SHEET_PATH)
	_footer_icon_sheet = ShowcaseAssets.load_texture(COMMON_FOOTER_ICON_SHEET_PATH)
	_build_background()
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_build_book_backplate(root)
	_build_book_spine(root)
	_build_header(root)
	_build_book_grid(root)
	_build_detail_panel(root)
	_build_footer(root)
	_ensure_valid_selection()
	_refresh_all()
	_configure_keyboard_focus()
	set_common_cancel_handler(_return_to_harbor)


func _build_background() -> void:
	var bg := _texture_rect(FISH_BOOK_BG_PATH)
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	move_child(bg, 0)

	var shade := ColorRect.new()
	shade.color = Palette.FISH_BOOK_BG_SCRIM
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)


func _build_book_backplate(root: Control) -> void:
	var frame := _texture_rect(FISH_BOOK_BOOK_FRAME_PATH)
	_place_control(root, frame, 0.018, 0.018, 0.982, 0.982)


func _build_book_spine(root: Control) -> void:
	var spine := Control.new()
	spine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spine.z_index = 4
	_place_control(root, spine, 0.586, 0.150, 0.616, 0.885)

	var outer_shadow := _label_plate(_alpha(Palette.TEXT_OUTLINE_DARK, 0.24))
	_place_control(spine, outer_shadow, 0.0, 0.0, 1.0, 1.0)

	var leather := _label_plate(_alpha(Palette.WOOD_DARK, 0.62))
	_place_control(spine, leather, 0.160, 0.0, 0.840, 1.0)

	var center_fold := _label_plate(_alpha(Palette.TEXT_OUTLINE_DARK, 0.42))
	_place_control(spine, center_fold, 0.460, 0.0, 0.540, 1.0)

	var left_highlight := _label_plate(_alpha(Palette.GOLD_DEEP, 0.24))
	_place_control(spine, left_highlight, 0.180, 0.020, 0.220, 0.980)
	var right_highlight := _label_plate(_alpha(Palette.GOLD_DEEP, 0.16))
	_place_control(spine, right_highlight, 0.780, 0.020, 0.820, 0.980)

	var page_shadow := _label_plate(_alpha(Palette.WOOD_DARK, 0.18))
	_place_control(spine, page_shadow, 0.000, 0.0, 0.160, 1.0)
	var page_light := _label_plate(_alpha(Palette.PARCHMENT_DEEP, 0.10))
	_place_control(spine, page_light, 0.840, 0.0, 1.000, 1.0)


func _build_header(root: Control) -> void:
	var header := _anchored_control(root, 0.018, 0.020, 0.982, 0.154)

	var found_bar := _texture_rect(COMMON_STATUS_BAR_PATH)
	_place_control(header, found_bar, 0.022, 0.188, 0.276, 0.820)
	var progress_track := Panel.new()
	progress_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_track.add_theme_stylebox_override("panel", _collection_progress_track_style())
	_place_control(header, progress_track, 0.054, 0.674, 0.244, 0.758)
	_found_progress_fill = _label_plate(_alpha(Palette.GOLD_BRIGHT, 0.78))
	_place_control(progress_track, _found_progress_fill, 0.0, 0.0, 0.0, 1.0)
	var progress_gloss := _label_plate(_alpha(Palette.PARCHMENT, 0.16))
	_place_control(progress_track, progress_gloss, 0.0, 0.0, 1.0, 0.420)
	_found_label = _book_label("発見済み 0/0", 22, Palette.FISH_BOOK_FOUND_TEXT, true, 2, Palette.FISH_BOOK_INK_OUTLINE)
	_found_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_found_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(header, _found_label, 0.034, 0.230, 0.264, 0.770)

	var sign := _texture_rect(FISH_BOOK_TITLE_SIGN_PATH)
	_place_control(header, sign, 0.345, -0.045, 0.655, 1.020)
	var title := _book_label("魚図鑑", 42, Palette.FISH_BOOK_TITLE_TEXT, true, 4, Palette.FISH_BOOK_TITLE_OUTLINE)
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

	var page_surface := _label_plate(_alpha(Palette.PARCHMENT, 0.34))
	_place_control(left, page_surface, 0.047, 0.105, 0.936, 0.970)
	var page_wash := _paper_wash()
	page_wash.modulate = Palette.FISH_BOOK_PAGE_WASH_TINT
	_place_control(left, page_wash, 0.047, 0.105, 0.936, 0.970)
	_add_left_page_guides(left)

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
	_fish_scroll = scroll

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

	_detail_nushi_accent = Panel.new()
	_detail_nushi_accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_detail_nushi_accent.visible = false
	_detail_nushi_accent.add_theme_stylebox_override("panel", _nushi_detail_accent_style())
	_place_control(detail, _detail_nushi_accent, 0.060, 0.042, 0.940, 0.972)

	var header_wash := _label_plate(_alpha(Palette.PARCHMENT_DEEP, 0.92))
	_place_control(detail, header_wash, 0.082, 0.052, 0.918, 0.150)
	_add_rule(detail, 0.095, 0.126, 0.905, _alpha(Palette.GOLD_DEEP, 0.30), 1.0)

	var number_plate := _label_plate(_alpha(Palette.WOOD_DARK, 0.88))
	_place_control(detail, number_plate, 0.082, 0.052, 0.318, 0.118)

	_detail_no_label = _book_label("No.000", 18, Palette.GOLD_BRIGHT, true, 1, Palette.TEXT_OUTLINE_DARK)
	_detail_no_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_detail_no_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(detail, _detail_no_label, 0.098, 0.058, 0.308, 0.108)

	_detail_name_label = _book_label("アジ", 36, Palette.FISH_BOOK_DETAIL_NAME, true, 0)
	_detail_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(detail, _detail_name_label, 0.265, 0.068, 0.756, 0.150)

	var detail_badge := _texture_rect(COMMON_BADGE_FRAME_PATH)
	_place_control(detail, detail_badge, 0.760, 0.066, 0.940, 0.150)
	_detail_rarity_label = _book_label("コモン", 16, Palette.FISH_BOOK_BADGE_TEXT, true, 2, Palette.FISH_BOOK_INK_OUTLINE)
	_detail_rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_rarity_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(detail, _detail_rarity_label, 0.762, 0.072, 0.928, 0.145)

	_detail_portrait_shadow = _portrait_rect(Palette.FISH_BOOK_PORTRAIT_SHADOW_DETAIL)
	_detail_portrait = _portrait_rect(_portrait_paper_tint())
	var portrait_bg := ColorRect.new()
	portrait_bg.color = Palette.FISH_BOOK_PORTRAIT_BG
	portrait_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(detail, portrait_bg, 0.090, 0.155, 0.920, 0.505)
	var portrait_paper := _texture_rect(COMMON_PARCHMENT_CARD_PATH)
	portrait_paper.modulate = Palette.FISH_BOOK_PORTRAIT_CARD_TINT
	_place_control(detail, portrait_paper, 0.078, 0.145, 0.935, 0.510)
	_add_rule(detail, 0.095, 0.160, 0.915, _alpha(Palette.FISH_BOOK_RULE_INK, 0.45), 2.0)
	_add_rule(detail, 0.095, 0.505, 0.915, _alpha(Palette.FISH_BOOK_RULE_INK, 0.35), 1.0)
	var detail_portrait_clip := _portrait_clip()
	_place_control(detail, detail_portrait_clip, 0.095, 0.175, 0.915, 0.490)
	_add_specimen_rule(detail_portrait_clip, 0.030, 0.245, 0.970, 0.252, _alpha(Palette.GOLD_DEEP, 0.12))
	_add_specimen_rule(detail_portrait_clip, 0.030, 0.485, 0.970, 0.492, _alpha(Palette.GOLD_DEEP, 0.12))
	_add_specimen_rule(detail_portrait_clip, 0.030, 0.725, 0.970, 0.732, _alpha(Palette.GOLD_DEEP, 0.12))
	_add_specimen_rule(detail_portrait_clip, 0.075, 0.125, 0.080, 0.870, _alpha(Palette.WOOD_DARK, 0.10))
	_add_specimen_ruler(detail_portrait_clip)
	_detail_portrait_underprints = _add_portrait_underprint(detail_portrait_clip, null, 0.16, 0.004, 0.009)
	_place_control(detail_portrait_clip, _detail_portrait_shadow, 0.012, 0.036, 1.012, 1.036)
	_place_control(detail_portrait_clip, _detail_portrait, 0.0, 0.0, 1.0, 1.0)
	var specimen_wash := _label_plate(_alpha(Palette.PARCHMENT, 0.08))
	_place_control(detail_portrait_clip, specimen_wash, 0.0, 0.0, 1.0, 1.0)
	_add_detail_specimen_fixture(detail_portrait_clip, 0.060, 0.060, 0.210, 0.145)
	_add_detail_specimen_fixture(detail_portrait_clip, 0.790, 0.060, 0.940, 0.145)

	var count_slip := Panel.new()
	count_slip.add_theme_stylebox_override("panel", _detail_stat_slip_style())
	_place_control(detail, count_slip, 0.090, 0.518, 0.500, 0.596)
	var count_plate := _label_plate(_alpha(Palette.WOOD_DARK, 0.88))
	_place_control(detail, count_plate, 0.108, 0.535, 0.225, 0.578)
	var count_caption := _book_label("釣果", 16, Palette.TEXT_BONE, true, 1, Palette.TEXT_OUTLINE_LIGHT)
	count_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(detail, count_caption, 0.108, 0.535, 0.225, 0.578)
	_detail_count_label = _book_label("0匹", 28, Palette.TEXT_OUTLINE_LIGHT, true, 0)
	_detail_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_detail_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(detail, _detail_count_label, 0.245, 0.520, 0.485, 0.592)

	var best_slip := Panel.new()
	best_slip.add_theme_stylebox_override("panel", _detail_stat_slip_style())
	_place_control(detail, best_slip, 0.510, 0.518, 0.910, 0.596)
	var best_plate := _label_plate(_alpha(Palette.WOOD_DARK, 0.88))
	_place_control(detail, best_plate, 0.528, 0.535, 0.645, 0.578)
	var best_caption := _book_label("最大", 16, Palette.TEXT_BONE, true, 1, Palette.TEXT_OUTLINE_LIGHT)
	best_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	best_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(detail, best_caption, 0.528, 0.535, 0.645, 0.578)
	_detail_best_label = _book_label("--.-cm", 24, Palette.TEXT_OUTLINE_LIGHT, true, 0)
	_detail_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_detail_best_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(detail, _detail_best_label, 0.662, 0.524, 0.895, 0.590)

	_detail_nushi_label = _book_label("", 13, Palette.GOLD_BRIGHT, true, 1, Palette.TEXT_OUTLINE_DARK)
	_detail_nushi_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_nushi_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_detail_nushi_label.visible = false
	_place_control(detail, _detail_nushi_label, 0.105, 0.594, 0.895, 0.620)

	_add_rule(detail, 0.095, 0.602, 0.910, _alpha(Palette.FISH_BOOK_RULE_INK, 0.30), 1.0)
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
	row_frame.modulate = Palette.FISH_BOOK_DETAIL_ROW_FRAME_TINT
	_place_control(parent, row_frame, 0.082, top - 0.010, 0.918, top + 0.063)

	var plate := _label_plate(Palette.FISH_BOOK_LABEL_PLATE)
	_place_control(parent, plate, 0.090, top, 0.235, top + 0.055)

	var title := _book_label(label_text, 16, Palette.FISH_BOOK_DETAIL_ROW_TITLE, true, 1, Palette.FISH_BOOK_TITLE_OUTLINE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(parent, title, 0.090, top, 0.235, top + 0.055)

	var value := _book_label("", 16, Palette.FISH_BOOK_DETAIL_ROW_VALUE, false, 0)
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	value.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_place_control(parent, value, 0.270, top - 0.001, 0.902, top + 0.068)
	return value


func _build_footer(root: Control) -> void:
	var footer := _anchored_control(root, 0.024, 0.890, 0.976, 0.975)

	var index_rail := _label_plate(_alpha(Palette.PARCHMENT_DEEP, 0.16))
	_place_control(footer, index_rail, 0.026, 0.132, 0.784, 0.868)
	var rail_top := _label_plate(_alpha(Palette.GOLD_DEEP, 0.24))
	_place_control(footer, rail_top, 0.034, 0.132, 0.776, 0.162)
	var rail_shadow := _label_plate(_alpha(Palette.TEXT_OUTLINE_DARK, 0.20))
	_place_control(footer, rail_shadow, 0.034, 0.812, 0.776, 0.868)

	var x := FILTER_TAB_X0
	for filter in FILTERS:
		var filter_id := String(filter["id"])
		var button := _textured_button(String(filter["label"]), _set_filter.bind(filter_id), false)
		button.name = "FishBookFilter_%s" % filter_id
		button.set_meta("fish_book_filter", filter_id)
		_filter_buttons[filter_id] = button
		_add_button_icon(button, _detail_icon(int(filter.get("icon", -1))), false)
		_place_control(footer, button, x, 0.072, x + FILTER_TAB_WIDTH, 0.850)
		x += FILTER_TAB_STEP

	var return_plaque := Panel.new()
	return_plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return_plaque.add_theme_stylebox_override("panel", _return_button_plaque_style())
	_place_control(footer, return_plaque, 0.778, 0.038, 0.974, 0.938)
	var return_top_rule := _label_plate(_alpha(Palette.GOLD_BRIGHT, 0.42))
	_place_control(footer, return_top_rule, 0.792, 0.086, 0.960, 0.118)
	var return_bottom_shadow := _label_plate(_alpha(Palette.TEXT_OUTLINE_DARK, 0.24))
	_place_control(footer, return_bottom_shadow, 0.792, 0.842, 0.960, 0.898)

	var back := make_return_button(func() -> void: navigate("harbor"), 0.0)
	back.name = "FishBookReturnButton"
	back.set_meta("fish_book_return", true)
	back.add_theme_font_override("font", GameFontsScript.extra_bold(get_theme_default_font()))
	back.add_theme_font_size_override("font_size", 22)
	back.add_theme_constant_override("outline_size", 3)
	_add_button_icon(back, _footer_icon(1), true)
	_place_control(footer, back, 0.786, 0.100, 0.970, 0.910)
	_return_button = back


func _refresh_all(retained_focus_id: String = "") -> void:
	_refresh_header()
	_rebuild_grid()
	_refresh_detail()
	_refresh_filter_buttons()
	if _keyboard_focus_initialized:
		_sync_keyboard_focus(retained_focus_id)


func _refresh_header() -> void:
	var total := GameData.get_all_fish_ids().size()
	var found := 0
	for fish_id in GameData.get_all_fish_ids():
		if _is_discovered(fish_id):
			found += 1
	_found_label.text = "発見済み  %d/%d" % [found, total]
	if _found_progress_fill != null:
		var ratio := 0.0 if total <= 0 else clampf(float(found) / float(total), 0.0, 1.0)
		_found_progress_fill.anchor_right = ratio
		_found_progress_fill.offset_right = 0.0
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
		card.focus_entered.connect(_keep_card_focus_visible.bind(card))


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

	var card_body := Panel.new()
	card_body.add_theme_stylebox_override("panel", _card_body_style(discovered, selected))
	card_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(button, card_body, 0.038, 0.040, 0.962, 0.958)

	if selected:
		var bookmark := Panel.new()
		bookmark.add_theme_stylebox_override("panel", _selected_card_bookmark_style())
		bookmark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place_control(button, bookmark, 0.036, 0.205, 0.064, 0.760)
		var bookmark_glint := _label_plate(_alpha(Palette.GOLD_BRIGHT, 0.38))
		bookmark_glint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place_control(button, bookmark_glint, 0.044, 0.230, 0.050, 0.720)

	var portrait_field := Panel.new()
	portrait_field.add_theme_stylebox_override("panel", _card_portrait_field_style(discovered))
	portrait_field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(button, portrait_field, 0.070, 0.190, 0.930, 0.615)

	var no_plate := _label_plate(_alpha(Palette.FISH_BOOK_LABEL_PLATE, 0.80) if discovered else _alpha(Palette.WOOD_DARK, 0.72))
	no_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(button, no_plate, 0.055, 0.052, 0.300, 0.178)

	var no_label := _book_label(String(fish.get("fish_no", "No.---")), 12, Palette.TEXT_BONE, true, 2, Palette.FISH_BOOK_NO_OUTLINE)
	no_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	no_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	no_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(button, no_label, 0.055, 0.052, 0.390, 0.175)

	var name_text := String(fish.get("name", fish_id)) if discovered else "？？？？？"
	var name_color := Palette.FISH_BOOK_CARD_NAME
	if not discovered:
		name_color = Palette.TEXT_OUTLINE_LIGHT
	var name_label := _book_label(name_text, 16, name_color, true, 0, Palette.FISH_BOOK_CARD_NAME_OUTLINE)
	name_label.add_theme_font_size_override("font_size", _card_name_font_size(name_text))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(button, name_label, 0.292, 0.048, 0.940, 0.185)

	var portrait_texture := _fish_card_portrait_texture(fish) if discovered else _fish_locked_card_portrait_texture(fish)
	var portrait := _portrait_rect(_alpha(Palette.WOOD_DARK, 0.62) if not discovered else _portrait_paper_tint())
	portrait.texture = portrait_texture
	var portrait_clip := _portrait_clip()
	_place_control(button, portrait_clip, 0.080, 0.198, 0.920, 0.602)
	if discovered:
		_add_portrait_underprint(portrait_clip, portrait_texture, 0.22, 0.006, 0.016)
		var portrait_shadow := _portrait_rect(Palette.FISH_BOOK_PORTRAIT_SHADOW_CARD)
		portrait_shadow.texture = portrait_texture
		_place_control(portrait_clip, portrait_shadow, 0.014, 0.036, 1.014, 1.036)
	_place_control(portrait_clip, portrait, 0.0, 0.0, 1.0, 1.0)

	if not discovered:
		var sealed_wash := _label_plate(_alpha(Palette.PARCHMENT, 0.18))
		sealed_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place_control(button, sealed_wash, 0.070, 0.190, 0.930, 0.615)

		var seal_cord := _label_plate(_alpha(Palette.WOOD_DARK, 0.18))
		seal_cord.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place_control(button, seal_cord, 0.125, 0.492, 0.875, 0.508)
		var seal := Panel.new()
		seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		seal.add_theme_stylebox_override("panel", _locked_card_seal_style())
		_place_control(button, seal, 0.125, 0.418, 0.255, 0.608)
		var seal_mark := _book_label("封", 15, Palette.TEXT_BONE, true, 1, Palette.TEXT_OUTLINE_DARK)
		seal_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		seal_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		seal_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place_control(button, seal_mark, 0.125, 0.420, 0.255, 0.604)

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

	if _has_caught_nushi_for_base(fish_id):
		var nushi_pin := Panel.new()
		nushi_pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		nushi_pin.add_theme_stylebox_override("panel", _nushi_card_pin_style())
		_place_control(button, nushi_pin, 0.840, 0.205, 0.925, 0.355)
		var nushi_mark := _book_label("主", 12, Palette.TEXT_OUTLINE_DARK, true, 0)
		nushi_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nushi_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nushi_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place_control(button, nushi_mark, 0.842, 0.204, 0.923, 0.354)

	var rarity := String(fish.get("rarity", ""))
	var badge_bg := _label_plate(_rarity_badge_color(rarity))
	badge_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(button, badge_bg, 0.060, 0.610, 0.438, 0.765)
	var rarity_label := _book_label(rarity, _rarity_font_size(rarity, false), Palette.FISH_BOOK_BADGE_TEXT, true, 1, Palette.FISH_BOOK_INK_OUTLINE)
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
	divider.color = _alpha(Palette.FISH_BOOK_CARD_DIVIDER, 0.34)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(button, divider, 0.080, 0.778, 0.920, 0.788)
	var stat_color := Palette.FISH_BOOK_CARD_STAT_TEXT
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
		for underprint in _detail_portrait_underprints:
			underprint.texture = null
		_detail_count_label.text = "--"
		_detail_count_label.add_theme_font_size_override("font_size", 26)
		_detail_best_label.text = "--.-cm"
		_detail_best_label.add_theme_font_size_override("font_size", 22)
		if _detail_nushi_label != null:
			_detail_nushi_label.visible = false
			_detail_nushi_label.text = ""
		if _detail_nushi_accent != null:
			_detail_nushi_accent.visible = false
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
	_detail_rarity_label.add_theme_color_override("font_color", _rarity_text_color(rarity) if discovered else Palette.FISH_BOOK_UNDISCOVERED_RARITY)
	var detail_texture := _fish_detail_portrait_texture(fish) if discovered else _fish_portrait_texture(fish, true)
	_detail_portrait.texture = detail_texture
	_detail_portrait_shadow.texture = detail_texture if discovered else null
	for underprint in _detail_portrait_underprints:
		underprint.texture = detail_texture if discovered else null
	_detail_portrait.modulate = _portrait_paper_tint() if discovered else Palette.FISH_BOOK_LOCKED_PORTRAIT

	var count := int(PlayerProgress.caught_counts.get(fish_id, 0))
	var best := float(PlayerProgress.best_sizes.get(fish_id, 0.0))
	_detail_count_label.text = "%d匹" % count if discovered else "未記録"
	_detail_count_label.add_theme_font_size_override("font_size", 28 if discovered else 22)
	_detail_best_label.text = "%.1fcm" % best if discovered else "--.-cm"
	_detail_best_label.add_theme_font_size_override("font_size", 24 if discovered else 22)
	_refresh_nushi_detail_record(fish_id, discovered)
	_detail_habitat_label.text = String(fish.get("habitat", "")) if discovered else "まだ釣ったことがない魚。記録すると詳細が開きます。"
	_detail_bait_label.text = String(fish.get("preferred_bait", "")) if discovered else "？？？"
	_detail_behavior_label.text = String(fish.get("behavior", "")) if discovered else "釣り場で出会うまで行動は不明。"
	_rebuild_spot_strip(_spot_ids_for_fish(fish_id) if discovered else [])


func _rebuild_spot_strip(spot_ids: Array) -> void:
	for child in _detail_spots.get_children():
		child.queue_free()
	if spot_ids.is_empty():
		var empty := _book_label("記録後に表示されます", 15, Palette.FISH_BOOK_EMPTY_SPOT_TEXT, true, 0)
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
		thumb.modulate = Palette.FISH_BOOK_SPOT_THUMB_TINT
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
	var retained_focus_id := _focused_control_identity()
	_active_filter = filter_id
	_ensure_valid_selection()
	if retained_focus_id.is_empty():
		retained_focus_id = "filter:%s" % filter_id
	_refresh_all(retained_focus_id)


func _select_fish(fish_id: String) -> void:
	_selected_fish_id = fish_id
	_refresh_all("card:%s" % fish_id)


func _configure_keyboard_focus() -> void:
	_keyboard_focus_initialized = true
	_sync_keyboard_focus("card:%s" % _selected_fish_id)


func _sync_keyboard_focus(retained_focus_id: String = "") -> void:
	var candidates: Array[Control] = []
	var cards := _card_controls_in_display_order()
	for card in cards:
		candidates.append(card)
	var filters := _filter_controls_in_display_order()
	for filter_button in filters:
		candidates.append(filter_button)
	if _return_button != null:
		candidates.append(_return_button)

	var preferred := _focus_control_for_identity(retained_focus_id)
	if preferred == null:
		preferred = _fish_card_buttons.get(_selected_fish_id) as Button
	if preferred == null and not filters.is_empty():
		preferred = filters[0]
	if preferred == null:
		preferred = _return_button
	setup_keyboard_focus(candidates, preferred)
	_link_keyboard_focus_graph(cards, filters)


func _card_controls_in_display_order() -> Array[Control]:
	var result: Array[Control] = []
	for fish_id in _filtered_fish_ids():
		var card := _fish_card_buttons.get(fish_id) as Button
		if card != null and is_instance_valid(card):
			result.append(card)
	return result


func _filter_controls_in_display_order() -> Array[Control]:
	var result: Array[Control] = []
	for filter in FILTERS:
		var button := _filter_buttons.get(String(filter["id"])) as Button
		if button != null and is_instance_valid(button):
			result.append(button)
	return result


func _focused_control_identity() -> String:
	if not is_inside_tree():
		return ""
	return _control_focus_identity(get_viewport().gui_get_focus_owner())


func _control_focus_identity(control: Control) -> String:
	if control == null or not is_instance_valid(control):
		return ""
	if control == _return_button:
		return "return"
	if control.has_meta("fish_book_card"):
		return "card:%s" % String(control.get_meta("fish_book_card", ""))
	if control.has_meta("fish_book_filter"):
		return "filter:%s" % String(control.get_meta("fish_book_filter", ""))
	return ""


func _focus_control_for_identity(identity: String) -> Control:
	if identity == "return":
		return _return_button
	if identity.begins_with("card:"):
		return _fish_card_buttons.get(identity.trim_prefix("card:")) as Button
	if identity.begins_with("filter:"):
		return _filter_buttons.get(identity.trim_prefix("filter:")) as Button
	return null


func _link_keyboard_focus_graph(cards: Array[Control], filters: Array[Control]) -> void:
	var available: Array[Control] = []
	available.append_array(cards)
	available.append_array(filters)
	if _return_button != null and is_keyboard_focus_available(_return_button):
		available.append(_return_button)
	for control in available:
		control.focus_neighbor_left = NodePath()
		control.focus_neighbor_right = NodePath()
		control.focus_neighbor_top = NodePath()
		control.focus_neighbor_bottom = NodePath()
		control.focus_next = NodePath()
		control.focus_previous = NodePath()
	if available.is_empty():
		return

	for index in range(available.size()):
		var control := available[index]
		var previous := available[(index - 1 + available.size()) % available.size()]
		var next := available[(index + 1) % available.size()]
		control.focus_previous = control.get_path_to(previous)
		control.focus_next = control.get_path_to(next)

	for index in range(cards.size()):
		var card := cards[index]
		var column := index % 3
		var left := cards[index - 1] if column > 0 else card
		var right := cards[index + 1] if column < 2 and index + 1 < cards.size() else card
		var top := cards[index - 3] if index >= 3 else card
		var bottom := cards[index + 3] if index + 3 < cards.size() else _filter_at(filters, mini(column, filters.size() - 1))
		_set_focus_neighbors(card, left, right, top, bottom)

	for index in range(filters.size()):
		var filter_button := filters[index]
		var left := filters[index - 1] if index > 0 else (_return_button as Control)
		var right := filters[index + 1] if index + 1 < filters.size() else (_return_button as Control)
		var card_target := _bottom_card_for_filter(cards, index, filters.size())
		if card_target == null:
			card_target = _return_button
		_set_focus_neighbors(filter_button, left, right, card_target, _return_button)

	if _return_button != null:
		var left_target := filters[filters.size() - 1] if not filters.is_empty() else (cards[cards.size() - 1] if not cards.is_empty() else _return_button)
		var right_target := filters[0] if not filters.is_empty() else (cards[0] if not cards.is_empty() else _return_button)
		var top_target := cards[cards.size() - 1] if not cards.is_empty() else left_target
		var bottom_target := _fish_card_buttons.get(_selected_fish_id) as Control
		if bottom_target == null:
			bottom_target = right_target
		_set_focus_neighbors(_return_button, left_target, right_target, top_target, bottom_target)


func _filter_at(filters: Array[Control], index: int) -> Control:
	if filters.is_empty():
		return _return_button
	return filters[clampi(index, 0, filters.size() - 1)]


func _bottom_card_for_filter(cards: Array[Control], filter_index: int, filter_count: int) -> Control:
	if cards.is_empty():
		return null
	var last_row_start := int(floor(float(cards.size() - 1) / 3.0)) * 3
	var last_row_count := cards.size() - last_row_start
	var column := 0
	if last_row_count > 1 and filter_count > 1:
		column = int(round(float(filter_index) * float(last_row_count - 1) / float(filter_count - 1)))
	return cards[last_row_start + clampi(column, 0, last_row_count - 1)]


func _set_focus_neighbors(control: Control, left: Control, right: Control, top: Control, bottom: Control) -> void:
	if control == null:
		return
	control.focus_neighbor_left = control.get_path_to(left if left != null else control)
	control.focus_neighbor_right = control.get_path_to(right if right != null else control)
	control.focus_neighbor_top = control.get_path_to(top if top != null else control)
	control.focus_neighbor_bottom = control.get_path_to(bottom if bottom != null else control)


func _keep_card_focus_visible(card: Control) -> void:
	call_deferred("_scroll_card_into_view", card)


func _scroll_card_into_view(card: Control) -> void:
	if (
		_fish_scroll == null
		or card == null
		or not is_instance_valid(card)
		or not _fish_scroll.is_ancestor_of(card)
	):
		return
	_fish_scroll.ensure_control_visible(card)


func _return_to_harbor() -> void:
	navigate("harbor")


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
		"nushi":
			return not GameData.get_nushi_for_base_fish(fish_id).is_empty()
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
	return int(PlayerProgress.caught_counts.get(fish_id, 0)) > 0 or _has_caught_nushi_for_base(fish_id)


func _has_caught_nushi_for_base(base_fish_id: String) -> bool:
	var nushi := GameData.get_nushi_for_base_fish(base_fish_id)
	if nushi.is_empty():
		return false
	return int(PlayerProgress.caught_counts.get(String(nushi.get("id", "")), 0)) > 0


func _refresh_nushi_detail_record(base_fish_id: String, discovered: bool) -> void:
	if _detail_nushi_label == null or _detail_nushi_accent == null:
		return
	var nushi := GameData.get_nushi_for_base_fish(base_fish_id)
	var nushi_id := String(nushi.get("id", ""))
	var caught := discovered and not nushi_id.is_empty() and int(PlayerProgress.caught_counts.get(nushi_id, 0)) > 0
	_detail_nushi_label.visible = caught
	_detail_nushi_accent.visible = caught
	if not caught:
		_detail_nushi_label.text = ""
		return
	var best := float(PlayerProgress.best_sizes.get(nushi_id, 0.0))
	_detail_nushi_label.text = "ヌシ記録　%s　%.1fcm" % [String(nushi.get("name", "ヌシ")), best]


func _fish_portrait_texture(fish: Dictionary, crop_to_fish := false) -> Texture2D:
	var path := FightFishAssets.card_portrait_path(fish)
	var texture := ShowcaseAssets.load_texture(path)
	if texture == null:
		var fallback_color := Palette.FISH_BOOK_FISH_ICON_FALLBACK
		var fallback_html := "#%s" % fallback_color.to_html(false)
		texture = UITextures.get_fish_icon(Color.from_string(String(fish.get("color", fallback_html)), fallback_color))
	if crop_to_fish:
		return _cropped_portrait_texture(texture)
	return texture


func _fish_card_portrait_texture(fish: Dictionary) -> Texture2D:
	var texture := _fish_showcase_frame_texture(fish, "card_frame", null, 0.012, 0.025, 0.070, 2)
	if texture == null:
		return _fish_locked_card_portrait_texture(fish)
	return texture


func _fish_locked_card_portrait_texture(fish: Dictionary) -> Texture2D:
	var texture := _fish_portrait_texture(fish, false)
	return _cropped_portrait_texture(texture, 0.012, 0.025, 0.070, 2)


func _fish_detail_portrait_texture(fish: Dictionary) -> Texture2D:
	return _fish_showcase_frame_texture(fish, "detail_frame", _fish_portrait_texture(fish, true))


func _fish_showcase_frame_texture(
	fish: Dictionary,
	cache_prefix: String,
	fallback: Texture2D = null,
	pad_x_ratio := 0.035,
	pad_y_ratio := 0.060,
	alpha_threshold := 0.035,
	min_pad := 8
) -> Texture2D:
	var path := FightFishAssets.sheet_path(fish)
	var key := "%s:%s:%s:%s:%s:%s" % [
		cache_prefix,
		path,
		str(pad_x_ratio),
		str(pad_y_ratio),
		str(alpha_threshold),
		str(min_pad),
	]
	if _portrait_crop_cache.has(key):
		return _portrait_crop_cache[key]
	var sheet := ShowcaseAssets.load_texture(path)
	if sheet == null:
		_portrait_crop_cache[key] = fallback
		return fallback
	var image := sheet.get_image()
	if image == null or image.is_empty():
		_portrait_crop_cache[key] = fallback
		return fallback
	var frame_width := int(image.get_width() / 4)
	if frame_width <= 0:
		_portrait_crop_cache[key] = fallback
		return fallback
	var frame := image.get_region(Rect2i(0, 0, frame_width, image.get_height()))
	frame.flip_x()
	var texture := ImageTexture.create_from_image(frame)
	var cropped := _cropped_portrait_texture(texture, pad_x_ratio, pad_y_ratio, alpha_threshold, min_pad)
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
	var normal := _filter_tab_style(selected, false)
	var hover := _filter_tab_style(selected, true)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	var font_color := Palette.TEXT_BONE if selected else Palette.TEXT_OUTLINE_LIGHT
	var outline_color := Palette.TEXT_OUTLINE_DARK if selected else _alpha(Palette.GOLD_BRIGHT, 0.95)
	var shadow_color := _alpha(Palette.TEXT_OUTLINE_DARK, 0.34) if selected else _alpha(Palette.GOLD, 0.26)
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
	var font_color := Palette.FISH_BOOK_PRIMARY_BUTTON_TEXT if primary else Palette.FISH_BOOK_BUTTON_TEXT
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_outline_color", Palette.FISH_BOOK_PRIMARY_BUTTON_OUTLINE if primary else Palette.FISH_BOOK_BUTTON_OUTLINE)
	button.add_theme_color_override("font_shadow_color", Palette.FISH_BOOK_PRIMARY_BUTTON_SHADOW if primary else Palette.FISH_BOOK_BUTTON_SHADOW)
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
	icon.modulate = Palette.FISH_BOOK_PRIMARY_ICON_TINT if primary else Palette.FISH_BOOK_ICON_TINT
	if primary:
		_place_control(button, icon, 0.055, 0.170, 0.240, 0.830)
	else:
		_place_control(button, icon, 0.055, 0.235, 0.245, 0.770)


func _style_scrollbar(scroll: ScrollContainer) -> void:
	var vbar := scroll.get_v_scroll_bar()
	if vbar == null:
		return
	vbar.custom_minimum_size = Vector2(10.0, 0.0)
	var track := UITextures.flat_style(_alpha(Palette.FISH_BOOK_SCROLL_TRACK_BG, 0.58), _alpha(Palette.FISH_BOOK_SCROLL_TRACK_BORDER, 0.48), 1, 5)
	var grabber := UITextures.flat_style(Palette.FISH_BOOK_SCROLL_GRABBER, Palette.FISH_BOOK_SCROLL_GRABBER_BORDER, 1, 5, true, 2)
	var grabber_hot := UITextures.flat_style(Palette.FISH_BOOK_SCROLL_GRABBER_HOT, Palette.FISH_BOOK_SCROLL_GRABBER_HOT_BORDER, 1, 5, true, 2)
	vbar.add_theme_stylebox_override("scroll", track)
	vbar.add_theme_stylebox_override("scroll_focus", track)
	vbar.add_theme_stylebox_override("grabber", grabber)
	vbar.add_theme_stylebox_override("grabber_highlight", grabber_hot)
	vbar.add_theme_stylebox_override("grabber_pressed", grabber_hot)


func _book_label(
	text: String,
	font_size: int,
	color: Color,
	bold := false,
	outline := 0,
	outline_color := Palette.FISH_BOOK_INK_OUTLINE
) -> Label:
	return make_screen_label(text, font_size, color, bold, outline, outline_color, Palette.FISH_BOOK_LABEL_SHADOW)


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
	return Palette.FISH_BOOK_PORTRAIT_PAPER_TINT


func _add_portrait_underprint(
	parent: Control,
	texture: Texture2D,
	alpha: float,
	spread_x: float,
	spread_y: float
) -> Array[TextureRect]:
	var layers: Array[TextureRect] = []
	var offsets := [
		Vector2(-spread_x, 0.0),
		Vector2(spread_x, 0.0),
		Vector2(0.0, -spread_y),
		Vector2(0.0, spread_y),
	]
	for offset in offsets:
		var layer := _portrait_rect(_alpha(Palette.WOOD_DARK, alpha))
		layer.texture = texture
		_place_control(parent, layer, offset.x, offset.y, 1.0 + offset.x, 1.0 + offset.y)
		layers.append(layer)
	return layers


func _detail_icon(icon_index: int) -> Texture2D:
	return _atlas_icon(_detail_icon_sheet, FISH_BOOK_ICON_SIZE, icon_index)


func _footer_icon(icon_index: int) -> Texture2D:
	return _atlas_icon(_footer_icon_sheet, FISH_BOOK_ICON_SIZE, icon_index)


func _atlas_icon(sheet: Texture2D, cell_size: float, icon_index: int) -> Texture2D:
	if sheet == null or icon_index < 0:
		return null
	return ShowcaseAssetsScript.atlas_icon_from_texture(sheet, cell_size, icon_index)

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


func _paper_wash() -> TextureRect:
	var gradient := Gradient.new()
	gradient.set_color(0, _alpha(Palette.PARCHMENT, 0.78))
	gradient.set_color(1, _alpha(Palette.PARCHMENT_DEEP, 0.44))
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


func _add_left_page_guides(parent: Control) -> void:
	var left_edge := _label_plate(_alpha(Palette.WOOD_DARK, 0.10))
	_place_control(parent, left_edge, 0.047, 0.105, 0.056, 0.970)
	var right_edge := _label_plate(_alpha(Palette.WOOD_DARK, 0.08))
	_place_control(parent, right_edge, 0.927, 0.105, 0.936, 0.970)
	for y in [0.310, 0.524, 0.738, 0.952]:
		_add_rule(parent, 0.058, y, 0.922, _alpha(Palette.WOOD_DARK, 0.13), 1.0)
	for x in [0.342, 0.636]:
		var column_rule := _label_plate(_alpha(Palette.WOOD_DARK, 0.075))
		_place_control(parent, column_rule, x, 0.126, x + 0.002, 0.952)


func _label_plate(color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _add_specimen_rule(parent: Control, left: float, top: float, right: float, bottom: float, color: Color) -> void:
	var rule := _label_plate(color)
	_place_control(parent, rule, left, top, right, bottom)


func _add_specimen_ruler(parent: Control) -> void:
	_add_specimen_rule(parent, 0.105, 0.858, 0.895, 0.864, _alpha(Palette.WOOD_DARK, 0.10))
	for index in range(11):
		var x := 0.105 + 0.079 * float(index)
		var top := 0.848
		var color := _alpha(Palette.WOOD_DARK, 0.12)
		if index % 5 == 0:
			top = 0.820
			color = _alpha(Palette.WOOD_DARK, 0.18)
		elif index % 2 == 0:
			top = 0.838
			color = _alpha(Palette.WOOD_DARK, 0.15)
		_add_specimen_rule(parent, x - 0.002, top, x + 0.002, 0.866, color)


func _add_detail_specimen_fixture(parent: Control, left: float, top: float, right: float, bottom: float) -> void:
	var tape := Panel.new()
	tape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tape.add_theme_stylebox_override("panel", _detail_specimen_tape_style())
	_place_control(parent, tape, left, top, right, bottom)
	var pin := Panel.new()
	pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pin.add_theme_stylebox_override("panel", _detail_specimen_pin_style())
	var center_x := (left + right) * 0.5
	var center_y := top + (bottom - top) * 0.50
	_place_control(parent, pin, center_x - 0.018, center_y - 0.028, center_x + 0.018, center_y + 0.028)


func _detail_stat_slip_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _alpha(Palette.PARCHMENT_DEEP, 0.48)
	style.border_color = _alpha(Palette.WOOD_DARK, 0.28)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 4.0
	style.content_margin_top = 2.0
	style.content_margin_right = 4.0
	style.content_margin_bottom = 2.0
	return style


func _nushi_detail_accent_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = _alpha(Palette.GOLD_BRIGHT, 0.86)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.shadow_color = _alpha(Palette.GOLD, 0.22)
	style.shadow_size = 4
	style.shadow_offset = Vector2.ZERO
	return style


func _nushi_card_pin_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _alpha(Palette.GOLD_BRIGHT, 0.92)
	style.border_color = _alpha(Palette.GOLD_DEEP, 0.95)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.shadow_color = _alpha(Palette.TEXT_OUTLINE_DARK, 0.30)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0.0, 1.0)
	return style


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


func _filter_tab_style(selected: bool, hot: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if selected:
		style.bg_color = _alpha(Palette.DARK_PANEL, 0.94 if not hot else 0.98)
		style.border_color = _alpha(Palette.GOLD_BRIGHT, 0.82 if not hot else 0.95)
	else:
		style.bg_color = _alpha(Palette.PARCHMENT_DEEP, 0.88 if not hot else 0.96)
		style.border_color = _alpha(Palette.WOOD_DARK, 0.72 if not hot else 0.86)
	style.set_border_width_all(1)
	style.set_border_width(SIDE_TOP, 2 if selected else 1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 8.0
	style.content_margin_top = 3.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 4.0
	style.shadow_color = _alpha(Palette.TEXT_OUTLINE_DARK, 0.22 if selected else 0.14)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0.0, 2.0)
	return style


func _return_button_plaque_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _alpha(Palette.WOOD_DARK, 0.70)
	style.border_color = _alpha(Palette.GOLD_DEEP, 0.58)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 4.0
	style.content_margin_top = 4.0
	style.content_margin_right = 4.0
	style.content_margin_bottom = 4.0
	style.shadow_color = _alpha(Palette.TEXT_OUTLINE_DARK, 0.24)
	style.shadow_size = 3
	style.shadow_offset = Vector2(0.0, 2.0)
	return style


func _locked_card_seal_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _alpha(Palette.GOLD_DEEP, 0.84)
	style.border_color = _alpha(Palette.WOOD_DARK, 0.72)
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.content_margin_left = 2.0
	style.content_margin_top = 2.0
	style.content_margin_right = 2.0
	style.content_margin_bottom = 2.0
	style.shadow_color = _alpha(Palette.TEXT_OUTLINE_DARK, 0.24)
	style.shadow_size = 2
	style.shadow_offset = Vector2(1.0, 1.0)
	return style


func _detail_specimen_tape_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _alpha(Palette.PARCHMENT_DEEP, 0.46)
	style.border_color = _alpha(Palette.WOOD_DARK, 0.18)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.shadow_color = _alpha(Palette.TEXT_OUTLINE_DARK, 0.10)
	style.shadow_size = 2
	style.shadow_offset = Vector2(0.0, 1.0)
	return style


func _detail_specimen_pin_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _alpha(Palette.GOLD_DEEP, 0.78)
	style.border_color = _alpha(Palette.WOOD_DARK, 0.52)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.shadow_color = _alpha(Palette.TEXT_OUTLINE_DARK, 0.20)
	style.shadow_size = 1
	style.shadow_offset = Vector2(1.0, 1.0)
	return style


func _collection_progress_track_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _alpha(Palette.TEXT_OUTLINE_DARK, 0.48)
	style.border_color = _alpha(Palette.GOLD_DEEP, 0.52)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 1.0
	style.content_margin_top = 1.0
	style.content_margin_right = 1.0
	style.content_margin_bottom = 1.0
	return style


func _card_body_style(discovered: bool, selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var base_alpha := 0.76 if discovered else 0.50
	if selected:
		base_alpha = 0.84
	style.bg_color = _alpha(Palette.PARCHMENT if discovered else Palette.PARCHMENT_DEEP, base_alpha)
	style.border_color = _alpha(Palette.WOOD_DARK, 0.24 if discovered else 0.30)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.content_margin_left = 3.0
	style.content_margin_top = 3.0
	style.content_margin_right = 3.0
	style.content_margin_bottom = 3.0
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


func _selected_card_bookmark_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _alpha(Palette.GOLD_DEEP, 0.76)
	style.border_color = _alpha(Palette.WOOD_DARK, 0.72)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.shadow_color = _alpha(Palette.TEXT_OUTLINE_DARK, 0.18)
	style.shadow_size = 2
	style.shadow_offset = Vector2(1.0, 1.0)
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
