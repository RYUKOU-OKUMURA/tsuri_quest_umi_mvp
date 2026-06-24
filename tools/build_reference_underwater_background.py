#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
REFERENCE = ROOT / "reference" / "02_underwater_fight_mockup.png"
OUTPUT = ROOT / "assets" / "showcase" / "underwater" / "underwater_battle_bg.png"

CANVAS_SIZE = (1672, 941)


def _draw_polyline(
    draw: ImageDraw.ImageDraw,
    points: list[tuple[float, float]],
    fill: tuple[int, int, int, int],
    width: int,
) -> None:
    if len(points) >= 2:
        draw.line(points, fill=fill, width=width, joint="curve")


def _draw_seaweed(
    draw: ImageDraw.ImageDraw,
    x: float,
    y: float,
    height: float,
    color: tuple[int, int, int, int],
    lean: float,
    width: int,
) -> None:
    points: list[tuple[float, float]] = []
    for step in range(8):
        t = step / 7.0
        points.append((x + math.sin(t * math.pi * 1.55) * 8.0 + lean * t, y - height * t))
    _draw_polyline(draw, points, color, width)
    for step in (2, 3, 4, 5, 6):
        px, py = points[step]
        side = -1 if step % 2 == 0 else 1
        draw.line(
            (px, py, px + side * height * 0.13, py - height * 0.09),
            fill=(color[0], color[1], color[2], max(20, color[3] - 16)),
            width=max(1, width - 1),
        )


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


def _add_masked_area_detail(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    w, h = image.size
    rng = random.Random(240628)

    layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer, "RGBA")

    # Keep the runtime fish zone quiet, then restore reference-like seabed and
    # side density below it so the masked center does not read as an empty wall.
    for i in range(64):
        x = rng.uniform(w * 0.24, w * 0.92)
        y = rng.uniform(h * 0.67, h * 0.90)
        length = rng.uniform(48, 170)
        amp = rng.uniform(3, 9)
        points: list[tuple[float, float]] = []
        for step in range(7):
            t = step / 6.0
            points.append((x + length * t, y + math.sin(t * math.tau + i * 0.5) * amp))
        _draw_polyline(draw, points, (203, 246, 230, rng.randint(20, 44)), rng.choice((1, 1, 2)))

    rock_groups = (
        (w * 0.76, h * 0.79, w * 0.18, 7),
        (w * 0.90, h * 0.70, w * 0.16, 9),
        (w * 0.54, h * 0.90, w * 0.12, 5),
    )
    for cx, cy, spread, count in rock_groups:
        for index in range(count):
            x = cx + rng.uniform(-spread * 0.5, spread * 0.5)
            y = cy + rng.uniform(-h * 0.05, h * 0.06)
            rx = rng.uniform(32, 92) * (1.0 - index * 0.025)
            ry = rng.uniform(16, 46)
            draw.ellipse((x - rx, y - ry, x + rx, y + ry), fill=(2, 38, 55, rng.randint(46, 86)))
            draw.ellipse((x - rx * 0.70, y - ry * 0.82, x + rx * 0.25, y + ry * 0.05), fill=(71, 126, 116, rng.randint(28, 54)))
            draw.arc((x - rx * 0.65, y - ry * 0.85, x + rx * 0.55, y + ry * 0.35), 198, 340, fill=(162, 220, 178, rng.randint(24, 44)), width=2)

    clusters = (
        (w * 0.34, h * 0.91, w * 0.16, 18),
        (w * 0.78, h * 0.88, w * 0.18, 20),
        (w * 0.91, h * 0.84, w * 0.12, 24),
    )
    for cx, base_y, spread, count in clusters:
        for _ in range(count):
            x = cx + rng.uniform(-spread * 0.5, spread * 0.5)
            height = rng.uniform(52, 160)
            pick = rng.random()
            if pick < 0.66:
                color = (42, rng.randint(118, 176), rng.randint(88, 132), rng.randint(64, 118))
            elif pick < 0.86:
                color = (108, rng.randint(116, 154), 58, rng.randint(52, 92))
            else:
                color = (178, rng.randint(70, 104), rng.randint(96, 132), rng.randint(44, 80))
            _draw_seaweed(draw, x, base_y + rng.uniform(-20, 18), height, color, rng.uniform(-22, 20), rng.choice((2, 2, 3)))

    for row, (y, count, scale, alpha) in enumerate(
        ((h * 0.25, 10, 0.70, 48), (h * 0.35, 9, 0.56, 40), (h * 0.45, 7, 0.46, 34))
    ):
        for i in range(count):
            x = w * 0.54 + i * rng.uniform(44, 66) + rng.uniform(-10, 16)
            yy = y + math.sin(i * 1.6 + row) * 16.0 + rng.uniform(-5, 5)
            bw = 15.0 * scale * rng.uniform(0.8, 1.2)
            bh = bw * 0.32
            color = (2, 30, 52, alpha)
            draw.ellipse((x - bw, yy - bh, x + bw, yy + bh), fill=color)
            draw.polygon(((x - bw * 0.85, yy), (x - bw * 1.38, yy - bh * 0.85), (x - bw * 1.38, yy + bh * 0.85)), fill=color)

    for _ in range(46):
        x = rng.uniform(w * 0.20, w * 0.88)
        y = rng.uniform(h * 0.78, h * 0.93)
        rx = rng.uniform(4, 14)
        ry = rng.uniform(2, 6)
        draw.ellipse((x - rx, y - ry, x + rx, y + ry), fill=(3, 41, 55, rng.randint(24, 46)))

    image.alpha_composite(layer.filter(ImageFilter.GaussianBlur(0.45)))

    depth = Image.new("RGBA", image.size, (0, 0, 0, 0))
    dd = ImageDraw.Draw(depth, "RGBA")
    dd.rectangle((0, int(h * 0.82), w, h), fill=(0, 33, 43, 18))
    dd.rectangle((int(w * 0.84), int(h * 0.34), w, h), fill=(0, 31, 49, 14))
    image.alpha_composite(depth.filter(ImageFilter.GaussianBlur(22)))
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
    background = _add_masked_area_detail(background)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    background.save(OUTPUT, optimize=True)
    print(f"built reference-derived underwater background: {OUTPUT}")


if __name__ == "__main__":
    build()
