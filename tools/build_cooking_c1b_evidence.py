#!/usr/bin/env python3
"""Build the fixed COOK-C1B before/after/reference evidence boards."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ROOT / "docs" / "qa" / "evidence" / "cooking"
BEFORE = EVIDENCE / "2026-07-17_v1_prebaseline_select.png"
AFTER = Path("/tmp/tsuri_cooking_select.png")
REFERENCE = ROOT / "reference" / "cooking_flow" / "01_cook_select_concept.png"


def _load(path: Path, size: tuple[int, int]) -> Image.Image:
    if not path.is_file():
        raise FileNotFoundError(path)
    with Image.open(path) as image:
        return image.convert("RGB").resize(size, Image.Resampling.LANCZOS)


def _board(size: tuple[int, int], output: Path) -> None:
    label_height = 30 if size[1] >= 720 else 18
    labels = ("BEFORE", "AFTER", "REFERENCE")
    images = (_load(BEFORE, size), _load(AFTER, size), _load(REFERENCE, size))
    board = Image.new("RGB", (size[0] * 3, size[1] + label_height), (10, 18, 28))
    draw = ImageDraw.Draw(board)
    for index, (label, image) in enumerate(zip(labels, images)):
        x = index * size[0]
        board.paste(image, (x, label_height))
        draw.text((x + 8, 7 if label_height >= 30 else 2), label, fill=(255, 231, 168))
    output.parent.mkdir(parents=True, exist_ok=True)
    board.save(output, format="PNG", optimize=False, compress_level=9)


def main() -> None:
    _board((1280, 720), EVIDENCE / "2026-07-17_c1b_full_before_after_reference.png")
    _board((320, 180), EVIDENCE / "2026-07-17_c1b_thumbnail_before_after_reference.png")


if __name__ == "__main__":
    main()
