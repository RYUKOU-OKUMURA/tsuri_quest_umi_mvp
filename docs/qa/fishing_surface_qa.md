# 水上キャスト画面 QA判断ログ

最終更新: 2026-07-08 / 状態: READY餌魚名固定スロット修正 採用
参照画像: `reference/01_surface_fishing_mockup.png` / `reference/13_fishing_ready_danger_mockup.png`
QA更新コマンド: `./tools/surface_weather_visual_qa.sh` / `godot --path . res://tools/fishing_surface_states_preview.tscn` / `godot --path . res://tools/catch_fanfare_preview.tscn` / `./tools/fight_visual_qa.sh`

## 1. freeze値（正本）

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 晴天の状態別プレート | 変更しない | `assets/showcase/surface/surface_scene_waiting.png` / `surface_scene_approach.png` / `surface_scene_bite.png` | 晴天は焼き込み魚影の品質が高く、今回の対象外 |
| 非晴天魚影素材 | `surface_fish_shadow_soft.png` 3フレーム横並びシート、無ければ `surface_fish_shadow.png` | `src/ui/components/surface_cast_view.gd` | 新素材未import時も `ImageTexture.create_from_image()` 経由で表示、欠落時は旧素材へフォールバック |
| 非晴天魚影ステージング | WAITING=小・薄、APPROACH=拡大+alpha上昇、BITE=縮小+低alpha | `_draw_asset_fish_shadow()` | BITEで魚影を濃くせず、スプラッシュを主役にする |
| 非晴天航跡 | 固定楕円なし、進行方向V字航跡+後方リップル | `_draw_asset_fish_wake()` | 旧楕円アウトラインの照準レティクル感を解消 |
| rain/fogオーバーレイ | rain=2枚縦スクロール、fog=横ドリフト+alpha揺らぎ | `_draw_weather_texture_overlay()` | 静止合成をやめ、天候の動きを出す |
| READY専用下段バー品質 | READY時は `fight_hud_frame.png` を背景に描かない。下段バーは `common/button_frame_primary.png`、セレクタ/通常エサカードは `common/parchment_card.png` + `common/card_frame.png`、投げるボタンは `common/action_button_frame.png`、矢印・右メニューは `common/button_frame*.png` で構成する。READYキーチップは濃色の `common/button_frame_primary.png` + 白文字で表示する。`投げる` はfont ascent/descentで中央に収め、READYで見える餌アイコンは `underwater/hud_bait_icon.png` または魚ポートレートを使う | `src/ui/components/fight_hud.gd` / `tools/audit_showcase_asset_refs.py` | docs/40準拠。FIGHT用の焼き込み区画・分割線がREADYバー背面に覗かないことをfreeze。監査allowlistはこのため `fight_hud.gd` に common を明示許可。READY実表示でコード描画の餌アイコンを出さない |
| サメ餌魚READYセレクタ | `spot_id == "danger_reef"` のREADY時だけ下段HUD左をサメ餌魚セレクタに差し替え。`餌魚なし`・所持魚・残チャージ中の魚を左右で選ぶ。表示は魚名スロット＋右固定の `xN`、チャージありはピップ＋`あとN回`、在庫0残チャージはフッターに `在庫0` を出す。長い魚名はカード幅内で縮小し、最小でも収まらない場合は魚名だけ末尾を詰め、`xN` は表示維持 | `src/ui/fishing_screen.gd` / `src/ui/components/fight_hud.gd` | docs/38・docs/40準拠。餌魚は釣り場選択では消費せず、投げる時に1匹消費してチャージを付与する。`港のぬし・大岩クロダイ` 等の長名でカード外へ文字が抜けないことをfreeze |
| サメ餌魚チャージ表示 | READYでは旧 `所持 xN` / `1匹で最大N回` 表記を廃止し、`魚名 xN` + ピップ + `あとN回` / `投げると1匹つかう` に集約。CASTING以降は下段HUDに `餌魚：<魚名>（あとN回）` を表示 | `src/ui/components/fight_hud.gd` | レア=3回、ぬし=5回の耐久をUI上で追えるようにする。READYの情報階層を参照13へ寄せたため旧freezeを上書き |
| サメ餌魚APPROACH/BITE文 | 餌魚ありの時だけ `魚影が餌の<魚名>へ近づいている` / `<魚名>に何かが食いついた`。ヒット魚名・サメ名は出さない | `src/core/fishing_simulator.gd` / `src/ui/components/fight_sidebar.gd` | 上部メッセージパネルはAPPROACH/BITEで非表示のため、実表示される右サイドカードにも反映 |
| 未確認魚影カード詳細行 | signal art比率を compact=0.36 / 通常=0.34、詳細2行を下端から逆算して配置 | `src/ui/components/fight_sidebar.gd` | 「釣り場」「タナ / エサ」2行の下端見切れP1を解消 |
| 好物発見ファンファーレ | `favorite_bait_discovery_text` を記録更新・撃破報酬の下、称号の上に表示。`megalodon` は除外 | `src/ui/fishing_screen.gd` / `src/ui/components/catch_fanfare.gd` | 好物一致サメだけポジティブな発見行を返す。不一致・非サメ・メガロドンは無言 |

