#!/usr/bin/env python3
"""Generate raster assets for the fishing spot map screen.

The map source is intentionally text-free. Godot draws all labels, lock state,
and selected state so Japanese text stays crisp and data-driven.
"""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tools" / "source_assets" / "fishing_spot_map_source.png"
OUT_DIR = ROOT / "assets" / "showcase" / "fishing_spots"

MAP_BG_OUT = OUT_DIR / "map_bg.png"
MAP_GRADE_OUT = OUT_DIR / "map_color_grade.png"
HEADER_FRAME_OUT = OUT_DIR / "map_header_frame.png"
DETAIL_FRAME_OUT = OUT_DIR / "map_detail_frame.png"
FOOTER_FRAME_OUT = OUT_DIR / "map_footer_frame.png"
MARKER_SHEET_OUT = OUT_DIR / "map_marker_sheet.png"
SPOT_MARKER_SHEET_OUT = OUT_DIR / "map_spot_marker_sheet.png"
DETAIL_ICON_SHEET_OUT = OUT_DIR / "map_detail_icon_sheet.png"
CARD_FRAME_OUT = OUT_DIR / "map_spot_card_frame.png"
CARD_FRAME_LOCKED_OUT = OUT_DIR / "map_spot_card_frame_locked.png"
ROUTE_CHIP_FRAME_OUT = OUT_DIR / "map_route_chip_frame.png"
ROUTE_CHIP_FRAME_LOCKED_OUT = OUT_DIR / "map_route_chip_frame_locked.png"
COMPLETION_SLOT_FRAME_OUT = OUT_DIR / "map_completion_slot_frame.png"
COMPLETION_SLOT_SELECTED_OUT = OUT_DIR / "map_completion_slot_selected.png"
COMPLETION_SLOT_LOCKED_OUT = OUT_DIR / "map_completion_slot_locked.png"
THUMB_DIR = OUT_DIR / "thumbs"

SPOT_ORDER = [
    "harbor_pier",
    "shallow_sand",
    "rock_breakwater",
    "outer_tide",
    "south_reef",
    "bluewater_route",
    "deep_ocean",
    "harbor_boulder",
]

SPOT_POINTS = {
    "harbor_pier": (0.255, 0.505),
    "shallow_sand": (0.330, 0.335),
    "rock_breakwater": (0.455, 0.500),
    "outer_tide": (0.620, 0.300),
    "south_reef": (0.300, 0.735),
    "bluewater_route": (0.700, 0.525),
    "deep_ocean": (0.765, 0.770),
    "harbor_boulder": (0.435, 0.620),
}


