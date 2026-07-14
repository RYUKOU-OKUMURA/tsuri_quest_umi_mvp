# 34. サメの生簀画面 v1 実装仕様

Date: 2026-07-07（2026-07-13 水槽背景採用同期）
対象: `src/ui/shark_pen_screen.gd`
参照画像: `reference/12_shark_pen_mockup.png`
根拠: `docs/30_v2_expansion_overview.md` / `docs/v2/E10_shark_raising.md` / `docs/19_ui_production_playbook.md`
水槽背景uplift: `docs/48_shark_pen_tank_uplift_spec.md`

## 1. 参照画像の分解

`reference/12_shark_pen_mockup.png` は、E10 v1用の**1状態の構成参照**。給餌後演出やメガロドン最終演出を合成したものではない。

### 存在する領域

| 領域 | 役割 | 実装方針 |
|---|---|---|
| 上部ヘッダー | 画面名・短い説明・`PlayerStatusBar` | 共通ステータスバーを右側に配置。Lv/装備/所持金の重複表示は禁止 |
| 左メイン水槽 | 捕獲済みサメのコレクション感を見せる | `FightFishAssets` の `showcase_sheet` を流用。参照画像もsheet第1フレーム基準。未捕獲はシルエット/非表示で扱う |
| 右サメ選択列 | 9種＋メガロドンの10枠、なつき度ゲージ、完全成長状態 | 固定10行。行ごとの金縁過多は避け、選択行のみ紙面ハイライト |
| 下部餌やりパネル | インベントリ魚一覧、好物表示、獲得EXP/なつき度予告、主操作「あたえる」 | 一覧は実データから構築。好物は `GameData.is_favorite_food()` で判定 |
| 右下戻るボタン | 港へ戻る | `ScreenBase.make_return_button()` を使い、右下規約に合わせる |

### 存在しない領域

- 市場売却・料理・図鑑の詳細一覧はこの画面に入れない
- サメの詳細ステータス（stamina/power/speed）の全表は入れない
- 1日あたり給餌回数やタイマーは入れない
- Lv/所持金をヘッダー以外に再掲しない
- 日本語テキストをPNG素材に焼き込まない

### 参照に在るが採用しない/調整する要素

| 要素 | 判断 |
|---|---|
| 参照画像内の文字入りパネル | 製品ではすべてGodot runtime描画。参照画像は構成確認用 |
| 餌一覧の王冠アイコン | v1ではruntime描画の小チップで代替。専用PNG王冠はv2候補 |
| 水槽背景の質感 | `assets/showcase/shark_pen/tank_environment_bg.png` を採用済み。素材欠落時だけruntimeグラデーションへfallbackし、旧runtime直線3本は撤去 |
| メガロドン最終演出 | E10本体の到達演出候補として残し、v1画面には常時表示しない |

## 2. 主操作と補助操作

- 主操作: 選択中のサメへ選択中の魚を「あたえる」
- 補助操作: サメ選択、餌魚選択、港へ戻る
- フィードバック: 給餌結果メッセージ、なつき度ゲージ更新、EXP獲得表示、100到達時の完全成長表示

## 3. PNG素材とruntime描画の分担

| 種別 | 担当 |
|---|---|
| PNG素材 | 共通フレーム/ボタン/カード、魚素材（`assets/showcase/fish/*_showcase_sheet.png` / `*_card_portrait.png`）、画面専用水槽背景 `tank_environment_bg.png` |
| runtime描画 | サメ選択行、ゲージ、好物チップ、数値、メッセージ。水槽背景欠落時のみgradient fallback |
| 新規PNG | `megalodon_card_portrait.png` / `megalodon_showcase_sheet.png`、`assets/showcase/shark_pen/tank_environment_bg.png` |
| v2送り | 専用王冠/完全成長バッジ、全サメが揃って泳ぐ最終演出 |

## 4. smoke観点

`tools/shark_pen_screen_smoke.tscn` で以下を固定する。

- `SharkPenScreen` が10枠のサメ選択列を持つ
- 捕獲済みサメは選択可能、未捕獲サメはロック/未捕獲表示になる
- インベントリの `shark:true` 魚は餌一覧に出ない
- 好物魚が選択されると「あたえる」実行で `PlayerProgress.feed_shark()` が成功し、在庫・EXP・なつき度が増える
- 在庫0/未捕獲サメ/サメを餌にするケースは失敗表示になり、状態を壊さない
- `港へ戻る` が `harbor` へ遷移要求を出す

## 5. visual QA

- QAコマンド: `./tools/shark_pen_visual_qa.sh`
- 出力:
  - `/tmp/tsuri_shark_pen.png`
  - `/tmp/tsuri_shark_pen_selected_hover.png`
  - `/tmp/tsuri_shark_pen_compare.png`
  - `/tmp/tsuri_shark_pen_selected_hover_compare.png`
- 採用判断の証拠画像は `docs/qa/evidence/shark_pen/` へコピーする

## 6. v1完了条件

- `docs/19` §2.1 のv1条件を満たす
- `tools/shark_pen_screen_smoke.tscn`、`tools/shark_pen_smoke.tscn`、`tools/shark_lure_audit.tscn`、`./tools/validate_project.sh` がgreen
- `docs/qa/shark_pen_qa.md` にfreeze値と残ギャップを記録する
