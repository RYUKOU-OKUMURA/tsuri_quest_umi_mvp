#!/usr/bin/env python3
"""Build deterministic M3 fish-market before/after/reference evidence."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageChops


ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ROOT / "docs" / "qa" / "evidence" / "fish_market"
REFERENCE = ROOT / "reference" / "10_fish_market_mockup.png"
STATES = ("select", "confirm", "sold", "empty")
CTA_STATES = ("normal", "hover", "pressed", "focus")
# The CTA comparison includes the old StyleBoxFlat shadow halo while the
# Control itself remains frozen at CART_ACTION_RECT=(1008,612,190,50).
ALLOWED_RECTS = ((41, 109, 701, 677), (1004, 610, 1210, 668))


def load_rgb(path: Path) -> Image.Image:
    if not path.is_file():
        raise SystemExit(f"missing evidence input: {path}")
    with Image.open(path) as source:
        source.load()
        return source.convert("RGB")


def save(image: Image.Image, path: Path) -> None:
    image.save(path, format="PNG", optimize=False, compress_level=9)
    print(path.relative_to(ROOT))


def triptych(images: tuple[Image.Image, Image.Image, Image.Image]) -> Image.Image:
    width = sum(image.width for image in images)
    height = max(image.height for image in images)
    output = Image.new("RGB", (width, height))
    x = 0
    for image in images:
        output.paste(image, (x, 0))
        x += image.width
    return output


def assert_diff_is_scoped(before: Image.Image, after: Image.Image, state: str) -> None:
    diff = ImageChops.difference(before, after).convert("L")
    allowed = Image.new("L", before.size, 0)
    for rect in ALLOWED_RECTS:
        allowed.paste(255, rect)
    outside = ImageChops.multiply(diff, ImageChops.invert(allowed))
    if outside.getbbox() is not None:
        raise SystemExit(f"{state}: M3 diff escaped frozen inventory/CTA regions: {outside.getbbox()}")
    print(f"{state}: scoped diff bbox={diff.getbbox()}")


def build_state_evidence() -> None:
    reference_original = load_rgb(REFERENCE)
    reference_runtime = reference_original.resize((1280, 720), Image.Resampling.LANCZOS)
    reference_thumb = reference_original.resize((320, 180), Image.Resampling.LANCZOS)
    for state in STATES:
        before = load_rgb(EVIDENCE / f"2026-07-13_m3_before_{state}.png")
        after = load_rgb(Path(f"/tmp/tsuri_market_{state}.png"))
        assert_diff_is_scoped(before, after, state)
        save(after, EVIDENCE / f"2026-07-13_m3_after_{state}.png")
        save(
            triptych((before, after, reference_runtime)),
            EVIDENCE / f"2026-07-13_m3_{state}_original_triptych.png",
        )
        thumb = tuple(
            image.resize((320, 180), Image.Resampling.LANCZOS)
            for image in (before, after, reference_thumb)
        )
        save(
            triptych(thumb),
            EVIDENCE / f"2026-07-13_m3_{state}_thumbnail_triptych.png",
        )
        gray = tuple(image.convert("L").convert("RGB") for image in thumb)
        save(
            triptych(gray),
            EVIDENCE / f"2026-07-13_m3_{state}_gray_triptych.png",
        )


def build_cta_evidence() -> None:
    full_states: list[Image.Image] = []
    for state in CTA_STATES:
        image = load_rgb(Path(f"/tmp/tsuri_market_cta_{state}.png"))
        save(image, EVIDENCE / f"2026-07-13_m3_cta_{state}.png")
        full_states.append(image)
    disabled = load_rgb(Path("/tmp/tsuri_market_empty.png"))
    crops = [image.crop((996, 600, 1210, 674)) for image in (*full_states, disabled)]
    save(
        triptych((crops[0], crops[1], crops[2])),
        EVIDENCE / "2026-07-13_m3_cta_normal_hover_pressed.png",
    )
    focus_disabled = Image.new("RGB", (crops[3].width + crops[4].width, crops[3].height))
    focus_disabled.paste(crops[3], (0, 0))
    focus_disabled.paste(crops[4], (crops[3].width, 0))
    save(focus_disabled, EVIDENCE / "2026-07-13_m3_cta_focus_disabled.png")


def main() -> int:
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    build_state_evidence()
    build_cta_evidence()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
