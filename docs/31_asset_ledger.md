# 31. 素材台帳（作者・ライセンス・入手元）

作成日: 2026-07-06
目的: `docs/08_独自性と権利メモ.md` §制作ルール「使用素材の作者、ライセンス、入手元を台帳化する」の実体。**販売（ローンチ）前に「要記入」をゼロにすることが E11 の完了条件の一つ**（docs/v2/E11_launch_readiness.md）。

運用ルール:

- 新しい素材・音源・フォントを追加したら、**同じコミットで本台帳に行を足す**
- 「入手元」は再取得できる具体性で書く（URL、生成スクリプト名、生成サービス名＋日付）
- AI生成サービスを使った場合は、サービス名・生成日・当時の商用利用規約の要点を書く

RIGHTS-01A状態marker（`docs/qa/evidence/licensing/README.md` の未完/完了表と同時更新）:

`pending`から`complete`へ移す時はmarkerだけを書き換えず、対象実体行の`U-XX待ち`等を除去して`U-XX解決済み`へ更新する。監査はmarkerと実体proseの両方を照合する。

- `[RIGHTS-01A:U-01]=pending`
- `[RIGHTS-01A:U-02]=pending`
- `[RIGHTS-01A:U-03]=pending`
- `[RIGHTS-01A:U-04]=pending`
- `[RIGHTS-01A:U-05]=pending`
- `[RIGHTS-01A:U-06]=pending`
- `[RIGHTS-01A:U-08]=pending`

2026-07-12の全件監査は `docs/qa/evidence/licensing/2026-07-12_RIGHTS-01A_AUDIT.md`。リポジトリ側の棚卸し・証拠受入準備は完了したが、U-01〜U-06・U-08は外部証拠待ちであり、RIGHTS-01A全体は未完了。

## 1. フォント — 記入済み・問題なし

| 素材 | パス | 作者/出所 | ライセンス | 同梱ライセンス文書 |
|---|---|---|---|---|
| LINE Seed JP（Rg / Bd / Eb） | `assets/fonts/line_seed/` | LY Corporation | SIL OFL 1.1（商用可） | `assets/fonts/line_seed/OFL.txt` ✓ |
| M PLUS 1p（Regular / Bold / ExtraBold） | `assets/fonts/` | The M+ FONTS Project | SIL OFL 1.1（商用可） | `assets/fonts/OFL-MPLUS1p.txt` ✓ |

## 2. スクリプト生成/後処理PNG — 純粋生成と外部source消費を分離

スクリプト名が `generate_*` であることや、外部APIを実行時に呼ばないことだけでは、出力の権利は確定しない。`tools/source_assets/**` や参照画像を `Image.open` 等で読み込む処理は、入力画像の権利を引き継ぐ **source-consuming pipeline** として §4 / U-03 / U-08 の対象にする。純粋生成として確定できるのは、外部画像を画素入力に使わないコード描画部分・素材だけである。

### 2.1 外部sourceを画素入力にしない生成物

