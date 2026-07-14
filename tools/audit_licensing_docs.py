#!/usr/bin/env python3
"""Read-only consistency checks for the repository's licensing documents."""

from pathlib import Path
from pathlib import PurePosixPath
from datetime import date, datetime, timezone
import hashlib
import html
import ipaddress
import io
import os
import re
import subprocess
import sys
import tempfile
import time
import unicodedata
from contextlib import redirect_stderr, redirect_stdout
from urllib.parse import unquote
from zoneinfo import ZoneInfo


ROOT = Path(__file__).resolve().parents[1]
RELEASE_TIME_ZONE = ZoneInfo("Asia/Tokyo")
KNOWN_ORIGINAL_ICON_SHA256 = "493a29b86943751f2441343ebc347a9fa42b046032dedd7d1fcb86fd51567595"
ATTESTATION_FIELDS = {
    "Evidence-ID", "Evidence-Type", "Original-SHA256", "Reviewed-At", "Reviewer",
    "Private-Storage-Reference", "Redaction-Checked", "Finding",
}
TYPE_SPECIFIC_FIELDS = {
    "suno-track-provenance": {"Asset-Count", "One-to-One-Mapping-Verified"},
    "suno-paid-period": {
        "Plan", "Period-Start", "Period-End", "Evidence-As-Of", "Covers-U-01",
    },
    "ai-image-provenance": {
        "Inventory-Contract", "Population-Count", "Population-SHA256",
        "Provenance-Count", "Unresolved-Items", "Provenance-Complete",
    },
    "icon-rights": {
        "Product-Decision", "Baseline-Original-Content-SHA256",
        "Product-Content-SHA256", "Author-Verified",
        "Rights-Holder-Verified", "Replacement-Integrated", "Replacement-Product-Path",
        "Replacement-Content-SHA256", "Replacement-Rights-Attestation",
    },
    "icon-replacement-rights": {
        "Replacement-Asset-Path", "Replacement-Content-SHA256",
        "Replacement-Asset-Rights-Verified",
    },
    "license-holder": {"License-Holder-Matches-LICENSE"},
    "trademark-clearance": {
        "Territories", "Trademark-Classes", "Official-DB", "Search-Date",
        "Result-Count", "Expert-Review",
    },
    "ai-input-rights": {
        "Covered-Media", "Population-Count", "Population-SHA256", "Clearance-Complete",
    },
}
EVIDENCE_ID_TYPES = {
    "U-01": {"suno-track-provenance"},
    "U-02": {"suno-paid-period"},
    "U-03": {"ai-image-provenance"},
    "U-04": {"icon-rights", "icon-replacement-rights"},
    "U-05": {"license-holder"},
    "U-06": {"trademark-clearance"},
    "U-08": {"ai-input-rights"},
}
FINDING_CODES = {
    "suno-track-provenance": "track-provenance-verified",
    "suno-paid-period": "paid-period-verified",
    "ai-image-provenance": "image-provenance-verified",
    "icon-rights": "icon-rights-verified",
    "icon-replacement-rights": "replacement-rights-verified",
    "license-holder": "license-holder-verified",
    "trademark-clearance": "trademark-clearance-reviewed",
    "ai-input-rights": "ai-input-rights-cleared",
}
MANAGEMENT_FILES = {
    "README.md", "OWNER_EVIDENCE_REQUEST.md", "2026-07-12_RIGHTS-01A_AUDIT.md",
}
OFFICIAL_PUBLIC_URLS = {
    "https://suno.com/terms/",
    "https://help.suno.com/en/articles/9601665",
    "https://help.suno.com/en/articles/2425729",
    "https://help.suno.com/en/articles/2410177",
    "https://openai.com/policies/terms-of-use/",
    "https://docs.godotengine.org/en/stable/about/complying_with_licenses.html",
    "https://partner.steamgames.com/doc/gettingstarted/contentsurvey",
    "https://www.j-platpat.inpit.go.jp/t0100",
    "https://www.j-platpat.inpit.go.jp/t1201",
}
SAFE_PUBLIC_SLASH_ENUMERATIONS = (
    "raw screenshot / screen recording / PDF / email / invoice / receipt",
    "raw screenshot/PDF/email/invoice",
)
ALLOWED_PUBLIC_BARE_DOMAINS = {"itch.io"}
ALLOWED_PUBLIC_DOTTED_NON_URLS = {
    "image.open", "license.md", "readme.md", "ofl.txt", "ofl-mplus1p.txt", "icon.svg",
    "net.physical-balance-lab.tsuri-quest-umi",
}
PUBLIC_REPO_FILE_SUFFIXES = {
    ".cfg", ".gd", ".godot", ".json", ".md", ".mp3", ".png", ".py", ".svg",
    ".tscn", ".ttf", ".txt", ".webp",
}
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


def release_today(now: datetime | None = None) -> date:
    """Return the release-audit date in the project's fixed Asia/Tokyo timezone."""
    instant = now if now is not None else datetime.now(timezone.utc)
    assert instant.tzinfo is not None, "release audit clock must be timezone-aware"
    return instant.astimezone(RELEASE_TIME_ZONE).date()


def normalize_public_text(text: str) -> str:
    """Decode nested entities/percent escapes and compatibility characters."""
    decoded = text
    for _ in range(32):
        compatibility_text = unicodedata.normalize("NFKC", decoded)
        unescaped = unquote(html.unescape(compatibility_text))
        if unescaped == decoded:
            break
        decoded = unescaped
    else:
        raise AssertionError("public licensing text contains excessive nested encoding")
    return decoded


def scan_public_text(
    text: str, path: Path, allow_official_urls: bool,
    allowed_repo_tokens: set[str] | None = None,
) -> None:
    normalized_text = normalize_public_text(text)
    for character in normalized_text:
        category = unicodedata.category(character)
        assert category != "Cf" and not (category == "Cc" and character not in "\n\r\t"), (
            f"Unicode format/control character forbidden in public licensing text: {path}"
        )
    assert not re.search(r"<!--|-->|</?[A-Za-z][^>]*>", normalized_text), (
        f"HTML tags/comments forbidden in public licensing text: {path}"
    )
    assert not re.search(r"(?<![A-Za-z0-9])(?:data|blob)\s*:", normalized_text, flags=re.IGNORECASE), (
        f"embedded data/blob URI forbidden in public licensing text: {path}"
    )
    urls = re.findall(
        r"(?<![A-Za-z0-9])(?:[a-z][a-z0-9+.-]{1,20}:)?//[^\s|<>()\[\]`\"'、。]+",
        normalized_text,
        flags=re.IGNORECASE,
    )
    if allow_official_urls:
        assert all(url in OFFICIAL_PUBLIC_URLS for url in urls), f"non-allowlisted URL in public licensing text: {path}"
    else:
        assert not urls, f"URL forbidden in attestation: {path}"
    text_without_urls = normalized_text
    for url in urls:
        text_without_urls = text_without_urls.replace(url, " " * len(url))
    bare_urls_with_paths = re.findall(
        r"(?<![A-Za-z0-9._-])(?:www\.)?(?:[A-Za-z0-9-]+\.)+[A-Za-z]{2,}"
        r"(?:/[^\s|<>()\[\]`\"'、。]+)+",
        text_without_urls,
        flags=re.IGNORECASE,
    )
    assert not bare_urls_with_paths, f"bare/non-allowlisted URL in public licensing text: {path}"
    for ipv4_match in re.finditer(
        r"(?<![A-Za-z0-9.])(?:\d{1,3}\.){3}\d{1,3}(?![A-Za-z0-9.])",
        text_without_urls,
    ):
        try:
            ipaddress.ip_address(ipv4_match.group(0))
        except ValueError:
            continue
        raise AssertionError(f"bare IP destination in public licensing text: {path}")
    for ipv6_match in re.finditer(r"\[([0-9A-Fa-f:.%]+)\]", text_without_urls):
        try:
            ipaddress.ip_address(ipv6_match.group(1).split("%", 1)[0])
        except ValueError:
            continue
        raise AssertionError(f"bare IPv6 destination in public licensing text: {path}")
    for ipv6_path_match in re.finditer(
        r"(?<![A-Za-z0-9_.%:-])"
        r"((?=[A-Fa-f0-9:]*:)[A-Fa-f0-9:]{2,}(?:%[A-Za-z0-9_.-]+)?)"
        r"(?![A-Za-z0-9_%:-])",
        text_without_urls,
    ):
        try:
            ipaddress.ip_address(ipv6_path_match.group(1).split("%", 1)[0])
        except ValueError:
            continue
        raise AssertionError(f"bare IPv6 destination in public licensing text: {path}")
    assert not re.search(
        r"(?<![A-Za-z0-9._-])localhost(?::\d{1,5})?(?:/[^\s|<>()\[\]`\"'、。]*)?",
        text_without_urls,
        flags=re.IGNORECASE,
    ), f"bare localhost destination in public licensing text: {path}"
    assert not re.search(r"(?<![A-Za-z0-9+.-])(?:file|ftp|s3):[\\/]+", text_without_urls, flags=re.IGNORECASE), (
        f"non-public URI scheme/path in public licensing text: {path}"
    )
    assert not re.search(
        r"(?:^|[\s(\[{'\"`])/(?!/)[^\s|<>()\[\]`\"'、。]+", text_without_urls,
    ), f"absolute POSIX path in public licensing text: {path}"
    domain_scan_text = text_without_urls
    allowed_dotted_tokens = ALLOWED_PUBLIC_BARE_DOMAINS | ALLOWED_PUBLIC_DOTTED_NON_URLS
    for allowed_token in sorted(allowed_dotted_tokens, key=len, reverse=True):
        domain_scan_text = re.sub(
            rf"(?<![A-Za-z0-9.-]){re.escape(allowed_token)}(?![A-Za-z0-9.-])",
            lambda match: " " * len(match.group(0)),
            domain_scan_text,
            flags=re.IGNORECASE,
        )
    for repo_token in sorted(allowed_repo_tokens or set(), key=len, reverse=True):
        domain_scan_text = re.sub(
            rf"(?<![\w./-]){re.escape(repo_token)}(?![\w./-])",
            lambda match: " " * len(match.group(0)),
            domain_scan_text,
        )
    # ASCII-dot IDNs are domain-shaped.  Ideographic-dot text is ambiguous with
    # Japanese sentences, so pure-Unicode labels need a path or explicit context.
    idn_candidate = re.compile(
        r"(?<![@\w.-])"
        r"(?P<host>(?:[^\W_]|-)+(?:\.(?:[^\W_]|-)+)+)\.?(?![\w.-])",
        flags=re.IGNORECASE | re.MULTILINE,
    )
    unicode_dot_candidate = re.compile(
        r"(?<![A-Za-z0-9@_.-])"
        r"(?P<host>(?:[^\W_]|-)+(?:。(?:[^\W_]|-)+)+)[.。]?(?![\w.-])",
        flags=re.IGNORECASE | re.MULTILINE,
    )
    destination_context_core = r"(?:接続先|リンク先|URL|URI|host|domain|宛先|リンク)"
    contextual_idn_candidate = re.compile(
        rf"(?<!\w){destination_context_core}"
        r"(?P<bridge>(?:(?:として|して|は|を|が|の|へ|と)|"
        r"[ \t:：=＝→⇒\-–—>›»・、，,;；（(\[「『【'\"）)\]」』】]){1,24})"
        r"(?P<host>(?:[^\W_]|-)+(?:[.。](?:[^\W_]|-)+)+)[.。]?(?![\w.-])",
        flags=re.IGNORECASE | re.MULTILINE,
    )
    idn_matches = list(idn_candidate.finditer(domain_scan_text))
    unicode_dot_matches = list(unicode_dot_candidate.finditer(domain_scan_text))
    contextual_idn_matches = list(contextual_idn_candidate.finditer(domain_scan_text))
    domain_matches = (
        [(match, "general") for match in idn_matches]
        + [(match, "unicode-dot") for match in unicode_dot_matches]
        + [(match, "explicit-context") for match in contextual_idn_matches]
    )
    for match, match_mode in domain_matches:
        host = match.group("host")
        unicode_labels = any(ord(character) > 127 for character in host if character != "。")
        if not unicode_labels and "。" not in host:
            continue
        ascii_dots = host.replace("。", ".")
        labels = ascii_dots.split(".")
        if not (
            2 <= len(labels)
            and all(
                label
                and len(label) <= 63
                and not label.startswith("-")
                and not label.endswith("-")
                and all(character.isalnum() or character == "-" for character in label)
                for label in labels
            )
            and len(labels[-1]) >= 2
            and (labels[-1].isalpha() or labels[-1].lower().startswith("xn--"))
        ):
            continue
        host_start = match.start("host")
        destination_end = match.end()
        if match_mode == "unicode-dot":
            followed_by_path = (
                destination_end < len(domain_scan_text)
                and domain_scan_text[destination_end] == "/"
            )
            consumed_trailing_dot = destination_end > match.end("host")
            explicit_ascii_trailing_dot = (
                consumed_trailing_dot and domain_scan_text[destination_end - 1] == "."
            )
            if not followed_by_path and not explicit_ascii_trailing_dot:
                continue
        line_start = domain_scan_text.rfind("\n", 0, host_start) + 1
        inside_markdown_code = domain_scan_text[line_start:host_start].count("`") % 2 == 1
        if inside_markdown_code and Path(ascii_dots).suffix.lower() in PUBLIC_REPO_FILE_SUFFIXES:
            continue
        raise AssertionError(f"bare IDN destination in public licensing text: {path}")
    bare_domain_matches = list(re.finditer(
        r"(?<![@\w.-])(?:(?:[^\W_]|-)+\.)+"
        r"[A-Za-z](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?\.?(?![\w.-])",
        domain_scan_text,
        flags=re.IGNORECASE,
    ))
    for match in bare_domain_matches:
        dotted_token = match.group(0).lower().rstrip(".")
        line_start = domain_scan_text.rfind("\n", 0, match.start()) + 1
        inside_markdown_code = domain_scan_text[line_start:match.start()].count("`") % 2 == 1
        if inside_markdown_code and Path(dotted_token).suffix.lower() in PUBLIC_REPO_FILE_SUFFIXES:
            continue
        if match.end() < len(domain_scan_text) and domain_scan_text[match.end()] in "/:":
            raise AssertionError(f"bare/non-allowlisted domain in public licensing text: {path}")
        start, end = match.span()
        while start > 0 and (
            domain_scan_text[start - 1].isalnum() or domain_scan_text[start - 1] in "._-/"
        ):
            start -= 1
        while end < len(domain_scan_text) and (
            domain_scan_text[end].isalnum() or domain_scan_text[end] in "._-/"
        ):
            end += 1
        candidate = domain_scan_text[start:end]
        candidate_path = PurePosixPath(candidate)
        is_repo_relative = (
            candidate
            and not candidate_path.is_absolute()
            and all(part not in {"", ".", ".."} for part in candidate_path.parts)
            and ("/" in candidate or (ROOT / candidate).exists())
        )
        assert is_repo_relative, f"bare/non-allowlisted domain in public licensing text: {path}"
    sensitive_label_core = (
        r"(?:name|first[-_ ]*name|last[-_ ]*name|customer[-_ ]*name|full[-_ ]*name|"
        r"subscriber[-_ ]*name|account[-_ ]*holder|cardholder[-_ ]*name|"
        r"contact[-_ ]*(?:name|person)|billing[-_ ]*address|postal[-_ ]*code|zip[-_ ]*code|"
        r"e[-_ ]?mail(?:[-_ ]*address)?|"
        r"phone(?:[-_ ]*number)?|telephone|mobile(?:[-_ ]*number)?|address|"
        r"account(?:[-_ ]*(?:id|number))?|"
        r"billing|invoice|receipt|payment|order|transaction|session|token|"
        r"password|passphrase|credential|api[-_ ]*key|access[-_ ]*key|secret[-_ ]*key|"
        r"auth[-_ ]*token|access[-_ ]*token|private[-_ ]*storage[-_ ]*password|"
        r"card[-_ ]*(?:id|number|last[-_ ]*4|last4)|last[-_ ]*4|"
        r"ssn|social[-_ ]*security[-_ ]*(?:id|number)|tax[-_ ]*(?:id|number)|"
        r"dob|date[-_ ]*of[-_ ]*birth|bank[-_ ]*(?:id|account|number)|"
        r"routing(?:[-_ ]*(?:id|number))?|private[-_ ]*url|secret[-_ ]*url|"
        r"顧客名|契約者名|名義(?:人)?|担当者|氏名|名前|メール(?:アドレス)?|電子メール|"
        r"住所|請求先|郵便番号|"
        r"電話(?:番号)?|携帯(?:電話)?(?:番号)?|アカウント(?:ID|番号)?|連絡先|"
        r"請求(?:書|情報|ID|番号)?|決済(?:サービス)?(?:情報|ID|番号)?|"
        r"注文(?:ID|番号)?|取引(?:ID|番号)?|領収書(?:ID|番号)?|"
        r"カード(?:番号|下[-_ ]?4桁)|下[-_ ]?4桁|"
        r"銀行(?:名|情報|口座|番号)?|口座(?:番号)?|税務(?:ID|番号|情報)?|"
        r"生年月日|パスワード|認証情報|認証トークン|アクセストークン|トークン|"
        r"API[-_ ]?キー|秘密[-_ ]?URL)"
    )
    sensitive_label = re.compile(
        rf"(?<![A-Za-z0-9_])(?P<label>\[?{sensitive_label_core}\]?)\s*"
        rf"(?P<separator>[:=/])\s*"
        rf"(?P<value>[^\s|<{{\[、。,.，;；:/]+)",
        flags=re.IGNORECASE,
    )
    sensitive_table_label = re.compile(rf"^{sensitive_label_core}$", flags=re.IGNORECASE)
    sensitive_markdown_value = re.compile(
        rf"\[\s*(?P<label>{sensitive_label_core})\s*\]\s*"
        rf"(?:\((?P<inline>[^)]+)\)|\[(?P<reference>[^]]+)\])",
        flags=re.IGNORECASE,
    )
    def normalize_table_label(value: str) -> str:
        value = value.strip().strip(":=")
        value = value.strip("[]")
        value = re.sub(r"\s*(?:\([^)]*\)|\[[^]]*\])\s*$", "", value)
        value = re.sub(r"(?:欄|フィールド)$", "", value)
        return value.strip()

    for line in normalized_text.splitlines():
        plain = re.sub(r"[*_`~]", "", line)
        for match in sensitive_markdown_value.finditer(plain):
            value = (match.group("inline") or match.group("reference") or "").strip()
            assert not value, f"public licensing Markdown link/reference contains sensitive value: {path}"
        for match in sensitive_label.finditer(plain):
            value = match.group("value").rstrip("、。,.，;；")
            lower_plain = plain.lower()
            safe_ranges = []
            for safe_phrase in SAFE_PUBLIC_SLASH_ENUMERATIONS:
                start = lower_plain.find(safe_phrase.lower())
                if start >= 0:
                    safe_ranges.append((start, start + len(safe_phrase)))
            slash_enumeration = (
                match.group("separator") == "/"
                and sensitive_table_label.fullmatch(value)
                and any(start <= match.start() and match.end() <= end for start, end in safe_ranges)
            )
            assert slash_enumeration, f"public licensing text contains sensitive labeled value: {path}"
        if "|" in plain:
            cells = [cell.strip().strip(":=") for cell in plain.strip().strip("|").split("|")]
            for index, cell in enumerate(cells[:-1]):
                value = cells[index + 1].strip()
                if (
                    sensitive_table_label.fullmatch(normalize_table_label(cell))
                    and value
                    and not re.fullmatch(r"[-:]+", value)
                    and not re.fullmatch(r"<[^>]+>", value)
                ):
                    raise AssertionError(f"public licensing Markdown table contains sensitive value: {path}")
    table_block: list[list[str]] = []
    table_blocks: list[list[list[str]]] = []
    for line in normalized_text.splitlines() + [""]:
        if "|" in line:
            plain = re.sub(r"[*_`~]", "", line)
            table_block.append([cell.strip() for cell in plain.strip().strip("|").split("|")])
        elif table_block:
            table_blocks.append(table_block)
            table_block = []
    for block in table_blocks:
        for separator_index in range(1, len(block)):
            separator = block[separator_index]
            if not separator or not all(re.fullmatch(r":?-{3,}:?", cell) for cell in separator):
                continue
            headers = block[separator_index - 1]
            sensitive_columns = {
                index for index, header in enumerate(headers)
                if sensitive_table_label.fullmatch(normalize_table_label(header))
            }
            for row in block[separator_index + 1:]:
                for index in sensitive_columns:
                    if index >= len(row):
                        continue
                    value = row[index].strip()
                    if value and not re.fullmatch(r"[-:]+|<[^>]+>", value):
                        raise AssertionError(
                            f"public licensing Markdown header column contains sensitive value: {path}"
                        )
            break
    prohibited = (
        (r"\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b", "email"),
        (r"(?<![A-Za-z0-9])0\d{1,4}[ \t.\-\u2010-\u2015\u2212\u30fc]+\d{1,4}[ \t.\-\u2010-\u2015\u2212\u30fc]+\d{3,4}(?![A-Za-z0-9])", "Japanese phone-like number"),
        (r"(?<![A-Za-z0-9])0\d{1,4}[ \t\-]*\(\d{1,4}\)[ \t\-]*\d{3,4}(?![A-Za-z0-9])", "parenthesized Japanese phone-like number"),
        (r"(?<![A-Za-z0-9])0(?:[5789]0\d{8}|\d{9})(?![A-Za-z0-9])", "contiguous Japanese phone-like number"),
        (r"(?<![A-Za-z0-9])\+81[ \-]?(?:\(0\)[ \-]?)?\d{1,4}[ \-]\d{1,4}[ \-]\d{3,4}(?![A-Za-z0-9])", "international Japanese phone-like number"),
        (r"(?<![A-Za-z0-9+/=_-])[A-Za-z0-9+/_-]{120,}={0,2}(?![A-Za-z0-9+/=_-])", "long raw base64 payload"),
        (r"(?<![A-Za-z0-9._-])/(?:[^/\s|`<>]+/)*(?:Users|home)/[^\s|`<>]+", "absolute macOS/Linux user path"),
        (r"(?<![A-Za-z0-9._-])/(?:[^/\s|`<>]+/)*root(?:/[^\s|`<>]+)?", "absolute root user path"),
        (r"(?<![A-Za-z0-9_])[A-Z]:[\\/][^\s|`<>]+", "absolute Windows user path"),
        (r"(?<![A-Za-z0-9_])\\\\[^\\\s|`<>]+\\[^\s|`<>]+", "Windows UNC path"),
        (r"(?:^|[\\/\s(\[{'\"`])(?:~[\\/]|\.\.[\\/])", "home/traversal path"),
    )
    for pattern, label in prohibited:
        assert not re.search(pattern, normalized_text, flags=re.IGNORECASE), (
            f"public licensing text contains prohibited {label}: {path}"
        )
    assert not re.search(r"(?<![A-Za-z0-9])\d{12,19}(?![A-Za-z0-9])", normalized_text), (
        f"public licensing text contains contiguous 12-19 digit card-like number: {path}"
    )
    grouped_card_pattern = re.compile(
        r"(?<![A-Za-z0-9])\d{2,6}"
        r"(?:(?:[ \t]*[./\-\u2010-\u2015\u2212\u30fc][ \t]*|[ \t]+)\d{2,6}){2,5}"
        r"(?![A-Za-z0-9])"
    )
    for card_match in grouped_card_pattern.finditer(normalized_text):
        candidate = card_match.group(0)
        digit_groups = re.split(
            r"[ \t]*[./\-\u2010-\u2015\u2212\u30fc][ \t]*|[ \t]+",
            candidate,
        )
        digit_count = sum(len(group) for group in digit_groups)
        card_like = 12 <= digit_count <= 19 and 2 <= len(digit_groups[0]) <= 4
        assert not card_like, (
            f"public licensing text contains separated 12-19 digit card-like number: {path}"
        )
    wrapped_base64_size = 0
    for line in normalized_text.splitlines():
        candidate = re.sub(r"^[\s>|`*~-]+", "", line)
        candidate = re.sub(r"[`]+$", "", candidate).strip()
        candidate = re.sub(r"^[A-Za-z0-9-]+:\s*", "", candidate)
        compact_candidate = re.sub(r"[ \t]", "", candidate)
        if len(compact_candidate.rstrip("=")) >= 120 and re.fullmatch(
            r"[A-Za-z0-9+/_-]+={0,2}", compact_candidate,
        ):
            raise AssertionError(f"public licensing text contains spaced raw base64 payload: {path}")
        if compact_candidate.startswith("iVBORw0KGgo") and len(compact_candidate) >= 16:
            raise AssertionError(f"public licensing text contains raw PNG base64 payload: {path}")
        is_wrapped_chunk = (
            len(compact_candidate.rstrip("=")) >= 50
            and re.fullmatch(r"[A-Za-z0-9+/_-]+={0,2}", compact_candidate)
            and not re.fullmatch(r"[0-9a-fA-F]{64}", compact_candidate)
        )
        if is_wrapped_chunk:
            wrapped_base64_size += len(compact_candidate.rstrip("="))
            assert wrapped_base64_size < 120, (
                f"public licensing text contains wrapped raw base64 payload: {path}"
            )
        elif compact_candidate:
            wrapped_base64_size = 0


