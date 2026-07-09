#!/usr/bin/env python3
"""Generate raster assets for the harbor info board v3 (frame, fish cards, time slots, plan icons)."""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

from generate_harbor_showcase_assets import _blend_noise, _draw_corner_plates


ROOT = Path(__file__).resolve().parents[1]
HARBOR_OUT = ROOT / "assets" / "showcase" / "harbor"
COMMON_OUT = ROOT / "assets" / "showcase" / "common"

INFO_BOARD_FRAME_OUT = HARBOR_OUT / "harbor_info_board_frame.png"
INFO_FISH_CARD_OUT = HARBOR_OUT / "harbor_info_fish_card.png"
TIME_SLOT_BTN_NORMAL_OUT = HARBOR_OUT / "harbor_time_slot_btn_normal.png"
TIME_SLOT_BTN_SELECTED_OUT = HARBOR_OUT / "harbor_time_slot_btn_selected.png"
TIME_SLOT_BTN_LOCKED_OUT = HARBOR_OUT / "harbor_time_slot_btn_locked.png"
TIME_SLOT_ICON_ASA_OUT = HARBOR_OUT / "harbor_time_slot_icon_asa.png"
TIME_SLOT_ICON_DAY_OUT = HARBOR_OUT / "harbor_time_slot_icon_day.png"
TIME_SLOT_ICON_NIGHT_OUT = HARBOR_OUT / "harbor_time_slot_icon_night.png"
PLAN_ICON_GUIDE_OUT = HARBOR_OUT / "harbor_plan_icon_guide.png"
PLAN_ICON_PIN_OUT = HARBOR_OUT / "harbor_plan_icon_pin.png"
PLAN_ICON_RUMOR_OUT = HARBOR_OUT / "harbor_plan_icon_rumor.png"
WEATHER_STUB_OUT = HARBOR_OUT / "harbor_weather_stub_icon.png"
NAV_QUEST_ICON_OUT = COMMON_OUT / "nav_quest_icon.png"

RNG_SEED = 20260709
TIME_SLOT_BTN_SIZE = (220, 72)


def _paper_texture(size: tuple[int, int], seed: int, base: tuple[int, int, int]) -> Image.Image:
    rng = random.Random(seed)
    img = Image.new("RGBA", size, (*base, 255))
    px = img.load()
    for y in range(size[1]):
        for x in range(size[0]):
            noise = rng.randint(-8, 7)
            wave = int(math.sin((x + seed) * 0.031) * 4 + math.sin((y - seed) * 0.043) * 3)
            r = max(0, min(255, base[0] + noise + wave))
            g = max(0, min(255, base[1] + noise + wave))
            b = max(0, min(255, base[2] + noise + wave))
            px[x, y] = (r, g, b, 255)
    return img.filter(ImageFilter.GaussianBlur(0.3))


def _wood_grain_overlay(size: tuple[int, int], seed: int) -> Image.Image:
    rng = random.Random(seed)
    overlay = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    for y in range(18, size[1] - 18, 9):
        alpha = rng.randint(10, 22)
        draw.line((24, y, size[0] - 24, y + rng.randint(-1, 1)), fill=(74, 43, 22, alpha), width=1)
    for _ in range(28):
        x = rng.randint(30, size[0] - 60)
        y = rng.randint(20, size[1] - 20)
        length = rng.randint(40, 140)
        draw.line((x, y, x + length, y + rng.randint(-2, 2)), fill=(92, 57, 28, rng.randint(8, 18)), width=1)
    return overlay


def build_info_fish_card() -> None:
    size = (240, 280)
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    shadow = Image.new("RGBA", size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle((10, 12, size[0] - 10, size[1] - 8), radius=14, fill=(0, 0, 0, 96))
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(6)))

    body_w, body_h = size[0] - 24, size[1] - 22
    body = _paper_texture((body_w, body_h), RNG_SEED + 17, (242, 226, 186))
    stain = Image.new("RGBA", body.size, (168, 118, 58, 28))
    body.alpha_composite(stain)
    body.alpha_composite(_wood_grain_overlay(body.size, RNG_SEED + 19))
    mask = Image.new("L", body.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, body.width - 1, body.height - 1), radius=12, fill=255)
    img.paste(body, (12, 10), mask)

    draw = ImageDraw.Draw(img)
    outer = (12, 10, size[0] - 12, size[1] - 12)
    inner = (20, 18, size[0] - 20, size[1] - 20)
    draw.rounded_rectangle(outer, radius=12, outline=(48, 29, 17, 245), width=4)
    draw.rounded_rectangle(outer, radius=12, outline=(223, 171, 83, 235), width=2)
    draw.rounded_rectangle(inner, radius=9, outline=(218, 166, 76, 205), width=2)
    draw.rounded_rectangle(
        (inner[0] + 5, inner[1] + 5, inner[2] - 5, inner[3] - 5),
        radius=7,
        outline=(74, 43, 22, 195),
        width=1,
    )
    _draw_corner_plates(draw, (outer[0] + 3, outer[1] + 3, outer[2] - 3, outer[3] - 3), 22)
    _blend_noise(img, (inner[0] + 8, inner[1] + 8, inner[2] - 8, inner[3] - 8), 5, 0.028)
    draw.line((inner[0] + 8, inner[1] + 10, inner[2] - 8, inner[1] + 10), fill=(255, 236, 162, 48), width=1)
    draw.line((inner[0] + 8, inner[3] - 12, inner[2] - 8, inner[3] - 12), fill=(36, 23, 14, 36), width=1)
    img.save(INFO_FISH_CARD_OUT)


