#!/usr/bin/env python3
"""C3 EXP_GAIN祝祭光背のsource→product決定処理。"""

from __future__ import annotations

import argparse
import hashlib
import os
import tempfile
from pathlib import Path
from unittest.mock import patch

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tools/source_assets/cooking/c3_exp_burst_source.png"
PRODUCT = ROOT / "assets/showcase/cooking/exp_burst_frame.png"
PRODUCT_SIZE = (760, 220)


def _alpha_for_pixel(red: int, green: int, blue: int) -> int:
    """生成画像に残った灰色checkerboardだけを透明化する。"""
    chroma = max(red, green, blue) - min(red, green, blue)
    luminance = (red * 299 + green * 587 + blue * 114) // 1000
    if chroma <= 6 and luminance <= 214:
        return 0
    color_alpha = max(0, (chroma - 3) * 5)
    light_alpha = max(0, (luminance - 214) * 7)
    return min(255, max(color_alpha, light_alpha))


def build_product(source_path: Path = SOURCE) -> Image.Image:
    source = Image.open(source_path).convert("RGB")
    resized = source.resize(PRODUCT_SIZE, Image.Resampling.LANCZOS)
    output = Image.new("RGBA", PRODUCT_SIZE, (0, 0, 0, 0))
    source_pixels = resized.load()
    output_pixels = output.load()
    for y in range(PRODUCT_SIZE[1]):
        for x in range(PRODUCT_SIZE[0]):
            red, green, blue = source_pixels[x, y]
            alpha = _alpha_for_pixel(red, green, blue)
            if alpha == 0:
                output_pixels[x, y] = (0, 0, 0, 0)
                continue
            chroma = max(red, green, blue) - min(red, green, blue)
            if chroma <= 10:
                # 白いsparkleの芯は紙色寄りへ揃え、灰色checkerboardの色を残さない。
                color = (255, 239, 190)
            else:
                color = (red, green, blue)
            output_pixels[x, y] = (*color, alpha)
    return output


def _rgba_sha256(image: Image.Image) -> str:
    return hashlib.sha256(image.convert("RGBA").tobytes()).hexdigest()


def _write_if_changed(image: Image.Image, output_path: Path) -> str:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    expected = image.convert("RGBA")
    if output_path.is_file():
        try:
            current = Image.open(output_path).convert("RGBA")
            if current.size == expected.size and current.tobytes() == expected.tobytes():
                return "preserved pixel-identical"
        except OSError:
            pass
    fd, temp_name = tempfile.mkstemp(prefix=f".{output_path.name}.", suffix=".tmp", dir=output_path.parent)
    os.close(fd)
    temp_path = Path(temp_name)
    try:
        expected.save(temp_path, format="PNG", optimize=False)
        with temp_path.open("rb") as handle:
            os.fsync(handle.fileno())
        os.replace(temp_path, output_path)
    finally:
        temp_path.unlink(missing_ok=True)
    return "written"


def _check(output_path: Path, expected: Image.Image) -> None:
    if not output_path.is_file():
        raise SystemExit(f"missing product: {output_path}")
    try:
        actual = Image.open(output_path).convert("RGBA")
    except OSError as exc:
        raise SystemExit(f"unreadable product: {output_path}: {exc}") from exc
    if actual.size != PRODUCT_SIZE:
        raise SystemExit(f"unexpected product size: {actual.size}")
    if actual.tobytes() != expected.tobytes():
        raise SystemExit(
            "product decoded RGBA differs: "
            f"expected={_rgba_sha256(expected)} actual={_rgba_sha256(actual)}"
        )
    if actual.getpixel((0, 0))[3] != 0 or actual.getpixel((PRODUCT_SIZE[0] - 1, PRODUCT_SIZE[1] - 1))[3] != 0:
        raise SystemExit("product corners must remain transparent")
    print(f"C3 product check passed: {_rgba_sha256(actual)}")


def _self_test() -> None:
    """隔離tmpだけでprocessorの保存・破損・失敗時保護を検証する。"""
    with tempfile.TemporaryDirectory(prefix="tsuri_cooking_c3_product_test_") as temp_dir:
        root = Path(temp_dir)
        output = root / "exp_burst_frame.png"
        expected = Image.new("RGBA", PRODUCT_SIZE, (0, 0, 0, 0))
        expected.putpixel((PRODUCT_SIZE[0] // 2, PRODUCT_SIZE[1] // 2), (255, 239, 190, 220))
        expected.save(output, format="PNG", optimize=False)
        original_bytes = output.read_bytes()

        status = _write_if_changed(expected, output)
        if status != "preserved pixel-identical" or output.read_bytes() != original_bytes:
            raise AssertionError("decoded-identical product must preserve existing bytes")

        changed = expected.copy()
        changed.putpixel((PRODUCT_SIZE[0] // 2 + 1, PRODUCT_SIZE[1] // 2), (39, 193, 164, 190))
        status = _write_if_changed(changed, output)
        if status != "written" or output.read_bytes() == original_bytes:
            raise AssertionError("decoded-different product must be rewritten")
        if Image.open(output).convert("RGBA").tobytes() != changed.tobytes():
            raise AssertionError("rewritten product pixels differ from the candidate")

        corrupted = changed.copy()
        corrupted.putpixel((PRODUCT_SIZE[0] // 2, PRODUCT_SIZE[1] // 2), (240, 30, 30, 255))
        corrupted.save(output, format="PNG", optimize=False)
        corrupted_bytes = output.read_bytes()
        try:
            _check(output, expected)
        except SystemExit:
            pass
        else:
            raise AssertionError("decoded-corrupt product must be detected")
        if output.read_bytes() != corrupted_bytes:
            raise AssertionError("check must not repair or overwrite a corrupt product")

        output.write_bytes(b"not-a-png")
        unreadable_bytes = output.read_bytes()
        try:
            _check(output, expected)
        except SystemExit:
            pass
        else:
            raise AssertionError("unreadable product must be detected")
        if output.read_bytes() != unreadable_bytes:
            raise AssertionError("check must not overwrite an unreadable product")

        output.write_bytes(original_bytes)
        replacement = expected.copy()
        replacement.putpixel((PRODUCT_SIZE[0] // 2, PRODUCT_SIZE[1] // 2), (255, 180, 60, 255))
        try:
            with patch.object(os, "replace", side_effect=OSError("self-test save failure")):
                _write_if_changed(replacement, output)
        except OSError:
            pass
        else:
            raise AssertionError("save failure must be surfaced")
        if output.read_bytes() != original_bytes:
            raise AssertionError("save failure must preserve the old product bytes")
        if list(root.glob(f".{output.name}.*.tmp")):
            raise AssertionError("save failure must clean up the temporary product")

    print("C3 product self-test passed: byte preservation, rewrite, corruption, failure cleanup")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=SOURCE)
    parser.add_argument("--output", type=Path, default=PRODUCT)
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.check and args.self_test:
        parser.error("--check and --self-test cannot be combined")
    if args.self_test:
        _self_test()
        return
    product = build_product(args.source)
    if args.check:
        _check(args.output, product)
        return
    print(f"{args.output}: {_write_if_changed(product, args.output)}")
    print(f"decoded RGBA sha256: {_rgba_sha256(product)}")


if __name__ == "__main__":
    main()
