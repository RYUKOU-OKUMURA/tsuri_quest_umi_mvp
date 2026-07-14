#!/usr/bin/env python3
"""依頼ボードの authored source を runtime 用PNGへ整形する。"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageEnhance, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "tools" / "source_assets" / "quest_board"
OUTPUT_DIR = ROOT / "assets" / "showcase" / "quest_board"


def _cover(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    scale = max(size[0] / image.width, size[1] / image.height)
    resized = image.resize(
        (round(image.width * scale), round(image.height * scale)),
        Image.Resampling.LANCZOS,
    )
    left = (resized.width - size[0]) // 2
    top = (resized.height - size[1]) // 2
    return resized.crop((left, top, left + size[0], top + size[1]))


def _remove_green(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    pixels = []
    for red, green, blue, _alpha in rgba.getdata():
        green_score = green - max(red, blue)
        if green_score <= 34:
            alpha = 255
        elif green_score >= 118:
            alpha = 0
        else:
            alpha = round(255 * (118 - green_score) / 84)
        if alpha < 255:
            # 半透明縁に緑RGBを残さない。
            spill = max(0, green - max(red, blue))
            green = max(0, green - spill)
        pixels.append((red, green, blue, alpha))
    rgba.putdata(pixels)
    return rgba


def build_wood_panel() -> Path:
    source = Image.open(SOURCE_DIR / "quest_board_wood_source.png").convert("RGB")
    panel = _cover(source, (1280, 512))
    panel = ImageEnhance.Color(panel).enhance(0.90)
    panel = ImageEnhance.Contrast(panel).enhance(0.94)
    output = OUTPUT_DIR / "quest_board_wood_panel.png"
    panel.save(output, optimize=True)
    return output


def build_notice_card() -> Path:
    source = _remove_green(Image.open(SOURCE_DIR / "quest_notice_card_source.png"))
    bbox = source.getchannel("A").getbbox()
    if bbox is None:
        raise SystemExit("quest notice source has no opaque subject")
    subject = source.crop(bbox).resize((360, 408), Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", (384, 432), (0, 0, 0, 0))
    shadow_alpha = subject.getchannel("A").filter(ImageFilter.GaussianBlur(5))
    shadow = Image.new("RGBA", subject.size, (45, 24, 10, 0))
    shadow.putalpha(shadow_alpha.point(lambda value: round(value * 0.34)))
    canvas.alpha_composite(shadow, (14, 16))
    canvas.alpha_composite(subject, (12, 10))

    alpha = canvas.getchannel("A")
    if alpha.getextrema() != (0, 255):
        raise SystemExit("quest notice output must include transparent and opaque pixels")
    output = OUTPUT_DIR / "quest_notice_card.png"
    canvas.save(output, optimize=True)
    return output


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    for output in (build_wood_panel(), build_notice_card()):
        with Image.open(output) as image:
            print(f"{output.relative_to(ROOT)}: {image.size} {image.mode}")


if __name__ == "__main__":
    main()
