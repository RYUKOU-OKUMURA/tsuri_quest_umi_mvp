class_name CatchFanfare
extends Control

const FightFishAssetsScript = preload("res://src/ui/fight_fish_assets.gd")
const RarityStylesScript = preload("res://src/ui/rarity_styles.gd")
const ShowcaseAssetsScript = preload("res://src/ui/showcase_assets.gd")

signal continue_requested
signal harbor_requested

const DESIGN_SIZE := Vector2(1280.0, 720.0)
const AUDIO_MIX_RATE := 22050
const AUDIO_SECONDS := 1.12
const FANFARE_NOTES := [
	{"start": 0.00, "duration": 0.11, "freq": 523.25},
	{"start": 0.12, "duration": 0.11, "freq": 659.25},
	{"start": 0.24, "duration": 0.11, "freq": 783.99},
	{"start": 0.36, "duration": 0.18, "freq": 1046.50},
	{"start": 0.57, "duration": 0.11, "freq": 783.99},
	{"start": 0.69, "duration": 0.11, "freq": 987.77},
	{"start": 0.81, "duration": 0.24, "freq": 1318.51},
]
const CATCH_PHOTO_BASE_PATH := "res://assets/showcase/underwater/catch_photo_base.png"
const PHOTO_TITLE_SLOT := Rect2(326.0, 28.0, 628.0, 112.0)
const PHOTO_INFO_SLOT := Rect2(150.0, 496.0, 284.0, 90.0)
const PHOTO_RECORD_BADGE_SLOT := Rect2(286.0, 472.0, 136.0, 24.0)
const PHOTO_BONUS_SLOT := Rect2(742.0, 500.0, 388.0, 112.0)
const PHOTO_FISH_SLOT := Rect2(210.0, 204.0, 860.0, 476.0)
const PHOTO_CONTINUE_SLOT := Rect2(280.0, 642.0, 300.0, 54.0)
const PHOTO_HARBOR_SLOT := Rect2(674.0, 642.0, 300.0, 54.0)

var _fish_data: Dictionary = {}
var _catch_result: Dictionary = {}
var _size_cm := 0.0
var _elapsed := 0.0
var _playing := false
var _rare_mode := false
var _particles: Array[Dictionary] = []

var _flash: ColorRect
var _photo_base_texture: TextureRect
var _banner: PanelContainer
var _banner_label: Label
var _info_panel: PanelContainer
var _bonus_panel: PanelContainer
var _fish_card: Control
var _fish_texture: TextureRect
var _fish_name_label: Label
var _rarity_label: Label
var _size_label: Label
var _record_badge_label: Label
var _bonus_label: Label
var _continue_button: Button
var _harbor_button: Button
var _animation_tween: Tween

var _banner_target_position := Vector2.ZERO
var _info_target_position := Vector2.ZERO
var _bonus_target_position := Vector2.ZERO
var _fish_card_target_position := Vector2.ZERO
var _continue_target_position := Vector2.ZERO
var _harbor_target_position := Vector2.ZERO

var _audio_player: AudioStreamPlayer
var _audio_playback: AudioStreamGeneratorPlayback
var _audio_sample_time := 0.0
var _audio_active := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_particles()
	_build_nodes()
	resized.connect(_layout_nodes)
	_layout_nodes()


func is_playing() -> bool:
	return _playing


func play(fish_data: Dictionary, size_cm: float, catch_result: Dictionary = {}) -> void:
	_stop_tweens()
	_fish_data = fish_data.duplicate(true)
	_catch_result = catch_result.duplicate(true)
	_size_cm = size_cm
	_elapsed = 0.0
	_playing = true
	_rare_mode = RarityStylesScript.is_rare_or_boss(_fish_data)
	visible = true
	modulate = Color.WHITE
	_update_content()
	_layout_nodes()
	_prepare_intro_state()
	_start_animation()
	_start_fanfare_audio()
	queue_redraw()


func _process(delta: float) -> void:
	if not _playing:
		return
	_elapsed += delta
	_fill_audio_buffer()
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not _playing:
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			if (
				key_event.keycode == KEY_SPACE
				or key_event.keycode == KEY_ENTER
				or key_event.keycode == KEY_KP_ENTER
			):
				_request_continue()
				get_viewport().set_input_as_handled()
			elif key_event.keycode == KEY_ESCAPE:
				_request_harbor()
				get_viewport().set_input_as_handled()


func _draw() -> void:
	if not _playing:
		return
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(Palette.DARK_PANEL_DEEP, 0.52), true)
	_draw_rays()
	_draw_particles()


