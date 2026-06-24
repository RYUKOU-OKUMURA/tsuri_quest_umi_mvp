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

`tools/generate_underwater_showcase_assets.py` で生成した初期 PNG は、素材ベース表示の技術検証用であり、完成方向の土台ではない。現在の `underwater_battle_bg.png` は `tools/build_reference_underwater_background.py` で、`reference/02_underwater_fight_mockup.png` の水中窓から抽出したリファレンス由来の背景パスである。魚、ヒット演出、糸、ルアーが入る領域はマスクして水色面で埋め、さらに海底光、右岩場、海藻、小石、遠景魚、参照左岩場をミラーした低透過テクスチャ、参照画像全体から切り出した右岩場の内容マスク合成を焼き込んで、runtime のクロダイ/ヒット演出を邪魔しない範囲で密度を戻す。旧生成背景ソース `tools/source_assets/underwater_battle_bg_source.png` と `tools/enhance_underwater_battle_bg.py` は、リファレンス抽出が使えない場合の代替パスとして残す。`kurodai_showcase_sheet.png` はリファレンス魚の切り出しを背景抽出して作った高品質パスである。右カードでは泳ぎ用シートを直接描かず、紙背景に焼き込んだ `kurodai_card_portrait.png` を使う。`hit_burst.png` は `tools/process_underwater_fish_assets.py` で青い水しぶき素材として再生成し、暖色は Godot 側の「ヒット！」文字だけに寄せている。画面全体の品質判定は引き続き `reference/02_underwater_fight_mockup.png` との横並び比較で行う。

`sidebar_frame.png`、`top_status_frame.png`、`fight_hud_frame.png` は、生成素材の金飾りが強すぎたため `tools/generate_underwater_ui_frame_assets.py` で参照画像寄りの紙カード/濃紺ゲージ台として作り直している。これは最終美術素材ではなく、文字・ゲージ・アイコンが破綻しない完成寄りの枠素材スロットである。`FishingScreen` では右サイドバー外側の汎用パネルを外し、専用 `sidebar_frame.png` が直接画面に出るようにしている。現行の生成ルールでは `_draw_clean_card()` を使い、黒い太枠・鋲・強い金線を減らして、参照画像の紙カード寄りに軽量化している。

`kurodai_showcase_sheet.png`、`kurodai_card_portrait.png`、`hit_burst.png` は、`kurodai_chroma_source.png` を元に `tools/process_underwater_fish_assets.py` で生成する。処理内容は、クロマキー除去、マゼンタ縁のデスピル、単体魚または4フレーム素材の正規化、右カード用の紙背景ポートレート生成、ヒットバッジ生成である。`kurodai_card_portrait.png` は右パネルの実表示窓に合わせた 620x330 比率にし、横長すぎる素材を縮小表示して魚の存在感を落とさない。生成元は内製差し替え用の中間素材で、画面表示は最終PNGのみを参照する。

水中ファイトの主要文字は `src/ui/fight_fonts.gd` から `MPLUS1p-Bold.ttf` を使う。通常テーマ全体は既存の `MPLUS1p-Regular.ttf` を維持し、看板画面の上部ステータス、HUD、右パネル、ヒット文字だけ太い表示に寄せる。

次フェーズでは、コード生成の簡易素材を磨くのではなく、以下を満たす完成素材を作ってから組み込む。

- クロダイは魚らしいシルエット、鱗、ヒレ、目、背と腹の陰影が読める。
- 背景は岩場、海藻、泡、光芒、遠景魚、海底の奥行きを持つ。
- 下部 HUD と右パネルは、参照画像の情報カード品質に近い専用枠素材を使う。
- 金色の格子状・デバッグ風に見える UI スキンは使わない。

## レイヤー構成

1. `underwater_battle_bg.png`
   水面光、光芒、海底、岩、海藻、遠景魚、泡を含む 16:9 背景。
