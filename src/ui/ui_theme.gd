extends RefCounted
## JRPG ウィンドウスキン テーマ。
#  - パネル/ボタンは UITextures が procedural 生成した 9スライス装飾枠（StyleBoxTexture）。
#  - フォントは res://assets/fonts/ の FontFile を NEAREST(アンチエイリアスOFF) で読み込み、
#    なければ macOS システムゴシックにフォールバック。
#  - 色は Palette（src/ui/palette.gd）へ一元化。
const PIXEL_FONT_PATH := "res://assets/fonts/MPLUS1p-Regular.ttf"
# レトロピクセル風にするためアンチエイリアスOFF。漢字の可読性を優先したい場合は GRAY に変更。
const PIXEL_FONT_ANTIALIASING := TextServer.FONT_ANTIALIASING_NONE

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

	# 9スライス ウィンドウスキン
	var panel := _tex(UITextures.get_skin("parchment"))
	var dark := _tex(UITextures.get_skin("dark"))
	var blue := _tex(UITextures.get_skin("blue"))
	var dialog := _tex(UITextures.get_skin("dialog"))

	var btn_n := _tex(UITextures.get_skin("button_normal"), 8, 4)
	var btn_h := _tex(UITextures.get_skin("button_hover"), 8, 4)
	var btn_p := _tex(UITextures.get_skin("button_pressed"), 8, 4)
	var btn_d := _tex(UITextures.get_skin("button_normal"), 8, 4)
	var btn_gold := _tex(UITextures.get_skin("button_gold"), 8, 4)

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
	theme.set_stylebox("focus", "ItemList", UITextures.flat_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0))
	theme.set_color("font_color", "ItemList", Palette.TEXT_DARK)
	theme.set_color("font_selected_color", "ItemList", Palette.TEXT_BONE)
	theme.set_color("font_hovered_color", "ItemList", Palette.TEXT_DARK)
	theme.set_color("guide_color", "ItemList", Color(0, 0, 0, 0))
	theme.set_constant("vseparation", "ItemList", 6)
	theme.set_constant("hseparation", "ItemList", 10)

	# 入力欄
	var input := UITextures.flat_style(Color("#fff8e8"), Palette.WOOD_DARK, 2, 6)
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
	theme.set_color("font_color", "Label", Palette.TEXT_DARK)
	theme.set_color("font_outline_color", "Label", Palette.TEXT_OUTLINE_DARK)
	theme.set_constant("outline_size", "Label", 0)
	theme.set_color("font_color", "Button", Palette.TEXT_BONE)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", Palette.GOLD_BRIGHT)
	theme.set_color("font_disabled_color", "Button", Color("#d0cbc1"))
	theme.set_color("font_outline_color", "Button", Palette.TEXT_OUTLINE_LIGHT)
	theme.set_constant("outline_size", "Button", 3)
	theme.set_color("font_color", "OptionButton", Palette.TEXT_BONE)
	theme.set_color("font_hover_color", "OptionButton", Color.WHITE)
	theme.set_color("font_outline_color", "OptionButton", Palette.TEXT_OUTLINE_LIGHT)
	theme.set_constant("outline_size", "OptionButton", 3)
	theme.set_color("font_color", "ItemList", Palette.TEXT_DARK)
	theme.set_color("font_outline_color", "ItemList", Palette.TEXT_OUTLINE_DARK)
	theme.set_constant("outline_size", "ItemList", 0)
	theme.set_color("font_color", "ProgressBar", Color.WHITE)
	theme.set_color("font_outline_color", "ProgressBar", Palette.TEXT_OUTLINE_DARK)
	theme.set_constant("outline_size", "ProgressBar", 3)

	theme.set_font_size("font_size", "Label", 18)
	theme.set_font_size("font_size", "Button", 18)
	theme.set_font_size("font_size", "OptionButton", 18)
	theme.set_font_size("font_size", "ItemList", 18)
	theme.set_font_size("font_size", "ProgressBar", 16)
	return theme


static func build_font() -> Font:
	if ResourceLoader.exists(PIXEL_FONT_PATH):
		var loaded := load(PIXEL_FONT_PATH)
		var f := loaded as FontFile
		if f != null:
			f.antialiasing = PIXEL_FONT_ANTIALIASING
			f.hinting = TextServer.HINTING_NONE
			f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
			f.generate_mipmaps = true
			return f
	return _system_font()


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
