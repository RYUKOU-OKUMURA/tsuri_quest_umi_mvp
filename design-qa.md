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
- Improved: the bottom HUD is now a dedicated fight dashboard with segmented tension/stamina gauges, a central depth card, bait card, operation hints, and a menu card.
- Improved: the right panel has denser fish/action/tackle cards, with extra fish notes and tackle details.
- Improved: the right panel now uses a dedicated generated sidebar frame asset with parchment cards, navy action/tackle bands, gold trim, and ornamental corners.
- Improved: the top status area now uses a generated ornate frame asset with icon medallions, parchment cards, a navy location/depth card, and overlaid live values.
- Improved: the bottom HUD is now scoped to the left battle area, while the right fish panel extends downward like the reference layout.
- Improved: the right fish card uses the extra vertical space for a larger portrait and three detail lines.
- Improved: the bottom HUD now uses a dedicated generated frame asset with a continuous navy top dashboard, angled gold depth module, parchment lower cards, and a navy pause card.
- Improved: tension safe markers are subtler, the current tension pointer is more prominent, and empty gauge wells come from the HUD frame instead of code-drawn boxes.
- Improved: the main fish and hit burst were scaled down, and the left depth scale was softened so the water scene reads less like a debug overlay.
- Improved: a generated transparent icon sheet now supplies the top status, HUD bait/tension/stamina, and right-panel action/tackle icons.
- Still blocked: final right-panel overlay hierarchy, small icon alignment, and final fish/effect art direction are not yet at the reference's JRPG window/card quality.

## Blocking Differences

1. Main composition: the fish and hit burst are better balanced, but the fish pose/silhouette and hit text treatment still differ from the reference's calmer, centered composition.
2. Top status: functional icons are now present, but their scale/position still needs a final pass to match the reference's smaller, cleaner sun/wind/coin treatment.
3. Right panel: action/tackle icons are now raster assets, but the lower cards still need stronger hierarchy and tighter text/icon alignment.
4. Bottom HUD: the generated frame and bait/tension/stamina icons bring the panel quality closer, but the key chips still need a final alignment/icon pass.
5. Typography/icons: the reference has denser hierarchy; the current screen still has generic key chips and some overlaid text that could be optically tuned.

## Next Required Iteration

1. Finalize right-panel overlay spacing and action/tackle content against the generated frame.
2. Polish top/HUD icon scale, key chips, and bait text alignment so the icons feel integrated rather than pasted on.
3. Run a final fish/effect art pass: compare fish silhouette/pose, hit typography, and burst placement against the reference.
4. Re-run `tools/fishing_fight_preview.gd`, rebuild `/tmp/tsuri_fight_compare.html`, and compare against the same five criteria: density, spacing, color, fish presence, and UI frame quality.
