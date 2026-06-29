extends "res://src/ui/screen_base.gd"

const HarborBackdropScript = preload("res://src/ui/components/harbor_backdrop.gd")
const GameFontsScript = preload("res://src/ui/game_fonts.gd")

const HARBOR_TOP_FRAME_PATH := "res://assets/showcase/harbor/harbor_top_frame.png"
const HARBOR_MAIN_FRAME_PATH := "res://assets/showcase/harbor/harbor_main_frame.png"
const HARBOR_MENU_FRAME_PATH := "res://assets/showcase/harbor/harbor_menu_frame.png"
const HARBOR_FOOTER_FRAME_PATH := "res://assets/showcase/harbor/harbor_footer_frame.png"
const HARBOR_SCENE_WINDOW_PATH := "res://assets/showcase/harbor/harbor_scene_window.png"
const HARBOR_PARCHMENT_CARD_PATH := "res://assets/showcase/harbor/harbor_parchment_card.png"
const HARBOR_BUTTON_PATH := "res://assets/showcase/harbor/harbor_facility_card.png"
const HARBOR_BUTTON_HOVER_PATH := "res://assets/showcase/harbor/harbor_facility_card_hover.png"
const HARBOR_BUTTON_PRIMARY_PATH := "res://assets/showcase/harbor/harbor_facility_card_primary.png"
const ICON_FISHING_PATH := "res://assets/showcase/underwater/hud_bait_icon.png"
const ICON_COOKING_PATH := "res://assets/showcase/cooking/dish_feature_aji_shioyaki.png"
const ICON_MARKET_PATH := "res://assets/showcase/cooking/status_money_art.png"
const ICON_SHOP_PATH := "res://assets/showcase/underwater/fight_tackle_card_icon.png"
const ICON_STATUS_PATH := "res://assets/showcase/cooking/player_status_portrait.png"
const ICON_TITLE_PATH := "res://assets/showcase/underwater/fight_action_card_icon.png"

var _status_label: Label
var _top_level_label: Label
var _top_money_label: Label
var _top_rod_label: Label
var _top_exp_label: Label
var _buff_name_label: Label
var _buff_text_label: Label


func _build_screen() -> void:
	var backdrop := HarborBackdropScript.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	move_child(backdrop, 0)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_build_top_bar(root)
	_build_main_panel(root)
	_build_facility_menu(root)
	_build_footer(root)
	_refresh_labels()


func _build_top_bar(root: Control) -> void:
	var top := _anchored_control(root, 0.020, 0.028, 0.980, 0.150)
	var frame := _texture_rect(HARBOR_TOP_FRAME_PATH)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top.add_child(frame)

	var location := _harbor_label("南の島・港", 32, Color("#fff0aa"), true, 4, Color("#1c1309"))
	location.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	location.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(top, location, 0.026, 0.15, 0.265, 0.67)

	var context := _harbor_label("潮位：満ち始め　天候：快晴　風：弱", 15, Color("#d9f2ff"), false, 2, Color("#06131d"))
	context.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	context.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(top, context, 0.030, 0.62, 0.395, 0.92)

	_top_level_label = _top_metric(top, 0.395, 0.145, 0.485, 0.825, "Lv.1")
	_top_exp_label = _top_metric(top, 0.495, 0.145, 0.660, 0.825, "EXP 0 / 60")
	_top_money_label = _top_metric(top, 0.670, 0.145, 0.810, 0.825, "500 G")
	_top_rod_label = _top_metric(top, 0.820, 0.145, 0.972, 0.825, "入門竿")


func _build_main_panel(root: Control) -> void:
	var main := _anchored_control(root, 0.026, 0.170, 0.660, 0.882)
	var frame := _texture_rect(HARBOR_MAIN_FRAME_PATH)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.add_child(frame)

	var scene := _texture_rect(HARBOR_SCENE_WINDOW_PATH)
	scene.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_place_control(main, scene, 0.060, 0.068, 0.940, 0.432)

	var scene_shadow := ColorRect.new()
	scene_shadow.color = Color(0.0, 0.0, 0.0, 0.22)
	scene_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(main, scene_shadow, 0.060, 0.068, 0.940, 0.432)

	var scene_title := _harbor_label("潮風が吹く、小さな漁港", 34, Color("#ffe59d"), true, 4, Color("#271708"))
	scene_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(main, scene_title, 0.090, 0.104, 0.910, 0.205)

	var scene_text := _harbor_label(
		"沖では魚影が濃くなっている。\n釣った魚は市場で売るか、調理場で食べて成長できる。\n準備ができたら海へ出よう。",
		18,
		Color("#f2fbff"),
		false,
		2,
		Color("#071522")
	)
	scene_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scene_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	scene_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place_control(main, scene_text, 0.130, 0.225, 0.870, 0.395)

	_build_parchment_card(
		main,
		Rect2(0.066, 0.482, 0.868, 0.172),
		"今日の支度",
		"釣る  →  売る／料理する  →  装備・レベル強化  →  ぬしに挑む",
		ICON_FISHING_PATH
	)
	_build_buff_card(main)


