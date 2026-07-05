# 調理場 QA判断ログ

最終更新: 2026-07-05 / 状態: 調理場未使用detail helper削除完了
参照画像: reference/cooking_flow/01_cook_select_concept.png, reference/cooking_flow/02_meal_result_concept.png, reference/cooking_flow/03_exp_gain_concept.png, reference/cooking_flow/04_level_up_overlay_concept.png, reference/cooking_flow/05_status_summary_concept.png
QA更新コマンド: ./tools/cooking_visual_qa.sh

## 1. freeze値（正本）

現在有効な値だけを書く。値を更新したら該当行を**上書き**する（追記して古い行を残さない）。

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 共通Labelのoverrun既定 | `TextServer.OVERRUN_TRIM_ELLIPSIS` | `src/ui/screen_base.gd` `ScreenBase.make_label` | `make_body_label` / `make_shadow_label` 由来の調理場ラベルで `clip_text` だけが立つ状態を避ける。省略が通常データで発動しないことはvisual QAで確認する |

## 2. 不採用・再試行禁止リスト

| 案 | 却下理由 | 判断日 |
|---|---|---|

## 3. 微調整カウンタ

| パラメータ | 回数 | 直近の変更内容 | 状態 |
|---|---|---|---|
| COOK_SELECT 料理カード星ランク表示 | 1 | Label幅中央寄せを試したが実スクショで星文字が弱く、runtimeポリゴン描画 `RecipeStarRank` へ切替 | 完了 |

## 4. 暫定判定・再検証TODO

なし。

## 5. 現在の残ギャップ

- P2: レアリティ表示の `RarityStyles` 横展開は未実施。
- R1: `src/ui/cooking_screen.gd` の画面固有ハードコード色は、背景fallback以外を処理済み。今回触った左魚リスト周辺のruntime色は `Palette.COOKING_FISH_*`、見出しリボン周辺は `Palette.COOKING_SECTION_RIBBON_*`、料理カード/中央料理グリッド外枠周辺は `Palette.COOKING_RECIPE_*`、下部バー周辺は `Palette.COOKING_PREP_*`、右詳細パネルactive runtime色は `Palette.COOKING_DETAIL_*`、調理ボタン周辺は `Palette.COOKING_ACTION_*`、料理図鑑ボタン周辺は `Palette.COOKING_RECIPE_BOOK_BUTTON_*`、小アイコン/アクションキュー周辺は `Palette.COOKING_SMALL_ICON_*` / `Palette.COOKING_ACTION_CUE_*`、結果サマリーカード周辺は `Palette.COOKING_SUMMARY_CARD_*` / `Palette.COOKING_RESULT_TITLE_OUTLINE`、背景glazeは `Palette.COOKING_BG_GLAZE` へ移行済み。未使用detail helper由来のhexは削除済み。残りは背景fallbackのPalette移行。
- 監査: `tools/cooking_layout_audit.tscn` / `tools/cooking_content_audit.tscn` / `./tools/cooking_visual_qa.sh` はgreen。visual QAは状態間キャプチャ重複のfail guard追加済み。

## 6. フェーズスコープ宣言（作業中のみ）

なし。

## 7. 判断ログ（直近パスのみ）

2026-07-05: `unused detail helper cleanup` 完了。右詳細旧helperを削除し、未使用コード由来の直書き色を消した。

- 選定理由: `_add_detail_tile` / `_add_detail_pair_tile` / `_add_detail_pair_cell` は参照uplift後の実表示から呼び出されておらず、旧構成の直書き色だけを残していたため。
- 変えたもの: 上記3関数を削除。現行右詳細行で使う `_add_detail_story_row` は維持。
- 変えていないもの: §1 freeze値、レイアウト値、素材、表示文言、右詳細パネル構成、COOK_SELECT下部4区画、料理カード、調理報酬オーバーレイ、日本語PNG焼き込み。
- Palette: 新規定数なし。未使用コード削除による直書き色解消。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_unused_detail_helper_cleanup_select.png`, `docs/qa/evidence/cooking/2026-07-05_unused_detail_helper_cleanup_report.html`
- 判定: 実スクショと5状態visual QAでP1なし。これはUI upliftではなく未使用コード削除なので、cmp一致は完了条件にしていない。
- 検証: `./tools/cooking_visual_qa.sh`、`tools/cooking_content_audit.tscn`、`tools/cooking_layout_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`validate_project.sh` の ObjectDB/resource 警告はベースライン既知。
- 固定条件: 右詳細行は `_add_detail_story_row` と `Palette.COOKING_DETAIL_*` を現行経路とする。

