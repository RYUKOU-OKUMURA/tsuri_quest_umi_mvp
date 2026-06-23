class_name ScreenBase
extends Control

signal navigate_requested(screen_id: String, payload: Dictionary)

var route_payload: Dictionary = {}


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


func make_root_margin(margin: int = 18) -> MarginContainer:
	var root := MarginContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", margin)
	root.add_theme_constant_override("margin_top", margin)
	root.add_theme_constant_override("margin_right", margin)
	root.add_theme_constant_override("margin_bottom", margin)
	add_child(root)
	return root


func make_label(text: String, font_size: int = 18, color: Color = Color("#203042")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func make_button(text: String, callback: Callable, minimum_width: float = 0.0) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(minimum_width, 50.0)
	button.pressed.connect(callback)
	return button


func make_panel(dark: bool = false) -> PanelContainer:
	var panel := PanelContainer.new()
	if dark:
		panel.theme_type_variation = "DarkPanel"
	return panel


func make_header(title: String, subtitle: String = "") -> PanelContainer:
	var panel := make_panel(true)
	panel.custom_minimum_size = Vector2(0.0, 76.0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	panel.add_child(row)
	var title_label := make_label(title, 30, Color("#fff1c7"))
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title_label)
	if not subtitle.is_empty():
		var subtitle_label := make_label(subtitle, 17, Color("#d8e8f5"))
		subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(subtitle_label)
	return panel


func format_play_time(total_seconds: float) -> String:
	var seconds := int(total_seconds)
	var hours := seconds / 3600
	var minutes := (seconds % 3600) / 60
	var remaining := seconds % 60
	return "%02d:%02d:%02d" % [hours, minutes, remaining]
