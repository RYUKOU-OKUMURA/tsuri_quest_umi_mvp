# 水中ファイト画面 QA判断ログ

最終更新: 2026-07-17 / 状態: **FIGHT-A1採用freeze・Visual Wave V2着手前baseline固定 / 次: FIGHT-A2**
参照画像: `reference/14_underwater_fight_simple_mockup.png`（基盤レイアウト） / `reference/02_underwater_fight_mockup.png`（旧v1素材・質感参照）
QA更新コマンド: `./tools/fight_visual_qa.sh`（reference/14 + runtime capture標準） / 入力確認: `godot --headless --path . res://tools/fishing_input_smoke.tscn` / 水面天候確認: `./tools/surface_weather_visual_qa.sh` / 釣り上げ結果確認: `godot --path . res://tools/catch_fanfare_preview.tscn`（通常魚確認は `TSURI_CATCH_FANFARE_FISH_ID=aji`）
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
| 水中魚表示の上下/左右安全域 | `UnderwaterView._target_fish_center()` で、泳ぎシートの描画サイズから上下/左右margin（8px以上）を逆算してX/Y中心をclamp | `src/ui/components/underwater_view.gd` | シマアジを含む大きい魚が水面側/海底側へ寄ったときの上端・下端見切れと、アラのような横長魚が右端へ寄ったときの顔見切れP1を防ぐ。`FishingSimulator.visual_position` は変更しない |
| 旧派生crop修正とP2新規ソース化 | `rouninaji.contact_crop` 上端修正は `rouninaji/ishidai/akahata/kajiki` 系の残存派生向けfreeze。docs/35 P2対象の `shimaaji/gingameaji/kaiwari/ishigakidai/oomonhata` は2026-07-08バッチ2で `dedup_20260708_4` の `source + contact_crop` に置換済み。`medai` / `nenbutsudai` は2026-07-08 P1バッチ2で新規ソース化済み | `tools/process_underwater_fish_assets.py` / `assets/showcase/fish/*_{showcase_sheet,card_portrait}.png` | 旧cropは背びれ・背中を水平切断していたため修正したが、docs/35対象魚は形状差が主目的なのでtemplate派生へ戻さない |
| docs/35 P3魚素材 | `megochi/kurosoi/takenokomebaru/mejina` は `dedup_20260708_5` の `source + contact_crop` に置換済み。P3暫定allowlistは削除し、監査で残る類似は意図的派生のみ | `tools/process_underwater_fish_assets.py` / `assets/showcase/fish/{megochi,kurosoi,takenokomebaru,mejina}_*` | コチ/メバル派生の色替え境界を、配置値ではなく新規source artで解消。カードは頭左向き、泳ぎシート先頭フレームは頭右向き |

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
| BITE/FIGHT入力focus契約 | CASTING/WAITING/APPROACHはfocus候補なしで、早期EnterではFIGHTへ進まない。BITEはアワセ1候補へ初期focusし、`E` またはfocus中の `Enter/KP Enter` でFIGHTへ移る。FIGHTは `巻く` → `糸を出す` の2候補へ共通focus ringを付け、`Space` / `Shift` のpress/release契約を維持する。Esc確認は安全側の `続ける` を初期focusにし、見出し44px・説明56pxの文字領域を確保して、閉じた後に直前のFIGHT focusへ戻す | `src/ui/fishing_screen.gd` / `src/ui/components/fight_hud.gd` | キーechoではheld actionを重複変更しない。modal表示時は背景入力を遮断し、mouse held actionも解放する。各HUD Rect2・ゲージ・ゲームロジックは変更しない |
| ゲージ | 18分割セグメント | `fight_hud.gd` | |

### 上部ステータス

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| スロット比率 | 23.5% / 30.0% / 25.0% / 21.5% | `top_status_frame.png` ＋ `fight_status_bar.gd` | |
| アイコン | 38–44px、時計/風/コインは `top_status_icon_sheet.png`（128pxセル）、天気は `weather_status_icon_sheet.png`（5天気128pxセル） | 同上 | スロット比率と文字位置は変更なし。天気アイコンのみ `trip_stats.weather_id` に追従 |
| タイポ | E5以降の1枠目は `時間帯` 14px + 選択ラベル 24px。所持金 24px、天候/風 21/19px、ロケーションカード 14px＋16/19px | `fight_status_bar.gd` | 固定の `AM 08:47` は夜釣りと矛盾するためE5で廃止。スロット比率とアイコン位置は維持 |

