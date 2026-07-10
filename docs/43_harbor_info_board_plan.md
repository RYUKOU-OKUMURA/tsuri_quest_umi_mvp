# 43. 港の情報板構想 — 初心者アシスト強化プラン

作成日: 2026-07-09
状態: **旧レイアウト計画（superseded）**。候補選定などの情報設計ロジックだけ継続し、画面・素材・freezeの正本は `docs/44_harbor_command_board_spec.md` と `docs/qa/harbor_qa.md`（天気先読みロジックは未着手）
関連: `docs/41_e5_time_slots_implementation_review.md` §2（港画面UX再構成）/ `docs/38_shark_bait_ready_selector_spec.md` §6（餌魚UI撤去）/ `docs/qa/harbor_qa.md`（港画面freeze）/ `docs/19_ui_production_playbook.md` §4.6・§4.5（基盤レイアウト原則）/ `docs/31_asset_ledger.md`（素材台帳）

注意: 本物の天候先読み（§2）以外は完了済み経緯であり、新規実装指示に使わない。港レイアウト・素材・freezeはdocs/44とharbor_qaを正とする。§2はローンチ必須外backlogで、着手時は独立した設計判断が必要。

## 0.0 「港の司令盤」への移行（2026-07-10）

本書の候補選定、初心者ガイド、天候スタブ、ヌシ/メガロドン、時間帯のデータ契約は継続する。一方、旧v4の「3魚同格＋大きな出港プラン紙面＋右10行メニュー」という画面構成、v4完成イメージ、Phase A/Bの素材計画は、採用モック `docs/qa/evidence/harbor/2026-07-10_harbor_command_board_mockup_v1.png` と実装仕様 `docs/44_harbor_command_board_spec.md` に置き換えた。現在の画面・素材分担・freeze値は `docs/44` / `docs/qa/harbor_qa.md` を正とし、本書の旧レイアウト節を新規作業の指示に使わない。

## 0.1 旧v4確定事項（2026-07-09、2026-07-10失効）

旧完成イメージ（正本から除外）: 会話生成の `harbor_info_board_vision_v4.png`（港情報板＋出港プラン可読性＋時間帯視認性）。以下は採用当時の記録であり、現行仕様ではない。

| 項目 | 確定内容 |
|---|---|
| 時間帯ボタン | 未選択=明るい羊皮紙地＋濃茶文字＋はっきり枠。選択=金/琥珀グロー。素材 `harbor_time_slot_btn_*.png` を再生成 |
| 出港プラン | 羊皮紙二重枠撤廃 → **Phase A:** `harbor_plan_panel.png`（AI一点物）＋行リスト。面積 0.37–0.70 |
| 情報板 | 3カード維持。面積 0.05–0.36（プランへ縦を譲る） |
| 左CTA「釣り場へ向かう」 | **削除**（v3から継続）。出港は右施設メニュー primary のみ |
| §2 天気の気配 | **スタブのまま**（先読み抽選・セーブは後続） |

## 0.2 旧v3確定事項（2026-07-09・v4で一部更新、現在は失効）

旧完成イメージ（正本から除外）: 会話生成の `harbor_info_board_vision_v3.png`（港情報板＋拡充出港プラン＋右メニュー主導線）。

| 項目 | 確定内容 |
|---|---|
| 左CTA「釣り場へ向かう」 | **削除**。出港は右施設メニュー primary のみ |
| 面積の使い方 | CTA削除分を情報板＋出港プランの情報行に回す。右メニュー項目の左への移動はしない |
| §1 情報板 | 左上段。最大3匹ポートレート＋理由バッジ |
| §3 初心者ガイド | 出港プランカード内の1行。情報板とは面積を取り合わない |
| §2 天気の気配 | **今回は見た目スタブのみ**（固定/仮テキスト＋既存天候アイコン）。先読み抽選・セーブは後続 |
| 時間帯・施設UI | ボタンスキンとナビアイコンを素材刷新（依頼ボード専用 `nav_quest_icon.png` 含む） |
| 着手順（実装） | freeze改訂 → 候補リストAPI → 素材生成（並列可） → UI配線 → visual QA |

## 0. 背景と位置づけ

