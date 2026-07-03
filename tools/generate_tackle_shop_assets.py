#!/usr/bin/env python3
"""Generate production PNG parts for the tackle shop screen.

The generated assets intentionally contain no Japanese text or runtime state.
Godot draws names, prices, ownership, money, and button labels at runtime.
"""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "showcase" / "tackle_shop"

W, H = 1280, 720
RNG = random.Random(240703)

WOOD_DARK = (63, 38, 22)
WOOD = (117, 72, 37)
WOOD_HI = (164, 106, 55)
NAVY = (16, 38, 60)
NAVY_DARK = (8, 20, 32)
GOLD = (225, 189, 114)
GOLD_HI = (255, 231, 168)
PAPER = (243, 232, 205)
PAPER_DEEP = (222, 200, 152)
INK = (32, 48, 66)
SHADOW = (0, 0, 0, 90)
TRANSPARENT = (0, 0, 0, 0)


def rgba(size: tuple[int, int], color=TRANSPARENT) -> Image.Image:
    return Image.new("RGBA", size, color)


def vertical_gradient(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int]) -> Image.Image:
    img = rgba(size)
    px = img.load()
    for y in range(size[1]):
        t = y / max(size[1] - 1, 1)
        color = tuple(round(top[i] * (1.0 - t) + bottom[i] * t) for i in range(3)) + (255,)
        for x in range(size[0]):
            px[x, y] = color
    return img


