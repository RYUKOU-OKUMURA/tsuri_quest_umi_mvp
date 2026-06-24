# Underwater Fight Design QA

final result: blocked

Date: 2026-06-24

Reference: `reference/02_underwater_fight_mockup.png`
Current capture: `/tmp/tsuri_fishing_fight.png`
Side-by-side page: `/tmp/tsuri_fight_compare.html`

## Current Pass

- Fixed: the broad gold grid/debug-like 9-slice UI skin is no longer used for normal panels and buttons.
- Still blocked: the current background, kurodai sprite, hit effect, right panel, and bottom HUD are not production-quality assets.

## Blocking Differences

1. Fish presence: the current kurodai is readable but lacks the reference's organic silhouette, scale texture, fins, eye detail, and lighting.
2. Background density: the current water scene has simple repeated silhouettes and sparse props; the reference has layered rocks, seaweed, bubbles, light shafts, seabed detail, and distant fish groups.
3. Main composition: the reference gives the fish and bait a strong central stage; the current capture still feels like a functional UI over a temporary backdrop.
4. Right panel: the current panel is layout-correct but not a finished JRPG information card. The fish portrait and card frame are both temporary.
5. Bottom HUD: the reference uses custom gauge framing, segmented tension, icons, and dense control cards. The current HUD is cleaner after the theme fix but still too plain.

## Next Required Iteration

1. Create production-quality kurodai art before further sprite tuning.
2. Create a dense 16:9 underwater background with rocks, seaweed, bubbles, light shafts, and distant fish.
3. Replace the bottom HUD frame and right info-card frame with dedicated image assets.
4. Re-run `tools/fishing_fight_preview.gd`, rebuild `/tmp/tsuri_fight_compare.html`, and compare against the same five criteria: density, spacing, color, fish presence, and UI frame quality.
