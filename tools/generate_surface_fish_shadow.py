#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "showcase" / "surface"
FRAME_W = 288
FRAME_H = 108
FRAME_COUNT = 3
SCALE = 4


def save_image(image: Image.Image, path: Path) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    image.save(path)
    print(path.relative_to(ROOT))


def s(value: float) -> int:
    return round(value * SCALE)


def p(point: tuple[float, float]) -> tuple[int, int]:
    return (s(point[0]), s(point[1]))


def box(rect: tuple[float, float, float, float]) -> tuple[int, int, int, int]:
    return tuple(s(value) for value in rect)  # type: ignore[return-value]


def draw_soft_shape(
    target: Image.Image,
    draw_fn,
    color: tuple[int, int, int],
    alpha: int,
    blur: float,
) -> None:
    layer = Image.new("RGBA", target.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer, "RGBA")
    draw_fn(draw, (*color, alpha))
    if blur > 0.0:
        layer = layer.filter(ImageFilter.GaussianBlur(s(blur)))
    target.alpha_composite(layer)


def fish_shape(draw: ImageDraw.ImageDraw, fill: tuple[int, int, int, int], tail_offset: float, body_shift: float = 0.0) -> None:
    cy = 54.0 + body_shift
    draw.ellipse(box((70, cy - 17, 222, cy + 17)), fill=fill)
    draw.ellipse(box((186, cy - 14, 244, cy + 14)), fill=fill)
    draw.polygon(
        [
            p((78, cy)),
            p((19, cy - 25 + tail_offset)),
            p((42, cy - 2 + tail_offset * 0.18)),
            p((19, cy + 25 + tail_offset)),
        ],
        fill=fill,
    )
    draw.polygon(
        [
            p((97, cy - 1)),
            p((45, cy - 13 - tail_offset * 0.24)),
            p((52, cy + 12 - tail_offset * 0.18)),
        ],
        fill=fill,
    )


def create_frame(tail_offset: float) -> Image.Image:
    image = Image.new("RGBA", (FRAME_W * SCALE, FRAME_H * SCALE), (0, 0, 0, 0))
    base = (164, 190, 199)
    core = (126, 158, 170)

    def broad(draw: ImageDraw.ImageDraw, fill: tuple[int, int, int, int]) -> None:
        fish_shape(draw, fill, tail_offset, 1.5)

    def main(draw: ImageDraw.ImageDraw, fill: tuple[int, int, int, int]) -> None:
        fish_shape(draw, fill, tail_offset)

    def inner(draw: ImageDraw.ImageDraw, fill: tuple[int, int, int, int]) -> None:
        draw.ellipse(box((92, 44, 214, 64)), fill=fill)
        draw.ellipse(box((184, 46, 232, 62)), fill=fill)

    draw_soft_shape(image, broad, base, 88, 7.4)
    draw_soft_shape(image, main, base, 138, 3.8)
    draw_soft_shape(image, inner, core, 74, 2.6)

    # Very faint water blur, not bubbles or fish details.
    haze = Image.new("RGBA", image.size, (0, 0, 0, 0))
    hdraw = ImageDraw.Draw(haze, "RGBA")
    for index, x in enumerate([76, 112, 151, 190]):
        hdraw.ellipse(box((x, 48 + (index % 2) * 2, x + 48, 59 + (index % 2) * 2)), fill=(210, 232, 236, 14))
    haze = haze.filter(ImageFilter.GaussianBlur(s(4.2)))
    image.alpha_composite(haze)
    return image.resize((FRAME_W, FRAME_H), Image.Resampling.LANCZOS)


def create_sheet() -> Image.Image:
    sheet = Image.new("RGBA", (FRAME_W * FRAME_COUNT, FRAME_H), (0, 0, 0, 0))
    for index, tail_offset in enumerate([-7.0, 0.0, 7.0]):
        sheet.alpha_composite(create_frame(tail_offset), (index * FRAME_W, 0))
    return sheet


def main() -> None:
    save_image(create_sheet(), OUT_DIR / "surface_fish_shadow_soft.png")


if __name__ == "__main__":
    main()