func _build_nodes() -> void:
	_photo_base_texture = ShowcaseAssetsScript.texture_rect(CATCH_PHOTO_BASE_PATH, TextureRect.STRETCH_SCALE)
	_photo_base_texture.name = "CatchPhotoBase"
	add_child(_photo_base_texture)

	_fish_card = Control.new()
	_fish_card.name = "CatchPhotoFishLayer"
	_fish_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fish_card)

	_fish_texture = TextureRect.new()
	_fish_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_fish_texture.stretch_mode = TextureRect.STRETCH_SCALE
	_fish_texture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_fish_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fish_card.add_child(_fish_texture)

	_flash = ColorRect.new()
	_flash.color = Palette.CATCH_FLASH_CLEAR
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_banner = PanelContainer.new()
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.add_theme_stylebox_override("panel", _empty_style())
	add_child(_banner)

	_banner_label = _make_label("釣り上げた！", 76, Palette.GOLD_BRIGHT, 6)
	_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_banner_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_banner.add_child(_banner_label)

	_info_panel = PanelContainer.new()
	_info_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_info_panel.add_theme_stylebox_override("panel", _text_plate_style())
	add_child(_info_panel)
	var info_box := VBoxContainer.new()
	info_box.add_theme_constant_override("separation", 0)
	_info_panel.add_child(info_box)
	_fish_name_label = _make_label("", 22, Palette.TEXT_BONE, 3)
	_fish_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_box.add_child(_fish_name_label)
	_size_label = _make_label("", 20, Palette.TEXT_BONE, 3)
	_size_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_box.add_child(_size_label)
	_rarity_label = _make_label("", 18, Palette.TEXT_BONE, 3)
	_rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_box.add_child(_rarity_label)

	_record_badge_label = _make_label("NEW RECORD", 12, Palette.GOLD_BRIGHT, 2)
	_record_badge_label.name = "CatchRecordBadge"
	_record_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_record_badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_record_badge_label.visible = false
	add_child(_record_badge_label)

	_bonus_panel = PanelContainer.new()
	_bonus_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bonus_panel.add_theme_stylebox_override("panel", _text_plate_style())
	add_child(_bonus_panel)
	_bonus_label = _make_label("", 17, Palette.TEXT_BONE, 3)
	_bonus_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bonus_label.max_lines_visible = 4
	_bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bonus_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bonus_label.clip_text = false
	_bonus_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_bonus_panel.add_child(_bonus_label)

	_continue_button = _make_photo_button("続けて釣る")
	_continue_button.pressed.connect(_request_continue)
	add_child(_continue_button)

	_harbor_button = _make_photo_button("港へ戻る")
	_harbor_button.pressed.connect(_request_harbor)
	add_child(_harbor_button)

	add_child(_flash)

	_audio_player = AudioStreamPlayer.new()
	_audio_player.name = "CatchFanfareAudio"
	_audio_player.volume_db = -10.0
	add_child(_audio_player)


func _layout_nodes() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var scale_factor := minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	var origin := (size - DESIGN_SIZE * scale_factor) * 0.5
	_apply_rect(_photo_base_texture, Rect2(Vector2.ZERO, DESIGN_SIZE), scale_factor, origin)
	_apply_rect(_banner, PHOTO_TITLE_SLOT, scale_factor, origin)
	_apply_rect(_info_panel, PHOTO_INFO_SLOT, scale_factor, origin)
	_apply_rect(_record_badge_label, PHOTO_RECORD_BADGE_SLOT, scale_factor, origin)
	_apply_rect(_bonus_panel, PHOTO_BONUS_SLOT, scale_factor, origin)
	_apply_rect(_fish_card, PHOTO_FISH_SLOT, scale_factor, origin)
	_apply_rect(_fish_texture, Rect2(Vector2.ZERO, _fish_card.size), 1.0, Vector2.ZERO)
	_apply_rect(_continue_button, PHOTO_CONTINUE_SLOT, scale_factor, origin)
	_apply_rect(_harbor_button, PHOTO_HARBOR_SLOT, scale_factor, origin)
	_banner_target_position = _banner.position
	_info_target_position = _info_panel.position
	_bonus_target_position = _bonus_panel.position
	_fish_card_target_position = _fish_card.position
	_continue_target_position = _continue_button.position
	_harbor_target_position = _harbor_button.position
	_banner.pivot_offset = _banner.size * 0.5
	_info_panel.pivot_offset = _info_panel.size * 0.5
	_bonus_panel.pivot_offset = _bonus_panel.size * 0.5
	_fish_card.pivot_offset = _fish_card.size * 0.5


