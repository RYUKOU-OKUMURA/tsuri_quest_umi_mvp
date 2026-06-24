# Underwater Fight Design QA

final result: blocked

Date: 2026-06-25

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
- Tuned `FightStatusBar` typography and icon layout: larger top icons, stronger AM/time/weather text, a single strong money value instead of a tiny stacked money label, and a larger centered location-depth value.
- Tuned right-panel lower card runtime layout: larger action/tackle text, reduced lower-card icon footprint, condensed the tackle card into two readable lines, and adjusted body baselines so the action and tackle notes read less like shrunken debug copy.
- Added `tools/source_assets/underwater_battle_bg_source.png` plus `tools/enhance_underwater_battle_bg.py` so `underwater_battle_bg.png` is now regenerated deterministically from a preserved source asset. The first pass adds a subtle paint glaze, darker edge/depth enclosure, far-depth haze, extra seabed contour lines, edge plants, and small foreground rocks directly into the base background while keeping the main fish zone clear.
- Set `UnderwaterView.texture_filter` to linear so the showcase background/fish/hit textures downscale more like the smoother reference illustration instead of inheriting the project's global nearest-neighbor UI texture setting.
- Added a half-resolution bilateral smoothing stage to `enhance_underwater_battle_bg.py`, blending it back into the source before depth/detail layers so the base background keeps rock/plant information while reducing the hard pixel-art surface.
- Added `tools/build_reference_underwater_background.py`, which builds `underwater_battle_bg.png` from the reference mockup's water window instead of continuing to polish the generated background as the primary source. The current pass uses the full authored water window rather than only the upper-left crop, masks the main fish, hit burst, line, and lure zones, fills those runtime-subject areas with a clean blue water field, expands the crop to the existing 1672x941 texture slot, and harmonizes the result for use under the runtime fish/HUD.
- Reduced `underwater_color_grade.png`, `underwater_seabed_detail.png`, and `underwater_foreground_ambience.png` draw opacity in `UnderwaterView` so the old generated-background helper layers no longer create a gray film over the reference-derived base.
- Replaced the earlier procedural lower/right detail and right-reef patch approach with the full-window extraction path. This preserves the reference's actual left rock pile, right reef, seabed caustics, bubble rhythm, and distant fish, while broad masks prevent the original fish/hit/line/lure from doubling behind the runtime art.
- Added a reference-derived center texture pass inside `tools/build_reference_underwater_background.py`. The pass reuses side seabed/water pixels and subtle caustic strokes inside the masked fish/hit zone, reducing the smooth circular clean-water patch without reintroducing the original reference fish, hit text, lure, or line.
- Reduced `hit_burst.png` ray/glint density in `tools/process_underwater_fish_assets.py`, so the hit badge throws fewer bright blue-white lines across the center water and competes less with the live `ヒット！` text.
- Rebuilt `sidebar_frame.png` with a shallower navy title band and taller paper body wells for the right-panel action/tackle cards. `FightSidebar` now aligns the action title/message and tackle text to those larger paper wells, with slightly smaller card icons and less assertive internal guide lines.
- Added sparse central midwater bubble columns to `underwater_foreground_ambience.png` via `tools/generate_underwater_foreground_assets.py`. A side QA check found no P2+ regressions; the bubbles do not interfere with the fish, line, or `ヒット！` text, and they slightly reduce the empty central-water read.
- Enlarged and lowered the lower-HUD operation-hint key caps and labels so the runtime `A/B/LR` controls sit more deliberately inside the baked paper slots instead of reading like small floating text.
- Strengthened the reference-derived center replacement inside `tools/build_reference_underwater_background.py` with a softer subject mask, a more visible midwater texture pass, stronger seabed caustic strokes, and small low-contrast bubbles. The updated `/tmp/tsuri_fish_hit_focus.png` restores some water/seabed density behind the runtime fish without covering the fish, line, lure, or `ヒット！` text.
- Removed the extra runtime body-panel redraw from the right-panel action/tackle cards when `sidebar_frame.png` is active. The lower cards now rely on the baked paper wells, with smaller action message text, cleaner vertical spacing, and shorter tackle copy so the text reads more like card printing than an overlaid debug panel.
- Regenerated `/tmp/tsuri_fight_compare.png`, `/tmp/tsuri_frame_focus_compare.png`, and `/tmp/tsuri_fish_hit_focus.png`.

## Findings

