# 依頼ボード QA判断ログ

最終更新: 2026-07-06 / 状態: v1確認済み
参照画像: reference/11_quest_board_mockup.png
QA更新コマンド: ./tools/quest_board_visual_qa.sh

## 1. freeze値（正本）

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 依頼札枚数 | 3枚固定 | `src/ui/quest_board_screen.gd` | E3仕様。掲示中3件は常時進行中 |
| 札配置 | 横3列 | `QuestBoardPanel` | 1280x720で依頼文・進捗・報酬を同時に読ませるため |
| 帰港ボタン | 右下 | `QuestBoardFooter` | 他画面の右下規約に合わせる |

## 2. 不採用・再試行禁止リスト

| 案 | 却下理由 | 判断日 |
|---|---|---|

## 3. 微調整カウンタ

| パラメータ | 回数 | 直近の変更内容 | 状態 |
|---|---|---|---|
| 装飾パス累計 | 1 | 共通素材とruntime木板でv1掲示板を構成 | v1確認中 |

## 4. 暫定判定・再検証TODO

- 専用PNG素材は未投入。v1は共通キットでの機能実装を優先し、専用木製掲示板・依頼札タグはP2候補。
- 実キャプチャ証拠: `docs/qa/evidence/quest_board/2026-07-06_quest_board.png`
- 横並び比較: `docs/qa/evidence/quest_board/2026-07-06_quest_board_compare.png`

## 5. 現在の残ギャップ

- 依頼札の紙質・ピン留め・掲示板の木目はruntime表現のため、既存完成画面より素材感が弱い。
- 依頼者/NPCの個性付けは未実装。

## 6. フェーズスコープ宣言（作業中のみ）

E3 v1では、画面構成・進捗可読性・納品/報告操作を確定対象にする。専用PNG素材の品質追求は今回のfreeze対象外。

## 7. 判断ログ（直近パスのみ）

2026-07-06:

- `reference/11_quest_board_mockup.png` をv1参照として追加。
- `tools/quest_board_visual_qa.sh` で実キャプチャと横並び比較を生成し、`docs/qa/evidence/quest_board/2026-07-06_quest_board_compare.png` に保存。
- 3枚の依頼札、進捗、報酬、未達成disabled表示、右下帰港ボタンが確認できるためv1確認済みとする。
