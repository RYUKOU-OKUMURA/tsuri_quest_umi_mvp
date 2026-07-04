extends ScreenBase
## 調理フローの STATUS_SUMMARY。
# `reference/cooking_flow/05_status_summary_concept.png` を基準にした全画面サマリー。
signal closed

const GaugeBarScript = preload("res://src/ui/components/gauge_bar.gd")

const STATUS_SUMMARY_BG := "res://assets/showcase/cooking/status_summary_bg.png"
const STATUS_CARD_FRAME := "res://assets/showcase/cooking/status_card_frame.png"


class StatusBackdropVisual:
	extends Control

	func _draw() -> void:
		var sky := Color("#8bd3f7")
		var sea := Color("#126998")
		var wood := Color("#4a2c18")
		var wall := Color("#6a4a2b")
		draw_rect(Rect2(0.0, 78.0, size.x * 0.46, 180.0), sky)
		draw_rect(Rect2(0.0, 174.0, size.x * 0.46, 84.0), sea)
		for i in range(5):
			var x := 34.0 + float(i) * 104.0
			draw_rect(Rect2(x, 150.0 - float(i % 2) * 22.0, 24.0, 78.0), Color("#75533a"))
			draw_rect(Rect2(x - 24.0, 222.0, 86.0, 13.0), Color("#3b2618"))
		for i in range(7):
			var p := Vector2(78.0 + float(i) * 74.0, 112.0 + float(i % 3) * 11.0)
			draw_arc(p, 13.0, 0.15, PI - 0.15, 10, Color(1.0, 1.0, 1.0, 0.54), 2.0)
		draw_rect(Rect2(size.x * 0.46, 78.0, size.x * 0.54, 180.0), Color("#332015"))
		for i in range(7):
			var x := size.x * 0.49 + float(i) * 78.0
			draw_rect(Rect2(x, 100.0 + float(i % 2) * 16.0, 48.0, 80.0), wall)
			draw_rect(Rect2(x - 8.0, 94.0 + float(i % 2) * 16.0, 64.0, 10.0), wood)
		for i in range(4):
			var x := size.x * 0.63 + float(i) * 92.0
			draw_line(Vector2(x, 88.0), Vector2(x, 154.0), Color("#18110c"), 4.0)
			draw_arc(Vector2(x, 167.0), 22.0, 0.0, PI, 20, Color("#19110c"), 5.0)
		var lamp := Vector2(size.x - 116.0, 148.0)
		draw_line(lamp + Vector2(0.0, -76.0), lamp + Vector2(0.0, -20.0), Color("#20140b"), 4.0)
		draw_circle(lamp, 31.0, Color(1.0, 0.72, 0.25, 0.34))
		draw_circle(lamp, 17.0, Color(1.0, 0.82, 0.38, 0.62))
		draw_rect(Rect2(0.0, 258.0, size.x, size.y - 258.0), Color(0.03, 0.10, 0.18, 0.42))


