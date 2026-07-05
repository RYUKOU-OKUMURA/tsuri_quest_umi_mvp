extends ScreenBase

const GaugeBarScript = preload("res://src/ui/components/gauge_bar.gd")
const LevelUpPanelScript = preload("res://src/ui/components/level_up_panel.gd")
const CookingRewardPanelScript = preload("res://src/ui/components/cooking_reward_panel.gd")
const CookingStatusPanelScript = preload("res://src/ui/components/cooking_status_panel.gd")
const PlayerStatusBarScript = preload("res://src/ui/components/player_status_bar.gd")
const FightFishAssets = preload("res://src/ui/fight_fish_assets.gd")

const COOKING_TITLE_BANNER := "res://assets/showcase/cooking/cooking_title_banner.png"
const COOKING_SECTION_RIBBON := "res://assets/showcase/cooking/cooking_section_ribbon.png"
const FISH_ICON_SHEET := "res://assets/showcase/cooking/fish_icon_sheet.png"
const RECIPE_GRID_FRAME := "res://assets/showcase/cooking/recipe_grid_frame.png"
const RECIPE_CARD_FRAME := "res://assets/showcase/cooking/recipe_card_frame.png"
const RECIPE_SELECTED_CARD_FRAME := "res://assets/showcase/cooking/recipe_selected_card_frame.png"
const RECIPE_DISH_THUMB_FRAME := "res://assets/showcase/cooking/recipe_dish_thumb_frame.png"
const RECIPE_MATERIAL_STRIP_FRAME := "res://assets/showcase/cooking/recipe_material_strip_frame.png"
const RECIPE_TO_DETAIL_ARROW := "res://assets/showcase/cooking/recipe_to_detail_arrow.png"
const DISH_DETAIL_FRAME := "res://assets/showcase/cooking/dish_detail_frame.png"
const COOK_DETAIL_ROW_FRAME := "res://assets/showcase/cooking/cook_detail_row_frame.png"
const COOK_BUTTON_FRAME := "res://assets/showcase/cooking/cook_button_frame.png"
const COOK_ACTION_RUNWAY_FRAME := "res://assets/showcase/cooking/cook_action_runway_frame.png"
const PREP_SUMMARY_BAR_FRAME := "res://assets/showcase/cooking/prep_summary_bar_frame.png"
const PREP_SUMMARY_CARD_FRAME := "res://assets/showcase/cooking/prep_summary_card_frame.png"
const FISH_ROW_FRAME := "res://assets/showcase/cooking/fish_row_frame.png"
const COOKING_FISH_DISPLAY_ORDER := [
	"aji",
	"saba",
	"madai",
	"kasago",
	"hirame",
	"kawahagi",
	"mejina",
	"isaki",
	"suzuki",
	"boss_kurodai",
]
const COOKING_FISH_MIN_VISIBLE_ROWS := 6
const FISH_ROW_ICON_MIN_WIDTH := 120.0
const FISH_ROW_NAME_MIN_WIDTH := 48.0
const FISH_ROW_AMOUNT_WIDTH := 58.0


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
			"player_mini":
				_draw_player_mini()
			"meal_mini":
				_draw_meal_mini()
			"fish_mini":
				_draw_fish_mini()
			"coin_mini":
				_draw_coin_mini()
			_:
				_draw_player()

	func _draw_player() -> void:
		var center := size * 0.5
		draw_circle(center + Vector2(0.0, -7.0), 15.0, Color("#f2b889"))
		draw_rect(Rect2(center.x - 18.0, center.y + 8.0, 36.0, 22.0), Color("#17324d"))
		draw_rect(Rect2(center.x - 18.0, center.y - 24.0, 36.0, 9.0), Color("#234f7c"))
		draw_circle(center + Vector2(-6.0, -8.0), 2.0, Color("#1d160f"))
		draw_circle(center + Vector2(6.0, -8.0), 2.0, Color("#1d160f"))

	func _draw_player_mini() -> void:
		var center := size * 0.5
		var scale_value: float = minf(size.x, size.y) / 28.0
		draw_rect(
			Rect2(center.x - 10.0 * scale_value, center.y + 3.0 * scale_value, 20.0 * scale_value, 11.0 * scale_value),
			Color("#17324d")
		)
		draw_circle(center + Vector2(0.0, -4.0 * scale_value), 7.2 * scale_value, Color("#f2b889"))
		draw_rect(
			Rect2(center.x - 10.0 * scale_value, center.y - 13.0 * scale_value, 20.0 * scale_value, 5.0 * scale_value),
			Color("#234f7c")
		)
		draw_circle(center + Vector2(-3.0 * scale_value, -4.5 * scale_value), 1.2 * scale_value, Color("#1d160f"))
		draw_circle(center + Vector2(3.0 * scale_value, -4.5 * scale_value), 1.2 * scale_value, Color("#1d160f"))

	func _draw_meal_mini() -> void:
		var center := size * 0.5
		var scale_value: float = minf(size.x, size.y) / 28.0
		draw_arc(center + Vector2(0.0, 5.0 * scale_value), 10.0 * scale_value, 0.0, PI, 18, Color("#fff1cf"), 3.0 * scale_value)
		draw_arc(center + Vector2(0.0, 3.0 * scale_value), 8.0 * scale_value, 0.0, PI, 16, Color("#b35f25"), 2.5 * scale_value)
		for i in range(3):
			var x := center.x - 7.0 * scale_value + float(i) * 7.0 * scale_value
			draw_arc(Vector2(x, center.y - 7.0 * scale_value), 4.0 * scale_value, -1.6, 0.9, 8, Color(1.0, 0.92, 0.70, 0.36), 1.2 * scale_value)

	func _draw_fish_mini() -> void:
		var center := size * 0.5
		var scale_value: float = minf(size.x, size.y) / 28.0
		var body := PackedVector2Array(
			[
				center + Vector2(-11.0, 0.0) * scale_value,
				center + Vector2(-4.0, -5.5) * scale_value,
				center + Vector2(9.0, -2.5) * scale_value,
				center + Vector2(12.0, 0.0) * scale_value,
				center + Vector2(9.0, 2.5) * scale_value,
				center + Vector2(-4.0, 5.5) * scale_value,
			]
		)
		draw_colored_polygon(body, Color("#3e86b5"))
		draw_colored_polygon(
			PackedVector2Array(
				[
					center + Vector2(9.0, -2.5) * scale_value,
					center + Vector2(14.0, -7.0) * scale_value,
					center + Vector2(13.0, 0.0) * scale_value,
					center + Vector2(14.0, 7.0) * scale_value,
					center + Vector2(9.0, 2.5) * scale_value,
				]
			),
			Color("#24638e")
		)
		draw_circle(center + Vector2(-6.0, -1.0) * scale_value, 1.3 * scale_value, Color("#06111e"))

	func _draw_coin_mini() -> void:
		var center := size * 0.5
		var scale_value: float = minf(size.x, size.y) / 28.0
		for i in range(3):
			var offset := Vector2(float(i) * 4.4 - 4.4, float(i % 2) * 3.0) * scale_value
			draw_circle(center + offset, 6.5 * scale_value, Color("#9b641e"))
			draw_circle(center + offset + Vector2(-1.0, -1.0) * scale_value, 4.8 * scale_value, Palette.GOLD_BRIGHT)
			draw_arc(center + offset, 4.8 * scale_value, 0.0, TAU, 14, Color("#70451f"), 1.2 * scale_value)

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
		var left := 8.0
		var right := w - 18.0
		var rail := Color(1.0, 0.78, 0.28, 0.56) if available else Color(0.52, 0.45, 0.36, 0.42)
		var glow := Color(1.0, 0.95, 0.66, 0.34) if available else Color(0.58, 0.52, 0.42, 0.24)
		draw_line(Vector2(left, cy), Vector2(right, cy), glow, 5.0)
		draw_line(Vector2(left, cy), Vector2(right, cy), rail, 2.0)
		draw_colored_polygon(
			PackedVector2Array(
				[
					Vector2(right + 10.0, cy),
					Vector2(right - 3.0, cy - 5.0),
					Vector2(right - 3.0, cy + 5.0),
				]
			),
			rail
		)
		for i in range(2):
			var x := lerpf(left + 18.0, right - 18.0, float(i))
			draw_circle(Vector2(x, cy - 5.0), 1.8, glow)

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


