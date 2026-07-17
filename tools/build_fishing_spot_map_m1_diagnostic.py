#!/usr/bin/env python3
"""Build fixed-baseline diagnostic boards for MAP-M1 Stage A."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps


ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ROOT / "docs/qa/evidence/fishing_spot_map"
REFERENCE = ROOT / "reference/06_fishing_spot_map_mockup.png"
FONT = ROOT / "assets/fonts/line_seed/LINESeedJP_A_TTF_Bd.ttf"
VIEWPORT = (1280, 720)
THUMBNAIL = (320, 180)
PREFIX = "2026-07-17_map_m1_stage_a"
LABEL_HEIGHT = 30
BACKGROUND = "#10151d"
TEXT = "#f4ead1"


def _load_viewport(path: Path) -> Image.Image:
	with Image.open(path) as opened:
		opened.load()
		image = opened.convert("RGB")
	if path == REFERENCE:
		return ImageOps.fit(image, VIEWPORT, Image.Resampling.LANCZOS)
	if image.size != VIEWPORT:
		raise ValueError(f"unexpected baseline size {image.size}: {path}")
	return image


def _font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
	try:
		return ImageFont.truetype(str(FONT), size)
	except OSError:
		return ImageFont.load_default()


def _board(
	items: list[tuple[str, Path]],
	cell_size: tuple[int, int],
	target: Path,
	*,
	grayscale: bool = False,
) -> None:
	board = Image.new(
		"RGB",
		(cell_size[0] * len(items), cell_size[1] + LABEL_HEIGHT),
		BACKGROUND,
	)
	draw = ImageDraw.Draw(board)
	font = _font(15)
	for index, (label, path) in enumerate(items):
		image = _load_viewport(path)
		if grayscale:
			image = ImageOps.grayscale(image).convert("RGB")
		if image.size != cell_size:
			image = image.resize(cell_size, Image.Resampling.LANCZOS)
		x = index * cell_size[0]
		board.paste(image, (x, LABEL_HEIGHT))
		draw.text((x + 8, 5), label, font=font, fill=TEXT)
	board.save(target, format="PNG", optimize=False, compress_level=9)


def main() -> int:
	baseline = EVIDENCE / "2026-07-17_v2_prebaseline_normal.png"
	normal_pair = [("CURRENT / NORMAL", baseline), ("REFERENCE / 06", REFERENCE)]
	_board(
		normal_pair,
		VIEWPORT,
		EVIDENCE / f"{PREFIX}_original_normal_reference.png",
	)
	_board(
		normal_pair,
		THUMBNAIL,
		EVIDENCE / f"{PREFIX}_320x180_normal_reference.png",
	)
	_board(
		normal_pair,
		VIEWPORT,
		EVIDENCE / f"{PREFIX}_grayscale_normal_reference.png",
		grayscale=True,
	)
	_board(
		[
			("NORMAL", baseline),
			("CONTINUE", EVIDENCE / "2026-07-17_v2_prebaseline_continue.png"),
			("DANGER CHART LOCK", EVIDENCE / "2026-07-17_v2_prebaseline_danger_chart_lock.png"),
			("REFERENCE / 06", REFERENCE),
		],
		THUMBNAIL,
		EVIDENCE / f"{PREFIX}_320x180_state_check.png",
	)
	print("MAP-M1 Stage A diagnostic evidence built from fixed baseline")
	return 0


if __name__ == "__main__":
	raise SystemExit(main())
