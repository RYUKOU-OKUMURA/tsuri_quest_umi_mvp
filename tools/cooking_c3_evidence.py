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
HIGH_RISK_MANIFEST = Path("/tmp/tsuri_cooking_c3_highrisk_manifest.json")
HIGH_RISK_CASES = {
    "EXP_GAIN_LEVELUP": {
        "capture": HIGH_RISK,
        "evidence": EVIDENCE / "2026-07-18_c3_highrisk_exp_gain_levelup.png",
    },
    "EXP_GAIN_FIRST_BONUS": {
        "capture": Path("/tmp/tsuri_cooking_c3_exp_gain_first_bonus.png"),
        "evidence": EVIDENCE / "2026-07-18_c3_highrisk_exp_gain_first_bonus.png",
    },
    "EXP_GAIN_NO_BONUS": {
        "capture": Path("/tmp/tsuri_cooking_c3_exp_gain_no_bonus.png"),
        "evidence": EVIDENCE / "2026-07-18_c3_highrisk_exp_gain_no_bonus.png",
    },
    "EXP_GAIN_EXP_CAP": {
        "capture": Path("/tmp/tsuri_cooking_c3_exp_gain_exp_cap.png"),
        "evidence": EVIDENCE / "2026-07-18_c3_highrisk_exp_gain_exp_cap.png",
    },
    "EXP_GAIN_LONG_BUFF": {
        "capture": Path("/tmp/tsuri_cooking_c3_exp_gain_long_buff.png"),
        "evidence": EVIDENCE / "2026-07-18_c3_highrisk_exp_gain_long_buff.png",
    },
}
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


def _load_high_risk_captures() -> tuple[dict, dict[str, Image.Image]]:
    if not HIGH_RISK_MANIFEST.is_file():
        raise SystemExit(f"missing C3 high-risk runtime manifest: {HIGH_RISK_MANIFEST}")
    try:
        manifest = json.loads(HIGH_RISK_MANIFEST.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise SystemExit(f"invalid C3 high-risk runtime manifest: {exc}") from exc
    if manifest.get("source") != "tools/cooking_preview.gd" or manifest.get("runtime_preview") is not True:
        raise SystemExit("C3 high-risk manifest must identify the runtime preview source")
    captures = manifest.get("captures")
    if not isinstance(captures, list):
        raise SystemExit("C3 high-risk manifest must contain a captures list")
    by_state: dict[str, dict] = {}
    for entry in captures:
        if not isinstance(entry, dict):
            raise SystemExit("C3 high-risk manifest contains a non-object capture")
        state = entry.get("state")
        if state in by_state:
            raise SystemExit(f"duplicate C3 high-risk state: {state}")
        by_state[state] = entry

    images: dict[str, Image.Image] = {}
    for state, spec in HIGH_RISK_CASES.items():
        entry = by_state.get(state)
        if entry is None:
            raise SystemExit(f"C3 high-risk manifest missing state identification: {state}")
        capture = spec["capture"]
        if entry.get("capture") != str(capture):
            raise SystemExit(
                f"C3 high-risk {state} capture path mismatch: expected {capture}, got {entry.get('capture')}"
            )
        if entry.get("verified_state") != state:
            raise SystemExit(
                f"C3 high-risk {state} verified_state mismatch: got {entry.get('verified_state')}"
            )
        if (entry.get("width"), entry.get("height")) != (1280, 720):
            raise SystemExit(
                f"C3 high-risk {state} manifest size must be 1280x720, "
                f"got {entry.get('width')}x{entry.get('height')}"
            )
        image = _load(capture)
        if image.size != (1280, 720):
            raise SystemExit(f"C3 high-risk {state} image must be 1280x720, got {image.size}")
        images[state] = image
    if set(by_state) != set(HIGH_RISK_CASES):
        extra = sorted(set(by_state) - set(HIGH_RISK_CASES))
        raise SystemExit(f"C3 high-risk manifest has unexpected state IDs: {extra}")
    return manifest, images


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="require all C3 inputs and outputs")
    args = parser.parse_args()

    before = _load(BEFORE)
    after = _load(AFTER)
    reference = _load(REFERENCE)
    high_risk_manifest, high_risk_images = _load_high_risk_captures()
    if before.size != (1280, 720) or after.size != (1280, 720):
        raise SystemExit("C3 runtime representative images must be 1280x720")
    if HIGH_RISK_CASES["EXP_GAIN_LEVELUP"]["capture"] != HIGH_RISK:
        raise SystemExit("C3 EXP_GAIN_LEVELUP capture contract is inconsistent")

    outputs = {
        "after_exp": EVIDENCE / "2026-07-18_c3_after_exp.png",
        "before_after_exp": EVIDENCE / "2026-07-18_c3_before_after_exp.png",
        "after_reference": EVIDENCE / "2026-07-18_c3_after_reference.png",
        "after_reference_320": EVIDENCE / "2026-07-18_c3_after_reference_320x180.png",
    }
    _write(outputs["after_exp"], after)
    _write(outputs["before_after_exp"], _side_by_side(before, after))
    _write(outputs["after_reference"], _side_by_side(after, reference))
    _write(outputs["after_reference_320"], _side_by_side(after, reference, (320, 180)))
    high_risk_outputs: dict[str, Path] = {}
    for state, spec in HIGH_RISK_CASES.items():
        high_risk_outputs[state] = spec["evidence"]
        _write(spec["evidence"], high_risk_images[state])

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
            "file": str(high_risk_outputs["EXP_GAIN_LEVELUP"]),
            "file_sha256": _sha256(HIGH_RISK),
            "decoded_rgba_sha256": _decoded_sha256(high_risk_images["EXP_GAIN_LEVELUP"]),
            "note": "全5ケースをEXP_GAINの実runtime previewで再撮影。EXP_GAIN_LEVELUPはoverlay受理前。",
            "manifest": str(HIGH_RISK_MANIFEST),
            "runtime_source": high_risk_manifest["source"],
            "cases": {
                state: {
                    "state": state,
                    "source_capture": str(spec["capture"]),
                    "file": str(high_risk_outputs[state]),
                    "file_sha256": _sha256(spec["capture"]),
                    "decoded_rgba_sha256": _decoded_sha256(high_risk_images[state]),
                    "size": list(high_risk_images[state].size),
                    "verified_state": state,
                }
                for state, spec in HIGH_RISK_CASES.items()
            },
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
        for output in [*outputs.values(), *formal_after_paths, *high_risk_outputs.values()]:
            if not output.is_file():
                raise SystemExit(f"missing C3 output: {output}")
        for state, output in high_risk_outputs.items():
            formal = _load(output)
            if formal.size != (1280, 720):
                raise SystemExit(f"C3 high-risk evidence {state} must be 1280x720")
            if formal.tobytes() != high_risk_images[state].tobytes():
                raise SystemExit(f"C3 high-risk evidence {state} differs from fresh runtime capture")
        for state, details in regression.items():
            if state != "EXP_GAIN" and not bool(details["pixel_identical"]):
                raise SystemExit(f"C3 changed non-EXP_GAIN state: {state} bbox={details['diff_bbox']}")
    print(f"C3 evidence written: {report_path}")
    for state, details in regression.items():
        print(f"{state}: pixel_identical={details['pixel_identical']} diff_bbox={details['diff_bbox']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
