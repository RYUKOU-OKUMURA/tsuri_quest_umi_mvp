# Underwater Fight Design QA

final result: blocked

Date: 2026-06-24

Reference: `reference/02_underwater_fight_mockup.png`
Current capture: `/tmp/tsuri_fishing_fight.png`
Side-by-side page: `/tmp/tsuri_fight_compare.html`

## Current Pass

- Fixed: the broad gold grid/debug-like 9-slice UI skin is no longer used for normal panels and buttons.
- Improved: the underwater background now uses a dense AI-generated reef background with stronger light shafts, rocks, seaweed, bubbles, distant fish, and seabed depth.
- Improved: the main kurodai now uses an AI-generated transparent four-frame sprite sheet with stronger anatomy, scales, fins, eye detail, and silhouette.
- Improved: the hit burst now uses an AI-generated splash/impact asset, with the preview capturing the hit moment for reference comparison.
- Still blocked: the top status area, right panel, and bottom HUD are not yet at the reference's JRPG window/card quality.

## Blocking Differences

1. Layout: the current top status bar uses broad dark cards, while the reference has compact parchment cards plus a smaller blue depth card.
2. Main composition: the fish and background are closer, but the hit effect and fish placement still need a final art-direction pass against the reference.
3. Right panel: the current panel is layout-correct and uses the better fish portrait, but the frame, header, description density, and tackle card are still not a finished JRPG information card.
4. Bottom HUD: the reference uses custom gauge framing, segmented tension, icons, bait card, operation hint card, and menu card. The current HUD is still plain functional UI.
5. Typography/icons: the reference has icon-led labels and denser hierarchy; the current screen still relies on plain text labels and generic buttons.

## Next Required Iteration

1. Rebuild the top status bar to match the reference's card density and hierarchy.
2. Replace the bottom HUD frame with a dedicated art-directed panel and segmented gauges.
3. Replace the right info-card frame/header/action/tackle panels with dedicated high-quality window assets.
4. Re-run `tools/fishing_fight_preview.gd`, rebuild `/tmp/tsuri_fight_compare.html`, and compare against the same five criteria: density, spacing, color, fish presence, and UI frame quality.
