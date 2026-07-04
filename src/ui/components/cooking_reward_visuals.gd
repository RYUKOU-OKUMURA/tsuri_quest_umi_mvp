extends RefCounted
## cooking_reward_panel の描画専用 Visual クラス集（behavior-preserving 抽出）

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
	const DISH_ICONS := "res://assets/showcase/cooking/dish_icon_sheet.png"

	var mode := "meal"
	var dish_texture: Texture2D
	var recipe_id := ""
	var _table_spread_texture: Texture2D

	func set_mode(next_mode: String) -> void:
		mode = next_mode
		queue_redraw()

	func set_dish_texture(texture: Texture2D) -> void:
		dish_texture = texture
		queue_redraw()

	func set_recipe_id(next_recipe_id: String) -> void:
		recipe_id = next_recipe_id
		queue_redraw()

	func _draw() -> void:
		if mode == "meal":
			_draw_meal_table_scene()
			return
		_draw_dish_source()

	func _draw_meal_table_scene() -> void:
		var table_rect := Rect2(
			Vector2(size.x * 0.00, size.y * 0.55),
			Vector2(size.x, size.y * 0.38)
		)
		draw_rect(table_rect, Color(0.26, 0.12, 0.04, 0.58))
		draw_line(
			table_rect.position + Vector2(0.0, 4.0),
			table_rect.position + Vector2(table_rect.size.x, 4.0),
			Color(0.96, 0.70, 0.34, 0.34),
			2.0
		)
		for i in range(3):
			var y := table_rect.position.y + 18.0 + float(i) * 28.0
			draw_line(
				Vector2(table_rect.position.x + 10.0, y),
				Vector2(table_rect.end.x - 10.0, y + sin(float(i)) * 4.0),
				Color(0.68, 0.36, 0.14, 0.18),
				2.0
		)
		draw_ellipse(Vector2(size.x * 0.54, size.y * 0.77), size.x * 0.46, 18.0, Color(0.0, 0.0, 0.0, 0.28))
		if not _draw_table_spread_asset():
			if not _draw_dish_icon_spread():
				_draw_feature_dish_on_table()
			_draw_side_dishes()
		_draw_meal_sparkles()

	func _draw_table_spread_asset() -> bool:
		if recipe_id != "salt_grill":
			return false
		var tex := _table_spread_texture
		if tex == null:
			var image := Image.load_from_file(ProjectSettings.globalize_path(TABLE_SPREAD))
			if image != null and not image.is_empty():
				_table_spread_texture = ImageTexture.create_from_image(image)
				tex = _table_spread_texture
		if tex == null:
			return false
		var tex_size := Vector2(float(tex.get_width()), float(tex.get_height()))
		if tex_size.x <= 0.0 or tex_size.y <= 0.0 or size.x <= 0.0 or size.y <= 0.0:
			return false
		var scale := minf(size.x * 0.98 / tex_size.x, size.y * 0.72 / tex_size.y)
		var draw_size := tex_size * scale
		var rect := Rect2(
			Vector2((size.x - draw_size.x) * 0.48, size.y - draw_size.y - size.y * 0.055),
			draw_size
		)
		draw_texture_rect_region(tex, rect, Rect2(Vector2.ZERO, tex_size))
		return true

	func _draw_dish_icon_spread() -> bool:
		var tex := load(DISH_ICONS) as Texture2D
		if tex == null:
			return false
		var tex_size := Vector2(float(tex.get_width()), float(tex.get_height()))
		if tex_size.x <= 0.0 or tex_size.y <= 0.0 or size.x <= 0.0 or size.y <= 0.0:
			return false
		var cell_size := Vector2(tex_size.x / 3.0, tex_size.y / 2.0)
		var icon_index := _dish_icon_index()
		var src := Rect2(Vector2(float(icon_index % 3) * cell_size.x, float(int(icon_index / 3)) * cell_size.y), cell_size)
		var scale := minf(size.x * 0.88 / cell_size.x, size.y * 0.62 / cell_size.y)
		var draw_size := cell_size * scale
		var rect := Rect2(
			Vector2((size.x - draw_size.x) * 0.50, size.y - draw_size.y - size.y * 0.04),
			draw_size
		)
		draw_texture_rect_region(tex, rect, src)
		if icon_index == 0:
			_draw_grilled_fish_overlay(rect)
		return true

	func _dish_icon_index() -> int:
		match recipe_id:
			"sashimi":
				return 1
			"simmered":
				return 2
			"soup":
				return 3
			"fry":
				return 4
			_:
				return 0

	func _draw_grilled_fish_overlay(rect: Rect2) -> void:
		var body_center := rect.position + Vector2(rect.size.x * 0.46, rect.size.y * 0.42)
		var body_rx := rect.size.x * 0.28
		var body_ry := rect.size.y * 0.105
		draw_ellipse(body_center + Vector2(0.0, 1.0), body_rx, body_ry, Color("#8f4b20"))
		draw_ellipse(body_center + Vector2(-4.0, -1.0), body_rx * 0.82, body_ry * 0.62, Color("#c16a2b", 0.74))
		for i in range(4):
			var x := body_center.x - body_rx * 0.40 + float(i) * body_rx * 0.25
			draw_line(
				Vector2(x, body_center.y - body_ry * 0.86),
				Vector2(x + body_rx * 0.12, body_center.y + body_ry * 0.80),
				Color("#3b1c11", 0.78),
				2.0
			)
		draw_circle(body_center + Vector2(-body_rx * 0.66, -body_ry * 0.12), 3.0, Color("#17110c"))
		draw_circle(body_center + Vector2(-body_rx * 0.66, -body_ry * 0.12), 1.0, Color("#fff4d4"))
		var tail_root := body_center + Vector2(body_rx * 0.95, 0.0)
		draw_polygon(
			PackedVector2Array(
				[
					tail_root,
					tail_root + Vector2(rect.size.x * 0.18, -rect.size.y * 0.18),
					tail_root + Vector2(rect.size.x * 0.12, 0.0),
					tail_root + Vector2(rect.size.x * 0.18, rect.size.y * 0.18),
				]
			),
			PackedColorArray([Color("#d7a13a"), Color("#d7a13a"), Color("#c38325"), Color("#c38325")])
		)

	func _draw_feature_dish_on_table() -> void:
		if dish_texture != null:
			var tex_size := Vector2(float(dish_texture.get_width()), float(dish_texture.get_height()))
			if tex_size.x > 0.0 and tex_size.y > 0.0:
				var src := Rect2(
					Vector2(tex_size.x * 0.06, tex_size.y * 0.28),
					Vector2(tex_size.x * 0.88, tex_size.y * 0.50)
				)
				var scale := minf(size.x * 0.90 / src.size.x, size.y * 0.46 / src.size.y)
				var draw_size := src.size * scale
				var rect := Rect2(
					Vector2((size.x - draw_size.x) * 0.56, size.y - draw_size.y - size.y * 0.14),
					draw_size
				)
				draw_texture_rect_region(dish_texture, rect, src)

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

	func _draw_side_dishes() -> void:
		var bowl_center := Vector2(size.x * 0.78, size.y * 0.72)
		draw_ellipse(bowl_center + Vector2(0.0, 12.0), 30.0, 8.0, Color(0.0, 0.0, 0.0, 0.24))
		draw_arc(bowl_center, 25.0, 0.0, PI, 24, Color("#f5e6c5"), 6.0)
		draw_arc(bowl_center + Vector2(0.0, -3.0), 21.0, 0.0, PI, 24, Color("#8a3f18"), 6.0)
		for i in range(3):
			var steam_x := bowl_center.x - 14.0 + float(i) * 12.0
			draw_arc(
				Vector2(steam_x, bowl_center.y - 24.0),
				10.0,
				-1.55,
				0.9,
				12,
				Color(1.0, 0.88, 0.58, 0.34),
				2.0
			)
		var cup_rect := Rect2(Vector2(size.x * 0.02, size.y * 0.61), Vector2(26.0, 42.0))
		draw_rect(cup_rect, Color("#5d331a"))
		draw_rect(Rect2(cup_rect.position, Vector2(cup_rect.size.x, 7.0)), Color("#8d5527"))

	func _draw_meal_sparkles() -> void:
		var gold := Color("#ffe081")
		for i in range(5):
			var p := Vector2(
				size.x * (0.10 + float((i * 19) % 72) / 100.0),
				size.y * (0.12 + float((i * 29) % 62) / 100.0)
			)
			gold.a = 0.54 if i % 2 == 0 else 0.34
			draw_line(p + Vector2(-4.0, 0.0), p + Vector2(4.0, 0.0), gold, 2.0)
			draw_line(p + Vector2(0.0, -4.0), p + Vector2(0.0, 4.0), gold, 2.0)


