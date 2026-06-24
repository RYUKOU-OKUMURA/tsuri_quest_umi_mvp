#!/usr/bin/env python3
from __future__ import annotations

import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "showcase" / "underwater"
ICON_SHEET = OUT_DIR / "fight_icon_sheet.png"


def _rgba(hex_value: str, alpha: int = 255) -> tuple[int, int, int, int]:
    value = hex_value.lstrip("#")
    return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16), alpha)


def _texture(size: tuple[int, int], base: str, seed: int, strength: int = 10) -> Image.Image:
    rng = random.Random(seed)
    w, h = size
    r, g, b, a = _rgba(base)
    pixels = bytearray()
    for y in range(h):
        warm = int((y / max(1, h - 1) - 0.5) * strength)
        for x in range(w):
            grain = rng.randint(-strength, strength)
            speck = rng.randint(-3, 3) if (x * 17 + y * 23) % 19 == 0 else 0
            pixels.extend(
                (
                    max(0, min(255, r + grain + warm + speck)),
                    max(0, min(255, g + grain + warm + speck)),
                    max(0, min(255, b + grain + warm + speck)),
                    a,
                )
            )
    return Image.frombytes("RGBA", size, bytes(pixels))


def _paste_masked(dst: Image.Image, src: Image.Image, mask: Image.Image, xy: tuple[int, int]) -> None:
    dst.alpha_composite(Image.composite(src, Image.new("RGBA", src.size, (0, 0, 0, 0)), mask), xy)


def _rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def _content_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    alpha = image.getchannel("A")
    bbox = alpha.point(lambda value: 255 if value > 18 else 0).getbbox()
    if bbox is None:
        return (0, 0, image.width, image.height)
    x0, y0, x1, y1 = bbox
    pad = max(10, int(max(x1 - x0, y1 - y0) * 0.05))
    return (max(0, x0 - pad), max(0, y0 - pad), min(image.width, x1 + pad), min(image.height, y1 + pad))


def _draw_paper_inset(d: ImageDraw.ImageDraw, box: tuple[int, int, int, int], *, alpha: int = 42) -> None:
    x0, y0, x1, y1 = box
    warm = max(0, min(18, alpha // 3))
    fill = (255 - warm, 250 - warm, 232 - warm, 255)
    d.rounded_rectangle((x0, y0, x1, y1), radius=7, fill=fill, outline=_rgba("#b89b64", 92), width=1)
    d.line((x0 + 12, y0 + 13, x1 - 12, y0 + 13), fill=_rgba("#ffffff", 82), width=1)
    d.line((x0 + 12, y1 - 12, x1 - 12, y1 - 12), fill=_rgba("#7c592d", 46), width=1)


def _draw_inner_shadow(d: ImageDraw.ImageDraw, box: tuple[int, int, int, int], *, radius: int = 7, alpha: int = 38) -> None:
    x0, y0, x1, y1 = box
    d.rounded_rectangle((x0, y0, x1, y1), radius=radius, outline=(0, 0, 0, alpha), width=2)
    d.line((x0 + 10, y0 + 2, x1 - 10, y0 + 2), fill=(255, 255, 255, max(16, alpha)), width=1)
    d.line((x0 + 10, y1 - 2, x1 - 10, y1 - 2), fill=(70, 45, 22, alpha), width=1)


def _draw_paper_slot(d: ImageDraw.ImageDraw, box: tuple[int, int, int, int], *, title: bool = False) -> None:
    x0, y0, x1, y1 = box
    fill = "#fff2d2" if title else "#f7edd6"
    d.rounded_rectangle((x0, y0, x1, y1), radius=7, fill=_rgba(fill), outline=_rgba("#8c6733", 120), width=1)
    d.rounded_rectangle((x0 + 3, y0 + 3, x1 - 3, y1 - 3), radius=5, outline=_rgba("#d8b45d", 80), width=1)
    d.line((x0 + 10, y0 + 8, x1 - 10, y0 + 8), fill=(255, 255, 255, 90), width=1)
    d.line((x0 + 10, y1 - 8, x1 - 10, y1 - 8), fill=(106, 73, 35, 38), width=1)


def _draw_sidebar_icon_recess(image: Image.Image, box: tuple[int, int, int, int], *, seed: int) -> None:
    x0, y0, x1, y1 = box
    w = x1 - x0
    h = y1 - y0
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((x0 + 2, y0 + 3, x1 + 2, y1 + 3), radius=10, fill=(68, 43, 18, 24))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(3)))

    mask = _rounded_mask((w, h), 10)
    texture = _texture((w, h), "#f3e0b2", seed, strength=5)
    _paste_masked(image, texture, mask, (x0, y0))

    d = ImageDraw.Draw(image)
    d.rounded_rectangle((x0, y0, x1, y1), radius=10, outline=_rgba("#8b6733", 64), width=1)
    d.rounded_rectangle((x0 + 6, y0 + 6, x1 - 6, y1 - 6), radius=7, outline=_rgba("#e4c371", 48), width=1)
    d.ellipse((x0 + 15, y1 - 27, x1 - 15, y1 - 12), fill=(214, 193, 151, 66))
    d.line((x0 + 14, y0 + 11, x1 - 14, y0 + 11), fill=(255, 255, 255, 56), width=1)


