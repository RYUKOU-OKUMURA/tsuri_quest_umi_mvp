#!/usr/bin/env python3
"""FIGHT-A2のallowed-diffと状態回帰を検査し、正式比較evidenceを作る。"""

from __future__ import annotations

import argparse
from pathlib import Path
import tempfile

from PIL import Image, ImageChops

from process_fight_a2_slim_bar import write_if_changed


ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ROOT / "docs/qa/evidence/underwater_fight"
REFERENCE = ROOT / "reference" / "14_underwater_fight_simple_mockup.png"
DEFAULT_BEFORE = EVIDENCE / "2026-07-17_v2_prebaseline_standard.png"
DEFAULT_FOCUS_BEFORE = EVIDENCE / "2026-07-17_v2_prebaseline_focus.png"
# 1280x720 screen上のFightHud実Rect。root margin 6pxと上部/scene gapを含む。
HUD_BOX = (6, 574, 1274, 714)
FOCUS_RING_BOX = (443, 628, 636, 692)
REFERENCE_HUD_BOX = (0, 756, 1536, 1002)
READY_HUD_BOX = (6, 490, 955, 714)
REQUIRED_PIXEL_STATES = ("ready", "casting", "waiting", "approach", "bite")
STATE_PROBE_BOX = (6, 574, 1274, 714)


def opened(path: Path) -> Image.Image:
    with Image.open(path) as source:
        source.load()
        image = source.convert("RGB")
    if image.size != (1280, 720):
        raise ValueError(f"capture must be 1280x720: {path} {image.size}")
    return image


def difference(before: Image.Image, after: Image.Image) -> Image.Image:
    return ImageChops.difference(before.convert("RGB"), after.convert("RGB"))


def assert_only_inside(diff: Image.Image, allowed: tuple[int, int, int, int], label: str) -> tuple[int, int, int, int]:
    bbox = diff.getbbox()
    if bbox is None:
        raise ValueError(f"{label} has no pixel difference")
    outside = diff.copy()
    outside.paste((0, 0, 0), allowed)
    if outside.getbbox() is not None:
        raise ValueError(f"{label} changed outside allowed rect {allowed}: {outside.getbbox()}")
    return bbox


def assert_identical(before_path: Path, after_path: Path, label: str) -> None:
    before = opened(before_path)
    after = opened(after_path)
    bbox = difference(before, after).getbbox()
    if bbox is not None:
        raise ValueError(f"{label} must remain pixel-identical: diff={bbox}")


def assert_required_pixel_regressions(regressions: list[tuple[str, Path, Path]]) -> None:
    labels = [label for label, _before, _after in regressions]
    missing = [label for label in REQUIRED_PIXEL_STATES if labels.count(label) == 0]
    duplicate = sorted({label for label in labels if labels.count(label) > 1})
    unexpected = sorted(set(labels) - set(REQUIRED_PIXEL_STATES))
    if missing or duplicate or unexpected or len(labels) != len(REQUIRED_PIXEL_STATES):
        raise ValueError(
            "pixel-identical regression requires each state exactly once: "
            f"required={REQUIRED_PIXEL_STATES} missing={missing} "
            f"duplicate={duplicate} unexpected={unexpected}"
        )
    for label, before_path, after_path in regressions:
        assert_identical(before_path, after_path, label)
    by_label = {label: (opened(before), opened(after)) for label, before, after in regressions}
    for side_index, side in enumerate(("before", "after")):
        previous_label = ""
        previous_probe: Image.Image | None = None
        for label in REQUIRED_PIXEL_STATES:
            probe = by_label[label][side_index].crop(STATE_PROBE_BOX)
            if previous_probe is not None and difference(previous_probe, probe).getbbox() is None:
                raise ValueError(
                    f"stale state capture: {side} {label} reused {previous_label} HUD pixels"
                )
            previous_label = label
            previous_probe = probe


def parse_regression(value: str) -> tuple[str, Path, Path]:
    parts = value.split(":", 2)
    if len(parts) != 3:
        raise argparse.ArgumentTypeError("regression must be LABEL:BEFORE:AFTER")
    return parts[0], Path(parts[1]), Path(parts[2])


def parse_hud_regression(value: str) -> tuple[str, Path, Path, str]:
    parts = value.split(":", 3)
    if len(parts) != 4 or parts[3] not in {"ready", "slim"}:
        raise argparse.ArgumentTypeError("HUD regression must be LABEL:BEFORE:AFTER:ready|slim")
    return parts[0], Path(parts[1]), Path(parts[2]), parts[3]


