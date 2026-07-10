# 31. 素材台帳（作者・ライセンス・入手元）

作成日: 2026-07-06
目的: `docs/08_独自性と権利メモ.md` §制作ルール「使用素材の作者、ライセンス、入手元を台帳化する」の実体。**販売（ローンチ）前に「要記入」をゼロにすることが E11 の完了条件の一つ**（docs/v2/E11_launch_readiness.md）。

運用ルール:

- 新しい素材・音源・フォントを追加したら、**同じコミットで本台帳に行を足す**
- 「入手元」は再取得できる具体性で書く（URL、生成スクリプト名、生成サービス名＋日付）
- AI生成サービスを使った場合は、サービス名・生成日・当時の商用利用規約の要点を書く

## 1. フォント — 記入済み・問題なし

| 素材 | パス | 作者/出所 | ライセンス | 同梱ライセンス文書 |
|---|---|---|---|---|
| LINE Seed JP（Rg / Bd / Eb） | `assets/fonts/line_seed/` | LY Corporation | SIL OFL 1.1（商用可） | `assets/fonts/line_seed/OFL.txt` ✓ |
| M PLUS 1p（Regular / Bold / ExtraBold） | `assets/fonts/` | The M+ FONTS Project | SIL OFL 1.1（商用可） | `assets/fonts/OFL-MPLUS1p.txt` ✓ |

## 2. スクリプト生成/後処理PNG — 記入済み

`tools/generate_*.py` のうち、PIL使用・外部AI API不使用・決定的生成の素材は**プロジェクト所有**であり第三者ライセンスの問題はない。対象: `assets/showcase/cooking/`・`fish_book/`・`fish_market/`・`fishing_spots/`・`harbor/`・`surface/`・`tackle_shop/`・`title/` などの各 generate スクリプト出力一式。

| 生成スクリプト | 出力先 |
|---|---|
| `tools/generate_cooking_showcase_assets.py` | `assets/showcase/cooking/` |
| `tools/generate_fish_book_book_frame.py` / `generate_fish_book_paper_assets.py` | `assets/showcase/fish_book/` |
| `tools/generate_fish_market_assets.py` | `assets/showcase/fish_market/` |
| `tools/generate_fishing_spot_map_assets.py` | `assets/showcase/fishing_spots/` |
| `tools/generate_harbor_showcase_assets.py` | `assets/showcase/harbor/` |
| `tools/generate_harbor_info_board_assets.py` | `assets/showcase/harbor/harbor_info_board_frame.png`, `harbor_info_fish_card.png`, `harbor_time_slot_btn_*.png`, `harbor_time_slot_icon_*.png`, `assets/showcase/common/nav_quest_icon.png`, `assets/showcase/common/nav_lock_icon.png`（2026-07-09追加。右メニューのロック行アイコン）（出港プラン紙面・行アイコンは `process_harbor_plan_assets.py` 経由。`generate_harbor_showcase_assets.py` からも呼び出し可） |
| `tools/process_harbor_plan_assets.py` | `assets/showcase/harbor/harbor_plan_panel.png`, `harbor_plan_icon_guide.png`, `harbor_plan_icon_pin.png`, `harbor_plan_icon_rumor.png`, `harbor_weather_stub_icon.png`。AIソース `tools/source_assets/harbor/` をクロマキー・ヘッダークリーンアップ・リサイズ |
| `tools/generate_nushi_fish_assets.py` | `assets/showcase/fish/nushi_*_card_portrait.png`, `assets/showcase/fish/nushi_*_showcase_sheet.png`（既存魚素材の派生） |
| `tools/generate_surface_fish_shadow.py` | `assets/showcase/surface/surface_fish_shadow_soft.png`（3フレーム魚影シート） |
| `tools/generate_surface_showcase_assets.py` | `assets/showcase/surface/` |
| `tools/generate_tackle_shop_assets.py` | `assets/showcase/tackle_shop/` |
| `tools/generate_title_showcase_assets.py` | `assets/showcase/title/` |
| `tools/generate_top_status_weather_icons.py` | `assets/showcase/common/` |
| `tools/build_quest_board_reference.py` | `reference/11_quest_board_mockup.png`（製品非同梱） |
| `tools/build_shark_pen_reference.py` | `reference/12_shark_pen_mockup.png`（製品非同梱） |

