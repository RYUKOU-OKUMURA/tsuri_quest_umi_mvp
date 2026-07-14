#!/usr/bin/env python3
"""Build persistent visual evidence for the Status R5-A portrait uplift."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageOps


ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ROOT / "docs/qa/evidence/status"
REFERENCE = ROOT / "reference/08_status_screen_mockup.png"
SOURCE = ROOT / "tools/source_assets/status/status_player_fishing_source.png"
PRODUCT = ROOT / "assets/showcase/status/status_player_fishing_portrait.png"
TMP = Path("/tmp")
PREFIX = "2026-07-14_r5a"
HERO_BOX = (418, 184, 530, 299)


def _open(path: Path) -> Image.Image:
    if not path.is_file():
        raise FileNotFoundError(path)
    return Image.open(path).convert("RGBA")


def _save(image: Image.Image, name: str) -> None:
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    image.save(EVIDENCE / name, format="PNG", optimize=False, compress_level=9)


def _checker(size: tuple[int, int], cell: int = 16) -> Image.Image:
    image = Image.new("RGBA", size, (229, 220, 197, 255))
    draw = ImageDraw.Draw(image)
    for y in range(0, size[1], cell):
        for x in range(0, size[0], cell):
            if (x // cell + y // cell) % 2:
                draw.rectangle((x, y, x + cell - 1, y + cell - 1), fill=(181, 174, 158, 255))
    return image


def _fit(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    return ImageOps.fit(image, size, method=Image.Resampling.LANCZOS, centering=(0.5, 0.5))


def build() -> None:
    before_normal = _open(TMP / "tsuri_status_r5a_before_normal.png")
    before_hard = _open(TMP / "tsuri_status_r5a_before_hard.png")
    after_normal = _open(TMP / "tsuri_status_r5a_after_normal.png")
    after_hard = _open(TMP / "tsuri_status_r5a_after_hard.png")
    reference = _open(REFERENCE)

    originals = {
        f"{PREFIX}_before_normal.png": before_normal,
        f"{PREFIX}_before_hard.png": before_hard,
        f"{PREFIX}_after_normal.png": after_normal,
        f"{PREFIX}_after_hard.png": after_hard,
        f"{PREFIX}_reference.png": reference,
    }
    for name, image in originals.items():
        _save(image, name)

    _save(
        Image.new("RGBA", (1280 * 3, 720), (0, 0, 0, 255)),
        f"{PREFIX}_full_normal_compare.png",
    )
    full_normal = _open(EVIDENCE / f"{PREFIX}_full_normal_compare.png")
    full_normal.paste(before_normal, (0, 0))
    full_normal.paste(after_normal, (1280, 0))
    full_normal.paste(reference, (2560, 0))
    _save(full_normal, f"{PREFIX}_full_normal_compare.png")

    full_hard = Image.new("RGBA", (1280 * 3, 720), (0, 0, 0, 255))
    full_hard.paste(before_hard, (0, 0))
    full_hard.paste(after_hard, (1280, 0))
    full_hard.paste(reference, (2560, 0))
    _save(full_hard, f"{PREFIX}_full_hard_compare.png")

    thumbs = [_fit(image, (320, 180)) for image in (before_normal, after_normal, reference)]
    thumbnail = Image.new("RGBA", (960, 180), (0, 0, 0, 255))
    for index, thumb in enumerate(thumbs):
        thumbnail.paste(thumb, (index * 320, 0))
    _save(thumbnail, f"{PREFIX}_thumbnail_compare.png")

    gray = Image.new("L", (960, 180), 0)
    for index, thumb in enumerate(thumbs):
        gray.paste(ImageOps.grayscale(thumb), (index * 320, 0))
    _save(gray.convert("RGBA"), f"{PREFIX}_gray_compare.png")

    source = _fit(_open(SOURCE), (320, 320))
    product = _open(PRODUCT)
    product_cell = _checker((320, 320))
    product_cell.alpha_composite(_fit(product, (320, 320)))
    runtime = _fit(after_normal.crop(HERO_BOX), (320, 320))
    contact = Image.new("RGBA", (960, 320), (0, 0, 0, 255))
    for index, image in enumerate((source, product_cell, runtime)):
        contact.paste(image, (index * 320, 0))
    _save(contact, f"{PREFIX}_asset_contact.png")


if __name__ == "__main__":
    build()