def main(args: argparse.Namespace) -> None:
    before = opened(args.before)
    after = opened(args.after)
    focus_before = opened(args.focus_before)
    focus_after = opened(args.focus_after)

    full_bbox = assert_only_inside(difference(before, after), HUD_BOX, "FIGHT-A2 standard")
    before_focus_bbox = assert_only_inside(difference(before, focus_before), FOCUS_RING_BOX, "baseline focus")
    after_focus_bbox = assert_only_inside(difference(after, focus_after), FOCUS_RING_BOX, "FIGHT-A2 focus")
    if before_focus_bbox != after_focus_bbox:
        raise ValueError(
            f"focus ring geometry changed: before={before_focus_bbox} after={after_focus_bbox}"
        )
    assert_required_pixel_regressions(args.pixel_identical)
    for label, before_path, after_path, kind in args.hud_identical:
        before_hud = opened(before_path).crop(READY_HUD_BOX if kind == "ready" else HUD_BOX)
        after_hud = opened(after_path).crop(READY_HUD_BOX if kind == "ready" else HUD_BOX)
        bbox = difference(before_hud, after_hud).getbbox()
        if bbox is not None:
            raise ValueError(f"{label} HUD must remain pixel-identical: diff={bbox}")

    with Image.open(REFERENCE) as source:
        reference = source.convert("RGB")
    full_board = Image.new("RGB", (2560, 720), (5, 17, 29))
    full_board.paste(before, (0, 0))
    full_board.paste(after, (1280, 0))
    write_if_changed(EVIDENCE / "2026-07-17_fight_a2_standard_before_after.png", full_board.convert("RGBA"))

    small_board = Image.new("RGB", (640, 180), (5, 17, 29))
    small_board.paste(after.resize((320, 180), Image.Resampling.LANCZOS), (0, 0))
    small_board.paste(reference.resize((320, 180), Image.Resampling.LANCZOS), (320, 0))
    write_if_changed(EVIDENCE / "2026-07-17_fight_a2_after_reference_320x180.png", small_board.convert("RGBA"))

    before_bar = before.crop(HUD_BOX)
    after_bar = after.crop(HUD_BOX)
    reference_bar = reference.crop(REFERENCE_HUD_BOX).resize((1268, 140), Image.Resampling.LANCZOS)
    bar_board = Image.new("RGB", (1268, 420), (5, 17, 29))
    bar_board.paste(before_bar, (0, 0))
    bar_board.paste(after_bar, (0, 140))
    bar_board.paste(reference_bar, (0, 280))
    write_if_changed(EVIDENCE / "2026-07-17_fight_a2_bar_before_after_reference.png", bar_board.convert("RGBA"))

    write_if_changed(EVIDENCE / "2026-07-17_fight_a2_standard_after.png", after.convert("RGBA"))
    write_if_changed(EVIDENCE / "2026-07-17_fight_a2_focus_after.png", focus_after.convert("RGBA"))
    print(f"FIGHT-A2 standard allowed-diff: {full_bbox}; outside HUD: 0px")
    print(f"FIGHT-A2 focus ring geometry preserved: {after_focus_bbox}")
    print(f"FIGHT-A2 pixel-identical regression states: {len(args.pixel_identical)}")
    print(f"FIGHT-A2 pixel-identical HUD regression states: {len(args.hud_identical)}")


def self_test() -> None:
    with tempfile.TemporaryDirectory(prefix="fight-a2-evidence-self-test-") as tmp:
        root = Path(tmp)
        complete: list[tuple[str, Path, Path]] = []
        for index, label in enumerate(REQUIRED_PIXEL_STATES):
            before = root / f"{label}-before.png"
            after = root / f"{label}-after.png"
            Image.new("RGB", (1280, 720), (12 + index, 34, 56)).save(before)
            with Image.open(before) as source:
                source.save(after)
            complete.append((label, before, after))
        assert_required_pixel_regressions(complete)

        try:
            assert_required_pixel_regressions(complete[:-1])
        except ValueError:
            pass
        else:
            raise AssertionError("missing state was not rejected")

        corrupted = root / "corrupted.png"
        with Image.open(complete[2][2]) as source:
            damaged = source.convert("RGB")
        damaged.putpixel((640, 360), (255, 0, 0))
        damaged.save(corrupted)
        broken = list(complete)
        broken[2] = ("waiting", complete[2][1], corrupted)
        try:
            assert_required_pixel_regressions(broken)
        except ValueError:
            pass
        else:
            raise AssertionError("pixel corruption was not rejected")

        stale = list(complete)
        stale[3] = ("approach", complete[2][1], complete[2][2])
        try:
            assert_required_pixel_regressions(stale)
        except ValueError:
            pass
        else:
            raise AssertionError("stale state capture was not rejected")
    print("FIGHT-A2 evidence self-test: missing state / pixel corruption / stale state rejected")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--before", type=Path, default=DEFAULT_BEFORE)
    parser.add_argument("--after", type=Path)
    parser.add_argument("--focus-before", type=Path, default=DEFAULT_FOCUS_BEFORE)
    parser.add_argument("--focus-after", type=Path)
    parser.add_argument(
        "--pixel-identical",
        action="append",
        default=[],
        type=parse_regression,
        metavar="LABEL:BEFORE:AFTER",
    )
    parser.add_argument(
        "--hud-identical",
        action="append",
        default=[],
        type=parse_hud_regression,
        metavar="LABEL:BEFORE:AFTER:ready|slim",
    )
    parsed = parser.parse_args()
    if parsed.self_test:
        self_test()
    else:
        if parsed.after is None or parsed.focus_after is None:
            parser.error("--after and --focus-after are required unless --self-test is used")
        main(parsed)
