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

`tools/generate_underwater_showcase_assets.py` で生成した初期 PNG は、素材ベース表示の技術検証用であり、完成方向の土台ではない。現在の `underwater_battle_bg.png` は AI 生成素材を取り込んだ本番寄りパスで、`kurodai_showcase_sheet.png` はリファレンス魚の切り出しを背景抽出して作った高品質パスである。`hit_burst.png` は `tools/process_underwater_fish_assets.py` で青い水しぶき素材として再生成し、暖色は Godot 側の「ヒット！」文字だけに寄せている。画面全体の品質判定は引き続き `reference/02_underwater_fight_mockup.png` との横並び比較で行う。

`sidebar_frame.png`、`top_status_frame.png`、`fight_hud_frame.png` は、生成素材の金飾りが強すぎたため `tools/generate_underwater_ui_frame_assets.py` で参照画像寄りの紙カード/濃紺ゲージ台として作り直している。これは最終美術素材ではなく、文字・ゲージ・アイコンが破綻しない完成寄りの枠素材スロットである。`FishingScreen` では右サイドバー外側の汎用パネルを外し、専用 `sidebar_frame.png` が直接画面に出るようにしている。現行の生成ルールでは `_draw_clean_card()` を使い、黒い太枠・鋲・強い金線を減らして、参照画像の紙カード寄りに軽量化している。

`kurodai_showcase_sheet.png` と `hit_burst.png` は、`kurodai_chroma_source.png` を元に `tools/process_underwater_fish_assets.py` で生成する。処理内容は、クロマキー除去、マゼンタ縁のデスピル、単体魚または4フレーム素材の正規化、ヒットバッジ生成である。生成元は内製差し替え用の中間素材で、画面表示は最終PNGのみを参照する。

水中ファイトの主要文字は `src/ui/fight_fonts.gd` から `MPLUS1p-Bold.ttf` を使う。通常テーマ全体は既存の `MPLUS1p-Regular.ttf` を維持し、看板画面の上部ステータス、HUD、右パネル、ヒット文字だけ太い表示に寄せる。

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
10. `fight_icon_sheet.png`
   時計、天候、風、コイン、テンション、魚体力、エサ、行動、タックルの共通アイコンシート。3x3 グリッドで各 UI が同じ素材を参照する。

## 最小素材セット

| ファイル | 役割 | 現在の作り方 | 本番差し替え時の条件 |
|---|---|---|---|
| `assets/showcase/underwater/underwater_battle_bg.png` | 水中背景 | `tools/generate_underwater_showcase_assets.py` で生成 | 16:9、暗部と主役魚のコントラストを確保 |
| `assets/showcase/underwater/kurodai_chroma_source.png` | クロダイ中間素材 | リファレンス魚の切り出しを ImageGen で背景抽出 | フラットなマゼンタ背景、単体魚または横4フレーム |
| `assets/showcase/underwater/kurodai_showcase_sheet.png` | クロダイ | `tools/process_underwater_fish_assets.py` で生成 | 透明背景、横 4 フレーム、全フレーム同サイズ |
| `assets/showcase/underwater/hit_burst.png` | ヒット演出 | `tools/process_underwater_fish_assets.py` で生成 | 濃紺の水しぶき、透明背景、文字は含めない |
| `assets/showcase/underwater/sidebar_frame.png` | 右パネルフレーム | `tools/generate_underwater_ui_frame_assets.py` で生成 | テキストなし、魚なし、縦長フレームとして全面表示 |
| `assets/showcase/underwater/top_status_frame.png` | 上部ステータスバー | `tools/generate_underwater_ui_frame_assets.py` で生成 | テキストなし、横長フレームとして全面表示 |
| `assets/showcase/underwater/fight_hud_frame.png` | 下部操作盤フレーム | `tools/generate_underwater_ui_frame_assets.py` で生成 | テキストなし、左カラム幅の二段HUDとして全面表示 |
| `assets/showcase/underwater/fight_icon_sheet.png` | 共通機能アイコン | 生成 UI 素材 | 透明 PNG、3x3 グリッド、各セル同サイズ |
| `assets/fonts/MPLUS1p-Bold.ttf` | 水中ファイト主要UIフォント | Google Fonts の M PLUS 1p Bold | OFL同梱、見出し/数値/ヒット文字用 |
| `assets/fonts/OFL-MPLUS1p.txt` | M PLUS 1p ライセンス | Google Fonts 由来 | フォント更新時も保持 |

