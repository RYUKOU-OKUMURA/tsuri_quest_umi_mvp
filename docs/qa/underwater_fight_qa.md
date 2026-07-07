# 水中ファイト画面 QA判断ログ

最終更新: 2026-07-08 / 状態: **docs/39 水中ファイト基盤UI刷新 採用・freeze改定済み / docs/35 P1 A群15種差し替え済み**
参照画像: `reference/14_underwater_fight_simple_mockup.png`（基盤レイアウト） / `reference/02_underwater_fight_mockup.png`（旧v1素材・質感参照）
QA更新コマンド: `./tools/fight_visual_qa.sh`（reference/14 + runtime capture標準） / 水面天候確認: `./tools/surface_weather_visual_qa.sh` / 釣り上げ結果確認: `godot --path . res://tools/catch_fanfare_preview.tscn`（通常魚確認は `TSURI_CATCH_FANFARE_FISH_ID=aji`）
詳細な経過履歴: `docs/qa/archive/underwater_fight_design_qa_2026-06.md`（旧 `design-qa.md`）

## 新魚素材投入時チェックリスト

`tools/audit_fish_sheet_contract.py` で泳ぎシートのサイズ・4フレーム構成・1フレーム1魚・line_anchor近傍は自動監査する。頭の向きは自動判定が不安定なため、素材追加・差し替え時は必ず次を実スクショで確認する。

- 泳ぎシート `*_showcase_sheet.png` の先頭フレームは、既存魚と同じく頭が右向き。
- `./tools/fight_visual_qa.sh` または `TSURI_FIGHT_FISH_ID=<fish_id>` 指定の実キャプチャで、ライン/ルアーが口元（吻の下）に接続し、頬・エラ・目に重ならない。
- カード肖像 `*_card_portrait.png` は、既存慣例どおり頭が左向き。

## 1. freeze値（正本）

P1破綻（黒帯・マスク境界・残像・破綻カットアウト・文字衝突/見切れ・魚/ライン/距離が読めない）の再発時以外は動かさない。次の品質向上は値いじりではなく素材差し替えで行う。

### 背景

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 背景ビルド | `tools/build_reference_underwater_background.py` の決定的パイプライン一式（全窓抽出＋広い被写体マスク＋エッジ安全クロップのみ） | `assets/showcase/underwater/underwater_battle_bg.png` | 明るさ・泡・床光・中央密度の再調整ループ禁止 |
| ヘルパーオーバーレイ透過 | color grade 0.10 / seabed detail 0.22 | `src/ui/components/underwater_view.gd` | 旧ヘルパー層が中央を暗く覆うのを防ぐ採用値 |
| テクスチャ配置 | top-biased cover `Vector2(0.5, 0.24)` | 同上 | 水面光を可視域に入れる |

### 水面キャスト天候

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 天気系統 | `sunny / partly_cloudy / cloudy / rain / fog`。`sunny_windy` は `weather_id=sunny` の風強互換枠 | `GameData.FISHING_ENVIRONMENTS` | 天気は5系統、環境は風違い込み6エントリ |
| 描画方式 | READYは `trip_stats.weather_id` に応じた専用シーンPNGを優先する。非快晴のCASTING/WAITING/APPROACH/BITEは同じ天気専用ベースを維持し、WAITINGは波紋、APPROACH以降は魚影、BITEはスプラッシュをruntimeで重ねる。快晴は既存状態別シーンPNGを使う | `src/ui/components/surface_cast_view.gd` | 上部/右/下部HUDのfreeze値は動かさない。雨/霧は専用画像の上に効果overlayのみ重ね、色味gradeの二重掛けを避ける |
| 採用素材 | `surface_scene_ready_sunny.png` / `surface_scene_ready_partly_cloudy.png` / `surface_scene_ready_cloudy.png` / `surface_scene_ready_rain.png` / `surface_scene_ready_fog.png` / `surface_weather_partly_cloudy_grade.png` / `surface_weather_cloudy_grade.png` / `surface_weather_rain_grade.png` / `surface_weather_rain_overlay.png` / `surface_weather_fog_grade.png` / `surface_weather_fog_overlay.png` | `assets/showcase/surface/` | 非快晴の水面状態は天気専用READY画像をベースとして維持。状態別×天気画像は量産しない |
| 検証画像 | `docs/qa/evidence/underwater_fight/2026-07-04_surface_weather_asset_contact_sheet.png` / `2026-07-04_surface_weather_ready_compare.png` / `2026-07-04_surface_scene_ready_weather_runtime_compare.png` / `2026-07-04_surface_fog_state_consistency_compare.png` / `2026-07-04_surface_weather_icon_compare.png` / `2026-07-04_surface_weather_status_icon_compare.png` | `tools/surface_weather_visual_qa.sh` / `tools/fishing_surface_states_preview.gd` | 晴れ・曇り・雨・霧のREADY専用画像差、霧のREADY→BITE状態連続性、上部天候ラベルと天気アイコンの見切れなしを確認 |

