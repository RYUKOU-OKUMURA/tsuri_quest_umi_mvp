# 28. リテンション拡張 実装仕様書（docs/27 の実装用詳細）

作成日: 2026-07-05
状態: 仕様確定（未決事項ゼロ）。docs/27 が「なぜ・何を・どの順で」の正本、本docが「どう作るか」の正本
対象読者: 実装ワーカー（Codex / Composer）。**各フェーズはこのdocの該当節だけで着手できる**ことを目標に書いてある

## 0. 使い方

- 実装時は「§1 確定判断」→「§2 共通仕様」→ 当該フェーズ節、の順に読む
- 数値（確率・倍率・経験値・称号しきい値）は**初期値**。headless監査で分布を確認して調整してよいが、変更したら本docの表を更新する
- 本docと docs/27 が矛盾したら docs/27 の方針（順序・目的）が優先。ただし**レベル基準は本doc §1-1 が正**（docs/27 作成時の Lv30〜50 記述はキャップ拡張決定で回収済み）
- UI品質判断はすべて `docs/19_ui_production_playbook.md` に従う。freeze値は `docs/qa/<screen>_qa.md` を参照

### フェーズ実施順（docs/27 §3 を E0 挿入で改訂）

| 順 | ID | 内容 | 前提 |
|---|---|---|---|
| 1 | E1 | 記録更新演出＋称号 | なし |
| 2 | E0 | レベルキャップ拡張（10→30） | なし（E1と並走可） |
| 3 | E2 | ヌシシステム | E1（称号の受け皿） |
| 4 | E3 | 依頼ボード | E1 |
| 5 | E6 | 釣行中ランダムイベント | なし |
| 6 | E4 | サメ危険海域 | E0・E2・E6 |
| 7 | E5 | 時間帯 | E0（夜=Lv15ゲート） |
| 8 | E7 | 難易度選択 | E1〜E4 |
| 9 | E8 | ザリガニ釣り | E3 |
| 10 | E9 | 川エリア | E1〜E8 |

---

## 1. 確定判断（2026-07-05 ユーザー確認 + Fable設計判断）

### 1-1. ユーザー決定（docs/27 §7 の残項目を解消）

| # | 項目 | 決定 |
|---|---|---|
| 9 | レベル基準 | **MAX_LEVEL を 10→30 へ拡張**（新フェーズE0）。Lv11以降はステータス成長を減衰させ、主に解放ゲートとして使う。夜釣り=Lv15、サメ海域=Lv30 は docs/27 の記述どおり有効 |
| 5 | サメ海域の解放 | **(c) 両方**。Lv30到達で釣り場マップに「？」として存在を告知、E6ボトルメールの海図断片3つで解放 |
| 6 | サメ横取りペナルティ | **(a) 掛けた魚のロストのみ**。仕掛け・餌は失わない（消耗品システムは導入しない） |
| 7 | 川エリアの形態 | **(a) 同一セーブ内の新エリア**。釣り場マップにエリア切替（海/川）を追加 |

### 1-2. Fable 設計判断（docs/27 で「Fable単体で決める」とされていた項目）

| 項目 | 決定 | 理由 |
|---|---|---|
| ヌシのデータモデル | **別魚ID方式**（`nushi_<spot_id>` の独立エントリ、`boss: true` + `nushi: true`）。ただし通常の `FISH` 辞書ではなく新設 `NUSHI_FISH` 辞書に置く | `boss_kurodai` の初回撃破報酬・演出・素材規約をそのまま流用できる。`NUSHI_FISH` を分けるのは `get_all_fish_ids()`（図鑑ページ列挙・出現抽選の走査元）にヌシを混ぜないため。図鑑は「既存魚ページに金枠」決定なのでヌシに `fish_no` は振らない |
| 図鑑「ヌシ」タブとfreezeの衝突 | **タブ列freeze値を7列用に改訂する**（§E2-6 に再計測値）。改訂理由をQAログに追記し、before/after比較画像を残す | 現行freeze（6件 x step 0.125）のまま7件目を足すと「港へ戻る」レール（x 0.778〜）に衝突する。機能追加に伴う意図的なfreeze改訂として扱う |
| E3依頼の受注モデル | **受注操作なしの掲示制**。掲示中の3件は常に進行中扱いで、ボード画面で納品/達成報告する | docs/27決定の「達成＆帰港でリフレッシュ・未達成は掲示継続」と整合し、受注/辞退のUI状態を丸ごと省ける |
| E3サイズ依頼の判定 | 依頼は**納品型**（数量・料理向け）と**記録型**（サイズ条件）の2種類に分ける | インベントリは魚種ごとの匹数のみでサイズを持たない。サイズ依頼は「掲示中に `best_sizes` が条件を超えたら達成」の記録型にすることでスキーマ変更を回避 |
| E8ザリガニの変則ルール | シミュレータに `surface_escape` フラグの分岐を1つ足す（§E8-2）。技術スパイクは不要 | 「体力が残ったまま水面に出たら逃げる」は既存の depth / stamina_ratio で表現でき、追加は10行程度 |
| E9エリア切替UI | 釣り場マップ画面の左上に「海 / 川」タブを追加する（港からの導線分岐は作らない） | マップ画面はE4/E6でも追加が入る（docs/27 §6-4）。エリア概念をマップに集約し、港の導線は現状維持 |

---

## 2. 共通仕様（全フェーズ）

### 2-1. セーブスキーマ追加の全量

追加はこの5フィールドのみ。すべてロード時デフォルト補完（`player_progress.gd` の `_apply_save_data()` に追記。`owned_rigs` と同じ流儀）。`SAVE_VERSION` は 1 のまま（フィールド追加のみの変更は変換不要、`_migrate_save_data()` のコメント方針どおり）。

| フィールド | 型 | デフォルト | 追加フェーズ | 内容 |
|---|---|---|---|---|
| `difficulty_id` | String | `"normal"` | E7 | 難易度ID。既存セーブは補完で「ふつう」になる |
| `quest_board` | Array[Dictionary] | `[]` | E3 | 掲示中の依頼（最大3件）。要素の形は §E3-3 |
| `quest_completed_count` | int | `0` | E3 | 依頼達成の累計。称号・専用仕掛けの判定に使う |
| `sea_chart_fragments` | int | `0` | E6 | 海図断片の所持数（0〜3） |
| `selected_time_slot_id` | String | `"daytime"` | E5 | 港で最後に選んだ時間帯（次回の初期選択に使う） |

