#!/usr/bin/env python3
"""C3 EXP_GAINの原寸・縮小比較と回帰証拠を固定する。"""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
from pathlib import Path

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ROOT / "docs/qa/evidence/cooking"
BEFORE = EVIDENCE / "2026-07-18_c3_before_exp.png"
AFTER = Path("/tmp/tsuri_cooking_exp.png")
REFERENCE = ROOT / "reference/cooking_flow/03_exp_gain_concept.png"
HIGH_RISK = Path("/tmp/tsuri_cooking_c3_exp_gain_levelup.png")
PROJECT = ROOT / "project.godot"
STATE_PAIRS = {
    "COOK_SELECT": (EVIDENCE / "2026-07-18_c3_before_select.png", Path("/tmp/tsuri_cooking_select.png")),
    "MEAL_RESULT": (EVIDENCE / "2026-07-18_c3_before_result.png", Path("/tmp/tsuri_cooking_result.png")),
    "LEVEL_UP_OVERLAY": (EVIDENCE / "2026-07-18_c3_before_levelup.png", Path("/tmp/tsuri_cooking_levelup.png")),
    "STATUS_SUMMARY": (EVIDENCE / "2026-07-18_c3_before_status.png", Path("/tmp/tsuri_cooking_status.png")),
}


def _load(path: Path) -> Image.Image:
    if not path.is_file():
        raise SystemExit(f"missing evidence input: {path}")
    return Image.open(path).convert("RGBA")


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _decoded_sha256(image: Image.Image) -> str:
    return hashlib.sha256(image.convert("RGBA").tobytes()).hexdigest()


def _bbox(a: Image.Image, b: Image.Image) -> tuple[int, int, int, int] | None:
    if a.size != b.size:
        raise SystemExit(f"comparison size mismatch: {a.size} != {b.size}")
    diff = ImageChops.difference(a, b)
    bounds: tuple[int, int, int, int] | None = None
    for channel in diff.getbands():
        channel_bounds = diff.getchannel(channel).getbbox()
        if channel_bounds is None:
            continue
        if bounds is None:
            bounds = channel_bounds
            continue
        bounds = (
            min(bounds[0], channel_bounds[0]),
            min(bounds[1], channel_bounds[1]),
            max(bounds[2], channel_bounds[2]),
            max(bounds[3], channel_bounds[3]),
        )
    return bounds


def _side_by_side(left: Image.Image, right: Image.Image, size: tuple[int, int] | None = None) -> Image.Image:
    if size is not None:
        left = left.resize(size, Image.Resampling.LANCZOS)
        right = right.resize(size, Image.Resampling.LANCZOS)
    result = Image.new("RGBA", (left.width + right.width, max(left.height, right.height)), (12, 18, 28, 255))
    result.alpha_composite(left, (0, 0))
    result.alpha_composite(right, (left.width, 0))
    return result


def _write(path: Path, image: Image.Image) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, format="PNG", optimize=False)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="require all C3 inputs and outputs")
    args = parser.parse_args()

    before = _load(BEFORE)
    after = _load(AFTER)
    reference = _load(REFERENCE)
    high_risk = _load(HIGH_RISK)
    if before.size != (1280, 720) or after.size != (1280, 720):
        raise SystemExit("C3 runtime representative images must be 1280x720")
    if high_risk.size != (1280, 720):
        raise SystemExit("C3 high-risk image must be 1280x720")

    outputs = {
        "after_exp": EVIDENCE / "2026-07-18_c3_after_exp.png",
        "before_after_exp": EVIDENCE / "2026-07-18_c3_before_after_exp.png",
        "after_reference": EVIDENCE / "2026-07-18_c3_after_reference.png",
        "after_reference_320": EVIDENCE / "2026-07-18_c3_after_reference_320x180.png",
        "high_risk_exp_gain_levelup": EVIDENCE / "2026-07-18_c3_highrisk_exp_gain_levelup.png",
    }
    _write(outputs["after_exp"], after)
    _write(outputs["before_after_exp"], _side_by_side(before, after))
    _write(outputs["after_reference"], _side_by_side(after, reference))
    _write(outputs["after_reference_320"], _side_by_side(after, reference, (320, 180)))
    _write(outputs["high_risk_exp_gain_levelup"], high_risk)

    regression: dict[str, dict[str, object]] = {}
    formal_after_paths: list[Path] = []
    for state, (before_path, after_path) in STATE_PAIRS.items():
        prior = _load(before_path)
        current = _load(after_path)
        if prior.size != (1280, 720) or current.size != (1280, 720):
            raise SystemExit(f"{state} regression evidence must be 1280x720")
        after_evidence = EVIDENCE / f"2026-07-18_c3_after_{state.lower()}.png"
        _write(after_evidence, current)
        formal_after_paths.append(after_evidence)
        regression[state] = {
            "before_file_sha256": _sha256(before_path),
            "after_file_sha256": _sha256(after_path),
            "before_decoded_rgba_sha256": _decoded_sha256(prior),
            "after_decoded_rgba_sha256": _decoded_sha256(current),
            "after_evidence": str(after_evidence),
            "diff_bbox": _bbox(prior, current),
            "pixel_identical": prior.tobytes() == current.tobytes(),
        }

    report = {
        "date": "2026-07-18",
        "scope": "C3 EXP_GAIN祝祭 Top1 exp_burst_frame 1 slot",
        "representative": {
            "before_file_sha256": _sha256(BEFORE),
            "after_file_sha256": _sha256(AFTER),
            "reference_file_sha256": _sha256(REFERENCE),
            "before_decoded_rgba_sha256": _decoded_sha256(before),
            "after_decoded_rgba_sha256": _decoded_sha256(after),
            "reference_decoded_rgba_sha256": _decoded_sha256(reference),
            "before_after_diff_bbox": _bbox(before, after),
            "after_reference_size": list(reference.size),
            "after_reference_320_each_size": [320, 180],
        },
        "high_risk": {
            "state": "EXP_GAIN_LEVELUP",
            "file": str(outputs["high_risk_exp_gain_levelup"]),
            "file_sha256": _sha256(HIGH_RISK),
            "decoded_rgba_sha256": _decoded_sha256(high_risk),
            "note": "EXP_GAIN_LEVELUPのoverlay受理前。LEVEL_UP後の別画面を採否対象にしない。",
        },
        "regression": regression,
        "project_godot_sha256": _sha256(PROJECT),
    }
    head_project = subprocess.check_output(["git", "show", "HEAD:project.godot"], cwd=ROOT)
    report["project_godot_head_sha256"] = hashlib.sha256(head_project).hexdigest()
    if report["project_godot_sha256"] != report["project_godot_head_sha256"]:
        raise SystemExit("project.godot differs from HEAD; restore baseline before C3 evidence")
    report_path = EVIDENCE / "2026-07-18_c3_evidence.json"
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    if args.check:
        for output in [*outputs.values(), *formal_after_paths]:
            if not output.is_file():
                raise SystemExit(f"missing C3 output: {output}")
        for state, details in regression.items():
            if state != "EXP_GAIN" and not bool(details["pixel_identical"]):
                raise SystemExit(f"C3 changed non-EXP_GAIN state: {state} bbox={details['diff_bbox']}")
    print(f"C3 evidence written: {report_path}")
    for state, details in regression.items():
        print(f"{state}: pixel_identical={details['pixel_identical']} diff_bbox={details['diff_bbox']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
