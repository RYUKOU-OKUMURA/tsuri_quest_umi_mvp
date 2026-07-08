# 41. E5 時間帯 実装レビュー・改善提案

作成日: 2026-07-08  
状態: スライス1〜4 実装完了（2026-07-08）
関連: `docs/v2/E5_time_slots.md`（実装仕様） / `docs/42_fishing_time_slot_asset_brief.md` / `docs/qa/harbor_qa.md` / `docs/qa/fishing_surface_qa.md` / `docs/qa/underwater_fight_qa.md`

## 0. この文書の位置づけ

E5「時間帯（朝まずめ・夜釣り）」実装（2026-07-08 完了）に対するコード監査・港画面 UX 見直し・釣行ビジュアル改善案を1本にまとめたレビュー報告書。実装仕様の正本は `docs/v2/E5_time_slots.md` のまま。本 doc は**レビュー結果と次スライスの提案**を記録する。

検証は親エージェントが `./tools/validate_project.sh`・`time_slot_encounter_audit`・`harbor_screen_smoke`・`fishing_reveal_smoke`・`save_system_verify.sh` を実行して green を確認済み。

---

## 1. E5 実装レビュー — 総合判定: 合格

中核ロジック（データ定義・抽選接続・港選択 UI・出港 stats 反映・カラーグレーディング・夜 BGM override）は仕様準拠。残りは表示文言・演出詳細・監査カバレッジの軽微なギャップ。

### 1-1. 仕様節ごとの判定

| 節 | 判定 | 備考 |
|---|---|---|
| E5-1 データ | 準拠 | `TIME_SLOT_ORDER` / `TIME_SLOTS` の解放 Lv・倍率・`surface_bgm_key_override` は仕様表と一致（`game_catalog_data.gd:1855-1907`） |
| E5-2 抽選 | 準拠 | `time_slot_id` は `extra_fish_weight_modifiers` の**後ろ**に末尾追加。rarity と fish_id の両方を乗算。`roll_hooked_fish` / `nushi_candidate` へ接続済み |
| E5-3 港 UI | 準拠（文言のみ逸脱） | 3 ボタン・未解放ロック・ヘッダー実値化・セーブ永続化・`begin_fishing_trip()` stats 反映 |
| E5-4 グレーディング | 準拠（ビネット未実装） | 朝=暖色・夜=寒色+暗め・日中=透明。港=全画面、釣行=`water_panel` 内 |
| BGM | 準拠 | 夜のみ `"calm"` 固定。`main.gd` の BGM 境界上で `surface_bgm_key` を上書き |
| E5-6 DoD | 準拠（監査 1 点不足） | 監査シーン・smoke・visual QA 証拠・`harbor_qa.md` 新設済み |

### 1-2. 逸脱・懸念（対応推奨順）

| 優先 | 内容 | 所在 | 推奨対応 |
|---|---|---|---|
| 1 | ロック文言が「夜釣り Lv.15」形式。仕様例は「Lv.15で解放」 | `harbor_screen.gd:281` | コード修正（1 行） |
| 2 | 監査に BGM override 検証ケースなし | `time_slot_encounter_audit.gd` / `docs/30` §4-4 | 監査 1 ケース追加 |
| 3 | ビネット未実装（色乗算のみ） | E5-4 / `fishing_screen.gd` | 釣行ビジュアル Stage 1 に統合 |
| 4 | `night.name` が「夜釣り」（仕様表は「夜」） | `game_catalog_data.gd:1892` | UI 的には「夜釣り」の方が分かりやすい → **仕様書側を改訂** |
| — | 港 `_refresh_labels` で未解放スロットを日中へ正規化するが即 `save_game` しない | `harbor_screen.gd:493-498` | ロード時 `_normalized_time_slot_id` で補正されるため実害なし。正規化ロジックを `PlayerProgress` 1 箇所に寄せると安全 |
| — | 釣行グレードは `water_panel` のみ（サイドバー・ステータスバーは対象外） | `fishing_screen.gd:109-123` | 意図的範囲。Stage 1 で外縁・リザルト拡張を検討 |
| — | boss_spot で時間帯倍率をスキップ | `game_data.gd:996-998` | 仕様未記載。意図的と判断 |
| — | ヌシ `time_slot_id` 配線済みだが全 nushi は `""` | `game_catalog_data.gd` | 将来用。現状無害 |

### 1-3. 検証結果（2026-07-08 実行）

| コマンド | 結果 |
|---|---|
| `./tools/validate_project.sh` | green |
| `time_slot_encounter_audit.tscn` | 全ケース一致（asa_mazume レア 1.30・アンコモン 1.12、night tachiuo 2.20、extra 合成 3.25） |
| `harbor_screen_smoke.tscn` | ok |
| `fishing_reveal_smoke.tscn` | ok |
| `./tools/save_system_verify.sh` | passed |

### 1-4. 実装コミット

- `fe1728d7` — E5 前提（BGM 境界整理）
- `7f0ddb37` — データと抽選
- `5508ea42` — 港 UI と演出
- `b887be69` — 監査に重み合成ケース追加

