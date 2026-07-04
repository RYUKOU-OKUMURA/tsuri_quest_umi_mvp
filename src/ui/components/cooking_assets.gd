class_name CookingAssets
extends RefCounted

const COOKING_BG := "res://assets/showcase/cooking/cooking_room_bg.png"
const DISH_ICON_SHEET := "res://assets/showcase/cooking/dish_icon_sheet.png"
const DISH_FEATURE_AJI := "res://assets/showcase/cooking/dish_feature_aji_shioyaki.png"
const DISH_FEATURE_SASHIMI := "res://assets/showcase/cooking/dish_feature_sashimi.png"
const DISH_FEATURE_SIMMERED := "res://assets/showcase/cooking/dish_feature_simmered.png"
const DISH_FEATURE_SOUP := "res://assets/showcase/cooking/dish_feature_soup.png"
const DISH_FEATURE_FRY := "res://assets/showcase/cooking/dish_feature_fry.png"
const FLOW_ACTION_BUTTON_FRAME := "res://assets/showcase/cooking/flow_action_button_frame.png"
const REWARD_CARD_FRAME := "res://assets/showcase/cooking/reward_card_frame.png"
const PLAYER_STATUS_PORTRAIT := "res://assets/showcase/cooking/player_status_portrait_pixel.png"
const STATUS_COOLER_ART := "res://assets/showcase/cooking/status_cooler_art.png"
const STATUS_MONEY_ART := "res://assets/showcase/cooking/status_money_art.png"


static func panel_box(
	fill: Color,
	border: Color,
	inner: Color,
	border_width: int,
	content_x: float = 14.0,
	content_y: float = 10.0,
	shadow_alpha: float = 0.35,
	shadow_size: int = 6,
	shadow_offset_y: float = 3.0,
	panel_radius: int = 5
) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel",
		style_box(
			fill,
			border,
			inner,
			border_width,
			panel_radius,
			content_x,
			content_y,
			shadow_alpha,
			shadow_size,
			shadow_offset_y
		)
	)
	return panel


static func texture_panel_box(
	path: String,
	margin: int,
	fallback: StyleBox,
	content_x: float,
	content_y: float,
	expand_margin: float = 6.0
) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel", texture_style_box(path, margin, fallback, content_x, content_y, expand_margin)
	)
	return panel


static func style_box(
	fill: Color,
	border: Color,
	inner: Color,
	border_width: int,
	radius: int,
	content_x: float = 14.0,
	content_y: float = 10.0,
	shadow_alpha: float = 0.35,
	shadow_size: int = 6,
	shadow_offset_y: float = 3.0
) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border.lerp(inner, 0.18)
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = content_x
	sb.content_margin_top = content_y
	sb.content_margin_right = content_x
	sb.content_margin_bottom = content_y
	sb.shadow_color = Color(0.0, 0.0, 0.0, shadow_alpha)
	sb.shadow_size = shadow_size
	sb.shadow_offset = Vector2(0.0, shadow_offset_y)
	sb.anti_aliasing = false
	return sb


static func texture_style_box(
	path: String,
	margin: int,
	fallback: StyleBox,
	content_x: float,
	content_y: float,
	expand_margin: float = 6.0
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
	sb.expand_margin_left = expand_margin
	sb.expand_margin_top = expand_margin
	sb.expand_margin_right = expand_margin
	sb.expand_margin_bottom = expand_margin
	sb.content_margin_left = content_x
	sb.content_margin_top = content_y
	sb.content_margin_right = content_x
	sb.content_margin_bottom = content_y
	return sb


static func featured_dish_texture(recipe_id: String) -> Texture2D:
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
		_:
			return null


static func apply_flow_button_style(
	button: Button, content_x: float, expand_margin: float = 6.0
) -> void:
	var normal_fallback := style_box(Color("#102f51"), Palette.GOLD_DEEP, Palette.GOLD_BRIGHT, 4, 6)
	var hover_fallback := style_box(Color("#16436c"), Palette.GOLD_BRIGHT, Color("#fff0b2"), 4, 6)
	var pressed_fallback := style_box(Color("#081a2d"), Color("#a06d28"), Palette.GOLD_DEEP, 4, 6)
	var disabled_fallback := style_box(Color("#202a31"), Color("#71614a"), Color("#8c7b62"), 3, 6)
	button.add_theme_stylebox_override(
		"normal",
		texture_style_box(FLOW_ACTION_BUTTON_FRAME, 24, normal_fallback, content_x, 8.0, expand_margin)
	)
	button.add_theme_stylebox_override(
		"hover",
		texture_style_box(FLOW_ACTION_BUTTON_FRAME, 24, hover_fallback, content_x, 8.0, expand_margin)
	)
	button.add_theme_stylebox_override(
		"pressed",
		texture_style_box(FLOW_ACTION_BUTTON_FRAME, 24, pressed_fallback, content_x, 8.0, expand_margin)
	)
	button.add_theme_stylebox_override(
		"disabled",
		texture_style_box(FLOW_ACTION_BUTTON_FRAME, 24, disabled_fallback, content_x, 8.0, expand_margin)
	)
	button.add_theme_stylebox_override(
		"focus",
		texture_style_box(FLOW_ACTION_BUTTON_FRAME, 24, hover_fallback, content_x, 8.0, expand_margin)
	)
	button.add_theme_color_override("font_color", Palette.GOLD_BRIGHT)
	button.add_theme_color_override("font_hover_color", Color("#fff1ba"))
	button.add_theme_color_override("font_pressed_color", Color("#f0c06b"))
	button.add_theme_color_override("font_disabled_color", Color("#b6a68d"))


static func compact_style_box(
	fill: Color, border: Color, inner: Color, border_width: int, radius: int
) -> StyleBoxFlat:
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


static func compact_panel_box(fill: Color, border: Color, inner: Color, border_width: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", compact_style_box(fill, border, inner, border_width, 5))
	return panel


static func recipe_icon(recipe_id: String) -> Texture2D:
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


static func featured_dish_texture_or_icon(recipe_id: String) -> Texture2D:
	var tex := featured_dish_texture(recipe_id)
	if tex == null:
		return recipe_icon(recipe_id)
	return tex


static func card_from_label(label: Label) -> Control:
	if label == null:
		return null
	var node := label.get_parent()
	while node != null:
		if node is PanelContainer:
			return node as Control
		node = node.get_parent()
	return null
