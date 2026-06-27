extends "res://src/ui/screen_base.gd"

const GaugeBarScript = preload("res://src/ui/components/gauge_bar.gd")
const LevelUpPanelScript = preload("res://src/ui/components/level_up_panel.gd")
const CookingRewardPanelScript = preload("res://src/ui/components/cooking_reward_panel.gd")
const CookingStatusPanelScript = preload("res://src/ui/components/cooking_status_panel.gd")

const COOKING_BG := "res://assets/showcase/cooking/cooking_room_bg.png"
const COOKING_TITLE_BANNER := "res://assets/showcase/cooking/cooking_title_banner.png"
const COOKING_SECTION_RIBBON := "res://assets/showcase/cooking/cooking_section_ribbon.png"
const FISH_ICON_SHEET := "res://assets/showcase/cooking/fish_icon_sheet.png"
const DISH_ICON_SHEET := "res://assets/showcase/cooking/dish_icon_sheet.png"
const DISH_FEATURE_AJI := "res://assets/showcase/cooking/dish_feature_aji_shioyaki.png"
const DISH_FEATURE_SASHIMI := "res://assets/showcase/cooking/dish_feature_sashimi.png"
const DISH_FEATURE_SIMMERED := "res://assets/showcase/cooking/dish_feature_simmered.png"
const DISH_FEATURE_SOUP := "res://assets/showcase/cooking/dish_feature_soup.png"
const DISH_FEATURE_FRY := "res://assets/showcase/cooking/dish_feature_fry.png"
const RECIPE_GRID_FRAME := "res://assets/showcase/cooking/recipe_grid_frame.png"
const RECIPE_CARD_FRAME := "res://assets/showcase/cooking/recipe_card_frame.png"
const RECIPE_SELECTED_CARD_FRAME := "res://assets/showcase/cooking/recipe_selected_card_frame.png"
const RECIPE_TO_DETAIL_ARROW := "res://assets/showcase/cooking/recipe_to_detail_arrow.png"
const DISH_DETAIL_FRAME := "res://assets/showcase/cooking/dish_detail_frame.png"
const COOK_BUTTON_FRAME := "res://assets/showcase/cooking/cook_button_frame.png"
const FISH_ROW_FRAME := "res://assets/showcase/cooking/fish_row_frame.png"
const PLAYER_HEADER_PORTRAIT := "res://assets/showcase/cooking/player_status_portrait_pixel.png"
const FISH_CARD_PORTRAIT_PATHS := {
	"aji": "res://assets/showcase/underwater/fish/aji_card_portrait.png",
	"saba": "res://assets/showcase/underwater/fish/saba_card_portrait.png",
	"tai": "res://assets/showcase/underwater/fish/madai_card_portrait.png",
	"kasago": "res://assets/showcase/underwater/fish/kasago_card_portrait.png",
	"hirame": "res://assets/showcase/underwater/fish/hirame_card_portrait.png",
	"mejina": "res://assets/showcase/underwater/fish/mejina_card_portrait.png",
	"isaki": "res://assets/showcase/underwater/fish/isaki_card_portrait.png",
	"boss_kurodai": "res://assets/showcase/underwater/fish/kurodai_card_portrait.png",
}


class CookingSmallIcon:
	extends Control

	var mode := "player"
	var accent := Color.WHITE

	func configure(next_mode: String, next_accent: Color) -> void:
		mode = next_mode
		accent = next_accent
		queue_redraw()

	func _draw() -> void:
		match mode:
			"coin":
				_draw_coin()
			"meal":
				_draw_meal()
			"cooler":
				_draw_cooler()
			"book":
				_draw_book()
			"fish":
				_draw_fish()
			"exp":
				_draw_exp()
			"buff":
				_draw_buff()
			"fire":
				_draw_fire()
			_:
				_draw_player()

	func _draw_player() -> void:
		var center := size * 0.5
		draw_circle(center + Vector2(0.0, -7.0), 15.0, Color("#f2b889"))
		draw_rect(Rect2(center.x - 18.0, center.y + 8.0, 36.0, 22.0), Color("#17324d"))
		draw_rect(Rect2(center.x - 18.0, center.y - 24.0, 36.0, 9.0), Color("#234f7c"))
		draw_circle(center + Vector2(-6.0, -8.0), 2.0, Color("#1d160f"))
		draw_circle(center + Vector2(6.0, -8.0), 2.0, Color("#1d160f"))

	func _draw_coin() -> void:
		var center := size * 0.5
		for i in range(3):
			var offset := Vector2(float(i) * 7.0 - 7.0, float(i % 2) * 5.0)
			draw_circle(center + offset, 14.0, Color("#9b641e"))
			draw_circle(center + offset + Vector2(-2.0, -2.0), 10.0, Palette.GOLD_BRIGHT)
			draw_arc(center + offset, 10.0, 0.0, TAU, 18, Color("#70451f"), 2.0)

	func _draw_meal() -> void:
		var center := size * 0.5
		draw_arc(center + Vector2(0.0, 12.0), 21.0, 0.0, PI, 24, Color("#fff1cf"), 6.0)
		draw_arc(center + Vector2(0.0, 8.0), 17.0, 0.0, PI, 22, Color("#b35f25"), 5.0)
		for i in range(3):
			var x := center.x - 12.0 + float(i) * 12.0
			draw_arc(Vector2(x, center.y - 13.0), 8.0, -1.6, 0.9, 10, Color(1.0, 0.92, 0.70, 0.34), 2.0)

	func _draw_cooler() -> void:
		var center := size * 0.5
		draw_rect(Rect2(center.x - 22.0, center.y - 6.0, 44.0, 28.0), Color("#1b5d8d"))
		draw_rect(Rect2(center.x - 22.0, center.y - 6.0, 44.0, 7.0), Color("#eef4fa"))
		draw_rect(Rect2(center.x - 16.0, center.y - 18.0, 32.0, 10.0), Color("#d7e3ef"))
		draw_line(center + Vector2(-10.0, 11.0), center + Vector2(10.0, 11.0), Color("#f0f6fb"), 3.0)

	func _draw_book() -> void:
		var center := size * 0.5
		draw_rect(Rect2(center.x - 18.0, center.y - 18.0, 36.0, 36.0), Color("#17324d"))
		draw_rect(Rect2(center.x - 14.0, center.y - 14.0, 28.0, 28.0), Color("#f2e4c2"))
		draw_line(center + Vector2(0.0, -14.0), center + Vector2(0.0, 14.0), Color("#8b5b2c"), 2.0)
		draw_line(center + Vector2(-10.0, -4.0), center + Vector2(-3.0, -4.0), accent, 2.0)
		draw_line(center + Vector2(4.0, 5.0), center + Vector2(11.0, 5.0), accent, 2.0)

	func _draw_fish() -> void:
		var center := size * 0.5
		var body := PackedVector2Array(
			[
				center + Vector2(-22.0, 0.0),
				center + Vector2(-8.0, -11.0),
				center + Vector2(18.0, -5.0),
				center + Vector2(23.0, 0.0),
				center + Vector2(18.0, 5.0),
				center + Vector2(-8.0, 11.0),
			]
		)
		draw_colored_polygon(body, Color("#3e86b5"))
		draw_colored_polygon(
			PackedVector2Array(
				[
					center + Vector2(18.0, -5.0),
					center + Vector2(30.0, -15.0),
					center + Vector2(27.0, 0.0),
					center + Vector2(30.0, 15.0),
					center + Vector2(18.0, 5.0),
				]
			),
			Color("#275d86")
		)
		draw_line(center + Vector2(-9.0, -7.0), center + Vector2(13.0, -2.0), Color("#d6eef4"), 2.0)
		draw_circle(center + Vector2(-16.0, -2.0), 2.2, Color("#1d160f"))

	func _draw_exp() -> void:
		var center := size * 0.5
		draw_circle(center, 19.0, Color("#0f5d76"))
		draw_circle(center, 13.0, accent)
		for i in range(8):
			var angle := TAU * float(i) / 8.0
			var from := center + Vector2(cos(angle), sin(angle)) * 21.0
			var to := center + Vector2(cos(angle), sin(angle)) * 28.0
			draw_line(from, to, Color("#fff2b8"), 2.0)
		draw_circle(center, 5.0, Color("#fff2b8"))

	func _draw_buff() -> void:
		var center := size * 0.5
		draw_circle(center, 19.0, Color("#2f7a45"))
		draw_arc(center + Vector2(-3.0, 2.0), 13.0, -0.2, 2.8, 20, Color("#f8f0cf"), 4.0)
		draw_line(center + Vector2(-8.0, 3.0), center + Vector2(-16.0, -4.0), Color("#f8f0cf"), 4.0)
		draw_circle(center + Vector2(11.0, -11.0), 4.0, accent)

	func _draw_fire() -> void:
		var center := size * 0.5
		var flame := PackedVector2Array(
			[
				center + Vector2(0.0, -24.0),
				center + Vector2(15.0, -5.0),
				center + Vector2(9.0, 19.0),
				center + Vector2(0.0, 25.0),
				center + Vector2(-10.0, 17.0),
				center + Vector2(-15.0, -4.0),
			]
		)
		draw_colored_polygon(flame, Color("#cf5c26"))
		draw_colored_polygon(
			PackedVector2Array(
				[
					center + Vector2(1.0, -12.0),
					center + Vector2(8.0, 2.0),
					center + Vector2(3.0, 14.0),
					center + Vector2(-4.0, 14.0),
					center + Vector2(-7.0, 0.0),
				]
			),
			accent
		)


