#!/usr/bin/env python3
"""TACKLE-T1のmarlin詳細絵を既存sheetの1セルだけへ統合する。"""

from __future__ import annotations

import argparse
import hashlib
import os
import tempfile
from pathlib import Path

from PIL import Image, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tools/source_assets/tackle_shop/t1_marlin_detail_source.png"
OUTPUT = ROOT / "assets/showcase/tackle_shop/shop_detail_item_sheet.png"
CELL_SIZE = (384, 224)
CELL_COUNT = 11
TARGET_INDEX = 4  # ITEM_ICON_INDEX の marlin
EXPECTED_SOURCE_SIZE = (1641, 958)
BACKGROUND_CHROMA_MAX = 8
BACKGROUND_LUMA_MIN = 220


def _decoded_hash(image: Image.Image) -> str:
    payload = image.mode.encode() + b"\0" + str(image.size).encode() + b"\0" + image.tobytes()
    return hashlib.sha256(payload).hexdigest()


def _background_mask(source: Image.Image) -> Image.Image:
    if source.mode != "RGB":
        raise ValueError(f"T1 source must be RGB before background removal, got {source.mode}")
    mask = Image.new("L", source.size, 0)
    source_pixels = source.load()
    mask_pixels = mask.load()
    for y in range(source.height):
        for x in range(source.width):
            red, green, blue = source_pixels[x, y]
            chroma = max(red, green, blue) - min(red, green, blue)
            is_checker_background = chroma <= BACKGROUND_CHROMA_MAX and min(red, green, blue) >= BACKGROUND_LUMA_MIN
            mask_pixels[x, y] = 0 if is_checker_background else 255
    # 1px dilation removes the light checker fringe around the authored silhouette
    # without touching the product's dark/navy body. The operation is deterministic.
    return mask.filter(ImageFilter.MaxFilter(3))