## 2. 不採用・再試行禁止リスト

| 案 | 却下理由 | 判断日 |
|---|---|---|
| 旧 `surface_fish_shadow.png` の白modulate合成を継続 | 目穴・泡・ヒレが見え、霧/雨の水面上でデカール調に浮く | 2026-07-06 |
| BITE時に魚影alphaを0.82へ上げる | ヒット時に魚影が主役化し、スプラッシュに隠れるべき演出と逆 | 2026-07-06 |
| 魚影周辺の固定楕円アウトライン | レティクルに見えるため、魚の進行方向を示す航跡に置換 | 2026-07-06 |

## 3. 微調整カウンタ

| パラメータ | 回数 | 直近の変更内容 | 状態 |
|---|---|---|---|
| 装飾パス累計 | 2 | READY下段バーのゾーンセパレータのみruntime直線。枠・カード・ボタンの質感はcommon PNGへ移管 | 採用 |
| READY下段バー品質改善 | 3 | `投げる` をさらに上へ補正し、`E / Enter` を濃色PNGキーチップ＋白文字へ変更 | 採用・close。文字位置の微調整は3回到達のため、以後はP1再発以外で値いじりしない |
| READY餌魚名固定スロット | 1 | 魚名と `xN` を分離し、魚名スロットを固定幅内で縮小・最終省略する | 採用。長名がカード外へ伸びるP1再発時のみ再調整 |
| 魚影tint/alpha | 2 | rainで沈みすぎたため、環境色tintを明るめの青灰へ戻しAPPROACHのみalpha/scaleを増加 | 採用・close |
| 未確認魚影カード下部詰め | 1 | signal art比率を圧縮し、詳細2行を下端から逆算配置 | 採用・close |

## 4. 暫定判定・再検証TODO

なし。

## 5. 現在の残ギャップ

- WAITING魚影は遠景扱いでかなり控えめ。P1/P2ではなく、必要なら別フェーズで「待機時の水面反応」演出として扱う。
- 右サイドカード内の魚影図は既存UI表示で、今回の水面合成パスとは別対象。
- READYセレクタ内の長い魚名（例: `港のぬし・大岩クロダイ`）は魚名スロット内で縮小し、最小でも収まらない場合だけ魚名末尾を詰める。カード外へのはみ出しはP1として扱う。

## 6. フェーズスコープ宣言（作業中のみ）

完了済みのためなし。

## 7. 判断ログ（直近パスのみ）

2026-07-08 READY餌魚名固定スロット修正を採用。

差分Top1:
- P1-1: `港のぬし・大岩クロダイ x99` など長い餌魚名がREADYセレクタカード外へ伸び、右矢印や周辺UIに重なって画面全体が揺れて見える。

