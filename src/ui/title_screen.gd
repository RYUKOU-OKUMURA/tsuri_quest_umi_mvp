extends ScreenBase

const TitleBackdropScript = preload("res://src/ui/components/title_backdrop.gd")
const GameFontsScript = preload("res://src/ui/game_fonts.gd")
const FightFishAssets = preload("res://src/ui/fight_fish_assets.gd")

const TITLE_LOGO_FRAME_PATH := "res://assets/showcase/title/title_logo_frame.png"
const TITLE_MENU_FRAME_PATH := "res://assets/showcase/title/title_menu_frame.png"
const TITLE_BUTTON_PRIMARY_PATH := "res://assets/showcase/title/title_button_primary.png"
const TITLE_BUTTON_PRIMARY_HOVER_PATH := "res://assets/showcase/title/title_button_primary_hover.png"
const TITLE_BUTTON_PRIMARY_PRESSED_PATH := "res://assets/showcase/title/title_button_primary_pressed.png"
const TITLE_BUTTON_SECONDARY_PATH := "res://assets/showcase/title/title_button_secondary.png"
const TITLE_BUTTON_SECONDARY_HOVER_PATH := "res://assets/showcase/title/title_button_secondary_hover.png"
const TITLE_BUTTON_DISABLED_PATH := "res://assets/showcase/title/title_button_disabled.png"
const TITLE_BAIT_PATH := "res://assets/showcase/common/nav_fishing_icon.png"

var _confirm_reset: ConfirmationDialog


func _build_screen() -> void:
	var backdrop := TitleBackdropScript.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	move_child(backdrop, 0)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_build_logo(root)
	_build_fish_feature(root)
	_build_menu(root)
	_build_version(root)
	_build_reset_dialog()


