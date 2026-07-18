#!/usr/bin/env python3
"""C3 EXP_GAINの原寸・縮小比較と回帰証拠を固定する。"""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import tempfile
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
        "observed": {
            "runtime_state": "EXP_GAIN_LEVELUP",
            "runtime_state_visible": True,
            "title_text": "食経験値が成長へ！",
            "title_visible": True,
            "progress_text": "EXP 92 / 150  ->  150 / 150",
            "progress_visible": True,
            "bonus_badge_text": "初回 記録済み",
            "bonus_badge_visible": True,
            "bonus_text_visible": False,
            "effect_name_text": "アジの塩焼き",
            "effect_name_visible": True,
            "effect_text": "最大体力 +5%",
            "effect_text_visible": True,
        },
    },
    "EXP_GAIN_FIRST_BONUS": {
        "capture": Path("/tmp/tsuri_cooking_c3_exp_gain_first_bonus.png"),
        "evidence": EVIDENCE / "2026-07-18_c3_highrisk_exp_gain_first_bonus.png",
        "observed": {
            "runtime_state": "EXP_GAIN",
            "runtime_state_visible": True,
            "title_text": "食経験値を獲得！",
            "title_visible": True,
            "progress_text": "EXP 132 / 285  ->  198 / 285",
            "progress_visible": True,
            "bonus_badge_text": "初回ボーナス +30 EXP",
            "bonus_badge_visible": True,
            "bonus_text_visible": True,
            "effect_name_text": "メジナの煮付け",
            "effect_name_visible": True,
            "effect_text": "安全域 +10%",
            "effect_text_visible": True,
        },
    },
    "EXP_GAIN_NO_BONUS": {
        "capture": Path("/tmp/tsuri_cooking_c3_exp_gain_no_bonus.png"),
        "evidence": EVIDENCE / "2026-07-18_c3_highrisk_exp_gain_no_bonus.png",
        "observed": {
            "runtime_state": "EXP_GAIN",
            "runtime_state_visible": True,
            "title_text": "食経験値を獲得！",
            "title_visible": True,
            "progress_text": "EXP 127 / 285  ->  165 / 285",
            "progress_visible": True,
            "bonus_badge_text": "初回 記録済み",
            "bonus_badge_visible": True,
            "bonus_text_visible": False,
            "effect_name_text": "メジナの煮付け",
            "effect_name_visible": True,
            "effect_text": "安全域 +10%",
            "effect_text_visible": True,
        },
    },
    "EXP_GAIN_EXP_CAP": {
        "capture": Path("/tmp/tsuri_cooking_c3_exp_gain_exp_cap.png"),
        "evidence": EVIDENCE / "2026-07-18_c3_highrisk_exp_gain_exp_cap.png",
        "observed": {
            "runtime_state": "EXP_GAIN",
            "runtime_state_visible": True,
            "title_text": "食経験値を獲得！",
            "title_visible": True,
            "progress_text": "EXP 260 / 285  ->  285 / 285",
            "progress_visible": True,
            "bonus_badge_text": "初回 記録済み",
            "bonus_badge_visible": True,
            "bonus_text_visible": False,
            "effect_name_text": "メジナの煮付け",
            "effect_name_visible": True,
            "effect_text": "安全域 +10%",
            "effect_text_visible": True,
        },
    },
    "EXP_GAIN_LONG_BUFF": {
        "capture": Path("/tmp/tsuri_cooking_c3_exp_gain_long_buff.png"),
        "evidence": EVIDENCE / "2026-07-18_c3_highrisk_exp_gain_long_buff.png",
        "observed": {
            "runtime_state": "EXP_GAIN",
            "runtime_state_visible": True,
            "title_text": "食経験値を獲得！",
            "title_visible": True,
            "progress_text": "EXP 127 / 285  ->  165 / 285",
            "progress_visible": True,
            "bonus_badge_text": "初回 記録済み",
            "bonus_badge_visible": True,
            "bonus_text_visible": False,
            "effect_name_text": "港町特製メジナと彩り野菜の香草煮",
            "effect_name_visible": True,
            "effect_text": "安全域と最大体力が長時間にわたり大きく上がる",
            "effect_text_visible": True,
        },
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


def _json_bbox(bounds: tuple[int, int, int, int] | None) -> list[int] | None:
    return None if bounds is None else list(bounds)


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


def _load_high_risk_captures() -> tuple[dict, dict[str, dict], dict[str, Image.Image]]:
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
        if entry.get("case_id") != state:
            raise SystemExit(f"C3 high-risk case_id self-match failed: {entry.get('case_id')} != {state}")
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
        observed = entry.get("observed")
        expected_observed = spec["observed"]
        if not isinstance(observed, dict):
            raise SystemExit(f"C3 high-risk {state} is missing runtime node observations")
        for key, expected in expected_observed.items():
            if observed.get(key) != expected:
                raise SystemExit(
                    f"C3 high-risk {state} observation mismatch for {key}: "
                    f"expected {expected!r}, got {observed.get(key)!r}"
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
    return manifest, by_state, images


REPORT_PATH = EVIDENCE / "2026-07-18_c3_evidence.json"


def _build_bundle() -> tuple[dict[Path, Image.Image], dict]:
    before = _load(BEFORE)
    after = _load(AFTER)
    reference = _load(REFERENCE)
    high_risk_manifest, high_risk_entries, high_risk_images = _load_high_risk_captures()
    if before.size != (1280, 720) or after.size != (1280, 720):
        raise SystemExit("C3 runtime representative images must be 1280x720")
    if HIGH_RISK_CASES["EXP_GAIN_LEVELUP"]["capture"] != HIGH_RISK:
        raise SystemExit("C3 EXP_GAIN_LEVELUP capture contract is inconsistent")

    outputs: dict[Path, Image.Image] = {
        EVIDENCE / "2026-07-18_c3_after_exp.png": after,
        EVIDENCE / "2026-07-18_c3_before_after_exp.png": _side_by_side(before, after),
        EVIDENCE / "2026-07-18_c3_after_reference.png": _side_by_side(after, reference),
        EVIDENCE / "2026-07-18_c3_after_reference_320x180.png": _side_by_side(
            after, reference, (320, 180)
        ),
    }
    for state, spec in HIGH_RISK_CASES.items():
        outputs[spec["evidence"]] = high_risk_images[state]

    regression: dict[str, dict[str, object]] = {}
    for state, (before_path, after_path) in STATE_PAIRS.items():
        prior = _load(before_path)
        current = _load(after_path)
        if prior.size != (1280, 720) or current.size != (1280, 720):
            raise SystemExit(f"{state} regression evidence must be 1280x720")
        after_evidence = EVIDENCE / f"2026-07-18_c3_after_{state.lower()}.png"
        outputs[after_evidence] = current
        regression[state] = {
            "before_file_sha256": _sha256(before_path),
            "after_file_sha256": _sha256(after_path),
            "before_decoded_rgba_sha256": _decoded_sha256(prior),
            "after_decoded_rgba_sha256": _decoded_sha256(current),
            "after_evidence": str(after_evidence),
            "diff_bbox": _json_bbox(_bbox(prior, current)),
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
            "before_after_diff_bbox": _json_bbox(_bbox(before, after)),
            "after_reference_size": list(reference.size),
            "after_reference_320_each_size": [320, 180],
        },
        "high_risk": {
            "state": "EXP_GAIN_LEVELUP",
            "file": str(HIGH_RISK_CASES["EXP_GAIN_LEVELUP"]["evidence"]),
            "file_sha256": _sha256(HIGH_RISK),
            "decoded_rgba_sha256": _decoded_sha256(high_risk_images["EXP_GAIN_LEVELUP"]),
            "note": "全5ケースをEXP_GAINの実runtime previewで再撮影。EXP_GAIN_LEVELUPはoverlay受理前。",
            "manifest": str(HIGH_RISK_MANIFEST),
            "runtime_source": high_risk_manifest["source"],
            "cases": {
                state: {
                    "state": state,
                    "case_id": state,
                    "source_capture": str(spec["capture"]),
                    "file": str(spec["evidence"]),
                    "file_sha256": _sha256(spec["capture"]),
                    "decoded_rgba_sha256": _decoded_sha256(high_risk_images[state]),
                    "size": list(high_risk_images[state].size),
                    "verified_state": state,
                    "observed": high_risk_entries[state]["observed"],
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
    return outputs, report


def _check_formal_png(path: Path, expected: Image.Image) -> None:
    if not path.is_file():
        raise SystemExit(f"missing formal C3 evidence: {path}")
    try:
        actual = _load(path)
    except (OSError, SystemExit) as exc:
        raise SystemExit(f"formal C3 evidence is unreadable: {path}") from exc
    if actual.size != expected.size:
        raise SystemExit(f"formal C3 evidence size mismatch: {path} {actual.size} != {expected.size}")
    if actual.tobytes() != expected.tobytes():
        raise SystemExit(f"formal C3 evidence is stale or pixel-corrupt: {path}")


def _check_formal_json(path: Path, expected: dict) -> None:
    if not path.is_file():
        raise SystemExit(f"missing formal C3 evidence JSON: {path}")
    try:
        actual = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise SystemExit(f"formal C3 evidence JSON is unreadable: {path}") from exc
    if actual != expected:
        raise SystemExit(f"formal C3 evidence JSON is stale or corrupt: {path}")


def _check_formal_bundle(formal_images: dict[Path, Image.Image], report: dict, report_path: Path) -> None:
    formal_bytes_before = {
        path: path.read_bytes() for path in formal_images if path.is_file()
    }
    report_bytes_before = report_path.read_bytes() if report_path.is_file() else None
    for path, expected in formal_images.items():
        _check_formal_png(path, expected)
    _check_formal_json(report_path, report)
    for path, original in formal_bytes_before.items():
        if path.read_bytes() != original:
            raise SystemExit(f"read-only check observed a formal PNG mutation: {path}")
    if report_bytes_before is not None and report_path.read_bytes() != report_bytes_before:
        raise SystemExit(f"read-only check observed a formal JSON mutation: {report_path}")


def _self_test() -> None:
    """隔離tmpでformal PNG/JSONのstale・破損拒否とbytes不変を検証する。"""
    with tempfile.TemporaryDirectory(prefix="tsuri_cooking_c3_evidence_test_") as temp_dir:
        root = Path(temp_dir)
        formal = root / "formal.png"
        report = root / "formal.json"
        expected = Image.new("RGBA", (8, 4), (12, 18, 28, 255))
        expected.putpixel((3, 2), (255, 239, 190, 220))
        expected.save(formal, format="PNG", optimize=False)
        expected_report = {"contract": "C3 read-only evidence"}
        report.write_text(json.dumps(expected_report) + "\n", encoding="utf-8")
        _check_formal_bundle({formal: expected}, expected_report, report)

        formal.write_bytes(b"broken-png")
        broken_png_bytes = formal.read_bytes()
        try:
            _check_formal_bundle({formal: expected}, expected_report, report)
        except SystemExit:
            pass
        else:
            raise AssertionError("corrupt formal PNG must be rejected")
        if formal.read_bytes() != broken_png_bytes:
            raise AssertionError("formal PNG self-test changed corrupt bytes")

        expected.save(formal, format="PNG", optimize=False)
        stale = expected.copy()
        stale.putpixel((4, 2), (39, 193, 164, 190))
        stale.save(formal, format="PNG", optimize=False)
        stale_png_bytes = formal.read_bytes()
        try:
            _check_formal_bundle({formal: expected}, expected_report, report)
        except SystemExit:
            pass
        else:
            raise AssertionError("decoded pixel-stale formal PNG must be rejected")
        if formal.read_bytes() != stale_png_bytes:
            raise AssertionError("formal PNG stale self-test changed bytes")

        expected.save(formal, format="PNG", optimize=False)
        report.write_text("{broken-json", encoding="utf-8")
        broken_json_bytes = report.read_bytes()
        try:
            _check_formal_bundle({formal: expected}, expected_report, report)
        except SystemExit:
            pass
        else:
            raise AssertionError("corrupt formal JSON must be rejected")
        if report.read_bytes() != broken_json_bytes:
            raise AssertionError("formal JSON self-test changed corrupt bytes")

        report.write_text(json.dumps({"contract": "different but valid"}) + "\n", encoding="utf-8")
        stale_json_bytes = report.read_bytes()
        try:
            _check_formal_bundle({formal: expected}, expected_report, report)
        except SystemExit:
            pass
        else:
            raise AssertionError("valid but stale formal JSON must be rejected")
        if report.read_bytes() != stale_json_bytes:
            raise AssertionError("formal JSON stale self-test changed bytes")

    print("C3 evidence self-test passed: corrupt formal PNG/JSON rejected, bytes preserved")


def main() -> int:
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--check", action="store_true", help="read-only validation of fresh captures and formal evidence")
    mode.add_argument("--update", action="store_true", help="explicitly write formal PNG/JSON evidence")
    mode.add_argument("--self-test", action="store_true", help="run isolated formal evidence corruption checks")
    args = parser.parse_args()
    if not (args.check or args.update or args.self_test):
        parser.error("one of --check, --update, or --self-test is required")
    if args.self_test:
        _self_test()
        return 0

    formal_images, report = _build_bundle()
    if args.check:
        _check_formal_bundle(formal_images, report, REPORT_PATH)
        for state, details in report["regression"].items():
            if state != "EXP_GAIN" and not bool(details["pixel_identical"]):
                raise SystemExit(f"C3 changed non-EXP_GAIN state: {state} bbox={details['diff_bbox']}")
        print(f"C3 evidence check passed (read-only): {REPORT_PATH}")
    else:
        for path, image in formal_images.items():
            _write(path, image)
        REPORT_PATH.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"C3 evidence updated: {REPORT_PATH}")
    for state, details in report["regression"].items():
        print(f"{state}: pixel_identical={details['pixel_identical']} diff_bbox={details['diff_bbox']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
