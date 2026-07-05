# リファクタ作戦台帳

最終更新: 2026-07-05 / 状態: R0/R2/R3/R4/R6/R7/R8 完了。R9（cooking_reward_panel 分割）は第1〜3段完了。R5/R1 は釣り場マップ完了、魚図鑑 Palette 移行 + P2素材評価完了、調理場 `text_overrun_behavior` 既知ギャップ解消済み、調理場COOK_SELECTの `PlayerStatusBar` 展開 + 情報重複解消済み、調理場 layout監査失敗は実P1修正として解消済み、COOK_SELECT 4スライス（料理カード/下部バー/右詳細パネル/背景）reference-uplift完了、COOK_SELECT仕上げ精度点検完了、MEAL_RESULT / EXP_GAIN reference-uplift完了。`src/ui/screen_base.gd` の残hexは `Palette.SCREEN_BG_DEFAULT` へ移行済み。共有 `GaugeBar` の描画色は `Palette.GAUGE_*` へ移行済み。共有テーマ `src/ui/ui_theme.gd` は `Palette.THEME_*` へ移行済みで直書き色ゼロ。共有 `src/ui/ui_textures.gd` のprocedural魚アイコン色は `Palette.UI_FISH_ICON_*` へ移行済みで直書き色ゼロ。釣具店 `src/ui/shop_screen.gd` は `Palette.TACKLE_*` へ移行済みで直書き色ゼロ。魚市場 `src/ui/market_screen.gd` は一覧レアリティ色を `RarityStyles.list_text_color` へ、透明シャドウ色を `Color.TRANSPARENT` へ移行済みで直書き色ゼロ。調理場 `src/ui/cooking_screen.gd` は `Color(` 直書きゼロ。UI側の直接 `Palette.RARITY_*` 参照は `src/ui/rarity_styles.gd` へ集約済み。R1残件は台帳に温存し、次はLEVEL_UP_OVERLAY reference-uplift

Fable オーケストレーターが本ファイルを正本としてスライス順・状態・ベースラインを管理する。
Composer ワーカーは個別 brief のみ受け取り、本ファイルの更新はオーケストレーターが行う。

関連: `AGENTS.md` §オーケストレーション、`.cursor/rules/orchestration.mdc`、`skills/project-refactor-orchestration/SKILL.md`

## 全体ゴール

MVPを壊さず、今後のUI改善を画面単位で安全に進められる状態にする。

このフェーズの到達点は「全画面を完成形まで磨く」ではなく、次の画面改善を小さなスライスとして切り出し、見た目・Palette・素材所有・セーブ退行を毎回検証できる足場を作ること。

この作戦台帳でいう「安全」は、次を満たすこと:

- 共有基盤・巨大ファイル・Palette境界が、次の画面作業を妨げない粒度に整理されている
- 画面ごとの見た目判断が、実スクショ、reference横並び比較、`docs/qa/<screen>_qa.md`、`docs/qa/evidence/<screen>/` で追跡できる
- 触った画面は、その画面内のハードコード色を `src/ui/palette.gd` の用途名定数へ移行している
- UI変更は、該当 smoke と visual QA、全体 `validate_project.sh`、セーブ退行 `save_system_verify.sh` で退行なしを確認している
- freeze値は、P1再発時以外は動かしていない

この健全化フェーズの非ゴール:

- 全画面を参照画像どおりの最終アート品質まで磨き切ること
- `palette.gd` 外の色を機械的に一括ゼロ化すること
- 魚ポートレート専用描き起こし、水中ファイト最終authored素材など、素材制作そのものを完了条件に含めること
- コード整理とUI upliftを同一スライス・同一コミットへ混ぜること

## 実装優先順位

1. **完了済み差分の保護**: R9第1〜3段、釣り場マップR5/R1、魚図鑑R5/R1、調理場COOK_SELECT改善は完了済み。以後は純リファクタ、画面uplift、Palette移行を混ぜず、1スライス1関心で扱う。
2. **検証の信頼性維持**: `tools/cooking_layout_audit.tscn` の既存失敗は実スクショ上のP1文字欠けとして修正済み。以後はvisual QAの状態重複guard、layout/content audit、実スクショ目視をセットで扱う。
3. **調理フロー残り状態のR5優先**: 調理場R1は `src/ui/cooking_screen.gd` の `Color(` 直書きゼロまで完了したため一旦停止。MEAL_RESULT / EXP_GAINは完了。体感品質に寄与する LEVEL_UP_OVERLAY → STATUS_SUMMARY のreference-upliftを、1状態1スライスで進める。
4. **残り画面のR5/R1**: P1があれば最優先。P1がなければ、P2が明確で smoke / visual QA / reference / QAログが揃っている画面から進める。R1残件は画面単位で再開するまで温存し、機械的一括置換はしない。
5. **R1残件の棚卸し**: 画面単位の進行で残ったPalette未移行箇所を監査リストとして管理する。機械的一括ゼロ化はしない。
6. **任意の構造課題**: BGM二重実装など、MVP健全化の出口に必須でないものは、上記の完了後に別スライス化する。

## 健全化フェーズの完了判定

- [x] R9 第3段（報酬カード節抽出）が完了し、分割前後の調理visual QA 6キャプチャが cmp 完全一致
- [x] 調理場の高リスク既知ギャップを、最低1スライス以上、`docs/19` §8.5 と画面QAログに沿って解消
- [x] `tools/cooking_layout_audit.tscn` の失敗を、実P1修正または現行UX契約への監査更新として整理済み
- [ ] 触った画面・ファイルのPalette監査が green（調理場 `src/ui/cooking_screen.gd` は `Color(` 直書きゼロ。UI側の `Palette.RARITY_*` 直接参照は `src/ui/rarity_styles.gd` に集約済み。R1全体は画面単位で継続）
- [x] 各スライスの判断ログと証拠画像が `docs/qa/` 配下に保存済み
- [x] `./tools/validate_project.sh`、`./tools/save_system_verify.sh`、該当 smoke、該当 visual QA が green
- [x] 完了済みのfreeze値をP1再発なしに動かしていない