class RecipeStarRank:
	extends Control

	var filled_count := 2
	var muted := false

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func configure(next_filled_count: int, next_muted: bool) -> void:
		filled_count = clampi(next_filled_count, 0, 3)
		muted = next_muted
		queue_redraw()

	func _draw() -> void:
		var outer_radius: float = clampf(size.y * 0.34, 4.8, 7.0)
		var inner_radius := outer_radius * 0.46
		var gap := 3.2
		var total_width := outer_radius * 2.0 * 3.0 + gap * 2.0
		var start_x := (size.x - total_width) * 0.5 + outer_radius
		var center_y := size.y * 0.52
		for i in range(3):
			var center := Vector2(start_x + float(i) * (outer_radius * 2.0 + gap), center_y)
			var filled := i < filled_count
			var outline := Palette.COOKING_RECIPE_STAR_OUTLINE
			var fill := Palette.GOLD_BRIGHT if filled and not muted else Palette.COOKING_RECIPE_STAR_LOCKED
			outline.a = 0.86 if filled else 0.54
			fill.a = 0.96 if filled and not muted else (0.62 if filled else 0.22)
			var shadow := Palette.COOKING_RECIPE_STAR_OUTLINE
			shadow.a = 0.34
			draw_colored_polygon(
				_star_points(center + Vector2(0.0, 1.2), outer_radius + 1.5, inner_radius + 0.8),
				shadow
			)
			draw_colored_polygon(
				_star_points(center, outer_radius + 0.9, inner_radius + 0.5),
				outline
			)
			draw_colored_polygon(_star_points(center, outer_radius, inner_radius), fill)

	func _star_points(center: Vector2, outer_radius: float, inner_radius: float) -> PackedVector2Array:
		var points := PackedVector2Array()
		for i in range(10):
			var radius := outer_radius if i % 2 == 0 else inner_radius
			var angle := -PI * 0.5 + TAU * float(i) / 10.0
			points.append(center + Vector2(cos(angle), sin(angle)) * radius)
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

var _player_status_bar: PlayerStatusBar
var _fish_scroll: ScrollContainer
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
var _result_title_slot: HBoxContainer
var _result_title: Label
var _result_title_lead: Control
var _result_title_icon: Control
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
	var root := make_root_margin(0)
	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 3)
	root.add_child(layout)

	_build_header(layout)
	_build_cook_select(layout)
	_build_result_summary(layout)

	_refresh_all()
	_show_status_summary()


func _add_cooking_background() -> void:
	var bg_tex := load(CookingAssets.COOKING_BG) as Texture2D
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
	glaze.color = Palette.COOKING_BG_GLAZE
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
		_style_box(
			Palette.COOKING_TITLE_FALLBACK_BG,
			Palette.COOKING_WOOD_BORDER,
			Palette.COOKING_GOLD_TRIM,
			6,
			5
		),
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

	_player_status_bar = PlayerStatusBarScript.new()
	_player_status_bar.name = "CookingPlayerStatusBar"
	_player_status_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_player_status_bar.custom_minimum_size = Vector2(0.0, 60.0)
	header.add_child(_player_status_bar)

	var back := make_button("港へ", func() -> void: navigate("harbor"), 96, false)
	back.custom_minimum_size = Vector2(90, 52)
	header.add_child(back)