class StatusIconVisual:
	extends Control

	const ICON_SHEET := "res://assets/showcase/cooking/cooking_icon_sheet.png"
	const PLAYER_PORTRAIT := "res://assets/showcase/cooking/player_status_portrait_pixel.png"
	const COOLER_ART := "res://assets/showcase/cooking/status_cooler_art.png"
	const MONEY_ART := "res://assets/showcase/cooking/status_money_art.png"
	const CLOCK_ART := "res://assets/showcase/cooking/status_clock_art.png"
	const ICON_CELL_SIZE := 96.0
	const USE_CUTOUT_TEXTURE_ASSETS := false

	var mode := "player"
	var accent := Color.WHITE

	func configure(next_mode: String, next_accent: Color) -> void:
		mode = next_mode.to_lower()
		accent = next_accent
		queue_redraw()

	func _draw() -> void:
		var large_asset := _large_asset_path()
		if USE_CUTOUT_TEXTURE_ASSETS and large_asset != "" and _draw_texture_asset(large_asset):
			return
		var atlas_index := _atlas_index()
		if USE_CUTOUT_TEXTURE_ASSETS and atlas_index >= 0 and _draw_atlas_icon(atlas_index):
			return
		match mode:
			"cooler":
				_draw_cooler()
			"gold":
				_draw_gold()
			"time":
				_draw_clock()
			"ready":
				_draw_ready()
			_:
				_draw_player()

	func _atlas_index() -> int:
		match mode:
			"cooler":
				return 5
			"gold":
				return 6
			"time":
				return 7
			"ready":
				return 8
			_:
				return -1

	func _large_asset_path() -> String:
		match mode:
			"cooler":
				return COOLER_ART
			"gold":
				return MONEY_ART
			"time":
				return CLOCK_ART
			_:
				return ""

	func _draw_atlas_icon(index: int) -> bool:
		var tex := load(ICON_SHEET) as Texture2D
		if tex == null:
			return false
		var side := minf(size.x, size.y)
		if side <= 0.0:
			return false
		var rect := Rect2((size - Vector2(side, side)) * 0.5, Vector2(side, side))
		var src := Rect2(float(index) * ICON_CELL_SIZE, 0.0, ICON_CELL_SIZE, ICON_CELL_SIZE)
		draw_texture_rect_region(tex, rect, src)
		return true

	func _draw_player() -> void:
		if USE_CUTOUT_TEXTURE_ASSETS and _draw_texture_asset(PLAYER_PORTRAIT):
			return
		var center := size * 0.5
		draw_ellipse(center + Vector2(0.0, 45.0), 48.0, 10.0, Color(0.0, 0.0, 0.0, 0.25))
		draw_rect(Rect2(center.x - 45.0, center.y + 5.0, 90.0, 48.0), Color("#17324d"))
		draw_rect(Rect2(center.x - 45.0, center.y + 5.0, 90.0, 9.0), Color("#2c5f8c"))
		draw_circle(center + Vector2(0.0, -22.0), 34.0, Color("#f2b889"))
		draw_rect(Rect2(center.x - 37.0, center.y - 58.0, 74.0, 17.0), Color("#1d4771"))
		draw_rect(Rect2(center.x - 26.0, center.y - 72.0, 52.0, 15.0), Color("#234f7c"))
		draw_circle(center + Vector2(-13.0, -24.0), 3.0, Color("#1d160f"))
		draw_circle(center + Vector2(13.0, -24.0), 3.0, Color("#1d160f"))
		draw_arc(center + Vector2(0.0, -12.0), 13.0, 0.12, PI - 0.12, 14, Color("#6a2a1c"), 3.0)
		draw_line(center + Vector2(-28.0, -1.0), center + Vector2(-45.0, 36.0), Color("#234f7c"), 8.0)
		draw_line(center + Vector2(28.0, -1.0), center + Vector2(45.0, 36.0), Color("#234f7c"), 8.0)

	func _draw_texture_asset(path: String) -> bool:
		var tex := load(path) as Texture2D
		if tex == null:
			return false
		var tex_size := Vector2(float(tex.get_width()), float(tex.get_height()))
		if tex_size.x <= 0.0 or tex_size.y <= 0.0 or size.x <= 0.0 or size.y <= 0.0:
			return false
		var scale := minf(size.x / tex_size.x, size.y / tex_size.y)
		var draw_size := tex_size * scale
		var rect := Rect2((size - draw_size) * 0.5, draw_size)
		draw_texture_rect(tex, rect, false)
		return true

	func _draw_ready() -> void:
		_draw_player()
		var rod_color := Color("#c9944d")
		var base := size * 0.5 + Vector2(42.0, 42.0)
		draw_line(base, base + Vector2(32.0, -92.0), rod_color, 3.0)
		draw_arc(base + Vector2(44.0, -92.0), 18.0, PI * 0.1, PI * 1.35, 16, Color("#fff1c7"), 2.0)

	func _draw_cooler() -> void:
		var center := size * 0.5
		draw_ellipse(center + Vector2(0.0, 52.0), 58.0, 10.0, Color(0.0, 0.0, 0.0, 0.25))
		draw_rect(Rect2(center.x - 58.0, center.y - 10.0, 116.0, 70.0), Color("#1b5d8d"))
		draw_rect(Rect2(center.x - 58.0, center.y - 10.0, 116.0, 17.0), Color("#eef4fa"))
		draw_rect(Rect2(center.x - 42.0, center.y - 30.0, 84.0, 22.0), Color("#d7e3ef"))
		draw_line(center + Vector2(-42.0, -19.0), center + Vector2(42.0, -19.0), Color("#6b8298"), 4.0)
		draw_rect(Rect2(center.x - 21.0, center.y + 12.0, 42.0, 19.0), Color("#f0f6fb"))
		draw_line(center + Vector2(-12.0, 47.0), center + Vector2(12.0, 47.0), Color("#083354"), 3.0)
		for i in range(4):
			draw_ellipse(center + Vector2(-34.0 + float(i) * 23.0, 2.0), 14.0, 5.0, Color("#b7c2c9"))

	func _draw_gold() -> void:
		var center := size * 0.5
		draw_ellipse(center + Vector2(0.0, 56.0), 62.0, 10.0, Color(0.0, 0.0, 0.0, 0.22))
		for i in range(10):
			var x := center.x - 46.0 + float((i * 23) % 92)
			var y := center.y + 32.0 - float(i / 3) * 16.0
			draw_circle(Vector2(x, y), 15.0, Color("#d9941f"))
			draw_circle(Vector2(x - 2.0, y - 3.0), 11.0, Color("#ffd86b"))
			draw_arc(Vector2(x, y), 12.0, 0.0, TAU, 18, Color("#8b5515"), 2.0)
		draw_rect(Rect2(center.x + 22.0, center.y - 12.0, 46.0, 58.0), Color("#7b4b20"))
		draw_rect(Rect2(center.x + 15.0, center.y - 18.0, 60.0, 13.0), Color("#b97a31"))

	func _draw_clock() -> void:
		var center := size * 0.5
		draw_ellipse(center + Vector2(0.0, 56.0), 52.0, 9.0, Color(0.0, 0.0, 0.0, 0.22))
		draw_circle(center + Vector2(0.0, 4.0), 54.0, Color("#c59035"))
		draw_circle(center + Vector2(0.0, 4.0), 46.0, Color("#fff1cf"))
		draw_arc(center + Vector2(0.0, 4.0), 47.0, 0.0, TAU, 42, Color("#5b3516"), 3.0)
		draw_line(center + Vector2(0.0, 4.0), center + Vector2(0.0, -27.0), Color("#2a2118"), 4.0)
		draw_line(center + Vector2(0.0, 4.0), center + Vector2(26.0, 20.0), Color("#2a2118"), 4.0)
		draw_circle(center + Vector2(0.0, 4.0), 5.0, Color("#2a2118"))
		draw_arc(center + Vector2(-33.0, -48.0), 16.0, PI * 0.2, PI * 1.35, 14, Color("#c59035"), 5.0)
		draw_arc(center + Vector2(33.0, -48.0), 16.0, PI * -0.35, PI * 0.8, 14, Color("#c59035"), 5.0)


