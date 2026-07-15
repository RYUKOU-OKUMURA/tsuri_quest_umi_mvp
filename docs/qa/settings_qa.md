# 設定画面 QA判断ログ

最終更新: 2026-07-15 / 状態: INPUT-SETTINGS focus契約freeze
参照画像: 専用参照なし。`docs/19_ui_production_playbook.md` のメニュー画面文法と共通キットを正とする
QA更新コマンド: `./tools/settings_visual_qa.sh`

## 1. freeze値（正本）

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 画面寸法 | 1280x720 | 全体 | 固定viewportの実runtime captureで確認 |
| 設定パネル | `Rect2(180, 144, 920, 430)` | 中央 | 音声2行と対象slot削除ブロックが省略なしで収まる |
| BGM行 / SE行 | y=`72` / `142`（panel内） | 中央 | 既存の読み順を維持し削除領域を確保 |
| 削除ブロック | 見出しy=`215`、要約y=`252`、操作y=`250` | 中央下 | slot/Lv/プレイ時間と削除入口を同時判別できる |
| 削除状態文 | y=`350`、h=`48`（panel内footer well） | 中央下 | 通常/失敗文を金縁から離し、暗色well内に上下余白を確保 |
| 二段階確認 | `Rect2(270, 130, 740, 460)` | 中央モーダル | 共通フレーム1枚を状態切替で再利用し、情報アンカーを固定 |
| 戻るボタン | `Rect2(920, 616, 276, 60)` | 右下 | 既存の右下戻る文法を維持 |
| 既定音量 | BGM=`80` / SE=`80` | `settings.json` | 初回に十分聞こえ、最大音量を避ける |
| 音量刻み | 5 | 両slider | キーボード / ゲームパッドで調整回数を抑える |
| focus順 / 可視署名 | BGM → SE → フルスクリーン → 削除（enabled時のみ）→ 戻る。初期BGM、上下/Tabは循環 | 画面内 | 空slotではdisabled削除を飛ばす。全対象はScreenBase共通4px focus ringを使い、確認modalは安全側操作を初期focusにする |
| フルスクリーン切替 | panel内`Rect2(500, 10, 350, 58)` / global`Rect2(680, 154, 350, 58)`、文言 `フルスクリーン: オン / オフ` | 中央パネル上部右 | action_button_frame.pngのvertical patch margin 24+24を吸収し、heading/BGM行と分離。装飾線が文字へ干渉しない |
| 表示設定 | `fullscreen` bool、既定`false`、`stretch/aspect=keep` | `settings_screen.gd` / `project.godot` | 起動時・再生成時に`DisplayServer.window_set_mode`へ適用。16:9領域を維持 |
| 解像度matrix | 1280x720 / 1280x800 / 1024x768 | `settings_visual_qa.sh` | 実ウィンドウcaptureで16:9領域、上下黒帯なし / 各40px / 各96pxを確認 |

## 2. 不採用・再試行禁止リスト

| 案 | 却下理由 | 判断日 |
|---|---|---|
| 設定画面専用PNG | E11-SETTINGS-AUDIOは共通キットでv1固定するスコープ | 2026-07-12 |
| fullscreen / 解像度の先行表示 | E11-DISPLAY着手前に未実装操作を見せる案。現在のfullscreen切替はE11-DISPLAYの採用仕様 | 2026-07-12 |
| 解像度選択・ウィンドウサイズ選択 | E11-DISPLAYの責務はfullscreen切替と16:9 keep＋黒帯であり、選択UIは追加しない | 2026-07-13 |
| 確認ごとに別フレームを重ねる | 同一位置のNinePatchを二重所有すると状態切替時の描画が不安定。1枚を再利用する | 2026-07-12 |
| Lv / 所持金など上部ステータス | 設定操作と無関係で情報重複になる | 2026-07-12 |

## 3. 微調整カウンタ