func _build_cook_select(layout: VBoxContainer) -> void:
	var body_margin := MarginContainer.new()
	body_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_margin.add_theme_constant_override("margin_left", 8)
	body_margin.add_theme_constant_override("margin_right", 8)
	layout.add_child(body_margin)

	var body := HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	body_margin.add_child(body)

	var fish_panel := _panel_box(
		Palette.COOKING_FISH_PANEL_FILL,
		Palette.COOKING_FISH_PANEL_BORDER,
		Palette.COOKING_FISH_PANEL_INNER,
		6
	)
	fish_panel.custom_minimum_size = Vector2(322, 0)
	fish_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(fish_panel)
	var fish_layout := VBoxContainer.new()
	fish_layout.add_theme_constant_override("separation", 6)
	fish_panel.add_child(fish_layout)
	fish_layout.add_child(_section_ribbon("所持している魚", "fish", "FishSectionRibbon"))
	_fish_scroll = ScrollContainer.new()
	_fish_scroll.name = "FishListScroll"
	_fish_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fish_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_fish_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_fish_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_fish_scroll.follow_focus = true
	fish_layout.add_child(_fish_scroll)
	_fish_box = VBoxContainer.new()
	_fish_box.name = "FishList"
	_fish_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fish_box.add_theme_constant_override("separation", 6)
	_fish_scroll.add_child(_fish_box)

	var recipe_panel := _texture_panel_box(
		RECIPE_GRID_FRAME,
		32,
		_style_box(
			Palette.COOKING_RECIPE_GRID_FILL,
			Palette.COOKING_RECIPE_GRID_BORDER,
			Palette.COOKING_RECIPE_GRID_INNER,
			6,
			5
		),
		16.0,
		10.0
	)
	recipe_panel.custom_minimum_size = Vector2(444, 0)
	recipe_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(recipe_panel)
	var recipe_layout := VBoxContainer.new()
	recipe_layout.add_theme_constant_override("separation", 6)
	recipe_panel.add_child(recipe_layout)
	recipe_layout.add_child(_section_ribbon("料理を選ぶ", "meal_mini", "RecipeSectionRibbon"))
	_recipe_grid = GridContainer.new()
	_recipe_grid.name = "RecipeGrid"
	_recipe_grid.columns = 3
	_recipe_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_recipe_grid.add_theme_constant_override("h_separation", 7)
	_recipe_grid.add_theme_constant_override("v_separation", 9)
	recipe_layout.add_child(_recipe_grid)
	var recipe_book_button := make_button("料理図鑑を見る", _show_status_overlay, 280, false)
	recipe_book_button.name = "RecipeBookButton"
	recipe_book_button.custom_minimum_size = Vector2(330.0, 44.0)
	recipe_book_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	recipe_book_button.icon = _recipe_icon("locked")
	recipe_book_button.expand_icon = true
	recipe_book_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_apply_recipe_book_button_style(recipe_book_button)
	recipe_layout.add_child(recipe_book_button)

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
		_style_box(
			Palette.COOKING_DETAIL_PANEL_FILL,
			Palette.COOKING_DETAIL_PANEL_BORDER,
			Palette.COOKING_DETAIL_PANEL_INNER,
			6,
			5
		),
		18.0,
		12.0
	)
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(detail_panel)
	var detail_layout := VBoxContainer.new()
	detail_layout.add_theme_constant_override("separation", 3)
	detail_panel.add_child(detail_layout)
	_dish_title = make_label(
		"料理を選んでください",
		27,
		Palette.COOKING_DETAIL_TITLE_TEXT,
		1,
		Palette.COOKING_DETAIL_TITLE_OUTLINE
	)
	_dish_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dish_title.custom_minimum_size = Vector2(0.0, 32.0)
	detail_layout.add_child(_dish_title)
	_dish_subtitle = make_label("", 13, Palette.COOKING_DETAIL_SUBTITLE_TEXT)
	_dish_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dish_subtitle.custom_minimum_size = Vector2(0.0, 16.0)
	detail_layout.add_child(_dish_subtitle)
	var dish_frame := _panel_box(
		Palette.COOKING_DETAIL_DISH_FRAME_FILL,
		Palette.COOKING_DETAIL_DISH_FRAME_BORDER,
		Palette.COOKING_DETAIL_PANEL_INNER,
		4
	)
	dish_frame.custom_minimum_size = Vector2(0, 154)
	dish_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_layout.add_child(dish_frame)
	_dish_image = TextureRect.new()
	_dish_image.name = "SelectedDishFeatureImage"
	_dish_image.custom_minimum_size = Vector2(0, 144)
	_dish_image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dish_image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dish_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dish_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	dish_frame.add_child(_dish_image)
	var detail_rows := VBoxContainer.new()
	detail_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_rows.add_theme_constant_override("separation", 5)
	detail_layout.add_child(detail_rows)
	var material_labels := _add_detail_story_row(
		detail_rows,
		"CookDetailMaterialRow",
		"必要な材料",
		"fish",
		Palette.COOKING_DETAIL_MATERIAL_ACCENT,
		132.0
	)
	_material_value = material_labels[0] as Label
	_stock_value = material_labels[1] as Label
	var exp_labels := _add_detail_story_row(
		detail_rows,
		"CookDetailExpRow",
		"獲得EXP",
		"exp",
		Palette.COOKING_DETAIL_EXP_ACCENT,
		118.0
	)
	_exp_value = exp_labels[0] as Label
	_bonus_value = exp_labels[1] as Label
	var buff_labels := _add_detail_story_row(
		detail_rows,
		"CookDetailEffectRow",
		"次の釣行効果",
		"buff",
		Palette.GAUGE_GREEN_HI,
		168.0
	)
	_buff_value = buff_labels[0] as Label
	_effect_count_value = buff_labels[1] as Label
	var action_panel := _texture_panel_box(
		COOK_ACTION_RUNWAY_FRAME,
		28,
		_style_box(
			Palette.COOKING_DETAIL_ACTION_FILL,
			Palette.COOKING_DETAIL_ROW_BORDER,
			Palette.COOKING_DETAIL_ROW_INNER,
			3,
			5
		),
		10.0,
		5.0
	)
	action_panel.name = "CookActionRunway"
	action_panel.custom_minimum_size = Vector2(0, 100)
	action_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_layout.add_child(action_panel)
	var action_layout := VBoxContainer.new()
	action_layout.add_theme_constant_override("separation", 4)
	action_panel.add_child(action_layout)
	var cue_row := HBoxContainer.new()
	cue_row.custom_minimum_size = Vector2(0, 22)
	cue_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cue_row.add_theme_constant_override("separation", 8)
	action_layout.add_child(cue_row)
	var note_badge := PanelContainer.new()
	var note_style := _style_box(
		Palette.COOKING_DETAIL_NOTE_FILL,
		Palette.COOKING_DETAIL_NOTE_BORDER,
		Palette.COOKING_DETAIL_NOTE_INNER,
		2,
		4
	)
	note_style.content_margin_left = 8.0
	note_style.content_margin_top = 1.0
	note_style.content_margin_right = 8.0
	note_style.content_margin_bottom = 1.0
	note_badge.add_theme_stylebox_override("panel", note_style)
	note_badge.custom_minimum_size = Vector2(186, 22)
	cue_row.add_child(note_badge)
	_overwrite_note = make_label("", 12, Palette.TEXT_BONE, 1, Palette.COOKING_DETAIL_NOTE_OUTLINE)
	_overwrite_note.autowrap_mode = TextServer.AUTOWRAP_OFF
	_overwrite_note.clip_text = true
	_overwrite_note.custom_minimum_size = Vector2(0, 18)
	_overwrite_note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_overwrite_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_overwrite_note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	note_badge.add_child(_overwrite_note)
	var cue_spacer := Control.new()
	cue_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cue_row.add_child(cue_spacer)
	_cook_action_cue = CookActionCueVisual.new()
	_cook_action_cue.name = "CookActionCue"
	_cook_action_cue.custom_minimum_size = Vector2(82, 18)
	cue_row.add_child(_cook_action_cue)
	_cook_button = make_button("調理する", _cook_selected, 300, true)
	_cook_button.name = "CookButton"
	_cook_button.custom_minimum_size = Vector2(356, 64)
	_cook_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_apply_cook_button_style()
	_cook_button.draw.connect(func() -> void: _draw_cook_button_icon(_cook_button))
	action_layout.add_child(_cook_button)