### 右カラム / フローティングカード

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| READY右カラム | 右326px前後。釣り場情報・魚影/状態・仕掛けカードを表示 | `fishing_screen.gd` / `fight_sidebar.gd` | docs/38 READY専用。釣り場詳細はREADYにだけ残す |
| CASTING〜FIGHT | 右カラムを隠し、シーンを全幅へ拡張。シーン右上に約288x120pxのフローティングカード1枚 | `fishing_screen.gd` / `fight_sidebar.gd` | docs/39採用による改定。旧サイドバー寸法はFIGHT/中間状態へ戻さない |
| floating-card外装 | 288×120px文字なし専用PNG `fight_floating_card_frame.png`。羊皮紙紙面＋濃紺タイトル帯＋細い金縁 | `fight_sidebar.gd` / `tools/process_fight_a1_floating_card.py` | FIGHT-A1採用。source/productとも画面ownerの`underwater/`へ閉じ、runtime文字・rarity・状態値を焼き込まない |
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
| 釣果決定focus契約 | `続けて釣る` → `港へ戻る` の2候補、初期focusは安全側の `続けて釣る`。`Enter/KP Enter` は現在focus中のボタン、`Space` は続行、`Escape` は港帰還を各1回だけ実行する | `src/ui/components/catch_fanfare.gd` / `src/ui/fishing_screen.gd` | 写真ベース・ボタンRect・演出時間・結果文言は変更しない |

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
| 魚表示左右安全域 | 1 | 横長魚が右端/左端へ寄ったときに顔や尾が水窓外へ切れないよう、描画サイズからX中心をclamp | 採用 |
| 旧派生crop修正とP2新規ソース化 | 1 | `rouninaji.contact_crop` 上端切断を修正し、rouninaji/ishidai/akahata/kajiki系を再生成。後続のdocs/35 P2バッチ2で `shimaaji/gingameaji/kaiwari/ishigakidai/oomonhata` は新規 `source + contact_crop` に置換済み。ヌシ派生はdocs/35対象外の意図的派生として扱う | 採用 |
| docs/35 P3魚素材 | 1 | `megochi/kurosoi/takenokomebaru/mejina` を新規source化し、P3暫定allowlistを削除 | 採用 |
| フローティングカード・レアリティ帯 | 1 | 固定50pxから文字幅+paddingへ変更し、「アンコモン」が緑帯内に収まるようにした | 採用 |
| フローティングカード・外装素材 | 1 | 平坦なruntime枠を文字なし羊皮紙＋濃紺帯＋細金縁の専用PNGへ1スロット置換 | 採用・freeze |
| 離脱modal文字領域 | 1 | autowrap Labelの最小高0による押し潰しを、見出し44px・説明56pxの固定文字領域で解消 | 採用・freeze |

## 4. 判定メモ・再検証ルール

- 2026-07-07 docs/39で `./tools/fight_visual_qa.sh` のランタイム実キャプチャを標準に戻し、比較対象を `reference/14_underwater_fight_simple_mockup.png` へ更新済み。docs/39の合格判定ではruntime capture必須。旧静的合成ボードは `TSURI_FIGHT_RUNTIME_CAPTURE=0` を明示したときだけ出るレガシー補助資料で、採用判断には使わない。
- 注: 2026-06-26 パスの証拠画像は `/tmp` のみに残され失われた。以後の採用判断では `docs/qa/evidence/underwater_fight/` へのコピーを必須とする。

## 5. 現在の残ギャップ

- **P2**: 下段140pxスリムバーのauthored専用PNG化は後続`FIGHT-A2`。FIGHT-A1採用済みカードをbeforeとして別採否にし、カードとバーを同一判断へ戻さない。
- **P3**: 参照の行動アイコン相当の装飾密度は`FIGHT-A2`以降へ後続化する。現行288×120pxでは魚名・rarity・推定サイズ・行動文が判断情報として成立しており、アイコン追加は文字safe-areaまたは情報配置の再設計を伴うため、外装1スロットだけを置換するFIGHT-A1へ混ぜない。
- **残**: 魚のアニメ/接地の微ポリッシュ、背景中央の理想画質、ヒットバッジの最終合わせ。非快晴の水面状態は天気専用ベースを維持済み。専用の状態別×天気PNG量産はしない。

## 6. フェーズスコープ宣言（作業中のみ）

（現在作業中のフェーズなし。FIGHT-A1は2026-07-17に独立再レビューP0/P1/P2/P3 0で採用・freeze。次は下段バーだけを扱うFIGHT-A2）

