#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -n "${TSURI_GODOT_HOME+x}" ]]; then
  HOME_PARENT_RAW="$TSURI_GODOT_HOME"
else
  HOME_PARENT_RAW="${TMPDIR:-/tmp}"
  # macOSのTMPDIRは通常末尾slash付きなので、platform既定だけ正規化する。
  while [[ "$HOME_PARENT_RAW" != "/" && "$HOME_PARENT_RAW" == */ ]]; do
    HOME_PARENT_RAW="${HOME_PARENT_RAW%/}"
  done
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

HOME_PARENT="$({ python3 - "$HOME_PARENT_RAW" <<'PY'
import os
from pathlib import Path
import stat
import sys

raw = sys.argv[1]
if not raw or raw != raw.strip() or not raw.startswith("/") or raw != os.path.normpath(raw):
    raise SystemExit("save system HOME parentは曖昧さのない絶対path必須です")
if raw == "/":
    raise SystemExit("save system HOME parentにroot directoryは使用できません")

# macOSの/tmpと/varは/private配下へのOS標準aliasなので、その成分だけ許可する。
platform_aliases = {"/tmp", "/var"}
current = Path("/")
for component in Path(raw).parts[1:]:
    current /= component
    try:
        mode = os.lstat(current).st_mode
    except FileNotFoundError:
        raise SystemExit(f"save system HOME parentは既存directory必須です: {raw}")
    if stat.S_ISLNK(mode) and str(current) not in platform_aliases:
        raise SystemExit(f"save system HOME parentのsymlink祖先を拒否しました: {current}")

resolved = Path(raw).resolve(strict=True)
if not resolved.is_dir() or resolved == Path("/"):
    raise SystemExit(f"save system HOME parentは実directory必須です: {raw}")
print(resolved)
PY
} 2>&1)" || {
  printf '%s\n' "$HOME_PARENT" >&2
  exit 2
}

RUN_ROOT="$(mktemp -d "$HOME_PARENT/tsuri_save_system.XXXXXX")"
cleanup() {
  local status="$1"
  trap - EXIT HUP INT TERM
  if [[ -L "${RUN_ROOT:-}" || ( -e "${RUN_ROOT:-}" && ! -d "${RUN_ROOT:-}" ) ]]; then
    echo "save system verification: unsafe cleanup targetを拒否しました: $RUN_ROOT" >&2
    status=2
  elif [[ -n "${RUN_ROOT:-}" && -d "$RUN_ROOT" ]]; then
    local run_parent run_base
    run_parent="$(cd "$(dirname "$RUN_ROOT")" && pwd -P)"
    run_base="$(basename "$RUN_ROOT")"
    if [[ "$run_parent" == "$HOME_PARENT" && "$run_base" == tsuri_save_system.* ]]; then
      rm -rf -- "$RUN_ROOT"
    else
      echo "save system verification: unsafe cleanup targetを拒否しました: $RUN_ROOT" >&2
      status=2
    fi
  fi
  exit "$status"
}
trap 'cleanup $?' EXIT
trap 'cleanup 129' HUP
trap 'cleanup 130' INT
trap 'cleanup 143' TERM

MIGRATION_HOME="$RUN_ROOT/migration"
SAVE_HOME="$RUN_ROOT/save"
mkdir -p "$MIGRATION_HOME" "$SAVE_HOME"
MIGRATION_TOKEN="$(python3 -c 'import secrets; print(secrets.token_hex(24))')"
SAVE_TOKEN="$(python3 -c 'import secrets; print(secrets.token_hex(24))')"
printf '%s' "$MIGRATION_TOKEN" > "$MIGRATION_HOME/.tsuri_save_qa_guard"
printf '%s' "$SAVE_TOKEN" > "$SAVE_HOME/.tsuri_save_qa_guard"

# run固有かつscene別のHOMEだけを渡し、実ユーザーsaveと並列実行を分離する。
TSURI_SAVE_MIGRATION_SMOKE_ALLOW=1 \
  TSURI_QA_ISOLATED_HOME="$MIGRATION_HOME" \
  TSURI_QA_RUN_TOKEN="$MIGRATION_TOKEN" \
  HOME="$MIGRATION_HOME" \
  "$GODOT" --headless --path "$ROOT" "res://tools/save_namespace_migration_smoke.tscn"
TSURI_SAVE_SMOKE_ALLOW=1 \
  TSURI_QA_ISOLATED_HOME="$SAVE_HOME" \
  TSURI_QA_RUN_TOKEN="$SAVE_TOKEN" \
  HOME="$SAVE_HOME" \
  "$GODOT" --headless --path "$ROOT" "res://tools/save_system_smoke.tscn"

echo "Save system verification passed."
