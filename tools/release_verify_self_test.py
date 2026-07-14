#!/usr/bin/env python3
import json
import os
from pathlib import Path
import subprocess
import shutil
import sys
import tempfile
import time
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))
from app_bundle_manifest import bundle_manifest_snapshot, write_bundle_manifest
from release_verify import REQUIRED_SPECIAL, TEST_TIMEOUT_OVERRIDES, atomic_json, classify, create_run_home, discover, load_manifest, main, normalize_output, parse_export_evidence, prepare_output_root, prepare_run_logs, preserve_python_user_base, run, sha256, timeout_budget, unexplained_errors, validate_export_run_log, warning_summary


def must_fail(label, callback):
    try:
        callback()
    except ValueError:
        return
    raise AssertionError(f"負ケースが成功しました: {label}")


def create_fixture_app(app: Path, label: str) -> tuple[Path, Path, Path]:
    executable = app / "Contents/MacOS/game"
    info_plist = app / "Contents/Info.plist"
    pck = app / "Contents/Resources/game.pck"
    executable.parent.mkdir(parents=True)
    pck.parent.mkdir(parents=True)
    executable.write_bytes(f"{label}-binary".encode())
    executable.chmod(0o755)
    info_plist.write_bytes(f"{label}-plist".encode())
    pck.write_bytes(f"{label}-pck".encode())
    return executable, info_plist, pck


def write_export_evidence(
    artifact_log: Path,
    source_commit: str,
    source_tree: str,
    debug_app: Path,
    release_app: Path,
    pack_manifest: Path,
) -> dict[str, object]:
    debug_manifest = artifact_log.parent / "debug_app_bundle_manifest.jsonl"
    release_manifest = artifact_log.parent / "release_app_bundle_manifest.jsonl"
    debug_result = write_bundle_manifest(debug_app, debug_manifest)
    release_result = write_bundle_manifest(release_app, release_manifest)
    debug_pck = debug_app / "Contents/Resources/game.pck"
    release_pck = release_app / "Contents/Resources/game.pck"
    artifact_log.write_text(
        f"source_commit={source_commit}\n"
        f"source_tree={source_tree}\n"
        f"debug_pck={debug_pck}\n"
        f"debug_pck_sha256={sha256(debug_pck)}\n"
        f"release_pck={release_pck}\n"
        f"release_pck_sha256={sha256(release_pck)}\n"
        f"release_pack_manifest={pack_manifest}\n"
        f"release_pack_manifest_count={len(pack_manifest.read_text().splitlines())}\n"
        f"release_pack_manifest_sha256={sha256(pack_manifest)}\n"
        f"debug_app={debug_app}\n"
        f"debug_app_manifest={debug_manifest}\n"
        f"debug_app_manifest_count={debug_result['count']}\n"
        f"debug_app_manifest_sha256={debug_result['sha256']}\n"
        f"release_app={release_app}\n"
        f"release_app_manifest={release_manifest}\n"
        f"release_app_manifest_count={release_result['count']}\n"
        f"release_app_manifest_sha256={release_result['sha256']}\n"
    )
    return {
        "debug_manifest": debug_manifest,
        "release_manifest": release_manifest,
        "debug_result": debug_result,
        "release_result": release_result,
    }


