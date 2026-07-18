# 釣具店画面 QA判断ログ

最終更新: 2026-07-18 / 状態: 座標・素材・入力契約 v1 freeze中 / E11 INPUT-SHOP確認済み / TACKLE-T1 marlin pilot採用
参照画像: `reference/09_tackle_shop_rod_mockup.png` / `reference/09_tackle_shop_gear_mockup.png`
QA更新コマンド: `./tools/tackle_shop_visual_qa.sh`

## 1. freeze値（正本）

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 画面サイズ | 1280x720固定 | 全体 | プロジェクト標準 |
| 実ウィンドウ表示 | 1280x720デザインキャンバスを等比スケール + 中央寄せ | `shop_screen.gd` / `TackleShopDesignCanvas` | `window/stretch/aspect="expand"` で広い/縦長viewportになっても、backplateとruntime文字/クリック領域を同じ座標系に保つ |
| 正規リファレンス | 店主なし竿5本 / 店主なし仕掛け6種 | `reference/09_tackle_shop_*_mockup.png` | 商品陳列を主役にする。旧店主あり画像と現行スクショ由来 `*_complete.png` は正規参照から外す |
| backplate | 全画面 1280x720、竿/仕掛けで同一骨格 | `shop_screen.gd` / `assets/showcase/tackle_shop/shop_*_backplate.png` | 店内、棚、商品カード、空プレート、詳細紙面、装飾枠をPNGで担う。仕掛け側の旧カテゴリUIは削除 |
| 商品カード座標 | 3x2共通グリッド。竿は先頭5枠、仕掛けは6枠 | `shop_screen.gd` / `CARD_SLOT_RECTS` | 透明Button、選択ハイライトは共通カード枠へ合わせる |
| 商品名/状態プレート | 商品名はカード上部プレート中央、価格/所持/装備中/Lv不足は下部プレート中央。太字・輪郭付き | `shop_screen.gd` / `ROD_CARD_*_RECTS` / `RIG_CARD_*_RECTS` | 竿/仕掛けで微妙に異なる実プレート位置へruntime文字を合わせ、列が右へ流れる再発を防ぐ |
| 詳細表示 | 右紙面上にruntime表示 + 選択商品詳細大絵 | `shop_screen.gd` / `shop_detail_item_sheet.png` | 商品名、状態、説明、性能、対応エサ、購入/装備文言は焼き込まない。詳細大絵は384x224セルで商品ID差し替え |
| TACKLE-T1 pilot対象 | 竿タブ `marlin`（詳細sheet index 4）のみ | `tools/source_assets/tackle_shop/t1_marlin_detail_source.png` → `tools/process_tackle_shop_t1_marlin.py` → `shop_detail_item_sheet.png` | 高視線の竿タブ選択商品。カード/詳細矩形・runtime文言・購入可能→購入後disabled契約は不変 |
| TACKLE-T1 非対象セル | index 0–3, 5–10の10セル | `shop_detail_item_sheet.png` | decoded RGBA連結hash `6f5304272900d7f5fcdc61d5dbf496c8a98cbdd2040241357e3f92a01a1e19a9` をbefore/afterで一致させ、batch化しない |
| 下部操作 | 右下購入/装備、下部右の紙面中央に港戻り | `shop_screen.gd` | 戻る文言が紙面ボタン内の縦横中央に乗るよう透明Button領域を合わせる |
| 入力検証 | 初期focus=選択カード。タブ・表示カード・有効な購入/装備・港戻りを閉じたgraphで結び、disabled主操作をskipする。refresh/rebuild後は意味IDでfocusを保持し、Escapeは港へ1回戻る | `src/ui/shop_screen.gd` / `tools/tackle_shop_input_smoke.gd` / `tools/tackle_shop_smoke.gd` | 実Viewportのキーpress/releaseとmouse clickで、カード可視focus・決定・購入後fallback・戻るを固定する。1280x720矩形と既存mouse hit領域は不変 |

## 2. 不採用・再試行禁止リスト

| 案 | 却下理由 | 判断日 |
|---|---|---|
| 商品名・価格・状態値をPNGへ焼き込む | 所持/装備中/資金不足/Lv不足で表示が変わり、GameDataとズレやすい。docs/19のruntime分担に反する | 2026-07-03 |
| 店主ありリファレンスへ戻す | 商品陳列を主役にする新方針と衝突する | 2026-07-03 |
| 現行スクショ由来 `*_complete.png` を正規参照として残す | 目標画像と現行記録が混同されるため削除対象 | 2026-07-03 |
| エサ単体の購入タブを追加 | データ仕様外。今回は仕掛けの対応エサカテゴリ表示に留める | 2026-07-03 |

