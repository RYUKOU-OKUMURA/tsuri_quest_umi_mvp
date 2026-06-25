---
name: tsuri-cooking-showcase-uplift
description: Project-local workflow for raising this repository's cooking, meal, EXP, level-up, and status-summary flow toward the five state-specific cooking references in `reference/cooking_flow/`. Use when Codex works on `src/ui/cooking_screen.gd`, `src/ui/components/level_up_panel.gd`, `src/ui/components/cooking_*`, `tools/cooking_preview.gd`, `reference/cooking_flow/*`, or `assets/showcase/cooking/*`, especially when implementing state-split cooking UI, meal-result UI, EXP/level-up presentation, dish/fish assets, or reference-driven visual QA for the cooking flow.
---

# Tsuri Cooking Showcase Uplift

## Purpose

Turn the cooking, meal, and level-up flow into showcase-quality screens using the five images in `reference/cooking_flow/` as the positive state references. Preserve the existing cooking and progression logic while replacing flat stock UI with authored assets, stronger composition, and repeatable visual QA.

`reference/03_cooking_levelup_mockup.png` is the parent direction image only. The implementation target is the state-by-state reference set:

- `reference/cooking_flow/01_cook_select_concept.png`
- `reference/cooking_flow/02_meal_result_concept.png`
- `reference/cooking_flow/03_exp_gain_concept.png`
- `reference/cooking_flow/04_level_up_overlay_concept.png`
- `reference/cooking_flow/05_status_summary_concept.png`

Do not generate replacement concept images unless the user explicitly asks. Treat these five files as the source of truth for layout, density, major parts, visual hierarchy, and effect timing. Do not import these reference PNGs into the game as final UI; decompose them into reusable parts under `assets/showcase/cooking/`.

Treat the reference set as five separate moments, not as one always-visible playable screen. Split the implementation into stateful screens/overlays:

- `COOK_SELECT`: normal cooking interaction with owned fish, recipe cards, selected dish detail, materials, EXP, buff, and cook button.
- `MEAL_RESULT`: short payoff after cooking/eating, showing the dish, gained EXP, first-time bonus, and pending meal buff.
- `EXP_GAIN`: focused food EXP meter update. If no level-up occurs, the flow can return to `COOK_SELECT` here.
- `LEVEL_UP_OVERLAY`: strong reward overlay for level transition, stat gains, and Lv.5 boss/unlock callout.
- `STATUS_SUMMARY`: standalone status-summary view with level/stats, active meal, cooler box, money, and play time. Keep the compact bottom strip for context where useful, but use `05_status_summary_concept.png` as the target for the dedicated summary state.

## Load Before Acting

Read these when doing cooking-screen implementation or review:

- `references/water-fight-lessons.md` for lessons from the underwater fight uplift.
- `references/cooking-screen-rubric.md` for cooking-specific quality gates and freeze rules.
- `reference/cooking_flow/README.md` for the reference-set contract.

Also inspect the current project files before editing:

- `reference/03_cooking_levelup_mockup.png`
- `reference/cooking_flow/01_cook_select_concept.png`
- `reference/cooking_flow/02_meal_result_concept.png`
- `reference/cooking_flow/03_exp_gain_concept.png`
- `reference/cooking_flow/04_level_up_overlay_concept.png`
- `reference/cooking_flow/05_status_summary_concept.png`
- `src/ui/cooking_screen.gd`
- `src/ui/components/level_up_panel.gd`
- `tools/cooking_preview.gd`
- `docs/03_画面遷移とUI.md`
- `docs/10_UIクオリティ向上マスタープラン.md`

Before editing `.gd` UI code, extract the target layout, major parts, effects, and needed asset slots from the relevant reference image(s). If implementation is already in progress, keep it, compare it against the five references, then adjust the plan. Do not discard working flow code just because the visual direction is changing.

## State Reference Extraction

Use this extraction as the first comparison baseline. Refine it only after inspecting the actual reference images again.

### `COOK_SELECT` - `01_cook_select_concept.png`

