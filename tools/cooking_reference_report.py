#!/usr/bin/env python3
"""Build a local HTML contact sheet for cooking reference QA.

The Godot preview writes state screenshots to /tmp when run with a real display
driver. This report puts those captures beside the five positive references so
the remaining visual QA can be done without hand-assembling files.
"""

from __future__ import annotations

from html import escape
from pathlib import Path
from urllib.parse import quote


ROOT = Path(__file__).resolve().parents[1]
OUT = Path("/tmp/tsuri_cooking_reference_report.html")

STATES = [
    {
        "id": "COOK_SELECT",
        "reference": ROOT / "reference/cooking_flow/01_cook_select_concept.png",
        "capture": Path("/tmp/tsuri_cooking_select.png"),
        "focus": "3カラム構成、魚行、3x2料理カード、右詳細、下部ステータス帯",
    },
    {
        "id": "MEAL_RESULT",
        "reference": ROOT / "reference/cooking_flow/02_meal_result_concept.png",
        "capture": Path("/tmp/tsuri_cooking_result.png"),
        "focus": "食事シーン、食べたバナー、料理カード、4報酬カード、下部ステータス帯",
    },
    {
        "id": "EXP_GAIN",
        "reference": ROOT / "reference/cooking_flow/03_exp_gain_concept.png",
        "capture": Path("/tmp/tsuri_cooking_exp.png"),
        "focus": "+EXP、EXPゲージ、放射バースト、左料理カード、右効果カード",
    },
    {
        "id": "LEVEL_UP_OVERLAY",
        "reference": ROOT / "reference/cooking_flow/04_level_up_overlay_concept.png",
        "capture": Path("/tmp/tsuri_cooking_levelup.png"),
        "focus": "中央LEVEL UP、Lv遷移、能力上昇、赤リボン、ぬし/釣り場解放",
    },
    {
        "id": "STATUS_SUMMARY",
        "reference": ROOT / "reference/cooking_flow/05_status_summary_concept.png",
        "capture": Path("/tmp/tsuri_cooking_status.png"),
        "focus": "5カード、ヘッダーEXP、効果中料理、下部メッセージ、港へ戻る導線",
    },
]


def file_url(path: Path) -> str:
    return "file://" + quote(str(path))


def image_cell(path: Path, label: str) -> str:
    if not path.exists():
        return (
            '<div class="missing">'
            f"<strong>{escape(label)}</strong><br>"
            f"Missing: <code>{escape(str(path))}</code>"
            "</div>"
        )
    return (
        f'<figure><img src="{file_url(path)}" alt="{escape(label)}">'
        f"<figcaption>{escape(label)}<br><code>{escape(str(path))}</code></figcaption></figure>"
    )


def build_html() -> str:
    state_sections = []
    missing = 0
    for state in STATES:
        if not state["capture"].exists():
            missing += 1
        state_sections.append(
            f"""
            <section>
              <h2>{escape(state["id"])}</h2>
              <p class="focus">Focus: {escape(state["focus"])}</p>
              <div class="pair">
                {image_cell(state["reference"], "Reference")}
                {image_cell(state["capture"], "Current Capture")}
              </div>
            </section>
            """
        )
    status = (
        "All captures found. Review each pair against the focus notes."
        if missing == 0
        else f"{missing} capture(s) missing. Run tools/cooking_preview.gd with a real display driver first."
    )
    return f"""<!doctype html>
<html lang="ja">
<head>
  <meta charset="utf-8">
  <title>Tsuri Cooking Reference QA</title>
  <style>
    body {{
      margin: 0;
      background: #10151d;
      color: #f4ead1;
      font-family: -apple-system, BlinkMacSystemFont, "Hiragino Sans", sans-serif;
    }}
    header {{
      position: sticky;
      top: 0;
      z-index: 1;
      padding: 18px 24px;
      background: #13243a;
      border-bottom: 2px solid #c79545;
    }}
    h1, h2, p {{
      margin: 0;
    }}
    .status {{
      margin-top: 8px;
      color: #ffd980;
    }}
    main {{
      padding: 22px;
    }}
    section {{
      margin-bottom: 34px;
      padding: 18px;
      background: #172130;
      border: 1px solid #5f4424;
    }}
    h2 {{
      margin-bottom: 8px;
      color: #ffd980;
    }}
    .focus {{
      margin-bottom: 14px;
      color: #d8c8a8;
    }}
    .pair {{
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
      align-items: start;
    }}
    figure {{
      margin: 0;
    }}
    img {{
      display: block;
      width: 100%;
      background: #0b0e14;
      border: 1px solid #7a5a2a;
    }}
    figcaption, .missing {{
      margin-top: 8px;
      color: #d8c8a8;
      font-size: 13px;
      line-height: 1.45;
    }}
    code {{
      color: #9fe8ff;
    }}
    .missing {{
      min-height: 260px;
      padding: 24px;
      background: #261922;
      border: 1px dashed #c76b6b;
    }}
  </style>
</head>
<body>
  <header>
    <h1>Tsuri Cooking Reference QA</h1>
    <p class="status">{escape(status)}</p>
  </header>
  <main>
    {''.join(state_sections)}
  </main>
</body>
</html>
"""


def main() -> int:
    OUT.write_text(build_html(), encoding="utf-8")
    print(OUT)
    for state in STATES:
        capture = state["capture"]
        if not capture.exists():
            print(f"missing {state['id']}: {capture}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
