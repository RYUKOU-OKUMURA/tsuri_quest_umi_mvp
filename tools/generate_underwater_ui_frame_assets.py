#!/usr/bin/env python3
from __future__ import annotations

import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "showcase" / "underwater"
ICON_SHEET = OUT_DIR / "fight_icon_sheet.png"
REFERENCE_MOCKUP = ROOT / "reference" / "02_underwater_fight_mockup.png"

REFERENCE_SIDEBAR_ICON_CROPS = {
    "fight_action_card_icon.png": (1266, 602, 1335, 704),
    "fight_tackle_card_icon.png": (1530, 802, 1642, 908),
}


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


def _reference_paper_texture(size: tuple[int, int], base: str, seed: int, strength: int = 5) -> Image.Image:
    texture = _texture(size, base, seed, strength)
    if not REFERENCE_MOCKUP.exists():
        return texture

    source = Image.open(REFERENCE_MOCKUP).convert("RGB")
    paper_crops = [
        (18, 34, 235, 112),
        (252, 34, 540, 112),
        (560, 34, 802, 112),
        (1268, 126, 1650, 590),
        (20, 730, 365, 928),
    ]
    rng = random.Random(seed + 173)
    crop = source.crop(paper_crops[seed % len(paper_crops)])
    scale = max(size[0] / crop.width, size[1] / crop.height)
    resized = crop.resize((round(crop.width * scale), round(crop.height * scale)), Image.Resampling.BICUBIC)
    if resized.width > size[0] or resized.height > size[1]:
        x = rng.randint(0, max(0, resized.width - size[0]))
        y = rng.randint(0, max(0, resized.height - size[1]))
        resized = resized.crop((x, y, x + size[0], y + size[1]))
    resized = resized.resize(size, Image.Resampling.BICUBIC).filter(ImageFilter.GaussianBlur(10.0))

    br, bg, bb, _ = _rgba(base)
    pixels = bytearray()
    for r, g, b in resized.getdata():
        luminance = (r * 0.30 + g * 0.59 + b * 0.11)
        warm = (r - b) * 0.018
        delta = (luminance - 205.0) * 0.16
        pixels.extend(
            (
                max(0, min(255, int(br + delta + warm))),
                max(0, min(255, int(bg + delta * 0.92 + warm * 0.35))),
                max(0, min(255, int(bb + delta * 0.72))),
                255,
            )
        )
    reference_variation = Image.frombytes("RGBA", size, bytes(pixels))
    return Image.blend(texture, reference_variation, 0.36)


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


def _transparentize_paper_cutout(crop: Image.Image) -> Image.Image:
    image = crop.convert("RGBA")
    pixels = image.load()
    paper_mask = Image.new("L", image.size, 0)
    mask_pixels = paper_mask.load()

    def is_paper_like(x: int, y: int) -> bool:
        r, g, b, a = pixels[x, y]
        if a <= 0:
            return False
        saturation = max(r, g, b) - min(r, g, b)
        return r > 170 and g > 145 and b > 100 and r >= g >= b - 10 and saturation < 105

    stack: list[tuple[int, int]] = []
    for x in range(image.width):
        stack.extend([(x, 0), (x, image.height - 1)])
    for y in range(image.height):
        stack.extend([(0, y), (image.width - 1, y)])
    while stack:
        x, y = stack.pop()
        if x < 0 or y < 0 or x >= image.width or y >= image.height:
            continue
        if mask_pixels[x, y] != 0 or not is_paper_like(x, y):
            continue
        mask_pixels[x, y] = 255
        stack.extend([(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)])

    softened = paper_mask.filter(ImageFilter.GaussianBlur(1.1))
    softened_pixels = softened.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            remove = softened_pixels[x, y]
            pixels[x, y] = (r, g, b, max(0, int(a * (255 - remove) / 255)))
    bbox = _content_bbox(image)
    return image.crop(bbox)


