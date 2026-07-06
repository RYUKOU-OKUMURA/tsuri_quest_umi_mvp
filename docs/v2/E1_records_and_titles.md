# V2 / E1. 記録更新演出＋称号

正本: `docs/30_v2_expansion_overview.md`（読む順: docs/30 §4 共通仕様 → 本doc）
前提フェーズ: なし
状態: 仕様確定・未着手

目的: 「前より大きいのが釣れた」を確実に気持ちよくする。他フェーズの成果（ヌシ捕獲・依頼達成・サメ飼育）を称号が受け止める土台。

## E1-1. `record_catch()` の戻り値拡張

`src/autoload/player_progress.gd:112` の `catch_result` に3キーを追加する。**`best_sizes` を上書きする前に旧値を取ること**（現在は L129 で即上書きしている）。

```gdscript
var previous_best := float(best_sizes.get(fish_id, 0.0))
var catch_result := {
    "fish_id": fish_id,
    "first_catch": previous_count <= 0,
    "boss_first_clear_reward": {},
    "record_broken": previous_count > 0 and size_cm > previous_best,  # 追加
    "previous_best_cm": previous_best,                                 # 追加
    "new_titles": [],                                                  # 追加（称号判定で埋める）
}
```

初回捕獲（`first_catch`）は `record_broken` を **true にしない**（初回は「図鑑登録」演出が担当。二重に祝わない）。

## E1-2. 称号アーキテクチャ

- 称号カタログは `game_catalog_data.gd` に `const TITLES: Array[Dictionary]`
- 判定は `game_data.gd` に pure 関数:

```gdscript
## stats スナップショットから獲得済み称号IDを返す（保存しない。毎回再計算）
func compute_earned_titles(stats: Dictionary) -> Array[String]
```

- `stats` の形（`PlayerProgress.title_stats_snapshot()` を新設して作る）:

```gdscript
{
  "level": int,
  "caught_counts": Dictionary,       # fish_id -> 匹数（ヌシ・サメ・ザリガニ含む）
  "spot_caught_counts": Dictionary,  # spot_id -> {fish_id: 匹数}
  "best_sizes": Dictionary,          # fish_id -> cm
  "eaten_recipes": Dictionary,       # "fish:recipe" -> 回数
  "quest_completed_count": int,      # E3導入までは常に0
  "shark_bonds": Dictionary,         # E10導入までは常に{}
}
```

- 獲得通知: `PlayerProgress` に in-memory キャッシュ `_known_title_ids: Array[String]`。`load_game()` 直後と `reset_game()` で計算結果を代入（ロード時に再通知しない）。`record_catch()` / `cook_and_eat()` / 依頼納品（E3）/ 餌やり（E10）の末尾で再計算し、差分があれば新シグナル `titles_earned(title_ids)` を emit、`record_catch` では `catch_result["new_titles"]` にも入れる
- 表示先: ステータス画面の「記録」節（`status_screen.gd:381` 付近）に「称号」小節を追加。獲得済みは称号名、未獲得は「？？？＋条件ヒント」をグレー表示。獲得数「12 / 31」を見出しに出す

## E1-3. 称号カタログ（初期31件）

条件type: `total_catches` / `species_count` / `fish_count` / `best_size` / `spots_complete` / `level` / `dish_total` / `quest_completed` / `fish_caught_any` / `fish_caught_all` / `shark_bond`（E10: 指定サメのなつき度100）/ `shark_bond_all`（E10: リスト全てなつき度100）。