2026-07-05: `cooking summary card palette R1 pass` 完了。調理場の結果サマリーカード周辺のactive runtime色をPalette用途名へ追加移行した。

- 選定理由: 食事結果/ステータス要約で使う `_summary_card` と結果タイトルに直書き色が残っており、COOK_SELECT後続状態のカード質感改善時に色責務が追いづらかったため。
- 変えたもの: 結果タイトルの影/アウトライン色、サマリーカードのfill/border/inner、カードタイトル文字色、値アウトライン色。
- 変えていないもの: §1 freeze値、レイアウト値、素材、表示文言、COOK_SELECT下部4区画、右詳細パネル、料理カード、調理報酬オーバーレイ、日本語PNG焼き込み。
- Palette: 新規 `Palette.COOKING_SUMMARY_CARD_*` / `Palette.COOKING_RESULT_TITLE_OUTLINE` を追加。理由は結果サマリーのカード色を、表示同値のままPalette正本へ移すため。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_summary_card_palette_result.png`, `docs/qa/evidence/cooking/2026-07-05_summary_card_palette_status.png`, `docs/qa/evidence/cooking/2026-07-05_summary_card_palette_report.html`
- 判定: 実スクショで食事結果/ステータス要約のカードと文字にP1なし。これは参照upliftではなくR1表示同値移行なので、cmp一致は完了条件にしていない。
- 検証: `./tools/cooking_visual_qa.sh`、`tools/cooking_content_audit.tscn`、`tools/cooking_layout_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`validate_project.sh` の ObjectDB/resource 警告はベースライン既知。
- 固定条件: 結果サマリーカードは `COOKING_SUMMARY_CARD_*`、結果タイトルアウトラインは `COOKING_RESULT_TITLE_OUTLINE` として扱う。

2026-07-05: `COOK_SELECT section ribbon palette R1 pass` 完了。参照uplift済みCOOK_SELECT見出しリボンのactive runtime fallback色をPalette用途名へ追加移行した。

- 選定理由: 左魚リストと中央料理リストの主要見出しリボンに、fallback frameの直書き色が残っており、次回のリボン素材/質感改善時に色責務が追いづらかったため。
- 変えたもの: `FishSectionRibbon` / `RecipeSectionRibbon` のfallback fill/border色。
- 変えていないもの: §1 freeze値、レイアウト値、素材、表示文言、リボン上のアイコン/文字色、魚リスト、料理カード、右詳細パネル、下部バー、背景、調理報酬オーバーレイ、日本語PNG焼き込み。
- Palette: 新規 `Palette.COOKING_SECTION_RIBBON_*` を追加。理由はCOOK_SELECTの主要見出し帯fallback色を、表示同値のままPalette正本へ移すため。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_section_ribbon_palette_select.png`, `docs/qa/evidence/cooking/2026-07-05_section_ribbon_palette_report.html`
- 判定: 実スクショでCOOK_SELECT左/中央の見出しリボンにP1なし。これは参照upliftではなくR1表示同値移行なので、cmp一致は完了条件にしていない。
- 検証: `./tools/cooking_visual_qa.sh`、`tools/cooking_content_audit.tscn`、`tools/cooking_layout_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`validate_project.sh` の ObjectDB/resource 警告はベースライン既知。
- 固定条件: COOK_SELECTの主要見出し帯fallback色は `COOKING_SECTION_RIBBON_*` として扱い、見出し文字/アイコン色は別スライスで扱う。

2026-07-05: `COOK_SELECT small icon palette R1 pass` 完了。参照uplift済みCOOK_SELECTのruntime小アイコン/アクションキュー色をPalette用途名へ追加移行した。

