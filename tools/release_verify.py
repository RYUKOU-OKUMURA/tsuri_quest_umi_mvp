#!/usr/bin/env python3
"""QA-RELEASE: smoke/auditの全件被覆実行と機械可読証跡の生成。"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
from typing import Iterable

SCENE_RE = re.compile(r"^tools/.+_(?:smoke|audit)\.tscn$")
ALLOWED_RUNNERS = {"direct", "save_system", "export_evidence"}
EXPLAINED_ERROR_RULES = {
    "all": [(re.compile(r"^ERROR: 1 resources still in use at exit(?: \(.*\))?\.$"), "Godot終了時の既知resource解放診断。exit codeと他ERRORを別途検査")],
    "save_system": [(re.compile(r"^ERROR: Parse JSON failed\. Error at line 0: Expected key$"), "破損JSONからbackup復元する既存save負ケースの意図的入力")],
    "validation": [(re.compile(r"^ERROR: Could not create ObjectDB Snapshots directory:"), "headless editor検証時の任意snapshot保存失敗。validate本体のexitを別途検査")],
}
REQUIRED_SPECIAL = {
    "tools/save_namespace_migration_smoke.tscn": "save_system",
    "tools/save_system_smoke.tscn": "save_system",
    "tools/export_launch_smoke.tscn": "export_evidence",
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def discover(root: Path) -> list[str]:
    return sorted(
        path.relative_to(root).as_posix()
        for path in (root / "tools").rglob("*.tscn")
        if SCENE_RE.fullmatch(path.relative_to(root).as_posix())
    )


def load_manifest(path: Path) -> dict[str, str]:
    entries: dict[str, str] = {}
    for number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split("|")
        if len(parts) != 2 or not all(parts):
            raise ValueError(f"manifest {number}: scene|runner 形式ではありません")
        scene, runner = parts
        if scene in entries:
            raise ValueError(f"manifest {number}: 重複scene: {scene}")
        if not SCENE_RE.fullmatch(scene):
            raise ValueError(f"manifest {number}: 対象外scene: {scene}")
        if runner not in ALLOWED_RUNNERS:
            raise ValueError(f"manifest {number}: 未知runner: {runner}")
        entries[scene] = runner
    return entries


def classify(scenes: list[str], overrides: dict[str, str]) -> list[tuple[str, str]]:
    if not scenes:
        raise ValueError("smoke/audit sceneが0件です")
    stale = sorted(set(overrides) - set(scenes))
    if stale:
        raise ValueError(f"manifestに存在しないsceneがあります: {', '.join(stale)}")
    for scene, expected in REQUIRED_SPECIAL.items():
        if scene in scenes and overrides.get(scene) != expected:
            raise ValueError(f"特殊sceneのrunner不正: {scene} は {expected} 必須です")
    return [(scene, overrides.get(scene, "direct")) for scene in scenes]


def unexplained_errors(output: str, context: str = "all") -> list[str]:
    rules = EXPLAINED_ERROR_RULES["all"] + EXPLAINED_ERROR_RULES.get(context, [])
    return [line.strip() for line in output.splitlines() if "ERROR:" in line and not any(pattern.search(line.strip()) for pattern, _reason in rules)]


def run(command: list[str], cwd: Path, env: dict[str, str], log: Path, context: str = "all") -> tuple[int, list[str]]:
    timeout = int(env.get("TSURI_RELEASE_TEST_TIMEOUT_SECONDS", "900"))
    try:
        completed = subprocess.run(command, cwd=cwd, env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=timeout)
        output = completed.stdout
        return_code = completed.returncode
    except subprocess.TimeoutExpired as exc:
        output = (exc.stdout or "") + f"\nrelease_verify: timeout after {timeout}s\n"
        return_code = 124
    log.write_text(output, encoding="utf-8")
    return return_code, unexplained_errors(output, context)


def git_value(root: Path, *args: str) -> str:
    return subprocess.check_output(["git", "-C", str(root), *args], text=True).strip()


def parse_export_evidence(path: Path | None) -> dict[str, object]:
    if path is None or not path.is_file():
        return {"status": "not_provided", "contract": "tools/export_launch_verify.sh が生成する artifacts.sha256 をRC時に指定"}
    fields: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            fields[key] = value
    required = {"source_commit", "source_tree", "debug_pck_sha256", "release_pck_sha256", "release_pack_manifest_sha256"}
    missing = sorted(required - set(fields))
    if missing:
        raise ValueError(f"export証跡の必須field不足: {', '.join(missing)}")
    for key in ("source_commit", "source_tree", "debug_pck_sha256", "release_pck_sha256", "release_pack_manifest_sha256"):
        if not re.fullmatch(r"[0-9a-f]{40,64}", fields[key]):
            raise ValueError(f"export証跡のhash形式不正: {key}")
    for path_key, hash_key in (
        ("debug_pck", "debug_pck_sha256"),
        ("release_pck", "release_pck_sha256"),
        ("release_pack_manifest", "release_pack_manifest_sha256"),
    ):
        artifact = Path(fields.get(path_key, ""))
        if not artifact.is_file() or sha256(artifact) != fields[hash_key]:
            raise ValueError(f"export成果物hash不一致または消失: {path_key}")
    return {"status": "consumed", "path": str(path), "sha256": sha256(path), "fields": fields}


def validate_export_run_log(path: Path, artifact_log: Path, godot_version: str, template_version: str, template: Path) -> dict[str, object]:
    text = path.read_text(encoding="utf-8")
    errors = unexplained_errors(text)
    if errors:
        raise ValueError(f"export実行ログに未説明ERRORがあります: {errors[0]}")
    if not template.is_file():
        raise ValueError("RC検証に対応するexport templateがありません")
    expected_lines = (
        f"Godot: {godot_version}",
        f"Template: {template_version} ({template})",
        f"Artifact hashes: {artifact_log}",
        "export_launch_verify: PASS",
    )
    for line in expected_lines:
        if line not in text.splitlines():
            raise ValueError(f"export実行ログの契約行不足/不一致: {line}")
    return {"path": str(path), "sha256": sha256(path), "template_sha256_at_release_verify": sha256(template), "artifact_log_sha256": sha256(artifact_log)}


def main(argv: Iterable[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument("--manifest", type=Path)
    parser.add_argument("--output-dir", type=Path)
    parser.add_argument("--rc", action="store_true", help="固定RC契約（clean tree・同一sourceのexport証跡）を必須化")
    args = parser.parse_args(argv)
    root = args.root.resolve()
    manifest = args.manifest or root / "tools/release_test_manifest.txt"
    output = (args.output_dir or Path(os.environ.get("TSURI_RELEASE_VERIFY_OUTPUT", "/tmp/tsuri_release_verify"))).resolve()
    logs = output / "logs"
    logs.mkdir(parents=True, exist_ok=True)

    try:
        classified = classify(discover(root), load_manifest(manifest))
        godot = os.environ.get("GODOT_BIN", "/Applications/Godot.app/Contents/MacOS/Godot")
        if not Path(godot).is_file():
            godot = next((candidate for candidate in ("godot", "godot4") if subprocess.call(["sh", "-c", f"command -v {candidate} >/dev/null"]) == 0), "")
        if not godot:
            raise ValueError("Godot 4.xが見つかりません")
        version = subprocess.check_output([godot, "--version"], text=True, stderr=subprocess.STDOUT).strip()
        template_version = version.split(".official.", 1)[0]
        template = Path.home() / "Library/Application Support/Godot/export_templates" / template_version / "macos.zip"
        source_commit = git_value(root, "rev-parse", "HEAD^{commit}")
        source_tree = git_value(root, "rev-parse", "HEAD^{tree}")
        dirty = bool(git_value(root, "status", "--porcelain"))
        evidence_env = os.environ.get("TSURI_EXPORT_ARTIFACT_LOG")
        artifact_log = Path(evidence_env).resolve() if evidence_env else None
        export_evidence = parse_export_evidence(artifact_log)
        if export_evidence["status"] == "consumed":
            evidence_fields = export_evidence["fields"]
            if evidence_fields["source_commit"] != source_commit or evidence_fields["source_tree"] != source_tree:
                raise ValueError("export証跡のsource commit/treeが検証対象と一致しません")
        export_run_log: dict[str, object] | None = None
        if args.rc:
            if dirty:
                raise ValueError("RC検証はclean worktree必須です")
            if artifact_log is None or export_evidence["status"] != "consumed":
                raise ValueError("RC検証はTSURI_EXPORT_ARTIFACT_LOG必須です")
            run_log_env = os.environ.get("TSURI_EXPORT_VERIFY_LOG")
            if not run_log_env:
                raise ValueError("RC検証はexport_launch_verify.shの全stdoutを保存したTSURI_EXPORT_VERIFY_LOG必須です")
            export_run_log = validate_export_run_log(Path(run_log_env).resolve(), artifact_log, version, template_version, template)
        env = os.environ.copy()
        home_root = Path(env.get("TSURI_GODOT_HOME", "/tmp/tsuri_release_verify_home"))
        home_root.mkdir(parents=True, exist_ok=True)

        results: list[dict[str, object]] = []
        save_done = False
        failed = False
        validate_log = logs / "000_validate_project.log"
        validate_env = env.copy()
        validate_env["HOME"] = str(home_root / "validate")
        Path(validate_env["HOME"]).mkdir(parents=True, exist_ok=True)
        validate_rc, validate_errors = run([str(root / "tools/validate_project.sh")], root, validate_env, validate_log, "validation")
        failed |= validate_rc != 0 or bool(validate_errors)
        validation = {"status": "passed" if not failed else "failed", "exit_code": validate_rc, "unexplained_errors": validate_errors, "log": str(validate_log), "log_sha256": sha256(validate_log)}
        for index, (scene, runner) in enumerate(classified, 1):
            record: dict[str, object] = {"scene": scene, "runner": runner}
            if runner == "export_evidence":
                record["status"] = "delegated_evidence"
            elif runner == "save_system" and save_done:
                record["status"] = "covered_by_save_system_verify"
            else:
                log = logs / f"{index:03d}_{Path(scene).stem}.log"
                command = [str(root / "tools/save_system_verify.sh")] if runner == "save_system" else [godot, "--headless", "--path", str(root), f"res://{scene}"]
                test_env = env.copy()
                test_env["HOME"] = str(home_root / f"scene_{index:03d}")
                test_env["TSURI_GODOT_HOME"] = test_env["HOME"]
                Path(test_env["HOME"]).mkdir(parents=True, exist_ok=True)
                rc, errors = run(command, root, test_env, log, runner)
                save_done |= runner == "save_system"
                record.update(status="passed" if rc == 0 and not errors else "failed", exit_code=rc, unexplained_errors=errors, log=str(log), log_sha256=sha256(log))
                failed |= rc != 0 or bool(errors)
            results.append(record)

        report = {
            "schema_version": 1,
            "status": "failed" if failed else ("rc_passed" if args.rc else "skeleton_passed"),
            "mode": "rc" if args.rc else "skeleton",
            "source": {"commit": source_commit, "tree": source_tree, "dirty": dirty},
            "godot": {"version": version, "binary": godot},
            "export_template": {"version": template_version, "path": str(template), "present": template.is_file(), "sha256": sha256(template) if template.is_file() else None},
            "discovery": {"pattern": "tools/*_{smoke,audit}.tscn", "count": len(classified), "manifest": str(manifest), "manifest_sha256": sha256(manifest)},
            "validation": validation,
            "export_evidence": export_evidence,
            "export_verify_run_log": export_run_log,
            "tests": results,
            "rc_remaining": ["同一RCの署名・公証判断と最終成果物hash", "最終配布ZIPのhash", "RIGHTS-01B・性能/soak・3難易度9セル受入"],
        }
        report_path = output / "release_verify_report.json"
        report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"release_verify: {'FAIL' if failed else 'PASS'} ({len(classified)} scenes)")
        print(f"report: {report_path}")
        return 1 if failed else 0
    except (OSError, ValueError, subprocess.CalledProcessError) as exc:
        output.mkdir(parents=True, exist_ok=True)
        (output / "release_verify_report.json").write_text(
            json.dumps({"schema_version": 1, "status": "failed", "mode": "rc" if args.rc else "skeleton", "error": str(exc)}, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(f"release_verify: FAIL: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