def validate_u04_decision_schema(
    fields: dict[str, str], label: str,
    known_original_digest: str = KNOWN_ORIGINAL_ICON_SHA256,
) -> None:
    decision = fields.get("Product-Decision")
    assert decision in {"adopted", "rejected"}, f"U-04 product decision missing: {label}"
    assert re.fullmatch(r"[0-9a-f]{64}", known_original_digest), (
        f"invalid U-04 known original icon digest contract: {known_original_digest}"
    )
    assert fields.get("Baseline-Original-Content-SHA256") == known_original_digest, (
        f"U-04 decision does not preserve the known original icon digest: {label}"
    )
    if decision == "adopted":
        required = {"Product-Content-SHA256", "Author-Verified", "Rights-Holder-Verified"}
        forbidden = {
            "Replacement-Integrated", "Replacement-Product-Path",
            "Replacement-Content-SHA256", "Replacement-Rights-Attestation",
        }
        assert required <= fields.keys(), f"U-04 adopted decision fields missing: {label}"
        assert not (forbidden & fields.keys()), f"U-04 adopted decision has replacement payload: {label}"
        assert fields["Product-Content-SHA256"] == known_original_digest, (
            f"U-04 adopted product digest differs from the known original icon: {label}"
        )
        assert fields["Author-Verified"] == "true" and fields["Rights-Holder-Verified"] == "true", (
            f"U-04 adopted icon author/rights holder is not verified: {label}"
        )
    else:
        required = {
            "Replacement-Integrated", "Replacement-Product-Path",
            "Replacement-Content-SHA256", "Replacement-Rights-Attestation",
        }
        forbidden = {"Product-Content-SHA256", "Author-Verified", "Rights-Holder-Verified"}
        assert required <= fields.keys(), f"U-04 rejected decision fields missing: {label}"
        assert not (forbidden & fields.keys()), f"U-04 rejected decision has adopted-only payload: {label}"
        assert fields["Replacement-Integrated"] == "true", f"U-04 replacement is not integrated: {label}"


def attestation_repo_tokens(fields: dict[str, str], asset_root: Path) -> set[str]:
    evidence_type = fields.get("Evidence-Type", "")
    tokens: set[str] = set()
    candidates: list[tuple[str, tuple[str, ...], set[str]]] = []
    if evidence_type == "suno-track-provenance":
        for key, value in fields.items():
            if re.fullmatch(r"Track-\d{2,4}", key):
                candidates.append((value.split(";", 1)[0].strip(), ("assets/audio/",), {".mp3"}))
    elif evidence_type == "ai-image-provenance":
        for key, value in fields.items():
            if re.fullmatch(r"Item-\d{4,6}", key):
                candidates.append((value.split(";", 1)[0].strip(), (
                    "assets/showcase/", "tools/source_assets/", "reference/",
                ), {".png"}))
    elif evidence_type == "ai-input-rights":
        for key, value in fields.items():
            if re.fullmatch(r"Item-\d{4,6}", key):
                candidates.append((value.split(";", 1)[0].strip(), (
                    "assets/audio/", "assets/showcase/", "tools/source_assets/", "reference/",
                ), {".mp3", ".png"}))
    elif evidence_type == "icon-rights":
        candidate = fields.get("Replacement-Product-Path", "")
        if candidate:
            candidates.append((candidate, ("assets/",), {".svg", ".png", ".webp"}))
    elif evidence_type == "icon-replacement-rights":
        candidate = fields.get("Replacement-Asset-Path", "")
        if candidate:
            candidates.append((candidate, ("assets/",), {".svg", ".png", ".webp"}))
    for candidate, prefixes, suffixes in candidates:
        if evidence_type == "suno-track-provenance":
            relative = f"assets/audio/{candidate}"
            canonical = PurePosixPath(candidate).name == candidate
        else:
            relative = candidate
            canonical_path = PurePosixPath(candidate)
            canonical = (
                candidate
                and "\\" not in candidate
                and not canonical_path.is_absolute()
                and all(part not in {"", ".", ".."} for part in canonical_path.parts)
                and canonical_path.as_posix() == candidate
            )
        if (
            canonical
            and relative.startswith(prefixes)
            and Path(relative).suffix.lower() in suffixes
            and (asset_root / relative).is_file()
        ):
            tokens.add(candidate)
            tokens.add(relative)
            tokens.add(Path(relative).name)
    return tokens


