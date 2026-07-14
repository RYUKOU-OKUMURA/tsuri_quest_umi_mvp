#!/usr/bin/env python3
"""Build a canonical, non-following manifest for one exported macOS app bundle."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import stat
import tempfile


def _lexical_absolute(path: Path) -> Path:
    return Path(os.path.abspath(os.fspath(path.expanduser())))


def _reject_symlink_components(path: Path, label: str) -> None:
    for component in reversed((path, *path.parents)):
        if component.is_symlink():
            raise ValueError(f"{label} path component must not be a symlink: {component}")


def validate_bundle_root(raw_root: Path) -> Path:
    root = _lexical_absolute(raw_root)
    _reject_symlink_components(root, "app bundle")
    if not root.is_dir():
        raise ValueError(f"app bundle must be a real directory: {root}")
    return root


def validate_manifest_file(raw_manifest: Path, raw_root: Path) -> Path:
    root = validate_bundle_root(raw_root)
    manifest = _lexical_absolute(raw_manifest)
    _reject_symlink_components(manifest, "app manifest")
    if not manifest.is_file() or not stat.S_ISREG(manifest.lstat().st_mode):
        raise ValueError(f"app manifest must be a real regular file: {manifest}")
    if manifest == root or root in manifest.parents:
        raise ValueError("app manifest must be outside the app bundle")
    return manifest


def _mode(file_stat: os.stat_result) -> str:
    return f"{stat.S_IMODE(file_stat.st_mode):04o}"


def _regular_file_sha256(path: Path, expected: os.stat_result) -> str:
    flags = os.O_RDONLY
    if hasattr(os, "O_NOFOLLOW"):
        flags |= os.O_NOFOLLOW
    descriptor = os.open(path, flags)
    digest = hashlib.sha256()
    try:
        actual = os.fstat(descriptor)
        if not stat.S_ISREG(actual.st_mode):
            raise ValueError(f"bundle entry changed type while hashing: {path}")
        expected_identity = (expected.st_dev, expected.st_ino, expected.st_size, expected.st_mode)
        actual_identity = (actual.st_dev, actual.st_ino, actual.st_size, actual.st_mode)
        if actual_identity != expected_identity:
            raise ValueError(f"bundle entry changed while hashing: {path}")
        while chunk := os.read(descriptor, 1024 * 1024):
            digest.update(chunk)
    finally:
        os.close(descriptor)
    return digest.hexdigest()


def bundle_manifest_entries(raw_root: Path) -> list[dict[str, object]]:
    root = validate_bundle_root(raw_root)
    entries: list[dict[str, object]] = []
    pending = [root]
    while pending:
        path = pending.pop()
        file_stat = path.lstat()
        relative_path = "." if path == root else path.relative_to(root).as_posix()
        base: dict[str, object] = {"mode": _mode(file_stat), "path": relative_path}
        if stat.S_ISLNK(file_stat.st_mode):
            entries.append(base | {"target": os.readlink(path), "type": "symlink"})
        elif stat.S_ISDIR(file_stat.st_mode):
            entries.append(base | {"type": "directory"})
            with os.scandir(path) as directory_entries:
                children = [path / item.name for item in directory_entries]
            pending.extend(children)
        elif stat.S_ISREG(file_stat.st_mode):
            entries.append(
                base
                | {
                    "sha256": _regular_file_sha256(path, file_stat),
                    "size": file_stat.st_size,
                    "type": "file",
                }
            )
        else:
            raise ValueError(f"unsupported app bundle entry type: {path}")
    entries.sort(key=lambda item: str(item["path"]))
    return entries


def canonical_manifest_bytes(entries: list[dict[str, object]]) -> bytes:
    lines = [
        json.dumps(entry, ensure_ascii=True, sort_keys=True, separators=(",", ":"))
        for entry in entries
    ]
    return ("\n".join(lines) + "\n").encode("ascii")


def bundle_manifest_snapshot(raw_root: Path) -> dict[str, object]:
    root = validate_bundle_root(raw_root)
    entries = bundle_manifest_entries(root)
    data = canonical_manifest_bytes(entries)
    return {
        "root": str(root),
        "count": len(entries),
        "sha256": hashlib.sha256(data).hexdigest(),
        "data": data,
    }


def write_bundle_manifest(raw_root: Path, raw_output: Path) -> dict[str, object]:
    snapshot = bundle_manifest_snapshot(raw_root)
    root = Path(str(snapshot["root"]))
    output = _lexical_absolute(raw_output)
    _reject_symlink_components(output.parent, "manifest output")
    if not output.parent.is_dir():
        raise ValueError(f"manifest output parent must be a real directory: {output.parent}")
    if output.is_symlink():
        raise ValueError(f"manifest output must not be a symlink: {output}")
    if output == root or root in output.parents:
        raise ValueError("manifest output must be outside the app bundle")

    temporary_path: Path | None = None
    try:
        descriptor, temporary = tempfile.mkstemp(prefix=f".{output.name}.", dir=output.parent)
        temporary_path = Path(temporary)
        with os.fdopen(descriptor, "wb") as stream:
            stream.write(bytes(snapshot["data"]))
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temporary_path, 0o644)
        os.replace(temporary_path, output)
        temporary_path = None
    finally:
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)
    return {key: value for key, value in snapshot.items() if key != "data"} | {"manifest": str(output)}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    arguments = parser.parse_args()
    result = write_bundle_manifest(arguments.app, arguments.output)
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))


if __name__ == "__main__":
    main()
