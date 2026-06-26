# 水中ファイト本番素材ブリーフ

このブリーフは、水中ファイト画面を v1 看板画面から理想品質へ進めるための素材差し替え仕様である。背景、魚位置、魚サイズ、接地影、右パネル比率、HUDキーサイズ、上部AM/時刻間隔、右下タックル行数は固定済みとして扱い、ここでは動かさない。

## 判断基準

比較対象は `reference/02_underwater_fight_mockup.png`。毎回 `./tools/fight_visual_qa.sh` を実行し、少なくとも `/tmp/tsuri_fight_compare.png`、`/tmp/tsuri_full_static_compare.png`、`/tmp/tsuri_sidebar_static_compare.png` を横並びで見る。

魚アート候補は `python3 tools/build_fish_asset_contact_sheet.py --candidate path/to/candidate.png` で `/tmp/tsuri_fish_asset_contact.png` を生成し、参照魚、現行最終ソース、現行ランタイム魚、現行カードポートレート、候補ソース、候補処理後フレームを同じボードで比較する。`./tools/fight_visual_qa.sh` もこのコンタクトシートを再生成する。

P1破綻がない限り、背景やレイアウトの微調整へ戻らない。残り差分は、次の3つの素材フェーズとして扱う。

1. 最終魚アート
2. 専用UIフォント/アイコン
3. 本番カード素材

## 最終魚アート

入力スロットは `tools/source_assets/kurodai_final_art_source.png`。このファイルを差し替えた後、`python3 tools/process_underwater_fish_assets.py` を実行して `assets/showcase/underwater/kurodai_showcase_sheet.png` と `assets/showcase/underwater/kurodai_card_portrait.png` を再生成する。

差し替え前に必ず `tools/build_fish_asset_contact_sheet.py` で候補をプレビューする。候補処理後フレームが現行ランタイム魚より弱い、欠ける、背景が混じる、ハロが出る、鱗やヒレが失われる場合は採用しない。

現行採用ソースは、右向き全身クロダイを純マゼンタ背景で生成した `tools/source_assets/kurodai_final_art_source.png` である。最新採用候補は、前ソースより鱗密度、背びれ、黒帯、輪郭が強く、`/tmp/tsuri_fish_asset_contact.png`、`/tmp/tsuri_fish_three_way_processed.png`、`/tmp/tsuri_fight_compare.png` で確認済みである。より暗い2枚目候補は口元と頭部の主張が強く、参照魚から離れるため採用しない。参照画像の魚より少し滑らかな描画ではあるため、次に更新する場合は、同じレイアウトに載せた全画面比較でこの現行採用ソースを明確に上回る候補だけを使う。

生成/制作する魚は、右向きのクロダイ単体。背景、泡、水中光、釣り糸、ルアー、影、文字、UI枠は入れない。既存パイプラインへそのまま渡せるよう、純マゼンタ `#ff00ff` 背景のPNGを基本にする。透明背景を使う場合は、黒い半透明縁や暗いRGB値が透明ピクセルに残らないかを確認する。

必要条件:

- 全身が切れていない右向き側面シルエット
- 背びれの棘、尾びれ、胸びれ、腹びれ、目、口元が明確
- クロダイらしい銀灰色の体、黒い縦帯、細かい鱗、暗い輪郭
- 画面内で白飛びしない腹側ハイライト
- 現在素材よりも、参照画像の黒く締まった鱗密度と魚らしい重さに近い
- 滑らかすぎる3Dレンダー、汎用魚、金魚/タイ風、過剰な青いハロ、写真切り抜き風は不可

ImageGen用プロンプトの基準:

```text
Use case: stylized-concept
Asset type: game UI fish sprite source for a JRPG fishing battle screen
Primary request: a single right-facing black seabream / kurodai fish, full body side profile
Style/medium: polished hand-painted game illustration with crisp inked silhouette, detailed scales and fins, close to a premium Japanese fishing RPG UI mockup
Composition/framing: fish centered, full body visible, nose facing right, no cropping, no shadow, no UI
Color palette: silver gray body, dark charcoal vertical bands, black dorsal spines, subtle yellow eye, restrained pearly belly
Materials/textures: dense small scale pattern, visible fin rays, dark mouth and gill line, firm outline
Constraints: pure #ff00ff flat background, no water, no bubbles, no fishing line, no lure, no text, no logo, no frame, no extra fish
Avoid: smooth generic 3D render, photo cutout, cartoon mascot, oversized eye, whitewashed belly, blue glow, halo, broken fins
```