class CookActionCueVisual:
	extends Control

	var available := true

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_available(next_available: bool) -> void:
		available = next_available
		modulate = Color.WHITE if available else Color(0.62, 0.58, 0.50, 0.72)
		queue_redraw()

	func _draw() -> void:
		var w := maxf(size.x, 1.0)
		var h := maxf(size.y, 1.0)
		var cy := h * 0.55
		var left := minf(58.0, w * 0.26)
		var right := maxf(left + 42.0, w - minf(62.0, w * 0.28))
		var rail := Color(1.0, 0.78, 0.28, 0.72) if available else Color(0.52, 0.45, 0.36, 0.55)
		var glow := Color(1.0, 0.95, 0.66, 0.55) if available else Color(0.58, 0.52, 0.42, 0.35)
		var ink := Color("#3b2515") if available else Color("#6b5a44")
		var fill := Color("#d68a31") if available else Color("#8d7453")
		draw_line(Vector2(left, cy), Vector2(right, cy), glow, 7.0)
		draw_line(Vector2(left, cy), Vector2(right, cy), rail, 2.5)
		draw_colored_polygon(
			PackedVector2Array(
				[
					Vector2(right + 14.0, cy),
					Vector2(right - 3.0, cy - 7.0),
					Vector2(right - 3.0, cy + 7.0),
				]
			),
			rail
		)
		_draw_pot(Vector2(left - 28.0, cy + 2.0), ink, fill, glow)
		_draw_plate(Vector2(right + 34.0, cy + 1.0), ink, fill, glow)
		for i in range(3):
			var x := lerpf(left + 22.0, right - 20.0, float(i) / 2.0)
			var y := cy - 8.0 - float(i % 2) * 3.0
			draw_circle(Vector2(x, y), 2.4, glow)

	func _draw_pot(origin: Vector2, ink: Color, fill: Color, glow: Color) -> void:
		draw_rect(Rect2(origin.x - 15.0, origin.y - 4.0, 30.0, 16.0), ink)
		draw_rect(Rect2(origin.x - 12.0, origin.y - 1.0, 24.0, 12.0), fill)
		draw_line(origin + Vector2(-17.0, -6.0), origin + Vector2(17.0, -6.0), ink, 4.0)
		draw_arc(origin + Vector2(0.0, -10.0), 10.0, PI, TAU, 12, ink, 2.0)
		draw_line(origin + Vector2(-8.0, 13.0), origin + Vector2(-14.0, 18.0), ink, 2.0)
		draw_line(origin + Vector2(8.0, 13.0), origin + Vector2(14.0, 18.0), ink, 2.0)
		for i in range(2):
			draw_arc(
				origin + Vector2(-5.0 + float(i) * 10.0, -17.0),
				6.0,
				-1.8,
				0.8,
				8,
				glow,
				1.8
			)

	func _draw_plate(origin: Vector2, ink: Color, fill: Color, glow: Color) -> void:
		draw_colored_polygon(_oval_points(origin + Vector2(0.0, 9.5), 20.0, 5.5, 20), ink)
		draw_colored_polygon(
			_oval_points(origin + Vector2(0.0, 8.5), 16.0, 3.5, 20),
			Color("#fff0c7") if available else Color("#a69478")
		)
		draw_colored_polygon(
			PackedVector2Array(
				[
					origin + Vector2(-13.0, 4.0),
					origin + Vector2(-4.0, -10.0),
					origin + Vector2(14.0, -4.0),
					origin + Vector2(10.0, 5.0),
				]
			),
			fill
		)
		draw_line(origin + Vector2(-12.0, 2.0), origin + Vector2(12.0, -2.0), glow, 2.0)

	func _oval_points(center: Vector2, radius_x: float, radius_y: float, segments: int) -> PackedVector2Array:
		var points := PackedVector2Array()
		for i in range(segments):
			var angle := TAU * float(i) / float(segments)
			points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
		return points


const FISH_ICON_INDEX := {
	"aji": 0,
	"mejina": 1,
	"kasago": 2,
	"isaki": 3,
	"saba": 4,
	"boss_kurodai": 5,
}

const RECIPE_ICON_INDEX := {
	"salt_grill": 0,
	"sashimi": 1,
	"simmered": 2,
	"soup": 3,
	"fry": 4,
}

enum FlowState { COOK_SELECT, MEAL_RESULT, EXP_GAIN }

var _flow_state := FlowState.COOK_SELECT
var _selected_fish_id: String = ""
var _selected_recipe_id: String = ""
var _preview_suppress_level_overlay := false

var _level_label: Label
var _money_label: Label
var _exp_bar: GaugeBar
var _exp_label: Label
var _fish_box: VBoxContainer
var _recipe_grid: GridContainer
var _recipe_to_detail_arrow: TextureRect
var _dish_title: Label
var _dish_subtitle: Label
var _dish_image: TextureRect
var _material_value: Label
var _exp_value: Label
var _bonus_value: Label
var _buff_value: Label
var _effect_count_value: Label
var _stock_value: Label
var _overwrite_note: Label
var _cook_action_cue: CookActionCueVisual
var _cook_button: Button
var _result_panel: PanelContainer
var _result_title: Label
var _result_body: HBoxContainer
var _status_button: Button

var _fish_cards: Dictionary = {}
var _recipe_cards: Dictionary = {}
var _pending_level_up: Dictionary = {}


func configure(payload: Dictionary) -> void:
	super.configure(payload)
	_preview_suppress_level_overlay = bool(payload.get("suppress_level_overlay", false))


func _build_screen() -> void:
	_add_cooking_background()
	var root := make_root_margin(4)
	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 5)
	root.add_child(layout)

	_build_header(layout)
	_build_cook_select(layout)
	_build_result_summary(layout)

	_refresh_all()
	_show_status_summary()


func _add_cooking_background() -> void:
	var bg_tex := load(COOKING_BG) as Texture2D
	if bg_tex != null:
		var bg := TextureRect.new()
		bg.texture = bg_tex
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
		move_child(bg, 0)
	else:
		add_gradient_background(Color("#2a2418"), Color("#14110b"))

	var glaze := ColorRect.new()
	glaze.color = Color(0.03, 0.06, 0.10, 0.34)
	glaze.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glaze.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glaze)
	move_child(glaze, 1)


