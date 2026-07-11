#!/usr/bin/env python3
"""Read-only consistency checks for the repository's licensing documents."""

from pathlib import Path
from datetime import date, datetime, timezone
import hashlib
import re
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[1]
ATTESTATION_FIELDS = {
    "Evidence-ID", "Evidence-Type", "Original-SHA256", "Reviewed-At", "Reviewer",
    "Private-Storage-Reference", "Redaction-Checked", "Finding",
}
MANAGEMENT_FILES = {"README.md", "OWNER_EVIDENCE_REQUEST.md"}
EXPECTED_AUDIO = {
    "opening_bgm.mp3", "アタリ_ヒット音.mp3", "外海・回遊ルート.mp3",
    "岩礁・消波ブロック.mp3", "水中ファイト通常.mp3", "海辺（さざなみ）.mp3",
    "海辺（少し風が強い）.mp3", "港外・潮目.mp3", "砂浜・かけあがり.mp3",
    "逃げられた.mp3",
}


def require_file(relative: str) -> str:
    path = ROOT / relative
    if not path.is_file():
        raise AssertionError(f"missing required file: {relative}")
    return path.read_text(encoding="utf-8")


def require_calendar_date(value: str, label: str) -> date:
    value = value.strip()
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", value):
        raise AssertionError(f"invalid {label} format (expected YYYY-MM-DD): {value}")
    try:
        return date.fromisoformat(value)
    except ValueError as exc:
        raise AssertionError(f"invalid {label}: {value}") from exc


def parse_attestation(path: Path) -> dict[str, str]:
    assert path.is_file(), f"attestation is not a regular file: {path}"
    text = path.read_text(encoding="utf-8")
    assert text.strip(), f"attestation is empty: {path}"
    prohibited = (
        (r"https?://|file://|s3://", "URL"),
        (r"\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b", "email"),
        (r"\b(?:account|invoice|payment|transaction|order|card)[-_ ]?(?:id|number|last4)\s*:", "identifier"),
        (r"\b\d{12,19}\b", "long payment-like number"),
    )
    for pattern, label in prohibited:
        assert not re.search(pattern, text, flags=re.IGNORECASE), f"attestation contains prohibited {label}: {path}"
    fields: dict[str, str] = {}
    for line in text.splitlines():
        match = re.fullmatch(r"([A-Za-z0-9-]+):\s*(.+)", line)
        if match:
            fields[match.group(1)] = match.group(2).strip()
    assert ATTESTATION_FIELDS <= fields.keys(), (
        f"attestation fields missing: {sorted(ATTESTATION_FIELDS - fields.keys())} in {path}"
    )
    assert re.fullmatch(r"U-(?:0[1-6]|08)", fields["Evidence-ID"]), f"invalid Evidence-ID: {path}"
    assert re.fullmatch(r"[0-9a-f]{64}", fields["Original-SHA256"]), f"invalid original SHA-256: {path}"
    assert len(set(fields["Original-SHA256"])) >= 5, f"placeholder original SHA-256: {path}"
    reviewed_at = require_calendar_date(fields["Reviewed-At"], f"Reviewed-At in {path}")
    assert reviewed_at <= date.today(), f"future Reviewed-At in {path}: {reviewed_at}"
    assert re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{1,63}", fields["Reviewer"]), (
        f"Reviewer must be a non-secret role/ID: {path}"
    )
    assert re.fullmatch(r"[A-Z0-9][A-Z0-9._-]{2,63}", fields["Private-Storage-Reference"]), (
        f"Private-Storage-Reference must be a non-secret management ID: {path}"
    )
    assert not re.search(
        r"(?:^|[-_.])(?:ACCOUNT|BILLING|BILL|INVOICE|PAYMENT|TRANSACTION|ORDER|RECEIPT|CARD|LAST4)(?=[-_.\d]|$)",
        fields["Private-Storage-Reference"],
    ), f"Private-Storage-Reference contains a prohibited billing/account identifier: {path}"
    assert fields["Redaction-Checked"] == "true", f"redaction must be confirmed: {path}"
    assert len(fields["Finding"]) >= 10, f"finding too short: {path}"
    return fields


def audit_evidence_tree(evidence_root: Path) -> dict[Path, dict[str, str]]:
    """Reject raw/private evidence anywhere under the public licensing tree."""
    assert evidence_root.is_dir() and not evidence_root.is_symlink(), f"invalid evidence root: {evidence_root}"
    attestation_root = evidence_root / "attestations"
    parsed: dict[Path, dict[str, str]] = {}
    for path in evidence_root.rglob("*"):
        assert not path.is_symlink(), f"symlink forbidden in licensing evidence tree: {path}"
        relative = path.relative_to(evidence_root)
        if path.is_dir():
            assert relative == Path("attestations"), f"unexpected directory in licensing evidence tree: {relative}"
            continue
        assert path.is_file(), f"non-regular entry in licensing evidence tree: {relative}"
        if relative.parent == Path("."):
            assert relative.name in MANAGEMENT_FILES, f"raw/unknown evidence file forbidden: {relative}"
            continue
        assert relative.parent == Path("attestations"), f"nested evidence path forbidden: {relative}"
        if relative.name == ".gitkeep":
            continue
        assert re.fullmatch(r"U-(?:0[1-6]|08)_[A-Za-z0-9._-]+\.md", relative.name), (
            f"attestation filename must be U-XX_*.md: {relative}"
        )
        fields = parse_attestation(path)
        assert relative.name.startswith(f"{fields['Evidence-ID']}_"), f"filename/ID mismatch: {relative}"
        parsed[path.resolve()] = fields
    return parsed


