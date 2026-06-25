#!/usr/bin/env python3
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
REFERENCE = ROOT / "reference" / "02_underwater_fight_mockup.png"
OUTPUT = ROOT / "assets" / "showcase" / "underwater" / "underwater_battle_bg.png"
GENERATED_CENTER_PAINTOVER = ROOT / "tools" / "source_assets" / "underwater_center_paintover_candidate.png"

CANVAS_SIZE = (1672, 941)


def _make_full_window_subject_mask(size: tuple[int, int]) -> Image.Image:
    w, h = size
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)

    # The full reference water window preserves the authored left/right reefs
    # and seabed, so only remove the runtime subjects that will be redrawn by
    # Godot: the large kurodai, the hit burst, the line, and the lure.
    # Keep the subject mask broad enough to avoid fish/hit remnants in the
    # reusable background. Detail restoration comes from edge-only safe crops.
    draw.ellipse((w * 0.11, h * 0.16, w * 0.66, h * 0.68), fill=255)
    draw.rectangle((w * 0.22, h * 0.28, w * 0.60, h * 0.60), fill=255)
    draw.polygon(((w * 0.23, h * 0.38), (w * 0.10, h * 0.27), (w * 0.11, h * 0.62)), fill=255)
    draw.ellipse((w * 0.48, h * 0.24, w * 0.70, h * 0.62), fill=255)
    draw.polygon(((w * 0.40, h * 0.56), (w * 0.60, h * 0.54), (w * 0.58, h * 0.72), (w * 0.44, h * 0.72)), fill=255)

    draw.ellipse((w * 0.34, h * 0.62, w * 0.76, h * 1.04), fill=255)
    draw.rectangle((w * 0.34, h * 0.70, w * 0.76, h * 0.99), fill=255)

    draw.line((w * 0.91, -h * 0.08, w * 0.68, h * 0.54), fill=255, width=max(42, int(w * 0.046)))
    draw.line((w * 0.84, -h * 0.06, w * 0.67, h * 0.52), fill=255, width=max(32, int(w * 0.036)))
    draw.polygon(
        (
            (w * 0.78, 0.0),
            (w * 0.93, 0.0),
            (w * 0.74, h * 0.56),
            (w * 0.63, h * 0.53),
        ),
        fill=255,
    )
    draw.ellipse((w * 0.61, h * 0.33, w * 0.78, h * 0.58), fill=255)
    return mask.filter(ImageFilter.GaussianBlur(16.0))


def _make_water_fill(size: tuple[int, int]) -> Image.Image:
    w, h = size
    fill = Image.new("RGB", size)
    pixels = fill.load()
    for y in range(h):
        v = y / max(1, h - 1)
        for x in range(w):
            u = x / max(1, w - 1)
            top = (18, 143, 190)
            mid = (7, 107, 164)
            bottom = (9, 72, 105)
            if v < 0.58:
                t = v / 0.58
                base = tuple(round(top[i] * (1.0 - t) + mid[i] * t) for i in range(3))
            else:
                t = (v - 0.58) / 0.42
                base = tuple(round(mid[i] * (1.0 - t) + bottom[i] * t) for i in range(3))
            light = max(0.0, 1.0 - ((u - 0.48) ** 2 + (v - 0.28) ** 2) * 3.0)
            pixels[x, y] = tuple(min(255, round(base[i] + light * (18 if i != 2 else 30))) for i in range(3))
    return fill.filter(ImageFilter.GaussianBlur(1.2))


def _vertical_mask(size: tuple[int, int], alpha: int, top: float, bottom: float) -> Image.Image:
    w, h = size
    mask = Image.new("L", size, 0)
    pixels = mask.load()
    for y in range(h):
        v = y / max(1, h - 1)
        for x in range(w):
            u = x / max(1, w - 1)
            edge_wave = (
                math.sin(u * math.tau * 1.7) * 0.018
                + math.sin((u * 3.6 + 0.25) * math.tau) * 0.010
            )
            top_edge = top + edge_wave
            bottom_edge = bottom + math.sin((u * 2.2 + 0.55) * math.tau) * 0.014
            fade_in = min(1.0, max(0.0, (v - top_edge) / 0.18))
            fade_out = min(1.0, max(0.0, (bottom_edge - v) / 0.10))
            side_fade = min(1.0, u / 0.16, (1.0 - u) / 0.16)
            pixels[x, y] = int(alpha * fade_in * fade_out * side_fade)
    return mask.filter(ImageFilter.GaussianBlur(10.0))


def _soft_blob_mask(size: tuple[int, int], alpha: int, *, seed_offset: int = 0) -> Image.Image:
    w, h = size
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    for index in range(4):
        x0 = int(w * (0.02 + index * 0.18))
        x1 = int(w * (0.48 + index * 0.17))
        y0 = int(h * (0.16 + (index % 2) * 0.08))
        y1 = int(h * (0.92 - (index % 3) * 0.05))
        local_alpha = max(0, alpha - index * 8 + seed_offset)
        draw.ellipse((x0, y0, x1, y1), fill=local_alpha)
    return mask.filter(ImageFilter.GaussianBlur(max(8, int(min(w, h) * 0.07))))


def _stitch_reference_patches(left: Image.Image, right: Image.Image, *, align: str = "top") -> Image.Image:
    left = left.convert("RGB")
    right = right.convert("RGB")
    overlap = max(8, int(min(left.width, right.width) * 0.22))
    width = left.width + right.width - overlap
    height = max(left.height, right.height)
    stitched = Image.new("RGB", (width, height))

    left_y = height - left.height if align == "bottom" else 0
    right_y = height - right.height if align == "bottom" else 0
    stitched.paste(left, (0, left_y))

    mask = Image.new("L", right.size, 255)
    pixels = mask.load()
    for x in range(min(overlap, right.width)):
        alpha = int(255 * x / max(1, overlap - 1))
        for y in range(right.height):
            pixels[x, y] = alpha
    stitched.paste(right, (left.width - overlap, right_y), mask)
    return stitched


def _add_distant_fish_layer(
    base: Image.Image,
    source: Image.Image,
    subject_mask: Image.Image,
) -> None:
    w, h = source.size
    fish_source = source.crop((int(w * 0.73), int(h * 0.14), int(w * 0.96), int(h * 0.40)))
    positions = (
        (0.42, 0.30, 0.24, 0.110, 42, False),
        (0.53, 0.25, 0.19, 0.090, 36, True),
        (0.61, 0.36, 0.22, 0.105, 34, False),
        (0.70, 0.30, 0.18, 0.086, 30, True),
        (0.35, 0.40, 0.17, 0.080, 28, True),
    )
    for u, v, pw_ratio, ph_ratio, alpha, flip in positions:
        patch_size = (int(w * pw_ratio), int(h * ph_ratio))
        patch = fish_source.resize(patch_size, Image.Resampling.LANCZOS)
        if flip:
            patch = patch.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        patch = ImageEnhance.Brightness(patch).enhance(0.52)
        patch = ImageEnhance.Color(patch).enhance(0.62)
        patch = ImageEnhance.Contrast(patch).enhance(0.76)
        patch = patch.filter(ImageFilter.GaussianBlur(1.4)).convert("RGBA")

        x = int(w * u - patch_size[0] * 0.5)
        y = int(h * v - patch_size[1] * 0.5)
        local_mask = _soft_blob_mask(patch_size, alpha)
        local_mask = ImageChops.multiply(local_mask, _vertical_mask(patch_size, 230, 0.0, 1.0))
        subject_crop = subject_mask.crop((x, y, x + patch_size[0], y + patch_size[1]))
        local_mask = ImageChops.multiply(local_mask, subject_crop)
        base.alpha_composite(
            Image.composite(
                patch,
                Image.new("RGBA", patch_size, (0, 0, 0, 0)),
                local_mask,
            ),
            (x, y),
        )


