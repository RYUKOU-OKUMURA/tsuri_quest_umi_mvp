extends ScreenBase
## 調理フローの LEVEL_UP_OVERLAY。
# レベル遷移、能力上昇、Lv.5 解放を一画面の報酬ピークとして見せる。
signal closed

const LEVEL_UP_FRAME := "res://assets/showcase/cooking/level_up_frame.png"
const LEVEL_UNLOCK_RIBBON := "res://assets/showcase/cooking/level_unlock_ribbon.png"
const LEVEL_STAT_ROW_FRAME := "res://assets/showcase/cooking/level_stat_row_frame.png"


class LevelUpVisual:
	extends Control

	const CROWN_ASSET := "res://assets/showcase/cooking/level_crown.png"
	const LAUREL_LEFT_ASSET := "res://assets/showcase/cooking/level_laurel_left.png"
	const LAUREL_RIGHT_ASSET := "res://assets/showcase/cooking/level_laurel_right.png"
	const UNLOCK_MEDALLION_ASSET := "res://assets/showcase/cooking/level_unlock_medallion.png"
	const UNLOCK_SPOT_ASSET := "res://assets/showcase/cooking/level_unlock_spot.png"
	const USE_CUTOUT_TEXTURE_ASSETS := false

	var mode := "crown"

	func configure(next_mode: String) -> void:
		mode = next_mode
		queue_redraw()

	func _draw() -> void:
		match mode:
			"laurel_left":
				if USE_CUTOUT_TEXTURE_ASSETS and _draw_texture_asset(LAUREL_LEFT_ASSET):
					return
				_draw_laurel(-1.0)
			"laurel_right":
				if USE_CUTOUT_TEXTURE_ASSETS and _draw_texture_asset(LAUREL_RIGHT_ASSET):
					return
				_draw_laurel(1.0)
			"medal":
				if USE_CUTOUT_TEXTURE_ASSETS and _draw_texture_asset(UNLOCK_MEDALLION_ASSET):
					return
				_draw_medal()
			"spot":
				if USE_CUTOUT_TEXTURE_ASSETS and _draw_texture_asset(UNLOCK_SPOT_ASSET):
					return
				_draw_spot()
			_:
				if USE_CUTOUT_TEXTURE_ASSETS and _draw_texture_asset(CROWN_ASSET):
					return
				_draw_crown()

	func _draw_texture_asset(path: String) -> bool:
		var tex := load(path) as Texture2D
		if tex == null:
			return false
		var tex_size := Vector2(float(tex.get_width()), float(tex.get_height()))
		if tex_size.x <= 0.0 or tex_size.y <= 0.0:
			return false
		var scale := minf(size.x / tex_size.x, size.y / tex_size.y)
		var draw_size := tex_size * scale
		var rect := Rect2((size - draw_size) * 0.5, draw_size)
		draw_texture_rect(tex, rect, false)
		return true

	func _draw_crown() -> void:
		var center := size * 0.5
		var gold := Palette.COOKING_LEVEL_CROWN_GOLD
		var deep := Palette.COOKING_LEVEL_CROWN_DEEP
		var points := PackedVector2Array(
			[
				center + Vector2(-58.0, 10.0),
				center + Vector2(-41.0, -22.0),
				center + Vector2(-18.0, 2.0),
				center + Vector2(0.0, -31.0),
				center + Vector2(18.0, 2.0),
				center + Vector2(41.0, -22.0),
				center + Vector2(58.0, 10.0),
			]
		)
		var fill_points := PackedVector2Array(points)
		fill_points.append(center + Vector2(48.0, 26.0))
		fill_points.append(center + Vector2(-48.0, 26.0))
		draw_polygon(fill_points, PackedColorArray([deep, deep, deep, deep, deep, deep, deep, deep, deep]))
		draw_polyline(points, Palette.COOKING_LEVEL_DARK_INK, 9.0)
		draw_polyline(points, gold, 4.0)
		draw_rect(Rect2(center.x - 54.0, center.y + 10.0, 108.0, 18.0), Palette.COOKING_LEVEL_DARK_INK)
		draw_rect(Rect2(center.x - 48.0, center.y + 12.0, 96.0, 12.0), gold)
		for i in range(points.size()):
			var p := points[i]
			draw_circle(p, 7.0, Palette.COOKING_LEVEL_IVORY)
			draw_circle(p, 4.0, Palette.GAUGE_RED_HI if i % 2 == 0 else Palette.GAUGE_CYAN_HI)
		for i in range(5):
			var x := center.x - 32.0 + float(i) * 16.0
			draw_line(Vector2(x, center.y + 14.0), Vector2(x, center.y + 24.0), deep, 2.0)

	func _draw_laurel(direction: float) -> void:
		var center := size * 0.5
		var stem := Palette.COOKING_LEVEL_CROWN_DEEP
		var leaf := Palette.GOLD_BRIGHT
		var points := PackedVector2Array()
		for i in range(9):
			var t := float(i) / 8.0
			var y := center.y + 40.0 - t * 78.0
			var x := center.x + direction * (34.0 - sin(t * PI) * 30.0)
			points.append(Vector2(x, y))
		draw_polyline(points, stem, 4.0)
		for i in range(points.size()):
			var p := points[i]
			var len := 16.0 + float(i % 3) * 2.0
			var outward := Vector2(direction * len, -8.0)
			var inward := Vector2(-direction * 6.0, -5.0)
			draw_polygon(
				PackedVector2Array([p, p + outward, p + inward]),
				PackedColorArray([leaf, leaf, Palette.COOKING_LEVEL_IVORY])
			)
			draw_line(p, p + outward * 0.72, Palette.COOKING_LEVEL_IVORY, 1.0)

	func _draw_medal() -> void:
		var center := size * 0.5
		draw_polygon(
			PackedVector2Array(
				[
					center + Vector2(-24.0, -56.0),
					center + Vector2(-2.0, -24.0),
					center + Vector2(24.0, -56.0),
					center + Vector2(14.0, -16.0),
					center + Vector2(-14.0, -16.0),
				]
			),
			PackedColorArray([Palette.COOKING_LEVEL_RIBBON_FILL, Palette.COOKING_LEVEL_RIBBON_FILL, Palette.COOKING_LEVEL_RIBBON_FILL, Palette.COOKING_LEVEL_RIBBON_DEEP, Palette.COOKING_LEVEL_RIBBON_DEEP])
		)
		draw_circle(center, 48.0, Palette.COOKING_LEVEL_DARK_INK)
		draw_circle(center, 42.0, Palette.COOKING_LEVEL_MEDAL_EDGE)
		draw_circle(center, 34.0, Palette.COOKING_LEVEL_MEDAL_GOLD)
		draw_circle(center, 25.0, Palette.COOKING_LEVEL_IVORY)
		for i in range(14):
			var a := TAU * float(i) / 14.0
			var from := center + Vector2(cos(a), sin(a)) * 36.0
			var to := center + Vector2(cos(a), sin(a)) * 48.0
			draw_line(from, to, Palette.COOKING_LEVEL_CROWN_GOLD, 3.0)
		draw_arc(center, 42.0, 0.0, TAU, 48, Palette.COOKING_LEVEL_CROWN_GOLD, 3.0)
		draw_ellipse(center + Vector2(-2.0, 0.0), 20.0, 11.0, Palette.COOKING_LEVEL_MEDAL_FISH)
		draw_polygon(
			PackedVector2Array(
				[
					center + Vector2(17.0, -1.0),
					center + Vector2(34.0, -11.0),
					center + Vector2(34.0, 10.0),
				]
			),
			PackedColorArray([Palette.COOKING_LEVEL_MEDAL_FISH, Palette.COOKING_LEVEL_MEDAL_FISH, Palette.COOKING_LEVEL_MEDAL_FISH])
		)
		draw_circle(center + Vector2(-13.0, -2.0), 3.0, Palette.COOKING_LEVEL_IVORY)
		draw_line(center + Vector2(-12.0, 19.0), center + Vector2(14.0, 19.0), Palette.COOKING_LEVEL_MEDAL_LINE, 3.0)

	func _draw_spot() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Palette.COOKING_LEVEL_SPOT_SEA)
		draw_rect(Rect2(0.0, 0.0, size.x, size.y * 0.42), Palette.COOKING_LEVEL_SPOT_SKY)
		draw_rect(Rect2(0.0, size.y * 0.55, size.x, size.y * 0.45), Palette.COOKING_LEVEL_SPOT_WATER)
		draw_polygon(
			PackedVector2Array(
				[
					Vector2(size.x * 0.48, size.y * 0.18),
					Vector2(size.x * 0.68, size.y * 0.74),
					Vector2(size.x * 0.26, size.y * 0.74),
				]
			),
			PackedColorArray([Palette.COOKING_LEVEL_SPOT_ROCK, Palette.COOKING_LEVEL_SPOT_ROCK, Palette.COOKING_LEVEL_SPOT_ROCK])
		)
		draw_rect(Rect2(size.x * 0.70, size.y * 0.26, 18.0, size.y * 0.42), Palette.COOKING_LEVEL_IVORY)
		draw_rect(Rect2(size.x * 0.67, size.y * 0.22, 24.0, 10.0), Palette.COOKING_LEVEL_SPOT_LIGHTHOUSE)
		draw_circle(Vector2(size.x * 0.79, size.y * 0.20), 5.0, Palette.COOKING_LEVEL_CROWN_GOLD)
		for i in range(3):
			var y := size.y * 0.70 + float(i) * 10.0
			draw_line(Vector2(12.0, y), Vector2(size.x - 12.0, y - 6.0), Palette.COOKING_LEVEL_SPOT_WAKE, 2.0)