AI生成ソースをPILで後処理するスクリプトは下表に分ける。権利・生成サービスの正本は §4。

| 後処理スクリプト | 出力先 / ソース |
|---|---|
| `tools/generate_shark_fish_assets.py` | `assets/showcase/fish/` の E4サメ9種 + `nushi_danger_reef`。OpenAI生成ソース `tools/source_assets/fish/shark_e4_realistic_sources/` をPILで透過・カード/シート整形 |
| `tools/generate_megalodon_fish_assets.py` | `assets/showcase/fish/megalodon_*`。E4のOpenAI生成ソース `nushi_danger_reef_source.png` をPILで青灰ティント・傷追加・カード/シート整形 |
| `tools/process_fishing_time_slot_assets.py` | E5 Stage 2時間帯素材4枚。OpenAI生成ソース `tools/source_assets/fishing_time_slots/` を既存解像度へクロップ/リサイズし、釣果ベース下段ボタンクロームは日中版基準へ正規化 |
| `tools/process_harbor_plan_assets.py` | 港出港プラン紙面＋行アイコン5点。OpenAI生成ソース `tools/source_assets/harbor/` をマゼンタ透過・ヘッダー帯の焼き込み文字除去・2xリサイズ |

## 3. 音源（BGM / SE） — 記入済み（証拠保全のみ推奨）

`assets/audio/` の全10ファイル（`opening_bgm` / `アタリ_ヒット音` / `外海・回遊ルート` / `岩礁・消波ブロック` / `水中ファイト通常` / `海辺（さざなみ）` / `海辺（少し風が強い）` / `港外・潮目` / `砂浜・かけあがり` / `逃げられた`）は同一条件のため一括記載:

| 項目 | 内容 |
|---|---|
| 生成手段 | **Suno AI（有料プラン）** で生成（2026-07-06 ユーザー確認） |
| 商用利用 | **可**。Suno の有料プランは生成物の商用利用権を購読者に付与する（生成時点の規約による） |
| 帰属表記 | 不要（有料プランの規約による） |
| プラン | **Pro Plan（月額）**。2026-07-06 時点で加入中（次回請求 2026-07-07）をアカウント画面で確認済み |
| 証拠保全 | プラン画面スクショ → `docs/qa/evidence/licensing/2026-07-06_suno_pro_plan.png` として保存（ユーザー保存待ち）。あわせて (a) **Billing History（購読開始からの履歴）**——生成が過去月ならその期間の加入証明になる——と (b) **Suno Terms の商用利用条項ページ**のスクショも同フォルダへ |

今後音源を追加する場合も、生成時のプランと日付をこの節へ追記する。

## 4. AI生成画像（外部サービス由来） — **要記入**

generate スクリプトの出力に**含まれない**画像素材。生成に使ったサービスと当時の商用規約を記録すること。

