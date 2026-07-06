#!/usr/bin/env python3
"""Build the v1 quest board reference mockup."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "reference" / "11_quest_board_mockup.png"
FONT_BOLD = ROOT / "assets" / "fonts" / "line_seed" / "LINESeedJP_A_TTF_Bd.ttf"
FONT_REGULAR = ROOT / "assets" / "fonts" / "line_seed" / "LINESeedJP_A_TTF_Rg.ttf"
W, H = 1280, 720


def font(size: int, *, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    path = FONT_BOLD if bold else FONT_REGULAR
    try:
        return ImageFont.truetype(str(path), size)
    except OSError:
        return ImageFont.load_default()


def rounded(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], fill: str, outline: str, width: int = 2) -> None:
    draw.rounded_rectangle(box, radius=8, fill=fill, outline=outline, width=width)


def text(draw: ImageDraw.ImageDraw, xy: tuple[int, int], value: str, size: int, fill: str, *, bold: bool = False) -> None:
    draw.text(xy, value, font=font(size, bold=bold), fill=fill)


def build() -> None:
    img = Image.new("RGB", (W, H), "#08243a")
    draw = ImageDraw.Draw(img)

    for y in range(H):
        ratio = y / H
        r = round(16 * (1 - ratio) + 4 * ratio)
        g = round(85 * (1 - ratio) + 32 * ratio)
        b = round(104 * (1 - ratio) + 44 * ratio)
        draw.line((0, y, W, y), fill=(r, g, b))

    rounded(draw, (32, 24, 1248, 122), "#103a49", "#dfb45d", 3)
    text(draw, (70, 42), "依頼ボード", 38, "#fff2bc", bold=True)
    text(draw, (72, 88), "港の人たちから届いた3件の依頼", 17, "#d8f5ff")
    rounded(draw, (760, 42, 1210, 104), "#15291f", "#dfb45d", 2)
    text(draw, (792, 62), "Lv.9     職人竿     12,450 G", 21, "#fff2bc", bold=True)

    rounded(draw, (44, 148, 1236, 602), "#5b3519", "#efca71", 4)
    for x in range(58, 1228, 32):
        draw.line((x, 166, x + 26, 584), fill="#69411f", width=2)

    quests = [
        ("依頼札 1", "納品", "アジを5匹届けてほしい", "進捗 2 / 5 匹", "報酬 960 G", False),
        ("依頼札 2", "記録", "45cm以上のメジナを釣り上げてくれ", "進捗 47.2 / 45.0 cm", "報酬 1,250 G", True),
        ("依頼札 3", "納品", "磯の活力丼にするカサゴを1匹", "進捗 1 / 1 匹", "報酬 420 G", True),
    ]
    for i, quest in enumerate(quests):
        left = 74 + i * 386
        top = 186
        right = left + 350
        bottom = 562
        rounded(draw, (left + 6, top + 8, right + 6, bottom + 8), "#1a1208", "#1a1208", 1)
        rounded(draw, (left, top, right, bottom), "#f0d7a2", "#6d4824", 3)
        text(draw, (left + 28, top + 22), quest[0], 22, "#2e1a0b", bold=True)
        rounded(draw, (right - 100, top + 18, right - 26, top + 50), "#774b1f", "#3b210d", 2)
        text(draw, (right - 84, top + 21), quest[1], 17, "#fff4c9", bold=True)
        rounded(draw, (left + 28, top + 78, left + 112, top + 162), "#d8c18f", "#6d4824", 2)
        text(draw, (left + 132, top + 82), quest[2], 22, "#2a190c", bold=True)
        text(draw, (left + 132, top + 142), quest[3], 18, "#473019")
        draw.rounded_rectangle((left + 28, top + 208, right - 28, top + 232), radius=6, fill="#49311a", outline="#8f6d35", width=2)
        fill_right = left + 28 + (right - left - 56) * (0.42 if not quest[5] else 1.0)
        draw.rounded_rectangle((left + 31, top + 211, round(fill_right) - 3, top + 229), radius=5, fill="#e2ad45")
        text(draw, (left + 28, top + 256), quest[4], 20, "#2d1d0d", bold=True)
        button_fill = "#6d4a24" if not quest[5] else "#2e6b53"
        rounded(draw, (left + 74, bottom - 70, right - 74, bottom - 24), button_fill, "#231507", 2)
        text(draw, (left + 143, bottom - 60), "納品" if quest[1] == "納品" else "報告", 22, "#fff2bc", bold=True)

    rounded(draw, (44, 624, 1236, 690), "#103a49", "#dfb45d", 3)
    text(draw, (74, 644), "達成数 9件  |  10件目で職人仕掛け", 19, "#fff2bc", bold=True)
    rounded(draw, (1040, 636, 1212, 678), "#6f411d", "#efca71", 2)
    text(draw, (1074, 644), "港へ戻る", 22, "#fff2bc", bold=True)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT)
    print(OUT)


if __name__ == "__main__":
    build()
