# サメの生簀 QA判断ログ

最終更新: 2026-07-13 / 状態: 水槽背景・環境光uplift freeze済み
参照画像: `reference/12_shark_pen_mockup.png`
QA更新コマンド: `./tools/shark_pen_visual_qa.sh`

## 1. freeze値（正本）

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 画面サイズ | 1280x720固定 | `tools/shark_pen_preview.gd` | 他画面QAと同一条件 |
| 上部ヘッダー | x 2.6% / y 2.8% / w 94.8% / h 12.2% | `src/ui/shark_pen_screen.gd` | 画面名と共通ステータスバーを1段に集約 |
| 水槽ビュー | x 3.4% / y 17.6% / w 56.1% / h 59.9% | `src/ui/shark_pen_screen.gd` | コレクション感の主領域。メガロドンが主役として読める比率 |
| 水槽環境背景 | `tank_environment_bg.png` / 1280x768 | `assets/showcase/shark_pen/` | authored深海背景・泡・上方環境光。水槽wellの既存矩形へ表示 |
| サメ選択列 | x 61.3% / y 17.6% / w 35.3% / h 59.9% | `src/ui/shark_pen_screen.gd` | 10枠を1画面内に省略なしで表示 |
| 餌やりパネル | x 3.4% / y 80.7% / w 73.8% / h 14.8% | `src/ui/shark_pen_screen.gd` | 好物・獲得EXP・主操作を下部に集約 |
| 戻る導線 | 右下パネル内 | `src/ui/shark_pen_screen.gd` | docs/19 の右下規約に準拠 |
| 餌カード表示 | 実インベントリ全件 | `src/ui/shark_pen_screen.gd` | 実プレイで餌魚が到達不能にならないよう全件を横スクロール対象にする。QA seedは5件に抑えて初期表示を確認 |

## 2. 不採用・再試行禁止リスト

| 案 | 却下理由 | 判断日 |
|---|---|---|
| サメ選択行ごとの金縁フレーム | docs/19 §4.4 の行レベル金縁禁止に反するため。選択行のみ紙面ハイライト | 2026-07-07 |
| 水槽専用背景PNGをv1で生成 | v1は構成固定が目的。専用背景はv2素材候補へ送る | 2026-07-07 |

## 3. 微調整カウンタ

| パラメータ | 回数 | 直近の変更内容 | 状態 |
|---|---|---|---|
| 装飾パス累計 | 1 | runtime水槽グラデーション・流線・行ハイライトで構成 | v1内では追加装飾を増やさない |
| 餌カード幅 | 1 | 142px相当から132px相当へ調整しQA seedでは横スクロールを出さない | freeze候補 |
| 水槽補助サメ枠 | 1 | 補助サメが切れないよう表示枠を拡張 | freeze候補 |
| 水槽背景素材候補 | 1 | OpenAI生成sourceをteal/deep-navyへ統一処理し採用 | freeze |

## 4. 暫定判定・再検証TODO

- なし。

## 5. 現在の残ギャップ

- 好物の王冠はruntime小チップ。専用アイコン化はv2候補。
- メガロドン最終演出（全サメが揃って泳ぐ）は未実装。E10完了後の演出強化候補。

## 6. フェーズスコープ宣言（作業中のみ）

- なし（2026-07-13の水槽背景・環境光upliftは採用・freeze済み）。

### 参照との差分Top3（面積×視線優先度）

1. 解消済み: 水槽の明るい単色青＋直線3本を、deep tealのauthored背景・有機的な泡・上方環境光へ置換。
2. P2 / 現行Top1: 好物の王冠がruntime小チップ。
3. P2 / 現行Top2: メガロドン最終演出と全サメ同時遊泳が未実装。

## 7. 判断ログ（直近パスのみ）

2026-07-13 水槽背景・環境光uplift:

- 変更: `tools/source_assets/shark_pen/shark_pen_tank_bg_source.png` をOpenAI built-in image generationで生成し、`tools/generate_shark_pen_assets.py` で1280x768・teal/deep-navyへ統一処理。`SharkPenAquariumWater` へ配線し、旧runtime直線3本を撤去。
- 変えていない: freeze表の全矩形、サメ10枠、選択/なつき度、餌5枠/全件scroll、給餌CTA、港へ戻る、魚素材/配置、王冠、メガロドン最終演出。
- 状態: 標準=`メガロドン84/餌5種`、高リスク=`同一seed＋メガロドン行hover＋選択餌focus`。両方1280x720。高リスクbeforeはbase `86f6a2c4` の一時worktreeで同じ入力を再現して取得し、一時fixture変更は製品branchへ持ち込んでいない。
- 判断画像: 標準=`docs/qa/evidence/shark_pen/2026-07-13_tank_uplift_before_after_reference_original.png`、`..._thumbnail.png`、`..._grayscale.png`。高リスク=`..._selected_hover_before_after_reference_original.png`、`..._thumbnail.png`、`..._grayscale.png`。個別原寸=`..._before_selected_hover.png` / `..._after_selected_hover.png`。素材=`..._asset_contact.png`。
- 同一状態pixel確認: 高リスクbefore/afterの差分bboxは `(53,133)-(754,553)`、変更260,595px。freeze済み水槽矩形 `x=44..761 / y=127..557` の外側は0pxで、背景以外のhover/focus・文字・矩形は同一。
- 採用理由: beforeの明るい単色blueとHUD状の直線から、参照のdeep teal水槽・有機的な泡・上方環境光へ縮小でも明確に近づいた。標準/高リスクで文字衝突・見切れ・選択状態の可読性退行はなくP1ゼロ。
- 固定条件: 背景の中央は大サメ用safe-areaとして静かに保ち、タイトル/下段情報帯のcontrastを下げない。runtime装飾の再加算で質感を補わない。

2026-07-07 P1可読性修正:

- 変更: 選択済みサメ行・餌カードの hover/focus 背景を通常選択背景と同じ紙面色に揃え、濃色文字が濃紺背景へ沈む状態を解消。`shark_pen_screen_smoke` に選択済み hover/focus 背景の回帰チェックを追加。
- 変えていない: サメ選択列のfreeze値、行数、行ごとの金縁禁止、素材構成。
- 判断画像: `docs/qa/evidence/shark_pen/2026-07-07_selected_hover_readability_compare.png`（通常選択状態の確認）。hover/focus の回帰保証は `shark_pen_screen_smoke` で固定。
- 採用理由: P1（選択中テキストが読めない）の解消。選択行は紙面ハイライトのまま読み、非選択行のみ濃紺hoverを維持する。
- 固定条件: 選択済みアイテムでは `hover` / `focus` 時も濃色文字に対して明背景を維持する。

2026-07-07 v1構成確認:

- 変更: `src/ui/shark_pen_screen.gd`、`tools/shark_pen_preview.gd`、`tools/shark_pen_screen_smoke.gd`、`tools/shark_pen_visual_qa.sh` を追加。
- 変えていない: 既存港画面導線、釣行中の餌魚セットUI、E4危険海域のfreeze値。
- 判断画像: `docs/qa/evidence/shark_pen/2026-07-07_v1_compare.png`
- 採用理由: 参照と同じ上部/水槽/サメ選択/餌やり/右下戻るの構成になり、10枠表示・好物給餌・サメ除外がsmokeで確認できた。
- 固定条件: 行レベル金縁は戻さない。餌カードは実インベントリ全件を表示し、QA seedの初期表示では横スクロールを出さない。
