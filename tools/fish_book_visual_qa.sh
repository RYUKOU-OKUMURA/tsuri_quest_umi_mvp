#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_HOME="${TSURI_GODOT_HOME:-/tmp/tsuri_fish_book_home}"

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
CAPTURES=(/tmp/tsuri_fish_book.png)
rm -f "${CAPTURES[@]}" /tmp/tsuri_fish_book_compare.png

echo "==> Capture fish book preview"
HOME="$GODOT_HOME" "$GODOT" --path "$ROOT" "res://tools/fish_book_preview.tscn"

for capture in "${CAPTURES[@]}"; do
  if [[ ! -s "$capture" ]]; then
    echo "Fish book preview did not create expected capture: $capture" >&2
    exit 1
  fi
done

echo "==> Build fish book side-by-side QA output"
python3 "$ROOT/tools/build_screen_visual_comparison.py" fish_book

echo "Fish book visual QA output:"
echo "/tmp/tsuri_fish_book.png"
echo "/tmp/tsuri_fish_book_compare.png"
