# V2 / E7. 難易度選択

正本: `docs/30_v2_expansion_overview.md`（読む順: docs/30 §4 共通仕様 → 本doc）
前提フェーズ: E1〜E4（環の完成後のポリッシュ枠）
状態: 未着手。進行状況はdocs/30 §6、発売前の追加監査事項はdocs/45を参照

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
- 空スロットは難易度選択後に開始。使用済みスロットは、選択難易度と上書き対象slotを示す最終確認を1回以上行い、docs/01 FR-001「確認後に初期化」を維持する。他スロットは変更しない
- slot番号・Lv・プレイ時間・不可逆警告・安全なcancel focusまで表示する強化案と、確認を二段階にする案はP2提案。採用する場合はモックをユーザー確認し、docs/45 TITLE-03とtitle QAへ決定を記録する
- resetと初回saveが成功してから港へ遷移する。保存失敗時はslotを開始済み扱いにせず、E11の共通通知契約へ接続する
- 既存セーブはロード補完で `"normal"`（docs/30 §4-1）
- `docs/qa/title_qa.md` とruntime title visual QAを新設する。旧 `tools/build_title_static_preview.py` だけを合否根拠にしない
- ステータス画面のヘッダー付近に現在難易度を小さく表示

## E7-4. 触ってよいファイル / DoD

- 触る: `game_catalog_data.gd`, `player_progress.gd`, `title_screen.gd`, `fishing_screen.gd`, `status_screen.gd`, `tools/difficulty_fight_audit.tscn`（新設）, runtime title visual QA（新設）, `docs/qa/title_qa.md`（新設）
- DoD:
  1. `difficulty_fight_audit`: 3難易度で safe帯幅・スタミナ・売値・経験値の実効値を表出力
  2. `save_system_verify.sh`: 旧セーブ→normal補完、選択slotだけ変更、他2slot不変
  3. 空slot開始、使用済みslotでcancel、使用済みslotの確認後開始、保存失敗時非遷移。他slot不変
  4. タイトルruntime visual QA: empty / occupied / 3slot / difficulty / overwrite確認
  5. validate green