class LevelStatIconVisual:
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
			"reel":
				_draw_reel()
			"technique":
				_draw_sword()
			"focus":
				_draw_target()
			_:
				_draw_heart()

	func _draw_badge() -> void:
		var center := size * 0.5
		draw_circle(center, 23.0, Palette.COOKING_LEVEL_BADGE_DARK)
		draw_circle(center, 20.0, accent.darkened(0.20))
		draw_arc(center, 21.0, 0.0, TAU, 36, Palette.GOLD_BRIGHT, 2.0)
		draw_circle(center + Vector2(-6.0, -7.0), 5.0, Palette.COOKING_LEVEL_BADGE_SHINE)

	func _draw_heart() -> void:
		var center := size * 0.5
		var color := Palette.GAUGE_RED_HI
		draw_circle(center + Vector2(-6.0, -5.0), 7.0, color)
		draw_circle(center + Vector2(6.0, -5.0), 7.0, color)
		draw_polygon(
			PackedVector2Array(
				[
					center + Vector2(-14.0, 0.0),
					center + Vector2(14.0, 0.0),
					center + Vector2(0.0, 15.0),
				]
			),
			PackedColorArray([color, color, color])
		)

	func _draw_reel() -> void:
		var center := size * 0.5
		var color := Palette.GAUGE_CYAN_HI
		draw_arc(center, 14.0, 0.0, TAU, 30, color, 4.0)
		draw_circle(center, 5.0, Palette.COOKING_LEVEL_IVORY)
		for i in range(4):
			var a := TAU * float(i) / 4.0 + 0.35
			draw_line(center, center + Vector2(cos(a), sin(a)) * 15.0, color, 3.0)
		draw_circle(center + Vector2(19.0, 0.0), 4.0, Palette.GOLD_BRIGHT)

	func _draw_sword() -> void:
		var center := size * 0.5
		var color := Palette.GOLD_BRIGHT
		draw_line(center + Vector2(-10.0, 12.0), center + Vector2(10.0, -13.0), color, 5.0)
		draw_polygon(
			PackedVector2Array(
				[
					center + Vector2(12.0, -16.0),
					center + Vector2(15.0, -5.0),
					center + Vector2(4.0, -13.0),
				]
			),
			PackedColorArray([color, color, color])
		)
		draw_line(center + Vector2(-15.0, 5.0), center + Vector2(-3.0, 16.0), Palette.COOKING_LEVEL_IVORY, 3.0)
		draw_circle(center + Vector2(-13.0, 13.0), 3.0, Palette.COOKING_LEVEL_MEDAL_EDGE)

	func _draw_target() -> void:
		var center := size * 0.5
		var color := Palette.COOKING_LEVEL_FOCUS_ACCENT
		draw_arc(center, 15.0, 0.0, TAU, 30, color, 3.0)
		draw_arc(center, 8.0, 0.0, TAU, 24, color, 2.0)
		draw_line(center + Vector2(-17.0, 0.0), center + Vector2(17.0, 0.0), color, 3.0)
		draw_line(center + Vector2(0.0, -17.0), center + Vector2(0.0, 17.0), color, 3.0)
		draw_circle(center, 4.0, Palette.GOLD_BRIGHT)


