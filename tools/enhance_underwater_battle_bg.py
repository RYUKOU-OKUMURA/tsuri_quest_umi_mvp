#!/usr/bin/env python3
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tools" / "source_assets" / "underwater_battle_bg_source.png"
OUTPUT = ROOT / "assets" / "showcase" / "underwater" / "underwater_battle_bg.png"


def _rgba(hex_value: str, alpha: int = 255) -> tuple[int, int, int, int]:
    value = hex_value.lstrip("#")
    return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16), alpha)


def _draw_polyline(
    draw: ImageDraw.ImageDraw,
    points: list[tuple[float, float]],
    fill: tuple[int, int, int, int],
    width: int,
) -> None:
    if len(points) >= 2:
        draw.line(points, fill=fill, width=width, joint="curve")


def _draw_seaweed(
    draw: ImageDraw.ImageDraw,
    x: float,
    y: float,
    height: float,
    color: tuple[int, int, int, int],
    lean: float,
    width: int,
) -> None:
    points: list[tuple[float, float]] = []
    for step in range(8):
        t = step / 7.0
        points.append((x + math.sin(t * math.pi * 1.5) * 8.0 + lean * t, y - height * t))
    _draw_polyline(draw, points, color, width)
    for step in (2, 3, 4, 5, 6):
        px, py = points[step]
        side = -1 if step % 2 == 0 else 1
        draw.line(
            (px, py, px + side * height * 0.16, py - height * 0.11),
            fill=(color[0], color[1], color[2], max(24, color[3] - 14)),
            width=max(1, width - 1),
        )


