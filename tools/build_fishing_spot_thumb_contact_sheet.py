#!/usr/bin/env python3
"""Build a current-vs-candidate contact sheet for fishing spot thumbnails."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
CURRENT_DIR = ROOT / "assets" / "showcase" / "fishing_spots" / "thumbs"
CANDIDATE_DIR = ROOT / "tools" / "source_assets" / "fishing_spot_thumbs"
OUT = Path("/tmp/tsuri_fishing_spot_thumb_contact_sheet.png")
FONT_BOLD = ROOT / "assets" / "fonts" / "line_seed" / "LINESeedJP_A_TTF_Bd.ttf"
FONT_REGULAR = ROOT / "assets" / "fonts" / "line_seed" / "LINESeedJP_A_TTF_Rg.ttf"
THUMB_SIZE = (420, 184)
SPOT_ORDER = [
    ("harbor_pier", "港内・堤防"),
    ("shallow_sand", "砂浜"),
    ("rock_breakwater", "岩礁"),
    ("outer_tide", "潮目"),
    ("south_reef", "南岩礁"),
    ("bluewater_route", "外海回遊"),
    ("deep_ocean", "外洋深場"),
    ("harbor_boulder", "港の大岩"),
]


def _font(size: int, *, bold: bool = True) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    path = FONT_BOLD if bold else FONT_REGULAR
    try:
        return ImageFont.truetype(str(path), size)
    except OSError:
        return ImageFont.load_default()


def _fit(path: Path) -> Image.Image:
    if not path.exists():
        image = Image.new("RGB", THUMB_SIZE, "#2a2d31")
        draw = ImageDraw.Draw(image)
        draw.text((24, 76), "missing", font=_font(28), fill="#e5d7b7")
        return image
    image = Image.open(path).convert("RGB")
    scale = max(THUMB_SIZE[0] / image.width, THUMB_SIZE[1] / image.height)
    resized = image.resize((round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS)
    left = (resized.width - THUMB_SIZE[0]) // 2
    top = (resized.height - THUMB_SIZE[1]) // 2
    return resized.crop((left, top, left + THUMB_SIZE[0], top + THUMB_SIZE[1]))


def main() -> int:
    gap = 18
    label_h = 36
    row_h = label_h + THUMB_SIZE[1] + 14
    width = THUMB_SIZE[0] * 2 + gap * 3
    height = 52 + row_h * len(SPOT_ORDER)
    sheet = Image.new("RGB", (width, height), "#10151d")
    draw = ImageDraw.Draw(sheet)
    draw.text((gap, 12), "釣り場サムネイル current / candidate", font=_font(24), fill="#f4ead1")

    y = 52
    for spot_id, label in SPOT_ORDER:
        draw.text((gap, y + 7), f"{label}  current", font=_font(16), fill="#f4ead1")
        draw.text((THUMB_SIZE[0] + gap * 2, y + 7), f"{label}  candidate", font=_font(16), fill="#9fe8ff")
        sheet.paste(_fit(CURRENT_DIR / f"{spot_id}.png"), (gap, y + label_h))
        sheet.paste(_fit(CANDIDATE_DIR / f"{spot_id}.png"), (THUMB_SIZE[0] + gap * 2, y + label_h))
        y += row_h

    OUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT)
    print(OUT)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
