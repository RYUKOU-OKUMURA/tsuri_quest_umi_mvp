#!/usr/bin/env python3
"""TACKLE-T1の同一状態before/afterと縮小比較を保存する。"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ROOT / "docs/qa/evidence/tackle_shop"
REFERENCE = ROOT / "reference/09_tackle_shop_rod_mockup.png"
BEFORE = Path("/tmp/tsuri_tackle_shop_rod_before.png")
AFTER = Path("/tmp/tsuri_tackle_shop_rod.png")
EXPANDED_BEFORE = Path("/tmp/tsuri_tackle_shop_rod_expanded_before.png")
EXPANDED_AFTER = Path("/tmp/tsuri_tackle_shop_rod_expanded.png")
DETAIL_RECT = (848, 196, 1188, 380)
DATE_PREFIX = "2026-07-18_tackle_t1_marlin"


def _open(path: Path) -> Image.Image:
    if not path.is_file():
        raise FileNotFoundError(path)
    with Image.open(path) as opened:
        opened.load()
        return opened.convert("RGBA")


def _side_by_side(images: list[Image.Image], gap: int = 8) -> Image.Image:
    width = sum(image.width for image in images) + gap * (len(images) - 1)
    height = max(image.height for image in images)
    board = Image.new("RGBA", (width, height), (7, 17, 28, 255))
    x = 0
    for image in images:
        board.alpha_composite(image, (x, 0))
        x += image.width + gap
    return board


def _write(path: Path, image: Image.Image) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, format="PNG", optimize=False, compress_level=9)
    print(path)


def main() -> None:
    before = _open(BEFORE)
    after = _open(AFTER)
    expanded_before = _open(EXPANDED_BEFORE)
    expanded_after = _open(EXPANDED_AFTER)
    reference = _open(REFERENCE)
    if before.size != after.size or before.size != (1280, 720):
        raise ValueError(f"T1 full captures must be identical 1280x720: {before.size} / {after.size}")
    if expanded_before.size != expanded_after.size:
        raise ValueError("T1 expanded captures must share the same viewport")

    _write(EVIDENCE / f"{DATE_PREFIX}_before_after.png", _side_by_side([before, after]))

    thumb_size = (320, 180)
    thumb_before = ImageOps.contain(before, thumb_size, Image.Resampling.LANCZOS)
    thumb_after = ImageOps.contain(after, thumb_size, Image.Resampling.LANCZOS)
    thumb_reference = ImageOps.contain(reference, thumb_size, Image.Resampling.LANCZOS)
    _write(
        EVIDENCE / f"{DATE_PREFIX}_before_after_reference_320x180.png",
        _side_by_side([thumb_before, thumb_after, thumb_reference], gap=4),
    )

    detail_before = before.crop(DETAIL_RECT)
    detail_after = after.crop(DETAIL_RECT)
    _write(EVIDENCE / f"{DATE_PREFIX}_detail_before_after.png", _side_by_side([detail_before, detail_after]))

    _write(
        EVIDENCE / f"{DATE_PREFIX}_expanded_before_after.png",
        _side_by_side([expanded_before, expanded_after]),
    )


if __name__ == "__main__":
    main()