## 7. 判断ログ（直近パスのみ）

- 2026-07-17: Visual Wave V2の共通起点 `e297692a` で、FIGHT-A2着手前のstandard / `巻く` focusを再固定。`./tools/fight_visual_qa.sh` exit 0。証拠は `docs/qa/evidence/underwater_fight/2026-07-17_v2_prebaseline_{standard,focus}.png` と `2026-07-17_v2_prebaseline_standard_reference_compare.png`。FIGHT-A2のallowed-diffはFIGHT時の下段140px HUD rect内だけで、A1カードを含む下段外、READY 224px、中間4状態、上部、背景、魚、line/lure、入力/modal/fanfareはこのbaselineから回帰させない。

- 2026-07-17: 独立レビューP2を解消。TIP内legacy toggleで作ったbeforeを廃止し、base `6d37322b`へTIPと同一の決定fixture（partly-cloudy固定、`_view._time=1.25`、同一描画待ち、standardはfocus解放）だけを一時適用したfresh capture `2026-07-17_fight_a1_base_6d37322b_recapture.png`を正式beforeとした。builderはbase decoded RGB SHA-256=`1791a4a46abd9d937844cee719842391351c339cad970c34b1d75f9042f27372`、TIP after=`2c265b09f3f7ccc15d2a5b81a868af45c83c91fd703a8fda07ee6d0cab8cdc30`、base→TIP全差分bbox=`(953,109)-(1243,231)`、カード外差分0pxを機械検証し、base自身/no-op/legacy afterをrejectする。全画面可視率と64×48px局所tileも検査し、header/HUDだけが黒矩形になる不完全captureを拒否する。focus証拠はafterと同じfixtureで`巻く`を実focus ownerにしたfresh capture（decoded RGB SHA-256=`ee6027f2378cb95b00db9560f27d8854987d52c1888d5818c0be557740abd626`）とし、standardとの差をring固有bbox=`(443,628)-(636,692)`・1,961pxだけに固定するため、standard-after-as-focus、非水中FIGHT、ringなし、操作文字未描画をrejectする。negative probeとして`--after=<base>`と`--focus=<standard after>`を個別投入し、両方が`ValueError`で終了することを確認した。P3の行動アイコンは288×120pxの文字safe-area/情報配置再設計を伴うためFIGHT-A2以降へ分離する。

- 2026-07-17: 修正TIP `77e45fa8`を実装者とは別のread-only reviewerが再確認し、P0/P1/P2/P3すべて0件。親もbase/TIP原寸、focus、カード外差分0、大型右端寄り、未確認/長文状態と全smokeを独立確認したため、FIGHT-A1を採用・freezeした。

- 2026-07-17: `FIGHT-A1`を局所upliftとして採用。右上288×120pxカードの外形・runtime文字座標・`RarityStyles`動的幅を維持し、背景だけを画面専用の文字なし羊皮紙＋濃紺帯＋細金縁PNGへ置換した。base `6d37322b`の同一決定fixture beforeとTIP afterのカード外画素差0を`tools/build_fight_a1_evidence.py`が検証し、原寸before/afterと320×180 after/referenceで平坦な紙面・帯・縁の差が縮小。未確認、`アカシュモクザメ`＋`アンコモン`＋実データ最長級行動文、アラ右端寄り大型でP1なし。focus/離脱modal/fanfareは実入力回帰green。証拠: `2026-07-17_fight_a1_{base_6d37322b_recapture,standard_before,standard_after,standard_before_after,card_before_after_reference,after_reference_320x180,unrevealed,long_rarity_name_action,ara_right_edge,focus_regression,modal_regression,fanfare_regression}.png`。下段140pxバー、READY、上部、背景、魚、safe clamp、line/lure、18分割ゲージ、入力ロジックは不変。

- 2026-07-17: INPUT統合後のV0 visual baselineを、V1 `FIGHT-A1` 着手前状態として再固定。`./tools/fight_visual_qa.sh` の標準クロダイと、`TSURI_FIGHT_FISH_ID=ara TSURI_FIGHT_VISUAL_X=0.86 TSURI_FIGHT_VISUAL_Y=0.46 TSURI_FIGHT_VISUAL_DIRECTION=1` のアラ右端寄りをruntime captureし、いずれもexit 0。証拠は `docs/qa/evidence/underwater_fight/2026-07-17_v1_prebaseline_{standard,ara_right_edge}.png` と各 `_reference_compare.png`。A1は右上floating card一枚だけを対象とし、下段140pxバー、READY 224px、上部、背景、魚、魚位置/clamp、line anchor、入力/modal/fanfareをこのbaselineから回帰させない。