| 生成スクリプト | 出力先 |
|---|---|
| `tools/generate_fish_book_book_frame.py` / `generate_fish_book_paper_assets.py` | `assets/showcase/fish_book/` |
| `tools/generate_fish_market_assets.py` | `assets/showcase/fish_market/market_header_frame.png`, `inventory_panel_frame.png`, `detail_panel_frame.png`, `cart_panel_frame.png`（2026-07-14時点。プロジェクト所有の純PIL生成と既存 `common/parchment_card.png` の中央紙面テクスチャ再利用。旧一枚backplateを表示同値で分解。`market_bg` / `ice_tray_hero` はM2で§2.2、汎用主CTAは下記common生成経路へ移行） |
| `tools/generate_common_primary_action_assets.py` | `assets/showcase/common/primary_action_{normal,hover,pressed,focus,disabled}.png`（2026-07-14、プロジェクト所有の純PIL決定的生成。文字・数字・魚・画面固有意匠なしの汎用9-slice追加variant。既存common素材を上書きせず、魚市場から参照。旧 `fish_market/cart_action_*` とdecoded pixels完全同一） |
| `tools/process_cooking_c1b_assets.py` | `tools/source_assets/cooking/c1b_recipe_{card_frame,selected_card_frame,title_band}_source.png` → `assets/showcase/cooking/recipe_card_frame.png`, `recipe_selected_card_frame.png`, `recipe_title_band.png`（2026-07-17採用。Codexが純PILで作成した羊皮紙・木/金細枠・濃紺帯。外部画像の画素入力、日本語焼き込み、魚/料理絵なし） |
| 手作業SVG（港の司令盤モックから分解） | `assets/showcase/common/harbor_command_icon_sheet.svg`（Codex作成、2026-07-10、プロジェクト所有。文字・第三者素材なし） |
| 手作業SVG（港の司令盤共通フレーム） | `assets/showcase/common/harbor_command_dark_frame.svg`（Codex作成、2026-07-10、プロジェクト所有。端9px内に罫線を収めた文字なし9-slice素材、第三者素材なし） |
| 既存PIL生成素材のcommon昇格コピー | `assets/showcase/common/harbor_command_cta.png`（`assets/showcase/harbor/harbor_time_slot_btn_selected.png` の司令盤CTA/選択状態向けコピー、2026-07-10、プロジェクト所有。新規外部生成なし） |
| `tools/generate_surface_fish_shadow.py` | `assets/showcase/surface/surface_fish_shadow_soft.png`（3フレーム魚影シート） |
| `tools/generate_top_status_weather_icons.py` | `assets/showcase/common/` |
| `tools/build_quest_board_reference.py` | `reference/11_quest_board_mockup.png`（製品非同梱） |
| `tools/build_shark_pen_reference.py` | `reference/12_shark_pen_mockup.png`（製品非同梱） |

`generate_cooking_showcase_assets.py` と `generate_surface_showcase_assets.py` は参照画像・既存画像も読むため、ディレクトリ出力一式を純粋生成とは扱わない。`generate_harbor_info_board_assets.py` も末尾で `process_harbor_plan_assets.py` を呼ぶため、スクリプト実行全体は純粋生成に分類しない。

### 2.2 `tools/source_assets/**` / `reference/**` を消費するパイプライン（全件追跡対象）

下表のsource/reference-consuming pipelineについて、「生成元・日付・入力権利」は、個別記録がある行でもサービス規約の一般条件と第三者権利clearanceを分離する。`reference/` 自体が製品非同梱でも、その画素をcrop/blendして製品PNGへ書き出す経路は派生製品として追跡し、全source/referenceについて採否、生成元、日付、入力権利、製品出力先が揃うまで U-03・U-08 は未完了。

