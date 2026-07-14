#!/usr/bin/env python3
"""Deterministically process authored fish-market M2 source art.

This processor intentionally writes only the requested M2 slot. The M1 header,
panel frames, layer order, and runtime geometry remain untouched.
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageEnhance, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "tools" / "source_assets" / "fish_market"
OUTPUT_DIR = ROOT / "assets" / "showcase" / "fish_market"
OUTPUT_SIZE = (1280, 720)
DARK_PANEL = (19, 40, 63)
BACKGROUND_SCRIM_ALPHA = 71  # 27.8%; docs/19 §4.5 allows 20–40%.
ICE_TRAY_SAFE_BOX = (746, 202, 1110, 366)
ICE_TRAY_ENVIRONMENT_TINT = 0.10


def save_png_if_pixels_changed(candidate: Image.Image, output_path: Path) -> bool:
    """Preserve existing PNG bytes when decoded pixels are already identical."""
    candidate.load()
    if output_path.is_file():
        with Image.open(output_path) as existing:
            existing.load()
            if (
                existing.size == candidate.size
                and existing.mode == candidate.mode
                and existing.tobytes() == candidate.tobytes()
            ):
                print(f"preserved pixel-identical {output_path}")
                return False

    temporary_path = output_path.with_name(f".{output_path.name}.tmp")
    try:
        candidate.save(
            temporary_path,
            format="PNG",
            optimize=False,
            compress_level=9,
        )
        temporary_path.replace(output_path)
    finally:
        temporary_path.unlink(missing_ok=True)
    print(f"updated {output_path}")
    return True


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
    save_png_if_pixels_changed(image, output_path)
    return output_path


def process_ice_tray_hero() -> Path:
    source_path = SOURCE_DIR / "ice_tray_hero_cutout.png"
    output_path = OUTPUT_DIR / "ice_tray_hero.png"
    with Image.open(source_path) as source:
        cutout = source.convert("RGBA")

    alpha_bbox = cutout.getchannel("A").getbbox()
    if alpha_bbox is None:
        raise ValueError(f"cutout has no visible pixels: {source_path}")
    cutout = cutout.crop(alpha_bbox)

    alpha = cutout.getchannel("A")
    rgb = cutout.convert("RGB")
    tint = Image.new("RGB", rgb.size, DARK_PANEL)
    rgb = Image.blend(rgb, tint, ICE_TRAY_ENVIRONMENT_TINT)
    cutout = rgb.convert("RGBA")
    cutout.putalpha(alpha)

    x0, y0, x1, y1 = ICE_TRAY_SAFE_BOX
    cutout = ImageOps.contain(
        cutout,
        (x1 - x0, y1 - y0),
        method=Image.Resampling.LANCZOS,
    )
    canvas = Image.new("RGBA", OUTPUT_SIZE, (0, 0, 0, 0))
    paste_x = x0 + ((x1 - x0) - cutout.width) // 2
    paste_y = y1 - cutout.height
    canvas.alpha_composite(cutout, (paste_x, paste_y))

    # LANCZOS can leave fully imperceptible alpha=1 key-colored pixels at the
    # edge. Canonicalize those samples to transparent black before shipping.
    pixels = canvas.load()
    for y in range(canvas.height):
        for x in range(canvas.width):
            if pixels[x, y][3] <= 1:
                pixels[x, y] = (0, 0, 0, 0)

    visible_bbox = canvas.getchannel("A").getbbox()
    if visible_bbox is None:
        raise ValueError("processed ice tray is empty")
    if not (
        x0 <= visible_bbox[0]
        and y0 <= visible_bbox[1]
        and visible_bbox[2] <= x1
        and visible_bbox[3] <= y1
    ):
        raise ValueError(f"processed ice tray escaped safe box: {visible_bbox}")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    save_png_if_pixels_changed(canvas, output_path)
    return output_path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("slot", choices=("market_bg", "ice_tray_hero"))
    args = parser.parse_args()

    if args.slot == "market_bg":
        output_path = process_market_bg()
    elif args.slot == "ice_tray_hero":
        output_path = process_ice_tray_hero()
    else:  # pragma: no cover - argparse rejects unsupported slots.
        raise AssertionError(args.slot)
    print(f"processed {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
