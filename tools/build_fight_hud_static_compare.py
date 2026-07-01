#!/usr/bin/env python3
"""Build a lower-HUD static visual QA board from the real frame asset."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
REFERENCE = ROOT / "reference" / "02_underwater_fight_mockup.png"
ASSET_DIR = ROOT / "assets" / "showcase" / "underwater"
FONT_BOLD = ROOT / "assets" / "fonts" / "line_seed" / "LINESeedJP_A_TTF_Bd.ttf"
FONT_REGULAR = ROOT / "assets" / "fonts" / "line_seed" / "LINESeedJP_A_TTF_Rg.ttf"
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


def _paste_icon_contain(base: Image.Image, image: Image.Image, box: tuple[float, float, float, float]) -> None:
    width = box[2] - box[0]
    height = box[3] - box[1]
    scale = min(width / image.width, height / image.height)
    icon = _resize(image, (round(image.width * scale), round(image.height * scale)))
    base.alpha_composite(icon, (round(box[0] + (width - icon.width) * 0.5), round(box[1] + (height - icon.height) * 0.5)))


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
    draw.rectangle((x0 - 2, y0 - 2, x1 + 2, y1 + 2), fill=(0, 0, 0))
    draw.rectangle(rect, fill=(5, 11, 18))
    segments = 18
    gap = 1.5
    seg_w = ((x1 - x0) - gap * (segments - 1)) / segments
    for i in range(segments):
        start = i / segments
        filled = start < ratio
        if warm:
            fill = (34, 211, 78)
            if start > 0.55:
                fill = (217, 85, 36)
            elif start > 0.35:
                fill = (220, 198, 72)
        else:
            fill = (28, 205, 155)
        if not filled:
            fill = (7, 16, 24)
        sx = x0 + i * (seg_w + gap)
        draw.rectangle((sx, y0 + 2, sx + seg_w, y1 - 2), fill=fill)
        if filled:
            draw.rectangle((sx, y0 + 2, sx + seg_w, y0 + 7), fill=tuple(min(255, channel + 24) for channel in fill))
            draw.rectangle((sx, y1 - 4, sx + seg_w, y1 - 2), fill=tuple(max(0, round(channel * 0.62)) for channel in fill))
        else:
            draw.rectangle((sx, y1 - 4, sx + seg_w, y1 - 2), fill=(0, 0, 0))
    if warm:
        for marker in (safe_min, safe_max):
            mx = x0 + (x1 - x0) * marker
            draw.line((mx, y0 + 2, mx, y1 - 2), fill=(76, 79, 77), width=1)
        mx = x0 + (x1 - x0) * ratio
        draw.line((mx + 1.5, y0 - 1, mx + 1.5, y1 + 3), fill=(0, 0, 0), width=2)
        draw.line((mx, y0 - 2, mx, y1 + 3), fill=(228, 220, 192), width=1)
        _draw_triangle(draw, (mx, y0 - 7), 6, (228, 220, 192), up=False)


def _draw_triangle(draw: ImageDraw.ImageDraw, center: tuple[float, float], radius: float, fill: str, *, up: bool) -> None:
    cx, cy = center
    if up:
        points = ((cx, cy - radius), (cx - radius, cy + radius * 0.8), (cx + radius, cy + radius * 0.8))
    else:
        points = ((cx, cy + radius), (cx - radius, cy - radius * 0.8), (cx + radius, cy - radius * 0.8))
    draw.polygon(points, fill=fill)


def _key_icon_path(label: str) -> Path:
    return {
        "+": ASSET_DIR / "hud_key_plus.png",
        "-": ASSET_DIR / "hud_key_minus.png",
    }.get(label, ASSET_DIR / "__missing_keycap.png")


def _keyboard_key_width(key: str) -> float:
    return {
        "Space": 58.0,
        "Shift": 54.0,
        "E / Enter": 76.0,
    }.get(key, 44.0)


def _draw_keyboard_key_cap(
    draw: ImageDraw.ImageDraw,
    box: tuple[float, float, float, float],
    key: str,
    *,
    active: bool = False,
    enabled: bool = True,
) -> None:
    fill = (34, 50, 71, 235 if enabled else 115)
    if key == "Shift":
        fill = (45, 52, 44, 235 if enabled else 115)
    elif key == "E / Enter":
        fill = (74, 47, 42, 245 if enabled else 122)
    if active:
        fill = tuple(min(255, round(channel * 1.16)) for channel in fill[:3]) + (fill[3],)
    outline = (240, 198, 106, 219 if enabled else 92)
    draw.rounded_rectangle(box, radius=5, fill=fill, outline=outline, width=1)
    draw.line((box[0] + 6, box[1] + 4, box[2] - 6, box[1] + 4), fill=(255, 255, 255, 38 if enabled else 13), width=1)
    size = 10 if key == "E / Enter" else 11
    tw = _text_width(key, size)
    fill_text = (255, 245, 208, 255 if enabled else 140)
    _draw_text(draw, (box[0] + (box[2] - box[0] - tw) * 0.5, box[1] + 16), key, size, fill_text, stroke=1 if enabled else 0)


def _hint_slots(hint: tuple[float, float, float, float]) -> list[tuple[float, float, float, float]]:
    slot_w = ((hint[2] - hint[0]) - 44) / 3
    slot_y = hint[1] + 31
    x0 = hint[0] + 22
    return [
        (x0 + i * slot_w, slot_y, x0 + i * slot_w + slot_w, slot_y + 48)
        for i in range(3)
    ]


def _draw_keyboard_hint(
    draw: ImageDraw.ImageDraw,
    slot: tuple[float, float, float, float],
    key: str,
    label: str,
    note: str,
    *,
    active: bool = False,
    enabled: bool = True,
    accent: bool = False,
) -> None:
    cap_w = _keyboard_key_width(key)
    cap = (slot[0] + 6, slot[1] + 4, slot[0] + 6 + cap_w, slot[1] + 27)
    _draw_keyboard_key_cap(draw, cap, key, active=active, enabled=enabled or accent)
    label_size = 16 if key == "E / Enter" else 17
    label_x = cap[2] + 6
    label_y = cap[1] + 17
    label_w = _text_width(label, label_size)
    if label_x + label_w > slot[2] - 2:
        label_x = cap[0]
        label_y = cap[1] + 38
    label_fill = (33, 23, 15, 255) if enabled or accent else (92, 75, 53, 199)
    note_fill = (58, 42, 24, 255) if enabled or accent else (108, 92, 67, 158)
    _draw_text(draw, (label_x, label_y), label, label_size, label_fill)
    note_size = 10
    note_x = cap[0]
    note_y = cap[1] + 38
    if label_y > cap[1] + 24:
        note_x = label_x + label_w + 5
        note_y = label_y
    while _text_width(note, note_size, bold=False) > slot[2] - note_x - 2 and note_size > 8:
        note_size = max(8, note_size - 1)
    _draw_text(draw, (note_x, note_y), note, note_size, note_fill, bold=False)


def _draw_safe_zone_hint(draw: ImageDraw.ImageDraw, slot: tuple[float, float, float, float]) -> None:
    gauge = (slot[0] + 6, slot[1] + 9, slot[0] + 64, slot[1] + 21)
    draw.rectangle((gauge[0] - 1, gauge[1] - 1, gauge[2] + 1, gauge[3] + 1), fill=(0, 0, 0, 51))
    draw.rectangle(gauge, fill=(9, 19, 13, 219))
    segments = 5
    gap = 1.5
    seg_w = ((gauge[2] - gauge[0]) - gap * (segments - 1)) / segments
    for i in range(segments):
        x0 = gauge[0] + i * (seg_w + gap)
        fill = (27, 59, 44)
        if 1 <= i <= 3:
            fill = (39, 200, 95)
        draw.rectangle((x0, gauge[1] + 2, x0 + seg_w, gauge[3] - 2), fill=fill)
        draw.rectangle((x0, gauge[1] + 2, x0 + seg_w, gauge[1] + 4), fill=tuple(min(255, channel + 22) for channel in fill))
    _draw_text(draw, (slot[0] + 72, slot[1] + 19), "安全域", 16, "#21170f")
    _draw_text(draw, (slot[0] + 6, slot[1] + 40), "緑ゲージを保つ", 10, "#3a2a18", bold=False)


def _draw_status_hint(draw: ImageDraw.ImageDraw, slot: tuple[float, float, float, float], label: str, note: str) -> None:
    cx, cy = slot[0] + 14, slot[1] + 16
    draw.ellipse((cx - 5, cy - 5, cx + 5, cy + 5), fill=(0, 0, 0, 46))
    draw.ellipse((cx - 4, cy - 4, cx + 4, cy + 4), fill=(215, 183, 102, 179))
    _draw_text(draw, (slot[0] + 26, slot[1] + 20), label, 16, (92, 75, 53, 219))
    _draw_text(draw, (slot[0] + 8, slot[1] + 40), note, 10, (108, 92, 67, 184), bold=False)


def _draw_operation_hints(draw: ImageDraw.ImageDraw, hint: tuple[float, float, float, float], state: str) -> None:
    slots = _hint_slots(hint)
    fight_enabled = state == "fight"
    _draw_keyboard_hint(draw, slots[0], "Space", "巻く", "長押し", enabled=fight_enabled)
    _draw_keyboard_hint(draw, slots[1], "Shift", "糸を出す", "長押し", enabled=fight_enabled)
    if state == "ready":
        _draw_keyboard_hint(draw, slots[2], "E / Enter", "投げる", "仕掛け投入", enabled=True, accent=True)
    elif state == "bite":
        _draw_keyboard_hint(draw, slots[2], "E / Enter", "アワセる", "食いつき中", enabled=True, accent=True)
    elif state == "fight":
        _draw_safe_zone_hint(draw, slots[2])
    elif state in {"casting", "waiting", "approach"}:
        _draw_status_hint(draw, slots[2], "反応待ち", "魚影を待つ")
    else:
        _draw_status_hint(draw, slots[2], "結果確認", "次の操作へ")


def _draw_menu_row(base: Image.Image, draw: ImageDraw.ImageDraw, pos: tuple[float, float], key: str, label: str) -> None:
    cx, cy = pos[0], pos[1] - 2
    icon_path = _key_icon_path(key)
    if icon_path.exists():
        _paste_icon_contain(base, Image.open(icon_path).convert("RGBA"), (cx - 12, cy - 12, cx + 12, cy + 12))
    else:
        draw.ellipse((cx - 10, cy - 10, cx + 10, cy + 10), fill="#f7e8c4", outline="#b98a42", width=1)
        draw.line((cx - 5, cy - 5, cx + 5, cy - 5), fill=(255, 255, 255, 92), width=1)
        key_w = _text_width(key, 16)
        _draw_text(draw, (cx - key_w * 0.5, cy + 5), key, 16, "#2b2117")
    label_size = 14 if len(label) >= 6 else 15
    _draw_text(draw, (pos[0] + 28, pos[1] + 4), label, label_size, "#f7ecd0", stroke=1)


def build_current_hud(state: str = "fight") -> Image.Image:
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

    tension_icon_path = ASSET_DIR / "hud_tension_icon.png"
    tension_icon_box = (tension[0] + 12, tension[1] + 10, tension[0] + 36, tension[1] + 34)
    if tension_icon_path.exists():
        _paste_icon_contain(frame, Image.open(tension_icon_path).convert("RGBA"), tension_icon_box)
    else:
        _draw_sheet_icon(frame, 4, tension_icon_box, (255, 91, 99, 220))
    _draw_text(draw, (tension[0] + 40, tension[1] + 26), "テンション", 18, "#f7ecd0", stroke=1)
    _draw_segment_gauge(draw, (tension[0] + 24, tension[1] + 43, tension[2] - 34, tension[1] + 67), 0.66, 0.30, 0.74, warm=True)
    _draw_text(draw, (tension[0] + 24, tension[3] - 8), "ゆるい", 14, "#72f47d", stroke=1)
    _draw_text(draw, (tension[2] - 74, tension[3] - 8), "きつい", 14, "#ff823e", stroke=1)

    title = "タナ（深さ）"
    title_w = _text_width(title, 15)
    depth_center = (depth[0] + depth[2] - 40) * 0.5
    _draw_text(draw, (depth_center - title_w * 0.5, depth[1] + 24), title, 15, "#f7ecd0", stroke=1)
    value = "18.6m"
    value_w = _text_width(value, 30)
    _draw_text(draw, (depth_center - value_w * 0.5, depth[1] + 63), value, 30, "#eaf6ff", stroke=1)
    arrow_x = depth[2] - 17
    _draw_triangle(draw, (arrow_x, depth[1] + 34), 11, "#29baf7", up=True)
    _draw_triangle(draw, (arrow_x, depth[1] + 72), 11, "#ff6b3e", up=False)

    stamina_icon_path = ASSET_DIR / "hud_stamina_icon.png"
    stamina_icon_box = (stamina[0] + 12, stamina[1] + 10, stamina[0] + 36, stamina[1] + 34)
    if stamina_icon_path.exists():
        _paste_icon_contain(frame, Image.open(stamina_icon_path).convert("RGBA"), stamina_icon_box)
    else:
        _draw_sheet_icon(frame, 5, stamina_icon_box, (108, 200, 255, 220))
    _draw_text(draw, (stamina[0] + 40, stamina[1] + 26), "魚の体力", 18, "#f7ecd0", stroke=1)
    _draw_segment_gauge(draw, (stamina[0] + 24, stamina[1] + 43, stamina[2] - 34, stamina[1] + 67), 0.72, 0.0, 1.0, warm=False)
    _draw_text(draw, (stamina[0] + 24, stamina[3] - 8), "弱い", 14, "#fff1c7", stroke=1)
    _draw_text(draw, (stamina[2] - 63, stamina[3] - 8), "強い", 14, "#fff1c7", stroke=1)

    bait_w = (bottom[2] - bottom[0]) * 0.265
    menu_w = (bottom[2] - bottom[0]) * 0.175
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
    _draw_text(draw, (bait[0] + 116, bait[1] + (bait[3] - bait[1]) * 0.56), "オキアミ", 19, "#2b2117")
    _draw_text(draw, (bait[0] + 130, bait[1] + (bait[3] - bait[1]) * 0.74), "× 17", 17, "#2b2117")

    hint_title = "操作のヒント"
    hint_title_w = _text_width(hint_title, 16)
    _draw_text(draw, (hint[0] + (hint[2] - hint[0] - hint_title_w) * 0.5, hint[1] + 21), hint_title, 16, "#f7ecd0", stroke=1)
    _draw_operation_hints(draw, hint, state)

    menu_h = menu[3] - menu[1]
    menu_button_gap = 6
    menu_button_h = (menu_h - 20 - menu_button_gap) * 0.5
    change_spot = (menu[0] + 9, menu[1] + 10, menu[2] - 9, menu[1] + 10 + menu_button_h)
    harbor = (menu[0] + 9, menu[1] + 10 + menu_button_h + menu_button_gap, menu[2] - 9, menu[1] + 10 + menu_button_h * 2 + menu_button_gap)
    for row in (change_spot, harbor):
        draw.rounded_rectangle(row, radius=4, fill=(14, 70, 111, 220), outline=(215, 183, 102, 224), width=1)
        draw.line((row[0] + 7, row[1] + 4, row[2] - 7, row[1] + 4), fill=(255, 255, 255, 31), width=1)
    _draw_menu_row(frame, draw, (change_spot[0] + 25, change_spot[1] + (change_spot[3] - change_spot[1]) * 0.62), "+", "釣り場変更")
    _draw_menu_row(frame, draw, (harbor[0] + 25, harbor[1] + (harbor[3] - harbor[1]) * 0.62), "-", "港へ戻る")
    return frame.convert("RGB")


def build_reference_hud() -> Image.Image:
    reference = Image.open(REFERENCE).convert("RGB")
    crop = reference.crop((0, 645, 1260, reference.height))
    return _resize(crop, (round(crop.width * HUD_SIZE[1] / crop.height), HUD_SIZE[1]))


def main() -> int:
    reference = build_reference_hud()
    current_fight = build_current_hud("fight")
    current_bite = build_current_hud("bite")
    label_h = 38
    gap = 24
    width = max(reference.width, current_fight.width, current_bite.width) + 32
    height = label_h * 3 + reference.height + current_fight.height + current_bite.height + gap * 2 + 18
    out = Image.new("RGB", (width, height), BG)
    draw = ImageDraw.Draw(out)
    draw.text((16, 12), "REFERENCE LOWER HUD", fill=TEXT_LABEL)
    out.paste(reference, (16, label_h))
    y = label_h + reference.height + gap
    draw.text((16, y + 12), "CURRENT STATIC LOWER HUD: FIGHT", fill=TEXT_LABEL)
    out.paste(current_fight, (16, y + label_h))
    y += label_h + current_fight.height + gap
    draw.text((16, y + 12), "CURRENT STATIC LOWER HUD: BITE", fill=TEXT_LABEL)
    out.paste(current_bite, (16, y + label_h))
    out.save(OUT)
    print(OUT)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
