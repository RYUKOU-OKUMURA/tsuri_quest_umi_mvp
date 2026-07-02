# 20. ステータス画面 実装整理

Date: 2026-07-02

対象画面: `src/ui/status_screen.gd`

参照画像: `reference/08_status_screen_mockup.png`

この文書は、現行の簡易ステータス/図鑑画面を、完成イメージに沿った本番寄りステータス画面へ作り替えるための着手前整理である。作業手順は `skills/ui-screen-build/SKILL.md` と `docs/19_ui_production_playbook.md` を正とする。

## 現状

- `src/ui/status_screen.gd` は既に存在し、`main.gd` の `status` ルートから開ける。
- 現状は `make_header()` と汎用 `PanelContainer` を使った3ペイン構成で、プレイヤー情報、魚図鑑グリッド、所持品/料理記録を同一画面へ詰めている。
- `tools/status_preview.tscn` は存在し、`/tmp/tsuri_status.png` の固定スクショを出せる。
- `tools/build_screen_visual_comparison.py` には status 用 preset がまだ無い。
- `tools/status_visual_qa.sh` と status smoke test はまだ無い。

## 参照画像の解釈

参照画像は1状態のメニュー画面として扱う。料理選択や魚図鑑詳細など、複数状態を合成したモックではない。

ただし、参照画像には Lv/所持金が上部と左パネルに重複して見える。`docs/19` の「同一情報を同一画面に2箇所表示しない」を優先し、実装では次のように整理する。

- 上部ステータスバー: `Lv / 装備 / 所持金` のグローバル要約を担当する。
- 左プレイヤーパネル: EXP、能力値、装備詳細、船、次の食事効果を担当し、所持金は重複表示しない。

## 存在する領域

- 港背景が画面外周や隙間から見える。
- 画面全体を木枠/真鍮/濃紺帯で囲う大きな台帳フレームがある。
- 上部にタイトル `ステータス` と短い説明がある。
- 上部右に `PlayerStatusBar` 相当の `Lv / 装備 / 所持金` がある。
- 左にプレイヤーパネルがあり、能力値、装備、船、次の食事効果を読む。
- 中央に釣果サマリーがあり、発見済み魚種、釣果総数、最大サイズ、累計釣行回数、最近釣れた魚、図鑑コンプリート率を読む。
- 右に所持品・料理パネルがあり、クーラーボックス、所持している竿、料理/食事効果ログを読む。
- 下部に導線ボタンが並ぶ。主ボタンは `港へ戻る`、補助導線は `魚図鑑`、`料理・食事`、必要に応じて画面内の `装備・持ち物` フォーカス。

## 存在しない領域

- 全魚種を並べる大きな魚図鑑グリッド。魚図鑑は `fish_book` 独立画面へ移す。
- 料理選択、食事実行、レベルアップ演出。料理フローは `cooking` 側の責務にする。
- デバッグ用の自動保存メッセージを大きく出すフッター。
- 長文の所持品テキストだけをスクロールする構成。
- Webダッシュボード風の白い表や、汎用パネルだけの仮UI。

## 主操作と補助操作

主操作:

- `港へ戻る`: `ScreenBase.make_return_button()` を使い、画面内で最も強いボタンにする。

補助操作:

- `魚図鑑`: `navigate("fish_book")`
- `料理・食事`: `navigate("cooking")`
- `装備・持ち物`: v1では右パネルへ視線を誘導するだけに留める。専用装備画面を作る場合は別フェーズ。
- `手動セーブ`: 参照画像にないため、v1の主導線には入れない。残す場合は目立たない補助操作として扱う。

## データ表示

プレイヤー:

- `PlayerProgress.level`
- `PlayerProgress.exp`
- `PlayerProgress.exp_to_next_level()`
- `PlayerProgress.get_base_stats()`
- `PlayerProgress.equipped_rod_id`
- `PlayerProgress.owned_boats`
- `PlayerProgress.pending_buff`

釣果サマリー:

