#!/usr/bin/env python3
"""Generate replaceable first-pass cooking showcase assets.

These are intentionally authored placeholders, not final art. They give the
Godot UI stable image slots for the cooking flow while keeping all assets
project-owned and deterministic.
"""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "showcase" / "cooking"
COOK_SELECT_REFERENCE = ROOT / "reference" / "cooking_flow" / "01_cook_select_concept.png"


def rgba(hex_color: str, alpha: int = 255) -> tuple[int, int, int, int]:
    hex_color = hex_color.lstrip("#")
    return (
        int(hex_color[0:2], 16),
        int(hex_color[2:4], 16),
        int(hex_color[4:6], 16),
        alpha,
    )


def save(img: Image.Image, name: str) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    img.save(OUT / name)


def draw_panel(
    draw: ImageDraw.ImageDraw,
    box: tuple[int, int, int, int],
    fill: tuple[int, int, int, int],
    border: tuple[int, int, int, int],
    inner: tuple[int, int, int, int] | None = None,
    width: int = 4,
    radius: int = 8,
) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=border, width=width)
    if inner is not None:
        x0, y0, x1, y1 = box
        draw.rounded_rectangle(
            (x0 + width + 3, y0 + width + 3, x1 - width - 3, y1 - width - 3),
            radius=max(2, radius - 4),
            outline=inner,
            width=max(1, width // 2),
        )


def texture(size: tuple[int, int], base: str, seed: int, strength: int = 9) -> Image.Image:
    rng = random.Random(seed)
    w, h = size
    r, g, b, a = rgba(base)
    pixels = bytearray()
    for y in range(h):
        warm = int((y / max(1, h - 1) - 0.5) * strength)
        for x in range(w):
            grain = rng.randint(-strength, strength)
            fleck = rng.randint(-7, 5) if (x * 19 + y * 31 + seed) % 47 == 0 else 0
            pixels.extend(
                (
                    max(0, min(255, r + grain + warm + fleck)),
                    max(0, min(255, g + grain + warm + fleck // 2)),
                    max(0, min(255, b + grain // 2)),
                    a,
                )
            )
    return Image.frombytes("RGBA", size, bytes(pixels))


def reference_paper_texture(
    size: tuple[int, int],
    base: str,
    seed: int,
    crop_box: tuple[int, int, int, int] | None = None,
    blend: float = 0.42,
    blur: float = 8.0,
) -> Image.Image:
    base_texture = texture(size, base, seed, 8)
    if not COOK_SELECT_REFERENCE.exists():
        return base_texture

    source = Image.open(COOK_SELECT_REFERENCE).convert("RGB")
    paper_crops = [
        (76, 204, 458, 302),
        (496, 204, 650, 438),
        (1030, 190, 1540, 790),
        (106, 846, 1532, 944),
        (706, 470, 1000, 752),
    ]
    rng = random.Random(seed + 421)
    crop = source.crop(crop_box if crop_box is not None else paper_crops[seed % len(paper_crops)])
    scale = max(size[0] / crop.width, size[1] / crop.height)
    resized = crop.resize((round(crop.width * scale), round(crop.height * scale)), Image.Resampling.BICUBIC)
    if resized.width > size[0] or resized.height > size[1]:
        x = rng.randint(0, max(0, resized.width - size[0]))
        y = rng.randint(0, max(0, resized.height - size[1]))
        resized = resized.crop((x, y, x + size[0], y + size[1]))
    resized = resized.resize(size, Image.Resampling.BICUBIC).filter(ImageFilter.GaussianBlur(blur))

    br, bg, bb, _ = rgba(base)
    pixels = bytearray()
    for r, g, b in resized.getdata():
        luminance = r * 0.30 + g * 0.59 + b * 0.11
        warm = (r - b) * 0.024
        delta = (luminance - 205.0) * 0.19
        pixels.extend(
            (
                max(0, min(255, int(br + delta + warm))),
                max(0, min(255, int(bg + delta * 0.92 + warm * 0.40))),
                max(0, min(255, int(bb + delta * 0.70))),
                255,
            )
        )
    reference_variation = Image.frombytes("RGBA", size, bytes(pixels))
    return Image.blend(base_texture, reference_variation, blend)


def reference_background_patch(
    size: tuple[int, int],
    crop_box: tuple[int, int, int, int],
    brightness: float = 0.76,
    contrast: float = 1.08,
    blur: float = 0.4,
) -> Image.Image | None:
    if not COOK_SELECT_REFERENCE.exists():
        return None
    source = Image.open(COOK_SELECT_REFERENCE).convert("RGBA")
    crop = source.crop(crop_box)
    scale = max(size[0] / crop.width, size[1] / crop.height)
    resized = crop.resize((round(crop.width * scale), round(crop.height * scale)), Image.Resampling.BICUBIC)
    left = max(0, (resized.width - size[0]) // 2)
    top = max(0, (resized.height - size[1]) // 2)
    patch = resized.crop((left, top, left + size[0], top + size[1]))
    patch = ImageEnhance.Brightness(patch).enhance(brightness)
    patch = ImageEnhance.Contrast(patch).enhance(contrast)
    if blur > 0:
        patch = patch.filter(ImageFilter.GaussianBlur(blur))
    return patch


def rounded_mask(size: tuple[int, int], radius: int, alpha: int = 255) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=alpha)
    return mask


def paste_rounded(dst: Image.Image, patch: Image.Image, box: tuple[int, int, int, int], radius: int, alpha: int = 255) -> None:
    x0, y0, x1, y1 = box
    resized = patch.resize((x1 - x0, y1 - y0), Image.Resampling.BICUBIC)
    mask = rounded_mask(resized.size, radius, alpha).filter(ImageFilter.GaussianBlur(0.35))
    dst.alpha_composite(Image.composite(resized, Image.new("RGBA", resized.size, (0, 0, 0, 0)), mask), (x0, y0))


def draw_corner_brackets(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], color: tuple[int, int, int, int], dark: tuple[int, int, int, int], length: int = 22, width: int = 3) -> None:
    x0, y0, x1, y1 = box
    for sx, sy, ox, oy in [(1, 1, x0, y0), (-1, 1, x1, y0), (1, -1, x0, y1), (-1, -1, x1, y1)]:
        draw.line((ox, oy, ox + sx * length, oy), fill=dark, width=width + 2)
        draw.line((ox, oy, ox, oy + sy * length), fill=dark, width=width + 2)
        draw.line((ox, oy, ox + sx * length, oy), fill=color, width=width)
        draw.line((ox, oy, ox, oy + sy * length), fill=color, width=width)


def cooking_room_bg() -> None:
    w, h = 1280, 720
    img = Image.new("RGBA", (w, h), rgba("1c2c32"))
    draw = ImageDraw.Draw(img, "RGBA")

    for y in range(h):
        t = y / max(1, h - 1)
        top = (40, 42, 44)
        mid = (128, 76, 33)
        bot = (48, 33, 25)
        if t < 0.62:
            u = t / 0.62
            col = tuple(int(top[i] * (1 - u) + mid[i] * u) for i in range(3))
        else:
            u = (t - 0.62) / 0.38
            col = tuple(int(mid[i] * (1 - u) + bot[i] * u) for i in range(3))
        draw.line((0, y, w, y), fill=(*col, 255))

    # Back wall planks.
    for x in range(0, w, 64):
        shade = 18 + (x // 64 % 2) * 12
        draw.rectangle((x, 92, x + 62, 470), fill=(88 + shade, 55 + shade // 2, 27, 126))
        draw.line((x, 92, x, 470), fill=(26, 18, 15, 155), width=2)
    for y in range(122, 470, 56):
        draw.line((0, y, w, y), fill=(26, 17, 12, 120), width=2)

    # Windows and sea outside. The references read as a kitchen connected to the harbor,
    # so keep the blue view visible at both sides behind the UI columns.
    draw_panel(draw, (64, 126, 310, 300), rgba("1a2638", 240), rgba("583719"), rgba("d9a84f"), 6, 4)
    for yy in range(144, 286):
        t = (yy - 144) / 142
        col = (82, int(164 + 48 * (1 - t)), int(211 + 28 * (1 - t)), 255)
        draw.line((80, yy, 294, yy), fill=col)
    draw.rectangle((80, 226, 294, 286), fill=(25, 122, 158, 232))
    for i in range(12):
        y = 240 + i * 4
        draw.line((90, y, 286, y + int(math.sin(i * 0.7) * 2)), fill=(211, 246, 238, 88), width=1)
    for x in [151, 224]:
        draw.line((x, 132, x, 294), fill=(76, 45, 22, 220), width=5)
    draw.line((70, 212, 304, 212), fill=(76, 45, 22, 220), width=5)

    draw_panel(draw, (930, 112, 1180, 302), rgba("1a2638", 240), rgba("583719"), rgba("d9a84f"), 6, 4)
    for yy in range(130, 286):
        t = (yy - 130) / 156
        col = (74, int(150 + 60 * (1 - t)), int(205 + 35 * (1 - t)), 255)
        draw.line((946, yy, 1164, yy), fill=col)
    draw.rectangle((946, 222, 1164, 286), fill=(24, 111, 151, 230))
    for i in range(16):
        y = 238 + i * 3
        draw.line((956, y, 1155, y + int(math.sin(i) * 2)), fill=(199, 239, 238, 90), width=1)
    draw.line((1054, 118, 1054, 294), fill=(76, 45, 22, 220), width=6)
    draw.line((940, 208, 1170, 208), fill=(76, 45, 22, 220), width=6)

    # The COOK_SELECT layout leaves a narrow vertical strip visible between the
    # recipe grid and detail card. Fill that exposed strip with the reference
    # harbor-window density instead of letting it read as plain dark planks.
    strip = reference_background_patch((94, 560), (1530, 120, 1670, 760), 0.88, 1.12, 0.15)
    if strip is not None:
        mask = Image.new("L", strip.size, 0)
        md = ImageDraw.Draw(mask)
        for x in range(strip.width):
            edge = min(x, strip.width - 1 - x)
            alpha = max(0, min(226, int(edge / 8 * 226)))
            md.line((x, 0, x, strip.height), fill=alpha)
        mask = mask.filter(ImageFilter.GaussianBlur(0.65))
        img.alpha_composite(Image.composite(strip, Image.new("RGBA", strip.size, (0, 0, 0, 0)), mask), (760, 96))
        draw = ImageDraw.Draw(img, "RGBA")
        draw.line((766, 102, 766, 640), fill=(42, 25, 14, 176), width=3)
        draw.line((848, 102, 848, 640), fill=(42, 25, 14, 165), width=3)

    # Counter/floor.
    draw.rounded_rectangle((418, 332, 852, 430), radius=14, fill=(74, 43, 24, 210), outline=(158, 105, 48, 120), width=3)
    for x in range(440, 840, 56):
        draw.line((x, 340, x - 20, 420), fill=(35, 22, 15, 72), width=2)
    draw.ellipse((534, 372, 758, 432), fill=(21, 18, 16, 120))
    draw.rounded_rectangle((584, 334, 700, 392), radius=12, fill=(32, 31, 30, 168), outline=(183, 123, 60, 130), width=3)
    for x in [614, 654]:
        draw.arc((x, 350, x + 44, 392), 192, 342, fill=(255, 199, 88, 88), width=3)
    draw.polygon([(0, 498), (1280, 454), (1280, 720), (0, 720)], fill=(92, 51, 25, 240))
    for y in range(520, 720, 34):
        draw.line((0, y, 1280, y - 40), fill=(35, 22, 15, 120), width=2)
    for x in range(-80, 1280, 92):
        draw.line((x, 506, x + 142, 720), fill=(141, 84, 40, 62), width=2)

    # Lanterns and warm glows.
    for cx, cy, r in [(104, 96, 78), (338, 174, 58), (1116, 98, 92), (872, 180, 58)]:
        glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        gd = ImageDraw.Draw(glow, "RGBA")
        for k in range(r, 0, -6):
            a = int(70 * (1 - k / r) ** 1.7)
            gd.ellipse((cx - k, cy - k, cx + k, cy + k), fill=(255, 180, 75, a))
        img.alpha_composite(glow)
        draw = ImageDraw.Draw(img, "RGBA")
        draw.ellipse((cx - 12, cy - 18, cx + 12, cy + 18), fill=(255, 205, 115, 210), outline=(84, 48, 24, 240), width=3)

    # Hanging herbs and kitchen silhouettes.
    for x in [390, 428, 772, 810, 916]:
        draw.line((x, 84, x, 190), fill=(67, 42, 20, 210), width=3)
        for j in range(6):
            draw.ellipse((x - 18 + j * 4, 120 + j * 10, x + 10 + j * 4, 148 + j * 10), fill=(48, 95, 48, 150))
    for x, y, ww, hh in [(56, 390, 130, 90), (230, 372, 110, 92), (1110, 404, 120, 100)]:
        draw.rounded_rectangle((x, y, x + ww, y + hh), radius=8, fill=(22, 22, 24, 130), outline=(142, 96, 47, 130), width=2)
    for x, y in [(492, 184), (536, 182), (580, 188), (624, 180), (668, 186)]:
        draw.ellipse((x, y, x + 34, y + 44), fill=(78, 46, 29, 165), outline=(199, 139, 72, 100), width=2)
    draw.line((470, 174, 730, 174), fill=(78, 48, 28, 210), width=6)

    # Readability glaze.
    overlay = Image.new("RGBA", (w, h), (8, 12, 18, 44))
    img.alpha_composite(overlay)
    save(img, "cooking_room_bg.png")


def meal_scene_bg() -> None:
    w, h = 1280, 720
    img = Image.new("RGBA", (w, h), rgba("2a1c16"))
    draw = ImageDraw.Draw(img, "RGBA")

    for y in range(h):
        t = y / max(1, h - 1)
        top = (48, 31, 24)
        mid = (150, 82, 37)
        bot = (45, 29, 22)
        if t < 0.55:
            u = t / 0.55
            col = tuple(int(top[i] * (1 - u) + mid[i] * u) for i in range(3))
        else:
            u = (t - 0.55) / 0.45
            col = tuple(int(mid[i] * (1 - u) + bot[i] * u) for i in range(3))
        draw.line((0, y, w, y), fill=(*col, 255))

    # Table surface.
    draw.polygon([(0, 432), (1280, 386), (1280, 720), (0, 720)], fill=(113, 58, 27, 248))
    for y in range(448, 720, 34):
        draw.line((0, y, 1280, y - 48), fill=(43, 24, 16, 130), width=2)
    for x in range(-160, 1280, 160):
        draw.line((x, 430, x + 230, 720), fill=(146, 89, 44, 70), width=3)
    draw.rounded_rectangle((368, 388, 912, 476), radius=18, fill=(70, 38, 21, 128), outline=(194, 127, 62, 70), width=3)

    # Soft lantern glow behind the reward panel.
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow, "RGBA")
    for r in range(500, 20, -16):
        a = int(72 * (1 - r / 500) ** 1.55)
        gd.ellipse((640 - r, 282 - r, 640 + r, 282 + r), fill=(255, 178, 82, a))
    img.alpha_composite(glow)
    draw = ImageDraw.Draw(img, "RGBA")

    # Background shelves and cookware silhouettes.
    draw.rounded_rectangle((70, 86, 430, 198), radius=8, fill=(37, 27, 24, 160), outline=(132, 80, 38, 150), width=3)
    draw.rounded_rectangle((850, 82, 1210, 202), radius=8, fill=(37, 27, 24, 160), outline=(132, 80, 38, 150), width=3)
    draw.rounded_rectangle((492, 74, 788, 174), radius=10, fill=(41, 28, 22, 150), outline=(157, 96, 44, 135), width=3)
    for x in [116, 176, 236, 934, 1004, 1074, 1144]:
        draw.ellipse((x, 124, x + 42, 170), fill=(86, 55, 34, 180), outline=(191, 135, 68, 100), width=2)
    for x in [314, 374, 526, 584, 642, 700, 876]:
        draw.rounded_rectangle((x, 110, x + 46, 174), radius=8, fill=(41, 80, 64, 170), outline=(184, 135, 72, 110), width=2)
    for cx, cy, rr in [(110, 78, 68), (1180, 76, 74), (640, 82, 78)]:
        for k in range(rr, 0, -8):
            a = int(42 * (1 - k / rr) ** 1.6)
            draw.ellipse((cx - k, cy - k, cx + k, cy + k), fill=(255, 185, 80, a))
        draw.ellipse((cx - 12, cy - 16, cx + 12, cy + 16), fill=(255, 207, 116, 210), outline=(93, 52, 27, 225), width=3)

    # Plates and side dishes around the focal dialog area.
    for cx, cy, sx, sy in [(186, 548, 190, 72), (1062, 552, 210, 78), (468, 632, 150, 58), (822, 626, 150, 58)]:
        draw.ellipse((cx - sx // 2, cy - sy // 2 + 14, cx + sx // 2, cy + sy // 2 + 18), fill=(28, 20, 16, 82))
        draw.ellipse((cx - sx // 2, cy - sy // 2, cx + sx // 2, cy + sy // 2), fill=(224, 213, 184, 220), outline=(94, 66, 46, 180), width=4)
        draw.ellipse((cx - sx // 3, cy - sy // 3, cx + sx // 3, cy + sy // 3), fill=(181, 128, 64, 160))

    # Steam strokes near the dish area, subtle enough to stay behind text.
    for i, x in enumerate([356, 384, 920, 948]):
        y0 = 384 + (i % 2) * 16
        for k in range(3):
            draw.arc((x - 18, y0 - k * 44, x + 22, y0 + 64 - k * 44), 104, 258, fill=(255, 234, 196, 72), width=3)

    # Readability vignette.
    vignette = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette, "RGBA")
    for r in range(760, 180, -20):
        a = int(62 * (1 - (760 - r) / 580) ** 1.3)
        vd.rectangle((0, 0, w, h), outline=(8, 10, 14, a), width=18)
    img.alpha_composite(vignette)
    img.alpha_composite(Image.new("RGBA", (w, h), (14, 14, 20, 28)))
    save(img, "meal_scene_bg.png")


def exp_stage_bg() -> None:
    w, h = 1280, 720
    img = Image.new("RGBA", (w, h), rgba("07101d"))
    draw = ImageDraw.Draw(img, "RGBA")

    # Cool, dark kitchen stage for EXP_GAIN. This deliberately separates the
    # meter moment from the warm MEAL_RESULT eating scene.
    for y in range(h):
        t = y / max(1, h - 1)
        top = (5, 12, 25)
        mid = (12, 30, 50)
        bot = (6, 13, 22)
        if t < 0.54:
            u = t / 0.54
            col = tuple(int(top[i] * (1 - u) + mid[i] * u) for i in range(3))
        else:
            u = (t - 0.54) / 0.46
            col = tuple(int(mid[i] * (1 - u) + bot[i] * u) for i in range(3))
        draw.line((0, y, w, y), fill=(*col, 255))

    # Dim shelves and cookware silhouettes, visible behind the EXP UI.
    for x0, x1, y0 in [(48, 404, 72), (874, 1234, 86), (486, 790, 88)]:
        draw.rounded_rectangle((x0, y0, x1, y0 + 132), radius=8, fill=(16, 20, 28, 176), outline=(98, 60, 31, 105), width=3)
        for x in range(x0 + 28, x1 - 28, 58):
            draw.line((x, y0 + 14, x - 18, y0 + 116), fill=(72, 44, 25, 52), width=2)
            draw.ellipse((x, y0 + 52, x + 32, y0 + 92), fill=(63, 43, 33, 116), outline=(166, 111, 54, 64), width=2)
    for x in [150, 214, 950, 1030, 1110, 578, 648, 716]:
        draw.rounded_rectangle((x, 164, x + 38, 236), radius=8, fill=(27, 62, 64, 106), outline=(137, 93, 50, 64), width=2)
    for x in [420, 828, 1148]:
        draw.line((x, 28, x, 162), fill=(72, 44, 24, 160), width=5)
        draw.ellipse((x - 14, 142, x + 14, 184), fill=(230, 163, 70, 170), outline=(92, 52, 23, 220), width=3)

    # Central burst behind the +EXP and gauge.
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow, "RGBA")
    center = (640, 290)
    for i in range(72):
        angle = math.tau * i / 72
        inner = 36 + (i % 5) * 4
        outer = 520 + (i % 7) * 22
        col = (255, 214, 94, 42) if i % 2 == 0 else (83, 229, 255, 28)
        x0 = center[0] + math.cos(angle) * inner
        y0 = center[1] + math.sin(angle) * inner
        x1 = center[0] + math.cos(angle) * outer
        y1 = center[1] + math.sin(angle) * outer
        gd.line((x0, y0, x1, y1), fill=col, width=5 if i % 2 == 0 else 3)
    for r in range(430, 24, -18):
        a = int(90 * (1 - r / 430) ** 1.9)
        gd.ellipse((center[0] - r, center[1] - r, center[0] + r, center[1] + r), fill=(255, 204, 74, a))
    for r in range(240, 20, -18):
        a = int(54 * (1 - r / 240) ** 1.5)
        gd.ellipse((center[0] - r, center[1] - r, center[0] + r, center[1] + r), outline=(94, 239, 255, a), width=6)
    glow = glow.filter(ImageFilter.GaussianBlur(1))
    img.alpha_composite(glow)
    draw = ImageDraw.Draw(img, "RGBA")

    # Energy trails from dish area to gauge/effect card.
    for i in range(6):
        y = 296 + i * 18
        draw.arc((246, y - 68, 680, y + 58), 190, 350, fill=(255, 206, 73, 92), width=4)
        draw.arc((606, y - 42, 1018, y + 48), 190, 350, fill=(99, 242, 255, 78), width=3)
    for i in range(56):
        x = 64 + (i * 139) % (w - 128)
        y = 54 + (i * 67) % (h - 160)
        r = 2 + i % 4
        col = (255, 224, 129, 165) if i % 3 else (107, 241, 255, 150)
        draw.line((x - r, y, x + r, y), fill=col, width=2)
        draw.line((x, y - r, x, y + r), fill=col, width=2)

    # Bottom navy stage so the status strip reads as part of the same moment.
    draw.rectangle((0, 586, w, h), fill=(4, 11, 21, 132))
    draw.line((0, 586, w, 586), fill=(225, 170, 82, 94), width=3)
    img.alpha_composite(Image.new("RGBA", (w, h), (2, 6, 14, 36)))
    save(img, "exp_stage_bg.png")


def fish_icon_sheet() -> None:
    species = [
        ("aji", rgba("5f96ad"), rgba("dff3f5"), rgba("d3b34b"), "stripe"),
        ("mejina", rgba("445d68"), rgba("9eb8bc"), rgba("2d3d45"), "round"),
        ("kasago", rgba("b95336"), rgba("ffb47c"), rgba("7a2f22"), "spots"),
        ("isaki", rgba("8ca08e"), rgba("d9ddbc"), rgba("d7bd59"), "bands"),
        ("saba", rgba("5e91b2"), rgba("eef7f2"), rgba("314f6d"), "waves"),
        ("boss", rgba("334552"), rgba("9baeb3"), rgba("1d2831"), "boss"),
    ]
    cell_w, cell_h = 192, 88
    img = Image.new("RGBA", (cell_w, cell_h * len(species)), (0, 0, 0, 0))

    if COOK_SELECT_REFERENCE.exists():
        source = Image.open(COOK_SELECT_REFERENCE).convert("RGBA")
        reference_specs = [
            ((80, 220, 250, 274), 1.05, 1.04, 1.08),
            ((78, 676, 252, 733), 0.72, 0.76, 1.12),
            ((75, 492, 254, 550), 1.05, 1.03, 1.08),
            ((80, 312, 250, 366), 0.82, 1.06, 1.10),
            ((80, 312, 250, 366), 1.05, 1.05, 1.08),
            ((77, 402, 252, 458), 0.46, 0.62, 1.24),
        ]
        for i, (box, color, brightness, contrast) in enumerate(reference_specs):
            fish = source.crop(box)
            fish = ImageEnhance.Color(fish).enhance(color)
            fish = ImageEnhance.Brightness(fish).enhance(brightness)
            fish = ImageEnhance.Contrast(fish).enhance(contrast)
            fish.thumbnail((166, 62), Image.Resampling.LANCZOS)
            ox = 13 + (166 - fish.width) // 2
            oy = i * cell_h + 13 + (62 - fish.height) // 2

            shadow = Image.new("RGBA", fish.size, (0, 0, 0, 0))
            sd = ImageDraw.Draw(shadow, "RGBA")
            sd.rounded_rectangle((3, fish.height - 13, fish.width - 4, fish.height - 3), radius=6, fill=(0, 0, 0, 82))
            shadow = shadow.filter(ImageFilter.GaussianBlur(4))
            img.alpha_composite(shadow, (ox + 3, oy + 7))

            mask = rounded_mask(fish.size, 4, 246).filter(ImageFilter.GaussianBlur(0.25))
            img.alpha_composite(Image.composite(fish, Image.new("RGBA", fish.size, (0, 0, 0, 0)), mask), (ox, oy))
        save(img, "fish_icon_sheet.png")
        return

    draw = ImageDraw.Draw(img, "RGBA")
    for i, (_name, body, belly, accent, pattern) in enumerate(species):
        ox, oy = 10, i * cell_h + 6
        center_y = oy + 43
        length = 156 if pattern != "boss" else 166
        height = 44 if pattern not in ["round", "boss"] else 52
        head_x = ox + 24
        tail_x = ox + length

        draw.ellipse(
            (head_x - 8, center_y + height // 2 - 4, tail_x + 18, center_y + height // 2 + 10),
            fill=(16, 14, 13, 64),
        )
        body_box = (head_x, center_y - height // 2, tail_x - 24, center_y + height // 2)
        draw.ellipse(body_box, fill=body, outline=(20, 20, 18, 238), width=3)
        draw.pieslice(
            (head_x + 26, center_y - 4, tail_x - 26, center_y + height // 2 + 12),
            0,
            180,
            fill=belly,
        )
        draw.polygon(
            [
                (tail_x - 24, center_y),
                (tail_x + 24, center_y - 27),
                (tail_x + 12, center_y),
                (tail_x + 24, center_y + 27),
            ],
            fill=accent,
            outline=(20, 18, 16, 224),
        )
        draw.polygon(
            [(head_x + 48, center_y - height // 2 + 6), (head_x + 82, oy + 5), (head_x + 76, center_y - 12)],
            fill=accent,
            outline=(20, 18, 16, 180),
        )
        draw.polygon(
            [
                (head_x + 66, center_y + height // 2 - 2),
                (head_x + 100, center_y + height // 2 + 16),
                (head_x + 88, center_y + 13),
            ],
            fill=accent,
            outline=(20, 18, 16, 140),
        )

        if pattern == "stripe":
            draw.line((head_x + 36, center_y - 6, tail_x - 44, center_y - 15), fill=(239, 208, 95, 224), width=4)
            for s in range(5):
                x = head_x + 58 + s * 13
                draw.arc((x, center_y - 20, x + 16, center_y + 22), 98, 260, fill=(255, 255, 255, 78), width=2)
        elif pattern == "round":
            for s in range(4):
                x = head_x + 52 + s * 18
                draw.line((x, center_y - 21, x - 5, center_y + 17), fill=(210, 224, 224, 54), width=3)
        elif pattern == "spots":
            for s in range(14):
                px = head_x + 38 + (s * 19) % 92
                py = center_y - 17 + (s * 11) % 33
                draw.ellipse((px, py, px + 6, py + 5), fill=(111, 38, 28, 150))
            for sx in [head_x + 38, head_x + 132]:
                draw.polygon([(sx, center_y - 24), (sx + 12, center_y - 38), (sx + 18, center_y - 20)], fill=accent)
        elif pattern == "bands":
            for s in range(4):
                x = head_x + 48 + s * 23
                draw.line((x, center_y - 20, x + 8, center_y + 18), fill=(232, 204, 91, 178), width=5)
        elif pattern == "waves":
            for s in range(5):
                x = head_x + 42 + s * 19
                draw.arc((x, center_y - 28, x + 34, center_y - 2), 198, 342, fill=(236, 248, 255, 150), width=3)
            draw.line((head_x + 42, center_y - 13, tail_x - 42, center_y - 10), fill=(39, 68, 92, 180), width=3)
        elif pattern == "boss":
            draw.arc((head_x + 44, center_y - 34, tail_x - 36, center_y + 30), 202, 332, fill=(225, 196, 112, 190), width=4)
            draw.line((head_x + 96, center_y - 17, head_x + 118, center_y + 14), fill=(234, 230, 214, 210), width=4)
            draw.ellipse((tail_x - 70, center_y - 2, tail_x - 58, center_y + 10), fill=(225, 196, 112, 220))

        draw.ellipse((head_x + 16, center_y - 9, head_x + 28, center_y + 3), fill=(250, 246, 218, 248), outline=(15, 14, 13, 255), width=2)
        draw.ellipse((head_x + 20, center_y - 5, head_x + 25, center_y), fill=(10, 9, 8, 255))
        draw.line((head_x + 6, center_y + 9, head_x + 24, center_y + 16), fill=(66, 37, 26, 120), width=2)
    save(img, "fish_icon_sheet.png")


def fish_row_frame() -> None:
    w, h = 340, 82
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow, "RGBA")
    sd.rounded_rectangle((8, 12, w - 8, h - 7), radius=4, fill=(0, 0, 0, 150))
    shadow = shadow.filter(ImageFilter.GaussianBlur(5))
    img.alpha_composite(shadow)
    paper = reference_paper_texture((w - 16, h - 18), "f2dfad", 44, (76, 204, 458, 302), 0.52, 7.0)
    paste_rounded(img, paper, (6, 5, w - 10, h - 12), 5)
    draw = ImageDraw.Draw(img, "RGBA")

    # Ingredient rows should read as one mounted material slip, not separate
    # image/quantity widgets.
    draw.rounded_rectangle((5, 4, w - 10, h - 12), radius=5, outline=(49, 27, 13, 255), width=5)
    draw.rounded_rectangle((15, 13, w - 20, h - 22), radius=3, outline=(230, 178, 78, 205), width=2)
    draw.rounded_rectangle((13, 17, 22, h - 26), radius=2, fill=(10, 39, 64, 190), outline=(48, 28, 13, 180), width=1)
    draw.line((38, h - 27, w - 34, h - 27), fill=(136, 91, 44, 28), width=2)
    draw.line((224, h - 30, w - 44, h - 30), fill=(136, 91, 44, 16), width=1)
    draw_corner_brackets(draw, (18, 15, w - 22, h - 25), (246, 198, 83, 205), (51, 29, 13, 235), 16, 2)
    save(img, "fish_row_frame.png")


def dish_icon_sheet() -> None:
    cell_w, cell_h = 220, 150
    img = Image.new("RGBA", (cell_w * 3, cell_h * 2), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    for idx in range(6):
        col = idx % 3
        row = idx // 3
        x, y = col * cell_w, row * cell_h
        # Plate shadow and plate.
        draw.ellipse((x + 32, y + 104, x + 190, y + 136), fill=(41, 28, 21, 70))
        draw.ellipse((x + 28, y + 36, x + 194, y + 126), fill=(237, 227, 202, 255), outline=(95, 73, 55, 210), width=4)
        draw.ellipse((x + 46, y + 52, x + 176, y + 112), fill=(205, 193, 170, 255))
        if idx == 0:  # salt grill
            draw.ellipse((x + 58, y + 58, x + 156, y + 96), fill=(150, 91, 40, 255), outline=(28, 20, 16, 220), width=3)
            draw.polygon([(x + 154, y + 77), (x + 196, y + 52), (x + 184, y + 82), (x + 196, y + 108)], fill=(145, 92, 43, 255), outline=(28, 20, 16, 220))
            draw.ellipse((x + 68, y + 70, x + 78, y + 80), fill=(22, 18, 16, 255))
            draw.pieslice((x + 142, y + 72, x + 178, y + 108), 300, 80, fill=(251, 220, 102, 255))
            draw.rectangle((x + 82, y + 48, x + 132, y + 56), fill=(54, 97, 52, 230))
        elif idx == 1:  # sashimi
            for k in range(5):
                draw.rounded_rectangle((x + 62 + k * 18, y + 58 + k % 2 * 6, x + 98 + k * 18, y + 90 + k % 2 * 6), radius=10, fill=(232, 122, 112, 255), outline=(245, 232, 220, 255), width=3)
            draw.ellipse((x + 126, y + 84, x + 168, y + 110), fill=(46, 118, 58, 230))
        elif idx == 2:  # simmered
            draw.ellipse((x + 50, y + 48, x + 178, y + 114), fill=(112, 70, 38, 255), outline=(54, 32, 20, 255), width=4)
            draw.ellipse((x + 64, y + 58, x + 166, y + 104), fill=(90, 48, 25, 255))
            for k in range(3):
                draw.ellipse((x + 72 + k * 26, y + 64, x + 106 + k * 26, y + 92), fill=(189, 142, 83, 255))
        elif idx == 3:  # soup
            draw.ellipse((x + 50, y + 48, x + 178, y + 116), fill=(117, 72, 39, 255), outline=(55, 33, 22, 255), width=4)
            draw.ellipse((x + 66, y + 58, x + 162, y + 102), fill=(225, 194, 132, 255))
            for k in range(4):
                draw.ellipse((x + 74 + k * 20, y + 66 + (k % 2) * 10, x + 96 + k * 20, y + 88 + (k % 2) * 10), fill=(238, 224, 183, 255), outline=(116, 92, 55, 180))
        elif idx == 4:  # fry
            for k in range(3):
                draw.rounded_rectangle((x + 62 + k * 34, y + 58 + k % 2 * 10, x + 108 + k * 34, y + 98 + k % 2 * 10), radius=14, fill=(205, 128, 38, 255), outline=(104, 58, 24, 255), width=3)
            draw.ellipse((x + 122, y + 82, x + 172, y + 112), fill=(66, 135, 55, 230))
        else:  # recipe book / coming-soon card
            draw.ellipse((x + 52, y + 104, x + 170, y + 130), fill=(45, 31, 22, 72))
            draw.rounded_rectangle((x + 56, y + 50, x + 158, y + 112), radius=8, fill=(92, 58, 31, 245), outline=(45, 29, 18, 245), width=4)
            draw.rounded_rectangle((x + 72, y + 42, x + 174, y + 104), radius=8, fill=(239, 220, 174, 245), outline=(124, 84, 42, 230), width=4)
            draw.line((x + 119, y + 48, x + 119, y + 100), fill=(126, 85, 42, 150), width=2)
            draw.arc((x + 84, y + 58, x + 114, y + 92), 205, 335, fill=(72, 65, 46, 190), width=3)
            draw.ellipse((x + 92, y + 72, x + 126, y + 85), fill=(85, 93, 68, 150), outline=(55, 45, 31, 160), width=2)
            draw.polygon([(x + 126, y + 78), (x + 146, y + 66), (x + 140, y + 79), (x + 146, y + 91)], fill=(95, 92, 62, 150), outline=(55, 45, 31, 150))
            for yy in [58, 67, 88]:
                draw.line((x + 130, y + yy, x + 160, y + yy), fill=(130, 91, 48, 95), width=2)
    save(img, "dish_icon_sheet.png")


def dish_feature() -> None:
    w, h = 620, 330
    if COOK_SELECT_REFERENCE.exists():
        source = Image.open(COOK_SELECT_REFERENCE).convert("RGBA")
        crop = source.crop((1038, 222, 1512, 504))
        crop = ImageEnhance.Color(crop).enhance(1.06)
        crop = ImageEnhance.Contrast(crop).enhance(1.08)
        crop = ImageEnhance.Sharpness(crop).enhance(1.08)
        img = crop.resize((w, h), Image.Resampling.LANCZOS)
        glaze = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        gd = ImageDraw.Draw(glaze, "RGBA")
        gd.rectangle((0, 0, w, 18), fill=(255, 244, 214, 38))
        gd.rectangle((0, h - 22, w, h), fill=(48, 25, 12, 42))
        img.alpha_composite(glaze)
        save(img, "dish_feature_aji_shioyaki.png")
        return

    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    draw.rounded_rectangle((18, 22, w - 18, h - 22), radius=16, fill=(104, 65, 34, 245), outline=(225, 176, 96, 230), width=5)
    for x in range(28, w - 28, 32):
        draw.line((x, 30, x - 32, h - 32), fill=(77, 47, 28, 70), width=2)
    draw.ellipse((70, 196, 545, 292), fill=(38, 24, 18, 78))
    draw.ellipse((58, 70, 555, 276), fill=(230, 222, 199, 255), outline=(97, 70, 51, 240), width=6)
    draw.ellipse((90, 98, 520, 248), fill=(204, 194, 170, 255))
    draw.rectangle((166, 104, 410, 142), fill=(48, 104, 54, 210))
    draw.ellipse((132, 120, 405, 220), fill=(157, 92, 40, 255), outline=(28, 20, 16, 230), width=5)
    draw.polygon([(398, 166), (510, 96), (488, 168), (512, 238)], fill=(142, 88, 42, 255), outline=(28, 20, 16, 230))
    draw.polygon([(240, 112), (315, 62), (298, 130)], fill=(110, 78, 45, 255), outline=(28, 20, 16, 220))
    draw.ellipse((158, 150, 182, 174), fill=(244, 234, 204, 250), outline=(16, 14, 12, 255), width=3)
    draw.ellipse((166, 158, 174, 166), fill=(12, 10, 8, 255))
    for s in range(8):
        x = 220 + s * 22
        draw.arc((x, 126, x + 38, 208), 94, 268, fill=(245, 235, 205, 80), width=3)
    for dx, dy in [(430, 196), (454, 186), (470, 210)]:
        draw.ellipse((dx, dy, dx + 56, dy + 56), fill=(250, 222, 100, 255), outline=(124, 93, 32, 230), width=3)
        draw.line((dx + 8, dy + 46, dx + 48, dy + 10), fill=(255, 248, 185, 180), width=3)
    for _x, _y in [(394, 92), (420, 88), (444, 104), (386, 222), (212, 102)]:
        draw.ellipse((_x, _y, _x + 5, _y + 5), fill=(250, 246, 220, 190))
    save(img, "dish_feature_aji_shioyaki.png")


def cooking_title_banner() -> None:
    w, h = 420, 110
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow, "RGBA")
    sd.rounded_rectangle((18, 20, w - 20, h - 12), radius=12, fill=(0, 0, 0, 120))
    shadow = shadow.filter(ImageFilter.GaussianBlur(5))
    img.alpha_composite(shadow)
    draw = ImageDraw.Draw(img, "RGBA")

    # Hanging wooden sign for the COOK_SELECT title. Text is drawn in Godot.
    draw.rounded_rectangle((10, 8, w - 24, h - 20), radius=10, fill=(136, 82, 35, 255), outline=(52, 31, 16, 255), width=5)
    draw.rounded_rectangle((24, 20, w - 38, h - 34), radius=7, fill=(191, 127, 60, 250), outline=(236, 184, 95, 220), width=3)
    for y in [30, 54, 78]:
        draw.line((25, y, w - 39, y - 8), fill=(93, 54, 25, 120), width=3)
        draw.line((28, y + 9, w - 42, y + 1), fill=(228, 167, 77, 72), width=2)
    for x in range(50, w - 76, 58):
        draw.ellipse((x, 30, x + 7, 37), fill=(69, 39, 18, 160))
        draw.ellipse((x + 4, 69, x + 10, 75), fill=(69, 39, 18, 125))

    # Rope hangers.
    for x in [48, w - 74]:
        draw.line((x, 0, x + 4, 19), fill=(82, 54, 31, 255), width=7)
        draw.line((x + 10, 0, x + 6, 19), fill=(181, 128, 65, 230), width=4)
        draw.ellipse((x - 7, 13, x + 17, 37), outline=(57, 35, 18, 230), width=5)

    # Kitchen/fishing ornaments at both ends, kept outside the text center.
    leaf = (51, 128, 72, 240)
    for i, (lx, ly) in enumerate([(34, 66), (48, 58), (59, 72)]):
        draw.ellipse((lx - 12, ly - 6, lx + 14, ly + 9), fill=leaf, outline=(24, 70, 38, 190), width=2)
        draw.line((lx - 10, ly + 1, lx + 12, ly + 1), fill=(185, 217, 126, 120), width=2)
    fish_cx, fish_cy = w - 80, 56
    draw.ellipse((fish_cx - 34, fish_cy - 13, fish_cx + 24, fish_cy + 14), fill=(44, 111, 151, 235), outline=(14, 43, 63, 230), width=3)
    draw.polygon(
        [(fish_cx + 20, fish_cy), (fish_cx + 52, fish_cy - 20), (fish_cx + 44, fish_cy), (fish_cx + 52, fish_cy + 20)],
        fill=(44, 111, 151, 230),
        outline=(14, 43, 63, 210),
    )
    draw.ellipse((fish_cx - 24, fish_cy - 5, fish_cx - 17, fish_cy + 2), fill=(255, 242, 204, 255))
    draw.ellipse((fish_cx - 21, fish_cy - 3, fish_cx - 18, fish_cy), fill=(8, 12, 15, 255))
    for s in range(3):
        x = fish_cx - 2 + s * 9
        draw.arc((x, fish_cy - 12, x + 14, fish_cy + 13), 95, 265, fill=(226, 246, 255, 105), width=2)

    # Warm title glow behind the Godot label.
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow, "RGBA")
    gd.ellipse((94, 28, 282, 92), fill=(255, 221, 119, 44))
    glow = glow.filter(ImageFilter.GaussianBlur(12))
    img.alpha_composite(glow)

    save(img, "cooking_title_banner.png")


def cooking_section_ribbon() -> None:
    w, h = 520, 72
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow, "RGBA")
    sd.rounded_rectangle((34, 20, w - 34, h - 10), radius=8, fill=(0, 0, 0, 105))
    shadow = shadow.filter(ImageFilter.GaussianBlur(4))
    img.alpha_composite(shadow)
    draw = ImageDraw.Draw(img, "RGBA")

    navy = (18, 48, 78, 252)
    navy_hi = (29, 77, 116, 235)
    edge = (61, 37, 20, 255)
    gold = (230, 177, 83, 245)
    cloth_shadow = (7, 21, 37, 210)

    # Tails are outside the 9-slice center so the ribbon reads as cloth/wood trim.
    draw.polygon([(10, 28), (48, 10), (64, 34), (48, 60), (10, 44)], fill=cloth_shadow, outline=edge)
    draw.polygon([(w - 10, 28), (w - 48, 10), (w - 64, 34), (w - 48, 60), (w - 10, 44)], fill=cloth_shadow, outline=edge)
    draw.rounded_rectangle((38, 8, w - 38, h - 16), radius=9, fill=navy, outline=edge, width=5)
    draw.rounded_rectangle((52, 18, w - 52, h - 26), radius=5, fill=navy_hi, outline=gold, width=2)
    draw.rectangle((54, 20, w - 54, 31), fill=(45, 103, 145, 92))
    draw.line((58, h - 28, w - 58, h - 28), fill=(4, 16, 30, 120), width=2)
    for x in range(72, w - 72, 54):
        draw.line((x, 21, x - 22, h - 30), fill=(255, 255, 255, 22), width=2)
    for x, y in [(50, 16), (w - 62, 16), (50, h - 31), (w - 62, h - 31)]:
        draw.rectangle((x, y, x + 10, y + 10), fill=gold, outline=edge, width=2)
    for x in [83, w - 94]:
        draw.line((x, 2, x + 10, 14), fill=(132, 88, 43, 210), width=4)
        draw.line((x - 3, 4, x + 13, 18), fill=(61, 37, 20, 180), width=2)
    save(img, "cooking_section_ribbon.png")


def recipe_to_detail_arrow() -> None:
    w, h = 96, 220
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow, "RGBA")
    for r in range(58, 8, -5):
        alpha = int(86 * (1 - r / 58) ** 1.5)
        gd.ellipse((48 - r, 110 - r, 48 + r, 110 + r), fill=(255, 190, 55, alpha))
    glow = glow.filter(ImageFilter.GaussianBlur(3))
    img.alpha_composite(glow)
    draw = ImageDraw.Draw(img, "RGBA")

    # Bridge from the selected recipe card toward the large dish detail.
    # The reference uses this as a strong visual read, not as text.
    tail = [(12, 91), (45, 91), (45, 69), (86, 110), (45, 151), (45, 129), (12, 129)]
    outline = [(7, 86), (39, 86), (39, 57), (95, 110), (39, 163), (39, 134), (7, 134)]
    draw.polygon(outline, fill=(62, 32, 9, 235))
    draw.polygon(tail, fill=(244, 161, 31, 255), outline=(255, 234, 139, 245))
    inner = [(21, 100), (53, 100), (53, 86), (75, 110), (53, 134), (53, 120), (21, 120)]
    draw.polygon(inner, fill=(255, 232, 96, 250), outline=(141, 78, 15, 190))
    draw.line((17, 95, 47, 95), fill=(255, 249, 196, 185), width=3)
    draw.line((17, 126, 47, 126), fill=(112, 63, 15, 150), width=3)
    for x, y in [(28, 64), (72, 72), (68, 150), (26, 156), (83, 112)]:
        draw.line((x - 5, y, x + 5, y), fill=(255, 241, 174, 185), width=2)
        draw.line((x, y - 5, x, y + 5), fill=(255, 241, 174, 185), width=2)
    save(img, "recipe_to_detail_arrow.png")


def recipe_selected_card_frame() -> None:
    w, h = 280, 220
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow, "RGBA")
    sd.rounded_rectangle((12, 15, w - 10, h - 7), radius=12, fill=(0, 0, 0, 142))
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(4)))

    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow, "RGBA")
    for offset, alpha, width in [(0, 132, 8), (5, 84, 6), (12, 42, 4), (19, 20, 3)]:
        gd.rounded_rectangle(
            (9 - offset, 9 - offset, w - 16 + offset, h - 14 + offset),
            radius=12 + offset,
            outline=(255, 190, 45, alpha),
            width=width,
        )
    glow = glow.filter(ImageFilter.GaussianBlur(3))
    img.alpha_composite(glow)

    paper = reference_paper_texture((w - 24, h - 22), "f2deaa", 72, (496, 204, 650, 438), 0.48, 6.0)
    paste_rounded(img, paper, (8, 8, w - 16, h - 14), 9, 252)
    draw = ImageDraw.Draw(img, "RGBA")

    # Three sockets mirror the concept art: runtime title, dish art, then
    # runtime rank/materials. No text is baked into the PNG.
    draw.rounded_rectangle((7, 7, w - 16, h - 14), radius=9, outline=(62, 35, 15, 255), width=6)
    draw.rounded_rectangle((14, 14, w - 23, h - 21), radius=8, outline=(255, 225, 103, 255), width=4)
    draw.rounded_rectangle((24, 22, w - 33, 60), radius=7, fill=(92, 50, 21, 236), outline=(255, 232, 125, 238), width=3)
    draw.rounded_rectangle((34, 30, w - 43, 52), radius=5, fill=(255, 242, 190, 50), outline=(120, 70, 25, 130), width=1)
    draw.rounded_rectangle((28, 64, w - 37, 154), radius=8, fill=(88, 53, 29, 132), outline=(83, 48, 23, 230), width=4)
    draw.rounded_rectangle((42, 76, w - 51, 145), radius=7, fill=(255, 238, 196, 58), outline=(255, 222, 105, 160), width=2)
    draw.rounded_rectangle((31, 158, w - 40, h - 31), radius=7, fill=(87, 49, 21, 120), outline=(167, 103, 38, 178), width=2)
    draw.rounded_rectangle((45, 169, w - 54, h - 42), radius=5, fill=(255, 241, 194, 54), outline=(255, 226, 119, 118), width=1)
    draw.line((50, 164, w - 59, 164), fill=(255, 231, 98, 168), width=2)
    draw.line((54, h - 39, w - 63, h - 39), fill=(92, 55, 28, 94), width=2)
    draw_corner_brackets(draw, (18, 18, w - 30, h - 29), (255, 222, 96, 255), (60, 34, 14, 248), 22, 4)
    for x, y in [(35, 35), (w - 54, 35), (35, h - 46), (w - 54, h - 46)]:
        draw.rectangle((x - 6, y - 6, x + 6, y + 6), fill=(255, 227, 98, 255), outline=(77, 43, 15, 238), width=1)
    for x, y in [(54, 68), (226, 70), (54, 158), (224, 156), (140, 25), (140, 178)]:
        draw.line((x - 5, y, x + 5, y), fill=(255, 247, 178, 158), width=2)
        draw.line((x, y - 5, x, y + 5), fill=(255, 247, 178, 158), width=2)
    save(img, "recipe_selected_card_frame.png")


def recipe_material_strip_frame() -> None:
    w, h = 240, 54
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow, "RGBA")
    sd.rounded_rectangle((7, 8, w - 7, h - 4), radius=8, fill=(0, 0, 0, 110))
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(3)))
    paper = reference_paper_texture((w - 18, h - 14), "f4dfab", 151, (440, 614, 622, 664), 0.46, 5.0)
    paste_rounded(img, paper, (6, 6, w - 8, h - 8), 7, 246)
    draw = ImageDraw.Draw(img, "RGBA")

    # Footer socket for the runtime fish/material icon.
    draw.rounded_rectangle((6, 6, w - 8, h - 8), radius=7, outline=(74, 43, 18, 252), width=3)
    draw.rounded_rectangle((17, 13, w - 20, h - 15), radius=6, fill=(255, 241, 199, 56), outline=(135, 82, 33, 104), width=1)
    draw.line((35, 16, w - 41, 16), fill=(255, 233, 139, 96), width=2)
    draw.line((38, h - 18, w - 44, h - 18), fill=(112, 67, 26, 64), width=2)
    for x, y in [(14, 12), (w - 28, 12), (14, h - 28), (w - 28, h - 28)]:
        draw.rectangle((x, y, x + 9, y + 9), fill=(231, 174, 69, 218), outline=(58, 33, 14, 225), width=1)
    save(img, "recipe_material_strip_frame.png")


def cook_detail_row_frame() -> None:
    w, h = 560, 46
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow, "RGBA")
    sd.rounded_rectangle((8, 10, w - 8, h - 5), radius=8, fill=(0, 0, 0, 108))
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(3)))
    paper = reference_paper_texture((w - 18, h - 14), "f5dfad", 149, (1042, 558, 1534, 728), 0.46, 4.0)
    paste_rounded(img, paper, (6, 6, w - 8, h - 8), 6, 248)
    draw = ImageDraw.Draw(img, "RGBA")

    # Detail rows are story ribbons: title/icon socket, value field, and a
    # right-side badge pocket for stock/bonus/count.
    draw.rounded_rectangle((6, 6, w - 8, h - 8), radius=6, outline=(82, 48, 22, 250), width=3)
    draw.rounded_rectangle((16, 10, 190, h - 11), radius=6, fill=(72, 43, 21, 232), outline=(47, 28, 14, 230), width=2)
    draw.rounded_rectangle((24, 15, 58, h - 15), radius=5, fill=(255, 231, 149, 52), outline=(232, 174, 68, 86), width=1)
    draw.line((66, 14, 66, h - 15), fill=(255, 226, 126, 58), width=1)
    draw.line((201, 12, 201, h - 13), fill=(80, 47, 20, 70), width=2)
    draw.line((214, h - 16, w - 102, h - 16), fill=(117, 73, 34, 42), width=2)
    draw.rectangle((216, 17, w - 108, 24), fill=(255, 245, 205, 24))
    draw.rounded_rectangle((w - 92, 12, w - 26, h - 12), radius=5, fill=(255, 237, 190, 58), outline=(126, 79, 35, 92), width=1)
    draw.line((w - 86, h - 17, w - 32, h - 17), fill=(122, 76, 34, 56), width=2)
    for x, y in [(14, 11), (w - 30, 11), (14, h - 23), (w - 30, h - 23)]:
        draw.rectangle((x, y, x + 8, y + 8), fill=(232, 174, 68, 204), outline=(58, 32, 13, 218), width=1)
    draw_corner_brackets(draw, (13, 11, w - 26, h - 18), (234, 181, 80, 128), (59, 34, 16, 182), 12, 1)
    save(img, "cook_detail_row_frame.png")


def cook_button_frame() -> None:
    w, h = 360, 82
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow, "RGBA")
    sd.rounded_rectangle((18, 18, w - 12, h - 8), radius=10, fill=(0, 0, 0, 128))
    shadow = shadow.filter(ImageFilter.GaussianBlur(5))
    img.alpha_composite(shadow)
    draw = ImageDraw.Draw(img, "RGBA")

    # Primary COOK_SELECT action button: a chunky navy plank like the reference CTA.
    draw.rounded_rectangle((7, 7, w - 13, h - 15), radius=8, fill=(50, 29, 12, 255), outline=(28, 17, 8, 255), width=5)
    draw.rounded_rectangle((18, 17, w - 24, h - 25), radius=5, fill=(9, 38, 67, 255), outline=(255, 207, 83, 245), width=4)
    draw.rectangle((30, 24, w - 36, 38), fill=(39, 112, 162, 52))
    draw.line((32, h - 31, w - 38, h - 31), fill=(1, 10, 24, 120), width=3)
    draw.rounded_rectangle((32, 20, 92, h - 28), radius=7, fill=(6, 24, 41, 124), outline=(255, 224, 105, 150), width=2)
    draw.line((108, 22, 108, h - 31), fill=(255, 213, 87, 48), width=1)
    for x, y in [(20, 18), (w - 42, 18), (20, h - 48), (w - 42, h - 48)]:
        draw.rectangle((x, y, x + 14, y + 14), fill=(255, 206, 73, 235), outline=(57, 32, 14, 255), width=2)
    save(img, "cook_button_frame.png")


def cook_action_runway_frame() -> None:
    w, h = 560, 88
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow, "RGBA")
    sd.rounded_rectangle((12, 12, w - 10, h - 6), radius=9, fill=(0, 0, 0, 105))
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(4)))
    paper = reference_paper_texture((w - 22, h - 20), "ead6ad", 131, (1032, 688, 1538, 792), 0.35, 8.0)
    paste_rounded(img, paper, (8, 7, w - 14, h - 13), 8, 245)
    draw = ImageDraw.Draw(img, "RGBA")

    # A unified landing strip for the final cook action. The CTA supplies its
    # own navy plank, so this frame stays quiet and parchment-led.
    draw.rounded_rectangle((7, 7, w - 14, h - 13), radius=8, outline=(72, 43, 19, 245), width=4)
    draw.rounded_rectangle((22, 15, w - 30, 32), radius=5, fill=(248, 229, 184, 28), outline=(147, 94, 43, 24), width=1)
    draw.line((42, 25, w - 44, 25), fill=(104, 65, 32, 24), width=2)
    for x, y in [(22, 15), (w - 46, 15), (22, h - 39), (w - 46, h - 39)]:
        draw.rectangle((x, y, x + 13, y + 13), fill=(230, 174, 72, 205), outline=(57, 32, 14, 225), width=2)
    draw.line((82, h - 20, w - 82, h - 20), fill=(255, 226, 113, 30), width=2)
    save(img, "cook_action_runway_frame.png")


