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

- Enlarged the right-panel action and tackle card regions in `assets/showcase/underwater/sidebar_frame.png`.
- Matched `FightSidebar` card layout ratios to the updated sidebar frame.
- Tightened tackle card copy, font size, and line spacing so the three equipment lines fit inside the parchment body.
- Regenerated `/tmp/tsuri_fight_compare.png` and `/tmp/tsuri_frame_focus_compare.png`.

## Findings

- [P2] Right panel is structurally better but still below reference card quality.
  Location: `assets/showcase/underwater/sidebar_frame.png`, `src/ui/components/fight_sidebar.gd`, `src/ui/fishing_screen.gd`.
  Evidence: the action and tackle bodies are larger and the tackle text now fits inside its parchment card. The panel still has less precise corner ornamentation, weaker internal hierarchy, and a more procedural frame rhythm than the reference.
  Impact: the right panel is more readable, but it still does not fully sell the premium JRPG card quality.
  Fix: replace the remaining procedural border style with more hand-authored/card-painted ornamentation and tune right-panel type sizes after the final font decision.

- [P2] HUD top row is more connected, but the board styling is still not as authored as the reference.
  Location: `assets/showcase/underwater/fight_hud_frame.png`, `src/ui/components/fight_hud.gd`.
  Evidence: the bottom controls now share a navy base, so the previous three-floating-card read is reduced. The reference still has stronger angular segmentation in the upper gauge board, more deliberate depth-module geometry, and tighter vertical rhythm.
  Impact: the HUD is moving toward a single operation board, but it still lacks the reference's compact, authored console feel.
  Fix: bring the depth module closer to the reference shape, reduce lower-row height slightly if needed, and tune text positions after the final frame geometry is locked.

- [P3] Main fish is now close, with minor runtime-placement polish remaining.
  Location: `assets/showcase/underwater/kurodai_showcase_sheet.png`, `src/ui/components/underwater_view.gd`.
  Evidence: the fish source now preserves the reference-like black seabream outline, scale texture, dorsal spines, eye, and gray banding. The implementation fish is also closer in scale and no longer reads as a generic generated cutout. The remaining mismatch is mainly placement polish: the bait sits slightly higher/right than the reference and the runtime fish still lives on a brighter, denser generated background.
  Impact: the fish is no longer a blocking quality mismatch; it now sells the screen's main subject.
  Fix: keep this asset as the current kurodai baseline, then tune lure placement only after the hit badge and HUD frame settle.

- [P3] Hit treatment is closer, with minor placement/brightness polish remaining.
  Location: `assets/showcase/underwater/hit_burst.png`, `src/ui/components/underwater_view.gd`.
  Evidence: the badge now reads as a dark blue splash with cyan edges behind the yellow/orange live text, which is much closer to the reference than the previous orange-centered oval. It still has more radial white streaks and a slightly different lower-edge overlap than the source mockup.
  Impact: the hit moment is no longer a major art-style mismatch, but it still needs a final polish pass after the HUD frame is locked.
  Fix: after the HUD pass, tune the splash brightness and exact vertical overlap so it sits naturally on the top edge of the lower operation board.

- [P2] Typography is improved but still not at the reference's custom UI quality.
  Location: all fight UI overlay text.
  Evidence: the fight UI now uses `MPLUS1p-Bold.ttf` for the main overlay text and the top-status numbers are stronger. The reference still has more tailored optical weights, tighter small-text rendering, and a more bespoke game-font feel.
  Impact: the screen now reads more like a game UI, but typography still does not fully sell the premium mockup quality.
  Fix: keep the bold/regular split, then tune per-component font sizes and consider a more display-like Japanese face for title/value text only.

## Open Questions

- None blocking. The next highest-value pass is another HUD/sidebar pass now that the fish and hit silhouette are usable.

## Implementation Checklist

1. Bring the HUD depth module and top-row angular separators closer to the reference.
2. Tune right-panel border ornamentation and title/body type sizes.
3. Continue font-size tuning after the next frame pass, especially small right-panel body text.
4. Re-run `/tmp/tsuri_fight_compare.png`, `/tmp/tsuri_frame_focus_compare.png`, and `/tmp/tsuri_fish_hit_focus.png` after each pass.

## Follow-up Polish

- Replace top status icons with simpler reference-like icons if they still feel noisy after the font pass.
- Tune the hit splash brightness and bottom overlap after the HUD shape is finalized.
- Add small sparkle/bubble particles only after the main frame and typography mismatches are solved.
- Add subtle tail/body variants to the kurodai sheet later if animation quality becomes noticeable; keep the current static extracted art for visual fidelity.