スコープ:
- 今回動かしたもの: READY餌魚カードの魚名・個数描画、`_draw_text_fit()` の最小サイズ到達後のはみ出し防止。
- 触っていないもの: READY下段バーのゾーン幅、魚ポートレートサイズ、投げるボタン、右メニュー、抽選/消費ロジック、CASTING以降のHUDレイアウト。

変更したもの:
- 魚名と `xN` を1文字列ではなく、魚名スロットと右固定の個数スロットに分離した。
- `_draw_text_fit()` を、最小フォントでも収まらない場合にカード外へ描かず、固定幅内で末尾を詰める描画へ変更した。

検証:
- `tools/fishing_surface_states_preview.tscn`: 危険海域READY（`boss_kurodai`）を取得し、長い魚名がカード外へ出ないことを目視確認。
- `./tools/validate_project.sh`: showcase素材参照監査、魚シート監査、Godotロード確認すべて通過。
- `fishing_harbor_return_smoke.tscn`: green。
- `fishing_spot_select_smoke.tscn`: green。
- `harbor_screen_smoke.tscn`: green。
- `fishing_reveal_smoke.tscn`: green。

判断根拠:
- 長名READY証拠: `docs/qa/evidence/fishing_surface/2026-07-08_ready_lure_long_name_fixed.png`

採用理由:
- `港のぬし・大岩クロダイ` 選択時でも魚名描画がカード内に収まり、右矢印・投げるボタン・右メニューに重ならない。
- 個数 `xN` は右固定で表示されるため、在庫桁数や魚名長による見た目の揺れが起きにくい。

2026-07-07 READY投げる/Enter視認性修正を採用。

差分Top2:
- P1-1: `投げる` がまだわずかに下へ寄って見え、主操作ボタンの中央感が弱かった。
- P1-2: `E / Enter` が紙色キーチップ上の小さい暗色文字になり、縮小表示で読みにくかった。

スコープ:
- 今回動かしたもの: READY中央ボタン内の `E / Enter` キーチップサイズ・素材・文字色・文字サイズ、`投げる` ラベル領域の縦位置。
- 触っていないもの: READY下段バーの3ゾーン幅、餌魚カード、右メニュー、抽選/消費ロジック、CASTING以降のHUD情報設計。

変更したもの:
- `E / Enter` を 124x34px の濃色PNGキーチップに変更し、白文字+outlineで視認性を上げた。
- `投げる` のラベル領域を上へ補正し、ボタン下端へ落ちて見える状態を解消した。

検証:
- `tools/fishing_surface_states_preview.tscn`: 非headless通常起動で危険海域READY（マハゼ）・通常釣り場READY・CASTINGを取得し目視確認。
- `./tools/validate_project.sh`: showcase素材参照監査、魚シート監査、Godotロード確認すべて通過。
- `fishing_harbor_return_smoke.tscn`: green。
- `fishing_spot_select_smoke.tscn`: green。
- `harbor_screen_smoke.tscn`: green。
- `catch_fanfare_smoke.tscn`: green。
- `./tools/fight_visual_qa.sh`: FIGHT runtime captureと比較画像生成まで通過。

判断根拠:
- before/after比較: `docs/qa/evidence/fishing_surface/2026-07-07_ready_button_label_key_final_before_after.png`
- 中央ボタン焦点比較: `docs/qa/evidence/fishing_surface/2026-07-07_ready_button_label_key_final_focus.png`
- 個別READY証拠: `docs/qa/evidence/fishing_surface/2026-07-07_ready_button_label_key_final_danger_ready.png` / `2026-07-07_ready_button_label_key_final_common_ready.png`
- CASTING回帰証拠: `docs/qa/evidence/fishing_surface/2026-07-07_ready_button_label_key_final_casting_regression.png`

採用理由:
- focus比較で `E / Enter` が縮小状態でも読める。
- `投げる` の下寄り感が減り、中央主操作としての収まりが改善した。
- 既存PNGキット内の使い方変更のみで、新規素材・新規コード描画は増やしていない。

