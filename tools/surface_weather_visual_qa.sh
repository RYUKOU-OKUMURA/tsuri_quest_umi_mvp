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

GODOT_HOME="${TSURI_GODOT_HOME:-/tmp/tsuri_surface_weather_home}"
mkdir -p "$GODOT_HOME"

rm -f /tmp/tsuri_surface_weather_sunny.png \
  /tmp/tsuri_surface_weather_partly_cloudy.png \
  /tmp/tsuri_surface_weather_cloudy.png \
  /tmp/tsuri_surface_weather_rain.png \
  /tmp/tsuri_surface_weather_fog.png \
  /tmp/tsuri_surface_weather_compare.png

echo "==> Capture surface weather previews"
HOME="$GODOT_HOME" "$GODOT" --path "$ROOT" "res://tools/surface_weather_preview.tscn"

echo "==> Build surface weather comparison"
python3 - <<'PY'
from pathlib import Path
from PIL import Image, ImageDraw

items = [
    ("sunny", Path("/tmp/tsuri_surface_weather_sunny.png")),
    ("partly_cloudy", Path("/tmp/tsuri_surface_weather_partly_cloudy.png")),
    ("cloudy", Path("/tmp/tsuri_surface_weather_cloudy.png")),
    ("rain", Path("/tmp/tsuri_surface_weather_rain.png")),
    ("fog", Path("/tmp/tsuri_surface_weather_fog.png")),
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
sheet.save("/tmp/tsuri_surface_weather_compare.png")
PY

echo "Surface weather visual QA outputs:"
echo "/tmp/tsuri_surface_weather_sunny.png"
echo "/tmp/tsuri_surface_weather_partly_cloudy.png"
echo "/tmp/tsuri_surface_weather_cloudy.png"
echo "/tmp/tsuri_surface_weather_rain.png"
echo "/tmp/tsuri_surface_weather_fog.png"
echo "/tmp/tsuri_surface_weather_compare.png"
