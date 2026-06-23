extends RefCounted


# macOS ビルトインの丸ゴシックを即適用。リリース時はライセンス確定済みの
# .ttf を res://assets/fonts/ に置き、build_font() を FontFile 化に差し替えること。
const _SYSTEM_FONT_NAMES: Array[String] = [
	"Hiragino Maru Gothic ProN",
	"Hiragino Sans",
	"Yu Gothic",
	"Noto Sans JP",
	"Meiryo",
	"sans-serif",
]


static func build_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = build_font()
	theme.default_font_size = 18

	# 塗り＋枠に加え、柔らかいドロップシャドウでパネル/ボタンを浮かせる。
	var panel := _style(Color("#f3e8cd"), Color("#6e5635"), 3, 12, true, 12)
	var panel_dark := _style(Color("#12283f"), Color("#9a7745"), 3, 12, true, 14)
	var panel_blue := _style(Color("#173b61"), Color("#d1aa63"), 3, 10, true, 10)
	var button_normal := _style(Color("#8a5428"), Color("#e1bd72"), 2, 10, true, 7)
	var button_hover := _style(Color("#a66831"), Color("#ffe39b"), 3, 10, true, 9)
	var button_pressed := _style(Color("#60381f"), Color("#d29a4f"), 2, 10, false, 3)
	var button_disabled := _style(Color("#6c6860"), Color("#9c9586"), 2, 10, false, 0)
	var input_style := _style(Color("#fff8e8"), Color("#80643c"), 2, 8, true, 5)
	var progress_bg := _style(Color("#18202a"), Color("#8b7452"), 2, 6, false, 0)
	var progress_fill := _style(Color("#3cbf78"), Color("#d9ef8c"), 1, 6, false, 0)

	theme.set_stylebox("panel", "PanelContainer", panel)
	theme.set_stylebox("panel", "Panel", panel)
	theme.set_stylebox("panel", "PopupPanel", panel)
	theme.set_stylebox("normal", "Button", button_normal)
	theme.set_stylebox("hover", "Button", button_hover)
	theme.set_stylebox("pressed", "Button", button_pressed)
	theme.set_stylebox("disabled", "Button", button_disabled)
	theme.set_stylebox("focus", "Button", button_hover)
	theme.set_stylebox("normal", "LineEdit", input_style)
	theme.set_stylebox("normal", "TextEdit", input_style)
	theme.set_stylebox("normal", "OptionButton", button_normal)
	theme.set_stylebox("hover", "OptionButton", button_hover)
	theme.set_stylebox("pressed", "OptionButton", button_pressed)
	theme.set_stylebox("disabled", "OptionButton", button_disabled)
	theme.set_stylebox("background", "ProgressBar", progress_bg)
	theme.set_stylebox("fill", "ProgressBar", progress_fill)
	theme.set_stylebox("panel", "AcceptDialog", panel_dark)
	theme.set_stylebox("panel", "ConfirmationDialog", panel_dark)

	theme.set_color("font_color", "Label", Color("#203042"))
	theme.set_color("font_outline_color", "Label", Color("#0a1622"))
	theme.set_constant("outline_size", "Label", 0)  # 暗背景のラベルで個別に上書きして使う
	theme.set_color("font_color", "Button", Color("#fff7df"))
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", Color("#fff0c2"))
	theme.set_color("font_disabled_color", "Button", Color("#d0cbc1"))
	theme.set_color("font_outline_color", "Button", Color("#3a2410"))
	theme.set_constant("outline_size", "Button", 3)
	theme.set_color("font_color", "OptionButton", Color("#fff7df"))
	theme.set_color("font_outline_color", "OptionButton", Color("#3a2410"))
	theme.set_constant("outline_size", "OptionButton", 3)
	theme.set_color("font_color", "ProgressBar", Color.WHITE)
	theme.set_color("font_outline_color", "ProgressBar", Color("#102030"))
	theme.set_constant("outline_size", "ProgressBar", 3)

	theme.set_font_size("font_size", "Label", 18)
	theme.set_font_size("font_size", "Button", 18)
	theme.set_font_size("font_size", "OptionButton", 18)
	theme.set_font_size("font_size", "ProgressBar", 16)

	theme.set_type_variation("DarkPanel", "PanelContainer")
	theme.set_stylebox("panel", "DarkPanel", panel_dark)
	theme.set_type_variation("BluePanel", "PanelContainer")
	theme.set_stylebox("panel", "BluePanel", panel_blue)
	return theme


static func build_font() -> Font:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(_SYSTEM_FONT_NAMES)
	font.generate_mipmaps = true
	return font


# background: 塗り / border: 枠色 / width: 枠太さ / radius: 角丸
# shadow: 影の有無 / shadow_size: 影の広がり
static func _style(
	background: Color,
	border: Color,
	width: int,
	radius: int,
	shadow: bool = false,
	shadow_size: int = 0
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = width
	style.border_width_top = width
	style.border_width_right = width
	style.border_width_bottom = width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 14.0
	style.content_margin_top = 10.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 10.0
	if shadow and shadow_size > 0:
		style.shadow_color = Color(0.0, 0.0, 0.0, 0.32)
		style.shadow_size = shadow_size
		style.shadow_offset = Vector2(0.0, maxf(float(shadow_size) * 0.45, 3.0))
	return style