class LevelCenteredTextVisual:
	extends Control

	var text := ""
	var font_size := 18
	var text_color := Palette.TEXT_BONE
	var shadow_color := Palette.COOKING_LEVEL_TEXT_SHADOW

	func configure(next_text: String, next_font_size: int, next_color: Color, next_shadow: Color) -> void:
		text = next_text
		font_size = next_font_size
		text_color = next_color
		shadow_color = next_shadow
		queue_redraw()

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if text.strip_edges().is_empty():
			return
		var font := get_theme_default_font()
		if font == null:
			return
		var baseline_y := size.y * 0.5 + float(font_size) * 0.36
		if shadow_color.a > 0.0:
			draw_string(
				font,
				Vector2(2.0, baseline_y + 2.0),
				text,
				HORIZONTAL_ALIGNMENT_CENTER,
				size.x,
				font_size,
				shadow_color
			)
		draw_string(
			font,
			Vector2(0.0, baseline_y),
			text,
			HORIZONTAL_ALIGNMENT_CENTER,
			size.x,
			font_size,
			text_color
		)


class LevelStatTextVisual:
	extends Control

	var name_text := ""
	var values_text := ""
	var gain_text := ""
	var gain_color := Palette.GAUGE_GREEN_HI

	func configure(next_name: String, next_values: String, next_gain: String, next_gain_color: Color) -> void:
		name_text = next_name
		values_text = next_values
		gain_text = next_gain
		gain_color = next_gain_color
		queue_redraw()

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var font := get_theme_default_font()
		if font == null:
			return
		var baseline_y := size.y * 0.5 + 7.0
		var shadow := Palette.COOKING_LEVEL_STAT_TEXT_SHADOW
		_draw_text(font, Vector2(62.0, baseline_y), name_text, 17, Palette.TEXT_BONE, shadow, HORIZONTAL_ALIGNMENT_LEFT, 108.0)
		_draw_text(
			font,
			Vector2(156.0, baseline_y + 1.0),
			values_text,
			21,
			Palette.TEXT_BONE,
			shadow,
			HORIZONTAL_ALIGNMENT_CENTER,
			maxf(120.0, size.x - 244.0)
		)
		_draw_text(
			font,
			Vector2(size.x - 72.0, baseline_y),
			gain_text,
			19,
			gain_color,
			shadow,
			HORIZONTAL_ALIGNMENT_RIGHT,
			58.0
		)

	func _draw_text(
		font: Font,
		pos: Vector2,
		value: String,
		draw_font_size: int,
		color: Color,
		shadow: Color,
		alignment: HorizontalAlignment,
		width: float
	) -> void:
		if value.strip_edges().is_empty():
			return
		draw_string(font, pos + Vector2(1.5, 1.5), value, alignment, width, draw_font_size, shadow)
		draw_string(font, pos, value, alignment, width, draw_font_size, color)


