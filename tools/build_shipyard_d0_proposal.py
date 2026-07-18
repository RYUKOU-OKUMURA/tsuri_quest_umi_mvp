#!/usr/bin/env python3
"""SHIPYARD-D0の未採用全画面モック候補を決定的に生成する。"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image as PILImage, ImageDraw, ImageFont, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
VIEWPORT = (1280, 720)
DEFAULT_INPUT = Path("/tmp/tsuri_shipyard_available.png")
DEFAULT_OUTPUT = ROOT.joinpath("reference", "shipyard_d0_proposal_unapproved.png")
NAVY = (7, 25, 43, 238)
NAVY_SOFT = (8, 31, 49, 214)
GOLD = (239, 190, 77, 255)
PAPER = (246, 229, 192, 255)
INK = (53, 39, 25, 255)
CYAN = (104, 229, 245, 255)


def load_font(size: int, bold: bool = True) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    name = "LINESeedJP_A_TTF_Bd.ttf" if bold else "LINESeedJP_A_TTF_Rg.ttf"
    path = ROOT / "assets" / "fonts" / "line_seed" / name
    try:
        return ImageFont.truetype(str(path), size)
    except OSError:
        return ImageFont.load_default()


def center_text(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], text: str, font, fill) -> None:
    left, top, right, bottom = box
    bounds = draw.textbbox((0, 0), text, font=font)
    x = left + (right - left - (bounds[2] - bounds[0])) // 2
    y = top + (bottom - top - (bounds[3] - bounds[1])) // 2 - bounds[1]
    draw.text((x, y), text, font=font, fill=fill)


def panel(
    draw: ImageDraw.ImageDraw,
    box: tuple[int, int, int, int],
    fill,
    outline=GOLD,
    radius: int = 16,
    width: int = 2,
) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def paste_crop(canvas: PILImage.Image, source: PILImage.Image, source_box, target_box) -> None:
    crop = source.crop(source_box).resize(
        (target_box[2] - target_box[0], target_box[3] - target_box[1]),
        PILImage.Resampling.LANCZOS,
    )
    canvas.alpha_composite(crop, target_box[:2])


def build(input_path: Path, output_path: Path) -> None:
    with PILImage.open(input_path) as source_image:
        source = source_image.convert("RGBA")
    if source.size != VIEWPORT:
        raise ValueError(f"SHIPYARD-D0 source must be 1280x720: {input_path} -> {source.size}")

    canvas = source.copy()
    # 現行の背景・上部ステータス・右下帰港導線は方向性比較の基準として残し、
    # 中段だけを「船舶司令盤」へ再配分する一案にする。
    scrim = PILImage.new("RGBA", VIEWPORT, (4, 16, 28, 0))
    scrim_draw = ImageDraw.Draw(scrim)
    scrim_draw.rectangle((8, 72, 1272, 642), fill=(4, 16, 28, 48))
    scrim = scrim.filter(ImageFilter.GaussianBlur(0.4))
    canvas.alpha_composite(scrim)
    draw = ImageDraw.Draw(canvas)

    # 左: 3船の選択列。実入力矩形は製品側で不動のまま、視覚上だけ台帳化する。
    panel(draw, (12, 78, 328, 642), NAVY, (226, 177, 68, 255), 18, 3)
    center_text(draw, (28, 88, 312, 126), "船舶台帳", load_font(22), PAPER)
    draw.line((28, 130, 312, 130), fill=(105, 194, 215, 190), width=2)
    card_sources = ((14, 84, 316, 248), (14, 270, 316, 434), (14, 450, 316, 628))
    card_targets = ((28, 142, 312, 282), (28, 294, 312, 434), (28, 446, 312, 586))
    for source_box, target_box in zip(card_sources, card_targets):
        card = source.crop(source_box).resize(
            (target_box[2] - target_box[0], target_box[3] - target_box[1]),
            PILImage.Resampling.LANCZOS,
        )
        card = card.convert("RGBA")
        mask = PILImage.new("L", card.size, 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, card.width - 1, card.height - 1), radius=10, fill=255)
        card.putalpha(mask)
        canvas.alpha_composite(card, target_box[:2])
    center_text(draw, (28, 600, 312, 632), "選択中の船が中央に表示されます", load_font(12, False), (190, 230, 235, 255))

    # 中央: 主役を購入判断に絞った dossier。背景の船は見せ、情報のwellを一本化する。
    panel(draw, (344, 78, 912, 642), NAVY_SOFT, (236, 189, 78, 255), 22, 3)
    center_text(draw, (368, 92, 888, 136), "船舶司令盤", load_font(30), PAPER)
    center_text(draw, (368, 138, 888, 168), "選択中の船を購入して航路を拡張", load_font(14, False), (185, 229, 236, 255))
    draw.line((380, 180, 876, 180), fill=(129, 220, 231, 210), width=2)
    # 現行スクリーンの中央船カットを、候補の主対象として再利用する。
    central_crop = source.crop((338, 172, 914, 472)).convert("RGBA")
    central_crop = central_crop.filter(ImageFilter.GaussianBlur(0.1))
    central_crop = central_crop.resize((496, 258), PILImage.Resampling.LANCZOS)
    canvas.alpha_composite(central_crop, (380, 194))
    panel(draw, (380, 466, 876, 526), (5, 33, 55, 245), (114, 221, 237, 230), 10, 2)
    center_text(draw, (398, 469, 618, 523), "小型船・浜風", load_font(23), PAPER)
    center_text(draw, (628, 469, 858, 523), "南の岩礁まで", load_font(17, False), (210, 238, 235, 255))
    panel(draw, (380, 542, 524, 604), (37, 38, 40, 245), GOLD, 10, 2)
    center_text(draw, (390, 545, 514, 601), "3,600 G", load_font(22), PAPER)
    panel(draw, (548, 542, 876, 604), (217, 147, 34, 250), (255, 224, 138, 255), 10, 2)
    center_text(draw, (564, 545, 860, 601), "購入", load_font(24), (255, 247, 218, 255))

    # 右: ルート情報は地図と現在/購入後の比較を1枚へ収める。
    panel(draw, (926, 78, 1268, 642), NAVY, (226, 177, 68, 255), 18, 3)
    center_text(draw, (944, 90, 1250, 128), "航路図  小型船", load_font(22), PAPER)
    route_crop = source.crop((918, 84, 1266, 628)).convert("RGBA")
    route_crop = route_crop.resize((306, 476), PILImage.Resampling.LANCZOS)
    canvas.alpha_composite(route_crop, (944, 142))
    panel(draw, (944, 566, 1248, 618), (5, 33, 55, 245), (105, 222, 237, 230), 8, 2)
    center_text(draw, (958, 568, 1098, 616), "現在 0/3", load_font(16), (212, 241, 241, 255))
    center_text(draw, (1102, 568, 1236, 616), "購入後 1/3", load_font(16), (255, 232, 170, 255))

    # 下部の説明は既存の可変値/帰港矩形を壊さないため、現行のフッターを保持する。
    footer = source.crop((270, 640, 1020, 720)).convert("RGBA")
    footer = footer.resize((750, 80), PILImage.Resampling.LANCZOS)
    canvas.alpha_composite(footer, (270, 640))
    return_button = source.crop((1024, 640, 1280, 720)).convert("RGBA")
    return_button = return_button.resize((256, 80), PILImage.Resampling.LANCZOS)
    canvas.alpha_composite(return_button, (1024, 640))

    output_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(output_path, optimize=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, default=DEFAULT_INPUT)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    args = parser.parse_args()
    build(args.input, args.output)
    print(args.output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
