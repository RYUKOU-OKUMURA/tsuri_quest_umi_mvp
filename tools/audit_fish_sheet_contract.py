#!/usr/bin/env python3
"""Audit fight fish showcase sheets.

Contract:
- every ``*_showcase_sheet.png`` is 2560x320
- each sheet contains 4 horizontal frames of 640x320
- each frame contains one meaningful fish alpha cluster
- fish data anchors should land on, or very near, frame-0 alpha

The audit cannot determine fish facing direction reliably. Head direction remains
a visual QA checklist item in ``docs/qa/underwater_fight_qa.md``.
"""
from __future__ import annotations

import re
import sys
from collections import deque
from pathlib import Path

from PIL import Image

try:
    import numpy as np
    from scipy import ndimage as ndi
except Exception:  # pragma: no cover - local fallback for lean Python envs
    np = None
    ndi = None


ROOT = Path(__file__).resolve().parents[1]
FISH_DIR = ROOT / "assets" / "showcase" / "fish"
GAME_DATA_FILES = [
    ROOT / "src" / "autoload" / "game_catalog_data.gd",
    ROOT / "src" / "autoload" / "fish_expansion_data.gd",
]

SHEET_SIZE = (2560, 320)
FRAME_COUNT = 4
FRAME_SIZE = (640, 320)
ALPHA_THRESHOLD = 8
MIN_COMPONENT_RATIO = 0.05
COMPONENT_BRIDGE_PIXELS = 3
ANCHOR_NEAR_ALPHA_MAX_DISTANCE = 48.0
ANCHOR_X_RANGE = (0.20, 0.50)
ANCHOR_Y_RANGE = (-0.22, 0.22)
ANCHOR_RANGE_TOLERANCE = 0.05


def main() -> int:
    failures: list[str] = []
    sheet_paths = sorted(FISH_DIR.glob("*_showcase_sheet.png"))
    if not sheet_paths:
        failures.append(f"no showcase sheets found under {FISH_DIR}")

    anchors_by_asset_id = _load_anchor_data()
    for path in sheet_paths:
        _audit_sheet(path, anchors_by_asset_id, failures)

    if failures:
        print("fish sheet contract audit failed:")
        for failure in failures:
            print(f"- {failure}")
        return 1

    print(f"fish sheet contract audit passed: {len(sheet_paths)} sheets")
    return 0


def _audit_sheet(path: Path, anchors_by_asset_id: dict[str, tuple[float, float]], failures: list[str]) -> None:
    try:
        image = Image.open(path).convert("RGBA")
    except OSError as exc:
        failures.append(f"{path.name}: failed to load PNG: {exc}")
        return

    if image.size != SHEET_SIZE:
        failures.append(f"{path.name}: expected size {SHEET_SIZE[0]}x{SHEET_SIZE[1]}, got {image.width}x{image.height}")
        return

    asset_id = path.name.removesuffix("_showcase_sheet.png")
    for index in range(FRAME_COUNT):
        x0 = index * FRAME_SIZE[0]
        frame = image.crop((x0, 0, x0 + FRAME_SIZE[0], FRAME_SIZE[1]))
        _audit_frame_components(path.name, index, frame, failures)
        if index == 0:
            anchor = anchors_by_asset_id.get(asset_id)
            if anchor is None:
                failures.append(f"{path.name}: no fish data line_anchor_x/y found for asset id '{asset_id}'")
            else:
                _audit_anchor(path.name, frame, anchor, failures)