class MealSceneTableBridgeVisual:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x <= 0.0 or size.y <= 0.0:
			return
		var table_y := size.y * 0.57
		var table_rect := Rect2(Vector2(0.0, table_y), Vector2(size.x, size.y - table_y))
		draw_rect(table_rect, Color("#3a1a09", 0.34))
		draw_rect(Rect2(Vector2(0.0, table_y), Vector2(size.x, size.y * 0.08)), Color("#d68633", 0.16))
		draw_line(Vector2(0.0, table_y + 4.0), Vector2(size.x, table_y + 4.0), Color("#ffd18a", 0.38), 2.0)
		for i in range(4):
			var y := table_y + 24.0 + float(i) * 22.0
			draw_line(
				Vector2(14.0, y),
				Vector2(size.x - 14.0, y + sin(float(i) * 1.7) * 4.0),
				Color("#8f4b20", 0.20),
				2.0
			)
		_draw_window_to_table_light()
		var runner := PackedVector2Array(
			[
				Vector2(size.x * 0.18, size.y * 0.68),
				Vector2(size.x * 0.98, size.y * 0.63),
				Vector2(size.x * 0.94, size.y * 0.93),
				Vector2(size.x * 0.05, size.y * 0.96),
			]
		)
		draw_polygon(
			runner,
			PackedColorArray(
				[
					Color("#f0c07a", 0.13),
					Color("#f0c07a", 0.10),
					Color("#5c2f14", 0.13),
					Color("#5c2f14", 0.16),
				]
			)
		)
		draw_ellipse(Vector2(size.x * 0.23, size.y * 0.83), size.x * 0.18, 13.0, Color(0.0, 0.0, 0.0, 0.24))
		draw_ellipse(Vector2(size.x * 0.66, size.y * 0.78), size.x * 0.28, 18.0, Color(0.0, 0.0, 0.0, 0.22))
		draw_circle(Vector2(size.x * 0.48, size.y * 0.55), size.x * 0.34, Color("#ffd18a", 0.06))
		draw_ellipse(Vector2(size.x * 0.45, size.y * 0.77), size.x * 0.42, 30.0, Color("#ffb83d", 0.055))
		_draw_table_unity_glow()
		draw_line(
			Vector2(size.x * 0.05, size.y * 0.88),
			Vector2(size.x * 0.93, size.y * 0.82),
			Color("#ffd18a", 0.24),
			3.0
		)
		draw_line(
			Vector2(size.x * 0.04, size.y * 0.91),
			Vector2(size.x * 0.95, size.y * 0.86),
			Color("#2a1208", 0.24),
			5.0
		)
		_draw_shared_steam()
		for i in range(5):
			var p := Vector2(
				size.x * (0.26 + float((i * 17) % 58) / 100.0),
				size.y * (0.40 + float((i * 11) % 34) / 100.0)
			)
			var gold := Color("#ffe081", 0.40 if i % 2 == 0 else 0.26)
			draw_line(p + Vector2(-3.0, 0.0), p + Vector2(3.0, 0.0), gold, 1.5)
			draw_line(p + Vector2(0.0, -3.0), p + Vector2(0.0, 3.0), gold, 1.5)

	func _draw_window_to_table_light() -> void:
		var beam := PackedVector2Array(
			[
				Vector2(size.x * 0.37, size.y * 0.18),
				Vector2(size.x * 0.92, size.y * 0.25),
				Vector2(size.x * 0.86, size.y * 0.72),
				Vector2(size.x * 0.24, size.y * 0.92),
			]
		)
		draw_polygon(
			beam,
			PackedColorArray(
				[
					Color("#fff1c7", 0.12),
					Color("#fff1c7", 0.05),
					Color("#ffb83d", 0.08),
					Color("#ffb83d", 0.13),
				]
			)
		)
		draw_circle(Vector2(size.x * 0.42, size.y * 0.34), size.x * 0.30, Color("#ffe081", 0.040))
		for i in range(3):
			var x := size.x * (0.43 + float(i) * 0.12)
			draw_line(
				Vector2(x, size.y * 0.26),
				Vector2(x - size.x * 0.16, size.y * 0.86),
				Color("#fff1c7", 0.10 - float(i) * 0.018),
				2.0
			)

	func _draw_table_unity_glow() -> void:
		var gold := Color("#ffd18a", 0.18)
		draw_line(
			Vector2(size.x * 0.18, size.y * 0.72),
			Vector2(size.x * 0.78, size.y * 0.69),
			gold,
			5.0
		)
		draw_line(
			Vector2(size.x * 0.27, size.y * 0.62),
			Vector2(size.x * 0.72, size.y * 0.70),
			Color("#fff1c7", 0.12),
			3.0
		)
		draw_ellipse(Vector2(size.x * 0.54, size.y * 0.73), size.x * 0.35, 22.0, Color("#ffe081", 0.065))

	func _draw_shared_steam() -> void:
		var steam := Color("#fff1c7", 0.20)
		for i in range(5):
			var x := size.x * (0.42 + float(i) * 0.075)
			var y := size.y * (0.36 + float(i % 2) * 0.075)
			var radius := 18.0 + float(i % 3) * 5.0
			steam.a = 0.22 - float(i) * 0.025
			draw_arc(Vector2(x, y), radius, -1.75, 0.75, 18, steam, 2.0)


