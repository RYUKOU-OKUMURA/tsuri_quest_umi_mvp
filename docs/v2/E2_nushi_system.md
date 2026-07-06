# V2 / E2. ヌシシステム

正本: `docs/30_v2_expansion_overview.md`（読む順: docs/30 §4 共通仕様 → 本doc）
前提フェーズ: E1（称号の受け皿）
状態: 仕様確定・実装中

目的: 各釣り場に長期目標を置く。「全釣り場のヌシ制覇」がゲーム全体の中期ゴール。

設計判断（確定済み）: **別魚ID方式**（`nushi_<spot_id>` の独立エントリ、`boss: true` + `nushi: true`）。ただし通常の `FISH` 辞書ではなく新設 `NUSHI_FISH` 辞書に置く。`boss_kurodai` の初回撃破報酬・演出・素材規約をそのまま流用でき、`get_all_fish_ids()`（図鑑ページ列挙・出現抽選の走査元）にヌシを混ぜない。図鑑は「既存魚ページに金枠」なのでヌシに `fish_no` は振らない。

## E2-1. データ: `NUSHI_FISH` 辞書（`game_catalog_data.gd` に新設）

エントリの生成規則（基準魚からの導出。**具体値はこの式で計算して定数に書き下ろす**）:

| 項目 | 規則 |
|---|---|
| `id` | `nushi_<spot_id>`（例 `nushi_harbor_pier`） |
| `name` | 下表の異名 |
| `base_fish_id` | 下表。図鑑金枠の対象ページ |
| `rarity` | `"レア"` 固定（RarityStyles の boss 扱いは `boss: true` で効く）。UI上で「ヌシ」表示が必要な箇所は `nushi: true` を優先して補正する |
| `boss` / `nushi` | 両方 `true`（bossは初回報酬機構の流用、nushiは抽選・図鑑の判別用） |
| `size_min` / `size_max` | 基準魚の `size_max` の 2.0倍 / 2.6倍 |
| `stamina` | 基準魚 × 2.3 |
| `power` | 基準魚 × 1.35（上限 2.0） |
| `speed` | 基準魚 × 0.95 |
| `sell_price` | 基準魚 × 4 |
| `min_level` | 出現スポットの `unlock_level` |
| `fish_no` | **持たせない** |
| 素材・motion系 | 基準魚と同規約で専用素材。`visual_scale` は基準魚 × 1.35 |

## E2-2. ヌシ一覧（E2は通常7体。danger_reef はE4で追加）

| spot | id | 異名 | base_fish_id | 出現条件（天候 × 仕掛け） | 初回撃破報酬 |
|---|---|---|---|---|---|
| harbor_pier | nushi_harbor_pier | 堤防の底主 | maanago | rain × chokusen | 1,200 G |
| shallow_sand | nushi_shallow_sand | 砂底の座布団 | hirame | fog × nomase | 1,500 G |
| rock_breakwater | nushi_rock_breakwater | 磯の黒帝 | ishidai | cloudy × kani | 1,800 G |
| outer_tide | nushi_outer_tide | 潮目の銀狼 | suzuki | rain × nomase | 1,600 G |
| south_reef | nushi_south_reef | 岩窟の老王 | kue | fog × kani | 2,600 G |
| bluewater_route | nushi_bluewater_route | 回遊の大将 | buri | sunny_windy × jigging | 2,400 G |
| deep_ocean | nushi_deep_ocean | 深淵の重鎮 | ara | fog × nomase | 3,200 G |

- `FISHING_SPOTS[spot]` に `nushi` 節を追加: `{"fish_id", "environment_id", "rig_id", "hint"}`。`hint` はNPC目撃情報の文言（例 harbor_pier: 「雨の日、堤防の底で竿を折られた奴がいるらしい…」）
- 初回撃破報酬は `BOSS_FIRST_CLEAR_REWARDS` に7エントリ追加（`money` + `message`）。`record_catch()` は無変更で機能する（`boss: true` 経路）
- 将来E5で時間帯条件を足せるよう `nushi` 節に `"time_slot_id": ""`（空=不問）を最初から置く。E2時点では常に不問
- `danger_reef` の `nushi_danger_reef`（深海の白帝 / `hohojirozame` / fog × nomase / 5,000 G）はE4で追加する。E2のデータ・素材・DoDには含めない

## E2-3. 抽選への接続

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

## E2-4. 予兆演出・ヒント

- 釣行開始時（`begin_fishing_trip` 後の釣行画面初期化時）、条件成立なら画面メッセージ「……ヌシの気配がする。」を1回出す（新画面・新素材なし）
- 港画面「今日の支度」カード内に1行のヒントラベル: 未捕獲ヌシからランダムに1体選び `hint` を表示。全捕獲済みなら非表示

