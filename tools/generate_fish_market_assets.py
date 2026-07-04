#!/usr/bin/env python3
"""Generate first-pass fish market showcase assets.

The generated image intentionally contains no Japanese labels, fish names,
prices, or quantities. Runtime UI draws all variable state.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "showcase" / "fish_market"
W, H = 1280, 720


COLORS = {
    "navy": (19, 40, 63, 238),
    "navy_deep": (10, 22, 34, 246),
    "blue": (23, 59, 97, 230),
    "gold": (225, 189, 114, 255),
    "gold_deep": (185, 138, 62, 255),
    "paper": (243, 232, 205, 255),
    "paper_deep": (231, 214, 173, 255),
    "sand": (216, 192, 137, 255),
    "wood": (94, 58, 28, 255),
    "wood_hi": (138, 84, 40, 255),
    "teal": (47, 155, 214, 255),
    "shadow": (0, 0, 0, 86),
    "ice": (214, 238, 247, 255),
}


def rgba(color: str, alpha: int | None = None) -> tuple[int, int, int, int]:
    r, g, b, a = COLORS[color]
    return (r, g, b, a if alpha is None else alpha)


def rounded(draw: ImageDraw.ImageDraw, xy, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=width)


def shadowed_panel(base: Image.Image, xy, radius: int, fill, outline, width: int = 3, shadow=8):
    x0, y0, x1, y1 = xy
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    rounded(d, (x0 + shadow, y0 + shadow, x1 + shadow, y1 + shadow), radius, rgba("shadow", 92))
    layer = layer.filter(ImageFilter.GaussianBlur(6))
    base.alpha_composite(layer)
    d = ImageDraw.Draw(base)
    rounded(d, xy, radius, fill, outline, width)


def parchment_panel(base: Image.Image, xy, radius: int = 10):
    shadowed_panel(base, xy, radius, rgba("paper"), rgba("gold_deep"), 3, shadow=6)
    d = ImageDraw.Draw(base)
    x0, y0, x1, y1 = xy
    rounded(d, (x0 + 8, y0 + 8, x1 - 8, y1 - 8), radius - 2, (255, 250, 232, 38), rgba("paper_deep"), 1)


def navy_panel(base: Image.Image, xy, radius: int = 10):
    shadowed_panel(base, xy, radius, rgba("navy"), rgba("gold"), 3, shadow=6)
    d = ImageDraw.Draw(base)
    x0, y0, x1, y1 = xy
    rounded(d, (x0 + 8, y0 + 8, x1 - 8, y1 - 8), radius - 2, (13, 30, 48, 122), rgba("gold_deep", 170), 1)


def draw_market_background(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    for y in range(H):
        t = y / H
        r = int(155 * (1 - t) + 9 * t)
        g = int(214 * (1 - t) + 26 * t)
        b = int(238 * (1 - t) + 45 * t)
        d.line((0, y, W, y), fill=(r, g, b, 255))

    # Wooden roof and beams.
    d.rectangle((0, 0, W, 92), fill=rgba("wood"))
    for x in range(-40, W, 110):
        d.polygon([(x, 0), (x + 72, 0), (x + 48, 92), (x - 24, 92)], fill=rgba("wood_hi", 210))
    for y in (86, 676):
        d.rectangle((0, y, W, y + 14), fill=rgba("wood"))

    # Distant market shapes.
    for x in range(0, W, 165):
        d.rectangle((x + 18, 112, x + 128, 520), fill=(37, 54, 58, 96))
        d.rectangle((x + 10, 110, x + 136, 124), fill=rgba("wood_hi", 160))
    d.rectangle((1012, 128, 1268, 292), fill=(201, 237, 247, 110))
    d.rectangle((1012, 292, 1268, 320), fill=(47, 155, 214, 126))

    # Crates and ice piles around the edges.
    for box in [(20, 554, 220, 690), (1050, 510, 1266, 690), (24, 130, 214, 244), (1048, 340, 1262, 488)]:
        x0, y0, x1, y1 = box
        rounded(d, box, 8, rgba("wood", 235), rgba("gold_deep", 130), 2)
        d.rectangle((x0 + 10, y0 + 20, x1 - 10, y0 + 34), fill=rgba("wood_hi", 190))
        for i in range(18):
            cx = x0 + 18 + (i * 29) % max(30, (x1 - x0 - 36))
            cy = y0 + 46 + ((i * 19) % max(28, (y1 - y0 - 62)))
            d.ellipse((cx, cy, cx + 24, cy + 12), fill=(142, 168, 172, 170), outline=(55, 75, 78, 130))

    # Soft darkening behind the information surface.
    overlay = Image.new("RGBA", img.size, (10, 22, 34, 86))
    img.alpha_composite(overlay)


def draw_top_frame(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    shadowed_panel(img, (54, 18, 1226, 92), 8, rgba("navy_deep", 236), rgba("gold"), 3, shadow=5)
    rounded(d, (78, 30, 334, 82), 8, rgba("blue", 220), rgba("gold_deep"), 2)
    d.ellipse((98, 35, 143, 80), fill=rgba("gold_deep"), outline=rgba("gold"), width=2)
    d.line((121, 42, 121, 73), fill=rgba("paper"), width=3)
    d.line((106, 58, 136, 58), fill=rgba("paper"), width=3)


def draw_inventory_panel(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    parchment_panel(img, (48, 114, 682, 658), 10)
    rounded(d, (86, 132, 176, 182), 5, rgba("blue", 220), rgba("gold_deep"), 2)
    rounded(d, (198, 136, 440, 174), 6, rgba("paper_deep", 190), rgba("gold_deep", 85), 1)

    row_y = 198
    row_h = 62
    for i in range(7):
        y = row_y + i * 66
        fill = (247, 239, 217, 220) if i % 2 == 0 else (235, 222, 191, 215)
        rounded(d, (72, y, 662, y + row_h), 4, fill, (172, 151, 116, 150), 1)
        rounded(d, (88, y + 6, 166, y + 56), 4, rgba("navy_deep", 228), rgba("gold_deep"), 2)
        rounded(d, (190, y + 14, 330, y + 42), 5, rgba("paper_deep", 175))
        draw_basket_icon(d, 350, y + 21, 20, rgba("wood"))
        rounded(d, (386, y + 15, 448, y + 43), 5, (245, 235, 210, 220), (148, 121, 82, 130), 1)
        draw_coin(d, 476, y + 29, 14)
        rounded(d, (504, y + 15, 584, y + 43), 5, (245, 235, 210, 220), (148, 121, 82, 130), 1)
        for x in (606, 642):
            rounded(d, (x, y + 12, x + 28, y + 46), 4, rgba("navy_deep"), rgba("gold_deep"), 1)
        rounded(d, (640, y + 12, 660, y + 46), 4, rgba("blue"), rgba("gold_deep"), 1)


def draw_detail_panel(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    navy_panel(img, (704, 122, 1234, 486), 10)
    rounded(d, (760, 142, 1098, 182), 8, rgba("paper"), rgba("gold_deep"), 2)
    rounded(d, (1138, 152, 1198, 212), 10, rgba("blue"), rgba("teal"), 3)
    for x in (1148, 1172, 1196):
        d.polygon([(x, 232), (x + 10, 222), (x + 20, 232), (x + 10, 242)], fill=rgba("navy_deep"), outline=rgba("gold"))

    # Fish art socket on crushed ice; runtime fish portrait sits on top.
    rounded(d, (738, 198, 1118, 370), 8, (42, 69, 83, 225), rgba("gold_deep"), 2)
    for i in range(80):
        x = 750 + (i * 41) % 350
        y = 212 + (i * 23) % 136
        d.ellipse((x, y, x + 22, y + 16), fill=rgba("ice", 150), outline=(255, 255, 255, 90))
    for offset in range(0, 7):
        y = 250 + offset * 12
        d.arc((800, y - 36, 1058, y + 56), 185, 350, fill=(255, 255, 255, 28), width=2)

    rounded(d, (724, 382, 1214, 450), 6, rgba("navy_deep", 220), rgba("gold_deep"), 1)
    for idx, y in enumerate((397, 426)):
        d.rectangle((820, y, 1128, y + 14), fill=(198, 211, 213, 120))
        if idx == 0:
            d.ellipse((754, y - 3, 774, y + 17), fill=rgba("sand"))
        else:
            d.arc((750, y - 10, 780, y + 20), 10, 170, fill=rgba("teal"), width=3)

    for x, w in ((724, 140), (888, 144), (1056, 150)):
        rounded(d, (x, 456, x + w, 480), 5, (42, 52, 58, 180), rgba("gold_deep"), 1)


def draw_cart_panel(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    navy_panel(img, (704, 504, 1234, 666), 10)
    draw_basket_icon(d, 734, 526, 34, rgba("sand"))
    rounded(d, (790, 526, 1018, 556), 6, (203, 215, 210, 130))
    for i in range(6):
        x = 736 + i * 76
        rounded(d, (x, 572, x + 58, 624), 6, rgba("navy_deep", 170), (211, 228, 230, 70), 1)
        d.ellipse((x + 14, 592, x + 44, 610), fill=(84, 118, 126, 78))
    draw_coin(d, 752, 642, 19)
    rounded(d, (792, 626, 980, 660), 7, rgba("paper"), rgba("gold_deep"), 1)
    rounded(d, (1008, 612, 1198, 662), 10, rgba("gold"), rgba("gold_deep"), 3)


def draw_return_button(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    shadowed_panel(img, (52, 666, 172, 706), 10, rgba("blue"), rgba("gold_deep"), 2, shadow=4)
    d.line((100, 686, 132, 686), fill=rgba("paper"), width=5)
    d.line((100, 686, 116, 674), fill=rgba("paper"), width=5)
    d.line((100, 686, 116, 698), fill=rgba("paper"), width=5)


def draw_coin(d: ImageDraw.ImageDraw, cx: int, cy: int, r: int) -> None:
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=rgba("gold"), outline=rgba("gold_deep"), width=2)
    d.ellipse((cx - r + 5, cy - r + 5, cx + r - 5, cy + r - 5), outline=(255, 244, 188, 180), width=1)


def draw_basket_icon(d: ImageDraw.ImageDraw, x: int, y: int, s: int, color) -> None:
    d.arc((x, y - s // 3, x + s, y + s // 2), 190, 350, fill=color, width=max(2, s // 9))
    d.polygon([(x + 3, y + s // 3), (x + s - 3, y + s // 3), (x + s - 8, y + s), (x + 8, y + s)], outline=color, fill=None)
    d.line((x + 8, y + s // 2, x + s - 8, y + s // 2), fill=color, width=max(1, s // 12))


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw_market_background(img)
    draw_top_frame(img)
    draw_inventory_panel(img)
    draw_detail_panel(img)
    draw_cart_panel(img)
    draw_return_button(img)
    img.save(OUT / "fish_market_backplate.png")
    print(f"generated {OUT / 'fish_market_backplate.png'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