### 魚（クロダイ）

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| ソースアート | `tools/source_assets/kurodai_final_art_source.png` | `tools/process_underwater_fish_assets.py` | 次の魚改善は真のソース差し替えのみ（配置/スケール調整で埋めない） |
| 中心オフセット | `SHOWCASE_FISH_CENTER_OFFSET = Vector2(-0.070, 0.008)` | `underwater_view.gd` | |
| 描画幅 | 水窓幅の 0.525 | 同上 | |
| ヒット時フラッシュ | 0.10 | 同上 | 0.52 は鱗・背鰭・目が白飛びし不採用 |
| ルアー前方オフセット | 魚幅の約 0.44 | 同上 | 鼻先と融合しない距離 |
| 泳ぎシート | 尾側のみ変化する4フレーム | `assets/showcase/fish/kurodai_showcase_sheet.png` | クローン4枚へ戻さない |

### 魚（共通表示・個別素材）

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 水中魚表示の上下安全域 | `UnderwaterView._target_fish_center()` で、泳ぎシートの実描画高さから上下margin（8px以上）を逆算してY中心をclamp | `src/ui/components/underwater_view.gd` | シマアジを含む大きい魚が水面側/海底側へ寄ったときの上端・下端見切れP1を防ぐ。`FishingSimulator.visual_position` は変更しない |
| シマアジ派生素材 | `process_underwater_fish_assets.py` の `rouninaji.contact_crop` 上端修正＋関連派生9魚の泳ぎ/カード再生成。`shimaaji.scale_y = 1.00` は維持。`medai` / `nenbutsudai` は同日のdocs/35 P1バッチ2で新規ソース化 | `tools/process_underwater_fish_assets.py` / `assets/showcase/fish/{rouninaji,shimaaji,gingameaji,kaiwari,ishidai,ishigakidai,akahata,oomonhata,kajiki}_*` | 旧cropは背びれ・背中を水平切断し、rouninaji派生（シマアジ含む）の上端が平坦化していたP1。2026-07-07の `scale_y` 補正だけでは根本原因未解消 |

### ヒット・距離表示

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| ヒット表現 | `hit_badge_full.png` 優先（burst＋描画テキストはフォールバック） | `underwater_view.gd` | 文字とバーストを光学的に一体化 |
| バッジ中心/スケール | 水窓の 49%/76.5%、スケール 0.47–0.56 | 同上 | |
| 距離メーター | 水窓幅28% / 244px上限、9pxラベル、低alpha | 同上 | 長いシアンのデバッグバー化を防ぐ |