def prep_summary_bar_frame() -> None:
    w, h = 1280, 92
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    draw.rectangle((0, 0, w, h), fill=(40, 23, 11, 246))
    paper = reference_paper_texture((w - 18, h - 18), "ead6ad", 187, (74, 670, 1168, 720), 0.40, 6.0)
    paste_rounded(img, paper, (4, 7, w - 6, h - 8), 6, 246)
    draw = ImageDraw.Draw(img, "RGBA")

    # Four-slot bottom tray: player level, active meal, cooler, and money.
    # Runtime text/icons sit on top; the PNG only supplies the compartments.
    draw.rounded_rectangle((3, 6, w - 7, h - 8), radius=6, outline=(67, 38, 16, 255), width=5)
    draw.rounded_rectangle((16, 16, w - 20, h - 18), radius=6, outline=(232, 174, 68, 118), width=2)
    draw.line((28, 18, w - 28, 18), fill=(255, 220, 102, 118), width=2)
    draw.line((28, h - 20, w - 28, h - 20), fill=(109, 67, 27, 112), width=3)
    slot_w = (w - 44) / 4.0
    for i in range(4):
        x0 = int(22 + slot_w * i)
        x1 = int(22 + slot_w * (i + 1) - 8)
        draw.rounded_rectangle((x0, 20, x1, h - 22), radius=5, fill=(255, 239, 194, 34), outline=(83, 49, 20, 62), width=1)
        draw.line((x0 + 88, 24, x0 + 88, h - 26), fill=(83, 49, 20, 52), width=2)
        draw.line((x0 + 96, 28, x0 + 96, h - 30), fill=(255, 236, 160, 36), width=1)
        if i > 0:
            sep = x0 - 7
            draw.line((sep, 17, sep, h - 19), fill=(71, 39, 16, 168), width=4)
            draw.line((sep + 4, 23, sep + 4, h - 25), fill=(255, 226, 126, 80), width=1)
        for y in [25, h - 35]:
            draw.rectangle((x0 + 8, y, x0 + 18, y + 10), fill=(232, 174, 68, 190), outline=(58, 32, 13, 210), width=1)
            draw.rectangle((x1 - 18, y, x1 - 8, y + 10), fill=(232, 174, 68, 190), outline=(58, 32, 13, 210), width=1)
    for x, y in [(16, 16), (w - 30, 16), (16, h - 32), (w - 30, h - 32)]:
        draw.rectangle((x, y, x + 11, y + 11), fill=(232, 174, 68, 218), outline=(58, 32, 13, 240), width=2)
    save(img, "prep_summary_bar_frame.png")


