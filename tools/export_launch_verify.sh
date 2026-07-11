#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
PRESET="macOS Universal"
BUILD_ROOT="${TSURI_EXPORT_BUILD_ROOT:-/tmp/tsuri_quest_umi_export_spike}"
DEBUG_APP="$BUILD_ROOT/debug/tsuri_quest_umi.app"
RELEASE_APP="$BUILD_ROOT/release/tsuri_quest_umi.app"
FIXTURE_HOME="$BUILD_ROOT/user_home"
NEGATIVE_HOME="$BUILD_ROOT/negative_home"
LOG_DIR="$BUILD_ROOT/logs"
STAGE_ROOT="$BUILD_ROOT/stage"
ARTIFACT_LOG="$LOG_DIR/artifacts.sha256"
RELEASE_PACK_MANIFEST="$LOG_DIR/release_pack_manifest.txt"
BUNDLE_ID="net.physical-balance-lab.tsuri-quest-umi"
SOURCE_REF="${TSURI_EXPORT_SOURCE_REF:-HEAD}"

fail() {
	echo "export_launch_verify: FAIL: $*" >&2
	exit 1
}

BUILD_PARENT="$(cd "$(dirname "$BUILD_ROOT")" 2>/dev/null && pwd -P)" || fail "build parent does not exist: $(dirname "$BUILD_ROOT")"
BUILD_BASENAME="$(basename "$BUILD_ROOT")"
[[ "$BUILD_BASENAME" == tsuri_quest_umi_export_* ]] || fail "unsafe build directory name: $BUILD_BASENAME"
[[ "$BUILD_PARENT" == "/private/tmp" ]] || fail "build directory must be directly under /tmp: $BUILD_PARENT/$BUILD_BASENAME"
BUILD_ROOT="$BUILD_PARENT/$BUILD_BASENAME"
DEBUG_APP="$BUILD_ROOT/debug/tsuri_quest_umi.app"
RELEASE_APP="$BUILD_ROOT/release/tsuri_quest_umi.app"
FIXTURE_HOME="$BUILD_ROOT/user_home"
NEGATIVE_HOME="$BUILD_ROOT/negative_home"
LOG_DIR="$BUILD_ROOT/logs"
STAGE_ROOT="$BUILD_ROOT/stage"
ARTIFACT_LOG="$LOG_DIR/artifacts.sha256"
RELEASE_PACK_MANIFEST="$LOG_DIR/release_pack_manifest.txt"

[[ -x "$GODOT_BIN" ]] || fail "Godot not found: $GODOT_BIN"
GODOT_VERSION="$($GODOT_BIN --version | tr -d '\r')"
TEMPLATE_VERSION="${GODOT_VERSION%%.official.*}"
TEMPLATE_ROOT="$HOME/Library/Application Support/Godot/export_templates/$TEMPLATE_VERSION"
[[ -f "$TEMPLATE_ROOT/macos.zip" ]] || fail "macOS export template missing: $TEMPLATE_ROOT/macos.zip (Godot $GODOT_VERSION)"
SOURCE_COMMIT="$(git -C "$ROOT_DIR" rev-parse --verify "$SOURCE_REF^{commit}" 2>/dev/null)" || fail "source ref must resolve to a commit: $SOURCE_REF"
SOURCE_OBJECT="$(git -C "$ROOT_DIR" rev-parse --verify "$SOURCE_COMMIT^{tree}")" || fail "could not resolve source tree: $SOURCE_COMMIT"

rm -rf "$BUILD_ROOT"
mkdir -p "$BUILD_ROOT/debug" "$BUILD_ROOT/release" "$LOG_DIR"

# trackedかつ指定Git objectに固定したtreeだけを展開する。worktreeのdirty/untracked/ignoredは
# 入力にしない。Universal向け設定とsmoke autoloadはstageだけへ追加する。
mkdir -p "$STAGE_ROOT"
git -C "$ROOT_DIR" archive "$SOURCE_OBJECT" | tar -x -C "$STAGE_ROOT"
mkdir -p "$STAGE_ROOT/src/__export_spike"
cp "$STAGE_ROOT/tools/export_launch_smoke.gd" "$STAGE_ROOT/src/__export_spike/export_launch_smoke.gd"
perl -0pi -e 's/\[rendering\]\n/[rendering]\ntextures\/vram_compression\/import_etc2_astc=true\n/' "$STAGE_ROOT/project.godot"
perl -0pi -e 's/\[autoload\]\n/[autoload]\n\nExportLaunchPreflight="*res:\/\/src\/__export_spike\/export_launch_smoke.gd"\n/' "$STAGE_ROOT/project.godot"
perl -0pi -e 's/(Juicer=.*\n)/$1ExportLaunchSmoke="*res:\/\/src\/__export_spike\/export_launch_smoke.gd"\n/' "$STAGE_ROOT/project.godot"

