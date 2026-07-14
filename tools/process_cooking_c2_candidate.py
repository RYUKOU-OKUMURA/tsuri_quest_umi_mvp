#!/usr/bin/env python3
"""調理 C2 の AI 生成背景 source を決定的に整形・検査・比較する。"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFilter, ImageFont, ImageOps, PngImagePlugin


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tools/source_assets/cooking/c2_meal_scene_bg_source.png"
CANDIDATE = ROOT / "tools/source_assets/cooking/c2_meal_scene_bg_candidate.png"
CURRENT = Path("/tmp/tsuri_cooking_result.png")
REFERENCE = ROOT / "reference/cooking_flow/02_meal_result_concept.png"
EVIDENCE = ROOT / "docs/qa/evidence/cooking"
PREFIX = "2026-07-14_c2_assetprep"
SIZE = (1280, 720)

# 現行 runtime の overlay 占有域。背景処理と比較ボードの双方で同じ値を使う。
SAFE_AREAS = {
    "A_banner": (520, 20, 1215, 140),
    "B_actor": (55, 25, 510, 355),
    "C_dish": (525, 155, 1210, 350),
    "D_rewards": (55, 380, 1220, 515),
    "E_status": (55, 525, 1220, 625),
    "F_cta": (420, 635, 860, 690),
}

# UI背面で許容する上限。edge density は Sobel 相当の PIL FIND_EDGES 平均から算出。
SAFE_LIMITS = {
    "A_banner": {"mean_luma": 150.0, "stdev_luma": 72.0, "edge_density": 0.135},
    "B_actor": {"mean_luma": 145.0, "stdev_luma": 75.0, "edge_density": 0.155},
    "C_dish": {"mean_luma": 145.0, "stdev_luma": 72.0, "edge_density": 0.145},
    "D_rewards": {"mean_luma": 120.0, "stdev_luma": 65.0, "edge_density": 0.135},
    "E_status": {"mean_luma": 108.0, "stdev_luma": 60.0, "edge_density": 0.135},
    "F_cta": {"mean_luma": 105.0, "stdev_luma": 58.0, "edge_density": 0.125},
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def decoded_sha256(image: Image.Image) -> str:
    return hashlib.sha256(image.convert("RGBA").tobytes()).hexdigest()


def _has_same_decoded_pixels(image: Image.Image, path: Path) -> bool:
    if not path.exists():
        return False
    try:
        with Image.open(path) as existing:
            existing.load()
            return (
                existing.size == image.size
                and existing.mode == image.mode
                and existing.tobytes() == image.tobytes()
            )
    except (OSError, ValueError):
        return False


def save_png(image: Image.Image, path: Path) -> bool:
    """画素同値なら既存bytesを保持し、差分時だけatomic replaceする。"""
    path.parent.mkdir(parents=True, exist_ok=True)
    if _has_same_decoded_pixels(image, path):
        return False

    pnginfo = PngImagePlugin.PngInfo()
    temporary_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w+b",
            prefix=f".{path.name}.",
            suffix=".tmp",
            dir=path.parent,
            delete=False,
        ) as temporary:
            temporary_path = Path(temporary.name)
            image.save(
                temporary,
                format="PNG",
                optimize=False,
                compress_level=9,
                pnginfo=pnginfo,
            )
            temporary.flush()
            os.fsync(temporary.fileno())
        os.replace(temporary_path, path)
        temporary_path = None
    finally:
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)
    return True


def process_source(source_path: Path = SOURCE) -> Image.Image:
    with Image.open(source_path) as source:
        image = ImageOps.fit(
            source.convert("RGB"),
            SIZE,
            method=Image.Resampling.LANCZOS,
            centering=(0.5, 0.5),
        )

    # docs/19 §3.3: 暖色を残しつつ彩度・コントラストを抑え、UI背面用に減光する。
    image = ImageEnhance.Color(image).enhance(0.88)
    image = ImageEnhance.Contrast(image).enhance(0.93)
    image = ImageEnhance.Brightness(image).enhance(0.78)

    grade = Image.new("RGBA", SIZE, (9, 27, 43, 22))
    image = Image.alpha_composite(image.convert("RGBA"), grade)

    # 下段UIの背面だけを連続グラデーションで追加減光。矩形の継ぎ目を製品候補へ残さない。
    shade = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    shade_pixels = shade.load()
    for y in range(SIZE[1]):
        if y < 330:
            alpha = 0
        else:
            alpha = round(8 + 54 * ((y - 330) / (SIZE[1] - 330)))
        for x in range(SIZE[0]):
            shade_pixels[x, y] = (5, 16, 27, alpha)
    return Image.alpha_composite(image, shade)


def region_metrics(image: Image.Image, box: tuple[int, int, int, int]) -> dict[str, float]:
    gray = image.convert("L").crop(box)
    histogram = gray.histogram()
    count = sum(histogram)
    mean = sum(value * amount for value, amount in enumerate(histogram)) / count
    variance = sum(((value - mean) ** 2) * amount for value, amount in enumerate(histogram)) / count
    edges = gray.filter(ImageFilter.FIND_EDGES)
    edge_density = sum(edges.histogram()[96:]) / (edges.width * edges.height)
    return {
        "mean_luma": round(mean, 3),
        "stdev_luma": round(variance**0.5, 3),
        "edge_density": round(edge_density, 6),
    }


def validate_candidate(image: Image.Image) -> dict[str, object]:
    if image.size != SIZE:
        raise ValueError(f"candidate size must be {SIZE}, got {image.size}")
    rgba = image.convert("RGBA")
    alpha_min, alpha_max = rgba.getchannel("A").getextrema()
    if (alpha_min, alpha_max) != (255, 255):
        raise ValueError(f"candidate must be fully opaque, alpha={alpha_min}..{alpha_max}")

    regions: dict[str, dict[str, object]] = {}
    for name, box in SAFE_AREAS.items():
        metrics = region_metrics(rgba, box)
        limits = SAFE_LIMITS[name]
        failures = [key for key, limit in limits.items() if metrics[key] > limit]
        regions[name] = {"rect": list(box), "metrics": metrics, "limits": limits, "failures": failures}
        if failures:
            raise ValueError(f"safe-area {name} exceeds limits: {failures}; {metrics}")

    return {
        "size": list(rgba.size),
        "mode": rgba.mode,
        "alpha_range": [alpha_min, alpha_max],
        "safe_areas": regions,
        "machine_forbidden_checks": {
            "transparent_pixels": 0,
            "png_text_chunks": 0,
            "reference_pixels_consumed_by_processor": 0,
            "runtime_pixels_consumed_by_processor": 0,
        },
        "semantic_forbidden_elements": "独立アートレビューで0件を確認する（ローカル物体検出器なし）",
    }


def normalized(image: Image.Image) -> Image.Image:
    return ImageOps.fit(image.convert("RGB"), SIZE, method=Image.Resampling.LANCZOS)


def labeled_thumb(image: Image.Image, label: str, grayscale: bool = False) -> Image.Image:
    if grayscale:
        image = ImageOps.grayscale(image).convert("RGB")
    thumb = ImageOps.fit(image.convert("RGB"), (320, 180), method=Image.Resampling.LANCZOS)
    tile = Image.new("RGB", (336, 216), (12, 23, 35))
    tile.paste(thumb, (8, 28))
    draw = ImageDraw.Draw(tile)
    draw.text((10, 8), label, fill=(242, 222, 176), font=ImageFont.load_default())
    return tile


def overlay_board(candidate: Image.Image) -> Image.Image:
    board = candidate.convert("RGBA")
    layer = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    colors = [(41, 182, 246, 52), (255, 193, 7, 52), (76, 175, 80, 52)]
    for index, (name, box) in enumerate(SAFE_AREAS.items()):
        color = colors[index % len(colors)]
        draw.rectangle(box, fill=color, outline=color[:3] + (235,), width=3)
        draw.rectangle((box[0] + 5, box[1] + 5, box[0] + 118, box[1] + 25), fill=(7, 20, 33, 220))
        draw.text((box[0] + 9, box[1] + 8), name, fill=(255, 241, 199, 255), font=ImageFont.load_default())
    return Image.alpha_composite(board, layer).convert("RGB")


def write_evidence(candidate: Image.Image, report: dict[str, object]) -> None:
    if not CURRENT.exists():
        raise FileNotFoundError(f"current runtime capture is required: {CURRENT}")

    with Image.open(CURRENT) as current_file, Image.open(REFERENCE) as reference_file:
        sources = {
            "current": normalized(current_file),
            "reference": normalized(reference_file),
            "candidate": candidate.convert("RGB"),
        }

    for name, image in sources.items():
        save_png(image, EVIDENCE / f"{PREFIX}_{name}_original.png")
        save_png(image.resize((320, 180), Image.Resampling.LANCZOS), EVIDENCE / f"{PREFIX}_{name}_320x180.png")
        save_png(ImageOps.grayscale(image), EVIDENCE / f"{PREFIX}_{name}_grayscale.png")

    tiles = [labeled_thumb(sources[name], name.upper()) for name in ("current", "reference", "candidate")]
    gray_tiles = [labeled_thumb(sources[name], f"{name.upper()} GRAY", True) for name in ("current", "reference", "candidate")]
    contact = Image.new("RGB", (1008, 432), (7, 17, 28))
    for index, tile in enumerate(tiles + gray_tiles):
        contact.paste(tile, ((index % 3) * 336, (index // 3) * 216))
    save_png(contact, EVIDENCE / f"{PREFIX}_contact.png")
    save_png(overlay_board(candidate), EVIDENCE / f"{PREFIX}_overlay_safe_area.png")

    report_path = EVIDENCE / f"{PREFIX}_report.json"
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=SOURCE)
    parser.add_argument("--output", type=Path, default=CANDIDATE)
    parser.add_argument("--evidence", action="store_true")
    args = parser.parse_args()

    candidate = process_source(args.source)
    validation = validate_candidate(candidate)
    save_png(candidate, args.output)
    report: dict[str, object] = {
        "source": str(args.source.relative_to(ROOT)),
        "candidate": str(args.output.relative_to(ROOT)),
        "source_sha256": sha256(args.source),
        "candidate_sha256": sha256(args.output),
        "candidate_decoded_rgba_sha256": decoded_sha256(candidate),
        "validation": validation,
        "verdict": "C2配線レビューへ進められる候補（本番採用・freezeではない）",
    }
    if args.evidence:
        write_evidence(candidate, report)
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
