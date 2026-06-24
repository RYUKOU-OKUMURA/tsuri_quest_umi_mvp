#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
REFERENCE = ROOT / "reference" / "02_underwater_fight_mockup.png"
OUTPUT = ROOT / "assets" / "showcase" / "underwater" / "underwater_battle_bg.png"

CANVAS_SIZE = (1672, 941)


def _make_mask(size: tuple[int, int]) -> Image.Image:
    w, h = size
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)

    # Main fish and its outline shadow. The crop cuts through the fish head,
    # so mask past the right edge rather than trusting a centered oval.
    draw.ellipse((w * 0.15, h * 0.25, w * 1.14, h * 0.98), fill=255)
    draw.rectangle((w * 0.28, h * 0.50, w * 1.08, h * 1.04), fill=255)
    draw.polygon(
        (
            (w * 0.25, h * 0.47),
            (w * 0.10, h * 0.34),
            (w * 0.12, h * 0.73),
        ),
        fill=255,
    )

    # Hit burst and text near the lower center.
    draw.ellipse((w * 0.36, h * 0.74, w * 0.73, h * 1.08), fill=255)
    draw.rectangle((w * 0.35, h * 0.80, w * 0.74, h * 1.00), fill=255)

    # Fishing line, lure, and small bait glow.
    draw.line((w * 0.80, -h * 0.04, w * 0.68, h * 0.58), fill=255, width=max(5, int(w * 0.013)))
    draw.ellipse((w * 0.62, h * 0.46, w * 0.73, h * 0.67), fill=255)

    return mask.filter(ImageFilter.GaussianBlur(4.0))


def _remove_runtime_subjects(crop: Image.Image) -> Image.Image:
    rgb = crop.convert("RGB")
    w, h = rgb.size
    fill = Image.new("RGB", rgb.size)
    pixels = fill.load()
    for y in range(h):
        v = y / max(1, h - 1)
        for x in range(w):
            u = x / max(1, w - 1)
            top = (18, 145, 189)
            mid = (7, 107, 164)
            bottom = (14, 74, 105)
            if v < 0.55:
                t = v / 0.55
                base = tuple(round(top[i] * (1.0 - t) + mid[i] * t) for i in range(3))
            else:
                t = (v - 0.55) / 0.45
                base = tuple(round(mid[i] * (1.0 - t) + bottom[i] * t) for i in range(3))
            light = max(0.0, 1.0 - ((u - 0.52) ** 2 + (v - 0.42) ** 2) * 4.0)
            pixels[x, y] = tuple(min(255, round(base[i] + light * (18 if i != 2 else 28))) for i in range(3))

    haze = Image.new("RGBA", rgb.size, (0, 0, 0, 0))
    hd = ImageDraw.Draw(haze, "RGBA")
    hd.rectangle((0, int(h * 0.76), w, h), fill=(4, 79, 104, 24))
    hd.ellipse((int(w * 0.18), int(h * 0.18), int(w * 0.76), int(h * 0.78)), fill=(43, 166, 204, 32))
    fill = fill.convert("RGBA")
    fill.alpha_composite(haze.filter(ImageFilter.GaussianBlur(18)))
    fill = fill.convert("RGB").filter(ImageFilter.GaussianBlur(1.0))

    mask = _make_mask(rgb.size)
    return Image.composite(fill, rgb, mask)


def _expand_to_canvas(image: Image.Image) -> Image.Image:
    # Reference water window is wider than the runtime texture. Fit by height
    # and crop horizontally; this keeps the authored seabed and light scale.
    scale = CANVAS_SIZE[1] / image.height
    scaled_size = (round(image.width * scale), CANVAS_SIZE[1])
    scaled = image.resize(scaled_size, Image.Resampling.LANCZOS)
    left = max(0, (scaled.width - CANVAS_SIZE[0]) // 2)
    return scaled.crop((left, 0, left + CANVAS_SIZE[0], CANVAS_SIZE[1]))


def _harmonize(image: Image.Image) -> Image.Image:
    # The reference crop has UI-adjacent compression and sharp paint edges.
    # Gentle smoothing plus a cool depth glaze makes it function as a clean
    # reusable background under the runtime fish and HUD.
    image = ImageEnhance.Color(image).enhance(0.96)
    image = ImageEnhance.Contrast(image).enhance(1.04)
    softened = image.filter(ImageFilter.GaussianBlur(0.38))
    image = Image.blend(image, softened, 0.18)

    overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay, "RGBA")
    w, h = image.size
    draw.rectangle((0, 0, w, int(h * 0.10)), fill=(0, 20, 42, 22))
    draw.rectangle((0, int(h * 0.78), w, h), fill=(0, 28, 42, 20))
    draw.rectangle((0, 0, int(w * 0.12), h), fill=(0, 20, 38, 18))
    draw.rectangle((int(w * 0.88), 0, w, h), fill=(0, 20, 38, 18))
    image = image.convert("RGBA")
    image.alpha_composite(overlay.filter(ImageFilter.GaussianBlur(28)))
    return image.convert("RGB")


def build() -> None:
    if not REFERENCE.exists():
        raise FileNotFoundError(f"Missing reference: {REFERENCE}")

    reference = Image.open(REFERENCE)
    # The left battle window in the reference, excluding top status and lower HUD.
    crop = reference.crop((0, 88, 760, 426))

    clean_crop = _remove_runtime_subjects(crop)
    background = _expand_to_canvas(clean_crop)
    background = _harmonize(background)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    background.save(OUTPUT, optimize=True)
    print(f"built reference-derived underwater background: {OUTPUT}")


if __name__ == "__main__":
    build()
