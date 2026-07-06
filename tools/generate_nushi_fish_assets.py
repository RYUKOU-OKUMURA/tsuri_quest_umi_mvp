#!/usr/bin/env python3
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
FISH_DIR = ROOT / "assets" / "showcase" / "fish"
CONTACT_SHEET = ROOT / "tools" / "source_assets" / "fish" / "nushi_e2_contact_sheet.png"

FRAME_SIZE = 320

NUSHI_SPECS = [
    {
        "id": "nushi_harbor_pier",
        "base": "maanago",
        "label": "harbor",
        "tint": (104, 76, 44),
        "glow": (225, 179, 87),
        "scale": 1.10,
        "mark": "spots",
    },
    {
        "id": "nushi_shallow_sand",
        "base": "hirame",
        "label": "sand",
        "tint": (139, 103, 63),
        "glow": (228, 190, 112),
        "scale": 1.08,
        "mark": "mottle",
    },
    {
        "id": "nushi_rock_breakwater",
        "base": "ishidai",
        "label": "rock",
        "tint": (58, 55, 47),
        "glow": (230, 188, 92),
        "scale": 1.08,
        "mark": "bars",
    },
    {
        "id": "nushi_outer_tide",
        "base": "suzuki",
        "label": "tide",
        "tint": (73, 104, 127),
        "glow": (185, 221, 230),
        "scale": 1.10,
        "mark": "lateral",
    },
    {
        "id": "nushi_south_reef",
        "base": "kue",
        "label": "reef",
        "tint": (105, 74, 49),
        "glow": (226, 166, 88),
        "scale": 1.12,
        "mark": "scars",
    },
    {
        "id": "nushi_bluewater_route",
        "base": "buri",
        "label": "bluewater",
        "tint": (52, 97, 126),
        "glow": (227, 191, 72),
        "scale": 1.12,
        "mark": "lateral",
    },
    {
        "id": "nushi_deep_ocean",
        "base": "ara",
        "label": "deep",
        "tint": (76, 61, 91),
        "glow": (160, 129, 219),
        "scale": 1.10,
        "mark": "spots",
    },
]


def main() -> None:
    previews: list[Image.Image] = []
    for spec in NUSHI_SPECS:
        card = _make_variant(_load_rgba(FISH_DIR / f"{spec['base']}_card_portrait.png"), spec, scale_bias=1.0)
        sheet = _make_sheet_variant(_load_rgba(FISH_DIR / f"{spec['base']}_showcase_sheet.png"), spec)
        card.save(FISH_DIR / f"{spec['id']}_card_portrait.png")
        sheet.save(FISH_DIR / f"{spec['id']}_showcase_sheet.png")
        previews.append(_preview_tile(spec, card))
    CONTACT_SHEET.parent.mkdir(parents=True, exist_ok=True)
    _build_contact_sheet(previews).save(CONTACT_SHEET)
    print(f"generated {len(NUSHI_SPECS)} nushi fish asset pairs")
    print(CONTACT_SHEET)


def _load_rgba(path: Path) -> Image.Image:
    if not path.exists():
        raise FileNotFoundError(path)
    return Image.open(path).convert("RGBA")


def _make_sheet_variant(source: Image.Image, spec: dict, scale_bias: float = 0.96) -> Image.Image:
    frame_count = source.width // FRAME_SIZE
    out = Image.new("RGBA", source.size, (0, 0, 0, 0))
    for index in range(frame_count):
        frame = source.crop((index * FRAME_SIZE, 0, (index + 1) * FRAME_SIZE, source.height))
        variant = _make_variant(frame, spec, scale_bias=scale_bias)
        out.alpha_composite(variant, (index * FRAME_SIZE, 0))
    return out


