#!/usr/bin/env python3
from __future__ import annotations

import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "showcase" / "underwater"


def _rgba(hex_value: str, alpha: int = 255) -> tuple[int, int, int, int]:
    value = hex_value.lstrip("#")
    return (int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16), alpha)


def _texture(size: tuple[int, int], base: str, seed: int, strength: int = 10) -> Image.Image:
    rng = random.Random(seed)
    w, h = size
    r, g, b, a = _rgba(base)
    pixels = bytearray()
    for y in range(h):
        warm = int((y / max(1, h - 1) - 0.5) * strength)
        for x in range(w):
            grain = rng.randint(-strength, strength)
            speck = rng.randint(-3, 3) if (x * 17 + y * 23) % 19 == 0 else 0
            pixels.extend(
                (
                    max(0, min(255, r + grain + warm + speck)),
                    max(0, min(255, g + grain + warm + speck)),
                    max(0, min(255, b + grain + warm + speck)),
                    a,
                )
            )
    return Image.frombytes("RGBA", size, bytes(pixels))


def _paste_masked(dst: Image.Image, src: Image.Image, mask: Image.Image, xy: tuple[int, int]) -> None:
    dst.alpha_composite(Image.composite(src, Image.new("RGBA", src.size, (0, 0, 0, 0)), mask), xy)


def _rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def _draw_card(
    image: Image.Image,
    box: tuple[int, int, int, int],
    fill: str,
    *,
    radius: int = 16,
    border: str = "#5b3f1f",
    inner: str = "#d7b765",
    seed: int = 1,
    texture_strength: int = 8,
    shadow: bool = True,
) -> None:
    x0, y0, x1, y1 = box
    w = x1 - x0
    h = y1 - y0
    if shadow:
        shadow_layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
        sd = ImageDraw.Draw(shadow_layer)
        sd.rounded_rectangle((x0 + 5, y0 + 7, x1 + 5, y1 + 7), radius=radius, fill=(0, 0, 0, 86))
        image.alpha_composite(shadow_layer.filter(ImageFilter.GaussianBlur(5)))

    mask = _rounded_mask((w, h), radius)
    texture = _texture((w, h), fill, seed, texture_strength)
    _paste_masked(image, texture, mask, (x0, y0))

    d = ImageDraw.Draw(image)
    d.rounded_rectangle((x0, y0, x1, y1), radius=radius, outline=_rgba("#1f1710"), width=4)
    d.rounded_rectangle((x0 + 4, y0 + 4, x1 - 4, y1 - 4), radius=max(2, radius - 4), outline=_rgba(border), width=4)
    d.rounded_rectangle((x0 + 10, y0 + 10, x1 - 10, y1 - 10), radius=max(2, radius - 8), outline=_rgba(inner, 160), width=2)
    d.line((x0 + 18, y0 + 16, x1 - 18, y0 + 16), fill=(255, 248, 218, 120), width=2)
    d.line((x0 + 18, y1 - 15, x1 - 18, y1 - 15), fill=(95, 58, 24, 80), width=2)
    for cx, cy in ((x0 + 12, y0 + 12), (x1 - 12, y0 + 12), (x0 + 12, y1 - 12), (x1 - 12, y1 - 12)):
        d.ellipse((cx - 4, cy - 4, cx + 4, cy + 4), fill=_rgba(inner), outline=_rgba("#3e2b16"))