func _build_header(layout: VBoxContainer) -> void:
	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 64)
	header.add_theme_constant_override("separation", 8)
	layout.add_child(header)

	var title_card := _texture_panel_box(
		COOKING_TITLE_BANNER,
		30,
		_style_box(Color("#25170e"), Color("#70451f"), Color("#f0c06b"), 6, 5),
		24.0,
		8.0
	)
	title_card.name = "CookingTitleBanner"
	title_card.custom_minimum_size = Vector2(318, 0)
	header.add_child(title_card)
	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", 6)
	title_card.add_child(title_row)
	var title := make_shadow_label("調理場", 34, Palette.GOLD_BRIGHT, 5)
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.custom_minimum_size = Vector2(118.0, 0.0)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_row.add_child(title)

	var status_card := _panel_box(Color("#0d2338"), Color("#70451f"), Color("#dba75b"), 6)
	status_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(status_card)
	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 12)
	status_card.add_child(status_row)
	var player_icon := _header_player_icon()
	status_row.add_child(player_icon)
	_level_label = make_shadow_label("", 21, Palette.TEXT_BONE, 3)
	_level_label.custom_minimum_size = Vector2(138, 0)
	status_row.add_child(_level_label)
	_exp_bar = GaugeBarScript.new()
	_exp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_exp_bar.show_value = false
	_exp_bar.custom_minimum_size = Vector2(0, 24)
	_exp_bar.set_colors(Palette.GAUGE_CYAN, Palette.GAUGE_CYAN_HI)
	status_row.add_child(_exp_bar)
	_exp_label = make_shadow_label("", 17, Palette.TEXT_BONE, 2)
	_exp_label.custom_minimum_size = Vector2(126, 0)
	_exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_row.add_child(_exp_label)

	var money_card := _panel_box(Color("#0d2338"), Color("#70451f"), Color("#dba75b"), 6)
	money_card.custom_minimum_size = Vector2(224, 0)
	header.add_child(money_card)
	var money_row := HBoxContainer.new()
	money_row.alignment = BoxContainer.ALIGNMENT_CENTER
	money_row.add_theme_constant_override("separation", 8)
	money_card.add_child(money_row)
	money_row.add_child(_small_icon("coin", Palette.GOLD_BRIGHT, Vector2(46.0, 0.0)))
	_money_label = make_shadow_label("", 22, Palette.GOLD_BRIGHT, 3)
	_money_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_money_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	money_row.add_child(_money_label)

	var back := make_button("港へ", func() -> void: navigate("harbor"), 96, false)
	back.custom_minimum_size = Vector2(90, 52)
	header.add_child(back)


func _build_cook_select(layout: VBoxContainer) -> void:
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	layout.add_child(body)

	var fish_panel := _panel_box(Color("#10283d"), Color("#5e391a"), Color("#e4b461"), 6)
	fish_panel.custom_minimum_size = Vector2(306, 0)
	fish_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(fish_panel)
	var fish_layout := VBoxContainer.new()
	fish_layout.add_theme_constant_override("separation", 6)
	fish_panel.add_child(fish_layout)
	fish_layout.add_child(_section_ribbon("所持している魚", "fish", "FishSectionRibbon"))
	_fish_box = VBoxContainer.new()
	_fish_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_fish_box.add_theme_constant_override("separation", 6)
	fish_layout.add_child(_fish_box)

	var recipe_panel := _texture_panel_box(
		RECIPE_GRID_FRAME,
		32,
		_style_box(Color("#ead9b2"), Color("#5e391a"), Color("#e6b561"), 6, 5),
		16.0,
		10.0
	)
	recipe_panel.custom_minimum_size = Vector2(452, 0)
	recipe_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(recipe_panel)
	var recipe_layout := VBoxContainer.new()
	recipe_layout.add_theme_constant_override("separation", 6)
	recipe_panel.add_child(recipe_layout)
	recipe_layout.add_child(_section_ribbon("料理を選ぶ", "fire", "RecipeSectionRibbon"))
	_recipe_grid = GridContainer.new()
	_recipe_grid.name = "RecipeGrid"
	_recipe_grid.columns = 3
	_recipe_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_recipe_grid.add_theme_constant_override("h_separation", 8)
	_recipe_grid.add_theme_constant_override("v_separation", 10)
	recipe_layout.add_child(_recipe_grid)

	_recipe_to_detail_arrow = TextureRect.new()
	_recipe_to_detail_arrow.name = "RecipeToDetailArrow"
	_recipe_to_detail_arrow.texture = load(RECIPE_TO_DETAIL_ARROW) as Texture2D
	_recipe_to_detail_arrow.custom_minimum_size = Vector2(30, 0)
	_recipe_to_detail_arrow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_recipe_to_detail_arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_recipe_to_detail_arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_recipe_to_detail_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(_recipe_to_detail_arrow)

	var detail_panel := _texture_panel_box(
		DISH_DETAIL_FRAME,
		34,
		_style_box(Color("#f4e7c8"), Color("#5e391a"), Color("#e6b561"), 6, 5),
		18.0,
		12.0
	)
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(detail_panel)
	var detail_layout := VBoxContainer.new()
	detail_layout.add_theme_constant_override("separation", 6)
	detail_panel.add_child(detail_layout)
	_dish_title = make_label("料理を選んでください", 28, Color("#2a2118"), 1, Color("#fff4d4"))
	_dish_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dish_title.custom_minimum_size = Vector2(0.0, 34.0)
	detail_layout.add_child(_dish_title)
	_dish_subtitle = make_label("", 15, Color("#59422b"))
	_dish_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dish_subtitle.custom_minimum_size = Vector2(0.0, 20.0)
	detail_layout.add_child(_dish_subtitle)
	var dish_frame := _panel_box(Color("#6a4023"), Color("#3b2515"), Color("#e6b561"), 4)
	dish_frame.custom_minimum_size = Vector2(0, 122)
	dish_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_layout.add_child(dish_frame)
	_dish_image = TextureRect.new()
	_dish_image.name = "SelectedDishFeatureImage"
	_dish_image.custom_minimum_size = Vector2(0, 106)
	_dish_image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dish_image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dish_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dish_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dish_frame.add_child(_dish_image)
	var detail_rows := VBoxContainer.new()
	detail_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_rows.add_theme_constant_override("separation", 6)
	detail_layout.add_child(detail_rows)
	var material_labels := _add_detail_story_row(
		detail_rows,
		"CookDetailMaterialRow",
		"必要な材料",
		"fish",
		Palette.GAUGE_CYAN_HI,
		150.0
	)
	_material_value = material_labels[0] as Label
	_stock_value = material_labels[1] as Label
	var exp_labels := _add_detail_story_row(
		detail_rows,
		"CookDetailExpRow",
		"獲得EXP",
		"exp",
		Palette.GOLD_BRIGHT,
		142.0
	)
	_exp_value = exp_labels[0] as Label
	_bonus_value = exp_labels[1] as Label
	var buff_labels := _add_detail_story_row(
		detail_rows,
		"CookDetailEffectRow",
		"次の釣行で得られる効果",
		"buff",
		Palette.GAUGE_GREEN_HI,
		158.0
	)
	_buff_value = buff_labels[0] as Label
	_effect_count_value = buff_labels[1] as Label
	var cue_row := HBoxContainer.new()
	cue_row.custom_minimum_size = Vector2(0, 24)
	cue_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cue_row.add_theme_constant_override("separation", 8)
	detail_layout.add_child(cue_row)
	_overwrite_note = make_label("", 13, Color("#624b31"))
	_overwrite_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_overwrite_note.clip_text = true
	_overwrite_note.custom_minimum_size = Vector2(0, 22)
	_overwrite_note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_overwrite_note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cue_row.add_child(_overwrite_note)
	_cook_action_cue = CookActionCueVisual.new()
	_cook_action_cue.name = "CookActionCue"
	_cook_action_cue.custom_minimum_size = Vector2(112, 22)
	cue_row.add_child(_cook_action_cue)
	_cook_button = make_button("調理する", _cook_selected, 300, true)
	_cook_button.name = "CookButton"
	_cook_button.custom_minimum_size = Vector2(286, 46)
	_cook_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_apply_cook_button_style()
	_cook_button.draw.connect(func() -> void: _draw_cook_button_icon(_cook_button))
	detail_layout.add_child(_cook_button)


func _build_result_summary(layout: VBoxContainer) -> void:
	var result_panel := _panel_box(Color("#0f2338"), Color("#5e391a"), Color("#e3b15e"), 6)
	_result_panel = result_panel
	result_panel.custom_minimum_size = Vector2(0, 58)
	layout.add_child(result_panel)
	var result_layout := VBoxContainer.new()
	result_layout.add_theme_constant_override("separation", 4)
	result_panel.add_child(result_layout)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 10)
	result_layout.add_child(title_row)
	var left_spacer := Control.new()
	left_spacer.custom_minimum_size = Vector2(92, 0)
	title_row.add_child(left_spacer)
	_result_title = make_shadow_label("", 18, Palette.GOLD_BRIGHT, 3)
	_result_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_row.add_child(_result_title)
	_status_button = make_button("詳細", _show_status_overlay, 100, false)
	_status_button.custom_minimum_size = Vector2(92, 34)
	title_row.add_child(_status_button)
	_result_body = HBoxContainer.new()
	_result_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_result_body.add_theme_constant_override("separation", 6)
	result_layout.add_child(_result_body)