## 実装方針

- `UnderwaterView` は上記 PNG が存在すれば素材版を優先する。
- PNG がない場合は既存の procedural 描画にフォールバックする。
- 魚スプライトの位置、向き、状態は `FishingSimulator.visual_position`、`visual_direction`、`action_name`、`fish_stamina_ratio()` から決める。
- `FightStatusBar` は `top_status_frame.png` を敷き、時計・天候・所持金・水深のテキストだけを Godot 側で重ねる。
- `FightHud` は画面全幅ではなく左カラム内に置き、`fight_hud_frame.png` の上にゲージ色、現在位置、深度、操作文字を重ねる。
- `FightStatusBar`、`FightHud`、`FightSidebar` は `fight_icon_sheet.png` の3x3セルを使い、コード描画アイコンを本番素材へ置き換える。
- `FightStatusBar`、`FightHud`、`FightSidebar`、`UnderwaterView` のヒット文字は `src/ui/fight_fonts.gd` から水中ファイト専用の太字フォントを読み込む。
- 右パネルは汎用 `make_panel()` の中に入れず、`FightSidebar` の専用フレームを直接表示する。二重枠にするとサイドバー素材が縮み、参照画像のカード品質から離れるため。
- `UnderwaterView` は主役魚とヒット演出のスケールを参照画像寄りに抑え、深度目盛りは背景に馴染む低コントラスト表示にする。
- `tools/fishing_fight_preview.gd` は参照比較用に `クロダイ / レア / 44.2cm` 相当の固定状態を作り、画面品質の比較条件を揃える。ゲーム本編の魚データは別途維持する。
- 画面の完成度チェックは、Godot で `tools/fishing_fight_preview.gd` のキャプチャを取り、`tools/build_fight_comparison_html.py` と `tools/build_fight_comparison_images.py` でリファレンスと横並び比較する。

## 品質ゲート

毎回 `/tmp/tsuri_fishing_fight.png` と `reference/02_underwater_fight_mockup.png` を横並びで見て、以下を判定する。

1. 密度：背景、魚、UI、演出に参照画像相当の描き込みがあるか。
2. 余白：水中表示、右パネル、下部 HUD の占有率が参照に近いか。
3. 色：水中の青緑、暗部、金縁、情報カードの明度が破綻していないか。
4. 魚の存在感：クロダイが画面主役として読めるか。
5. UI枠の質：JRPGウィンドウ/情報カードとして見えるか。格子状・仮テーマ・デバッグ風に見える場合は不合格。

## 次に本番化する素材

1. `sidebar_frame.png` は行動/タックル下段カード拡張、内部罫線、角ブラケット追加、主要見出しの光学サイズ調整まで完了。次は最終比較で本文が軽く見える場合だけ詰める。
2. `fight_hud_frame.png` の上段は深度プレート強化、暗色化、HUDアイコン縮小、右ラベル余白調整まで完了。次は最終比較で残るラベル違和感だけを詰める。
3. 上部ステータスの地点カードは参照に合わせてアイコンなし中央寄せに修正済み。上部アイコン群は縮小済みで、差し替えは最終比較でまだ装飾過多に見える場合だけ行う。
4. ヒット演出は白い放射線と下端の重なりを調整済み。最終 HUD/フォント調整後に比較だけ再確認する。
5. 泡、光粒、魚影を個別スプライトまたは CPUParticles2D に分離する。