"$GODOT_BIN" --headless --path "$STAGE_ROOT" --export-debug "$PRESET" "$DEBUG_APP" 2>&1 | tee "$LOG_DIR/export_debug.log"
"$GODOT_BIN" --headless --path "$STAGE_ROOT" --export-release "$PRESET" "$RELEASE_APP" 2>&1 | tee "$LOG_DIR/export_release.log"

# Godotのlocalized progress logからsavepack対象だけを抽出し、順序とANSI表示に
# 依存しないcanonical manifestを残す。不要素材検査も同じmanifestを正とする。
perl -pe 's/\e\[[0-9;]*[A-Za-z]//g; s/\r//g' "$LOG_DIR/export_release.log" \
	| perl -ne 'print "$1\n" if /savepack.*?(res:\/\/.*)$/' \
	| LC_ALL=C sort -u > "$RELEASE_PACK_MANIFEST"
[[ -s "$RELEASE_PACK_MANIFEST" ]] || fail "release pack manifest is empty"
RELEASE_PACK_MANIFEST_COUNT="$(wc -l < "$RELEASE_PACK_MANIFEST" | tr -d '[:space:]')"
[[ "$RELEASE_PACK_MANIFEST_COUNT" =~ ^[1-9][0-9]*$ ]] || fail "invalid release pack manifest count"
RELEASE_PACK_MANIFEST_SHA256="$(shasum -a 256 "$RELEASE_PACK_MANIFEST" | awk '{print $1}')"
if grep -a -E '^res://(reference|tools|\.git|build)(/|$)' "$RELEASE_PACK_MANIFEST" >/dev/null; then
	fail "forbidden development resources found in release pack manifest"
fi

for app in "$DEBUG_APP" "$RELEASE_APP"; do
	[[ -d "$app" ]] || fail "export was not created: $app"
	identifier="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Contents/Info.plist")"
	[[ "$identifier" == "$BUNDLE_ID" ]] || fail "bundle ID mismatch in $app: $identifier"
	executable_name="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$app/Contents/Info.plist")"
	lipo_info="$(lipo -info "$app/Contents/MacOS/$executable_name" 2>&1)"
	[[ "$lipo_info" == *"x86_64"* && "$lipo_info" == *"arm64"* ]] || fail "not Universal: $lipo_info"
done