2. `underwater_color_grade.png`
   背景の上に重ねる透明PNG。外周の暗部、海底の締まり、水面光の帯を足し、背景PNGの均一な明るさを抑える。
3. `underwater_seabed_detail.png`
   背景下部と左右に重ねる透明PNG。岩場シルエット、海藻、サンゴ、水底の光線を足し、生成背景の滑らかさを補う。
4. `underwater_foreground_ambience.png`
   背景の上に重ねる透明PNG。泡柱、光の筋、遠景魚影、粒子を含み、主役魚を邪魔しない密度補助として扱う。
5. 動的深度表示
   現在深度と目盛り。背景上に半透明で重ねる。
6. 釣り糸・エサ
   既存ロジックの位置に合わせて動的描画する。
7. `kurodai_showcase_sheet.png`
   主役魚。4 フレーム構成で、遊泳・緊張・突進・疲労を切り替える。
8. `kurodai_card_portrait.png`
   右魚カード専用の静止ポートレート。紙背景へ魚を焼き込み、カード上で暗い矩形が出ないようにする。
9. `hit_burst.png`
   アワセ直後の「ヒット！」演出。短時間だけ魚の手前に表示する。
10. HUD / 情報 UI
   上部ステータスバー、下部ゲージ、右パネル、ボタンは既存 Control UI を維持しつつ、順次画像枠へ差し替える。
11. `sidebar_frame.png`
   右側の魚情報・行動・タックルカード用の縦長フレーム素材。文字、魚、行動表示は Godot 側で重ねる。
12. `top_status_frame.png`
   時計、天候、所持金、地点/水深の上部ステータスバー用フレーム素材。左ファイトカラム内にだけ敷き、文字と数値は Godot 側で重ねる。
13. `top_status_icon_sheet.png`
   上部ステータスバー専用の時計、太陽、風、コイン小型アイコン。共通アイコンを縮小すると潰れて読めないため、上部カードでは専用素材を使う。
14. `fight_hud_frame.png`
   下部操作盤の一体型フレーム素材。ゲージ色、現在位置、操作文字、エサ情報は Godot 側で重ねる。
15. `fight_icon_sheet.png`
   時計、天候、風、コイン、テンション、魚体力、エサ、行動、タックルの共通アイコンシート。3x3 グリッドで各 UI が同じ素材を参照する。
16. `fight_action_card_icon.png` / `fight_tackle_card_icon.png`
   右パネル下段カード専用の小型アイコン。共通アイコンシートをそのまま縮小すると装飾が強く、カード本文を圧迫するため、紙カード上に整えた別素材として使う。

## 最小素材セット

