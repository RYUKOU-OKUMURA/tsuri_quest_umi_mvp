extends "res://src/ui/screen_base.gd"
## 調理後の MEAL_RESULT / EXP_GAIN を担う報酬オーバーレイ。
# 料理を食べた結果、EXP、初回ボーナス、次回バフを一拍置いて見せる。
signal closed

const GaugeBarScript = preload("res://src/ui/components/gauge_bar.gd")

const DISH_FEATURE_AJI := "res://assets/showcase/cooking/dish_feature_aji_shioyaki.png"
const DISH_FEATURE_SASHIMI := "res://assets/showcase/cooking/dish_feature_sashimi.png"
const DISH_FEATURE_SIMMERED := "res://assets/showcase/cooking/dish_feature_simmered.png"
const DISH_FEATURE_SOUP := "res://assets/showcase/cooking/dish_feature_soup.png"
const DISH_FEATURE_FRY := "res://assets/showcase/cooking/dish_feature_fry.png"
const DISH_ICON_SHEET := "res://assets/showcase/cooking/dish_icon_sheet.png"
const MEAL_RESULT_SCENE_ART := "res://assets/showcase/cooking/meal_result_scene_art_v2.png"
const PLAYER_EATING_POSE := "res://assets/showcase/cooking/player_eating_pose_pixel_tight.png"
const PLAYER_EXP_POSE := "res://assets/showcase/cooking/player_exp_message_pose_pixel.png"
const PLAYER_EXP_SCENE_POSE := "res://assets/showcase/cooking/player_exp_pose_pixel_tight.png"
const MEAL_SCENE_BG := "res://assets/showcase/cooking/meal_scene_bg.png"
const EXP_STAGE_BG := "res://assets/showcase/cooking/exp_stage_bg.png"
const MEAL_RESULT_FRAME := "res://assets/showcase/cooking/meal_result_frame.png"
const MEAL_BANNER_FRAME := "res://assets/showcase/cooking/meal_banner_frame.png"
const MEAL_DISH_CARD_FRAME := "res://assets/showcase/cooking/meal_dish_card_frame.png"
const EXP_BURST_FRAME := "res://assets/showcase/cooking/exp_burst_frame.png"
const REWARD_CARD_FRAME := "res://assets/showcase/cooking/reward_card_frame.png"
const FLOW_ACTION_BUTTON_FRAME := "res://assets/showcase/cooking/flow_action_button_frame.png"


class SceneActorVisual:
	extends Control

	const EATING_POSE := "res://assets/showcase/cooking/player_eating_pose_pixel_tight.png"
	const USE_CUTOUT_TEXTURE_ASSETS := false

	var mode := "meal"

	func set_mode(next_mode: String) -> void:
		mode = next_mode
		queue_redraw()

	func _draw() -> void:
		if mode == "exp":
			_draw_exp_power()
		else:
			_draw_eating_player()

	func _draw_eating_player() -> void:
		if USE_CUTOUT_TEXTURE_ASSETS and _draw_texture_asset(EATING_POSE):
			return
		var center := size * 0.5
		draw_ellipse(center + Vector2(0.0, 62.0), 42.0, 8.0, Color(0.0, 0.0, 0.0, 0.28))
		draw_rect(Rect2(center.x - 42.0, center.y + 8.0, 84.0, 50.0), Color("#17324d"))
		draw_rect(Rect2(center.x - 42.0, center.y + 8.0, 84.0, 8.0), Color("#2c5f8c"))
		draw_circle(center + Vector2(0.0, -22.0), 29.0, Color("#f2b889"))
		draw_rect(Rect2(center.x - 31.0, center.y - 51.0, 62.0, 16.0), Color("#1d4771"))
		draw_rect(Rect2(center.x - 22.0, center.y - 62.0, 44.0, 14.0), Color("#234f7c"))
		draw_circle(center + Vector2(-11.0, -24.0), 3.0, Color("#1d160f"))
		draw_circle(center + Vector2(11.0, -24.0), 3.0, Color("#1d160f"))
		draw_arc(center + Vector2(0.0, -14.0), 11.0, 0.15, PI - 0.15, 12, Color("#6a2a1c"), 3.0)
		draw_line(center + Vector2(-33.0, 6.0), center + Vector2(-58.0, 25.0), Color("#f2b889"), 8.0)
		draw_line(center + Vector2(33.0, 6.0), center + Vector2(57.0, 25.0), Color("#f2b889"), 8.0)
		draw_line(center + Vector2(-54.0, 18.0), center + Vector2(-11.0, -5.0), Color("#d9a45f"), 3.0)
		draw_arc(center + Vector2(0.0, 36.0), 30.0, 0.0, PI, 22, Color("#fff4d4"), 5.0)
		draw_arc(center + Vector2(0.0, 33.0), 25.0, 0.0, PI, 20, Color("#b35f25"), 5.0)
		for i in range(3):
			var x := center.x - 18.0 + float(i) * 18.0
			draw_arc(Vector2(x, center.y + 8.0), 14.0, -1.7, 0.9, 12, Color(1.0, 0.92, 0.70, 0.32), 2.0)

	func _draw_exp_power() -> void:
		var center := size * 0.5
		var cyan := Color("#6bf1ff")
		var gold := Color("#ffe081")
		var green := Color("#9cff6f")
		draw_ellipse(center + Vector2(0.0, 63.0), 42.0, 7.0, Color(0.0, 0.0, 0.0, 0.28))
		draw_arc(center + Vector2(0.0, 24.0), 32.0, 0.05, PI - 0.05, 24, Color("#fff4d4"), 5.0)
		draw_arc(center + Vector2(0.0, 21.0), 26.0, 0.05, PI - 0.05, 22, Color("#b35f25"), 5.0)
		for i in range(6):
			var angle := -2.45 + float(i) * 0.98
			var from := center + Vector2(cos(angle), sin(angle)) * 21.0
			var to := center + Vector2(cos(angle), sin(angle)) * 61.0
			var color := cyan if i % 2 == 0 else green
			color.a = 0.52
			draw_line(from, to, color, 4.0)
		draw_circle(center + Vector2(0.0, -23.0), 27.0, Color(0.05, 0.45, 0.32, 0.46))
		draw_circle(center + Vector2(0.0, -23.0), 16.0, Color(0.42, 1.0, 0.70, 0.65))
		for i in range(7):
			var p := center + Vector2(-46.0 + float(i) * 15.0, -58.0 + float((i * 17) % 36))
			draw_line(p + Vector2(-4.0, 0.0), p + Vector2(4.0, 0.0), gold, 2.0)
			draw_line(p + Vector2(0.0, -4.0), p + Vector2(0.0, 4.0), gold, 2.0)

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


class MealTableSpreadVisual:
	extends Control

	const TABLE_SPREAD := "res://assets/showcase/cooking/meal_table_spread.png"
	const USE_CUTOUT_TEXTURE_ASSETS := false

	var mode := "meal"
	var dish_texture: Texture2D

	func set_mode(next_mode: String) -> void:
		mode = next_mode
		queue_redraw()

	func set_dish_texture(texture: Texture2D) -> void:
		dish_texture = texture
		queue_redraw()

	func _draw() -> void:
		if USE_CUTOUT_TEXTURE_ASSETS and mode == "meal" and _draw_texture_asset(TABLE_SPREAD):
			return
		_draw_dish_source()

	func _draw_dish_source() -> void:
		var center := size * 0.5
		draw_ellipse(center + Vector2(0.0, 40.0), size.x * 0.34, 10.0, Color(0.0, 0.0, 0.0, 0.26))
		if dish_texture != null:
			var tex_size := Vector2(float(dish_texture.get_width()), float(dish_texture.get_height()))
			if tex_size.x > 0.0 and tex_size.y > 0.0:
				var scale := minf(size.x * 0.88 / tex_size.x, size.y * 0.74 / tex_size.y)
				var draw_size := tex_size * scale
				var rect := Rect2(Vector2((size.x - draw_size.x) * 0.5, (size.y - draw_size.y) * 0.52), draw_size)
				draw_texture_rect(dish_texture, rect, false)
		var cyan := Color("#6bf1ff")
		var gold := Color("#ffe081")
		for i in range(5):
			var angle := -2.45 + float(i) * 0.66
			var from := center + Vector2(cos(angle), sin(angle)) * 30.0
			var to := center + Vector2(cos(angle), sin(angle)) * 54.0
			var color := cyan if i % 2 == 0 else gold
			color.a = 0.45
			draw_line(from, to, color, 3.0)
		for i in range(4):
			var p := Vector2(size.x * (0.18 + float(i) * 0.19), size.y * (0.18 + float((i * 13) % 44) / 100.0))
			draw_line(p + Vector2(-4.0, 0.0), p + Vector2(4.0, 0.0), gold, 2.0)
			draw_line(p + Vector2(0.0, -4.0), p + Vector2(0.0, 4.0), gold, 2.0)

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