def _build_product_cell(source_path: Path = SOURCE) -> Image.Image:
    if not source_path.is_file():
        raise FileNotFoundError(f"missing T1 source: {source_path}")
    with Image.open(source_path) as opened:
        opened.load()
        if opened.size != EXPECTED_SOURCE_SIZE:
            raise ValueError(f"T1 source must be {EXPECTED_SOURCE_SIZE}, got {opened.size}")
        source = opened.convert("RGB")

    alpha = _background_mask(source)
    bbox = alpha.getbbox()
    if bbox is None or bbox[2] - bbox[0] < 1200 or bbox[3] - bbox[1] < 700:
        raise ValueError(f"T1 source silhouette bbox is implausibly small: {bbox}")

    rgba = source.convert("RGBA")
    rgba.putalpha(alpha)
    cropped = rgba.crop(bbox)
    fitted = Image.new("RGBA", CELL_SIZE, (0, 0, 0, 0))
    scale = min(CELL_SIZE[0] / cropped.width, CELL_SIZE[1] / cropped.height)
    resized = cropped.resize(
        (max(1, round(cropped.width * scale)), max(1, round(cropped.height * scale))),
        Image.Resampling.LANCZOS,
    )
    fitted.alpha_composite(resized, ((CELL_SIZE[0] - resized.width) // 2, (CELL_SIZE[1] - resized.height) // 2))
    return fitted


def _split_cells(sheet: Image.Image) -> list[Image.Image]:
    if sheet.mode != "RGBA" or sheet.size != (CELL_SIZE[0] * CELL_COUNT, CELL_SIZE[1]):
        raise ValueError(f"detail sheet must be RGBA {(CELL_SIZE[0] * CELL_COUNT, CELL_SIZE[1])}, got {sheet.mode} {sheet.size}")
    return [sheet.crop((index * CELL_SIZE[0], 0, (index + 1) * CELL_SIZE[0], CELL_SIZE[1])) for index in range(CELL_COUNT)]


def _build_sheet(output_path: Path = OUTPUT, source_path: Path = SOURCE) -> tuple[Image.Image, list[str], str]:
    if not output_path.is_file():
        raise FileNotFoundError(f"missing detail sheet: {output_path}")
    with Image.open(output_path) as opened:
        opened.load()
        current = opened.convert("RGBA")
    cells = _split_cells(current)
    before_hashes = [_decoded_hash(cell) for cell in cells]
    cells[TARGET_INDEX] = _build_product_cell(source_path)
    sheet = Image.new("RGBA", current.size, (0, 0, 0, 0))
    for index, cell in enumerate(cells):
        sheet.alpha_composite(cell, (index * CELL_SIZE[0], 0))
    return sheet, before_hashes, _decoded_hash(cells[TARGET_INDEX])


def _write_if_changed(path: Path, candidate: Image.Image) -> bool:
    if _same_pixels(path, candidate):
        print(f"preserved pixel-identical {_display_path(path)} {_decoded_hash(candidate)}")
        return False
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(dir=path.parent, prefix=f".{path.stem}.", suffix=".png", delete=False) as stream:
            temporary_path = Path(stream.name)
        candidate.save(temporary_path, format="PNG", optimize=False, compress_level=9)
        os.replace(temporary_path, path)
        temporary_path = None
    finally:
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)
    print(f"updated {_display_path(path)} {_decoded_hash(candidate)}")
    return True


def _same_pixels(path: Path, candidate: Image.Image) -> bool:
    if not path.is_file():
        return False
    try:
        with Image.open(path) as opened:
            opened.load()
            current = opened.copy()
        return current.mode == candidate.mode and current.size == candidate.size and current.tobytes() == candidate.tobytes()
    except (OSError, ValueError, AttributeError):
        return False


def _display_path(path: Path) -> str:
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


def _validate_target_and_others(sheet: Image.Image, before_hashes: list[str], target_hash: str) -> None:
    cells = _split_cells(sheet)
    for index, cell in enumerate(cells):
        actual = _decoded_hash(cell)
        if index == TARGET_INDEX:
            if actual != target_hash:
                raise ValueError(f"T1 marlin target cell drifted: {actual} != {target_hash}")
        elif actual != before_hashes[index]:
            raise ValueError(f"T1 non-target cell changed at index {index}: {actual} != {before_hashes[index]}")


def check_product(source_path: Path = SOURCE, output_path: Path = OUTPUT) -> None:
    expected, before_hashes, target_hash = _build_sheet(output_path, source_path)
    # The current product is expected to contain the generated target; reconstructing
    # the comparison from its ten non-target cells prevents accidental full-sheet regeneration.
    with Image.open(output_path) as opened:
        opened.load()
        actual = opened.convert("RGBA")
    _split_cells(actual)
    actual_cells = _split_cells(actual)
    expected_cells = _split_cells(expected)
    for index in range(CELL_COUNT):
        if index == TARGET_INDEX:
            if actual_cells[index].tobytes() != expected_cells[index].tobytes():
                raise ValueError("T1 marlin target cell is stale")
        elif actual_cells[index].tobytes() != expected_cells[index].tobytes():
            raise ValueError(f"T1 sheet changed outside target cell at index {index}")
    _validate_target_and_others(expected, before_hashes, target_hash)
    print(f"TACKLE-T1 product check passed: {_display_path(output_path)} target={target_hash}")


def self_test() -> None:
    with Image.open(OUTPUT) as opened:
        opened.load()
        baseline = opened.convert("RGBA")
    baseline_cells = _split_cells(baseline)
    expected_target = _build_product_cell(SOURCE)
    before_hashes = [_decoded_hash(cell) for cell in baseline_cells]

    with tempfile.TemporaryDirectory(prefix="tackle_shop_t1_processor_") as directory:
        isolated = Path(directory) / OUTPUT.name
        # 製品が既に採用済みでも、隔離コピーの対象セルだけを壊して
        # target-only writerが実際に差分を適用する経路を必ず通す。
        isolated_baseline = baseline.copy()
        isolated_baseline.paste(Image.new("RGBA", CELL_SIZE, (0, 0, 0, 0)), (TARGET_INDEX * CELL_SIZE[0], 0))
        isolated_baseline.save(isolated, format="PNG", optimize=False, compress_level=9)
        expected, expected_before, target_hash = _build_sheet(isolated, SOURCE)
        _validate_target_and_others(expected, expected_before, target_hash)
        for index in range(CELL_COUNT):
            if index != TARGET_INDEX and expected_before[index] != before_hashes[index]:
                raise AssertionError(f"T1 self-test non-target baseline changed at index {index}")

        if not _write_if_changed(isolated, expected):
            raise AssertionError("T1 self-test failed to write isolated target cell")
        check_product(SOURCE, isolated)
        preserved_bytes = isolated.read_bytes()
        if _write_if_changed(isolated, expected):
            raise AssertionError("T1 decoded-identical sheet was rewritten")
        if isolated.read_bytes() != preserved_bytes:
            raise AssertionError("T1 identical sheet bytes changed")

        corrupted = expected.copy()
        corrupted.putpixel((TARGET_INDEX * CELL_SIZE[0] + 20, 20), (0, 0, 0, 255))
        corrupted.save(isolated, format="PNG", optimize=False, compress_level=9)
        try:
            check_product(SOURCE, isolated)
        except ValueError:
            pass
        else:
            raise AssertionError("T1 self-test failed to detect target-cell drift")

        repaired = expected.copy()
        repaired.save(isolated, format="PNG", optimize=False, compress_level=9)
        check_product(SOURCE, isolated)

        class FailingCandidate:
            mode = "RGBA"
            size = expected.size

            @staticmethod
            def save(*_args: object, **_kwargs: object) -> None:
                raise OSError("isolated save failure")

        old_bytes = isolated.read_bytes()
        temporary_before = set(isolated.parent.glob(f".{isolated.stem}.*.png"))
        try:
            _write_if_changed(isolated, FailingCandidate())  # type: ignore[arg-type]
        except OSError:
            pass
        else:
            raise AssertionError("T1 self-test did not propagate isolated save failure")
        if isolated.read_bytes() != old_bytes:
            raise AssertionError("T1 self-test replaced old sheet after save failure")
        if set(isolated.parent.glob(f".{isolated.stem}.*.png")) != temporary_before:
            raise AssertionError("T1 self-test left a temporary file")

    if expected_target.size != CELL_SIZE:
        raise AssertionError("T1 target cell size mismatch")
    print("TACKLE-T1 processor self-test passed (target-only integration, invariance, stale and atomic failure checks)")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=SOURCE)
    parser.add_argument("--output", type=Path, default=OUTPUT)
    parser.add_argument("--check", action="store_true", help="read-only product verification")
    parser.add_argument("--self-test", action="store_true", help="verify isolated integration and failure handling")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return
    if args.check:
        check_product(args.source, args.output)
        return
    candidate, before_hashes, target_hash = _build_sheet(args.output, args.source)
    _validate_target_and_others(candidate, before_hashes, target_hash)
    _write_if_changed(args.output, candidate)


if __name__ == "__main__":
    main()
