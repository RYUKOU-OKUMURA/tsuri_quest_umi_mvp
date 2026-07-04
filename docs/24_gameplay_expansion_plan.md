# 24. ゲーム拡張 実装計画（ブラッシュアップメモ対応）

作成日: 2026-07-03
更新日: 2026-07-04
対象メモ:

> - 釣り上げた時の「パパパラパッパパーン」的な演出
> - 釣具店画面の実装（竿や仕掛けの種類や設定）
> - 狙う魚で仕掛けを変える仕様設定の実装
> - 釣れる魚を増やす（当初30種→50種、P4実装時に70種へ拡張）
> - 料理でお金が発生する設定の実装
> - 魚市場画面の実装（魚を売る時の仕様：1匹・1種類全部・複数選択・全部）
> - 天気のパターン増やす

UI作業のルール正本は `docs/19_ui_production_playbook.md`。本docはゲームシステム拡張の設計・順序を定めるもので、UI品質判断はdocs/19に従う。

---

## 1. 現状把握（コード上の事実）

| 項目 | 現状 |
|---|---|
| 魚データ | 既存30種は `GameData.FISH`、P4追加40種は `FishExpansionData.ROWS`。全70種を `GameData.get_all_fish_ids()` / `get_fish()` 経由で扱う |
| 釣り場 | 8スポット。各スポットに `recommended_baits`（表示用）と `fish_weight_modifiers`（出現重み補正）あり |
| 出現抽選 | `GameData.encounter_weights()` → `roll_normal_fish()`。軸は「レベル × 釣り場 × 仕掛け × 天候」。ぬし専用ポイントでは仕掛け補正と天候補正を掛けない |
| 天気 | `FISHING_ENVIRONMENTS` に6環境（天気は `sunny / partly_cloudy / cloudy / rain / fog` の5系統）。釣行開始時に重み抽選し、`fish_weight_modifiers` で出現テーブルへ接続済み |
| 竿・仕掛け | `RODS` 5本、`RIGS` 6種。竿はファイト性能補正、仕掛けは出現重み補正と釣行前装備に接続済み |
| 釣具店画面 | `src/ui/shop_screen.gd`。**P2実装完了**。PNGメインUIで竿5本・仕掛け6種の購入/装備、タブ切替、詳細表示を扱う |
| 魚市場画面 | `src/ui/market_screen.gd`。**P6実装完了**。PNGメインUIで数量指定・1種類全部・複数選択・全部選択・確認つき一括売却を扱う |
| 料理 | `RECIPES` 5種。`cook_and_eat()` で経験値＋次釣行バフ。**お金は一切発生しない** |
| キャッチ結果 | **P0実装完了**。成功時は写真風の釣り上げ結果画面（`CatchFanfare`）を表示し、旧テキスト結果パネルは出さない。失敗時のみ既存の「逃げられた……」結果パネルを維持 |
| 魚素材 | `assets/showcase/fish/` に `<id>_card_portrait.png` と `<id>_showcase_sheet.png` の2点セット×70種。`FightFishAssets` が命名規約で解決 |
| 参照画像 | 釣具店は `reference/09_tackle_shop_rod_mockup.png` / `reference/09_tackle_shop_gear_mockup.png`、魚市場は `reference/10_fish_market_mockup.png` を正規参照に設定済み |
| セーブ | `PlayerProgress.save_game()/load_game()`。仕掛けの `owned_rigs` / `equipped_rig_id` は旧セーブ読み込み時に `sabiki` で補完済み。新フィールド追加時は同様にデフォルト値の手当てが必要 |

---

## 2. 依存関係と推奨実装順序

### 依存グラフ

```
[P1 仕掛けシステム(データ+ロジック)] ──┬─→ [P2 釣具店 正式化]
                                        ├─→ [P4 魚 30→70種]（出現軸が揃ってから）
[P3 天気パターン追加] ──────────────────┘
[P6 魚市場 正式化] …… P5非依存。P4魚データ・魚素材完了後に実装
[P5 調理費用] …… MVP保留。将来の難易度設定で再検討
[P0 キャッチ演出] …… 依存なし（いつでも差し込み可）
```

### 推奨順序

