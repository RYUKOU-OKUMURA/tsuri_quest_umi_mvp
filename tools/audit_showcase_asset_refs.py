#!/usr/bin/env python3
"""Audit showcase asset ownership from src/ui GDScript files.

画面別素材は自画面フォルダからだけ参照し、共有部品は common、
魚ドメイン素材は FightFishAssets 経由に寄せる。
例外を増やす場合は、このファイル内に理由コメント付きで明示する。
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
UI_ROOT = ROOT / "src" / "ui"

ASSET_RE = re.compile(r"res://assets/showcase/([^/\"']+)(?:/[^\"']*)?")

# 魚ドメイン素材のパス組み立てを一箇所へ閉じ込めるため、
# direct fish refs はこのヘルパだけ許可する。
FISH_OWNER = Path("src/ui/fight_fish_assets.gd")

# 画面/コンポーネントごとの素材所有。common は全UIで許可する。
EXPLICIT_OWNERS: dict[Path, set[str]] = {
    Path("src/ui/screen_base.gd"): {"common"},
    Path("src/ui/components/player_status_bar.gd"): {"common"},
    Path("src/ui/fight_fish_assets.gd"): {"fish"},
    Path("src/ui/title_screen.gd"): {"title", "common"},
    Path("src/ui/components/title_backdrop.gd"): {"title"},
    Path("src/ui/harbor_screen.gd"): {"harbor", "common"},
    Path("src/ui/components/harbor_backdrop.gd"): {"harbor"},
    # R6: 調理フロー4ファイル共通の素材パス・スタイル定義を集約する所有モジュール
    Path("src/ui/components/cooking_assets.gd"): {"cooking"},
    Path("src/ui/cooking_screen.gd"): {"cooking", "common"},
    Path("src/ui/components/cooking_status_panel.gd"): {"cooking"},
    Path("src/ui/components/cooking_reward_panel.gd"): {"cooking"},
    # cooking_reward_panel から抽出した描画専用 Visual クラス集（所有素材は同じ cooking）
    Path("src/ui/components/cooking_reward_visuals.gd"): {"cooking"},
    Path("src/ui/components/level_up_panel.gd"): {"cooking"},
    Path("src/ui/fish_book_screen.gd"): {"fish_book", "common"},
    # R5-Aの人物portraitはstatus画面だけが所有するauthored一点物。
    Path("src/ui/status_screen.gd"): {"status", "common"},
    Path("src/ui/market_screen.gd"): {"fish_market", "common"},
    Path("src/ui/shop_screen.gd"): {"tackle_shop", "common"},
    # 依頼ボードは画面専用の木面/紙札と既存common操作部品だけを所有する。
    Path("src/ui/quest_board_screen.gd"): {"quest_board", "common"},
    # サメ生簀のauthored水槽背景は画面専用素材として所有する。
    Path("src/ui/shark_pen_screen.gd"): {"shark_pen", "common"},
    Path("src/ui/fishing_spot_select_screen.gd"): {"fishing_spots", "common"},
    Path("src/ui/components/fishing_spot_map_view.gd"): {"fishing_spots"},
    Path("src/ui/components/catch_fanfare.gd"): {"underwater"},
    Path("src/ui/components/surface_cast_view.gd"): {"surface"},
    # docs/40 READY専用下段バーは、FIGHT用underwater枠ではなく共通キットの
    # カード/ボタンフレームで構成するため common を明示許可する。
    Path("src/ui/components/fight_hud.gd"): {"underwater", "common"},
    Path("src/ui/components/fight_status_bar.gd"): {"underwater"},
    Path("src/ui/components/fight_sidebar.gd"): {"underwater"},
    Path("src/ui/components/underwater_view.gd"): {"underwater"},
    Path("src/ui/shipyard_screen.gd"): {"shipyard"},
}


def rel(path: Path) -> Path:
    return path.relative_to(ROOT)


def allowed_roots(path: Path) -> set[str]:
    rel_path = rel(path)
    if rel_path in EXPLICIT_OWNERS:
        return set(EXPLICIT_OWNERS[rel_path])
    return {"common"}


def audit_file(path: Path) -> list[str]:
    failures: list[str] = []
    text = path.read_text(encoding="utf-8")
    rel_path = rel(path)
    allowed = allowed_roots(path)
    for line_no, line in enumerate(text.splitlines(), start=1):
        for match in ASSET_RE.finditer(line):
            root = match.group(1)
            asset_path = match.group(0)
            if root == "fish" and rel_path != FISH_OWNER:
                failures.append(
                    f"{rel_path}:{line_no}: fish素材はFightFishAssets経由にしてください: {asset_path}"
                )
                continue
            if root == "underwater" and "/fish/" in asset_path:
                failures.append(
                    f"{rel_path}:{line_no}: 旧underwater/fish参照が残っています: {asset_path}"
                )
                continue
            if root not in allowed:
                failures.append(
                    f"{rel_path}:{line_no}: 許可外のshowcase素材参照です "
                    f"(allowed={sorted(allowed)}): {asset_path}"
                )
    return failures


def main() -> int:
    failures: list[str] = []
    for path in sorted(UI_ROOT.rglob("*.gd")):
        failures.extend(audit_file(path))
    if failures:
        print("showcase asset reference audit failed:")
        for failure in failures:
            print(f"  - {failure}")
        return 1
    print("showcase asset reference audit passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
