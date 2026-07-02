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
rm -f /tmp/tsuri_status.png /tmp/tsuri_status_compare.png

echo "==> Capture status preview"
HOME="$GODOT_HOME" "$GODOT" --path "$ROOT" "res://tools/status_preview.tscn"

echo "==> Build status side-by-side QA output"
python3 "$ROOT/tools/build_screen_visual_comparison.py" status

echo "Status visual QA output:"
echo "/tmp/tsuri_status.png"
echo "/tmp/tsuri_status_compare.png"
