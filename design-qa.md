# Underwater Fight Design QA

final result: blocked

Date: 2026-06-24

Source visual truth: `reference/02_underwater_fight_mockup.png`
Implementation screenshot: `/tmp/tsuri_fishing_fight.png`
Full-view comparison evidence: `/tmp/tsuri_fight_compare.png`
Focused frame comparison evidence: `/tmp/tsuri_frame_focus_compare.png`
Focused fish/hit comparison evidence: `/tmp/tsuri_fish_hit_focus.png`
Side-by-side page: `/tmp/tsuri_fight_compare.html`
Viewport: 1280x720
State: underwater fight, kurodai hit moment, depth 18.6m, action `突進`

## Patches Made Since Previous QA

- Widened the right fight panel, added a dedicated `kurodai_card_portrait.png` for the fish card, and stopped using the swimming sprite sheet directly for the sidebar portrait so the card no longer exposes a dark rectangular sprite background.
- Rebuilt `sidebar_frame.png` with stronger paper-card structure, a portrait mat, lighter body rules, and lower-card icon wells.
- Reduced HUD meter grid noise by lowering the background well dividers, using fewer runtime segments, and muting segment highlight strokes/colors.
- Increased the main underwater kurodai display ratio so the fish regains screen presence after the wider right panel.
- Regenerated `/tmp/tsuri_fight_compare.png`, `/tmp/tsuri_frame_focus_compare.png`, and `/tmp/tsuri_fish_hit_focus.png`.

## Findings

- [P2] Right panel is structurally better but still below reference card quality.
  Location: `assets/showcase/underwater/sidebar_frame.png`, `src/ui/components/fight_sidebar.gd`, `src/ui/fishing_screen.gd`.
  Evidence: the panel is now wider, the fish card uses a dedicated paper-backed kurodai portrait instead of the runtime swimming sheet, and the previous dark portrait rectangle regression is gone. The fish card has clearer internal paper structure, and the action/tackle cards have lighter guide rules plus stronger action title text. The lower cards still feel more cramped and mechanically framed than the reference, especially around the action/tackle icons and small body text.
  Impact: the right panel is more readable and more deliberately framed, but it still does not fully sell the premium JRPG card quality.
  Fix: keep the dedicated fish-card portrait and wider panel. Next, simplify or replace the right-panel lower-card icon treatments and tune body text so the action/tackle cards read as authored cards, not compressed info boxes.

- [P2] HUD top row is closer, but still below the reference's authored console quality.
  Location: `assets/showcase/underwater/fight_hud_frame.png`, `src/ui/components/fight_hud.gd`.
  Evidence: the upper board is now darker, the central depth module is less bright, the title/icon scale is more compact, and the row icons are visually quieter after opacity modulation. The latest pass also reduced the bar-well grid density, dropped the runtime meter to fewer segments, and softened segment strokes. The reference still has more deliberate black-panel spacing and a more bespoke meter construction.
  Impact: the HUD is closer to a single premium operation board, but it still needs final spacing and icon simplification before it can pass.
  Fix: keep the darker frame, new label padding, quieter icon opacity, and reduced segment grid. Next, make the bottom control cards feel less flat and revisit the meter art only if the remaining segmentation still reads debug-like.

- [P3] Main fish is now close, with minor runtime-placement polish remaining.
  Location: `assets/showcase/underwater/kurodai_showcase_sheet.png`, `src/ui/components/underwater_view.gd`.
  Evidence: the fish source now preserves the reference-like black seabream outline, scale texture, dorsal spines, eye, and gray banding. The implementation fish is also larger again after the panel-width change and no longer reads as a generic generated cutout. The remaining mismatch is mainly placement polish: the bait sits slightly higher/right than the reference and the runtime fish still lives on a brighter, denser generated background.
  Impact: the fish is no longer a blocking quality mismatch; it now sells the screen's main subject.
  Fix: keep this asset as the current kurodai baseline, then tune lure placement only after the hit badge and HUD frame settle.

- [P3] Hit treatment is close, with only final context polish remaining.
  Location: `assets/showcase/underwater/hit_burst.png`, `src/ui/components/underwater_view.gd`.
  Evidence: the badge now reads as a darker blue splash with reduced white rays/flecks behind the yellow/orange live text, and its lower edge sits closer to the top of the operation board. It still differs slightly from the reference starburst silhouette and text optical weight.
  Impact: the hit moment is no longer a major art-style mismatch; the remaining work is small visual context tuning.
  Fix: keep the current darker badge, then revisit only if the final HUD/font pass makes the overlap or brightness feel off again.

- [P2] Typography is improved but still not at the reference's custom UI quality.
  Location: all fight UI overlay text.
  Evidence: the fight UI now uses `MPLUS1p-Bold.ttf` for the main overlay text, the top-status numbers are stronger, and the location/depth card now matches the reference's iconless centered layout. The parchment-card icons are smaller and lower opacity, but still more ornate than the simpler reference glyphs. The reference still has more tailored optical weights plus tighter small-text rendering.
  Impact: the screen now reads more like a game UI, but typography still does not fully sell the premium mockup quality.
  Fix: keep the bold/regular split, then tune per-component font sizes and replace/simplify the top-status icon sheet if those icons still read too noisy in the final full-screen pass.

## Open Questions

- None blocking. The next highest-value pass is right-panel lower-card icon/text treatment and bottom HUD card depth.

## Implementation Checklist

1. Improve right-panel action/tackle icon treatment so the lower cards stop reading as cramped generated boxes.
2. Add depth and clearer card hierarchy to the lower HUD bait/hint/menu row.
3. Keep the dedicated fish-card portrait; do not return to drawing the swimming sprite sheet directly in the sidebar.
4. Re-run `/tmp/tsuri_fight_compare.png`, `/tmp/tsuri_frame_focus_compare.png`, and `/tmp/tsuri_fish_hit_focus.png` after each pass.

## Follow-up Polish

- Replace top status and right-panel small icons with simpler reference-like icons if they still feel noisy after the lower-card pass.
- Recheck the hit splash after the final HUD/font pass, but do not keep iterating it unless the comparison regresses.
- Add small sparkle/bubble particles only after the main frame and typography mismatches are solved.
- Add subtle tail/body variants to the kurodai sheet later if animation quality becomes noticeable; keep the current static extracted art for visual fidelity.
