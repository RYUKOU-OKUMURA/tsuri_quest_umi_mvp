# V2 / E5. 時間帯（朝まずめ・夜釣り）

正本: `docs/30_v2_expansion_overview.md`（読む順: docs/30 §4 共通仕様 → 本doc）
前提フェーズ: E0（朝まずめ=Lv12・夜=Lv15ゲート）
状態: 仕様確定・未着手

目的: 同じ釣り場を別の顔にしてコンテンツを実質倍増する。決定#1: **時間帯は港画面で出港前に選択**（天候=自然の運、時間帯=プレイヤーの選択、の対比）。

## E5-1. データ（`game_catalog_data.gd` に `TIME_SLOT_ORDER` / `TIME_SLOTS`）

| id | 名称 | 解放 | rarity_weight_modifiers | fish_weight_modifiers（主なもの） | 画面効果 |
|---|---|---|---|---|---|
| asa_mazume | 朝まずめ | Lv12 | レア×1.30、アンコモン×1.12 | aji 1.3 / iwashi 1.3 / katsuo 1.2 / buri 1.2 / kanpachi 1.2 / madai 1.15 | 暖色グレーディング（橙） |
| daytime | 日中 | 最初から（デフォルト） | なし | なし | なし（現行そのまま） |
| night | 夜 | Lv15 | なし | tachiuo 2.2 / maanago 2.4 / kinmedai 1.6 / akamutsu 1.5 / mebaru 1.5 / kurosoi 1.5 / suzuki 1.4 / ara 1.3 | 寒色グレーディング（紺）＋暗め |

- `rarity_weight_modifiers` は新概念: 魚の `rarity` 文字列で引く倍率。`fish_weight_modifiers`（魚ID別）と両方適用
- BGM: 各slotに `"surface_bgm_key_override": ""`（空=天候由来のまま）。夜のみ `"calm"` 固定を初期値にする

## E5-2. 抽選への接続

`encounter_weights()` に任意引数 `time_slot_id: String = ""` を追加（5軸目。既存呼び出し互換）。適用は environment と同じパターン: `_time_slot_weight_modifier(fish_id, fish, time_slot_id)` を掛ける。`roll_hooked_fish`（E2）にも `time_slot_id` を通し、`nushi` 節の `time_slot_id` が非空ならヌシ条件に含める。

## E5-3. 港画面の選択UI

- 位置: 「今日の支度」節（`harbor_screen.gd:110` 付近）に、食事バフカードと並ぶ時間帯セレクタ（3ボタン横並び。未解放はロック表示「Lv.15で解放」）
- ヘッダーの状況行（`harbor_screen.gd:63`）は現在ハードコードの飾り文字列。この機会に「時間帯：{選択中}　潮位：{飾りのまま}　風：{飾りのまま}」の形で時間帯のみ実値にする。潮位・風の実データ化はスコープ外
- 選択は `selected_time_slot_id` に保存（docs/30 §4-1）。`begin_fishing_trip()` が `stats["time_slot_id"]` / `stats["time_slot_label"]` を載せる
- 港のスクショ比較を行い、`docs/qa/harbor_qa.md` を新設して選択UIの配置を記録（現状freezeログなし＝低リスク）

## E5-4. 背景・空気感（素材は最小から）

- 全組み合わせの背景素材は**作らない**。まず釣行画面・港画面に時間帯カラーグレーディング（`CanvasModulate` 相当の色乗算+ビネット1枚）で成立するか検証する
- グレーディングで不足と判断した画面だけ、時間帯差し替え背景を素材ブリーフに起こす。判断は実スクショ横並び比較で行い、`docs/qa/` に判断理由を残す

## E5-5. 釣り場マップの「よく釣れる魚」追従

**追従させない**（v1スコープ外と決定済み）。マップは日中基準の表示のまま。将来要望が出たら別スライスで。

## E5-6. 触ってよいファイル / DoD

- 触る: `game_catalog_data.gd`, `game_data.gd`, `harbor_screen.gd`, `player_progress.gd`, `fishing_screen.gd`（グレーディング）, 監査シーン
- DoD: 時間帯別出現監査（asa_mazume でレア重み計が約1.3倍になること等）+ `fishing_reveal_smoke` + 港・釣行のvisual QA（3時間帯スクショ）+ `save_system_verify.sh` + validate green
