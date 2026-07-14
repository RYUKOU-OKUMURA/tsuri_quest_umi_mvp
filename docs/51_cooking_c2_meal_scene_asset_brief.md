# 調理 C2 食事シーン背景候補ブリーフ

## 目的とスコープ

`MEAL_RESULT` を「暗い下地にカードが浮く画面」から、「食事シーンの上に既存カード・人物・料理が載る画面」へ近づけるため、後続 C2 配線レビュー用の背景候補を準備する。本タスクは asset-only とし、`src/ui/**`、`assets/showcase/cooking/**`、freeze 値、画面への配線は変更しない。

比較の正は `reference/cooking_flow/02_meal_result_concept.png`。現行同一状態は `/tmp/tsuri_cooking_result.png`、現行背景は `assets/showcase/cooking/meal_scene_bg.png` とする。参照画像は方向性・密度・距離の比較にのみ使い、processor で crop / blend しない。

## 素材スロットと供給経路

| 項目 | 仕様 |
|---|---|
| 用途 | 1280×720 固定画面の全面背景候補 |
| AI生成 source | `tools/source_assets/cooking/c2_meal_scene_bg_source.png` |
| 決定的加工後 candidate | `tools/source_assets/cooking/c2_meal_scene_bg_candidate.png` |
| processor | `tools/process_cooking_c2_candidate.py` |
| 生成手段 | OpenAI built-in image generation（2026-07-14） |
| 採否 | 本タスクでは freeze / 本番採用しない。C2 実装者が runtime の同一状態比較で決定する |

背景は有機的一点物のため、docs/19 §3.4 に従い AI 画像生成を必須とする。PIL は生成 source の crop、縮小、色調統一、検査、比較ボード作成だけに用いる。

## 構図

- 港町の小さな厨房兼食堂。木と石の手仕事感がある、温かい JRPG の食事シーン。
- 横長の夕景窓から港、水面、桟橋、遠景の灯台または帆柱が見える。窓景は上半分に置き、カード越しにも夕景の存在が分かる。
- 暖色ランタンを上部左右または片側に置き、中央へ柔らかな琥珀色の光を落とす。
- 木製テーブルは画面下 35〜40% を占める。後から人物と料理が載るため、食器・料理・人物を置かない。
- 左上〜中央左は既存人物アートのシルエットが読める程度に中密度、右上〜中央右はバナー・料理カードが載るため低〜中密度にする。
- 下半分は報酬カード4枚とステータス帯が載るため、強い輪郭・極端なハイライト・細かな小物を避ける。

## overlay safe-area

現行 `MEAL_RESULT` の静的合成を基準に、次の領域では背景が情報より前へ出ないこと。

| 領域（1280×720） | 後から載る要素 | 背景条件 |
|---|---|---|
| x=520〜1215, y=20〜140 | 食事結果バナー | 低コントラスト。窓枠・ランタン本体を横切らせない |
| x=55〜510, y=25〜355 | 人物・食卓シーンアート | 人物なし。大きな主役物なし。暖色の奥行きは可 |
| x=525〜1210, y=155〜350 | 料理画像・料理名カード | 低〜中密度。皿・魚・料理を焼き込まない |
| x=55〜1220, y=380〜515 | 報酬カード4枚 | 暗めで均質。強い縦線・光点を避ける |
| x=55〜1220, y=525〜625 | 共通ステータス帯 | 暗めで均質。細かな小物を避ける |
| x=420〜860, y=635〜690 | 主導線ボタン | 暗めで均質。光源中心を置かない |

safe-area は「空白」にせず、木目・壁・窓外の大きな色面でシーンを継続させる。背景単体の見栄えより、overlay 後の情報階層を優先する。

## スタイル・色・質感

