extends RefCounted
## JRPG ウィンドウスキン テーマ。
#  - 通常UIは細い縁の StyleBoxFlat を使い、生成9スライス由来の格子状破綻を避ける。
#  - 本番ウィンドウ素材が用意できたら、ここを StyleBoxTexture に差し替える。
#  - フォントは LINE Seed JP を共通ローダー経由で読み込み、
#    通常UIではアンチエイリアスON・軽いヒンティングで描画する。
#  - 色は Palette（src/ui/palette.gd）へ一元化。
const GameFontsScript = preload("res://src/ui/game_fonts.gd")

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
	var default_font := theme.default_font
	var bold_font := GameFontsScript.bold(default_font)

	var panel := _panel_style(Palette.PARCHMENT, Palette.WOOD_DARK, Palette.GOLD, false)
	var dark := _panel_style(Palette.DARK_PANEL, Palette.THEME_DARK_PANEL_BORDER, Palette.THEME_PANEL_INNER_GOLD, true)
	var blue := _panel_style(Palette.BLUE_PANEL, Palette.THEME_BLUE_PANEL_BORDER, Palette.THEME_PANEL_INNER_GOLD, true)
	var dialog := _panel_style(Palette.THEME_DIALOG_FILL, Palette.GOLD_DEEP, Palette.GOLD_BRIGHT, true)

	var btn_n := _button_style(Palette.WOOD, Palette.WOOD_DARK, Palette.GOLD)
	var btn_h := _button_style(Palette.WOOD_HOVER, Palette.WOOD_DARK, Palette.GOLD_BRIGHT)
	var btn_p := _button_style(Palette.WOOD_PRESSED, Palette.THEME_BUTTON_PRESSED_BORDER, Palette.GOLD_DEEP)
	var btn_d := _button_style(Palette.THEME_BUTTON_DISABLED_FILL, Palette.THEME_BUTTON_DISABLED_BORDER, Palette.THEME_BUTTON_DISABLED_INNER)
	var btn_gold := _button_style(Palette.THEME_GOLD_BUTTON_FILL, Palette.THEME_GOLD_BUTTON_BORDER, Palette.GOLD_BRIGHT)

	theme.set_stylebox("panel", "PanelContainer", panel)
	theme.set_stylebox("panel", "Panel", panel)
	theme.set_stylebox("panel", "PopupPanel", dialog)
	theme.set_stylebox("normal", "Button", btn_n)
	theme.set_stylebox("hover", "Button", btn_h)
	theme.set_stylebox("pressed", "Button", btn_p)
	theme.set_stylebox("disabled", "Button", btn_d)
	theme.set_stylebox("focus", "Button", btn_h)
	theme.set_stylebox("normal", "OptionButton", btn_n)
	theme.set_stylebox("hover", "OptionButton", btn_h)
	theme.set_stylebox("pressed", "OptionButton", btn_p)
	theme.set_stylebox("disabled", "OptionButton", btn_d)
	theme.set_stylebox("focus", "OptionButton", btn_h)

	# 型バリエーション（DarkPanel/BluePanel は既存コードが参照）。JRPG* を追加。
	theme.set_type_variation("DarkPanel", "PanelContainer")
	theme.set_stylebox("panel", "DarkPanel", dark)
	theme.set_type_variation("BluePanel", "PanelContainer")
	theme.set_stylebox("panel", "BluePanel", blue)
	theme.set_type_variation("JRPGPanel", "PanelContainer")
	theme.set_stylebox("panel", "JRPGPanel", panel)
	theme.set_type_variation("JRPGHeader", "PanelContainer")
	theme.set_stylebox("panel", "JRPGHeader", dark)
	theme.set_type_variation("JRPGDialog", "PanelContainer")
	theme.set_stylebox("panel", "JRPGDialog", dialog)
	theme.set_type_variation("GoldButton", "Button")
	theme.set_stylebox("normal", "GoldButton", btn_gold)
	theme.set_stylebox("hover", "GoldButton", btn_gold)
	theme.set_stylebox("pressed", "GoldButton", btn_p)
	theme.set_stylebox("focus", "GoldButton", btn_gold)
	theme.set_stylebox("disabled", "GoldButton", btn_d)

	# ItemList（市場/釣具店/調理で使用）。デフォルト灰をウィンドウスキンに統一。
	theme.set_stylebox("panel", "ItemList", panel)
	var selected := UITextures.flat_style(Palette.BLUE_PANEL, Palette.GOLD, 1, 4)
	theme.set_stylebox("selected", "ItemList", selected)
	theme.set_stylebox("selected_focus", "ItemList", selected)
	theme.set_stylebox("cursor", "ItemList", selected)
	theme.set_stylebox("hover", "ItemList", UITextures.flat_style(Palette.PARCHMENT_DEEP, Palette.WOOD_DARK, 1, 4))
	theme.set_stylebox("focus", "ItemList", UITextures.flat_style(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0))
	theme.set_color("font_color", "ItemList", Palette.TEXT_DARK)
	theme.set_color("font_selected_color", "ItemList", Palette.TEXT_BONE)
	theme.set_color("font_hovered_color", "ItemList", Palette.TEXT_DARK)
	theme.set_color("guide_color", "ItemList", Color.TRANSPARENT)
	theme.set_constant("vseparation", "ItemList", 6)
	theme.set_constant("hseparation", "ItemList", 10)

	# 入力欄
	var input := UITextures.flat_style(Palette.THEME_INPUT_FILL, Palette.WOOD_DARK, 2, 6)
	theme.set_stylebox("normal", "LineEdit", input)
	theme.set_stylebox("focus", "LineEdit", input)
	theme.set_stylebox("normal", "TextEdit", input)

	# ProgressBar（調理EXP等。最終的には GaugeBar に差し替え）
	theme.set_stylebox("background", "ProgressBar", UITextures.flat_style(Palette.DARK_PANEL_DEEP, Palette.WOOD_DARK, 2, 6, false, 0))
	theme.set_stylebox("fill", "ProgressBar", UITextures.flat_style(Palette.GAUGE_GREEN, Palette.GAUGE_GREEN_HI, 1, 6, false, 0))

	# ダイアログ
	theme.set_stylebox("panel", "AcceptDialog", dialog)
	theme.set_stylebox("panel", "ConfirmationDialog", dialog)
	theme.set_stylebox("panel", "AcceptDialog", dialog)

	# 色・アウトライン・サイズ
	theme.set_font("font", "Label", default_font)
	theme.set_font("font", "Button", bold_font)
	theme.set_font("font", "OptionButton", bold_font)
	theme.set_font("font", "ItemList", default_font)
	theme.set_font("font", "ProgressBar", bold_font)
	theme.set_color("font_color", "Label", Palette.TEXT_DARK)
	theme.set_color("font_outline_color", "Label", Palette.TEXT_OUTLINE_DARK)
	theme.set_constant("outline_size", "Label", 0)
	theme.set_color("font_color", "Button", Palette.TEXT_BONE)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", Palette.GOLD_BRIGHT)
	theme.set_color("font_disabled_color", "Button", Palette.THEME_BUTTON_DISABLED_TEXT)
	theme.set_color("font_outline_color", "Button", Palette.TEXT_OUTLINE_LIGHT)
	theme.set_constant("outline_size", "Button", 2)
	theme.set_color("font_color", "OptionButton", Palette.TEXT_BONE)
	theme.set_color("font_hover_color", "OptionButton", Color.WHITE)
	theme.set_color("font_outline_color", "OptionButton", Palette.TEXT_OUTLINE_LIGHT)
	theme.set_constant("outline_size", "OptionButton", 2)
	theme.set_color("font_color", "ItemList", Palette.TEXT_DARK)
	theme.set_color("font_outline_color", "ItemList", Palette.TEXT_OUTLINE_DARK)
	theme.set_constant("outline_size", "ItemList", 0)
	theme.set_color("font_color", "ProgressBar", Color.WHITE)
	theme.set_color("font_outline_color", "ProgressBar", Palette.TEXT_OUTLINE_DARK)
	theme.set_constant("outline_size", "ProgressBar", 2)

	theme.set_font_size("font_size", "Label", 18)
	theme.set_font_size("font_size", "Button", 18)
	theme.set_font_size("font_size", "OptionButton", 18)
	theme.set_font_size("font_size", "ItemList", 18)
	theme.set_font_size("font_size", "ProgressBar", 16)
	return theme


