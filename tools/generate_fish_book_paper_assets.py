#!/usr/bin/env python3
"""Generate fish-book paper/card assets.

All text and state values stay in Godot. These images only provide paper
material, subtle frame treatment, and selection/locked state surfaces.
"""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "showcase" / "fish_book"

CARD_OUT = OUT_DIR / "fish_book_card_frame.png"
CARD_SELECTED_OUT = OUT_DIR / "fish_book_card_selected_frame.png"
CARD_LOCKED_OUT = OUT_DIR / "fish_book_card_locked_frame.png"
DETAIL_PAPER_OUT = OUT_DIR / "fish_book_detail_paper.png"


def _clamp(value: int) -> int:
    return max(0, min(255, value))


def _paper_texture(size: tuple[int, int], seed: int, base: tuple[int, int, int]) -> Image.Image:
    rng = random.Random(seed)
    img = Image.new("RGBA", size, (*base, 255))
    px = img.load()
    for y in range(size[1]):
        for x in range(size[0]):
            wave = int(math.sin((x + seed) * 0.045) * 4 + math.sin((y - seed) * 0.033) * 5)
            fiber = rng.randint(-8, 8)
            edge = 0
            edge += max(0, 18 - min(x, size[0] - 1 - x)) // 2
            edge += max(0, 18 - min(y, size[1] - 1 - y)) // 2
            px[x, y] = (
                _clamp(base[0] + wave + fiber - edge),
                _clamp(base[1] + wave + fiber - edge),
                _clamp(base[2] + wave // 2 + fiber // 2 - edge),
                255,
            )
    return img.filter(ImageFilter.GaussianBlur(0.22))


def _rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def _draw_scuffs(draw: ImageDraw.ImageDraw, rect: tuple[int, int, int, int], seed: int, count: int, alpha: tuple[int, int]) -> None:
    rng = random.Random(seed)
    x0, y0, x1, y1 = rect
    if x1 <= x0 or y1 <= y0:
        return
    for _ in range(count):
        x = rng.randint(x0, x1)
        y = rng.randint(y0, y1)
        length = rng.randint(6, 34)
        color = (99, 64, 29, rng.randint(alpha[0], alpha[1]))
        draw.line((x, y, min(x1, x + length), y + rng.randint(-1, 1)), fill=color, width=1)


def _draw_corner_marks(draw: ImageDraw.ImageDraw, rect: tuple[int, int, int, int], inset: int, color: tuple[int, int, int, int]) -> None:
    x0, y0, x1, y1 = rect
    length = 24
    for sx, sy in [(x0, y0), (x1, y0), (x0, y1), (x1, y1)]:
        hx0 = sx + inset if sx == x0 else sx - inset - length
        hx1 = sx + inset + length if sx == x0 else sx - inset
        vy0 = sy + inset if sy == y0 else sy - inset - length
        vy1 = sy + inset + length if sy == y0 else sy - inset
        y = sy + inset if sy == y0 else sy - inset
        x = sx + inset if sx == x0 else sx - inset
        draw.line((hx0, y, hx1, y), fill=color, width=2)
        draw.line((x, vy0, x, vy1), fill=color, width=2)


def _card_frame(selected: bool = False, locked: bool = False) -> Image.Image:
    size = (280, 220)
    img = Image.new("RGBA", size, (0, 0, 0, 0))

    shadow = Image.new("RGBA", size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((9, 12, size[0] - 9, size[1] - 10), radius=10, fill=(0, 0, 0, 92 if selected else 70))
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(5)))

    base = (238, 220, 174) if not locked else (150, 136, 111)
    paper = _paper_texture((size[0] - 18, size[1] - 20), 8302 if selected else 8301 if not locked else 8303, base)
    if locked:
        veil = Image.new("RGBA", paper.size, (35, 30, 22, 82))
        paper.alpha_composite(veil)
    img.paste(paper, (9, 8), _rounded_mask(paper.size, 9))

    draw = ImageDraw.Draw(img)
    outer = (9, 8, size[0] - 9, size[1] - 12)
    inner = (17, 17, size[0] - 17, size[1] - 21)
    if selected:
        draw.rounded_rectangle((6, 5, size[0] - 6, size[1] - 7), radius=13, outline=(255, 228, 128, 230), width=5)
        draw.rounded_rectangle((12, 11, size[0] - 12, size[1] - 15), radius=9, outline=(116, 64, 22, 210), width=3)
    else:
        draw.rounded_rectangle(outer, radius=10, outline=(76, 45, 20, 235), width=4)
        draw.rounded_rectangle(inner, radius=5, outline=(205, 151, 64, 175), width=2)

    if locked:
        draw.rounded_rectangle((23, 26, size[0] - 23, size[1] - 31), radius=5, fill=(34, 28, 20, 58), outline=(47, 31, 17, 145), width=2)
    else:
        draw.rounded_rectangle((23, 26, size[0] - 23, size[1] - 31), radius=5, outline=(132, 89, 38, 54), width=1)
    _draw_corner_marks(draw, outer, 12, (112, 68, 25, 120) if not selected else (255, 232, 146, 135))
    # Keep wear at the edges only. Runtime labels, rarity badges, and stats own
    # the card interior, so dark ruled marks would compete with real text.
    _draw_scuffs(draw, (30, 178, size[0] - 44, size[1] - 28), 8401 if not locked else 8402, 5, (3, 7))
    return img


