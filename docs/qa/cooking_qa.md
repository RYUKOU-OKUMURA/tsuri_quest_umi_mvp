# 調理場 QA判断ログ

最終更新: 2026-07-05 / 状態: 調理場cooking_screen R1完了 / COOK_SELECT仕上げ点検完了 / MEAL_RESULT / EXP_GAIN / LEVEL_UP_OVERLAY / STATUS_SUMMARY reference-uplift完了
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
| LEVEL_UP_OVERLAY 上部祝祭帯 | 3 | crown/laurel候補を生成。LEVEL UP文字拡大とLv行拡大は表示契約が落ちたため不採用、最終的にcrown/laurelとダイアログ寸法のみ採用 | 完了 |
| STATUS_SUMMARY カード密度/背景 | 3 | `status_card_frame.png` 候補生成、背景抜け、値プレート化を実施。半透明化したカード素材候補は不採用とし、素材生成を合成方式へ修正して不透明紙面で採用 | 完了 |
| EXP_GAIN 中央演出/ステップ行 | 4 | `exp_burst_frame.png` 候補を生成。透明外枠/見出し拡大は可読性が落ちたため不採用、最終的にステップ行はcontent契約上visibleのままalpha 0.18で抑制 | 完了 |
| MEAL_RESULT 料理カード/外枠構成 | 2 | 料理カード素材候補の広い料理窓に合わせて配分を試し、1回目は料理名が狭くなったため、2回目で画像幅/文字サイズとMEAL_RESULT専用透明外枠を採用 | 完了 |
| COOK_SELECT 料理カードタイトル帯 | 1 | 最新比較で枠ノッチとタイトル文字の干渉を確認し、runtimeタイトルをアウトラインなし太字・帯内下寄せへ調整 | 完了 |
| COOK_SELECT 料理カード星ランク表示 | 1 | Label幅中央寄せを試したが実スクショで星文字が弱く、runtimeポリゴン描画 `RecipeStarRank` へ切替 | 完了 |

## 4. 暫定判定・再検証TODO

なし。

## 5. 現在の残ギャップ

- R5: ユーザー指定の調理フロー残り4状態（MEAL_RESULT / EXP_GAIN / LEVEL_UP_OVERLAY / STATUS_SUMMARY）はreference-uplift完了。残る画面別R5は、次の対象選定時に `docs/19` §8.5 と各画面QAログから判断する。
- R1温存: レアリティ表示の `RarityStyles` 横展開は未実施。調理場 `src/ui/cooking_screen.gd` のR1完了により、残件は台帳に残したまま一旦停止。
- R1: `src/ui/cooking_screen.gd` は `Color(` 直書きゼロ。COOK_SELECT左魚リスト周辺は `Palette.COOKING_FISH_*`、見出しリボン周辺は `Palette.COOKING_SECTION_RIBBON_*`、料理カード/中央料理グリッド外枠周辺は `Palette.COOKING_RECIPE_*`、下部バー周辺は `Palette.COOKING_PREP_*`、右詳細パネルactive runtime色は `Palette.COOKING_DETAIL_*`、調理ボタン周辺は `Palette.COOKING_ACTION_*`、料理図鑑ボタン周辺は `Palette.COOKING_RECIPE_BOOK_BUTTON_*`、小アイコン/アクションキュー周辺は `Palette.COOKING_SMALL_ICON_*` / `Palette.COOKING_ACTION_CUE_*`、結果サマリーカード周辺は `Palette.COOKING_SUMMARY_CARD_*` / `Palette.COOKING_RESULT_TITLE_OUTLINE`、背景fallback/glazeは `Palette.COOKING_BG_*` へ移行済み。未使用detail helper由来のhexは削除済み。
- 監査: `tools/cooking_layout_audit.tscn` / `tools/cooking_content_audit.tscn` / `./tools/cooking_visual_qa.sh` はgreen。visual QAは状態間キャプチャ重複のfail guard追加済み。

## 6. フェーズスコープ宣言（作業中のみ）

なし。

## 7. 判断ログ（直近パスのみ）

2026-07-05: `STATUS_SUMMARY reference-uplift` 完了。`reference/cooking_flow/05_status_summary_concept.png` へ向けて、5カードの独立画面感と主値の読みを強めた。

