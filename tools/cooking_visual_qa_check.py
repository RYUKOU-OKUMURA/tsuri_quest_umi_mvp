#!/usr/bin/env python3
"""Validate cooking visual QA captures and refresh the comparison report."""

from __future__ import annotations

import argparse
import hashlib
import json
import struct
import sys
from pathlib import Path

import cooking_reference_report
from PIL import Image


EXPECTED_SIZE = (1280, 720)
MANIFEST = Path("/tmp/tsuri_cooking_capture_manifest.json")
C1B_HOVER_FOCUS = Path("/tmp/tsuri_cooking_c1b_hover_focus.png")
EXPECTED_MANIFEST_STATES = {
    "COOK_SELECT": "current_prep_summary",
    "MEAL_RESULT": "MEAL_RESULT",
    "EXP_GAIN": "EXP_GAIN",
    "LEVEL_UP_OVERLAY": "LEVEL_UP_OVERLAY",
    "STATUS_SUMMARY": "STATUS_SUMMARY",
}


def png_size(path: Path) -> tuple[int, int]:
    with path.open("rb") as fh:
        signature = fh.read(8)
        if signature != b"\x89PNG\r\n\x1a\n":
            raise ValueError("not a PNG file")
        length_bytes = fh.read(4)
        chunk_type = fh.read(4)
        if len(length_bytes) != 4 or chunk_type != b"IHDR":
            raise ValueError("missing PNG IHDR")
        length = struct.unpack(">I", length_bytes)[0]
        if length < 8:
            raise ValueError("invalid PNG IHDR")
        width, height = struct.unpack(">II", fh.read(8))
        return width, height


def check_visual_content(path: Path, label: str, failures: list[str]) -> None:
    try:
        with Image.open(path) as image:
            rgba = image.convert("RGBA")
            alpha_extrema = rgba.getchannel("A").getextrema()
            if alpha_extrema[1] == 0:
                failures.append(f"{label}: image is fully transparent at {path}")
                return
            rgb = rgba.convert("RGB")
            extrema = rgb.getextrema()
            channel_spread = max(maximum - minimum for minimum, maximum in extrema)
            sample = rgb.resize((64, 36))
            colors = sample.getcolors(maxcolors=(64 * 36) + 1) or []
            sampled_pixels = list(sample.getdata())
            near_black_ratio = sum(1 for pixel in sampled_pixels if max(pixel) < 18) / len(sampled_pixels)
            transparent_ratio = sum(1 for alpha in rgba.getchannel("A").resize((64, 36)).getdata() if alpha < 250) / len(sampled_pixels)
    except OSError as exc:
        failures.append(f"{label}: could not inspect PNG pixels {path}: {exc}")
        return

    if channel_spread < 8:
        failures.append(f"{label}: image has too little color variation at {path}")
    if len(colors) < 16:
        failures.append(f"{label}: image has too few sampled colors at {path}")
    if near_black_ratio > 0.45:
        failures.append(f"{label}: near-black area is too large ({near_black_ratio:.1%}) at {path}")
    if transparent_ratio > 0.01:
        failures.append(f"{label}: transparent area is too large ({transparent_ratio:.1%}) at {path}")


def check_png(path: Path, label: str, failures: list[str], expected_size: tuple[int, int] | None) -> None:
    if not path.exists():
        failures.append(f"{label}: missing {path}")
        return
    try:
        size = png_size(path)
    except ValueError as exc:
        failures.append(f"{label}: invalid PNG {path}: {exc}")
        return
    if expected_size is not None and size != expected_size:
        failures.append(
            f"{label}: expected {expected_size[0]}x{expected_size[1]}, got {size[0]}x{size[1]} at {path}"
        )
    check_visual_content(path, label, failures)


