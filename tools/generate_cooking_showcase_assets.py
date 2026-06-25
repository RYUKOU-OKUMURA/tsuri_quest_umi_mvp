#!/usr/bin/env python3
"""Generate replaceable first-pass cooking showcase assets.

These are intentionally authored placeholders, not final art. They give the
Godot UI stable image slots for the cooking flow while keeping all assets
project-owned and deterministic.
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "showcase" / "cooking"


def rgba(hex_color: str, alpha: int = 255) -> tuple[int, int, int, int]:
    hex_color = hex_color.lstrip("#")
    return (
        int(hex_color[0:2], 16),
        int(hex_color[2:4], 16),
        int(hex_color[4:6], 16),
        alpha,
    )


def save(img: Image.Image, name: str) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(OUT / name)


def draw_panel(
    draw: ImageDraw.ImageDraw,
    box: tuple[int, int, int, int],
    fill: tuple[int, int, int, int],
    border: tuple[int, int, int, int],
    inner: tuple[int, int, int, int] | None = None,
    width: int = 4,
    radius: int = 8,
) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=border, width=width)
    if inner is not None:
        x0, y0, x1, y1 = box
        draw.rounded_rectangle(
            (x0 + width + 3, y0 + width + 3, x1 - width - 3, y1 - width - 3),
            radius=max(2, radius - 4),
            outline=inner,
            width=max(1, width // 2),
        )


def cooking_room_bg() -> None:
    w, h = 1280, 720
    img = Image.new("RGBA", (w, h), rgba("102035"))
    draw = ImageDraw.Draw(img, "RGBA")

    for y in range(h):
        t = y / max(1, h - 1)
        top = (22, 35, 50)
        mid = (95, 58, 28)
        bot = (17, 24, 32)
        if t < 0.62:
            u = t / 0.62
            col = tuple(int(top[i] * (1 - u) + mid[i] * u) for i in range(3))
        else:
            u = (t - 0.62) / 0.38
            col = tuple(int(mid[i] * (1 - u) + bot[i] * u) for i in range(3))
        draw.line((0, y, w, y), fill=(*col, 255))

    # Back wall planks.
    for x in range(0, w, 64):
        shade = 24 + (x // 64 % 2) * 9
        draw.rectangle((x, 92, x + 62, 470), fill=(70 + shade, 45 + shade // 2, 26, 116))
        draw.line((x, 92, x, 470), fill=(26, 18, 15, 155), width=2)
    for y in range(122, 470, 56):
        draw.line((0, y, w, y), fill=(26, 17, 12, 120), width=2)

    # Window and sea outside.
    draw_panel(draw, (930, 112, 1180, 302), rgba("1a2638", 240), rgba("583719"), rgba("d9a84f"), 6, 4)
    for yy in range(130, 286):
        t = (yy - 130) / 156
        col = (74, int(150 + 60 * (1 - t)), int(205 + 35 * (1 - t)), 255)
        draw.line((946, yy, 1164, yy), fill=col)
    draw.rectangle((946, 222, 1164, 286), fill=(24, 111, 151, 230))
    for i in range(16):
        y = 238 + i * 3
        draw.line((956, y, 1155, y + int(math.sin(i) * 2)), fill=(199, 239, 238, 90), width=1)
    draw.line((1054, 118, 1054, 294), fill=(76, 45, 22, 220), width=6)
    draw.line((940, 208, 1170, 208), fill=(76, 45, 22, 220), width=6)

    # Counter/floor.
    draw.polygon([(0, 498), (1280, 454), (1280, 720), (0, 720)], fill=(73, 42, 22, 235))
    for y in range(520, 720, 34):
        draw.line((0, y, 1280, y - 40), fill=(35, 22, 15, 120), width=2)

    # Lanterns and warm glows.
    for cx, cy, r in [(106, 188, 72), (1116, 98, 90), (872, 180, 54)]:
        glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        gd = ImageDraw.Draw(glow, "RGBA")
        for k in range(r, 0, -6):
            a = int(70 * (1 - k / r) ** 1.7)
            gd.ellipse((cx - k, cy - k, cx + k, cy + k), fill=(255, 180, 75, a))
        img.alpha_composite(glow)
        draw = ImageDraw.Draw(img, "RGBA")
        draw.ellipse((cx - 12, cy - 18, cx + 12, cy + 18), fill=(255, 205, 115, 210), outline=(84, 48, 24, 240), width=3)

    # Hanging herbs and kitchen silhouettes.
    for x in [390, 428, 772, 810]:
        draw.line((x, 84, x, 190), fill=(67, 42, 20, 210), width=3)
        for j in range(6):
            draw.ellipse((x - 18 + j * 4, 120 + j * 10, x + 10 + j * 4, 148 + j * 10), fill=(48, 95, 48, 150))
    for x, y, ww, hh in [(56, 390, 130, 90), (230, 372, 110, 92), (1110, 404, 120, 100)]:
        draw.rounded_rectangle((x, y, x + ww, y + hh), radius=8, fill=(22, 22, 24, 130), outline=(142, 96, 47, 130), width=2)

    # Readability glaze.
    overlay = Image.new("RGBA", (w, h), (7, 13, 22, 72))
    img.alpha_composite(overlay)
    save(img, "cooking_room_bg.png")


def fish_icon_sheet() -> None:
    names = [
        ("aji", rgba("5f8ea5"), rgba("d7eef4")),
        ("mejina", rgba("405869"), rgba("9eb7bd")),
        ("kasago", rgba("b55334"), rgba("ffb27a")),
        ("isaki", rgba("7e988a"), rgba("d6ddc0")),
        ("saba", rgba("5f88a7"), rgba("edf5ee")),
        ("boss", rgba("2f3f4d"), rgba("a8b1b3")),
    ]
    cell_w, cell_h = 192, 88
    img = Image.new("RGBA", (cell_w, cell_h * len(names)), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    for i, (_name, body, belly) in enumerate(names):
        ox, oy = 12, i * cell_h + 8
        draw.ellipse((ox + 16, oy + 16, ox + 132, oy + 62), fill=body, outline=(25, 25, 25, 230), width=3)
        draw.pieslice((ox + 44, oy + 32, ox + 132, oy + 72), 0, 180, fill=belly)
        draw.polygon([(ox + 132, oy + 38), (ox + 176, oy + 12), (ox + 166, oy + 44), (ox + 176, oy + 72)], fill=body, outline=(25, 25, 25, 220))
        draw.polygon([(ox + 64, oy + 14), (ox + 94, oy), (ox + 86, oy + 22)], fill=body.darker(0.1) if hasattr(body, "darker") else body)
        draw.ellipse((ox + 34, oy + 30, ox + 44, oy + 40), fill=(250, 250, 225, 240), outline=(20, 20, 20, 255))
        draw.ellipse((ox + 37, oy + 33, ox + 41, oy + 37), fill=(12, 12, 12, 255))
        for s in range(5):
            x = ox + 60 + s * 12
            draw.arc((x, oy + 26, x + 18, oy + 54), 90, 270, fill=(255, 255, 255, 68), width=2)
    save(img, "fish_icon_sheet.png")


def dish_icon_sheet() -> None:
    cell_w, cell_h = 220, 150
    img = Image.new("RGBA", (cell_w * 3, cell_h * 2), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    for idx in range(6):
        col = idx % 3
        row = idx // 3
        x, y = col * cell_w, row * cell_h
        # Plate shadow and plate.
        draw.ellipse((x + 32, y + 104, x + 190, y + 136), fill=(41, 28, 21, 70))
        draw.ellipse((x + 28, y + 36, x + 194, y + 126), fill=(237, 227, 202, 255), outline=(95, 73, 55, 210), width=4)
        draw.ellipse((x + 46, y + 52, x + 176, y + 112), fill=(205, 193, 170, 255))
        if idx == 0:  # salt grill
            draw.ellipse((x + 58, y + 58, x + 156, y + 96), fill=(150, 91, 40, 255), outline=(28, 20, 16, 220), width=3)
            draw.polygon([(x + 154, y + 77), (x + 196, y + 52), (x + 184, y + 82), (x + 196, y + 108)], fill=(145, 92, 43, 255), outline=(28, 20, 16, 220))
            draw.ellipse((x + 68, y + 70, x + 78, y + 80), fill=(22, 18, 16, 255))
            draw.pieslice((x + 142, y + 72, x + 178, y + 108), 300, 80, fill=(251, 220, 102, 255))
            draw.rectangle((x + 82, y + 48, x + 132, y + 56), fill=(54, 97, 52, 230))
        elif idx == 1:  # sashimi
            for k in range(5):
                draw.rounded_rectangle((x + 62 + k * 18, y + 58 + k % 2 * 6, x + 98 + k * 18, y + 90 + k % 2 * 6), radius=10, fill=(232, 122, 112, 255), outline=(245, 232, 220, 255), width=3)
            draw.ellipse((x + 126, y + 84, x + 168, y + 110), fill=(46, 118, 58, 230))
        elif idx == 2:  # simmered
            draw.ellipse((x + 50, y + 48, x + 178, y + 114), fill=(112, 70, 38, 255), outline=(54, 32, 20, 255), width=4)
            draw.ellipse((x + 64, y + 58, x + 166, y + 104), fill=(90, 48, 25, 255))
            for k in range(3):
                draw.ellipse((x + 72 + k * 26, y + 64, x + 106 + k * 26, y + 92), fill=(189, 142, 83, 255))
        elif idx == 3:  # soup
            draw.ellipse((x + 50, y + 48, x + 178, y + 116), fill=(117, 72, 39, 255), outline=(55, 33, 22, 255), width=4)
            draw.ellipse((x + 66, y + 58, x + 162, y + 102), fill=(225, 194, 132, 255))
            for k in range(4):
                draw.ellipse((x + 74 + k * 20, y + 66 + (k % 2) * 10, x + 96 + k * 20, y + 88 + (k % 2) * 10), fill=(238, 224, 183, 255), outline=(116, 92, 55, 180))
        elif idx == 4:  # fry
            for k in range(3):
                draw.rounded_rectangle((x + 62 + k * 34, y + 58 + k % 2 * 10, x + 108 + k * 34, y + 98 + k % 2 * 10), radius=14, fill=(205, 128, 38, 255), outline=(104, 58, 24, 255), width=3)
            draw.ellipse((x + 122, y + 82, x + 172, y + 112), fill=(66, 135, 55, 230))
        else:  # locked/special silhouette
            draw.rectangle((x + 74, y + 54, x + 150, y + 108), fill=(58, 50, 44, 210))
            draw.arc((x + 86, y + 38, x + 138, y + 88), 200, -20, fill=(225, 205, 150, 230), width=8)
            draw.rectangle((x + 94, y + 74, x + 132, y + 104), fill=(225, 205, 150, 230))
    save(img, "dish_icon_sheet.png")


def dish_feature() -> None:
    w, h = 620, 330
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    draw.rounded_rectangle((18, 22, w - 18, h - 22), radius=16, fill=(104, 65, 34, 245), outline=(225, 176, 96, 230), width=5)
    for x in range(28, w - 28, 32):
        draw.line((x, 30, x - 32, h - 32), fill=(77, 47, 28, 70), width=2)
    draw.ellipse((70, 196, 545, 292), fill=(38, 24, 18, 78))
    draw.ellipse((58, 70, 555, 276), fill=(230, 222, 199, 255), outline=(97, 70, 51, 240), width=6)
    draw.ellipse((90, 98, 520, 248), fill=(204, 194, 170, 255))
    draw.rectangle((166, 104, 410, 142), fill=(48, 104, 54, 210))
    draw.ellipse((132, 120, 405, 220), fill=(157, 92, 40, 255), outline=(28, 20, 16, 230), width=5)
    draw.polygon([(398, 166), (510, 96), (488, 168), (512, 238)], fill=(142, 88, 42, 255), outline=(28, 20, 16, 230))
    draw.polygon([(240, 112), (315, 62), (298, 130)], fill=(110, 78, 45, 255), outline=(28, 20, 16, 220))
    draw.ellipse((158, 150, 182, 174), fill=(244, 234, 204, 250), outline=(16, 14, 12, 255), width=3)
    draw.ellipse((166, 158, 174, 166), fill=(12, 10, 8, 255))
    for s in range(8):
        x = 220 + s * 22
        draw.arc((x, 126, x + 38, 208), 94, 268, fill=(245, 235, 205, 80), width=3)
    for dx, dy in [(430, 196), (454, 186), (470, 210)]:
        draw.ellipse((dx, dy, dx + 56, dy + 56), fill=(250, 222, 100, 255), outline=(124, 93, 32, 230), width=3)
        draw.line((dx + 8, dy + 46, dx + 48, dy + 10), fill=(255, 248, 185, 180), width=3)
    for _x, _y in [(394, 92), (420, 88), (444, 104), (386, 222), (212, 102)]:
        draw.ellipse((_x, _y, _x + 5, _y + 5), fill=(250, 246, 220, 190))
    save(img, "dish_feature_aji_shioyaki.png")


def frame_assets() -> None:
    specs = [
        ("recipe_card_frame.png", (280, 220), rgba("f4e5bf"), rgba("59371c"), rgba("f4c56b")),
        ("dish_detail_frame.png", (620, 560), rgba("f5e8c8"), rgba("59371c"), rgba("f4c56b")),
        ("meal_result_frame.png", (760, 240), rgba("102840", 238), rgba("59371c"), rgba("f4c56b")),
        ("level_up_frame.png", (680, 460), rgba("102840", 248), rgba("b47a2e"), rgba("ffe0a0")),
        ("status_card_frame.png", (320, 120), rgba("f4e7c9"), rgba("59371c"), rgba("d8a452")),
    ]
    for name, size, fill, border, inner in specs:
        img = Image.new("RGBA", size, (0, 0, 0, 0))
        shadow = Image.new("RGBA", size, (0, 0, 0, 0))
        sd = ImageDraw.Draw(shadow, "RGBA")
        sd.rounded_rectangle((14, 16, size[0] - 8, size[1] - 6), radius=12, fill=(0, 0, 0, 95))
        shadow = shadow.filter(ImageFilter.GaussianBlur(4))
        img.alpha_composite(shadow)
        draw = ImageDraw.Draw(img, "RGBA")
        draw_panel(draw, (8, 8, size[0] - 16, size[1] - 18), fill, border, inner, 5, 9)
        # Corner studs.
        for x, y in [(22, 22), (size[0] - 34, 22), (22, size[1] - 44), (size[0] - 34, size[1] - 44)]:
            draw.rectangle((x, y, x + 12, y + 12), fill=inner, outline=border, width=2)
        save(img, name)


def icon_sheets() -> None:
    img = Image.new("RGBA", (64 * 6, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    colors = [rgba("d94848"), rgba("3f86b7"), rgba("d8b04f"), rgba("7d54b7"), rgba("4fb36a"), rgba("d8a442")]
    for i, col in enumerate(colors):
        x = i * 64 + 8
        draw.ellipse((x, 8, x + 48, 56), fill=col, outline=(25, 20, 18, 230), width=3)
        if i == 0:
            draw.polygon([(x + 24, 48), (x + 8, 28), (x + 14, 16), (x + 24, 22), (x + 34, 16), (x + 42, 28)], fill=(255, 225, 210, 230))
        elif i == 1:
            draw.arc((x + 14, 16, x + 34, 40), 90, 270, fill=(240, 250, 255, 230), width=4)
            draw.line((x + 32, 18, x + 42, 26), fill=(240, 250, 255, 230), width=4)
        elif i == 2:
            draw.polygon([(x + 24, 10), (x + 30, 26), (x + 46, 26), (x + 33, 36), (x + 38, 52), (x + 24, 42), (x + 10, 52), (x + 15, 36), (x + 2, 26), (x + 18, 26)], fill=(255, 241, 134, 230))
        elif i == 3:
            draw.ellipse((x + 18, 12, x + 30, 24), fill=(245, 235, 255, 230))
            draw.ellipse((x + 30, 24, x + 42, 36), fill=(245, 235, 255, 230))
            draw.ellipse((x + 16, 34, x + 28, 46), fill=(245, 235, 255, 230))
        elif i == 4:
            draw.rectangle((x + 16, 16, x + 36, 44), fill=(236, 255, 218, 230))
            draw.arc((x + 18, 6, x + 44, 30), 200, -20, fill=(236, 255, 218, 230), width=5)
        else:
            draw.ellipse((x + 14, 14, x + 38, 38), fill=(255, 238, 128, 230), outline=(90, 55, 22, 220), width=2)
            draw.line((x + 26, 14, x + 26, 38), fill=(110, 67, 24, 180), width=3)
    save(img, "cooking_icon_sheet.png")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    cooking_room_bg()
    fish_icon_sheet()
    dish_icon_sheet()
    dish_feature()
    frame_assets()
    icon_sheets()
    print(f"generated cooking showcase assets in {OUT}")


if __name__ == "__main__":
    main()