def add_noise(img: Image.Image, amount: int = 10, alpha: int = 34) -> Image.Image:
    overlay = rgba(img.size)
    draw = ImageDraw.Draw(overlay)
    for _ in range(img.size[0] * img.size[1] // 1800):
        x = RNG.randrange(img.size[0])
        y = RNG.randrange(img.size[1])
        r = RNG.randrange(1, 4)
        delta = RNG.randrange(-amount, amount + 1)
        base = max(0, min(255, 128 + delta))
        draw.ellipse((x - r, y - r, x + r, y + r), fill=(base, base, base, alpha))
    return Image.alpha_composite(img, overlay)


def rounded_panel(size: tuple[int, int], fill: tuple[int, int, int], border: tuple[int, int, int], radius: int = 14, border_w: int = 5) -> Image.Image:
    img = rgba(size)
    draw = ImageDraw.Draw(img)
    x2, y2 = size[0] - 1, size[1] - 1
    draw.rounded_rectangle((3, 5, x2 - 3, y2 - 2), radius, fill=(0, 0, 0, 76))
    draw.rounded_rectangle((0, 0, x2 - 6, y2 - 7), radius, fill=fill + (245,), outline=border + (255,), width=border_w)
    draw.rounded_rectangle((border_w + 3, border_w + 3, x2 - border_w - 9, y2 - border_w - 10), max(3, radius - border_w), outline=GOLD_HI + (150,), width=1)
    return add_noise(img, 8, 22)


def parchment_panel(size: tuple[int, int], selected: bool = False) -> Image.Image:
    fill = PAPER if not selected else (250, 236, 192)
    border = (139, 88, 39) if not selected else GOLD_HI
    img = rounded_panel(size, fill, border, radius=12, border_w=4 if selected else 3)
    draw = ImageDraw.Draw(img)
    inset = 12
    draw.rounded_rectangle((inset, inset, size[0] - inset - 8, size[1] - inset - 10), 8, outline=(103, 70, 38, 90), width=1)
    if selected:
        glow = rgba(size)
        gd = ImageDraw.Draw(glow)
        gd.rounded_rectangle((3, 3, size[0] - 10, size[1] - 10), 12, outline=(255, 231, 168, 160), width=5)
        img = Image.alpha_composite(img, glow.filter(ImageFilter.GaussianBlur(2)))
    return img


def shop_background() -> Image.Image:
    img = vertical_gradient((W, H), (83, 50, 28), (25, 16, 12))
    draw = ImageDraw.Draw(img)

    # Back wall planks.
    for x in range(-30, W, 62):
        color = (83 + RNG.randrange(-8, 12), 52 + RNG.randrange(-6, 8), 28 + RNG.randrange(-5, 6), 255)
        draw.rectangle((x, 0, x + 58, H), fill=color)
        draw.line((x + 58, 0, x + 58, H), fill=(29, 19, 13, 190), width=2)
    for y in (92, 190, 288, 388, 520):
        draw.rectangle((0, y, W, y + 13), fill=(41, 27, 17, 220))
        draw.line((0, y + 13, W, y + 13), fill=(185, 122, 62, 95), width=1)

    # Shelves and tackle silhouettes.
    shelf_zones = [(34, 126, 460), (494, 126, 760), (826, 124, 1210), (56, 328, 590)]
    for x1, y, x2 in shelf_zones:
        draw.rounded_rectangle((x1, y, x2, y + 20), 4, fill=(44, 27, 16, 255))
        draw.rectangle((x1 + 4, y - 4, x2 - 4, y + 4), fill=(155, 97, 47, 255))
        for x in range(x1 + 26, x2 - 12, 38):
            if RNG.random() < 0.52:
                draw.line((x, y - 74, x + RNG.randrange(-5, 6), y - 8), fill=(176, 135, 79, 210), width=3)
                draw.ellipse((x - 5, y - 86, x + 7, y - 74), outline=(216, 196, 140, 180), width=2)
            else:
                color = RNG.choice([(53, 103, 98), (157, 72, 44), (206, 178, 95), (39, 83, 124)])
                draw.rounded_rectangle((x - 8, y - 42, x + 10, y - 9), 5, fill=color + (215,), outline=(16, 24, 26, 190), width=1)
                draw.line((x + 1, y - 42, x + 1, y - 12), fill=(255, 240, 170, 70), width=1)

    # Counter and foreground depth.
    draw.rounded_rectangle((0, 540, W, 740), 18, fill=(55, 32, 20, 255))
    draw.rectangle((0, 540, W, 574), fill=(135, 78, 38, 255))
    for x in range(0, W, 76):
        draw.line((x, 550, x + 36, 720), fill=(30, 19, 14, 88), width=2)
    draw.rectangle((0, 620, W, H), fill=(0, 0, 0, 56))

    # Shopkeeper silhouette, visible behind right panel edges.
    cx, cy = 1040, 292
    draw.ellipse((cx - 70, cy - 120, cx + 62, cy + 10), fill=(92, 57, 35, 255))
    draw.ellipse((cx - 44, cy - 86, cx + 43, cy + 0), fill=(214, 164, 116, 255))
    draw.arc((cx - 42, cy - 62, cx + 42, cy + 34), 20, 160, fill=(86, 45, 25, 230), width=8)
    draw.rounded_rectangle((cx - 74, cy - 4, cx + 72, cy + 154), 34, fill=(34, 72, 78, 255), outline=(215, 171, 91, 120), width=2)
    draw.line((cx - 36, cy + 28, cx - 84, cy + 104), fill=(214, 164, 116, 230), width=12)
    draw.line((cx + 35, cy + 28, cx + 90, cy + 100), fill=(214, 164, 116, 230), width=12)

    # Vignette and working area scrim.
    vignette = rgba((W, H))
    vd = ImageDraw.Draw(vignette)
    for i in range(90):
        alpha = int(i * 1.25)
        vd.rectangle((i, i, W - i, H - i), outline=(0, 0, 0, max(0, 112 - alpha)), width=1)
    img = Image.alpha_composite(img, vignette)
    scrim = rgba((W, H), (0, 0, 0, 34))
    img = Image.alpha_composite(img, scrim)
    return add_noise(img, 12, 24).convert("RGBA")


def title_sign() -> Image.Image:
    img = rgba((430, 88))
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle((12, 18, 418, 78), 16, fill=(0, 0, 0, 72))
    draw.rounded_rectangle((2, 4, 410, 68), 14, fill=(176, 111, 52, 255), outline=(93, 53, 25, 255), width=4)
    draw.rounded_rectangle((18, 16, 394, 55), 9, fill=(220, 174, 94, 235), outline=GOLD_HI + (190,), width=2)
    for x in (45, 365):
        draw.ellipse((x - 9, 28, x + 9, 46), fill=(84, 51, 28, 230), outline=GOLD_HI + (160,), width=2)
    return add_noise(img, 8, 24)


def tab_frame(active: bool) -> Image.Image:
    fill = (161, 93, 39) if active else (70, 48, 33)
    border = GOLD_HI if active else (141, 103, 67)
    img = rounded_panel((168, 50), fill, border, radius=12, border_w=3)
    if active:
        shine = rgba((168, 50))
        draw = ImageDraw.Draw(shine)
        draw.rounded_rectangle((12, 8, 152, 22), 8, fill=(255, 241, 185, 52))
        img = Image.alpha_composite(img, shine)
    return img


def draw_rod(draw: ImageDraw.ImageDraw, cx: int, cy: int, length: int, color: tuple[int, int, int]) -> None:
    angle = -0.72
    x1 = cx - math.cos(angle) * length * 0.42
    y1 = cy - math.sin(angle) * length * 0.42
    x2 = cx + math.cos(angle) * length * 0.42
    y2 = cy + math.sin(angle) * length * 0.42
    draw.line((x1, y1, x2, y2), fill=color + (255,), width=5)
    draw.line((x2, y2, x2 + 12, y2 - 18), fill=color + (190,), width=2)
    for t in (0.18, 0.36, 0.55):
        rx = x1 * (1 - t) + x2 * t
        ry = y1 * (1 - t) + y2 * t
        draw.ellipse((rx - 5, ry - 5, rx + 5, ry + 5), outline=GOLD_HI + (230,), width=2)
    draw.ellipse((x1 - 13, y1 - 13, x1 + 13, y1 + 13), outline=(45, 50, 55, 255), width=4)
    draw.line((x1 - 14, y1 + 16, x1 + 18, y1 + 28), fill=(57, 36, 24, 255), width=6)


def draw_hook(draw: ImageDraw.ImageDraw, cx: int, cy: int, scale: float = 1.0) -> None:
    box = (cx - 20 * scale, cy - 18 * scale, cx + 22 * scale, cy + 28 * scale)
    draw.arc(box, 285, 105, fill=(218, 220, 205, 255), width=max(2, int(4 * scale)))
    draw.line((cx + 14 * scale, cy - 11 * scale, cx + 22 * scale, cy - 23 * scale), fill=(218, 220, 205, 255), width=max(2, int(3 * scale)))
    draw.line((cx - 1 * scale, cy - 16 * scale, cx - 1 * scale, cy - 45 * scale), fill=(210, 220, 218, 190), width=max(1, int(2 * scale)))


def item_icon_sheet() -> Image.Image:
    cell = 96
    img = rgba((cell * 9, cell))
    draw = ImageDraw.Draw(img)
    for i in range(9):
        x = i * cell
        draw.ellipse((x + 7, 7, x + 89, 89), fill=(19, 42, 63, 230), outline=GOLD + (190,), width=3)
        draw.ellipse((x + 16, 14, x + 80, 78), outline=(255, 255, 255, 38), width=2)

    for i, color in enumerate([(218, 186, 116), (104, 154, 142), (73, 110, 170)]):
        draw_rod(draw, i * cell + 48, 50, 88, color)

    # Sabiki beads.
    x = 3 * cell
    for j in range(5):
        draw.line((x + 46, 16, x + 46, 80), fill=(224, 232, 228, 180), width=2)
        draw.ellipse((x + 30 + j * 6, 24 + j * 10, x + 44 + j * 6, 38 + j * 10), fill=(214, 228, 98, 255), outline=(36, 50, 30, 180), width=1)
    draw_hook(draw, x + 50, 66, 0.75)

    # Float rig.
    x = 4 * cell
    draw.line((x + 49, 18, x + 49, 78), fill=(224, 232, 228, 180), width=2)
    draw.ellipse((x + 34, 26, x + 64, 58), fill=(230, 235, 212, 255), outline=(58, 70, 80, 220), width=2)
    draw.pieslice((x + 34, 26, x + 64, 58), 180, 360, fill=(199, 50, 45, 255))
    draw_hook(draw, x + 50, 72, 0.58)

    # Bottom rig.
    x = 5 * cell
    draw.line((x + 48, 14, x + 48, 75), fill=(220, 230, 225, 190), width=2)
    for dx in (-17, 17):
        draw.line((x + 48, 38, x + 48 + dx, 58), fill=(220, 230, 225, 190), width=2)
        draw_hook(draw, x + 48 + dx, 65, 0.5)
    draw.ellipse((x + 40, 68, x + 56, 84), fill=(93, 89, 86, 255), outline=(215, 205, 184, 160), width=1)

    # Live bait rig.
    x = 6 * cell
    draw.line((x + 48, 16, x + 48, 80), fill=(220, 230, 225, 190), width=2)
    draw.ellipse((x + 24, 38, x + 70, 62), fill=(71, 140, 153, 255), outline=(225, 245, 245, 190), width=2)
    draw.polygon([(x + 70, 50), (x + 86, 38), (x + 82, 62)], fill=(71, 140, 153, 255), outline=(225, 245, 245, 190))
    draw_hook(draw, x + 48, 75, 0.54)

    # Jig.
    x = 7 * cell
    draw.line((x + 48, 14, x + 48, 79), fill=(220, 230, 225, 190), width=2)
    draw.polygon([(x + 42, 24), (x + 60, 44), (x + 48, 72), (x + 31, 50)], fill=(55, 123, 175, 255), outline=(225, 245, 255, 190))
    draw.line((x + 36, 44, x + 58, 56), fill=(255, 238, 136, 200), width=3)
    draw_hook(draw, x + 52, 77, 0.48)

    # Crab bait.
    x = 8 * cell
    draw.line((x + 48, 14, x + 48, 80), fill=(220, 230, 225, 190), width=2)
    draw.ellipse((x + 31, 38, x + 65, 68), fill=(174, 76, 43, 255), outline=(255, 210, 155, 160), width=2)
    for dx in (-18, -10, 10, 18):
        draw.line((x + 48, 56, x + 48 + dx, 76), fill=(174, 76, 43, 230), width=3)
    draw.arc((x + 17, 28, x + 42, 52), 90, 250, fill=(230, 112, 62, 255), width=4)
    draw.arc((x + 54, 28, x + 79, 52), 290, 90, fill=(230, 112, 62, 255), width=4)
    return img


def bait_icon_sheet() -> Image.Image:
    cell = 64
    img = rgba((cell * 9, cell))
    draw = ImageDraw.Draw(img)
    colors = [
        (226, 122, 118), (235, 184, 126), (214, 196, 82),
        (173, 114, 79), (155, 132, 105), (236, 221, 169),
        (72, 140, 155), (62, 122, 190), (186, 75, 45),
    ]
    for i, color in enumerate(colors):
        x = i * cell
        draw.ellipse((x + 6, 6, x + 58, 58), fill=(18, 38, 54, 230), outline=GOLD + (150,), width=2)
        cx, cy = x + 32, 32
        if i in (0, 1, 2):
            for j in range(9):
                ang = j * math.tau / 9.0
                r = 8 + (j % 3) * 4
                draw.ellipse((cx + math.cos(ang) * r - 4, cy + math.sin(ang) * r - 4, cx + math.cos(ang) * r + 4, cy + math.sin(ang) * r + 4), fill=color + (255,))
        elif i == 3:
            draw.arc((x + 14, 16, x + 54, 54), 205, 40, fill=color + (255,), width=7)
        elif i in (4, 5):
            draw.pieslice((x + 15, 18, x + 54, 52), 205, 28, fill=color + (255,), outline=(88, 70, 48, 210), width=2)
        elif i == 6:
            draw.ellipse((x + 15, 24, x + 48, 42), fill=color + (255,), outline=(230, 248, 248, 180), width=2)
            draw.polygon([(x + 48, 33), (x + 58, 24), (x + 56, 44)], fill=color + (255,))
        elif i == 7:
            draw.polygon([(x + 29, 13), (x + 49, 31), (x + 35, 55), (x + 17, 37)], fill=color + (255,), outline=(230, 246, 255, 170))
            draw.line((x + 22, 34, x + 44, 42), fill=(255, 236, 130, 210), width=3)
        else:
            draw.ellipse((x + 18, 23, x + 47, 47), fill=color + (255,), outline=(255, 210, 155, 180), width=2)
            draw.line((x + 20, 35, x + 9, 46), fill=color + (230,), width=3)
            draw.line((x + 45, 35, x + 56, 46), fill=color + (230,), width=3)
    return img


def save(name: str, image: Image.Image) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    image.save(OUT / name)
    print(OUT / name)


def main() -> int:
    save("shop_bg.png", shop_background())
    save("shop_header_frame.png", rounded_panel((1244, 88), NAVY, GOLD, radius=14, border_w=4))
    save("shop_title_sign.png", title_sign())
    save("shop_detail_frame.png", rounded_panel((462, 500), NAVY_DARK, GOLD, radius=16, border_w=5))
    save("shop_notice_frame.png", rounded_panel((724, 60), NAVY_DARK, GOLD, radius=12, border_w=3))
    save("shop_card_frame.png", parchment_panel((220, 144), selected=False))
    save("shop_card_selected_frame.png", parchment_panel((220, 144), selected=True))
    save("shop_tab_frame.png", tab_frame(False))
    save("shop_tab_active_frame.png", tab_frame(True))
    save("shop_item_icon_sheet.png", item_icon_sheet())
    save("shop_bait_icon_sheet.png", bait_icon_sheet())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
