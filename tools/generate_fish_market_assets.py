#!/usr/bin/env python3
"""Generate decomposed fish market showcase assets.

The generated image intentionally contains no Japanese labels, fish names,
prices, or quantities. Runtime UI draws all variable state.
"""

from __future__ import annotations

import math
from pathlib import Path
from random import Random

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "showcase" / "fish_market"
M2_SOURCE = ROOT / "tools" / "source_assets" / "fish_market"
COMMON_PARCHMENT = ROOT / "assets" / "showcase" / "common" / "parchment_card.png"
W, H = 1280, 720
RNG = Random(20260704)
RUNTIME_BACKDROP = (10, 22, 34, 255)


COLORS = {
    "navy": (19, 40, 63, 238),
    "navy_deep": (10, 22, 34, 246),
    "blue": (23, 59, 97, 230),
    "gold": (225, 189, 114, 255),
    "gold_deep": (185, 138, 62, 255),
    "paper": (243, 232, 205, 255),
    "paper_deep": (231, 214, 173, 255),
    "paper_shadow": (178, 147, 98, 255),
    "sand": (216, 192, 137, 255),
    "wood": (94, 58, 28, 255),
    "wood_dark": (62, 38, 22, 255),
    "wood_hi": (138, 84, 40, 255),
    "teal": (47, 155, 214, 255),
    "teal_deep": (19, 99, 112, 255),
    "shadow": (0, 0, 0, 86),
    "ice": (214, 238, 247, 255),
    "ice_shadow": (120, 151, 162, 255),
}


def save_png_if_pixels_changed(candidate: Image.Image, output_path: Path) -> bool:
    """Preserve existing PNG bytes when decoded pixels are already identical."""
    candidate.load()
    if output_path.is_file():
        with Image.open(output_path) as existing:
            existing.load()
            if (
                existing.size == candidate.size
                and existing.mode == candidate.mode
                and existing.tobytes() == candidate.tobytes()
            ):
                print(f"preserved pixel-identical {output_path}")
                return False

    temporary_path = output_path.with_name(f".{output_path.name}.tmp")
    try:
        candidate.save(
            temporary_path,
            format="PNG",
            optimize=False,
            compress_level=9,
        )
        temporary_path.replace(output_path)
    finally:
        temporary_path.unlink(missing_ok=True)
    print(f"updated {output_path}")
    return True


def rgba(color: str, alpha: int | None = None) -> tuple[int, int, int, int]:
    r, g, b, a = COLORS[color]
    return (r, g, b, a if alpha is None else alpha)


def rounded(draw: ImageDraw.ImageDraw, xy, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline, width=width)


def mix(a, b, t: float) -> tuple[int, int, int, int]:
    return tuple(int(a[i] * (1.0 - t) + b[i] * t) for i in range(4))


def gradient_rect(d: ImageDraw.ImageDraw, xy, top, bottom) -> None:
    x0, y0, x1, y1 = map(int, xy)
    height = max(1, y1 - y0)
    for y in range(y0, y1):
        t = (y - y0) / height
        d.line((x0, y, x1, y), fill=mix(top, bottom, t))


