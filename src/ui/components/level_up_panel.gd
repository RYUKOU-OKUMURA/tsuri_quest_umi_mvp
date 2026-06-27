extends "res://src/ui/screen_base.gd"
## 調理フローの LEVEL_UP_OVERLAY。
# レベル遷移、能力上昇、Lv.5 解放を一画面の報酬ピークとして見せる。
signal closed

const LEVEL_UP_FRAME := "res://assets/showcase/cooking/level_up_frame.png"
const LEVEL_UNLOCK_RIBBON := "res://assets/showcase/cooking/level_unlock_ribbon.png"
const LEVEL_STAT_ROW_FRAME := "res://assets/showcase/cooking/level_stat_row_frame.png"
const FLOW_ACTION_BUTTON_FRAME := "res://assets/showcase/cooking/flow_action_button_frame.png"


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
		var gold := Color("#ffe081")
		var deep := Color("#8b5515")
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
		draw_polyline(points, Color("#4c2b0b"), 9.0)
		draw_polyline(points, gold, 4.0)
		draw_rect(Rect2(center.x - 54.0, center.y + 10.0, 108.0, 18.0), Color("#4c2b0b"))
		draw_rect(Rect2(center.x - 48.0, center.y + 12.0, 96.0, 12.0), gold)
		for i in range(points.size()):
			var p := points[i]
			draw_circle(p, 7.0, Color("#fff1c7"))
			draw_circle(p, 4.0, Palette.GAUGE_RED_HI if i % 2 == 0 else Palette.GAUGE_CYAN_HI)
		for i in range(5):
			var x := center.x - 32.0 + float(i) * 16.0
			draw_line(Vector2(x, center.y + 14.0), Vector2(x, center.y + 24.0), deep, 2.0)

	func _draw_laurel(direction: float) -> void:
		var center := size * 0.5
		var stem := Color("#8b5515")
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
				PackedColorArray([leaf, leaf, Color("#fff1c7")])
			)
			draw_line(p, p + outward * 0.72, Color("#fff1c7"), 1.0)

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
			PackedColorArray([Color("#8d2430"), Color("#8d2430"), Color("#8d2430"), Color("#5a1f26"), Color("#5a1f26")])
		)
		draw_circle(center, 48.0, Color("#4c2b0b"))
		draw_circle(center, 42.0, Color("#7b4b20"))
		draw_circle(center, 34.0, Color("#d8a13a"))
		draw_circle(center, 25.0, Color("#fff1c7"))
		for i in range(14):
			var a := TAU * float(i) / 14.0
			var from := center + Vector2(cos(a), sin(a)) * 36.0
			var to := center + Vector2(cos(a), sin(a)) * 48.0
			draw_line(from, to, Color("#ffe081"), 3.0)
		draw_arc(center, 42.0, 0.0, TAU, 48, Color("#ffe081"), 3.0)
		draw_ellipse(center + Vector2(-2.0, 0.0), 20.0, 11.0, Color("#3d5360"))
		draw_polygon(
			PackedVector2Array(
				[
					center + Vector2(17.0, -1.0),
					center + Vector2(34.0, -11.0),
					center + Vector2(34.0, 10.0),
				]
			),
			PackedColorArray([Color("#3d5360"), Color("#3d5360"), Color("#3d5360")])
		)
		draw_circle(center + Vector2(-13.0, -2.0), 3.0, Color("#fff1c7"))
		draw_line(center + Vector2(-12.0, 19.0), center + Vector2(14.0, 19.0), Color("#70451f"), 3.0)

	func _draw_spot() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#0d5f8e"))
		draw_rect(Rect2(0.0, 0.0, size.x, size.y * 0.42), Color("#7bc9f5"))
		draw_rect(Rect2(0.0, size.y * 0.55, size.x, size.y * 0.45), Color("#124f7d"))
		draw_polygon(
			PackedVector2Array(
				[
					Vector2(size.x * 0.48, size.y * 0.18),
					Vector2(size.x * 0.68, size.y * 0.74),
					Vector2(size.x * 0.26, size.y * 0.74),
				]
			),
			PackedColorArray([Color("#6f6a56"), Color("#6f6a56"), Color("#6f6a56")])
		)
		draw_rect(Rect2(size.x * 0.70, size.y * 0.26, 18.0, size.y * 0.42), Color("#fff1c7"))
		draw_rect(Rect2(size.x * 0.67, size.y * 0.22, 24.0, 10.0), Color("#1f3654"))
		draw_circle(Vector2(size.x * 0.79, size.y * 0.20), 5.0, Color("#ffe081"))
		for i in range(3):
			var y := size.y * 0.70 + float(i) * 10.0
			draw_line(Vector2(12.0, y), Vector2(size.x - 12.0, y - 6.0), Color(1.0, 1.0, 1.0, 0.28), 2.0)


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
		draw_circle(center, 23.0, Color("#07121e"))
		draw_circle(center, 20.0, accent.darkened(0.20))
		draw_arc(center, 21.0, 0.0, TAU, 36, Palette.GOLD_BRIGHT, 2.0)
		draw_circle(center + Vector2(-6.0, -7.0), 5.0, Color(1.0, 1.0, 1.0, 0.12))

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
		draw_circle(center, 5.0, Color("#fff1c7"))
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
		draw_line(center + Vector2(-15.0, 5.0), center + Vector2(-3.0, 16.0), Color("#fff1c7"), 3.0)
		draw_circle(center + Vector2(-13.0, 13.0), 3.0, Color("#7b4b20"))

	func _draw_target() -> void:
		var center := size * 0.5
		var color := Color("#d9b7ff")
		draw_arc(center, 15.0, 0.0, TAU, 30, color, 3.0)
		draw_arc(center, 8.0, 0.0, TAU, 24, color, 2.0)
		draw_line(center + Vector2(-17.0, 0.0), center + Vector2(17.0, 0.0), color, 3.0)
		draw_line(center + Vector2(0.0, -17.0), center + Vector2(0.0, 17.0), color, 3.0)
		draw_circle(center, 4.0, Palette.GOLD_BRIGHT)


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
		var glow := Color("#fff1c7")
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
		draw_rect(rect.grow(2.0), Color("#07121e"))
		draw_rect(rect, Color("#f2e4c2"))
		draw_line(rect.position + Vector2(2.0, 4.0), rect.position + Vector2(rect.size.x - 2.0, 4.0), Color("#17324d"), 4.0)
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
		draw_circle(center + Vector2(0.0, -2.0), 5.0, Color("#f2b889"))
		draw_rect(Rect2(center.x - 7.0, center.y + 4.0, 14.0, 6.0), Color("#1d4771"))

	func _draw_mini_meal(center: Vector2) -> void:
		draw_arc(center + Vector2(0.0, 5.0), 8.0, 0.0, PI, 12, Color("#9b4f22"), 3.0)
		draw_arc(center + Vector2(0.0, 2.0), 6.0, 0.0, PI, 10, Color("#fff1c7"), 2.0)

	func _draw_mini_cooler(center: Vector2) -> void:
		draw_rect(Rect2(center.x - 8.0, center.y - 2.0, 16.0, 10.0), Color("#1b5d8d"))
		draw_rect(Rect2(center.x - 8.0, center.y - 2.0, 16.0, 3.0), Color("#eef4fa"))

	func _draw_mini_coin(center: Vector2) -> void:
		draw_circle(center + Vector2(-3.0, 2.0), 6.0, Palette.GOLD_BRIGHT)
		draw_circle(center + Vector2(4.0, -1.0), 5.0, Color("#d8a13a"))

	func _draw_mini_clock(center: Vector2) -> void:
		draw_circle(center, 7.0, Color("#fff1c7"))
		draw_arc(center, 7.0, 0.0, TAU, 18, Color("#70451f"), 1.5)
		draw_line(center, center + Vector2(0.0, -5.0), Color("#70451f"), 1.5)
		draw_line(center, center + Vector2(4.0, 2.0), Color("#70451f"), 1.5)


