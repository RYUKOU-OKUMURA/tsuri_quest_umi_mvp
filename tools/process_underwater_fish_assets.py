#!/usr/bin/env python3
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "showcase" / "underwater"
REFERENCE = ROOT / "reference" / "02_underwater_fight_mockup.png"
FISH_SOURCE = OUT_DIR / "kurodai_chroma_source.png"
FISH_SHEET = OUT_DIR / "kurodai_showcase_sheet.png"
FISH_CARD_PORTRAIT = OUT_DIR / "kurodai_card_portrait.png"
HIT_BURST = OUT_DIR / "hit_burst.png"
HIT_BADGE_FULL = OUT_DIR / "hit_badge_full.png"
FIGHT_LURE = OUT_DIR / "fight_lure.png"
HUD_BAIT_ICON = OUT_DIR / "hud_bait_icon.png"
HUD_TENSION_ICON = OUT_DIR / "hud_tension_icon.png"
HUD_STAMINA_ICON = OUT_DIR / "hud_stamina_icon.png"
HUD_KEY_A = OUT_DIR / "hud_key_a.png"
HUD_KEY_B = OUT_DIR / "hud_key_b.png"
HUD_KEY_LR = OUT_DIR / "hud_key_lr.png"
HUD_KEY_PLUS = OUT_DIR / "hud_key_plus.png"
HUD_KEY_MINUS = OUT_DIR / "hud_key_minus.png"


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
    expanded = alpha.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(0.90))
    inner = alpha.filter(ImageFilter.GaussianBlur(0.35))
    edge = ImageChops.subtract(expanded, inner).point(lambda value: int(value * 0.28))
    underlay = Image.new("RGBA", image.size, (6, 24, 36, 0))
    underlay.putalpha(edge)
    return Image.alpha_composite(underlay, image)


def _restore_fish_detail(image: Image.Image) -> Image.Image:
    alpha = image.getchannel("A")
    rgb = image.convert("RGB")
    rgb = ImageEnhance.Contrast(rgb).enhance(1.08)
    rgb = ImageEnhance.Sharpness(rgb).enhance(1.18)
    rgb = rgb.filter(ImageFilter.UnsharpMask(radius=0.85, percent=72, threshold=2))
    out = rgb.convert("RGBA")
    out.putalpha(alpha)
    return out


def _polish_fish_material(image: Image.Image) -> Image.Image:
    out = image.copy()
    alpha = out.getchannel("A")
    bbox = alpha.point(lambda value: 255 if value > 24 else 0).getbbox()
    if bbox is None:
        return out

    x0, y0, x1, y1 = bbox
    content_w = max(1, x1 - x0)
    content_h = max(1, y1 - y0)
    px = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            nx = (x - x0) / content_w
            ny = (y - y0) / content_h
            opacity = min(1.0, a / 255.0)
            upper = max(0.0, min(1.0, (0.56 - ny) / 0.50))
            belly = max(0.0, min(1.0, (ny - 0.45) / 0.42))
            center_body = max(0.0, 1.0 - abs(nx - 0.47) / 0.52)
            fin_tail = max(0.0, min(1.0, (0.24 - nx) / 0.22)) + max(0.0, min(1.0, (nx - 0.79) / 0.18))
            edge = 1.0 - opacity

            # Cool the upper body and fin edges so the fish sits inside the
            # water instead of reading as a flat pasted sticker.
            cool_mix = min(0.24, 0.082 * upper + 0.065 * fin_tail + 0.135 * edge)
            r = int(r * (1.0 - cool_mix) + 18 * cool_mix)
            g = int(g * (1.0 - cool_mix) + 43 * cool_mix)
            b = int(b * (1.0 - cool_mix) + 60 * cool_mix)

            # Preserve the reference-like pearly belly without letting it turn
            # into a white flash during hit moments.
            belly_lift = min(0.058, 0.048 * belly * center_body * opacity)
            r = int(r * (1.0 - belly_lift) + 226 * belly_lift)
            g = int(g * (1.0 - belly_lift) + 231 * belly_lift)
            b = int(b * (1.0 - belly_lift) + 224 * belly_lift)

            lum = (r * 0.299 + g * 0.587 + b * 0.114) / 255.0
            if opacity > 0.60 and upper > 0.20 and lum > 0.76:
                cap_mix = min(0.078, (lum - 0.76) * 0.28 + upper * 0.024)
                r = int(r * (1.0 - cap_mix) + 166 * cap_mix)
                g = int(g * (1.0 - cap_mix) + 181 * cap_mix)
                b = int(b * (1.0 - cap_mix) + 188 * cap_mix)
            if opacity > 0.55 and 0.18 < nx < 0.76 and 0.12 < ny < 0.62 and lum > 0.64:
                line_mix = 0.030 * (1.0 - abs((ny - 0.35) / 0.35))
                r = int(r * (1.0 - line_mix) + 46 * line_mix)
                g = int(g * (1.0 - line_mix) + 58 * line_mix)
                b = int(b * (1.0 - line_mix) + 66 * line_mix)
            if opacity > 0.42:
                water_mix = min(0.062, 0.016 + upper * 0.018 + edge * 0.070 + fin_tail * 0.010)
                r = int(r * (1.0 - water_mix) + 20 * water_mix)
                g = int(g * (1.0 - water_mix) + 54 * water_mix)
                b = int(b * (1.0 - water_mix) + 72 * water_mix)

            px[x, y] = (max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b)), a)
    return out


