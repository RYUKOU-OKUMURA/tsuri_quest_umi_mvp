# Underwater Fight Design QA

final result: blocked

Date: 2026-06-24

Source visual truth: `reference/02_underwater_fight_mockup.png`
Implementation screenshot: `/tmp/tsuri_fishing_fight.png`
Full-view comparison evidence: `/tmp/tsuri_fight_compare.png`
Focused region comparison evidence: `/tmp/tsuri_frame_focus_compare.png`
Side-by-side page: `/tmp/tsuri_fight_compare.html`
Viewport: 1280x720
State: underwater fight, kurodai hit moment, depth 18.6m, action `突進`

## Patches Made Since Previous QA

- Replaced the heavy generated `top_status_frame.png` with a cleaner paper-card raster frame: smaller icon wells, no text-like baked artifacts, less gold ornament.
- Replaced the heavy generated `fight_hud_frame.png` with a cleaner two-row raster HUD: dark gauge plates, parchment lower cards, quieter gold dividers, explicit blank content zones.
- Added `tools/generate_underwater_ui_frame_assets.py` so the top/HUD frame slots can be regenerated deterministically at the same asset paths.
- Updated top status text composition: inline AM/time and weather/wind, comma-formatted money, preview money fixed to `12,450 G`.
- Adjusted the bait icon well so the frame and live bait icon no longer read as two unrelated symbols.

## Findings

- [P1] Main fish and hit art still do not match the reference art direction.
  Location: `src/ui/components/underwater_view.gd`, `assets/showcase/underwater/kurodai_showcase_sheet.png`, `assets/showcase/underwater/hit_burst.png`.
  Evidence: the reference fish has a calmer horizontal silhouette and softer integration with the water; the implementation fish is correctly sized now, but the pose is still more dramatic and the hit burst is sharper/more explosive than the reference badge-like splash.
  Impact: this is the central focal point of the screen, so the remaining art-direction mismatch keeps the whole screen from feeling like the reference even after UI improvements.
  Fix: re-author the kurodai sprite sheet and hit burst from the reference crop: calmer side profile, less aggressive fin spread, softer burst silhouette, and a stronger match to the reference's `ヒット！` treatment.

- [P2] HUD frame quality is improved, but the operation board is still more fragmented than the reference.
  Location: `assets/showcase/underwater/fight_hud_frame.png`, `src/ui/components/fight_hud.gd`.
  Evidence: the reference's top gauge row reads as one connected operation board with angular depth module; the implementation now has cleaner materials, but the row still feels like three separated cards with a visible gap before the lower row.
  Impact: hierarchy is much clearer than before, but the bottom HUD still feels less authored and less compact than the reference.
  Fix: next HUD pass should connect the top row visually and reduce vertical gap while preserving the cleaner frame style.

- [P2] Right panel still has cramped lower-card hierarchy.
  Location: `src/ui/components/fight_sidebar.gd`, `assets/showcase/underwater/sidebar_frame.png`.
  Evidence: the reference lower action/tackle cards have readable card hierarchy and larger breathing room; the implementation's lower right cards remain miniature, especially the tackle details.
  Impact: the right panel is functional, but it still does not reach the JRPG information-card polish of the reference.
  Fix: re-author `sidebar_frame.png` inner windows or reduce tackle copy so the lower cards gain whitespace and clearer hierarchy.

- [P2] Typography remains system-font generic compared with the reference.
  Location: all fight UI overlay text.
  Evidence: the reference has heavier game UI Japanese text and stronger numeric hierarchy; the implementation still uses default Godot/system rendering and mixed outlines.
  Impact: even with better frame assets, the screen keeps a prototype feel.
  Fix: import a Japanese UI/pixel display font and define fixed styles for status values, card titles, body copy, gauge labels, and key chips.

- [P2] Top status is cleaner but still not as dense as the reference.
  Location: `src/ui/components/fight_status_bar.gd`, `assets/showcase/underwater/top_status_frame.png`.
  Evidence: the new cards remove the generated-artifact problem, but the reference cards are tighter, larger in the vertical crop, and use stronger icon/text contrast.
  Impact: this is no longer the biggest blocker, but it still leaves a visible fidelity gap in the first read of the screen.
  Fix: after font selection, retune top card height, text weight, and icon scale against `/tmp/tsuri_frame_focus_compare.png`.

## Open Questions

- None blocking. The next highest-value work is the central fish/hit asset pass, followed by sidebar and font integration.

## Implementation Checklist

1. Re-author `kurodai_showcase_sheet.png` and `hit_burst.png` against the reference crop.
2. Connect the HUD top row visually and reduce vertical separation between gauge row and lower controls.
3. Rework `sidebar_frame.png` or reduce right-panel lower-card content density.
4. Import/apply a Japanese game UI font and retune top/HUD/right-panel type sizes.
5. Re-run `/tmp/tsuri_fight_compare.png` and `/tmp/tsuri_frame_focus_compare.png` after each asset swap.

## Follow-up Polish

- Tune icon opacity after typography is selected.
- Consider replacing the top status icon sheet cells with simpler reference-like icons if the current generated icons still feel noisy at final size.
