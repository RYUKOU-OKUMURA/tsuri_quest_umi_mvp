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
- Added `underwater_foreground_ambience.png`, a transparent foreground ambience asset with bubble columns, caustic strokes, and distant fish silhouettes. `UnderwaterView` now uses it over `underwater_battle_bg.png` and keeps only light specks as a runtime shimmer.
- Rebuilt `top_status_frame.png` with stronger paper-card inner frames, corner brackets, a more authored navy location card, and quieter top-status icon rendering.
- Refined HUD segment gauges with visible inactive segments, subtle upper highlights, bottom shadows, and a stronger tension marker shadow so the meters feel more embedded in the authored console.
- Rebuilt the lower HUD frame with stronger paper title bands, recessed bait/hint/menu wells, and darker menu row slots. Realigned the runtime bait text and A/B/LR key caps to the baked paper slots.
- Added `top_status_icon_sheet.png` as a top-bar-specific icon sheet extracted and cleaned from the reference. `FightStatusBar` now uses those larger clock/weather/wind/coin icons and draws the wind icon as its own inline glyph instead of a tiny overlay on the sun.
- Moved `FightStatusBar` from the full-width root row into the left fight column so the right sidebar header starts at the same top height as the status cards, matching the reference's top-level composition more closely.
- Rebuilt `top_status_frame.png` and `FightStatusBar` slot ratios so the weather/money cards are wider and the location card is tighter instead of one oversized rightmost blue card.
- Regenerated `kurodai_card_portrait.png` with the fish occupying more of the paper portrait window, reducing empty parchment around the sidebar fish card.
- Added `underwater_color_grade.png`, a transparent background color-grade/depth overlay. `UnderwaterView` now draws it over `underwater_battle_bg.png` before ambience/fish so the clean generated background gets darker edges, stronger seabed depth, and subtler surface light structure.
- Added `underwater_seabed_detail.png`, a transparent seabed/edge-density layer with extra rock silhouettes, seaweed/coral clusters, and low caustic contour lines. `UnderwaterView` draws it after the color grade and before bubble/fish ambience.
- Rebuilt `kurodai_card_portrait.png` with a 620x330 card-window ratio instead of the previous 720x330 source ratio, so the runtime sidebar slot no longer scales the portrait down like a wide document thumbnail.
- Regenerated `/tmp/tsuri_fight_compare.png`, `/tmp/tsuri_frame_focus_compare.png`, and `/tmp/tsuri_fish_hit_focus.png`.

## Findings

- [P2] Right panel is structurally better but still below reference card quality.
  Location: `assets/showcase/underwater/sidebar_frame.png`, `src/ui/components/fight_sidebar.gd`, `src/ui/fishing_screen.gd`.
  Evidence: the panel is now wider, starts at the top of the screen beside the status cards, uses a dedicated paper-backed kurodai portrait instead of the runtime swimming sheet, and the previous dark portrait rectangle regression is gone. The fish-card title row now sits on an opaque paper plaque, so `No.028 / クロダイ / レア` reads clearly like the reference instead of sinking into a dark band. Moving the status bar into the left column gives the right panel more vertical room, and the 620x330 `kurodai_card_portrait.png` ratio now fits the runtime fish window better than the previous 720x330 source, making the fish read larger and less like a shrunken document thumbnail. The lower-card copy has been shortened and spaced more deliberately, but the cards still feel more mechanically framed than the reference, especially around small-text optical quality.
  Impact: the right panel now matches the reference's top-level composition better, and the fish card has stronger subject presence. It still does not fully sell the premium JRPG card quality.
  Fix: keep the larger dedicated fish-card portrait, wider panel, paper title plaque, card-specific lower icons, separated lower-card wells, and shorter lower-card copy. Next, move to the next largest visible gap unless the right panel regresses: background density/final UI frame art.

- [P2] HUD top row is closer, but still below the reference's authored console quality.
  Location: `assets/showcase/underwater/fight_hud_frame.png`, `src/ui/components/fight_hud.gd`.
  Evidence: the upper board is now darker, the central depth module is less bright, the title/icon scale is more compact, and the row icons are visually quieter after opacity modulation. The bar-well grid density is lower, the runtime meter uses fewer segments, inactive segments remain faintly visible, and filled segments now have small highlight/shadow treatment instead of flat rectangles. The lower bait/hint/menu area now has stronger baked paper title bands, recessed paper slots, darker menu rows, and runtime A/B/LR key caps aligned to those slots instead of floating inside a generic grid. The reference still has more deliberate black-panel spacing, larger authored operation-card proportions, and a more bespoke meter construction.
  Impact: the HUD reads more like an authored operation board and less like a debug grid. It still does not fully reach the reference's premium console quality.
  Fix: keep the darker frame, label padding, quieter icon opacity, reduced segment grid, visible inactive segments, navy menu card, recessed lower paper slots, and aligned operation-hint caps. The next HUD pass should focus on final proportions/typography only after background and top-icon gaps are checked in full view.

