extends RefCounted
## 水中ファイト看板画面用フォント。
# 通常テーマのフォントと分けて、参照画像に近い太い見出し/数値を安定して使う。

const REGULAR_PATH := "res://assets/fonts/MPLUS1p-Regular.ttf"
const BOLD_PATH := "res://assets/fonts/MPLUS1p-Bold.ttf"
const ANTIALIASING := TextServer.FONT_ANTIALIASING_GRAY

static var _regular: FontFile
static var _bold: FontFile


static func regular(fallback: Font) -> Font:
	if _regular == null:
		_regular = _load_font(REGULAR_PATH)
	return _regular if _regular != null else fallback


static func bold(fallback: Font) -> Font:
	if _bold == null:
		_bold = _load_font(BOLD_PATH)
	return _bold if _bold != null else fallback


static func _load_font(path: String) -> FontFile:
	if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
		return null
	var loaded := load(path)
	var font := loaded as FontFile
	if font == null:
		return null
	font.antialiasing = ANTIALIASING
	font.hinting = TextServer.HINTING_NONE
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	font.generate_mipmaps = true
	return font