with tempfile.TemporaryDirectory() as temporary:
    root = Path(temporary)
    (root / "tools/sub").mkdir(parents=True)
    for relative in ("tools/z_smoke.tscn", "tools/z_smoke.gd", "tools/sub/a_audit.gd", "tools/sub/b_audit.tscn", "tools/sub/b_audit.gd", "tools/sub/ignored.gd"):
        (root / relative).touch()
    external_script = root / "external_audit.gd"
    external_script.touch()
    (root / "tools/symlink_audit.gd").symlink_to(external_script)
    # sceneと同stemのgdは重複除外し、sceneを持たない--script監査は完全列挙する。
    assert discover(root) == ["tools/sub/a_audit.gd", "tools/sub/b_audit.tscn", "tools/z_smoke.tscn"]
    manifest = root / "manifest.txt"
    manifest.write_text("tools/a_smoke.gd|direct_script\n", encoding="utf-8")
    special_tests = sorted(REQUIRED_SPECIAL)
    special_manifest = dict(REQUIRED_SPECIAL)
    tests = sorted(special_tests + ["tools/a_smoke.gd"])
    manifest.write_text("\n".join(f"{test}|{runner}" for test, runner in (special_manifest | {"tools/a_smoke.gd": "direct_script"}).items()) + "\n")
    assert dict(classify(tests, load_manifest(manifest)))["tools/a_smoke.gd"] == "direct_script"
    other_settings = "tools/other_settings_smoke.tscn"
    (root / other_settings).touch()
    must_fail(
        "settings runner排他",
        lambda: classify(sorted(tests + [other_settings]), special_manifest | {"tools/a_smoke.gd": "direct_script", other_settings: "settings_smoke"}),
    )
    must_fail("特殊同時削除", lambda: classify(["tools/a_smoke.gd"], {"tools/a_smoke.gd": "direct_script"}))
    must_fail("未登録target", lambda: classify(sorted(tests + ["tools/new_audit.gd"]), special_manifest | {"tools/a_smoke.gd": "direct_script"}))
    must_fail("0件", lambda: classify([], {}))
    manifest.write_text("tools/a_smoke.gd|direct_script\ntools/a_smoke.gd|direct_script\n", encoding="utf-8")
    must_fail("重複", lambda: load_manifest(manifest))
    manifest.write_text("tools/a_smoke.gd|direct_scene\n", encoding="utf-8")
    must_fail("runner不一致", lambda: classify(["tools/a_smoke.gd"], load_manifest(manifest)))
    manifest_link = root / "manifest_link.txt"
    manifest_link.symlink_to(manifest)
    must_fail("manifest symlink", lambda: load_manifest(manifest_link))
    assert TEST_TIMEOUT_OVERRIDES["tools/nushi_encounter_audit.tscn"] == 1800.0
    assert timeout_budget("tools/nushi_encounter_audit.tscn", {}) == 1800.0
    assert timeout_budget("tools/nushi_encounter_audit.tscn", {"TSURI_RELEASE_TEST_TIMEOUT_SECONDS": "12"}) == 12.0

    assert normalize_output(b"partial\xff") == "partial�"
    assert unexplained_errors("ERROR: forced\n") == ["ERROR: forced"]
    assert unexplained_errors("ERROR: Parse JSON failed. Error at line 0: Expected key\n", "save_system") == []
    assert unexplained_errors("ERROR: Parse JSON failed. Error at line 0: Expected key\n", "direct_script") != []
    vector_warning = "WARNING: Vector2 cannot be normalized, the elements must be finite. Making (0, 0) as a fallback.\n"
    assert warning_summary(vector_warning, "save_system")["unexplained"]
    delete_failure_warning = "WARNING: セーブデータを削除できませんでした（コード: 20）。"
    assert not warning_summary(f"{delete_failure_warning}\n", "save_system")["unexplained"]
    assert warning_summary(f"{delete_failure_warning}\n", "direct_scene")["unexplained"] == [delete_failure_warning]
    assert not warning_summary(f"{delete_failure_warning}\n", "settings_smoke")["unexplained"]
    similar_delete_warning = "WARNING: セーブデータを削除できませんでした（コード: 21）。"
    assert warning_summary(f"{similar_delete_warning}\n", "save_system")["unexplained"] == [similar_delete_warning]
    assert warning_summary(f"{similar_delete_warning}\n", "direct_scene")["unexplained"] == [similar_delete_warning]
    assert warning_summary(f"{similar_delete_warning}\n", "settings_smoke")["unexplained"] == [similar_delete_warning]
    for context in ("validation", "save_system", "export"):
        assert not warning_summary("WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).\n", context)["unexplained"]
    for count in (2, 3):
        assert not warning_summary(f"WARNING: {count} ObjectDB instances were leaked at exit (run with `--verbose` for details).\n", "direct_scene")["unexplained"]
    for count in (4, 999):
        assert warning_summary(f"WARNING: {count} ObjectDB instances were leaked at exit (run with `--verbose` for details).\n", "direct_scene")["unexplained"]

    marker = root / "orphan_marker"
    timeout_log = root / "timeout.log"
    command = ["sh", "-c", f"(sleep 1; touch '{marker}') & printf '\\377'; wait"]
    result = run(command, root, {**os.environ, "TSURI_RELEASE_TEST_TIMEOUT_SECONDS": "0.1", "TSURI_RELEASE_TERM_GRACE_SECONDS": "0.1"}, timeout_log)
    assert result["exit_code"] == 124 and result["timed_out"] and timeout_log.is_file()
    assert result["duration_seconds"] >= 0.1
    assert timeout_log.read_text(encoding="utf-8").count("�") == 1
    time.sleep(1.2)
    assert not marker.exists(), "timeout後にorphan子processがmarkerを書きました"
    warning_result = run(["sh", "-c", "echo 'WARNING: sample'; echo 'WARNING: sample'"], root, os.environ.copy(), root / "warning.log")
    assert warning_result["warnings"] == {"count": 2, "distinct_samples": ["WARNING: sample"], "unexplained": ["WARNING: sample", "WARNING: sample"]}
    assert warning_summary("WARNING: unknown\n", "direct_scene")["unexplained"] == ["WARNING: unknown"]
    assert warning_summary("WARNING: 999 ObjectDB instances were leaked at exit (run with `--verbose` for details).\n", "direct_scene")["unexplained"]
    with mock.patch("release_verify.os.killpg", side_effect=ProcessLookupError):
        raced = run(["sh", "-c", "sleep 0.05"], root, {**os.environ, "TSURI_RELEASE_TEST_TIMEOUT_SECONDS": "0.01", "TSURI_RELEASE_TERM_GRACE_SECONDS": "0.2"}, root / "race.log")
    assert raced["exit_code"] == 124 and raced["timed_out"]

    old_report = root / "report.json"
    atomic_json(old_report, {"status": "passed"})
    atomic_json(old_report, {"status": "failed", "error": "current run"})
    assert json.loads(old_report.read_text())["status"] == "failed"

    external = root / "external"
    external.mkdir()
    outside_marker = external / "marker"
    outside_marker.write_text("keep")
    symlink_parent = root / "linked_parent"
    symlink_parent.symlink_to(external, target_is_directory=True)
    must_fail("symlink HOME親", lambda: create_run_home(symlink_parent))
    fresh = create_run_home(external)
    assert fresh.parent == external.resolve() and not fresh.is_symlink()
    fresh.rmdir()
    assert outside_marker.read_text() == "keep"

    # Godot用HOMEを差し替えても、起動元Pythonのユーザー依存はPYTHONUSERBASEで維持する。
    python_user_base = root / "python_user_base"
    python_user_site = Path(subprocess.check_output(
        [sys.executable, "-c", "import site; print(site.getusersitepackages())"],
        env={**os.environ, "PYTHONUSERBASE": str(python_user_base)},
        text=True,
    ).strip())
    python_user_site.mkdir(parents=True)
    (python_user_site / "release_fixture_dependency.py").write_text("VALUE = 7\n")
    isolated_python_home = root / "isolated_python_home"
    isolated_python_home.mkdir()
    python_env = preserve_python_user_base(os.environ.copy(), str(python_user_base))
    assert python_env["PYTHONUSERBASE"] == str(python_user_base.resolve())
    explicit_user_base = root / "explicit_user_base"
    assert preserve_python_user_base({"PYTHONUSERBASE": str(explicit_user_base)}, str(python_user_base))["PYTHONUSERBASE"] == str(explicit_user_base)
    python_probe = run(
        [sys.executable, "-c", "import os, release_fixture_dependency; assert release_fixture_dependency.VALUE == 7 and os.environ['HOME'].endswith('isolated_python_home')"],
        root,
        python_env | {"HOME": str(isolated_python_home)},
        root / "python_user_site.log",
    )
    assert python_probe["exit_code"] == 0, python_probe
    logs_target = root / "outside_logs"
    logs_target.mkdir()
    logs_marker = logs_target / "marker"
    logs_marker.write_text("keep")
    unsafe_output = root / "unsafe_output"
    unsafe_output.mkdir()
    (unsafe_output / "logs").symlink_to(logs_target, target_is_directory=True)
    safe_unsafe_output = prepare_output_root(unsafe_output)
    must_fail("logs symlink", lambda: prepare_run_logs(safe_unsafe_output))
    assert logs_marker.read_text() == "keep"
    safe_output = root / "safe_output"
    safe_output = prepare_output_root(safe_output)
    first_logs = prepare_run_logs(safe_output)
    (first_logs / "old.log").write_text("old")
    second_logs = prepare_run_logs(safe_output)
    assert first_logs != second_logs and not (second_logs / "old.log").exists()

    # 旧PASSがあってもlogs symlink拒否は今回failedへ原子的に更新し、外部を触らない。
    old_pass_output = Path(tempfile.mkdtemp(prefix="release_old_pass_"))
    atomic_json(old_pass_output / "release_verify_report.json", {"status": "skeleton_passed"})
    old_logs_target = root / "old_logs_target"
    old_logs_target.mkdir()
    old_logs_marker = old_logs_target / "marker"
    old_logs_marker.write_text("keep")
    (old_pass_output / "logs").symlink_to(old_logs_target, target_is_directory=True)
    assert main(["--root", str(root), "--manifest", str(root / "manifest.txt"), "--output-dir", str(old_pass_output)]) == 1
    assert json.loads((old_pass_output / "release_verify_report.json").read_text())["status"] == "failed"
    assert old_logs_marker.read_text() == "keep"
    shutil.rmtree(old_pass_output)
    ignored_output = root / "ignored_output"
    must_fail("repo内output", lambda: main(["--root", str(root), "--output-dir", str(ignored_output)]))
    assert not ignored_output.exists()
    ancestor_target = root / "ancestor_target"
    ancestor_target.mkdir()
    ancestor_marker = ancestor_target / "marker"
    ancestor_marker.write_text("keep")
    ancestor_link = root / "ancestor_link"
    ancestor_link.symlink_to(ancestor_target, target_is_directory=True)
    must_fail("output祖先symlink", lambda: prepare_output_root(ancestor_link / "release"))
    assert ancestor_marker.read_text() == "keep" and not (ancestor_target / "release").exists()

    artifact_log = root / "artifacts.sha256"
    artifact_log.write_text("fixture\n")
    template = root / "macos.zip"
    template.write_bytes(b"template")
    export_log = root / "export.log"
    export_log.write_text(f"ERROR: forced\nGodot: 4.7\nTemplate: 4.7 ({template})\nArtifact hashes: {artifact_log}\nexport_launch_verify: PASS\n")
    must_fail("export未説明ERROR", lambda: validate_export_run_log(export_log, artifact_log, "4.7", "4.7", template))
    export_log.write_text(f"WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details).\nGodot: 4.7\nTemplate: 4.7 ({template})\nArtifact hashes: {artifact_log}\nexport_launch_verify: PASS\n")
    assert validate_export_run_log(export_log, artifact_log, "4.7", "4.7", template)["warnings"]["unexplained"] == []
    export_log.write_text(f"WARNING: unknown\nGodot: 4.7\nTemplate: 4.7 ({template})\nArtifact hashes: {artifact_log}\nexport_launch_verify: PASS\n")
    must_fail("export未知WARNING", lambda: validate_export_run_log(export_log, artifact_log, "4.7", "4.7", template))