| id | 称号名 | type | 条件 | フェーズ |
|---|---|---|---|---|
| total_10 | 駆け出し釣り人 | total_catches | 累計10匹 | E1 |
| total_100 | 波止場の常連 | total_catches | 累計100匹 | E1 |
| total_500 | 海を知る者 | total_catches | 累計500匹 | E1 |
| species_10 | 図鑑の入り口 | species_count | 10種 | E1 |
| species_30 | 海の収集家 | species_count | 30種 | E1 |
| species_50 | 海の博物学者 | species_count | 50種 | E1 |
| species_70 | 海の生き字引 | species_count | 70種 | E1 |
| aji_100 | アジ博士 | fish_count | aji 100匹 | E1 |
| iwashi_100 | イワシの群れ長 | fish_count | iwashi 100匹 | E1 |
| hirame_80 | 座布団職人 | best_size | hirame 80cm以上 | E1 |
| buri_100 | 寒ブリ一本 | best_size | buri 100cm以上 | E1 |
| kajiki_250 | 蒼い槍の主 | best_size | kajiki 250cm以上 | E1 |
| spots_all | 全釣り場制覇 | spots_complete | 通常7釣り場すべてで捕獲 | E1 |
| boss_kurodai | 大岩の覇者 | fish_caught_any | boss_kurodai | E1 |
| level_10 | 一人前の釣り人 | level | Lv10 | E1 |
| level_20 | 海のベテラン | level | Lv20 | E0以降有効 |
| level_30 | 海の頂 | level | Lv30 | E0以降有効 |
| level_40 | 大海の勇者 | level | Lv40 | E0以降有効 |
| level_50 | 伝説の釣り人 | level | Lv50 | E0以降有効 |
| dish_10 | 港の料理人 | dish_total | 料理10回 | E1 |
| dish_50 | 板前級 | dish_total | 料理50回 | E1 |
| nushi_first | ヌシとの遭遇 | fish_caught_any | NUSHI_FISH のいずれか | E2 |
| nushi_all | 全ヌシ制覇 | fish_caught_all | 通常7釣り場のヌシ全て | E2 |
| quest_1 | はじめての依頼 | quest_completed | 1件 | E3 |
| quest_10 | 港の便利屋 | quest_completed | 10件 | E3 |
| quest_30 | 依頼ボードの主 | quest_completed | 30件 | E3 |
| shark_first | 危険海域の生還者 | fish_caught_any | 通常サメ9種のいずれか | E4 |
| shark_nushi | 白帝を討つ者 | fish_caught_any | nushi_danger_reef | E4 |
| shark_raised_all | 鮫使い | shark_bond_all | 通常サメ9種すべて なつき度100 | E10 |
| megalodon | 古代の海の王 | fish_caught_any | megalodon | E10 |
| zarigani_10 | ザリガニ名人 | fish_count | zarigani 10匹 | E8 |

E2以降の称号もE1時点でカタログに全部入れてよい（対象が未実装なら判定が偽になるだけ）。後続フェーズは統計を書くだけで称号が増える。

## E1-4. CatchFanfare の演出序列

差し込み先は `catch_fanfare.gd` の `_bonus_text()`（L257）。行の優先順位と最大行数を固定する:

1. 記録更新行（`record_broken` 時）: `"自己記録更新！ %.1f cm（+%.1f cm）"`。`first_catch` 時は出さない
2. 既存のボス撃破報酬行（変更しない）
3. 称号行（`new_titles` の先頭最大2件）: `"称号獲得　「%s」"`
4. フォールバック「港で売却 / 料理に使える」は他の行が1つもないときだけ（現行ロジック維持）

記録更新時はバナー近くに追加の視覚強調を1点だけ入れる（例: サイズラベルの金色化 `Palette.GOLD_BRIGHT` + 小さな「NEW RECORD」札）。演出は docs/19 の作業順（構成→…→演出）に従い、visual確認をDoDに含める。

## E1-5. 触ってよいファイル / DoD

- 触る: `player_progress.gd`, `game_data.gd`, `game_catalog_data.gd`, `catch_fanfare.gd`, `status_screen.gd`
- 触らない: `docs/qa/status_qa.md` のfreeze値（称号節は既存「記録」レイアウトの下に**追加**。既存要素の位置を動かさない）
- DoD: `./tools/validate_project.sh` green + `status_smoke` / `catch_fanfare_smoke` / `save_system_verify.sh` 通過 + ファンファーレ実スクショで「初回」「記録更新」「称号同時」の3ケース目視確認（比較画像を `docs/qa/evidence/` へ）

## E1-6. Composer brief 分割案

1. brief A: `record_catch` 戻り値拡張 + 称号カタログ/判定関数 + snapshot（UI以外。headlessで判定検証）
2. brief B: CatchFanfare 演出序列 + status画面の称号節（Aマージ後）