func _build_result_summary(layout: VBoxContainer) -> void:
	var result_panel := _texture_panel_box(
		PREP_SUMMARY_BAR_FRAME,
		18,
		_style_box(
			Palette.COOKING_PREP_BAR_FILL,
			Palette.COOKING_PREP_BAR_BORDER,
			Palette.COOKING_PREP_BAR_INNER,
			6,
			5
		),
		12.0,
		6.0
	)
	result_panel.name = "CurrentPrepBar"
	_result_panel = result_panel
	result_panel.custom_minimum_size = Vector2(0, 84)
	layout.add_child(result_panel)
	var result_layout := HBoxContainer.new()
	result_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_layout.add_theme_constant_override("separation", 6)
	result_panel.add_child(result_layout)
	var title_slot := HBoxContainer.new()
	title_slot.name = "CurrentPrepTitleSlot"
	title_slot.custom_minimum_size = Vector2(184.0, 0.0)
	title_slot.add_theme_constant_override("separation", 4)
	result_layout.add_child(title_slot)
	_result_title_slot = title_slot
	var title_lead := Control.new()
	title_lead.name = "CurrentPrepTitleLead"
	title_lead.custom_minimum_size = Vector2(14.0, 0.0)
	title_slot.add_child(title_lead)
	_result_title_lead = title_lead
	var title_icon := _small_icon("player_mini", Palette.GOLD_BRIGHT, Vector2(28.0, 28.0))
	title_icon.name = "CurrentPrepTitleIcon"
	title_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_slot.add_child(title_icon)
	_result_title_icon = title_icon
	_result_title = make_shadow_label("", 15, Palette.TEXT_BONE, 2, Color("#2b2117"))
	_result_title.name = "CurrentPrepTitle"
	_result_title.custom_minimum_size = Vector2(0.0, 0.0)
	_result_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_result_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_result_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	_result_title.clip_text = true
	title_slot.add_child(_result_title)
	_result_body = HBoxContainer.new()
	_result_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_result_body.add_theme_constant_override("separation", 6)
	result_layout.add_child(_result_body)
	_status_button = make_button("詳細", _show_status_overlay, 100, false)
	_status_button.name = "CurrentPrepDetailButton"
	_status_button.custom_minimum_size = Vector2(72, 52)
	_status_button.visible = false
	result_layout.add_child(_status_button)


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
	var tile := _texture_panel_box(
		COOK_DETAIL_ROW_FRAME,
		16,
		_style_box(
			Palette.COOKING_DETAIL_ROW_FILL,
			Palette.COOKING_DETAIL_ROW_BORDER,
			Palette.COOKING_DETAIL_ROW_INNER,
			3,
			5
		),
		8.0,
		2.0
	)
	tile.name = node_name
	tile.custom_minimum_size = Vector2(0, 56)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(tile)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	tile.add_child(row)

	var title_band := MarginContainer.new()
	title_band.custom_minimum_size = Vector2(title_width, 44)
	title_band.add_theme_constant_override("margin_left", 4)
	title_band.add_theme_constant_override("margin_right", 4)
	row.add_child(title_band)
	var title_row := HBoxContainer.new()
	title_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	title_row.add_theme_constant_override("separation", 4)
	title_band.add_child(title_row)
	var icon_size := 20.0 if title.length() > 8 else 24.0
	var icon := _small_icon(icon_mode, accent, Vector2(icon_size, icon_size))
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_row.add_child(icon)
	var compact := title.length() > 5
	var title_size := 10 if title.length() > 8 else 14 if compact else 15
	var title_label := make_shadow_label(title, title_size, Palette.TEXT_BONE, 1)
	title_label.custom_minimum_size = Vector2(0, 42)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_label.clip_text = true
	title_row.add_child(title_label)

	var primary_size := 17 if node_name == "CookDetailEffectRow" else 18
	var primary := make_shadow_label(
		"",
		primary_size,
		Palette.COOKING_DETAIL_VALUE_TEXT,
		1,
		Palette.COOKING_DETAIL_VALUE_OUTLINE
	)
	primary.custom_minimum_size = Vector2(0, 44)
	primary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	primary.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if node_name == "CookDetailEffectRow" else HORIZONTAL_ALIGNMENT_CENTER
	primary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	primary.autowrap_mode = TextServer.AUTOWRAP_OFF
	primary.clip_text = true
	row.add_child(primary)

	var secondary_width := 48.0 if compact else 130.0
	if node_name == "CookDetailEffectRow":
		secondary_width = 54.0
	elif node_name == "CookDetailExpRow":
		secondary_width = 142.0
	var secondary_badge := PanelContainer.new()
	secondary_badge.name = "%sSecondaryBadge" % node_name
	var secondary_style := _style_box(
		Palette.COOKING_DETAIL_BADGE_FILL,
		Palette.COOKING_DETAIL_BADGE_BORDER,
		Palette.COOKING_DETAIL_BADGE_INNER,
		2,
		5
	)
	secondary_style.content_margin_left = 5.0
	secondary_style.content_margin_top = 1.0
	secondary_style.content_margin_right = 5.0
	secondary_style.content_margin_bottom = 1.0
	secondary_badge.add_theme_stylebox_override("panel", secondary_style)
	secondary_badge.custom_minimum_size = Vector2(secondary_width, 38)
	secondary_badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(secondary_badge)
	var secondary_size := 14 if node_name == "CookDetailExpRow" else primary_size
	var secondary := make_shadow_label("", secondary_size, accent, 1, Palette.COOKING_DETAIL_BADGE_OUTLINE)
	secondary.custom_minimum_size = Vector2(0, 34)
	secondary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	secondary.horizontal_alignment = (
		HORIZONTAL_ALIGNMENT_RIGHT
		if node_name == "CookDetailEffectRow"
		else HORIZONTAL_ALIGNMENT_CENTER
	)
	secondary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	secondary.autowrap_mode = TextServer.AUTOWRAP_OFF
	secondary.clip_text = true
	secondary_badge.add_child(secondary)
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
	if _player_status_bar != null:
		_player_status_bar.refresh()


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
	var ordered_ids := _ordered_cooking_fish_ids()
	for fish_id in ordered_ids:
		if PlayerProgress.fish_count(fish_id) > 0:
			_append_fish_display_id(ids, fish_id)
	for fish_id in ordered_ids:
		if ids.size() >= COOKING_FISH_MIN_VISIBLE_ROWS:
			break
		if ids.has(fish_id):
			continue
		if fish_id == "boss_kurodai":
			continue
		_append_fish_display_id(ids, fish_id)
	if ids.size() < COOKING_FISH_MIN_VISIBLE_ROWS:
		_append_fish_display_id(ids, "boss_kurodai")
	return ids


func _append_fish_display_id(ids: Array[String], fish_id: String) -> void:
	if ids.has(fish_id):
		return
	if GameData.get_fish(fish_id).is_empty():
		return
	ids.append(fish_id)


