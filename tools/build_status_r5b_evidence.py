#!/usr/bin/env python3
"""Persist the fresh STATUS-R5B visual QA evidence set."""

from __future__ import annotations

import shutil
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs/qa/evidence/status"
REFERENCE = ROOT / "reference/08_status_screen_mockup.png"
FONT = ROOT / "assets/fonts/line_seed/LINESeedJP_A_TTF_Bd.ttf"
VIEWPORT = (1280, 720)
THUMB = (320, 180)


def _checked(path: Path) -> Image.Image:
    with Image.open(path) as opened:
        opened.load()
        image = opened.convert("RGB")
    if image.size != VIEWPORT:
        raise ValueError(f"unexpected evidence size {image.size}: {path}")
    # Fail closed on the exact black/incomplete regression that can occur if
    # two preview processes race on the same /tmp capture path.
    visible = sum(1 for r, g, b in image.getdata() if r + g + b > 80)
    if visible / (VIEWPORT[0] * VIEWPORT[1]) < 0.20:
        raise ValueError(f"black or incomplete evidence capture: {path}")
    return image


def _copy_checked(source: Path, target: Path) -> None:
    _checked(source)
    shutil.copyfile(source, target)


def _thumbnail_board(paths: list[tuple[str, Path]], target: Path, grayscale: bool = False) -> None:
    label_h = 26
    board = Image.new("RGB", (THUMB[0] * len(paths), THUMB[1] + label_h), "#10151d")
    draw = ImageDraw.Draw(board)
    try:
        font = ImageFont.truetype(str(FONT), 14)
    except OSError:
        font = ImageFont.load_default()
    for index, (label, path) in enumerate(paths):
        image = _checked(path)
        if grayscale:
            image = ImageOps.grayscale(image).convert("RGB")
        image = image.resize(THUMB, Image.Resampling.LANCZOS)
        x = index * THUMB[0]
        board.paste(image, (x, label_h))
        draw.text((x + 8, 5), label, font=font, fill="#f4ead1")
    board.save(target, format="PNG", optimize=False, compress_level=9)


def main() -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    copies = {
        ROOT / "docs/qa/evidence/status/2026-07-17_v1_prebaseline_normal.png": OUT / "2026-07-17_r5b_before_normal.png",
        ROOT / "docs/qa/evidence/status/2026-07-17_v1_prebaseline_hard.png": OUT / "2026-07-17_r5b_before_hard.png",
        Path("/tmp/tsuri_status_normal.png"): OUT / "2026-07-17_r5b_after_normal.png",
        Path("/tmp/tsuri_status_hard.png"): OUT / "2026-07-17_r5b_after_hard.png",
        Path("/tmp/tsuri_status_long_content.png"): OUT / "2026-07-17_r5b_long_content.png",
        Path("/tmp/tsuri_status_title_overlay.png"): OUT / "2026-07-17_r5b_title_overlay.png",
    }
    for source, target in copies.items():
        _copy_checked(source, target)
    shutil.copyfile(
        "/tmp/tsuri_status_normal_compare.png",
        OUT / "2026-07-17_r5b_after_normal_reference_compare.png",
    )
    shutil.copyfile(
        "/tmp/tsuri_status_hard_compare.png",
        OUT / "2026-07-17_r5b_after_hard_reference_compare.png",
    )

    normal_set = [
        ("BEFORE", OUT / "2026-07-17_r5b_before_normal.png"),
        ("AFTER", OUT / "2026-07-17_r5b_after_normal.png"),
        ("REFERENCE", REFERENCE),
    ]
    _thumbnail_board(normal_set, OUT / "2026-07-17_r5b_thumbnail_compare.png")
    _thumbnail_board(normal_set, OUT / "2026-07-17_r5b_gray_compare.png", grayscale=True)
    print("status R5-B evidence built")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
