# E2 ヌシ魚素材ブリーフ

Date: 2026-07-06

対象フェーズ: `docs/v2/E2_nushi_system.md`
対象素材: 通常7釣り場のヌシ魚 `card_portrait` / `showcase_sheet`
出力先: `assets/showcase/fish/`
生成ツール: `tools/generate_nushi_fish_assets.py`

## 目的

E2のヌシを、通常魚の単なるステータス違いではなく「その釣り場の長期目標」として読ませる。図鑑・ファイト画面のどちらでも基準魚との血縁は残しつつ、巨大さ、古株感、金枠にふさわしい特別感が見える専用素材にする。

## 対象

| ヌシID | 基準魚 | 方向性 |
|---|---|---|
| `nushi_harbor_pier` | `maanago` | 暗い金褐色、古傷、底物のぬめり |
| `nushi_shallow_sand` | `hirame` | 砂地に溶ける大判、濃い斑紋 |
| `nushi_rock_breakwater` | `ishidai` | 黒帝らしい太い縞と金縁 |
| `nushi_outer_tide` | `suzuki` | 銀青の横走り、鋭い背線 |
| `nushi_south_reef` | `kue` | 岩窟の老王、重い褐色と傷 |
| `nushi_bluewater_route` | `buri` | 回遊魚の青金、速さのある側線 |
| `nushi_deep_ocean` | `ara` | 深場の紫影、暗い斑点 |

## 生成方針

- 既存のAI生成魚素材を基準に、PILで色調・スケール・斑紋・薄い発光影を加えるプロシージャル派生とする。
- 日本語テキスト、魚名、No.、ラベル、カード枠、背景をPNGに焼き込まない。
- `card_portrait` は図鑑カード/詳細での主役感を優先する。
- `showcase_sheet` は既存の8フレーム形式（2560x320）を維持し、ファイト画面で破綻しない透明背景の魚単体にする。
- 魚種識別は基準魚から保つ。色違いだけに見えないよう、ヌシごとに傷・斑紋・側線を変える。

## 採用条件

- 基準魚と並べたとき、同一魚種の巨大な個体として読める。
- 図鑑カードの小サイズでも、ヌシ固有の金ピン/金枠と合わせて特別感が出る。
- 透明境界に白フチ、黒い矩形、強すぎるハロが残らない。
- 既存 `FightFishAssets` 経由で読み込める命名規約に合う。
- `tools/verify_fight_fish_assets.gd` と `./tools/validate_project.sh` を通す。

## 不採用条件

- 元魚が識別できないほど色や形が変わる。
- 発光や傷がUIテキスト・ゲージの視認性を邪魔する。
- 1体だけ質感が浮き、魚素材群の文法が揃わない。
- テキストや枠が焼き込まれてruntime UIと二重化する。

## 評価手順

1. `python3 tools/generate_nushi_fish_assets.py` を実行する。
2. `tools/source_assets/fish/nushi_e2_contact_sheet.png` で7体を横断確認する。
3. `Godot --headless --path . res://tools/verify_fight_fish_assets.tscn` 相当の魚素材検証を実行する。
4. 図鑑実装後、`./tools/fish_book_visual_qa.sh` の横並び比較でヌシタブ/金枠と合わせて確認する。