2026-07-09、港画面の出港プランカードから餌魚選択を撤去し、「本日の狙い目」動的ヒント（既存 `GameData.encounter_weights()` ベース、依頼対象魚→時間帯ブースト魚→未捕獲魚の優先順）を導入した（安い案）。本ドキュメントはその先の「理想案」＝港の情報板構想の計画書である。目的は、やり込み要素が増えたV2以降のゲームで初心者（子供プレイヤー）へのヒント・アシストを強化すること。仕様判断はエンジニア都合で狭めず、子供の体験を第一にする（3案とも「絵で伝わる」「文字を減らす」方向を優先する）。

本ドキュメントで引用するコード参照（関数名・行）は作成時点（2026-07-09）のリポジトリで実在を確認済み。「本日の狙い目」ヒントは `src/ui/harbor_screen.gd` の `_target_hint_text()`（優先順: `_quest_target_hint_text()` → `_time_slot_boost_hint_text()` → `_uncaught_sighting_hint_text()`）として実装済みで、`_preparation_card_text()` から呼ばれている（詳細は §1 実装方針を参照）。

## 1. 港の情報板（狙い目の視覚化）

### 狙い

文字ヒント（「本日の狙い目：〇〇」）を、ポートレート付きの視覚情報へ格上げする。子供は文章より絵で判断するため、狙うべき魚が一目で分かる港にする。

### 体験

港画面のシーンウィンドウ領域（`docs/qa/harbor_qa.md` freeze: 左カラム上段・高さ約25%）を「港の情報板」に転用し、優先順位の高い狙い目魚を最大2〜3匹、ポートレート＋短い理由ラベル（例: 「依頼」「朝まずめで出やすい」「まだ見ぬ魚」）付きで並べる。

### 実装方針

安い案の文字ヒント選定ロジックは既に `src/ui/harbor_screen.gd` に実装済みで、そのまま流用できる。

- `_target_hint_text()`（`src/ui/harbor_screen.gd:319`）が優先順位を1本化している:
  1. `_quest_target_hint_text()`（同 `:214`）— `PlayerProgress.quest_board`（`Array[Dictionary]`、`src/autoload/player_progress.gd:94`）の各要素を `PlayerProgress.quest_progress(index)`（`src/autoload/player_progress.gd:467`）で評価し、未完了の依頼対象魚のうち `GameData.encounter_weights(...)`（`src/autoload/game_data.gd:972`）で最も重みが高い釣り場と紐づける
  2. `_time_slot_boost_hint_text()`（同 `:241`）— 現在の時間帯あり/なしで `encounter_weights()` を2回引き、倍率（`boost = weights_with / weights_without`）> 1.0 の魚から選ぶ（未捕獲優先）
  3. `_uncaught_sighting_hint_text()`（同 `:294`）— `PlayerProgress.caught_counts.get(fish_id, 0) == 0`（`src/autoload/player_progress.gd:82`）の魚を `encounter_weights()` の重み降順で選ぶ
  4. 該当なしのフォールバックは固定文「海は穏やか。どこへ出ても釣り日和だ」
- 情報板ではこの1本の優先順位から**上位1〜3件**を取り出せるよう `_target_hint_text()` 系の内部ロジックを「文字列を1つ返す」から「候補リストを返す」形へリファクタし、UI側でポートレート表示に使う
- ポートレートは既存 `FightFishAssets.card_portrait_path(fish_data)`（`src/ui/fight_fish_assets.gd:25`）経由で参照する。**新規魚素材ゼロで成立する**（AGENTS.md不変ルール「魚素材はFightFishAssets経由」を遵守）
- 情報板の枠・背景に新規PNGが要る場合のみ `assets/showcase/harbor/`（既存フォルダ。`harbor_scene_window.png` 等が同居）に「情報板」風フレームを追加する。装飾はrun-time描画（StyleBoxFlat等）で足りるかを先に試し、`docs/19` §5-13「runtime装飾は1画面3パスまで」を踏まえて素材要否を判断する
- 新素材を追加した場合は**同じコミットで `docs/31_asset_ledger.md` に作者・ライセンス・入手元を記入する**（AGENTS.md不変ルール）

### 必要素材

- 最小構成: 新規素材ゼロ（既存 `harbor_parchment_card.png` 系のスタイルを流用 + runtime描画の縁取り）
- 拡張構成: 情報板枠PNG 1点（`assets/showcase/harbor/harbor_info_board_frame.png` 相当）

### freezeとの関係

