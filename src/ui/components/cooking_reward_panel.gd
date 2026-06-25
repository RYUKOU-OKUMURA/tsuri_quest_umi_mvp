extends "res://src/ui/screen_base.gd"
## 調理後の MEAL_RESULT / EXP_GAIN を担う報酬オーバーレイ。
# 料理を食べた結果、EXP、初回ボーナス、次回バフを一拍置いて見せる。
signal closed

const GaugeBarScript = preload("res://src/ui/components/gauge_bar.gd")

const DISH_FEATURE_AJI := "res://assets/showcase/cooking/dish_feature_aji_shioyaki.png"
const DISH_ICON_SHEET := "res://assets/showcase/cooking/dish_icon_sheet.png"
const MEAL_SCENE_BG := "res://assets/showcase/cooking/meal_scene_bg.png"
const MEAL_RESULT_FRAME := "res://assets/showcase/cooking/meal_result_frame.png"


class SceneActorVisual:
	extends Control

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

	var mode := "exp"
	var accent := Color("#6bf1ff")

	func configure(next_mode: String, next_accent: Color) -> void:
		mode = next_mode
		accent = next_accent
		queue_redraw()

	func _draw() -> void:
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


class EffectPreviewVisual:
	extends Control

	func _draw() -> void:
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


var _dialog: PanelContainer
var _header_title: Label
var _bridge_label: Label
var _dish_title: Label
var _dish_image: TextureRect
var _dish_card: PanelContainer
var _scene_title: Label
var _scene_caption: Label
var _scene_bonus_label: Label
var _scene_dish_image: TextureRect
var _scene_actor_visual: SceneActorVisual
var _exp_trail_visual: ExpTrailVisual
var _exp_focus_card: PanelContainer
var _exp_message_label: Label
var _effect_preview_card: PanelContainer
var _effect_preview_visual: EffectPreviewVisual
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
	_dialog.custom_minimum_size = Vector2(1150.0, 0.0)
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
	root.add_theme_constant_override("separation", 2)
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
	hero.add_theme_constant_override("separation", 10)
	root.add_child(hero)

	var scene_card := _panel_box(Color("#22150c"), Color("#5e391a"), Palette.GOLD_BRIGHT, 5)
	scene_card.custom_minimum_size = Vector2(430.0, 152.0)
	hero.add_child(scene_card)
	var scene_box := VBoxContainer.new()
	scene_box.add_theme_constant_override("separation", 6)
	scene_card.add_child(scene_box)
	_scene_title = make_shadow_label("食べる", 24, Palette.GOLD_BRIGHT, 3)
	_scene_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene_box.add_child(_scene_title)
	var table := HBoxContainer.new()
	table.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table.add_theme_constant_override("separation", 10)
	scene_box.add_child(table)
	var eater := _scene_actor_box()
	eater.custom_minimum_size = Vector2(136.0, 0.0)
	table.add_child(eater)
	_scene_dish_image = TextureRect.new()
	_scene_dish_image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scene_dish_image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scene_dish_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_scene_dish_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	table.add_child(_scene_dish_image)
	_scene_caption = make_shadow_label("湯気の立つ料理を味わった。", 17, Palette.TEXT_BONE, 2)
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

	var banner := _panel_box(Color("#f2e4c2"), Color("#5e391a"), Palette.GOLD_BRIGHT, 5)
	banner.custom_minimum_size = Vector2(0.0, 58.0)
	right.add_child(banner)
	var banner_box := VBoxContainer.new()
	banner_box.add_theme_constant_override("separation", 2)
	banner.add_child(banner_box)
	_header_title = make_shadow_label("いただきます！", 32, Color("#9b2f17"), 3)
	_header_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_box.add_child(_header_title)
	_bridge_label = make_shadow_label("", 18, Color("#4f3b25"), 1)
	_bridge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bridge_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner_box.add_child(_bridge_label)

	_dish_card = _panel_box(Color("#0f2238"), Color("#07121e"), Palette.GOLD_DEEP, 5)
	_dish_card.custom_minimum_size = Vector2(0.0, 104.0)
	right.add_child(_dish_card)
	var dish_row := HBoxContainer.new()
	dish_row.add_theme_constant_override("separation", 14)
	_dish_card.add_child(dish_row)
	_dish_image = TextureRect.new()
	_dish_image.custom_minimum_size = Vector2(238.0, 0.0)
	_dish_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dish_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dish_row.add_child(_dish_image)
	var dish_text := VBoxContainer.new()
	dish_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dish_text.alignment = BoxContainer.ALIGNMENT_CENTER
	dish_row.add_child(dish_text)
	var dish_tag := make_shadow_label("今回の料理", 18, Palette.GOLD_BRIGHT, 2)
	dish_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dish_text.add_child(dish_tag)
	_dish_title = make_shadow_label("", 29, Palette.TEXT_BONE, 3)
	_dish_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dish_text.add_child(_dish_title)
	var dish_note := make_shadow_label("料理を食べて、体に力が湧いてきた。", 17, Palette.TEXT_BONE, 2)
	dish_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dish_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dish_text.add_child(dish_note)

	_exp_focus_card = _panel_box(Color("#071e34"), Color("#07121e"), Palette.GAUGE_CYAN_HI, 5)
	_exp_focus_card.custom_minimum_size = Vector2(0.0, 104.0)
	_exp_focus_card.visible = false
	right.add_child(_exp_focus_card)
	var exp_focus_box := VBoxContainer.new()
	exp_focus_box.add_theme_constant_override("separation", 4)
	_exp_focus_card.add_child(exp_focus_box)
	_exp_focus_card.draw.connect(_draw_exp_focus_burst)
	var exp_focus_tag := make_shadow_label("食経験値", 20, Palette.TEXT_BONE, 3)
	exp_focus_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exp_focus_box.add_child(exp_focus_tag)
	_exp_label = make_shadow_label("+0 EXP", 36, Palette.GOLD_BRIGHT, 5)
	_exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exp_focus_box.add_child(_exp_label)
	_exp_bar = GaugeBarScript.new()
	_exp_bar.show_value = false
	_exp_bar.custom_minimum_size = Vector2(0.0, 30.0)
	_exp_bar.set_colors(Palette.GAUGE_CYAN, Palette.GAUGE_CYAN_HI)
	exp_focus_box.add_child(_exp_bar)
	_exp_progress_label = make_shadow_label("", 20, Palette.GAUGE_CYAN_HI, 2)
	_exp_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exp_focus_box.add_child(_exp_progress_label)
	_exp_message_label = make_shadow_label("体に力がみなぎってきた！", 17, Palette.TEXT_BONE, 2)
	_exp_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_exp_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	exp_focus_box.add_child(_exp_message_label)

	_build_effect_preview_card(hero)

	_reward_grid = GridContainer.new()
	_reward_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reward_grid.add_theme_constant_override("h_separation", 6)
	_reward_grid.add_theme_constant_override("v_separation", 4)
	root.add_child(_reward_grid)

	_exp_card = _panel_box(Color("#0f2238"), Color("#07121e"), Palette.GOLD_DEEP, 5)
	_exp_card.custom_minimum_size = Vector2(300.0, 120.0)
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
	_confirm_button.custom_minimum_size = Vector2(250.0, 34.0)
	_confirm_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(_confirm_button)