def audit_rights_state(open_ids: set[str], completed_ids: set[str], v2_overview: str) -> None:
    if "U-02" in completed_ids:
        assert "U-01" in completed_ids, "U-02 cannot complete before U-01"
    expected_state = "complete" if not open_ids else "pending"
    markers = re.findall(r"\[RIGHTS-01A\]=(pending|complete)", v2_overview)
    assert markers == [expected_state], (
        f"docs/30 RIGHTS-01A state mismatch: expected={expected_state}, found={markers}"
    )


def audit_completion_dependencies(completed_ids: set[str]) -> None:
    if "U-02" in completed_ids:
        assert "U-01" in completed_ids, "U-02 cannot complete before U-01"
    if "U-08" in completed_ids:
        assert {"U-01", "U-03"} <= completed_ids, "U-08 cannot complete before U-01 and U-03"


def audit_ledger_evidence_state(evidence_id: str, is_open: bool, ledger: str) -> None:
    pending_tokens = {
        "U-01": ("U-01待ち", "加入期間証拠待ち"),
        "U-02": ("U-02待ち", "加入期間証拠待ち"),
        "U-03": ("U-03待ち",),
        "U-04": ("権利者申告待ち（証拠index U-04）",),
        "U-05": ("ユーザー入力待ち（証拠index U-05）",),
        "U-06": ("未完（証拠index U-06）",),
        "U-08": ("U-08待ち",),
    }[evidence_id]
    resolved_token = f"{evidence_id}解決済み"
    if is_open:
        assert all(token in ledger for token in pending_tokens), (
            f"open {evidence_id} lacks substantive pending ledger prose: {pending_tokens}"
        )
        assert resolved_token not in ledger, f"open {evidence_id} has stale resolved ledger prose"
    else:
        assert all(token not in ledger for token in pending_tokens), (
            f"completed {evidence_id} retains stale pending ledger prose: {pending_tokens}"
        )
        assert resolved_token in ledger, f"completed {evidence_id} lacks substantive resolved ledger prose"


def parse_generated_at(value: str, label: str) -> datetime:
    assert re.fullmatch(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:Z|[+-]\d{2}:\d{2})", value), (
        f"invalid {label} format (expected timezone-qualified RFC3339 seconds): {value}"
    )
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as exc:
        raise AssertionError(f"invalid {label}: {value}") from exc
    assert parsed <= datetime.now(timezone.utc), f"future {label}: {value}"
    return parsed


def validate_u01_tracks(fields: dict[str, str], label: str) -> list[datetime]:
    assert fields.get("Asset-Count") == "10", f"U-01 Asset-Count must be 10: {label}"
    tracks: dict[str, tuple[datetime, str]] = {}
    mapping_ids: set[str] = set()
    for number in range(1, 11):
        value = fields.get(f"Track-{number:02d}", "")
        parts = [part.strip() for part in value.split(";")]
        assert len(parts) == 3, f"U-01 Track-{number:02d} must be filename;generated-at;mapping-id: {label}"
        filename, generated_at_raw, mapping_id = parts
        assert filename in EXPECTED_AUDIO and filename not in tracks, f"U-01 invalid/duplicate filename: {filename}"
        generated_at = parse_generated_at(generated_at_raw, f"U-01 generated-at for {filename}")
        assert re.fullmatch(r"[A-Z0-9][A-Z0-9._-]{2,63}", mapping_id), (
            f"U-01 mapping ID must be a non-secret management ID: {filename}"
        )
        assert mapping_id not in mapping_ids, f"U-01 duplicate mapping ID: {mapping_id}"
        tracks[filename] = (generated_at, mapping_id)
        mapping_ids.add(mapping_id)
    assert set(tracks) == EXPECTED_AUDIO, f"U-01 must cover exactly all 10 audio files: {label}"
    assert fields.get("One-to-One-Mapping-Verified") == "true", f"U-01 mapping is not verified: {label}"
    return [tracks[name][0] for name in sorted(tracks)]


def validate_u02_period(fields: dict[str, str], label: str) -> tuple[date, date]:
    assert fields.get("Plan") in {"Pro", "Premier"}, f"invalid Suno plan: {label}"
    period_start = require_calendar_date(fields.get("Period-Start", ""), f"Period-Start in {label}")
    period_end = require_calendar_date(fields.get("Period-End", ""), f"Period-End in {label}")
    assert period_start <= period_end, f"invalid Suno paid period order: {label}"
    assert fields.get("Covers-U-01") == "true", f"U-02 does not declare U-01 coverage: {label}"
    return period_start, period_end


def cross_check_u02_covers_u01(u01_fields: dict[str, str], u02_fields: dict[str, str], label: str) -> None:
    generated = validate_u01_tracks(u01_fields, label)
    period_start, period_end = validate_u02_period(u02_fields, label)
    # Subscription evidence uses calendar dates. Compare each generation's calendar date in its recorded offset.
    generated_dates = [value.date() for value in generated]
    assert period_start <= min(generated_dates) and max(generated_dates) <= period_end, (
        f"U-02 paid period does not contain U-01 local generated dates: "
        f"{period_start}..{period_end} vs {min(generated_dates)}..{max(generated_dates)}"
    )


def build_u03_population(root: Path) -> list[str]:
    tracked = subprocess.run(
        ["git", "ls-files"], cwd=root, check=True, capture_output=True, text=True
    ).stdout.splitlines()
    prefixes = ("assets/showcase/", "tools/source_assets/", "reference/")
    return sorted(path for path in tracked if path.startswith(prefixes) and Path(path).suffix.lower() == ".png")


def manifest_sha256(items: list[str]) -> str:
    return hashlib.sha256(("\n".join(items) + "\n").encode("utf-8")).hexdigest()


