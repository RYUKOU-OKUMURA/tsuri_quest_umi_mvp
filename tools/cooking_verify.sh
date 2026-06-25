#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_HOME="${TSURI_GODOT_HOME:-/tmp/tsuri_cooking_home}"

if command -v godot >/dev/null 2>&1; then
  GODOT=godot
elif command -v godot4 >/dev/null 2>&1; then
  GODOT=godot4
elif [[ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]]; then
  GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
else
  echo "Godot 4.xが見つかりません。" >&2
  exit 1
fi

mkdir -p "$GODOT_HOME"

run_scene() {
  local scene="$1"
  echo "==> $scene"
  HOME="$GODOT_HOME" "$GODOT" --headless --path "$ROOT" "$scene"
}

run_scene "res://tools/cooking_content_audit.tscn"
run_scene "res://tools/cooking_layout_audit.tscn"
run_scene "res://tools/cooking_flow_smoke.tscn"

echo "Cooking showcase verification passed."