func _add_detail_tile(
	parent: Container, title: String, value: String, icon_mode: String, accent: Color
) -> Label:
	var tile := _panel_box(Color("#fff0cf"), Color("#8b5b2c"), Color("#e6b561"), 3)
	tile.custom_minimum_size = Vector2(0, 32)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(tile)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	tile.add_child(row)
	row.add_child(_small_icon(icon_mode, accent, Vector2(30.0, 0.0)))
	var title_label := make_label(title, 13, Color("#6a4a2b"))
	title_label.custom_minimum_size = Vector2(88, 0)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(title_label)
	var value_label := make_label(value, 17, Color("#2a2118"), 1, Color("#fff2cf"))
	value_label.custom_minimum_size = Vector2(0, 24)
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.clip_text = true
	row.add_child(value_label)
	return value_label


func _add_detail_story_row(
	parent: Container,
	node_name: String,
	title: String,
	icon_mode: String,
	accent: Color,
	title_width: float
) -> Array:
	var tile := _panel_box(Color("#fff0cf"), Color("#8b5b2c"), Color("#e6b561"), 3)
	tile.name = node_name
	tile.custom_minimum_size = Vector2(0, 42)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(tile)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	tile.add_child(row)

	var title_band := _panel_box(Color("#5a3a1c"), Color("#3b2515"), Color("#d7a456"), 2)
	title_band.custom_minimum_size = Vector2(title_width, 28)
	row.add_child(title_band)
	var title_row := HBoxContainer.new()
	title_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	title_row.add_theme_constant_override("separation", 5)
	title_band.add_child(title_row)
	var compact := title.length() > 6
	title_row.add_child(_small_icon(icon_mode, accent, Vector2(18.0 if compact else 24.0, 0.0)))
	var title_size := 8 if compact else 12
	var title_label := make_shadow_label(title, title_size, Palette.TEXT_BONE, 2)
	title_label.custom_minimum_size = Vector2(0, 22)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_label.clip_text = true
	title_row.add_child(title_label)

	var primary_size := 12 if compact else 14
	var primary := make_label("", primary_size, Color("#2a2118"), 1, Color("#fff2cf"))
	primary.custom_minimum_size = Vector2(0, 24)
	primary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	primary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	primary.autowrap_mode = TextServer.AUTOWRAP_OFF
	primary.clip_text = true
	row.add_child(primary)

	var secondary := make_label("", primary_size, accent, 1, Color("#fff2cf"))
	secondary.custom_minimum_size = Vector2(62 if compact else 108, 24)
	secondary.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	secondary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	secondary.autowrap_mode = TextServer.AUTOWRAP_OFF
	secondary.clip_text = true
	row.add_child(secondary)
	return [primary, secondary]


func _add_detail_pair_tile(
	parent: Container,
	left_title: String,
	right_title: String,
	left_icon: String,
	right_icon: String,
	left_accent: Color,
	right_accent: Color
) -> Array:
	var tile := _panel_box(Color("#fff0cf"), Color("#8b5b2c"), Color("#e6b561"), 3)
	tile.custom_minimum_size = Vector2(0, 36)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(tile)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	tile.add_child(row)

	var left_value := _add_detail_pair_cell(row, left_title, left_icon, left_accent)
	var divider := ColorRect.new()
	divider.color = Color(0.545, 0.357, 0.173, 0.35)
	divider.custom_minimum_size = Vector2(2, 0)
	row.add_child(divider)
	var right_value := _add_detail_pair_cell(row, right_title, right_icon, right_accent)
	return [left_value, right_value]


func _add_detail_pair_cell(
	parent: HBoxContainer, title: String, icon_mode: String, accent: Color
) -> Label:
	var cell := HBoxContainer.new()
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.add_theme_constant_override("separation", 5)
	parent.add_child(cell)
	cell.add_child(_small_icon(icon_mode, accent, Vector2(26.0, 0.0)))
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 0)
	cell.add_child(box)
	var title_label := make_label(title, 12, Color("#6a4a2b"))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title_label)
	var value_label := make_label("", 16, Color("#2a2118"), 1, Color("#fff2cf"))
	value_label.custom_minimum_size = Vector2(0, 22)
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.clip_text = true
	box.add_child(value_label)
	return value_label


func _refresh_all() -> void:
	_refresh_header()
	_rebuild_fish_cards()


func _refresh_header() -> void:
	_level_label.text = "プレイヤー Lv.%d" % PlayerProgress.level
	_money_label.text = "%d G" % PlayerProgress.money
	if PlayerProgress.level >= GameData.MAX_LEVEL:
		_exp_bar.max_value = 1.0
		_exp_bar.set_value(1.0)
		_exp_label.text = "MAX"
	else:
		var next := PlayerProgress.exp_to_next_level()
		_exp_bar.max_value = maxf(1.0, float(next))
		_exp_bar.set_value(float(PlayerProgress.exp))
		_exp_label.text = "%d / %d" % [PlayerProgress.exp, next]


func _rebuild_fish_cards() -> void:
	_clear_container(_fish_box)
	_fish_cards.clear()
	var first_id := ""
	for fish_id in _fish_display_ids():
		var count := PlayerProgress.fish_count(fish_id)
		if count > 0 and first_id.is_empty():
			first_id = fish_id
		_fish_box.add_child(_make_fish_card(fish_id, count))
	if first_id.is_empty():
		_selected_fish_id = ""
		_selected_recipe_id = ""
		_rebuild_recipe_cards()
		_refresh_detail()
		return
	if _selected_fish_id.is_empty() or PlayerProgress.fish_count(_selected_fish_id) <= 0:
		_selected_fish_id = first_id
	_rebuild_recipe_cards()
	_refresh_fish_card_styles()


func _fish_display_ids() -> Array[String]:
	var ids: Array[String] = []
	for fish_id in GameData.get_all_fish_ids():
		var fish_key := String(fish_id)
		if PlayerProgress.fish_count(fish_key) > 0:
			ids.append(fish_key)
	if not ids.has("boss_kurodai"):
		ids.append("boss_kurodai")
	for fish_id in GameData.get_all_fish_ids():
		var fish_key := String(fish_id)
		if ids.has(fish_key):
			continue
		if ids.size() < 5:
			ids.append(fish_key)
		if ids.size() >= 5:
			break
	return ids


func _make_fish_card(fish_id: String, count: int) -> PanelContainer:
	var fish := GameData.get_fish(fish_id)
	var owned := count > 0
	var card := PanelContainer.new()
	card.name = _fish_row_node_name(fish_id)
	card.custom_minimum_size = Vector2(0, 68)
	card.mouse_filter = Control.MOUSE_FILTER_STOP if owned else Control.MOUSE_FILTER_IGNORE
	if owned:
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		card.gui_input.connect(
			func(event: InputEvent) -> void:
				if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					_select_fish(fish_id)
		)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	card.add_child(row)
	var marker := make_shadow_label("", 20, Palette.GOLD_BRIGHT, 2)
	marker.custom_minimum_size = Vector2(18, 0)
	marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(marker)
	var icon := TextureRect.new()
	icon.texture = _fish_icon(fish_id)
	icon.custom_minimum_size = Vector2(96, 50)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = Color(1.18, 1.12, 1.04, 1.0) if owned else Color(0.38, 0.36, 0.31, 0.76)
	row.add_child(icon)
	var display_name := _fish_row_display_name(fish_id, String(fish.get("name", fish_id)))
	var name_font_size := 18 if display_name.length() <= 4 else 17
	var name := make_label(display_name, name_font_size, Color("#241b12"), 1, Color("#fff2ca"))
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name.autowrap_mode = TextServer.AUTOWRAP_OFF
	name.clip_text = true
	row.add_child(name)
	var amount_text := "× %d" % count if owned else "未所持"
	var amount := make_label(amount_text, 18 if owned else 13, Color("#241b12"), 1, Color("#fff2ca"))
	amount.custom_minimum_size = Vector2(50.0, 0.0)
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(amount)
	_fish_cards[fish_id] = {"card": card, "marker": marker, "owned": owned}
	return card


