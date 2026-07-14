# 調理 C2 食事シーン背景候補 — 採否準備記録

## 結論

**C2配線レビューへ進められる候補（本番採用・freezeではない）**。

現行 `MEAL_RESULT` の平坦な暗茶背景に対し、候補は320×180でも「広い木製食卓」「左右の暖色ランタン」「港の夕景窓」が一読できる。参照 `02_meal_result_concept.png` の食事シーン全面背景へ距離が縮み、人物・料理・結果カードを後から重ねる空間も残る。

最終採用は C2 実装者が `assets/showcase/cooking/meal_scene_bg.png` へ配線する別タスクで、同一状態 runtime capture、visual QA、smokeを通して決める。本記録では既存素材を上書きせず、採用・freezeを宣言しない。

## 比較

- `2026-07-14_c2_assetprep_contact.png`: 現行 / reference / candidate の320×180とgrayscale。
- `2026-07-14_c2_assetprep_overlay_safe_area.png`: 現行カード・人物・料理の占有矩形をcandidateへ重ねた確認。
- `*_original.png`: 1280×720へ正規化した原寸比較。
- `*_320x180.png`: 縮小比較。
- `*_grayscale.png`: 情報階層・明度比較。
- `2026-07-14_c2_assetprep_report.json`: hash、safe-area、crop、色調、機械検査結果。

processorのPNG保存は、既存ファイルとsize / mode / decoded pixelsが完全同値なら既存bytesを保持し、画素差がある時だけatomic replaceする。これによりPillow等のencoder差があっても、clean checkout相当の状態から `--evidence` を再生成してworktree clean、candidate PNG SHA-256 `88b404ed…`、decoded RGBA `fcdfcd62…` を維持する。

## safe-area判断

- 左人物域: 大きな主役物・人物・料理がなく、壁の大きな色面が人物シルエットを受ける。左ランタンは端部にあり、既存人物の顔・手の中心と競合しない。
- 右バナー/料理カード域: 港窓は奥行きを作るが、加工後の平均輝度・標準偏差・edge densityは全上限内。右端ランタンはバナー背面で隠れる位置であり、主情報の中心を横切らない。
- 報酬/ステータス/CTA域: 下方へ連続減光し、矩形ごとの不自然な継ぎ目を作らず、全領域が上限内。
- crop: source 1672×941を中央cover-cropして1280×720。主要な食卓、左右ランタン、港窓を欠損しない。

## 禁止要素と権利

目視事前確認では人物、手、顔、動物、魚、料理、食器、食材、湯気、UI、枠、文字、数字、ロゴ、透かしは0件。processorは完全不透明、PNG text chunk 0、参照/runtime画素消費0を機械検査する。意味的禁止要素はローカル物体検出器がないため、完了前の独立アートレビューでも0件を再確認する。

OpenAI built-in image generationで2026-07-14に生成。正式参照、現行runtime、現行背景は生成時の方向性/safe-area入力であり、processorの画素入力は生成sourceのみ。`docs/31_asset_ledger.md` にsource/candidate/生成日/製品未使用/U-08待ちを記録した。

## hash

| 対象 | SHA-256 |
|---|---|
| source PNG | `673783a3d9c2bab5dc4d0410fa3468137b732a8538c135206b8007081b38a245` |
| candidate PNG | `88b404ed323faa6e258a062e13c3928cc2b70b8db3b1d7bbecc39665c60f9e43` |
| candidate decoded RGBA | `fcdfcd62a75a916d22055717d7ebfb1923cef26eedbba8aa34762d47673ee873` |
| 現行MEAL_RESULT capture | `c1af90799375b02d23299d2f9fcb8c1ae9f638d4a689dad01bb74a561fe044ed` |
| reference | `c65d78660bd6f8319d4d3235002eafad2d8ff3674bf585e14dbeffaf889d1045` |

## C2実装者への引継ぎ

1. sourceではなく `c2_meal_scene_bg_candidate.png` を候補入力にする。
2. 既存 `player_eating_pose_pixel_tight.png`、料理画像、結果カード、ステータス帯の座標/freezeは先に動かさず、背景だけを同一状態へ仮配線する。
3. runtime captureで右窓の夕日またはランタンが文字へ干渉する場合は、背景位置ではなく低アルファの画面スクリムを最小差分で検討する。
4. `./tools/cooking_visual_qa.sh`、該当smoke、`./tools/validate_project.sh`を実行し、現行/reference/candidate runtimeの320×180比較で最終採否を決める。
5. 台帳のU-08 pendingは外部証拠が揃うまで維持する。

競合候補は、現行 `assets/showcase/cooking/meal_scene_bg.png`（平坦で参照距離が遠い）と、現行 `meal_result_scene_art_v2.png` / `player_eating_pose_pixel_tight.png` を前景として維持する構成。candidateへ人物・料理を焼き込む案は競合ではなく禁止とする。