## 3. 微調整カウンタ

| パラメータ | 回数 | 直近の変更内容 | 状態 |
|---|---|---|---|
| backplate正規化 | 1 | 生成コンセプトを1280x720へ縮小し、referenceとassetsへ分離 | 採用 |
| 商品ラベル配置 | 2 | 共通offsetをやめ、竿/仕掛けの実プレートRectへruntimeラベルを配置 | freeze |
| 詳細パネル文字配置 | 2 | 初回は左へ寄りすぎたため、右紙面のタイトル/説明/性能行へ座標補正 | freeze |
| 港戻り導線 | 1 | backplate下部右のボタン幅に合わせて透明Button領域を拡張 | freeze |
| 固定キャンバス化 | 1 | 1280x720の`TackleShopDesignCanvas`へ全素材/文字/クリック領域を収め、実viewportへ等比スケール | P1解消としてfreeze |
| カードレイヤー順 | 1 | カードレイヤーを先に作り、タブ/詳細/下部操作を後段に置いて入力を塞がない構造へ変更 | P1解消としてfreeze |
| visual QA非黒チェック | 1 | 1280x720と2124x1507の竿/仕掛けキャプチャが黒画像なら失敗する検証を追加 | P1再発防止としてfreeze |
| backplate/runtime座標再同期 | 1 | 共通カードグリッドへ統一し、仕掛けbackplateを竿画面骨格へ再合成 | P1解消としてfreeze |
| 詳細商品絵追従 | 1 | 固定大絵をbackplateから外し、`shop_detail_item_sheet.png` をruntime表示 | P1解消としてfreeze |
| 商品文字視認性 | 1 | カード名/状態、詳細行、下部メッセージを太字・大型化し、プレート幅を広く使用 | P1/P2解消としてfreeze |
| 詳細商品絵サイズ | 2 | 詳細シートを384x224横長セルへ変更し、小さい切り抜きも拡大して右紙面で主役化 | P2解消としてfreeze |
| ヘッダー装備表示 | 1 | Lv/竿/所持金/仕掛けのruntime文字を上部プレート中央へ下げ、所持金は実プレート中心へ左寄せ | P1解消としてfreeze |
| 港戻り導線 | 3 | 右端飾りではなく紙面ボタン中央へ透明Button/文字位置を再配置 | P1解消としてfreeze |
| visual QA拡大キャプチャ | 2 | キャプチャごとにSubViewportを作り、描画待ちと`RenderingServer.force_draw()`を追加 | P1再発防止としてfreeze |
| 入力focus収束 | 1 | 選択カード初期focus、closed graph、disabled skip、意味ID復元、共通Escapeを追加 | 採用・freeze |
| T1詳細大絵 | 0 | marlin 1セルだけを高解像度一点物へ置換。矩形・文言・入力は不変 | 採用。別の数px調整へ戻さない |

## 4. 暫定判定・再検証TODO

なし。ラベル位置ブラッシュアップ後の比較画像は `docs/qa/evidence/tackle_shop/2026-07-04_tackle_shop_rod_label_alignment_compare.png` / `docs/qa/evidence/tackle_shop/2026-07-04_tackle_shop_rig_label_alignment_compare.png` に保存済み。広いviewport確認は `docs/qa/evidence/tackle_shop/2026-07-04_tackle_shop_rod_label_alignment_expanded.png` / `docs/qa/evidence/tackle_shop/2026-07-04_tackle_shop_rig_label_alignment_expanded.png` に保存済み。

## 5. 現在の残ギャップ

- 仕掛け6商品と竿の他4商品は既存v1詳細絵を維持。T1の勝ちを根拠に一括batch化しない。
- OpenAI生成sourceの個別権利clearanceは `docs/31_asset_ledger.md` と同じくU-08 pending。

## 6. フェーズスコープ宣言（作業中のみ）

（現在作業中のフェーズなし）

## 7. 判断ログ（直近パスのみ）

