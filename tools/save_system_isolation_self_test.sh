#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
COMMAND_RUNNER="$ROOT/tools/export_command_runner.py"
TOTAL_TIMEOUT_SECONDS="${TSURI_SAVE_ISOLATION_TOTAL_TIMEOUT_SECONDS:-180}"
COMMAND_TIMEOUT_SECONDS="${TSURI_SAVE_ISOLATION_COMMAND_TIMEOUT_SECONDS:-60}"
TERM_GRACE_SECONDS="${TSURI_SAVE_ISOLATION_TERM_GRACE_SECONDS:-1}"
TOTAL_TERM_GRACE_SECONDS="${TSURI_SAVE_ISOLATION_TOTAL_TERM_GRACE_SECONDS:-3}"
[[ -f "$COMMAND_RUNNER" ]]

# self-test全体も既存のprocess-group runnerで監督する。内側runnerがwarm-up/sceneを
# 掃除してから終了できるよう、全体側のTERM猶予は別契約にする。
if [[ "${TSURI_SAVE_ISOLATION_SUPERVISED:-}" != "1" ]]; then
  OUTER_LOG="$(mktemp /tmp/tsuri_save_isolation_outer.XXXXXX)"
  ACTIVE_RUNNER_PID=""
  cleanup_outer_log() {
    if [[ -f "$OUTER_LOG" && ! -L "$OUTER_LOG" ]]; then
      rm -f -- "$OUTER_LOG"
    fi
  }
  interrupt_outer_runner() {
    local signal_name="$1"
    local exit_code="$2"
    trap - HUP INT TERM
    if [[ -n "$ACTIVE_RUNNER_PID" ]] && kill -0 "$ACTIVE_RUNNER_PID" 2>/dev/null; then
      kill -s "$signal_name" "$ACTIVE_RUNNER_PID" 2>/dev/null || true
      wait "$ACTIVE_RUNNER_PID" 2>/dev/null || true
    fi
    ACTIVE_RUNNER_PID=""
    exit "$exit_code"
  }
  trap cleanup_outer_log EXIT
  trap 'interrupt_outer_runner HUP 129' HUP
  trap 'interrupt_outer_runner INT 130' INT
  trap 'interrupt_outer_runner TERM 143' TERM

  python3 "$COMMAND_RUNNER" run \
    --timeout-seconds "$TOTAL_TIMEOUT_SECONDS" \
    --term-grace-seconds "$TOTAL_TERM_GRACE_SECONDS" \
    --log "$OUTER_LOG" --echo -- \
    env TSURI_SAVE_ISOLATION_SUPERVISED=1 "$SCRIPT_PATH" "$@" &
  ACTIVE_RUNNER_PID=$!
  outer_status=0
  if wait "$ACTIVE_RUNNER_PID"; then
    outer_status=0
  else
    outer_status=$?
  fi
  ACTIVE_RUNNER_PID=""
  exit "$outer_status"
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

TEST_PARENT="${TMPDIR:-/tmp}"
while [[ "$TEST_PARENT" != "/" && "$TEST_PARENT" == */ ]]; do
  TEST_PARENT="${TEST_PARENT%/}"
done
[[ -d "$TEST_PARENT" ]]
TEST_PARENT="$(cd "$TEST_PARENT" && pwd -P)"
TEST_ROOT="$(mktemp -d "$TEST_PARENT/tsuri_save_isolation_test.XXXXXX")"
TEST_ROOT="$(cd "$TEST_ROOT" && pwd -P)"
cleanup_test_root() {
  rm -rf -- "$TEST_ROOT"
}
trap cleanup_test_root EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

run_bounded_command() {
  local timeout_seconds="$1"
  local grace_seconds="$2"
  local log_path="$3"
  shift 3
  python3 "$COMMAND_RUNNER" run \
    --timeout-seconds "$timeout_seconds" \
    --term-grace-seconds "$grace_seconds" \
    --log "$log_path" -- "$@"
}

