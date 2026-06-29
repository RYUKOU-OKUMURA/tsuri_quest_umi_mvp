class_name ScreenBase
extends Control

signal navigate_requested(screen_id: String, payload: Dictionary)

var route_payload: Dictionary = {}

static var _particle_tex: Texture2D


func configure(payload: Dictionary) -> void:
	route_payload = payload.duplicate(true)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_screen()


func _build_screen() -> void:
	pass


func navigate(screen_id: String, payload: Dictionary = {}) -> void:
	navigate_requested.emit(screen_id, payload)


func add_background(color: Color = Color("#091a2d")) -> ColorRect:
	var background := ColorRect.new()
	background.color = color
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	move_child(background, 0)
	return background


# 垂直グラデーション背景。空→海など、単色ColorRectより奥行きが出る。
func add_gradient_background(top_color: Color, bottom_color: Color) -> TextureRect:
	var gradient := Gradient.new()
	gradient.set_color(0, top_color)
	gradient.set_color(1, bottom_color)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(0.0, 1.0)
	texture.width = 64
	texture.height = 64
	var background := TextureRect.new()
	background.texture = texture
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	move_child(background, 0)
	return background


# 明るい海のグラデーション（シェル画面用の簡易ヘルパ）。
func add_sea_background() -> TextureRect:
	return add_gradient_background(Palette.SKY_TOP, Palette.SEA_DEEP)


# 環境のきらめき粒子（CPUParticles2D：macOS gl_compat で安全）。
func add_sparkles(count: int = 18, area: Rect2 = Rect2()) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = count
	p.lifetime = 3.0
	p.texture = _get_particle_tex()
	p.local_coords = true
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	if area.size.length() <= 0.0:
		area = Rect2(Vector2.ZERO, Vector2(1280.0, 720.0))
	p.emission_rect_extents = area.size * 0.5
	p.position = area.get_center()
	p.gravity = Vector2.ZERO
	p.direction = Vector2(0.0, -1.0)
	p.spread = 25.0
	p.initial_velocity_min = 4.0
	p.initial_velocity_max = 12.0
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.6
	p.color = Palette.FOAM
	p.modulate.a = 0.7
	return p


func make_root_margin(margin: int = 18) -> MarginContainer:
	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", margin)
	root.add_theme_constant_override("margin_top", margin)
	root.add_theme_constant_override("margin_right", margin)
	root.add_theme_constant_override("margin_bottom", margin)
	add_child(root)
	return root


func make_label(
	text: String,
	font_size: int = 18,
	color: Color = Palette.TEXT_DARK,
	outline: int = 0,
	outline_color: Color = Palette.TEXT_OUTLINE_DARK
) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if outline > 0:
		label.add_theme_color_override("font_outline_color", outline_color)
		label.add_theme_constant_override("outline_size", outline)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func make_body_label(
	text: String,
	font_size: int = 18,
	color: Color = Palette.TEXT_DARK,
	outline: int = 0,
	outline_color: Color = Palette.TEXT_OUTLINE_DARK
) -> Label:
	var label := make_label(text, font_size, color, outline, outline_color)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.clip_text = true
	return label


# 落とし影付きラベル（明背景でタイトルを目立たせる）。
func make_shadow_label(
	text: String,
	font_size: int = 18,
	color: Color = Palette.TEXT_DARK,
	outline: int = 0,
	outline_color: Color = Palette.TEXT_OUTLINE_DARK,
	shadow_color: Color = Palette.SHADOW
) -> Label:
	var effective_outline := outline
	if font_size < 16:
		effective_outline = mini(outline, 1)
	elif font_size < 20:
		effective_outline = mini(outline, 2)
	var label := make_label(text, font_size, color, effective_outline, outline_color)
	label.add_theme_color_override("font_shadow_color", shadow_color)
	var shadow_offset := 1 if font_size < 18 else 2
	var shadow_outline := 1 if font_size < 18 else 2
	label.add_theme_constant_override("shadow_offset_x", shadow_offset)
	label.add_theme_constant_override("shadow_offset_y", shadow_offset)
	label.add_theme_constant_override("shadow_outline_size", shadow_outline)
	return label


# juice 付きボタン。gold=true で GoldButton（主役ボタン）。
func make_button(text: String, callback: Callable, minimum_width: float = 0.0, gold: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	if gold:
		button.theme_type_variation = "GoldButton"
	button.custom_minimum_size = Vector2(maxf(minimum_width, 0.0), 50.0)
	button.pressed.connect(callback)
	_wire_button_juice(button)
	return button


func _wire_button_juice(button: Button) -> void:
	var twn: Variant = null
	var enter := func() -> void:
		button.pivot_offset = button.size * 0.5
		twn = _kill_and_tween(twn, button, 1.06, Tween.EASE_OUT, Tween.TRANS_SINE)
	var exit := func() -> void:
		twn = _kill_and_tween(twn, button, 1.0, Tween.EASE_OUT, Tween.TRANS_SINE)
	var down := func() -> void:
		button.pivot_offset = button.size * 0.5
		twn = _kill_and_tween(twn, button, 0.94, Tween.EASE_OUT, Tween.TRANS_BACK)
	var up := func() -> void:
		twn = _kill_and_tween(twn, button, 1.0, Tween.EASE_OUT, Tween.TRANS_BACK)
	button.mouse_entered.connect(enter)
	button.mouse_exited.connect(exit)
	button.button_down.connect(down)
	button.button_up.connect(up)


func _kill_and_tween(prev: Variant, node: Control, target: float, ease: int, trans: int) -> Tween:
	if prev != null and prev.is_valid():
		prev.kill()
	var tw := create_tween()
	tw.set_ease(ease as Tween.EaseType)
	tw.set_trans(trans as Tween.TransitionType)
	tw.tween_property(node, "scale", Vector2(target, target), 0.12)
	return tw


func make_panel(dark: bool = false) -> PanelContainer:
	var panel := PanelContainer.new()
	if dark:
		panel.theme_type_variation = "DarkPanel"
	return panel


func make_header(title: String, subtitle: String = "") -> PanelContainer:
	var panel := make_panel(true)
	panel.custom_minimum_size = Vector2(0.0, 68.0)
	panel.clip_contents = true
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	var title_label := make_label(title, 28, Palette.TEXT_BONE, 3, Palette.TEXT_OUTLINE_DARK)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(title_label)
	if not subtitle.is_empty():
		var subtitle_label := make_label(subtitle, 16, Color("#d8e8f5"), 2, Palette.TEXT_OUTLINE_DARK)
		subtitle_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_child(subtitle_label)
	return panel


func format_play_time(total_seconds: float) -> String:
	var seconds := int(total_seconds)
	var hours := seconds / 3600
	var minutes := (seconds % 3600) / 60
	var remaining := seconds % 60
	return "%02d:%02d:%02d" % [hours, minutes, remaining]


static func _get_particle_tex() -> Texture2D:
	if _particle_tex != null:
		return _particle_tex
	var img := Image.create_empty(3, 3, false, Image.FORMAT_RGBA8)
	img.fill(Color(1.0, 1.0, 1.0, 1.0))
	_particle_tex = ImageTexture.create_from_image(img)
	return _particle_tex