var _dialog: PanelContainer
var _level_line: Label
var _stats_box: GridContainer
var _unlock_card: PanelContainer
var _unlock_ribbon: PanelContainer
var _unlock_ribbon_label: Label
var _unlock_tag: Label
var _unlock_title: Label
var _unlock_body: Label
var _confirm_button: Button


func _build_screen() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.name = "LevelUpDimmer"
	dim.color = Color(0.0, 0.0, 0.0, 0.58)
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
	_dialog.custom_minimum_size = Vector2(930.0, 0.0)
	_dialog.add_theme_stylebox_override(
		"panel",
		_texture_style_box(
			LEVEL_UP_FRAME,
			36,
			_style_box(Color("#10233a"), Color("#7b4b20"), Palette.GOLD_BRIGHT, 6, 8),
			22.0,
			12.0
		)
	)
	center.add_child(_dialog)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 5)
	_dialog.add_child(box)

	var title_band := HBoxContainer.new()
	title_band.name = "LevelUpTitleBand"
	title_band.alignment = BoxContainer.ALIGNMENT_CENTER
	title_band.add_theme_constant_override("separation", 8)
	title_band.custom_minimum_size = Vector2(840.0, 92.0)
	title_band.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(title_band)

	var left_laurel := LevelUpVisual.new()
	left_laurel.name = "LevelLaurelLeftAsset"
	left_laurel.configure("laurel_left")
	left_laurel.custom_minimum_size = Vector2(108.0, 86.0)
	title_band.add_child(left_laurel)

	var title_stack := VBoxContainer.new()
	title_stack.alignment = BoxContainer.ALIGNMENT_CENTER
	title_stack.add_theme_constant_override("separation", 0)
	title_stack.custom_minimum_size = Vector2(580.0, 0.0)
	title_band.add_child(title_stack)

	var crown_visual := LevelUpVisual.new()
	crown_visual.name = "LevelCrownAsset"
	crown_visual.configure("crown")
	crown_visual.custom_minimum_size = Vector2(148.0, 34.0)
	crown_visual.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	title_stack.add_child(crown_visual)
	var crown_label := make_shadow_label("成長の証", 16, Palette.GOLD_BRIGHT, 3)
	crown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_stack.add_child(crown_label)

	var title := make_shadow_label("LEVEL UP!", 56, Palette.GOLD_BRIGHT, 5)
	title.name = "LevelUpTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_stack.add_child(title)

	var right_laurel := LevelUpVisual.new()
	right_laurel.name = "LevelLaurelRightAsset"
	right_laurel.configure("laurel_right")
	right_laurel.custom_minimum_size = Vector2(108.0, 86.0)
	title_band.add_child(right_laurel)

	_level_line = make_shadow_label("", 34, Palette.TEXT_BONE, 4)
	_level_line.name = "LevelUpLevelLine"
	_level_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_level_line)

	var source_line := make_shadow_label("食経験値が成長に変わった", 20, Palette.GAUGE_GREEN_HI, 3)
	source_line.name = "LevelUpSourceLine"
	source_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(source_line)

	_stats_box = GridContainer.new()
	_stats_box.columns = 2
	_stats_box.add_theme_constant_override("h_separation", 10)
	_stats_box.add_theme_constant_override("v_separation", 7)
	_stats_box.custom_minimum_size = Vector2(820.0, 0.0)
	_stats_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_stats_box)

	_unlock_card = _panel_box(Color("#f2e4c2"), Color("#70451f"), Palette.GOLD_BRIGHT, 5)
	_unlock_card.custom_minimum_size = Vector2(820.0, 130.0)
	_unlock_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(_unlock_card)
	var unlock_root := VBoxContainer.new()
	unlock_root.add_theme_constant_override("separation", 6)
	_unlock_card.add_child(unlock_root)
	_unlock_ribbon = PanelContainer.new()
	_unlock_ribbon.name = "LevelUnlockRibbonAsset"
	_unlock_ribbon.add_theme_stylebox_override(
		"panel",
		_texture_style_box(
			LEVEL_UNLOCK_RIBBON,
			24,
			_style_box(Color("#8d2430"), Color("#4c111a"), Palette.GOLD_BRIGHT, 3, 5),
			12.0,
			5.0
		)
	)
	_unlock_ribbon.custom_minimum_size = Vector2(0.0, 34.0)
	unlock_root.add_child(_unlock_ribbon)
	_unlock_ribbon_label = make_shadow_label("新たな釣り場が解放！", 22, Color("#fff4d4"), 3)
	_unlock_ribbon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_unlock_ribbon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_unlock_ribbon.add_child(_unlock_ribbon_label)

	var unlock_layout := HBoxContainer.new()
	unlock_layout.add_theme_constant_override("separation", 12)
	unlock_root.add_child(unlock_layout)
	var unlock_icon := _medal_box()
	unlock_icon.custom_minimum_size = Vector2(112.0, 0.0)
	unlock_layout.add_child(unlock_icon)
	var unlock_text := VBoxContainer.new()
	unlock_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unlock_text.add_theme_constant_override("separation", 2)
	unlock_layout.add_child(unlock_text)
	_unlock_tag = make_shadow_label("", 16, Palette.GAUGE_RED_HI, 2)
	unlock_text.add_child(_unlock_tag)
	_unlock_title = make_label("", 22, Color("#2a2118"), 1, Color("#fff4d4"))
	unlock_text.add_child(_unlock_title)
	_unlock_body = make_label("", 17, Color("#4d3924"))
	_unlock_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	unlock_text.add_child(_unlock_body)
	var summary_cue := LevelToSummaryCueVisual.new()
	summary_cue.name = "LevelToSummaryCue"
	summary_cue.custom_minimum_size = Vector2(0.0, 24.0)
	summary_cue.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unlock_text.add_child(summary_cue)
	var spot := _spot_thumbnail_box()
	spot.custom_minimum_size = Vector2(196.0, 86.0)
	unlock_layout.add_child(spot)

	_confirm_button = make_button("OK  成果確認へ", _close, 286.0, true)
	_confirm_button.name = "LevelUpConfirmButton"
	_confirm_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_apply_flow_button_style(_confirm_button)
	_confirm_button.draw.connect(func() -> void: _draw_confirm_button_cue(_confirm_button))
	box.add_child(_confirm_button)


