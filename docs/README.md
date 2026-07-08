# docs 索引

最終更新: 2026-07-07

## 1. 分類の定義

- **正本**: 現在のルール・数値の正。矛盾したらこちらが勝つ
- **現行**: 進行中の計画、または今も参照する仕様・発注書
- **履歴**: 完了した作業の記録・教訓。読み物としては有効だが、値の正は docs/qa/ 側
- **アーカイブ**: `docs/archive/` へ移動済み。世代交代して役目を終えたもの

## 2. 状態管理の運用ルール

- 各フェーズ・トラックの進行状況の正本は **`docs/30_v2_expansion_overview.md` §6**。個別docのヘッダに進行状態を書き続けない（書く場合は「進行状況は docs/30 参照」とする）
- 新規docを作ったら**同じコミットで**本索引に1行追加する
- 役目を終えたdocは `docs/archive/` へ移動し、参照元のパスを修正する
- 番号は既存最大+1を使う。17 / 24 / 25 / 28 の番号重複は歴史的経緯であり、**リネームはしない**（リンク切れ防止）

## 3. 読み順の推奨

1. `docs/19_ui_production_playbook.md` — UI作業ルールの正本
2. `docs/30_v2_expansion_overview.md` — V2拡張台帳・現在地
3. 実装対象の仕様doc（現在は `docs/39_underwater_fight_ui_redesign_spec.md` §0 のドキュメントマップ）
4. `docs/qa/` — 画面別freeze値・不採用リスト

## 4. 索引本体

番号順。`docs/qa/`（freeze値の正本）と `docs/v2/E*`（V2フェーズ仕様の正本）は番号体系外のため、正本として別途注記する。

