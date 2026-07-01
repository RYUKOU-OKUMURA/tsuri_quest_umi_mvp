#!/usr/bin/env python3
"""Generate raster assets for the harbor hub showcase screen."""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tools" / "source_assets" / "harbor_hub_bg_source.png"
OUT_DIR = ROOT / "assets" / "showcase" / "harbor"

BG_OUT = OUT_DIR / "harbor_hub_bg.png"
GRADE_OUT = OUT_DIR / "harbor_color_grade.png"
SCENE_OUT = OUT_DIR / "harbor_scene_window.png"
TOP_FRAME_OUT = OUT_DIR / "harbor_top_frame.png"
MAIN_FRAME_OUT = OUT_DIR / "harbor_main_frame.png"
MENU_FRAME_OUT = OUT_DIR / "harbor_menu_frame.png"
FOOTER_FRAME_OUT = OUT_DIR / "harbor_footer_frame.png"
PARCHMENT_CARD_OUT = OUT_DIR / "harbor_parchment_card.png"
FACILITY_CARD_OUT = OUT_DIR / "harbor_facility_card.png"
FACILITY_CARD_HOVER_OUT = OUT_DIR / "harbor_facility_card_hover.png"
FACILITY_CARD_PRIMARY_OUT = OUT_DIR / "harbor_facility_card_primary.png"

BG_SIZE = (1920, 1080)