func _ordered_cooking_fish_ids() -> Array[String]:
	var ids: Array[String] = []
	for fish_id_variant in COOKING_FISH_DISPLAY_ORDER:
		var fish_id := String(fish_id_variant)
		if GameData.get_fish(fish_id).is_empty():
			continue
		if not ids.has(fish_id):
			ids.append(fish_id)
	for fish_id_variant in GameData.get_all_fish_ids():
		var fish_id := String(fish_id_variant)
		if not ids.has(fish_id):
			ids.append(fish_id)
	return ids


func _make_fish_card(fish_id: String, count: int) -> PanelContainer:
	var fish := GameData.get_fish(fish_id)
	var owned := count > 0
	var card := PanelContainer.new()
	card.name = _fish_row_node_name(fish_id)
	card.custom_minimum_size = Vector2(0, 72)
	card.mouse_filter = Control.MOUSE_FILTER_STOP if owned else Control.MOUSE_FILTER_IGNORE
	if owned:
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		card.gui_input.connect(
			func(event: InputEvent) -> void:
				if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
					_select_fish(fish_id)
		)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	card.add_child(row)
	var marker := make_shadow_label("", 20, Palette.GOLD_BRIGHT, 2)
	marker.custom_minimum_size = Vector2(0, 0)
	marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(marker)
	var icon := TextureRect.new()
	icon.texture = _fish_row_texture(fish_id)
	icon.custom_minimum_size = Vector2(FISH_ROW_ICON_MIN_WIDTH, 60)
	icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon.size_flags_stretch_ratio = 1.45
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.modulate = Palette.COOKING_FISH_ICON_TINT if owned else Palette.COOKING_FISH_ICON_MUTED_TINT
	row.add_child(icon)
	var display_name := _fish_row_display_name(fish_id, String(fish.get("name", fish_id)))
	var name_font_size := 20 if display_name.length() <= 3 else 15
	var name := make_label(
		display_name,
		name_font_size,
		Palette.COOKING_FISH_NAME_TEXT,
		1,
		Palette.COOKING_FISH_NAME_OUTLINE
	)
	name.custom_minimum_size = Vector2(FISH_ROW_NAME_MIN_WIDTH, 0.0)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.size_flags_stretch_ratio = 1.0
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name.autowrap_mode = TextServer.AUTOWRAP_OFF
	name.clip_text = true
	row.add_child(name)
	var amount_text := "× %d 匹" % count if owned else "未所持"
	var amount_color := Palette.COOKING_FISH_AMOUNT_TEXT if owned else Palette.COOKING_FISH_AMOUNT_MUTED_TEXT
	var amount := make_label(amount_text, 15 if owned else 12, amount_color, 1, Palette.COOKING_FISH_AMOUNT_OUTLINE)
	amount.custom_minimum_size = Vector2(FISH_ROW_AMOUNT_WIDTH, 34.0)
	amount.size_flags_horizontal = Control.SIZE_SHRINK_END
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	amount.clip_text = true
	row.add_child(amount)
	_make_card_contents_click_through(card)
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
		"madai":
			return "FishRowMadai"
		"kasago":
			return "FishRowKasago"
		"ika":
			return "FishRowIka"
		"suzuki":
			return "FishRowSuzuki"
		"kawahagi":
			return "FishRowKawahagi"
		"hirame":
			return "FishRowHirame"
		"mejina":
			return "FishRowMejina"
		"isaki":
			return "FishRowIsaki"
		"boss_kurodai":
			return "FishRowBossKurodai"
		_:
			return "FishRow_%s" % fish_id


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
		var card_tint := Palette.COOKING_FISH_ROW_MUTED_MODULATE
		var fill := Palette.COOKING_FISH_ROW_MUTED_FILL
		var border := Palette.COOKING_FISH_ROW_MUTED_BORDER
		var inner := Palette.COOKING_FISH_ROW_MUTED_INNER
		if selected:
			card_tint = Palette.COOKING_FISH_ROW_SELECTED_MODULATE
			fill = Palette.COOKING_FISH_ROW_SELECTED_FILL
			border = Palette.COOKING_FISH_ROW_SELECTED_BORDER
			inner = Palette.COOKING_FISH_ROW_SELECTED_INNER
		elif owned:
			card_tint = Palette.COOKING_FISH_ROW_MODULATE
			fill = Palette.COOKING_FISH_ROW_FILL
			border = Palette.COOKING_FISH_ROW_BORDER
			inner = Palette.COOKING_FISH_ROW_INNER
		card.self_modulate = card_tint
		card.add_theme_stylebox_override(
			"panel",
			_texture_style_box(
				FISH_ROW_FRAME,
				36,
				_style_box(fill, border, inner, 4, 6),
				10.0,
				6.0
			)
		)
		if marker != null:
			marker.text = ""


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
		_recipe_grid.add_child(_make_recipe_preview_card())
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


func _recipe_card_title_text(recipe: Dictionary, locked: bool, unavailable: bool) -> String:
	var recipe_id := String(recipe.get("id", ""))
	var recipe_name := String(recipe.get("name", ""))
	var fish_id := _recipe_material_fish_id(recipe, locked, unavailable)
	if fish_id.is_empty():
		return recipe_name
	var fish := GameData.get_fish(fish_id)
	var fish_name := String(fish.get("name", fish_id))
	return _dish_display_name(fish_name, recipe_id, recipe_name)


func _dish_display_name(fish_name: String, recipe_id: String, recipe_name: String) -> String:
	if fish_name.is_empty():
		return recipe_name
	if recipe_id == "fry":
		return "%sフライ" % fish_name
	return "%sの%s" % [fish_name, recipe_name]