def validate_u03_manifest(fields: dict[str, str], population: list[str], label: str) -> None:
    assert fields.get("Inventory-Contract") == "docs/31 sections 2.2 and 4", (
        f"U-03 inventory contract mismatch: {label}"
    )
    assert fields.get("Population-Count") == str(len(population)), f"U-03 population count mismatch: {label}"
    assert fields.get("Population-SHA256") == manifest_sha256(population), f"U-03 population hash mismatch: {label}"
    covered: set[str] = set()
    referenced_provenance_ids: set[str] = set()
    for number in range(1, len(population) + 1):
        parts = [part.strip() for part in fields.get(f"Item-{number:04d}", "").split(";")]
        assert len(parts) == 3, f"U-03 Item-{number:04d} requires path;disposition;provenance-id: {label}"
        path, disposition, provenance_id = parts
        assert path in population and path not in covered, f"U-03 invalid/duplicate path: {path}"
        assert disposition in {"procedural", "ai-generated", "source-derived", "reference-only", "rejected"}, (
            f"U-03 invalid disposition for {path}: {disposition}"
        )
        assert re.fullmatch(r"[A-Z0-9][A-Z0-9._-]{2,63}", provenance_id), (
            f"U-03 invalid provenance ID for {path}"
        )
        covered.add(path)
        referenced_provenance_ids.add(provenance_id)
    assert covered == set(population), f"U-03 manifest does not cover current population: {label}"
    try:
        provenance_count = int(fields.get("Provenance-Count", ""))
    except ValueError as exc:
        raise AssertionError(f"U-03 invalid Provenance-Count: {label}") from exc
    provenance_records: set[str] = set()
    for number in range(1, provenance_count + 1):
        parts = [part.strip() for part in fields.get(f"Provenance-{number:04d}", "").split(";")]
        assert len(parts) == 5, (
            f"U-03 Provenance-{number:04d} requires id;service;generated-start;generated-end;creator-id: {label}"
        )
        provenance_id, service, generated_start_raw, generated_end_raw, creator_id = parts
        assert provenance_id in referenced_provenance_ids and provenance_id not in provenance_records, (
            f"U-03 invalid/duplicate provenance record ID: {provenance_id}"
        )
        assert re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{2,63}", service), (
            f"U-03 invalid generation service: {service}"
        )
        generated_start = parse_generated_at(generated_start_raw, f"U-03 generated-start for {provenance_id}")
        generated_end = parse_generated_at(generated_end_raw, f"U-03 generated-end for {provenance_id}")
        assert generated_start <= generated_end, f"U-03 generation range reversed: {provenance_id}"
        assert re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{2,63}", creator_id), (
            f"U-03 creator must be a non-secret role/ID: {provenance_id}"
        )
        provenance_records.add(provenance_id)
    assert provenance_records == referenced_provenance_ids, (
        f"U-03 provenance records do not resolve all item IDs: "
        f"missing={sorted(referenced_provenance_ids - provenance_records)}, "
        f"extra={sorted(provenance_records - referenced_provenance_ids)}"
    )
    assert fields.get("Unresolved-Items") == "0" and fields.get("Provenance-Complete") == "true", (
        f"U-03 provenance is incomplete: {label}"
    )


def validate_u08_manifest(fields: dict[str, str], population: list[str], label: str) -> None:
    combined = sorted(EXPECTED_AUDIO | set(population))
    assert fields.get("Covered-Media") == "suno-and-ai-images", f"U-08 media coverage incomplete: {label}"
    assert fields.get("Population-Count") == str(len(combined)), f"U-08 population count mismatch: {label}"
    assert fields.get("Population-SHA256") == manifest_sha256(combined), f"U-08 population hash mismatch: {label}"
    covered: set[str] = set()
    for number in range(1, len(combined) + 1):
        parts = [part.strip() for part in fields.get(f"Item-{number:04d}", "").split(";")]
        assert len(parts) == 3, f"U-08 Item-{number:04d} requires asset;status;rights-id: {label}"
        asset, status, rights_id = parts
        assert asset in combined and asset not in covered, f"U-08 invalid/duplicate asset: {asset}"
        assert status in {"none", "cleared"}, f"U-08 invalid input-rights status for {asset}: {status}"
        assert re.fullmatch(r"[A-Z0-9][A-Z0-9._-]{2,63}", rights_id), f"U-08 invalid rights ID: {asset}"
        covered.add(asset)
    assert covered == set(combined), f"U-08 manifest does not cover U-01/U-03 populations: {label}"
    assert fields.get("Clearance-Complete") == "true", f"U-08 clearance incomplete: {label}"


def validate_u04_rejected(
    fields: dict[str, str], relative: str, saved_paths: list[str],
    parsed_attestations: dict[Path, dict[str, str]], ledger: str,
    project_config: str, root: Path,
) -> None:
    assert fields.get("Replacement-Integrated") == "true", f"U-04 replacement is not integrated: {relative}"
    replacement_product_path = fields.get("Replacement-Product-Path", "")
    assert replacement_product_path and replacement_product_path != "assets/icon.svg", (
        f"U-04 replacement product path is invalid: {relative}"
    )
    replacement_path = (root / replacement_product_path).resolve()
    assert replacement_path.is_file() and root.resolve() in replacement_path.parents, (
        f"U-04 replacement product file missing: {replacement_product_path}"
    )
    assert re.search(
        rf'^config/icon\s*=\s*"res://{re.escape(replacement_product_path)}"\s*$',
        project_config,
        flags=re.MULTILINE,
    ), (
        f"U-04 replacement is not wired in project.godot: {replacement_product_path}"
    )
    assert replacement_product_path in ledger, (
        f"U-04 replacement is not recorded in asset ledger: {replacement_product_path}"
    )
    assert "[RIGHTS-01A:U-04-REPLACEMENT]=integrated" in ledger, (
        "U-04 replacement ledger integration marker missing"
    )
    replacement_attestation_relative = fields.get("Replacement-Rights-Attestation", "")
    assert replacement_attestation_relative in saved_paths, (
        f"U-04 replacement rights attestation is not referenced by completed row: {relative}"
    )
    replacement_attestation_path = (root / replacement_attestation_relative).resolve()
    replacement_fields = parsed_attestations.get(replacement_attestation_path)
    assert replacement_fields and replacement_fields.get("Evidence-ID") == "U-04", (
        f"U-04 replacement rights attestation invalid: {replacement_attestation_relative}"
    )
    assert replacement_fields.get("Replacement-Asset-Rights-Verified") == "true", (
        f"U-04 replacement rights are not verified: {replacement_attestation_relative}"
    )