**保存しないもの**（統計から毎回導出する）: 称号、ヌシ捕獲フラグ（`caught_counts["nushi_*"]` で判る）、記録更新歴、サメ撃破（`caught_counts` で判る）。

セーブを触るフェーズのDoDには必ず `./tools/save_system_verify.sh` を含める。

### 2-2. pure関数境界（docs/26 R3 の維持）

- データ表は `src/autoload/game_catalog_data.gd`（E9の川データ量次第で `river_expansion_data.gd` を新設してよい。`fish_expansion_data.gd` 前例）
- 判定・抽選ロジックは `src/autoload/game_data.gd` に pure 関数として追加（乱数は既存の `_rng` 流儀: 「重みテーブルを返すpure関数」+「それを引くroll関数」に分け、監査はテーブル側を叩く）
- 進行状態の読み書きは `src/autoload/player_progress.gd` のみ

### 2-3. 新魚の素材規約

新魚（サメ・ザリガニ・川魚・ヌシ）はすべて `assets/showcase/fish/` に `<id>_card_portrait.png` + `<id>_showcase_sheet.png` の2点セット。参照は `FightFishAssets` 経由。素材ブリーフを docs/22〜24 方式で書き、**サンプル生成→品質確認をコード実装より先に行う**（docs/27 §5-5）。ブリーフ一覧は §13。

### 2-4. smoke増設の一覧（docs/26 §Smoke へ追記するもの)

| フェーズ | 新設smoke | 検証内容 |
|---|---|---|
| E1 | （新設なし。`status_smoke` / `catch_fanfare_smoke` に検証を追加） | 称号判定・記録演出 |
| E0 | `level_curve_audit.tscn` | Lv1〜30の必要経験値とステータス成長の表出力 |
| E2 | `nushi_encounter_audit.tscn` | 条件成立/不成立でのヌシ出現率の監査 |
| E3 | `quest_board_smoke.tscn` | 生成→納品→リフレッシュの一巡 |
| E6 | `trip_event_audit.tscn` | イベント抽選分布と海図断片の進行 |
| E4 | （`fishing_spot_select_smoke` / `nushi_encounter_audit` に追加） | 海図ロック・横取り抽選 |
| E5 | （`nushi_encounter_audit` を流用した時間帯別出現監査を追加） | 時間帯別テーブル |
| E7 | `difficulty_fight_audit.tscn` | 3難易度のファイト指標比較 |
| E8 | `zarigani_flow_smoke.tscn` | 水路釣行→納品の一巡 |
| E9 | 既存smokeの川版一式 | — |

---

## E1. 記録更新演出＋称号

### E1-1. `record_catch()` の戻り値拡張

`src/autoload/player_progress.gd:112` の `catch_result` に3キーを追加する。**`best_sizes` を上書きする前に旧値を取ること**（現在は L129 で即上書きしている）。

```gdscript
var previous_best := float(best_sizes.get(fish_id, 0.0))
var catch_result := {
    "fish_id": fish_id,
    "first_catch": previous_count <= 0,
    "boss_first_clear_reward": {},
    "record_broken": previous_count > 0 and size_cm > previous_best,  # 追加
    "previous_best_cm": previous_best,                                 # 追加
    "new_titles": [],                                                  # 追加（後述の称号判定で埋める）
}
```

初回捕獲（`first_catch`）は `record_broken` を **true にしない**（初回は「図鑑登録」演出が担当。二重に祝わない）。

### E1-2. 称号アーキテクチャ

- 称号カタログは `game_catalog_data.gd` に `const TITLES: Array[Dictionary]` として追加
- 判定は `game_data.gd` に pure 関数で追加:

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
}
```

- 獲得通知: `PlayerProgress` に in-memory キャッシュ `_known_title_ids: Array[String]` を持つ。`load_game()` 直後と `reset_game()` で計算結果をそのまま代入（ロード時に再通知しない）。`record_catch()` / `cook_and_eat()` / 依頼納品（E3）の末尾で再計算し、差分があれば新シグナル `titles_earned(title_ids: Array[String])` を emit、`record_catch` では `catch_result["new_titles"]` にも入れる
- 表示先: ステータス画面の「記録」節（`status_screen.gd:381` 付近）に「称号」小節を追加。獲得済みは称号名、未獲得は「？？？＋条件ヒント」をグレー表示。獲得数「12 / 26」を見出しに出す

### E1-3. 称号カタログ（初期26件）

条件typeは5種のみ: `total_catches`（累計匹数）/ `species_count`（発見種数）/ `fish_count`（特定魚の匹数）/ `best_size`（特定魚のcm）/ `spots_complete`（`NORMAL_FISHING_SPOT_IDS` 全てで1匹以上）/ `level` / `dish_total`（eaten_recipes の値合計）/ `quest_completed` / `fish_caught_any`（リストのいずれか1匹以上）/ `fish_caught_all`（リスト全て1匹以上）。

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
| dish_10 | 港の料理人 | dish_total | 料理10回 | E1 |
| dish_50 | 板前級 | dish_total | 料理50回 | E1 |
| nushi_first | ヌシとの遭遇 | fish_caught_any | NUSHI_FISH のいずれか | E2 |
| nushi_all | 全ヌシ制覇 | fish_caught_all | 通常7釣り場のヌシ全て | E2 |
| quest_1 | はじめての依頼 | quest_completed | 1件 | E3 |
| quest_10 | 港の便利屋 | quest_completed | 10件 | E3 |
| quest_30 | 依頼ボードの主 | quest_completed | 30件 | E3 |
| shark_first | 危険海域の生還者 | fish_caught_any | hoshizame / aozame | E4 |
| shark_nushi | 白帝を討つ者 | fish_caught_any | nushi_danger_reef | E4 |
| zarigani_10 | ザリガニ名人 | fish_count | zarigani 10匹 | E8 |

E2以降の称号もE1時点でカタログに全部入れてよい（対象魚が未実装なら判定が偽になるだけ）。後続フェーズは統計を書くだけで称号が増える（docs/27 §6-2 のとおり）。

### E1-4. CatchFanfare の演出序列

差し込み先は `catch_fanfare.gd` の `_bonus_text()`（L257）。行の優先順位と最大行数を固定する:

1. 記録更新行（`record_broken` 時）: `"自己記録更新！ %.1f cm（+%.1f cm）"`。`first_catch` 時は出さない（既存の「初回記録　図鑑に登録」が優先）
2. 既存のボス撃破報酬行（変更しない）
3. 称号行（`new_titles` の先頭最大2件）: `"称号獲得　「%s」"`
4. フォールバック「港で売却 / 料理に使える」は**他の行が1つもないときだけ**（現行ロジック維持）

記録更新時はバナー近くに追加の視覚強調を1点だけ入れる（例: サイズラベルの金色化 `Palette.GOLD_BRIGHT` + 小さな「NEW RECORD」札）。演出の追加は docs/19 の作業順（構成→…→演出）に従い、visual確認をDoDに含める。

### E1-5. 触ってよいファイル / DoD

- 触る: `player_progress.gd`, `game_data.gd`, `game_catalog_data.gd`, `catch_fanfare.gd`, `status_screen.gd`
- 触らない: `docs/qa/status_qa.md` のfreeze値（称号節は既存「記録」レイアウトの下に**追加**する。既存要素の位置を動かさない）
- DoD: `./tools/validate_project.sh` green + `status_smoke` / `catch_fanfare_smoke` / `save_system_verify.sh` 通過 + ファンファーレ実スクショで「初回」「記録更新」「称号同時」の3ケース目視確認（比較画像を `docs/qa/evidence/` へ）

### E1-6. Composer brief 分割案

1. brief A: `record_catch` 戻り値拡張 + 称号カタログ/判定関数 + snapshot（UI以外。headlessテストで判定検証）
2. brief B: CatchFanfare 演出序列 + status画面の称号節（Aマージ後）

---

## E0. レベルキャップ拡張（10→30）

### E0-1. 定数変更

- `game_data.gd`: `MAX_LEVEL: int = 30`
- `player_progress.gd`: `EXP_REQUIREMENTS` を31要素へ拡張（index=現在Lv、値=次Lvまでの必要経験値。index 30 は 0）:

```
[0, 60, 85, 115, 150, 190, 235, 285, 340, 400,          # Lv1-9→10（既存値。変更しない）
 460, 520, 580, 640, 700, 770, 840, 910, 980, 1050,     # Lv10-19
 1130, 1210, 1290, 1370, 1450, 1540, 1630, 1720, 1810, 1900,  # Lv20-29
 0]                                                      # Lv30 = 上限