class ExpMessagePortraitVisual:
	extends Control

	const EXP_POSE := "res://assets/showcase/cooking/player_exp_message_pose_pixel.png"
	const USE_CUTOUT_TEXTURE_ASSETS := false

	func _draw() -> void:
		if USE_CUTOUT_TEXTURE_ASSETS and _draw_texture_asset(EXP_POSE):
			return
		var center := size * 0.5
		draw_ellipse(center + Vector2(0.0, 31.0), 33.0, 6.0, Color(0.0, 0.0, 0.0, 0.24))
		draw_rect(Rect2(center.x - 28.0, center.y + 7.0, 56.0, 31.0), Color("#17324d"))
		draw_circle(center + Vector2(0.0, -11.0), 21.0, Color("#f2b889"))
		draw_rect(Rect2(center.x - 26.0, center.y - 32.0, 52.0, 11.0), Color("#1d4771"))
		draw_circle(center + Vector2(-8.0, -12.0), 2.5, Color("#1d160f"))
		draw_circle(center + Vector2(8.0, -12.0), 2.5, Color("#1d160f"))
		draw_arc(center + Vector2(0.0, -5.0), 8.0, 0.10, PI - 0.10, 10, Color("#6a2a1c"), 2.5)
		draw_arc(center + Vector2(0.0, 17.0), 16.0, 0.0, PI, 16, Color("#fff1c7"), 3.0)
		for i in range(3):
			var p := center + Vector2(31.0 + float(i) * 8.0, -24.0 + float(i % 2) * 9.0)
			draw_line(p + Vector2(-4.0, 0.0), p + Vector2(4.0, 0.0), Palette.GOLD_BRIGHT, 2.0)
			draw_line(p + Vector2(0.0, -4.0), p + Vector2(0.0, 4.0), Palette.GOLD_BRIGHT, 2.0)

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


class ExpTrailVisual:
	extends Control

	func _draw() -> void:
		var cyan := Color("#6bf1ff")
		var gold := Color("#ffe081")
		var green := Color("#9cff6f")
		for i in range(5):
			var y := size.y * (0.24 + float(i) * 0.13)
			var start := Vector2(2.0, y + sin(float(i)) * 8.0)
			var mid := Vector2(size.x * 0.52, size.y * 0.5 + cos(float(i) * 1.3) * 24.0)
			var end := Vector2(size.x - 2.0, size.y * (0.36 + float(i % 2) * 0.26))
			var color := cyan if i % 2 == 0 else gold
			color.a = 0.38
			draw_line(start, mid, color, 4.0)
			draw_line(mid, end, color, 4.0)
			color.a = 0.70
			draw_circle(end, 4.0 + float(i % 2), color)
		for i in range(7):
			var p := Vector2(
				size.x * (0.15 + float((i * 17) % 70) / 100.0),
				size.y * (0.18 + float((i * 23) % 62) / 100.0)
			)
			var color := green if i % 2 == 0 else gold
			color.a = 0.52
			draw_line(p + Vector2(-5.0, 0.0), p + Vector2(5.0, 0.0), color, 2.0)
			draw_line(p + Vector2(0.0, -5.0), p + Vector2(0.0, 5.0), color, 2.0)


class FlowConnectorVisual:
	extends Control

	var mode := "idle"

	func set_mode(next_mode: String) -> void:
		mode = next_mode
		queue_redraw()

	func _draw() -> void:
		var center_y := size.y * 0.5
		var start := Vector2(4.0, center_y)
		var end := Vector2(size.x - 8.0, center_y)
		var color := Color("#46566d")
		var glow := Color("#46566d")
		var active := false
		match mode:
			"meal_to_exp":
				color = Palette.GOLD_BRIGHT
				glow = Color("#fff1c7")
				active = true
			"exp_to_growth":
				color = Palette.GAUGE_CYAN_HI
				glow = Color("#c9fbff")
				active = true
			"growth_unlock":
				color = Palette.GAUGE_RED_HI
				glow = Palette.GOLD_BRIGHT
				active = true
			_:
				color.a = 0.38
				glow.a = 0.20
		if active:
			glow.a = 0.28
			draw_line(start + Vector2(0.0, -2.0), end + Vector2(0.0, -2.0), glow, 5.0)
			glow.a = 0.16
			draw_line(start + Vector2(0.0, 4.0), end + Vector2(0.0, 4.0), glow, 9.0)
		draw_line(start, end, color, 3.0)
		draw_polygon(
			PackedVector2Array(
				[
					Vector2(size.x - 4.0, center_y),
					Vector2(size.x - 15.0, center_y - 7.0),
					Vector2(size.x - 15.0, center_y + 7.0),
				]
			),
			PackedColorArray([color, color, color])
		)
		if active:
			draw_polygon(
				PackedVector2Array(
					[
						Vector2(size.x - 18.0, center_y),
						Vector2(size.x - 27.0, center_y - 5.0),
						Vector2(size.x - 27.0, center_y + 5.0),
					]
				),
				PackedColorArray([glow, glow, glow])
			)
		if not active:
			return
		for i in range(5):
			var x := 10.0 + float(i) * 10.5
			var p := Vector2(x, center_y - 8.0 + float(i % 2) * 16.0)
			var sparkle := glow
			sparkle.a = 0.62
			draw_line(p + Vector2(-3.0, 0.0), p + Vector2(3.0, 0.0), sparkle, 1.5)
			draw_line(p + Vector2(0.0, -3.0), p + Vector2(0.0, 3.0), sparkle, 1.5)


class RewardIconVisual:
	extends Control

	const ICON_SHEET := "res://assets/showcase/cooking/cooking_icon_sheet.png"
	const ICON_CELL_SIZE := 96.0
	const USE_CUTOUT_TEXTURE_ASSETS := false

	var mode := "exp"
	var accent := Color("#6bf1ff")

	func configure(next_mode: String, next_accent: Color) -> void:
		mode = next_mode
		accent = next_accent
		queue_redraw()

	func _draw() -> void:
		var atlas_index := _atlas_index()
		if USE_CUTOUT_TEXTURE_ASSETS and atlas_index >= 0 and _draw_atlas_icon(atlas_index):
			return
		match mode:
			"bonus":
				_draw_bonus()
			"total":
				_draw_total()
			"buff":
				_draw_buff()
			"growth":
				_draw_growth()
			_:
				_draw_exp()

	func _atlas_index() -> int:
		match mode:
			"bonus":
				return 1
			"total":
				return 2
			"buff":
				return 3
			"growth":
				return 9
			"exp":
				return 0
			_:
				return -1

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

	func _draw_exp() -> void:
		var center := size * 0.5
		draw_rect(Rect2(center.x - 15.0, center.y - 12.0, 30.0, 24.0), Color("#17324d"))
		draw_rect(Rect2(center.x - 12.0, center.y - 9.0, 24.0, 18.0), Color("#fff1c7"))
		draw_line(center + Vector2(-8.0, 0.0), center + Vector2(8.0, 0.0), accent, 3.0)
		draw_line(center + Vector2(0.0, -8.0), center + Vector2(0.0, 8.0), accent, 3.0)
		draw_circle(center + Vector2(13.0, -10.0), 4.0, Color("#ffe081"))

	func _draw_bonus() -> void:
		var center := size * 0.5
		draw_rect(Rect2(center.x - 4.0, center.y - 15.0, 8.0, 28.0), Color("#9b2f17"))
		draw_polygon(
			PackedVector2Array(
				[
					center + Vector2(4.0, -14.0),
					center + Vector2(22.0, -8.0),
					center + Vector2(4.0, -2.0),
				]
			),
			PackedColorArray([accent, accent, accent])
		)
		draw_arc(center + Vector2(-8.0, 13.0), 14.0, PI, TAU, 20, Color("#fff1c7"), 5.0)
		draw_arc(center + Vector2(8.0, 13.0), 14.0, PI, TAU, 20, Color("#fff1c7"), 5.0)

	func _draw_total() -> void:
		var center := size * 0.5
		var points := PackedVector2Array()
		for i in range(10):
			var radius := 18.0 if i % 2 == 0 else 8.0
			var a := -PI * 0.5 + TAU * float(i) / 10.0
			points.append(center + Vector2(cos(a), sin(a)) * radius)
		var colors := PackedColorArray()
		for _i in range(points.size()):
			colors.append(accent)
		draw_polygon(points, colors)
		draw_arc(center, 17.0, 0.0, TAU, 32, Color("#7b4b20"), 2.0)

	func _draw_buff() -> void:
		var center := size * 0.5
		draw_ellipse(center + Vector2(-4.0, 2.0), 16.0, 10.0, Color("#235f33"))
		draw_polygon(
			PackedVector2Array(
				[
					center + Vector2(0.0, 8.0),
					center + Vector2(22.0, -4.0),
					center + Vector2(22.0, 14.0),
				]
			),
			PackedColorArray([accent, accent, accent])
		)
		draw_line(center + Vector2(-16.0, 8.0), center + Vector2(18.0, -6.0), Color("#fff1c7"), 2.0)

	func _draw_growth() -> void:
		var center := size * 0.5
		draw_line(center + Vector2(0.0, 16.0), center + Vector2(0.0, -16.0), accent, 5.0)
		draw_polygon(
			PackedVector2Array(
				[
					center + Vector2(0.0, -20.0),
					center + Vector2(-14.0, -4.0),
					center + Vector2(14.0, -4.0),
				]
			),
			PackedColorArray([accent, accent, accent])
		)
		draw_arc(center + Vector2(0.0, 8.0), 16.0, 0.0, TAU, 24, Color("#ffe081"), 2.0)


