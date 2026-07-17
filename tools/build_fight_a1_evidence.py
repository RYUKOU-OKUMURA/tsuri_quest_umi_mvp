#!/usr/bin/env python3
"""Validate fresh FIGHT-A1 captures and build permanent evidence boards."""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path

from PIL import Image, ImageChops, ImageStat

from process_fight_a1_floating_card import _save_if_pixels_changed


ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ROOT / "docs/qa/evidence/underwater_fight"
BASE_BEFORE = EVIDENCE / "2026-07-17_fight_a1_base_6d37322b_recapture.png"
BEFORE = EVIDENCE / "2026-07-17_fight_a1_standard_before.png"
AFTER = EVIDENCE / "2026-07-17_fight_a1_standard_after.png"
FOCUS = EVIDENCE / "2026-07-17_fight_a1_focus_regression.png"
REFERENCE = ROOT / "reference" / "14_underwater_fight_simple_mockup.png"
DEFAULT_AFTER_CAPTURE = Path("/tmp/tsuri_fishing_fight.png")
DEFAULT_FOCUS_CAPTURE = Path("/tmp/tsuri_fishing_fight_focus.png")
BASE_BEFORE_DECODED_SHA256 = "1791a4a46abd9d937844cee719842391351c339cad970c34b1d75f9042f27372"
AFTER_DECODED_SHA256 = "2c265b09f3f7ccc15d2a5b81a868af45c83c91fd703a8fda07ee6d0cab8cdc30"
FOCUS_DECODED_SHA256 = "ee6027f2378cb95b00db9560f27d8854987d52c1888d5818c0be557740abd626"
CARD_DIFF_BOX = (950, 105, 1247, 235)
EXPECTED_FULL_DIFF_BOX = (953, 109, 1243, 231)
REFERENCE_CARD_BOX = (1134, 112, 1532, 410)
EXPECTED_FOCUS_RING_DIFF_BOX = (443, 628, 636, 692)
EXPECTED_FOCUS_RING_DIFF_PIXELS = 1961
UNDERWATER_SIGNATURE_BOX = (25, 100, 250, 300)


def _opened(path: Path) -> Image.Image:
    with Image.open(path) as image:
        image.load()
        return image.convert("RGB")


def _decoded_sha256(image: Image.Image) -> str:
    return hashlib.sha256(image.convert("RGB").tobytes()).hexdigest()


def _validate_runtime_capture(image: Image.Image, path: Path) -> None:
    if image.size != (1280, 720):
        raise ValueError(f"FIGHT-A1 capture must be 1280x720: {path} {image.size}")
    visible = sum(1 for pixel in image.getdata() if sum(pixel) > 48)
    if visible < int(image.width * image.height * 0.75):
        raise ValueError(f"FIGHT-A1 capture is black or incomplete: {path} visible={visible}")
    # Global visibility alone misses the renderer failure where individual
    # header/HUD panels become black rectangles. Scan local tiles as well.
    for top in range(0, image.height, 48):
        for left in range(0, image.width, 64):
            tile = image.crop((left, top, min(left + 64, image.width), min(top + 48, image.height)))
            pixels = list(tile.getdata())
            near_black = sum(1 for pixel in pixels if max(pixel) <= 8)
            if near_black > int(len(pixels) * 0.35):
                raise ValueError(
                    f"FIGHT-A1 capture contains a local black/incomplete tile: {path} tile=({left},{top})"
                )


