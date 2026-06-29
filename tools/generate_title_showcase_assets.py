#!/usr/bin/env python3
"""Generate raster assets for the opening/title screen showcase."""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tools" / "source_assets" / "title_opening_bg_source.png"
OUT_DIR = ROOT / "assets" / "showcase" / "title"

BG_OUT = OUT_DIR / "title_ocean_bg.png"
GRADE_OUT = OUT_DIR / "title_color_grade.png"
LOGO_FRAME_OUT = OUT_DIR / "title_logo_frame.png"
MENU_FRAME_OUT = OUT_DIR / "title_menu_frame.png"
BUTTON_PRIMARY_OUT = OUT_DIR / "title_button_primary.png"
BUTTON_PRIMARY_HOVER_OUT = OUT_DIR / "title_button_primary_hover.png"
BUTTON_PRIMARY_PRESSED_OUT = OUT_DIR / "title_button_primary_pressed.png"
BUTTON_SECONDARY_OUT = OUT_DIR / "title_button_secondary.png"
BUTTON_SECONDARY_HOVER_OUT = OUT_DIR / "title_button_secondary_hover.png"
BUTTON_DISABLED_OUT = OUT_DIR / "title_button_disabled.png"

BG_SIZE = (1920, 1080)


def _cover(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    scale = max(size[0] / image.width, size[1] / image.height)
    resized = image.resize((round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS)
    left = round((resized.width - size[0]) * 0.5)
    top = round((resized.height - size[1]) * 0.5)
    return resized.crop((left, top, left + size[0], top + size[1]))


def _blend_noise(image: Image.Image, rect: tuple[int, int, int, int], strength: int = 14) -> None:
    rng = random.Random(240629)
    pixels = image.load()
    x0, y0, x1, y1 = rect
    for y in range(y0, y1):
        for x in range(x0, x1):
            if rng.random() > 0.055:
                continue
            r, g, b, a = pixels[x, y]
            delta = rng.randint(-strength, strength)
            pixels[x, y] = (
                max(0, min(255, r + delta)),
                max(0, min(255, g + delta)),
                max(0, min(255, b + delta)),
                a,
            )


def _draw_corner_plates(draw: ImageDraw.ImageDraw, rect: tuple[int, int, int, int], size: int = 34) -> None:
    x0, y0, x1, y1 = rect
    fill = (214, 159, 75, 238)
    edge = (92, 51, 22, 230)
    shine = (255, 235, 160, 170)
    plates = [
        [(x0, y0 + size), (x0, y0), (x0 + size, y0), (x0 + size - 11, y0 + 11), (x0 + 11, y0 + size - 11)],
        [(x1, y0 + size), (x1, y0), (x1 - size, y0), (x1 - size + 11, y0 + 11), (x1 - 11, y0 + size - 11)],
        [(x0, y1 - size), (x0, y1), (x0 + size, y1), (x0 + size - 11, y1 - 11), (x0 + 11, y1 - size + 11)],
        [(x1, y1 - size), (x1, y1), (x1 - size, y1), (x1 - size + 11, y1 - 11), (x1 - 11, y1 - size + 11)],
    ]
    for points in plates:
        draw.polygon(points, fill=fill, outline=edge)
        draw.line(points[:3], fill=shine, width=2)


def _rounded_panel(
    size: tuple[int, int],
    outer: tuple[int, int, int, int],
    inner: tuple[int, int, int, int],
    accent: tuple[int, int, int, int],
    *,
    radius: int,
    margin: int,
    shadow: int = 16,
) -> Image.Image:
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    box = (shadow, shadow, size[0] - shadow, size[1] - shadow)
    for i in range(shadow, 0, -1):
        alpha = round(72 * (i / shadow) ** 1.7)
        draw.rounded_rectangle(
            (box[0] - i, box[1] - i // 2, box[2] + i, box[3] + i),
            radius=radius + i,
            fill=(0, 0, 0, alpha),
        )
    draw.rounded_rectangle(box, radius=radius, fill=outer)
    inner_box = (box[0] + margin, box[1] + margin, box[2] - margin, box[3] - margin)
    draw.rounded_rectangle(inner_box, radius=max(6, radius - margin), fill=inner)
    draw.rounded_rectangle(box, radius=radius, outline=(58, 33, 18, 240), width=4)
    draw.rounded_rectangle(
        (box[0] + 7, box[1] + 7, box[2] - 7, box[3] - 7),
        radius=radius - 4,
        outline=accent,
        width=3,
    )
    draw.rounded_rectangle(inner_box, radius=max(6, radius - margin), outline=(96, 63, 31, 150), width=2)
    _draw_corner_plates(draw, (box[0] + 5, box[1] + 5, box[2] - 5, box[3] - 5))
    return img


def build_background() -> None:
    source = Image.open(SOURCE).convert("RGB")
    bg = _cover(source, BG_SIZE)
    bg.save(BG_OUT)


def build_color_grade() -> None:
    w, h = BG_SIZE
    grade = Image.new("RGBA", BG_SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(grade)

    for y in range(h):
        t = y / max(1, h - 1)
        if t < 0.42:
            alpha = round(24 * (1.0 - t / 0.42))
            draw.line((0, y, w, y), fill=(255, 226, 150, alpha))
        else:
            alpha = round(112 * ((t - 0.42) / 0.58) ** 1.25)
            draw.line((0, y, w, y), fill=(1, 17, 32, alpha))

    right = Image.new("RGBA", BG_SIZE, (0, 0, 0, 0))
    rd = ImageDraw.Draw(right)
    for x in range(w):
        t = max(0.0, (x / w - 0.55) / 0.45)
        alpha = round(120 * t**1.45)
        rd.line((x, 0, x, h), fill=(0, 18, 32, alpha))
    grade.alpha_composite(right)

    vignette = Image.new("L", BG_SIZE, 0)
    px = vignette.load()
    cx, cy = w * 0.46, h * 0.44
    max_dist = math.hypot(max(cx, w - cx), max(cy, h - cy))
    for y in range(h):
        for x in range(w):
            d = math.hypot(x - cx, y - cy) / max_dist
            px[x, y] = max(0, min(125, round(((d - 0.42) / 0.58) ** 1.8 * 125))) if d > 0.42 else 0
    vignette = vignette.filter(ImageFilter.GaussianBlur(18))
    dark = Image.new("RGBA", BG_SIZE, (0, 8, 20, 0))
    dark.putalpha(vignette)
    grade.alpha_composite(dark)

    grade.save(GRADE_OUT)


def build_logo_frame() -> None:
    img = _rounded_panel(
        (1040, 274),
        outer=(13, 49, 76, 236),
        inner=(242, 225, 180, 236),
        accent=(235, 190, 93, 235),
        radius=28,
        margin=20,
        shadow=18,
    )
    draw = ImageDraw.Draw(img)
    body = (52, 52, 988, 222)
    draw.rounded_rectangle(body, radius=14, fill=(19, 63, 91, 212), outline=(251, 216, 126, 180), width=2)
    draw.rounded_rectangle((82, 82, 958, 192), radius=10, fill=(10, 35, 60, 126))
    draw.line((110, 71, 930, 71), fill=(255, 236, 162, 120), width=2)
    draw.line((132, 204, 908, 204), fill=(23, 104, 132, 160), width=2)
    for i in range(26):
        x = 110 + i * 32
        y = 58 + (i % 3) * 2
        draw.ellipse((x, y, x + 5, y + 5), fill=(255, 239, 170, 86))
    _blend_noise(img, (44, 44, 996, 230), 8)
    img.save(LOGO_FRAME_OUT)


def build_menu_frame() -> None:
    img = _rounded_panel(
        (590, 430),
        outer=(11, 44, 70, 240),
        inner=(238, 222, 179, 242),
        accent=(229, 181, 91, 232),
        radius=20,
        margin=18,
        shadow=18,
    )
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle((46, 44, 544, 92), radius=9, fill=(10, 67, 70, 222), outline=(247, 213, 121, 156), width=2)
    draw.rounded_rectangle((50, 112, 540, 368), radius=12, fill=(254, 240, 199, 220), outline=(130, 91, 45, 102), width=1)
    for y in (182, 256, 330):
        draw.line((76, y, 514, y), fill=(183, 145, 86, 72), width=1)
    for i in range(10):
        x = 78 + i * 42
        draw.line((x, 122, x + 18, 122), fill=(255, 247, 210, 72), width=1)
    _blend_noise(img, (50, 112, 540, 368), 10)
    img.save(MENU_FRAME_OUT)


def _button_frame(
    path: Path,
    fill: tuple[int, int, int, int],
    inner: tuple[int, int, int, int],
    glow: tuple[int, int, int, int],
    *,
    disabled: bool = False,
) -> None:
    w, h = (500, 78)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle((6, 9, w - 6, h - 4), radius=13, fill=(0, 0, 0, 82))
    draw.rounded_rectangle((10, 7, w - 10, h - 9), radius=11, fill=fill, outline=(74, 43, 22, 230), width=3)
    draw.rounded_rectangle((18, 15, w - 18, h - 17), radius=7, fill=inner, outline=glow, width=2)
    draw.line((34, 18, w - 34, 18), fill=(255, 241, 182, 110 if not disabled else 38), width=2)
    draw.line((40, h - 19, w - 40, h - 19), fill=(0, 16, 25, 82), width=2)
    for x in (30, w - 35):
        draw.polygon(
            [(x, h * 0.5), (x + (8 if x < w / 2 else -8), h * 0.5 - 8), (x + (8 if x < w / 2 else -8), h * 0.5 + 8)],
            fill=glow,
        )
    img.save(path)


def build_buttons() -> None:
    _button_frame(
        BUTTON_PRIMARY_OUT,
        (128, 75, 28, 246),
        (182, 125, 45, 236),
        (255, 226, 132, 220),
    )
    _button_frame(
        BUTTON_PRIMARY_HOVER_OUT,
        (156, 90, 32, 250),
        (217, 151, 54, 242),
        (255, 244, 176, 238),
    )
    _button_frame(
        BUTTON_PRIMARY_PRESSED_OUT,
        (92, 54, 27, 250),
        (138, 91, 38, 240),
        (212, 156, 78, 210),
    )
    _button_frame(
        BUTTON_SECONDARY_OUT,
        (8, 53, 79, 246),
        (13, 84, 104, 235),
        (229, 184, 90, 204),
    )
    _button_frame(
        BUTTON_SECONDARY_HOVER_OUT,
        (11, 69, 100, 248),
        (16, 111, 131, 238),
        (255, 225, 129, 226),
    )
    _button_frame(
        BUTTON_DISABLED_OUT,
        (67, 61, 54, 220),
        (96, 88, 78, 204),
        (157, 138, 104, 150),
        disabled=True,
    )


def main() -> int:
    if not SOURCE.exists():
        print(f"Missing source image: {SOURCE}")
        return 1
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    build_background()
    build_color_grade()
    build_logo_frame()
    build_menu_frame()
    build_buttons()
    for path in [
        BG_OUT,
        GRADE_OUT,
        LOGO_FRAME_OUT,
        MENU_FRAME_OUT,
        BUTTON_PRIMARY_OUT,
        BUTTON_PRIMARY_HOVER_OUT,
        BUTTON_PRIMARY_PRESSED_OUT,
        BUTTON_SECONDARY_OUT,
        BUTTON_SECONDARY_HOVER_OUT,
        BUTTON_DISABLED_OUT,
    ]:
        print(path.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