def prep_summary_card_frame() -> None:
    w, h = 340, 62
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow, "RGBA")
    sd.rounded_rectangle((8, 10, w - 6, h - 5), radius=7, fill=(0, 0, 0, 98))
    img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(3)))
    paper = reference_paper_texture((w - 18, h - 16), "f2e0b8", 207, (226, 680, 492, 720), 0.42, 5.0)
    paste_rounded(img, paper, (6, 6, w - 8, h - 8), 6, 246)
    draw = ImageDraw.Draw(img, "RGBA")

    # Reusable bottom-slot card. Large emblem on the left, compact label/value
    # stack on the right; no text is baked into the PNG.
    draw.rounded_rectangle((6, 6, w - 8, h - 8), radius=6, outline=(82, 47, 20, 250), width=3)
    draw.rounded_rectangle((16, 12, 78, h - 12), radius=6, fill=(250, 226, 179, 88), outline=(126, 79, 35, 86), width=1)
    draw.ellipse((27, 18, 67, h - 18), fill=(255, 242, 204, 52), outline=(232, 174, 68, 70), width=1)
    draw.line((90, 14, 90, h - 16), fill=(94, 57, 24, 78), width=2)
    draw.line((98, 27, w - 34, 27), fill=(120, 75, 34, 58), width=1)
    draw.line((98, h - 17, w - 34, h - 17), fill=(122, 76, 34, 52), width=2)
    draw.rectangle((100, 33, w - 36, 39), fill=(255, 245, 205, 28))
    for x, y in [(14, 12), (w - 28, 12), (14, h - 28), (w - 28, h - 28)]:
        draw.rectangle((x, y, x + 9, y + 9), fill=(232, 174, 68, 214), outline=(58, 32, 13, 228), width=1)
    save(img, "prep_summary_card_frame.png")