func _build_buff_card(main: Control) -> void:
	var card := _anchored_control(main, 0.066, 0.684, 0.934, 0.855)
	var frame := _texture_rect(HARBOR_PARCHMENT_CARD_PATH)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_child(frame)

	var icon := _icon_rect(ICON_COOKING_PATH)
	_place_control(card, icon, 0.030, 0.160, 0.118, 0.840)

	var title := _harbor_label("次の釣行の食事効果", 15, Color("#765025"), true, 0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(card, title, 0.145, 0.100, 0.930, 0.365)

	_buff_name_label = _harbor_label("", 20, Color("#2a2118"), true, 0)
	_buff_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_buff_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(card, _buff_name_label, 0.145, 0.345, 0.930, 0.635)

	_buff_text_label = _harbor_label("", 15, Color("#4f3a21"), false, 0)
	_buff_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_buff_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(card, _buff_text_label, 0.145, 0.625, 0.930, 0.900)


func _build_parchment_card(parent: Control, ratios: Rect2, title_text: String, body_text: String, icon_path: String) -> void:
	var card := _anchored_control(parent, ratios.position.x, ratios.position.y, ratios.position.x + ratios.size.x, ratios.position.y + ratios.size.y)
	var frame := _texture_rect(HARBOR_PARCHMENT_CARD_PATH)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_child(frame)

	var icon := _icon_rect(icon_path)
	_place_control(card, icon, 0.030, 0.185, 0.112, 0.815)

	var title := _harbor_label(title_text, 15, Color("#765025"), true, 0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(card, title, 0.140, 0.100, 0.930, 0.375)

	var body := _harbor_label(body_text, 19, Color("#243349"), true, 0)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(card, body, 0.140, 0.405, 0.930, 0.820)


func _build_facility_menu(root: Control) -> void:
	var menu := _anchored_control(root, 0.675, 0.170, 0.974, 0.882)
	var frame := _texture_rect(HARBOR_MENU_FRAME_PATH)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(frame)

	var header := _harbor_label("港の施設", 27, Color("#fff2c6"), true, 3, Color("#07131c"))
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(menu, header, 0.100, 0.030, 0.900, 0.120)

	_build_facility_button(menu, 0.160, "釣り場へ向かう", "海へ出て釣りをする", ICON_FISHING_PATH, func() -> void: navigate("fishing"), true)
	_build_facility_button(menu, 0.285, "調理場", "魚を料理して食事にする", ICON_COOKING_PATH, func() -> void: navigate("cooking"))
	_build_facility_button(menu, 0.410, "魚市場", "釣果を売って資金にする", ICON_MARKET_PATH, func() -> void: navigate("market"))
	_build_facility_button(menu, 0.535, "釣具店", "竿を購入・装備する", ICON_SHOP_PATH, func() -> void: navigate("shop"))
	_build_facility_button(menu, 0.660, "ステータス・図鑑", "成長と釣果を確認する", ICON_STATUS_PATH, func() -> void: navigate("status"))
	_build_facility_button(menu, 0.795, "タイトルへ戻る", "進行を保存して戻る", ICON_TITLE_PATH, _return_to_title)


func _build_facility_button(
	parent: Control,
	top: float,
	title_text: String,
	body_text: String,
	icon_path: String,
	callback: Callable,
	primary := false
) -> void:
	var button := make_button("", callback)
	button.custom_minimum_size = Vector2.ZERO
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.clip_contents = true
	_apply_facility_button_skin(button, primary)
	_place_control(parent, button, 0.088, top, 0.912, top + 0.108)

	var icon := _icon_rect(icon_path)
	icon.modulate = Color(1.0, 1.0, 1.0, 0.96)
	_place_control(button, icon, 0.038, 0.175, 0.155, 0.825)

	var title := _harbor_label(title_text, 20, Color("#fff4c9") if primary else Color("#22180f"), true, 2 if primary else 0, Color("#1b1209"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(button, title, 0.185, 0.070, 0.930, 0.515)

	var body := _harbor_label(body_text, 13, Color("#d9f4ff") if primary else Color("#4d3219"), false, 1 if primary else 0, Color("#06131d"))
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_control(button, body, 0.185, 0.570, 0.930, 0.930)


func _build_footer(root: Control) -> void:
	var footer := _anchored_control(root, 0.026, 0.902, 0.974, 0.974)
	var frame := _texture_rect(HARBOR_FOOTER_FRAME_PATH)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	footer.add_child(frame)

	_status_label = _harbor_label("", 17, Color("#edf8ff"), false, 2, Color("#06131d"))
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(footer, _status_label, 0.035, 0.050, 0.965, 0.950)


func _refresh_labels() -> void:
	var fish_total := 0
	for count in PlayerProgress.inventory.values():
		fish_total += int(count)
	var next_text := (
		"MAX"
		if PlayerProgress.level >= GameData.MAX_LEVEL
		else "%d / %d EXP" % [PlayerProgress.exp, PlayerProgress.exp_to_next_level()]
	)
	var rod_name := String(GameData.get_rod(PlayerProgress.equipped_rod_id).get("name", "入門竿"))
	_top_level_label.text = "Lv.%d" % PlayerProgress.level
	_top_exp_label.text = "EXP %s" % next_text.replace(" EXP", "")
	_top_money_label.text = "%s G" % _format_money(PlayerProgress.money)
	_top_rod_label.text = rod_name
	_status_label.text = (
		"クーラーボックス：%d匹　｜　食経験値：%s　｜　プレイ時間：%s"
		% [
			fish_total,
			next_text,
			format_play_time(PlayerProgress.play_seconds),
		]
	)
	if PlayerProgress.pending_buff.is_empty():
		_buff_name_label.text = "食事効果：なし"
		_buff_text_label.text = "調理場で料理を食べると、次の釣行が有利になる。"
	else:
		_buff_name_label.text = String(PlayerProgress.pending_buff.get("name", "料理"))
		_buff_text_label.text = String(PlayerProgress.pending_buff.get("text", ""))


func _return_to_title() -> void:
	PlayerProgress.save_game()
	navigate("title")


func _top_metric(parent: Control, left: float, top: float, right: float, bottom: float, value: String) -> Label:
	var label := _harbor_label(value, 17, Color("#fff4c7"), true, 2, Color("#06131d"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_place_control(parent, label, left, top, right, bottom)
	return label


func _anchored_control(parent: Control, left: float, top: float, right: float, bottom: float) -> Control:
	var control := Control.new()
	control.anchor_left = left
	control.anchor_top = top
	control.anchor_right = right
	control.anchor_bottom = bottom
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0
	parent.add_child(control)
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


func _texture_rect(path: String) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = _load_texture_if_exists(path)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _icon_rect(path: String) -> TextureRect:
	var icon := _texture_rect(path)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon


func _load_texture_if_exists(path: String) -> Texture2D:
	if ResourceLoader.exists(path) or FileAccess.file_exists(path):
		return load(path) as Texture2D
	return null


func _harbor_label(
	text: String,
	font_size: int,
	color: Color,
	bold := false,
	outline := 0,
	outline_color := Color("#07131d")
) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if outline > 0:
		label.add_theme_color_override("font_outline_color", outline_color)
		label.add_theme_constant_override("outline_size", outline)
		label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.26))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		label.add_theme_constant_override("shadow_outline_size", 1)
	var fallback := get_theme_default_font()
	label.add_theme_font_override("font", GameFontsScript.bold(fallback) if bold else GameFontsScript.regular(fallback))
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return label


func _apply_facility_button_skin(button: Button, primary: bool) -> void:
	var normal_path := HARBOR_BUTTON_PRIMARY_PATH if primary else HARBOR_BUTTON_PATH
	var hover_path := HARBOR_BUTTON_HOVER_PATH
	var normal := _make_button_style(normal_path)
	var hover := _make_button_style(hover_path)
	if normal == null or hover == null:
		return
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_font_override("font", GameFontsScript.bold(get_theme_default_font()))
	button.add_theme_color_override("font_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_hover_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_pressed_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_disabled_color", Color.TRANSPARENT)
	button.add_theme_constant_override("outline_size", 0)
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func _make_button_style(path: String) -> StyleBoxTexture:
	var texture := _load_texture_if_exists(path)
	if texture == null:
		return null
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 50
	style.texture_margin_top = 28
	style.texture_margin_right = 50
	style.texture_margin_bottom = 28
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.content_margin_left = 22.0
	style.content_margin_top = 8.0
	style.content_margin_right = 22.0
	style.content_margin_bottom = 8.0
	return style


func _format_money(value: int) -> String:
	var raw := str(value)
	var result := ""
	var count := 0
	for index in range(raw.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = raw[index] + result
		count += 1
	return result
