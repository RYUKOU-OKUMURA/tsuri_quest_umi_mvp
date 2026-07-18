#!/usr/bin/env python3
"""SHIPYARD-D0の撮影検査と、現行/未採用reference候補の比較evidenceを作る。"""

from __future__ import annotations

import argparse
import hashlib
import os
import tempfile
from pathlib import Path

from PIL import Image as PILImage, ImageDraw, ImageFont, ImageStat

import build_shipyard_d0_proposal


ROOT = Path(__file__).resolve().parents[1]
VIEWPORT = (1280, 720)
EVIDENCE = ROOT / "docs" / "qa" / "evidence" / "shipyard"
REFERENCE = ROOT.joinpath("reference", "shipyard_d0_proposal_unapproved.png")
DEFAULT_DATE = "2026-07-18"
CAPTURES = {
    "available_focus": Path("/tmp/tsuri_shipyard_available.png"),
    "insufficient": Path("/tmp/tsuri_shipyard_insufficient.png"),
    "purchased_focus_fallback": Path("/tmp/tsuri_shipyard_purchased_focus_fallback.png"),
    "all_owned": Path("/tmp/tsuri_shipyard_all_owned.png"),
}


def _font(size: int, bold: bool = True):
    name = "LINESeedJP_A_TTF_Bd.ttf" if bold else "LINESeedJP_A_TTF_Rg.ttf"
    path = ROOT / "assets" / "fonts" / "line_seed" / name
    try:
        return ImageFont.truetype(str(path), size)
    except OSError:
        return ImageFont.load_default()


def inspect_image(path: Path, label: str, expected_size: tuple[int, int] = VIEWPORT) -> list[str]:
    if not path.exists():
        return [f"{label}: missing {path}"]
    try:
        with PILImage.open(path) as source:
            source.load()
            if source.size != expected_size:
                return [
                    f"{label}: expected {expected_size[0]}x{expected_size[1]}, got "
                    f"{source.size[0]}x{source.size[1]} ({path})"
                ]
            rgba = source.convert("RGBA")
            alpha = list(rgba.getchannel("A").resize((64, 36)).getdata())
            rgb = rgba.convert("RGB")
            sample = list(rgb.resize((64, 36)).getdata())
            colors = rgb.resize((64, 36)).getcolors(maxcolors=64 * 36 + 1) or []
            channel_spread = max(maximum - minimum for minimum, maximum in rgb.getextrema())
            near_black_ratio = sum(max(pixel) < 18 for pixel in sample) / len(sample)
            visible_ratio = sum(sum(pixel) > 80 for pixel in sample) / len(sample)
            transparent_ratio = sum(value < 250 for value in alpha) / len(alpha)
            color_stddev = max(ImageStat.Stat(rgb).stddev)
    except OSError as exc:
        return [f"{label}: unreadable PNG {path}: {exc}"]

    failures: list[str] = []
    if transparent_ratio > 0.01:
        failures.append(f"{label}: transparent capture region ({transparent_ratio:.1%})")
    if near_black_ratio > 0.45:
        failures.append(f"{label}: black/near-black capture region ({near_black_ratio:.1%})")
    if visible_ratio < 0.20:
        failures.append(f"{label}: blank capture ({visible_ratio:.1%} visible)")
    if len(colors) < 16 or channel_spread < 8 or color_stddev < 4.0:
        failures.append(f"{label}: low-variation or duplicated-looking image")
    return failures


def duplicate_failures(paths: dict[str, Path]) -> list[str]:
    hashes: dict[str, list[str]] = {}
    for state, path in paths.items():
        if path.exists():
            hashes.setdefault(hashlib.sha256(path.read_bytes()).hexdigest(), []).append(state)
    return [
        "capture frames are stale or duplicated across states: " + ", ".join(states)
        for states in hashes.values()
        if len(states) > 1
    ]


def _build_board(left: PILImage.Image, right: PILImage.Image, size: tuple[int, int], output: Path) -> None:
    left = left.convert("RGB").resize(size, PILImage.Resampling.LANCZOS)
    right = right.convert("RGB").resize(size, PILImage.Resampling.LANCZOS)
    board = PILImage.new("RGB", (size[0] * 2, size[1]), (12, 22, 32))
    board.paste(left, (0, 0))
    board.paste(right, (size[0], 0))
    output.parent.mkdir(parents=True, exist_ok=True)
    board.save(output, optimize=True)