---

## 2. 港画面 UX — 構成見直し提案

### 2-1. 違和感の正体

1. **左カラム上 40% が装飾** — シーンウィンドウ＋固定フレーバー 3 行が最大面積を占め、意思決定に寄与しない
2. **「今日の支度」カードの雑居** — チュートリアル文・サメ餌魚・時間帯 3 ボタンが 1 枚に同居。時間帯セレクタが「置き場所がなくて押し込んだ」ように見える
3. **飾りデータが実データに混ざる** — ヘッダー「潮位：満ち始め　風：弱」は固定文字列なのに、隣の「時間帯」だけ実値
4. **EXP の二重表示** — トップバー「EXP 0 / 2000」とフッター「食経験値：0 / 2000 EXP」

### 2-2. 情報の重複（現状）

| 情報 | 出現箇所 |
|---|---|
| EXP（食経験値） | トップバー + フッター |
| 時間帯名 | ヘッダー状況行 + 「今日の支度」内ボタン + 全画面 grade オーバーレイ |
| Lv / 所持金 / 装備竿 | トップのみ |
| クーラーボックス / プレイ時間 | フッターのみ |

### 2-3. 推奨再構成（左カラム中心、右施設メニュー・フッター枠は維持）

港画面の役割を **「次の釣行のプランを立てて出港する」** に定義し直す。

1. **シーンウィンドウを縮小**（高さ 40% → 25% 程度、説明文 3 行 → 1 行または削除）
2. **「出港プラン」カード**（「今日の支度」を改名・再編）
   - **時間帯**: 3 ボタンを等幅セグメント風 1 行。「選択中」テキスト付加をやめ、GoldButton 系の見た目だけで選択状態を表現。ロック時は「Lv.Nで解放」
   - **サメ餌魚**: 同カード内に残すが「餌魚」行ラベルで時間帯と同じ行形式に揃える
   - **食事効果**: 独立カードをやめこの行に統合（「食事効果：なし」1 行。バフがある時だけ強調）
3. **主導線「釣り場へ向かう」をカード直下に大ボタン**（右メニュー同項目は残してよい）

**情報整理**

- ヘッダーの「潮位・風」は**削除**（時間帯のみ残す）。実データ化するまで飾り文言を出さない
- フッターの「食経験値」を削除し「クーラーボックス｜プレイ時間」に絞る（EXP はトップバーに一本化）

### 2-4. 着手条件

- ui-screen-build の分解ゲート + ui-screen-uplift の距離ゲートの併用対象
- `docs/qa/harbor_qa.md` は新設済み。freeze は時間帯グレードのみで、レイアウト改修は動きやすい

---

## 3. 釣行ビジュアル — 「昼のまま」問題と改善案

### 3-1. 「リビール/レビュー画面」の正体

独立したリビール画面は**存在しない**。釣行はすべて `fishing_screen.gd` 1 画面内の状態切り替え。

| 呼称 | 実体 |
|---|---|
| fishing_reveal | `FishingSimulator.fish_revealed` の公開タイミング（`hook()` 後） |
| リビール（魚種判明） | `State.FIGHT` 遷移 + 水中ビュー + サイドバー/フローティングカード |
| 釣果リビール（成功） | `CatchFanfare` オーバーレイ（z_index=80） |
| 逃走リザルト | `_result_overlay`（全画面ディム + パネル） |

### 3-2. 昼のままに見える技術的原因

1. **時間帯は背景 PNG を変えない設計**（E5 = `ColorRect` グレーディングのみ）
2. **水面状態プレート**（`surface_scene_ready_*.png` 等）が昼アート固定。太陽が描き込まれており alpha 0.14〜0.28 のグレードでは隠せない
3. **水中・釣果**（`underwater_battle_bg.png` / `catch_photo_base.png`）が単一の昼ベース PNG
4. **E5 グレードは `water_panel` 内のみ** — 外縁グラデ・釣果ファンファーレ・逃走リザルトは対象外（釣果は全画面オーバーレイでグレードを完全遮蔽）
5. **水面は天候のみ差し替え** — `time_slot_id` 未参照
6. **釣行中の釣り場マップ**に時間帯表現なし（E5 v1 スコープ外）

### 3-3. E5 グレーディング適用範囲（現状）

```
港(harbor)     → 全画面 ColorRect（backdrop の上・UI の下）
釣行(fishing)  → water_panel 内のみ ColorRect
  ├ 適用される    → SurfaceCastView, UnderwaterView
  └ 適用されない  → 外縁グラデ、上部バー、右サイドバー、下段 HUD、CatchFanfare、逃走リザルト、釣り場マップ
```

色定義（`palette.gd`）: 日中=透明 / 朝=橙 alpha 0.14 / 夜=紺 alpha 0.28

### 3-4. 段階的改善案

#### Stage 1: コードのみ（素材ゼロ、即着手可）