func _apply_rect(control: Control, design_rect: Rect2, scale_factor: float, origin: Vector2) -> void:
	control.position = origin + design_rect.position * scale_factor
	control.size = design_rect.size * scale_factor


func _update_content() -> void:
	var fish_name := String(_fish_data.get("name", "魚"))
	var rarity := String(_fish_data.get("rarity", "コモン"))
	var record_broken := bool(_catch_result.get("record_broken", false))
	_fish_name_label.text = fish_name
	_size_label.text = "大きさ %.1f cm" % _size_cm
	_size_label.add_theme_color_override(
		"font_color",
		Palette.GOLD_BRIGHT if record_broken else Palette.TEXT_BONE
	)
	_record_badge_label.visible = record_broken
	_rarity_label.text = "レアリティ　%s" % rarity
	_rarity_label.add_theme_color_override("font_color", RarityStylesScript.text_color(rarity))
	_bonus_label.text = _bonus_text()
	_fish_texture.texture = ShowcaseAssetsScript.load_texture(FightFishAssetsScript.card_portrait_path(_fish_data))


func _bonus_text() -> String:
	var lines: Array[String] = []
	if bool(_catch_result.get("record_broken", false)):
		var previous_best := float(_catch_result.get("previous_best_cm", 0.0))
		lines.append("自己記録更新！ %.1f cm（+%.1f cm）" % [_size_cm, maxf(0.0, _size_cm - previous_best)])
	var reward: Dictionary = _catch_result.get("boss_first_clear_reward", {})
	var reward_money := int(reward.get("money", 0))
	if reward_money > 0:
		lines.append("撃破報酬 +%s G" % ScreenBase.format_money(reward_money))
	for title_id_variant in Array(_catch_result.get("new_titles", [])).slice(0, 2):
		lines.append("称号獲得　「%s」" % _title_name(String(title_id_variant)))
	if bool(_catch_result.get("first_catch", false)) and lines.is_empty():
		lines.append("初回記録　図鑑に登録")
	if lines.is_empty():
		lines.append("港で売却 / 料理に使える")
	return "\n".join(PackedStringArray(lines))


func _title_name(title_id: String) -> String:
	for title in GameData.TITLES:
		if String(title.get("id", "")) == title_id:
			return String(title.get("name", title_id))
	return title_id


func _prepare_intro_state() -> void:
	_flash.color = Palette.CATCH_FLASH_BRIGHT
	_banner.position = _banner_target_position
	_banner.scale = Vector2(0.72, 0.72)
	_banner.modulate = Palette.CATCH_FLASH_CLEAR
	_info_panel.position = _info_target_position + Vector2(-72.0, 18.0)
	_info_panel.scale = Vector2(0.96, 0.96)
	_info_panel.modulate = Palette.CATCH_FLASH_CLEAR
	_record_badge_label.modulate = Palette.CATCH_FLASH_CLEAR
	_bonus_panel.position = _bonus_target_position + Vector2(58.0, 16.0)
	_bonus_panel.scale = Vector2(0.96, 0.96)
	_bonus_panel.modulate = Palette.CATCH_FLASH_CLEAR
	_fish_card.position = _fish_card_target_position + Vector2(128.0, 20.0)
	_fish_card.scale = Vector2(0.92, 0.92)
	_fish_card.modulate = Palette.CATCH_FLASH_CLEAR
	_continue_button.position = _continue_target_position
	_continue_button.modulate = Palette.CATCH_FLASH_CLEAR
	_harbor_button.position = _harbor_target_position
	_harbor_button.modulate = Palette.CATCH_FLASH_CLEAR