def _add_midwater_bubble_texture(
    base: Image.Image,
    source: Image.Image,
    subject_mask: Image.Image,
) -> None:
    w, h = source.size
    bubbles = Image.new("RGBA", source.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(bubbles, "RGBA")
    for index in range(104):
        col = index % 16
        row = index // 16
        u = 0.23 + col * 0.038 + (row % 2) * 0.014
        v = 0.20 + row * 0.065 + math.sin(index * 1.7) * 0.010
        radius = 1.1 + (index % 4) * 0.55
        alpha = 21 + (index % 3) * 8
        draw.ellipse(
            (
                w * u - radius,
                h * v - radius,
                w * u + radius,
                h * v + radius,
            ),
            outline=(196, 238, 246, alpha),
            width=1,
        )
    for index in range(36):
        u = 0.30 + (index % 9) * 0.052
        v = 0.54 + (index // 9) * 0.042
        radius = 1.5 + (index % 3) * 0.7
        draw.ellipse(
            (
                w * u - radius,
                h * v - radius,
                w * u + radius,
                h * v + radius,
            ),
            outline=(213, 246, 245, 34),
            width=1,
        )
    bubble_mask = ImageChops.multiply(
        subject_mask,
        _vertical_mask(source.size, 108, 0.08, 0.78),
    )
    base.alpha_composite(
        Image.composite(
            bubbles,
            Image.new("RGBA", source.size, (0, 0, 0, 0)),
            bubble_mask.filter(ImageFilter.GaussianBlur(1.5)),
        ),
        (0, 0),
    )


def _add_reference_school_texture(
    base: Image.Image,
    source: Image.Image,
    subject_mask: Image.Image,
) -> None:
    w, h = source.size

    left_school = source.crop((int(w * 0.02), int(h * 0.14), int(w * 0.14), int(h * 0.42)))
    right_school = source.crop((int(w * 0.70), int(h * 0.12), int(w * 0.98), int(h * 0.40)))
    school_source = _stitch_reference_patches(left_school, right_school)

    patch_size = (int(w * 0.64), int(h * 0.38))
    patch = school_source.resize(patch_size, Image.Resampling.LANCZOS)
    patch = ImageEnhance.Brightness(patch).enhance(0.70)
    patch = ImageEnhance.Color(patch).enhance(0.70)
    patch = ImageEnhance.Contrast(patch).enhance(0.82)
    patch = patch.filter(ImageFilter.GaussianBlur(1.15)).convert("RGBA")

    x = int(w * 0.18)
    y = int(h * 0.16)
    alpha = ImageChops.multiply(
        subject_mask.crop((x, y, x + patch_size[0], y + patch_size[1])),
        _vertical_mask(patch_size, 72, 0.00, 0.90),
    )
    alpha = ImageChops.multiply(alpha, _soft_blob_mask(patch_size, 228, seed_offset=6))
    base.alpha_composite(
        Image.composite(
            patch,
            Image.new("RGBA", patch_size, (0, 0, 0, 0)),
            alpha,
        ),
        (x, y),
    )

    left_ridge = source.crop((int(w * 0.04), int(h * 0.58), int(w * 0.16), int(h * 0.80)))
    right_ridge = source.crop((int(w * 0.80), int(h * 0.58), int(w * 0.96), int(h * 0.80)))
    ridge_source = _stitch_reference_patches(left_ridge, right_ridge)
    ridge_size = (int(w * 0.70), int(h * 0.18))
    ridge = ridge_source.resize(ridge_size, Image.Resampling.LANCZOS)
    ridge = ImageEnhance.Brightness(ridge).enhance(0.62)
    ridge = ImageEnhance.Color(ridge).enhance(0.66)
    ridge = ImageEnhance.Contrast(ridge).enhance(0.74)
    ridge = ridge.filter(ImageFilter.GaussianBlur(2.2)).convert("RGBA")

    ridge_x = int(w * 0.17)
    ridge_y = int(h * 0.55)
    ridge_alpha = ImageChops.multiply(
        subject_mask.crop((ridge_x, ridge_y, ridge_x + ridge_size[0], ridge_y + ridge_size[1])),
        _vertical_mask(ridge_size, 42, 0.06, 0.98),
    )
    ridge_alpha = ImageChops.multiply(ridge_alpha, _soft_blob_mask(ridge_size, 236, seed_offset=10))
    base.alpha_composite(
        Image.composite(
            ridge,
            Image.new("RGBA", ridge_size, (0, 0, 0, 0)),
            ridge_alpha,
        ),
        (ridge_x, ridge_y),
    )


def _add_center_seabed_shelf(
    base: Image.Image,
    source: Image.Image,
    subject_mask: Image.Image,
) -> None:
    w, h = source.size
    left_shelf = source.crop((int(w * 0.04), int(h * 0.58), int(w * 0.16), int(h * 0.84)))
    right_shelf = source.crop((int(w * 0.78), int(h * 0.58), int(w * 0.96), int(h * 0.84)))
    shelf_source = _stitch_reference_patches(left_shelf, right_shelf)

    shelf_size = (int(w * 0.68), int(h * 0.30))
    shelf = shelf_source.resize(shelf_size, Image.Resampling.LANCZOS)
    shelf = ImageEnhance.Brightness(shelf).enhance(0.74)
    shelf = ImageEnhance.Color(shelf).enhance(0.78)
    shelf = ImageEnhance.Contrast(shelf).enhance(0.94)
    shelf = shelf.filter(ImageFilter.GaussianBlur(1.0)).convert("RGBA")

    x = int(w * 0.17)
    y = int(h * 0.48)
    shelf_alpha = ImageChops.multiply(
        subject_mask.crop((x, y, x + shelf_size[0], y + shelf_size[1])),
        _vertical_mask(shelf_size, 118, 0.02, 1.0),
    )
    shelf_alpha = ImageChops.multiply(shelf_alpha, _soft_blob_mask(shelf_size, 230, seed_offset=12))
    base.alpha_composite(
        Image.composite(
            shelf,
            Image.new("RGBA", shelf_size, (0, 0, 0, 0)),
            shelf_alpha,
        ),
        (x, y),
    )


def _add_center_floor_glints(
    base: Image.Image,
    source: Image.Image,
    subject_mask: Image.Image,
) -> None:
    w, h = source.size
    left_floor = source.crop((int(w * 0.06), int(h * 0.66), int(w * 0.18), int(h * 0.94)))
    right_floor = source.crop((int(w * 0.78), int(h * 0.64), int(w * 0.96), int(h * 0.92)))
    floor_source = _stitch_reference_patches(left_floor, right_floor, align="bottom")

    patch_size = (int(w * 0.56), int(h * 0.24))
    patch = floor_source.resize(patch_size, Image.Resampling.LANCZOS)
    patch = ImageEnhance.Brightness(patch).enhance(0.99)
    patch = ImageEnhance.Color(patch).enhance(0.82)
    patch = ImageEnhance.Contrast(patch).enhance(1.16)
    patch = patch.filter(ImageFilter.GaussianBlur(0.55)).convert("RGBA")

    x = int(w * 0.24)
    y = int(h * 0.61)
    alpha = ImageChops.multiply(
        subject_mask.crop((x, y, x + patch_size[0], y + patch_size[1])),
        _vertical_mask(patch_size, 148, 0.00, 0.96),
    )
    alpha = ImageChops.multiply(alpha, _soft_blob_mask(patch_size, 226, seed_offset=18))
    base.alpha_composite(
        Image.composite(
            patch,
            Image.new("RGBA", patch_size, (0, 0, 0, 0)),
            alpha,
        ),
        (x, y),
    )


def _add_center_floor_micro_detail(
    base: Image.Image,
    source: Image.Image,
    subject_mask: Image.Image,
) -> None:
    w, h = source.size
    left_floor = source.crop((int(w * 0.05), int(h * 0.69), int(w * 0.18), int(h * 0.94)))
    right_floor = source.crop((int(w * 0.76), int(h * 0.66), int(w * 0.97), int(h * 0.92)))
    detail_source = _stitch_reference_patches(left_floor, right_floor, align="bottom")

    patch_size = (int(w * 0.62), int(h * 0.22))
    patch = detail_source.resize(patch_size, Image.Resampling.LANCZOS)
    patch = ImageEnhance.Brightness(patch).enhance(0.98)
    patch = ImageEnhance.Color(patch).enhance(0.82)
    patch = ImageEnhance.Contrast(patch).enhance(1.24)
    patch = patch.filter(ImageFilter.UnsharpMask(radius=1.1, percent=62, threshold=4)).convert("RGBA")

    x = int(w * 0.22)
    y = int(h * 0.61)
    alpha = ImageChops.multiply(
        subject_mask.crop((x, y, x + patch_size[0], y + patch_size[1])),
        _vertical_mask(patch_size, 84, 0.08, 0.98),
    )
    alpha = ImageChops.multiply(alpha, _soft_blob_mask(patch_size, 220, seed_offset=26))
    base.alpha_composite(
        Image.composite(
            patch,
            Image.new("RGBA", patch_size, (0, 0, 0, 0)),
            alpha,
        ),
        (x, y),
    )


def _add_center_floor_caustic_mesh(
    base: Image.Image,
    source: Image.Image,
    subject_mask: Image.Image,
) -> None:
    w, h = source.size
    left_floor = source.crop((int(w * 0.05), int(h * 0.72), int(w * 0.18), int(h * 0.96)))
    right_floor = source.crop((int(w * 0.72), int(h * 0.70), int(w * 0.97), int(h * 0.94)))
    floor_source = _stitch_reference_patches(left_floor, right_floor, align="bottom")

    patch_size = (int(w * 0.58), int(h * 0.21))
    patch = floor_source.resize(patch_size, Image.Resampling.LANCZOS)
    patch = ImageEnhance.Brightness(patch).enhance(1.04)
    patch = ImageEnhance.Color(patch).enhance(0.86)
    patch = ImageEnhance.Contrast(patch).enhance(1.12)
    patch = patch.filter(ImageFilter.GaussianBlur(0.35)).convert("RGBA")

    x = int(w * 0.24)
    y = int(h * 0.64)
    patch_alpha = ImageChops.multiply(
        subject_mask.crop((x, y, x + patch_size[0], y + patch_size[1])),
        _vertical_mask(patch_size, 108, 0.06, 1.0),
    )
    patch_alpha = ImageChops.multiply(patch_alpha, _soft_blob_mask(patch_size, 210, seed_offset=38))
    base.alpha_composite(
        Image.composite(
            patch,
            Image.new("RGBA", patch_size, (0, 0, 0, 0)),
            patch_alpha,
        ),
        (x, y),
    )

    mesh = Image.new("RGBA", source.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(mesh, "RGBA")
    for index in range(34):
        row = index % 7
        col = index // 7
        start_x = w * (0.26 + col * 0.095 + (row % 2) * 0.018)
        start_y = h * (0.67 + row * 0.030)
        points: list[tuple[float, float]] = []
        for step in range(5):
            t = step / 4.0
            points.append(
                (
                    start_x + 98.0 * t,
                    start_y + math.sin(t * math.pi * 2.0 + index * 0.7) * (2.2 + (index % 3) * 0.6),
                )
            )
        draw.line(points, fill=(205, 249, 228, 34 if index % 3 else 46), width=1)
    for index in range(42):
        u = 0.26 + (index % 10) * 0.052
        v = 0.62 + (index // 10) * 0.054
        radius = 0.9 + (index % 4) * 0.35
        draw.ellipse(
            (w * u - radius, h * v - radius, w * u + radius, h * v + radius),
            outline=(214, 250, 240, 24),
            width=1,
        )

    mesh_alpha = ImageChops.multiply(
        subject_mask,
        _vertical_mask(source.size, 100, 0.50, 0.97),
    )
    base.alpha_composite(
        Image.composite(
            mesh,
            Image.new("RGBA", source.size, (0, 0, 0, 0)),
            mesh_alpha.filter(ImageFilter.GaussianBlur(1.0)),
        ),
        (0, 0),
    )


def _add_center_sand_channel(
    base: Image.Image,
    source: Image.Image,
    subject_mask: Image.Image,
) -> None:
    w, h = source.size
    left_sand = source.crop((int(w * 0.03), int(h * 0.73), int(w * 0.17), int(h * 0.98)))
    right_sand = source.crop((int(w * 0.79), int(h * 0.72), int(w * 0.97), int(h * 0.98)))
    sand_source = _stitch_reference_patches(left_sand, right_sand, align="bottom")

    patch_size = (int(w * 0.70), int(h * 0.26))
    patch = sand_source.resize(patch_size, Image.Resampling.LANCZOS)
    patch = ImageEnhance.Brightness(patch).enhance(1.08)
    patch = ImageEnhance.Color(patch).enhance(0.86)
    patch = ImageEnhance.Contrast(patch).enhance(1.18)
    patch = patch.filter(ImageFilter.GaussianBlur(0.42)).convert("RGBA")

    x = int(w * 0.17)
    y = int(h * 0.66)
    alpha = ImageChops.multiply(
        subject_mask.crop((x, y, x + patch_size[0], y + patch_size[1])),
        _vertical_mask(patch_size, 166, 0.04, 1.0),
    )
    alpha = ImageChops.multiply(alpha, _soft_blob_mask(patch_size, 236, seed_offset=20))
    base.alpha_composite(
        Image.composite(
            patch,
            Image.new("RGBA", patch_size, (0, 0, 0, 0)),
            alpha,
        ),
        (x, y),
    )


def _add_center_midwater_depth(
    base: Image.Image,
    source: Image.Image,
    subject_mask: Image.Image,
) -> None:
    w, h = source.size
    left_water = source.crop((int(w * 0.02), int(h * 0.34), int(w * 0.14), int(h * 0.64)))
    right_water = source.crop((int(w * 0.82), int(h * 0.34), int(w * 0.98), int(h * 0.64)))
    water_source = _stitch_reference_patches(left_water, right_water)

    patch_size = (int(w * 0.66), int(h * 0.28))
    patch = water_source.resize(patch_size, Image.Resampling.LANCZOS)
    patch = ImageEnhance.Brightness(patch).enhance(1.00)
    patch = ImageEnhance.Color(patch).enhance(0.90)
    patch = ImageEnhance.Contrast(patch).enhance(0.90)
    patch = patch.filter(ImageFilter.GaussianBlur(1.9)).convert("RGBA")

    x = int(w * 0.17)
    y = int(h * 0.39)
    alpha = ImageChops.multiply(
        subject_mask.crop((x, y, x + patch_size[0], y + patch_size[1])),
        _vertical_mask(patch_size, 28, 0.00, 0.96),
    )
    alpha = ImageChops.multiply(alpha, _soft_blob_mask(patch_size, 226, seed_offset=28))
    base.alpha_composite(
        Image.composite(
            patch,
            Image.new("RGBA", patch_size, (0, 0, 0, 0)),
            alpha,
        ),
        (x, y),
    )


def _add_center_band_breakup(
    base: Image.Image,
    source: Image.Image,
    subject_mask: Image.Image,
) -> None:
    w, h = source.size
    left_haze = source.crop((int(w * 0.02), int(h * 0.40), int(w * 0.14), int(h * 0.68)))
    right_haze = source.crop((int(w * 0.82), int(h * 0.38), int(w * 0.98), int(h * 0.66)))
    haze_source = _stitch_reference_patches(left_haze, right_haze)

    patch_size = (int(w * 0.68), int(h * 0.24))
    patch = haze_source.resize(patch_size, Image.Resampling.LANCZOS)
    patch = ImageEnhance.Brightness(patch).enhance(0.98)
    patch = ImageEnhance.Color(patch).enhance(0.90)
    patch = ImageEnhance.Contrast(patch).enhance(0.90)
    patch = patch.filter(ImageFilter.GaussianBlur(2.4)).convert("RGBA")

    x = int(w * 0.16)
    y = int(h * 0.43)
    alpha = ImageChops.multiply(
        subject_mask.crop((x, y, x + patch_size[0], y + patch_size[1])),
        _vertical_mask(patch_size, 22, 0.00, 0.98),
    )
    alpha = ImageChops.multiply(alpha, _soft_blob_mask(patch_size, 214, seed_offset=32))
    base.alpha_composite(
        Image.composite(
            patch,
            Image.new("RGBA", patch_size, (0, 0, 0, 0)),
            alpha,
        ),
        (x, y),
    )


def _add_center_midwater_light_glaze(
    base: Image.Image,
    source: Image.Image,
    subject_mask: Image.Image,
) -> None:
    w, h = source.size
    upper_left = source.crop((int(w * 0.05), int(h * 0.06), int(w * 0.15), int(h * 0.36)))
    upper_right = source.crop((int(w * 0.70), int(h * 0.06), int(w * 0.97), int(h * 0.34)))
    light_source = _stitch_reference_patches(upper_left, upper_right)

    patch_size = (int(w * 0.64), int(h * 0.36))
    patch = light_source.resize(patch_size, Image.Resampling.LANCZOS)
    patch = ImageEnhance.Brightness(patch).enhance(1.32)
    patch = ImageEnhance.Color(patch).enhance(0.96)
    patch = ImageEnhance.Contrast(patch).enhance(0.82)
    patch = patch.filter(ImageFilter.GaussianBlur(1.8)).convert("RGBA")

    x = int(w * 0.18)
    y = int(h * 0.18)
    alpha = ImageChops.multiply(
        subject_mask.crop((x, y, x + patch_size[0], y + patch_size[1])),
        _vertical_mask(patch_size, 132, 0.00, 0.96),
    )
    alpha = ImageChops.multiply(alpha, _soft_blob_mask(patch_size, 220, seed_offset=34))
    base.alpha_composite(
        Image.composite(
            patch,
            Image.new("RGBA", patch_size, (0, 0, 0, 0)),
            alpha,
        ),
        (x, y),
    )


def _add_center_surface_ray_detail(
    base: Image.Image,
    source: Image.Image,
    subject_mask: Image.Image,
) -> None:
    w, h = source.size
    rays = Image.new("RGBA", source.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(rays, "RGBA")

    # These are raster light accents behind the runtime fish. They use only
    # the subject mask, so they cannot reintroduce the reference fish, line, or
    # hit text, but they keep the center from reading as one dark replacement band.
    for index, (x0, x1, x2, x3, alpha) in enumerate(
        (
            (0.25, 0.31, 0.37, 0.32, 30),
            (0.34, 0.41, 0.50, 0.45, 38),
            (0.47, 0.54, 0.62, 0.57, 34),
            (0.58, 0.64, 0.71, 0.67, 27),
        )
    ):
        bottom = h * (0.60 + index * 0.018)
        draw.polygon(
            (
                (w * x0, 0.0),
                (w * x1, 0.0),
                (w * x2, bottom),
                (w * x3, bottom),
            ),
            fill=(176, 239, 248, alpha),
        )

    for index in range(72):
        col = index % 12
        row = index // 12
        u = 0.24 + col * 0.046 + (row % 2) * 0.014
        v = 0.14 + row * 0.058 + math.sin(index * 1.31) * 0.010
        radius = 0.8 + (index % 4) * 0.42
        alpha = 28 + (index % 5) * 5
        draw.ellipse(
            (
                w * u - radius,
                h * v - radius,
                w * u + radius,
                h * v + radius,
            ),
            fill=(218, 249, 255, alpha),
        )

    ray_mask = ImageChops.multiply(
        subject_mask,
        _vertical_mask(source.size, 118, 0.00, 0.72),
    )
    ray_mask = ImageChops.multiply(ray_mask, _soft_blob_mask(source.size, 214, seed_offset=42))
    base.alpha_composite(
        Image.composite(
            rays.filter(ImageFilter.GaussianBlur(7.0)),
            Image.new("RGBA", source.size, (0, 0, 0, 0)),
            ray_mask,
        ),
        (0, 0),
    )


def _add_center_clear_water_glaze(
    base: Image.Image,
    source: Image.Image,
    subject_mask: Image.Image,
) -> None:
    w, h = source.size
    glaze = Image.new("RGBA", source.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(glaze, "RGBA")

    draw.ellipse(
        (int(w * 0.14), int(h * 0.10), int(w * 0.84), int(h * 0.70)),
        fill=(28, 145, 184, 54),
    )
    draw.ellipse(
        (int(w * 0.24), -int(h * 0.08), int(w * 0.72), int(h * 0.34)),
        fill=(132, 226, 244, 32),
    )
    draw.rectangle(
        (int(w * 0.20), int(h * 0.30), int(w * 0.80), int(h * 0.58)),
        fill=(12, 116, 166, 22),
    )
    draw.ellipse(
        (int(w * 0.20), int(h * 0.54), int(w * 0.82), int(h * 0.93)),
        fill=(82, 177, 176, 30),
    )

    for index in range(6):
        x = w * (0.24 + index * 0.085)
        draw.polygon(
            (
                (x, 0),
                (x + w * 0.040, 0),
                (x + w * 0.105, h * 0.64),
                (x + w * 0.050, h * 0.64),
            ),
            fill=(158, 236, 247, 16 if index % 2 else 22),
        )

    alpha = ImageChops.multiply(
        subject_mask,
        _vertical_mask(source.size, 132, 0.00, 0.95),
    )
    alpha = ImageChops.multiply(alpha, _soft_blob_mask(source.size, 226, seed_offset=48))
    base.alpha_composite(
        Image.composite(
            glaze.filter(ImageFilter.GaussianBlur(18.0)),
            Image.new("RGBA", source.size, (0, 0, 0, 0)),
            alpha,
        ),
        (0, 0),
    )


def _add_center_final_paintover(
    base: Image.Image,
    source: Image.Image,
    subject_mask: Image.Image,
) -> None:
    w, h = source.size

    lift_mask = ImageChops.multiply(
        subject_mask,
        _vertical_mask(source.size, 158, 0.08, 0.74),
    )
    lift_mask = ImageChops.multiply(lift_mask, _soft_blob_mask(source.size, 218, seed_offset=54))
    lifted = ImageEnhance.Brightness(base.convert("RGB")).enhance(1.42)
    lifted = ImageEnhance.Color(lifted).enhance(1.04)
    lifted = ImageEnhance.Contrast(lifted).enhance(0.92).convert("RGBA")
    base.alpha_composite(
        Image.composite(
            lifted,
            Image.new("RGBA", source.size, (0, 0, 0, 0)),
            lift_mask,
        ),
        (0, 0),
    )

    left_floor = source.crop((int(w * 0.04), int(h * 0.70), int(w * 0.18), int(h * 0.96)))
    right_floor = source.crop((int(w * 0.78), int(h * 0.68), int(w * 0.98), int(h * 0.94)))
    floor_source = _stitch_reference_patches(left_floor, right_floor, align="bottom")
    floor_size = (int(w * 0.66), int(h * 0.24))
    floor_patch = floor_source.resize(floor_size, Image.Resampling.LANCZOS)
    floor_patch = ImageEnhance.Brightness(floor_patch).enhance(1.18)
    floor_patch = ImageEnhance.Color(floor_patch).enhance(0.92)
    floor_patch = ImageEnhance.Contrast(floor_patch).enhance(1.08)
    floor_patch = floor_patch.filter(ImageFilter.GaussianBlur(0.5)).convert("RGBA")

    floor_x = int(w * 0.19)
    floor_y = int(h * 0.60)
    floor_alpha = ImageChops.multiply(
        subject_mask.crop((floor_x, floor_y, floor_x + floor_size[0], floor_y + floor_size[1])),
        _vertical_mask(floor_size, 132, 0.05, 1.0),
    )
    floor_alpha = ImageChops.multiply(floor_alpha, _soft_blob_mask(floor_size, 224, seed_offset=56))
    base.alpha_composite(
        Image.composite(
            floor_patch,
            Image.new("RGBA", floor_size, (0, 0, 0, 0)),
            floor_alpha,
        ),
        (floor_x, floor_y),
    )

    paint = Image.new("RGBA", source.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(paint, "RGBA")
    draw.ellipse(
        (int(w * 0.12), int(h * 0.14), int(w * 0.84), int(h * 0.62)),
        fill=(45, 164, 195, 58),
    )
    draw.ellipse(
        (int(w * 0.22), int(h * 0.48), int(w * 0.82), int(h * 0.90)),
        fill=(102, 188, 178, 38),
    )
    draw.rectangle(
        (int(w * 0.20), int(h * 0.38), int(w * 0.80), int(h * 0.56)),
        fill=(40, 153, 186, 22),
    )
    for index, (x0, x1, x2, x3, alpha) in enumerate(
        (
            (0.26, 0.31, 0.36, 0.31, 26),
            (0.36, 0.42, 0.50, 0.45, 32),
            (0.48, 0.54, 0.61, 0.56, 28),
            (0.58, 0.64, 0.70, 0.66, 22),
        )
    ):
        draw.polygon(
            (
                (w * x0, 0.0),
                (w * x1, 0.0),
                (w * x2, h * (0.70 + index * 0.012)),
                (w * x3, h * (0.70 + index * 0.012)),
            ),
            fill=(178, 236, 242, alpha),
        )

    for index in range(38):
        row = index % 7
        col = index // 7
        x = w * (0.23 + col * 0.095 + (row % 2) * 0.014)
        y = h * (0.66 + row * 0.032)
        points: list[tuple[float, float]] = []
        for step in range(6):
            t = step / 5.0
            points.append(
                (
                    x + 126.0 * t,
                    y + math.sin(t * math.pi * 2.0 + index * 0.63) * (2.0 + (index % 3) * 0.7),
                )
            )
        draw.line(points, fill=(211, 250, 230, 44 if index % 4 == 0 else 31), width=1)

    for index in range(142):
        col = index % 17
        row = index // 17
        u = 0.22 + col * 0.036 + (row % 2) * 0.012
        v = 0.18 + row * 0.052 + math.sin(index * 1.13) * 0.009
        radius = 0.8 + (index % 5) * 0.38
        draw.ellipse(
            (
                w * u - radius,
                h * v - radius,
                w * u + radius,
                h * v + radius,
            ),
            outline=(213, 248, 250, 24 if index % 3 else 38),
            width=1,
        )

    alpha = ImageChops.multiply(
        subject_mask,
        _vertical_mask(source.size, 150, 0.04, 0.96),
    )
    alpha = ImageChops.multiply(alpha, _soft_blob_mask(source.size, 218, seed_offset=58))
    base.alpha_composite(
        Image.composite(
            paint.filter(ImageFilter.GaussianBlur(7.0)),
            Image.new("RGBA", source.size, (0, 0, 0, 0)),
            alpha,
        ),
        (0, 0),
    )


def _add_center_water_texture(
    clean: Image.Image,
    source: Image.Image,
    subject_mask: Image.Image,
) -> Image.Image:
    base = clean.convert("RGBA")
    w, h = source.size

    # Reuse the reference's own seabed and water pixels to break up the clean
    # fill inside the removed fish/hit area. This stays in the target art
    # language while keeping the runtime fish zone visually quiet.
    left_floor = source.crop((int(w * 0.02), int(h * 0.69), int(w * 0.17), h))
    right_floor = source.crop((int(w * 0.76), int(h * 0.66), int(w * 0.98), h))
    floor_source = _stitch_reference_patches(left_floor, right_floor, align="bottom")
    seabed_patch = floor_source.resize(
        (int(w * 0.72), int(h * 0.30)),
        Image.Resampling.LANCZOS,
    )
    seabed_patch = ImageEnhance.Brightness(seabed_patch).enhance(0.90)
    seabed_patch = ImageEnhance.Color(seabed_patch).enhance(0.86)
    seabed_patch = ImageEnhance.Contrast(seabed_patch).enhance(1.00)

    seabed_alpha = ImageChops.multiply(
        subject_mask.crop(
            (int(w * 0.16), int(h * 0.66), int(w * 0.88), int(h * 0.96)),
        ).resize(
            seabed_patch.size,
            Image.Resampling.LANCZOS,
        ),
        _vertical_mask(seabed_patch.size, 92, 0.18, 0.98),
    )
    seabed_alpha = ImageChops.multiply(
        seabed_alpha,
        _soft_blob_mask(seabed_patch.size, 225, seed_offset=4),
    )
    base.alpha_composite(
        Image.composite(
            seabed_patch.convert("RGBA"),
            Image.new("RGBA", seabed_patch.size, (0, 0, 0, 0)),
            seabed_alpha,
        ),
        (int(w * 0.16), int(h * 0.66)),
    )

    _add_center_midwater_depth(base, source, subject_mask)
    _add_center_band_breakup(base, source, subject_mask)
    _add_center_midwater_light_glaze(base, source, subject_mask)
    _add_center_surface_ray_detail(base, source, subject_mask)
    _add_center_seabed_shelf(base, source, subject_mask)
    _add_center_sand_channel(base, source, subject_mask)
    _add_center_floor_glints(base, source, subject_mask)
    _add_center_floor_micro_detail(base, source, subject_mask)
    _add_center_floor_caustic_mesh(base, source, subject_mask)

    floor_fragments = (
        (source.crop((int(w * 0.08), int(h * 0.74), int(w * 0.18), int(h * 0.92))), 0.33, 0.79, 0.24, 0.11, 22),
        (source.crop((int(w * 0.78), int(h * 0.72), int(w * 0.96), int(h * 0.92))), 0.49, 0.82, 0.21, 0.10, 18),
        (source.crop((int(w * 0.82), int(h * 0.78), int(w * 0.98), int(h * 0.94))), 0.61, 0.83, 0.19, 0.09, 16),
    )
    for fragment, u, v, patch_w_ratio, patch_h_ratio, alpha in floor_fragments:
        patch_size = (int(w * patch_w_ratio), int(h * patch_h_ratio))
        patch = fragment.resize(patch_size, Image.Resampling.LANCZOS)
        patch = ImageEnhance.Brightness(patch).enhance(0.90)
        patch = ImageEnhance.Color(patch).enhance(0.82)
        patch = ImageEnhance.Contrast(patch).enhance(0.92)
        patch = patch.filter(ImageFilter.GaussianBlur(0.8)).convert("RGBA")

        local_mask = Image.new("L", patch_size, 0)
        local_draw = ImageDraw.Draw(local_mask)
        local_draw.ellipse(
            (
                int(patch_size[0] * 0.04),
                int(patch_size[1] * 0.18),
                int(patch_size[0] * 0.96),
                int(patch_size[1] * 0.98),
            ),
            fill=alpha,
        )
        local_mask = ImageChops.multiply(
            local_mask,
            _vertical_mask(patch_size, 255, 0.28, 1.0),
        )
        local_mask = local_mask.filter(ImageFilter.GaussianBlur(18.0))
        x = int(w * u - patch_size[0] * 0.5)
        y = int(h * v - patch_size[1] * 0.5)
        subject_crop = subject_mask.crop((x, y, x + patch_size[0], y + patch_size[1]))
        fragment_alpha = ImageChops.multiply(local_mask, subject_crop)
        base.alpha_composite(
            Image.composite(
                patch,
                Image.new("RGBA", patch_size, (0, 0, 0, 0)),
                fragment_alpha,
            ),
            (x, y),
        )

    reef_fragments = (
        (source.crop((int(w * 0.04), int(h * 0.58), int(w * 0.16), int(h * 0.88))), 0.36, 0.70, 0.28, 0.22, 12),
        (source.crop((int(w * 0.82), int(h * 0.48), int(w * 0.98), int(h * 0.78))), 0.49, 0.61, 0.34, 0.24, 14),
        (source.crop((int(w * 0.78), int(h * 0.54), int(w * 0.98), int(h * 0.86))), 0.57, 0.68, 0.30, 0.23, 11),
        (source.crop((int(w * 0.82), int(h * 0.70), int(w * 0.98), int(h * 0.94))), 0.49, 0.82, 0.27, 0.14, 12),
    )
    for index, (fragment, u, v, patch_w_ratio, patch_h_ratio, alpha) in enumerate(reef_fragments):
        patch_size = (int(w * patch_w_ratio), int(h * patch_h_ratio))
        patch = fragment.resize(patch_size, Image.Resampling.LANCZOS)
        patch = ImageEnhance.Brightness(patch).enhance(0.78)
        patch = ImageEnhance.Color(patch).enhance(0.76)
        patch = ImageEnhance.Contrast(patch).enhance(0.82)
        patch = patch.filter(ImageFilter.GaussianBlur(2.4)).convert("RGBA")
        patch_alpha = ImageChops.multiply(
            _soft_blob_mask(patch_size, alpha, seed_offset=index * 2),
            _vertical_mask(patch_size, 210, 0.00, 1.0),
        )
        x = int(w * u - patch_size[0] * 0.5)
        y = int(h * v - patch_size[1] * 0.5)
        subject_crop = subject_mask.crop((x, y, x + patch_size[0], y + patch_size[1]))
        patch_alpha = ImageChops.multiply(patch_alpha, subject_crop)
        base.alpha_composite(
            Image.composite(
                patch,
                Image.new("RGBA", patch_size, (0, 0, 0, 0)),
                patch_alpha,
            ),
            (x, y),
        )

    left_water = source.crop((int(w * 0.02), int(h * 0.18), int(w * 0.14), int(h * 0.56)))
    right_water = source.crop((int(w * 0.82), int(h * 0.18), int(w * 0.98), int(h * 0.56)))
    mid_source = _stitch_reference_patches(left_water, right_water)
    mid_patch = mid_source.resize((int(w * 0.60), int(h * 0.36)), Image.Resampling.LANCZOS)
    mid_patch = ImageEnhance.Brightness(mid_patch).enhance(1.04)
    mid_patch = ImageEnhance.Color(mid_patch).enhance(0.92)
    mid_patch = ImageEnhance.Contrast(mid_patch).enhance(0.90)
    mid_patch = mid_patch.filter(ImageFilter.GaussianBlur(0.28))

    mid_alpha = ImageChops.multiply(
        subject_mask.crop((int(w * 0.20), int(h * 0.20), int(w * 0.80), int(h * 0.56))).resize(
            mid_patch.size,
            Image.Resampling.LANCZOS,
        ),
        _vertical_mask(mid_patch.size, 70, 0.00, 0.86),
    )
    mid_alpha = ImageChops.multiply(
        mid_alpha,
        _soft_blob_mask(mid_patch.size, 218, seed_offset=0),
    )
    base.alpha_composite(
        Image.composite(
            mid_patch.convert("RGBA"),
            Image.new("RGBA", mid_patch.size, (0, 0, 0, 0)),
            mid_alpha,
        ),
        (int(w * 0.20), int(h * 0.20)),
    )

    _add_center_clear_water_glaze(base, source, subject_mask)
    _add_reference_school_texture(base, source, subject_mask)
    _add_distant_fish_layer(base, source, subject_mask)
    _add_midwater_bubble_texture(base, source, subject_mask)

    surface_light = source.crop((int(w * 0.08), 0, int(w * 0.94), int(h * 0.22)))
    light_patch_size = (int(w * 0.72), int(h * 0.46))
    light_patch = surface_light.resize(light_patch_size, Image.Resampling.LANCZOS)
    light_patch = ImageEnhance.Brightness(light_patch).enhance(0.98)
    light_patch = ImageEnhance.Color(light_patch).enhance(0.92)
    light_patch = ImageEnhance.Contrast(light_patch).enhance(1.08)
    light_patch = light_patch.filter(ImageFilter.GaussianBlur(0.55)).convert("RGBA")

    light_x = int(w * 0.17)
    light_y = int(h * 0.08)
    light_alpha = ImageChops.multiply(
        subject_mask.crop((light_x, light_y, light_x + light_patch_size[0], light_y + light_patch_size[1])),
        _vertical_mask(light_patch_size, 58, 0.00, 0.92),
    )
    base.alpha_composite(
        Image.composite(
            light_patch,
            Image.new("RGBA", light_patch_size, (0, 0, 0, 0)),
            light_alpha,
        ),
        (light_x, light_y),
    )

    caustics = Image.new("RGBA", source.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(caustics, "RGBA")
    for index, (x0, x1, x2, x3, alpha) in enumerate(
        (
            (0.20, 0.25, 0.35, 0.30, 26),
            (0.29, 0.34, 0.46, 0.40, 32),
            (0.39, 0.45, 0.58, 0.50, 29),
            (0.52, 0.58, 0.68, 0.62, 24),
            (0.64, 0.69, 0.75, 0.70, 19),
        )
    ):
        ray = (
            (w * x0, h * 0.06),
            (w * x1, h * 0.06),
            (w * x2, h * (0.62 + index * 0.025)),
            (w * x3, h * (0.62 + index * 0.025)),
        )
        draw.polygon(ray, fill=(150, 223, 238, alpha))
    for index in range(28):
        y = h * (0.60 + (index % 7) * 0.045)
        x = w * (0.22 + (index // 7) * 0.13)
        points: list[tuple[float, float]] = []
        for step in range(5):
            t = step / 4.0
            points.append(
                (x + 112.0 * t, y + ((step % 2) * 2.0 - 1.0) * (3.0 + index % 3)),
            )
        draw.line(points, fill=(185, 236, 220, 40), width=1)
    for index in range(18):
        y = h * (0.66 + (index % 6) * 0.038)
        x = w * (0.31 + (index // 6) * 0.13)
        points = []
        for step in range(6):
            t = step / 5.0
            points.append(
                (x + 150.0 * t, y + ((step % 2) * 2.0 - 1.0) * (2.5 + index % 2)),
            )
        draw.line(points, fill=(209, 249, 232, 32), width=1)
    for index in range(54):
        u = 0.23 + (index % 9) * 0.057 + ((index // 9) % 2) * 0.018
        v = 0.24 + (index // 9) * 0.070
        radius = 1.3 + (index % 3) * 0.6
        alpha = 30 if index % 4 else 46
        draw.ellipse(
            (
                w * u - radius,
                h * v - radius,
                w * u + radius,
                h * v + radius,
            ),
            outline=(194, 238, 245, alpha),
            width=1,
        )

    caustic_mask = ImageChops.multiply(
        subject_mask,
        _vertical_mask(source.size, 112, 0.02, 0.94),
    )
    base.alpha_composite(
        Image.composite(
            caustics,
            Image.new("RGBA", source.size, (0, 0, 0, 0)),
            caustic_mask,
        ),
        (0, 0),
    )
    _add_center_final_paintover(base, source, subject_mask)
    return base.convert("RGB")


def _remove_full_window_subjects(crop: Image.Image) -> Image.Image:
    mask = _make_full_window_subject_mask(crop.size)
    clean = Image.composite(_make_water_fill(crop.size), crop.convert("RGB"), mask)
    clean = _add_center_water_texture(clean, crop.convert("RGB"), mask)

    # A soft blue veil hides the boundary between authored reef pixels and the
    # clean center water while leaving the edges detailed.
    w, h = crop.size
    veil = Image.new("RGBA", crop.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(veil, "RGBA")
    draw.ellipse((int(w * 0.18), int(h * 0.08), int(w * 0.78), int(h * 0.75)), fill=(22, 148, 191, 12))
    clean_rgba = clean.convert("RGBA")
    clean_rgba.alpha_composite(veil.filter(ImageFilter.GaussianBlur(30.0)))
    return clean_rgba.convert("RGB")


def _expand_to_canvas(image: Image.Image) -> Image.Image:
    # Reference water window is wider than the runtime texture. Fit by height
    # and crop horizontally; this keeps the authored seabed and light scale.
    scale = CANVAS_SIZE[1] / image.height
    scaled_size = (round(image.width * scale), CANVAS_SIZE[1])
    scaled = image.resize(scaled_size, Image.Resampling.LANCZOS)
    left = max(0, (scaled.width - CANVAS_SIZE[0]) // 2)
    return scaled.crop((left, 0, left + CANVAS_SIZE[0], CANVAS_SIZE[1]))


def _harmonize(image: Image.Image) -> Image.Image:
    # The reference crop has UI-adjacent compression and sharp paint edges.
    # Gentle smoothing plus a cool depth glaze makes it function as a clean
    # reusable background under the runtime fish and HUD.
    image = ImageEnhance.Color(image).enhance(0.96)
    image = ImageEnhance.Contrast(image).enhance(1.04)
    softened = image.filter(ImageFilter.GaussianBlur(0.38))
    image = Image.blend(image, softened, 0.18)

    overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay, "RGBA")
    w, h = image.size
    draw.rectangle((0, 0, w, int(h * 0.10)), fill=(0, 20, 42, 14))
    draw.rectangle((0, int(h * 0.78), w, h), fill=(0, 28, 42, 12))
    draw.rectangle((0, 0, int(w * 0.12), h), fill=(0, 20, 38, 18))
    draw.rectangle((int(w * 0.88), 0, w, h), fill=(0, 20, 38, 18))
    image = image.convert("RGBA")
    image.alpha_composite(overlay.filter(ImageFilter.GaussianBlur(28)))
    return image.convert("RGB")


def _add_generated_canvas_paintover(image: Image.Image, crop_subject_mask: Image.Image) -> Image.Image:
    if not GENERATED_CENTER_PAINTOVER.exists():
        return image

    candidate = Image.open(GENERATED_CENTER_PAINTOVER).convert("RGB")
    if candidate.size != CANVAS_SIZE:
        candidate = candidate.resize(CANVAS_SIZE, Image.Resampling.LANCZOS)

    candidate = ImageEnhance.Brightness(candidate).enhance(1.30)
    candidate = ImageEnhance.Color(candidate).enhance(0.94)
    candidate = ImageEnhance.Contrast(candidate).enhance(0.96)
    candidate = candidate.filter(ImageFilter.GaussianBlur(0.4)).convert("RGBA")

    w, h = CANVAS_SIZE

    broad_center = Image.new("L", CANVAS_SIZE, 0)
    draw = ImageDraw.Draw(broad_center)
    draw.ellipse((int(w * 0.08), int(h * 0.02), int(w * 0.90), int(h * 0.96)), fill=236)
    draw.rectangle((int(w * 0.16), int(h * 0.20), int(w * 0.84), int(h * 0.88)), fill=252)
    broad_center = broad_center.filter(ImageFilter.GaussianBlur(56.0))
    broad_center = ImageChops.multiply(broad_center, _vertical_mask(CANVAS_SIZE, 250, 0.02, 0.98))
    broad_center = ImageChops.multiply(broad_center, _soft_blob_mask(CANVAS_SIZE, 250, seed_offset=62))

    subject_mask = _expand_to_canvas(crop_subject_mask).convert("L")
    center_gate = Image.new("L", CANVAS_SIZE, 0)
    draw = ImageDraw.Draw(center_gate)
    draw.ellipse((int(w * 0.13), int(h * 0.08), int(w * 0.86), int(h * 0.93)), fill=236)
    draw.rectangle((int(w * 0.20), int(h * 0.50), int(w * 0.82), int(h * 0.90)), fill=255)
    center_gate = center_gate.filter(ImageFilter.GaussianBlur(42.0))
    subject_mask = ImageChops.multiply(subject_mask, center_gate)
    subject_mask = ImageChops.multiply(subject_mask, _vertical_mask(CANVAS_SIZE, 255, 0.08, 0.98))
    subject_mask = ImageChops.multiply(subject_mask, _soft_blob_mask(CANVAS_SIZE, 255, seed_offset=64))
    mask = ImageChops.lighter(broad_center, subject_mask)

    result = image.convert("RGBA")
    result.alpha_composite(
        Image.composite(
            candidate,
            Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0)),
            mask,
        ),
        (0, 0),
    )
    return result.convert("RGB")


def _add_canvas_center_floor_lift(image: Image.Image, crop_subject_mask: Image.Image) -> Image.Image:
    if not GENERATED_CENTER_PAINTOVER.exists():
        return image

    candidate = Image.open(GENERATED_CENTER_PAINTOVER).convert("RGB")
    if candidate.size != CANVAS_SIZE:
        candidate = candidate.resize(CANVAS_SIZE, Image.Resampling.LANCZOS)

    candidate = ImageEnhance.Brightness(candidate).enhance(1.40)
    candidate = ImageEnhance.Color(candidate).enhance(0.98)
    candidate = ImageEnhance.Contrast(candidate).enhance(1.08)
    candidate = candidate.filter(ImageFilter.GaussianBlur(0.18)).convert("RGBA")

    w, h = CANVAS_SIZE
    result = image.convert("RGBA")

    floor_gate = Image.new("L", CANVAS_SIZE, 0)
    draw = ImageDraw.Draw(floor_gate)
    draw.ellipse((int(w * 0.18), int(h * 0.43), int(w * 0.86), int(h * 0.95)), fill=214)
    draw.rectangle((int(w * 0.24), int(h * 0.58), int(w * 0.82), int(h * 0.88)), fill=244)
    floor_gate = floor_gate.filter(ImageFilter.GaussianBlur(54.0))
    floor_gate = ImageChops.multiply(floor_gate, _vertical_mask(CANVAS_SIZE, 255, 0.38, 0.98))
    floor_gate = ImageChops.multiply(floor_gate, _soft_blob_mask(CANVAS_SIZE, 250, seed_offset=70))

    subject_mask = _expand_to_canvas(crop_subject_mask).convert("L")
    subject_gate = Image.new("L", CANVAS_SIZE, 0)
    draw = ImageDraw.Draw(subject_gate)
    draw.ellipse((int(w * 0.14), int(h * 0.14), int(w * 0.84), int(h * 0.88)), fill=236)
    draw.rectangle((int(w * 0.18), int(h * 0.48), int(w * 0.80), int(h * 0.88)), fill=255)
    subject_gate = subject_gate.filter(ImageFilter.GaussianBlur(38.0))
    subject_mask = ImageChops.multiply(subject_mask, subject_gate)
    subject_mask = ImageChops.multiply(subject_mask, _vertical_mask(CANVAS_SIZE, 255, 0.16, 0.98))
    subject_mask = ImageChops.multiply(subject_mask, _soft_blob_mask(CANVAS_SIZE, 255, seed_offset=72))

    mask = ImageChops.lighter(floor_gate, subject_mask)
    result.alpha_composite(
        Image.composite(
            candidate,
            Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0)),
            mask,
        ),
        (0, 0),
    )
    return result.convert("RGB")


def _add_canvas_reference_light_polish(
    image: Image.Image,
    reference_crop: Image.Image,
    crop_subject_mask: Image.Image,
) -> Image.Image:
    source = _expand_to_canvas(reference_crop.convert("RGB"))
    subject_mask = _expand_to_canvas(crop_subject_mask).convert("L")
    result = image.convert("RGBA")
    w, h = CANVAS_SIZE

    upper_left = source.crop((int(w * 0.06), int(h * 0.02), int(w * 0.18), int(h * 0.34)))
    upper_right = source.crop((int(w * 0.70), int(h * 0.02), int(w * 0.96), int(h * 0.34)))
    light_source = _stitch_reference_patches(upper_left, upper_right)
    light_size = (int(w * 0.70), int(h * 0.50))
    light_patch = light_source.resize(light_size, Image.Resampling.LANCZOS)
    light_patch = ImageEnhance.Brightness(light_patch).enhance(1.20)
    light_patch = ImageEnhance.Color(light_patch).enhance(0.96)
    light_patch = ImageEnhance.Contrast(light_patch).enhance(0.88)
    light_patch = light_patch.filter(ImageFilter.GaussianBlur(1.0)).convert("RGBA")

    light_x = int(w * 0.15)
    light_y = int(h * 0.03)
    light_gate = Image.new("L", light_size, 0)
    light_draw = ImageDraw.Draw(light_gate)
    light_draw.ellipse(
        (
            int(light_size[0] * 0.02),
            int(light_size[1] * -0.08),
            int(light_size[0] * 0.98),
            int(light_size[1] * 0.96),
        ),
        fill=150,
    )
    light_gate = light_gate.filter(ImageFilter.GaussianBlur(30.0))
    light_alpha = ImageChops.multiply(
        subject_mask.crop((light_x, light_y, light_x + light_size[0], light_y + light_size[1])),
        _vertical_mask(light_size, 118, 0.00, 0.86),
    )
    light_alpha = ImageChops.multiply(light_alpha, light_gate)
    light_alpha = ImageChops.multiply(light_alpha, _soft_blob_mask(light_size, 232, seed_offset=74))
    result.alpha_composite(
        Image.composite(
            light_patch,
            Image.new("RGBA", light_size, (0, 0, 0, 0)),
            light_alpha,
        ),
        (light_x, light_y),
    )

    rays = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    ray_draw = ImageDraw.Draw(rays, "RGBA")
    ray_specs = [
        (0.25, 0.34, 0.18, 0.50, 28),
        (0.34, 0.45, 0.27, 0.62, 34),
        (0.47, 0.56, 0.39, 0.70, 26),
        (0.59, 0.69, 0.50, 0.75, 20),
    ]
    for left, right, bottom_left, bottom_right, alpha in ray_specs:
        ray_draw.polygon(
            [
                (w * left, h * 0.00),
                (w * right, h * 0.00),
                (w * bottom_right, h * 0.58),
                (w * bottom_left, h * 0.58),
            ],
            fill=(130, 226, 255, alpha),
        )
    for index in range(28):
        x = w * (0.16 + (index % 14) * 0.045)
        y = h * (0.035 + (index // 14) * 0.048 + math.sin(index * 1.7) * 0.006)
        ray_draw.line(
            [
                (x, y),
                (x + w * 0.040, y + math.sin(index * 0.61) * h * 0.006),
                (x + w * 0.095, y + math.sin(index * 0.77) * h * 0.010),
            ],
            fill=(226, 255, 248, 34 if index % 5 else 46),
            width=1,
        )
    ray_gate = Image.new("L", CANVAS_SIZE, 0)
    ray_gate_draw = ImageDraw.Draw(ray_gate)
    ray_gate_draw.ellipse((int(w * 0.10), int(h * -0.06), int(w * 0.84), int(h * 0.70)), fill=186)
    ray_gate = ray_gate.filter(ImageFilter.GaussianBlur(36.0))
    broad_ray = Image.new("L", CANVAS_SIZE, 0)
    broad_ray_draw = ImageDraw.Draw(broad_ray)
    broad_ray_draw.ellipse((int(w * 0.14), int(h * -0.10), int(w * 0.80), int(h * 0.64)), fill=168)
    broad_ray_draw.rectangle((int(w * 0.20), 0, int(w * 0.70), int(h * 0.32)), fill=190)
    broad_ray = broad_ray.filter(ImageFilter.GaussianBlur(48.0))
    ray_alpha = ImageChops.lighter(subject_mask, broad_ray)
    ray_alpha = ImageChops.multiply(ray_alpha, _vertical_mask(CANVAS_SIZE, 106, 0.00, 0.66))
    ray_alpha = ImageChops.multiply(ray_alpha, ray_gate)
    result.alpha_composite(
        Image.composite(
            rays.filter(ImageFilter.GaussianBlur(8.0)),
            Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0)),
            ray_alpha,
        ),
        (0, 0),
    )

    left_floor = source.crop((int(w * 0.05), int(h * 0.70), int(w * 0.18), int(h * 0.96)))
    right_floor = source.crop((int(w * 0.78), int(h * 0.68), int(w * 0.98), int(h * 0.94)))
    floor_source = _stitch_reference_patches(left_floor, right_floor, align="bottom")
    floor_size = (int(w * 0.66), int(h * 0.25))
    floor_patch = floor_source.resize(floor_size, Image.Resampling.LANCZOS)
    floor_patch = ImageEnhance.Brightness(floor_patch).enhance(1.16)
    floor_patch = ImageEnhance.Color(floor_patch).enhance(0.92)
    floor_patch = ImageEnhance.Contrast(floor_patch).enhance(1.18)
    floor_patch = floor_patch.filter(ImageFilter.UnsharpMask(radius=1.1, percent=42, threshold=3)).convert("RGBA")

    floor_x = int(w * 0.20)
    floor_y = int(h * 0.58)
    floor_gate = Image.new("L", floor_size, 0)
    floor_draw = ImageDraw.Draw(floor_gate)
    floor_draw.ellipse(
        (
            int(floor_size[0] * 0.00),
            int(floor_size[1] * 0.06),
            int(floor_size[0] * 1.00),
            int(floor_size[1] * 1.08),
        ),
        fill=132,
    )
    floor_gate = floor_gate.filter(ImageFilter.GaussianBlur(24.0))
    floor_alpha = ImageChops.multiply(
        subject_mask.crop((floor_x, floor_y, floor_x + floor_size[0], floor_y + floor_size[1])),
        _vertical_mask(floor_size, 132, 0.10, 1.0),
    )
    floor_alpha = ImageChops.multiply(floor_alpha, floor_gate)
    floor_alpha = ImageChops.multiply(floor_alpha, _soft_blob_mask(floor_size, 226, seed_offset=76))
    result.alpha_composite(
        Image.composite(
            floor_patch,
            Image.new("RGBA", floor_size, (0, 0, 0, 0)),
            floor_alpha,
        ),
        (floor_x, floor_y),
    )

    strokes = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    stroke_draw = ImageDraw.Draw(strokes, "RGBA")
    for index in range(72):
        row = index % 9
        col = index // 9
        x = w * (0.22 + col * 0.074 + (row % 2) * 0.018)
        y = h * (0.57 + row * 0.028)
        points: list[tuple[float, float]] = []
        for step in range(6):
            t = step / 5.0
            points.append(
                (
                    x + 132.0 * t,
                    y + math.sin(t * math.tau + index * 0.52) * (2.1 + (index % 4) * 0.50),
                )
            )
        stroke_draw.line(points, fill=(218, 252, 235, 31 if index % 4 else 46), width=1)

    for index in range(22):
        x = w * (0.27 + (index % 11) * 0.044)
        y = h * (0.67 + (index // 11) * 0.070 + ((index % 3) - 1) * 0.010)
        stroke_draw.arc(
            (x, y, x + w * 0.070, y + h * 0.030),
            start=192,
            end=344,
            fill=(226, 255, 238, 28),
            width=1,
        )

    stroke_mask = ImageChops.multiply(
        subject_mask,
        _vertical_mask(CANVAS_SIZE, 102, 0.46, 0.92),
    )
    stroke_mask = ImageChops.multiply(stroke_mask, _soft_blob_mask(CANVAS_SIZE, 218, seed_offset=78))
    result.alpha_composite(
        Image.composite(
            strokes.filter(ImageFilter.GaussianBlur(0.35)),
            Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0)),
            stroke_mask,
        ),
        (0, 0),
    )

    return result.convert("RGB")


def build() -> None:
    if not REFERENCE.exists():
        raise FileNotFoundError(f"Missing reference: {REFERENCE}")

    reference = Image.open(REFERENCE)
    # The full authored water window in the reference, excluding top status,
    # lower HUD, and the right sidebar. This keeps the real left/right reefs,
    # seabed, bubbles, and distant fish as the primary background source.
    crop = reference.crop((0, 88, 1215, 660))

    clean_crop = _remove_full_window_subjects(crop)
    background = _expand_to_canvas(clean_crop)
    background = _add_generated_canvas_paintover(background, _make_full_window_subject_mask(crop.size))
    background = _add_canvas_center_floor_lift(background, _make_full_window_subject_mask(crop.size))
    background = _add_canvas_reference_light_polish(background, crop, _make_full_window_subject_mask(crop.size))
    background = _harmonize(background)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    background.save(OUTPUT, optimize=True)
    print(f"built reference-derived underwater background: {OUTPUT}")


if __name__ == "__main__":
    build()