- Layout: full warm fishing-town kitchen background; top wooden sign/title, player EXP header, money header; main three-column body; bottom persistent status strip.
- Major parts: large owned-fish rows with fish art and counts; centered 3x2 recipe card grid; selected recipe glow; right parchment detail card with large dish image, material stock/need row, EXP row, next-fishing effect row, and primary cook button.
- Effects: lantern glow, ocean/window depth, selected-card gold glow, nautical/wood trim.
- Asset slots: kitchen room background, fish row frames, large fish icons, recipe card frames, dish portraits, detail frame, cook button skin, bottom status cards, player portrait, money/cooler/effect icons.

### `MEAL_RESULT` - `02_meal_result_concept.png`

- Layout: dedicated eating-result scene, not a form overlay; left table/player eating illustration, right top large "ate dish" banner, right middle dish card, lower reward cards, bottom status strip.
- Major parts: meal-scene background, player eating pose, large dish on table, dish result banner, current-dish panel, four reward cards for gained food EXP, first-time bonus, total EXP, and next-fishing effect.
- Effects: steam, warm lantern light, sparkles, celebratory card glow.
- Asset slots: meal scene background, eating character art, table/dish foreground, result banner frame, reward card frames, EXP/rice/chef/effect icons.

### `EXP_GAIN` - `03_exp_gain_concept.png`

- Layout: dedicated EXP gain state; huge title at top, giant `+EXP` centered, central EXP gauge, left eaten-dish card, right next-effect card, bottom status strip.
- Major parts: before/after EXP numbers, bright cyan gauge, character message panel under the gauge, first-time bonus block inside the left card, next-effect illustration and duration inside the right card.
- Effects: radial burst behind `+EXP`, sparkles, energy trails from dish to gauge/effect, cyan gauge flash.
- Asset slots: EXP stage background, burst/sparkle overlays, dish info card, effect card, gauge frame/fill, character portrait/message box, effect illustration.

### `LEVEL_UP_OVERLAY` - `04_level_up_overlay_concept.png`

- Layout: dimmed cooking-selection screen remains visible; large central celebratory dialog dominates; bottom status strip remains dimmed.
- Major parts: giant `LEVEL UP!` with crown/laurel, `Lv.4 -> Lv.5`, two columns of stat before/after rows, red unlock ribbon, parchment unlock card, boss/spot medallion, fishing-spot thumbnail, large OK button.
- Effects: dark backdrop, gold rays, confetti, sparkles, overlay focus blocking background interaction.
- Asset slots: level-up dialog frame, crown/laurel graphics, confetti/sparkle FX, stat icons, unlock ribbon, medallion, unlock location thumbnail, OK button skin.

### `STATUS_SUMMARY` - `05_status_summary_concept.png`

- Layout: standalone status-summary screen rather than a small modal; top navy header with title/player EXP; wide harbor/kitchen background; five large vertical cards; bottom message bar and return button.
- Major parts: player card with portrait and stats, active meal card with dish image/effect/remaining uses, cooler card with cooler art and capacity, money card with coin art, play-time card with clock art.
- Effects: calm post-reward presentation, readable parchment cards, nautical header/footer trim.
- Asset slots: status background, player portrait, five card frames, meal/cooler/money/clock illustrations, bottom message bar, return button skin.

## Workflow

1. Re-read and compare against the five state references before changing visuals.
   For the state being edited, inspect the matching `reference/cooking_flow/*_concept.png`, then write or update a short comparison note in the QA doc: target layout, current implementation gap, planned change, and freeze condition. Do this before `.gd` layout work.

2. Fix deterministic preview states before changing visuals.
   Start with one end-to-end state: player Lv.4, EXP near level-up, several fish in inventory, `アジの塩焼き` selected, meal consumed, EXP gained, Lv.5 reached, and the boss/unlock callout visible. As the flow splits, keep stable captures for each implemented state, for example `/tmp/tsuri_cooking_select.png`, `/tmp/tsuri_cooking_result.png`, `/tmp/tsuri_cooking_exp.png`, `/tmp/tsuri_cooking_levelup.png`, and `/tmp/tsuri_cooking_status.png`.