def build_info_board_frame() -> None:
    size = (1280, 320)
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    shadow = Image.new("RGBA", size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle((14, 16, size[0] - 14, size[1] - 10), radius=16, fill=(0, 0, 0, 108))
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(7)))

    body = _paper_texture((size[0] - 28, size[1] - 24), RNG_SEED, (118, 78, 38))
    stain = Image.new("RGBA", body.size, (62, 36, 16, 34))
    body.alpha_composite(stain)
    body.alpha_composite(_wood_grain_overlay(body.size, RNG_SEED + 11))
    mask = Image.new("L", body.size, 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle((0, 0, body.width - 1, body.height - 1), radius=14, fill=255)
    img.paste(body, (14, 12), mask)

    draw = ImageDraw.Draw(img)
    outer = (14, 12, size[0] - 14, size[1] - 12)
    inner = (22, 20, size[0] - 22, size[1] - 20)
    draw.rounded_rectangle(outer, radius=14, outline=(48, 29, 17, 245), width=5)
    draw.rounded_rectangle(outer, radius=14, outline=(223, 171, 83, 230), width=2)
    draw.rounded_rectangle(inner, radius=10, outline=(218, 166, 76, 190), width=2)
    draw.rounded_rectangle((inner[0] + 5, inner[1] + 5, inner[2] - 5, inner[3] - 5), radius=8, outline=(74, 43, 22, 210), width=1)
    _draw_corner_plates(draw, (outer[0] + 4, outer[1] + 4, outer[2] - 4, outer[3] - 4), 28)

    # 全面の暗い掲示板面。ポートレート配置は UI 側に任せ、焼き込みスロットは作らない。
    panel = (36, 28, size[0] - 36, size[1] - 28)
    panel_w = panel[2] - panel[0]
    panel_h = panel[3] - panel[1]
    panel_body = _paper_texture((panel_w, panel_h), RNG_SEED + 3, (18, 48, 68))
    stain = Image.new("RGBA", panel_body.size, (8, 22, 36, 90))
    panel_body.alpha_composite(stain)
    panel_mask = Image.new("L", panel_body.size, 0)
    ImageDraw.Draw(panel_mask).rounded_rectangle(
        (0, 0, panel_body.width - 1, panel_body.height - 1), radius=10, fill=255
    )
    img.paste(panel_body, (panel[0], panel[1]), panel_mask)
    _blend_noise(img, panel, 7, 0.022)
    draw.rounded_rectangle(panel, radius=10, outline=(236, 196, 102, 170), width=2)
    draw.rounded_rectangle(
        (panel[0] + 6, panel[1] + 6, panel[2] - 6, panel[3] - 6),
        radius=8,
        outline=(12, 42, 58, 140),
        width=1,
    )

    draw.line((36, 30, size[0] - 36, 30), fill=(255, 236, 162, 55), width=2)
    draw.line((36, size[1] - 32, size[0] - 36, size[1] - 32), fill=(61, 35, 17, 70), width=1)
    img.save(INFO_BOARD_FRAME_OUT)


def _time_slot_button(state: str) -> Image.Image:
    size = TIME_SLOT_BTN_SIZE
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    dark_border = (74, 43, 22, 245)

    if state == "selected":
        fill = (196, 118, 18, 252)
        body = (255, 220, 118, 255)
        accent = (255, 196, 62, 245)
        glow = (255, 188, 36, 165)
        shadow_alpha = 108
    elif state == "locked":
        fill = (108, 102, 92, 238)
        body = (142, 136, 124, 228)
        accent = (118, 108, 92, 195)
        glow = (0, 0, 0, 0)
        shadow_alpha = 62
    else:
        # v4: 暗いメイン枠に溶けない明るい羊皮紙地＋濃い茶枠
        fill = (252, 244, 220, 252)
        body = (255, 250, 232, 255)
        accent = (157, 103, 47, 220)
        glow = (0, 0, 0, 0)
        shadow_alpha = 72

    draw.rounded_rectangle((8, 12, size[0] - 8, size[1] - 5), radius=12, fill=(0, 0, 0, shadow_alpha))
    draw.rounded_rectangle((12, 8, size[0] - 12, size[1] - 10), radius=11, fill=fill, outline=dark_border, width=3)
    draw.rounded_rectangle((20, 14, size[0] - 20, size[1] - 16), radius=9, fill=body, outline=accent, width=2)

    if state == "selected":
        glow_img = Image.new("RGBA", size, (0, 0, 0, 0))
        glow_draw = ImageDraw.Draw(glow_img)
        glow_draw.rounded_rectangle((4, 1, size[0] - 4, size[1] - 1), radius=13, fill=glow)
        img.alpha_composite(glow_img.filter(ImageFilter.GaussianBlur(7)))
        draw = ImageDraw.Draw(img)
        draw.rounded_rectangle((10, 5, size[0] - 10, size[1] - 8), radius=11, outline=(255, 236, 128, 245), width=4)
        draw.rounded_rectangle((14, 9, size[0] - 14, size[1] - 12), radius=10, outline=(196, 118, 18, 225), width=1)
        draw.line((22, 16, size[0] - 22, 16), fill=(255, 248, 196, 185), width=2)
        draw.line((22, size[1] - 20, size[0] - 22, size[1] - 20), fill=(168, 98, 12, 90), width=1)
    elif state == "locked":
        draw.rectangle((20, 14, size[0] - 20, size[1] - 16), fill=(88, 82, 72, 48))
        draw.arc((size[0] - 66, 20, size[0] - 32, 54), 180, 360, fill=(78, 70, 58, 205), width=4)
        draw.rounded_rectangle(
            (size[0] - 68, 36, size[0] - 30, 58),
            radius=4,
            fill=(108, 98, 82, 225),
            outline=(62, 48, 30, 220),
            width=2,
        )
        draw.ellipse((size[0] - 54, 42, size[0] - 44, 52), fill=(62, 48, 30, 255))
    else:
        draw.line((24, 18, size[0] - 24, 18), fill=(255, 244, 196, 72), width=2)
        draw.line((24, size[1] - 18, size[0] - 24, size[1] - 18), fill=(36, 23, 14, 38), width=1)

    if state != "locked":
        for x in (18, size[0] - 18):
            sign = 1 if x < size[0] / 2 else -1
            draw.polygon(
                [(x, size[1] * 0.50), (x + sign * 7, size[1] * 0.41), (x + sign * 7, size[1] * 0.59)],
                fill=accent,
            )
    return img


def build_time_slot_buttons() -> None:
    _time_slot_button("normal").save(TIME_SLOT_BTN_NORMAL_OUT)
    _time_slot_button("selected").save(TIME_SLOT_BTN_SELECTED_OUT)
    _time_slot_button("locked").save(TIME_SLOT_BTN_LOCKED_OUT)


def _draw_sun_rays(draw: ImageDraw.ImageDraw, cx: float, cy: float, radius: float, *, alpha: int = 255) -> None:
    for angle in range(0, 360, 45):
        rad = math.radians(angle)
        x0 = cx + math.cos(rad) * (radius + 4)
        y0 = cy + math.sin(rad) * (radius + 4)
        x1 = cx + math.cos(rad) * (radius + 14)
        y1 = cy + math.sin(rad) * (radius + 14)
        draw.line((x0, y0, x1, y1), fill=(47, 33, 18, min(225, alpha)), width=3)
        draw.line((x0, y0, x1, y1), fill=(240, 165, 27, alpha), width=2)


def _draw_time_slot_icon(kind: str) -> Image.Image:
    size = 64
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = 32.0, 32.0

    if kind == "asa":
        draw.rectangle((4, 44, 60, 52), fill=(94, 72, 48, 220))
        draw.polygon([(4, 44), (60, 44), (60, 36), (32, 28), (4, 36)], fill=(255, 196, 108, 180))
        _draw_sun_rays(draw, 48, 30, 10, alpha=230)
        draw.ellipse((38, 20, 58, 40), fill=(47, 33, 18, 220))
        draw.ellipse((40, 22, 56, 38), fill=(255, 155, 31, 255))
        draw.ellipse((43, 25, 50, 32), fill=(255, 230, 140, 180))
    elif kind == "day":
        _draw_sun_rays(draw, cx, cy, 14, alpha=255)
        draw.ellipse((cx - 17, cy - 17, cx + 17, cy + 17), fill=(47, 33, 18, 235))
        draw.ellipse((cx - 15, cy - 15, cx + 15, cy + 15), fill=(255, 155, 31, 255))
        draw.ellipse((cx - 8, cy - 10, cx + 2, cy), fill=(255, 230, 140, 200))
    else:
        moon = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        moon_draw = ImageDraw.Draw(moon)
        moon_draw.ellipse((cx - 20, cy - 20, cx + 20, cy + 20), fill=(47, 33, 18, 235))
        moon_draw.ellipse((cx - 18, cy - 18, cx + 18, cy + 18), fill=(236, 210, 140, 255))
        cut = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        cut_draw = ImageDraw.Draw(cut)
        cut_draw.ellipse((cx + 2, cy - 20, cx + 28, cy + 2), fill=(255, 255, 255, 255))
        moon = Image.composite(Image.new("RGBA", (size, size), (0, 0, 0, 0)), moon, cut)
        img.alpha_composite(moon)
        draw = ImageDraw.Draw(img)
        for x, y in ((18, 14), (42, 18), (24, 40)):
            draw.ellipse((x - 1, y - 1, x + 1, y + 1), fill=(255, 255, 255, 180))

    return img


def build_time_slot_icons() -> None:
    _draw_time_slot_icon("asa").save(TIME_SLOT_ICON_ASA_OUT)
    _draw_time_slot_icon("day").save(TIME_SLOT_ICON_DAY_OUT)
    _draw_time_slot_icon("night").save(TIME_SLOT_ICON_NIGHT_OUT)


def build_weather_stub_icon() -> None:
    size = 64
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cloud_parts = [
        (18, 24, 11),
        (30, 18, 14),
        (44, 16, 15),
        (52, 26, 11),
    ]
    for cx, cy, r in cloud_parts:
        draw.ellipse((cx - r - 2, cy - r - 2, cx + r + 2, cy + r + 2), fill=(37, 44, 50, 200))
    draw.rounded_rectangle((12, 26, 54, 40), radius=10, fill=(37, 44, 50, 200))
    for cx, cy, r in cloud_parts:
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(104, 120, 132, 255))
    draw.rounded_rectangle((14, 27, 52, 38), radius=8, fill=(120, 138, 150, 255))
    for x, y in ((22, 46), (32, 52), (42, 47), (50, 53)):
        draw.line((x, y, x - 4, y + 10), fill=(119, 191, 224, 210), width=2)
        draw.line((x, y, x - 4, y + 10), fill=(243, 249, 255, 180), width=1)
    img.save(WEATHER_STUB_OUT)