func show_meal_result(result: Dictionary) -> void:
	_preview_state = "MEAL_RESULT"
	var dish_name := String(result.get("dish_name", "料理"))
	_header_title.text = "%sを\n食べた！" % dish_name
	_bridge_label.text = "%sで次の釣行効果を予約。食経験値は次に加算される。" % dish_name
	_dish_title.text = "%sを食べた！" % dish_name
	var dish_texture := _featured_dish_texture(String(Dictionary(result.get("buff", {})).get("recipe_id", "")))
	_dish_image.texture = dish_texture
	_scene_dish_image.texture = dish_texture
	_scene_caption.text = "湯気の立つ%sを味わった。" % dish_name
	_scene_bonus_label.text = _meal_bonus_badge_text(result)
	_scene_title.text = "食べる"
	_scene_actor_visual.set_mode("meal")
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
		_bonus_label.text = "記録済み。今回は基本EXPのみ。"
	_total_label.text = "合計獲得食経験値\n+%d EXP" % int(result.get("total_exp", 0))

	var buff := Dictionary(result.get("buff", {}))
	_buff_label.text = "次回の釣行で効果を発揮！\n%s" % _buff_effect_text(buff)
	_refresh_status_strip(result)
	_set_reward_line_visible(_growth_label, false)
	_confirm_button.text = "食経験値へ進む"
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
	var dish_name := String(result.get("dish_name", "料理"))
	_header_title.text = "食経験値が成長へ！" if leveled else "食経験値を獲得！"
	_bridge_label.text = _growth_bridge_text(dish_name, leveled, level_before, level_after)
	_dish_title.text = "%sを食べた！" % dish_name
	var dish_texture := _featured_dish_texture(String(Dictionary(result.get("buff", {})).get("recipe_id", "")))
	_dish_image.texture = dish_texture
	_scene_dish_image.texture = dish_texture
	_scene_title.text = "食べた料理"
	_scene_actor_visual.set_mode("exp")
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
		_bonus_label.text = "初めて食べた料理！ 追加 +%d EXP" % int(result.get("first_bonus", 0))
	else:
		_bonus_label.text = "記録済み。今回は基本EXPのみ。"
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
	_refresh_flow_steps(leveled)
	_present()


