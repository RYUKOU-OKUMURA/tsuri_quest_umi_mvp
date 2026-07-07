#!/usr/bin/env python3
"""Audit fish portraits and fight sheets for near-duplicate art.

Default mode keeps validation green while docs/35 P1/P2 are still in progress:
documented C-class/intended derivatives are allowed, and documented P1/P2
duplicates are reported as a temporary pair-specific baseline. Use ``--strict``
after P1/P2 are complete to make that temporary baseline fail.
"""
from __future__ import annotations

import argparse
import itertools
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parents[1]
FISH_DIR = ROOT / "assets" / "showcase" / "fish"

HASH_SIZE = 16
THRESHOLD = 12
ALPHA_THRESHOLD = 8
PORTRAIT_SUFFIX = "_card_portrait.png"
SHEET_SUFFIX = "_showcase_sheet.png"
SHEET_FRAME_SIZE = (640, 320)


@dataclass(frozen=True)
class SimilarPair:
    first: str
    second: str
    portrait_distance: int | None
    sheet_distance: int | None
    classification: str
    reason: str

    @property
    def min_distance(self) -> int:
        values = [value for value in (self.portrait_distance, self.sheet_distance) if value is not None]
        return min(values)


def _pair(first: str, second: str) -> frozenset[str]:
    return frozenset((first, second))


ALLOWED_PAIRS: dict[frozenset[str], str] = {
    _pair("sappa", "iwashi"): "docs/35 C: sappa is distinguishable from iwashi",
    _pair("shitabirame", "hirame"): "docs/35 C: shitabirame shape is distinguishable",
    _pair("datsu", "kamasu"): "docs/35 C: datsu silhouette is distinguishable",
    _pair("maanago", "tachiuo"): "docs/35 C: maanago is a permitted eel-like derivative",
    _pair("megochi", "kochi"): "docs/35 C/P3: boundary case kept until P3 reevaluation",
    _pair("kurosoi", "mebaru"): "docs/35 C/P3: rockfish derivative kept until P3 reevaluation",
    _pair("takenokomebaru", "mebaru"): "docs/35 C/P3: rockfish derivative kept until P3 reevaluation",
    _pair("kurosoi", "takenokomebaru"): "docs/35 C/P3: rockfish pair kept until P3 reevaluation",
    _pair("tsumuburi", "hiramasa"): "docs/35 C: bluefish derivative is distinguishable",
    _pair("megalodon", "nushi_danger_reef"): "docs/35 target-excluded E10 derivative",
    _pair("nushi_harbor_pier", "maanago"): "E2 nushi is an intentional base-fish derivative",
    _pair("nushi_shallow_sand", "hirame"): "E2 nushi is an intentional base-fish derivative",
    _pair("nushi_rock_breakwater", "ishidai"): "E2 nushi is an intentional base-fish derivative",
    _pair("nushi_outer_tide", "suzuki"): "E2 nushi is an intentional base-fish derivative",
    _pair("nushi_south_reef", "kue"): "E2 nushi is an intentional base-fish derivative",
    _pair("nushi_bluewater_route", "buri"): "E2 nushi is an intentional base-fish derivative",
    _pair("nushi_deep_ocean", "ara"): "E2 nushi is an intentional base-fish derivative",
    _pair("nushi_danger_reef", "hohojirozame"): "E4 nushi is an intentional base-fish boss variant",
}


# Exact docs/35 baseline pairs observed in the current assets. Keep this
# pair-specific so any new near-duplicate fails, even inside a known family.
PENDING_PAIRS: dict[frozenset[str], str] = {}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--threshold", type=int, default=THRESHOLD, help="Maximum dhash distance treated as similar.")
    parser.add_argument("--strict", action="store_true", help="Fail documented P1/P2 baseline pairs too.")
    parser.add_argument("--verbose", action="store_true", help="Print every similar pair, including allowed pairs.")
    args = parser.parse_args()

    failures: list[str] = []
    portraits = _load_hashes(PORTRAIT_SUFFIX, "portrait", failures)
    sheets = _load_hashes(SHEET_SUFFIX, "sheet", failures)
    fish_ids = sorted(set(portraits) | set(sheets))

    if not fish_ids:
        failures.append(f"no fish assets found under {FISH_DIR}")

    similar = _find_similar_pairs(fish_ids, portraits, sheets, args.threshold)
    unexpected = [pair for pair in similar if pair.classification == "unexpected"]
    pending = [pair for pair in similar if pair.classification == "pending"]
    allowed = [pair for pair in similar if pair.classification == "allowed"]

    if unexpected:
        failures.append(f"{len(unexpected)} unexpected near-duplicate fish asset pair(s)")
    if args.strict and pending:
        failures.append(f"{len(pending)} docs/35 pending pair(s) still exceed threshold in strict mode")

    if failures:
        print("fish asset duplicate audit failed:")
        for failure in failures:
            print(f"- {failure}")
        for pair in unexpected + (pending if args.strict else []):
            print(f"- {_format_pair(pair)}")
        return 1

    print(
        "fish asset duplicate audit passed: "
        f"{len(fish_ids)} fish, {len(allowed)} allowed, {len(pending)} docs/35 pending baseline, "
        f"{len(unexpected)} unexpected"
    )
    if args.verbose:
        for pair in similar:
            print(f"- {_format_pair(pair)}")
    elif pending:
        print("  note: run with --strict after docs/35 P1/P2 asset replacement to remove the temporary baseline")
    return 0


