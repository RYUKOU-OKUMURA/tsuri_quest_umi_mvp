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

RUN_DIR="$(mktemp -d "${TMPDIR:-/tmp}/e11-qa-harness.XXXXXX")"
trap 'rm -rf "$RUN_DIR"' EXIT
mkdir -p "$RUN_DIR/home"

run_probe() {
  local scene="$1"
  local output="$2"
  shift 2
  HOME="$RUN_DIR/home" "$GODOT" --headless --path "$ROOT" "res://tools/$scene" -- "$@" --output "$output"
}

run_probe e11_input_focus_probe.tscn "$RUN_DIR/input-self.json" --self-test
run_probe e11_resolution_probe.tscn "$RUN_DIR/resolution-self.json" --self-test
run_probe e11_input_focus_probe.tscn "$RUN_DIR/input-baseline.json"
run_probe e11_resolution_probe.tscn "$RUN_DIR/resolution-baseline.json"

set +e
run_probe e11_resolution_probe.tscn "$RUN_DIR/resolution-strict.json" --strict
strict_rc=$?
run_probe e11_input_focus_probe.tscn "$RUN_DIR/harness-error.json" --self-test --self-test-harness-error
harness_rc=$?
set -e
[[ "$strict_rc" -eq 1 ]] || { echo "strict findingの終了コードが1ではありません: $strict_rc" >&2; exit 1; }
[[ "$harness_rc" -eq 2 ]] || { echo "harness errorの終了コードが2ではありません: $harness_rc" >&2; exit 1; }

python3 - "$RUN_DIR" "$ROOT" <<'PY'
import importlib.util
import json
import pathlib
import sys

run_dir, root = map(pathlib.Path, sys.argv[1:])
required = {
    "schema_version": int,
    "probe": str,
    "mode": str,
    "harness_status": str,
    "product_status": str,
    "findings": list,
    "harness_errors": list,
}

def load(name):
    data = json.loads((run_dir / name).read_text(encoding="utf-8"))
    for key, kind in required.items():
        assert key in data and isinstance(data[key], kind), f"{name}: schema {key}"
    assert data["schema_version"] == 1
    assert data["harness_status"] in {"ok", "error"}
    for finding in data["findings"]:
        assert {"code", "severity", "target", "message", "evidence"} <= finding.keys()
        assert finding["severity"] in {"P0", "P1", "P2", "P3"}
        assert all(isinstance(finding[key], str) for key in ("code", "severity", "target", "message"))
        assert isinstance(finding["evidence"], dict)
    assert data["product_status"] == ("pass" if not data["findings"] else "findings")
    return data

input_self = load("input-self.json")
resolution_self = load("resolution-self.json")
input_baseline = load("input-baseline.json")
resolution_baseline = load("resolution-baseline.json")
resolution_strict = load("resolution-strict.json")
harness_error = load("harness-error.json")
fixtures = {item["id"]: item["classification"] for item in input_self["screens"]}
assert fixtures == {"fixture_good": "pass", "fixture_bad": "finding"}
assert not input_self["findings"]
assert not resolution_self["findings"]
assert len(input_baseline["screens"]) == input_baseline["registry_count"] == 12
assert input_baseline["product_status"] in {"pass", "findings"}
assert resolution_baseline["product_status"] in {"pass", "findings"}
assert len(resolution_baseline["measurements"]) == 3
assert all("observed" in item and "matches_expected_keep" in item for item in resolution_baseline["measurements"])
assert resolution_strict["findings"] and resolution_strict["mode"] == "strict"
assert harness_error["harness_status"] == "error" and harness_error["harness_errors"]

spec = importlib.util.spec_from_file_location("release_verify", root / "tools/release_verify.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
tests = module.discover(root)
manifest = module.load_manifest(root / "tools/release_test_manifest.txt")
module.classify(tests, manifest)
assert len(tests) == len(manifest) == 30
assert not any("e11_" in item for item in tests)
print(f"e11_qa_harness: schema/fixtures/baseline ok; release tests={len(tests)}")
PY

echo "e11_qa_harness_verify: ok"
