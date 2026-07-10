# 魚市場 QA判断ログ

最終更新: 2026-07-10 / 状態: v1 freeze・M0空状態P1再オープン完了 / RarityStyles共通化済み / R1 Palette確認済み / 帰港導線右下統一済み
参照画像: reference/10_fish_market_mockup.png
QA更新コマンド: ./tools/market_visual_qa.sh（通常選択・売却確認・売却完了・空状態）

## 1. freeze値（正本）

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 論理画面サイズ | 1280x720 | `MarketScreen.FishMarketDesignCanvas` | 既存P2釣具店と同じ固定キャンバス運用 |
| 一覧表示行数 | 7行 | 左一覧 | 参照画像の密度に合わせる |
| 上部ステータス | `PlayerStatusBar` | 画面上部 | docs/19の共通キット方針・情報重複禁止に合わせる |
| 主操作 | `まとめて売る` | 右下カート | 1匹売却も数量指定に統合 |
| 港へ戻る導線 | `RETURN_RECT = Rect2(1066.0, 670.0, 132.0, 40.0)` | 右下カート下 | docs/28の「画面右下 = 港へ戻る」規約に合わせる。旧左下矢印はbackplate焼き込みで非クリック |
| 売却結果 | 同画面内メッセージ | 右下カート/結果表示 | 別画面を作らない |
| 売却確認オーバーレイ | `CONFIRM_OVERLAY_Z = 100` / パネル不透明 | `MarketConfirmOverlay` | 背景側の詳細ラベル・数量ボタン・単価表示が確認パネルの上に描画されるP1を防ぐ |

### 1.1 M0 P1再オープン（2026-07-10）

docs/33 §3.1 と docs/45 §12.2 に基づくP1再発として、空状態だけを局所再オープンした。通常選択・売却確認・売却完了の構成と既存freezeは維持する。

| 区分 | 値・状態 | 理由 |
|---|---|---|
| 動かした値 | `INVENTORY_EMPTY_RECT = Rect2(86, 204, 582, 454)` | 左一覧の最終7行目までを空状態パネルで覆い、焼き込み行UIの残骸を隠す |
| 動かした値 | `EMPTY_DETAIL_RECT = Rect2(738, 198, 480, 284)` のruntime空状態ラベル | 魚なし氷トレー、詳細欄の灰色未ロード風バー、空の数値スロットを同一面で覆い、「次の釣果を待っています」を主役化する |
| 動かした値 | 通常詳細の `DETAIL_BODY_RECT` を濃紺のruntime情報カード化 | 灰色バーを意味のある詳細情報面へ置換する。位置・本文・売却仕様は不変 |
| 不動 | 1280x720、一覧7行、`PlayerStatusBar`、主操作、`RETURN_RECT`、同画面内売却結果、`CONFIRM_OVERLAY_Z`、売却API・価格・素材/backplate | M0の対象外。M1〜M3・素材置換へ送る |

同一seed・viewportの空状態before/afterは `docs/qa/evidence/fish_market/2026-07-10_m0_empty_before_after.png`。4状態のraw before/afterと参照比較は同ディレクトリの `2026-07-10_m0_{before,after}_*` を正とする。

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
| 空状態表示 | 2 | M0で左空状態パネルを最終行まで拡張し、右詳細を「次の釣果を待っています」へ切替。氷トレー・行残骸・未ロード風バーを同時に解消 | 採用 |
| 査定情報表示 | 1 | 通常時の説明欄を濃紺のruntime情報カード化し、焼き込み灰色バーを見せない | 採用 |
| backplate質感 | 3 | 市場背景、紙面粒状感、濃紺パネル装飾、査定トレーの氷・木箱・葉を強化。斜線・粒状ノイズを3回目で抑制 | 採用 |
| 行パーツ品質 | 1 | 名前・所持数・単価・数量をruntimeフィールドパネル化。紙面上の白アウトライン文字とコイン/単価重なりを解消 | 採用 |
| サッパ素材 | 1 | サバと混同しやすい見た目だったため、小型・淡色のサッパとして再生成 | 採用 |
| 売却確認モーダルP1 | 1 | `MarketConfirmOverlay` を通常UIより前面化し、確認本文枠・警告文を省略なしで読める長さへ調整 | 採用 |
| 港へ戻る位置 | 1 | `RETURN_RECT` を左下から右下カート下へ移動 | 採用 |

## 4. v1判定

