# 46. E11 設定・音声 基礎仕様

Date: 2026-07-12
対象: E11-SETTINGS-AUDIO

## 0. スコープ

`BGM音量` / `SE音量`、設定保存、タイトル・港からの往復、既存音声経路の Audio Bus 接続だけを実装する。fullscreen、解像度、セーブスロット削除、共通入力改修、外部公開設定は存在しない領域として追加しない。

設定画面は完全新規画面。専用の完成モックは無いため、`docs/19` のメニュー画面文法と既存共通キットを正とする。専用PNGは作らず、共通フレーム・ボタンと runtime テキストで v1 を構成する。

## 1. 画面分解

### 状態

1状態の設定画面で、入口だけが2種類ある。`return_screen_id` は `title` または `harbor` に正規化し、戻る操作で入口へ返す。値変更は即時に Audio Bus へ反映し、操作確定ごとに保存する。

### 存在する領域

| 領域 | 役割 |
|---|---|
| 上部 | 画面名「せってい」と短い説明 |
| 中央 | BGM音量行、SE音量行。各行は名称、スライダー、百分率 |
| 下部右 | 入口へ戻る主操作。`ScreenBase.make_return_button()` を使用 |
| 下部左 | キーボード / ゲームパッドの操作ヒント |

### 存在しない領域・非採用要素

- fullscreen、解像度、画面モード
- セーブスロット削除
- キーコンフィグ、入力方式切替
- 音声ミュートの別トグル、音量プリセット
- Lv、所持金、装備など設定と無関係なプレイヤー情報
- 新規専用PNG、日本語焼き込み素材

### 操作と入力

- 主操作: 選択中スライダーの左右変更。
- 補助操作: 上下で BGM / SE 行を移動、キャンセル操作で入口へ戻る、戻るボタン決定。
- マウス: スライダー操作と戻るボタン。
- キーボード / ゲームパッド: Godot標準 `ui_up/down/left/right/accept/cancel` を使用する。共通 InputMap は変更しない。
- 初期focusは BGM スライダー。フォーカスは BGM → SE → 戻るの縦順で循環させない。

### 代表状態・高リスク状態

| 状態 | 値 | 観測点 |
|---|---|---|
| 既定 | BGM 80 / SE 80 | 初期focus、百分率、主導線 |
| 境界 | 0 / 100 | 表示見切れなし、bus mute相当のdB変換 |
| 復元 | 任意の異なる値 | 再生成後も slider / bus が一致 |
| 破損 | 不正JSON、型不正、範囲外 | 安全な既定値へ戻り、正規化ファイルを保存 |

固定アンカーはタイトル、2行の矩形、戻るボタン。値変更で動くのはスライダーつまみと百分率だけ。

## 2. 描画分担

| 対象 | 担当 |
|---|---|
| 外周・中央パネル・ボタン | `assets/showcase/common/` の既存共通キット |
| 背景色、補助的な減光 | `Palette.*` を使う runtime 描画 |
| 見出し、説明、行名、百分率、操作ヒント | `GameFonts` 経由の runtime テキスト |
| スライダー値・focus・hover・pressed | Godot runtime状態 |

画面専用一点物は不要。共通キットに無い質感を画面ローカルの `StyleBoxFlat` で代替しない。

## 3. 設定データ契約

- 保存先: `user://settings.json`。ゲーム進行セーブとは独立。
- キー: `version`、`bgm_volume`、`se_volume`。音量は整数相当の 0〜100。
- 既定値: BGM 80、SE 80。
- 読込時は欠損、JSON破損、Dictionary以外、非数値、非有限値、範囲外を既定値へ正規化する。
- 0 は対象busを mute、それ以外は `linear_to_db(value / 100.0)`。busが無い環境でもクラッシュせず保存・UI操作は成立する。
- `default_bus_layout.tres` に `Master` 直下の `BGM` / `SE` を定義する。既存BGM playerは `BGM`、効果音と catch fanfare は `SE` に接続する。

## 4. 画面遷移契約

- `main.gd` が `settings` routeを所有し、`SettingsScreen`を生成する。
- タイトルからは `{return_screen_id = "title"}`、港からは `{return_screen_id = "harbor"}` を渡す。
- 設定画面は任意のroute値を信用せず、上記2値以外を `title` に戻す。
- 設定表示中も opening BGM は継続し、変更結果をその場で聴ける。

## 5. smoke 観測点

`tools/settings_smoke.tscn` は隔離した `user://` で次を検証する。

1. BGM / SE busが存在する。
2. slider変更が対応busの音量・muteへ反映される。
3. 変更値が `settings.json` に保存される。
4. 設定画面を再生成すると slider と bus が保存値へ復元される。
5. 欠損ファイルは既定値、不正JSON・型不正・範囲外は安全な既定値へ復旧する。
6. 初期focus、BGM / SE / 戻るのfocus隣接、`ui_cancel` の戻り先を検証する。
7. タイトルと港に `settings` 導線が存在し、payloadの戻り先が正しい。
8. fullscreen、解像度、slot削除UIが存在しない。

## 6. visual QA 観測点

- 1280x720の実runtimeスクリーンショットを保存する。
- 原寸で文字見切れ、ellipsis、重なりがゼロ。
- BGM / SEの情報階層、初期focus、戻る導線が判別できる。
- 0% / 100%でも値表示とレイアウトが崩れない。
- 共通キットの世界観が上・中央・下で揃う。