- 選定理由: 下部4区画、右詳細行、調理導線で使う `CookingSmallIcon` / `CookActionCueVisual` に多数の直書き色が残っており、次回のアイコン質感改善時に色責務が追いづらかったため。
- 変えたもの: プレイヤー/料理/魚/コイン/クーラー/本/EXP/効果/炎のruntime小アイコン色、調理ボタンへ向かうキュー線/皿面のactive/disabled色。
- 変えていないもの: §1 freeze値、レイアウト値、素材、表示文言、各ボタンstyle、魚リスト、料理カード、右詳細パネル構成、下部バー構成、背景、調理報酬オーバーレイ、日本語PNG焼き込み。
- Palette: 新規 `Palette.COOKING_SMALL_ICON_*` / `Palette.COOKING_ACTION_CUE_*` を追加。理由はCOOK_SELECTの小さなruntime装飾色を、表示同値のままPalette正本へ移すため。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_small_icon_palette_select.png`, `docs/qa/evidence/cooking/2026-07-05_small_icon_palette_report.html`
- 判定: 実スクショでCOOK_SELECT下部バー、右詳細行、調理導線の小アイコンにP1なし。これは参照upliftではなくR1表示同値移行なので、cmp一致は完了条件にしていない。
- 検証: `./tools/cooking_visual_qa.sh`、`tools/cooking_content_audit.tscn`、`tools/cooking_layout_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`validate_project.sh` の ObjectDB/resource 警告はベースライン既知。
- 固定条件: 小アイコン群は `COOKING_SMALL_ICON_*`、調理導線キューは `COOKING_ACTION_CUE_*` として扱い、ボタン本体の `COOKING_ACTION_*` とは分けて管理する。

2026-07-05: `COOK_SELECT recipe book button palette R1 pass` 完了。参照uplift済みCOOK_SELECT料理図鑑ボタンのactive runtime色をPalette用途名へ追加移行した。

- 選定理由: 中央料理グリッド外枠と調理ボタンのR1移行後も、副導線である「料理図鑑を見る」ボタンに枠normal/hover/pressedと文字状態の直書き色が残っており、次回の料理グリッド改善時に安全に触りづらかったため。
- 変えたもの: 料理図鑑ボタンのnormal/hover/pressed fallback色、hover/pressed文字色。
- 変えていないもの: §1 freeze値、レイアウト値、素材、表示文言、調理ボタン、左魚リスト、料理カード、右詳細パネル、下部バー、背景、調理報酬オーバーレイ、日本語PNG焼き込み。
- Palette: 新規 `Palette.COOKING_RECIPE_BOOK_BUTTON_*` を追加。理由は中央列の副導線ボタン色を、表示同値のままPalette正本へ移すため。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_recipe_book_button_palette_select.png`, `docs/qa/evidence/cooking/2026-07-05_recipe_book_button_palette_report.html`
- 判定: 実スクショでCOOK_SELECTの料理図鑑ボタン、ボタン文字、中央料理グリッドにP1なし。これは参照upliftではなくR1表示同値移行なので、cmp一致は完了条件にしていない。
- 検証: `./tools/cooking_visual_qa.sh`、`tools/cooking_content_audit.tscn`、`tools/cooking_layout_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`validate_project.sh` の ObjectDB/resource 警告はベースライン既知。
- 固定条件: 料理図鑑ボタンは `COOKING_RECIPE_BOOK_BUTTON_*` 系で扱い、調理実行ボタンの `COOKING_ACTION_*` とは分けて管理する。

2026-07-05: `COOK_SELECT cook button palette R1 pass` 完了。参照uplift済みCOOK_SELECT調理ボタンのactive runtime色をPalette用途名へ追加移行した。