- 2026-07-15: E11 INPUT-FISHINGのCASTING〜FIGHT・離脱modal・釣果決定入力契約を採用・freeze。CASTING/WAITING/APPROACHはfocus候補なし・早期Enter無効、BITEはアワセへ初期focus、FIGHTは `巻く` / `糸を出す` の2候補とした。Esc確認は安全側 `続ける` 初期focusを維持し、P1だった見出し/説明の押し潰しを44px/56pxの文字領域で解消した。釣果は `続けて釣る` / `港へ戻る` の2候補で、Enter/Spaceに加えてEscapeの港帰還1回発火を実Viewportイベントで確認した。既存のHUD/overlay外形/写真ベースのRect、素材、ゲージ、釣行ロジック、魚データ、バランスは変更なし。証拠: `docs/qa/evidence/underwater_fight/2026-07-15_input_fight_focus.png`、`2026-07-15_input_quit_focus.png`、`2026-07-15_input_fanfare_focus.png`。検証: `fishing_input_smoke.tscn` / `fishing_harbor_return_smoke.tscn` / `catch_fanfare_smoke.tscn` green、E11 strict input probeの `FISHING` finding 0件、`./tools/fight_visual_qa.sh` runtime横並び比較exit 0、`./tools/validate_project.sh` exit 0。

