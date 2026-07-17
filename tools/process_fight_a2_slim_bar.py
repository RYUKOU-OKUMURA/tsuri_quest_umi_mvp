#!/usr/bin/env python3
"""FIGHT-A2のauthored下段スリムバーを決定的に製品化する。"""

from __future__ import annotations

import argparse
import hashlib
import os
import tempfile
from pathlib import Path

from PIL import Image, ImageChops, ImageEnhance, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tools/source_assets/underwater/fight_a2_slim_bar_frame_source.png"
OUTPUT = ROOT / "assets/showcase/underwater/fight_slim_bar_frame.png"
SOURCE_SIZE = (2119, 742)
OUTPUT_SIZE = (1280, 140)


def _decoded_hash(image: Image.Image) -> str:
    payload = image.mode.encode() + b"\0" + str(image.size).encode() + b"\0" + image.tobytes()
    return hashlib.sha256(payload).hexdigest()


def _panel_bbox(source: Image.Image) -> tuple[int, int, int, int]:
    # imagegen sourceは黒いキャンバス上の単一パネル。固定しきい値で
    # authored shellだけを抽出し、reference/runtime画素は一切読まない。
    mask = source.convert("L").point(lambda value: 255 if value > 12 else 0)
    bbox = mask.getbbox()
    if bbox is None:
        raise ValueError("FIGHT-A2 source has no visible authored panel")
    left, top, right, bottom = bbox
    if right - left < 1800 or bottom - top < 220:
        raise ValueError(f"FIGHT-A2 authored panel bbox is implausibly small: {bbox}")
    return (max(0, left - 4), max(0, top - 4), min(source.width, right + 4), min(source.height, bottom + 4))


def build_product(source_path: Path = SOURCE) -> Image.Image:
    if not source_path.is_file():
        raise FileNotFoundError(f"missing FIGHT-A2 authored source: {source_path}")
    with Image.open(source_path) as opened:
        opened.load()
        if opened.size != SOURCE_SIZE:
            raise ValueError(f"FIGHT-A2 source must be {SOURCE_SIZE}, got {opened.size}")
        source = opened.convert("RGB")

    panel = source.crop(_panel_bbox(source))
    product = panel.resize(OUTPUT_SIZE, Image.Resampling.LANCZOS)
    # 小寸法で木目を残しながら、runtime文字・ゲージ背面は静かに保つ。
    product = ImageEnhance.Contrast(product).enhance(1.04)
    product = ImageEnhance.Color(product).enhance(0.92)
    return product.convert("RGBA")


def validate_product(product: Image.Image) -> None:
    if product.mode != "RGBA" or product.size != OUTPUT_SIZE:
        raise ValueError(f"FIGHT-A2 product must be RGBA {OUTPUT_SIZE}, got {product.mode} {product.size}")
    if product.getchannel("A").getextrema() != (255, 255):
        raise ValueError("FIGHT-A2 product must be fully opaque")
    # 3つのruntime content wellが暗く、文字・ゲージを阻害しないことを固定。
    for name, box in {
        "tension": (48, 35, 405, 117),
        "action": (465, 30, 815, 117),
        "stamina": (875, 35, 1232, 117),
    }.items():
        gray = ImageOps.grayscale(product.crop(box))
        mean = sum(value * count for value, count in enumerate(gray.histogram())) / (gray.width * gray.height)
        if mean > 52.0:
            raise ValueError(f"FIGHT-A2 {name} well is too bright for runtime content: {mean:.2f}")


def _same_pixels(path: Path, candidate: Image.Image) -> bool:
    if not path.is_file():
        return False
    try:
        with Image.open(path) as opened:
            opened.load()
            current = opened.convert("RGBA")
        return (
            current.size == candidate.size
            and ImageChops.difference(current.convert("RGB"), candidate.convert("RGB")).getbbox() is None
        )
    except (OSError, ValueError):
        return False


def _display_path(path: Path) -> str:
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


def write_if_changed(path: Path, candidate: Image.Image) -> bool:
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


def check_product(source_path: Path, output_path: Path) -> None:
    expected = build_product(source_path)
    validate_product(expected)
    if not _same_pixels(output_path, expected):
        raise ValueError(f"FIGHT-A2 product is missing or stale: {output_path}")
    print(f"FIGHT-A2 product check passed: {output_path} {_decoded_hash(expected)}")


def self_test() -> None:
    expected = build_product(SOURCE)
    validate_product(expected)
    with tempfile.TemporaryDirectory(prefix="fight_a2_processor_") as directory:
        isolated = Path(directory) / "fight_slim_bar_frame.png"
        write_if_changed(isolated, expected)
        check_product(SOURCE, isolated)
        corrupted = expected.copy()
        r, g, b, a = corrupted.getpixel((640, 70))
        corrupted.putpixel((640, 70), ((r + 1) % 256, g, b, a))
        corrupted.save(isolated, format="PNG")
        try:
            check_product(SOURCE, isolated)
        except ValueError:
            pass
        else:
            raise AssertionError("FIGHT-A2 self-test failed to detect a corrupted isolated product")
    print("FIGHT-A2 processor self-test passed (corruption rejected)")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=SOURCE)
    parser.add_argument("--output", type=Path, default=OUTPUT)
    parser.add_argument("--check", action="store_true", help="read-only product verification")
    parser.add_argument("--self-test", action="store_true", help="verify isolated corruption detection")
    args = parser.parse_args()
    if args.self_test:
        self_test()
        return
    if args.check:
        check_product(args.source, args.output)
        return
    product = build_product(args.source)
    validate_product(product)
    write_if_changed(args.output, product)


if __name__ == "__main__":
    main()