def parse_attestation(path: Path, asset_root: Path = ROOT) -> dict[str, str]:
    assert path.is_file(), f"attestation is not a regular file: {path}"
    text = path.read_text(encoding="utf-8")
    assert text.strip(), f"attestation is empty: {path}"
    fields: dict[str, str] = {}
    duplicate_fields: set[str] = set()
    for line in text.splitlines():
        if line.strip():
            assert re.fullmatch(r"[A-Za-z0-9-]+:\s*.+", line), (
                f"attestation permits plain field lines only: {path}: {line!r}"
            )
        match = re.fullmatch(r"([A-Za-z0-9-]+):\s*(.+)", line)
        if match:
            key = match.group(1)
            if key in fields:
                duplicate_fields.add(key)
            fields[key] = match.group(2).strip()
    assert not duplicate_fields, f"duplicate attestation fields forbidden: {sorted(duplicate_fields)} in {path}"
    assert ATTESTATION_FIELDS <= fields.keys(), (
        f"attestation fields missing: {sorted(ATTESTATION_FIELDS - fields.keys())} in {path}"
    )
    assert re.fullmatch(r"U-(?:0[1-6]|08)", fields["Evidence-ID"]), f"invalid Evidence-ID: {path}"
    evidence_type = fields["Evidence-Type"]
    assert evidence_type in TYPE_SPECIFIC_FIELDS, f"unknown Evidence-Type: {evidence_type} in {path}"
    assert evidence_type in EVIDENCE_ID_TYPES[fields["Evidence-ID"]], (
        f"Evidence-ID/Type mismatch: {fields['Evidence-ID']} / {evidence_type} in {path}"
    )
    scan_public_text(
        text, path, allow_official_urls=False,
        allowed_repo_tokens=attestation_repo_tokens(fields, asset_root),
    )
    allowed_fields = ATTESTATION_FIELDS | TYPE_SPECIFIC_FIELDS[evidence_type]
    dynamic_patterns = {
        "suno-track-provenance": (r"Track-\d{2,4}",),
        "ai-image-provenance": (r"Item-\d{4,6}", r"Provenance-\d{4,6}"),
        "ai-input-rights": (r"Item-\d{4,6}",),
    }.get(evidence_type, ())
    unknown_fields = {
        key for key in fields
        if key not in allowed_fields and not any(re.fullmatch(pattern, key) for pattern in dynamic_patterns)
    }
    assert not unknown_fields, f"unknown attestation fields forbidden: {sorted(unknown_fields)} in {path}"
    if evidence_type == "icon-rights":
        validate_u04_decision_schema(fields, str(path))
    else:
        missing_type_fields = TYPE_SPECIFIC_FIELDS[evidence_type] - fields.keys()
        assert not missing_type_fields, (
            f"attestation type-specific fields missing: {sorted(missing_type_fields)} in {path}"
        )
    def bounded_count(field_name: str, maximum: int) -> int:
        raw = fields.get(field_name, "")
        assert re.fullmatch(r"0|[1-9]\d*", raw), f"invalid {field_name}: {raw} in {path}"
        value = int(raw)
        assert 0 <= value <= maximum, f"{field_name} exceeds practical limit {maximum}: {value} in {path}"
        return value

    if evidence_type == "suno-track-provenance":
        count = bounded_count("Asset-Count", 1000)
        expected_dynamic = {f"Track-{number:02d}" for number in range(1, count + 1)}
        actual_dynamic = {key for key in fields if key.startswith("Track-")}
        assert actual_dynamic == expected_dynamic, (
            f"Track field set mismatch: missing={sorted(expected_dynamic - actual_dynamic)}, "
            f"extra={sorted(actual_dynamic - expected_dynamic)} in {path}"
        )
    elif evidence_type == "ai-image-provenance":
        population_count = bounded_count("Population-Count", 10000)
        provenance_count = bounded_count("Provenance-Count", 10000)
        expected_items = {f"Item-{number:04d}" for number in range(1, population_count + 1)}
        expected_provenance = {f"Provenance-{number:04d}" for number in range(1, provenance_count + 1)}
        actual_items = {key for key in fields if key.startswith("Item-")}
        actual_provenance = {key for key in fields if key.startswith("Provenance-") and key != "Provenance-Count" and key != "Provenance-Complete"}
        assert actual_items == expected_items, f"Item field set mismatch in {path}"
        assert actual_provenance == expected_provenance, f"Provenance field set mismatch in {path}"
    elif evidence_type == "ai-input-rights":
        population_count = bounded_count("Population-Count", 20000)
        expected_items = {f"Item-{number:04d}" for number in range(1, population_count + 1)}
        actual_items = {key for key in fields if key.startswith("Item-")}
        assert actual_items == expected_items, f"Item field set mismatch in {path}"
    assert re.fullmatch(r"[0-9a-f]{64}", fields["Original-SHA256"]), f"invalid original SHA-256: {path}"
    assert len(set(fields["Original-SHA256"])) >= 5, f"placeholder original SHA-256: {path}"
    reviewed_at = require_calendar_date(fields["Reviewed-At"], f"Reviewed-At in {path}")
    assert reviewed_at <= release_today(), f"future Reviewed-At in {path}: {reviewed_at}"
    assert re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]{1,63}", fields["Reviewer"]), (
        f"Reviewer must be a non-secret role/ID: {path}"
    )
    assert re.fullmatch(r"[A-Z0-9][A-Z0-9_-]{2,63}", fields["Private-Storage-Reference"]), (
        f"Private-Storage-Reference must be a non-secret management ID: {path}"
    )
    assert not re.search(
        r"(?:^|[-_.])(?:ACCOUNT|BILLING|BILL|INVOICE|PAYMENT|TRANSACTION|ORDER|RECEIPT|CARD|LAST4)(?=[-_.\d]|$)",
        fields["Private-Storage-Reference"],
    ), f"Private-Storage-Reference contains a prohibited billing/account identifier: {path}"
    assert fields["Redaction-Checked"] == "true", f"redaction must be confirmed: {path}"
    assert fields["Finding"] == FINDING_CODES[evidence_type], (
        f"Finding must use the closed safe code for {evidence_type}: {path}"
    )
    return fields


def audit_evidence_tree(
    evidence_root: Path, asset_root: Path = ROOT,
    management_text_overrides: dict[Path, str] | None = None,
) -> dict[Path, dict[str, str]]:
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
            management_text = (management_text_overrides or {}).get(
                path.resolve(), path.read_text(encoding="utf-8"),
            )
            scan_public_text(management_text, path, allow_official_urls=True)
            continue
        assert relative.parent == Path("attestations"), f"nested evidence path forbidden: {relative}"
        if relative.name == ".gitkeep":
            assert path.stat().st_size == 0, "attestations/.gitkeep must be zero bytes"
            continue
        assert re.fullmatch(r"U-(?:0[1-6]|08)_[A-Za-z0-9._-]+\.md", relative.name), (
            f"attestation filename must be U-XX_*.md: {relative}"
        )
        fields = parse_attestation(path, asset_root)
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
    rows = [line for line in v2_overview.splitlines() if line.startswith("| RIGHTS-01A |")]
    assert len(rows) == 1, f"docs/30 must contain one visible RIGHTS-01A row: {rows}"
    cells = [cell.strip() for cell in rows[0].strip("|").split("|")]
    assert len(cells) == 3, f"invalid docs/30 RIGHTS-01A row: {rows[0]}"
    visible_state, description = cells[1], cells[2]
    if expected_state == "pending":
        assert visible_state == "**外部証拠待ち**", (
            "docs/30 visible RIGHTS-01A row falsely reports completion"
        )
        assert not re.search(r"(?:全件)?(?:完了|close済み)", description, flags=re.IGNORECASE), (
            "docs/30 pending RIGHTS-01A description falsely reports completion"
        )
    else:
        assert visible_state == "**完了**" and "全件close済み" in description, (
            "docs/30 visible RIGHTS-01A row is not synchronized to complete"
        )
        assert "待ち" not in visible_state + description, "docs/30 completed row retains pending prose"


def audit_completion_dependencies(completed_ids: set[str]) -> None:
    if "U-02" in completed_ids:
        assert "U-01" in completed_ids, "U-02 cannot complete before U-01"
    if "U-08" in completed_ids:
        assert {"U-01", "U-03"} <= completed_ids, "U-08 cannot complete before U-01 and U-03"


def audit_ledger_evidence_state(evidence_id: str, is_open: bool, ledger: str) -> None:
    pending_tokens = {
        "U-01": ("U-01待ち",),
        "U-02": ("U-02待ち",),
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


def audit_ledger_section_states(
    open_ids: set[str], ledger: str, require_source_scope: bool = False,
) -> None:
    audio_pending_heading = "## 3. 音源（BGM / SE） — 条件確認済み・証拠待ち"
    if {"U-01", "U-02"} & open_ids:
        assert audio_pending_heading in ledger, "audio ledger heading must remain pending while U-01/U-02 is open"
    else:
        assert audio_pending_heading not in ledger and "## 3. 音源（BGM / SE） — 解決済み" in ledger, (
            "audio ledger heading must be resolved after U-01/U-02 complete"
        )
    audio_heading = audio_pending_heading if audio_pending_heading in ledger else "## 3. 音源（BGM / SE） — 解決済み"
    audio_section = ledger.split(audio_heading, 1)[1].split("\n## ", 1)[0]
    if "U-01" not in open_ids:
        for stale in ("U-01待ち", "個別10音源との対応と生成日時", "生成日時/曲詳細"):
            assert stale not in audio_section, f"U-01 completed audio section retains stale prose: {stale}"
    if "U-02" not in open_ids:
        for stale in ("U-02待ち", "加入期間証拠が必要", "Billing History・Pro/Premier加入証拠が必要"):
            assert stale not in audio_section, f"U-02 completed audio section retains stale prose: {stale}"
    if not ({"U-01", "U-02"} & open_ids):
        for stale in ("未完", "未完了"):
            assert stale not in audio_section, f"resolved audio ledger section retains stale state: {stale}"
    ai_pending_heading = "## 4. AI生成画像（外部サービス由来） — **要記入**"
    ai_resolved_heading = "## 4. AI生成画像（外部サービス由来） — 解決済み"
    assert not ("U-03" in open_ids and "U-08" not in open_ids), (
        "AI ledger cannot report U-08 complete while prerequisite U-03 remains open"
    )
    if {"U-03", "U-08"} & open_ids:
        assert ledger.count(ai_pending_heading) == 1 and ledger.count(ai_resolved_heading) == 0, (
            "AI image ledger must contain only the pending heading while U-03/U-08 is open"
        )
        ai_heading = ai_pending_heading
    else:
        assert ledger.count(ai_pending_heading) == 0 and ledger.count(ai_resolved_heading) == 1, (
            "AI image ledger heading must be resolved after U-03/U-08 complete"
        )
        ai_heading = ai_resolved_heading
    ai_section = ledger.split(ai_heading, 1)[1].split("\n## ", 1)[0]
    source_scope_heading = "### 2.2 `tools/source_assets/**` / `reference/**` を消費するパイプライン（全件追跡対象）"
    source_scope = ""
    if require_source_scope:
        assert ledger.count(source_scope_heading) == 1, (
            "docs/31 requires exactly one canonical AI source/reference scope heading"
        )
    if source_scope_heading in ledger:
        assert ledger.count(source_scope_heading) == 1, "duplicate AI source/reference scope heading"
        source_scope = ledger.split(source_scope_heading, 1)[1].split("\n## ", 1)[0]
    ai_provenance_scope = source_scope + "\n" + ai_section
    expected_ai_tokens = {
        "U-03": "U-03待ち" if "U-03" in open_ids else "U-03解決済み",
        "U-08": "U-08待ち" if "U-08" in open_ids else "U-08解決済み",
    }
    for evidence_id, token in expected_ai_tokens.items():
        assert token in ai_section, f"AI ledger section lacks {evidence_id} state token: {token}"
    if "U-03" not in open_ids:
        for stale in ("U-03待ち", "未完", "未確定", "証拠待ち", "ユーザー入力待ち"):
            assert stale not in ai_provenance_scope, (
                f"U-03-resolved AI provenance scope retains stale state: {stale}"
            )
    if not ({"U-03", "U-08"} & open_ids):
        for stale in (
            "U-03待ち", "U-08待ち", "未完", "未確定", "証拠待ち", "ユーザー入力待ち",
            "要記入", "確定しない", "申告がなく", "推定が残",
        ):
            assert stale not in ai_provenance_scope, f"resolved AI ledger scope retains stale state: {stale}"


def audit_canonical_attestation_counts(
    completed_fields: dict[str, list[dict[str, str]]], completed_ids: set[str],
) -> None:
    for evidence_id in ("U-01", "U-02", "U-03", "U-05", "U-06", "U-08"):
        if evidence_id in completed_ids:
            assert len(completed_fields.get(evidence_id, [])) == 1, (
                f"{evidence_id} requires exactly one canonical full attestation"
            )
    if "U-04" in completed_ids:
        u04_fields = completed_fields.get("U-04", [])
        decisions = [item for item in u04_fields if item.get("Evidence-Type") == "icon-rights"]
        replacements = [item for item in u04_fields if item.get("Evidence-Type") == "icon-replacement-rights"]
        assert len(decisions) == 1, "U-04 requires exactly one canonical decision attestation"
        if decisions[0].get("Product-Decision") == "rejected":
            assert len(replacements) == 1, "U-04 rejected requires exactly one distinct replacement-rights attestation"
        else:
            assert not replacements, "U-04 adopted must not include replacement-rights attestations"


def audit_completed_attestation_references(
    evidence_id: str, saved_paths: list[str],
    parsed_attestations: dict[Path, dict[str, str]], root: Path,
) -> None:
    expected_paths = {
        path.relative_to(root.resolve()).as_posix()
        for path, fields in parsed_attestations.items()
        if fields.get("Evidence-ID") == evidence_id
    }
    assert set(saved_paths) == expected_paths, (
        f"completed {evidence_id} row must reference every and only canonical attestation: "
        f"expected={sorted(expected_paths)}, found={sorted(set(saved_paths))}"
    )


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


def validate_u01_tracks(
    fields: dict[str, str], label: str, audio_names: list[str], root: Path = ROOT,
) -> list[datetime]:
    assert fields.get("Asset-Count") == str(len(audio_names)), f"U-01 Asset-Count mismatch: {label}"
    tracks: dict[str, tuple[datetime, str]] = {}
    mapping_ids: set[str] = set()
    expected_audio = set(audio_names)
    for number in range(1, len(audio_names) + 1):
        value = fields.get(f"Track-{number:02d}", "")
        parts = [part.strip() for part in value.split(";")]
        assert len(parts) == 4, (
            f"U-01 Track-{number:02d} must be filename;content-sha256;generated-at;mapping-id: {label}"
        )
        filename, content_sha256, generated_at_raw, mapping_id = parts
        assert filename in expected_audio and filename not in tracks, f"U-01 invalid/duplicate filename: {filename}"
        assert content_sha256 == file_sha256(root / "assets/audio" / filename), (
            f"U-01 stale content digest for {filename}"
        )
        generated_at = parse_generated_at(generated_at_raw, f"U-01 generated-at for {filename}")
        assert re.fullmatch(r"[A-Z0-9][A-Z0-9_-]{2,63}", mapping_id), (
            f"U-01 mapping ID must be a non-secret management ID: {filename}"
        )
        assert mapping_id not in mapping_ids, f"U-01 duplicate mapping ID: {mapping_id}"
        tracks[filename] = (generated_at, mapping_id)
        mapping_ids.add(mapping_id)
    assert set(tracks) == expected_audio, f"U-01 must cover exactly the indexed audio population: {label}"
    assert fields.get("One-to-One-Mapping-Verified") == "true", f"U-01 mapping is not verified: {label}"
    return [tracks[name][0] for name in sorted(tracks)]


def validate_u02_period(
    fields: dict[str, str], label: str, audit_date: date | None = None,
) -> tuple[date, date, date]:
    assert fields.get("Plan") in {"Pro", "Premier"}, f"invalid Suno plan: {label}"
    period_start = require_calendar_date(fields.get("Period-Start", ""), f"Period-Start in {label}")
    period_end = require_calendar_date(fields.get("Period-End", ""), f"Period-End in {label}")
    evidence_as_of = require_calendar_date(
        fields.get("Evidence-As-Of", ""), f"Evidence-As-Of in {label}"
    )
    reviewed_at = require_calendar_date(fields.get("Reviewed-At", ""), f"Reviewed-At in {label}")
    assert period_start <= period_end, f"invalid Suno paid period order: {label}"
    assert period_start <= evidence_as_of <= period_end and evidence_as_of <= reviewed_at, (
        f"Suno evidence-as-of must be within the period and no later than Reviewed-At: {label}"
    )
    assert evidence_as_of <= (audit_date if audit_date is not None else release_today()), (
        f"Suno Evidence-As-Of cannot be in the future: {label}"
    )
    assert fields.get("Covers-U-01") == "true", f"U-02 does not declare U-01 coverage: {label}"
    return period_start, period_end, evidence_as_of


def cross_check_u02_covers_u01(
    u01_fields: dict[str, str], u02_fields: dict[str, str], label: str,
    audio_names: list[str], root: Path = ROOT,
) -> None:
    generated = validate_u01_tracks(u01_fields, label, audio_names, root)
    period_start, period_end, evidence_as_of = validate_u02_period(u02_fields, label)
    # Subscription evidence uses calendar dates. Compare each generation's calendar date in its recorded offset.
    generated_dates = [value.date() for value in generated]
    confirmed_period_end = min(period_end, evidence_as_of)
    assert period_start <= min(generated_dates) and max(generated_dates) <= confirmed_period_end, (
        f"U-02 paid period does not contain U-01 local generated dates: "
        f"confirmed={period_start}..{confirmed_period_end}, contractual-end={period_end}, "
        f"generated={min(generated_dates)}..{max(generated_dates)}"
    )


def git_ls_files(root: Path) -> list[str]:
    raw = subprocess.run(
        ["git", "ls-files", "-z"], cwd=root, check=True, capture_output=True,
    ).stdout
    return [os.fsdecode(item) for item in raw.split(b"\0") if item]


def build_u03_population(root: Path) -> list[str]:
    tracked = git_ls_files(root)
    prefixes = ("assets/showcase/", "tools/source_assets/", "reference/")
    return sorted(path for path in tracked if path.startswith(prefixes) and Path(path).suffix.lower() == ".png")


def build_audio_population(root: Path) -> list[str]:
    return sorted(
        Path(path).name for path in indexed_paths(root)
        if path.startswith("assets/audio/") and Path(path).suffix.lower() == ".mp3"
    )


def indexed_paths(root: Path) -> set[str]:
    return set(git_ls_files(root))


def audit_unreviewed_dependencies(tracked: list[str]) -> None:
    addon_entries = [path for path in tracked if path == "addons" or path.startswith("addons/")]
    native_extensions = [
        path for path in tracked if Path(path).suffix.lower() in {".gdextension", ".dll", ".so", ".dylib"}
    ]
    assert not addon_entries, f"unreviewed tracked Godot add-ons: {addon_entries}"
    assert not native_extensions, f"unreviewed tracked native dependencies: {native_extensions}"


def require_indexed(relative: str, index_paths: set[str], label: str) -> None:
    assert relative in index_paths, f"{label} must be added to git index: {relative}"


def index_blob_sha256(root: Path, relative: str) -> str:
    result = subprocess.run(
        ["git", "show", f":{relative}"], cwd=root, check=True, capture_output=True,
    )
    return hashlib.sha256(result.stdout).hexdigest()


def require_worktree_matches_index(root: Path, relative: str, index_paths: set[str], label: str) -> None:
    require_indexed(relative, index_paths, label)
    assert file_sha256(root / relative) == index_blob_sha256(root, relative), (
        f"{label} working bytes differ from git index blob: {relative}"
    )


def manifest_sha256(items: list[str]) -> str:
    return hashlib.sha256(("\n".join(items) + "\n").encode("utf-8")).hexdigest()


def file_sha256(path: Path) -> str:
    assert path.is_file(), f"manifest asset missing: {path}"
    return hashlib.sha256(path.read_bytes()).hexdigest()


def validate_u03_manifest(fields: dict[str, str], population: list[str], label: str, root: Path = ROOT) -> None:
    assert fields.get("Inventory-Contract") == "docs/31 sections 2.2 and 4", (
        f"U-03 inventory contract mismatch: {label}"
    )
    assert fields.get("Population-Count") == str(len(population)), f"U-03 population count mismatch: {label}"
    population_records = [f"{path};{file_sha256(root / path)}" for path in population]
    assert fields.get("Population-SHA256") == manifest_sha256(population_records), f"U-03 population hash mismatch: {label}"
    covered: set[str] = set()
    referenced_provenance_ids: set[str] = set()
    for number in range(1, len(population) + 1):
        parts = [part.strip() for part in fields.get(f"Item-{number:04d}", "").split(";")]
        assert len(parts) == 4, f"U-03 Item-{number:04d} requires path;content-sha256;disposition;provenance-id: {label}"
        path, content_sha256, disposition, provenance_id = parts
        assert path in population and path not in covered, f"U-03 invalid/duplicate path: {path}"
        assert content_sha256 == file_sha256(root / path), f"U-03 stale content digest for {path}"
        assert disposition in {"procedural", "ai-generated", "source-derived", "reference-only", "rejected"}, (
            f"U-03 invalid disposition for {path}: {disposition}"
        )
        assert re.fullmatch(r"[A-Z0-9][A-Z0-9_-]{2,63}", provenance_id), (
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
        assert re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]{2,63}", service), (
            f"U-03 invalid generation service: {service}"
        )
        generated_start = parse_generated_at(generated_start_raw, f"U-03 generated-start for {provenance_id}")
        generated_end = parse_generated_at(generated_end_raw, f"U-03 generated-end for {provenance_id}")
        assert generated_start <= generated_end, f"U-03 generation range reversed: {provenance_id}"
        assert re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_-]{2,63}", creator_id), (
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


