#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_HOME="${TSURI_GODOT_HOME:-/tmp/tsuri_fishing_spot_home}"

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
  /tmp/tsuri_fishing_spot_map.png
  /tmp/tsuri_fishing_spot_map_continue.png
  /tmp/tsuri_fishing_spot_map_danger_chart.png
)
rm -f "${CAPTURES[@]}" \
  /tmp/tsuri_fishing_spot_map_compare.png \
  /tmp/tsuri_fishing_spot_map_continue_compare.png \
  /tmp/tsuri_fishing_spot_map_danger_chart_compare.png

echo "==> Capture fishing spot map previews"
HOME="$GODOT_HOME" "$GODOT" --path "$ROOT" "res://tools/fishing_spot_map_preview.tscn"

for capture in "${CAPTURES[@]}"; do
  if [[ ! -s "$capture" ]]; then
    echo "Fishing spot map preview did not create expected capture: $capture" >&2
    exit 1
  fi
done

echo "==> Build fishing spot map side-by-side QA outputs"
python3 "$ROOT/tools/build_screen_visual_comparison.py" fishing_spot_map

echo "Fishing spot map visual QA outputs:"
echo "/tmp/tsuri_fishing_spot_map.png"
echo "/tmp/tsuri_fishing_spot_map_continue.png"
echo "/tmp/tsuri_fishing_spot_map_danger_chart.png"
echo "/tmp/tsuri_fishing_spot_map_compare.png"
echo "/tmp/tsuri_fishing_spot_map_continue_compare.png"
echo "/tmp/tsuri_fishing_spot_map_danger_chart_compare.png"
