# Water Fight Lessons For Cooking Uplift

## What Worked

- One-screen scope worked. The underwater fight improved once it was treated as a single showcase screen instead of a broad app-wide redesign.
- A fixed reference worked. Every quality judgment was made against `reference/02_underwater_fight_mockup.png`, not against vague taste.
- Asset slots worked. Background, fish, HUD frames, sidebar frames, icons, hit effects, and fonts became replaceable assets instead of being simulated only with Control nodes and `_draw()`.
- Deterministic screenshots worked. Stable `/tmp` captures made comparison possible after every pass.
- P1/P2/P3 worked. Blocking visual defects were separated from ideal-quality polish, which kept the work moving.
- Rejecting placeholder quality worked. Early generated/procedural assets were useful scaffolding but not acceptable as final art direction.
- Freeze rules worked. The background started to loop until explicit acceptance criteria stopped repeated brightness, bubble, and floor-light tweaks.

## What Did Not Work

- Polishing low-quality source assets did not produce high-quality UI. The screen improved only after the source assets became closer to the reference.
- Generic gold grid/frame decoration read as debug UI, not premium JRPG UI.
- Over-segmented panels and strong guide rules made cards look like forms.
- Small dense text inside ornate cards made the screen feel less authored.
- Repeatedly changing one region without a whole-screen comparison created loop risk.

## Transfer To Cooking

- Treat `reference/03_cooking_levelup_mockup.png` as the cooking screen's source of visual truth.
- Build cooking-owned assets instead of pushing generic `make_panel()` and `ItemList` styling too far.
- Keep a deterministic `tools/cooking_preview.gd` state and compare after every pass.
- Freeze regions once they no longer block the whole-screen read.
- Focus first on visual hierarchy: selected fish, selected recipe, featured dish, cook/eat result, EXP, and level-up reward.

## Loop Warning Signs

- The same background warmth, card border, grain, or shadow is adjusted across several passes without improving the whole screenshot.
- Changes describe "slightly brighter", "a little denser", or "more texture" but do not address a named P1/P2 issue.
- The work keeps editing shared theme files while the cooking screen still lacks dedicated dish/card assets.
- The screenshot still looks like a form, but the active work is only small spacing or color tuning.

## Recommended Stop Conditions

- Freeze background once it establishes a warm kitchen/meal mood, keeps all text readable, and has no obvious tiling, seam, or placeholder artifact.
- Freeze recipe-card frames once selected/unselected/locked states are clear and no text or art collides.
- Freeze the level-up panel once the reward hierarchy is strong, stats are readable, and the boss unlock callout is visible.
- Reopen frozen areas only for P1 defects or if a later whole-screen comparison shows a clear regression.