run_import_warmup() {
  local godot_bin="$1"
  local warmup_home="$2"
  local log_path="$3"
  local timeout_seconds="$4"
  local grace_seconds="$5"
  local status=0
  mkdir -p "$warmup_home"
  run_bounded_command "$timeout_seconds" "$grace_seconds" "$log_path" \
    env HOME="$warmup_home" TSURI_GODOT_HOME="$warmup_home" \
    "$godot_bin" --headless --editor --path "$ROOT" --quit \
    || status=$?
  rm -rf -- "$warmup_home"
  return "$status"
}

assert_process_gone() {
  local process_id="$1"
  local attempt
  for attempt in {1..100}; do
    if ! kill -0 "$process_id" 2>/dev/null; then
      return
    fi
    sleep 0.02
  done
  echo "timeout後もdescendant processが残っています: $process_id" >&2
  exit 1
}

FAKE_GODOT="$TEST_ROOT/fake_godot"
FAKE_LOG="$TEST_ROOT/fake.log"
cat > "$FAKE_GODOT" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
expected="${TSURI_QA_ISOLATED_HOME:-}"
token="${TSURI_QA_RUN_TOKEN:-}"
[[ -n "$expected" && "$HOME" == "$expected" && -n "$token" ]]
[[ -f "$HOME/.tsuri_save_qa_guard" ]]
[[ "$(cat "$HOME/.tsuri_save_qa_guard")" == "$token" ]]
kind=""
if [[ "${TSURI_SAVE_MIGRATION_SMOKE_ALLOW:-}" == "1" ]]; then
  kind=migration
elif [[ "${TSURI_SAVE_SMOKE_ALLOW:-}" == "1" ]]; then
  kind=save
else
  exit 9
fi
printf '%s|%s|%s\n' "$HOME" "$kind" "$token" >> "$TSURI_FAKE_GODOT_LOG"
sleep 0.15
if [[ "${TSURI_FAKE_FAIL_KIND:-}" == "$kind" ]]; then
  exit 17
fi
SH
chmod +x "$FAKE_GODOT"

expect_exit_2() {
  local output="$TEST_ROOT/rejection.log"
  set +e
  "$@" >"$output" 2>&1
  local status=$?
  set -e
  if [[ "$status" -ne 2 ]]; then
    cat "$output" >&2
    echo "expected exit 2, got $status: $*" >&2
    exit 1
  fi
}

assert_file_hash() {
  local path="$1" expected="$2"
  [[ "$(shasum -a 256 "$path" | awk '{print $1}')" == "$expected" ]]
}

run_direct_rejection() {
  local scene="$1" allow_name="$2" actual="$3" expected="$4" token="$5"
  expect_exit_2 env \
    HOME="$actual" \
    TSURI_QA_ISOLATED_HOME="$expected" \
    TSURI_QA_RUN_TOKEN="$token" \
    "$allow_name=1" \
    "$GODOT" --headless --path "$ROOT" "res://tools/$scene"
}

# 既定親の2並列wrapperが4つのscene別HOMEを作り、終了時に全て片付ける。
PARALLEL_PARENT="$TEST_ROOT/parallel"
mkdir -p "$PARALLEL_PARENT"
: > "$FAKE_LOG"
env -u TSURI_GODOT_HOME TMPDIR="$PARALLEL_PARENT" GODOT_BIN="$FAKE_GODOT" \
  TSURI_FAKE_GODOT_LOG="$FAKE_LOG" "$ROOT/tools/save_system_verify.sh" >"$TEST_ROOT/parallel-1.log" 2>&1 &
first_pid=$!
env -u TSURI_GODOT_HOME TMPDIR="$PARALLEL_PARENT" GODOT_BIN="$FAKE_GODOT" \
  TSURI_FAKE_GODOT_LOG="$FAKE_LOG" "$ROOT/tools/save_system_verify.sh" >"$TEST_ROOT/parallel-2.log" 2>&1 &
