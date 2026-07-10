#!/usr/bin/env python3
"""Read-only consistency checks for the repository's licensing documents."""

from pathlib import Path
import re
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[1]


def require_file(relative: str) -> str:
    path = ROOT / relative
    if not path.is_file():
        raise AssertionError(f"missing required file: {relative}")
    return path.read_text(encoding="utf-8")


def main() -> int:
    try:
        license_text = require_file("LICENSE.md")
        notices = require_file("THIRD_PARTY_NOTICES.md")
        ledger = require_file("docs/31_asset_ledger.md")
        evidence = require_file("docs/qa/evidence/licensing/README.md")
        line_seed_ofl = require_file("assets/fonts/line_seed/OFL.txt")
        mplus_ofl = require_file("assets/fonts/OFL-MPLUS1p.txt")

        for marker in ("## Scope", "Original project-owned visual and audio assets"):
            assert marker in license_text, f"LICENSE.md missing marker: {marker}"
        unresolved_holder = "RIGHTS HOLDER NAME" in license_text
        if unresolved_holder:
            assert "U-05" in evidence, "unresolved LICENSE holder must map to evidence U-05"
        else:
            copyright_line = next(
                (line for line in license_text.splitlines() if line.startswith("Copyright (c) 2026 ")),
                "",
            )
            assert re.fullmatch(r"Copyright \(c\) 2026 \S.*", copyright_line), "invalid copyright holder line"
        for marker in ("Godot Engine", "LINE Seed JP", "M PLUS 1p"):
            assert marker in notices, f"THIRD_PARTY_NOTICES.md missing: {marker}"
        for marker in ("Engine.get_license_text()", "Engine.get_license_info()", "Engine.get_copyright_info()"):
            assert marker in notices, f"Godot notice extraction method missing: {marker}"
        for marker in ("Copyright 2020-2022 LY Corporation", "SIL OPEN FONT LICENSE Version 1.1"):
            assert marker in line_seed_ofl, f"LINE Seed OFL missing: {marker}"
        for marker in ("Copyright 2016 The M+ Project Authors", "SIL OPEN FONT LICENSE Version 1.1"):
            assert marker in mplus_ofl, f"M PLUS OFL missing: {marker}"
        for marker in ("U-01", "U-08", "ユーザー入力・保存待ち"):
            assert marker in evidence, f"licensing evidence index missing: {marker}"
        for marker in ("THIRD_PARTY_NOTICES.md", "加入期間証拠待ち", "Pre-Generated AI"):
            assert marker in ledger, f"asset ledger missing: {marker}"

        expected_fonts = {
            "assets/fonts/line_seed/LINESeedJP_A_TTF_Rg.ttf",
            "assets/fonts/line_seed/LINESeedJP_A_TTF_Bd.ttf",
            "assets/fonts/line_seed/LINESeedJP_A_TTF_Eb.ttf",
            "assets/fonts/MPLUS1p-Regular.ttf",
            "assets/fonts/MPLUS1p-Bold.ttf",
            "assets/fonts/MPLUS1p-ExtraBold.ttf",
        }
        actual_fonts = {
            path.relative_to(ROOT).as_posix()
            for path in (ROOT / "assets/fonts").glob("**/*")
            if path.suffix.lower() in {".ttf", ".otf", ".woff", ".woff2"}
        }
        assert actual_fonts == expected_fonts, (
            f"font notice boundary mismatch: missing={sorted(expected_fonts - actual_fonts)}, "
            f"unreviewed={sorted(actual_fonts - expected_fonts)}"
        )
        for relative in expected_fonts:
            assert Path(relative).name in notices, f"font not enumerated in notices: {relative}"

        tracked = subprocess.run(
            ["git", "ls-files"], cwd=ROOT, check=True, capture_output=True, text=True
        ).stdout.splitlines()
        addon_entries = [path for path in tracked if path == "addons" or path.startswith("addons/")]
        native_extensions = [
            path for path in tracked if Path(path).suffix.lower() in {".gdextension", ".dll", ".so", ".dylib"}
        ]
        assert not addon_entries, f"unreviewed tracked Godot add-ons: {addon_entries}"
        assert not native_extensions, f"unreviewed tracked native dependencies: {native_extensions}"
    except AssertionError as exc:
        print(f"licensing audit: FAIL: {exc}", file=sys.stderr)
        return 1

    print("licensing audit: ok (document consistency; release blockers remain explicitly listed)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