class LevelToSummaryCueVisual:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := maxf(size.x, 1.0)
		var h := maxf(size.y, 1.0)
		var cy := h * 0.50
		var start_x := 10.0
		var end_x := w - 14.0
		var gold := Palette.GOLD_BRIGHT
		var glow := Palette.COOKING_LEVEL_IVORY
		glow.a = 0.24
		draw_line(Vector2(start_x, cy), Vector2(end_x, cy), glow, 7.0)
		draw_line(Vector2(start_x, cy), Vector2(end_x, cy), gold, 2.0)
		draw_polygon(
			PackedVector2Array(
				[
					Vector2(end_x + 7.0, cy),
					Vector2(end_x - 4.0, cy - 6.0),
					Vector2(end_x - 4.0, cy + 6.0),
				]
			),
			PackedColorArray([gold, gold, gold])
		)
		var card_count := 5
		var span := maxf(1.0, w - 88.0)
		for i in range(card_count):
			var x := 42.0 + span * float(i) / float(card_count - 1)
			_draw_summary_card(Vector2(x, cy), i)

	func _draw_summary_card(center: Vector2, index: int) -> void:
		var rect := Rect2(center.x - 14.0, center.y - 12.0, 28.0, 24.0)
		draw_rect(rect.grow(2.0), Palette.COOKING_LEVEL_BADGE_DARK)
		draw_rect(rect, Palette.COOKING_LEVEL_SUMMARY_CARD_FILL)
		draw_line(rect.position + Vector2(2.0, 4.0), rect.position + Vector2(rect.size.x - 2.0, 4.0), Palette.COOKING_LEVEL_SUMMARY_CARD_HEAD, 4.0)
		match index:
			0:
				_draw_mini_player(center)
			1:
				_draw_mini_meal(center)
			2:
				_draw_mini_cooler(center)
			3:
				_draw_mini_coin(center)
			_:
				_draw_mini_clock(center)

	func _draw_mini_player(center: Vector2) -> void:
		draw_circle(center + Vector2(0.0, -2.0), 5.0, Palette.COOKING_LEVEL_MINI_PLAYER_SKIN)
		draw_rect(Rect2(center.x - 7.0, center.y + 4.0, 14.0, 6.0), Palette.COOKING_LEVEL_MINI_PLAYER_BODY)

	func _draw_mini_meal(center: Vector2) -> void:
		draw_arc(center + Vector2(0.0, 5.0), 8.0, 0.0, PI, 12, Palette.COOKING_LEVEL_MINI_MEAL_FILL, 3.0)
		draw_arc(center + Vector2(0.0, 2.0), 6.0, 0.0, PI, 10, Palette.COOKING_LEVEL_IVORY, 2.0)

	func _draw_mini_cooler(center: Vector2) -> void:
		draw_rect(Rect2(center.x - 8.0, center.y - 2.0, 16.0, 10.0), Palette.COOKING_LEVEL_MINI_COOLER_BODY)
		draw_rect(Rect2(center.x - 8.0, center.y - 2.0, 16.0, 3.0), Palette.COOKING_LEVEL_MINI_COOLER_LID)

	func _draw_mini_coin(center: Vector2) -> void:
		draw_circle(center + Vector2(-3.0, 2.0), 6.0, Palette.GOLD_BRIGHT)
		draw_circle(center + Vector2(4.0, -1.0), 5.0, Palette.COOKING_LEVEL_MEDAL_GOLD)

	func _draw_mini_clock(center: Vector2) -> void:
		draw_circle(center, 7.0, Palette.COOKING_LEVEL_IVORY)
		draw_arc(center, 7.0, 0.0, TAU, 18, Palette.COOKING_LEVEL_MEDAL_LINE, 1.5)
		draw_line(center, center + Vector2(0.0, -5.0), Palette.COOKING_LEVEL_MEDAL_LINE, 1.5)
		draw_line(center, center + Vector2(4.0, 2.0), Palette.COOKING_LEVEL_MEDAL_LINE, 1.5)


var _dialog: PanelContainer
var _level_line: Label
var _stats_box: GridContainer
var _unlock_card: PanelContainer
var _unlock_ribbon: PanelContainer
var _unlock_ribbon_label: Label
var _unlock_ribbon_visual: LevelCenteredTextVisual
var _unlock_tag: Label
var _unlock_title: Label
var _unlock_body: Label
var _spot_tag: Label
var _spot_title: Label
var _spot_subtitle: Label
var _confirm_button: Button
var _confirm_cue: Label


