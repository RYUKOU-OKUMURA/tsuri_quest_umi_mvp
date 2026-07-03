# 魚図鑑 専用魚ポートレート素材ブリーフ

Date: 2026-07-03

対象画面: `src/ui/fish_book_screen.gd`
参照画像: `reference/07_fish_book_mockup.png`
評価ツール: `tools/build_fish_book_portrait_contact_sheet.py`
QA正本: `docs/qa/fish_book_qa.md`

## 目的

魚図鑑を「ゲーム内に置かれた一冊の釣り図鑑」として仕上げるため、既存の水中ファイト兼用魚素材を、図鑑カード/詳細ページで主役になる専用ポートレートへ引き上げる。

現状のUI側では、魚の枠内収まり、紙面なじませ、標本窓、未発見カード、台帳外周、索引導線は合格済み。残っている差分は、参照画像にある魚イラストの密度、手描き感、紙面上の存在感であり、座標や明度の微調整で埋めない。

## 今回動かす範囲

- 魚図鑑で表示する魚ポートレートの元アート候補
- 候補の正規化処理
- `assets/showcase/fish/*_showcase_sheet.png`
- `assets/showcase/fish/*_card_portrait.png`
- `tools/build_fish_book_portrait_contact_sheet.py` と `./tools/fish_book_visual_qa.sh` による採用判定

## 今回動かさない範囲

- 左カードサイズ、列数、スクロール領域
- 左カードの魚clip座標、魚cropパラメータ、レアリティチップ幅、魚名フォント縮小
- 右詳細の魚clip座標、釣果/最大欄、説明行、釣り場カード
- 台帳外周フレーム、中央綴じ目、下部索引タブ、戻るボタン
- 日本語テキストや数値のPNG焼き込み

## 優先順

最初の素材パスは、ファーストビューで品質差が最も見える魚だけに絞る。

1. `aji` / `saba` / `kasago`
2. `madai` / `hirame` / `shirogisu` / `mebaru`
3. 未発見カードのシルエット代表に使う魚種
4. 残りの全魚

1パスで全30魚を差し替えない。まず1〜3魚で候補を作り、contact sheetと全画面比較で現行に明確に勝つことを確認してから拡張する。

## 素材条件

- 透明背景の魚単体。紙背景、カード枠、罫線、ラベル、名前、No.、レアリティ文言を含めない。
- 図鑑カードでは左向きに見えること。元素材が右向きでもパイプラインで左右反転できるが、目や口の情報が潰れない向きを優先する。
- 参照画像のように、鱗、目、ヒレ、腹の陰影、尾びれの形が1280x720のカードサイズでも読める。
- リアル写真ではなく、ゲーム内の手描き図鑑イラストとして見えること。
- 魚種の識別特徴を優先する。色違いだけで別魚に見える候補は不採用。
- 魚の外周に白フチ、青ハロ、黒い矩形背景、生成時の余白線を残さない。
- 水中ファイト素材との一貫性を壊さない。必要なら `tools/process_underwater_fish_assets.py` の正規化処理を通し、図鑑側でだけ浮かない色味へ寄せる。

## 候補の置き場所

候補素材は直接 `assets/showcase/fish/` へ置かない。

- 単体候補: `tools/source_assets/fish/<fish_id>_final_art_source.png`
- 複数候補の比較用: `tools/source_assets/fish/fish_book_<date>_contact_sheet.png`

採用時だけ、既存パイプラインで `assets/showcase/fish/<fish_id>_showcase_sheet.png` と `<fish_id>_card_portrait.png` を再生成する。

## 評価手順

1. 候補を `tools/source_assets/fish/` に置く。
2. 既存の魚素材生成パイプラインで対象魚の `showcase_sheet` / `card_portrait` 候補を作る。
3. `python3 tools/build_fish_book_portrait_contact_sheet.py --out /tmp/tsuri_fish_book_portrait_contact_sheet.png` を実行する。
4. contact sheetで、参照カード/参照詳細魚、現行カードcrop、現行詳細crop、候補を比較する。
5. 候補を仮適用した状態で `./tools/fish_book_visual_qa.sh` を実行する。
6. `/tmp/tsuri_fish_book_compare.png` の全画面比較で、現行より明確に勝つ場合だけ採用する。
7. 採用/不採用を `docs/qa/fish_book_qa.md` に記録し、証拠画像を `docs/qa/evidence/fish_book/` へ保存する。

## 採用条件

- 左一覧カードで、魚が同じ写真枠内に収まりつつ、参照に近い主役感が増している。
- 右詳細ページで、魚が大きな標本画として読める。
- 釣果、最大サイズ、レアリティチップ、魚名へ干渉しない。
- 未発見カードやフィルタ導線の情報階層を壊さない。
- 1280x720の実スクショで、魚種ごとの差が明確に読める。
- contact sheet単体ではなく、全画面比較で現行に勝っている。

## 不採用条件

- 魚が写真風、写実素材、または別ゲームのカード素材に見える。
- 透明境界のハロ、白フチ、黒い影が目立つ。
- 魚の存在感は増えたが、カード内の文字や釣果行が読みにくくなる。
- 1魚だけ良くなり、同じ画面内の魚素材の文法が揃わない。
- 現行との差が小さく、好みの範囲に留まる。

## 現時点の判断

2026-07-03時点では、既存 `card_portrait` への単純差し替えは全画面で明確に勝つ根拠が弱い。次の実作業は、座標調整ではなく、上記条件を満たす専用魚アート候補を作り、contact sheetから全画面比較へ進める。
