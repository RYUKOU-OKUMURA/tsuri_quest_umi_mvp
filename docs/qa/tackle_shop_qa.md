# 釣具店画面 QA判断ログ

最終更新: 2026-07-04 / 状態: 座標再同期 + 視認性ブラッシュアップ済み v1 freeze中
参照画像: `reference/09_tackle_shop_rod_mockup.png` / `reference/09_tackle_shop_gear_mockup.png`
QA更新コマンド: `./tools/tackle_shop_visual_qa.sh`

## 1. freeze値（正本）

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 画面サイズ | 1280x720固定 | 全体 | プロジェクト標準 |
| 実ウィンドウ表示 | 1280x720デザインキャンバスを等比スケール + 中央寄せ | `shop_screen.gd` / `TackleShopDesignCanvas` | `window/stretch/aspect="expand"` で広い/縦長viewportになっても、backplateとruntime文字/クリック領域を同じ座標系に保つ |
| 正規リファレンス | 店主なし竿5本 / 店主なし仕掛け6種 | `reference/09_tackle_shop_*_mockup.png` | 商品陳列を主役にする。旧店主あり画像と現行スクショ由来 `*_complete.png` は正規参照から外す |
| backplate | 全画面 1280x720、竿/仕掛けで同一骨格 | `shop_screen.gd` / `assets/showcase/tackle_shop/shop_*_backplate.png` | 店内、棚、商品カード、空プレート、詳細紙面、装飾枠をPNGで担う。仕掛け側の旧カテゴリUIは削除 |
| 商品カード座標 | 3x2共通グリッド。竿は先頭5枠、仕掛けは6枠 | `shop_screen.gd` / `CARD_SLOT_RECTS` | 透明Button、選択ハイライト、商品名Label、価格/状態Labelを同じカード枠から派生させる |
| 商品名/状態プレート | 商品名はカード上部プレート中央、価格/所持/装備中/Lv不足は下部プレート中央。太字・輪郭付き | `shop_screen.gd` / `CARD_NAME_OFFSET` / `CARD_STATUS_OFFSET` | 個別Rect管理による左ズレ再発を防ぎ、拡大viewportでも読める文字量にする |
| 詳細表示 | 右紙面上にruntime表示 + 選択商品詳細大絵 | `shop_screen.gd` / `shop_detail_item_sheet.png` | 商品名、状態、説明、性能、対応エサ、購入/装備文言は焼き込まない。詳細大絵は384x224セルで商品ID差し替え |
| 下部操作 | 右下購入/装備、下部右の紙面中央に港戻り | `shop_screen.gd` | 戻る文言が右端飾りへ寄らないよう透明Button領域を紙面中央へ合わせる |
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
| 商品ラベル配置 | 1 | backplate内の空プレートへruntimeラベルを配置 | freeze |
| 詳細パネル文字配置 | 2 | 初回は左へ寄りすぎたため、右紙面のタイトル/説明/性能行へ座標補正 | freeze |
| 港戻り導線 | 1 | backplate下部右のボタン幅に合わせて透明Button領域を拡張 | freeze |
| 固定キャンバス化 | 1 | 1280x720の`TackleShopDesignCanvas`へ全素材/文字/クリック領域を収め、実viewportへ等比スケール | P1解消としてfreeze |
| カードレイヤー順 | 1 | カードレイヤーを先に作り、タブ/詳細/下部操作を後段に置いて入力を塞がない構造へ変更 | P1解消としてfreeze |
| visual QA非黒チェック | 1 | 1280x720と2124x1507の竿/仕掛けキャプチャが黒画像なら失敗する検証を追加 | P1再発防止としてfreeze |
| backplate/runtime座標再同期 | 1 | 共通カードグリッドへ統一し、仕掛けbackplateを竿画面骨格へ再合成 | P1解消としてfreeze |
| 詳細商品絵追従 | 1 | 固定大絵をbackplateから外し、`shop_detail_item_sheet.png` をruntime表示 | P1解消としてfreeze |
| 商品文字視認性 | 1 | カード名/状態、詳細行、下部メッセージを太字・大型化し、プレート幅を広く使用 | P1/P2解消としてfreeze |
| 詳細商品絵サイズ | 2 | 詳細シートを384x224横長セルへ変更し、小さい切り抜きも拡大して右紙面で主役化 | P2解消としてfreeze |
| 港戻り導線 | 2 | 右端飾りではなく紙面ボタン中央へ透明Button/文字位置を再配置 | P1解消としてfreeze |
| visual QA拡大キャプチャ | 2 | キャプチャごとにSubViewportを作り、描画待ちと`RenderingServer.force_draw()`を追加 | P1再発防止としてfreeze |

