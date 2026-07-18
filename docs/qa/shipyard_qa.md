# 船着き場 QA判断ログ

最終更新: 2026-07-18 / 状態: SHIPYARD-D0観測基盤完了・製品UI/freeze維持
参照画像: `reference/shipyard_d0_proposal_unapproved.png`（D0提案候補・未採用。専用referenceがないため作成。製品runtime/assetの正本ではない）
QA更新コマンド: `./tools/shipyard_visual_qa.sh`

## 1. freeze値（正本）

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 論理画面サイズ | 1280x720 | `tools/shipyard_preview.tscn` | プロジェクト固定キャンバス |
| 船カード矩形 | `0.022–0.253 × 0.124–0.345` / `0.022–0.253 × 0.365–0.586` / `0.022–0.253 × 0.606–0.827` | `src/ui/shipyard_screen.gd` `_build_boat_cards()` | 3船選択・マウス入力の既存契約。D0で不動 |
| 購入ボタン矩形 | `0.545–0.654 × 0.794–0.862` | `src/ui/shipyard_screen.gd` `_build_center_detail()` | 価格/購入導線と入力矩形を維持 |
| 港へ戻る矩形 | `0.842–0.976 × 0.912–0.976` | `src/ui/shipyard_screen.gd` `_build_footer()` | docs/28の右下規約。幅・y帯ともfreeze |
| フッター説明矩形 | `0.270–0.768 × 0.912–0.976` | `src/ui/shipyard_screen.gd` `_build_footer()` | 帰港導線移動時から維持。D0で不動 |
| 航路パネル領域 | `0.746–0.976 × 0.140–0.895` | `src/ui/shipyard_screen.gd` `_build_route_panel()` | 現在/購入後航路の表示領域。D0で不動 |
| 価格・購入・所有 | `GameData` / `PlayerProgress` の現行契約 | `src/ui/shipyard_screen.gd` | 価格、購入、所有、航路解放、save/economyは変更しない |
| キーボードfocus | 代表: 購入可能→購入focus。高リスク: 資金不足/所有済み/全所有は購入をskipし、選択中カードへ退避 | `src/ui/shipyard_screen.gd` / `tools/shipyard_input_smoke.gd` | E11 INPUT-SHIPYARD finding 0。共通focus styleとEscape一重を維持 |

## 2. 不採用・再試行禁止リスト

| 案 | 却下理由 | 判断日 |
|---|---|---|
| D0「船舶司令盤」提案候補を製品runtimeへ仮配線 | 方向性は未承認。製品UI、製品asset、freeze値、入力矩形を変更しないD0のため | 2026-07-18 |
| 旧構成の左下帰港ボタンへ戻す | docs/28の「画面右下 = 港へ戻る」に反し、既存freezeを再オープンする根拠がない | 2026-07-05 |
| フッター説明を帰港導線に合わせて再配置 | RF4は帰港導線位置だけのスライス。説明文の構成変更は別concern | 2026-07-05 |
| 帰港ボタンの見た目をcommonへ置換 | docs/28でスタイル共通化はスコープ外。造船所固有ボタンアートを維持 | 2026-07-05 |

## 3. 微調整カウンタ

| パラメータ | 回数 | 直近の変更内容 | 状態 |
|---|---:|---|---|
| 港へ戻る位置 | 1 | 左下アンカーから右下 `0.842–0.976 × 0.912–0.976` へ移動 | freeze |
| D0提案モックの構成 | 0 | 製品画面へ未配線。候補生成・比較のみ | 未承認 |
| 装飾パス累計 | 0 | 製品runtimeの装飾変更なし | — |

## 4. 暫定判定・再検証TODO

- D0のvisual QAは通常表示driverによる1280x720実キャプチャで確定。`2026-07-18_current_*.png` と `2026-07-18_d0_current_reference_{full,320x180}.png` を正式保存済み。
- `reference/shipyard_d0_proposal_unapproved.png` はユーザー未採用の方向性候補。採用承認までは製品参照・製品assetとして扱わない。
- ユーザー承認後に実装へ進む場合だけ、候補がsupersedeする旧構成範囲と再オープンするfreezeを別フェーズで宣言する。現時点で再オープンなし。

## 5. 現在の残ギャップ

- 船着き場の専用正式referenceは未採用。D0では「船舶司令盤」方向を1案だけ提示した。
- 現行の左船列・中央購入面・右航路面という旧構成を、将来この候補が承認された場合に視覚的にsupersedeする提案である。現時点では製品UIを変更していない。

