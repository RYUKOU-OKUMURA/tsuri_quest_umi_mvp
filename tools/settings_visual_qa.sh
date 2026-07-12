#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOME_PARENT="${TSURI_SETTINGS_VISUAL_HOME_PARENT:-/tmp}"
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
SAFE_TMP_ROOT="$(cd /tmp && pwd -P)"
if [[ ! -d "$HOME_PARENT" ]]; then
  echo "settings visual QA HOME parent must already exist: $HOME_PARENT" >&2
  exit 2
fi
HOME_PARENT_PHYSICAL="$(cd "$HOME_PARENT" && pwd -P)"
case "$HOME_PARENT_PHYSICAL" in
  "$SAFE_TMP_ROOT"|"$SAFE_TMP_ROOT"/*) ;;
  *)
    echo "settings visual QA HOME parent must resolve under $SAFE_TMP_ROOT: $HOME_PARENT_PHYSICAL" >&2
    exit 2
    ;;
esac
GODOT_HOME_PHYSICAL="$(mktemp -d "$HOME_PARENT_PHYSICAL/tsuri_settings_visual.XXXXXX")"
trap 'rm -rf "$GODOT_HOME_PHYSICAL"' EXIT
RUN_TOKEN="settings-preview-$RANDOM-$RANDOM-$$"
printf '%s' "$RUN_TOKEN" >"$GODOT_HOME_PHYSICAL/.tsuri_settings_qa_guard"
unset TSURI_QA_REJECT_RAW_HOME_PROBE
rm -f /tmp/tsuri_settings_normal.png /tmp/tsuri_settings_confirm1.png /tmp/tsuri_settings_confirm2.png /tmp/tsuri_settings_failure.png /tmp/tsuri_settings_hover.png /tmp/tsuri_settings_pressed.png /tmp/tsuri_settings_focus.png
rm -f /tmp/tsuri_settings_fullscreen_hover.png /tmp/tsuri_settings_fullscreen_pressed.png /tmp/tsuri_settings_fullscreen_focus.png
rm -f /tmp/tsuri_settings_resolution_1280x720.png /tmp/tsuri_settings_resolution_1280x800.png /tmp/tsuri_settings_resolution_1024x768.png
mkdir -p "$ROOT/docs/qa/evidence/settings"
for state in normal confirm1 confirm2 failure hover pressed focus; do
  TSURI_SETTINGS_PREVIEW_ALLOW=1 TSURI_QA_ISOLATED_HOME="$GODOT_HOME_PHYSICAL" TSURI_QA_RUN_TOKEN="$RUN_TOKEN" TSURI_SETTINGS_PREVIEW_STATE="$state" HOME="$GODOT_HOME_PHYSICAL" "$GODOT" --path "$ROOT" "res://tools/settings_preview.tscn"
  test -s "/tmp/tsuri_settings_${state}.png"
	cp "/tmp/tsuri_settings_${state}.png" "$ROOT/docs/qa/evidence/settings/2026-07-13_settings_${state}_1280x720.png"
done

for state in fullscreen_hover fullscreen_pressed fullscreen_focus; do
  TSURI_SETTINGS_PREVIEW_ALLOW=1 TSURI_QA_ISOLATED_HOME="$GODOT_HOME_PHYSICAL" TSURI_QA_RUN_TOKEN="$RUN_TOKEN" TSURI_SETTINGS_PREVIEW_STATE="$state" HOME="$GODOT_HOME_PHYSICAL" "$GODOT" --path "$ROOT" "res://tools/settings_preview.tscn"
  test -s "/tmp/tsuri_settings_${state}.png"
  cp "/tmp/tsuri_settings_${state}.png" "$ROOT/docs/qa/evidence/settings/2026-07-13_settings_${state}_1280x720.png"
done

for resolution in 1280x720 1280x800 1024x768; do
  output="/tmp/tsuri_settings_resolution_${resolution}.png"
  width="${resolution%x*}"
  height="${resolution#*x}"
  rm -f "$output"
  TSURI_SETTINGS_PREVIEW_ALLOW=1 TSURI_QA_ISOLATED_HOME="$GODOT_HOME_PHYSICAL" TSURI_QA_RUN_TOKEN="$RUN_TOKEN" TSURI_SETTINGS_PREVIEW_STATE=normal TSURI_SETTINGS_PREVIEW_WINDOW="$resolution" TSURI_SETTINGS_SCREEN_HOLD=1 HOME="$GODOT_HOME_PHYSICAL" "$GODOT" --path "$ROOT" "res://tools/settings_preview.tscn" >"/tmp/tsuri_settings_resolution_${resolution}.log" 2>&1 &
  godot_pid=$!
  captured=0
  for attempt in 1 2 3 4 5 6 7 8; do
    osascript -e 'tell application "Godot" to activate' >/dev/null 2>&1 || true
    expected_window_width=$((width / 2))
    expected_window_height=$((height / 2))
    window_id="$(swift -e "import CoreGraphics; import Foundation; let expectedWidth = $expected_window_width; let expectedHeight = $expected_window_height; let ws = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as! [[String:Any]]; for w in ws { let owner = String(describing: w[kCGWindowOwnerName as String] ?? \"\"); if owner == \"Godot\", let bounds = w[kCGWindowBounds as String] as? [String:Any], let boundsWidth = (bounds[\"Width\"] as? NSNumber)?.intValue, let boundsHeight = (bounds[\"Height\"] as? NSNumber)?.intValue, boundsWidth == expectedWidth, boundsHeight == expectedHeight { print(w[kCGWindowNumber as String] ?? \"\") } }" | tail -1)"
    if [[ "$window_id" =~ ^[0-9]+$ ]] && screencapture -x -o -l "$window_id" "$output" 2>/dev/null && test -s "$output"; then
      captured=1
      break
    fi
    sleep 1
  done
  wait "$godot_pid" || true
  test "$captured" -eq 1
  test -s "$output"
  cp "$output" "$ROOT/docs/qa/evidence/settings/2026-07-13_settings_resolution_${resolution}.png"
done

python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
from PIL import Image

root = Path(sys.argv[1])
evidence = root / "docs/qa/evidence/settings"
design_w, design_h = 1280, 720
cases = {
    "1280x720": (1280, 720),
    "1280x800": (1280, 800),
    "1024x768": (1024, 768),
}

for name, (window_w, window_h) in cases.items():
    image_path = evidence / f"2026-07-13_settings_resolution_{name}.png"
    image = Image.open(image_path).convert("RGBA")
    pixel_scale_x = image.width / window_w
    pixel_scale_y = image.height / window_h
    assert pixel_scale_x == pixel_scale_y and pixel_scale_x in (1, 2), (name, image.size)
    pixel_scale = int(pixel_scale_x)
    scale = min(window_w / design_w, window_h / design_h)
    logical_content_w = round(design_w * scale)
    logical_content_h = round(design_h * scale)
    logical_offset_x = (window_w - logical_content_w) // 2
    logical_offset_y = (window_h - logical_content_h) // 2
    content_w = logical_content_w * pixel_scale
    content_h = logical_content_h * pixel_scale
    offset_x = logical_offset_x * pixel_scale
    offset_y = logical_offset_y * pixel_scale
    assert logical_content_w * 9 == logical_content_h * 16, (name, logical_content_w, logical_content_h)
    pixels = image.load()
    assert all(pixels[x, y][3] == 255 for y in range(window_h) for x in range(window_w)), name

    def luminance(pixel):
        return 0.2126 * pixel[0] / 255 + 0.7152 * pixel[1] / 255 + 0.0722 * pixel[2] / 255

    content_sample = pixels[min(image.width - 1, offset_x + max(20 * pixel_scale, content_w // 3)), offset_y + max(20 * pixel_scale, content_h // 3)]
    assert luminance(content_sample) > 0.008, (name, "content sample", content_sample)
    bar_points = []
    if offset_y:
        bar_points.extend([(image.width // 2, 0), (image.width // 2, offset_y - 1), (image.width // 2, image.height - offset_y), (image.width // 2, image.height - 1)])
    if offset_x:
        bar_points.extend([(0, image.height // 2), (offset_x - 1, image.height // 2), (image.width - offset_x, image.height // 2), (image.width - 1, image.height // 2)])
    for point in bar_points:
        assert luminance(pixels[point]) < 0.12, (name, "bar sample", point, pixels[point])
    expected_bars = 2 * offset_y * image.width + 2 * offset_x * content_h
    observed_non_content = 0
    for y in range(image.height):
        for x in range(image.width):
            if not (offset_x <= x < offset_x + content_w and offset_y <= y < offset_y + content_h):
                observed_non_content += 1
    assert observed_non_content == expected_bars, (name, observed_non_content, expected_bars)
    print(f"settings resolution QA: {name} pixels={image.width}x{image.height} content={content_w}x{content_h} offset=({offset_x},{offset_y}) bars={expected_bars}")
PY

echo "Settings visual QA: normal / confirm1 / confirm2 / failure / hover / pressed / focus / resolution matrix"
