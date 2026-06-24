#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
REFERENCE = ROOT / "reference" / "02_underwater_fight_mockup.png"
OUTPUT = ROOT / "assets" / "showcase" / "underwater" / "underwater_battle_bg.png"

CANVAS_SIZE = (1672, 941)


def _make_full_window_subject_mask(size: tuple[int, int]) -> Image.Image:
    w, h = size
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)

    # The full reference water window preserves the authored left/right reefs
    # and seabed, so only remove the runtime subjects that will be redrawn by
    # Godot: the large kurodai, the hit burst, the line, and the lure.
    draw.ellipse((w * 0.11, h * 0.16, w * 0.66, h * 0.68), fill=255)
    draw.rectangle((w * 0.22, h * 0.28, w * 0.60, h * 0.60), fill=255)
    draw.polygon(((w * 0.23, h * 0.38), (w * 0.10, h * 0.27), (w * 0.11, h * 0.62)), fill=255)
    draw.ellipse((w * 0.48, h * 0.24, w * 0.70, h * 0.62), fill=255)
    draw.polygon(((w * 0.40, h * 0.56), (w * 0.60, h * 0.54), (w * 0.58, h * 0.72), (w * 0.44, h * 0.72)), fill=255)

    draw.ellipse((w * 0.34, h * 0.62, w * 0.76, h * 1.04), fill=255)
    draw.rectangle((w * 0.34, h * 0.70, w * 0.76, h * 0.99), fill=255)

    draw.line((w * 0.91, -h * 0.08, w * 0.68, h * 0.54), fill=255, width=max(58, int(w * 0.062)))
    draw.line((w * 0.84, -h * 0.06, w * 0.67, h * 0.52), fill=255, width=max(46, int(w * 0.050)))
    draw.polygon(
        (
            (w * 0.78, 0.0),
            (w * 0.93, 0.0),
            (w * 0.74, h * 0.56),
            (w * 0.63, h * 0.53),
        ),
        fill=255,
    )
    draw.ellipse((w * 0.61, h * 0.33, w * 0.78, h * 0.58), fill=255)
    return mask.filter(ImageFilter.GaussianBlur(9.0))


def _make_water_fill(size: tuple[int, int]) -> Image.Image:
    w, h = size
    fill = Image.new("RGB", size)
    pixels = fill.load()
    for y in range(h):
        v = y / max(1, h - 1)
        for x in range(w):
            u = x / max(1, w - 1)
            top = (18, 143, 190)
            mid = (7, 107, 164)
            bottom = (9, 72, 105)
            if v < 0.58:
                t = v / 0.58
                base = tuple(round(top[i] * (1.0 - t) + mid[i] * t) for i in range(3))
            else:
                t = (v - 0.58) / 0.42
                base = tuple(round(mid[i] * (1.0 - t) + bottom[i] * t) for i in range(3))
            light = max(0.0, 1.0 - ((u - 0.48) ** 2 + (v - 0.28) ** 2) * 3.0)
            pixels[x, y] = tuple(min(255, round(base[i] + light * (18 if i != 2 else 30))) for i in range(3))
    return fill.filter(ImageFilter.GaussianBlur(1.2))


def _remove_full_window_subjects(crop: Image.Image) -> Image.Image:
    mask = _make_full_window_subject_mask(crop.size)
    clean = Image.composite(_make_water_fill(crop.size), crop.convert("RGB"), mask)

    # A soft blue veil hides the boundary between authored reef pixels and the
    # clean center water while leaving the edges detailed.
    w, h = crop.size
    veil = Image.new("RGBA", crop.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(veil, "RGBA")
    draw.ellipse((int(w * 0.18), int(h * 0.08), int(w * 0.78), int(h * 0.75)), fill=(22, 148, 191, 24))
    clean_rgba = clean.convert("RGBA")
    clean_rgba.alpha_composite(veil.filter(ImageFilter.GaussianBlur(30.0)))
    return clean_rgba.convert("RGB")


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
    # The full authored water window in the reference, excluding top status,
    # lower HUD, and the right sidebar. This keeps the real left/right reefs,
    # seabed, bubbles, and distant fish as the primary background source.
    crop = reference.crop((0, 88, 1215, 660))

    clean_crop = _remove_full_window_subjects(crop)
    background = _expand_to_canvas(clean_crop)
    background = _harmonize(background)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    background.save(OUTPUT, optimize=True)
    print(f"built reference-derived underwater background: {OUTPUT}")


if __name__ == "__main__":
    build()