def _detail_paper() -> Image.Image:
    size = (520, 760)
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    shadow = Image.new("RGBA", size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((10, 14, size[0] - 10, size[1] - 12), radius=18, fill=(0, 0, 0, 85))
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(6)))

    paper = _paper_texture((size[0] - 34, size[1] - 36), 8501, (232, 210, 162))
    img.paste(paper, (17, 16), _rounded_mask(paper.size, 16))

    draw = ImageDraw.Draw(img)
    outer = (17, 16, size[0] - 17, size[1] - 20)
    inner = (29, 29, size[0] - 29, size[1] - 33)
    draw.rounded_rectangle(outer, radius=18, outline=(92, 58, 27, 210), width=4)
    draw.rounded_rectangle(inner, radius=12, outline=(224, 171, 78, 160), width=2)
    # The existing detail frame and runtime rows own structure. This paper only
    # adds page material and edge wear, never baked-in guide lines.
    _draw_corner_marks(draw, outer, 16, (116, 68, 25, 102))
    for rect, seed in [
        ((45, 54, size[0] - 56, 94), 8502),
        ((45, 642, size[0] - 56, size[1] - 62), 8504),
    ]:
        _draw_scuffs(draw, rect, seed, 8, (3, 7))

    warm = Image.new("RGBA", size, (143, 88, 28, 0))
    wm = Image.new("L", size, 0)
    wpx = wm.load()
    cx, cy = size[0] * 0.48, size[1] * 0.40
    max_dist = math.hypot(max(cx, size[0] - cx), max(cy, size[1] - cy))
    for y in range(size[1]):
        for x in range(size[0]):
            d = math.hypot(x - cx, y - cy) / max_dist
            wpx[x, y] = max(0, min(42, round(((d - 0.52) / 0.48) ** 1.5 * 42))) if d > 0.52 else 0
    warm.putalpha(wm.filter(ImageFilter.GaussianBlur(10)))
    img.alpha_composite(warm)
    return img


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    _card_frame(False, False).save(CARD_OUT)
    _card_frame(True, False).save(CARD_SELECTED_OUT)
    _card_frame(False, True).save(CARD_LOCKED_OUT)
    _detail_paper().save(DETAIL_PAPER_OUT)
    for path in [CARD_OUT, CARD_SELECTED_OUT, CARD_LOCKED_OUT, DETAIL_PAPER_OUT]:
        print(path)


if __name__ == "__main__":
    main()
