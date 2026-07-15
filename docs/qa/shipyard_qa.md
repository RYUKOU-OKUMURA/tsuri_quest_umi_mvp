# 船着き場 QA判断ログ

最終更新: 2026-07-15 / 状態: INPUT-SHIPYARD収束 / 帰港導線・RF3 freeze維持
参照画像: なし（`docs/28_harbor_return_placement_unification.md` の配置規約を正とする）
QA更新コマンド: `HOME=/tmp/tsuri_shipyard_home /Applications/Godot.app/Contents/MacOS/Godot --path . res://tools/shipyard_preview.tscn -- --state=available_focus --output=<evidence path>`

## 1. freeze値（正本）

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 論理画面サイズ | 1280x720 | `tools/shipyard_preview.tscn` | 他showcase画面と同じ固定キャンバス運用 |
| 港へ戻る導線 | `_place_control(root, _return_button, 0.842, 0.912, 0.976, 0.976)` | `src/ui/shipyard_screen.gd` `_build_footer()` | docs/28の「画面右下 = 港へ戻る」規約に合わせる。幅とy帯は旧配置を維持 |
| フッター説明 | `_place_control(root, _footer_label, 0.270, 0.912, 0.768, 0.976)` | `src/ui/shipyard_screen.gd` `_build_footer()` | RF4では触らないfreeze値 |
| キーボード候補 | 船カード3件＋購入＋港へ戻る | `src/ui/shipyard_screen.gd` `_configure_keyboard_focus()` | 初期focusは選択中の船カード。購入disabled時は候補から外す |
| focus遷移 | 矢印は画面配置順、Tab / Shift+Tabは有効候補を循環 | `src/ui/shipyard_screen.gd` `_refresh_keyboard_navigation()` | 資金不足・所有済み・全所有でdisabled購入をskip |
| 可視focus | `ScreenBase` 共通4px `Palette.GOLD_BRIGHT` | `setup_keyboard_focus()` 適用後 | 造船所ローカルの空styleを共通focus styleで上書きし、normalと識別可能にする |
| 戻る入力 | `ScreenBase` 共通cancel handlerで港へ戻る | `src/ui/shipyard_screen.gd` `_return_to_harbor()` | Escapeの1 pressにつき1回。echoは消費 |

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

- visual QA専用シェルは未整備。通常起動の `shipyard_preview.tscn` で、2026-07-15の購入可能／購入後focus証拠を1280x720で再生成できる。専用シェル整備は `SHIPYARD-D0` のtooling課題として維持する。

## 5. 現在の残ギャップ

- 船着き場専用のreference画像は未整備。現時点ではdocs/28の右下配置規約と実スクショで判断する。
- 専用visual QAシェル未整備（`SHIPYARD-D0`で扱う）。INPUT-SHIPYARDの入力findingは0。

## 6. フェーズスコープ宣言（作業中のみ）

- 現在作業中のP2フェーズなし。

## 7. 判断ログ（直近パスのみ）

2026-07-15 INPUT-SHIPYARD:

- 変更仮説は「既存5操作を `ScreenBase` 共通入力契約へ登録し、購入disabled化時だけ安全にfocusを退避すれば、マウス契約を保ったままキーボードfindingを0にできる」。船カード3件、購入、港へ戻るへ矢印／Tabで到達できるgraphを画面側に定義した。
- 購入成功でfocus中の購入ボタンがdisabledへ変わった場合は、選択中の船カードへ退避する。資金不足・所有済み・全所有では購入をgraphから外す。
- 戻るは既存の帰港先を変えず、共通cancel handlerへ接続してEscape echoを含む1 press 1回を固定した。
- 不動値: 3船カードと中央／航路／フッターの全矩形、帰港導線右下、船着き場固有PNG、価格・購入・恒久unlock・economy契約、RF3 palette、採用済み素材。

| 状態 | 固定データ | 有効候補 / 初期・退避focus | 証拠 / smoke契約 |
|---|---|---|---|
| 資金不足 | 500 G・船なし | 4件 / 小型船カード | `shipyard_input_smoke`: 購入disabled skip、矢印、Enter一重 |
| 購入可能 | 4,000 G・船なし | 5件 / 小型船カード（証拠では購入へ移動） | `docs/qa/evidence/shipyard/2026-07-15_input_available_buy_focus.png` |
| 購入成功直後 | 400 G・小型船所有 | 4件 / 購入から小型船カードへ退避 | `docs/qa/evidence/shipyard/2026-07-15_input_purchased_focus_fallback.png`。smokeは非defaultの沖釣り船購入でも同契約を確認 |
| 全所有 | 999,999 G・3船所有 | 4件 / 外洋船カード | `shipyard_input_smoke`: 購入skip、帰港到達 |

- 原寸確認では、購入可能状態の購入ボタンと購入後状態の小型船カードに共通focus枠が表示され、同じ画面内のnormal操作と識別できる。購入後も文字欠け・重なり・既存freezeの移動はない。
- マウスは実 `InputEventMouseButton` で船選択→購入→港へ戻るを回帰確認した。キーボードは実 `InputEventKey` で矢印／Tab／Enter／Escapeを確認し、private handler直呼びを入力根拠にしていない。
- 検証: `shipyard_smoke.tscn`、`shipyard_input_smoke.tscn`、E11入力probe（SHIPYARD finding 0）、`validate_project.sh`、`git diff --check` green。`e11_qa_harness_verify.sh` は製品findingではなく、新設scene `tools/shipyard_input_smoke.tscn` の共有release test manifest未登録だけでfailするため、3画面統合時に親ownerが一括同期する。
