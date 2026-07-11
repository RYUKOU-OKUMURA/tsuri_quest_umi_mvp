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
from release_verify import REQUIRED_SPECIAL, TEST_TIMEOUT_OVERRIDES, atomic_json, classify, create_run_home, discover, load_manifest, main, normalize_output, prepare_output_root, prepare_run_logs, run, sha256, timeout_budget, unexplained_errors, validate_export_run_log, warning_summary


def must_fail(label, callback):
    try:
        callback()
    except ValueError:
        return
    raise AssertionError(f"負ケースが成功しました: {label}")


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

# end-to-end: validate/save wrapperも同一GODOT_BINを使い、隔離・source変化・timeout失敗を固定する。
with tempfile.TemporaryDirectory() as temporary, tempfile.TemporaryDirectory() as output_temporary:
    fixture = Path(temporary)
    tools = fixture / "tools"
    tools.mkdir()
    (tools / "only_audit.gd").write_text("extends SceneTree\n")
    (tools / "nushi_encounter_audit.tscn").touch()
    (tools / "save_namespace_migration_smoke.tscn").touch()
    (tools / "save_system_smoke.tscn").touch()
    (tools / "export_launch_smoke.tscn").touch()
    (tools / "release_test_manifest.txt").write_text(
        "tools/only_audit.gd|direct_script\n"
        "tools/nushi_encounter_audit.tscn|direct_scene\n"
        "tools/save_namespace_migration_smoke.tscn|save_system\n"
        "tools/save_system_smoke.tscn|save_system\n"
        "tools/export_launch_smoke.tscn|export_evidence\n"
    )
    outside = Path(output_temporary)
    engine_marker = outside / "engine_marker"
    orphan_marker = outside / "e2e_orphan"
    outside_marker = outside / "outside_marker"
    outside_marker.write_text("keep")
    mutation = fixture / "mutation_during_run"
    mutation.write_text("base\n")
    fake_godot = fixture / "fake_godot"
    fake_godot.write_text(
        "#!/bin/sh\n"
        f"echo fake-engine >> '{engine_marker}'\n"
        "if [ \"${1:-}\" = --version ]; then echo 4.7.test.official.fixture; exit 0; fi\n"
        f"if echo \" $* \" | grep -q ' --script '; then echo dirty-after > '{mutation}'; (sleep 1; touch '{orphan_marker}') & wait; fi\n"
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
    os.environ.update(GODOT_BIN=str(fake_godot), TSURI_RELEASE_TEST_TIMEOUT_SECONDS="0.5", TSURI_RELEASE_TERM_GRACE_SECONDS="0.1")
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
    assert rc == 1 and report["status"] == "failed" and direct["timed_out"] and not report["source"]["stable"], repr(report)
    assert report["source"]["start"]["porcelain_sha256"] == report["source"]["end"]["porcelain_sha256"]
    assert report["source"]["start"]["worktree_content_sha256"] != report["source"]["end"]["worktree_content_sha256"]
    assert report["godot"] == {"version": "4.7.test.official.fixture", "binary": str(fake_godot.resolve())}
    assert report["validation"]["status"] == "passed" and save_execution["status"] == "passed", repr(report)
    assert direct["timeout_seconds"] == 0.5 and direct["duration_seconds"] >= 0 and export_pending["status"] == "pending_rc_evidence"
    assert nushi_budget_record["timeout_seconds"] == 0.5  # 明示global overrideはnushi個別defaultより優先
    engine_count = engine_marker.read_text().count("fake-engine")
    assert engine_count >= 3, f"同一engine呼び出し数が不正: {engine_count}"
    assert outside_marker.read_text() == "keep"
    time.sleep(1.2)
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
    evidence = Path(evidence_temporary)
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
    debug_pck, release_pck, pack_manifest = evidence / "debug.pck", evidence / "release.pck", evidence / "pack.txt"
    for path, value in ((debug_pck, b"debug"), (release_pck, b"release"), (pack_manifest, b"manifest")):
        path.write_bytes(value)
    (tools / "save_system_verify.sh").write_text(f"#!/bin/sh\nprintf changed >> '{release_pck}'\n")
    (tools / "save_system_verify.sh").chmod(0o755)
    subprocess.run(["git", "init", "-q"], cwd=fixture, check=True)
    subprocess.run(["git", "add", "."], cwd=fixture, check=True)
    subprocess.run(["git", "-c", "user.name=fixture", "-c", "user.email=fixture@example.invalid", "commit", "-qm", "fixture"], cwd=fixture, check=True)
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=fixture, text=True).strip()
    tree = subprocess.check_output(["git", "rev-parse", "HEAD^{tree}"], cwd=fixture, text=True).strip()
    artifact_log = evidence / "artifacts.sha256"
    artifact_log.write_text(
        f"source_commit={commit}\nsource_tree={tree}\ndebug_pck={debug_pck}\ndebug_pck_sha256={sha256(debug_pck)}\n"
        f"release_pck={release_pck}\nrelease_pck_sha256={sha256(release_pck)}\nrelease_pack_manifest={pack_manifest}\n"
        f"release_pack_manifest_sha256={sha256(pack_manifest)}\n"
    )
    template_home = evidence / "home"
    template = template_home / "Library/Application Support/Godot/export_templates/4.7.rc/macos.zip"
    template.parent.mkdir(parents=True)
    template.write_bytes(b"template")
    run_log = evidence / "export.log"
    run_log.write_text(f"Godot: 4.7.rc.official.fixture\nTemplate: 4.7.rc ({template})\nArtifact hashes: {artifact_log.resolve()}\nexport_launch_verify: PASS\n")
    old_env = os.environ.copy()
    os.environ.update(GODOT_BIN=str(fake), TSURI_EXPORT_ARTIFACT_LOG=str(artifact_log), TSURI_EXPORT_VERIFY_LOG=str(run_log))
    try:
        with mock.patch("release_verify.Path.home", return_value=template_home):
            rc = main(["--root", str(fixture), "--output-dir", str(evidence / "out"), "--rc"])
    finally:
        os.environ.clear(); os.environ.update(old_env)
    swapped_report = json.loads((evidence / "out/release_verify_report.json").read_text())
    assert rc == 1 and swapped_report["status"] == "failed" and "export成果物hash不一致" in swapped_report["error"]

print("release_verify self-test: ok (列挙/process-group/atomic report/HOME/engine/warning)")