func _fish_row_display_name(fish_id: String, fallback: String) -> String:
	if fish_id == "boss_kurodai":
		return "港のぬし"
	return fallback


func _fish_row_node_name(fish_id: String) -> String:
	match fish_id:
		"aji":
			return "FishRowAji"
		"saba":
			return "FishRowSaba"
		"tai":
			return "FishRowTai"
		"kasago":
			return "FishRowKasago"
		"ika":
			return "FishRowIka"
		"hirame":
			return "FishRowHirame"
		"mejina":
			return "FishRowMejina"
		"isaki":
			return "FishRowIsaki"
		"boss_kurodai":
			return "FishRowBossKurodai"
		_:
			return "FishRow"


func _select_fish(fish_id: String) -> void:
	if _selected_fish_id == fish_id:
		return
	_selected_fish_id = fish_id
	_selected_recipe_id = ""
	_rebuild_recipe_cards()
	_refresh_fish_card_styles()
	_show_status_summary()


func _refresh_fish_card_styles() -> void:
	for fish_id in _fish_cards.keys():
		var selected := String(fish_id) == _selected_fish_id
		var entry := Dictionary(_fish_cards[fish_id])
		var card := entry.get("card") as PanelContainer
		var marker := entry.get("marker") as Label
		var owned := bool(entry.get("owned", true))
		if card == null:
			continue
		card.self_modulate = Color("#fff1bc") if selected else Color("#f3dfb9" if owned else "#8f846c")
		card.add_theme_stylebox_override(
			"panel",
			_texture_style_box(
				FISH_ROW_FRAME,
				24,
				_style_box(
					Color("#ffefbd") if selected else Color("#ead9b4" if owned else "#9a8f76"),
					Color("#f4c96e") if selected else Color("#6a421f" if owned else "#4d3e2c"),
					Color("#ffffff") if selected else Color("#c29250" if owned else "#756349"),
					4,
					6
				),
				10.0,
				6.0
			)
		)
		if marker != null:
			marker.text = ">" if selected else ""


func _rebuild_recipe_cards() -> void:
	_clear_container(_recipe_grid)
	_recipe_cards.clear()
	if _selected_fish_id.is_empty():
		return
	var entries := _recipe_entries_for_fish(_selected_fish_id)
	var first_available := ""
	var selected_available := false
	for entry in entries:
		var recipe := Dictionary(entry.get("recipe", {}))
		var recipe_id := String(recipe.get("id", ""))
		var locked := bool(entry.get("locked", false))
		var unavailable := bool(entry.get("unavailable", false))
		if first_available.is_empty() and not locked and not unavailable:
			first_available = recipe_id
		if recipe_id == _selected_recipe_id and not locked and not unavailable:
			selected_available = true
		_recipe_grid.add_child(_make_recipe_card(recipe, locked, unavailable))
	for _i in range(maxi(0, 6 - entries.size())):
		_recipe_grid.add_child(_make_recipe_book_card())
	if _selected_recipe_id.is_empty() or not selected_available:
		_selected_recipe_id = first_available
	_refresh_recipe_card_styles()
	_refresh_detail()


func _recipe_entries_for_fish(fish_id: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for recipe_id_variant in GameData.RECIPES.keys():
		var recipe_id := String(recipe_id_variant)
		var recipe := GameData.get_recipe(recipe_id)
		var allowed = recipe.get("allowed_fish", [])
		entries.append(
			{
				"recipe": recipe,
				"locked": PlayerProgress.level < int(recipe.get("unlock_level", 1)),
				"unavailable": fish_id not in allowed,
			}
		)
	entries.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return int(Dictionary(a.get("recipe", {})).get("unlock_level", 1)) < int(Dictionary(b.get("recipe", {})).get("unlock_level", 1))
	)
	return entries


