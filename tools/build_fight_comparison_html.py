#!/usr/bin/env python3
"""Build a local side-by-side visual QA page for the underwater fight screen."""

from __future__ import annotations

from html import escape
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REFERENCE = ROOT / "reference" / "02_underwater_fight_mockup.png"
CAPTURE = Path("/tmp/tsuri_fishing_fight.png")
OUT = Path("/tmp/tsuri_fight_compare.html")


def file_url(path: Path) -> str:
    return path.resolve().as_uri()


def main() -> int:
    missing = [str(path) for path in (REFERENCE, CAPTURE) if not path.exists()]
    if missing:
        print("Missing required image(s):")
        for path in missing:
            print(f"  - {path}")
        return 1

    html = f"""<!doctype html>
<html lang="ja">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Underwater Fight Visual QA</title>
  <style>
    :root {{
      color-scheme: dark;
      --bg: #07111d;
      --panel: #101c2b;
      --line: #314860;
      --text: #edf6ff;
      --muted: #9fb2c4;
      --accent: #f0c76b;
    }}
    * {{ box-sizing: border-box; }}
    body {{
      margin: 0;
      background: var(--bg);
      color: var(--text);
      font-family: -apple-system, BlinkMacSystemFont, "Hiragino Sans", "Yu Gothic", sans-serif;
    }}
    header {{
      padding: 16px 20px 8px;
      border-bottom: 1px solid var(--line);
    }}
    h1 {{
      margin: 0 0 6px;
      font-size: 18px;
      font-weight: 700;
      letter-spacing: 0;
    }}
    p {{
      margin: 0;
      color: var(--muted);
      font-size: 13px;
      line-height: 1.5;
    }}
    main {{
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 14px;
      padding: 14px;
    }}
    figure {{
      margin: 0;
      background: var(--panel);
      border: 1px solid var(--line);
      border-radius: 6px;
      overflow: hidden;
      min-width: 0;
    }}
    figcaption {{
      display: flex;
      justify-content: space-between;
      gap: 12px;
      padding: 10px 12px;
      border-bottom: 1px solid var(--line);
      color: var(--accent);
      font-size: 13px;
      font-weight: 700;
    }}
    .path {{
      color: var(--muted);
      font-weight: 500;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }}
    img {{
      display: block;
      width: 100%;
      height: auto;
      image-rendering: auto;
      background: #000;
    }}
    @media (max-width: 1100px) {{
      main {{ grid-template-columns: 1fr; }}
    }}
  </style>
</head>
<body>
  <header>
    <h1>Underwater Fight Visual QA</h1>
    <p>Judge density, spacing, palette, fish presence, and UI frame quality side by side.</p>
  </header>
  <main>
    <figure>
      <figcaption><span>Reference</span><span class="path">{escape(str(REFERENCE))}</span></figcaption>
      <img alt="reference underwater fight mockup" src="{file_url(REFERENCE)}">
    </figure>
    <figure>
      <figcaption><span>Current Capture</span><span class="path">{escape(str(CAPTURE))}</span></figcaption>
      <img alt="current underwater fight capture" src="{file_url(CAPTURE)}">
    </figure>
  </main>
</body>
</html>
"""
    OUT.write_text(html, encoding="utf-8")
    print(OUT)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
