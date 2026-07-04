#!/usr/bin/env python3
"""Build a contact sheet for fish-book portrait presentation QA.

This script does not write production assets. It mirrors the fish-book crop
settings so current card/detail presentation can be judged before changing
portrait sources or per-fish display rules.
"""

from __future__ import annotations

import argparse
import re
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
FISH_DIR = ROOT / "assets" / "showcase" / "fish"
GAME_DATA = ROOT / "src" / "autoload" / "game_data.gd"
FISH_EXPANSION_DATA = ROOT / "src" / "autoload" / "fish_expansion_data.gd"
REFERENCE = ROOT / "reference" / "07_fish_book_mockup.png"
OUT = Path("/tmp/tsuri_fish_book_portrait_contact_sheet.png")
FONT_BOLD = ROOT / "assets" / "fonts" / "line_seed" / "LINESeedJP_A_TTF_Bd.ttf"
FONT_REGULAR = ROOT / "assets" / "fonts" / "line_seed" / "LINESeedJP_A_TTF_Rg.ttf"

BG = "#10151d"
PAPER = "#f3e8cd"
PAPER_DEEP = "#bfa56f"
INK = "#261708"
MUTED = "#9a865e"
NAVY = "#062543"
GOLD = "#d5a13a"
TEXT = "#fff1c7"


@dataclass(frozen=True)
class FishEntry:
    fish_id: str
    asset_id: str
    fish_no: str
    name: str


def _font(size: int, *, bold: bool = True) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    path = FONT_BOLD if bold else FONT_REGULAR
    try:
        return ImageFont.truetype(str(path), size)
    except OSError:
        return ImageFont.load_default()


def _extract_string(block: str, key: str, default: str) -> str:
    match = re.search(rf'"{re.escape(key)}"\s*:\s*"([^"]*)"', block)
    return match.group(1) if match else default


def _read_fish_entries() -> list[FishEntry]:
    if not GAME_DATA.exists():
        return []
    text = GAME_DATA.read_text(encoding="utf-8")
    entries: list[FishEntry] = []
    pattern = re.compile(r'\n\t"([^"]+)"\s*:\s*\{\n(.*?)(?=\n\t\},)', re.DOTALL)
    for fish_id, block in pattern.findall(text):
        fish_no = _extract_string(block, "fish_no", "No.---")
        if fish_no == "No.---":
            continue
        name = _extract_string(block, "name", fish_id)
        asset_id = "kurodai" if fish_id == "boss_kurodai" else fish_id
        entries.append(FishEntry(fish_id, asset_id, fish_no, name))
    if FISH_EXPANSION_DATA.exists():
        expansion_text = FISH_EXPANSION_DATA.read_text(encoding="utf-8")
        row_pattern = re.compile(r'\{"id"\s*:\s*"([^"]+)".*?\}', re.DOTALL)
        for match in row_pattern.finditer(expansion_text):
            block = match.group(0)
            fish_id = match.group(1)
            fish_no = _extract_string(block, "fish_no", "No.---")
            if fish_no == "No.---":
                continue
            name = _extract_string(block, "name", fish_id)
            entries.append(FishEntry(fish_id, fish_id, fish_no, name))
    entries.sort(key=lambda entry: entry.fish_no)
    return entries


def _fallback_entries() -> list[FishEntry]:
    ids = sorted(path.name.removesuffix("_showcase_sheet.png") for path in FISH_DIR.glob("*_showcase_sheet.png"))
    return [FishEntry(asset_id, asset_id, f"No.{index + 1:03d}", asset_id) for index, asset_id in enumerate(ids)]


def _alpha_bbox(image: Image.Image, threshold: float) -> tuple[int, int, int, int] | None:
    image = image.convert("RGBA")
    cutoff = int(round(threshold * 255))
    return image.getchannel("A").point(lambda value: 255 if value > cutoff else 0).getbbox()


def _crop_alpha(image: Image.Image, pad_x_ratio: float, pad_y_ratio: float, threshold: float, min_pad: int) -> Image.Image:
    image = image.convert("RGBA")
    bbox = _alpha_bbox(image, threshold)
    if bbox is None:
        return image
    left, top, right, bottom = bbox
    fish_w = right - left
    fish_h = bottom - top
    pad_x = max(min_pad, round(fish_w * pad_x_ratio))
    pad_y = max(min_pad, round(fish_h * pad_y_ratio))
    left = max(0, left - pad_x)
    top = max(0, top - pad_y)
    right = min(image.width, right + pad_x)
    bottom = min(image.height, bottom + pad_y)
    return image.crop((left, top, right, bottom))


def _load_showcase_frame(asset_id: str) -> Image.Image | None:
    path = FISH_DIR / f"{asset_id}_showcase_sheet.png"
    if not path.exists():
        return None
    sheet = Image.open(path).convert("RGBA")
    frame_w = sheet.width // 4
    if frame_w <= 0:
        return None
    frame = sheet.crop((0, 0, frame_w, sheet.height))
    return frame.transpose(Image.Transpose.FLIP_LEFT_RIGHT)