参照モックアップから主役魚を自動抽出する案は、現時点では採用しない。試作した抽出候補は参照ピクセル由来だが、水背景の混入と下腹部/輪郭の欠けが残り、`kurodai_final_art_source.png` の置換素材としては現在の手描き寄りソースより弱い。再挑戦する場合は、単純なしきい値抽出ではなく、手作業マスクまたは高品質な背景除去で全身シルエットを保つ。

## 専用UIフォント/アイコン

現在の v1 では `src/ui/fight_fonts.gd` の fight-screen 用 M PLUS 1p と参照由来PNGアイコンを使う。DotGothic16 の全面置換は `/tmp/tsuri_font_candidate_compare.png` で、数値、右カード本文、HUDラベルが細くなりすぎるため採用しない。次フェーズでは、座標やサイズを変えずに、文字と小アイコンの完成度だけを上げる。フォントを変える場合は、全テキスト一括置換ではなく、見出し/数値/本文の役割ごとに重さを保てるJP対応フォントか、文字素材化を検討する。

対象:

- 上部ステータスの時計、天候、風、コイン
- 下部HUDのA/B/LR/+/-キーキャップ、テンション、魚体力、エサ
- 右パネルの魚行動アイコン、タックルのロッド/リール切り抜き
- 魚カード生態メモ、タックル5行本文、距離ラベル

専用UIフォント/アイコンの作業では、右下タックルカードの5行・13px、104pxアイコンレーン、118x86pxロッド/リール切り抜きを変えない。

## 本番カード素材

対象は `assets/showcase/underwater/sidebar_frame.png`、`assets/showcase/underwater/fight_hud_frame.png`、`assets/showcase/underwater/top_status_frame.png`。現在は生成スクリプトと参照紙テクスチャで完成寄りにしているが、理想品質では専用に描いたカードスキンへ置き換える。

右サイドバーは `tools/source_assets/sidebar_frame_material_source.png` を本番素材ソースとして使う。`tools/generate_underwater_ui_frame_assets.py` は、この生成カードスキンを直接全体置換せず、既存の header / fish / action / tackle スロットへリサイズ合成する。これにより、runtime文字座標、魚ポートレート、タックル5行、下段カード比率を守ったまま、紙面、濃紺帯、金属角、細いベベルだけを本番寄りにする。

下部HUDは `tools/source_assets/fight_hud_material_source.png` を本番素材ソースとして使う。`tools/generate_underwater_ui_frame_assets.py` は、この生成カードスキンを既存の top gauge / bait / operation / menu スロットへリサイズ合成する。これにより、HUD高、A/B/LR/+/-キーサイズ、ゲージ座標、操作文字ベースライン、エサ/操作/メニュー比率を守ったまま、黒い機械箱感を弱めて紙カードと濃紺操作盤の素材感だけを本番寄りにする。

上部ステータスは `tools/source_assets/top_status_material_source.png` を本番素材ソースとして使う。`tools/generate_underwater_ui_frame_assets.py` は、この生成カードスキンを左3つの紙札スロットへ低アルファで合成する。右端の濃紺地点カード、スロット比率、AM/時刻間隔、アイコン座標、文字サイズは維持し、白い無地札感を弱める素材上乗せだけに留める。

必要条件:

- 参照画像のJRPG情報カードらしい紙面、濃紺帯、金属角、細い罫線
- 白いフォーム、デバッグパネル、黒金の機械箱、格子状UIスキンに見えない
- runtime文字が乗る座標を守り、文字ベースラインと焼き込み罫線が衝突しない
- 右パネル、下部HUD、上部ステータスの既存比率とカードスロットを維持する

本番カード素材を更新したら、必ず静的比較を再生成して、密度、余白、色、魚の存在感、UI枠の質を参照画像と横並びで判断する。
