# 46. E11 設定・音声 基礎仕様

Date: 2026-07-13
対象: E11-SETTINGS-AUDIO / E11-SLOT-DELETE UI / E11-DISPLAY

## 0. スコープ

既存の `BGM音量` / `SE音量` と往復導線を維持し、現在対象の1スロットを安全に削除するUIを追加する。E11-DISPLAYでは子供にも分かる大きなフルスクリーン切替と、1280x720を基準にした16:9固定表示を追加する。解像度選択、共通入力改修、外部公開設定は存在しない領域として追加しない。

既存設定画面への新UIブロック追加である。専用の完成モックは無いため、`docs/19` のメニュー画面文法と既存共通キットを正とする。専用PNGは作らず、共通フレーム・ボタンと runtime テキストで v1 を構成する。

## 1. 画面分解

### 状態

入口は2種類ある。タイトル入口はタイトルで選択中の `target_slot_id`、港入口は `PlayerProgress.active_save_slot` を削除対象にする。設定側は受け取った値を整数かつ `1..SAVE_SLOT_COUNT` の範囲だけ採用し、不正値は入口に応じた安全値へ戻す。値変更は即時に Audio Bus へ反映し、操作確定ごとに保存する。

| 状態 | 表示 | 主操作 | `ui_cancel` |
|---|---|---|---|
| 通常 | 音声2行、削除対象slot要約、削除入口、戻る | 音量変更 / 「このスロットを削除」 | 入口画面へ戻る |
| 確認1 | slot番号・Lv・プレイ時間、不可逆警告、続行/やめる | 安全側の「やめる」 | 通常へ戻り、削除入口へfocus |
| 最終確認 | 同じ要約と「元に戻せない」最終警告、削除/戻る | 安全側の「戻る」 | 確認1へ戻り、安全側の「やめる」へfocus |
| 失敗 | 通常画面内に `message`、なければ `reason` の日本語説明 | 再度削除入口を選べる | 入口画面へ戻る |

### 存在する領域

| 領域 | 役割 |
|---|---|
| 上部 | 画面名「せってい」と短い説明 |
| 中央 | BGM音量行、SE音量行。各行は名称、スライダー、百分率 |
| 中央下 | 削除対象slotの番号・Lv・プレイ時間、削除入口、空slotまたは失敗理由 |
| 下部右 | 入口へ戻る主操作。`ScreenBase.make_return_button()` を使用 |
| 下部左 | キーボード / ゲームパッドの操作ヒント |
| 確認時中央 | 共通フレームを使うモーダル。二段階とも安全側操作を初期focusにする |
| 中央パネル上部右 | 「フルスクリーン: オン / オフ」を一目で読める大きな切替。音声行・削除領域とは横方向に分離し、状態だけが変わる |

### 存在しない領域・非採用要素

- 解像度選択、ウィンドウサイズ選択、ボーダーレス別モード
- キーコンフィグ、入力方式切替
- 音声ミュートの別トグル、音量プリセット
- Lv、所持金、装備など設定と無関係なプレイヤー情報
- 新規専用PNG、日本語焼き込み素材
- 他slotの一覧・切替、settings.json削除、キーコンフィグ、正式名/icon/splash

### 操作と入力

- 主操作: 通常は選択中スライダーの左右変更。削除フロー中は各段階の安全側ボタン。
- 補助操作: 上下で BGM / SE / フルスクリーン / 削除 / 戻るを移動、通常時のキャンセルで入口へ戻る。
- マウス: スライダー操作と戻るボタン。
- キーボード / ゲームパッド: Godot標準 `ui_up/down/left/right/accept/cancel` を使用する。共通 InputMap は変更しない。
- 初期focusは BGM スライダー。フォーカスは BGM → SE → フルスクリーン → 削除 → 戻るの縦順で循環させない。空slotではdisabledの削除を飛ばして戻るへ進む。

### 代表状態・高リスク状態