def _build_state_strip(captures: dict[str, Path], output: Path) -> None:
    thumb = (320, 180)
    labels_h = 28
    board = PILImage.new("RGB", (thumb[0] * 2, (thumb[1] + labels_h) * 2), (12, 22, 32))
    draw = ImageDraw.Draw(board)
    labels = list(captures)
    for index, state in enumerate(labels):
        with PILImage.open(captures[state]) as source:
            image = source.convert("RGB").resize(thumb, PILImage.Resampling.LANCZOS)
        x = (index % 2) * thumb[0]
        y = (index // 2) * (thumb[1] + labels_h)
        board.paste(image, (x, y + labels_h))
        draw.text((x + 8, y + 6), state, font=_font(13), fill=(245, 233, 201))
    output.parent.mkdir(parents=True, exist_ok=True)
    board.save(output, optimize=True)


def build_evidence(date: str) -> list[str]:
    failures: list[str] = []
    for state, path in CAPTURES.items():
        failures.extend(inspect_image(path, f"current {state}"))
    failures.extend(duplicate_failures(CAPTURES))
    if failures:
        return failures

    # 現行captureから、reference候補を毎回同じ入力で再生成する。
    build_shipyard_d0_proposal.build(CAPTURES["available_focus"], REFERENCE)
    failures.extend(inspect_image(REFERENCE, "reference候補"))
    if failures:
        return failures

    EVIDENCE.mkdir(parents=True, exist_ok=True)
    for state, path in CAPTURES.items():
        target = EVIDENCE / f"{date}_current_{state}.png"
        target.write_bytes(path.read_bytes())

    with PILImage.open(CAPTURES["available_focus"]) as current, PILImage.open(REFERENCE) as reference:
        _build_board(
            current,
            reference,
            VIEWPORT,
            EVIDENCE / f"{date}_d0_current_reference_full.png",
        )
        _build_board(
            current,
            reference,
            (320, 180),
            EVIDENCE / f"{date}_d0_current_reference_320x180.png",
        )
    _build_state_strip(CAPTURES, EVIDENCE / f"{date}_d0_current_states_320x180.png")
    return []


def self_test() -> int:
    with tempfile.TemporaryDirectory(prefix="shipyard_visual_qa_") as temporary:
        root = Path(temporary)
        valid = PILImage.new("RGB", VIEWPORT, (14, 54, 78))
        ImageDraw.Draw(valid).rectangle((60, 60, 600, 600), fill=(223, 178, 72))
        valid_path = root / "valid.png"
        valid.save(valid_path)
        transparent = PILImage.new("RGBA", VIEWPORT, (255, 255, 255, 0))
        transparent_path = root / "transparent.png"
        transparent.save(transparent_path)
        black_path = root / "black.png"
        PILImage.new("RGB", VIEWPORT, "#000000").save(black_path)
        duplicate_a = root / "duplicate_a.png"
        duplicate_b = root / "duplicate_b.png"
        valid.save(duplicate_a)
        valid.save(duplicate_b)
        failures = []
        if inspect_image(valid_path, "valid"):
            failures.append("valid fixture should pass")
        if not inspect_image(transparent_path, "transparent"):
            failures.append("transparent fixture should fail")
        if not inspect_image(black_path, "black"):
            failures.append("black fixture should fail")
        duplicate = duplicate_failures({"a": duplicate_a, "b": duplicate_b})
        if not duplicate:
            failures.append("duplicate fixtures should fail")
        if failures:
            print("shipyard visual QA self-test failed:")
            for failure in failures:
                print(f"  - {failure}")
            return 1
    print("shipyard visual QA self-test: black/transparent/duplicate rejected")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--date", default=os.environ.get("TSURI_QA_DATE", DEFAULT_DATE))
    args = parser.parse_args()
    if args.self_test:
        return self_test()
    failures = build_evidence(args.date)
    if failures:
        print("shipyard visual QA failed:")
        for failure in failures:
            print(f"  - {failure}")
        return 1
    print(f"shipyard visual QA evidence: {EVIDENCE}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