second_pid=$!
wait "$first_pid"
wait "$second_pid"
[[ "$(wc -l < "$FAKE_LOG" | tr -d '[:space:]')" == "4" ]]
[[ "$(cut -d'|' -f1 "$FAKE_LOG" | LC_ALL=C sort -u | wc -l | tr -d '[:space:]')" == "4" ]]
[[ "$(cut -d'|' -f1 "$FAKE_LOG" | xargs -n1 dirname | LC_ALL=C sort -u | wc -l | tr -d '[:space:]')" == "2" ]]
[[ "$(cut -d'|' -f2 "$FAKE_LOG" | LC_ALL=C sort | tr '\n' ' ')" == "migration migration save save " ]]
while IFS='|' read -r isolated_home _kind _token; do
  [[ ! -e "$isolated_home" ]]
done < "$FAKE_LOG"
if find "$PARALLEL_PARENT" -mindepth 1 -maxdepth 1 -name 'tsuri_save_system.*' -print -quit | grep -q .; then
  echo "parallel wrapperのrun rootが残っています" >&2
  exit 1
fi

# scene失敗でも元の終了コードを保ち、run rootを残さない。
FAIL_PARENT="$TEST_ROOT/failure_cleanup"
mkdir -p "$FAIL_PARENT"
set +e
TSURI_GODOT_HOME="$FAIL_PARENT" GODOT_BIN="$FAKE_GODOT" \
  TSURI_FAKE_GODOT_LOG="$FAKE_LOG" TSURI_FAKE_FAIL_KIND=migration \
  "$ROOT/tools/save_system_verify.sh" >"$TEST_ROOT/failure-cleanup.log" 2>&1
failure_status=$?
set -e
[[ "$failure_status" -eq 17 ]]
if find "$FAIL_PARENT" -mindepth 1 -maxdepth 1 -name 'tsuri_save_system.*' -print -quit | grep -q .; then
  echo "失敗したwrapperのrun rootが残っています" >&2
  exit 1
fi

# bounded runnerのwarm-up/actual timeoutを、TERM無視descendantとmarkerで固定する。
HUNG_GODOT="$TEST_ROOT/hung_godot.py"
cat > "$HUNG_GODOT" <<'PY'
#!/usr/bin/env python3
import os
from pathlib import Path
import subprocess
import sys
import time

ready = os.environ["TSURI_HUNG_READY"]
marker = os.environ["TSURI_HUNG_MARKER"]
pid_path = os.environ["TSURI_HUNG_PID_PATH"]
child_code = (
    "import os, pathlib, signal, time; "
    "signal.signal(signal.SIGTERM, signal.SIG_IGN); "
    f"pathlib.Path({pid_path!r}).write_text(str(os.getpid())); "
    f"pathlib.Path({ready!r}).write_text('ready'); "
    "time.sleep(1.5); "
    f"pathlib.Path({marker!r}).write_text('orphan')"
)
subprocess.Popen([sys.executable, "-c", child_code])
deadline = time.monotonic() + 2.0
while not Path(ready).exists() and time.monotonic() < deadline:
    time.sleep(0.01)
time.sleep(10)
PY
chmod +x "$HUNG_GODOT"

HUNG_WARMUP_HOME="$TEST_ROOT/hung_warmup_home"
HUNG_WARMUP_READY="$TEST_ROOT/hung_warmup_ready"
HUNG_WARMUP_MARKER="$TEST_ROOT/hung_warmup_marker"
HUNG_WARMUP_PID="$TEST_ROOT/hung_warmup.pid"
export TSURI_HUNG_READY="$HUNG_WARMUP_READY"
export TSURI_HUNG_MARKER="$HUNG_WARMUP_MARKER"
export TSURI_HUNG_PID_PATH="$HUNG_WARMUP_PID"
set +e
run_import_warmup \
  "$HUNG_GODOT" "$HUNG_WARMUP_HOME" "$TEST_ROOT/hung-warmup.log" 0.75 0.1