class MealSceneForegroundGlowVisual:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x <= 0.0 or size.y <= 0.0:
			return
		_draw_lantern_wash()
		_draw_actor_dish_rim_light()
		_draw_front_steam()
		_draw_meal_glints()

	func _draw_lantern_wash() -> void:
		var lantern_center := Vector2(size.x * 0.13, size.y * 0.20)
		draw_circle(lantern_center, size.x * 0.24, Color("#ffb83d", 0.060))
		draw_circle(lantern_center + Vector2(size.x * 0.10, size.y * 0.06), size.x * 0.18, Color("#fff1c7", 0.040))
		for i in range(3):
			var from := lantern_center + Vector2(float(i) * 18.0, 18.0)
			var to := Vector2(size.x * (0.38 + float(i) * 0.12), size.y * 0.78)
			draw_line(from, to, Color("#ffd18a", 0.060 - float(i) * 0.010), 8.0 - float(i) * 1.6)

	func _draw_actor_dish_rim_light() -> void:
		var warm := Color("#ffd18a", 0.20)
		draw_line(
			Vector2(size.x * 0.16, size.y * 0.70),
			Vector2(size.x * 0.80, size.y * 0.66),
			warm,
			4.0
		)
		draw_line(
			Vector2(size.x * 0.22, size.y * 0.78),
			Vector2(size.x * 0.86, size.y * 0.75),
			Color("#fff1c7", 0.12),
			2.0
		)
		draw_ellipse(Vector2(size.x * 0.24, size.y * 0.51), size.x * 0.16, 24.0, Color("#ffb83d", 0.055))
		draw_ellipse(Vector2(size.x * 0.62, size.y * 0.62), size.x * 0.23, 18.0, Color("#ffe081", 0.052))

	func _draw_front_steam() -> void:
		var steam := Color("#fff1c7", 0.16)
		for i in range(4):
			var x := size.x * (0.48 + float(i) * 0.08)
			var y := size.y * (0.42 - float(i % 2) * 0.04)
			var radius := 20.0 + float(i) * 4.0
			steam.a = 0.18 - float(i) * 0.025
			draw_arc(Vector2(x, y), radius, -1.62, 0.92, 18, steam, 2.0)
		draw_arc(Vector2(size.x * 0.31, size.y * 0.48), 19.0, -1.8, 0.7, 16, Color("#fff1c7", 0.12), 1.8)

	func _draw_meal_glints() -> void:
		for i in range(7):
			var p := Vector2(
				size.x * (0.20 + float((i * 23) % 65) / 100.0),
				size.y * (0.20 + float((i * 17) % 58) / 100.0)
			)
			var color := Color("#ffe081", 0.36 if i % 2 == 0 else 0.22)
			var arm := 2.5 + float(i % 3)
			draw_line(p + Vector2(-arm, 0.0), p + Vector2(arm, 0.0), color, 1.4)
			draw_line(p + Vector2(0.0, -arm), p + Vector2(0.0, arm), color, 1.4)


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


