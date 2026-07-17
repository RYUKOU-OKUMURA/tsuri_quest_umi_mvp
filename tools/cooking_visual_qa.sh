#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_HOME="${TSURI_GODOT_HOME:-/tmp/tsuri_cooking_home}"

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
  /tmp/tsuri_cooking.png
  /tmp/tsuri_cooking_select.png
  /tmp/tsuri_cooking_result.png
  /tmp/tsuri_cooking_exp.png
  /tmp/tsuri_cooking_levelup.png
  /tmp/tsuri_cooking_status.png
  /tmp/tsuri_cooking_c1b_hover_focus.png
  /tmp/tsuri_cooking_capture_manifest.json
)

for capture in "${CAPTURES[@]}"; do
  rm -f "$capture"
done

echo "==> Capture cooking reference states"
set +e
TSURI_QA_DETERMINISTIC=1 HOME="$GODOT_HOME" "$GODOT" --path "$ROOT" "res://tools/cooking_preview.tscn"
capture_status=$?
set -e

if [[ "$capture_status" -ne 0 ]]; then
  echo "Cooking preview capture failed with exit code $capture_status." >&2
  echo "Refreshing the reference report with missing-capture diagnostics." >&2
  python3 "$ROOT/tools/cooking_visual_qa_check.py" --allow-missing
  exit "$capture_status"
fi

echo "==> Check cooking captures and refresh report"
python3 "$ROOT/tools/cooking_visual_qa_check.py"

echo "Cooking visual QA passed."
