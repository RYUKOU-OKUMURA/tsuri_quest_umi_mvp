#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RUNNER="$ROOT/tools/title_visual_qa.sh"
SAFE_ROOT="/tmp/tsuri_title_guard_safe"
SYMLINK_TARGET="/tmp/tsuri_title_guard_symlink"
SENTINEL="$SAFE_ROOT/sentinel"
DIRECT_HOME="/tmp/tsuri_title_preview_direct_guard"
DIRECT_SYMLINK_HOME="/tmp/tsuri_title_preview_direct_symlink"
NESTED_HOME="/tmp/tsuri_title_preview_nested_guard"
NESTED_TARGET="/tmp/tsuri_title_preview_nested_target"

rm -rf "$SAFE_ROOT" "$SYMLINK_TARGET" "$DIRECT_HOME" "$DIRECT_SYMLINK_HOME" "$NESTED_HOME" "$NESTED_TARGET"
mkdir -p "$SAFE_ROOT"
touch "$SENTINEL"
ln -s "$SAFE_ROOT" "$SYMLINK_TARGET"

expect_rejected() {
  local candidate="$1"
  if TSURI_TITLE_VISUAL_QA_GUARD_ONLY=1 TSURI_GODOT_HOME="$candidate" "$RUNNER" >/dev/null 2>&1; then
    echo "危険なHOMEが拒否されませんでした: ${candidate:-<empty>}" >&2
    exit 1
  fi
  if [[ ! -f "$SENTINEL" ]]; then
    echo "guard check中にsentinelが削除されました。" >&2
    exit 1
  fi
}

expect_rejected ""
expect_rejected "/"
expect_rejected "$HOME"
expect_rejected "/tmp/not_tsuri_title"
expect_rejected "$SYMLINK_TARGET"
expect_rejected "/tmp/tsuri_title_parent/nested"

TSURI_TITLE_VISUAL_QA_GUARD_ONLY=1 TSURI_GODOT_HOME="$SAFE_ROOT" "$RUNNER" >/dev/null
if [[ ! -f "$SENTINEL" ]]; then
  echo "guard-only成功経路がsafe HOMEを削除しました。" >&2
  exit 1
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

"$GODOT" --headless --path "$ROOT" "res://tools/title_preview_guard_smoke.tscn" >/dev/null

ARTIFACT_DIR="$DIRECT_HOME/Library/Application Support/tsuri_quest_umi/slots/1"
mkdir -p "$ARTIFACT_DIR" "$DIRECT_HOME/Library/Application Support/tsuri_quest_umi/shader_cache"
printf '%s' '{"version":1,"money":111}' >"$ARTIFACT_DIR/tsuri_quest_save.json"
printf '%s' '{"version":1,"money":222}' >"$ARTIFACT_DIR/tsuri_quest_save.json.bak"
printf '%s' '{"version":1,"money":333}' >"$ARTIFACT_DIR/tsuri_quest_save.json.tmp"
hash_artifacts() {
  shasum -a 256 \
    "$ARTIFACT_DIR/tsuri_quest_save.json" \
    "$ARTIFACT_DIR/tsuri_quest_save.json.bak" \
    "$ARTIFACT_DIR/tsuri_quest_save.json.tmp"
}
HASHES_BEFORE="$(hash_artifacts)"

TSURI_QA_SANDBOX=1 TSURI_QA_DETERMINISTIC=1 \
  TSURI_TITLE_PREVIEW_OUT=/tmp/tsuri_title_direct_normal_guard.png \
  HOME="$DIRECT_HOME" "$GODOT" --path "$ROOT" "res://tools/title_preview.tscn" >/dev/null
if [[ "$(hash_artifacts)" != "$HASHES_BEFORE" ]]; then
  echo "direct normal previewがsave artifactを変更しました。" >&2
  exit 1
fi

mkdir -p "$NESTED_HOME/Library/Application Support" "$NESTED_TARGET/slots/1"
printf '%s' '{"version":1,"money":444}' >"$NESTED_TARGET/slots/1/tsuri_quest_save.json"
NESTED_HASH_BEFORE="$(shasum -a 256 "$NESTED_TARGET/slots/1/tsuri_quest_save.json")"
ln -s "$NESTED_TARGET" "$NESTED_HOME/Library/Application Support/tsuri_quest_umi"
if TSURI_QA_SANDBOX=1 TSURI_QA_DETERMINISTIC=1 TSURI_TITLE_PREVIEW_MODE=invalid_artifact \
  TSURI_TITLE_PREVIEW_ALLOW_MUTATION=1 HOME="$NESTED_HOME" \
  "$GODOT" --path "$ROOT" "res://tools/title_preview.tscn" >/dev/null 2>&1; then
  echo "nested symlinkを含むinvalid previewが成功しました。" >&2
  exit 1
fi
if [[ "$(shasum -a 256 "$NESTED_TARGET/slots/1/tsuri_quest_save.json")" != "$NESTED_HASH_BEFORE" ]]; then
  echo "nested symlink拒否時に外部artifactが変更されました。" >&2
  exit 1
fi

if TSURI_QA_SANDBOX=1 TSURI_QA_DETERMINISTIC=1 TSURI_TITLE_PREVIEW_MODE=invalid_artifact \
  TSURI_TITLE_PREVIEW_OUT=/tmp/tsuri_title_direct_invalid_rejected.png \
  HOME="$DIRECT_HOME" "$GODOT" --path "$ROOT" "res://tools/title_preview.tscn" >/dev/null 2>&1; then
  echo "mutation sentinelなしのinvalid previewが成功しました。" >&2
  exit 1
fi
if [[ "$(hash_artifacts)" != "$HASHES_BEFORE" ]]; then
  echo "拒否されたinvalid previewがsave artifactを変更しました。" >&2
  exit 1
fi

ln -s "$DIRECT_HOME" "$DIRECT_SYMLINK_HOME"
if TSURI_QA_SANDBOX=1 TSURI_QA_DETERMINISTIC=1 TSURI_TITLE_PREVIEW_MODE=invalid_artifact \
  TSURI_TITLE_PREVIEW_ALLOW_MUTATION=1 HOME="$DIRECT_SYMLINK_HOME" \
  "$GODOT" --path "$ROOT" "res://tools/title_preview.tscn" >/dev/null 2>&1; then
  echo "symlink HOMEのinvalid previewが成功しました。" >&2
  exit 1
fi
if [[ "$(hash_artifacts)" != "$HASHES_BEFORE" ]]; then
  echo "symlink HOME拒否時にsave artifactが変更されました。" >&2
  exit 1
fi

rm -rf "$SAFE_ROOT" "$SYMLINK_TARGET" "$DIRECT_HOME" "$DIRECT_SYMLINK_HOME" "$NESTED_HOME" "$NESTED_TARGET"
echo "title visual QA HOME guard check passed."
