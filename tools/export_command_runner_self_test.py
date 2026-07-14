#!/usr/bin/env python3
"""Focused contract tests for export_command_runner.py."""

from __future__ import annotations

import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import tempfile
import time


RUNNER = Path(__file__).with_name("export_command_runner.py").resolve()
EXPORT_SCRIPT = Path(__file__).with_name("export_launch_verify.sh").resolve()


def invoke(
    log_path: Path,
    command: list[str],
    timeout: str = "2",
    grace: str = "0.1",
    echo: bool = False,
) -> subprocess.CompletedProcess[bytes]:
    arguments = [
        sys.executable,
        str(RUNNER),
        "run",
        "--timeout-seconds",
        timeout,
        "--term-grace-seconds",
        grace,
        "--log",
        str(log_path),
    ]
    if echo:
        arguments.append("--echo")
    arguments.extend(["--", *command])
    return subprocess.run(arguments, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)


def assert_process_gone(process_id: int) -> None:
    deadline = time.monotonic() + 1.0
    while time.monotonic() < deadline:
        try:
            os.kill(process_id, 0)
        except ProcessLookupError:
            return
        time.sleep(0.02)
    raise AssertionError(f"descendant process survived cleanup: {process_id}")


def descendant_command(ready: Path, marker: Path, pid_path: Path) -> list[str]:
    child_code = (
        "import os, pathlib, signal, time; "
        "signal.signal(signal.SIGTERM, signal.SIG_IGN); "
        f"pathlib.Path({str(pid_path)!r}).write_text(str(os.getpid())); "
        f"pathlib.Path({str(ready)!r}).write_text('ready'); "
        "time.sleep(1.2); "
        f"pathlib.Path({str(marker)!r}).write_text('orphan')"
    )
    parent_code = (
        "import subprocess, sys, time; "
        f"subprocess.Popen([sys.executable, '-c', {child_code!r}]); "
        "time.sleep(10)"
    )
    return [sys.executable, "-c", parent_code]


def early_exit_descendant_command(
    ready: Path,
    marker: Path,
    pid_path: Path,
    return_code: int,
) -> list[str]:
    child_code = (
        "import os, pathlib, signal, time; "
        "signal.signal(signal.SIGTERM, signal.SIG_IGN); "
        f"pathlib.Path({str(pid_path)!r}).write_text(str(os.getpid())); "
        f"pathlib.Path({str(ready)!r}).write_text('ready'); "
        "time.sleep(0.4); "
        f"pathlib.Path({str(marker)!r}).write_text('orphan')"
    )
    parent_code = (
        "import pathlib, subprocess, sys, time\n"
        f"ready = pathlib.Path({str(ready)!r})\n"
        f"subprocess.Popen([sys.executable, '-c', {child_code!r}])\n"
        "deadline = time.monotonic() + 2.0\n"
        "while not ready.exists() and time.monotonic() < deadline:\n"
        "    time.sleep(0.01)\n"
        f"raise SystemExit({return_code})\n"
    )
    return [sys.executable, "-c", parent_code]


def short_lived_descendant_command(ready: Path, marker: Path, pid_path: Path) -> list[str]:
    child_code = (
        "import os, pathlib, time; "
        f"pathlib.Path({str(pid_path)!r}).write_text(str(os.getpid())); "
        f"pathlib.Path({str(ready)!r}).write_text('ready'); "
        "time.sleep(0.05)"
    )
    parent_code = (
        "import subprocess, sys; "
        f"child = subprocess.Popen([sys.executable, '-c', {child_code!r}]); "
        "child.wait(); "
        "raise SystemExit(0)"
    )
    return [sys.executable, "-c", parent_code]