### 下部HUD

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 表示高さ | READY=224px / CASTING〜FIGHT=140px | `fishing_screen.gd` / `fight_hud.gd` | docs/39採用による改定。旧214px試行の不採用理由はREADY側にのみ残す |
| 下段構成 | READY=docs/38専用バー / CASTING〜BITE=タナ・アワセ・反応+餌情報 / FIGHT=テンション・巻く/糸を出す+タナ・魚体力 | `fight_hud.gd` | 旧「エサ26.5% / メニュー17.5% / 操作ヒント」はFIGHT/中間状態では廃止 |
| 操作表記 | 実キー `Space` / `Shift` / `E / Enter`。FIGHT中は `Space` / `Shift` の主操作のみ、CASTING〜BITEは `E / Enter` のアワセを中心表示 | `fight_hud.gd` ほか | A/B/L/R 表記へ戻さない。`+ 釣り場変更` / `- 港へ戻る` はREADYのみ。FIGHT中の離脱はEscオーバーレイ |
| ゲージ | 18分割セグメント | `fight_hud.gd` | |

### 上部ステータス

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| スロット比率 | 23.5% / 30.0% / 25.0% / 21.5% | `top_status_frame.png` ＋ `fight_status_bar.gd` | |
| アイコン | 38–44px、時計/風/コインは `top_status_icon_sheet.png`（128pxセル）、天気は `weather_status_icon_sheet.png`（5天気128pxセル） | 同上 | スロット比率と文字位置は変更なし。天気アイコンのみ `trip_stats.weather_id` に追従 |
| タイポ | AM 16px（濃色）、時刻/所持金 24px、AM→時刻オフセット 31px、天候/風 21/19px、ロケーションカード 14px＋16/19px | `fight_status_bar.gd` | AM/時刻間隔は再調整禁止 |

### 右カラム / フローティングカード

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| READY右カラム | 右326px前後。釣り場情報・魚影/状態・仕掛けカードを表示 | `fishing_screen.gd` / `fight_sidebar.gd` | docs/38 READY専用。釣り場詳細はREADYにだけ残す |
| CASTING〜FIGHT | 右カラムを隠し、シーンを全幅へ拡張。シーン右上に約288x120pxのフローティングカード1枚 | `fishing_screen.gd` / `fight_sidebar.gd` | docs/39採用による改定。旧サイドバー寸法はFIGHT/中間状態へ戻さない |
| 未確認カード | 「未確認の魚影」＋反応タグ＋行動行。魚名・レア度・推定サイズは出さない | `fight_sidebar.gd` | 正体秘匿を維持。APPROACH/BITEの餌魚主語文言は行動行へ移す |
| 判明後カード | 魚名＋レア度バッジ＋推定サイズ＋行動行。生態解説・タックル欄は表示しない | `fight_sidebar.gd` | ファイト中の判断に使わない情報を削除し、図鑑/仕掛け画面へ役割分担 |

### キャッチ演出

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 成功時結果画面 | 魚なし写真風ベースを全面表示し、runtime見出し「釣り上げた！」、既存魚ポートレートの前面合成、結果プレート文字、下部2ボタン「続けて釣る」「港へ戻る」を表示。自動終了とスキップはなし | `src/ui/components/catch_fanfare.gd` / `src/ui/fishing_screen.gd` | 成功時の旧白い結果パネルは出さない。失敗時の「逃げられた……」結果パネルは維持 |
| 写真風ベース素材 | `catch_photo_base.png` 1枚を全面表示し、その上へ魚だけを重ねる | `assets/showcase/underwater/catch_photo_base.png` | 日本語テキストと魚本体は焼き込まない。手前指マスクは使わず、魚が指を隠す方針 |
| 魚画像参照 | `FightFishAssets.card_portrait_path()` 経由 | `catch_fanfare.gd` | 魚素材所有ルールを維持。直接パス参照なし |
| 音 | `AudioStreamGenerator` による短い合成ファンファーレ | `catch_fanfare.gd` | 専用SE素材がないため、P0ではruntime生成で効果音経路を成立させる |
| 検証画像 | `docs/qa/evidence/underwater_fight/2026-07-03_catch_result_photo_boss.png` / `2026-07-03_catch_result_photo_aji.png` | `tools/catch_fanfare_preview.gd` | 通常起動キャプチャ。ぬし魚と通常魚で魚差し替え、ボタン統合、文字視認性を確認 |
| レアリティ色責務 | `RarityStyles.text_color()` 経由 | `src/ui/components/catch_fanfare.gd` | レア紙吹雪色を含め、UI側で `Palette.RARITY_*` を直接参照しない |

