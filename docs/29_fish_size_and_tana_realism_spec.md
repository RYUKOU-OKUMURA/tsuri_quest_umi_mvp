# 29. 魚サイズ現実化 & タナ（深さ）挙動修正 指示書

Date: 2026-07-05
状態: 完了（2026-07-05）

Codex（ワーカー）向けの実装指示書。**スライスA（魚サイズ）とスライスB（タナ挙動）は独立した別作業**として扱い、1スライス=1ブランチ/1報告で進めること。両方を1つの変更に混ぜない。

## 背景（なぜやるか）

1. **魚が全体的に大きすぎる。** サイズ抽選が `size_min`〜`size_max` の一様乱数（`game_data.gd` の `roll_fish_size`）で、かつ `size_min` が実釣感覚より一段高い。平均が中間値になるため毎回「良型」が釣れ、小物→たまに大物という釣りの体験が出ない。対象は**全70種**（`game_catalog_data.gd` の30種 + `fish_expansion_data.gd` の40種 No.031–070）。
   - 例外として**ヌシ（ぬし）はあえて伝説サイズを維持する**設計方針（§ヌシのサイズ原則）。現実化の対象は通常個体のみ。
2. **ファイト中にタナが深くなる一方通行。** `fishing_simulator.gd` に `depth` を減らす処理が存在しない（潜水アクションで増えるのみ、`clampf(depth, 2.0, 24.0)` に張り付く）。巻き上げても魚が浮上せず、「タナ 24m のまま釣り上げ成功」が起こる。また画面上部ステータスバーの「水深」表示が `simulator.depth`（＝魚のタナ）をそのまま映しており、タナ表示と同じ値になる仕様矛盾がある。

---

## スライスA: 魚サイズの現実化

### Concern（1つだけ）

魚のサイズ定義と抽選分布を現実的にする。**ファイト挙動・タナ・UIレイアウトには一切触れない。**

### 触ってよいファイル

- `src/autoload/game_catalog_data.gd` — `FISH` テーブルの `size_min` / `size_max` の数値変更、`boss_kurodai` への `size_bias` キー追加のみ
- `src/autoload/fish_expansion_data.gd` — `ROWS` 各行の `size_min` / `size_max` の数値変更のみ（1行1魚の圧縮辞書。その場で数値だけ書き換える）
- `src/autoload/game_data.gd` — `roll_fish_size()` 本体と定数追加のみ
- `src/ui/components/fight_sidebar.gd` — 158行付近の「推定」計算式のみ

拡張40種は `FishExpansionData.all_fish()` → `_build_fish()`（`row.duplicate`）でマージされるため、`ROWS` の数値変更だけで `roll_fish_size` に反映される。**マージロジックの変更は不要・禁止。**

### 触ってはいけないもの

- `docs/qa/*.md` の freeze 表、`assets/` 以下すべて
- `FISH` テーブル・`ROWS` の `size_min` / `size_max` / `size_bias` 以外のキー（`weight`, `sell_price`, `stamina`, `power`, `start_depth`, `visual_scale` 等は変更禁止）
- セーブデータ互換処理。既存セーブの `PlayerProgress.best_sizes` に新最大値を超える記録（例: 90cm クロダイ）が残っていてもよい。**マイグレーションを実装しないこと。**
- `tools/catch_fanfare_smoke.gd` は `result_size_cm` を直接代入しているため影響なし。変更禁止。

### A-1. サイズ表の置き換え（本編30種: `game_catalog_data.gd`）

`game_catalog_data.gd` の各魚の `size_min` / `size_max` を下表の値に置き換える。値はすべて `float` リテラル（例: `12.0`）。「現行維持」の行は編集しない。