| source群 | 消費スクリプト | 製品出力先 / 採否 | 権利証拠状態 |
|---|---|---|---|
| `fish/*.png`, `fish/shark_e4_realistic_sources/*.png`, `kurodai_final_art_source.png` | `process_underwater_fish_assets.py`, `generate_shark_fish_assets.py`, `generate_megalodon_fish_assets.py`（`generate_nushi_fish_assets.py` のcontact sheetは入力ではなくQA出力） | `assets/showcase/fish/` | 一部にOpenAI・日付記録あり。全sourceの入力権利はU-08待ち |
| `fishing_spot_map_source.png`, `fishing_spot_thumbs/*.png` | `generate_fishing_spot_map_assets.py` | `map_bg.png`, `map_color_grade.png`, `thumbs/{id}.png`（採用済み） | 生成元・日付・入力権利はU-03待ち・U-08待ち |
| `fishing_time_slots/*.png` | `process_fishing_time_slot_assets.py` | `assets/showcase/surface/`, `assets/showcase/underwater/`（一部採用済み、contact sheetは製品非同梱） | 一部にOpenAI・日付記録あり。入力権利はU-08待ち |
| `harbor_hub_bg_source.png`, `harbor/harbor_plan_panel_source.png`, `harbor/harbor_plan_icons_contact_source.png` | `generate_harbor_showcase_assets.py`, `generate_harbor_info_board_assets.py`（plan processorを間接実行）, `process_harbor_plan_assets.py` | `harbor_hub_bg.png`, `harbor_color_grade.png`, `harbor_scene_window.png`, plan panel / icon 5点（採用済み） | plan以外を含む生成元・日付はU-03待ち、入力権利はU-08待ち |
| `shark_pen/shark_pen_tank_bg_source.png` | `generate_shark_pen_assets.py` | `assets/showcase/shark_pen/tank_environment_bg.png`（2026-07-13採用。水槽背景・泡・環境光） | OpenAI built-in image generationの作業記録あり。入力は正式参照と現行runtime capture。入力権利・第三者権利clearanceはU-08待ち |
| `harbor/harbor_info_board_frame_source.png`, `harbor/harbor_info_fish_card_source.png` | `process_harbor_info_board_assets.py` | Phase B AI一点物候補はQAで**不採用・製品未使用**。現行製品はPIL版を維持 | 不採用証拠: `docs/qa/harbor_qa.md` §2。再採用しない限り製品出力なし |
| `quest_board/quest_board_wood_source.png`, `quest_board/quest_notice_card_source.png` | `generate_quest_board_assets.py` | `assets/showcase/quest_board/quest_board_wood_panel.png`, `quest_notice_card.png`（採用済み） | OpenAI built-in生成・日付・source/output対応を§4へ記録。入力はテキストプロンプトのみ、第三者画像入力なし。第三者権利clearanceはU-08待ち |
| `tackle_shop_*_backplate_source.png` | `generate_tackle_shop_assets.py` | `shop_rod_backplate.png`, `shop_rig_backplate.png`, `shop_item_icon_sheet.png`, `shop_detail_item_sheet.png`（採用済み） | 生成元・日付・入力権利はU-03待ち・U-08待ち |
| `title_opening_bg_source.png` | `generate_title_showcase_assets.py` | `title_ocean_bg.png`, `title_color_grade.png`（採用済み） | 生成元・日付・入力権利はU-03待ち・U-08待ち |
| `underwater_battle_bg_source.png` | `enhance_underwater_battle_bg.py` | 履歴上の旧採用経路（`bba599ee` 以前）。現行 `underwater_battle_bg.png` には未使用 | sourceがrepoに残るため、再採用時は生成元・日付・入力権利をU-03・U-08で確認 |
| `sidebar_frame_material_source.png`, `fight_hud_material_source.png`, `top_status_material_source.png` | `generate_underwater_ui_frame_assets.py` | `assets/showcase/underwater/sidebar_frame.png`, `fight_hud_frame.png`, `top_status_frame.png`（採用済み） | 生成元・日付・入力権利はU-03待ち・U-08待ち |
| `reference/02_underwater_fight_mockup.png` + `tools/source_assets/underwater_center_paintover_candidate.png` | `build_reference_underwater_background.py` | `72038061`以降referenceから再構築し、`b6cb03ec`以降はrepoに存在するcenter paintoverも合成。最新更新`463edcbb`までこの経路の `underwater_battle_bg.png` が**現行採用済み** | 両入力の生成元・日付・入力権利と派生利用権はU-03待ち・U-08待ち |
| `reference/02_underwater_fight_mockup.png` | `process_underwater_fish_assets.py` | `hit_badge_full.png`, `fight_lure.png`, `hud_bait_icon.png`, `hud_tension_icon.png`, `hud_stamina_icon.png`, `hud_key_a.png`, `hud_key_b.png`, `hud_key_lr.png`, `hud_key_plus.png`, `hud_key_minus.png`（crop/合成して採用済み） | referenceの生成元・日付・入力権利と派生利用権はU-03待ち・U-08待ち |
| `reference/02_underwater_fight_mockup.png` | `generate_underwater_ui_frame_assets.py` | 紙質crop/blend由来の `top_status_frame.png`, `sidebar_frame.png`, `fight_hud_frame.png`、直接cropの `fight_action_card_icon.png`, `fight_tackle_card_icon.png`（採用済み） | referenceの生成元・日付・入力権利と派生利用権はU-03待ち・U-08待ち |
| `reference/02_underwater_fight_mockup.png` | `extract_top_status_icons.py` | `top_status_icon_sheet.png`（時計・太陽・風・コインをcrop、採用済み） | referenceの生成元・日付・入力権利と派生利用権はU-03待ち・U-08待ち |
| `reference/cooking_flow/01_cook_select_concept.png` | `generate_cooking_showcase_assets.py` | `fish_icon_sheet.png`, `dish_feature_aji_shioyaki.png`、紙質blendを使う各frame、二次派生 `meal_table_spread.png`（採用済み）。`cooking_room_bg.png` はC1-Aで下記source経路へ移行 | referenceの生成元・日付・入力権利と派生利用権はU-03待ち・U-08待ち |
| `cooking/c1a_kitchen_bg_source.png` | `process_cooking_c1a_assets.py` | `assets/showcase/cooking/cooking_room_bg.png`（2026-07-14採用。1280×720、環境のみ、彩度統一+濃紺減光scrim） | OpenAI built-in image generationによるsource。生成入力は正式5状態参照（01はスタイル/環境密度、02〜05は回帰参照）。入力権利・第三者権利clearanceはU-08待ち |
| `fish_market/market_bg_source.png` | `process_fish_market_m2_assets.py market_bg` | `assets/showcase/fish_market/market_bg.png`（2026-07-13、採用済み。1280×720、魚/UI/文字なし、28%減光スクリム） | OpenAI built-in image generationによるsource。生成時のスタイル参照入力と第三者権利clearanceはU-08待ち |
| `fish_market/ice_tray_hero_source.png`, `fish_market/ice_tray_hero_cutout.png` | imagegen skill標準 `remove_chroma_key.py` → `process_fish_market_m2_assets.py ice_tray_hero` | `assets/showcase/fish_market/ice_tray_hero.png`（2026-07-13、採用済み。1280×720透明レイヤー、魚/UI/文字なし） | OpenAI built-in image generationによるsource。生成時のスタイル参照入力と第三者権利clearanceはU-08待ち |
| `cooking/c2_meal_scene_bg_source.png` | `process_cooking_c2_candidate.py` | `tools/source_assets/cooking/c2_meal_scene_bg_candidate.png`（2026-07-14、C2配線レビュー候補。製品未使用・採用/freeze未実施） | OpenAI built-in image generationによるsource。`reference/cooking_flow/02_meal_result_concept.png`、現行runtime capture、現行 `meal_scene_bg.png` は方向性/safe-area参照として生成入力に使用し、processorは生成sourceだけを消費。入力権利・第三者権利clearanceはU-08待ち |
| `status/status_player_fishing_source.png` | `process_status_r5a_assets.py` | `assets/showcase/status/status_player_fishing_portrait.png`（2026-07-14、採用済み。256×256円形alpha、文字/UI/魚なし） | OpenAI built-in image generationによるsource。`reference/08_status_screen_mockup.png`をスタイル/構図参照入力に使用。入力権利・第三者権利clearanceはU-08待ち |

