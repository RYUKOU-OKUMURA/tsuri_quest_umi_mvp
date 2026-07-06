# V2 / E10. サメ飼育・生簀（V2の目玉機能）

正本: `docs/30_v2_expansion_overview.md`（読む順: docs/30 §4 共通仕様 → 本doc）
前提フェーズ: E4（サメ9種と危険海域が稼働していること）
状態: 仕様確定・未着手（2026-07-06 決定#11〜#13で新設）

## 目的

- 「売る／料理する／**サメの餌にする**」の第3の使い道を作り、**低レア魚を釣る意味**を終盤まで残す
- 釣行の環にコレクション軸を足す: 釣る → 持ち帰る → サメに与える → なつき度が上がる → 新しいサメ・メガロドンへ
- **Lv30→50 帯の主経験値源**（E0 doc §E0-1。餌やり経験値でレベリングと飼育が同時に進む）

決定事項（docs/30 §3-1 #11〜#13）:

- 餌にできるのは**自分で釣った魚のみ**（入手経路が釣りのみなので自動成立。docs/30 §3-3 不変条件を守ること)
- サメ狙いの餌魚（釣行時）と飼育の餌やりの両方で釣った魚を**消費**する。決定#6「消耗品システムは導入しない」の**サメ関連のみの例外**
- メガロドンは飼育軸の頂点: 解放 = **Lv50 ＋ 通常サメ9種の飼育完了（なつき度100）**

## E10-1. 生簀（サメ飼育）のデータモデル

- セーブ: `shark_bonds: Dictionary`（shark_id → なつき度 int 0〜100。docs/30 §4-1）。**これ以外は保存しない**（捕獲済みサメは `caught_counts` で判る。メガロドン解放可否は Lv＋shark_bonds から毎回導出）
- JSONロード時、`shark_bonds` の値は float で返るため読み出し側で必ず `int(...)` を噛ませる（docs/30 §4-1 の型補正の流儀）
- **生簀直行**: `record_catch()` で `shark: true` の魚はインベントリに加算せず、`caught_counts` / `best_sizes` のみ記録（図鑑・称号・記録演出は通常どおり機能する）。`shark_bonds` に未登録なら 0 で登録。CatchFanfare のフォールバック行を「生簀に運ばれた」に差し替える
- サメは売却・料理の対象にならない（市場・調理の一覧構築で `shark: true` を除外）

## E10-2. 好物（カタログ駆動。魚IDのハードコード列挙をしない）

`game_catalog_data.gd` に `SHARK_DIETS`。好物は魚カタログの `style` × `rarity` × `sell_price` の述語で定義し、判定は `game_data.gd` の pure 関数 `is_favorite_food(shark_id, fish_data) -> bool` で行う（E9で川魚が増えても自動で機能する）:

| shark_id | サメ | 好物（述語） | 意図 |
|---|---|---|---|
| nekozame | ネコザメ | style=bottom のコモン | 底物・貝カニ食のイメージ |
| inuzame | イヌザメ | コモン全般 | 小魚・エビ系。一番育てやすい入門枠 |
| dochizame | ドチザメ | コモンの回遊小魚（BIRD_SWARM_FISH_IDS ∩ コモン） | アジ・イワシ・サバなど |
| hoshizame | ホシザメ | 港系スポットの魚（harbor_pier の allowed_fish） | 港の小魚 |
| eporetto | エポレットシャーク | style=bottom のコモン〜アンコモン | 底の小物・甲殻類 |
| darumazame | ダルマザメ | レア全般 | 「レア魚の切り身」枠。レア魚の使い道 |
| fujikujira | フジクジラ | deep_ocean の allowed_fish | 深場の魚 |
| shumokuzame | シュモクザメ | BIRD_SWARM_FISH_IDS（回遊魚）全般 | 回遊魚・大きめの魚 |
| hohojirozame | ホオジロザメ | sell_price 1,000 以上の魚 | 大型魚 |
| megalodon | メガロドン | ヌシ個体（nushi_*）または sell_price 3,000 以上 | ヌシ級・超大型魚のみ |

具体的にどの魚が該当するかは実装時に監査シーンで一覧出力し、意図とズレる魚があれば述語を調整して本表を更新する。

## E10-3. 餌やり（飼育ループ）

`PlayerProgress.feed_shark(shark_id: String, fish_id: String) -> Dictionary` を新設:

1. インベントリから `fish_id` を1匹消費（0匹なら失敗を返す）
2. なつき度加算: 好物 **+8** / それ以外 **+3**（上限100）
3. **餌やり経験値**: 好物 = `food_exp × 2.0`、それ以外 = `food_exp × 1.5` を `gain_exp()` へ（int丸め）。これがLv30→50の主経験値源。1セッション（餌5〜10匹）で800〜1,200入る想定（初期値。`shark_pen_smoke` の出力で調整）
4. なつき度100到達時: 完全成長メッセージ＋称号再計算（`shark_raised_all` 等）
5. 称号再計算と `titles_earned` emit（E1機構）

- 1日（1帰港）あたりの餌やり回数制限は**設けない**（子供向けに面倒を増やさない。経済側は「餌にした魚は売れない」機会費用で自然にバランスする）
- なつき度のマイルストーン演出（25/50/75/100）で生簀のサメ表示が段階的に変わる（稚ザメ→成体。素材はshowcase_sheetのスケール差で表現し、専用素材は作らない）

## E10-4. サメ狙いの餌魚（釣行側。E4の大型2種を解禁する仕組み）

