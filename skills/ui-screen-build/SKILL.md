---
name: ui-screen-build
description: Zero-to-one implementation of a NEW game screen UI in this repo. Use when the user asks to create/implement a new screen (新しい画面を作る, ○○画面を実装, ゼロイチ実装) targeting a reference image in `reference/`, adding a new `src/ui/*_screen.gd`, or building a screen that does not exist yet. For improving an EXISTING screen use ui-screen-uplift instead; for the cooking/meal/level-up flow use tsuri-cooking-showcase-uplift instead.
---

# UI Screen Build（新画面ゼロイチ実装）

## Purpose

新しい画面UIを、参照画像から迷いなく「v1合格（本番寄り80点）」まで持っていく。ルールの正本は `docs/19_ui_production_playbook.md`（以下「プレイブック」）。本スキルは手順の圧縮のみで、規約本文はプレイブックを読むこと。

## Load Before Acting

- `docs/19_ui_production_playbook.md`（全編。特に §0 原則、§1 分解、§2.1 v1完了条件、§3 共通キット、§4 スタイルガイド、§8.5 既知ギャップ）
- 対象画面の参照画像（`reference/` 内の該当PNG）
- 対象画面の仕様doc（`docs/` 内にあれば）
- 類似実装の見本: `src/ui/components/fight_status_bar.gd`、`src/ui/fishing_spot_select_screen.gd`（素材+runtime分担の実例）
- `src/ui/palette.gd` / `src/ui/game_fonts.gd`

## Workflow

1. **分解ドキュメントを書く（実装より先。省略禁止）**
   プレイブック §1 の観点で参照画像を分解し、画面spec doc（無ければ新規 `docs/NN_<screen>_spec.md`）へ記録する:
   - 参照画像が1状態か複数状態の合成モックか。合成なら状態→画面/オーバーレイの対応表
   - 存在する領域 / **存在しない領域**（作りたくなるが参照に無いもの）
   - 主操作（1つ）と補助操作
   - PNG素材が担う部分 / runtime描画が担う部分
   - 共通キットで賄う部品 / この画面専用の一点物
   分解結果に不確実な解釈があればユーザーに確認してから進む。

2. **§8.5 先行工事の状態を確認する**
   `assets/showcase/common/` が未整備の間は、枠・帯・ボタンは水中ファイト採用素材（`assets/showcase/underwater/`）系統から流用・昇格する。他画面のフォルダを直接参照しない。上部ステータスクラスタは `FightStatusBar` の汎用化を優先し、画面ローカル再実装しない。

3. **smoke観点を先に定義する**
   新UX契約として「存在すべき要素」「存在してはいけない要素」「接続するゲームフロー（trip_stats等）」を列挙し、`tools/<screen>_smoke.gd` の検証観点にする。

4. **構成フェーズ**
   共通部品とプレースホルダで領域構成・主導線・情報階層を組む。`tools/<screen>_visual_qa.sh` を最初に作り（`fight_visual_qa.sh` が雛形）、実スクショ+参照横並びで構成一致を確認。文字の見切れ・省略をゼロにする（全Labelに `clip_text` + `text_overrun_behavior`、ただし通常データで省略が発動しない幅設計）。

5. **素材フェーズ（1回につき1スロット）**
   発注仕様（`docs/12_underwater_fight_production_asset_brief.md` 形式）→ 生成 → 統一処理（パレット寄せ・解像度規約・なじませ。プレイブック §3.3）→ contact sheet 比較 → 仮適用 → 全画面比較。**現行に明確に勝つ場合だけ採用**し、採用/却下理由を記録。

6. **収束**
   プレイブック §2.1 のv1チェックリストを全項目確認 → `./tools/validate_project.sh` + smoke → 採用値をfreezeとして画面別QAドキュメントへ記録。v2（90点）作業は別フェーズとして残課題を列挙して終了。

## Acceptance Gate

プレイブック §2.1 の全項目。特に落としやすいもの:

- 同一情報を同一画面に2箇所表示していない
- 行レベルに金縁フレーム・行端飾りが無い（§4.4）
- 一覧系なら背景が密閉型かスクリム減光型になっている（§4.5）
- `tools/<screen>_visual_qa.sh` が存在し再実行可能

## Hard Rules

- `reference/*.png` をゲームに直接インポートしない
- 日本語テキストをPNGへ焼き込まない
- 色は `Palette.*` 参照。ハードコードhexを書かない
- 参照に存在しない要素を実装しない（欲しければ先にユーザー確認）
- 分解ドキュメントなしで `.gd` を書き始めない
