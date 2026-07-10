# Third-Party Notices

This file lists third-party components that the repository evidence shows are
used by the game. It is not a substitute for the full license texts referenced
below. The final release package must include this file and the referenced
license texts.

## Godot Engine

The game is built with Godot Engine. Repository QA logs identify the current
development baseline as Godot Engine 4.7 stable; the exact export template and
its complete third-party license set must be copied from the final export
toolchain using Godot's `Engine.get_license_text()`, `Engine.get_license_info()`
and `Engine.get_copyright_info()` data, or the matching Godot source release's
`COPYRIGHT.txt`, and verified against the packaged build.

Godot Engine is distributed under the MIT License. Official compliance guide:
https://docs.godotengine.org/en/stable/about/complying_with_licenses.html

Godot's own copyright and license text, plus attribution required by libraries
compiled into the selected official export template, must accompany the final
desktop distribution. This repository cannot freeze that complete set until
the target OS, export format, and exact export template are selected.

## LINE Seed JP

Runtime font: referenced by `src/ui/game_fonts.gd`.

- Files: `assets/fonts/line_seed/LINESeedJP_A_TTF_Rg.ttf`,
  `LINESeedJP_A_TTF_Bd.ttf`, `LINESeedJP_A_TTF_Eb.ttf`
- Copyright: 2020-2022 LY Corporation
- License: SIL Open Font License 1.1
- Full text: `assets/fonts/line_seed/OFL.txt`

## M PLUS 1p

Bundled fallback font files: present in the repository and therefore included
in the notice boundary even though the current runtime font loader selects LINE
Seed JP.

- Files: `assets/fonts/MPLUS1p-Regular.ttf`, `MPLUS1p-Bold.ttf`,
  `MPLUS1p-ExtraBold.ttf`
- Copyright: 2016 The M+ Project Authors
- License: SIL Open Font License 1.1
- Full text: `assets/fonts/OFL-MPLUS1p.txt`

## Service-generated media

The repository records that pre-generated images and audio may have been made
with external AI services. These are not third-party runtime libraries. Only
the services' general terms have been reviewed; this does **not** establish
that each bundled asset satisfies the applicable paid-plan, input-rights, or
non-infringement conditions. Suno asset/date/subscription evidence remains open
under U-01/U-02, and input-rights clearance for Suno and OpenAI material remains
open under U-08 in `docs/qa/evidence/licensing/README.md`. OpenAI's contractual
assignment of its rights in Output is separate from third-party rights
clearance. Required store disclosure is also channel-dependent.

## Repository dependency boundary

No Godot add-on, GDExtension, native `.dll`, `.so`, or `.dylib` dependency was
found in the repository as of 2026-07-11. Re-run the licensing audit after the
release export is configured; the exported Godot runtime has its own compiled
third-party dependency set even when the project repository has none.
