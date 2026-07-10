#!/usr/bin/env python3
"""Process AI sources for the harbor info board (frame + fish card) into showcase PNGs.

Pipeline (docs/43_harbor_info_board_plan.md「Phase B」/ docs/19 §3.4 と同じ流儀。
tools/process_harbor_plan_assets.py の踏襲):
  tools/source_assets/harbor/harbor_info_board_frame_source.png
  tools/source_assets/harbor/harbor_info_fish_card_source.png
    → chroma key（マゼンタ #FF00FF）/ trim
    → 現行PIL素材と同一ピクセル寸法へ cover-fit リサイズ
    → assets/showcase/harbor/harbor_info_board_frame.png / harbor_info_fish_card.png

現行素材はどちらも TextureRect.STRETCH_SCALE（アスペクト非保持のフルレクト伸縮）で
表示される（src/ui/harbor_screen.gd の `_texture_rect()` 参照）。タイトル・魚名・
理由バッジは runtime Label が上に重なるだけで、素材側に透過の「くり抜き」領域は
不要（現行 tools/generate_harbor_info_board_assets.py の PIL 版も不透明な板のまま）。
そのため本スクリプトはヘッダー帯のクリーンアップ等は行わず、キー抜き→トリム→
cover-fit リサイズのみを行う。

ソースが無い場合は、生成指示書（docs/43 §1.5）に従って置くべきファイルパスを
案内して終了する（exit 1）。
"""

from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image, ImageEnhance

ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "tools" / "source_assets" / "harbor"
HARBOR_OUT = ROOT / "assets" / "showcase" / "harbor"

FRAME_SOURCE = SOURCE_DIR / "harbor_info_board_frame_source.png"
CARD_SOURCE = SOURCE_DIR / "harbor_info_fish_card_source.png"

FRAME_OUT = HARBOR_OUT / "harbor_info_board_frame.png"
CARD_OUT = HARBOR_OUT / "harbor_info_fish_card.png"

# 現行 tools/generate_harbor_info_board_assets.py の出力と同一ピクセル寸法
# （src/ui/harbor_screen.gd は STRETCH_SCALE でこのアスペクト比のまま伸縮するため、
#  ここを変えると港画面の縦横比が崩れる）。
FRAME_SIZE = (1280, 320)  # 4:1
CARD_SIZE = (240, 280)  # 6:7

sys.path.insert(0, str(Path(__file__).resolve().parent))
from process_harbor_plan_assets import _remove_chroma_magenta, _trim_alpha  # noqa: E402


def _missing_source_message() -> str:
    return (
        "harbor情報板の一点物ソースが見つかりません。\n"
        "以下のファイルを配置してから再実行してください（docs/43_harbor_info_board_plan.md「Phase B」§生成指示 参照）:\n"
        f"  - {FRAME_SOURCE.relative_to(ROOT)}\n"
        f"  - {CARD_SOURCE.relative_to(ROOT)}\n"
        "\n"
        "生成手順:\n"
        "  1. Cursor の GenerateImage（OpenAI）で docs/43 記載のプロンプトを使い、\n"
        "     マゼンタ #FF00FF 背景・文字/ロゴなしの2素材を生成する\n"
        "  2. 生成画像を上記パスへそのまま保存する（リサイズ不要。本スクリプトが\n"
        f"     {FRAME_SIZE[0]}x{FRAME_SIZE[1]} / {CARD_SIZE[0]}x{CARD_SIZE[1]} へ cover-fit する）\n"
        "  3. 本スクリプトを再実行する: python3 tools/process_harbor_info_board_assets.py\n"
    )


def _quantize_toward_palette(image: Image.Image) -> Image.Image:
    """process_harbor_plan_assets の流儀に合わせた、控えめな色寄せ。"""
    alpha = image.getchannel("A")
    rgb = image.convert("RGB")
    rgb = ImageEnhance.Color(rgb).enhance(0.92)
    rgb = ImageEnhance.Contrast(rgb).enhance(1.04)
    out = rgb.convert("RGBA")
    out.putalpha(alpha)
    return out


def _cover_fit(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    """アスペクト比を保ったまま拡大し、中央を目標サイズへクロップ（隙間を作らない）。"""
    scale = max(size[0] / image.width, size[1] / image.height)
    resized = image.resize(
        (max(1, round(image.width * scale)), max(1, round(image.height * scale))),
        Image.Resampling.LANCZOS,
    )
    ox = (resized.width - size[0]) // 2
    oy = (resized.height - size[1]) // 2
    return resized.crop((ox, oy, ox + size[0], oy + size[1]))


def _process_one(source: Path, out_path: Path, size: tuple[int, int]) -> Path:
    raw = _remove_chroma_magenta(Image.open(source))
    trimmed = _trim_alpha(raw, pad=2)
    fitted = _cover_fit(trimmed, size)
    finished = _quantize_toward_palette(fitted)
    finished = ImageEnhance.Sharpness(finished).enhance(1.05)
    HARBOR_OUT.mkdir(parents=True, exist_ok=True)
    finished.save(out_path)
    return out_path


def build_info_board_frame() -> Path:
    if not FRAME_SOURCE.exists():
        raise SystemExit(_missing_source_message())
    return _process_one(FRAME_SOURCE, FRAME_OUT, FRAME_SIZE)


def build_info_fish_card() -> Path:
    if not CARD_SOURCE.exists():
        raise SystemExit(_missing_source_message())
    return _process_one(CARD_SOURCE, CARD_OUT, CARD_SIZE)


def build_all() -> list[Path]:
    if not FRAME_SOURCE.exists() or not CARD_SOURCE.exists():
        raise SystemExit(_missing_source_message())
    return [build_info_board_frame(), build_info_fish_card()]


def main() -> int:
    for path in build_all():
        print(path.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