def validate_u08_manifest(
    fields: dict[str, str], population: list[str], label: str,
    audio_names: list[str], root: Path = ROOT,
) -> None:
    combined = sorted({f"assets/audio/{name}" for name in audio_names} | set(population))
    assert fields.get("Covered-Media") == "suno-and-ai-images", f"U-08 media coverage incomplete: {label}"
    assert fields.get("Population-Count") == str(len(combined)), f"U-08 population count mismatch: {label}"
    population_records = [f"{path};{file_sha256(root / path)}" for path in combined]
    assert fields.get("Population-SHA256") == manifest_sha256(population_records), f"U-08 population hash mismatch: {label}"
    covered: set[str] = set()
    for number in range(1, len(combined) + 1):
        parts = [part.strip() for part in fields.get(f"Item-{number:04d}", "").split(";")]
        assert len(parts) == 4, f"U-08 Item-{number:04d} requires asset;content-sha256;status;rights-id: {label}"
        asset, content_sha256, status, rights_id = parts
        assert asset in combined and asset not in covered, f"U-08 invalid/duplicate asset: {asset}"
        assert content_sha256 == file_sha256(root / asset), f"U-08 stale content digest for {asset}"
        assert status in {"none", "cleared"}, f"U-08 invalid input-rights status for {asset}: {status}"
        assert re.fullmatch(r"[A-Z0-9][A-Z0-9_-]{2,63}", rights_id), f"U-08 invalid rights ID: {asset}"
        covered.add(asset)
    assert covered == set(combined), f"U-08 manifest does not cover U-01/U-03 populations: {label}"
    assert fields.get("Clearance-Complete") == "true", f"U-08 clearance incomplete: {label}"