## 全体 Definition of Done

- [ ] `./tools/validate_project.sh` が通る
- [ ] 下記 §Smoke 一覧がすべて通る（R0 でベースライン記録済み）
- [ ] `docs/qa/*_qa.md` の freeze 値を変更していない（P1 再発時を除く）
- [ ] UI を触ったスライスは visual QA で退行なし

## Smoke 一覧（headless 実行）

Godot 4.x headless。プロジェクトルートから（`HOME` 隔離で本番セーブを保護）:

```bash
SMOKE_HOME=/tmp/tsuri-smoke-home; mkdir -p "$SMOKE_HOME"
HOME="$SMOKE_HOME" godot --headless --path . res://tools/<scene>.tscn
```

なお `PlayerProgress` は `res://tools/` 配下のシーン起動を検出してセーブ読み書きを無効化する（サンドボックスモード）ため、エディタから直接実行しても本番セーブは書き換わらない。`HOME` 隔離はその二重防護。

| シーン | 主な確認内容 |
|---|---|
| `fishing_reveal_smoke.tscn` | 魚種公開タイミング（BITE 前は伏せ、hook 後に公開） |
| `fishing_harbor_return_smoke.tscn` | 帰港確認・キーボード導線 |
| `fishing_spot_select_smoke.tscn` | 釣り場選択・ロック・船不足 |
| `shipyard_smoke.tscn` | 船購入・再購入防止・アクセス判定 |
| `tackle_shop_smoke.tscn` | 釣具店購入導線 |
| `market_smoke.tscn` | 市場売却 |
| `cooking_flow_smoke.tscn` | 調理→食事→EXP フロー |
| `fish_book_smoke.tscn` | 魚図鑑表示 |
| `status_smoke.tscn` | ステータス画面 |
| `catch_fanfare_smoke.tscn` | 捕獲ファンファーレ |
| `save_system_smoke.tscn` | セーブの原子的書き込み・バックアップ復元・サンドボックス保護（**必ず `./tools/save_system_verify.sh` 経由で実行**） |

一括実行（R0 ベースライン用）:

```bash
SMOKE_HOME=/tmp/tsuri-smoke-home; mkdir -p "$SMOKE_HOME"
for s in fishing_reveal fishing_harbor_return fishing_spot_select shipyard tackle_shop market cooking_flow fish_book status catch_fanfare; do
  echo "=== ${s}_smoke ==="
  HOME="$SMOKE_HOME" godot --headless --path . "res://tools/${s}_smoke.tscn" || exit 1
done
./tools/save_system_verify.sh
./tools/validate_project.sh
```

## スライス計画

