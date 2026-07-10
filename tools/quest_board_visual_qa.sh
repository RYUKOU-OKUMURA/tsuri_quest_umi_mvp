#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_HOME="${TSURI_GODOT_HOME:-/tmp/tsuri_quest_board_qa_home}"

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

prepare_godot_home() {
  if [[ -z "${TSURI_GODOT_HOME:-}" ]]; then
    rm -rf "$GODOT_HOME"
  fi
  mkdir -p "$GODOT_HOME"
}

rm -f \
  /tmp/tsuri_quest_board.png \
  /tmp/tsuri_quest_board_compare.png \
  /tmp/tsuri_quest_board_long_text_a.png \
  /tmp/tsuri_quest_board_long_text_b.png

if [[ "${QUEST_BOARD_REFRESH_REFERENCE:-0}" == "1" ]]; then
  echo "==> Refresh quest board reference"
  python3 "$ROOT/tools/build_quest_board_reference.py"
else
  echo "==> Use checked-in quest board reference"
fi

echo "==> Capture quest board preview"
prepare_godot_home
HOME="$GODOT_HOME" "$GODOT" --path "$ROOT" "res://tools/quest_board_preview.tscn"
sleep 1

echo "==> Capture long condition cases"
prepare_godot_home
QUEST_BOARD_PREVIEW_MODE=long_text_a HOME="$GODOT_HOME" "$GODOT" --path "$ROOT" "res://tools/quest_board_preview.tscn"
sleep 1
prepare_godot_home
QUEST_BOARD_PREVIEW_MODE=long_text_b HOME="$GODOT_HOME" "$GODOT" --path "$ROOT" "res://tools/quest_board_preview.tscn"

python3 - <<'PY'
from pathlib import Path
from PIL import Image

for path in [
    Path("/tmp/tsuri_quest_board.png"),
    Path("/tmp/tsuri_quest_board_long_text_a.png"),
    Path("/tmp/tsuri_quest_board_long_text_b.png"),
]:
    rgba = Image.open(path).convert("RGBA")
    alpha = rgba.getchannel("A")
    alpha_extrema = alpha.getextrema()
    if alpha_extrema != (255, 255):
        raise SystemExit(f"{path} contains a transparent capture region: alpha_extrema={alpha_extrema}")
    img = rgba.convert("RGB")
    visible = sum(1 for r, g, b in img.getdata() if r + g + b > 80)
    ratio = visible / float(img.width * img.height)
    if ratio < 0.20:
        raise SystemExit(f"{path} looks blank or nearly black: visible_ratio={ratio:.3f}")
    header = img.crop((0, 0, img.width, 120))
    header_visible = sum(1 for r, g, b in header.getdata() if r + g + b > 80)
    header_ratio = header_visible / float(header.width * header.height)
    if header_ratio < 0.20:
        raise SystemExit(f"{path} is missing the stable header: header_visible_ratio={header_ratio:.3f}")
PY

echo "==> Build quest board side-by-side QA output"
python3 "$ROOT/tools/build_screen_visual_comparison.py" quest_board

echo "Quest board visual QA outputs:"
echo "/tmp/tsuri_quest_board.png"
echo "/tmp/tsuri_quest_board_compare.png"
echo "/tmp/tsuri_quest_board_long_text_a.png"
echo "/tmp/tsuri_quest_board_long_text_b.png"
