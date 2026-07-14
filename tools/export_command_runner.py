#!/usr/bin/env python3
"""Run one export verification command with a bounded process-group lifetime."""

from __future__ import annotations

import argparse
import math
import os
from pathlib import Path
import signal
import subprocess
import sys
import time
from typing import NoReturn


TIMEOUT_EXIT_CODE = 124
PROCESS_GROUP_CLEANUP_EXIT_CODE = 125
DEFAULT_TERM_GRACE_SECONDS = 1.0
HANDLED_SIGNALS = (signal.SIGINT, signal.SIGTERM, signal.SIGHUP)


class CommandInterrupted(BaseException):
    def __init__(self, signum: int) -> None:
        super().__init__(signum)
        self.signum = signum


def positive_finite(value: str, label: str) -> float:
    try:
        parsed = float(value)
    except ValueError as error:
        raise ValueError(f"{label} must be a positive finite number: {value!r}") from error
    if not math.isfinite(parsed) or parsed <= 0.0:
        raise ValueError(f"{label} must be a positive finite number: {value!r}")
    return parsed


def _group_exists(process_group_id: int) -> bool:
    try:
        os.killpg(process_group_id, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return True


def _signal_group(process_group_id: int, signum: int) -> None:
    try:
        os.killpg(process_group_id, signum)
    except ProcessLookupError:
        pass


def _wait_for_group_exit(
    process: subprocess.Popen[bytes],
    process_group_id: int,
    timeout_seconds: float,
) -> bool:
    deadline = time.monotonic() + timeout_seconds
    while True:
        process.poll()
        if not _group_exists(process_group_id):
            return True
        remaining = deadline - time.monotonic()
        if remaining <= 0.0:
            return False
        time.sleep(min(0.02, remaining))


def terminate_process_group(process: subprocess.Popen[bytes], grace_seconds: float) -> bool:
    """Terminate the complete child session, including TERM-ignoring descendants."""
    process_group_id = process.pid
    if not _group_exists(process_group_id):
        return True
    _signal_group(process_group_id, signal.SIGTERM)
    if _wait_for_group_exit(process, process_group_id, grace_seconds):
        return True
    _signal_group(process_group_id, signal.SIGKILL)
    return _wait_for_group_exit(process, process_group_id, grace_seconds)


def _open_log(log_path: Path):
    if not log_path.is_absolute():
        raise ValueError(f"log path must be absolute: {log_path}")
    if not log_path.parent.is_dir():
        raise ValueError(f"log parent must already exist: {log_path.parent}")
    if log_path.is_symlink():
        raise ValueError(f"log path must not be a symlink: {log_path}")
    flags = os.O_WRONLY | os.O_CREAT | os.O_TRUNC
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW
    descriptor = os.open(log_path, flags, 0o600)
    return os.fdopen(descriptor, "wb", buffering=0)


def _append_diagnostic(log_file, message: str) -> None:
    log_file.write(f"\nexport_command_runner: {message}\n".encode("utf-8"))


def replay_log(log_path: Path) -> None:
    """Replay binary command output without allowing invalid UTF-8 to crash the runner."""
    output = log_path.read_bytes().decode("utf-8", errors="replace")
    sys.stdout.write(output)
    sys.stdout.flush()


def run_command(
    command: list[str],
    timeout_seconds: float,
    grace_seconds: float,
    log_path: Path,
    echo: bool,
) -> int:
    if not command:
        raise ValueError("command must not be empty")

    process: subprocess.Popen[bytes] | None = None
    previous_handlers: dict[int, signal.Handlers] = {}

    def handle_signal(signum: int, _frame) -> NoReturn:
        raise CommandInterrupted(signum)

    with _open_log(log_path) as log_file:
        try:
            for signum in HANDLED_SIGNALS:
                previous_handlers[signum] = signal.getsignal(signum)
                signal.signal(signum, handle_signal)
            try:
                process = subprocess.Popen(
                    command,
                    stdout=log_file,
                    stderr=subprocess.STDOUT,
                    start_new_session=True,
                )
                try:
                    return_code = process.wait(timeout=timeout_seconds)
                except subprocess.TimeoutExpired:
                    for signum in HANDLED_SIGNALS:
                        signal.signal(signum, signal.SIG_IGN)
                    cleanup_succeeded = terminate_process_group(process, grace_seconds)
                    _append_diagnostic(log_file, f"timeout after {timeout_seconds:g}s")
                    if cleanup_succeeded:
                        return_code = TIMEOUT_EXIT_CODE
                    else:
                        _append_diagnostic(log_file, "failed to clean process group after timeout")
                        return_code = PROCESS_GROUP_CLEANUP_EXIT_CODE
                else:
                    original_return_code = return_code
                    if _group_exists(process.pid):
                        cleanup_succeeded = terminate_process_group(process, grace_seconds)
                        if cleanup_succeeded:
                            _append_diagnostic(
                                log_file,
                                f"cleaned surviving process group after command exit {original_return_code}",
                            )
                        else:
                            _append_diagnostic(
                                log_file,
                                f"failed to clean surviving process group after command exit {original_return_code}",
                            )
                            return_code = PROCESS_GROUP_CLEANUP_EXIT_CODE
            except CommandInterrupted as interrupted:
                for signum in HANDLED_SIGNALS:
                    signal.signal(signum, signal.SIG_IGN)
                cleanup_succeeded = True
                if process is not None:
                    cleanup_succeeded = terminate_process_group(process, grace_seconds)
                signal_name = signal.Signals(interrupted.signum).name
                _append_diagnostic(log_file, f"interrupted by {signal_name}")
                if cleanup_succeeded:
                    return_code = 128 + interrupted.signum
                else:
                    _append_diagnostic(log_file, "failed to clean process group after interrupt")
                    return_code = PROCESS_GROUP_CLEANUP_EXIT_CODE
        finally:
            for signum in previous_handlers:
                signal.signal(signum, signal.SIG_IGN)
            if process is not None and _group_exists(process.pid):
                terminate_process_group(process, grace_seconds)
            for signum, previous_handler in previous_handlers.items():
                signal.signal(signum, previous_handler)

    if echo:
        replay_log(log_path)
    if return_code < 0:
        return 128 - return_code
    return return_code


def parse_arguments(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="action", required=True)

    validate_parser = subparsers.add_parser("validate", help="validate label=seconds values")
    validate_parser.add_argument("values", nargs="+")

    run_parser = subparsers.add_parser("run", help="run one bounded command")
    run_parser.add_argument("--timeout-seconds", required=True)
    run_parser.add_argument("--term-grace-seconds", default=str(DEFAULT_TERM_GRACE_SECONDS))
    run_parser.add_argument("--log", required=True, type=Path)
    run_parser.add_argument("--echo", action="store_true")
    run_parser.add_argument("command", nargs=argparse.REMAINDER)
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    arguments = parse_arguments(sys.argv[1:] if argv is None else argv)
    try:
        if arguments.action == "validate":
            for item in arguments.values:
                label, separator, raw_value = item.partition("=")
                if not separator or not label:
                    raise ValueError(f"timeout validation requires label=value: {item!r}")
                positive_finite(raw_value, label)
            return 0

        timeout_seconds = positive_finite(arguments.timeout_seconds, "timeout_seconds")
        grace_seconds = positive_finite(arguments.term_grace_seconds, "term_grace_seconds")
        command = list(arguments.command)
        if command and command[0] == "--":
            command = command[1:]
        return run_command(command, timeout_seconds, grace_seconds, arguments.log, arguments.echo)
    except (OSError, ValueError) as error:
        print(f"export_command_runner: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