- 選定理由: COOK_SELECTの主導線である調理ボタンに、枠4状態・文字状態・runtime鍋アイコン色の直書きが残っており、次回のボタン質感改善時に安全に触りづらかったため。
- 変えたもの: 調理ボタンのnormal/hover/pressed/disabled fallback色、hover/pressed/disabled文字色、runtime鍋アイコンのactive/disabled色。
- 変えていないもの: §1 freeze値、レイアウト値、素材、表示文言、料理図鑑ボタン、左魚リスト、料理カード、右詳細パネル、下部バー、背景、調理報酬オーバーレイ、日本語PNG焼き込み。
- Palette: 新規 `Palette.COOKING_ACTION_BUTTON_*` / `COOKING_ACTION_ICON_*` を追加。理由は調理ボタンとruntime鍋アイコン色を、表示同値のままPalette正本へ移すため。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_cook_button_palette_select.png`, `docs/qa/evidence/cooking/2026-07-05_cook_button_palette_report.html`
- 判定: 実スクショでCOOK_SELECTの調理ボタン、ボタン文字、鍋アイコンにP1なし。これは参照upliftではなくR1表示同値移行なので、cmp一致は完了条件にしていない。
- 検証: `./tools/cooking_visual_qa.sh`、`tools/cooking_content_audit.tscn`、`tools/cooking_layout_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`validate_project.sh` の ObjectDB/resource 警告はベースライン既知。
- 固定条件: COOK_SELECTの調理実行導線は `COOKING_ACTION_*` 系で扱い、料理図鑑ボタンは別スライスで扱う。

2026-07-05: `COOK_SELECT recipe grid palette R1 pass` 完了。参照uplift済みCOOK_SELECT中央料理グリッド外枠のactive runtime色をPalette用途名へ追加移行した。

- 選定理由: 料理カード本体は `Palette.COOKING_RECIPE_*` へ移行済みだったが、中央列の `RECIPE_GRID_FRAME` fallback色が直書きで残っており、次回の料理グリッド改善時に枠とカードの色責務が分かれにくかったため。
- 変えたもの: 中央料理グリッド外枠のfallback panel色。
- 変えていないもの: §1 freeze値、レイアウト値、素材、表示文言、料理カード内部、左魚リスト、右詳細パネル、下部バー、背景、調理報酬オーバーレイ、日本語PNG焼き込み。
- Palette: 新規 `Palette.COOKING_RECIPE_GRID_FILL` / `COOKING_RECIPE_GRID_BORDER` / `COOKING_RECIPE_GRID_INNER` を追加。理由は中央料理グリッド外枠色を、表示同値のままPalette正本へ移すため。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_recipe_grid_palette_select.png`, `docs/qa/evidence/cooking/2026-07-05_recipe_grid_palette_report.html`
- 判定: 実スクショでCOOK_SELECT中央料理グリッド、料理カード、料理図鑑ボタンにP1なし。これは参照upliftではなくR1表示同値移行なので、cmp一致は完了条件にしていない。
- 検証: `./tools/cooking_visual_qa.sh`、`tools/cooking_content_audit.tscn`、`tools/cooking_layout_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`validate_project.sh` の ObjectDB/resource 警告はベースライン既知。
- 固定条件: 料理カード内部と中央料理グリッド外枠は `COOKING_RECIPE_*` 系で扱い、次の調理場直接編集でも一括置換はしない。

2026-07-05: `COOK_SELECT fish list palette R1 pass` 完了。参照uplift済みCOOK_SELECT左魚リストのactive runtime色をPalette用途名へ追加移行した。

- 選定理由: 右詳細パネルR1移行後も、COOK_SELECT左列の魚リストにパネル枠・魚行・選択状態・所有/未所持tintの直書き色が残っており、次回の魚行改善時に再利用しづらかったため。
- 変えたもの: 左魚リストのパネル色、魚アイコン所有/未所持tint、魚名/所持数テキスト色、魚行の選択/所有/未所持フレーム色。
- 変えていないもの: §1 freeze値、レイアウト値、素材、表示文言、料理カード、右詳細パネル、下部バー、背景、調理報酬オーバーレイ、日本語PNG焼き込み。
- Palette: 新規 `Palette.COOKING_FISH_PANEL_*` / `COOKING_FISH_ICON_*` / `COOKING_FISH_NAME_*` / `COOKING_FISH_AMOUNT_*` / `COOKING_FISH_ROW_*` を追加。理由は左魚リストのactive runtime色を、表示同値のままPalette正本へ移すため。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_fish_list_palette_select.png`, `docs/qa/evidence/cooking/2026-07-05_fish_list_palette_report.html`
- 判定: 実スクショでCOOK_SELECT左魚リスト、魚名、所持数、未所持行、選択行にP1なし。これは参照upliftではなくR1表示同値移行なので、cmp一致は完了条件にしていない。
- 検証: `./tools/cooking_visual_qa.sh`、`tools/cooking_content_audit.tscn`、`tools/cooking_layout_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`validate_project.sh` の ObjectDB/resource 警告はベースライン既知。
- 固定条件: 次の調理場直接編集でも一括置換はせず、触るactive部品ごとにPalette移行を続ける。

