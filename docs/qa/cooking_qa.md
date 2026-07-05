# 調理場 QA判断ログ

最終更新: 2026-07-05 / 状態: R5 layout audit repair 完了
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

## 4. 暫定判定・再検証TODO

なし。

## 5. 現在の残ギャップ

- P2: レアリティ表示の `RarityStyles` 横展開は未実施。
- R1: `src/ui/cooking_screen.gd` の画面固有ハードコード色は大半が未移行。今回触ったヘッダーfallback色は `Palette.COOKING_*` へ同値移行済み。残りは次の調理場直接編集スライスで継続する。
- 監査: `tools/cooking_layout_audit.tscn` / `tools/cooking_content_audit.tscn` / `./tools/cooking_visual_qa.sh` はgreen。visual QAは状態間キャプチャ重複のfail guard追加済み。

## 6. フェーズスコープ宣言（作業中のみ）

なし。

## 7. 判断ログ（直近パスのみ）

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