2026-07-18:
- TACKLE-T1として、竿タブの高視線代表商品 `marlin` だけをpilotした。現行の同一seed・同一データ・同一選択（`tools/tackle_shop_preview.gd` の竿タブ `marlin`、Lv.3、5,400 G、装備竿=外海・青嵐）を1280x720と2124x1507で再撮影し、旧v1詳細絵をbefore、T1候補をafterとして比較した。
- 変えたもの: `tools/source_assets/tackle_shop/t1_marlin_detail_source.png`、T1専用の決定的processor/check/self-test、`shop_detail_item_sheet.png` のindex 4セル、比較/evidence。変えていないもの: index 0–3/5–10の10セル、backplate、3x2カード、全Rect、商品/価格/状態/runtime文言、GameData/PlayerProgress、購入/装備ロジック、mouse hit領域、仕掛け6カード、focus graph。
- 非対象10セルのdecoded RGBA連結freeze hashはbaseline `b73d275c` と一致（`6f5304272900d7f5fcdc61d5dbf496c8a98cbdd2040241357e3f92a01a1e19a9`）。hashはprocessor定数へ固定し、`--check`と`--self-test`は非対象任意セル変更、対象index 4のsource期待値stale、decoded同値rewrite、atomic失敗時の旧output/temp cleanupを検出する。現行sheet自身から期待値を再生成しない。
- 採用理由: 原寸で旧切り抜き拡大よりmarlinの竿全体・ガイド・両軸リールの構造が明瞭になり、detail wellの横幅を使って主対象として読める。320x180比較でも詳細大絵が商品カード群に埋もれず、参照の「商品を大きく見せる」方向へ近づいた。候補生成そのものは採用理由にせず、before/after/reference比較で採否した。
- 証拠: `docs/qa/evidence/tackle_shop/2026-07-18_tackle_t1_marlin_before_after.png`、`2026-07-18_tackle_t1_marlin_before_after_reference_320x180.png`、`2026-07-18_tackle_t1_marlin_detail_before_after.png`、`2026-07-18_tackle_t1_marlin_expanded_before_after.png`、`2026-07-18_tackle_t1_focus_disabled-card.png`。
- 高リスク回帰: `tackle_shop_smoke.tscn` のmarlin購入可能→購入後disabled、資金不足big_game、竿/仕掛け切替、`tackle_shop_input_smoke.tscn` の初期focus/disabled skip/Tab/Shift+Tab/Enter/Escape/mouse、仕掛け6カードを維持する。focus原寸証拠はinput smokeがmarlinを実表示し、購入後disabled actionからmarlinカードへfocus fallbackしたfresh after状態で保存した。
- 固定条件: `marlin` 以外の詳細絵を同じcommitで作らない。sourceをreference/候補へ戻さず、商品名・価格・状態値をPNGへ焼き込まない。次の大絵は別pilotとして同一比較条件を満たす場合だけ起票する。

2026-07-15:
- E11 INPUT-SHOPとして、選択中カードを安全な初期focusにし、竿/仕掛けタブ・現在表示中の商品カード・有効な購入/装備・港戻りを閉じたfocus graphへ登録した。disabledの購入/装備は候補から除外する。
- カードはrefreshごとに再生成されるため、`tab:<mode>` / `card:<item_id>` / `action` / `return` の意味IDで操作文脈を復元する。購入直後にfocus中の主操作がdisabledになった場合は、選択カードへfallbackする。
- 代表状態は「竿・入門竿装備中（主操作disabled）」、高リスク状態は「磯竿を選択して購入可能→購入後disabled」と「仕掛けタブ・6カード」。実キーのTab/Shift+Tab/Enter/Escapeと実mouse clickで、全enabled到達、disabled skip、カード選択、購入1回、タブ切替、港戻り1回を確認した。
- 原寸証拠: `docs/qa/evidence/tackle_shop/2026-07-15_input_card_focus.png` は既存E11初期focus証拠。T1高リスク証拠は `docs/qa/evidence/tackle_shop/2026-07-18_tackle_t1_focus_disabled-card.png` で、input smokeがmarlin購入後のdisabled actionとmarlinカードfocus ringを1280x720でfresh captureした。
- 変えていないもの: 1280x720 design canvas、backplate、3x2カード、全Rect、商品/詳細素材、runtime文言、GameData、PlayerProgress、価格・購入・装備ロジック、既存mouse hit領域。
- 検証: `tackle_shop_input_smoke.tscn` / `tackle_shop_smoke.tscn` / `tackle_shop_visual_qa.sh` / E11 input baselineのSHOP finding 0件 / `./tools/validate_project.sh` / `git diff --check`。
- 固定条件: カード再生成後のfocusは意味IDで復元し、disabled操作をgraphへ戻さない。カードのローカル透明styleで共通focus ringを上書きしない。