### フォント

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| ファイト画面フォント | LINE Seed JP（Eb/Bd/Rg）、AA有効 | `src/ui/game_fonts.gd` | 2026-07-05 AA方針統一（docs/19 §4.2 確定）に伴い `fight_fonts.gd` を削除し `game_fonts.gd` へ一本化。AA無効テキストはヒット演出のフォールバックのみで、PNGバッジ素材があるため実画面には描画されていなかった |

## 2. 不採用・再試行禁止リスト

| 案 | 却下理由 | 判断日 |
|---|---|---|
| DotGothic16 の全画面一括置換 | 上部数値・カード本文・HUDラベルが細くなりプレミアム感喪失 | 2026-06 |
| DelaGothicOne（ボールド候補） | 上部数値がロゴ的になりすぎる | 2026-06 |
| RocknRoll One（ボールド候補） | 軽すぎる | 2026-06 |
| タックルカード 4行14px | 参照より情報密度不足 | 2026-06 |
| タックルカード 6行（`ウキ：なし` 含む） | 全画面比較で文字が小さすぎる | 2026-06 |
| HUD高さ 214px | 水窓が縦に窮屈 | 2026-06 |
| HUD紙面の半透明インセット | テキストが暗い板に沈む | 2026-06 |
| 参照魚の自動閾値抽出 | 水背景の汚染・下側シルエット欠け。次はauthoredソースか手動マスク抽出のみ | 2026-06 |
| 被写体マスクを狭める背景ビルド | 元絵の魚残像が再発 | 2026-06 |
| 強めの候補ディテール背景パス | 中央水域が暗くなる | 2026-06 |
| ヒットフラッシュ 0.52 | ヒット瞬間に魚が白飛び | 2026-06 |
| 低密度の手描き分割写真素材（背面・手前手・枠の3PNG） | 添付完成イメージの品質に届かず、キャラクターと背景が簡素すぎる。以後は魚なし高品質ベース1枚＋魚前面合成を採用 | 2026-07-03 |

## 3. 微調整カウンタ

（v1 freeze中のため空。次のフェーズ着手時に docs/qa/README.md の書式で記録する。旧ログでは魚位置オフセット6回以上・HUD高さ4回・背景約30パスの反復が起きており、このカウンタはその再発防止のためにある）

| パラメータ | 回数 | 直近の変更内容 | 状態 |
|---|---|---|---|
| キャッチ演出・補足文 | 1 | 長文の結果補足が省略表示になったため、「初回記録」「撃破報酬」の短い2行へ変更 | 採用 |
| キャッチ演出・表示時間 | 2 | 釣り上げ演出を成功結果画面へ統合し、自動終了を廃止してプレイヤー選択待ちに変更 | 採用 |
| キャッチ演出・写真ベース | 1 | 右カード型の手描き分割素材をやめ、魚なし高品質ベース1枚＋既存魚ポートレート前面合成へ変更 | 採用 |
| キャッチ演出・結果統合 | 1 | 成功時の旧白い結果ポップアップを廃止し、写真風画面の下部ボタンから「続けて釣る」「港へ戻る」を直接実行 | 採用 |
| キャッチ結果・港ボタン位置 | 1 | 「港へ戻る」runtimeテキストがボタン枠より右へ寄っていたため、右ボタンスロットを30px左へ移動 | 採用 |
| 水面天候overlay | 1 | 5天気の候補contact sheetから、状態別PNG量産ではなくgrade/overlay方式を採用 | 採用 |
| 水面天気専用ベース | 3 | READY用の5天気フル画像を生成後、`SurfaceCastView` で `weather_id` に応じてruntime採用。非快晴はキャスト後も同じ天気ベースを維持 | 採用 |
| 上部天気アイコン | 1 | `weather_id` 未参照で晴れ固定だったため、5天気シートを追加して上部アイコンだけを天気追従に変更 | 採用 |
| 魚表示上下安全域 | 1 | 描画時に泳ぎシートの実描画高さからY中心をclampし、上端/下端見切れを防止 | 採用 |
| シマアジ派生素材 | 1 | `rouninaji.contact_crop` 上端切断を修正し、rouninaji/ishidai/akahata/kajiki系9魚を再生成。`scale_y=1.00` は維持。`nushi_rock_breakwater` はP3再評価へ回す | 採用 |
| フローティングカード・レアリティ帯 | 1 | 固定50pxから文字幅+paddingへ変更し、「アンコモン」が緑帯内に収まるようにした | 採用 |