func _build_logo(root: Control) -> void:
	var logo_layer := _anchored_control(root, 0.055, 0.090, 0.720, 0.375)
	logo_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var logo_frame := _texture_rect(TITLE_LOGO_FRAME_PATH)
	logo_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	logo_layer.add_child(logo_frame)

	var title := make_shadow_label("釣りクエスト", 66, Color("#fff0a9"), 7, Color("#2b1308"), Color(0.0, 0.0, 0.0, 0.74))
	_apply_title_font(title, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	_place_control(logo_layer, title, 0.12, 0.18, 0.88, 0.49)

	var subtitle := make_shadow_label("海釣り編", 30, Color("#9de9ff"), 4, Color("#062a40"), Color(0.0, 0.0, 0.0, 0.58))
	_apply_title_font(subtitle, true)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_OFF
	_place_control(logo_layer, subtitle, 0.18, 0.50, 0.82, 0.67)

	var concept := make_shadow_label("港で支度し、釣って、料理して、強くなる。", 18, Color("#fff7d4"), 2, Color("#061624"), Color(0.0, 0.0, 0.0, 0.46))
	_apply_title_font(concept, false)
	concept.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	concept.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	concept.autowrap_mode = TextServer.AUTOWRAP_OFF
	concept.clip_text = true
	_place_control(logo_layer, concept, 0.14, 0.70, 0.86, 0.84)


func _build_fish_feature(root: Control) -> void:
	var feature := _anchored_control(root, 0.050, 0.555, 0.430, 0.930)
	feature.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var fish_texture := _load_texture_if_exists(FightFishAssets.card_portrait_path({"id": "boss_kurodai"}))
	if fish_texture != null:
		var fish := TextureRect.new()
		fish.texture = fish_texture
		fish.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fish.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fish.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		fish.modulate = Color(1.0, 1.0, 1.0, 0.92)
		fish.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fish.offset_top = -18.0
		fish.offset_bottom = -18.0
		feature.add_child(fish)

	var caption := make_shadow_label("次の大物が、海の底で待っている。", 18, Color("#fff5c5"), 2, Color("#071420"), Color(0.0, 0.0, 0.0, 0.54))
	_apply_title_font(caption, false)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.anchor_left = 0.0
	caption.anchor_top = 0.82
	caption.anchor_right = 1.0
	caption.anchor_bottom = 1.0
	caption.offset_left = 10.0
	caption.offset_top = 0.0
	caption.offset_right = -10.0
	caption.offset_bottom = 0.0
	feature.add_child(caption)


func _build_menu(root: Control) -> void:
	var menu := _anchored_control(root, 0.550, 0.395, 0.960, 0.925)
	var menu_frame := _texture_rect(TITLE_MENU_FRAME_PATH)
	menu_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(menu_frame)

	var bait_texture := _load_texture_if_exists(TITLE_BAIT_PATH)
	if bait_texture != null:
		var bait := TextureRect.new()
		bait.texture = bait_texture
		bait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		bait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_place_control(menu, bait, 0.285, 0.075, 0.355, 0.175)

	var header := make_shadow_label("冒険の開始", 24, Palette.TEXT_BONE, 2, Color("#06121c"), Color(0.0, 0.0, 0.0, 0.42))
	_apply_title_font(header, true)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.autowrap_mode = TextServer.AUTOWRAP_OFF
	header.clip_text = true
	_place_control(menu, header, 0.13, 0.070, 0.91, 0.185)

	var has_save := PlayerProgress.has_save_file()
	var save_status := make_label("セーブデータ  %s" % ("あり" if has_save else "なし"), 15, Color("#4f361b"))
	_apply_title_font(save_status, false)
	save_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	save_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	save_status.autowrap_mode = TextServer.AUTOWRAP_OFF
	_place_control(menu, save_status, 0.14, 0.230, 0.86, 0.290)

	var continue_button := make_button("つづきから", func() -> void: navigate("harbor"), 430)
	continue_button.disabled = not PlayerProgress.has_save_file()
	continue_button.custom_minimum_size = Vector2.ZERO
	_apply_title_button_skin(continue_button, false)
	_place_control(menu, continue_button, 0.105, 0.330, 0.895, 0.470)

	var new_text := "最初から" if PlayerProgress.has_save_file() else "ゲームを始める"
	var new_button := make_button(new_text, _on_new_game_pressed, 430, true)
	new_button.custom_minimum_size = Vector2.ZERO
	_apply_title_button_skin(new_button, true)
	_place_control(menu, new_button, 0.105, 0.535, 0.895, 0.675)

	var readme_button := make_button("README.md を参照", func() -> void: pass, 430)
	readme_button.disabled = true
	readme_button.custom_minimum_size = Vector2.ZERO
	_apply_title_button_skin(readme_button, false)
	_place_control(menu, readme_button, 0.105, 0.740, 0.895, 0.880)


func _build_version(root: Control) -> void:
	var version_label := make_shadow_label("MVP Prototype v0.1 / Godot 4.7", 14, Color("#d7eef6"), 1, Color("#03101c"), Color(0.0, 0.0, 0.0, 0.42))
	_apply_title_font(version_label, false)
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_label.anchor_left = 0.550
	version_label.anchor_top = 0.925
	version_label.anchor_right = 0.960
	version_label.anchor_bottom = 0.980
	version_label.offset_left = 0.0
	version_label.offset_top = 0.0
	version_label.offset_right = 0.0
	version_label.offset_bottom = 0.0
	root.add_child(version_label)


func _build_reset_dialog() -> void:
	_confirm_reset = ConfirmationDialog.new()
	_confirm_reset.title = "セーブデータの初期化"
	_confirm_reset.dialog_text = "現在の進行を消して、最初から始めます。よろしいですか？"
	_confirm_reset.ok_button_text = "最初から始める"
	_confirm_reset.cancel_button_text = "キャンセル"
	_confirm_reset.confirmed.connect(_start_new_game)
	add_child(_confirm_reset)

func _texture_rect(path: String) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = _load_texture_if_exists(path)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _load_texture_if_exists(path: String) -> Texture2D:
	if ResourceLoader.exists(path) or FileAccess.file_exists(path):
		return load(path) as Texture2D
	return null


func _apply_title_font(label: Label, bold: bool) -> void:
	var fallback := get_theme_default_font()
	var font := GameFontsScript.extra_bold(fallback) if bold else GameFontsScript.regular(fallback)
	label.add_theme_font_override("font", font)


func _apply_title_button_skin(button: Button, primary: bool) -> void:
	var normal_path := TITLE_BUTTON_PRIMARY_PATH if primary else TITLE_BUTTON_SECONDARY_PATH
	var hover_path := TITLE_BUTTON_PRIMARY_HOVER_PATH if primary else TITLE_BUTTON_SECONDARY_HOVER_PATH
	var pressed_path := TITLE_BUTTON_PRIMARY_PRESSED_PATH if primary else TITLE_BUTTON_SECONDARY_PATH
	var normal := _make_button_style(normal_path)
	var hover := _make_button_style(hover_path)
	var pressed := _make_button_style(pressed_path)
	var disabled := _make_button_style(TITLE_BUTTON_DISABLED_PATH)
	if normal == null or hover == null or pressed == null or disabled == null:
		return
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_font_override("font", GameFontsScript.bold(get_theme_default_font()))
	button.add_theme_color_override("font_color", Color("#fff4ca"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Palette.GOLD_BRIGHT)
	button.add_theme_color_override("font_disabled_color", Color("#d1c8b6"))
	button.add_theme_color_override("font_outline_color", Color("#2a1608"))
	button.add_theme_constant_override("outline_size", 2)
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	button.clip_text = true


func _make_button_style(path: String) -> StyleBoxTexture:
	var texture := _load_texture_if_exists(path)
	if texture == null:
		return null
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 42
	style.texture_margin_top = 24
	style.texture_margin_right = 42
	style.texture_margin_bottom = 24
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.content_margin_left = 28.0
	style.content_margin_top = 10.0
	style.content_margin_right = 28.0
	style.content_margin_bottom = 10.0
	return style


func _on_new_game_pressed() -> void:
	if PlayerProgress.has_save_file():
		_confirm_reset.popup_centered(Vector2i(620, 220))
	else:
		_start_new_game()


func _start_new_game() -> void:
	PlayerProgress.reset_game()
	navigate("harbor")