func _make_recipe_card(recipe: Dictionary, locked: bool, unavailable: bool) -> PanelContainer:
	var recipe_id := String(recipe.get("id", ""))
	var card := PanelContainer.new()
	card.name = "RecipeCard_%s" % recipe_id
	card.custom_minimum_size = Vector2(132, 196)
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
	var title_text := _recipe_card_title_text(recipe, locked, unavailable)
	var title_font_size := 13 if title_text.length() <= 7 else 12
	var title := make_shadow_label(
		title_text,
		title_font_size,
		Palette.COOKING_RECIPE_TITLE_TEXT,
		1,
		Palette.COOKING_RECIPE_TITLE_OUTLINE
	)
	title.name = "RecipeTitle_%s" % recipe_id
	title.custom_minimum_size = Vector2(0.0, 31.0)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.clip_text = true
	box.add_child(title)
	var image := _recipe_card_dish_image(recipe_id, locked or unavailable)
	box.add_child(image)
	var stars := RecipeStarRank.new()
	stars.name = "RecipeStars_%s" % recipe_id
	stars.custom_minimum_size = Vector2(0.0, 19.0)
	stars.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stars.configure(_recipe_star_count(recipe), locked)
	box.add_child(stars)
	var material_row := _add_recipe_material_badge(box, recipe_id)
	var material_icon := TextureRect.new()
	material_icon.name = "RecipeMaterialIcon_%s" % recipe_id
	material_icon.texture = _recipe_material_texture(recipe, locked, unavailable)
	material_icon.custom_minimum_size = Vector2(68.0, 22.0)
	material_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	material_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	material_icon.modulate = Color(0.88, 0.80, 0.66, 0.96) if locked or unavailable else Color.WHITE
	material_row.add_child(material_icon)
	var footer_text := _recipe_card_status_text(recipe, locked, unavailable)
	var footer: Label = null
	if not footer_text.is_empty():
		footer = make_label(
			footer_text,
			9,
			Palette.COOKING_RECIPE_FOOTER_TEXT,
			1,
			Palette.COOKING_RECIPE_FOOTER_OUTLINE
		)
		footer.custom_minimum_size = Vector2(30.0, 20.0)
		footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		footer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		footer.clip_text = true
		material_row.add_child(footer)
	_recipe_cards[recipe_id] = {
		"card": card,
		"locked": locked,
		"unavailable": unavailable,
		"footer": footer,
		"footer_text": footer_text,
	}
	_make_card_contents_click_through(card)
	return card


func _make_recipe_preview_card() -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "RecipeCard_PreviewMeuniere"
	card.custom_minimum_size = Vector2(132, 196)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.self_modulate = Color(0.92, 0.86, 0.74, 1.0)
	card.add_theme_stylebox_override(
		"panel",
		_texture_style_box(
			RECIPE_CARD_FRAME,
			28,
			_style_box(
				Palette.COOKING_RECIPE_CARD_UNAVAILABLE_FILL,
				Palette.COOKING_RECIPE_CARD_BORDER,
				Palette.COOKING_RECIPE_CARD_INNER,
				4,
				6
			),
			12.0,
			8.0
		)
	)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	card.add_child(box)
	var title := make_shadow_label(
		"ヒラメのムニエル",
		12,
		Palette.COOKING_RECIPE_TITLE_TEXT,
		1,
		Palette.COOKING_RECIPE_TITLE_OUTLINE
	)
	title.name = "RecipeTitle_PreviewMeuniere"
	title.custom_minimum_size = Vector2(0.0, 31.0)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.clip_text = true
	box.add_child(title)
	var image := _recipe_card_dish_image("PreviewMeuniere", true, _featured_dish_texture("fry"))
	box.add_child(image)
	var stars := RecipeStarRank.new()
	stars.name = "RecipeStars_PreviewMeuniere"
	stars.custom_minimum_size = Vector2(0.0, 19.0)
	stars.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stars.configure(2, true)
	box.add_child(stars)
	var material_row := _add_recipe_material_badge(box, "PreviewMeuniere")
	var icon := TextureRect.new()
	icon.name = "RecipeMaterialIcon_PreviewMeuniere"
	icon.texture = _fish_material_texture("hirame")
	icon.custom_minimum_size = Vector2(68.0, 22.0)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = Color(0.88, 0.80, 0.66, 0.96)
	material_row.add_child(icon)
	var footer := make_label(
		"Lv.6",
		9,
		Palette.COOKING_RECIPE_FOOTER_TEXT,
		1,
		Palette.COOKING_RECIPE_FOOTER_OUTLINE
	)
	footer.custom_minimum_size = Vector2(30.0, 20.0)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.clip_text = true
	material_row.add_child(footer)
	_make_card_contents_click_through(card)
	return card


func _recipe_card_dish_image(
	recipe_id: String, muted: bool, texture_override: Texture2D = null
) -> PanelContainer:
	var thumb := _texture_panel_box(
		RECIPE_DISH_THUMB_FRAME,
		18,
		_style_box(
			Palette.COOKING_RECIPE_THUMB_FILL,
			Palette.COOKING_RECIPE_THUMB_BORDER,
			Palette.COOKING_RECIPE_THUMB_INNER,
			2,
			4
		),
		5.0,
		3.0
	)
	thumb.name = "RecipeDishThumb_%s" % recipe_id
	thumb.custom_minimum_size = Vector2(0.0, 94.0)
	thumb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var image := TextureRect.new()
	image.name = "RecipeDishImage_%s" % recipe_id
	image.texture = texture_override if texture_override != null else _featured_dish_texture(recipe_id)
	image.custom_minimum_size = Vector2(0.0, 88.0)
	image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	image.modulate = Color(0.82, 0.76, 0.64, 0.94) if muted else Color.WHITE
	thumb.add_child(image)
	return thumb


func _add_recipe_material_badge(parent: Container, recipe_id: String) -> HBoxContainer:
	var badge := _texture_panel_box(
		RECIPE_MATERIAL_STRIP_FRAME,
		14,
		_style_box(
			Palette.COOKING_RECIPE_MATERIAL_FILL,
			Palette.COOKING_RECIPE_CARD_BORDER,
			Palette.COOKING_RECIPE_MATERIAL_INNER,
			3,
			5
		),
		5.0,
		1.0
	)
	badge.name = "RecipeMaterialBadge_%s" % recipe_id
	badge.custom_minimum_size = Vector2(0.0, 26.0)
	badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(badge)
	var material_row := HBoxContainer.new()
	material_row.name = "RecipeMaterialRow_%s" % recipe_id
	material_row.custom_minimum_size = Vector2(0.0, 24.0)
	material_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	material_row.alignment = BoxContainer.ALIGNMENT_CENTER
	material_row.add_theme_constant_override("separation", 2)
	badge.add_child(material_row)
	return material_row


func _recipe_star_count(recipe: Dictionary) -> int:
	var multiplier := float(recipe.get("exp_multiplier", 1.0))
	if multiplier >= 1.3:
		return 3
	return 2


func _recipe_material_texture(recipe: Dictionary, locked: bool, unavailable: bool) -> Texture2D:
	var fish_id := _recipe_material_fish_id(recipe, locked, unavailable)
	if fish_id.is_empty():
		return _recipe_icon("locked")
	return _fish_material_texture(fish_id)


func _recipe_material_fish_id(recipe: Dictionary, locked: bool, unavailable: bool) -> String:
	if not locked and not unavailable and not _selected_fish_id.is_empty():
		return _selected_fish_id
	var allowed = recipe.get("allowed_fish", [])
	if allowed is Array and not allowed.is_empty():
		return String(allowed[0])
	return ""


