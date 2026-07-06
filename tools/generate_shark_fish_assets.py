#!/usr/bin/env python3
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
FISH_DIR = ROOT / "assets" / "showcase" / "fish"
CONTACT_SHEET = ROOT / "tools" / "source_assets" / "fish" / "shark_e4_contact_sheet.png"
REALISTIC_SOURCE_DIR = ROOT / "tools" / "source_assets" / "fish" / "shark_e4_realistic_sources"
FONT_BOLD = ROOT / "assets" / "fonts" / "line_seed" / "LINESeedJP_A_TTF_Bd.ttf"

CARD_SIZE = (560, 310)
FRAME_SIZE = (640, 320)
SHEET_FRAMES = 4


SHARK_SPECS = [
    {
        "id": "nekozame",
        "label": "ネコザメ",
        "body": (122, 95, 66),
        "belly": (202, 175, 133),
        "accent": (72, 53, 39),
        "pattern": "saddle",
        "body_len": 0.72,
        "body_h": 0.23,
        "tail": 0.15,
        "dorsal": 0.18,
        "nose": "blunt",
        "scale": 0.86,
    },
    {
        "id": "inuzame",
        "label": "イヌザメ",
        "body": (103, 111, 96),
        "belly": (191, 193, 170),
        "accent": (48, 56, 47),
        "pattern": "fine_spots",
        "body_len": 0.76,
        "body_h": 0.20,
        "tail": 0.16,
        "dorsal": 0.16,
        "nose": "slender",
        "scale": 0.84,
    },
    {
        "id": "dochizame",
        "label": "ドチザメ",
        "body": (92, 113, 119),
        "belly": (196, 207, 200),
        "accent": (44, 69, 76),
        "pattern": "lateral",
        "body_len": 0.79,
        "body_h": 0.21,
        "tail": 0.17,
        "dorsal": 0.18,
        "nose": "slender",
        "scale": 0.90,
    },
    {
        "id": "hoshizame",
        "label": "ホシザメ",
        "body": (83, 107, 124),
        "belly": (200, 213, 215),
        "accent": (222, 229, 215),
        "pattern": "star_spots",
        "body_len": 0.78,
        "body_h": 0.22,
        "tail": 0.17,
        "dorsal": 0.18,
        "nose": "slender",
        "scale": 0.90,
    },
    {
        "id": "eporetto",
        "label": "エポレットシャーク",
        "body": (119, 86, 58),
        "belly": (206, 174, 126),
        "accent": (43, 31, 26),
        "pattern": "epaulette",
        "body_len": 0.73,
        "body_h": 0.20,
        "tail": 0.15,
        "dorsal": 0.15,
        "nose": "blunt",
        "scale": 0.78,
    },
    {
        "id": "darumazame",
        "label": "ダルマザメ",
        "body": (84, 78, 92),
        "belly": (180, 169, 184),
        "accent": (47, 38, 56),
        "pattern": "collar",
        "body_len": 0.58,
        "body_h": 0.24,
        "tail": 0.12,
        "dorsal": 0.13,
        "nose": "round",
        "scale": 0.64,
    },
    {
        "id": "fujikujira",
        "label": "フジクジラ",
        "body": (63, 69, 91),
        "belly": (166, 171, 190),
        "accent": (136, 122, 172),
        "pattern": "deep_glow",
        "body_len": 0.60,
        "body_h": 0.22,
        "tail": 0.13,
        "dorsal": 0.14,
        "nose": "round",
        "scale": 0.60,
    },
    {
        "id": "shumokuzame",
        "label": "シュモクザメ",
        "body": (80, 111, 127),
        "belly": (194, 211, 213),
        "accent": (38, 70, 83),
        "pattern": "lateral",
        "body_len": 0.86,
        "body_h": 0.22,
        "tail": 0.20,
        "dorsal": 0.22,
        "nose": "hammer",
        "scale": 0.98,
    },
    {
        "id": "hohojirozame",
        "label": "ホオジロザメ",
        "body": (71, 91, 103),
        "belly": (226, 230, 224),
        "accent": (33, 52, 61),
        "pattern": "countershade",
        "body_len": 0.88,
        "body_h": 0.27,
        "tail": 0.21,
        "dorsal": 0.24,
        "nose": "pointed",
        "scale": 1.00,
    },
    {
        "id": "nushi_danger_reef",
        "label": "深海の白帝",
        "body": (226, 229, 224),
        "belly": (248, 248, 238),
        "accent": (119, 138, 153),
        "pattern": "nushi_scars",
        "body_len": 0.90,
        "body_h": 0.29,
        "tail": 0.22,
        "dorsal": 0.26,
        "nose": "pointed",
        "scale": 1.04,
        "glow": (184, 223, 240),
    },
]


