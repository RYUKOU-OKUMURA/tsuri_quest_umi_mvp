# 50. 調理 C1-A 厨房背景 発注仕様

作成日: 2026-07-14

## 目的とスロット

`COOK_SELECT` の既存 `assets/showcase/cooking/cooking_room_bg.png` を、参照01の世界観へ近づける authored 厨房背景へ差し替える。生成sourceは `tools/source_assets/cooking/c1a_kitchen_bg_source.png`、決定的加工は `tools/process_cooking_c1a_assets.py`、製品出力は既存slotの1280x720 PNGとする。

このフェーズは背景1スロットだけを扱う。3列、カード、右詳細、CTA、`PlayerStatusBar`、下部strip、文字、状態、ロジックは変更しない。

## スタイルアンカーと構図

- 正の方向性: `reference/cooking_flow/01_cook_select_concept.png`
- 回帰参照: `reference/cooking_flow/02_meal_result_concept.png` 〜 `05_status_summary_concept.png`
- 画面: 海辺の小さな釣り町にある、使い込まれた温かな調理場。磨かれた木材、石/漆喰壁、瓶や鍋が並ぶ調理棚、吊り下げ道具、暖色ランタン光を持つ。
- 海窓: 青い海、港の桟橋、遠景の空が読める窓を置く。室内の暖色と外の青で奥行きを作る。
- safe area: 中央〜右寄りの狭い縦ガターでも海窓または厨房棚の一部が読める。画面端と上部にもランタン光/棚の手掛かりを置く。前景UIが載る中央面は密度とコントラストを抑える。
- 画角: 16:9、正面寄りの広角室内、人物の目線高。背景として歪みの少ない一枚絵。
- 表現: polished pixel-art / hand-painted pixel illustration。参照のタイル密度と輪郭を手本にし、写真・3Dレンダーにはしない。
- 色: 暖色の琥珀/木、深い濃紺の影、海の青緑。processorで `Palette.DARK_PANEL` 系の減光と彩度統一を加える前提。

## 禁止事項

- 日本語、英字、数字、記号、看板文字、ロゴ、透かし
- UI枠、パネル、カード、ボタン、ゲージ、HUD
- 人物、料理、皿、食卓上の完成料理、魚、釣果
- 参照PNGのコピー/切り抜き、既存ゲーム固有アートへの酷似
- 写真調、滑らかな3D、平坦なベクター、純PILで代替可能な単純矩形だけの背景
- 前景情報面と競合する極端な白飛び、高彩度、細密ノイズ

## ImageGen prompt

```text
Use case: stylized-concept
Asset type: authored 16:9 game-screen background for a warm JRPG cooking selection UI
Primary request: a richly authored fishing-town kitchen interior with warm lantern light, a clear window view of the blue sea and harbor, and readable shelves filled with cookware, jars, hanging herbs, ropes, and practical kitchen tools
Input images: Image 1 is the style, atmosphere, and environmental-density reference only; Images 2-5 are regression references for the broader cooking flow only
Scene/backdrop: cozy working kitchen attached to a seaside fishing harbor, weathered timber and stone, open ocean window, subtle depth beyond the room
Style/medium: polished hand-painted pixel-art game background, premium Japanese fishing RPG mood, crisp clustered pixels, painterly material detail, not photorealistic and not 3D
Composition/framing: 16:9 wide frontal interior, useful environmental details at the outer edges and in a narrow center-right vertical sightline; quieter lower-contrast surfaces across the broad center where opaque UI panels will sit
Lighting/mood: warm amber lantern pools against deep navy-brown shadows, cool blue sea daylight through the window, inviting and lived-in
Color palette: amber wood, dark navy shadow, parchment-neutral stone, restrained teal-blue ocean
Materials/textures: worn timber grain, iron cookware, glass jars, rope, herbs, masonry, soft atmospheric dust
Constraints: environment only; no characters, no people, no food, no plated dish, no fish, no UI, no frames, no panels, no buttons, no text, no letters, no numbers, no symbols, no logo, no watermark
Avoid: generic tavern, restaurant dining room, photographic look, smooth 3D render, flat vector art, centered hero object, excessive bloom, high-frequency clutter in the middle, illegible pseudo-text on labels or signs
```

## 決定的統一処理

1. sourceを中央cropして16:9化し、LANCZOSで1280x720へ正規化する。
2. 彩度を抑え、軽いcontrast調整で生成ごとの色密度を揃える。
3. `Palette.DARK_PANEL` 相当の濃紺減光scrimを全面へ合成する。背景は読めるが、前景情報より先に読ませない。
4. PNGは固定パラメータで保存し、decoded pixelsが同一なら既存bytesを保持する。

## 採用基準

- 原寸before/afterで、暖色ランタン光、海の見える窓、調理棚が背景として読め、現行の平坦な矩形背景に明確に勝つ。
- 320x180のafter/reference比較で、COOK_SELECTの背景差が縮む。
- 前景の料理名、材料、EXP、効果、CTA、魚名、所持数にP1がない。
- 5状態比較で、COOK_SELECTを背面に使う状態は背景差だけ、専用不透明状態は意図しない差ゼロ。
- 日本語/英字/数字/UI枠/人物/料理/魚の焼き込みがない。