def _final_fish_art_readability_pass(image: Image.Image) -> Image.Image:
    """Raise authored fish linework without changing runtime placement/scale."""
    out = image.copy()
    alpha = out.getchannel("A")
    bbox = alpha.point(lambda value: 255 if value > 24 else 0).getbbox()
    if bbox is None:
        return out

    gray = out.convert("L")
    edge_map = gray.filter(ImageFilter.FIND_EDGES).filter(ImageFilter.GaussianBlur(0.35))
    x0, y0, x1, y1 = bbox
    content_w = max(1, x1 - x0)
    content_h = max(1, y1 - y0)
    px = out.load()
    edge_px = edge_map.load()

    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue

            nx = (x - x0) / content_w
            ny = (y - y0) / content_h
            opacity = a / 255.0
            lum = (r * 0.299 + g * 0.587 + b * 0.114) / 255.0
            upper = max(0.0, min(1.0, (0.58 - ny) / 0.48))
            belly = max(0.0, min(1.0, (ny - 0.54) / 0.30))
            rear_fin = max(0.0, min(1.0, (0.34 - nx) / 0.28))
            head = max(0.0, min(1.0, (nx - 0.66) / 0.20))
            silhouette = max(0.0, min(1.0, (1.0 - opacity) * 1.8))
            line_edge = min(1.0, edge_px[x, y] / 255.0)

            line_mix = 0.0
            if opacity > 0.34:
                line_mix += 0.070 * line_edge
                line_mix += 0.044 * upper * (1.0 - belly)
                line_mix += 0.034 * rear_fin
                line_mix += 0.025 * head
                if lum < 0.42:
                    line_mix += 0.060
                if opacity < 0.82:
                    line_mix += 0.050 * silhouette
            line_mix = min(0.20, line_mix)
            r = int(r * (1.0 - line_mix) + 16 * line_mix)
            g = int(g * (1.0 - line_mix) + 24 * line_mix)
            b = int(b * (1.0 - line_mix) + 31 * line_mix)

            if opacity > 0.62 and belly > 0.18 and lum > 0.74:
                cap_mix = min(0.085, (lum - 0.74) * 0.20 + belly * 0.030)
                r = int(r * (1.0 - cap_mix) + 172 * cap_mix)
                g = int(g * (1.0 - cap_mix) + 184 * cap_mix)
                b = int(b * (1.0 - cap_mix) + 186 * cap_mix)

            if 0 < a < 150 and lum > 0.50:
                alpha_trim = 0.92 - min(0.18, silhouette * 0.10 + line_edge * 0.05)
                a = int(a * alpha_trim)

            px[x, y] = (
                max(0, min(255, r)),
                max(0, min(255, g)),
                max(0, min(255, b)),
                max(0, min(255, a)),
            )
    return out


