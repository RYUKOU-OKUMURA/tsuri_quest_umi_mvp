# タイトル画面 QA判断ログ

最終更新: 2026-07-15 / 状態: E7 freeze維持、INPUT-TITLE収束済み
参照: `docs/14_opening_title_showcase.md` の採用構成、および通常状態の現行runtime
QA更新コマンド: `./tools/title_visual_qa.sh`

## 1. freeze値（正本）

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 通常状態 | 3slot＋状態欄＋「つづきから」＋「ゲームを始める」 | `src/ui/title_screen.gd` | 既存構成を維持 |
| セーブ領域利用不可状態 | 3slotすべて「利用不可（再起動）」、状態欄と主ボタンに再起動案内 | `src/ui/title_screen.gd` | 旧saveを空slotと誤認させない |
| 利用不可時の操作 | slot選択・続き・新規開始をdisabled | `src/ui/title_screen.gd` | 移行不整合中のload / save / resetを防ぐ |
| 不正artifact状態 | 対象slotを「セーブ破損（利用不可）」、状態欄を「セーブ破損。原本は変更していません」と表示 | `src/ui/title_screen.gd` | 一過性signalに依存せず、破損原本を空slotと誤認させない |
| 不正artifact時の操作 | 対象slotの続き・新規開始をdisabled。他の正常slotは利用可能 | `src/ui/title_screen.gd` | 明示的な安全操作なしの原本上書きを防ぐ |
| 固定アンカー | ロゴ、魚、menu枠、3slot、下段2ボタンの既存矩形 | `src/ui/title_screen.gd` | ID-01ではfreeze値を再オープンしない |
| 難易度選択 | やさしい／ふつう／むずかしいの3択＋キャンセル | `src/ui/title_screen.gd` | 新規開始時のみ。既存title画像スキンを再利用 |
| 上書き最終確認 | 難易度選択後に1回。slot番号／Lv／プレイ時間／選択難易度／不可逆警告を表示 | `src/ui/title_screen.gd` | 初期focusはキャンセル。二段階確認禁止 |
| モーダルfocus | 表示中は背面slot／下段ボタンを`FOCUS_NONE` | `src/ui/title_screen.gd` | Tab／方向キーの背面漏れを防止 |
| 通常focus graph | 選択中slotを初期focusとし、3slot／有効な続き・新規開始／設定を上下左右・Tabで循環 | `src/ui/title_screen.gd` | disabled操作を候補から除外。storage blocked時は設定だけを安全な初期focusにする |
| モーダル復帰 | 難易度は「ふつう」、上書き確認は「キャンセル」を初期focusとし、決定／戻る後は呼び出し元の新規開始へ復帰 | `src/ui/title_screen.gd` | modal表示中は候補scopeを置換し、1入力1回を共通cancel契約で消費 |

## 2. 不採用・再試行禁止リスト

| 案 | 却下理由 | 判断日 |
|---|---|---|
| 移行失敗時も空slotとして表示する | 旧save消失と誤認し、新規開始を誘発する | 2026-07-11 |
| 起動時の一過性toastだけで通知する | autoload初期化時は画面側のsignal接続前で、通知を見落とす | 2026-07-11 |
| 不正artifactを「空き」と表示して新規開始を許可する | 原本上書きと正常backup喪失を誘発する | 2026-07-11 |

## 3. 微調整カウンタ

| パラメータ | 回数 | 直近の変更内容 | 状態 |
|---|---:|---|---|
| 装飾パス累計 | 0 | 素材・配色・座標は変更なし | freeze |
| 利用不可文言 | 1 | 既存slot / 状態欄 / 主ボタン内へ収めた | freeze |
| 不正artifact文言 | 1 | 既存矩形を動かさず、状態欄のellipsisを解消する短文へ収束 | freeze |
| E7モーダル説明幅 | 1 | hard説明が1行に収まるよう新規モーダルのみ拡幅 | freeze |
| INPUT-TITLE操作状態 | 1 | 共通focus styleと状態別focus scopeを配線。矩形・素材・文言は不動 | freeze |

## 4. 暫定判定・再検証TODO

なし。Godot 4.7の1280x720実スクショで確認済み。

## 5. 現在の残ギャップ

- 正式製品名・v1.0.0外装は後続。

## 6. E7状態契約（freeze）

- 局所uplift: E7仕様で確定済みの難易度選択／上書き最終確認ブロックだけを新設する。
- 存在する領域: 背景スクリム、共通画像スキンのモーダル、3難易度ボタン、キャンセル、使用済みslotのみ最終確認。
- 存在しない領域: 旧上書き確認→難易度→再確認の二段階、難易度の後日変更、倍率の重複詳細表示、新規PNG。
- 主操作: 選択slotの新規開始難易度を1つ選ぶ。補助操作はキャンセル。上書き最終確認の初期focusはキャンセル。
- 状態対応: emptyは選択後すぐreset、occupiedは選択後にslot番号／Lv／プレイ時間／難易度／不可逆警告の5項目を含む1回の最終確認。storage blocked / future guarded / invalid artifactはモーダル非表示でreset不可。
- 固定アンカー: ロゴ、魚、menu枠、3slot、状態欄、下段2ボタンの現行矩形。可変領域は画面中央のオーバーレイのみ。
- 素材/runtime分担: title/commonの既存画像スキンが枠・ボタン質感、Palette/GameFontsとGodot runtimeが文言・選択状態・フォーカス・スクリムを担う。
- 動かす値: 新規モーダル内の矩形と内部余白のみ。不動freeze: 既存画面の全矩形、素材、配色、フォント、安全遮断契約。
- INPUT-TITLE追加契約: 通常／storage blocked／future guard／invalid artifact／difficulty／overwriteごとにfocus候補を置換する。slot選択、続き、新規開始、設定、modal操作の既存導線とマウスclickは維持し、disabled操作はfocus graphへ含めない。