# app bundle evidenceはcanonical treeとlive treeを一致させ、外部symlinkを追跡しない。
with tempfile.TemporaryDirectory() as temporary:
    evidence = Path(temporary).resolve()
    debug_app = evidence / "Debug.app"
    release_app = evidence / "Release.app"
    debug_executable, debug_info, _debug_pck = create_fixture_app(debug_app, "debug")
    create_fixture_app(release_app, "release")
    external_target = evidence / "external_target"
    external_target.write_bytes(b"outside-v1")
    external_link = debug_app / "Contents/Frameworks/External"
    external_link.parent.mkdir()
    external_link.symlink_to(external_target)
    pack_manifest = evidence / "pack.txt"
    pack_manifest.write_text("res://main.tscn\n")
    artifact_log = evidence / "artifacts.sha256"
    bundle_evidence = write_export_evidence(
        artifact_log,
        "a" * 40,
        "b" * 40,
        debug_app,
        release_app,
        pack_manifest,
    )
    parsed = parse_export_evidence(artifact_log)
    assert parsed["status"] == "consumed"
    debug_manifest = Path(bundle_evidence["debug_manifest"])
    manifest_entries = [json.loads(line) for line in debug_manifest.read_text().splitlines()]
    manifest_paths = [entry["path"] for entry in manifest_entries]
    assert manifest_paths == sorted(manifest_paths) and manifest_paths[0] == "."
    assert {entry["type"] for entry in manifest_entries} == {"directory", "file", "symlink"}
    link_entry = next(entry for entry in manifest_entries if entry["path"] == "Contents/Frameworks/External")
    assert link_entry["target"] == str(external_target)

    atomic_probe = evidence / "atomic_probe.jsonl"
    write_bundle_manifest(debug_app, atomic_probe)
    atomic_probe_before = atomic_probe.read_bytes()
    with mock.patch("app_bundle_manifest.os.replace", side_effect=OSError("replace failed")):
        try:
            write_bundle_manifest(debug_app, atomic_probe)
        except OSError:
            pass
        else:
            raise AssertionError("負ケースが成功しました: manifest atomic replace")
    assert atomic_probe.read_bytes() == atomic_probe_before
    assert not list(evidence.glob(f".{atomic_probe.name}.*"))

    app_root_link = evidence / "DebugLink.app"
    app_root_link.symlink_to(debug_app, target_is_directory=True)
    must_fail("app root symlink", lambda: bundle_manifest_snapshot(app_root_link))
    linked_parent = evidence / "linked_parent"
    linked_parent.symlink_to(evidence, target_is_directory=True)
    must_fail("app ancestor symlink", lambda: bundle_manifest_snapshot(linked_parent / debug_app.name))
    must_fail(
        "manifest inside app",
        lambda: write_bundle_manifest(debug_app, debug_app / "Contents/manifest.jsonl"),
    )

    # target file自体はbundle外なので、内容変更してもmanifest/live検証へ影響しない。
    external_target.write_bytes(b"outside-v2")
    assert parse_export_evidence(artifact_log)["status"] == "consumed"

    debug_binary = debug_executable.read_bytes()
    debug_binary_mode = debug_executable.stat().st_mode & 0o777
    debug_plist = debug_info.read_bytes()
    debug_plist_mode = debug_info.stat().st_mode & 0o777
    original_link_target = os.readlink(external_link)
    original_manifest = debug_manifest.read_bytes()

    debug_executable.write_bytes(debug_binary + b"-tampered")
    must_fail("bundle binary tamper", lambda: parse_export_evidence(artifact_log))
    debug_executable.write_bytes(debug_binary)
    debug_executable.chmod(debug_binary_mode)

    debug_info.write_bytes(debug_plist + b"-tampered")
    must_fail("bundle Info.plist tamper", lambda: parse_export_evidence(artifact_log))
    debug_info.write_bytes(debug_plist)
    debug_info.chmod(debug_plist_mode)

    debug_executable.chmod(0o700)
    must_fail("bundle mode tamper", lambda: parse_export_evidence(artifact_log))
    debug_executable.chmod(debug_binary_mode)

    external_link.unlink()
    external_link.symlink_to(evidence / "different_target")
    must_fail("bundle symlink target tamper", lambda: parse_export_evidence(artifact_log))
    external_link.unlink()
    external_link.symlink_to(original_link_target)

    added = debug_app / "Contents/added.txt"
    added.write_text("added")
    must_fail("bundle added entry", lambda: parse_export_evidence(artifact_log))
    added.unlink()

    debug_info.unlink()
    must_fail("bundle deleted entry", lambda: parse_export_evidence(artifact_log))
    debug_info.write_bytes(debug_plist)
    debug_info.chmod(debug_plist_mode)

    debug_manifest.write_bytes(original_manifest + b"tampered\n")
    must_fail("bundle manifest tamper", lambda: parse_export_evidence(artifact_log))
    debug_manifest.write_bytes(original_manifest)
    assert parse_export_evidence(artifact_log)["status"] == "consumed"

    manifest_target = evidence / "manifest_target"
    manifest_target.mkdir()
    copied_manifest = manifest_target / debug_manifest.name
    copied_manifest.write_bytes(original_manifest)
    manifest_parent_link = evidence / "manifest_parent_link"
    manifest_parent_link.symlink_to(manifest_target, target_is_directory=True)
    original_artifact_log = artifact_log.read_text()
    artifact_log.write_text(
        original_artifact_log.replace(
            f"debug_app_manifest={debug_manifest}",
            f"debug_app_manifest={manifest_parent_link / debug_manifest.name}",
        )
    )
    must_fail("bundle manifest ancestor symlink", lambda: parse_export_evidence(artifact_log))
    artifact_log.write_text(original_artifact_log)
    assert parse_export_evidence(artifact_log)["status"] == "consumed"

    old_artifact_log = evidence / "old_artifacts.sha256"
    old_artifact_log.write_text(
        f"source_commit={'a' * 40}\nsource_tree={'b' * 40}\n"
        f"debug_pck={debug_app / 'Contents/Resources/game.pck'}\n"
        f"debug_pck_sha256={sha256(debug_app / 'Contents/Resources/game.pck')}\n"
        f"release_pck={release_app / 'Contents/Resources/game.pck'}\n"
        f"release_pck_sha256={sha256(release_app / 'Contents/Resources/game.pck')}\n"
        f"release_pack_manifest={pack_manifest}\nrelease_pack_manifest_sha256={sha256(pack_manifest)}\n"
    )
    must_fail("legacy export evidence", lambda: parse_export_evidence(old_artifact_log))