def _validate_focus_capture(
    focus: Image.Image,
    base: Image.Image,
    standard_after: Image.Image,
    path: Path,
) -> None:
    _validate_runtime_capture(focus, path)
    if _decoded_sha256(focus) != FOCUS_DECODED_SHA256:
        raise ValueError("FIGHT-A1 focus is not the reviewed same-fixture reel-focus capture")

    # A stable FIGHT capture shares the frozen underwater background in this
    # fish/card-free patch. Surface-state or transition captures diverge sharply.
    focus_signature = focus.crop(UNDERWATER_SIGNATURE_BOX)
    base_signature = base.crop(UNDERWATER_SIGNATURE_BOX)
    signature_mean = sum(ImageStat.Stat(ImageChops.difference(focus_signature, base_signature)).mean) / 3.0
    if signature_mean > 28.0:
        raise ValueError(
            f"focus evidence is not the stable underwater FIGHT state: {path} signature_mean={signature_mean:.2f}"
        )

    # Focus and standard use the same fish/data/time fixture. Their only pixels
    # allowed to differ are the common 4px ring around the reel action.
    focus_difference = ImageChops.difference(focus, standard_after)
    focus_bbox = focus_difference.getbbox()
    focus_pixels = sum(pixel != (0, 0, 0) for pixel in focus_difference.getdata())
    if focus_bbox != EXPECTED_FOCUS_RING_DIFF_BOX or focus_pixels != EXPECTED_FOCUS_RING_DIFF_PIXELS:
        raise ValueError(
            "focus evidence does not have the reviewed reel-ring-only signature: "
            f"{path} bbox={focus_bbox} pixels={focus_pixels}"
        )
    action_labels = focus.crop((515, 635, 825, 685))
    readable_label_pixels = sum(
        1 for r, g, b in action_labels.getdata() if r >= 180 and g >= 150 and b >= 90
    )
    if readable_label_pixels < 500:
        raise ValueError(
            f"focus evidence does not show readable FIGHT action labels: {path} pixels={readable_label_pixels}"
        )


def main(base_capture_path: Path, after_capture_path: Path, focus_capture_path: Path) -> None:
    base_before = _opened(base_capture_path)
    if _decoded_sha256(base_before) != BASE_BEFORE_DECODED_SHA256:
        raise ValueError(
            "FIGHT-A1 before is not base 6d37322b rendered with the reviewed deterministic fixture"
        )
    after = _opened(after_capture_path)
    focus = _opened(focus_capture_path)
    reference = _opened(REFERENCE)
    _validate_runtime_capture(after, after_capture_path)
    if _decoded_sha256(after) != AFTER_DECODED_SHA256:
        raise ValueError("FIGHT-A1 after is not the reviewed TIP deterministic fixture")
    _validate_focus_capture(focus, base_before, after, focus_capture_path)

    difference = ImageChops.difference(base_before, after)
    full_bbox = difference.getbbox()
    if full_bbox != EXPECTED_FULL_DIFF_BOX:
        raise ValueError(
            f"FIGHT-A1 base-to-TIP full diff is not the reviewed card change: {full_bbox}"
        )
    outside = difference.copy()
    outside.paste((0, 0, 0), CARD_DIFF_BOX)
    if outside.getbbox() is not None:
        raise ValueError(
            f"FIGHT-A1 changed base 6d37322b pixels outside the floating card: {outside.getbbox()}"
        )

    _save_if_pixels_changed(base_before.convert("RGBA"), BASE_BEFORE)
    _save_if_pixels_changed(base_before.convert("RGBA"), BEFORE)
    _save_if_pixels_changed(after.convert("RGBA"), AFTER)
    _save_if_pixels_changed(focus.convert("RGBA"), FOCUS)

    original_board = Image.new("RGB", (2560, 720), (5, 17, 29))
    original_board.paste(base_before, (0, 0))
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

    before_card = base_before.crop(CARD_DIFF_BOX).resize((288, 120), Image.Resampling.LANCZOS)
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
    print(f"FIGHT-A1 canonical before: base 6d37322b decoded={BASE_BEFORE_DECODED_SHA256}")
    print(f"FIGHT-A1 canonical after: TIP decoded={AFTER_DECODED_SHA256}")
    print(f"FIGHT-A1 base-to-TIP full diff: {EXPECTED_FULL_DIFF_BOX}; outside-card pixel diff: 0")
    print(
        "FIGHT-A1 focus evidence: stable underwater FIGHT + reel-ring-only diff "
        f"{EXPECTED_FOCUS_RING_DIFF_BOX}/{EXPECTED_FOCUS_RING_DIFF_PIXELS}px decoded={FOCUS_DECODED_SHA256}"
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--base",
        type=Path,
        required=True,
        help="fresh base 6d37322b capture made with the same fishing_fight_preview.gd fixture",
    )
    parser.add_argument("--after", type=Path, default=DEFAULT_AFTER_CAPTURE)
    parser.add_argument("--focus", type=Path, default=DEFAULT_FOCUS_CAPTURE)
    arguments = parser.parse_args()
    main(arguments.base, arguments.after, arguments.focus)