## 3. 音源（BGM / SE） — 条件確認済み・証拠待ち

`assets/audio/` の全10ファイル（`opening_bgm` / `アタリ_ヒット音` / `外海・回遊ルート` / `岩礁・消波ブロック` / `水中ファイト通常` / `海辺（さざなみ）` / `海辺（少し風が強い）` / `港外・潮目` / `砂浜・かけあがり` / `逃げられた`）は同一条件のため一括記載:

| 項目 | 内容 |
|---|---|
| 生成手段 | Suno AIで生成したとのユーザー申告あり。個別10音源との対応と生成日時はU-01待ち |
| サービス規約条件 | **一般条件のみ確認済み**。生成時にPro/Premier加入中で規約を遵守したOutputには、Suno Terms上の権利譲渡と公式Help上の動画ゲーム利用案内がある（2026-07-11確認。https://suno.com/terms/ / https://help.suno.com/en/articles/9601665）。現10件が条件を満たすとの個別clearanceではない |
| 帰属表記 | 公式Helpでは配信時のSuno表記は不要と案内（https://help.suno.com/en/articles/2410177）。ただし入力素材の権利と第三者権利の非侵害は別途必要 |
| プラン | 2026-07-06時点のPro Plan加入とのユーザー申告記録あり。repo内証拠は未保存でU-02待ち |
| 証拠保全 | **未完了**。各mp3の生成日時/曲詳細と、その全期間を覆うBilling History・Pro/Premier加入証拠が必要。規約は公式URLで確認済みだが、現10件が有料加入期間中の生成物であることはrepoだけでは立証できない。保存項目は `docs/qa/evidence/licensing/README.md` U-01/U-02 |

