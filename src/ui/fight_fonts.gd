extends RefCounted
## ドット感を狙う特殊用途のフォント。
# 通常UIは game_fonts.gd を使う。ここはアンチエイリアスOFFが必要な演出だけに限定する。

const REGULAR_PATH := "res://assets/fonts/line_seed/LINESeedJP_A_TTF_Rg.ttf"
const BOLD_PATH := "res://assets/fonts/line_seed/LINESeedJP_A_TTF_Bd.ttf"
const EXTRA_BOLD_PATH := "res://assets/fonts/line_seed/LINESeedJP_A_TTF_Eb.ttf"
const ANTIALIASING := TextServer.FONT_ANTIALIASING_NONE

static var _regular: FontFile
static var _bold: FontFile
static var _extra_bold: FontFile


static func regular(fallback: Font) -> Font:
	if _regular == null:
		_regular = _load_font(REGULAR_PATH)
	return _regular if _regular != null else fallback


static func bold(fallback: Font) -> Font:
	if _bold == null:
		_bold = _load_font(BOLD_PATH)
	return _bold if _bold != null else fallback


static func extra_bold(fallback: Font) -> Font:
	if _extra_bold == null:
		_extra_bold = _load_font(EXTRA_BOLD_PATH)
	return _extra_bold if _extra_bold != null else fallback


static func _load_font(path: String) -> FontFile:
	if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
		return null
	var loaded := load(path) as FontFile
	if loaded == null:
		return null
	var font := loaded.duplicate(true) as FontFile
	if font == null:
		return null
	font.antialiasing = ANTIALIASING
	font.hinting = TextServer.HINTING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	font.generate_mipmaps = true
	return font
