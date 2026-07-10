# 44. 港画面「港の司令盤」採用モック実装仕様

作成日: 2026-07-10
状態: 採用モック v1 の Godot 実装・freeze 完了
採用参照: `docs/qa/evidence/harbor/2026-07-10_harbor_command_board_mockup_v1.png`
関連: `docs/19_ui_production_playbook.md` / `docs/43_harbor_info_board_plan.md` / `docs/qa/harbor_qa.md`

## 1. 参照の分解

採用モックは単一状態の港メニューである。朝まずめ・日中・夜釣りは同じ構成のまま、時間帯ボタンの選択状態と背景グレードだけが変化する。

### 存在する領域

| 領域 | 1280x720上の矩形 | 責務 |
|---|---:|---|
| 上部ステータス | `(32, 24, 1216, 80)` | 場所名、Lv/EXP、装備竿、所持金 |
| 左・主情報盤 | `(40, 120, 788, 512)` | 狙い魚1＋2、出港情報、時間帯、食事効果 |
| 右・操作盤 | `(844, 120, 396, 512)` | タイトル戻り、主CTA、施設2x3、記録2件、推薦 |
| フッター | `(40, 648, 1200, 48)` | クーラーボックス匹数、プレイ時間 |

左盤の主要スロットは、最優先魚 `(60,172,364,154)`、副候補 `(436,172,180,154)` / `(628,172,180,154)`、出港情報3枚 `(60,364,270,64)` / `(338,364,270,64)` / `(616,364,192,64)`、目撃談 `(60,436,748,58)`、時間帯3ボタン `(132,504,216,44)` / `(356,504,216,44)` / `(580,504,228,44)`、食事効果 `(60,560,748,52)` とする。

右盤の主要スロットは、主CTA `(864,176,356,64)`、施設2x3（x=`864/1046`、y=`272/338/404`、各`174x58`）、記録2件（x=`864/1046`、y=`494`、各`174x42`）、推薦 `(864,544,356,68)` とする。

### 存在しない領域

- 旧「出港プラン」大紙面と4行縦リスト。
- 旧右メニューの10行縦リストと、独立した詳細パネル。
- 左側の重複した出港CTA。
- ヘッダー内の時間帯表示。時間帯は選択UIだけを正本にする。
- フッター中央の区切り記号。左右の情報を空間で分離する。

### 参照に在るが固定値として採用しない要素

- 魚名・魚画像・理由・候補数は `_harbor_highlight_candidates()` の結果で更新する。
- Lv/EXP/装備竿/所持金/クーラー匹数/プレイ時間/食事効果は `PlayerProgress` から更新する。
- 出港情報、目撃談、推薦文は既存の初心者ガイド・天候スタブ・狙いポイント・ヌシ/メガロドン・通知優先度を維持する。
- モック内の魚構成や数値は密度見本であり、ゲーム状態を上書きしない。

## 2. 操作契約

主操作は右上の大型「釣り場へ向かう」1つ。補助操作は依頼ボード、調理場、魚市場、釣具店、船着き場、サメの生簀、ステータス、魚図鑑、タイトルへ戻る、時間帯3種。

- 既存10 route/callbackを変更しない。
- サメの生簀はロック中も押下可能にし、推薦欄へ解放条件を表示する。
- 依頼ボード・魚市場の通知バッジ条件を維持する。
- 主CTAを初期フォーカスとし、CTA・2x3施設・記録・タイトル・時間帯の隣接フォーカスを明示する。
- hover/focus時は下端の推薦欄に各施設の説明を表示し、フォーカスが外れた場合は `_facility_menu_hint()` の推薦へ戻せる構造にする。

## 3. 素材とruntimeの分担