今後音源を追加する場合も、生成時のプランと日付をこの節へ追記する。

## 4. AI生成画像（外部サービス由来） — **要記入**

generate外画像に加え、§2.2のsource-consuming出力も対象。OpenAI Terms上のOutput帰属という一般条件と、各Inputの権利・出力の第三者権利clearanceは別であり、後者はU-08が完了するまで確定しない。

| 対象 | パス | 生成サービス / 日付の記録 | サービス規約条件と個別証拠 | 記入状態 |
|---|---|---|---|---|
| 魚ポートレート・泳ぎシート（70種×2点 + E2ヌシ7体×2点 + E4サメ9種 + `nushi_danger_reef` + E10メガロドン） | `assets/showcase/fish/` | OpenAI（Codex App / ChatGPT）とのユーザー申告記録（2026-07-06）。E2ヌシ7体は既存魚素材の派生、E4サメ・E10はsource-consuming | OpenAI Terms上のOutput帰属という一般条件のみ確認。個別sourceとの対応・入力権利・第三者権利clearanceはU-03待ち・U-08待ち | 未完 |
| docs/35 P1バッチ1 魚素材8種（`houbou`, `kanagashira`, `kyusen`, `kobudai`, `ojisan`, `sayori`, `binnaga`, `konoshiro`） | `tools/source_assets/fish/fish_dedup_2026-07-08_contact_sheet_1.png` → `assets/showcase/fish/{id}_card_portrait.png` / `{id}_showcase_sheet.png` | OpenAI built-in image generationとの作業記録（2026-07-08） | Output帰属の一般条件のみ確認。入力権利・第三者権利clearanceはU-08待ち | 未完 |
| docs/35 P1バッチ2 魚素材7種（`ira`, `kinmedai`, `akamutsu`, `medai`, `sawara`, `mahaze`, `nenbutsudai`） | `tools/source_assets/fish/fish_dedup_2026-07-08_contact_sheet_2.png` → `assets/showcase/fish/{id}_card_portrait.png` / `{id}_showcase_sheet.png` | OpenAI built-in image generationとの作業記録（2026-07-08） | Output帰属の一般条件のみ確認。入力権利・第三者権利clearanceはU-08待ち | 未完 |
| docs/35 P2バッチ1 魚素材9種（`meichidai`, `murasoi`, `onikasago`, `kihada`, `mebachi`, `hirasouda`, `suma`, `takabe`, `makogarei`） | `tools/source_assets/fish/fish_dedup_2026-07-08_contact_sheet_3.png` → `assets/showcase/fish/{id}_card_portrait.png` / `{id}_showcase_sheet.png` | OpenAI built-in image generationとの作業記録（2026-07-08） | Output帰属の一般条件のみ確認。入力権利・第三者権利clearanceはU-08待ち | 未完 |
| docs/35 P2バッチ2 魚素材8種（`shimaaji`, `gingameaji`, `kaiwari`, `ishigarei`, `umitanago`, `ishigakidai`, `oomonhata`, `ara`） | `tools/source_assets/fish/fish_dedup_2026-07-08_contact_sheet_4.png` → `assets/showcase/fish/{id}_card_portrait.png` / `{id}_showcase_sheet.png` | OpenAI built-in image generationとの作業記録（2026-07-08） | Output帰属の一般条件のみ確認。入力権利・第三者権利clearanceはU-08待ち | 未完 |
| docs/35 P3 魚素材4種（`megochi`, `kurosoi`, `takenokomebaru`, `mejina`） | `tools/source_assets/fish/fish_dedup_2026-07-08_contact_sheet_5.png` → `assets/showcase/fish/{id}_card_portrait.png` / `{id}_showcase_sheet.png` | OpenAI built-in image generationとの作業記録（2026-07-08） | Output帰属の一般条件のみ確認。入力権利・第三者権利clearanceはU-08待ち | 未完 |
| E5 Stage 2 時間帯READY/釣果ベース4枚（朝まずめ/夜釣り） | `tools/source_assets/fishing_time_slots/*_source.png` → `assets/showcase/surface/surface_scene_ready_asa_mazume.png` / `surface_scene_ready_night.png` / `assets/showcase/underwater/catch_photo_base_asa.png` / `catch_photo_base_night.png` | OpenAI built-in image generationとの作業記録（2026-07-08） | Output帰属の一般条件のみ確認。入力権利・第三者権利clearanceはU-08待ち | 未完 |
| 港出港プラン紙面＋行アイコン（Phase A） | `tools/source_assets/harbor/harbor_plan_panel_source.png` / `harbor_plan_icons_contact_source.png` → `assets/showcase/harbor/harbor_plan_panel.png` / `harbor_plan_icon_*.png` / `harbor_weather_stub_icon.png` | OpenAI Cursor GenerateImageとの作業記録（2026-07-09） | Output帰属の一般条件のみ確認。入力権利・第三者権利clearanceはU-08待ち | 未完 |
| 魚市場M2 市場背景 | `tools/source_assets/fish_market/market_bg_source.png` → `assets/showcase/fish_market/market_bg.png` | OpenAI built-in image generation（2026-07-13）。`reference/10_fish_market_mockup.png` はスタイル/密度参照として生成入力に使用し、processorは生成sourceだけを消費 | OpenAI Terms上のOutput帰属という一般条件のみ確認。参照入力の権利・出力の第三者権利clearanceはU-08待ち | 未完 |
| 魚市場M2 氷+木箱の査定トレー | `tools/source_assets/fish_market/ice_tray_hero_source.png` / `ice_tray_hero_cutout.png` → `assets/showcase/fish_market/ice_tray_hero.png` | OpenAI built-in image generation（2026-07-13）。`reference/10_fish_market_mockup.png` はスタイル/構図参照として生成入力に使用。クロマキー除去後に決定的processorで整形 | OpenAI Terms上のOutput帰属という一般条件のみ確認。参照入力の権利・出力の第三者権利clearanceはU-08待ち | 未完 |
| 調理C1-A COOK_SELECT厨房背景 | `tools/source_assets/cooking/c1a_kitchen_bg_source.png` → `assets/showcase/cooking/cooking_room_bg.png` | OpenAI built-in image generation（2026-07-14）。正式5状態参照をスタイル/回帰入力に使用し、processorは生成sourceだけを消費。作者はOpenAI image generation + 本セッションの決定的後処理 | OpenAI Terms上のOutput帰属という一般条件のみ確認。参照入力の権利・出力の第三者権利clearanceはU-08待ち | 未完 |
| 依頼ボード木面＋ピン付き無地紙札 | `tools/source_assets/quest_board/quest_board_wood_source.png` / `quest_notice_card_source.png` → `assets/showcase/quest_board/quest_board_wood_panel.png` / `quest_notice_card.png` | OpenAI built-in image generationとの作業記録（2026-07-13）。`docs/46_quest_board_material_uplift_spec.md` の文字なしプロンプトから生成 | Output帰属の一般条件のみ確認。第三者画像入力なし。出力の第三者権利clearanceはU-08待ち | 未完 |
| サメ生簀 水槽背景・泡・環境光 | `tools/source_assets/shark_pen/shark_pen_tank_bg_source.png` → `assets/showcase/shark_pen/tank_environment_bg.png` | OpenAI built-in image generation（2026-07-13）。正式参照 `reference/12_shark_pen_mockup.png` と同日baselineを方向性/safe-area入力に使用 | Output帰属の一般条件のみ確認。入力権利・第三者権利clearanceはU-08待ち | 未完 |
| 調理C2 食事シーン背景候補 | `tools/source_assets/cooking/c2_meal_scene_bg_source.png` → `tools/source_assets/cooking/c2_meal_scene_bg_candidate.png` | OpenAI built-in image generation（2026-07-14）。`docs/51_cooking_c2_meal_scene_asset_brief.md` の文字なし・人物なし・料理なしプロンプトで生成。正式参照、現行runtime、現行背景は方向性/safe-area入力に使用し、processorはsourceだけを決定的加工 | OpenAI Terms上のOutput帰属という一般条件のみ確認。候補は製品未使用。入力権利・出力の第三者権利clearanceはU-08待ち | 未完 |
| ステータスR5-A 海釣り人portrait | `tools/source_assets/status/status_player_fishing_source.png` → `assets/showcase/status/status_player_fishing_portrait.png` | OpenAI built-in image generation（2026-07-14）。`reference/08_status_screen_mockup.png` はスタイル/円形構図参照として生成入力に使用し、processorは生成sourceだけを消費 | OpenAI Terms上のOutput帰属という一般条件のみ確認。参照入力の権利・出力の第三者権利clearanceはU-08待ち | 未完 |
| reference 完成イメージ一式 | `reference/`（`.gdignore` 済で原本は製品非同梱） | OpenAI生成画像、またはPIL生成との従前記録 | `reference/02` と `reference/cooking_flow/01` は§2.2のとおり製品PNGへcrop/blendされているため、原本非同梱だけではclearできない。その他referenceも派生利用有無をU-03で監査 | 未完 |
| 各画面の背景など generate スクリプト外のPNG | 各 `assets/showcase/{screen}/` | **未確定**。OpenAI利用との従前メモはあるが、ファイル単位の生成サービス・日付・作成者申告がなく推定を確定へ昇格できない | サービス確定後、その生成時点の規約と入力権利を確認 | ユーザー入力待ち（証拠index U-03・U-08） |