func _make_recipe_card(recipe: Dictionary, locked: bool, unavailable: bool) -> PanelContainer:
	var recipe_id := String(recipe.get("id", ""))
	var card := PanelContainer.new()
	card.name = "RecipeCard_%s" % recipe_id
	card.custom_minimum_size = Vector2(134, 146)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var selectable := not locked and not unavailable
	if selectable:
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		card.gui_input.connect(
			func(event: InputEvent) -> void:
				if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					_select_recipe(recipe_id)
		)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	card.add_child(box)
	var title_text := "？？？" if locked else String(recipe.get("name", ""))
	var title := make_label(title_text, 16, Color("#251c12"), 1, Color("#fff3cf"))
	title.custom_minimum_size = Vector2(0.0, 20.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.clip_text = true
	box.add_child(title)
	var image := TextureRect.new()
	image.texture = _recipe_icon(recipe_id if not locked else "locked")
	image.custom_minimum_size = Vector2(0, 70)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.modulate = Color(0.46, 0.42, 0.36, 0.82) if locked or unavailable else Color.WHITE
	box.add_child(image)
	var stars := make_shadow_label(
		_recipe_star_text(recipe, locked),
		13,
		Palette.GOLD_BRIGHT if not locked else Color("#d0c2a3"),
		2,
		Color("#4c2b0b")
	)
	stars.custom_minimum_size = Vector2(0.0, 17.0)
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(stars)
	var material_text := _recipe_material_chip(recipe, locked, unavailable)
	var material := make_label(material_text, 12, Color("#49351f"), 1, Color("#fff4cf"))
	material.custom_minimum_size = Vector2(0.0, 16.0)
	material.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	material.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	material.clip_text = true
	box.add_child(material)
	var footer_text := ""
	if locked:
		footer_text = "未解放 Lv.%d" % int(recipe.get("unlock_level", 1))
	elif unavailable:
		footer_text = "素材違い"
	else:
		var dish_key := "%s:%s" % [_selected_fish_id, recipe_id]
		var first_time := not PlayerProgress.eaten_recipes.has(dish_key)
		var base_exp := GameData.recipe_exp(_selected_fish_id, recipe_id)
		var total_exp := base_exp * 2 if first_time else base_exp
		footer_text = "%d EXP%s" % [total_exp, " 初回" if first_time else ""]
	var footer := make_label(footer_text, 13, Color("#49351f"), 1, Color("#fff4cf"))
	footer.custom_minimum_size = Vector2(0.0, 17.0)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.clip_text = true
	box.add_child(footer)
	_recipe_cards[recipe_id] = {
		"card": card,
		"locked": locked,
		"unavailable": unavailable,
		"footer": footer,
		"footer_text": footer_text,
	}
	return card


func _make_recipe_book_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "RecipeCard_Book"
	card.custom_minimum_size = Vector2(134, 146)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.self_modulate = Color(0.72, 0.66, 0.54, 1.0)
	card.add_theme_stylebox_override(
		"panel",
		_texture_style_box(
			RECIPE_CARD_FRAME,
			28,
			_style_box(Color("#b7a884"), Color("#7b5027"), Color("#c59a59"), 4, 6),
			12.0,
			8.0
		)
	)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	card.add_child(box)
	var title := make_label("料理図鑑", 16, Color("#251c12"), 1, Color("#fff3cf"))
	title.custom_minimum_size = Vector2(0.0, 20.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.clip_text = true
	box.add_child(title)
	var image := TextureRect.new()
	image.texture = _recipe_icon("locked")
	image.custom_minimum_size = Vector2(0, 70)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.modulate = Color(0.62, 0.58, 0.50, 0.88)
	box.add_child(image)
	var stars := make_shadow_label("☆☆☆", 13, Color("#d0c2a3"), 2, Color("#4c2b0b"))
	stars.custom_minimum_size = Vector2(0.0, 17.0)
	stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(stars)
	var material := make_label("新しい献立", 12, Color("#49351f"), 1, Color("#fff4cf"))
	material.custom_minimum_size = Vector2(0.0, 16.0)
	material.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	material.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	material.clip_text = true
	box.add_child(material)
	var footer := make_label("準備中", 13, Color("#49351f"), 1, Color("#fff4cf"))
	footer.custom_minimum_size = Vector2(0.0, 17.0)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.clip_text = true
	box.add_child(footer)
	return card


func _recipe_star_text(recipe: Dictionary, locked: bool) -> String:
	if locked:
		return "☆☆☆"
	var multiplier := float(recipe.get("exp_multiplier", 1.0))
	var stars := 2
	if multiplier >= 1.3:
		stars = 3
	return "★★★" if stars >= 3 else "★★"


func _recipe_material_chip(recipe: Dictionary, locked: bool, unavailable: bool) -> String:
	if locked:
		return "素材 ？？？"
	if unavailable:
		var allowed = recipe.get("allowed_fish", [])
		if allowed is Array and not allowed.is_empty():
			var fish := GameData.get_fish(String(allowed[0]))
			return "素材 %s" % String(fish.get("name", "魚"))
		return "素材違い"
	var fish := GameData.get_fish(_selected_fish_id)
	return "素材 %s" % String(fish.get("name", "魚"))


func _select_recipe(recipe_id: String) -> void:
	if _selected_recipe_id == recipe_id:
		return
	_selected_recipe_id = recipe_id
	_refresh_recipe_card_styles()
	_refresh_detail()
	_show_status_summary()


func _refresh_recipe_card_styles() -> void:
	for recipe_id in _recipe_cards.keys():
		var entry := Dictionary(_recipe_cards[recipe_id])
		var card := entry.get("card") as PanelContainer
		var footer := entry.get("footer") as Label
		var locked := bool(entry.get("locked", false))
		var unavailable := bool(entry.get("unavailable", false))
		var selected := String(recipe_id) == _selected_recipe_id
		if card == null:
			continue
		var fill := Color("#ffedbb") if selected else Color("#ead7ad")
		if locked:
			fill = Color("#8c8069")
		elif unavailable:
			fill = Color("#b7a884")
		var border := Color("#f2c86d") if selected else Color("#7b5027")
		var inner := Color("#fff6d4") if selected else Color("#c59a59")
		var tint := Color.WHITE
		if selected:
			tint = Color("#fff1ba")
		elif locked or unavailable:
			tint = Color(0.55, 0.50, 0.42, 1.0)
		card.self_modulate = tint
		card.add_theme_stylebox_override(
			"panel",
			_texture_style_box(
				RECIPE_SELECTED_CARD_FRAME if selected and not locked and not unavailable else RECIPE_CARD_FRAME,
				28,
				_style_box(
					fill,
					border,
					inner,
					4,
					6
				),
				12.0,
				8.0
			)
		)
		if footer != null:
			var base_footer := String(entry.get("footer_text", ""))
			var selected_footer := "選択中 %s" % base_footer.replace(" EXP", "EXP").replace(" 初回", "")
			footer.text = selected_footer if selected and not locked and not unavailable else base_footer


func _refresh_detail() -> void:
	var fish := GameData.get_fish(_selected_fish_id)
	var recipe := GameData.get_recipe(_selected_recipe_id)
	if fish.is_empty() or recipe.is_empty():
		_dish_title.text = "魚と料理を選んでください"
		_dish_subtitle.text = "クーラーボックスに魚がいない場合は、先に釣り場へ向かいましょう。"
		_dish_image.texture = null
		_material_value.text = "-"
		_stock_value.text = "-"
		_exp_value.text = "-"
		_bonus_value.text = "-"
		_buff_value.text = "-"
		_effect_count_value.text = "-"
		_overwrite_note.text = ""
		_cook_action_cue.visible = false
		_cook_action_cue.set_available(false)
		_cook_button.disabled = true
		_cook_button.queue_redraw()
		return
	var base_exp := GameData.recipe_exp(_selected_fish_id, _selected_recipe_id)
	var dish_key := "%s:%s" % [_selected_fish_id, _selected_recipe_id]
	var first_time := not PlayerProgress.eaten_recipes.has(dish_key)
	var total_exp := base_exp * 2 if first_time else base_exp
	var count := PlayerProgress.fish_count(_selected_fish_id)
	_dish_title.text = "%sの%s" % [String(fish["name"]), String(recipe["name"])]
	_dish_subtitle.text = String(recipe.get("description", ""))
	_dish_image.texture = _featured_dish_texture(_selected_recipe_id)
	_material_value.text = "%s ×1" % String(fish["name"])
	_stock_value.text = "所持 %d → %d" % [count, maxi(0, count - 1)]
	_exp_value.text = "+%d EXP" % total_exp
	_bonus_value.text = "初回 +%d EXP" % base_exp if first_time else "初回済"
	_buff_value.text = String(recipe.get("buff_text", ""))
	_effect_count_value.text = "1回"
	_overwrite_note.text = "調理後は食事結果へ / 既存効果を上書き。"
	_cook_action_cue.visible = true
	_cook_action_cue.set_available(count > 0)
	_cook_button.disabled = count <= 0
	_cook_button.queue_redraw()


func _apply_cook_button_style() -> void:
	var normal_fallback := _style_box(Color("#103a5f"), Color("#3b2515"), Palette.GOLD_BRIGHT, 4, 6)
	var hover_fallback := _style_box(Color("#19517d"), Color("#3b2515"), Color("#ffe67a"), 4, 6)
	var pressed_fallback := _style_box(Color("#0c2946"), Color("#2a1a10"), Palette.GOLD_DEEP, 4, 6)
	var disabled_fallback := _style_box(Color("#5f5142"), Color("#3b3027"), Color("#8f7b5e"), 4, 6)
	_cook_button.add_theme_stylebox_override(
		"normal",
		_texture_style_box(COOK_BUTTON_FRAME, 22, normal_fallback, 58.0, 8.0)
	)
	_cook_button.add_theme_stylebox_override(
		"hover",
		_texture_style_box(COOK_BUTTON_FRAME, 22, hover_fallback, 58.0, 8.0)
	)
	_cook_button.add_theme_stylebox_override(
		"pressed",
		_texture_style_box(COOK_BUTTON_FRAME, 22, pressed_fallback, 58.0, 8.0)
	)
	_cook_button.add_theme_stylebox_override(
		"disabled",
		_texture_style_box(COOK_BUTTON_FRAME, 22, disabled_fallback, 58.0, 8.0)
	)
	_cook_button.add_theme_stylebox_override(
		"focus",
		_texture_style_box(COOK_BUTTON_FRAME, 22, hover_fallback, 58.0, 8.0)
	)
	_cook_button.add_theme_color_override("font_color", Palette.GOLD_BRIGHT)
	_cook_button.add_theme_color_override("font_hover_color", Color("#fff1ba"))
	_cook_button.add_theme_color_override("font_pressed_color", Color("#f0c06b"))
	_cook_button.add_theme_color_override("font_disabled_color", Color("#b6a68d"))


func _draw_cook_button_icon(button: Button) -> void:
	var active := not button.disabled
	var center := Vector2(34.0, button.size.y * 0.5 + 1.0)
	var ink := Color("#3b2515") if active else Color("#665847")
	var pot := Color("#9b5a29") if active else Color("#7a6954")
	var flame := Color("#f06a2e") if active else Color("#7a604b")
	var glow := Color(1.0, 0.86, 0.36, 0.42) if active else Color(0.48, 0.40, 0.32, 0.22)
	button.draw_circle(center + Vector2(4.0, 5.0), 24.0, glow)
	button.draw_rect(Rect2(center.x - 15.0, center.y - 4.0, 30.0, 15.0), ink)
	button.draw_rect(Rect2(center.x - 12.0, center.y - 1.0, 24.0, 11.0), pot)
	button.draw_line(center + Vector2(-17.0, -6.0), center + Vector2(17.0, -6.0), ink, 4.0)
	button.draw_arc(center + Vector2(0.0, -11.0), 10.0, PI, TAU, 12, ink, 2.0)
	button.draw_colored_polygon(
		PackedVector2Array(
			[
				center + Vector2(-6.0, 18.0),
				center + Vector2(0.0, 7.0),
				center + Vector2(6.0, 18.0),
				center + Vector2(1.0, 23.0),
			]
		),
		flame
	)
	button.draw_colored_polygon(
		PackedVector2Array(
			[
				center + Vector2(2.0, 16.0),
				center + Vector2(7.0, 7.0),
				center + Vector2(12.0, 17.0),
				center + Vector2(7.0, 22.0),
			]
		),
		Color("#ffe67a") if active else Color("#96805d")
	)
	for i in range(2):
		var x := center.x - 6.0 + float(i) * 12.0
		button.draw_arc(Vector2(x, center.y - 18.0), 8.0, -1.6, 0.9, 9, glow, 2.0)
	var arrow_x := center.x + 36.0
	var arrow_color := Color("#ffe67a") if active else Color("#8b7654")
	button.draw_line(Vector2(arrow_x, center.y), Vector2(arrow_x + 22.0, center.y), arrow_color, 3.0)
	button.draw_colored_polygon(
		PackedVector2Array(
			[
				Vector2(arrow_x + 28.0, center.y),
				Vector2(arrow_x + 16.0, center.y - 7.0),
				Vector2(arrow_x + 16.0, center.y + 7.0),
			]
		),
		arrow_color
	)


func _cook_selected() -> void:
	if _selected_fish_id.is_empty() or _selected_recipe_id.is_empty():
		return
	var level_before := PlayerProgress.level
	var stats_before := PlayerProgress.get_base_stats()
	var exp_before := PlayerProgress.exp
	var exp_max_before := PlayerProgress.exp_to_next_level()
	var result := PlayerProgress.cook_and_eat(_selected_fish_id, _selected_recipe_id)
	if not bool(result.get("ok", false)):
		_show_error_result(String(result.get("message", "調理できませんでした。")))
		return

	var leveled_to: Array = result.get("leveled_to", [])
	_refresh_all()
	var leveled := not leveled_to.is_empty()
	var reward_exp_after := exp_max_before if leveled else PlayerProgress.exp
	var meal_status_snapshot := _meal_status_snapshot(level_before, exp_before, exp_max_before)
	_show_meal_result(result, leveled)
	_show_reward_overlay(
		result,
		exp_before,
		reward_exp_after,
		exp_max_before,
		level_before,
		stats_before,
		leveled,
		meal_status_snapshot
	)
	Juicer.add_trauma(0.16)


func preview_cook_selected() -> void:
	_cook_selected()


func preview_show_meal_result(result: Dictionary, leveled: bool) -> void:
	_refresh_header()
	_refresh_detail()
	_show_meal_result(result, leveled)


func preview_show_reward_result(result: Dictionary, exp_before: int, exp_after: int, exp_max: int, leveled: bool) -> void:
	_refresh_header()
	_refresh_detail()
	_show_meal_result(result, leveled)
	var level_before := maxi(1, PlayerProgress.level - 1)
	var stats_before := _preview_base_stats_for_level(level_before) if leveled else {}
	_show_exp_reward_overlay(result, exp_before, exp_after, exp_max, level_before, stats_before, leveled)


func preview_show_meal_reward_result(result: Dictionary, leveled: bool) -> void:
	_refresh_header()
	_refresh_detail()
	_show_meal_result(result, leveled)
	var panel := CookingRewardPanelScript.new()
	add_child(panel)
	panel.show_meal_result(result)


func _preview_base_stats_for_level(level_value: int) -> Dictionary:
	var current_level := PlayerProgress.level
	PlayerProgress.level = clampi(level_value, 1, GameData.MAX_LEVEL)
	var stats := PlayerProgress.get_base_stats().duplicate(true)
	PlayerProgress.level = current_level
	return stats


func preview_accept_reward_overlay() -> bool:
	for child in get_children():
		if child.get_script() == CookingRewardPanelScript:
			child.preview_accept()
			return true
	return false


func preview_has_reward_overlay_state(expected_state: String) -> bool:
	for child in get_children():
		if child.get_script() == CookingRewardPanelScript:
			return child.preview_state() == expected_state
	return false


func preview_has_level_up_overlay() -> bool:
	for child in get_children():
		if child.get_script() == LevelUpPanelScript:
			return true
	return false


func preview_accept_level_up_overlay() -> bool:
	for child in get_children():
		if child.get_script() == LevelUpPanelScript:
			child.preview_accept()
			return true
	return false


func preview_has_status_overlay() -> bool:
	for child in get_children():
		if child.get_script() == CookingStatusPanelScript:
			return true
	return false


func preview_accept_status_overlay() -> bool:
	for child in get_children():
		if child.get_script() == CookingStatusPanelScript:
			child.preview_accept()
			return true
	return false


func preview_has_current_prep_summary() -> bool:
	return _result_title != null and _result_title.text == "現在の準備"


func preview_show_status_overlay() -> void:
	_refresh_header()
	_refresh_detail()
	_show_status_summary()
	_show_status_overlay()


func _show_error_result(message: String) -> void:
	_flow_state = FlowState.MEAL_RESULT
	_set_result_summary_compact(false)
	_result_title.text = "調理できませんでした"
	_clear_container(_result_body)
	_result_body.add_child(_summary_card("確認", message, Palette.GAUGE_RED_HI))


func _show_status_summary() -> void:
	if _flow_state != FlowState.COOK_SELECT:
		_flow_state = FlowState.COOK_SELECT
	_set_result_summary_compact(false)
	_result_title.text = "現在の準備"
	_clear_container(_result_body)
	_result_body.add_child(
		_prep_summary_card(
			"プレイヤーLv.",
			"Lv.%d  %d/%d" % [
				PlayerProgress.level,
				PlayerProgress.exp,
				PlayerProgress.exp_to_next_level(),
			],
			Palette.GOLD_BRIGHT,
			"player"
		)
	)
	_result_body.add_child(
		_prep_summary_card("効果中の料理", _current_meal_summary_text(), Palette.GAUGE_GREEN_HI, "meal")
	)
	_result_body.add_child(
		_prep_summary_card("クーラーボックス", "%d / 20" % _total_fish_count(), Palette.GAUGE_CYAN_HI, "cooler")
	)
	_result_body.add_child(
		_prep_summary_card("所持金", "%d G" % PlayerProgress.money, Palette.GOLD_BRIGHT, "coin")
	)


func _show_status_overlay() -> void:
	var panel := CookingStatusPanelScript.new()
	add_child(panel)
	panel.closed.connect(func() -> void: navigate("harbor"))
	panel.show_summary()


func _current_meal_summary_text() -> String:
	var buff := PlayerProgress.pending_buff
	if buff.is_empty():
		return "なし"
	var name := String(buff.get("name", "料理効果"))
	return "%s / 1回" % name


func _show_meal_result(result: Dictionary, leveled: bool) -> void:
	_flow_state = FlowState.MEAL_RESULT if not leveled else FlowState.EXP_GAIN
	_set_result_summary_compact(false)
	_result_title.text = "%sを食べた！" % String(result.get("dish_name", "料理"))
	_clear_container(_result_body)
	_result_body.add_child(
		_summary_card("食経験値", "+%d EXP" % int(result.get("total_exp", 0)), Palette.GAUGE_CYAN_HI, "book")
	)
	var first_text := "+%d EXP" % int(result.get("first_bonus", 0)) if bool(result.get("first_time", false)) else "記録済み"
	_result_body.add_child(_summary_card("初回ボーナス", first_text, Palette.GOLD_BRIGHT, "book"))
	var buff := Dictionary(result.get("buff", {}))
	_result_body.add_child(
		_summary_card(
			"次の釣行",
			"%s / 1回の釣行で発動" % String(buff.get("text", "")),
			Palette.GAUGE_GREEN_HI,
			"meal"
		)
	)
	var remaining_exp := maxi(0, PlayerProgress.exp_to_next_level() - PlayerProgress.exp)
	_result_body.add_child(
		_summary_card(
			"成長",
			"LEVEL UP!" if leveled else "次のレベルまで %d" % remaining_exp,
			Palette.GAUGE_RED_HI if leveled else Palette.TEXT_BONE,
			"player"
		)
	)


func _show_reward_overlay(
	result: Dictionary,
	exp_before: int,
	exp_after: int,
	exp_max: int,
	level_before: int,
	stats_before: Dictionary,
	leveled: bool,
	meal_status_snapshot := {}
) -> void:
	var panel := CookingRewardPanelScript.new()
	add_child(panel)
	panel.show_meal_result(_with_meal_status_snapshot(result, meal_status_snapshot))
	panel.closed.connect(
		func() -> void:
			_show_exp_reward_overlay(
				result,
				exp_before,
				exp_after,
				exp_max,
				level_before,
				stats_before,
				leveled
			)
	)


func _meal_status_snapshot(level_before: int, exp_before: int, exp_max_before: int) -> Dictionary:
	return {
		"level": level_before,
		"exp": exp_before,
		"exp_max": exp_max_before,
		"fish_total": _total_fish_count(),
		"money": PlayerProgress.money,
	}


func _with_meal_status_snapshot(result: Dictionary, meal_status_snapshot: Dictionary) -> Dictionary:
	if meal_status_snapshot.is_empty() or result.has("status_snapshot"):
		return result
	var display_result := result.duplicate(true)
	display_result["status_snapshot"] = meal_status_snapshot.duplicate(true)
	return display_result


func _show_exp_reward_overlay(
	result: Dictionary,
	exp_before: int,
	exp_after: int,
	exp_max: int,
	level_before: int,
	stats_before: Dictionary,
	leveled: bool
) -> void:
	var panel := CookingRewardPanelScript.new()
	add_child(panel)
	panel.show_reward(result, exp_before, exp_after, exp_max, leveled, level_before, PlayerProgress.level)
	if leveled and not _preview_suppress_level_overlay:
		_pending_level_up = {
			"level_from": level_before,
			"level_to": PlayerProgress.level,
			"old_stats": stats_before,
			"new_stats": PlayerProgress.get_base_stats(),
		}
		panel.closed.connect(_show_pending_level_up)
	else:
		_pending_level_up = {}
		panel.closed.connect(_show_post_reward_select_summary)


func _show_pending_level_up() -> void:
	if _pending_level_up.is_empty():
		return
	var payload := _pending_level_up.duplicate(true)
	_pending_level_up = {}
	_show_post_reward_select_summary()
	_show_level_up(
		int(payload.get("level_from", PlayerProgress.level)),
		int(payload.get("level_to", PlayerProgress.level)),
		Dictionary(payload.get("old_stats", {})),
		Dictionary(payload.get("new_stats", {}))
	)


func _show_post_reward_select_summary() -> void:
	_refresh_header()
	_refresh_detail()
	_show_status_summary()


func _small_icon(mode: String, accent: Color, minimum_size: Vector2) -> CookingSmallIcon:
	var icon := CookingSmallIcon.new()
	icon.configure(mode, accent)
	icon.custom_minimum_size = minimum_size
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func _header_player_icon() -> TextureRect:
	var icon := TextureRect.new()
	icon.name = "CookingHeaderPlayerPortrait"
	icon.texture = load(PLAYER_HEADER_PORTRAIT) as Texture2D
	icon.custom_minimum_size = Vector2(54.0, 0.0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func _section_ribbon(text: String, icon_mode: String, node_name: String) -> PanelContainer:
	var ribbon := _texture_panel_box(
		COOKING_SECTION_RIBBON,
		28,
		_style_box(Color("#143553"), Color("#3b2515"), Palette.GOLD_DEEP, 4, 5),
		18.0,
		5.0
	)
	ribbon.name = node_name
	ribbon.custom_minimum_size = Vector2(0.0, 42.0)
	ribbon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	ribbon.add_child(row)
	row.add_child(_small_icon(icon_mode, Palette.GOLD_BRIGHT, Vector2(28.0, 0.0)))
	var label := make_shadow_label(text, 22, Palette.GOLD_BRIGHT, 3)
	label.custom_minimum_size = Vector2(170.0 if text.length() >= 7 else 126.0, 0.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	row.add_child(label)
	row.add_child(_small_icon(icon_mode, Palette.GOLD_BRIGHT, Vector2(28.0, 0.0)))
	return ribbon


func _summary_card(title: String, value: String, accent: Color, icon_mode := "book") -> PanelContainer:
	var card := _panel_box(Color("#f2e4c2"), Color("#60401f"), Color("#d7a456"), 5)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 42)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	card.add_child(row)
	row.add_child(_small_icon(icon_mode, accent, Vector2(30.0, 0.0)))
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 0)
	row.add_child(box)
	var title_label := make_label(title, 13, Color("#614525"))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title_label)
	var value_label := make_label(value, 14, accent, 1, Color("#1d160f"))
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(value_label)
	return card


func _prep_summary_card(title: String, value: String, accent: Color, icon_mode := "book") -> PanelContainer:
	var card := _panel_box(Color("#0d2338"), Color("#60401f"), Color("#d7a456"), 4)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 48)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)
	row.add_child(_small_icon(icon_mode, accent, Vector2(38.0, 0.0)))
	var title_label := make_shadow_label(title, 12, Palette.TEXT_BONE, 2)
	title_label.custom_minimum_size = Vector2(104.0, 0.0)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_label.clip_text = true
	row.add_child(title_label)
	var value_label := make_shadow_label(value, 14, accent, 2)
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	value_label.clip_text = true
	row.add_child(value_label)
	return card