func _growth_bridge_text(
	dish_name: String, leveled: bool, level_before: int, level_after: int
) -> String:
	if leveled and level_before > 0 and level_after > level_before:
		return "%sの食経験値が Lv.%d 到達を後押しした。" % [dish_name, level_after]
	return "%sの食経験値がたまり、次の釣行効果も予約された。" % dish_name


func _buff_effect_text(buff: Dictionary) -> String:
	var text := String(buff.get("text", "次の釣行で効果を得る"))
	if text.begins_with("次の釣行で"):
		text = text.trim_prefix("次の釣行で")
	return "%s / 1回発動" % text


func _meal_bonus_badge_text(result: Dictionary) -> String:
	if bool(result.get("first_time", false)):
		return "初回ボーナス +%d EXP" % int(result.get("first_bonus", 0))
	return "初回 記録済み"


func _draw_exp_focus_burst() -> void:
	if _exp_focus_card == null or not _exp_focus_card.visible:
		return
	var rect := Rect2(Vector2.ZERO, _exp_focus_card.size)
	var center := Vector2(rect.size.x * 0.5, rect.size.y * 0.48)
	var gold := Palette.GOLD_BRIGHT
	var cyan := Palette.GAUGE_CYAN_HI
	for i in range(18):
		var angle := TAU * float(i) / 18.0
		var from := center + Vector2(cos(angle), sin(angle)) * 20.0
		var to := center + Vector2(cos(angle), sin(angle)) * 210.0
		var color := gold if i % 2 == 0 else cyan
		color.a = 0.12 if i % 2 == 0 else 0.08
		_exp_focus_card.draw_line(from, to, color, 4.0)
	for i in range(5):
		var width := rect.size.x - 68.0 - float(i) * 18.0
		var y := rect.size.y * 0.62 + float(i) * 2.0
		var color := cyan
		color.a = 0.10 - float(i) * 0.012
		_exp_focus_card.draw_rect(
			Rect2(Vector2((rect.size.x - width) * 0.5, y), Vector2(width, 10.0)),
			color
		)
	for i in range(16):
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
	strip.custom_minimum_size = Vector2(0.0, 38.0)
	strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	strip.add_theme_constant_override("separation", 8)
	parent.add_child(strip)

	_status_level_label = _status_strip_card(strip, "プレイヤーLv.", Palette.GOLD_BRIGHT)
	_status_meal_label = _status_strip_card(strip, "効果中の料理", Palette.GAUGE_GREEN_HI)
	_status_cooler_label = _status_strip_card(strip, "クーラーボックス", Palette.GAUGE_CYAN_HI)
	_status_money_label = _status_strip_card(strip, "所持金", Palette.GOLD_BRIGHT)


