#!/usr/bin/env bash
set -u

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

echo "==> Build deterministic static fight comparisons"
python3 tools/build_fight_sidebar_static_compare.py || exit 1
python3 tools/build_fight_hud_static_compare.py || exit 1
python3 tools/build_fight_top_status_static_compare.py || exit 1
python3 tools/build_fight_full_static_compare.py || exit 1
python3 tools/build_fish_asset_contact_sheet.py || exit 1

if [[ "${TSURI_FIGHT_RUNTIME_CAPTURE:-0}" == "1" ]]; then
  if [[ -z "$GODOT" ]]; then
    echo "Runtime capture skipped: Godot 4.x was not found." >&2
  else
    echo "==> Try runtime fight capture"
    rm -f /tmp/tsuri_fishing_fight.png
    "$GODOT" --path "$ROOT" "res://tools/fishing_fight_preview.tscn"
    capture_status=$?
    if [[ "$capture_status" -ne 0 ]]; then
      rm -f /tmp/tsuri_fishing_fight.png
      echo "Runtime capture failed with exit code $capture_status; static fallback will be used." >&2
    fi
  fi
fi

echo "==> Build side-by-side QA outputs"
python3 tools/build_fight_comparison_images.py || exit 1
python3 tools/build_fight_comparison_html.py || exit 1

echo "==> Fight visual QA outputs"
echo "/tmp/tsuri_sidebar_static_compare.png"
echo "/tmp/tsuri_hud_static_compare.png"
echo "/tmp/tsuri_top_status_static_compare.png"
echo "/tmp/tsuri_full_static_compare.png"
echo "/tmp/tsuri_fish_asset_contact.png"
echo "/tmp/tsuri_fight_compare.png"
echo "/tmp/tsuri_fight_compare.html"