def _draw_clean_card(
    image: Image.Image,
    box: tuple[int, int, int, int],
    fill: str,
    *,
    radius: int = 10,
    border: str = "#8a622e",
    inner: str = "#d2b06b",
    seed: int = 1,
    texture_strength: int = 6,
    shadow: bool = True,
) -> None:
    x0, y0, x1, y1 = box
    w = x1 - x0
    h = y1 - y0
    if shadow:
        shadow_layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
        sd = ImageDraw.Draw(shadow_layer)
        sd.rounded_rectangle((x0 + 3, y0 + 4, x1 + 3, y1 + 4), radius=radius, fill=(0, 0, 0, 54))
        image.alpha_composite(shadow_layer.filter(ImageFilter.GaussianBlur(4)))

    mask = _rounded_mask((w, h), radius)
    texture = _texture((w, h), fill, seed, texture_strength)
    _paste_masked(image, texture, mask, (x0, y0))

    d = ImageDraw.Draw(image)
    d.rounded_rectangle((x0, y0, x1, y1), radius=radius, outline=_rgba("#4a3218"), width=3)
    d.rounded_rectangle((x0 + 5, y0 + 5, x1 - 5, y1 - 5), radius=max(2, radius - 5), outline=_rgba(border, 185), width=2)
    d.rounded_rectangle((x0 + 10, y0 + 10, x1 - 10, y1 - 10), radius=max(2, radius - 8), outline=_rgba(inner, 105), width=1)
    d.line((x0 + 16, y0 + 14, x1 - 16, y0 + 14), fill=(255, 246, 215, 88), width=1)
    d.line((x0 + 16, y1 - 13, x1 - 16, y1 - 13), fill=(98, 67, 36, 42), width=1)


def _draw_navy_card(
    image: Image.Image,
    box: tuple[int, int, int, int],
    *,
    radius: int = 16,
    seed: int = 7,
    shadow: bool = True,
) -> None:
    _draw_clean_card(image, box, "#113654", radius=radius, border="#9f7a3d", inner="#dfbf73", seed=seed, shadow=shadow)
    x0, y0, x1, y1 = box
    overlay = Image.new("RGBA", (x1 - x0, y1 - y0), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    for i in range(5):
        y = int((i + 1) * overlay.height / 11)
        od.line((18, y, overlay.width - 18, y), fill=(92, 178, 214, 10), width=1)
    image.alpha_composite(overlay, (x0, y0))


def _draw_outer_frame(image: Image.Image, box: tuple[int, int, int, int], *, radius: int = 18) -> None:
    x0, y0, x1, y1 = box
    d = ImageDraw.Draw(image)
    shadow = Image.new("RGBA", image.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((x0 + 4, y0 + 6, x1 + 4, y1 + 6), radius=radius, fill=(0, 0, 0, 82))
    image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(6)))
    d.rounded_rectangle((x0, y0, x1, y1), radius=radius, fill=_rgba("#08213a", 230), outline=_rgba("#1c1209"), width=3)
    d.rounded_rectangle((x0 + 5, y0 + 5, x1 - 5, y1 - 5), radius=radius - 4, outline=_rgba("#d8b45d", 230), width=3)
    d.rounded_rectangle((x0 + 11, y0 + 11, x1 - 11, y1 - 11), radius=radius - 8, outline=_rgba("#6e4b22", 180), width=2)
    d.line((x0 + 22, y0 + 17, x1 - 22, y0 + 17), fill=(255, 240, 190, 70), width=1)
    d.line((x0 + 22, y1 - 17, x1 - 22, y1 - 17), fill=(0, 0, 0, 70), width=1)


def _draw_icon_well(d: ImageDraw.ImageDraw, center: tuple[int, int], radius: int, pale: bool = True) -> None:
    cx, cy = center
    fill = "#f4dfaa" if pale else "#0d2437"
    d.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill=_rgba(fill), outline=_rgba("#6d4b23"), width=3)
    d.ellipse((cx - radius + 6, cy - radius + 6, cx + radius - 6, cy + radius - 6), outline=_rgba("#e0bd62", 150), width=2)