def _apply_painterly_smoothing(image: Image.Image) -> Image.Image:
    try:
        import numpy as np
        from skimage.restoration import denoise_bilateral
    except Exception:
        softened = image.filter(ImageFilter.GaussianBlur(0.72))
        return Image.blend(image, softened, 0.24)

    source = image.convert("RGB")
    work_size = (max(1, source.width // 2), max(1, source.height // 2))
    work = source.resize(work_size, Image.Resampling.BILINEAR)
    arr = np.asarray(work).astype("float32") / 255.0
    smoothed = denoise_bilateral(
        arr,
        sigma_color=0.045,
        sigma_spatial=3.2,
        channel_axis=-1,
    )
    smooth_image = Image.fromarray(np.clip(smoothed * 255.0, 0, 255).astype("uint8"), "RGB")
    smooth_image = smooth_image.resize(source.size, Image.Resampling.BILINEAR)
    blended = Image.blend(source, smooth_image, 0.34)
    return blended.filter(ImageFilter.UnsharpMask(radius=1.2, percent=42, threshold=4))


def _add_depth_and_paint_glaze(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    # The source art is high detail but pixel-art crisp. A very low-opacity
    # blurred glaze makes it sit closer to the smoother reference background
    # without destroying the authored rocks and plants.
    softened = image.filter(ImageFilter.GaussianBlur(0.42))
    image = Image.blend(image, softened, 0.16)

    w, h = image.size
    grade = Image.new("RGBA", image.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(grade, "RGBA")

    # Enclose the stage like the reference: darker sides and seabed, bright
    # central water left open for the kurodai silhouette.
    gd.rectangle((0, 0, int(w * 0.13), h), fill=(0, 20, 36, 38))
    gd.rectangle((int(w * 0.87), 0, w, h), fill=(0, 20, 36, 36))
    gd.rectangle((0, int(h * 0.78), w, h), fill=(0, 28, 40, 22))
    gd.rectangle((0, 0, w, int(h * 0.08)), fill=(0, 23, 43, 20))
    image.alpha_composite(grade.filter(ImageFilter.GaussianBlur(34)))
    return image


def _add_far_depth(image: Image.Image) -> None:
    w, h = image.size
    layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer, "RGBA")

    # Soft far-rock masses, visible through the water but not competing with
    # the foreground fish. These fill the cleaner central distance.
    masses = [
        (w * 0.22, h * 0.50, w * 0.13, h * 0.22, "#063a5d", 16),
        (w * 0.35, h * 0.61, w * 0.17, h * 0.15, "#063451", 14),
        (w * 0.66, h * 0.58, w * 0.15, h * 0.17, "#062f4a", 14),
        (w * 0.78, h * 0.47, w * 0.14, h * 0.22, "#073a58", 15),
    ]
    for cx, cy, rx, ry, color, alpha in masses:
        d.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=_rgba(color, alpha))
        d.ellipse((cx - rx * 0.85, cy - ry * 0.72, cx + rx * 0.15, cy + ry * 0.12), fill=(72, 126, 130, max(4, alpha // 3)))

    # Thin distant fish schools and particulate haze, mostly above and behind
    # the main fish area.
    rng = random.Random(240626)
    for row, y in enumerate((h * 0.23, h * 0.31, h * 0.42)):
        for i in range(15 - row * 2):
            x = w * (0.27 + i * 0.035) + rng.uniform(-12, 16)
            yy = y + math.sin(i * 1.37 + row) * 14 + rng.uniform(-5, 5)
            bw = rng.uniform(4, 9) * (1.0 - row * 0.12)
            bh = bw * 0.30
            col = (2, 31, 54, 18 - row * 3)
            d.ellipse((x - bw, yy - bh, x + bw, yy + bh), fill=col)
            d.polygon(((x - bw * 0.88, yy), (x - bw * 1.35, yy - bh * 0.85), (x - bw * 1.35, yy + bh * 0.85)), fill=col)

    for _ in range(170):
        x = rng.uniform(w * 0.12, w * 0.88)
        y = rng.uniform(h * 0.10, h * 0.72)
        r = rng.choice((0.7, 1.0, 1.3, 1.6))
        a = rng.randint(12, 36)
        d.ellipse((x - r, y - r, x + r, y + r), fill=(210, 246, 255, a))

    image.alpha_composite(layer.filter(ImageFilter.GaussianBlur(1.15)))


def _add_seabed_and_edge_detail(image: Image.Image) -> None:
    w, h = image.size
    layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer, "RGBA")
    rng = random.Random(240627)

    # Hand-authored-looking contour lines and broken caustics on the sand. The
    # HUD covers the very bottom, so place these just above it.
    for i in range(82):
        x = rng.uniform(w * 0.06, w * 0.90)
        y = rng.uniform(h * 0.67, h * 0.89)
        length = rng.uniform(44, 180)
        amp = rng.uniform(3, 10)
        points: list[tuple[float, float]] = []
        for step in range(7):
            t = step / 6.0
            points.append((x + length * t, y + math.sin(t * math.tau + i * 0.45) * amp))
        col = (229, 252, 228, rng.randint(20, 52))
        _draw_polyline(d, points, col, rng.choice((1, 1, 2)))

    # Foreground-edge plant density. Keep the center and main fish silhouette
    # area relatively clean.
    clusters = [
        (w * 0.05, h * 0.92, 28, w * 0.13),
        (w * 0.18, h * 0.90, 18, w * 0.16),
        (w * 0.78, h * 0.90, 20, w * 0.14),
        (w * 0.92, h * 0.92, 28, w * 0.12),
    ]
    for cx, base_y, count, spread in clusters:
        for _ in range(count):
            x = cx + rng.uniform(-spread * 0.5, spread * 0.5)
            height = rng.uniform(36, 132)
            hue = rng.random()
            if hue < 0.68:
                color = (38, rng.randint(116, 178), rng.randint(84, 135), rng.randint(58, 112))
            elif hue < 0.88:
                color = (96, rng.randint(114, 154), 62, rng.randint(44, 84))
            else:
                color = (190, rng.randint(72, 106), rng.randint(90, 132), rng.randint(42, 76))
            _draw_seaweed(d, x, base_y + rng.uniform(-28, 24), height, color, rng.uniform(-24, 20), rng.choice((2, 2, 3)))

    # Small rocks and shell-like marks at the visible lower middle.
    for _ in range(52):
        x = rng.uniform(w * 0.10, w * 0.88)
        y = rng.uniform(h * 0.73, h * 0.92)
        rx = rng.uniform(5, 18)
        ry = rng.uniform(2, 8)
        d.ellipse((x - rx, y - ry, x + rx, y + ry), fill=(2, 34, 48, rng.randint(28, 58)))
        d.arc((x - rx, y - ry * 2.0, x + rx, y + ry * 1.4), 195, 340, fill=(167, 214, 181, rng.randint(20, 42)), width=1)

    image.alpha_composite(layer.filter(ImageFilter.GaussianBlur(0.28)))


def enhance() -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(f"Missing source background: {SOURCE}")
    image = Image.open(SOURCE)
    image = _apply_painterly_smoothing(image)
    image = _add_depth_and_paint_glaze(image)
    _add_far_depth(image)
    _add_seabed_and_edge_detail(image)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    image.convert("RGB").save(OUTPUT, optimize=True)
    print(f"enhanced {OUTPUT} from {SOURCE}")


if __name__ == "__main__":
    enhance()
