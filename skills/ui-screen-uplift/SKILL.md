---
name: ui-screen-uplift
description: Quality uplift of an EXISTING game screen UI in this repo. Use when the user asks to raise/polish/improve a screen's visual quality (クオリティを上げる, ブラッシュアップ, 参照に近づける, 見た目改善) for screens like fish book (`src/ui/fish_book_screen.gd`), fishing spot map (`src/ui/fishing_spot_select_screen.gd`), underwater fight, title, or harbor. For building a brand-new screen OR formalizing an existing placeholder/simple screen into its first production v1 (○○画面を正式化) use ui-screen-build instead; for the cooking/meal/level-up flow use tsuri-cooking-showcase-uplift instead.
---

# UI Screen Uplift（既存画面ブラッシュアップ）

## Purpose

既存画面を、微調整ループに入らずに参照品質へ近づける。ルールの正本は `docs/19_ui_production_playbook.md`（以下「プレイブック」）。本スキルは手順の圧縮のみで、規約本文はプレイブックを読むこと。

## Load Before Acting

- `docs/19_ui_production_playbook.md`（特に §0 原則とトリアージ、§2 品質基準、§4.4/§4.5 装飾・背景ルール、§5 実装中ルール、§8.5 既知ギャップ）
- 対象画面の参照画像（`reference/` 内の該当PNG）
- 対象画面のQAドキュメント（`design-qa.md` 等）にある **freeze値と不採用理由**（同じ案の再試行を避ける）
- 対象画面の振り返り（`docs/13`・`docs/17` が該当するなら）

## Workflow

1. **現状を最新化する**
   `tools/<screen>_visual_qa.sh` を実行して現状スクショ+参照横並び比較を再生成する。**スクリプトが無い画面（魚図鑑・釣り場マップ等）は最初にこれを作る**（`fight_visual_qa.sh` が雛形）。古いキャプチャ・デスクトップのウィンドウキャプチャを判断材料にしない。

2. **差分をトリアージする**
   横並び比較から差分を列挙し、P1（破綻: 見切れ・省略・重なり・素材未表示・読めないゲージ）/ P2（素材・構成差分）/ P3（好み・数px）に分類して報告する。**このとき §8.5 の既知ギャップ（共通キット未整備、情報重複、装飾過多など）に該当するものは画面個別の問題ではなく横断工事として扱う。**

3. **P1を先に全部直す**
   P1は安く直せて未完成感の大半を占める。素材・構成に触る前に潰す。

4. **P2から1フェーズだけ選ぶ**
   背景・主役素材・枠・フォント等を同時に触らない。選定基準は「全画面比較で一番大きく効く差分」。構成ズレ（参照に無い要素、状態合成モックの詰め込み、装飾階層違反）があるなら素材より先に構成を直す。

5. **候補を作り、比較で採用判定する**
   発注仕様 → 生成 → 統一処理（プレイブック §3.3）→ contact sheet → 既存スロットへ仮適用 → 現行/候補/参照の全画面比較。**現行に明確に勝つ場合だけ採用。** 少し違うだけ・一部だけ良い候補は不採用にし、理由を記録する。

6. **記録して収束する**
   `./tools/validate_project.sh` + 該当smoke（UI変更でも釣行継続・港戻り等のフロー検証を省かない）→ 採用値・freeze値・不採用理由をQAドキュメントへ。P3だけが残ったら作業を終了する（P3を理由に続行しない）。

## Acceptance Gate

- 対象フェーズの変更が、参照との全画面横並び比較で**変更前に明確に勝っている**
- P1がゼロ（見切れ・省略・重なり・素材未表示なし）
- freeze値を動かしていない（動かした場合はP1再発の証拠と新しい採用値を記録済み）
- validate + 該当smokeが通る
- QAドキュメントに判断ログが残っている

## Hard Rules

- freeze値をP3（好み）を理由に再調整しない
- 数px・明度の微調整で素材品質不足を埋めようとしない（3回で見切って素材フェーズへ）
- パーツ単体の見栄えで採用判定しない（最終判断は全画面）
- フォントの全画面一括置換をしない
- 行レベルの金縁フレーム・行端飾りを追加しない（§4.4）
- 明るい背景の上へスクリムなしで情報パネルを載せない（§4.5）
