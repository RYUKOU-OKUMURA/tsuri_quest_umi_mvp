#!/usr/bin/env python3
"""Build a contact sheet for judging underwater-fight kurodai art candidates.

The tool never writes production assets. It previews a candidate through the
same fish-material pipeline used by process_underwater_fish_assets.py so final
art can be judged before replacing tools/source_assets/kurodai_final_art_source.png.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / "tools"
sys.path.insert(0, str(TOOLS))

from process_underwater_fish_assets import (  # noqa: E402
    FINAL_FISH_SOURCE,
    FISH_CARD_PORTRAIT,
    FISH_SHEET,
    _add_runtime_fish_edge_underlay,
    _clean_transparent_fish_edge,
    _content_bbox,
    _final_despill,
    _final_fish_art_readability_pass,
    _magenta_removed,
    _polish_fish_material,
    _restore_fish_detail,
)


REFERENCE = ROOT / "reference" / "02_underwater_fight_mockup.png"
OUT = Path("/tmp/tsuri_fish_asset_contact.png")
FONT_BOLD = ROOT / "assets" / "fonts" / "MPLUS1p-Bold.ttf"
FONT_REGULAR = ROOT / "assets" / "fonts" / "MPLUS1p-Regular.ttf"
BG = "#07111d"
PANEL_BG = "#081822"
TEXT = "#e8f3ff"
MUTED = "#b9cbd4"


def _font(size: int, *, bold: bool = True) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    path = FONT_BOLD if bold else FONT_REGULAR
    try:
        return ImageFont.truetype(str(path), size)
    except OSError:
        return ImageFont.load_default()


def _alpha_bbox(image: Image.Image) -> tuple[int, int, int, int] | None:
    if image.mode != "RGBA":
        image = image.convert("RGBA")
    return image.getchannel("A").point(lambda value: 255 if value > 8 else 0).getbbox()


def _has_transparent_border(image: Image.Image) -> bool:
    image = image.convert("RGBA")
    alpha = image.getchannel("A")
    samples = []
    step_x = max(1, image.width // 80)
    step_y = max(1, image.height // 80)
    px = alpha.load()
    for x in range(0, image.width, step_x):
        samples.append(px[x, 0])
        samples.append(px[x, image.height - 1])
    for y in range(0, image.height, step_y):
        samples.append(px[0, y])
        samples.append(px[image.width - 1, y])
    if not samples:
        return False
    transparent = sum(1 for value in samples if value < 8)
    return transparent / len(samples) > 0.70


def _normalize_source(path: Path) -> Image.Image:
    source = Image.open(path).convert("RGBA")
    if _has_transparent_border(source):
        return source
    return _magenta_removed(source)


def _processed_runtime_frame(path: Path) -> Image.Image:
    source = _normalize_source(path)
    source_frames = 1 if source.width / max(1, source.height) < 2.4 else 4
    source_w = source.width // source_frames
    source_index = 0 if source_frames == 1 else 1
    raw = source.crop((source_index * source_w, 0, (source_index + 1) * source_w, source.height))
    crop = raw.crop(_content_bbox(raw))
    frame_w, frame_h = 640, 320
    scale = min((frame_w * 0.96) / crop.width, (frame_h * 0.92) / crop.height)
    resized = crop.resize((round(crop.width * scale), round(crop.height * scale)), Image.Resampling.LANCZOS)
    frame = Image.new("RGBA", (frame_w, frame_h), (0, 0, 0, 0))
    frame.alpha_composite(resized, ((frame_w - resized.width) // 2, (frame_h - resized.height) // 2 + 8))
    clean = _final_fish_art_readability_pass(
        _polish_fish_material(_restore_fish_detail(_clean_transparent_fish_edge(_final_despill(frame))))
    )
    return _add_runtime_fish_edge_underlay(clean)


def _reference_fish_crop() -> Image.Image:
    # Wide enough to include the full reference fish and enough water context
    # to judge scale/linework, but excludes the lure and right panel.
    return Image.open(REFERENCE).convert("RGBA").crop((150, 150, 750, 430))


def _fit_tile(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    image = image.convert("RGBA")
    canvas = Image.new("RGBA", size, PANEL_BG)
    bbox = _alpha_bbox(image)
    if bbox is not None:
        image = image.crop(bbox)
    scale = min((size[0] - 28) / image.width, (size[1] - 84) / image.height)
    resized = image.resize((max(1, round(image.width * scale)), max(1, round(image.height * scale))), Image.Resampling.LANCZOS)
    canvas.alpha_composite(resized, ((size[0] - resized.width) // 2, 42 + (size[1] - 86 - resized.height) // 2))
    return canvas


def _short_note(note: str, max_chars: int = 68) -> str:
    if len(note) <= max_chars:
        return note
    keep = max_chars - 3
    head = keep // 2
    tail = keep - head
    return f"{note[:head]}...{note[-tail:]}"


def _draw_tile(
    board: Image.Image,
    position: tuple[int, int],
    title: str,
    image: Image.Image,
    *,
    tile_size: tuple[int, int],
    note: str | None = None,
) -> None:
    x, y = position
    board.alpha_composite(_fit_tile(image, tile_size), (x, y))
    draw = ImageDraw.Draw(board)
    draw.text((x + 14, y + 10), title, font=_font(18), fill=TEXT)
    if note:
        draw.text((x + 14, y + tile_size[1] - 25), _short_note(note), font=_font(12, bold=False), fill=MUTED)


def build(candidate: Path, out: Path) -> None:
    tile = (520, 246)
    board = Image.new("RGBA", (tile[0] * 2, tile[1] * 3), BG)

    current_frame = Image.open(FISH_SHEET).convert("RGBA").crop((0, 0, Image.open(FISH_SHEET).width // 4, Image.open(FISH_SHEET).height))
    candidate_processed = _processed_runtime_frame(candidate)

    entries = [
        ("REFERENCE MAIN FISH", _reference_fish_crop(), "visual target, not an extraction source"),
        ("CURRENT FINAL SOURCE", Image.open(FINAL_FISH_SOURCE).convert("RGBA"), str(FINAL_FISH_SOURCE.relative_to(ROOT))),
        ("CURRENT RUNTIME FRAME", current_frame, str(FISH_SHEET.relative_to(ROOT))),
        ("CURRENT CARD PORTRAIT", Image.open(FISH_CARD_PORTRAIT).convert("RGBA"), str(FISH_CARD_PORTRAIT.relative_to(ROOT))),
        ("CANDIDATE SOURCE", Image.open(candidate).convert("RGBA"), str(candidate)),
        ("CANDIDATE PROCESSED FRAME", candidate_processed, "preview only; production assets are not overwritten"),
    ]
    for index, (title, image, note) in enumerate(entries):
        _draw_tile(board, ((index % 2) * tile[0], (index // 2) * tile[1]), title, image, tile_size=tile, note=note)

    out.parent.mkdir(parents=True, exist_ok=True)
    board.convert("RGB").save(out)
    print(out)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--candidate",
        type=Path,
        default=FINAL_FISH_SOURCE,
        help="Candidate kurodai source PNG. Defaults to the current final-art source.",
    )
    parser.add_argument("--out", type=Path, default=OUT, help="Output contact sheet PNG path.")
    args = parser.parse_args()

    missing = [path for path in (REFERENCE, FINAL_FISH_SOURCE, FISH_SHEET, FISH_CARD_PORTRAIT, args.candidate) if not path.exists()]
    if missing:
        print("Missing required image(s):")
        for path in missing:
            print(f"  - {path}")
        return 1
    build(args.candidate, args.out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