def _load_hashes(suffix: str, label: str, failures: list[str]) -> dict[str, int]:
    hashes: dict[str, int] = {}
    for path in sorted(FISH_DIR.glob(f"*{suffix}")):
        fish_id = path.name.removesuffix(suffix)
        try:
            image = Image.open(path).convert("RGBA")
            if label == "sheet":
                image = image.crop((0, 0, SHEET_FRAME_SIZE[0], SHEET_FRAME_SIZE[1]))
            hashes[fish_id] = _dhash(_normalised_for_hash(image))
        except OSError as exc:
            failures.append(f"{path.name}: failed to load PNG: {exc}")
    return hashes


def _normalised_for_hash(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    bbox = image.getchannel("A").point(lambda value: 255 if value > ALPHA_THRESHOLD else 0).getbbox()
    if bbox is not None:
        image = image.crop(_padded_bbox(bbox, image.size))

    grayscale = ImageOps.grayscale(_composite_for_hash(image))
    canvas = Image.new("L", (256, 160), 0)
    scale = min(canvas.width / grayscale.width, canvas.height / grayscale.height)
    resized = grayscale.resize(
        (max(1, round(grayscale.width * scale)), max(1, round(grayscale.height * scale))),
        Image.Resampling.LANCZOS,
    )
    canvas.paste(resized, ((canvas.width - resized.width) // 2, (canvas.height - resized.height) // 2))
    return canvas


def _padded_bbox(bbox: tuple[int, int, int, int], size: tuple[int, int]) -> tuple[int, int, int, int]:
    left, top, right, bottom = bbox
    width = right - left
    height = bottom - top
    pad_x = max(8, round(width * 0.06))
    pad_y = max(8, round(height * 0.10))
    return (
        max(0, left - pad_x),
        max(0, top - pad_y),
        min(size[0], right + pad_x),
        min(size[1], bottom + pad_y),
    )


def _composite_for_hash(image: Image.Image) -> Image.Image:
    background = Image.new("RGBA", image.size, (0, 0, 0, 255))
    background.alpha_composite(image)
    return background.convert("RGB")


def _dhash(image: Image.Image) -> int:
    sample = image.resize((HASH_SIZE + 1, HASH_SIZE), Image.Resampling.LANCZOS)
    pixels = list(sample.getdata())
    value = 0
    for y in range(HASH_SIZE):
        for x in range(HASH_SIZE):
            value <<= 1
            if pixels[y * (HASH_SIZE + 1) + x] > pixels[y * (HASH_SIZE + 1) + x + 1]:
                value |= 1
    return value


def _hamming(left: int, right: int) -> int:
    return (left ^ right).bit_count()


def _find_similar_pairs(
    fish_ids: list[str],
    portraits: dict[str, int],
    sheets: dict[str, int],
    threshold: int,
) -> list[SimilarPair]:
    similar: list[SimilarPair] = []
    for first, second in itertools.combinations(fish_ids, 2):
        portrait_distance = _distance_for(first, second, portraits)
        sheet_distance = _distance_for(first, second, sheets)
        if not _is_similar(portrait_distance, sheet_distance, threshold):
            continue
        classification, reason = _classify(first, second)
        similar.append(SimilarPair(first, second, portrait_distance, sheet_distance, classification, reason))
    return sorted(similar, key=lambda pair: (pair.classification, pair.min_distance, pair.first, pair.second))


def _distance_for(first: str, second: str, hashes: dict[str, int]) -> int | None:
    if first not in hashes or second not in hashes:
        return None
    return _hamming(hashes[first], hashes[second])


def _is_similar(portrait_distance: int | None, sheet_distance: int | None, threshold: int) -> bool:
    return any(value is not None and value <= threshold for value in (portrait_distance, sheet_distance))


def _classify(first: str, second: str) -> tuple[str, str]:
    pair = _pair(first, second)
    if pair in ALLOWED_PAIRS:
        return "allowed", ALLOWED_PAIRS[pair]
    if pair in PENDING_PAIRS:
        return "pending", f"{PENDING_PAIRS[pair]}; temporary baseline until P1/P2/P3 is closed"
    return "unexpected", "not documented in docs/35 allowlist or temporary P1/P2 baseline"


def _format_pair(pair: SimilarPair) -> str:
    portrait = "n/a" if pair.portrait_distance is None else str(pair.portrait_distance)
    sheet = "n/a" if pair.sheet_distance is None else str(pair.sheet_distance)
    return (
        f"{pair.first} <-> {pair.second}: portrait={portrait}, sheet={sheet}, "
        f"{pair.classification}: {pair.reason}"
    )


if __name__ == "__main__":
    raise SystemExit(main())
