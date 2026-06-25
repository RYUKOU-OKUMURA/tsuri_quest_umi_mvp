#!/usr/bin/env python3
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "showcase" / "underwater"
FISH_SOURCE = OUT_DIR / "kurodai_chroma_source.png"
FISH_SHEET = OUT_DIR / "kurodai_showcase_sheet.png"
FISH_CARD_PORTRAIT = OUT_DIR / "kurodai_card_portrait.png"
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


def _clean_transparent_fish_edge(image: Image.Image) -> Image.Image:
    out = image.copy()
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if a < 38:
                px[x, y] = (r, g, b, int(a * 0.55))
                continue
            if a < 246 and ((r > g + 14 and b > g + 14) or (r > 112 and b > 118 and g < 118)):
                gray = max(22, min(112, int(g * 1.18 + min(r, b) * 0.10)))
                alpha = a
                if a < 132:
                    alpha = int(a * 0.78)
                px[x, y] = (gray, min(122, gray + 7), min(140, gray + 24), alpha)
    return out


def _add_runtime_fish_edge_underlay(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    expanded = alpha.filter(ImageFilter.MaxFilter(5)).filter(ImageFilter.GaussianBlur(1.15))
    inner = alpha.filter(ImageFilter.GaussianBlur(0.35))
    edge = ImageChops.subtract(expanded, inner).point(lambda value: int(value * 0.34))
    underlay = Image.new("RGBA", image.size, (8, 28, 42, 0))
    underlay.putalpha(edge)
    return Image.alpha_composite(underlay, image)


def create_kurodai_sheet() -> Image.Image:
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

    clean_sheet = _clean_transparent_fish_edge(_final_despill(sheet))
    _add_runtime_fish_edge_underlay(clean_sheet).save(FISH_SHEET)
    return clean_sheet


def create_kurodai_card_portrait(sheet: Image.Image | None = None) -> None:
    if sheet is None:
        sheet = Image.open(FISH_SHEET).convert("RGBA")
    frame_w = sheet.width // 4
    frame = sheet.crop((0, 0, frame_w, sheet.height))
    crop = frame.crop(_content_bbox(frame))
    # Match the in-game sidebar portrait window. A 720x330 source became too
    # wide for the runtime card slot and made the fish feel like a shrunken
    # document thumbnail rather than the card's subject.
    canvas = Image.new("RGBA", (620, 330), _rgba("#f4ead4"))
    d = ImageDraw.Draw(canvas)
    d.rounded_rectangle((10, 10, canvas.width - 10, canvas.height - 10), radius=12, fill=_rgba("#f4ead4"), outline=_rgba("#c6aa73", 82), width=2)
    for y in range(54, canvas.height - 34, 58):
        d.line((42, y, canvas.width - 42, y), fill=_rgba("#c3a873", 30), width=1)
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse((92, 236, canvas.width - 70, 300), fill=(72, 52, 31, 28))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(7)))

    max_w = int(canvas.width * 0.90)
    max_h = int(canvas.height * 0.84)
    scale = min(max_w / crop.width, max_h / crop.height)
    resized = crop.resize((round(crop.width * scale), round(crop.height * scale)), Image.Resampling.LANCZOS)
    x = (canvas.width - resized.width) // 2
    y = (canvas.height - resized.height) // 2 - 4
    canvas.alpha_composite(resized, (x, y))
    canvas.save(FISH_CARD_PORTRAIT)


def _rgba(hex_value: str, alpha: int = 255) -> tuple[int, int, int, int]:
    value = hex_value.lstrip("#")
    return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16), alpha)


def _star_points(
    cx: float,
    cy: float,
    outer: float,
    inner: float,
    count: int,
    flatten: float = 0.56,
    phase: float = -math.pi / 2,
) -> list[tuple[float, float]]:
    points: list[tuple[float, float]] = []
    for i in range(count * 2):
        radius = outer if i % 2 == 0 else inner
        angle = phase + i * math.pi / count
        points.append((cx + math.cos(angle) * radius, cy + math.sin(angle) * radius * flatten))
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
    w, h = 540, 205
    image = Image.new("RGBA", (w * scale, h * scale), (0, 0, 0, 0))
    d = ImageDraw.Draw(image)
    cx, cy = w * scale * 0.50, h * scale * 0.55
    outer = _star_points(cx, cy, 220 * scale, 112 * scale, 16, 0.50)
    inner = _star_points(cx, cy, 178 * scale, 84 * scale, 16, 0.46, -math.pi / 2 + math.pi / 32)
    core = _star_points(cx, cy, 132 * scale, 68 * scale, 12, 0.42)

    # Soft shadow.
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.polygon([(x + 8 * scale, y + 10 * scale) for x, y in outer], fill=(0, 0, 0, 128))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(4.5 * scale)))

    # Layered blue splash body. Keep the warm color for the live Godot text, not
    # the asset, so the badge reads like water instead of an orange sticker.
    d.polygon(outer, fill=_rgba("#061a3a", 248))
    d.line(outer + [outer[0]], fill=_rgba("#1b5b90", 204), width=7 * scale, joint="curve")
    d.line(outer + [outer[0]], fill=_rgba("#8ce7ff", 120), width=2 * scale, joint="curve")
    d.polygon(inner, fill=_rgba("#083765", 240))
    d.line(inner + [inner[0]], fill=_rgba("#4fbdea", 112), width=2 * scale, joint="curve")
    d.polygon(core, fill=_rgba("#0b4f84", 222))

    for i in range(12):
        angle = -math.pi + i * math.tau / 12
        x0 = cx + math.cos(angle) * (45 + (i % 4) * 5) * scale
        y0 = cy + math.sin(angle) * (10 + (i % 3) * 2) * scale
        x1 = cx + math.cos(angle) * (118 + (i % 5) * 11) * scale
        y1 = cy + math.sin(angle) * (24 + (i % 4) * 4) * scale
        d.line((x0, y0, x1, y1), fill=(205, 246, 255, 40), width=max(1, 1 * scale))

    # Tiny foam flecks and glints.
    for i in range(18):
        angle = i * math.tau / 18
        radius = (118 + (i % 6) * 13) * scale
        x = cx + math.cos(angle) * radius
        y = cy + math.sin(angle) * radius * 0.31
        r = (1.5 + i % 2) * scale
        d.ellipse((x - r, y - r, x + r, y + r), fill=(236, 255, 255, 82))
    for i in range(3):
        x = cx + (-52 + i * 52) * scale
        y = cy + (-38 + (i % 3) * 18) * scale
        d.line(
            (x - 12 * scale, y + 5 * scale, x + 14 * scale, y - 6 * scale),
            fill=(255, 255, 255, 46),
            width=1 * scale,
        )

    image = image.resize((w, h), Image.Resampling.LANCZOS)
    # Keep exact text out of the asset; Godot draws the Japanese label.
    image.save(HIT_BURST)


def main() -> None:
    clean_sheet = create_kurodai_sheet()
    create_kurodai_card_portrait(clean_sheet)
    create_hit_burst()
    print(f"processed {FISH_SHEET}, {FISH_CARD_PORTRAIT}, and {HIT_BURST}")


if __name__ == "__main__":
    main()
