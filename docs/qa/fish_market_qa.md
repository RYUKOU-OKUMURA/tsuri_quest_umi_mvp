# 魚市場 QA判断ログ

最終更新: 2026-07-05 / 状態: v1 freeze / RarityStyles共通化済み / R1 Palette確認済み
参照画像: reference/10_fish_market_mockup.png
QA更新コマンド: ./tools/market_visual_qa.sh（通常選択・売却確認・売却完了・空状態）

## 1. freeze値（正本）

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 論理画面サイズ | 1280x720 | `MarketScreen.FishMarketDesignCanvas` | 既存P2釣具店と同じ固定キャンバス運用 |
| 一覧表示行数 | 7行 | 左一覧 | 参照画像の密度に合わせる |
| 上部ステータス | `PlayerStatusBar` | 画面上部 | docs/19の共通キット方針・情報重複禁止に合わせる |
| 主操作 | `まとめて売る` | 右下カート | 1匹売却も数量指定に統合 |
| 売却結果 | 同画面内メッセージ | 右下カート/結果表示 | 別画面を作らない |
| 売却確認オーバーレイ | `CONFIRM_OVERLAY_Z = 100` / パネル不透明 | `MarketConfirmOverlay` | 背景側の詳細ラベル・数量ボタン・単価表示が確認パネルの上に描画されるP1を防ぐ |

## 2. 不採用・再試行禁止リスト

| 案 | 却下理由 | 判断日 |
|---|---|---|
| 旧 `ItemList` にボタンを足す | 完成ゴール画像の領域構成と一致せず、正式UI化にならない | 2026-07-04 |
| 参照画像をゲーム内backplateとして直接使用 | 魚・記号・疑似文字が焼き込まれており、runtime状態表示の方針に反する | 2026-07-04 |
| 売却後専用の別画面 | 1画面内の状態差し替えで足り、遷移が重くなる | 2026-07-04 |
| MVPで調理費用を導入 | 序盤難度が上がるため、難易度設定フェーズへ保留 | 2026-07-04 |

## 3. 微調整カウンタ

| パラメータ | 回数 | 直近の変更内容 | 状態 |
|---|---|---|---|
| 空状態表示 | 1 | 左一覧にruntime空状態パネルを追加し、backplateの空スロットを操作残骸に見せない | 採用 |
| backplate質感 | 3 | 市場背景、紙面粒状感、濃紺パネル装飾、査定トレーの氷・木箱・葉を強化。斜線・粒状ノイズを3回目で抑制 | 採用 |
| 行パーツ品質 | 1 | 名前・所持数・単価・数量をruntimeフィールドパネル化。紙面上の白アウトライン文字とコイン/単価重なりを解消 | 採用 |
| サッパ素材 | 1 | サバと混同しやすい見た目だったため、小型・淡色のサッパとして再生成 | 採用 |
| 売却確認モーダルP1 | 1 | `MarketConfirmOverlay` を通常UIより前面化し、確認本文枠・警告文を省略なしで読める長さへ調整 | 採用 |

## 4. v1判定

| 状態 | 判定 | 証拠 |
|---|---|---|
| 通常選択 | 採用 | `docs/qa/evidence/fish_market/2026-07-04_market_row_polish_compare.png` |
| 売却確認 | 採用 | `docs/qa/evidence/fish_market/2026-07-05_market_confirm_layer_fix_compare.png` |
| 売却完了 | 採用 | `docs/qa/evidence/fish_market/2026-07-04_market_sold_uplift_compare.png` |
| 空状態 | 採用 | `docs/qa/evidence/fish_market/2026-07-04_market_row_polish_empty_compare.png` |

通常選択・売却確認・売却完了・空状態の4状態で、参照画像の「左にクーラーボックス一覧、右上に査定、右下に売却カート」という構成を維持できている。魚名・所持数・単価・数量・合計・ボタン状態はruntime描画で、PNGへの日本語テキスト焼き込みはない。売却確認モーダルでは背景側の詳細ラベル・数量ボタン・単価表示が確認パネル上へ描画されず、確認文とボタンだけが読める。

## 5. 現在の残ギャップ

- 現行backplateはPIL生成の手描き風素材。参照画像のような高密度な市場背景・写真寄りの氷台は、次の一点物PNG生成フェーズで再検討する。
- 空状態はruntime空状態パネルで成立。専用空背景の追加はv2候補。