| 状態 | 値 | 観測点 |
|---|---|---|
| 既定 | BGM 80 / SE 80 | 初期focus、百分率、主導線 |
| 境界 | 0 / 100 | 表示見切れなし、bus mute相当のdB変換 |
| 復元 | 任意の異なる値 | 再生成後も slider / bus が一致 |
| 破損 | 不正JSON、型不正、範囲外 | 安全な既定値へ戻り、正規化ファイルを保存 |
| 空slot | `has_save=false` かつartifactなし | 削除disabled、理由表示 |
| future/unknown/invalid artifact | 要約可能な範囲＋artifact状態 | 削除は可能、必ず二段階確認 |
| 削除失敗 | backend `ok=false` | 画面維持、message/reason表示、再操作可能 |
| tmp-only / 部分削除失敗 | main/backup候補が無くてもartifact残存 | 削除入口を維持し、再試行成功でmain/backup/tmpを完全削除 |

固定アンカーはタイトルと戻るボタン。通常状態内で動くのはスライダーつまみ、百分率、削除対象の状態文だけで、確認は中央モーダルとして重ねる。

### E11-DISPLAYの状態分解（2026-07-13）

| 状態 | 表示 | 主操作 | 保存・復元 | 高リスク観測 |
|---|---|---|---|---|
| windowed | `フルスクリーン: オフ` | 切替ボタンを押す | `fullscreen=false` を `user://settings.json` へ即時保存し、ウィンドウモードへ適用 | 通常ボタンとの状態差、normal/hover/pressed/focus、既存音声・削除行の不変 |
| fullscreen | `フルスクリーン: オン` | 切替ボタンを押す | `fullscreen=true` を保存し、フルスクリーンへ適用 | 大きな文字の収まり、設定画面の再生成、BGM/SEとslot削除導線の維持 |
| 起動時・設定再読込 | 保存済み値に一致する表示モード | 起動／画面生成 | 欠損・破損・型不正・範囲外の設定は既存既定値（fullscreen=false、BGM/SE=80）へ正規化して保存 | `DisplayServer.window_set_mode` の最終モードとsettings.jsonのbool一致 |
| 16:10 / 4:3 runtime | 16:9ゲーム領域＋黒帯 | 操作は通常状態と同じ | 表示モード設定とは独立 | 1280x800は上下各40px、1024x768は上下各96pxの黒帯。ゲーム領域の縦横比は16:9 |

#### E11-DISPLAYの存在する領域 / 存在しない領域

- **存在する**: 中央パネル上部右の大きな切替ボタン、オン/オフのruntime文言、`settings.json`の`fullscreen`、起動時と設定再生成時の`DisplayServer.window_set_mode`適用、16:9ゲーム領域と余剰領域の黒帯。
- **存在しない**: 解像度選択、ウィンドウサイズ選択、ボーダーレス別モード、キーコンフィグ、ゲームパッド対応、fullscreen専用PNG、日本語を焼き込んだ素材、他画面のレイアウト変更。

#### 主操作・共通キット/runtime分担

- 主操作はフルスクリーン切替。既存設定画面の主導線（音量変更、対象slot削除、入口へ戻る）を補助操作として維持する。
- ボタン面は `assets/showcase/common/action_button_frame.png` を共通キットとして使い、オン/オフ文言とhover/pressed/focusはruntimeで描画・適用する。専用PNGは作らない。
- 1280x720のデザイン座標、`stretch/mode=canvas_items`、`stretch/aspect=keep`、黒帯はproject/runtime設定の責務。表示モードの保存・正規化・復元は設定データの責務。黒帯の寸法と色は実runtime画像で確認する。

#### E11-DISPLAYのsmoke観点

1. 既定値 `fullscreen=false`、切替で`true/false`が即時保存され、`DisplayServer.window_get_mode()` と一致する。
2. 設定画面を再生成・起動時相当再適用しても、slider・BGM/SE bus・fullscreen表示が保存値へ復元する。
3. `fullscreen`欠損、bool以外、JSON破損、version不正は既存既定値へ安全復帰し、正規化ファイルを残す。
4. 既存のBGM/SE保存復元、タイトル/港導線、対象slot削除、二段階確認、失敗時再試行、normal/hover/pressed/focus、戻る導線を回帰する。
5. 1280x720、16:10（1280x800）、4:3（1024x768）の実runtime画像で、ゲーム領域が16:9のまま保たれ、期待した上下黒帯寸法になることを自動検査する。

