class_name Palette
extends RefCounted
## 統一カラーパレット（docs/10 §2-D）。全UI/ビューの色はこの定数を参照し、
## 散在する hex リテラルを一元化する。将来のパレット差し替えはここだけで済む。

# --- 海・空（明るい海） ---
const SKY_TOP := Color("#9bd6ee")
const SKY_HORIZON := Color("#c9ecf6")
const SEA_SHALLOW := Color("#2f9bd6")
const SEA_MID := Color("#1f6fa8")
const SEA_DEEP := Color("#0e3f63")
const FOAM := Color("#eaf6ff")

# --- 砂・木・羊皮紙（暖色） ---
const SAND := Color("#d8c089")
const SAND_DEEP := Color("#b69a5e")
const WOOD := Color("#8a5428")
const WOOD_HOVER := Color("#a66831")
const WOOD_PRESSED := Color("#60381f")
const WOOD_DARK := Color("#5e3a1c")
const PARCHMENT := Color("#f3e8cd")
const PARCHMENT_DEEP := Color("#e7d6ad")

# --- パネル ---
const DARK_PANEL := Color("#13283f")
const DARK_PANEL_DEEP := Color("#0a1622")
const BLUE_PANEL := Color("#173b61")

# --- 金 ---
const GOLD := Color("#e1bd72")
const GOLD_BRIGHT := Color("#ffe7a8")
const GOLD_DEEP := Color("#b98a3e")

# --- ゲージ（意味色） ---
const GAUGE_GREEN := Color("#3cbf78")
const GAUGE_GREEN_HI := Color("#9ff0c0")
const GAUGE_AMBER := Color("#e0a02e")
const GAUGE_AMBER_HI := Color("#ffd277")
const GAUGE_RED := Color("#d94b4b")
const GAUGE_RED_HI := Color("#ff9a82")
const GAUGE_CYAN := Color("#2f7fd0")
const GAUGE_CYAN_HI := Color("#88bdf2")

# --- テキスト ---
const TEXT_DARK := Color("#203042")
const TEXT_BODY := Color("#31485d")
const TEXT_BONE := Color("#fff1c7")
const TEXT_OUTLINE_DARK := Color("#0a1622")
const TEXT_OUTLINE_LIGHT := Color("#3a2410")

const SHADOW := Color(0.0, 0.0, 0.0, 0.34)

## ゲージの意味色を状態で取得（安全域=緑, 警戒=琥珀, 危険=赤）。
static func gauge_pair(level: String) -> Dictionary:
	match level:
		"amber":
			return {"from": GAUGE_AMBER, "to": GAUGE_AMBER_HI}
		"red":
			return {"from": GAUGE_RED, "to": GAUGE_RED_HI}
		_:
			return {"from": GAUGE_GREEN, "to": GAUGE_GREEN_HI}
