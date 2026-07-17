#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_HOME="${TSURI_GODOT_HOME:-/tmp/tsuri_status_home}"

if [[ -n "${GODOT_BIN:-}" ]]; then
  GODOT="$GODOT_BIN"
elif command -v godot >/dev/null 2>&1; then
  GODOT=godot
elif command -v godot4 >/dev/null 2>&1; then
  GODOT=godot4
elif [[ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]]; then
  GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
else
  echo "Godot 4.x was not found. Set GODOT_BIN to the Godot executable." >&2
  exit 1
fi

mkdir -p "$GODOT_HOME"
CAPTURES=(
  /tmp/tsuri_status_normal.png
  /tmp/tsuri_status_hard.png
  /tmp/tsuri_status_long_content.png
  /tmp/tsuri_status_title_overlay.png
)
rm -f "${CAPTURES[@]}" /tmp/tsuri_status_normal_compare.png /tmp/tsuri_status_hard_compare.png

echo "==> Capture status normal preview"
TSURI_STATUS_DIFFICULTY=normal HOME="$GODOT_HOME" "$GODOT" --path "$ROOT" "res://tools/status_preview.tscn"

echo "==> Capture status hard preview"
TSURI_STATUS_DIFFICULTY=hard HOME="$GODOT_HOME" "$GODOT" --path "$ROOT" "res://tools/status_preview.tscn"

echo "==> Capture status long-content preview"
TSURI_STATUS_DIFFICULTY=hard TSURI_STATUS_LONG_CONTENT=1 HOME="$GODOT_HOME" "$GODOT" --path "$ROOT" "res://tools/status_preview.tscn"

echo "==> Capture status title-overlay preview"
TSURI_STATUS_DIFFICULTY=normal TSURI_STATUS_TITLE_OVERLAY=1 HOME="$GODOT_HOME" "$GODOT" --path "$ROOT" "res://tools/status_preview.tscn"

for capture in "${CAPTURES[@]}"; do
  if [[ ! -s "$capture" ]]; then
    echo "Status preview did not create expected capture: $capture" >&2
    exit 1
  fi
done

echo "==> Build status side-by-side QA output"
python3 "$ROOT/tools/build_screen_visual_comparison.py" status

echo "Status visual QA output:"
echo "/tmp/tsuri_status_normal.png"
echo "/tmp/tsuri_status_hard.png"
echo "/tmp/tsuri_status_long_content.png"
echo "/tmp/tsuri_status_title_overlay.png"
echo "/tmp/tsuri_status_normal_compare.png"
echo "/tmp/tsuri_status_hard_compare.png"