def flow_action_button_frame() -> None:
    w, h = 380, 88
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow, "RGBA")
    sd.rounded_rectangle((18, 18, w - 12, h - 8), radius=8, fill=(0, 0, 0, 145))
    shadow = shadow.filter(ImageFilter.GaussianBlur(6))
    img.alpha_composite(shadow)
    draw = ImageDraw.Draw(img, "RGBA")

    # Shared primary action button for MEAL_RESULT, EXP_GAIN, LEVEL_UP, and
    # STATUS_SUMMARY. The left medallion is reserved for state-specific cues.
    draw.rounded_rectangle((8, 8, w - 14, h - 16), radius=8, fill=(5, 20, 39, 255), outline=(45, 25, 10, 255), width=5)
    draw.rounded_rectangle((20, 18, w - 26, h - 26), radius=5, fill=(12, 45, 81, 250), outline=(255, 202, 73, 235), width=3)
    draw.rectangle((28, 24, w - 36, 40), fill=(38, 96, 143, 105))
    draw.line((32, h - 32, w - 40, h - 32), fill=(0, 11, 24, 170), width=3)
    draw.rounded_rectangle((34, 20, 100, h - 28), radius=7, fill=(8, 22, 37, 170), outline=(255, 215, 92, 160), width=2)
    draw.ellipse((45, 25, 89, h - 33), fill=(17, 47, 78, 210), outline=(255, 224, 113, 145), width=2)
    draw.line((116, 24, 116, h - 31), fill=(255, 215, 92, 78), width=2)
    for x in range(130, w - 64, 44):
        draw.line((x, 25, x - 28, h - 34), fill=(255, 255, 255, 22), width=2)
    for x, y in [(20, 18), (w - 42, 18), (20, h - 48), (w - 42, h - 48)]:
        draw.rectangle((x, y, x + 14, y + 14), fill=(255, 204, 70, 238), outline=(45, 25, 10, 255), width=2)
    for x, y in [(122, 21), (w - 66, 22), (w - 70, 60)]:
        draw.line((x - 5, y, x + 5, y), fill=(255, 246, 174, 150), width=2)
        draw.line((x, y - 5, x, y + 5), fill=(255, 246, 174, 150), width=2)
    save(img, "flow_action_button_frame.png")


def player_eating_pose() -> None:
    w, h = 360, 280
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    draw.ellipse((58, 226, 306, 262), fill=(0, 0, 0, 58))

    # Chair and table edge, so the sprite reads as part of the meal scene.
    draw.rounded_rectangle((44, 136, 130, 230), radius=16, fill=(76, 44, 24, 210), outline=(36, 24, 18, 190), width=4)
    draw.rounded_rectangle((84, 202, 332, 250), radius=18, fill=(116, 63, 29, 235), outline=(58, 35, 20, 220), width=4)
    for x in range(110, 320, 34):
        draw.line((x, 207, x - 18, 246), fill=(64, 38, 22, 90), width=2)

    # Body.
    draw.rounded_rectangle((96, 118, 210, 218), radius=28, fill=(24, 68, 108, 255), outline=(10, 26, 44, 235), width=4)
    draw.rectangle((96, 126, 210, 146), fill=(41, 96, 139, 240))
    draw.polygon([(104, 132), (52, 174), (68, 192), (122, 160)], fill=(242, 184, 137, 255), outline=(68, 39, 28, 180))
    draw.polygon([(194, 132), (256, 178), (238, 197), (182, 158)], fill=(242, 184, 137, 255), outline=(68, 39, 28, 180))

    # Head, hair, cap.
    draw.ellipse((91, 42, 189, 136), fill=(242, 184, 137, 255), outline=(45, 27, 18, 235), width=4)
    hair = [(84, 78), (98, 35), (122, 54), (144, 28), (156, 58), (187, 42), (196, 84)]
    draw.polygon(hair, fill=(45, 30, 24, 255), outline=(20, 14, 12, 220))
    draw.pieslice((79, 22, 197, 92), 184, 358, fill=(33, 80, 126, 255), outline=(14, 35, 64, 230), width=4)
    draw.rectangle((108, 26, 174, 47), fill=(235, 238, 226, 255), outline=(20, 52, 84, 230), width=3)
    draw.ellipse((137, 27, 159, 47), fill=(124, 168, 185, 180))
    draw.ellipse((116, 88, 124, 97), fill=(18, 14, 12, 255))
    draw.ellipse((158, 87, 167, 96), fill=(18, 14, 12, 255))
    draw.arc((126, 100, 161, 125), 12, 168, fill=(111, 44, 30, 255), width=5)

    # Bowl, chopsticks, food, and steam.
    draw.line((52, 169, 132, 126), fill=(217, 156, 83, 255), width=5)
    draw.line((58, 178, 137, 132), fill=(111, 65, 36, 255), width=3)
    draw.ellipse((218, 172, 306, 218), fill=(36, 24, 18, 92))
    draw.arc((218, 152, 306, 218), 0, 180, fill=(255, 244, 218, 255), width=8)
    draw.arc((226, 140, 298, 204), 0, 180, fill=(176, 88, 37, 255), width=9)
    for cx, cy in [(244, 149), (260, 142), (276, 151), (252, 160)]:
        draw.ellipse((cx, cy, cx + 18, cy + 16), fill=(255, 249, 224, 245))
    for i, sx in enumerate([218, 246, 283]):
        draw.arc((sx, 70 + i * 8, sx + 42, 150 + i * 10), 105, 255, fill=(255, 235, 197, 92), width=4)

    save(img, "player_eating_pose.png")


