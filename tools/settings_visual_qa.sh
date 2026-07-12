#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_HOME="${TSURI_GODOT_HOME:-/tmp/tsuri_settings_home}"
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
rm -f /tmp/tsuri_settings_normal.png /tmp/tsuri_settings_confirm1.png /tmp/tsuri_settings_confirm2.png /tmp/tsuri_settings_failure.png
HOME="$GODOT_HOME" "$GODOT" --path "$ROOT" "res://tools/settings_preview.tscn"
mkdir -p "$ROOT/docs/qa/evidence/settings"
for state in normal confirm1 confirm2 failure; do
  test -s "/tmp/tsuri_settings_${state}.png"
  cp "/tmp/tsuri_settings_${state}.png" "$ROOT/docs/qa/evidence/settings/2026-07-12_settings_${state}_1280x720.png"
done
echo "Settings visual QA: normal / confirm1 / confirm2 / failure"