| doc | 1行説明 | 分類 |
|---|---|---|
| `00_プロジェクト概要.md` | プロジェクト全体の概要 | 現行 |
| `01_要件定義書.md` | MVP要件定義（初期版） | 履歴 |
| `02_ゲームデザイン仕様.md` | ゲームデザインの基本仕様 | 現行 |
| `03_画面遷移とUI.md` | 画面遷移とUI構成 | 現行 |
| `04_技術設計.md` | 技術アーキテクチャ設計 | 現行 |
| `05_データ仕様.md` | データ構造・カタログ仕様 | 現行 |
| `07_テスト計画.md` | テスト方針と計画 | 現行 |
| `08_独自性と権利メモ.md` | 独自性・権利・制作ルール | 現行 |
| `09_パラメータ調整表.md` | ゲーム数値の正。docs/11 等より優先 | **正本** |
| `10_UIクオリティ向上マスタープラン.md` | 「何を目指すか」。「どう進めるか」は docs/19 | 現行 |
| `11_underwater_fight_showcase.md` | 水中ファイトの品質基準の原典。freeze の正は `docs/qa/underwater_fight_qa.md` | 履歴 |
| `12_underwater_fight_production_asset_brief.md` | 素材発注仕様の型（docs/19 が「docs/12方式」として参照） | 現行 |
| `13_underwater_fight_process_lessons.md` | 水中ファイト制作の教訓。docs/19 へ反映済み | 履歴 |
| `14_opening_title_showcase.md` | タイトル画面の採用素材構成 | 現行 |
| `15_fishing_spot_encounter_spec.md` | 出現設計の正 | **正本** |
| `16_fishing_spot_map_screen_spec.md` | 釣り場マップ画面の実装仕様（完了）。freeze は `docs/qa/fishing_spot_map_qa.md` | 履歴 |
| `17_boat_access_spec.md` | 船アクセス仕様。**番号17が重複** | 現行 |
| `17_fishing_spot_map_process_lessons.md` | 釣り場マップ制作の教訓。docs/19 へ反映済み。**番号17が重複** | 履歴 |
| `18_fish_book_ui_implementation_goal.md` | 魚図鑑UI実装目標（完了）。freeze は `docs/qa/fish_book_qa.md` | 履歴 |
| `19_ui_production_playbook.md` | UI作業ルールの正。全UI作業はここに従う | **正本** |
| `20_status_screen_spec.md` | ステータス画面の実装仕様（完了） | 履歴 |
| `21_status_screen_build_process_lessons.md` | ステータス画面構築の教訓。skills/ui-screen-build が参照 | 履歴 |
| `22_fish_book_book_frame_asset_brief.md` | 魚図鑑・本枠素材の発注仕様。素材再生成時に使用 | 現行 |
| `23_fish_book_card_paper_asset_brief.md` | 魚図鑑・カード紙素材の発注仕様。素材再生成時に使用 | 現行 |
| `24_fish_book_portrait_asset_brief.md` | 魚図鑑・ポートレート素材の発注仕様。素材再生成時に使用。**番号24が重複** | 現行 |
| `24_gameplay_expansion_plan.md` | 第1次拡張計画（docs/27 の前提）。**番号24が重複** | 履歴 |
| `25_fish_market_screen_spec.md` | 魚市場画面の実装仕様（完了）。freeze は `docs/qa/fish_market_qa.md`。**番号25が重複** | 履歴 |
| `25_tackle_shop_spec.md` | タックルショップ画面の実装仕様（完了）。freeze は `docs/qa/tackle_shop_qa.md`。**番号25が重複** | 履歴 |
| `26_refactor_orchestration_plan.md` | 完了済みリファクタ作戦台帳。Smoke一覧・brief様式の参照先としては現役 | 履歴 |
| `28_harbor_return_placement_unification.md` | 「港へ戻る」右下統一の実装指示書 | 履歴 |
| `29_fish_size_and_tana_realism_spec.md` | 魚サイズ現実化とタナ（深さ）挙動修正のCodex向け実装指示書（完了） | 履歴 |
| `30_v2_expansion_overview.md` | V2拡張台帳。フェーズ順・確定事項・進行状況（§6）の正本 | **正本** |
| `31_asset_ledger.md` | 素材台帳（作者・ライセンス・入手元） | **正本** |
| `33_cooking_market_ui_uplift_plan.md` | 調理・魚市場UIクオリティ向上計画（現状監査＋作戦） | 現行 |
| `34_shark_pen_screen_spec.md` | サメの生簀画面 v1 実装仕様 | 現行 |
| `35_fish_asset_duplicate_fix_plan.md` | 魚素材の同一画像使い回し調査結果と修正計画 | 現行 |
| `36_shark_bait_ux_visibility_spec.md` | サメ餌魚の釣行中UX改善（演出・表示レイヤー）。**docs/38 実装完了後に履歴へ移す予定。消費仕様の正本は docs/38** | 現行 |
| `37_shark_bait_in_trip_management_design_note.md` | サメ餌魚の釣行中管理 再設計メモ（経緯・判断記録）。**docs/38 実装完了後に履歴へ移す予定。消費仕様の正本は docs/38** | 現行 |
| `38_shark_bait_ready_selector_spec.md` | サメ餌魚READYセレクタ＋レア度耐久チャージ 実装仕様（最優先） | 現行 |
| `39_underwater_fight_ui_redesign_spec.md` | 水中ファイト画面 基盤UI刷新 実装仕様（docs/38 完了後） | 現行 |
| `40_ready_bottom_bar_quality_priority_brief.md` | READY 下段バー品質優先 brief | 現行 |
| `41_e5_time_slots_implementation_review.md` | E5 時間帯 実装レビュー・港画面 UX / 釣行ビジュアル改善提案 | 現行 |

**番号体系外の正本**

| パス | 1行説明 | 分類 |
|---|---|---|
| `docs/qa/` | 画面別freeze値・不採用リスト・判断ログ（書式: `docs/qa/README.md`） | **正本** |
| `docs/v2/E*.md` | V2フェーズ別実装仕様（E0〜E11） | **正本** |

## 5. アーカイブ一覧（docs/archive/）

| doc | 移動日 | 理由 | 置き換え先 |
|---|---|---|---|
| `archive/06_実装ロードマップ.md` | 2026-07-07 | MVP後にフェーズ進捗の正本が docs/30 へ移行したため陳腐化 | `docs/30_v2_expansion_overview.md` |
| `archive/12_cooking_showcase_qa.md` | 2026-07-05 | freeze値・判断ログを docs/qa/ へ統合 | `docs/qa/cooking_qa.md` |
| `archive/27_retention_expansion_plan.md` | 2026-07-07 | V2体系（総覧＋フェーズ別doc）へ再編され superseded | `docs/30_v2_expansion_overview.md` + `docs/v2/` |
| `archive/28_retention_expansion_implementation_specs.md` | 2026-07-07 | 同上 | `docs/30_v2_expansion_overview.md` + `docs/v2/` |
| `archive/32_quest_board_screen_build_spec.md` | 2026-07-07 | E3実装済み・被参照ゼロ | — |
| `archive/32_nushi_fish_asset_brief.md` | 2026-07-07 | E2実装済み・被参照ゼロ | — |