def main() -> None:
    missing_sources = _missing_realistic_sources()
    if missing_sources:
        formatted = "\n".join(f"- {path}" for path in missing_sources)
        raise FileNotFoundError(f"Missing required realistic shark source PNGs:\n{formatted}")

    FISH_DIR.mkdir(parents=True, exist_ok=True)
    previews: list[Image.Image] = []
    for spec in SHARK_SPECS:
        source = _load_realistic_source(spec)
        card = _make_card_from_source(source)
        sheet = _make_sheet_from_source(source)
        card.save(FISH_DIR / f"{spec['id']}_card_portrait.png")
        sheet.save(FISH_DIR / f"{spec['id']}_showcase_sheet.png")
        previews.append(_preview_tile(spec, card))
    CONTACT_SHEET.parent.mkdir(parents=True, exist_ok=True)
    _build_contact_sheet(previews).save(CONTACT_SHEET)
    print(f"generated {len(SHARK_SPECS)} shark fish asset pairs")
    print(CONTACT_SHEET)


def _make_card(spec: dict) -> Image.Image:
    work_size = (round(CARD_SIZE[0] * 1.35), round(CARD_SIZE[1] * 1.35))
    fish = _draw_shark(spec, work_size, phase=0.35, scale=float(spec["scale"]) * 1.04)
    return _contain_alpha(_readability_pass(fish), CARD_SIZE, margin=18)


def _make_sheet(spec: dict) -> Image.Image:
    frame_w, frame_h = FRAME_SIZE
    sheet = Image.new("RGBA", (frame_w * SHEET_FRAMES, frame_h), (0, 0, 0, 0))
    work_size = (round(frame_w * 1.20), round(frame_h * 1.35))
    for index in range(SHEET_FRAMES):
        phase = index / float(SHEET_FRAMES)
        frame = _draw_shark(spec, work_size, phase=phase, scale=float(spec["scale"]))
        frame = frame.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        frame = _contain_alpha(_readability_pass(frame), FRAME_SIZE, margin=10)
        sheet.alpha_composite(frame, (index * frame_w, 0))
    return sheet


def _missing_realistic_sources() -> list[Path]:
    return [path for spec in SHARK_SPECS if not (path := _realistic_source_path(spec)).exists()]


def _realistic_source_path(spec: dict) -> Path:
    return REALISTIC_SOURCE_DIR / f"{spec['id']}_source.png"


def _load_realistic_source(spec: dict) -> Image.Image:
    path = _realistic_source_path(spec)
    if not path.exists():
        raise FileNotFoundError(path)
    source = Image.open(path).convert("RGBA")
    return _trim_alpha(_remove_chroma_green(source))


def _make_card_from_source(source: Image.Image) -> Image.Image:
    return _add_card_shadow(_contain_alpha(_realistic_readability_pass(source), CARD_SIZE, margin=10))


def _make_sheet_from_source(source: Image.Image) -> Image.Image:
    frame_w, frame_h = FRAME_SIZE
    sheet = Image.new("RGBA", (frame_w * SHEET_FRAMES, frame_h), (0, 0, 0, 0))
    for index in range(SHEET_FRAMES):
        phase = math.sin(index / float(SHEET_FRAMES) * math.tau)
        scale = 1.0 + phase * 0.012
        frame_source = source
        if abs(scale - 1.0) > 0.001:
            frame_source = source.resize(
                (
                    max(1, round(source.width * scale)),
                    max(1, round(source.height * (1.0 - phase * 0.006))),
                ),
                Image.Resampling.LANCZOS,
            )
        frame_source = frame_source.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        frame = _contain_alpha(_realistic_readability_pass(frame_source), FRAME_SIZE, margin=9)
        y_offset = round(phase * 2.0)
        sheet.alpha_composite(frame, (index * frame_w, y_offset))
    return sheet