| ファイル | 役割 | 現在の作り方 | 本番差し替え時の条件 |
|---|---|---|---|
| `assets/showcase/underwater/underwater_battle_bg.png` | 水中背景 | `tools/build_reference_underwater_background.py` で参照画像の水中窓から抽出 | 16:9、リファレンスの岩場/泡/水面光を保持し、魚/ヒット/糸/ルアーの残像を背景に残さない |
| `tools/build_reference_underwater_background.py` | 水中背景ビルダー | 参照画像クロップ、主役/演出マスク、色面補完、参照左岩場のミラー合成、参照画像全体からの右岩場内容マスク合成、キャンバス拡張、中央/右側の密度焼き込み | 中間PNGを残さず、最終背景だけを決定的に再生成する |
| `tools/source_assets/underwater_battle_bg_source.png` | 代替水中背景の元画像 | 旧本番寄り背景PNGの保存元 | Godotインポート対象外、参照抽出を使わない場合の後処理ソース |
| `assets/showcase/underwater/underwater_color_grade.png` | 背景の奥行き/光調整 | `tools/generate_underwater_foreground_assets.py` で生成 | 透明PNG、外周暗部・海底の締まり・水面光を含み、魚/ヒット演出を覆わない |
| `assets/showcase/underwater/underwater_seabed_detail.png` | 海底/左右の密度補助 | `tools/generate_underwater_foreground_assets.py` で生成 | 透明PNG、岩場・海藻・サンゴ・水底光を含み、主役魚を邪魔しない |
| `assets/showcase/underwater/underwater_foreground_ambience.png` | 前景密度補助 | `tools/generate_underwater_foreground_assets.py` で生成 | 透明PNG、泡柱・遠景魚・光粒を含み主役魚を邪魔しない |
| `assets/showcase/underwater/kurodai_chroma_source.png` | クロダイ中間素材 | リファレンス魚の切り出しを ImageGen で背景抽出 | フラットなマゼンタ背景、単体魚または横4フレーム |
| `assets/showcase/underwater/kurodai_showcase_sheet.png` | クロダイ | `tools/process_underwater_fish_assets.py` で生成 | 透明背景、横 4 フレーム、全フレーム同サイズ |
| `assets/showcase/underwater/kurodai_card_portrait.png` | 右カード用クロダイ | `tools/process_underwater_fish_assets.py` で生成 | 紙背景に魚を合成、620x330 前後のカード窓比率、暗い矩形を出さず、魚が紙窓の主役として大きく読める |
| `assets/showcase/underwater/hit_burst.png` | ヒット演出 | `tools/process_underwater_fish_assets.py` で生成 | 濃紺の水しぶき、透明背景、文字は含めない |
| `assets/showcase/underwater/sidebar_frame.png` | 右パネルフレーム | `tools/generate_underwater_ui_frame_assets.py` で生成 | テキストなし、魚なし、縦長フレームとして全面表示 |
| `assets/showcase/underwater/top_status_frame.png` | 上部ステータスバー | `tools/generate_underwater_ui_frame_assets.py` で生成 | テキストなし、横長フレームとして全面表示 |
| `assets/showcase/underwater/top_status_icon_sheet.png` | 上部ステータス専用アイコン | `tools/extract_top_status_icons.py` で参照画像から抽出・透明化 | 4セル横並び、時計/太陽/風/コイン、上部カードで潰れず読める |
| `assets/showcase/underwater/fight_hud_frame.png` | 下部操作盤フレーム | `tools/generate_underwater_ui_frame_assets.py` で生成 | テキストなし、左カラム幅の二段HUDとして全面表示 |
| `assets/showcase/underwater/fight_icon_sheet.png` | 共通機能アイコン | 生成 UI 素材 | 透明 PNG、3x3 グリッド、各セル同サイズ |
| `assets/showcase/underwater/fight_action_card_icon.png` | 右パネル行動カードアイコン | `tools/generate_underwater_ui_frame_assets.py` で生成 | 紙カード背景つき、本文を圧迫しない小型表示 |
| `assets/showcase/underwater/fight_tackle_card_icon.png` | 右パネルタックルカードアイコン | `tools/generate_underwater_ui_frame_assets.py` で生成 | 紙カード背景つき、本文を圧迫しない小型表示 |
| `assets/fonts/MPLUS1p-Bold.ttf` | 水中ファイト主要UIフォント | Google Fonts の M PLUS 1p Bold | OFL同梱、見出し/数値/ヒット文字用 |
| `assets/fonts/OFL-MPLUS1p.txt` | M PLUS 1p ライセンス | Google Fonts 由来 | フォント更新時も保持 |

## 実装方針