2026-07-05: `COOK_SELECT detail palette R1 pass` 完了。参照uplift済み右詳細パネルのactive runtime色をPalette用途名へ追加移行した。

- 選定理由: COOK_SELECT 4スライス完了後の次作業として、台帳で調理場R1継続が最優先になっており、右詳細パネル内に前回触ったactive runtime色の直書きが残っていたため。
- 変えたもの: 右詳細パネルのfallback panel色、料理タイトル/サブタイトル、皿枠、必要素材/EXPアクセント、アクション帯、上書き注意バッジの色参照。
- 変えていないもの: §1 freeze値、レイアウト値、素材、表示文言、料理カード、下部バー、背景、調理報酬オーバーレイ、日本語PNG焼き込み。
- Palette: 新規 `Palette.COOKING_DETAIL_PANEL_*` / `COOKING_DETAIL_TITLE_*` / `COOKING_DETAIL_SUBTITLE_TEXT` / `COOKING_DETAIL_DISH_FRAME_*` / `COOKING_DETAIL_ACTION_FILL` / `COOKING_DETAIL_NOTE_*` / `COOKING_DETAIL_MATERIAL_ACCENT` / `COOKING_DETAIL_EXP_ACCENT` を追加。理由は右詳細パネルのactive runtime色を、表示同値のままPalette正本へ移すため。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_detail_palette_select.png`, `docs/qa/evidence/cooking/2026-07-05_detail_palette_report.html`
- 判定: 実スクショでCOOK_SELECTの右詳細パネル、料理タイトル、3行詳細、アクション帯にP1なし。これは参照upliftではなくR1表示同値移行なので、cmp一致は完了条件にしていない。
- 検証: `./tools/cooking_visual_qa.sh`、`tools/cooking_content_audit.tscn`、`tools/cooking_layout_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`validate_project.sh` の ObjectDB/resource 警告はベースライン既知。
- 固定条件: 次の調理場直接編集でも一括置換はせず、触るactive部品ごとにPalette移行を続ける。

2026-07-05: `COOK_SELECT background reveal reference-uplift` 完了。COOK_SELECT本体の余白/パネル間隔/glazeを調整し、厨房背景の見え方を参照へ寄せた。

- 選定理由: 右詳細パネル完了後のafterでもパネル群が横幅をほぼ覆い、参照のような左右パネル間/外周の厨房背景と暖色奥行きが弱かったため。
- 変えたもの: COOK_SELECT本体の左右8px余白、パネル間隔12px、厨房背景glazeの色/透明度、背景glazeのPalette定数。
- 変えていないもの: §1 freeze値、料理カード、魚リスト内容、下部バー、右詳細行、ヘッダー `PlayerStatusBar`、調理報酬オーバーレイ、日本語PNG焼き込み。
- 素材候補: 新規背景素材は採用していない。既存 `CookingAssets.COOKING_BG` を使い、暗いglazeとパネル間隔が背景を殺していたため、素材差し替えではなく見せ方の調整で前進した。
- Palette: 新規 `Palette.COOKING_BG_GLAZE` を追加。理由は今回触った背景glaze色をPalette正本へ移すため。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_background_before_after_ref.png`, `docs/qa/evidence/cooking/2026-07-05_background_select.png`, `docs/qa/evidence/cooking/2026-07-05_background_report.html`
- 判定: afterではパネル外周とパネル間に厨房背景が見え、青黒い暗幕感が弱まった。参照ほど背景面積は大きくないが、freeze値に触れずに奥行きの前進が判別できる。cmp一致は判定に使っていない。
- 検証: `./tools/cooking_visual_qa.sh`、`tools/cooking_content_audit.tscn`、`tools/cooking_layout_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`validate_project.sh` の ObjectDB/resource 警告はベースライン既知。
- 固定条件: COOK_SELECT本体は左右8px余白/パネル間隔12pxを現行の参照寄せ基準とする。COOK_SELECT 4スライス（料理カード/下部バー/右詳細パネル/背景）は完了。

