# V2 / E0. レベルキャップ拡張（10→50）

正本: `docs/30_v2_expansion_overview.md`（読む順: docs/30 §4 共通仕様 → 本doc）
前提フェーズ: なし（E1と並走可）
状態: 仕様確定・未着手
改訂: 2026-07-06 決定#10 により旧仕様（10→30）を **10→50 の一括拡張**へ改訂。30キャップは経由しない

## E0-1. 定数変更

- `game_data.gd`: `MAX_LEVEL: int = 50`
- `player_progress.gd`: `EXP_REQUIREMENTS` を51要素へ拡張（index=現在Lv、値=次Lvまでの必要経験値。index 50 は 0）:

```
[0, 60, 85, 115, 150, 190, 235, 285, 340, 400,               # Lv1-9→10（既存値。変更しない）
 460, 520, 580, 640, 700, 770, 840, 910, 980, 1050,          # Lv10-19
 1130, 1210, 1290, 1370, 1450, 1540, 1630, 1720, 1810, 1900, # Lv20-29
 2000, 2100, 2200, 2300, 2400, 2500, 2600, 2700, 2800, 2900, # Lv30-39
 3050, 3200, 3350, 3500, 3650, 3800, 3950, 4100, 4250, 4400, # Lv40-49
 0]                                                           # Lv50 = 上限
```

- Lv10→30 合計 約22,500。終盤の1回の釣行（釣り+料理）で300〜500入る想定で50〜70釣行ぶん
- Lv30→50 合計 約61,750。**主経験値源はE10のサメ飼育ループ**（餌やり経験値＋サメ釣り）を想定し、サメ通いの1セッションで800〜1,200入る設計（E10 doc §経験値）。50〜70セッションぶんで 10→30 帯とペーシングを揃える
- いずれも初期値。`level_curve_audit` で体感調整してよい（docs/30 §4-5）

## E0-2. ステータス成長の減衰（2段ソフトキャップ）

`get_base_stats()`（`player_progress.gd:353`）の線形成長をそのまま50まで伸ばすとファイトが壊れる。**成長ポイント**を導入し、Lv30 で第2の減衰を掛ける:

```gdscript
const GROWTH_SOFT_CAP := 10
const GROWTH_RATE_AFTER_CAP := 0.35
const GROWTH_SOFT_CAP_2 := 30
const GROWTH_RATE_AFTER_CAP_2 := 0.10

func growth_points() -> float:
    if level <= GROWTH_SOFT_CAP:
        return float(level - 1)
    if level <= GROWTH_SOFT_CAP_2:
        return float(GROWTH_SOFT_CAP - 1) \
            + float(level - GROWTH_SOFT_CAP) * GROWTH_RATE_AFTER_CAP
    return float(GROWTH_SOFT_CAP - 1) \
        + float(GROWTH_SOFT_CAP_2 - GROWTH_SOFT_CAP) * GROWTH_RATE_AFTER_CAP \
        + float(level - GROWTH_SOFT_CAP_2) * GROWTH_RATE_AFTER_CAP_2
```

`get_base_stats()` 内の `(level - 1)` をすべて `growth_points()` に置換（`technique` と `focus` は `int(floor(growth_points()))`）。

- **Lv10以下の数値は1bitも変わらない**こと（回帰条件）
- 目安: Lv30 growth=16.0（max_energy 180 / 素の巻力 現Lv10比+34%）、Lv50 growth=18.0（Lv30比でさらに+約4%）。**Lv31〜50 は実質「純ゲート」**であり、ファイトバランスへの影響を最小に抑える

## E0-3. レベルの用途

Lv11以降は主に解放ゲート:

| Lv | 解放 | フェーズ |
|---|---|---|
| 12 | 朝まずめ | E5 |
| 15 | 夜釣り | E5 |
| 20 / 30 / 40 / 50 | 称号（level_20 / level_30 / level_40 / level_50） | E1カタログ |
| 30 | サメ海域の告知＋サメ飼育（生簀）開放 | E4 / E10 |
| 33 | レア枠サメ（エポレット / ダルマザメ / フジクジラ）の出現 | E10 |
| 38 | 大型サメ（シュモクザメ / ホオジロザメ）の出現 | E10 |
| 50 | メガロドン解放条件の片方（もう片方は通常サメ9種の飼育完了） | E10 |

魚の `min_level` は全て10以下のまま変更しない（サメを除く。サメの min_level は E4/E10 doc）。

## E0-4. 触ってよいファイル / DoD

- 触る: `game_data.gd`, `player_progress.gd`, `tools/level_curve_audit.tscn`（新設）
- 触らない: `fishing_simulator.gd`（バランスはgrowth側で吸収）、既存Lv1〜10の必要経験値
- `level_curve_audit` はV2最初の監査シーンなので、**表出力の共通ヘルパを `tools/` に切り出して作る**（docs/30 §4-4。以後の nushi / trip_event / shark_lure / difficulty 監査が使い回す）
- DoD:
  1. `level_curve_audit` でLv1〜50の必要経験値・全ステータスを表出力し、**Lv1〜10が現行値と完全一致**すること
  2. `save_system_verify.sh`（Lv10セーブのロード）
  3. `cooking_flow_smoke`（レベルアップ演出の回帰。`level_up_panel.gd` はgrowth差分をそのまま表示するので変更不要のはず）
  4. validate green