with tempfile.TemporaryDirectory(prefix="export-command-runner-test-") as temporary:
    root = Path(temporary)

    success_log = root / "success.log"
    success = invoke(
        success_log,
        [sys.executable, "-c", "import sys; print('stdout'); print('stderr', file=sys.stderr)"],
        echo=True,
    )
    assert success.returncode == 0
    assert success_log.read_text().splitlines() == ["stderr", "stdout"] or set(success_log.read_text().splitlines()) == {"stdout", "stderr"}
    assert b"stdout" in success.stdout and b"stderr" in success.stdout

    nonzero_log = root / "nonzero.log"
    nonzero = invoke(nonzero_log, [sys.executable, "-c", "raise SystemExit(7)"])
    assert nonzero.returncode == 7 and nonzero_log.is_file()

    for label, parent_exit in (("early_success", 0), ("early_nonzero", 7)):
        early_ready = root / f"{label}_ready"
        early_marker = root / f"{label}_marker"
        early_pid_path = root / f"{label}.pid"
        early_log = root / f"{label}.log"
        early_result = invoke(
            early_log,
            early_exit_descendant_command(early_ready, early_marker, early_pid_path, parent_exit),
        )
        assert early_result.returncode == parent_exit
        assert early_ready.is_file() and early_pid_path.is_file()
        assert "cleaned surviving process group after command exit" in early_log.read_text()
        assert_process_gone(int(early_pid_path.read_text()))
        time.sleep(0.45)
        assert not early_marker.exists(), f"親exit {parent_exit}後のdescendantがmarkerを書きました"

    short_ready = root / "short_lived_ready"
    short_marker = root / "short_lived_marker"
    short_pid_path = root / "short_lived.pid"
    short_log = root / "short_lived.log"
    short_result = invoke(
        short_log,
        short_lived_descendant_command(short_ready, short_marker, short_pid_path),
    )
    assert short_result.returncode == 0
    assert short_ready.is_file() and short_pid_path.is_file()
    assert_process_gone(int(short_pid_path.read_text()))
    assert not short_marker.exists()
    assert "surviving process group" not in short_log.read_text()

    binary_log = root / "binary.log"
    binary = invoke(
        binary_log,
        [sys.executable, "-c", "import os; os.write(1, b'partial\\xff')"],
        echo=True,
    )
    assert binary.returncode == 0
    assert binary_log.read_bytes() == b"partial\xff"
    assert "partial�" in binary.stdout.decode("utf-8")

    timeout_log = root / "timeout.log"
    timed_out = invoke(timeout_log, [sys.executable, "-c", "import time; time.sleep(10)"], timeout="0.1")
    assert timed_out.returncode == 124
    assert "timeout after 0.1s" in timeout_log.read_text()

    ready = root / "ready"
    marker = root / "orphan_marker"
    pid_path = root / "descendant.pid"
    descendant_log = root / "descendant.log"
    descendant = invoke(descendant_log, descendant_command(ready, marker, pid_path), timeout="0.3")
    assert descendant.returncode == 124 and ready.is_file() and pid_path.is_file()
    descendant_pid = int(pid_path.read_text())
    assert_process_gone(descendant_pid)
    time.sleep(1.25)
    assert not marker.exists(), "TERMを無視したdescendantがtimeout後にmarkerを書きました"

    interrupt_ready = root / "interrupt_ready"
    interrupt_marker = root / "interrupt_marker"
    interrupt_pid_path = root / "interrupt_descendant.pid"
    interrupt_log = root / "interrupt.log"
    runner_process = subprocess.Popen(
        [
            sys.executable,
            str(RUNNER),
            "run",
            "--timeout-seconds",
            "10",
            "--term-grace-seconds",
            "0.1",
            "--log",
            str(interrupt_log),
            "--",
            *descendant_command(interrupt_ready, interrupt_marker, interrupt_pid_path),
        ]
    )
    deadline = time.monotonic() + 2.0
    while not interrupt_ready.exists() and time.monotonic() < deadline:
        time.sleep(0.02)
    assert interrupt_ready.exists() and interrupt_pid_path.exists()
    runner_process.send_signal(signal.SIGTERM)
    assert runner_process.wait(timeout=2.0) == 128 + signal.SIGTERM
    assert_process_gone(int(interrupt_pid_path.read_text()))
    time.sleep(1.25)
    assert not interrupt_marker.exists(), "中断後にdescendantがmarkerを書きました"
    assert "interrupted by SIGTERM" in interrupt_log.read_text()

    for invalid in ("0", "-1", "nan", "inf"):
        invalid_result = subprocess.run(
            [sys.executable, str(RUNNER), "validate", f"fixture={invalid}"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        assert invalid_result.returncode == 2
    assert subprocess.run(
        [sys.executable, str(RUNNER), "validate", "setup=30", "export=900", "smoke=30", "grace=0.1"],
        check=False,
    ).returncode == 0

    # export wrapperへTERMをpid指定しても、active runnerへ転送してchild sessionを掃除する。
    wrapper_ready = root / "wrapper_ready"
    wrapper_marker = root / "wrapper_marker"
    wrapper_pid_path = root / "wrapper_descendant.pid"
    fake_godot = root / "fake_godot.py"
    fake_child_code = (
        "import os, pathlib, signal, time; "
        "signal.signal(signal.SIGTERM, signal.SIG_IGN); "
        f"pathlib.Path({str(wrapper_pid_path)!r}).write_text(str(os.getpid())); "
        f"pathlib.Path({str(wrapper_ready)!r}).write_text('ready'); "
        "time.sleep(1.2); "
        f"pathlib.Path({str(wrapper_marker)!r}).write_text('orphan')"
    )
    fake_godot.write_text(
        "#!/usr/bin/env python3\n"
        "import subprocess, sys, time\n"
        f"subprocess.Popen([sys.executable, '-c', {fake_child_code!r}])\n"
        "time.sleep(10)\n"
    )
    fake_godot.chmod(0o755)
    build_root = Path("/tmp") / f"tsuri_quest_umi_export_runner_test_{os.getpid()}"
    shutil.rmtree(build_root, ignore_errors=True)
    wrapper = subprocess.Popen(
        ["bash", str(EXPORT_SCRIPT)],
        env={
            **os.environ,
            "GODOT_BIN": str(fake_godot),
            "TSURI_EXPORT_BUILD_ROOT": str(build_root),
            "TSURI_EXPORT_SETUP_TIMEOUT_SECONDS": "10",
            "TSURI_EXPORT_TERM_GRACE_SECONDS": "0.1",
        },
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    deadline = time.monotonic() + 2.0
    while not wrapper_ready.exists() and time.monotonic() < deadline:
        time.sleep(0.02)
    assert wrapper_ready.exists() and wrapper_pid_path.exists()
    wrapper.send_signal(signal.SIGTERM)
    wrapper_output = wrapper.communicate(timeout=3.0)
    assert wrapper.returncode == 128 + signal.SIGTERM, wrapper_output
    assert_process_gone(int(wrapper_pid_path.read_text()))
    time.sleep(1.25)
    assert not wrapper_marker.exists(), "export wrapper中断後にdescendantがmarkerを書きました"
    shutil.rmtree(build_root, ignore_errors=True)

    # wrapperのsetup timeoutもrunnerの124を失わず、同じcleanup契約を通る。
    timeout_ready = root / "wrapper_timeout_ready"
    timeout_marker = root / "wrapper_timeout_marker"
    timeout_pid_path = root / "wrapper_timeout_descendant.pid"
    timeout_child_code = (
        "import os, pathlib, signal, time; "
        "signal.signal(signal.SIGTERM, signal.SIG_IGN); "
        f"pathlib.Path({str(timeout_pid_path)!r}).write_text(str(os.getpid())); "
        f"pathlib.Path({str(timeout_ready)!r}).write_text('ready'); "
        "time.sleep(1.2); "
        f"pathlib.Path({str(timeout_marker)!r}).write_text('orphan')"
    )
    fake_godot.write_text(
        "#!/usr/bin/env python3\n"
        "import subprocess, sys, time\n"
        f"subprocess.Popen([sys.executable, '-c', {timeout_child_code!r}])\n"
        "time.sleep(10)\n"
    )
    with tempfile.TemporaryDirectory(prefix="tsuri_quest_umi_export_timeout_", dir="/tmp") as timeout_build:
        timed_wrapper = subprocess.run(
            ["bash", str(EXPORT_SCRIPT)],
            env={
                **os.environ,
                "GODOT_BIN": str(fake_godot),
                "TSURI_EXPORT_BUILD_ROOT": timeout_build,
                "TSURI_EXPORT_SETUP_TIMEOUT_SECONDS": "0.3",
                "TSURI_EXPORT_TERM_GRACE_SECONDS": "0.1",
            },
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
    assert timed_wrapper.returncode == 124, timed_wrapper
    assert timeout_ready.exists() and timeout_pid_path.exists()
    assert_process_gone(int(timeout_pid_path.read_text()))
    time.sleep(1.25)
    assert not timeout_marker.exists(), "export wrapper timeout後にdescendantがmarkerを書きました"

print("export command runner self-test: ok")
