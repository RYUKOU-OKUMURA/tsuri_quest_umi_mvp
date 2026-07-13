#!/usr/bin/env python3
"""サメ生簀のauthored水槽背景を画面専用素材へ統一処理する。"""

from pathlib import Path

from PIL import Image, ImageEnhance


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tools/source_assets/shark_pen/shark_pen_tank_bg_source.png"
OUTPUT = ROOT / "assets/showcase/shark_pen/tank_environment_bg.png"
OUTPUT_SIZE = (1280, 768)
TARGET_RATIO = OUTPUT_SIZE[0] / OUTPUT_SIZE[1]


def center_crop(image: Image.Image) -> Image.Image:
    width, height = image.size
    ratio = width / height
    if ratio > TARGET_RATIO:
        crop_width = round(height * TARGET_RATIO)
        left = (width - crop_width) // 2
        return image.crop((left, 0, left + crop_width, height))
    crop_height = round(width / TARGET_RATIO)
    top = (height - crop_height) // 2
    return image.crop((0, top, width, top + crop_height))


def main() -> None:
    if not SOURCE.exists():
        raise SystemExit(f"missing source: {SOURCE}")
    image = Image.open(SOURCE).convert("RGB")
    image = center_crop(image).resize(OUTPUT_SIZE, Image.Resampling.LANCZOS)
    image = ImageEnhance.Color(image).enhance(0.78)
    image = ImageEnhance.Contrast(image).enhance(0.96)
    image = ImageEnhance.Brightness(image).enhance(0.80)
    deep_teal = Image.new("RGB", image.size, (4, 28, 47))
    image = Image.blend(image, deep_teal, 0.12)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    image.save(OUTPUT, optimize=True)
    print(OUTPUT)


if __name__ == "__main__":
    main()