class StatIconVisual:
	extends Control

	var mode := "energy"
	var accent := Color.WHITE

	func configure(next_mode: String, next_accent: Color) -> void:
		mode = next_mode
		accent = next_accent
		queue_redraw()

	func _draw() -> void:
		_draw_badge()
		match mode:
			"power":
				_draw_sword()
			"defense":
				_draw_shield()
			"speed":
				_draw_boot()
			"luck":
				_draw_clover()
			_:
				_draw_heart()

	func _draw_badge() -> void:
		var rect := Rect2(Vector2(1.0, 1.0), size - Vector2(2.0, 2.0))
		draw_rect(rect, Color("#fff1cf"))
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3.0)), Color("#f4d18f"))
		draw_line(rect.position, rect.position + Vector2(rect.size.x, 0.0), Color("#b5813a"), 1.0)
		draw_line(rect.position, rect.position + Vector2(0.0, rect.size.y), Color("#b5813a"), 1.0)
		draw_line(
			rect.position + Vector2(rect.size.x, 0.0),
			rect.position + rect.size,
			Color("#b5813a"),
			1.0
		)
		draw_line(
			rect.position + Vector2(0.0, rect.size.y),
			rect.position + rect.size,
			Color("#b5813a"),
			1.0
		)

	func _draw_heart() -> void:
		var center := size * 0.5
		var color := accent
		draw_circle(center + Vector2(-5.0, -4.0), 7.0, color)
		draw_circle(center + Vector2(5.0, -4.0), 7.0, color)
		draw_polygon(
			PackedVector2Array(
				[
					center + Vector2(-13.0, 0.0),
					center + Vector2(13.0, 0.0),
					center + Vector2(0.0, 15.0),
				]
			),
			PackedColorArray([color, color, color])
		)

	func _draw_sword() -> void:
		var center := size * 0.5
		draw_line(center + Vector2(-9.0, 11.0), center + Vector2(9.0, -11.0), accent, 5.0)
		draw_polygon(
			PackedVector2Array(
				[
					center + Vector2(11.0, -14.0),
					center + Vector2(13.0, -4.0),
					center + Vector2(3.0, -12.0),
				]
			),
			PackedColorArray([accent, accent, accent])
		)
		draw_line(center + Vector2(-13.0, 6.0), center + Vector2(-2.0, 16.0), Color("#fff1c7"), 3.0)
		draw_circle(center + Vector2(-12.0, 13.0), 3.0, Color("#7b4b20"))

	func _draw_shield() -> void:
		var center := size * 0.5
		var points := PackedVector2Array(
			[
				center + Vector2(0.0, -15.0),
				center + Vector2(14.0, -9.0),
				center + Vector2(11.0, 7.0),
				center + Vector2(0.0, 16.0),
				center + Vector2(-11.0, 7.0),
				center + Vector2(-14.0, -9.0),
			]
		)
		draw_polygon(points, PackedColorArray([accent, accent, accent, accent, accent, accent]))
		draw_line(center + Vector2(0.0, -11.0), center + Vector2(0.0, 11.0), Color("#fff1c7"), 2.0)
		draw_arc(center, 15.0, 0.0, TAU, 26, Color("#5b3516"), 2.0)

	func _draw_boot() -> void:
		var center := size * 0.5
		draw_polygon(
			PackedVector2Array(
				[
					center + Vector2(-10.0, -14.0),
					center + Vector2(1.0, -14.0),
					center + Vector2(4.0, 2.0),
					center + Vector2(16.0, 7.0),
					center + Vector2(12.0, 15.0),
					center + Vector2(-11.0, 13.0),
					center + Vector2(-7.0, 2.0),
				]
			),
			PackedColorArray([accent, accent, accent, accent, accent, accent, accent])
		)
		draw_line(center + Vector2(-8.0, 14.0), center + Vector2(14.0, 14.0), Color("#5b3516"), 3.0)
		draw_line(center + Vector2(-7.0, -5.0), center + Vector2(3.0, -5.0), Color("#fff1c7"), 2.0)

	func _draw_clover() -> void:
		var center := size * 0.5
		draw_circle(center + Vector2(-7.0, -5.0), 7.0, accent)
		draw_circle(center + Vector2(7.0, -5.0), 7.0, accent)
		draw_circle(center + Vector2(-5.0, 8.0), 7.0, accent)
		draw_circle(center + Vector2(5.0, 8.0), 7.0, accent)
		draw_line(center + Vector2(5.0, 12.0), center + Vector2(15.0, 18.0), Color("#235f33"), 3.0)


