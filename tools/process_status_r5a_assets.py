#!/usr/bin/env python3
"""Build the deterministic Status R5-A player medallion portrait."""

from pathlib import Path

from PIL import Image, ImageEnhance, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tools/source_assets/status/status_player_fishing_source.png"
OUTPUT = ROOT / "assets/showcase/status/status_player_fishing_portrait.png"
OUTPUT_SIZE = 256


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
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output.save(output_path, format="PNG", optimize=False, compress_level=9)


if __name__ == "__main__":
    build_portrait()