## 6. フェーズスコープ宣言（作業中のみ）

- 現在作業中のP2フェーズなし。P1修正では確認モーダルの描画レイヤー・確認本文の収まり・QAキャプチャ対象のみを動かし、論理画面サイズ、一覧7行、上部ステータス、主操作、売却仕様、一括売却API、料理費用、調理画面、魚価格バランス、共通キット全体の見た目は触っていない。

## 7. 判断ログ（直近パスのみ）

2026-07-04:
- ユーザー確認により、生成済み2枚目を完成ゴールに採用。
- P5調理費用はMVPでは保留し、P6をP5非依存で進める。
- 実装判断は `reference/10_fish_market_mockup.png` と実スクショ比較で行う。
- `tools/market_visual_qa.sh` で通常選択・売却完了・空状態を生成し、比較画像を `docs/qa/evidence/fish_market/` に保存。
- 右上説明文は長文時に省略表示が出たため、「料理素材に残すか、装備資金へ。」へ短縮して採用。
- ブラッシュアップで空状態パネルを追加し、在庫0時の左一覧が操作残骸に見えないようにした。証拠: `2026-07-04_market_empty_uplift_compare.png`。
- backplateは魚市場背景、パネル装飾、査定トレーを強化。1回目は角装飾と斜線が強すぎたため、3回目で密度を抑えた版を採用。証拠: `2026-07-04_market_select_uplift_compare.png`。
- 行内の名前・所持数・単価・数量をruntimeフィールドパネルへ載せ替えた。単価は行内では数字のみ、詳細欄では `単価 ○○ G` の完全表記を維持する。証拠: `2026-07-04_market_row_polish_compare.png`。
- `サバ` と `サッパ` はデータ上別魚。市場でサッパがサバに見えたため、`sappa` の魚素材だけ小型・淡色へ再生成し、名前自体は `サッパ` のまま維持した。

2026-07-05:
- ユーザー報告スクショで、売却確認モーダル上に背景側の魚詳細テキスト・数量ボタン・単価表示が重なって見えるP1を確認。
- 原因は確認モーダル座標ではなく、`MarketConfirmOverlay` が通常UIラベル（`z_index = 30`）より低い描画レイヤーに残っていたこと。`CONFIRM_OVERLAY_Z = 100` を追加し、確認パネルを不透明化して背景の透けも抑えた。
- `tools/market_preview.gd` と `tools/build_screen_visual_comparison.py` に売却確認状態を追加し、`./tools/market_visual_qa.sh` で `/tmp/tsuri_market_confirm.png` / `_compare.png` を生成できるようにした。証拠: `docs/qa/evidence/fish_market/2026-07-05_market_confirm_layer_fix_compare.png`。
- `market_smoke` に「確認オーバーレイが詳細ラベルより上のレイヤーである」検査を追加。`./tools/market_visual_qa.sh`、`market_smoke.tscn`、`./tools/validate_project.sh` はgreen。
- R1 / `RarityStyles` 横展開として、一覧行のレアリティ色分岐を `market_screen.gd` から `RarityStyles.list_text_color` へ移行。色値は既存表示と同値で、新規Palette定数・freeze値変更・素材変更なし。
- 証拠: `docs/qa/evidence/fish_market/2026-07-05_market_rarity_styles_select_compare.png`、`2026-07-05_market_rarity_styles_confirm_compare.png`、`2026-07-05_market_rarity_styles_sold_compare.png`、`2026-07-05_market_rarity_styles_empty_compare.png`。
- R1 / Palette確認として、`_market_label` の透明シャドウ直書き色を `Color.TRANSPARENT` へ移行。新規Palette定数なし。表示同値の責務整理で、freeze値・レイアウト・素材・売却仕様は変更なし。
- 証拠: `docs/qa/evidence/fish_market/2026-07-05_market_transparent_palette_select_compare.png`、`2026-07-05_market_transparent_palette_confirm_compare.png`、`2026-07-05_market_transparent_palette_sold_compare.png`、`2026-07-05_market_transparent_palette_empty_compare.png`。
- 検証: `./tools/market_visual_qa.sh`、`market_smoke.tscn`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`validate_project.sh` のObjectDB/resource警告はベースライン既知。
- 固定条件: 魚市場画面へ新規直書き色を戻さない。
