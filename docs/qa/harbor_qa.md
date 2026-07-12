# 港画面 QA判断ログ

最終更新: 2026-07-12 / 状態: 「港の司令盤」採用・freeze
参照画像: `docs/qa/evidence/harbor/2026-07-10_harbor_command_board_mockup_v1.png`
実装仕様: `docs/44_harbor_command_board_spec.md`
QA更新コマンド: `./tools/harbor_visual_qa.sh`（固定previewデータで3時間帯、食事効果なし日中、モック横並び、grayscale、thumbnailを一括生成）

## 1. freeze値（正本）

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 上部ステータス | `(32,24,1216,80)`。港専用 `harbor_top_frame.png`。場所名local `(36,3)`／副題 `(38,41)`、共通 `PlayerStatusBar` 港モードは Lv/EXP y=`7/38`、装備キャプション/竿名 y=`8/29`、所持金 y=`6/27` | `src/ui/harbor_screen.gd` / `components/player_status_bar.gd` | 4クラスタの見た目中心差を0.5px以内へ補正 |
| 左・主情報盤 | `(40,120,788,512)`。共通 `harbor_command_dark_frame.svg`＋暗色スクリム | `src/ui/harbor_screen.gd` | 採用モック実寸 |
| 狙い魚 | 最優先 `(60,172,364,154)`、副候補 `(436,172,180,154)` / `(628,172,180,154)`。魚素材は `FightFishAssets` 経由 | `_build_info_board` | 3件同格を廃止し1＋2の階層にする |
| 狙い目候補 | `_harbor_highlight_candidates(max_count)`。依頼（納品可能を含む）→時間帯ブースト→未捕獲、重複排除・乱数なし | 候補収集関数群 | 情報盤と出港情報で共有 |
| 出港情報 | 3カード `(60,364,270,78)` / `(338,364,270,78)` / `(616,364,192,78)`。目撃談は食事効果あり `(60,450,748,78)`、なし `(60,450,748,114)`。見出し11px・本文15px | `_build_departure_plan_card` / `_apply_meal_dependent_departure_layout` | 非表示になった食事効果36pxを目撃談へ回収 |
| 初心者ガイド | `level <= GROWTH_SOFT_CAP(10)` のみ。調理未経験→依頼未達成→狙い魚要約 | `_departure_guide_summary` | 子供向けの短文を維持 |
| 天気気配 | 「雨・潮目が立ちやすい」の固定スタブ | `_refresh_preparation_card` | 本物の先読み抽選は別設計 |
| 時間帯 | 朝 `(132,576,216,44)`、日中 `(356,576,216,44)`、夜 `(580,576,228,44)`。左盤下端から12px。未選択=濃紺、選択=金、ロック=既存lockスキン | `_build_time_slot_selector` | 食事効果の有無で位置を動かさない |
| 食事効果 | `(60,532,748,36)`。時間帯の直上に1段表示し、効果なしは全体非表示 | `_build_time_slot_zone` | 次回釣行へ効く値だけ表示 |
| 右・操作盤 | `(844,120,396,512)`。共通 `harbor_command_dark_frame.svg`＋暗色スクリム | `_build_facility_menu` | 採用モック実寸 |
| 出港主導線 | `(864,176,356,64)` の共通 `harbor_command_cta.png`による金CTA 1件だけ。初期フォーカス | `_build_command_route_button` | 左CTAは置かない |
| 施設 | 2列x3行、各`174x58`。依頼/調理 y272、魚市場/釣具 y338、船着き/生簀 y404。共通 `harbor_command_dark_frame.svg` | `_build_facility_menu` | 旧6行縦リストをタイル化 |
| 記録・システム | ステータス/魚図鑑 `(864/1046,494,174,42)`。設定 `(1064,140,76,28)`、タイトル `(1148,140,72,28)`。両方とも非透明runtime子Labelを中央配置し、省略なし。共通 `harbor_command_dark_frame.svg` | `_build_facility_menu` | 設定とタイトルを右上へ分離し、既存compact描画文法を共有 |
| 推薦 | `(864,544,356,68)`。共通 `harbor_command_dark_frame.svg`。納品可能依頼→クーラー内の魚→出港の優先順。施設hover/focus時だけ説明へ切替 | `_facility_menu_hint` | 常設の初心者契約 |
| 通知・ロック | 依頼/市場は14px通知丸。生簀ロック中も押下可能で、推薦欄に解放条件を表示 | `_build_command_route_button` | 読めないdisabled導線にしない |
| 10既存導線＋設定とフォーカス | 既存route 10件は不変。追加設定は `settings` へ遷移し港戻りpayloadを渡す。右上は設定↔タイトル、両方から下の主CTAへ隣接。全route/timeはhover=明度差、pressed=暗化、focus=透明fill＋金色2px枠（CTAは3px） | `_route_buttons` / `_settings_button` / `_wire_command_focus` | ゲームパッドでも現在地を可視化 |
| 共通ラインアイコン | `assets/showcase/common/harbor_command_icon_sheet.svg`（15セル×32px） | `_command_icon_rect` | モックの線画へ統一 |
| フッター | `(40,648,1200,48)`。共通 `harbor_command_dark_frame.svg`。左にクーラー匹数、右にプレイ時間。区切り記号なし | `_build_footer` | 情報重複なし |
| 背景 | 全画面減光スクリム＋朝/夜の既存時間帯グレード | `_build_screen` / `_refresh_time_slot_grade_overlay` | 背景と情報盤の競合を抑える |

