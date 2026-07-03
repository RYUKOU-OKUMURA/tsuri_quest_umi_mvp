# 魚図鑑画面 QA判断ログ

最終更新: 2026-07-03 / 状態: **v1.8 P2カード/詳細紙面素材合格・freeze中**
参照画像: `reference/07_fish_book_mockup.png`
QA更新コマンド: `./tools/fish_book_visual_qa.sh`

## 1. freeze値（正本）

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 右上ステータスバー | `PlayerStatusBar` のスロット配分を所持金優先 | `src/ui/components/`（PlayerStatusBar） | P1だった所持金省略の解消 |
| 竿名表記 | 短縮形（`港の入門竿`→`入門竿`、`外海竿・青嵐`→`青嵐`） | データ表示側 | ステータスバー内の収まり |
| カード内レアリティチップ | 幅 0.060–0.438 | `src/ui/fish_book_screen.gd` | `アンコモン` の省略解消 |
| 長い魚名 | カード/詳細で段階的にフォントサイズを落とす | 同上 | 省略ではなく縮小で収める採用値 |
| 背景スクリム | alpha 0.42 | 同上 | docs/19 §4.5（スクリム減光型） |
| 木色バックプレート | 0.024/0.118–0.976/0.982 | 同上 | 分離パネルから「一冊の台帳」への寄せ |
| 内側ウェル | 0.031/0.135–0.969/0.970 | 同上 | 同上 |
| 魚ポートレート表示 | 透明余白をalpha bboxで実表示クロップ。左カードは clip 0.055/0.165–0.945/0.670、右詳細は clip 0.095/0.175–0.915/0.490 | `src/ui/fish_book_screen.gd` | 魚画像が紙窓・カード情報帯・レアリティチップへ食い込むP1を解消 |
| 台帳外周フレーム | `fish_book_book_frame.png` を 0.018/0.018–0.982/0.982 に配置。ヘッダー/フッターの全面濃紺フレームは外し、ステータス/ボタンを木製レール上に載せる | `assets/showcase/fish_book/`, `src/ui/fish_book_screen.gd` | 画面全体を分離パネル群ではなく一冊の木製台帳として読ませる |
| カード/詳細紙面素材 | 通常/選択/未発見カードに `fish_book_card_frame.png` / `fish_book_card_selected_frame.png` / `fish_book_card_locked_frame.png`、右詳細下地に `fish_book_detail_paper.png` を使用。カード内のruntime文字領域へ焼き込み罫線を入れない | `assets/showcase/fish_book/`, `src/ui/fish_book_screen.gd` | 汎用カード・runtime塗り紙面から、魚図鑑専用の収集カード/羊皮紙ページへ寄せる |

## 2. 不採用・再試行禁止リスト

| 案 | 却下理由 | 判断日 |
|---|---|---|
| 2026-06時点での新規PNG生成 | 構成・文字収まり・スクリムのみで v1.5 目標を達成できたため、その時点では生成に着手せず | 2026-06 |

## 3. 微調整カウンタ

| パラメータ | 回数 | 直近の変更内容 | 状態 |
|---|---|---|---|
| 魚ポートレート表示枠 | 1 | alpha bboxクロップ＋clipコンテナ化 | P1解消としてfreeze |
| カード/詳細紙面の焼き込み線 | 1 | 初回候補の罫線・傷線がruntime文字に近かったため、端の紙質表現だけに削減 | P2紙面素材としてfreeze |

## 4. 暫定判定・再検証TODO

なし。直近の判断根拠は `docs/qa/evidence/fish_book/2026-07-03_paper_assets_compare.png` に保存済み。

## 5. 現在の残ギャップ

- **P2**: 魚ポートレート素材そのものの描き起こし・魚ごとの見せ方、フォント全体方針、左一覧面の暗色ウェルとカード密度の参照寄せは未着手。次に品質を上げる場合は1フェーズだけ選び、contact sheet → 全画面比較で判定する。
- 文字収まりの採用値（レアリティチップ幅・段階的フォント縮小）を、P1再発なしに動かさないこと。

## 6. フェーズスコープ宣言（作業中のみ）

（現在作業中のフェーズなし）

## 7. 判断ログ（直近パスのみ）

- 2026-07-03: v1.8 P2カード/詳細紙面素材フェーズ。`docs/23_fish_book_card_paper_asset_brief.md` に従い、`tools/generate_fish_book_paper_assets.py` で通常/選択/未発見カード枠と右詳細ページ紙面を生成。カード内のruntime文字領域へ焼き込み罫線を置かず、端の紙質・角飾り・選択金縁で「収集カード」として読ませる方向へ寄せた。`./tools/fish_book_visual_qa.sh` の横並び比較で、旧汎用カードより左一覧と右詳細が同じ台帳内の紙面としてつながり、P1（文字見切れ・魚画像はみ出し・素材未表示）の再発もないため採用。判断根拠: `docs/qa/evidence/fish_book/2026-07-03_paper_assets_compare.png`。検証: `./tools/validate_project.sh` exit 0（Godot終了時のObjectDB/resource警告あり）、`fish_book_smoke: ok`。