class RewardBuffSignalVisual:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var center := size * 0.5
		var green := Color("#75d653")
		var cyan := Color("#6bf1ff")
		var gold := Color("#ffe081")
		draw_circle(center + Vector2(-2.0, 0.0), 18.0, Color("#173b28"))
		draw_circle(center + Vector2(-2.0, 0.0), 14.0, Color("#2f7a45"))
		var fish := PackedVector2Array(
			[
				center + Vector2(-14.0, -1.0),
				center + Vector2(-5.0, -8.0),
				center + Vector2(10.0, -4.0),
				center + Vector2(14.0, 0.0),
				center + Vector2(10.0, 4.0),
				center + Vector2(-5.0, 8.0),
			]
		)
		draw_colored_polygon(fish, cyan)
		draw_colored_polygon(
			PackedVector2Array(
				[
					center + Vector2(10.0, -4.0),
					center + Vector2(21.0, -11.0),
					center + Vector2(18.0, 0.0),
					center + Vector2(21.0, 11.0),
					center + Vector2(10.0, 4.0),
				]
			),
			Color("#2e86b5")
		)
		draw_circle(center + Vector2(-9.0, -2.0), 2.0, Color("#0a1723"))
		for x in [-24.0, 23.0]:
			draw_line(center + Vector2(x, 19.0), center + Vector2(x, -16.0), green, 4.0)
			draw_polygon(
				PackedVector2Array(
					[
						center + Vector2(x, -22.0),
						center + Vector2(x - 7.0, -10.0),
						center + Vector2(x + 7.0, -10.0),
					]
				),
				PackedColorArray([green, green, green])
			)
		for i in range(4):
			var p := center + Vector2(-28.0 + float(i) * 18.0, -19.0 + float(i % 2) * 8.0)
			draw_line(p + Vector2(-3.0, 0.0), p + Vector2(3.0, 0.0), gold, 1.6)
			draw_line(p + Vector2(0.0, -3.0), p + Vector2(0.0, 3.0), gold, 1.6)


class EffectPreviewVisual:
	extends Control

	const EFFECT_ART := "res://assets/showcase/cooking/next_effect_art.png"
	const USE_CUTOUT_TEXTURE_ASSETS := false

	func _draw() -> void:
		if USE_CUTOUT_TEXTURE_ASSETS and _draw_texture_asset():
			return
		var center := size * 0.5
		var green := Color("#8ee65a")
		var cyan := Color("#6bf1ff")
		var gold := Color("#ffe081")
		draw_rect(Rect2(8.0, 8.0, size.x - 16.0, size.y - 16.0), Color("#113b27"))
		for i in range(10):
			var a := TAU * float(i) / 10.0
			var from := center + Vector2(cos(a), sin(a)) * 14.0
			var to := center + Vector2(cos(a), sin(a)) * 56.0
			var color := green if i % 2 == 0 else gold
			color.a = 0.34
			draw_line(from, to, color, 3.0)
		draw_ellipse(center + Vector2(-12.0, 2.0), 46.0, 20.0, Color("#2a76a7"))
		draw_polygon(
			PackedVector2Array(
				[
					center + Vector2(28.0, 0.0),
					center + Vector2(56.0, -14.0),
					center + Vector2(56.0, 14.0),
				]
			),
			PackedColorArray([cyan, cyan, cyan])
		)
		draw_circle(center + Vector2(-34.0, -5.0), 4.0, Color("#0a1723"))
		draw_line(center + Vector2(-40.0, 13.0), center + Vector2(20.0, 13.0), Color("#fff1c7"), 3.0)
		for x in [-26.0, 18.0]:
			draw_line(center + Vector2(x, 54.0), center + Vector2(x, 24.0), green, 6.0)
			draw_polygon(
				PackedVector2Array(
					[
						center + Vector2(x, 15.0),
						center + Vector2(x - 12.0, 31.0),
						center + Vector2(x + 12.0, 31.0),
					]
				),
				PackedColorArray([green, green, green])
			)
		for i in range(5):
			var p := Vector2(18.0 + float(i) * 36.0, 16.0 + float((i * 23) % 48))
			draw_line(p + Vector2(-4.0, 0.0), p + Vector2(4.0, 0.0), gold, 2.0)
			draw_line(p + Vector2(0.0, -4.0), p + Vector2(0.0, 4.0), gold, 2.0)

	func _draw_texture_asset() -> bool:
		var tex := load(EFFECT_ART) as Texture2D
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


var _dialog: PanelContainer
var _stage_background: TextureRect
var _result_banner: PanelContainer
var _header_title: Label
var _bridge_label: Label
var _dish_title: Label
var _dish_image: TextureRect
var _dish_card: PanelContainer
var _scene_title: Label
var _scene_caption: Label
var _scene_bonus_label: Label
var _scene_result_image: TextureRect
var _scene_table: HBoxContainer
var _scene_dish_image: MealTableSpreadVisual
var _scene_actor_visual: SceneActorVisual
var _scene_actor_image: TextureRect
var _exp_trail_visual: ExpTrailVisual
var _exp_focus_card: PanelContainer
var _exp_message_label: Label
var _effect_preview_card: PanelContainer
var _effect_preview_visual: TextureRect
var _effect_name_label: Label
var _effect_text_label: Label
var _effect_duration_label: Label
var _reward_grid: GridContainer
var _exp_card: PanelContainer
var _exp_bar: GaugeBar
var _exp_label: Label
var _exp_progress_label: Label
var _base_label: Label
var _bonus_label: Label
var _total_label: Label
var _buff_label: Label
var _growth_label: Label
var _status_level_label: Label
var _status_meal_label: Label
var _status_cooler_label: Label
var _status_money_label: Label
var _confirm_button: Button
var _flow_step_cards: Array[PanelContainer] = []
var _flow_step_labels: Array[Label] = []
var _flow_connectors: Array[FlowConnectorVisual] = []
var _preview_state := ""
var _closing := false

var _target_exp := 0.0
var _target_max := 1.0


