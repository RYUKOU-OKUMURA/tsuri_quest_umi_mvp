#!/usr/bin/env python3
"""Build and deterministically process COOK-C1B recipe-card surfaces.

The committed 2x sources are the authored geometric masters. Normal/selected
paper, wood and gold framing live in the full-card PNGs; the shared navy title
band is a separate PNG so Japanese recipe names remain runtime-drawn.
"""

from __future__ import annotations

import argparse
import hashlib
import os
from pathlib import Path
import tempfile

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "tools" / "source_assets" / "cooking"
OUTPUT_DIR = ROOT / "assets" / "showcase" / "cooking"

SLOTS = {
    "c1b_recipe_card_frame_source.png": ("recipe_card_frame.png", (280, 220)),
    "c1b_recipe_selected_card_frame_source.png": (
        "recipe_selected_card_frame.png",
        (280, 220),
    ),
    "c1b_recipe_title_band_source.png": ("recipe_title_band.png", (280, 62)),
}


def _paper_texture(size: tuple[int, int]) -> Image.Image:
    width, height = size
    image = Image.new("RGBA", size, (235, 216, 169, 255))
    pixels = image.load()
    for y in range(height):
        for x in range(width):
            grain = ((x * 17 + y * 31 + (x * y) % 19) % 15) - 7
            wave = ((x // 29 + y // 17) % 5) - 2
            pixels[x, y] = (
                max(0, min(255, 235 + grain + wave)),
                max(0, min(255, 216 + grain)),
                max(0, min(255, 169 + grain // 2)),
                255,
            )
    draw = ImageDraw.Draw(image, "RGBA")
    for index in range(34):
        y = 18 + ((index * 47) % max(1, height - 36))
        x = 22 + ((index * 83) % max(1, width - 100))
        length = 34 + (index * 13) % 88
        draw.line((x, y, min(width - 20, x + length), y + index % 3 - 1), fill=(112, 75, 35, 22), width=1)
    return image


def _draw_card_source(selected: bool) -> Image.Image:
    size = (560, 440)
    paper = _paper_texture(size)
    image = Image.new("RGBA", size, (0, 0, 0, 0))

    if selected:
        glow = Image.new("RGBA", size, (0, 0, 0, 0))
        glow_draw = ImageDraw.Draw(glow, "RGBA")
        glow_draw.rounded_rectangle((8, 8, 551, 431), radius=31, outline=(255, 204, 63, 225), width=20)
        glow = glow.filter(ImageFilter.GaussianBlur(8.0))
        image.alpha_composite(glow)

    # Opaque parchment field keeps locked/unavailable modulation predictable.
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((18, 14, 541, 425), radius=25, fill=255)
    image.paste(paper, (0, 0), mask)
    draw = ImageDraw.Draw(image, "RGBA")

    # Restrained dark wood shell, then two hairline gold trims.
    draw.rounded_rectangle((12, 10, 547, 429), radius=28, outline=(62, 34, 18, 255), width=13)
    draw.rounded_rectangle((22, 20, 537, 419), radius=21, outline=(132, 79, 31, 255), width=8)
    draw.rounded_rectangle((29, 27, 530, 412), radius=17, outline=(225, 177, 72, 255), width=4)
    draw.rounded_rectangle((35, 33, 524, 406), radius=14, outline=(92, 54, 25, 210), width=2)

    # Small joinery marks add authored rhythm without competing with dish art.
    for x in (49, 511):
        draw.line((x - 12, 49, x + 12, 49), fill=(244, 205, 112, 235), width=3)
        draw.line((x, 39, x, 59), fill=(244, 205, 112, 235), width=3)
        draw.ellipse((x - 4, 45, x + 4, 53), fill=(75, 41, 19, 255), outline=(244, 205, 112, 255), width=2)

    if selected:
        draw.rounded_rectangle((25, 23, 534, 416), radius=20, outline=(255, 221, 111, 255), width=6)
        draw.line((78, 31, 482, 31), fill=(255, 238, 156, 255), width=3)
        draw.line((78, 408, 482, 408), fill=(255, 238, 156, 255), width=3)

    return image


def _draw_title_band_source() -> Image.Image:
    size = (560, 124)
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image, "RGBA")
    draw.rounded_rectangle((8, 9, 551, 114), radius=20, fill=(43, 24, 14, 245))
    draw.rounded_rectangle((16, 13, 543, 109), radius=16, fill=(12, 37, 58, 255), outline=(224, 175, 70, 255), width=5)
    draw.rounded_rectangle((25, 21, 534, 101), radius=12, outline=(114, 75, 34, 255), width=3)
    # Quiet woven navy grain; no text or symbolic content is baked in.
    for y in range(29, 96, 7):
        draw.line((40, y, 520, y), fill=(55, 86, 100, 34), width=2)
    draw.line((52, 26, 508, 26), fill=(248, 211, 119, 170), width=2)
    draw.line((52, 97, 508, 97), fill=(4, 18, 31, 220), width=2)
    for x in (34, 526):
        draw.polygon(((x, 51), (x + 9, 62), (x, 73), (x - 9, 62)), fill=(224, 175, 70, 255))
        draw.polygon(((x, 56), (x + 5, 62), (x, 68), (x - 5, 62)), fill=(91, 50, 23, 255))
    return image


def _atomic_save_if_changed(candidate: Image.Image, path: Path) -> bool:
    candidate = candidate.convert("RGBA")
    candidate.load()
    if path.is_file():
        with Image.open(path) as existing:
            existing = existing.convert("RGBA")
            existing.load()
            if existing.size == candidate.size and existing.tobytes() == candidate.tobytes():
                print(f"preserved pixel-identical {path}")
                return False

    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temp_name = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=path.parent)
    temp_path = Path(temp_name)
    try:
        with os.fdopen(descriptor, "wb") as stream:
            candidate.save(stream, format="PNG", optimize=False, compress_level=9)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temp_path, path)
    finally:
        temp_path.unlink(missing_ok=True)
    print(f"updated {path}")
    return True


def refresh_sources() -> None:
    _atomic_save_if_changed(_draw_card_source(False), SOURCE_DIR / "c1b_recipe_card_frame_source.png")
    _atomic_save_if_changed(_draw_card_source(True), SOURCE_DIR / "c1b_recipe_selected_card_frame_source.png")
    _atomic_save_if_changed(_draw_title_band_source(), SOURCE_DIR / "c1b_recipe_title_band_source.png")


def process_outputs() -> None:
    for source_name, (output_name, output_size) in SLOTS.items():
        source_path = SOURCE_DIR / source_name
        if not source_path.is_file():
            raise FileNotFoundError(f"missing authored C1-B source: {source_path}")
        with Image.open(source_path) as source:
            candidate = source.convert("RGBA").resize(output_size, Image.Resampling.LANCZOS)
        _atomic_save_if_changed(candidate, OUTPUT_DIR / output_name)


def _digest(path: Path) -> tuple[str, str]:
    file_hash = hashlib.sha256(path.read_bytes()).hexdigest()
    with Image.open(path) as image:
        decoded_hash = hashlib.sha256(image.convert("RGBA").tobytes()).hexdigest()
    return file_hash, decoded_hash


def verify_twice() -> None:
    process_outputs()
    first = {name: _digest(OUTPUT_DIR / output_name) for name, (output_name, _) in SLOTS.items()}
    process_outputs()
    second = {name: _digest(OUTPUT_DIR / output_name) for name, (output_name, _) in SLOTS.items()}
    if first != second:
        raise RuntimeError("C1-B processor changed file or decoded hashes on its second run")
    for source_name, (output_name, _) in SLOTS.items():
        file_hash, decoded_hash = second[source_name]
        print(f"deterministic {output_name} file={file_hash} decoded={decoded_hash}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--refresh-sources", action="store_true")
    parser.add_argument("--verify-twice", action="store_true")
    args = parser.parse_args()
    if args.refresh_sources:
        refresh_sources()
    if args.verify_twice:
        verify_twice()
    else:
        process_outputs()


if __name__ == "__main__":
    main()