- 2026-07-09: アラがファイト中に右端へ寄ったとき、顔が水窓外へ切れるP1を修正。`UnderwaterView._clamp_showcase_fish_center()` を上下だけでなく左右にも適用し、泳ぎシートの描画サイズからX/Y中心を水窓内へclampする。`FishingSimulator.visual_position`、魚素材、ラインアンカー、上部ステータス、下段HUD、釣行ロジックは変更なし。再現用に `tools/fishing_fight_preview.gd` へ `TSURI_FIGHT_VISUAL_X/Y/DIRECTION` を追加し、通常のQAキャプチャ既定値は維持した。検証: `TSURI_FIGHT_FISH_ID=ara TSURI_FIGHT_VISUAL_X=0.86 TSURI_FIGHT_VISUAL_Y=0.46 TSURI_FIGHT_VISUAL_DIRECTION=1 ./tools/fight_visual_qa.sh` exit 0。証拠: `docs/qa/evidence/underwater_fight/2026-07-09_ara_right_edge_clip_fix.png`、`docs/qa/evidence/underwater_fight/2026-07-09_ara_right_edge_reference_compare.png`。
- 2026-07-08: E5時間帯対応として上部ステータス1枠目を固定の `AM 08:47` から `時間帯` + 選択ラベルへ変更。夜釣りで時計表示が矛盾しないようにするためで、スロット比率、アイコンサイズ、天候/所持金/ロケーション枠は維持した。検証: `./tools/fight_visual_qa.sh` exit 0。証拠: `docs/qa/evidence/underwater_fight/2026-07-08_e5_time_slot_top_status_compare.png`。
- 2026-07-08: docs/35 P3魚素材差し替え。対象4種（`megochi`, `kurosoi`, `takenokomebaru`, `mejina`）の泳ぎシートは頭右向き、カード肖像は頭左向きで整形した。コチ/メバル派生の境界ケースと縞の強いメジナ元絵を新規source artで解消し、P3暫定allowlistを削除。画面freeze値、`UnderwaterView`、`FightSidebar`、釣行ロジックは変更なし。検証: `./tools/fight_visual_qa.sh` exit 0、`python3 tools/audit_fish_sheet_contract.py` exit 0、`python3 tools/audit_fish_asset_duplicates.py --strict` exit 0（allowed 1、pending 0、unexpected 0）。証拠: `docs/qa/evidence/underwater_fight/2026-07-08_p3_fight_targets.png`、`docs/qa/evidence/underwater_fight/2026-07-08_p3_fight_compare.png`、`docs/qa/evidence/underwater_fight/2026-07-08_p3_fish_asset_contact.png`。
- 2026-07-08: docs/35 P1バッチ2魚素材差し替え。対象7種（`ira`, `kinmedai`, `akamutsu`, `medai`, `sawara`, `mahaze`, `nenbutsudai`）の泳ぎシートは頭右向き、カード肖像は頭左向きで整形した。小型/丸型魚は `runtime_offset_x` でline_anchor近傍に口元が乗るよう調整し、fish sheet contract監査と `TSURI_FIGHT_FISH_ID=<fish_id>` 指定の実キャプチャでライン/ルアー接続を確認。画面freeze値、`UnderwaterView`、`FightSidebar`、釣行ロジックは変更なし。検証: `./tools/fight_visual_qa.sh` exit 0、`python3 tools/audit_fish_sheet_contract.py` exit 0、`python3 tools/audit_fish_asset_duplicates.py` exit 0（pending 14→8、unexpected 0）、`./tools/validate_project.sh` exit 0。証拠: `docs/qa/evidence/underwater_fight/2026-07-08_p1_batch2_fight_targets.png`、`docs/qa/evidence/underwater_fight/2026-07-08_p1_batch2_fight_compare.png`。
- 2026-07-08: docs/35 P2バッチ1魚素材差し替え。対象9種（`meichidai`, `murasoi`, `onikasago`, `kihada`, `mebachi`, `hirasouda`, `suma`, `takabe`, `makogarei`）の泳ぎシートは頭右向き、カード肖像は頭左向きで整形した。`runtime_offset_x` でline_anchor近傍に口元が乗るよう調整し、fish sheet contract監査と `TSURI_FIGHT_FISH_ID=<fish_id>` 指定の実キャプチャでライン/ルアー接続を確認。画面freeze値、`UnderwaterView`、`FightSidebar`、釣行ロジックは変更なし。検証: `./tools/fight_visual_qa.sh` exit 0、`python3 tools/audit_fish_sheet_contract.py` exit 0、`python3 tools/audit_fish_asset_duplicates.py --strict` exit 0（pending 8→0、unexpected 0）。証拠: `docs/qa/evidence/underwater_fight/2026-07-08_p2_batch1_fight_targets.png`、`docs/qa/evidence/underwater_fight/2026-07-08_p2_batch1_fight_compare.png`。
- 2026-07-08: docs/35 P2バッチ2魚素材差し替え。対象8種（`shimaaji`, `gingameaji`, `kaiwari`, `ishigarei`, `umitanago`, `ishigakidai`, `oomonhata`, `ara`）の泳ぎシートは頭右向き、カード肖像は頭左向きで整形した。`runtime_offset_x` でline_anchor近傍に口元が乗るよう調整し、fish sheet contract監査と `TSURI_FIGHT_FISH_ID=<fish_id>` 指定の実キャプチャでライン/ルアー接続を確認。これでP2 B群17種の `source` + `contact_crop` 化を完了。画面freeze値、`UnderwaterView`、`FightSidebar`、釣行ロジックは変更なし。検証: `./tools/fight_visual_qa.sh` exit 0、`python3 tools/audit_fish_sheet_contract.py` exit 0、`python3 tools/audit_fish_asset_duplicates.py --strict` exit 0（pending 0、unexpected 0）。証拠: `docs/qa/evidence/underwater_fight/2026-07-08_p2_batch2_fight_targets.png`、`docs/qa/evidence/underwater_fight/2026-07-08_p2_batch2_fight_compare.png`。
- 2026-07-08: rouninaji/ishidai/akahata/kajiki の `contact_crop` 上端切断修正。`process_underwater_fish_assets.py` で4魚のcrop座標を実bboxへ合わせ、関連派生9魚（rouninaji, shimaaji, gingameaji, kaiwari, ishidai, ishigakidai, akahata, oomonhata, kajiki）の泳ぎシート/カード肖像を選択再生成。画面freeze値、`UnderwaterView`、釣行ロジックは変更なし。検証: 上端±2px最長連続列メトリクス全対象100px未満（修正前 shimaaji=238→22、rouninaji=247→26、akahata=359→8 等）、`python3 tools/audit_fish_sheet_contract.py` exit 0（88 sheets）、`python3 tools/audit_fish_asset_duplicates.py` exit 0（unexpected 0。副次効果で rouninaji系/ishidai系のpendingペアも類似解消）、`./tools/fight_visual_qa.sh` exit 0、`./tools/fish_book_visual_qa.sh` exit 0、`./tools/validate_project.sh` exit 0、`TSURI_FIGHT_FISH_ID=shimaaji` 実機キャプチャで背びれ復元を目視確認。`nushi_rock_breakwater` はヌシの意図的派生としてdocs/35の対象外。証拠: `docs/qa/evidence/underwater_fight/2026-07-08_shimaaji_dorsal_crop_fix.png`、`docs/qa/evidence/fish_assets/2026-07-08_dorsal_crop_fix_grid.png`。
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