**AI生成画像の横断注意（販売時）**:

1. **Steam で販売する場合、AI生成コンテンツの開示義務がある**（Valve のコンテンツ調査で申告し、ストアページに表示される。禁止ではなく開示義務）。→ E11-6
2. 純AI生成画像は日米とも**著作権保護されない可能性が高い**（販売は可能だが、画像単体のコピーを法的に止めにくい）。ゲーム全体（コード・データ設計・構成）は保護される。
3. 既存作品に酷似した出力を使わないこと（docs/08 §避けること のとおり。特に実在ゲームの魚グラフィックとの類似に注意）。

## 5. その他

| 項目 | 状態 |
|---|---|
| 正式製品名「釣りクエスト ～海釣り編～」の商標調査 | 正式名称 / v1.0.0は決定#20で確定済み。販売地域・商標対象区分の確定と、その範囲での公式DB検索・必要な専門家確認の証跡は未完（証拠index U-06）。類似検索だけで法的clearance完了とは扱わない |
| `assets/icon.svg`（魚と釣り針のcustom SVG。Godotデフォルトではない） | commit `9a9974a`（2026-06-24）で新規追加された履歴は確認済み。U-04 decisionの現行原本bytesはSHA-256 `493a29b86943751f2441343ebc347a9fa42b046032dedd7d1fcb86fd51567595`へ固定し、非採用後に原本を削除しても同一bytesの再利用を差し替えと認めない。ただしコミット著者だけでは作者・作成手段・権利者を確定できない。製品採否と権利者申告待ち（証拠index U-04） |
| 製品コードのMIT権利者・適用範囲 | `LICENSE.md` に適用範囲を追記。法的権利者名はユーザー入力待ち（証拠index U-05）のためplaceholderを残し、発売不可条件として明示 |
| Godot / font / 同梱依存notice | `THIRD_PARTY_NOTICES.md` を新設し、repoで確認できるGodot・LINE Seed JP・M PLUS 1pを列挙。初回販売=itch.io、対象OS=macOS Universal、bundle ID=`net.physical-balance-lab.tsuri-quest-umi`、予定slug=`tsuri-quest-umi`、store App ID=`未発行`は確定済み。正確なGodot export preset/templateへの配線と、clean exportへの必要notice・OFL全文の同梱確認は未完（証拠index U-07） |
| Steam AI開示 | 初回itch.io版v1.0.0の発売ゲート対象外。将来Steamを採用する場合はOpenAI画像・Suno音源をPre-Generated AIとしてContent Surveyへ申告し、提出控えを保存する（公式: https://partner.steamgames.com/doc/gettingstarted/contentsurvey） |
| itch.io公開時の質問項目 | itch.ioの実公開フローで、AI生成コンテンツ開示、年齢・コンテンツ区分、その他質問票の入力要否を公式手順により確認し、必要な場合は回答控えを保存する（証拠index U-07） |