| id | 名前 | 現行 | **新 min–max (cm)** | 根拠 |
|---|---|---|---|---|
| aji | アジ | 18–36 | **12.0–40.0** | 豆アジ主体、40cmは「ギガアジ」級 |
| mejina | メジナ | 24–46 | **20.0–50.0** | 50cmで大会級 |
| kasago | カサゴ | 17–34 | **12.0–30.0** | 30cm超はまれ |
| isaki | イサキ | 26–52 | **20.0–45.0** | 45cmで記録級 |
| saba | サバ | 30–58 | **25.0–50.0** | 50cmでほぼ上限 |
| suzuki | スズキ | 42–78 | **30.0–85.0** | セイゴ〜ランカー |
| madai | マダイ | 38–72 | **25.0–85.0** | チャリコ〜大鯛 |
| hirame | ヒラメ | 36–70 | **30.0–85.0** | ソゲ〜座布団 |
| kawahagi | カワハギ | 18–34 | **12.0–30.0** | 30cmは尺カワハギ |
| iwashi | イワシ | 14–24 | **10.0–22.0** | |
| shirogisu | シロギス | 16–29 | **12.0–27.0** | 27cmは「ヒジタタキ」 |
| mebaru | メバル | 18–32 | **12.0–30.0** | 30cm=尺メバルは一生モノ |
| ainame | アイナメ | 28–48 | **20.0–50.0** | |
| bora | ボラ | 38–70 | **30.0–70.0** | トド級まで |
| kamasu | カマス | 28–48 | **20.0–40.0** | |
| kochi | コチ | 35–62 | **30.0–65.0** | |
| tachiuo | タチウオ | 70–115 | **70.0–130.0** | 指3本〜ドラゴン |
| ishidai | イシダイ | 35–62 | **25.0–65.0** | サンバソウ〜老成魚 |
| akahata | アカハタ | 28–48 | **20.0–40.0** | |
| fuefukidai | フエフキダイ | 38–72 | **30.0–70.0** | |
| aobudai | アオブダイ | 45–80 | **35.0–80.0** | |
| kanpachi | カンパチ | 55–95 | **40.0–120.0** | ショゴ〜船の大物 |
| buri | ブリ | 65–110 | **55.0–110.0** | ワラサ級主体 |
| katsuo | カツオ | 45–78 | **40.0–80.0** | |
| shiira | シイラ | 70–125 | **60.0–140.0** | ペンペン〜メーター超 |
| kue | クエ | 65–120 | **50.0–130.0** | |
| hiramasa | ヒラマサ | 70–125 | **60.0–140.0** | |
| rouninaji | ロウニンアジ | 75–135 | **60.0–160.0** | GT |
| kajiki | カジキ | 140–260 | **150.0–330.0** | 演出枠として維持・拡大 |
| boss_kurodai | 港のぬし・大岩クロダイ | 72–94 | **現行維持（72.0–94.0）** | ヌシは伝説サイズが正（§ヌシのサイズ原則）。実在記録超えは意図的 |

`boss_kurodai` にはキー `"size_bias": 0.85,` を `size_max` の直後の行に追加する（意味は A-2 参照。ぬしは大型に偏らせる）。

### A-1b. サイズ表の置き換え（拡張40種: `fish_expansion_data.gd`）

`ROWS` の各行の `size_min` / `size_max` を下表の値に置き換える。「現行維持」の行は編集しない。