def meal_table_spread() -> None:
    w, h = 420, 190
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")

    # Wide table foreground for the MEAL_RESULT scene. The dish itself is
    # rebuilt from the high-density featured-dish slot, then clipped to a
    # platter silhouette so the table scene never becomes a rectangular card.
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow, "RGBA")
    shadow_draw.ellipse((14, 142, 406, 186), fill=(0, 0, 0, 84))
    shadow = shadow.filter(ImageFilter.GaussianBlur(3))
    img.alpha_composite(shadow)

    draw.rounded_rectangle((14, 126, 406, 178), radius=20, fill=(108, 57, 26, 238), outline=(46, 28, 17, 220), width=4)
    draw.rectangle((24, 132, 396, 146), fill=(171, 99, 45, 130))
    draw.line((20, 126, 400, 126), fill=(244, 177, 82, 118), width=2)
    for x in range(36, 398, 38):
        draw.line((x, 129, x - 26, 178), fill=(42, 24, 16, 84), width=2)
        draw.line((x + 14, 132, x - 4, 174), fill=(217, 137, 61, 40), width=1)

    draw.polygon([(65, 119), (350, 112), (386, 157), (42, 164)], fill=(42, 72, 57, 95))
    draw.line((58, 122, 358, 115), fill=(238, 206, 132, 75), width=2)

    feature_path = OUT / "dish_feature_aji_shioyaki.png"
    if feature_path.exists():
        source = Image.open(feature_path).convert("RGBA")
        crop = source.crop((40, 54, 594, 294))
        crop = ImageEnhance.Color(crop).enhance(1.10)
        crop = ImageEnhance.Contrast(crop).enhance(1.10)
        crop = ImageEnhance.Sharpness(crop).enhance(1.22)
        plate_size = (336, 146)
        crop = crop.resize(plate_size, Image.Resampling.LANCZOS)

        mask = Image.new("L", plate_size, 0)
        mask_draw = ImageDraw.Draw(mask)
        mask_draw.ellipse((7, 9, 329, 132), fill=255)
        mask_draw.polygon(
            [
                (12, 67),
                (54, 41),
                (96, 22),
                (139, 8),
                (192, 20),
                (252, 36),
                (314, 59),
                (326, 94),
                (255, 125),
                (70, 120),
            ],
            fill=255,
        )
        mask = mask.filter(ImageFilter.GaussianBlur(0.35))

        plate = Image.new("RGBA", plate_size, (0, 0, 0, 0))
        plate.alpha_composite(crop)
        plate.putalpha(Image.composite(plate.getchannel("A"), Image.new("L", plate_size, 0), mask))

        rim = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        rim_draw = ImageDraw.Draw(rim, "RGBA")
        rim_draw.ellipse((51, 45, 392, 151), fill=(0, 0, 0, 70))
        rim_draw.ellipse((51, 35, 390, 144), outline=(250, 235, 199, 190), width=5)
        rim_draw.ellipse((67, 48, 374, 132), outline=(83, 65, 48, 150), width=3)
        img.alpha_composite(rim)
        img.alpha_composite(plate, (43, 23))
        draw = ImageDraw.Draw(img, "RGBA")

        for x, y in [(150, 119), (166, 123), (183, 117), (209, 122), (226, 118), (242, 123), (262, 113), (286, 106), (300, 118)]:
            draw.ellipse((x, y, x + 4, y + 3), fill=(255, 246, 216, 205))
        for x, y in [(179, 67), (206, 72), (232, 76), (258, 82)]:
            draw.line((x, y, x + 14, y + 28), fill=(45, 25, 14, 150), width=2)
            draw.line((x + 2, y, x + 16, y + 27), fill=(255, 223, 163, 68), width=1)
    else:
        draw.ellipse((62, 38, 344, 142), fill=(219, 205, 175, 255), outline=(84, 63, 46, 245), width=5)
        draw.polygon([(94, 78), (222, 50), (316, 98), (158, 118)], fill=(42, 92, 52, 235))
        draw.ellipse((98, 72, 262, 116), fill=(155, 86, 35, 255), outline=(28, 20, 14, 235), width=4)
        draw.polygon([(254, 94), (330, 58), (312, 94), (330, 130)], fill=(207, 139, 45, 255), outline=(55, 35, 20, 220))
        draw.ellipse((112, 84, 130, 102), fill=(247, 238, 210, 255), outline=(18, 15, 12, 255), width=2)
        for s in range(6):
            x = 144 + s * 20
            draw.line((x, 75, x + 12, 112), fill=(64, 31, 17, 190), width=3)

    # Side dishes and cup, matching the reference table density.
    draw.ellipse((18, 122, 78, 160), fill=(42, 24, 16, 90))
    draw.rounded_rectangle((28, 90, 66, 144), radius=10, fill=(83, 51, 26, 255), outline=(44, 27, 16, 230), width=3)
    draw.arc((22, 98, 46, 128), 95, 265, fill=(185, 117, 58, 220), width=5)
    draw.rectangle((32, 96, 62, 106), fill=(122, 75, 34, 235))

    draw.ellipse((292, 146, 380, 184), fill=(0, 0, 0, 72))
    draw.arc((300, 119, 374, 182), 0, 180, fill=(255, 244, 218, 255), width=8)
    draw.arc((309, 111, 365, 169), 0, 180, fill=(175, 89, 39, 255), width=8)
    for cx, cy in [(318, 117), (334, 111), (350, 116), (340, 126), (358, 126)]:
        draw.ellipse((cx, cy, cx + 15, cy + 13), fill=(255, 250, 228, 246))

    for i, sx in enumerate([116, 172, 232, 346]):
        draw.arc((sx, 8 + (i % 2) * 8, sx + 34, 86 + (i % 2) * 9), 105, 250, fill=(255, 235, 197, 88), width=4)
    for i, (sx, sy) in enumerate([(84, 42), (304, 34), (366, 62), (70, 80)]):
        col = (255, 224, 129, 220) if i % 2 == 0 else (255, 246, 199, 190)
        draw.line((sx - 6, sy, sx + 6, sy), fill=col, width=3)
        draw.line((sx, sy - 6, sx, sy + 6), fill=col, width=3)

    save(img, "meal_table_spread.png")


def player_status_portrait() -> None:
    w, h = 240, 240
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    draw.ellipse((38, 198, 204, 226), fill=(0, 0, 0, 58))
    draw.rounded_rectangle((50, 132, 190, 226), radius=24, fill=(24, 68, 108, 255), outline=(9, 25, 43, 235), width=4)
    draw.rectangle((50, 140, 190, 162), fill=(43, 99, 143, 240))
    draw.polygon([(66, 148), (36, 206), (65, 212), (94, 166)], fill=(23, 58, 91, 255))
    draw.polygon([(174, 148), (204, 206), (175, 212), (146, 166)], fill=(23, 58, 91, 255))

    draw.ellipse((64, 56, 176, 164), fill=(242, 184, 137, 255), outline=(45, 27, 18, 235), width=4)
    draw.polygon(
        [(58, 94), (70, 42), (96, 62), (120, 32), (139, 63), (176, 47), (184, 97)],
        fill=(43, 29, 24, 255),
        outline=(20, 14, 12, 220),
    )
    draw.pieslice((53, 28, 187, 99), 184, 358, fill=(34, 80, 126, 255), outline=(13, 35, 64, 230), width=4)
    draw.rectangle((82, 31, 160, 56), fill=(235, 238, 226, 255), outline=(20, 52, 84, 230), width=3)
    draw.ellipse((108, 32, 134, 57), fill=(117, 165, 187, 190))
    draw.line((121, 35, 121, 53), fill=(34, 80, 126, 220), width=3)
    draw.line((113, 43, 129, 43), fill=(34, 80, 126, 220), width=3)
    draw.ellipse((91, 106, 101, 116), fill=(18, 14, 12, 255))
    draw.ellipse((139, 106, 149, 116), fill=(18, 14, 12, 255))
    draw.arc((101, 123, 141, 148), 15, 165, fill=(105, 42, 28, 255), width=5)
    draw.line((67, 180, 35, 222), fill=(183, 121, 61, 255), width=5)
    draw.line((35, 222, 28, 235), fill=(255, 240, 180, 255), width=3)

    save(img, "player_status_portrait.png")


def player_exp_message_pose() -> None:
    w, h = 180, 130
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    draw.ellipse((28, 102, 150, 123), fill=(0, 0, 0, 55))

    # Body leaning forward with a cooked dish, for the EXP message panel.
    draw.rounded_rectangle((54, 62, 126, 116), radius=17, fill=(24, 68, 108, 255), outline=(8, 27, 48, 230), width=3)
    draw.rectangle((54, 70, 126, 82), fill=(43, 99, 143, 235))
    draw.polygon([(58, 75), (29, 101), (42, 113), (74, 88)], fill=(242, 184, 137, 255), outline=(68, 39, 28, 165))
    draw.polygon([(122, 75), (150, 100), (137, 113), (106, 88)], fill=(242, 184, 137, 255), outline=(68, 39, 28, 165))

    draw.ellipse((52, 22, 128, 91), fill=(242, 184, 137, 255), outline=(45, 27, 18, 235), width=3)
    draw.polygon([(47, 54), (58, 18), (75, 34), (91, 13), (104, 35), (129, 23), (134, 57)], fill=(45, 30, 24, 255), outline=(20, 14, 12, 210))
    draw.pieslice((45, 9, 135, 58), 184, 358, fill=(34, 80, 126, 255), outline=(14, 35, 64, 230), width=3)
    draw.rectangle((68, 12, 112, 29), fill=(235, 238, 226, 255), outline=(20, 52, 84, 230), width=2)
    draw.ellipse((82, 13, 99, 30), fill=(124, 168, 185, 180))
    draw.ellipse((73, 57, 80, 65), fill=(18, 14, 12, 255))
    draw.ellipse((102, 57, 109, 65), fill=(18, 14, 12, 255))
    draw.arc((78, 66, 106, 86), 12, 168, fill=(111, 44, 30, 255), width=4)

    # Dish and EXP sparks.
    draw.ellipse((54, 91, 126, 119), fill=(44, 25, 16, 82))
    draw.arc((54, 76, 126, 119), 0, 180, fill=(255, 244, 218, 255), width=6)
    draw.arc((62, 68, 118, 111), 0, 180, fill=(176, 88, 37, 255), width=7)
    for cx, cy in [(73, 73), (88, 69), (101, 74)]:
        draw.ellipse((cx, cy, cx + 12, cy + 11), fill=(255, 249, 224, 245))
    for i, (sx, sy) in enumerate([(31, 35), (141, 37), (150, 72), (25, 77)]):
        col = (255, 224, 129, 210) if i % 2 == 0 else (107, 241, 255, 190)
        draw.line((sx - 6, sy, sx + 6, sy), fill=col, width=3)
        draw.line((sx, sy - 6, sx, sy + 6), fill=col, width=3)
    draw.arc((129, 26, 170, 89), 95, 255, fill=(255, 235, 197, 88), width=3)
    save(img, "player_exp_message_pose.png")


def next_effect_art() -> None:
    w, h = 280, 120
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")

    # Compact illustration for the EXP_GAIN "next fishing effect" card.
    draw.rounded_rectangle((8, 8, w - 8, h - 8), radius=16, fill=(14, 54, 36, 252), outline=(142, 230, 91, 230), width=4)
    draw.rounded_rectangle((18, 18, w - 18, h - 18), radius=12, fill=(20, 80, 50, 160), outline=(255, 224, 129, 130), width=2)
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow, "RGBA")
    for r in range(118, 12, -8):
        a = int(76 * (1 - r / 118) ** 1.65)
        gd.ellipse((140 - r, 58 - r, 140 + r, 58 + r), fill=(120, 255, 108, a))
    glow = glow.filter(ImageFilter.GaussianBlur(2))
    img.alpha_composite(glow)
    draw = ImageDraw.Draw(img, "RGBA")

    center = (134, 60)
    for i in range(18):
        angle = math.tau * i / 18.0
        inner = 28 + (i % 3) * 3
        outer = 86 + (i % 4) * 6
        col = (255, 224, 129, 120) if i % 2 else (107, 241, 255, 110)
        draw.line(
            (
                center[0] + math.cos(angle) * inner,
                center[1] + math.sin(angle) * inner,
                center[0] + math.cos(angle) * outer,
                center[1] + math.sin(angle) * outer,
            ),
            fill=col,
            width=3,
        )

    # Fish silhouette receiving the meal buff.
    draw.ellipse((55, 42, 166, 80), fill=(66, 164, 203, 255), outline=(8, 31, 42, 240), width=3)
    draw.polygon([(156, 61), (220, 28), (202, 61), (220, 94)], fill=(72, 181, 217, 248), outline=(8, 31, 42, 220))
    draw.polygon([(97, 43), (132, 23), (126, 51)], fill=(41, 128, 166, 240), outline=(8, 31, 42, 185))
    draw.ellipse((68, 52, 82, 66), fill=(255, 246, 215, 255), outline=(8, 31, 42, 230), width=2)
    draw.ellipse((73, 56, 78, 61), fill=(7, 18, 24, 255))
    draw.line((88, 72, 142, 72), fill=(255, 246, 215, 138), width=3)
    for x in [100, 121, 142]:
        draw.arc((x, 46, x + 24, 78), 96, 268, fill=(227, 250, 255, 120), width=2)

    # Up arrows and sparkles make the effect readable at small size.
    for x, height in [(40, 34), (230, 42), (246, 28)]:
        draw.line((x, 92, x, 92 - height), fill=(142, 230, 91, 255), width=6)
        draw.polygon([(x, 42 - (height - 34)), (x - 12, 60 - (height - 34)), (x + 12, 60 - (height - 34))], fill=(142, 230, 91, 255))
    for i, (sx, sy) in enumerate([(42, 30), (66, 22), (192, 24), (230, 78), (118, 94), (178, 92)]):
        col = (255, 224, 129, 235) if i % 2 == 0 else (107, 241, 255, 220)
        draw.line((sx - 6, sy, sx + 6, sy), fill=col, width=3)
        draw.line((sx, sy - 6, sx, sy + 6), fill=col, width=3)
    save(img, "next_effect_art.png")


def status_summary_bg() -> None:
    w, h = 1280, 720
    img = Image.new("RGBA", (w, h), rgba("081522"))
    draw = ImageDraw.Draw(img, "RGBA")

    # Dedicated STATUS_SUMMARY backdrop: calmer than EXP_GAIN, with harbor on
    # the left and warm kitchen context on the right behind the five cards.
    for y in range(h):
        t = y / max(1, h - 1)
        top = (14, 38, 62)
        mid = (44, 74, 82)
        bot = (11, 21, 34)
        if t < 0.58:
            u = t / 0.58
            col = tuple(int(top[i] * (1 - u) + mid[i] * u) for i in range(3))
        else:
            u = (t - 0.58) / 0.42
            col = tuple(int(mid[i] * (1 - u) + bot[i] * u) for i in range(3))
        draw.line((0, y, w, y), fill=(*col, 255))

    # Header and footer bands reinforce that this is a standalone summary view.
    draw.rectangle((0, 0, w, 92), fill=(5, 22, 40, 220))
    draw.line((0, 91, w, 91), fill=(229, 176, 83, 132), width=3)
    draw.rectangle((0, 604, w, h), fill=(4, 13, 25, 190))
    draw.line((0, 604, w, 604), fill=(229, 176, 83, 116), width=3)

    # Harbor side.
    harbor = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    hd = ImageDraw.Draw(harbor, "RGBA")
    hd.rounded_rectangle((42, 116, 520, 314), radius=14, fill=(30, 102, 145, 206), outline=(225, 176, 83, 94), width=3)
    for yy in range(124, 302):
        t = (yy - 124) / 178
        top = (129, 207, 243)
        sea = (21, 111, 156)
        col = tuple(int(top[i] * (1 - t) + sea[i] * t) for i in range(3))
        hd.line((54, yy, 508, yy), fill=(*col, 226))
    hd.rectangle((54, 214, 508, 302), fill=(21, 110, 154, 232))
    for i in range(14):
        y = 228 + i * 5
        hd.line((70, y, 494, y + int(math.sin(i * 0.8) * 3)), fill=(220, 248, 244, 90), width=2)
    for x in [96, 172, 248, 402]:
        hd.rectangle((x, 174, x + 22, 288), fill=(91, 61, 39, 210))
        hd.rectangle((x - 30, 282, x + 76, 298), fill=(52, 36, 25, 230))
    for bx, by in [(108, 153), (246, 136), (392, 158)]:
        hd.arc((bx, by, bx + 26, by + 12), 180, 350, fill=(255, 255, 255, 150), width=2)
    harbor = harbor.filter(ImageFilter.GaussianBlur(0.3))
    img.alpha_composite(harbor)
    draw = ImageDraw.Draw(img, "RGBA")

    # Kitchen side.
    draw.rounded_rectangle((760, 112, 1226, 318), radius=14, fill=(52, 32, 22, 205), outline=(225, 176, 83, 84), width=3)
    for x in range(792, 1208, 64):
        draw.rectangle((x, 132, x + 48, 286), fill=(105, 73, 44, 130))
        draw.line((x - 8, 126, x + 56, 126), fill=(55, 35, 22, 190), width=5)
        draw.ellipse((x + 8, 176, x + 44, 224), fill=(64, 93, 68, 140), outline=(205, 151, 76, 82), width=2)
    for x in [884, 982, 1080, 1166]:
        draw.line((x, 104, x, 176), fill=(31, 21, 15, 190), width=4)
        draw.arc((x - 20, 182, x + 20, 226), 0, 180, fill=(28, 19, 14, 200), width=5)
    for cx, cy, r in [(742, 124, 130), (1186, 116, 118), (1016, 270, 110)]:
        glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        gd = ImageDraw.Draw(glow, "RGBA")
        for k in range(r, 8, -9):
            a = int(46 * (1 - k / r) ** 1.65)
            gd.ellipse((cx - k, cy - k, cx + k, cy + k), fill=(255, 181, 78, a))
        img.alpha_composite(glow)
        draw = ImageDraw.Draw(img, "RGBA")
        draw.ellipse((cx - 10, cy - 14, cx + 10, cy + 14), fill=(255, 204, 112, 190), outline=(75, 43, 23, 230), width=3)

    # Card landing shelves and subtle highlights behind the five summary cards.
    draw.rounded_rectangle((38, 336, 1242, 584), radius=18, fill=(8, 24, 40, 98), outline=(255, 224, 129, 48), width=2)
    for x in range(70, 1220, 240):
        draw.rounded_rectangle((x, 356, x + 188, 556), radius=16, fill=(255, 230, 168, 20), outline=(255, 224, 129, 34), width=2)
        draw.ellipse((x + 24, 526, x + 164, 558), fill=(0, 0, 0, 42))
    for i in range(50):
        x = 42 + (i * 151) % (w - 84)
        y = 106 + (i * 83) % 472
        r = 2 + i % 3
        col = (255, 224, 129, 110) if i % 3 == 0 else (126, 216, 245, 86)
        draw.line((x - r, y, x + r, y), fill=col, width=2)
        draw.line((x, y - r, x, y + r), fill=col, width=2)

    # Final readability wash.
    img.alpha_composite(Image.new("RGBA", (w, h), (3, 7, 13, 42)))
    save(img, "status_summary_bg.png")


