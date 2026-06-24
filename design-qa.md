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

- Reduced HUD upper-row icon sizes again in `FightHud` so the symbols sit closer to the reference's small status glyphs.
- Reduced top-status parchment-card icon size and opacity in `FightStatusBar`.
- Regenerated `/tmp/tsuri_fight_compare.png`, `/tmp/tsuri_frame_focus_compare.png`, and `/tmp/tsuri_fish_hit_focus.png`.

## Findings

- [P2] Right panel is structurally better but still below reference card quality.
  Location: `assets/showcase/underwater/sidebar_frame.png`, `src/ui/components/fight_sidebar.gd`, `src/ui/fishing_screen.gd`.
  Evidence: the fish card now has quieter reference-like ruled lines, and the action/tackle cards have clearer title separators plus body brackets. The lower-card text sits better inside the parchment bodies. The panel still has a more procedural border rhythm and less bespoke typography than the reference.
  Impact: the right panel is more readable and more deliberately framed, but it still does not fully sell the premium JRPG card quality.
  Fix: keep the new internal structure, then tune title/body optical sizes and replace any remaining generated-looking linework only if it still reads too mechanical in the next full-screen pass.

- [P2] HUD top row is closer, but still below the reference's authored console quality.
  Location: `assets/showcase/underwater/fight_hud_frame.png`, `src/ui/components/fight_hud.gd`.
  Evidence: the upper board is now darker, the central depth module is less bright, and the title/icon scale is more compact. The latest icon-size pass reduces the ornate icon pull further. The reference still has cleaner gauge-label alignment, simpler iconography, and more deliberate black-panel spacing around the bars.
  Impact: the HUD is closer to a single premium operation board, but it still needs final spacing and icon simplification before it can pass.
  Fix: keep the darker frame baseline, then tune gauge-label padding. Replace the icon sheet only if the remaining ornamentation still reads noisy after spacing is locked.

- [P3] Main fish is now close, with minor runtime-placement polish remaining.
  Location: `assets/showcase/underwater/kurodai_showcase_sheet.png`, `src/ui/components/underwater_view.gd`.
  Evidence: the fish source now preserves the reference-like black seabream outline, scale texture, dorsal spines, eye, and gray banding. The implementation fish is also closer in scale and no longer reads as a generic generated cutout. The remaining mismatch is mainly placement polish: the bait sits slightly higher/right than the reference and the runtime fish still lives on a brighter, denser generated background.
  Impact: the fish is no longer a blocking quality mismatch; it now sells the screen's main subject.
  Fix: keep this asset as the current kurodai baseline, then tune lure placement only after the hit badge and HUD frame settle.

- [P3] Hit treatment is close, with only final context polish remaining.
  Location: `assets/showcase/underwater/hit_burst.png`, `src/ui/components/underwater_view.gd`.
  Evidence: the badge now reads as a darker blue splash with reduced white rays/flecks behind the yellow/orange live text, and its lower edge sits closer to the top of the operation board. It still differs slightly from the reference starburst silhouette and text optical weight.
  Impact: the hit moment is no longer a major art-style mismatch; the remaining work is small visual context tuning.
  Fix: keep the current darker badge, then revisit only if the final HUD/font pass makes the overlap or brightness feel off again.

- [P2] Typography is improved but still not at the reference's custom UI quality.
  Location: all fight UI overlay text.
  Evidence: the fight UI now uses `MPLUS1p-Bold.ttf` for the main overlay text, the top-status numbers are stronger, and the location/depth card now matches the reference's iconless centered layout. The parchment-card icons are smaller and quieter, but still more ornate than the simpler reference glyphs. The reference still has more tailored optical weights plus tighter small-text rendering.
  Impact: the screen now reads more like a game UI, but typography still does not fully sell the premium mockup quality.
  Fix: keep the bold/regular split, then tune per-component font sizes and replace/simplify the top-status icon sheet if those icons still read too noisy in the final full-screen pass.

## Open Questions

- None blocking. The next highest-value pass is final gauge-label spacing and optical type tuning, while keeping the darker HUD board and reduced icon scale as the current baseline.

## Implementation Checklist

1. Tune final gauge-label padding on the HUD upper board.
2. Tune final title/value optical sizes on HUD and right panel.
3. Replace HUD/top-status icons only if they still read ornate after spacing is locked.
4. Re-run `/tmp/tsuri_fight_compare.png`, `/tmp/tsuri_frame_focus_compare.png`, and `/tmp/tsuri_fish_hit_focus.png` after each pass.

## Follow-up Polish

- Replace top status icons with simpler reference-like icons if they still feel noisy after the font pass.
- Recheck the hit splash after the final HUD/font pass, but do not keep iterating it unless the comparison regresses.
- Add small sparkle/bubble particles only after the main frame and typography mismatches are solved.
- Add subtle tail/body variants to the kurodai sheet later if animation quality becomes noticeable; keep the current static extracted art for visual fidelity.