class HeaderMarkVisual:
	extends Control

	var mode := "wheel"

	func configure(next_mode: String) -> void:
		mode = next_mode
		queue_redraw()

	func _draw() -> void:
		if mode == "anchor":
			_draw_anchor()
		else:
			_draw_wheel()

	func _draw_wheel() -> void:
		var center := size * 0.5
		var gold := Palette.GOLD_BRIGHT
		draw_circle(center, 25.0, Color("#4c2b0b"))
		draw_circle(center, 20.0, Color("#10283f"))
		draw_arc(center, 24.0, 0.0, TAU, 36, gold, 3.0)
		draw_arc(center, 10.0, 0.0, TAU, 24, gold, 3.0)
		for i in range(8):
			var a := TAU * float(i) / 8.0
			var inner := center + Vector2(cos(a), sin(a)) * 9.0
			var outer := center + Vector2(cos(a), sin(a)) * 33.0
			draw_line(inner, outer, gold, 3.0)
			draw_circle(outer, 4.0, gold)

	func _draw_anchor() -> void:
		var center := size * 0.5
		var gold := Palette.GOLD_BRIGHT
		draw_arc(center + Vector2(0.0, -24.0), 9.0, 0.0, TAU, 22, gold, 3.0)
		draw_line(center + Vector2(0.0, -13.0), center + Vector2(0.0, 28.0), gold, 5.0)
		draw_line(center + Vector2(-20.0, -1.0), center + Vector2(20.0, -1.0), gold, 4.0)
		draw_arc(center + Vector2(0.0, 18.0), 28.0, 0.15, PI - 0.15, 28, gold, 4.0)
		draw_polygon(
			PackedVector2Array(
				[
					center + Vector2(-27.0, 17.0),
					center + Vector2(-40.0, 18.0),
					center + Vector2(-31.0, 30.0),
				]
			),
			PackedColorArray([gold, gold, gold])
		)
		draw_polygon(
			PackedVector2Array(
				[
					center + Vector2(27.0, 17.0),
					center + Vector2(40.0, 18.0),
					center + Vector2(31.0, 30.0),
				]
			),
			PackedColorArray([gold, gold, gold])
		)


class HeaderPlayerBadgeVisual:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var center := size * 0.5
		draw_rect(Rect2(2.0, 2.0, size.x - 4.0, size.y - 4.0), Color("#07121e"))
		draw_rect(Rect2(5.0, 5.0, size.x - 10.0, size.y - 10.0), Color("#f2e4c2"))
		draw_circle(center + Vector2(0.0, 4.0), 17.0, Color("#f2b889"))
		draw_rect(Rect2(center.x - 20.0, center.y - 17.0, 40.0, 9.0), Color("#1d4771"))
		draw_rect(Rect2(center.x - 15.0, center.y - 25.0, 30.0, 10.0), Color("#234f7c"))
		draw_circle(center + Vector2(-6.0, 3.0), 2.0, Color("#1d160f"))
		draw_circle(center + Vector2(6.0, 3.0), 2.0, Color("#1d160f"))
		draw_arc(center + Vector2(0.0, 9.0), 7.0, 0.12, PI - 0.12, 10, Color("#6a2a1c"), 2.0)
		draw_rect(Rect2(center.x - 16.0, center.y + 21.0, 32.0, 9.0), Color("#17324d"))
		draw_line(Vector2(6.0, 6.0), Vector2(size.x - 6.0, 6.0), Palette.GOLD_BRIGHT, 2.0)
		draw_line(Vector2(6.0, size.y - 6.0), Vector2(size.x - 6.0, size.y - 6.0), Palette.GOLD_BRIGHT, 2.0)


class MealEffectCueVisual:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var center := size * 0.5
		var badge := Rect2(Vector2(2.0, 4.0), size - Vector2(4.0, 8.0))
		draw_rect(badge, Color("#123924"))
		draw_rect(Rect2(badge.position + Vector2(3.0, 3.0), badge.size - Vector2(6.0, 6.0)), Color("#1e6a3a"))
		draw_line(badge.position, badge.position + Vector2(badge.size.x, 0.0), Palette.GOLD_BRIGHT, 2.0)
		draw_line(
			badge.position + Vector2(0.0, badge.size.y),
			badge.position + badge.size,
			Palette.GOLD_BRIGHT,
			2.0
		)
		var blade := Color("#dff8ff")
		draw_line(center + Vector2(-8.0, 10.0), center + Vector2(8.0, -12.0), blade, 4.0)
		draw_polygon(
			PackedVector2Array(
				[
					center + Vector2(10.0, -15.0),
					center + Vector2(13.0, -5.0),
					center + Vector2(3.0, -12.0),
				]
			),
			PackedColorArray([blade, blade, blade])
		)
		draw_line(center + Vector2(-13.0, 4.0), center + Vector2(-2.0, 15.0), Color("#ffe5a3"), 3.0)
		draw_circle(center + Vector2(-12.0, 13.0), 3.0, Color("#7b4b20"))
		for i in range(3):
			var x := center.x + 2.0 + float(i) * 8.0
			var y := center.y + 11.0 - float(i) * 8.0
			draw_line(Vector2(x, y + 8.0), Vector2(x, y - 7.0), Color("#a8f2a5"), 3.0)
			draw_polygon(
				PackedVector2Array(
					[
						Vector2(x, y - 11.0),
						Vector2(x - 5.0, y - 4.0),
						Vector2(x + 5.0, y - 4.0),
					]
				),
				PackedColorArray([Color("#a8f2a5"), Color("#a8f2a5"), Color("#a8f2a5")])
			)


var _exp_bar: GaugeBar
var _header_exp_bar: GaugeBar
var _header_level_label: Label
var _header_exp_label: Label
var _level_label: Label
var _next_exp_label: Label
var _stats_box: VBoxContainer
var _meal_badge: Label
var _meal_image: TextureRect
var _meal_name_label: Label
var _meal_effect_label: Label
var _meal_hint_label: Label
var _cooler_count_label: Label
var _money_label: Label
var _play_label: Label
var _footer_message_label: Label
var _header_panel: Control
var _footer_panel: Control
var _summary_cards: Array[Control] = []


func _build_screen() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_add_status_background()

	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 18)
	root.add_theme_constant_override("margin_top", 6)
	root.add_theme_constant_override("margin_right", 18)
	root.add_theme_constant_override("margin_bottom", 6)
	add_child(root)

	var layout := VBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 4)
	root.add_child(layout)

	_build_header(layout)
	_build_cards(layout)
	_build_footer(layout)


