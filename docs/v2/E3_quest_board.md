# V2 / E3. 依頼ボード（注文システム）

正本: `docs/30_v2_expansion_overview.md`（読む順: docs/30 §4 共通仕様 → 本doc）
前提フェーズ: E1
状態: 完了（2026-07-06）
**本フェーズに含む追加作業（決定#17）**: セーブの**3スロット化**を、本フェーズのセーブスキーマ変更（`quest_board` 等の追加）と同時に実施する（移行を1回で済ませるため）。仕様は `E11_launch_readiness.md` §E11-2（`user://slots/<n>/` 構造、既存セーブは slot 1 へ自動移行、タイトルにスロット選択UI、`save_system_verify.sh` へ移行テスト追加）。brief分割ではデータ層（brief B）とは別スライスにする

目的: 毎回の釣行に「今日の目的」を作る。中盤のダレ（動機のレベル上げ一本化）対策の本命。

設計判断（確定済み）: **受注操作なしの掲示制**。掲示中の3件は常に進行中扱いで、ボード画面で納品/達成報告する。依頼は**納品型**（数量・料理向け）と**記録型**（サイズ条件。インベントリはサイズを持たないため `best_sizes` 判定でスキーマ変更を回避）の2種類。

## E3-1. 画面

- 新画面 `src/ui/quest_board_screen.gd`。**`skills/ui-screen-build/SKILL.md` の工程に従う**（reference画像の用意→素材ブリーフ→実装→`docs/qa/quest_board_qa.md` 新設）
- 導線: 港画面のメニューに「依頼ボード」を追加
- 構成: 木製掲示板背景に依頼札3枚（縦並びまたは横並び。reference次第）。各札に「依頼文 / 進捗（例 2/5） / 報酬 / 納品ボタン」。下部右に共通の「港へ戻る」ボタン（他画面と同じ右下規約）

## E3-2. 依頼テンプレート（`game_catalog_data.gd` に `QUEST_TEMPLATES`）

| id | 種別 | 生成規則 | 依頼文の型 | 報酬（money） |
|---|---|---|---|---|
| bulk_common | 納品型 | 解放済み釣り場の allowed_fish からコモンを1種、n=3〜5 | 「{魚}を{n}匹届けてほしい」 | sell_price × n × 1.6 |
| bulk_uncommon | 納品型 | 同・アンコモン1種、n=2〜3 | 「{魚}を{n}匹。上物を頼む」 | sell_price × n × 1.8 |
| cuisine | 納品型 | RECIPESから1品→allowed_fishの1種、n=1 | 「{料理}にする{魚}を1匹」 | sell_price × 2.0 |
| size_record | 記録型 | 解放済み釣り場の魚1種、目標 = size_min + (size_max - size_min) × 0.62 を5cm単位へ丸め | 「{目標}cm以上の{魚}を釣り上げてくれ」 | sell_price × 2.5 |
| rare_order | 納品型 | Lv8以上で出現。レア1種、n=1 | 「{魚}を探している。金は弾む」 | sell_price × 2.2 |
| zarigani_kid | 納品型 | E8導入後のみ。固定（E8 doc §依頼接続） | 「（子ども）ザリガニをつかまえて！」 | 0 G（称号・お礼文言のみ） |

- 生成: 掲示枠が空いたとき、レベルで重み付けして抽選（Lv7以下: bulk_common 50% / bulk_uncommon 25% / cuisine 15% / size_record 10%。Lv8+: bulk_common 30% / bulk_uncommon 25% / cuisine 15% / size_record 15% / rare_order 15%）。同じ魚の依頼が2枚同時に出ないこと
- **対象魚の除外（docs/30 §3-3 不変条件）**: 依頼の魚抽選から `shark: true` の魚とヌシ（`NUSHI_FISH`）を必ず除外する。サメはE10以降インベントリに入らないため、含めると達成不能依頼になる（記録型 size_record も同様に除外。`quest_board_smoke` に「danger_reef 解放済み状態でサメ依頼が生成されない」検証を含める）
- pure関数: `generate_quest(template_weights_context) -> Dictionary` と `quest_progress(quest, stats) -> Dictionary` を `game_data.gd` に置き、headlessで検証する

## E3-3. 依頼データの形（セーブされる `quest_board` の要素）

```gdscript
{
  "template_id": "bulk_common",
  "kind": "delivery",          # "delivery" | "record"
  "fish_id": "aji",
  "count": 5,                   # delivery のみ
  "target_size_cm": 40.0,       # record のみ
  "posted_best_cm": 32.0,       # record のみ。掲示時点の自己ベスト
  "reward_money": 960,
  "text": "アジを5匹届けてほしい",
}
```

## E3-4. 達成・納品・リフレッシュ

- **納品型**: ボード画面の「納品」ボタン。`PlayerProgress.deliver_quest(index)` を新設し、インベントリから `count` 匹消費 → `money += reward` → `quest_completed_count += 1` → 称号再計算 → その枠を**即座に新依頼で入替**
- **記録型**: 釣行から帰港した時点で `best_sizes[fish_id] >= target_size_cm` なら達成扱い。ボード画面で「報告」ボタン → 報酬受取 → 枠入替（魚の消費なし）
- 未達成の依頼は掲示され続ける（リフレッシュなし）
- インベントリ不足時の納品ボタンは無効表示（進捗 2/5 を札に出す）

## E3-5. 専用報酬: 依頼限定仕掛け

`quest_completed_count` が10に達した納品時に、店で買えない仕掛けを付与する:

```gdscript
"shokunin": {"id": "shokunin", "name": "職人仕掛け", "price": 0,
  "bait_types": ["イソメ", "オキアミ", "小魚"], "unlock_level": 1,
  "shop_hidden": true, "description": "港の常連たちから贈られた万能仕掛け。"},
```

- `RIGS` / `RIG_ORDER` に追加し、タックルショップの一覧構築側で `shop_hidden` を除外するフィルタを1行追加（`shop_screen.gd`）
- 付与は `owned_rigs.append` + ボード画面でメッセージ表示。既所持なら何もしない

**報酬は お金・称号・限定仕掛けのみ。魚そのものを配らない**（docs/30 §3-3 不変条件）。

## E3-6. 触ってよいファイル / DoD

- 触る: `quest_board_screen.gd`（新設）, `harbor_screen.gd`（導線）, `player_progress.gd`（`quest_board`/`quest_completed_count`/`deliver_quest`）, `game_data.gd` + `game_catalog_data.gd`, `shop_screen.gd`（shop_hiddenフィルタ）, `tools/quest_board_smoke.tscn`（新設）
- 触らない: `market_screen.gd` の売却ロジック（納品は独自にインベントリを減らす）
- DoD: `quest_board_smoke`（生成→納品→入替→限定仕掛け付与の一巡）+ `market_smoke` 退行なし + `save_system_verify.sh` + 新画面visual QA（`docs/qa/quest_board_qa.md` 新設）+ validate green

## E3-7. brief分割案

1. brief A: reference画像・素材ブリーフ→素材生成
2. brief B: 依頼生成・進捗・納品のデータ層 + smoke（画面なしで完結）
3. brief C: ボード画面実装（ui-screen-build工程。A/B完了後）