def _draw_sidebar_text_well(image: Image.Image, box: tuple[int, int, int, int], *, seed: int) -> None:
    x0, y0, x1, y1 = box
    w = x1 - x0
    h = y1 - y0
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((x0 + 2, y0 + 3, x1 + 2, y1 + 3), radius=10, fill=(74, 47, 20, 16))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(4)))

    mask = _rounded_mask((w, h), 10)
    texture = _texture((w, h), "#fff0ce", seed, strength=6)
    td = ImageDraw.Draw(texture)
    for i in range(5):
        alpha = 6 - i
        td.line((5 + i, 10, 5 + i, h - 10), fill=(127, 87, 38, max(0, alpha)), width=1)
        td.line((w - 6 - i, 10, w - 6 - i, h - 10), fill=(255, 255, 255, max(0, alpha)), width=1)
    _paste_masked(image, texture, mask, (x0, y0))

    d = ImageDraw.Draw(image)
    d.rounded_rectangle((x0, y0, x1, y1), radius=10, outline=_rgba("#a98242", 38), width=1)
    d.line((x0 + 16, y0 + 12, x1 - 16, y0 + 12), fill=(255, 255, 255, 54), width=1)
    d.line((x0 + 18, y1 - 12, x1 - 18, y1 - 12), fill=_rgba("#80552a", 16), width=1)
    d.line((x0 + 18, y0 + 36, x1 - 72, y0 + 36), fill=_rgba("#b89b64", 14), width=1)
    _draw_corner_brackets(d, (x0 + 2, y0 + 2, x1 - 2, y1 - 2), length=13, inset=7, color="#a77d3b", alpha=28, width=1)


def _draw_card(
    image: Image.Image,
    box: tuple[int, int, int, int],
    fill: str,
    *,
    radius: int = 16,
    border: str = "#5b3f1f",
    inner: str = "#d7b765",
    seed: int = 1,
    texture_strength: int = 8,
    shadow: bool = True,
) -> None:
    x0, y0, x1, y1 = box
    w = x1 - x0
    h = y1 - y0
    if shadow:
        shadow_layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
        sd = ImageDraw.Draw(shadow_layer)
        sd.rounded_rectangle((x0 + 5, y0 + 7, x1 + 5, y1 + 7), radius=radius, fill=(0, 0, 0, 86))
        image.alpha_composite(shadow_layer.filter(ImageFilter.GaussianBlur(5)))

    mask = _rounded_mask((w, h), radius)
    texture = _texture((w, h), fill, seed, texture_strength)
    _paste_masked(image, texture, mask, (x0, y0))

    d = ImageDraw.Draw(image)
    d.rounded_rectangle((x0, y0, x1, y1), radius=radius, outline=_rgba("#1f1710"), width=4)
    d.rounded_rectangle((x0 + 4, y0 + 4, x1 - 4, y1 - 4), radius=max(2, radius - 4), outline=_rgba(border), width=4)
    d.rounded_rectangle((x0 + 10, y0 + 10, x1 - 10, y1 - 10), radius=max(2, radius - 8), outline=_rgba(inner, 160), width=2)
    d.line((x0 + 18, y0 + 16, x1 - 18, y0 + 16), fill=(255, 248, 218, 120), width=2)
    d.line((x0 + 18, y1 - 15, x1 - 18, y1 - 15), fill=(95, 58, 24, 80), width=2)
    for cx, cy in ((x0 + 12, y0 + 12), (x1 - 12, y0 + 12), (x0 + 12, y1 - 12), (x1 - 12, y1 - 12)):
        d.ellipse((cx - 4, cy - 4, cx + 4, cy + 4), fill=_rgba(inner), outline=_rgba("#3e2b16"))


