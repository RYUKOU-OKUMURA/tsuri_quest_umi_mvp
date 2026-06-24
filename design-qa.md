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

- Added dedicated `fight_action_card_icon.png` and `fight_tackle_card_icon.png` assets for the right-panel lower cards so the large ornate shared icon sheet no longer dominates those small cards.
- Rebuilt `sidebar_frame.png` with calmer lower-card icon wells and kept the dedicated `kurodai_card_portrait.png` path for the fish card.
- Added opaque paper insets to the lower HUD bait/hint cards while keeping the menu card navy; a translucent inset attempt was rejected because it made text sink into the dark board.
- Rebuilt the lower HUD operation-hint slots to align the authored paper wells with the Godot-drawn A/B/LR key blocks, reducing the broken grid/debug-panel read.
- Shortened and re-spaced the right-panel action/tackle lower-card text so the dedicated card icons no longer fight as much with dense body copy.
- Reworked the right fish-card title row into an opaque paper plaque and regenerated `sidebar_frame.png`, so `No.028 / クロダイ / レア` no longer sits on a dark, stale-looking strip.
- Rebuilt the right-panel action/tackle card interiors with separate icon wells and text plaques, reducing the mechanical guide-rule feel in the lower cards.
- Added a showcase ambience layer over `underwater_battle_bg.png`: subtle distant fish schools, bubble columns, and light specks to increase underwater depth without covering the main kurodai.
- Regenerated `/tmp/tsuri_fight_compare.png`, `/tmp/tsuri_frame_focus_compare.png`, and `/tmp/tsuri_fish_hit_focus.png`.

## Findings

- [P2] Right panel is structurally better but still below reference card quality.
  Location: `assets/showcase/underwater/sidebar_frame.png`, `src/ui/components/fight_sidebar.gd`, `src/ui/fishing_screen.gd`.
  Evidence: the panel is now wider, the fish card uses a dedicated paper-backed kurodai portrait instead of the runtime swimming sheet, and the previous dark portrait rectangle regression is gone. The fish-card title row now sits on an opaque paper plaque, so `No.028 / クロダイ / レア` reads clearly like the reference instead of sinking into a dark band. The action/tackle cards now use dedicated paper-backed card icons, separate icon wells, and calmer text plaques, so the small lower cards read less like compressed cutouts from the ornate shared icon sheet. The lower-card copy has been shortened and spaced more deliberately, but the cards still feel more mechanically framed than the reference, especially around small-text optical quality and the remaining tight vertical crop.
  Impact: the right panel is more readable and more deliberately framed, but it still does not fully sell the premium JRPG card quality.
  Fix: keep the dedicated fish-card portrait, wider panel, paper title plaque, card-specific lower icons, separated lower-card wells, and shorter lower-card copy. Next, move to the next largest visible gap unless the right panel regresses: background density/final UI frame art.

- [P2] HUD top row is closer, but still below the reference's authored console quality.
  Location: `assets/showcase/underwater/fight_hud_frame.png`, `src/ui/components/fight_hud.gd`.
  Evidence: the upper board is now darker, the central depth module is less bright, the title/icon scale is more compact, and the row icons are visually quieter after opacity modulation. The bar-well grid density is lower, the runtime meter uses fewer segments, and the lower bait/hint cards now have opaque paper insets. The operation-hint key row now uses three aligned paper slots with compact A/B/LR key blocks instead of labels sinking into the dark board. The reference still has more deliberate black-panel spacing and a more bespoke meter construction.
  Impact: the HUD is closer to a single premium operation board, and the most obvious broken-grid read in the lower hint row is reduced. It still does not fully reach the reference's authored console quality.
  Fix: keep the darker frame, new label padding, quieter icon opacity, reduced segment grid, navy menu card, and aligned operation-hint slots. Next, revisit the meter art and lower HUD frame texture only if the final full-screen comparison still reads too mechanical.

- [P3] Main fish is now close, with minor runtime-placement polish remaining.
  Location: `assets/showcase/underwater/kurodai_showcase_sheet.png`, `src/ui/components/underwater_view.gd`.
  Evidence: the fish source now preserves the reference-like black seabream outline, scale texture, dorsal spines, eye, and gray banding. The implementation fish is also larger again after the panel-width change and no longer reads as a generic generated cutout. The remaining mismatch is mainly placement polish: the bait sits slightly higher/right than the reference and the runtime fish still lives on a brighter, denser generated background.
  Impact: the fish is no longer a blocking quality mismatch; it now sells the screen's main subject.
  Fix: keep this asset as the current kurodai baseline, then tune lure placement only after the hit badge and HUD frame settle.

- [P2] Background depth is improved, but still not a final art pass.
  Location: `assets/showcase/underwater/underwater_battle_bg.png`, `src/ui/components/underwater_view.gd`.
  Evidence: the rendered scene now adds subtle bubble columns, far-fish schools, and light specks over the existing background PNG, so the water column has more motion and density in the same areas the reference uses bubbles and distant fish. The overlay stays behind the line/fish/hit treatment and does not cover the kurodai. The base background still has a cleaner, more generated look than the reference's richer hand-authored seabed and far-rock detail.
  Impact: the screen feels less empty in full view, especially around the left/right edges and upper water column, but a true reference-quality background still requires a stronger final raster art pass.
  Fix: keep the ambience layer as the runtime depth pass. Next, improve the actual `underwater_battle_bg.png` art or add authored foreground bubble/caustic sprites if the background still reads too smooth.

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

- None blocking. The next highest-value pass is still final background art or final UI frame material quality; the ambience layer helps density but does not replace authored background art.

## Implementation Checklist

1. Keep comparing `/tmp/tsuri_frame_focus_compare.png` against the reference after any HUD/sidebar frame change.
2. Improve `underwater_battle_bg.png` itself or add authored foreground bubble/caustic sprites; the current ambience layer is only a runtime density pass.
3. Keep the dedicated fish-card portrait; do not return to drawing the swimming sprite sheet directly in the sidebar.
4. Re-run `/tmp/tsuri_fight_compare.png`, `/tmp/tsuri_frame_focus_compare.png`, and `/tmp/tsuri_fish_hit_focus.png` after each pass.

## Follow-up Polish

- Replace top status and right-panel small icons with simpler reference-like icons if they still feel noisy after the lower-card pass.
- Recheck the hit splash after the final HUD/font pass, but do not keep iterating it unless the comparison regresses.
- Add small sparkle/bubble particles only after the main frame and typography mismatches are solved.
- Add subtle tail/body variants to the kurodai sheet later if animation quality becomes noticeable; keep the current static extracted art for visual fidelity.
