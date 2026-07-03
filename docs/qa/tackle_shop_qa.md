# 釣具店画面 QA判断ログ

最終更新: 2026-07-03 / 状態: 店主なしbackplate版 v1 freeze中
参照画像: `reference/09_tackle_shop_rod_mockup.png` / `reference/09_tackle_shop_gear_mockup.png`
QA更新コマンド: `./tools/tackle_shop_visual_qa.sh`

## 1. freeze値（正本）

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 画面サイズ | 1280x720固定 | 全体 | プロジェクト標準 |
| 正規リファレンス | 店主なし竿5本 / 店主なし仕掛け6種 | `reference/09_tackle_shop_*_mockup.png` | 商品陳列を主役にする。旧店主あり画像と現行スクショ由来 `*_complete.png` は正規参照から外す |
| backplate | 全画面 1280x720 | `shop_screen.gd` / `assets/showcase/tackle_shop/shop_*_backplate.png` | 店内、棚、商品絵、空プレート、詳細紙面、装飾枠をPNGで担う |
| 竿カードクリック領域 | 5本: 上段3 / 下段2 | `shop_screen.gd` | 竿5本の陳列と一致させる。透明Buttonで入力だけを受ける |
| 仕掛けカードクリック領域 | 6種: 3x2 | `shop_screen.gd` | 既存仕掛け6種を維持し、透明Buttonで入力だけを受ける |
| 詳細表示 | 右紙面上にruntime表示 | `shop_screen.gd` | 商品名、状態、説明、性能、対応エサ、購入/装備文言は焼き込まない |
| 下部操作 | 右下購入/装備、さらに右端港戻り | `shop_screen.gd` | 参照の下部操作帯に合わせる |

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

## 4. 暫定判定・再検証TODO

なし。竿/仕掛けの比較画像は `docs/qa/evidence/tackle_shop/2026-07-03_tackle_shop_rod_compare.png` / `docs/qa/evidence/tackle_shop/2026-07-03_tackle_shop_rig_compare.png` に保存済み。

## 5. 現在の残ギャップ

- **P2**: 仕掛けタブの右詳細大絵はbackplate固定のため、runtime詳細アイコンを重ねて選択対象を補足する。全画面比較で邪魔になる場合は次素材フェーズで選択商品の差し替えスロットを分離する。
- **P2**: 右詳細紙面は新backplateの装飾密度が高く、runtime文字と大絵の重なり余白がまだ浅い。P1の棚側流出・省略・重なりが再発しない限り、次は素材側の空欄設計で改善する。

## 6. フェーズスコープ宣言（作業中のみ）

（現在作業中のフェーズなし）

## 7. 判断ログ（直近パスのみ）

- 2026-07-03: 店主あり/現行スクショ参照を廃止し、店主なし・商品陳列主役のbackplate構成へ移行。竿は `big_game` / `marlin` を加えて5本化し、表示順は `ROD_ORDER` で固定する。
- 判断画像: `docs/qa/evidence/tackle_shop/2026-07-03_no_shopkeeper_rod_5lineup_concept.png` / `docs/qa/evidence/tackle_shop/2026-07-03_no_shopkeeper_rig_concept.png`。
- 実装後比較: `docs/qa/evidence/tackle_shop/2026-07-03_tackle_shop_rod_compare.png` / `docs/qa/evidence/tackle_shop/2026-07-03_tackle_shop_rig_compare.png`。
- 採用理由: 旧PIL背景より店内密度、商品主役感、紙面/金具の質感が明確に高く、店主なしでも釣具店として成立する。商品名・価格・状態値はruntime描画のまま維持できる。
- 検証: `./tools/tackle_shop_visual_qa.sh` exit 0、`tackle_shop_smoke` ok、`status_smoke` ok、`fish_book_smoke` ok、`fishing_spot_select_smoke` ok、`./tools/validate_project.sh` exit 0。Godot終了時に既存のObjectDB/resource警告あり。
- 固定条件: reference画像を実装から直接読まない。商品名・価格・状態値はPNGへ焼き込まない。今後の改善は全画面比較で現行に明確に勝つ候補だけ採用する。