## 4. 暫定判定・再検証TODO

なし。視認性ブラッシュアップ後の比較画像は `docs/qa/evidence/tackle_shop/2026-07-04_tackle_shop_rod_readability_compare.png` / `docs/qa/evidence/tackle_shop/2026-07-04_tackle_shop_rig_readability_compare.png` に保存済み。広いviewport確認は `docs/qa/evidence/tackle_shop/2026-07-04_tackle_shop_rod_readability_expanded.png` / `docs/qa/evidence/tackle_shop/2026-07-04_tackle_shop_rig_readability_expanded.png` に保存済み。

## 5. 現在の残ギャップ

- **P2**: 詳細大絵は既存backplateからの透過切り抜き拡大でv1採用。看板品質へ上げる場合は、11商品分の専用高解像度詳細絵を別素材フェーズで作る。

## 6. フェーズスコープ宣言（作業中のみ）

（現在作業中のフェーズなし）

## 7. 判断ログ（直近パスのみ）

- 2026-07-03: 店主あり/現行スクショ参照を廃止し、店主なし・商品陳列主役のbackplate構成へ移行。竿は `big_game` / `marlin` を加えて5本化し、表示順は `ROD_ORDER` で固定する。
- 2026-07-03追補: `window/stretch/aspect="expand"` の実ウィンドウでbackplateだけが伸び、runtime文字/透明クリック領域が1280座標に残るP1を修正。全体を `TackleShopDesignCanvas` に閉じ込めて等比スケールし、カードレイヤーがタブ入力を塞がない順序へ変更した。
- 2026-07-04: backplateとruntime UIレイヤーの座標不一致をP1として再修正。カードButton、選択ハイライト、商品名Label、価格/状態Labelを共通カードグリッドから派生させ、仕掛けbackplateを竿画面と同じヘッダー/下部タブ/商品エリア/詳細パネル骨格へ再合成した。
- 2026-07-04追補: 詳細パネルの固定大絵を削除し、`shop_detail_item_sheet.png` のAtlas regionを選択商品IDで差し替える方式へ変更。仕掛け側のリール/糸/箱/カゴ系カテゴリUIはbackplateから削除した。
- 2026-07-04再追補: カード名/状態/価格、詳細行、下部メッセージを太字化・大型化し、港戻りを紙面ボタン中央へ移動。詳細商品絵は384x224横長セルへ変更して右紙面で大きく見せる。装飾アイコン列と重なる詳細ヒント文は非表示にした。
- 判断画像: `docs/qa/evidence/tackle_shop/2026-07-03_no_shopkeeper_rod_5lineup_concept.png` / `docs/qa/evidence/tackle_shop/2026-07-03_no_shopkeeper_rig_concept.png`。
- 実装後比較: `docs/qa/evidence/tackle_shop/2026-07-04_tackle_shop_rod_readability_compare.png` / `docs/qa/evidence/tackle_shop/2026-07-04_tackle_shop_rig_readability_compare.png`。
- 広いviewport証拠: `docs/qa/evidence/tackle_shop/2026-07-04_tackle_shop_rod_readability_expanded.png` / `docs/qa/evidence/tackle_shop/2026-07-04_tackle_shop_rig_readability_expanded.png`。
- 採用理由: 旧PIL背景より店内密度、商品主役感、紙面/金具の質感が明確に高く、店主なしでも釣具店として成立する。商品名・価格・状態値はruntime描画のまま維持できる。
- 検証: `./tools/tackle_shop_visual_qa.sh` exit 0、座標/詳細絵追従assert込み `tackle_shop_smoke` ok、`status_smoke` ok、`./tools/validate_project.sh` exit 0。Godot終了時に既存のObjectDB/resource警告あり。
- 固定条件: reference画像を実装から直接読まない。商品名・価格・状態値はPNGへ焼き込まない。今後の改善は全画面比較で現行に明確に勝つ候補だけ採用する。