## 2. 描画分担

| 対象 | 担当 |
|---|---|
| 外周・中央パネル・ボタン | `assets/showcase/common/` の既存共通キット |
| 背景色、補助的な減光 | `Palette.*` を使う runtime 描画 |
| 見出し、説明、行名、百分率、操作ヒント | `GameFonts` 経由の runtime テキスト |
| スライダー値・focus・hover・pressed | Godot runtime状態 |
| slot番号・Lv・プレイ時間・警告・結果 | `PlayerProgress.save_slot_summary()` / 削除resultを使うruntimeテキスト |
| 確認モーダル、削除ボタン | 既存 `card_frame.png` / `action_button_frame.png` とruntime状態 |

画面専用一点物は不要。共通キットに無い質感を画面ローカルの `StyleBoxFlat` で代替しない。

## 3. 設定データ契約

- 保存先: `user://settings.json`。ゲーム進行セーブとは独立。
- キー: `version`、`bgm_volume`、`se_volume`、`fullscreen`。音量は整数相当の 0〜100、fullscreenはbool。
- 既定値: BGM 80、SE 80、fullscreen=false。
- 読込時は欠損、JSON破損、Dictionary以外、非数値、非有限値、範囲外、fullscreenのbool以外を既定値へ正規化する。
- 0 は対象busを mute、それ以外は `linear_to_db(value / 100.0)`。busが無い環境でもクラッシュせず保存・UI操作は成立する。
- `default_bus_layout.tres` に `Master` 直下の `BGM` / `SE` を定義する。既存BGM playerは `BGM`、効果音と catch fanfare は `SE` に接続する。

## 4. 画面遷移契約

- `main.gd` が `settings` routeを所有し、`SettingsScreen`を生成する。
- タイトルからは `{return_screen_id = "title"}`、港からは `{return_screen_id = "harbor"}` を渡す。
- タイトルからはさらに `{target_slot_id = <タイトルで選択中のslot>}` を明示する。港では設定側が `PlayerProgress.active_save_slot` を採用する。
- 設定画面は任意のroute値を信用せず、上記2値以外を `title` に戻す。
- 設定表示中も opening BGM は継続し、変更結果をその場で聴ける。
- 削除可否はロード候補の有無ではなく `save_slot_artifact_status()` のmain/backup/tmp存在で判断する。`storage_blocked` はartifact/空判定より優先し、削除disabledとbackend messageを表示する。

## 5. smoke 観測点

`tools/settings_smoke.tscn` は隔離した `user://` で次を検証する。

