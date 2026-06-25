---
name: tsuri-cooking-showcase-uplift
description: Project-local workflow for raising this repository's cooking, meal, EXP, level-up, and status-summary flow toward reference-mockup quality. Use when Codex works on `src/ui/cooking_screen.gd`, `src/ui/components/level_up_panel.gd`, `tools/cooking_preview.gd`, `reference/03_cooking_levelup_mockup.png`, or `assets/showcase/cooking/*`, especially when implementing state-split cooking UI, meal-result UI, EXP/level-up presentation, dish/fish assets, or reference-driven visual QA for the cooking flow.
---

# Tsuri Cooking Showcase Uplift

## Purpose

Turn the cooking, meal, and level-up flow into showcase-quality screens using `reference/03_cooking_levelup_mockup.png` as the visual target. Preserve the existing cooking and progression logic while replacing flat stock UI with authored assets, stronger composition, and repeatable visual QA.

Treat the reference image as a compressed concept of several moments, not as one always-visible playable screen. Split the implementation into stateful screens/overlays:

- `COOK_SELECT`: normal cooking interaction with owned fish, recipe cards, selected dish detail, materials, EXP, buff, and cook button.
- `MEAL_RESULT`: short payoff after cooking/eating, showing the dish, gained EXP, first-time bonus, and pending meal buff.
- `EXP_GAIN`: focused food EXP meter update. If no level-up occurs, the flow can return to `COOK_SELECT` here.
- `LEVEL_UP_OVERLAY`: strong reward overlay for level transition, stat gains, and Lv.5 boss/unlock callout.
- `STATUS_SUMMARY`: compact status cards for level/stats, active meal, cooler box, money, and play time. Use as a bottom/status layer or separate summary view when useful.

## Load Before Acting

Read these when doing cooking-screen implementation or review:

- `references/water-fight-lessons.md` for lessons from the underwater fight uplift.
- `references/cooking-screen-rubric.md` for cooking-specific quality gates and freeze rules.

Also inspect the current project files before editing:

- `reference/03_cooking_levelup_mockup.png`
- `src/ui/cooking_screen.gd`
- `src/ui/components/level_up_panel.gd`
- `tools/cooking_preview.gd`
- `docs/03_画面遷移とUI.md`
- `docs/10_UIクオリティ向上マスタープラン.md`

## Workflow

1. Fix deterministic preview states before changing visuals.
   Start with one end-to-end state: player Lv.4, EXP near level-up, several fish in inventory, `アジの塩焼き` selected, meal consumed, EXP gained, Lv.5 reached, and the boss/unlock callout visible. As the flow splits, keep stable captures for each implemented state, for example `/tmp/tsuri_cooking_select.png`, `/tmp/tsuri_cooking_result.png`, `/tmp/tsuri_cooking_exp.png`, `/tmp/tsuri_cooking_levelup.png`, and `/tmp/tsuri_cooking_status.png`.

2. Capture the current screen.
   Use the existing cooking preview path and keep a stable screenshot at `/tmp/tsuri_cooking.png` until state-specific captures exist. If `--headless` cannot read `SubViewport` textures on this machine, use the normal Godot invocation for capture instead of weakening the preview. If the Godot command differs, discover the local invocation rather than rewriting the preview tool.

3. Compare against the reference.
   Put the generated capture(s) next to `reference/03_cooking_levelup_mockup.png`. Judge the whole state first, then focus areas. Do not rely on "the code is working" as a visual-quality signal.

4. Decompose the reference into asset slots.
   Prefer dedicated cooking assets under `assets/showcase/cooking/` for:
   - warm kitchen or meal-scene background
   - fish list icons
   - dish card portraits
   - featured dish image
   - recipe-grid frame
   - detail-card frame
   - meal-result/EXP frame
   - level-up frame and stat icons
   - bottom status cards

5. Implement the flow in this order unless the latest comparison proves otherwise.
   First make `COOK_SELECT` read as an authored cooking UI. Then add `MEAL_RESULT`, `EXP_GAIN`, `LEVEL_UP_OVERLAY`, and finally `STATUS_SUMMARY`/polish. Do not build all reference-image regions as permanent widgets in one screen.

6. Implement mostly inside cooking-owned files.
   Prefer `src/ui/cooking_screen.gd`, `src/ui/components/level_up_panel.gd`, `tools/cooking_preview.gd`, new `src/ui/components/cooking_*` files, new `tools/cooking_*` scripts, and `assets/showcase/cooking/*`.
   Avoid shared files unless the change is clearly reusable and needed now: `src/ui/screen_base.gd`, `src/ui/ui_theme.gd`, `src/ui/palette.gd`, `src/autoload/game_data.gd`, `src/autoload/player_progress.gd`, `src/main.gd`, and `project.godot`.

7. Replace stock-looking controls before micro-polishing.
   Godot `ItemList`, flat panels, generic labels, and plain buttons are acceptable as scaffolding only. Showcase quality requires authored card surfaces, icons, dish art, intentional hierarchy, and custom layout.

8. Make one high-impact visual pass at a time.
   Work in this order unless the current comparison proves otherwise:
   - screen composition and major panel proportions
   - dish/fish/meal artwork
   - cooking-specific frames and recipe cards
   - level-up and EXP reward presentation
   - typography, spacing, and small icon polish
   - animation/juice after static composition reads well

9. Record QA after each pass.
   Keep notes in the relevant project QA doc or a cooking-specific QA file if one exists. Mark findings as P1/P2/P3 and include screenshot paths. If a region is "good enough for this pass", freeze it.

## Acceptance Gate

Before considering a pass complete:

- `/tmp/tsuri_cooking.png` exists and was produced from a deterministic preview state.
- The screen reads as a warm cooking/reward scene, not a generic form.
- The selected dish, required material, EXP gain, meal effect, and level-up outcome are visible without reading dense paragraphs.
- Recipe cards and detail cards look authored, not like stock list widgets.
- The level-up panel has enough presence to feel like the reward beat.
- Each implemented state has a clear reason to exist and does not duplicate the whole reference image permanently.
- No text overlaps, clips, or becomes too small inside cards.
- Loop-prone areas have a written freeze condition.

## Hard Rules

- Do not treat low-quality generated or procedural placeholder art as final.
- Do not keep polishing a weak stock-widget layout when the real gap is missing assets or composition.
- Do not change cooking progression logic unless the user asked for behavior changes.
- Do not copy the water-fight palette literally; cooking should be warm, indoor, food/reward-oriented.
- Do not import `reference/03_cooking_levelup_mockup.png` directly into the game as a final asset. Use it as visual direction and create proper cooking asset slots.
