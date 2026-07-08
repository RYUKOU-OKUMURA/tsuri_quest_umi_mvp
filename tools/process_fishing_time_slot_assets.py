#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "tools" / "source_assets" / "fishing_time_slots"
SURFACE_DIR = ROOT / "assets" / "showcase" / "surface"
UNDERWATER_DIR = ROOT / "assets" / "showcase" / "underwater"

ASSETS = [
    (
        SOURCE_DIR / "surface_scene_ready_asa_mazume_source.png",
        SURFACE_DIR / "surface_scene_ready_asa_mazume.png",
        (960, 405),
    ),
    (
        SOURCE_DIR / "surface_scene_ready_night_source.png",
        SURFACE_DIR / "surface_scene_ready_night.png",
        (960, 405),
    ),
    (
        SOURCE_DIR / "catch_photo_base_asa_source.png",
        UNDERWATER_DIR / "catch_photo_base_asa.png",
        (1280, 720),
    ),
    (
        SOURCE_DIR / "catch_photo_base_night_source.png",
        UNDERWATER_DIR / "catch_photo_base_night.png",
        (1280, 720),
    ),
]


def cover_resize(image: Image.Image, target_size: tuple[int, int]) -> Image.Image:
    target_w, target_h = target_size
    image = image.convert("RGBA")
    src_w, src_h = image.size
    target_ratio = target_w / target_h
    src_ratio = src_w / src_h
    if src_ratio > target_ratio:
        crop_h = src_h
        crop_w = round(crop_h * target_ratio)
    else:
        crop_w = src_w
        crop_h = round(crop_w / target_ratio)
    left = max(0, (src_w - crop_w) // 2)
    top = max(0, (src_h - crop_h) // 2)
    cropped = image.crop((left, top, left + crop_w, top + crop_h))
    return cropped.resize(target_size, Image.Resampling.LANCZOS)


def build_contact_sheet(outputs: list[Path]) -> None:
    thumbs: list[tuple[str, Image.Image]] = []
    for path in outputs:
        image = Image.open(path).convert("RGBA")
        if image.width > image.height:
            thumb_w = 420
            thumb_h = round(image.height * thumb_w / image.width)
        else:
            thumb_h = 260
            thumb_w = round(image.width * thumb_h / image.height)
        thumbs.append((path.name, image.resize((thumb_w, thumb_h), Image.Resampling.LANCZOS)))

    label_h = 28
    pad = 18
    col_w = 450
    row_h = 248
    sheet = Image.new("RGBA", (col_w * 2 + pad * 3, row_h * 2 + pad * 3), (16, 24, 34, 255))
    draw = ImageDraw.Draw(sheet)
    for index, (label, thumb) in enumerate(thumbs):
        col = index % 2
        row = index // 2
        x = pad + col * (col_w + pad)
        y = pad + row * (row_h + pad)
        draw.text((x, y), label, fill=(240, 228, 190, 255))
        image_y = y + label_h
        sheet.alpha_composite(thumb, (x, image_y))
    out = SOURCE_DIR / "fishing_time_slot_asset_contact_sheet.png"
    sheet.save(out)
    print(out.relative_to(ROOT))


def main() -> None:
    outputs: list[Path] = []
    for source, out, target_size in ASSETS:
        if not source.exists():
            raise SystemExit(f"missing source: {source.relative_to(ROOT)}")
        out.parent.mkdir(parents=True, exist_ok=True)
        image = cover_resize(Image.open(source), target_size)
        image.save(out)
        outputs.append(out)
        print(out.relative_to(ROOT))
    build_contact_sheet(outputs)


if __name__ == "__main__":
    main()

