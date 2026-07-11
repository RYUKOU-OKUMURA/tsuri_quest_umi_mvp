#!/usr/bin/env python3
"""QA-RELEASE: smoke/auditの全件被覆実行と機械可読証跡の生成。"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import tempfile
import time
import shutil
from typing import Iterable

TEST_RE = re.compile(r"^tools/.+_(?:smoke|audit)\.(?:tscn|gd)$")
ALLOWED_RUNNERS = {"direct_scene", "direct_script", "save_system", "export_evidence"}
EXPLAINED_ERROR_RULES = {
    "all": [(re.compile(r"^ERROR: 1 resources still in use at exit(?: \(.*\))?\.$"), "Godot終了時の既知resource解放診断")],
    "save_system": [(re.compile(r"^ERROR: Parse JSON failed\. Error at line 0: Expected key$"), "破損JSONからbackup復元する既存負ケース")],
    "validation": [(re.compile(r"^ERROR: Could not create ObjectDB Snapshots directory:"), "headless editorの任意snapshot保存失敗")],
}
EXPLAINED_WARNING_RULES = {
    "all": [],
    "validation": [(re.compile(r"^WARNING: \d+ ObjectDB instances were leaked at exit \(run with `--verbose` for details\)\.$"), "既存headless validation終了時のObjectDB cleanup診断")],
    "direct_scene": [(re.compile(r"^WARNING: \d+ ObjectDB instances were leaked at exit \(run with `--verbose` for details\)\.$"), "既存scene終了時のObjectDB cleanup診断")],
    "export": [(re.compile(r"^WARNING: 2 ObjectDB instances were leaked at exit \(run with `--verbose` for details\)\.$"), "REL-01 export成果物smoke終了時の既知ObjectDB cleanup診断")],
    "save_system": [
        (re.compile(r"^WARNING: (?:新しい版で作られたセーブのため、対応する新しい版で開いてください。|旧版セーブの移行を完了できなかったため、セーブの読み書きを停止しました。ゲームを再起動してください。|移行markerのない一時コピーがあるため、移行を停止します。|旧namespace移行markerが不正なため、移行を停止します。|セーブデータが壊れていたため、バックアップから復元します。|セーブデータとバックアップが壊れているため、読み込めませんでした。原本は変更していません。|セーブファイルの差し替えに失敗しました（コード: 20）。|進行データがセーブ可能な範囲を超えたため、原本を変更せず保存を中止しました。|セーブ用の一時ファイルを開けませんでした。|セーブデータを書き込めませんでした。|セーブのバックアップ作成に失敗しました（コード: 20）。)$"), "save verifierの意図的な移行・破損・I/O失敗fixture"),
        (re.compile(r"^WARNING: Vector2 cannot be normalized, the elements must be finite\. Making \(0, 0\) as a fallback\.$"), "save smokeのtitle要約生成時にzero-size TitleBackdropを描画する既知経路"),
    ],
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


def normalize_output(value: str | bytes | None) -> str:
    if value is None:
        return ""
    return value.decode("utf-8", errors="replace") if isinstance(value, bytes) else value


def atomic_json(path: Path, data: dict[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as stream:
            json.dump(data, stream, ensure_ascii=False, indent=2)
            stream.write("\n")
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
    except BaseException:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass
        raise


def discover(root: Path) -> list[str]:
    root_resolved = root.resolve(strict=True)
    tools_root = root / "tools"
    candidates = {
        path.relative_to(root).as_posix()
        for path in tools_root.rglob("*")
        if path.is_file()
        and not path.is_symlink()
        and path.resolve(strict=True).is_relative_to(root_resolved)
        and not any(parent.is_symlink() for parent in path.parents if parent == tools_root or tools_root in parent.parents)
        and TEST_RE.fullmatch(path.relative_to(root).as_posix())
    }
    scene_stems = {str(Path(item).with_suffix("")) for item in candidates if item.endswith(".tscn")}
    return sorted(item for item in candidates if not (item.endswith(".gd") and str(Path(item).with_suffix("")) in scene_stems))


def default_runner(test: str) -> str:
    return "direct_scene" if test.endswith(".tscn") else "direct_script"


def load_manifest(path: Path) -> dict[str, str]:
    entries: dict[str, str] = {}
    for number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split("|")
        if len(parts) != 2 or not all(parts):
            raise ValueError(f"manifest {number}: test|runner 形式ではありません")
        test, runner = parts
        if test in entries:
            raise ValueError(f"manifest {number}: 重複test: {test}")
        if not TEST_RE.fullmatch(test) or runner not in ALLOWED_RUNNERS:
            raise ValueError(f"manifest {number}: testまたはrunnerが不正: {line}")
        entries[test] = runner
    return entries


def classify(tests: list[str], overrides: dict[str, str]) -> list[tuple[str, str]]:
    if not tests:
        raise ValueError("smoke/auditが0件です")
    missing = sorted(set(tests) - set(overrides))
    stale = sorted(set(overrides) - set(tests))
    if missing or stale:
        raise ValueError(f"発見集合とmanifestが不一致です missing={missing} stale={stale}")
    for test, expected in REQUIRED_SPECIAL.items():
        if test in tests and overrides.get(test) != expected:
            raise ValueError(f"特殊testのrunner不正: {test} は {expected} 必須です")
    classified = [(test, overrides[test]) for test in tests]
    for test, runner in classified:
        if runner == "direct_scene" and not test.endswith(".tscn") or runner == "direct_script" and not test.endswith(".gd"):
            raise ValueError(f"拡張子とrunnerが不一致です: {test}|{runner}")
    return classified


def unexplained_errors(output: str, context: str = "all") -> list[str]:
    rules = EXPLAINED_ERROR_RULES["all"] + EXPLAINED_ERROR_RULES.get(context, [])
    return [line.strip() for line in output.splitlines() if "ERROR:" in line and not any(pattern.search(line.strip()) for pattern, _ in rules)]


def warning_summary(output: str, context: str = "all") -> dict[str, object]:
    found = [line.strip() for line in output.splitlines() if "WARNING:" in line]
    rules = EXPLAINED_WARNING_RULES["all"] + EXPLAINED_WARNING_RULES.get(context, [])
    unknown = [line for line in found if not any(pattern.fullmatch(line) for pattern, _ in rules)]
    return {"count": len(found), "distinct_samples": sorted(set(found))[:20], "unexplained": unknown}


def run(command: list[str], cwd: Path, env: dict[str, str], log: Path, context: str = "all") -> dict[str, object]:
    timeout = float(env.get("TSURI_RELEASE_TEST_TIMEOUT_SECONDS", "900"))
    grace = float(env.get("TSURI_RELEASE_TERM_GRACE_SECONDS", "3"))
    process = subprocess.Popen(command, cwd=cwd, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, start_new_session=True)
    timed_out = False
    try:
        raw, _ = process.communicate(timeout=timeout)
    except subprocess.TimeoutExpired as exc:
        timed_out = True
        try:
            os.killpg(process.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        try:
            raw, _ = process.communicate(timeout=grace)
        except subprocess.TimeoutExpired:
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            raw, _ = process.communicate()
    output = normalize_output(raw)
    if timed_out:
        output += f"\nrelease_verify: timeout after {timeout:g}s\n"
    log.write_text(output, encoding="utf-8")
    return {
        "exit_code": 124 if timed_out else process.returncode,
        "timed_out": timed_out,
        "unexplained_errors": unexplained_errors(output, context),
        "warnings": warning_summary(output, context),
        "log": str(log),
        "log_sha256": sha256(log),
    }


def create_run_home(parent: Path) -> Path:
    if parent.is_symlink() or not parent.is_dir():
        raise ValueError(f"HOME親は既存の実ディレクトリ必須です: {parent}")
    resolved = parent.resolve(strict=True)
    return Path(tempfile.mkdtemp(prefix="tsuri_release_verify_home_", dir=resolved))


def install_engine_shim(home_root: Path, godot: str) -> Path:
    source = Path(godot) if os.path.sep in godot else Path(shutil.which(godot) or "")
    if not source.is_file():
        raise ValueError(f"選択Godotを解決できません: {godot}")
    source = source.resolve(strict=True)
    bin_dir = home_root / "bin"
    bin_dir.mkdir()
    shim = bin_dir / "godot"
    shim.symlink_to(source)
    return bin_dir


def git_value(root: Path, *args: str) -> str:
    return subprocess.check_output(["git", "-C", str(root), *args], text=True).strip()


def parse_export_evidence(path: Path | None) -> dict[str, object]:
    if path is None or not path.is_file():
        return {"status": "not_provided", "contract": "export_launch_verify.sh生成のartifacts.sha256をRC時に指定"}
    fields = dict(line.split("=", 1) for line in path.read_text(encoding="utf-8").splitlines() if "=" in line)
    required = {"source_commit", "source_tree", "debug_pck_sha256", "release_pck_sha256", "release_pack_manifest_sha256"}
    missing = sorted(required - set(fields))
    if missing:
        raise ValueError(f"export証跡の必須field不足: {', '.join(missing)}")
    for key in required:
        if not re.fullmatch(r"[0-9a-f]{40,64}", fields[key]):
            raise ValueError(f"export証跡のhash形式不正: {key}")
    for path_key, hash_key in (("debug_pck", "debug_pck_sha256"), ("release_pck", "release_pck_sha256"), ("release_pack_manifest", "release_pack_manifest_sha256")):
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
    for line in (f"Godot: {godot_version}", f"Template: {template_version} ({template})", f"Artifact hashes: {artifact_log}", "export_launch_verify: PASS"):
        if line not in text.splitlines():
            raise ValueError(f"export実行ログの契約行不足/不一致: {line}")
    export_warnings = warning_summary(text, "export")
    if export_warnings["unexplained"]:
        raise ValueError(f"export実行ログに未説明WARNINGがあります: {export_warnings['unexplained'][0]}")
    return {"path": str(path), "sha256": sha256(path), "warnings": export_warnings, "template_sha256_at_release_verify": sha256(template), "artifact_log_sha256": sha256(artifact_log)}


def git_snapshot(root: Path) -> dict[str, object]:
    porcelain = git_value(root, "status", "--porcelain")
    digest = hashlib.sha256()
    for args in (("diff", "--binary", "--no-ext-diff"), ("diff", "--cached", "--binary", "--no-ext-diff")):
        digest.update(subprocess.check_output(["git", "-C", str(root), *args]))
    untracked = subprocess.check_output(["git", "-C", str(root), "ls-files", "--others", "--exclude-standard", "-z"]).split(b"\0")
    for raw in sorted(item for item in untracked if item):
        relative = raw.decode("utf-8", errors="surrogateescape")
        path = root / relative
        digest.update(raw + b"\0")
        if path.is_symlink():
            digest.update(b"symlink\0" + os.readlink(path).encode("utf-8", errors="surrogateescape"))
        elif path.is_file():
            digest.update(b"file\0" + bytes.fromhex(sha256(path)))
        else:
            digest.update(b"other\0")
    return {
        "commit": git_value(root, "rev-parse", "HEAD^{commit}"),
        "tree": git_value(root, "rev-parse", "HEAD^{tree}"),
        "dirty": bool(porcelain),
        "porcelain_sha256": hashlib.sha256(porcelain.encode()).hexdigest(),
        "worktree_content_sha256": digest.hexdigest(),
    }


def main(argv: Iterable[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument("--manifest", type=Path)
    parser.add_argument("--output-dir", type=Path)
    parser.add_argument("--rc", action="store_true")
    args = parser.parse_args(argv)
    root = args.root.resolve()
    manifest = args.manifest or root / "tools/release_test_manifest.txt"
    output = (args.output_dir or Path(os.environ.get("TSURI_RELEASE_VERIFY_OUTPUT", "/tmp/tsuri_release_verify"))).resolve()
    report_path = output / "release_verify_report.json"
    report: dict[str, object] = {"schema_version": 2, "status": "running", "mode": "rc" if args.rc else "skeleton", "started_at_unix": time.time()}
    atomic_json(report_path, report)  # 旧PASSを最初に無効化する
    home_root: Path | None = None
    try:
        output.mkdir(parents=True, exist_ok=True)
        logs = output / "logs"
        logs.mkdir(parents=True, exist_ok=True)
        classified = classify(discover(root), load_manifest(manifest))
        godot = os.environ.get("GODOT_BIN", "/Applications/Godot.app/Contents/MacOS/Godot")
        if not Path(godot).is_file():
            godot = next((name for name in ("godot", "godot4") if subprocess.call(["sh", "-c", f"command -v {name} >/dev/null"]) == 0), "")
        if not godot:
            raise ValueError("Godot 4.xが見つかりません")
        version = subprocess.check_output([godot, "--version"], text=True, stderr=subprocess.STDOUT).strip()
        template_version = version.split(".official.", 1)[0]
        template = Path.home() / "Library/Application Support/Godot/export_templates" / template_version / "macos.zip"
        source_start = git_snapshot(root)
        source_commit = source_start["commit"]
        source_tree = source_start["tree"]
        dirty = source_start["dirty"]
        artifact_env = os.environ.get("TSURI_EXPORT_ARTIFACT_LOG")
        artifact_log = Path(artifact_env).resolve() if artifact_env else None
        export_evidence = parse_export_evidence(artifact_log)
        if export_evidence["status"] == "consumed" and (export_evidence["fields"]["source_commit"] != source_commit or export_evidence["fields"]["source_tree"] != source_tree):
            raise ValueError("export証跡のsource commit/treeが検証対象と一致しません")
        export_run_log = None
        if args.rc:
            if dirty or artifact_log is None or export_evidence["status"] != "consumed":
                raise ValueError("RC検証はclean worktreeとTSURI_EXPORT_ARTIFACT_LOG必須です")
            run_log_env = os.environ.get("TSURI_EXPORT_VERIFY_LOG")
            if not run_log_env:
                raise ValueError("RC検証はexport_launch_verify.sh全stdoutのTSURI_EXPORT_VERIFY_LOG必須です")
            export_run_log = validate_export_run_log(Path(run_log_env).resolve(), artifact_log, version, template_version, template)

        parent = Path(os.environ.get("TSURI_RELEASE_HOME_PARENT", tempfile.gettempdir()))
        home_root = create_run_home(parent)
        engine_bin = install_engine_shim(home_root, godot)
        env = os.environ.copy()
        env["PATH"] = f"{engine_bin}{os.pathsep}{env.get('PATH', '')}"
        results: list[dict[str, object]] = []
        validate_home = home_root / "validation"
        validate_home.mkdir()
        validate_env = env | {"HOME": str(validate_home), "TSURI_GODOT_HOME": str(validate_home)}
        validation = run([str(root / "tools/validate_project.sh")], root, validate_env, logs / "000_validate_project.log", "validation")
        validation["status"] = "passed" if validation["exit_code"] == 0 and not validation["unexplained_errors"] and not validation["warnings"]["unexplained"] else "failed"
        failed = validation["status"] == "failed"
        save_done = False
        for index, (test, runner) in enumerate(classified, 1):
            record: dict[str, object] = {"test": test, "runner": runner}
            if runner == "export_evidence":
                record.update(status="delegated_evidence", warnings={"count": 0, "distinct_samples": []})
            elif runner == "save_system" and save_done:
                record.update(status="covered_by_save_system_verify", warnings={"count": 0, "distinct_samples": []})
            else:
                test_home = home_root / f"test_{index:03d}"
                test_home.mkdir()
                test_env = env | {"HOME": str(test_home), "TSURI_GODOT_HOME": str(test_home)}
                if runner == "save_system":
                    command = [str(root / "tools/save_system_verify.sh")]
                elif runner == "direct_script":
                    command = [godot, "--headless", "--path", str(root), "--script", f"res://{test}"]
                else:
                    command = [godot, "--headless", "--path", str(root), f"res://{test}"]
                execution = run(command, root, test_env, logs / f"{index:03d}_{Path(test).stem}.log", runner)
                save_done |= runner == "save_system"
                execution["status"] = "passed" if execution["exit_code"] == 0 and not execution["unexplained_errors"] and not execution["warnings"]["unexplained"] else "failed"
                record.update(execution)
                failed |= execution["status"] == "failed"
            results.append(record)
        shutil.rmtree(home_root)
        home_root = None
        source_end = git_snapshot(root)
        if source_end != source_start:
            failed = True
        report.update(
            status="failed" if failed else ("rc_passed" if args.rc else "skeleton_passed"),
            source={"start": source_start, "end": source_end, "stable": source_end == source_start},
            godot={"version": version, "binary": godot},
            export_template={"version": template_version, "path": str(template), "present": template.is_file(), "sha256": sha256(template) if template.is_file() else None},
            discovery={"patterns": ["tools/**/*_{smoke,audit}.tscn", "non-scene tools/**/*_{smoke,audit}.gd"], "count": len(classified), "manifest": str(manifest), "manifest_sha256": sha256(manifest)},
            validation=validation,
            export_evidence=export_evidence,
            export_verify_run_log=export_run_log,
            tests=results,
            warnings={"count": int(validation["warnings"]["count"]) + sum(int(item["warnings"]["count"]) for item in results), "distinct_samples": sorted(set(validation["warnings"]["distinct_samples"]).union(*(item["warnings"]["distinct_samples"] for item in results)))[:50]},
            rc_remaining=["同一RCの署名・公証判断と最終成果物hash", "最終配布ZIPのhash", "RIGHTS-01B・性能/soak・3難易度9セル受入"],
        )
        atomic_json(report_path, report)
        print(f"release_verify: {'FAIL' if failed else 'PASS'} ({len(classified)} tests)")
        print(f"report: {report_path}")
        return 1 if failed else 0
    except BaseException as exc:
        cleanup_error = None
        if home_root is not None:
            try:
                shutil.rmtree(home_root)
            except BaseException as cleanup_exc:
                cleanup_error = f"{type(cleanup_exc).__name__}: {cleanup_exc}"
        report.update(status="failed", error=f"{type(exc).__name__}: {exc}", failed_at_unix=time.time())
        if cleanup_error:
            report["cleanup_error"] = cleanup_error
        atomic_json(report_path, report)
        print(f"release_verify: FAIL: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
