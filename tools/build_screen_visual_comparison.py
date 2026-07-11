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
    "title_storage_block": [
        {
            "id": "TITLE_STORAGE_BLOCK",
            "reference": Path("/tmp/tsuri_title_normal.png"),
            "capture": Path("/tmp/tsuri_title_storage_blocked.png"),
            "out": Path("/tmp/tsuri_title_storage_blocked_compare.png"),
        }
    ],
    "title_invalid_artifact": [
        {
            "id": "TITLE_INVALID_ARTIFACT",
            "reference": Path("/tmp/tsuri_title_normal.png"),
            "capture": Path("/tmp/tsuri_title_invalid_artifact.png"),
            "out": Path("/tmp/tsuri_title_invalid_artifact_compare.png"),
        }
    ],
    "status": [
        {
            "id": "STATUS",
            "reference": ROOT / "reference" / "08_status_screen_mockup.png",
            "capture": Path("/tmp/tsuri_status.png"),
            "out": Path("/tmp/tsuri_status_compare.png"),
        }
    ],
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
        {
            "id": "FISHING_SPOT_DANGER_CHART",
            "reference": ROOT / "reference" / "06_fishing_spot_map_mockup.png",
            "capture": Path("/tmp/tsuri_fishing_spot_map_danger_chart.png"),
            "out": Path("/tmp/tsuri_fishing_spot_map_danger_chart_compare.png"),
        },
    ],
    "tackle_shop": [
        {
            "id": "TACKLE_SHOP_ROD",
            "reference": ROOT / "reference" / "09_tackle_shop_rod_mockup.png",
            "capture": Path("/tmp/tsuri_tackle_shop_rod.png"),
            "out": Path("/tmp/tsuri_tackle_shop_rod_compare.png"),
        },
        {
            "id": "TACKLE_SHOP_RIG",
            "reference": ROOT / "reference" / "09_tackle_shop_gear_mockup.png",
            "capture": Path("/tmp/tsuri_tackle_shop_rig.png"),
            "out": Path("/tmp/tsuri_tackle_shop_rig_compare.png"),
        },
    ],
    "market": [
        {
            "id": "FISH_MARKET_SELECT",
            "reference": ROOT / "reference" / "10_fish_market_mockup.png",
            "capture": Path("/tmp/tsuri_market_select.png"),
            "out": Path("/tmp/tsuri_market_select_compare.png"),
        },
        {
            "id": "FISH_MARKET_CONFIRM",
            "reference": ROOT / "reference" / "10_fish_market_mockup.png",
            "capture": Path("/tmp/tsuri_market_confirm.png"),
            "out": Path("/tmp/tsuri_market_confirm_compare.png"),
        },
        {
            "id": "FISH_MARKET_SOLD",
            "reference": ROOT / "reference" / "10_fish_market_mockup.png",
            "capture": Path("/tmp/tsuri_market_sold.png"),
            "out": Path("/tmp/tsuri_market_sold_compare.png"),
        },
        {
            "id": "FISH_MARKET_EMPTY",
            "reference": ROOT / "reference" / "10_fish_market_mockup.png",
            "capture": Path("/tmp/tsuri_market_empty.png"),
            "out": Path("/tmp/tsuri_market_empty_compare.png"),
        },
    ],
    "quest_board": [
        {
            "id": "QUEST_BOARD",
            "reference": ROOT / "reference" / "11_quest_board_mockup.png",
            "capture": Path("/tmp/tsuri_quest_board.png"),
            "out": Path("/tmp/tsuri_quest_board_compare.png"),
        }
    ],
    "shark_pen": [
        {
            "id": "SHARK_PEN",
            "reference": ROOT / "reference" / "12_shark_pen_mockup.png",
            "capture": Path("/tmp/tsuri_shark_pen.png"),
            "out": Path("/tmp/tsuri_shark_pen_compare.png"),
        }
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
    title_font = font(16)
    path_font = font(12, bold=False)
    draw.text((x, 7), title, font=title_font, fill=TEXT)
    path_x = x + int(draw.textlength(title, font=title_font)) + 16
    draw.text((path_x, 9), str(path), font=path_font, fill=MUTED)


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
