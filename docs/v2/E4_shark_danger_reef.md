# V2 / E4. サメ危険海域（釣り側）

正本: `docs/30_v2_expansion_overview.md`（読む順: docs/30 §4 共通仕様 → 本doc）
前提フェーズ: E0・E2・E6（＋サメ素材の品質確認）
状態: 実装完了（2026-07-06）
改訂: 2026-07-06 決定#11〜#13 により、サメのロスターを2種→**9種＋ヌシ＋メガロドン**へ拡張（旧 aozame 案は廃止）。飼育・餌システムは `E10_shark_raising.md` が担当し、本docは**海域・釣り・横取り**のみを扱う

目的: リテンションの環の最終目標。Lv30〜50帯のエンドコンテンツの入口。

## E4-1. 釣り場「危険海域」

`FISHING_SPOTS` に追加（`FISHING_SPOT_ORDER` は `deep_ocean` の後、`harbor_boulder` の前）:

```gdscript
"danger_reef": {
  "id": "danger_reef", "name": "危険海域・鮫の根", "short_name": "危険海域",
  "unlock_level": 30, "required_boat_rank": 3,
  "requires_sea_chart": true,   # 新フィールド
  "depth_range": [18.0, 30.0],
  "description": "海図でしか辿り着けない鮫の根。掛けた魚を横取りされる危険がある。",
  "common_modifier": 0.05,
  "featured_fish": ["hoshizame", "dochizame", "kihada", "kajiki", "ara"],
  "recommended_baits": ["小魚", "大型ルアー"],
  "boss_spot": false,
  "allowed_fish": ["nekozame", "inuzame", "dochizame", "hoshizame",
                   "eporetto", "darumazame", "fujikujira",
                   "shumokuzame", "hohojirozame",
                   "kihada", "mebachi", "kajiki", "ara", "shiira", "kanpachi", "buri"],
  "fish_weight_modifiers": {"nekozame": 1.4, "inuzame": 1.4, "dochizame": 1.6, "hoshizame": 1.6,
                            "eporetto": 0.5, "darumazame": 0.5, "fujikujira": 0.4,
                            "kihada": 0.9, "mebachi": 0.8, "kajiki": 0.9, "ara": 0.8},
  "nushi": {"fish_id": "nushi_danger_reef", "environment_id": "fog", "rig_id": "nomase", "time_slot_id": "", "hint": "霧の日の鮫の根に、白い巨影が出るという……"},
},
```

- 大型2種（shumokuzame / hohojirozame）は `allowed_fish` に載るが、**通常抽選の重みは0**（`fish_weight_modifiers` に載せない＋encounter側で除外）。出現はE10の餌魚システム（好物の餌魚をセットした釣行のみ）で解禁する
- レア3種（eporetto / darumazame / fujikujira）の `min_level` は33、大型2種は38（E0 doc §用途のゲート段差）

## E4-2. 解放フロー（決定: 告知＋海図の両方式）

`fishing_spot_access_status()`（`game_data.gd:222`）に第4引数 `sea_chart_fragments: int = 3` を追加し、レベル・船判定の後に:

```gdscript
if bool(spot.get("requires_sea_chart", false)) and sea_chart_fragments < 3:
    return {"ok": false, "reason": "chart",
        "message": "海図が必要　断片 %d/3" % sea_chart_fragments,
        "detail": "釣行中に流れ着くボトルメールから海図の断片を集めよう。", ...}
```

- マップ表示: Lv30未満は従来どおり「未発見 Lv.30で発見」。Lv30以上かつ断片<3 は「？」アイコン＋上記メッセージ（存在の告知）。断片3で通常表示
- 釣り場マップへのサムネ・ピン追加は `docs/qa/fishing_spot_map_qa.md` のfreeze値と照合してから（マップ追加はフェーズごとに1回）

## E4-3. サメ9種＋ヌシ1体（ロスター確定 2026-07-06）

`FishExpansionData.ROWS` の様式で追加（fish_no は既存の続き。数値は初期値、監査で調整可）:

| id | 名前 | ランク | rarity | fish_no | min_level | size | sell | stamina | power | speed | style | preferred_bait |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| nekozame | ネコザメ | 通常 | アンコモン | No.071 | 30 | 60〜120cm | 900 | 120 | 0.95 | 0.70 | bottom | 岩ガニ |
| inuzame | イヌザメ | 通常 | アンコモン | No.072 | 30 | 60〜110cm | 850 | 110 | 0.90 | 0.75 | bottom | イソメ |
| dochizame | ドチザメ | 通常 | アンコモン | No.073 | 30 | 80〜150cm | 1,000 | 140 | 1.05 | 0.85 | bottom | 小魚 |
| hoshizame | ホシザメ | 通常 | アンコモン | No.074 | 30 | 70〜130cm | 1,400 | 150 | 1.20 | 0.90 | bottom | イソメ |
| eporetto | エポレットシャーク | レア | レア | No.075 | 33 | 60〜100cm | 2,200 | 130 | 0.85 | 0.65 | bottom | 岩ガニ |
| darumazame | ダルマザメ | レア | レア | No.076 | 33 | 30〜55cm | 2,600 | 90 | 0.80 | 1.10 | bottom | 小魚 |
| fujikujira | フジクジラ | レア | レア | No.077 | 33 | 25〜45cm | 3,000 | 80 | 0.70 | 0.95 | bottom | 小魚 |
| shumokuzame | シュモクザメ | 大型 | レア | No.078 | 38 | 200〜350cm | 4,200 | 280 | 1.70 | 1.45 | pelagic_fast | 小魚 |
| hohojirozame | ホオジロザメ | 大型 | レア | No.079 | 38 | 250〜420cm | 5,500 | 320 | 1.90 | 1.50 | pelagic_fast | 小魚 |

- **ヌシ**: `nushi_danger_reef`「深海の白帝」= `hohojirozame` を基準魚として E2-1 の規則で導出。ただしサイズのみ規則の例外で **480〜620cm**（規則値 2.0〜2.6× では巨大すぎるため。例外理由を定数コメントに残す）
- **メガロドンは本フェーズに含まない**（E10 doc。fish_no を振らず特別枠として扱う）
- 全サメエントリに `"shark": true` を付ける（E10 の好物判定・生簀直行の判別用）
- **サメは釣ると生簀へ直行し、インベントリに入らない・売却/料理不可**（`sell` 値はカタログ上の参考値。実装は E10 doc §生簀直行）
- **リリース単位（決定#14）**: E4 と E10 は同時リリース。E4 を単体で先行公開しない（サメが一時的に売却可能になる過渡期と、Lv30以降の経験値源がない期間を露出させないため）。開発順としては E4 完了→E10 着手のままでよい

## E4-4. 横取り（リスク設計の本体）

- 対象: `danger_reef` での**サメ以外**の魚とのファイト
- 決定方式（pure・監査可能）: ファイト開始時に `shark_ambush_plan(rand1, rand2) -> Dictionary` で「この勝負に横取りが起きるか（確率 `SHARK_AMBUSH_CHANCE := 0.22`）」「起きる場合の発動しきい値（魚スタミナ比 0.25〜0.60 の一様乱数）」を先に決める
- 発動: ファイト中に `fish_stamina_ratio()` がしきい値を下回った瞬間、ファイトを強制終了。専用メッセージ「巨大な影が食らいついた！ 獲物を横取りされた……」+ 画面フラッシュ。**魚はロスト（記録なし・インベントリなし）。仕掛け・餌・お金は失わない**
- サメ（`shark: true`）とのファイトでは発生しない
- 釣り場説明・初回入場時メッセージで横取りの存在を予告する（理不尽に感じさせない）

## E4-5. 触ってよいファイル / DoD

- 触る: `game_catalog_data.gd`, `fish_expansion_data.gd`, `game_data.gd`（access status・ambush）, `fishing_screen.gd`（ambush発動・演出）, `fishing_spot_select_screen.gd`（？表示・chart理由）, `player_progress.gd`（`fishing_spot_access_status` ラッパーに断片数を渡す）
- 先行条件: E0・E2・E6完了、サメ素材の品質確認（素材ブリーフは docs/30 §5）
- DoD: `fishing_spot_select_smoke`（Lv/船/海図の3段ロック判定）+ `nushi_encounter_audit` にdanger_reef条件を追加 + ambush分布のheadless監査 + 出現監査（大型2種が通常抽選に**乗らない**ことを含む）+ 釣り場マップvisual QA + validate green
