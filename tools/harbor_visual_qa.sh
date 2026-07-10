#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

GODOT=""
if command -v godot >/dev/null 2>&1; then
  GODOT=godot
elif command -v godot4 >/dev/null 2>&1; then
  GODOT=godot4
elif [[ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]]; then
  GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
fi

if [[ -z "$GODOT" ]]; then
  echo "Godot 4.x was not found." >&2
  exit 1
fi

FFMPEG="$(command -v ffmpeg || true)"
if [[ -z "$FFMPEG" ]]; then
  echo "ffmpeg was not found." >&2
  exit 1
fi

MOCK="$ROOT/docs/qa/evidence/harbor/2026-07-10_harbor_command_board_mockup_v1.png"
if [[ ! -f "$MOCK" ]]; then
  echo "Adopted harbor mock was not found: $MOCK" >&2
  exit 1
fi

GODOT_HOME="${TSURI_GODOT_HOME:-/tmp/tsuri_harbor_visual_home}"
mkdir -p "$GODOT_HOME"

rm -f /tmp/tsuri_harbor_asa_mazume.png \
  /tmp/tsuri_harbor_daytime.png \
  /tmp/tsuri_harbor_night.png \
  /tmp/tsuri_harbor_time_slot_compare.png \
  /tmp/tsuri_harbor_daytime_after_mock.png \
  /tmp/tsuri_harbor_daytime_after_mock_grayscale.png \
  /tmp/tsuri_harbor_daytime_after_mock_thumbnail.png

echo "==> Capture harbor time slot previews"
for slot in asa_mazume daytime night; do
  HOME="$GODOT_HOME" \
    TSURI_HARBOR_SEED=standard \
    TSURI_HARBOR_LEVEL=30 \
    TSURI_HARBOR_TIME_SLOT_ID="$slot" \
    TSURI_HARBOR_OUT="/tmp/tsuri_harbor_${slot}.png" \
    "$GODOT" --path "$ROOT" "res://tools/harbor_preview.tscn"
done

echo "==> Build harbor time slot comparison"
python3 - <<'PY'
from pathlib import Path
from PIL import Image, ImageDraw

items = [
    ("asa_mazume", Path("/tmp/tsuri_harbor_asa_mazume.png")),
    ("daytime", Path("/tmp/tsuri_harbor_daytime.png")),
    ("night", Path("/tmp/tsuri_harbor_night.png")),
]
for label, path in items:
    if not path.exists():
        raise SystemExit(f"missing capture: {path}")
    img = Image.open(path).convert("RGBA")
    if img.getbbox() is None:
        raise SystemExit(f"blank capture: {path}")

thumb_w = 384
thumb_h = 216
label_h = 30
gutter = 12
sheet = Image.new("RGBA", (gutter + len(items) * (thumb_w + gutter), thumb_h + label_h + gutter * 2), (8, 18, 30, 255))
draw = ImageDraw.Draw(sheet)
for index, (label, path) in enumerate(items):
    img = Image.open(path).convert("RGBA").resize((thumb_w, thumb_h), Image.Resampling.LANCZOS)
    x = gutter + index * (thumb_w + gutter)
    y = gutter + label_h
    draw.text((x, gutter + 5), label, fill=(240, 232, 204, 255))
    sheet.alpha_composite(img, (x, y))
    draw.rectangle((x, y, x + thumb_w - 1, y + thumb_h - 1), outline=(216, 172, 88, 255), width=2)
sheet.save("/tmp/tsuri_harbor_time_slot_compare.png")
PY

echo "==> Build adopted-mock comparisons"
"$FFMPEG" -hide_banner -loglevel error -y \
  -i /tmp/tsuri_harbor_daytime.png \
  -i "$MOCK" \
  -filter_complex \
    "[0:v]scale=1280:720:flags=lanczos,setsar=1[after];[1:v]scale=1280:720:flags=lanczos,setsar=1[mock];[after][mock]hstack=inputs=2" \
  -frames:v 1 -update 1 \
  /tmp/tsuri_harbor_daytime_after_mock.png
"$FFMPEG" -hide_banner -loglevel error -y \
  -i /tmp/tsuri_harbor_daytime_after_mock.png \
  -vf "format=gray" \
  -frames:v 1 -update 1 \
  /tmp/tsuri_harbor_daytime_after_mock_grayscale.png
"$FFMPEG" -hide_banner -loglevel error -y \
  -i /tmp/tsuri_harbor_daytime_after_mock.png \
  -vf "scale=640:180:flags=lanczos" \
  -frames:v 1 -update 1 \
  /tmp/tsuri_harbor_daytime_after_mock_thumbnail.png

echo "Harbor visual QA outputs:"
echo "/tmp/tsuri_harbor_asa_mazume.png"
echo "/tmp/tsuri_harbor_daytime.png"
echo "/tmp/tsuri_harbor_night.png"
echo "/tmp/tsuri_harbor_time_slot_compare.png"
echo "/tmp/tsuri_harbor_daytime_after_mock.png"
echo "/tmp/tsuri_harbor_daytime_after_mock_grayscale.png"
echo "/tmp/tsuri_harbor_daytime_after_mock_thumbnail.png"