```

Lv10→30 の合計必要経験値は約23,500。終盤の1回の釣行（釣り+料理）で300〜500入る想定で、50〜70釣行ぶん。監査で体感調整してよい。

### E0-2. ステータス成長の減衰

`get_base_stats()`（`player_progress.gd:353`）の線形成長をそのまま30まで伸ばすとファイトが壊れる（巻力が約2.7倍になる）。**成長ポイント**を導入する:

```gdscript
const GROWTH_SOFT_CAP := 10
const GROWTH_RATE_AFTER_CAP := 0.35

func growth_points() -> float:
    if level <= GROWTH_SOFT_CAP:
        return float(level - 1)
    return float(GROWTH_SOFT_CAP - 1) + float(level - GROWTH_SOFT_CAP) * GROWTH_RATE_AFTER_CAP
```

`get_base_stats()` 内の `(level - 1)` をすべて `growth_points()` に置換（`technique` と `focus` は `int(floor(growth_points()))`）。Lv10以下の数値は**1bitも変わらない**こと（回帰条件）。Lv30時点の目安: growth=16.0 → max_energy 180 / 素の巻力 14.9（現Lv10比 +34%）。

### E0-3. レベルの用途

Lv11以降は主に解放ゲート: 朝まずめ=Lv12（E5）、夜釣り=Lv15（E5）、サメ海域の告知=Lv30（E4）、称号 Lv20/30（E1カタログ済み）。魚の `min_level` は全て10以下のまま変更しない。

### E0-4. 触ってよいファイル / DoD

- 触る: `game_data.gd`, `player_progress.gd`, `tools/level_curve_audit.tscn`（新設）
- 触らない: `fishing_simulator.gd`（バランスはgrowth側で吸収）、既存Lv1〜10の必要経験値
- DoD: `level_curve_audit` でLv1〜30の必要経験値・全ステータスを表出力し、Lv1〜10が現行値と完全一致すること + `save_system_verify.sh`（Lv10セーブのロード）+ `cooking_flow_smoke`（レベルアップ演出の回帰。`level_up_panel.gd` はgrowth差分をそのまま表示するので変更不要のはず）+ validate green

---

## E2. ヌシシステム

### E2-1. データ: `NUSHI_FISH` 辞書（`game_catalog_data.gd` に新設）

エントリの生成規則（基準魚からの導出。**具体値はこの式で計算して定数に書き下ろす**）:

| 項目 | 規則 |
|---|---|
| `id` | `nushi_<spot_id>`（例 `nushi_harbor_pier`） |
| `name` | 下表の異名 |
| `base_fish_id` | 下表。図鑑金枠の対象ページ |
| `rarity` | `"レア"` 固定（RarityStyles の boss 扱いは `boss: true` で効く） |
| `boss` / `nushi` | 両方 `true`（bossは初回報酬機構の流用、nushiは抽選・図鑑の判別用） |
| `size_min` / `size_max` | 基準魚の `size_max` の 2.0倍 / 2.6倍 |
| `stamina` | 基準魚 × 2.3 |
| `power` | 基準魚 × 1.35（上限 2.0） |
| `speed` | 基準魚 × 0.95 |
| `sell_price` | 基準魚 × 4 |
| `min_level` | 出現スポットの `unlock_level` |
| `fish_no` | **持たせない**（図鑑に独立ページを作らない。`get_all_fish_ids()` に混ぜない） |
| 素材・motion系 | 基準魚と同規約で専用素材（§13）。`visual_scale` は基準魚 × 1.35 |

### E2-2. ヌシ一覧（8体。danger_reef はE4で追加）

| spot | id | 異名 | base_fish_id | 出現条件（天候 × 仕掛け） | 初回撃破報酬 |
|---|---|---|---|---|---|
| harbor_pier | nushi_harbor_pier | 堤防の底主 | maanago | rain × chokusen | 1,200 G |
| shallow_sand | nushi_shallow_sand | 砂底の座布団 | hirame | fog × nomase | 1,500 G |
| rock_breakwater | nushi_rock_breakwater | 磯の黒帝 | ishidai | cloudy × kani | 1,800 G |
| outer_tide | nushi_outer_tide | 潮目の銀狼 | suzuki | rain × nomase | 1,600 G |
| south_reef | nushi_south_reef | 岩窟の老王 | kue | fog × kani | 2,600 G |
| bluewater_route | nushi_bluewater_route | 回遊の大将 | buri | sunny_windy × jigging | 2,400 G |
| deep_ocean | nushi_deep_ocean | 深淵の重鎮 | ara | fog × nomase | 3,200 G |
| danger_reef（E4） | nushi_danger_reef | 深海の白帝 | aozame | fog × nomase | 5,000 G |

- `FISHING_SPOTS[spot]` に `nushi` 節を追加: `{"fish_id", "environment_id", "rig_id", "hint"}`。`hint` はNPC目撃情報の文言（例 harbor_pier: 「雨の日、堤防の底で竿を折られた奴がいるらしい…」）
- 初回撃破報酬は `BOSS_FIRST_CLEAR_REWARDS` に8エントリ追加（`money` + `message`）。`record_catch()` は無変更で機能する（`boss: true` 経路）
- 将来E5で時間帯条件を足せるよう `nushi` 節に `"time_slot_id": ""`（空=不問）を最初から置く。E2時点では常に不問

### E2-3. 抽選への接続

`encounter_weights()` は触らない（ヌシは通常テーブルに混ぜない）。`game_data.gd` に追加:

```gdscript
const NUSHI_ENCOUNTER_CHANCE := 0.04  # 条件成立時、1ヒットごとの確率

