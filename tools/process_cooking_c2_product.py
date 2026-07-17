#!/usr/bin/env python3
"""Adopt the authored COOK-C2 source into the MEAL_RESULT product slot.

The candidate processor remains a QA/intermediate owner.  This script is the
only writer for the adopted production background and provides a read-only
check suitable for validate_project.sh.
"""

from __future__ import annotations

import argparse
import hashlib
import os
from pathlib import Path
import shutil
import sys
import tempfile

from PIL import Image

from process_cooking_c2_candidate import process_source, validate_candidate


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tools/source_assets/cooking/c2_meal_scene_bg_source.png"
PRODUCT_DIR = ROOT / "assets/showcase/cooking"
PRODUCT_NAME = "meal_scene_bg.png"
PRODUCT = PRODUCT_DIR / PRODUCT_NAME


def _expected_product() -> Image.Image:
    candidate = process_source(SOURCE).convert("RGBA")
    candidate.load()
    validate_candidate(candidate)
    return candidate


def _decoded_digest(image: Image.Image) -> str:
    return hashlib.sha256(image.tobytes()).hexdigest()


def _file_and_decoded_digest(path: Path) -> tuple[str, str]:
    file_digest = hashlib.sha256(path.read_bytes()).hexdigest()
    with Image.open(path) as source:
        image = source.copy()
        image.load()
    return file_digest, _decoded_digest(image)


def _atomic_save_if_changed(candidate: Image.Image, path: Path) -> bool:
    """Preserve identical bytes; atomically replace only genuine pixel drift."""
    candidate.load()
    if path.is_file():
        try:
            with Image.open(path) as source:
                existing = source.copy()
                existing.load()
            if (
                existing.size == candidate.size
                and existing.mode == candidate.mode
                and existing.tobytes() == candidate.tobytes()
            ):
                print(f"preserved pixel-identical {path}")
                return False
        except (OSError, ValueError):
            pass

    path.parent.mkdir(parents=True, exist_ok=True)
    output_mode = path.stat().st_mode & 0o777 if path.exists() else 0o644
    descriptor, temp_name = tempfile.mkstemp(
        prefix=f".{path.name}.", suffix=".tmp", dir=path.parent
    )
    temp_path = Path(temp_name)
    try:
        with os.fdopen(descriptor, "wb") as stream:
            candidate.save(stream, format="PNG", optimize=False, compress_level=9)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temp_path, output_mode)
        os.replace(temp_path, path)
    finally:
        temp_path.unlink(missing_ok=True)
    print(f"updated {path}")
    return True


def process_product() -> None:
    _atomic_save_if_changed(_expected_product(), PRODUCT)


def check_product(output_dir: Path = PRODUCT_DIR) -> list[str]:
    """Compare size, mode and decoded pixels without modifying the product."""
    expected = _expected_product()
    expected_hash = _decoded_digest(expected)
    path = output_dir / PRODUCT_NAME
    if not path.is_file():
        return [f"missing {path}; expected decoded={expected_hash}"]
    try:
        with Image.open(path) as source:
            actual = source.copy()
            actual.load()
    except (OSError, ValueError) as exc:
        return [f"unreadable {path}: {exc}; expected decoded={expected_hash}"]

    actual_hash = _decoded_digest(actual)
    if (
        actual.size != expected.size
        or actual.mode != expected.mode
        or actual.tobytes() != expected.tobytes()
    ):
        return [
            f"product mismatch {path}: expected size={expected.size} mode={expected.mode} "
            f"decoded={expected_hash}, actual size={actual.size} mode={actual.mode} "
            f"decoded={actual_hash}"
        ]
    return []


def verify_twice() -> None:
    process_product()
    first = _file_and_decoded_digest(PRODUCT)
    process_product()
    second = _file_and_decoded_digest(PRODUCT)
    if first != second:
        raise RuntimeError("C2 product changed file or decoded hashes on its second run")
    print(f"C2 product deterministic file={second[0]} decoded={second[1]}")


def check_self_test() -> None:
    """Prove read-only checking catches isolated RGB/alpha corruption."""
    with tempfile.TemporaryDirectory(prefix="cooking-c2-product-check-") as temp_name:
        isolated = Path(temp_name)
        shutil.copy2(PRODUCT, isolated / PRODUCT_NAME)
        clean_failures = check_product(isolated)
        if clean_failures:
            raise RuntimeError(f"C2 clean isolated check failed: {clean_failures}")

        corrupt_path = isolated / PRODUCT_NAME
        for channel_name, channel_index in (("RGB", 0), ("alpha", 3)):
            shutil.copy2(PRODUCT, corrupt_path)
            with Image.open(corrupt_path) as source:
                corrupt = source.convert("RGBA")
                corrupt.load()
            pixel = list(corrupt.getpixel((0, 0)))
            pixel[channel_index] = (pixel[channel_index] + 1) % 256
            corrupt.putpixel((0, 0), tuple(pixel))
            corrupt.save(corrupt_path, format="PNG", optimize=False, compress_level=9)
            before_bytes = corrupt_path.read_bytes()
            before_mtime = corrupt_path.stat().st_mtime_ns

            failures = check_product(isolated)
            if not failures:
                raise RuntimeError(f"C2 isolated {channel_name} drift was not detected")
            if (
                corrupt_path.read_bytes() != before_bytes
                or corrupt_path.stat().st_mtime_ns != before_mtime
            ):
                raise RuntimeError(
                    f"C2 read-only check mutated {channel_name}-corrupt isolated product"
                )
        print(
            "C2 product read-only check self-test: ok "
            "(RGB+alpha drift detected, sha256/mtime unchanged)"
        )


def main() -> None:
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--verify-twice", action="store_true")
    mode.add_argument("--check", action="store_true")
    mode.add_argument("--check-self-test", action="store_true")
    parser.add_argument(
        "--output-dir",
        type=Path,
        help="alternate product directory for --check isolated regression tests",
    )
    args = parser.parse_args()

    if args.check:
        failures = check_product(args.output_dir or PRODUCT_DIR)
        if failures:
            for failure in failures:
                print(f"FAIL: {failure}", file=sys.stderr)
            raise SystemExit(1)
        print("C2 product check: ok (size/mode/decoded RGBA, read-only)")
        return
    if args.check_self_test:
        if args.output_dir is not None:
            parser.error("--output-dir is only valid with --check")
        check_self_test()
        return
    if args.output_dir is not None:
        parser.error("--output-dir is only valid with --check")
    if args.verify_twice:
        verify_twice()
    else:
        process_product()


if __name__ == "__main__":
    main()
