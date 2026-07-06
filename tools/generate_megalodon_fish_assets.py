#!/usr/bin/env python3
"""Generate E10 megalodon fish assets from the E4 white shark source."""
from __future__ import annotations

import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance


ROOT = Path(__file__).resolve().parents[1]
TOOLS_DIR = ROOT / "tools"
sys.path.insert(0, str(TOOLS_DIR))

from generate_shark_fish_assets import (  # noqa: E402
    CONTACT_SHEET,
    FISH_DIR,
    _add_card_shadow,
    _contain_alpha,
    _make_sheet_from_source,
    _remove_chroma_green,
    _trim_alpha,
)


SOURCE_DIR = ROOT / "tools" / "source_assets" / "fish" / "shark_e4_realistic_sources"
BASE_SOURCE = SOURCE_DIR / "nushi_danger_reef_source.png"
MEGALODON_SOURCE = SOURCE_DIR / "megalodon_source.png"
MEGALODON_CONTACT = ROOT / "tools" / "source_assets" / "fish" / "megalodon_contact_sheet.png"
CARD_SIZE = (560, 310)


def main() -> None:
    if not BASE_SOURCE.exists():
        raise FileNotFoundError(BASE_SOURCE)
    FISH_DIR.mkdir(parents=True, exist_ok=True)
    SOURCE_DIR.mkdir(parents=True, exist_ok=True)

    source = _make_megalodon_source(Image.open(BASE_SOURCE).convert("RGBA"))
    MEGALODON_SOURCE.parent.mkdir(parents=True, exist_ok=True)
    source.save(MEGALODON_SOURCE)

    card = _add_card_shadow(_contain_alpha(_readability_pass(source), CARD_SIZE, margin=6))
    sheet = _make_sheet_from_source(source)
    card.save(FISH_DIR / "megalodon_card_portrait.png")
    sheet.save(FISH_DIR / "megalodon_showcase_sheet.png")
    _build_contact(card, sheet).save(MEGALODON_CONTACT)
    print("generated megalodon fish asset pair")
    print(MEGALODON_SOURCE)
    print(MEGALODON_CONTACT)
    print(CONTACT_SHEET)


def _make_megalodon_source(base: Image.Image) -> Image.Image:
    shark = _trim_alpha(_remove_chroma_green(base))
    shark = shark.resize(
        (round(shark.width * 1.07), round(shark.height * 1.05)),
        Image.Resampling.LANCZOS,
    )
    alpha = shark.getchannel("A")
    rgb = shark.convert("RGB")
    pixels = rgb.load()
    width, height = rgb.size
    for y in range(height):
        for x in range(width):
            r, g, b = pixels[x, y]
            luminance = (r * 0.299 + g * 0.587 + b * 0.114) / 255.0
            depth = y / max(1.0, float(height - 1))
            ancient_blue = (34, 72, 90)
            tint = 0.50 - 0.18 * luminance + 0.08 * (1.0 - depth)
            nr = round(r * (1.0 - tint) + ancient_blue[0] * tint)
            ng = round(g * (1.0 - tint) + ancient_blue[1] * tint)
            nb = round(b * (1.0 - tint) + ancient_blue[2] * tint)
            pixels[x, y] = (max(0, min(255, nr)), max(0, min(255, ng)), max(0, min(255, nb)))

    out = ImageEnhance.Contrast(rgb).enhance(1.18).convert("RGBA")
    out.putalpha(alpha)
    _draw_ancient_marks(out)
    return _trim_alpha(out)


def _draw_ancient_marks(image: Image.Image) -> None:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        return
    x0, y0, x1, y1 = bbox
    width = x1 - x0
    height = y1 - y0
    marks = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(marks)
    for index in range(9):
        x = x0 + width * (0.25 + index * 0.055)
        y = y0 + height * (0.35 + 0.10 * math.sin(index * 1.7))
        draw.line(
            (
                x,
                y,
                x + width * (0.035 + 0.010 * (index % 2)),
                y - height * (0.06 + 0.015 * (index % 3)),
            ),
            fill=(190, 230, 236, 128),
            width=max(2, round(height * 0.010)),
        )
    for index in range(18):
        x = x0 + width * (0.18 + ((index * 17) % 72) / 100.0)
        y = y0 + height * (0.18 + ((index * 29) % 58) / 100.0)
        radius = max(2, round(height * (0.006 + (index % 3) * 0.003)))
        draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=(20, 45, 55, 78))
    clipped = Image.new("RGBA", image.size, (0, 0, 0, 0))
    clipped.putalpha(image.getchannel("A"))
    marks.putalpha(Image.composite(marks.getchannel("A"), Image.new("L", image.size, 0), clipped.getchannel("A")))
    image.alpha_composite(marks)


def _readability_pass(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    rgb = ImageEnhance.Color(image.convert("RGB")).enhance(1.04)
    rgb = ImageEnhance.Sharpness(rgb).enhance(1.10)
    out = rgb.convert("RGBA")
    out.putalpha(alpha)
    return out


def _build_contact(card: Image.Image, sheet: Image.Image) -> Image.Image:
    board = Image.new("RGBA", (1160, 690), (10, 18, 26, 255))
    board.alpha_composite(card, (30, 30))
    for index in range(4):
        frame = sheet.crop((index * 640, 0, (index + 1) * 640, 320))
        frame = frame.resize((512, 256), Image.Resampling.LANCZOS)
        board.alpha_composite(frame, (40 + (index % 2) * 560, 370 + (index // 2) * 145))
    draw = ImageDraw.Draw(board)
    draw.rectangle((20, 20, 1140, 670), outline=(106, 167, 185, 180), width=3)
    draw.text((620, 96), "megalodon / E10 v1 derived asset", fill=(238, 231, 205, 255))
    draw.text((620, 126), "source: nushi_danger_reef_source.png + scripted tint/scars", fill=(158, 218, 232, 255))
    return board


if __name__ == "__main__":
    main()
