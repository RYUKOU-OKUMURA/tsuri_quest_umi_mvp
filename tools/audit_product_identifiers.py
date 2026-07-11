#!/usr/bin/env python3
"""ID-01の製品識別子・移行境界が正本と設定で一致するか検証する。"""

from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[1]
USER_DATA_NAMESPACE = "tsuri_quest_umi"
MACOS_BUNDLE_ID = "net.physical-balance-lab.tsuri-quest-umi"
ITCH_PAGE_SLUG = "tsuri-quest-umi"
LEGACY_PROJECT_NAME = "釣りクエスト ～海釣り編～ MVP"


def require_file(relative: str) -> str:
    path = ROOT / relative
    if not path.is_file():
        raise AssertionError(f"missing required file: {relative}")
    return path.read_text(encoding="utf-8")


def main() -> int:
    try:
        project = require_file("project.godot")
        overview = require_file("docs/00_プロジェクト概要.md")
        requirements = require_file("docs/01_要件定義書.md")
        technical_design = require_file("docs/04_技術設計.md")
        v2 = require_file("docs/30_v2_expansion_overview.md")
        e11 = require_file("docs/v2/E11_launch_readiness.md")
        ledger = require_file("docs/31_asset_ledger.md")
        evidence = require_file("docs/qa/evidence/licensing/README.md")

        for marker in (
            "config/use_custom_user_dir=true",
            f'config/custom_user_dir_name="{USER_DATA_NAMESPACE}"',
        ):
            assert marker in project, f"project identifier setting missing: {marker}"

        authoritative_docs = {
            "docs/00": overview,
            "docs/30": v2,
            "E11": e11,
        }
        for label, content in authoritative_docs.items():
            for marker in (
                USER_DATA_NAMESPACE,
                MACOS_BUNDLE_ID,
                ITCH_PAGE_SLUG,
                "未発行",
                LEGACY_PROJECT_NAME,
            ):
                assert marker in content, f"{label} missing ID-01 marker: {marker}"

        for marker in (MACOS_BUNDLE_ID, ITCH_PAGE_SLUG, "未発行"):
            assert marker in ledger, f"asset ledger missing ID-01 marker: {marker}"
            assert marker in evidence, f"licensing evidence missing ID-01 marker: {marker}"

        for label, content in (("requirements", requirements), ("technical design", technical_design)):
            for marker in (USER_DATA_NAMESPACE, "user://slots/<1..3>/tsuri_quest_save.json"):
                assert marker in content, f"{label} missing current save path contract: {marker}"

        for marker in (
            "ID-01（製品識別子） | 完了",
            "新側にsave artifactが1件でもあれば全件をskip",
            "既存ファイルは上書きしない",
            "旧namespace原本はrename / removeせず",
            "部分コピーを空slotとして扱わない",
            "future / 不明versionはbyte copy後にSAVE-01 guardへ渡す",
            "最小export spike",
        ):
            assert marker in v2, f"ID-01 contract missing from docs/30: {marker}"

        assert "後続ID-01では" not in v2, "docs/30 still treats completed ID-01 as future work"
        assert "後続ID-01では" not in e11, "E11 still treats completed ID-01 as future work"

        export_presets = ROOT / "export_presets.cfg"
        if export_presets.is_file():
            preset_text = export_presets.read_text(encoding="utf-8")
            assert f'application/bundle_identifier="{MACOS_BUNDLE_ID}"' in preset_text, (
                "macOS export preset does not use the approved bundle ID"
            )
        else:
            assert "最小export spike" in v2 and "未完" in e11, (
                "missing export preset must remain explicit follow-up work"
            )
    except AssertionError as exc:
        print(f"product identifier audit: FAIL: {exc}", file=sys.stderr)
        return 1

    print("product identifier audit passed: ID-01 values and migration contract are synchronized")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