single_pck_path() {
	local app="$1"
	local resources="$app/Contents/Resources"
	local pcks=("$resources"/*.pck)
	[[ -e "${pcks[0]}" ]] || fail "PCK is missing: $resources"
	[[ "${#pcks[@]}" -eq 1 ]] || fail "expected exactly one PCK in $resources, found ${#pcks[@]}"
	printf '%s\n' "${pcks[0]}"
}

DEBUG_PCK="$(single_pck_path "$DEBUG_APP")"
RELEASE_PCK="$(single_pck_path "$RELEASE_APP")"
DEBUG_PCK_SHA256="$(shasum -a 256 "$DEBUG_PCK" | awk '{print $1}')"
RELEASE_PCK_SHA256="$(shasum -a 256 "$RELEASE_PCK" | awk '{print $1}')"
{
	printf 'source_commit=%s\n' "$SOURCE_COMMIT"
	printf 'source_tree=%s\n' "$SOURCE_OBJECT"
	printf 'debug_pck=%s\n' "$DEBUG_PCK"
	printf 'debug_pck_sha256=%s\n' "$DEBUG_PCK_SHA256"
	printf 'release_pck=%s\n' "$RELEASE_PCK"
	printf 'release_pck_sha256=%s\n' "$RELEASE_PCK_SHA256"
	printf 'release_pack_manifest=%s\n' "$RELEASE_PACK_MANIFEST"
	printf 'release_pack_manifest_count=%s\n' "$RELEASE_PACK_MANIFEST_COUNT"
	printf 'release_pack_manifest_sha256=%s\n' "$RELEASE_PACK_MANIFEST_SHA256"
} > "$ARTIFACT_LOG"

RELEASE_EXECUTABLE_NAME="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$RELEASE_APP/Contents/Info.plist")"
EXECUTABLE="$RELEASE_APP/Contents/MacOS/$RELEASE_EXECUTABLE_NAME"

# preflight負ケース: actual HOMEと異なるexpected pathではPlayerProgressより前に停止し、
# actual user dataへmigration/save artifactを一切作らない。
rm -rf "$NEGATIVE_HOME"
mkdir -p "$NEGATIVE_HOME"
NEGATIVE_ACTUAL_USER_DIR="$NEGATIVE_HOME/Library/Application Support/tsuri_quest_umi"
NEGATIVE_EXPECTED_USER_DIR="$NEGATIVE_HOME/expected_mismatch/tsuri_quest_umi"
set +e
HOME="$NEGATIVE_HOME" "$EXECUTABLE" --headless -- \
	--tsuri-export-smoke=create "--tsuri-expected-user-dir=$NEGATIVE_EXPECTED_USER_DIR" \
	> "$LOG_DIR/user_dir_mismatch.log" 2>&1
NEGATIVE_RC=$?
set -e
cat "$LOG_DIR/user_dir_mismatch.log"
[[ "$NEGATIVE_RC" -ne 0 ]] || fail "user-data mismatch smoke unexpectedly succeeded"
grep -q 'EXPORT_LAUNCH_PREFLIGHT_FAILED' "$LOG_DIR/user_dir_mismatch.log" || fail "user-data mismatch did not fail in preflight"
if [[ -d "$NEGATIVE_ACTUAL_USER_DIR" ]] && find "$NEGATIVE_ACTUAL_USER_DIR" -type f \( \
	-name 'namespace_migration_v1.json' -o -name 'namespace_migration_v1.json.tmp' -o \
	-name 'tsuri_quest_save.json' -o -name 'tsuri_quest_save.json.bak' -o \
	-name 'tsuri_quest_save.json.tmp' -o -name '*.namespace_migration.tmp' \
\) -print -quit | grep -q .; then
	fail "user-data mismatch wrote a migration/save artifact"
fi

# preflight負ケース: unknown phaseもPlayerProgress起動前に拒否する。
rm -rf "$NEGATIVE_HOME"
mkdir -p "$NEGATIVE_HOME"
set +e
HOME="$NEGATIVE_HOME" "$EXECUTABLE" --headless -- \
	--tsuri-export-smoke=unknown "--tsuri-expected-user-dir=$NEGATIVE_ACTUAL_USER_DIR" \
	> "$LOG_DIR/unknown_phase.log" 2>&1
UNKNOWN_RC=$?
set -e
cat "$LOG_DIR/unknown_phase.log"
[[ "$UNKNOWN_RC" -ne 0 ]] || fail "unknown phase smoke unexpectedly succeeded"
grep -q 'EXPORT_LAUNCH_PREFLIGHT_FAILED: phase=unknown' "$LOG_DIR/unknown_phase.log" || fail "unknown phase did not fail in preflight"
if [[ -d "$NEGATIVE_ACTUAL_USER_DIR" ]] && find "$NEGATIVE_ACTUAL_USER_DIR" -type f \( \
	-name 'namespace_migration_v1.json' -o -name 'namespace_migration_v1.json.tmp' -o \
	-name 'tsuri_quest_save.json' -o -name 'tsuri_quest_save.json.bak' -o \
	-name 'tsuri_quest_save.json.tmp' -o -name '*.namespace_migration.tmp' \
\) -print -quit | grep -q .; then
	fail "unknown phase wrote a migration/save artifact"
fi

rm -rf "$FIXTURE_HOME"
mkdir -p "$FIXTURE_HOME"
EXPECTED_USER_DIR="$FIXTURE_HOME/Library/Application Support/tsuri_quest_umi"
run_smoke() {
	local phase="$1"
	local log_path="$2"
	HOME="$FIXTURE_HOME" "$EXECUTABLE" --headless -- \
		"--tsuri-export-smoke=$phase" "--tsuri-expected-user-dir=$EXPECTED_USER_DIR" 2>&1 | tee "$log_path"
	grep -q "EXPORT_LAUNCH_SMOKE_OK phase=$phase title=ready" "$log_path" || fail "$phase smoke did not complete"
	if grep -a 'ERROR:' "$log_path" | grep -a -v 'ERROR: 1 resources still in use at exit' >/dev/null; then
		fail "$phase smoke emitted an unexplained ERROR"
	fi
}
run_smoke create "$LOG_DIR/clean_create.log"
run_smoke reload "$LOG_DIR/clean_reload.log"

rm -rf "$FIXTURE_HOME"
LEGACY_ROOT="$FIXTURE_HOME/Library/Application Support/Godot/app_userdata/釣りクエスト ～海釣り編～ MVP"
LEGACY_SAVE="$LEGACY_ROOT/tsuri_quest_save.json"
mkdir -p "$LEGACY_ROOT"
printf '{"version":1,"money":731}\n' > "$LEGACY_SAVE"
LEGACY_HASH_BEFORE="$(shasum -a 256 "$LEGACY_SAVE" | awk '{print $1}')"
EXPECTED_USER_DIR="$FIXTURE_HOME/Library/Application Support/tsuri_quest_umi"
run_smoke migration "$LOG_DIR/migration.log"
LEGACY_HASH_AFTER="$(shasum -a 256 "$LEGACY_SAVE" | awk '{print $1}')"
[[ "$LEGACY_HASH_BEFORE" == "$LEGACY_HASH_AFTER" ]] || fail "legacy save was modified"

echo "Godot: $GODOT_VERSION"
echo "Template: $TEMPLATE_VERSION ($TEMPLATE_ROOT/macos.zip)"
echo "Source object: $SOURCE_OBJECT"
echo "Source commit: $SOURCE_COMMIT"
echo "Artifact hashes: $ARTIFACT_LOG"
cat "$ARTIFACT_LOG"
echo "Release pack manifest: $RELEASE_PACK_MANIFEST ($RELEASE_PACK_MANIFEST_COUNT entries)"
echo "Debug app: $DEBUG_APP"
echo "Release app: $RELEASE_APP"
echo "export_launch_verify: PASS"
