#!/usr/bin/env python3
"""Build deterministic before/after/reference boards for one market M2 slot."""

from __future__ import annotations

import argparse
import shutil
from pathlib import Path

from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parents[1]
REFERENCE = ROOT / "reference" / "10_fish_market_mockup.png"
EVIDENCE_DIR = ROOT / "docs" / "qa" / "evidence" / "fish_market"
STATES = ("select", "confirm", "sold", "empty")
FULL_SIZE = (1280, 720)
THUMB_SIZE = (320, 180)


def load_rgb(path: Path, size: tuple[int, int] | None = None) -> Image.Image:
    with Image.open(path) as source:
        image = source.convert("RGB")
    if size is not None:
        image = ImageOps.fit(image, size, method=Image.Resampling.LANCZOS)
    return image


def join(images: list[Image.Image]) -> Image.Image:
    width = sum(image.width for image in images)
    height = max(image.height for image in images)
    board = Image.new("RGB", (width, height), (10, 22, 34))
    x = 0
    for image in images:
        board.paste(image, (x, 0))
        x += image.width
    return board


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--slot", required=True, choices=("bg", "ice"))
    parser.add_argument("--before-dir", type=Path, required=True)
    parser.add_argument("--after-dir", type=Path, default=Path("/tmp"))
    args = parser.parse_args()

    EVIDENCE_DIR.mkdir(parents=True, exist_ok=True)
    reference_full = load_rgb(REFERENCE, FULL_SIZE)
    reference_thumb = load_rgb(REFERENCE, THUMB_SIZE)
    shutil.copyfile(REFERENCE, EVIDENCE_DIR / "2026-07-13_m2_reference_original.png")

    for state in STATES:
        before = load_rgb(args.before_dir / f"before_{state}.png", FULL_SIZE)
        after_path = args.after_dir / f"tsuri_market_{state}.png"
        after = load_rgb(after_path, FULL_SIZE)

        before.save(EVIDENCE_DIR / f"2026-07-13_m2_{args.slot}_before_{state}.png")
        after.save(EVIDENCE_DIR / f"2026-07-13_m2_{args.slot}_after_{state}.png")
        join([before, after]).save(
            EVIDENCE_DIR / f"2026-07-13_m2_{args.slot}_{state}_before_after.png"
        )
        join([after, reference_full]).save(
            EVIDENCE_DIR / f"2026-07-13_m2_{args.slot}_{state}_after_reference.png"
        )

        thumbs = [
            before.resize(THUMB_SIZE, Image.Resampling.LANCZOS),
            after.resize(THUMB_SIZE, Image.Resampling.LANCZOS),
            reference_thumb,
        ]
        join(thumbs).save(
            EVIDENCE_DIR / f"2026-07-13_m2_{args.slot}_{state}_thumbnail_triptych.png"
        )
        join([ImageOps.grayscale(image).convert("RGB") for image in thumbs]).save(
            EVIDENCE_DIR / f"2026-07-13_m2_{args.slot}_{state}_gray_triptych.png"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
