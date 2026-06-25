#!/usr/bin/env python3
"""Build a lower-HUD static visual QA board from the real frame asset."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
REFERENCE = ROOT / "reference" / "02_underwater_fight_mockup.png"
ASSET_DIR = ROOT / "assets" / "showcase" / "underwater"
FONT_BOLD = ROOT / "assets" / "fonts" / "MPLUS1p-Bold.ttf"
FONT_REGULAR = ROOT / "assets" / "fonts" / "MPLUS1p-Regular.ttf"
OUT = Path("/tmp/tsuri_hud_static_compare.png")

HUD_SIZE = (937, 224)
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
    font = _font(size, bold=bold)
    ascent, _descent = font.getmetrics()
    draw.text(
        (xy[0], xy[1] - ascent),
        text,
        font=font,
        fill=fill,
        stroke_width=stroke,
        stroke_fill=(0, 0, 0, 180),
    )


def _text_width(text: str, size: int, *, bold: bool = True) -> float:
    return _font(size, bold=bold).getlength(text)


def _draw_sheet_icon(base: Image.Image, index: int, box: tuple[float, float, float, float], tint: tuple[int, int, int, int] | None = None) -> None:
    sheet = Image.open(ASSET_DIR / "fight_icon_sheet.png").convert("RGBA")
    cell_w = sheet.width // 3
    cell_h = sheet.height // 3
    src = sheet.crop(((index % 3) * cell_w, (index // 3) * cell_h, (index % 3 + 1) * cell_w, (index // 3 + 1) * cell_h))
    icon = _resize(src, (round(box[2] - box[0]), round(box[3] - box[1])))
    if tint is not None:
        color = Image.new("RGBA", icon.size, tint)
        alpha = icon.getchannel("A")
        icon = Image.composite(color, icon, alpha)
        icon.putalpha(alpha)
    base.alpha_composite(icon, (round(box[0]), round(box[1])))


def _draw_segment_gauge(
    draw: ImageDraw.ImageDraw,
    rect: tuple[float, float, float, float],
    ratio: float,
    safe_min: float,
    safe_max: float,
    *,
    warm: bool,
) -> None:
    x0, y0, x1, y1 = rect
    draw.rectangle((x0 - 2, y0 - 2, x1 + 2, y1 + 2), fill=(0, 0, 0, 56))
    draw.rectangle(rect, fill=(0, 0, 0, 46))
    segments = 18
    gap = 1.5
    seg_w = ((x1 - x0) - gap * (segments - 1)) / segments
    for i in range(segments):
        start = i / segments
        filled = start < ratio
        if warm:
            fill = (34, 211, 78, 255)
            if start > 0.55:
                fill = (217, 85, 36, 255)
            elif start > 0.35:
                fill = (220, 198, 72, 255)
        else:
            fill = (28, 205, 155, 255)
        if not filled:
            fill = (23, 37, 52, 82)
        sx = x0 + i * (seg_w + gap)
        draw.rectangle((sx, y0 + 3, sx + seg_w, y1 - 3), fill=fill)
        draw.rectangle((sx, y0 + 3, sx + seg_w, y0 + 8), fill=(255, 255, 255, 34 if filled else 10))
        draw.rectangle((sx, y1 - 5, sx + seg_w, y1 - 3), fill=(0, 0, 0, 54))
    if warm:
        for marker in (safe_min, safe_max):
            mx = x0 + (x1 - x0) * marker
            draw.line((mx, y0 + 1, mx, y1 - 1), fill=(255, 255, 255, 76), width=1)
        mx = x0 + (x1 - x0) * ratio
        draw.line((mx + 2, y0 - 2, mx + 2, y1 + 4), fill=(0, 0, 0, 86), width=2)
        draw.line((mx, y0 - 3, mx, y1 + 4), fill="#fff8df", width=2)


def _draw_key_cap(draw: ImageDraw.ImageDraw, box: tuple[float, float, float, float], label: str, size: int) -> None:
    draw.rounded_rectangle(box, radius=999, fill="#132132", outline="#f0c66a", width=1)
    draw.arc((box[0] + 4, box[1] + 3, box[2] - 4, box[3] - 4), 200, 340, fill=(255, 244, 190, 96), width=1)
    tw = _text_width(label, size)
    _draw_text(draw, (box[0] + (box[2] - box[0] - tw) * 0.5, box[1] + 16), label, size, "#fff5d0", stroke=1)


def _hint_slots(hint: tuple[float, float, float, float]) -> list[tuple[float, float, float, float]]:
    slot_w = ((hint[2] - hint[0]) - 52) / 3
    slot_y = hint[1] + 31
    x0 = hint[0] + 26
    return [
        (x0 + i * slot_w, slot_y, x0 + i * slot_w + slot_w, slot_y + 48)
        for i in range(3)
    ]


def _draw_key_hint(draw: ImageDraw.ImageDraw, slot: tuple[float, float, float, float], key: str, label: str, note: str) -> None:
    is_long = key == "L/R"
    cap_w = 26 if not is_long else 44
    cap_h = 22
    cap = (slot[0] + 9, slot[1] + 9, slot[0] + 9 + cap_w, slot[1] + 9 + cap_h)
    _draw_key_cap(draw, cap, key, 12 if is_long else 14)
    label_x = cap[0] + cap_w + (6 if is_long else 8)
    _draw_text(draw, (label_x, cap[1] + 17), label, 16, "#2b2117")
    _draw_text(draw, (label_x, cap[1] + 29), note, 8 if is_long else 9, "#5a4327", bold=False)


def _draw_menu_row(draw: ImageDraw.ImageDraw, pos: tuple[float, float], key: str, label: str) -> None:
    cx, cy = pos[0], pos[1] - 2
    draw.ellipse((cx - 10, cy - 10, cx + 10, cy + 10), fill="#f7e8c4", outline="#b98a42", width=1)
    draw.line((cx - 5, cy - 5, cx + 5, cy - 5), fill=(255, 255, 255, 92), width=1)
    key_w = _text_width(key, 16)
    _draw_text(draw, (cx - key_w * 0.5, cy + 5), key, 16, "#2b2117")
    _draw_text(draw, (pos[0] + 28, pos[1] + 4), label, 16, "#f7ecd0", stroke=2)


def build_current_hud() -> Image.Image:
    frame = _resize(Image.open(ASSET_DIR / "fight_hud_frame.png").convert("RGBA"), HUD_SIZE)
    draw = ImageDraw.Draw(frame)
    w, h = HUD_SIZE
    top = (w * 0.014, h * 0.065, w * 0.986, h * 0.520)
    bottom = (w * 0.014, h * 0.552, w * 0.986, h * 0.940)
    gap = 10.0
    depth_w = min(max(w * 0.210, 165.0), 205.0)
    left_w = (top[2] - top[0] - depth_w - gap * 2) * 0.50
    right_w = top[2] - top[0] - depth_w - left_w - gap * 2
    tension = (top[0], top[1], top[0] + left_w, top[3])
    depth = (tension[2] + gap, top[1], tension[2] + gap + depth_w, top[3])
    stamina = (depth[2] + gap, top[1], depth[2] + gap + right_w, top[3])

    _draw_sheet_icon(frame, 4, (tension[0] + 12, tension[1] + 10, tension[0] + 36, tension[1] + 34), (255, 91, 99, 220))
    _draw_text(draw, (tension[0] + 40, tension[1] + 26), "テンション", 18, "#f7ecd0", stroke=2)
    _draw_segment_gauge(draw, (tension[0] + 24, tension[1] + 43, tension[2] - 34, tension[1] + 67), 0.66, 0.30, 0.74, warm=True)
    _draw_text(draw, (tension[0] + 24, tension[3] - 8), "ゆるい", 14, "#72f47d", stroke=1)
    _draw_text(draw, (tension[2] - 74, tension[3] - 8), "きつい", 14, "#ff823e", stroke=1)

    title = "タナ（深さ）"
    title_w = _text_width(title, 15)
    depth_center = (depth[0] + depth[2] - 24) * 0.5
    _draw_text(draw, (depth_center - title_w * 0.5, depth[1] + 24), title, 15, "#f7ecd0", stroke=2)
    value = "18.6m"
    value_w = _text_width(value, 32)
    _draw_text(draw, (depth_center - value_w * 0.5, depth[1] + 64), value, 32, "#eaf6ff", stroke=4)

    _draw_sheet_icon(frame, 5, (stamina[0] + 12, stamina[1] + 10, stamina[0] + 36, stamina[1] + 34), (108, 200, 255, 220))
    _draw_text(draw, (stamina[0] + 40, stamina[1] + 26), "魚の体力", 18, "#f7ecd0", stroke=2)
    _draw_segment_gauge(draw, (stamina[0] + 24, stamina[1] + 43, stamina[2] - 34, stamina[1] + 67), 0.72, 0.0, 1.0, warm=False)
    _draw_text(draw, (stamina[0] + 24, stamina[3] - 8), "弱い", 14, "#fff1c7", stroke=1)
    _draw_text(draw, (stamina[2] - 63, stamina[3] - 8), "強い", 14, "#fff1c7", stroke=1)

    bait_w = (bottom[2] - bottom[0]) * 0.265
    menu_w = (bottom[2] - bottom[0]) * 0.190
    hint_w = bottom[2] - bottom[0] - bait_w - menu_w - gap * 2
    bait = (bottom[0], bottom[1], bottom[0] + bait_w, bottom[3])
    hint = (bait[2] + gap, bottom[1], bait[2] + gap + hint_w, bottom[3])
    menu = (hint[2] + gap, bottom[1], bottom[2], bottom[3])

    _draw_text(draw, (bait[0] + 16, bait[1] + 19), "使用中のエサ", 15, "#fff1cb", bold=True, stroke=1)
    bait_icon_path = ASSET_DIR / "hud_bait_icon.png"
    if bait_icon_path.exists():
        bait_icon = Image.open(bait_icon_path).convert("RGBA")
        icon_y = bait[1] + (bait[3] - bait[1]) * 0.5 - 28.0
        icon_box = (bait[0] + 46, icon_y, bait[0] + 114, icon_y + 62)
        scale = min((icon_box[2] - icon_box[0]) / bait_icon.width, (icon_box[3] - icon_box[1]) / bait_icon.height)
        bait_icon = _resize(bait_icon, (round(bait_icon.width * scale), round(bait_icon.height * scale)))
        frame.alpha_composite(
            bait_icon,
            (
                round(icon_box[0] + (icon_box[2] - icon_box[0] - bait_icon.width) * 0.5),
                round(icon_box[1] + (icon_box[3] - icon_box[1] - bait_icon.height) * 0.5),
            ),
        )
    else:
        _draw_sheet_icon(frame, 6, (bait[0] + 58, bait[1] + 48, bait[0] + 100, bait[1] + 90))
    _draw_text(draw, (bait[0] + 116, bait[1] + 54), "オキアミ", 23, "#2b2117")
    _draw_text(draw, (bait[0] + 126, bait[1] + 79), "× 17", 21, "#2b2117")

    hint_title = "操作のヒント"
    hint_title_w = _text_width(hint_title, 18)
    _draw_text(draw, (hint[0] + (hint[2] - hint[0] - hint_title_w) * 0.5, hint[1] + 22), hint_title, 18, "#f7ecd0", stroke=2)
    for slot, args in zip(_hint_slots(hint), (("A", "巻く", "リールを巻く"), ("B", "緩める", "ラインを出す"), ("L/R", "調整", "テンション"))):
        _draw_key_hint(draw, slot, *args)

    _draw_menu_row(draw, (menu[0] + 38, menu[1] + (menu[3] - menu[1]) * 0.42), "+", "ポーズ")
    _draw_menu_row(draw, (menu[0] + 38, menu[1] + (menu[3] - menu[1]) * 0.78), "-", "港へ戻る")
    return frame.convert("RGB")


def build_reference_hud() -> Image.Image:
    reference = Image.open(REFERENCE).convert("RGB")
    crop = reference.crop((0, 645, 1260, reference.height))
    return _resize(crop, (round(crop.width * HUD_SIZE[1] / crop.height), HUD_SIZE[1]))


def main() -> int:
    reference = build_reference_hud()
    current = build_current_hud()
    label_h = 38
    gap = 24
    width = max(reference.width, current.width) + 32
    height = label_h * 2 + reference.height + current.height + gap + 18
    out = Image.new("RGB", (width, height), BG)
    draw = ImageDraw.Draw(out)
    draw.text((16, 12), "REFERENCE LOWER HUD", fill=TEXT_LABEL)
    out.paste(reference, (16, label_h))
    y = label_h + reference.height + gap
    draw.text((16, y + 12), "CURRENT STATIC LOWER HUD", fill=TEXT_LABEL)
    out.paste(current, (16, y + label_h))
    out.save(OUT)
    print(OUT)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
