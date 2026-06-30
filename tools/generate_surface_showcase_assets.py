#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "showcase" / "surface"

CANVAS_W = 960
CANVAS_H = 405
HORIZON_Y = 174


def rgba(hex_value: str, alpha: int = 255) -> tuple[int, int, int, int]:
    value = hex_value.strip().lstrip("#")
    return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16), alpha)


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def mix(c1: tuple[int, int, int], c2: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    t = max(0.0, min(1.0, t))
    return (round(lerp(c1[0], c2[0], t)), round(lerp(c1[1], c2[1], t)), round(lerp(c1[2], c2[2], t)))


def noise_color(color: tuple[int, int, int], amount: int, rng: random.Random) -> tuple[int, int, int]:
    delta = rng.randint(-amount, amount)
    return tuple(max(0, min(255, channel + delta)) for channel in color)


def save_image(image: Image.Image, path: Path) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    image.save(path)
    print(path.relative_to(ROOT))


class HiCanvas:
    def __init__(self, width: int, height: int, scale: int = 3, fill: tuple[int, int, int, int] = (0, 0, 0, 0)) -> None:
        self.width = width
        self.height = height
        self.scale = scale
        self.image = Image.new("RGBA", (width * scale, height * scale), fill)
        self.draw = ImageDraw.Draw(self.image, "RGBA")

    def p(self, point: tuple[float, float]) -> tuple[int, int]:
        return (round(point[0] * self.scale), round(point[1] * self.scale))

    def box(self, rect: tuple[float, float, float, float]) -> tuple[int, int, int, int]:
        return tuple(round(v * self.scale) for v in rect)  # type: ignore[return-value]

    def poly(self, points: list[tuple[float, float]], fill: tuple[int, int, int, int]) -> None:
        self.draw.polygon([self.p(point) for point in points], fill=fill)

    def rect(self, rect: tuple[float, float, float, float], fill: tuple[int, int, int, int], outline: tuple[int, int, int, int] | None = None, width: float = 1.0) -> None:
        self.draw.rectangle(self.box(rect), fill=fill, outline=outline, width=max(1, round(width * self.scale)))

    def ellipse(self, rect: tuple[float, float, float, float], fill: tuple[int, int, int, int], outline: tuple[int, int, int, int] | None = None, width: float = 1.0) -> None:
        self.draw.ellipse(self.box(rect), fill=fill, outline=outline, width=max(1, round(width * self.scale)))

    def line(self, points: list[tuple[float, float]], fill: tuple[int, int, int, int], width: float = 1.0) -> None:
        self.draw.line([self.p(point) for point in points], fill=fill, width=max(1, round(width * self.scale)), joint="curve")

    def paste_layer(self, layer: Image.Image) -> None:
        self.image.alpha_composite(layer)

    def finish(self) -> Image.Image:
        return self.image.resize((self.width, self.height), Image.Resampling.LANCZOS)


def draw_blur_ellipse(target: Image.Image, rect: tuple[float, float, float, float], color: tuple[int, int, int, int], blur: float, scale: int = 3) -> None:
    layer = Image.new("RGBA", target.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer, "RGBA")
    scaled = tuple(round(v * scale) for v in rect)
    draw.ellipse(scaled, fill=color)
    layer = layer.filter(ImageFilter.GaussianBlur(blur * scale))
    target.alpha_composite(layer)


def draw_cloud(canvas: HiCanvas, cx: float, cy: float, scale: float, alpha: int = 230) -> None:
    shadow = rgba("#87cfe4", round(alpha * 0.34))
    white = (255, 255, 255, alpha)
    pieces = [
        (-44, 5, 56, 20),
        (-24, -10, 58, 32),
        (12, -18, 66, 39),
        (48, -7, 54, 27),
        (77, 5, 32, 18),
    ]
    for x, y, w, h in pieces:
        canvas.ellipse((cx + x * scale, cy + y * scale + 6 * scale, cx + (x + w) * scale, cy + (y + h) * scale + 6 * scale), shadow)
    for x, y, w, h in pieces:
        canvas.ellipse((cx + x * scale, cy + y * scale, cx + (x + w) * scale, cy + (y + h) * scale), white)
    canvas.rect((cx - 54 * scale, cy + 9 * scale, cx + 112 * scale, cy + 22 * scale), (255, 255, 255, round(alpha * 0.55)))


def draw_palm(canvas: HiCanvas, base: tuple[float, float], scale: float) -> None:
    x, y = base
    top = (x + 9 * scale, y - 45 * scale)
    canvas.line([(x, y), top], rgba("#6d431e", 235), 4.5 * scale)
    canvas.line([(x + 2 * scale, y - 2 * scale), (top[0] + 2 * scale, top[1] + 4 * scale)], rgba("#ba7c34", 150), 1.6 * scale)
    for idx, angle in enumerate([-2.75, -2.35, -1.95, -1.42, -0.95, -0.52]):
        length = (31 + (idx % 2) * 8) * scale
        tip = (top[0] + math.cos(angle) * length, top[1] + math.sin(angle) * length)
        canvas.line([top, tip], rgba("#0f6940", 230), 5.0 * scale)
        canvas.line([top, (tip[0] * 0.82 + top[0] * 0.18, tip[1] * 0.82 + top[1] * 0.18)], rgba("#30a466", 155), 2.0 * scale)


def process_source_background(source: Path) -> bool:
    if not source.exists():
        return False
    image = Image.open(source).convert("RGBA")
    width, height = image.size
    target_ratio = CANVAS_W / CANVAS_H
    crop_w = min(width, round(height * target_ratio))
    crop_h = round(crop_w / target_ratio)
    crop_w = min(crop_w, width)
    crop_h = min(crop_h, height)
    left = max(0, min(width - crop_w, 40))
    top = max(0, min(height - crop_h, 60))
    crop = image.crop((left, top, left + crop_w, top + crop_h))
    crop = crop.resize((CANVAS_W, CANVAS_H), Image.Resampling.LANCZOS)

    grade = Image.new("RGBA", crop.size, (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(grade, "RGBA")
    gdraw.rectangle((0, 0, CANVAS_W, CANVAS_H), fill=(0, 24, 50, 16))
    gdraw.rectangle((0, round(CANVAS_H * 0.74), CANVAS_W, CANVAS_H), fill=(0, 30, 48, 32))
    crop.alpha_composite(grade)
    crop = ImageEnhanceProxy(crop).color(1.06).contrast(1.04).sharpness(1.08).image
    save_image(crop, OUT_DIR / "surface_cast_bg.png")
    return True


class ImageEnhanceProxy:
    def __init__(self, image: Image.Image) -> None:
        self.image = image

    def color(self, value: float) -> "ImageEnhanceProxy":
        from PIL import ImageEnhance

        self.image = ImageEnhance.Color(self.image).enhance(value)
        return self

    def contrast(self, value: float) -> "ImageEnhanceProxy":
        from PIL import ImageEnhance

        self.image = ImageEnhance.Contrast(self.image).enhance(value)
        return self

    def sharpness(self, value: float) -> "ImageEnhanceProxy":
        from PIL import ImageEnhance

        self.image = ImageEnhance.Sharpness(self.image).enhance(value)
        return self


def create_background() -> None:
    if process_source_background(OUT_DIR / "surface_cast_bg_source.png"):
        return

    rng = random.Random(7001)
    canvas = HiCanvas(CANVAS_W, CANVAS_H, 3, (0, 0, 0, 255))
    pix = canvas.image.load()
    sky_top = (77, 194, 232)
    sky_low = (196, 243, 249)
    sea_top = (27, 173, 216)
    sea_mid = (16, 127, 190)
    sea_deep = (6, 75, 130)
    scale = canvas.scale
    for y in range(CANVAS_H * scale):
        yy = y / scale
        if yy < HORIZON_Y:
            t = yy / max(1, HORIZON_Y)
            base = mix(sky_top, sky_low, t)
            haze = 20 if yy > HORIZON_Y * 0.74 else 0
            base = (min(255, base[0] + haze), min(255, base[1] + haze), min(255, base[2] + haze))
        else:
            t = (yy - HORIZON_Y) / max(1, CANVAS_H - HORIZON_Y)
            base = mix(sea_top, sea_mid, min(1.0, t * 1.35))
            base = mix(base, sea_deep, max(0.0, (t - 0.42) / 0.58))
        for x in range(CANVAS_W * scale):
            delta = ((x * 3 + y * 5) % 17) - 8
            pix[x, y] = (max(0, min(255, base[0] + delta // 5)), max(0, min(255, base[1] + delta // 4)), max(0, min(255, base[2] + delta // 3)), 255)

    draw_blur_ellipse(canvas.image, (654, -8, 840, 178), (255, 242, 160, 44), 21, scale)
    draw_blur_ellipse(canvas.image, (700, 37, 787, 124), (255, 243, 157, 205), 2.0, scale)
    canvas.ellipse((714, 50, 774, 111), rgba("#fff4a8", 244))
    canvas.ellipse((721, 54, 749, 82), (255, 255, 255, 106))
    for i in range(14):
        a = i / 14 * math.tau + 0.17
        start = (744 + math.cos(a) * 45, 82 + math.sin(a) * 43)
        end = (744 + math.cos(a) * (96 + (i % 3) * 12), 82 + math.sin(a) * (92 + (i % 3) * 8))
        canvas.line([start, end], (255, 245, 174, 45), 2.4)

    draw_cloud(canvas, 180, 58, 0.72, 238)
    draw_cloud(canvas, 355, 91, 0.48, 220)
    draw_cloud(canvas, 567, 72, 0.53, 210)
    draw_cloud(canvas, 871, 50, 0.61, 205)

    left_far = [(0, HORIZON_Y - 1), (46, 143), (126, 121), (220, 151), (282, HORIZON_Y - 1)]
    canvas.poly(left_far, rgba("#184d3a", 255))
    canvas.poly([(0, HORIZON_Y - 3), (65, 149), (142, 132), (236, HORIZON_Y - 2)], rgba("#2c7b4c", 240))
    canvas.poly([(0, HORIZON_Y - 1), (80, 167), (200, 165), (284, HORIZON_Y - 1)], rgba("#e2cb84", 185))
    for i in range(8):
        draw_palm(canvas, (48 + i * 25, 154 + (i % 3) * 4), 0.44 + (i % 2) * 0.05)

    canvas.poly([(790, HORIZON_Y - 1), (835, 146), (914, 126), (960, 154), (960, HORIZON_Y - 1)], rgba("#14513f", 255))
    canvas.poly([(803, HORIZON_Y - 2), (853, 151), (921, 139), (960, 160), (960, HORIZON_Y - 2)], rgba("#2d8661", 225))
    canvas.line([(0, HORIZON_Y), (CANVAS_W, HORIZON_Y)], (238, 255, 255, 150), 2.0)
    canvas.line([(0, HORIZON_Y + 3), (CANVAS_W, HORIZON_Y + 2)], (255, 255, 255, 72), 1.2)

    sun_x = 744
    for i in range(34):
        t = i / 33
        y = HORIZON_Y + 8 + t * 118
        half = 18 + t * 148
        alpha = round(68 * (1.0 - t) ** 1.65)
        canvas.line([(sun_x - half, y), (sun_x + half, y + math.sin(i * 0.8) * 1.5)], (255, 247, 177, alpha), 2.2)

    for i in range(112):
        lane = i % 14
        y = HORIZON_Y + 9 + lane * 15.1 + math.sin(i * 1.7) * 2.2
        x = (i * 83 + (lane * 19)) % (CANVAS_W + 120) - 60
        width = 16 + (i % 7) * 8
        alpha = 28 + (i % 5) * 8
        if y > CANVAS_H - 18:
            alpha = round(alpha * 0.55)
        canvas.line([(x, y), (x + width, y + math.sin(i) * 0.9)], (223, 250, 255, alpha), 1.5 + (i % 3) * 0.35)

    for i in range(86):
        x = rng.randrange(24, CANVAS_W - 20)
        y = rng.randrange(HORIZON_Y + 16, CANVAS_H - 18)
        if rng.random() < 0.45:
            canvas.rect((x, y, x + rng.randrange(2, 6), y + 1), (255, 255, 255, rng.randrange(38, 92)))
        else:
            canvas.ellipse((x - 1, y - 1, x + 2, y + 2), (255, 255, 255, rng.randrange(28, 64)))

    for i in range(9):
        bx = 330 + i * 38
        by = 126 + (i % 3) * 9
        canvas.line([(bx - 8, by), (bx, by - 4), (bx + 8, by)], rgba("#163f4e", 118), 1.6)

    vignette = Image.new("L", canvas.image.size, 0)
    vdraw = ImageDraw.Draw(vignette)
    inset = round(16 * scale)
    vdraw.rectangle((inset, inset, canvas.image.size[0] - inset, canvas.image.size[1] - inset), fill=0)
    vignette = ImageOps.invert(vignette.filter(ImageFilter.GaussianBlur(58 * scale)))
    shade = Image.new("RGBA", canvas.image.size, (0, 18, 34, 0))
    shade.putalpha(vignette.point(lambda value: round((255 - value) * 0.20)))
    canvas.image.alpha_composite(shade)

    save_image(canvas.finish(), OUT_DIR / "surface_cast_bg.png")


def create_dock_foreground() -> None:
    bg_path = OUT_DIR / "surface_cast_bg.png"
    if bg_path.exists():
        bg = Image.open(bg_path).convert("RGBA")
        mask = Image.new("L", bg.size, 0)
        draw = ImageDraw.Draw(mask)
        draw.polygon([(584, 276), (960, 264), (960, 405), (622, 405), (590, 335)], fill=255)
        draw.rectangle((690, 220, 960, 405), fill=255)
        mask = mask.filter(ImageFilter.GaussianBlur(0.8))
        dock = bg.copy()
        dock.putalpha(mask)
        save_image(dock, OUT_DIR / "surface_dock_foreground.png")
        return

    canvas = HiCanvas(CANVAS_W, CANVAS_H, 3)
    top = 278
    deck = [(593, top - 3), (960, top - 3), (960, 405), (648, 405), (604, 337)]
    side = [(604, top + 28), (960, top + 28), (960, 405), (647, 405)]
    canvas.poly(side, rgba("#543014", 255))
    canvas.poly(deck, rgba("#8f5729", 255))
    canvas.poly([(593, top - 13), (960, top - 13), (960, top + 20), (610, top + 20)], rgba("#d19b4c", 255))
    canvas.line([(602, top - 9), (960, top - 9)], rgba("#f0c56d", 205), 2.0)
    canvas.line([(610, top + 19), (960, top + 19)], rgba("#3e2412", 190), 2.3)

    for i in range(10):
        x0 = 606 + i * 39
        xb = 646 + i * 45
        canvas.line([(x0, top - 12), (xb, 405)], rgba("#4d2c15", 205), 2.0)
        canvas.line([(x0 + 3, top - 8), (xb + 4, 405)], rgba("#b97738", 135), 0.9)
    for i in range(7):
        y = top + 29 + i * 19
        left_x = 612 + i * 7
        canvas.line([(left_x, y), (960, y - 6)], rgba("#71401d", 210), 1.7)
        canvas.line([(left_x + 3, y + 3), (960, y - 3)], rgba("#a56a31", 90), 1.0)

    for i, x in enumerate([641, 724, 808, 893]):
        y0 = top + 10 + (i % 2) * 5
        canvas.rect((x - 9, y0 - 64, x + 9, 405), rgba("#442412", 255))
        canvas.rect((x - 5, y0 - 61, x - 1, 405), rgba("#b47a38", 155))
        canvas.rect((x + 6, y0 - 60, x + 9, 405), rgba("#23140b", 180))
        canvas.ellipse((x - 12, y0 - 76, x + 12, y0 - 52), rgba("#b97a34", 255))
        canvas.ellipse((x - 7, y0 - 73, x + 2, y0 - 62), rgba("#f2c76a", 165))
        if i < 3:
            nx = [724, 808, 893][i]
            canvas.line([(x + 9, y0 - 48), (nx - 9, y0 - 41 + (i % 2) * 8)], rgba("#392515", 210), 3.5)
            canvas.line([(x + 8, y0 - 46), (nx - 8, y0 - 39 + (i % 2) * 8)], rgba("#d09a53", 92), 1.2)

    for x in [629, 675, 719, 766, 812, 856, 902, 943]:
        for y in [top + 2, top + 19]:
            canvas.ellipse((x - 2.2, y - 1.5, x + 2.2, y + 1.5), rgba("#3b2413", 185))

    # Props on the near pier: crate, bucket, coiled rope and small tackle box.
    canvas.rect((812, 306, 858, 344), rgba("#70421f", 255), rgba("#402310", 230), 2.0)
    canvas.rect((817, 311, 853, 318), rgba("#c98a3d", 205))
    canvas.line([(813, 329), (858, 329)], rgba("#3f230f", 170), 1.3)
    canvas.ellipse((876, 326, 914, 360), rgba("#563117", 255), rgba("#2e1a0e", 210), 2.0)
    canvas.ellipse((883, 331, 907, 353), rgba("#9d642c", 220))
    canvas.rect((878, 320, 912, 331), rgba("#71451f", 245))
    for i in range(4):
        cx = 768 + i * 6
        canvas.ellipse((cx - 18, 340 + i * 2, cx + 18, 368 + i * 3), (43, 30, 18, 0), rgba("#332214", 210), 2.3)
    canvas.rect((918, 299, 951, 320), rgba("#13374b", 230), rgba("#061f2d", 230), 2.0)
    canvas.rect((924, 294, 945, 300), rgba("#d3a34e", 235), rgba("#5e3a17", 210), 1.5)

    shadow = Image.new("RGBA", canvas.image.size, (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow, "RGBA")
    s = canvas.scale
    sdraw.polygon([(0, 323 * s), (604 * s, 311 * s), (683 * s, 405 * s), (0, 405 * s)], fill=(0, 20, 31, 42))
    shadow = shadow.filter(ImageFilter.GaussianBlur(3.0 * s))
    canvas.image.alpha_composite(shadow)

    save_image(canvas.finish(), OUT_DIR / "surface_dock_foreground.png")


def create_ambience() -> None:
    canvas = HiCanvas(CANVAS_W, CANVAS_H, 3)
    for i in range(18):
        t = i / 17
        x = 680 + math.sin(i * 1.2) * 38
        y = HORIZON_Y + 18 + t * 150
        w = 42 + t * 120
        canvas.line([(x - w, y), (x + w, y + math.sin(i) * 1.2)], (255, 246, 182, round(28 * (1 - t))), 2.0)
    for i in range(38):
        x = 40 + (i * 149) % 872
        y = HORIZON_Y + 30 + (i * 71) % 168
        a = 34 + (i % 4) * 11
        canvas.line([(x - 4, y), (x + 4, y)], (255, 255, 255, a), 1.2)
        canvas.line([(x, y - 3), (x, y + 3)], (255, 255, 255, round(a * 0.44)), 1.0)
    for i in range(7):
        x = 130 + i * 110
        canvas.line([(x, 0), (x + 104 + math.sin(i) * 38, 310)], (205, 245, 255, 16), 9.0 + i % 2)
    save_image(canvas.finish(), OUT_DIR / "surface_foreground_ambience.png")


def create_color_grade() -> None:
    canvas = HiCanvas(CANVAS_W, CANVAS_H, 3)
    draw_blur_ellipse(canvas.image, (-90, 212, 380, 526), (0, 33, 58, 42), 16, canvas.scale)
    draw_blur_ellipse(canvas.image, (760, -50, 1080, 210), (255, 236, 151, 34), 24, canvas.scale)
    save_image(canvas.finish(), OUT_DIR / "surface_color_grade.png")


def draw_angler_common(canvas: HiCanvas, casting: bool) -> None:
    body_x = 194
    foot_y = 137
    bob = -3 if casting else 0
    canvas.ellipse((body_x - 28, foot_y + 3, body_x + 32, foot_y + 15), (0, 0, 0, 76))
    canvas.rect((body_x - 16, foot_y - 55 + bob, body_x + 17, foot_y - 18 + bob), rgba("#244a63", 255), rgba("#0e2534", 230), 2.0)
    canvas.rect((body_x - 16, foot_y - 55 + bob, body_x + 17, foot_y - 45 + bob), rgba("#3c86a9", 255))
    canvas.rect((body_x - 19, foot_y - 23 + bob, body_x - 4, foot_y + 10), rgba("#1c2d3b", 255))
    canvas.rect((body_x + 4, foot_y - 23 + bob, body_x + 20, foot_y + 10), rgba("#1c2d3b", 255))
    canvas.rect((body_x - 24, foot_y + 5, body_x - 1, foot_y + 13), rgba("#141b22", 255))
    canvas.rect((body_x + 3, foot_y + 5, body_x + 26, foot_y + 13), rgba("#141b22", 255))
    canvas.ellipse((body_x - 17, foot_y - 82 + bob, body_x + 17, foot_y - 48 + bob), rgba("#e5b081", 255), rgba("#5b341c", 180), 1.4)
    canvas.rect((body_x - 24, foot_y - 87 + bob, body_x + 23, foot_y - 75 + bob), rgba("#623619", 255))
    canvas.rect((body_x - 11, foot_y - 93 + bob, body_x + 15, foot_y - 83 + bob), rgba("#79451f", 255))
    canvas.rect((body_x - 8, foot_y - 67 + bob, body_x - 5, foot_y - 64 + bob), rgba("#101018", 255))
    canvas.rect((body_x + 8, foot_y - 67 + bob, body_x + 11, foot_y - 64 + bob), rgba("#101018", 255))

    hand = rgba("#e5b081", 255)
    if casting:
        canvas.line([(body_x - 13, foot_y - 48 + bob), (body_x - 47, foot_y - 70 + bob), (body_x - 73, foot_y - 90 + bob)], hand, 7.0)
        canvas.line([(body_x + 10, foot_y - 48 + bob), (body_x - 29, foot_y - 65 + bob), (body_x - 57, foot_y - 78 + bob)], hand, 6.0)
        rod = [(body_x - 68, foot_y - 90 + bob), (118, 45), (31, 18)]
    else:
        canvas.line([(body_x - 15, foot_y - 43), (body_x - 40, foot_y - 49), (body_x - 59, foot_y - 61)], hand, 7.0)
        canvas.line([(body_x + 10, foot_y - 44), (body_x - 20, foot_y - 50), (body_x - 44, foot_y - 59)], hand, 6.0)
        rod = [(body_x - 56, foot_y - 61), (114, 54), (47, 33)]
    canvas.line(rod, rgba("#4c2a12", 255), 5.0)
    canvas.line([(rod[0][0] + 1, rod[0][1] - 1), (rod[1][0] + 1, rod[1][1] - 2), (rod[2][0] + 1, rod[2][1] - 1)], rgba("#d99b42", 220), 1.6)
    canvas.ellipse((rod[-1][0] - 3, rod[-1][1] - 3, rod[-1][0] + 3, rod[-1][1] + 3), rgba("#261508", 255))
    canvas.ellipse((body_x - 48, foot_y - 64 + bob, body_x - 35, foot_y - 51 + bob), rgba("#25252a", 255), rgba("#caa44c", 200), 1.4)


def create_angler_sprites() -> None:
    for filename, casting in [("surface_angler_idle.png", False), ("surface_angler_cast.png", True)]:
        canvas = HiCanvas(260, 160, 4)
        draw_angler_common(canvas, casting)
        save_image(canvas.finish(), OUT_DIR / filename)


def create_bobber() -> None:
    canvas = HiCanvas(56, 76, 4)
    canvas.line([(28, 4), (28, 64)], rgba("#4c2b15", 222), 2.0)
    canvas.ellipse((17, 31, 39, 57), rgba("#fff1b7", 255), rgba("#5d3016", 235), 2.0)
    canvas.paste_layer(Image.new("RGBA", canvas.image.size, (0, 0, 0, 0)))
    canvas.rect((18, 43, 38, 56), rgba("#d83a2c", 255))
    canvas.ellipse((19, 31, 38, 47), rgba("#fff1b7", 255))
    canvas.ellipse((21, 33, 28, 40), (255, 255, 255, 190))
    canvas.ellipse((22, 58, 34, 68), rgba("#bc2b22", 235), rgba("#5d3016", 180), 1.2)
    save_image(canvas.finish(), OUT_DIR / "surface_bobber.png")


def create_fish_shadow() -> None:
    canvas = HiCanvas(224, 86, 4)
    canvas.ellipse((41, 24, 176, 62), rgba("#062c3d", 142))
    canvas.poly([(42, 43), (5, 21), (14, 43), (5, 66)], rgba("#062c3d", 125))
    canvas.poly([(128, 31), (166, 7), (150, 36)], rgba("#062c3d", 83))
    canvas.ellipse((123, 29, 156, 55), (255, 255, 255, 21))
    canvas.ellipse((157, 36, 163, 42), (255, 255, 255, 64))
    for i in range(5):
        x = 20 + i * 16
        y = 15 + (i % 3) * 10
        canvas.ellipse((x, y, x + 6 + i % 2, y + 6 + i % 2), (255, 255, 255, 46))
    save_image(canvas.finish(), OUT_DIR / "surface_fish_shadow.png")


def create_splash() -> None:
    canvas = HiCanvas(184, 118, 4)
    for i in range(4):
        canvas.ellipse((38 - i * 5, 70 - i * 2, 146 + i * 5, 92 + i * 2), (0, 0, 0, 0), (255, 255, 255, 120 - i * 20), 2.0)
    center = (92, 75)
    for i in range(18):
        angle = -math.pi * 0.92 + i / 17 * math.pi * 0.84
        length = 30 + (i % 5) * 7
        start = (center[0] + math.cos(angle) * 17, center[1] + math.sin(angle) * 8)
        end = (center[0] + math.cos(angle) * length, center[1] + math.sin(angle) * length * 0.78)
        canvas.line([start, end], (234, 255, 255, 170), 2.4)
        canvas.ellipse((end[0] - 3, end[1] - 3, end[0] + 3, end[1] + 3), (255, 255, 255, 205))
    canvas.ellipse((64, 52, 121, 85), (255, 255, 255, 126))
    canvas.ellipse((72, 61, 112, 83), rgba("#80dcf0", 116))
    save_image(canvas.finish(), OUT_DIR / "surface_splash.png")


def _scene_source_base(source_name: str = "surface_scene_source.png") -> Image.Image:
    source_path = OUT_DIR / source_name
    if not source_path.exists():
        return Image.open(OUT_DIR / "surface_cast_bg.png").convert("RGBA")
    source = Image.open(source_path).convert("RGBA")
    scaled_h = round(source.height * CANVAS_W / source.width)
    scaled = source.resize((CANVAS_W, scaled_h), Image.Resampling.LANCZOS)
    if scaled_h >= CANVAS_H:
        y0 = 0
        return scaled.crop((0, y0, CANVAS_W, y0 + CANVAS_H))
    plate = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 255))
    plate.alpha_composite(scaled, (0, (CANVAS_H - scaled_h) // 2))
    return plate


def _try_save_scene_state_from_source(state: str) -> bool:
    source_name = f"surface_scene_{state}_source.png"
    source_path = OUT_DIR / source_name
    if not source_path.exists():
        return False
    _save_scene_plate(_scene_source_base(source_name), f"surface_scene_{state}.png")
    return True


def _draw_state_fish(draw: ImageDraw.ImageDraw, center: tuple[float, float], scale: float, alpha: int) -> None:
    cx, cy = center
    body = (cx - 60 * scale, cy - 18 * scale, cx + 56 * scale, cy + 18 * scale)
    draw.ellipse(body, fill=(3, 42, 60, alpha))
    draw.polygon(
        [
            (cx - 57 * scale, cy),
            (cx - 96 * scale, cy - 24 * scale),
            (cx - 88 * scale, cy),
            (cx - 96 * scale, cy + 24 * scale),
        ],
        fill=(3, 42, 60, round(alpha * 0.72)),
    )
    draw.polygon(
        [
            (cx + 2 * scale, cy - 10 * scale),
            (cx + 32 * scale, cy - 34 * scale),
            (cx + 22 * scale, cy - 5 * scale),
        ],
        fill=(3, 42, 60, round(alpha * 0.34)),
    )
    draw.ellipse((cx + 31 * scale, cy - 8 * scale, cx + 39 * scale, cy), fill=(214, 247, 255, round(alpha * 0.22)))
    draw.ellipse((cx - 5 * scale, cy - 13 * scale, cx + 30 * scale, cy + 13 * scale), fill=(255, 255, 255, round(alpha * 0.05)))


def _draw_ripple(draw: ImageDraw.ImageDraw, center: tuple[float, float], rx: float, ry: float, alpha: int, width: int = 2) -> None:
    cx, cy = center
    draw.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), outline=(232, 255, 255, alpha), width=width)


def _draw_splash_burst(draw: ImageDraw.ImageDraw, center: tuple[float, float]) -> None:
    cx, cy = center
    for index in range(4):
        _draw_ripple(draw, (cx, cy + 8), 34 + index * 18, 10 + index * 5, 154 - index * 30, 3)
    for index in range(24):
        angle = -math.pi * 0.95 + (index / 23.0) * math.pi * 0.92
        length = 20 + (index % 7) * 8
        sx = cx + math.cos(angle) * 14
        sy = cy + math.sin(angle) * 8
        ex = cx + math.cos(angle) * length
        ey = cy + math.sin(angle) * length * 0.82
        draw.line((sx, sy, ex, ey), fill=(238, 255, 255, 218), width=3)
        draw.ellipse((ex - 3, ey - 3, ex + 3, ey + 3), fill=(255, 255, 255, 232))
    draw.ellipse((cx - 30, cy - 19, cx + 35, cy + 21), fill=(255, 255, 255, 130))
    draw.ellipse((cx - 21, cy - 9, cx + 25, cy + 18), fill=(92, 213, 232, 142))


def _add_vignette(image: Image.Image, color: tuple[int, int, int, int], strength: float) -> None:
    mask = Image.new("L", image.size, 0)
    draw = ImageDraw.Draw(mask)
    inset = 18
    draw.rectangle((inset, inset, image.width - inset, image.height - inset), fill=0)
    mask = ImageOps.invert(mask.filter(ImageFilter.GaussianBlur(48)))
    layer = Image.new("RGBA", image.size, color)
    layer.putalpha(mask.point(lambda value: round((255 - value) * strength)))
    image.alpha_composite(layer)


def _save_scene_plate(image: Image.Image, name: str) -> None:
    _add_vignette(image, (0, 18, 36, 255), 0.16)
    opaque = Image.new("RGBA", image.size, (0, 0, 0, 255))
    opaque.alpha_composite(image)
    save_image(opaque, OUT_DIR / name)


def create_scene_state_plates() -> None:
    base = _scene_source_base()
    bobber = (270, 303)
    rod_tip = (522, 178)

    ready = base.copy()
    _save_scene_plate(ready, "surface_scene_ready.png")

    if _try_save_scene_state_from_source("casting"):
        casting = None
    else:
        casting = base.copy()
        casting_overlay = Image.new("RGBA", casting.size, (0, 0, 0, 0))
        cd = ImageDraw.Draw(casting_overlay, "RGBA")
        cd.line([(643, 238), (552, 175), (454, 165), (349, 215), (279, 292)], fill=(255, 255, 255, 132), width=3, joint="curve")
        cd.line([(641, 238), (552, 175), (454, 165), (349, 215), (279, 292)], fill=(32, 98, 120, 58), width=1, joint="curve")
        for i in range(5):
            cd.arc((244 - i * 7, 275 - i * 4, 318 + i * 9, 322 + i * 4), 194, 338, fill=(238, 255, 255, 70 - i * 9), width=2)
        cd.ellipse((rod_tip[0] - 10, rod_tip[1] - 10, rod_tip[0] + 10, rod_tip[1] + 10), fill=(255, 232, 142, 28))
        casting.alpha_composite(casting_overlay)
        _save_scene_plate(casting, "surface_scene_casting.png")

    if _try_save_scene_state_from_source("waiting"):
        waiting = None
    else:
        waiting = base.copy()
        waiting_overlay = Image.new("RGBA", waiting.size, (0, 0, 0, 0))
        wd = ImageDraw.Draw(waiting_overlay, "RGBA")
        for i in range(5):
            _draw_ripple(wd, bobber, 26 + i * 16, 8 + i * 4, 150 - i * 24, 2)
        for i in range(18):
            x = 228 + (i * 29) % 164
            y = 271 + (i * 17) % 58
            wd.line((x - 6, y, x + 7, y), fill=(255, 255, 255, 80), width=1)
        waiting.alpha_composite(waiting_overlay)
        _save_scene_plate(waiting, "surface_scene_waiting.png")

    if _try_save_scene_state_from_source("approach"):
        approach = None
    else:
        approach = base.copy()
        approach_overlay = Image.new("RGBA", approach.size, (0, 0, 0, 0))
        ad = ImageDraw.Draw(approach_overlay, "RGBA")
        _draw_state_fish(ad, (224, 314), 0.58, 112)
        ad.line((209, 309, 247, 303, 274, 304), fill=(226, 255, 255, 88), width=2)
        for i in range(4):
            _draw_ripple(ad, (240 + i * 12, 307 + i), 28 + i * 10, 7 + i * 3, 96 - i * 17, 2)
        ad.ellipse((bobber[0] - 9, bobber[1] - 9, bobber[0] + 9, bobber[1] + 9), fill=(255, 246, 160, 78))
        approach.alpha_composite(approach_overlay)
        _save_scene_plate(approach, "surface_scene_approach.png")

    if _try_save_scene_state_from_source("bite"):
        return

    bite = base.copy()
    bite_overlay = Image.new("RGBA", bite.size, (0, 0, 0, 0))
    bd = ImageDraw.Draw(bite_overlay, "RGBA")
    _draw_state_fish(bd, (232, 314), 0.72, 148)
    _draw_splash_burst(bd, bobber)
    bd.line([(642, 238), (526, 179), (390, 229), (bobber[0], bobber[1] - 2)], fill=(255, 255, 255, 226), width=4, joint="curve")
    bite.alpha_composite(bite_overlay)
    flash = Image.new("RGBA", bite.size, (255, 244, 170, 24))
    bite.alpha_composite(flash)
    _save_scene_plate(bite, "surface_scene_bite.png")


def main() -> None:
    create_background()
    create_dock_foreground()
    create_ambience()
    create_color_grade()
    create_angler_sprites()
    create_bobber()
    create_fish_shadow()
    create_splash()
    create_scene_state_plates()


if __name__ == "__main__":
    main()