def _cover_crop(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    scale = max(size[0] / image.width, size[1] / image.height)
    resized = image.resize(
        (round(image.width * scale), round(image.height * scale)),
        Image.Resampling.LANCZOS,
    )
    left = (resized.width - size[0]) // 2
    top = (resized.height - size[1]) // 2
    return resized.crop((left, top, left + size[0], top + size[1]))


def _enhance_map_bg(image: Image.Image) -> Image.Image:
    """Apply a final art pass so the map reads crisply at 720p UI scale."""
    img = ImageEnhance.Color(image).enhance(1.11)
    img = ImageEnhance.Contrast(img).enhance(1.07)
    img = ImageEnhance.Sharpness(img).enhance(1.18)
    img = img.filter(ImageFilter.UnsharpMask(radius=1.1, percent=72, threshold=3)).convert("RGBA")

    glaze = Image.new("RGBA", img.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(glaze)
    # Make shallow water around the island and reefs pop without repainting labels.
    for cx, cy, rx, ry, color in [
        (540, 410, 620, 390, (76, 225, 210, 20)),
        (560, 760, 420, 220, (73, 212, 190, 18)),
        (1280, 480, 520, 330, (24, 91, 142, 24)),
        (1610, 660, 420, 280, (4, 28, 68, 28)),
    ]:
        draw.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=color)
    # A subtle nautical paper/ink glaze keeps the image in the same family as the UI frames.
    for x in range(0, img.width, 80):
        draw.line((x, 0, x - 180, img.height), fill=(255, 232, 164, 5), width=1)
    glaze = glaze.filter(ImageFilter.GaussianBlur(18))
    img.alpha_composite(glaze)
    return img.convert("RGB")


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


def _draw_header_frame(size: tuple[int, int]) -> Image.Image:
    frame = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(frame)
    # A calm single nautical status band. Text is drawn by Godot.
    _rounded(draw, (8, 8, size[0] - 8, size[1] - 8), 7, (9, 34, 55, 246), (16, 62, 95, 240), 3)
    _rounded(draw, (20, 20, size[0] - 20, size[1] - 20), 2, None, (176, 134, 64, 150), 2)
    draw.line((32, 25, size[0] - 32, 25), fill=(255, 255, 255, 24), width=2)
    draw.line((32, size[1] - 24, size[0] - 32, size[1] - 24), fill=(0, 0, 0, 86), width=2)
    draw.rectangle((32, 32, size[0] - 32, size[1] - 32), fill=(10, 42, 68, 46))
    return frame


def _draw_detail_frame(size: tuple[int, int]) -> Image.Image:
    frame = _draw_frame(size, seed=230, header=False, dark_footer=False)
    draw = ImageDraw.Draw(frame)
    # Clean content wells: title, image, description, info rows, buttons.
    title = (38, 31, size[0] - 38, 91)
    _rounded(draw, title, 8, (8, 50, 79, 242), (214, 174, 91, 235), 3)
    draw.line((title[0] + 14, title[1] + 10, title[2] - 14, title[1] + 10), fill=(255, 255, 255, 50), width=2)

    thumb = (38, 106, size[0] - 38, 275)
    _rounded(draw, thumb, 8, (18, 43, 52, 205), (119, 83, 42, 130), 2)
    draw.rectangle((thumb[0] + 6, thumb[1] + 6, thumb[2] - 6, thumb[3] - 6), fill=(225, 205, 163, 80))

    desc = (38, 287, size[0] - 38, 354)
    _rounded(draw, desc, 7, (235, 215, 174, 214), (130, 88, 42, 62), 1)

    # Runtime draws the actual information rows. Keep this area as paper so
    # row text never collides with baked guide lines after panel scaling.
    _rounded(draw, (38, 366, size[0] - 38, 560), 7, (238, 218, 177, 92), (122, 82, 38, 26), 1)

    # Button wells at the bottom, left blank for Godot buttons.
    _rounded(draw, (38, size[1] - 143, size[0] - 38, size[1] - 91), 8, (7, 62, 96, 225), (213, 173, 85, 210), 2)
    _rounded(draw, (38, size[1] - 79, size[0] - 38, size[1] - 31), 8, (235, 215, 175, 230), (139, 91, 42, 205), 2)
    return frame


def _draw_footer_frame(size: tuple[int, int]) -> Image.Image:
    frame = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(frame)
    _rounded(draw, (10, 10, size[0] - 10, size[1] - 10), 14, (7, 34, 54, 238), (178, 130, 58, 220), 3)
    _rounded(draw, (20, 20, size[0] - 20, size[1] - 20), 9, None, (230, 190, 96, 165), 1)

    # Left side is a logbook board, not another set of point-selection cards.
    board = _paper_texture((size[0] - 430, size[1] - 54), 980, (221, 202, 162))
    board_mask = Image.new("L", board.size, 0)
    mask_draw = ImageDraw.Draw(board_mask)
    mask_draw.rounded_rectangle((0, 0, board.width - 1, board.height - 1), radius=10, fill=255)
    frame.paste(board, (28, 27), board_mask)
    _rounded(draw, (28, 27, size[0] - 402, size[1] - 27), 10, None, (110, 72, 35, 178), 2)
    _rounded(draw, (39, 36, size[0] - 413, 65), 7, (7, 46, 72, 226), (213, 171, 88, 165), 1)
    draw.line((55, 45, size[0] - 430, 45), fill=(255, 255, 255, 34), width=1)
    for x in range(54, size[0] - 438, 74):
        draw.line((x, 78, x + 42, 78), fill=(118, 79, 38, 42), width=1)

    # Right memo is parchment, visually secondary to the map and right detail panel.
    _rounded(draw, (size[0] - 382, 27, size[0] - 30, size[1] - 27), 9, (225, 202, 155, 232), (132, 85, 38, 165), 2)
    _rounded(draw, (size[0] - 362, 42, size[0] - 50, 70), 5, (8, 50, 78, 230), (210, 171, 88, 200), 1)
    _rounded(draw, (size[0] - 362, size[1] - 59, size[0] - 50, size[1] - 31), 5, (8, 50, 78, 210), None, 1)
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


def _draw_spot_symbol(draw: ImageDraw.ImageDraw, spot_id: str, cx: int, cy: int, scale: float, color) -> None:
    s = scale
    if spot_id == "harbor_pier":
        draw.line((cx, cy - 26 * s, cx, cy + 28 * s), fill=color, width=round(7 * s))
        draw.ellipse((cx - 12 * s, cy - 34 * s, cx + 12 * s, cy - 10 * s), outline=color, width=round(6 * s))
        draw.line((cx - 24 * s, cy - 8 * s, cx + 24 * s, cy - 8 * s), fill=color, width=round(6 * s))
        draw.arc((cx - 34 * s, cy - 12 * s, cx + 34 * s, cy + 42 * s), 25, 155, fill=color, width=round(7 * s))
    elif spot_id == "shallow_sand":
        draw.arc((cx - 33 * s, cy - 10 * s, cx + 34 * s, cy + 46 * s), 204, 342, fill=color, width=round(7 * s))
        draw.line((cx - 5 * s, cy - 8 * s, cx - 5 * s, cy + 30 * s), fill=color, width=round(6 * s))
        for angle in [-45, -18, 10, 34]:
            end = (cx - 5 * s + math.cos(math.radians(angle)) * 29 * s, cy - 8 * s + math.sin(math.radians(angle)) * 24 * s)
            draw.line((cx - 5 * s, cy - 8 * s, end[0], end[1]), fill=color, width=round(5 * s))
    elif spot_id == "rock_breakwater":
        rocks = [
            (cx - 30 * s, cy + 8 * s, cx - 4 * s, cy + 34 * s),
            (cx - 10 * s, cy - 16 * s, cx + 18 * s, cy + 15 * s),
            (cx + 13 * s, cy + 4 * s, cx + 38 * s, cy + 33 * s),
        ]
        for box in rocks:
            draw.rounded_rectangle(box, radius=round(4 * s), fill=color, outline=(38, 35, 28, 210), width=round(2 * s))
    elif spot_id == "outer_tide":
        for offset in [-16, 2, 20]:
            draw.arc((cx - 36 * s, cy + offset * s, cx + 36 * s, cy + (offset + 30) * s), 200, 340, fill=color, width=round(6 * s))
    elif spot_id == "south_reef":
        for dx, dy, r in [(-18, 4, 12), (2, -8, 15), (20, 10, 11), (-2, 20, 10)]:
            draw.ellipse((cx + (dx - r) * s, cy + (dy - r) * s, cx + (dx + r) * s, cy + (dy + r) * s), outline=color, width=round(5 * s))
        draw.line((cx - 30 * s, cy + 32 * s, cx + 32 * s, cy + 32 * s), fill=color, width=round(5 * s))
    elif spot_id == "bluewater_route":
        for dx, dy in [(-20, -10), (5, 4), (24, -6)]:
            body = [(cx + (dx - 18) * s, cy + dy * s), (cx + dx * s, cy - 11 * s + dy * s), (cx + (dx + 19) * s, cy + dy * s), (cx + dx * s, cy + 11 * s + dy * s)]
            draw.polygon(body, fill=color)
            draw.polygon([(cx + (dx + 19) * s, cy + dy * s), (cx + (dx + 32) * s, cy - 9 * s + dy * s), (cx + (dx + 32) * s, cy + 9 * s + dy * s)], fill=color)
    elif spot_id == "deep_ocean":
        draw.polygon([(cx - 28 * s, cy + 10 * s), (cx - 3 * s, cy - 24 * s), (cx + 28 * s, cy + 6 * s), (cx + 3 * s, cy + 34 * s)], fill=color)
        draw.line((cx - 2 * s, cy - 22 * s, cx + 4 * s, cy + 32 * s), fill=(31, 49, 61, 160), width=round(3 * s))
    elif spot_id == "harbor_boulder":
        rock = [(cx - 32 * s, cy + 25 * s), (cx - 20 * s, cy - 15 * s), (cx - 3 * s, cy - 30 * s), (cx + 15 * s, cy - 8 * s), (cx + 31 * s, cy - 16 * s), (cx + 41 * s, cy + 24 * s)]
        draw.polygon(rock, fill=color, outline=(48, 37, 31, 210))
        draw.line((cx - 13 * s, cy - 9 * s, cx - 3 * s, cy + 23 * s), fill=(220, 220, 193, 115), width=round(3 * s))


def _draw_spot_marker(spot_id: str, state: str, size: int = 128) -> Image.Image:
    upscale = 4
    work_size = size * upscale
    u = upscale
    cell = Image.new("RGBA", (work_size, work_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(cell)
    cx = cy = work_size // 2
    selected = state == "selected"
    locked = state == "locked"
    if selected:
        for radius, alpha in [(60 * u, 34), (51 * u, 64), (43 * u, 88)]:
            draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill=(255, 205, 58, alpha))

    draw.ellipse((17 * u, 76 * u, work_size - 17 * u, 119 * u), fill=(0, 0, 0, 76))
    fill = (10, 66, 100, 248)
    ring = (236, 203, 118, 248)
    symbol = (225, 246, 238, 255)
    inner = (8, 60, 85, 236)
    outline = (31, 19, 11, 238)
    if selected:
        fill = (8, 78, 124, 252)
        ring = (255, 222, 86, 255)
        symbol = (255, 249, 205, 255)
        inner = (9, 70, 104, 242)
    if locked:
        fill = (58, 66, 70, 220)
        ring = (116, 106, 87, 230)
        symbol = (181, 178, 159, 255)
        inner = (68, 72, 70, 222)
    if spot_id == "harbor_boulder" and not locked:
        fill = (93, 38, 32, 248)
        ring = (229, 151, 82, 248)
        inner = (84, 42, 37, 236)

    tail = [
        (cx - 15 * u, cy + 24 * u),
        (cx + 15 * u, cy + 24 * u),
        (cx, cy + 55 * u),
    ]
    draw.polygon(tail, fill=fill)
    draw.line([tail[0], tail[1], tail[2], tail[0]], fill=outline, width=3 * u, joint="curve")
    draw.ellipse((14 * u, 7 * u, work_size - 14 * u, work_size - 31 * u), fill=fill, outline=outline, width=3 * u)
    draw.ellipse((22 * u, 15 * u, work_size - 22 * u, work_size - 39 * u), outline=ring, width=5 * u)
    draw.ellipse((35 * u, 27 * u, work_size - 35 * u, work_size - 52 * u), fill=inner, outline=(255, 244, 190, 74), width=2 * u)
    draw.arc((32 * u, 22 * u, work_size - 32 * u, work_size - 58 * u), 198, 338, fill=(255, 255, 255, 64), width=3 * u)

    symbol_scale = 0.64 * u
    symbol_y = cy - 7 * u
    _draw_spot_symbol(draw, spot_id, cx + 2 * u, symbol_y + 3 * u, symbol_scale, (0, 0, 0, 96))
    _draw_spot_symbol(draw, spot_id, cx, symbol_y, symbol_scale, symbol)
    if locked:
        veil = Image.new("RGBA", (work_size, work_size), (0, 0, 0, 0))
        veil_draw = ImageDraw.Draw(veil)
        veil_draw.ellipse((14 * u, 7 * u, work_size - 14 * u, work_size - 31 * u), fill=(20, 24, 26, 78))
        cell.alpha_composite(veil)
        draw = ImageDraw.Draw(cell)
        draw.rounded_rectangle((75 * u, 70 * u, 108 * u, 100 * u), radius=5 * u, fill=(227, 188, 86, 252), outline=(74, 45, 22, 255), width=2 * u)
        draw.arc((80 * u, 51 * u, 103 * u, 83 * u), 180, 360, fill=(239, 222, 174, 245), width=5 * u)
        draw.line((38 * u, 92 * u, 63 * u, 104 * u), fill=(238, 222, 165, 170), width=4 * u)
    return cell.resize((size, size), Image.Resampling.LANCZOS)


def _draw_spot_marker_sheet() -> Image.Image:
    sheet = Image.new("RGBA", (128 * len(SPOT_ORDER), 128 * 3), (0, 0, 0, 0))
    for row, state in enumerate(["normal", "selected", "locked"]):
        for col, spot_id in enumerate(SPOT_ORDER):
            sheet.alpha_composite(_draw_spot_marker(spot_id, state), (col * 128, row * 128))
    return sheet


def _draw_detail_icon_sheet() -> Image.Image:
    size = 96
    sheet = Image.new("RGBA", (size * 4, size), (0, 0, 0, 0))
    colors = [(18, 83, 119, 255), (18, 83, 119, 255), (166, 65, 33, 255), (156, 106, 35, 255)]
    for i in range(4):
        cell = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(cell)
        draw.ellipse((14, 14, size - 14, size - 14), fill=(241, 224, 181, 225), outline=(143, 94, 42, 230), width=3)
        c = colors[i]
        if i == 0:
            for y in [35, 48, 61]:
                draw.arc((24, y - 12, 72, y + 14), 200, 340, fill=c, width=5)
        elif i == 1:
            draw.polygon([(25, 49), (45, 34), (69, 49), (45, 64)], fill=c)
            draw.polygon([(69, 49), (82, 39), (82, 59)], fill=c)
            draw.ellipse((36, 45, 42, 51), fill=(245, 238, 196, 255))
        elif i == 2:
            draw.arc((25, 33, 69, 69), -40, 210, fill=c, width=7)
            draw.ellipse((22, 41, 37, 57), fill=(225, 139, 63, 255))
            draw.line((62, 56, 79, 68), fill=c, width=4)
        else:
            draw.polygon([(48, 21), (55, 43), (79, 43), (59, 56), (67, 79), (48, 64), (29, 79), (37, 56), (17, 43), (41, 43)], fill=c)
        sheet.alpha_composite(cell, (i * size, 0))
    return sheet


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
    draw.rectangle((11, 10, size[0] - 11, 42), fill=(10, 58, 85, 230) if not locked else (72, 78, 80, 174))
    draw.line((17, 18, size[0] - 17, 18), fill=(255, 255, 255, 42), width=1)
    draw.line((15, 43, size[0] - 15, 43), fill=accent, width=1)
    if not locked:
        _rounded(draw, (16, 49, size[0] - 16, size[1] - 14), 5, (240, 222, 184, 218), (124, 82, 38, 70), 1)
    else:
        _rounded(draw, (16, 49, size[0] - 16, size[1] - 14), 5, (202, 194, 171, 190), (94, 82, 61, 70), 1)
    return img


def _draw_route_chip_frame(size: tuple[int, int], locked: bool) -> Image.Image:
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    base = (205, 196, 174) if locked else (236, 216, 174)
    body = _paper_texture((size[0] - 8, size[1] - 8), 650 + int(locked), base)
    mask = Image.new("L", body.size, 0)
    draw_mask = ImageDraw.Draw(mask)
    draw_mask.rounded_rectangle((0, 0, body.width - 1, body.height - 1), radius=8, fill=255)
    img.paste(body, (4, 4), mask)

    draw = ImageDraw.Draw(img)
    border = (106, 95, 78, 220) if locked else (151, 99, 43, 235)
    accent = (115, 106, 91, 155) if locked else (219, 176, 86, 230)
    header = (65, 72, 72, 190) if locked else (9, 59, 87, 232)
    _rounded(draw, (4, 4, size[0] - 4, size[1] - 4), 8, None, border, 2)
    _rounded(draw, (8, 8, size[0] - 8, size[1] - 8), 5, None, accent, 1)
    draw.rectangle((9, 8, size[0] - 9, 27), fill=header)
    draw.line((13, 13, size[0] - 13, 13), fill=(255, 255, 255, 35), width=1)
    draw.line((13, 28, size[0] - 13, 28), fill=accent, width=1)
    if locked:
        draw.rectangle((10, 29, size[0] - 10, size[1] - 9), fill=(185, 178, 157, 112))
    else:
        draw.rectangle((10, 29, size[0] - 10, size[1] - 9), fill=(246, 227, 187, 92))
    return img


def _draw_completion_slot_frame(size: tuple[int, int], state: str) -> Image.Image:
    selected = state == "selected"
    locked = state == "locked"
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # A ledger cell, not a card. The parchment board underneath remains visible
    # so this row reads as progress records instead of selectable destinations.
    draw.line((0, 6, 0, size[1] - 6), fill=(91, 61, 32, 70), width=1)
    draw.line((size[0] - 1, 6, size[0] - 1, size[1] - 6), fill=(255, 238, 180, 30), width=1)
    fill = (241, 223, 184, 38) if not locked else (86, 82, 76, 42)
    if selected:
        fill = (255, 216, 82, 58)
    draw.rectangle((3, 6, size[0] - 3, size[1] - 6), fill=fill)

    rail = (7, 6, size[0] - 7, 27)
    rail_color = (68, 72, 70, 136) if locked else (6, 50, 76, 186)
    if selected:
        rail_color = (7, 60, 91, 210)
    _rounded(draw, rail, 3, rail_color, None, 1)
    draw.line((rail[0] + 8, rail[1] + 5, rail[2] - 8, rail[1] + 5), fill=(255, 255, 255, 25), width=1)

    draw.line((8, 30, size[0] - 8, 30), fill=(92, 65, 34, 54), width=1)
    if selected:
        draw.line((7, 4, size[0] - 7, 4), fill=(255, 216, 82, 180), width=2)
        draw.line((7, size[1] - 5, size[0] - 7, size[1] - 5), fill=(255, 216, 82, 145), width=2)
    if locked:
        draw.rectangle((7, 31, size[0] - 7, size[1] - 7), fill=(68, 66, 61, 28))
        draw.line((size[0] - 30, 35, size[0] - 17, 48), fill=(86, 76, 61, 90), width=2)
        draw.line((size[0] - 17, 35, size[0] - 30, 48), fill=(86, 76, 61, 90), width=2)
    return img


def _make_thumbnails(bg: Image.Image) -> None:
    THUMB_DIR.mkdir(parents=True, exist_ok=True)
    thumb_size = (420, 184)
    for spot_id in SPOT_ORDER:
        nx, ny = SPOT_POINTS[spot_id]
        cx = int(bg.width * nx)
        cy = int(bg.height * ny)
        crop_w = 620
        crop_h = 330
        if spot_id in {"bluewater_route", "deep_ocean"}:
            crop_w = 740
            crop_h = 380
        left = max(0, min(bg.width - crop_w, cx - crop_w // 2))
        top = max(0, min(bg.height - crop_h, cy - crop_h // 2))
        crop = bg.crop((left, top, left + crop_w, top + crop_h)).resize(thumb_size, Image.Resampling.LANCZOS)
        # Subtle vignette to sit inside the paper card.
        overlay = Image.new("RGBA", thumb_size, (0, 0, 0, 0))
        draw = ImageDraw.Draw(overlay)
        draw.rectangle((0, 0, thumb_size[0] - 1, thumb_size[1] - 1), outline=(42, 29, 18, 190), width=3)
        crop_rgba = crop.convert("RGBA")
        crop_rgba.alpha_composite(overlay)
        crop_rgba.save(THUMB_DIR / f"{spot_id}.png")


def build() -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(f"Missing source image: {SOURCE}")
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    source = Image.open(SOURCE).convert("RGB")
    bg = _enhance_map_bg(_cover_crop(source, (1920, 1080)))
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

    _draw_header_frame((1600, 128)).save(HEADER_FRAME_OUT)
    _draw_detail_frame((520, 760)).save(DETAIL_FRAME_OUT)
    _draw_footer_frame((1600, 146)).save(FOOTER_FRAME_OUT)

    sheet = Image.new("RGBA", (128 * 4, 128), (0, 0, 0, 0))
    for i, kind in enumerate(["normal", "selected", "locked", "boss"]):
        sheet.alpha_composite(_draw_marker_cell(kind), (i * 128, 0))
    sheet.save(MARKER_SHEET_OUT)
    _draw_spot_marker_sheet().save(SPOT_MARKER_SHEET_OUT)
    _draw_detail_icon_sheet().save(DETAIL_ICON_SHEET_OUT)

    _draw_card_frame((420, 128), locked=False).save(CARD_FRAME_OUT)
    _draw_card_frame((420, 128), locked=True).save(CARD_FRAME_LOCKED_OUT)
    _draw_route_chip_frame((360, 84), locked=False).save(ROUTE_CHIP_FRAME_OUT)
    _draw_route_chip_frame((360, 84), locked=True).save(ROUTE_CHIP_FRAME_LOCKED_OUT)
    _draw_completion_slot_frame((360, 78), "normal").save(COMPLETION_SLOT_FRAME_OUT)
    _draw_completion_slot_frame((360, 78), "selected").save(COMPLETION_SLOT_SELECTED_OUT)
    _draw_completion_slot_frame((360, 78), "locked").save(COMPLETION_SLOT_LOCKED_OUT)
    _make_thumbnails(bg)


def main() -> int:
    build()
    print(f"Generated fishing spot map assets in {OUT_DIR}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
