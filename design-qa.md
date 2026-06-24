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
- Still blocked: final HUD art polish, right-panel overlay polish, and final fish/effect composition are not yet at the reference's JRPG window/card quality.

## Blocking Differences

1. Main composition: the fish and background are closer, but the hit effect, fish scale, and fish placement still need a final art-direction pass against the reference.
2. Top status: the generated frame now has enough ornamentation, but its icon medallions are more decorative than the reference's clearer functional icons.
3. Right panel: the generated frame is much closer, but action/tackle overlays still need cleaner icon polish and less cramped text at the lower edge.
4. Bottom HUD: the layout now matches the left-only reference structure, but the final panel art, angled separators, key chips, and typography still need polish.
5. Typography/icons: the reference has icon-led labels and denser hierarchy; the current screen still has several code-drawn glyphs and generic key chips.

## Next Required Iteration

1. Polish the bottom HUD into the reference-like continuous dashboard: angled separators, subtler tension markers, stronger bevels, and compact key chips.
2. Finalize right-panel overlay spacing, icons, and action/tackle content against the generated frame.
3. Run a final fish/effect composition pass: reduce debug-like depth overlays, tune hit burst placement, and compare fish silhouette/scale against the reference.
4. Re-run `tools/fishing_fight_preview.gd`, rebuild `/tmp/tsuri_fight_compare.html`, and compare against the same five criteria: density, spacing, color, fish presence, and UI frame quality.
