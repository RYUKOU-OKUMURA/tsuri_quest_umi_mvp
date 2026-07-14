# ステータス画面 QA判断ログ

最終更新: 2026-07-14 / 状態: R5-Aプレイヤーhero作業中
参照画像: reference/08_status_screen_mockup.png
QA更新コマンド: ./tools/status_visual_qa.sh

## 1. freeze値（正本）

現在有効な値だけを書く。値を更新したら該当行を**上書き**する（追記して古い行を残さない）。

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 現在難易度 | ヘッダー左クラスタに「難易度: <name>」を1回 | `src/ui/status_screen.gd` | `PlayerProgress.difficulty()["name"]`の実値。重複情報なし |
| ヘッダー外形 | 現行矩形を維持 | `src/ui/status_screen.gd` | `PlayerStatusBar`・3ペイン・フッターを不動 |

## 2. 不採用・再試行禁止リスト

| 案 | 却下理由 | 判断日 |
|---|---|---|

## 3. 微調整カウンタ

| パラメータ | 回数 | 直近の変更内容 | 状態 |
|---|---|---|---|
| 難易度表示余白 | 0 | 初回採用値でnormal/hardとも収まり | freeze |

## 4. 暫定判定・再検証TODO

なし。

## 5. 現在の残ギャップ

- R5: ステータス画面全体の参照upliftは未着手。本パスは共有 `GaugeBar` のR1表示同値移行のみ。

## 6. E7状態契約（freeze）

- 局所uplift: E7の現在難易度名をヘッダー左クラスタ内に小さく1回だけ表示する。
- 存在する領域: `PlayerProgress.difficulty()["name"]` を使う「難易度: <名>」。存在しない領域: 倍率詳細、ID、変更操作、他ペインへの重複表示。
- 動かす値: 左ヘッダー内の副文言領域の分割のみ。不動freeze: ヘッダー外形、`PlayerStatusBar`、3ペイン、フッター、素材、配色、フォント。
- 状態契約: normal / hardの実値が同一アンカーに表示され、見切れ・省略・重なりがないこと。

## 6.1 R5-Aフェーズスコープ宣言（作業中）

- 変更仮説: 中央上部の最近魚アイコンを海辺で釣る人物portraitへ置換すると、「誰の釣果か」が縮小表示でも読め、参照のプレイヤーidentityへ近づく。
- 採否条件: normal / hardの全画面でbeforeへ明確に勝ち、after / referenceの320×180比較でも人物・竿・海が読めること。
- 動かす値: `StatusSummaryBadge` 約x419–529 / y184–298内のportrait textureだけ。円形crop成立に必要な場合のみ既存内側slotを最小調整する。
- 不動freeze: `PlayerStatusBar`、難易度名1回、3ペイン外形、フッター/戻る、魚図鑑/料理ボタン、badgeのruntime「記録」、右側4指標、最近魚、称号、図鑑率、クーラー/竿/料理ログ、全ロジック。
- 差分Top3: Top1=魚アイコンで人物identity不在（P2、本パス対象）。Top2=全画面authored枠質感（P2、対象外）。Top3=参照と現行の情報構成差（現契約上P3、対象外）。

| 状態 | 固定seed/データ | 表示/非表示 | 固定アンカー | 可変領域 | evidence出力 | smoke契約 |
|---|---|---|---|---|---|---|
| normal | preview既定seed、難易度normal | 全要素表示 | 3ペイン・header・footer・badge外形 | なし | `2026-07-14_r5a_after_normal.png` | portrait存在、難易度1回、既存釣果/導線 |
| hard | normalと同じseed、難易度hard | 全要素表示 | normalと同一 | なし | `2026-07-14_r5a_after_hard.png` | portrait存在、難易度1回、安全域実値、既存釣果/導線 |

## 7. 判断ログ（直近パスのみ）

