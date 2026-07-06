# 32. 依頼ボード画面 v1 分解仕様

作成日: 2026-07-06
対象: `src/ui/quest_board_screen.gd`
参照画像: `reference/11_quest_board_mockup.png`

## 1. 画面の目的

E3の依頼ボードは、港から確認する「今日の目的」画面。掲示中の3件は常に受注済み扱いで、プレイヤーはここで納品または記録報告を行い、報酬を受け取る。

## 2. v1の構成

- 上部: 画面名「依頼ボード」、短い状況文、共通 `PlayerStatusBar`
- 中央: 木製掲示板風の面に依頼札3枚を横並びで掲示
- 各札: 依頼番号、種別、魚名、依頼文、進捗、報酬、納品/報告ボタン
- 下部: 達成数、職人仕掛けの状態、操作メッセージ、右下の「港へ戻る」

## 3. v1で扱わないもの

- 受注/破棄/手動リフレッシュ
- 依頼一覧のスクロール
- 魚市場の売却ロジックとの統合
- 魚そのものを報酬で配る処理
- 依頼ごとの専用NPC絵、専用背景PNG、文字焼き込み済みPNG

## 4. PNG素材とruntime描画の分担

- runtime: 日本語テキスト、進捗、ボタン状態、報酬、達成メッセージ
- 共通PNG: `assets/showcase/common/` のカード、ボタン、ステータスバー
- 魚PNG: `FightFishAssets` 経由で魚ポートレートを表示
- v1では専用ゲーム内素材を追加しない。専用木製掲示板や依頼札タグはP2候補としてQAログへ残す

## 5. 操作

- 達成済み依頼のボタン: `PlayerProgress.deliver_quest(index)` を呼び、報酬受取と依頼入替を即時反映
- 未達成依頼のボタン: disabled 表示
- 港へ戻る: `navigate("harbor")`

## 6. 検証

- `tools/quest_board_smoke.tscn`: 生成、納品、記録報告、限定仕掛け、画面構築を確認
- `tools/quest_board_visual_qa.sh`: `reference/11_quest_board_mockup.png` と実キャプチャの横並びを生成
- `docs/qa/quest_board_qa.md`: freeze値、残ギャップ、証拠画像を管理