def _reference_sidebar_icon(filename: str, canvas_size: tuple[int, int]) -> Image.Image | None:
    if not REFERENCE_MOCKUP.exists() or filename not in REFERENCE_SIDEBAR_ICON_CROPS:
        return None
    source = Image.open(REFERENCE_MOCKUP).convert("RGBA")
    cutout = _transparentize_paper_cutout(source.crop(REFERENCE_SIDEBAR_ICON_CROPS[filename]))
    canvas = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    max_w = int(canvas.width * 0.86)
    max_h = int(canvas.height * 0.88)
    scale = min(max_w / cutout.width, max_h / cutout.height)
    resized = cutout.resize((round(cutout.width * scale), round(cutout.height * scale)), Image.Resampling.LANCZOS)
    x = (canvas.width - resized.width) // 2
    y = (canvas.height - resized.height) // 2
    shadow = Image.new("RGBA", resized.size, (0, 0, 0, 0))
    shadow.putalpha(resized.getchannel("A").point(lambda value: int(value * 0.18)))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(2.0)), (x + 3, y + 4))
    canvas.alpha_composite(resized, (x, y))
    return canvas


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
    fill = "#f7e5c1" if title else "#f1e1c2"
    d.rounded_rectangle((x0, y0, x1, y1), radius=7, fill=_rgba(fill), outline=_rgba("#8c6733", 120), width=1)
    d.rounded_rectangle((x0 + 3, y0 + 3, x1 - 3, y1 - 3), radius=5, outline=_rgba("#d8b45d", 80), width=1)
    d.rounded_rectangle((x0 + 6, y0 + 6, x1 - 6, y1 - 6), radius=4, outline=_rgba("#6f4a21", 20), width=1)
    d.line((x0 + 10, y0 + 8, x1 - 10, y0 + 8), fill=(255, 255, 255, 90), width=1)
    d.line((x0 + 10, y1 - 8, x1 - 10, y1 - 8), fill=(106, 73, 35, 38), width=1)
    d.line((x0 + 7, y0 + 12, x0 + 7, y1 - 12), fill=_rgba("#6f4a21", 24), width=1)
    d.line((x1 - 7, y0 + 12, x1 - 7, y1 - 12), fill=(255, 255, 255, 34), width=1)
    for inset, alpha in ((12, 22), (20, 12)):
        d.arc((x0 + inset, y0 + inset, x0 + inset + 24, y0 + inset + 24), 180, 270, fill=_rgba("#6f4a21", alpha), width=1)
        d.arc((x1 - inset - 24, y1 - inset - 24, x1 - inset, y1 - inset), 0, 90, fill=_rgba("#6f4a21", alpha), width=1)


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
    outer_alpha: int = 255,
    outer_width: int = 3,
    border_alpha: int = 185,
    border_width: int = 2,
    inner_alpha: int = 105,
    detail_alpha_scale: float = 1.0,
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
    d.rounded_rectangle((x0, y0, x1, y1), radius=radius, outline=_rgba("#4a3218", outer_alpha), width=outer_width)
    d.rounded_rectangle((x0 + 5, y0 + 5, x1 - 5, y1 - 5), radius=max(2, radius - 5), outline=_rgba(border, border_alpha), width=border_width)
    d.rounded_rectangle((x0 + 10, y0 + 10, x1 - 10, y1 - 10), radius=max(2, radius - 8), outline=_rgba(inner, inner_alpha), width=1)
    for inset, alpha in ((14, 18), (20, 10)):
        d.rounded_rectangle(
            (x0 + inset, y0 + inset, x1 - inset, y1 - inset),
            radius=max(2, radius - 8),
            outline=_rgba("#6f4e28", int(alpha * detail_alpha_scale)),
            width=1,
        )
    d.line((x0 + 16, y0 + 14, x1 - 16, y0 + 14), fill=(255, 246, 215, int(88 * detail_alpha_scale)), width=1)
    d.line((x0 + 16, y1 - 13, x1 - 16, y1 - 13), fill=(98, 67, 36, int(42 * detail_alpha_scale)), width=1)