| ID | concern | 依存 | 担当 | DoD | 状態 |
|---|---|---|---|---|---|
| R0 | ベースライン計測 | — | Composer | 全 smoke + validate の結果を §ベースラインに記録 | **done (2026-07-05)** |
| R1 | palette 外ハードコード色の洗い出しと修正 | R0 | Composer | `rg` 監査 green、validate + 触った画面 smoke | pending（洗い出しのみ完了: 約932件/22ファイル。機械置換の見た目退行リスクが高く、freeze済み画面のvisual QA前提で画面単位に分割して実施する。2026-07-05: 釣り場マップ2ファイル `src/ui/fishing_spot_select_screen.gd` / `src/ui/components/fishing_spot_map_view.gd` は `Palette.MAP_*` へ移行済み。魚図鑑 `src/ui/fish_book_screen.gd` は `Palette.FISH_BOOK_*` へ移行済み。共有基盤 `src/ui/screen_base.gd` は `Palette.SCREEN_BG_DEFAULT` へ移行済みで直書きhexゼロ。共有 `src/ui/components/gauge_bar.gd` は `Palette.GAUGE_*` へ移行済みで `Color(` 直書きゼロ。共有テーマ `src/ui/ui_theme.gd` は `Palette.THEME_*` へ移行済みで直書き色ゼロ。共有 `src/ui/ui_textures.gd` は `Palette.UI_FISH_ICON_*` へ移行済みで直書き色ゼロ。釣具店 `src/ui/shop_screen.gd` は `Palette.TACKLE_*` へ移行済みで直書き色ゼロ。魚市場 `src/ui/market_screen.gd` の一覧レアリティ色分岐は `RarityStyles.list_text_color` へ、透明シャドウ直書き色は `Color.TRANSPARENT` へ移行済みで直書き色ゼロ。調理場 `src/ui/cooking_screen.gd` は `Palette.COOKING_*` へ移行し、未使用detail helper由来のhex削除も含めて `Color(` 直書きゼロ。UI側の直接 `Palette.RARITY_*` 参照は `src/ui/rarity_styles.gd` に集約済み。`src/ui/cooking_screen.gd` のR1は完了、R1全体は他画面で継続） |
| R2 | showcase 素材参照違反の修正 | R0 | Composer×画面 | `audit_showcase_asset_refs.py` green | **done（監査の結果、現状違反ゼロ。作業不要）** |
| R3 | autoload / core の pure ロジック境界抽出 | R0, Fable 設計 | Composer | 振る舞い不変、該当 smoke green | **done (2026-07-05)** `game_data.gd`（1828行）を `game_catalog_data.gd`（constテーブル15個・約1430行）と `game_data.gd`（ルール定数+エイリアス+ロジック・約430行）に分離。公開APIはconstエイリアスで不変。7テーブルの JSON md5 前後一致で証明 |
| R4 | UI 共通基盤（ScreenBase 等）の整理 | R3, Fable 設計 | Composer | Fable 承認済み設計どおり、全 smoke green | **done (2026-07-05)** `ScreenBase.make_screen_label` を新設し、`_harbor_label` / `_shipyard_label` / `_book_label` / `_status_label` / `_market_label` を1行委譲に統合（呼び出し約120箇所は無変更）。画面固有の shadow/outline 色は引数渡しで screen_base への新規hex持ち込みなし。`GameFontsScript` preload を ScreenBase へ昇格し、継承7画面の重複 const を削除。全10 smoke + validate green |
| R5 | 画面別 UI uplift | R4 | Composer×画面 | 各 `skills/ui-screen-uplift/` + visual QA | 釣り場マップ done (2026-07-05): 詳細`エサ`/`仕掛け`行の省略P1再発を修正し、通常/釣行継続visual QA証拠を `docs/qa/evidence/fishing_spot_map/` に保存。魚図鑑 done (2026-07-05): Palette gate後のvisual QAでP1再発なし、既存portrait候補は現行に明確勝ちせず素材採用見送り（専用素材P2は新規候補待ち）。調理場 safe overrun foundation done (2026-07-05): `ScreenBase.make_label` の既定 `text_overrun_behavior` を `OVERRUN_TRIM_ELLIPSIS` に統一し、`docs/19` §8.5-7 を解消。編集前ベースライン `/tmp/tsuri_refactor_baseline/cooking_overrun_20260705_113951/` と編集後6キャプチャはピクセル完全一致、`cooking_visual_qa.sh` / 全UI smoke / `save_system_verify.sh` / `validate_project.sh` green。調理場 status de-dup done (2026-07-05): COOK_SELECTヘッダーを `PlayerStatusBar` へ置換し、下部「現在の準備」バーから重複Lv/EXP・所持金カードを撤去。証拠 `docs/qa/evidence/cooking/2026-07-05_status_dedupe_before_after_select.png`、`cooking_visual_qa.sh` / `cooking_flow_smoke` / 全UI smoke / `save_system_verify.sh` / `validate_project.sh` / `cooking_content_audit.tscn` green。調理場 layout audit repair done (2026-07-05): EXP_GAIN / LEVEL_UP_OVERLAY / STATUS_SUMMARY の実P1文字欠けを修正し、visual QAに重複キャプチャguardを追加。証拠 `docs/qa/evidence/cooking/2026-07-05_layout_audit_repair_levelup.png`、`cooking_visual_qa.sh` / `cooking_layout_audit.tscn` / `cooking_content_audit.tscn` green。調理場 COOK_SELECT recipe card reference-uplift done (2026-07-05): カード枠素材4枚を生成し、runtime星描画 `RecipeStarRank` とカード縦配分で上部タイトル帯 / 中央皿画像 / 下部星ランク+魚アイコンの3段構成へ寄せた。証拠 `docs/qa/evidence/cooking/2026-07-05_recipe_card_before_after_ref.png`、`cooking_visual_qa.sh` / `cooking_content_audit.tscn` / `cooking_layout_audit.tscn` / `cooking_flow_smoke` / `save_system_verify.sh` / `validate_project.sh` green。調理場 COOK_SELECT prep bar reference-uplift done (2026-07-05): 下部バー枠素材2枚を生成し、プレイヤーLv / 効果中の料理 / クーラーボックス / 所持金の4区画へ再構成。証拠 `docs/qa/evidence/cooking/2026-07-05_prep_bar_before_after_ref.png`、`cooking_visual_qa.sh` / `cooking_content_audit.tscn` / `cooking_layout_audit.tscn` / `cooking_flow_smoke` / `save_system_verify.sh` / `validate_project.sh` green。調理場 COOK_SELECT detail panel reference-uplift done (2026-07-05): 詳細行フレーム素材1枚を生成し、必要素材/獲得EXP/次の釣行効果行をアイコン帯+右バッジ構成へ再構成。証拠 `docs/qa/evidence/cooking/2026-07-05_detail_panel_before_after_ref.png`、`cooking_visual_qa.sh` / `cooking_content_audit.tscn` / `cooking_layout_audit.tscn` / `cooking_flow_smoke` / `save_system_verify.sh` / `validate_project.sh` green。調理場 COOK_SELECT background reveal reference-uplift done (2026-07-05): COOK_SELECT本体の左右余白/パネル間隔/glazeを調整し、厨房背景の見え方を改善。証拠 `docs/qa/evidence/cooking/2026-07-05_background_before_after_ref.png`、`cooking_visual_qa.sh` / `cooking_content_audit.tscn` / `cooking_layout_audit.tscn` / `cooking_flow_smoke` / `save_system_verify.sh` / `validate_project.sh` green。調理場 COOK_SELECT finish precision done (2026-07-05): 最新比較で料理カードタイトル帯の枠ノッチ干渉を確認し、runtimeタイトルをアウトラインなし太字+帯内下寄せへ調整。右詳細値プレートと下部4区画は実スクショでP1なし。証拠 `docs/qa/evidence/cooking/2026-07-05_select_precision_before_after_ref.png`、`cooking_visual_qa.sh` / `cooking_layout_audit.tscn` / `cooking_content_audit.tscn` / `cooking_flow_smoke` / `save_system_verify.sh` / `validate_project.sh` green。調理場 MEAL_RESULT reference-uplift done (2026-07-05): `meal_dish_card_frame.png` 候補を生成し、料理カードの広い料理窓+MEAL_RESULT専用の透明外枠でフォーム感を弱め、食事シーン背景上のpayoff状態へ寄せた。証拠 `docs/qa/evidence/cooking/2026-07-05_meal_result_before_after_ref.png`、`cooking_visual_qa.sh` / `cooking_layout_audit.tscn` / `cooking_content_audit.tscn` / `cooking_flow_smoke` / `save_system_verify.sh` / `validate_project.sh` green。調理場 EXP_GAIN reference-uplift done (2026-07-05): `exp_burst_frame.png` 候補を生成し、EXP_GAIN上部ステップ行を抑制して中央EXP演出を主役化。証拠 `docs/qa/evidence/cooking/2026-07-05_exp_gain_before_after_ref.png`、`cooking_visual_qa.sh` / `cooking_layout_audit.tscn` / `cooking_content_audit.tscn` / `cooking_flow_smoke` / `save_system_verify.sh` / `validate_project.sh` green。次はLEVEL_UP_OVERLAY |
| R6 | 調理フロー4ファイルの重複抽出（定数・StyleBoxヘルパ・皿テクスチャ解決→CookingAssets） | R0 | Composer | behavior-preserving、cooking_flow smoke + visual QA 画像一致、validate green | **done (2026-07-05)** 新規 `src/ui/components/cooking_assets.gd`。STATUS スクショはピクセル一致。RESULT/EXP/LEVELUP は元コードからキャプチャ非決定（アニメーション）のため cmp は参考値、visual QA passed |
| R7 | 画面横断の重複ヘルパ統合と不要コード削除（_format_money 8重複、_load_texture_if_exists、ScreenBase未使用API、extends表記統一） | R0 | Composer | behavior-preserving、全 smoke + validate green | **done (2026-07-05)** `ScreenBase.format_money` / `_anchored_control` / `_place_control` へ統合。見送り: `_last_sfx_path`（smoke が参照）、`shipyard._format_money`（`maxi` で挙動差）、独自ロジック入り `_load_texture_if_exists` 9ファイル |
| R9 | cooking_reward_panel（3,396行）の behavior-preserving 分割 | R8（決定的QAを退行判定に使用） | Composer | 各段で cooking visual QA 連続キャプチャが分割前と cmp 完全一致、cooking_flow smoke + validate green | **第1段 done (2026-07-05)** 内部Visualクラス17個（純描画・panel非依存）を新規 `src/ui/components/cooking_reward_visuals.gd`（1,297行）へ純移動し、panel 側は const エイリアスで参照不変（2,119行に減）。移動塊は空行差以外完全一致を diff で確認。素材監査 allowlist に抽出先を登録。6キャプチャがベースライン cmp 全一致。**第2段 done (2026-07-05)** ステータスストリップ節を `src/ui/components/cooking_reward_status_strip.gd`（296行、HBoxContainer component）へ抽出し panel は 1,796行に減。共有ヘルパ5つ+素材パス4定数を `CookingAssets` static へ昇格、`ScreenBase.make_label`/`make_body_label`/`make_shadow_label` を static 化（component からの利用を解禁、呼び出し側無変更）。panel の `_preview_state` 依存は `set_secondary(bool)` 注入に置換。6キャプチャがベースライン cmp 全一致。**第3段 done (2026-07-05)** 報酬カード節を新規 `src/ui/components/cooking_reward_cards.gd`（492行、GridContainer component）へ抽出し、panel は 1,338行に減。panel 側は `set_preview_state` / `show_meal_result` / `show_exp_gain` / `set_reward_cards_height` / `set_growth_text` の明示注入へ置換。編集前ベースライン `/tmp/tsuri_refactor_baseline/r9_reward_cards_20260705_112625/` と分割後6キャプチャが cmp 全一致。`cooking_flow_smoke` / `save_system_verify.sh` / `validate_project.sh` green |
| R8 | QA決定性（`TSURI_QA_DETERMINISTIC=1` で調理visual QAをピクセル決定的に）+ cooking_flow_smoke の ok 出力 | R0 | Composer | 連続2回実行で全状態 cmp 一致、フラグOFF時のパス不変 | **done (2026-07-05)** 原因は Tween入退場・Juicer trauma/hit_stop・GaugeBar の `_process` 補間。ガードは `ScreenBase.is_qa_deterministic()` に集約。オーケストレーターが独立に2回実行し6キャプチャ全一致を追認済み |

