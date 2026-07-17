#!/usr/bin/env python3
"""Build COOK-C2 adoption evidence and enforce non-MEAL_RESULT pixel regression."""

from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import tempfile

from PIL import Image, ImageChops, ImageOps


ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ROOT / "docs/qa/evidence/cooking"
REFERENCE = ROOT / "reference" / "cooking_flow" / "02_meal_result_concept.png"
PREFIX = "2026-07-17_c2"
SIZE = (1280, 720)

BEFORE_RESULT = EVIDENCE / "2026-07-17_v2_prebaseline_result.png"
AFTER_RESULT = Path("/tmp/tsuri_cooking_result.png")
FIRST_LONG = Path("/tmp/tsuri_cooking_c2_first_long.png")
REPEAT_LONG = Path("/tmp/tsuri_cooking_c2_repeat_long.png")
REGRESSION_STATES = {
    "select": (EVIDENCE / "2026-07-17_v2_prebaseline_select.png", Path("/tmp/tsuri_cooking_select.png")),
    "exp": (EVIDENCE / "2026-07-17_v2_prebaseline_exp.png", Path("/tmp/tsuri_cooking_exp.png")),
    "levelup": (EVIDENCE / "2026-07-17_v2_prebaseline_levelup.png", Path("/tmp/tsuri_cooking_levelup.png")),
    "status": (EVIDENCE / "2026-07-17_v2_prebaseline_status.png", Path("/tmp/tsuri_cooking_status.png")),
}


def _open_rgba(path: Path) -> Image.Image:
    if not path.is_file():
        raise FileNotFoundError(path)
    with Image.open(path) as source:
        image = source.convert("RGBA")
        image.load()
    if image.size != SIZE:
        raise ValueError(f"{path} must be {SIZE}, got {image.size}")
    return image


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _save_if_changed(image: Image.Image, path: Path) -> None:
    image.load()
    if path.is_file():
        with Image.open(path) as source:
            existing = source.convert(image.mode)
            existing.load()
        if existing.size == image.size and existing.tobytes() == image.tobytes():
            return
    descriptor, temp_name = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=path.parent)
    temp_path = Path(temp_name)
    try:
        with os.fdopen(descriptor, "wb") as stream:
            image.save(stream, format="PNG", optimize=False, compress_level=9)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temp_path, path)
    finally:
        temp_path.unlink(missing_ok=True)


def _triptych(images: list[Image.Image], tile_size: tuple[int, int]) -> Image.Image:
    tiles = [image.resize(tile_size, Image.Resampling.LANCZOS) for image in images]
    board = Image.new("RGBA", (tile_size[0] * len(tiles), tile_size[1]), (7, 17, 28, 255))
    for index, tile in enumerate(tiles):
        board.paste(tile, (index * tile_size[0], 0))
    return board


def main() -> None:
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    before = _open_rgba(BEFORE_RESULT)
    after = _open_rgba(AFTER_RESULT)
    first_long = _open_rgba(FIRST_LONG)
    repeat_long = _open_rgba(REPEAT_LONG)
    with Image.open(REFERENCE) as source:
        reference = ImageOps.fit(source.convert("RGBA"), SIZE, method=Image.Resampling.LANCZOS)

    regression: dict[str, object] = {}
    for state, (baseline_path, current_path) in REGRESSION_STATES.items():
        baseline = _open_rgba(baseline_path)
        current = _open_rgba(current_path)
        if baseline.tobytes() != current.tobytes():
            bbox = ImageChops.difference(baseline.convert("RGB"), current.convert("RGB")).getbbox()
            raise RuntimeError(f"C2 changed non-MEAL_RESULT state {state}: bbox={bbox}")
        regression[state] = {
            "baseline_sha256": _sha256(baseline_path),
            "after_sha256": _sha256(current_path),
            "decoded_pixels_equal": True,
        }
        _save_if_changed(current, EVIDENCE / f"{PREFIX}_regression_{state}.png")

    result_difference = ImageChops.difference(before.convert("RGB"), after.convert("RGB"))
    result_bbox = result_difference.getbbox()
    if result_bbox is None:
        raise RuntimeError("C2 MEAL_RESULT after is pixel-identical to before; product is not visible")

    _save_if_changed(after, EVIDENCE / f"{PREFIX}_after_result.png")
    _save_if_changed(first_long, EVIDENCE / f"{PREFIX}_first_long.png")
    _save_if_changed(repeat_long, EVIDENCE / f"{PREFIX}_repeat_long.png")
    _save_if_changed(
        _triptych([before, after, reference], SIZE),
        EVIDENCE / f"{PREFIX}_full_before_after_reference.png",
    )
    _save_if_changed(
        _triptych([before, after, reference], (320, 180)),
        EVIDENCE / f"{PREFIX}_thumbnail_before_after_reference.png",
    )

    report = {
        "state": "MEAL_RESULT",
        "order": ["before", "after", "reference"],
        "before_sha256": _sha256(BEFORE_RESULT),
        "after_sha256": _sha256(AFTER_RESULT),
        "reference_sha256": _sha256(REFERENCE),
        "result_difference_bbox": list(result_bbox),
        "required_fixtures": {
            "first_time_bonus_four_cards_long_buff": _sha256(FIRST_LONG),
            "repeat_long_dish_and_effect": _sha256(REPEAT_LONG),
        },
        "non_meal_result_regression": regression,
    }
    (EVIDENCE / f"{PREFIX}_report.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