`docs/qa/harbor_qa.md` の「シーンウィンドウ」freeze（高さ約25%・タイトル1行のみ）を情報板へ転用する場合は、着手前にQAドキュメントの改訂（スコープ宣言＋新freeze値）が必要（AGENTS.md不変ルール「合格済みfreeze値はP1破綻時以外動かさない」）。

### 概算スライス数: 3

1. データ層 — 優先順位ロジックを純粋関数として抽出（例: `GameData.harbor_highlight_fish_ids()` 相当）＋単体検証
2. UI実装 — 情報板レイアウト・ポートレート表示・理由ラベル（`skills/ui-screen-uplift/` の距離ゲート併用、`docs/qa/harbor_qa.md` freeze改訂込み）
3. QA証拠 — 実スクショ・`harbor_screen_smoke` 回帰・`docs/qa/evidence/harbor/` への証拠保存

## 1.5 旧Phase B: 一点物化の生成指示（実行済み・不採用）

2026-07-10に下記指示で生成・加工・3時間帯比較まで実施したが、現行PIL版に全画面で明確に勝たなかったため**不採用**とした。出力素材はPIL版へ戻しており、港の司令盤ではこのPhase Bを採用しない。判断の正本は `docs/qa/harbor_qa.md` §2。本節は生成条件の監査記録として残すもので、再実行指示ではない。

当時の対象は `tools/generate_harbor_info_board_assets.py` が出力する下記2素材のみだった。

| 素材 | 現行の役割・寸法 | 参照箇所 |
|---|---|---|
| `harbor_info_board_frame.png` | 情報板全体の外枠背景。**1280x320px**（4:1）。`TextureRect.STRETCH_SCALE` でフルレクト伸縮（アスペクト非保持）。タイトル「本日の狙い目」は runtime Label が上に重なるだけで素材側に焼き込まない | `src/ui/harbor_screen.gd:117-119` |
| `harbor_info_fish_card.png` | 情報板内の魚カード背景。**240x280px**（6:7）。同じく `STRETCH_SCALE` で3枚並べて使う。ポートレート・魚名・理由バッジはすべて runtime 要素が上に重なる | `src/ui/harbor_screen.gd:135-137`（1スロット分。3スロットで使い回し） |

いずれも中央領域を透過でくり抜く必要はない（現行PIL版も不透明な板のまま。portrait/label は単に前面に重ねて表示される）。**アスペクト比を変えると港画面の縦横比が崩れるため、生成・加工の両方で上記比率を厳守する。**

### 当時の生成指示（監査記録）

トーンは既存港画面素材（金縁×濃紺×羊皮紙の和洋折衷・海洋RPG調。`harbor_plan_panel.png` や `harbor_main_frame.png` と揃える）。**日本語・英語問わず文字/ロゴ/紋章の描き込みは禁止**（実行時にrun-time描画と二重になる／将来のローカライズに耐えない）。背景はクロマキー用にマゼンタ `#FF00FF` 単色で塗りつぶす。

**1. `harbor_info_board_frame_source.png` 用プロンプト（英語）**

```
A wide wooden bulletin-board frame for a seafaring fantasy RPG UI, ornate gold-leaf trim
around a dark navy-blue felt/parchment center panel, warm brown weathered wood grain
border with subtle carved corner plates, nautical fishing-village aesthetic (Japanese-
European hybrid maritime style), rich but not gaudy, painterly texture with soft ambient
occlusion. Wide banner aspect ratio 4:1 (approximately 1600x400px or larger, same aspect,
generate bigger and it will be downscaled). Absolutely no text, no letters, no numbers,
no logos, no emblems, no watermarks — decorative border and panel only. Flat solid
magenta background color #FF00FF everywhere outside the board (for chroma-key removal).
Soft directional lighting from upper-left, no harsh reflections, no glass glare.
```

**2. `harbor_info_fish_card_source.png` 用プロンプト（英語）**

```
A small ornate parchment card background for a seafaring fantasy RPG UI, aged cream
parchment paper texture with a warm brown-gold carved wooden frame border, subtle
corner plate ornaments matching a nautical fishing-village aesthetic (Japanese-European
hybrid maritime style), soft vignette shadow at the edges, gentle paper grain and faint
stains, no glossy highlights. Portrait aspect ratio 6:7, roughly square-ish and taller
than wide (approximately 480x560px or larger, same aspect, generate bigger and it will
be downscaled). Absolutely no text, no letters, no numbers, no logos, no icons, no
illustrations of fish or animals — decorative frame and paper texture only, the center
must stay a plain lightly-textured parchment fill so a portrait image and labels can be
overlaid on top of it later. Flat solid magenta background color #FF00FF everywhere
outside the card (for chroma-key removal).
```

