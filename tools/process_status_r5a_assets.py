#!/usr/bin/env python3
"""Build the deterministic Status R5-A player medallion portrait."""

import os
import tempfile
from pathlib import Path

from PIL import Image, ImageEnhance, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tools/source_assets/status/status_player_fishing_source.png"
OUTPUT = ROOT / "assets/showcase/status/status_player_fishing_portrait.png"
OUTPUT_SIZE = 256


def _same_decoded_image(path: Path, candidate: Image.Image) -> bool:
    if not path.is_file():
        return False
    try:
        with Image.open(path) as existing_image:
            existing_image.load()
            return (
                existing_image.size == candidate.size
                and existing_image.mode == candidate.mode
                and existing_image.tobytes() == candidate.tobytes()
            )
    except (OSError, ValueError):
        return False


def _save_if_pixels_changed(candidate: Image.Image, output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    if _same_decoded_image(output_path, candidate):
        return

    temp_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            dir=output_path.parent,
            prefix=f".{output_path.stem}.",
            suffix=output_path.suffix,
            delete=False,
        ) as temp_file:
            temp_path = Path(temp_file.name)
        candidate.save(temp_path, format="PNG", optimize=False, compress_level=9)
        os.replace(temp_path, output_path)
        temp_path = None
    finally:
        if temp_path is not None:
            temp_path.unlink(missing_ok=True)


def build_portrait(source_path: Path = SOURCE, output_path: Path = OUTPUT) -> None:
    if not source_path.is_file():
        raise FileNotFoundError(f"status R5-A source is missing: {source_path}")

    with Image.open(source_path) as source_image:
        source = ImageOps.exif_transpose(source_image).convert("RGB")

    side = min(source.size)
    left = (source.width - side) // 2
    top = (source.height - side) // 2
    portrait = source.crop((left, top, left + side, top + side))
    portrait = portrait.resize((OUTPUT_SIZE, OUTPUT_SIZE), Image.Resampling.LANCZOS)
    portrait = ImageEnhance.Color(portrait).enhance(0.90)
    portrait = ImageEnhance.Contrast(portrait).enhance(1.06)
    portrait = portrait.filter(ImageFilter.UnsharpMask(radius=0.8, percent=115, threshold=3))

    # Keep the generated character untouched; PIL only normalizes and creates the
    # screen-local circular alpha silhouette required by the existing medallion.
    mask = Image.new("L", (OUTPUT_SIZE, OUTPUT_SIZE), 0)
    mask_draw = Image.new("L", (OUTPUT_SIZE * 4, OUTPUT_SIZE * 4), 0)
    from PIL import ImageDraw

    draw = ImageDraw.Draw(mask_draw)
    inset = 6 * 4
    draw.ellipse(
        (inset, inset, OUTPUT_SIZE * 4 - inset - 1, OUTPUT_SIZE * 4 - inset - 1),
        fill=255,
    )
    mask = mask_draw.resize((OUTPUT_SIZE, OUTPUT_SIZE), Image.Resampling.LANCZOS)

    output = portrait.convert("RGBA")
    output.putalpha(mask)
    _save_if_pixels_changed(output, output_path)


if __name__ == "__main__":
    build_portrait()
