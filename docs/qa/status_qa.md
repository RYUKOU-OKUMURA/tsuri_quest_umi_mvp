# ステータス画面 QA判断ログ

最終更新: 2026-07-05 / 状態: 共有GaugeBar R1確認済み
参照画像: reference/08_status_screen_mockup.png
QA更新コマンド: ./tools/status_visual_qa.sh

## 1. freeze値（正本）

現在有効な値だけを書く。値を更新したら該当行を**上書き**する（追記して古い行を残さない）。

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|

## 2. 不採用・再試行禁止リスト

| 案 | 却下理由 | 判断日 |
|---|---|---|

## 3. 微調整カウンタ

| パラメータ | 回数 | 直近の変更内容 | 状態 |
|---|---|---|---|

## 4. 暫定判定・再検証TODO

なし。

## 5. 現在の残ギャップ

- R5: ステータス画面全体の参照upliftは未着手。本パスは共有 `GaugeBar` のR1表示同値移行のみ。

## 6. フェーズスコープ宣言（作業中のみ）

なし。

## 7. 判断ログ（直近パスのみ）

2026-07-05: `shared GaugeBar palette R1 pass` 完了。ステータス画面で使う共有ゲージの描画色をPalette用途名へ移行した。

- 選定理由: `GaugeBar` はステータス画面の食経験値/図鑑コンプリート率と調理フローで共有されるが、既定色と描画色に直書き `Color(...)` が残っていたため。
- 変えたもの: `src/ui/components/gauge_bar.gd` の既定グラデーション、トラック、影、ゴースト、ハイライト、ダメージ点滅、危険域グロー、数値文字色。`src/ui/palette.gd` へ `Palette.GAUGE_*` 定数を追加。
- 変えていないもの: ステータス画面のレイアウト、表示文言、所持品/料理リスト、ボタン、背景、日本語PNG焼き込み。
- Palette: 新規 `Palette.GAUGE_TRACK` / `GAUGE_TRACK_BORDER` / `GAUGE_SHADOW_CLEAR` / `GAUGE_SHADOW` / `GAUGE_GHOST` / `GAUGE_HIGHLIGHT` / `GAUGE_DAMAGE_FLASH` / `GAUGE_CRITICAL_GLOW` / `GAUGE_VALUE_OUTLINE` / `GAUGE_VALUE_TEXT` を追加。理由は共有ゲージの描画色責務をPaletteへ集約するため。
- 証拠画像: `docs/qa/evidence/status/2026-07-05_gauge_bar_palette_status.png`, `docs/qa/evidence/status/2026-07-05_gauge_bar_palette_compare.png`
- 判定: 実スクショで食経験値ゲージと図鑑コンプリート率ゲージに未表示・文字重なり・見切れなし。これは参照upliftではなくR1表示同値移行なので、cmp一致は完了条件にしていない。
- 検証: `./tools/status_visual_qa.sh`、`status_smoke.tscn`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`validate_project.sh` の ObjectDB/resource 警告はベースライン既知。
- 固定条件: 共有ゲージの描画色は `Palette.GAUGE_*` として扱い、`src/ui/components/gauge_bar.gd` へ新規 `Color(...)` を戻さない。
