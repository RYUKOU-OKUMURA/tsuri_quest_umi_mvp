#!/usr/bin/env python3
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))
from release_verify import atomic_json, classify, create_run_home, discover, load_manifest, main, normalize_output, run, unexplained_errors, validate_export_run_log, warning_summary


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
    assert classify(["tools/a_smoke.gd"], load_manifest(manifest)) == [("tools/a_smoke.gd", "direct_script")]
    assert classify(["tools/a_smoke.tscn"], {"tools/a_smoke.tscn": "direct_scene"}) == [("tools/a_smoke.tscn", "direct_scene")]
    must_fail("未登録target", lambda: classify(["tools/a_smoke.tscn", "tools/new_audit.gd"], {"tools/a_smoke.tscn": "direct_scene"}))
    must_fail("0件", lambda: classify([], {}))
    manifest.write_text("tools/a_smoke.gd|direct_script\ntools/a_smoke.gd|direct_script\n", encoding="utf-8")
    must_fail("重複", lambda: load_manifest(manifest))
    manifest.write_text("tools/a_smoke.gd|direct_scene\n", encoding="utf-8")
    must_fail("runner不一致", lambda: classify(["tools/a_smoke.gd"], load_manifest(manifest)))

    assert normalize_output(b"partial\xff") == "partial�"
    assert unexplained_errors("ERROR: forced\n") == ["ERROR: forced"]
    assert unexplained_errors("ERROR: Parse JSON failed. Error at line 0: Expected key\n", "save_system") == []
    assert unexplained_errors("ERROR: Parse JSON failed. Error at line 0: Expected key\n", "direct_script") != []

    marker = root / "orphan_marker"
    timeout_log = root / "timeout.log"
    command = ["sh", "-c", f"(sleep 1; touch '{marker}') & printf '\\377'; wait"]
    result = run(command, root, {**os.environ, "TSURI_RELEASE_TEST_TIMEOUT_SECONDS": "0.1", "TSURI_RELEASE_TERM_GRACE_SECONDS": "0.1"}, timeout_log)
    assert result["exit_code"] == 124 and result["timed_out"] and timeout_log.is_file()
    assert timeout_log.read_text(encoding="utf-8").count("�") == 1
    time.sleep(1.2)
    assert not marker.exists(), "timeout後にorphan子processがmarkerを書きました"
    warning_result = run(["sh", "-c", "echo 'WARNING: sample'; echo 'WARNING: sample'"], root, os.environ.copy(), root / "warning.log")
    assert warning_result["warnings"] == {"count": 2, "distinct_samples": ["WARNING: sample"], "unexplained": ["WARNING: sample", "WARNING: sample"]}
    assert warning_summary("WARNING: unknown\n", "direct_scene")["unexplained"] == ["WARNING: unknown"]
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
    (tools / "save_namespace_migration_smoke.tscn").touch()
    (tools / "save_system_smoke.tscn").touch()
    (tools / "release_test_manifest.txt").write_text(
        "tools/only_audit.gd|direct_script\n"
        "tools/save_namespace_migration_smoke.tscn|save_system\n"
        "tools/save_system_smoke.tscn|save_system\n"
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
    assert rc == 1 and report["status"] == "failed" and direct["timed_out"] and not report["source"]["stable"], repr(report)
    assert report["source"]["start"]["porcelain_sha256"] == report["source"]["end"]["porcelain_sha256"]
    assert report["source"]["start"]["worktree_content_sha256"] != report["source"]["end"]["worktree_content_sha256"]
    assert report["godot"] == {"version": "4.7.test.official.fixture", "binary": str(fake_godot)}
    assert report["validation"]["status"] == "passed" and save_execution["status"] == "passed", repr(report)
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
    (tools / "release_test_manifest.txt").write_text("tools/cleanup_audit.gd|direct_script\n")
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

print("release_verify self-test: ok (列挙/process-group/atomic report/HOME/engine/warning)")