func _add_status_background() -> void:
	var bg_tex := load(STATUS_SUMMARY_BG) as Texture2D
	if bg_tex == null:
		bg_tex = load(CookingAssets.COOKING_BG) as Texture2D
	if bg_tex != null:
		var bg := TextureRect.new()
		bg.name = "StatusSummaryBackground"
		bg.texture = bg_tex
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg)
	else:
		add_gradient_background(Color("#17314c"), Color("#071322"))

	if not ResourceLoader.exists(STATUS_SUMMARY_BG):
		var scene := StatusBackdropVisual.new()
		scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		scene.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(scene)
		scene.queue_redraw()

	var wash := ColorRect.new()
	wash.color = Color(0.02, 0.06, 0.11, 0.34)
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wash)


func _build_header(parent: VBoxContainer) -> void:
	var header := _panel_box(Color("#0a2744"), Color("#06111e"), Palette.GOLD_BRIGHT, 5)
	_header_panel = header
	header.custom_minimum_size = Vector2(0.0, 68.0)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(header)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	header.add_child(row)

	var wheel := HeaderMarkVisual.new()
	wheel.configure("wheel")
	wheel.custom_minimum_size = Vector2(62.0, 0.0)
	row.add_child(wheel)

	var title := make_shadow_label("ステータス", 34, Palette.TEXT_BONE, 4)
	title.name = "StatusTitle"
	title.custom_minimum_size = Vector2(220.0, 0.0)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(title)

	var subtitle := make_shadow_label("調理の成果を確認できます", 18, Palette.TEXT_BONE, 2)
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(subtitle)

	var exp_box := _panel_box(Color("#10283f"), Color("#07121e"), Palette.GOLD_DEEP, 3)
	exp_box.name = "StatusHeaderExpBox"
	exp_box.custom_minimum_size = Vector2(460.0, 0.0)
	row.add_child(exp_box)
	var exp_row := HBoxContainer.new()
	exp_row.add_theme_constant_override("separation", 10)
	exp_box.add_child(exp_row)
	var player_badge := HeaderPlayerBadgeVisual.new()
	player_badge.name = "StatusHeaderPlayerBadge"
	player_badge.custom_minimum_size = Vector2(42.0, 0.0)
	exp_row.add_child(player_badge)
	_header_level_label = make_shadow_label("", 22, Palette.TEXT_BONE, 3)
	_header_level_label.name = "StatusHeaderLevel"
	_header_level_label.custom_minimum_size = Vector2(64.0, 0.0)
	_header_level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	exp_row.add_child(_header_level_label)
	var exp_title := make_shadow_label("EXP", 17, Palette.TEXT_BONE, 2)
	exp_title.custom_minimum_size = Vector2(42.0, 0.0)
	exp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exp_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	exp_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	exp_title.clip_text = true
	exp_row.add_child(exp_title)
	_header_exp_bar = GaugeBarScript.new()
	_header_exp_bar.name = "StatusHeaderExpBar"
	_header_exp_bar.show_value = false
	_header_exp_bar.custom_minimum_size = Vector2(0.0, 20.0)
	_header_exp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_header_exp_bar.set_colors(Palette.GAUGE_CYAN, Palette.GAUGE_CYAN_HI)
	exp_row.add_child(_header_exp_bar)
	_header_exp_label = make_shadow_label("", 16, Palette.TEXT_BONE, 2)
	_header_exp_label.name = "StatusHeaderExpValue"
	_header_exp_label.custom_minimum_size = Vector2(92.0, 0.0)
	_header_exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_header_exp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	exp_row.add_child(_header_exp_label)

	var anchor := HeaderMarkVisual.new()
	anchor.configure("anchor")
	anchor.custom_minimum_size = Vector2(62.0, 0.0)
	row.add_child(anchor)


func _build_cards(parent: VBoxContainer) -> void:
	var cards := HBoxContainer.new()
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("separation", 12)
	parent.add_child(cards)

	_build_player_card(cards)
	_build_meal_card(cards)
	_build_cooler_card(cards)
	_build_money_card(cards)
	_build_play_card(cards)


func _build_player_card(parent: HBoxContainer) -> void:
	var card := _status_card(parent, "プレイヤー")
	var portrait := _portrait_box("PLAYER", Palette.GAUGE_CYAN_HI)
	portrait.custom_minimum_size = Vector2(0.0, 126.0)
	card.add_child(portrait)
	_level_label = make_shadow_label("", 48, Color("#2a2118"), 2)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(_level_label)
	_next_exp_label = make_label("", 16, Color("#24486a"), 1, Color("#fff4d4"))
	_next_exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(_next_exp_label)
	_exp_bar = GaugeBarScript.new()
	_exp_bar.show_value = false
	_exp_bar.custom_minimum_size = Vector2(0.0, 18.0)
	_exp_bar.set_colors(Palette.GAUGE_CYAN, Palette.GAUGE_CYAN_HI)
	card.add_child(_exp_bar)
	_stats_box = VBoxContainer.new()
	_stats_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_stats_box.add_theme_constant_override("separation", 2)
	card.add_child(_stats_box)


func _build_meal_card(parent: HBoxContainer) -> void:
	var card := _status_card(parent, "効果中の料理")
	_meal_badge = make_shadow_label("", 18, Palette.GAUGE_GREEN_HI, 2)
	_meal_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(_meal_badge)
	_meal_image = TextureRect.new()
	_meal_image.name = "StatusMealDishImage"
	_meal_image.custom_minimum_size = Vector2(0.0, 120.0)
	_meal_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_meal_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card.add_child(_meal_image)
	_meal_name_label = make_label("", 30, Color("#2a2118"), 1, Color("#fff4d4"))
	_meal_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(_meal_name_label)
	_meal_effect_label = make_label("", 18, Palette.GAUGE_GREEN_HI, 2)
	_meal_effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_meal_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(_meal_effect_label)
	_meal_hint_label = _meal_note_box(card, "")