## 2. 不採用・再試行禁止リスト

| 案 | 却下理由 | 判断日 |
|---|---|---|
| 時間帯ごとの港背景PNGを先に作る | E5はグレーディング検証から | 2026-07-08 |
| 左カラム「釣り場へ向かう」大ボタン維持 | 右CTAと重複する | 2026-07-09 |
| 情報板枠へのポートレートスロット焼き込み | runtime UIとずれて二重枠になる | 2026-07-09 |
| 時間帯を大きな出港プラン紙面へ埋め込む | 主導線と情報階層が弱くなる | 2026-07-09 |
| 3魚を同じ寸法で並べる | 最優先魚が読めず、縮小時に主役不在になる | 2026-07-10 |
| 施設10件の縦1列リスト | 主CTAが弱く、施設と記録とシステムの階層が潰れる | 2026-07-10 |
| 情報板外枠＋魚カード枠の Phase B AI一点物候補 | 木目・紙粒子は増えたが、3時間帯の全画面比較で現行PIL版に明確に勝たない | 2026-07-10 |

## 3. 微調整カウンタ

| パラメータ | 回数 | 直近の変更内容 | 状態 |
|---|---|---|---|
| 装飾パス累計 | 2 | 既存時間帯グレード＋一覧画面用の全画面減光スクリム | 採用 |
| 司令盤レイアウト | 1 | 採用モックの実寸で全面再構成 | freeze |
| 最長文字フィット | 1 | 最長魚名は26px→最小12pxで自動縮小、smokeで実測 | freeze |
| 暗色フレーム共通化 | 2 | 既存footer再利用案から、端9px内に罫線を収めた `harbor_command_dark_frame.svg` へ切替 | freeze |
| 出港情報／時間帯の縦配分 | 2 | 食事効果なしの目撃談78→114px。時間帯との12px間隔は維持 | freeze |
| ヘッダー文字基準線 | 1 | 場所名−2px、Lv/EXP＋1px、装備＋2px。所持金は不変 | freeze |
| 右上compact導線文字 | 1 | 設定／タイトルを各ボタン内の12px runtime子Labelへ統一 | freeze |

## 4. 暫定判定・再検証TODO

なし。

## 5. 現在の残ギャップ

- 夜釣りの港背景は寒色グレードのみで、専用夜景ではない。
- 天気気配は固定スタブで、本物の天候先読みは未着手。

## 6. フェーズスコープ宣言（作業中のみ）

完了済みのためなし。

## 7. 判断ログ（直近パスのみ）

2026-07-12 右上の設定／タイトル導線P1修正を採用し、局所freeze。

- 再オープン: 右操作盤ヘッダーの設定 `(1064,140,76,28)` とタイトル `(1148,140,72,28)` の表示文字だけ。
- 変更: 標準Button文字を使わず、既存compactスキン上へ非透明の12px runtime子Labelを置く共通描画へ統一。タイトル表示はボタン幅に合う完全語「タイトル」とした。
- 維持: 主CTA、施設2x3、記録2件、推薦、左主情報盤、上部ステータス、フッター、既存route 10件、素材、Palette、他freezeは変更していない。
- smoke: 子Labelの存在、非透明色、完全な文言、文字実測幅、ボタン矩形内包含、設定／タイトル遷移、設定↔タイトルと主CTAへのfocus隣接を契約化した。

判断根拠:

- `docs/qa/evidence/harbor/2026-07-12_settings_title_before_after.png`（左=空設定／切れたタイトル、右=設定／タイトル完全表示。同一seed・1280x720）
- `docs/qa/evidence/harbor/2026-07-12_settings_title_after.png`（採用原寸normal）
- `docs/qa/evidence/harbor/2026-07-12_settings_title_hover.png` / `2026-07-12_settings_title_pressed.png` / `2026-07-12_settings_title_focus.png`（操作状態原寸）

採用理由:

- beforeの空ボタンと文字切れが解消し、原寸で「設定」「タイトル」を完全に読める。
- normal / hover / pressed / focusで文字が維持され、focus枠と押下状態を識別できる。
- 同一seedの全画面比較で、右上以外の港freezeに視覚差がない。

検証結果: `settings_smoke: ok` / `harbor_screen_smoke: ok` / `./tools/harbor_visual_qa.sh` green / `./tools/validate_project.sh` green / `git diff --check` green。
