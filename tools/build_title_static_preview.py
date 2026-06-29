#!/usr/bin/env python3
"""Build a deterministic static preview of the opening/title screen."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
ASSET_DIR = ROOT / "assets" / "showcase"
TITLE_DIR = ASSET_DIR / "title"
UNDERWATER_DIR = ASSET_DIR / "underwater"
FONT_BOLD = ROOT / "assets" / "fonts" / "MPLUS1p-ExtraBold.ttf"
FONT_REGULAR = ROOT / "assets" / "fonts" / "MPLUS1p-Regular.ttf"
OUT = Path("/tmp/tsuri_title_static_preview.png")

VIEWPORT = (1280, 720)


def _font(size: int, *, bold: bool = True) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONT_BOLD if bold else FONT_REGULAR), size)


def _cover(image: Image.Image, size: tuple[int, int], align: tuple[float, float] = (0.5, 0.5)) -> Image.Image:
    scale = max(size[0] / image.width, size[1] / image.height)
    resized = image.resize((round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS)
    x = round((resized.width - size[0]) * align[0])
    y = round((resized.height - size[1]) * align[1])
    return resized.crop((x, y, x + size[0], y + size[1]))


def _fit_contain(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    scale = min(size[0] / image.width, size[1] / image.height)
    return image.resize((round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS)


def _alpha_composite(base: Image.Image, layer: Image.Image, xy: tuple[int, int] = (0, 0), alpha: float = 1.0) -> None:
    layer = layer.convert("RGBA")
    if alpha < 1.0:
        layer.putalpha(layer.getchannel("A").point(lambda v: round(v * alpha)))
    base.alpha_composite(layer, xy)


def _draw_text(
    draw: ImageDraw.ImageDraw,
    xy: tuple[float, float],
    text: str,
    size: int,
    fill: str,
    *,
    bold: bool = True,
    stroke: int = 0,
    stroke_fill: str = "#000000",
    anchor: str = "la",
) -> None:
    draw.text(
        xy,
        text,
        font=_font(size, bold=bold),
        fill=fill,
        stroke_width=stroke,
        stroke_fill=stroke_fill,
        anchor=anchor,
    )


def _draw_centered_text(
    draw: ImageDraw.ImageDraw,
    box: tuple[int, int, int, int],
    text: str,
    size: int,
    fill: str,
    *,
    bold: bool = True,
    stroke: int = 0,
    stroke_fill: str = "#000000",
) -> None:
    x = (box[0] + box[2]) * 0.5
    y = (box[1] + box[3]) * 0.5
    _draw_text(draw, (x, y), text, size, fill, bold=bold, stroke=stroke, stroke_fill=stroke_fill, anchor="mm")


def _rect(ratios: tuple[float, float, float, float]) -> tuple[int, int, int, int]:
    return (
        round(VIEWPORT[0] * ratios[0]),
        round(VIEWPORT[1] * ratios[1]),
        round(VIEWPORT[0] * ratios[2]),
        round(VIEWPORT[1] * ratios[3]),
    )


def build_preview() -> Image.Image:
    bg = _cover(Image.open(TITLE_DIR / "title_ocean_bg.png").convert("RGBA"), VIEWPORT)
    ambience_path = UNDERWATER_DIR / "underwater_foreground_ambience.png"
    if ambience_path.exists():
        _alpha_composite(bg, _cover(Image.open(ambience_path).convert("RGBA"), VIEWPORT, (0.5, 0.55)), alpha=0.22)
    grade_path = TITLE_DIR / "title_color_grade.png"
    if grade_path.exists():
        _alpha_composite(bg, _cover(Image.open(grade_path).convert("RGBA"), VIEWPORT))

    draw = ImageDraw.Draw(bg)
    draw.rectangle((0, 0, VIEWPORT[0] - 1, VIEWPORT[1] - 1), outline=(0, 13, 25, 96), width=6)
    draw.line((0, 2, VIEWPORT[0], 2), fill=(255, 230, 140, 42), width=2)

    logo = Image.open(TITLE_DIR / "title_logo_frame.png").convert("RGBA")
    logo_box = _rect((0.040, 0.075, 0.735, 0.405))
    logo = logo.resize((logo_box[2] - logo_box[0], logo_box[3] - logo_box[1]), Image.Resampling.LANCZOS)
    _alpha_composite(bg, logo, (logo_box[0], logo_box[1]))
    _draw_centered_text(draw, (logo_box[0] + 64, logo_box[1] + 44, logo_box[2] - 64, logo_box[1] + 137), "釣りクエスト", 74, "#fff0a9", stroke=7, stroke_fill="#2b1308")
    _draw_centered_text(draw, (logo_box[0] + 64, logo_box[1] + 136, logo_box[2] - 64, logo_box[1] + 179), "海釣り編", 34, "#9de9ff", stroke=4, stroke_fill="#062a40")
    _draw_centered_text(draw, (logo_box[0] + 64, logo_box[1] + 182, logo_box[2] - 64, logo_box[3] - 30), "港で支度し、釣って、料理して、強くなる。", 19, "#fff7d4", bold=False, stroke=2, stroke_fill="#061624")

    fish_box = _rect((0.050, 0.555, 0.430, 0.930))
    fish = Image.open(UNDERWATER_DIR / "fish" / "kurodai_card_portrait.png").convert("RGBA")
    fish = _fit_contain(fish, (fish_box[2] - fish_box[0], fish_box[3] - fish_box[1] - 40))
    fish.putalpha(fish.getchannel("A").point(lambda v: round(v * 0.92)))
    _alpha_composite(bg, fish, (round((fish_box[0] + fish_box[2] - fish.width) * 0.5), fish_box[1] - 10))
    _draw_centered_text(draw, (fish_box[0] + 10, fish_box[1] + round((fish_box[3] - fish_box[1]) * 0.82), fish_box[2] - 10, fish_box[3]), "次の大物が、海の底で待っている。", 18, "#fff5c5", bold=False, stroke=2, stroke_fill="#071420")

    menu = Image.open(TITLE_DIR / "title_menu_frame.png").convert("RGBA")
    menu_box = _rect((0.585, 0.360, 0.965, 0.950))
    menu = menu.resize((menu_box[2] - menu_box[0], menu_box[3] - menu_box[1]), Image.Resampling.LANCZOS)
    _alpha_composite(bg, menu, (menu_box[0], menu_box[1]))

    header_y = menu_box[1] + 54
    bait = Image.open(UNDERWATER_DIR / "hud_bait_icon.png").convert("RGBA").resize((34, 34), Image.Resampling.LANCZOS)
    _alpha_composite(bg, bait, (menu_box[0] + 177, header_y - 19))
    _draw_text(draw, (menu_box[0] + 219, header_y), "冒険の開始", 24, "#fff1c7", stroke=2, stroke_fill="#06121c", anchor="lm")
    _draw_centered_text(draw, (menu_box[0] + 42, menu_box[1] + 86, menu_box[2] - 42, menu_box[1] + 112), "セーブデータ  なし", 15, "#4f361b", bold=False)

    button_specs = [
        ("title_button_disabled.png", "つづきから", 0),
        ("title_button_primary.png", "ゲームを始める", 1),
        ("title_button_disabled.png", "仕様書・操作は README.md を参照", 2),
    ]
    for filename, label, index in button_specs:
        button = Image.open(TITLE_DIR / filename).convert("RGBA")
        button_box = (
            menu_box[0] + 55,
            menu_box[1] + 126 + index * 70,
            menu_box[2] - 55,
            menu_box[1] + 184 + index * 70,
        )
        button = button.resize((button_box[2] - button_box[0], button_box[3] - button_box[1]), Image.Resampling.LANCZOS)
        _alpha_composite(bg, button, (button_box[0], button_box[1]))
        fill = "#fff4ca" if index == 1 else "#d1c8b6"
        _draw_centered_text(draw, button_box, label, 19, fill, stroke=2, stroke_fill="#2a1608")

    _draw_centered_text(draw, _rect((0.585, 0.950, 0.965, 0.995)), "MVP Prototype v0.1 / Godot 4.7", 14, "#d7eef6", bold=False, stroke=1, stroke_fill="#03101c")
    return bg.convert("RGB")


def main() -> int:
    missing = [
        TITLE_DIR / "title_ocean_bg.png",
        TITLE_DIR / "title_color_grade.png",
        TITLE_DIR / "title_logo_frame.png",
        TITLE_DIR / "title_menu_frame.png",
        TITLE_DIR / "title_button_primary.png",
        TITLE_DIR / "title_button_disabled.png",
        UNDERWATER_DIR / "fish" / "kurodai_card_portrait.png",
        UNDERWATER_DIR / "hud_bait_icon.png",
    ]
    missing = [path for path in missing if not path.exists()]
    if missing:
        print("Missing required title preview assets:")
        for path in missing:
            print(f"  - {path}")
        return 1
    preview = build_preview()
    preview.save(OUT)
    print(OUT)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
