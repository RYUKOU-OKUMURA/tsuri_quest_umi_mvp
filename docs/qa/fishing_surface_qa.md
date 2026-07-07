# 水上キャスト画面 QA判断ログ

最終更新: 2026-07-07 / 状態: サメ餌魚READYセレクタ 採用
参照画像: `reference/01_surface_fishing_mockup.png` / `reference/13_fishing_ready_danger_mockup.png`
QA更新コマンド: `./tools/surface_weather_visual_qa.sh` / `tools/fishing_surface_states_preview.gd`

## 1. freeze値（正本）

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 晴天の状態別プレート | 変更しない | `assets/showcase/surface/surface_scene_waiting.png` / `surface_scene_approach.png` / `surface_scene_bite.png` | 晴天は焼き込み魚影の品質が高く、今回の対象外 |
| 非晴天魚影素材 | `surface_fish_shadow_soft.png` 3フレーム横並びシート、無ければ `surface_fish_shadow.png` | `src/ui/components/surface_cast_view.gd` | 新素材未import時も `ImageTexture.create_from_image()` 経由で表示、欠落時は旧素材へフォールバック |
| 非晴天魚影ステージング | WAITING=小・薄、APPROACH=拡大+alpha上昇、BITE=縮小+低alpha | `_draw_asset_fish_shadow()` | BITEで魚影を濃くせず、スプラッシュを主役にする |
| 非晴天航跡 | 固定楕円なし、進行方向V字航跡+後方リップル | `_draw_asset_fish_wake()` | 旧楕円アウトラインの照準レティクル感を解消 |
| rain/fogオーバーレイ | rain=2枚縦スクロール、fog=横ドリフト+alpha揺らぎ | `_draw_weather_texture_overlay()` | 静止合成をやめ、天候の動きを出す |
| サメ餌魚READYセレクタ | `spot_id == "danger_reef"` のREADY時だけ下段HUD左をサメ餌魚セレクタに差し替え。`餌魚なし`・所持魚・残チャージ中の魚を左右で選ぶ | `src/ui/fishing_screen.gd` / `src/ui/components/fight_hud.gd` | docs/38準拠。餌魚は釣り場選択では消費せず、投げる時に1匹消費してチャージを付与する |
| サメ餌魚チャージ表示 | READYでは `所持 xN` と `あとN回` / `1匹で最大N回` を表示。CASTING以降は下段HUDに `餌魚：<魚名>（あとN回）` を表示 | `src/ui/components/fight_hud.gd` | レア=3回、ぬし=5回の耐久をUI上で追えるようにする。通常魚は1投ごとに1匹消費 |
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
| 装飾パス累計 | 1 | 非晴天魚影の2パス描画、V字航跡、rain/fogオーバーレイアニメ化 | 採用 |
| 魚影tint/alpha | 2 | rainで沈みすぎたため、環境色tintを明るめの青灰へ戻しAPPROACHのみalpha/scaleを増加 | 採用・close |
| 未確認魚影カード下部詰め | 1 | signal art比率を圧縮し、詳細2行を下端から逆算配置 | 採用・close |

## 4. 暫定判定・再検証TODO

なし。

## 5. 現在の残ギャップ

- WAITING魚影は遠景扱いでかなり控えめ。P1/P2ではなく、必要なら別フェーズで「待機時の水面反応」演出として扱う。
- 右サイドカード内の魚影図は既存UI表示で、今回の水面合成パスとは別対象。

## 6. フェーズスコープ宣言（作業中のみ）

完了済みのためなし。

## 7. 判断ログ（直近パスのみ）

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
