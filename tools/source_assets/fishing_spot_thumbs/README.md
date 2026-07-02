# 釣り場サムネイル専用ソース

このディレクトリに `420x184` 以上のPNGを置くと、`tools/generate_fishing_spot_map_assets.py` が `assets/showcase/fishing_spots/thumbs/` へ正規化して出力する。

必要なファイル:

- `harbor_pier.png` — 港内・堤防、小舟、穏やかな港
- `shallow_sand.png` — 砂浜、浅瀬、かけあがり
- `rock_breakwater.png` — 岩礁、消波ブロック、根魚の気配
- `outer_tide.png` — 港外の潮目、流れ、回遊魚の気配
- `south_reef.png` — 南の岩礁、浅い岩棚、サンゴ混じりの海
- `bluewater_route.png` — 外海の回遊ルート、青い沖合、魚影
- `deep_ocean.png` — 外洋の深場、深い藍色、底知れない水深
- `harbor_boulder.png` — 港の大岩、ぬしポイント、大きな岩陰

生成条件:

- 日本語テキスト、UI枠、ラベル、ロック表示を焼き込まない。
- 釣り場の特徴が小さな右詳細サムネイルでも読める構図にする。
- `reference/06_fishing_spot_map_mockup.png` と同じ、明るい海釣りRPGの絵柄に寄せる。