class MealResultRewardCueVisual:
	extends Control

	func _draw() -> void:
		var gold := Color("#ffe081")
		var amber := Color("#d7a456")
		var glow := Color("#fff1c7")
		var y := size.y * 0.48
		var row_left := size.x * 0.03
		var row_right := size.x * 0.97
		glow.a = 0.11
		draw_line(Vector2(row_left, y + 1.0), Vector2(row_right, y + 1.0), glow, 6.0)
		amber.a = 0.34
		draw_line(Vector2(row_left + 8.0, y + 1.0), Vector2(row_right - 8.0, y + 1.0), amber, 1.4)
		for i in range(4):
			var card_x := lerpf(row_left + 66.0, row_right - 66.0, float(i) / 3.0)
			var card_glow := glow
			card_glow.a = 0.30
			draw_line(Vector2(card_x, y - 5.0), Vector2(card_x, y + 7.0), card_glow, 2.0)
			_draw_down_chevron(Vector2(card_x, y + 3.0), gold if i == 2 else amber)
		var left := size.x * 0.46
		var right := size.x * 0.96
		glow.a = 0.18
		draw_line(Vector2(left, y), Vector2(right, y), glow, 8.0)
		gold.a = 0.70
		draw_line(Vector2(left + 10.0, y), Vector2(right - 14.0, y), gold, 2.0)
		for i in range(4):
			var x := lerpf(left + 70.0, right - 82.0, float(i) / 3.0)
			_draw_down_chevron(Vector2(x, y + 2.0), amber if i % 2 == 0 else gold)
		for i in range(8):
			var p := Vector2(left + 28.0 + float(i) * ((right - left - 56.0) / 7.0), y - 5.0 + float(i % 2) * 9.0)
			var spark := glow
			spark.a = 0.58 if i % 2 == 0 else 0.34
			draw_line(p + Vector2(-3.0, 0.0), p + Vector2(3.0, 0.0), spark, 1.5)
			draw_line(p + Vector2(0.0, -3.0), p + Vector2(0.0, 3.0), spark, 1.5)

	func _draw_down_chevron(center: Vector2, color: Color) -> void:
		color.a = 0.82
		var points := PackedVector2Array(
			[
				center + Vector2(-12.0, -4.0),
				center + Vector2(0.0, 8.0),
				center + Vector2(12.0, -4.0),
				center + Vector2(7.0, -4.0),
				center,
				center + Vector2(-7.0, -4.0),
			]
		)
		var colors := PackedColorArray()
		for _i in range(points.size()):
			colors.append(color)
		draw_polygon(points, colors)