| id | 名前 | 現行 | **新 min–max (cm)** | 根拠 |
|---|---|---|---|---|
| mahaze | マハゼ | 12–24 | **8.0–24.0** | デキハゼ〜良型 |
| umitanago | ウミタナゴ | 16–28 | **12.0–28.0** | |
| sappa | サッパ | 10–18 | 現行維持 | |
| konoshiro | コノシロ | 22–34 | **12.0–32.0** | シンコ/コハダ〜コノシロ |
| sayori | サヨリ | 22–40 | **18.0–40.0** | 小型〜閂級 |
| maanago | マアナゴ | 35–70 | 現行維持 | |
| kyusen | キュウセン | 15–28 | **12.0–30.0** | |
| nenbutsudai | ネンブツダイ | 10–18 | **8.0–14.0** | 実際は15cm止まり |
| makogarei | マコガレイ | 25–48 | **18.0–50.0** | |
| ishigarei | イシガレイ | 28–55 | **20.0–60.0** | |
| shitabirame | シタビラメ | 18–34 | **15.0–40.0** | |
| houbou | ホウボウ | 25–45 | **20.0–50.0** | |
| kanagashira | カナガシラ | 18–32 | **15.0–30.0** | |
| megochi | メゴチ | 12–24 | **10.0–22.0** | |
| ishigakidai | イシガキダイ | 30–58 | **20.0–70.0** | サンバソウ〜クチジロ |
| kurosoi | クロソイ | 22–42 | **15.0–55.0** | |
| murasoi | ムラソイ | 16–30 | **12.0–30.0** | |
| takenokomebaru | タケノコメバル | 24–44 | **15.0–45.0** | |
| oomonhata | オオモンハタ | 30–60 | **20.0–60.0** | |
| onikasago | オニカサゴ | 25–48 | **18.0–50.0** | |
| kobudai | コブダイ | 45–90 | **30.0–95.0** | 若魚〜老成コブ |
| sawara | サワラ | 55–95 | **40.0–110.0** | サゴシ〜大サワラ |
| datsu | ダツ | 45–90 | 現行維持 | |
| hirasouda | ヒラソウダ | 35–58 | **25.0–58.0** | |
| suma | スマ | 40–70 | **30.0–75.0** | |
| ojisan | オジサン | 20–36 | **15.0–35.0** | |
| takabe | タカベ | 18–30 | **12.0–28.0** | |
| ira | イラ | 30–55 | **25.0–45.0** | 実際は45cm程度が上限 |
| meichidai | メイチダイ | 28–48 | **20.0–48.0** | |
| shimaaji | シマアジ | 35–75 | **25.0–90.0** | 小型〜「オオカミ」級 |
| tsumuburi | ツムブリ | 55–100 | **40.0–110.0** | |
| gingameaji | ギンガメアジ | 45–85 | **30.0–90.0** | |
| kaiwari | カイワリ | 22–42 | **15.0–40.0** | |
| kihada | キハダマグロ | 90–180 | **60.0–180.0** | キメジ〜本キハダ |
| binnaga | ビンナガ | 75–150 | **60.0–135.0** | 実際は140cm弱まで |
| mebachi | メバチマグロ | 95–190 | **70.0–190.0** | |
| akamutsu | アカムツ | 28–48 | **20.0–50.0** | |
| kinmedai | キンメダイ | 30–55 | **20.0–55.0** | |
| ara | アラ | 60–120 | **40.0–130.0** | |
| medai | メダイ | 45–85 | **35.0–90.0** | |

### A-2. 抽選分布を小型優位に変更

`src/autoload/game_data.gd` の `roll_fish_size()`（現行 380–381 行）を次の実装に置き換える。ファイル内の他の定数群と同じ場所に定数を1つ追加する。

```gdscript
const SIZE_ROLL_EXPONENT_DEFAULT := 2.1  # 大きいほど小型に偏る。1.0で一様分布


func roll_fish_size(fish: Dictionary) -> float:
	var exponent := float(fish.get("size_bias", SIZE_ROLL_EXPONENT_DEFAULT))
	var t := pow(_rng.randf(), exponent)
	return snappedf(lerpf(float(fish["size_min"]), float(fish["size_max"]), t), 0.1)
```

- 期待される性質: `t` の平均は `1/(1+exponent)`。既定 2.1 なら平均約 0.32（＝レンジ下側1/3が典型サイズ、最大級はレア）。`boss_kurodai` は `size_bias 0.85` で平均約 0.54（ぬしは常にそこそこ大きい）。
- 戻り値の snap 0.1 は現行維持。

### A-3. サイドバー「推定」表示の補正

`src/ui/components/fight_sidebar.gd` の推定値計算（現行 158 行、`(size_min + size_max) * 0.5`）は分布変更後は過大評価になる。次に置き換える:

```gdscript
var estimate := lerpf(float(fish_data.get("size_min", 0.0)), float(fish_data.get("size_max", 0.0)), 0.35)
```

表示フォーマット・レイアウトは変更しない。

### スライスA Definition of Done

1. `./tools/validate_project.sh` が成功する。
2. 分布のサニティチェック: 一時スクリプト（コミットしない。`/tmp` 等に置く）で `GameData.roll_fish_size(GameData.get_fish("aji"))` を1000回実行し、(a) 全値が 12.0–40.0 内、(b) 平均が 19–23cm 程度（中間値26より明確に下）であることを headless Godot で確認し、出力を報告に貼る。拡張側の代表として `mahaze` も同様に1000回（全値 8.0–24.0 内・平均 12–14cm 程度）、`boss_kurodai` も1000回（全値 72.0–94.0 内・平均 82–86cm 程度＝大型寄りに偏ること）を確認。
3. headless smoke: `tools/fishing_reveal_smoke.tscn` と `tools/catch_fanfare_smoke.tscn` が従来どおり成功する。
4. 報告: 変更ファイル一覧 / 分布チェック出力 / 未解決事項（あれば）。