func show_level_up(
	level_from: int, level_to: int, old_stats: Dictionary, new_stats: Dictionary
) -> void:
	_level_line.text = "Lv.%d   ->   Lv.%d" % [level_from, level_to]
	_rebuild_stats(old_stats, new_stats)
	var boss_unlocked := (
		level_from < GameData.BOSS_UNLOCK_LEVEL and level_to >= GameData.BOSS_UNLOCK_LEVEL
	)
	_unlock_card.visible = boss_unlocked
	_unlock_ribbon.visible = boss_unlocked
	if boss_unlocked:
		_unlock_tag.text = "挑戦解放"
		_unlock_title.text = "港のぬしに挑戦できるようになった！"
		_unlock_body.text = "食事でLv.%d到達。次の目標：港のぬし。港の大岩周辺で、本格ファイトが解放されます。" % GameData.BOSS_UNLOCK_LEVEL
	_present()


func preview_accept() -> void:
	_close()


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
			"color": Color("#d9b7ff"),
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
		_texture_style_box(
			LEVEL_STAT_ROW_FRAME,
			18,
			_style_box(Color("#17324d"), Color("#07121e"), Palette.GOLD_DEEP, 3, 5),
			12.0,
			5.0
		)
	)
	panel.custom_minimum_size = Vector2(0.0, 54.0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 8)
	panel.add_child(line)

	var icon := _stat_icon(String(row["icon"]), row["color"])
	icon.custom_minimum_size = Vector2(52.0, 0.0)
	line.add_child(icon)

	var name := make_label(String(row["name"]), 20, Palette.TEXT_BONE, 2)
	name.custom_minimum_size = Vector2(104.0, 0.0)
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(name)

	var fmt := String(row["fmt"])
	var old_text := fmt % old_value
	var new_text := fmt % new_value
	var values := make_shadow_label("%s  ->  %s" % [old_text, new_text], 24, Palette.TEXT_BONE, 3)
	values.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	values.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	values.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(values)

	var gain_text := "%.1f" % delta if fmt == "%.1f" else "%d" % int(round(delta))
	var gain := make_shadow_label("+%s" % gain_text, 22, Palette.GAUGE_GREEN_HI, 3)
	if absf(delta) < 0.01:
		gain.text = "-"
	gain.custom_minimum_size = Vector2(70.0, 0.0)
	gain.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	gain.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.add_child(gain)
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