func _build_screen() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	_add_meal_scene_background()

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.38)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	_add_reward_ambient_layer()

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_dialog = PanelContainer.new()
	_dialog.custom_minimum_size = Vector2(1168.0, 0.0)
	_dialog.add_theme_stylebox_override(
		"panel",
		_texture_style_box(
			MEAL_RESULT_FRAME,
			34,
			_style_box(Color("#10283f"), Color("#5e391a"), Palette.GOLD_BRIGHT, 6, 8),
			18.0,
			2.0
		)
	)
	center.add_child(_dialog)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	_dialog.add_child(root)

	var flow_row := HBoxContainer.new()
	flow_row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	flow_row.alignment = BoxContainer.ALIGNMENT_CENTER
	flow_row.add_theme_constant_override("separation", 5)
	root.add_child(flow_row)
	_add_flow_step(flow_row, "1 食事")
	_add_flow_connector(flow_row)
	_add_flow_step(flow_row, "2 EXP")
	_add_flow_connector(flow_row)
	_add_flow_step(flow_row, "3 成長")

	var hero := HBoxContainer.new()
	hero.add_theme_constant_override("separation", 12)
	root.add_child(hero)

	var scene_card := _panel_box(Color(0.10, 0.06, 0.03, 0.72), Color("#5e391a"), Palette.GOLD_BRIGHT, 5)
	scene_card.custom_minimum_size = Vector2(438.0, 244.0)
	hero.add_child(scene_card)
	var scene_box := VBoxContainer.new()
	scene_box.add_theme_constant_override("separation", 5)
	scene_card.add_child(scene_box)
	_scene_title = make_shadow_label("食べる", 27, Palette.GOLD_BRIGHT, 3)
	_scene_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene_box.add_child(_scene_title)
	var scene_visual_stack := Control.new()
	scene_visual_stack.name = "MealSceneVisualStack"
	scene_visual_stack.custom_minimum_size = Vector2(0.0, 164.0)
	scene_visual_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scene_visual_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene_box.add_child(scene_visual_stack)
	_scene_result_image = TextureRect.new()
	_scene_result_image.name = "MealResultSceneArt"
	_scene_result_image.texture = load(MEAL_RESULT_SCENE_ART) as Texture2D
	_scene_result_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scene_result_image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scene_result_image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scene_result_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_scene_result_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_scene_result_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scene_visual_stack.add_child(_scene_result_image)
	_scene_table = HBoxContainer.new()
	_scene_table.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scene_table.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scene_table.add_theme_constant_override("separation", 10)
	scene_visual_stack.add_child(_scene_table)
	var eater := _scene_actor_box()
	eater.custom_minimum_size = Vector2(176.0, 0.0)
	_scene_table.add_child(eater)
	_scene_dish_image = MealTableSpreadVisual.new()
	_scene_dish_image.name = "MealTableSpread"
	_scene_dish_image.custom_minimum_size = Vector2(252.0, 132.0)
	_scene_dish_image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scene_dish_image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scene_dish_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scene_table.add_child(_scene_dish_image)
	_scene_caption = make_shadow_label("湯気の立つ料理を味わった。", 18, Palette.TEXT_BONE, 2)
	_scene_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_scene_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scene_box.add_child(_scene_caption)
	_scene_bonus_label = make_shadow_label("初回ボーナス", 16, Palette.GOLD_BRIGHT, 2)
	_scene_bonus_label.custom_minimum_size = Vector2(0.0, 18.0)
	_scene_bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_scene_bonus_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_scene_bonus_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_scene_bonus_label.clip_text = true
	scene_box.add_child(_scene_bonus_label)

	_exp_trail_visual = ExpTrailVisual.new()
	_exp_trail_visual.name = "ExpEnergyTrail"
	_exp_trail_visual.custom_minimum_size = Vector2(32.0, 152.0)
	_exp_trail_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_exp_trail_visual.visible = false
	hero.add_child(_exp_trail_visual)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	hero.add_child(right)

	_result_banner = PanelContainer.new()
	_result_banner.custom_minimum_size = Vector2(0.0, 96.0)
	_result_banner.add_theme_stylebox_override(
		"panel",
		_texture_style_box(
			MEAL_BANNER_FRAME,
			24,
			_style_box(Color("#f2e4c2"), Color("#5e391a"), Palette.GOLD_BRIGHT, 5, 5),
			18.0,
			6.0
		)
	)
	right.add_child(_result_banner)
	var banner_box := VBoxContainer.new()
	banner_box.add_theme_constant_override("separation", 2)
	_result_banner.add_child(banner_box)
	_header_title = make_shadow_label("いただきます！", 32, Color("#9b2f17"), 3)
	_header_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_header_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner_box.add_child(_header_title)
	_bridge_label = make_shadow_label("", 16, Color("#4f3b25"), 1)
	_bridge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bridge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bridge_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner_box.add_child(_bridge_label)

	_dish_card = PanelContainer.new()
	_dish_card.name = "MealDishCard"
	_dish_card.add_theme_stylebox_override(
		"panel",
		_texture_style_box(
			MEAL_DISH_CARD_FRAME,
			24,
			_style_box(Color("#0f2238"), Color("#07121e"), Palette.GOLD_DEEP, 5, 5),
			14.0,
			8.0
		)
	)
	_dish_card.custom_minimum_size = Vector2(0.0, 166.0)
	right.add_child(_dish_card)
	var dish_row := HBoxContainer.new()
	dish_row.add_theme_constant_override("separation", 14)
	_dish_card.add_child(dish_row)
	_dish_image = TextureRect.new()
	_dish_image.name = "RewardDishFeatureImage"
	_dish_image.custom_minimum_size = Vector2(304.0, 0.0)
	_dish_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dish_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dish_row.add_child(_dish_image)
	var dish_text := VBoxContainer.new()
	dish_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dish_text.alignment = BoxContainer.ALIGNMENT_CENTER
	dish_row.add_child(dish_text)
	var dish_tag := make_shadow_label("今回の料理", 19, Palette.GOLD_BRIGHT, 2)
	dish_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dish_text.add_child(dish_tag)
	_dish_title = make_shadow_label("", 30, Palette.TEXT_BONE, 3)
	_dish_title.custom_minimum_size = Vector2(0.0, 64.0)
	_dish_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dish_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_dish_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dish_text.add_child(_dish_title)
	var dish_note := make_shadow_label("料理を食べて、体に力が湧いてきた。", 17, Palette.TEXT_BONE, 2)
	dish_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dish_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dish_text.add_child(dish_note)

	_exp_focus_card = PanelContainer.new()
	_exp_focus_card.name = "ExpBurstFrame"
	_exp_focus_card.add_theme_stylebox_override(
		"panel",
		_texture_style_box(
			EXP_BURST_FRAME,
			28,
			_style_box(Color("#071e34"), Color("#07121e"), Palette.GAUGE_CYAN_HI, 5, 5),
			18.0,
			8.0
		)
	)
	_exp_focus_card.custom_minimum_size = Vector2(0.0, 216.0)
	_exp_focus_card.visible = false
	right.add_child(_exp_focus_card)
	var exp_focus_box := VBoxContainer.new()
	exp_focus_box.add_theme_constant_override("separation", 5)
	_exp_focus_card.add_child(exp_focus_box)
	_exp_focus_card.draw.connect(_draw_exp_focus_burst)
	var exp_focus_tag := make_shadow_label("食経験値", 22, Palette.TEXT_BONE, 3)
	exp_focus_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exp_focus_box.add_child(exp_focus_tag)
	_exp_label = make_shadow_label("+0 EXP", 62, Palette.GOLD_BRIGHT, 7)
	_exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exp_focus_box.add_child(_exp_label)
	_exp_bar = GaugeBarScript.new()
	_exp_bar.show_value = false
	_exp_bar.custom_minimum_size = Vector2(0.0, 46.0)
	_exp_bar.set_colors(Palette.GAUGE_CYAN, Palette.GAUGE_CYAN_HI)
	exp_focus_box.add_child(_exp_bar)
	_exp_progress_label = make_shadow_label("", 22, Palette.GAUGE_CYAN_HI, 2)
	_exp_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exp_focus_box.add_child(_exp_progress_label)
	var message_row := HBoxContainer.new()
	message_row.name = "ExpMessagePanel"
	message_row.add_theme_constant_override("separation", 8)
	message_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	exp_focus_box.add_child(message_row)
	var exp_portrait := TextureRect.new()
	exp_portrait.name = "ExpMessagePortrait"
	exp_portrait.texture = load(PLAYER_EXP_POSE) as Texture2D
	exp_portrait.custom_minimum_size = Vector2(108.0, 62.0)
	exp_portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	exp_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	exp_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	exp_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	message_row.add_child(exp_portrait)
	_exp_message_label = make_shadow_label("体に力がみなぎってきた！", 17, Palette.TEXT_BONE, 2)
	_exp_message_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_exp_message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_exp_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_row.add_child(_exp_message_label)

	_build_effect_preview_card(hero)

	_reward_grid = GridContainer.new()
	_reward_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reward_grid.add_theme_constant_override("h_separation", 8)
	_reward_grid.add_theme_constant_override("v_separation", 8)
	root.add_child(_reward_grid)

	_exp_card = _panel_box(Color("#0f2238"), Color("#07121e"), Palette.GOLD_DEEP, 5)
	_exp_card.custom_minimum_size = Vector2(280.0, 112.0)
	_exp_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reward_grid.add_child(_exp_card)
	var exp_layout := VBoxContainer.new()
	exp_layout.add_theme_constant_override("separation", 4)
	_exp_card.add_child(exp_layout)
	var exp_title := make_shadow_label("食経験値を獲得！", 23, Palette.TEXT_BONE, 3)
	exp_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exp_layout.add_child(exp_title)
	var exp_summary := make_shadow_label("中央ゲージで加算中", 20, Palette.GAUGE_CYAN_HI, 3)
	exp_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exp_summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	exp_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	exp_summary.size_flags_vertical = Control.SIZE_EXPAND_FILL
	exp_layout.add_child(exp_summary)

	_base_label = _reward_line(_reward_grid, "基本EXP", "exp", Palette.GAUGE_CYAN_HI)
	_bonus_label = _reward_line(_reward_grid, "初回ボーナス", "bonus", Palette.GOLD_BRIGHT)
	_total_label = _reward_line(_reward_grid, "合計獲得", "total", Palette.GAUGE_GREEN_HI)
	_buff_label = _reward_line(_reward_grid, "次の釣行", "buff", Palette.GAUGE_GREEN_HI)
	_growth_label = _reward_line(_reward_grid, "成長", "growth", Palette.GAUGE_RED_HI)

	_build_status_strip(root)

	_confirm_button = make_button("OK", _close, 280.0, true)
	_confirm_button.name = "RewardConfirmButton"
	_confirm_button.custom_minimum_size = Vector2(318.0, 40.0)
	_confirm_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_apply_flow_button_style(_confirm_button)
	_confirm_button.draw.connect(func() -> void: _draw_confirm_button_cue(_confirm_button))
	root.add_child(_confirm_button)


