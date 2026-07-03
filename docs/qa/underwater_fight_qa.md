# 水中ファイト画面 QA判断ログ

最終更新: 2026-07-03 / 状態: **v1 showcase 合格・freeze中**（2026-06-26 判定）+ P0キャッチ演出写真風化
参照画像: `reference/02_underwater_fight_mockup.png`
QA更新コマンド: `./tools/fight_visual_qa.sh` / P0演出確認: `godot --path . res://tools/catch_fanfare_preview.tscn`（通常魚確認は `TSURI_CATCH_FANFARE_FISH_ID=aji`）
詳細な経過履歴: `docs/qa/archive/underwater_fight_design_qa_2026-06.md`（旧 `design-qa.md`）

## 1. freeze値（正本）

P1破綻（黒帯・マスク境界・残像・破綻カットアウト・文字衝突/見切れ・魚/ライン/距離が読めない）の再発時以外は動かさない。次の品質向上は値いじりではなく素材差し替えで行う。

### 背景

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 背景ビルド | `tools/build_reference_underwater_background.py` の決定的パイプライン一式（全窓抽出＋広い被写体マスク＋エッジ安全クロップのみ） | `assets/showcase/underwater/underwater_battle_bg.png` | 明るさ・泡・床光・中央密度の再調整ループ禁止 |
| ヘルパーオーバーレイ透過 | color grade 0.10 / seabed detail 0.22 | `src/ui/components/underwater_view.gd` | 旧ヘルパー層が中央を暗く覆うのを防ぐ採用値 |
| テクスチャ配置 | top-biased cover `Vector2(0.5, 0.24)` | 同上 | 水面光を可視域に入れる |

### 魚（クロダイ）

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| ソースアート | `tools/source_assets/kurodai_final_art_source.png` | `tools/process_underwater_fish_assets.py` | 次の魚改善は真のソース差し替えのみ（配置/スケール調整で埋めない） |
| 中心オフセット | `SHOWCASE_FISH_CENTER_OFFSET = Vector2(-0.070, 0.008)` | `underwater_view.gd` | |
| 描画幅 | 水窓幅の 0.525 | 同上 | |
| ヒット時フラッシュ | 0.10 | 同上 | 0.52 は鱗・背鰭・目が白飛びし不採用 |
| ルアー前方オフセット | 魚幅の約 0.44 | 同上 | 鼻先と融合しない距離 |
| 泳ぎシート | 尾側のみ変化する4フレーム | `assets/showcase/fish/kurodai_showcase_sheet.png` | クローン4枚へ戻さない |

### ヒット・距離表示

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| ヒット表現 | `hit_badge_full.png` 優先（burst＋描画テキストはフォールバック） | `underwater_view.gd` | 文字とバーストを光学的に一体化 |
| バッジ中心/スケール | 水窓の 49%/76.5%、スケール 0.47–0.56 | 同上 | |
| 距離メーター | 水窓幅28% / 244px上限、9pxラベル、低alpha | 同上 | 長いシアンのデバッグバー化を防ぐ |

### 下部HUD

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 表示高さ | 224px | `fishing_screen.gd` / `fight_hud.gd` | 214px試行は水窓が窮屈で不採用 |
| 下段比率 | エサ 26.5% / メニュー 17.5% / 残り操作ヒント | `fight_hud_frame.png` ＋ runtime | |
| 操作表記 | 実キー `Space` / `Shift` / `E / Enter`、`+ 釣り場変更` / `- 港へ戻る` | `fight_hud.gd` ほか | A/B/L/R 表記へ戻さない。`Esc` は入力のみ（表示しない） |
| ゲージ | 18分割セグメント | `fight_hud.gd` | |

### 上部ステータス

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| スロット比率 | 23.5% / 30.0% / 25.0% / 21.5% | `top_status_frame.png` ＋ `fight_status_bar.gd` | |
| アイコン | 38–44px、`top_status_icon_sheet.png`（128pxセル） | 同上 | |
| タイポ | AM 16px（濃色）、時刻/所持金 24px、AM→時刻オフセット 31px、天候/風 21/19px、ロケーションカード 14px＋16/19px | `fight_status_bar.gd` | AM/時刻間隔は再調整禁止 |

### 右サイドバー

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| ヘッダー | 高さ 7.71%、タイトル/カウント 1px アウトライン | `sidebar_frame.png` ＋ `fight_sidebar.gd` | |
| 魚カード | y=9.18% h=48.83%、ポートレート88%スケール・-9px/-15px、窓高42.5%、推定 16px/26px、生態 14px | 同上 | ポートレートは `kurodai_card_portrait.png`（560x310、透明左向き切り抜き）。泳ぎシート直描画へ戻さない |
| アクション/タックル | y=59.18% / 80.08%、h=19.53% / 18.75%、アクションタイトル21px・メッセージ15px | 同上 | |
| タックルカード | **5行13px（ロッド/リール/ライン/ハリス/針）、104pxアイコンレーン、118x86pxロッド/リール切り抜き** | 同上 | v1公式値。`docs/11_underwater_fight_showcase.md` と共通 |