# end-to-end: validate/save wrapperも同一GODOT_BINを使い、隔離・source変化・timeout失敗を固定する。
with tempfile.TemporaryDirectory() as temporary, tempfile.TemporaryDirectory() as output_temporary:
    fixture = Path(temporary)
    tools = fixture / "tools"
    tools.mkdir()
    (tools / "only_audit.gd").write_text("extends SceneTree\n")
    (tools / "nushi_encounter_audit.tscn").touch()
    (tools / "save_namespace_migration_smoke.tscn").touch()
    (tools / "save_system_smoke.tscn").touch()
    (tools / "settings_smoke.tscn").touch()
    (tools / "export_launch_smoke.tscn").touch()
    (tools / "release_test_manifest.txt").write_text(
        "tools/only_audit.gd|direct_script\n"
        "tools/nushi_encounter_audit.tscn|direct_scene\n"
        "tools/save_namespace_migration_smoke.tscn|save_system\n"
        "tools/save_system_smoke.tscn|save_system\n"
        "tools/settings_smoke.tscn|settings_smoke\n"
        "tools/export_launch_smoke.tscn|export_evidence\n"
    )
    outside = Path(output_temporary)
    engine_marker = outside / "engine_marker"
    orphan_marker = outside / "e2e_orphan"
    outside_marker = outside / "outside_marker"
    env_log = outside / "env_log"
    outside_marker.write_text("keep")
    mutation = fixture / "mutation_during_run"
    mutation.write_text("base\n")
    fake_godot = fixture / "fake_godot"
    fake_godot.write_text(
        "#!/bin/sh\n"
        f"echo fake-engine >> '{engine_marker}'\n"
        f"guard=missing; [ -f \"${{HOME:-}}/.tsuri_settings_qa_guard\" ] && [ \"$(cat \"${{HOME:-}}/.tsuri_settings_qa_guard\")\" = \"${{TSURI_QA_RUN_TOKEN:-}}\" ] && guard=ok\n"
        f"printf '%s|%s|%s|%s|%s|%s|%s\\n' \"$*\" \"${{TSURI_SETTINGS_SMOKE_ALLOW:-}}\" \"${{TSURI_QA_ISOLATED_HOME:-}}\" \"${{TSURI_QA_RUN_TOKEN:-}}\" \"${{HOME:-}}\" \"$guard\" \"${{TSURI_QA_REJECT_RAW_HOME_PROBE:-}}\" >> '{env_log}'\n"
        "if [ \"${1:-}\" = --version ]; then echo 4.7.test.official.fixture; exit 0; fi\n"
        f"if echo \" $* \" | grep -q ' --script '; then echo dirty-after > '{mutation}'; (sleep 3; touch '{orphan_marker}') & wait; fi\n"
    )
    fake_godot.chmod(0o755)
    (tools / "validate_project.sh").write_text("#!/bin/sh\nset -eu\ngodot --version >/dev/null\n[ \"$HOME\" = \"$TSURI_GODOT_HOME\" ]\n")
    (tools / "validate_project.sh").chmod(0o755)
    (tools / "save_system_verify.sh").write_text("#!/bin/sh\nset -eu\n[ \"$HOME\" = \"$TSURI_GODOT_HOME\" ]\n[ ! -L \"$HOME\" ]\ngodot --save-wrapper\nrm -rf \"$TSURI_GODOT_HOME/sandbox\"\n")
    (tools / "save_system_verify.sh").chmod(0o755)
    subprocess.run(["git", "init", "-q"], cwd=fixture, check=True)
    subprocess.run(["git", "add", "."], cwd=fixture, check=True)
    subprocess.run(["git", "-c", "user.name=fixture", "-c", "user.email=fixture@example.invalid", "commit", "-qm", "fixture"], cwd=fixture, check=True)
    mutation.write_text("dirty-before\n")  # 開始/終了ともporcelainは同じ M、内容digestだけが変わる
    output = outside / "out"
    old_env = os.environ.copy()
    os.environ.update(
        GODOT_BIN=str(fake_godot),
        # 0.5秒では通常fake工程まで稀にtimeoutしたため、意図的な3秒hungだけを落とす。
        TSURI_RELEASE_TEST_TIMEOUT_SECONDS="1.5",
        TSURI_RELEASE_TERM_GRACE_SECONDS="0.1",
        TSURI_SETTINGS_SMOKE_ALLOW="caller-fake-allow",
        TSURI_QA_ISOLATED_HOME="/caller/fake/home",
        TSURI_QA_RUN_TOKEN="caller-fake-token",
        TSURI_QA_REJECT_RAW_HOME_PROBE="caller-fake-probe",
    )
    try:
        rc = main(["--root", str(fixture), "--output-dir", str(output)])
    finally:
        os.environ.clear()
        os.environ.update(old_env)
    report = json.loads((output / "release_verify_report.json").read_text())
    direct = next(item for item in report["tests"] if item["runner"] == "direct_script")
    save_execution = next(item for item in report["tests"] if item["runner"] == "save_system" and "exit_code" in item)
    export_pending = next(item for item in report["tests"] if item["runner"] == "export_evidence")
    nushi_budget_record = next(item for item in report["tests"] if item["test"] == "tools/nushi_encounter_audit.tscn")
    settings_execution = next(item for item in report["tests"] if item["runner"] == "settings_smoke")
    assert rc == 1 and report["status"] == "failed" and direct["timed_out"] and not report["source"]["stable"], repr(report)
    assert report["source"]["start"]["porcelain_sha256"] == report["source"]["end"]["porcelain_sha256"]
    assert report["source"]["start"]["worktree_content_sha256"] != report["source"]["end"]["worktree_content_sha256"]
    assert report["godot"] == {"version": "4.7.test.official.fixture", "binary": str(fake_godot.resolve())}
    assert report["validation"]["status"] == "passed" and save_execution["status"] == "passed", repr(report)
    assert settings_execution["status"] == "passed", repr(settings_execution)
    assert direct["timeout_seconds"] == 1.5 and direct["duration_seconds"] >= 0 and export_pending["status"] == "pending_rc_evidence"
    assert nushi_budget_record["timeout_seconds"] == 1.5  # 明示global overrideはnushi個別defaultより優先
    engine_count = engine_marker.read_text().count("fake-engine")
    assert engine_count >= 3, f"同一engine呼び出し数が不正: {engine_count}"
    assert outside_marker.read_text() == "keep"
    env_lines = env_log.read_text().splitlines()
    settings_env = next(line.split("|", 6) for line in env_lines if "settings_smoke.tscn" in line)
    assert settings_env[1] == "1" and settings_env[2] == settings_env[4] and Path(settings_env[2]).is_absolute()
    assert settings_env[3] and settings_env[5] == "ok" and settings_env[6] == ""
    for line in env_lines:
        if "settings_smoke.tscn" not in line:
            fields = line.split("|", 6)
            assert fields[1] == "" and fields[2] == "" and fields[3] == "" and fields[6] == "", line
    time.sleep(3.2)
    assert not orphan_marker.exists()

