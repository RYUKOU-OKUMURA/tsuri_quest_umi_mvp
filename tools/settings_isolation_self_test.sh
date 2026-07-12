#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -n "${GODOT_BIN:-}" ]]; then
  GODOT="$GODOT_BIN"
elif command -v godot >/dev/null 2>&1; then
  GODOT=godot
elif command -v godot4 >/dev/null 2>&1; then
  GODOT=godot4
elif [[ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]]; then
  GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
else
  echo "Godot 4.x was not found." >&2
  exit 1
fi

SAFE_HOME="$(mktemp -d /tmp/tsuri_settings_isolation.XXXXXX)"
OUTSIDE_HOME="$(mktemp -d /var/tmp/tsuri_settings_isolation.XXXXXX)"
LINK_PARENT="/tmp/tsuri_settings_isolation_link.$$"
ANCESTOR_TARGET="$(mktemp -d /var/tmp/tsuri_settings_ancestor.XXXXXX)"
ANCESTOR_HOME="$ANCESTOR_TARGET/child"
ANCESTOR_LINK="/tmp/tsuri_settings_ancestor_link.$$"
NESTED_ROOT="$(mktemp -d /tmp/tsuri_settings_nested.XXXXXX)"
NESTED_ROOT="$(cd "$NESTED_ROOT" && pwd -P)"
NESTED_OUTSIDE="$(mktemp -d /var/tmp/tsuri_settings_nested_outside.XXXXXX)"
RAW_TARGET="$(mktemp -d /tmp/tsuri_settings_raw.XXXXXX)"
RAW_TARGET="$(cd "$RAW_TARGET" && pwd -P)"
RAW_LINK="/private/tmp/tsuri_settings_raw_link.$$"
trap 'rm -rf "$SAFE_HOME" "$OUTSIDE_HOME" "$LINK_PARENT" "$ANCESTOR_TARGET" "$ANCESTOR_LINK" "$NESTED_ROOT" "$NESTED_OUTSIDE" "$RAW_TARGET" "$RAW_LINK"' EXIT

data_root() {
  printf '%s/Library/Application Support/tsuri_quest_umi' "$1"
}

make_sentinels() {
  local data
  data="$(data_root "$1")"
  mkdir -p "$data/slots/1"
  printf '%s' 'marker-byte-sentinel' >"$data/marker"
  printf '%s' '{"version":1,"level":77}' >"$data/slots/1/tsuri_quest_save.json"
  printf '%s' 'backup-byte-sentinel' >"$data/slots/1/tsuri_quest_save.json.bak"
  printf '%s' 'tmp-byte-sentinel' >"$data/slots/1/tsuri_quest_save.json.tmp"
  printf '%s' '{"bgm_volume":17}' >"$data/settings.json"
}

sentinel_hashes() {
  local data
  data="$(data_root "$1")"
  shasum -a 256 "$data/marker" "$data/slots/1/tsuri_quest_save.json" "$data/slots/1/tsuri_quest_save.json.bak" "$data/slots/1/tsuri_quest_save.json.tmp" "$data/settings.json"
}

expect_exit_2() {
  set +e
  "$@" >/tmp/tsuri_settings_isolation_case.log 2>&1
  local status=$?
  set -e
  if [[ "$status" -ne 2 ]]; then
    cat /tmp/tsuri_settings_isolation_case.log >&2
    echo "expected exit 2, got $status" >&2
    exit 1
  fi
}

assert_unchanged() {
  local home="$1" before="$2"
  test "$(sentinel_hashes "$home")" = "$before"
}

expect_guard_rejection_both() {
  local home="$1" protected_home="$2" token="$3" before
  before="$(sentinel_hashes "$protected_home")"
  expect_exit_2 env HOME="$home" TSURI_SETTINGS_SMOKE_ALLOW=1 TSURI_QA_ISOLATED_HOME="$home" TSURI_QA_RUN_TOKEN="$token" "$GODOT" --headless --path "$ROOT" res://tools/settings_smoke.tscn
  assert_unchanged "$protected_home" "$before"
  expect_exit_2 env HOME="$home" TSURI_SETTINGS_PREVIEW_ALLOW=1 TSURI_QA_ISOLATED_HOME="$home" TSURI_QA_RUN_TOKEN="$token" TSURI_SETTINGS_PREVIEW_STATE=normal "$GODOT" --headless --path "$ROOT" res://tools/settings_preview.tscn
  assert_unchanged "$protected_home" "$before"
}