- [P2] Right panel is structurally better but still below reference card quality.
  Location: `assets/showcase/underwater/sidebar_frame.png`, `src/ui/components/fight_sidebar.gd`, `src/ui/fishing_screen.gd`.
  Evidence: the panel is now wider, starts at the top of the screen beside the status cards, uses a dedicated paper-backed kurodai portrait instead of the runtime swimming sheet, and the previous dark portrait rectangle regression is gone. The fish-card title row now sits on an opaque paper plaque, so `No.028 / クロダイ / レア` reads clearly like the reference instead of sinking into a dark band. Moving the status bar into the left column gives the right panel more vertical room, and the 620x330 `kurodai_card_portrait.png` ratio now fits the runtime fish window better than the previous 720x330 source, making the fish read larger and less like a shrunken document thumbnail. The latest lower-card pass makes the navy title bands shallower, enlarges the paper wells, reduces the icon-well footprint, softens internal guide lines, and realigns the action/tackle text onto the larger paper areas. The newest runtime pass stops drawing an extra body panel over the baked action/tackle wells, shrinks the action message just enough to avoid the lower rule, and shortens the tackle second line so it no longer collides with the icon. In `/tmp/tsuri_frame_focus_compare.png`, the lower cards read less cramped and less like a tiny debug table. They still feel more mechanically framed than the reference, especially around small-text optical quality and the authored paper-card finish.
  Impact: the right panel now matches the reference's top-level composition better, and the lower cards have more readable paper-card presence. It still does not fully sell the premium JRPG card quality.
  Fix: keep the larger dedicated fish-card portrait, wider panel, paper title plaque, card-specific lower icons, taller lower-card paper wells, shorter lower-card copy, stronger lower-card runtime text, and the two-line tackle copy. Next, move to background density/final UI frame art unless the right panel regresses.

- [P2] HUD top row is closer, but still below the reference's authored console quality.
  Location: `assets/showcase/underwater/fight_hud_frame.png`, `src/ui/components/fight_hud.gd`.
  Evidence: the upper board is now darker, the central depth module is less bright, the title/icon scale is more compact, and the row icons are visually quieter after opacity modulation. The bar-well grid density is lower, the runtime meter uses fewer segments, inactive segments remain faintly visible, and filled segments now have small highlight/shadow treatment instead of flat rectangles. The lower bait/hint/menu area now has stronger baked paper title bands, recessed paper slots, darker menu rows, and runtime A/B/LR key caps aligned to those slots instead of floating inside a generic grid. The latest operation-hint pass makes the key caps and labels larger and lowers them within the paper wells, so `/tmp/tsuri_frame_focus_compare.png` reads a bit less like undersized overlay text. The reference still has more deliberate black-panel spacing, larger authored operation-card proportions, and a more bespoke meter construction.
  Impact: the HUD reads more like an authored operation board and less like a debug grid. It still does not fully reach the reference's premium console quality.
  Fix: keep the darker frame, label padding, quieter icon opacity, reduced segment grid, visible inactive segments, navy menu card, recessed lower paper slots, and aligned operation-hint caps. The next HUD pass should focus on final proportions/typography only after background and top-icon gaps are checked in full view.

- [P2] Top status bar has stronger material quality, but still trails the reference's compact icon grammar.
  Location: `assets/showcase/underwater/top_status_frame.png`, `assets/showcase/underwater/top_status_icon_sheet.png`, `src/ui/components/fight_status_bar.gd`.
  Evidence: the top status frame now has stronger paper-card inner borders, corner brackets, subtler icon wells, and a more authored navy location card. The old common icon sheet made the first three top cards read as small noisy ornaments; the new top-specific icon sheet gives the clock, sun, wind, and coin clearer silhouettes closer to the reference, and the wind glyph is now placed inline before `風 弱`. The status bar now lives only over the left fight column, and the weather/money/location slot ratios are closer to the reference instead of stretching the blue location card across the full screen. The latest typography pass increases the top icons, time, weather, money value, and location-depth value; the money card now reads as a strong coin-plus-amount card instead of a small label/value stack. The reference still has slightly more tailored glyph metrics and tighter icon/text alignment.
  Impact: the top row now reads more like the reference's authored status strip and no longer pushes the right panel down. It still does not fully match the compact, high-contrast reference top bar.
  Fix: keep `top_status_icon_sheet.png`, left-column placement, the new card ratios, and the stronger money/time typography. Next top-row work should only happen if a later background/right-panel pass makes these baselines feel off again.

- [P3] Main fish is now close, with minor runtime-placement polish remaining.
  Location: `assets/showcase/underwater/kurodai_showcase_sheet.png`, `src/ui/components/underwater_view.gd`.
  Evidence: the fish source now preserves the reference-like black seabream outline, scale texture, dorsal spines, eye, and gray banding. The implementation fish is also larger again after the panel-width change and no longer reads as a generic generated cutout. The remaining mismatch is mainly placement polish: the bait sits slightly higher/right than the reference and the runtime fish still lives on a brighter, denser generated background.
  Impact: the fish is no longer a blocking quality mismatch; it now sells the screen's main subject.
  Fix: keep this asset as the current kurodai baseline, then tune lure placement only after the hit badge and HUD frame settle.