# cleanup failureはPASS確定前にfailed reportへ変換する。
with tempfile.TemporaryDirectory() as temporary, tempfile.TemporaryDirectory() as output_temporary:
    fixture = Path(temporary)
    tools = fixture / "tools"
    tools.mkdir()
    (tools / "cleanup_audit.gd").touch()
    for special in REQUIRED_SPECIAL:
        (fixture / special).touch()
    (tools / "release_test_manifest.txt").write_text("tools/cleanup_audit.gd|direct_script\n" + "".join(f"{test}|{runner}\n" for test, runner in REQUIRED_SPECIAL.items()))
    fake = fixture / "fake"
    fake.write_text("#!/bin/sh\nif [ \"${1:-}\" = --version ]; then echo 4.7.test.official.fixture; exit 0; fi\nparent=$(dirname \"$HOME\")\nmv \"$parent\" \"${parent}.moved\"\n")
    fake.chmod(0o755)
    (tools / "validate_project.sh").write_text("#!/bin/sh\nexit 0\n")
    (tools / "validate_project.sh").chmod(0o755)
    subprocess.run(["git", "init", "-q"], cwd=fixture, check=True)
    subprocess.run(["git", "add", "."], cwd=fixture, check=True)
    subprocess.run(["git", "-c", "user.name=fixture", "-c", "user.email=fixture@example.invalid", "commit", "-qm", "fixture"], cwd=fixture, check=True)
    old_env = os.environ.copy()
    os.environ["GODOT_BIN"] = str(fake)
    try:
        rc = main(["--root", str(fixture), "--output-dir", str(Path(output_temporary) / "out")])
    finally:
        os.environ.clear(); os.environ.update(old_env)
    cleanup_report = json.loads((Path(output_temporary) / "out/release_verify_report.json").read_text())
    assert rc == 1 and cleanup_report["status"] == "failed" and "cleanup_error" in cleanup_report