func _build_cooler_card(parent: HBoxContainer) -> void:
	var card := _status_card(parent, "クーラーボックス")
	var visual := _portrait_box("COOLER", Palette.GAUGE_CYAN_HI)
	visual.custom_minimum_size = Vector2(0.0, 130.0)
	card.add_child(visual)
	_cooler_count_label = make_shadow_label("", 48, Color("#2a2118"), 2)
	_cooler_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(_cooler_count_label)
	_note_box(card, "釣った魚を保存できます\n容量を増やすと、より多くの魚を持ち帰れます")
	var extend := make_button("拡張する", func() -> void: pass, 156.0, false)
	extend.custom_minimum_size = Vector2(150.0, 34.0)
	extend.disabled = true
	extend.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.add_child(extend)


func _build_money_card(parent: HBoxContainer) -> void:
	var card := _status_card(parent, "所持金")
	var visual := _portrait_box("GOLD", Palette.GOLD_BRIGHT)
	visual.custom_minimum_size = Vector2(0.0, 130.0)
	card.add_child(visual)
	_money_label = make_shadow_label("", 46, Color("#2a2118"), 2)
	_money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(_money_label)
	_note_box(card, "釣り具の購入や\nクーラーボックスの拡張に使用します")


func _build_play_card(parent: HBoxContainer) -> void:
	var card := _status_card(parent, "プレイ時間")
	var visual := _portrait_box("TIME", Palette.TEXT_BONE)
	visual.custom_minimum_size = Vector2(0.0, 130.0)
	card.add_child(visual)
	_play_label = make_shadow_label("", 40, Color("#2a2118"), 2)
	_play_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(_play_label)
	_note_box(card, "冒険の記録です\nたくさん釣って、強くなろう！")


func _build_footer(parent: VBoxContainer) -> void:
	var footer := _panel_box(Color("#08213a"), Color("#06111e"), Palette.GOLD_DEEP, 4)
	_footer_panel = footer
	footer.custom_minimum_size = Vector2(0.0, 72.0)
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(footer)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	footer.add_child(row)
	var portrait := _portrait_box("READY", Palette.GAUGE_GREEN_HI)
	portrait.custom_minimum_size = Vector2(120.0, 0.0)
	row.add_child(portrait)
	_footer_message_label = make_shadow_label("", 21, Palette.TEXT_BONE, 2)
	_footer_message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_footer_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_footer_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(_footer_message_label)
	var back := make_button("港へ戻る", _close, 190.0, true)
	back.name = "StatusReturnButton"
	back.custom_minimum_size = Vector2(206.0, 46.0)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_apply_flow_button_style(back)
	back.draw.connect(func() -> void: _draw_return_anchor(back))
	row.add_child(back)


func show_summary() -> void:
	var stats := PlayerProgress.get_base_stats()
	_header_level_label.text = "Lv.%d" % PlayerProgress.level
	_level_label.text = "Lv.%d" % PlayerProgress.level
	var next_exp := PlayerProgress.exp_to_next_level()
	if PlayerProgress.level >= GameData.MAX_LEVEL:
		_header_exp_bar.max_value = 1.0
		_header_exp_bar.set_value(1.0)
		_exp_bar.max_value = 1.0
		_exp_bar.set_value(1.0)
		_header_exp_label.text = "MAX"
		_next_exp_label.text = "EXP MAX"
	else:
		_header_exp_bar.max_value = maxf(1.0, float(next_exp))
		_header_exp_bar.set_value(float(PlayerProgress.exp))
		_exp_bar.max_value = maxf(1.0, float(next_exp))
		_exp_bar.set_value(float(PlayerProgress.exp))
		_header_exp_label.text = "%d / %d" % [PlayerProgress.exp, next_exp]
		_next_exp_label.text = "次のレベルまで %d EXP" % maxi(0, next_exp - PlayerProgress.exp)

	_clear_container(_stats_box)
	_stats_box.add_child(_stat_line("体力", "%d" % int(round(float(stats.get("max_energy", 0)))), Palette.GAUGE_RED_HI))
	_stats_box.add_child(_stat_line("攻撃力", "%.1f" % float(stats.get("reel_power", 0)), Palette.GAUGE_CYAN_HI))
	_stats_box.add_child(_stat_line("防御力", "%d" % int(stats.get("technique", 0)), Palette.GOLD_BRIGHT))
	_stats_box.add_child(_stat_line("素早さ", "%d" % int(stats.get("focus", 0)), Color("#b98cff")))
	_stats_box.add_child(_stat_line("運", "%d" % (PlayerProgress.level + _owned_fish_kinds() + 5), Palette.GAUGE_GREEN_HI))

	if PlayerProgress.pending_buff.is_empty():
		_meal_badge.text = "効果なし"
		_meal_image.texture = null
		_meal_name_label.text = "料理なし"
		_meal_effect_label.text = "次の料理で準備"
		_meal_hint_label.text = "魚を料理すると\n次の釣行で効果が発動します"
	else:
		var recipe_id := String(PlayerProgress.pending_buff.get("recipe_id", ""))
		_meal_badge.text = "効果中！ あと 1回"
		_meal_image.texture = _meal_texture(recipe_id)
		_meal_name_label.text = String(PlayerProgress.pending_buff.get("name", "料理"))
		_meal_effect_label.text = _effect_summary(String(PlayerProgress.pending_buff.get("text", "")))
		_meal_hint_label.text = "次回の釣行で\n%s" % _effect_sentence(String(PlayerProgress.pending_buff.get("text", "")))

	_cooler_count_label.text = "%d / 20" % _total_fish_count()
	_money_label.text = "%d G" % PlayerProgress.money
	_play_label.text = format_play_time(PlayerProgress.play_seconds)
	if PlayerProgress.level >= GameData.BOSS_UNLOCK_LEVEL:
		_footer_message_label.text = (
			"Lv.%d到達！ 港のぬしに挑めます！\n"
			+ "効果中の料理を活かして、次の釣りへ向かおう！"
		) % PlayerProgress.level
	else:
		_footer_message_label.text = "うまい料理で力がみなぎってきた！\n次の釣りもがんばろう！"
	_present()