- 選定理由: LEVEL_UP_OVERLAY完了後、ユーザー指定の優先順で次がSTATUS_SUMMARYだったため。before比較では5カード構成はあるが、背景が下のCOOK_SELECTに透け、カードの主値と表面密度が参照より弱かった。
- 変えたもの: `status_card_frame.png` 候補を生成し、カード表面に紙目/帯を追加。STATUS_SUMMARY背景の下に不透明ベースを敷き、下のCOOK_SELECT透けを解消。5カードの主値をruntime値プレート化し、クーラー/所持金/プレイ時間の読みを強化。visual QA保存は `RenderingServer.force_draw` で同期し、状態別キャプチャの安定性を補強。プレビュー種のクーラー値は参照判断用に `19 / 20` へ調整。
- 変えていないもの: §1 freeze値、調理/EXP/レベルアップ進行ロジック、COOK_SELECT、MEAL_RESULT、EXP_GAIN、LEVEL_UP_OVERLAY、ステータス計算ロジック、セーブ仕様、R1残件、日本語PNG焼き込み。
- 素材候補: `status_card_frame.png` 候補を採用。ただし半透明描画が既存紙面を置換して下画面が透けた版は不採用。合成方式に直した不透明紙面版を採用した。
- 微調整カウンタ: `STATUS_SUMMARY カード密度/背景` 3回。3回目で値プレートと背景抜けは改善したが、半透明カードは素材品質問題と判断し、素材生成を修正して採用した。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_status_summary_before_after_ref.png`, `docs/qa/evidence/cooking/2026-07-05_status_summary_focus.png`, `docs/qa/evidence/cooking/2026-07-05_status_summary_status.png`, `docs/qa/evidence/cooking/2026-07-05_status_summary_report.html`
- 判定: afterでは背景の港/厨房帯が見え、5カードの絵+主値+説明の読みがbeforeより明確になった。参照ほどカードアートの密度やプレイヤーカードの大きな人物絵には未到達だが、独立したステータス要約画面へ前進したと第三者に判別できる。cmp一致は判定に使っていない。
- 検証: `./tools/cooking_visual_qa.sh`、`cooking_layout_audit.tscn`、`cooking_content_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`save_system_verify.sh` のJSON警告と `validate_project.sh` のObjectDB/resource警告はベースライン既知。
- 固定条件: STATUS_SUMMARYは下のCOOK_SELECTを透かさず、5カードの主値を値プレートで表示する。次のR5対象は台帳で改めて選定する。

2026-07-05: `LEVEL_UP_OVERLAY reference-uplift` 完了。`reference/cooking_flow/04_level_up_overlay_concept.png` へ向けて、上部祝祭帯の存在感を強めた。

- 選定理由: EXP_GAIN完了後、ユーザー指定の優先順で次がLEVEL_UP_OVERLAYだったため。before比較では情報契約は揃っているが、参照のcrown/laurel/金色祝祭感に比べ、上部報酬ビートが弱かった。
- 変えたもの: `tools/generate_cooking_showcase_assets.py` の `level_crown_asset()` / `level_laurel_asset()` から `level_crown.png` / `level_laurel_left.png` / `level_laurel_right.png` 候補を生成し、crown/laurelの輝きとサイズを強化。`LevelUpPanel` のダイアログ幅/高さ、title band、crown/laurel表示サイズを調整。
- 変えていないもの: §1 freeze値、調理/EXP/レベルアップ進行ロジック、COOK_SELECT、MEAL_RESULT、EXP_GAIN、STATUS_SUMMARY、ステータス値、解放文言、日本語PNG焼き込み、R1残件。
- 素材候補: `level_crown.png` / `level_laurel_*.png` 候補を採用。runtime `LEVEL UP!` 文字拡大とLv行拡大は実スクショ/監査で表示契約が落ちたため不採用。最終候補は参照ほどの巨大タイトルには届かないが、beforeよりcrown/laurelが読みやすく、祝祭overlayとして前進したと判断。
- 微調整カウンタ: `LEVEL_UP_OVERLAY 上部祝祭帯` 3回。3回目で表示契約を維持する構成へ戻し、残る巨大タイトル差分は次回以降の構造/素材フェーズへ送る。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_levelup_before_after_ref.png`, `docs/qa/evidence/cooking/2026-07-05_levelup_title_focus.png`, `docs/qa/evidence/cooking/2026-07-05_levelup_levelup.png`, `docs/qa/evidence/cooking/2026-07-05_levelup_report.html`
- 判定: afterでは上部crown/laurelとダイアログの存在感が増し、報酬overlayの第一印象がbeforeより強い。参照の巨大 `LEVEL UP!` / 大きなLv遷移には未到達だが、祝祭方向へ前進したと第三者に判別できる。cmp一致は判定に使っていない。
- 検証: `./tools/cooking_visual_qa.sh`、`cooking_layout_audit.tscn`、`cooking_content_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`save_system_verify.sh` のJSON警告と `validate_project.sh` のObjectDB/resource警告はベースライン既知。
- 固定条件: LEVEL_UP_OVERLAYの `成長の証` / `LEVEL UP!` / Lv遷移行はcontent audit契約上visibleを維持し、祝祭感はcrown/laurel素材と上部帯で強める。次スライスはSTATUS_SUMMARYへ進める。

