#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "showcase" / "underwater" / "weather_status_icon_sheet.png"
CELL = 128
SCALE = 4


def _rgba(hex_value: str, alpha: int = 255) -> tuple[int, int, int, int]:
    value = hex_value.lstrip("#")
    return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16), alpha)


def _scaled_canvas() -> tuple[Image.Image, ImageDraw.ImageDraw]:
    size = CELL * SCALE
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    return image, ImageDraw.Draw(image)


def _downsample(image: Image.Image) -> Image.Image:
    image = image.filter(ImageFilter.GaussianBlur(0.15 * SCALE))
    return image.resize((CELL, CELL), Image.Resampling.LANCZOS)


def _s(value: float) -> float:
    return value * SCALE


def _ellipse(
    draw: ImageDraw.ImageDraw,
    box: tuple[float, float, float, float],
    fill: str,
    *,
    alpha: int = 255,
    outline: str | None = None,
    outline_alpha: int = 255,
    width: int = 1,
) -> None:
    scaled = tuple(_s(v) for v in box)
    draw.ellipse(
        scaled,
        fill=_rgba(fill, alpha),
        outline=_rgba(outline, outline_alpha) if outline else None,
        width=max(1, width * SCALE),
    )


def _line(
    draw: ImageDraw.ImageDraw,
    points: tuple[float, float, float, float],
    fill: str,
    *,
    alpha: int = 255,
    width: int = 1,
) -> None:
    draw.line(tuple(_s(v) for v in points), fill=_rgba(fill, alpha), width=max(1, width * SCALE))


def _sun_layer(draw: ImageDraw.ImageDraw, cx: float, cy: float, radius: float, *, alpha: int = 255) -> None:
    for angle in range(0, 360, 45):
        import math

        rad = math.radians(angle)
        x0 = cx + math.cos(rad) * (radius + 7.0)
        y0 = cy + math.sin(rad) * (radius + 7.0)
        x1 = cx + math.cos(rad) * (radius + 19.0)
        y1 = cy + math.sin(rad) * (radius + 19.0)
        _line(draw, (x0, y0, x1, y1), "#2f2418", alpha=min(225, alpha), width=5)
        _line(draw, (x0, y0, x1, y1), "#f0a51b", alpha=alpha, width=3)
    _ellipse(draw, (cx - radius - 3, cy - radius - 3, cx + radius + 3, cy + radius + 3), "#2d2116", alpha=min(220, alpha))
    _ellipse(draw, (cx - radius, cy - radius, cx + radius, cy + radius), "#ff9b17", alpha=alpha)
    _ellipse(draw, (cx - radius + 7, cy - radius + 5, cx + radius - 7, cy + radius - 9), "#ffd047", alpha=int(alpha * 0.92))
    _ellipse(draw, (cx - radius + 14, cy - radius + 11, cx - radius + 23, cy - radius + 20), "#fff0a5", alpha=int(alpha * 0.72))


def _cloud_layer(
    draw: ImageDraw.ImageDraw,
    *,
    x: float,
    y: float,
    color: str,
    outline: str,
    alpha: int = 255,
    scale: float = 1.0,
) -> None:
    parts = [
        (x + 14 * scale, y + 35 * scale, 16 * scale),
        (x + 32 * scale, y + 25 * scale, 21 * scale),
        (x + 55 * scale, y + 21 * scale, 24 * scale),
        (x + 78 * scale, y + 33 * scale, 19 * scale),
    ]
    for cx, cy, r in parts:
        _ellipse(draw, (cx - r - 4, cy - r - 4, cx + r + 4, cy + r + 4), outline, alpha=int(alpha * 0.82))
    body = (x + 4 * scale, y + 35 * scale, x + 93 * scale, y + 67 * scale)
    draw.rounded_rectangle(
        tuple(_s(v) for v in body),
        radius=int(_s(17 * scale)),
        fill=_rgba(outline, int(alpha * 0.82)),
    )
    for cx, cy, r in parts:
        _ellipse(draw, (cx - r, cy - r, cx + r, cy + r), color, alpha=alpha)
    draw.rounded_rectangle(
        tuple(_s(v) for v in (x + 8 * scale, y + 36 * scale, x + 90 * scale, y + 63 * scale)),
        radius=int(_s(14 * scale)),
        fill=_rgba(color, alpha),
    )
    _line(draw, (x + 19 * scale, y + 61 * scale, x + 83 * scale, y + 61 * scale), "#f4f0db", alpha=int(alpha * 0.34), width=2)


def _draw_sunny() -> Image.Image:
    image, draw = _scaled_canvas()
    _sun_layer(draw, 64, 64, 27)
    return _downsample(image)


def _draw_partly_cloudy() -> Image.Image:
    image, draw = _scaled_canvas()
    _sun_layer(draw, 46, 43, 22, alpha=242)
    _cloud_layer(draw, x=25, y=36, color="#f2ede1", outline="#2c2924", alpha=246, scale=0.78)
    _cloud_layer(draw, x=43, y=45, color="#d8e3e6", outline="#2c2924", alpha=224, scale=0.58)
    return _downsample(image)


def _draw_cloudy() -> Image.Image:
    image, draw = _scaled_canvas()
    _cloud_layer(draw, x=18, y=31, color="#c7d2d7", outline="#2b2e31", alpha=244, scale=0.90)
    _cloud_layer(draw, x=42, y=45, color="#edf1eb", outline="#2b2e31", alpha=230, scale=0.62)
    _line(draw, (34, 86, 97, 86), "#4e5b60", alpha=120, width=3)
    return _downsample(image)


def _draw_rain() -> Image.Image:
    image, draw = _scaled_canvas()
    _cloud_layer(draw, x=18, y=25, color="#687883", outline="#252a30", alpha=246, scale=0.92)
    for x, y in ((34, 78), (52, 86), (71, 77), (88, 84)):
        _line(draw, (x + 7, y, x - 2, y + 20), "#f3f9ff", alpha=205, width=4)
        _line(draw, (x + 7, y, x - 2, y + 20), "#77bfe0", alpha=190, width=2)
    return _downsample(image)


def _draw_fog() -> Image.Image:
    image, draw = _scaled_canvas()
    _cloud_layer(draw, x=22, y=25, color="#d9e2df", outline="#596567", alpha=178, scale=0.82)
    for y, x0, x1, alpha in (
        (65, 26, 104, 205),
        (78, 16, 91, 226),
        (91, 31, 112, 188),
        (103, 23, 80, 145),
    ):
        _line(draw, (x0, y, x1, y), "#eef4ee", alpha=alpha, width=5)
        _line(draw, (x0, y + 2, x1, y + 2), "#6f7d7c", alpha=int(alpha * 0.34), width=1)
    return _downsample(image)


def main() -> None:
    icons = [_draw_sunny(), _draw_partly_cloudy(), _draw_cloudy(), _draw_rain(), _draw_fog()]
    sheet = Image.new("RGBA", (CELL * len(icons), CELL), (0, 0, 0, 0))
    for index, icon in enumerate(icons):
        sheet.alpha_composite(icon, (CELL * index, 0))
    OUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT)
    print(OUT)


if __name__ == "__main__":
    main()
