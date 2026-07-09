#!/usr/bin/env python3
"""Process AI sources for harbor departure-plan panel + row icons into showcase PNGs.

Pipeline (docs/19 §3.4 / docs/33 §3.0):
  tools/source_assets/harbor/*_source.png
    → chroma key / crop / header cleanup (no baked JP text)
    → assets/showcase/harbor/
"""

from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "tools" / "source_assets" / "harbor"
HARBOR_OUT = ROOT / "assets" / "showcase" / "harbor"

PANEL_SOURCE = SOURCE_DIR / "harbor_plan_panel_source.png"
ICONS_SOURCE = SOURCE_DIR / "harbor_plan_icons_contact_source.png"

PANEL_OUT = HARBOR_OUT / "harbor_plan_panel.png"
ICON_OUTS = {
    "guide": HARBOR_OUT / "harbor_plan_icon_guide.png",
    "weather": HARBOR_OUT / "harbor_weather_stub_icon.png",
    "pin": HARBOR_OUT / "harbor_plan_icon_pin.png",
    "rumor": HARBOR_OUT / "harbor_plan_icon_rumor.png",
}

# Runtime plan card is ~730x249; export 2x for crisp 9-slice-ish stretch.
PANEL_SIZE = (1460, 498)
ICON_SIZE = (96, 96)

# Palette anchors (docs/19 §4.1 / palette.gd)
PARCHMENT = (243, 232, 205)
NAVY = (19, 40, 63)
GOLD = (255, 231, 168)
GOLD_DARK = (146, 98, 42)
BROWN = (74, 43, 22)


