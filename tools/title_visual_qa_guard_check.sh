#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RUNNER="$ROOT/tools/title_visual_qa.sh"
SAFE_ROOT="/tmp/tsuri_title_guard_safe"
SYMLINK_TARGET="/tmp/tsuri_title_guard_symlink"
SENTINEL="$SAFE_ROOT/sentinel"

rm -rf "$SAFE_ROOT" "$SYMLINK_TARGET"
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

rm -rf "$SAFE_ROOT" "$SYMLINK_TARGET"
echo "title visual QA HOME guard check passed."