def _draw_clean_card(
    image: Image.Image,
    box: tuple[int, int, int, int],
    fill: str,
    *,
    radius: int = 10,
    border: str = "#8a622e",
    inner: str = "#d2b06b",
    seed: int = 1,
    texture_strength: int = 6,
    shadow: bool = True,
) -> None:
    x0, y0, x1, y1 = box
    w = x1 - x0
    h = y1 - y0
    if shadow:
        shadow_layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
        sd = ImageDraw.Draw(shadow_layer)
        sd.rounded_rectangle((x0 + 3, y0 + 4, x1 + 3, y1 + 4), radius=radius, fill=(0, 0, 0, 54))
        image.alpha_composite(shadow_layer.filter(ImageFilter.GaussianBlur(4)))

    mask = _rounded_mask((w, h), radius)
    texture = _texture((w, h), fill, seed, texture_strength)
    _paste_masked(image, texture, mask, (x0, y0))

    d = ImageDraw.Draw(image)
    d.rounded_rectangle((x0, y0, x1, y1), radius=radius, outline=_rgba("#4a3218"), width=3)
    d.rounded_rectangle((x0 + 5, y0 + 5, x1 - 5, y1 - 5), radius=max(2, radius - 5), outline=_rgba(border, 185), width=2)
    d.rounded_rectangle((x0 + 10, y0 + 10, x1 - 10, y1 - 10), radius=max(2, radius - 8), outline=_rgba(inner, 105), width=1)
    for inset, alpha in ((14, 18), (20, 10)):
        d.rounded_rectangle(
            (x0 + inset, y0 + inset, x1 - inset, y1 - inset),
            radius=max(2, radius - 8),
            outline=_rgba("#6f4e28", alpha),
            width=1,
        )
    d.line((x0 + 16, y0 + 14, x1 - 16, y0 + 14), fill=(255, 246, 215, 88), width=1)
    d.line((x0 + 16, y1 - 13, x1 - 16, y1 - 13), fill=(98, 67, 36, 42), width=1)


def _draw_navy_card(
    image: Image.Image,
    box: tuple[int, int, int, int],
    *,
    radius: int = 16,
    seed: int = 7,
    shadow: bool = True,
) -> None:
    _draw_clean_card(image, box, "#113654", radius=radius, border="#9f7a3d", inner="#dfbf73", seed=seed, shadow=shadow)
    x0, y0, x1, y1 = box
    overlay = Image.new("RGBA", (x1 - x0, y1 - y0), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    for i in range(5):
        y = int((i + 1) * overlay.height / 11)
        od.line((18, y, overlay.width - 18, y), fill=(92, 178, 214, 10), width=1)
    image.alpha_composite(overlay, (x0, y0))


def _draw_outer_frame(image: Image.Image, box: tuple[int, int, int, int], *, radius: int = 18) -> None:
    x0, y0, x1, y1 = box
    d = ImageDraw.Draw(image)
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((x0 + 4, y0 + 6, x1 + 4, y1 + 6), radius=radius, fill=(0, 0, 0, 82))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(6)))
    d.rounded_rectangle((x0, y0, x1, y1), radius=radius, fill=_rgba("#08213a", 230), outline=_rgba("#1c1209"), width=3)
    d.rounded_rectangle((x0 + 5, y0 + 5, x1 - 5, y1 - 5), radius=radius - 4, outline=_rgba("#d8b45d", 230), width=3)
    d.rounded_rectangle((x0 + 11, y0 + 11, x1 - 11, y1 - 11), radius=radius - 8, outline=_rgba("#6e4b22", 180), width=2)
    d.line((x0 + 22, y0 + 17, x1 - 22, y0 + 17), fill=(255, 240, 190, 70), width=1)
    d.line((x0 + 22, y1 - 17, x1 - 22, y1 - 17), fill=(0, 0, 0, 70), width=1)