func _stat_icon(mode: String, accent: Color) -> LevelStatIconVisual:
	var icon := LevelStatIconVisual.new()
	icon.configure(mode, accent)
	icon.custom_minimum_size = Vector2(52.0, 44.0)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func _badge_box(text: String, fill: Color, text_color: Color) -> PanelContainer:
	var badge := PanelContainer.new()
	badge.add_theme_stylebox_override(
		"panel",
		_style_box(fill.darkened(0.18), Color("#07121e"), Palette.GOLD_BRIGHT, 2, 4)
	)
	var label := make_shadow_label(text, 17, text_color, 2)
	label.custom_minimum_size = Vector2(54.0, 0.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	badge.add_child(label)
	return badge


func _medal_box() -> PanelContainer:
	var medal := _panel_box(Color("#6a4515"), Color("#2d1a09"), Palette.GOLD_BRIGHT, 4)
	var visual := LevelUpVisual.new()
	visual.name = "LevelUnlockMedallionAsset"
	visual.configure("medal")
	visual.custom_minimum_size = Vector2(106.0, 84.0)
	visual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	visual.size_flags_vertical = Control.SIZE_EXPAND_FILL
	medal.add_child(visual)
	return medal


func _spot_thumbnail_box() -> PanelContainer:
	var panel := _panel_box(Color("#0b3c62"), Color("#07121e"), Palette.GOLD_BRIGHT, 4)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	var tag := make_shadow_label("新釣り場", 15, Palette.GOLD_BRIGHT, 2)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tag)
	var visual := LevelUpVisual.new()
	visual.name = "LevelUnlockSpotAsset"
	visual.configure("spot")
	visual.custom_minimum_size = Vector2(0.0, 48.0)
	visual.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(visual)
	var title := make_shadow_label("港の大岩", 22, Palette.TEXT_BONE, 3)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var sea := make_shadow_label("外洋への挑戦", 16, Palette.GAUGE_CYAN_HI, 2)
	sea.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sea)
	return panel