def run_negative_self_tests() -> None:
    def must_fail(label: str, operation) -> None:
        try:
            operation()
        except (AssertionError, UnicodeDecodeError):
            return
        raise AssertionError(f"negative fixture unexpectedly passed: {label}")

    for filename in (
        "billing.png", "invoice.pdf", "raw.txt", "mail.eml", "video.mp4",
        "archive.zip", "data.csv", "data.json", "unknown.bin",
    ):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            (root / filename).write_bytes(b"raw-private-evidence")
            must_fail(filename, lambda root=root: audit_evidence_tree(root))

    with tempfile.TemporaryDirectory() as temp_dir:
        temp_root = Path(temp_dir)
        root = temp_root / "evidence"
        root.mkdir()
        target = temp_root / "outside.txt"
        target.write_text("private", encoding="utf-8")
        link = root / "evidence-link"
        link.symlink_to(target)
        must_fail("symlink", lambda: audit_evidence_tree(root))

    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        attestations = root / "attestations"
        attestations.mkdir()
        unreferenced = attestations / "U-01_unreferenced.md"
        unreferenced.write_text("raw unreferenced evidence", encoding="utf-8")
        must_fail("unreferenced malformed md", lambda: audit_evidence_tree(root))

    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        attestations = root / "attestations"
        attestations.mkdir()
        private_path = attestations / "U-01_private_path.md"
        private_path.write_text(
            "\n".join((
                "Evidence-ID: U-01", "Evidence-Type: suno-track-provenance",
                f"Original-SHA256: {'1234567890abcdef' * 4}", "Reviewed-At: 2026-07-11",
                "Reviewer: reviewer-1", "Private-Storage-Reference: ../private/path",
                "Redaction-Checked: true", "Finding: sanitized finding only",
            )), encoding="utf-8",
        )
        must_fail("private storage path", lambda: audit_evidence_tree(root))

    for private_reference in ("INVOICE-12345", "INVOICE12345", "ACCOUNT123", "BILLING-12345"):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            attestations = root / "attestations"
            attestations.mkdir()
            billing_id = attestations / "U-01_billing_id.md"
            billing_id.write_text(
                "\n".join((
                    "Evidence-ID: U-01", "Evidence-Type: suno-track-provenance",
                    f"Original-SHA256: {'1234567890abcdef' * 4}", "Reviewed-At: 2026-07-11",
                    "Reviewer: reviewer-1", f"Private-Storage-Reference: {private_reference}",
                    "Redaction-Checked: true", "Finding: sanitized finding only",
                )), encoding="utf-8",
            )
            must_fail(f"billing identifier {private_reference}", lambda root=root: audit_evidence_tree(root))

    must_fail(
        "U-02 before U-01",
        lambda: audit_rights_state({"U-01"}, {"U-02"}, "[RIGHTS-01A]=pending"),
    )
    must_fail(
        "docs/30 premature completion",
        lambda: audit_rights_state({"U-01"}, set(), "[RIGHTS-01A]=complete"),
    )
    must_fail(
        "U-04 rejected without replacement",
        lambda: validate_u04_rejected(
            {"Product-Decision": "rejected"}, "fixture", [], {}, "", "", ROOT,
        ),
    )
    must_fail(
        "U-08 dependencies pending",
        lambda: audit_completion_dependencies({"U-08"}),
    )
    must_fail(
        "U-03 generic flags without manifest",
        lambda: validate_u03_manifest(
            {"Inventory-Contract": "docs/31 sections 2.2 and 4", "Unresolved-Items": "0", "Provenance-Complete": "true"},
            ["assets/showcase/example.png"], "fixture",
        ),
    )
    one_item_population = ["assets/showcase/example.png"]
    must_fail(
        "U-03 item without provenance record",
        lambda: validate_u03_manifest(
            {
                "Inventory-Contract": "docs/31 sections 2.2 and 4",
                "Population-Count": "1", "Population-SHA256": manifest_sha256(one_item_population),
                "Item-0001": "assets/showcase/example.png;ai-generated;PROV-001",
                "Provenance-Count": "0", "Unresolved-Items": "0", "Provenance-Complete": "true",
            },
            one_item_population, "fixture",
        ),
    )
    must_fail(
        "U-08 generic flags without manifest",
        lambda: validate_u08_manifest(
            {"Covered-Media": "suno-and-ai-images", "Clearance-Complete": "true"}, [], "fixture",
        ),
    )
    must_fail(
        "ledger top marker only",
        lambda: audit_ledger_evidence_state("U-03", False, "[RIGHTS-01A:U-03]=complete"),
    )
    audit_ledger_evidence_state("U-03", False, "[RIGHTS-01A:U-03]=complete\nU-03解決済み")
    must_fail(
        "U-01 missing timestamp/mapping",
        lambda: validate_u01_tracks(
            {"Asset-Count": "10", "One-to-One-Mapping-Verified": "true"}, "fixture",
        ),
    )
    valid_u01 = {"Asset-Count": "10", "One-to-One-Mapping-Verified": "true"}
    for number, filename in enumerate(sorted(EXPECTED_AUDIO), start=1):
        valid_u01[f"Track-{number:02d}"] = f"{filename};2026-07-10T12:00:00+09:00;MAP-{number:02d}"
    must_fail(
        "U-02 period does not contain U-01",
        lambda: cross_check_u02_covers_u01(
            valid_u01,
            {"Plan": "Pro", "Period-Start": "2026-07-01", "Period-End": "2026-07-09", "Covers-U-01": "true"},
            "fixture",
        ),
    )
    print("licensing audit negative fixtures: ok (privacy tree/IDs, U-01 mapping, U-02 dependency/period, U-03/U-08 manifests, U-04, ledger/docs30 transitions)")


