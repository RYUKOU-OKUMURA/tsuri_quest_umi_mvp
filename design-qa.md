# Underwater Fight Design QA

final result: blocked

Date: 2026-06-24

Source visual truth: `reference/02_underwater_fight_mockup.png`
Implementation screenshot: `/tmp/tsuri_fishing_fight.png`
Full-view comparison evidence: `/tmp/tsuri_fight_compare.png`
Side-by-side page: `/tmp/tsuri_fight_compare.html`
Viewport: 1280x720
State: underwater fight, kurodai hit moment, depth 18.6m, action `突進`
Focused region evidence: not saved separately in this pass because the remaining blockers are visible in the full-view 720p side-by-side comparison.

## Patches Made Since Previous QA

- Reduced the showcase fish scale so the water scene keeps more background/line/hit-effect breathing room.
- Removed the dark fish/action badge from the water viewport; fish/action data now lives in the right panel and HUD instead of covering the underwater art.
- Softened the in-water distance meter so it reads as secondary telemetry rather than a primary UI block.
- Adjusted `/tmp/tsuri_fishing_fight.png` preview data to compare a reference-like `クロダイ / レア / 44.2 cm` state instead of the oversized boss fixture.
- Tightened the right panel action/tackle overlays and added denser tackle information.
- Reduced HUD/top icon sizes and corrected the bait card text stack to reduce pasted-on icon weight.

## Findings

- [P1] Top status frame still feels over-decorated and less readable than the reference.
  Location: `src/ui/components/fight_status_bar.gd` over `assets/showcase/underwater/top_status_frame.png`.
  Evidence: the reference uses bright paper cards with compact icons and strong text hierarchy; the implementation still has heavy gold medallions and a generated frame that competes with the time/weather/money labels.
  Impact: the first read becomes ornament-first instead of information-first, which makes the screen feel more generated than authored.
  Fix: remake `top_status_frame.png` as a cleaner paper-card frame with smaller blank icon wells and no baked text/visual clutter, then keep Godot text aligned to those slots.

- [P1] Bottom HUD remains denser and more ornate than the reference's operation board.
  Location: `src/ui/components/fight_hud.gd` over `assets/showcase/underwater/fight_hud_frame.png`.
  Evidence: the reference separates tension/depth/stamina clearly and keeps the lower cards light; the implementation has strong gold edging, busy dividers, and crowded bait/control/menu content.
  Impact: the player has to scan too many equally loud elements, and the water scene loses visual priority.
  Fix: remake the HUD frame with fewer ornamental strokes, larger pale lower cards, and explicit blank content zones for bait, controls, and menu rows.

- [P2] Main fish scale is now closer, but fish/effect art direction still does not match the reference.
  Location: `src/ui/components/underwater_view.gd`, `kurodai_showcase_sheet.png`, `hit_burst.png`.
  Evidence: the reference fish has a calmer horizontal pose with more natural body proportions; the implementation fish is better sized but still has a more dramatic sprite pose and sharper illustration style. The hit burst is also more explosive and lower-contrast than the reference badge-like burst.
  Impact: the screen is improving structurally, but the central art still reads as a different game asset set.
  Fix: regenerate or hand-author a calmer kurodai sprite and hit burst specifically against the reference crop, then replace the existing PNGs without changing the layout API.

- [P2] Right panel is aligned to the reference data now, but text and micro-icons are still cramped.
  Location: `src/ui/components/fight_sidebar.gd`.
  Evidence: the reference fish card has clearer white-space around the portrait, description, and bottom cards; the implementation's generated frame insets and extra tackle lines make the lower two cards feel miniature.
  Impact: the right panel looks functional, but not yet like a polished JRPG information card.
  Fix: make the sidebar frame's inner content windows wider/cleaner and reserve larger blank text zones, then reduce lower-card copy if needed.

- [P2] Typography remains system-font generic compared with the reference.
  Location: all fight UI overlay text.
  Evidence: the reference has heavier, game-like Japanese UI text with stronger optical hierarchy; the implementation still uses default Godot/system rendering and mixed outlines.
  Impact: even when asset placement improves, the screen keeps a prototype feel.
  Fix: select and import a Japanese game UI font, then define fixed sizes/weights for status labels, card titles, body text, numbers, and button chips.

## Open Questions

- Should the next pass remake `top_status_frame.png` and `fight_hud_frame.png` first, or should it replace the main kurodai/hit art first? Based on the latest comparison, the UI frame assets are now the biggest visible mismatch.

## Implementation Checklist

1. Re-author `top_status_frame.png` without baked text-like marks and with smaller icon wells.
2. Re-author `fight_hud_frame.png` with lighter lower cards and less gold ornament density.
3. Re-author `sidebar_frame.png` inner windows or reduce lower-card copy to restore readable white-space.
4. Create a calmer reference-matched kurodai sprite sheet and a less explosive hit burst.
5. Import a Japanese UI font and apply a consistent typography scale.

## Follow-up Polish

- Tune final icon opacity and baseline alignment after the frame assets are replaced.
- Re-check the same `/tmp/tsuri_fight_compare.png` side-by-side after each asset swap.
