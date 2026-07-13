#!/usr/bin/env python3
"""Deterministically process authored fish-market M2 source art.

This processor intentionally writes only the requested M2 slot. The M1 header,
panel frames, layer order, and runtime geometry remain untouched.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageEnhance


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "tools" / "source_assets" / "fish_market"
OUTPUT_DIR = ROOT / "assets" / "showcase" / "fish_market"
OUTPUT_SIZE = (1280, 720)
DARK_PANEL = (19, 40, 63)
BACKGROUND_SCRIM_ALPHA = 71  # 27.8%; docs/19 §4.5 allows 20–40%.


def center_crop_aspect(image: Image.Image, target_size: tuple[int, int]) -> Image.Image:
    target_ratio = target_size[0] / target_size[1]
    source_ratio = image.width / image.height
    if source_ratio > target_ratio:
        crop_width = round(image.height * target_ratio)
        left = (image.width - crop_width) // 2
        box = (left, 0, left + crop_width, image.height)
    else:
        crop_height = round(image.width / target_ratio)
        top = (image.height - crop_height) // 2
        box = (0, top, image.width, top + crop_height)
    return image.crop(box)


def process_market_bg() -> Path:
    source_path = SOURCE_DIR / "market_bg_source.png"
    output_path = OUTPUT_DIR / "market_bg.png"
    with Image.open(source_path) as source:
        image = center_crop_aspect(source.convert("RGB"), OUTPUT_SIZE)
        image = image.resize(OUTPUT_SIZE, Image.Resampling.LANCZOS)
        image = ImageEnhance.Color(image).enhance(0.90)
        image = image.convert("RGBA")

    # The authored background stays visible at the margins while the stable M1
    # panels remain readable over a palette-owned navy scrim.
    scrim = Image.new("RGBA", OUTPUT_SIZE, (*DARK_PANEL, BACKGROUND_SCRIM_ALPHA))
    image = Image.alpha_composite(image, scrim)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    image.save(output_path, format="PNG", optimize=False, compress_level=9)
    return output_path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("slot", choices=("market_bg",))
    args = parser.parse_args()

    if args.slot == "market_bg":
        output_path = process_market_bg()
    else:  # pragma: no cover - argparse rejects unsupported slots.
        raise AssertionError(args.slot)
    print(f"processed {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