def _soft_body_alpha(body: Image.Image, overlap: int) -> Image.Image:
    alpha = body.getchannel("A")
    if overlap <= 0:
        return alpha
    mask = Image.new("L", body.size, 0)
    mask_px = mask.load()
    alpha_px = alpha.load()
    for y in range(body.height):
        for x in range(body.width):
            fade = min(1.0, x / max(1, overlap))
            mask_px[x, y] = int(alpha_px[x, y] * fade)
    return mask


def _pose_runtime_fish_frame(fish: Image.Image, frame_index: int) -> Image.Image:
    if frame_index == 0:
        return fish

    w, h = fish.size
    tail_cut = int(w * 0.31)
    overlap = int(w * 0.105)
    tail_box = (0, 0, min(w, tail_cut + overlap), h)
    body_box = (max(0, tail_cut - overlap), 0, w, h)
    tail = fish.crop(tail_box)
    body = fish.crop(body_box)

    # Subtle authored poses from one high-quality source. The head/body stays
    # stable for readability; the tail and rear dorsal area create the motion.
    poses = {
        1: (-2.4, -3, 0),
        2: (3.2, 4, -1),
        3: (-1.4, 1, 1),
    }
    angle, dy, dx = poses.get(frame_index, (0.0, 0, 0))
    posed_tail = tail.rotate(angle, resample=Image.Resampling.BICUBIC, center=(tail.width * 0.72, tail.height * 0.52))
    posed_tail = _clean_transparent_fish_edge(posed_tail)

    out = Image.new("RGBA", fish.size, (0, 0, 0, 0))
    out.alpha_composite(posed_tail, (dx, dy))
    blended_body = body.copy()
    blended_body.putalpha(_soft_body_alpha(body, overlap))
    out.alpha_composite(blended_body, (body_box[0], 0))

    # A tiny vertical body bob keeps the four cells from reading like cloned
    # frames while avoiding visible distortion of the reference-quality fish.
    if frame_index in (1, 3):
        bob = -1 if frame_index == 1 else 1
        shifted = Image.new("RGBA", fish.size, (0, 0, 0, 0))
        shifted.alpha_composite(out, (0, bob))
        return shifted
    return out


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
        posed = _pose_runtime_fish_frame(resized, index if source_frames == 1 else min(index, 3))
        sheet.alpha_composite(posed, (x, y))

    clean_sheet = _final_fish_art_readability_pass(
        _polish_fish_material(_restore_fish_detail(_clean_transparent_fish_edge(_final_despill(sheet))))
    )
    _add_runtime_fish_edge_underlay(clean_sheet).save(FISH_SHEET)
    return clean_sheet


def create_kurodai_card_portrait(sheet: Image.Image | None = None) -> None:
    if sheet is None:
        sheet = Image.open(FISH_SHEET).convert("RGBA")
    frame_w = sheet.width // 4
    frame = sheet.crop((0, 0, frame_w, sheet.height))
    crop = ImageOps.mirror(frame.crop(_content_bbox(frame)))
    # Match the in-game sidebar portrait window, but keep the card paper and
    # rules in sidebar_frame.png so the fish reads as printed on one card
    # surface instead of sitting inside a second framed panel.
    canvas = Image.new("RGBA", (560, 310), (0, 0, 0, 0))
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.ellipse((74, 226, canvas.width - 64, 276), fill=(72, 52, 31, 22))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(9)))

    max_w = int(canvas.width * 0.985)
    max_h = int(canvas.height * 0.955)
    scale = min(max_w / crop.width, max_h / crop.height)
    resized = crop.resize((round(crop.width * scale), round(crop.height * scale)), Image.Resampling.LANCZOS)
    x = (canvas.width - resized.width) // 2
    y = (canvas.height - resized.height) // 2 - 5
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


