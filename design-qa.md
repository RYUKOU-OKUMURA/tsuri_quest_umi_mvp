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

- Replaced the previous generated kurodai source with a reference-fish background-extraction pass saved to `assets/showcase/underwater/kurodai_chroma_source.png`.
- Updated `tools/process_underwater_fish_assets.py` so a single high-quality fish cutout can be normalized into the required four-frame runtime sheet without slicing it into quarters.
- Regenerated `assets/showcase/underwater/kurodai_showcase_sheet.png` from the extracted reference-style source.
- Increased the showcase fish display scale in `src/ui/components/underwater_view.gd` to restore the reference's main-subject presence.
- Moved the bait/line endpoint from the fish body to the fish's nose-forward area so the line no longer visually pierces the kurodai.

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

- [P3] Main fish is now close, with minor runtime-placement polish remaining.
  Location: `assets/showcase/underwater/kurodai_showcase_sheet.png`, `src/ui/components/underwater_view.gd`.
  Evidence: the fish source now preserves the reference-like black seabream outline, scale texture, dorsal spines, eye, and gray banding. The implementation fish is also closer in scale and no longer reads as a generic generated cutout. The remaining mismatch is mainly placement polish: the bait sits slightly higher/right than the reference and the runtime fish still lives on a brighter, denser generated background.
  Impact: the fish is no longer a blocking quality mismatch; it now sells the screen's main subject.
  Fix: keep this asset as the current kurodai baseline, then tune lure placement only after the hit badge and HUD frame settle.

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

- None blocking. The next highest-value pass is final hit-badge art plus another HUD/sidebar pass now that the fish silhouette is usable.

## Implementation Checklist

1. Tighten `hit_burst.png` placement/silhouette after HUD placement stabilizes.
2. Make the HUD lower control row read as one integrated operation strip.
3. Enlarge the sidebar lower card body regions if the current sidebar width remains.
4. Continue font-size tuning after the next frame pass, especially small right-panel body text.
5. Re-run `/tmp/tsuri_fight_compare.png`, `/tmp/tsuri_frame_focus_compare.png`, and `/tmp/tsuri_fish_hit_focus.png` after each pass.

## Follow-up Polish

- Replace top status icons with simpler reference-like icons if they still feel noisy after the font pass.
- Add small sparkle/bubble particles only after the main frame and typography mismatches are solved.
- Add subtle tail/body variants to the kurodai sheet later if animation quality becomes noticeable; keep the current static extracted art for visual fidelity.