2026-07-05: `COOK_SELECT detail panel reference-uplift` 完了。右詳細パネルの3行を帯/アイコン/右端バッジ構成へ寄せ、詳細行素材候補を採用した。

- 選定理由: 下部バー完了後のafterでも「次の釣行で得られる効果」行の `1回` が右端に浮いて見え、必要素材行/獲得EXP行も参照の帯・アイコン質感に届いていなかったため。
- 変えたもの: `cook_detail_row_frame.png`、右詳細パネルの必要素材/獲得EXP/次の釣行効果行、右端補足値のバッジ化、行タイトルへのruntime小アイコン追加、効果行見出しの短縮、右詳細行周辺のPalette定数、`tools/cooking_content_audit.gd` の表示契約。
- 変えていないもの: §1 freeze値、料理カード、魚リスト、下部バー、背景/左右余白、ヘッダー `PlayerStatusBar`、調理報酬オーバーレイ、日本語PNG焼き込み。
- 素材候補: `tools/generate_cooking_showcase_assets.py` で詳細行フレーム候補を生成し採用。候補は左のタイトル/アイコン帯、中央値、右バッジポケットを持ち、beforeより参照の情報帯構成へ近づいたため。
- Palette: 新規 `Palette.COOKING_DETAIL_*` を追加。理由は右詳細行/バッジ/値のruntime色を、今回触った行から用途名定数へ移すため。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_detail_panel_before_after_ref.png`, `docs/qa/evidence/cooking/2026-07-05_detail_panel_select.png`, `docs/qa/evidence/cooking/2026-07-05_detail_panel_report.html`
- 判定: `1回` は右端バッジ内に整理され、必要素材/EXP/効果の各行にアイコン帯が入った。効果行の長い見出しは見切れ回避のため `次の釣行効果` に短縮し、実スクショで見切れなしを確認した。cmp一致は判定に使っていない。
- 検証: `./tools/cooking_visual_qa.sh`、`tools/cooking_content_audit.tscn`、`tools/cooking_layout_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`cooking_visual_qa.sh` は途中で透明キャプチャが1回発生したが、同一差分で再実行してgreen。`validate_project.sh` の ObjectDB/resource 警告はベースライン既知。
- 固定条件: 右詳細行の補足値（材料数、初回EXP、効果回数）は行内バッジとして扱う。次スライスは背景の見せ方に進める。

2026-07-05: `COOK_SELECT prep bar reference-uplift` 完了。下部バーを参照の4区画構成へ寄せ、下部バー素材候補を採用した。

