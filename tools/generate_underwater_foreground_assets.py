#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "showcase" / "underwater"


def _rgba(hex_value: str, alpha: int = 255) -> tuple[int, int, int, int]:
    value = hex_value.lstrip("#")
    return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16), alpha)


def _draw_bubble(draw: ImageDraw.ImageDraw, x: float, y: float, r: float, alpha: int) -> None:
    box = (x - r, y - r, x + r, y + r)
    draw.ellipse(box, outline=(214, 248, 255, alpha), width=max(1, int(r * 0.18)))
    draw.arc((x - r * 0.55, y - r * 0.65, x + r * 0.15, y + r * 0.05), 205, 310, fill=(255, 255, 255, min(180, alpha + 28)), width=1)
    if r > 5:
        draw.ellipse((x - r * 0.35, y - r * 0.42, x - r * 0.18, y - r * 0.25), fill=(255, 255, 255, min(160, alpha + 22)))


def create_foreground_ambience() -> None:
    w, h = 1672, 941
    image = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image, "RGBA")
    rng = random.Random(240624)

    # Soft caustic strokes near the bright surface and around the seabed.
    caustics = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    cd = ImageDraw.Draw(caustics, "RGBA")
    for i in range(34):
        y = int(h * (0.07 + rng.random() * 0.23))
        x0 = int(rng.random() * w)
        length = int(90 + rng.random() * 190)
        wave = rng.uniform(-18, 18)
        color = (214, 249, 255, int(26 + rng.random() * 30))
        points: list[tuple[float, float]] = []
        for step in range(7):
            t = step / 6.0
            points.append((x0 + length * t, y + math.sin(t * math.tau + i) * 7 + wave * t))
        cd.line(points, fill=color, width=2)
    for i in range(28):
        y = int(h * (0.76 + rng.random() * 0.16))
        x0 = int(rng.random() * w)
        length = int(70 + rng.random() * 160)
        color = (225, 251, 255, int(14 + rng.random() * 22))
        cd.arc((x0, y, x0 + length, y + 32), 190, 350, fill=color, width=2)
    image.alpha_composite(caustics.filter(ImageFilter.GaussianBlur(radius=0.7)))

    # Bubble columns at the same visual zones as the reference: left rocks, mid distance, right plants.
    columns = [
        (112, 0.72, 42, 38),
        (236, 0.58, 30, 24),
        (1260, 0.50, 28, 22),
        (1514, 0.70, 38, 36),
    ]
    for base_x, height_ratio, spread, count in columns:
        for i in range(count):
            t = i / max(1, count - 1)
            y = h * (0.86 - t * height_ratio) + rng.uniform(-8, 8)
            x = base_x + math.sin(t * 7.0 + base_x * 0.03) * spread * 0.45 + rng.uniform(-spread, spread)
            r = rng.uniform(2.0, 8.0) * (0.85 + t * 0.35)
            alpha = int(60 + t * 92 + rng.random() * 24)
            _draw_bubble(draw, x, y, r, alpha)

    # A few foreground specks around the central water column. Keep them sparse so the fish stays dominant.
    for _ in range(86):
        x = rng.uniform(w * 0.18, w * 0.82)
        y = rng.uniform(h * 0.12, h * 0.72)
        r = rng.choice([1.0, 1.3, 1.6, 2.0])
        alpha = rng.randint(24, 68)
        draw.ellipse((x - r, y - r, x + r, y + r), fill=(213, 247, 255, alpha))

    # Dark far silhouettes add depth without competing with the main kurodai sprite.
    for school_y, count, scale, alpha in (
        (260, 13, 0.75, 72),
        (340, 11, 0.58, 58),
        (508, 9, 0.48, 50),
    ):
        for i in range(count):
            x = 360 + i * rng.uniform(52, 72) + rng.uniform(-10, 16)
            y = school_y + math.sin(i * 1.7) * 18 + rng.uniform(-7, 7)
            body_w = 18 * scale * rng.uniform(0.85, 1.25)
            body_h = 7 * scale * rng.uniform(0.8, 1.15)
            color = (2, 28, 52, alpha)
            draw.ellipse((x - body_w, y - body_h, x + body_w, y + body_h), fill=color)
            draw.polygon(
                [
                    (x - body_w * 0.85, y),
                    (x - body_w * 1.45, y - body_h * 0.82),
                    (x - body_w * 1.45, y + body_h * 0.82),
                ],
                fill=color,
            )

    image.save(OUT_DIR / "underwater_foreground_ambience.png")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    create_foreground_ambience()
    print(f"generated {OUT_DIR / 'underwater_foreground_ambience.png'}")


if __name__ == "__main__":
    main()