def status_cooler_art() -> None:
    w, h = 260, 170
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    draw.ellipse((28, 130, 232, 160), fill=(0, 0, 0, 58))

    # Open lid.
    draw.polygon([(56, 38), (188, 18), (220, 55), (84, 76)], fill=(229, 238, 246, 255), outline=(72, 91, 108, 240))
    draw.polygon([(70, 45), (184, 29), (203, 51), (88, 66)], fill=(185, 203, 218, 255))
    draw.line((86, 73, 104, 96), fill=(92, 106, 119, 230), width=5)
    draw.line((197, 58, 182, 90), fill=(92, 106, 119, 230), width=5)

    # Body.
    draw.rounded_rectangle((42, 78, 222, 140), radius=16, fill=(22, 83, 134, 255), outline=(8, 42, 72, 255), width=5)
    draw.rectangle((48, 84, 216, 102), fill=(238, 246, 250, 255))
    draw.rounded_rectangle((68, 94, 196, 132), radius=12, fill=(27, 99, 154, 255))
    draw.rectangle((111, 103, 153, 124), fill=(235, 242, 246, 255), outline=(73, 99, 121, 220), width=2)
    draw.line((62, 118, 198, 118), fill=(6, 44, 77, 130), width=2)
    draw.line((76, 82, 76, 139), fill=(255, 255, 255, 52), width=3)

    # Fish and ice inside.
    for i, (x, y, color) in enumerate([(84, 86, (92, 170, 202)), (126, 78, (205, 74, 60)), (160, 88, (102, 141, 136))]):
        draw.ellipse((x, y, x + 56, y + 18), fill=(*color, 245), outline=(24, 32, 36, 220), width=2)
        draw.polygon([(x + 50, y + 9), (x + 70, y - 2), (x + 64, y + 9), (x + 70, y + 20)], fill=(*color, 230), outline=(24, 32, 36, 180))
        draw.ellipse((x + 8, y + 6, x + 13, y + 11), fill=(255, 244, 214, 255))
        if i == 1:
            draw.line((x + 22, y + 3, x + 42, y + 15), fill=(255, 225, 190, 110), width=2)
    for i in range(16):
        x = 64 + (i * 29) % 138
        y = 74 + (i * 13) % 32
        draw.polygon([(x, y), (x + 8, y + 2), (x + 4, y + 8), (x - 4, y + 5)], fill=(230, 250, 255, 120), outline=(115, 166, 190, 72))
    draw.rectangle((119, 136, 145, 145), fill=(7, 45, 75, 255))
    draw.line((122, 140, 142, 140), fill=(238, 246, 250, 255), width=3)
    save(img, "status_cooler_art.png")


def status_money_art() -> None:
    w, h = 260, 170
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    draw.ellipse((30, 132, 232, 162), fill=(0, 0, 0, 48))

    # Pouch.
    draw.rounded_rectangle((132, 58, 204, 140), radius=18, fill=(113, 72, 33, 255), outline=(62, 35, 16, 240), width=4)
    draw.polygon([(138, 64), (154, 30), (183, 30), (199, 64)], fill=(144, 91, 41, 255), outline=(62, 35, 16, 220))
    draw.rectangle((142, 55, 196, 68), fill=(87, 52, 23, 255))
    draw.line((147, 60, 191, 60), fill=(227, 165, 70, 210), width=3)
    draw.line((158, 31, 148, 18), fill=(231, 181, 88, 230), width=4)
    draw.line((178, 31, 190, 18), fill=(231, 181, 88, 230), width=4)

    coins = [
        (45, 111, 26), (78, 98, 29), (111, 120, 27), (31, 134, 24),
        (68, 136, 27), (102, 88, 25), (135, 106, 28), (164, 127, 25),
        (197, 134, 24), (55, 73, 23), (91, 61, 24), (126, 68, 23),
    ]
    for i, (cx, cy, r) in enumerate(coins):
        draw.ellipse((cx - r, cy - r * 0.58, cx + r, cy + r * 0.58), fill=(174, 96, 19, 255))
        draw.ellipse((cx - r + 3, cy - r * 0.58 - 4, cx + r - 3, cy + r * 0.58 - 4), fill=(224, 151, 31, 255), outline=(91, 54, 18, 235), width=2)
        draw.ellipse((cx - r + 9, cy - r * 0.42 - 4, cx + r - 9, cy + r * 0.42 - 4), fill=(255, 219, 94, 235))
        draw.line((cx - r + 10, cy - 4, cx + r - 10, cy - 4), fill=(134, 75, 18, 145), width=2)
        if i % 3 == 0:
            draw.line((cx, cy - r * 0.38 - 4, cx, cy + r * 0.38 - 4), fill=(255, 239, 150, 110), width=2)
    for x, y in [(42, 47), (211, 65), (214, 112), (25, 98)]:
        draw.line((x - 5, y, x + 5, y), fill=(255, 238, 154, 190), width=2)
        draw.line((x, y - 5, x, y + 5), fill=(255, 238, 154, 190), width=2)
    save(img, "status_money_art.png")


def status_clock_art() -> None:
    w, h = 260, 170
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    draw.ellipse((42, 132, 218, 162), fill=(0, 0, 0, 50))

    center = (121, 91)
    # Chain.
    chain_points = [(165, 34), (190, 25), (215, 34), (222, 56), (207, 74), (184, 76), (164, 65)]
    for a, b in zip(chain_points, chain_points[1:]):
        draw.line((a[0], a[1], b[0], b[1]), fill=(125, 82, 31, 230), width=7)
        draw.line((a[0], a[1], b[0], b[1]), fill=(228, 169, 64, 255), width=3)
    for x, y in chain_points[1:-1]:
        draw.ellipse((x - 8, y - 8, x + 8, y + 8), outline=(228, 169, 64, 255), width=3)

    draw.ellipse((center[0] - 70, center[1] - 70, center[0] + 70, center[1] + 70), fill=(109, 65, 21, 255))
    draw.ellipse((center[0] - 62, center[1] - 62, center[0] + 62, center[1] + 62), fill=(219, 156, 54, 255), outline=(73, 42, 14, 255), width=4)
    draw.ellipse((center[0] - 49, center[1] - 49, center[0] + 49, center[1] + 49), fill=(255, 244, 213, 255), outline=(92, 55, 22, 230), width=3)
    draw.ellipse((center[0] - 12, center[1] - 82, center[0] + 12, center[1] - 58), fill=(218, 158, 63, 255), outline=(83, 49, 18, 230), width=3)
    draw.rectangle((center[0] - 22, center[1] - 68, center[0] + 22, center[1] - 57), fill=(218, 158, 63, 255), outline=(83, 49, 18, 230), width=2)
    for i in range(12):
        a = -math.pi * 0.5 + math.tau * i / 12
        r0 = 39 if i % 3 else 34
        r1 = 45
        x0 = center[0] + math.cos(a) * r0
        y0 = center[1] + math.sin(a) * r0
        x1 = center[0] + math.cos(a) * r1
        y1 = center[1] + math.sin(a) * r1
        draw.line((x0, y0, x1, y1), fill=(70, 47, 28, 230), width=2 if i % 3 else 3)
    draw.line((center[0], center[1], center[0] + 1, center[1] - 33), fill=(43, 34, 24, 255), width=5)
    draw.line((center[0], center[1], center[0] + 31, center[1] + 18), fill=(43, 34, 24, 255), width=5)
    draw.ellipse((center[0] - 6, center[1] - 6, center[0] + 6, center[1] + 6), fill=(43, 34, 24, 255))
    draw.arc((center[0] - 68, center[1] - 68, center[0] + 68, center[1] + 68), 205, 312, fill=(255, 242, 184, 92), width=5)
    save(img, "status_clock_art.png")