| フェーズ | 内容 | 種別 | 規模感 |
|---|---|---|---|
| **P0** | キャッチ演出（ファンファーレ） | 演出 | **完了** |
| **P1** | 仕掛けシステム：データモデル＋出現抽選への接続＋最小UI | システム | **完了** |
| **P2** | 釣具店画面の正式化（竿＋仕掛け販売） | UI正式化 | **完了** |
| **P3** | 天気パターン追加（雨・曇り等＋出現補正） | データ＋演出 | **完了** |
| **P4** | 魚 30種→70種 | データ＋素材 | **完了** |
| **P5** | 調理費用（料理を食べるのにお金を払う） | システム | **MVP保留** |
| **P6** | 魚市場画面の正式化＋売却仕様拡張 | UI正式化 | **完了** |

### 順序の理由

1. **P0を最初に置く理由**: 依存ゼロ・低リスクで、以降の全フェーズの手触り確認が楽しくなる。P1以降の検証プレイでも毎回目にする部分なので、投資対効果が最も早く回収される。
2. **P1が土台だった理由**: 仕掛けが入ったことで (a) 釣具店に並べる商品ラインナップができ、(b)「狙う魚で仕掛けを変える」ゲーム性が生まれ、(c) 魚を増やしたときの出現条件の軸になった。魚データに `preferred_bait`、釣り場に `recommended_baits` が既にあったため、既存データを活かして完了できた。
3. **P2をP1直後に置いた理由**: P1で仕掛けデータと購入/装備処理が固まったため、簡易shop画面への一時的な作り足しを長引かせず、竿＋仕掛けを扱う正式画面へ統合できた。
4. **P3はP4より先**: 天気×仕掛け×釣り場の3軸が揃ってから魚を増やすほうが、追加魚に「このエリアで狙う」「この仕掛けが合う」「この天候で少し有利」の個性を配れる。軸がないまま魚種だけ増やすと釣り場ごとの出現テーブルが薄まって単調になる。
5. **P5はMVP保留、P6は単独実装へ変更（2026-07-04）**: 調理費用は序盤難度を上げるためMVPでは入れない。将来の難易度設定（ふつう/むずかしい等）で、料理にも費用がかかる経済ルールとして再検討する。P6の市場正式化は、魚を装備・船の資金へ換える導線としてP5非依存で進める。

---

## 3. フェーズ別 詳細計画

### P0. キャッチ演出（パパパラパッパパーン） — **実装完了（2026-07-03）**

**ゴール**: 魚を釣り上げた瞬間に達成感のあるファンファーレ演出が入る。レアリティが高いほど豪華。

**実装結果**
- 成功時の旧白い結果ポップアップを廃止し、写真風の釣り上げ画面をそのまま結果選択画面に統合した。
- `src/ui/components/catch_fanfare.gd` が `continue_requested` / `harbor_requested` を発火し、`fishing_screen.gd` が既存の次釣行・港遷移へ接続する。
- 魚画像は引き続き `FightFishAssets.card_portrait_path()` 経由で解決し、魚なし写真風ベース `assets/showcase/underwater/catch_photo_base.png` の上へruntime合成する。
- `続けて釣る` / `港へ戻る` は写真風画面下部のruntimeボタンへ統合した。成功時は自動終了せず、プレイヤー選択待ちにする。
- 失敗時の `逃げられた……` 結果ポップアップは現状維持。

**変更箇所**
- `src/ui/fishing_screen.gd` `_on_fight_finished(caught=true)` → `PlayerProgress.record_catch()` 後に `CatchFanfare.play(...)` を表示し、成功時の旧結果パネルは出さない
- `src/ui/components/catch_fanfare.gd` → 写真風成功結果画面、魚合成、結果テキスト、下部2ボタン、キーボード入力、短いファンファーレ音を担当

**採用した演出シーケンス**
1. 画面フラッシュ（白 0.1s）＋ SE「ジャジャーン」
2. 「釣り上げた！」帯バナーがスケールインで登場
3. 魚ポートレート（`FightFishAssets.card_portrait_path()` 流用）がスライドイン
4. 魚名・サイズ・レアリティ・初回記録/報酬を写真内のruntimeテキストとして表示
5. 下部の `続けて釣る` / `港へ戻る` で結果フローを完結