2026-07-05: `EXP_GAIN reference-uplift` 完了。`reference/cooking_flow/03_exp_gain_concept.png` へ向けて、中央EXP演出を主役に寄せた。

- 選定理由: MEAL_RESULT完了後、ユーザー指定の優先順で次がEXP_GAINだったため。before比較では上部ステップ行と旧EXPフレームが強く、参照の巨大 `+EXP` / 中央ゲージの報酬ビートより進行UI感が勝っていた。
- 変えたもの: `tools/generate_cooking_showcase_assets.py` の `exp_burst_frame()` から `assets/showcase/cooking/exp_burst_frame.png` 候補を生成し、中央フレームの光量・ゲージ台座・粒子を強化。EXP_GAIN時のステップ行はcontent audit契約上visibleのまま、alpha 0.18で背景側へ退かせた。
- 変えていないもの: §1 freeze値、調理/EXP/レベルアップ進行ロジック、COOK_SELECT、MEAL_RESULT、LEVEL_UP_OVERLAY、STATUS_SUMMARY、R1残件、日本語PNG焼き込み。
- 素材候補: `exp_burst_frame.png` 候補を採用。透明外枠化と見出し拡大は `+EXP` / 見出しの可読性が落ちたため不採用。最終候補は、参照ほどの巨大タイトルには届かないが、beforeより中央ゲージの発光と専用EXP状態の読みが強いと判断。
- 微調整カウンタ: `EXP_GAIN 中央演出/ステップ行` 4回。3回目で表示契約を満たす改善に戻し、4回目の見出し拡大は不採用として戻した。追加の数px調整は行わず、残る巨大タイトル差分は次回以降の構造/素材フェーズへ送る。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_exp_gain_before_after_ref.png`, `docs/qa/evidence/cooking/2026-07-05_exp_gain_focus.png`, `docs/qa/evidence/cooking/2026-07-05_exp_gain_exp.png`, `docs/qa/evidence/cooking/2026-07-05_exp_gain_report.html`
- 判定: afterでは上部ステップ行が主導線から退き、中央EXPカードの光とゲージ台座が強くなった。参照の巨大 `+60 EXP` ほどの迫力は残課題だが、EXP獲得専用状態へ前進したと第三者に判別できる。cmp一致は判定に使っていない。
- 検証: `./tools/cooking_visual_qa.sh`、`cooking_layout_audit.tscn`、`cooking_content_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`save_system_verify.sh` のJSON警告と `validate_project.sh` のObjectDB/resource警告はベースライン既知。
- 固定条件: EXP_GAINのステップ行はcontent audit契約上visibleを維持するが、主役は中央EXP演出とする。次スライスはLEVEL_UP_OVERLAYへ進める。

2026-07-05: `MEAL_RESULT reference-uplift` 完了。`reference/cooking_flow/02_meal_result_concept.png` へ向けて、食事結果がフォームではなくpayoff状態に見えるように調整した。

