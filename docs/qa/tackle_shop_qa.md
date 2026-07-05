# 釣具店画面 QA判断ログ

最終更新: 2026-07-05 / 状態: 座標再同期 + ラベル位置ブラッシュアップ済み v1 freeze中 / R1 Palette確認済み
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
| 下部操作 | 右下購入/装備、下部右の紙面中央に港戻り | `shop_screen.gd` | 戻る文言が紙面ボタン内の縦横中央に乗るよう透明Button領域を合わせる |
| 入力検証 | 実クリックでタブ切替、商品選択、購入/装備、港戻りを検証 | `tools/tackle_shop_smoke.gd` | 内部メソッド直呼びだけでは、レイヤーが入力を塞ぐP1を検出できないため |

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

## 4. 暫定判定・再検証TODO

なし。ラベル位置ブラッシュアップ後の比較画像は `docs/qa/evidence/tackle_shop/2026-07-04_tackle_shop_rod_label_alignment_compare.png` / `docs/qa/evidence/tackle_shop/2026-07-04_tackle_shop_rig_label_alignment_compare.png` に保存済み。広いviewport確認は `docs/qa/evidence/tackle_shop/2026-07-04_tackle_shop_rod_label_alignment_expanded.png` / `docs/qa/evidence/tackle_shop/2026-07-04_tackle_shop_rig_label_alignment_expanded.png` に保存済み。

## 5. 現在の残ギャップ

- **将来改善**: 詳細大絵は既存backplateからの透過切り抜き拡大でv1採用。看板品質へ上げる場合は、11商品分の専用高解像度詳細絵を別素材フェーズで作る。

## 6. フェーズスコープ宣言（作業中のみ）

（現在作業中のフェーズなし）

## 7. 判断ログ（直近パスのみ）

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