func _status_card(parent: HBoxContainer, title: String) -> VBoxContainer:
	var panel := _texture_panel_box(
		STATUS_CARD_FRAME,
		24,
		_style_box(Color("#f2e4c2"), Color("#60401f"), Palette.GOLD_BRIGHT, 5, 5),
		14.0,
		12.0
	)
	panel.name = _status_card_node_name(title)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0.0, 0.0)
	parent.add_child(panel)
	_summary_cards.append(panel)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	var title_band := _texture_panel_box(
		CookingAssets.FLOW_ACTION_BUTTON_FRAME,
		24,
		_style_box(Color("#102f51"), Palette.GOLD_DEEP, Palette.GOLD_BRIGHT, 4, 4),
		20.0,
		5.0
	)
	title_band.custom_minimum_size = Vector2(0.0, 36.0)
	title_band.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(title_band)

	var title_label := make_shadow_label(title, 21, Palette.TEXT_BONE, 3)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.custom_minimum_size = Vector2(0.0, 26.0)
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	title_band.add_child(title_label)
	return box


func _status_card_node_name(title: String) -> String:
	match title:
		"プレイヤー":
			return "StatusCardPlayer"
		"効果中の料理":
			return "StatusCardMeal"
		"クーラーボックス":
			return "StatusCardCooler"
		"所持金":
			return "StatusCardMoney"
		"プレイ時間":
			return "StatusCardPlayTime"
		_:
			return "StatusCard"


func _portrait_box(text: String, accent: Color) -> PanelContainer:
	var panel := _panel_box(Color("#10283f"), Color("#07121e"), accent, 3)
	panel.add_theme_stylebox_override(
		"panel",
		_style_box(Color("#0c263f"), Color("#07121e"), accent, 3, 4, 10.0, 8.0)
	)
	var visual := _status_texture_visual(text)
	if visual == null:
		visual = StatusIconVisual.new()
		(visual as StatusIconVisual).configure(text, accent)
	visual.name = _status_visual_name(text)
	visual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	visual.size_flags_vertical = Control.SIZE_EXPAND_FILL
	visual.custom_minimum_size = Vector2(0.0, 48.0)
	panel.add_child(visual)
	return panel


func _status_texture_visual(text: String) -> Control:
	var path := ""
	match text.to_upper():
		"PLAYER":
			path = StatusIconVisual.PLAYER_PORTRAIT
		"READY":
			path = StatusIconVisual.PLAYER_PORTRAIT
		"COOLER":
			path = StatusIconVisual.COOLER_ART
		"GOLD":
			path = StatusIconVisual.MONEY_ART
		"TIME":
			path = StatusIconVisual.CLOCK_ART
		_:
			return null
	var visual := TextureRect.new()
	visual.texture = load(path) as Texture2D
	visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	visual.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return visual


func _status_visual_name(text: String) -> String:
	match text.to_upper():
		"COOLER":
			return "StatusCoolerArt"
		"GOLD":
			return "StatusMoneyArt"
		"TIME":
			return "StatusClockArt"
		"PLAYER":
			return "StatusPlayerPortrait"
		"READY":
			return "StatusReadyVisual"
		_:
			return "StatusVisual"