static func build_font() -> Font:
	return GameFontsScript.regular(_system_font())


static func _system_font() -> SystemFont:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(_SYSTEM_FONT_NAMES)
	font.generate_mipmaps = true
	return font


# 9スライス StyleBoxTexture。margin=枠幅, shadow_expand=焼き込み影の描画拡張。
static func _tex(tex: Texture2D, margin: int = 10, shadow_expand: int = 4) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = margin
	sb.texture_margin_top = margin
	sb.texture_margin_right = margin
	sb.texture_margin_bottom = margin
	sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	sb.expand_margin_left = shadow_expand
	sb.expand_margin_top = shadow_expand
	sb.expand_margin_right = shadow_expand
	sb.expand_margin_bottom = shadow_expand
	sb.content_margin_left = 14.0
	sb.content_margin_top = 10.0
	sb.content_margin_right = 14.0
	sb.content_margin_bottom = 10.0
	# texture_filtering は設定しない（プロジェクト既定 NEAREST でチャンキーピクセル枠になる）
	return sb


static func _panel_style(fill: Color, outer: Color, inner: Color, dark_text: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = outer.lerp(inner, 0.22)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(2)
	sb.content_margin_left = 14.0
	sb.content_margin_top = 10.0
	sb.content_margin_right = 14.0
	sb.content_margin_bottom = 10.0
	sb.shadow_color = Palette.THEME_PANEL_SHADOW
	sb.shadow_size = 5
	sb.shadow_offset = Vector2(0.0, 3.0)
	sb.anti_aliasing = false
	if dark_text:
		sb.bg_color = fill.lightened(0.02)
	return sb


static func _button_style(fill: Color, outer: Color, inner: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = outer.lerp(inner, 0.45)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 14.0
	sb.content_margin_top = 8.0
	sb.content_margin_right = 14.0
	sb.content_margin_bottom = 8.0
	sb.shadow_color = Palette.THEME_BUTTON_SHADOW
	sb.shadow_size = 3
	sb.shadow_offset = Vector2(0.0, 2.0)
	sb.anti_aliasing = false
	return sb
