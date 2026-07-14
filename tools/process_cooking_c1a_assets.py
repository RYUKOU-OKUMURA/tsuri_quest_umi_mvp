#!/usr/bin/env python3
"""Deterministically process the authored COOK_SELECT C1-A kitchen source.

Only the existing cooking-room background slot is written. Runtime geometry,
other cooking states, and all shared UI assets remain outside this processor.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageEnhance


ROOT = Path(__file__).resolve().parents[1]
SOURCE_PATH = ROOT / "tools" / "source_assets" / "cooking" / "c1a_kitchen_bg_source.png"
OUTPUT_PATH = ROOT / "assets" / "showcase" / "cooking" / "cooking_room_bg.png"
OUTPUT_SIZE = (1280, 720)

# Mirrors Palette.DARK_PANEL. The source is also covered by the existing
# runtime COOKING_BG_GLAZE; this lighter baked scrim normalizes generated art
# without flattening the lantern/window read in the narrow visible gutters.
DARK_PANEL = (19, 40, 63)
BACKGROUND_SCRIM_ALPHA = 48  # 18.8%; runtime glaze brings total dimming above 20%.
SOURCE_SATURATION = 0.84
SOURCE_CONTRAST = 0.97
SOURCE_BRIGHTNESS = 0.94


def center_crop_aspect(image: Image.Image, target_size: tuple[int, int]) -> Image.Image:
    target_ratio = target_size[0] / target_size[1]
    source_ratio = image.width / image.height
    if source_ratio > target_ratio:
        crop_width = round(image.height * target_ratio)
        left = (image.width - crop_width) // 2
        return image.crop((left, 0, left + crop_width, image.height))

    crop_height = round(image.width / target_ratio)
    top = (image.height - crop_height) // 2
    return image.crop((0, top, image.width, top + crop_height))


def save_png_if_pixels_changed(candidate: Image.Image, output_path: Path) -> bool:
    """Keep existing PNG bytes when decoded pixels are already identical."""
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

    output_path.parent.mkdir(parents=True, exist_ok=True)
    temporary_path = output_path.with_name(f".{output_path.name}.tmp")
    try:
        candidate.save(temporary_path, format="PNG", optimize=False, compress_level=9)
        temporary_path.replace(output_path)
    finally:
        temporary_path.unlink(missing_ok=True)
    print(f"updated {output_path}")
    return True


def process_kitchen_background() -> Path:
    if not SOURCE_PATH.is_file():
        raise FileNotFoundError(f"missing authored C1-A source: {SOURCE_PATH}")

    with Image.open(SOURCE_PATH) as source:
        image = center_crop_aspect(source.convert("RGB"), OUTPUT_SIZE)
        image = image.resize(OUTPUT_SIZE, Image.Resampling.LANCZOS)
        image = ImageEnhance.Color(image).enhance(SOURCE_SATURATION)
        image = ImageEnhance.Contrast(image).enhance(SOURCE_CONTRAST)
        image = ImageEnhance.Brightness(image).enhance(SOURCE_BRIGHTNESS)
        image = image.convert("RGBA")

    scrim = Image.new("RGBA", OUTPUT_SIZE, (*DARK_PANEL, BACKGROUND_SCRIM_ALPHA))
    image = Image.alpha_composite(image, scrim)
    save_png_if_pixels_changed(image, OUTPUT_PATH)
    return OUTPUT_PATH


def main() -> None:
    output = process_kitchen_background()
    print(output)


if __name__ == "__main__":
    main()