func show_meal_result(result: Dictionary) -> void:
	_preview_state = "MEAL_RESULT"
	_result_banner.name = "MealResultBanner"
	_header_title.name = "MealResultTitle"
	_set_stage_background(MEAL_SCENE_BG)
	var dish_name := String(result.get("dish_name", "料理"))
	_set_result_banner_height(104.0)
	_set_header_title_font_size(28)
	_set_bridge_font_size(16)
	_set_exp_label_font_size(56)
	_header_title.text = "%sを\n食べた！" % dish_name
	_bridge_label.text = "%sで次の釣行効果を予約。食経験値は次に加算される。" % dish_name
	_dish_title.text = "%sを食べた！" % dish_name
	var dish_texture := _featured_dish_texture(String(Dictionary(result.get("buff", {})).get("recipe_id", "")))
	_dish_image.texture = dish_texture
	_scene_dish_image.set_dish_texture(dish_texture)
	_scene_dish_image.set_mode("meal")
	_set_scene_result_art_visible(true)
	_scene_caption.text = "湯気の立つ%sを味わった。" % dish_name
	_scene_bonus_label.text = _meal_bonus_badge_text(result)
	_scene_title.text = "食べる"
	_set_scene_actor_mode("meal")
	_exp_trail_visual.visible = false
	_dish_card.visible = true
	_exp_focus_card.visible = false
	_effect_preview_card.visible = false

	_exp_card.visible = false
	_reward_grid.columns = 4
	_base_label.text = "食経験値を獲得した！\n+%d EXP" % int(result.get("base_exp", 0))
	if bool(result.get("first_time", false)):
		_bonus_label.text = "はじめて作った料理！\n+%d EXP" % int(result.get("first_bonus", 0))
	else:
		_bonus_label.text = "記録済み。\n今回は基本EXPのみ。"
	_total_label.text = "合計獲得食経験値\n+%d EXP" % int(result.get("total_exp", 0))

	var buff := Dictionary(result.get("buff", {}))
	_buff_label.text = "次回の釣行で効果を発揮！\n%s" % _buff_effect_text(buff)
	_refresh_status_strip(result)
	_set_reward_line_visible(_growth_label, false)
	_confirm_button.text = "食経験値へ進む"
	_confirm_button.queue_redraw()
	_refresh_meal_steps()
	_present()


func show_reward(
	result: Dictionary,
	exp_before: int,
	exp_after: int,
	exp_max: int,
	leveled: bool,
	level_before := 0,
	level_after := 0
) -> void:
	_preview_state = "EXP_GAIN_LEVELUP" if leveled else "EXP_GAIN"
	_result_banner.name = "ExpGainBanner"
	_header_title.name = "ExpGainTitle"
	_set_stage_background(EXP_STAGE_BG)
	var dish_name := String(result.get("dish_name", "料理"))
	_set_result_banner_height(92.0)
	_set_header_title_font_size(36)
	_set_bridge_font_size(14)
	_set_exp_label_font_size(72)
	_header_title.text = "食経験値が成長へ！" if leveled else "食経験値を獲得！"
	_bridge_label.text = _growth_bridge_text(dish_name, leveled, level_before, level_after)
	_dish_title.text = "%sを食べた！" % dish_name
	var dish_texture := _featured_dish_texture(String(Dictionary(result.get("buff", {})).get("recipe_id", "")))
	_dish_image.texture = dish_texture
	_scene_dish_image.set_dish_texture(dish_texture)
	_scene_dish_image.set_mode("exp")
	_set_scene_result_art_visible(false)
	_scene_title.text = "食べた料理"
	_set_scene_actor_mode("exp")
	_exp_trail_visual.visible = true
	_exp_trail_visual.queue_redraw()
	_scene_caption.text = "%sから食経験値が流れ込む。" % dish_name
	_scene_bonus_label.text = _meal_bonus_badge_text(result)
	_dish_card.visible = false
	_exp_focus_card.visible = true
	_effect_preview_card.visible = true
	_exp_card.visible = false
	_reward_grid.columns = 5
	_set_reward_line_visible(_growth_label, true)

	_target_max = maxf(1.0, float(exp_max))
	_target_exp = clampf(float(exp_after), 0.0, _target_max)
	_exp_bar.max_value = _target_max
	_exp_bar.set_value(clampf(float(exp_before), 0.0, _target_max))
	var shown_max := maxi(1, exp_max)
	var shown_before := mini(maxi(0, exp_before), shown_max)
	var shown_after := mini(maxi(0, exp_after), shown_max)
	_exp_progress_label.text = "EXP %d / %d  ->  %d / %d" % [
		shown_before,
		shown_max,
		shown_after,
		shown_max,
	]
	_exp_label.text = "+%d EXP" % int(result.get("total_exp", 0))
	_exp_message_label.text = (
		"体に力がみなぎってきた！\nLv.%dの成長が近づいた。"
		% level_after
		if leveled and level_after > 0
		else "体に力がみなぎってきた！\n次の釣りも頑張れそうだ！"
	)
	_base_label.text = "料理の経験値 +%d EXP" % int(result.get("base_exp", 0))

	if bool(result.get("first_time", false)):
		_bonus_label.text = "初めて食べた料理！\n+%d EXP" % int(result.get("first_bonus", 0))
	else:
		_bonus_label.text = "記録済み。\n今回は基本EXPのみ。"
	_total_label.text = "今回の合計 +%d EXP" % int(result.get("total_exp", 0))

	var buff := Dictionary(result.get("buff", {}))
	_buff_label.text = _buff_effect_text(buff)
	_effect_name_label.text = String(buff.get("name", "次回効果"))
	_effect_text_label.text = String(buff.get("text", "次の釣行で効果を得る"))
	_effect_duration_label.text = "効果時間：1回の釣行で発動"
	_effect_preview_visual.queue_redraw()
	_exp_focus_card.queue_redraw()
	_refresh_status_strip(result)
	if leveled:
		if level_before > 0 and level_after > level_before:
			var boss_unlocked := (
				level_before < GameData.BOSS_UNLOCK_LEVEL
				and level_after >= GameData.BOSS_UNLOCK_LEVEL
			)
			if boss_unlocked:
				_growth_label.text = "Lv.%d -> Lv.%d / ぬし解放" % [
					level_before,
					level_after,
				]
				_confirm_button.text = "解放を見る"
			else:
				_growth_label.text = "LEVEL UP! Lv.%d -> Lv.%d" % [level_before, level_after]
				_confirm_button.text = "Lv.%dの成長を見る" % level_after
		else:
			_growth_label.text = "LEVEL UP! 能力上昇へ"
			_confirm_button.text = "成長を見る"
	else:
		_growth_label.text = "次のレベルまで %d EXP" % maxi(0, exp_max - exp_after)
		_confirm_button.text = "準備へ戻る"
	_confirm_button.queue_redraw()
	_refresh_flow_steps(leveled)
	_present()


func _growth_bridge_text(
	dish_name: String, leveled: bool, level_before: int, level_after: int
) -> String:
	if leveled and level_before > 0 and level_after > level_before:
		return "%sの食経験値が Lv.%d 到達へ！" % [dish_name, level_after]
	return "%sの食経験値がたまり、力が満ちた。" % dish_name


func _buff_effect_text(buff: Dictionary) -> String:
	var text := String(buff.get("text", "次の釣行で効果を得る"))
	if text.begins_with("次の釣行で"):
		text = text.trim_prefix("次の釣行で")
	return "%s / 1回発動" % text


func _meal_bonus_badge_text(result: Dictionary) -> String:
	if bool(result.get("first_time", false)):
		return "初回ボーナス +%d EXP" % int(result.get("first_bonus", 0))
	return "初回 記録済み"