def main() -> int:
    try:
        license_text = require_file("LICENSE.md")
        notices = require_file("THIRD_PARTY_NOTICES.md")
        ledger = require_file("docs/31_asset_ledger.md")
        evidence = require_file("docs/qa/evidence/licensing/README.md")
        owner_request = require_file("docs/qa/evidence/licensing/OWNER_EVIDENCE_REQUEST.md")
        project_config = require_file("project.godot")
        project_overview = require_file("docs/00_プロジェクト概要.md")
        v2_overview = require_file("docs/30_v2_expansion_overview.md")
        line_seed_ofl = require_file("assets/fonts/line_seed/OFL.txt")
        mplus_ofl = require_file("assets/fonts/OFL-MPLUS1p.txt")

        for marker in ("## Scope", "Original project-owned visual and audio assets"):
            assert marker in license_text, f"LICENSE.md missing marker: {marker}"
        open_evidence_section = evidence.split("## ユーザー入力・保存待ち（未完了）", 1)[1]
        open_evidence_section = open_evidence_section.split("\n## ", 1)[0]
        evidence_ids = re.findall(r"^\| (U-\d{2}) \|", open_evidence_section, flags=re.MULTILINE)
        assert len(evidence_ids) == len(set(evidence_ids)), f"duplicate evidence IDs: {evidence_ids}"
        completed_evidence_section = evidence.split("## RIGHTS-01A完了済み", 1)[1]
        completed_evidence_section = completed_evidence_section.split("\n## ", 1)[0]
        completed_evidence_ids = re.findall(
            r"^\| (U-\d{2}) \|", completed_evidence_section, flags=re.MULTILINE
        )
        assert len(completed_evidence_ids) == len(set(completed_evidence_ids)), (
            f"duplicate completed evidence IDs: {completed_evidence_ids}"
        )
        assert not (set(evidence_ids) & set(completed_evidence_ids)), (
            f"evidence IDs cannot be both open and complete: "
            f"{sorted(set(evidence_ids) & set(completed_evidence_ids))}"
        )
        completed_rows = re.findall(
            r"^\| (U-\d{2}) \| ([^|]+) \| ([^|]+) \|$",
            completed_evidence_section,
            flags=re.MULTILINE,
        )
        assert len(completed_rows) == len(completed_evidence_ids), (
            "completed evidence rows require non-empty close date and saved-evidence judgment"
        )
        evidence_root = (ROOT / "docs/qa/evidence/licensing").resolve()
        attestation_root = (evidence_root / "attestations").resolve()
        parsed_attestations = audit_evidence_tree(evidence_root)
        u03_population = build_u03_population(ROOT)
        non_evidence_management_files = {
            (evidence_root / "README.md").resolve(),
            (evidence_root / "OWNER_EVIDENCE_REQUEST.md").resolve(),
        }
        completed_fields: dict[str, list[dict[str, str]]] = {}
        for evidence_id, close_date, saved_evidence in completed_rows:
            parsed_close_date = require_calendar_date(close_date, f"close date for {evidence_id}")
            assert parsed_close_date <= date.today(), f"future close date for {evidence_id}: {parsed_close_date}"
            saved_paths = re.findall(r"`([^`]+)`", saved_evidence)
            assert saved_paths, f"completed {evidence_id} requires a backticked saved evidence path"
            matching_attestations = 0
            for relative in saved_paths:
                saved_path = (ROOT / relative).resolve()
                assert attestation_root in saved_path.parents, (
                    f"completed {evidence_id} evidence must be under attestations/: {relative}"
                )
                assert saved_path not in non_evidence_management_files, (
                    f"completed {evidence_id} cannot cite a management file as evidence: {relative}"
                )
                assert saved_path.is_file(), f"completed {evidence_id} evidence file missing: {relative}"
                assert saved_path.suffix == ".md" and saved_path.name.startswith(f"{evidence_id}_"), (
                    f"completed {evidence_id} attestation must be U-XX_*.md: {relative}"
                )
                assert saved_path in parsed_attestations, f"unvalidated attestation referenced: {relative}"
                attestation = saved_path.read_text(encoding="utf-8")
                assert attestation.strip(), f"completed {evidence_id} attestation is empty: {relative}"
                fields = {}
                for line in attestation.splitlines():
                    match = re.fullmatch(r"([A-Za-z0-9-]+):\s*(.+)", line)
                    if match:
                        fields[match.group(1)] = match.group(2).strip()
                required_fields = {
                    "Evidence-ID",
                    "Evidence-Type",
                    "Original-SHA256",
                    "Reviewed-At",
                    "Reviewer",
                    "Private-Storage-Reference",
                    "Redaction-Checked",
                    "Finding",
                }
                assert required_fields <= fields.keys(), (
                    f"attestation fields missing for {evidence_id}: "
                    f"{sorted(required_fields - fields.keys())} in {relative}"
                )
                assert fields["Evidence-ID"] == evidence_id, (
                    f"attestation ID mismatch for {evidence_id}: {relative}"
                )
                allowed_types = {
                    "U-01": {"suno-track-provenance"},
                    "U-02": {"suno-paid-period"},
                    "U-03": {"ai-image-provenance"},
                    "U-04": {"icon-rights"},
                    "U-05": {"license-holder"},
                    "U-06": {"trademark-clearance"},
                    "U-08": {"ai-input-rights"},
                }
                assert fields["Evidence-Type"] in allowed_types[evidence_id], (
                    f"invalid evidence type for {evidence_id}: {fields['Evidence-Type']}"
                )
                assert re.fullmatch(r"[0-9a-f]{64}", fields["Original-SHA256"]), (
                    f"invalid original SHA-256 for {evidence_id}: {relative}"
                )
                assert len(set(fields["Original-SHA256"])) >= 5, (
                    f"placeholder original SHA-256 for {evidence_id}: {relative}"
                )
                reviewed_at = require_calendar_date(fields["Reviewed-At"], f"Reviewed-At for {evidence_id}")
                assert reviewed_at <= date.today(), f"future Reviewed-At for {evidence_id}: {reviewed_at}"
                assert reviewed_at <= parsed_close_date, (
                    f"review date after close date for {evidence_id}: {reviewed_at} > {parsed_close_date}"
                )
                assert len(fields["Reviewer"]) >= 2, f"missing reviewer for {evidence_id}: {relative}"
                private_reference = fields["Private-Storage-Reference"]
                assert len(private_reference) >= 3 and "://" not in private_reference, (
                    f"private storage reference must be a non-secret ID, not URL: {relative}"
                )
                assert fields["Redaction-Checked"] == "true", (
                    f"redaction must be confirmed for {evidence_id}: {relative}"
                )
                assert len(fields["Finding"]) >= 10, f"finding too short for {evidence_id}: {relative}"
                if evidence_id == "U-01":
                    validate_u01_tracks(fields, relative)
                elif evidence_id == "U-02":
                    validate_u02_period(fields, relative)
                elif evidence_id == "U-03":
                    validate_u03_manifest(fields, u03_population, relative)
                elif evidence_id == "U-04":
                    assert fields.get("Product-Decision") in {"adopted", "rejected"}, (
                        f"U-04 product decision missing: {relative}"
                    )
                    if fields["Product-Decision"] == "adopted":
                        assert re.search(
                            r'^config/icon\s*=\s*"res://assets/icon\.svg"\s*$',
                            project_config,
                            flags=re.MULTILINE,
                        ), "U-04 adopted decision requires assets/icon.svg as project config/icon"
                        assert fields.get("Author-Verified") == "true" and fields.get("Rights-Holder-Verified") == "true", (
                            f"U-04 adopted icon author/rights holder is not verified: {relative}"
                        )
                    else:
                        validate_u04_rejected(
                            fields, relative, saved_paths, parsed_attestations,
                            ledger, project_config, ROOT,
                        )
                elif evidence_id == "U-05":
                    assert fields.get("License-Holder-Matches-LICENSE") == "true", (
                        f"U-05 does not match LICENSE: {relative}"
                    )
                elif evidence_id == "U-06":
                    assert fields.get("Territories") and fields.get("Trademark-Classes"), (
                        f"U-06 territory/classes missing: {relative}"
                    )
                    assert fields.get("Official-DB") and "://" not in fields["Official-DB"], (
                        f"U-06 official DB must be named without secret URL: {relative}"
                    )
                    try:
                        search_date = require_calendar_date(fields.get("Search-Date", ""), f"Search-Date in {relative}")
                        result_count = int(fields.get("Result-Count", ""))
                    except ValueError as exc:
                        raise AssertionError(f"invalid U-06 search payload: {relative}") from exc
                    assert search_date <= date.today() and result_count >= 0, f"invalid U-06 results: {relative}"
                    assert fields.get("Expert-Review") in {"completed", "not-required"}, (
                        f"U-06 expert review decision missing: {relative}"
                    )
                elif evidence_id == "U-08":
                    validate_u08_manifest(fields, u03_population, relative)
                completed_fields.setdefault(evidence_id, []).append(fields)
                matching_attestations += 1
            assert matching_attestations > 0, f"completed {evidence_id} requires a valid attestation"
        unresolved_holder = "RIGHTS HOLDER NAME" in license_text
        rights_01a_ids = {"U-01", "U-02", "U-03", "U-04", "U-05", "U-06", "U-08"}
        classified_ids = set(evidence_ids) | set(completed_evidence_ids)
        assert classified_ids == rights_01a_ids, (
            f"RIGHTS-01A evidence classification mismatch: "
            f"missing={sorted(rights_01a_ids - classified_ids)}, "
            f"unexpected={sorted(classified_ids - rights_01a_ids)}"
        )
        audit_rights_state(set(evidence_ids), set(completed_evidence_ids), v2_overview)
        audit_completion_dependencies(set(completed_evidence_ids))
        if "U-02" in completed_evidence_ids:
            assert completed_fields.get("U-01") and completed_fields.get("U-02"), (
                "U-01/U-02 completed attestations missing for coverage cross-check"
            )
            cross_check_u02_covers_u01(
                completed_fields["U-01"][0], completed_fields["U-02"][0], "completed U-01/U-02",
            )

        for evidence_id in sorted(rights_01a_ids):
            expected_state = "pending" if evidence_id in evidence_ids else "complete"
            expected_marker = f"[RIGHTS-01A:{evidence_id}]={expected_state}"
            opposite_state = "complete" if expected_state == "pending" else "pending"
            opposite_marker = f"[RIGHTS-01A:{evidence_id}]={opposite_state}"
            assert expected_marker in ledger, f"asset ledger missing state marker: {expected_marker}"
            assert opposite_marker not in ledger, f"asset ledger has stale state marker: {opposite_marker}"
            audit_ledger_evidence_state(evidence_id, evidence_id in evidence_ids, ledger)

        if unresolved_holder:
            assert "U-05" in evidence_ids, "unresolved LICENSE holder requires open U-05"
            assert "legal rights holder remains a\nrelease blocker" in license_text, (
                "unresolved LICENSE holder must retain the release-blocker statement"
            )
        else:
            assert "U-05" not in evidence_ids, "resolved LICENSE holder requires U-05 removal"
            assert "placeholder" not in license_text.lower(), "resolved LICENSE must remove placeholder prose"
            assert "legal rights holder remains a\nrelease blocker" not in license_text, (
                "resolved LICENSE must remove holder release-blocker prose"
            )
            copyright_line = next(
                (line for line in license_text.splitlines() if line.startswith("Copyright (c) 2026 ")),
                "",
            )
            assert re.fullmatch(r"Copyright \(c\) 2026 \S.*", copyright_line), "invalid copyright holder line"
        for marker in ("Godot Engine", "LINE Seed JP", "M PLUS 1p"):
            assert marker in notices, f"THIRD_PARTY_NOTICES.md missing: {marker}"
        for marker in ("Engine.get_license_text()", "Engine.get_license_info()", "Engine.get_copyright_info()"):
            assert marker in notices, f"Godot notice extraction method missing: {marker}"
        for marker in ("Copyright 2020-2022 LY Corporation", "SIL OPEN FONT LICENSE Version 1.1"):
            assert marker in line_seed_ofl, f"LINE Seed OFL missing: {marker}"
        for marker in ("Copyright 2016 The M+ Project Authors", "SIL OPEN FONT LICENSE Version 1.1"):
            assert marker in mplus_ofl, f"M PLUS OFL missing: {marker}"
        for marker in ("ユーザー入力・保存待ち",):
            assert marker in evidence, f"licensing evidence index missing: {marker}"
        for evidence_id in sorted(evidence_ids):
            assert evidence_id in owner_request, (
                f"owner evidence request missing unresolved item: {evidence_id}"
            )
        rights_01b_section = evidence.split("## RIGHTS-01B:", 1)[1]
        assert re.search(r"^\| U-07 \|", rights_01b_section, flags=re.MULTILINE), (
            "RIGHTS-01B evidence table missing U-07"
        )
        for audio_name in (
            "opening_bgm.mp3",
            "アタリ_ヒット音.mp3",
            "外海・回遊ルート.mp3",
            "岩礁・消波ブロック.mp3",
            "水中ファイト通常.mp3",
            "海辺（さざなみ）.mp3",
            "海辺（少し風が強い）.mp3",
            "港外・潮目.mp3",
            "砂浜・かけあがり.mp3",
            "逃げられた.mp3",
        ):
            assert audio_name in owner_request, f"Suno evidence request missing track: {audio_name}"
        for marker in ("RIGHTS-01Bへ分離", "RIGHTS-01Bへ送る項目"):
            assert marker in evidence or marker in owner_request, f"RIGHTS-01B boundary missing: {marker}"

        release_markers = ("釣りクエスト ～海釣り編～", "itch.io", "macOS Universal")
        for marker in release_markers:
            assert marker in project_overview, f"project overview missing Gate 0 value: {marker}"
            assert marker in v2_overview, f"V2 overview missing Gate 0 value: {marker}"
            assert marker in ledger, f"asset ledger not synchronized with Gate 0: {marker}"
            assert marker in evidence, f"licensing evidence not synchronized with Gate 0: {marker}"
        for marker in ("itch.io", "macOS Universal"):
            assert marker in notices, f"third-party notices not synchronized with Gate 0: {marker}"
        stale_gate_zero_markers = (
            "正式名称・販売地域・対象区分が未決",
            "チャネル/OS決定待ち",
            "販売チャネル未決",
            "チャネル決定後の提出・保存待ち",
        )
        licensing_docs = "\n".join((ledger, evidence, notices))
        for marker in stale_gate_zero_markers:
            assert marker not in licensing_docs, f"stale pre-Gate-0 licensing text remains: {marker}"
        for marker in (
            "THIRD_PARTY_NOTICES.md",
            "Pre-Generated AI",
            "source-consuming pipeline",
            "source/reference-consuming",
        ):
            assert marker in ledger, f"asset ledger missing: {marker}"

        reference_pipeline_contract = {
            "tools/process_underwater_fish_assets.py": (
                "reference/02_underwater_fight_mockup.png",
                "hit_badge_full.png",
                "hud_key_minus.png",
            ),
            "tools/generate_underwater_ui_frame_assets.py": (
                "reference/02_underwater_fight_mockup.png",
                "fight_action_card_icon.png",
                "fight_tackle_card_icon.png",
            ),
            "tools/extract_top_status_icons.py": (
                "reference/02_underwater_fight_mockup.png",
                "top_status_icon_sheet.png",
            ),
            "tools/generate_cooking_showcase_assets.py": (
                "reference/cooking_flow/01_cook_select_concept.png",
                "dish_feature_aji_shioyaki.png",
                "meal_table_spread.png",
            ),
        }
        for script, markers in reference_pipeline_contract.items():
            script_text = require_file(script)
            assert "reference" in script_text and "Image.open" in script_text, (
                f"reference-consuming implementation changed: {script}"
            )
            assert Path(script).name in ledger, f"reference-consuming script missing from ledger: {script}"
            for marker in markers:
                assert marker in ledger, f"reference pipeline marker missing from ledger: {marker}"

        ledger_lines = ledger.splitlines()
        current_bg_rows = [
            line for line in ledger_lines
            if "build_reference_underwater_background.py" in line and "underwater_battle_bg.png" in line
        ]
        assert len(current_bg_rows) == 1, f"expected one current underwater background row: {current_bg_rows}"
        current_bg_row = current_bg_rows[0]
        for marker in (
            "reference/02_underwater_fight_mockup.png",
            "underwater_center_paintover_candidate.png",
            "build_reference_underwater_background.py",
            "underwater_battle_bg.png",
            "現行採用済み",
        ):
            assert marker in current_bg_row, f"current underwater background relation missing: {marker}"
        for evidence_id in ("U-03", "U-08"):
            expected_row_marker = f"{evidence_id}待ち" if evidence_id in evidence_ids else f"{evidence_id}解決済み"
            assert expected_row_marker in current_bg_row, (
                f"current underwater background row state mismatch: {expected_row_marker}"
            )

        legacy_bg_rows = [
            line for line in ledger_lines
            if "enhance_underwater_battle_bg.py" in line and "underwater_battle_bg_source.png" in line
        ]
        assert len(legacy_bg_rows) == 1, f"expected one legacy underwater background row: {legacy_bg_rows}"
        legacy_bg_row = legacy_bg_rows[0]
        for marker in ("履歴上の旧採用経路", "現行", "未使用", "再採用時"):
            assert marker in legacy_bg_row, f"legacy underwater background relation missing: {marker}"

        current_bg_script = require_file("tools/build_reference_underwater_background.py")
        for marker in (
            'REFERENCE = ROOT / "reference" / "02_underwater_fight_mockup.png"',
            'GENERATED_CENTER_PAINTOVER = ROOT / "tools" / "source_assets" / "underwater_center_paintover_candidate.png"',
            "background = _add_generated_canvas_paintover",
            "background.save(OUTPUT",
        ):
            assert marker in current_bg_script, f"current underwater background code relation changed: {marker}"
        assert "不採用・製品未使用" in ledger, "harbor Phase B rejection is not recorded"
        harbor_qa = require_file("docs/qa/harbor_qa.md")
        assert "情報板外枠＋魚カード枠の Phase B AI一点物候補" in harbor_qa, (
            "harbor Phase B rejection evidence missing"
        )

        known_product_consumers = {
            "build_reference_underwater_background.py",
            "enhance_underwater_battle_bg.py",
            "extract_top_status_icons.py",
            "generate_cooking_showcase_assets.py",
            "generate_fishing_spot_map_assets.py",
            "generate_harbor_showcase_assets.py",
            "generate_megalodon_fish_assets.py",
            "generate_shark_fish_assets.py",
            "generate_tackle_shop_assets.py",
            "generate_title_showcase_assets.py",
            "generate_underwater_ui_frame_assets.py",
            "process_fishing_time_slot_assets.py",
            "process_harbor_info_board_assets.py",
            "process_harbor_plan_assets.py",
            "process_underwater_fish_assets.py",
        }
        known_non_product_or_intermediate_consumers = {
            "build_fight_full_static_compare.py",
            "build_fight_comparison_images.py",
            "build_fight_hud_static_compare.py",
            "build_fight_sidebar_static_compare.py",
            "build_fight_top_status_static_compare.py",
            "build_fish_asset_contact_sheet.py",
            "build_fish_book_portrait_contact_sheet.py",
            "build_fishing_spot_thumb_contact_sheet.py",
            "build_shark_pen_reference.py",
            "build_screen_visual_comparison.py",
            "generate_nushi_fish_assets.py",
        }
        detected_consumers = set()
        for path in (ROOT / "tools").glob("*.py"):
            if path.name == Path(__file__).name:
                continue
            script_text = path.read_text(encoding="utf-8")
            reads_external_image = "Image.open" in script_text and (
                "source_assets" in script_text or 'ROOT / "reference"' in script_text
            )
            if reads_external_image:
                detected_consumers.add(path.name)
        known_consumers = known_product_consumers | known_non_product_or_intermediate_consumers
        assert detected_consumers == known_consumers, (
            f"source/reference consumer inventory changed: "
            f"new={sorted(detected_consumers - known_consumers)}, "
            f"missing={sorted(known_consumers - detected_consumers)}"
        )
        for script_name in known_product_consumers:
            assert script_name in ledger, f"product consumer missing from ledger: {script_name}"

        expected_fonts = {
            "assets/fonts/line_seed/LINESeedJP_A_TTF_Rg.ttf",
            "assets/fonts/line_seed/LINESeedJP_A_TTF_Bd.ttf",
            "assets/fonts/line_seed/LINESeedJP_A_TTF_Eb.ttf",
            "assets/fonts/MPLUS1p-Regular.ttf",
            "assets/fonts/MPLUS1p-Bold.ttf",
            "assets/fonts/MPLUS1p-ExtraBold.ttf",
        }
        actual_fonts = {
            path.relative_to(ROOT).as_posix()
            for path in (ROOT / "assets/fonts").glob("**/*")
            if path.suffix.lower() in {".ttf", ".otf", ".woff", ".woff2"}
        }
        assert actual_fonts == expected_fonts, (
            f"font notice boundary mismatch: missing={sorted(expected_fonts - actual_fonts)}, "
            f"unreviewed={sorted(actual_fonts - expected_fonts)}"
        )
        for relative in expected_fonts:
            assert Path(relative).name in notices, f"font not enumerated in notices: {relative}"

        tracked = subprocess.run(
            ["git", "ls-files"], cwd=ROOT, check=True, capture_output=True, text=True
        ).stdout.splitlines()
        addon_entries = [path for path in tracked if path == "addons" or path.startswith("addons/")]
        native_extensions = [
            path for path in tracked if Path(path).suffix.lower() in {".gdextension", ".dll", ".so", ".dylib"}
        ]
        assert not addon_entries, f"unreviewed tracked Godot add-ons: {addon_entries}"
        assert not native_extensions, f"unreviewed tracked native dependencies: {native_extensions}"
    except AssertionError as exc:
        print(f"licensing audit: FAIL: {exc}", file=sys.stderr)
        return 1

    print("licensing audit: ok (document consistency; release blockers remain explicitly listed)")
    return 0


if __name__ == "__main__":
    if sys.argv[1:] == ["--self-test"]:
        run_negative_self_tests()
        raise SystemExit(0)
    assert not sys.argv[1:], f"unknown arguments: {sys.argv[1:]}"
    raise SystemExit(main())
