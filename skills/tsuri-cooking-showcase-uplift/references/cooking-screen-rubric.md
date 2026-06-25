# Cooking Screen Quality Rubric

## Target Read

The cooking flow should feel like a warm JRPG cooking and reward sequence. Do not force every reference-image region into one permanent screen.

Primary states:

- `COOK_SELECT`: normal cooking interaction.
- `MEAL_RESULT`: dish/eating payoff after cooking.
- `EXP_GAIN`: food EXP accumulation.
- `LEVEL_UP_OVERLAY`: level-up and unlock celebration.
- `STATUS_SUMMARY`: compact player/meal/cooler/money summary.

Across the flow, the player should understand:

- left: owned fish inventory with readable fish icons and counts
- center: recipe choices as visual dish cards, with selected and locked states
- right: selected dish detail with a featured dish image, EXP, effect, materials, and stock delta
- lower/moment layer: eating result, EXP gain, current meal effect, and a strong LEVEL UP reward
- bottom/status: player status, active meal, cooler box, and money summarized as cards

## State Acceptance

### COOK_SELECT

- Owned fish rows show fish identity, count, and selected state without stock `ItemList` feel.
- Recipe choices are cards with dish art, availability/locked/selected state, and clear recipe names.
- Selected dish detail shows featured dish art, material requirement, stock delta, EXP, buff, and overwrite note in a scannable layout.
- The cook action is visually primary but does not compete with the dish image.

### MEAL_RESULT

- The player can tell which dish was eaten and why the result is rewarding.
- Gained EXP, first-time bonus, total reward, and pending meal buff are separated into readable reward cards.
- The scene feels like a payoff moment, not another selection form.

### EXP_GAIN

- Food EXP meter and `+EXP` change dominate the state.
- Source dish, first-time bonus, and buff preview support the meter without crowding it.
- If no level-up happens, returning to `COOK_SELECT` feels complete.

### LEVEL_UP_OVERLAY

- Level transition is the strongest visual hierarchy on screen.
- Stat increases are readable as before/after changes, not buried in body copy.
- Lv.5 boss/unlock callout is explicit and celebratory.
- Background dimming blocks accidental interaction and keeps focus on the reward.

### STATUS_SUMMARY

- Player level/stats, active meal, cooler box, money, and play time are scannable as cards.
- This state should not duplicate recipe selection controls.
- It may be a bottom layer inside cooking or a reusable summary view, but it must stay readable at 1280x720.

## P1 Defects

Fix before broadening scope:

- The screen still reads as a generic data-entry form or stock `ItemList` UI.
- The implementation tries to show the entire reference image at once instead of separating interaction, result, EXP, level-up, and status states.
- The selected dish, material requirement, EXP, effect, or level-up result is hard to find.
- Text overlaps, clips, or is too small to read at 1280x720.
- The level-up panel is visually weaker than ordinary panels.
- Dish/fish images are missing, extremely low quality, or obviously placeholder final art.
- Background or card art makes foreground text unreadable.
- Cooking changes break inventory, EXP, level-up, or pending-buff behavior.

## P2 Defects

Fix after P1:

- Recipe cards lack enough material quality or state distinction.
- The right detail card has weak hierarchy between title, image, description, EXP, effect, materials, and stock delta.
- Fish inventory rows have weak icons or unclear selected state.
- Meal-result and EXP-gain areas feel disconnected from the main cooking action.
- Level-up stats are readable but not celebratory.
- Panel spacing or proportions differ from the reference enough to weaken the showcase composition.

## P3 Polish

Only polish after P1/P2 are under control:

- Steam, sparkles, small particles, and subtle motion.
- Tiny icon consistency.
- Fine paper grain, bevel strength, and shadow tuning.
- Secondary text optical sizing.
- Extra dish variants beyond the selected showcase dish.

## Suggested Cooking Asset Slots

Create only the slots needed for the current pass, under `assets/showcase/cooking/`:

- `cooking_room_bg.png`
- `meal_scene_bg.png`
- `fish_icon_sheet.png`
- `dish_icon_sheet.png`
- `dish_feature_aji_shioyaki.png`
- `recipe_grid_frame.png`
- `recipe_card_frame.png`
- `dish_detail_frame.png`
- `meal_result_frame.png`
- `level_up_frame.png`
- `status_card_frame.png`
- `cooking_icon_sheet.png`

Generated assets are acceptable as iteration assets, but mark them as replaceable and do not confuse them with final art.

## Preview Captures

Use `/tmp/tsuri_cooking.png` as the initial all-purpose capture. Once states exist, prefer stable state-specific captures:

- `/tmp/tsuri_cooking_select.png`
- `/tmp/tsuri_cooking_result.png`
- `/tmp/tsuri_cooking_exp.png`
- `/tmp/tsuri_cooking_levelup.png`
- `/tmp/tsuri_cooking_status.png`

If headless Godot cannot return `SubViewport` images, use the normal local Godot invocation for screenshots and keep the output paths stable.

## Implementation Boundaries

Prefer:

- `src/ui/cooking_screen.gd`
- `src/ui/components/level_up_panel.gd`
- `src/ui/components/cooking_*`
- `tools/cooking_preview.gd`
- `tools/cooking_*`
- `assets/showcase/cooking/*`

Avoid unless clearly necessary:

- `src/ui/screen_base.gd`
- `src/ui/ui_theme.gd`
- `src/ui/palette.gd`
- `src/autoload/game_data.gd`
- `src/autoload/player_progress.gd`
- `src/main.gd`
- `project.godot`

## Freeze Rules

Freeze a region when it meets its functional read and has no P1 visual defect. Do not keep editing it only because it is not identical to the reference.

- Background: warm mood, readable foreground, no obvious seams, no placeholder artifacts.
- Fish inventory: selected row and fish counts are clear, icons are not embarrassing, no text collision.
- Recipe grid: selected, available, and locked states are clear; dish art reads at card size.
- Detail card: title, dish image, EXP, effect, material, and stock delta are scannable.
- Meal result: dish eaten, EXP, first-time bonus, and buff are readable as a short payoff.
- EXP gain: the meter update is central and the state can finish cleanly without level-up.
- Level-up panel: level transition, stat increases, and unlock callout are the strongest reward moment.
- Status summary: cards are readable and do not reintroduce dense form layout.

## Done For First Showcase Pass

The first pass is done when the static screenshot looks intentionally authored at 1280x720, even if some assets remain temporary. It is not done if the screen still depends on stock list styling, flat generic panels, or dense paragraph text to carry the experience.