## 4. 判定メモ・再検証ルール

- 2026-07-07 docs/39で `./tools/fight_visual_qa.sh` のランタイム実キャプチャを標準に戻し、比較対象を `reference/14_underwater_fight_simple_mockup.png` へ更新済み。docs/39の合格判定ではruntime capture必須。旧静的合成ボードは `TSURI_FIGHT_RUNTIME_CAPTURE=0` を明示したときだけ出るレガシー補助資料で、採用判断には使わない。
- 注: 2026-06-26 パスの証拠画像は `/tmp` のみに残され失われた。以後の採用判断では `docs/qa/evidence/underwater_fight/` へのコピーを必須とする。

## 5. 現在の残ギャップ

- **P2**: reference/14の最終アート質感（フローティングカード/スリムバー専用PNG化、カード縁やボタン質感のauthored素材化）は未着手。現状は共通paletteのruntime描画でv1採用。
- **残**: 魚のアニメ/接地の微ポリッシュ、背景中央の理想画質、ヒットバッジの最終合わせ。非快晴の水面状態は天気専用ベースを維持済み。専用の状態別×天気PNG量産はしない。

## 6. フェーズスコープ宣言（作業中のみ）

（現在作業中のフェーズなし。docs/39は2026-07-07に採用・freeze改定済み）

## 7. 判断ログ（直近パスのみ）