def meal_banner_frame() -> None:
    w, h = 760, 128
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow, "RGBA")
    sd.rounded_rectangle((17, 21, w - 14, h - 12), radius=13, fill=(0, 0, 0, 138))
    shadow = shadow.filter(ImageFilter.GaussianBlur(6))
    img.alpha_composite(shadow)
    draw = ImageDraw.Draw(img, "RGBA")

    draw.rounded_rectangle((12, 10, w - 18, h - 20), radius=10, fill=(237, 214, 172, 255), outline=(82, 50, 25, 255), width=5)
    draw.rounded_rectangle((21, 18, w - 28, h - 29), radius=7, fill=(246, 228, 188, 250), outline=(129, 79, 38, 150), width=2)

    # Keep the headline area quieter than the old diagonal stripe texture.
    wash = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    wd = ImageDraw.Draw(wash, "RGBA")
    for y in range(20, h - 28):
        t = (y - 20) / float(h - 48)
        top = (255, 246, 216)
        bot = (228, 193, 133)
        col = tuple(int(top[i] * (1.0 - t) + bot[i] * t) for i in range(3))
        wd.line((24, y, w - 32, y), fill=(*col, 30), width=1)
    img.alpha_composite(wash)
    draw = ImageDraw.Draw(img, "RGBA")

    draw.rounded_rectangle((27, 25, w - 36, h - 38), radius=5, outline=(225, 170, 82, 220), width=3)
    draw.line((35, 29, w - 58, 29), fill=(255, 249, 223, 118), width=2)
    draw.line((35, h - 39, w - 64, h - 39), fill=(104, 62, 31, 82), width=2)
    for x, y in [(56, 11), (128, 10), (277, 10), (470, 11), (639, 10), (32, 103), (194, 107), (518, 106), (703, 105)]:
        draw.rectangle((x, y, x + 18, y + 3), fill=(84, 50, 25, 74))
    for x, y in [(15, 38), (16, 77), (w - 23, 49), (w - 24, 86)]:
        draw.rectangle((x, y, x + 3, y + 15), fill=(84, 50, 25, 84))

    mark_layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    md = ImageDraw.Draw(mark_layer, "RGBA")
    rng = random.Random(902)
    for i in range(78):
        x = rng.randint(34, w - 52)
        y = rng.randint(27, h - 43)
        clear = 232 < x < 546 and 35 < y < 98
        if clear and i % 3:
            continue
        alpha = rng.randint(5, 14) if clear else rng.randint(8, 24)
        r = 1 if rng.random() < 0.86 else 2
        md.ellipse((x, y, x + r, y + r), fill=(100, 59, 27, alpha))
    for x0, y0, x1, y1, alpha in [(58, 30, 34, 92, 5), (126, 23, 98, 91, 4), (568, 24, 618, 91, 3), (658, 22, 713, 88, 4)]:
        md.line((x0, y0, x1, y1), fill=(115, 72, 34, alpha), width=1)
        md.line((x0 + 3, y0, x1 + 3, y1), fill=(255, 246, 218, max(4, alpha // 2)), width=1)

    # Irregular parchment chips and edge shadows read as material without crossing the headline.
    chips = [
        (74, 18, 121, 23, 10),
        (244, 18, 302, 22, 8),
        (382, 18, 426, 23, 9),
        (84, h - 34, 146, h - 29, 10),
        (226, h - 33, 286, h - 28, 8),
        (474, h - 34, 548, h - 29, 9),
        (620, h - 34, 692, h - 28, 11),
    ]
    for x0, y0, x1, y1, alpha in chips:
        md.rectangle((x0, y0, x1, y1), fill=(73, 43, 22, alpha))
        md.line((x0 + 3, y0, x1 - 5, y0), fill=(255, 246, 218, max(5, alpha - 3)), width=1)
    for x in range(34, w - 42, 57):
        y = 19 + (x * 7) % 6
        md.rectangle((x, y, x + 18, y + 2), fill=(255, 248, 225, 26))
        by = h - 35 - (x * 5) % 5
        md.rectangle((x + 16, by, x + 38, by + 2), fill=(71, 42, 22, 18))

    # Folded corner and fish stamp echo the reference without baking text.
    md.polygon([(w - 103, 10), (w - 18, 10), (w - 18, 78)], fill=(255, 244, 219, 218), outline=(166, 112, 58, 125))
    md.line((w - 97, 17, w - 29, 72), fill=(135, 85, 44, 78), width=2)
    fish_cx, fish_cy = w - 118, 67
    fish_fill = (92, 76, 55, 12)
    fish_line = (84, 68, 48, 34)
    md.ellipse((fish_cx - 52, fish_cy - 15, fish_cx + 32, fish_cy + 17), fill=fish_fill, outline=fish_line, width=2)
    tail = [(fish_cx + 26, fish_cy), (fish_cx + 70, fish_cy - 25), (fish_cx + 57, fish_cy), (fish_cx + 70, fish_cy + 24)]
    md.polygon(tail, fill=(92, 76, 55, 10))
    md.line(tail + [tail[0]], fill=fish_line, width=1)
    fin = [(fish_cx - 18, fish_cy - 13), (fish_cx + 3, fish_cy - 33), (fish_cx + 1, fish_cy - 12)]
    md.polygon(fin, fill=(92, 76, 55, 8))
    md.line(fin + [fin[0]], fill=(84, 68, 48, 25), width=1)
    md.ellipse((fish_cx - 40, fish_cy - 6, fish_cx - 32, fish_cy + 2), fill=(40, 34, 28, 34))
    for s in range(5):
        x = fish_cx - 22 + s * 13
        md.arc((x, fish_cy - 14, x + 20, fish_cy + 16), 98, 260, fill=(84, 68, 48, 24), width=1)
    img.alpha_composite(mark_layer)
    draw = ImageDraw.Draw(img, "RGBA")

    # Navy command tab at upper left, with a small utensil mark for the eating state.
    gold = (229, 173, 81, 255)
    draw.rounded_rectangle((42, 0, 218, 38), radius=7, fill=(10, 31, 55, 255), outline=gold, width=3)
    draw.rectangle((49, 4, 211, 11), fill=(29, 61, 94, 178))
    draw.line((55, 36, 204, 36), fill=(3, 16, 30, 165), width=2)
    utensil = (255, 232, 160, 230)
    draw.line((66, 29, 94, 8), fill=utensil, width=4)
    for tine_x in (88, 94, 100):
        draw.line((tine_x, 7, tine_x - 5, 18), fill=utensil, width=2)
    draw.ellipse((116, 7, 136, 25), outline=utensil, width=4)
    draw.line((127, 24, 156, 30), fill=utensil, width=4)

    save(img, "meal_banner_frame.png")


def exp_burst_frame() -> None:
    w, h = 760, 220
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")

    bg = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    bd = ImageDraw.Draw(bg, "RGBA")
    center = (w // 2, h // 2 - 20)
    for r in range(380, 24, -16):
        a = int(96 * (1 - r / 380) ** 1.8)
        bd.ellipse((center[0] - r, center[1] - r, center[0] + r, center[1] + r), fill=(255, 204, 78, a))
    for r in range(230, 18, -16):
        a = int(64 * (1 - r / 230) ** 1.45)
        bd.ellipse((center[0] - r, center[1] - r, center[0] + r, center[1] + r), outline=(90, 238, 255, a), width=7)
    mask = Image.new("L", (w, h), 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle((4, 4, w - 6, h - 8), radius=12, fill=255)
    img.alpha_composite(bg)
    img.putalpha(mask)
    draw = ImageDraw.Draw(img, "RGBA")

    for i in range(56):
        angle = math.tau * i / 56
        inner = 20 + (i % 3) * 5
        outer = 390 + (i % 5) * 18
        color = (255, 224, 129, 78) if i % 2 == 0 else (107, 241, 255, 48)
        x0 = center[0] + math.cos(angle) * inner
        y0 = center[1] + math.sin(angle) * inner
        x1 = center[0] + math.cos(angle) * outer
        y1 = center[1] + math.sin(angle) * outer
        draw.line((x0, y0, x1, y1), fill=color, width=5 if i % 2 == 0 else 3)

    for r in range(180, 18, -12):
        a = int(82 * (1 - r / 180) ** 1.65)
        draw.ellipse((center[0] - r, center[1] - r, center[0] + r, center[1] + r), fill=(255, 222, 112, a))
    draw.ellipse((center[0] - 76, center[1] - 60, center[0] + 76, center[1] + 60), outline=(255, 240, 172, 132), width=3)

    # Gauge pedestal and cyan flash trails.
    for i in range(6):
        width = w - 114 - i * 52
        y = 142 + i * 5
        draw.rounded_rectangle(
            ((w - width) // 2, y, (w + width) // 2, y + 13),
            radius=7,
            fill=(68, 229, 255, max(22, 92 - i * 10)),
        )
    draw.rounded_rectangle((62, 152, w - 62, 194), radius=20, fill=(3, 12, 24, 172), outline=(107, 241, 255, 152), width=3)
    draw.rounded_rectangle((86, 164, w - 86, 181), radius=9, fill=(30, 128, 172, 168))

    for i in range(46):
        x = 48 + (i * 113) % (w - 96)
        y = 32 + (i * 47) % (h - 78)
        r = 2 + i % 4
        color = (255, 224, 129, 172) if i % 3 else (107, 241, 255, 148)
        draw.line((x - r, y, x + r, y), fill=color, width=2)
        draw.line((x, y - r, x, y + r), fill=color, width=2)

    draw.line((28, 22, w - 28, 22), fill=(255, 224, 129, 118), width=3)
    draw.line((40, h - 24, w - 40, h - 24), fill=(107, 241, 255, 96), width=3)
    save(img, "exp_burst_frame.png")


def level_crown_asset() -> None:
    w, h = 220, 96
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow, "RGBA")
    sd.polygon([(28, 64), (52, 24), (78, 48), (110, 12), (142, 48), (168, 24), (192, 64), (180, 84), (40, 84)], fill=(0, 0, 0, 130))
    shadow = shadow.filter(ImageFilter.GaussianBlur(4))
    img.alpha_composite(shadow)
    draw = ImageDraw.Draw(img, "RGBA")

    base = [(28, 62), (52, 22), (78, 48), (110, 10), (142, 48), (168, 22), (192, 62), (178, 84), (42, 84)]
    draw.polygon(base, fill=(112, 65, 13, 255), outline=(46, 29, 8, 255))
    inner = [(39, 58), (56, 33), (82, 58), (110, 22), (138, 58), (164, 33), (181, 58), (169, 76), (51, 76)]
    draw.polygon(inner, fill=(255, 219, 86, 255), outline=(126, 74, 18, 255))
    draw.rectangle((47, 64, 173, 82), fill=(255, 226, 106, 255), outline=(72, 42, 10, 255), width=3)
    for x, y, col in [(52, 22, rgba("ff5f6d")), (110, 10, rgba("fff1c7")), (168, 22, rgba("6bf1ff"))]:
        draw.ellipse((x - 8, y - 8, x + 8, y + 8), fill=col, outline=(72, 42, 10, 255), width=2)
    for x in range(64, 158, 23):
        draw.line((x, 66, x + 8, 78), fill=(126, 74, 18, 145), width=2)
    draw.arc((26, 16, 194, 116), 198, 342, fill=(255, 244, 188, 105), width=3)
    save(img, "level_crown.png")


def level_laurel_asset(name: str, direction: int) -> None:
    w, h = 140, 120
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    points: list[tuple[float, float]] = []
    for i in range(10):
        t = i / 9
        y = 104 - t * 92
        x = 72 + direction * (34 - math.sin(t * math.pi) * 30)
        points.append((x, y))
    draw.line(points, fill=(106, 69, 18, 255), width=6, joint="curve")
    draw.line(points, fill=(255, 219, 86, 210), width=2, joint="curve")
    for i, (x, y) in enumerate(points):
        leaf_len = 26 + (i % 3) * 3
        outward = (direction * leaf_len, -10)
        inward = (-direction * 8, -7)
        leaf = [(x, y), (x + outward[0], y + outward[1]), (x + inward[0], y + inward[1])]
        draw.polygon(leaf, fill=(238, 181, 62, 255), outline=(107, 67, 18, 210))
        draw.line((x, y, x + outward[0] * 0.72, y + outward[1] * 0.72), fill=(255, 246, 188, 180), width=2)
    save(img, name)


def level_unlock_medallion() -> None:
    w, h = 150, 150
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    draw.polygon([(42, 0), (75, 44), (108, 0), (96, 58), (54, 58)], fill=(143, 36, 48, 255), outline=(76, 22, 25, 230))
    draw.ellipse((14, 24, 136, 146), fill=(50, 29, 8, 170))
    for r, col in [(58, rgba("6a4515")), (52, rgba("d8a13a")), (43, rgba("ffe081")), (34, rgba("5d3d18"))]:
        draw.ellipse((75 - r, 84 - r, 75 + r, 84 + r), fill=col, outline=(65, 36, 10, 220), width=3)
    for i in range(24):
        a = math.tau * i / 24
        x0 = 75 + math.cos(a) * 48
        y0 = 84 + math.sin(a) * 48
        x1 = 75 + math.cos(a) * 60
        y1 = 84 + math.sin(a) * 60
        draw.line((x0, y0, x1, y1), fill=(255, 232, 130, 190), width=3)

    # Boss fish silhouette.
    body = [(38, 82), (55, 65), (89, 69), (109, 84), (91, 99), (55, 100)]
    draw.polygon(body, fill=(52, 65, 60, 255), outline=(22, 19, 14, 255))
    draw.polygon([(103, 84), (133, 62), (126, 84), (133, 106)], fill=(42, 50, 50, 255), outline=(22, 19, 14, 255))
    draw.polygon([(62, 65), (82, 45), (87, 70)], fill=(44, 54, 50, 255), outline=(22, 19, 14, 220))
    draw.ellipse((47, 78, 56, 87), fill=(255, 241, 184, 255), outline=(20, 16, 10, 255))
    draw.ellipse((50, 80, 54, 84), fill=(12, 10, 8, 255))
    for s in range(4):
        x = 68 + s * 10
        draw.arc((x, 72, x + 18, 98), 98, 260, fill=(255, 238, 152, 120), width=2)
    draw.line((40, 111, 112, 106), fill=(255, 245, 190, 110), width=4)
    save(img, "level_unlock_medallion.png")


def level_unlock_spot() -> None:
    w, h = 260, 110
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")
    draw.rounded_rectangle((0, 0, w - 1, h - 1), radius=8, fill=(9, 69, 107, 255), outline=(255, 224, 129, 220), width=4)
    for y in range(4, h - 4):
        t = y / h
        top = (125, 202, 245)
        mid = (31, 111, 154)
        bot = (12, 65, 110)
        if t < 0.48:
            u = t / 0.48
            col = tuple(int(top[i] * (1 - u) + mid[i] * u) for i in range(3))
        else:
            u = (t - 0.48) / 0.52
            col = tuple(int(mid[i] * (1 - u) + bot[i] * u) for i in range(3))
        draw.line((4, y, w - 5, y), fill=(*col, 255))
    draw.rectangle((4, 48, w - 5, 52), fill=(255, 246, 210, 95))
    for i in range(5):
        x = 22 + i * 28
        draw.arc((x, 57 + i % 2 * 3, x + 72, 85 + i % 2 * 3), 190, 350, fill=(255, 255, 255, 80), width=2)

    draw.polygon([(132, 35), (192, 94), (76, 94)], fill=(90, 92, 72, 255), outline=(48, 48, 40, 220))
    draw.polygon([(132, 35), (116, 94), (76, 94)], fill=(68, 73, 58, 210))
    draw.rectangle((178, 35, 198, 86), fill=(245, 238, 207, 255), outline=(72, 55, 40, 230), width=2)
    draw.rectangle((174, 28, 202, 40), fill=(31, 54, 84, 255), outline=(72, 55, 40, 230), width=2)
    draw.rectangle((183, 44, 193, 56), fill=(52, 102, 139, 255), outline=(32, 44, 60, 210))
    draw.ellipse((190, 19, 207, 35), fill=(255, 224, 129, 245), outline=(112, 70, 22, 220), width=2)
    draw.polygon([(14, 92), (62, 76), (118, 86), (162, 72), (246, 88), (246, 106), (14, 106)], fill=(43, 68, 62, 255))
    for bx, by in [(40, 26), (60, 20), (224, 30)]:
        draw.arc((bx, by, bx + 18, by + 9), 180, 350, fill=(255, 255, 255, 170), width=2)
    save(img, "level_unlock_spot.png")


def level_unlock_ribbon() -> None:
    w, h = 760, 72
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow, "RGBA")
    sd.rounded_rectangle((74, 20, w - 74, h - 8), radius=6, fill=(0, 0, 0, 118))
    sd.polygon([(18, 20), (92, 10), (112, 36), (92, 62), (18, 52), (48, 36)], fill=(0, 0, 0, 102))
    sd.polygon([(w - 18, 20), (w - 92, 10), (w - 112, 36), (w - 92, 62), (w - 18, 52), (w - 48, 36)], fill=(0, 0, 0, 102))
    shadow = shadow.filter(ImageFilter.GaussianBlur(4))
    img.alpha_composite(shadow)
    draw = ImageDraw.Draw(img, "RGBA")

    red = (139, 35, 48, 255)
    red_hi = (183, 55, 64, 245)
    red_shadow = (82, 19, 29, 255)
    gold = (255, 224, 129, 240)
    edge = (67, 25, 20, 255)

    # Folded tails and central banner for the Lv.5 unlock callout.
    draw.polygon([(16, 20), (92, 10), (116, 36), (92, 62), (16, 52), (48, 36)], fill=red_shadow, outline=edge)
    draw.polygon([(w - 16, 20), (w - 92, 10), (w - 116, 36), (w - 92, 62), (w - 16, 52), (w - 48, 36)], fill=red_shadow, outline=edge)
    draw.rounded_rectangle((70, 8, w - 70, h - 16), radius=8, fill=red, outline=edge, width=5)
    draw.rounded_rectangle((88, 18, w - 88, h - 28), radius=4, fill=red_hi, outline=gold, width=2)
    draw.line((98, 22, w - 98, 18), fill=(255, 241, 180, 70), width=3)
    draw.line((98, h - 30, w - 98, h - 32), fill=(71, 17, 24, 120), width=2)
    for x in range(116, w - 116, 62):
        draw.line((x, 19, x - 28, h - 31), fill=(255, 255, 255, 24), width=2)
    for sx in [84, w - 96]:
        draw.line((sx - 8, 36, sx + 8, 36), fill=gold, width=4)
        draw.line((sx, 28, sx, 44), fill=gold, width=4)
        draw.ellipse((sx - 5, 31, sx + 5, 41), fill=(255, 244, 190, 220))
    save(img, "level_unlock_ribbon.png")


def level_stat_row_frame() -> None:
    w, h = 420, 76
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow, "RGBA")
    sd.rounded_rectangle((8, 12, w - 8, h - 8), radius=8, fill=(0, 0, 0, 118))
    shadow = shadow.filter(ImageFilter.GaussianBlur(4))
    img.alpha_composite(shadow)
    draw = ImageDraw.Draw(img, "RGBA")

    draw.rounded_rectangle((4, 4, w - 6, h - 10), radius=8, fill=(6, 19, 32, 248), outline=(57, 34, 15, 250), width=4)
    draw.rounded_rectangle((14, 12, w - 16, h - 20), radius=5, fill=(16, 42, 65, 232), outline=(207, 148, 62, 172), width=2)
    draw.rectangle((24, 18, 78, h - 27), fill=(7, 18, 28, 148), outline=(255, 224, 129, 118), width=2)
    draw.line((148, 18, 148, h - 26), fill=(255, 224, 129, 54), width=2)
    draw.line((284, 18, 284, h - 26), fill=(255, 224, 129, 64), width=2)
    draw.line((318, 38, 354, 38), fill=(255, 196, 69, 190), width=4)
    draw.polygon([(354, 28), (378, 38), (354, 48)], fill=(255, 196, 69, 210), outline=(89, 56, 15, 210))
    draw.rectangle((w - 82, 18, w - 25, h - 26), fill=(19, 62, 44, 168), outline=(110, 229, 106, 120), width=2)
    for x in [32, 390]:
        draw.line((x - 7, 18, x + 7, 18), fill=(255, 241, 190, 150), width=3)
        draw.line((x, 11, x, 25), fill=(255, 241, 190, 150), width=3)
    for x in range(100, 280, 44):
        draw.line((x, 17, x - 18, h - 27), fill=(255, 255, 255, 20), width=2)
    save(img, "level_stat_row_frame.png")


def reward_card_frame() -> None:
    w, h = 360, 150
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow, "RGBA")
    sd.rounded_rectangle((14, 18, w - 10, h - 8), radius=12, fill=(0, 0, 0, 120))
    shadow = shadow.filter(ImageFilter.GaussianBlur(4))
    img.alpha_composite(shadow)
    draw = ImageDraw.Draw(img, "RGBA")

    # Reward cards in reference 02 are dark, celebratory, and more prominent
    # than ordinary form panels. Text is drawn in Godot.
    draw.rounded_rectangle((8, 8, w - 14, h - 16), radius=10, fill=(8, 26, 43, 250), outline=(72, 45, 21, 255), width=5)
    draw.rounded_rectangle((20, 20, w - 26, h - 28), radius=6, fill=(13, 38, 60, 232), outline=(224, 169, 78, 190), width=2)
    center = (w // 2, h + 18)
    for i in range(28):
        angle = -math.pi * 0.92 + math.pi * 1.84 * i / 27
        inner = 14 + (i % 3) * 3
        outer = 152 + (i % 4) * 8
        col = (255, 207, 83, 34) if i % 2 == 0 else (121, 220, 255, 24)
        draw.line(
            (
                center[0] + math.cos(angle) * inner,
                center[1] + math.sin(angle) * inner,
                center[0] + math.cos(angle) * outer,
                center[1] + math.sin(angle) * outer,
            ),
            fill=col,
            width=3,
        )
    for r in range(76, 16, -8):
        a = int(34 * (1 - r / 76) ** 1.7)
        draw.ellipse((center[0] - r, center[1] - r, center[0] + r, center[1] + r), fill=(255, 197, 62, a))
    draw.rectangle((24, 28, w - 30, 50), fill=(6, 18, 30, 116))
    draw.line((28, 52, w - 34, 52), fill=(224, 169, 78, 126), width=2)
    for x, y in [(22, 22), (w - 40, 22), (22, h - 48), (w - 40, h - 48)]:
        draw.rectangle((x, y, x + 12, y + 12), fill=(224, 169, 78, 220), outline=(72, 45, 21, 255), width=2)
    for i in range(12):
        x = 34 + (i * 29) % (w - 68)
        y = 66 + (i * 17) % 52
        col = (255, 224, 129, 110) if i % 2 else (107, 241, 255, 84)
        draw.line((x - 3, y, x + 3, y), fill=col, width=2)
        draw.line((x, y - 3, x, y + 3), fill=col, width=2)
    save(img, "reward_card_frame.png")


def meal_dish_card_frame() -> None:
    w, h = 760, 170
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow, "RGBA")
    sd.rounded_rectangle((18, 20, w - 14, h - 8), radius=14, fill=(0, 0, 0, 120))
    shadow = shadow.filter(ImageFilter.GaussianBlur(5))
    img.alpha_composite(shadow)
    draw = ImageDraw.Draw(img, "RGBA")

    # "Current dish" card for MEAL_RESULT. The wide left recess lets the food
    # read as the hero while the compact right plaque carries runtime labels.
    draw.rounded_rectangle((10, 8, w - 18, h - 18), radius=13, fill=(7, 22, 37, 248), outline=(73, 45, 21, 255), width=5)
    draw.rounded_rectangle((24, 22, w - 32, h - 32), radius=8, fill=(12, 36, 58, 228), outline=(224, 169, 78, 170), width=2)
    draw.rounded_rectangle((40, 34, 522, h - 36), radius=12, fill=(238, 226, 201, 238), outline=(108, 75, 44, 225), width=4)
    draw.rounded_rectangle((56, 48, 506, h - 50), radius=9, fill=(205, 194, 170, 210), outline=(255, 248, 221, 145), width=2)
    draw.ellipse((126, 46, 474, h - 44), fill=(255, 244, 214, 32), outline=(255, 226, 128, 70), width=2)
    draw.rectangle((548, 42, w - 58, 72), fill=(5, 17, 29, 128))
    draw.line((554, 78, w - 64, 78), fill=(224, 169, 78, 118), width=2)
    draw.rounded_rectangle((548, 90, w - 62, h - 48), radius=6, fill=(255, 232, 175, 30), outline=(224, 169, 78, 70), width=1)
    for i in range(12):
        x = 570 + (i * 27) % 118
        y = 98 + (i * 17) % 34
        col = (255, 224, 129, 96) if i % 2 == 0 else (107, 241, 255, 72)
        draw.line((x - 3, y, x + 3, y), fill=col, width=2)
        draw.line((x, y - 3, x, y + 3), fill=col, width=2)
    for x, y in [(26, 24), (w - 48, 24), (26, h - 52), (w - 48, h - 52)]:
        draw.rectangle((x, y, x + 14, y + 14), fill=(224, 169, 78, 220), outline=(73, 45, 21, 255), width=2)
    # Small fish stamp on the text side, matching the reference paper/nautical language.
    fish_cx, fish_cy = w - 108, 112
    draw.ellipse((fish_cx - 44, fish_cy - 12, fish_cx + 30, fish_cy + 14), fill=(162, 144, 106, 92))
    draw.polygon(
        [(fish_cx + 26, fish_cy), (fish_cx + 62, fish_cy - 19), (fish_cx + 52, fish_cy), (fish_cx + 62, fish_cy + 19)],
        fill=(162, 144, 106, 92),
    )
    draw.ellipse((fish_cx - 34, fish_cy - 5, fish_cx - 27, fish_cy + 2), fill=(220, 205, 168, 100))
    save(img, "meal_dish_card_frame.png")


def frame_assets() -> None:
    def save_recipe_grid_frame() -> None:
        size = (460, 560)
        img = Image.new("RGBA", size, (0, 0, 0, 0))
        shadow = Image.new("RGBA", size, (0, 0, 0, 0))
        sd = ImageDraw.Draw(shadow, "RGBA")
        sd.rounded_rectangle((14, 16, size[0] - 8, size[1] - 6), radius=13, fill=(0, 0, 0, 130))
        img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(5)))
        draw = ImageDraw.Draw(img, "RGBA")
        draw.rounded_rectangle((8, 8, size[0] - 16, size[1] - 18), radius=10, fill=(42, 25, 13, 255), outline=(21, 13, 8, 255), width=5)
        draw.rounded_rectangle((20, 20, size[0] - 28, size[1] - 30), radius=7, fill=(15, 43, 66, 248), outline=(229, 170, 75, 210), width=3)
        paper = reference_paper_texture((size[0] - 64, size[1] - 84), "ead8ad", 93, (496, 204, 1002, 752), 0.38, 9.0)
        paste_rounded(img, paper, (32, 54, size[0] - 32, size[1] - 34), 6, 236)
        draw.rounded_rectangle((32, 54, size[0] - 32, size[1] - 34), radius=6, outline=(95, 57, 26, 130), width=2)
        for x in [154, 306]:
            draw.line((x, 64, x, size[1] - 46), fill=(93, 55, 24, 44), width=2)
        draw.line((44, 302, size[0] - 44, 302), fill=(93, 55, 24, 45), width=2)
        draw_corner_brackets(draw, (22, 22, size[0] - 30, size[1] - 32), (234, 182, 82, 215), (32, 19, 9, 245), 24, 3)
        save(img, "recipe_grid_frame.png")

    def save_recipe_card_frame() -> None:
        size = (280, 220)
        img = Image.new("RGBA", size, (0, 0, 0, 0))
        shadow = Image.new("RGBA", size, (0, 0, 0, 0))
        sd = ImageDraw.Draw(shadow, "RGBA")
        sd.rounded_rectangle((14, 16, size[0] - 10, size[1] - 7), radius=12, fill=(0, 0, 0, 116))
        img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(4)))
        paper = reference_paper_texture((size[0] - 24, size[1] - 22), "f0dcaa", 95, (496, 204, 650, 438), 0.50, 6.0)
        paste_rounded(img, paper, (8, 8, size[0] - 16, size[1] - 14), 9)
        draw = ImageDraw.Draw(img, "RGBA")
        draw.rounded_rectangle((7, 7, size[0] - 16, size[1] - 14), radius=9, outline=(70, 40, 18, 255), width=5)
        draw.rounded_rectangle((18, 18, size[0] - 27, size[1] - 26), radius=7, outline=(219, 166, 74, 175), width=2)
        draw.rounded_rectangle((24, 22, size[0] - 33, 60), radius=7, fill=(80, 46, 21, 218), outline=(210, 152, 62, 188), width=2)
        draw.rounded_rectangle((34, 30, size[0] - 43, 52), radius=5, fill=(255, 240, 188, 38), outline=(111, 68, 30, 110), width=1)
        draw.rounded_rectangle((28, 64, size[0] - 37, 154), radius=8, fill=(92, 55, 28, 106), outline=(92, 55, 28, 170), width=3)
        draw.rounded_rectangle((42, 76, size[0] - 51, 145), radius=7, fill=(255, 239, 199, 42), outline=(224, 171, 79, 112), width=2)
        draw.rounded_rectangle((31, 158, size[0] - 40, size[1] - 31), radius=7, fill=(83, 49, 24, 84), outline=(160, 114, 52, 70), width=2)
        draw.rounded_rectangle((45, 169, size[0] - 54, size[1] - 42), radius=5, fill=(246, 224, 176, 32), outline=(160, 114, 52, 52), width=1)
        draw.line((50, 164, size[0] - 59, 164), fill=(226, 170, 75, 104), width=2)
        draw_corner_brackets(draw, (18, 18, size[0] - 30, size[1] - 29), (223, 170, 75, 182), (58, 34, 16, 225), 17, 2)
        save(img, "recipe_card_frame.png")

    def save_recipe_dish_thumb_frame() -> None:
        size = (260, 170)
        img = Image.new("RGBA", size, (0, 0, 0, 0))
        shadow = Image.new("RGBA", size, (0, 0, 0, 0))
        sd = ImageDraw.Draw(shadow, "RGBA")
        sd.rounded_rectangle((10, 12, size[0] - 8, size[1] - 7), radius=8, fill=(0, 0, 0, 118))
        img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(4)))
        draw = ImageDraw.Draw(img, "RGBA")

        # Plate-like mat used inside recipe cards. The food art remains the
        # hero, but the socket now reads as a deliberate center stage.
        draw.rounded_rectangle((7, 7, size[0] - 12, size[1] - 14), radius=9, fill=(92, 55, 28, 150), outline=(48, 27, 13, 248), width=4)
        draw.rounded_rectangle((18, 18, size[0] - 24, size[1] - 28), radius=7, fill=(245, 227, 184, 64), outline=(224, 171, 79, 168), width=2)
        draw.ellipse((39, 33, size[0] - 45, size[1] - 45), fill=(255, 244, 214, 34), outline=(255, 226, 128, 76), width=2)
        draw.rounded_rectangle((30, 28, size[0] - 36, size[1] - 38), radius=5, fill=(255, 241, 205, 16), outline=(255, 231, 150, 58), width=1)
        draw.line((24, size[1] - 32, size[0] - 30, size[1] - 32), fill=(255, 218, 106, 92), width=2)
        draw_corner_brackets(draw, (16, 16, size[0] - 24, size[1] - 28), (238, 181, 77, 204), (53, 31, 15, 235), 14, 2)
        save(img, "recipe_dish_thumb_frame.png")

    def save_dish_detail_frame() -> None:
        size = (620, 560)
        img = Image.new("RGBA", size, (0, 0, 0, 0))
        shadow = Image.new("RGBA", size, (0, 0, 0, 0))
        sd = ImageDraw.Draw(shadow, "RGBA")
        sd.rounded_rectangle((14, 16, size[0] - 8, size[1] - 6), radius=14, fill=(0, 0, 0, 135))
        img.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(5)))
        paper = reference_paper_texture((size[0] - 22, size[1] - 28), "f3e3bd", 96, (1032, 524, 1538, 792), 0.36, 12.0)
        paste_rounded(img, paper, (8, 8, size[0] - 14, size[1] - 20), 11)
        draw = ImageDraw.Draw(img, "RGBA")
        draw.rounded_rectangle((7, 7, size[0] - 14, size[1] - 20), radius=11, outline=(66, 38, 18, 255), width=6)
        draw.rounded_rectangle((22, 24, size[0] - 30, size[1] - 38), radius=7, outline=(224, 171, 79, 170), width=2)
        draw.rounded_rectangle((42, 108, size[0] - 44, 316), radius=6, fill=(92, 55, 28, 82), outline=(92, 55, 28, 116), width=2)
        for y in [356, 414, 472]:
            draw.rounded_rectangle((40, y, size[0] - 42, y + 42), radius=5, fill=(245, 224, 178, 112), outline=(116, 75, 40, 105), width=1)
        draw_corner_brackets(draw, (23, 24, size[0] - 30, size[1] - 38), (231, 177, 82, 210), (52, 30, 14, 240), 24, 3)
        save(img, "dish_detail_frame.png")

    save_recipe_grid_frame()
    save_recipe_card_frame()
    save_recipe_dish_thumb_frame()
    save_dish_detail_frame()

    specs = [
        ("meal_result_frame.png", (760, 240), rgba("102840", 238), rgba("59371c"), rgba("f4c56b")),
        ("level_up_frame.png", (680, 460), rgba("102840", 248), rgba("b47a2e"), rgba("ffe0a0")),
        ("status_card_frame.png", (320, 120), rgba("f4e7c9"), rgba("59371c"), rgba("d8a452")),
    ]
    for name, size, fill, border, inner in specs:
        img = Image.new("RGBA", size, (0, 0, 0, 0))
        shadow = Image.new("RGBA", size, (0, 0, 0, 0))
        sd = ImageDraw.Draw(shadow, "RGBA")
        sd.rounded_rectangle((14, 16, size[0] - 8, size[1] - 6), radius=12, fill=(0, 0, 0, 95))
        shadow = shadow.filter(ImageFilter.GaussianBlur(4))
        img.alpha_composite(shadow)
        draw = ImageDraw.Draw(img, "RGBA")
        draw_panel(draw, (8, 8, size[0] - 16, size[1] - 18), fill, border, inner, 5, 9)
        # Corner studs.
        for x, y in [(22, 22), (size[0] - 34, 22), (22, size[1] - 44), (size[0] - 34, size[1] - 44)]:
            draw.rectangle((x, y, x + 12, y + 12), fill=inner, outline=border, width=2)
        save(img, name)