**fan-out 向き**: R0、R1（ファイル単位）、R2（画面単位）、R5（画面単位・並列可）、R6/R7（ファイル集合が素で並列可）  
**Fable 単体向き**: R3/R4 の設計判断、サブタスクに名前を付けられない調査

### R1 / Palette・RarityStyles 展開ログ

- 2026-07-05: 魚市場 `src/ui/market_screen.gd` の最後の透明シャドウ直書き色を `Color.TRANSPARENT` へ移行。新規Palette定数なし。理由: `_market_label` の表示同値透明色を直書き数値から組み込み定数へ寄せ、魚市場画面の直書き色をゼロにするため。`rg -n "Color\\((\\\"#|[0-9])" src/ui/market_screen.gd` 該当ゼロ。`./tools/market_visual_qa.sh` / `market_smoke.tscn` / `save_system_verify.sh` / `validate_project.sh` green。証拠: `docs/qa/evidence/fish_market/2026-07-05_market_transparent_palette_select_compare.png`, `docs/qa/evidence/fish_market/2026-07-05_market_transparent_palette_confirm_compare.png`。
- 2026-07-05: 釣具店 `src/ui/shop_screen.gd` の詳細アイコンtint、選択カードwash、タブactive/inactive tint、選択枠透明fillを `Palette.TACKLE_*` へ移行。新規定数は `TACKLE_DETAIL_ICON_MODULATE` / `TACKLE_CARD_SELECTION_WASH` / `TACKLE_TAB_*_MODULATE` / `TACKLE_SELECTION_FILL`。理由: freeze済み釣具店の残り直書き色4件を表示同値のまま用途名定数へ寄せ、次回R5で安全に触れるようにするため。`rg -n "Color\\((\\\"#|[0-9])" src/ui/shop_screen.gd` 該当ゼロ。`./tools/tackle_shop_visual_qa.sh` / `tackle_shop_smoke.tscn` / `save_system_verify.sh` / `validate_project.sh` green。証拠: `docs/qa/evidence/tackle_shop/2026-07-05_tackle_shop_palette_rod_compare.png`, `docs/qa/evidence/tackle_shop/2026-07-05_tackle_shop_palette_rig_compare.png`。
- 2026-07-05: 共有 `src/ui/ui_textures.gd` のprocedural魚アイコン色を `Color.TRANSPARENT` / `Color.WHITE` / `Palette.UI_FISH_ICON_EYE_DARK` へ移行。新規定数は `UI_FISH_ICON_EYE_DARK`。理由: ステータス画面・魚図鑑・ファイトサイドバーで使う共通魚アイコンの目色責務をPaletteへ集約し、`ui_textures.gd` の直書き色をゼロにするため。`rg -n "Color\\((\\\"#|[0-9])" src/ui/ui_textures.gd` 該当ゼロ。`./tools/fish_book_visual_qa.sh` / `./tools/status_visual_qa.sh` / `./tools/fight_visual_qa.sh` / `fish_book_smoke.tscn` / `status_smoke.tscn` / `fishing_reveal_smoke.tscn` / `save_system_verify.sh` / `validate_project.sh` green。証拠: `docs/qa/evidence/fish_book/2026-07-05_ui_textures_fish_icon_palette_compare.png`, `docs/qa/evidence/status/2026-07-05_ui_textures_fish_icon_palette_compare.png`, `docs/qa/evidence/underwater_fight/2026-07-05_ui_textures_fish_icon_sidebar_compare.png`。
- 2026-07-05: 共有テーマ `src/ui/ui_theme.gd` のパネル/ボタン/入力欄/ItemList focus/影/無効文字色を `Palette.THEME_*` へ移行。新規定数は `THEME_DARK_PANEL_BORDER` / `THEME_BLUE_PANEL_BORDER` / `THEME_PANEL_INNER_GOLD` / `THEME_DIALOG_FILL` / `THEME_BUTTON_PRESSED_BORDER` / `THEME_BUTTON_DISABLED_*` / `THEME_GOLD_BUTTON_*` / `THEME_INPUT_FILL` / `THEME_PANEL_SHADOW` / `THEME_BUTTON_SHADOW`。理由: 全画面に入るテーマ色責務をPaletteへ集約し、`ui_theme.gd` の直書き色をゼロにするため。`rg -n "Color\\((\\\"#|[0-9])" src/ui/ui_theme.gd` 該当ゼロ。headless `theme_preview.tscn` はViewport texture取得不可で失敗したため通常起動で証拠取得。`./tools/status_visual_qa.sh` / `./tools/tackle_shop_visual_qa.sh` / `./tools/market_visual_qa.sh` / `status_smoke.tscn` / `tackle_shop_smoke.tscn` / `market_smoke.tscn` / `save_system_verify.sh` / `validate_project.sh` green。証拠: `docs/qa/evidence/theme/2026-07-05_ui_theme_palette_preview.png`, `docs/qa/evidence/status/2026-07-05_ui_theme_palette_compare.png`, `docs/qa/evidence/tackle_shop/2026-07-05_ui_theme_palette_rod_compare.png`, `docs/qa/evidence/fish_market/2026-07-05_ui_theme_palette_confirm_compare.png`。
- 2026-07-05: 共有 `GaugeBar` の描画色（既定グラデーション、トラック、影、ゴースト、ハイライト、ダメージ点滅、危険域グロー、数値文字）を `Palette.GAUGE_*` へ移行。新規定数は `GAUGE_TRACK` / `GAUGE_TRACK_BORDER` / `GAUGE_SHADOW_CLEAR` / `GAUGE_SHADOW` / `GAUGE_GHOST` / `GAUGE_HIGHLIGHT` / `GAUGE_DAMAGE_FLASH` / `GAUGE_CRITICAL_GLOW` / `GAUGE_VALUE_OUTLINE` / `GAUGE_VALUE_TEXT`。理由: 調理報酬・調理ステータス・ステータス画面で共有するゲージの描画色責務を `palette.gd` へ集約し、共有部品内の直書き `Color(` をゼロにするため。`rg -n "Color\\(" src/ui/components/gauge_bar.gd` 該当ゼロ。`./tools/status_visual_qa.sh` / `status_smoke.tscn` / `./tools/cooking_visual_qa.sh`（透明キャプチャ1回後に同一差分で再実行green） / `cooking_flow_smoke.tscn` / `cooking_content_audit.tscn` / `cooking_layout_audit.tscn` / `save_system_verify.sh` / `validate_project.sh` green。証拠: `docs/qa/evidence/status/2026-07-05_gauge_bar_palette_compare.png`, `docs/qa/evidence/cooking/2026-07-05_gauge_bar_palette_select.png`。
- 2026-07-05: 魚市場一覧行のレアリティ色を、`src/ui/market_screen.gd` 内のローカル `match rarity` から `RarityStyles.list_text_color` へ移行。既存値を同値維持し、新規Palette定数なし。`./tools/market_visual_qa.sh` / `market_smoke.tscn` / `save_system_verify.sh` / `validate_project.sh` green。証拠: `docs/qa/evidence/fish_market/2026-07-05_market_rarity_styles_select_compare.png`。
- 2026-07-05: 調理場COOK_SELECT右詳細パネルのactive runtime色を追加で `Palette.COOKING_DETAIL_*` へ移行。新規定数は `COOKING_DETAIL_PANEL_*` / `COOKING_DETAIL_TITLE_*` / `COOKING_DETAIL_SUBTITLE_TEXT` / `COOKING_DETAIL_DISH_FRAME_*` / `COOKING_DETAIL_ACTION_FILL` / `COOKING_DETAIL_NOTE_*` / `COOKING_DETAIL_MATERIAL_ACCENT` / `COOKING_DETAIL_EXP_ACCENT`。理由: 参照uplift済みの右詳細パネルを、次回の画面単位改善で直書き色へ戻らず触れるようにするため。`./tools/cooking_visual_qa.sh` / `cooking_content_audit.tscn` / `cooking_layout_audit.tscn` / `cooking_flow_smoke.tscn` / `save_system_verify.sh` / `validate_project.sh` green。証拠: `docs/qa/evidence/cooking/2026-07-05_detail_palette_select.png`。
- 2026-07-05: 調理場COOK_SELECT左魚リストのactive runtime色を `Palette.COOKING_FISH_*` へ移行。新規定数は `COOKING_FISH_PANEL_*` / `COOKING_FISH_ICON_*` / `COOKING_FISH_NAME_*` / `COOKING_FISH_AMOUNT_*` / `COOKING_FISH_ROW_*`。理由: 参照uplift済みCOOK_SELECTの左列を、次回の魚行/素材改善で直書き色へ戻らず触れるようにするため。`./tools/cooking_visual_qa.sh` / `cooking_content_audit.tscn` / `cooking_layout_audit.tscn` / `cooking_flow_smoke.tscn` / `save_system_verify.sh` / `validate_project.sh` green。証拠: `docs/qa/evidence/cooking/2026-07-05_fish_list_palette_select.png`。
- 2026-07-05: 調理場COOK_SELECT中央料理グリッド外枠のactive runtime色を `Palette.COOKING_RECIPE_GRID_*` へ移行。理由: 料理カード本体だけでなく、中央列の枠色も次回の料理グリッド改善で直書き色へ戻らず触れるようにするため。`./tools/cooking_visual_qa.sh` / `cooking_content_audit.tscn` / `cooking_layout_audit.tscn` / `cooking_flow_smoke.tscn` / `save_system_verify.sh` / `validate_project.sh` green。証拠: `docs/qa/evidence/cooking/2026-07-05_recipe_grid_palette_select.png`。
- 2026-07-05: 調理場COOK_SELECT調理ボタンのactive runtime色を `Palette.COOKING_ACTION_*` へ移行。対象はボタン枠4状態、文字hover/pressed/disabled、runtime鍋アイコンのactive/disabled色。理由: 調理実行導線を、次回のボタン質感改善で直書き色へ戻らず触れるようにするため。`./tools/cooking_visual_qa.sh` / `cooking_content_audit.tscn` / `cooking_layout_audit.tscn` / `cooking_flow_smoke.tscn` / `save_system_verify.sh` / `validate_project.sh` green。証拠: `docs/qa/evidence/cooking/2026-07-05_cook_button_palette_select.png`。
- 2026-07-05: 調理場COOK_SELECT料理図鑑ボタンのactive runtime色を `Palette.COOKING_RECIPE_BOOK_BUTTON_*` へ移行。対象はボタン枠normal/hover/pressedと文字hover/pressed。理由: 中央列の副導線ボタンを、次回の料理グリッド改善で直書き色へ戻らず触れるようにするため。`./tools/cooking_visual_qa.sh` / `cooking_content_audit.tscn` / `cooking_layout_audit.tscn` / `cooking_flow_smoke.tscn` / `save_system_verify.sh` / `validate_project.sh` green。証拠: `docs/qa/evidence/cooking/2026-07-05_recipe_book_button_palette_select.png`。
- 2026-07-05: 調理場COOK_SELECT小アイコン/アクションキューのactive runtime色を `Palette.COOKING_SMALL_ICON_*` / `Palette.COOKING_ACTION_CUE_*` へ移行。対象はCOOK_SELECT下部バー/右詳細行/調理導線で使うruntime小アイコンと、調理ボタンへ向かうキュー線/皿面。理由: 参照uplift済みの装飾小物色を、次回のアイコン質感改善で直書き色へ戻らず触れるようにするため。`./tools/cooking_visual_qa.sh` / `cooking_content_audit.tscn` / `cooking_layout_audit.tscn` / `cooking_flow_smoke.tscn` / `save_system_verify.sh` / `validate_project.sh` green。証拠: `docs/qa/evidence/cooking/2026-07-05_small_icon_palette_select.png`。
- 2026-07-05: 調理場COOK_SELECT見出しリボンのactive runtime fallback色を `Palette.COOKING_SECTION_RIBBON_*` へ移行。対象は左魚リスト/中央料理リスト見出しのfallback frame色。理由: COOK_SELECTの主要見出し帯を、次回のリボン素材/質感改善で直書き色へ戻らず触れるようにするため。`./tools/cooking_visual_qa.sh` / `cooking_content_audit.tscn` / `cooking_layout_audit.tscn` / `cooking_flow_smoke.tscn` / `save_system_verify.sh` / `validate_project.sh` green。証拠: `docs/qa/evidence/cooking/2026-07-05_section_ribbon_palette_select.png`。
- 2026-07-05: 調理場結果サマリーカードのactive runtime色を `Palette.COOKING_SUMMARY_CARD_*` / `Palette.COOKING_RESULT_TITLE_OUTLINE` へ移行。対象は食事結果/ステータス要約で使うサマリーカード枠・タイトル・値アウトラインと結果タイトルアウトライン。理由: COOK_SELECT後続状態の結果カードを、次回のサマリー質感改善で直書き色へ戻らず触れるようにするため。`./tools/cooking_visual_qa.sh` / `cooking_content_audit.tscn` / `cooking_layout_audit.tscn` / `cooking_flow_smoke.tscn` / `save_system_verify.sh` / `validate_project.sh` green。証拠: `docs/qa/evidence/cooking/2026-07-05_summary_card_palette_result.png`。
- 2026-07-05: 調理場右詳細旧helper `_add_detail_tile` / `_add_detail_pair_tile` / `_add_detail_pair_cell` を削除。理由: 参照uplift後の実表示は `_add_detail_story_row` 経由で、旧helperは呼び出しゼロのまま直書き色だけを残していたため。`./tools/cooking_visual_qa.sh` / `cooking_content_audit.tscn` / `cooking_layout_audit.tscn` / `cooking_flow_smoke.tscn` / `save_system_verify.sh` / `validate_project.sh` green。証拠: `docs/qa/evidence/cooking/2026-07-05_unused_detail_helper_cleanup_select.png`。
- 2026-07-05: 調理場背景fallbackと料理カードtintの残色を `Palette.COOKING_BG_FALLBACK_*` / `Palette.COOKING_RECIPE_*_MODULATE` へ移行。理由: `src/ui/cooking_screen.gd` の最後の `Color(` 直書き（背景fallback、料理カード/素材/皿画像tint）を用途名定数へ寄せ、調理場画面のR1を完了するため。`rg -n "Color\\(" src/ui/cooking_screen.gd` 該当ゼロ。`./tools/cooking_visual_qa.sh` / `cooking_content_audit.tscn` / `cooking_layout_audit.tscn` / `cooking_flow_smoke.tscn` / `save_system_verify.sh` / `validate_project.sh` green。証拠: `docs/qa/evidence/cooking/2026-07-05_background_fallback_palette_select.png`。
- 2026-07-05: catch fanfareのレア紙吹雪色を `Palette.RARITY_RARE_TEXT` 直接参照から `RarityStyles.text_color("レア")` へ移行。理由: UI側で `Palette.RARITY_*` を直接参照せず、レアリティ色責務を `src/ui/rarity_styles.gd` へ集約するため。`rg -n "Palette\\.RARITY" src/ui -g "*.gd"` は `src/ui/rarity_styles.gd` のみ。`catch_fanfare_smoke.tscn` / `save_system_verify.sh` / `validate_project.sh` green。証拠: `docs/qa/evidence/underwater_fight/2026-07-05_catch_fanfare_rarity_styles.png`。