1. BGM / SE busが存在する。
2. slider変更が対応busの音量・muteへ反映される。
3. 変更値が `settings.json` に保存される。
4. 設定画面を再生成すると slider と bus が保存値へ復元される。
5. 欠損ファイルは既定値、不正JSON・型不正・範囲外は安全な既定値へ復旧する。
6. fullscreenの既定値、切替保存、設定再生成・起動時相当復元、`DisplayServer.window_set_mode`適用が最終保存値と一致する。
7. 初期focus、BGM / SE / fullscreen / 戻るのfocus隣接、`ui_cancel` の戻り先を検証する。
8. タイトルと港に `settings` 導線が存在し、payloadの戻り先が正しい。
9. 解像度UIが存在しない。タイトル選択slot / 港active slotが対象となり、不正payloadは範囲内へ安全に正規化される。
10. 空slotはdisabled。通常→確認1→取消、確認1→確認2→取消、最終確定成功、各段階の`ui_cancel`とfocus復帰を検証する。
11. slot/Lv/プレイ時間が両確認に表示され、`delete_save_slot()` は最終確定時だけ1回呼ばれる。
12. 成功時はtitleへ遷移し、失敗時は画面維持＋理由表示＋再操作可能。
13. 実ファイル統合では対象slotのmain/backup/tmpだけが消え、他2slotとsettings.jsonがbyte不変、削除slotが終了時に再生成されないことを確認する。
14. tmp-only初期状態と、main/backup/tmp各段階の削除失敗→同じ画面から再試行成功を検証する。
15. 削除・続行・最終削除・fullscreen切替はbutton signal経由で操作し、callback配線を含めて検証する。
16. smoke/previewは明示opt-in、`TSURI_QA_ISOLATED_HOME` の絶対パスと`HOME`の正規化一致、trusted runnerがHOME直下へ作るguard sentinelと実行tokenの内容一致がすべて揃う前にwrite/cleanupを行わずfail-closed。visual wrapperは既存HOMEを再利用せず、物理パス解決後も`/private/tmp`配下であることを確認した親から毎回fresh HOMEを作り、symlink外周逸脱を拒否して終了時に破棄する。標準release verifierはsettings専用runnerだけへtestごとの隔離HOME絶対パス・opt-in・sentinel/tokenを付与し、削除統合試験を省略せず実行する。
17. `./tools/settings_isolation_self_test.sh` で、HOME不一致・token不一致・rawの`.`/`..`/前後空白/非正規表記、HOME祖先/final componentとuser-data root / slots / slot directoryのnested symlink（matching sentinel/tokenを含む）をwrite前exit 2とし、main / backup / tmp / settings / markerのbyte不変を検証する。raw expected / raw actual相当は共有pure helperで同じ判定を使い、engine初期化前にraw HOMEが不安定なケースは通常guardを緩めない拒否専用probeで両sceneから直接固定する。guardは`user://`のglobalize先が物理expected HOME配下（`expected + "/"`境界）であること、およびsettings・save root・全slot/artifact親の既存祖先が検査可能で非linkであることも要求する。通常visual/release runnerは拒否専用probeを継承しない。

## 6. visual QA 観測点

- 1280x720、1280x800（16:10）、1024x768（4:3）の実runtimeスクリーンショットを保存し、各画像で16:9ゲーム領域と黒帯の寸法・色を自動検査する。
- 原寸で文字見切れ、ellipsis、重なりがゼロ。
- BGM / SEの情報階層、初期focus、戻る導線が判別できる。
- 0% / 100%でも値表示とレイアウトが崩れない。
- 共通キットの世界観が上・中央・下で揃う。
- 通常、確認1、確認2、失敗、hover、pressed、focusを1280x720で保存し、全画素opaque・全画面黒欠損集計を自動確認する。slot/Lv/プレイ時間、不可逆警告、normal/hover/pressed/focusに見切れ・ellipsis・重なりが無い。
- 通常、確認1、確認2、失敗、hover、pressed、focusを1280x720で保存し、fullscreenのオン/オフ文言と切替ボタンの状態差にも見切れ・ellipsis・重なりが無い。

## 7. E11-SLOT-DELETE UI のfreeze再オープン宣言

- 再オープン: 削除状態文のY位置（panel内298→350）とartifact由来のdisabled/focus。footer well活用と再試行契約のために限る。
- 維持: 1280x720、タイトル/説明、背景、右下戻る矩形、既定音量、音量刻み、設定保存・Audio Bus契約、共通素材、フォント。
- 差分Top3: ①通常状態で削除対象が判別できること、②二段階確認で不可逆性と安全側focusが読めること、③空/失敗状態でも主導線が崩れないこと。

## 8. E11-DISPLAY freeze再オープン宣言

- 再オープン: 中央パネル上部右の切替ボタン矩形、fullscreen表示文言、settings.jsonのfullscreenキー、起動時/再生成時のDisplayServer適用、project.godotのstretch/aspect、解像度matrix evidence。
- 不動値: 既存の音声行、削除ブロック、確認モーダル、右下戻る矩形、既定音量、音量刻み、対象slot契約、BGM/SE bus契約、共通素材、フォント。