### キャッチ演出

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 成功時ファンファーレ | 2.8秒のruntime描画オーバーレイ。魚なし写真風ベース、runtime見出し「釣り上げた！」、既存魚ポートレートの前面合成、結果プレート文字、スキップボタンを表示 | `src/ui/components/catch_fanfare.gd` / `src/ui/fishing_screen.gd` | 既存の結果パネルは演出完了後に表示。既存freeze値は動かさない |
| 写真風ベース素材 | `catch_photo_base.png` 1枚を全面表示し、その上へ魚だけを重ねる | `assets/showcase/underwater/catch_photo_base.png` | 日本語テキストと魚本体は焼き込まない。手前指マスクは使わず、魚が指を隠す方針 |
| 魚画像参照 | `FightFishAssets.card_portrait_path()` 経由 | `catch_fanfare.gd` | 魚素材所有ルールを維持。直接パス参照なし |
| 音 | `AudioStreamGenerator` による短い合成ファンファーレ | `catch_fanfare.gd` | 専用SE素材がないため、P0ではruntime生成で効果音経路を成立させる |
| 検証画像 | `docs/qa/evidence/underwater_fight/2026-07-03_catch_photo_base_boss.png` / `2026-07-03_catch_photo_base_aji.png` | `tools/catch_fanfare_preview.gd` | 通常起動キャプチャ。ぬし魚と通常魚で魚差し替え確認 |

### フォント

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| ファイト画面フォント | ボールド系 `MPLUS1p-ExtraBold.ttf`＋本文 `MPLUS1p-Regular.ttf`、AA無効 | `src/ui/fight_fonts.gd` | AA方針は全体で分裂中（docs/19 §4.2 課題） |

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
| キャッチ演出・表示時間 | 1 | 釣り上げ演出が短すぎたため、自動終了を1.85秒から2.8秒へ延長 | 採用 |
| キャッチ演出・写真ベース | 1 | 右カード型の手描き分割素材をやめ、魚なし高品質ベース1枚＋既存魚ポートレート前面合成へ変更 | 採用 |

## 4. 暫定判定・再検証TODO

- [ ] サンドボックス環境で非headlessのGodotプレビューがクラッシュし、headless `SubViewport` キャプチャも不可のため、v1判定の一部は静的合成ボード（`tools/build_fight_*_static_compare.py`）による**暫定**。通常キャプチャ復旧後に `./tools/fight_visual_qa.sh` で実スクショ比較を再生成し、`/tmp/tsuri_fight_compare.png`・`/tmp/tsuri_frame_focus_compare.png`・サイドバー魚カードのフォーカス比較を再判定する。
- [ ] fight系フォントAA無効のランタイム文字品質は、実ディスプレイでのキャプチャ確認待ち（静的ボードはPILテキストのためAAの実挙動を反映しない）。
- 注: 2026-06-26 パスの証拠画像は `/tmp` のみに残され失われた。以後の採用判断では `docs/qa/evidence/underwater_fight/` へのコピーを必須とする。

## 5. 現在の残ギャップ

- **P2**: 右パネル/HUD/上部の最終authored素材・専用タイポグラフィ品質が参照に未達。生成フレームの機械的な印象が残る。→ 対応は次フェーズ（下記）であり、フレーム素材のマイクロポリッシュ続行ではない。
- **P3**: 魚のアニメ/接地の微ポリッシュ、背景中央の理想画質、ヒットバッジの最終合わせ。P3のみを理由に作業しない。

## 6. フェーズスコープ宣言（作業中のみ）

（現在作業中のフェーズなし）

## 7. 判断ログ（直近パスのみ）

- 2026-07-03: キャッチ演出を写真風ベース方式へ更新。`assets/showcase/underwater/catch_photo_base.png` を全面表示し、魚本体は `FightFishAssets.card_portrait_path()` の既存ポートレートを前面合成する。日本語テキストと魚はPNGへ焼き込まない。採用判断は `docs/qa/evidence/underwater_fight/2026-07-03_catch_photo_base_boss.png` と `docs/qa/evidence/underwater_fight/2026-07-03_catch_photo_base_aji.png`。既存の水中背景・HUD・上部・右サイドバー・成功後結果パネルのフローは変更していない。自動終了/スキップは `tools/catch_fanfare_smoke.tscn` で検証済み。