func _start_animation() -> void:
	_animation_tween = create_tween()
	_animation_tween.set_parallel(true)
	_animation_tween.tween_property(_flash, "color:a", 0.0, 0.20).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_animation_tween.tween_property(_banner, "modulate:a", 1.0, 0.20).set_ease(Tween.EASE_OUT)
	_animation_tween.tween_property(_banner, "scale", Vector2.ONE, 0.34).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_animation_tween.tween_property(_fish_card, "position", _fish_card_target_position, 0.38).set_delay(0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_animation_tween.tween_property(_fish_card, "modulate:a", 1.0, 0.30).set_delay(0.18).set_ease(Tween.EASE_OUT)
	_animation_tween.tween_property(_fish_card, "scale", Vector2.ONE, 0.42).set_delay(0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_animation_tween.tween_property(_info_panel, "position", _info_target_position, 0.34).set_delay(0.36).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_animation_tween.tween_property(_info_panel, "modulate:a", 1.0, 0.28).set_delay(0.36).set_ease(Tween.EASE_OUT)
	_animation_tween.tween_property(_record_badge_label, "modulate:a", 1.0, 0.24).set_delay(0.42).set_ease(Tween.EASE_OUT)
	_animation_tween.tween_property(_bonus_panel, "position", _bonus_target_position, 0.34).set_delay(0.40).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_animation_tween.tween_property(_bonus_panel, "modulate:a", 1.0, 0.28).set_delay(0.40).set_ease(Tween.EASE_OUT)
	_animation_tween.tween_property(_continue_button, "modulate:a", 1.0, 0.18).set_delay(0.82).set_ease(Tween.EASE_OUT)
	_animation_tween.tween_property(_harbor_button, "modulate:a", 1.0, 0.18).set_delay(0.82).set_ease(Tween.EASE_OUT)


func _close_result_screen() -> void:
	if not _playing:
		return
	_playing = false
	_stop_tweens()
	_stop_audio()
	visible = false


func _request_continue() -> void:
	if not _playing:
		return
	_close_result_screen()
	continue_requested.emit()


func _request_harbor() -> void:
	if not _playing:
		return
	_close_result_screen()
	harbor_requested.emit()


func _stop_tweens() -> void:
	if _animation_tween != null and _animation_tween.is_valid():
		_animation_tween.kill()
	_animation_tween = null


func _build_particles() -> void:
	_particles.clear()
	for index in range(42):
		var x := fmod(91.0 + float(index * 137), 1120.0) + 80.0
		var y := fmod(62.0 + float(index * 83), 480.0) + 76.0
		var speed := 18.0 + float(index % 6) * 7.0
		var phase := float(index % 9) * 0.33
		_particles.append({
			"x": x,
			"y": y,
			"speed": speed,
			"phase": phase,
			"kind": index % 4,
		})


func _draw_rays() -> void:
	var center := Vector2(size.x * 0.50, size.y * 0.26)
	var radius := maxf(size.x, size.y) * (0.62 + 0.05 * sin(_elapsed * 3.0))
	var alpha := clampf(0.30 - _elapsed * 0.07, 0.11, 0.30)
	for index in range(24):
		var angle := TAU * float(index) / 24.0 + _elapsed * 0.10
		var spread := TAU / 55.0
		var points := PackedVector2Array([
			center,
			center + Vector2(cos(angle - spread), sin(angle - spread)) * radius,
			center + Vector2(cos(angle + spread), sin(angle + spread)) * radius,
		])
		var ray_color := Palette.GOLD_BRIGHT if index % 2 == 0 else Palette.FOAM
		draw_colored_polygon(points, Color(ray_color, alpha * (0.72 if index % 2 == 0 else 0.35)))
	draw_circle(center, 96.0 + sin(_elapsed * 5.0) * 9.0, Color(Palette.GOLD_BRIGHT, 0.13))
	draw_circle(center, 42.0 + sin(_elapsed * 8.0) * 5.0, Color(Palette.FOAM, 0.18))


func _draw_particles() -> void:
	var amount := 42 if _rare_mode else 24
	for index in range(amount):
		var particle: Dictionary = _particles[index % _particles.size()]
		var base := Vector2(float(particle["x"]), float(particle["y"]))
		var drift := Vector2(
			sin(_elapsed * 2.4 + float(particle["phase"])) * 16.0,
			_elapsed * float(particle["speed"])
		)
		var pos := base + drift
		if pos.y > size.y - 76.0:
			pos.y = fmod(pos.y, size.y - 130.0) + 64.0
		var sparkle_alpha := clampf(1.0 - maxf(0.0, _elapsed - 1.35) * 2.0, 0.0, 1.0)
		if int(particle["kind"]) == 0 and _rare_mode:
			_draw_confetti(pos, index, sparkle_alpha)
		else:
			_draw_star(pos, 5.0 + float(index % 5), sparkle_alpha)


func _draw_star(center: Vector2, radius: float, alpha: float) -> void:
	var color := Color(Palette.GOLD_BRIGHT if _rare_mode else Palette.FOAM, 0.70 * alpha)
	draw_line(center + Vector2(-radius, 0.0), center + Vector2(radius, 0.0), color, 2.0)
	draw_line(center + Vector2(0.0, -radius), center + Vector2(0.0, radius), color, 2.0)
	if _rare_mode:
		draw_line(center + Vector2(-radius * 0.62, -radius * 0.62), center + Vector2(radius * 0.62, radius * 0.62), Color(Palette.GOLD, 0.38 * alpha), 1.5)
		draw_line(center + Vector2(radius * 0.62, -radius * 0.62), center + Vector2(-radius * 0.62, radius * 0.62), Color(Palette.GOLD, 0.38 * alpha), 1.5)


func _draw_confetti(center: Vector2, index: int, alpha: float) -> void:
	var color_options := [
		Palette.GOLD_BRIGHT,
		Palette.GAUGE_AMBER_HI,
		RarityStylesScript.text_color("レア"),
		Palette.FOAM,
	]
	var color := Color(color_options[index % color_options.size()], 0.78 * alpha)
	var rect := Rect2(center, Vector2(12.0 + float(index % 4) * 2.0, 5.0))
	draw_set_transform(center, 0.35 * sin(_elapsed * 3.0 + float(index)), Vector2.ONE)
	draw_rect(Rect2(-rect.size * 0.5, rect.size), color, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _make_label(text: String, font_size: int, color: Color, outline: int = 0) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if outline > 0:
		label.add_theme_constant_override("outline_size", outline)
		label.add_theme_color_override("font_outline_color", Palette.TEXT_OUTLINE_DARK)
	label.add_theme_color_override("font_shadow_color", Palette.SHADOW)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_constant_override("shadow_outline_size", 2)
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return label


func _empty_style() -> StyleBoxEmpty:
	var style := StyleBoxEmpty.new()
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style


func _text_plate_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Palette.PARCHMENT, 0.32)
	style.border_color = Color(Palette.GOLD_BRIGHT, 0.18)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	style.shadow_color = Color(Palette.TEXT_OUTLINE_DARK, 0.20)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0.0, 2.0)
	return style


func _make_photo_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.flat = true
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 30)
	button.add_theme_color_override("font_color", Palette.TEXT_BONE)
	button.add_theme_color_override("font_hover_color", Palette.GOLD_BRIGHT)
	button.add_theme_color_override("font_pressed_color", Palette.GOLD_BRIGHT)
	button.add_theme_color_override("font_focus_color", Palette.GOLD_BRIGHT)
	button.add_theme_color_override("font_outline_color", Palette.TEXT_OUTLINE_DARK)
	button.add_theme_constant_override("outline_size", 4)
	button.add_theme_stylebox_override("normal", _photo_button_style(false))
	button.add_theme_stylebox_override("hover", _photo_button_style(true))
	button.add_theme_stylebox_override("focus", _photo_button_style(true))
	button.add_theme_stylebox_override("pressed", _photo_button_pressed_style())
	return button


