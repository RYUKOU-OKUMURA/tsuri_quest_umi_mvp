#!/usr/bin/env python3
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "showcase" / "underwater"
FISH_SOURCE = OUT_DIR / "kurodai_chroma_source.png"
FISH_SHEET = OUT_DIR / "kurodai_showcase_sheet.png"
HIT_BURST = OUT_DIR / "hit_burst.png"


def _magenta_removed(image: Image.Image) -> Image.Image:
    src = image.convert("RGBA")
    out = Image.new("RGBA", src.size, (0, 0, 0, 0))
    px = src.load()
    dst = out.load()
    for y in range(src.height):
        for x in range(src.width):
            r, g, b, a = px[x, y]
            # The ImageGen source uses a flat #ff00ff key with antialiased edges.
            dist = math.sqrt((r - 255) ** 2 + g**2 + (b - 255) ** 2)
            if dist < 36:
                continue
            alpha = a
            if dist < 130:
                alpha = int(a * (dist - 36) / 94)
            # Despill magenta from the antialiased edge. The fish itself is
            # gray/silver, so purple edge pixels should become cool dark linework.
            if r > 125 and b > 125 and g < 115:
                gray = max(18, min(112, int(g * 1.55) + 18))
                r = gray
                g = min(118, gray + 6)
                b = min(142, gray + 28)
                if dist < 190:
                    alpha = int(alpha * 0.78)
            else:
                r = min(r, int((g + b) * 0.72))
                b = min(b, int((r + g) * 0.95))
            if r > 105 and b > 105 and g < 105:
                gray = max(24, min(100, g + 24))
                r = gray
                g = min(116, gray + 6)
                b = min(132, gray + 24)
            dst[x, y] = (r, g, b, max(0, min(255, alpha)))
    return out


def _content_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    alpha = image.getchannel("A")
    bbox = alpha.point(lambda value: 255 if value > 16 else 0).getbbox()
    if bbox is None:
        return (0, 0, image.width, image.height)
    x0, y0, x1, y1 = bbox
    pad_x = max(12, int((x1 - x0) * 0.05))
    pad_y = max(12, int((y1 - y0) * 0.10))
    return (
        max(0, x0 - pad_x),
        max(0, y0 - pad_y),
        min(image.width, x1 + pad_x),
        min(image.height, y1 + pad_y),
    )


def _final_despill(image: Image.Image) -> Image.Image:
    out = image.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a > 0 and r > 105 and b > 105 and g < 110:
                gray = max(22, min(104, g + 24))
                alpha = a
                if a < 120:
                    alpha = int(a * 0.72)
                px[x, y] = (gray, min(118, gray + 6), min(136, gray + 24), alpha)
    return out


def create_kurodai_sheet() -> None:
    source = _magenta_removed(Image.open(FISH_SOURCE))
    # ImageGen passes can produce either a four-cell source sheet or a single
    # reference-quality fish cutout. The final runtime asset always remains a
    # four-frame sheet, but single-source art should be duplicated instead of
    # sliced into unusable quarters.
    source_frames = 1 if source.width / max(1, source.height) < 2.4 else 4
    source_w = source.width // source_frames
    frame_w, frame_h = 640, 320

    source_indices = [0, 0, 0, 0] if source_frames == 1 else [1, 1, 2, 3]
    sheet = Image.new("RGBA", (frame_w * len(source_indices), frame_h), (0, 0, 0, 0))
    for index, source_index in enumerate(source_indices):
        raw = source.crop((source_index * source_w, 0, (source_index + 1) * source_w, source.height))
        crop = raw.crop(_content_bbox(raw))
        max_w = int(frame_w * 0.96)
        max_h = int(frame_h * 0.92)
        scale = min(max_w / crop.width, max_h / crop.height)
        resized = crop.resize((round(crop.width * scale), round(crop.height * scale)), Image.Resampling.LANCZOS)
        # Keep all frames visually centered, with a slight downward bias like the reference.
        x = index * frame_w + (frame_w - resized.width) // 2
        y = (frame_h - resized.height) // 2 + 8
        sheet.alpha_composite(resized, (x, y))

    _final_despill(sheet).save(FISH_SHEET)


