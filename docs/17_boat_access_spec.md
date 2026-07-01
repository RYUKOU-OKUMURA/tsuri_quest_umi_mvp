# 船アクセス仕様

## 1. 目的

沖の釣り場に「船がないと到達できない」制約を追加し、魚を売って資金を作る意味を中盤以降も維持する。

この仕様では、レベル到達を「釣り場を発見する条件」、船の購入を「実際に出航できる条件」として分ける。レベルだけで沖へ出られる状態にはせず、ただし船の燃料、耐久、航行操作などの重い管理はMVPには入れない。

## 2. 採用方針

- 船は恒久アンロックアイテムとして扱う。
- 船の装備切り替えは持たず、所持している船の最大ランクで出航範囲を決める。
- `unlock_level` は従来通り釣り場の発見・レベル解放を表す。
- `required_boat_rank` は釣り場へ出航するための到達条件を表す。
- 釣り場の魚抽選は従来通り `player_level` と `spot_id` で行い、船は抽選weightに影響しない。
- 釣り場マップUIは、最終的に「Lv不足」と「船不足」を別のロック理由として表示する。

## 3. 釣り場ごとの到達条件

| 釣り場ID | 表示名 | 発見Lv | 必要船ランク | 意図 |
|---|---|---:|---:|---|
| `harbor_pier` | 港内・堤防 | 1 | 0 | 初期ポイント |
| `shallow_sand` | 砂浜・かけあがり | 2 | 0 | 徒歩圏/岸釣り |
| `rock_breakwater` | 岩礁・消波ブロック | 2 | 0 | 徒歩圏/岸釣り |
| `outer_tide` | 港外・潮目 | 3 | 0 | 港外側の岸釣り扱い |
| `south_reef` | 南の岩礁 | 5 | 1 | 小型船の最初の目的地 |
| `bluewater_route` | 外海・回遊ルート | 6 | 2 | 沖釣り船の目的地 |
| `deep_ocean` | 外洋の深場 | 9 | 3 | 終盤の高額目標 |
| `harbor_boulder` | 港の大岩 | 5 | 0 | ぬし導線を船購入で塞がない |

## 4. 船マスター

| 船ID | 表示名 | ランク | 価格 | 到達範囲 |
|---|---|---:|---:|---|
| `skiff` | 小型船・浜風 | 1 | 3600 G | 南の岩礁まで |
| `offshore_boat` | 沖釣り船・潮路 | 2 | 8200 G | 外海・回遊ルートまで |
| `bluewater_boat` | 外洋船・群青 | 3 | 14500 G | 外洋の深場まで |

価格は既存の竿価格 `850 G` / `2600 G` と、Lv.5以降の魚売価を基準に置く。料理によるレベルアップを完全に捨てて売却だけが正解にならないよう、プレイテストで必要に応じて下げる。

## 5. 進行状態

`PlayerProgress` に次を追加する。

```gdscript
var owned_boats: Array[String] = []
```

セーブデータには `owned_boats` を保存する。既存セーブにはこのキーがないため、ロード時は空配列として扱う。

## 6. 判定API

`GameData` は静的な判定を提供する。

```gdscript
func fishing_spot_access_status(spot_id: String, player_level: int, owned_boat_ids: Array) -> Dictionary
func is_fishing_spot_accessible(spot_id: String, player_level: int, owned_boat_ids: Array) -> bool
func get_accessible_fishing_spot_ids(player_level: int, owned_boat_ids: Array) -> Array[String]
```

`PlayerProgress` は現在の進行状態を使うラッパーを提供する。

```gdscript
func fishing_spot_access_status(spot_id: String) -> Dictionary
func can_access_fishing_spot(spot_id: String) -> bool
func buy_boat(boat_id: String) -> Dictionary
```

`fishing_spot_access_status` は、少なくとも `ok`、`reason`、`message`、`detail`、`button_text` を返す。UIはこの結果を使って、Lv不足と船不足を同じロックではなく別理由として表示する。

## 7. UI反映方針

今回の実装では、釣具店で船を購入でき、釣り場選択の右詳細と `ここで釣る` 実行時に船不足を止める。

釣り場マップの本番ブラッシュアップが落ち着いた後に、次を追加する。

- 地図マーカー上で船不足とLv不足の見た目を出し分ける。
- 航路の表示を、船ランク不足の区間だけ弱くする。
- レベルアップ演出では「釣り場を発見」と「船購入で出航可能」を分けて表示する。

## 8. 検証

- Lv.5、船なしでは `south_reef` に出航できない。
- Lv.5、`skiff` 所持では `south_reef` に出航できる。
- Lv.6、`skiff` 所持では `bluewater_route` に出航できない。
- Lv.6、`offshore_boat` 所持では `bluewater_route` に出航できる。
- Lv.9、`offshore_boat` 所持では `deep_ocean` に出航できない。
- Lv.9、`bluewater_boat` 所持では `deep_ocean` に出航できる。
- 船を持っていても、発見Lv未到達の釣り場には出航できない。
- `harbor_boulder` はLv.5で船なしでも挑戦できる。