def add_panel_grain(base: Image.Image, xy, color, alpha: int, count: int) -> None:
    x0, y0, x1, y1 = map(int, xy)
    d = ImageDraw.Draw(base)
    for _ in range(count):
        x = RNG.randint(x0 + 6, x1 - 6)
        y = RNG.randint(y0 + 6, y1 - 6)
        r = RNG.choice((1, 1, 2))
        a = RNG.randint(max(8, alpha // 3), alpha)
        d.ellipse((x, y, x + r, y + r), fill=(*color[:3], a))


def draw_corner_plates(d: ImageDraw.ImageDraw, xy, color, accent) -> None:
    x0, y0, x1, y1 = xy
    for sx, sy in ((1, 1), (-1, 1), (1, -1), (-1, -1)):
        cx = x0 if sx == 1 else x1
        cy = y0 if sy == 1 else y1
        d.line((cx + sx * 8, cy + sy * 5, cx + sx * 52, cy + sy * 5), fill=color, width=2)
        d.line((cx + sx * 5, cy + sy * 8, cx + sx * 5, cy + sy * 52), fill=color, width=2)
        d.line((cx + sx * 16, cy + sy * 18, cx + sx * 34, cy + sy * 10), fill=accent, width=1)


def draw_wood_planks(d: ImageDraw.ImageDraw, xy, base, highlight, shadow) -> None:
    x0, y0, x1, y1 = map(int, xy)
    gradient_rect(d, xy, highlight, base)
    for y in range(y0 + 12, y1, 24):
        d.line((x0, y, x1, y), fill=shadow, width=2)
        d.line((x0, y + 2, x1, y + 2), fill=(*highlight[:3], 70), width=1)


def shadowed_panel(base: Image.Image, xy, radius: int, fill, outline, width: int = 3, shadow=8):
    x0, y0, x1, y1 = xy
    layer = Image.new("RGBA", base.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    rounded(d, (x0 + shadow, y0 + shadow, x1 + shadow, y1 + shadow), radius, rgba("shadow", 92))
    layer = layer.filter(ImageFilter.GaussianBlur(6))
    base.alpha_composite(layer)
    d = ImageDraw.Draw(base)
    rounded(d, xy, radius, fill, outline, width)
    x0, y0, x1, y1 = xy
    rounded(d, (x0 + 5, y0 + 5, x1 - 5, y1 - 5), max(2, radius - 4), (255, 255, 255, 0), (255, 231, 168, 95), 1)


def parchment_panel(base: Image.Image, xy, radius: int = 10):
    shadowed_panel(base, xy, radius, rgba("paper"), rgba("gold_deep"), 3, shadow=6)
    d = ImageDraw.Draw(base)
    x0, y0, x1, y1 = xy
    rounded(d, (x0 + 8, y0 + 8, x1 - 8, y1 - 8), radius - 2, (255, 250, 232, 42), rgba("paper_deep"), 1)
    draw_corner_plates(d, xy, rgba("gold_deep", 185), (255, 231, 168, 120))
    add_panel_grain(base, xy, rgba("paper_shadow"), 12, 140)


def navy_panel(base: Image.Image, xy, radius: int = 10):
    shadowed_panel(base, xy, radius, rgba("navy"), rgba("gold"), 3, shadow=6)
    d = ImageDraw.Draw(base)
    x0, y0, x1, y1 = xy
    rounded(d, (x0 + 8, y0 + 8, x1 - 8, y1 - 8), radius - 2, (13, 30, 48, 122), rgba("gold_deep", 170), 1)
    draw_corner_plates(d, xy, rgba("gold_deep", 175), (255, 231, 168, 110))
    add_panel_grain(base, xy, (76, 132, 164, 255), 10, 110)


def draw_market_background(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    gradient_rect(d, (0, 0, W, H), (132, 191, 209, 255), (9, 26, 45, 255))

    # Wooden roof and beams.
    draw_wood_planks(d, (0, 0, W, 116), rgba("wood"), rgba("wood_hi"), rgba("wood_dark", 190))
    for x in range(-40, W, 110):
        d.polygon([(x, 0), (x + 72, 0), (x + 48, 116), (x - 24, 116)], fill=rgba("wood_hi", 112))
    for y in (102, 676):
        draw_wood_planks(d, (0, y, W, y + 20), rgba("wood_dark"), rgba("wood"), rgba("wood_dark", 180))

    # Distant market stalls and window shapes.
    for x in range(-20, W, 155):
        d.rectangle((x + 22, 124, x + 126, 528), fill=(25, 43, 49, 118))
        d.rectangle((x + 14, 122, x + 134, 136), fill=rgba("wood_hi", 170))
        d.rectangle((x + 28, 144, x + 118, 306), fill=(176, 220, 232, 58))
    d.rectangle((1012, 126, 1268, 292), fill=(201, 237, 247, 118))
    d.rectangle((1012, 292, 1268, 334), fill=(47, 155, 214, 150))
    for x in (1034, 1110, 1184):
        d.rectangle((x, 130, x + 7, 334), fill=(24, 42, 50, 130))
    d.rectangle((1012, 246, 1268, 254), fill=(24, 42, 50, 100))

    # Crates and ice piles around the edges.
    for box in [(18, 554, 228, 696), (1050, 526, 1268, 700), (22, 132, 218, 246), (1048, 352, 1264, 494)]:
        draw_wood_crate(d, box)
        draw_fish_mound(d, box, 18)

    draw_hanging_scale(d, 1180, 64)
    draw_lantern(d, 1038, 42)

    # Soft darkening behind the information surface.
    overlay = Image.new("RGBA", img.size, (10, 22, 34, 106))
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
    with Image.open(COMMON_PARCHMENT) as source:
        source.load()
        paper_center = source.convert("RGBA").crop((42, 24, source.width - 42, source.height - 24))
    paper_center = paper_center.resize((606, 520), Image.Resampling.LANCZOS)
    img.alpha_composite(paper_center, (62, 126))
    d = ImageDraw.Draw(img)
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


def draw_detail_panel_frame(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    navy_panel(img, (704, 122, 1234, 486), 10)
    rounded(d, (760, 142, 1098, 182), 8, rgba("paper"), rgba("gold_deep"), 2)
    rounded(d, (1138, 152, 1198, 212), 10, rgba("blue"), rgba("teal"), 3)
    for x in (1148, 1172, 1196):
        d.polygon([(x, 232), (x + 10, 222), (x + 20, 232), (x + 10, 242)], fill=rgba("navy_deep"), outline=rgba("gold"))

    rounded(d, (724, 382, 1214, 450), 6, rgba("navy_deep", 220), rgba("gold_deep"), 1)
    for idx, y in enumerate((397, 426)):
        d.rectangle((820, y, 1128, y + 14), fill=(198, 211, 213, 120))
        if idx == 0:
            d.ellipse((754, y - 3, 774, y + 17), fill=rgba("sand"))
        else:
            d.arc((750, y - 10, 780, y + 20), 10, 170, fill=rgba("teal"), width=3)

    for x, w in ((724, 140), (888, 144), (1056, 150)):
        rounded(d, (x, 456, x + w, 480), 5, (42, 52, 58, 180), rgba("gold_deep"), 1)


def draw_ice_tray_hero(img: Image.Image) -> None:
    """Draw the fish-free appraisal tray; runtime fish art is layered above it."""
    d = ImageDraw.Draw(img)
    rounded(d, (738, 198, 1118, 370), 8, (38, 70, 86, 230), rgba("gold_deep"), 2)
    rounded(d, (772, 244, 1104, 358), 8, rgba("wood", 214), rgba("wood_dark", 180), 2)
    d.rectangle((784, 254, 1092, 272), fill=rgba("wood_hi", 130))
    d.rectangle((784, 328, 1092, 346), fill=rgba("wood_dark", 96))
    draw_leaf(d, (782, 222), 108, -18)
    draw_leaf(d, (998, 224), 100, 20)
    for i in range(104):
        x = 760 + (i * 41) % 340
        y = 216 + (i * 23) % 126
        w = RNG.randint(14, 28)
        h = RNG.randint(10, 18)
        fill = rgba("ice", RNG.randint(135, 198)) if i % 3 else rgba("ice_shadow", RNG.randint(110, 155))
        d.ellipse((x, y, x + w, y + h), fill=fill, outline=(255, 255, 255, RNG.randint(50, 110)))
    for offset in range(0, 7):
        y = 248 + offset * 13
        d.arc((792, y - 38, 1064, y + 58), 185, 350, fill=(255, 255, 255, 34), width=2)

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


def flatten_for_runtime(img: Image.Image) -> Image.Image:
    """Match Godot's composition over MarketScreen's opaque letterbox color."""
    backdrop = Image.new("RGBA", img.size, RUNTIME_BACKDROP)
    return Image.alpha_composite(backdrop, img)


def delta_layer(before: Image.Image, after: Image.Image) -> Image.Image:
    """Create a replacement-only layer that reproduces ``after`` over ``before``."""
    layer = Image.new("RGBA", after.size, (0, 0, 0, 0))
    before_data = before.load()
    after_data = after.load()
    layer_data = layer.load()
    for y in range(after.height):
        for x in range(after.width):
            if before_data[x, y] != after_data[x, y]:
                r, g, b, _ = after_data[x, y]
                layer_data[x, y] = (r, g, b, 255)
    return layer


def draw_coin(d: ImageDraw.ImageDraw, cx: int, cy: int, r: int) -> None:
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=rgba("gold"), outline=rgba("gold_deep"), width=2)
    d.ellipse((cx - r + 5, cy - r + 5, cx + r - 5, cy + r - 5), outline=(255, 244, 188, 180), width=1)


def draw_basket_icon(d: ImageDraw.ImageDraw, x: int, y: int, s: int, color) -> None:
    d.arc((x, y - s // 3, x + s, y + s // 2), 190, 350, fill=color, width=max(2, s // 9))
    d.polygon([(x + 3, y + s // 3), (x + s - 3, y + s // 3), (x + s - 8, y + s), (x + 8, y + s)], outline=color, fill=None)
    d.line((x + 8, y + s // 2, x + s - 8, y + s // 2), fill=color, width=max(1, s // 12))


def draw_wood_crate(d: ImageDraw.ImageDraw, xy) -> None:
    x0, y0, x1, y1 = xy
    rounded(d, xy, 8, rgba("wood", 238), rgba("gold_deep", 120), 2)
    for y in range(y0 + 16, y1 - 6, 26):
        d.rectangle((x0 + 8, y, x1 - 8, y + 6), fill=rgba("wood_hi", 150))
        d.line((x0 + 8, y + 7, x1 - 8, y + 7), fill=rgba("wood_dark", 140), width=1)
    d.line((x0 + 14, y0 + 10, x0 + 14, y1 - 10), fill=rgba("wood_dark", 150), width=4)
    d.line((x1 - 14, y0 + 10, x1 - 14, y1 - 10), fill=rgba("wood_dark", 150), width=4)


def draw_fish_mound(d: ImageDraw.ImageDraw, xy, count: int) -> None:
    x0, y0, x1, y1 = xy
    width = max(40, x1 - x0 - 48)
    height = max(34, y1 - y0 - 54)
    for i in range(count):
        cx = x0 + 22 + (i * 37) % width
        cy = y0 + 48 + ((i * 23) % height)
        body = (118, 147, 154, 165) if i % 2 else (178, 204, 208, 150)
        d.ellipse((cx, cy, cx + 32, cy + 14), fill=body, outline=(43, 64, 70, 120))
        d.polygon([(cx + 28, cy + 7), (cx + 42, cy), (cx + 42, cy + 14)], fill=(82, 112, 120, 130))
        d.ellipse((cx + 7, cy + 4, cx + 10, cy + 7), fill=(9, 22, 30, 180))


def draw_hanging_scale(d: ImageDraw.ImageDraw, x: int, y: int) -> None:
    d.line((x, y, x, y + 272), fill=rgba("wood_dark", 210), width=4)
    d.ellipse((x - 36, y + 160, x + 36, y + 232), fill=(54, 42, 34, 185), outline=rgba("gold_deep", 185), width=3)
    for angle in range(210, 340, 18):
        rad = math.radians(angle)
        d.line((x, y + 196, x + int(math.cos(rad) * 28), y + 196 + int(math.sin(rad) * 28)), fill=(185, 166, 132, 120), width=1)
    d.line((x, y + 196, x + 18, y + 176), fill=rgba("gold"), width=2)
    d.line((x - 46, y + 264, x + 46, y + 264), fill=rgba("gold_deep"), width=3)
    d.line((x - 38, y + 264, x - 4, y + 230), fill=rgba("gold_deep"), width=2)
    d.line((x + 38, y + 264, x + 4, y + 230), fill=rgba("gold_deep"), width=2)
    d.arc((x - 46, y + 242, x + 46, y + 286), 0, 180, fill=rgba("gold"), width=3)


def draw_lantern(d: ImageDraw.ImageDraw, x: int, y: int) -> None:
    d.line((x + 20, y, x + 20, y + 62), fill=rgba("wood_dark", 200), width=3)
    d.rounded_rectangle((x, y + 58, x + 42, y + 104), radius=6, fill=(247, 207, 119, 140), outline=rgba("gold_deep", 170), width=2)
    d.rectangle((x + 8, y + 64, x + 34, y + 98), fill=(255, 232, 154, 82))
    d.line((x + 10, y + 58, x + 10, y + 104), fill=rgba("wood_dark", 160), width=2)
    d.line((x + 32, y + 58, x + 32, y + 104), fill=rgba("wood_dark", 160), width=2)


def draw_leaf(d: ImageDraw.ImageDraw, origin, length: int, angle: float) -> None:
    ox, oy = origin
    rad = math.radians(angle)
    dx = math.cos(rad) * length
    dy = math.sin(rad) * length
    normal = (-math.sin(rad), math.cos(rad))
    w = 24
    pts = [
        (ox, oy),
        (ox + dx * 0.46 + normal[0] * w, oy + dy * 0.46 + normal[1] * w),
        (ox + dx, oy + dy),
        (ox + dx * 0.46 - normal[0] * w, oy + dy * 0.46 - normal[1] * w),
    ]
    d.polygon(pts, fill=(70, 113, 55, 180), outline=(27, 69, 38, 130))
    d.line((ox, oy, ox + dx, oy + dy), fill=(167, 184, 100, 150), width=2)
    for i in range(1, 5):
        t = i / 5
        cx = ox + dx * t
        cy = oy + dy * t
        spread = w * (1 - abs(t - 0.5) * 1.6)
        d.line((cx, cy, cx + normal[0] * spread, cy + normal[1] * spread), fill=(167, 184, 100, 72), width=1)
        d.line((cx, cy, cx - normal[0] * spread, cy - normal[1] * spread), fill=(167, 184, 100, 72), width=1)


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw_market_background(img)
    flattened = flatten_for_runtime(img)
    background_path = OUT / "market_bg.png"
    if (M2_SOURCE / "market_bg_source.png").exists():
        # M2 authored art owns this slot. Preserve it when regenerating the M1
        # geometric layers; use process_fish_market_m2_assets.py to rebuild it.
        print(f"preserved authored M2 slot {background_path}")
    else:
        flattened.save(background_path)
        print(f"generated {background_path}")

    layers = (
        ("market_header_frame.png", draw_top_frame),
        ("inventory_panel_frame.png", draw_inventory_panel),
        ("detail_panel_frame.png", draw_detail_panel_frame),
        ("ice_tray_hero.png", draw_ice_tray_hero),
        ("cart_panel_frame.png", draw_cart_panel),
    )
    for filename, draw_layer in layers:
        before = flattened
        draw_layer(img)
        flattened = flatten_for_runtime(img)
        layer = delta_layer(before, flattened)
        path = OUT / filename
        if filename == "ice_tray_hero.png" and (M2_SOURCE / "ice_tray_hero_source.png").exists():
            # Keep the authored tray while still drawing the legacy tray into
            # the private M1 chain so downstream geometric deltas stay stable.
            print(f"preserved authored M2 slot {path}")
        else:
            save_png_if_pixels_changed(layer, path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
