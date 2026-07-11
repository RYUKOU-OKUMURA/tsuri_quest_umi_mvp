#!/usr/bin/env python3
import tempfile
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
from release_verify import classify, discover, load_manifest, run, unexplained_errors, validate_export_run_log


def must_fail(label, callback):
    try:
        callback()
    except ValueError:
        return
    raise AssertionError(f"負ケースが成功しました: {label}")


with tempfile.TemporaryDirectory() as temporary:
    root = Path(temporary)
    (root / "tools/sub").mkdir(parents=True)
    (root / "tools/z_smoke.tscn").touch()
    (root / "tools/sub/a_audit.tscn").touch()
    (root / "tools/sub/ignored.tscn").touch()
    assert discover(root) == ["tools/sub/a_audit.tscn", "tools/z_smoke.tscn"]
    manifest = root / "manifest.txt"
    manifest.write_text("tools/a_smoke.tscn|direct\n", encoding="utf-8")
    assert classify(["tools/a_smoke.tscn"], load_manifest(manifest)) == [("tools/a_smoke.tscn", "direct")]
    assert classify(["tools/b_audit.tscn", "tools/a_smoke.tscn"], {}) == [("tools/b_audit.tscn", "direct"), ("tools/a_smoke.tscn", "direct")]
    must_fail("0件", lambda: classify([], {}))
    manifest.write_text("tools/a_smoke.tscn|direct\ntools/a_smoke.tscn|direct\n", encoding="utf-8")
    must_fail("重複", lambda: load_manifest(manifest))
    manifest.write_text("tools/missing_smoke.tscn|direct\n", encoding="utf-8")
    must_fail("存在しないpath", lambda: classify(["tools/a_smoke.tscn"], load_manifest(manifest)))
    manifest.write_text("tools/export_launch_smoke.tscn|direct\n", encoding="utf-8")
    must_fail("特殊scene直接実行", lambda: classify(["tools/export_launch_smoke.tscn"], load_manifest(manifest)))
    must_fail("失敗", lambda: (_ for _ in ()).throw(ValueError("forced command failure")))
    assert unexplained_errors("ERROR: forced\n") == ["ERROR: forced"]
    assert unexplained_errors("ERROR: 1 resources still in use at exit (run with --verbose for details).\n") == []
    assert unexplained_errors("ERROR: Parse JSON failed. Error at line 0: Expected key\n", "save_system") == []
    assert unexplained_errors("ERROR: Parse JSON failed. Error at line 0: Expected key\n", "direct") != []
    process_log = root / "process.log"
    rc, errors = run(["sh", "-c", "echo 'ERROR: forced'; exit 7"], root, {}, process_log)
    assert rc == 7 and errors == ["ERROR: forced"] and process_log.is_file()
    timeout_log = root / "timeout.log"
    rc, errors = run(["sh", "-c", "sleep 2"], root, {"TSURI_RELEASE_TEST_TIMEOUT_SECONDS": "1"}, timeout_log)
    assert rc == 124 and not errors and "timeout after 1s" in timeout_log.read_text(encoding="utf-8")
    artifact_log = root / "artifacts.sha256"
    artifact_log.write_text("fixture\n", encoding="utf-8")
    template = root / "macos.zip"
    template.write_bytes(b"template")
    export_log = root / "export.log"
    export_log.write_text(
        f"ERROR: forced\nGodot: 4.7\nTemplate: 4.7 ({template})\nArtifact hashes: {artifact_log}\nexport_launch_verify: PASS\n",
        encoding="utf-8",
    )
    must_fail("export未説明ERROR", lambda: validate_export_run_log(export_log, artifact_log, "4.7", "4.7", template))

print("release_verify self-test: ok (0件/重複/失敗/未説明ERROR)")