## E2-5. 図鑑表示（金枠バッジ＋ヌシ記録）

- 判定: `caught_counts.has("nushi_<spot>")` で、その `base_fish_id` のページに反映
- 一覧カード: 発見済みカードの右上に小さな金ピン（`Palette.GOLD_BRIGHT`）
- 詳細パネル: 釣果記録スリップに1行追加「ヌシ記録　{異名}　{best_sizes[nushi_id]} cm」+ 詳細枠の外周を金線アクセント
- 未捕獲の「気配」表示は今回はやらない（不採用として `docs/qa/fish_book_qa.md` に記録）

## E2-6. 図鑑フッター「ヌシ」タブ（freeze改訂）

現行freeze（`docs/qa/fish_book_qa.md` §1: 6件、x0 0.032 / step 0.125 / 幅 0.122）のままでは7件目が「港へ戻る」レール（x 0.778〜）に衝突する。**7列用の改訂値**（機能追加に伴う意図的なfreeze改訂として扱う）:

- x0 0.032 / step 0.1065 / 幅 0.104（7件目の右端 = 0.775 < 0.778）
- タブ順: 全魚 / 港内 / 砂浜 / 岩礁 / 沖 / レア / **ヌシ**
- 「ヌシ」フィルタの内容: `NUSHI_FISH` が定義されている `base_fish_id` のページ群
- 手順: 改訂前スクショ → 実装 → `./tools/fish_book_visual_qa.sh` → 横並び比較 → `docs/qa/fish_book_qa.md` のfreeze表を新値へ更新し、改訂理由と比較画像を追記

## E2-7. 触ってよいファイル / DoD

- 実装で触る: `game_catalog_data.gd`, `game_data.gd`, `fishing_screen.gd`（roll差し替え・気配メッセージ）, `fish_book_screen.gd`, `harbor_screen.gd`（ヒント1行）, `market_screen.gd`（ヌシ売却対象の確認・必要時のみ）, `tools/fight_envelope_audit.gd/.tscn`（新設）, `tools/nushi_encounter_audit.gd/.tscn`（新設）
- 素材・記録で触る: `assets/showcase/fish/`（通常7体×2点）, `docs/31_asset_ledger.md`, `docs/qa/fish_book_qa.md`, `docs/qa/evidence/fish_book/`
- 触らない: `player_progress.gd`（セーブ追加なし。`caught_counts` で足りる）, `catch_fanfare.gd`（boss経路で動く）
- DoD: `fight_envelope_audit` でヌシ級ファイト成立を確認 + `nushi_encounter_audit` で「条件成立時のみ約4%、非成立時0%」を確認 + `fish_book_smoke` + `fishing_reveal_smoke` 退行なし + 市場売却経路確認（必要なら `market_smoke`）+ 初回報酬経路確認（必要なら `catch_fanfare_smoke`）+ 図鑑visual QA + validate green

## E2-8. ヌシ級ファイトの成立監査（最初のスライス。2026-07-06 追加）

現行のファイトシステムが検証済みなのは魚スタミナ約240（＋boss_kurodai）まで。ヌシは基準魚×2.3で**500〜736**に達し、検証済みエンベロープの2〜3倍になる。データを本実装する前に、**ヌシ級ステータスでのファイト成立をheadless監査で確認する**:

- `tools/fight_envelope_audit.tscn`（新設）: 仮のヌシ級ステータス（stamina 400 / 550 / 736、power 1.6〜2.0）× プレイヤーLv（10 / 30 / 50 相当の growth）で自動ファイトを回し、**勝率・所要時間・ライン切れ率**を表出力する
- 成立条件の目安: 適正装備・適正Lvで勝率がゼロや100%に張り付かず、所要時間が子供の集中力の範囲（1ファイト2〜3分以内）に収まること
- 崩れていた場合は E2-1 の導出倍率（stamina ×2.3 等）を先に調整してから本実装に入る。`fishing_simulator.gd` は触らない（バランスはデータ側で吸収）
- この監査はE4のサメ（white shark 320 / 白帝 736）・E10のメガロドン（600）の事前検証を兼ねる

## E2-9. brief分割案

1. brief A: **fight_envelope_audit（§E2-8）**。結果をFableがレビューし、必要なら導出倍率を改訂してから以降へ
2. brief B: 素材ブリーフ + 通常7体×2点セット + `docs/31_asset_ledger.md`
3. brief C: NUSHI_FISH/spot nushi節/BOSS_FIRST_CLEAR_REWARDS + `nushi_candidate`/`roll_hooked_fish` + `nushi_encounter_audit`
4. brief D: 図鑑金枠＋ヌシタブ（freeze改訂手順込み）
5. brief E: 気配メッセージ＋港ヒント
6. brief F: ヌシ売却対象の市場接続確認 + 最終DoD検証