def check_manifest(failures: list[str]) -> None:
    if not MANIFEST.exists():
        failures.append(f"capture manifest missing {MANIFEST}")
        return
    try:
        payload = json.loads(MANIFEST.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        failures.append(f"capture manifest invalid JSON {MANIFEST}: {exc}")
        return
    captures = payload.get("captures")
    if not isinstance(captures, list):
        failures.append(f"capture manifest missing captures list {MANIFEST}")
        return
    if len(captures) != len(cooking_reference_report.STATES):
        failures.append(
            f"capture manifest expected {len(cooking_reference_report.STATES)} captures, got {len(captures)}"
        )
        return
    by_state = {}
    for entry in captures:
        if not isinstance(entry, dict):
            failures.append(f"capture manifest contains non-object entry: {entry!r}")
            return
        state_id = entry.get("state")
        if state_id in by_state:
            failures.append(f"capture manifest has duplicate state {state_id}")
            return
        by_state[state_id] = entry
    for state in cooking_reference_report.STATES:
        state_id = str(state["id"])
        entry = by_state.get(state_id)
        if entry is None:
            failures.append(f"capture manifest missing state {state_id}")
            continue
        expected_capture = str(Path(state["capture"]))
        if entry.get("capture") != expected_capture:
            failures.append(
                f"capture manifest {state_id} expected capture {expected_capture}, got {entry.get('capture')}"
            )
        expected_verified_state = EXPECTED_MANIFEST_STATES[state_id]
        if entry.get("verified_state") != expected_verified_state:
            failures.append(
                f"capture manifest {state_id} expected verified_state {expected_verified_state}, "
                f"got {entry.get('verified_state')}"
            )
        if (entry.get("width"), entry.get("height")) != EXPECTED_SIZE:
            failures.append(
                f"capture manifest {state_id} expected size {EXPECTED_SIZE[0]}x{EXPECTED_SIZE[1]}, "
                f"got {entry.get('width')}x{entry.get('height')}"
            )


def check_capture_uniqueness(failures: list[str]) -> None:
    hashes: dict[str, list[str]] = {}
    for state in cooking_reference_report.STATES:
        state_id = str(state["id"])
        capture = Path(state["capture"])
        if not capture.exists():
            continue
        digest = hashlib.sha256(capture.read_bytes()).hexdigest()
        hashes.setdefault(digest, []).append(state_id)
    if not hashes:
        return
    for state_ids in hashes.values():
        if len(state_ids) >= 3:
            failures.append(
                "capture frames are stale or duplicated across states: %s"
                % ", ".join(state_ids)
            )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Check cooking reference captures and regenerate the HTML QA report."
    )
    parser.add_argument(
        "--allow-missing",
        action="store_true",
        help="Return success even when current /tmp captures are missing.",
    )
    args = parser.parse_args()

    failures: list[str] = []
    missing_capture_failures: list[str] = []
    for state in cooking_reference_report.STATES:
        state_id = str(state["id"])
        reference = Path(state["reference"])
        capture = Path(state["capture"])
        check_png(reference, f"{state_id} reference", failures, None)
        before = len(failures)
        check_png(capture, f"{state_id} capture", failures, EXPECTED_SIZE)
        if len(failures) > before and not capture.exists():
            missing_capture_failures.append(failures[-1])
    before = len(failures)
    check_png(C1B_HOVER_FOCUS, "COOK-C1B hover/focus capture", failures, EXPECTED_SIZE)
    if len(failures) > before and not C1B_HOVER_FOCUS.exists():
        missing_capture_failures.append(failures[-1])
    if not missing_capture_failures:
        check_manifest(failures)
        check_capture_uniqueness(failures)

    cooking_reference_report.main()

    effective_failures = failures
    if args.allow_missing:
        effective_failures = [f for f in failures if f not in missing_capture_failures]

    if effective_failures:
        for failure in effective_failures:
            print(f"FAIL: {failure}", file=sys.stderr)
        print(
            "Run tools/cooking_preview.gd with a real display driver, then rerun this check.",
            file=sys.stderr,
        )
        return 1

    if missing_capture_failures:
        for failure in missing_capture_failures:
            print(f"ALLOW-MISSING: {failure}")
    print(f"Cooking visual QA report: {cooking_reference_report.OUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
