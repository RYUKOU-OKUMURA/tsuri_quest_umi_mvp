# 船着き場 QA判断ログ

最終更新: 2026-07-05 / 状態: 帰港導線右下統一済み / RF3 Palette移行完了
参照画像: なし（`docs/28_harbor_return_placement_unification.md` の配置規約を正とする）
QA更新コマンド: `HOME=/tmp/tsuri_shipyard_home /Applications/Godot.app/Contents/MacOS/Godot --path . res://tools/shipyard_preview.tscn`

## 1. freeze値（正本）

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 論理画面サイズ | 1280x720 | `tools/shipyard_preview.tscn` | 他showcase画面と同じ固定キャンバス運用 |
| 港へ戻る導線 | `_place_control(root, back, 0.842, 0.912, 0.976, 0.976)` | `src/ui/shipyard_screen.gd` `_build_footer()` | docs/28の「画面右下 = 港へ戻る」規約に合わせる。幅とy帯は旧配置を維持 |
| フッター説明 | `_place_control(root, _footer_label, 0.270, 0.912, 0.768, 0.976)` | `src/ui/shipyard_screen.gd` `_build_footer()` | RF4では触らないfreeze値 |

## 2. 不採用・再試行禁止リスト

| 案 | 却下理由 | 判断日 |
|---|---|---|
| フッター説明を右下移動に合わせて再配置 | RF4は帰港導線位置のみのスライスで、説明文の構成変更は別判断になるため | 2026-07-05 |
| 戻るボタンの見た目を共通化 | docs/28でスタイル共通化はスコープ外。造船所固有ボタンアートを維持するため | 2026-07-05 |

## 3. 微調整カウンタ

| パラメータ | 回数 | 直近の変更内容 | 状態 |
|---|---|---|---|
| 港へ戻る位置 | 1 | 左下アンカー `0.018–0.152` から右下 `0.842–0.976` へ移動 | 採用 |
| 装飾パス累計 | 0 | — | — |

## 4. 暫定判定・再検証TODO

- headless実行では `SubViewport.get_image()` がnullになったため、通常起動のpreviewで `docs/qa/evidence/shipyard/2026-07-05_return_right_preview.png` と `docs/qa/evidence/shipyard/2026-07-05_rf3_palette_preview.png` を保存した。visual QA専用スクリプト未整備はP2 tooling残課題であり、RF4/RF3完了ブロッカーではない。

## 5. 現在の残ギャップ

- 船着き場専用のreference画像は未整備。現時点ではdocs/28の右下配置規約と実スクショで判断する。

## 6. フェーズスコープ宣言（作業中のみ）

- 現在作業中のP2フェーズなし。

## 7. 判断ログ（直近パスのみ）

2026-07-05 RF4:
- docs/28の帰港導線規約に合わせ、造船所フッターの「港へ戻る」を左下から右下へ移動。変更は `_build_footer()` の配置アンカーのみで、ボタン見た目、`shipyard_return` meta、`navigate("harbor")`、`_footer_label`、航路パネル群は触っていない。
- 通常previewで、右下の「港へ戻る」が航路パネル、ロックラベル、フッター説明文と重ならないことを確認した。
- 証拠: `docs/qa/evidence/shipyard/2026-07-05_return_right_preview.png`。
- 検証: `shipyard_smoke.tscn` green。

2026-07-05 RF3:
- `shipyard_screen.gd` の生色を `Palette.SHIPYARD_*` へ移行。帰港ボタン右下配置、`shipyard_return` meta、`navigate("harbor")`、フッター説明のfreeze値は維持した。
- 通常previewで、右下の「港へ戻る」が航路パネル、ロックラベル、フッター説明文と重ならないことを再確認した。
- 証拠: `docs/qa/evidence/shipyard/2026-07-05_rf3_palette_preview.png`。
- 検証: `shipyard_smoke.tscn`、`save_system_verify.sh`、`validate_project.sh` green。
