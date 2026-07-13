#!/usr/bin/env python3
"""Build side-by-side visual QA boards for single-screen previews."""

from __future__ import annotations

import argparse
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageStat


ROOT = Path(__file__).resolve().parents[1]
FONT_BOLD = ROOT / "assets" / "fonts" / "line_seed" / "LINESeedJP_A_TTF_Bd.ttf"
FONT_REGULAR = ROOT / "assets" / "fonts" / "line_seed" / "LINESeedJP_A_TTF_Rg.ttf"
VIEWPORT = (1280, 720)
LABEL_H = 34
GAP = 18
BG = "#10151d"
TEXT = "#f4ead1"
MUTED = "#9fe8ff"

# Runtime screenshots are full-screen UI captures. Match the existing
# screen-specific 0.20 visible-pixel gates so dark game screens are
# accepted while black/error frames are rejected.
MIN_NONTRANSPARENT_PIXEL_RATIO = 0.95
MIN_MEAN_ALPHA_RATIO = 0.95
MIN_OPAQUE_PIXEL_RATIO = 0.95
MIN_CONTENT_PIXEL_RATIO = 0.20
CONTENT_RGB_SUM_THRESHOLD = 80
MIN_COLOR_STDDEV = 4.0

PRESETS = {
    "title_e7": [
        {
            "id": f"TITLE_E7_{state.upper()}",
            "reference": Path("/tmp/tsuri_title_empty.png"),
            "capture": Path(f"/tmp/tsuri_title_{state}.png"),
            "out": Path(f"/tmp/tsuri_title_{state}_compare.png"),
        }
        for state in ["occupied", "3slot", "difficulty", "overwrite"]
    ],
    "title_storage_block": [
        {
            "id": "TITLE_STORAGE_BLOCK",
            "reference": Path("/tmp/tsuri_title_normal.png"),
            "capture": Path("/tmp/tsuri_title_storage_blocked.png"),
            "out": Path("/tmp/tsuri_title_storage_blocked_compare.png"),
        }
    ],
    "title_invalid_artifact": [
        {
            "id": "TITLE_INVALID_ARTIFACT",
            "reference": Path("/tmp/tsuri_title_normal.png"),
            "capture": Path("/tmp/tsuri_title_invalid_artifact.png"),
            "out": Path("/tmp/tsuri_title_invalid_artifact_compare.png"),
        }
    ],
    "status": [
        {
            "id": "STATUS_NORMAL",
            "reference": ROOT / "reference" / "08_status_screen_mockup.png",
            "capture": Path("/tmp/tsuri_status_normal.png"),
            "out": Path("/tmp/tsuri_status_normal_compare.png"),
        },
        {
            "id": "STATUS_HARD",
            "reference": ROOT / "reference" / "08_status_screen_mockup.png",
            "capture": Path("/tmp/tsuri_status_hard.png"),
            "out": Path("/tmp/tsuri_status_hard_compare.png"),
        },
    ],
    "fish_book": [
        {
            "id": "FISH_BOOK",
            "reference": ROOT / "reference" / "07_fish_book_mockup.png",
            "capture": Path("/tmp/tsuri_fish_book.png"),
            "out": Path("/tmp/tsuri_fish_book_compare.png"),
        }
    ],
    "fishing_spot_map": [
        {
            "id": "FISHING_SPOT_DEFAULT",
            "reference": ROOT / "reference" / "06_fishing_spot_map_mockup.png",
            "capture": Path("/tmp/tsuri_fishing_spot_map.png"),
            "out": Path("/tmp/tsuri_fishing_spot_map_compare.png"),
        },
        {
            "id": "FISHING_SPOT_CONTINUE",
            "reference": ROOT / "reference" / "06_fishing_spot_map_mockup.png",
            "capture": Path("/tmp/tsuri_fishing_spot_map_continue.png"),
            "out": Path("/tmp/tsuri_fishing_spot_map_continue_compare.png"),
        },
        {
            "id": "FISHING_SPOT_DANGER_CHART",
            "reference": ROOT / "reference" / "06_fishing_spot_map_mockup.png",
            "capture": Path("/tmp/tsuri_fishing_spot_map_danger_chart.png"),
            "out": Path("/tmp/tsuri_fishing_spot_map_danger_chart_compare.png"),
        },
    ],
    "tackle_shop": [
        {
            "id": "TACKLE_SHOP_ROD",
            "reference": ROOT / "reference" / "09_tackle_shop_rod_mockup.png",
            "capture": Path("/tmp/tsuri_tackle_shop_rod.png"),
            "out": Path("/tmp/tsuri_tackle_shop_rod_compare.png"),
        },
        {
            "id": "TACKLE_SHOP_RIG",
            "reference": ROOT / "reference" / "09_tackle_shop_gear_mockup.png",
            "capture": Path("/tmp/tsuri_tackle_shop_rig.png"),
            "out": Path("/tmp/tsuri_tackle_shop_rig_compare.png"),
        },
        {
            "id": "TACKLE_SHOP_ROD_EXPANDED",
            "reference": ROOT / "reference" / "09_tackle_shop_rod_mockup.png",
            "capture": Path("/tmp/tsuri_tackle_shop_rod_expanded.png"),
            "capture_size": (2124, 1507),
            "out": Path("/tmp/tsuri_tackle_shop_rod_expanded_compare.png"),
        },
        {
            "id": "TACKLE_SHOP_RIG_EXPANDED",
            "reference": ROOT / "reference" / "09_tackle_shop_gear_mockup.png",
            "capture": Path("/tmp/tsuri_tackle_shop_rig_expanded.png"),
            "capture_size": (2124, 1507),
            "out": Path("/tmp/tsuri_tackle_shop_rig_expanded_compare.png"),
        },
    ],
    "market": [
        {
            "id": "FISH_MARKET_SELECT",
            "reference": ROOT / "reference" / "10_fish_market_mockup.png",
            "capture": Path("/tmp/tsuri_market_select.png"),
            "out": Path("/tmp/tsuri_market_select_compare.png"),
        },
        {
            "id": "FISH_MARKET_CONFIRM",
            "reference": ROOT / "reference" / "10_fish_market_mockup.png",
            "capture": Path("/tmp/tsuri_market_confirm.png"),
            "out": Path("/tmp/tsuri_market_confirm_compare.png"),
        },
        {
            "id": "FISH_MARKET_SOLD",
            "reference": ROOT / "reference" / "10_fish_market_mockup.png",
            "capture": Path("/tmp/tsuri_market_sold.png"),
            "out": Path("/tmp/tsuri_market_sold_compare.png"),
        },
        {
            "id": "FISH_MARKET_EMPTY",
            "reference": ROOT / "reference" / "10_fish_market_mockup.png",
            "capture": Path("/tmp/tsuri_market_empty.png"),
            "out": Path("/tmp/tsuri_market_empty_compare.png"),
        },
    ],
    "quest_board": [
        {
            "id": "QUEST_BOARD",
            "reference": ROOT / "reference" / "11_quest_board_mockup.png",
            "capture": Path("/tmp/tsuri_quest_board.png"),
            "out": Path("/tmp/tsuri_quest_board_compare.png"),
        }
    ],
    "shark_pen": [
        {
            "id": "SHARK_PEN",
            "reference": ROOT / "reference" / "12_shark_pen_mockup.png",
            "capture": Path("/tmp/tsuri_shark_pen.png"),
            "out": Path("/tmp/tsuri_shark_pen_compare.png"),
        }
    ],
}


