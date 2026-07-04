#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_HOME="${TSURI_GODOT_HOME:-/tmp/tsuri_market_home}"

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
rm -f \
  /tmp/tsuri_market_select.png \
  /tmp/tsuri_market_sold.png \
  /tmp/tsuri_market_empty.png \
  /tmp/tsuri_market_select_compare.png \
  /tmp/tsuri_market_sold_compare.png \
  /tmp/tsuri_market_empty_compare.png

echo "==> Capture market previews"
HOME="$GODOT_HOME" "$GODOT" --path "$ROOT" "res://tools/market_preview.tscn"

python3 - <<'PY'
from pathlib import Path
from PIL import Image

for path in [
    Path("/tmp/tsuri_market_select.png"),
    Path("/tmp/tsuri_market_sold.png"),
    Path("/tmp/tsuri_market_empty.png"),
]:
    img = Image.open(path).convert("RGB")
    pixels = img.getdata()
    visible = sum(1 for r, g, b in pixels if r + g + b > 80)
    ratio = visible / float(img.width * img.height)
    if ratio < 0.20:
        raise SystemExit(f"{path} looks blank or nearly black: visible_ratio={ratio:.3f}")
PY

echo "==> Build market side-by-side QA outputs"
python3 "$ROOT/tools/build_screen_visual_comparison.py" market

echo "Market visual QA outputs:"
echo "/tmp/tsuri_market_select.png"
echo "/tmp/tsuri_market_sold.png"
echo "/tmp/tsuri_market_empty.png"
echo "/tmp/tsuri_market_select_compare.png"
echo "/tmp/tsuri_market_sold_compare.png"
echo "/tmp/tsuri_market_empty_compare.png"