- 選定理由: 料理カード完了後のafterでも下部は「現在の準備 / 効果中の料理 / クーラーボックス / 詳細」に留まり、参照の「プレイヤーLv / 効果中の料理 / クーラーボックス / 所持金」4区画の装飾フレーム構成へ未到達だったため。
- 変えたもの: 下部バー枠2枚（バー/カード）、COOK_SELECT下部4区画、COOK_SELECTではタイトルスロット/詳細ボタンを非表示にする状態制御、下部バー周辺のPalette定数、`tools/cooking_content_audit.gd` / `tools/cooking_layout_audit.gd` のCOOK_SELECT契約。
- 変えていないもの: §1 freeze値、料理カード、魚リスト、右詳細パネル、背景/左右余白、ヘッダー `PlayerStatusBar`、調理報酬オーバーレイ、日本語PNG焼き込み。
- 素材候補: `tools/generate_cooking_showcase_assets.py` で4区画トレイと下部カード枠候補を生成し採用。候補は4つの情報スロットと縦セパレータが読め、beforeより参照の下部バー構成へ近づいたため。
- 判断更新: 以前の「下部準備バーへLv/所持金カードを戻さない」は退行ゼロ/重複解消フェーズの暫定条件だった。今回のreference-upliftでは参照構成を優先し、4区画として小さく整理できたため再導入を採用した。
- Palette: 新規 `Palette.COOKING_PREP_*` を追加。理由は下部バー/カード/タイトル/値のruntime色を、今回触った行から用途名定数へ移すため。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_prep_bar_before_after_ref.png`, `docs/qa/evidence/cooking/2026-07-05_prep_bar_select.png`, `docs/qa/evidence/cooking/2026-07-05_prep_bar_report.html`
- 判定: afterではプレイヤーLv、効果中の料理、クーラーボックス、所持金が装飾枠で区切られ、参照の下部4区画へ前進した。所持金は `1,250 G` 表記へ合わせ、テキストの見切れなしを実スクショで確認した。cmp一致は判定に使っていない。
- 検証: `./tools/cooking_visual_qa.sh`、`tools/cooking_content_audit.tscn`、`tools/cooking_layout_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`validate_project.sh` の ObjectDB/resource 警告はベースライン既知。
- 固定条件: COOK_SELECT下部バーは4区画構成を正とする。ヘッダー `PlayerStatusBar` は維持し、次スライスは右詳細パネルへ進める。

2026-07-05: `COOK_SELECT recipe card reference-uplift` 完了。料理カードを参照の3段構成へ寄せ、カード枠素材候補を採用した。

- 選定理由: `docs/qa/evidence/cooking/2026-07-05_layout_audit_repair_select.png` と `reference/cooking_flow/01_cook_select_concept.png` の横並びで、現行はカード上部タイトル帯 / 中央皿画像 / 下部星ランク+魚アイコンの分離が弱く、docs/19の順序では素材質感フェーズに入るため。
- 変えたもの: 料理カード枠4枚（通常/選択/皿サムネ/素材フッター）、カード内タイトル・皿・星・素材行の縦配分、星ランクのruntimeポリゴン描画、料理カード周辺のPalette定数、`tools/cooking_content_audit.gd` の星ランク契約。
- 変えていないもの: §1 freeze値、魚リスト、右詳細パネル、画面下部バー、背景/左右余白、調理報酬オーバーレイ、日本語PNG焼き込み。
- 素材候補: `tools/generate_cooking_showcase_assets.py` でカード枠候補を生成し採用。候補はカード上部にタイトル帯、中央に皿窓、下部に星/素材ソケットを持ち、beforeより参照の読み方に近づいたため。
- Palette: 新規 `Palette.COOKING_RECIPE_*` を追加。理由は料理カード固有のタイトル/星/フッター/カード状態/サムネ/素材行の色を、今回触ったruntime行から用途名定数へ移すため。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_recipe_card_before_after_ref.png`, `docs/qa/evidence/cooking/2026-07-05_recipe_card_select.png`, `docs/qa/evidence/cooking/2026-07-05_recipe_card_report.html`
- 判定: beforeではタイトル文字がカード絵へ沈み、星ランクが実質読めなかった。afterではタイトル帯、皿画像、星ランク+魚アイコンの下部ソケットが分かれ、参照構成への前進が第三者に判別できる。cmp一致は判定に使っていない。
- 検証: `./tools/cooking_visual_qa.sh`、`tools/cooking_content_audit.tscn`、`tools/cooking_layout_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`validate_project.sh` の ObjectDB/resource 警告はベースライン既知。
- 固定条件: COOK_SELECT料理カードの日本語タイトル・星ランク・素材数値はruntime描画のまま維持する。参照化の次スライスは下部バーで、カード幅/背景余白には波及させない。

2026-07-05: `layout audit repair` 完了。layout audit失敗を実スクショで確認し、EXP_GAIN / LEVEL_UP_OVERLAY / STATUS_SUMMARY の文字欠けP1と、visual QAの状態キャプチャ重複を修正した。