class MealResultBannerSparkVisual:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x <= 0.0 or size.y <= 0.0:
			return
		var gold := Color("#ffe081")
		var glow := Color("#fff1c7")
		var ember := Color("#d7a456")
		_draw_corner_burst(Vector2(size.x * 0.15, size.y * 0.30), gold, 0.88)
		_draw_corner_burst(Vector2(size.x * 0.72, size.y * 0.25), glow, 0.58)
		_draw_corner_burst(Vector2(size.x * 0.88, size.y * 0.66), ember, 0.54)
		var arc_radius := minf(size.x, size.y) * 0.48
		glow.a = 0.20
		draw_arc(Vector2(size.x * 0.46, size.y * 0.56), arc_radius, -2.72, -0.35, 28, glow, 4.0)
		gold.a = 0.34
		draw_arc(Vector2(size.x * 0.51, size.y * 0.56), arc_radius * 0.78, -2.55, -0.50, 24, gold, 2.0)
		for i in range(10):
			var p := Vector2(
				size.x * (0.20 + float((i * 13) % 64) / 100.0),
				size.y * (0.20 + float((i * 19) % 56) / 100.0)
			)
			var sparkle := gold if i % 2 == 0 else glow
			sparkle.a = 0.34 if i % 3 == 0 else 0.48
			var arm := 2.5 + float(i % 3)
			draw_line(p + Vector2(-arm, 0.0), p + Vector2(arm, 0.0), sparkle, 1.5)
			draw_line(p + Vector2(0.0, -arm), p + Vector2(0.0, arm), sparkle, 1.5)

	func _draw_corner_burst(center: Vector2, color: Color, alpha: float) -> void:
		var burst := color
		burst.a = alpha
		for i in range(8):
			var angle := TAU * float(i) / 8.0
			var from := center + Vector2(cos(angle), sin(angle)) * 4.0
			var to := center + Vector2(cos(angle), sin(angle)) * (12.0 if i % 2 == 0 else 8.0)
			draw_line(from, to, burst, 2.0)
		burst.a = minf(1.0, alpha + 0.10)
		draw_circle(center, 2.8, burst)


class MealResultSplitTitleVisual:
	extends Control

	var dish_name := "料理"

	func configure(next_dish_name: String) -> void:
		dish_name = next_dish_name
		queue_redraw()

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x <= 0.0 or size.y <= 0.0:
			return
		var font := get_theme_default_font()
		if font == null:
			return
		var text_rect := Rect2(Vector2(size.x * 0.20, size.y * 0.10), Vector2(size.x * 0.66, size.y * 0.82))
		var top := "%sを" % dish_name
		var top_size := 38
		if top.length() >= 10:
			top_size = 34
		if top.length() >= 13:
			top_size = 31
		var bottom_size := 48
		var top_baseline := Vector2(text_rect.position.x, size.y * 0.42)
		var bottom_baseline := Vector2(text_rect.position.x, size.y * 0.82)
		var impact_center := Vector2(text_rect.position.x + text_rect.size.x * 0.50, bottom_baseline.y - float(bottom_size) * 0.34)
		draw_ellipse(impact_center, text_rect.size.x * 0.24, size.y * 0.20, Color("#fff1c7", 0.22))
		draw_line(
			Vector2(text_rect.position.x + text_rect.size.x * 0.26, bottom_baseline.y + 4.0),
			Vector2(text_rect.position.x + text_rect.size.x * 0.74, bottom_baseline.y + 4.0),
			Color("#9b2f17", 0.34),
			5.0
		)
		draw_line(
			Vector2(text_rect.position.x + text_rect.size.x * 0.30, bottom_baseline.y + 8.0),
			Vector2(text_rect.position.x + text_rect.size.x * 0.70, bottom_baseline.y + 8.0),
			Color("#ffe081", 0.28),
			2.0
		)
		draw_string_outline(
			font,
			top_baseline,
			top,
			HORIZONTAL_ALIGNMENT_CENTER,
			text_rect.size.x,
			top_size,
			5,
			Color("#fff3d6", 0.82)
		)
		draw_string(font, top_baseline, top, HORIZONTAL_ALIGNMENT_CENTER, text_rect.size.x, top_size, Color("#2a160c"))
		draw_string_outline(
			font,
			bottom_baseline,
			"食べた！",
			HORIZONTAL_ALIGNMENT_CENTER,
			text_rect.size.x,
			bottom_size,
			6,
			Color("#fff3d6", 0.88)
		)
		draw_string(font, bottom_baseline, "食べた！", HORIZONTAL_ALIGNMENT_CENTER, text_rect.size.x, bottom_size, Color("#9b2f17"))


