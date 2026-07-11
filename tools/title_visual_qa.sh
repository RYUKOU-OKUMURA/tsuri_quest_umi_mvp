#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_HOME="${TSURI_GODOT_HOME-/tmp/tsuri_title_visual_qa_home}"

safe_title_qa_home() {
  local target="$1"
  if [[ -z "$target" || "$target" == "/" || "$target" == "$HOME" || -L "$target" ]]; then
    echo "危険なtitle visual QA HOMEを拒否しました: ${target:-<empty>}" >&2
    return 1
  fi
  local parent base canonical_parent
  parent="$(dirname "$target")"
  base="$(basename "$target")"
  if [[ "$parent" != "/tmp" && "$parent" != "/private/tmp" ]]; then
    echo "title visual QA HOMEは/private/tmp直下だけ許可します: $target" >&2
    return 1
  fi
  if [[ "$base" != tsuri_title_* ]]; then
    echo "title visual QA HOMEのbasenameが専用prefix外です: $base" >&2
    return 1
  fi
  canonical_parent="$(cd "$parent" && pwd -P)"
  if [[ "$canonical_parent" != "/private/tmp" ]]; then
    echo "title visual QA HOMEの実parentが/private/tmpではありません: $canonical_parent" >&2
    return 1
  fi
  printf '%s/%s\n' "$canonical_parent" "$base"
}

GODOT_HOME="$(safe_title_qa_home "$GODOT_HOME")"
INVALID_GODOT_HOME="$(safe_title_qa_home "${GODOT_HOME}_invalid_artifact")"

if [[ "${TSURI_TITLE_VISUAL_QA_GUARD_ONLY:-0}" == "1" ]]; then
  echo "title visual QA HOME guard passed."
  exit 0
fi

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

rm -rf "$GODOT_HOME" "$INVALID_GODOT_HOME"
mkdir -p "$GODOT_HOME"
# macOS対象のcustom user data dirとshader cacheを先に作り、初回描画のERRORを避ける。
mkdir -p "$GODOT_HOME/Library/Application Support/tsuri_quest_umi/shader_cache"
mkdir -p "$INVALID_GODOT_HOME/Library/Application Support/tsuri_quest_umi/shader_cache"
rm -f /tmp/tsuri_title_*.png

for mode in empty occupied 3slot difficulty overwrite; do
  mode_home="$(safe_title_qa_home "${GODOT_HOME}_${mode}")"
  rm -rf "$mode_home"
  mkdir -p "$mode_home/Library/Application Support/tsuri_quest_umi/shader_cache"
  echo "==> E7 title ${mode}状態をキャプチャ"
  TSURI_QA_SANDBOX=1 TSURI_QA_DETERMINISTIC=1 TSURI_TITLE_PREVIEW_MODE="$mode" \
    TSURI_TITLE_PREVIEW_ALLOW_MUTATION=1 HOME="$mode_home" \
    "$GODOT" --path "$ROOT" "res://tools/title_preview.tscn"
done

echo "==> E7 title 5状態の比較画像を作成"
python3 "$ROOT/tools/build_screen_visual_comparison.py" title_e7

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
  TSURI_TITLE_PREVIEW_ALLOW_MUTATION=1 \
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
echo "/tmp/tsuri_title_empty.png"
echo "/tmp/tsuri_title_occupied.png"
echo "/tmp/tsuri_title_3slot.png"
echo "/tmp/tsuri_title_difficulty.png"
echo "/tmp/tsuri_title_overwrite.png"
