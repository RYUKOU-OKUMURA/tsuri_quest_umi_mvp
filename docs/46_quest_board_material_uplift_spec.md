# 依頼ボード authored 素材 uplift 発注仕様

Date: 2026-07-13

## 目的と適用範囲

対象は `reference/11_quest_board_mockup.png` と現行1280×720実画面の差分Top1である「紙質・ピン留め・掲示板木目の素材感不足」。依頼札3列、主条件全文、進捗、報酬、状態CTA、上部/下部の既存矩形と操作契約はfreezeしたまま、画面専用のauthored PNGだけで質感を上げる局所upliftとする。

NPC個性、依頼抽選・納品・報酬・保存ロジック、カード内情報階層、共通キットは変更しない。日本語テキスト、魚、進捗、報酬、CTAは引き続きGodot runtime描画とする。

## 状態対応表

| 状態 | 固定データ | 出力 | 確認契約 |
|---|---|---|---|
| 通常 | Lv.9 / 12,450G / アジ・メジナ・カサゴ | `2026-07-13_wave-a-*-normal.png` | 3列・主条件・進捗・報酬・CTAの矩形維持 |
| long_text_a | タケノコメバル＋最長料理名 | `2026-07-13_wave-a-*-long-text-a.png` | 全文表示、紙面装飾との衝突ゼロ |
| long_text_b | 最長魚名の記録/希少/複数納品 | `2026-07-13_wave-a-*-long-text-b.png` | 全文表示、CTAアンカー維持 |

## freeze / 可変範囲

- 不動: board `0.035, 0.182, 0.965, 0.832`、3カードの外形、カード内全Label・ゲージ・CTA矩形、header/footer、魚肖像、フォント、文言、フォーカス/押下契約。
- 可変: `_add_wood_board()` の背景描画経路、カード全面の背景Texture2D、必要最小限の素材用TextureRect順序。
- 再オープンしない: `docs/qa/quest_board_qa.md` の既存freeze値すべて。

## 素材A: 掲示板木製背景

- 用途: `QuestBoardPanel` 全面。実使用は約1190×468px。
- source: `tools/source_assets/quest_board/quest_board_wood_source.png`
- product: `assets/showcase/quest_board/quest_board_wood_panel.png`
- 生成方式: OpenAI built-in image generationで一点物の手描き木製掲示板を生成し、Pillowで1280×512へcover crop、色調・安全枠を整える。
- runtime safe area: 外周20pxは留め具/縁、内側は3枚の紙札が乗るため強い節・金具・文字を置かない。
- 必須: 暖色の濃い木、横方向の板継ぎ、細かな木目、薄い使用傷、金茶の細い外枠、港のJRPG掲示板らしい手描き質感。
- 禁止: 紙札、文字、魚、人物、ロゴ、UIラベル、写真調、現代オフィスのコルクボード、強い立体彫刻。

ImageGen用プロンプト基準:

```text
Use case: stylized-concept
Asset type: full-frame material background for a Japanese fishing RPG quest-board UI
Primary request: an authored dark warm wooden harbor notice board, empty and ready for three paper notices
Style/medium: polished hand-painted 2D JRPG game UI asset, restrained painterly texture, readable at 1280x720
Composition/framing: straight-on orthographic rectangle, full frame filled by horizontal timber planks, thin crafted golden-brown rim, calm center areas for overlaid cards
Lighting/mood: warm maritime tavern light, subtle age and use, no dramatic highlights
Color palette: dark walnut, burnt umber, muted ochre edge accents
Materials/textures: visible natural wood grain, plank seams, small dents and rubbed edges, controlled low-frequency contrast
Constraints: no paper, no pins, no text, no symbols, no fish, no people, no logo, no watermark, no perspective tilt
Avoid: photorealism, cork board, glossy plastic, ornate carved frame, busy knots behind text areas, black empty center
```

## 素材B: ピン付き依頼札

- 用途: 3列カード全面。実使用は約357×393px。
- source: `tools/source_assets/quest_board/quest_notice_card_source.png`
- product: `assets/showcase/quest_board/quest_notice_card.png`
- 生成方式: OpenAI built-in image generationで純緑背景の単体札を生成し、chroma-key除去後、Pillowで384×432へcontain、alpha・紙面明度・安全域を整える。
- runtime safe area: 左右28px、上42px、下26pxを除く中央は文字・肖像・ゲージ用。罫線や染みを強く置かない。
- 必須: 生成感の少ない厚手の生成り紙、わずかな繊維・色むら、柔らかな端の摩耗、上中央の真鍮または赤銅の丸ピン、紙下の控えめな影。
- 禁止: 文字、罫線、チェック欄、封蝋、魚、アイコン、穴、破れ、強い折り目、角を大きく巻く表現。

ImageGen用プロンプト基準:

```text
Use case: background-extraction
Asset type: reusable paper notice background for a Japanese fishing RPG quest-board UI
Primary request: a single blank aged parchment quest notice pinned at the top center by one small round brass tack
Scene/backdrop: perfectly flat solid #00ff00 chroma-key background for removal
Style/medium: polished hand-painted 2D JRPG UI asset, understated tactile paper
Composition/framing: straight-on rectangular portrait paper, centered, full object visible, generous padding, subtly uneven handmade edges, one tack only
Lighting/mood: soft warm ambient light, shallow contact shadow confined to the paper edge
Color palette: warm ivory parchment, muted tan fibers, aged ochre edge, dark antique brass tack
Materials/textures: fine paper fibers and gentle mottling with a calm clean central writing field
Constraints: no text, no lines, no symbols, no fish, no logo, no watermark; background one uniform #00ff00 with no gradient or texture; do not use #00ff00 in subject
Avoid: scroll, envelope, torn paper, curled corners, large stains, wax seal, multiple pins, photorealistic office stationery
```

## 加工・採否条件

`tools/generate_quest_board_assets.py` はsourceを上書き生成せず、検証してproduct PNGを再現可能に出力する。紙札は透明四隅、alpha bbox、緑ハロ、中央safe areaの明度を検査する。木製背景は指定寸法とRGB/RGBAを検査する。

採用条件は同一データの原寸before/afterでP1ゼロを維持し、320×180縮小で紙札と木製掲示板が別素材として読め、参照の「厚い紙＋ピン＋連続した木面」へ明確に近づくこと。満たさなければ候補を不採用とし、現行へ戻す。