## 6. フェーズスコープ宣言（作業中のみ）

SHIPYARD-D0は完了。今回動かしたのは `tools/shipyard_preview.gd/.tscn` のキャプチャ状態/安定化、`tools/shipyard_visual_qa.sh`、専用比較/check builder、未採用reference候補、evidence、QA記録だけ。製品runtime、製品asset、価格/購入/所有、`PlayerProgress`、`project.godot`、既存freeze/input矩形は触っていない。

状態契約は次の通り固定した。

| 状態 | 固定seed/データ | 表示/非表示 | 固定アンカー | 可変領域 | evidence出力 | smoke契約 |
|---|---|---|---|---|---|---|
| 代表・購入可能 | Lv5 / 4,000 G / 船なし / skiff選択 | 購入有効・購入focus | 3船、購入、帰港、航路 | 詳細ステータス/フッター文 | `2026-07-18_current_available_focus.png` | `shipyard_smoke` の購入可能・価格表示 |
| 高リスク・資金不足 | Lv5 / 500 G / 船なし / skiff選択 | 購入disabled・カードfocus | 同上 | 不足額/フッター文 | `2026-07-18_current_insufficient.png` | `shipyard_input_smoke` のdisabled skip |
| 高リスク・購入直後 | Lv5 / 400 G / skiff所有 / skiff選択 | 購入disabled・選択カードfocus | 同上 | 所有状態/帰港文 | `2026-07-18_current_purchased_focus_fallback.png` | 購入後focus fallback |
| 高リスク・全所有 | Lv5 / 999,999 G / 3船所有 / bluewater選択 | 購入disabled・最終カードfocus | 同上 | 全航路/所有表示 | `2026-07-18_current_all_owned.png` | 全所有で購入skip・帰港到達 |

## 7. 判断ログ（直近パスのみ）

2026-07-18 SHIPYARD-D0:

- 構成再設計ゲートを、専用reference不在・現行の左船列/中央購入/右航路の同格面・視覚的な主役不在という設計課題の観測として開いた。ただし方向性未承認のため、コード/製品asset/freezeの再オープンは行っていない。
- 1方向だけ「船舶司令盤」候補を `reference/shipyard_d0_proposal_unapproved.png` として作成した。現行スクリーンの背景・船/航路の観測画素を提案用に再配置し、現行機能文言・価格・所有状態を保持した。日本語・動的値・CTAは製品assetへ焼き込まず、候補PNGはreference/evidence専用である。
- 候補が将来supersedeする提案範囲は、旧構成の「左の3船カード列・中央の詳細購入面・右の航路面・下部説明の並列構成」。右下帰港、3船の入力矩形、購入入力矩形、状態遷移、価格/所有/economyは候補承認後も別途維持条件として扱う。
- `shipyard_preview.gd` は `available_focus`、`insufficient`、`purchased_focus_fallback`、`all_owned` の4状態を追加し、SubViewportのclear/force draw/frame_post_draw待機を固定した。これにより同じ1280x720 viewportで代表/高リスクを再生成できる。製品screenの配置/文言/ロジックは変更していない。
- `shipyard_visual_qa.sh` は毎回対象tmp capture/evidenceを消してから撮影し、専用checkerのself-testで黒/透明/重複captureをfailする。実キャプチャ4枚は1280x720、不透明、状態間ハッシュ重複なし。現行/reference候補の原寸比較は `2026-07-18_d0_current_reference_full.png`、320x180比較は `2026-07-18_d0_current_reference_320x180.png`、状態一覧は `2026-07-18_d0_current_states_320x180.png` に保存した。
- 変えていないもの: `src/ui/shipyard_screen.gd`、`assets/showcase/shipyard/**`、`GameData/PlayerProgress`、価格/購入/所有/economy、`project.godot`、他画面、docs/30・docs/54、既存freeze値、既存input矩形。
- 検証: `./tools/shipyard_visual_qa.sh`、`shipyard_smoke.tscn`、`shipyard_input_smoke.tscn`、E11入力probe strict（SHIPYARD finding 0）、`./tools/validate_project.sh`、`git diff --check` を実行し、全てgreen。

2026-07-15 INPUT-SHIPYARD:

- 船カード3件、購入、港へ戻るへ矢印/Tabで到達できるgraphを定義。購入成功でfocus中の購入がdisabledになった場合は選択カードへ退避し、資金不足/所有済み/全所有では購入をgraphから外した。
- 戻るは既存の帰港先を変えず、共通cancel handlerへ接続してEscape echoを含む1 press 1回を固定した。入力findingは0件。