| 状態 | 判定 | 証拠 |
|---|---|---|
| 通常選択 | M0後も採用 | `docs/qa/evidence/fish_market/2026-07-10_m0_after_select_reference_compare.png` |
| 売却確認 | M0後も採用 | `docs/qa/evidence/fish_market/2026-07-10_m0_after_confirm_reference_compare.png` |
| 売却完了 | M0後も採用 | `docs/qa/evidence/fish_market/2026-07-10_m0_after_sold_reference_compare.png` |
| 空状態 | M0 P1解消・採用 | `docs/qa/evidence/fish_market/2026-07-10_m0_empty_before_after.png` / `2026-07-10_m0_after_empty_reference_compare.png` |

通常選択・売却確認・売却完了・空状態の4状態で、参照画像の「左にクーラーボックス一覧、右上に査定、右下に売却カート」という構成を維持できている。魚名・所持数・単価・数量・合計・ボタン状態はruntime描画で、PNGへの日本語テキスト焼き込みはない。売却確認モーダルでは背景側の詳細ラベル・数量ボタン・単価表示が確認パネル上へ描画されず、確認文とボタンだけが読める。

## 5. 現在の残ギャップ

- 現行backplateはPIL生成の手描き風素材。参照画像のような高密度な市場背景・写真寄りの氷台は、次の一点物PNG生成フェーズで再検討する。
- M0で空状態はruntime表示として成立。氷+木箱の一点物査定トレー、専用市場背景はM1〜M2の素材工事で再検討する。
- 左下の矢印風ボタン枠は `fish_market_backplate.png` に焼き込まれた非クリック装飾。RF4ではruntime「港へ戻る」を右下へ移動し、素材の描き直しはv2候補へ送る。

## 6. フェーズスコープ宣言（作業中のみ）

- M0 P1は完了。空状態の左パネル被覆、右詳細の空状態メッセージ、通常詳細の説明面だけを動かした。論理画面サイズ、一覧7行、上部ステータス、主操作、`RETURN_RECT`、売却仕様、一括売却API、魚価格、確認オーバーレイ、backplate/素材、M1〜M3、他画面は触っていない。

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

2026-07-05 RF4:
- docs/28の帰港導線規約に合わせ、`MarketReturnButton` を左下から右下カート下へ移動。変更は `RETURN_RECT` のみで、`CART_ACTION_RECT`、ボタンスタイル、売却仕様、確認オーバーレイ、魚市場Paletteは触っていない。
- 4状態（通常選択・売却確認・売却完了・空状態）で、右下の「港へ戻る」が「まとめて売る」ボタン、カート枠、確認オーバーレイと重ならないことを実スクショで確認した。
- 左下に残る矢印風枠はbackplate焼き込みで、クリック可能ノードではない。素材変更は本スライスのスコープ外として残ギャップに送る。
- 証拠: `docs/qa/evidence/fish_market/2026-07-05_return_right_select_compare.png`、`2026-07-05_return_right_confirm_compare.png`、`2026-07-05_return_right_sold_compare.png`、`2026-07-05_return_right_empty_compare.png`。
- 検証: `./tools/market_visual_qa.sh`、`market_smoke.tscn` green。

2026-07-10 M0:
- docs/45で再確認されたP1（空の氷トレー、左一覧下端の行UI残骸、右詳細の未ロード風灰色バー）を局所再オープンした。参照は継続して `reference/10_fish_market_mockup.png`、M0の状態契約は通常選択・売却確認・売却完了・空状態の4枚で固定する。
- 空状態では`EMPTY_DETAIL_RECT`の濃紺メッセージ面へ切替え、「次の釣果を待っています」と釣り場へ向かう次行動を表示。氷トレー・灰色バー・空の数値スロットは同面の下へ隠し、通常状態では元の詳細領域へ復帰する。
- 左空状態パネルは最終7行目まで拡張し、焼き込み行残骸を隠した。通常の説明欄も濃紺情報カードとして再描画し、灰色バーの未ロード感を解消した。
- 同一seedの空状態before/after: `docs/qa/evidence/fish_market/2026-07-10_m0_empty_before_after.png`。4状態のafter参照比較: `2026-07-10_m0_after_{select,confirm,sold,empty}_reference_compare.png`。
- 検証（2026-07-10）: `./tools/market_visual_qa.sh` の4状態、`market_smoke.tscn` の空→魚あり→空復帰・空メッセージ・最終行被覆・通常詳細復帰、`./tools/validate_project.sh` はすべてgreen。