func _status_strip_card(parent: HBoxContainer, title: String, accent: Color) -> Label:
	var card := _compact_panel_box(Color("#0d2338"), Color("#07121e"), Palette.GOLD_DEEP, 3)
	card.custom_minimum_size = Vector2(0.0, 30.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(card)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.add_child(row)
	var title_label := make_shadow_label(title, 12, Palette.TEXT_BONE, 2)
	title_label.custom_minimum_size = Vector2(84.0, 0.0)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(title_label)
	var value := make_shadow_label("", 15, accent, 2)
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
	var bg_tex := load(MEAL_SCENE_BG) as Texture2D
	if bg_tex == null:
		return
	var bg := TextureRect.new()
	bg.texture = bg_tex
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)


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
	_scene_actor_visual = SceneActorVisual.new()
	_scene_actor_visual.custom_minimum_size = Vector2(110.0, 0.0)
	_scene_actor_visual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scene_actor_visual.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(_scene_actor_visual)
	return panel


func _build_effect_preview_card(parent: HBoxContainer) -> void:
	_effect_preview_card = _compact_panel_box(Color("#f2e4c2"), Color("#274b2f"), Color("#8ee65a"), 4)
	_effect_preview_card.custom_minimum_size = Vector2(232.0, 146.0)
	_effect_preview_card.visible = false
	parent.add_child(_effect_preview_card)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	_effect_preview_card.add_child(box)

	var title := make_shadow_label("次の釣行で効果！", 15, Color("#fff1c7"), 2)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Palette.TEXT_BONE)
	var title_panel := _compact_panel_box(Color("#173b28"), Color("#07121e"), Palette.GAUGE_GREEN_HI, 3)
	title_panel.custom_minimum_size = Vector2(0.0, 24.0)
	title_panel.add_child(title)
	box.add_child(title_panel)

	_effect_name_label = make_shadow_label("次回効果", 19, Color("#1f6b32"), 2, Color("#fff1c7"))
	_effect_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_effect_name_label)

	_effect_preview_visual = EffectPreviewVisual.new()
	_effect_preview_visual.custom_minimum_size = Vector2(0.0, 42.0)
	_effect_preview_visual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_effect_preview_visual.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_effect_preview_visual)

	_effect_text_label = make_shadow_label("", 12, Color("#2a2118"), 1, Color("#fff1c7"))
	_effect_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_effect_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_effect_text_label)

	_effect_duration_label = make_shadow_label("", 11, Color("#235f33"), 1, Color("#fff1c7"))
	_effect_duration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_effect_duration_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_effect_duration_label)


func _reward_line(parent: GridContainer, title: String, icon_mode: String, accent: Color) -> Label:
	var card := _compact_panel_box(Color("#f2e4c2"), Color("#60401f"), Color("#d7a456"), 4)
	card.custom_minimum_size = Vector2(0.0, 54.0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(card)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	card.add_child(box)
	var title_row := HBoxContainer.new()
	title_row.alignment = BoxContainer.ALIGNMENT_CENTER
	title_row.add_theme_constant_override("separation", 4)
	box.add_child(title_row)
	var icon := RewardIconVisual.new()
	icon.configure(icon_mode, accent)
	icon.custom_minimum_size = Vector2(18.0, 15.0)
	title_row.add_child(icon)
	var title_label := make_shadow_label(title, 13, Color("#60411f"), 1)
	title_label.custom_minimum_size = Vector2(0.0, 15.0)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_row.add_child(title_label)
	var value_label := make_shadow_label("", 14, accent, 2)
	value_label.custom_minimum_size = Vector2(0.0, 24.0)
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(value_label)
	return value_label


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
	_dialog.pivot_offset = _dialog.size * 0.5
	var tw := create_tween()
	tw.set_ease(Tween.EASE_IN)
	tw.set_trans(Tween.TRANS_QUAD)
	tw.tween_property(_dialog, "scale", Vector2(0.88, 0.88), 0.14)
	tw.parallel().tween_property(_dialog, "modulate:a", 0.0, 0.14)
	tw.tween_callback(
		func() -> void:
			closed.emit()
			queue_free()
	)


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
	if recipe_id == "salt_grill":
		return load(DISH_FEATURE_AJI) as Texture2D
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