expect_guard_rejection_both_paths() {
  local home="$1" expected="$2" protected_home="$3" token="$4" before
  before="$(sentinel_hashes "$protected_home")"
  expect_exit_2 env HOME="$home" TSURI_SETTINGS_SMOKE_ALLOW=1 TSURI_QA_ISOLATED_HOME="$expected" TSURI_QA_RUN_TOKEN="$token" "$GODOT" --headless --path "$ROOT" res://tools/settings_smoke.tscn
  assert_unchanged "$protected_home" "$before"
  expect_exit_2 env HOME="$home" TSURI_SETTINGS_PREVIEW_ALLOW=1 TSURI_QA_ISOLATED_HOME="$expected" TSURI_QA_RUN_TOKEN="$token" TSURI_SETTINGS_PREVIEW_STATE=normal "$GODOT" --headless --path "$ROOT" res://tools/settings_preview.tscn
  assert_unchanged "$protected_home" "$before"
}

make_sentinels "$OUTSIDE_HOME"
outside_before="$(sentinel_hashes "$OUTSIDE_HOME")"
ln -s "$OUTSIDE_HOME" "$LINK_PARENT"
expect_exit_2 env TSURI_SETTINGS_VISUAL_HOME_PARENT="$LINK_PARENT" "$ROOT/tools/settings_visual_qa.sh"
assert_unchanged "$OUTSIDE_HOME" "$outside_before"
printf '%s' 'matching-token' >"$OUTSIDE_HOME/.tsuri_settings_qa_guard"
expect_exit_2 env HOME="$LINK_PARENT" TSURI_SETTINGS_SMOKE_ALLOW=1 TSURI_QA_ISOLATED_HOME="$LINK_PARENT" TSURI_QA_RUN_TOKEN=matching-token "$GODOT" --headless --path "$ROOT" res://tools/settings_smoke.tscn
assert_unchanged "$OUTSIDE_HOME" "$outside_before"
expect_exit_2 env HOME="$LINK_PARENT" TSURI_SETTINGS_PREVIEW_ALLOW=1 TSURI_QA_ISOLATED_HOME="$LINK_PARENT" TSURI_QA_RUN_TOKEN=matching-token TSURI_SETTINGS_PREVIEW_STATE=normal "$GODOT" --headless --path "$ROOT" res://tools/settings_preview.tscn
assert_unchanged "$OUTSIDE_HOME" "$outside_before"

make_sentinels "$ANCESTOR_HOME"
ancestor_before="$(sentinel_hashes "$ANCESTOR_HOME")"
printf '%s' 'ancestor-matching-token' >"$ANCESTOR_HOME/.tsuri_settings_qa_guard"
ln -s "$ANCESTOR_TARGET" "$ANCESTOR_LINK"
expect_exit_2 env HOME="$ANCESTOR_LINK/child" TSURI_SETTINGS_SMOKE_ALLOW=1 TSURI_QA_ISOLATED_HOME="$ANCESTOR_LINK/child" TSURI_QA_RUN_TOKEN=ancestor-matching-token "$GODOT" --headless --path "$ROOT" res://tools/settings_smoke.tscn
assert_unchanged "$ANCESTOR_HOME" "$ancestor_before"
expect_exit_2 env HOME="$ANCESTOR_LINK/child" TSURI_SETTINGS_PREVIEW_ALLOW=1 TSURI_QA_ISOLATED_HOME="$ANCESTOR_LINK/child" TSURI_QA_RUN_TOKEN=ancestor-matching-token TSURI_SETTINGS_PREVIEW_STATE=normal "$GODOT" --headless --path "$ROOT" res://tools/settings_preview.tscn
assert_unchanged "$ANCESTOR_HOME" "$ancestor_before"

# HOME自体は物理pathでも、user data root / slots / slot directoryのnested linkを拒否する。
for kind in user_data slots slot; do
  case_home="$NESTED_ROOT/$kind"
  case_outside="$NESTED_OUTSIDE/$kind"
  mkdir -p "$case_home" "$case_outside"
  make_sentinels "$case_outside"
  case "$kind" in
    user_data)
      mkdir -p "$case_home/Library/Application Support"
      ln -s "$(data_root "$case_outside")" "$(data_root "$case_home")"
      ;;
    slots)
      mkdir -p "$(data_root "$case_home")"
      ln -s "$(data_root "$case_outside")/slots" "$(data_root "$case_home")/slots"
      ;;
    slot)
      mkdir -p "$(data_root "$case_home")/slots"
      ln -s "$(data_root "$case_outside")/slots/1" "$(data_root "$case_home")/slots/1"
      ;;
  esac
  printf '%s' "nested-$kind-token" >"$case_home/.tsuri_settings_qa_guard"
  expect_guard_rejection_both "$case_home" "$case_outside" "nested-$kind-token"
done