def _draw_navy_card(
    image: Image.Image,
    box: tuple[int, int, int, int],
    *,
    radius: int = 16,
    seed: int = 7,
    shadow: bool = True,
    outer_alpha: int = 255,
    outer_width: int = 3,
    border_alpha: int = 185,
    border_width: int = 2,
    inner_alpha: int = 105,
    detail_alpha_scale: float = 1.0,
) -> None:
    _draw_clean_card(
        image,
        box,
        "#113654",
        radius=radius,
        border="#9f7a3d",
        inner="#dfbf73",
        seed=seed,
        shadow=shadow,
        outer_alpha=outer_alpha,
        outer_width=outer_width,
        border_alpha=border_alpha,
        border_width=border_width,
        inner_alpha=inner_alpha,
        detail_alpha_scale=detail_alpha_scale,
    )
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
    sd.rounded_rectangle((x0 + 2, y0 + 4, x1 + 2, y1 + 4), radius=radius, fill=(0, 0, 0, 18))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(4)))
    d.rounded_rectangle((x0, y0, x1, y1), radius=radius, fill=_rgba("#071a2d", 132), outline=_rgba("#1c1209", 82), width=1)
    d.rounded_rectangle((x0 + 4, y0 + 4, x1 - 4, y1 - 4), radius=radius - 4, outline=_rgba("#d8b45d", 62), width=1)
    d.rounded_rectangle((x0 + 8, y0 + 8, x1 - 8, y1 - 8), radius=radius - 8, outline=_rgba("#6e4b22", 28), width=1)
    d.line((x0 + 22, y0 + 14, x1 - 22, y0 + 14), fill=(255, 240, 190, 13), width=1)
    d.line((x0 + 22, y1 - 14, x1 - 22, y1 - 14), fill=(0, 0, 0, 12), width=1)