def _draw_icon_well(d: ImageDraw.ImageDraw, center: tuple[int, int], radius: int, pale: bool = True) -> None:
    cx, cy = center
    fill = "#f4dfaa" if pale else "#0d2437"
    d.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill=_rgba(fill), outline=_rgba("#6d4b23"), width=3)
    d.ellipse((cx - radius + 6, cy - radius + 6, cx + radius - 6, cy + radius - 6), outline=_rgba("#e0bd62", 150), width=2)


def _draw_corner_brackets(
    d: ImageDraw.ImageDraw,
    box: tuple[int, int, int, int],
    *,
    length: int = 34,
    inset: int = 10,
    color: str = "#e0bd62",
    alpha: int = 145,
    width: int = 2,
) -> None:
    x0, y0, x1, y1 = box
    points = (
        ((x0 + inset, y0 + inset), (x0 + inset + length, y0 + inset)),
        ((x0 + inset, y0 + inset), (x0 + inset, y0 + inset + length)),
        ((x1 - inset, y0 + inset), (x1 - inset - length, y0 + inset)),
        ((x1 - inset, y0 + inset), (x1 - inset, y0 + inset + length)),
        ((x0 + inset, y1 - inset), (x0 + inset + length, y1 - inset)),
        ((x0 + inset, y1 - inset), (x0 + inset, y1 - inset - length)),
        ((x1 - inset, y1 - inset), (x1 - inset - length, y1 - inset)),
        ((x1 - inset, y1 - inset), (x1 - inset, y1 - inset - length)),
    )
    for start, end in points:
        d.line((*start, *end), fill=_rgba(color, alpha), width=width)


def create_top_status_frame() -> None:
    w, h = 1774, 248
    image = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(image)
    y0, y1 = 22, 222
    split1 = int(w * 0.245)
    split2 = int(w * 0.555)
    split3 = int(w * 0.825)
    slots = [
        (8, y0, split1 - 4, y1, "#f4ead5"),
        (split1 + 4, y0, split2 - 4, y1, "#f3e8d0"),
        (split2 + 4, y0, split3 - 4, y1, "#f5ead4"),
        (split3 + 4, y0, w - 8, y1, "#123554"),
    ]
    for i, (x0, sy0, x1, sy1, fill) in enumerate(slots):
        if i == 3:
            _draw_navy_card(image, (x0, sy0, x1, sy1), radius=12, seed=30 + i)
            d.rounded_rectangle(
                (x0 + 18, sy0 + 22, x1 - 18, sy1 - 22),
                radius=8,
                outline=_rgba("#6dc8ee", 34),
                width=1,
            )
            d.line((x0 + 36, sy0 + 62, x1 - 36, sy0 + 62), fill=_rgba("#e0bd62", 82), width=1)
            _draw_corner_brackets(d, (x0 + 10, sy0 + 10, x1 - 10, sy1 - 10), length=32, inset=10, color="#e0bd62", alpha=105, width=2)
        else:
            _draw_card(image, (x0, sy0, x1, sy1), fill, radius=12, seed=10 + i, texture_strength=5)
            body = (x0 + 20, sy0 + 20, x1 - 20, sy1 - 20)
            d.rounded_rectangle(body, radius=7, outline=_rgba("#8c6733", 36), width=1)
            d.line((body[0] + 18, body[1] + 13, body[2] - 18, body[1] + 13), fill=_rgba("#ffffff", 42), width=1)
            _draw_corner_brackets(d, (x0 + 8, sy0 + 8, x1 - 8, sy1 - 8), length=28, inset=10, color="#8c6733", alpha=98, width=1)
            if i in (1, 2):
                d.line((x0 + 132, sy0 + 42, x0 + 132, sy1 - 42), fill=_rgba("#b8934d", 74), width=2)
                d.line((x0 + 138, sy0 + 48, x0 + 138, sy1 - 48), fill=_rgba("#ffffff", 42), width=1)
    image.save(OUT_DIR / "top_status_frame.png")