def _make_variant(source: Image.Image, spec: dict, scale_bias: float) -> Image.Image:
    fish = _fit_scaled(_trim_alpha(source), source.size, float(spec["scale"]) * scale_bias)
    fish = _grade_fish(fish, spec)
    alpha = fish.getchannel("A")

    out = Image.new("RGBA", source.size, (0, 0, 0, 0))
    shadow = Image.new("RGBA", source.size, (0, 0, 0, 0))
    shadow_alpha = alpha.filter(ImageFilter.GaussianBlur(max(3, source.width // 38)))
    shadow.putalpha(shadow_alpha.point(lambda a: int(a * 0.42)))
    shadow_rgb = Image.new("RGBA", source.size, (*spec["glow"], 0))
    shadow_rgb.putalpha(shadow.getchannel("A"))
    out.alpha_composite(shadow_rgb)

    edge = alpha.filter(ImageFilter.GaussianBlur(max(1, source.width // 120)))
    edge_rgb = Image.new("RGBA", source.size, (*spec["glow"], 0))
    edge_rgb.putalpha(edge.point(lambda a: int(a * 0.18)))
    out.alpha_composite(edge_rgb)
    out.alpha_composite(fish)
    _draw_marks(out, alpha, spec)
    return out


def _trim_alpha(image: Image.Image) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        return image
    pad_x = max(8, image.width // 30)
    pad_y = max(8, image.height // 30)
    bbox = (
        max(0, bbox[0] - pad_x),
        max(0, bbox[1] - pad_y),
        min(image.width, bbox[2] + pad_x),
        min(image.height, bbox[3] + pad_y),
    )
    return image.crop(bbox)


def _fit_scaled(image: Image.Image, canvas_size: tuple[int, int], scale: float) -> Image.Image:
    max_w = int(canvas_size[0] * 0.94)
    max_h = int(canvas_size[1] * 0.84)
    base_ratio = min(max_w / image.width, max_h / image.height)
    ratio = min(base_ratio * scale, max_w / image.width, max_h / image.height)
    new_size = (max(1, int(image.width * ratio)), max(1, int(image.height * ratio)))
    resized = image.resize(new_size, Image.Resampling.LANCZOS)
    out = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    out.alpha_composite(resized, ((canvas_size[0] - new_size[0]) // 2, (canvas_size[1] - new_size[1]) // 2))
    return out


def _grade_fish(image: Image.Image, spec: dict) -> Image.Image:
    rgb = image.convert("RGB")
    tint = Image.new("RGB", image.size, spec["tint"])
    graded = Image.blend(rgb, tint, 0.24)
    graded = ImageEnhance.Color(graded).enhance(1.16)
    graded = ImageEnhance.Contrast(graded).enhance(1.12)
    result = graded.convert("RGBA")
    result.putalpha(image.getchannel("A"))
    return result


def _draw_marks(image: Image.Image, alpha: Image.Image, spec: dict) -> None:
    bbox = alpha.getbbox()
    if bbox is None:
        return
    mask = alpha.point(lambda a: min(185, int(a * 0.62)))
    marks = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(marks)
    x0, y0, x1, y1 = bbox
    w = x1 - x0
    h = y1 - y0
    glow = tuple(spec["glow"])
    dark = (34, 28, 24)
    mark = str(spec["mark"])
    if mark == "bars":
        for i in range(5):
            x = x0 + int(w * (0.22 + i * 0.12))
            draw.line((x, y0 + h * 0.18, x - w * 0.05, y1 - h * 0.16), fill=(*dark, 92), width=max(3, w // 45))
    elif mark == "lateral":
        y = y0 + int(h * 0.48)
        draw.line((x0 + w * 0.14, y, x1 - w * 0.12, y - h * 0.05), fill=(*glow, 118), width=max(2, h // 18))
        draw.line((x0 + w * 0.16, y + h * 0.06, x1 - w * 0.16, y + h * 0.02), fill=(*dark, 70), width=max(1, h // 28))
    elif mark == "scars":
        for i in range(4):
            x = x0 + int(w * (0.24 + i * 0.13))
            y = y0 + int(h * (0.34 + (i % 2) * 0.17))
            draw.line((x, y, x + w * 0.10, y - h * 0.08), fill=(*glow, 118), width=max(2, h // 22))
            draw.line((x + 2, y + 2, x + w * 0.10 + 2, y - h * 0.08 + 2), fill=(*dark, 70), width=max(1, h // 35))
    elif mark == "mottle":
        for i in range(26):
            px = x0 + int(w * ((i * 37 % 100) / 100.0))
            py = y0 + int(h * ((i * 53 % 100) / 100.0))
            r = max(2, min(w, h) // (18 + i % 5))
            draw.ellipse((px - r, py - r, px + r, py + r), fill=(*dark, 52 + (i % 3) * 18))
    else:
        for i in range(18):
            px = x0 + int(w * (0.18 + (i * 19 % 68) / 100.0))
            py = y0 + int(h * (0.24 + (i * 31 % 54) / 100.0))
            r = max(2, min(w, h) // (20 + i % 6))
            draw.ellipse((px - r, py - r, px + r, py + r), fill=(*glow, 74))

    clipped = Image.composite(marks, Image.new("RGBA", image.size, (0, 0, 0, 0)), mask)
    image.alpha_composite(clipped)


def _preview_tile(spec: dict, card: Image.Image) -> Image.Image:
    tile = Image.new("RGBA", (620, 360), (28, 34, 42, 255))
    tile.alpha_composite(card, (30, 22))
    draw = ImageDraw.Draw(tile)
    draw.rectangle((20, 20, 600, 340), outline=(*spec["glow"], 190), width=3)
    draw.text((34, 315), f"{spec['id']}  base={spec['base']}", fill=(238, 231, 205, 255))
    return tile


def _build_contact_sheet(previews: list[Image.Image]) -> Image.Image:
    cols = 2
    rows = math.ceil(len(previews) / cols)
    sheet = Image.new("RGBA", (cols * 620, rows * 360), (18, 22, 28, 255))
    for index, tile in enumerate(previews):
        sheet.alpha_composite(tile, ((index % cols) * 620, (index // cols) * 360))
    return sheet


if __name__ == "__main__":
    main()