### ソース画像の置き場所

生成した画像はリサイズせずそのまま以下へ保存する（加工スクリプトが目標ピクセル寸法へ cover-fit する）:

- `tools/source_assets/harbor/harbor_info_board_frame_source.png`
- `tools/source_assets/harbor/harbor_info_fish_card_source.png`

### 当時の生成後手順（完了済み・再実行しない）

1. 加工スクリプト実行: `python3 tools/process_harbor_info_board_assets.py`（マゼンタ透過 → トリム → 現行と同一ピクセル寸法へ cover-fit リサイズ → `assets/showcase/harbor/harbor_info_board_frame.png` / `harbor_info_fish_card.png` を上書き出力）
2. Visual QA: 港画面を実機/smoke でスクリーンショットし、Phase A前（PIL版）・完成イメージ（`harbor_info_board_vision_v4.png`）と横並び比較する（AGENTS.md不変ルール「見た目の完了判断は実スクショ+参照画像との横並び比較」）
3. 採用基準（`docs/19_ui_production_playbook.md` の基準どおり）: **現行PIL版に全画面比較で明確に勝つ場合のみ採用**。僅差・部分的な質感向上だけでは不採用とし、理由を `docs/qa/harbor_qa.md`（不採用リスト／freeze更新）に記録し、比較画像を `docs/qa/evidence/harbor/` へコピーする
4. 採用した場合だけ素材台帳へ追記する条件だったが、不採用のため製品素材としての追記対象外とした（AI生成ソースは監査用に残してよい）
5. `./tools/validate_project.sh` を通す（`tools/audit_showcase_asset_refs.py` の素材参照監査を含む）

不採用の比較証拠は `docs/qa/evidence/harbor/2026-07-10_info_board_phase_b_all_slots_before_after.png`（3時間帯一覧）と、同接頭辞の `asa_mazume` / `daytime` / `night` 個別比較に保存済み。

## 2. 天気の気配（出港前の天候先読み）

### 現状（コード事実）

天候・風は `GameData.roll_fishing_environment()`（`src/autoload/game_data.gd:100`）が抽選するが、これは港画面ではなく `PlayerProgress.begin_fishing_trip()`（`src/autoload/player_progress.gd:692-694`）内で呼ばれる。さらに `begin_fishing_trip()` 自体は港画面ではなく `fishing_screen.gd:261`（`_resolve_trip_stats()`。新規釣行時のみ、`continue_trip` の釣行継続時は呼ばれない）から呼ばれる。つまり天候は**港を出た後、釣行画面に入って初めて確定**する。港の時点では天候情報が一切存在しない。

### 構想

港到着時（または港画面表示時）に「次の釣行の天候」を先読み抽選して保持し、港では確定値ではなく「今日は荒れそうだ……」のような気配テキスト（雰囲気予報）だけを見せる。実際の抽選は従来どおり `begin_fishing_trip()` 内で行い、先読み結果と一致させるか、先読み結果自体を実際の抽選値として使い回すかは設計判断が必要（後者なら「気配」ではなく「予報」になり、雨天限定コンテンツの導線としてはより強い）。

### 効果

- ヒントであると同時に「雨の日限定コンテンツ」（例: 雨の日の目撃談、雨天ボーナス）への導線になる
- 「明日は良い日和になりそうだ」という子供にも分かりやすい先読み体験を提供する

### 注意点

- 抽選タイミングの変更はセーブデータに新規フィールド（例: `pending_weather_preview` 相当）を追加する可能性が高く、`PlayerProgress` のセーブ/ロード処理（`save_game()` / ロード側の正規化処理。`src/autoload/player_progress.gd` の該当箇所）と釣行継続フロー（`fishing_spot_select_screen.gd` の `continue_trip` payload、`docs/38` §3-4 のフォールバック処理）の両方に影響する
- 「先読み結果を実際の抽選に使うか、独立した気配演出に留めるか」は体験に直結する設計判断であり、**独立スライスで設計レビュー必須**（AGENTS.md「親エージェント単体で行う」対象になりうる。fan-outする場合もbrief作成前に方針を固定する）
- `./tools/save_system_verify.sh`（セーブ保護の回帰）を必ず回す