def _extract_reference_hit_text() -> Image.Image:
    crop = Image.open(REFERENCE).convert("RGBA").crop((520, 525, 750, 645))
    w, h = crop.size
    warm = Image.new("L", crop.size, 0)
    src = crop.load()
    warm_px = warm.load()
    for y in range(h):
        for x in range(w):
            r, g, b, _a = src[x, y]
            warm_body = r > 125 and g > 50 and b < 120 and r > g + 24 and r > b + 38
            warm_highlight = r > 205 and g > 125 and b < 135
            if warm_body or warm_highlight:
                warm_px[x, y] = 255

    # Keep the large warm connected components that form the Japanese hit text,
    # then pull in only the nearby brown/black outline. This avoids carrying the
    # reference water background into the runtime badge.
    seen: set[tuple[int, int]] = set()
    keep = Image.new("L", crop.size, 0)
    keep_px = keep.load()
    for sy in range(h):
        for sx in range(w):
            if (sx, sy) in seen or warm_px[sx, sy] == 0:
                continue
            stack = [(sx, sy)]
            points: list[tuple[int, int]] = []
            while stack:
                x, y = stack.pop()
                if (x, y) in seen or not (0 <= x < w and 0 <= y < h):
                    continue
                seen.add((x, y))
                if warm_px[x, y] == 0:
                    continue
                points.append((x, y))
                stack.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
            if len(points) <= 45:
                continue
            xs = [point[0] for point in points]
            ys = [point[1] for point in points]
            x0, y0 = min(xs), min(ys)
            if 15 < x0 < 205 and 20 < y0 < 118:
                for x, y in points:
                    keep_px[x, y] = 255

    near = keep.filter(ImageFilter.MaxFilter(15)).filter(ImageFilter.GaussianBlur(0.55))
    mask = Image.new("L", crop.size, 0)
    near_px = near.load()
    mask_px = mask.load()
    for y in range(h):
        for x in range(w):
            if near_px[x, y] < 8:
                continue
            r, g, b, _a = src[x, y]
            warmish = r > 100 and g > 35 and b < 130 and r > g + 18 and r > b + 28
            brown_shadow = r > 42 and r < 135 and g < 86 and b < 78 and r >= b - 4
            black_edge = r < 58 and g < 58 and b < 64
            highlight = r > 185 and g > 130 and b > 70 and r > b + 25
            if warmish or brown_shadow or black_edge or highlight:
                mask_px[x, y] = min(255, int(near_px[x, y] * 1.9))

    mask = mask.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(0.32))
    text = crop.copy()
    text.putalpha(mask)
    bbox = mask.point(lambda value: 255 if value > 14 else 0).getbbox()
    if bbox is None:
        raise RuntimeError("hit text extraction produced an empty mask")
    pad = 4
    text = text.crop(
        (
            max(0, bbox[0] - pad),
            max(0, bbox[1] - pad),
            min(w, bbox[2] + pad),
            min(h, bbox[3] + pad),
        )
    )
    return text


def create_hit_badge_full() -> None:
    if not HIT_BURST.exists():
        create_hit_burst()
    badge = Image.open(HIT_BURST).convert("RGBA")
    text = _extract_reference_hit_text()
    scale = min(badge.width * 0.43 / text.width, badge.height * 0.52 / text.height)
    resized = text.resize((round(text.width * scale), round(text.height * scale)), Image.Resampling.LANCZOS)
    x = (badge.width - resized.width) // 2 + 2
    y = round(badge.height * 0.43 - resized.height * 0.5)
    badge.alpha_composite(resized, (x, y))
    badge.save(HIT_BADGE_FULL)