def _draw_plan_icon(kind: str) -> Image.Image:
    size = 64
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = 32.0, 34.0
    outline = (47, 33, 18, 235)
    fill = (255, 155, 31, 255)
    accent = (255, 230, 140, 210)

    if kind == "guide":
        stem = [(cx, cy + 14), (cx - 3, cy - 6), (cx + 3, cy - 6)]
        draw.polygon(stem, fill=(92, 138, 58, 255), outline=outline)
        draw.line((cx, cy + 14, cx, cy - 4), fill=(62, 96, 38, 255), width=3)
        for ox, oy in ((-12, -8), (0, -14), (12, -8)):
            leaf = [
                (cx + ox, cy + oy),
                (cx + ox - 8, cy + oy - 14),
                (cx + ox + 8, cy + oy - 14),
            ]
            draw.polygon(leaf, fill=(118, 186, 72, 255), outline=outline)
            draw.line((cx + ox, cy + oy, cx + ox, cy + oy - 12), fill=(78, 128, 48, 220), width=2)
        draw.ellipse((cx - 4, cy - 18, cx + 4, cy - 10), fill=accent)
    elif kind == "pin":
        draw.ellipse((cx - 16, cy - 22, cx + 16, cy + 2), fill=outline)
        draw.ellipse((cx - 14, cy - 20, cx + 14, cy), fill=(224, 72, 58, 255))
        draw.ellipse((cx - 7, cy - 16, cx + 1, cy - 8), fill=accent)
        draw.polygon([(cx, cy + 18), (cx - 10, cy + 2), (cx + 10, cy + 2)], fill=outline)
        draw.polygon([(cx, cy + 16), (cx - 8, cy + 4), (cx + 8, cy + 4)], fill=(196, 118, 58, 255))
        draw.ellipse((cx - 5, cy + 10, cx + 5, cy + 20), fill=(247, 231, 190, 255), outline=outline, width=2)
    else:
        bubble = (10, 14, 54, 42)
        draw.rounded_rectangle(bubble, radius=12, fill=outline)
        draw.rounded_rectangle((12, 16, 52, 40), radius=10, fill=(247, 231, 190, 255))
        draw.rounded_rectangle((14, 18, 50, 38), radius=8, outline=(218, 166, 76, 180), width=2)
        for y in (24, 30, 36):
            draw.rounded_rectangle((18, y, 46, y + 4), radius=2, fill=(10, 56, 76, 210))
        tail = [(22, 42), (16, 56), (30, 44)]
        draw.polygon(tail, fill=outline)
        draw.polygon([(24, 42), (20, 52), (28, 44)], fill=(247, 231, 190, 255))

    return img