def _create_sidebar_card_icon(icon_index: int, filename: str, *, seed: int) -> None:
    if not ICON_SHEET.exists():
        return
    sheet = Image.open(ICON_SHEET).convert("RGBA")
    cell_w = sheet.width // 3
    cell_h = sheet.height // 3
    col = icon_index % 3
    row = icon_index // 3
    raw = sheet.crop((col * cell_w, row * cell_h, (col + 1) * cell_w, (row + 1) * cell_h))
    crop = raw.crop(_content_bbox(raw))

    canvas = _texture((168, 150), "#f3e7cd", seed, strength=5)
    d = ImageDraw.Draw(canvas)
    d.rounded_rectangle((3, 3, 164, 146), radius=14, outline=_rgba("#8c6733", 190), width=3)
    d.rounded_rectangle((11, 11, 156, 138), radius=10, outline=_rgba("#d8b45d", 112), width=1)
    d.ellipse((38, 104, 130, 128), fill=(216, 199, 160, 255))

    max_w = 116
    max_h = 102
    scale = min(max_w / crop.width, max_h / crop.height)
    resized = crop.resize((round(crop.width * scale), round(crop.height * scale)), Image.Resampling.LANCZOS)
    # The source icon sheet is intentionally ornate; card icons are calmer and
    # slightly translucent so text remains the focus.
    alpha = resized.getchannel("A").point(lambda value: int(value * 0.86))
    resized.putalpha(alpha)
    x = (canvas.width - resized.width) // 2
    y = (canvas.height - resized.height) // 2 - 4
    canvas.alpha_composite(resized, (x, y))
    canvas.save(OUT_DIR / filename)


def create_sidebar_card_icons() -> None:
    _create_sidebar_card_icon(7, "fight_action_card_icon.png", seed=90)
    _create_sidebar_card_icon(8, "fight_tackle_card_icon.png", seed=91)


def create_sidebar_frame() -> None:
    w, h = 678, 1024
    image = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(image)
    _draw_outer_frame(image, (7, 7, w - 8, h - 8), radius=18)

    header = (24, 22, w - 24, 112)
    fish = (28, 126, w - 28, 600)
    action = (24, 618, w - 24, 812)
    tackle = (24, 830, w - 24, h - 24)
    action_body = (42, 662, w - 42, 798)
    tackle_body = (42, 872, w - 42, h - 40)

    _draw_clean_card(
        image,
        header,
        "#075d47",
        radius=14,
        border="#0a342c",
        inner="#e1be65",
        seed=80,
        texture_strength=7,
        shadow=False,
    )
    d.line((header[0] + 24, header[3] - 15, header[2] - 24, header[3] - 15), fill=_rgba("#063626", 110), width=3)
    d.line((header[0] + 24, header[3] - 10, header[2] - 24, header[3] - 10), fill=_rgba("#f4d27c", 70), width=1)

    _draw_clean_card(image, fish, "#f1e4c7", radius=10, border="#8c6733", inner="#d2aa58", seed=81, texture_strength=7)
    name_band = (fish[0] + 34, fish[1] + 24, fish[2] - 34, fish[1] + 84)
    d.rounded_rectangle(name_band, radius=5, fill=(255, 243, 215, 255), outline=_rgba("#b89b64", 92), width=1)
    d.line((name_band[0] + 16, name_band[1] + 15, name_band[2] - 16, name_band[1] + 15), fill=_rgba("#ffffff", 82), width=1)
    portrait_mat = (fish[0] + 42, fish[1] + 96, fish[2] - 42, fish[1] + 348)
    d.rounded_rectangle(portrait_mat, radius=8, fill=(255, 251, 233, 255), outline=_rgba("#b89b64", 74), width=1)
    for y in range(portrait_mat[1] + 42, portrait_mat[3], 56):
        d.line((portrait_mat[0] + 22, y, portrait_mat[2] - 22, y), fill=_rgba("#c8ad76", 16), width=1)
    for y in (fish[1] + 86,):
        d.line((fish[0] + 38, y, fish[2] - 38, y), fill=_rgba("#b89b64", 58), width=1)
    _draw_corner_brackets(d, fish, length=30, inset=18, color="#a77d3b", alpha=95, width=1)

    _draw_navy_card(image, action, radius=12, seed=82)
    _draw_clean_card(image, action_body, "#f2e5cb", radius=8, border="#8c6733", inner="#d8b45d", seed=83, texture_strength=5)
    _draw_navy_card(image, tackle, radius=12, seed=84)
    _draw_clean_card(image, tackle_body, "#f2e5cb", radius=8, border="#8c6733", inner="#d8b45d", seed=85, texture_strength=5)

    for panel_index, (panel, body, icon_side) in enumerate(((action, action_body, "left"), (tackle, tackle_body, "right"))):
        d.line((panel[0] + 26, panel[1] + 39, panel[2] - 26, panel[1] + 39), fill=_rgba("#e0bd62", 104), width=2)
        d.line((panel[0] + 28, panel[1] + 44, panel[2] - 28, panel[1] + 44), fill=_rgba("#07121b", 72), width=1)
        if icon_side == "left":
            icon_well = (body[0] + 18, body[1] + 27, body[0] + 78, body[3] - 27)
            text_well = (body[0] + 88, body[1] + 14, body[2] - 16, body[3] - 14)
        else:
            icon_well = (body[2] - 78, body[1] + 27, body[2] - 18, body[3] - 27)
            text_well = (body[0] + 16, body[1] + 14, body[2] - 88, body[3] - 14)
        _draw_sidebar_icon_recess(image, icon_well, seed=130 + panel_index)
        _draw_sidebar_text_well(image, text_well, seed=140 + panel_index)
        _draw_corner_brackets(d, body, length=22, inset=9, color="#a77d3b", alpha=88, width=1)

    # Sparse corner accents only. Heavy rivets made the frame read as generated/debug UI.
    for cx, cy in (
        (28, 28),
        (w - 28, 28),
        (28, h - 28),
        (w - 28, h - 28),
    ):
        d.ellipse((cx - 7, cy - 7, cx + 7, cy + 7), fill=_rgba("#112031"), outline=_rgba("#e1be65"), width=2)
        d.ellipse((cx - 2, cy - 2, cx + 2, cy + 2), fill=_rgba("#fff1b7", 210))

    image.save(OUT_DIR / "sidebar_frame.png")