---

## ヌシのサイズ原則（設計方針。本指示書の実装対象外）

docs/27 §E2「ヌシシステム」（各釣り場に1体の隠れヌシ）で採用する原則。**スライスAの「現実化」はヌシに適用しない**ためにここに明記する。Codexはこの節を実装しないこと（E2着手時に別指示書で扱う）。

- 通常個体は現実準拠、**ヌシはあえて伝説サイズ**にする。日常のリアリティとの落差がヌシの畏怖・祝祭感を作る
- 目安: その種の典型サイズ（`size_min + (size_max - size_min) × 0.35`）の **2.5〜3倍**、レンジ幅は狭く（±15%程度）、`size_bias: 0.85` で大型寄り
- 例: メバル（典型 ≒ 18cm）のヌシ ≒ 45〜55cm、マダイ（典型 ≒ 46cm）のヌシ ≒ 115〜140cm
- 既存の `boss_kurodai`（72–94cm、クロダイ典型の約2.5〜3倍）はこの原則の先行例。実在記録（≒70cm）超えは意図的であり、「現実化」の対象にしない
- ヌシのサイズは通常個体の `size_max` を必ず超えるようにし、図鑑の金枠バッジ＋ヌシ記録併記（docs/27 決定済み）と整合させる
- 巨大サイズは `visual_scale`・ファイト画面の収まりに直結するため、E2実装時は素材/visual QA フェーズとセットで扱う

---

## スライスB: タナ（深さ）挙動の修正

### Concern（1つだけ）

ファイト中の `depth` に「巻けば浮上する」「残距離以上に深くいられない」という物理を入れ、水深表示の矛盾を直す。**魚サイズ・カタログ数値には一切触れない。**

### 触ってよいファイル

- `src/core/fishing_simulator.gd`
- `src/ui/components/fight_status_bar.gd` — 水深表示のデータソース変更のみ（描画レイアウト・フォント・色は変更禁止）

### 触ってはいけないもの

- `docs/qa/underwater_fight_qa.md` の freeze 表に載っている値（レイアウト・素材・色）。今回はロジックのみで、HUDの見た目・配置は変えない
- `src/ui/components/fight_hud.gd`（タナ表示は現行のまま `simulator.depth` を映す。これが正）
- `src/autoload/game_catalog_data.gd`、`assets/` 以下すべて
- 釣り上げ判定条件 `distance <= 0.8 and fish_stamina_ratio() <= 0.22`（267行）は変更しない

### 前提知識（実装前に読むこと）

- `_simulator.prepare(_current_fish, _trip_stats)`（`fishing_screen.gd:485`）の第2引数 `_trip_stats` が simulator の `player_stats` になる。`_trip_stats` には `fishing_screen.gd:213` で `"spot_depth_range"`（`[min, max]` の Array、単位m）が既に入っている。**fishing_screen 側の変更は不要。**
- 釣り場の水深: `game_catalog_data.gd` の `FISHING_SPOTS` 各エントリの `depth_range`。例: `harbor_boulder`（港の大岩）= `[16.0, 22.0]`。現行バグでは表示水深が 23.7m など釣り場の実水深を超えることがある（ハードコード clamp 24.0 のため）。
- `fight_status_bar.gd` は `trip_stats` を既に保持している（`_spot_title()` が `trip_stats.get("spot_name")` を参照）。

### B-1. 水深（釣り場）と定数の導入

`fishing_simulator.gd` に以下を追加する。

```gdscript
const DEPTH_SURFACE_LIMIT := 1.2         # これ以上は浮かない（水面直下）
const DEPTH_RISE_BASE := 0.55            # 巻き上げ中の基本浮上速度 m/s
const DEPTH_RISE_FATIGUE_GAIN := 1.35    # 魚が疲れるほど浮上が速くなる係数
const DEPTH_DISTANCE_RATIO := 1.15       # 残距離に比例した物理的な最大タナ
const DEPTH_NEAR_OFFSET := 1.0           # 距離0付近でも許す深さの余裕

var water_depth: float = 24.0
```

`prepare()` 内（`initial_depth` を決める前）で水深を確定し、開始タナを水深内に収める:

```gdscript
var depth_range: Array = player_stats.get("spot_depth_range", [])
water_depth = 24.0
if depth_range.size() >= 2:
	water_depth = clampf(float(depth_range[1]), 4.0, 30.0)
initial_depth = clampf(float(fish_data.get("start_depth", 8.0)), 2.0, water_depth - 1.0)
```

（現行 67 行の `initial_depth = maxf(2.0, ...)` はこの式で置き換える。）

### B-2. ファイト中の浮上と深さ上限

`_tick_fight()` 内、現行 253 行の `depth = clampf(depth, 2.0, 24.0)` を次のブロックで置き換える。`stamina_ratio` は同関数冒頭で計算済みの変数を使う。

```gdscript
if reeling:
	depth -= DEPTH_RISE_BASE * (1.0 + DEPTH_RISE_FATIGUE_GAIN * (1.0 - stamina_ratio)) * delta
var depth_ceiling := minf(water_depth, distance * DEPTH_DISTANCE_RATIO + DEPTH_NEAR_OFFSET)
depth = clampf(depth, DEPTH_SURFACE_LIMIT, depth_ceiling)
```

- 意図する挙動: 巻いている間は 0.55 m/s（魚の体力ゼロで約 1.29 m/s）で浮上。潜水アクション（293・307行、変更しない）で一時的に深くなるが、残距離 `distance` が縮むほど上限 `depth_ceiling` が下がるため、寄せた魚は構造的に浮く。釣り上げ条件の `distance <= 0.8` 時点で上限は約 1.9m（水面直下でのフィニッシュ）。
- 潜水アクション・`_update_visual_position` の `dive_shift` はそのまま残す（clamp が抑えるので二重対策不要）。

### B-3. 画面上の魚の縦位置を水深基準にする

現在 `depth / 25.0` を使っている4箇所（`prepare` 72行、`_tick_waiting` 189行、`_tick_approach` 199行、`_update_visual_position` 329行）を、水深で正規化するヘルパーに置き換える:

```gdscript
func _depth_to_view_y(d: float) -> float:
	return lerpf(0.26, 0.82, clampf(d / water_depth, 0.0, 1.0))
```

- 72行: `Vector2(0.26, clampf(_depth_to_view_y(depth), 0.30, 0.78))`
- 189行: `clampf(_depth_to_view_y(initial_depth) + sin(_visual_time * 0.5) * 0.02, 0.30, 0.80)`
- 199行: `Vector2(0.61, clampf(_depth_to_view_y(initial_depth), 0.32, 0.78))`
- 329行: `clampf(_depth_to_view_y(depth) + _motion_value("depth_bias", 0.0), 0.22, 0.84)`

外側の clamp 値は現行のまま。これで浅い釣り場でも魚が画面上部に張り付かず、終盤の浮上が見た目に反映される。

### B-4. ステータスバー「水深」を釣り場の水深に固定

`fight_status_bar.gd` の 77–80 行付近、`depth = simulator.depth` の部分を釣り場水深に変更する:

```gdscript
var depth := 0.0
var depth_range: Array = trip_stats.get("spot_depth_range", [])
if depth_range.size() >= 2:
	depth = float(depth_range[1])
elif simulator != null:
	depth = simulator.depth
```

表示フォーマット `"水深 %.1fm"`・レイアウトは変更しない。これで上部バー「水深」= 釣り場の固定水深、下部HUD「タナ」= 魚の現在深度、という役割分担になる。

### スライスB Definition of Done

1. `./tools/validate_project.sh` が成功する。
2. headless smoke: `tools/fishing_reveal_smoke.tscn`、`tools/fishing_harbor_return_smoke.tscn`、`tools/catch_fanfare_smoke.tscn` が成功する。
3. `./tools/fight_visual_qa.sh` で比較スクショを再生成し、(a) HUD レイアウトが変化していない、(b) 魚の縦位置が破綻していない（画面外・極端な張り付きがない）ことを目視確認。スクショパスを報告に含める。
4. ロジック確認（一時スクリプト、コミットしない）: simulator を直接駆動し、`prepare` →`FIGHT` 状態で `set_reeling(true)` のまま `tick` を回したとき (a) `depth` が単調に減少して `DEPTH_SURFACE_LIMIT` 付近まで到達する、(b) `depth` が常に `water_depth` 以下、(c) `distance` が 1.0 のとき `depth <= 2.15` になることをプリントで確認し、出力を報告に貼る。
5. 報告: 変更ファイル一覧 / smoke・visual QA 結果 / ロジック確認出力 / 未解決事項。

