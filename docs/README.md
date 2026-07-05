# docs 索引

最終更新: 2026-07-05

ドキュメントの現在の位置づけ一覧。**迷ったら docs/19（ルールの正本）→ docs/26（作戦台帳）→ docs/qa/（画面別freeze値）の順に読む。**

## 状態の意味

- **正本**: 現在のルール・数値の正。矛盾したらこちらが勝つ
- **現行**: 進行中の計画、または今も参照する仕様・発注書
- **履歴**: 完了した作業の記録・教訓。読み物としては有効だが、値の正は docs/qa/ 側
- **アーカイブ**: `docs/archive/` へ移動済み。世代交代して役目を終えたもの

## 基盤仕様（00–09）

| doc | 状態 | 備考 |
|---|---|---|
| `00_プロジェクト概要.md` | 現行 | |
| `01_要件定義書.md` | 現行 | |
| `02_ゲームデザイン仕様.md` | 現行 | |
| `03_画面遷移とUI.md` | 現行 | |
| `04_技術設計.md` | 現行 | |
| `05_データ仕様.md` | 現行 | |
| `06_実装ロードマップ.md` | 現行 | フェーズ進捗のチェックリスト |
| `07_テスト計画.md` | 現行 | |
| `08_独自性と権利メモ.md` | 現行 | |
| `09_パラメータ調整表.md` | **正本** | ゲーム数値の正。docs/11 等より優先 |

## UI制作ルール・計画

| doc | 状態 | 備考 |
|---|---|---|
| `10_UIクオリティ向上マスタープラン.md` | 現行 | 「何を目指すか」。「どう進めるか」は docs/19 |
| `19_ui_production_playbook.md` | **正本** | UI作業ルールの正。全UI作業はここに従う |
| `26_refactor_orchestration_plan.md` | 現行 | リファクタ作戦台帳 |
| `27_retention_expansion_plan.md` | 現行 | 第2次拡張計画 |
| `24_gameplay_expansion_plan.md` | 現行 | 第1次拡張計画（docs/27 の前提）。**番号24が重複** |
| `28_harbor_return_placement_unification.md` | 現行 | 「港へ戻る」右下統一の実装指示書（Codex向け） |

## 画面別の仕様・振り返り（実装完了分は「履歴」）

freeze値・不採用リストの正は `docs/qa/<screen>_qa.md`。以下は設計意図と教訓の記録。

| doc | 状態 | 備考 |
|---|---|---|
| `11_underwater_fight_showcase.md` | 履歴 | 水中ファイトの品質基準の原典。freeze の正は `docs/qa/underwater_fight_qa.md` |
| `12_underwater_fight_production_asset_brief.md` | 現行 | 素材発注仕様の型（docs/19 が「docs/12方式」として参照） |
| `13_underwater_fight_process_lessons.md` | 履歴 | 教訓は docs/19 へ反映済み |
| `14_opening_title_showcase.md` | 現行 | タイトル画面の採用素材構成 |
| `15_fishing_spot_encounter_spec.md` | **正本** | 出現設計の正 |
| `16_fishing_spot_map_screen_spec.md` | 履歴 | 実装完了。freeze は `docs/qa/fishing_spot_map_qa.md` |
| `17_boat_access_spec.md` | 現行 | 船アクセス仕様。**番号17が重複** |
| `17_fishing_spot_map_process_lessons.md` | 履歴 | 教訓は docs/19 へ反映済み。**番号17が重複** |
| `18_fish_book_ui_implementation_goal.md` | 履歴 | 実装完了。freeze は `docs/qa/fish_book_qa.md` |
| `20_status_screen_spec.md` | 履歴 | 実装完了 |
| `21_status_screen_build_process_lessons.md` | 履歴 | skills/ui-screen-build が参照 |
| `22_fish_book_book_frame_asset_brief.md` | 現行 | 素材再生成時に使用 |
| `23_fish_book_card_paper_asset_brief.md` | 現行 | 素材再生成時に使用 |
| `24_fish_book_portrait_asset_brief.md` | 現行 | 素材再生成時に使用。**番号24が重複** |
| `25_fish_market_screen_spec.md` | 履歴 | 実装完了。freeze は `docs/qa/fish_market_qa.md`。**番号25が重複** |
| `25_tackle_shop_spec.md` | 履歴 | 実装完了。freeze は `docs/qa/tackle_shop_qa.md`。**番号25が重複** |

## アーカイブ済み（docs/archive/）

| doc | 移動日 | 世代交代先 |
|---|---|---|
| `archive/12_cooking_showcase_qa.md` | 2026-07-05 | `docs/qa/cooking_qa.md`（freeze値・判断ログはすべて移行済み） |

## 番号重複について

12（解消済み）・17・24・25 は歴史的経緯で番号が重複している。被参照が多くリネームのコストが利益を上回るため、番号は据え置き、本索引で区別する。**新規docは既存の最大番号+1を使い、重複させない**（次は 29）。

## 運用ルール

- 新規docを作ったら本索引に1行追加する
- 画面のQA記録は本フォルダに作らず `docs/qa/<screen>_qa.md`（書式: `docs/qa/README.md`）へ
- 役目を終えたdocは削除せず `docs/archive/` へ移し、本索引のアーカイブ表へ移動理由を書く
