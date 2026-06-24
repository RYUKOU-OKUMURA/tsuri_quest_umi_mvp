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

- Added reproducible `sidebar_frame.png` generation to `tools/generate_underwater_ui_frame_assets.py`.
- Re-authored `sidebar_frame.png` as a dedicated right-panel frame with a larger fish card and tighter action/tackle cards.
- Re-authored `fight_hud_frame.png` so the top gauge row reads more like one connected operation board instead of separated cards.
- Retuned `FightSidebar` layout: fish name/tag sizing, larger portrait slot, centered estimate value, two-line fish detail copy, larger action icon, reduced tackle copy.
- Removed the generic outer `make_panel()` wrapper around the right sidebar in `FishingScreen`, so the dedicated sidebar art is no longer shrunk inside a second parchment panel.
- Removed baked fish-card divider lines from `sidebar_frame.png` after they conflicted with the live Godot text/dividers.

## Findings

- [P2] Right panel is structurally better but still below reference card quality.
  Location: `assets/showcase/underwater/sidebar_frame.png`, `src/ui/components/fight_sidebar.gd`, `src/ui/fishing_screen.gd`.
  Evidence: the implementation no longer has the extra cream outer wrapper and no longer has a divider line crossing the estimate text. The panel reads more like a dedicated JRPG sidebar. It still has heavier black/gold trim, smaller lower-card content, and less refined card rhythm than the reference.
  Impact: this is a real step toward the target, but the right panel still feels more like a generated UI frame than finished game art.
  Fix: final sidebar pass should use a cleaner hand-authored/card-painted frame, enlarge the lower card body areas, and tune the title/body font styles after the font pass.

- [P2] HUD top row is more connected, but the board styling is still not as authored as the reference.
  Location: `assets/showcase/underwater/fight_hud_frame.png`, `src/ui/components/fight_hud.gd`.
  Evidence: the top gauge row now reads as one navy operation board with a central angular depth plate. The reference has stronger angular segmentation and tighter vertical rhythm; the implementation still has generated-looking linework and a plainer lower control row.
  Impact: the HUD is no longer fragmented, but it still lacks the reference's compact, deliberate console feel.
  Fix: reduce generated line noise, bring the depth module closer to the reference shape, and tune the lower control row as one integrated strip instead of three equal cards.

- [P2] Main fish remains a style mismatch.
  Location: `assets/showcase/underwater/kurodai_showcase_sheet.png`, `src/ui/components/underwater_view.gd`.
  Evidence: the current fish is readable and detailed, but the reference fish is longer, flatter, calmer, and more naturally shaded. The implementation fish is taller and more dramatic.
  Impact: the screen has a strong subject, but it still does not match the reference's premium pixel-art/painted fish quality.
  Fix: make a final fish asset pass: elongate the body, reduce fin drama, flatten the belly, and tune contrast against `/tmp/tsuri_fish_hit_focus.png`.

- [P2] Hit treatment is clear but still a different art style.
  Location: `assets/showcase/underwater/hit_burst.png`, `src/ui/components/underwater_view.gd`.
  Evidence: the implementation has a readable large `ヒット！`, but the badge is flatter and more central than the reference, which sits more naturally at the water/HUD boundary.
  Impact: the moment is legible, but the effect is still not visually unified with the target mockup.
  Fix: tighten the burst silhouette, reduce height, and retune vertical placement after the final HUD pass.

- [P2] Typography remains the largest cross-cutting quality gap.
  Location: all fight UI overlay text.
  Evidence: the project uses `MPLUS1p-Regular.ttf` through the theme, but the reference has heavier game UI text, stronger numeric hierarchy, and better optical weights. Current small labels in the right panel and HUD still feel thin and cramped.
  Impact: even with better frames, text keeps the screen in prototype territory.
  Fix: import a heavier Japanese UI/display font or add a bold face, then define fixed styles for top status values, HUD labels, side-card titles, body copy, and key chips.

## Open Questions

- None blocking. The next highest-value pass is typography plus a cleaner final sidebar/HUD frame pass.

## Implementation Checklist

1. Add a heavier Japanese UI font and retune all fight-screen text sizes/weights.
2. Rework the sidebar frame one more time with less heavy black trim and larger lower-card body regions.
3. Reduce HUD frame line noise and make the lower control row read as one integrated operation strip.
4. Do the final kurodai art pass against `/tmp/tsuri_fish_hit_focus.png`.
5. Tighten `hit_burst.png` placement/silhouette after HUD placement stabilizes.
6. Re-run `/tmp/tsuri_fight_compare.png`, `/tmp/tsuri_frame_focus_compare.png`, and `/tmp/tsuri_fish_hit_focus.png` after each pass.

## Follow-up Polish

- Replace top status icons with simpler reference-like icons if they still feel noisy after the font pass.
- Add small sparkle/bubble particles only after the main frame and typography mismatches are solved.