- `UnderwaterView` は上記 PNG が存在すれば素材版を優先する。
- PNG がない場合は既存の procedural 描画にフォールバックする。
- `UnderwaterView` の showcase テクスチャは、プロジェクト既定の NEAREST ではなく LINEAR で表示する。UI枠はチャンキーなままでよいが、水中背景・魚・ヒット演出はリファレンスのなめらかなイラスト感に近づけるため、縮小時の硬いピクセル段差を抑える。
- 魚スプライトの位置、向き、状態は `FishingSimulator.visual_position`、`visual_direction`、`action_name`、`fish_stamina_ratio()` から決める。
- `FightStatusBar` は `top_status_frame.png` を左ファイトカラム内に敷き、時計・天候・所持金・水深のテキストを Godot 側で重ねる。全幅ルート直下に置くと右パネルが下がり、参照画像の「左ステータスカードと右魚カードヘッダーが同じ上端に並ぶ」構成から外れるため、右パネルとは横並びの同階層にする。上部の時計/太陽/風/コインは `top_status_icon_sheet.png` を優先し、共通アイコンシートは専用素材がない場合のフォールバックにする。上部カードは小さな説明ラベルを詰め込まず、アイコンと強い数値/状態文字を優先する。特に所持金はコインアイコンと金額だけで読ませ、ラベルが金額を圧迫しないようにする。
- `FightHud` は画面全幅ではなく左カラム内に置き、`fight_hud_frame.png` の上にゲージ色、現在位置、深度、操作文字を重ねる。ゲージは塗り済みセグメントだけでなく、薄い未充填セグメント、上ハイライト、下影、テンション位置マーカー影を描き、矩形の羅列ではなく操作盤に埋まったメーターとして見せる。
- `FightStatusBar`、`FightHud`、`FightSidebar` は `fight_icon_sheet.png` の3x3セルを使い、コード描画アイコンを本番素材へ置き換える。
- `FightSidebar` の魚カードだけは、泳ぎ用の `kurodai_showcase_sheet.png` ではなく `kurodai_card_portrait.png` を優先する。泳ぎ用シートを拡大するとカード上で暗い矩形が出るため、カード用素材を分ける。`kurodai_card_portrait.png` は紙背景込みの横長素材だが、魚が小さくなりすぎると図鑑カード品質に届かないため、生成時は魚が紙窓の大部分を占める比率にする。
- `FightSidebar` の行動/タックル小カードは `fight_action_card_icon.png` / `fight_tackle_card_icon.png` を優先する。共通アイコンシートは大きな装飾を含むため、右下段カードではカード専用にトリミングした素材を使う。右下段カードの本文は、長文情報をそのまま詰め込まず、アイコン横で読める短い行に圧縮する。特にタックルカードは3行の小文字を避け、ロッド行とリール/糸/針の2行にまとめて可読サイズを優先する。小カードではアイコンを本文より主張させず、本文サイズとベースラインを優先して、縮小UIではなくカードに印字された情報として見せる。
- `FightStatusBar`、`FightHud`、`FightSidebar`、`UnderwaterView` のヒット文字は `src/ui/fight_fonts.gd` から水中ファイト専用の太字フォントを読み込む。
- `FightHud` の下段は、`fight_hud_frame.png` 側にエサ/操作/メニューの紙タイトル帯、本文スロット、濃紺メニュー行を焼き込み、Godot側でエサ数とA/B/LRのキーキャップと短いラベルだけを重ねる。PNG側の装飾枠と実コードの座標がずれると、文字が暗い盤面に沈んでデバッグUIに見えるため、フレーム生成とGodot描画の座標を必ず合わせる。
- 右パネルは汎用 `make_panel()` の中に入れず、`FightSidebar` の専用フレームを直接表示する。二重枠にするとサイドバー素材が縮み、参照画像のカード品質から離れるため。
- `UnderwaterView` は主役魚とヒット演出のスケールを参照画像寄りに抑え、深度目盛りは背景に馴染む低コントラスト表示にする。
- `UnderwaterView` は `underwater_battle_bg.png` の上に `underwater_color_grade.png`、`underwater_seabed_detail.png`、`underwater_foreground_ambience.png` の順で重ね、追加の光粒だけを動的に描く。参照抽出背景では旧生成背景向けの補助レイヤーが強すぎると灰色の膜に見えるため、色調整、海底補助、前景 ambience は低めの opacity で重ねる。PNG がない場合だけ、コード描画の遠景魚群・泡柱へフォールバックする。
- `underwater_battle_bg.png` を直接詰める場合は、まず `tools/build_reference_underwater_background.py` を実行して参照画像由来の背景を決定的に再生成する。中央のマスク領域は主役魚とヒット演出で隠れるため、魚の存在感を邪魔しない水色面を基本にしつつ、下端と右側には海底光、岩場、海藻、小石、遠景魚を焼き込んで空白感を抑える。右下の密度は参照クロップの左岩場/海底ピクセルをミラーして低透過・強フェザーで合成し、さらに参照画像全体の右岩場から暗い岩・海藻・泡だけを内容マスクで抽出して薄く重ねる。矩形の貼り付け境界が見えるほど濃くしない。参照抽出を使わない代替検証時のみ、`tools/source_assets/underwater_battle_bg_source.png` から `tools/enhance_underwater_battle_bg.py` を実行する。
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

