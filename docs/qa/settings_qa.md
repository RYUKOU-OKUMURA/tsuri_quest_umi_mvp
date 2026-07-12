# 設定画面 QA判断ログ

最終更新: 2026-07-13 / 状態: E11-DISPLAY freeze
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
| focus順 | BGM → SE → フルスクリーン → 削除 → 戻る | 画面内 | 空slotではdisabled削除を飛ばし、安全側操作を確認時の初期focusにする |
| フルスクリーン切替 | `Rect2(740, 164, 290, 46)`、文言 `フルスクリーン: オン / オフ` | 中央パネル上部右 | 共通`action_button_frame.png`上にruntime文言を描画。既存音声行・削除領域と重ならない |
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

## 4. 暫定判定・再検証TODO

なし。

## 5. 現在の残ギャップ

- P3: 専用一点物を持たない簡潔なv1。音量操作と安全な削除導線を優先し、専用装飾は追加しない。

## 6. フェーズスコープ宣言（作業中のみ）

| 状態 | 固定seed/データ | 表示/非表示 | 固定アンカー | 可変領域 | evidence出力 | smoke契約 |
|---|---|---|---|---|---|---|
| windowed / fullscreen | 既存settings・slot seed、BGM80/SE80 | fullscreen切替とオン/オフ文言を表示。解像度選択は非表示 | 既存タイトル、音声行、削除ブロック、確認モーダル、右下戻る | 追加切替ボタンの状態文言とwindow mode | `settings_fullscreen_*_1280x720.png`、解像度matrix画像 | settings保存、再読込、DisplayServer適用、既存全契約回帰 |
| 16:10 / 4:3 | 1280x800 / 1024x768 | 16:9ゲーム領域＋黒帯 | ゲーム座標1280x720 | 余剰領域の黒帯だけ | `settings_resolution_{1280x800,1024x768}.png` | 黒帯寸法・色を画像検査 |

再オープン理由と差分を明記する。beforeはfullscreen UIなし、`stretch/aspect=expand`、解像度matrix未実装。afterは中央パネル上部右の大きなruntime切替、`fullscreen`保存/復元、`stretch/aspect=keep`、16:10/4:3の実runtime黒帯証拠。既存音声行、削除ブロック、確認モーダル、右下戻る矩形、BGM/SE bus、フォントは不動値とする。

## 7. 判断ログ（直近パスのみ）

`docs/qa/evidence/settings/2026-07-12_settings_{normal,confirm1,confirm2,failure,hover,pressed,focus}_1280x720.png` をE11-DISPLAY前の既存evidenceとして原寸確認した。beforeはcommit `54b2b91` のnormal/failure（状態文y=298,h=42）で、金縁直上に寄りfooter wellが空いていた。E11-DISPLAYのafterは同じ7状態へ切替ボタンを追加し、`2026-07-13_settings_{normal,confirm1,confirm2,failure,hover,pressed,focus}_1280x720.png` と `2026-07-13_settings_{fullscreen_hover,fullscreen_pressed,fullscreen_focus}_1280x720.png` で設定画面と切替ボタンのnormal/hover/pressed/focusを原寸確認した。さらに`2026-07-13_settings_resolution_{1280x720,1280x800,1024x768}.png`を実ウィンドウcaptureし、16:9ゲーム領域と黒帯寸法（なし / 上下40px / 上下96px）を画素検査した。slot/Lv/プレイ時間、不可逆警告、失敗理由、fullscreen文言、ボタンに見切れ・ellipsis・重なりは無い。専用PNG・fullscreen以外の表示設定・キー設定は追加していない。