def _audit_frame_components(sheet_name: str, frame_index: int, frame: Image.Image, failures: list[str]) -> None:
    if np is not None and ndi is not None:
        alpha = np.array(frame.getchannel("A"), dtype=np.uint8) > ALPHA_THRESHOLD
        total_alpha = int(alpha.sum())
        if total_alpha <= 0:
            failures.append(f"{sheet_name}: frame {frame_index} has no alpha content")
            return
        # Bridge tiny seams in a single stylized fish, while keeping two 320px-packed fish separated.
        component_mask = ndi.binary_dilation(alpha, iterations=COMPONENT_BRIDGE_PIXELS)
        labels, _count = ndi.label(component_mask)
        sizes = np.bincount(labels.ravel())[1:]
        significant = [int(size) for size in sizes if size >= total_alpha * MIN_COMPONENT_RATIO]
    else:
        alpha_mask = _alpha_mask(frame)
        total_alpha = sum(1 for row in alpha_mask for value in row if value)
        if total_alpha <= 0:
            failures.append(f"{sheet_name}: frame {frame_index} has no alpha content")
            return
        bridged = _dilate_mask(alpha_mask, COMPONENT_BRIDGE_PIXELS)
        sizes = _component_sizes(bridged)
        significant = [size for size in sizes if size >= total_alpha * MIN_COMPONENT_RATIO]

    if len(significant) != 1:
        significant_total = max(1, sum(significant))
        ratios = ", ".join(f"{size / significant_total:.2f}" for size in sorted(significant, reverse=True)[:4])
        failures.append(
            f"{sheet_name}: frame {frame_index} has {len(significant)} significant alpha clusters"
            f" (ratios: {ratios or 'none'})"
        )


def _audit_anchor(sheet_name: str, frame: Image.Image, anchor: tuple[float, float], failures: list[str]) -> None:
    anchor_x, anchor_y = anchor
    if not (ANCHOR_X_RANGE[0] - ANCHOR_RANGE_TOLERANCE <= anchor_x <= ANCHOR_X_RANGE[1] + ANCHOR_RANGE_TOLERANCE):
        failures.append(
            f"{sheet_name}: line_anchor_x {anchor_x:.3f} far outside runtime clamp range"
            f" [{ANCHOR_X_RANGE[0]:.2f}, {ANCHOR_X_RANGE[1]:.2f}]"
        )
        return
    if not (ANCHOR_Y_RANGE[0] - ANCHOR_RANGE_TOLERANCE <= anchor_y <= ANCHOR_Y_RANGE[1] + ANCHOR_RANGE_TOLERANCE):
        failures.append(
            f"{sheet_name}: line_anchor_y {anchor_y:.3f} far outside runtime clamp range"
            f" [{ANCHOR_Y_RANGE[0]:.2f}, {ANCHOR_Y_RANGE[1]:.2f}]"
        )
        return
    clamped_x = _clamp(anchor_x, ANCHOR_X_RANGE[0], ANCHOR_X_RANGE[1])
    clamped_y = _clamp(anchor_y, ANCHOR_Y_RANGE[0], ANCHOR_Y_RANGE[1])
    px = round(FRAME_SIZE[0] / 2 + clamped_x * FRAME_SIZE[0])
    py = round(FRAME_SIZE[1] / 2 + clamped_y * FRAME_SIZE[1])
    px = int(_clamp(px, 0, FRAME_SIZE[0] - 1))
    py = int(_clamp(py, 0, FRAME_SIZE[1] - 1))

    distance = _distance_to_alpha(frame, px, py)
    if distance is None or distance > ANCHOR_NEAR_ALPHA_MAX_DISTANCE:
        distance_text = "none" if distance is None else f"{distance:.1f}px"
        failures.append(
            f"{sheet_name}: frame 0 line anchor ({anchor_x:.3f}, {anchor_y:.3f})"
            f" resolves to ({px}, {py}), nearest alpha distance {distance_text}"
        )


def _distance_to_alpha(frame: Image.Image, px: int, py: int) -> float | None:
    alpha = frame.getchannel("A")
    if alpha.getpixel((px, py)) > ALPHA_THRESHOLD:
        return 0.0

    if np is not None and ndi is not None:
        mask = np.array(alpha, dtype=np.uint8) > ALPHA_THRESHOLD
        if not bool(mask.any()):
            return None
        distances = ndi.distance_transform_edt(~mask)
        return float(distances[py, px])

    pix = alpha.load()
    max_radius = int(ANCHOR_NEAR_ALPHA_MAX_DISTANCE) + 16
    best_sq: int | None = None
    for radius in range(1, max_radius + 1):
        x0 = max(0, px - radius)
        x1 = min(FRAME_SIZE[0] - 1, px + radius)
        y0 = max(0, py - radius)
        y1 = min(FRAME_SIZE[1] - 1, py + radius)
        for x in range(x0, x1 + 1):
            for y in (y0, y1):
                if pix[x, y] > ALPHA_THRESHOLD:
                    dist_sq = (x - px) ** 2 + (y - py) ** 2
                    best_sq = dist_sq if best_sq is None else min(best_sq, dist_sq)
        for y in range(y0 + 1, y1):
            for x in (x0, x1):
                if pix[x, y] > ALPHA_THRESHOLD:
                    dist_sq = (x - px) ** 2 + (y - py) ** 2
                    best_sq = dist_sq if best_sq is None else min(best_sq, dist_sq)
        if best_sq is not None:
            return best_sq ** 0.5
    return None