**当初案からの変更**
- 成功後の選択UIまで新画面へ統合したため、短時間の自動終了と `スキップ` は廃止した。
- 手前手マスク分割素材案は品質不足で不採用。魚なし高品質ベース1枚＋既存魚ポートレート前面合成を採用した。

**素材**
- `assets/showcase/underwater/catch_photo_base.png`
- 日本語テキストと魚本体はPNGへ焼き込まない。文字はruntime描画、魚は `FightFishAssets.card_portrait_path()` 経由。
- 専用SE素材は未追加。P0では `AudioStreamGenerator` による短い合成ファンファーレで音の経路を成立させた。

**検証**
- `godot --headless --path . res://tools/catch_fanfare_smoke.tscn`
- `./tools/fight_visual_qa.sh`
- `./tools/validate_project.sh`
- 証拠画像: `docs/qa/evidence/underwater_fight/2026-07-03_catch_result_photo_boss.png` / `2026-07-03_catch_result_photo_aji.png` / `2026-07-03_catch_result_harbor_button_align.png`

**完了条件**: **完了**。通常魚とぬし魚で魚差し替えが成立し、成功後の連続釣行・港戻りが新画面から操作できる。成功時の旧結果パネルは出ず、失敗時の旧結果パネルは維持される。

**関連コミット**
- `6c3329a5` 釣り上げ成功画面を結果操作に統合
- `3a221b73` 釣り上げ結果画面の不要コードを削除
- `c6481ce7` 釣り上げ結果の港ボタン位置を調整

---

### P1. 仕掛けシステム（狙う魚で仕掛けを変える） — **実装完了（2026-07-03）**

**ゴール**: プレイヤーが釣行前に仕掛けを選び、選択によって釣れる魚の傾向が変わる。

**実装結果**
- `GameData.RIGS` / `RIG_ORDER` / `DEFAULT_RIG_ID` を追加し、6種の仕掛け（サビキ、ウキ、胴突き、泳がせ、ルアー・ジグ、カニ餌）を買い切り装備として定義した。
- `GameData.encounter_weights(player_level, spot_id, rig_id)` と `roll_normal_fish(..., rig_id)` に仕掛け補正を接続した。`preferred_bait` が装備仕掛けの `bait_types` に含まれる場合は **×2.5**、含まれない場合は **×0.4**。ぬし専用ポイントは補正対象外。
- `PlayerProgress` に `owned_rigs` / `equipped_rig_id` / `buy_or_equip_rig()` を追加し、`save_game()` / `load_game()` で旧セーブは `sabiki` 所持・装備へ補完する。
- `fishing_spot_select_screen.gd` に装備中の仕掛け表示と所持仕掛けの切替導線を追加し、釣行開始時の `trip_stats` と水中ファイトへ装備仕掛けを渡す。
- `shop_screen.gd` 側にも仕掛けの購入/装備処理を接続し、P2の釣具店正式化の土台にした。

**検証**
- `tools/fishing_spot_encounter_audit.gd` で仕掛けマスタ、全魚の `preferred_bait` カバー、通常ポイントの仕掛け補正、ぬし専用ポイントの補正無効を検証。
- `tools/fishing_spot_select_smoke.gd` で所持仕掛け切替、釣行継続時の仕掛け反映、旧セーブ読み込み時の `sabiki` 補完を検証。
- `docs/05_データ仕様.md` / `docs/09_パラメータ調整表.md` / `docs/15_fishing_spot_encounter_spec.md` に仕掛け仕様を反映済み。

**完了条件**: **完了**。同じ釣り場で仕掛けを変えると釣果傾向が変わり、全釣り場×全仕掛けで抽選が空にならない。旧セーブは `sabiki` 装備で継続できる。

**関連コミット**
- `836f78b7` P1: 仕掛けデータと選択UIを釣行・ショップへ接続

---

### P2. 釣具店画面の正式化 — **実装完了（2026-07-04）**

**ゴール**: 簡易実装の `shop_screen.gd` を、竿＋仕掛けを扱う本番品質の画面へ置き換える。

