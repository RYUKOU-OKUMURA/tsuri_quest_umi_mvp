#!/usr/bin/env python3
"""Build the FIGHT-A1 authored floating-card frame deterministically.

The source and product contain no text or dynamic values. The existing Godot
draw pass remains responsible for fish name, rarity, estimate/reaction and the
action sentence.
"""

from __future__ import annotations

import argparse
import os
import random
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tools/source_assets/underwater/fight_a1_floating_card_frame_source.png"
OUTPUT = ROOT / "assets/showcase/underwater/fight_floating_card_frame.png"
SOURCE_SIZE = (1152, 480)
OUTPUT_SIZE = (288, 120)


def _same_decoded_image(path: Path, candidate: Image.Image) -> bool:
    if not path.is_file():
        return False
    try:
        with Image.open(path) as existing:
            existing.load()
            return (
                existing.mode == candidate.mode
                and existing.size == candidate.size
                and existing.tobytes() == candidate.tobytes()
            )
    except (OSError, ValueError):
        return False


def _save_if_pixels_changed(candidate: Image.Image, output_path: Path) -> bool:
    candidate.load()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    if _same_decoded_image(output_path, candidate):
        print(f"preserved pixel-identical {output_path}")
        return False

    temporary_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            dir=output_path.parent,
            prefix=f".{output_path.stem}.",
            suffix=output_path.suffix,
            delete=False,
        ) as temporary_file:
            temporary_path = Path(temporary_file.name)
        candidate.save(temporary_path, format="PNG", optimize=False, compress_level=9)
        os.replace(temporary_path, output_path)
        temporary_path = None
    finally:
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)
    print(f"updated {output_path}")
    return True


def _paper_texture(size: tuple[int, int]) -> Image.Image:
    rng = random.Random(20260717)
    width, height = size
    pixels = bytearray()
    for y in range(height):
        vertical = round(9 * (y / max(1, height - 1) - 0.5))
        for x in range(width):
            grain = rng.randrange(-7, 8)
            fiber = 3 if (x * 11 + y * 29) % 113 == 0 else 0
            pixels.extend(
                (
                    max(0, min(255, 239 + grain + vertical + fiber)),
                    max(0, min(255, 221 + grain + vertical)),
                    max(0, min(255, 182 + grain + vertical - fiber)),
                    255,
                )
            )
    paper = Image.frombytes("RGBA", size, bytes(pixels))
    fibers = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(fibers)
    for index in range(54):
        y = 18 + (index * 71) % (height - 36)
        x = 20 + (index * 137) % (width - 80)
        length = 30 + (index * 19) % 150
        draw.line((x, y, min(width - 20, x + length), y + (index % 3) - 1), fill=(112, 76, 35, 16), width=1)
    return Image.alpha_composite(paper, fibers.filter(ImageFilter.GaussianBlur(0.45)))


def build_authored_source() -> Image.Image:
    canvas = Image.new("RGBA", SOURCE_SIZE, (0, 0, 0, 0))
    shadow = Image.new("RGBA", SOURCE_SIZE, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle((14, 17, 1138, 466), radius=28, fill=(0, 8, 18, 150))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(10)))

    card_mask = Image.new("L", SOURCE_SIZE, 0)
    ImageDraw.Draw(card_mask).rounded_rectangle((8, 8, 1143, 471), radius=28, fill=255)
    paper = _paper_texture(SOURCE_SIZE)
    canvas.alpha_composite(Image.composite(paper, Image.new("RGBA", SOURCE_SIZE), card_mask))
    draw = ImageDraw.Draw(canvas)

    # Navy rim + restrained double gold line. At product size this resolves to
    # a dark 1px silhouette and a fine gold edge without entering text wells.
    draw.rounded_rectangle((8, 8, 1143, 471), radius=28, outline=(4, 27, 48, 255), width=12)
    draw.rounded_rectangle((13, 13, 1138, 466), radius=24, outline=(118, 75, 22, 255), width=7)
    draw.rounded_rectangle((20, 20, 1131, 459), radius=19, outline=(239, 197, 102, 255), width=4)
    draw.rounded_rectangle((25, 25, 1126, 454), radius=16, outline=(95, 57, 18, 150), width=2)

    # The title band matches the frozen runtime header well: x=8..280,
    # y=8..36 after 4x downsampling.
    band = Image.new("RGBA", SOURCE_SIZE, (0, 0, 0, 0))
    band_draw = ImageDraw.Draw(band)
    band_draw.rounded_rectangle((32, 32, 1119, 143), radius=17, fill=(7, 34, 58, 252))
    band_glaze = Image.new("RGBA", SOURCE_SIZE, (0, 0, 0, 0))
    glaze_draw = ImageDraw.Draw(band_glaze)
    for y in range(40, 138):
        alpha = round(18 * (1.0 - (y - 40) / 98.0))
        glaze_draw.line((46, y, 1105, y), fill=(38, 92, 121, alpha), width=1)
    band = Image.alpha_composite(band, band_glaze)
    band_draw = ImageDraw.Draw(band)
    band_draw.rounded_rectangle((32, 32, 1119, 143), radius=17, outline=(116, 75, 24, 255), width=5)
    band_draw.rounded_rectangle((38, 38, 1113, 137), radius=13, outline=(239, 196, 98, 205), width=3)
    canvas.alpha_composite(band)

    # Quiet authored corner knots: decorative enough to read at 1x, but kept
    # outside the frozen runtime content rectangle.
    for left, top, sx, sy in ((22, 22, 1, 1), (1129, 22, -1, 1), (22, 457, 1, -1), (1129, 457, -1, -1)):
        draw.arc((left - 18, top - 18, left + 18, top + 18), 20 if sx == sy else 110, 250 if sx == sy else 340, fill=(250, 214, 126, 230), width=4)
        draw.ellipse((left - 5, top - 5, left + 5, top + 5), fill=(105, 63, 17, 255), outline=(248, 211, 119, 255), width=2)

    # Subtle paper edge wear makes the card authored while leaving all runtime
    # labels on a calm, high-contrast field.
    wear = Image.new("RGBA", SOURCE_SIZE, (0, 0, 0, 0))
    wear_draw = ImageDraw.Draw(wear)
    for index in range(36):
        x = 42 + (index * 97) % 1060
        y = 157 + (index * 53) % 278
        wear_draw.ellipse((x, y, x + 7 + index % 9, y + 2 + index % 4), fill=(99, 61, 24, 12))
    canvas.alpha_composite(wear.filter(ImageFilter.GaussianBlur(1.1)))
    return canvas


def process(source_path: Path = SOURCE, output_path: Path = OUTPUT) -> Image.Image:
    if not source_path.is_file():
        raise FileNotFoundError(f"FIGHT-A1 source is missing: {source_path}")
    with Image.open(source_path) as source_image:
        source_image.load()
        if source_image.mode != "RGBA" or source_image.size != SOURCE_SIZE:
            raise ValueError(
                f"FIGHT-A1 source must be RGBA {SOURCE_SIZE}, got {source_image.mode} {source_image.size}"
            )
        product = source_image.resize(OUTPUT_SIZE, Image.Resampling.LANCZOS)
    _save_if_pixels_changed(product, output_path)
    return product


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--create-source",
        action="store_true",
        help="write the deterministic authored source before processing it",
    )
    args = parser.parse_args()
    if args.create_source:
        _save_if_pixels_changed(build_authored_source(), SOURCE)
    process()


if __name__ == "__main__":
    main()