def validate_u04_rejected(
    fields: dict[str, str], relative: str, saved_paths: list[str],
    parsed_attestations: dict[Path, dict[str, str]], ledger: str,
    project_config: str, root: Path, index_paths: set[str], decision_attestation_path: Path,
    known_original_digest: str = KNOWN_ORIGINAL_ICON_SHA256,
) -> None:
    validate_u04_decision_schema(fields, relative, known_original_digest)
    replacement_product_path = fields.get("Replacement-Product-Path", "")
    posix_path = PurePosixPath(replacement_product_path)
    assert (
        replacement_product_path
        and "\\" not in replacement_product_path
        and "//" not in replacement_product_path
        and not posix_path.is_absolute()
        and all(part not in {"", ".", ".."} for part in posix_path.parts)
        and posix_path.as_posix() == replacement_product_path
    ), f"U-04 replacement path must be canonical repo-relative POSIX path: {replacement_product_path}"
    assert replacement_product_path != "assets/icon.svg", (
        f"U-04 replacement product path is invalid: {relative}"
    )
    assert posix_path.suffix.lower() in {".svg", ".png", ".webp"}, (
        f"U-04 replacement must use an allowed image extension: {replacement_product_path}"
    )
    replacement_path = (root / replacement_product_path).resolve()
    original_icon_path = (root / "assets/icon.svg").resolve()
    assert replacement_path != original_icon_path, "U-04 replacement resolves to original assets/icon.svg"
    assert replacement_path.is_file() and root.resolve() in replacement_path.parents, (
        f"U-04 replacement product file missing: {replacement_product_path}"
    )
    replacement_digest = file_sha256(replacement_path)
    assert replacement_digest != known_original_digest, (
        "U-04 rejected replacement must differ from the persisted original icon bytes"
    )
    if original_icon_path.exists():
        assert file_sha256(original_icon_path) == known_original_digest, (
            "U-04 original assets/icon.svg changed after its baseline digest was fixed"
        )
        assert not replacement_path.samefile(original_icon_path), (
            "U-04 replacement must not be the same inode as original assets/icon.svg"
        )
    require_indexed(replacement_product_path, index_paths, "U-04 replacement product")
    assert fields.get("Replacement-Content-SHA256") == replacement_digest, (
        f"U-04 replacement content digest is stale: {replacement_product_path}"
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
    assert replacement_attestation_path != decision_attestation_path.resolve(), (
        "U-04 replacement rights attestation must be distinct from decision attestation"
    )
    replacement_fields = parsed_attestations.get(replacement_attestation_path)
    assert replacement_fields and replacement_fields.get("Evidence-ID") == "U-04", (
        f"U-04 replacement rights attestation invalid: {replacement_attestation_relative}"
    )
    assert replacement_fields.get("Evidence-Type") == "icon-replacement-rights", (
        f"U-04 replacement rights attestation has wrong schema: {replacement_attestation_relative}"
    )
    assert replacement_fields.get("Replacement-Asset-Path") == replacement_product_path, (
        f"U-04 replacement rights path mismatch: {replacement_attestation_relative}"
    )
    assert replacement_fields.get("Replacement-Content-SHA256") == replacement_digest, (
        f"U-04 replacement rights digest mismatch: {replacement_attestation_relative}"
    )
    assert replacement_fields.get("Replacement-Asset-Rights-Verified") == "true", (
        f"U-04 replacement rights are not verified: {replacement_attestation_relative}"
    )


def validate_completed_attestation_payload(
    evidence_id: str, fields: dict[str, str], relative: str,
    saved_paths: list[str], parsed_attestations: dict[Path, dict[str, str]],
    ledger: str, project_config: str, root: Path, index_paths: set[str],
    saved_path: Path, audio_population: list[str], u03_population: list[str],
) -> None:
    """Apply the same per-evidence close gate used by main and positive fixtures."""
    if evidence_id == "U-01":
        for audio_name in audio_population:
            audio_relative = f"assets/audio/{audio_name}"
            require_worktree_matches_index(root, audio_relative, index_paths, "U-01 audio")
        validate_u01_tracks(fields, relative, audio_population, root)
    elif evidence_id == "U-02":
        validate_u02_period(fields, relative)
    elif evidence_id == "U-03":
        for asset_relative in u03_population:
            require_worktree_matches_index(root, asset_relative, index_paths, "U-03 asset")
        validate_u03_manifest(fields, u03_population, relative, root)
    elif evidence_id == "U-04":
        if fields["Evidence-Type"] == "icon-replacement-rights":
            replacement_asset_path = fields.get("Replacement-Asset-Path", "")
            assert replacement_asset_path and replacement_asset_path in index_paths, (
                f"U-04 replacement rights record references unindexed asset: {relative}"
            )
            assert fields.get("Replacement-Content-SHA256") == file_sha256(root / replacement_asset_path), (
                f"U-04 replacement rights record has stale digest: {relative}"
            )
            require_worktree_matches_index(
                root, replacement_asset_path, index_paths, "U-04 replacement asset"
            )
            assert fields.get("Replacement-Asset-Rights-Verified") == "true", (
                f"U-04 replacement rights are not verified: {relative}"
            )
        else:
            assert fields.get("Product-Decision") in {"adopted", "rejected"}, (
                f"U-04 product decision missing: {relative}"
            )
        if fields.get("Product-Decision") == "adopted":
            require_worktree_matches_index(root, "assets/icon.svg", index_paths, "U-04 adopted icon")
            require_worktree_matches_index(root, "project.godot", index_paths, "U-04 project config")
            assert re.search(
                r'^config/icon\s*=\s*"res://assets/icon\.svg"\s*$',
                project_config,
                flags=re.MULTILINE,
            ), "U-04 adopted decision requires assets/icon.svg as project config/icon"
            assert fields.get("Product-Content-SHA256") == file_sha256(root / "assets/icon.svg"), (
                "U-04 adopted icon content digest is stale"
            )
            assert fields.get("Author-Verified") == "true" and fields.get("Rights-Holder-Verified") == "true", (
                f"U-04 adopted icon author/rights holder is not verified: {relative}"
            )
        elif fields.get("Product-Decision") == "rejected":
            require_worktree_matches_index(root, "project.godot", index_paths, "U-04 project config")
            validate_u04_rejected(
                fields, relative, saved_paths, parsed_attestations,
                ledger, project_config, root, index_paths, saved_path,
            )
    elif evidence_id == "U-05":
        require_worktree_matches_index(root, "LICENSE.md", index_paths, "U-05 license")
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
        assert search_date <= release_today() and result_count >= 0, f"invalid U-06 results: {relative}"
        assert fields.get("Expert-Review") in {"completed", "not-required"}, (
            f"U-06 expert review decision missing: {relative}"
        )
    elif evidence_id == "U-08":
        for audio_name in audio_population:
            require_worktree_matches_index(
                root, f"assets/audio/{audio_name}", index_paths, "U-08 audio"
            )
        for asset_relative in u03_population:
            require_worktree_matches_index(root, asset_relative, index_paths, "U-08 asset")
        validate_u08_manifest(fields, u03_population, relative, audio_population, root)
    else:
        raise AssertionError(f"unsupported completed evidence ID: {evidence_id}")


def audit_dated_rights_snapshot(text: str) -> None:
    """Validate the immutable 2026-07-12 snapshot independently of current state."""
    assert "監査日: 2026-07-12" in text, "dated RIGHTS-01A audit date changed"
    assert "2026-07-12時点の歴史的snapshot" in text, (
        "dated RIGHTS-01A audit missing historical snapshot contract"
    )
    section = text.split("## 監査結果", 1)[1].split("\n## ", 1)[0]
    table_lines = [line.strip() for line in section.splitlines() if line.strip().startswith("|")]
    assert len(table_lines) == 10, "dated RIGHTS-01A audit table must have header, separator, and 8 rows"
    parsed_lines = []
    for line in table_lines:
        assert line.startswith("|") and line.endswith("|"), "dated audit table row boundary invalid"
        cells = [cell.strip() for cell in line[1:-1].split("|")]
        assert len(cells) == 6, f"dated audit table row must have exactly 6 columns: {line}"
        parsed_lines.append(cells)
    assert parsed_lines[0] == ["ID", "現在の主張", "必要証拠", "現存証拠", "判定", "残作業"], (
        "dated RIGHTS-01A audit header changed"
    )
    assert all(re.fullmatch(r"-+", cell) for cell in parsed_lines[1]), (
        "dated RIGHTS-01A audit separator invalid"
    )
    rows = parsed_lines[2:]
    expected_ids = [f"U-{number:02d}" for number in range(1, 9)]
    assert [row[0] for row in rows] == expected_ids, (
        "dated RIGHTS-01A audit must cover U-01 through U-08 once and in order"
    )
    canonical_judgments = {
        "U-01": "pending。個別曲の由来と生成日時をrepoから検証不能",
        "U-02": "pending。申告だけでは生成時点の有料期間を確定不能",
        "U-03": "pending。既知バッチ以外を推定で補完できず、母集団全件のprovenanceが未確定",
        "U-04": "pending。Git著者は作者または法的権利者の証明ではない",
        "U-05": "pending。名前をGit著者等から推定不可",
        "U-06": "pending。対象範囲未決で検索結果もなく、検索だけで法的保証にもならない",
        "U-07": "RIGHTS-01A対象外。RIGHTS-01Bでpending",
        "U-08": "pending。入力権利と第三者権利をrepoから確定不能",
    }
    for row in rows:
        assert all(row), f"dated RIGHTS-01A audit contains empty cell: {row[0]}"
        evidence_id, judgment = row[0], row[4]
        assert judgment == canonical_judgments[evidence_id], (
            f"dated {evidence_id} judgment differs from immutable snapshot"
        )
    conclusion = text.split("## 結論", 1)[1].strip()
    canonical_conclusion = (
        "リポジトリ側で可能な棚卸し、証拠受入形式、機密情報境界、状態判定は準備完了。"
        "U-01〜U-06とU-08は外部証拠待ちのためpendingを維持し、"
        "RIGHTS-01A全体は未完了である。U-07はRIGHTS-01Bとして未完了であり、"
        "この監査でcloseしない。"
    )
    assert conclusion == canonical_conclusion, (
        "dated RIGHTS-01A conclusion differs from immutable snapshot"
    )


def run_negative_self_tests() -> None:
    def must_fail(label: str, operation) -> None:
        try:
            operation()
        except (AssertionError, UnicodeDecodeError):
            return
        raise AssertionError(f"negative fixture unexpectedly passed: {label}")

    privacy_fixture = Path("privacy-fixture.md")
    privacy_negatives = {
        "ASCII HTML tag": "Finding: <span>private evidence</span>",
        "ASCII HTML comment": "Finding: <!-- private evidence -->",
        "Unicode format character": "Finding: safe\u200bhidden",
        "Markdown bracketed Japanese label": "[氏名]: 山田太郎",
        "Markdown inline-link Japanese label": "[氏名](山田太郎)",
        "Markdown reference-link Japanese label": "[氏名][山田太郎]",
        "Japanese fullwidth label separator": "Finding: 氏名：山田太郎",
        "Japanese fullwidth equals": "電話番号＝09012345678",
        "Japanese inline slash with Markdown": "**氏名** / `山田太郎`",
        "Japanese chained slash/colon": "氏名/名前: 山田太郎",
        "Japanese slash table label": "| 氏名 / 名前 | 山田太郎 |",
        "safe enumeration prefix cannot mask PII": (
            "Finding: raw screenshot / PDF / x / 氏名 / 名前: 山田太郎"
        ),
        "English sensitive-word slash value": "Password / token",
        "English Markdown label/value table": "| **Phone** | `090-1234-5678` |",
        "English code label/value table": "| `Account-ID` | **ACCOUNT-123** |",
        "English Name label": "Name: Alice Example",
        "English Name Markdown table": "| **Name** | `Alice Example` |",
        "English First Name table": "| First Name | Alice |",
        "English Last Name table": "| Last Name | Example |",
        "English billing address table": "| Billing Address | Tokyo |",
        "English postal code table": "| Postal Code | 100-0001 |",
        "English vertical Name table": (
            "| Role | **Name** |\n|---|---|\n| reviewer | `Alice Example` |"
        ),
        "English decorated Name table": "| Name (owner) | Alice |",
        "Japanese Markdown label/value table": "| `メールアドレス` | **owner@example.com** |",
        "Japanese bold table label": "| **カード番号** | `4111 1111 1111 1111` |",
        "Japanese contract holder label": "契約者名: 山田太郎",
        "Japanese billing destination label": "請求先: 東京都内",
        "Japanese postal code table": "| 郵便番号 | 100-0001 |",
        "Japanese contact person table": "| 担当者 | 山田 |",
        "Japanese vertical name table": "| 種別 | 氏名 |\n|---|---|\n| 確認者 | 山田太郎 |",
        "Japanese decorated name table": "| 氏名欄 | 山田 |",
        "protocol-relative URL": "Finding: //private.example/evidence",
        "bare URL": "Finding: www.private.example/evidence",
        "Markdown bare URL": "Finding: [private](private.example/evidence)",
        "bare root domain": "Finding: www.private.example",
        "Markdown bare root domain": "Finding: [private](private.example)",
        "multi-label bare domain": "Finding: private.co.uk",
        "arbitrary-TLD bare domain": "Finding: private.tech",
        "trailing-dot bare domain": "Finding: private.example.",
        "local bare domain": "Finding: intranet.local",
        "bare IPv4 path": "Finding: 192.168.1.10/private",
        "bare IPv4 root": "Finding: 10.0.0.1",
        "bare IPv6 path": "Finding: [fd00::1]/private",
        "bare unbracketed IPv6 path": "Finding: fd00::1/private",
        "bare unbracketed IPv6 root": "Finding: fd00::1",
        "bare unbracketed IPv6 before period": "Finding: fd00::1.",
        "bare loopback IPv6 root": "Finding: ::1",
        "bare trailing-compression IPv6 root": "Finding: 2001:db8::",
        "bare localhost path": "Finding: localhost:8080/private",
        "punycode bare domain": "Finding: xn--eckwd4c7c.xn--zckzah/private",
        "IDN bare domain": "Finding: 秘密.example/private",
        "Unicode-TLD IDN path": "Finding: 秘密.テスト/private",
        "Unicode-TLD IDN root": "Finding: 秘密.テスト",
        "Unicode-TLD IDN trailing dot": "Finding: 秘密.テスト.",
        "quoted Unicode-TLD IDN": "Finding: 「秘密.テスト」",
        "Japanese-comma bounded Unicode-TLD IDN": "確認、秘密.テスト、",
        "Japanese-period bounded Unicode-TLD IDN": "確認。秘密.テスト。",
        "Japanese-semicolon bounded Unicode-TLD IDN": "確認；秘密.テスト；",
        "ideographic-dot Unicode IDN path": "Finding: 秘密。テスト/private",
        "long-label ideographic-dot Unicode IDN path": "Finding: 内部秘密。テスト/private",
        "whitespace-bounded ideographic-dot IDN": "接続先は 秘密。テスト",
        "adjacent contextual ideographic-dot IDN": "接続先は秘密。テスト",
        "URL-context ideographic-dot IDN": "URLは秘密。テスト",
        "arrow-context ideographic-dot IDN": "接続先→秘。テスト",
        "link-destination contextual IDN": "リンク先は秘。テスト",
        "link-destination colon IDN": "リンク先: private。example",
        "link-destination quoted IDN": "リンク先「秘。テスト」",
        "trailing-dot ideographic IDN path": "内部秘密。テスト./private",
        "ideographic-trailing-dot IDN path": "秘。テスト。/p",
        "contextual ASCII-label Unicode-dot path": "接続先はprivate。example/path",
        "ASCII-label Unicode-dot trailing dot": "private。example.",
        "Unicode-dot bare domain": "Finding: private。example/path",
        "mixed Unicode-dot path": "Finding: 内部秘密。example/path",
        "intra-label mixed Unicode-dot path": "Finding: a秘。example/path",
        "twice-encoded protocol-relative URL": "Finding: &amp;#x2f;&amp;#x2f;private.example/evidence",
        "fullwidth amp nested URL": "Finding: ＆amp;#x2f;＆amp;#x2f;private.example/evidence",
        "fullwidth hash nested URL": "Finding: &amp;＃x2f;&amp;＃x2f;private.example/evidence",
        "nested encoded Japanese PII": "Finding: &#x6c0f;&#x540d;&amp;#x3a;山田太郎",
        "macOS absolute user path": "Finding: /Users/alice/private/evidence.pdf",
        "Linux absolute user path": "Finding: /home/alice/private/evidence.pdf",
        "nested Linux home path": "Finding: /var/home/alice/private/evidence.pdf",
        "mounted macOS home path": "Finding: /Volumes/Disk/Users/alice/private/evidence.pdf",
        "root absolute user path": "Finding: /root/private/evidence.pdf",
        "nested root home path": "Finding: /var/root/private/evidence.pdf",
        "general absolute POSIX path": "Finding: /private/var/evidence.pdf",
        "single-slash file URI": "Finding: file:/private/var/evidence.pdf",
        "Windows absolute user path": r"Finding: C:\Users\Alice\private\evidence.pdf",
        "Windows forward-slash user path": "Finding: C:/Users/Alice/private/evidence.pdf",
        "Windows profile path": r"Finding: D:\Profiles\Alice\private\evidence.pdf",
        "Windows UNC path": r"Finding: \\private-server\evidence\raw.pdf",
        "home shorthand path": "Finding: ~/private/evidence.pdf",
        "parent traversal path": "Finding: ../private/evidence.pdf",
        "embedded parent traversal path": "Finding: assets/../private/evidence.pdf",
        "Windows parent traversal path": r"Finding: assets\..\private\evidence.pdf",
        "encoded traversal path": "Finding: &amp;#x2e;&amp;#x2e;&amp;#x2f;private/evidence.pdf",
        "percent-encoded traversal path": "Finding: assets/%252e%252e%252fprivate/evidence.pdf",
        "long raw base64": f"Finding: {'A' * 160}",
        "long raw base64url": f"Finding: {'A_' * 80}",
        "wrapped raw base64": f"{'A' * 76}\n{'B' * 76}",
        "three short wrapped base64 chunks": f"Finding: {'A' * 50}\n{'B' * 50}\n{'C' * 50}",
        "short PNG base64": "Finding: iVBORw0KGgoAAAANSUhEUg",
        "space-wrapped field base64": f"Finding: {'A' * 76} {'B' * 76}",
        "field-prefixed wrapped base64": f"Finding: {'A' * 76}\nNote: {'B' * 76}",
        "spaced card number": "Finding: 4111 1111 1111 1111",
        "double-spaced card number": "Finding: 4111  1111  1111  1111",
        "tab-spaced card number": "Finding: 4111\t1111\t1111\t1111",
        "hyphenated card number": "Finding: 4111-1111-1111-1111",
        "twelve-digit card-like number": "Finding: 4111-1111-1111",
        "slash-separated card number": "Finding: 4111/1111/1111/1111",
        "mixed-separator card number": "Finding: 4111-1111 1111-1111",
        "spaced-hyphen card number": "Finding: 4111 - 1111 - 1111 - 1111",
        "spaced-slash card number": "Finding: 4111 / 1111 / 1111 / 1111",
        "Japanese mobile phone": "Finding: 090-1234-5678",
        "Japanese dotted phone": "Finding: 090.1234.5678",
        "Japanese landline phone": "Finding: 03-1234-5678",
        "Japanese long-dash phone": "Finding: 090ー1234ー5678",
        "Japanese parenthesized phone": "Finding: 03(1234)5678",
        "Japanese contiguous phone": "Finding: 09012345678",
        "international Japanese phone": "Finding: +81-90-1234-5678",
    }
    for label, public_text in privacy_negatives.items():
        must_fail(
            label,
            lambda public_text=public_text: scan_public_text(
                public_text, privacy_fixture, allow_official_urls=True,
            ),
        )
    for official_url in sorted(OFFICIAL_PUBLIC_URLS):
        scan_public_text(
            f"公式一次情報: {official_url}", privacy_fixture, allow_official_urls=True,
        )
    scan_public_text(
        "repo-relative paths: project.godot docs/31_asset_ledger.md assets/icon.svg "
        "tools/source_assets/**/*.png reference/02_underwater_fight_mockup.png "
        "tools/audit.py reference/foo.png docs/plan.md",
        privacy_fixture,
        allow_official_urls=True,
    )
    scan_public_text(
        "公開禁止ラベルの列挙: 氏名、メールアドレス、住所、電話番号。| 項目 | 内容 |",
        privacy_fixture,
        allow_official_urls=True,
    )
    scan_public_text(
        f"benign numeric text: v1.0.0 / 3.14159 / 2026-07-11; repo: docs/plan.md; "
        f"sha256: {'0123456789abcdef' * 4}",
        privacy_fixture,
        allow_official_urls=True,
    )
    scan_public_text(
        "benign boundaries: 12:34:56 2026-07-11T12:34:56+09:00 ratio 1:2:3 "
        "versions v2.3.4 decimal 12345.6789 ratio 1920/1080 "
        "repo `assets/showcase/example.v1.png` `docs/qa/evidence/2026-07-11/build_1234.md`",
        privacy_fixture,
        allow_official_urls=True,
    )
    scan_public_text(
        "確認済み。問題なし\nこれは説明。続きです\n成功。完了\n正常。完了\n"
        "曖昧rootは許可: 秘密。example private。テスト 完了。next SVG。Godot",
        privacy_fixture,
        allow_official_urls=True,
    )
    management_readme_path = (ROOT / "docs/qa/evidence/licensing/README.md").resolve()
    management_readme = management_readme_path.read_text(encoding="utf-8")
    main_injection_payloads = (
        "確認: 秘密.テスト fd00::1 [氏名](山田太郎) 4111-1111 1111-1111",
        "秘密.テスト",
        "fd00::1",
        "[氏名](山田太郎)",
        "4111-1111 1111-1111",
        "接続先は秘密。テスト",
        "URLは秘密。テスト",
        "接続先はprivate。example/path",
        "private。example.",
        "内部秘密。テスト./private",
        "内部秘密。example/path",
        "a秘。example/path",
        "秘。テスト。/p",
        "接続先→秘。テスト",
        "リンク先は秘。テスト",
        "リンク先: private。example",
        "リンク先「秘。テスト」",
    )
    for injected_payload in main_injection_payloads:
        injected_management_readme = f"{management_readme}\n{injected_payload}\n"
        captured_stdout = io.StringIO()
        captured_stderr = io.StringIO()
        with redirect_stdout(captured_stdout), redirect_stderr(captured_stderr):
            injected_main_result = main({management_readme_path: injected_management_readme})
        assert injected_main_result == 1 and "licensing audit: FAIL:" in captured_stderr.getvalue(), (
            f"main accepted private management README payload: {injected_payload}"
        )
    boundary_instant = datetime(2026, 7, 10, 15, 30, tzinfo=timezone.utc)
    previous_tz = os.environ.get("TZ")
    try:
        for process_tz in ("Asia/Tokyo", "UTC", "Pacific/Honolulu"):
            os.environ["TZ"] = process_tz
            if hasattr(time, "tzset"):
                time.tzset()
            assert release_today(boundary_instant) == date(2026, 7, 11), (
                f"release evidence date changed with process TZ={process_tz}"
            )
    finally:
        if previous_tz is None:
            os.environ.pop("TZ", None)
        else:
            os.environ["TZ"] = previous_tz
        if hasattr(time, "tzset"):
            time.tzset()
    validate_u02_period(
        {
            "Plan": "Pro", "Period-Start": "2026-07-01", "Period-End": "2026-08-01",
            "Evidence-As-Of": "2026-07-11", "Reviewed-At": "2026-07-11",
            "Covers-U-01": "true",
        },
        "active renewal fixture",
        audit_date=release_today(boundary_instant),
    )
    must_fail(
        "U-02 Evidence-As-Of extends into a future Asia/Tokyo date",
        lambda: validate_u02_period(
            {
                "Plan": "Pro", "Period-Start": "2026-07-01", "Period-End": "2026-08-01",
                "Evidence-As-Of": "2026-07-12", "Reviewed-At": "2026-07-12",
                "Covers-U-01": "true",
            },
            "JST boundary fixture",
            audit_date=release_today(boundary_instant),
        ),
    )

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
        (attestations / ".gitkeep").write_text("Card-Last4: 4242", encoding="utf-8")
        must_fail("nonempty gitkeep", lambda: audit_evidence_tree(root))

    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        (root / "README.md").write_text("Customer-Name: Alice", encoding="utf-8")
        must_fail("management markdown PII", lambda: audit_evidence_tree(root))

    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        (root / "README.md").write_text("Card-Last-4: 4242", encoding="utf-8")
        must_fail("management Card-Last-4", lambda: audit_evidence_tree(root))

    for decorated in (
        "> Customer-Name: Alice", "| Phone: 090-0000 |", "**Address: secret**",
        "> Card-Last-4: 4242", "| **Password: hunter2** |",
        "**Customer-Name**: Alice", "| **Customer-Name**: Alice |", "- `Password`: hunter2",
        "確認欄 Customer-Name: Alice", "note: Password: hunter2",
    ):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            (root / "README.md").write_text(decorated, encoding="utf-8")
            must_fail("management decorated PII", lambda root=root: audit_evidence_tree(root))

    common_attestation_lines = (
        "Evidence-ID: U-01", "Evidence-Type: suno-track-provenance",
        f"Original-SHA256: {'1234567890abcdef' * 4}", "Reviewed-At: 2026-07-11",
        "Reviewer: reviewer-1", "Private-Storage-Reference: EVIDENCE-12345",
        "Redaction-Checked: true", "Finding: track-provenance-verified",
        "Asset-Count: 0", "One-to-One-Mapping-Verified: true",
    )
    for label, old_line, new_line in (
        (
            "arbitrary Finding summary",
            "Finding: track-provenance-verified",
            "Finding: arbitrary sanitized summary",
        ),
        ("dotted Reviewer ID", "Reviewer: reviewer-1", "Reviewer: reviewer.team"),
        (
            "dotted private storage ID",
            "Private-Storage-Reference: EVIDENCE-12345",
            "Private-Storage-Reference: EVIDENCE.TEAM",
        ),
    ):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            attestations = root / "attestations"
            attestations.mkdir()
            fixture = attestations / "U-01_schema_negative.md"
            fixture.write_text(
                "\n".join(new_line if line == old_line else line for line in common_attestation_lines),
                encoding="utf-8",
            )
            must_fail(label, lambda root=root: audit_evidence_tree(root))
    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        attestations = root / "attestations"
        attestations.mkdir()
        unknown = attestations / "U-01_unknown.md"
        unknown.write_text("\n".join((*common_attestation_lines, "Card-Last-4: 4242")), encoding="utf-8")
        must_fail("unknown Card-Last-4 attestation field", lambda: audit_evidence_tree(root))

    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        attestations = root / "attestations"
        attestations.mkdir()
        duplicate = attestations / "U-01_duplicate.md"
        duplicate.write_text(
            "\n".join((*common_attestation_lines, "Finding: contradictory duplicate finding")),
            encoding="utf-8",
        )
        must_fail("duplicate attestation key", lambda: audit_evidence_tree(root))

    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        attestations = root / "attestations"
        attestations.mkdir()
        extra_track = attestations / "U-01_extra_track.md"
        extra_track.write_text(
            "\n".join((*common_attestation_lines, "Track-9999: ignored")), encoding="utf-8"
        )
        must_fail("extra Track-9999", lambda: audit_evidence_tree(root))

    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        attestations = root / "attestations"
        attestations.mkdir()
        mismatch = attestations / "U-01_type_mismatch.md"
        mismatch.write_text(
            "\n".join((
                "Evidence-ID: U-01", "Evidence-Type: trademark-clearance",
                f"Original-SHA256: {'1234567890abcdef' * 4}", "Reviewed-At: 2026-07-11",
                "Reviewer: reviewer-1", "Private-Storage-Reference: EVIDENCE-12345",
                "Redaction-Checked: true", "Finding: trademark-clearance-reviewed",
                "Territories: JP", "Trademark-Classes: 9", "Official-DB: J-PlatPat",
                "Search-Date: 2026-07-11", "Result-Count: 0", "Expert-Review: not-required",
            )), encoding="utf-8",
        )
        must_fail("Evidence-ID/type mismatch", lambda: audit_evidence_tree(root))

    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        attestations = root / "attestations"
        attestations.mkdir()
        extra_item = attestations / "U-03_extra_item.md"
        extra_item.write_text(
            "\n".join((
                "Evidence-ID: U-03", "Evidence-Type: ai-image-provenance",
                f"Original-SHA256: {'1234567890abcdef' * 4}", "Reviewed-At: 2026-07-11",
                "Reviewer: reviewer-1", "Private-Storage-Reference: EVIDENCE-12345",
                "Redaction-Checked: true", "Finding: image-provenance-verified",
                "Inventory-Contract: docs/31 sections 2.2 and 4", "Population-Count: 0",
                f"Population-SHA256: {'abcdef0123456789' * 4}", "Provenance-Count: 0",
                "Unresolved-Items: 0", "Provenance-Complete: true",
                "Item-999999: ignored",
            )), encoding="utf-8",
        )
        must_fail("extra Item-999999", lambda: audit_evidence_tree(root))

    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        attestations = root / "attestations"
        attestations.mkdir()
        replacement_record = attestations / "U-04_replacement.md"
        replacement_lines = (
            "Evidence-ID: U-04", "Evidence-Type: icon-replacement-rights",
            f"Original-SHA256: {'1234567890abcdef' * 4}", "Reviewed-At: 2026-07-11",
            "Reviewer: reviewer-1", "Private-Storage-Reference: EVIDENCE-12345",
            "Redaction-Checked: true", "Finding: replacement-rights-verified",
            "Replacement-Asset-Path: assets/product_icon.svg",
            f"Replacement-Content-SHA256: {'abcdef0123456789' * 4}",
            "Replacement-Asset-Rights-Verified: true",
        )
        replacement_record.write_text("\n".join(replacement_lines), encoding="utf-8")
        audit_evidence_tree(root)
        replacement_record.write_text(
            "\n".join((*replacement_lines, "Product-Decision: rejected")), encoding="utf-8",
        )
        must_fail(
            "U-04 replacement-rights record contains decision payload",
            lambda: audit_evidence_tree(root),
        )

    for embedded in (
        "![billing](data:image/png;base64,AAAA)",
        '<embed src="data:application/pdf;base64,AAAA">',
        "blob:https://private.example/secret",
    ):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            (root / "README.md").write_text(embedded, encoding="utf-8")
            must_fail("management embedded raw evidence", lambda root=root: audit_evidence_tree(root))

    for secret_label in (
        "Password: hunter2",
        "Private-Storage-Password = secret",
        "Access-Token: token-value",
        "API_Key = key-value",
    ):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            (root / "README.md").write_text(secret_label, encoding="utf-8")
            must_fail("management credential label", lambda root=root: audit_evidence_tree(root))

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
                "Redaction-Checked: true", "Finding: track-provenance-verified",
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
                    "Redaction-Checked: true", "Finding: track-provenance-verified",
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
        "docs/30 visible premature completion",
        lambda: audit_rights_state(
            {"U-01"}, set(),
            "[RIGHTS-01A]=pending\n| RIGHTS-01A | **完了** | 全件close済み |",
        ),
    )
    must_fail(
        "U-04 rejected without replacement",
        lambda: validate_u04_rejected(
            {"Product-Decision": "rejected"}, "fixture", [], {}, "", "", ROOT, set(), ROOT / "decision.md",
        ),
    )
    with tempfile.TemporaryDirectory() as temp_dir:
        fixture_root = Path(temp_dir)
        replacement_relative = "assets/replacement.svg"
        replacement = fixture_root / replacement_relative
        replacement.parent.mkdir(parents=True)
        replacement.write_text("<svg/>", encoding="utf-8")
        original_fixture_icon = fixture_root / "assets/icon.svg"
        original_fixture_icon.write_text("<svg>original</svg>", encoding="utf-8")
        baseline_digest = file_sha256(original_fixture_icon)
        decision_path = (fixture_root / "docs/qa/evidence/licensing/attestations/U-04_decision.md").resolve()
        rights_relative = "docs/qa/evidence/licensing/attestations/U-04_replacement.md"
        rights_path = (fixture_root / rights_relative).resolve()
        decision_path.parent.mkdir(parents=True)
        decision_path.write_text("decision", encoding="utf-8")
        rights_path.write_text("rights", encoding="utf-8")
        digest = file_sha256(replacement)
        decision_fields = {
            "Product-Decision": "rejected", "Replacement-Integrated": "true",
            "Baseline-Original-Content-SHA256": baseline_digest,
            "Replacement-Product-Path": replacement_relative,
            "Replacement-Content-SHA256": digest,
            "Replacement-Rights-Attestation": rights_relative,
        }
        rights_fields = {
            "Evidence-ID": "U-04", "Evidence-Type": "icon-replacement-rights",
            "Replacement-Asset-Path": replacement_relative,
            "Replacement-Content-SHA256": digest,
            "Replacement-Asset-Rights-Verified": "true",
        }
        ledger_fixture = f"{replacement_relative}\n[RIGHTS-01A:U-04-REPLACEMENT]=integrated"
        config_fixture = f'config/icon="res://{replacement_relative}"'
        validate_u04_rejected(
            decision_fields, "fixture", [rights_relative], {rights_path: rights_fields},
            ledger_fixture, config_fixture, fixture_root, {replacement_relative}, decision_path,
            baseline_digest,
        )
        adopted_fields = {
            "Product-Decision": "adopted",
            "Baseline-Original-Content-SHA256": baseline_digest,
            "Product-Content-SHA256": baseline_digest,
            "Author-Verified": "true",
            "Rights-Holder-Verified": "true",
        }
        validate_u04_decision_schema(adopted_fields, "fixture adopted", baseline_digest)
        adopted_with_replacement = dict(adopted_fields)
        adopted_with_replacement["Replacement-Integrated"] = "true"
        must_fail(
            "U-04 adopted decision contains rejected payload",
            lambda: validate_u04_decision_schema(
                adopted_with_replacement, "fixture adopted conflict", baseline_digest,
            ),
        )
        rejected_with_adopted = dict(decision_fields)
        rejected_with_adopted["Author-Verified"] = "true"
        must_fail(
            "U-04 rejected decision contains adopted-only payload",
            lambda: validate_u04_decision_schema(
                rejected_with_adopted, "fixture rejected conflict", baseline_digest,
            ),
        )
        stale_baseline = dict(decision_fields)
        stale_baseline["Baseline-Original-Content-SHA256"] = "a" * 64
        must_fail(
            "U-04 decision changes persisted original digest",
            lambda: validate_u04_decision_schema(
                stale_baseline, "fixture stale baseline", baseline_digest,
            ),
        )
        self_reference = dict(decision_fields)
        self_reference["Replacement-Rights-Attestation"] = decision_path.relative_to(fixture_root.resolve()).as_posix()
        must_fail(
            "U-04 self-reference",
            lambda: validate_u04_rejected(
                self_reference, "fixture", [self_reference["Replacement-Rights-Attestation"]],
                {decision_path: rights_fields}, ledger_fixture, config_fixture,
                fixture_root, {replacement_relative}, decision_path, baseline_digest,
            ),
        )
        must_fail(
            "U-04 untracked replacement",
            lambda: validate_u04_rejected(
                decision_fields, "fixture", [rights_relative], {rights_path: rights_fields},
                ledger_fixture, config_fixture, fixture_root, set(), decision_path, baseline_digest,
            ),
        )
        traversal = dict(decision_fields)
        traversal["Replacement-Product-Path"] = "assets/../assets/icon.svg"
        must_fail(
            "U-04 replacement path traversal to original icon",
            lambda: validate_u04_rejected(
                traversal, "fixture", [rights_relative], {rights_path: rights_fields},
                ledger_fixture, config_fixture, fixture_root,
                {"assets/../assets/icon.svg"}, decision_path, baseline_digest,
            ),
        )
        same_bytes_relative = "assets/icon_copy.svg"
        same_bytes_path = fixture_root / same_bytes_relative
        same_bytes_path.write_bytes(original_fixture_icon.read_bytes())
        same_bytes_fields = dict(decision_fields)
        same_bytes_fields["Replacement-Product-Path"] = same_bytes_relative
        same_bytes_fields["Replacement-Content-SHA256"] = file_sha256(same_bytes_path)
        same_rights = dict(rights_fields)
        same_rights["Replacement-Asset-Path"] = same_bytes_relative
        same_rights["Replacement-Content-SHA256"] = file_sha256(same_bytes_path)
        original_fixture_icon.unlink()
        must_fail(
            "U-04 same original bytes after assets/icon.svg deletion",
            lambda: validate_u04_rejected(
                same_bytes_fields, "fixture", [rights_relative], {rights_path: same_rights},
                f"{same_bytes_relative}\n[RIGHTS-01A:U-04-REPLACEMENT]=integrated",
                f'config/icon="res://{same_bytes_relative}"', fixture_root,
                {same_bytes_relative}, decision_path, baseline_digest,
            ),
        )
        validate_u04_rejected(
            decision_fields, "fixture after original deletion", [rights_relative],
            {rights_path: rights_fields}, ledger_fixture, config_fixture,
            fixture_root, {replacement_relative}, decision_path, baseline_digest,
        )
        replacement.write_text("<svg>changed</svg>", encoding="utf-8")
        must_fail(
            "U-04 replacement bytes changed after evidence",
            lambda: validate_u04_rejected(
                decision_fields, "fixture", [rights_relative], {rights_path: rights_fields},
                ledger_fixture, config_fixture, fixture_root, {replacement_relative}, decision_path,
                baseline_digest,
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
    with tempfile.TemporaryDirectory() as temp_dir:
        fixture_root = Path(temp_dir)
        fixture_asset = fixture_root / "assets/showcase/example.png"
        fixture_asset.parent.mkdir(parents=True)
        fixture_asset.write_bytes(b"png-fixture")
        one_item_population = ["assets/showcase/example.png"]
        one_item_digest = file_sha256(fixture_asset)
        must_fail(
            "U-03 item without provenance record",
            lambda: validate_u03_manifest(
                {
                    "Inventory-Contract": "docs/31 sections 2.2 and 4",
                    "Population-Count": "1",
                    "Population-SHA256": manifest_sha256([f"assets/showcase/example.png;{one_item_digest}"]),
                    "Item-0001": f"assets/showcase/example.png;{one_item_digest};ai-generated;PROV-001",
                    "Provenance-Count": "0", "Unresolved-Items": "0", "Provenance-Complete": "true",
                },
                one_item_population, "fixture", fixture_root,
            ),
        )
        valid_u03 = {
            "Inventory-Contract": "docs/31 sections 2.2 and 4",
            "Population-Count": "1",
            "Population-SHA256": manifest_sha256([f"assets/showcase/example.png;{one_item_digest}"]),
            "Item-0001": f"assets/showcase/example.png;{one_item_digest};ai-generated;PROV-001",
            "Provenance-Count": "1",
            "Provenance-0001": "PROV-001;OpenAI;2026-07-10T10:00:00+09:00;2026-07-10T10:01:00+09:00;creator-1",
            "Unresolved-Items": "0", "Provenance-Complete": "true",
        }
        validate_u03_manifest(valid_u03, one_item_population, "fixture", fixture_root)
        for label, replacement in (
            (
                "U-03 dotted provenance ID",
                {"Item-0001": f"assets/showcase/example.png;{one_item_digest};ai-generated;PROV.001"},
            ),
            (
                "U-03 dotted service ID",
                {"Provenance-0001": "PROV-001;Open.AI;2026-07-10T10:00:00+09:00;2026-07-10T10:01:00+09:00;creator-1"},
            ),
            (
                "U-03 dotted creator ID",
                {"Provenance-0001": "PROV-001;OpenAI;2026-07-10T10:00:00+09:00;2026-07-10T10:01:00+09:00;creator.1"},
            ),
        ):
            dotted_u03 = dict(valid_u03)
            dotted_u03.update(replacement)
            must_fail(
                label,
                lambda dotted_u03=dotted_u03: validate_u03_manifest(
                    dotted_u03, one_item_population, "fixture", fixture_root,
                ),
            )
        valid_u08 = {
            "Covered-Media": "suno-and-ai-images",
            "Population-Count": "1",
            "Population-SHA256": manifest_sha256(
                [f"assets/showcase/example.png;{one_item_digest}"]
            ),
            "Item-0001": f"assets/showcase/example.png;{one_item_digest};none;RIGHTS_001",
            "Clearance-Complete": "true",
        }
        validate_u08_manifest(valid_u08, one_item_population, "fixture", [], fixture_root)
        dotted_u08 = dict(valid_u08)
        dotted_u08["Item-0001"] = (
            f"assets/showcase/example.png;{one_item_digest};none;RIGHTS.001"
        )
        must_fail(
            "U-08 dotted rights ID",
            lambda: validate_u08_manifest(
                dotted_u08, one_item_population, "fixture", [], fixture_root,
            ),
        )
        fixture_asset.write_bytes(b"png-fixture-changed")
        must_fail(
            "U-03 content replaced after evidence",
            lambda: validate_u03_manifest(valid_u03, one_item_population, "fixture", fixture_root),
        )
    must_fail(
        "U-08 generic flags without manifest",
        lambda: validate_u08_manifest(
            {"Covered-Media": "suno-and-ai-images", "Clearance-Complete": "true"}, [], "fixture", [],
        ),
    )
    must_fail(
        "ledger top marker only",
        lambda: audit_ledger_evidence_state("U-03", False, "[RIGHTS-01A:U-03]=complete"),
    )
    audit_ledger_evidence_state("U-03", False, "[RIGHTS-01A:U-03]=complete\nU-03解決済み")
    audit_ledger_evidence_state("U-01", False, "U-01解決済み\nU-02待ち")
    audit_ledger_evidence_state("U-02", True, "U-01解決済み\nU-02待ち")
    # docs/31 §4 must describe all three reachable U-03/U-08 transitions exactly.
    audit_ledger_section_states(
        {"U-03", "U-08"},
        "## 3. 音源（BGM / SE） — 解決済み\n"
        "## 4. AI生成画像（外部サービス由来） — **要記入**\n"
        "U-03待ち / U-08待ち / | item | 未完 |",
    )
    audit_ledger_section_states(
        {"U-08"},
        "## 3. 音源（BGM / SE） — 解決済み\n"
        "## 4. AI生成画像（外部サービス由来） — **要記入**\n"
        "U-03解決済み / U-08待ち",
    )
    audit_ledger_section_states(
        set(),
        "## 3. 音源（BGM / SE） — 解決済み\n"
        "## 4. AI生成画像（外部サービス由来） — 解決済み\n"
        "U-03解決済み / U-08解決済み / 全件確認済み",
    )
    must_fail(
        "docs31 pending and resolved AI headings coexist",
        lambda: audit_ledger_section_states(
            {"U-03", "U-08"},
            "## 3. 音源（BGM / SE） — 解決済み\n"
            "## 4. AI生成画像（外部サービス由来） — **要記入**\nU-03待ち / U-08待ち\n"
            "## 4. AI生成画像（外部サービス由来） — 解決済み\nU-03解決済み / U-08解決済み",
        ),
    )
    must_fail(
        "docs31 canonical AI source scope heading missing",
        lambda: audit_ledger_section_states(
            {"U-03", "U-08"},
            "## 3. 音源（BGM / SE） — 解決済み\n"
            "## 4. AI生成画像（外部サービス由来） — **要記入**\nU-03待ち / U-08待ち",
            require_source_scope=True,
        ),
    )
    must_fail(
        "docs31 U-03-resolved source scope retains stale provenance prose",
        lambda: audit_ledger_section_states(
            {"U-08"},
            "### 2.2 `tools/source_assets/**` / `reference/**` を消費するパイプライン（全件追跡対象）\n"
            "生成サービス・生成日は未確定、所有者証拠待ち\n"
            "## 3. 音源（BGM / SE） — 解決済み\n"
            "## 4. AI生成画像（外部サービス由来） — **要記入**\nU-03解決済み / U-08待ち",
            require_source_scope=True,
        ),
    )
    must_fail(
        "docs31 duplicate resolved AI heading",
        lambda: audit_ledger_section_states(
            set(),
            "## 3. 音源（BGM / SE） — 解決済み\n"
            "## 4. AI生成画像（外部サービス由来） — 解決済み\nU-03解決済み / U-08解決済み\n"
            "## 4. AI生成画像（外部サービス由来） — 解決済み\nU-03解決済み / U-08解決済み",
        ),
    )
    audit_ledger_section_states(
        {"U-02", "U-08"},
        "## 3. 音源（BGM / SE） — 条件確認済み・証拠待ち\nU-01解決済み\nU-02待ち\n"
        "## 4. AI生成画像（外部サービス由来） — **要記入**\nU-03解決済み / U-08待ち",
    )
    must_fail(
        "partial audio transition retains U-01 pending prose",
        lambda: audit_ledger_section_states(
            {"U-02", "U-08"},
            "## 3. 音源（BGM / SE） — 条件確認済み・証拠待ち\nU-01待ち\nU-02待ち\n"
            "## 4. AI生成画像（外部サービス由来） — **要記入**\nU-03解決済み / U-08待ち",
        ),
    )
    must_fail(
        "fully resolved audio table retains 未完了",
        lambda: audit_ledger_section_states(
            {"U-08"},
            "## 3. 音源（BGM / SE） — 解決済み\n| 証拠保全 | **未完了**。生成日時と加入期間証拠が必要 |\n"
            "## 4. AI生成画像（外部サービス由来） — **要記入**\nU-03解決済み / U-08待ち",
        ),
    )
    for stale in ("U-03待ち", "未完", "未確定", "証拠待ち", "ユーザー入力待ち"):
        must_fail(
            f"docs31 U-03-resolved section retains {stale}",
            lambda stale=stale: audit_ledger_section_states(
                {"U-08"},
                "## 3. 音源（BGM / SE） — 解決済み\n"
                "## 4. AI生成画像（外部サービス由来） — **要記入**\n"
                f"U-03解決済み / U-08待ち / {stale}",
            ),
        )
    for stale in ("U-03待ち", "U-08待ち", "未完", "未確定", "証拠待ち", "ユーザー入力待ち"):
        must_fail(
            f"docs31 fully resolved section retains {stale}",
            lambda stale=stale: audit_ledger_section_states(
                set(),
                "## 3. 音源（BGM / SE） — 解決済み\n"
                "## 4. AI生成画像（外部サービス由来） — 解決済み\n"
                f"U-03解決済み / U-08解決済み / {stale}",
            ),
        )
    for evidence_id in ("U-01", "U-02", "U-03", "U-05", "U-06", "U-08"):
        audit_canonical_attestation_counts(
            {evidence_id: [{"Evidence-ID": evidence_id, "Finding": "canonical"}]},
            {evidence_id},
        )
        must_fail(
            f"multiple contradictory {evidence_id} attestations",
            lambda evidence_id=evidence_id: audit_canonical_attestation_counts(
                {
                    evidence_id: [
                        {"Evidence-ID": evidence_id, "Finding": "decision-a"},
                        {"Evidence-ID": evidence_id, "Finding": "decision-b"},
                    ],
                },
                {evidence_id},
            ),
        )
    must_fail(
        "contradictory U-03/U-08 canonical attestations",
        lambda: audit_canonical_attestation_counts(
            {
                "U-03": [{"Finding": "provenance-a"}, {"Finding": "provenance-b"}],
                "U-08": [{"Finding": "rights-a"}, {"Finding": "rights-b"}],
            },
            {"U-03", "U-08"},
        ),
    )
    audit_canonical_attestation_counts(
        {"U-04": [{"Evidence-Type": "icon-rights", "Product-Decision": "adopted"}]},
        {"U-04"},
    )
    audit_canonical_attestation_counts(
        {
            "U-04": [
                {"Evidence-Type": "icon-rights", "Product-Decision": "rejected"},
                {"Evidence-Type": "icon-replacement-rights"},
            ],
        },
        {"U-04"},
    )
    must_fail(
        "U-04 adopted with replacement attestation",
        lambda: audit_canonical_attestation_counts(
            {
                "U-04": [
                    {"Evidence-Type": "icon-rights", "Product-Decision": "adopted"},
                    {"Evidence-Type": "icon-replacement-rights"},
                ],
            },
            {"U-04"},
        ),
    )
    with tempfile.TemporaryDirectory() as temp_dir:
        fixture_root = Path(temp_dir).resolve()
        decision_relative = "docs/qa/evidence/licensing/attestations/U-04_decision.md"
        replacement_relative = "docs/qa/evidence/licensing/attestations/U-04_replacement.md"
        parsed_u04 = {
            (fixture_root / decision_relative).resolve(): {
                "Evidence-ID": "U-04", "Evidence-Type": "icon-rights",
            },
            (fixture_root / replacement_relative).resolve(): {
                "Evidence-ID": "U-04", "Evidence-Type": "icon-replacement-rights",
            },
        }
        audit_completed_attestation_references(
            "U-04", [decision_relative, replacement_relative], parsed_u04, fixture_root,
        )
        must_fail(
            "U-04 completed row omits canonical decision attestation",
            lambda: audit_completed_attestation_references(
                "U-04", [replacement_relative], parsed_u04, fixture_root,
            ),
        )
    must_fail(
        "untracked completed attestation",
        lambda: require_indexed(
            "docs/qa/evidence/licensing/attestations/U-01_fixture.md", set(), "fixture attestation",
        ),
    )
    with tempfile.TemporaryDirectory() as temp_dir:
        fixture_root = Path(temp_dir)
        fixture_file = fixture_root / "evidence.md"
        fixture_file.write_text("staged", encoding="utf-8")
        subprocess.run(["git", "init", "-q"], cwd=fixture_root, check=True)
        subprocess.run(["git", "add", "evidence.md"], cwd=fixture_root, check=True)
        fixture_file.write_text("unstaged-change", encoding="utf-8")
        must_fail(
            "staged evidence followed by unstaged byte change",
            lambda: require_worktree_matches_index(
                fixture_root, "evidence.md", {"evidence.md"}, "fixture evidence",
            ),
        )
    with tempfile.TemporaryDirectory() as temp_dir:
        fixture_root = Path(temp_dir)
        japanese_file = fixture_root / "assets/audio/日本語曲.mp3"
        japanese_file.parent.mkdir(parents=True)
        japanese_file.write_bytes(b"audio")
        subprocess.run(["git", "init", "-q"], cwd=fixture_root, check=True)
        subprocess.run(["git", "config", "core.quotePath", "true"], cwd=fixture_root, check=True)
        subprocess.run(["git", "add", "assets/audio/日本語曲.mp3"], cwd=fixture_root, check=True)
        assert "assets/audio/日本語曲.mp3" in git_ls_files(fixture_root), (
            "NUL git ls-files must preserve Japanese paths under quotePath=true"
        )
        assert build_audio_population(fixture_root) == ["日本語曲.mp3"], (
            "audio population must preserve Japanese indexed filenames"
        )
        addon_file = fixture_root / "addons/日本語/拡張.gd"
        native_file = fixture_root / "native/日本語.dylib"
        addon_file.parent.mkdir(parents=True)
        native_file.parent.mkdir(parents=True)
        addon_file.write_text("extends Node", encoding="utf-8")
        native_file.write_bytes(b"native")
        subprocess.run(
            ["git", "add", "addons/日本語/拡張.gd", "native/日本語.dylib"],
            cwd=fixture_root, check=True,
        )
        japanese_tracked = git_ls_files(fixture_root)
        assert "addons/日本語/拡張.gd" in japanese_tracked and "native/日本語.dylib" in japanese_tracked
        must_fail(
            "Japanese addon/native dependency under quotePath=true",
            lambda: audit_unreviewed_dependencies(japanese_tracked),
        )
    must_fail(
        "U-01 missing timestamp/mapping",
        lambda: validate_u01_tracks(
            {"Asset-Count": "10", "One-to-One-Mapping-Verified": "true"},
            "fixture", sorted(EXPECTED_AUDIO),
        ),
    )
    valid_u01 = {"Asset-Count": "10", "One-to-One-Mapping-Verified": "true"}
    for number, filename in enumerate(sorted(EXPECTED_AUDIO), start=1):
        valid_u01[f"Track-{number:02d}"] = (
            f"{filename};{file_sha256(ROOT / 'assets/audio' / filename)};"
            f"2026-07-10T12:00:00+09:00;MAP-{number:02d}"
        )
    dotted_mapping_u01 = dict(valid_u01)
    dotted_mapping_u01["Track-01"] = dotted_mapping_u01["Track-01"].rsplit(";", 1)[0] + ";MAP.01"
    must_fail(
        "U-01 dotted mapping ID",
        lambda: validate_u01_tracks(dotted_mapping_u01, "fixture", sorted(EXPECTED_AUDIO)),
    )
    must_fail(
        "U-02 period does not contain U-01",
        lambda: cross_check_u02_covers_u01(
            valid_u01,
            {
                "Plan": "Pro", "Period-Start": "2026-07-01", "Period-End": "2026-08-01",
                "Evidence-As-Of": "2026-07-09", "Reviewed-At": "2026-07-11",
                "Covers-U-01": "true",
            },
            "fixture", sorted(EXPECTED_AUDIO),
        ),
    )
    dated_snapshot = require_file(
        "docs/qa/evidence/licensing/2026-07-12_RIGHTS-01A_AUDIT.md"
    )
    snapshot_mutations = {
        "dated U-01 false complete": dated_snapshot.replace(
            "| U-01 |", "| U-01 |", 1
        ).replace("| pending。個別曲", "| complete。個別曲", 1),
        "dated overall false complete": dated_snapshot.replace(
            "RIGHTS-01A全体は未完了", "RIGHTS-01A全体はcomplete", 1
        ),
        "dated U-07 moved to RIGHTS-01A complete": dated_snapshot.replace(
            "RIGHTS-01A対象外。RIGHTS-01Bでpending", "RIGHTS-01A complete", 1
        ),
        "dated table column shift": dated_snapshot.replace(
            "| U-03 | 一部画像", "| U-03 | extra | 一部画像", 1
        ),
        "dated duplicate row": dated_snapshot.replace(
            "| U-08 | AI素材", "| U-06 | duplicate | x | x | pending。x | x |\n| U-08 | AI素材", 1
        ),
        "dated missing row": "\n".join(
            line for line in dated_snapshot.splitlines() if not line.startswith("| U-05 |")
        ),
        "dated U-01 pending plus Japanese completion claim": dated_snapshot.replace(
            "pending。個別曲の由来と生成日時をrepoから検証不能",
            "pending。個別曲の権利確認は完了",
            1,
        ),
        "dated conclusion retains incomplete plus completion claim": dated_snapshot.replace(
            "RIGHTS-01A全体は未完了である。",
            "RIGHTS-01A全体は未完了である。RIGHTS-01Aは完了した。",
            1,
        ),
    }
    for label, mutated_snapshot in snapshot_mutations.items():
        must_fail(label, lambda snapshot=mutated_snapshot: audit_dated_rights_snapshot(snapshot))
    dated_snapshot_path = (
        ROOT / "docs/qa/evidence/licensing/2026-07-12_RIGHTS-01A_AUDIT.md"
    ).resolve()
    for label in (
        "dated U-01 pending plus Japanese completion claim",
        "dated conclusion retains incomplete plus completion claim",
    ):
        with redirect_stdout(io.StringIO()), redirect_stderr(io.StringIO()):
            result = main({dated_snapshot_path: snapshot_mutations[label]})
        assert result != 0, f"production main path accepted negative fixture: {label}"
    with tempfile.TemporaryDirectory() as temp_dir:
        fixture_root = Path(temp_dir)
        audio_dir = fixture_root / "assets/audio"
        audio_dir.mkdir(parents=True)
        eleven_audio = sorted(EXPECTED_AUDIO | {"追加曲.mp3"})
        for filename in eleven_audio:
            (audio_dir / filename).write_bytes(filename.encode("utf-8"))
        stale_ten = {"Asset-Count": "10", "One-to-One-Mapping-Verified": "true"}
        for number, filename in enumerate(sorted(EXPECTED_AUDIO), start=1):
            stale_ten[f"Track-{number:02d}"] = (
                f"{filename};{file_sha256(audio_dir / filename)};"
                f"2026-07-10T12:00:00+09:00;MAP-{number:02d}"
            )
        must_fail(
            "U-01 indexed eleventh MP3 invalidates old population",
            lambda: validate_u01_tracks(stale_ten, "fixture", eleven_audio, fixture_root),
        )
        valid_eleven = {"Asset-Count": "11", "One-to-One-Mapping-Verified": "true"}
        for number, filename in enumerate(eleven_audio, start=1):
            valid_eleven[f"Track-{number:02d}"] = (
                f"{filename};{file_sha256(audio_dir / filename)};"
                f"2026-07-10T12:00:00+09:00;MAP11-{number:02d}"
            )
        validate_u01_tracks(valid_eleven, "fixture", eleven_audio, fixture_root)
        (audio_dir / eleven_audio[0]).write_bytes(b"changed-audio")
        must_fail(
            "U-01 MP3 bytes replaced after evidence",
            lambda: validate_u01_tracks(valid_eleven, "fixture", eleven_audio, fixture_root),
        )
    print("licensing audit negative fixtures: ok (privacy tree/IDs, U-01 mapping, U-02 dependency/period, U-03/U-08 manifests, U-04, dated snapshot, ledger/docs30 transitions)")


def write_attestation_fixture(path: Path, fields: dict[str, str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        "\n".join(f"{key}: {value}" for key, value in fields.items()) + "\n",
        encoding="utf-8",
    )


def fixture_common_fields(evidence_id: str, evidence_type: str) -> dict[str, str]:
    return {
        "Evidence-ID": evidence_id,
        "Evidence-Type": evidence_type,
        "Original-SHA256": hashlib.sha256(b"private-source-evidence").hexdigest(),
        "Reviewed-At": "2026-07-11",
        "Reviewer": "reviewer_1",
        "Private-Storage-Reference": "EVIDENCE_12345",
        "Redaction-Checked": "true",
        "Finding": FINDING_CODES[evidence_type],
    }


def run_positive_attestation_self_tests() -> None:
    """Exercise real attestation files through parsing and the main close gate."""
    with tempfile.TemporaryDirectory() as temp_dir:
        fixture_root = Path(temp_dir).resolve()
        audio_dir = fixture_root / "assets/audio"
        audio_dir.mkdir(parents=True)
        for filename in EXPECTED_AUDIO:
            (audio_dir / filename).write_bytes(f"audio:{filename}".encode("utf-8"))
        image_relative = "assets/showcase/example.png"
        image_path = fixture_root / image_relative
        image_path.parent.mkdir(parents=True)
        image_path.write_bytes(b"fixture-png-bytes")
        icon_path = fixture_root / "assets/icon.svg"
        icon_path.write_bytes((ROOT / "assets/icon.svg").read_bytes())
        (fixture_root / "project.godot").write_text(
            '[application]\nconfig/icon="res://assets/icon.svg"\n', encoding="utf-8",
        )
        (fixture_root / "LICENSE.md").write_text(
            "Copyright (c) 2026 Fixture Rights Holder\n", encoding="utf-8",
        )
        subprocess.run(["git", "init", "-q"], cwd=fixture_root, check=True)
        subprocess.run(
            ["git", "add", "assets", "project.godot", "LICENSE.md"],
            cwd=fixture_root, check=True,
        )
        audio_population = build_audio_population(fixture_root)
        u03_population = build_u03_population(fixture_root)
        assert set(audio_population) == EXPECTED_AUDIO and u03_population == [image_relative]

        u01 = fixture_common_fields("U-01", "suno-track-provenance") | {
            "Asset-Count": str(len(audio_population)),
            "One-to-One-Mapping-Verified": "true",
        }
        for number, filename in enumerate(audio_population, start=1):
            u01[f"Track-{number:02d}"] = (
                f"{filename};{file_sha256(audio_dir / filename)};"
                f"2026-07-10T12:00:00+09:00;MAP_{number:02d}"
            )
        u02 = fixture_common_fields("U-02", "suno-paid-period") | {
            "Plan": "Pro",
            "Period-Start": "2026-07-01",
            "Period-End": "2026-08-01",
            "Evidence-As-Of": "2026-07-11",
            "Covers-U-01": "true",
        }
        image_digest = file_sha256(image_path)
        u03 = fixture_common_fields("U-03", "ai-image-provenance") | {
            "Inventory-Contract": "docs/31 sections 2.2 and 4",
            "Population-Count": "1",
            "Population-SHA256": manifest_sha256([f"{image_relative};{image_digest}"]),
            "Item-0001": f"{image_relative};{image_digest};ai-generated;PROV_001",
            "Provenance-Count": "1",
            "Provenance-0001": (
                "PROV_001;OpenAI;2026-07-10T10:00:00+09:00;"
                "2026-07-10T10:01:00+09:00;creator_1"
            ),
            "Unresolved-Items": "0",
            "Provenance-Complete": "true",
        }
        u04 = fixture_common_fields("U-04", "icon-rights") | {
            "Product-Decision": "adopted",
            "Baseline-Original-Content-SHA256": KNOWN_ORIGINAL_ICON_SHA256,
            "Product-Content-SHA256": KNOWN_ORIGINAL_ICON_SHA256,
            "Author-Verified": "true",
            "Rights-Holder-Verified": "true",
        }
        u05 = fixture_common_fields("U-05", "license-holder") | {
            "License-Holder-Matches-LICENSE": "true",
        }
        u06 = fixture_common_fields("U-06", "trademark-clearance") | {
            "Territories": "JP",
            "Trademark-Classes": "9, 41",
            "Official-DB": "J_PlatPat",
            "Search-Date": "2026-07-11",
            "Result-Count": "0",
            "Expert-Review": "not-required",
        }
        combined = sorted({f"assets/audio/{name}" for name in audio_population} | set(u03_population))
        u08 = fixture_common_fields("U-08", "ai-input-rights") | {
            "Covered-Media": "suno-and-ai-images",
            "Population-Count": str(len(combined)),
            "Population-SHA256": manifest_sha256(
                [f"{relative};{file_sha256(fixture_root / relative)}" for relative in combined]
            ),
            "Clearance-Complete": "true",
        }
        for number, relative in enumerate(combined, start=1):
            u08[f"Item-{number:04d}"] = (
                f"{relative};{file_sha256(fixture_root / relative)};none;RIGHTS_{number:02d}"
            )

        evidence_root = fixture_root / "docs/qa/evidence/licensing"
        canonical_fields = {
            "U-01": u01, "U-02": u02, "U-03": u03, "U-04": u04,
            "U-05": u05, "U-06": u06, "U-08": u08,
        }
        for evidence_id, fields in canonical_fields.items():
            write_attestation_fixture(
                evidence_root / "attestations" / f"{evidence_id}_positive.md", fields,
            )
        subprocess.run(["git", "add", "docs"], cwd=fixture_root, check=True)

        historical_u02_path = fixture_root / "U-02_historical_positive.md"
        write_attestation_fixture(
            historical_u02_path,
            fixture_common_fields("U-02", "suno-paid-period") | {
                "Plan": "Premier",
                "Period-Start": "2026-06-01",
                "Period-End": "2026-07-11",
                "Evidence-As-Of": "2026-07-11",
                "Covers-U-01": "true",
            },
        )
        validate_u02_period(
            parse_attestation(historical_u02_path, fixture_root), "historical U-02 positive"
        )

        parsed = audit_evidence_tree(evidence_root, fixture_root)
        completed_ids = set(canonical_fields)
        grouped: dict[str, list[dict[str, str]]] = {}
        for fields in parsed.values():
            grouped.setdefault(fields["Evidence-ID"], []).append(fields)
        audit_completion_dependencies(completed_ids)
        audit_canonical_attestation_counts(grouped, completed_ids)
        index_paths = indexed_paths(fixture_root)
        project_config = (fixture_root / "project.godot").read_text(encoding="utf-8")
        for evidence_id in sorted(completed_ids):
            saved_paths = sorted(
                path.relative_to(fixture_root).as_posix()
                for path, fields in parsed.items()
                if fields["Evidence-ID"] == evidence_id
            )
            audit_completed_attestation_references(
                evidence_id, saved_paths, parsed, fixture_root,
            )
            for relative in saved_paths:
                saved_path = (fixture_root / relative).resolve()
                require_worktree_matches_index(
                    fixture_root, relative, index_paths, f"positive {evidence_id} attestation",
                )
                validate_completed_attestation_payload(
                    evidence_id, parsed[saved_path], relative, saved_paths, parsed,
                    "", project_config, fixture_root, index_paths, saved_path,
                    audio_population, u03_population,
                )
        cross_check_u02_covers_u01(
            grouped["U-01"][0], grouped["U-02"][0],
            "positive completed U-01/U-02", audio_population, fixture_root,
        )

    with tempfile.TemporaryDirectory() as temp_dir:
        fixture_root = Path(temp_dir).resolve()
        original_icon = fixture_root / "assets/icon.svg"
        original_icon.parent.mkdir(parents=True)
        original_icon.write_bytes((ROOT / "assets/icon.svg").read_bytes())
        replacement_relative = "assets/product_icon.svg"
        replacement = fixture_root / replacement_relative
        replacement.write_text("<svg>replacement icon</svg>", encoding="utf-8")
        replacement_digest = file_sha256(replacement)
        project_config = f'config/icon="res://{replacement_relative}"\n'
        (fixture_root / "project.godot").write_text(project_config, encoding="utf-8")
        decision_relative = "docs/qa/evidence/licensing/attestations/U-04_rejected.md"
        rights_relative = "docs/qa/evidence/licensing/attestations/U-04_replacement_rights.md"
        decision = fixture_common_fields("U-04", "icon-rights") | {
            "Product-Decision": "rejected",
            "Baseline-Original-Content-SHA256": KNOWN_ORIGINAL_ICON_SHA256,
            "Replacement-Integrated": "true",
            "Replacement-Product-Path": replacement_relative,
            "Replacement-Content-SHA256": replacement_digest,
            "Replacement-Rights-Attestation": rights_relative,
        }
        rights = fixture_common_fields("U-04", "icon-replacement-rights") | {
            "Replacement-Asset-Path": replacement_relative,
            "Replacement-Content-SHA256": replacement_digest,
            "Replacement-Asset-Rights-Verified": "true",
        }
        write_attestation_fixture(fixture_root / decision_relative, decision)
        write_attestation_fixture(fixture_root / rights_relative, rights)
        subprocess.run(["git", "init", "-q"], cwd=fixture_root, check=True)
        subprocess.run(["git", "add", "."], cwd=fixture_root, check=True)
        evidence_root = fixture_root / "docs/qa/evidence/licensing"
        parsed = audit_evidence_tree(evidence_root, fixture_root)
        saved_paths = [decision_relative, rights_relative]
        audit_completed_attestation_references("U-04", saved_paths, parsed, fixture_root)
        audit_canonical_attestation_counts(
            {"U-04": list(parsed.values())}, {"U-04"},
        )
        index_paths = indexed_paths(fixture_root)
        ledger = f"{replacement_relative}\n[RIGHTS-01A:U-04-REPLACEMENT]=integrated"
        for relative in saved_paths:
            saved_path = (fixture_root / relative).resolve()
            require_worktree_matches_index(
                fixture_root, relative, index_paths, "positive U-04 rejected attestation",
            )
            validate_completed_attestation_payload(
                "U-04", parsed[saved_path], relative, saved_paths, parsed,
                ledger, project_config, fixture_root, index_paths, saved_path, [], [],
            )
    print("licensing audit positive fixtures: ok (U-01/U-02/U-03/U-04 adopted+rejected/U-05/U-06/U-08)")


def main(management_text_overrides: dict[Path, str] | None = None) -> int:
    try:
        normalized_overrides = {
            path.resolve(): text for path, text in (management_text_overrides or {}).items()
        }
        allowed_override_paths = {
            (ROOT / "docs/qa/evidence/licensing/README.md").resolve(),
            (ROOT / "docs/qa/evidence/licensing/OWNER_EVIDENCE_REQUEST.md").resolve(),
            (ROOT / "docs/qa/evidence/licensing/2026-07-12_RIGHTS-01A_AUDIT.md").resolve(),
        }
        assert normalized_overrides.keys() <= allowed_override_paths, (
            "main fixture overrides are limited to licensing management Markdown"
        )
        license_text = require_file("LICENSE.md")
        notices = require_file("THIRD_PARTY_NOTICES.md")
        ledger = require_file("docs/31_asset_ledger.md")
        evidence = require_file("docs/qa/evidence/licensing/README.md")
        owner_request = require_file("docs/qa/evidence/licensing/OWNER_EVIDENCE_REQUEST.md")
        dated_audit = require_file(
            "docs/qa/evidence/licensing/2026-07-12_RIGHTS-01A_AUDIT.md"
        )
        evidence = normalized_overrides.get(
            (ROOT / "docs/qa/evidence/licensing/README.md").resolve(), evidence,
        )
        owner_request = normalized_overrides.get(
            (ROOT / "docs/qa/evidence/licensing/OWNER_EVIDENCE_REQUEST.md").resolve(),
            owner_request,
        )
        dated_audit = normalized_overrides.get(
            (ROOT / "docs/qa/evidence/licensing/2026-07-12_RIGHTS-01A_AUDIT.md").resolve(),
            dated_audit,
        )
        project_config = require_file("project.godot")
        project_overview = require_file("docs/00_プロジェクト概要.md")
        v2_overview = require_file("docs/30_v2_expansion_overview.md")
        line_seed_ofl = require_file("assets/fonts/line_seed/OFL.txt")
        mplus_ofl = require_file("assets/fonts/OFL-MPLUS1p.txt")
        git_index_paths = indexed_paths(ROOT)

        # The evidence tree scans README/OWNER plus every attestation; docs/31 is the
        # remaining public RIGHTS-01A narrative and must pass the same privacy gate.
        scan_public_text(ledger, ROOT / "docs/31_asset_ledger.md", allow_official_urls=True)
        for contract_text, contract_label in (
            (owner_request, "OWNER_EVIDENCE_REQUEST.md"),
            (ledger, "docs/31_asset_ledger.md"),
        ):
            assert KNOWN_ORIGINAL_ICON_SHA256 in contract_text, (
                f"U-04 known original icon digest missing from {contract_label}"
            )
        original_icon = ROOT / "assets/icon.svg"
        if original_icon.exists():
            assert file_sha256(original_icon) == KNOWN_ORIGINAL_ICON_SHA256, (
                "assets/icon.svg no longer matches the persisted U-04 original digest"
            )
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
        parsed_attestations = audit_evidence_tree(
            evidence_root, management_text_overrides=normalized_overrides,
        )
        all_attestation_fields: dict[str, list[dict[str, str]]] = {}
        for parsed_fields in parsed_attestations.values():
            all_attestation_fields.setdefault(parsed_fields["Evidence-ID"], []).append(parsed_fields)
        u03_population = build_u03_population(ROOT)
        audio_population = build_audio_population(ROOT)
        non_evidence_management_files = {
            (evidence_root / "README.md").resolve(),
            (evidence_root / "OWNER_EVIDENCE_REQUEST.md").resolve(),
            (evidence_root / "2026-07-12_RIGHTS-01A_AUDIT.md").resolve(),
        }
        completed_fields: dict[str, list[dict[str, str]]] = {}
        for evidence_id, close_date, saved_evidence in completed_rows:
            parsed_close_date = require_calendar_date(close_date, f"close date for {evidence_id}")
            assert parsed_close_date <= release_today(), f"future close date for {evidence_id}: {parsed_close_date}"
            saved_paths = re.findall(r"`([^`]+)`", saved_evidence)
            assert saved_paths, f"completed {evidence_id} requires a backticked saved evidence path"
            assert len(saved_paths) == len(set(saved_paths)), (
                f"completed {evidence_id} repeats the same attestation path"
            )
            audit_completed_attestation_references(
                evidence_id, saved_paths, parsed_attestations, ROOT,
            )
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
                require_worktree_matches_index(
                    ROOT, relative, git_index_paths, f"completed {evidence_id} attestation"
                )
                assert saved_path.suffix == ".md" and saved_path.name.startswith(f"{evidence_id}_"), (
                    f"completed {evidence_id} attestation must be U-XX_*.md: {relative}"
                )
                assert saved_path in parsed_attestations, f"unvalidated attestation referenced: {relative}"
                fields = parsed_attestations[saved_path]
                assert fields["Evidence-ID"] == evidence_id, (
                    f"attestation ID mismatch for {evidence_id}: {relative}"
                )
                reviewed_at = require_calendar_date(fields["Reviewed-At"], f"Reviewed-At for {evidence_id}")
                assert reviewed_at <= parsed_close_date, (
                    f"review date after close date for {evidence_id}: {reviewed_at} > {parsed_close_date}"
                )
                validate_completed_attestation_payload(
                    evidence_id, fields, relative, saved_paths, parsed_attestations,
                    ledger, project_config, ROOT, git_index_paths, saved_path,
                    audio_population, u03_population,
                )
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
        if completed_evidence_ids:
            for state_relative in (
                "docs/30_v2_expansion_overview.md",
                "docs/31_asset_ledger.md",
                "docs/qa/evidence/licensing/README.md",
                "docs/qa/evidence/licensing/OWNER_EVIDENCE_REQUEST.md",
            ):
                require_worktree_matches_index(
                    ROOT, state_relative, git_index_paths, "completed RIGHTS-01A state document"
                )
        audit_rights_state(set(evidence_ids), set(completed_evidence_ids), v2_overview)
        audit_completion_dependencies(set(completed_evidence_ids))
        audit_canonical_attestation_counts(all_attestation_fields, set(completed_evidence_ids))
        if "U-02" in completed_evidence_ids:
            cross_check_u02_covers_u01(
                completed_fields["U-01"][0], completed_fields["U-02"][0],
                "completed U-01/U-02", audio_population,
            )

        for evidence_id in sorted(rights_01a_ids):
            expected_state = "pending" if evidence_id in evidence_ids else "complete"
            expected_marker = f"[RIGHTS-01A:{evidence_id}]={expected_state}"
            opposite_state = "complete" if expected_state == "pending" else "pending"
            opposite_marker = f"[RIGHTS-01A:{evidence_id}]={opposite_state}"
            assert expected_marker in ledger, f"asset ledger missing state marker: {expected_marker}"
            assert opposite_marker not in ledger, f"asset ledger has stale state marker: {opposite_marker}"
            audit_ledger_evidence_state(evidence_id, evidence_id in evidence_ids, ledger)

        audit_ledger_section_states(set(evidence_ids), ledger, require_source_scope=True)

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
        assert "2026-07-12_RIGHTS-01A_AUDIT.md" in evidence, (
            "licensing evidence index missing dated RIGHTS-01A audit link"
        )
        for marker in (
            "| ID | 現在の主張 | 必要証拠 | 現存証拠 | 判定 | 残作業 |",
            "## 外部入力の最短チェックリスト",
            "リポジトリ側で可能な棚卸し、証拠受入形式、機密情報境界、状態判定は準備完了",
        ):
            assert marker in dated_audit, f"dated RIGHTS-01A audit missing marker: {marker}"
        audit_dated_rights_snapshot(dated_audit)
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
            "generate_quest_board_assets.py",
            "generate_shark_pen_assets.py",
            "generate_shark_fish_assets.py",
            "generate_tackle_shop_assets.py",
            "generate_title_showcase_assets.py",
            "generate_underwater_ui_frame_assets.py",
            "process_fishing_time_slot_assets.py",
            # M2 authored market art is a product source-consuming pipeline.
            "process_fish_market_m2_assets.py",
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
            # QA-only before/after/reference boards never ship product pixels.
            "build_fish_market_m2_evidence.py",
            # M3 QA-only triptychs and interaction contact sheets read the
            # adopted reference solely for docs/qa evidence, never products.
            "build_market_m3_evidence.py",
            "build_fishing_spot_thumb_contact_sheet.py",
            "build_shark_pen_reference.py",
            "build_screen_visual_comparison.py",
            # Pixel-preserving save reads existing products only; M2 sources
            # are existence guards and are never opened by this generator.
            "generate_fish_market_assets.py",
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

        audit_unreviewed_dependencies(git_ls_files(ROOT))
    except AssertionError as exc:
        print(f"licensing audit: FAIL: {exc}", file=sys.stderr)
        return 1

    print("licensing audit: ok (document consistency; release blockers remain explicitly listed)")
    return 0


if __name__ == "__main__":
    if sys.argv[1:] == ["--self-test"]:
        run_negative_self_tests()
        run_positive_attestation_self_tests()
        raise SystemExit(0)
    assert not sys.argv[1:], f"unknown arguments: {sys.argv[1:]}"
    raise SystemExit(main())
