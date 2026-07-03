# 魚図鑑 カード/詳細紙面素材ブリーフ

Date: 2026-07-03

対象画面: `src/ui/fish_book_screen.gd`
参照画像: `reference/07_fish_book_mockup.png`
出力素材:

- `assets/showcase/fish_book/fish_book_card_frame.png`
- `assets/showcase/fish_book/fish_book_card_selected_frame.png`
- `assets/showcase/fish_book/fish_book_card_locked_frame.png`
- `assets/showcase/fish_book/fish_book_detail_paper.png`

生成スクリプト: `tools/generate_fish_book_paper_assets.py`

## 目的

台帳外周に対して、左カードと右詳細ページがまだruntime塗りの紙面に見える差を埋める。魚カードは「集めた魚の記録カード」、右詳細は「台帳の羊皮紙ページ」として見せる。

## 今回動かす範囲

- 魚カードの通常/選択/未発見フレーム
- 右詳細ページの下地紙面

## 今回動かさない範囲

- 魚ポートレートPNGそのもの
- 魚カードのサイズ、列数、スクロール領域
- レアリティチップ幅、長い魚名フォント縮小
- 詳細ページ内のテキスト座標、釣果/サイズ/生息地/好物/行動の情報設計
- 台帳外周フレーム

## 必要条件

- 素材に日本語、魚名、数値、レアリティ文言を焼き込まない。
- 1280x720実スクショで、カード枠が共通汎用カードではなく魚図鑑内の収集カードに見える。
- 選択カードは参照のように明るい金縁で主役化する。
- 未発見カードは暗い伏せ表示として成立し、空欄や壊れたカードに見えない。
- 右詳細ページは一枚の羊皮紙に見え、外周台帳と質感がつながる。
- 既存の文字収まり、魚画像収まり、フィルタ操作を壊さない。

## 不採用条件

- 行レベルの金縁フレームや過剰な飾りで装飾階層が崩れる。
- カード枠が濃すぎて魚や文字より目立つ。
- 詳細ページの焼き込み罫線がruntime文字や魚ポートレートと衝突する。
- 参照比較で、現行より平たい、または視認性が落ちる。

## 判定方法

`./tools/fish_book_visual_qa.sh` を実行し、`/tmp/tsuri_fish_book_compare.png` で参照画像と横並び比較する。採用判断の証拠は `docs/qa/evidence/fish_book/` へ保存する。