# setupのhung engineもprocess-group timeoutとatomic failed reportへ載せる。
with tempfile.TemporaryDirectory() as temporary, tempfile.TemporaryDirectory() as output_temporary:
    fixture = Path(temporary)
    tools = fixture / "tools"
    tools.mkdir()
    for special in REQUIRED_SPECIAL:
        (fixture / special).touch()
    (tools / "release_test_manifest.txt").write_text("".join(f"{test}|{runner}\n" for test, runner in REQUIRED_SPECIAL.items()))
    hung = fixture / "hung_godot"
    hung.write_text("#!/bin/sh\n(sleep 1) & wait\n")
    hung.chmod(0o755)
    (tools / "validate_project.sh").write_text("#!/bin/sh\nexit 0\n")
    (tools / "validate_project.sh").chmod(0o755)
    subprocess.run(["git", "init", "-q"], cwd=fixture, check=True)
    subprocess.run(["git", "add", "."], cwd=fixture, check=True)
    subprocess.run(["git", "-c", "user.name=fixture", "-c", "user.email=fixture@example.invalid", "commit", "-qm", "fixture"], cwd=fixture, check=True)
    old_env = os.environ.copy()
    os.environ.update(GODOT_BIN=str(hung), TSURI_RELEASE_SETUP_TIMEOUT_SECONDS="0.1", TSURI_RELEASE_TERM_GRACE_SECONDS="0.1")
    try:
        rc = main(["--root", str(fixture), "--output-dir", str(Path(output_temporary) / "out")])
    finally:
        os.environ.clear(); os.environ.update(old_env)
    hung_report = json.loads((Path(output_temporary) / "out/release_verify_report.json").read_text())
    assert rc == 1 and hung_report["status"] == "failed" and hung_report["setup"]["timed_out"]