- [P2] Background is much closer to the reference, but the masked center still needs final art cleanup.
  Location: `assets/showcase/underwater/underwater_battle_bg.png`, `tools/build_reference_underwater_background.py`, `assets/showcase/underwater/underwater_color_grade.png`, `assets/showcase/underwater/underwater_seabed_detail.png`, `assets/showcase/underwater/underwater_foreground_ambience.png`, `src/ui/components/underwater_view.gd`.
  Evidence: the primary background is no longer the generated canyon scene. `tools/build_reference_underwater_background.py` now extracts the full authored water window from the reference mockup, preserving the real left rock pile, right reef, seabed caustics, bubbles, distant fish, surface light, and darker blue side depth. The main fish, hit burst, line, and lure zones are broadly masked so the runtime kurodai, hit treatment, and line can sit on top without obvious duplicates. The latest retained background pass softens the subject mask, strengthens the reference-derived midwater/seabed texture, adds more visible low-contrast caustic strokes, and keeps tiny bubbles in the central replacement zone. Together with the sparse central `underwater_foreground_ambience.png` bubbles, `/tmp/tsuri_fight_compare.png` and `/tmp/tsuri_fish_hit_focus.png` read less like a flat blue patch behind the runtime fish. The fish, line, lure, and `ヒット！` text remain readable. The remaining mismatch is that the center is still quieter and less hand-authored than the reference's dense middle seabed/water painting, and `underwater_battle_bg.png` itself still shows a broad replacement zone when inspected outside the composed runtime screen.
  Impact: this is a larger quality move toward the target image than the previous small patch passes, and the retained central bubbles are a safe density improvement. The water panel now carries the reference's real edge density, bubble rhythm, and seabed art language, and the main fish sits in a richer environment. It is still not a finished background because the center replacement is improved but not fully painted to reference density.
  Fix: keep the full-window extraction, stronger center texture pass, and sparse central ambience bubbles as the deterministic background build path, and keep UnderwaterView linear filtering/lower overlay opacity. Next background work should either author a higher-quality center replacement patch or use a final raster paintover for the masked fish/hit area; do not treat the current center fill as finished art.

- [P3] Hit treatment is close, with only final context polish remaining.
  Location: `assets/showcase/underwater/hit_burst.png`, `src/ui/components/underwater_view.gd`.
  Evidence: the badge now reads as a darker blue splash with fewer white rays/flecks behind the yellow/orange live text, and its lower edge sits closer to the top of the operation board. A rejected midwater-detail experiment made the center read like pasted residue, so that direction was not kept; the latest `/tmp/tsuri_fish_hit_focus.png` keeps the stable background and only quiets the hit badge's internal line noise. It still differs slightly from the reference starburst silhouette and text optical weight.
  Impact: the hit moment is less noisy and competes less with the fish/background. It is no longer a major art-style mismatch, but it is still not a perfect match to the reference badge.
  Fix: keep the quieter ray/glint density. Revisit only after the final background center paintover and HUD/font pass, because the badge's ideal strength depends on the final water density underneath it.

- [P2] Typography is improved but still not at the reference's custom UI quality.
  Location: all fight UI overlay text.
  Evidence: the fight UI now uses `MPLUS1p-Bold.ttf` for the main overlay text, the top-status numbers are stronger, and the location/depth card now matches the reference's iconless centered layout. The parchment-card icons are smaller and lower opacity, but still more ornate than the simpler reference glyphs. The reference still has more tailored optical weights plus tighter small-text rendering.
  Impact: the screen now reads more like a game UI, but typography still does not fully sell the premium mockup quality.
  Fix: keep the bold/regular split, then tune per-component font sizes and replace/simplify the top-status icon sheet if those icons still read too noisy in the final full-screen pass.

## Open Questions

- None blocking. The next highest-value pass remains final background art cleanup. The full-window reference extraction plus center texture pass is the right base, but the central masked zone still needs a more authored water/seabed replacement to reach the reference's hand-painted density.

## Implementation Checklist

1. Keep comparing `/tmp/tsuri_frame_focus_compare.png` against the reference after any HUD/sidebar frame change.
2. Improve `underwater_battle_bg.png` itself from `tools/build_reference_underwater_background.py`; `underwater_foreground_ambience.png` now covers the foreground bubble/caustic density slot.
3. Keep the dedicated fish-card portrait; do not return to drawing the swimming sprite sheet directly in the sidebar.
4. Re-run `/tmp/tsuri_fight_compare.png`, `/tmp/tsuri_frame_focus_compare.png`, and `/tmp/tsuri_fish_hit_focus.png` after each pass.

## Follow-up Polish

- Replace right-panel small icons with simpler reference-like icons only if they still feel noisy after the background/final-frame pass.
- Recheck lower HUD text sizes after any layout/proportion change; the current paper slots and key-cap positions are intentionally paired.
- Recheck the hit splash after the final HUD/font pass, but do not keep iterating it unless the comparison regresses.
- Add small sparkle/bubble particles only after the main frame and typography mismatches are solved.
- Add subtle tail/body variants to the kurodai sheet later if animation quality becomes noticeable; keep the current static extracted art for visual fidelity.
