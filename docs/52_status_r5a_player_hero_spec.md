# ステータス R5-A プレイヤーhero素材仕様

Date: 2026-07-14
対象参照: `reference/08_status_screen_mockup.png`
対象画面: `src/ui/status_screen.gd`

## 1. 目的と採否条件

現行3ペイン構成を維持した局所upliftとして、中央「釣果サマリー」上部medallionの魚ポートレートを、海辺で釣るプレイヤーの画面専用authored portraitへ置換する。参照の「釣り人自身の記録」というidentityへ近づけ、Lv・所持金・装備などの重複情報は増やさない。

採用条件は次の両方を満たすこと。

1. normal / hard同一seedの1280×720全画面でbeforeへ明確に勝つ。
2. after / referenceの320×180比較で、釣り人identityの差が縮んだと第三者が判別できる。円形cropの実表示寸法で顔または頭部、釣り竿、海が読める。

## 2. 参照分解と変更範囲

- 画面タイプ: 成長・所持品・釣果を確認するステータス一覧。現行の主な読み順と3ペインは成立済み。
- 参照でheroが担う役割: 釣果数値の前に「誰の釣り記録か」を示す円形の釣り人シーン。
- 現行Top1: `StatusSummaryBadge` 内が最近魚の丸アイコンで、プレイヤーidentityがない（P2）。
- Top2: 全画面の木・真鍮・紙のauthored質感差（P2、R5-A対象外）。
- Top3: 参照と現行のヘッダー/フッター情報構成差（現行契約を優先するP3、R5-A対象外）。
- 動かす矩形: `StatusSummaryBadge` 約x419–529 / y184–298の内側portrait slot約x423–524 / y190–279のみ。
- 維持するruntime情報: badge下部の「記録」、右側4指標、最近魚、称号、図鑑率。
- 不動: `PlayerStatusBar`、難易度名1回表示、3ペイン外形、フッター/戻る導線、魚図鑑/料理ボタン、全釣果数値、魚カード、クーラー/装備/料理ログ、難易度・保存ロジック。

## 3. 素材/runtime分担

| 要素 | 担当 | 備考 |
|---|---|---|
| 海辺で釣る人物・竿・海 | PNG一点物 | 文字・UI・魚なし |
| 円形外側の透明化・色調統一・解像度 | 決定的processor | `tools/process_status_r5a_assets.py` |
| 円形disk/frameと「記録」 | Godot runtime | 現行を維持 |
| 釣果・難易度・称号などの値 | Godot runtime | ロジック不変 |

## 4. ImageGen発注仕様（docs/12形式）

- use case: `stylized-concept`
- source: `tools/source_assets/status/status_player_fishing_source.png`
- product: `assets/showcase/status/status_player_fishing_portrait.png`
- source想定: 正方形、最低1024×1024。中央円形safe area内に人物上半身・竿・海面を収める。
- product: 256×256 RGBA。円外を透明化し、表示時の円形medallion cropへ最適化する。
- subject: 海辺または桟橋で釣りをする一人の若い釣り人。後ろ斜め向き。帽子または短髪の頭部、両手、斜め上へ伸びる釣り竿が明瞭。
- style: 本作のピクセルアート/タイル調背景になじむ、輪郭が明瞭な高品質2Dゲームイラスト。細かな写真表現ではなく、実表示90px前後でも形が読むことのできる大きな色面。
- palette: 深い海青、空色、濃紺、落ち着いた革茶、控えめな金色の光。既存の濃紺・羊皮紙・金枠と調和。
- composition: 人物の頭部は中央より少し左、竿は右上へ抜け、水平線と海面が背景として残る。円形cropの四隅に重要要素を置かない。
- lighting: 明るい海辺、爽やかだが彩度過多にしない。
- constraints: 文字、数字、ロゴ、UI枠、badge、魚、釣果、複数人物、船の主役化、透かしを入れない。人物と竿をcropしない。
- avoid: 写真、3Dレンダー、アニメ顔の接写、細すぎて消える竿、魚を掲げる構図、暗い逆光、過密な港、既存作品やキャラクターに似た意匠。

## 5. 決定的加工と検証

processorはsourceを中央正方形cropし、256×256へ高品質縮小、色数とコントラストを本作の小型portrait向けに正規化し、円形alpha maskを適用する。人物そのものをPIL描画しない。processorを2回実行し、ファイルhashとdecoded pixelsが一致することを確認する。

比較証拠は原寸before/after/reference、320×180 thumbnail、grayscale、source/product/実表示のasset contactを `docs/qa/evidence/status/2026-07-14_r5a_*` に保存する。
