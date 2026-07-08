# 43. 港の情報板構想 — 初心者アシスト強化プラン

作成日: 2026-07-09
状態: 構想（未着手）／前提: 出港プランカード再編（2026-07-09）完了
関連: `docs/41_e5_time_slots_implementation_review.md` §2（港画面UX再構成）/ `docs/38_shark_bait_ready_selector_spec.md` §6（餌魚UI撤去）/ `docs/qa/harbor_qa.md`（港画面freeze）/ `docs/19_ui_production_playbook.md` §4.6・§4.5（基盤レイアウト原則）/ `docs/31_asset_ledger.md`（素材台帳）

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

推奨着手順: **§3（コードのみ・最安）→ §1（素材1点まで）→ §2（設計変更を伴う）**

- §3はセーブ非変更・新規素材ゼロで最も安全。既存の目撃談ヒントとの表示優先順位さえ決めれば着手できる
- §1は最悪でも新規素材1点で済み、魚ポートレートは既存資産の再利用のため見た目インパクトの割にコストが低い
- §2はセーブデータ・釣行継続フローに触るため、他の2案が片付いた後に独立の設計レビューから始めるのが安全

各案とも実装時は `CLAUDE.md` のオーケストレーション原則（brief分割、`model: claude-sonnet-5` ワーカーの明示指定、visual QA）に従う。港画面のfreeze（`docs/qa/harbor_qa.md`）に触れる案（§1のシーンウィンドウ転用、§3の情報板1行の表示位置変更など）は、着手前に同QAドキュメントのfreeze改訂（スコープ宣言→新freeze値の記録）を先に行う。

## 5. 未決事項

1. §1の情報板と§3の初心者ガイドは同じ「シーンウィンドウ〜出港プランカード周辺」の限られた面積を取り合う可能性がある。両方を採用する場合はレイアウト調停が必要（どちらか一方を優先するか、ガイドをカード内1行に留めるか）
2. §2の先読み天候を「実際の抽選値」として使い回すか「別枠の気配演出」に留めるかは、雨天限定コンテンツ（E6 trip events等）の設計と合わせて決める
3. §1のポートレート表示数（2〜3匹）と理由ラベルの文言は、実装時に子供プレイヤーでの分かりやすさを優先して調整する