# source外manifestをrun中に変更しても開始hashで分類し、終了不一致でfailする。
with tempfile.TemporaryDirectory() as temporary, tempfile.TemporaryDirectory() as external_temporary:
    fixture = Path(temporary)
    external = Path(external_temporary)
    tools = fixture / "tools"
    tools.mkdir()
    (tools / "mutator_audit.gd").touch()
    for special in REQUIRED_SPECIAL:
        (fixture / special).touch()
    external_manifest = external / "manifest.txt"
    manifest_lines = "tools/mutator_audit.gd|direct_script\n" + "".join(f"{test}|{runner}\n" for test, runner in REQUIRED_SPECIAL.items())
    external_manifest.write_text(manifest_lines)
    fake = fixture / "godot"
    fake.write_text(f"#!/bin/sh\nif [ \"${{1:-}}\" = --version ]; then echo 4.7.test.official.fixture; exit 0; fi\ncase \" $* \" in *' --script '*) printf '%s' '# changed\n{manifest_lines}' > '{external_manifest}' ;; esac\n")
    fake.chmod(0o755)
    (tools / "validate_project.sh").write_text("#!/bin/sh\nexit 0\n")
    (tools / "validate_project.sh").chmod(0o755)
    (tools / "save_system_verify.sh").write_text("#!/bin/sh\nexit 0\n")
    (tools / "save_system_verify.sh").chmod(0o755)
    subprocess.run(["git", "init", "-q"], cwd=fixture, check=True)
    subprocess.run(["git", "add", "."], cwd=fixture, check=True)
    subprocess.run(["git", "-c", "user.name=fixture", "-c", "user.email=fixture@example.invalid", "commit", "-qm", "fixture"], cwd=fixture, check=True)
    old_env = os.environ.copy(); os.environ["GODOT_BIN"] = str(fake)
    try:
        rc = main(["--root", str(fixture), "--manifest", str(external_manifest), "--output-dir", str(external / "out")])
    finally:
        os.environ.clear(); os.environ.update(old_env)
    changed_manifest_report = json.loads((external / "out/release_verify_report.json").read_text())
    assert rc == 1 and changed_manifest_report["status"] == "failed"
    assert changed_manifest_report["source"]["stable"] and not changed_manifest_report["discovery"]["manifest"]["stable"]