| 対象 | パス | 生成サービス / 日付 | 商用利用条件 | 記入状態 |
|---|---|---|---|---|
| 魚ポートレート・泳ぎシート（70種×2点 + E2ヌシ7体×2点 + E4サメ9種 + `nushi_danger_reef` + E10メガロドン） | `assets/showcase/fish/` | **OpenAI（Codex App / ChatGPT の画像生成）**（2026-07-06 ユーザー確認）。E2ヌシ7体は既存魚素材を `tools/generate_nushi_fish_assets.py` でプロシージャル派生。E4サメは `tools/source_assets/fish/shark_e4_realistic_sources/` のOpenAI生成ソースを `tools/generate_shark_fish_assets.py` で透過・整形。E10メガロドンは `nushi_danger_reef_source.png` を `tools/generate_megalodon_fish_assets.py` で派生 | **商用利用可**。OpenAI Terms of Use は Output の権利をユーザーに帰属させる（生成時点の規約による）。派生加工分はプロジェクト所有。帰属表記不要 | ✓ |
| docs/35 P1バッチ1 魚素材8種（`houbou`, `kanagashira`, `kyusen`, `kobudai`, `ojisan`, `sayori`, `binnaga`, `konoshiro`） | `tools/source_assets/fish/fish_dedup_2026-07-08_contact_sheet_1.png` → `assets/showcase/fish/<id>_card_portrait.png` / `<id>_showcase_sheet.png` | **OpenAI（Codex App built-in image generation）**（2026-07-08）。4x2コンタクトシートを `tools/process_underwater_fish_assets.py` で透過・泳ぎシート/カード整形 | **商用利用可**。OpenAI Terms of Use は Output の権利をユーザーに帰属させる（生成時点の規約による）。パイプライン整形分はプロジェクト所有。帰属表記不要 | ✓ |
| docs/35 P1バッチ2 魚素材7種（`ira`, `kinmedai`, `akamutsu`, `medai`, `sawara`, `mahaze`, `nenbutsudai`） | `tools/source_assets/fish/fish_dedup_2026-07-08_contact_sheet_2.png` → `assets/showcase/fish/<id>_card_portrait.png` / `<id>_showcase_sheet.png` | **OpenAI（Codex App built-in image generation）**（2026-07-08）。4x2コンタクトシートを `tools/process_underwater_fish_assets.py` で透過・泳ぎシート/カード整形 | **商用利用可**。OpenAI Terms of Use は Output の権利をユーザーに帰属させる（生成時点の規約による）。パイプライン整形分はプロジェクト所有。帰属表記不要 | ✓ |
| docs/35 P2バッチ1 魚素材9種（`meichidai`, `murasoi`, `onikasago`, `kihada`, `mebachi`, `hirasouda`, `suma`, `takabe`, `makogarei`） | `tools/source_assets/fish/fish_dedup_2026-07-08_contact_sheet_3.png` → `assets/showcase/fish/<id>_card_portrait.png` / `<id>_showcase_sheet.png` | **OpenAI（Codex App built-in image generation）**（2026-07-08）。3x3コンタクトシートを `tools/process_underwater_fish_assets.py` で透過・泳ぎシート/カード整形 | **商用利用可**。OpenAI Terms of Use は Output の権利をユーザーに帰属させる（生成時点の規約による）。パイプライン整形分はプロジェクト所有。帰属表記不要 | ✓ |
| docs/35 P2バッチ2 魚素材8種（`shimaaji`, `gingameaji`, `kaiwari`, `ishigarei`, `umitanago`, `ishigakidai`, `oomonhata`, `ara`） | `tools/source_assets/fish/fish_dedup_2026-07-08_contact_sheet_4.png` → `assets/showcase/fish/<id>_card_portrait.png` / `<id>_showcase_sheet.png` | **OpenAI（Codex App built-in image generation）**（2026-07-08）。4x2コンタクトシートを `tools/process_underwater_fish_assets.py` で透過・泳ぎシート/カード整形 | **商用利用可**。OpenAI Terms of Use は Output の権利をユーザーに帰属させる（生成時点の規約による）。パイプライン整形分はプロジェクト所有。帰属表記不要 | ✓ |
| docs/35 P3 魚素材4種（`megochi`, `kurosoi`, `takenokomebaru`, `mejina`） | `tools/source_assets/fish/fish_dedup_2026-07-08_contact_sheet_5.png` → `assets/showcase/fish/<id>_card_portrait.png` / `<id>_showcase_sheet.png` | **OpenAI（Codex App built-in image generation）**（2026-07-08）。2x2コンタクトシートを `tools/process_underwater_fish_assets.py` で透過・泳ぎシート/カード整形 | **商用利用可**。OpenAI Terms of Use は Output の権利をユーザーに帰属させる（生成時点の規約による）。パイプライン整形分はプロジェクト所有。帰属表記不要 | ✓ |
| E5 Stage 2 時間帯READY/釣果ベース4枚（朝まずめ/夜釣り） | `tools/source_assets/fishing_time_slots/*_source.png` → `assets/showcase/surface/surface_scene_ready_asa_mazume.png` / `surface_scene_ready_night.png` / `assets/showcase/underwater/catch_photo_base_asa.png` / `catch_photo_base_night.png` | **OpenAI（Codex App built-in image generation）**（2026-07-08）。既存READY/釣果ベースを構図参照し、`tools/process_fishing_time_slot_assets.py` で既存解像度へクロップ/リサイズ。釣果ベース下段のボタンクロームは runtime ラベル位置に合わせ、日中版 `catch_photo_base.png` から正規化 | **商用利用可**。OpenAI Terms of Use は Output の権利をユーザーに帰属させる（生成時点の規約による）。パイプライン整形分はプロジェクト所有。帰属表記不要 | ✓ |
| 港出港プラン紙面＋行アイコン（Phase A） | `tools/source_assets/harbor/harbor_plan_panel_source.png` / `harbor_plan_icons_contact_source.png` → `assets/showcase/harbor/harbor_plan_panel.png` / `harbor_plan_icon_*.png` / `harbor_weather_stub_icon.png` | **OpenAI（Cursor GenerateImage）**（2026-07-09）。`tools/process_harbor_plan_assets.py` でマゼンタ透過・ヘッダー焼き込み文字除去・リサイズ。タイトル文言は runtime | **商用利用可**。OpenAI Terms of Use は Output の権利をユーザーに帰属させる（生成時点の規約による）。パイプライン整形分はプロジェクト所有。帰属表記不要 | ✓ |
| reference 完成イメージ一式 | `reference/`（`.gdignore` 済・**製品に同梱されない**） | OpenAI生成画像、または `tools/build_quest_board_reference.py` / `tools/build_shark_pen_reference.py` 等のPIL生成 | 製品非同梱のため実務上問題なし。宣伝素材へ転用する場合のみ個別に出所確認 | ✓ |
| 各画面の背景など generate スクリプト外のPNG | 各 `assets/showcase/<screen>/` | 同上（OpenAI）と推定 — **他サービス併用があれば追記** | 同上 | ⚠️ |