hung_warmup_status=$?
set -e
if [[ "$hung_warmup_status" -ne 124 ]]; then
  cat "$TEST_ROOT/hung-warmup.log" >&2
  echo "hung warm-upのtimeout codeが不正です: $hung_warmup_status" >&2
  exit 1
fi
if [[ ! -f "$HUNG_WARMUP_READY" || ! -f "$HUNG_WARMUP_PID" || -e "$HUNG_WARMUP_HOME" ]]; then
  cat "$TEST_ROOT/hung-warmup.log" >&2
  echo "hung warm-up fixture準備またはHOME cleanupに失敗しました" >&2
  exit 1
fi
assert_process_gone "$(cat "$HUNG_WARMUP_PID")"
sleep 1.55
if [[ -e "$HUNG_WARMUP_MARKER" ]]; then
  echo "hung warm-up descendantがtimeout後にmarkerを書きました" >&2
  exit 1
fi

HUNG_ACTUAL_PARENT="$TEST_ROOT/hung_actual_parent"
HUNG_ACTUAL_READY="$TEST_ROOT/hung_actual_ready"
HUNG_ACTUAL_MARKER="$TEST_ROOT/hung_actual_marker"
HUNG_ACTUAL_PID="$TEST_ROOT/hung_actual.pid"
mkdir -p "$HUNG_ACTUAL_PARENT"
export TSURI_HUNG_READY="$HUNG_ACTUAL_READY"
export TSURI_HUNG_MARKER="$HUNG_ACTUAL_MARKER"
export TSURI_HUNG_PID_PATH="$HUNG_ACTUAL_PID"
set +e
run_bounded_command 1 0.1 "$TEST_ROOT/hung-actual.log" \
  env TSURI_GODOT_HOME="$HUNG_ACTUAL_PARENT" GODOT_BIN="$HUNG_GODOT" \
  "$ROOT/tools/save_system_verify.sh"
hung_actual_status=$?
set -e
if [[ "$hung_actual_status" -ne 124 ]]; then
  cat "$TEST_ROOT/hung-actual.log" >&2
  echo "hung actual sceneのtimeout codeが不正です: $hung_actual_status" >&2
  exit 1
fi
if [[ ! -f "$HUNG_ACTUAL_READY" || ! -f "$HUNG_ACTUAL_PID" ]]; then
  cat "$TEST_ROOT/hung-actual.log" >&2
  echo "hung actual scene fixtureの準備に失敗しました" >&2
  exit 1
fi
assert_process_gone "$(cat "$HUNG_ACTUAL_PID")"
sleep 1.55
if [[ -e "$HUNG_ACTUAL_MARKER" ]]; then
  echo "hung actual scene descendantがtimeout後にmarkerを書きました" >&2
  exit 1
fi
if find "$HUNG_ACTUAL_PARENT" -mindepth 1 -maxdepth 1 -name 'tsuri_save_system.*' -print -quit | grep -q .; then
  echo "timeoutしたactual wrapperのrun rootが残っています" >&2
  exit 1
fi
unset TSURI_HUNG_READY TSURI_HUNG_MARKER TSURI_HUNG_PID_PATH

# cold checkoutでも共有.godot importを並列起動しないよう、run固有HOMEで直列warm-upする。
IMPORT_WARMUP_HOME="$TEST_ROOT/import_warmup_home"
if ! run_import_warmup \
  "$GODOT" "$IMPORT_WARMUP_HOME" "$TEST_ROOT/import-warmup.log" \
  "$COMMAND_TIMEOUT_SECONDS" "$TERM_GRACE_SECONDS"; then
  cat "$TEST_ROOT/import-warmup.log" >&2
  echo "save isolation import warm-up failed" >&2
  exit 1
fi
[[ ! -e "$IMPORT_WARMUP_HOME" ]]

