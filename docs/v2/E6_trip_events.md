# V2 / E6. 釣行中ランダムイベント

正本: `docs/30_v2_expansion_overview.md`（読む順: docs/30 §4 共通仕様 → 本doc）
前提フェーズ: なし
状態: 仕様確定・未着手

目的: 1回の釣行の単調さを崩す。E4の解放演出（ボトルメール→海図）の下地。

## E6-1. イベント表（`game_catalog_data.gd` に `TRIP_EVENTS`）

抽選タイミング: **キャスト成立ごとに1回**（アタリ待ち開始時）。1釣行あたり同一イベントは1回まで。

| id | 名称 | 重み | 効果 |
|---|---|---|---|
| none | （何もなし） | 0.86 | — |
| bird_swarm | 鳥山 | 0.06 | この釣行の以後3ヒット、`BIRD_SWARM_FISH_IDS` の重み×2.5。メッセージ「沖で鳥山が立っている！」 |
| driftwood | 流木・漂着物 | 0.05 | 50%:ハズレ「流木だった…」/ 45%: +80 G「漂着物を回収した」/ 5%: +500 G「小箱を拾った！」 |
| bottle_mail | ボトルメール | 0.03 | `sea_chart_fragments < 3` なら+1「海図の断片を拾った！（{n}/3）」。3枚目で「古い海図が完成した——危険海域の位置が判る」。所持済み3なら +200 G |

`BIRD_SWARM_FISH_IDS`（回遊魚）: `["iwashi", "saba", "kamasu", "sawara", "hirasouda", "suma", "katsuo", "buri", "kanpachi", "shiira", "hiramasa", "tsumuburi", "gingameaji", "kihada", "binnaga", "mebachi"]`

## E6-2. 実装形

- pure: `trip_event_table() -> Array[Dictionary]`（重み表を返す）+ `roll_trip_event(already_fired: Array[String]) -> Dictionary`
- 鳥山の重み補正は `encounter_weights()` に**任意引数** `extra_fish_weight_modifiers: Dictionary = {}` を追加して通す（既存呼び出しは無変更で互換）
- 演出は釣行画面の既存メッセージ行＋軽いエフェクト1点（鳥山: 水平線に鳥の小スプライトを数秒。共通素材の流用可なら流用）
- `sea_chart_fragments` は `PlayerProgress` に追加（docs/30 §4-1）

## E6-3. 触ってよいファイル / DoD

- 触る: `game_catalog_data.gd`, `game_data.gd`, `fishing_screen.gd`, `player_progress.gd`, `tools/trip_event_audit.tscn`（新設）
- 前提確認: 隠し釣り場の実体はE4の `danger_reef` として定義済み。E6単体では「断片が貯まる」まで動けばよい（3枚揃った時のマップ反映はE4側）
- DoD: `trip_event_audit`（分布と断片進行）+ `fishing_reveal_smoke` / `fishing_harbor_return_smoke` 退行なし + `save_system_verify.sh` + validate green