func _recipe_card_status_text(recipe: Dictionary, locked: bool, unavailable: bool) -> String:
	if locked:
		return "Lv.%d" % int(recipe.get("unlock_level", 1))
	if unavailable:
		return "別素材"
	return ""


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
		var fill := Palette.COOKING_RECIPE_CARD_SELECTED_FILL if selected else Palette.COOKING_RECIPE_CARD_FILL
		if locked:
			fill = Palette.COOKING_RECIPE_CARD_LOCKED_FILL
		elif unavailable:
			fill = Palette.COOKING_RECIPE_CARD_UNAVAILABLE_FILL
		var border := Palette.COOKING_RECIPE_CARD_SELECTED_BORDER if selected else Palette.COOKING_RECIPE_CARD_BORDER
		var inner := Palette.COOKING_RECIPE_CARD_SELECTED_INNER if selected else Palette.COOKING_RECIPE_CARD_INNER
		var tint := Color.WHITE
		if locked:
			tint = Color(0.86, 0.80, 0.68, 1.0)
		elif unavailable:
			tint = Color(0.90, 0.84, 0.72, 1.0)
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
			footer.text = base_footer


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
	_dish_title.text = _dish_display_name(
		String(fish["name"]),
		_selected_recipe_id,
		String(recipe["name"])
	)
	_dish_subtitle.text = String(recipe.get("description", ""))
	_dish_image.texture = _featured_dish_texture(_selected_recipe_id)
	_material_value.text = "%s ×1" % String(fish["name"])
	_stock_value.text = "%d / 1" % count
	_exp_value.text = "+%d EXP" % total_exp
	_bonus_value.text = "初回 +%d EXP" % base_exp if first_time else "初回済"
	_buff_value.text = _detail_buff_value_text(String(recipe.get("buff_text", "")))
	_effect_count_value.text = "1回"
	_overwrite_note.text = "調理後は食事結果へ"
	_cook_action_cue.visible = true
	_cook_action_cue.set_available(count > 0)
	_cook_button.disabled = count <= 0
	_cook_button.queue_redraw()


func _detail_buff_value_text(buff_text: String) -> String:
	var prefix := "次の釣行で"
	if buff_text.begins_with(prefix):
		return buff_text.substr(prefix.length())
	return buff_text


func _apply_cook_button_style() -> void:
	var normal_fallback := _style_box(
		Palette.COOKING_ACTION_BUTTON_FILL,
		Palette.COOKING_ACTION_BUTTON_BORDER,
		Palette.GOLD_BRIGHT,
		4,
		6
	)
	var hover_fallback := _style_box(
		Palette.COOKING_ACTION_BUTTON_HOVER_FILL,
		Palette.COOKING_ACTION_BUTTON_BORDER,
		Palette.COOKING_ACTION_BUTTON_HOVER_INNER,
		4,
		6
	)
	var pressed_fallback := _style_box(
		Palette.COOKING_ACTION_BUTTON_PRESSED_FILL,
		Palette.COOKING_ACTION_BUTTON_PRESSED_BORDER,
		Palette.GOLD_DEEP,
		4,
		6
	)
	var disabled_fallback := _style_box(
		Palette.COOKING_ACTION_BUTTON_DISABLED_FILL,
		Palette.COOKING_ACTION_BUTTON_DISABLED_BORDER,
		Palette.COOKING_ACTION_BUTTON_DISABLED_INNER,
		4,
		6
	)
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
	_cook_button.add_theme_color_override("font_hover_color", Palette.COOKING_ACTION_BUTTON_HOVER_TEXT)
	_cook_button.add_theme_color_override("font_pressed_color", Palette.COOKING_ACTION_BUTTON_PRESSED_TEXT)
	_cook_button.add_theme_color_override("font_disabled_color", Palette.COOKING_ACTION_BUTTON_DISABLED_TEXT)
	_cook_button.add_theme_font_size_override("font_size", 25)


func _apply_recipe_book_button_style(button: Button) -> void:
	var normal_fallback := _style_box(Color("#123553"), Color("#3b2515"), Palette.GOLD_BRIGHT, 4, 6)
	var hover_fallback := _style_box(Color("#1b496e"), Color("#3b2515"), Color("#ffe67a"), 4, 6)
	var pressed_fallback := _style_box(Color("#0d2942"), Color("#2a1a10"), Palette.GOLD_DEEP, 4, 6)
	button.add_theme_stylebox_override(
		"normal",
		_texture_style_box(COOK_BUTTON_FRAME, 22, normal_fallback, 52.0, 6.0)
	)
	button.add_theme_stylebox_override(
		"hover",
		_texture_style_box(COOK_BUTTON_FRAME, 22, hover_fallback, 52.0, 6.0)
	)
	button.add_theme_stylebox_override(
		"pressed",
		_texture_style_box(COOK_BUTTON_FRAME, 22, pressed_fallback, 52.0, 6.0)
	)
	button.add_theme_stylebox_override(
		"focus",
		_texture_style_box(COOK_BUTTON_FRAME, 22, hover_fallback, 52.0, 6.0)
	)
	button.add_theme_color_override("font_color", Palette.GOLD_BRIGHT)
	button.add_theme_color_override("font_hover_color", Color("#fff1ba"))
	button.add_theme_color_override("font_pressed_color", Color("#f0c06b"))
	button.add_theme_font_size_override("font_size", 18)


func _draw_cook_button_icon(button: Button) -> void:
	var active := not button.disabled
	var center := Vector2(54.0, button.size.y * 0.5 - 1.0)
	var ink := Palette.COOKING_ACTION_ICON_INK if active else Palette.COOKING_ACTION_ICON_MUTED_INK
	var pot := Palette.COOKING_ACTION_ICON_POT if active else Palette.COOKING_ACTION_ICON_MUTED_POT
	var lid := Palette.COOKING_ACTION_ICON_LID if active else Palette.COOKING_ACTION_ICON_MUTED_LID
	var steam := Palette.COOKING_ACTION_ICON_STEAM if active else Palette.COOKING_ACTION_ICON_MUTED_STEAM
	button.draw_rect(Rect2(center.x - 14.0, center.y - 1.0, 28.0, 12.0), ink)
	button.draw_rect(Rect2(center.x - 11.0, center.y + 1.0, 22.0, 9.0), pot)
	button.draw_line(center + Vector2(-16.0, -3.0), center + Vector2(16.0, -3.0), ink, 3.0)
	button.draw_line(center + Vector2(-12.0, -6.0), center + Vector2(12.0, -6.0), lid, 2.0)
	button.draw_arc(center + Vector2(0.0, -10.0), 7.5, PI, TAU, 12, ink, 2.0)
	button.draw_line(center + Vector2(-15.0, 4.0), center + Vector2(-20.0, 7.0), ink, 2.0)
	button.draw_line(center + Vector2(15.0, 4.0), center + Vector2(20.0, 7.0), ink, 2.0)
	button.draw_line(center + Vector2(-8.0, 12.0), center + Vector2(-13.0, 16.0), ink, 2.0)
	button.draw_line(center + Vector2(8.0, 12.0), center + Vector2(13.0, 16.0), ink, 2.0)
	for i in range(2):
		var x := center.x - 5.0 + float(i) * 10.0
		button.draw_arc(Vector2(x, center.y - 17.0), 5.5, -1.8, 0.8, 8, steam, 1.7)


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
	if not is_qa_deterministic():
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
	_set_result_summary_compact(true)
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
	if _result_title_slot != null:
		_result_title_slot.visible = true
	if _result_title_icon != null:
		_result_title_icon.visible = false
	if _result_title_lead != null:
		_result_title_lead.visible = false
	if _status_button != null:
		_status_button.visible = false
	_result_title.text = "調理できませんでした"
	_clear_container(_result_body)
	_result_body.add_child(_summary_card("確認", message, Palette.GAUGE_RED_HI))