| 状態 | 固定seed/データ | 表示/非表示 | 固定アンカー | 可変領域 | evidence出力 | smoke契約 |
|---|---|---|---|---|---|---|
| empty | 3slot空 | 通常UI | 既存全矩形 | slot文言のみ | `title/2026-07-12_e7_empty.png` | 選択のみで保存しない |
| occupied | slot1=Lv12/12時間34分 | 通常UI | 同上 | slot文言のみ | `title/2026-07-12_e7_occupied.png` | 旧確認は先に出ない |
| 3slot | 3slotすべて使用済み（Lv/時間/難易度差） | 通常UI | 同上 | slot文言のみ | `title/2026-07-12_e7_3slot.png` | 選択slot以外のartifact不変 |
| difficulty | slot1選択 | 3択モーダル | 背面の既存全矩形 | モーダル | `title/2026-07-12_e7_difficulty.png` | 3IDとcancel、安全状態での非表示 |
| overwrite | slot1=Lv12/12時間34分、hard | 5項目最終確認 | 背面の既存全矩形 | モーダル | `title/2026-07-12_e7_overwrite.png` | 確認1回、cancel初期focus、確認後開始 |

## 7. 判断ログ（直近パスのみ）

2026-07-15 INPUT-TITLE局所upliftを採用。動かしたのはfocus候補scope、隣接graph、初期focus、modal cancel／復帰だけで、ロゴ、魚、menu枠、3slot、下段2ボタン、設定ボタン、モーダルの全矩形・素材・配色・フォント・save安全契約は不動。実`InputEventKey`と実viewport mouse eventの専用smokeで、通常、storage blocked、future guard、invalid artifact、difficulty、overwriteを検証し、disabled skip、全enabled到達、決定1回、modal背面遮断、cancel後の新規開始focus復帰、mouse click回帰を確認した。E11 strict findingはタイトル3件から0件。原寸証拠は`docs/qa/evidence/title/2026-07-15_input_normal_settings_focus.png`と`docs/qa/evidence/title/2026-07-15_input_overwrite_cancel_focus.png`。`./tools/title_visual_qa.sh`、`title_input_smoke.tscn`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh`はgreen。`./tools/e11_qa_harness_verify.sh`は入力probe自体を通過し、共有`release_test_manifest.txt`へ新規smokeを登録する親統合作業だけを残す。

2026-07-12 E7局所upliftを採用。empty / occupied / 3slot / difficulty / overwriteの5状態をGodot 4.7・1280x720で実撮影し、hard説明と5項目最終確認に見切れ・省略・重なりなし。既存title矩形、素材、storage blocked / future guarded / invalid artifact契約は不動。smokeで空slotの保存成功後遷移、SAVE-02失敗時の非遷移、確認1回／5項目／cancel初期focus、背面focus遮断、他2slotのmain/backup/tmp不変を固定。証拠は`docs/qa/evidence/title/2026-07-12_e7_*.png`、主比較は`2026-07-12_e7_difficulty_compare.png`と`2026-07-12_e7_overwrite_compare.png`。

2026-07-11 ID-01の高リスク状態としてセーブ領域利用不可を追加。「移行失敗を空slotに見せない」だけを変更し、既存レイアウト、素材、配色、フォント、通常状態の導線は不動とした。通常状態と同じ1280x720・同じ矩形で比較し、3slot、状態欄、主ボタンの文言に見切れ・重なりがなく、全操作がdisabledになることを実スクショとsmokeで確認した。採用証拠は`docs/qa/evidence/title/2026-07-11_id01_storage_blocked.png`、比較は`docs/qa/evidence/title/2026-07-11_id01_storage_block_compare.png`。通常状態へ戻すとslotと主ボタンが再度有効になる契約もsmokeで固定した。

2026-07-11 SAVE-03の高リスク状態として、main / backupの両方に不正artifactがあるslotを追加。局所upliftとして、動かす対象をslot文言・状態欄文言・disabled契約だけに限定し、ロゴ、魚、menu枠、3slot、下段2ボタンの矩形、素材、配色、フォント、通常状態は不動とした。初回実スクショで詳細文のellipsisをP1として検出し、状態欄を「セーブ破損。原本は変更していません」へ短縮。1280x720再撮影で見切れ・重なりなし、続き／新規開始disabled、他slotの通常表示を確認した。採用証拠は`docs/qa/evidence/title/2026-07-11_save03_invalid_artifact.png`、比較は`docs/qa/evidence/title/2026-07-11_save03_invalid_artifact_compare.png`。