def create_fight_lure() -> None:
    crop = Image.open(REFERENCE).convert("RGBA").crop((780, 320, 900, 420))
    mask = Image.new("L", crop.size, 0)
    src = crop.load()
    raw_mask = mask.load()
    for y in range(crop.height):
        for x in range(crop.width):
            r, g, b, _a = src[x, y]
            warm_body = r > 92 and g > 38 and b < 150 and r > g + 18 and r > b + 35
            if warm_body:
                raw_mask[x, y] = 255

    near_lure = mask.filter(ImageFilter.MaxFilter(13)).filter(ImageFilter.GaussianBlur(1.0))
    final_mask = Image.new("L", crop.size, 0)
    near = near_lure.load()
    dst = final_mask.load()
    for y in range(crop.height):
        for x in range(crop.width):
            if near[x, y] <= 3:
                continue
            r, g, b, _a = src[x, y]
            warm_body = r > 92 and g > 38 and b < 150 and r > g + 18 and r > b + 35
            highlight = r > 150 and g > 128 and b > 82 and r > b + 18
            pale_hook = r > 175 and g > 175 and b > 165 and abs(r - g) < 45 and abs(g - b) < 55
            dark_outline = r < 82 and g < 95 and b < 112 and (r + g + b) < 245
            if warm_body or highlight or pale_hook or dark_outline:
                dst[x, y] = min(255, max(0, int(near[x, y] * 1.8)))

    final_mask = final_mask.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(0.35))
    lure = crop.copy()
    lure.putalpha(final_mask)
    bbox = final_mask.point(lambda value: 255 if value > 18 else 0).getbbox()
    if bbox is None:
        raise RuntimeError("fight lure extraction produced an empty mask")
    pad = 6
    box = (
        max(0, bbox[0] - pad),
        max(0, bbox[1] - pad),
        min(lure.width, bbox[2] + pad),
        min(lure.height, bbox[3] + pad),
    )
    lure = lure.crop(box)

    canvas = Image.new("RGBA", (128, 96), (0, 0, 0, 0))
    scale = min(114 / lure.width, 82 / lure.height)
    resized = lure.resize((round(lure.width * scale), round(lure.height * scale)), Image.Resampling.LANCZOS)
    canvas.alpha_composite(resized, ((canvas.width - resized.width) // 2, (canvas.height - resized.height) // 2))
    canvas.save(FIGHT_LURE)


def create_hud_bait_icon() -> None:
    crop = Image.open(REFERENCE).convert("RGBA").crop((185, 815, 260, 895))
    mask = Image.new("L", crop.size, 0)
    src = crop.load()
    raw_mask = mask.load()
    for y in range(crop.height):
        for x in range(crop.width):
            r, g, b, _a = src[x, y]
            warm_body = r > 105 and g > 35 and b < 145 and r > g + 22 and r > b + 35
            if warm_body:
                raw_mask[x, y] = 255

    near_bait = mask.filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.GaussianBlur(0.75))
    final_mask = Image.new("L", crop.size, 0)
    near = near_bait.load()
    dst = final_mask.load()
    for y in range(crop.height):
        for x in range(crop.width):
            if near[x, y] <= 4:
                continue
            r, g, b, _a = src[x, y]
            warm_body = r > 105 and g > 35 and b < 145 and r > g + 18 and r > b + 30
            highlight = r > 155 and g > 75 and b < 150 and r > g + 24 and r > b + 38
            dark_outline = r < 85 and g < 75 and b < 75 and (r + g + b) < 205
            if warm_body or highlight or dark_outline:
                dst[x, y] = min(255, int(near[x, y] * 1.75))

    final_mask = final_mask.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(0.25))
    bait = crop.copy()
    bait.putalpha(final_mask)
    bbox = final_mask.point(lambda value: 255 if value > 16 else 0).getbbox()
    if bbox is None:
        raise RuntimeError("HUD bait extraction produced an empty mask")
    pad = 5
    box = (
        max(0, bbox[0] - pad),
        max(0, bbox[1] - pad),
        min(bait.width, bbox[2] + pad),
        min(bait.height, bbox[3] + pad),
    )
    bait = bait.crop(box)

    canvas = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
    scale = min(84 / bait.width, 84 / bait.height)
    resized = bait.resize((round(bait.width * scale), round(bait.height * scale)), Image.Resampling.LANCZOS)
    canvas.alpha_composite(resized, ((canvas.width - resized.width) // 2, (canvas.height - resized.height) // 2))
    canvas.save(HUD_BAIT_ICON)


def create_hud_tension_icon() -> None:
    crop = Image.open(REFERENCE).convert("RGBA").crop((36, 658, 78, 700))
    mask = Image.new("L", crop.size, 0)
    src = crop.load()
    raw_mask = mask.load()
    for y in range(crop.height):
        for x in range(crop.width):
            r, g, b, _a = src[x, y]
            red_body = r > 170 and g > 45 and g < 130 and b < 120 and r > g + 50 and r > b + 65
            red_shadow = r > 100 and g < 80 and b < 80 and r > g + 35 and r > b + 35
            if red_body or red_shadow:
                raw_mask[x, y] = 255

    final_mask = mask.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(0.25))
    icon = crop.copy()
    icon.putalpha(final_mask)
    bbox = final_mask.point(lambda value: 255 if value > 16 else 0).getbbox()
    if bbox is None:
        raise RuntimeError("HUD tension extraction produced an empty mask")
    pad = 3
    box = (
        max(0, bbox[0] - pad),
        max(0, bbox[1] - pad),
        min(icon.width, bbox[2] + pad),
        min(icon.height, bbox[3] + pad),
    )
    icon = icon.crop(box)

    canvas = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    scale = min(56 / icon.width, 52 / icon.height)
    resized = icon.resize((round(icon.width * scale), round(icon.height * scale)), Image.Resampling.LANCZOS)
    canvas.alpha_composite(resized, ((canvas.width - resized.width) // 2, (canvas.height - resized.height) // 2))
    canvas.save(HUD_TENSION_ICON)


def create_hud_stamina_icon() -> None:
    crop = Image.open(REFERENCE).convert("RGBA").crop((786, 663, 846, 698))
    mask = Image.new("L", crop.size, 0)
    src = crop.load()
    raw_mask = mask.load()
    for y in range(crop.height):
        for x in range(crop.width):
            r, g, b, _a = src[x, y]
            blue_body = b > 92 and g > 70 and b > r + 24 and g > r - 18
            cyan_highlight = b > 135 and g > 120 and r < 150
            if blue_body or cyan_highlight:
                raw_mask[x, y] = 255

    near_icon = mask.filter(ImageFilter.MaxFilter(7)).filter(ImageFilter.GaussianBlur(0.55))
    final_mask = Image.new("L", crop.size, 0)
    near = near_icon.load()
    dst = final_mask.load()
    for y in range(crop.height):
        for x in range(crop.width):
            if near[x, y] <= 5:
                continue
            r, g, b, _a = src[x, y]
            blue_body = b > 88 and g > 62 and b > r + 18 and g > r - 24
            cyan_highlight = b > 128 and g > 110 and r < 160
            dark_outline = b > 46 and g > 36 and r < 70 and b > r + 8
            pale_glint = b > 150 and g > 150 and r > 120 and abs(g - b) < 50
            if blue_body or cyan_highlight or dark_outline or pale_glint:
                dst[x, y] = min(255, int(near[x, y] * 1.70))

    final_mask = final_mask.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(0.22))
    icon = crop.copy()
    icon.putalpha(final_mask)
    bbox = final_mask.point(lambda value: 255 if value > 16 else 0).getbbox()
    if bbox is None:
        raise RuntimeError("HUD stamina extraction produced an empty mask")
    pad = 3
    box = (
        max(0, bbox[0] - pad),
        max(0, bbox[1] - pad),
        min(icon.width, bbox[2] + pad),
        min(icon.height, bbox[3] + pad),
    )
    icon = icon.crop(box)
    icon = ImageEnhance.Contrast(icon).enhance(1.10)
    icon = ImageEnhance.Sharpness(icon).enhance(1.16)

    canvas = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    scale = min(60 / icon.width, 48 / icon.height)
    resized = icon.resize((round(icon.width * scale), round(icon.height * scale)), Image.Resampling.LANCZOS)
    canvas.alpha_composite(resized, ((canvas.width - resized.width) // 2, (canvas.height - resized.height) // 2))
    canvas.save(HUD_STAMINA_ICON)


def _create_keycap_from_reference(
    box: tuple[int, int, int, int],
    output: Path,
    *,
    canvas_size: tuple[int, int],
    light_key: bool,
) -> None:
    crop = Image.open(REFERENCE).convert("RGBA").crop(box)
    src = crop.load()
    seed_mask = Image.new("L", crop.size, 0)
    seed_px = seed_mask.load()
    for y in range(crop.height):
        for x in range(crop.width):
            r, g, b, _a = src[x, y]
            if light_key:
                keep = r > 170 and g > 145 and b > 105 and (r - b) > 28
            else:
                keep = r < 92 and g < 92 and b < 104
            if keep:
                seed_px[x, y] = 255

    near = seed_mask.filter(ImageFilter.MaxFilter(11)).filter(ImageFilter.GaussianBlur(0.45))
    mask = Image.new("L", crop.size, 0)
    near_px = near.load()
    mask_px = mask.load()
    for y in range(crop.height):
        for x in range(crop.width):
            if near_px[x, y] <= 4:
                continue
            r, g, b, _a = src[x, y]
            saturation = max(r, g, b) - min(r, g, b)
            if light_key:
                circle = r > 160 and g > 135 and b > 90 and r >= g >= b - 10
                glyph = r < 92 and g < 82 and b < 72
                highlight = r > 220 and g > 205 and b > 170
                keep = circle or glyph or highlight
            else:
                body = r < 112 and g < 112 and b < 122
                glyph = r > 180 and g > 175 and b > 160 and saturation < 75
                edge = r > 90 and g > 72 and b > 48 and r < 170 and g < 145
                keep = body or glyph or edge
            if keep:
                mask_px[x, y] = min(255, int(near_px[x, y] * 1.85))

    mask = mask.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(0.25))
    keycap = crop.copy()
    keycap.putalpha(mask)
    bbox = mask.point(lambda value: 255 if value > 16 else 0).getbbox()
    if bbox is None:
        raise RuntimeError(f"keycap extraction produced an empty mask for {output.name}")
    pad = 3
    keycap = keycap.crop(
        (
            max(0, bbox[0] - pad),
            max(0, bbox[1] - pad),
            min(keycap.width, bbox[2] + pad),
            min(keycap.height, bbox[3] + pad),
        )
    )
    keycap = ImageEnhance.Contrast(keycap).enhance(1.05)
    keycap = ImageEnhance.Sharpness(keycap).enhance(1.08)
    canvas = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    scale = min((canvas.width - 4) / keycap.width, (canvas.height - 4) / keycap.height)
    resized = keycap.resize((round(keycap.width * scale), round(keycap.height * scale)), Image.Resampling.LANCZOS)
    canvas.alpha_composite(resized, ((canvas.width - resized.width) // 2, (canvas.height - resized.height) // 2))
    canvas.save(output)


def create_hud_keycaps() -> None:
    _create_keycap_from_reference((397, 858, 437, 898), HUD_KEY_A, canvas_size=(64, 64), light_key=False)
    _create_keycap_from_reference((586, 858, 626, 898), HUD_KEY_B, canvas_size=(64, 64), light_key=False)
    _create_keycap_from_reference((785, 861, 863, 895), HUD_KEY_LR, canvas_size=(96, 64), light_key=False)
    _create_keycap_from_reference((1028, 826, 1070, 868), HUD_KEY_PLUS, canvas_size=(64, 64), light_key=True)
    _create_keycap_from_reference((1028, 872, 1070, 914), HUD_KEY_MINUS, canvas_size=(64, 64), light_key=True)


def main() -> None:
    clean_sheet = create_kurodai_sheet()
    create_kurodai_card_portrait(clean_sheet)
    create_hit_burst()
    create_hit_badge_full()
    create_fight_lure()
    create_hud_bait_icon()
    create_hud_tension_icon()
    create_hud_stamina_icon()
    create_hud_keycaps()
    print(
        f"processed {FISH_SHEET}, {FISH_CARD_PORTRAIT}, {HIT_BURST}, {HIT_BADGE_FULL}, "
        f"{FIGHT_LURE}, {HUD_BAIT_ICON}, {HUD_TENSION_ICON}, {HUD_STAMINA_ICON}, "
        f"{HUD_KEY_A}, {HUD_KEY_B}, {HUD_KEY_LR}, {HUD_KEY_PLUS}, and {HUD_KEY_MINUS}"
    )


if __name__ == "__main__":
    main()