func _draw_confirm_button_cue(button: Button) -> void:
	var center := Vector2(32.0, button.size.y * 0.5)
	var active := not button.disabled
	var gold := Palette.GOLD_BRIGHT if active else Color("#8b7654")
	var ink := Color("#3b2515") if active else Color("#665847")
	var cyan := Palette.GAUGE_CYAN_HI if active else Color("#607077")
	var red := Palette.GAUGE_RED_HI if active else Color("#775a58")
	var glow := Color(1.0, 0.82, 0.25, 0.36) if active else Color(0.42, 0.36, 0.30, 0.22)
	button.draw_circle(center, 22.0, glow)
	match _preview_state:
		"MEAL_RESULT":
			_draw_button_meal_to_exp(button, center, ink, gold, cyan)
		"EXP_GAIN_LEVELUP":
			_draw_button_exp_to_level(button, center, ink, gold, red)
		_:
			_draw_button_exp_to_summary(button, center, ink, gold, cyan)


func _apply_flow_button_style(button: Button) -> void:
	var normal_fallback := _style_box(Color("#102f51"), Palette.GOLD_DEEP, Palette.GOLD_BRIGHT, 4, 6)
	var hover_fallback := _style_box(Color("#16436c"), Palette.GOLD_BRIGHT, Color("#fff0b2"), 4, 6)
	var pressed_fallback := _style_box(Color("#081a2d"), Color("#a06d28"), Palette.GOLD_DEEP, 4, 6)
	var disabled_fallback := _style_box(Color("#202a31"), Color("#71614a"), Color("#8c7b62"), 3, 6)
	button.add_theme_stylebox_override(
		"normal",
		_texture_style_box(FLOW_ACTION_BUTTON_FRAME, 24, normal_fallback, 78.0, 8.0)
	)
	button.add_theme_stylebox_override(
		"hover",
		_texture_style_box(FLOW_ACTION_BUTTON_FRAME, 24, hover_fallback, 78.0, 8.0)
	)
	button.add_theme_stylebox_override(
		"pressed",
		_texture_style_box(FLOW_ACTION_BUTTON_FRAME, 24, pressed_fallback, 78.0, 8.0)
	)
	button.add_theme_stylebox_override(
		"disabled",
		_texture_style_box(FLOW_ACTION_BUTTON_FRAME, 24, disabled_fallback, 78.0, 8.0)
	)
	button.add_theme_stylebox_override(
		"focus",
		_texture_style_box(FLOW_ACTION_BUTTON_FRAME, 24, hover_fallback, 78.0, 8.0)
	)
	button.add_theme_color_override("font_color", Palette.GOLD_BRIGHT)
	button.add_theme_color_override("font_hover_color", Color("#fff1ba"))
	button.add_theme_color_override("font_pressed_color", Color("#f0c06b"))
	button.add_theme_color_override("font_disabled_color", Color("#b6a68d"))


func _draw_button_meal_to_exp(
	button: Button, center: Vector2, ink: Color, gold: Color, cyan: Color
) -> void:
	button.draw_arc(center + Vector2(-7.0, 6.0), 13.0, 0.0, PI, 18, Color("#fff1cf"), 5.0)
	button.draw_arc(center + Vector2(-7.0, 2.0), 10.0, 0.0, PI, 16, gold, 4.0)
	for i in range(2):
		var x := center.x - 15.0 + float(i) * 9.0
		button.draw_arc(Vector2(x, center.y - 12.0), 6.0, -1.5, 0.9, 8, Color(1.0, 0.93, 0.68, 0.55), 2.0)
	button.draw_line(center + Vector2(10.0, 0.0), center + Vector2(34.0, 0.0), gold, 3.0)
	button.draw_colored_polygon(
		PackedVector2Array(
			[
				center + Vector2(40.0, 0.0),
				center + Vector2(28.0, -7.0),
				center + Vector2(28.0, 7.0),
			]
		),
		gold
	)
	button.draw_circle(center + Vector2(57.0, 0.0), 12.0, Color("#0f5d76"))
	button.draw_circle(center + Vector2(57.0, 0.0), 7.0, cyan)
	button.draw_line(center + Vector2(51.0, 0.0), center + Vector2(63.0, 0.0), ink, 2.0)


func _draw_button_exp_to_level(
	button: Button, center: Vector2, ink: Color, gold: Color, red: Color
) -> void:
	button.draw_circle(center + Vector2(-7.0, 0.0), 13.0, Color("#0f5d76"))
	button.draw_circle(center + Vector2(-7.0, 0.0), 7.0, Palette.GAUGE_CYAN_HI)
	button.draw_line(center + Vector2(9.0, 0.0), center + Vector2(34.0, 0.0), gold, 3.0)
	button.draw_colored_polygon(
		PackedVector2Array(
			[
				center + Vector2(40.0, 0.0),
				center + Vector2(28.0, -7.0),
				center + Vector2(28.0, 7.0),
			]
		),
		gold
	)
	var star_center := center + Vector2(58.0, 0.0)
	var points := PackedVector2Array()
	for i in range(10):
		var radius := 13.0 if i % 2 == 0 else 6.0
		var angle := -PI * 0.5 + TAU * float(i) / 10.0
		points.append(star_center + Vector2(cos(angle), sin(angle)) * radius)
	button.draw_colored_polygon(points, red)
	button.draw_line(star_center + Vector2(-9.0, 12.0), star_center + Vector2(9.0, 12.0), ink, 2.0)
	button.draw_line(star_center + Vector2(-6.0, -14.0), star_center + Vector2(0.0, -23.0), gold, 2.0)
	button.draw_line(star_center + Vector2(6.0, -14.0), star_center + Vector2(0.0, -23.0), gold, 2.0)


func _draw_button_exp_to_summary(
	button: Button, center: Vector2, ink: Color, gold: Color, cyan: Color
) -> void:
	button.draw_circle(center + Vector2(-9.0, 0.0), 12.0, Color("#0f5d76"))
	button.draw_circle(center + Vector2(-9.0, 0.0), 7.0, cyan)
	button.draw_line(center + Vector2(8.0, 0.0), center + Vector2(30.0, 0.0), gold, 3.0)
	button.draw_colored_polygon(
		PackedVector2Array(
			[
				center + Vector2(36.0, 0.0),
				center + Vector2(24.0, -7.0),
				center + Vector2(24.0, 7.0),
			]
		),
		gold
	)
	for i in range(3):
		var x := center.x + 48.0 + float(i) * 11.0
		var rect := Rect2(x, center.y - 10.0 + float(i % 2) * 3.0, 9.0, 18.0)
		button.draw_rect(rect, Color("#fff1cf"))
		button.draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3.0)), gold)
		button.draw_line(rect.position, rect.position + Vector2(rect.size.x, 0.0), ink, 1.0)
		button.draw_line(rect.position, rect.position + Vector2(0.0, rect.size.y), ink, 1.0)
		button.draw_line(rect.position + Vector2(rect.size.x, 0.0), rect.position + rect.size, ink, 1.0)
		button.draw_line(rect.position + Vector2(0.0, rect.size.y), rect.position + rect.size, ink, 1.0)


func _draw_exp_focus_burst() -> void:
	if _exp_focus_card == null or not _exp_focus_card.visible:
		return
	var rect := Rect2(Vector2.ZERO, _exp_focus_card.size)
	var center := Vector2(rect.size.x * 0.5, rect.size.y * 0.48)
	var gold := Palette.GOLD_BRIGHT
	var cyan := Palette.GAUGE_CYAN_HI
	for i in range(22):
		var angle := TAU * float(i) / 22.0
		var from := center + Vector2(cos(angle), sin(angle)) * 16.0
		var to := center + Vector2(cos(angle), sin(angle)) * 252.0
		var color := gold if i % 2 == 0 else cyan
		color.a = 0.16 if i % 2 == 0 else 0.11
		_exp_focus_card.draw_line(from, to, color, 5.0)
	for i in range(6):
		var width := rect.size.x - 48.0 - float(i) * 18.0
		var y := rect.size.y * 0.60 + float(i) * 2.0
		var color := cyan
		color.a = 0.15 - float(i) * 0.014
		_exp_focus_card.draw_rect(
			Rect2(Vector2((rect.size.x - width) * 0.5, y), Vector2(width, 12.0)),
			color
		)
	for i in range(22):
		var p := Vector2(
			rect.size.x * (0.12 + float((i * 37) % 78) / 100.0),
			rect.size.y * (0.14 + float((i * 23) % 64) / 100.0)
		)
		var color := gold if i % 3 != 0 else cyan
		color.a = 0.42
		var radius := 2.0 + float(i % 3)
		_exp_focus_card.draw_line(p + Vector2(-radius, 0.0), p + Vector2(radius, 0.0), color, 2.0)
		_exp_focus_card.draw_line(p + Vector2(0.0, -radius), p + Vector2(0.0, radius), color, 2.0)