class MealResultModeTabVisual:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x <= 0.0 or size.y <= 0.0:
			return
		var font := get_theme_default_font()
		if font == null:
			return
		var plate := Rect2(Vector2(94.0, 6.0), Vector2(76.0, 28.0))
		draw_rect(plate, Color("#082642", 0.92))
		draw_rect(Rect2(plate.position + Vector2(2.0, 2.0), plate.size - Vector2(4.0, 4.0)), Color("#103a5e", 0.46))
		draw_line(plate.position + Vector2(0.0, 1.0), plate.position + Vector2(plate.size.x, 1.0), Color("#ffe081", 0.44), 1.5)
		draw_line(plate.position + Vector2(0.0, plate.size.y - 1.0), plate.position + plate.size - Vector2(0.0, 1.0), Color("#07121e", 0.65), 1.5)
		draw_line(Vector2(88.0, 8.0), Vector2(88.0, 31.0), Color("#ffe081", 0.50), 1.5)
		var baseline := Vector2(99.0, 27.0)
		draw_string_outline(
			font,
			baseline,
			"食べる",
			HORIZONTAL_ALIGNMENT_CENTER,
			66.0,
			19,
			3,
			Color(0.02, 0.04, 0.07, 0.78)
		)
		draw_string(font, baseline, "食べる", HORIZONTAL_ALIGNMENT_CENTER, 66.0, 19, Color("#fff1c7"))