**実装結果**
- `reference/09_tackle_shop_rod_mockup.png` / `reference/09_tackle_shop_gear_mockup.png` を正規参照に設定し、店主なし・商品陳列主役の釣具店UIへ正式化した。
- `shop_screen.gd` をPNG backplate + runtime文字/状態/クリック領域の構成に置き換え、竿/仕掛けタブ、商品カード、詳細紙面、購入/装備ボタン、港戻り導線を実装した。
- 竿は5本、仕掛けは6種を扱い、所持/装備中/所持金不足/Lv不足をruntime表示で切り替える。仕掛け詳細では対応エサカテゴリと代表魚を表示する。
- 1280x720の `TackleShopDesignCanvas` に素材・文字・透明Buttonを閉じ込め、広いviewportでも座標がずれないようにした。

**素材**
- `assets/showcase/tackle_shop/shop_rod_backplate.png`
- `assets/showcase/tackle_shop/shop_rig_backplate.png`
- `assets/showcase/tackle_shop/shop_item_icon_sheet.png`
- `assets/showcase/tackle_shop/shop_bait_icon_sheet.png`
- `assets/showcase/tackle_shop/shop_detail_item_sheet.png`

**QA運用**
- `docs/qa/tackle_shop_qa.md` にfreeze表・不採用リスト・微調整カウンタ・判断ログを記録済み。
- visual QAスクリプト `tools/tackle_shop_visual_qa.sh` と比較画像生成を追加済み。
- 証拠画像: `docs/qa/evidence/tackle_shop/2026-07-04_tackle_shop_rod_label_alignment_compare.png` / `2026-07-04_tackle_shop_rig_label_alignment_compare.png` / `2026-07-04_tackle_shop_rod_label_alignment_expanded.png` / `2026-07-04_tackle_shop_rig_label_alignment_expanded.png`
- `tools/audit_showcase_asset_refs.py` の所有ルールに `assets/showcase/tackle_shop/` を追加済み。

**検証**
- `./tools/tackle_shop_visual_qa.sh`
- `godot --headless --path . res://tools/tackle_shop_smoke.tscn`
- `godot --headless --path . res://tools/status_smoke.tscn`
- `./tools/validate_project.sh`
- Godot終了時に既存のObjectDB/resource警告あり。

**完了条件**: **完了**。docs/19 §のv1完了条件（実スクショ×参照画像の横並び比較）を満たし、既存smoke＋購入/装備フローが動作する。

**残ギャップ**
- 詳細大絵は既存backplateからの透過切り抜き拡大でv1採用。看板品質へ上げる場合は、11商品分の専用高解像度詳細絵を将来の素材フェーズで作る。

**関連コミット**
- `f2e560ba` 釣具店画面をPNGメインUIに正式化
- `736fef22` Update tackle shop assets and UI for no-shopkeeper version
- `f8b3c7bf` Enhance tackle shop UI and functionality for expanded viewports
- `ede4e534` Refine tackle shop UI layout and label positioning for improved readability

---

### P3. 天気パターン追加 — **実装完了（2026-07-04）**

**ゴール**: 快晴のみ→ 複数天候（快晴/晴れ曇り/曇り/小雨/霧）＋風の強弱の組み合わせにし、天候が釣果と画面の見た目に影響する。

**実装結果**
- `FISHING_ENVIRONMENTS` を6環境へ拡張した。天気系統は `sunny / partly_cloudy / cloudy / rain / fog` の5つで、`sunny_windy` は既存互換の快晴・風強枠として残した。
- 各環境に `fish_weight_modifiers` を追加し、通常魚抽選の最終式を `魚weight × 釣り場補正 × 仕掛け補正 × 天候補正` に統一した。
- `encounter_weights(player_level, spot_id, rig_id, environment_id)` と `roll_normal_fish(..., environment_id)` に後方互換ありで天候引数を追加した。
- `FishingScreen` は `trip_stats.environment_id` を通常魚抽選へ渡す。釣行継続/釣り場変更では既存 `trip_stats` を保持するため、同じ釣行中の天気は変わらない。
- `SurfaceCastView` は既存の状態別シーンPNGを描いた後、`trip_stats.weather_id` に応じて天候grade/overlayを重ねる。上部/右/下部UIのfreeze値は変更していない。
- READY状態だけは、`trip_stats.weather_id` に応じた天気専用フル画像5枚をruntime採用した。CASTING/WAITING/APPROACH/BITE は既存状態別PNG + 天候grade/overlayを維持する。
- `FightStatusBar` は天気ラベルだけでなく、`weather_status_icon_sheet.png` から天気アイコンも `weather_id` に追従して描画する。

