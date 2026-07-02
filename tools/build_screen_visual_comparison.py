#!/usr/bin/env python3
"""Build side-by-side visual QA boards for single-screen previews."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
FONT_BOLD = ROOT / "assets" / "fonts" / "line_seed" / "LINESeedJP_A_TTF_Bd.ttf"
FONT_REGULAR = ROOT / "assets" / "fonts" / "line_seed" / "LINESeedJP_A_TTF_Rg.ttf"
VIEWPORT = (1280, 720)
LABEL_H = 34
GAP = 18
BG = "#10151d"
TEXT = "#f4ead1"
MUTED = "#9fe8ff"

PRESETS = {
    "fish_book": [
        {
            "id": "FISH_BOOK",
            "reference": ROOT / "reference" / "07_fish_book_mockup.png",
            "capture": Path("/tmp/tsuri_fish_book.png"),
            "out": Path("/tmp/tsuri_fish_book_compare.png"),
        }
    ],
    "fishing_spot_map": [
        {
            "id": "FISHING_SPOT_DEFAULT",
            "reference": ROOT / "reference" / "06_fishing_spot_map_mockup.png",
            "capture": Path("/tmp/tsuri_fishing_spot_map.png"),
            "out": Path("/tmp/tsuri_fishing_spot_map_compare.png"),
        },
        {
            "id": "FISHING_SPOT_CONTINUE",
            "reference": ROOT / "reference" / "06_fishing_spot_map_mockup.png",
            "capture": Path("/tmp/tsuri_fishing_spot_map_continue.png"),
            "out": Path("/tmp/tsuri_fishing_spot_map_continue_compare.png"),
        },
    ],
}


def font(size: int, *, bold: bool = True) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    path = FONT_BOLD if bold else FONT_REGULAR
    try:
        return ImageFont.truetype(str(path), size)
    except OSError:
        return ImageFont.load_default()


def fit_viewport(image: Image.Image) -> Image.Image:
    image = image.convert("RGB")
    if image.size == VIEWPORT:
        return image
    scale = min(VIEWPORT[0] / image.width, VIEWPORT[1] / image.height)
    resized = image.resize((round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS)
    canvas = Image.new("RGB", VIEWPORT, "#0b0e14")
    canvas.paste(resized, ((VIEWPORT[0] - resized.width) // 2, (VIEWPORT[1] - resized.height) // 2))
    return canvas


def draw_label(draw: ImageDraw.ImageDraw, x: int, title: str, path: Path) -> None:
    draw.text((x, 7), title, font=font(16), fill=TEXT)
    draw.text((x + 150, 9), str(path), font=font(12, bold=False), fill=MUTED)


def build_pair(reference: Path, capture: Path, out: Path, state_id: str) -> list[str]:
    missing = [path for path in (reference, capture) if not path.exists()]
    if missing:
        return [f"{state_id}: missing {path}" for path in missing]

    ref = fit_viewport(Image.open(reference))
    cur = fit_viewport(Image.open(capture))
    board = Image.new("RGB", (VIEWPORT[0] * 2 + GAP, VIEWPORT[1] + LABEL_H), BG)
    draw = ImageDraw.Draw(board)
    draw_label(draw, 8, f"{state_id} reference", reference)
    draw_label(draw, VIEWPORT[0] + GAP + 8, f"{state_id} current", capture)
    board.paste(ref, (0, LABEL_H))
    board.paste(cur, (VIEWPORT[0] + GAP, LABEL_H))
    out.parent.mkdir(parents=True, exist_ok=True)
    board.save(out)
    print(out)
    return []


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("preset", choices=sorted(PRESETS), help="Comparison preset to build.")
    args = parser.parse_args()

    failures: list[str] = []
    for item in PRESETS[args.preset]:
        failures.extend(build_pair(item["reference"], item["capture"], item["out"], item["id"]))
    if failures:
        print("visual comparison failed:")
        for failure in failures:
            print(f"  - {failure}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