func _build_screen() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.name = "LevelUpDimmer"
	dim.color = Palette.COOKING_LEVEL_DIM
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	_add_burst_layer()
	_add_confetti_layer()

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_dialog = PanelContainer.new()
	_dialog.name = "LevelUpDialog"
	_dialog.custom_minimum_size = Vector2(1100.0, 590.0)
	_dialog.add_theme_stylebox_override(
		"panel",
		_texture_style_box(
			LEVEL_UP_FRAME,
			36,
			_style_box(Palette.COOKING_LEVEL_DIALOG_FILL, Palette.COOKING_LEVEL_MEDAL_EDGE, Palette.GOLD_BRIGHT, 6, 8),
			22.0,
			8.0
		)
	)
	center.add_child(_dialog)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 4)
	_dialog.add_child(box)

	var title_band := _panel_box(
		Palette.COOKING_LEVEL_SUMMARY_CARD_HEAD,
		Palette.COOKING_LEVEL_MEDAL_EDGE,
		Palette.GOLD_BRIGHT,
		4
	)
	title_band.name = "LevelUpTitleBand"
	title_band.custom_minimum_size = Vector2(1000.0, 172.0)
	title_band.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(title_band)
	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", 8)
	title_band.add_child(title_row)

	var left_laurel := _level_asset_texture(
		"LevelLaurelLeftAsset", LevelUpVisual.LAUREL_LEFT_ASSET, Vector2(160.0, 136.0)
	)
	title_row.add_child(left_laurel)

	var title_stack := VBoxContainer.new()
	title_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	title_stack.add_theme_constant_override("separation", 0)
	title_stack.custom_minimum_size = Vector2(650.0, 160.0)
	title_row.add_child(title_stack)

	var crown_visual := _level_asset_texture(
		"LevelCrownAsset", LevelUpVisual.CROWN_ASSET, Vector2(210.0, 44.0)
	)
	crown_visual.stretch_mode = TextureRect.STRETCH_SCALE
	crown_visual.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	title_stack.add_child(crown_visual)
	var crown_label := make_shadow_label("成長の証", 13, Palette.GOLD_BRIGHT, 2)
	_set_label_min_height(crown_label, 13)
	crown_label.custom_minimum_size.x = 180.0
	crown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_stack.add_child(crown_label)

	var title := make_shadow_label("LEVEL UP!", 64, Palette.GOLD_BRIGHT, 4, Palette.COOKING_LEVEL_DARK_INK)
	title.name = "LevelUpTitle"
	title.z_index = 2
	title.add_theme_font_override("font", GameFontsScript.extra_bold(get_theme_default_font()))
	_set_label_min_height(title, 64)
	title.custom_minimum_size = Vector2(650.0, maxf(title.custom_minimum_size.y, 92.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	title.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	title.clip_text = false
	title_stack.add_child(title)

	var right_laurel := _level_asset_texture(
		"LevelLaurelRightAsset", LevelUpVisual.LAUREL_RIGHT_ASSET, Vector2(160.0, 136.0)
	)
	title_row.add_child(right_laurel)

	_level_line = make_shadow_label("", 42, Palette.GOLD_BRIGHT, 4, Palette.COOKING_LEVEL_DARK_INK)
	_level_line.name = "LevelUpLevelLine"
	_level_line.add_theme_font_override("font", GameFontsScript.extra_bold(get_theme_default_font()))
	_set_label_min_height(_level_line, 42)
	_level_line.custom_minimum_size = Vector2(520.0, maxf(_level_line.custom_minimum_size.y, 58.0))
	_level_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_line.autowrap_mode = TextServer.AUTOWRAP_OFF
	_level_line.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	box.add_child(_level_line)

	var source_line := make_label("食経験値が成長に変わった", 16, Palette.GAUGE_GREEN_HI)
	source_line.name = "LevelUpSourceLine"
	source_line.z_index = 2
	_set_label_min_height(source_line, 16)
	source_line.custom_minimum_size = Vector2(360.0, maxf(source_line.custom_minimum_size.y, 24.0))
	source_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(source_line)

	_stats_box = GridContainer.new()
	_stats_box.columns = 2
	_stats_box.add_theme_constant_override("h_separation", 10)
	_stats_box.add_theme_constant_override("v_separation", 5)
	_stats_box.custom_minimum_size = Vector2(880.0, 0.0)
	_stats_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_stats_box)

	_unlock_card = _panel_box(Palette.COOKING_LEVEL_SUMMARY_CARD_FILL, Palette.COOKING_LEVEL_MEDAL_LINE, Palette.GOLD_BRIGHT, 5)
	_unlock_card.custom_minimum_size = Vector2(900.0, 142.0)
	_unlock_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_unlock_card)
	var unlock_root := VBoxContainer.new()
	unlock_root.add_theme_constant_override("separation", 4)
	_unlock_card.add_child(unlock_root)
	_unlock_ribbon = PanelContainer.new()
	_unlock_ribbon.name = "LevelUnlockRibbonAsset"
	_unlock_ribbon.add_theme_stylebox_override(
		"panel",
		_style_box(Palette.COOKING_LEVEL_RIBBON_FILL, Palette.COOKING_LEVEL_RIBBON_BORDER, Palette.GOLD_BRIGHT, 3, 5)
	)
	_unlock_ribbon.custom_minimum_size = Vector2(0.0, 36.0)
	unlock_root.add_child(_unlock_ribbon)
	_unlock_ribbon_label = make_label("新たな釣り場が解放！", 22, Palette.COOKING_LEVEL_UNLOCK_TEXT)
	_unlock_ribbon_label.name = "LevelUnlockRibbonLabel"
	_unlock_ribbon_label.z_index = 2
	_set_label_min_height(_unlock_ribbon_label, 22)
	_unlock_ribbon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_unlock_ribbon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_unlock_ribbon.add_child(_unlock_ribbon_label)
	_unlock_ribbon_visual = LevelCenteredTextVisual.new()
	_unlock_ribbon_visual.name = "LevelUnlockRibbonTextVisual"
	_unlock_ribbon_visual.z_index = 10
	_unlock_ribbon_visual.custom_minimum_size = Vector2(0.0, 36.0)
	_unlock_ribbon_visual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_unlock_ribbon_visual.configure("新たな釣り場が解放！", 22, Palette.COOKING_LEVEL_UNLOCK_TEXT, Palette.COOKING_LEVEL_RIBBON_TEXT_SHADOW)
	_unlock_ribbon.add_child(_unlock_ribbon_visual)

	var unlock_layout := HBoxContainer.new()
	unlock_layout.add_theme_constant_override("separation", 10)
	unlock_root.add_child(unlock_layout)
	var unlock_icon := _medal_box()
	unlock_icon.custom_minimum_size = Vector2(126.0, 0.0)
	unlock_layout.add_child(unlock_icon)
	var unlock_text := VBoxContainer.new()
	unlock_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unlock_text.add_theme_constant_override("separation", 2)
	unlock_layout.add_child(unlock_text)
	_unlock_tag = make_label("", 14, Palette.GAUGE_RED_HI)
	_unlock_tag.z_index = 2
	_set_label_min_height(_unlock_tag, 14)
	unlock_text.add_child(_unlock_tag)
	_unlock_title = make_label("", 24, Palette.COOKING_LEVEL_RIBBON_FILL)
	_unlock_title.name = "LevelUnlockTitle"
	_unlock_title.z_index = 2
	_set_label_min_height(_unlock_title, 24)
	unlock_text.add_child(_unlock_title)
	_unlock_body = make_label("", 14, Palette.COOKING_LEVEL_UNLOCK_BODY)
	_unlock_body.name = "LevelUnlockBody"
	_set_label_min_height(_unlock_body, 14, 2)
	_unlock_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	unlock_text.add_child(_unlock_body)
	var summary_cue := LevelToSummaryCueVisual.new()
	summary_cue.name = "LevelToSummaryCue"
	summary_cue.custom_minimum_size = Vector2(0.0, 20.0)
	summary_cue.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unlock_text.add_child(summary_cue)
	var spot := _spot_thumbnail_box()
	spot.custom_minimum_size = Vector2(230.0, 92.0)
	unlock_layout.add_child(spot)

	_confirm_button = make_button("OK  成果確認へ", _close, 300.0, true)
	_confirm_button.name = "LevelUpConfirmButton"
	_confirm_button.custom_minimum_size = Vector2(300.0, 42.0)
	_confirm_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_apply_flow_button_style(_confirm_button)
	_confirm_cue = Label.new()
	_confirm_cue.name = "LevelUpConfirmCue"
	_confirm_cue.set_meta("c0_glyph_count", 1)
	_confirm_cue.set_meta("c0_glyph_id", "summary")
	_confirm_cue.text = "▶"
	_confirm_cue.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	_confirm_cue.offset_left = 20.0
	_confirm_cue.offset_right = 60.0
	_confirm_cue.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_confirm_cue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm_cue.add_theme_font_size_override("font_size", 24)
	_confirm_cue.add_theme_color_override("font_color", Palette.GOLD_BRIGHT)
	_confirm_cue.add_theme_color_override("font_outline_color", Palette.COOKING_LEVEL_DARK_INK)
	_confirm_cue.add_theme_constant_override("outline_size", 2)
	_confirm_cue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_confirm_button.add_child(_confirm_cue)
	box.add_child(_confirm_button)