def icon_sheets() -> None:
    cell = 96
    img = Image.new("RGBA", (cell * 10, cell), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img, "RGBA")

    def badge(i: int, fill: tuple[int, int, int, int]) -> tuple[int, int]:
        x = i * cell
        draw.ellipse((x + 12, 14, x + 84, 84), fill=(12, 20, 31, 150))
        draw.ellipse((x + 9, 8, x + 83, 82), fill=fill, outline=(33, 22, 15, 245), width=4)
        draw.ellipse((x + 18, 16, x + 74, 72), outline=(255, 230, 157, 170), width=2)
        draw.ellipse((x + 24, 19, x + 42, 35), fill=(255, 255, 255, 38))
        return x, 0

    # 0: EXP rice bowl.
    x, _ = badge(0, rgba("2f7a45"))
    draw.arc((x + 25, 46, x + 71, 77), 0, 180, fill=(255, 244, 218, 255), width=7)
    draw.arc((x + 30, 38, x + 66, 68), 0, 180, fill=(185, 91, 34, 255), width=8)
    for px, py in [(36, 43), (45, 38), (55, 40), (62, 45)]:
        draw.ellipse((x + px, py, x + px + 9, py + 9), fill=(255, 249, 220, 245))
    draw.polygon([(x + 28, 30), (x + 36, 18), (x + 44, 30)], fill=(158, 233, 89, 245))
    draw.polygon([(x + 68, 30), (x + 60, 18), (x + 52, 30)], fill=(158, 233, 89, 245))

    # 1: first-time bonus flag.
    x, _ = badge(1, rgba("8d2430"))
    draw.rectangle((x + 39, 22, x + 47, 70), fill=(84, 38, 20, 255))
    draw.polygon([(x + 47, 24), (x + 77, 34), (x + 47, 45)], fill=(255, 210, 83, 255), outline=(84, 38, 20, 210))
    draw.arc((x + 26, 59, x + 49, 82), 180, 360, fill=(255, 244, 218, 255), width=6)
    draw.arc((x + 49, 59, x + 72, 82), 180, 360, fill=(255, 244, 218, 255), width=6)

    # 2: total reward star.
    x, _ = badge(2, rgba("6c4a16"))
    points = []
    for p in range(10):
        r = 31 if p % 2 == 0 else 13
        a = -math.pi * 0.5 + math.tau * p / 10
        points.append((x + 46 + math.cos(a) * r, 45 + math.sin(a) * r))
    draw.polygon(points, fill=(255, 226, 96, 255), outline=(91, 54, 18, 230))
    draw.ellipse((x + 38, 37, x + 54, 53), fill=(255, 248, 188, 160))

    # 3: next-fishing buff fish.
    x, _ = badge(3, rgba("1f6b32"))
    fish = [(x + 22, 48), (x + 37, 35), (x + 61, 40), (x + 73, 48), (x + 61, 56), (x + 37, 61)]
    draw.polygon(fish, fill=(109, 226, 255, 255), outline=(18, 28, 34, 240))
    draw.polygon([(x + 62, 40), (x + 84, 28), (x + 77, 48), (x + 84, 68), (x + 62, 56)], fill=(46, 134, 181, 255), outline=(18, 28, 34, 230))
    draw.ellipse((x + 30, 43, x + 38, 51), fill=(8, 16, 24, 255))
    draw.line((x + 28, 69, x + 72, 25), fill=(164, 255, 108, 210), width=5)
    draw.polygon([(x + 72, 25), (x + 62, 26), (x + 72, 36)], fill=(164, 255, 108, 230))

    # 4: player portrait.
    x, _ = badge(4, rgba("163f5f"))
    draw.rectangle((x + 24, 53, x + 73, 80), fill=(28, 71, 113, 255))
    draw.ellipse((x + 26, 19, x + 70, 63), fill=(242, 184, 137, 255), outline=(40, 27, 19, 230), width=2)
    draw.rectangle((x + 24, 21, x + 72, 33), fill=(230, 235, 224, 255), outline=(26, 49, 78, 230), width=2)
    draw.rectangle((x + 33, 12, x + 63, 24), fill=(34, 79, 124, 255))
    draw.arc((x + 32, 19, x + 61, 41), 195, 350, fill=(34, 79, 124, 255), width=7)
    draw.ellipse((x + 38, 39, x + 43, 44), fill=(18, 14, 12, 255))
    draw.ellipse((x + 55, 39, x + 60, 44), fill=(18, 14, 12, 255))
    draw.arc((x + 40, 43, x + 58, 56), 15, 165, fill=(105, 42, 28, 255), width=3)

    # 5: cooler box.
    x, _ = badge(5, rgba("154a75"))
    draw.rectangle((x + 20, 35, x + 76, 72), fill=(31, 91, 141, 255), outline=(9, 48, 78, 255), width=3)
    draw.rectangle((x + 20, 35, x + 76, 45), fill=(235, 244, 250, 255))
    draw.rectangle((x + 29, 22, x + 67, 35), fill=(215, 227, 239, 255), outline=(85, 112, 134, 230), width=2)
    draw.line((x + 35, 29, x + 61, 29), fill=(92, 122, 145, 255), width=3)
    for px in [30, 44, 58]:
        draw.ellipse((x + px, 49, x + px + 16, 57), fill=(184, 198, 205, 230), outline=(68, 87, 94, 180))

    # 6: money.
    x, _ = badge(6, rgba("7b4b20"))
    for k in range(8):
        cx = x + 25 + (k * 15) % 44
        cy = 63 - (k // 3) * 13
        draw.ellipse((cx, cy, cx + 20, cy + 20), fill=(218, 148, 31, 255), outline=(95, 54, 18, 230), width=2)
        draw.ellipse((cx + 4, cy + 4, cx + 16, cy + 16), fill=(255, 216, 107, 235))
    draw.rectangle((x + 55, 36, x + 76, 72), fill=(107, 70, 32, 255), outline=(74, 41, 19, 230), width=2)
    draw.rectangle((x + 50, 31, x + 81, 40), fill=(184, 122, 49, 255))

    # 7: play time.
    x, _ = badge(7, rgba("5e4630"))
    draw.ellipse((x + 24, 24, x + 72, 72), fill=(255, 241, 204, 255), outline=(87, 50, 20, 255), width=4)
    draw.line((x + 48, 48, x + 48, 28), fill=(42, 33, 24, 255), width=4)
    draw.line((x + 48, 48, x + 63, 58), fill=(42, 33, 24, 255), width=4)
    draw.ellipse((x + 44, 44, x + 52, 52), fill=(42, 33, 24, 255))
    draw.arc((x + 22, 13, x + 43, 35), 205, 340, fill=(218, 158, 63, 255), width=5)
    draw.arc((x + 53, 13, x + 74, 35), 200, 335, fill=(218, 158, 63, 255), width=5)

    # 8: return/ready anchor.
    x, _ = badge(8, rgba("17324d"))
    draw.line((x + 48, 20, x + 48, 66), fill=(255, 226, 96, 255), width=6)
    draw.ellipse((x + 40, 11, x + 56, 27), fill=(15, 34, 55, 255), outline=(255, 226, 96, 255), width=4)
    draw.arc((x + 23, 42, x + 73, 82), 10, 170, fill=(255, 226, 96, 255), width=6)
    draw.polygon([(x + 23, 59), (x + 13, 52), (x + 27, 47)], fill=(255, 226, 96, 255))
    draw.polygon([(x + 73, 59), (x + 83, 52), (x + 69, 47)], fill=(255, 226, 96, 255))

    # 9: growth/level-up crown.
    x, _ = badge(9, rgba("8d2430"))
    crown = [(x + 22, 56), (x + 31, 28), (x + 41, 48), (x + 48, 24), (x + 55, 48), (x + 65, 28), (x + 74, 56)]
    draw.polygon(crown + [(x + 70, 70), (x + 26, 70)], fill=(255, 224, 129, 255), outline=(76, 43, 11, 255))
    for px, py in [(31, 28), (48, 24), (65, 28)]:
        draw.ellipse((x + px - 5, py - 5, x + px + 5, py + 5), fill=(255, 241, 199, 255))
    draw.rectangle((x + 26, 58, x + 70, 70), fill=(255, 224, 129, 255), outline=(76, 43, 11, 255), width=2)

    save(img, "cooking_icon_sheet.png")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    cooking_room_bg()
    meal_scene_bg()
    exp_stage_bg()
    fish_icon_sheet()
    fish_row_frame()
    dish_icon_sheet()
    dish_feature()
    cooking_title_banner()
    cooking_section_ribbon()
    recipe_to_detail_arrow()
    recipe_selected_card_frame()
    recipe_material_strip_frame()
    cook_detail_row_frame()
    cook_button_frame()
    cook_action_runway_frame()
    prep_summary_bar_frame()
    prep_summary_card_frame()
    flow_action_button_frame()
    player_eating_pose()
    meal_table_spread()
    player_status_portrait()
    player_exp_message_pose()
    next_effect_art()
    status_summary_bg()
    status_cooler_art()
    status_money_art()
    status_clock_art()
    meal_banner_frame()
    exp_burst_frame()
    level_crown_asset()
    level_laurel_asset("level_laurel_left.png", -1)
    level_laurel_asset("level_laurel_right.png", 1)
    level_unlock_medallion()
    level_unlock_spot()
    level_unlock_ribbon()
    level_stat_row_frame()
    reward_card_frame()
    meal_dish_card_frame()
    frame_assets()
    icon_sheets()
    print(f"generated cooking showcase assets in {OUT}")


if __name__ == "__main__":
    main()