| パラメータ | 回数 | 直近の変更内容 | 状態 |
|---|---|---|---|
| 装飾パス累計 | 0 | 共通キットのみ | close |
| タイトル / 行文字 | 1 | GameFonts共通ローダーへ統一し、暗部での可読性を確保 | close |
| 削除状態文footer収束 | 2 | panel内y=298→350、h=42→48。既存footer wellへ移し上下余白を確保 | close |
| focus可視署名 | 1 | ScreenBase共通4px ringをBGM/SE sliderとfullscreenへ適用。既存Buttonも同じ署名へ統一 | close |

## 4. 暫定判定・再検証TODO

- `settings_visual_qa.sh` は1280x720の11状態を再生成・合格したが、解像度matrix開始時にローカルSwift/SDK不整合でCoreGraphicsをbuildできず、画面起動前に停止した。既存matrix evidenceは変更せず、ツールチェーン復旧後に再実行する。
- 既存 `settings_smoke.tscn` はclean main `19bf7aad` と本branchの双方で、Title復帰payload/slotの同じ2 assertionが失敗した。INPUT-SETTINGS差分外の基盤既知failureとして分離し、正規runnerで再確認する。

## 5. 現在の残ギャップ

- P3: 専用一点物を持たない簡潔なv1。音量操作と安全な削除導線を優先し、専用装飾は追加しない。

## 6. フェーズスコープ宣言（作業中のみ）

（現在作業中のフェーズなし。INPUT-SETTINGSは採用・freeze済み。）

## 7. 判断ログ（直近パスのみ）

`docs/qa/evidence/settings/2026-07-12_settings_{normal,confirm1,confirm2,failure,hover,pressed,focus}_1280x720.png` をE11-DISPLAY前の既存evidenceとして原寸確認した。beforeはcommit `54b2b91` のnormal/failure（状態文y=298,h=42）で、金縁直上に寄りfooter wellが空いていた。E11-DISPLAYのafterは同じ7状態へ切替ボタンを追加し、`2026-07-13_settings_{normal,confirm1,confirm2,failure,hover,pressed,focus}_1280x720.png` と `2026-07-13_settings_{fullscreen_hover,fullscreen_pressed,fullscreen_focus,fullscreen_on}_1280x720.png` で設定画面と切替ボタンのnormal/hover/pressed/focus、および保存値fullscreen=trueから復元したオン文言を原寸確認した。fullscreen_onは実保存・実読込・表示モード適用後にpreview隔離内だけwindowedへ戻してcaptureした。追加P2対応では切替ボタンをbefore global`Rect2(740,164,290,46)`からafter global`Rect2(680,154,350,58)`へ再収束し、装飾線とオン/オフ文言の干渉がないことを原寸確認した。さらに`2026-07-13_settings_resolution_{1280x720,1280x800,1024x768}.png`を実ウィンドウcaptureし、黒帯全領域の黒画素率・連続境界・content内側境界を実画素検査した。slot/Lv/プレイ時間、不可逆警告、失敗理由、fullscreen文言、ボタンに見切れ・ellipsis・重なりは無い。専用PNG・fullscreen以外の表示設定・キー設定は追加していない。

2026-07-15 INPUT-SETTINGSでは、全freeze矩形、文言、素材、font、palette、音量/save/display/deleteロジックを不動のまま、BGM/SE sliderとfullscreenへScreenBase共通focus styleを適用した。focus graphはBGM→SE→fullscreen→削除（enabled時のみ）→戻るの循環へ明示し、`2026-07-15_input_bgm_focus.png` と `2026-07-15_input_fullscreen_focus.png` を1280x720原寸で確認した。実 `Viewport.push_input(InputEventKey)` のsmokeでslider左右、Tab/上下巡回、disabled削除skip、Enter/Escapeの単発発火、二段階確認の安全側初期focus・背景隔離・復帰を確認した。E11 probeのSETTINGSは `INPUT_FOCUS_STYLE_MISSING` 3件→0件、全体finding 35件→34件となった。
