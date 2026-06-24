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


def create_color_grade() -> None:
    w, h = 1672, 941
    image = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image, "RGBA")

    # Broad edge and depth vignette. This reins in the clean generated
    # background without baking over the fish or hit burst.
    for y in range(h):
        v = y / max(1, h - 1)
        for x in range(w):
            u = x / max(1, w - 1)
            edge = max(abs(u - 0.5) * 2.0, abs(v - 0.48) * 1.20)
            lower = max(0.0, (v - 0.58) / 0.42)
            alpha = int(max(0.0, edge - 0.42) * 58 + lower * 34)
            if alpha <= 0:
                continue
            # Navy/teal, not pure black, so it feels like depth rather than a dirty overlay.
            image.putpixel((x, y), (2, 24, 45, min(82, alpha)))

    # Slightly dim the immediate HUD-adjacent seabed so the operation board reads cleaner.
    seabed_shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(seabed_shadow, "RGBA")
    sd.rectangle((0, int(h * 0.76), w, h), fill=(0, 18, 34, 42))
    image.alpha_composite(seabed_shadow.filter(ImageFilter.GaussianBlur(34)))

    # Reference-like surface glow and a few authored light shafts. These are subtle;
    # the base background still owns the illustration detail.
    light = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ld = ImageDraw.Draw(light, "RGBA")
    ld.ellipse((int(w * 0.18), -int(h * 0.18), int(w * 0.78), int(h * 0.28)), fill=(198, 248, 255, 30))
    for i, x in enumerate((260, 430, 620, 850, 1080)):
        width = 80 + i * 14
        ld.polygon(
            [
                (x - width, 0),
                (x + width, 0),
                (x + width * 1.6, int(h * 0.55)),
                (x - width * 0.55, int(h * 0.56)),
            ],
            fill=(178, 238, 255, 16 if i % 2 == 0 else 11),
        )
    image.alpha_composite(light.filter(ImageFilter.GaussianBlur(14)))

    # Darken the very top corners where the reference frame feels more enclosed.
    corner = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    cd = ImageDraw.Draw(corner, "RGBA")
    cd.rectangle((0, 0, w, int(h * 0.10)), fill=(0, 13, 27, 28))
    cd.rectangle((0, 0, int(w * 0.10), h), fill=(0, 13, 27, 18))
    cd.rectangle((int(w * 0.90), 0, w, h), fill=(0, 13, 27, 18))
    image.alpha_composite(corner.filter(ImageFilter.GaussianBlur(20)))

    image.save(OUT_DIR / "underwater_color_grade.png")


def _draw_seaweed(draw: ImageDraw.ImageDraw, base_x: float, base_y: float, height: float, color: tuple[int, int, int, int], lean: float) -> None:
    points: list[tuple[float, float]] = []
    for step in range(7):
        t = step / 6.0
        x = base_x + math.sin(t * math.pi * 1.35) * 7.0 + lean * t
        y = base_y - height * t
        points.append((x, y))
    draw.line(points, fill=color, width=3)
    for step in (2, 3, 4, 5):
        t = step / 6.0
        x, y = points[step]
        side = -1 if step % 2 == 0 else 1
        draw.line((x, y, x + side * 12, y - height * 0.10), fill=color, width=2)


def create_seabed_detail() -> None:
    w, h = 1672, 941
    image = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image, "RGBA")
    rng = random.Random(240625)

    # Extra rock silhouettes at the left/right margins. The base art already
    # has rocks; these add the denser edge framing visible in the reference.
    rock_sets = (
        ([-90, -30, 42, 128, 214], 815, 1.08),
        ([1420, 1500, 1588, 1660, 1740], 812, 0.96),
        ([260, 390, 540, 1230], 884, 0.55),
    )
    for xs, base_y, scale in rock_sets:
        for index, x in enumerate(xs):
            rx = int((78 + rng.random() * 64) * scale)
            ry = int((42 + rng.random() * 45) * scale)
            y = int(base_y + rng.uniform(-28, 18))
            dark = (4, 37, 52, 74)
            mid = (42, 94, 94, 54)
            hi = (110, 156, 136, 30)
            draw.ellipse((x - rx, y - ry, x + rx, y + ry), fill=dark)
            draw.ellipse((x - rx * 0.78, y - ry * 0.84, x + rx * 0.18, y + ry * 0.05), fill=mid)
            draw.arc((x - rx * 0.66, y - ry * 0.72, x + rx * 0.46, y + ry * 0.38), 196, 330, fill=hi, width=2)
            draw.line((x - rx * 0.62, y + ry * 0.35, x + rx * 0.64, y + ry * 0.22), fill=(0, 18, 31, 46), width=3)

    # Seaweed and coral clusters near the lower edges, kept clear of the main fish.
    for cluster_x, count, spread in ((160, 18, 170), (430, 12, 180), (1260, 12, 160), (1500, 20, 150)):
        for _ in range(count):
            x = cluster_x + rng.uniform(-spread * 0.5, spread * 0.5)
            base_y = rng.uniform(h * 0.78, h * 0.94)
            height = rng.uniform(34, 112)
            hue_pick = rng.random()
            if hue_pick < 0.64:
                color = (38, rng.randint(105, 168), rng.randint(96, 132), rng.randint(64, 116))
            elif hue_pick < 0.86:
                color = (118, rng.randint(96, 150), 58, rng.randint(46, 88))
            else:
                color = (185, 78, 103, rng.randint(44, 82))
            _draw_seaweed(draw, x, base_y, height, color, rng.uniform(-18, 18))

    # Fine seabed caustics and sand contour lines, mostly below the hit badge.
    caustics = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    cd = ImageDraw.Draw(caustics, "RGBA")
    for i in range(54):
        x = rng.uniform(w * 0.08, w * 0.92)
        y = rng.uniform(h * 0.68, h * 0.92)
        length = rng.uniform(38, 128)
        amp = rng.uniform(4, 14)
        points: list[tuple[float, float]] = []
        for step in range(6):
            t = step / 5.0
            points.append((x + length * t, y + math.sin(t * math.tau + i) * amp))
        cd.line(points, fill=(221, 248, 237, rng.randint(18, 46)), width=2)
    image.alpha_composite(caustics.filter(ImageFilter.GaussianBlur(0.45)))

    # Subtle bottom haze to bind the new details into the existing raster background.
    haze = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    hd = ImageDraw.Draw(haze, "RGBA")
    hd.rectangle((0, int(h * 0.84), w, h), fill=(13, 50, 50, 18))
    image.alpha_composite(haze.filter(ImageFilter.GaussianBlur(16)))

    image.save(OUT_DIR / "underwater_seabed_detail.png")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    create_foreground_ambience()
    create_color_grade()
    create_seabed_detail()
    print(f"generated {OUT_DIR / 'underwater_foreground_ambience.png'}")


if __name__ == "__main__":
    main()
