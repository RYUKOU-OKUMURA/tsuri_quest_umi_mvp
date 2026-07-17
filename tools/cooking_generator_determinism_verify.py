#!/usr/bin/env python3
"""Verify safe, deterministic publication of cooking showcase PNG products."""

from __future__ import annotations

import hashlib
import importlib.util
import json
import shutil
import tempfile
from pathlib import Path
from types import ModuleType
from unittest import mock

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
GENERATOR_PATH = ROOT / "tools" / "generate_cooking_showcase_assets.py"
PRODUCT_DIR = ROOT / "assets" / "showcase" / "cooking"
EXPECTED_PRODUCT_COUNT = 58


def load_generator() -> ModuleType:
    spec = importlib.util.spec_from_file_location("cooking_showcase_generator", GENERATOR_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"generatorを読み込めません: {GENERATOR_PATH}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def png_info(path: Path) -> dict[str, object]:
    raw = path.read_bytes()
    with Image.open(path) as image:
        mode = image.mode
        size = list(image.size)
        rgba = image.convert("RGBA").tobytes()
    return {
        "file_sha256": hashlib.sha256(raw).hexdigest(),
        "rgba_sha256": hashlib.sha256(rgba).hexdigest(),
        "size": size,
        "mode": mode,
    }


def product_manifest(directory: Path) -> dict[str, dict[str, object]]:
    return {path.name: png_info(path) for path in sorted(directory.glob("*.png"))}


def temp_products(directory: Path) -> list[Path]:
    return sorted(directory.glob(".*.png.*.tmp"))


def assert_no_temp_products(directory: Path) -> None:
    leftovers = temp_products(directory)
    if leftovers:
        raise AssertionError(f"PNG一時ファイルが残っています ({directory}): {leftovers}")


def copy_product_pngs(
    source_directory: Path,
    output_directory: Path,
    expected_manifest: dict[str, dict[str, object]],
) -> None:
    """Seed an isolated generator OUT with byte-identical production products."""
    output_directory.mkdir(parents=True, exist_ok=True)
    for name in expected_manifest:
        shutil.copyfile(source_directory / name, output_directory / name)
    copied_manifest = product_manifest(output_directory)
    if copied_manifest != expected_manifest:
        raise AssertionError("一時OUTへの製品PNG byte copyがproduction manifestと一致しません")


def verify_save_contract(generator: ModuleType) -> None:
    original_out = generator.OUT
    with tempfile.TemporaryDirectory(prefix="cooking-generator-save-contract-") as temp_dir:
        output_dir = Path(temp_dir)
        try:
            generator.OUT = output_dir

            identical_path = output_dir / "identical.png"
            identical = Image.new("RGBA", (4, 3), (12, 34, 56, 255))
            identical.save(identical_path, format="PNG", compress_level=0)
            identical_bytes = identical_path.read_bytes()
            generator.save(identical.copy(), identical_path.name)
            if identical_path.read_bytes() != identical_bytes:
                raise AssertionError("decoded同値PNGの既存bytesが保持されませんでした")

            size_only_path = output_dir / "size_only.png"
            Image.new("RGBA", (4, 3), (18, 28, 38, 255)).save(size_only_path, format="PNG")
            size_only_candidate = Image.new("RGBA", (3, 4), (18, 28, 38, 255))
            generator.save(size_only_candidate, size_only_path.name)
            with Image.open(size_only_path) as size_only_product:
                if size_only_product.size != size_only_candidate.size:
                    raise AssertionError("sizeだけ異なるcandidateがatomic更新されませんでした")

            mode_only_path = output_dir / "mode_only.png"
            Image.new("RGB", (3, 2), (44, 55, 66)).save(mode_only_path, format="PNG")
            mode_only_candidate = Image.new("RGBA", (3, 2), (44, 55, 66, 255))
            generator.save(mode_only_candidate, mode_only_path.name)
            with Image.open(mode_only_path) as mode_only_product:
                if mode_only_product.mode != mode_only_candidate.mode:
                    raise AssertionError("modeだけ異なるcandidateがatomic更新されませんでした")

            changed_path = output_dir / "changed.png"
            Image.new("RGBA", (3, 2), (80, 20, 10, 255)).save(changed_path, format="PNG")
            old_changed_bytes = changed_path.read_bytes()
            changed_candidate = Image.new("RGBA", (3, 2), (10, 90, 140, 255))
            generator.save(changed_candidate, changed_path.name)
            if changed_path.read_bytes() == old_changed_bytes:
                raise AssertionError("真の画素差がatomic更新されませんでした")
            with Image.open(changed_path) as changed_product:
                if changed_product.convert("RGBA").tobytes() != changed_candidate.tobytes():
                    raise AssertionError("atomic更新後のdecoded pixelsがcandidateと一致しません")

            missing_candidate = Image.new("RGBA", (2, 2), (1, 2, 3, 255))
            generator.save(missing_candidate, "missing.png")
            if not (output_dir / "missing.png").is_file():
                raise AssertionError("欠損productがatomic生成されませんでした")

            unreadable_path = output_dir / "unreadable.png"
            unreadable_path.write_bytes(b"not a png")
            unreadable_candidate = Image.new("RGBA", (2, 1), (9, 8, 7, 255))
            generator.save(unreadable_candidate, unreadable_path.name)
            with Image.open(unreadable_path) as recovered:
                if recovered.convert("RGBA").tobytes() != unreadable_candidate.tobytes():
                    raise AssertionError("読込不能productがcandidateで復旧されませんでした")

            failure_path = output_dir / "failure.png"
            Image.new("RGBA", (2, 2), (30, 40, 50, 255)).save(failure_path, format="PNG")
            failure_bytes = failure_path.read_bytes()
            try:
                with mock.patch.object(generator.os, "replace", side_effect=OSError("simulated replace failure")):
                    generator.save(Image.new("RGBA", (2, 2), (60, 70, 80, 255)), failure_path.name)
            except OSError as error:
                if str(error) != "simulated replace failure":
                    raise
            else:
                raise AssertionError("保存例外のシミュレーションが伝播しませんでした")
            if failure_path.read_bytes() != failure_bytes:
                raise AssertionError("保存例外時に旧productが変化しました")
            assert_no_temp_products(output_dir)

            guarded_name = "next_effect_art.png"
            guarded_path = output_dir / guarded_name
            Image.new("RGBA", (2, 2), (100, 110, 120, 255)).save(guarded_path, format="PNG")
            guarded_bytes = guarded_path.read_bytes()
            generator.save(Image.new("RGBA", (2, 2), (130, 140, 150, 255)), guarded_name)
            if guarded_path.read_bytes() != guarded_bytes:
                raise AssertionError("adopted product guardが現行画素を保持しませんでした")
        finally:
            generator.OUT = original_out


def verify_full_generator(
    generator: ModuleType,
    production_manifest: dict[str, dict[str, object]],
) -> dict[str, dict[str, object]]:
    original_out = generator.OUT
    with tempfile.TemporaryDirectory(prefix="cooking-generator-products-") as temp_dir:
        output_dir = Path(temp_dir) / "cooking"
        copy_product_pngs(PRODUCT_DIR, output_dir, production_manifest)
        before = product_manifest(output_dir)
        try:
            generator.OUT = output_dir
            if generator.OUT.resolve() == PRODUCT_DIR.resolve():
                raise AssertionError("generator.OUTがproduction製品directoryを指しています")
            generator.main()
            after_first = product_manifest(output_dir)
            generator.main()
            after_second = product_manifest(output_dir)
        finally:
            generator.OUT = original_out
        if before != after_first or before != after_second:
            changed = sorted(
                name
                for name in set(before) | set(after_first) | set(after_second)
                if before.get(name) != after_first.get(name) or before.get(name) != after_second.get(name)
            )
            raise AssertionError(f"隔離generator再実行で製品manifestが変化しました: {changed}")
        assert_no_temp_products(output_dir)
        return before


def main() -> None:
    generator = load_generator()
    production_before = product_manifest(PRODUCT_DIR)
    if len(production_before) != EXPECTED_PRODUCT_COUNT:
        raise AssertionError(
            f"調理製品PNG数が契約値と一致しません: {len(production_before)} != {EXPECTED_PRODUCT_COUNT}"
        )
    assert_no_temp_products(PRODUCT_DIR)
    try:
        verify_save_contract(generator)
        manifest = verify_full_generator(generator, production_before)
    finally:
        production_after = product_manifest(PRODUCT_DIR)
        assert_no_temp_products(PRODUCT_DIR)
        if production_after != production_before:
            changed = sorted(
                name
                for name in set(production_before) | set(production_after)
                if production_before.get(name) != production_after.get(name)
            )
            raise AssertionError(f"検証中にproduction製品manifestが変化しました: {changed}")
    print(
        json.dumps(
            {
                "status": "ok",
                "products": len(manifest),
                "generator_runs": 2,
                "generator_output": "temporary-byte-copy",
                "production_manifest_unchanged": True,
                "save_contracts": [
                    "decoded-identical byte preservation",
                    "size/mode-different atomic update",
                    "pixel-different atomic update",
                    "missing/unreadable recovery",
                    "save-failure cleanup and old-output preservation",
                    "adopted-product guard",
                ],
            },
            ensure_ascii=False,
        )
    )


if __name__ == "__main__":
    main()