**素材**
- `assets/showcase/surface/surface_scene_ready_sunny.png`
- `assets/showcase/surface/surface_scene_ready_partly_cloudy.png`
- `assets/showcase/surface/surface_scene_ready_cloudy.png`
- `assets/showcase/surface/surface_scene_ready_rain.png`
- `assets/showcase/surface/surface_scene_ready_fog.png`
- `assets/showcase/surface/surface_weather_contact_sheet.png`
- `assets/showcase/surface/surface_weather_partly_cloudy_grade.png`
- `assets/showcase/surface/surface_weather_cloudy_grade.png`
- `assets/showcase/surface/surface_weather_rain_grade.png`
- `assets/showcase/surface/surface_weather_rain_overlay.png`
- `assets/showcase/surface/surface_weather_fog_grade.png`
- `assets/showcase/surface/surface_weather_fog_overlay.png`
- `assets/showcase/underwater/weather_status_icon_sheet.png`

**QA運用**
- 水面READYの天気別preview/visual QAとして `tools/surface_weather_preview.tscn` / `tools/surface_weather_visual_qa.sh` を追加した。
- 採用証跡: `docs/qa/evidence/underwater_fight/2026-07-04_surface_weather_asset_contact_sheet.png` / `docs/qa/evidence/underwater_fight/2026-07-04_surface_weather_ready_compare.png` / `docs/qa/evidence/underwater_fight/2026-07-04_surface_scene_ready_weather_runtime_compare.png` / `docs/qa/evidence/underwater_fight/2026-07-04_surface_weather_status_icon_compare.png`
- `docs/qa/underwater_fight_qa.md` にfreeze条件・判断ログを記録済み。

**検証**
- `tools/fishing_spot_encounter_audit.gd` に環境マスタ、天候補正倍率、全釣り場×全仕掛け×全天候の抽選可能性、ぬし専用ポイントの天候補正無効を追加。
- `./tools/surface_weather_visual_qa.sh`
- `godot --headless --path . --script res://tools/fishing_spot_encounter_audit.gd`
- `./tools/fight_visual_qa.sh`
- `./tools/validate_project.sh`

**完了条件**: **完了**。釣行ごとに天候が変わり、見た目と釣果傾向の両方に差が出る。天候ラベルと天気アイコンは上部ステータスに表示され、天候別水面READYスクショで晴れ・曇り・雨・霧の差を確認できる。

**P3対象外・後続候補**
- 天候SE、時間帯、専用雨BGM、釣り場選択画面での事前予報UIはP3完了条件に含めない。BGMは既存 `calm` / `windy` へのフォールバックで完了扱い。
- READY以外の CASTING/WAITING/APPROACH/BITE は専用天気画像を量産せず、既存状態別PNG + 天候overlay/gradeのフォールバックで完了扱い。専用画像化は将来の見た目polish候補とする。

---

### P4. 魚を増やす（30種→70種） — **実装完了（2026-07-04）**

**ゴール**: 既存30種を全て続投し、日本近海・海釣り対象魚の追加40種を入れて全70種にする。ぬし追加はしない。

**採用方針**
- 既存30種は `GameData.FISH` のまま維持し、追加40種は `src/autoload/fish_expansion_data.gd` の `FishExpansionData.ROWS` に分離する。
- `GameData.get_fish()` / `get_all_fish_ids()` / `encounter_weights()` は既存魚と追加魚を透過的に扱う。画面側は70種化を意識しない。
- ぬし専用の `harbor_boulder` を除く7通常エリアに、低レベル共通魚10種 + エリア限定魚8〜9種を配置する。
- 低レベル共通魚は `aji / mejina / kasago / iwashi / shirogisu / isaki / kawahagi / mebaru / ainame / bora`。全通常エリアに混ざる。
- 共通魚とぬし以外は原則1エリア限定。竿限定ではなく、エリア限定 + 仕掛け相性 + 天候補正で狙い分けを作る。
- ユーザー希望のコブダイは `kobudai` として岩礁・消波ブロックに配置する。