# simplify前ならlink成分が見える `link/../child` をmatching tokenでも拒否する。
mkdir -p "$RAW_TARGET/anchor" "$RAW_TARGET/child"
make_sentinels "$RAW_TARGET/child"
printf '%s' 'raw-dotdot-token' >"$RAW_TARGET/child/.tsuri_settings_qa_guard"
ln -s "$RAW_TARGET/anchor" "$RAW_LINK"
expect_guard_rejection_both_paths "$RAW_TARGET/child" "$RAW_LINK/../child" "$RAW_TARGET/child" raw-dotdot-token
raw_before="$(sentinel_hashes "$RAW_TARGET/child")"
expect_exit_2 env HOME="$RAW_TARGET/child" TSURI_SETTINGS_SMOKE_ALLOW=1 TSURI_QA_ISOLATED_HOME="$RAW_TARGET/child" TSURI_QA_RUN_TOKEN=raw-dotdot-token TSURI_QA_REJECT_RAW_HOME_PROBE="$RAW_LINK/../child" "$GODOT" --headless --path "$ROOT" res://tools/settings_smoke.tscn
assert_unchanged "$RAW_TARGET/child" "$raw_before"
expect_exit_2 env HOME="$RAW_TARGET/child" TSURI_SETTINGS_PREVIEW_ALLOW=1 TSURI_QA_ISOLATED_HOME="$RAW_TARGET/child" TSURI_QA_RUN_TOKEN=raw-dotdot-token TSURI_QA_REJECT_RAW_HOME_PROBE="$RAW_LINK/../child" TSURI_SETTINGS_PREVIEW_STATE=normal "$GODOT" --headless --path "$ROOT" res://tools/settings_preview.tscn
assert_unchanged "$RAW_TARGET/child" "$raw_before"
expect_guard_rejection_both_paths "$RAW_TARGET/child" " $RAW_TARGET/child " "$RAW_TARGET/child" raw-dotdot-token
expect_exit_2 env HOME="$RAW_TARGET/child" TSURI_SETTINGS_SMOKE_ALLOW=1 TSURI_QA_ISOLATED_HOME="$RAW_TARGET/child" TSURI_QA_RUN_TOKEN=raw-dotdot-token TSURI_QA_REJECT_RAW_HOME_PROBE=" $RAW_TARGET/child " "$GODOT" --headless --path "$ROOT" res://tools/settings_smoke.tscn
assert_unchanged "$RAW_TARGET/child" "$raw_before"
expect_exit_2 env HOME="$RAW_TARGET/child" TSURI_SETTINGS_PREVIEW_ALLOW=1 TSURI_QA_ISOLATED_HOME="$RAW_TARGET/child" TSURI_QA_RUN_TOKEN=raw-dotdot-token TSURI_QA_REJECT_RAW_HOME_PROBE=" $RAW_TARGET/child " TSURI_SETTINGS_PREVIEW_STATE=normal "$GODOT" --headless --path "$ROOT" res://tools/settings_preview.tscn
assert_unchanged "$RAW_TARGET/child" "$raw_before"

make_sentinels "$SAFE_HOME"
safe_before="$(sentinel_hashes "$SAFE_HOME")"
expect_exit_2 env HOME="$SAFE_HOME" TSURI_SETTINGS_SMOKE_ALLOW=1 TSURI_QA_ISOLATED_HOME=/tmp/not_the_actual_home TSURI_QA_RUN_TOKEN=token "$GODOT" --headless --path "$ROOT" res://tools/settings_smoke.tscn
assert_unchanged "$SAFE_HOME" "$safe_before"
expect_exit_2 env HOME="$SAFE_HOME" TSURI_SETTINGS_PREVIEW_ALLOW=1 TSURI_QA_ISOLATED_HOME="$SAFE_HOME" TSURI_QA_RUN_TOKEN=token TSURI_SETTINGS_PREVIEW_STATE=normal "$GODOT" --headless --path "$ROOT" res://tools/settings_preview.tscn
assert_unchanged "$SAFE_HOME" "$safe_before"
printf '%s' 'different-token' >"$SAFE_HOME/.tsuri_settings_qa_guard"
expect_exit_2 env HOME="$SAFE_HOME" TSURI_SETTINGS_SMOKE_ALLOW=1 TSURI_QA_ISOLATED_HOME="$SAFE_HOME" TSURI_QA_RUN_TOKEN=token "$GODOT" --headless --path "$ROOT" res://tools/settings_smoke.tscn
assert_unchanged "$SAFE_HOME" "$safe_before"
expect_exit_2 env HOME="$SAFE_HOME" TSURI_SETTINGS_PREVIEW_ALLOW=1 TSURI_QA_ISOLATED_HOME="$SAFE_HOME" TSURI_QA_RUN_TOKEN=token TSURI_SETTINGS_PREVIEW_STATE=normal "$GODOT" --headless --path "$ROOT" res://tools/settings_preview.tscn
assert_unchanged "$SAFE_HOME" "$safe_before"

echo "settings isolation self-test: ok"