class MealDishCardBridgeVisual:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x <= 0.0 or size.y <= 0.0:
			return
		var gold := Color("#ffe081")
		var warm := Color("#ffb83d")
		var cyan := Color("#6bf1ff")
		var dish_center := Vector2(size.x * 0.37, size.y * 0.55)
		var text_center := Vector2(size.x * 0.79, size.y * 0.50)
		_draw_dish_showcase_frame()
		draw_ellipse(dish_center, size.x * 0.22, size.y * 0.36, Color("#ffd36a", 0.050))
		draw_ellipse(text_center, size.x * 0.15, size.y * 0.30, Color("#6bf1ff", 0.026))
		draw_line(Vector2(size.x * 0.64, 12.0), Vector2(size.x * 0.64, size.y - 12.0), Color("#d7a456", 0.12), 1.5)
		_draw_dish_name_plate()
		draw_line(
			Vector2(size.x * 0.46, size.y * 0.45),
			Vector2(size.x * 0.84, size.y * 0.34),
			Color("#ffb83d", 0.10),
			7.0
		)
		draw_line(
			Vector2(size.x * 0.47, size.y * 0.48),
			Vector2(size.x * 0.82, size.y * 0.39),
			Color("#ffe081", 0.26),
			2.0
		)
		for i in range(3):
			var y := size.y * (0.34 + float(i) * 0.16)
			var alpha := 0.26 - float(i) * 0.05
			var from := Vector2(size.x * 0.42, y + float(i) * 4.0)
			var mid := Vector2(size.x * 0.56, y + 2.0)
			var to := Vector2(size.x * 0.69, y - float(i) * 5.0)
			var line_color := gold
			line_color.a = alpha
			draw_line(from, mid, line_color, 3.0)
			draw_line(mid, to, line_color, 2.0)
		for i in range(5):
			var p := Vector2(
				size.x * (0.48 + float((i * 17) % 36) / 100.0),
				size.y * (0.22 + float((i * 19) % 58) / 100.0)
			)
			var sparkle := warm if i % 2 == 0 else cyan
			sparkle.a = 0.32 if i % 2 == 0 else 0.22
			draw_line(p + Vector2(-3.0, 0.0), p + Vector2(3.0, 0.0), sparkle, 1.4)
			draw_line(p + Vector2(0.0, -3.0), p + Vector2(0.0, 3.0), sparkle, 1.4)
		_draw_card_glint(Vector2(size.x * 0.86, size.y * 0.18), gold)

	func _draw_dish_showcase_frame() -> void:
		var frame := Rect2(
			Vector2(size.x * 0.030, size.y * 0.080),
			Vector2(size.x * 0.610, size.y * 0.830)
		)
		draw_rect(Rect2(frame.position + Vector2(0.0, 5.0), frame.size), Color("#020a12", 0.28))
		draw_rect(frame, Color("#07121e", 0.16))
		draw_line(frame.position + Vector2(12.0, 5.0), frame.position + Vector2(frame.size.x - 12.0, 5.0), Color("#ffe081", 0.24), 2.0)
		draw_line(
			frame.position + Vector2(12.0, frame.size.y - 6.0),
			frame.position + Vector2(frame.size.x - 12.0, frame.size.y - 6.0),
			Color("#07121e", 0.50),
			3.0
		)
		draw_ellipse(frame.get_center() + Vector2(4.0, frame.size.y * 0.20), frame.size.x * 0.38, frame.size.y * 0.16, Color("#ffb83d", 0.08))
		for corner in [
			frame.position + Vector2(10.0, 10.0),
			frame.position + Vector2(frame.size.x - 10.0, 10.0),
			frame.position + Vector2(10.0, frame.size.y - 10.0),
			frame.position + frame.size - Vector2(10.0, 10.0),
		]:
			var x_dir := -1.0 if corner.x > frame.get_center().x else 1.0
			var y_dir := -1.0 if corner.y > frame.get_center().y else 1.0
			var gold := Color("#ffe081", 0.42)
			draw_line(corner, corner + Vector2(18.0 * x_dir, 0.0), gold, 1.5)
			draw_line(corner, corner + Vector2(0.0, 14.0 * y_dir), gold, 1.5)

	func _draw_dish_name_plate() -> void:
		var plate := Rect2(
			Vector2(size.x * 0.665, size.y * 0.31),
			Vector2(size.x * 0.285, size.y * 0.44)
		)
		var shadow := Color("#020a12", 0.42)
		draw_rect(Rect2(plate.position + Vector2(0.0, 5.0), plate.size), shadow)
		draw_rect(plate, Color("#071726", 0.72))
		draw_rect(Rect2(plate.position + Vector2(3.0, 3.0), plate.size - Vector2(6.0, 6.0)), Color("#12334f", 0.34))
		draw_ellipse(plate.get_center() + Vector2(0.0, -2.0), plate.size.x * 0.44, plate.size.y * 0.25, Color("#fff1c7", 0.06))
		draw_line(plate.position + Vector2(8.0, 3.0), plate.position + Vector2(plate.size.x - 8.0, 3.0), Color("#ffe081", 0.42), 2.0)
		draw_line(
			plate.position + Vector2(9.0, plate.size.y - 4.0),
			plate.position + Vector2(plate.size.x - 9.0, plate.size.y - 4.0),
			Color("#07121e", 0.60),
			2.0
		)
		var accent := Color("#ffb83d", 0.20)
		draw_line(
			Vector2(plate.position.x - size.x * 0.06, plate.position.y + plate.size.y * 0.54),
			Vector2(plate.position.x + plate.size.x * 0.42, plate.position.y + plate.size.y * 0.32),
			accent,
			6.0
		)
		var gold := Color("#ffe081", 0.54)
		var corner_offsets: Array[float] = [0.0, plate.size.x - 16.0]
		for offset: float in corner_offsets:
			var x: float = plate.position.x + offset
			draw_line(Vector2(x, plate.position.y + 7.0), Vector2(x + 16.0, plate.position.y + 7.0), gold, 1.5)
			draw_line(Vector2(x, plate.end.y - 7.0), Vector2(x + 16.0, plate.end.y - 7.0), gold, 1.5)

	func _draw_card_glint(center: Vector2, color: Color) -> void:
		var glow := color
		glow.a = 0.72
		draw_line(center + Vector2(-18.0, 0.0), center + Vector2(18.0, 0.0), glow, 2.2)
		draw_line(center + Vector2(0.0, -18.0), center + Vector2(0.0, 18.0), glow, 2.2)
		glow.a = 0.38
		draw_line(center + Vector2(-10.0, -10.0), center + Vector2(10.0, 10.0), glow, 1.5)
		draw_line(center + Vector2(-10.0, 10.0), center + Vector2(10.0, -10.0), glow, 1.5)


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