- polished hand-painted pixel-art / high-end 2D JRPG background。1280×720 で輪郭が読み、320×180 縮小でも「食卓・ランタン・港の夕景窓」が残る。
- 濃紺、焦げ茶、琥珀、夕焼け橙、控えめな海の青。白飛びと全面オレンジ化を避ける。
- 木目、石壁、縄、棚は大きなまとまりで描き、UI背面にノイズを増やさない。
- 現行の平坦な幾何背景より、窓の奥行き・光源・素材感を明確に上げる。一方で参照の人物・料理・UIは背景へ取り込まない。

## 禁止事項

- 人物、手、顔、シルエット、動物
- 魚、料理、皿、茶碗、カップ、カトラリー、食材、湯気
- UI、枠、カード、ボタン、ゲージ、アイコン
- 文字、数字、記号、ロゴ、看板文字、透かし、署名
- 参照画像の画素 crop / blend、既存製品素材の埋め込み
- 写真調、滑らかな3Dレンダー、現代的レストラン、豪華すぎる宴会場

## ImageGen 用プロンプト

```text
Use case: stylized-concept
Asset type: full-screen environment background source for a 1280x720 JRPG meal-result scene
Primary request: an empty warm harbor-town kitchen and dining room with a large wooden dining table, amber lantern light, and a wide window overlooking a fishing harbor at sunset
Scene/backdrop: handcrafted timber-and-stone seaside eatery, shelves and ropes kept subtle, glowing sunset harbor water and distant pier visible through the upper window
Style/medium: polished hand-painted pixel-art game background, premium 2D Japanese fishing RPG atmosphere, coherent large pixel clusters, authored environment art
Composition/framing: wide 16:9, table across the lower 35-40 percent; open scene area at upper left for a character overlay; quiet low-detail areas at upper right for a result banner and dish card; dark calm lower half for four reward cards and a status strip
Lighting/mood: cozy amber lantern light inside, blue-orange harbor dusk outside, celebratory but calm, readable under dark navy and parchment UI overlays
Color palette: deep navy shadows, dark walnut, warm amber, sunset orange, restrained harbor blue; no blown highlights
Materials/textures: broad readable wood grain, aged stone, subtle rope and shelves, window depth, no fine clutter in overlay zones
Constraints: environment background only; no people, no character silhouettes, no fish, no food, no dishes, no plates, no bowls, no cups, no utensils, no ingredients, no steam; no UI, frames, cards, buttons, gauges, icons, text, numbers, symbols, logos, signs, watermark, or signature; keep all subjects out of the safe areas
Avoid: photorealism, smooth 3D render, modern restaurant, banquet hall, centered hero prop, bright hotspots behind UI, dense clutter, baked-in foreground meal scene
```

入力画像の役割は、`02_meal_result_concept.png` が方向性・画面距離の reference、`/tmp/tsuri_cooking_result.png` が overlay safe-area の current runtime reference、現行 `meal_scene_bg.png` が改善対象の baseline reference。いずれも processor の画素入力にはしない。

## 決定的加工

processor は source を中央 cover-crop して 1280×720 へ Lanczos 縮小し、軽い色調統一と減光を一定値で適用する。乱数、時刻、メタデータ依存、参照画像・runtime screenshot の画素読み込みは禁止する。candidate の再生成2回で decoded RGBA bytes と保存PNG bytes が一致すること。

機械検査:

- candidate が 1280×720 RGBA
- source と candidate の対応 hash を manifest / evidence に記録
- safe-area ごとの平均輝度、標準偏差、edge density が上限内
- OCR 非依存の禁止要素検査に加え、目視で人物・料理・UI・文字が0
- 原寸、320×180、grayscale、現行/参照/candidate contact、矩形overlay contactを `docs/qa/evidence/cooking/2026-07-14_c2_assetprep_*` に保存

## C2 配線レビューへ進める条件

320×180 の横並びで、現行よりも「食卓＋暖色ランタン＋港の夕景窓」が明確に読め、参照の食事シーン距離が縮むこと。矩形overlayまたは静的合成で既存人物・料理・カードの読みを阻害せず、禁止要素が0であること。ここを満たしても本番採用とはせず、C2 実装者が同一状態 runtime 比較、smoke、visual QA を行う。