def font(size: int, *, bold: bool = True) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    path = FONT_BOLD if bold else FONT_REGULAR
    try:
        return ImageFont.truetype(str(path), size)
    except OSError:
        return ImageFont.load_default()


def fit_viewport(image: Image.Image) -> Image.Image:
    image = image.convert("RGB")
    if image.size == VIEWPORT:
        return image
    scale = min(VIEWPORT[0] / image.width, VIEWPORT[1] / image.height)
    resized = image.resize((round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS)
    canvas = Image.new("RGB", VIEWPORT, "#0b0e14")
    canvas.paste(resized, ((VIEWPORT[0] - resized.width) // 2, (VIEWPORT[1] - resized.height) // 2))
    return canvas


def draw_label(draw: ImageDraw.ImageDraw, x: int, title: str, path: Path) -> None:
    title_font = font(16)
    path_font = font(12, bold=False)
    draw.text((x, 7), title, font=title_font, fill=TEXT)
    path_x = x + int(draw.textlength(title, font=title_font)) + 16
    draw.text((path_x, 9), str(path), font=path_font, fill=MUTED)


def validate_runtime_image(
    image_path: Path,
    image_id: str,
    expected_size: tuple[int, int] = VIEWPORT,
) -> tuple[list[str], dict[str, object]]:
    try:
        with Image.open(image_path) as source:
            source.load()
            mode = source.mode
            size = source.size
            if mode not in {"RGB", "RGBA"}:
                return [f"{image_id}: runtime image mode must be RGB/RGBA, got {mode}: {image_path}"], {}
            if size != expected_size:
                return [
                    f"{image_id}: runtime image must be {expected_size[0]}x{expected_size[1]}, "
                    f"got {size[0]}x{size[1]}: {image_path}"
                ], {}

            rgba = source.convert("RGBA")
            alpha_histogram = rgba.getchannel("A").histogram()
            total_pixels = size[0] * size[1]
            nontransparent_ratio = (total_pixels - alpha_histogram[0]) / total_pixels
            mean_alpha_ratio = sum(
                alpha * count for alpha, count in enumerate(alpha_histogram)
            ) / (255.0 * total_pixels)
            opaque_ratio = alpha_histogram[255] / total_pixels
            rgb = Image.new("RGB", size, "#000000")
            rgb.paste(rgba, mask=rgba.getchannel("A"))
            content_pixels = sum(
                1 for red, green, blue in rgb.getdata()
                if red + green + blue > CONTENT_RGB_SUM_THRESHOLD
            )
            content_ratio = content_pixels / total_pixels
            color_stddev = max(ImageStat.Stat(rgb).stddev)
    except OSError as exc:
        return [f"{image_id}: runtime image cannot be decoded: {image_path}: {exc}"], {}

    failures: list[str] = []
    if nontransparent_ratio < MIN_NONTRANSPARENT_PIXEL_RATIO:
        failures.append(
            f"{image_id}: runtime image is transparent or incomplete "
            f"(nontransparent_ratio={nontransparent_ratio:.3f}, "
            f"minimum={MIN_NONTRANSPARENT_PIXEL_RATIO:.2f}): {image_path}"
        )
    if mean_alpha_ratio < MIN_MEAN_ALPHA_RATIO:
        failures.append(
            f"{image_id}: runtime image has low average alpha "
            f"(mean_alpha_ratio={mean_alpha_ratio:.3f}, "
            f"minimum={MIN_MEAN_ALPHA_RATIO:.2f}): {image_path}"
        )
    if opaque_ratio < MIN_OPAQUE_PIXEL_RATIO:
        failures.append(
            f"{image_id}: runtime image is not sufficiently opaque "
            f"(opaque_ratio={opaque_ratio:.3f}, "
            f"minimum={MIN_OPAQUE_PIXEL_RATIO:.2f}): {image_path}"
        )
    if content_ratio < MIN_CONTENT_PIXEL_RATIO:
        failures.append(
            f"{image_id}: runtime image is blank or nearly black "
            f"(content_ratio={content_ratio:.3f}, minimum={MIN_CONTENT_PIXEL_RATIO:.2f}): {image_path}"
        )
    if color_stddev < MIN_COLOR_STDDEV:
        failures.append(
            f"{image_id}: runtime image is empty or nearly single-color "
            f"(max_channel_stddev={color_stddev:.3f}, minimum={MIN_COLOR_STDDEV:.1f}): {image_path}"
        )
    return failures, {
        "mode": mode,
        "size": size,
        "nontransparent_ratio": nontransparent_ratio,
        "mean_alpha_ratio": mean_alpha_ratio,
        "opaque_ratio": opaque_ratio,
        "content_ratio": content_ratio,
        "color_stddev": color_stddev,
    }


def format_runtime_metrics(image_id: str, metrics: dict[str, object]) -> str:
    return (
        f"{image_id}: runtime image ok "
        f"{metrics['size'][0]}x{metrics['size'][1]} {metrics['mode']} "
        f"alpha_nonzero={metrics['nontransparent_ratio']:.3f} "
        f"alpha_mean={metrics['mean_alpha_ratio']:.3f} "
        f"opaque={metrics['opaque_ratio']:.3f} "
        f"content={metrics['content_ratio']:.3f} "
        f"stddev={metrics['color_stddev']:.3f}"
    )


def is_formal_reference(path: Path) -> bool:
    return path.resolve().is_relative_to((ROOT / "reference").resolve())


def build_pair(
    reference: Path,
    capture: Path,
    out: Path,
    state_id: str,
    capture_size: tuple[int, int] = VIEWPORT,
) -> list[str]:
    missing = [path for path in (reference, capture) if not path.exists()]
    if missing:
        return [f"{state_id}: missing {path}" for path in missing]

    failures: list[str] = []
    if not is_formal_reference(reference):
        reference_failures, reference_metrics = validate_runtime_image(
            reference,
            f"{state_id} reference",
        )
        failures.extend(reference_failures)
        if not reference_failures:
            print(format_runtime_metrics(f"{state_id} reference", reference_metrics))
    capture_failures, capture_metrics = validate_runtime_image(
        capture,
        f"{state_id} current",
        capture_size,
    )
    failures.extend(capture_failures)
    if failures:
        return failures
    print(format_runtime_metrics(f"{state_id} current", capture_metrics))

    ref = fit_viewport(Image.open(reference))
    cur = fit_viewport(Image.open(capture))
    board = Image.new("RGB", (VIEWPORT[0] * 2 + GAP, VIEWPORT[1] + LABEL_H), BG)
    draw = ImageDraw.Draw(board)
    draw_label(draw, 8, f"{state_id} reference", reference)
    draw_label(draw, VIEWPORT[0] + GAP + 8, f"{state_id} current", capture)
    board.paste(ref, (0, LABEL_H))
    board.paste(cur, (VIEWPORT[0] + GAP, LABEL_H))
    out.parent.mkdir(parents=True, exist_ok=True)
    board.save(out)
    print(out)
    return []


def run_self_test() -> int:
    with tempfile.TemporaryDirectory(prefix="screen_visual_comparison_") as temporary:
        root = Path(temporary)
        fixtures = {
            "valid_rgb": Image.new("RGB", VIEWPORT, "#102840"),
            "valid_rgba": Image.new("RGBA", VIEWPORT, "#102840ff"),
            "transparent": Image.new("RGBA", VIEWPORT, (255, 255, 255, 0)),
            "black": Image.new("RGB", VIEWPORT, "#000000"),
            "near_black": Image.new("RGB", VIEWPORT, "#080808"),
            "uniform": Image.new("RGB", VIEWPORT, "#b07030"),
            "low_alpha": Image.new("RGBA", VIEWPORT, (16, 40, 64, 96)),
            "wrong_size": Image.new("RGB", (640, 360), "#204060"),
            "wrong_mode": Image.new("L", VIEWPORT, 128),
        }
        for name in ("valid_rgb", "valid_rgba"):
            draw = ImageDraw.Draw(fixtures[name])
            draw.rectangle((80, 80, 600, 640), fill="#d4a84f")
            draw.rectangle((680, 120, 1200, 600), fill="#2f8db5")
        low_alpha_draw = ImageDraw.Draw(fixtures["low_alpha"])
        low_alpha_draw.rectangle((80, 80, 600, 640), fill=(212, 168, 79, 96))
        low_alpha_draw.rectangle((680, 120, 1200, 600), fill=(47, 141, 181, 96))

        paths: dict[str, Path] = {}
        for name, image in fixtures.items():
            path = root / f"{name}.png"
            image.save(path)
            paths[name] = path

        failures: list[str] = []
        for name in ("valid_rgb", "valid_rgba"):
            fixture_failures, _metrics = validate_runtime_image(paths[name], name)
            if fixture_failures:
                failures.append(f"{name} should pass: {fixture_failures}")
        rejected = {
            "transparent": "transparent or incomplete",
            "black": "blank or nearly black",
            "near_black": "blank or nearly black",
            "uniform": "single-color",
            "low_alpha": "low average alpha",
            "wrong_size": "must be 1280x720",
            "wrong_mode": "mode must be RGB/RGBA",
        }
        for name, expected_message in rejected.items():
            fixture_failures, _metrics = validate_runtime_image(paths[name], name)
            if not fixture_failures:
                failures.append(f"{name} should fail")
            elif not any(expected_message in failure for failure in fixture_failures):
                failures.append(
                    f"{name} should fail with '{expected_message}', got {fixture_failures}"
                )
        runtime_reference_out = root / "runtime_reference_compare.png"
        runtime_reference_failures = build_pair(
            paths["low_alpha"],
            paths["valid_rgb"],
            runtime_reference_out,
            "runtime_reference",
        )
        if not any(
            "reference" in failure and "low average alpha" in failure
            for failure in runtime_reference_failures
        ):
            failures.append(
                "runtime-generated reference should use the same alpha validation: "
                f"{runtime_reference_failures}"
            )
        if runtime_reference_out.exists():
            failures.append("invalid runtime-generated reference must not create a comparison")

    if failures:
        print("screen visual comparison self-test failed:")
        for failure in failures:
            print(f"  - {failure}")
        return 1
    print("screen visual comparison self-test: ok")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("preset", nargs="?", choices=sorted(PRESETS), help="Comparison preset to build.")
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        return run_self_test()
    if args.preset is None:
        parser.error("preset is required unless --self-test is used")

    failures: list[str] = []
    for item in PRESETS[args.preset]:
        failures.extend(
            build_pair(
                item["reference"],
                item["capture"],
                item["out"],
                item["id"],
                item.get("capture_size", VIEWPORT),
            )
        )
    if failures:
        print("visual comparison failed:")
        for failure in failures:
            print(f"  - {failure}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