func _note_box(parent: VBoxContainer, text: String) -> Label:
	var panel := _panel_box(Color("#fff1cf"), Color("#b5813a"), Color("#e0b667"), 2)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0.0, 76.0)
	parent.add_child(panel)
	var label := make_label(text, 15, Color("#3f2d1a"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(label)
	return label


func _meal_note_box(parent: VBoxContainer, text: String) -> Label:
	var panel := _panel_box(Color("#fff1cf"), Color("#b5813a"), Color("#e0b667"), 2)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0.0, 78.0)
	parent.add_child(panel)

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	var cue := MealEffectCueVisual.new()
	cue.name = "StatusMealEffectCue"
	cue.custom_minimum_size = Vector2(34.0, 34.0)
	cue.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(cue)

	var label := make_label(text, 15, Color("#3f2d1a"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	return label


func _stat_line(title: String, value: String, accent: Color) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0.0, 28.0)
	row.add_theme_constant_override("separation", 8)
	var icon := StatIconVisual.new()
	icon.configure(_stat_icon_mode(title), accent)
	icon.custom_minimum_size = Vector2(32.0, 26.0)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var name := make_label(title, 17, Color("#2a2118"))
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(name)
	var amount := make_label(value, 17, Color("#2a2118"), 1, Color("#fff4d4"))
	amount.custom_minimum_size = Vector2(46.0, 0.0)
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(amount)
	return row


func _stat_icon_mode(title: String) -> String:
	match title:
		"攻撃力":
			return "power"
		"防御力":
			return "defense"
		"素早さ":
			return "speed"
		"運":
			return "luck"
		_:
			return "energy"


func _apply_flow_button_style(button: Button) -> void:
	CookingAssets.apply_flow_button_style(button, 54.0, 5.0)


func _draw_return_anchor(button: Button) -> void:
	var center := Vector2(28.0, button.size.y * 0.5 + 1.0)
	var gold := Palette.GOLD_BRIGHT
	button.draw_arc(center + Vector2(0.0, -13.0), 6.0, 0.0, TAU, 18, gold, 2.0)
	button.draw_line(center + Vector2(0.0, -6.0), center + Vector2(0.0, 14.0), gold, 4.0)
	button.draw_line(center + Vector2(-12.0, 1.0), center + Vector2(12.0, 1.0), gold, 3.0)
	button.draw_arc(center + Vector2(0.0, 8.0), 17.0, 0.14, PI - 0.14, 22, gold, 3.0)
	button.draw_polygon(
		PackedVector2Array(
			[
				center + Vector2(-16.0, 8.0),
				center + Vector2(-24.0, 9.0),
				center + Vector2(-18.0, 17.0),
			]
		),
		PackedColorArray([gold, gold, gold])
	)
	button.draw_polygon(
		PackedVector2Array(
			[
				center + Vector2(16.0, 8.0),
				center + Vector2(24.0, 9.0),
				center + Vector2(18.0, 17.0),
			]
		),
		PackedColorArray([gold, gold, gold])
	)


func _effect_summary(text: String) -> String:
	if text.contains("最大体力"):
		return "効果：体力アップ【中】"
	if text.contains("巻"):
		return "効果：攻撃力アップ【中】"
	return "効果：釣行サポート【中】"


func _effect_sentence(text: String) -> String:
	var cleaned := text
	if cleaned.begins_with("次の釣行で"):
		cleaned = cleaned.trim_prefix("次の釣行で")
	return cleaned


func _present() -> void:
	modulate.a = 1.0
	await get_tree().process_frame
	if is_qa_deterministic():
		return
	_prepare_entry_part(_header_panel, -12.0)
	for card in _summary_cards:
		_prepare_entry_part(card, 18.0)
	_prepare_entry_part(_footer_panel, 0.0)
	_animate_entry_part(_header_panel, 0.02, -12.0)
	for i in range(_summary_cards.size()):
		_animate_entry_part(_summary_cards[i], 0.05 + float(i) * 0.025, 18.0)
	_animate_entry_part(_footer_panel, 0.20, 0.0)


func _prepare_entry_part(part: Control, offset_y: float) -> void:
	if part == null:
		return
	part.modulate.a = 1.0
	part.position.y += offset_y


func _animate_entry_part(part: Control, delay: float, offset_y: float) -> void:
	if part == null:
		return
	var target_y := part.position.y - offset_y
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.tween_interval(delay)
	tw.tween_property(part, "position:y", target_y, 0.22)


func _close() -> void:
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "modulate:a", 0.0, 0.12)
	tw.tween_callback(
		func() -> void:
			closed.emit()
			queue_free()
	)


func preview_accept() -> void:
	if is_qa_deterministic():
		closed.emit()
		queue_free()
		return
	_close()


func _total_fish_count() -> int:
	var total := 0
	for fish_id in GameData.get_all_fish_ids():
		total += PlayerProgress.fish_count(fish_id)
	return total


func _owned_fish_kinds() -> int:
	var kinds := 0
	for fish_id in GameData.get_all_fish_ids():
		if PlayerProgress.fish_count(fish_id) > 0:
			kinds += 1
	return kinds


func _clear_container(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _panel_box(fill: Color, border: Color, inner: Color, border_width: int) -> PanelContainer:
	return CookingAssets.panel_box(fill, border, inner, border_width)


func _texture_panel_box(
	path: String, margin: int, fallback: StyleBox, content_x: float, content_y: float
) -> PanelContainer:
	return CookingAssets.texture_panel_box(path, margin, fallback, content_x, content_y, 5.0)


func _style_box(
	fill: Color,
	border: Color,
	inner: Color,
	border_width: int,
	radius: int,
	content_x: float = 14.0,
	content_y: float = 10.0
) -> StyleBoxFlat:
	return CookingAssets.style_box(fill, border, inner, border_width, radius, content_x, content_y)


func _meal_texture(recipe_id: String) -> Texture2D:
	var tex := CookingAssets.featured_dish_texture(recipe_id)
	if tex == null:
		return _recipe_icon(recipe_id)
	return tex


func _recipe_icon(recipe_id: String) -> Texture2D:
	var icon_index := 0
	match recipe_id:
		"sashimi":
			icon_index = 1
		"simmered":
			icon_index = 2
		"soup":
			icon_index = 3
		"fry":
			icon_index = 4
	var tex := load(CookingAssets.DISH_ICON_SHEET) as Texture2D
	if tex == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	var cell_w := float(tex.get_width()) / 3.0
	var cell_h := float(tex.get_height()) / 2.0
	atlas.region = Rect2(float(icon_index % 3) * cell_w, float(int(icon_index / 3)) * cell_h, cell_w, cell_h)
	return atlas


func _texture_style_box(
	path: String, margin: int, fallback: StyleBox, content_x: float, content_y: float
) -> StyleBox:
	return CookingAssets.texture_style_box(path, margin, fallback, content_x, content_y, 5.0)