- 2026-07-08: docs/35 P1バッチ2魚素材差し替え。対象7種（`ira`, `kinmedai`, `akamutsu`, `medai`, `sawara`, `mahaze`, `nenbutsudai`）の泳ぎシートは頭右向き、カード肖像は頭左向きで整形した。小型/丸型魚は `runtime_offset_x` でline_anchor近傍に口元が乗るよう調整し、fish sheet contract監査と `TSURI_FIGHT_FISH_ID=<fish_id>` 指定の実キャプチャでライン/ルアー接続を確認。画面freeze値、`UnderwaterView`、`FightSidebar`、釣行ロジックは変更なし。検証: `./tools/fight_visual_qa.sh` exit 0、`python3 tools/audit_fish_sheet_contract.py` exit 0、`python3 tools/audit_fish_asset_duplicates.py` exit 0（pending 14→8、unexpected 0）、`./tools/validate_project.sh` exit 0。証拠: `docs/qa/evidence/underwater_fight/2026-07-08_p1_batch2_fight_targets.png`、`docs/qa/evidence/underwater_fight/2026-07-08_p1_batch2_fight_compare.png`。
- 2026-07-08: docs/35 P2バッチ1魚素材差し替え。対象9種（`meichidai`, `murasoi`, `onikasago`, `kihada`, `mebachi`, `hirasouda`, `suma`, `takabe`, `makogarei`）の泳ぎシートは頭右向き、カード肖像は頭左向きで整形した。`runtime_offset_x` でline_anchor近傍に口元が乗るよう調整し、fish sheet contract監査と `TSURI_FIGHT_FISH_ID=<fish_id>` 指定の実キャプチャでライン/ルアー接続を確認。画面freeze値、`UnderwaterView`、`FightSidebar`、釣行ロジックは変更なし。検証: `./tools/fight_visual_qa.sh` exit 0、`python3 tools/audit_fish_sheet_contract.py` exit 0、`python3 tools/audit_fish_asset_duplicates.py --strict` exit 0（pending 8→0、unexpected 0）。証拠: `docs/qa/evidence/underwater_fight/2026-07-08_p2_batch1_fight_targets.png`、`docs/qa/evidence/underwater_fight/2026-07-08_p2_batch1_fight_compare.png`。
- 2026-07-08: rouninaji/ishidai/akahata/kajiki の `contact_crop` 上端切断修正。`process_underwater_fish_assets.py` で4魚のcrop座標を実bboxへ合わせ、関連派生9魚（rouninaji, shimaaji, gingameaji, kaiwari, ishidai, ishigakidai, akahata, oomonhata, kajiki）の泳ぎシート/カード肖像を選択再生成。画面freeze値、`UnderwaterView`、釣行ロジックは変更なし。検証: 上端±2px最長連続列メトリクス全対象100px未満（修正前 shimaaji=238→22、rouninaji=247→26、akahata=359→8 等）、`python3 tools/audit_fish_sheet_contract.py` exit 0（88 sheets）、`python3 tools/audit_fish_asset_duplicates.py` exit 0（unexpected 0。副次効果で rouninaji系/ishidai系のpendingペアも類似解消）、`./tools/fight_visual_qa.sh` exit 0、`./tools/fish_book_visual_qa.sh` exit 0、`./tools/validate_project.sh` exit 0、`TSURI_FIGHT_FISH_ID=shimaaji` 実機キャプチャで背びれ復元を目視確認。未解決: `nushi_rock_breakwater` 自体の上端平坦（E2コンタクトシート由来の既存事象）はP3で再評価。証拠: `docs/qa/evidence/underwater_fight/2026-07-08_shimaaji_dorsal_crop_fix.png`、`docs/qa/evidence/fish_assets/2026-07-08_dorsal_crop_fix_grid.png`。
- 2026-07-08: docs/35 P1バッチ1魚素材差し替え。対象8種（`houbou`, `kanagashira`, `kyusen`, `kobudai`, `ojisan`, `sayori`, `binnaga`, `konoshiro`）の泳ぎシートは頭右向き、カード肖像は頭左向きで整形した。`runtime_offset_x` でline_anchor近傍に口元が乗るよう調整し、fish sheet contract監査と `TSURI_FIGHT_FISH_ID=<fish_id>` 指定の実キャプチャでライン/ルアー接続を確認。画面freeze値、`UnderwaterView`、`FightSidebar`、釣行ロジックは変更なし。検証: `./tools/fight_visual_qa.sh` exit 0、`python3 tools/audit_fish_sheet_contract.py` exit 0、`python3 tools/audit_fish_asset_duplicates.py` exit 0（pending 26→14、unexpected 0）。証拠: `docs/qa/evidence/underwater_fight/2026-07-08_p1_batch1_fight_targets.png`、`docs/qa/evidence/underwater_fight/2026-07-08_p1_batch1_fight_compare.png`。
- 2026-07-07: シマアジ上部見切れ・アンコモン帯はみ出しのP1修正。`UnderwaterView` は魚の実描画高さから上下安全域を計算してY中心をclampし、大型魚/端寄り魚の上端・下端見切れを予防する。シマアジは `process_underwater_fish_assets.py` の派生値 `scale_y` を 0.90→1.00 に戻し、`shimaaji_card_portrait.png` / `shimaaji_showcase_sheet.png` だけ再生成した。`FightSidebar` はレアリティ帯を文字幅+paddingの動的幅へ変更し、「アンコモン」を省略・はみ出しなしで表示する。魚のロジック、上部ステータス、下段HUD、釣果フローは変更なし。検証: シマアジ/イヌザメ/釣果の通常起動キャプチャ、全魚上端alpha接触監査0件、`python3 tools/audit_fish_sheet_contract.py`、`./tools/fight_visual_qa.sh`、`fishing_reveal_smoke.tscn`、`fishing_harbor_return_smoke.tscn`、`catch_fanfare_smoke.tscn`、`./tools/validate_project.sh`。証拠: `docs/qa/evidence/underwater_fight/2026-07-07_shimaaji_clip_fix_fight.png`、`2026-07-07_uncommon_badge_fit_fight.png`、`2026-07-07_shimaaji_clip_fix_catch.png`、`2026-07-07_shimaaji_asset_before_after.png`。
- 2026-07-07: docs/39 水中ファイト基盤UI刷新を採用。FIGHT下段を140pxスリムバーへ改定し、右サイドバーを廃止してシーン右上フローティングカードへ魚名/レア度/推定サイズ/行動行を集約。CASTING/WAITING/APPROACH/BITEも同じスリムバーに寄せ、BITEの主操作を `E / Enter` のアワセへ集中させた。READY右カラム・docs/38餌魚セレクタ・上部ステータス・背景/魚素材・天候overlay・釣果ファンファーレ・`FishingSimulator` ロジックは変更なし。検証: `./tools/validate_project.sh`、`./tools/fight_visual_qa.sh`、`./tools/surface_weather_visual_qa.sh`、`fishing_surface_states_preview.tscn`、釣行系smoke。証拠: `docs/qa/evidence/underwater_fight/2026-07-07_docs39_final_fight_runtime.png`、`2026-07-07_docs39_final_reference14_compare.png`、`2026-07-07_docs39_final_surface_weather_state_matrix.png`、`2026-07-07_docs39_final_surface_casting.png`、`2026-07-07_docs39_final_surface_waiting.png`、`2026-07-07_docs39_final_surface_approach.png`、`2026-07-07_docs39_final_surface_bite.png`、`2026-07-07_docs39_slice3_danger_lure_approach.png`、`2026-07-07_docs39_slice3_danger_lure_bite.png`。
- 2026-07-05: catch fanfareのレア紙吹雪色を `Palette.RARITY_RARE_TEXT` 直接参照から `RarityStylesScript.text_color("レア")` へ移行。表示色は同値で、レアリティ色責務を `src/ui/rarity_styles.gd` に閉じた。freeze値、素材、レイアウト、表示文言、日本語PNG焼き込みは変更なし。検証: `catch_fanfare_smoke.tscn`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。通常起動プレビュー証拠: `docs/qa/evidence/underwater_fight/2026-07-05_catch_fanfare_rarity_styles.png`。
- 2026-07-05: RF2 Palette移行完了。`fight_hud.gd` / `surface_cast_view.gd` / `fight_sidebar.gd` / `underwater_view.gd` / `fight_status_bar.gd` / `fishing_screen.gd` / `catch_fanfare.gd` の生色を `Palette.FIGHT_*` / `Palette.SURFACE_*` / `Palette.UNDERWATER_*` / `Palette.CATCH_*` 等へ移行し、対象7ファイルraw color監査0件。freeze値、素材所有、レイアウト、表示文言、日本語PNG焼き込みは変更なし。検証: `fight_visual_qa.sh`、`surface_weather_visual_qa.sh`、`fishing_reveal_smoke.tscn`、`fishing_harbor_return_smoke.tscn`、`catch_fanfare_smoke.tscn`、`save_system_verify.sh`、`validate_project.sh` green。証拠: `docs/qa/evidence/underwater_fight/2026-07-05_rf2_palette_fight_compare.png`, `2026-07-05_rf2_palette_surface_weather_compare.png`, `2026-07-05_rf2_palette_catch_fanfare.png`。
- 2026-07-05: RF5棚卸しとして `./tools/fight_visual_qa.sh` を再実行し、静的比較を永続証拠へコピー。フォントAA待ちTODOは、`game_fonts.gd` AA有効統一と旧 `fight_fonts.gd` 削除により解消済みとして削除した。当時残したランタイム実スクショ再判定TODOは、2026-07-07 docs/39のruntime capture標準化で解消済み。
- 2026-07-03: キャッチ演出を写真風ベース方式へ更新。`assets/showcase/underwater/catch_photo_base.png` を全面表示し、魚本体は `FightFishAssets.card_portrait_path()` の既存ポートレートを前面合成する。日本語テキストと魚はPNGへ焼き込まない。採用判断は `docs/qa/evidence/underwater_fight/2026-07-03_catch_photo_base_boss.png` と `docs/qa/evidence/underwater_fight/2026-07-03_catch_photo_base_aji.png`。既存の水中背景・HUD・上部・右サイドバー・成功後結果パネルのフローは変更していない。自動終了/スキップは `tools/catch_fanfare_smoke.tscn` で検証済み。
- 2026-07-03: 成功時の旧白い結果ポップアップを廃止し、写真風釣り上げ画面を結果選択画面に統合。`CatchFanfare` は自動終了せず、`continue_requested` / `harbor_requested` で既存の次釣行・港遷移に接続する。魚位置を上げ、左情報枠を広げ、runtime文字にアウトラインと薄い紙色スクリムを追加。採用判断は `docs/qa/evidence/underwater_fight/2026-07-03_catch_result_photo_boss.png` と `docs/qa/evidence/underwater_fight/2026-07-03_catch_result_photo_aji.png`。新UX契約は `tools/catch_fanfare_smoke.tscn` で検証済み。
- 2026-07-04: 上部ステータスバーの天気アイコンが晴れ固定だった問題を修正。`weather_status_icon_sheet.png` を追加し、`FightStatusBar` が `trip_stats.weather_id` から `sunny / partly_cloudy / cloudy / rain / fog` の5種を選択する。水面・天気ラベル・風ラベルの既存挙動は変更なし。採用判断は `docs/qa/evidence/underwater_fight/2026-07-04_surface_weather_icon_compare.png` と `docs/qa/evidence/underwater_fight/2026-07-04_surface_weather_status_icon_compare.png`。
- 2026-07-03: 写真風釣り上げ結果画面の「港へ戻る」ボタン位置を補正。右ボタンのruntimeテキスト領域を `x=704` から `x=674` へ移動し、ベース素材のボタン枠中心へ合わせた。採用判断は `docs/qa/evidence/underwater_fight/2026-07-03_catch_result_harbor_button_align.png`。
- 2026-07-04: P3天気パターンとして水面READYの5天気差分を採用。`assets/showcase/surface/surface_weather_contact_sheet.png` で候補比較し、`SurfaceCastView` は既存状態別シーンPNGの上へ天候grade/overlayを重ねる方式にした。HUD/右サイドバー/上部ステータスのfreeze値は変更していない。採用判断は `docs/qa/evidence/underwater_fight/2026-07-04_surface_weather_asset_contact_sheet.png` と `docs/qa/evidence/underwater_fight/2026-07-04_surface_weather_ready_compare.png`。`./tools/surface_weather_visual_qa.sh` で晴れ・晴れ曇り・曇り・小雨・霧のREADY画面差分と天候ラベル見切れなしを確認済み。
- 2026-07-04: 水面READY用の天気専用フル画像5枚を生成し、`SurfaceCastView` でruntime採用。`sunny` は現行READYを維持し、`partly_cloudy/cloudy/rain/fog` は空・遠景・海面反射まで含めて描き分けた。非快晴はキャスト後も同じ天気ベースを維持し、状態手がかりはWAITINGが波紋、APPROACH以降が魚影、BITEがスプラッシュになるようruntimeで重ねる。雨/霧は天気専用画像の上に効果overlayのみ重ね、色味gradeの二重掛けはしない。HUD/右サイドバー/上部ステータスのfreeze値は変更していない。採用判断は `docs/qa/evidence/underwater_fight/2026-07-04_surface_scene_ready_weather_contact_sheet.png`、`docs/qa/evidence/underwater_fight/2026-07-04_surface_scene_ready_weather_candidate_compare.png`、`docs/qa/evidence/underwater_fight/2026-07-04_surface_scene_ready_weather_runtime_compare.png`、`docs/qa/evidence/underwater_fight/2026-07-04_surface_fog_state_consistency_compare.png`。
