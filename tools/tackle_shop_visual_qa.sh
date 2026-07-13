#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_HOME="${TSURI_GODOT_HOME:-/tmp/tsuri_tackle_shop_home}"

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
  /tmp/tsuri_tackle_shop_rod.png
  /tmp/tsuri_tackle_shop_rig.png
  /tmp/tsuri_tackle_shop_rod_expanded.png
  /tmp/tsuri_tackle_shop_rig_expanded.png
)
rm -f "${CAPTURES[@]}" \
  /tmp/tsuri_tackle_shop_rod_compare.png \
  /tmp/tsuri_tackle_shop_rig_compare.png \
  /tmp/tsuri_tackle_shop_rod_expanded_compare.png \
  /tmp/tsuri_tackle_shop_rig_expanded_compare.png

echo "==> Capture tackle shop previews"
HOME="$GODOT_HOME" "$GODOT" --path "$ROOT" "res://tools/tackle_shop_preview.tscn"

for capture in "${CAPTURES[@]}"; do
  if [[ ! -s "$capture" ]]; then
    echo "Tackle shop preview did not create expected capture: $capture" >&2
    exit 1
  fi
done

echo "==> Build tackle shop side-by-side QA outputs"
python3 "$ROOT/tools/build_screen_visual_comparison.py" tackle_shop

echo "Tackle shop visual QA outputs:"
echo "/tmp/tsuri_tackle_shop_rod.png"
echo "/tmp/tsuri_tackle_shop_rig.png"
echo "/tmp/tsuri_tackle_shop_rod_expanded.png"
echo "/tmp/tsuri_tackle_shop_rig_expanded.png"
echo "/tmp/tsuri_tackle_shop_rod_compare.png"
echo "/tmp/tsuri_tackle_shop_rig_compare.png"
echo "/tmp/tsuri_tackle_shop_rod_expanded_compare.png"
echo "/tmp/tsuri_tackle_shop_rig_expanded_compare.png"
