#!/usr/bin/env python3
"""Build a v1 layout reference for the shark pen screen."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "reference" / "12_shark_pen_mockup.png"
FONT_BOLD = ROOT / "assets" / "fonts" / "line_seed" / "LINESeedJP_A_TTF_Bd.ttf"
FONT_EXTRA = ROOT / "assets" / "fonts" / "line_seed" / "LINESeedJP_A_TTF_Eb.ttf"
FISH_DIR = ROOT / "assets" / "showcase" / "fish"
VIEWPORT = (1280, 720)


def main() -> None:
    OUT.parent.mkdir(parents=True, exist_ok=True)
    canvas = Image.new("RGB", VIEWPORT, "#061322")
    draw = ImageDraw.Draw(canvas)
    _draw_ocean_backdrop(draw)
    _panel(draw, (32, 20, 1248, 108), "#13283f", "#e1bd72", 3)
    _text(draw, (58, 34), "サメの生簀", 34, "#fff1c7", extra=True)
    _text(draw, (60, 75), "危険海域で出会ったサメに餌を与え、なつき度を育てる", 15, "#eaf6ff")
    _draw_status_stub(draw)

    aquarium = (44, 126, 760, 558)
    _panel(draw, aquarium, "#0b2b3c", "#e1bd72", 3)
    _draw_aquarium(canvas, draw, aquarium)
    _text(draw, (66, 145), "水槽ビュー", 20, "#fff1c7", bold=True)

    roster = (782, 126, 1236, 558)
    _panel(draw, roster, "#13283f", "#e1bd72", 3)
    _text(draw, (806, 145), "サメ選択", 20, "#fff1c7", bold=True)
    _draw_roster(draw, roster)

    feed = (44, 575, 986, 688)
    _panel(draw, feed, "#172f43", "#e1bd72", 3)
    _text(draw, (68, 594), "餌やり", 20, "#fff1c7", bold=True)
    _text(draw, (154, 598), "好物には王冠。1匹消費してEXPとなつき度を獲得", 14, "#eaf6ff")
    _draw_feed_cards(draw)

    _panel(draw, (1016, 603, 1228, 676), "#b88732", "#ffe7a8", 3)
    _text(draw, (1062, 624), "港へ戻る", 24, "#fff1c7", extra=True)
    canvas.save(OUT)
    print(OUT)


def _font(size: int, *, bold: bool = False, extra: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    path = FONT_EXTRA if extra else FONT_BOLD if bold else FONT_BOLD
    try:
        return ImageFont.truetype(str(path), size)
    except OSError:
        return ImageFont.load_default()


def _text(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str, size: int, fill: str, *, bold: bool = False, extra: bool = False) -> None:
    draw.text((xy[0] + 2, xy[1] + 2), text, font=_font(size, bold=bold, extra=extra), fill="#06101c")
    draw.text(xy, text, font=_font(size, bold=bold, extra=extra), fill=fill)


def _panel(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], fill: str, border: str, width: int) -> None:
    draw.rounded_rectangle(box, radius=8, fill=fill, outline="#06101c", width=width + 2)
    inset = (box[0] + 3, box[1] + 3, box[2] - 3, box[3] - 3)
    draw.rounded_rectangle(inset, radius=6, outline=border, width=width)


def _draw_ocean_backdrop(draw: ImageDraw.ImageDraw) -> None:
    for y in range(VIEWPORT[1]):
        t = y / float(VIEWPORT[1] - 1)
        r = round(7 * (1 - t) + 3 * t)
        g = round(35 * (1 - t) + 15 * t)
        b = round(58 * (1 - t) + 33 * t)
        draw.line((0, y, VIEWPORT[0], y), fill=(r, g, b))
    for x in range(0, VIEWPORT[0], 46):
        draw.line((x, 120, x - 160, 720), fill=(45, 119, 146), width=1)


def _draw_status_stub(draw: ImageDraw.ImageDraw) -> None:
    x0, y0 = 770, 42
    labels = ["Lv.50", "遠洋竿", "128,400 G"]
    widths = [112, 150, 210]
    for label, width in zip(labels, widths):
        _panel(draw, (x0, y0, x0 + width, y0 + 44), "#0a1622", "#b98a3e", 2)
        _text(draw, (x0 + 18, y0 + 10), label, 17, "#fff1c7", bold=True)
        x0 += width + 12


def _draw_aquarium(canvas: Image.Image, draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int]) -> None:
    x0, y0, x1, y1 = box
    for y in range(y0 + 6, y1 - 6):
        t = (y - y0) / float(max(1, y1 - y0))
        color = (round(16 * (1 - t) + 3 * t), round(82 * (1 - t) + 36 * t), round(104 * (1 - t) + 62 * t))
        draw.line((x0 + 6, y, x1 - 6, y), fill=color)
    for y in [214, 318, 428]:
        draw.arc((x0 + 60, y - 24, x1 - 50, y + 66), 178, 356, fill=(120, 210, 225), width=2)
    _paste_fish(canvas, "megalodon", (118, 250), 520)
    _paste_fish(canvas, "shumokuzame", (420, 176), 250)
    _paste_fish(canvas, "nekozame", (96, 410), 220)
    draw.rectangle((x0 + 16, y1 - 54, x1 - 16, y1 - 18), fill=(4, 18, 25))
    _text(draw, (x0 + 30, y1 - 48), "選択中: メガロドン  なつき度 84/100", 17, "#fff1c7", bold=True)


def _paste_fish(canvas: Image.Image, fish_id: str, xy: tuple[int, int], target_w: int) -> None:
    path = FISH_DIR / f"{fish_id}_showcase_sheet.png"
    if not path.exists():
        return
    sheet = Image.open(path).convert("RGBA")
    img = sheet.crop((0, 0, 640, 320))
    scale = target_w / float(img.width)
    img = img.resize((round(img.width * scale), round(img.height * scale)), Image.Resampling.LANCZOS)
    canvas.alpha_composite(img, xy) if canvas.mode == "RGBA" else canvas.paste(img, xy, img)


def _draw_roster(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int]) -> None:
    names = ["ネコザメ", "イヌザメ", "ドチザメ", "ホシザメ", "エポレット", "ダルマザメ", "フジクジラ", "シュモク", "ホオジロ", "メガロドン"]
    bonds = [100, 76, 64, 100, 42, 18, 0, 35, 12, 84]
    y = box[1] + 56
    for index, (name, bond) in enumerate(zip(names, bonds)):
        selected = name == "メガロドン"
        fill = "#f3e8cd" if selected else ("#102138" if index % 2 == 0 else "#0a1622")
        text = "#203042" if selected else "#fff1c7"
        draw.rounded_rectangle((806, y, 1212, y + 31), radius=5, fill=fill)
        if selected:
            draw.rounded_rectangle((806, y, 1212, y + 31), radius=5, outline="#ffe7a8", width=2)
        else:
            draw.line((812, y + 31, 1206, y + 31), fill="#31485d", width=1)
        _text(draw, (820, y + 5), name, 13, text, bold=True)
        draw.rectangle((946, y + 9, 1138, y + 21), fill="#06101c")
        fill_w = round(192 * bond / 100.0)
        draw.rectangle((946, y + 9, 946 + fill_w, y + 21), fill="#3cbf78" if bond == 100 else "#e0a02e")
        _text(draw, (1152, y + 5), "完" if bond == 100 else f"{bond}", 13, text, bold=True)
        y += 36


def _draw_feed_cards(draw: ImageDraw.ImageDraw) -> None:
    cards = [("キハダ", "x2", "好物"), ("深淵の重鎮", "x1", "好物"), ("マハゼ", "x8", ""), ("ブリ", "x3", ""), ("カサゴ", "x5", "")]
    x = 68
    for name, count, tag in cards:
        _panel(draw, (x, 630, x + 140, 674), "#f3e8cd", "#b98a3e", 1)
        _text(draw, (x + 12, 637), name, 13, "#203042", bold=True)
        _text(draw, (x + 100, 637), count, 13, "#203042", bold=True)
        if tag:
            draw.ellipse((x + 10, 653, x + 28, 671), fill="#ffe7a8", outline="#9b3d24", width=2)
        x += 152
    _panel(draw, (828, 626, 954, 678), "#b88732", "#ffe7a8", 2)
    _text(draw, (856, 640), "あたえる", 17, "#fff1c7", extra=True)


if __name__ == "__main__":
    main()
