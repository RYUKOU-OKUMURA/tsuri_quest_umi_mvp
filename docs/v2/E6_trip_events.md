# V2 / E6. 釣行中ランダムイベント

正本: `docs/30_v2_expansion_overview.md`（読む順: docs/30 §4 共通仕様 → 本doc）
前提フェーズ: なし
状態: **実装完了（2026-07-06）**

目的: 1回の釣行の単調さを崩す。E4の解放演出（ボトルメール→海図）の下地。

## E6-1. イベント表（`game_catalog_data.gd` に `TRIP_EVENTS`）

抽選タイミング: **キャスト成立ごとに1回**（アタリ待ち開始時）。1釣行あたり同一イベントは1回まで。

| id | 名称 | 重み | 効果 |
|---|---|---|---|
| none | （何もなし） | 0.86 | — |
| bird_swarm | 鳥山 | 0.06 | この釣行の以後3ヒット、`BIRD_SWARM_FISH_IDS` の重み×2.5。メッセージ「沖で鳥山が立っている！」 |
| driftwood | 流木・漂着物 | 0.05 | 50%:ハズレ「流木だった…」/ 45%: +80 G「漂着物を回収した」/ 5%: +500 G「小箱を拾った！」 |
| bottle_mail | ボトルメール | 0.03 | `sea_chart_fragments < 3` なら+1「海図の断片を拾った！（{n}/3）」。3枚目で「古い海図が完成した——危険海域の位置が判る」。所持済み3なら +200 G「ボトルメールを拾った。海図はもう完成している（+{money} G）」 |

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

## E6-4. 実装記録（2026-07-06）

- DoD全通過。`trip_event_audit`（10万回抽選、許容±0.5%）で分布・発火済み除外・driftwood内訳・鳥山2.5倍補正・断片clampの6項目PASS
- 発火済みイベントの重みは **none に加算**（再正規化しない）。`roll_trip_event` は none 当選時も `id:"none"` の Dictionary を返す
- 発火済みID・鳥山残ヒット数は `_trip_stats`（釣行単位）に保持。金銭・断片の加算は `PlayerProgress.gain_trip_event_money()` / `gain_trip_event_sea_chart_fragment()` 経由（加算→save→progress_changed の既存報酬フロー準拠）
- 鳥山演出: 新規素材 `assets/showcase/surface/surface_bird_swarm.png`（`tools/generate_surface_showcase_assets.py` の `create_bird_swarm_sprite()`。台帳記入済み）。`surface_cast_view.play_bird_swarm()` で水平線付近に約4秒表示→フェードアウト
- 証拠画像: `docs/qa/evidence/fishing/2026-07-06_e6_bird_swarm_message.png`
- **副産物の既存バグ修正**: 釣行画面メッセージラベルが `autowrap + clip_text + trim` の組み合わせで高さ1pxに潰れ、文字が描画されていなかった（E2の「……ヌシの気配がする。」も不可視だった）。単一行設定へ変更して解消
