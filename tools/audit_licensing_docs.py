#!/usr/bin/env python3
"""Read-only consistency checks for the repository's licensing documents."""

from pathlib import Path
import re
import subprocess
import sys


ROOT = Path(__file__).resolve().parents[1]


def require_file(relative: str) -> str:
    path = ROOT / relative
    if not path.is_file():
        raise AssertionError(f"missing required file: {relative}")
    return path.read_text(encoding="utf-8")


def main() -> int:
    try:
        license_text = require_file("LICENSE.md")
        notices = require_file("THIRD_PARTY_NOTICES.md")
        ledger = require_file("docs/31_asset_ledger.md")
        evidence = require_file("docs/qa/evidence/licensing/README.md")
        owner_request = require_file("docs/qa/evidence/licensing/OWNER_EVIDENCE_REQUEST.md")
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
        non_evidence_management_files = {
            (evidence_root / "README.md").resolve(),
            (evidence_root / "OWNER_EVIDENCE_REQUEST.md").resolve(),
        }
        for evidence_id, close_date, saved_evidence in completed_rows:
            assert re.fullmatch(r"\d{4}-\d{2}-\d{2}", close_date.strip()), (
                f"invalid close date for {evidence_id}: {close_date.strip()}"
            )
            saved_paths = re.findall(r"`([^`]+)`", saved_evidence)
            assert saved_paths, f"completed {evidence_id} requires a backticked saved evidence path"
            for relative in saved_paths:
                saved_path = (ROOT / relative).resolve()
                assert saved_path == evidence_root or evidence_root in saved_path.parents, (
                    f"completed {evidence_id} evidence must be under licensing evidence root: {relative}"
                )
                assert saved_path not in non_evidence_management_files, (
                    f"completed {evidence_id} cannot cite a management file as evidence: {relative}"
                )
                assert saved_path.is_file(), f"completed {evidence_id} evidence file missing: {relative}"
        unresolved_holder = "RIGHTS HOLDER NAME" in license_text
        rights_01a_ids = {"U-01", "U-02", "U-03", "U-04", "U-05", "U-06", "U-08"}
        classified_ids = set(evidence_ids) | set(completed_evidence_ids)
        assert classified_ids == rights_01a_ids, (
            f"RIGHTS-01A evidence classification mismatch: "
            f"missing={sorted(rights_01a_ids - classified_ids)}, "
            f"unexpected={sorted(classified_ids - rights_01a_ids)}"
        )

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
            "加入期間証拠待ち",
            "Pre-Generated AI",
            "source-consuming pipeline",
            "source/reference-consuming",
            "U-03/U-08",
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
            "U-03/U-08待ち",
        ):
            assert marker in current_bg_row, f"current underwater background relation missing: {marker}"

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
    raise SystemExit(main())