**1種あたりに必要なもの**（既存30種のデータ構造より）
1. `FISH` エントリ一式: 基本値・ファイトパラメータ（`motion` / `action_profile`）・**行動メッセージ4種**（日本語）・`preferred_bait`・`fish_no`
2. 素材2点: `<id>_card_portrait.png` ＋ `<id>_showcase_sheet.png`（`assets/showcase/fish/` 命名規約。`FightFishAssets` が自動解決するのでコード改修不要）
3. 釣り場への配置: `allowed_fish` / `fish_weight_modifiers` / 必要なら `featured_fish`
4. レシピ対応: `allow_all_fish` を持つ基本レシピで全魚を受け、専用レシピは従来どおり個別リストで調整する

**追加40種の配置**

| 釣り場 | 追加魚 |
|---|---|
| 港内・堤防 | マハゼ、ウミタナゴ、サッパ、コノシロ、サヨリ、マアナゴ、キュウセン、ネンブツダイ |
| 砂浜・かけあがり | マコガレイ、イシガレイ、シタビラメ、ホウボウ、カナガシラ、メゴチ |
| 岩礁・消波ブロック | イシガキダイ、クロソイ、ムラソイ、タケノコメバル、オオモンハタ、オニカサゴ、コブダイ |
| 港外・潮目 | サワラ、ダツ、ヒラソウダ、スマ |
| 南の岩礁 | オジサン、タカベ、イラ、メイチダイ |
| 外海・回遊ルート | シマアジ、ツムブリ、ギンガメアジ、カイワリ |
| 外洋の深場 | キハダマグロ、ビンナガ、メバチマグロ、アカムツ、キンメダイ、アラ、メダイ |

**管理方針**
- 追加魚の基本値は `FishExpansionData.ROWS` の1行を増減するだけで管理する。`style` から `motion` / `action_profile` / `action_messages` を生成し、似た行動の魚をまとめて調整できるようにする。
- 素材生成は `tools/process_underwater_fish_assets.py` の `FISH_ART_SOURCES` にテンプレート・色・模様を登録する。個別アートができた魚は `tools/source_assets/fish/<id>_final_art_source.png` を置けば差し替わる。
- 出現配置の不整合は `tools/fishing_spot_encounter_audit.gd` で検出する。70種数、魚番重複、共通魚の全エリア配置、エリア限定、料理/売却/到達可能性を監査する。

**検証**
- 出現監査smoke: 全70種がいずれかの釣り場・条件で出現可能なこと（「データはあるが一生釣れない魚」の検出）
- 魚素材監査: 全70種にカードポートレートと泳ぎシートがあること
- 図鑑smoke・調理フローsmoke（レシピ対応漏れ検出）
- `validate_project.sh`（素材参照監査含む）

**完了条件**: **完了**。70種全てが「釣れる・図鑑に載る・料理できる・売れる」の4動線を通る。

**リスク**: 追加魚40種の素材はテンプレート派生で成立させているため、最終アート品質は後続polish対象。ポートレート＋泳ぎシートの画風統一（既存30種と並べて違和感がないか）は図鑑一覧スクショで確認する。

---

### P5. 調理費用（料理を食べるのにお金を払う） — **MVP保留（2026-07-04）**

**方針変更**: MVPでは実装しない。料理は「釣った魚を食べて成長・バフを得るごほうび」として維持し、調理費用は将来の難易度設定で「ふつう/むずかしい以上の経済ルール」として再検討する。

**現時点で実装しないもの**
- `cook_cost` の追加
- `cook_and_eat()` での所持金チェック・支払い
- 調理画面への費用表示・資金不足ブロック
- 将来の難易度設定と合わせた食費込みの価格バランス調整

以下は将来再開時の設計メモとして残す。

**ゴール**: 調理に費用がかかるようにし、料理（経験値・バフ）を「お金を投資して得るもの」にする。収入源は市場売却に一本化され、「売って得た金を装備に回すか、食事（成長）に回すか」の配分がゲームになる。

**設計方針**
- 各レシピに `cook_cost`（調理費用）を追加。上位レシピほど高い
- 費用案（`exp_multiplier` の序列に合わせる。調整は `docs/09_パラメータ調整表.md` で管理）:

| レシピ | exp倍率 | cook_cost 案 |
|---|---|---|
| 塩焼き | 1.0 | 50 G |
| 刺身 | 1.2 | 120 G |
| 煮付け | 1.35 | 200 G |
| つみれ汁 | 1.5 | 300 G |
| 魚フライ | 1.6 | 450 G |