def _load_card_portrait(asset_id: str) -> Image.Image | None:
    path = FISH_DIR / f"{asset_id}_card_portrait.png"
    if not path.exists():
        return None
    return Image.open(path).convert("RGBA")


def _tint(image: Image.Image, rgb: tuple[float, float, float]) -> Image.Image:
    image = image.convert("RGBA")
    r, g, b, a = image.split()
    r = r.point(lambda value: int(value * rgb[0]))
    g = g.point(lambda value: int(value * rgb[1]))
    b = b.point(lambda value: int(value * rgb[2]))
    return Image.merge("RGBA", (r, g, b, a))


def _fit_keep_aspect(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    image = image.convert("RGBA")
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    scale = min(size[0] / image.width, size[1] / image.height)
    resized = image.resize((max(1, round(image.width * scale)), max(1, round(image.height * scale))), Image.Resampling.LANCZOS)
    canvas.alpha_composite(resized, ((size[0] - resized.width) // 2, (size[1] - resized.height) // 2))
    return canvas


def _fit_cover(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    image = image.convert("RGBA")
    scale = max(size[0] / image.width, size[1] / image.height)
    resized = image.resize((max(1, round(image.width * scale)), max(1, round(image.height * scale))), Image.Resampling.LANCZOS)
    left = (resized.width - size[0]) // 2
    top = (resized.height - size[1]) // 2
    return resized.crop((left, top, left + size[0], top + size[1]))


def _draw_missing(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], label: str) -> None:
    x1, y1, x2, y2 = box
    draw.rectangle(box, fill="#2b2520", outline="#735b31", width=2)
    draw.text((x1 + 18, y1 + (y2 - y1) // 2 - 12), label, font=_font(20), fill="#e8d3a2")


def _card_slot(source: Image.Image | None) -> Image.Image:
    card = Image.new("RGBA", (300, 156), PAPER)
    draw = ImageDraw.Draw(card)
    draw.rounded_rectangle((6, 6, 294, 150), radius=6, fill=PAPER, outline=PAPER_DEEP, width=2)
    draw.rounded_rectangle((28, 44, 272, 104), radius=3, fill="#f5e8c9", outline="#6d5130", width=1)
    draw.rectangle((28, 106, 124, 130), fill=NAVY)
    draw.text((42, 108), "コモン", font=_font(16), fill=TEXT)
    draw.text((28, 130), "釣果 12匹", font=_font(14), fill=INK)
    draw.text((166, 130), "最大 34.2cm", font=_font(14), fill=INK)
    if source is None:
        _draw_missing(draw, (28, 44, 272, 104), "missing")
        return card
    fish = _fit_keep_aspect(_tint(source, (1.0, 0.965, 0.880)), (244, 60))
    shadow = _fit_keep_aspect(_tint(source, (0.18, 0.105, 0.040)), (244, 60))
    card.alpha_composite(shadow, (31, 47))
    card.alpha_composite(fish, (28, 44))
    return card


def _detail_slot(source: Image.Image | None) -> Image.Image:
    detail = Image.new("RGBA", (460, 180), "#f5e4ba")
    draw = ImageDraw.Draw(detail)
    draw.rounded_rectangle((6, 6, 454, 174), radius=5, fill="#f5e4ba", outline="#7e5a2b", width=3)
    for y in (46, 90, 134):
        draw.line((22, y, 438, y), fill="#d5a13a44", width=2)
    draw.line((52, 26, 52, 154), fill="#4b2a1040", width=2)
    for x in range(72, 410, 24):
        height = 12 if (x - 72) % 72 == 0 else 7
        draw.line((x, 144, x, 144 + height), fill="#4b2a103a", width=1)
    if source is None:
        _draw_missing(draw, (18, 18, 442, 162), "missing")
        return detail
    fish = _fit_keep_aspect(_tint(source, (1.0, 0.965, 0.880)), (424, 144))
    shadow = _fit_keep_aspect(_tint(source, (0.18, 0.105, 0.040)), (424, 144))
    detail.alpha_composite(shadow, (23, 23))
    detail.alpha_composite(fish, (18, 18))
    return detail


def _source_tile(source: Image.Image | None, size: tuple[int, int]) -> Image.Image:
    tile = Image.new("RGBA", size, "#f5e8c9")
    draw = ImageDraw.Draw(tile)
    draw.rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=4, fill="#f5e8c9", outline="#8a6a3d", width=1)
    if source is None:
        _draw_missing(draw, (0, 0, size[0] - 1, size[1] - 1), "missing")
        return tile
    tile.alpha_composite(_fit_keep_aspect(_tint(_crop_alpha(source, 0.012, 0.025, 0.070, 2), (1.0, 0.965, 0.880)), (size[0] - 16, size[1] - 16)), (8, 8))
    return tile


def _draw_header(draw: ImageDraw.ImageDraw, width: int) -> None:
    draw.rectangle((0, 0, width, 72), fill="#07111d")
    draw.text((20, 16), "Fish book portrait contact sheet", font=_font(28), fill=TEXT)
    draw.text(
        (520, 22),
        "current card crop / current detail crop / stored card_portrait",
        font=_font(18, bold=False),
        fill="#b9cbd4",
    )


def _reference_crops() -> tuple[Image.Image, Image.Image] | None:
    if not REFERENCE.exists():
        return None
    image = Image.open(REFERENCE).convert("RGBA")
    w, h = image.size
    card = image.crop((round(w * 0.077), round(h * 0.136), round(w * 0.242), round(h * 0.340)))
    detail = image.crop((round(w * 0.592), round(h * 0.188), round(w * 0.902), round(h * 0.438)))
    return card, detail


def _draw_reference_strip(sheet: Image.Image, top: int) -> None:
    draw = ImageDraw.Draw(sheet)
    draw.rounded_rectangle((14, top, sheet.width - 14, top + 198), radius=8, fill="#141d27", outline="#33414c", width=1)
    draw.text((28, top + 18), "reference target", font=_font(22), fill=TEXT)
    draw.text((28, top + 50), "07_fish_book_mockup.png", font=_font(14, bold=False), fill="#b9cbd4")
    crops = _reference_crops()
    if crops is None:
        draw.text((210, top + 78), "reference missing", font=_font(24), fill="#e8d3a2")
        return
    card, detail = crops
    card_tile = _fit_cover(card, (300, 156))
    detail_tile = _fit_cover(detail, (460, 180))
    sheet.paste(card_tile.convert("RGB"), (180, top + 22))
    sheet.paste(detail_tile.convert("RGB"), (510, top + 9))
    draw.text((180, top + 180), "reference list card", font=_font(13, bold=False), fill="#b9cbd4")
    draw.text((510, top + 180), "reference detail fish", font=_font(13, bold=False), fill="#b9cbd4")
    draw.text((970, top + 60), "Use this strip for scale, fish presence, and paper integration.", font=_font(15, bold=False), fill="#d9c59a")


def build(out: Path, limit: int | None = None) -> None:
    entries = _read_fish_entries() or _fallback_entries()
    if limit is not None:
        entries = entries[:limit]
    row_h = 190
    ref_h = 212
    width = 1260
    height = 72 + ref_h + row_h * len(entries) + 24
    sheet = Image.new("RGB", (width, height), BG)
    draw = ImageDraw.Draw(sheet)
    _draw_header(draw, width)
    _draw_reference_strip(sheet, 78)
    y = 72 + ref_h + 10
    for entry in entries:
        row_bg = "#16202b" if ((y - 82) // row_h) % 2 == 0 else "#121a24"
        draw.rounded_rectangle((14, y - 6, width - 14, y + row_h - 14), radius=8, fill=row_bg, outline="#2d3a44", width=1)
        draw.text((28, y + 18), entry.fish_no, font=_font(18), fill="#f4d381")
        draw.text((28, y + 46), entry.name, font=_font(24), fill=TEXT)
        draw.text((28, y + 80), entry.asset_id, font=_font(13, bold=False), fill="#b9cbd4")

        frame = _load_showcase_frame(entry.asset_id)
        current_card = _crop_alpha(frame, 0.012, 0.025, 0.070, 2) if frame is not None else None
        current_detail = _crop_alpha(frame, 0.035, 0.060, 0.035, 8) if frame is not None else None
        stored_card = _load_card_portrait(entry.asset_id)

        card_image = _card_slot(current_card)
        detail_image = _detail_slot(current_detail)
        source_image = _source_tile(stored_card, (260, 130))
        sheet.paste(card_image.convert("RGB"), (180, y), card_image.getchannel("A"))
        sheet.paste(detail_image.convert("RGB"), (510, y - 12), detail_image.getchannel("A"))
        sheet.paste(source_image.convert("RGB"), (970, y + 12), source_image.getchannel("A"))

        draw.text((180, y + 160), "current list card", font=_font(13, bold=False), fill="#b9cbd4")
        draw.text((510, y + 160), "current detail specimen", font=_font(13, bold=False), fill="#b9cbd4")
        draw.text((970, y + 150), "stored card_portrait source", font=_font(13, bold=False), fill="#b9cbd4")
        y += row_h
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    print(out)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, default=OUT, help="Output contact sheet PNG path.")
    parser.add_argument("--limit", type=int, default=None, help="Limit rows for quick inspection.")
    args = parser.parse_args()
    build(args.out, args.limit)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