- 選定理由: COOK_SELECT仕上げ点検後、ユーザー指定の優先順で残り4状態の先頭がMEAL_RESULTだったため。before比較では外側の暗い巨大フレームが強く、食事シーン背景よりフォーム感が勝っていた。
- 変えたもの: `tools/generate_cooking_showcase_assets.py` の `meal_dish_card_frame()` から `assets/showcase/cooking/meal_dish_card_frame.png` 候補を生成し、料理カードの料理画像窓を広げた。MEAL_RESULT時のみ `CookingRewardPanel` の外枠を透明寄りにし、EXP_GAINでは従来報酬フレームへ戻す。料理画像/料理名の配分をMEAL_RESULT専用に調整。
- 変えていないもの: §1 freeze値、COOK_SELECT、EXP_GAINの表示契約、LEVEL_UP_OVERLAY、STATUS_SUMMARY、調理/EXP/レベルアップ進行ロジック、魚/料理データ、セーブ仕様、日本語PNG焼き込み、R1残件。
- 素材候補: `meal_dish_card_frame.png` 候補を採用。1回目は画像窓を広げすぎて料理名領域が狭くなったため採用せず、2回目で画像幅/文字サイズと外枠透明化を合わせて全画面のpayoff感がbeforeに明確に勝つと判断。
- 微調整カウンタ: `MEAL_RESULT 料理カード/外枠構成` 2回。3回未満で改善したため追加の素材再生成には進まない。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_meal_result_before_after_ref.png`, `docs/qa/evidence/cooking/2026-07-05_meal_result_dish_card_focus.png`, `docs/qa/evidence/cooking/2026-07-05_meal_result_result.png`, `docs/qa/evidence/cooking/2026-07-05_meal_result_report.html`
- 判定: afterでは大きな暗色モーダルの印象が弱まり、食事シーン背景の上にバナー、料理カード、報酬カード、ステータスカードが載る読みになった。参照ほどの背景全面化や報酬値の迫力は残課題だが、食事結果のpayoff状態へ前進したと第三者に判別できる。cmp一致は判定に使っていない。
- 検証: `./tools/cooking_visual_qa.sh`、`cooking_layout_audit.tscn`、`cooking_content_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`save_system_verify.sh` のJSON警告と `validate_project.sh` のObjectDB/resource警告はベースライン既知。
- 固定条件: MEAL_RESULTは暗い巨大外枠を主役に戻さず、食事シーン背景上のpayoffカード群として扱う。次スライスはEXP_GAINへ進める。

2026-07-05: `COOK_SELECT finish precision pass` 完了。最新COOK_SELECTスクショと `reference/cooking_flow/01_cook_select_concept.png` の横並びで、指定3点を点検した。

- 選定理由: R1色移行を一旦停止し、残り4状態reference-upliftへ進む前に、COOK_SELECTの料理カードタイトル帯、右詳細3行、下部4区画の仕上げ精度を確認するため。
- 変えたもの: 料理カードタイトルを共通 `_recipe_card_title_slot` で生成し、アウトラインなし太字・帯内下寄せ・左右余白付きに変更。実カードとプレビューカードで同じ処理に統一。
- 変えていないもの: §1 freeze値、料理カード枠素材、皿画像、星ランク、素材フッター、右詳細行素材、下部4区画、背景、調理/EXP/レベルアップ進行ロジック、日本語PNG焼き込み。
- 微調整カウンタ: `COOK_SELECT 料理カードタイトル帯` 1回。1回目で改善が見えたため素材再生成には進まない。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_select_precision_before_after_ref.png`, `docs/qa/evidence/cooking/2026-07-05_select_precision_title_crop.png`, `docs/qa/evidence/cooking/2026-07-05_select_precision_select.png`, `docs/qa/evidence/cooking/2026-07-05_select_precision_report.html`
- 判定: beforeではタイトル文字が白アウトラインでにじみ、上枠ノッチと干渉して読みにくかった。afterでは濃色太字がタイトル帯内に収まり、参照のカード見出しに近づいた。右詳細3行の `12 / 1`、`初回 +20 EXP`、`1回` は値プレート内に収まり、下部4区画も見切れなし。cmp一致は判定に使っていない。
- 検証: `./tools/cooking_visual_qa.sh`、`cooking_layout_audit.tscn`、`cooking_content_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`save_system_verify.sh` のJSON警告と `validate_project.sh` のObjectDB/resource警告はベースライン既知。
- 固定条件: COOK_SELECT料理カードタイトルはruntime描画のまま、アウトラインなし太字・帯内下寄せを現行基準とする。次スライスはMEAL_RESULTへ進める。

