class_name ScreenBase
extends Control

const ShowcaseAssetsScript = preload("res://src/ui/showcase_assets.gd")

signal navigate_requested(screen_id: String, payload: Dictionary)

var route_payload: Dictionary = {}
var _screen_bgm_player: AudioStreamPlayer
var _screen_bgm_path := ""
var _last_sfx_path := ""


func configure(payload: Dictionary) -> void:
	route_payload = payload.duplicate(true)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_screen()


func _exit_tree() -> void:
	stop_screen_bgm()


func _build_screen() -> void:
	pass


func navigate(screen_id: String, payload: Dictionary = {}) -> void:
	navigate_requested.emit(screen_id, payload)


func play_screen_bgm(path: String, volume_db: float = -10.0) -> void:
	if path.strip_edges().is_empty():
		stop_screen_bgm()
		return
	if (
		_screen_bgm_player != null
		and is_instance_valid(_screen_bgm_player)
		and _screen_bgm_path == path
	):
		if not _screen_bgm_player.playing:
			_screen_bgm_player.play()
		return
	stop_screen_bgm()
	if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
		push_warning("BGMが見つかりません: %s" % path)
		return
	var stream := load(path) as AudioStream
	if stream == null:
		push_warning("BGMを読み込めません: %s" % path)
		return
	var mp3_stream := stream as AudioStreamMP3
	if mp3_stream != null:
		mp3_stream.loop = true
	_screen_bgm_player = AudioStreamPlayer.new()
	_screen_bgm_player.name = "ScreenBGMPlayer"
	_screen_bgm_player.stream = stream
	_screen_bgm_player.volume_db = volume_db
	_screen_bgm_player.finished.connect(_on_screen_bgm_finished)
	add_child(_screen_bgm_player)
	_screen_bgm_path = path
	_screen_bgm_player.play()


func stop_screen_bgm() -> void:
	if _screen_bgm_player == null or not is_instance_valid(_screen_bgm_player):
		_screen_bgm_player = null
		_screen_bgm_path = ""
		return
	var player := _screen_bgm_player
	_screen_bgm_player = null
	_screen_bgm_path = ""
	player.stop()
	player.queue_free()


func _on_screen_bgm_finished() -> void:
	if _screen_bgm_player != null and is_instance_valid(_screen_bgm_player) and is_inside_tree():
		_screen_bgm_player.play()


func play_screen_sfx(path: String, volume_db: float = -3.0) -> void:
	_last_sfx_path = path
	if path.strip_edges().is_empty():
		return
	if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
		push_warning("効果音が見つかりません: %s" % path)
		return
	var stream := load(path) as AudioStream
	if stream == null:
		push_warning("効果音を読み込めません: %s" % path)
		return
	var player := AudioStreamPlayer.new()
	player.name = "ScreenSFXPlayer"
	player.stream = stream
	player.volume_db = volume_db
	player.finished.connect(func() -> void: player.queue_free())
	add_child(player)
	player.play()


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


func make_return_button(callback: Callable, minimum_width: float = 180.0) -> Button:
	var button := make_button("港へ戻る", callback, minimum_width, false)
	button.name = "HarborReturnButton"
	button.set_meta("harbor_return", true)
	var normal := ShowcaseAssetsScript.texture_style(
		"res://assets/showcase/common/action_button_frame.png",
		Vector4(46.0, 24.0, 46.0, 24.0)
	)
	if normal != null:
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", normal)
		button.add_theme_stylebox_override("pressed", normal)
		button.add_theme_stylebox_override("focus", normal)
	button.add_theme_color_override("font_color", Palette.TEXT_BONE)
	button.add_theme_color_override("font_hover_color", Palette.GOLD_BRIGHT)
	button.add_theme_color_override("font_pressed_color", Palette.GOLD_BRIGHT)
	button.add_theme_color_override("font_outline_color", Palette.TEXT_OUTLINE_DARK)
	button.add_theme_constant_override("outline_size", 2)
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


func format_play_time(total_seconds: float) -> String:
	var seconds := int(total_seconds)
	var hours := seconds / 3600
	var minutes := (seconds % 3600) / 60
	var remaining := seconds % 60
	return "%02d:%02d:%02d" % [hours, minutes, remaining]


static func format_money(value: int) -> String:
	var raw := str(value)
	var result := ""
	var count := 0
	for index in range(raw.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = raw[index] + result
		count += 1
	return result


func _anchored_control(parent: Control, left: float, top: float, right: float, bottom: float) -> Control:
	var control := Control.new()
	_place_control(parent, control, left, top, right, bottom)
	return control


func _place_control(parent: Control, control: Control, left: float, top: float, right: float, bottom: float) -> void:
	control.anchor_left = left
	control.anchor_top = top
	control.anchor_right = right
	control.anchor_bottom = bottom
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0
	parent.add_child(control)
