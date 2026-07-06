# V2 / E8. ザリガニ釣りミニゲーム

正本: `docs/30_v2_expansion_overview.md`（読む順: docs/30 §4 共通仕様 → 本doc）
前提フェーズ: E3（依頼ボードから入る）
状態: 仕様確定・未着手

目的: 箸休めと世界観の広がり（ポリッシュ枠）。専用ファイト機構・専用導線は作らない。

## E8-1. 魚データ

| id | 名前 | rarity | fish_no | size | sell | stamina | power | speed | 特記 |
|---|---|---|---|---|---|---|---|---|---|
| zarigani | アメリカザリガニ | コモン | No.080 | 8〜20cm | 60 | 26 | 0.40 | 0.60 | `"surface_escape": true` |

（fish_no はサメ9種 No.071〜079 の続き。E4より先に着手する場合は No を詰めず予約する）

## E8-2. 変則ルール `surface_escape`（シミュレータへの最小追加）

`fishing_simulator.gd` の深度更新後（L269 付近の depth 減少処理の直後）に:

```gdscript
if bool(_fish_data.get("surface_escape", false)) \
        and depth <= DEPTH_SURFACE_LIMIT and fish_stamina_ratio() > 0.25:
    _escape("水面に出た瞬間、ザリガニが手を離した！")
```

体力を25%未満まで削ってから浮かせないと逃げられる＝「急がば負け」。既存の取り込み条件（distance≤0.8 かつ stamina≤0.22）は変更しない。

## E8-3. 釣り場「港の水路」

```gdscript
"harbor_canal": {"id": "harbor_canal", "name": "港の水路", "short_name": "水路",
  "unlock_level": 1, "required_boat_rank": 0, "hidden_on_map": true,
  "depth_range": [1.0, 3.0], "boss_spot": false,
  "allowed_fish": ["zarigani"], "fish_weight_modifiers": {}, "common_modifier": 1.0, ...},
```

- `hidden_on_map: true` を新設し、釣り場マップの列挙から除外（マップfreezeに触らない）
- 入口は依頼ボードのザリガニ依頼札にある「水路へ行く」ボタンのみ → `fishing_screen` を `harbor_canal` で起動

## E8-4. 依頼接続（専用導線を作らない）

- `zarigani_kid` テンプレ（E3 doc §E3-2）: `quest_completed_count >= 5` 以降、掲示リフレッシュ時に15%で出現（同時に1枚まで）。内容「ザリガニを3匹つかまえて！」
- 報酬: お金0。お礼メッセージ＋称号 `zarigani_10` への進行。達成時の文言「ありがとう！ おねえちゃん（おにいちゃん）すごい！」

## E8-5. 触ってよいファイル / DoD

- 触る: `fish_expansion_data.gd`（zarigani行）, `game_catalog_data.gd`（水路・テンプレ）, `fishing_simulator.gd`（§E8-2の1分岐のみ）, `quest_board_screen.gd`（水路ボタン）, `fishing_spot_select_screen.gd`（hidden除外）, `tools/zarigani_flow_smoke.tscn`（新設）
- DoD: `zarigani_flow_smoke`（依頼→水路→捕獲→納品）+ `catch_fanfare_smoke` 退行なし + 既存ファイトsmoke退行なし + validate green