3. Capture the current screen.
   Use the existing cooking preview path and keep a stable screenshot at `/tmp/tsuri_cooking.png` until state-specific captures exist. If `--headless` cannot read `SubViewport` textures on this machine, use the normal Godot invocation for capture instead of weakening the preview. If the Godot command differs, discover the local invocation rather than rewriting the preview tool.

4. Compare against the matching state reference.
   Put generated capture(s) next to the corresponding `reference/cooking_flow/*_concept.png`. Judge the whole state first, then focus areas. Do not rely on "the code is working" as a visual-quality signal.

5. Decompose the state reference into asset slots.
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
   - player eating/status portraits
   - reward card icons
   - unlock medallion/location thumbnail
   - cooler, money, and play-time illustrations

6. Implement the flow in this order unless the latest comparison proves otherwise.
   First make `COOK_SELECT` read as an authored cooking UI. Then add `MEAL_RESULT`, `EXP_GAIN`, `LEVEL_UP_OVERLAY`, and finally `STATUS_SUMMARY`/polish. Do not build all reference-image regions as permanent widgets in one screen.

7. Implement mostly inside cooking-owned files.
   Prefer `src/ui/cooking_screen.gd`, `src/ui/components/level_up_panel.gd`, `tools/cooking_preview.gd`, new `src/ui/components/cooking_*` files, new `tools/cooking_*` scripts, and `assets/showcase/cooking/*`.
   Avoid shared files unless the change is clearly reusable and needed now: `src/ui/screen_base.gd`, `src/ui/ui_theme.gd`, `src/ui/palette.gd`, `src/autoload/game_data.gd`, `src/autoload/player_progress.gd`, `src/main.gd`, and `project.godot`.

8. Replace stock-looking controls before micro-polishing.
   Godot `ItemList`, flat panels, generic labels, and plain buttons are acceptable as scaffolding only. Showcase quality requires authored card surfaces, icons, dish art, intentional hierarchy, and custom layout.

9. Make one high-impact visual pass at a time.
   Work in this order unless the current comparison proves otherwise:
   - screen composition and major panel proportions
   - dish/fish/meal artwork
   - cooking-specific frames and recipe cards
   - level-up and EXP reward presentation
   - typography, spacing, and small icon polish
   - animation/juice after static composition reads well

10. Record QA after each pass.
   Keep notes in the relevant project QA doc or a cooking-specific QA file if one exists. Mark findings as P1/P2/P3 and include screenshot paths. If a region is "good enough for this pass", freeze it.

## Acceptance Gate

Before considering a pass complete:

- `/tmp/tsuri_cooking.png` exists and was produced from a deterministic preview state.
- Each implemented state has a capture or explicit current blocker recorded against its matching `reference/cooking_flow/*_concept.png`.
- The screen reads as a warm cooking/reward scene, not a generic form.
- The selected dish, required material, EXP gain, meal effect, and level-up outcome are visible without reading dense paragraphs.
- Recipe cards and detail cards look authored, not like stock list widgets.
- The level-up panel has enough presence to feel like the reward beat.
- Each implemented state has a clear reason to exist and does not duplicate the whole reference image permanently.
- No text overlaps, clips, or becomes too small inside cards.
- Loop-prone areas have a written freeze condition.

## Hard Rules

- Do not treat low-quality generated or procedural placeholder art as final.
- Do not create new concept images when the required state references already exist in `reference/cooking_flow/`.
- Do not keep polishing a weak stock-widget layout when the real gap is missing assets or composition.
- Do not change cooking progression logic unless the user asked for behavior changes.
- Do not copy the water-fight palette literally; cooking should be warm, indoor, food/reward-oriented.
- Do not import `reference/03_cooking_levelup_mockup.png` or `reference/cooking_flow/*.png` directly into the game as final assets. Use them as visual direction and create proper cooking asset slots.