---

## 共通の注意

- 本指示書の数値・式は正本。実装中に矛盾や不都合（clamp の衝突、smoke の失敗など）を見つけたら、**勝手に数値を変えず**、報告に「未解決」として挙げて指示を仰ぐこと。
- コミットメッセージは日本語。スライスA/Bで別コミットにする。
- docs/19（UI制作プレイブック）の不変ルールに従う。今回のスライスはロジック中心だが、B-3 は見た目に影響するため visual QA を省略しない。

---

## 実施結果（2026-07-05）

### マージ結果

- スライスB（タナ挙動）: `d5d7948 ファイト中のタナ挙動を修正`
- スライスA（魚サイズ）: `7df69e6 魚サイズと抽選分布を現実寄りに調整`
- main 統合: `51d8f95 魚サイズ現実化とタナ修正を統合`

### スライスB: タナ（深さ）挙動

- `src/core/fishing_simulator.gd` に釣り場水深 `water_depth`、浮上速度、疲労補正、残距離連動の最大タナ制限を追加。
- `prepare()` で `spot_depth_range` の最大値を釣り場水深として確定し、開始タナを水深内へ収めるように変更。
- 巻き上げ中に `depth` が減少し、魚が疲れるほど浮上しやすくなる挙動を追加。
- 残距離が縮むほど深く潜れないよう `depth_ceiling` を導入。
- 画面上の魚のY位置を固定値 `25.0` 基準ではなく釣り場水深基準に変更。
- `src/ui/components/fight_status_bar.gd` の上部「水深」は釣り場の固定水深、HUD「タナ」は魚の現在深度として分離。

実装時補正:

- 指示書の式 `minf(water_depth, distance * DEPTH_DISTANCE_RATIO + DEPTH_NEAR_OFFSET)` は、終盤に上限が `DEPTH_SURFACE_LIMIT` を下回る可能性があったため、定数は変えずに `maxf(DEPTH_SURFACE_LIMIT, minf(...))` で上限を水面直下1.2m未満に落とさない形にした。

検証:

- `tools/fishing_reveal_smoke.tscn`: ok
- `tools/fishing_harbor_return_smoke.tscn`: ok
- `tools/catch_fanfare_smoke.tscn`: ok
- `TSURI_FIGHT_RUNTIME_CAPTURE=1 ./tools/fight_visual_qa.sh`: ok
- `./tools/validate_project.sh`: ok
- ロジック確認: `start_depth=18.00 water_depth=22.00 final_depth=1.20 final_distance=0.11 ticks=147`
- ロジック確認: `monotonic_depth=true always_under_water_depth=true depth_at_distance_1=1.97 ok=true`
- runtime visual QA で上部「水深 22.0m」、HUD「タナ 18.6m」の役割分離を確認。

### スライスA: 魚サイズの現実化

- `src/autoload/game_catalog_data.gd` の本編30種について、`size_min` / `size_max` を本書の表どおり変更。
- `src/autoload/fish_expansion_data.gd` の拡張40種について、`size_min` / `size_max` を本書の表どおり変更。
- `boss_kurodai` は `72.0–94.0` を維持し、`size_bias: 0.85` を追加。
- `src/autoload/game_data.gd` の `roll_fish_size()` を一様分布から小型優位の指数分布へ変更。
- `src/ui/components/fight_sidebar.gd` の「推定」サイズ計算を中央値から `0.35` 位置の典型値へ変更。

検証:

- サイズ表チェック: 本編30種、拡張40種、`boss_kurodai size_bias=0.85` が本書の表どおり。
- 分布チェック 1000回: `aji min=12.0 max=39.8 mean=20.36 ok=true`
- 分布チェック 1000回: `mahaze min=8.0 max=24.0 mean=13.01 ok=true`
- 分布チェック 1000回: `boss_kurodai min=72.0 max=94.0 mean=84.33 ok=true`
- `tools/fishing_reveal_smoke.tscn`: ok
- `tools/catch_fanfare_smoke.tscn`: ok
- `./tools/validate_project.sh`: ok

### 未解決事項

- 実装上の未解決事項なし。
- `catch_fanfare_smoke` 等で終了時に ObjectDB / resource の既存警告が出るが、各検証コマンドの終了コードは成功。