def _remove_chroma_green(image: Image.Image) -> Image.Image:
    """Remove the flat green ImageGen background while preserving antialiased edges."""
    img = image.convert("RGBA")
    pixels = img.load()
    width, height = img.size
    border_samples = []
    for x in range(0, width, max(1, width // 80)):
        border_samples.append(pixels[x, 0])
        border_samples.append(pixels[x, height - 1])
    for y in range(0, height, max(1, height // 80)):
        border_samples.append(pixels[0, y])
        border_samples.append(pixels[width - 1, y])
    key_r = round(sum(p[0] for p in border_samples) / len(border_samples))
    key_g = round(sum(p[1] for p in border_samples) / len(border_samples))
    key_b = round(sum(p[2] for p in border_samples) / len(border_samples))

    transparent_threshold = 42.0
    opaque_threshold = 132.0
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            distance = math.sqrt((r - key_r) ** 2 + (g - key_g) ** 2 + (b - key_b) ** 2)
            if distance <= transparent_threshold:
                pixels[x, y] = (r, g, b, 0)
            elif distance < opaque_threshold:
                edge_alpha = int(a * ((distance - transparent_threshold) / (opaque_threshold - transparent_threshold)))
                pixels[x, y] = (*_despill_green(r, g, b), edge_alpha)
            elif g > max(r, b) + 20 and g > 80:
                pixels[x, y] = (*_despill_green(r, g, b), a)
    return img


def _despill_green(r: int, g: int, b: int) -> tuple[int, int, int]:
    if g <= max(r, b) + 8:
        return (r, g, b)
    softened_g = min(g, max(r, b, round((r + b) * 0.54)))
    return (r, softened_g, b)


def _trim_alpha(image: Image.Image) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        return image
    return image.crop(bbox)


def _realistic_readability_pass(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    rgb = image.convert("RGB")
    rgb = ImageEnhance.Color(rgb).enhance(1.03)
    rgb = ImageEnhance.Contrast(rgb).enhance(1.08)
    rgb = ImageEnhance.Sharpness(rgb).enhance(1.08)
    out = rgb.convert("RGBA")
    out.putalpha(alpha)
    return out


def _add_card_shadow(image: Image.Image) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        return image
    x0, _y0, x1, y1 = bbox
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(shadow)
    pad_x = max(8, round((x1 - x0) * 0.10))
    ellipse = (
        x0 + pad_x,
        min(image.height - 34, y1 - 18),
        x1 - pad_x,
        min(image.height - 4, y1 + 28),
    )
    draw.ellipse(ellipse, fill=(74, 45, 22, 105))
    shadow = shadow.filter(ImageFilter.GaussianBlur(13))
    out = Image.new("RGBA", image.size, (0, 0, 0, 0))
    out.alpha_composite(shadow)
    out.alpha_composite(image)
    return out


def _draw_shark(spec: dict, size: tuple[int, int], phase: float, scale: float) -> Image.Image:
    w, h = size
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    body_len = w * float(spec["body_len"]) * scale
    body_h = h * float(spec["body_h"]) * scale
    tail_len = w * float(spec["tail"]) * scale
    dorsal_h = h * float(spec["dorsal"]) * scale
    cx = w * 0.50 - tail_len * 0.42
    cy = h * (0.53 + 0.018 * math.sin(phase * math.tau))
    bend = w * 0.018 * math.sin(phase * math.tau)

    draw = ImageDraw.Draw(layer)
    x0 = cx - body_len * 0.50
    x1 = cx + body_len * 0.50
    y0 = cy - body_h * 0.50
    y1 = cy + body_h * 0.50

    body_color = tuple(spec["body"])
    belly_color = tuple(spec["belly"])
    accent = tuple(spec["accent"])

    body = [
        (x0 + body_len * 0.05, cy - body_h * 0.10),
        (x0 + body_len * 0.15, y0 + body_h * 0.08),
        (x0 + body_len * 0.46, y0 - body_h * 0.08),
        (x1 - body_len * 0.14, y0 + body_h * 0.12 + bend * 0.20),
        (x1, cy + bend * 0.35),
        (x1 - body_len * 0.12, y1 - body_h * 0.10 + bend * 0.20),
        (x0 + body_len * 0.38, y1 + body_h * 0.02),
        (x0 + body_len * 0.10, y1 - body_h * 0.10),
    ]
    if str(spec["nose"]) == "round":
        body[0] = (x0 + body_len * 0.02, cy)
    elif str(spec["nose"]) == "blunt":
        body[0] = (x0 + body_len * 0.00, cy - body_h * 0.02)

    tail_base_x = x1 - body_len * 0.04
    tail = [
        (tail_base_x, cy - body_h * 0.12 + bend),
        (tail_base_x + tail_len, cy - body_h * 0.62 + bend * 0.40),
        (tail_base_x + tail_len * 0.62, cy + bend * 0.20),
        (tail_base_x + tail_len, cy + body_h * 0.62 + bend * 0.40),
        (tail_base_x, cy + body_h * 0.12 + bend),
    ]
    draw.polygon(tail, fill=(*body_color, 245), outline=(*accent, 235))
    draw.polygon(body, fill=(*body_color, 255), outline=(*accent, 235))

    belly = [
        (x0 + body_len * 0.12, cy + body_h * 0.10),
        (x0 + body_len * 0.42, cy + body_h * 0.27),
        (x1 - body_len * 0.18, cy + body_h * 0.16 + bend * 0.15),
        (x1 - body_len * 0.08, cy + body_h * 0.04 + bend * 0.15),
        (x0 + body_len * 0.22, cy + body_h * 0.00),
    ]
    draw.polygon(belly, fill=(*belly_color, 205))

    dorsal = [
        (cx - body_len * 0.08, y0 + body_h * 0.06),
        (cx + body_len * 0.02, y0 - dorsal_h * 0.55),
        (cx + body_len * 0.12, y0 + body_h * 0.08),
    ]
    pectoral = [
        (cx - body_len * 0.07, cy + body_h * 0.20),
        (cx + body_len * 0.08, cy + body_h * 0.76),
        (cx + body_len * 0.14, cy + body_h * 0.18),
    ]
    draw.polygon(dorsal, fill=(*accent, 230))
    draw.polygon(pectoral, fill=(*accent, 210))

    if str(spec["nose"]) == "hammer":
        head_x = x0 + body_len * 0.02
        head_w = body_len * 0.18
        head_h = body_h * 0.30
        draw.rounded_rectangle(
            (head_x - head_w * 0.50, cy - head_h, head_x + head_w * 0.60, cy + head_h),
            radius=max(2, round(head_h * 0.55)),
            fill=(*body_color, 255),
            outline=(*accent, 230),
            width=max(1, round(w / 160)),
        )
        eye_points = [(head_x - head_w * 0.38, cy - head_h * 0.42), (head_x + head_w * 0.46, cy - head_h * 0.38)]
    else:
        eye_points = [(x0 + body_len * 0.12, cy - body_h * 0.20)]

    _draw_pattern(draw, spec, (x0, y0, x1, y1), cy, body_h, body_len)
    for ex, ey in eye_points:
        r = max(2, round(h * 0.010))
        draw.ellipse((ex - r, ey - r, ex + r, ey + r), fill=(8, 14, 18, 245))
        draw.ellipse((ex - r * 0.35, ey - r * 0.45, ex + r * 0.05, ey - r * 0.05), fill=(230, 246, 255, 220))

    glow_color = tuple(spec.get("glow", (108, 168, 188)))
    alpha = layer.getchannel("A")
    glow = Image.new("RGBA", size, (*glow_color, 0))
    glow.putalpha(alpha.filter(ImageFilter.GaussianBlur(max(2, round(w / 70)))).point(lambda a: round(a * 0.18)))
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    out.alpha_composite(glow)
    out.alpha_composite(layer)
    return out


def _draw_pattern(
    draw: ImageDraw.ImageDraw,
    spec: dict,
    box: tuple[float, float, float, float],
    cy: float,
    body_h: float,
    body_len: float,
) -> None:
    x0, y0, x1, y1 = box
    accent = tuple(spec["accent"])
    pattern = str(spec["pattern"])
    if pattern == "saddle":
        for index in range(4):
            x = x0 + body_len * (0.24 + index * 0.13)
            draw.arc((x, y0 + body_h * 0.10, x + body_len * 0.13, y1 - body_h * 0.05), 95, 250, fill=(*accent, 105), width=max(2, round(body_h * 0.05)))
    elif pattern == "fine_spots":
        for index in range(22):
            x = x0 + body_len * (0.16 + ((index * 19) % 70) / 100.0)
            y = y0 + body_h * (0.22 + ((index * 31) % 48) / 100.0)
            r = max(1.5, body_h * (0.018 + (index % 3) * 0.005))
            draw.ellipse((x - r, y - r, x + r, y + r), fill=(*accent, 80))
    elif pattern == "star_spots":
        for index in range(16):
            x = x0 + body_len * (0.18 + ((index * 23) % 66) / 100.0)
            y = y0 + body_h * (0.20 + ((index * 37) % 42) / 100.0)
            r = max(2.0, body_h * 0.030)
            draw.ellipse((x - r, y - r, x + r, y + r), fill=(*tuple(spec["accent"]), 132))
    elif pattern == "epaulette":
        for side in (0.28, 0.64):
            x = x0 + body_len * side
            y = cy - body_h * 0.10
            r = body_h * 0.18
            draw.ellipse((x - r, y - r, x + r, y + r), outline=(*accent, 158), width=max(2, round(body_h * 0.04)))
            draw.ellipse((x - r * 0.45, y - r * 0.45, x + r * 0.45, y + r * 0.45), fill=(*accent, 72))
    elif pattern == "collar":
        x = x0 + body_len * 0.23
        draw.line((x, y0 + body_h * 0.14, x + body_len * 0.05, y1 - body_h * 0.10), fill=(*accent, 120), width=max(2, round(body_h * 0.08)))
    elif pattern == "deep_glow":
        glow = tuple(spec["accent"])
        draw.line((x0 + body_len * 0.22, cy - body_h * 0.02, x1 - body_len * 0.12, cy - body_h * 0.08), fill=(*glow, 145), width=max(2, round(body_h * 0.05)))
        for index in range(7):
            x = x0 + body_len * (0.28 + index * 0.075)
            draw.ellipse((x - 2, cy - body_h * 0.22, x + 2, cy - body_h * 0.22 + 4), fill=(*glow, 150))
    elif pattern == "countershade":
        draw.line((x0 + body_len * 0.16, cy + body_h * 0.03, x1 - body_len * 0.12, cy + body_h * 0.00), fill=(*accent, 96), width=max(2, round(body_h * 0.045)))
    elif pattern == "nushi_scars":
        for index in range(5):
            x = x0 + body_len * (0.25 + index * 0.11)
            y = cy - body_h * (0.18 if index % 2 == 0 else 0.02)
            draw.line((x, y, x + body_len * 0.07, y - body_h * 0.16), fill=(178, 218, 232, 145), width=max(2, round(body_h * 0.035)))
    else:
        draw.line((x0 + body_len * 0.18, cy, x1 - body_len * 0.12, cy - body_h * 0.04), fill=(*accent, 95), width=max(2, round(body_h * 0.04)))


def _readability_pass(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    shadow.putalpha(alpha.filter(ImageFilter.GaussianBlur(max(2, image.width // 90))).point(lambda a: round(a * 0.28)))
    out = Image.new("RGBA", image.size, (0, 0, 0, 0))
    out.alpha_composite(shadow, (0, max(1, image.height // 85)))
    rgb = ImageEnhance.Contrast(image.convert("RGB")).enhance(1.05).convert("RGBA")
    rgb.putalpha(alpha)
    out.alpha_composite(rgb)
    return out


def _contain_alpha(image: Image.Image, size: tuple[int, int], margin: int) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        return image
    cropped = image.crop(bbox)
    max_w = max(1, size[0] - margin * 2)
    max_h = max(1, size[1] - margin * 2)
    scale = min(max_w / cropped.width, max_h / cropped.height, 1.0)
    if scale < 1.0:
        cropped = cropped.resize(
            (max(1, round(cropped.width * scale)), max(1, round(cropped.height * scale))),
            Image.Resampling.LANCZOS,
        )
    out = Image.new("RGBA", size, (0, 0, 0, 0))
    out.alpha_composite(cropped, ((size[0] - cropped.width) // 2, (size[1] - cropped.height) // 2))
    return out


def _preview_tile(spec: dict, card: Image.Image) -> Image.Image:
    tile = Image.new("RGBA", (620, 360), (18, 26, 32, 255))
    tile.alpha_composite(card, (30, 25))
    draw = ImageDraw.Draw(tile)
    draw.rectangle((20, 20, 600, 340), outline=(*tuple(spec.get("glow", spec["accent"])), 170), width=3)
    draw.text((34, 315), f"{spec['id']} / {spec['label']}", font=_font(13), fill=(238, 231, 205, 255))
    return tile


def _font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    try:
        return ImageFont.truetype(str(FONT_BOLD), size)
    except OSError:
        return ImageFont.load_default()


def _build_contact_sheet(previews: list[Image.Image]) -> Image.Image:
    cols = 2
    rows = math.ceil(len(previews) / cols)
    sheet = Image.new("RGBA", (cols * 620, rows * 360), (12, 16, 22, 255))
    for index, tile in enumerate(previews):
        sheet.alpha_composite(tile, ((index % cols) * 620, (index // cols) * 360))
    return sheet


if __name__ == "__main__":
    main()
