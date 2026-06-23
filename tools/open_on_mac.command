#!/bin/zsh
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/project.godot"

if command -v godot >/dev/null 2>&1; then
  exec godot --editor --path "$ROOT"
elif command -v godot4 >/dev/null 2>&1; then
  exec godot4 --editor --path "$ROOT"
elif [[ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]]; then
  exec "/Applications/Godot.app/Contents/MacOS/Godot" --editor --path "$ROOT"
else
  echo "Godotが見つかりません。Godot 4.7をApplicationsへ配置してください。"
  echo "Project: $PROJECT"
  read "?Enterキーで終了します。"
fi