# 実sceneも同じ既定親で2並列実行し、旧固定HOMEの相互破壊が再発しないことを確認する。
ACTUAL_PARALLEL_PARENT="$TEST_ROOT/actual_parallel"
mkdir -p "$ACTUAL_PARALLEL_PARENT"
run_bounded_command \
  "$COMMAND_TIMEOUT_SECONDS" "$TERM_GRACE_SECONDS" "$TEST_ROOT/actual-parallel-1.log" \
  env -u TSURI_GODOT_HOME TMPDIR="$ACTUAL_PARALLEL_PARENT" GODOT_BIN="$GODOT" \
  "$ROOT/tools/save_system_verify.sh" &
first_pid=$!
run_bounded_command \
  "$COMMAND_TIMEOUT_SECONDS" "$TERM_GRACE_SECONDS" "$TEST_ROOT/actual-parallel-2.log" \
  env -u TSURI_GODOT_HOME TMPDIR="$ACTUAL_PARALLEL_PARENT" GODOT_BIN="$GODOT" \
  "$ROOT/tools/save_system_verify.sh" &
second_pid=$!
set +e
wait "$first_pid"
first_status=$?
wait "$second_pid"
second_status=$?
set -e
if [[ "$first_status" -ne 0 || "$second_status" -ne 0 ]]; then
  cat "$TEST_ROOT/actual-parallel-1.log" "$TEST_ROOT/actual-parallel-2.log" >&2
  echo "actual parallel save verification failed: $first_status / $second_status" >&2
  exit 1
fi
grep -q 'Save system verification passed.' "$TEST_ROOT/actual-parallel-1.log"
grep -q 'Save system verification passed.' "$TEST_ROOT/actual-parallel-2.log"
if find "$ACTUAL_PARALLEL_PARENT" -mindepth 1 -maxdepth 1 -name 'tsuri_save_system.*' -print -quit | grep -q .; then
  echo "actual parallel wrapperのrun rootが残っています" >&2
  exit 1
fi

# callerのHOMEを親に指定しても、Godotにはrun子HOMEだけを渡す。
SIMULATED_ACTUAL_HOME="$TEST_ROOT/simulated_actual_home"
mkdir -p "$SIMULATED_ACTUAL_HOME"
: > "$FAKE_LOG"
HOME="$SIMULATED_ACTUAL_HOME" TSURI_GODOT_HOME="$SIMULATED_ACTUAL_HOME" \
  GODOT_BIN="$FAKE_GODOT" TSURI_FAKE_GODOT_LOG="$FAKE_LOG" \
  "$ROOT/tools/save_system_verify.sh" >/dev/null
while IFS='|' read -r isolated_home _kind _token; do
  [[ "$isolated_home" != "$SIMULATED_ACTUAL_HOME" ]]
  case "$isolated_home" in
    "$SIMULATED_ACTUAL_HOME"/tsuri_save_system.*/migration|"$SIMULATED_ACTUAL_HOME"/tsuri_save_system.*/save) ;;
    *) echo "caller HOMEがrun子HOMEへ分離されていません: $isolated_home" >&2; exit 1 ;;
  esac
  [[ ! -e "$isolated_home" ]]
done < "$FAKE_LOG"

# raw曖昧path、root、symlink親、nested symlink祖先をwrapperで拒否する。
PROTECTED_PARENT="$TEST_ROOT/protected_parent"
OUTSIDE_PARENT="$TEST_ROOT/outside_parent"
mkdir -p "$PROTECTED_PARENT" "$OUTSIDE_PARENT/child"
printf '%s' 'outside-byte-sentinel' > "$OUTSIDE_PARENT/sentinel"
outside_hash="$(shasum -a 256 "$OUTSIDE_PARENT/sentinel" | awk '{print $1}')"
ln -s "$OUTSIDE_PARENT" "$TEST_ROOT/parent_link"
ln -s "$OUTSIDE_PARENT" "$PROTECTED_PARENT/nested_link"
for unsafe_parent in \
  "/" \
  " $PROTECTED_PARENT " \
  "$PROTECTED_PARENT/../protected_parent" \
  "$TEST_ROOT/parent_link" \
  "$PROTECTED_PARENT/nested_link/child"; do
  expect_exit_2 env TSURI_GODOT_HOME="$unsafe_parent" GODOT_BIN="$FAKE_GODOT" \
    TSURI_FAKE_GODOT_LOG="$FAKE_LOG" "$ROOT/tools/save_system_verify.sh"
  assert_file_hash "$OUTSIDE_PARENT/sentinel" "$outside_hash"