- 目安: 「その料理によく使う魚1匹の売値の3〜5割」程度に収め、釣行→売却→食事のループが赤字にならないこと。魚の `sell_price`（120〜数千G）と食費の釣り合いは将来の難易度設定・経済バランス調整で最終確定
- 塩焼きを安く据え置くことで、序盤（所持金が薄い時期）に食事が詰まないようにする

**実装**
- `game_data.gd`: `RECIPES` 各エントリに `cook_cost: int` を追加
- `player_progress.gd`: `cook_and_eat()` の冒頭で所持金チェック（不足時 `{"ok": false, "message": "お金が足りません。..."}`）→ 成功時に `money -= cook_cost`。戻り値に `cost` を含めて結果表示で使えるようにする
- セーブ互換への影響なし（既存フィールド `money` の増減のみ）

**UI変更**（調理フローは `skills/tsuri-cooking-showcase-uplift/SKILL.md` の管轄。改修時はこのスキルに従う）
- `cooking_screen.gd`: レシピ選択カードに調理費用を表示、画面内に所持金表示を追加
- 所持金不足のレシピは選択不可（グレーアウト＋理由表示）。「作れない」の理由がレベル不足か資金不足か区別できる文言にする
- 実行結果に「−○○ G」を含める

**検証**
- 調理フローsmoke（`cooking_flow_smoke`）に「資金不足で調理不可→売却で資金確保→調理成功」のパスを追加
- 経済バランス確認: 序盤（Lv1〜3、アジ・イワシ主体）で食費が売却収入を上回らないか机上計算し、docs/09へ記録

**完了条件**: 全レシピに費用が設定され、支払い・不足時ブロック・結果表示が機能すること。序盤進行で食費により資金が詰まないこと。

---

### P6. 魚市場画面の正式化＋売却仕様拡張 — **実装完了（2026-07-04）**

**ゴール**: 簡易実装の `market_screen.gd` を本番品質にし、売却操作を「1匹 / 数量指定 / 1種類全部 / 複数選択 / 全部まとめて」に拡張する。

**前提**: P5はMVP保留。P6はP5非依存で進める。完成ゴールは `reference/10_fish_market_mockup.png`。手順は `skills/ui-screen-build/SKILL.md`。

**実装結果**
- `market_screen.gd` を旧 `ItemList` 画面から、1280x720固定の `FishMarketDesignCanvas` + `assets/showcase/fish_market/fish_market_backplate.png` + runtime描画の正式UIへ置き換えた。
- 売却操作は各魚種行の `- / 数量 / + / 全` と右下カートの `全部選択` / `まとめて売る` に統合した。「1匹売る」専用ボタンは復活させない。
- 右上に選択魚の査定詳細、右下に売却カート、同画面内に確認オーバーレイ・売却完了・空状態を持たせた。
- 魚画像は全て `FightFishAssets.card_portrait_path()` 経由で解決し、魚名・所持数・単価・数量・価格・ボタン状態はGodot runtimeで描画する。
- `PlayerProgress.sell_fish_batch(orders)` を追加し、正の数量だけを全件先に検証してから一括売却する。成功時の所持金・在庫・save・`progress_changed` 更新は1回にまとめる。
- `docs/25_fish_market_screen_spec.md` と `docs/qa/fish_market_qa.md` を新設し、visual QA証跡を `docs/qa/evidence/fish_market/` に保存する。

**売却仕様**
| 操作 | UI |
|---|---|
| 1匹 / 数量指定 | 魚種行に −/＋ステッパー（0〜所持数）。「1匹売る」はステッパー1の特殊形として統合 |
| 1種類全部 | 行の「全部」ボタンでステッパーを最大に |
| 複数選択 | 各行のステッパー値が売却カートを兼ねる（チェックボックス方式より操作が1段少ない） |
| 全部まとめて | 「全部売る」ボタン（全行ステッパー最大化）→ 合計金額の確認ダイアログを挟む |
- 画面下部に常時「売却合計 ○○ G」プレビュー → 「まとめて売る」で確定
- `PlayerProgress.sell_fish()` は既に (fish_id, amount) 型なのでロジック側はほぼ流用可。複数種一括用に `sell_fish_batch(orders: Dictionary) -> Dictionary` を追加

