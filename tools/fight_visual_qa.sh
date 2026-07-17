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

runtime_capture="${TSURI_FIGHT_RUNTIME_CAPTURE:-1}"
if [[ "$runtime_capture" == "1" ]]; then
  if [[ -z "$GODOT" ]]; then
    echo "Runtime capture is required for docs/39 visual QA, but Godot 4.x was not found." >&2
    exit 1
  else
    echo "==> Try runtime fight capture"
    rm -f /tmp/tsuri_fishing_fight.png /tmp/tsuri_fishing_fight_focus.png
    "$GODOT" --path "$ROOT" "res://tools/fishing_fight_preview.tscn"
    capture_status=$?
    if [[ "$capture_status" -ne 0 ]]; then
      rm -f /tmp/tsuri_fishing_fight.png
      echo "Runtime capture failed with exit code $capture_status; docs/39 visual QA cannot use the legacy static fallback." >&2
      exit "$capture_status"
    fi
    if [[ ! -f /tmp/tsuri_fishing_fight.png ]]; then
      echo "Runtime capture completed without /tmp/tsuri_fishing_fight.png; docs/39 visual QA cannot continue." >&2
      exit 1
    fi
    echo "==> Capture FIGHT focus signature"
    TSURI_FIGHT_FOCUS=1 TSURI_FIGHT_CAPTURE_OUT=/tmp/tsuri_fishing_fight_focus.png \
      "$GODOT" --path "$ROOT" "res://tools/fishing_fight_preview.tscn"
    focus_capture_status=$?
    if [[ "$focus_capture_status" -ne 0 ]]; then
      echo "Focused FIGHT capture failed; FIGHT-A1 focus evidence cannot be verified." >&2
      exit "$focus_capture_status"
    fi
    if [[ ! -f /tmp/tsuri_fishing_fight_focus.png ]]; then
      echo "Focused FIGHT capture completed without its expected output." >&2
      exit 1
    fi
  fi
else
  echo "Runtime capture disabled via TSURI_FIGHT_RUNTIME_CAPTURE=0; comparison boards will use legacy static fallback and are not a docs/39 acceptance run." >&2
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
echo "/tmp/tsuri_fishing_fight_focus.png"
