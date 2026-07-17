#!/usr/bin/env python3
"""Build deterministic STATUS-R5B screen-local shell assets.

The authored source supplies wood, brass and parchment texture. This processor
only performs fixed crops, 9-slice recomposition, palette grading and alpha
masking; it does not draw the authored material itself.
"""

from __future__ import annotations

import hashlib
import os
import tempfile
from pathlib import Path

from PIL import Image, ImageEnhance, ImageOps


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "tools/source_assets/status/status_r5b_shell_source.png"
OUTPUT_DIR = ROOT / "assets/showcase/status"

# The source's important hardware is confined to this fixed edge band.
SOURCE_MARGIN = (92, 88, 92, 76)


def _nine_slice(source: Image.Image, size: tuple[int, int], margin: int) -> Image.Image:
    source = source.convert("RGBA")
    sw, sh = source.size
    left, top, right, bottom = SOURCE_MARGIN
    x = (0, left, sw - right, sw)
    y = (0, top, sh - bottom, sh)
    out = Image.new("RGBA", size)
    tx = (0, margin, size[0] - margin, size[0])
    ty = (0, margin, size[1] - margin, size[1])
    for row in range(3):
        for col in range(3):
            crop = source.crop((x[col], y[row], x[col + 1], y[row + 1]))
            target = (tx[col], ty[row], tx[col + 1], ty[row + 1])
            crop = crop.resize((target[2] - target[0], target[3] - target[1]), Image.Resampling.LANCZOS)
            out.alpha_composite(crop, (target[0], target[1]))
    return out


def _paper_panel(source: Image.Image) -> Image.Image:
    panel = _nine_slice(source, (256, 256), 24)
    return _clear_source_matte(ImageEnhance.Contrast(panel).enhance(1.04))


def _dark_panel(source: Image.Image) -> Image.Image:
    panel = _nine_slice(source, (256, 256), 18)
    center_box = (18, 18, 238, 238)
    center = panel.crop(center_box)
    grain = ImageOps.grayscale(center)
    grain = ImageEnhance.Contrast(grain).enhance(0.48)
    navy = ImageOps.colorize(grain, black="#071523", white="#24435a").convert("RGBA")
    # Preserve a restrained amount of the source grain while making the well navy.
    navy.putalpha(255)
    panel.alpha_composite(navy, (18, 18))
    return _clear_source_matte(panel)


def _screen_shell(source: Image.Image) -> Image.Image:
    shell = _nine_slice(source, (1280, 720), 18)
    alpha = shell.getchannel("A")
    alpha.paste(0, (18, 18, 1262, 702))
    shell.putalpha(alpha)
    return _clear_source_matte(shell)


def _clear_source_matte(image: Image.Image) -> Image.Image:
    """Remove the near-black canvas matte outside the authored frame."""
    image = image.convert("RGBA")
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            if a > 0 and max(r, g, b) <= 12:
                pixels[x, y] = (r, g, b, 0)
    return image


def _decoded_hash(image: Image.Image) -> str:
    payload = image.mode.encode("ascii") + b"\0" + str(image.size).encode("ascii") + b"\0" + image.tobytes()
    return hashlib.sha256(payload).hexdigest()


def _write_if_changed(path: Path, candidate: Image.Image) -> bool:
    candidate = candidate.convert("RGBA")
    if path.exists():
        with Image.open(path) as current:
            current.load()
            current_rgba = current.convert("RGBA")
            if current_rgba.size == candidate.size and current_rgba.tobytes() == candidate.tobytes():
                print(f"unchanged {path.relative_to(ROOT)} {_decoded_hash(candidate)}")
                return False

    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp_name = tempfile.mkstemp(prefix=f".{path.stem}.", suffix=".png", dir=path.parent)
    os.close(fd)
    temp_path = Path(temp_name)
    try:
        candidate.save(temp_path, format="PNG", optimize=False, compress_level=9)
        os.replace(temp_path, path)
    finally:
        temp_path.unlink(missing_ok=True)
    print(f"updated {path.relative_to(ROOT)} {_decoded_hash(candidate)}")
    return True


def main() -> int:
    if not SOURCE.exists():
        raise FileNotFoundError(f"missing authored source: {SOURCE}")
    with Image.open(SOURCE) as opened:
        opened.load()
        source = opened.convert("RGBA")
    outputs = {
        OUTPUT_DIR / "status_panel_frame.png": _paper_panel(source),
        OUTPUT_DIR / "status_dark_frame.png": _dark_panel(source),
        OUTPUT_DIR / "status_screen_shell.png": _screen_shell(source),
    }
    for path, image in outputs.items():
        _write_if_changed(path, image)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
