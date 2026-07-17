#!/usr/bin/env python3
"""FIGHT-A2のauthored下段スリムバーを決定的に製品化する。"""

from __future__ import annotations

import argparse
import hashlib
import os
import tempfile
from pathlib import Path

from PIL import Image, ImageEnhance, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tools/source_assets/underwater/fight_a2_slim_bar_frame_source.png"
OUTPUT = ROOT / "assets/showcase/underwater/fight_slim_bar_frame.png"
SOURCE_SIZE = (2119, 742)
OUTPUT_SIZE = (1280, 140)
COLOR_KEEP_NUMERATOR = 92
COLOR_DENOMINATOR = 100


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


def _desaturate_rgb(image: Image.Image) -> Image.Image:
    """Pillowのversion依存blend丸めを避け、色92%を整数演算で固定する。"""
    if image.mode != "RGB":
        raise ValueError(f"FIGHT-A2 desaturation expects RGB, got {image.mode}")
    grayscale = image.convert("L").tobytes()
    source = image.tobytes()
    result = bytearray(len(source))
    gray_numerator = COLOR_DENOMINATOR - COLOR_KEEP_NUMERATOR
    for pixel_index, gray in enumerate(grayscale):
        channel_index = pixel_index * 3
        for offset in range(3):
            value = source[channel_index + offset]
            result[channel_index + offset] = (
                gray * gray_numerator + value * COLOR_KEEP_NUMERATOR
            ) // COLOR_DENOMINATOR
    return Image.frombytes("RGB", image.size, bytes(result))


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
    product = _desaturate_rgb(product)
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
            current = opened.copy()
        return (
            current.mode == candidate.mode
            and current.size == candidate.size
            and current.tobytes() == candidate.tobytes()
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
    if not output_path.is_file():
        raise ValueError(f"FIGHT-A2 product is missing or stale: {output_path}")
    try:
        with Image.open(output_path) as opened:
            opened.load()
            actual = opened.copy()
    except (OSError, ValueError) as error:
        raise ValueError(f"FIGHT-A2 product is unreadable: {output_path}") from error
    validate_product(actual)
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
        preserved_bytes = isolated.read_bytes()
        if write_if_changed(isolated, expected):
            raise AssertionError("decoded-identical RGBA product was rewritten")
        if isolated.read_bytes() != preserved_bytes:
            raise AssertionError("decoded-identical RGBA product bytes changed")

        corruptions: dict[str, Image.Image] = {
            "RGB mode": expected.convert("RGB"),
            "size": expected.resize((OUTPUT_SIZE[0] - 1, OUTPUT_SIZE[1])),
        }
        alpha_drift = expected.copy()
        r, g, b, _a = alpha_drift.getpixel((640, 70))
        alpha_drift.putpixel((640, 70), (r, g, b, 254))
        corruptions["alpha drift"] = alpha_drift
        pixel_drift = expected.copy()
        r, g, b, a = pixel_drift.getpixel((640, 70))
        pixel_drift.putpixel((640, 70), ((r + 1) % 256, g, b, a))
        corruptions["pixel drift"] = pixel_drift

        for label, corrupted in corruptions.items():
            corrupted.save(isolated, format="PNG")
            try:
                check_product(SOURCE, isolated)
            except ValueError:
                pass
            else:
                raise AssertionError(f"FIGHT-A2 self-test failed to detect {label}")
            if not write_if_changed(isolated, expected):
                raise AssertionError(f"FIGHT-A2 self-test failed to repair {label}")
            check_product(SOURCE, isolated)

        # 書き込み失敗時は旧outputを置換せず、同一directoryの一時ファイルも残さない。
        expected.convert("RGB").save(isolated, format="PNG")
        old_bytes = isolated.read_bytes()
        temporary_before = set(isolated.parent.glob(f".{isolated.stem}.*.png"))

        class FailingCandidate:
            mode = "RGBA"
            size = OUTPUT_SIZE

            @staticmethod
            def save(*_args: object, **_kwargs: object) -> None:
                raise OSError("isolated save failure")

        try:
            write_if_changed(isolated, FailingCandidate())  # type: ignore[arg-type]
        except OSError:
            pass
        else:
            raise AssertionError("FIGHT-A2 self-test did not propagate isolated save failure")
        if isolated.read_bytes() != old_bytes:
            raise AssertionError("FIGHT-A2 self-test replaced old output after save failure")
        temporary_after = set(isolated.parent.glob(f".{isolated.stem}.*.png"))
        if temporary_after != temporary_before:
            raise AssertionError("FIGHT-A2 self-test left a temporary file after save failure")
    print("FIGHT-A2 processor self-test passed (mode/alpha/size/pixels rejected and repaired)")


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
