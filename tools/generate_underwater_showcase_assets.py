#!/usr/bin/env python3
from __future__ import annotations

import math
import struct
import zlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "showcase" / "underwater"

Color = tuple[int, int, int, int]


def clamp(v: int) -> int:
    return max(0, min(255, v))


def lerp(a: int, b: int, t: float) -> int:
    return int(round(a + (b - a) * t))


def mix(c1: tuple[int, int, int], c2: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return (lerp(c1[0], c2[0], t), lerp(c1[1], c2[1], t), lerp(c1[2], c2[2], t))


class Canvas:
    def __init__(self, w: int, h: int, fill: Color = (0, 0, 0, 0)) -> None:
        self.w = w
        self.h = h
        self.pixels = bytearray(w * h * 4)
        self.clear(fill)

    def clear(self, color: Color) -> None:
        r, g, b, a = color
        self.pixels[:] = bytes((r, g, b, a)) * (self.w * self.h)

    def set_opaque(self, x: int, y: int, color: tuple[int, int, int]) -> None:
        if x < 0 or y < 0 or x >= self.w or y >= self.h:
            return
        i = (y * self.w + x) * 4
        self.pixels[i : i + 4] = bytes((color[0], color[1], color[2], 255))

    def blend(self, x: int, y: int, color: Color) -> None:
        if x < 0 or y < 0 or x >= self.w or y >= self.h:
            return
        sr, sg, sb, sa = color
        if sa <= 0:
            return
        i = (y * self.w + x) * 4
        if sa >= 255:
            self.pixels[i : i + 4] = bytes((sr, sg, sb, 255))
            return
        dr, dg, db, da = self.pixels[i], self.pixels[i + 1], self.pixels[i + 2], self.pixels[i + 3]
        a = sa / 255.0
        out_a = sa + da * (1.0 - a)
        self.pixels[i] = clamp(int(sr * a + dr * (1.0 - a)))
        self.pixels[i + 1] = clamp(int(sg * a + dg * (1.0 - a)))
        self.pixels[i + 2] = clamp(int(sb * a + db * (1.0 - a)))
        self.pixels[i + 3] = clamp(int(out_a))

    def rect(self, x0: int, y0: int, x1: int, y1: int, color: Color) -> None:
        for y in range(max(0, y0), min(self.h, y1 + 1)):
            for x in range(max(0, x0), min(self.w, x1 + 1)):
                self.blend(x, y, color)

    def ellipse(self, x0: int, y0: int, x1: int, y1: int, color: Color) -> None:
        cx = (x0 + x1) * 0.5
        cy = (y0 + y1) * 0.5
        rx = max(0.5, (x1 - x0) * 0.5)
        ry = max(0.5, (y1 - y0) * 0.5)
        for y in range(max(0, y0), min(self.h, y1 + 1)):
            dy = (y - cy) / ry
            for x in range(max(0, x0), min(self.w, x1 + 1)):
                dx = (x - cx) / rx
                if dx * dx + dy * dy <= 1.0:
                    self.blend(x, y, color)

    def polygon(self, points: list[tuple[float, float]], color: Color) -> None:
        if len(points) < 3:
            return
        min_y = max(0, int(math.floor(min(y for _, y in points))))
        max_y = min(self.h - 1, int(math.ceil(max(y for _, y in points))))
        n = len(points)
        for y in range(min_y, max_y + 1):
            scan_y = y + 0.5
            xs: list[float] = []
            for i in range(n):
                x0, y0 = points[i]
                x1, y1 = points[(i + 1) % n]
                if y0 == y1:
                    continue
                if (y0 <= scan_y < y1) or (y1 <= scan_y < y0):
                    t = (scan_y - y0) / (y1 - y0)
                    xs.append(x0 + (x1 - x0) * t)
            xs.sort()
            for i in range(0, len(xs) - 1, 2):
                x_start = max(0, int(math.floor(xs[i])))
                x_end = min(self.w - 1, int(math.ceil(xs[i + 1])))
                for x in range(x_start, x_end + 1):
                    self.blend(x, y, color)

    def line(self, x0: float, y0: float, x1: float, y1: float, color: Color, width: int = 1) -> None:
        dx = x1 - x0
        dy = y1 - y0
        steps = max(1, int(max(abs(dx), abs(dy))))
        radius = max(0, width // 2)
        for step in range(steps + 1):
            t = step / steps
            x = int(round(x0 + dx * t))
            y = int(round(y0 + dy * t))
            self.rect(x - radius, y - radius, x + radius, y + radius, color)

    def paste(self, other: "Canvas", ox: int, oy: int) -> None:
        for y in range(other.h):
            for x in range(other.w):
                i = (y * other.w + x) * 4
                color = tuple(other.pixels[i : i + 4])
                self.blend(ox + x, oy + y, color)  # type: ignore[arg-type]

    def scaled_nearest(self, factor: int) -> "Canvas":
        out = Canvas(self.w * factor, self.h * factor)
        for y in range(out.h):
            sy = y // factor
            for x in range(out.w):
                sx = x // factor
                src = (sy * self.w + sx) * 4
                dst = (y * out.w + x) * 4
                out.pixels[dst : dst + 4] = self.pixels[src : src + 4]
        return out

    def save_png(self, path: Path) -> None:
        raw = bytearray()
        stride = self.w * 4
        for y in range(self.h):
            raw.append(0)
            start = y * stride
            raw.extend(self.pixels[start : start + stride])

        def chunk(name: bytes, data: bytes) -> bytes:
            return (
                struct.pack(">I", len(data))
                + name
                + data
                + struct.pack(">I", zlib.crc32(name + data) & 0xFFFFFFFF)
            )

        png = bytearray(b"\x89PNG\r\n\x1a\n")
        png.extend(chunk(b"IHDR", struct.pack(">IIBBBBB", self.w, self.h, 8, 6, 0, 0, 0)))
        png.extend(chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
        png.extend(chunk(b"IEND", b""))
        path.write_bytes(png)


def create_background() -> None:
    w, h = 480, 270
    c = Canvas(w, h, (0, 0, 0, 255))
    top = (45, 159, 214)
    mid = (20, 101, 164)
    bottom = (7, 38, 73)
    for y in range(h):
        t = y / (h - 1)
        base = mix(top, mid, min(1.0, t * 1.4))
        base = mix(base, bottom, max(0.0, (t - 0.38) / 0.62))
        for x in range(w):
            d = ((x * 7 + y * 11) % 17) - 8
            c.set_opaque(x, y, (clamp(base[0] + d // 4), clamp(base[1] + d // 3), clamp(base[2] + d // 3)))

    for x in range(0, w, 14):
        y = 5 + int(math.sin(x * 0.08) * 3)
        c.line(x, y, x + 18, y + 1, (202, 244, 255, 120), 1)
    c.rect(0, 0, w, 5, (205, 247, 255, 65))

    for i, x in enumerate([48, 92, 152, 220, 292, 356, 420]):
        sway = math.sin(i * 1.8) * 12
        c.polygon([(x - 10, 0), (x + 12, 0), (x + 58 + sway, 218), (x + 30 + sway, 220)], (185, 235, 255, 34))

    for i in range(19):
        x = 42 + (i * 37) % 390
        y = 54 + (i * 23) % 92
        s = 4 + (i % 4)
        col = (4, 30, 56, 68)
        c.ellipse(x - s, y - s // 2, x + s, y + s // 2, col)
        c.polygon([(x - s, y), (x - s - 7, y - 4), (x - s - 7, y + 4)], col)

    sand = [(0, 238), (60, 229), (130, 241), (218, 232), (300, 244), (392, 230), (480, 237), (480, 270), (0, 270)]
    c.polygon(sand, (174, 155, 97, 255))
    for i in range(90):
        x = (i * 47 + 11) % w
        y = 235 + (i * 29) % 34
        c.rect(x, y, x + 1 + (i % 3), y + 1, (117 + i % 24, 122 + i % 28, 92 + i % 18, 150))

    def rock(cx: int, cy: int, r: int) -> None:
        c.ellipse(cx - r, cy - int(r * 0.65), cx + r, cy + int(r * 0.72), (36, 80, 94, 255))
        c.ellipse(cx - int(r * 0.78), cy - int(r * 0.72), cx + int(r * 0.24), cy + int(r * 0.20), (66, 111, 117, 255))
        c.ellipse(cx - int(r * 0.68), cy - int(r * 0.54), cx - int(r * 0.12), cy - int(r * 0.16), (107, 158, 151, 70))
        c.line(cx - r, cy + int(r * 0.45), cx + r, cy + int(r * 0.35), (7, 36, 54, 100), 2)

    rock(52, 230, 34)
    rock(410, 234, 47)
    rock(352, 247, 24)

    for i in range(13):
        x = 54 + i * 31
        height = 16 + (i * 7) % 32
        c.line(x, 248, x + (i % 5 - 2) * 2, 248 - height, (35, 127 + (i % 3) * 15, 104, 220), 2)
        c.line(x + 3, 250, x + 5, 250 - height * 0.65, (54, 150, 95, 190), 1)

    for i in range(58):
        x = 20 + (i * 73) % 440
        y = 15 + (i * 31) % 225
        r = 1 + i % 3
        c.ellipse(x - r, y - r, x + r, y + r, (193, 240, 255, 60))
        if r > 1:
            c.ellipse(x - r + 1, y - r + 1, x + r - 1, y + r - 1, (0, 0, 0, 45))

    c.scaled_nearest(2).save_png(OUT_DIR / "underwater_battle_bg.png")


def fish_frame(frame_index: int) -> Canvas:
    w, h = 144, 80
    c = Canvas(w, h)
    cx = 72 + [0, 1, 4, -1][frame_index]
    cy = 39 + [0, -1, 0, 2][frame_index]
    dark = (25, 35, 47, 255)
    darker = (9, 17, 27, 255)
    belly = (202, 199, 184, 230)

    tail_spread = 19 + (2 if frame_index == 2 else 0)
    c.polygon([(24, cy), (4, cy - tail_spread), (13, cy), (4, cy + tail_spread)], dark)
    c.polygon([(40, cy - 23), (60, cy - 37), (82, cy - 22)], dark)
    for i in range(7):
        x = 48 + i * 6
        c.line(x, cy - 24, x + 4, cy - 36, (205, 210, 205, 220), 1)

    c.ellipse(20, cy - 28, 124, cy + 26, darker)
    for i in range(16):
        t = i / 15
        y0 = cy - 25 + i * 3
        color = mix((142, 154, 162), (54, 67, 82), t) + (255,)
        c.rect(24, y0, 119, y0 + 2, color)
    c.ellipse(24, cy - 25, 120, cy + 23, (0, 0, 0, 0))
    c.ellipse(40, cy + 3, 106, cy + 23, belly)

    for row in range(4):
        for col in range(11):
            x = 42 + col * 6 + (row % 2) * 3
            y = cy - 14 + row * 7
            c.rect(x, y, x + 2, y + 1, (190, 198, 198, 70))

    for x in [48, 60, 72, 84, 96]:
        c.line(x, cy - 22, x + 7, cy + 18, (20, 27, 37, 130), 3)

    c.polygon([(68, cy + 5), (52, cy + 23), (82, cy + 14)], (117, 130, 137, 220))
    c.line(98, cy - 11, 102, cy + 13, (18, 25, 35, 190), 2)
    c.line(117, cy + 4, 129, cy + 6, darker, 2)
    c.ellipse(104, cy - 10, 114, cy, (239, 218, 151, 255))
    c.ellipse(108, cy - 7, 113, cy - 2, (8, 12, 16, 255))
    c.blend(109, cy - 7, (255, 255, 255, 255))

    if frame_index == 2:
        c.line(13, cy - 28, 4, cy - 19, (129, 222, 255, 120), 2)
        c.line(10, cy + 29, 0, cy + 18, (225, 252, 255, 90), 1)
    if frame_index == 3:
        c.rect(38, cy + 24, 108, cy + 27, (255, 255, 255, 42))
    return c.scaled_nearest(2)


def create_fish_sheet() -> None:
    frames = [fish_frame(i) for i in range(4)]
    sheet = Canvas(frames[0].w * 4, frames[0].h)
    for i, frame in enumerate(frames):
        sheet.paste(frame, i * frame.w, 0)
    sheet.save_png(OUT_DIR / "kurodai_showcase_sheet.png")


def create_hit_burst() -> None:
    c = Canvas(360, 160)
    cx, cy = 180, 82
    points: list[tuple[float, float]] = []
    for i in range(28):
        angle = -math.pi / 2 + i * math.tau / 28
        radius = 76 if i % 2 == 0 else 48
        points.append((cx + math.cos(angle) * radius, cy + math.sin(angle) * radius))
    c.polygon(points, (9, 65, 116, 235))
    for i in range(0, 28, 2):
        c.line(cx, cy, points[i][0], points[i][1], (47, 143, 211, 110), 3)
    for i in range(14):
        angle = i * math.tau / 14
        x = cx + math.cos(angle) * 92
        y = cy + math.sin(angle) * 50
        c.rect(int(x) - 2, int(y) - 2, int(x) + 2, int(y) + 2, (255, 220, 93, 160))
    c.save_png(OUT_DIR / "hit_burst.png")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    create_background()
    create_fish_sheet()
    create_hit_burst()
    print(f"generated assets in {OUT_DIR}")


if __name__ == "__main__":
    main()
