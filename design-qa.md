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

- Replaced `kurodai_showcase_sheet.png` with a new ImageGen-derived 4-frame kurodai sheet processed from `kurodai_chroma_source.png`.
- Added `tools/process_underwater_fish_assets.py` to remove chroma key, normalize the 4 fish frames, despill magenta edges, and regenerate `hit_burst.png`.
- Enlarged the in-water fish draw ratio so the kurodai reads as the central subject again.
- Reworked `hit_burst.png` into a flatter badge-style splash and increased the live Godot `ヒット！` text size, outline, and shadow.
- Locked `tools/fishing_fight_preview.gd` to the intended hit moment so the comparison capture consistently shows `突進` rather than advancing to another simulator action.

## Findings

- [P2] Main fish is improved, but the silhouette still differs from the reference.
  Location: `assets/showcase/underwater/kurodai_showcase_sheet.png`, `src/ui/components/underwater_view.gd`.
  Evidence: the implementation now has stronger scales, stripes, eye detail, and a more natural side profile than the previous asset. The reference fish is still longer, calmer, and slightly less rounded; the implementation has a taller body and more pronounced fins.
  Impact: the fish now works as a readable central subject, but exact reference fidelity still needs a final art pass.
  Fix: final fish pass should elongate the body, reduce the belly/fin drama, and tune the active frame against `/tmp/tsuri_fish_hit_focus.png`.

- [P2] Hit treatment is stronger but still not identical to the reference.
  Location: `assets/showcase/underwater/hit_burst.png`, `src/ui/components/underwater_view.gd`.
  Evidence: the implementation now has larger, heavier `ヒット！` text and a calmer badge-shaped splash. The reference badge is more compact and integrated into the HUD/water boundary, while the implementation sits more centrally and has a flatter blue star shape.
  Impact: the moment reads clearly now, but the effect still has a distinct art style from the reference.
  Fix: reduce badge height slightly, refine the outer silhouette, and retune the badge position after the final HUD/typography pass.

- [P2] HUD operation board remains more fragmented than the reference.
  Location: `assets/showcase/underwater/fight_hud_frame.png`, `src/ui/components/fight_hud.gd`.
  Evidence: the reference's top gauge row reads as one connected operation board with angular depth module; the implementation uses cleaner materials now, but still reads as separated cards.
  Impact: hierarchy is clear, but the bottom HUD still feels less compact and less authored than the reference.
  Fix: connect the HUD top row visually and reduce vertical separation between gauge row and lower controls.

- [P2] Right panel lower-card hierarchy is still cramped.
  Location: `src/ui/components/fight_sidebar.gd`, `assets/showcase/underwater/sidebar_frame.png`.
  Evidence: the reference lower action/tackle cards have larger breathing room; the implementation's action and tackle cards still feel miniature, especially in the tackle details.
  Impact: the right panel is functional, but not yet at the same JRPG information-card polish.
  Fix: re-author `sidebar_frame.png` inner windows or reduce lower-card copy so the lower cards gain whitespace and clearer hierarchy.

- [P2] Typography remains system-font generic compared with the reference.
  Location: all fight UI overlay text.
  Evidence: the reference has heavier game UI Japanese text and stronger numeric hierarchy; the implementation still uses default Godot/system rendering and mixed outlines.
  Impact: better assets are now in place, but typography keeps the screen in prototype territory.
  Fix: import a Japanese UI/pixel display font and define fixed styles for status values, card titles, body copy, gauge labels, and key chips.

## Open Questions

- None blocking. The next highest-value work is sidebar/HUD integration and typography, with a final fish silhouette refinement after those layout pieces settle.

## Implementation Checklist

1. Rework `sidebar_frame.png` or reduce right-panel lower-card content density.
2. Connect the HUD top row visually and reduce vertical separation between gauge row and lower controls.
3. Import/apply a Japanese game UI font and retune top/HUD/right-panel type sizes.
4. Optional final art pass: elongate the kurodai body and tighten the hit badge silhouette against the reference crop.
5. Re-run `/tmp/tsuri_fight_compare.png`, `/tmp/tsuri_frame_focus_compare.png`, and `/tmp/tsuri_fish_hit_focus.png` after each pass.

## Follow-up Polish

- Tune icon opacity after typography is selected.
- Consider replacing the top status icon sheet cells with simpler reference-like icons if the current generated icons still feel noisy at final size.