## 条件成立していれば NUSHI_FISH エントリを、していなければ {} を返す（pure）
func nushi_candidate(spot_id: String, environment_id: String, rig_id: String,
        time_slot_id: String, player_level: int) -> Dictionary

## 実際の抽選（fishing_screen のヒット判定から呼ぶ）:
## nushi_candidate が非空 かつ rand < NUSHI_ENCOUNTER_CHANCE ならヌシ、でなければ roll_normal_fish
func roll_hooked_fish(player_level, spot_id, rig_id, environment_id, time_slot_id := "") -> Dictionary
```

`fishing_screen.gd` の既存の `roll_normal_fish` 呼び出し箇所を `roll_hooked_fish` に差し替える。

### E2-4. 予兆演出・ヒント

- 釣行開始時（`begin_fishing_trip` 後の釣行画面初期化時）、条件成立なら画面メッセージ「……ヌシの気配がする。」を1回出す（新画面・新素材なし）
- 港画面「今日の支度」カード内に1行のヒントラベルを追加: 未捕獲ヌシからランダムに1体選び `hint` を表示。全捕獲済みなら非表示

### E2-5. 図鑑表示（金枠バッジ＋ヌシ記録）

- 判定: `caught_counts.has("nushi_<spot>")` で、その `base_fish_id` のページに反映
- 一覧カード: 発見済みカードの右上に小さな金ピン（`Palette.GOLD_BRIGHT`）
- 詳細パネル: 釣果記録スリップに1行追加「ヌシ記録　{異名}　{best_sizes[nushi_id]} cm」+ 詳細枠の外周を金線アクセント
- 未捕獲でも「気配」を出したい場合は今回はやらない（不採用として `docs/qa/fish_book_qa.md` に記録）

### E2-6. 図鑑フッター「ヌシ」タブ（freeze改訂）

現行freeze（`docs/qa/fish_book_qa.md` §1: 6件、x0 0.032 / step 0.125 / 幅 0.122）のままでは7件目が「港へ戻る」レール（x 0.778〜）に衝突する。**7列用の改訂値**:

- x0 0.032 / step 0.1065 / 幅 0.104（7件目の右端 = 0.775 < 0.778）
- タブ順: 全魚 / 港内 / 砂浜 / 岩礁 / 沖 / レア / **ヌシ**
- 「ヌシ」フィルタの内容: `NUSHI_FISH` が定義されている `base_fish_id` のページ群
- 手順: 改訂前スクショ → 実装 → `./tools/fish_book_visual_qa.sh` → 横並び比較 → `docs/qa/fish_book_qa.md` のfreeze表を新値へ更新し、改訂理由（ヌシタブ追加のため7列化）と比較画像を追記

### E2-7. 触ってよいファイル / DoD

- 触る: `game_catalog_data.gd`, `game_data.gd`, `fishing_screen.gd`（roll差し替え・気配メッセージ）, `fish_book_screen.gd`, `harbor_screen.gd`（ヒント1行）, `tools/nushi_encounter_audit.tscn`（新設）
- 触らない: `player_progress.gd`（セーブ追加なし。`caught_counts` で足りる）, `catch_fanfare.gd`（boss経路で動く）
- DoD: `nushi_encounter_audit` で「条件成立時のみ約4%、非成立時0%」を確認 + `fish_book_smoke` + `fishing_reveal_smoke` 退行なし + 図鑑visual QA + validate green

### E2-8. brief分割案

1. brief A: NUSHI_FISH/spot nushi節/BOSS_FIRST_CLEAR_REWARDS + `nushi_candidate`/`roll_hooked_fish` + 監査シーン
2. brief B: 素材生成（8体×2点セット。§13ブリーフ先行）
3. brief C: 図鑑金枠＋ヌシタブ（freeze改訂手順込み）
4. brief D: 気配メッセージ＋港ヒント

---

## E3. 依頼ボード

### E3-1. 画面

- 新画面 `src/ui/quest_board_screen.gd`。**`skills/ui-screen-build/SKILL.md` の工程に従う**（reference画像の用意→素材ブリーフ→実装→`docs/qa/quest_board_qa.md` 新設）
- 導線: 港画面のメニューに「依頼ボード」を追加
- 構成: 木製掲示板背景に依頼札3枚（縦並びまたは横並び。reference次第）。各札に「依頼文 / 進捗（例 2/5） / 報酬 / 納品ボタン」。下部右に共通の「港へ戻る」ボタン（他画面と同じ右下規約）

### E3-2. 依頼テンプレート（`game_catalog_data.gd` に `QUEST_TEMPLATES`）

| id | 種別 | 生成規則 | 依頼文の型 | 報酬（money） |
|---|---|---|---|---|
| bulk_common | 納品型 | 解放済み釣り場の allowed_fish からコモンを1種、n=3〜5 | 「{魚}を{n}匹届けてほしい」 | sell_price × n × 1.6 |
| bulk_uncommon | 納品型 | 同・アンコモン1種、n=2〜3 | 「{魚}を{n}匹。上物を頼む」 | sell_price × n × 1.8 |
| cuisine | 納品型 | RECIPESから1品→allowed_fishの1種、n=1 | 「{料理}にする{魚}を1匹」 | sell_price × 2.0 |
| size_record | 記録型 | 解放済み釣り場の魚1種、目標 = size_min + (size_max - size_min) × 0.62 を5cm単位へ丸め | 「{目標}cm以上の{魚}を釣り上げてくれ」 | sell_price × 2.5 |
| rare_order | 納品型 | Lv8以上で出現。レア1種、n=1 | 「{魚}を探している。金は弾む」 | sell_price × 2.2 |
| zarigani_kid | 納品型 | E8導入後のみ。固定（§E8-4） | 「（子ども）ザリガニをつかまえて！」 | 0 G（称号・お礼文言のみ） |

- 生成: 掲示枠が空いたとき、レベルで重み付けして抽選（Lv7以下: bulk_common 50% / bulk_uncommon 25% / cuisine 15% / size_record 10%。Lv8+: bulk_common 30% / bulk_uncommon 25% / cuisine 15% / size_record 15% / rare_order 15%）。同じ魚の依頼が2枚同時に出ないこと
- pure関数: `generate_quest(template_weights_context) -> Dictionary` と `quest_progress(quest, stats) -> Dictionary` を `game_data.gd` に置き、headlessで検証する

### E3-3. 依頼データの形（セーブされる `quest_board` の要素）

```gdscript
{
  "template_id": "bulk_common",
  "kind": "delivery",          # "delivery" | "record"
  "fish_id": "aji",
  "count": 5,                   # delivery のみ
  "target_size_cm": 40.0,       # record のみ
  "posted_best_cm": 32.0,       # record のみ。掲示時点の自己ベスト（これを超えても目標未満なら未達成）
  "reward_money": 960,
  "text": "アジを5匹届けてほしい",
}
```

### E3-4. 達成・納品・リフレッシュ（docs/27 決定の実装）

- **納品型**: ボード画面の「納品」ボタン。`PlayerProgress.deliver_quest(index)` を新設し、インベントリから `count` 匹消費 → `money += reward` → `quest_completed_count += 1` → 称号再計算 → その枠を**即座に新依頼で入替**（「達成して帰港した時に入替」の実装形。納品できるのは帰港中＝ボード画面にいる時だけなので同義）
- **記録型**: 釣行から帰港した時点で `best_sizes[fish_id] >= target_size_cm` なら達成扱い。ボード画面で「報告」ボタンを押して報酬受取→枠入替（魚の消費なし）
- 未達成の依頼は掲示され続ける（リフレッシュなし）
- インベントリが足りない場合の納品ボタンは無効表示（進捗 2/5 を札に出す）

### E3-5. 専用報酬: 依頼限定仕掛け

`quest_completed_count` が10に達した納品時に、店で買えない仕掛けを付与する:

```gdscript
"shokunin": {"id": "shokunin", "name": "職人仕掛け", "price": 0,
  "bait_types": ["イソメ", "オキアミ", "小魚"], "unlock_level": 1,
  "shop_hidden": true, "description": "港の常連たちから贈られた万能仕掛け。"},