def create_top_status_frame() -> None:
    w, h = 1774, 248
    image = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(image)
    y0, y1 = 22, 222
    slots = [
        (8, y0, int(w * 0.245) - 8, y1, "#f4ead5"),
        (int(w * 0.247) + 6, y0, int(w * 0.494) - 8, y1, "#f3e8d0"),
        (int(w * 0.496) + 6, y0, int(w * 0.701) - 8, y1, "#f5ead4"),
        (int(w * 0.704) + 8, y0, w - 8, y1, "#123554"),
    ]
    for i, (x0, sy0, x1, sy1, fill) in enumerate(slots):
        if i == 3:
            _draw_navy_card(image, (x0, sy0, x1, sy1), radius=12, seed=30 + i)
            _draw_icon_well(d, (x0 + 56, (sy0 + sy1) // 2), 34, pale=False)
        else:
            _draw_card(image, (x0, sy0, x1, sy1), fill, radius=12, seed=10 + i, texture_strength=7)
            _draw_icon_well(d, (x0 + 56, (sy0 + sy1) // 2), 32, pale=True)
            if i in (1, 2):
                d.line((x0 + 132, sy0 + 34, x0 + 132, sy1 - 34), fill=_rgba("#b8934d", 110), width=2)
    image.save(OUT_DIR / "top_status_frame.png")


def create_sidebar_frame() -> None:
    w, h = 678, 1024
    image = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(image)
    _draw_outer_frame(image, (7, 7, w - 8, h - 8), radius=18)

    header = (24, 22, w - 24, 112)
    fish = (28, 126, w - 28, 616)
    action = (24, 634, w - 24, 808)
    tackle = (24, 826, w - 24, h - 24)
    action_body = (42, 682, w - 42, 792)
    tackle_body = (42, 878, w - 42, h - 42)

    _draw_clean_card(
        image,
        header,
        "#075d47",
        radius=14,
        border="#0a342c",
        inner="#e1be65",
        seed=80,
        texture_strength=7,
        shadow=False,
    )
    d.line((header[0] + 24, header[3] - 15, header[2] - 24, header[3] - 15), fill=_rgba("#063626", 110), width=3)
    d.line((header[0] + 24, header[3] - 10, header[2] - 24, header[3] - 10), fill=_rgba("#f4d27c", 70), width=1)

    _draw_clean_card(image, fish, "#f1e4c7", radius=10, border="#8c6733", inner="#d2aa58", seed=81, texture_strength=7)

    _draw_navy_card(image, action, radius=12, seed=82)
    _draw_clean_card(image, action_body, "#f2e5cb", radius=8, border="#8c6733", inner="#d8b45d", seed=83, texture_strength=5)
    _draw_navy_card(image, tackle, radius=12, seed=84)
    _draw_clean_card(image, tackle_body, "#f2e5cb", radius=8, border="#8c6733", inner="#d8b45d", seed=85, texture_strength=5)

    # Sparse corner accents only. Heavy rivets made the frame read as generated/debug UI.
    for cx, cy in (
        (28, 28),
        (w - 28, 28),
        (28, h - 28),
        (w - 28, h - 28),
    ):
        d.ellipse((cx - 7, cy - 7, cx + 7, cy + 7), fill=_rgba("#112031"), outline=_rgba("#e1be65"), width=2)
        d.ellipse((cx - 2, cy - 2, cx + 2, cy + 2), fill=_rgba("#fff1b7", 210))

    image.save(OUT_DIR / "sidebar_frame.png")


def _draw_bar_well(image: Image.Image, box: tuple[int, int, int, int]) -> None:
    x0, y0, x1, y1 = box
    d = ImageDraw.Draw(image)
    d.rounded_rectangle((x0, y0, x1, y1), radius=8, fill=_rgba("#07121b", 235), outline=_rgba("#22384c", 190), width=2)
    for x in range(x0 + 28, x1, 54):
        d.line((x, y0 + 5, x, y1 - 5), fill=(255, 255, 255, 13), width=1)
    d.line((x0 + 7, y0 + 5, x1 - 7, y0 + 5), fill=(255, 255, 255, 26), width=1)


def create_fight_hud_frame() -> None:
    w, h = 2048, 456
    image = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(image)

    top = (int(w * 0.014), int(h * 0.065), int(w * 0.986), int(h * 0.520))
    bottom = (int(w * 0.014), int(h * 0.552), int(w * 0.986), int(h * 0.940))
    gap = 20
    depth_w = int(w * 0.225)
    left_w = int((top[2] - top[0] - depth_w - gap * 2) * 0.5)
    right_w = top[2] - top[0] - depth_w - gap * 2 - left_w
    tension = (top[0], top[1], top[0] + left_w, top[3])
    depth = (tension[2] + gap, top[1], tension[2] + gap + depth_w, top[3])
    stamina = (depth[2] + gap, top[1], depth[2] + gap + right_w, top[3])

    _draw_navy_card(image, top, radius=12, seed=40, shadow=True)
    d.line((top[0] + 30, top[1] + 54, top[2] - 30, top[1] + 54), fill=_rgba("#e0bd62", 55), width=2)
    d.line((top[0] + 30, top[3] - 24, top[2] - 30, top[3] - 24), fill=(255, 255, 255, 24), width=1)
    # Make the depth module read as the central blue plate from the reference.
    d.polygon(
        [
            (depth[0] + 12, depth[1] + 16),
            (depth[2] - 12, depth[1] + 16),
            (depth[2] - 60, depth[3] - 14),
            (depth[0] + 60, depth[3] - 14),
        ],
        fill=_rgba("#184c78", 225),
    )
    d.line((depth[0] + 10, depth[1] + 16, depth[0] + 60, depth[3] - 14), fill=_rgba("#d8b45d", 120), width=3)
    d.line((depth[2] - 10, depth[1] + 16, depth[2] - 60, depth[3] - 14), fill=_rgba("#d8b45d", 120), width=3)
    d.line((depth[0] + 36, depth[1] + 22, depth[2] - 36, depth[1] + 22), fill=_rgba("#e0bd62", 100), width=2)
    d.line((depth[0] + 48, depth[3] - 22, depth[2] - 48, depth[3] - 22), fill=(255, 255, 255, 26), width=1)

    _draw_bar_well(image, (tension[0] + 44, tension[1] + 88, tension[2] - 56, tension[1] + 142))
    _draw_bar_well(image, (stamina[0] + 44, stamina[1] + 88, stamina[2] - 48, stamina[1] + 142))

    bait_w = int((bottom[2] - bottom[0]) * 0.285)
    menu_w = int((bottom[2] - bottom[0]) * 0.26)
    hint_w = bottom[2] - bottom[0] - bait_w - menu_w - gap * 2
    bait = (bottom[0], bottom[1], bottom[0] + bait_w, bottom[3])
    hint = (bait[2] + gap, bottom[1], bait[2] + gap + hint_w, bottom[3])
    menu = (hint[2] + gap, bottom[1], bottom[2], bottom[3])

    _draw_navy_card(image, bottom, radius=12, seed=50, shadow=True)
    inner_y0 = bottom[1] + 10
    inner_y1 = bottom[3] - 10
    bait_panel = (bait[0] + 10, inner_y0, bait[2] - 4, inner_y1)
    hint_panel = (hint[0] + 4, inner_y0, hint[2] - 4, inner_y1)
    menu_panel = (menu[0] + 4, inner_y0, menu[2] - 10, inner_y1)
    _draw_clean_card(
        image,
        bait_panel,
        "#f3e6cc",
        radius=8,
        border="#8c6733",
        inner="#d8b45d",
        seed=51,
        texture_strength=5,
        shadow=False,
    )
    _draw_clean_card(
        image,
        hint_panel,
        "#f2e4c8",
        radius=8,
        border="#8c6733",
        inner="#d8b45d",
        seed=52,
        texture_strength=5,
        shadow=False,
    )
    _draw_clean_card(
        image,
        menu_panel,
        "#0e3a5b",
        radius=8,
        border="#9f7a3d",
        inner="#dfbf73",
        seed=53,
        texture_strength=5,
        shadow=False,
    )
    _draw_icon_well(d, (bait[0] + 80, (bait[1] + bait[3]) // 2), 30, pale=True)

    # Shared separators: enough structure without returning to the previous grid-like skin.
    for x in (depth[0] - gap // 2, depth[2] + gap // 2):
        d.line((x, top[1] + 22, x, top[3] - 22), fill=_rgba("#b88b3f", 82), width=2)
    for x in (hint[0] - gap // 2, menu[0] - gap // 2):
        d.line((x, bottom[1] + 16, x, bottom[3] - 16), fill=_rgba("#b88b3f", 90), width=2)

    image.save(OUT_DIR / "fight_hud_frame.png")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    create_sidebar_frame()
    create_top_status_frame()
    create_fight_hud_frame()
    print(f"generated clean UI frame assets in {OUT_DIR}")


if __name__ == "__main__":
    main()