func _build_status_strip(parent: VBoxContainer) -> void:
	var strip := HBoxContainer.new()
	strip.name = "RewardStatusStrip"
	strip.custom_minimum_size = Vector2(0.0, 46.0)
	strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strip.add_theme_constant_override("separation", 8)
	parent.add_child(strip)

	_status_level_label = _status_strip_card(strip, "RewardStatusLevelCard", "プレイヤーLv.", Palette.GOLD_BRIGHT)
	_status_meal_label = _status_strip_card(strip, "RewardStatusMealCard", "効果中の料理", Palette.GAUGE_GREEN_HI)
	_status_cooler_label = _status_strip_card(strip, "RewardStatusCoolerCard", "クーラーボックス", Palette.GAUGE_CYAN_HI)
	_status_money_label = _status_strip_card(strip, "RewardStatusMoneyCard", "所持金", Palette.GOLD_BRIGHT)


func _status_strip_card(parent: HBoxContainer, card_name: String, title: String, accent: Color) -> Label:
	var card := _compact_panel_box(Color("#0d2338"), Color("#07121e"), Palette.GOLD_DEEP, 3)
	card.name = card_name
	card.custom_minimum_size = Vector2(0.0, 38.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)
	var title_label := make_shadow_label(title, 13, Palette.TEXT_BONE, 2)
	title_label.custom_minimum_size = Vector2(84.0, 0.0)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(title_label)
	var value := make_shadow_label("", 16, accent, 2)
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(value)
	return value


func _refresh_status_strip(result: Dictionary) -> void:
	if _status_level_label == null:
		return
	var snapshot := Dictionary(result.get("status_snapshot", {}))
	var level := int(snapshot.get("level", PlayerProgress.level))
	var exp := int(snapshot.get("exp", PlayerProgress.exp))
	var next_exp := int(snapshot.get("exp_max", PlayerProgress.exp_to_next_level()))
	var fish_total := int(snapshot.get("fish_total", _total_fish_count()))
	var money := int(snapshot.get("money", PlayerProgress.money))
	_status_level_label.text = "Lv.%d  %d/%d EXP" % [
		level,
		exp,
		next_exp,
	]
	var buff := Dictionary(result.get("buff", {}))
	_status_meal_label.text = "%s / あと1回" % String(buff.get("name", result.get("dish_name", "料理")))
	_status_cooler_label.text = "%d / 20" % fish_total
	_status_money_label.text = "%d G" % money


func _total_fish_count() -> int:
	var total := 0
	for fish_id in GameData.get_all_fish_ids():
		total += PlayerProgress.fish_count(fish_id)
	return total


func _add_meal_scene_background() -> void:
	_stage_background = TextureRect.new()
	_stage_background.name = "RewardStageBackground"
	_stage_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_stage_background.stretch_mode = TextureRect.STRETCH_SCALE
	_stage_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage_background)
	_set_stage_background(MEAL_SCENE_BG)


func _set_stage_background(path: String) -> void:
	if _stage_background == null:
		return
	var bg_tex := load(path) as Texture2D
	if bg_tex != null:
		_stage_background.texture = bg_tex


func _add_reward_ambient_layer() -> void:
	var ambient := Control.new()
	ambient.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ambient.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ambient)
	ambient.draw.connect(
		func() -> void:
			var steam := Color("#fff1c7")
			var spark := Palette.GOLD_BRIGHT
			for i in range(6):
				var x := 250.0 + float(i) * 154.0
				var y := 440.0 - float(i % 3) * 26.0
				steam.a = 0.11
				ambient.draw_arc(Vector2(x, y), 34.0, -1.65, 1.35, 22, steam, 3.0)
				steam.a = 0.07
				ambient.draw_arc(Vector2(x + 18.0, y - 34.0), 25.0, -1.45, 1.2, 18, steam, 2.0)
			for i in range(14):
				var p := Vector2(126.0 + float((i * 89) % 1030), 96.0 + float((i * 47) % 500))
				var r := 3.0 + float(i % 3)
				spark.a = 0.17 if i % 2 == 0 else 0.10
				ambient.draw_line(p + Vector2(-r, 0.0), p + Vector2(r, 0.0), spark, 2.0)
				ambient.draw_line(p + Vector2(0.0, -r), p + Vector2(0.0, r), spark, 2.0)
	)
	ambient.queue_redraw()


func preview_accept() -> void:
	_close()


func preview_state() -> String:
	return _preview_state


func _add_flow_step(parent: HBoxContainer, text: String) -> void:
	var card := _panel_box(Color("#17324d"), Color("#07121e"), Palette.GOLD_DEEP, 3)
	card.name = "FlowStep_%d" % _flow_step_cards.size()
	card.custom_minimum_size = Vector2(160.0, 28.0)
	parent.add_child(card)
	var label := make_shadow_label(text, 14, Palette.TEXT_BONE, 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card.add_child(label)
	_flow_step_cards.append(card)
	_flow_step_labels.append(label)


func _add_flow_connector(parent: HBoxContainer) -> void:
	var connector := FlowConnectorVisual.new()
	connector.name = "FlowConnector_%d" % _flow_connectors.size()
	connector.custom_minimum_size = Vector2(60.0, 28.0)
	connector.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(connector)
	_flow_connectors.append(connector)


func _refresh_flow_steps(leveled: bool) -> void:
	_set_flow_step(0, "1 食事 完了", Color("#f2e4c2"), Palette.GOLD_BRIGHT, Color("#2a2118"))
	_set_flow_step(1, "2 EXP 加算中", Color("#14385a"), Palette.GAUGE_CYAN_HI, Palette.TEXT_BONE)
	_set_flow_connector(0, "meal_to_exp")
	if leveled:
		_set_flow_step(2, "3 成長 解放", Color("#5a1f26"), Palette.GAUGE_RED_HI, Palette.GOLD_BRIGHT)
		_set_flow_connector(1, "growth_unlock")
	else:
		_set_flow_step(2, "3 成長 進行中", Color("#17324d"), Palette.GOLD_DEEP, Palette.TEXT_BONE)
		_set_flow_connector(1, "exp_to_growth")


func _refresh_meal_steps() -> void:
	_set_flow_step(0, "1 食事 完了", Color("#f2e4c2"), Palette.GOLD_BRIGHT, Color("#2a2118"))
	_set_flow_step(1, "2 EXP 次へ", Color("#17324d"), Palette.GOLD_DEEP, Palette.TEXT_BONE)
	_set_flow_step(2, "3 成長 待機", Color("#17324d"), Palette.GOLD_DEEP, Palette.TEXT_BONE)
	_set_flow_connector(0, "meal_to_exp")
	_set_flow_connector(1, "idle")


func _set_flow_step(index: int, text: String, fill: Color, border: Color, text_color: Color) -> void:
	if index < 0 or index >= _flow_step_cards.size():
		return
	var card := _flow_step_cards[index]
	var label := _flow_step_labels[index]
	card.add_theme_stylebox_override("panel", _style_box(fill, border, Palette.GOLD_BRIGHT, 3, 5))
	label.text = text
	label.add_theme_color_override("font_color", text_color)


func _set_flow_connector(index: int, mode: String) -> void:
	if index < 0 or index >= _flow_connectors.size():
		return
	_flow_connectors[index].set_mode(mode)


func _scene_actor_box() -> PanelContainer:
	var panel := _panel_box(Color("#10283f"), Color("#07121e"), Palette.GOLD_DEEP, 3)
	_scene_actor_image = TextureRect.new()
	_scene_actor_image.name = "MealSceneActor"
	_scene_actor_image.texture = load(PLAYER_EATING_POSE) as Texture2D
	_scene_actor_image.custom_minimum_size = Vector2(148.0, 0.0)
	_scene_actor_image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scene_actor_image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scene_actor_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_scene_actor_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_scene_actor_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_scene_actor_image)
	_scene_actor_visual = SceneActorVisual.new()
	_scene_actor_visual.name = "MealSceneActorFallback"
	_scene_actor_visual.custom_minimum_size = Vector2(110.0, 0.0)
	_scene_actor_visual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scene_actor_visual.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scene_actor_visual.visible = false
	panel.add_child(_scene_actor_visual)
	return panel


func _set_scene_actor_mode(mode: String) -> void:
	if _scene_actor_visual != null:
		_scene_actor_visual.set_mode(mode)
	if _scene_actor_image == null:
		return
	var path := PLAYER_EXP_SCENE_POSE if mode == "exp" else PLAYER_EATING_POSE
	_scene_actor_image.texture = load(path) as Texture2D


func _set_scene_result_art_visible(visible: bool) -> void:
	if _scene_result_image != null:
		_scene_result_image.visible = visible
	if _scene_table != null:
		_scene_table.modulate.a = 0.0 if visible else 1.0


func _set_header_title_font_size(font_size: int) -> void:
	if _header_title != null:
		_header_title.add_theme_font_size_override("font_size", font_size)