```

- `RIGS` / `RIG_ORDER` に追加し、タックルショップの一覧構築側で `shop_hidden` を除外するフィルタを1行追加（`shop_screen.gd`）
- 付与は `owned_rigs.append` + ボード画面でメッセージ表示。既に所持していれば何もしない

### E3-6. 触ってよいファイル / DoD

- 触る: `quest_board_screen.gd`（新設）, `harbor_screen.gd`（導線）, `player_progress.gd`（`quest_board`/`quest_completed_count`/`deliver_quest`）, `game_data.gd` + `game_catalog_data.gd`（テンプレ・生成・進捗）, `shop_screen.gd`（shop_hiddenフィルタ）, `tools/quest_board_smoke.tscn`（新設）
- 触らない: `market_screen.gd` の売却ロジック（納品は独自にインベントリを減らす。sell系の流用は消費部分のパターンのみ）
- DoD: `quest_board_smoke`（生成→納品→入替→限定仕掛け付与の一巡）+ `market_smoke` 退行なし + `save_system_verify.sh` + 新画面visual QA（`docs/qa/quest_board_qa.md` 新設）+ validate green

### E3-7. brief分割案

1. brief A: reference画像・素材ブリーフ（§13）→素材生成
2. brief B: 依頼生成・進捗・納品のデータ層 + smoke（画面なしで完結）
3. brief C: ボード画面実装（ui-screen-build工程。A/B完了後）

---

## E6. 釣行中ランダムイベント

### E6-1. イベント表（`game_catalog_data.gd` に `TRIP_EVENTS`）

抽選タイミング: **キャスト成立ごとに1回**（アタリ待ち開始時）。1釣行あたり同一イベントは1回まで。

| id | 名称 | 重み | 効果 |
|---|---|---|---|
| none | （何もなし） | 0.86 | — |
| bird_swarm | 鳥山 | 0.06 | この釣行の以後3ヒット、`BIRD_SWARM_FISH_IDS` の重み×2.5。メッセージ「沖で鳥山が立っている！」 |
| driftwood | 流木・漂着物 | 0.05 | 50%:ハズレ「流木だった…」/ 45%: +80 G「漂着物を回収した」/ 5%: +500 G「小箱を拾った！」 |
| bottle_mail | ボトルメール | 0.03 | `sea_chart_fragments < 3` なら+1「海図の断片を拾った！（{n}/3）」。3枚目で「古い海図が完成した——危険海域の位置が判る」。所持済み3なら +200 G |

`BIRD_SWARM_FISH_IDS`（回遊魚）: `["iwashi", "saba", "kamasu", "sawara", "hirasouda", "suma", "katsuo", "buri", "kanpachi", "shiira", "hiramasa", "tsumuburi", "gingameaji", "kihada", "binnaga", "mebachi"]`

### E6-2. 実装形

- pure: `trip_event_table() -> Array[Dictionary]`（重み表を返す）+ `roll_trip_event(already_fired: Array[String]) -> Dictionary`
- 鳥山の重み補正は `encounter_weights()` に**任意引数** `extra_fish_weight_modifiers: Dictionary = {}` を追加して通す（既存呼び出しは無変更で互換）
- 演出は釣行画面の既存メッセージ行＋軽いエフェクト1点（鳥山: 水平線に鳥の小スプライトを数秒。素材は共通素材の流用可なら流用、無ければ§13）
- `sea_chart_fragments` は `PlayerProgress` に追加（§2-1）

### E6-3. 触ってよいファイル / DoD

- 触る: `game_catalog_data.gd`, `game_data.gd`, `fishing_screen.gd`, `player_progress.gd`, `tools/trip_event_audit.tscn`（新設）
- 前提確認: 隠し釣り場の実体はE4の `danger_reef`（§E4-1）として定義済み。E6単体では「断片が貯まる」まで動けばよい（3枚揃った時のマップ反映はE4側）
- DoD: `trip_event_audit`（分布と断片進行）+ `fishing_reveal_smoke` / `fishing_harbor_return_smoke` 退行なし + `save_system_verify.sh` + validate green

---

## E4. サメ危険海域

### E4-1. 釣り場「危険海域」

`FISHING_SPOTS` に追加（`FISHING_SPOT_ORDER` は `deep_ocean` の後、`harbor_boulder` の前）:

```gdscript
"danger_reef": {
  "id": "danger_reef", "name": "危険海域・鮫の根", "short_name": "危険海域",
  "unlock_level": 30, "required_boat_rank": 3,
  "requires_sea_chart": true,   # 新フィールド
  "depth_range": [18.0, 30.0],
  "description": "海図でしか辿り着けない鮫の根。掛けた魚を横取りされる危険がある。",
  "common_modifier": 0.05,
  "featured_fish": ["hoshizame", "aozame", "kihada", "kajiki", "ara"],
  "recommended_baits": ["小魚", "大型ルアー"],
  "boss_spot": false,
  "allowed_fish": ["hoshizame", "aozame", "kihada", "mebachi", "kajiki", "ara", "shiira", "kanpachi", "buri"],
  "fish_weight_modifiers": {"hoshizame": 2.0, "aozame": 1.2, "kihada": 0.9, "mebachi": 0.8, "kajiki": 0.9, "ara": 0.8},
  "nushi": {"fish_id": "nushi_danger_reef", "environment_id": "fog", "rig_id": "nomase", "time_slot_id": "", "hint": "霧の日の鮫の根に、白い巨影が出るという……"},
},
```

### E4-2. 解放フロー（決定: 告知＋海図の両方式）

`fishing_spot_access_status()`（`game_data.gd:222`）に第4引数 `sea_chart_fragments: int = 3` を追加し、レベル・船判定の後に:

```gdscript
if bool(spot.get("requires_sea_chart", false)) and sea_chart_fragments < 3:
    return {"ok": false, "reason": "chart",
        "message": "海図が必要　断片 %d/3" % sea_chart_fragments,
        "detail": "釣行中に流れ着くボトルメールから海図の断片を集めよう。", ...}
