#!/usr/bin/env python3
"""Build a full-screen static visual QA board for the underwater fight screen.

This is a fallback while Godot runtime screenshots are unavailable. It composites
the real fight assets with runtime-equivalent coordinates so the whole screen can
be judged in one reference comparison.
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / "tools"
sys.path.insert(0, str(TOOLS))

from build_fight_hud_static_compare import build_current_hud  # noqa: E402
from build_fight_sidebar_static_compare import build_current_sidebar  # noqa: E402
from build_fight_top_status_static_compare import build_current_status  # noqa: E402


REFERENCE = ROOT / "reference" / "02_underwater_fight_mockup.png"
ASSET_DIR = ROOT / "assets" / "showcase" / "underwater"
FONT_BOLD = ROOT / "assets" / "fonts" / "MPLUS1p-Bold.ttf"
FONT_REGULAR = ROOT / "assets" / "fonts" / "MPLUS1p-Regular.ttf"
OUT = Path("/tmp/tsuri_full_static_compare.png")
CURRENT_OUT = Path("/tmp/tsuri_fishing_fight_static.png")

VIEWPORT = (1280, 720)
ROOT_MARGIN = 6
BODY_GAP = 5
LEFT_W = 937
RIGHT_W = 326
CONTENT_H = 708
STATUS_H = 76
V_GAP = 2
HUD_H = 224
WATER_H = CONTENT_H - STATUS_H - HUD_H - V_GAP * 2
BG = "#07111d"
TEXT_LABEL = "#e8f3ff"


def _font(size: int, *, bold: bool = True) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT_BOLD if bold else FONT_REGULAR), size)


def _resize(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    return image.resize(size, Image.Resampling.LANCZOS)


def _cover(image: Image.Image, size: tuple[int, int], align: tuple[float, float] = (0.5, 0.5)) -> Image.Image:
    scale = max(size[0] / image.width, size[1] / image.height)
    resized = _resize(image, (round(image.width * scale), round(image.height * scale)))
    x = round((resized.width - size[0]) * align[0])
    y = round((resized.height - size[1]) * align[1])
    return resized.crop((x, y, x + size[0], y + size[1]))


def _alpha_composite(base: Image.Image, layer: Image.Image, alpha: float) -> None:
    layer = layer.convert("RGBA")
    if alpha < 1.0:
        layer.putalpha(layer.getchannel("A").point(lambda value: round(value * alpha)))
    base.alpha_composite(layer)


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


def _paste_contain(base: Image.Image, image: Image.Image, box: tuple[float, float, float, float]) -> None:
    width = box[2] - box[0]
    height = box[3] - box[1]
    scale = min(width / image.width, height / image.height)
    resized = _resize(image, (round(image.width * scale), round(image.height * scale)))
    x = round(box[0] + (width - resized.width) * 0.5)
    y = round(box[1] + (height - resized.height) * 0.5)
    base.alpha_composite(resized, (x, y))


def _draw_fish(water: Image.Image) -> tuple[float, float, float, float]:
    sheet = Image.open(ASSET_DIR / "kurodai_showcase_sheet.png").convert("RGBA")
    frame_w = sheet.width // 4
    frame_h = sheet.height
    frame_index = 2
    fish = sheet.crop((frame_w * frame_index, 0, frame_w * (frame_index + 1), frame_h))
    stamina_scale = 1.006
    draw_w = water.width * 0.49 * stamina_scale
    draw_h = draw_w * fish.height / fish.width
    center = (
        (0.42 - 0.067) * water.width,
        (0.46 - 0.018) * water.height,
    )
    shadow = Image.new("RGBA", water.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse(
        (
            center[0] - draw_w * 0.20,
            center[1] + draw_h * 0.275,
            center[0] + draw_w * 0.20,
            center[1] + draw_h * 0.365,
        ),
        fill=(0, 0, 0, 9),
    )
    water.alpha_composite(shadow)
    resized = _resize(fish, (round(draw_w), round(draw_h)))
    x = round(center[0] - resized.width * 0.5)
    y = round(center[1] - resized.height * 0.5)
    water.alpha_composite(resized, (x, y))
    flash = resized.copy()
    flash.putalpha(flash.getchannel("A").point(lambda value: round(value * 0.14)))
    white = Image.new("RGBA", resized.size, (255, 255, 255, 0))
    white.putalpha(flash.getchannel("A"))
    water.alpha_composite(white, (x, y))
    return (center[0], center[1], draw_w, draw_h)


def _draw_line_lure_hit(water: Image.Image, fish_metrics: tuple[float, float, float, float]) -> None:
    draw = ImageDraw.Draw(water)
    center_x, center_y, fish_w, fish_h = fish_metrics
    line_origin = (water.width * 0.82, 2.0)
    lure = (center_x + fish_w * 0.44, center_y + fish_h * 0.01)
    draw.line((line_origin[0], line_origin[1], lure[0], lure[1]), fill=(235, 250, 255, 224), width=2)
    lure_path = ASSET_DIR / "fight_lure.png"
    if lure_path.exists():
        lure_asset = Image.open(lure_path).convert("RGBA")
        lure_h = min(max(water.height * 0.145, 46.0), 62.0)
        lure_size = (round(lure_h * lure_asset.width / lure_asset.height), round(lure_h))
        lure_asset = _resize(lure_asset, lure_size)
        water.alpha_composite(lure_asset, (round(lure[0] - lure_asset.width * 0.5), round(lure[1] - lure_asset.height * 0.5)))
    else:
        draw.ellipse((lure[0] - 6, lure[1] - 6, lure[0] + 6, lure[1] + 6), fill="#e88b35")
        draw.ellipse((lure[0] + 1, lure[1] - 4, lure[0] + 5, lure[1]), fill="#ffd37a")
        draw.arc((lure[0], lure[1] - 2, lure[0] + 14, lure[1] + 12), 12, 138, fill="#d8e7ef", width=2)

    meter_rect = (72.0, water.height - 24.0, 72.0 + water.width * 0.56, water.height - 18.0)
    draw.rounded_rectangle(meter_rect, radius=3, fill=(5, 20, 36, 26))
    fill_w = (meter_rect[2] - meter_rect[0]) * 0.78
    draw.rounded_rectangle((meter_rect[0], meter_rect[1], meter_rect[0] + fill_w, meter_rect[3]), radius=3, fill=(132, 240, 255, 50))
    draw.line((meter_rect[0] + 3, meter_rect[1] + 1, meter_rect[0] + fill_w - 3, meter_rect[1] + 1), fill=(255, 255, 255, 24), width=1)
    _draw_text(draw, (72.0, water.height - 28.0), "距離 29.8m", 10, "#c7e5f1", bold=False, stroke=1)

    burst = Image.open(ASSET_DIR / "hit_burst.png").convert("RGBA")
    scale = min(max(water.width / 1450.0, 0.42), 0.50)
    burst_size = (round(burst.width * scale), round(burst.height * scale))
    burst = _resize(burst, burst_size)
    burst_center = (water.width * 0.49, water.height * 0.805)
    water.alpha_composite(burst, (round(burst_center[0] - burst.width * 0.5), round(burst_center[1] - burst.height * 0.5)))
    text = "ヒット！"
    font_size = int(min(max(water.height * 0.125, 42.0), 58.0))
    text_w = _text_width(text, font_size)
    pos = (burst_center[0] - text_w * 0.5, burst_center[1] + font_size * 0.20)
    _draw_text(draw, (pos[0] + 3, pos[1] + 4), text, font_size, "#ffe36e", stroke=8)
    _draw_text(draw, pos, text, font_size, "#ffe36e", stroke=8)


def build_water_window() -> Image.Image:
    size = (LEFT_W, WATER_H)
    water = _cover(Image.open(ASSET_DIR / "underwater_battle_bg.png").convert("RGBA"), size, (0.5, 0.24))
    _alpha_composite(water, _cover(Image.open(ASSET_DIR / "underwater_color_grade.png").convert("RGBA"), size, (0.5, 0.24)), 0.10)
    _alpha_composite(water, _cover(Image.open(ASSET_DIR / "underwater_seabed_detail.png").convert("RGBA"), size, (0.5, 0.24)), 0.22)
    _alpha_composite(water, _cover(Image.open(ASSET_DIR / "underwater_foreground_ambience.png").convert("RGBA"), size, (0.5, 0.24)), 0.72)
    draw = ImageDraw.Draw(water)
    draw.rectangle((0, 0, 44, water.height), fill=(5, 20, 41, 61))
    draw.line((44, 0, 44, water.height), fill=(140, 209, 242, 46), width=1)
    fish_metrics = _draw_fish(water)
    _draw_line_lure_hit(water, fish_metrics)
    draw.rectangle((0, 0, water.width - 1, water.height - 1), outline=(0, 13, 31, 92), width=2)
    for inset in range(0, 16, 2):
        alpha = max(0, 56 - inset * 6)
        draw.rectangle((inset, inset, water.width - 1 - inset, water.height - 1 - inset), outline=(0, 8, 20, alpha), width=1)
    return water.convert("RGB")


def build_current_screen() -> Image.Image:
    screen = Image.new("RGB", VIEWPORT, "#04101e")
    draw = ImageDraw.Draw(screen)
    for y in range(VIEWPORT[1]):
        t = y / max(1, VIEWPORT[1] - 1)
        r = round(12 * (1 - t) + 4 * t)
        g = round(36 * (1 - t) + 16 * t)
        b = round(58 * (1 - t) + 30 * t)
        draw.line((0, y, VIEWPORT[0], y), fill=(r, g, b))
    x = ROOT_MARGIN
    y = ROOT_MARGIN
    screen.paste(build_current_status(), (x, y))
    y += STATUS_H + V_GAP
    screen.paste(build_water_window(), (x, y))
    y += WATER_H + V_GAP
    screen.paste(build_current_hud(), (x, y))
    screen.paste(build_current_sidebar(), (ROOT_MARGIN + LEFT_W + BODY_GAP, ROOT_MARGIN))
    return screen


def main() -> int:
    reference = Image.open(REFERENCE).convert("RGB")
    current = build_current_screen()
    current.save(CURRENT_OUT)
    ref = _resize(reference, VIEWPORT)
    label_h = 34
    gap = 24
    out = Image.new("RGB", (VIEWPORT[0] * 2 + gap + 32, VIEWPORT[1] + label_h + 18), BG)
    draw = ImageDraw.Draw(out)
    draw.text((16, 11), "REFERENCE FULL SCREEN", fill=TEXT_LABEL)
    draw.text((16 + VIEWPORT[0] + gap, 11), "CURRENT STATIC FULL SCREEN", fill=TEXT_LABEL)
    out.paste(ref, (16, label_h))
    out.paste(current, (16 + VIEWPORT[0] + gap, label_h))
    out.save(OUT)
    print(OUT)
    print(CURRENT_OUT)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