- 選定理由: `tools/cooking_layout_audit.tscn` の既存失敗が、実スクショ上でもEXPタイトル・レベルアップ詳細・ステータス文字の欠落として再現し、`docs/19` §2.1の文字見切れP1に該当したため。
- 変えたもの: 調理報酬/ステータス/レベルアップ各パネルのLabel最小高、EXP演出レイヤー、レベルアップのステータス行・解放帯のruntime文字描画、`tools/cooking_preview.gd` の状態別SubViewport更新、`tools/cooking_visual_qa_check.py` の重複キャプチャ検出。
- 変えていないもの: reference画像の採用/不採用、freeze表、料理カード構成、魚素材、`src/ui/cooking_screen.gd` 全体R1、`RarityStyles` 横展開。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_layout_audit_repair_select.png`, `docs/qa/evidence/cooking/2026-07-05_layout_audit_repair_result.png`, `docs/qa/evidence/cooking/2026-07-05_layout_audit_repair_exp.png`, `docs/qa/evidence/cooking/2026-07-05_layout_audit_repair_levelup.png`, `docs/qa/evidence/cooking/2026-07-05_layout_audit_repair_status.png`, `docs/qa/evidence/cooking/2026-07-05_layout_audit_repair_report.html`
- 判定: EXP_GAINは見出し・EXP値・進捗・メッセージが読める。LEVEL_UP_OVERLAYはタイトル、Lv遷移、4ステータス行、解放帯が読める。STATUS_SUMMARYはカード見出し・数値・本文が読める。5状態キャプチャはsha256がすべて異なり、重複/透明キャプチャなし。
- 検証: `./tools/cooking_visual_qa.sh`、`tools/cooking_layout_audit.tscn`、`tools/cooking_content_audit.tscn` green。スライス完了検証として `cooking_flow_smoke` / `save_system_verify.sh` / `validate_project.sh` はコミット前に実行する。
- 固定条件: visual QAで3状態以上が同一ハッシュになった場合はfail扱い。調理フローの表示完了は実スクショで確認し、layout audit greenだけを根拠に完了扱いしない。

2026-07-05: `status de-dup pass` 完了。COOK_SELECTヘッダーのローカルLv/EXP/所持金クラスタを共通 `PlayerStatusBar` に置き換え、下部「現在の準備」バーから重複するプレイヤーLv/EXPカード・所持金カードを撤去した。

- 変えたもの: `src/ui/cooking_screen.gd` のCOOK_SELECTヘッダーと下部準備バー。古い構成を正としていた `tools/cooking_content_audit.gd` / `tools/cooking_layout_audit.gd` のCOOK_SELECT契約。
- 変えていないもの: 料理カード、魚行、詳細カード、報酬オーバーレイ、ステータス詳細オーバーレイ、素材差し替え、`RarityStyles` 横展開、調理場全体の最終アート品質。
- Palette: 今回触ったヘッダーfallback色を `Palette.COOKING_TITLE_FALLBACK_BG` / `Palette.COOKING_WOOD_BORDER` / `Palette.COOKING_GOLD_TRIM` へ表示同値で移した。`cooking_screen.gd` 全体のR1は未完。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_status_dedupe_before_after_select.png`, `docs/qa/evidence/cooking/2026-07-05_status_dedupe_select.png`, `docs/qa/evidence/cooking/2026-07-05_status_dedupe_report.html`
- 判定: COOK_SELECTで上部 `PlayerStatusBar` に Lv/装備/所持金がまとまり、下部は「効果中の料理」「クーラーボックス」「詳細」に整理。実スクショで重複Lv/EXP・所持金カードの撤去とP1なしを確認。
- 検証: `./tools/cooking_visual_qa.sh`、`cooking_flow_smoke`、全UI smoke、`./tools/save_system_verify.sh`、`./tools/validate_project.sh`、`tools/cooking_content_audit.tscn` green。`tools/cooking_layout_audit.tscn` は既存の報酬/ステータス詳細ラベル高さ検出で失敗するが、今回追加/撤去したCOOK_SELECT契約のgrep確認では失敗なし。
- 固定条件: COOK_SELECTのLv/装備/所持金はヘッダーの `PlayerStatusBar` を正とし、下部準備バーへ同じ情報カードを戻さない。
