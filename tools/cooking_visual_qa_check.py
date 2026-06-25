#!/usr/bin/env python3
"""Validate cooking visual QA captures and refresh the comparison report."""

from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path

import cooking_reference_report


EXPECTED_SIZE = (1280, 720)


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