done

# GDScript側もactual/expected不一致、token不一致、raw曖昧path、書込先linkをexit 2で拒否する。
for scene_contract in \
  'save_namespace_migration_smoke.tscn TSURI_SAVE_MIGRATION_SMOKE_ALLOW' \
  'save_system_smoke.tscn TSURI_SAVE_SMOKE_ALLOW'; do
  read -r scene allow_name <<< "$scene_contract"

  actual="$TEST_ROOT/direct_${scene}_actual"
  expected="$TEST_ROOT/direct_${scene}_expected"
  mkdir -p "$actual" "$expected"
  printf '%s' 'expected-token' > "$expected/.tsuri_save_qa_guard"
  printf '%s' 'actual-byte-sentinel' > "$actual/protected"
  actual_hash="$(shasum -a 256 "$actual/protected" | awk '{print $1}')"
  run_direct_rejection "$scene" "$allow_name" "$actual" "$expected" expected-token
  assert_file_hash "$actual/protected" "$actual_hash"

  token_home="$TEST_ROOT/direct_${scene}_token"
  mkdir -p "$token_home"
  printf '%s' 'stored-token' > "$token_home/.tsuri_save_qa_guard"
  printf '%s' 'token-byte-sentinel' > "$token_home/protected"
  token_hash="$(shasum -a 256 "$token_home/protected" | awk '{print $1}')"
  run_direct_rejection "$scene" "$allow_name" "$token_home" "$token_home" different-token
  assert_file_hash "$token_home/protected" "$token_hash"

  raw_home="$TEST_ROOT/direct_${scene}_raw"
  mkdir -p "$raw_home"
  printf '%s' 'raw-token' > "$raw_home/.tsuri_save_qa_guard"
  printf '%s' 'raw-byte-sentinel' > "$raw_home/protected"
  raw_hash="$(shasum -a 256 "$raw_home/protected" | awk '{print $1}')"
  run_direct_rejection "$scene" "$allow_name" "$raw_home" "$raw_home/../$(basename "$raw_home")" raw-token
  assert_file_hash "$raw_home/protected" "$raw_hash"

  link_home="$TEST_ROOT/direct_${scene}_link"
  link_outside="$TEST_ROOT/direct_${scene}_link_outside"
  mkdir -p "$link_home/Library/Application Support" "$link_outside/slots/1"
  printf '%s' 'link-token' > "$link_home/.tsuri_save_qa_guard"
  printf '%s' 'linked-save-byte-sentinel' > "$link_outside/slots/1/tsuri_quest_save.json"
  linked_hash="$(shasum -a 256 "$link_outside/slots/1/tsuri_quest_save.json" | awk '{print $1}')"
  ln -s "$link_outside" "$link_home/Library/Application Support/tsuri_quest_umi"
  run_direct_rejection "$scene" "$allow_name" "$link_home" "$link_home" link-token
  assert_file_hash "$link_outside/slots/1/tsuri_quest_save.json" "$linked_hash"

  file_home="$TEST_ROOT/direct_${scene}_file_target"
  mkdir -p "$file_home/Library/Application Support/tsuri_quest_umi"
  printf '%s' 'file-target-token' > "$file_home/.tsuri_save_qa_guard"
  printf '%s' 'must-remain-a-file' > "$file_home/Library/Application Support/tsuri_quest_umi/slots"
  file_target_hash="$(shasum -a 256 "$file_home/Library/Application Support/tsuri_quest_umi/slots" | awk '{print $1}')"
  run_direct_rejection "$scene" "$allow_name" "$file_home" "$file_home" file-target-token
  assert_file_hash "$file_home/Library/Application Support/tsuri_quest_umi/slots" "$file_target_hash"
done

echo "save system isolation self-test: ok"