```

- マップ表示: Lv30未満は従来どおり「未発見 Lv.30で発見」。Lv30以上かつ断片<3 は「？」アイコン＋上記メッセージ（存在の告知）。断片3で通常表示
- 釣り場マップへのサムネ・ピン追加は `docs/qa/fishing_spot_map_qa.md` のfreeze値と照合してから（docs/27 §6-4: マップ追加はフェーズごとに1回で済ませる）

### E4-3. サメ2種＋ヌシ1体

`FishExpansionData.ROWS` の様式で追加（fish_noは既存の続き）:

| id | 名前 | rarity | fish_no | min_level | size | sell | stamina | power | speed | style | preferred_bait |
|---|---|---|---|---|---|---|---|---|---|---|---|
| hoshizame | ホシザメ | アンコモン | No.071 | 30 | 70〜130cm | 1,400 | 150 | 1.20 | 0.90 | bottom | イソメ |
| aozame | アオザメ | レア | No.072 | 30 | 180〜320cm | 3,800 | 260 | 1.75 | 1.70 | pelagic_fast | 小魚 |
| nushi_danger_reef | 深海の白帝（ホホジロザメ） | （NUSHI_FISH。§E2-1の規則で aozame から導出、size 400〜550cm） | — | 30 | — | — | — | — | — | — | — |

### E4-4. 横取り（リスク設計の本体）

- 対象: `danger_reef` での**サメ以外**の魚とのファイト
- 決定方式（pure・監査可能）: ファイト開始時に `shark_ambush_plan(rand1, rand2) -> Dictionary` で「この勝負に横取りが起きるか（確率 `SHARK_AMBUSH_CHANCE := 0.22`）」「起きる場合の発動しきい値（魚スタミナ比 0.25〜0.60 の一様乱数）」を先に決める
- 発動: ファイト中に `fish_stamina_ratio()` がしきい値を下回った瞬間、ファイトを強制終了。専用メッセージ「巨大な影が食らいついた！ 獲物を横取りされた……」+ 画面フラッシュ。**魚はロスト（記録なし・インベントリなし）。仕掛け・餌・お金は失わない**
- サメ（hoshizame / aozame / nushi）とのファイトでは発生しない
- 釣り場説明・初回入場時メッセージで横取りの存在を予告する（理不尽に感じさせない）

### E4-5. 触ってよいファイル / DoD

- 触る: `game_catalog_data.gd`, `fish_expansion_data.gd`, `game_data.gd`（access status・ambush）, `fishing_screen.gd`（ambush発動・演出）, `fishing_spot_select_screen.gd`（？表示・chart理由）, `player_progress.gd`（`fishing_spot_access_status` ラッパーに断片数を渡す）
- 先行条件: E0・E2・E6完了、サメ素材の品質確認（§13）
- DoD: `fishing_spot_select_smoke`（Lv/船/海図の3段ロック判定）+ `nushi_encounter_audit` にdanger_reef条件を追加 + ambush分布のheadless監査 + 釣り場マップvisual QA + validate green

---

## E5. 時間帯（朝まずめ・夜釣り）

### E5-1. データ（`game_catalog_data.gd` に `TIME_SLOT_ORDER` / `TIME_SLOTS`）

| id | 名称 | 解放 | rarity_weight_modifiers | fish_weight_modifiers（主なもの） | 画面効果 |
|---|---|---|---|---|---|
| asa_mazume | 朝まずめ | Lv12 | レア×1.30、アンコモン×1.12 | aji 1.3 / iwashi 1.3 / katsuo 1.2 / buri 1.2 / kanpachi 1.2 / madai 1.15 | 暖色グレーディング（橙） |
| daytime | 日中 | 最初から（デフォルト） | なし | なし | なし（現行そのまま） |
| night | 夜 | Lv15 | なし | tachiuo 2.2 / maanago 2.4 / kinmedai 1.6 / akamutsu 1.5 / mebaru 1.5 / kurosoi 1.5 / suzuki 1.4 / ara 1.3 | 寒色グレーディング（紺）＋暗め |

- `rarity_weight_modifiers` は新概念: 魚の `rarity` 文字列で引く倍率。`fish_weight_modifiers`（魚ID別）と両方適用
- BGM: 各slotに `"surface_bgm_key_override": ""`（空=天候由来のまま）。夜のみ `"calm"` 固定を初期値にする

### E5-2. 抽選への接続

`encounter_weights()` に任意引数 `time_slot_id: String = ""` を追加（5軸目。既存呼び出し互換）。適用は environment と同じパターン: `_time_slot_weight_modifier(fish_id, fish, time_slot_id)` を掛ける。`roll_hooked_fish`（E2）にも `time_slot_id` を通し、`nushi` 節の `time_slot_id` が非空ならヌシ条件に含める。

### E5-3. 港画面の選択UI（docs/27 決定: 出港前に選択）

- 位置: 「今日の支度」節（`harbor_screen.gd:110` 付近）に、食事バフカードと並ぶ時間帯セレクタ（3ボタンの横並び。未解放はロック表示「Lv.15で解放」）
- ヘッダーの状況行（`harbor_screen.gd:63`）は**現在ハードコードされた飾り文字列**なので、この機会に実データ駆動へ差し替える: 天候は釣行開始時抽選（変えない）なのでヘッダーでは天候を出さず、「時間帯：{選択中}　潮位：{飾りのまま}　風：{飾りのまま}」の形で時間帯のみ実値にする。潮位・風の実データ化はスコープ外（やらない）
- 選択は `selected_time_slot_id` に保存（§2-1）。`begin_fishing_trip()` が `stats["time_slot_id"]` / `stats["time_slot_label"]` を載せる
- 港のスクショ比較を行い、`docs/qa/harbor_qa.md` を新設して選択UIの配置を記録（現状freezeログなし＝低リスク、docs/27 §E5条件2のとおり）

### E5-4. 背景・空気感（素材は最小から)

- 全組み合わせの背景素材は**作らない**。まず釣行画面・港画面に時間帯カラーグレーディング（`CanvasModulate` 相当の色乗算+ビネット1枚）で成立するか検証する（docs/27 §E5条件3）
- グレーディングで不足と判断した画面だけ、時間帯差し替え背景を素材ブリーフに起こす（§13）。判断は実スクショ横並び比較で行い、`docs/qa/` に判断理由を残す

### E5-5. 釣り場マップの「よく釣れる魚」追従

**追従させない**（v1スコープ外と決定）。マップは日中基準の表示のまま。理由: freeze照合コストに対して情報価値が薄い。将来要望が出たら別スライスで（docs/27 §設計ノートの判断を確定）

### E5-6. 触ってよいファイル / DoD

- 触る: `game_catalog_data.gd`, `game_data.gd`, `harbor_screen.gd`, `player_progress.gd`, `fishing_screen.gd`（グレーディング）, 監査シーン
- DoD: 時間帯別出現監査（asa_mazume でレア重み計が約1.3倍になること等）+ `fishing_reveal_smoke` + 港・釣行のvisual QA（3時間帯スクショ）+ `save_system_verify.sh` + validate green

---

## E7. 難易度選択

### E7-1. 倍率テーブル（`game_catalog_data.gd` に `DIFFICULTIES`）

| id | 名称 | safe_min shift | safe_max shift | line_break倍率 | 魚スタミナ倍率 | 売値倍率 | 経験値倍率 |
|---|---|---|---|---|---|---|---|
| easy | やさしい | -0.04 | +0.05 | ×1.15 | ×0.85 | ×1.00 | ×1.00 |
| normal | ふつう | 0 | 0 | ×1.00 | ×1.00 | ×1.00 | ×1.00 |
| hard | むずかしい | +0.02 | -0.04 | ×0.95 | ×1.25 | ×1.25 | ×1.25 |

「むずかしい」の売値・経験値ボーナスが採用条件（docs/27）。

### E7-2. 適用点（ロジック側は難易度IDを参照するだけ）

- `get_base_stats()`: safe_min/max shift と line_break倍率を適用
- ファイト開始時: 魚データの `stamina` に倍率（`fishing_screen.gd` が simulator へ渡す前に乗算）
- `sell_fish` / `sell_fish_batch`: income に売値倍率（丸めは int）
- `cook_and_eat`: `total_exp` に経験値倍率
- ヘルパ `PlayerProgress.difficulty() -> Dictionary` を1つ作り、各所はそれを読む

### E7-3. 選択UI（新規セーブ開始時のみ・変更不可）

- `title_screen.gd`: 「はじめから」押下時に3択パネルを重ねる（既存タイトルレイアウトの上のモーダル。タイトル自体の配置は動かさない）。選択→`reset_game(difficulty_id)` へ引数追加
- 既存セーブはロード補完で `"normal"`（§2-1）
- タイトルのfreeze記録は `docs/qa/` に現状ファイルがないため、実装後スクショ比較を行い必要なら `docs/qa/title_qa.md` を新設（docs/27 の「freeze済み」記述はQAログ未整備なので、抵触判断はスクショ比較で代替する）
- ステータス画面のヘッダー付近に現在難易度を小さく表示

### E7-4. 触ってよいファイル / DoD

- 触る: `game_catalog_data.gd`, `player_progress.gd`, `title_screen.gd`, `fishing_screen.gd`, `status_screen.gd`, `tools/difficulty_fight_audit.tscn`（新設）
- DoD: `difficulty_fight_audit`（3難易度で safe帯幅・スタミナ・売値・経験値の実効値を表出力）+ `save_system_verify.sh`（旧セーブ→normal補完）+ タイトルvisual QA + validate green

---

## E8. ザリガニ釣りミニゲーム

### E8-1. 魚データ

| id | 名前 | rarity | fish_no | size | sell | stamina | power | speed | 特記 |
|---|---|---|---|---|---|---|---|---|---|
| zarigani | アメリカザリガニ | コモン | No.073 | 8〜20cm | 60 | 26 | 0.40 | 0.60 | `"surface_escape": true` |

### E8-2. 変則ルール `surface_escape`（シミュレータへの最小追加）

`fishing_simulator.gd` の深度更新後（L269 付近の depth 減少処理の直後）に:

```gdscript
if bool(_fish_data.get("surface_escape", false)) \
        and depth <= DEPTH_SURFACE_LIMIT and fish_stamina_ratio() > 0.25:
    _escape("水面に出た瞬間、ザリガニが手を離した！")