2026-07-05:
- R1 / Palette移行として、詳細アイコンtint、選択カードwash、タブactive/inactive tint、選択枠透明fillを `Palette.TACKLE_*` へ移行した。
- 変えていないもの: §1 freeze値、1280x720固定キャンバス、商品カード座標、商品名/価格/状態/詳細文言、backplate、詳細大絵、透明Button領域、日本語PNG焼き込み。
- 新規Palette定数: `TACKLE_DETAIL_ICON_MODULATE` / `TACKLE_CARD_SELECTION_WASH` / `TACKLE_TAB_ACTIVE_MODULATE` / `TACKLE_TAB_INACTIVE_MODULATE` / `TACKLE_SELECTION_FILL`。理由は釣具店画面の残り直書き色4件を用途名で管理するため。
- 証拠画像: `docs/qa/evidence/tackle_shop/2026-07-05_tackle_shop_palette_rod_compare.png`, `docs/qa/evidence/tackle_shop/2026-07-05_tackle_shop_palette_rig_compare.png`, `docs/qa/evidence/tackle_shop/2026-07-05_tackle_shop_palette_rod_expanded.png`, `docs/qa/evidence/tackle_shop/2026-07-05_tackle_shop_palette_rig_expanded.png`
- 判定: 竿/仕掛けの通常キャプチャと広いviewportキャプチャで、カード選択枠・詳細アイコン・タブ表示に未表示/重なり/見切れなし。これはR1表示同値移行なので、cmp一致は完了条件にしていない。
- 検証: `./tools/tackle_shop_visual_qa.sh`、`tackle_shop_smoke.tscn`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`validate_project.sh` のObjectDB/resource警告はベースライン既知。
- 固定条件: 釣具店の画面固有色は `Palette.TACKLE_*` へ寄せ、`src/ui/shop_screen.gd` へ新規直書き色を戻さない。

- 2026-07-03: 店主あり/現行スクショ参照を廃止し、店主なし・商品陳列主役のbackplate構成へ移行。竿は `big_game` / `marlin` を加えて5本化し、表示順は `ROD_ORDER` で固定する。
- 2026-07-03追補: `window/stretch/aspect="expand"` の実ウィンドウでbackplateだけが伸び、runtime文字/透明クリック領域が1280座標に残るP1を修正。全体を `TackleShopDesignCanvas` に閉じ込めて等比スケールし、カードレイヤーがタブ入力を塞がない順序へ変更した。
- 2026-07-04: backplateとruntime UIレイヤーの座標不一致をP1として再修正。カードButton、選択ハイライト、商品名Label、価格/状態Labelを共通カードグリッドから派生させ、仕掛けbackplateを竿画面と同じヘッダー/下部タブ/商品エリア/詳細パネル骨格へ再合成した。
- 2026-07-04追補: 詳細パネルの固定大絵を削除し、`shop_detail_item_sheet.png` のAtlas regionを選択商品IDで差し替える方式へ変更。仕掛け側のリール/糸/箱/カゴ系カテゴリUIはbackplateから削除した。
- 2026-07-04再追補: カード名/状態/価格、詳細行、下部メッセージを太字化・大型化し、港戻りを紙面ボタン中央へ移動。詳細商品絵は384x224横長セルへ変更して右紙面で大きく見せる。装飾アイコン列と重なる詳細ヒント文は非表示にした。
- 2026-07-04三追補: カード文字を単一offsetから竿/仕掛け別の6枠プレートRectへ変更。上部ヘッダー表示を実プレート中心へ下げ、所持金はプレート中心へ左寄せ、港戻りは紙面ボタン中央へ再調整した。
- 判断画像: `docs/qa/evidence/tackle_shop/2026-07-03_no_shopkeeper_rod_5lineup_concept.png` / `docs/qa/evidence/tackle_shop/2026-07-03_no_shopkeeper_rig_concept.png`。
- 実装後比較: `docs/qa/evidence/tackle_shop/2026-07-04_tackle_shop_rod_label_alignment_compare.png` / `docs/qa/evidence/tackle_shop/2026-07-04_tackle_shop_rig_label_alignment_compare.png`。
- 広いviewport証拠: `docs/qa/evidence/tackle_shop/2026-07-04_tackle_shop_rod_label_alignment_expanded.png` / `docs/qa/evidence/tackle_shop/2026-07-04_tackle_shop_rig_label_alignment_expanded.png`。
- 採用理由: 旧PIL背景より店内密度、商品主役感、紙面/金具の質感が明確に高く、店主なしでも釣具店として成立する。商品名・価格・状態値はruntime描画のまま維持できる。
- 検証: `./tools/tackle_shop_visual_qa.sh` exit 0、座標/詳細絵追従assert込み `tackle_shop_smoke` ok、`status_smoke` ok、`./tools/validate_project.sh` exit 0。Godot終了時に既存のObjectDB/resource警告あり。
- 固定条件: reference画像を実装から直接読まない。商品名・価格・状態値はPNGへ焼き込まない。今後の改善は全画面比較で現行に明確に勝つ候補だけ採用する。
