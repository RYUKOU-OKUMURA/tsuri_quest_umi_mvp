#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_HOME="${TSURI_GODOT_HOME:-/tmp/tsuri_shipyard_qa_home}"
QA_DATE="${TSURI_QA_DATE:-2026-07-18}"

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

CAPTURES=(
  /tmp/tsuri_shipyard_available.png
  /tmp/tsuri_shipyard_insufficient.png
  /tmp/tsuri_shipyard_purchased_focus_fallback.png
  /tmp/tsuri_shipyard_all_owned.png
)
EVIDENCE=(
  "$ROOT/docs/qa/evidence/shipyard/${QA_DATE}_current_available_focus.png"
  "$ROOT/docs/qa/evidence/shipyard/${QA_DATE}_current_insufficient.png"
  "$ROOT/docs/qa/evidence/shipyard/${QA_DATE}_current_purchased_focus_fallback.png"
  "$ROOT/docs/qa/evidence/shipyard/${QA_DATE}_current_all_owned.png"
  "$ROOT/docs/qa/evidence/shipyard/${QA_DATE}_d0_current_reference_full.png"
  "$ROOT/docs/qa/evidence/shipyard/${QA_DATE}_d0_current_reference_320x180.png"
  "$ROOT/docs/qa/evidence/shipyard/${QA_DATE}_d0_current_states_320x180.png"
)

mkdir -p "$GODOT_HOME" "$ROOT/docs/qa/evidence/shipyard"
rm -f "${CAPTURES[@]}" "${EVIDENCE[@]}"

echo "==> SHIPYARD-D0 checker self-test"
python3 "$ROOT/tools/build_shipyard_visual_comparison.py" --self-test

capture_state() {
  local state="$1"
  local output="$2"
  echo "==> Capture shipyard ${state}"
  HOME="$GODOT_HOME" "$GODOT" --path "$ROOT" res://tools/shipyard_preview.tscn -- \
    "--state=${state}" "--output=${output}"
  if [[ ! -s "$output" ]]; then
    echo "Shipyard preview did not create expected capture: $output" >&2
    exit 1
  fi
}

capture_state available_focus /tmp/tsuri_shipyard_available.png
capture_state insufficient /tmp/tsuri_shipyard_insufficient.png
capture_state purchased_focus_fallback /tmp/tsuri_shipyard_purchased_focus_fallback.png
capture_state all_owned /tmp/tsuri_shipyard_all_owned.png

echo "==> Validate captures and build formal evidence"
TSURI_QA_DATE="$QA_DATE" python3 "$ROOT/tools/build_shipyard_visual_comparison.py"

for path in "${EVIDENCE[@]}"; do
  if [[ ! -s "$path" ]]; then
    echo "Shipyard visual QA evidence is missing: $path" >&2
    exit 1
  fi
done

echo "Shipyard visual QA outputs:"
printf '%s\n' "${CAPTURES[@]}"
printf '%s\n' "${EVIDENCE[@]}"
echo "$ROOT/reference/shipyard_d0_proposal_unapproved.png"
