#!/usr/bin/env python3
"""Generate the fish-book outer logbook frame asset.

The asset intentionally contains no Japanese text or data. Godot draws labels,
status values, filters, and button states at runtime.
"""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "showcase" / "fish_book" / "fish_book_book_frame.png"
SIZE = (1900, 1060)


def _clamp(value: int) -> int:
    return max(0, min(255, value))


def _wood_texture(size: tuple[int, int], seed: int, base: tuple[int, int, int]) -> Image.Image:
    rng = random.Random(seed)
    img = Image.new("RGBA", size, (*base, 255))
    px = img.load()
    for y in range(size[1]):
        plank = (y // 42) % 2
        for x in range(size[0]):
            grain = (
                math.sin((x + seed) * 0.030 + math.sin(y * 0.035) * 1.8) * 15
                + math.sin((x - seed) * 0.010) * 8
                + math.sin((x + y) * 0.052) * 4
            )
            noise = rng.randint(-8, 8)
            split = -12 if plank else 8
            r = _clamp(base[0] + int(grain) + noise + split)
            g = _clamp(base[1] + int(grain * 0.72) + noise + split)
            b = _clamp(base[2] + int(grain * 0.42) + noise // 2 + split)
            px[x, y] = (r, g, b, 255)
    return img.filter(ImageFilter.GaussianBlur(0.25))


def _rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def _paste_rounded(dst: Image.Image, src: Image.Image, xy: tuple[int, int], radius: int) -> None:
    dst.paste(src, xy, _rounded_mask(src.size, radius))


def _draw_corner_plate(draw: ImageDraw.ImageDraw, points: list[tuple[int, int]]) -> None:
    draw.polygon(points, fill=(211, 149, 65, 236), outline=(61, 34, 16, 235))
    draw.line(points[:3], fill=(255, 225, 132, 135), width=3)
    for x, y in points[:2]:
        draw.ellipse((x - 4, y - 4, x + 4, y + 4), fill=(86, 47, 20, 190))


def _draw_nails(draw: ImageDraw.ImageDraw, positions: list[tuple[int, int]]) -> None:
    for x, y in positions:
        draw.ellipse((x - 7, y - 7, x + 7, y + 7), fill=(118, 68, 29, 218), outline=(248, 202, 111, 145), width=2)
        draw.ellipse((x - 2, y - 2, x + 2, y + 2), fill=(44, 24, 12, 190))


def _draw_scuffs(draw: ImageDraw.ImageDraw, rect: tuple[int, int, int, int], seed: int, count: int) -> None:
    rng = random.Random(seed)
    x0, y0, x1, y1 = rect
    for _ in range(count):
        x = rng.randint(x0, x1)
        y = rng.randint(y0, y1)
        length = rng.randint(18, 118)
        alpha = rng.randint(18, 48)
        color = (42, 20, 8, alpha) if rng.random() < 0.65 else (255, 219, 132, alpha // 2)
        draw.line((x, y, min(x1, x + length), y + rng.randint(-2, 2)), fill=color, width=1)


def build_frame() -> Image.Image:
    img = Image.new("RGBA", SIZE, (0, 0, 0, 0))

    shadow = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((22, 22, SIZE[0] - 22, SIZE[1] - 18), radius=26, fill=(0, 0, 0, 120))
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(14)))

    outer = (18, 18, SIZE[0] - 18, SIZE[1] - 18)
    inner = (78, 150, SIZE[0] - 78, SIZE[1] - 134)
    top_rail = (42, 34, SIZE[0] - 42, 170)
    bottom_rail = (42, SIZE[1] - 138, SIZE[0] - 42, SIZE[1] - 42)
    left_post = (42, 150, 92, SIZE[1] - 132)
    right_post = (SIZE[0] - 92, 150, SIZE[0] - 42, SIZE[1] - 132)

    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle(outer, radius=30, fill=(42, 23, 11, 255))

    # Dark recessed writing area behind the child panels.
    draw.rounded_rectangle(inner, radius=14, fill=(12, 18, 20, 224), outline=(67, 42, 21, 240), width=6)
    draw.rounded_rectangle((inner[0] + 12, inner[1] + 12, inner[2] - 12, inner[3] - 12), radius=10, fill=(10, 25, 36, 188))

    # One continuous wood object: top rail, side posts, and lower shelf.
    top_tex = _wood_texture((top_rail[2] - top_rail[0], top_rail[3] - top_rail[1]), 7101, (116, 70, 30))
    bottom_tex = _wood_texture((bottom_rail[2] - bottom_rail[0], bottom_rail[3] - bottom_rail[1]), 7102, (91, 53, 24))
    left_tex = _wood_texture((left_post[2] - left_post[0], left_post[3] - left_post[1]), 7103, (88, 51, 24)).rotate(90, expand=True).resize((left_post[2] - left_post[0], left_post[3] - left_post[1]))
    right_tex = _wood_texture((right_post[2] - right_post[0], right_post[3] - right_post[1]), 7104, (88, 51, 24)).rotate(90, expand=True).resize((right_post[2] - right_post[0], right_post[3] - right_post[1]))
    _paste_rounded(img, top_tex, (top_rail[0], top_rail[1]), 20)
    _paste_rounded(img, bottom_tex, (bottom_rail[0], bottom_rail[1]), 18)
    _paste_rounded(img, left_tex, (left_post[0], left_post[1]), 12)
    _paste_rounded(img, right_tex, (right_post[0], right_post[1]), 12)

    draw = ImageDraw.Draw(img)
    # Bevels bind the separate wood strips into a single frame.
    for rect, radius in [(top_rail, 20), (bottom_rail, 18), (left_post, 12), (right_post, 12)]:
        draw.rounded_rectangle(rect, radius=radius, outline=(50, 27, 12, 242), width=6)
        inset = (rect[0] + 8, rect[1] + 8, rect[2] - 8, rect[3] - 8)
        draw.rounded_rectangle(inset, radius=max(4, radius - 5), outline=(231, 177, 87, 142), width=2)
        draw.line((inset[0] + 8, inset[1] + 6, inset[2] - 8, inset[1] + 6), fill=(255, 234, 161, 55), width=2)
        draw.line((inset[0] + 8, inset[3] - 5, inset[2] - 8, inset[3] - 5), fill=(0, 0, 0, 92), width=2)

    # Subtle plank seams: strong enough to read as wood, not as separate UI rows.
    for y in [76, 122]:
        draw.line((top_rail[0] + 24, top_rail[1] + y - 34, top_rail[2] - 24, top_rail[1] + y - 34), fill=(42, 21, 8, 88), width=2)
    for y in [bottom_rail[1] + 34, bottom_rail[1] + 65]:
        draw.line((bottom_rail[0] + 22, y, bottom_rail[2] - 22, y), fill=(35, 18, 8, 100), width=2)

    # Keep the center rail quiet: the actual title sign is a separate PNG.
    plate = (SIZE[0] // 2 - 310, top_rail[1] + 14, SIZE[0] // 2 + 310, top_rail[3] - 14)
    draw.rounded_rectangle(plate, radius=28, outline=(32, 16, 7, 72), width=2)

    # Corner metal plates and nails, similar to the reference mockup's logbook hardware.
    s = 64
    _draw_corner_plate(draw, [(outer[0], outer[1] + s), (outer[0], outer[1]), (outer[0] + s, outer[1]), (outer[0] + s - 18, outer[1] + 20), (outer[0] + 18, outer[1] + s - 18)])
    _draw_corner_plate(draw, [(outer[2], outer[1] + s), (outer[2], outer[1]), (outer[2] - s, outer[1]), (outer[2] - s + 18, outer[1] + 20), (outer[2] - 18, outer[1] + s - 18)])
    _draw_corner_plate(draw, [(outer[0], outer[3] - s), (outer[0], outer[3]), (outer[0] + s, outer[3]), (outer[0] + s - 18, outer[3] - 20), (outer[0] + 18, outer[3] - s + 18)])
    _draw_corner_plate(draw, [(outer[2], outer[3] - s), (outer[2], outer[3]), (outer[2] - s, outer[3]), (outer[2] - s + 18, outer[3] - 20), (outer[2] - 18, outer[3] - s + 18)])
    _draw_nails(
        draw,
        [
            (68, 70),
            (SIZE[0] - 68, 70),
            (68, SIZE[1] - 70),
            (SIZE[0] - 68, SIZE[1] - 70),
            (72, 195),
            (SIZE[0] - 72, 195),
            (72, SIZE[1] - 180),
            (SIZE[0] - 72, SIZE[1] - 180),
        ],
    )

    _draw_scuffs(draw, top_rail, 7201, 90)
    _draw_scuffs(draw, bottom_rail, 7202, 64)
    _draw_scuffs(draw, left_post, 7203, 36)
    _draw_scuffs(draw, right_post, 7204, 36)

    # Interior shadow makes the child panels feel seated inside the book.
    overlay = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.rounded_rectangle((inner[0] + 8, inner[1] + 8, inner[2] - 8, inner[3] - 8), radius=10, outline=(0, 0, 0, 120), width=10)
    overlay = overlay.filter(ImageFilter.GaussianBlur(5))
    img.alpha_composite(overlay)

    return img


def main() -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    build_frame().save(OUT)
    print(OUT)


if __name__ == "__main__":
    main()
