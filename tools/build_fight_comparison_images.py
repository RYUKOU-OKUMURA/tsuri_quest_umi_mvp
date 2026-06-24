#!/usr/bin/env python3
"""Build PNG comparison boards for the underwater fight screen."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
REFERENCE = ROOT / "reference" / "02_underwater_fight_mockup.png"
CAPTURE = Path("/tmp/tsuri_fishing_fight.png")
OUT_FULL = Path("/tmp/tsuri_fight_compare.png")
OUT_FRAME = Path("/tmp/tsuri_frame_focus_compare.png")
OUT_FISH = Path("/tmp/tsuri_fish_hit_focus.png")
BG = "#07111d"
TEXT = "#e8f3ff"


def _fit_height(image: Image.Image, height: int) -> Image.Image:
    return image.resize((round(image.width * height / image.height), height), Image.Resampling.LANCZOS)


def _fit_width(image: Image.Image, width: int) -> Image.Image:
    return image.resize((width, round(image.height * width / image.width)), Image.Resampling.LANCZOS)


def _label(draw: ImageDraw.ImageDraw, xy: tuple[int, int], text: str) -> None:
    draw.text(xy, text, fill=TEXT)


def build_full(reference: Image.Image, capture: Image.Image) -> None:
    label_h = 34
    scale_h = 720
    ref = _fit_height(reference, scale_h)
    cur = _fit_height(capture, scale_h)
    out = Image.new("RGB", (ref.width + cur.width + 24, scale_h + label_h + 16), BG)
    draw = ImageDraw.Draw(out)
    _label(draw, (8, 8), "REFERENCE: 02_underwater_fight_mockup.png")
    _label(draw, (ref.width + 24, 8), "CURRENT: /tmp/tsuri_fishing_fight.png")
    out.paste(ref, (8, label_h))
    out.paste(cur, (ref.width + 16, label_h))
    out.save(OUT_FULL)


def build_frame_focus(reference: Image.Image, capture: Image.Image) -> None:
    ref_ui = reference.crop((0, 610, reference.width, reference.height))
    cur_ui = capture.crop((0, 430, capture.width, capture.height))
    ref = _fit_height(ref_ui, 330)
    cur = _fit_height(cur_ui, 330)
    out = Image.new("RGB", (ref.width + cur.width + 28, 390), BG)
    draw = ImageDraw.Draw(out)
    _label(draw, (8, 8), "REFERENCE HUD / RIGHT PANEL REGION")
    _label(draw, (ref.width + 20, 8), "CURRENT HUD / RIGHT PANEL REGION")
    out.paste(ref, (8, 40))
    out.paste(cur, (ref.width + 20, 40))
    out.save(OUT_FRAME)


def build_fish_focus(reference: Image.Image, capture: Image.Image) -> None:
    ref_fish = reference.crop((0, 85, 1260, 612))
    cur_fish = capture.crop((0, 84, 980, 455))
    ref = _fit_width(ref_fish, 720)
    cur = _fit_width(cur_fish, 720)
    out = Image.new("RGB", (1460, max(ref.height, cur.height) + 80), BG)
    draw = ImageDraw.Draw(out)
    _label(draw, (12, 12), "REFERENCE FISH/HIT REGION")
    _label(draw, (740, 12), "CURRENT WATER REGION")
    out.paste(ref, (12, 40))
    out.paste(cur, (740, 40))
    out.save(OUT_FISH)


def main() -> int:
    missing = [path for path in (REFERENCE, CAPTURE) if not path.exists()]
    if missing:
        print("Missing required image(s):")
        for path in missing:
            print(f"  - {path}")
        return 1

    reference = Image.open(REFERENCE).convert("RGB")
    capture = Image.open(CAPTURE).convert("RGB")
    build_full(reference, capture)
    build_frame_focus(reference, capture)
    build_fish_focus(reference, capture)
    print(OUT_FULL)
    print(OUT_FRAME)
    print(OUT_FISH)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