def _remove_chroma_magenta(image: Image.Image) -> Image.Image:
    img = image.convert("RGBA")
    pixels = img.load()
    width, height = img.size
    border_samples: list[tuple[int, int, int, int]] = []
    for x in range(0, width, max(1, width // 80)):
        border_samples.append(pixels[x, 0])
        border_samples.append(pixels[x, height - 1])
    for y in range(0, height, max(1, height // 80)):
        border_samples.append(pixels[0, y])
        border_samples.append(pixels[width - 1, y])
    key_r = round(sum(p[0] for p in border_samples) / len(border_samples))
    key_g = round(sum(p[1] for p in border_samples) / len(border_samples))
    key_b = round(sum(p[2] for p in border_samples) / len(border_samples))

    transparent_threshold = 55.0
    opaque_threshold = 140.0
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            # Magenta-ish: high R+B, low G
            magenta_score = (r + b) * 0.5 - g
            distance = math.sqrt((r - key_r) ** 2 + (g - key_g) ** 2 + (b - key_b) ** 2)
            if distance <= transparent_threshold or (magenta_score > 70 and g < 90):
                pixels[x, y] = (r, g, b, 0)
            elif distance < opaque_threshold and magenta_score > 40:
                t = (distance - transparent_threshold) / (opaque_threshold - transparent_threshold)
                edge_alpha = int(a * t)
                # Despill magenta toward parchment/neutral
                nr = min(r, max(g, b) + 20)
                nb = min(b, max(r, g) + 20)
                pixels[x, y] = (nr, g, nb, edge_alpha)
    return img


def _trim_alpha(image: Image.Image, pad: int = 2) -> Image.Image:
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        return image
    x0, y0, x1, y1 = bbox
    x0 = max(0, x0 - pad)
    y0 = max(0, y0 - pad)
    x1 = min(image.width, x1 + pad)
    y1 = min(image.height, y1 + pad)
    return image.crop((x0, y0, x1, y1))


def _fit_contain(image: Image.Image, size: tuple[int, int], margin: int = 0) -> Image.Image:
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    inner_w = max(1, size[0] - margin * 2)
    inner_h = max(1, size[1] - margin * 2)
    fitted = image.copy()
    fitted.thumbnail((inner_w, inner_h), Image.Resampling.LANCZOS)
    ox = (size[0] - fitted.width) // 2
    oy = (size[1] - fitted.height) // 2
    canvas.alpha_composite(fitted, (ox, oy))
    return canvas


def _draw_ship_wheel(draw: ImageDraw.ImageDraw, cx: int, cy: int, radius: int) -> None:
    draw.ellipse(
        (cx - radius, cy - radius, cx + radius, cy + radius),
        outline=GOLD + (235,),
        width=max(2, radius // 6),
    )
    draw.ellipse(
        (cx - radius // 3, cy - radius // 3, cx + radius // 3, cy + radius // 3),
        outline=GOLD + (220,),
        width=max(2, radius // 8),
    )
    for angle_deg in range(0, 360, 45):
        rad = math.radians(angle_deg)
        x1 = cx + int(math.cos(rad) * (radius // 3))
        y1 = cy + int(math.sin(rad) * (radius // 3))
        x2 = cx + int(math.cos(rad) * radius)
        y2 = cy + int(math.sin(rad) * radius)
        draw.line((x1, y1, x2, y2), fill=GOLD + (230,), width=max(2, radius // 7))
    hub = max(2, radius // 5)
    draw.ellipse((cx - hub, cy - hub, cx + hub, cy + hub), fill=GOLD_DARK + (255,))


def _clean_header_band(panel: Image.Image) -> Image.Image:
    """Cover any baked JP title with a clean navy header + wheel motif (runtime draws text)."""
    img = panel.copy()
    w, h = img.size
    # Header occupies roughly top 12–18% of the panel body.
    header_top = int(h * 0.045)
    header_bottom = int(h * 0.175)
    band = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(band)
    # Soft navy fill over the title band only (keep outer gold frame).
    inset = int(w * 0.028)
    draw.rounded_rectangle(
        (inset, header_top, w - inset, header_bottom),
        radius=max(6, h // 40),
        fill=NAVY + (245,),
    )
    # Thin gold underline
    draw.line(
        (inset + 8, header_bottom - 2, w - inset - 8, header_bottom - 2),
        fill=GOLD + (160,),
        width=2,
    )
    # Ship's wheel on the left of the header (title text is runtime, left-aligned with padding)
    wheel_r = max(8, (header_bottom - header_top) // 3)
    _draw_ship_wheel(draw, inset + wheel_r + 14, (header_top + header_bottom) // 2, wheel_r)
    img.alpha_composite(band)
    return img


def _quantize_toward_palette(image: Image.Image) -> Image.Image:
    """Gentle color pull toward parchment/navy/gold without posterizing."""
    alpha = image.getchannel("A")
    rgb = image.convert("RGB")
    rgb = ImageEnhance.Color(rgb).enhance(0.92)
    rgb = ImageEnhance.Contrast(rgb).enhance(1.04)
    out = rgb.convert("RGBA")
    out.putalpha(alpha)
    return out


def build_plan_panel() -> Path:
    if not PANEL_SOURCE.exists():
        raise SystemExit(f"missing panel source: {PANEL_SOURCE}")
    raw = _remove_chroma_magenta(Image.open(PANEL_SOURCE))
    trimmed = _trim_alpha(raw, pad=2)
    # Cover-fit: fill the slot (slight crop ok) so side magenta margins don't leave gaps.
    scale = max(PANEL_SIZE[0] / trimmed.width, PANEL_SIZE[1] / trimmed.height)
    resized = trimmed.resize(
        (max(1, int(trimmed.width * scale)), max(1, int(trimmed.height * scale))),
        Image.Resampling.LANCZOS,
    )
    ox = (resized.width - PANEL_SIZE[0]) // 2
    oy = (resized.height - PANEL_SIZE[1]) // 2
    fitted = resized.crop((ox, oy, ox + PANEL_SIZE[0], oy + PANEL_SIZE[1]))
    cleaned = _clean_header_band(fitted)
    cleaned = _quantize_toward_palette(cleaned)
    cleaned = ImageEnhance.Sharpness(cleaned).enhance(1.05)
    HARBOR_OUT.mkdir(parents=True, exist_ok=True)
    cleaned.save(PANEL_OUT)
    return PANEL_OUT


def _icon_cells(contact: Image.Image) -> dict[str, Image.Image]:
    """2x2 contact sheet → guide / weather / pin / rumor."""
    w, h = contact.size
    mid_x, mid_y = w // 2, h // 2
    # Small inset to avoid grid lines / magenta bleed between cells
    pad = max(8, w // 64)
    boxes = {
        "guide": (pad, pad, mid_x - pad, mid_y - pad),
        "weather": (mid_x + pad, pad, w - pad, mid_y - pad),
        "pin": (pad, mid_y + pad, mid_x - pad, h - pad),
        "rumor": (mid_x + pad, mid_y + pad, w - pad, h - pad),
    }
    return {key: contact.crop(box) for key, box in boxes.items()}


def build_plan_icons() -> list[Path]:
    if not ICONS_SOURCE.exists():
        raise SystemExit(f"missing icons source: {ICONS_SOURCE}")
    contact = Image.open(ICONS_SOURCE).convert("RGBA")
    # If source already has magenta bg, key the whole sheet first for cleaner crops
    keyed = _remove_chroma_magenta(contact)
    cells = _icon_cells(keyed)
    outs: list[Path] = []
    for key, cell in cells.items():
        icon = _trim_alpha(cell, pad=2)
        # Re-key in case crop still has magenta fringe
        icon = _remove_chroma_magenta(icon)
        icon = _trim_alpha(icon, pad=1)
        icon = _fit_contain(icon, ICON_SIZE, margin=4)
        icon = _quantize_toward_palette(icon)
        icon = ImageEnhance.Sharpness(icon).enhance(1.08)
        out_path = ICON_OUTS[key]
        icon.save(out_path)
        outs.append(out_path)
    return outs


def build_all() -> list[Path]:
    paths = [build_plan_panel()]
    paths.extend(build_plan_icons())
    return paths


def main() -> int:
    for path in build_all():
        print(path.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
