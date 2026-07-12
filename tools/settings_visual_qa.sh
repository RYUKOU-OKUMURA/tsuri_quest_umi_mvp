#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOME_PARENT="${TSURI_SETTINGS_VISUAL_HOME_PARENT:-/tmp}"
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
SAFE_TMP_ROOT="$(cd /tmp && pwd -P)"
if [[ ! -d "$HOME_PARENT" ]]; then
  echo "settings visual QA HOME parent must already exist: $HOME_PARENT" >&2
  exit 2
fi
HOME_PARENT_PHYSICAL="$(cd "$HOME_PARENT" && pwd -P)"
case "$HOME_PARENT_PHYSICAL" in
  "$SAFE_TMP_ROOT"|"$SAFE_TMP_ROOT"/*) ;;
  *)
    echo "settings visual QA HOME parent must resolve under $SAFE_TMP_ROOT: $HOME_PARENT_PHYSICAL" >&2
    exit 2
    ;;
esac
GODOT_HOME_PHYSICAL="$(mktemp -d "$HOME_PARENT_PHYSICAL/tsuri_settings_visual.XXXXXX")"
trap 'rm -rf "$GODOT_HOME_PHYSICAL"' EXIT
RUN_TOKEN="settings-preview-$RANDOM-$RANDOM-$$"
printf '%s' "$RUN_TOKEN" >"$GODOT_HOME_PHYSICAL/.tsuri_settings_qa_guard"
unset TSURI_QA_REJECT_RAW_HOME_PROBE
rm -f /tmp/tsuri_settings_normal.png /tmp/tsuri_settings_confirm1.png /tmp/tsuri_settings_confirm2.png /tmp/tsuri_settings_failure.png /tmp/tsuri_settings_hover.png /tmp/tsuri_settings_pressed.png /tmp/tsuri_settings_focus.png
mkdir -p "$ROOT/docs/qa/evidence/settings"
for state in normal confirm1 confirm2 failure hover pressed focus; do
  TSURI_SETTINGS_PREVIEW_ALLOW=1 TSURI_QA_ISOLATED_HOME="$GODOT_HOME_PHYSICAL" TSURI_QA_RUN_TOKEN="$RUN_TOKEN" TSURI_SETTINGS_PREVIEW_STATE="$state" HOME="$GODOT_HOME_PHYSICAL" "$GODOT" --path "$ROOT" "res://tools/settings_preview.tscn"
  test -s "/tmp/tsuri_settings_${state}.png"
  cp "/tmp/tsuri_settings_${state}.png" "$ROOT/docs/qa/evidence/settings/2026-07-12_settings_${state}_1280x720.png"
done
echo "Settings visual QA: normal / confirm1 / confirm2 / failure / hover / pressed / focus"