def _draw_top_status_paper_card(
    image: Image.Image,
    box: tuple[int, int, int, int],
    fill: str,
    *,
    seed: int,
) -> None:
    x0, y0, x1, y1 = box
    w = x1 - x0
    h = y1 - y0
    radius = 10
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((x0 + 3, y0 + 4, x1 + 3, y1 + 4), radius=radius, fill=(0, 0, 0, 20))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(3)))

    mask = _rounded_mask((w, h), radius)
    texture = _reference_paper_texture((w, h), fill, seed, strength=6)
    _paste_masked(image, texture, mask, (x0, y0))
    patina = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    patina_px = patina.load()
    rng = random.Random(seed + 310)
    for py in range(h):
        for px in range(w):
            edge = min(px, py, w - 1 - px, h - 1 - py)
            edge_alpha = max(0, 58 - edge * 3)
            vertical = int(abs(py / max(1, h - 1) - 0.52) * 16)
            fleck = 0
            if (px * 13 + py * 29 + seed) % 97 == 0:
                fleck = rng.randint(5, 16)
            alpha = max(0, min(78, edge_alpha + vertical + fleck))
            if alpha > 0:
                patina_px[px, py] = (88, 56, 28, alpha)
    patina.putalpha(Image.composite(patina.getchannel("A"), Image.new("L", (w, h), 0), mask))
    image.alpha_composite(patina, (x0, y0))

    scuffs = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(scuffs)
    for _ in range(max(10, w // 34)):
        edge_side = rng.choice(("top", "bottom", "left", "right", "field"))
        if edge_side == "top":
            sx = rng.randint(12, max(12, w - 54))
            sy = rng.randint(7, 24)
            ex = min(w - 14, sx + rng.randint(16, 62))
            sd.line((sx, sy, ex, sy + rng.choice((-1, 0, 1))), fill=(83, 49, 21, rng.randint(16, 34)), width=1)
        elif edge_side == "bottom":
            sx = rng.randint(14, max(14, w - 62))
            sy = rng.randint(max(8, h - 26), max(8, h - 10))
            ex = min(w - 14, sx + rng.randint(18, 76))
            sd.line((sx, sy, ex, sy + rng.choice((-1, 0, 1))), fill=(94, 57, 25, rng.randint(15, 32)), width=1)
        elif edge_side == "left":
            sx = rng.randint(8, 20)
            sy = rng.randint(18, max(18, h - 34))
            ey = min(h - 14, sy + rng.randint(10, 44))
            sd.line((sx, sy, sx + rng.choice((-1, 0, 1)), ey), fill=(77, 46, 21, rng.randint(12, 26)), width=1)
        elif edge_side == "right":
            sx = rng.randint(max(8, w - 22), max(8, w - 10))
            sy = rng.randint(18, max(18, h - 34))
            ey = min(h - 14, sy + rng.randint(10, 44))
            sd.line((sx, sy, sx + rng.choice((-1, 0, 1)), ey), fill=(77, 46, 21, rng.randint(10, 24)), width=1)
        else:
            sx = rng.randint(34, max(34, w - 82))
            sy = rng.randint(34, max(34, h - 34))
            ex = min(w - 30, sx + rng.randint(18, 72))
            sd.line((sx, sy, ex, sy + rng.choice((-1, 0, 1))), fill=(128, 91, 45, rng.randint(5, 12)), width=1)
    for _ in range(max(6, w // 80)):
        cx = rng.choice((rng.randint(10, 34), rng.randint(max(10, w - 34), max(10, w - 12))))
        cy = rng.choice((rng.randint(10, 30), rng.randint(max(10, h - 30), max(10, h - 12))))
        r = rng.randint(2, 5)
        sd.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(71, 43, 22, rng.randint(12, 26)))
    scuffs = scuffs.filter(ImageFilter.GaussianBlur(0.18))
    scuffs.putalpha(Image.composite(scuffs.getchannel("A"), Image.new("L", (w, h), 0), mask))
    image.alpha_composite(scuffs, (x0, y0))

    d = ImageDraw.Draw(image)
    d.rounded_rectangle((x0, y0, x1, y1), radius=radius, outline=_rgba("#2d1d10", 156), width=1)
    d.rounded_rectangle((x0 + 4, y0 + 4, x1 - 4, y1 - 4), radius=radius - 3, outline=_rgba("#8d642f", 168), width=2)
    d.rounded_rectangle((x0 + 10, y0 + 10, x1 - 10, y1 - 10), radius=radius - 6, outline=_rgba("#c99b47", 92), width=1)
    d.line((x0 + 18, y0 + 13, x1 - 18, y0 + 13), fill=(255, 246, 215, 62), width=1)
    d.line((x0 + 18, y1 - 12, x1 - 18, y1 - 12), fill=(88, 54, 26, 58), width=1)


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
    y0, y1 = 12, 236
    split1 = int(w * 0.235)
    split2 = int(w * 0.535)
    split3 = int(w * 0.785)
    slot_gap = 8
    slots = [
        (8, y0, split1 - slot_gap, y1, "#f4ead5"),
        (split1 + slot_gap, y0, split2 - slot_gap, y1, "#f3e8d0"),
        (split2 + slot_gap, y0, split3 - slot_gap, y1, "#f5ead4"),
        (split3 + slot_gap, y0, w - 8, y1, "#123554"),
    ]
    for i, (x0, sy0, x1, sy1, fill) in enumerate(slots):
        if i == 3:
            _draw_navy_card(
                image,
                (x0, sy0, x1, sy1),
                radius=12,
                seed=30 + i,
                outer_alpha=220,
                outer_width=2,
                border_alpha=155,
                inner_alpha=88,
                detail_alpha_scale=0.86,
            )
            d.rounded_rectangle(
                (x0 + 18, sy0 + 22, x1 - 18, sy1 - 22),
                radius=8,
                outline=_rgba("#6dc8ee", 34),
                width=1,
            )
            d.line((x0 + 36, sy0 + 62, x1 - 36, sy0 + 62), fill=_rgba("#e0bd62", 82), width=1)
            _draw_corner_brackets(d, (x0 + 10, sy0 + 10, x1 - 10, sy1 - 10), length=32, inset=10, color="#e0bd62", alpha=105, width=2)
        else:
            _draw_top_status_paper_card(image, (x0, sy0, x1, sy1), fill, seed=10 + i)
            body = (x0 + 20, sy0 + 20, x1 - 20, sy1 - 20)
            d.rounded_rectangle(body, radius=6, outline=_rgba("#8c6733", 24), width=1)
            d.line((body[0] + 18, body[1] + 12, body[2] - 18, body[1] + 12), fill=_rgba("#ffffff", 32), width=1)
            _draw_corner_brackets(d, (x0 + 8, sy0 + 8, x1 - 8, sy1 - 8), length=28, inset=10, color="#8c6733", alpha=88, width=2)
            if i == 1:
                separator_x = x0 + 246
                d.line((separator_x, sy0 + 46, separator_x, sy1 - 46), fill=_rgba("#b8934d", 58), width=1)
                d.line((separator_x + 4, sy0 + 50, separator_x + 4, sy1 - 50), fill=_rgba("#ffffff", 28), width=1)
            elif i == 2:
                separator_x = x0 + 132
                d.line((separator_x, sy0 + 46, separator_x, sy1 - 46), fill=_rgba("#b8934d", 46), width=1)
                d.line((separator_x + 4, sy0 + 50, separator_x + 4, sy1 - 50), fill=_rgba("#ffffff", 24), width=1)
    image.save(OUT_DIR / "top_status_frame.png")


def _create_sidebar_card_icon(icon_index: int, filename: str, *, seed: int) -> None:
    reference_icon = _reference_sidebar_icon(filename, (168, 150))
    if reference_icon is not None:
        reference_icon.save(OUT_DIR / filename)
        return
    if not ICON_SHEET.exists():
        return
    sheet = Image.open(ICON_SHEET).convert("RGBA")
    cell_w = sheet.width // 3
    cell_h = sheet.height // 3
    col = icon_index % 3
    row = icon_index // 3
    raw = sheet.crop((col * cell_w, row * cell_h, (col + 1) * cell_w, (row + 1) * cell_h))
    crop = raw.crop(_content_bbox(raw))

    canvas = Image.new("RGBA", (168, 150), (0, 0, 0, 0))

    max_w = 116
    max_h = 102
    scale = min(max_w / crop.width, max_h / crop.height)
    resized = crop.resize((round(crop.width * scale), round(crop.height * scale)), Image.Resampling.LANCZOS)
    # The source icon sheet is intentionally ornate; lower-card icons are kept
    # as cutouts so the cards read as one printed paper surface, not nested UI.
    alpha = resized.getchannel("A").point(lambda value: int(value * 0.82))
    resized.putalpha(alpha)
    x = (canvas.width - resized.width) // 2
    y = (canvas.height - resized.height) // 2 - 4
    shadow = Image.new("RGBA", resized.size, (0, 0, 0, 0))
    shadow.putalpha(alpha.point(lambda value: int(value * 0.18)))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(2.0)), (x + 3, y + 4))
    canvas.alpha_composite(resized, (x, y))
    canvas.save(OUT_DIR / filename)


def create_sidebar_card_icons() -> None:
    _create_sidebar_card_icon(7, "fight_action_card_icon.png", seed=90)
    _create_sidebar_card_icon(8, "fight_tackle_card_icon.png", seed=91)


def create_sidebar_frame() -> None:
    w, h = 678, 1024
    image = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(image)
    _draw_outer_frame(image, (5, 4, w - 6, h - 5), radius=14)

    header = (10, 12, w - 10, 91)
    fish = (12, 94, w - 12, 594)
    action = (10, 606, w - 10, 806)
    tackle = (10, 820, w - 10, h - 12)
    action_body = (18, 640, w - 18, 799)
    tackle_body = (18, 852, w - 18, h - 20)

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
        outer_alpha=150,
        outer_width=1,
        border_alpha=96,
        border_width=1,
        inner_alpha=62,
        detail_alpha_scale=0.50,
    )
    d.line((header[0] + 24, header[3] - 15, header[2] - 24, header[3] - 15), fill=_rgba("#063626", 54), width=1)
    d.line((header[0] + 24, header[3] - 10, header[2] - 24, header[3] - 10), fill=_rgba("#f4d27c", 34), width=1)

    _draw_clean_card(
        image,
        fish,
        "#ecd8b6",
        radius=10,
        border="#8c6733",
        inner="#d2aa58",
        seed=81,
        texture_strength=8,
        outer_alpha=166,
        outer_width=1,
        border_alpha=100,
        border_width=1,
        inner_alpha=58,
        detail_alpha_scale=0.58,
    )
    title_rule_y = fish[1] + 76
    d.line((fish[0] + 48, title_rule_y, fish[2] - 48, title_rule_y), fill=_rgba("#b89b64", 58), width=1)
    d.line((fish[0] + 48, title_rule_y + 2, fish[2] - 48, title_rule_y + 2), fill=_rgba("#ffffff", 30), width=1)
    portrait_mat = (fish[0] + 42, fish[1] + 86, fish[2] - 42, fish[1] + 340)
    grid = Image.new("RGBA", image.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(grid)
    for x in range(portrait_mat[0] + 38, portrait_mat[2] - 20, 46):
        gd.line((x, portrait_mat[1] + 12, x, portrait_mat[3] - 8), fill=_rgba("#c8ad76", 12), width=1)
    for y in range(portrait_mat[1] + 38, portrait_mat[3] - 8, 48):
        gd.line((portrait_mat[0] + 18, y, portrait_mat[2] - 18, y), fill=_rgba("#c8ad76", 18), width=1)
    image.alpha_composite(grid)
    for y in (fish[1] + 348,):
        d.line((fish[0] + 38, y, fish[2] - 38, y), fill=_rgba("#b89b64", 58), width=1)
    _draw_corner_brackets(d, fish, length=30, inset=18, color="#a77d3b", alpha=66, width=1)

    _draw_navy_card(
        image,
        action,
        radius=12,
        seed=82,
        outer_alpha=112,
        outer_width=1,
        border_alpha=64,
        border_width=1,
        inner_alpha=34,
        detail_alpha_scale=0.30,
    )
    _draw_clean_card(
        image,
        action_body,
        "#eedcbb",
        radius=8,
        border="#8c6733",
        inner="#d8b45d",
        seed=83,
        texture_strength=6,
        shadow=False,
        outer_alpha=84,
        outer_width=1,
        border_alpha=48,
        border_width=1,
        inner_alpha=16,
        detail_alpha_scale=0.22,
    )
    _draw_navy_card(
        image,
        tackle,
        radius=12,
        seed=84,
        outer_alpha=112,
        outer_width=1,
        border_alpha=64,
        border_width=1,
        inner_alpha=34,
        detail_alpha_scale=0.30,
    )
    _draw_clean_card(
        image,
        tackle_body,
        "#eedcbb",
        radius=8,
        border="#8c6733",
        inner="#d8b45d",
        seed=85,
        texture_strength=6,
        shadow=False,
        outer_alpha=84,
        outer_width=1,
        border_alpha=48,
        border_width=1,
        inner_alpha=16,
        detail_alpha_scale=0.22,
    )

    for panel_index, (panel, body, icon_side) in enumerate(((action, action_body, "left"), (tackle, tackle_body, "right"))):
        d.line((panel[0] + 26, panel[1] + 39, panel[2] - 26, panel[1] + 39), fill=_rgba("#e0bd62", 22), width=1)
        d.line((panel[0] + 28, panel[1] + 44, panel[2] - 28, panel[1] + 44), fill=_rgba("#07121b", 10), width=1)
        d.rounded_rectangle(
            (body[0] + 12, body[1] + 13, body[2] - 12, body[3] - 13),
            radius=8,
            outline=_rgba("#a98242", 3),
            width=1,
        )
        d.line((body[0] + 36, body[3] - 18, body[2] - 36, body[3] - 18), fill=_rgba("#80552a", 2), width=1)
        _draw_corner_brackets(d, body, length=13, inset=11, color="#a77d3b", alpha=3, width=1)

    # Sparse corner accents only. Heavy rivets made the frame read as generated/debug UI.
    for cx, cy in (
        (24, 24),
        (w - 24, 24),
        (24, h - 24),
        (w - 24, h - 24),
    ):
        d.ellipse((cx - 4, cy - 4, cx + 4, cy + 4), fill=_rgba("#112031", 112), outline=_rgba("#e1be65", 64), width=1)
        d.ellipse((cx - 1, cy - 1, cx + 1, cy + 1), fill=_rgba("#fff1b7", 72))

    image.save(OUT_DIR / "sidebar_frame.png")


def _draw_bar_well(image: Image.Image, box: tuple[int, int, int, int]) -> None:
    x0, y0, x1, y1 = box
    d = ImageDraw.Draw(image)
    d.rounded_rectangle((x0, y0, x1, y1), radius=8, fill=_rgba("#07121b", 206), outline=_rgba("#22384c", 158), width=2)
    for x in range(x0 + 44, x1, 92):
        d.line((x, y0 + 7, x, y1 - 7), fill=(255, 255, 255, 5), width=1)
    d.line((x0 + 7, y0 + 5, x1 - 7, y0 + 5), fill=(255, 255, 255, 34), width=1)


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
        (top[1] + 54, _rgba("#e0bd62", 38), 2),
        (top[3] - 24, (255, 255, 255, 18), 1),
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
    d.polygon(plate_shadow, fill=(0, 0, 0, 54))
    plate = [
        (depth[0] + 24, depth[1] + 12),
        (depth[2] - 24, depth[1] + 12),
        (depth[2] - 70, depth[3] - 16),
        (depth[0] + 70, depth[3] - 16),
    ]
    d.polygon(plate, fill=_rgba("#123b61", 224))
    for inset, alpha, width_px in ((0, 118, 2), (10, 48, 1)):
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
    d.line((depth[0] + 52, depth[1] + 26, depth[2] - 52, depth[1] + 26), fill=_rgba("#fff1a8", 54), width=1)
    d.line((depth[0] + 76, depth[3] - 26, depth[2] - 76, depth[3] - 26), fill=(255, 255, 255, 24), width=1)

    title_tab = (depth[0] + 72, depth[1] + 46, depth[2] - 72, depth[1] + 94)
    d.rounded_rectangle(title_tab, radius=8, fill=_rgba("#081f35", 110), outline=_rgba("#6fd6ff", 28), width=1)
    value_plaque = (depth[0] + 84, depth[1] + 126, depth[2] - 84, depth[3] - 30)
    d.rounded_rectangle(value_plaque, radius=8, fill=_rgba("#103456", 145), outline=_rgba("#cfa45a", 58), width=1)
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
        "#eedcbb",
        radius=8,
        border="#8c6733",
        inner="#d8b45d",
        seed=51,
        texture_strength=6,
        shadow=False,
    )
    bait_title = (bait_panel[0] + 14, bait_panel[1] + 12, bait_panel[2] - 14, bait_panel[1] + 44)
    d.rounded_rectangle(bait_title, radius=7, fill=_rgba("#8b7558", 210), outline=_rgba("#fff0c7", 52), width=1)
    d.line((bait_title[0] + 8, bait_title[1] + 6, bait_title[2] - 8, bait_title[1] + 6), fill=(255, 255, 255, 34), width=1)
    bait_body = (bait_panel[0] + 58, bait_panel[1] + 55, bait_panel[2] - 16, bait_panel[3] - 14)
    _draw_paper_slot(d, bait_body)
    _draw_inner_shadow(d, bait_body, alpha=20)
    _draw_clean_card(
        image,
        hint_panel,
        "#0e3a5b",
        radius=8,
        border="#9f7a3d",
        inner="#dfbf73",
        seed=52,
        texture_strength=4,
        shadow=False,
    )
    hint_title = (hint_panel[0] + 14, hint_panel[1] + 12, hint_panel[2] - 14, hint_panel[1] + 50)
    d.rounded_rectangle(hint_title, radius=7, fill=_rgba("#092840", 160), outline=_rgba("#d8b45d", 62), width=1)
    d.line((hint_title[0] + 12, hint_title[1] + 7, hint_title[2] - 12, hint_title[1] + 7), fill=(255, 255, 255, 28), width=1)
    hint_body = (hint_panel[0] + 16, hint_panel[1] + 54, hint_panel[2] - 16, hint_panel[3] - 8)
    _draw_paper_slot(d, hint_body)
    _draw_inner_shadow(d, hint_body, alpha=14)
    for i in (1, 2):
        x = hint_body[0] + int((hint_body[2] - hint_body[0]) * i / 3)
        d.line((x, hint_body[1] + 14, x, hint_body[3] - 14), fill=_rgba("#8c6733", 5), width=1)
        d.line((x + 3, hint_body[1] + 18, x + 3, hint_body[3] - 18), fill=(255, 255, 255, 3), width=1)
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

    # Shared separators: enough structure without returning to the previous grid-like skin.
    for x, slant in ((depth[0] - gap // 2, 18), (depth[2] + gap // 2, -18)):
        d.line((x + slant, top[1] + 22, x - slant, top[3] - 22), fill=_rgba("#b88b3f", 76), width=2)
        d.line((x + slant + (6 if slant > 0 else -6), top[1] + 22, x - slant + (6 if slant > 0 else -6), top[3] - 22), fill=_rgba("#07121b", 86), width=1)
    for x in (hint[0] - gap // 2, menu[0] - gap // 2):
        d.line((x, bottom[1] + 16, x, bottom[3] - 16), fill=_rgba("#b88b3f", 68), width=1)

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
