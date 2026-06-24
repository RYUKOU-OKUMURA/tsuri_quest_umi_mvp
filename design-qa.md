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

- Reduced the white ray/fleck intensity in `assets/showcase/underwater/hit_burst.png`.
- Moved the hit badge slightly lower in `UnderwaterView` so the lower edge overlaps the operation board more like the reference.
- Increased the right action-card body copy size and added a minimal Japanese line-break guard so punctuation does not start the next line.
- Regenerated `/tmp/tsuri_fight_compare.png`, `/tmp/tsuri_frame_focus_compare.png`, and `/tmp/tsuri_fish_hit_focus.png`.

## Findings

- [P2] Right panel is structurally better but still below reference card quality.
  Location: `assets/showcase/underwater/sidebar_frame.png`, `src/ui/components/fight_sidebar.gd`, `src/ui/fishing_screen.gd`.
  Evidence: the fish card now has quieter reference-like ruled lines, and the action/tackle cards have clearer title separators plus body brackets. The lower-card text sits better inside the parchment bodies. The panel still has a more procedural border rhythm and less bespoke typography than the reference.
  Impact: the right panel is more readable and more deliberately framed, but it still does not fully sell the premium JRPG card quality.
  Fix: keep the new internal structure, then tune title/body optical sizes and replace any remaining generated-looking linework only if it still reads too mechanical in the next full-screen pass.

- [P2] HUD top row is closer, but the board styling still needs final authored polish.
  Location: `assets/showcase/underwater/fight_hud_frame.png`, `src/ui/components/fight_hud.gd`.
  Evidence: the central depth module now reads as a fitted blue plate instead of a simple vertical split, and the top-row separators better echo the reference's angled segmentation. The reference still has more restrained blue/black value-panel balance, more precise gauge spacing, and a tighter custom type rhythm.
  Impact: the HUD is now structurally closer to the target operation board, but it still does not fully reach the reference's hand-authored console quality.
  Fix: keep the new depth-plate structure, then tune upper-board color balance, title/value type sizes, and gauge-label spacing after the right-panel frame pass.

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
  Evidence: the fight UI now uses `MPLUS1p-Bold.ttf` for the main overlay text and the top-status numbers are stronger. The reference still has more tailored optical weights, tighter small-text rendering, and a more bespoke game-font feel.
  Impact: the screen now reads more like a game UI, but typography still does not fully sell the premium mockup quality.
  Fix: keep the bold/regular split, then tune per-component font sizes and consider a more display-like Japanese face for title/value text only.

## Open Questions

- None blocking. The next highest-value pass is top-status/HUD typography and icon simplification, while keeping the updated sidebar, HUD, and hit badge as the current baseline.

## Implementation Checklist

1. Tune top-status and HUD title/value optical sizes, especially the location/depth card and depth module.
2. Simplify or replace top-status icons if they still read noisy against the reference.
3. Continue HUD upper-board polish, focusing on color balance and gauge-label spacing.
4. Re-run `/tmp/tsuri_fight_compare.png`, `/tmp/tsuri_frame_focus_compare.png`, and `/tmp/tsuri_fish_hit_focus.png` after each pass.

## Follow-up Polish

- Replace top status icons with simpler reference-like icons if they still feel noisy after the font pass.
- Recheck the hit splash after the final HUD/font pass, but do not keep iterating it unless the comparison regresses.
- Add small sparkle/bubble particles only after the main frame and typography mismatches are solved.
- Add subtle tail/body variants to the kurodai sheet later if animation quality becomes noticeable; keep the current static extracted art for visual fidelity.