class RewardTotalPeakGlowVisual:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x <= 0.0 or size.y <= 0.0:
			return
		var center := Vector2(size.x * 0.50, size.y * 0.66)
		var gold := Color("#ffe081")
		var hot := Color("#ffb83d")
		_draw_card_rays(center, hot)
		for i in range(3):
			var alpha := 0.12 - float(i) * 0.025
			_draw_card_glow_ellipse(
				center + Vector2(0.0, 8.0),
				size.x * (0.30 + float(i) * 0.07),
				20.0 + float(i) * 8.0,
				Color("#ffd36a", alpha)
			)
		for i in range(9):
			var p := Vector2(
				size.x * (0.18 + float((i * 23) % 64) / 100.0),
				size.y * (0.28 + float((i * 17) % 54) / 100.0)
			)
			var sparkle := gold
			sparkle.a = 0.48 if i % 3 == 0 else 0.30
			var arm := 3.0 + float(i % 2)
			draw_line(p + Vector2(-arm, 0.0), p + Vector2(arm, 0.0), sparkle, 1.4)
			draw_line(p + Vector2(0.0, -arm), p + Vector2(0.0, arm), sparkle, 1.4)

	func _draw_card_rays(center: Vector2, color: Color) -> void:
		for i in range(24):
			var a := TAU * float(i) / 24.0
			var inner := center + Vector2(cos(a), sin(a)) * 20.0
			var outer := center + Vector2(cos(a), sin(a)) * (92.0 if i % 3 == 0 else 66.0)
			var ray := color
			ray.a = 0.18 if i % 3 == 0 else 0.10
			draw_line(inner, outer, ray, 3.2 if i % 3 == 0 else 1.6)

	func _draw_card_glow_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
		draw_ellipse(center, rx, ry, color)


class RewardValuePlateVisual:
	extends Control

	var mode := "exp"
	var accent := Color("#6bf1ff")

	func configure(next_mode: String, next_accent: Color) -> void:
		mode = next_mode
		accent = next_accent
		queue_redraw()

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x <= 0.0 or size.y <= 0.0:
			return
		var rect := Rect2(Vector2(8.0, 5.0), Vector2(size.x - 16.0, size.y - 10.0))
		if mode == "buff":
			_draw_buff_plate(rect)
			return
		var glow := accent
		glow.a = 0.22 if mode == "total" else 0.14
		var rim := accent
		rim.a = 0.55 if mode == "total" else 0.36
		draw_rect(rect, Color("#03111d", 0.72))
		draw_rect(Rect2(rect.position + Vector2(3.0, 3.0), rect.size - Vector2(6.0, 6.0)), glow)
		draw_line(rect.position, rect.position + Vector2(rect.size.x, 0.0), rim, 2.0)
		draw_line(
			rect.position + Vector2(0.0, rect.size.y),
			rect.position + rect.size,
			Color("#07121e", 0.70),
			2.0
		)
		if mode == "total":
			var center := rect.get_center()
			for i in range(10):
				var a := TAU * float(i) / 10.0
				var from := center + Vector2(cos(a), sin(a)) * 14.0
				var to := center + Vector2(cos(a), sin(a)) * 82.0
				var ray := Color("#ffb83d", 0.13)
				draw_line(from, to, ray, 2.0)

	func _draw_buff_plate(rect: Rect2) -> void:
		var green := accent
		var gold := Color("#ffe081")
		var cyan := Color("#6bf1ff")
		draw_rect(rect, Color("#03111d", 0.74))
		draw_rect(Rect2(rect.position + Vector2(3.0, 3.0), rect.size - Vector2(6.0, 6.0)), Color("#0d2c26", 0.70))
		green.a = 0.52
		draw_line(rect.position + Vector2(2.0, 0.0), rect.position + Vector2(rect.size.x - 2.0, 0.0), green, 2.4)
		draw_line(
			rect.position + Vector2(2.0, rect.size.y),
			rect.position + Vector2(rect.size.x - 2.0, rect.size.y),
			Color("#07121e", 0.78),
			2.0
		)
		var medal_center := rect.position + Vector2(37.0, rect.size.y * 0.50)
		draw_circle(medal_center, 27.0, Color("#07121e", 0.84))
		draw_circle(medal_center, 23.0, Color("#173b28", 0.86))
		gold.a = 0.32
		draw_arc(medal_center, 24.0, 0.0, TAU, 36, gold, 2.0)
		green.a = 0.18
		draw_circle(medal_center, 17.0, green)
		var lane := Rect2(rect.position + Vector2(74.0, 10.0), Vector2(maxf(16.0, rect.size.x - 86.0), rect.size.y - 20.0))
		draw_rect(lane, Color("#09201f", 0.58))
		cyan.a = 0.16
		draw_line(lane.position, lane.position + Vector2(lane.size.x, lane.size.y * 0.38), cyan, 2.0)
		draw_line(lane.position + Vector2(0.0, lane.size.y), lane.position + Vector2(lane.size.x, lane.size.y * 0.66), Color("#8ee65a", 0.14), 2.0)
		for i in range(4):
			var p := lane.position + Vector2(lane.size.x * (0.18 + float(i) * 0.20), lane.size.y * (0.28 + float(i % 2) * 0.36))
			var spark := gold if i % 2 == 0 else green
			spark.a = 0.48
			draw_line(p + Vector2(-3.2, 0.0), p + Vector2(3.2, 0.0), spark, 1.5)
			draw_line(p + Vector2(0.0, -3.2), p + Vector2(0.0, 3.2), spark, 1.5)


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
