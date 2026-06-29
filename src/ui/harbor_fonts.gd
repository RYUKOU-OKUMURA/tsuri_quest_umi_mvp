extends RefCounted
## 港メニュー用フォント。
# 水中ファイト用のドット寄り設定とは分け、港の小さなUI文字を滑らかに描画する。

const REGULAR_PATH := "res://assets/fonts/MPLUS1p-Regular.ttf"
const BOLD_PATH := "res://assets/fonts/MPLUS1p-ExtraBold.ttf"

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
	var loaded := load(path) as FontFile
	if loaded == null:
		return null
	var font := loaded.duplicate(true) as FontFile
	if font == null:
		return null
	font.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	font.hinting = TextServer.HINTING_LIGHT
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_ONE_QUARTER
	font.generate_mipmaps = true
	return font