2026-07-12 E7局所upliftを採用。normal / hardの実値をGodot 4.7・1280x720で撮影し、ヘッダー内に難易度名が1回だけ表示され、見切れ・省略・重なりなし。ヘッダー外形、`PlayerStatusBar`、3ペイン、フッターは不動。証拠は`docs/qa/evidence/status/2026-07-12_e7_normal.png`、`2026-07-12_e7_hard.png`および各compare。

2026-07-05: `shared UI theme palette R1 pass` 完了。ステータス画面にも適用される共通テーマ色をPalette用途名へ移行した。

- 選定理由: `src/ui/ui_theme.gd` はステータス/釣具店/市場などで共通利用されるが、パネル/ボタン/入力欄/影/無効文字色に直書き色が残っていたため。
- 変えたもの: `src/ui/ui_theme.gd` のテーマ色参照。`src/ui/palette.gd` へ `Palette.THEME_*` 定数を追加。
- 変えていないもの: ステータス画面のレイアウト、表示文言、所持品/料理リスト、ボタン配置、背景、日本語PNG焼き込み。
- Palette: 新規 `Palette.THEME_*` を追加。理由は共通テーマの表示色責務をPaletteへ集約するため。
- 証拠画像: `docs/qa/evidence/status/2026-07-05_ui_theme_palette_compare.png`, `docs/qa/evidence/theme/2026-07-05_ui_theme_palette_preview.png`
- 判定: 実スクショでステータス画面のパネル/ボタン/ゲージに未表示・文字重なり・見切れなし。これは参照upliftではなくR1表示同値移行なので、cmp一致は完了条件にしていない。
- 検証: `./tools/status_visual_qa.sh`、`status_smoke.tscn`、`./tools/tackle_shop_visual_qa.sh`、`./tools/market_visual_qa.sh`、`tackle_shop_smoke.tscn`、`market_smoke.tscn`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。headless `theme_preview.tscn` はViewport texture取得不可で失敗したため通常起動で証拠取得。
- 固定条件: 共通テーマ色は `Palette.THEME_*` として扱い、`src/ui/ui_theme.gd` へ新規直書き色を戻さない。

2026-07-05: `shared GaugeBar palette R1 pass` 完了。ステータス画面で使う共有ゲージの描画色をPalette用途名へ移行した。

- 選定理由: `GaugeBar` はステータス画面の食経験値/図鑑コンプリート率と調理フローで共有されるが、既定色と描画色に直書き `Color(...)` が残っていたため。
- 変えたもの: `src/ui/components/gauge_bar.gd` の既定グラデーション、トラック、影、ゴースト、ハイライト、ダメージ点滅、危険域グロー、数値文字色。`src/ui/palette.gd` へ `Palette.GAUGE_*` 定数を追加。
- 変えていないもの: ステータス画面のレイアウト、表示文言、所持品/料理リスト、ボタン、背景、日本語PNG焼き込み。
- Palette: 新規 `Palette.GAUGE_TRACK` / `GAUGE_TRACK_BORDER` / `GAUGE_SHADOW_CLEAR` / `GAUGE_SHADOW` / `GAUGE_GHOST` / `GAUGE_HIGHLIGHT` / `GAUGE_DAMAGE_FLASH` / `GAUGE_CRITICAL_GLOW` / `GAUGE_VALUE_OUTLINE` / `GAUGE_VALUE_TEXT` を追加。理由は共有ゲージの描画色責務をPaletteへ集約するため。
- 証拠画像: `docs/qa/evidence/status/2026-07-05_gauge_bar_palette_status.png`, `docs/qa/evidence/status/2026-07-05_gauge_bar_palette_compare.png`
- 判定: 実スクショで食経験値ゲージと図鑑コンプリート率ゲージに未表示・文字重なり・見切れなし。これは参照upliftではなくR1表示同値移行なので、cmp一致は完了条件にしていない。
- 検証: `./tools/status_visual_qa.sh`、`status_smoke.tscn`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`validate_project.sh` の ObjectDB/resource 警告はベースライン既知。
- 固定条件: 共有ゲージの描画色は `Palette.GAUGE_*` として扱い、`src/ui/components/gauge_bar.gd` へ新規 `Color(...)` を戻さない。