### 必要素材

新規素材は原則不要（気配テキストはruntime描画）。天候アイコンの薄型バリエーションが要る場合のみ `assets/showcase/common/` の既存天候アイコン（`tools/generate_top_status_weather_icons.py` 出力、`docs/31_asset_ledger.md` §2）を流用する。

### 概算スライス数: 4

1. 設計レビュー（親エージェント単体） — 先読みタイミング・セーブ影響範囲の確定
2. データ層 — 先読み抽選・保持・セーブフィールド追加
3. UI実装 — 港の気配テキスト表示
4. 検証 — `save_system_verify.sh` ＋ 釣行継続smoke ＋ 該当smoke一式

## 3. 初心者ガイド（次にやること表示）

### 狙い

出港プランカード再編で撤去した固定文「釣る → 売る／料理する → 強化」の役割を、低レベル帯限定の「次にやること」動的ガイドとして復活させる。固定文はレベルが上がっても同じ文言のままで情報価値が薄かった（撤去理由）が、進行状況に応じて変化するガイドなら初心者アシストとして機能する。現状の1行目は §1で扱う `_target_hint_text()` の「狙い目」ヒントに置き換わっており、フォールバック（該当ヒントなし時）は固定文「海は穏やか。どこへ出ても釣り日和だ」になっている（`src/ui/harbor_screen.gd:329`）。本節は主に**低Lv帯でこのフォールバック相当の場面に「次にやること」を割り込ませる**構想である。

### 体験

例（優先順位はイメージ。実装時に調整）:

- 調理未経験（`PlayerProgress.eaten_recipes.is_empty()`、`src/autoload/player_progress.gd:85`）→「魚を売るだけでなく、調理場で食べてみよう」
- 依頼未達成（`PlayerProgress.quest_board` の要素を `PlayerProgress.quest_progress(index)`（`src/autoload/player_progress.gd:467`）で評価し `completed: false` が残っている）→「依頼ボードで魚を届けよう」
- 上記に該当なし・低Lv → 現行の狙い目ヒント（`_target_hint_text()`）をそのまま出す
- 一定Lv以上（例: 既存の成長ソフトキャップ帯）では本ガイドを差し込まず、狙い目ヒントのみにして、やり込みプレイヤーの画面を汚さない

### 実装方針

- 判定材料は既存の `PlayerProgress` の状態（`level`、`caught_counts`、`eaten_recipes`、`quest_board`）で足りる見込み。新規セーブフィールドは不要
- 表示ロジックは `harbor_screen.gd` の `_preparation_card_text()`（`src/ui/harbor_screen.gd:195-203`。`_megalodon_omen_text()` → 1行目 → `_nushi_hint_text()` の順で組み立てる構造）に、低Lv向けガイドを`_target_hint_text()`より手前（または内側）の優先候補として追加する。既存の目撃談・メガロドン前兆・狙い目ヒントとの表示優先順位（同じ1行を取り合う）を先に整理する必要がある
- 新規素材は不要（runtime描画のみ）

### 必要素材

なし

### 概算スライス数: 2

1. データ層＋UI実装 — ガイド判定ロジックと `_preparation_card_text()` への統合（コードのみのため1スライスに収まる見込み）
2. 検証 — `harbor_screen_smoke` ＋ 低Lv/高Lv双方の表示確認スクショ

## 4. 優先順位と進め方

**旧v3の完了記録（再実行禁止）:** freeze改訂 → 候補リストAPI → 素材生成 → UI配線（§1＋§3＋天気スタブ＋CTA削除）→ visual QA。

本物の§2（先読み抽選・セーブ）は v3 UI 完了後に独立の設計レビューから始める。

各案とも実装時はオーケストレーション原則（brief分割、ワーカーのモデル明示、visual QA）に従う。

## 5. 未決事項

1. ~~§1と§3の面積取り合い~~ → **確定:** 情報板は上段、ガイドは出港プラン内1行
2. §2の先読み天候を「実際の抽選値」として使い回すか「別枠の気配演出」に留めるかは、雨天限定コンテンツ（E6 trip events等）の設計と合わせて決める（今回はスタブのみ）
3. §1のポートレート表示数（最大3）と理由ラベル文言は実装時に子供向け分かりやすさで微調整可
