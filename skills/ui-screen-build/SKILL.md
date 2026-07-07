---
name: ui-screen-build
description: Zero-to-one implementation of a game screen UI in this repo, OR formalizing an existing placeholder screen into production-grade v1, OR adding a NEW UI block/layout to an existing screen (状態別HUDバー・新パネルゾーンの追加, 既存画面への新レイアウト追加 — apply this skill's 分解・共通キット配線 gates to the new block, combined with ui-screen-uplift's reference-distance gate). Use when the user asks to create/implement a new screen (新しい画面を作る, ○○画面を実装, ゼロイチ実装) targeting a reference image in `reference/`, adding a new `src/ui/*_screen.gd`, or when an existing simple/placeholder screen (簡易実装) should be rebuilt to match a reference image for the first time (○○画面を正式化, 本番寄りに置き換え). For polishing a screen that already passed v1 use ui-screen-uplift instead; for the cooking/meal/level-up flow use tsuri-cooking-showcase-uplift instead.
---

# UI Screen Build（新画面ゼロイチ実装・既存簡易画面の正式化）

## Purpose

画面UIを、参照画像から迷いなく「v1合格（本番寄り80点）」まで持っていく。対象は「完全新規画面」と「既存簡易画面の正式化」の両方（後者の実例: `docs/21_status_screen_build_process_lessons.md`）。ルールの正本は `docs/19_ui_production_playbook.md`（以下「プレイブック」）。本スキルは手順の圧縮のみで、規約本文はプレイブックを読むこと。

## Load Before Acting

- `docs/19_ui_production_playbook.md`（全編。特に §0 原則、§1 分解、§2.1 v1完了条件、§3 共通キット、§4 スタイルガイド、§8.5 既知ギャップ）
- 対象画面の参照画像（`reference/` 内の該当PNG）
- 対象画面の仕様doc（`docs/` 内にあれば）
- 類似実装の見本: `src/ui/components/fight_status_bar.gd`、`src/ui/fishing_spot_select_screen.gd`（素材+runtime分担の実例）
- `docs/21_status_screen_build_process_lessons.md`（本スキル適用の振り返り。既存簡易画面の正式化の実例）
- `src/ui/palette.gd` / `src/ui/game_fonts.gd`

## Workflow

0. **既存画面か新規画面かを最初に判定する**
   対象の `src/ui/<screen>_screen.gd`、`main.gd` のroute、`tools/<screen>_preview.tscn` の有無を確認する。
   - **既存簡易画面の正式化**の場合: 新規ファイル追加ではなく既存 `*_screen.gd` の責務整理として扱い、既存route・previewを再利用する。旧構成のうち撤去するもの（他画面へ責務分離する領域）を分解ドキュメントに明記する。
   - **完全新規**の場合: route/preview/screen を新設する。
   - **既存画面への新UIブロック追加**（状態別HUDバー・新パネルゾーン等）の場合: 新ブロック部分に本スキルの分解（手順1）・共通キット配線（手順4）・Acceptance Gateを適用し、参照距離の合否判定は `ui-screen-uplift` のAcceptance Gateを併用する。「新画面ではないから」を理由にどちらのゲートも省略しない（2026-07-07 READYバーの再発防止）。

1. **分解ドキュメントを書く（実装より先。省略禁止）**
   プレイブック §1 の観点で参照画像を分解し、画面spec doc（無ければ新規 `docs/NN_<screen>_spec.md`）へ記録する:
   - 参照画像が1状態か複数状態の合成モックか。合成なら状態→画面/オーバーレイの対応表
   - 存在する領域 / **存在しない領域**（作りたくなるが参照に無いもの）
   - **参照に在るが採用しない要素**と理由（AI生成参照は情報重複・実装矛盾を含むことがある。docs/19 と矛盾する箇所は docs/19 を優先し、非採用と判断根拠を明記する。例: Lv/所持金の重複表示→上部バーへ集約）
   - 主操作（1つ）と補助操作
   - PNG素材が担う部分 / runtime描画が担う部分
   - 共通キットで賄う部品 / この画面専用の一点物
   分解結果に不確実な解釈があればユーザーに確認してから進む。

2. **§8.5 先行工事の状態を確認する**
   `assets/showcase/common/` が未整備の間は、枠・帯・ボタンは水中ファイト採用素材（`assets/showcase/underwater/`）系統から流用・昇格する。他画面のフォルダを直接参照しない。上部ステータスクラスタは `FightStatusBar` の汎用化を優先し、画面ローカル再実装しない。

3. **smoke観点を先に定義する**
   新UX契約として「存在すべき要素」「存在してはいけない要素」「接続するゲームフロー（trip_stats等）」を列挙し、`tools/<screen>_smoke.gd` の検証観点にする。