2026-07-07 READY下段バー見落とし修正を採用。

差分Top3:
- P1-1: 中央の `投げる` がボタン枠の下へ落ち、主操作として読めない状態だった。
- P1-2: `餌魚なし` と魚ポートレート欠落時に、既存PNGではなく `_draw_bait_icon()` のコード描画が実表示されていた。
- P2-1: READY中央の `E / Enter` チップもStyleBoxFlatのままで、今回の「共通PNGキットへ寄せる」方針から漏れていた。

スコープ:
- 今回動かしたもの: READY下段バー内の餌アイコンfallback、通常エサカードの餌アイコン経路、中央投げるボタンの文字中央揃え、READYキーチップのPNG枠化。
- 触っていないもの: 抽選/消費ロジック、CASTING以降の状態遷移、水面ビュー素材、右サイドカードの情報設計。

同種点検:
- READYで見える枠・カード・ボタン・キーチップ・餌アイコンはPNG素材経路に統一した。
- `_draw_bait_icon()` は旧FIGHT HUD fallback側にだけ残す。READY実表示からは外した。
- READY下段に残るruntime描画はゾーン区切り線とチャージピップのみ。小型の状態・境界表示で、質感部品ではないため採用。

検証:
- `./tools/validate_project.sh`: showcase素材参照監査、魚シート監査、Godotロード確認すべて通過。
- `fishing_harbor_return_smoke.tscn`: green。
- `fishing_spot_select_smoke.tscn`: green。
- `harbor_screen_smoke.tscn`: green。
- `catch_fanfare_smoke.tscn`: green。
- `tools/fishing_surface_states_preview.tscn`: 非headless通常起動で危険海域READY（餌魚なし/キハダ）・通常釣り場READY・CASTINGを取得し目視確認。
- `./tools/fight_visual_qa.sh`: FIGHT runtime captureと比較画像生成まで通過。

判断根拠:
- before/after比較: `docs/qa/evidence/fishing_surface/2026-07-07_ready_bottom_bar_quality_correction_before_after.png`
- READY状態別比較: `docs/qa/evidence/fishing_surface/2026-07-07_ready_bottom_bar_quality_correction_states.png`
- 個別READY証拠: `docs/qa/evidence/fishing_surface/2026-07-07_ready_bottom_bar_quality_correction_ready_empty.png` / `2026-07-07_ready_bottom_bar_quality_correction_ready_kihada.png` / `2026-07-07_ready_bottom_bar_quality_correction_ready_common.png`
- CASTING回帰証拠: `docs/qa/evidence/fishing_surface/2026-07-07_ready_bottom_bar_quality_correction_casting_regression.png`

採用理由:
- afterでは `投げる` が中央ボタン枠内に収まり、ボタン下端へ垂れていない。
- `餌魚なし` は `hud_bait_icon.png` の画像表示に変わり、コード描画の抽象アイコンが消えた。
- 通常釣り場READY・餌魚ありREADY・CASTINGの見た目と状態遷移に回帰なし。

2026-07-07 READY専用下段バー品質改善を採用。

差分Top3:
- P2-1: READY背面にFIGHT用 `fight_hud_frame.png` の区画・分割線が覗き、READYバーが「貼り付け」に見えていた。
- P2-2: セレクタ・投げるボタン・矢印・右メニューがStyleBoxFlat主体で、共通キットPNGの金縁・紙質感が未配線だった。
- P2-3: `仕掛け投入` 見出しと小さめCTA、`所持 xN` / `1匹で最大N回` 行により、参照13の主操作主役感・カード階層から離れていた。

スコープ:
- 今回動かしたもの: READY状態の下段バー背景、3ゾーン内の素材配線、投げるボタンのサイズとキーチップ位置、餌魚カードの表示形式、素材参照監査のcommon許可。
- 触っていないもの: 抽選遅延・チャージ消費ロジック、CASTING以降のFIGHT HUD描画経路、水面ビュー素材、右サイドカードの既存情報設計。