- 出港前（港画面「今日の支度」節）で、危険海域行きのときだけ「餌魚をセット」できる: インベントリから魚1匹を選択
- **セットした餌魚は釣行開始時に消費される**（ボウズでも戻らない。危険海域のリスク設計と一貫）
- 効果（pure関数 `shark_lure_weights(bait_fish_data) -> Dictionary` で重み補正を返し、`encounter_weights()` の `extra_fish_weight_modifiers`（E6で増設済み）に通す）:
  - 餌魚が好物に該当するサメ: 重み **×3.0**
  - 大型2種（shumokuzame / hohojirozame）: 好物の餌魚がセットされている釣行**のみ**抽選テーブルに乗る（基礎重み 0.6 / 0.5）
  - 餌魚なしの釣行: 通常4種＋レア3種のみ（E4-1 の重みどおり）
- メガロドン: E10-6 参照（餌魚システムの延長で出現）

## E10-5. 生簀画面（新画面）

- 新画面 `src/ui/shark_pen_screen.gd`「サメの生簀」。**`skills/ui-screen-build/SKILL.md` の工程に従う**（reference画像 → 素材ブリーフ → 実装 → `docs/qa/shark_pen_qa.md` 新設）
- 導線: 港画面メニューに「サメの生簀」（Lv30未満または捕獲サメ0のときはロック表示「Lv.30／危険海域で解放」）
- 構成の骨子（reference次第で調整）:
  - 水槽ビュー: 捕獲済みサメが泳ぐ（`FightFishAssets` の showcase_sheet を流用。未捕獲はシルエット）
  - サメ選択列: 10枠（9＋メガロドン特別枠）。各枠に名前・なつき度ゲージ・完全成長バッジ
  - 餌やりパネル: インベントリの魚一覧（好物に王冠アイコン）→「あたえる」ボタン。獲得経験値となつき度上昇を都度表示
  - 下部右に共通の「港へ戻る」ボタン（右下規約）
- 日本語テキストのPNG焼き込み禁止（名前・ゲージ・数値はすべてruntime描画）

## E10-6. メガロドン（飼育軸の頂点）

- 解放条件（pure関数 `is_megalodon_unlocked(level, shark_bonds) -> bool`）: **Lv50 かつ 通常サメ9種すべて なつき度100**
- **強さの位置づけ（意図的な設計）**: メガロドンの stamina 600 はヌシ「白帝」の736より低い。**釣り軸の強さの頂点は白帝、メガロドンは「到達すること」自体が価値の儀式的クライマックス**（Lv50＋飼育コンプの末の一戦を、理不尽な難度にしない）。E2-8 の fight_envelope_audit で両者の体感を比較し、逆転が不自然に感じられる場合のみ調整する
- 演出フロー:
  1. 条件成立後の初回帰港時にメッセージ「生簀のサメたちが、深海の何かに怯えている……」（存在の告知）
  2. 危険海域で**ヌシ級の餌魚**（E10-2 の好物述語: nushi_* または sell 3,000以上）をセットした釣行で、ヒットごとに確率 `MEGALODON_ENCOUNTER_CHANCE := 0.08` で出現
  3. データ: `fish_no` なし・`shark: true`・`boss: true`（初回報酬機構流用: 10,000 G）。size 1,200〜1,600cm、stamina 600 / power 2.0 / speed 1.30、`visual_scale` は演出上の上限値で別途調整
  4. 釣り上げると生簀の特別枠に入り、飼育（餌やり）できる。なつき度100で称号 `megalodon` とは別に最終演出（生簀の全サメが揃って泳ぐ）を出す
- メガロドンとのファイトでは横取り（E4-4）は発生しない

## E10-7. 経験値・ペーシングの検証（E0との整合）

`shark_lure_audit` / `shark_pen_smoke` で以下を表出力し、E0 doc の想定（Lv30→50 が50〜70セッション）とズレたら **餌やり経験値の倍率側を**調整する（EXP_REQUIREMENTS 側を先に動かさない）:

- 好物/非好物の餌やり1回あたり経験値の分布（対象魚カタログ全種）
- なつき度100までの必要餌数（好物のみ: 13匹 / 非好物のみ: 34匹）
- 9種コンプまでの概算餌数と、その間に入る総経験値

## E10-8. 触ってよいファイル / DoD

- 触る: `shark_pen_screen.gd`（新設）, `harbor_screen.gd`（導線・餌魚セットUI）, `player_progress.gd`（`shark_bonds`/`feed_shark`/生簀直行）, `game_data.gd` + `game_catalog_data.gd`（SHARK_DIETS・lure/unlock pure関数・メガロドン）, `fish_expansion_data.gd`（megalodon行）, `market_screen.gd`・調理系（`shark: true` 除外の1行フィルタ）, `tools/shark_pen_smoke.tscn` + `tools/shark_lure_audit.tscn`（新設）
- 触らない: `fishing_simulator.gd`（メガロドンも既存パラメータ範囲で表現する）、E4のfreeze済み要素
- DoD:
  1. `shark_pen_smoke`: 捕獲→生簀直行→餌やり→なつき度→経験値→称号の一巡
  2. `shark_lure_audit`: 餌魚あり/なしのサメ出現テーブル比較（大型2種が餌なしで出ないこと）、メガロドン条件成立時のみ出現すること
  3. `save_system_verify.sh`（`shark_bonds` の補完）
  4. 生簀画面の visual QA（`docs/qa/shark_pen_qa.md` 新設）+ validate green

## E10-9. brief分割案

1. brief A: データ層（SHARK_DIETS・feed_shark・生簀直行・好物/解放pure関数）+ 2監査シーン（画面なしで完結）
2. brief B: メガロドン素材（2点）＋生簀画面の素材ブリーフ→生成
3. brief C: 生簀画面実装（ui-screen-build工程。A/B完了後）
4. brief D: 港画面の餌魚セットUI＋導線（C完了後）
