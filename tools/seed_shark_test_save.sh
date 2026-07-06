#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

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

echo "サメ釣りQA用セーブをスロット2へ書き込みます（スロット1は触りません）。"
TSURI_SEED_SHARK_TEST_SAVE_ALLOW=1 "$GODOT" --headless --path "$ROOT" "res://tools/seed_shark_test_save.tscn"