def _cover(image: Image.Image, size: tuple[int, int], align: tuple[float, float] = (0.5, 0.5)) -> Image.Image:
    scale = max(size[0] / image.width, size[1] / image.height)
    resized = image.resize((round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS)
    left = round((resized.width - size[0]) * align[0])
    top = round((resized.height - size[1]) * align[1])
    return resized.crop((left, top, left + size[0], top + size[1]))


def _blend_noise(image: Image.Image, rect: tuple[int, int, int, int], strength: int = 10, rate: float = 0.035) -> None:
    rng = random.Random(20260629)
    pixels = image.load()
    x0, y0, x1, y1 = rect
    for y in range(y0, y1):
        for x in range(x0, x1):
            if rng.random() > rate:
                continue
            r, g, b, a = pixels[x, y]
            delta = rng.randint(-strength, strength)
            pixels[x, y] = (
                max(0, min(255, r + delta)),
                max(0, min(255, g + delta)),
                max(0, min(255, b + delta)),
                a,
            )


def _draw_corner_plates(draw: ImageDraw.ImageDraw, rect: tuple[int, int, int, int], size: int = 30) -> None:
    x0, y0, x1, y1 = rect
    fill = (219, 166, 79, 242)
    edge = (74, 43, 22, 235)
    shine = (255, 236, 162, 150)
    plates = [
        [(x0, y0 + size), (x0, y0), (x0 + size, y0), (x0 + size - 10, y0 + 10), (x0 + 10, y0 + size - 10)],
        [(x1, y0 + size), (x1, y0), (x1 - size, y0), (x1 - size + 10, y0 + 10), (x1 - 10, y0 + size - 10)],
        [(x0, y1 - size), (x0, y1), (x0 + size, y1), (x0 + size - 10, y1 - 10), (x0 + 10, y1 - size + 10)],
        [(x1, y1 - size), (x1, y1), (x1 - size, y1), (x1 - size + 10, y1 - 10), (x1 - 10, y1 - size + 10)],
    ]
    for points in plates:
        draw.polygon(points, fill=fill, outline=edge)
        draw.line(points[:3], fill=shine, width=2)


def _panel(
    size: tuple[int, int],
    *,
    fill: tuple[int, int, int, int],
    body: tuple[int, int, int, int],
    accent: tuple[int, int, int, int],
    radius: int = 16,
    margin: int = 16,
    shadow: int = 14,
    corners: bool = True,
) -> Image.Image:
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    box = (shadow, shadow, size[0] - shadow, size[1] - shadow)
    for i in range(shadow, 0, -1):
        alpha = round(74 * (i / shadow) ** 1.8)
        draw.rounded_rectangle(
            (box[0] - i, box[1] - i // 2, box[2] + i, box[3] + i),
            radius=radius + i,
            fill=(0, 0, 0, alpha),
        )
    draw.rounded_rectangle(box, radius=radius, fill=fill)
    inner = (box[0] + margin, box[1] + margin, box[2] - margin, box[3] - margin)
    draw.rounded_rectangle(inner, radius=max(4, radius - margin // 2), fill=body)
    draw.rounded_rectangle(box, radius=radius, outline=(48, 29, 17, 245), width=4)
    draw.rounded_rectangle((box[0] + 7, box[1] + 7, box[2] - 7, box[3] - 7), radius=max(4, radius - 4), outline=accent, width=2)
    if corners:
        _draw_corner_plates(draw, (box[0] + 3, box[1] + 3, box[2] - 3, box[3] - 3), 34)
    return img


def build_background() -> Image.Image:
    source = Image.open(SOURCE).convert("RGB")
    bg = _cover(source, BG_SIZE)
    bg.save(BG_OUT)
    return bg


def build_color_grade() -> None:
    w, h = BG_SIZE
    grade = Image.new("RGBA", BG_SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(grade)
    for y in range(h):
        t = y / max(1, h - 1)
        top_alpha = round(max(0.0, 1.0 - t / 0.55) * 32)
        bottom_alpha = round(max(0.0, (t - 0.54) / 0.46) ** 1.35 * 98)
        draw.line((0, y, w, y), fill=(0, 11, 24, bottom_alpha))
        if top_alpha > 0:
            draw.line((0, y, w, y), fill=(255, 231, 156, top_alpha))

    right = Image.new("RGBA", BG_SIZE, (0, 0, 0, 0))
    rd = ImageDraw.Draw(right)
    for x in range(w):
        t = max(0.0, (x / w - 0.58) / 0.42)
        rd.line((x, 0, x, h), fill=(0, 18, 32, round(82 * t**1.4)))
    grade.alpha_composite(right)

    vignette = Image.new("L", BG_SIZE, 0)
    px = vignette.load()
    cx, cy = w * 0.47, h * 0.42
    max_dist = math.hypot(max(cx, w - cx), max(cy, h - cy))
    for y in range(h):
        for x in range(w):
            d = math.hypot(x - cx, y - cy) / max_dist
            px[x, y] = max(0, min(115, round(((d - 0.52) / 0.48) ** 1.7 * 115))) if d > 0.52 else 0
    vignette = vignette.filter(ImageFilter.GaussianBlur(18))
    dark = Image.new("RGBA", BG_SIZE, (0, 8, 18, 0))
    dark.putalpha(vignette)
    grade.alpha_composite(dark)
    grade.save(GRADE_OUT)


def build_scene_window(bg: Image.Image) -> None:
    # Crop the brightest central harbor postcard area, leaving detailed pier/boats visible.
    scene = bg.crop((250, 230, 1420, 650)).resize((1170, 420), Image.Resampling.LANCZOS)
    overlay = Image.new("RGBA", scene.size, (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.rounded_rectangle((0, 0, scene.width - 1, scene.height - 1), radius=16, outline=(245, 209, 116, 210), width=5)
    od.rounded_rectangle((8, 8, scene.width - 9, scene.height - 9), radius=11, outline=(12, 42, 58, 220), width=3)
    scene = scene.convert("RGBA")
    scene.alpha_composite(overlay)
    scene.save(SCENE_OUT)


def build_frames() -> None:
    _panel(
        (1900, 118),
        fill=(7, 28, 48, 244),
        body=(11, 44, 72, 232),
        accent=(223, 171, 83, 230),
        radius=14,
        margin=10,
        shadow=10,
    ).save(TOP_FRAME_OUT)

    main = _panel(
        (1220, 810),
        fill=(8, 31, 54, 244),
        body=(13, 50, 78, 230),
        accent=(223, 171, 83, 226),
        radius=18,
        margin=14,
        shadow=16,
    )
    draw = ImageDraw.Draw(main)
    draw.rounded_rectangle((44, 44, 1176, 338), radius=14, fill=(6, 24, 40, 116), outline=(236, 196, 102, 155), width=2)
    draw.rounded_rectangle((54, 362, 1166, 540), radius=14, fill=(247, 231, 190, 235), outline=(106, 76, 36, 165), width=2)
    draw.rounded_rectangle((54, 566, 1166, 744), radius=14, fill=(247, 231, 190, 235), outline=(106, 76, 36, 165), width=2)
    _blend_noise(main, (54, 362, 1166, 744), 9, 0.030)
    main.save(MAIN_FRAME_OUT)

    menu = _panel(
        (680, 810),
        fill=(9, 32, 54, 246),
        body=(249, 236, 202, 250),
        accent=(225, 174, 83, 230),
        radius=18,
        margin=16,
        shadow=16,
    )
    draw = ImageDraw.Draw(menu)
    draw.rounded_rectangle((50, 48, 630, 112), radius=12, fill=(10, 56, 76, 230), outline=(239, 198, 102, 170), width=2)
    _blend_noise(menu, (58, 132, 622, 748), 5, 0.012)
    menu.save(MENU_FRAME_OUT)

    _panel(
        (1900, 92),
        fill=(6, 26, 45, 244),
        body=(10, 43, 70, 232),
        accent=(224, 171, 83, 226),
        radius=12,
        margin=9,
        shadow=9,
        corners=False,
    ).save(FOOTER_FRAME_OUT)

    parchment = _panel(
        (1180, 188),
        fill=(151, 106, 48, 210),
        body=(247, 231, 190, 238),
        accent=(218, 166, 76, 190),
        radius=13,
        margin=8,
        shadow=9,
        corners=False,
    )
    _blend_noise(parchment, (20, 20, 1160, 168), 9, 0.038)
    parchment.save(PARCHMENT_CARD_OUT)


def _facility_card(path: Path, *, primary: bool = False, hover: bool = False) -> None:
    size = (580, 94)
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    if primary:
        fill = (6, 61, 84, 248)
        body = (8, 84, 110, 246)
        accent = (245, 198, 90, 238)
    elif hover:
        fill = (163, 105, 42, 244)
        body = (255, 242, 205, 248)
        accent = (246, 194, 84, 236)
    else:
        fill = (130, 84, 38, 240)
        body = (252, 239, 205, 248)
        accent = (157, 103, 47, 190)
    draw.rounded_rectangle((8, 11, size[0] - 8, size[1] - 6), radius=10, fill=(0, 0, 0, 75))
    draw.rounded_rectangle((12, 8, size[0] - 12, size[1] - 10), radius=9, fill=fill, outline=(55, 33, 18, 230), width=3)
    draw.rounded_rectangle((22, 18, size[0] - 22, size[1] - 20), radius=7, fill=body, outline=accent, width=2)
    line_start = 432
    draw.line((line_start, 22, size[0] - 54, 22), fill=(255, 239, 169, 82 if primary or hover else 32), width=2)
    draw.line((line_start, size[1] - 25, size[0] - 54, size[1] - 25), fill=(36, 23, 14, 24), width=1)
    for x in (34, size[0] - 40):
        sign = 1 if x < size[0] / 2 else -1
        draw.polygon(
            [(x, size[1] * 0.50), (x + sign * 8, size[1] * 0.39), (x + sign * 8, size[1] * 0.61)],
            fill=accent,
        )
    img.save(path)


def build_buttons() -> None:
    _facility_card(FACILITY_CARD_OUT)
    _facility_card(FACILITY_CARD_HOVER_OUT, hover=True)
    _facility_card(FACILITY_CARD_PRIMARY_OUT, primary=True)


def main() -> int:
    if not SOURCE.exists():
        print(f"Missing source image: {SOURCE}")
        return 1
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    bg = build_background()
    build_color_grade()
    build_scene_window(bg)
    build_frames()
    build_buttons()
    for path in [
        BG_OUT,
        GRADE_OUT,
        SCENE_OUT,
        TOP_FRAME_OUT,
        MAIN_FRAME_OUT,
        MENU_FRAME_OUT,
        FOOTER_FRAME_OUT,
        PARCHMENT_CARD_OUT,
        FACILITY_CARD_OUT,
        FACILITY_CARD_HOVER_OUT,
        FACILITY_CARD_PRIMARY_OUT,
    ]:
        print(path.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
