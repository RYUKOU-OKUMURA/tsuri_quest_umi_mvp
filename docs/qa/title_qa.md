# タイトル画面 QA判断ログ

最終更新: 2026-07-11 / 状態: 既存レイアウトfreeze維持・ID-01利用不可／SAVE-03不正artifact状態freeze
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

## 4. 暫定判定・再検証TODO

なし。Godot 4.7の1280x720実スクショで確認済み。

## 5. 現在の残ギャップ

- 正式製品名・v1.0.0外装とE7難易度モーダルは後続。追加時も本利用不可状態を優先し、既存矩形を不用意に動かさない。

## 7. 判断ログ（直近パスのみ）

2026-07-11 ID-01の高リスク状態としてセーブ領域利用不可を追加。「移行失敗を空slotに見せない」だけを変更し、既存レイアウト、素材、配色、フォント、通常状態の導線は不動とした。通常状態と同じ1280x720・同じ矩形で比較し、3slot、状態欄、主ボタンの文言に見切れ・重なりがなく、全操作がdisabledになることを実スクショとsmokeで確認した。採用証拠は`docs/qa/evidence/title/2026-07-11_id01_storage_blocked.png`、比較は`docs/qa/evidence/title/2026-07-11_id01_storage_block_compare.png`。通常状態へ戻すとslotと主ボタンが再度有効になる契約もsmokeで固定した。

2026-07-11 SAVE-03の高リスク状態として、main / backupの両方に不正artifactがあるslotを追加。局所upliftとして、動かす対象をslot文言・状態欄文言・disabled契約だけに限定し、ロゴ、魚、menu枠、3slot、下段2ボタンの矩形、素材、配色、フォント、通常状態は不動とした。初回実スクショで詳細文のellipsisをP1として検出し、状態欄を「セーブ破損。原本は変更していません」へ短縮。1280x720再撮影で見切れ・重なりなし、続き／新規開始disabled、他slotの通常表示を確認した。採用証拠は`docs/qa/evidence/title/2026-07-11_save03_invalid_artifact.png`、比較は`docs/qa/evidence/title/2026-07-11_save03_invalid_artifact_compare.png`。