func show_level_up(
	level_from: int, level_to: int, old_stats: Dictionary, new_stats: Dictionary
) -> void:
	_level_line.text = "Lv.%d   ->   Lv.%d" % [level_from, level_to]
	_rebuild_stats(old_stats, new_stats)
	var boss_unlocked := (
		level_from < GameData.BOSS_UNLOCK_LEVEL and level_to >= GameData.BOSS_UNLOCK_LEVEL
	)
	if boss_unlocked:
		_unlock_ribbon_label.text = "新たな釣り場が解放！"
		_unlock_ribbon_visual.configure("新たな釣り場が解放！", 22, Palette.COOKING_LEVEL_UNLOCK_TEXT, Palette.COOKING_LEVEL_RIBBON_TEXT_SHADOW)
		_unlock_tag.text = "挑戦解放"
		_unlock_title.text = "港のぬしに挑戦できるようになった！"
		_unlock_body.text = "Lv.%d到達。港の大岩周辺で、港のぬしに挑めます。" % GameData.BOSS_UNLOCK_LEVEL
		_set_spot_copy("新釣り場", "港の大岩", "外洋への挑戦")
	else:
		_unlock_ribbon_label.text = "成長が進行！"
		_unlock_ribbon_visual.configure("成長が進行！", 22, Palette.COOKING_LEVEL_UNLOCK_TEXT, Palette.COOKING_LEVEL_RIBBON_TEXT_SHADOW)
		_unlock_tag.text = "能力上昇"
		_unlock_title.text = "次の釣行へ向けて力がついた！"
		_unlock_body.text = "Lv.%d到達。能力が伸び、次の釣行が安定します。" % level_to
		_set_spot_copy("成長記録", "次の釣行", "準備へ進む")
	_present()


func preview_accept() -> void:
	closed.emit()
	queue_free()


func _rebuild_stats(old_stats: Dictionary, new_stats: Dictionary) -> void:
	_clear_container(_stats_box)
	var rows := [
		{
			"icon": "energy",
			"name": "最大体力",
			"old": int(round(float(old_stats.get("max_energy", 0)))),
			"new": int(round(float(new_stats.get("max_energy", 0)))),
			"fmt": "%d",
			"color": Palette.GAUGE_RED_HI,
		},
		{
			"icon": "reel",
			"name": "巻力",
			"old": float(old_stats.get("reel_power", 0)),
			"new": float(new_stats.get("reel_power", 0)),
			"fmt": "%.1f",
			"color": Palette.GAUGE_CYAN_HI,
		},
		{
			"icon": "technique",
			"name": "技量",
			"old": int(old_stats.get("technique", 0)),
			"new": int(new_stats.get("technique", 0)),
			"fmt": "%d",
			"color": Palette.GOLD_BRIGHT,
		},
		{
			"icon": "focus",
			"name": "集中力",
			"old": int(old_stats.get("focus", 0)),
			"new": int(new_stats.get("focus", 0)),
			"fmt": "%d",
			"color": Palette.COOKING_LEVEL_FOCUS_ACCENT,
		},
	]
	for row in rows:
		_stats_box.add_child(_stat_row(row))