def build_plan_row_icons() -> None:
    _draw_plan_icon("guide").save(PLAN_ICON_GUIDE_OUT)
    _draw_plan_icon("pin").save(PLAN_ICON_PIN_OUT)
    _draw_plan_icon("rumor").save(PLAN_ICON_RUMOR_OUT)


def build_nav_quest_icon() -> None:
    size = 240
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    board = (52, 36, 188, 204)
    draw.rounded_rectangle(board, radius=14, fill=(247, 231, 190, 255), outline=(106, 76, 36, 255), width=4)
    draw.rounded_rectangle((board[0] + 10, board[1] + 10, board[2] - 10, board[3] - 10), radius=10, outline=(218, 166, 76, 180), width=2)
    _blend_noise(img, board, 6, 0.045)

    clip = (108, 24, 132, 52)
    draw.rounded_rectangle(clip, radius=6, fill=(157, 103, 47, 255), outline=(74, 43, 22, 255), width=3)
    draw.arc((clip[0] + 4, clip[1] + 2, clip[2] - 4, clip[3] + 18), 180, 0, fill=(255, 236, 162, 200), width=3)

    for y, width in ((72, 88), (104, 72), (136, 96), (168, 64)):
        draw.rounded_rectangle((72, y, 72 + width, y + 14), radius=4, fill=(10, 56, 76, 230))
        draw.line((76, y + 4, 68 + width, y + 4), fill=(239, 198, 102, 90), width=1)

    seal = (150, 156, 196, 190)
    draw.ellipse(seal, fill=(217, 157, 49, 255), outline=(92, 57, 22, 255), width=4)
    draw.ellipse((seal[0] + 8, seal[1] + 8, seal[2] - 8, seal[3] - 8), outline=(255, 226, 117, 220), width=3)
    draw.line((seal[0] + 14, seal[1] + 22, seal[2] - 14, seal[3] - 10), fill=(92, 57, 22, 220), width=3)
    draw.line((seal[0] + 14, seal[3] - 10, seal[2] - 14, seal[1] + 22), fill=(92, 57, 22, 220), width=3)

    pencil = [(44, 176), (34, 206), (42, 210), (52, 180)]
    draw.polygon(pencil, fill=(205, 157, 76, 255), outline=(74, 43, 22, 255))
    draw.polygon([(34, 206), (30, 216), (38, 218), (42, 210)], fill=(47, 33, 18, 255))
    draw.line((46, 180, 38, 204), fill=(255, 236, 162, 140), width=2)

    img.save(NAV_QUEST_ICON_OUT)


def build_info_board_assets() -> list[Path]:
    HARBOR_OUT.mkdir(parents=True, exist_ok=True)
    COMMON_OUT.mkdir(parents=True, exist_ok=True)
    build_info_board_frame()
    build_info_fish_card()
    build_time_slot_buttons()
    build_time_slot_icons()
    build_nav_quest_icon()
    # 出港プラン紙面・行アイコンは AI ソース加工（PIL 幾何で上書きしない）。
    from process_harbor_plan_assets import build_all as build_plan_ai_assets

    plan_paths = build_plan_ai_assets()
    return [
        INFO_BOARD_FRAME_OUT,
        INFO_FISH_CARD_OUT,
        TIME_SLOT_BTN_NORMAL_OUT,
        TIME_SLOT_BTN_SELECTED_OUT,
        TIME_SLOT_BTN_LOCKED_OUT,
        TIME_SLOT_ICON_ASA_OUT,
        TIME_SLOT_ICON_DAY_OUT,
        TIME_SLOT_ICON_NIGHT_OUT,
        *plan_paths,
        NAV_QUEST_ICON_OUT,
    ]


def build_all() -> list[Path]:
    return build_info_board_assets()


def main() -> int:
    for path in build_info_board_assets():
        print(path.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