**安全装置**
- 図鑑未登録魚・未知魚は `sell_fish_batch()` の検証で失敗させる。
- 最後の1匹を含む売却は確認オーバーレイで「料理素材としては残りません」と警告する。

**素材・QA**
- `assets/showcase/fish_market/`（新設）＋ `tools/generate_fish_market_assets.py` ＋ `docs/qa/fish_market_qa.md` ＋ visual QAスクリプト。所有監査への登録も忘れず
- 魚アイコンは `FightFishAssets.card_portrait_path()` 経由で流用（fish素材の直接参照禁止ルール順守）

**検証**
- `godot --headless --path . res://tools/market_smoke.tscn`
- `./tools/market_visual_qa.sh`
- `./tools/validate_project.sh`

**完了条件**: **完了**。4つの売却パターン全てが確認ダイアログ含め動作し、全部売却→所持0状態→再入場の表示も破綻しない。

---

## 4. 横断事項

1. **セーブ互換**: P1（owned_rigs等）で新フィールドが増える。`load_game()` は必ず `get(key, default)` 形式で補完し、各フェーズ完了時に「旧セーブ読込→新機能がデフォルト状態で動く」ことをsmokeで確認する。
2. **抽選の枠組み統一**: 出現重みは「基礎weight × レベル補正 × 釣り場補正 × **仕掛け補正(P1)** × **天候補正(P3)**」の乗算に統一する。加算や上書きを混ぜない。係数はすべて `docs/09_パラメータ調整表.md` に集約。
3. **素材所有ルール**: 新画面フォルダ（tackle_shop / fish_market）を作ったら `tools/audit_showcase_asset_refs.py` の監査対象へ追加。魚画像は必ず `FightFishAssets` 経由。
4. **各フェーズの完了ゲート**: `./tools/validate_project.sh` ＋該当smoke＋（UI変更時）visual QAスクショ比較。UI正式化フェーズはQAドキュメント（freeze表）新設まで含めて完了。
5. **docs更新**: P1完了時に `05_データ仕様.md`（RIGS）、P3完了時に `15_fishing_spot_encounter_spec.md`（環境補正）へ反映。

---

## 5. 決定事項と未決事項

### 決定済み（2026-07-03 ユーザー確認）

| # | 論点 | 決定 |
|---|---|---|
| 1 | 仕掛けの扱い | **買い切り装備**（消耗品化は将来の拡張として温存） |
| 2 | 「料理でお金」の意味 | **調理に費用を支払う（支出）**。作った料理を売る仕様ではない。MVPでは保留し、将来再開時は各レシピに `cook_cost` を設定する |

### 決定済み（2026-07-04 ユーザー確認）

| # | 論点 | 決定 |
|---|---|---|
| 1 | P4の魚数 | **ゲーム全体で70種**。既存30種は全種続投し、追加40種を入れる |
| 2 | 追加魚の条件 | **実在する日本近海・海釣り対象魚のみ** |
| 3 | 出現設計 | **エリア限定 + 仕掛け相性 + 天候補正**。低レベル共通魚10種は全通常エリアに混ぜる |
| 4 | ぬし追加 | **なし**。通常魚69種 + ぬし1種 |
| 5 | コブダイ | **追加対象**。`kobudai` として岩礁・消波ブロックに配置 |
| 6 | P5調理費用 | **MVP保留**。将来の難易度設定（ふつう/むずかしい等）で再検討 |
| 7 | 魚市場の完成ゴール | **生成済み2枚目**を `reference/10_fish_market_mockup.png` として採用 |
| 8 | 市場の売り切り警告 | **最後の1匹警告あり**。同画面内の確認オーバーレイに出す |

### 未決事項（着手前にユーザー判断が必要なもの）

| # | 論点 | 選択肢 | 暫定案 |
|---|---|---|---|
| 1 | ぬし釣り場と仕掛け | カニ餌仕掛けを入場条件にする / 補正対象外のまま | **補正対象外**（入場条件は難度が跳ねる） |
| 2 | 天候の種類数 | 3種（晴/曇/雨） / 5種（＋霧・時々曇り） | まず4種（快晴/曇り/小雨/霧）で様子見 |
| 3 | 調理費用の水準 | 上表のcook_cost案 / より安く・高く | MVP後の難易度設定フェーズで再検討 |
