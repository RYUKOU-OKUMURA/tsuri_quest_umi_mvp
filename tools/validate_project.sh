#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if command -v godot >/dev/null 2>&1; then
  GODOT=godot
elif command -v godot4 >/dev/null 2>&1; then
  GODOT=godot4
elif [[ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]]; then
  GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
else
  echo "Godot 4.xが見つかりません。" >&2
  exit 1
fi

GODOT_HOME="${TSURI_GODOT_HOME:-${TMPDIR:-/tmp}/tsuri-godot-home}"
mkdir -p "$GODOT_HOME"

python3 "$ROOT/tools/audit_showcase_asset_refs.py"
python3 "$ROOT/tools/audit_fish_asset_duplicates.py"
python3 "$ROOT/tools/audit_fish_sheet_contract.py"
HOME="$GODOT_HOME" "$GODOT" --headless --path "$ROOT" "res://tools/fish_catalog_asset_audit.tscn"
python3 "$ROOT/tools/audit_product_identifiers.py"
python3 "$ROOT/tools/audit_licensing_docs.py" --self-test
python3 "$ROOT/tools/audit_licensing_docs.py"
python3 "$ROOT/tools/build_screen_visual_comparison.py" --self-test
python3 "$ROOT/tools/cooking_generator_determinism_verify.py"
python3 "$ROOT/tools/process_cooking_c1b_assets.py" --check
python3 "$ROOT/tools/process_cooking_c1b_assets.py" --check-self-test
HOME="$GODOT_HOME" "$GODOT" --headless --editor --path "$ROOT" --quit
HOME="$GODOT_HOME" "$GODOT" --headless --path "$ROOT" --quit-after 2