# RC成果物をrun中に差し替えると終了時再hashでfailedになる。
with tempfile.TemporaryDirectory() as temporary, tempfile.TemporaryDirectory() as evidence_temporary:
    fixture = Path(temporary)
    evidence = Path(evidence_temporary).resolve()
    tools = fixture / "tools"
    tools.mkdir()
    for special in REQUIRED_SPECIAL:
        (fixture / special).touch()
    (tools / "release_test_manifest.txt").write_text("".join(f"{test}|{runner}\n" for test, runner in REQUIRED_SPECIAL.items()))
    fake = fixture / "godot"
    fake.write_text("#!/bin/sh\nif [ \"${1:-}\" = --version ]; then echo 4.7.rc.official.fixture; fi\n")
    fake.chmod(0o755)
    (tools / "validate_project.sh").write_text("#!/bin/sh\nexit 0\n")
    (tools / "validate_project.sh").chmod(0o755)
    debug_app, release_app = evidence / "debug.app", evidence / "release.app"
    create_fixture_app(debug_app, "debug")
    release_executable, _release_info, _release_pck = create_fixture_app(release_app, "release")
    pack_manifest = evidence / "pack.txt"
    pack_manifest.write_bytes(b"manifest\n")
    (tools / "save_system_verify.sh").write_text(f"#!/bin/sh\nif [ \"${{MUTATE_RC_ARTIFACT:-0}}\" = 1 ]; then printf changed >> '{release_executable}'; fi\n")
    (tools / "save_system_verify.sh").chmod(0o755)
    subprocess.run(["git", "init", "-q"], cwd=fixture, check=True)
    subprocess.run(["git", "add", "."], cwd=fixture, check=True)
    subprocess.run(["git", "-c", "user.name=fixture", "-c", "user.email=fixture@example.invalid", "commit", "-qm", "fixture"], cwd=fixture, check=True)
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=fixture, text=True).strip()
    tree = subprocess.check_output(["git", "rev-parse", "HEAD^{tree}"], cwd=fixture, text=True).strip()
    artifact_log = evidence / "artifacts.sha256"
    write_export_evidence(artifact_log, commit, tree, debug_app, release_app, pack_manifest)
    template_home = evidence / "home"
    template = template_home / "Library/Application Support/Godot/export_templates/4.7.rc/macos.zip"
    template.parent.mkdir(parents=True)
    template.write_bytes(b"template")
    run_log = evidence / "export.log"
    export_warning = "WARNING: 2 ObjectDB instances were leaked at exit (run with `--verbose` for details)."
    run_log.write_text(f"{export_warning}\nGodot: 4.7.rc.official.fixture\nTemplate: 4.7.rc ({template})\nArtifact hashes: {artifact_log.resolve()}\nexport_launch_verify: PASS\n")
    old_env = os.environ.copy()
    os.environ.update(GODOT_BIN=str(fake), TSURI_EXPORT_ARTIFACT_LOG=str(artifact_log), TSURI_EXPORT_VERIFY_LOG=str(run_log))
    try:
        with mock.patch("release_verify.Path.home", return_value=template_home):
            positive_rc = main(["--root", str(fixture), "--output-dir", str(evidence / "positive_out"), "--rc"])
        positive_report = json.loads((evidence / "positive_out/release_verify_report.json").read_text())
        export_record = next(item for item in positive_report["tests"] if item["runner"] == "export_evidence")
        assert positive_rc == 0 and positive_report["status"] == "rc_passed"
        assert export_record["warnings"]["count"] == 1 and export_warning in export_record["warnings"]["distinct_samples"]
        assert positive_report["warnings"]["count"] == 1 and export_warning in positive_report["warnings"]["distinct_samples"]
        os.environ["MUTATE_RC_ARTIFACT"] = "1"
        with mock.patch("release_verify.Path.home", return_value=template_home):
            rc = main(["--root", str(fixture), "--output-dir", str(evidence / "out"), "--rc"])
    finally:
        os.environ.clear(); os.environ.update(old_env)
    swapped_report = json.loads((evidence / "out/release_verify_report.json").read_text())
    assert rc == 1 and swapped_report["status"] == "failed" and "export app bundle manifest不一致" in swapped_report["error"]

print("release_verify self-test: ok (列挙/process-group/atomic report/HOME/engine/warning)")
