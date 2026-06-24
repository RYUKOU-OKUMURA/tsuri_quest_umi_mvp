# 11. 水中ファイト看板画面 実装仕様

## 目的

`reference/02_underwater_fight_mockup.png` を水中ファイト画面の品質基準にする。まずはクロダイ戦 1 画面だけを、背景・魚・UI 枠・ゲージ・演出が揃った看板画面として作り込む。

## 到達ライン

- 水中背景は `_draw()` の図形ではなく、専用ラスタ背景を敷く。
- 主役魚は楕円やポリゴンではなく、透明 PNG のスプライトシートで表示する。
- 釣り糸、エサ、ヒット演出、泡、魚影は背景と魚に重なるレイヤーとして扱う。
- 既存の釣りロジック、テンション、魚体力、深度、行動名は維持する。
- 本番アート到着時に、同じファイルスロットへ PNG を差し替えれば画面品質を上げられる構造にする。

## 現在素材の扱い

`tools/generate_underwater_showcase_assets.py` で生成した初期 PNG は、素材ベース表示の技術検証用であり、完成方向の土台ではない。現在の `underwater_battle_bg.png`、`kurodai_showcase_sheet.png`、`hit_burst.png` は AI 生成素材を取り込んだ本番寄りパスに更新済みだが、画面全体の品質判定は引き続き `reference/02_underwater_fight_mockup.png` との横並び比較で行う。

次フェーズでは、コード生成の簡易素材を磨くのではなく、以下を満たす完成素材を作ってから組み込む。

- クロダイは魚らしいシルエット、鱗、ヒレ、目、背と腹の陰影が読める。
- 背景は岩場、海藻、泡、光芒、遠景魚、海底の奥行きを持つ。
- 下部 HUD と右パネルは、参照画像の情報カード品質に近い専用枠素材を使う。
- 金色の格子状・デバッグ風に見える UI スキンは使わない。

## レイヤー構成

1. `underwater_battle_bg.png`
   水面光、光芒、海底、岩、海藻、遠景魚、泡を含む 16:9 背景。
2. 動的深度表示
   現在深度と目盛り。背景上に半透明で重ねる。
3. 釣り糸・エサ
   既存ロジックの位置に合わせて動的描画する。
4. `kurodai_showcase_sheet.png`
   主役魚。4 フレーム構成で、遊泳・緊張・突進・疲労を切り替える。
5. `hit_burst.png`
   アワセ直後の「ヒット！」演出。短時間だけ魚の手前に表示する。
6. HUD / 情報 UI
   上部ステータスバー、下部ゲージ、右パネル、ボタンは既存 Control UI を維持しつつ、順次画像枠へ差し替える。
7. `sidebar_frame.png`
   右側の魚情報・行動・タックルカード用の縦長フレーム素材。文字、魚、行動表示は Godot 側で重ねる。
8. `top_status_frame.png`
   時計、天候、所持金、地点/水深の上部ステータスバー用フレーム素材。文字と数値は Godot 側で重ねる。
9. `fight_hud_frame.png`
   下部操作盤の一体型フレーム素材。ゲージ色、現在位置、操作文字、エサ情報は Godot 側で重ねる。

## 最小素材セット

| ファイル | 役割 | 現在の作り方 | 本番差し替え時の条件 |
|---|---|---|---|
| `assets/showcase/underwater/underwater_battle_bg.png` | 水中背景 | `tools/generate_underwater_showcase_assets.py` で生成 | 16:9、暗部と主役魚のコントラストを確保 |
| `assets/showcase/underwater/kurodai_showcase_sheet.png` | クロダイ | 4 フレーム PNG スプライトシート | 透明背景、横 4 フレーム、全フレーム同サイズ |
| `assets/showcase/underwater/hit_burst.png` | ヒット演出 | 透明 PNG | 中央配置して読めるサイズ、透明背景 |
| `assets/showcase/underwater/sidebar_frame.png` | 右パネルフレーム | 生成 UI 素材 | テキストなし、魚なし、縦長フレームとして全面表示 |
| `assets/showcase/underwater/top_status_frame.png` | 上部ステータスバー | 生成 UI 素材 | テキストなし、横長フレームとして全面表示 |
| `assets/showcase/underwater/fight_hud_frame.png` | 下部操作盤フレーム | 生成 UI 素材 | テキストなし、左カラム幅の二段HUDとして全面表示 |

## 実装方針

- `UnderwaterView` は上記 PNG が存在すれば素材版を優先する。
- PNG がない場合は既存の procedural 描画にフォールバックする。
- 魚スプライトの位置、向き、状態は `FishingSimulator.visual_position`、`visual_direction`、`action_name`、`fish_stamina_ratio()` から決める。
- `FightStatusBar` は `top_status_frame.png` を敷き、時計・天候・所持金・水深のテキストだけを Godot 側で重ねる。
- `FightHud` は画面全幅ではなく左カラム内に置き、`fight_hud_frame.png` の上にゲージ色、現在位置、深度、操作文字を重ねる。
- `UnderwaterView` は主役魚とヒット演出のスケールを参照画像寄りに抑え、深度目盛りは背景に馴染む低コントラスト表示にする。
- 画面の完成度チェックは、Godot で `tools/fishing_fight_preview.gd` のキャプチャを取り、`tools/build_fight_comparison_html.py` でリファレンスと横並び比較する。

## 品質ゲート

毎回 `/tmp/tsuri_fishing_fight.png` と `reference/02_underwater_fight_mockup.png` を横並びで見て、以下を判定する。

1. 密度：背景、魚、UI、演出に参照画像相当の描き込みがあるか。
2. 余白：水中表示、右パネル、下部 HUD の占有率が参照に近いか。
3. 色：水中の青緑、暗部、金縁、情報カードの明度が破綻していないか。
4. 魚の存在感：クロダイが画面主役として読めるか。
5. UI枠の質：JRPGウィンドウ/情報カードとして見えるか。格子状・仮テーマ・デバッグ風に見える場合は不合格。

## 次に本番化する素材

1. 右パネルの重ね文字、魚肖像、行動/タックルアイコンを最終調整する。
2. 上部ステータス、下部 HUD、右パネルの機能アイコンを本番素材として統一する。
3. 魚のシルエット/ポーズ、ヒット文字、演出位置を最終調整する。
4. 泡、光粒、魚影を個別スプライトまたは CPUParticles2D に分離する。
5. 日本語ピクセルフォントを確定する。
