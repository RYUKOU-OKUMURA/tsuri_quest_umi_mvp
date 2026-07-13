# 47. サメの生簀 水槽背景・環境光 uplift 仕様

Date: 2026-07-13
対象: `src/ui/shark_pen_screen.gd`
正式参照: `reference/12_shark_pen_mockup.png`
適用手順: `docs/19_ui_production_playbook.md` / `skills/ui-screen-uplift/SKILL.md`

## 1. uplift判定と仮説

- 画面タイプ: 一覧＋育成メニュー。主対象は左の水槽、主操作は下段「あたえる」。
- 判定: **局所uplift**。10枠、給餌、戻る、読み順、主要矩形は成立しており、水槽のruntimeグラデーション・直線状の泡/流線だけが独立したTop1差分。
- 仮説: 水槽の可視wellを画面専用のauthored背景PNGへ置き換えれば、矩形と魚表示を動かさず、参照の深い海水色・有機的な泡・上方からの環境光へ明確に近づく。
- 動かすもの: `SharkPenAquariumWater` のtexture、旧runtime流線3本の撤去、背景素材の表示確認。
- 動かさないもの: 全freeze矩形、サメ10枠、なつき度、餌5枠/全件スクロール、給餌CTA、港へ戻る、魚素材/配置、王冠、メガロドン演出。
- 採否条件: 原寸でP1ゼロ、beforeへ全画面で明確に勝ち、320x180相当の縮小でも参照との水槽Top1差分が縮むこと。

## 2. 状態契約

| 状態 | 固定データ | 固定アンカー | 出力 | smoke契約 |
|---|---|---|---|---|
| 標準 | Lv50 / メガロドン84 / 餌5種 / 10枠 | 水槽、選択列、餌、CTA、戻る | `tsuri_shark_pen.png` | 素材表示、10枠、導線維持 |
| 高リスク | 標準と同一seed / メガロドン選択＋hover/focus | 同上 | `tsuri_shark_pen_selected_hover.png` | 選択中の明背景と濃色文字の可読性維持 |

## 3. 一点物素材 発注仕様（docs/12形式）

### 出力スロット

- source: `tools/source_assets/shark_pen/shark_pen_tank_bg_source.png`
- processed: `assets/showcase/shark_pen/tank_environment_bg.png`
- runtime表示領域: 水槽パネル内側 約700x420px。sourceは等倍以上のlandscapeで生成し、中央crop＋1280x768処理後に縮小表示する。

### ImageGenプロンプト

```text
Use case: stylized-concept
Asset type: authored game environment background for a shark aquarium well in a premium Japanese fishing RPG UI
Primary request: an empty deep-sea aquarium interior with rich water depth, soft organic bubble trails, and restrained overhead environmental lighting
Input images: Image 1 is the official full-screen composition reference; Image 2 is the current runtime screenshot showing the exact aquarium well and UI safe areas
Scene/backdrop: deep teal-blue aquarium water, subtle glass depth, faint suspended particles, very restrained dark seabed haze near the lower edge
Subject: environment only; no fish, sharks, people, UI, frames, gauges, labels, or text
Style/medium: polished hand-painted game background, premium JRPG environment art, coherent with the official reference without copying its UI
Composition/framing: wide landscape; calm center kept readable for one large shark; upper-left title safe area stays dark and quiet; edges slightly deeper; no hard horizon
Lighting/mood: soft shafts and caustic glow entering from above, quiet mysterious aquarium mood, bubbles integrated into depth rather than straight graphic lines
Color palette: deep navy, teal, muted cyan highlights; avoid bright saturated royal blue
Materials/textures: layered water depth, soft particulate haze, subtle glass reflection, painterly but not blurry
Constraints: no text, no watermark, no logo, no frame, no fish or animal silhouettes, no fishing line, no straight HUD-like streaks; preserve broad negative space and high fish readability
Avoid: photorealistic public aquarium, coral reef clutter, bright tropical water, black void, generic gradient, strong white beams through the center, decorative UI marks
```

### 統一処理

- source中央cropを表示比率へ合わせ、1280x768へLanczos縮小。
- teal/deep-navyへ軽く色相・彩度を寄せ、中央の魚safe-areaを過度に明るくしない。
- sourceは保存し、加工を `tools/generate_shark_pen_assets.py` で再現可能にする。
- 日本語/英字テキスト、魚、UI枠を含む候補は不採用。

## 4. 比較基準

1. 原寸before/after/referenceで、魚・タイトル・下段ラベルの可読性と既存矩形が不変。
2. 縮小比較で、水槽が単色の青い矩形ではなく、参照と同じ深い海中の主領域として先に読める。
3. グレースケールで魚と水槽背景が分離し、中央光が魚の白い腹を飛ばさない。
4. 標準/selected-hover双方でP1ゼロ。