func _add_burst_layer() -> void:
	var burst := Control.new()
	burst.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(burst)
	burst.draw.connect(
		func() -> void:
			var center := burst.size * 0.5
			for i in range(28):
				var a := TAU * float(i) / 28.0
				var inner := center + Vector2(cos(a), sin(a)) * 135.0
				var outer := center + Vector2(cos(a), sin(a)) * 390.0
				var color := Palette.GOLD_BRIGHT
				color.a = 0.22 if i % 2 == 0 else 0.10
				burst.draw_line(inner, outer, color, 5.0)
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
			crown_color.a = 0.30
			burst.draw_polyline(crown, crown_color, 5.0)
			var laurel := Palette.GOLD_BRIGHT
			laurel.a = 0.24
			burst.draw_arc(center + Vector2(-315.0, -185.0), 66.0, -1.25, 1.15, 18, laurel, 5.0)
			burst.draw_arc(center + Vector2(315.0, -185.0), 66.0, 1.99, 4.39, 18, laurel, 5.0)
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
				Color("#d9b7ff"),
			]
			for i in range(34):
				var x := 82.0 + float((i * 143) % 1120)
				var y := 38.0 + float((i * 59) % 560)
				var s := 4.0 + float(i % 4)
				var color: Color = colors[i % colors.size()]
				color.a = 0.62
				confetti.draw_rect(Rect2(Vector2(x, y), Vector2(s + 5.0, s)), color)
			var spark := Palette.GOLD_BRIGHT
			for i in range(16):
				var p := Vector2(130.0 + float((i * 211) % 1000), 84.0 + float((i * 97) % 470))
				var r := 4.0 + float(i % 3)
				spark.a = 0.38
				confetti.draw_line(p + Vector2(-r, 0.0), p + Vector2(r, 0.0), spark, 2.0)
				confetti.draw_line(p + Vector2(0.0, -r), p + Vector2(0.0, r), spark, 2.0)
	)
	confetti.queue_redraw()