func _stat_row(row: Dictionary) -> PanelContainer:
	var old_value = row["old"]
	var new_value = row["new"]
	var delta := float(new_value) - float(old_value)
	var panel := PanelContainer.new()
	panel.name = _stat_row_node_name(String(row["icon"]))
	panel.add_theme_stylebox_override(
		"panel",
		_style_box(Palette.COOKING_LEVEL_SUMMARY_CARD_HEAD, Palette.COOKING_LEVEL_BADGE_DARK, Palette.GOLD_DEEP, 3, 5)
	)
	panel.custom_minimum_size = Vector2(0.0, 44.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 6)
	panel.add_child(line)

	var icon := _stat_icon(String(row["icon"]), row["color"])
	icon.custom_minimum_size = Vector2(42.0, 0.0)
	line.add_child(icon)

	var name := make_label(String(row["name"]), 17, Palette.TEXT_BONE)
	name.name = "LevelStatName%s" % _stat_row_suffix(String(row["icon"]))
	name.z_index = 2
	name.custom_minimum_size = Vector2(84.0, 23.0)
	_set_label_min_height(name, 17)
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(name)

	var fmt := String(row["fmt"])
	var old_text := fmt % old_value
	var new_text := fmt % new_value
	var values := make_label("%s  ->  %s" % [old_text, new_text], 21, Palette.TEXT_BONE)
	values.name = "LevelStatValues%s" % _stat_row_suffix(String(row["icon"]))
	values.z_index = 2
	_set_label_min_height(values, 21)
	values.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	values.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	values.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(values)

	var gain_text := "%.1f" % delta if fmt == "%.1f" else "%d" % int(round(delta))
	var gain := make_label("+%s" % gain_text, 19, Palette.GAUGE_GREEN_HI)
	gain.name = "LevelStatGain%s" % _stat_row_suffix(String(row["icon"]))
	gain.z_index = 2
	if absf(delta) < 0.01:
		gain.text = "-"
	gain.custom_minimum_size = Vector2(58.0, 27.0)
	_set_label_min_height(gain, 19)
	gain.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	gain.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(gain)

	var overlay := LevelStatTextVisual.new()
	overlay.name = "LevelStatText%s" % _stat_row_suffix(String(row["icon"]))
	overlay.z_index = 10
	overlay.custom_minimum_size = Vector2(0.0, 44.0)
	overlay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overlay.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overlay.configure(String(row["name"]), "%s  ->  %s" % [old_text, new_text], gain.text, Palette.GAUGE_GREEN_HI)
	panel.add_child(overlay)
	return panel


func _stat_row_node_name(icon: String) -> String:
	match icon:
		"energy":
			return "LevelStatRowEnergy"
		"reel":
			return "LevelStatRowReel"
		"technique":
			return "LevelStatRowTechnique"
		"focus":
			return "LevelStatRowFocus"
		_:
			return "LevelStatRow"


func _stat_row_suffix(icon: String) -> String:
	match icon:
		"energy":
			return "Energy"
		"reel":
			return "Reel"
		"technique":
			return "Technique"
		"focus":
			return "Focus"
		_:
			return "Stat"


func _stat_icon(mode: String, accent: Color) -> LevelStatIconVisual:
	var icon := LevelStatIconVisual.new()
	icon.configure(mode, accent)
	icon.custom_minimum_size = Vector2(42.0, 36.0)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func _badge_box(text: String, fill: Color, text_color: Color) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override(
		"panel",
		_style_box(fill.darkened(0.18), Palette.COOKING_LEVEL_BADGE_DARK, Palette.GOLD_BRIGHT, 2, 4)
	)
	var label := make_shadow_label(text, 17, text_color, 2)
	label.custom_minimum_size = Vector2(54.0, 24.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	badge.add_child(label)
	return badge


func _medal_box() -> PanelContainer:
	var medal := _panel_box(Palette.COOKING_LEVEL_MEDAL_BOX_FILL, Palette.COOKING_LEVEL_MEDAL_BOX_BORDER, Palette.GOLD_BRIGHT, 4)
	var visual := _level_asset_texture(
		"LevelUnlockMedallionAsset", LevelUpVisual.UNLOCK_MEDALLION_ASSET, Vector2(96.0, 78.0)
	)
	visual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	visual.size_flags_vertical = Control.SIZE_EXPAND_FILL
	medal.add_child(visual)
	return medal


func _spot_thumbnail_box() -> PanelContainer:
	var panel := _panel_box(Palette.COOKING_LEVEL_SPOT_PANEL_FILL, Palette.COOKING_LEVEL_BADGE_DARK, Palette.GOLD_BRIGHT, 4)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 1)
	panel.add_child(box)
	_spot_tag = make_label("新釣り場", 13, Palette.GOLD_BRIGHT)
	_spot_tag.z_index = 2
	_set_label_min_height(_spot_tag, 13)
	_spot_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_spot_tag)
	var visual := _level_asset_texture(
		"LevelUnlockSpotAsset", LevelUpVisual.UNLOCK_SPOT_ASSET, Vector2(0.0, 44.0), true
	)
	visual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(visual)
	_spot_title = make_label("港の大岩", 20, Palette.TEXT_BONE)
	_spot_title.z_index = 2
	_set_label_min_height(_spot_title, 20)
	_spot_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_spot_title)
	_spot_subtitle = make_label("外洋への挑戦", 13, Palette.GAUGE_CYAN_HI)
	_spot_subtitle.z_index = 2
	_set_label_min_height(_spot_subtitle, 13)
	_spot_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_spot_subtitle)
	return panel


func _set_spot_copy(tag: String, title: String, subtitle: String) -> void:
	if _spot_tag != null:
		_spot_tag.text = tag
	if _spot_title != null:
		_spot_title.text = title
	if _spot_subtitle != null:
		_spot_subtitle.text = subtitle