func _set_result_summary_compact(compact: bool) -> void:
	if _result_panel != null:
		_result_panel.custom_minimum_size = Vector2(0, 58 if compact else 112)
	if _result_body != null:
		_result_body.visible = not compact


func _show_level_up(
	level_from: int, level_to: int, old_stats: Dictionary, new_stats: Dictionary
) -> void:
	var panel := LevelUpPanelScript.new()
	add_child(panel)
	panel.show_level_up(level_from, level_to, old_stats, new_stats)
	panel.closed.connect(_show_post_level_status_summary)


func _show_post_level_status_summary() -> void:
	_refresh_header()
	_refresh_detail()
	_show_status_summary()
	_show_status_overlay()


func _total_fish_count() -> int:
	var total := 0
	for fish_id in GameData.get_all_fish_ids():
		total += PlayerProgress.fish_count(fish_id)
	return total


func _clear_container(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _panel_box(fill: Color, border: Color, inner: Color, border_width: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style_box(fill, border, inner, border_width, 5))
	return panel


func _texture_panel_box(
	path: String, margin: int, fallback: StyleBox, content_x: float, content_y: float
) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel", _texture_style_box(path, margin, fallback, content_x, content_y)
	)
	return panel


func _style_box(fill: Color, border: Color, inner: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border.lerp(inner, 0.18)
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 12.0
	sb.content_margin_top = 8.0
	sb.content_margin_right = 12.0
	sb.content_margin_bottom = 8.0
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0.0, 2.0)
	sb.anti_aliasing = false
	return sb


