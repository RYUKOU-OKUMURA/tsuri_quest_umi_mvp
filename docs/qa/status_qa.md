# ステータス画面 QA判断ログ

最終更新: 2026-07-14 / 状態: R5-Aプレイヤーhero freeze
参照画像: reference/08_status_screen_mockup.png
QA更新コマンド: ./tools/status_visual_qa.sh

## 1. freeze値（正本）

現在有効な値だけを書く。値を更新したら該当行を**上書き**する（追記して古い行を残さない）。

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 現在難易度 | ヘッダー左クラスタに「難易度: <name>」を1回 | `src/ui/status_screen.gd` | `PlayerProgress.difficulty()["name"]`の実値。重複情報なし |
| ヘッダー外形 | 現行矩形を維持 | `src/ui/status_screen.gd` | `PlayerStatusBar`・3ペイン・フッターを不動 |
| 中央プレイヤーhero | `StatusSummaryBadge`内の海釣り人円形portrait。badge外形約x419–529 / y184–298、既存portrait slotを維持 | `src/ui/status_screen.gd` | 文字/UI/魚なしのscreen-local authored素材。「記録」はruntime描画を維持 |

## 2. 不採用・再試行禁止リスト

| 案 | 却下理由 | 判断日 |
|---|---|---|

## 3. 微調整カウンタ

| パラメータ | 回数 | 直近の変更内容 | 状態 |
|---|---|---|---|
| 難易度表示余白 | 0 | 初回採用値でnormal/hardとも収まり | freeze |
| 中央hero矩形/円形crop | 0 | 既存slotのまま初回候補を採用 | freeze |

## 4. 暫定判定・再検証TODO

なし。

## 5. 現在の残ギャップ

- R5-B候補: 参照に対する全画面の木・真鍮・紙のauthored枠質感差。本R5-Aとは独立concernのため未着手。

## 6. E7状態契約（freeze）

- 局所uplift: E7の現在難易度名をヘッダー左クラスタ内に小さく1回だけ表示する。
- 存在する領域: `PlayerProgress.difficulty()["name"]` を使う「難易度: <名>」。存在しない領域: 倍率詳細、ID、変更操作、他ペインへの重複表示。
- 動かす値: 左ヘッダー内の副文言領域の分割のみ。不動freeze: ヘッダー外形、`PlayerStatusBar`、3ペイン、フッター、素材、配色、フォント。
- 状態契約: normal / hardの実値が同一アンカーに表示され、見切れ・省略・重なりがないこと。

## 7. 判断ログ（直近パスのみ）

2026-07-14 R5-A局所upliftを採用。

- 変えたもの: 中央「釣果サマリー」上部medallionの最近魚アイコンを、OpenAI built-in image generationで生成した海釣り人portraitへ置換。source→256×256円形alpha製品PNGは`tools/process_status_r5a_assets.py`で決定的に加工する。
- 変えていないもの: `PlayerStatusBar`、難易度1回表示、3ペイン/hero badge外形、runtime「記録」、右側4指標、最近魚4枚、称号、図鑑率、クーラー/装備/料理ログ、フッター3導線、難易度・保存ロジック。
- 状態契約: normal / hardは同一seed・同一構成。差は難易度名と安全域の実値だけ。両状態で人物の頭部、竿、海が円形内に読み取れ、P1ゼロ。
- 採否理由: 原寸beforeより「誰の釣果か」が明確で、320×180のbefore / after / reference比較でも魚アイコンから釣り人identityへ変わったことを判別できる。gray比較でも中央heroの人物シルエットを維持する。
- 証拠: `2026-07-14_r5a_before_{normal,hard}.png`、`after_{normal,hard}.png`、`full_{normal,hard}_compare.png`、`thumbnail_compare.png`、`gray_compare.png`、`asset_contact.png`、`reference.png`（すべて`docs/qa/evidence/status/`）。
- 回帰確認: before/afterの描画差はhero矩形内に集中。hero外の散発差は`HarborBackdrop`の時刻依存描画でnormal 40px / hard 10pxのみ。コード上のanchor/offset変更は0件で、smokeが既存釣果値・導線・normal/hard実値を維持する。
- 固定条件: portrait slotとbadge外形を再調整しない。次のR5は全画面authored枠質感を別concernとして扱い、本hero素材の微調整へ戻らない。