### R5 選定ログ

- 2026-07-05: 最初のR5対象は釣り場マップ。`docs/qa/fishing_spot_map_qa.md` が「アップリフト進行中」かつ証拠画像の永続化TODOあり、`docs/19` §8.5のvisual QA継続運用対象で、`tools/fishing_spot_map_visual_qa.sh` / `fishing_spot_select_smoke.tscn` が既に揃っているため。
- 2026-07-05: 新規Palette定数は `Palette.MAP_*`（`MAP_BG_*` / `MAP_DETAIL_*` / `MAP_FOOTER_*` / `MAP_ENTRY_*` / `MAP_CHART_*` / `MAP_ROUTE_*` / `MAP_CHIP_*` など）。理由: 釣り場マップ固有の海図・羊皮紙・ロック状態・航路発光色が既存Paletteに用途名として存在せず、表示色を変えずに画面単位R1移行するため。
- 2026-07-05: 2画面目のR5対象は魚図鑑。`docs/qa/fish_book_qa.md` に残P2（専用魚ポートレート素材）と `docs/24_fish_book_portrait_asset_brief.md` の評価手順が整理済みで、`tools/fish_book_visual_qa.sh` / `fish_book_smoke.tscn` が揃っており、Palette移行対象も `src/ui/fish_book_screen.gd` 中心に限定できるため。
- 2026-07-05: 魚図鑑の新規Palette定数は `Palette.FISH_BOOK_*`。理由: 魚図鑑の台帳紙面・セピア罫線・魚ポートレートtint/影・索引ボタン色は freeze済みの画面固有値が多く、既存Paletteへ近似せず表示色同値でR1移行するため。
- 2026-07-05: 次のR5対象は調理場の `text_overrun_behavior` 既知ギャップ。`docs/19` §8.5-7 のP1予防で、`tools/cooking_visual_qa.sh` / `cooking_flow_smoke.tscn` が揃っており、共有ラベル基盤で解くため調理場のfreeze値・素材・画面固有Paletteを動かさず検証できるため。
- 2026-07-05: 新規Palette定数は `Palette.SCREEN_BG_DEFAULT`。理由: `ScreenBase.add_background()` の既定背景 `#091a2d` を表示同値のままPalette正本へ移し、今回触った共有基盤ファイルの残hexをゼロにするため。
- 2026-07-05: 次の調理場R5対象は `PlayerStatusBar` 展開 + COOK_SELECT情報重複解消。`docs/19` §8.5-2/3 の既知ギャップで、現行ヘッダーと下部「現在の準備」バーがLv/EXP/所持金を重複表示しており、共通ステータスバー適用と下部要約の役割整理を同一構成スライスとして検証できるため。
- 2026-07-05: 新規Palette定数は `Palette.COOKING_TITLE_FALLBACK_BG` / `Palette.COOKING_WOOD_BORDER` / `Palette.COOKING_GOLD_TRIM`。理由: 調理場ヘッダーのタイトルバナーfallback色を表示同値のままPalette正本へ移し、今回触った行へ新規hexを残さないため。
- 2026-07-05: 次の調理場R5対象は layout audit failure repair。`tools/cooking_layout_audit.tscn` の失敗が実スクショでもEXP_GAIN / LEVEL_UP_OVERLAY / STATUS_SUMMARYのP1文字欠けとして再現し、visual QAの状態重複も検出されたため。
- 2026-07-05: フェーズを「退行ゼロ」から「参照画像へ近づける」に切替。次のR5対象はCOOK_SELECT料理カード。`docs/qa/evidence/cooking/2026-07-05_layout_audit_repair_select.png` と `reference/cooking_flow/01_cook_select_concept.png` の横並びで、カード上部タイトル帯 / 中央皿画像 / 下部星ランク+魚アイコンの3段構成が弱く、docs/19の順序では構成・文字収まり通過後の素材質感フェーズに入るため。
- 2026-07-05: 新規Palette定数は `Palette.COOKING_RECIPE_*`。理由: COOK_SELECT料理カード固有のタイトル/星/フッター/カード状態/サムネ/素材行色を、今回触ったruntime行から用途名定数へ移すため。
- 2026-07-05: 次のR5対象はCOOK_SELECT下部バー。`docs/qa/evidence/cooking/2026-07-05_recipe_card_before_after_ref.png` のafterでも下部は「現在の準備 / 効果中の料理 / クーラーボックス / 詳細」に留まり、参照の「プレイヤーLv / 効果中の料理 / クーラーボックス / 所持金」4区画の装飾フレーム構成へ未到達のため。
- 2026-07-05: 新規Palette定数は `Palette.COOKING_PREP_*`。理由: COOK_SELECT下部バー/カード/タイトル/値のruntime色を、今回触った行から用途名定数へ移すため。
- 2026-07-05: 新規Palette定数は `Palette.COOKING_DETAIL_*`。理由: COOK_SELECT右詳細行/バッジ/値のruntime色を、今回触った行から用途名定数へ移すため。
- 2026-07-05: 新規Palette定数は `Palette.COOKING_BG_GLAZE`。理由: COOK_SELECT背景glaze色を、今回触った行からPalette正本へ移すため。
- 2026-07-05: 次のR5対象はCOOK_SELECT背景の見せ方。`docs/qa/evidence/cooking/2026-07-05_detail_panel_before_after_ref.png` のafterでもパネル群が横幅をほぼ覆い、参照のような左右パネル間/外周の厨房背景と暖色奥行きが弱いため。
- 2026-07-05: 次のR5対象はCOOK_SELECT右詳細パネル。`docs/qa/evidence/cooking/2026-07-05_prep_bar_before_after_ref.png` のafterでも「次の釣行で得られる効果」行の `1回` が右端に浮いて見え、必要素材行/獲得EXP行も参照の帯・アイコン質感に届いていないため。
- 2026-07-05: R1色移行は調理場 `src/ui/cooking_screen.gd` の `Color(` 直書きゼロ到達をもって一旦停止。次のR5対象はCOOK_SELECT仕上げ精度点検。最新 `reference/cooking_flow/01_cook_select_concept.png` 横並びで、料理カードタイトル帯の枠ノッチ干渉、右詳細3行の値プレート、下部4区画の見切れを確認してから残り4状態へ進むため。
- 2026-07-05: 次のR5対象はMEAL_RESULT。COOK_SELECT仕上げ点検後、ユーザー指定の優先順どおり `reference/cooking_flow/02_meal_result_concept.png` に対して1状態1スライスで参照upliftへ進めるため。
- 2026-07-05: 次のR5対象はEXP_GAIN。MEAL_RESULTのbefore/after/reference比較で食事payoff状態への前進を確認したため、ユーザー指定の優先順どおり `reference/cooking_flow/03_exp_gain_concept.png` に進む。
- 2026-07-05: 次のR5対象はLEVEL_UP_OVERLAY。EXP_GAINのbefore/after/reference比較で、上部ステップ行の抑制と中央EXP演出の素材更新により専用EXP状態への前進を確認したため、ユーザー指定の優先順どおり `reference/cooking_flow/04_level_up_overlay_concept.png` に進む。

