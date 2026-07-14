#!/usr/bin/env python3
"""Generate text-free common primary-action button variants deterministically."""

from __future__ import annotations

import re
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "showcase" / "common"
PALETTE_PATH = ROOT / "src" / "ui" / "palette.gd"


def palette_color(name: str, alpha: int = 255) -> tuple[int, int, int, int]:
    text = PALETTE_PATH.read_text(encoding="utf-8")
    match = re.search(rf'^const {re.escape(name)} := Color\("#([0-9a-fA-F]{{6}})"\)', text, re.MULTILINE)
    if match is None:
        raise ValueError(f"palette color not found: {name}")
    value = match.group(1)
    return tuple(int(value[index : index + 2], 16) for index in (0, 2, 4)) + (alpha,)


COLORS = {
    "navy": palette_color("DARK_PANEL", 238),
    "navy_deep": palette_color("DARK_PANEL_DEEP", 246),
    "gold": palette_color("GOLD"),
    "gold_deep": palette_color("GOLD_DEEP"),
    "paper": palette_color("PARCHMENT"),
    "sand": palette_color("SAND"),
    # Preserve the accepted M3 pressed-state pixels during common promotion.
    # This legacy generator tone predates Palette.WOOD_DARK and is asset-local.
    "wood_dark": (62, 38, 22, 255),
    "teal": palette_color("SEA_SHALLOW"),
    # Palette.SHADOW is Color(0, 0, 0, 0.34); the established asset uses 86/255.
    "shadow": (0, 0, 0, 86),
}


def rgba(color: str, alpha: int | None = None) -> tuple[int, int, int, int]:
    red, green, blue, base_alpha = COLORS[color]
    return (red, green, blue, base_alpha if alpha is None else alpha)


def mix(a, b, amount: float) -> tuple[int, int, int, int]:
    return tuple(int(a[index] * (1.0 - amount) + b[index] * amount) for index in range(4))


def gradient_rect(draw: ImageDraw.ImageDraw, xy, top, bottom) -> None:
    x0, y0, x1, y1 = map(int, xy)
    height = max(1, y1 - y0)
    for y in range(y0, y1):
        amount = (y - y0) / height
        draw.line((x0, y, x1, y), fill=mix(top, bottom, amount))


def save_png_if_pixels_changed(candidate: Image.Image, output_path: Path) -> bool:
    candidate.load()
    if output_path.is_file():
        with Image.open(output_path) as existing:
            existing.load()
            if existing.size == candidate.size and existing.mode == candidate.mode and existing.tobytes() == candidate.tobytes():
                print(f"preserved pixel-identical {output_path}")
                return False
    temporary_path = output_path.with_name(f".{output_path.name}.tmp")
    try:
        candidate.save(temporary_path, format="PNG", optimize=False, compress_level=9)
        temporary_path.replace(output_path)
    finally:
        temporary_path.unlink(missing_ok=True)
    print(f"updated {output_path}")
    return True


def draw_primary_action_frame(state: str) -> Image.Image:
    """Build one generic 190x50 primary-action skin without text or domain art."""
    width, height = 190, 50
    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    offset_y = 2 if state == "pressed" else 0
    outline = rgba("teal") if state == "focus" else rgba("gold_deep")
    if state == "hover":
        top, bottom = rgba("paper"), rgba("gold")
    elif state == "pressed":
        top, bottom = rgba("gold_deep"), mix(rgba("gold_deep"), rgba("wood_dark"), 0.34)
    elif state == "disabled":
        top, bottom = mix(rgba("navy"), rgba("gold_deep"), 0.22), rgba("navy_deep")
    else:
        top, bottom = rgba("gold"), rgba("gold_deep")

    polygon = [
        (8, 2 + offset_y), (181, 2 + offset_y), (188, 9 + offset_y),
        (188, 40 + offset_y), (181, 47 + offset_y), (8, 47 + offset_y),
        (1, 40 + offset_y), (1, 9 + offset_y),
    ]
    shadow = [(x + 1, min(height - 1, y + 2)) for x, y in polygon]
    draw.polygon(shadow, fill=rgba("shadow", 118))

    fill = Image.new("RGBA", image.size, (0, 0, 0, 0))
    gradient_rect(ImageDraw.Draw(fill), (0, 0, width, height), top, bottom)
    mask = Image.new("L", image.size, 0)
    ImageDraw.Draw(mask).polygon(polygon, fill=255)
    image.alpha_composite(Image.composite(fill, Image.new("RGBA", image.size), mask))
    draw = ImageDraw.Draw(image)
    draw.line(polygon + [polygon[0]], fill=outline, width=3, joint="curve")
    inner = [
        (13, 7 + offset_y), (176, 7 + offset_y), (183, 12 + offset_y),
        (183, 37 + offset_y), (176, 42 + offset_y), (13, 42 + offset_y),
        (6, 37 + offset_y), (6, 12 + offset_y),
    ]
    draw.line(inner + [inner[0]], fill=rgba("paper", 210), width=1, joint="curve")

    ink = rgba("navy_deep", 220) if state != "disabled" else rgba("sand", 150)
    for direction in (-1, 1):
        anchor = 26 if direction < 0 else 164
        for step in (0, 10):
            x = anchor + direction * step
            draw.line(
                [(x - direction * 4, 18 + offset_y), (x + direction * 3, 25 + offset_y), (x - direction * 4, 32 + offset_y)],
                fill=ink,
                width=3,
                joint="curve",
            )
    if state == "focus":
        draw.line([(12, 5), (177, 5)], fill=rgba("teal"), width=2)
        draw.line([(12, 44), (177, 44)], fill=rgba("teal"), width=2)
    return image


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    for state in ("normal", "hover", "pressed", "focus", "disabled"):
        save_png_if_pixels_changed(
            draw_primary_action_frame(state),
            OUT / f"primary_action_{state}.png",
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