**AI生成画像の横断注意（販売時）**:

1. **Steam で販売する場合、AI生成コンテンツの開示義務がある**（Valve のコンテンツ調査で申告し、ストアページに表示される。禁止ではなく開示義務）。→ E11-6
2. 純AI生成画像は日米とも**著作権保護されない可能性が高い**（販売は可能だが、画像単体のコピーを法的に止めにくい）。ゲーム全体（コード・データ設計・構成）は保護される。
3. 既存作品に酷似した出力を使わないこと（docs/08 §避けること のとおり。特に実在ゲームの魚グラフィックとの類似に注意）。

## 5. その他

| 項目 | 状態 |
|---|---|
| ゲームタイトル「釣りクエスト」の商標調査 | 未実施（E11） |
| `assets/icon.svg`（現状Godotデフォルトの可能性） | 差し替え時に本台帳へ記入（E11） |

## 補足: 本台帳の目的（誤解防止）

本台帳は素材の**転用を禁止するためのものではない**。「この素材は販売してよい権利がある」と後から証明するための記録である（ストア審査・権利照会・協業時に即答できる状態を保つ）。転用可否は各サービスの規約が定める。

## 更新履歴

- 2026-07-06: 初版。フォント・プロシージャル素材を記入済み化、音源・AI生成画像を要記入として棚卸し
- 2026-07-06: 音源10件を記入済み化（Suno AI 有料プラン・商用可。証拠保全を推奨事項として追記）。魚画像はAI生成と確認、サービス名のみ要記入
- 2026-07-06: 魚画像の生成元を OpenAI（Codex App / ChatGPT）と確認し記入済み化。商用利用可（Terms of Use による Output 帰属）。Steam のAI開示義務・著作権保護の限界を横断注意として追記
- 2026-07-06: E2ヌシ7体の魚素材を既存魚素材のプロシージャル派生として追加し、生成スクリプトを台帳へ追記
- 2026-07-06: E3依頼ボードのv1参照画像をPIL生成物として追加
- 2026-07-06: E6鳥山演出 `surface_bird_swarm.png` を `tools/generate_surface_showcase_assets.py` に追加
- 2026-07-06: E4サメ9種 + `nushi_danger_reef` の魚素材を `tools/generate_shark_fish_assets.py` で追加。初版のPILプロシージャル素材は品質不足のため、同日OpenAI生成ソース + PIL透過/整形へ差し替え
- 2026-07-06: E4危険海域のマップピン/海図ロックピン/サムネイルを `tools/generate_fishing_spot_map_assets.py` によるPILプロシージャル生成物として追加
- 2026-07-06: 表層釣り演出の3フレーム魚影 `surface_fish_shadow_soft.png` を `tools/generate_surface_fish_shadow.py` によるPILプロシージャル生成物として追加（旧 `surface_fish_shadow.png` はフォールバックとして残置）
- 2026-07-07: E10メガロドン素材2点を `tools/generate_megalodon_fish_assets.py` で追加。E4白帝のOpenAI生成ソースをPIL後処理で派生し、`reference/12_shark_pen_mockup.png` を `tools/build_shark_pen_reference.py` で追加
- 2026-07-07: `reference/13_fishing_ready_danger_mockup.png` を追加（docs/38 READY UI刷新の方向性参照。Cursorエージェントの画像生成ツールで生成、既存スクショ＋`reference/12` を参照入力に使用。`.gdignore` 済・製品非同梱）
- 2026-07-07: `reference/14_underwater_fight_simple_mockup.png` を追加（docs/39 水中ファイト刷新・docs/19 §4.6 基盤レイアウト原則の方向性参照。Cursorエージェントの画像生成ツールで生成、`reference/02`＋`reference/13` を参照入力に使用。`.gdignore` 済・製品非同梱）
- 2026-07-08: docs/35 P1バッチ1として8種（`houbou`, `kanagashira`, `kyusen`, `kobudai`, `ojisan`, `sayori`, `binnaga`, `konoshiro`）のOpenAI生成コンタクトシートを追加し、`tools/process_underwater_fish_assets.py` でカード/泳ぎシートへ整形
- 2026-07-08: docs/35 P1バッチ2として7種（`ira`, `kinmedai`, `akamutsu`, `medai`, `sawara`, `mahaze`, `nenbutsudai`）のOpenAI生成コンタクトシートを追加し、P1 A群15種の新規ソースアート差し替えを完了
- 2026-07-08: docs/35 P2バッチ1として9種（`meichidai`, `murasoi`, `onikasago`, `kihada`, `mebachi`, `hirasouda`, `suma`, `takabe`, `makogarei`）のOpenAI生成コンタクトシートを追加し、現監査pending 8件を解消
- 2026-07-08: docs/35 P2バッチ2として8種（`shimaaji`, `gingameaji`, `kaiwari`, `ishigarei`, `umitanago`, `ishigakidai`, `oomonhata`, `ara`）のOpenAI生成コンタクトシートを追加し、P2 B群17種の新規ソースアート差し替えを完了
- 2026-07-08: docs/35 P3として4種（`megochi`, `kurosoi`, `takenokomebaru`, `mejina`）のOpenAI生成コンタクトシートを追加し、P3境界ケースの新規ソースアート差し替えを完了
- 2026-07-08: E5 Stage 2として時間帯READY2枚（朝まずめ/夜釣り）と釣果写真ベース2枚（朝まずめ/夜釣り）をOpenAI生成し、`tools/process_fishing_time_slot_assets.py` で既存解像度へ整形
- 2026-07-09: E5 Stage 2釣果写真ベースの下段ボタンクロームを日中版基準へ正規化し、朝まずめ/夜釣りの runtime ボタンラベル位置を揃えた