- `GameData.get_all_fish_ids()`
- `GameData.get_fish(fish_id)`
- `PlayerProgress.caught_counts`
- `PlayerProgress.best_sizes`
- `PlayerProgress.spot_caught_counts`

所持品・料理:

- `PlayerProgress.fish_count(fish_id)`
- `PlayerProgress.owned_rods`
- `PlayerProgress.owned_boats`
- `PlayerProgress.eaten_recipes`
- `GameData.get_rod()`
- `GameData.get_boat()`
- `GameData.get_recipe()`

## PNG素材とruntime描画の分担

PNG素材が担うもの:

- 画面外周の木枠/真鍮/濃紺フレーム
- パネル枠、羊皮紙面、見出しリボン、ボタン枠
- 汎用アイコン、魚ポートレート、料理アイコン、クーラーボックスなどの装飾素材

Godot runtime が担うもの:

- 日本語テキスト、数値、単位
- EXP/図鑑率などのゲージ塗り
- 所持数、釣果数、最大サイズ、装備中表示
- スクロール、選択、ボタン押下、画面遷移

日本語テキストはPNGへ焼き込まない。

## 共通キットと画面専用素材

共通キットから使うもの:

- `assets/showcase/common/status_bar_frame.png`
- `assets/showcase/common/action_button_frame.png`
- `assets/showcase/common/button_frame*.png`
- `assets/showcase/common/card_frame.png`
- `assets/showcase/common/card_selected_frame.png`
- `assets/showcase/common/detail_row_frame.png`
- `assets/showcase/common/parchment_card.png`
- `assets/showcase/common/status_icon_sheet.png`
- `assets/showcase/common/detail_icon_sheet.png`
- `assets/showcase/common/footer_icon_sheet.png`

ドメイン共有素材:

- 魚ポートレートは `assets/showcase/fish/` を使い、画面からは `FightFishAssets.card_portrait_path()` 経由で参照する。

必要なら画面専用に作るもの:

- `assets/showcase/status/status_bg.png`
- `assets/showcase/status/status_outer_frame.png`
- `assets/showcase/status/status_header_frame.png`
- `assets/showcase/status/status_section_ribbon.png`
- `assets/showcase/status/status_inventory_slot_frame.png`

画面専用素材を作る場合は、先に発注仕様を書き、採用/不採用を全画面比較で判断する。

## 実装順

1. `tools/build_screen_visual_comparison.py` に `status` preset を追加する。
2. `tools/status_visual_qa.sh` を追加し、`tools/status_preview.tscn` のスクショと参照画像の横並び比較を再生成できるようにする。
3. status smoke test を追加する。観点は、上部ステータスバー、3ペイン、魚図鑑導線、料理導線、港戻り、主要データ表示。
4. `status_screen.gd` を構成フェーズとして作り替える。まず共通キットと既存素材だけで、ヘッダー、3ペイン、下部導線を固定する。
5. 魚図鑑グリッドを撤去し、中央は釣果サマリーと最近釣れた魚カードにする。
6. 右パネルを長文テキストから、クーラーボックス、所持竿、料理ログの小カード/行構成へ変える。
7. 全Labelに `clip_text` と `text_overrun_behavior` を設定し、通常データで省略が出ない幅にする。
8. `tools/status_visual_qa.sh` で参照横並びを見て、P1/P2/P3に分類して修正する。
9. 共通キットだけで質感が足りない箇所が残った場合だけ、status 専用素材フェーズへ進む。
10. `./tools/validate_project.sh` と status smoke を通し、採用値を画面別QAログへ残す。

## v1完了条件

- `reference/08_status_screen_mockup.png` と同じ読み順になっている。
- 1280x720実スクショで、主要テキストの見切れ、重なり、省略がない。
- 魚図鑑全量表示が消え、釣果サマリーと `fish_book` 導線に整理されている。
- 所持品/料理記録が、長文テキストではなく行/カードで読める。
- `港へ戻る` が主操作として最も目立つ。
- `tools/status_visual_qa.sh` が参照横並びを再生成できる。
- status smoke と `./tools/validate_project.sh` が通る。