| 部位 | 素材 | runtime |
|---|---|---|
| 背景 | `harbor_hub_bg.png`＋既存時間帯グレード | — |
| 上部 | `harbor/harbor_top_frame.png` | 共通 `PlayerStatusBar` 港司令盤モード、場所名・動的値 |
| 左右盤/最優先カード/フッター | `common/harbor_command_dark_frame.svg`を9-slice利用 | 見出し・区切り・動的内容 |
| 副魚カード | `harbor_info_fish_card.png` | `FightFishAssets`ポートレート、魚名、理由チップ |
| 出港情報 | `common/parchment_card.png`＋`harbor_command_icon_sheet.svg` | ガイド・天候・ポイント・目撃談 |
| 時間帯 | 未選択=`common/harbor_command_dark_frame.svg`、選択=`common/harbor_command_cta.png`、ロック=既存lockスキン＋時間帯アイコン | 選択/ロック/文言、hover/pressed/focus |
| 主CTA | `common/harbor_command_cta.png`を9-slice利用 | アイコン・2段ラベル、hover/pressed/focus |
| 施設/記録 | `common/harbor_command_dark_frame.svg`＋`harbor_command_icon_sheet.svg` | ラベル、通知、ロック、hover/pressed/focus |
| 食事効果/推薦 | `common/harbor_command_dark_frame.svg` | 動的本文と小さな状態アクセント |

`harbor_command_dark_frame.svg` は端9px内に罫線を収め、小型タイルでも内側の横罫線が文字を横断しない共通フレームとする。`harbor_command_cta.png` は既存 `harbor_time_slot_btn_selected.png` のcommon昇格コピーで、司令盤の主CTAと選択時間帯へ配線する。モックから分解した白1色の共通SVGアイコンシートを含め、いずれも文字を焼き込まない。

金縁・紙面・主CTAの質感を `StyleBoxFlat` で代替しない。通常時の面は上記素材を使い、`StyleBoxFlat` は通知丸、理由チップ、細いアクセント、および操作状態を示すoverlayに限定する。全route/timeボタンは hoverで明度差、pressedで暗化し、focusは透明fill＋金色2px枠（主CTAのみ3px枠）を重ねる。キーボード/ゲームパッドでも現在フォーカスが常時判別できることを操作契約とする。

## 4. 新UX smoke契約

- `HarborTopBar`、`HarborCommandBoard`、`HarborOperationBoard`、`HarborFooter` が存在する。
- `HarborHeroTarget`が1件、`HarborSecondaryTarget`が2件予約され、候補は最大3件・重複なし。
- 旧`DeparturePlanCard`および縦10行メニューが存在しない。
- route ID 10件が重複なく存在する。
- 主CTAは1件だけで、左盤に出港CTAがない。
- 施設は2列x3行、記録は2列x1行。
- 時間帯3ボタンと解放Lv、背景グレード更新を維持する。
- 通知バッジ、サメロック説明、推薦優先度、メガロドン前兆、食事効果の表示条件を維持する。
- 全route/timeボタンに可視hover/pressed/focus状態があり、初期focusの主CTAには3px金枠が表示される。

## 4.1 Visual QA契約

`./tools/harbor_visual_qa.sh` は固定previewデータ（乱数なし）で朝まずめ・日中・夜釣りを撮影し、3時間帯一覧に加えて、採用モックとの日中横並び、グレースケール、各画面320x180（全体640x180）の縮小比較を生成する。before/after比較は同一の `legacy_compare` データ条件で作り、魚・依頼・所持金・食事効果などの状態差を画面品質の差として扱わない。証拠の保存先と採否判断は `docs/qa/harbor_qa.md` を正とする。

## 5. 参照との差分Top3と採用条件

1. 右メニューの過密な縦リストと弱い主CTA → 大型CTA＋2x3タイルへ変更。
2. 3魚が同格で主役不在 → 最優先1件を大型・濃紺カードへ昇格。
3. 大紙面の文章密度と枠の入れ子 → 出港情報を3短冊＋目撃談へ分離。

採用条件は、3時間帯すべての1280x720実スクショでP1がゼロ、現行beforeに全画面で明確に勝ち、縮小比較でも主CTAと最優先魚が先に読めること。採用後は `docs/qa/harbor_qa.md` のfreeze表を本仕様へ上書きする。