1. `sidebar_frame.png` は右パネル幅拡張、魚カード用 `kurodai_card_portrait.png` 分離、魚カード見出しの紙プラーク化、紙面の内部構造追加、行動文の意味改行、行動/タックル下段カード専用アイコン追加、下段カード本文の短縮、余白調整、アイコン枠/本文プラーク分離まで完了。`kurodai_card_portrait.png` は魚の占有率を上げ、カード内の空白感を減らした。行動/タックル下段カードは、本文を大きくし、アイコン占有を抑え、タックル本文を2行に圧縮し、紙スロット上端に干渉しないベースラインへ調整済み。次は全体比較で右パネルが再び浮く場合だけ小さく調整する。
2. `fight_hud_frame.png` の上段は深度プレート強化、暗色化、HUDアイコン縮小/低透過化、右ラベル余白調整、メーター格子弱化、未充填セグメント表示とハイライト/影追加まで完了。下段はエサ/操作/メニューの紙タイトル帯、本文スロット、濃紺メニュー行、操作ヒントの3スロット化、A/B/LRキー配置の整列まで完了。次は最終比較でまだ機械的に見える場合だけ全体比率と小文字の詰めを行う。
3. 上部ステータスの地点カードは参照に合わせてアイコンなし中央寄せに修正済み。`top_status_frame.png` は紙カード内枠、角金具、濃紺地点カードの内装追加まで完了。上部アイコン群は `top_status_icon_sheet.png` に分離し、時計/太陽/風/コインが潰れない状態まで改善済み。`FightStatusBar` は左ファイトカラム内へ移動し、右パネルヘッダーが上端から始まる構造に修正済み。カード比率は天候/所持金を広げ、地点カードを締める方向へ調整済み。文字ベースラインと数値の光学サイズも調整し、所持金は小ラベルを外して金額を大きく読ませる状態まで改善済み。次に詰めるなら、背景または右パネルの本番素材差分が埋まったあとに最終比較で微調整する。
4. ヒット演出は白い放射線と下端の重なりを調整済み。最終 HUD/フォント調整後に比較だけ再確認する。
5. 泡、光粒、魚影は `underwater_foreground_ambience.png` と `UnderwaterView` の補助光粒として追加済み。背景の均一な明るさは `underwater_color_grade.png` で少し締め、海底/左右の密度は `underwater_seabed_detail.png` で補っている。`underwater_battle_bg.png` 本体は `tools/build_reference_underwater_background.py` でリファレンス水中窓から抽出し、主役魚/ヒット/糸/ルアー部分をマスク補完して再生成済み。現在はさらに、マスクで平坦になった下端と右側へ海底光、岩場、背の高い海藻、小石、遠景魚、参照左岩場をミラーした低透過テクスチャ、参照画像全体から切り出した右岩場の内容マスク合成を焼き込み、空白感を減らしている。参照抽出背景に合わせ、`UnderwaterView` 側では色調整/海底補助/前景 ambience の opacity を下げて灰色の膜を避けている。`UnderwaterView` は LINEAR フィルタで showcase テクスチャを描画し、背景の縮小時の硬さを抑える。次に背景を詰める場合は、中央/右側をより手描き密度の高い本番ラスタ素材へ置き換える。
