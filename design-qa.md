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

- Rebuilt the upper HUD depth module in `assets/showcase/underwater/fight_hud_frame.png` as a narrower central blue plate with darker side sockets, stronger angled gold separators, and title/value backing plaques.
- Matched `FightHud` depth text centering to the narrower plate and the right-side up/down arrows.
- Regenerated `/tmp/tsuri_fight_compare.png`, `/tmp/tsuri_frame_focus_compare.png`, and `/tmp/tsuri_fish_hit_focus.png`.

## Findings

- [P2] Right panel is structurally better but still below reference card quality.
  Location: `assets/showcase/underwater/sidebar_frame.png`, `src/ui/components/fight_sidebar.gd`, `src/ui/fishing_screen.gd`.
  Evidence: the action and tackle bodies are larger and the tackle text now fits inside its parchment card. The panel still has less precise corner ornamentation, weaker internal hierarchy, and a more procedural frame rhythm than the reference.
  Impact: the right panel is more readable, but it still does not fully sell the premium JRPG card quality.
  Fix: replace the remaining procedural border style with more hand-authored/card-painted ornamentation and tune right-panel type sizes after the final font decision.

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

- None blocking. The next highest-value pass is right-panel ornamentation and typography, while keeping the updated HUD depth plate as the current baseline.

## Implementation Checklist

1. Tune right-panel border ornamentation, internal dividers, and title/body type sizes.
2. Continue HUD upper-board polish only after the right-panel frame pass, focusing on color balance and gauge-label spacing.
3. Continue font-size tuning after the next frame pass, especially small right-panel body text and HUD value/title rhythm.
4. Re-run `/tmp/tsuri_fight_compare.png`, `/tmp/tsuri_frame_focus_compare.png`, and `/tmp/tsuri_fish_hit_focus.png` after each pass.

## Follow-up Polish

- Replace top status icons with simpler reference-like icons if they still feel noisy after the font pass.
- Tune the hit splash brightness and bottom overlap after the HUD shape is finalized.
- Add small sparkle/bubble particles only after the main frame and typography mismatches are solved.
- Add subtle tail/body variants to the kurodai sheet later if animation quality becomes noticeable; keep the current static extracted art for visual fidelity.
