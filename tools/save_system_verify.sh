#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_HOME="${TSURI_GODOT_HOME:-/tmp/tsuri_save_system_home}"

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

# HOME 隔離しているため user:// への書き込みは本番セーブに届かない
TSURI_SAVE_MIGRATION_SMOKE_ALLOW=1 HOME="$GODOT_HOME" "$GODOT" --headless --path "$ROOT" "res://tools/save_namespace_migration_smoke.tscn"
TSURI_SAVE_SMOKE_ALLOW=1 HOME="$GODOT_HOME" "$GODOT" --headless --path "$ROOT" "res://tools/save_system_smoke.tscn"

echo "Save system verification passed."
