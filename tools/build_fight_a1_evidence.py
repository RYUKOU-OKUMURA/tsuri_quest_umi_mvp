#!/usr/bin/env python3
"""Validate and build the permanent FIGHT-A1 visual evidence boards."""

from pathlib import Path

from PIL import Image, ImageChops

from process_fight_a1_floating_card import _save_if_pixels_changed


ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ROOT / "docs/qa/evidence/underwater_fight"
BEFORE = EVIDENCE / "2026-07-17_fight_a1_standard_before.png"
AFTER = EVIDENCE / "2026-07-17_fight_a1_standard_after.png"
REFERENCE = ROOT / "reference" / "14_underwater_fight_simple_mockup.png"
CARD_DIFF_BOX = (950, 105, 1247, 235)
REFERENCE_CARD_BOX = (1134, 112, 1532, 410)


def _opened(path: Path) -> Image.Image:
    with Image.open(path) as image:
        image.load()
        return image.convert("RGB")


def main() -> None:
    before = _opened(BEFORE)
    after = _opened(AFTER)
    reference = _opened(REFERENCE)
    if before.size != (1280, 720) or after.size != before.size:
        raise ValueError(f"FIGHT-A1 captures must be 1280x720: {before.size=} {after.size=}")

    difference = ImageChops.difference(before, after)
    outside = difference.copy()
    outside.paste((0, 0, 0), CARD_DIFF_BOX)
    if outside.getbbox() is not None:
        raise ValueError(f"FIGHT-A1 changed pixels outside the floating-card fixture: {outside.getbbox()}")

    original_board = Image.new("RGB", (2560, 720), (5, 17, 29))
    original_board.paste(before, (0, 0))
    original_board.paste(after, (1280, 0))
    _save_if_pixels_changed(
        original_board.convert("RGBA"),
        EVIDENCE / "2026-07-17_fight_a1_standard_before_after.png",
    )

    after_small = after.resize((320, 180), Image.Resampling.LANCZOS)
    reference_small = reference.resize((320, 180), Image.Resampling.LANCZOS)
    small_board = Image.new("RGB", (640, 180), (5, 17, 29))
    small_board.paste(after_small, (0, 0))
    small_board.paste(reference_small, (320, 0))
    _save_if_pixels_changed(
        small_board.convert("RGBA"),
        EVIDENCE / "2026-07-17_fight_a1_after_reference_320x180.png",
    )

    before_card = before.crop(CARD_DIFF_BOX).resize((288, 120), Image.Resampling.LANCZOS)
    after_card = after.crop(CARD_DIFF_BOX).resize((288, 120), Image.Resampling.LANCZOS)
    reference_card = reference.crop(REFERENCE_CARD_BOX).resize((288, 120), Image.Resampling.LANCZOS)
    card_board = Image.new("RGB", (864, 120), (5, 17, 29))
    card_board.paste(before_card, (0, 0))
    card_board.paste(after_card, (288, 0))
    card_board.paste(reference_card, (576, 0))
    _save_if_pixels_changed(
        card_board.convert("RGBA"),
        EVIDENCE / "2026-07-17_fight_a1_card_before_after_reference.png",
    )
    print("FIGHT-A1 outside-card pixel diff: 0")


if __name__ == "__main__":
    main()