- グレード適用を**釣果ファンファーレ・逃走リザルト・画面外縁グラデ**へ拡張
- 未実装の**ビネット**追加、夜の alpha 強化の検証
- 3 時間帯横並びスクショを `docs/qa/` に記録し「夜に見えるか」を判定
- **想定**: 水面 READY の太陽は消せないため不合格 → Stage 2 の素材投資根拠になる

#### Stage 2: 最小素材セット（推奨 4 枚）

組み合わせ爆発（時間帯 3 × 天候 5 × 状態 5）を避ける。**非晴天が READY 天候ベースを CASTING 以降も維持する既存パターン**に倣い、時間帯も READY 1 枚で全状態をカバーする。

| 素材 | 内容 | 効果 |
|---|---|---|
| `surface_scene_ready_asa_mazume.png` | 朝焼け READY（既存 READY と同構図） | 昼の太陽を解消 |
| `surface_scene_ready_night.png` | 月夜 READY | 同上 |
| `catch_photo_base_asa.png` | 釣果写真・朝版 | 釣れた瞬間の違和感解消 |
| `catch_photo_base_night.png` | 釣果写真・夜版 | 同上 |

- 朝/夜の天候表現: 天候別 READY 差し替えを使わず**時間帯 READY ベース + 既存天候 grade オーバーレイ**の合成
- 水中背景: まず夜=グレード強化のみで検証。不足なら `_night` 1 枚追加（`docs/qa/underwater_fight_qa.md` の freeze 改定が前提）

#### フック地点（実装時）

| 優先 | 画面 | 関数 |
|---|---|---|
| 高 | 水面 | `surface_cast_view.gd` `_weather_scene_texture_for_state()` — `trip_stats.time_slot_id` 分岐 |
| 高 | 釣果 | `catch_fanfare.gd` `play()` — `trip_stats` 引数追加 |
| 高 | 水中 | `underwater_view.gd` — `trip_stats` 注入 |
| 中 | 釣行外縁 | `fishing_screen.gd:72` `add_gradient_background()` |
| 中 | 逃走リザルト | `_create_result_overlay()` |
| 低 | 釣り場マップ | `fishing_spot_map_view.gd`（E5 v1 スコープ外） |

### 3-5. freeze 制約（素材差し替え前に確認）

- `docs/qa/fishing_surface_qa.md` — 晴天状態別プレート・非晴天魚影・rain/fog overlay は freeze。E5 Stage 2では時間帯READY 2枚 + 釣果写真ベース2枚だけ例外として改定済み
- `docs/qa/underwater_fight_qa.md` — 水中 BG ビルドパイプライン不変・状態別×天気 PNG 量産禁止
- `docs/qa/harbor_qa.md` — 港は ColorRect のみ。専用夜景 PNG は先に作らない
- 素材差し替えを進める前に `docs/qa/` への判断記録と freeze 改定が必要

---

## 4. 推奨スライス順

| 順 | スライス | 内容 | 依存 | 状態 |
|---|---|---|---|---|
| 1 | E5 軽微修正 | ロック文言・監査 BGM ケース | なし | 完了（2026-07-08）。仕様表の night 名称も「夜釣り」へ改訂 |
| 2 | 港画面再構成 | §2 の「出港プラン」カード化 | ui-screen-build / uplift | 完了（2026-07-08）。ロック文言は幅制約で「Lv.Nで解放」短形式、シーン説明文は削除。freeze改定は `docs/qa/harbor_qa.md` |
| 3 | 釣行 Stage 1 | グレード拡張 + ビネット + visual QA 判定 | なし（素材ゼロ） | 完了（2026-07-08）。夜成立判定は**不合格**（水面READYの焼き込み太陽・昼海面が残る）。記録は `docs/qa/fishing_surface_qa.md` |
| 4 | 釣行 Stage 2 | 最小素材 4 枚 + 配線 + freeze 改定 | Stage 1 不合格記録 | 完了（2026-07-08）。素材ブリーフは `docs/42_fishing_time_slot_asset_brief.md`、採用判断は `docs/qa/fishing_surface_qa.md` |

---

## 5. 証拠画像

| 用途 | パス |
|---|---|
| 港 3 時間帯比較 | `docs/qa/evidence/harbor/2026-07-08_e5_time_slot_compare.png` |
| 港 ヘッダー状況行 | `docs/qa/evidence/harbor/2026-07-08_e5_time_slot_top_status_compare.png` |
| 釣行 READY 3 時間帯 | `docs/qa/evidence/fishing_surface/2026-07-08_e5_time_slot_ready_compare.png` |
| 釣行 Stage 2 READY 3 時間帯 | `docs/qa/evidence/fishing_surface/2026-07-08_e5_stage2_time_slot_ready_compare.png` |
| 釣行 Stage 2 夜釣果ファンファーレ | `docs/qa/evidence/fishing_surface/2026-07-08_e5_stage2_night_fanfare.png` |
| 水中トップステータス | `docs/qa/evidence/underwater_fight/2026-07-08_e5_time_slot_top_status_compare.png` |