- [P2] Top status bar has stronger material quality, but still trails the reference's compact icon grammar.
  Location: `assets/showcase/underwater/top_status_frame.png`, `assets/showcase/underwater/top_status_icon_sheet.png`, `src/ui/components/fight_status_bar.gd`.
  Evidence: the top status frame now has stronger paper-card inner borders, corner brackets, subtler icon wells, and a more authored navy location card. The old common icon sheet made the first three top cards read as small noisy ornaments; the new top-specific icon sheet gives the clock, sun, wind, and coin clearer silhouettes closer to the reference, and the wind glyph is now placed inline before `風 弱`. The status bar now lives only over the left fight column, and the weather/money/location slot ratios are closer to the reference instead of stretching the blue location card across the full screen. The reference still has stronger number typography and slightly cleaner icon/text alignment.
  Impact: the top row now reads more like the reference's authored status strip and no longer pushes the right panel down. It still does not fully match the compact, high-contrast reference top bar.
  Fix: keep `top_status_icon_sheet.png`, left-column placement, and the new card ratios. Next top-row work should focus on typography/baselines only after the background and right-card art gaps are checked.

- [P3] Main fish is now close, with minor runtime-placement polish remaining.
  Location: `assets/showcase/underwater/kurodai_showcase_sheet.png`, `src/ui/components/underwater_view.gd`.
  Evidence: the fish source now preserves the reference-like black seabream outline, scale texture, dorsal spines, eye, and gray banding. The implementation fish is also larger again after the panel-width change and no longer reads as a generic generated cutout. The remaining mismatch is mainly placement polish: the bait sits slightly higher/right than the reference and the runtime fish still lives on a brighter, denser generated background.
  Impact: the fish is no longer a blocking quality mismatch; it now sells the screen's main subject.
  Fix: keep this asset as the current kurodai baseline, then tune lure placement only after the hit badge and HUD frame settle.

- [P2] Background depth is improved, but still not a final art pass.
  Location: `assets/showcase/underwater/underwater_battle_bg.png`, `assets/showcase/underwater/underwater_color_grade.png`, `assets/showcase/underwater/underwater_seabed_detail.png`, `assets/showcase/underwater/underwater_foreground_ambience.png`, `src/ui/components/underwater_view.gd`.
  Evidence: the rendered scene now composites transparent color-grade, seabed-detail, and foreground ambience assets over the existing background PNG. `underwater_color_grade.png` adds darker edges, seabed depth, and subtle surface-light structure. `underwater_seabed_detail.png` adds extra rock silhouettes, seaweed/coral clusters, and low caustic contour lines around the lower and side zones while keeping the main fish area clear. The ambience asset adds authored bubble columns, caustic strokes, far-fish silhouettes, and sparse particles in the same visual zones the reference uses for density. These layers stay behind the line/fish/hit treatment and do not cover the kurodai. The base background still has a cleaner, more generated look than the reference's richer hand-authored seabed and far-rock detail.
  Impact: the screen is less uniformly bright, the lower/side areas feel denser, and the fish/HUD sit in the scene more naturally. A true reference-quality background still requires a stronger final raster art pass.
  Fix: keep `underwater_color_grade.png` as the depth/lighting grade slot, `underwater_seabed_detail.png` as the edge/seabed density slot, and `underwater_foreground_ambience.png` as the bubble/far-fish density slot. Next, improve the actual `underwater_battle_bg.png` art if the background still reads too smooth.

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

- None blocking. The next highest-value pass is now final background art or top-status icon simplification; the HUD lower-frame pass reduced the grid/debug read but does not replace final art direction.

## Implementation Checklist

1. Keep comparing `/tmp/tsuri_frame_focus_compare.png` against the reference after any HUD/sidebar frame change.
2. Improve `underwater_battle_bg.png` itself; `underwater_foreground_ambience.png` now covers the foreground bubble/caustic density slot.
3. Keep the dedicated fish-card portrait; do not return to drawing the swimming sprite sheet directly in the sidebar.
4. Re-run `/tmp/tsuri_fight_compare.png`, `/tmp/tsuri_frame_focus_compare.png`, and `/tmp/tsuri_fish_hit_focus.png` after each pass.

## Follow-up Polish

- Replace top status and right-panel small icons with simpler reference-like icons if they still feel noisy after the lower-card pass.
- Recheck lower HUD text sizes after any layout/proportion change; the current paper slots and key-cap positions are intentionally paired.
- Recheck the hit splash after the final HUD/font pass, but do not keep iterating it unless the comparison regresses.
- Add small sparkle/bubble particles only after the main frame and typography mismatches are solved.
- Add subtle tail/body variants to the kurodai sheet later if animation quality becomes noticeable; keep the current static extracted art for visual fidelity.
