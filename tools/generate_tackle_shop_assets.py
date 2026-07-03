#!/usr/bin/env python3
"""Generate production PNG parts for the no-shopkeeper tackle shop screen.

The full shop backplates contain the environment, product illustrations,
ornamental cards, empty nameplates, and empty detail panels. Godot still draws
all Japanese text, prices, ownership state, money, and button labels at runtime.
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tools" / "source_assets"
OUT = ROOT / "assets" / "showcase" / "tackle_shop"

W, H = 1280, 720
ITEM_CELL = 128
DETAIL_CELL = 256
BAIT_CELL = 64
GOLD = (225, 189, 114)
GOLD_DARK = (116, 82, 34)
NAVY = (18, 38, 58)
PARCHMENT = (228, 203, 158)
PARCHMENT_DARK = (149, 111, 68)
TRANSPARENT = (0, 0, 0, 0)

CARD_SOURCE_RECTS = [
    (190, 92, 386, 328),
    (384, 92, 580, 328),
    (578, 92, 774, 328),
    (190, 330, 386, 566),
    (384, 330, 580, 566),
    (578, 330, 774, 566),
]

CARD_DEST_RECTS = [
    (216, 88, 408, 338),
    (414, 88, 606, 338),
    (612, 88, 804, 338),
    (216, 344, 408, 594),
    (414, 344, 606, 594),
    (612, 344, 804, 594),
]

DETAIL_CLEAN_BOX = (848, 100, 1188, 378)
DETAIL_TITLE_BOX = (884, 104, 1182, 160)
ROD_TAB_BOX = (82, 642, 178, 700)
RIG_TAB_BOX = (182, 642, 306, 700)
PRODUCT_CROPS = [
    (238, 140, 135, 145),  # starter
    (438, 136, 132, 150),  # iso
    (622, 134, 148, 152),  # offshore
    (232, 390, 150, 145),  # big_game
    (426, 390, 165, 145),  # marlin
    (198, 136, 160, 132),  # sabiki
    (416, 136, 145, 142),  # uki
    (608, 136, 160, 142),  # chokusen
    (206, 382, 160, 118),  # nomase
    (414, 378, 150, 125),  # jigging
    (612, 382, 160, 117),  # kani
]


def fit_1280x720(path: Path) -> Image.Image:
    image = Image.open(path).convert("RGBA")
    fitted = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    image.thumbnail((W, H), Image.Resampling.LANCZOS)
    fitted.alpha_composite(image, ((W - image.width) // 2, (H - image.height) // 2))
    return fitted


def parchment_patch(size: tuple[int, int]) -> Image.Image:
    width, height = size
    patch = Image.new("RGBA", size, PARCHMENT + (255,))
    pixels = patch.load()
    for y in range(height):
        for x in range(width):
            wave = int(8 * math.sin((x + y * 0.7) / 23.0) + 5 * math.sin((x * 0.9 - y) / 31.0))
            speckle = ((x * 37 + y * 19 + (x * y) % 17) % 15) - 7
            r = max(0, min(255, PARCHMENT[0] + wave + speckle))
            g = max(0, min(255, PARCHMENT[1] + wave + speckle))
            b = max(0, min(255, PARCHMENT[2] + wave + speckle))
            pixels[x, y] = (r, g, b, 255)
    return patch


def clean_detail_panel(image: Image.Image) -> Image.Image:
    cleaned = image.copy()
    x0, y0, x1, y1 = DETAIL_CLEAN_BOX
    patch = parchment_patch((x1 - x0, y1 - y0))
    cleaned.alpha_composite(patch, (x0, y0))
    draw = ImageDraw.Draw(cleaned, "RGBA")
    draw.rounded_rectangle(
        (x0, y0, x1, y1),
        radius=8,
        outline=PARCHMENT_DARK + (120,),
        width=2,
    )
    draw.rounded_rectangle(DETAIL_TITLE_BOX, radius=11, fill=NAVY + (245,), outline=GOLD_DARK + (230,), width=3)
    inset = (DETAIL_TITLE_BOX[0] + 8, DETAIL_TITLE_BOX[1] + 8, DETAIL_TITLE_BOX[2] - 8, DETAIL_TITLE_BOX[3] - 8)
    draw.rounded_rectangle(inset, radius=8, outline=GOLD + (110,), width=1)
    return cleaned


def draw_neutral_tabs(image: Image.Image) -> None:
    draw = ImageDraw.Draw(image, "RGBA")
    for box in (ROD_TAB_BOX, RIG_TAB_BOX):
        draw.rounded_rectangle(box, radius=8, fill=NAVY + (242,), outline=GOLD_DARK + (230,), width=3)
        inset = (box[0] + 5, box[1] + 5, box[2] - 5, box[3] - 5)
        draw.rounded_rectangle(inset, radius=6, outline=GOLD + (120,), width=1)


def compose_rig_backplate(rod_layout: Image.Image, rig_source: Image.Image) -> Image.Image:
    composed = rod_layout.copy()
    for source_box, dest_box in zip(CARD_SOURCE_RECTS, CARD_DEST_RECTS):
        crop = rig_source.crop(source_box)
        crop = crop.resize((dest_box[2] - dest_box[0], dest_box[3] - dest_box[1]), Image.Resampling.LANCZOS)
        composed.alpha_composite(crop, (dest_box[0], dest_box[1]))
    return composed


def product_cutout(source: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    x, y, width, height = box
    crop = source.crop((x, y, x + width, y + height)).convert("RGBA")
    pixels = crop.load()
    for y in range(crop.height):
        for x in range(crop.width):
            r, g, b, a = pixels[x, y]
            tan_bg = r > 165 and g > 135 and b > 85 and r > b + 35 and g > b + 15
            light_bg = r > 195 and g > 170 and b > 125 and r > b + 25 and g > b + 10
            if tan_bg or light_bg:
                pixels[x, y] = (r, g, b, 0)
                continue
            edge = min(x, y, crop.width - 1 - x, crop.height - 1 - y)
            if edge < 8:
                pixels[x, y] = (r, g, b, int(float(a) * float(edge) / 8.0))
    bbox = crop.getchannel("A").getbbox()
    if bbox is not None:
        crop = crop.crop(bbox)
    return crop


def product_sheet(rod: Image.Image, rig: Image.Image, cell_size: int, padding: int) -> Image.Image:
    sources = [rod] * 5 + [rig] * 6
    sheet = Image.new("RGBA", (cell_size * len(PRODUCT_CROPS), cell_size), TRANSPARENT)
    for index, (source, box) in enumerate(zip(sources, PRODUCT_CROPS)):
        crop = product_cutout(source, box)
        crop.thumbnail((cell_size - padding * 2, cell_size - padding * 2), Image.Resampling.LANCZOS)
        tile = Image.new("RGBA", (cell_size, cell_size), TRANSPARENT)
        tile.alpha_composite(crop, ((cell_size - crop.width) // 2, (cell_size - crop.height) // 2))
        sheet.alpha_composite(tile, (index * cell_size, 0))
    return sheet


def item_icon_sheet(rod: Image.Image, rig: Image.Image) -> Image.Image:
    return product_sheet(rod, rig, ITEM_CELL, 6)


def detail_icon_sheet(rod: Image.Image, rig: Image.Image) -> Image.Image:
    return product_sheet(rod, rig, DETAIL_CELL, 14)


def bait_icon_sheet() -> Image.Image:
    image = Image.new("RGBA", (BAIT_CELL * 9, BAIT_CELL), TRANSPARENT)
    draw = ImageDraw.Draw(image)
    colors = [
        (226, 122, 118),
        (235, 184, 126),
        (214, 196, 82),
        (173, 114, 79),
        (155, 132, 105),
        (236, 221, 169),
        (72, 140, 155),
        (62, 122, 190),
        (186, 75, 45),
    ]
    for i, color in enumerate(colors):
        x = i * BAIT_CELL
        draw.ellipse((x + 6, 6, x + 58, 58), fill=NAVY + (230,), outline=GOLD + (150,), width=2)
        cx, cy = x + 32, 32
        if i in (0, 1, 2):
            for j in range(9):
                angle = j * math.tau / 9.0
                r = 8 + (j % 3) * 4
                draw.ellipse(
                    (
                        cx + math.cos(angle) * r - 4,
                        cy + math.sin(angle) * r - 4,
                        cx + math.cos(angle) * r + 4,
                        cy + math.sin(angle) * r + 4,
                    ),
                    fill=color + (255,),
                )
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
    return image


def save(name: str, image: Image.Image) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    image.save(OUT / name)
    print(OUT / name)


def main() -> int:
    rod_source = fit_1280x720(SOURCE / "tackle_shop_rod_backplate_source.png")
    rig_source = fit_1280x720(SOURCE / "tackle_shop_rig_backplate_source.png")
    rod = clean_detail_panel(rod_source)
    draw_neutral_tabs(rod)
    rig = compose_rig_backplate(rod, rig_source)
    save("shop_rod_backplate.png", rod)
    save("shop_rig_backplate.png", rig)
    save("shop_item_icon_sheet.png", item_icon_sheet(rod_source, rig_source))
    save("shop_detail_item_sheet.png", detail_icon_sheet(rod_source, rig_source))
    save("shop_bait_icon_sheet.png", bait_icon_sheet())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