def _load_anchor_data() -> dict[str, tuple[float, float]]:
    anchors: dict[str, tuple[float, float]] = {}
    for path in GAME_DATA_FILES:
        anchors.update(_parse_anchor_file(path))

    # FightFishAssets.asset_id() maps boss_kurodai onto the shared kurodai sheet.
    if "boss_kurodai" in anchors:
        anchors["kurodai"] = anchors["boss_kurodai"]
    return anchors


def _parse_anchor_file(path: Path) -> dict[str, tuple[float, float]]:
    anchors: dict[str, tuple[float, float]] = {}
    text = path.read_text(encoding="utf-8")

    for line in text.splitlines():
        fish_id = _match_value(line, "id")
        x_value = _match_float(line, "line_anchor_x")
        y_value = _match_float(line, "line_anchor_y")
        if fish_id is not None and x_value is not None and y_value is not None:
            anchors[fish_id] = (x_value, y_value)

    current_id: str | None = None
    current_x: float | None = None
    current_y: float | None = None
    for line in text.splitlines():
        fish_id = _match_value(line, "id")
        if fish_id is not None:
            current_id = fish_id
            current_x = None
            current_y = None
        x_value = _match_float(line, "line_anchor_x")
        if x_value is not None:
            current_x = x_value
        y_value = _match_float(line, "line_anchor_y")
        if y_value is not None:
            current_y = y_value
        if current_id is not None and current_x is not None and current_y is not None:
            anchors[current_id] = (current_x, current_y)
            current_id = None
            current_x = None
            current_y = None
    return anchors


def _match_value(line: str, key: str) -> str | None:
    match = re.search(rf'"{re.escape(key)}"\s*:\s*"([^"]+)"', line)
    return match.group(1) if match else None


def _match_float(line: str, key: str) -> float | None:
    match = re.search(rf'"{re.escape(key)}"\s*:\s*([-0-9.]+)', line)
    return float(match.group(1)) if match else None


def _alpha_mask(frame: Image.Image) -> list[list[bool]]:
    alpha = frame.getchannel("A")
    pix = alpha.load()
    return [[pix[x, y] > ALPHA_THRESHOLD for x in range(FRAME_SIZE[0])] for y in range(FRAME_SIZE[1])]


def _dilate_mask(mask: list[list[bool]], iterations: int) -> list[list[bool]]:
    current = mask
    for _ in range(iterations):
        next_mask = [row[:] for row in current]
        for y, row in enumerate(current):
            for x, value in enumerate(row):
                if not value:
                    continue
                for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
                    if 0 <= nx < FRAME_SIZE[0] and 0 <= ny < FRAME_SIZE[1]:
                        next_mask[ny][nx] = True
        current = next_mask
    return current


def _component_sizes(mask: list[list[bool]]) -> list[int]:
    seen = [[False for _x in range(FRAME_SIZE[0])] for _y in range(FRAME_SIZE[1])]
    sizes: list[int] = []
    for y in range(FRAME_SIZE[1]):
        for x in range(FRAME_SIZE[0]):
            if seen[y][x] or not mask[y][x]:
                continue
            seen[y][x] = True
            queue: deque[tuple[int, int]] = deque([(x, y)])
            size = 0
            while queue:
                cx, cy = queue.popleft()
                size += 1
                for nx, ny in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if 0 <= nx < FRAME_SIZE[0] and 0 <= ny < FRAME_SIZE[1] and not seen[ny][nx] and mask[ny][nx]:
                        seen[ny][nx] = True
                        queue.append((nx, ny))
            sizes.append(size)
    return sizes


def _clamp(value: float, min_value: float, max_value: float) -> float:
    return max(min_value, min(max_value, value))


if __name__ == "__main__":
    sys.exit(main())
