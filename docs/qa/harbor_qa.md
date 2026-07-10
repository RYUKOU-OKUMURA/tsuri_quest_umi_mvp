# 港画面 QA判断ログ

最終更新: 2026-07-10 / 状態: 「港の司令盤」採用・freeze
参照画像: `docs/qa/evidence/harbor/2026-07-10_harbor_command_board_mockup_v1.png`
実装仕様: `docs/44_harbor_command_board_spec.md`
QA更新コマンド: `./tools/harbor_visual_qa.sh`（固定previewデータで3時間帯、モック横並び、grayscale、thumbnailを一括生成）

## 1. freeze値（正本）

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 上部ステータス | `(32,24,1216,80)`。港専用 `harbor_top_frame.png`。左に「南の島・港」＋`HARBOR COMMAND`、右は共通 `PlayerStatusBar` の港司令盤モードで Lv/EXP → 装備竿 → 所持金 | `src/ui/harbor_screen.gd` / `components/player_status_bar.gd` | 時間帯は重複表示しない |
| 左・主情報盤 | `(40,120,788,512)`。共通 `harbor_command_dark_frame.svg`＋暗色スクリム | `src/ui/harbor_screen.gd` | 採用モック実寸 |
| 狙い魚 | 最優先 `(60,172,364,154)`、副候補 `(436,172,180,154)` / `(628,172,180,154)`。魚素材は `FightFishAssets` 経由 | `_build_info_board` | 3件同格を廃止し1＋2の階層にする |
| 狙い目候補 | `_harbor_highlight_candidates(max_count)`。依頼（納品可能を含む）→時間帯ブースト→未捕獲、重複排除・乱数なし | 候補収集関数群 | 情報盤と出港情報で共有 |
| 出港情報 | 3カード `(60,364,270,64)` / `(338,364,270,64)` / `(616,364,192,64)`＋目撃談 `(60,436,748,58)` | `_build_departure_plan_card` | 旧大紙面4行を短い情報単位へ分解 |
| 初心者ガイド | `level <= GROWTH_SOFT_CAP(10)` のみ。調理未経験→依頼未達成→狙い魚要約 | `_departure_guide_summary` | 子供向けの短文を維持 |
| 天気気配 | 「雨・潮目が立ちやすい」の固定スタブ | `_refresh_preparation_card` | 本物の先読み抽選は別設計 |
| 時間帯 | 朝 `(132,504,216,44)`、日中 `(356,504,216,44)`、夜 `(580,504,228,44)`。未選択=濃紺、選択=金、ロック=既存lockスキン | `_build_time_slot_selector` | 時間帯表示の正本はここだけ |
| 食事効果 | `(60,560,748,52)`。効果なしは全体非表示 | `_build_time_slot_zone` | 次回釣行へ効く値だけ表示 |
| 右・操作盤 | `(844,120,396,512)`。共通 `harbor_command_dark_frame.svg`＋暗色スクリム | `_build_facility_menu` | 採用モック実寸 |
| 出港主導線 | `(864,176,356,64)` の共通 `harbor_command_cta.png`による金CTA 1件だけ。初期フォーカス | `_build_command_route_button` | 左CTAは置かない |
| 施設 | 2列x3行、各`174x58`。依頼/調理 y272、魚市場/釣具 y338、船着き/生簀 y404。共通 `harbor_command_dark_frame.svg` | `_build_facility_menu` | 旧6行縦リストをタイル化 |
| 記録・システム | ステータス/魚図鑑 `(864/1046,494,174,42)`。タイトル戻り `(1064,140,156,28)`。共通 `harbor_command_dark_frame.svg` | `_build_facility_menu` | タイトル戻りはヘッダーへ分離 |
| 推薦 | `(864,544,356,68)`。共通 `harbor_command_dark_frame.svg`。納品可能依頼→クーラー内の魚→出港の優先順。施設hover/focus時だけ説明へ切替 | `_facility_menu_hint` | 常設の初心者契約 |
| 通知・ロック | 依頼/市場は14px通知丸。生簀ロック中も押下可能で、推薦欄に解放条件を表示 | `_build_command_route_button` | 読めないdisabled導線にしない |
| 10導線とフォーカス | `fishing_spots / quest_board / cooking / market / shop / shipyard / shark_pen / status / fish_book / title`。上下左右の隣接を明示。全route/timeはhover=明度差、pressed=暗化、focus=透明fill＋金色2px枠（CTAは3px） | `_route_buttons` / `_wire_command_focus` | ゲームパッドでも現在地を可視化 |
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

## 4. 暫定判定・再検証TODO

なし。

## 5. 現在の残ギャップ

- 夜釣りの港背景は寒色グレードのみで、専用夜景ではない。
- 天気気配は固定スタブで、本物の天候先読みは未着手。

## 6. フェーズスコープ宣言（作業中のみ）

完了済みのためなし。

## 7. 判断ログ（直近パスのみ）

2026-07-10 「港の司令盤」採用モックをGodotへ実装し、freeze。

- 変更: ヘッダー、左主情報盤、右操作盤、フッターを `docs/44` の実寸構成へ置換。最優先魚1＋副候補2、大型金CTA、施設2x3、記録2件、常設推薦を実装した。
- 維持: 狙い魚の優先順、初心者ガイド、時間帯解放と背景グレード、食事効果、ヌシ/メガロドン、通知、サメロック、10 route/callback、魚素材の `FightFishAssets` 経由。
- 素材: 共通 `harbor_command_dark_frame.svg`、既存選択時間帯素材をcommon昇格した `harbor_command_cta.png`、モックから分解した文字なしの共通ラインアイコンSVGを採用した。日本語と動的値はすべてruntime。
- UX: 納品可能な依頼も最優先候補へ含め、主CTAを初期フォーカスに設定。全routeと時間帯ボタンの隣接を明示し、hover/pressed/focusの可視状態（金2px、CTAは3px）を追加した。
- smoke: 新構成の実寸、旧構成の不在、10導線、1＋2候補、通知/推薦/ロック、3時間帯、食事/前兆、最長文字、全テクスチャ読込、可視focusを検証する契約へ更新。
- 比較条件: previewデータを固定し、before/afterは `legacy_compare` の同一状態で3時間帯を比較。`./tools/harbor_visual_qa.sh` がモック横並び、grayscale、thumbnailまで生成する。

判断根拠:

- `docs/qa/evidence/harbor/2026-07-10_command_board_all_slots_before_after.png`（左=刷新前、右=刷新後。同一の固定 `legacy_compare` データ、朝/日中/夜）
- `docs/qa/evidence/harbor/2026-07-10_command_board_daytime_after_mock.png`（左=実装、右=採用モック）
- `docs/qa/evidence/harbor/2026-07-10_command_board_daytime_after_mock_grayscale.png` / `2026-07-10_command_board_daytime_after_mock_thumbnail.png`（明度階層・縮小1枚絵）
- `docs/qa/evidence/harbor/2026-07-10_command_board_after_all_slots.png`（固定standard previewデータの3時間帯）

採用理由:

- 同一固定データの3時間帯すべてで、旧画面より大型CTA・最優先魚・施設グループが先に読める。
- 旧大紙面と10行縦リストの過密感が消え、縮小比較でも主操作と主役魚を判別できる。
- 1280x720原寸で文字切れ・省略・重なりがなく、動的データと全導線を失っていない。

検証結果: `harbor_screen_smoke: ok` / `./tools/validate_project.sh` green。