func _texture_style_box(
	path: String, margin: int, fallback: StyleBox, content_x: float, content_y: float
) -> StyleBox:
	var tex := load(path) as Texture2D
	if tex == null:
		return fallback
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = margin
	sb.texture_margin_top = margin
	sb.texture_margin_right = margin
	sb.texture_margin_bottom = margin
	sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	sb.expand_margin_left = 6.0
	sb.expand_margin_top = 6.0
	sb.expand_margin_right = 6.0
	sb.expand_margin_bottom = 6.0
	sb.content_margin_left = content_x
	sb.content_margin_top = content_y
	sb.content_margin_right = content_x
	sb.content_margin_bottom = content_y
	return sb


func _atlas(path: String, index: int, columns: int, rows: int) -> Texture2D:
	var tex := load(path) as Texture2D
	if tex == null:
		return null
	var cell_w := float(tex.get_width()) / float(columns)
	var cell_h := float(tex.get_height()) / float(rows)
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	var row := int(index / columns)
	atlas.region = Rect2(
		float(index % columns) * cell_w,
		float(row) * cell_h,
		cell_w,
		cell_h
	)
	return atlas


func _fish_icon(fish_id: String) -> Texture2D:
	return _atlas(FISH_ICON_SHEET, int(FISH_ICON_INDEX.get(fish_id, 0)), 1, 6)


func _recipe_icon(recipe_id: String) -> Texture2D:
	var idx := 5 if recipe_id == "locked" else int(RECIPE_ICON_INDEX.get(recipe_id, 0))
	return _atlas(DISH_ICON_SHEET, idx, 3, 2)


func _featured_dish_texture(recipe_id: String) -> Texture2D:
	match recipe_id:
		"salt_grill":
			return load(DISH_FEATURE_AJI) as Texture2D
		"sashimi":
			return load(DISH_FEATURE_SASHIMI) as Texture2D
		"simmered":
			return load(DISH_FEATURE_SIMMERED) as Texture2D
		"soup":
			return load(DISH_FEATURE_SOUP) as Texture2D
		"fry":
			return load(DISH_FEATURE_FRY) as Texture2D
	return _recipe_icon(recipe_id)