def _draw_bar_well(image: Image.Image, box: tuple[int, int, int, int]) -> None:
    x0, y0, x1, y1 = box
    d = ImageDraw.Draw(image)
    d.rounded_rectangle((x0, y0, x1, y1), radius=8, fill=_rgba("#07121b", 235), outline=_rgba("#22384c", 190), width=2)
    for x in range(x0 + 44, x1, 92):
        d.line((x, y0 + 7, x, y1 - 7), fill=(255, 255, 255, 7), width=1)
    d.line((x0 + 7, y0 + 5, x1 - 7, y0 + 5), fill=(255, 255, 255, 26), width=1)


def create_fight_hud_frame() -> None:
    w, h = 2048, 456
    image = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(image)

    top = (int(w * 0.014), int(h * 0.065), int(w * 0.986), int(h * 0.520))
    bottom = (int(w * 0.014), int(h * 0.552), int(w * 0.986), int(h * 0.940))
    gap = 20
    depth_w = int(w * 0.210)
    left_w = int((top[2] - top[0] - depth_w - gap * 2) * 0.5)
    right_w = top[2] - top[0] - depth_w - gap * 2 - left_w
    tension = (top[0], top[1], top[0] + left_w, top[3])
    depth = (tension[2] + gap, top[1], tension[2] + gap + depth_w, top[3])
    stamina = (depth[2] + gap, top[1], depth[2] + gap + right_w, top[3])

    _draw_clean_card(
        image,
        top,
        "#0b263e",
        radius=12,
        border="#8f6f37",
        inner="#c59a4c",
        seed=40,
        texture_strength=6,
        shadow=True,
    )

    # Keep the upper board as one piece, but let the central depth plate interrupt
    # the trim so it feels fitted into the console instead of drawn on top.
    for y, color, width_px in (
        (top[1] + 54, _rgba("#e0bd62", 60), 2),
        (top[3] - 24, (255, 255, 255, 24), 1),
    ):
        d.line((top[0] + 30, y, depth[0] - 34, y), fill=color, width=width_px)
        d.line((depth[2] + 34, y, top[2] - 30, y), fill=color, width=width_px)

    left_socket = [
        (depth[0] - 42, depth[1] + 20),
        (depth[0] + 30, depth[1] + 20),
        (depth[0] + 80, depth[3] - 14),
        (depth[0] + 8, depth[3] - 14),
    ]
    right_socket = [
        (depth[2] - 30, depth[1] + 20),
        (depth[2] + 42, depth[1] + 20),
        (depth[2] - 8, depth[3] - 14),
        (depth[2] - 80, depth[3] - 14),
    ]
    d.polygon(left_socket, fill=_rgba("#061421", 205))
    d.polygon(right_socket, fill=_rgba("#061421", 205))

    plate_shadow = [
        (depth[0] + 30, depth[1] + 18),
        (depth[2] - 30, depth[1] + 18),
        (depth[2] - 70, depth[3] - 8),
        (depth[0] + 70, depth[3] - 8),
    ]
    d.polygon(plate_shadow, fill=(0, 0, 0, 72))
    plate = [
        (depth[0] + 24, depth[1] + 12),
        (depth[2] - 24, depth[1] + 12),
        (depth[2] - 70, depth[3] - 16),
        (depth[0] + 70, depth[3] - 16),
    ]
    d.polygon(plate, fill=_rgba("#123b61", 238))
    for inset, alpha, width_px in ((0, 145, 3), (10, 62, 2)):
        d.line(
            (depth[0] + 24 + inset, depth[1] + 12, depth[0] + 70 + inset, depth[3] - 16),
            fill=_rgba("#e0bd62", alpha),
            width=width_px,
        )
        d.line(
            (depth[2] - 24 - inset, depth[1] + 12, depth[2] - 70 - inset, depth[3] - 16),
            fill=_rgba("#e0bd62", alpha),
            width=width_px,
        )
    d.line((depth[0] + 52, depth[1] + 26, depth[2] - 52, depth[1] + 26), fill=_rgba("#fff1a8", 70), width=2)
    d.line((depth[0] + 76, depth[3] - 26, depth[2] - 76, depth[3] - 26), fill=(255, 255, 255, 32), width=1)

    title_tab = (depth[0] + 72, depth[1] + 46, depth[2] - 72, depth[1] + 94)
    d.rounded_rectangle(title_tab, radius=8, fill=_rgba("#081f35", 110), outline=_rgba("#6fd6ff", 28), width=1)
    value_plaque = (depth[0] + 84, depth[1] + 126, depth[2] - 84, depth[3] - 30)
    d.rounded_rectangle(value_plaque, radius=8, fill=_rgba("#071d32", 170), outline=_rgba("#cfa45a", 78), width=2)
    for cx, cy in (
        (depth[0] + 54, depth[1] + 34),
        (depth[2] - 54, depth[1] + 34),
        (depth[0] + 84, depth[3] - 32),
        (depth[2] - 84, depth[3] - 32),
    ):
        d.ellipse((cx - 4, cy - 4, cx + 4, cy + 4), fill=_rgba("#d8b45d", 150), outline=_rgba("#07121b", 160))

    _draw_bar_well(image, (tension[0] + 44, tension[1] + 88, tension[2] - 56, tension[1] + 142))
    _draw_bar_well(image, (stamina[0] + 44, stamina[1] + 88, stamina[2] - 48, stamina[1] + 142))

    bait_w = int((bottom[2] - bottom[0]) * 0.265)
    menu_w = int((bottom[2] - bottom[0]) * 0.190)
    hint_w = bottom[2] - bottom[0] - bait_w - menu_w - gap * 2
    bait = (bottom[0], bottom[1], bottom[0] + bait_w, bottom[3])
    hint = (bait[2] + gap, bottom[1], bait[2] + gap + hint_w, bottom[3])
    menu = (hint[2] + gap, bottom[1], bottom[2], bottom[3])

    _draw_navy_card(image, bottom, radius=12, seed=50, shadow=True)
    inner_y0 = bottom[1] + 10
    inner_y1 = bottom[3] - 10
    bait_panel = (bait[0] + 10, inner_y0, bait[2] - 4, inner_y1)
    hint_panel = (hint[0] + 4, inner_y0, hint[2] - 4, inner_y1)
    menu_panel = (menu[0] + 4, inner_y0, menu[2] - 10, inner_y1)
    for panel in (bait_panel, hint_panel, menu_panel):
        px0, py0, px1, py1 = panel
        d.rounded_rectangle((px0 + 3, py0 + 5, px1 + 3, py1 + 5), radius=9, fill=(0, 0, 0, 48))
    _draw_clean_card(
        image,
        bait_panel,
        "#f3e6cc",
        radius=8,
        border="#8c6733",
        inner="#d8b45d",
        seed=51,
        texture_strength=5,
        shadow=False,
    )
    _draw_paper_slot(d, (bait_panel[0] + 14, bait_panel[1] + 12, bait_panel[2] - 14, bait_panel[1] + 44), title=True)
    _draw_paper_slot(d, (bait_panel[0] + 76, bait_panel[1] + 55, bait_panel[2] - 18, bait_panel[3] - 16))
    _draw_inner_shadow(d, (bait_panel[0] + 76, bait_panel[1] + 55, bait_panel[2] - 18, bait_panel[3] - 16), alpha=28)
    _draw_clean_card(
        image,
        hint_panel,
        "#f2e4c8",
        radius=8,
        border="#8c6733",
        inner="#d8b45d",
        seed=52,
        texture_strength=5,
        shadow=False,
    )
    _draw_paper_slot(d, (hint_panel[0] + 14, hint_panel[1] + 12, hint_panel[2] - 14, hint_panel[1] + 44), title=True)
    slot_gap = 20
    slot_x0 = hint[0] + 38
    slot_y0 = hint[1] + 68
    slot_w = int((hint[2] - hint[0] - 80 - slot_gap * 2) / 3)
    slot_h = 96
    for i in range(3):
        x = slot_x0 + i * (slot_w + slot_gap)
        _draw_paper_slot(d, (x, slot_y0, x + slot_w, slot_y0 + slot_h))
        _draw_inner_shadow(d, (x, slot_y0, x + slot_w, slot_y0 + slot_h), alpha=24)
    _draw_clean_card(
        image,
        menu_panel,
        "#0e3a5b",
        radius=8,
        border="#9f7a3d",
        inner="#dfbf73",
        seed=53,
        texture_strength=5,
        shadow=False,
    )
    menu_row_pad = 24
    menu_row_h = 50
    for row_y in (menu_panel[1] + 34, menu_panel[1] + 96):
        d.rounded_rectangle(
            (menu_panel[0] + menu_row_pad, row_y, menu_panel[2] - menu_row_pad, row_y + menu_row_h),
            radius=6,
            fill=_rgba("#08243a", 185),
            outline=_rgba("#d8b45d", 90),
            width=1,
        )
        d.line((menu_panel[0] + menu_row_pad + 12, row_y + 8, menu_panel[2] - menu_row_pad - 12, row_y + 8), fill=(255, 255, 255, 26), width=1)
    _draw_icon_well(d, (bait[0] + 80, (bait[1] + bait[3]) // 2), 30, pale=True)

    # Shared separators: enough structure without returning to the previous grid-like skin.
    for x, slant in ((depth[0] - gap // 2, 18), (depth[2] + gap // 2, -18)):
        d.line((x + slant, top[1] + 22, x - slant, top[3] - 22), fill=_rgba("#b88b3f", 94), width=3)
        d.line((x + slant + (6 if slant > 0 else -6), top[1] + 22, x - slant + (6 if slant > 0 else -6), top[3] - 22), fill=_rgba("#07121b", 100), width=2)
    for x in (hint[0] - gap // 2, menu[0] - gap // 2):
        d.line((x, bottom[1] + 16, x, bottom[3] - 16), fill=_rgba("#b88b3f", 90), width=2)

    image.save(OUT_DIR / "fight_hud_frame.png")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    create_sidebar_card_icons()
    create_sidebar_frame()
    create_top_status_frame()
    create_fight_hud_frame()
    print(f"generated clean UI frame assets in {OUT_DIR}")


if __name__ == "__main__":
    main()