変更したもの:
- READY時の `_draw()` を先頭分岐にし、`fight_hud_frame.png` を描く経路から切り離した。
- 下段バー外周・カード・矢印・投げるボタン・右メニューを `assets/showcase/common/` のPNGキットへ配線した。
- 中央の `投げる` を大型化し、`仕掛け投入` 見出しを撤去。`E / Enter` キーチップをボタン上部中央へ移した。
- 餌魚カードを `魚名 xN` 1行 + ピップ + `あとN回` / `投げると1匹つかう` に整理し、旧 `所持 xN` / `1匹で最大N回` freezeを上書きした。
- `tools/audit_showcase_asset_refs.py` で、docs/40のREADYバー共通キット化を理由に `fight_hud.gd` からの `common` 参照を明示許可した。

共通キット未配線リスト:
- セレクタカード: 解消（`common/parchment_card.png` + `common/card_frame.png`）。
- 投げるボタン: 解消（`common/action_button_frame.png`）。
- ◀▶矢印: 解消（`common/button_frame.png`）。
- 右メニュー: 解消（`common/button_frame_primary.png`）。
- READYバー背面: 解消（`common/button_frame_primary.png`。専用PNG待ちP2なし）。

検証:
- `./tools/validate_project.sh`: showcase素材参照監査、魚シート監査、Godotロード確認すべて通過。
- `fishing_harbor_return_smoke.tscn`: green。
- `fishing_spot_select_smoke.tscn`: green。
- `harbor_screen_smoke.tscn`: green。
- `catch_fanfare_smoke.tscn`: green。
- `tools/fishing_surface_states_preview.tscn`: 非headless通常起動で危険海域READY、CASTING/WAITING/APPROACH/BITEを取得。
- `tools/catch_fanfare_preview.tscn`: 非headless通常起動で釣果ファンファーレを取得。
- 一時QAシーンで docs/38 §4-2 の4状態（チャージあり / チャージなし所持あり / 餌魚なし / 所持0残チャージあり）＋通常釣り場READYを取得。一時シーンは削除済み。
- `./tools/fight_visual_qa.sh`: FIGHT runtime captureと比較画像生成まで通過。

判断根拠:
- 参照/Before/After比較: `docs/qa/evidence/fishing_surface/2026-07-07_ready_bottom_bar_quality_reference_compare.png`
- READY状態別比較: `docs/qa/evidence/fishing_surface/2026-07-07_ready_bottom_bar_quality_states.png`
- CASTING〜BITE・釣果回帰比較: `docs/qa/evidence/fishing_surface/2026-07-07_ready_bottom_bar_quality_casting_regression.png`
- FIGHT回帰比較: `docs/qa/evidence/fishing_surface/2026-07-07_ready_bottom_bar_quality_fight_regression.png`
- 釣果個別証拠: `docs/qa/evidence/fishing_surface/2026-07-07_ready_bottom_bar_quality_catch_fanfare.png`
- 個別READY証拠: `docs/qa/evidence/fishing_surface/2026-07-07_ready_bottom_bar_quality_ready_common.png` / `2026-07-07_ready_bottom_bar_quality_ready_empty.png` / `2026-07-07_ready_bottom_bar_quality_ready_charged.png` / `2026-07-07_ready_bottom_bar_quality_ready_zero_stock_charge.png`

採用理由:
- afterはREADY下段にFIGHT用HUDの焼き込み区画・分割線が覗かず、1本のREADY専用バーとして見える。
- 参照13との縮小比較で、バーの一体感・金縁質感・主操作の主役感・カード階層がbeforeより明確に近づいた。
- 機能・状態遷移・CASTING以降のHUD経路はsmokeとFIGHT visual QAで回帰なし。

2026-07-07 サメ餌魚READYセレクタ＋チャージ表示を採用。