4. **構成フェーズ**
   領域構成・主導線・情報階層を組む。**パネル・枠・帯・ボタン・ゲージ・キーキャップは、この時点から共通キット（`assets/showcase/common/` + 昇格素材）のPNGを配線する（§3.2）。プレースホルダにしてよいのは一点物スロット（背景・キャラ・料理・魚アート等）だけで、キット部品をStyleBoxFlat / draw_rect で仮組みして後回しにしない**（後回しにした仮組みがそのまま合格・freezeされるのが再発パターン。docs/33 §2）。`tools/<screen>_visual_qa.sh` を最初に作り（`fight_visual_qa.sh` が雛形）、実スクショ+参照横並びで構成一致を確認。
   - **preview seed は参照密度に合わせて設計する**（visual QA作成と同時。空データや数件だけの簡易seedでは完成イメージとの比較にならない）。所持品・ログ・発見済み/未発見・装備中などを参照画像と同程度の密度で入れ、さらに**現実的に最長のデータ**（長い船名・食事効果名・魚名など）を必ず含めて、文字省略P1が初回スクショで発火するようにする。
   - 文字の見切れ・省略をゼロにする（全Labelに `clip_text` + `text_overrun_behavior`、ただし通常データで省略が発動しない幅設計）。カード・バッジ等の複合部品**内部**のテキストも対象。

5. **素材フェーズ（一点物のみ原則v2送り）**
   **v1は共通キット（`common/` + 昇格素材）だけで構成を固定する。v2送りにしてよいのは画面専用の一点物PNGだけで、キット部品の配線は構成フェーズで完了しているのが前提**（「素材はv2送り」を理由にフラット描画のまま収束しない）。専用PNGが必要と判明したものはv2候補として列挙するに留め、v1内で生成に着手しない（ユーザー合意がある場合のみ例外）。着手する場合は1回につき1スロット: 発注仕様（`docs/12_underwater_fight_production_asset_brief.md` 形式）→ 生成 → 統一処理（パレット寄せ・解像度規約・なじませ。プレイブック §3.3）→ contact sheet 比較 → 仮適用 → 全画面比較。**現行に明確に勝つ場合だけ採用**し、採用/却下理由を記録。

6. **収束**
   プレイブック §2.1 のv1チェックリストを全項目確認 → `./tools/validate_project.sh` + smoke → 採用値をfreezeとして画面別QAドキュメント `docs/qa/<screen>_qa.md` へ記録（新設。書式は `docs/qa/README.md`。freeze値は表で書く）。判断根拠の比較画像を `docs/qa/evidence/<screen>/` へコピー。v2（90点）作業（専用PNG生成・看板品質の質感追求を含む）は別フェーズとして残課題を列挙して終了。

## Acceptance Gate

プレイブック §2.1 の全項目。特に落としやすいもの:

- **パネル・枠・帯・主操作ボタンが共通キット（`assets/showcase/common/` + 昇格素材）のPNGで構成されており、StyleBoxFlat / draw_rect のフラット描画で金縁・紙面・CTAの質感を代替していない**（§2.1「質感が必要な部位がPNG素材化済み」・§3.2）
- 同一情報を同一画面に2箇所表示していない
- 行レベルに金縁フレーム・行端飾りが無い（§4.4）
- 一覧系なら背景が密閉型かスクリム減光型になっている（§4.5）
- `tools/<screen>_visual_qa.sh` が存在し再実行可能
- **原寸スクショでカード・バッジ等の複合部品内部のテキストに見切れ・省略が無い**（縮小した比較ボードだけで判断しない。密度の高い部品は等倍で確認する）
- 既存画面の正式化の場合: 撤去対象の旧構成が残っていないことをsmokeで検証している

## Hard Rules

- `reference/*.png` をゲームに直接インポートしない
- 日本語テキストをPNGへ焼き込まない
- 色は `Palette.*` 参照。ハードコードhexを書かない
- 参照に存在しない要素を実装しない（欲しければ先にユーザー確認）
- 参照に在っても docs/19 と矛盾する要素（情報重複等）はそのまま実装しない。非採用として分解ドキュメントに記録する
- 分解ドキュメントなしで `.gd` を書き始めない
- v1で専用PNG生成に着手しない（ユーザー合意がある場合を除く）
- **キット部品（パネル・枠・帯・ボタン・ゲージ）をStyleBoxFlat / draw_rect / PILの再発明で代替しない**。既存キットの配線が常に先。キットに無ければcommonへ追加/昇格してから使う
- 既存画面への新UIブロック追加を「新画面ではない」ことを理由に本スキルのゲート適用外にしない
