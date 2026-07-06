# V2 / E7. 難易度選択

正本: `docs/30_v2_expansion_overview.md`（読む順: docs/30 §4 共通仕様 → 本doc）
前提フェーズ: E1〜E4（環の完成後のポリッシュ枠）
状態: 仕様確定・未着手

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

- `title_screen.gd`: 「はじめから」押下時に3択パネルを重ねる（既存タイトルレイアウトの上のモーダル。タイトル自体の配置は動かさない）。選択→`reset_game(difficulty_id)` へ引数追加
- 既存セーブはロード補完で `"normal"`（docs/30 §4-1）
- タイトルのfreeze記録は `docs/qa/` に現状ファイルがないため、実装後スクショ比較を行い必要なら `docs/qa/title_qa.md` を新設
- ステータス画面のヘッダー付近に現在難易度を小さく表示

## E7-4. 触ってよいファイル / DoD

- 触る: `game_catalog_data.gd`, `player_progress.gd`, `title_screen.gd`, `fishing_screen.gd`, `status_screen.gd`, `tools/difficulty_fight_audit.tscn`（新設）
- DoD: `difficulty_fight_audit`（3難易度で safe帯幅・スタミナ・売値・経験値の実効値を表出力）+ `save_system_verify.sh`（旧セーブ→normal補完）+ タイトルvisual QA + validate green
