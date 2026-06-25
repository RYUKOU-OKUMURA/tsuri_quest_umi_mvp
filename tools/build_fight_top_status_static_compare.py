#!/usr/bin/env python3
"""Build a top-status static visual QA board from the real frame asset."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
REFERENCE = ROOT / "reference" / "02_underwater_fight_mockup.png"
ASSET_DIR = ROOT / "assets" / "showcase" / "underwater"
FONT_BOLD = ROOT / "assets" / "fonts" / "MPLUS1p-Bold.ttf"
OUT = Path("/tmp/tsuri_top_status_static_compare.png")

STATUS_SIZE = (937, 76)
BG = "#07111d"
TEXT_LABEL = "#e8f3ff"


def _font(size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT_BOLD), size)


def _resize(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    return image.resize(size, Image.Resampling.LANCZOS)


def _draw_text(
    draw: ImageDraw.ImageDraw,
    xy: tuple[float, float],
    text: str,
    size: int,
    fill: str,
    *,
    stroke: int = 0,
    max_width: float | None = None,
) -> None:
    font = _font(size)
    if max_width is not None:
        text = _fit_text(text, size, max_width)
    ascent, _descent = font.getmetrics()
    draw.text(
        (xy[0], xy[1] - ascent),
        text,
        font=font,
        fill=fill,
        stroke_width=stroke,
        stroke_fill=(0, 0, 0, 180),
    )


def _text_width(text: str, size: int) -> float:
    return _font(size).getlength(text)


def _fit_text(text: str, size: int, max_width: float) -> str:
    if _text_width(text, size) <= max_width:
        return text
    ellipsis = "..."
    result = text
    while result:
        result = result[:-1]
        candidate = result + ellipsis
        if _text_width(candidate, size) <= max_width:
            return candidate
    return ellipsis


def _slot_rects(rect: tuple[float, float, float, float]) -> list[tuple[float, float, float, float]]:
    x0, y0, x1, y1 = rect
    w = x1 - x0
    h = y1 - y0
    slot_y = y0 + h * 0.08
    slot_h = h * 0.84
    return [
        (x0 + w * 0.000, slot_y, x0 + w * 0.235, slot_y + slot_h),
        (x0 + w * 0.235, slot_y, x0 + w * 0.535, slot_y + slot_h),
        (x0 + w * 0.535, slot_y, x0 + w * 0.785, slot_y + slot_h),
        (x0 + w * 0.785, slot_y, x0 + w * 1.000, slot_y + slot_h),
    ]


def _draw_top_icon(base: Image.Image, index: int, slot: tuple[float, float, float, float]) -> None:
    sheet = Image.open(ASSET_DIR / "top_status_icon_sheet.png").convert("RGBA")
    cell_w = sheet.width // 4
    src = sheet.crop((index * cell_w, 0, (index + 1) * cell_w, sheet.height))
    slot_h = slot[3] - slot[1]
    icon_size = min(max(slot_h * 0.62, 40.0), 46.0)
    icon = _resize(src, (round(icon_size), round(icon_size)))
    base.alpha_composite(icon, (round(slot[0] + 11), round(slot[1] + (slot_h - icon_size) * 0.5 + 1)))


def _draw_inline_wind_icon(base: Image.Image, box: tuple[float, float, float, float]) -> None:
    sheet = Image.open(ASSET_DIR / "top_status_icon_sheet.png").convert("RGBA")
    cell_w = sheet.width // 4
    src = sheet.crop((2 * cell_w, 0, 3 * cell_w, sheet.height))
    icon = _resize(src, (round(box[2] - box[0]), round(box[3] - box[1])))
    base.alpha_composite(icon, (round(box[0]), round(box[1])))


def _draw_centered_dark_slot(
    draw: ImageDraw.ImageDraw,
    slot: tuple[float, float, float, float],
    title: str,
    body: str,
) -> None:
    x0, y0, x1, y1 = slot
    w = x1 - x0
    h = y1 - y0
    title_size = 13
    body_size = 19
    _draw_text(draw, (x0 + (w - _text_width(title, title_size)) * 0.5, y0 + h * 0.35), title, title_size, "#f1d58d", stroke=2)
    _draw_text(draw, (x0 + (w - _text_width(body, body_size)) * 0.5, y0 + h * 0.69), body, body_size, "#eaf6ff", stroke=2)


def _draw_status_slot(base: Image.Image, draw: ImageDraw.ImageDraw, slot: tuple[float, float, float, float], title: str, body: str) -> None:
    x0, y0, x1, y1 = slot
    h = y1 - y0
    icon_space = min(max(h * 0.96, 60.0), 68.0)
    text_x = x0 + icon_space
    max_width = x1 - text_x - 10.0
    if title == "AM":
        baseline = y0 + h * 0.54
        _draw_text(draw, (text_x - 1, baseline), title, 14, "#6d4d25", max_width=max_width)
        _draw_text(draw, (text_x + 29, baseline + 2), body, 25, "#21170f", max_width=max_width - 29)
        return
    if title == "快晴":
        baseline = y0 + h * 0.57
        _draw_text(draw, (text_x - 1, baseline), title, 20, "#21170f", max_width=max_width)
        wind_size = 25.0
        wind_x = text_x + 68.0
        _draw_inline_wind_icon(base, (wind_x, y0 + (h - wind_size) * 0.5 + 1, wind_x + wind_size, y0 + (h - wind_size) * 0.5 + 1 + wind_size))
        _draw_text(draw, (wind_x + 29, baseline), body, 19, "#173f32", max_width=max_width - (wind_x - text_x) - 29)
        return
    if title == "所持金":
        _draw_text(draw, (text_x - 1, y0 + h * 0.57), body, 25, "#21170f", max_width=max_width + 2)


def build_current_status() -> Image.Image:
    frame = _resize(Image.open(ASSET_DIR / "top_status_frame.png").convert("RGBA"), STATUS_SIZE)
    draw = ImageDraw.Draw(frame)
    slots = _slot_rects((0, 0, *STATUS_SIZE))
    _draw_top_icon(frame, 0, slots[0])
    _draw_top_icon(frame, 1, slots[1])
    _draw_top_icon(frame, 3, slots[2])
    _draw_status_slot(frame, draw, slots[0], "AM", "08:47")
    _draw_status_slot(frame, draw, slots[1], "快晴", "風 弱")
    _draw_status_slot(frame, draw, slots[2], "所持金", "12,450 G")
    _draw_centered_dark_slot(draw, slots[3], "南の島・沖", "水深 18.6m")
    return frame.convert("RGB")


def build_reference_status() -> Image.Image:
    reference = Image.open(REFERENCE).convert("RGB")
    crop = reference.crop((0, 0, 1242, 102))
    return _resize(crop, (round(crop.width * STATUS_SIZE[1] / crop.height), STATUS_SIZE[1]))


def main() -> int:
    reference = build_reference_status()
    current = build_current_status()
    label_h = 30
    gap = 22
    width = max(reference.width, current.width) + 32
    height = label_h * 2 + reference.height + current.height + gap + 18
    out = Image.new("RGB", (width, height), BG)
    draw = ImageDraw.Draw(out)
    draw.text((16, 10), "REFERENCE TOP STATUS", fill=TEXT_LABEL)
    out.paste(reference, (16, label_h))
    y = label_h + reference.height + gap
    draw.text((16, y + 10), "CURRENT STATIC TOP STATUS", fill=TEXT_LABEL)
    out.paste(current, (16, y + label_h))
    out.save(OUT)
    print(OUT)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
