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
- Improved: the empty message strip under the water view was removed; messages now overlay the water only when useful, giving the fight scene more vertical space.
- Improved: the top status area now uses compact cards for time, weather/wind, money, and location/depth.
- Still blocked: the right panel and bottom HUD are not yet at the reference's JRPG window/card quality.

## Blocking Differences

1. Main composition: the fish and background are closer, but the hit effect and fish placement still need a final art-direction pass against the reference.
2. Top status: the card structure is closer, but iconography and small ornamental frames are still weaker than the reference.
3. Right panel: the current panel is layout-correct and uses the better fish portrait, but the frame, header, description density, and tackle card are still not a finished JRPG information card.
4. Bottom HUD: the reference uses custom gauge framing, segmented tension, icons, bait card, operation hint card, and menu card. The current HUD is still plain functional UI.
5. Typography/icons: the reference has icon-led labels and denser hierarchy; the current screen still relies on plain text labels and generic buttons.

## Next Required Iteration

1. Replace the bottom HUD frame with a dedicated art-directed panel and segmented gauges.
2. Replace the right info-card frame/header/action/tackle panels with dedicated high-quality window assets.
3. Add icon-led status/details where they improve density without hurting readability.
4. Re-run `tools/fishing_fight_preview.gd`, rebuild `/tmp/tsuri_fight_compare.html`, and compare against the same five criteria: density, spacing, color, fish presence, and UI frame quality.
