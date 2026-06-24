#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
REFERENCE = ROOT / "reference" / "02_underwater_fight_mockup.png"
OUTPUT = ROOT / "assets" / "showcase" / "underwater" / "underwater_battle_bg.png"

CANVAS_SIZE = (1672, 941)


def _make_full_window_subject_mask(size: tuple[int, int]) -> Image.Image:
    w, h = size
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)

    # The full reference water window preserves the authored left/right reefs
    # and seabed, so only remove the runtime subjects that will be redrawn by
    # Godot: the large kurodai, the hit burst, the line, and the lure.
    draw.ellipse((w * 0.11, h * 0.16, w * 0.66, h * 0.68), fill=255)
    draw.rectangle((w * 0.22, h * 0.28, w * 0.60, h * 0.60), fill=255)
    draw.polygon(((w * 0.23, h * 0.38), (w * 0.10, h * 0.27), (w * 0.11, h * 0.62)), fill=255)
    draw.ellipse((w * 0.48, h * 0.24, w * 0.70, h * 0.62), fill=255)
    draw.polygon(((w * 0.40, h * 0.56), (w * 0.60, h * 0.54), (w * 0.58, h * 0.72), (w * 0.44, h * 0.72)), fill=255)

    draw.ellipse((w * 0.34, h * 0.62, w * 0.76, h * 1.04), fill=255)
    draw.rectangle((w * 0.34, h * 0.70, w * 0.76, h * 0.99), fill=255)

    draw.line((w * 0.91, -h * 0.08, w * 0.68, h * 0.54), fill=255, width=max(58, int(w * 0.062)))
    draw.line((w * 0.84, -h * 0.06, w * 0.67, h * 0.52), fill=255, width=max(46, int(w * 0.050)))
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
        fade_in = min(1.0, max(0.0, (v - top) / 0.18))
        fade_out = min(1.0, max(0.0, (bottom - v) / 0.10))
        row_alpha = int(alpha * fade_in * fade_out)
        for x in range(w):
            u = x / max(1, w - 1)
            side_fade = min(1.0, u / 0.16, (1.0 - u) / 0.16)
            pixels[x, y] = int(row_alpha * side_fade)
    return mask.filter(ImageFilter.GaussianBlur(10.0))


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
    left_floor = source.crop((int(w * 0.02), int(h * 0.69), int(w * 0.34), h))
    right_floor = source.crop((int(w * 0.76), int(h * 0.66), int(w * 0.98), h))
    floor_source = Image.new(
        "RGB",
        (left_floor.width + right_floor.width, max(left_floor.height, right_floor.height)),
    )
    floor_source.paste(left_floor, (0, floor_source.height - left_floor.height))
    floor_source.paste(right_floor, (left_floor.width, floor_source.height - right_floor.height))
    seabed_patch = floor_source.resize(
        (int(w * 0.72), int(h * 0.30)),
        Image.Resampling.LANCZOS,
    )
    seabed_patch = ImageEnhance.Brightness(seabed_patch).enhance(0.78)
    seabed_patch = ImageEnhance.Color(seabed_patch).enhance(0.82)
    seabed_patch = ImageEnhance.Contrast(seabed_patch).enhance(0.96)

    seabed_alpha = ImageChops.multiply(
        subject_mask.crop(
            (int(w * 0.16), int(h * 0.66), int(w * 0.88), int(h * 0.96)),
        ).resize(
            seabed_patch.size,
            Image.Resampling.LANCZOS,
        ),
        _vertical_mask(seabed_patch.size, 102, 0.18, 0.98),
    )
    base.alpha_composite(
        Image.composite(
            seabed_patch.convert("RGBA"),
            Image.new("RGBA", seabed_patch.size, (0, 0, 0, 0)),
            seabed_alpha,
        ),
        (int(w * 0.16), int(h * 0.66)),
    )

    floor_fragments = (
        (source.crop((int(w * 0.08), int(h * 0.74), int(w * 0.28), int(h * 0.92))), 0.33, 0.79, 0.24, 0.11, 30),
        (source.crop((int(w * 0.78), int(h * 0.72), int(w * 0.96), int(h * 0.92))), 0.49, 0.82, 0.21, 0.10, 24),
        (source.crop((int(w * 0.20), int(h * 0.78), int(w * 0.38), int(h * 0.94))), 0.61, 0.83, 0.19, 0.09, 20),
    )
    for fragment, u, v, patch_w_ratio, patch_h_ratio, alpha in floor_fragments:
        patch_size = (int(w * patch_w_ratio), int(h * patch_h_ratio))
        patch = fragment.resize(patch_size, Image.Resampling.LANCZOS)
        patch = ImageEnhance.Brightness(patch).enhance(0.72)
        patch = ImageEnhance.Color(patch).enhance(0.76)
        patch = ImageEnhance.Contrast(patch).enhance(0.88)
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

    left_water = source.crop((int(w * 0.02), int(h * 0.18), int(w * 0.24), int(h * 0.56)))
    right_water = left_water.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    mid_source = Image.new(
        "RGB",
        (left_water.width + right_water.width, max(left_water.height, right_water.height)),
    )
    mid_source.paste(left_water, (0, 0))
    mid_source.paste(right_water, (left_water.width, 0))
    mid_patch = mid_source.resize((int(w * 0.60), int(h * 0.36)), Image.Resampling.LANCZOS)
    mid_patch = ImageEnhance.Brightness(mid_patch).enhance(0.92)
    mid_patch = ImageEnhance.Color(mid_patch).enhance(0.88)
    mid_patch = ImageEnhance.Contrast(mid_patch).enhance(0.94)
    mid_patch = mid_patch.filter(ImageFilter.GaussianBlur(0.28))

    mid_alpha = ImageChops.multiply(
        subject_mask.crop((int(w * 0.20), int(h * 0.20), int(w * 0.80), int(h * 0.56))).resize(
            mid_patch.size,
            Image.Resampling.LANCZOS,
        ),
        _vertical_mask(mid_patch.size, 94, 0.00, 0.98),
    )
    base.alpha_composite(
        Image.composite(
            mid_patch.convert("RGBA"),
            Image.new("RGBA", mid_patch.size, (0, 0, 0, 0)),
            mid_alpha,
        ),
        (int(w * 0.20), int(h * 0.20)),
    )

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
        _vertical_mask(light_patch_size, 44, 0.00, 0.92),
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
            (0.24, 0.30, 0.40, 0.34, 24),
            (0.38, 0.45, 0.56, 0.48, 19),
            (0.55, 0.61, 0.68, 0.62, 17),
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
    for index in range(36):
        u = 0.24 + (index % 9) * 0.055 + ((index // 9) % 2) * 0.018
        v = 0.26 + (index // 9) * 0.088
        radius = 1.3 + (index % 3) * 0.6
        alpha = 34 if index % 4 else 50
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
        _vertical_mask(source.size, 112, 0.42, 0.94),
    )
    base.alpha_composite(
        Image.composite(
            caustics,
            Image.new("RGBA", source.size, (0, 0, 0, 0)),
            caustic_mask,
        ),
        (0, 0),
    )
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
    draw.rectangle((0, 0, w, int(h * 0.10)), fill=(0, 20, 42, 22))
    draw.rectangle((0, int(h * 0.78), w, h), fill=(0, 28, 42, 20))
    draw.rectangle((0, 0, int(w * 0.12), h), fill=(0, 20, 38, 18))
    draw.rectangle((int(w * 0.88), 0, w, h), fill=(0, 20, 38, 18))
    image = image.convert("RGBA")
    image.alpha_composite(overlay.filter(ImageFilter.GaussianBlur(28)))
    return image.convert("RGB")


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
    background = _harmonize(background)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    background.save(OUTPUT, optimize=True)
    print(f"built reference-derived underwater background: {OUTPUT}")


if __name__ == "__main__":
    build()