func _present() -> void:
	_dialog.modulate.a = 0.0
	_dialog.scale = Vector2(0.82, 0.82)
	await get_tree().process_frame
	_dialog.pivot_offset = _dialog.size * 0.5
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
	var normal_fallback := _style_box(Color("#102f51"), Palette.GOLD_DEEP, Palette.GOLD_BRIGHT, 4, 6)
	var hover_fallback := _style_box(Color("#16436c"), Palette.GOLD_BRIGHT, Color("#fff0b2"), 4, 6)
	var pressed_fallback := _style_box(Color("#081a2d"), Color("#a06d28"), Palette.GOLD_DEEP, 4, 6)
	var disabled_fallback := _style_box(Color("#202a31"), Color("#71614a"), Color("#8c7b62"), 3, 6)
	button.add_theme_stylebox_override(
		"normal",
		_texture_style_box(FLOW_ACTION_BUTTON_FRAME, 24, normal_fallback, 76.0, 8.0)
	)
	button.add_theme_stylebox_override(
		"hover",
		_texture_style_box(FLOW_ACTION_BUTTON_FRAME, 24, hover_fallback, 76.0, 8.0)
	)
	button.add_theme_stylebox_override(
		"pressed",
		_texture_style_box(FLOW_ACTION_BUTTON_FRAME, 24, pressed_fallback, 76.0, 8.0)
	)
	button.add_theme_stylebox_override(
		"disabled",
		_texture_style_box(FLOW_ACTION_BUTTON_FRAME, 24, disabled_fallback, 76.0, 8.0)
	)
	button.add_theme_stylebox_override(
		"focus",
		_texture_style_box(FLOW_ACTION_BUTTON_FRAME, 24, hover_fallback, 76.0, 8.0)
	)
	button.add_theme_color_override("font_color", Palette.GOLD_BRIGHT)
	button.add_theme_color_override("font_hover_color", Color("#fff1ba"))
	button.add_theme_color_override("font_pressed_color", Color("#f0c06b"))
	button.add_theme_color_override("font_disabled_color", Color("#b6a68d"))


func _draw_confirm_button_cue(button: Button) -> void:
	var h := maxf(button.size.y, 1.0)
	var center_y := h * 0.5
	var gold := Palette.GOLD_BRIGHT
	var ink := Color("#4c2b0b")
	var glow := Color("#fff1c7")
	glow.a = 0.24

	var crown_center := Vector2(30.0, center_y)
	var crown := PackedVector2Array(
		[
			crown_center + Vector2(-15.0, 4.0),
			crown_center + Vector2(-10.0, -8.0),
			crown_center + Vector2(-3.0, 1.0),
			crown_center + Vector2(0.0, -11.0),
			crown_center + Vector2(3.0, 1.0),
			crown_center + Vector2(10.0, -8.0),
			crown_center + Vector2(15.0, 4.0),
		]
	)
	button.draw_polyline(crown, ink, 5.0)
	button.draw_polyline(crown, gold, 2.0)
	button.draw_rect(Rect2(crown_center.x - 13.0, crown_center.y + 4.0, 26.0, 6.0), ink)
	button.draw_rect(Rect2(crown_center.x - 10.0, crown_center.y + 5.0, 20.0, 3.0), glow)

	var arrow_from := Vector2(52.0, center_y)
	var arrow_to := Vector2(78.0, center_y)
	button.draw_line(arrow_from, arrow_to, glow, 6.0)
	button.draw_line(arrow_from, arrow_to, gold, 2.0)
	button.draw_polygon(
		PackedVector2Array(
			[
				arrow_to + Vector2(7.0, 0.0),
				arrow_to + Vector2(-3.0, -5.0),
				arrow_to + Vector2(-3.0, 5.0),
			]
		),
		PackedColorArray([gold, gold, gold])
	)

	for i in range(3):
		var x := 98.0 + float(i) * 15.0
		var rect := Rect2(x - 5.0, center_y - 8.0, 11.0, 15.0)
		button.draw_rect(rect.grow(1.5), ink)
		button.draw_rect(rect, Color("#f2e4c2"))
		button.draw_line(rect.position + Vector2(1.0, 3.0), rect.position + Vector2(rect.size.x - 1.0, 3.0), Color("#17324d"), 2.0)
		if i == 0:
			button.draw_circle(rect.position + Vector2(5.5, 9.0), 3.0, Color("#f2b889"))
		elif i == 1:
			button.draw_arc(rect.position + Vector2(5.5, 10.0), 4.0, 0.0, PI, 8, Color("#9b4f22"), 2.0)
		else:
			button.draw_circle(rect.position + Vector2(5.5, 9.0), 3.5, gold)


func _clear_container(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _panel_box(fill: Color, border: Color, inner: Color, border_width: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style_box(fill, border, inner, border_width, 5))
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
	sb.expand_margin_left = 7.0
	sb.expand_margin_top = 7.0
	sb.expand_margin_right = 7.0
	sb.expand_margin_bottom = 7.0
	sb.content_margin_left = content_x
	sb.content_margin_top = content_y
	sb.content_margin_right = content_x
	sb.content_margin_bottom = content_y
	return sb