### 監査で確認したが今回見送った項目（2026-07-05）

- ~~ラベル生成ラッパー統合（`_harbor_label` / `_shipyard_label` / `_book_label` 等）~~: R4 として 2026-07-05 実施済み
- BGM 二重実装（`main.gd` の opening BGM と `ScreenBase.play_screen_bgm`）: main.gd は ScreenBase 非継承で境界設計が必要。Fable 単体向き
- `PlayerProgress` の emit-only シグナル（`progress_changed` 等）: 拡張点として温存。削除しない判断
- `fight_hud` 等 fight 系コンポーネントの hex 色: R1 へ

## ベースライン（R0 完了後に記録）

Godot v4.7.stable.official（`/Applications/Godot.app/Contents/MacOS/Godot`）で計測。

| チェック | 日付 | 結果 | 備考 |
|---|---|---|---|
| validate_project.sh | 2026-07-05 | green (exit 0) | 終了時 ObjectDB 2件リーク / resource 1件残存の警告あり |
| fishing_reveal_smoke | 2026-07-05 | green | |
| fishing_harbor_return_smoke | 2026-07-05 | green | ObjectDB 2件リーク / resource 1件残存 |
| fishing_spot_select_smoke | 2026-07-05 | green | ObjectDB 3件リーク / resource 1件残存 |
| shipyard_smoke | 2026-07-05 | green | |
| tackle_shop_smoke | 2026-07-05 | green | |
| market_smoke | 2026-07-05 | green | |
| cooking_flow_smoke | 2026-07-05 | green | 成功時の `ok` print がない唯一の smoke（観測性の改善候補） |
| fish_book_smoke | 2026-07-05 | green | |
| status_smoke | 2026-07-05 | green | |
| catch_fanfare_smoke | 2026-07-05 | green | ObjectDB 6件リーク / resource 2件残存 |

既知の警告（ベースライン時点から存在。リファクタの退行判定には使わない）: ObjectDB リーク、`Could not create ObjectDB Snapshots directory`。

## ワーカー brief テンプレート

```markdown
## Concern
（1文）

## 触ってよいファイル
- path/to/file.gd

## 触ってはいけないもの
- docs/qa/<screen>_qa.md の freeze 値
- （その他）

## Definition of Done
- [ ] （コマンドと期待結果）

## 報告形式
- 変更概要:
- 実行結果:
- 未解決:
```

## Cloud Agent 初回プロンプト例

```
docs/26_refactor_orchestration_plan.md を正本として behavior-preserving リファクタを進めてください。

- あなた（Fable）は計画・レビュー・完了判断のみ
- 実装・監査・smoke は Composer 2.5 subagent に brief で fan-out
- 1スライス完了ごとに validate + 該当 smoke を確認してから次へ
- freeze 値・docs/19 違反があれば停止して報告

最初の作業: R0 ベースライン計測。結果を §ベースライン に追記。
```
