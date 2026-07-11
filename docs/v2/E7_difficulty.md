# V2 / E7. 難易度選択

正本: `docs/30_v2_expansion_overview.md`（読む順: docs/30 §4 共通仕様 → 本doc）
前提フェーズ: E0〜E6・E10・Release Gate 1（SAVE-01〜04）。環と発売対象機能の完成後のポリッシュ枠
状態: 完了（2026-07-12。E7-core → E7-fight → E7-UIの順でmainへ統合し、全DoDを同一commit系列で再検証）。進行状況はdocs/30 §6、発売前の追加監査事項はdocs/45を参照

決定#3: **新しいセーブデータの開始時のみ選択・変更不可**。既存セーブはロード補完で「ふつう」。

## E7-1. 倍率テーブル（`game_catalog_data.gd` に `DIFFICULTIES`）

| id | 名称 | safe_min shift | safe_max shift | line_break倍率 | 魚スタミナ倍率 | 売値倍率 | 経験値倍率 |
|---|---|---|---|---|---|---|---|
| easy | やさしい | -0.04 | +0.05 | ×1.15 | ×0.85 | ×1.00 | ×1.00 |
| normal | ふつう | 0 | 0 | ×1.00 | ×1.00 | ×1.00 | ×1.00 |
| hard | むずかしい | +0.02 | -0.04 | ×0.95 | ×1.25 | ×1.25 | ×1.25 |

「むずかしい」の売値・経験値ボーナスが採用条件（選ぶ理由を作る）。

## E7-2. 適用点（ロジック側は難易度IDを参照するだけ）

- `get_base_stats()`: safe_min/max shift と line_break倍率を適用
- ファイト開始時: 魚データの `stamina` に倍率（`fishing_screen.gd` が simulator へ渡す前に乗算）
- `sell_fish` / `sell_fish_batch`: income に売値倍率（丸めは int）
- `cook_and_eat`: `total_exp` に経験値倍率（E10の餌やり経験値にも適用する）
- ヘルパ `PlayerProgress.difficulty() -> Dictionary` を1つ作り、各所はそれを読む

## E7-3. 選択UI（新規セーブ開始時のみ）

- 前提: docs/30 Release Gate 1（docs/45 SAVE-01〜04）が完了していること。係数を含めE7をGate 1と並列化しない。タイトル開始導線はSAVE-02の保存結果契約へ接続する
- `title_screen.gd`: 現在選択中のセーブスロットに対し、「はじめから」押下時に3択パネルを重ねる（既存タイトルレイアウトの上のモーダル。タイトル自体の配置は動かさない）。選択→確認→`reset_game(difficulty_id)` へ引数追加
- 空スロットは難易度選択後に開始。使用済みスロットは、難易度選択後に**最終確認を1回だけ**行い、docs/01 FR-001「確認後に初期化」を維持する。確認にはslot番号・Lv・プレイ時間・選択難易度・取り消せない旨を表示し、初期focusはcancelへ置く。他スロットは変更しない
- 二段階確認は採用しない。確認段数と表示項目をtitle QAへ確定値として記録する
- resetと初回saveが成功してから港へ遷移する。保存失敗時はslotを開始済み扱いにせず、SAVE-02で実装済みの共通通知契約へ接続する
- 既存セーブはロード補完で `"normal"`（docs/30 §4-1）
- ID-01で新設済みの `docs/qa/title_qa.md` とruntime title visual QAへ、empty / occupied / 3slot / difficulty / overwrite確認状態を追加する。旧 `tools/build_title_static_preview.py` だけを合否根拠にしない
- ステータス画面のヘッダー付近に現在難易度を小さく表示

## E7-4. 並列スライス

| スライス | 単一owner | 内容 |
|---|---|---|
| E7-core | `game_catalog_data.gd`、`game_data.gd`、`player_progress.gd`、`cooking_screen.gd` / `shark_pen_screen.gd`のEXPプレビュー、`difficulty_fight_audit.*`の基礎 | `difficulty_id`、倍率表と公開alias、safe帯・line break、売却・料理・サメ餌やりEXP、プレビューと実値の一致、save契約と監査。`player_progress.gd`を触る唯一のスライス |
| E7-fight | `fishing_screen.gd`、`difficulty_fight_audit.*`の実経路assertion | 魚スタミナ倍率をsimulatorへ渡す実ファイト経路へ接続し、coreが作った理論値監査を実経路まで延長 |
| E7-UI | `title_screen.gd`、`status_screen.gd`、`save_system_smoke.gd`のタイトル導線回帰、title preview / visual QA / QA文書 | 新規ゲーム導線、1回の上書き確認、難易度表示 |

E7-coreのAPIを先に統合し、そのcommitを基点にE7-fightとE7-UIを並列化する。統合順はcore→fight→UIとし、最終的に全DoDを同じcommit系列で再検証する。

完了記録（2026-07-12）: 上記順でmainへ統合。`difficulty_fight_audit`、`save_system_verify.sh`、title/status runtime visual QA、`status_smoke`、`validate_project.sh`、release verifyを通過し、各スライスと統合差分の独立レビューでP0/P1/P2なし。

## E7-5. 触ってよいファイル / DoD

- 触る: `game_catalog_data.gd`, `game_data.gd`, `player_progress.gd`, `cooking_screen.gd`, `shark_pen_screen.gd`, `title_screen.gd`, `fishing_screen.gd`, `status_screen.gd`, `tools/difficulty_fight_audit.gd` / `.tscn`（新設）, `tools/title_preview.gd` / `.tscn`, `tools/title_visual_qa.sh`, `docs/qa/title_qa.md`
- DoD:
  1. `difficulty_fight_audit`: 3難易度で safe帯幅・スタミナ・売値・料理EXP・E10サメ餌やりEXPの実効値を表出力
  2. `save_system_verify.sh`: 旧セーブ→normal補完、選択slotだけ変更、他2slot不変
  3. 空slot開始、使用済みslotの1回確認でslot番号・Lv・プレイ時間・難易度・不可逆警告を表示、cancel初期focus、確認後開始、保存失敗時非遷移。他slot不変
  4. タイトルruntime visual QA: empty / occupied / 3slot / difficulty / overwrite確認
  5. validate green
