#!/usr/bin/env python3
"""Build a right-sidebar static visual QA board from the real frame assets.

This does not replace the Godot runtime capture. It is a deterministic fallback
for checking sidebar asset/layout changes while SubViewport screenshots are not
available in headless CI.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
REFERENCE = ROOT / "reference" / "02_underwater_fight_mockup.png"
ASSET_DIR = ROOT / "assets" / "showcase" / "underwater"
FONT_BOLD = ROOT / "assets" / "fonts" / "MPLUS1p-Bold.ttf"
FONT_REGULAR = ROOT / "assets" / "fonts" / "MPLUS1p-Regular.ttf"
OUT = Path("/tmp/tsuri_sidebar_static_compare.png")

SIDEBAR_SIZE = (326, 708)
BG = "#07111d"
TEXT_LABEL = "#e8f3ff"


def _font(size: int, *, bold: bool = True) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT_BOLD if bold else FONT_REGULAR), size)


def _resize(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    return image.resize(size, Image.Resampling.LANCZOS)


def _draw_text(
    draw: ImageDraw.ImageDraw,
    xy: tuple[float, float],
    text: str,
    size: int,
    fill: str,
    *,
    bold: bool = True,
    stroke: int = 0,
) -> None:
    draw.text(xy, text, font=_font(size, bold=bold), fill=fill, stroke_width=stroke, stroke_fill=(0, 0, 0, 170))


def _center_text(
    draw: ImageDraw.ImageDraw,
    box: tuple[float, float, float, float],
    text: str,
    size: int,
    fill: str,
    *,
    bold: bool = True,
) -> None:
    font = _font(size, bold=bold)
    bbox = draw.textbbox((0, 0), text, font=font)
    x = box[0] + ((box[2] - box[0]) - (bbox[2] - bbox[0])) * 0.5
    y = box[1] + ((box[3] - box[1]) - (bbox[3] - bbox[1])) * 0.5 - 1
    draw.text((x, y), text, font=font, fill=fill)


def _wrapped_lines(text: str, max_width: float, size: int, *, bold: bool, max_lines: int) -> list[str]:
    font = _font(size, bold=bold)
    lines: list[str] = []
    line = ""
    closing_marks = "、。！？…）」』"
    for char in text:
        next_line = line + char
        if font.getlength(next_line) > max_width and line:
            if char in closing_marks:
                lines.append(next_line)
                line = ""
            else:
                lines.append(line)
                line = char
        else:
            line = next_line
    if line:
        lines.append(line)
    return lines[:max_lines]


def _draw_wrapped(
    draw: ImageDraw.ImageDraw,
    xy: tuple[float, float],
    text: str,
    max_width: float,
    size: int,
    fill: str,
    *,
    bold: bool = True,
    max_lines: int = 1,
    line_gap: float | None = None,
) -> None:
    gap = line_gap if line_gap is not None else size + 5
    for index, line in enumerate(_wrapped_lines(text, max_width, size, bold=bold, max_lines=max_lines)):
        draw.text((xy[0], xy[1] + index * gap), line, font=_font(size, bold=bold), fill=fill)


def _paste_contain(
    base: Image.Image,
    image: Image.Image,
    box: tuple[float, float, float, float],
    *,
    scale_multiplier: float = 1.0,
    offset: tuple[float, float] = (0.0, 0.0),
) -> None:
    width = box[2] - box[0]
    height = box[3] - box[1]
    scale = min(width / image.width, height / image.height) * scale_multiplier
    size = (round(image.width * scale), round(image.height * scale))
    resized = _resize(image, size)
    x = round(box[0] + (width - size[0]) * 0.5 + offset[0])
    y = round(box[1] + (height - size[1]) * 0.5 + offset[1])
    base.alpha_composite(resized, (x, y))


def _paste_alpha_crop_contain(base: Image.Image, image: Image.Image, box: tuple[float, float, float, float]) -> None:
    bbox = image.getchannel("A").getbbox()
    _paste_contain(base, image.crop(bbox) if bbox is not None else image, box)


def _draw_sheet_icon(base: Image.Image, index: int, box: tuple[float, float, float, float]) -> None:
    sheet = Image.open(ASSET_DIR / "fight_icon_sheet.png").convert("RGBA")
    cell_w = sheet.width // 3
    cell_h = sheet.height // 3
    src = sheet.crop(((index % 3) * cell_w, (index // 3) * cell_h, (index % 3 + 1) * cell_w, (index // 3 + 1) * cell_h))
    icon = _resize(src, (round(box[2] - box[0]), round(box[3] - box[1])))
    base.alpha_composite(icon, (round(box[0]), round(box[1])))


def _draw_rarity(draw: ImageDraw.ImageDraw, box: tuple[float, float, float, float]) -> None:
    draw.rounded_rectangle(box, radius=3, fill="#96517e", outline="#ddb3ce", width=1)
    draw.line((box[0] + 4, box[1] + 3, box[2] - 4, box[1] + 3), fill=(255, 225, 245, 90), width=1)
    _center_text(draw, box, "レア", 13, "white")


def _draw_header(draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    header = (w * 0.044, h * 0.026, w * (0.044 + 0.912), h * (0.026 + 0.078))
    _draw_text(draw, (header[0] + 14, header[1] + header[3] - header[1] - 31), "釣り中の魚", 18, "#f7ecd0", stroke=2)
    _draw_text(draw, (header[2] - 66, header[1] + header[3] - header[1] - 28), "1/1匹", 16, "#f7cf61", stroke=1)


def _draw_fish_card(base: Image.Image, draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    rect = (w * 0.048, h * 0.109, w * (0.048 + 0.904), h * (0.109 + 0.466))
    inner = (rect[0] + 12, rect[1] + 12, rect[2] - 12, rect[3] - 12)
    title = (inner[0] + 7, inner[1] + 8, inner[2] - 7, inner[1] + 36)
    rarity = (inner[2] - 58, inner[1] + 11, inner[2] - 10, inner[1] + 31)
    name = (title[0] + 62, title[1], rarity[0] - 10, title[3])
    draw.line((title[0] + 8, title[3] + 3, title[2] - 8, title[3] + 3), fill="#c9b486", width=1)
    _draw_text(draw, (inner[0] + 17, inner[1] + 9), "No.028", 14, "#665d50", bold=False)
    _center_text(draw, name, "クロダイ", 20, "#2b2117")
    _draw_rarity(draw, rarity)

    fish_rect = (
        inner[0] + 6,
        inner[1] + 44,
        inner[2] - 6,
        inner[1] + 44 + max(82, (rect[3] - rect[1]) * 0.425),
    )
    _paste_contain(
        base,
        Image.open(ASSET_DIR / "kurodai_card_portrait.png").convert("RGBA"),
        fish_rect,
        scale_multiplier=0.90,
        offset=(-7.0, -2.0),
    )
    divider_y = fish_rect[3] + 3
    draw.line((inner[0] + 8, divider_y, inner[2] - 8, divider_y), fill="#c9b486", width=1)
    _center_text(draw, (inner[0], divider_y + 8, inner[2], divider_y + 38), "推定 44.2 cm", 20, "#2b2117")
    desc_y = divider_y + 52
    draw.line((inner[0] + 8, desc_y - 12, inner[2] - 8, desc_y - 12), fill="#d6c299", width=1)
    _draw_wrapped(
        draw,
        (inner[0] + 15, desc_y),
        "岩場や海藻の周りに潜む警戒心の強い魚。底をねらうエサに好反応。",
        inner[2] - inner[0] - 26,
        13,
        "#2b2117",
        bold=False,
        max_lines=2,
        line_gap=16,
    )
    for y, text in ((desc_y + 34, "好むエサ：オキアミ・カニ"), (desc_y + 51, "主な生息域：沿岸の岩場")):
        draw.ellipse((inner[0] + 15, y + 6, inner[0] + 23, y + 14), fill="#49c75a")
        _draw_wrapped(draw, (inner[0] + 30, y - 1), text, inner[2] - inner[0] - 41, 13, "#2b2117", bold=False)


def _draw_lower_cards(base: Image.Image, draw: ImageDraw.ImageDraw, w: int, h: int) -> None:
    action = (w * 0.044, h * 0.588, w * (0.044 + 0.912), h * (0.588 + 0.195))
    tackle = (w * 0.044, h * 0.798, w * (0.044 + 0.912), h * (0.798 + 0.178))
    _draw_sheet_icon(base, 7, (action[0] + 14, action[1] + 6, action[0] + 36, action[1] + 28))
    _draw_text(draw, (action[0] + 40, action[1] + 5), "魚の行動", 18, "#f7ecd0", stroke=2)
    action_body = (action[0] + 14, action[1] + (action[3] - action[1]) * 0.225, action[2] - 14, action[3] - (action[3] - action[1]) * 0.060)
    _paste_alpha_crop_contain(base, Image.open(ASSET_DIR / "fight_action_card_icon.png").convert("RGBA"), (action_body[0] + 2, action_body[1] + 10, action_body[0] + 74, action_body[1] + 82))
    _draw_text(draw, (action_body[0] + 86, action_body[1] + 9), "突っ込み！", 21, "#2b2117")
    _draw_wrapped(draw, (action_body[0] + 86, action_body[1] + 44), "一気に深く潜る！", action_body[2] - action_body[0] - 92, 14, "#2b2117", max_lines=1, line_gap=15)
    _draw_wrapped(draw, (action_body[0] + 86, action_body[1] + 59), "ラインを緩めず耐えよう！", action_body[2] - action_body[0] - 92, 14, "#2b2117", max_lines=1, line_gap=15)

    _draw_text(draw, (tackle[0] + 14, tackle[1] + 4), "タックル", 18, "#f7ecd0", stroke=2)
    body = (tackle[0] + 14, tackle[1] + (tackle[3] - tackle[1]) * 0.225, tackle[2] - 14, tackle[3] - (tackle[3] - tackle[1]) * 0.060)
    for index, text in enumerate(("ロッド：港の入門竿", "ライン：ナイロン3号", "ハリス：フロロ2号", "針：チヌ針")):
        _draw_wrapped(
            draw,
            (body[0] + 14, body[1] + 15 + index * 14.5),
            text,
            body[2] - body[0] - 110,
            12,
            "#2b2117",
            bold=False,
            max_lines=1,
            line_gap=15,
        )
    _paste_contain(base, Image.open(ASSET_DIR / "fight_tackle_card_icon.png").convert("RGBA"), (body[2] - 94, body[3] - 76, body[2] - 6, body[3] - 6))


def build_current_sidebar() -> Image.Image:
    frame = _resize(Image.open(ASSET_DIR / "sidebar_frame.png").convert("RGBA"), SIDEBAR_SIZE)
    draw = ImageDraw.Draw(frame)
    _draw_header(draw, *SIDEBAR_SIZE)
    _draw_fish_card(frame, draw, *SIDEBAR_SIZE)
    _draw_lower_cards(frame, draw, *SIDEBAR_SIZE)
    return frame.convert("RGB")


def build_reference_sidebar() -> Image.Image:
    reference = Image.open(REFERENCE).convert("RGB")
    crop = reference.crop((1260, 0, reference.width, reference.height))
    return _resize(crop, (round(crop.width * SIDEBAR_SIZE[1] / crop.height), SIDEBAR_SIZE[1]))


def main() -> int:
    reference = build_reference_sidebar()
    current = build_current_sidebar()
    label_h = 38
    gap = 24
    width = reference.width + current.width + gap + 32
    height = SIDEBAR_SIZE[1] + label_h + 18
    out = Image.new("RGB", (width, height), BG)
    draw = ImageDraw.Draw(out)
    draw.text((16, 12), "REFERENCE RIGHT PANEL", fill=TEXT_LABEL)
    draw.text((16 + reference.width + gap, 12), "CURRENT STATIC SIDEBAR", fill=TEXT_LABEL)
    out.paste(reference, (16, label_h))
    out.paste(current, (16 + reference.width + gap, label_h))
    out.save(OUT)
    print(OUT)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
