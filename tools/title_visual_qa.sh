#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_HOME="${TSURI_GODOT_HOME:-/tmp/tsuri_title_visual_qa_home}"
INVALID_GODOT_HOME="${GODOT_HOME}_invalid_artifact"

if [[ -n "${GODOT_BIN:-}" ]]; then
  GODOT="$GODOT_BIN"
elif command -v godot >/dev/null 2>&1; then
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
# macOS対象のcustom user data dirとshader cacheを先に作り、初回描画のERRORを避ける。
mkdir -p "$GODOT_HOME/Library/Application Support/tsuri_quest_umi/shader_cache"
mkdir -p "$INVALID_GODOT_HOME/Library/Application Support/tsuri_quest_umi/shader_cache"
rm -f /tmp/tsuri_title_normal.png
rm -f /tmp/tsuri_title_storage_blocked.png
rm -f /tmp/tsuri_title_storage_blocked_compare.png
rm -f /tmp/tsuri_title_invalid_artifact.png
rm -f /tmp/tsuri_title_invalid_artifact_compare.png

echo "==> タイトル通常状態をキャプチャ"
TSURI_QA_SANDBOX=1 TSURI_QA_DETERMINISTIC=1 HOME="$GODOT_HOME" \
  "$GODOT" --path "$ROOT" "res://tools/title_preview.tscn"

echo "==> セーブ領域利用不可状態をキャプチャ"
TSURI_QA_SANDBOX=1 TSURI_QA_DETERMINISTIC=1 TSURI_TITLE_PREVIEW_MODE=storage_blocked \
  HOME="$GODOT_HOME" \
  "$GODOT" --path "$ROOT" "res://tools/title_preview.tscn"

echo "==> 通常 / 利用不可の比較画像を作成"
python3 "$ROOT/tools/build_screen_visual_comparison.py" title_storage_block

echo "==> 不正artifact状態をキャプチャ"
TSURI_QA_SANDBOX=1 TSURI_QA_DETERMINISTIC=1 TSURI_TITLE_PREVIEW_MODE=invalid_artifact \
  HOME="$INVALID_GODOT_HOME" \
  "$GODOT" --path "$ROOT" "res://tools/title_preview.tscn"

echo "==> 通常 / 不正artifactの比較画像を作成"
python3 "$ROOT/tools/build_screen_visual_comparison.py" title_invalid_artifact

echo "Title visual QA output:"
echo "/tmp/tsuri_title_normal.png"
echo "/tmp/tsuri_title_storage_blocked.png"
echo "/tmp/tsuri_title_storage_blocked_compare.png"
echo "/tmp/tsuri_title_invalid_artifact.png"
echo "/tmp/tsuri_title_invalid_artifact_compare.png"