func _level_asset_texture(
	node_name: String, path: String, minimum_size: Vector2, cover_frame := false
) -> TextureRect:
	var visual := TextureRect.new()
	visual.name = node_name
	visual.texture = load(path) as Texture2D
	visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	visual.stretch_mode = (
		TextureRect.STRETCH_KEEP_ASPECT_COVERED
		if cover_frame
		else TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	)
	visual.custom_minimum_size = minimum_size
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return visual


func _add_burst_layer() -> void:
	var burst := Control.new()
	burst.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(burst)
	burst.draw.connect(
		func() -> void:
			var center := burst.size * 0.5
			for i in range(36):
				var a := TAU * float(i) / 36.0
				var inner := center + Vector2(cos(a), sin(a)) * 112.0
				var outer := center + Vector2(cos(a), sin(a)) * 455.0
				var color := Palette.GOLD_BRIGHT
				color.a = 0.30 if i % 2 == 0 else 0.13
				burst.draw_line(inner, outer, color, 6.0)
			var crown_y := center.y - 250.0
			var crown_x := center.x
			var crown := PackedVector2Array(
				[
					Vector2(crown_x - 44.0, crown_y + 22.0),
					Vector2(crown_x - 30.0, crown_y - 18.0),
					Vector2(crown_x - 8.0, crown_y + 8.0),
					Vector2(crown_x, crown_y - 28.0),
					Vector2(crown_x + 8.0, crown_y + 8.0),
					Vector2(crown_x + 30.0, crown_y - 18.0),
					Vector2(crown_x + 44.0, crown_y + 22.0),
				]
			)
			var crown_color := Palette.GOLD_BRIGHT
			crown_color.a = 0.40
			burst.draw_polyline(crown, crown_color, 6.0)
			var laurel := Palette.GOLD_BRIGHT
			laurel.a = 0.34
			burst.draw_arc(center + Vector2(-340.0, -190.0), 78.0, -1.25, 1.15, 20, laurel, 6.0)
			burst.draw_arc(center + Vector2(340.0, -190.0), 78.0, 1.99, 4.39, 20, laurel, 6.0)
	)
	burst.queue_redraw()


func _add_confetti_layer() -> void:
	var confetti := Control.new()
	confetti.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	confetti.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(confetti)
	confetti.draw.connect(
		func() -> void:
			var colors := [
				Palette.GOLD_BRIGHT,
				Palette.GAUGE_RED_HI,
				Palette.GAUGE_CYAN_HI,
				Palette.GAUGE_GREEN_HI,
				Palette.COOKING_LEVEL_FOCUS_ACCENT,
			]
			for i in range(46):
				var x := 82.0 + float((i * 143) % 1120)
				var y := 38.0 + float((i * 59) % 560)
				var s := 4.0 + float(i % 4)
				var color: Color = colors[i % colors.size()]
				color.a = 0.70
				confetti.draw_rect(Rect2(Vector2(x, y), Vector2(s + 5.0, s)), color)
			var spark := Palette.GOLD_BRIGHT
			for i in range(24):
				var p := Vector2(130.0 + float((i * 211) % 1000), 84.0 + float((i * 97) % 470))
				var r := 4.0 + float(i % 3)
				spark.a = 0.46
				confetti.draw_line(p + Vector2(-r, 0.0), p + Vector2(r, 0.0), spark, 2.0)
				confetti.draw_line(p + Vector2(0.0, -r), p + Vector2(0.0, r), spark, 2.0)
	)
	confetti.queue_redraw()


func _present() -> void:
	_dialog.modulate.a = 0.0
	_dialog.scale = Vector2(0.82, 0.82)
	await get_tree().process_frame
	_dialog.pivot_offset = _dialog.size * 0.5
	if is_qa_deterministic():
		_dialog.scale = Vector2.ONE
		_dialog.modulate.a = 1.0
		return
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(_dialog, "scale", Vector2.ONE, 0.34)
	tw.parallel().tween_property(_dialog, "modulate:a", 1.0, 0.18)
	Juicer.add_trauma(0.45)
	Juicer.hit_stop(0.05)


func _close() -> void:
	_dialog.pivot_offset = _dialog.size * 0.5
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(_dialog, "scale", Vector2(0.86, 0.86), 0.16)
	tw.parallel().tween_property(_dialog, "modulate:a", 0.0, 0.16)
	tw.tween_callback(
		func() -> void:
			closed.emit()
			queue_free()
	)


func _apply_flow_button_style(button: Button) -> void:
	# 左端の完了グリフを本文から離し、40px高でも潰れない導線幅を確保する。
	CookingAssets.apply_flow_button_style(button, 92.0, 7.0)


func _set_label_min_height(label: Label, font_size: int, lines := 1) -> void:
	if label == null:
		return
	var outline := label.get_theme_constant("outline_size")
	var height := float(font_size * maxi(1, lines)) * 1.35 + float(outline * 2)
	label.custom_minimum_size.y = maxf(label.custom_minimum_size.y, ceilf(height))


func _clear_container(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _panel_box(fill: Color, border: Color, inner: Color, border_width: int) -> PanelContainer:
	return CookingAssets.panel_box(fill, border, inner, border_width)


func _style_box(fill: Color, border: Color, inner: Color, border_width: int, radius: int) -> StyleBoxFlat:
	return CookingAssets.style_box(fill, border, inner, border_width, radius)


func _texture_style_box(
	path: String, margin: int, fallback: StyleBox, content_x: float, content_y: float
) -> StyleBox:
	return CookingAssets.texture_style_box(path, margin, fallback, content_x, content_y, 7.0)
