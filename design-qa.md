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

- Added a lighter `_draw_clean_card()` path to `tools/generate_underwater_ui_frame_assets.py`.
- Reduced the heavy black/gold outer trim on `sidebar_frame.png`.
- Removed most decorative rivets from the sidebar frame so it no longer reads as a generated/debug skin.
- Rebuilt sidebar paper/navy cards with thinner inner strokes and lower paper grain.
- Reduced `fight_hud_frame.png` line noise: thinner gauge wells, lighter separators, lighter depth-plate borders, and cleaner lower-card frames.
- Regenerated `sidebar_frame.png`, `fight_hud_frame.png`, and `top_status_frame.png` with the lighter card rules.

## Findings

- [P2] Right panel is structurally better but still below reference card quality.
  Location: `assets/showcase/underwater/sidebar_frame.png`, `src/ui/components/fight_sidebar.gd`, `src/ui/fishing_screen.gd`.
  Evidence: the latest frame is visibly lighter: the previous heavy black/gold trim and extra rivets are reduced, and the paper cards read cleaner. The panel still has smaller lower-card content, less precise corner ornamentation, and less refined card rhythm than the reference.
  Impact: this is a real step toward the target, but the right panel still feels more like a generated UI frame than finished game art.
  Fix: final sidebar pass should enlarge the lower card body areas and replace the remaining procedural border style with a more hand-authored/card-painted frame.

- [P2] HUD top row is more connected, but the board styling is still not as authored as the reference.
  Location: `assets/showcase/underwater/fight_hud_frame.png`, `src/ui/components/fight_hud.gd`.
  Evidence: the top gauge row now reads as one navy operation board with a central angular depth plate, and the latest pass reduces the most obvious line noise. The reference still has stronger angular segmentation and tighter vertical rhythm; the implementation's lower control row still reads as separate simple cards.
  Impact: the HUD is no longer fragmented, but it still lacks the reference's compact, deliberate console feel.
  Fix: bring the depth module closer to the reference shape and tune the lower control row as one integrated strip instead of three equal cards.

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

- [P2] Typography is improved but still not at the reference's custom UI quality.
  Location: all fight UI overlay text.
  Evidence: the fight UI now uses `MPLUS1p-Bold.ttf` for the main overlay text and the top-status numbers are stronger. The reference still has more tailored optical weights, tighter small-text rendering, and a more bespoke game-font feel.
  Impact: the screen now reads more like a game UI, but typography still does not fully sell the premium mockup quality.
  Fix: keep the bold/regular split, then tune per-component font sizes and consider a more display-like Japanese face for title/value text only.

## Open Questions

- None blocking. The next highest-value pass is final fish/hit art, with another HUD/sidebar pass after the fish silhouette settles.

## Implementation Checklist

1. Do the final kurodai art pass against `/tmp/tsuri_fish_hit_focus.png`.
2. Tighten `hit_burst.png` placement/silhouette after HUD placement stabilizes.
3. Make the HUD lower control row read as one integrated operation strip.
4. Enlarge the sidebar lower card body regions if the final fish/HUD pass keeps the current sidebar width.
5. Continue font-size tuning after the next frame pass, especially small right-panel body text.
6. Re-run `/tmp/tsuri_fight_compare.png`, `/tmp/tsuri_frame_focus_compare.png`, and `/tmp/tsuri_fish_hit_focus.png` after each pass.

## Follow-up Polish

- Replace top status icons with simpler reference-like icons if they still feel noisy after the font pass.
- Add small sparkle/bubble particles only after the main frame and typography mismatches are solved.