変更したもの:
- 危険海域READYの下段HUDを、左=サメ餌魚セレクタ / 中央=投げる / 右=釣り場変更・港へ戻る の専用レイアウトに差し替え。
- 左右クリックと `←` / `→` で、`餌魚なし`・所持魚・残チャージ中の魚を切替可能にした。
- READYで所持数とチャージ（`あとN回` / `1匹で最大N回`）を表示し、CASTING以降は `餌魚：<魚名>（あとN回）` を下段HUDへ引き継ぐ。
- 危険海域READYの未抽選状態では右サイドのタナ表示を `--` にし、投げる前に魚の深度が出ないようにした。
- `tools/fishing_surface_states_preview.gd` を実際のREADY投入ボタン経由に変更し、QA用の餌魚選択プレビューでもキャスト時消費モデルを通すようにした。

変えていないもの:
- 水上背景・天候・魚影合成のfreeze値。
- FIGHT中のテンション/スタミナ/深度/操作ヒントの既存HUDレイアウト。
- 右サイドカードの未確認魚影レイアウト（未抽選時の深度だけ非表示）。

検証:
- `./tools/validate_project.sh`: showcase素材監査、魚シート監査、Godotロード確認すべて通過。
- `fishing_harbor_return_smoke.tscn`: キャスト時消費、レア3回、ぬし5回、餌魚なし再投入回帰を確認。
- `fishing_spot_select_smoke.tscn`: 釣り場選択時に餌魚を消費しないことを確認。
- `harbor_screen_smoke.tscn` / `fishing_reveal_smoke.tscn` / `catch_fanfare_smoke.tscn`: 周辺画面と未公開魚影・ファンファーレ回帰を確認。
- `fishing_surface_states_preview.tscn`: 非headless通常起動で危険海域READY、レアチャージREADY、投入後残回数、通常READYのスクショを取得して目視確認。

判断根拠:
- 参照比較: `docs/qa/evidence/fishing_surface/2026-07-07_shark_lure_ready_selector_reference_compare.png`
- 通常餌魚READY: `docs/qa/evidence/fishing_surface/2026-07-07_shark_lure_ready_selector_common.png`
- レア餌魚チャージREADY: `docs/qa/evidence/fishing_surface/2026-07-07_shark_lure_ready_selector_rare_charges.png`
- 投入後残チャージHUD: `docs/qa/evidence/fishing_surface/2026-07-07_shark_lure_cast_remaining_charges.png`

2026-07-07 サメ餌魚の釣行中UX表示を採用。

変更したもの:
- 危険海域かつ餌魚ありの時だけ、下部HUD「使用中のエサ」下段を `餌魚：<魚名>` に差し替え。
- APPROACH/BITE の simulator文言と、実際に見える右サイドカード「今の状況」を餌魚主語に変更。
- 未確認魚影カードの signal art 高さと詳細2行の配置を調整し、下端見切れを解消。
- 好物一致サメ釣果のみ、ファンファーレに `ホシザメはアジが大好物みたいだ！` 形式の発見行を追加。メガロドンは除外。
- `tools/fishing_surface_states_preview.gd` に釣り場・餌魚・出力prefixのQA用環境変数を追加し、`tools/catch_fanfare_preview.gd` に `favorite_bait` シナリオを追加。

変えていないもの:
- E10-4の餌魚消費、抽選重み、メガロドン条件。
- 晴天状態別プレート、非晴天魚影素材、天候オーバーレイのfreeze値。
- 港画面の餌魚セットUI、図鑑の好物永続表示。

検証:
- `fishing_reveal_smoke.tscn`: 餌魚名がAPPROACH/BITE文言に出ても、アワセ前の魚種公開は発生しない。
- `catch_fanfare_smoke.tscn`: 好物一致サメで発見行あり、不一致サメ・メガロドンで発見行なし。
- `shark_lure_audit.tscn`: 餌魚重み・大型サメ解禁・メガロドン条件の監査が従来どおりgreen。