func _set_bridge_font_size(font_size: int) -> void:
	if _bridge_label != null:
		_bridge_label.add_theme_font_size_override("font_size", font_size)


func _set_exp_label_font_size(font_size: int) -> void:
	if _exp_label != null:
		_exp_label.add_theme_font_size_override("font_size", font_size)


func _set_result_banner_height(height: float) -> void:
	if _result_banner != null:
		_result_banner.custom_minimum_size = Vector2(0.0, height)


func _build_effect_preview_card(parent: HBoxContainer) -> void:
	_effect_preview_card = _compact_panel_box(Color("#f2e4c2"), Color("#274b2f"), Color("#8ee65a"), 4)
	_effect_preview_card.custom_minimum_size = Vector2(252.0, 208.0)
	_effect_preview_card.visible = false
	parent.add_child(_effect_preview_card)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	_effect_preview_card.add_child(box)

	var title := make_shadow_label("次の釣行で効果！", 16, Color("#fff1c7"), 2)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Palette.TEXT_BONE)
	var title_panel := _compact_panel_box(Color("#173b28"), Color("#07121e"), Palette.GAUGE_GREEN_HI, 3)
	title_panel.custom_minimum_size = Vector2(0.0, 28.0)
	title_panel.add_child(title)
	box.add_child(title_panel)

	_effect_name_label = make_shadow_label("次回効果", 20, Color("#1f6b32"), 2, Color("#fff1c7"))
	_effect_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_effect_name_label)

	_effect_preview_visual = TextureRect.new()
	_effect_preview_visual.name = "NextEffectArt"
	_effect_preview_visual.texture = load(EffectPreviewVisual.EFFECT_ART) as Texture2D
	_effect_preview_visual.custom_minimum_size = Vector2(0.0, 102.0)
	_effect_preview_visual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_effect_preview_visual.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_effect_preview_visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_effect_preview_visual.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(_effect_preview_visual)

	_effect_text_label = make_shadow_label("", 13, Color("#2a2118"), 1, Color("#fff1c7"))
	_effect_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_effect_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_effect_text_label)

	_effect_duration_label = make_shadow_label("", 12, Color("#235f33"), 1, Color("#fff1c7"))
	_effect_duration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_effect_duration_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_effect_duration_label)


func _reward_line(parent: GridContainer, title: String, icon_mode: String, accent: Color) -> Label:
	var card := _compact_panel_box(Color("#f2e4c2"), Color("#60401f"), Color("#d7a456"), 4)
	card.name = _reward_card_node_name(icon_mode)
	card.add_theme_stylebox_override(
		"panel",
		_texture_style_box(
			REWARD_CARD_FRAME,
			22,
			_compact_style_box(Color("#0d2338"), Color("#07121e"), Palette.GOLD_DEEP, 4, 5),
			8.0,
			5.0
		)
	)
	card.custom_minimum_size = Vector2(0.0, 104.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(card)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)
	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", 4)
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(title_row)
	var icon := RewardIconVisual.new()
	icon.configure(icon_mode, accent)
	icon.custom_minimum_size = Vector2(34.0, 30.0)
	title_row.add_child(icon)
	var title_label := make_shadow_label(title, 16, Palette.TEXT_BONE, 2)
	title_label.custom_minimum_size = Vector2(0.0, 24.0)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	title_label.clip_text = true
	title_row.add_child(title_label)
	if icon_mode == "buff":
		var value_row := HBoxContainer.new()
		value_row.add_theme_constant_override("separation", 5)
		value_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(value_row)
		var signal_visual := RewardBuffSignalVisual.new()
		signal_visual.name = "RewardBuffSignal"
		signal_visual.custom_minimum_size = Vector2(54.0, 48.0)
		value_row.add_child(signal_visual)
		var buff_value := make_shadow_label("", 14, accent, 2)
		buff_value.custom_minimum_size = Vector2(0.0, 50.0)
		buff_value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buff_value.size_flags_vertical = Control.SIZE_EXPAND_FILL
		buff_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		buff_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		buff_value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		buff_value.clip_text = false
		value_row.add_child(buff_value)
		return buff_value
	var value_label := make_shadow_label("", 16, accent, 3)
	value_label.custom_minimum_size = Vector2(0.0, 50.0)
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	value_label.clip_text = true
	box.add_child(value_label)
	return value_label


func _reward_card_node_name(icon_mode: String) -> String:
	match icon_mode:
		"exp":
			return "RewardCardBaseExp"
		"bonus":
			return "RewardCardFirstBonus"
		"total":
			return "RewardCardTotalExp"
		"buff":
			return "RewardCardNextEffect"
		"growth":
			return "RewardCardGrowth"
		_:
			return "RewardCard"


func _set_reward_line_visible(label: Label, visible: bool) -> void:
	var row := label.get_parent() as Control
	if row == null:
		return
	var card := row.get_parent() as Control
	if card == null:
		return
	card.visible = visible


func _present() -> void:
	_dialog.modulate.a = 0.0
	_dialog.scale = Vector2(0.86, 0.86)
	await get_tree().process_frame
	_dialog.pivot_offset = _dialog.size * 0.5
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(_dialog, "scale", Vector2.ONE, 0.28)
	tw.parallel().tween_property(_dialog, "modulate:a", 1.0, 0.16)
	tw.tween_callback(_animate_exp)
	Juicer.add_trauma(0.18)


func _animate_exp() -> void:
	if not _exp_focus_card.visible:
		return
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.tween_method(
		func(v: float) -> void:
			_exp_bar.set_value(v),
		_exp_bar.value,
		_target_exp,
		0.55
	)
	tw.tween_callback(_pulse_exp_label)


func _pulse_exp_label() -> void:
	_exp_label.pivot_offset = _exp_label.size * 0.5
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_BACK)
	tw.tween_property(_exp_label, "scale", Vector2(1.12, 1.12), 0.12)
	tw.tween_property(_exp_label, "scale", Vector2.ONE, 0.18)


func _close() -> void:
	if _closing:
		return
	_closing = true
	_confirm_button.disabled = true
	_apply_close_cue()
	_dialog.pivot_offset = _dialog.size * 0.5
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(_dialog, "scale", Vector2(0.92, 0.92), 0.18)
	tw.parallel().tween_property(_dialog, "modulate:a", 0.0, 0.18)
	tw.tween_callback(
		func() -> void:
			closed.emit()
			queue_free()
	)


func _apply_close_cue() -> void:
	match _preview_state:
		"MEAL_RESULT":
			_bridge_label.text = "食経験値へ移ります。料理の力をゲージに送ります。"
			_set_flow_step(1, "2 EXP 起動", Color("#14385a"), Palette.GAUGE_CYAN_HI, Palette.TEXT_BONE)
			_confirm_button.text = "食経験値へ移動中"
		"EXP_GAIN_LEVELUP":
			_bridge_label.text = "成長結果を開きます。"
			_set_flow_step(2, "3 成長 表示", Color("#5a1f26"), Palette.GAUGE_RED_HI, Palette.GOLD_BRIGHT)
			_confirm_button.text = "成長を表示中"
		"EXP_GAIN":
			_bridge_label.text = "食事効果と経験値を保存して、現在の準備へ戻ります。"
			_set_flow_step(2, "3 成長 保存", Color("#17324d"), Palette.GAUGE_CYAN_HI, Palette.TEXT_BONE)
			_confirm_button.text = "準備へ戻っています"
		_:
			pass


func _panel_box(fill: Color, border: Color, inner: Color, border_width: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style_box(fill, border, inner, border_width, 5))
	return panel


func _compact_panel_box(fill: Color, border: Color, inner: Color, border_width: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _compact_style_box(fill, border, inner, border_width, 5))
	return panel


func _style_box(fill: Color, border: Color, inner: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border.lerp(inner, 0.18)
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 14.0
	sb.content_margin_top = 10.0
	sb.content_margin_right = 14.0
	sb.content_margin_bottom = 10.0
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0.0, 3.0)
	sb.anti_aliasing = false
	return sb


func _compact_style_box(fill: Color, border: Color, inner: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border.lerp(inner, 0.18)
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 8.0
	sb.content_margin_top = 5.0
	sb.content_margin_right = 8.0
	sb.content_margin_bottom = 5.0
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	sb.shadow_size = 3
	sb.shadow_offset = Vector2(0.0, 1.0)
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
	var tex := load(DISH_ICON_SHEET) as Texture2D
	if tex == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = tex
	var cell_w := float(tex.get_width()) / 3.0
	var cell_h := float(tex.get_height()) / 2.0
	atlas.region = Rect2(float(icon_index % 3) * cell_w, float(int(icon_index / 3)) * cell_h, cell_w, cell_h)
	return atlas