2026-07-05: `shared GaugeBar palette R1 pass` 完了。調理フローで使う共有ゲージの描画色をPalette用途名へ移行した。

- 選定理由: `GaugeBar` は調理報酬/調理ステータス/ステータス画面で共有されるが、既定色と描画色に直書き `Color(...)` が残っており、R1残件として小さく切れるため。
- 変えたもの: `src/ui/components/gauge_bar.gd` の既定グラデーション、トラック、影、ゴースト、ハイライト、ダメージ点滅、危険域グロー、数値文字色。`src/ui/palette.gd` へ `Palette.GAUGE_*` 定数を追加。
- 変えていないもの: §1 freeze値、調理場レイアウト、料理カード、下部バー、右詳細パネル、報酬カード、ゲージの値/補間/決定的QAガード、日本語PNG焼き込み。
- Palette: 新規 `Palette.GAUGE_TRACK` / `GAUGE_TRACK_BORDER` / `GAUGE_SHADOW_CLEAR` / `GAUGE_SHADOW` / `GAUGE_GHOST` / `GAUGE_HIGHLIGHT` / `GAUGE_DAMAGE_FLASH` / `GAUGE_CRITICAL_GLOW` / `GAUGE_VALUE_OUTLINE` / `GAUGE_VALUE_TEXT` を追加。理由は共有ゲージの描画色責務をPaletteへ集約するため。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_gauge_bar_palette_select.png`, `docs/qa/evidence/cooking/2026-07-05_gauge_bar_palette_report.html`
- 判定: 実スクショでCOOK_SELECTの下部バー/右詳細パネル、および調理フロー5状態にP1なし。これは参照upliftではなくR1表示同値移行なので、cmp一致は完了条件にしていない。
- 検証: `./tools/cooking_visual_qa.sh` は透明キャプチャで1回失敗後、同一差分で再実行してgreen。`tools/cooking_content_audit.tscn`、`tools/cooking_layout_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`validate_project.sh` の ObjectDB/resource 警告はベースライン既知。
- 固定条件: 共有ゲージの描画色は `Palette.GAUGE_*` として扱い、`src/ui/components/gauge_bar.gd` へ新規 `Color(...)` を戻さない。

2026-07-05: `cooking_screen final palette R1 pass` 完了。背景fallbackと料理カードtintの残色をPalette用途名へ移行し、`src/ui/cooking_screen.gd` の `Color(` 直書きをゼロにした。

- 選定理由: 未使用detail helper削除後も背景fallbackと料理カード/素材/皿画像tintに `Color(...)` の直書きが残っており、調理場画面全体のR1完了を阻んでいたため。
- 変えたもの: 背景fallback top/bottom、料理カードlocked/unavailable/preview modulate、料理素材アイコンmuted modulate、皿画像muted modulate。
- 変えていないもの: §1 freeze値、レイアウト値、素材、表示文言、COOK_SELECT構成、調理報酬オーバーレイ、日本語PNG焼き込み。
- Palette: 新規 `Palette.COOKING_BG_FALLBACK_*` / `Palette.COOKING_RECIPE_*_MODULATE` を追加。理由は調理場画面スクリプト内の最後の直書き色を、表示同値のままPalette正本へ移すため。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_background_fallback_palette_select.png`, `docs/qa/evidence/cooking/2026-07-05_background_fallback_palette_report.html`
- 判定: `rg -n "Color\\(" src/ui/cooking_screen.gd` 該当ゼロ。実スクショでCOOK_SELECT料理カード、背景、右詳細パネルにP1なし。これは参照upliftではなくR1表示同値移行なので、cmp一致は完了条件にしていない。
- 検証: `./tools/cooking_visual_qa.sh`、`tools/cooking_content_audit.tscn`、`tools/cooking_layout_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`validate_project.sh` の ObjectDB/resource 警告はベースライン既知。
- 固定条件: 調理場画面のruntime色は `Palette.COOKING_*` 系で扱い、次回以降 `src/ui/cooking_screen.gd` へ新規 `Color(...)` を戻さない。

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