func _show_status_summary() -> void:
	if _flow_state != FlowState.COOK_SELECT:
		_flow_state = FlowState.COOK_SELECT
	_set_result_summary_compact(false)
	if _result_title_slot != null:
		_result_title_slot.visible = false
	if _result_title_icon != null:
		_result_title_icon.visible = true
	if _result_title_lead != null:
		_result_title_lead.visible = true
	if _status_button != null:
		_status_button.visible = false
	_result_title.text = "現在の準備"
	_clear_container(_result_body)
	_result_body.add_child(
		_prep_summary_card(
			"プレイヤーLv",
			"Lv.%d" % PlayerProgress.level,
			Palette.GOLD_BRIGHT,
			"player_mini",
			"PrepSummaryCardLevel"
		)
	)
	_result_body.add_child(
		_prep_summary_card(
			"効果中の料理",
			_current_meal_summary_text(),
			Palette.GAUGE_GREEN_HI,
			"meal_mini",
			"PrepSummaryCardMeal"
		)
	)
	_result_body.add_child(
		_prep_summary_card(
			"クーラーボックス",
			"%d / 20" % _total_fish_count(),
			Palette.GAUGE_CYAN_HI,
			"fish_mini",
			"PrepSummaryCardFish"
		)
	)
	_result_body.add_child(
		_prep_summary_card(
			"所持金",
			"%s G" % format_money(PlayerProgress.money),
			Palette.GOLD_BRIGHT,
			"coin_mini",
			"PrepSummaryCardMoney"
		)
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
	return "%s / あと1回" % name


func _show_meal_result(result: Dictionary, leveled: bool) -> void:
	_flow_state = FlowState.MEAL_RESULT if not leveled else FlowState.EXP_GAIN
	_set_result_summary_compact(false)
	if _result_title_slot != null:
		_result_title_slot.visible = true
	if _result_title_icon != null:
		_result_title_icon.visible = false
	if _result_title_lead != null:
		_result_title_lead.visible = false
	if _status_button != null:
		_status_button.visible = false
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
	_set_result_summary_compact(true)
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
	_set_result_summary_compact(true)
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


func _prep_summary_card(
	title: String, value: String, accent: Color, icon_mode := "book", node_name := ""
) -> PanelContainer:
	var card := _texture_panel_box(
		PREP_SUMMARY_CARD_FRAME,
		12,
		_style_box(
			Palette.COOKING_PREP_CARD_FILL,
			Palette.COOKING_PREP_CARD_BORDER,
			Palette.COOKING_PREP_CARD_INNER,
			3,
			5
		),
		16.0,
		3.0
	)
	card.name = node_name
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 60)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)
	var icon := _small_icon(icon_mode, accent, Vector2(44.0, 44.0))
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 0)
	row.add_child(text_box)
	var title_size := 13 if title.length() >= 7 else 14
	var title_label := make_shadow_label(
		title,
		title_size,
		Palette.COOKING_PREP_TITLE_TEXT,
		1,
		Palette.COOKING_PREP_TITLE_OUTLINE
	)
	title_label.custom_minimum_size = Vector2(0.0, 21.0)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_label.clip_text = true
	text_box.add_child(title_label)
	var value_size := 15 if title == "効果中の料理" else 17 if value.length() >= 9 else 20
	var value_label := make_shadow_label(
		value,
		value_size,
		Palette.COOKING_PREP_VALUE_TEXT,
		1,
		Palette.COOKING_PREP_VALUE_OUTLINE
	)
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	value_label.clip_text = true
	text_box.add_child(value_label)
	return card


func _set_result_summary_compact(compact: bool) -> void:
	if _result_panel != null:
		_result_panel.custom_minimum_size = Vector2(0, 84)
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


func _make_card_contents_click_through(root: Control) -> void:
	for child in root.get_children():
		if not (child is Control):
			continue
		var control := child as Control
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_make_card_contents_click_through(control)


func _panel_box(fill: Color, border: Color, inner: Color, border_width: int) -> PanelContainer:
	return CookingAssets.panel_box(fill, border, inner, border_width, 12.0, 8.0, 0.28, 4, 2.0, 5)


func _texture_panel_box(
	path: String, margin: int, fallback: StyleBox, content_x: float, content_y: float
) -> PanelContainer:
	return CookingAssets.texture_panel_box(path, margin, fallback, content_x, content_y, 6.0)


func _style_box(fill: Color, border: Color, inner: Color, border_width: int, radius: int) -> StyleBoxFlat:
	return CookingAssets.style_box(fill, border, inner, border_width, radius, 12.0, 8.0, 0.28, 4, 2.0)


func _texture_style_box(
	path: String, margin: int, fallback: StyleBox, content_x: float, content_y: float
) -> StyleBox:
	return CookingAssets.texture_style_box(path, margin, fallback, content_x, content_y, 6.0)


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


func _fish_material_texture(fish_id: String) -> Texture2D:
	if FISH_ICON_INDEX.has(fish_id):
		return _fish_icon(fish_id)
	return _fish_portrait(fish_id)


func _fish_row_texture(fish_id: String) -> Texture2D:
	return _fish_portrait(fish_id)


func _fish_portrait(fish_id: String) -> Texture2D:
	var asset_id := "madai" if fish_id == "tai" else fish_id
	var path := FightFishAssets.card_portrait_path({"id": asset_id})
	if ResourceLoader.exists(path) or FileAccess.file_exists(path):
		var generated_tex := load(path) as Texture2D
		if generated_tex != null:
			return generated_tex
	return _fish_icon(fish_id)


func _recipe_icon(recipe_id: String) -> Texture2D:
	var idx := 5 if recipe_id == "locked" else int(RECIPE_ICON_INDEX.get(recipe_id, 0))
	return _atlas(CookingAssets.DISH_ICON_SHEET, idx, 3, 2)


func _featured_dish_texture(recipe_id: String) -> Texture2D:
	var tex := CookingAssets.featured_dish_texture(recipe_id)
	if tex == null:
		return _recipe_icon(recipe_id)
	return tex
