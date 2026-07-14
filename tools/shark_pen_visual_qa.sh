#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_HOME="${TSURI_GODOT_HOME:-/tmp/tsuri_shark_pen_home}"

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
rm -f /tmp/tsuri_shark_pen.png \
  /tmp/tsuri_shark_pen_selected_hover.png \
  /tmp/tsuri_shark_pen_compare.png \
  /tmp/tsuri_shark_pen_selected_hover_compare.png

if [[ ! -f "$ROOT/reference/12_shark_pen_mockup.png" ]]; then
  echo "Missing reference/12_shark_pen_mockup.png" >&2
  exit 1
fi

echo "==> Capture shark pen preview"
HOME="$GODOT_HOME" "$GODOT" --path "$ROOT" "res://tools/shark_pen_preview.tscn"

python3 - <<'PY'
from pathlib import Path
from PIL import Image

for path in (
    Path("/tmp/tsuri_shark_pen.png"),
    Path("/tmp/tsuri_shark_pen_selected_hover.png"),
):
    img = Image.open(path).convert("RGB")
    visible = sum(1 for r, g, b in img.getdata() if r + g + b > 80)
    ratio = visible / float(img.width * img.height)
    if ratio < 0.20:
        raise SystemExit(f"{path} looks blank or nearly black: visible_ratio={ratio:.3f}")
PY

echo "==> Build shark pen side-by-side QA output"
python3 "$ROOT/tools/build_screen_visual_comparison.py" shark_pen

ROOT="$ROOT" python3 - <<'PY'
import os
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(os.environ["ROOT"])
reference = Image.open(root / "reference/12_shark_pen_mockup.png").convert("RGB")
current = Image.open("/tmp/tsuri_shark_pen_selected_hover.png").convert("RGB")
header = 34
board = Image.new("RGB", (reference.width + current.width, max(reference.height, current.height) + header), (8, 20, 31))
board.paste(reference, (0, header))
board.paste(current, (reference.width, header))
draw = ImageDraw.Draw(board)
draw.text((8, 9), "REFERENCE", fill=(244, 232, 205))
draw.text((reference.width + 8, 9), "CURRENT SELECTED / HOVER", fill=(244, 232, 205))
board.save("/tmp/tsuri_shark_pen_selected_hover_compare.png")
PY

echo "Shark pen visual QA outputs:"
echo "/tmp/tsuri_shark_pen.png"
echo "/tmp/tsuri_shark_pen_selected_hover.png"
echo "/tmp/tsuri_shark_pen_compare.png"
echo "/tmp/tsuri_shark_pen_selected_hover_compare.png"