```

体力を25%未満まで削ってから浮かせないと逃げられる＝「急がば負け」。既存の取り込み条件（distance≤0.8 かつ stamina≤0.22）は変更しない。

### E8-3. 釣り場「港の水路」

```gdscript
"harbor_canal": {"id": "harbor_canal", "name": "港の水路", "short_name": "水路",
  "unlock_level": 1, "required_boat_rank": 0, "hidden_on_map": true,
  "depth_range": [1.0, 3.0], "boss_spot": false,
  "allowed_fish": ["zarigani"], "fish_weight_modifiers": {}, "common_modifier": 1.0, ...},
```

- `hidden_on_map: true` を新設し、釣り場マップの列挙から除外（マップfreezeに触らない）
- 入口は依頼ボードのザリガニ依頼札にある「水路へ行く」ボタンのみ → `fishing_screen` を `harbor_canal` で起動

### E8-4. 依頼接続（専用導線を作らない）

- `zarigani_kid` テンプレ（§E3-2）: `quest_completed_count >= 5` 以降、掲示リフレッシュ時に15%で出現（同時に1枚まで）。内容「ザリガニを3匹つかまえて！」
- 報酬: お金0。お礼メッセージ＋称号 `zarigani_10` への進行。達成時の文言「ありがとう！ おねえちゃん（おにいちゃん）すごい！」

### E8-5. 触ってよいファイル / DoD

- 触る: `fish_expansion_data.gd`（zarigani行）, `game_catalog_data.gd`（水路・テンプレ）, `fishing_simulator.gd`（§E8-2の1分岐のみ）, `quest_board_screen.gd`（水路ボタン）, `fishing_spot_select_screen.gd`（hidden除外）, `tools/zarigani_flow_smoke.tscn`（新設）
- DoD: `zarigani_flow_smoke`（依頼→水路→捕獲→納品）+ `catch_fanfare_smoke` 退行なし + 既存ファイトsmoke退行なし + validate green

---

## E9. 川エリア（横展開検証）

方針（docs/27）: 実装は原則カタログ＋素材の追加のみ。**コード変更が必要になった箇所を「横展開の障害リスト」として docs/27 に記録する**のが成果物。以下は着手時にそのまま使うデータ骨子。魚の詳細ステータスは「海の類似魚から導出」ルールで埋める（サンプル3種の素材品質確認が先。§13）。

### E9-1. エリアとデータの持ち方

- `FISHING_SPOTS` に `"area": "sea"`（既存全スポットにデフォルト補完）/ `"river"` を追加
- 釣り場マップ左上に「海 / 川」タブ。タブで `area` をフィルタ（マップfreeze照合はこのフェーズ内で1回だけ）
- 川魚は `river_expansion_data.gd` を新設（`fish_expansion_data.gd` と同形式・fish_no は No.074〜）

### E9-2. 川の釣り場（3箇所）

| id | 名前 | unlock_level | 主な魚 |
|---|---|---|---|
| river_rapids | 川瀬 | 3 | オイカワ、カワムツ、ウグイ、アユ、タナゴ |
| river_pool | 淵 | 6 | ヤマメ、イワナ、ニジマス、ウナギ、ナマズ、ニゴイ |
| pond | ため池 | 4 | コイ、フナ、ワカサギ、テナガエビ、ライギョ |

### E9-3. 川魚16種（ステータスは海の類似魚から導出）

| id | 名前 | rarity | 類似魚（ステータス基準） |
|---|---|---|---|
| oikawa | オイカワ | コモン | sappa |
| kawamutsu | カワムツ | コモン | nenbutsudai |
| ugui | ウグイ | コモン | bora |
| ayu | アユ | アンコモン | sayori |
| tanago | タナゴ | アンコモン | umitanago |
| yamame | ヤマメ | アンコモン | mebaru |
| iwana | イワナ | レア | ainame |
| nijimasu | ニジマス | アンコモン | isaki |
| unagi | ウナギ | レア | maanago |
| namazu | ナマズ | レア | kurosoi |
| nigoi | ニゴイ | コモン | konoshiro |
| koi | コイ | アンコモン | kobudai |
| funa | フナ | コモン | mejina |
| wakasagi | ワカサギ | コモン | iwashi |
| tenagaebi | テナガエビ | アンコモン | zarigani（surface_escape付き） |
| raigyo | ライギョ | レア | suzuki |

### E9-4. 淡水の仕掛け（2種）

| id | 名前 | bait_types | unlock_level | price |
|---|---|---|---|---|
| miyaku | ミャク釣り仕掛け | ミミズ、川虫 | 3 | 500 |
| neriuki | 練り餌ウキ仕掛け | 練りエサ | 4 | 700 |

### E9-5. DoD

- 既存smokeの川版一式 + 横展開障害リスト（docs/27へ追記）+ validate green
- 検証の観点: 「encounter/fight/図鑑/依頼/称号が、コード変更なしに川データで動いたか」。動かなかった箇所が障害リスト行になる

---

## 13. 素材ブリーフ一覧（コード実装より先に書く）

すべて docs/22〜24 方式のブリーフを新規docとして起こし、サンプル生成→品質確認→量産の順。日本語テキストのPNG焼き込み禁止。

| フェーズ | 対象 | 点数 | 置き場所 |
|---|---|---|---|
| E2 | ヌシ7体（各 card_portrait + showcase_sheet） | 14 | `assets/showcase/fish/` |
| E3 | 依頼ボード画面一式（掲示板背景、依頼札枠、ピン等）+ reference画像 | 画面素材一式 | `assets/showcase/quest_board/` + `reference/` |
| E6 | 鳥山スプライト（共通素材に流用可能なものが無い場合のみ） | 1 | `assets/showcase/common/` か fishing画面フォルダ |
| E4 | サメ2種＋ヌシ1体（各2点）+ 危険海域マップサムネ | 7 | fish/ + fishing_spot_map画面フォルダ |
| E5 | 時間帯グレーディング検証後、不足画面の背景差し替えのみ | 検証後確定 | 各画面フォルダ |
| E7 | タイトル難易度選択パネル（枠のみ。文字はruntime） | 1〜2 | title画面フォルダ |
| E8 | ザリガニ（2点）+ 水路背景 | 3 | fish/ + fishing画面フォルダ |
| E9 | 川魚16種（32点）+ 川背景3 + 川マップサムネ3 | 38 | fish/ + 各画面フォルダ |

---

## 14. 更新履歴

- 2026-07-05: 初版。docs/27 の未決5件（レベル基準含む）をユーザー確認で解消し、E0〜E9の実装仕様を確定
