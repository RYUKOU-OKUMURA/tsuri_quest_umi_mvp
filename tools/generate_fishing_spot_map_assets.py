#!/usr/bin/env python3
"""Generate raster assets for the fishing spot map screen.

The map source is intentionally text-free. Godot draws all labels, lock state,
and selected state so Japanese text stays crisp and data-driven.
"""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tools" / "source_assets" / "fishing_spot_map_source.png"
OUT_DIR = ROOT / "assets" / "showcase" / "fishing_spots"

MAP_BG_OUT = OUT_DIR / "map_bg.png"
MAP_GRADE_OUT = OUT_DIR / "map_color_grade.png"
DETAIL_FRAME_OUT = OUT_DIR / "map_detail_frame.png"
FOOTER_FRAME_OUT = OUT_DIR / "map_footer_frame.png"
MARKER_SHEET_OUT = OUT_DIR / "map_marker_sheet.png"
CARD_FRAME_OUT = OUT_DIR / "map_spot_card_frame.png"
CARD_FRAME_LOCKED_OUT = OUT_DIR / "map_spot_card_frame_locked.png"


def _cover_crop(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    scale = max(size[0] / image.width, size[1] / image.height)
    resized = image.resize(
        (round(image.width * scale), round(image.height * scale)),
        Image.Resampling.LANCZOS,
    )
    left = (resized.width - size[0]) // 2
    top = (resized.height - size[1]) // 2
    return resized.crop((left, top, left + size[0], top + size[1]))


def _paper_texture(size: tuple[int, int], seed: int, base: tuple[int, int, int]) -> Image.Image:
    rng = random.Random(seed)
    img = Image.new("RGBA", size, (*base, 255))
    px = img.load()
    for y in range(size[1]):
        for x in range(size[0]):
            noise = rng.randint(-9, 8)
            wave = int(math.sin((x + seed) * 0.035) * 4 + math.sin((y - seed) * 0.049) * 3)
            r = max(0, min(255, base[0] + noise + wave))
            g = max(0, min(255, base[1] + noise + wave))
            b = max(0, min(255, base[2] + noise + wave))
            px[x, y] = (r, g, b, 255)
    return img.filter(ImageFilter.GaussianBlur(0.25))


def _rounded(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], radius: int, fill, outline=None, width: int = 1) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def _draw_frame(
    size: tuple[int, int],
    *,
    seed: int,
    header: bool,
    dark_footer: bool = False,
) -> Image.Image:
    frame = Image.new("RGBA", size, (0, 0, 0, 0))
    shadow = Image.new("RGBA", size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    _rounded(shadow_draw, (10, 10, size[0] - 10, size[1] - 8), 18, (0, 0, 0, 95))
    shadow = shadow.filter(ImageFilter.GaussianBlur(8))
    frame.alpha_composite(shadow)

    body = _paper_texture((size[0] - 28, size[1] - 28), seed, (229, 205, 154))
    mask = Image.new("L", body.size, 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle((0, 0, body.width - 1, body.height - 1), radius=16, fill=255)
    frame.paste(body, (14, 12), mask)

    draw = ImageDraw.Draw(frame)
    outer = (14, 12, size[0] - 14, size[1] - 16)
    inner = (25, 23, size[0] - 25, size[1] - 27)
    _rounded(draw, outer, 16, None, (72, 45, 24, 235), 4)
    _rounded(draw, (19, 17, size[0] - 19, size[1] - 21), 12, None, (213, 171, 91, 220), 2)
    _rounded(draw, inner, 10, None, (119, 83, 42, 150), 1)

    for corner in [(25, 23), (size[0] - 25, 23), (25, size[1] - 27), (size[0] - 25, size[1] - 27)]:
        x, y = corner
        draw.ellipse((x - 4, y - 4, x + 4, y + 4), fill=(164, 105, 42, 205), outline=(255, 221, 130, 180))

    if header:
        header_box = (38, 34, size[0] - 38, 104)
        _rounded(draw, header_box, 8, (8, 50, 79, 238), (208, 166, 83, 230), 3)
        draw.line((header_box[0] + 12, header_box[1] + 10, header_box[2] - 12, header_box[1] + 10), fill=(255, 255, 255, 45), width=2)
        draw.line((header_box[0] + 12, header_box[3] - 8, header_box[2] - 12, header_box[3] - 8), fill=(0, 0, 0, 70), width=2)

    if dark_footer:
        band = (34, size[1] - 58, size[0] - 34, size[1] - 26)
        _rounded(draw, band, 8, (8, 42, 66, 222), (194, 150, 69, 185), 2)

    # Light scuffs and cartographic wear.
    rng = random.Random(seed + 99)
    for _ in range(70):
        x = rng.randint(34, size[0] - 52)
        y = rng.randint(38, size[1] - 46)
        length = rng.randint(14, 58)
        alpha = rng.randint(10, 28)
        draw.line((x, y, x + length, y + rng.randint(-2, 2)), fill=(104, 67, 31, alpha), width=1)
    return frame


def _draw_marker_cell(kind: str, size: int = 128) -> Image.Image:
    cell = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(cell)
    cx = cy = size // 2
    if kind == "selected":
        for radius, alpha in [(56, 38), (48, 70), (40, 90)]:
            draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill=(255, 204, 61, alpha))
    elif kind == "locked":
        draw.ellipse((9, 13, size - 9, size - 5), fill=(0, 0, 0, 75))

    palette = {
        "normal": ((11, 66, 99, 245), (236, 203, 118, 245), (188, 231, 244, 255)),
        "selected": ((11, 72, 111, 252), (255, 216, 84, 255), (255, 249, 204, 255)),
        "locked": ((54, 64, 70, 230), (109, 99, 79, 235), (177, 174, 158, 255)),
        "boss": ((92, 36, 31, 248), (231, 156, 84, 250), (255, 223, 162, 255)),
    }
    fill, ring, symbol = palette[kind]
    draw.ellipse((18, 13, size - 18, size - 23), fill=(0, 0, 0, 88))
    draw.ellipse((16, 10, size - 16, size - 26), fill=fill, outline=(35, 18, 10, 220), width=3)
    draw.ellipse((22, 16, size - 22, size - 32), outline=ring, width=5)
    draw.arc((36, 26, size - 36, size - 46), 200, 338, fill=(255, 255, 255, 58), width=3)

    if kind == "locked":
        # Lock shackle and body.
        draw.arc((45, 39, 83, 81), 180, 360, fill=(236, 215, 162, 245), width=7)
        draw.rounded_rectangle((41, 62, 87, 94), radius=7, fill=(230, 190, 86, 250), outline=(86, 53, 22, 255), width=2)
        draw.ellipse((59, 72, 69, 82), fill=(72, 44, 24, 255))
        draw.rectangle((63, 79, 66, 88), fill=(72, 44, 24, 255))
    elif kind == "boss":
        # Rock crest.
        rock = [(36, 79), (45, 52), (59, 42), (73, 56), (88, 49), (96, 80), (82, 91), (52, 91)]
        draw.polygon(rock, fill=(104, 118, 119, 255), outline=(28, 31, 31, 235))
        draw.line((50, 58, 59, 86), fill=(206, 213, 196, 120), width=3)
        draw.line((75, 61, 86, 86), fill=(45, 51, 51, 150), width=3)
    else:
        # Anchor-like fishing point mark.
        draw.line((cx, 32, cx, 83), fill=symbol, width=7)
        draw.ellipse((cx - 12, 24, cx + 12, 48), outline=symbol, width=6)
        draw.line((cx - 23, 56, cx + 23, 56), fill=symbol, width=6)
        draw.arc((cx - 33, 55, cx + 33, 105), 25, 155, fill=symbol, width=7)
        draw.polygon([(cx - 35, 76), (cx - 20, 80), (cx - 28, 91)], fill=symbol)
        draw.polygon([(cx + 35, 76), (cx + 20, 80), (cx + 28, 91)], fill=symbol)
    return cell


def _draw_card_frame(size: tuple[int, int], locked: bool) -> Image.Image:
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    base = (205, 194, 164) if locked else (236, 213, 166)
    body = _paper_texture((size[0] - 10, size[1] - 10), 400 + int(locked), base)
    mask = Image.new("L", body.size, 0)
    draw_mask = ImageDraw.Draw(mask)
    draw_mask.rounded_rectangle((0, 0, body.width - 1, body.height - 1), radius=10, fill=255)
    img.paste(body, (5, 5), mask)
    draw = ImageDraw.Draw(img)
    border = (108, 96, 76, 220) if locked else (151, 99, 43, 235)
    accent = (110, 103, 88, 160) if locked else (213, 169, 83, 230)
    _rounded(draw, (5, 5, size[0] - 5, size[1] - 5), 10, None, border, 2)
    _rounded(draw, (10, 10, size[0] - 10, size[1] - 10), 6, None, accent, 1)
    draw.rectangle((11, 10, size[0] - 11, 38), fill=(10, 58, 85, 224) if not locked else (72, 78, 80, 170))
    draw.line((15, 39, size[0] - 15, 39), fill=accent, width=1)
    return img


def build() -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(f"Missing source image: {SOURCE}")
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    source = Image.open(SOURCE).convert("RGB")
    bg = _cover_crop(source, (1920, 1080))
    bg.save(MAP_BG_OUT)

    grade = Image.new("RGBA", (1920, 1080), (0, 0, 0, 0))
    px = grade.load()
    for y in range(1080):
        for x in range(1920):
            edge = max(abs(x - 960) / 960, abs(y - 540) / 540)
            right = max(0.0, (x - 1140) / 780)
            bottom = max(0.0, (y - 790) / 290)
            alpha = int(min(115, max(0, (edge - 0.42) * 120 + right * 38 + bottom * 28)))
            px[x, y] = (2, 11, 22, alpha)
    grade = grade.filter(ImageFilter.GaussianBlur(9))
    grade.save(MAP_GRADE_OUT)

    _draw_frame((520, 760), seed=210, header=True, dark_footer=True).save(DETAIL_FRAME_OUT)
    _draw_frame((1600, 160), seed=310, header=False, dark_footer=True).save(FOOTER_FRAME_OUT)

    sheet = Image.new("RGBA", (128 * 4, 128), (0, 0, 0, 0))
    for i, kind in enumerate(["normal", "selected", "locked", "boss"]):
        sheet.alpha_composite(_draw_marker_cell(kind), (i * 128, 0))
    sheet.save(MARKER_SHEET_OUT)

    _draw_card_frame((340, 118), locked=False).save(CARD_FRAME_OUT)
    _draw_card_frame((340, 118), locked=True).save(CARD_FRAME_LOCKED_OUT)


def main() -> int:
    build()
    print(f"Generated fishing spot map assets in {OUT_DIR}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
