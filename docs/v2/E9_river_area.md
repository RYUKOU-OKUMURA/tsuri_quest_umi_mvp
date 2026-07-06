# V2 / E9. 川エリア（横展開検証）

正本: `docs/30_v2_expansion_overview.md`（読む順: docs/30 §4 共通仕様 → 本doc）
前提フェーズ: E1〜E8（全機構がカタログ駆動で動いている状態で検証する）
状態: 仕様確定・未着手

方針: 実装は原則カタログ＋素材の追加のみ。**コード変更が必要になった箇所を「横展開の障害リスト」として docs/30 §6 に記録する**のが成果物（別タイトル化のGo/No-Go判断材料）。決定#7: 同一セーブ内の新エリア。

## E9-1. エリアとデータの持ち方

- `FISHING_SPOTS` に `"area": "sea"`（既存全スポットにデフォルト補完）/ `"river"` を追加
- 釣り場マップ左上に「海 / 川」タブ。タブで `area` をフィルタ（マップfreeze照合はこのフェーズ内で1回だけ）
- 川魚は `river_expansion_data.gd` を新設（`fish_expansion_data.gd` と同形式・fish_no は No.081〜）

## E9-2. 川の釣り場（3箇所）

| id | 名前 | unlock_level | 主な魚 |
|---|---|---|---|
| river_rapids | 川瀬 | 3 | オイカワ、カワムツ、ウグイ、アユ、タナゴ |
| river_pool | 淵 | 6 | ヤマメ、イワナ、ニジマス、ウナギ、ナマズ、ニゴイ |
| pond | ため池 | 4 | コイ、フナ、ワカサギ、テナガエビ、ライギョ |

## E9-3. 川魚16種（ステータスは海の類似魚から導出）

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

## E9-4. 淡水の仕掛け（2種）

| id | 名前 | bait_types | unlock_level | price |
|---|---|---|---|---|
| miyaku | ミャク釣り仕掛け | ミミズ、川虫 | 3 | 500 |
| neriuki | 練り餌ウキ仕掛け | 練りエサ | 4 | 700 |

## E9-5. DoD

- 既存smokeの川版一式 + 横展開障害リスト（docs/30へ追記）+ validate green
- 検証の観点: 「encounter/fight/図鑑/依頼/称号/**サメ好物判定（E10のカタログ駆動述語が川魚でも機能するか）**が、コード変更なしに川データで動いたか」。動かなかった箇所が障害リスト行になる