func _photo_button_style(hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(Palette.GOLD_BRIGHT, 0.00 if not hovered else 0.10)
	style.border_color = Color(Palette.GOLD_BRIGHT, 0.00 if not hovered else 0.28)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


func _photo_button_pressed_style() -> StyleBoxFlat:
	var style := _photo_button_style(true)
	style.bg_color = Color(Palette.GOLD_DEEP, 0.18)
	return style


func _start_fanfare_audio() -> void:
	if _audio_player == null:
		return
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = AUDIO_MIX_RATE
	stream.buffer_length = 0.35
	_audio_player.stream = stream
	_audio_player.play()
	_audio_playback = _audio_player.get_stream_playback() as AudioStreamGeneratorPlayback
	_audio_sample_time = 0.0
	_audio_active = _audio_playback != null
	_fill_audio_buffer()


func _fill_audio_buffer() -> void:
	if not _audio_active or _audio_playback == null:
		return
	var frames_available := _audio_playback.get_frames_available()
	for _index in range(frames_available):
		var sample := _fanfare_sample(_audio_sample_time)
		_audio_playback.push_frame(Vector2(sample, sample))
		_audio_sample_time += 1.0 / float(AUDIO_MIX_RATE)
	if _audio_sample_time > AUDIO_SECONDS + 0.35:
		_audio_active = false


func _fanfare_sample(time_sec: float) -> float:
	var sample := 0.0
	for note_variant in FANFARE_NOTES:
		var note: Dictionary = note_variant
		var start := float(note["start"])
		var duration := float(note["duration"])
		if time_sec < start or time_sec > start + duration:
			continue
		var local := time_sec - start
		var phase := TAU * float(note["freq"]) * local
		var attack := clampf(local / 0.018, 0.0, 1.0)
		var release := clampf((duration - local) / 0.052, 0.0, 1.0)
		var envelope := minf(attack, release)
		sample += sin(phase) * envelope * 0.14
		sample += sin(phase * 2.0) * envelope * 0.035
	return clampf(sample, -0.42, 0.42)


func _stop_audio() -> void:
	_audio_active = false
	_audio_playback = null
	if _audio_player != null and _audio_player.playing:
		_audio_player.stop()
