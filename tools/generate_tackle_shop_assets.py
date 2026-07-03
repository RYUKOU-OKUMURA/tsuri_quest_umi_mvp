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
BAIT_CELL = 64
GOLD = (225, 189, 114)
NAVY = (18, 38, 58)
TRANSPARENT = (0, 0, 0, 0)


def fit_1280x720(path: Path) -> Image.Image:
    image = Image.open(path).convert("RGBA")
    fitted = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    image.thumbnail((W, H), Image.Resampling.LANCZOS)
    fitted.alpha_composite(image, ((W - image.width) // 2, (H - image.height) // 2))
    return fitted


def item_icon_sheet(rod: Image.Image, rig: Image.Image) -> Image.Image:
    crops = [
        (rod, 184, 120, 210, 175),  # starter
        (rod, 382, 118, 210, 178),  # iso
        (rod, 580, 116, 210, 180),  # offshore
        (rod, 184, 363, 210, 175),  # big_game
        (rod, 382, 360, 210, 178),  # marlin
        (rig, 165, 125, 190, 120),  # sabiki
        (rig, 390, 122, 190, 128),  # uki
        (rig, 614, 119, 190, 132),  # chokusen
        (rig, 165, 350, 190, 130),  # nomase
        (rig, 390, 348, 190, 130),  # jigging
        (rig, 614, 348, 190, 132),  # kani
    ]
    sheet = Image.new("RGBA", (ITEM_CELL * len(crops), ITEM_CELL), TRANSPARENT)
    for index, (source, x, y, w, h) in enumerate(crops):
        crop = source.crop((x, y, x + w, y + h))
        crop.thumbnail((ITEM_CELL - 10, ITEM_CELL - 10), Image.Resampling.LANCZOS)
        tile = Image.new("RGBA", (ITEM_CELL, ITEM_CELL), TRANSPARENT)
        tile.alpha_composite(crop, ((ITEM_CELL - crop.width) // 2, (ITEM_CELL - crop.height) // 2))
        sheet.alpha_composite(tile, (index * ITEM_CELL, 0))
    return sheet


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
    rod = fit_1280x720(SOURCE / "tackle_shop_rod_backplate_source.png")
    rig = fit_1280x720(SOURCE / "tackle_shop_rig_backplate_source.png")
    save("shop_rod_backplate.png", rod)
    save("shop_rig_backplate.png", rig)
    save("shop_item_icon_sheet.png", item_icon_sheet(rod, rig))
    save("shop_bait_icon_sheet.png", bait_icon_sheet())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