## 補足: 本台帳の目的（誤解防止）

本台帳は素材の**転用を禁止するためのものではない**。「この素材は販売してよい権利がある」と後から証明するための記録である（ストア審査・権利照会・協業時に即答できる状態を保つ）。転用可否は各サービスの規約が定める。

## 更新履歴

- 2026-07-06: 初版。フォント・プロシージャル素材を記入済み化、音源・AI生成画像を要記入として棚卸し
- 2026-07-06: 音源10件についてSuno AI有料プランとのユーザー申告を記録。当時は記入済みとしたが、2026-07-11の再監査で個別生成日時・加入期間・入力権利が未証明と判明し、U-01/U-02/U-08完了まで未完へ訂正
- 2026-07-06: 魚画像についてOpenAI利用とのユーザー確認を記録。当時「商用利用可」と整理したが、2026-07-11の再監査でOutput帰属の一般条件と個別素材の入力権利・第三者権利clearanceを分離し、U-03・U-08完了まで未完へ訂正
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
- 2026-07-11: Release Gate 0の確定値（正式名、itch.io、macOS Universal）を権利台帳へ同期。U-06/U-07の未完理由を、決定待ちから商標調査証跡・export包装検証待ちへ更新
- 2026-07-11: ID-01のbundle ID、itch.io予定slug、store App ID未発行をU-07へ同期。export presetへの実配線と最終包装検証は未完のまま維持
- 2026-07-13: 魚市場M2 `market_bg` をOpenAI built-in image generation source + 決定的processorへ移行。source・output・生成日を登録し、U-08待ちを維持
- 2026-07-13: 魚市場M2 `ice_tray_hero` をOpenAI built-in image generation source + クロマキー除去 + 決定的processorへ移行。source・cutout・output・生成日を登録し、U-08待ちを維持
- 2026-07-13: 依頼ボードの画面専用木面・ピン付き紙札をOpenAI built-inで生成し、source、加工スクリプト、製品PNGの対応を追加
- 2026-07-13: サメ生簀の水槽背景・泡・環境光をOpenAI built-in image generationで生成し、screen-local authored背景へ統一処理して採用
- 2026-07-14: 調理C1-A `cooking_room_bg.png` をOpenAI built-in生成source + 決定的processorへ移行。source・作者/生成サービス・生成日・output対応を登録し、U-08待ちを維持
- 2026-07-14: 調理C2 `meal_scene_bg` の配線レビュー候補をOpenAI built-in image generation source + 決定的processorで準備。source・candidate・生成日・参照入力を登録し、製品未使用・U-08待ちを維持
- 2026-07-14: ステータスR5-Aの海釣り人sourceをOpenAI built-in image generationで生成し、決定的processorで円形portraitへ整形