def _rgba(hex_value: str, alpha: int = 255) -> tuple[int, int, int, int]:
    value = hex_value.lstrip("#")
    return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16), alpha)


def _star_points(cx: float, cy: float, outer: float, inner: float, count: int) -> list[tuple[float, float]]:
    points: list[tuple[float, float]] = []
    for i in range(count * 2):
        radius = outer if i % 2 == 0 else inner
        angle = -math.pi / 2 + i * math.pi / count
        # Flatten the badge to match the reference's comic splash.
        points.append((cx + math.cos(angle) * radius, cy + math.sin(angle) * radius * 0.56))
    return points


def _font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for path in (
        "/System/Library/Fonts/ヒラギノ角ゴシック W8.ttc",
        "/System/Library/Fonts/Helvetica.ttc",
        "/Library/Fonts/Arial Unicode.ttf",
    ):
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()


def create_hit_burst() -> None:
    scale = 3
    w, h = 560, 220
    image = Image.new("RGBA", (w * scale, h * scale), (0, 0, 0, 0))
    d = ImageDraw.Draw(image)
    cx, cy = w * scale * 0.50, h * scale * 0.52

    # Soft shadow.
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.polygon(_star_points(cx + 8 * scale, cy + 10 * scale, 210 * scale, 126 * scale, 15), fill=(0, 0, 0, 120))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(4 * scale)))

    # Badge outline and body.
    d.polygon(_star_points(cx, cy, 210 * scale, 126 * scale, 15), fill=_rgba("#082549", 245))
    d.line(_star_points(cx, cy, 210 * scale, 126 * scale, 15) + [_star_points(cx, cy, 210 * scale, 126 * scale, 15)[0]], fill=_rgba("#5cb7ec", 235), width=4 * scale, joint="curve")
    d.polygon(_star_points(cx, cy, 174 * scale, 104 * scale, 15), fill=_rgba("#0f497a", 232))

    # White-blue water edges, restrained compared with the previous explosion asset.
    for i in range(22):
        angle = -math.pi + i * math.tau / 22
        x0 = cx + math.cos(angle) * 52 * scale
        y0 = cy + math.sin(angle) * 14 * scale
        x1 = cx + math.cos(angle) * (138 + (i % 3) * 10) * scale
        y1 = cy + math.sin(angle) * (30 + (i % 4) * 4) * scale
        d.line((x0, y0, x1, y1), fill=(205, 245, 255, 120), width=max(1, 2 * scale))

    # Warm center behind the live Godot text.
    d.ellipse((cx - 112 * scale, cy - 48 * scale, cx + 112 * scale, cy + 48 * scale), fill=(255, 138, 24, 86))
    d.ellipse((cx - 82 * scale, cy - 34 * scale, cx + 82 * scale, cy + 34 * scale), fill=(255, 232, 82, 58))

    # Tiny foam flecks.
    for i in range(34):
        angle = i * math.tau / 34
        radius = (135 + (i % 5) * 14) * scale
        x = cx + math.cos(angle) * radius
        y = cy + math.sin(angle) * radius * 0.32
        r = (2 + i % 3) * scale
        d.ellipse((x - r, y - r, x + r, y + r), fill=(236, 255, 255, 170))

    image = image.resize((w, h), Image.Resampling.LANCZOS)
    # Keep exact text out of the asset; Godot draws the Japanese label.
    image.save(HIT_BURST)


def main() -> None:
    create_kurodai_sheet()
    create_hit_burst()
    print(f"processed {FISH_SHEET} and {HIT_BURST}")


if __name__ == "__main__":
    main()