判断根拠:
- 危険海域APPROACH: `docs/qa/evidence/fishing_surface/2026-07-07_shark_bait_approach.png`
- 危険海域BITE: `docs/qa/evidence/fishing_surface/2026-07-07_shark_bait_bite.png`
- 通常釣り場BITE回帰: `docs/qa/evidence/fishing_surface/2026-07-07_shark_bait_normal_bite_regression.png`
- 好物発見ファンファーレ: `docs/qa/evidence/fishing_surface/2026-07-07_shark_bait_favorite_fanfare.png`

2026-07-06 右上「釣り場」情報パネル（READY時のみ表示）のバグ修正。

不具合: `make_label()` の既定値（autowrap_mode=WORD_SMART + text_overrun_behavior=OVERRUN_TRIM_ELLIPSIS）の組み合わせにより、VBoxContainer内でラベル最小サイズが (1,1) に潰れ、タイトル・釣り場概要・詳細の3ラベルが1行も描画されず空の枠だけが見えていた（水上メッセージ帯で既知だった同じ崩れがここでも再発）。加えて `_info_title_label`（「釣り場」）の文字色 `FISHING_SPOT_TITLE_TEXT`（`#22354a`）が背景グラデーション（`#0c243a`）とほぼ同色で、たとえ描画されても視認不可能だった。

変更したもの（`src/ui/fishing_screen.gd`）:
- `_info_title_label` / `_spot_summary_label` / `_spot_detail_label` に `autowrap_mode = AUTOWRAP_OFF` + `text_overrun_behavior = OVERRUN_NO_TRIMMING` + 固定 `custom_minimum_size` を設定し、崩れを解消。
- `_info_title_label` の色を `Palette.TEXT_BONE` + アウトラインへ変更（ダーク背景に直接乗る見出しは他画面同様このパターンを使用）。
- 未使用になった `Palette.FISHING_SPOT_TITLE_TEXT` を削除。

変えていないもの:
- パネルのレイアウト位置・サイズ、READY時のみ表示するロジック。
- 非晴天魚影・天候オーバーレイなど本ドキュメントの既存freeze値。

検証: `./tools/validate_project.sh`、`fishing_harbor_return_smoke.tscn`、`fishing_reveal_smoke.tscn` すべて通過。`fishing_surface_states_preview.tscn` で全天候READY状態のスクショを再取得し目視確認（`docs/qa/evidence/fishing_surface/2026-07-06_spot_info_panel_fix_ready.png`）。

2026-07-06 非晴天魚影・ヒット演出 uplift を採用。

変更したもの:
- `surface_fish_shadow_soft.png` を追加し、非晴天の WAITING / APPROACH / BITE 合成で優先使用。
- 魚影を天気別tint/alphaに変更し、同フレームを拡大低alpha + 等倍本alphaの2パスで描画。
- BITE時の `alpha=0.82` 固定を廃止し、縮小+フェードでスプラッシュに主役を渡す。
- 旧固定楕円アウトラインをV字航跡と後方リップルに置換。
- rain/fog overlay を `_time` でアニメーション化。

変えていないもの:
- 晴天の状態別プレートと晴天時の描画パス。
- 既存の晴天用PNG、他画面素材、魚ドメイン素材。

判断根拠:
- 5天気READY比較: `docs/qa/evidence/fishing_surface/2026-07-06_before_weather_ready_compare.png` / `docs/qa/evidence/fishing_surface/2026-07-06_final_after_weather_ready_compare.png`
- fog状態比較: `docs/qa/evidence/fishing_surface/2026-07-06_final_compare_fog_states.png`
- rain状態比較: `docs/qa/evidence/fishing_surface/2026-07-06_final_compare_rain_states.png`

採用理由:
- beforeの硬い魚アイコン感、白い浮き、BITE時の濃化、レティクル状楕円が解消された。
- afterは天気ごとの明度に馴染み、APPROACHでは魚影が読み取れ、BITEではスプラッシュが主役になっている。
- 比較シート上で晴天プレートの挙動に変更がない。
