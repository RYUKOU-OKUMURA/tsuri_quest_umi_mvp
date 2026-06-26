#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
REFERENCE = ROOT / "reference" / "02_underwater_fight_mockup.png"
OUT = ROOT / "assets" / "showcase" / "underwater" / "top_status_icon_sheet.png"


def _foreground_alpha(pixel: tuple[int, int, int, int]) -> int:
    r, g, b, _ = pixel
    # The source top bar uses cream parchment behind the icons. Keep dark ink,
    # saturated gold/orange fills, and soft anti-aliased edges; discard paper.
    saturation = max(r, g, b) - min(r, g, b)
    paper = r > 185 and g > 168 and b > 126 and saturation < 62
    if paper:
        return 0
    dark = max(0, 186 - min(r, g, b))
    saturated = max(0, saturation - 36) * 4
    alpha = max(dark * 2, saturated)
    return max(0, min(255, alpha))


def _extract_icon(source: Image.Image, box: tuple[int, int, int, int], size: int, *, padding: int = 14) -> Image.Image:
    crop = source.crop(box).convert("RGBA")
    alpha = Image.new("L", crop.size, 0)
    alpha.putdata([_foreground_alpha(pixel) for pixel in crop.getdata()])
    alpha = alpha.filter(ImageFilter.GaussianBlur(0.25))
    crop.putalpha(alpha)

    bbox = alpha.point(lambda value: 255 if value > 14 else 0).getbbox()
    if bbox is None:
        return Image.new("RGBA", (size, size), (0, 0, 0, 0))
    crop = crop.crop(bbox)
    scale = min((size - padding) / crop.width, (size - padding) / crop.height)
    resized = crop.resize((round(crop.width * scale), round(crop.height * scale)), Image.Resampling.LANCZOS)
    resized = ImageEnhance.Contrast(resized).enhance(1.02)
    resized = resized.filter(ImageFilter.SMOOTH)
    resized = resized.filter(ImageFilter.UnsharpMask(radius=0.7, percent=70, threshold=3))
    resized.putalpha(resized.getchannel("A").point(lambda value: 0 if value < 12 else min(255, int(value * 0.98))))
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.alpha_composite(resized, ((size - resized.width) // 2, (size - resized.height) // 2))
    return canvas


def main() -> None:
    source = Image.open(REFERENCE).convert("RGBA")
    cell = 128
    icons = [
        # clock, sun, wind, coin in the visual order used by FightStatusBar.
        ((34, 22, 78, 68), 6),
        ((316, 22, 362, 68), 6),
        ((466, 24, 515, 65), 14),
        ((692, 22, 741, 68), 6),
    ]
    sheet = Image.new("RGBA", (cell * len(icons), cell), (0, 0, 0, 0))
    for i, (box, padding) in enumerate(icons):
        sheet.alpha_composite(_extract_icon(source, box, cell, padding=padding), (i * cell, 0))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT)
    print(OUT)


if __name__ == "__main__":
    main()
