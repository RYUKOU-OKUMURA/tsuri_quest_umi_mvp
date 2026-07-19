# 調理場 QA判断ログ

最終更新: 2026-07-19 / 状態: iPad魚一覧scroll局所修正・自動回帰完了（実機再確認待ち） / C3・C1-A・C1-B・C2-WIRE・C0・既存構成freeze維持
参照画像: reference/cooking_flow/01_cook_select_concept.png, reference/cooking_flow/02_meal_result_concept.png, reference/cooking_flow/03_exp_gain_concept.png, reference/cooking_flow/04_level_up_overlay_concept.png, reference/cooking_flow/05_status_summary_concept.png
QA更新コマンド: ./tools/cooking_visual_qa.sh

## 1. freeze値（正本）

現在有効な値だけを書く。値を更新したら該当行を**上書き**する（追記して古い行を残さない）。

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 共通Labelのoverrun既定 | `TextServer.OVERRUN_TRIM_ELLIPSIS` | `src/ui/screen_base.gd` `ScreenBase.make_label` | `make_body_label` / `make_shadow_label` 由来の調理場ラベルで `clip_text` だけが立つ状態を避ける。省略が通常データで発動しないことはvisual QAで確認する |
| EXP_GAIN P1短縮文言 | 左説明 `料理から食経験値が流れ込む。` / 中央メッセージ `力がみなぎった！` | `src/ui/components/cooking_reward_panel.gd` | EXP_GAINの料理カード説明・中央メッセージ省略表示を消すため。P2構成改善時も省略を再発させない |
| EXP_GAIN 中央主役構成 | `RewardFlowRow visible=false` / `ExpGainBanner 104px` / `ExpGainValue font 68` / `ExpBurstFrame min-height 332px` / 右効果本文は短縮表示 | `src/ui/components/cooking_reward_panel.gd` | P2 Top1構成改善。参照の大見出し・巨大EXP・中央ゲージを先に読ませるため。主要単行ラベルは `OVERRUN_NO_TRIMMING` で描画安定化 |
| LEVEL_UP_OVERLAY 解放説明 | `Lv.%d到達。港の大岩周辺で、港のぬしに挑めます。` | `src/ui/components/level_up_panel.gd` | 解放説明の末尾省略を消し、Lv.5解放内容を読み切れるようにする |
| LEVEL_UP_OVERLAY 報酬階層 | `LevelUpDialog min 1100x590` / `LevelUpTitleBand min 1000x172` / `LevelUpTitle font 64 extra_bold` / `LevelUpLevelLine font 42 extra_bold` / 解放カード `900x142` | `src/ui/components/level_up_panel.gd` | P2構成改善。`LEVEL UP!` と `Lv.4 -> Lv.5` を通常パネルより明確に強い報酬ピークとして読ませるため |
| STATUS_SUMMARY ヘッダーEXP幅 | `StatusHeaderExpBox 540px` / `StatusHeaderExpBar min 170px` / `StatusHeaderExpValue min 120px` | `src/ui/components/cooking_status_panel.gd` | 上部EXPゲージと数値を空枠に見せないため。layout auditの最小幅も更新済み |
| STATUS_SUMMARY プレイヤーhero | `StatusPlayerHero min-height 154px` / `StatusNextExpText` は `次Lv\n%d EXP` / ステータス5行は `StatusStatRow*` 小カード | `src/ui/components/cooking_status_panel.gd` | P2 Top2構成改善。人物・Lv・次EXP・ステータス名/数値を、参照のプレイヤーカードのように同じ視線で読ませるため |
| COOK_SELECT 右詳細タイトル帯 | `SelectedDishTitlePlate min-height 68px` / `SelectedDishTitle font 31 extra_bold` / `OVERRUN_NO_TRIMMING` / 料理画像 `SelectedDishFeatureImage min-height 140px` | `src/ui/cooking_screen.gd` | P2 Top3構成改善。右詳細を「料理名 -> 大皿 -> 材料/EXP/効果 -> 調理する」の順に読ませるため |
| MEAL_RESULT モードタブ位置 | `MealResultModeTabVisual` plate `x=18 y=6` | `src/ui/components/cooking_reward_visuals.gd` | 「食べる」タブが結果バナー本文に重なるP1寄り表示を避けるため |
| MEAL_RESULT 不透明ステージ下地 | `RewardStageBase` はMEAL_RESULT時のみ画面全体 `1280x720`・alpha `1.0` | `src/ui/components/cooking_reward_panel.gd` | alpha付き `meal_scene_bg.png` の下から前状態が透けるP1を防ぎ、EXP_GAIN / LEVEL_UPでは背面の調理画面を維持する |
| STATUS_SUMMARY カード見出し帯 | `StatusSummaryTitleBand*` は `PanelBox`（文字を横断するボタン枠PNGを使わない） | `src/ui/components/cooking_status_panel.gd` | 5カードのタイトルを原寸で常に読めるようにする。カード矩形・見出し文字サイズは不変 |
| EXP_GAIN / LEVEL_UP 下部導線 | 本文左content margin `Reward=88px` / `LevelUp=92px`、各Button直下は単一の命名Label cue（`RewardConfirmCue` / `LevelUpConfirmCue`）のみ。`MEAL_RESULT` / `EXP_GAIN` / `LEVEL_UP` は `▶`、`EXP_GAIN_LEVELUP` は `▲` | `cooking_reward_panel.gd` / `level_up_panel.gd` / `tools/cooking_content_audit.gd` | 40px高の導線で複数小グリフが本文と潰れるP1を防ぐ。余白・cue名・単一Label構造・draw接続なし・状態別glyphはheadless監査する |
| STATUS_SUMMARY 所持金 | 整数部は3桁カンマ区切り（例: `10,170 G`） | `src/ui/components/cooking_status_panel.gd` | docs/19 §4.3の金額表記規格 |
| COOK_SELECT厨房背景 | source `b3e7d525...686cb` / output `67157172...81106`、1280x720、彩度 `0.84`、濃紺scrim alpha `48` | `tools/source_assets/cooking/c1a_kitchen_bg_source.png` / `tools/process_cooking_c1a_assets.py` / `assets/showcase/cooking/cooking_room_bg.png` | C1-A採用値。暖色ランタン光・海窓・調理棚を持つ環境のみ一点物。3列・全前景矩形・runtime glazeは不変 |
| COOK_SELECT料理カード C1-B | source: 通常/選択 `560x440`、濃紺タイトル帯 `560x124`。output: 通常/選択 `280x220`、濃紺タイトル帯 `280x62`。runtime表示 `132x196`、タイトル領域 `31px`。source SHA-256 `388b926f...27ad5` / `19ca076a...b5f9` / `d3ac1640...14b21`、output `4320ed58...3fe4` / `82151085...82f5` / `b509b93c...02bf` | `tools/source_assets/cooking/c1b_recipe_*_source.png` / `tools/process_cooking_c1b_assets.py` / `assets/showcase/cooking/recipe_{card_frame,selected_card_frame,title_band}.png` | 羊皮紙・木/金細枠・濃紺帯をPNGへ移し、日本語名/星/素材footer/lock文言はruntime維持。locked/unavailableは既存modulate、hoverは未選択availableだけ暖色tint、focusは共通枠を維持 |
| MEAL_RESULT食事シーン背景 C2 | source `1672x941 RGB`、製品 `1280x720 RGBA`。source file SHA-256 `673783a3...a245`、product file SHA-256 `42b68430...d8cb`、product decoded RGBA SHA-256 `fcdfcd62...873` | `tools/source_assets/cooking/c2_meal_scene_bg_source.png` / `tools/process_cooking_c2_product.py` / `assets/showcase/cooking/meal_scene_bg.png` | 2026-07-17採用。食卓・暖色ランタン・港の夕景窓を持つ環境背景だけを置換。人物/料理/UI/文字なし。product processorが単一writerで、同一画素bytes保持・差時same-dir atomic replace・read-only check・隔離破損self-testを所有する |
| COOK_SELECT 入力導線 | 初期focusは「選択中の調理可能recipe → 選択中の所持fish → 料理図鑑 → 港」の順。所持fish / 調理可能recipe / 料理図鑑 / 有効な調理 / 港だけを候補とし、未所持・locked・disabledは `FOCUS_NONE`。Tab/Shift+Tabと方向入力は有効候補だけの閉路、再構築時は `fish:<id>` / `recipe:<id>` でA→B→A復元。所持fish rowは `MOUSE_FILTER_PASS`、透明hit targetは72px row全面を覆うrelease-only、魚一覧のdrag deadzoneは1280×720論理座標 `12px`。12px未満はrelease時に1回だけ選択し、超過dragは選択をcancelしてscrollへ渡す | `src/ui/cooking_screen.gd` / `tools/cooking_input_smoke.gd` | INPUT-COOKING採用値。表示矩形とkeyboard/gamepad契約を変えず、魚画像・魚名・所持数とrow上下端から始めるiPad dragをScrollContainerへ渡す。headlessはdesktop emulated drag契約で、実touch合格は実機確認を別途要求する |
| 調理5状態 入力handoff | `MEAL_RESULT` / `EXP_GAIN` は `RewardConfirmButton`、`LEVEL_UP_OVERLAY` は `LevelUpConfirmButton`、`STATUS_SUMMARY` は `StatusReturnButton` のみfocus可能。背面とoverlay内の他Controlは `FOCUS_NONE`。EscapeはCOOK_SELECTとSTATUS_SUMMARYのみ港へ1回、食事・EXP・レベルアップでは進行を飛ばさず消費 | `src/ui/cooking_screen.gd` / `tools/cooking_input_smoke.gd` | C0の単一cue構造を変えず、不可逆報酬の誤skipと背景focus漏れを防ぐ |
| 旧調理一括generatorの製品保存 | size / mode / decoded pixels完全一致なら既存bytes保持。真の差・欠損・読込不能だけ同一directory tempへ `flush` + `fsync` 後atomic replace。C1-A背景は専用processor、採用済み11 slotは明示guard | `tools/generate_cooking_showcase_assets.py` / `tools/cooking_generator_determinism_verify.py` | Pillow版差で採用品を再encode・再描画しない。保存失敗時は旧製品とtemp cleanupを保証。製品57点のfile/decoded hash・size/modeをfocused検証で固定 |

## 2. 不採用・再試行禁止リスト

| 案 | 却下理由 | 判断日 |
|---|---|---|

## 3. 微調整カウンタ

| パラメータ | 回数 | 直近の変更内容 | 状態 |
|---|---|---|---|
| LEVEL_UP_OVERLAY 上部祝祭帯 | 3 | crown/laurel候補を生成。LEVEL UP文字拡大とLv行拡大は表示契約が落ちたため不採用、最終的にcrown/laurelとダイアログ寸法のみ採用 | 完了 |
| LEVEL_UP_OVERLAY 報酬階層 | 1 | ダイアログ全体を大型化し、`LevelUpTitleBand` を報酬プレート化。`LEVEL UP!` とLv遷移をextra boldで大型化し、ステータス行/解放カードを下へ再配分 | 構成改善完了 |
| STATUS_SUMMARY カード密度/背景 | 3 | `status_card_frame.png` 候補生成、背景抜け、値プレート化を実施。半透明化したカード素材候補は不採用とし、素材生成を合成方式へ修正して不透明紙面で採用 | 完了 |
| EXP_GAIN 中央演出/ステップ行 | 4 | 構成整理でステップ行を非表示、左右カードを圧縮、中央EXPカード/タイトル/+EXP/ゲージを拡大。主要単行ラベルは横展開と省略禁止で描画安定化 | 構成改善完了。残る迫力差は一点物素材/祝祭設計へ送る |
| STATUS_SUMMARY プレイヤーhero/ステータス行 | 1 | 人物・Lv・次EXP・ゲージをheroへ統合し、5ステータスを小カード化して名前と数値を読めるようにした | 構成改善完了 |
| MEAL_RESULT 料理カード/外枠構成 | 2 | 料理カード素材候補の広い料理窓に合わせて配分を試し、1回目は料理名が狭くなったため、2回目で画像幅/文字サイズとMEAL_RESULT専用透明外枠を採用 | 完了 |
| COOK_SELECT 料理カードタイトル帯 | 1 | 最新比較で枠ノッチとタイトル文字の干渉を確認し、runtimeタイトルをアウトラインなし太字・帯内下寄せへ調整 | 完了 |
| COOK_SELECT 料理カード星ランク表示 | 1 | Label幅中央寄せを試したが実スクショで星文字が弱く、runtimeポリゴン描画 `RecipeStarRank` へ切替 | 完了 |
| COOK_SELECT 右詳細料理名/大皿階層 | 1 | 右詳細上部を `SelectedDishTitlePlate` に組み替え、料理名を太字・省略禁止・監査対象にした | 構成改善完了 |
| C0 runtime表示破綻 | 1 | 不透明ステージ下地、静かなカード見出し帯、単一導線グリフ、金額formatへ置換 | 完了 |
| C1-A厨房背景 | 1 | OpenAI生成sourceを彩度統一・濃紺減光して既存slotへ差し替え | 素材採用・freeze |
| C1-B料理カード紙面・タイトル帯 | 1 | 通常/選択の羊皮紙・木/金細枠と共通濃紺タイトル帯を専用PNGへ移行 | 素材採用・freeze |
| C2 MEAL_RESULT食事シーン背景 | 1 | 準備済み候補を同一runtime状態へ仮配線し、木の食卓・ランタン・港の夕景窓を持つ背景へ置換 | 素材採用・freeze |

## 4. 暫定判定・再検証TODO

なし。

## 5. 現在の残ギャップ

- P1: なし。2026-07-10 C0でMEAL_RESULTの背面残像、STATUS_SUMMARYのタイトル帯衝突、EXP_GAIN / LEVEL_UP_OVERLAYの下部導線グリフ潰れ、STATUS_SUMMARY所持金の桁区切り違反を解消済み。既存の省略表示・ヘッダーEXP・モードタブのP1修正も維持。
- P2 Top1完了: `EXP_GAIN` はステップ行を退け、中央の大見出し・巨大 `+EXP`・EXPゲージを先に読める構成へ改善済み。参照の一点物祝祭密度、巨大タイトルの余白、背景/光の素材差は残るが、次に触るなら数px調整ではなくAI生成一点物素材または祝祭設計フェーズとして扱う。
- P2 Top2完了: `STATUS_SUMMARY` はヘッダーsubtitle、プレイヤーhero、ステータス5行、各カードのアート高さを見直し、人物・Lv/次EXP・ステータス名/数値が読める独立ステータス画面へ改善済み。参照ほどの人物一点物アート密度やカード装飾密度は残るが、次に触るなら素材フェーズとして扱う。
- P2 Top3完了: `COOK_SELECT` は右詳細上部を料理タイトル帯に組み替え、料理名・説明・大皿・材料/EXP/効果・調理ボタンの順に読める構成へ改善済み。参照ほど行ラベルと効果行の一体感は残っていないが、残差はカード素材/行フレームの一点物素材フェーズとして扱う。
- C1-A完了: COOK_SELECT厨房背景は、暖色ランタン光・海の見える窓・調理棚が読める authored sourceへ移行した。原寸と320x180比較で現行の平坦な矩形背景に明確に勝ち、参照01の背景差が縮んだ。後続C1-Bのカード質感も完了したため、背景の再調整へ戻らず、次はC2-WIREへ進む。
- C1-B完了: 中央3×2料理カードは、通常/選択の羊皮紙・木/金細枠と共通濃紺タイトル帯へ移行した。320×180でもタイトル帯と紙面が参照01方向へ近づき、locked/unavailable/長文/hover/focusでP1なし。カード寸法・皿・星・footerは不動。
- C2-WIRE完了: MEAL_RESULT背景は、幾何的な丸灯・床線・空皿の下地から、木の食卓・暖色ランタン・港の夕景窓を持つ authored 食堂へ移行した。原寸beforeへ明確に勝ち、320×180で参照02の暗い木部/食卓/ランタン方向との差が縮んだ。人物・料理・報酬4枚・文字・全foreground geometryは不動で、他4状態はV2 prebaselineとpixel完全一致。次は背景へ戻らずC3へ進む。
- INPUT-COOKING完了: E11実イベント計測でCOOKING findings 0。COOK_SELECTの動的fish/recipe、空inventory、locked recipe、最後の魚消費、5状態handoff、Escape一重処理、mouse回帰を専用smokeで固定した。2026-07-19に魚一覧だけを72px全面release-only hit target＋12px deadzoneへ局所修正し、上下端tap、6px jitterの一重選択、上下端起点72px dragのscroll開始・誤選択0、wheel、focus、72px row寸法不変を自動回帰へ追加した。iPad Air実機での魚画像・魚名・所持数起点の再確認は未実施で、完了まで本項の実touch判定は保留する。見た目の既存構成やC0 cueは再オープンしない。
- INPUT-COOKING visual回帰: 2026-07-19の再撮影で `COOK_SELECT / MEAL_RESULT / LEVEL_UP_OVERLAY / STATUS_SUMMARY` はC3 formal evidenceとpixel完全一致。C3 evidence JSONの `project.godot` hashだけを、後発のiPad export設定追加後のHEADへ同期した。
- P2完了: `LEVEL_UP_OVERLAY` はタイトル帯を報酬プレート化し、`LEVEL UP!` と `Lv.4 -> Lv.5` を通常パネルより強い主導線へ改善済み。ステータス行とLv.5解放カードも下段に残り、報酬ピークとして読める。
- P3止まり: 参照の立体的な巨大金文字、より密な金色光線/紙吹雪、月桂樹とメダルの一点物アート密度、魚種差、所持数差、枠線数px、星/小アイコン/紙汚れ/影/粒子の微差は、今後触るなら一点物素材/演出フェーズとして扱う。

## 6. フェーズスコープ宣言（作業中のみ）

2026-07-18: `Visual Wave V3 C3 EXP_GAIN祝祭` を、Top1の光背/バースト1スロットだけの局所素材スライスとして開始。

- 着手前baseline: `./tools/cooking_visual_qa.sh` を編集前に実行。現行5状態を同一決定状態で再撮影し、`/tmp/tsuri_cooking_{select,result,exp,levelup,status}.png` を確認。正式証拠は採否後に `docs/qa/evidence/cooking/2026-07-18_c3_*` へ保存する。
- C3差分Top3: 1) `EXP_GAIN` の `exp_burst_frame.png` がPILの黄青ストライプとゲージ要素の混在で祝祭の光背/放射粒子として弱い、2) `EXP_GAIN` 大見出し・`+EXP` の金文字/光量が参照03より小さく弱い、3) EXPゲージ台座が専用祝祭フレームと一体化していない。
- 今回動かすもの: Top1の `exp_burst_frame` 祝祭光背/放射光/粒子slotのみ、C3専用source、決定的processor、製品slot、C3証拠、素材台帳、必要最小限の素材監査consumer。
- 今回動かさないもの: `exp_stage_bg`、大見出し/`+EXP` のruntime文字とサイズ、ゲージ台座/ゲージ値、料理画像、`MEAL_RESULT` / `LEVEL_UP_OVERLAY` / `STATUS_SUMMARY` runtime、C1-A/C1-B/C2-WIRE製品とfreeze、既存レイアウト・Palette・common・進行/入力/バフ/セーブロジック・他画面。
- 代表状態: level-upなしEXP_GAIN、`EXP 127 / 285 -> 165 / 285`、初回済みの `メジナの煮付け`、効果 `安全域 +10%`。
- 高リスク状態: `EXP_GAIN_LEVELUP`、初回bonus有無、EXP上限、長いbuff文言。C3では料理画像・ゲージ台座・背景の差を混ぜず、光背slotの差だけを確認する。
- 採用条件: 同一状態の原寸afterが現行に明確に勝ち、320×180 after/referenceで参照03の「中央から広がる暖色放射光・粒子」の差が縮むこと。PIL有機バーストの再利用/改造は採用不可。参照PNGの直接import・日本語/可変数値の焼き込み不可。負けた候補はrevertし、不採用理由と証拠を記録する。
- allowed-diff: EXP_GAINの `exp_burst_frame` で表現されるslotの画素だけ。背景・runtime文字・ゲージ値/台座・料理画像・下部stripと、他4状態の非対象画素は不動。

2026-07-18: `C3 EXP_GAIN祝祭` を採用完了。Top1の `exp_burst_frame` 1スロットだけを差し替え、参照03の中央放射光・暖色粒子方向へ寄せた。

- 採用候補: `tools/source_assets/cooking/c3_exp_burst_source.png` を `tools/cooking_c3_product.py` で `assets/showcase/cooking/exp_burst_frame.png` へ決定的変換。sourceは文字・数値・UI・料理・魚なし、参照PNGは比較だけに使用し、本番へ直接importしていない。
- 原寸判断: `2026-07-18_c3_before_after_exp.png` で、現行PIL黄青ストライプ/ゲージ混在より、中央の金色放射光・青緑アクセント・粒子の祝祭性が明確に勝ち、`+38 EXP` の可読性を維持した。
- 320×180判断: `2026-07-18_c3_after_reference_320x180.png` で、参照03の中央から広がる暖色放射光・粒子方向との差が縮んだため採用。現行背景、見出し/ゲージ台座/料理画像、runtime演出、他4状態は採否対象外。
- 証拠: `docs/qa/evidence/cooking/2026-07-18_c3_after_exp.png`, `2026-07-18_c3_before_after_exp.png`, `2026-07-18_c3_after_reference.png`, `2026-07-18_c3_after_reference_320x180.png` と、実runtime previewで再撮影した `2026-07-18_c3_highrisk_exp_gain_{levelup,first_bonus,no_bonus,exp_cap,long_buff}.png`、`2026-07-18_c3_evidence.json`。他4状態はbefore/after decoded pixels一致をJSONへ記録し、高リスクmanifestは5状態ID・1280x720を検査する。
- 検査補強: `tools/cooking_c3_product.py --self-test` は隔離tmpでdecoded同値のbyte保持、真差分の書込、破損検出、保存失敗時の旧製品保持・temp cleanupを実証する。`cooking_visual_qa.sh` は通常5状態の回帰検査に加え、C3高リスク5状態の存在・サイズ・状態識別・fresh runtime同値を検査する。
- 再レビューP1補正: `tools/cooking_c3_evidence.py --update` を明示的な書込モード、`--check` を正式PNG/JSONを一切変更しないread-onlyモードとして分離。fresh captureと既存正式evidenceのdecoded一致、JSON一致、PNG/JSON破損拒否を検査し、previewは各高リスクfixtureのruntime state・title・EXP値・bonus表示・料理名・buff本文をnode/text/visibilityでassertしてmanifestへ観測値を記録する。
- 再レビューP1補正（可搬性）: 正式証拠の`file`/`after_evidence`はrepo-relative POSIX文字列へcanonicalizeし、`/tmp`のruntime source captureだけを絶対pathとして許可。`--self-test`はROOT絶対path混入拒否と別root間の期待JSON同値を検査する。
- 固定条件: `project.godot` は `b73d275c` のHEAD bytesへ復元済みで、C3製品/証拠commitへ含めない。旧一括generatorはC3製品をguardし、更新はC3専用processorだけで行う。`EXP_GAIN_LEVELUP` はoverlay受理前を高リスク証拠とし、LEVEL_UP後の別画面を変更しない。

2026-07-17: `C2-WIRE MEAL_RESULT食事シーン背景` を、Visual Wave V2の局所素材スライスとして開始し、同日完了。

- 差分Top1: 現行 `meal_scene_bg.png` は丸灯・床線・空皿を幾何描画した平坦な下地で、参照02の「木の食卓・暖色ランタン・港の夕景窓」が作る独立した食事payoffに届いていない。
- 動かすもの: C2 source/candidate、製品 `meal_scene_bg.png`、C2専用product processor、旧一括generator guard、production read-only checkと隔離破損self-test、C2 preview/visual QA fixture、C2証拠、素材台帳・ライセンス監査consumer分類。
- 不動値: COOK_SELECTとC1-A/C1-B、`player_eating_pose`、料理画像、`meal_result_scene_art_v2`、バナー・料理カード・報酬4枚・ステータス帯、全foreground geometry/文字座標、EXP_GAIN / LEVEL_UP_OVERLAY / STATUS_SUMMARY、料理/EXP/level-up/buff/saveロジック、common/palette/他画面。
- 代表状態: 初回bonusあり・報酬4枚・長いbuff文言のMEAL_RESULT。高リスク状態: 初回済み、長い料理名・効果文、MEAL_RESULT→EXP_GAIN、他4状態。
- 採用条件: 同一決定状態の原寸beforeに明確に勝ち、320×180 after/referenceで「食卓・ランタン・港の夕景窓」の差が縮む。背景より人物・料理・報酬が先に読め、safe-area文字干渉がなく、他4状態と進行ロジックが回帰しない。
- allowed-diff: MEAL_RESULTの背景画素だけ。人物・料理・カード・文字のgeometryは不変、他4状態は `2026-07-17_v2_prebaseline_*` とpixel完全一致を要求する。
- baseline: `2026-07-17_v2_prebaseline_{select,result,exp,levelup,status}.png`。同一worktreeの再撮影SHA-256が5枚すべてbaselineと一致することを仮配線前に確認済み。
- 判定: 採用。原寸では現行の幾何的な丸灯・床線・空皿が消え、人物/料理/報酬の背後が木造食堂として一貫した。320×180では参照02の暗い木部・食卓・暖色ランタンとの差が縮み、背景より人物・料理・報酬が先に読める。追加scrimは不要。
- 状態確認: 標準MEAL_RESULTは初回bonusあり・報酬4枚。C2専用captureで初回+長buff、初回済み+長料理名/長効果を原寸確認し、背景起因の文字衝突なし。`cooking_flow_smoke`でMEAL_RESULT→EXP_GAIN、`cooking_input_smoke`で状態handoffを確認。
- 回帰: `COOK_SELECT / EXP_GAIN / LEVEL_UP_OVERLAY / STATUS_SUMMARY` はV2 prebaselineとfile SHA-256・decoded pixelsが完全一致。`cooking_layout_audit`で人物・料理・カード・文字を含むMEAL_RESULT全foreground矩形を維持。
- 再現性: product processorを2回実行し2回目までfile/decoded hash不変・`preserved pixel-identical`。production `--check` はread-only、隔離copyのRGB/alpha 1channel破損をnonzero検出し、破損copyのSHA-256/mtimeを不変に保つ。旧一括generatorは採用製品を明示guard。
- 証拠: `2026-07-17_c2_full_before_after_reference.png`、`c2_thumbnail_before_after_reference.png`、`c2_after_result.png`、`c2_first_long.png`、`c2_repeat_long.png`、`c2_regression_{select,exp,levelup,status}.png`、`c2_report.json`。
- 固定条件: source/product/processorとMEAL_RESULT背景slotだけをC2正本としてfreezeする。C3以降で人物、料理、banner/cards/status、foreground geometry/text座標や他4状態へC2差分を波及させない。

2026-07-17: `COOK-C1B 料理カード紙面・タイトル帯` を、Visual Wave V1の局所素材スライスとして開始し、同日完了。

- 差分Top1: COOK_SELECT中央3×2カードは、白い平坦な紙面と太い茶枠が支配的で、参照01の羊皮紙・木/金の細枠・濃紺タイトル帯が作る authored な料理札の階層に届いていない。
- 動かすもの: 通常/選択カードの紙面・木/金細枠PNG、共通濃紺タイトル帯PNG、C1-B source/専用processor、カード素材の表示・状態契約、C1-B証拠、素材台帳。
- 不動値: C1-A背景、COOK_SELECTの3列、カード `132x196` と3×2配置、タイトル `31px`、皿画像、星、素材footer矩形、右詳細、下部4区画、`PlayerStatusBar`、他4状態、料理/EXP/level-up/buff/saveロジック、common/palette/他画面。
- 採用条件: 同一決定状態の原寸beforeに明確に勝ち、320×180 after/referenceでカード紙面・タイトル帯の差が縮む。normal / selected / locked / unavailable / hover / focus / 長い料理名 / hard初回・EXP上限 / 魚全種scrollにP1がなく、COOK_SELECT以外4状態は2026-07-17 V0 baselineから画素回帰しない。
- 再現性: 専用processorをclean相当で2回実行し、source/outputのfile hash・decoded RGBA pixelsが不変。同値時は既存PNG bytesを保持し、真の差だけ同一directory tempからatomic replaceする。
- 状態確認: normal/selectedは代表capture、locked/unavailable/長い `ヒラメのムニエル` はLv.1 capture、hover/focusは実入力captureで確認。hard初回・EXP上限はcontent audit、魚70種scrollはlayout audit、クリック/Tab/方向/focus復元はinput smokeでgreen。
- 回帰: MEAL_RESULT / STATUS_SUMMARYはV0 baselineとpixel完全一致。EXP_GAINはbbox `(356,132)-(771,391)`、LEVEL_UPは `(352,203)-(770,445)` にだけ差があり、半透明overlay背面の中央料理カード更新由来。overlay固有矩形・文字・導線の差はない。
- 証拠画像: `2026-07-17_c1b_after_select.png`, `c1b_full_before_after_reference.png`, `c1b_thumbnail_before_after_reference.png`, `c1b_locked_long.png`, `c1b_focus.png`, `c1b_hover_focus.png`, `c1b_regression_{result,exp,levelup,status}.png`。
- 判定: 原寸beforeの白い平坦面/太い茶枠より料理札として明確に読みやすく、320×180で参照の濃紺帯・羊皮紙・細い木金枠との差が縮んだため採用。P1/P2なし。
- 残P3: 参照の紙端汚れ、微細な木目、カードごとの料理別小紋、hoverの微細な光量差。C1-Bの再オープン理由にはせず、必要なら将来の一点物/演出スライスへ送る。
- 固定条件: source/output/processor、`132x196`、3×2、タイトル`31px`、皿/星/footer矩形をfreezeする。旧一括generatorは通常/選択slotをguardし、更新は専用processorだけで行う。次はC2 runtime採否へ進め、カード質感と食事背景を同じ仮説へ戻さない。

2026-07-16: `INPUT-COOKING` を、E11入力共通化の画面別スライスとして開始し、同日完了。

- 動かしたもの: `src/ui/cooking_screen.gd` のfocus候補・閉路・決定/戻る・動的再構築復元・5状態handoff、専用 `tools/cooking_input_smoke.*`、入力focus証拠、当QAログ。
- 不動値: §1の既存レイアウト/素材/文言、C1-A背景、C0のReward/LevelUp Button直下単一cue、`src/ui/components/*`、料理/EXP/レベル/バフ/セーブの進行値、他画面、common/palette/project.godot。
- 採用条件: 実 `InputEventKey` / `InputEventMouseButton` で、全有効候補到達、disabled/locked非到達、Tab/方向閉路、fish/recipe A→B→A focus復元、Enter/KP Enter一重処理、最後の魚1匹だけ消費、5状態handoff、不可逆報酬のEscape非skip、港遷移一重、mouse回帰がgreen。E11のCOOKING findingsが0であること。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-16_input_{select_normal_focus,select_locked_focus,select_empty_focus,select_last_fish_focus,meal_result_focus,exp_gain_focus,level_up_focus,status_summary_focus}.png`。全8枚を個別に原寸1280x720で確認し、focus可視、文字欠け/重なり/P1なし。入力表示以外の矩形・素材差はない。
- 検証: `cooking_input_smoke: ok`（production / deterministic）、`Cooking headless verification passed.`、`Cooking visual QA passed.`、`Save system verification passed.`、`validate_project.sh` exit 0。E11実測は `focusable=2 / reachable=2 / disabled_reached=0 / isolated=0 / missing_focus_style=0 / cancel=1 / accept_unobserved=0`（probeの空inventory fixture）でCOOKING findings 0。親統合後は新規smokeをrelease manifestへ登録し、46対象の集合一致と`e11_qa_harness_verify.sh` greenを再確認した。
- 固定条件: 入力改善で§1の構成freezeやC0 cueを動かさない。動的候補を追加する場合はsemantic identity、disabled除外、閉路、実イベントsmoke、代表/高リスク状態の原寸証拠を同時更新する。

2026-07-14: `旧調理一括generator決定性修正` を、UI Wave B横断P2として開始し、同日完了。

- 動かしたもの: `tools/generate_cooking_showcase_assets.py` の保存契約、focused verification、generator所有権記録、baseline manifest。
- 不動値: `assets/showcase/cooking/*.png` 全57点、accepted evidence画像、§1の既存freeze値、runtime UI、C2配線、新規アート、C1-B以降、common/palette/project.godot/他画面。
- 採用条件: Pillow 10.2 / 12.xの両方でclean baseline相当のgeneratorを2回実行し、全57製品のfile SHA-256 / decoded RGBA SHA-256 / size / modeが実行前と完全一致すること。保存契約の同値保持・atomic更新・例外rollback/cleanupをfocused testで確認すること。
- baseline証拠: `docs/qa/evidence/cooking/2026-07-14_generator_baseline_{before_manifest,after_manifest,diff_report}.json`。`bc596c56` の隔離snapshotで採取し、製品追加/削除なし、全57点size/mode不変。

2026-07-14: `C1-A COOK_SELECT厨房背景` を、docs/33 C1の1スロット素材フェーズとして開始し、同日完了。

- 差分Top1: COOK_SELECTの現行 `cooking_room_bg.png` は平面的な矩形・単色面が支配的で、参照01の暖色ランタン光、海の見える窓、調理棚が作る authored 厨房の空気に届いていない。
- 背景slotの実可視領域: 1280x720全面に敷かれるが、COOK_SELECTでは主にヘッダー/3列/下部stripの外周と12pxガター、中央列と右詳細の間の縦窓で見える。前景情報面の背後では減光・彩度統一を行い、背景の高周波を主役にしない。
- 動かすもの: `tools/source_assets/cooking/c1a_kitchen_bg_source.png`、`tools/process_cooking_c1a_assets.py`、既存製品slot `assets/showcase/cooking/cooking_room_bg.png`、発注brief、台帳、C1-A証拠。
- 不動値: COOK_SELECTの3列、カード/詳細/CTA矩形、`PlayerStatusBar`、下部strip、§1の全freeze値、料理/材料/EXP/バフ/レベルアップ/セーブロジック、MEAL_RESULT専用素材、C1-B〜C5、common/palette/project.godot、他画面。
- 採用条件: 同一決定状態の原寸beforeに明確に勝ち、320x180のafter/referenceでも「暖色ランタン光・海窓・調理棚」の差が縮むこと。COOK_SELECT以外は背面利用状態の背景差のみを許可し、専用不透明状態は意図しない差ゼロとする。
- baseline: `docs/qa/evidence/cooking/2026-07-14_c1a_before_{select,result,exp,levelup,status}.png`（5状態1280x720、2026-07-14固定）。

## 7. 判断ログ（直近パスのみ）

2026-07-17: `C2-WIRE` 完了。準備済みの食事シーン候補をMEAL_RESULT背景slotへ正式採用した。

- 採用製品: `assets/showcase/cooking/meal_scene_bg.png`。runtimeは既存slotを既に参照していたため、`src/ui/components/cooking_reward_panel.gd` は無変更。
- 比較: 原寸before/after/referenceと320×180 before/after/referenceを同一決定状態で確認。現行の平坦な丸灯・空皿・床線より明確に勝ち、参照02の木造食堂、食卓、暖色ランタン方向へ縮小距離が縮んだ。
- allowed-diff: MEAL_RESULT背景画素だけ。他4状態はfile SHA-256完全一致。人物・料理・報酬4枚・ステータス帯・文字・全foreground geometryはlayout/content auditで維持。
- 製品契約: 専用product processor、pixel-stable、同一画素bytes保持、差時same-dir atomic replace、production read-only `--check`、隔離RGB/alpha corruption self-test、旧generator guard、台帳/consumer分類を同期。U-08 pendingは維持。
- 検証: `cooking_visual_qa.sh`、`cooking_verify.sh`、`cooking_flow_smoke.tscn`、`cooking_input_smoke.tscn`、`save_system_verify.sh`、`validate_project.sh`、`git diff --check` green。save/validateのObjectDB/resource終了警告は既知契約。
- 未解決: C2内P1/P2なし。production catalogの最大値を超える合成stress fixtureでは副次的な小枠が既定ellipsisを使うが、主バナーと効果カードは読め、背景起因の干渉はない。通常データの収まり契約は既存content/layout auditでgreen。

2026-07-17: Visual Wave V2の共通起点 `e297692a` で、C2-WIRE着手前の調理5状態baselineを再固定。

- 実行: `./tools/cooking_visual_qa.sh` exit 0。`COOK_SELECT / MEAL_RESULT / EXP_GAIN / LEVEL_UP_OVERLAY / STATUS_SUMMARY` はすべて1280x720で、5枚のSHA-256は相互に異なる。
- 証拠: `docs/qa/evidence/cooking/2026-07-17_v2_prebaseline_{select,result,exp,levelup,status}.png`。
- 固定条件: C2-WIREのallowed-diffはMEAL_RESULT背景画素だけ。人物、料理、報酬4枚、文字、全foreground geometry、他4状態、料理・EXP・level-up・buff・saveロジックはこのbaselineから回帰させない。

2026-07-17: `COOK-C1B` 独立レビューのP2差し戻し2件を解消。素材・見た目・runtime表示は変更していない。

- P2-1: `validate_project.sh` が生成モード `--verify-twice` を呼び、製品PNG driftを先にatomic replaceして隠せる経路を廃止。専用processorへ純read-only `--check` を追加し、sourceからメモリ生成した期待RGBAと3製品の全channel decoded pixels/hashを照合する。欠損・読込不能・size/画素差はnonzeroで、書込みは明示した通常生成 / `--refresh-sources` / `--verify-twice` にだけ残した。
- P2-1回帰: 隔離temporary copyの1製品をRGB 1channelだけ破損し、`--check --output-dir <isolated>` がnonzeroとなり、破損copyのSHA-256/mtimeを不変に保つことを確認。`--check-self-test` はRGB差とalpha差の両方で同じ契約を自動検証し、`validate_project.sh` はproduction `--check` とこの隔離self-testを実行する。
- P2-2: `cooking_input_smoke.gd` から正式名 `2026-07-17_c1b_hover_focus.png` の保存を撤去。input smokeはhover tintのenter/exit assertだけを担い、正式hover captureは `cooking_preview.gd` → `/tmp/tsuri_cooking_c1b_hover_focus.png` → evidence builder/採用証拠の単一所有とした。`cooking_visual_qa_check.py` の黒・透明・低情報量拒否は維持。
- 検証: `--check` / 隔離破損CLI / `--check-self-test`、`./tools/cooking_visual_qa.sh`、`./tools/cooking_verify.sh`、`cooking_input_smoke.tscn`、content/layout/flow、`./tools/save_system_verify.sh`、`./tools/validate_project.sh`、`git diff --check` green。隔離破損CLIはexit 1、破損copyのSHA-256/mtime不変。全検証後も製品PNG・正式evidenceにtracked差分なし。
- 独立再レビュー: TIP `fe238610`でP0/P1/P2/P3すべて0件。親も原寸before/after、320×180 after/reference、locked/長文/hover/focusと他4状態回帰を確認し、C1-Bを採用・freezeした。
- 固定条件: C1-B 3製品/source、カード矩形、状態表現、正式evidence画素、調理進行・入力runtimeは不変。検証経路・証拠所有権以外へ範囲を広げない。

2026-07-17: `COOK-C1B` 完了。中央料理カードの紙面・細枠・タイトル帯だけをauthored PNGへ移行した。

- 採用: `recipe_card_frame.png`, `recipe_selected_card_frame.png`, 新規 `recipe_title_band.png`。日本語料理名、星、素材数、locked/unavailable文言はruntimeのまま。
- 比較: `2026-07-17_c1b_full_before_after_reference.png`（原寸）と `2026-07-17_c1b_thumbnail_before_after_reference.png`（320×180）。beforeに明確に勝ち、参照01の濃紺帯/羊皮紙/細枠との差が縮んだ。
- 状態/回帰: `c1b_locked_long`, `c1b_focus`, `c1b_hover_focus` と4状態回帰captureを確認。MEAL_RESULT / STATUS_SUMMARYはpixel同値、半透明のEXP_GAIN / LEVEL_UPは背面中央カードbbox内だけ意図差。
- 再現性: processor 2回で3出力のfile/decoded hash不変、2回目は全て `preserved pixel-identical`。旧一括generatorも58製品の隔離2回実行でproduction manifest不変。
- 固定条件: §1のC1-B行を正本とし、P1再発または承認済み方向更新なしに紙面/帯/枠へ戻らない。
- レビュー修正: input smoke経由の旧hover画像は表示環境によって黒欠損に見えるため正式根拠から除外し、`cooking_preview.gd` の実GUI・単一viewport経路で同名evidenceを再撮影した。1280×720原寸を再確認し、64×36 sampleでnear-black `0.087%` / transparent `0.000%`。visual QAは今後、hover/focus captureを必須にし、near-black 45%超または透明1%超をfailにする。

2026-07-17: INPUT統合後のV0 visual baselineを、V1 `COOK-C1B` 着手前状態として再固定。

- 実行: `./tools/cooking_visual_qa.sh`（5状態capture / strict check green）。
- 証拠: `docs/qa/evidence/cooking/2026-07-17_v1_prebaseline_{select,result,exp,levelup,status}.png`。全5枚1280x720、状態hashは相互に異なる。
- 固定条件: C1-BはCOOK_SELECT中央料理カードの紙面・細枠・タイトル帯だけを対象とし、C1-A背景、右詳細、下部4区画、`PlayerStatusBar`、他4状態と調理・成長・保存ロジックはこのbaselineから画素/挙動回帰させない。

2026-07-14: `旧調理一括generator決定性修正` 完了。採用済み製品PNG・runtime・freeze・accepted evidenceの意図的画素変更は0。

- 独立再計測: `bc596c56` の隔離snapshotをPython 3.12.3 / Pillow 12.0で実行すると57点中32点がdirty。byte-only 21点は `cook_action_runway_frame`, `cook_button_frame`, `cooking_section_ribbon`, `dish_detail_frame`, `fish_row_frame`, `flow_action_button_frame`, `level_stat_row_frame`, `level_unlock_ribbon`, `level_up_frame`, `meal_result_frame`, `meal_scene_bg`, `player_eating_pose`, `player_exp_message_pose`, `player_status_portrait`, `recipe_grid_frame`, `recipe_to_detail_arrow`, `reward_card_frame`, `status_clock_art`, `status_cooler_art`, `status_money_art`, `status_summary_bg`。decoded差11点は `cooking_icon_sheet`, `cooking_title_banner`, `dish_feature_aji_shioyaki`, `dish_icon_sheet`, `exp_stage_bg`, `fish_icon_sheet`, `level_unlock_medallion`, `level_unlock_spot`, `meal_banner_frame`, `meal_table_spread`, `next_effect_art`。
- 親観測との差: 既知の22 byte-only / 10 decoded差に対し、独立2計測はともに21/11。差分1点の `cooking_title_banner.png` は420x110中1px（channel absolute delta 248）だがdecoded RGBA SHAが異なるため、証拠上はdecoded差へ分類した。Pillow 10.2では13点dirty・全byte-only、Pillow 11.3では45点dirty・34/11で、PNG encoder・ImageDraw・filter/resize境界の版依存を確認した。
- 原因/採否: 旧 `save()` の無条件上書きがbyte差を作り、decoded差はPillow版による描画境界とLANCZOS差。`fish_icon_sheet` / `dish_feature_aji_shioyaki` / `meal_table_spread` はreference crop/二次派生、他の有機一点物・個別採用品も現行コミット済み製品を正本とし、専用processorへ移るまで明示guard。C1-A `cooking_room_bg.png` は既存どおり `process_cooking_c1a_assets.py` へ委譲する。
- 保存契約: candidateと既存PNGをsize/mode/decoded bytesで比較し、同値なら既存file bytesを保持。真の差・欠損・読込不能は同directoryのtempへPNG保存し、flush/fsync/chmod後に`os.replace`。例外時はfinallyでtempを削除し、replace前の旧製品を保持する。guard対象の欠損/読込不能は勝手にprocedural復旧せず明示失敗する。
- 必須gate: `tools/cooking_generator_determinism_verify.py` はproduction全57点を一時directoryへbyte copyし、そのcopyだけを `generator.OUT` にして2回実行する。同値bytes保持、size/mode/画素の真差atomic更新、欠損/読込不能復旧、replace例外時のtemp cleanup/旧output保持、guard、productionのfile/decoded hash・size/mode不変を検証し、`tools/validate_project.sh` から毎回実行する。
- 固定条件: generator保守で製品画素を更新する場合は、対象slotの所有契約・現行採用証拠・専用processorを先に確定する。単なるPillow候補差を採用品更新理由にしない。

2026-07-14: `C1-A COOK_SELECT厨房背景` 完了。既存の純PIL背景をOpenAI生成source + 決定的processorへ移行した。

- 選定理由: beforeは平面的な茶壁/矩形窓で、狭い可視ガターでも厨房の空気が読めなかった。afterは中央列と右詳細の間に海・灯台・港が明確に現れ、上端/外周には木棚・瓶・ランタン光が残る。320x180でも参照01との「海窓と暖色厨房」の差が縮み、beforeに明確に勝つため採用。
- 変えたもの: `c1a_kitchen_bg_source.png`、決定的processor、既存 `cooking_room_bg.png`、旧全素材generatorによる背景上書き防止、素材台帳/監査登録、C1-A証拠。
- 変えていないもの: COOK_SELECTの3列、カード/詳細/CTA矩形、`PlayerStatusBar`、下部strip、§1の既存freeze値、料理/材料/EXP/バフ/レベルアップ/セーブロジック、MEAL_RESULT専用素材、C1-B〜C5、common/palette/project.godot、他画面。既存slot表示済みのため `cooking_screen.gd` は無変更。
- 証拠画像: 原寸 `2026-07-14_c1a_full_before_after_reference.png`、縮小 `2026-07-14_c1a_thumbnail_after_reference.png`、gray `2026-07-14_c1a_gray_before_after_reference.png`、5状態 `2026-07-14_c1a_{before,after}_{select,result,exp,levelup,status}.png`。
- 5状態判定: COOK_SELECTは背景差のみ。背面を透かすEXP_GAIN / LEVEL_UP_OVERLAYも新背景由来の差だけ。専用不透明のMEAL_RESULTはbefore/after SHA-256 `c1af9079...44ed` で一致、STATUS_SUMMARYは `2b0ff0f8...fc92` で一致。5状態ともP1ゼロ。
- 再現性: source SHA-256 `b3e7d525...686cb`、output `67157172...81106`。processorを2回再実行し、hash・decoded RGBA pixelsとも不変。`generate_cooking_showcase_assets.py` もC1-A source存在時はこのslotを上書きしない。
- 独立レビュー: 結論を伏せた原寸証拠+diffレビューは `PASS_WITH_P3`。P1/P2なし。P3は「実画面では海窓が強く、ランタン本体は前景UIにほぼ隠れるため、暖色感は主に環境光として伝わる」。採用条件を満たし、再調整理由にはしない。
- 固定条件: source/output/processor値をfreezeし、P1再発またはユーザー承認済みの方向更新なしに背景を再調整しない。次はC1-Bへ進め、背景とカード質感を同じ仮説に混ぜない。

2026-07-11: `C0 runtime表示破綻` のレビュー差し戻しを反映。見た目の回帰は許容せず、C0契約をGUIキャプチャからheadless監査へ移した。

- 再オープン理由: `cooking_verify.sh` がGUI/表示サーバ必須の `cooking_visual_qa.sh` を呼び、CI・SSH・強制headlessでC0検証が完走できなかった。加えて導線余白が `>=88px` の共通検査で、Reward `88px` とLevelUp `92px` のfreeze差を識別できず、複数glyph復活も構造上検知できなかった。
- 変えたもの: `cooking_verify.sh` を純headless（content/layout/input/flow）へ分離し、`cooking_content_audit.gd` にMEAL_RESULT下地の状態別可視性・不透明性、Reward `88px` / LevelUp `92px` の個別余白、各Button直下の命名済み単一cue（子ノードなし・glyph数1・状態ID）の契約を追加。`cooking_preview.gd` はGUI visual QA専用の補助契約として同じ値を確認する。実装側は旧Button直描画を `RewardConfirmCue` / `LevelUpConfirmCue` の単一Controlへ置換した。
- 変えていないもの: §1の既存freeze値、調理/EXP/レベルアップ進行ロジック、カード矩形・見出し文字サイズ、料理/魚データ、既存素材、COOK_SELECT、C1〜C5。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-11_c0_contract_before_{select,result,exp,levelup,status}.png` と `docs/qa/evidence/cooking/2026-07-11_c0_contract_after_{select,result,exp,levelup,status}.png`。同一の決定的5状態で比較し、COOK_SELECT / STATUS_SUMMARYはpixel同値、MEAL_RESULT / EXP_GAIN / LEVEL_UP_OVERLAYは導線cueの単一Label glyph化だけが差分で、残像・タイトル帯・金額formatのC0解消状態を維持した。
- 判定: GUI表示を必要とするvisual QAをheadlessスモークから完全に切り離しても、C0構造契約はheadless content auditで失われない。RewardとLevelUpの余白を誤って共通化した場合、またはButtonへ2個目のcue/glyphノードを足した場合は監査が失敗する。
- 検証: `./tools/cooking_verify.sh` green（強制`--headless`、visual QA非呼出）、`./tools/cooking_visual_qa.sh` green（実GUI 5状態キャプチャ）、`./tools/validate_project.sh` と `git diff --check` green。`validate_project.sh` のObjectDB / resource終了ログは既知ベースライン警告。
- 固定条件: visual QAは `./tools/cooking_visual_qa.sh` として独立維持する。`cooking_verify.sh` へSubViewport/表示サーバ依存を戻さず、Reward `88px`、LevelUp `92px`、各Button直下の命名済み単一cue構造を変更しない。

2026-07-10: `C0 runtime表示破綻` 完了。docs/45 UI-C0-01の4件を、素材や既存freezeを動かさずに解消した。

- 再オープン理由: `2026-07-07_uplift_plan_gap_sheet.png` の実スクショで、MEAL_RESULTに前状態残像、STATUS_SUMMARYにタイトル帯衝突、EXP_GAIN / LEVEL_UP_OVERLAYに下部導線グリフ潰れを再確認。所持金の `%d G` もdocs/19 §4.3違反だったため、P1再発としてC0だけを開いた。
- 変えたもの: MEAL_RESULT時だけ表示する`RewardStageBase` の不透明下地、MEAL_RESULT scene artのalpha `1.0`、5カードの静かなruntime見出し帯、EXP_GAIN / LEVEL_UPの単一矢印グリフと本文余白、STATUS_SUMMARY金額format、決定的プレビューのC0表示契約、旧金額表記を持つcontent audit契約。
- 変えていないもの: §1の既存freeze値、調理/EXP/レベルアップの進行ロジック、カード矩形・見出し文字サイズ、料理/魚データ、既存素材、COOK_SELECT、C1〜C5。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-10_c0_before_{select,result,exp,levelup,status}.png` と `docs/qa/evidence/cooking/2026-07-10_c0_after_{select,result,exp,levelup,status}.png`。同一の決定的状態で比較し、MEAL_RESULTは下地が一貫して不透明、STATUS_SUMMARYは5見出しが文字横断なし、EXP_GAIN / LEVEL_UPは導線グリフと本文が分離、所持金は `10,170 G` を確認した。
- 判定: beforeにあった4件のP1がafterで再現せず、参照02〜05の「独立した食事シーン・静かな見出し帯・単一で読める下部導線・金額の階層」へ局所的に近づいた。素材密度などC1〜C5のP2課題は再オープンしていない。
- 検証: `./tools/cooking_visual_qa.sh` green、`./tools/cooking_verify.sh` green（content / layout / input / flow / C0 5状態表示契約）、`./tools/validate_project.sh` green。ObjectDB / resource終了ログは既知ベースライン警告。
- 固定条件: 今後この4状態を触るときは、MEAL_RESULT限定の`RewardStageBase`不透明性、EXP_GAIN / LEVEL_UPでの下地非表示、カード見出しの文字非横断、導線本文の左余白、金額カンマ区切りを表示契約として維持する。素材密度の改善はC1〜C5で扱う。

2026-07-05: `LEVEL_UP reward hierarchy pass` 完了。残P2として、レベルアップ報酬の主導線を通常パネルより強い構成へ上げた。

- 選定理由: P1 / EXP_GAIN / STATUS_SUMMARY / COOK_SELECT完了後の残P2が `LEVEL_UP_OVERLAY` の祝祭感だったため。上部祝祭帯の微調整は既に3回完了していたので、素材の小調整ではなくダイアログ全体の報酬階層を組み替えた。
- 変えたもの: `LevelUpDialog` を大型化し、`LevelUpTitleBand` を金縁の報酬プレートに変更。`LEVEL UP!` を64pt extra bold、Lv遷移を42pt extra boldに拡大し、ステータス行とLv.5解放カードを下段へ再配分。layout auditのLEVEL_UP最小サイズ契約を新構成に更新。
- 変えていないもの: 調理/EXP/レベルアップ進行ロジック、P1短縮文言、EXP_GAIN中央主役構成、STATUS_SUMMARYプレイヤーhero、COOK_SELECT右詳細、MEAL_RESULTタブ位置、魚/料理データ、他画面素材、日本語PNG焼き込み。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_levelup_reward_hierarchy_ref_current.png`, `docs/qa/evidence/cooking/2026-07-05_levelup_reward_hierarchy_focus.png`, `docs/qa/evidence/cooking/2026-07-05_levelup_reward_hierarchy_levelup.png`, `docs/qa/evidence/cooking/2026-07-05_levelup_reward_hierarchy_report.html`
- 判定: afterでは縮小表示でも `LEVEL UP!` と `Lv.4 -> Lv.5` が先に読め、ステータス上昇と「新たな釣り場が解放！」が続く。参照の立体金文字/紙吹雪密度には未達だが、レベルアップ報酬のP2構成改善としては完了。残差はP3の一点物素材/演出密度へ送る。
- 検証: `./tools/cooking_visual_qa.sh` green。`./tools/cooking_verify.sh` green（content/layout/input/flow）。`./tools/validate_project.sh` green。`validate_project.sh` のObjectDB/resource警告はベースライン既知。
- 固定条件: LEVEL_UPを再調整する場合は、`LevelUpTitleBand` / `LevelUpTitle` / `LevelUpLevelLine` の主導線を通常パネルより強く維持する。残る金文字立体感や紙吹雪密度は小さなStyleBox調整ではなく、一点物素材または演出フェーズで扱う。

2026-07-05: `COOK_SELECT detail hierarchy pass` 完了。P2 Top3として、右詳細パネルの料理名と大皿の主導線を強化した。

- 選定理由: `EXP_GAIN` / `STATUS_SUMMARY` 構成改善後の残P2で、`COOK_SELECT` 右詳細パネル上部の料理名が実スクショで主役として読めず、参照の「料理名 -> 大皿 -> 材料/EXP/効果 -> 調理する」階層より弱かったため。
- 変えたもの: 右詳細上部を `SelectedDishTitlePlate` に組み替え、料理名 `SelectedDishTitle` をextra bold・31pt・省略禁止・名前付き監査対象にした。説明 `SelectedDishSubtitle` を同じ帯に収め、料理画像/調理導線の高さを微調整。content/layout auditへタイトル帯・料理名・説明の表示契約を追加。
- 変えていないもの: 調理/EXP/レベルアップ進行ロジック、EXP_GAIN中央主役構成、STATUS_SUMMARYプレイヤーhero、LEVEL_UP解放説明、MEAL_RESULTタブ位置、魚/料理データ、他画面素材、日本語PNG焼き込み。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_cook_select_detail_ref_current.png`, `docs/qa/evidence/cooking/2026-07-05_cook_select_detail_focus.png`, `docs/qa/evidence/cooking/2026-07-05_cook_select_detail_select.png`, `docs/qa/evidence/cooking/2026-07-05_cook_select_detail_report.html`
- 判定: afterでは右詳細上部の「アジの塩焼き」が縮小表示でも最初に読め、料理画像、材料/EXP/効果、調理ボタンへ視線が落ちる。参照ほどの行フレーム一体感は未達だが、右詳細の階層改善としては完了。
- 検証: `./tools/cooking_visual_qa.sh` green。`./tools/cooking_verify.sh` green（content/layout/input/flow）。`./tools/validate_project.sh` green。`validate_project.sh` のObjectDB/resource警告はベースライン既知。
- 固定条件: COOK_SELECTで再調整する場合は、`SelectedDishTitlePlate` / `SelectedDishTitle` の主役性と省略禁止を守る。残る行フレーム密度差は小調整ではなく素材/構成フェーズへ送る。

2026-07-05: `STATUS_SUMMARY independent screen pass` 完了。P2 Top2として、ステータス要約を独立した確認画面に寄せた。

- 選定理由: `EXP_GAIN` 構成改善後の優先順位で、残るP2のうち `STATUS_SUMMARY` のプレイヤーカード/ステータス名/カード主値の弱さが最上位だったため。既存の背景/カード密度は微調整上限済みなので、枠線調整ではなく構成改善として扱った。
- 変えたもの: ヘッダーsubtitleを単行固定で表示。プレイヤーカード上部を `StatusPlayerHero` に組み替え、人物・Lv・次LvまでのEXP・ゲージを一体化。5ステータス行を `StatusStatRow*` 小カード化し、アイコンだけでなく名前と数値を読めるようにした。料理/クーラー/所持金/プレイ時間カードの主要アート高さを少し増やし、主値との階層を揃えた。対応してcontent/layout audit契約を更新。
- 変えていないもの: 調理/EXP/レベルアップ進行ロジック、EXP_GAIN P1短縮文言、EXP_GAIN中央主役構成、LEVEL_UP解放説明、MEAL_RESULTタブ位置、COOK_SELECT右詳細、料理/魚/背景/祝祭一点物素材、日本語PNG焼き込み。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_status_summary_independent_ref_current.png`, `docs/qa/evidence/cooking/2026-07-05_status_summary_independent_focus.png`, `docs/qa/evidence/cooking/2026-07-05_status_summary_independent_status.png`, `docs/qa/evidence/cooking/2026-07-05_status_summary_independent_report.html`
- 判定: afterではヘッダーの「調理の成果を確認できます」、プレイヤーの人物/Lv/次EXP、5ステータス名と値が縮小表示でも読める。5カードの主値とアートの高さも揃い、参照のステータス確認画面に近づいた。参照ほどの一点物人物/カードアート密度は未達だが、構成改善としては完了。
- 検証: `./tools/cooking_visual_qa.sh` green。`./tools/cooking_verify.sh` green（content/layout/input/flow）。`./tools/validate_project.sh` green。`validate_project.sh` のObjectDB/resource警告はベースライン既知。
- 固定条件: STATUS_SUMMARYで再調整する場合は、`StatusPlayerHero` とステータス5行の名前/数値読みをP1条件として守る。残る参照差分は小調整ではなく一点物人物/カードアート素材フェーズへ送る。

2026-07-05: `EXP_GAIN central hierarchy pass` 完了。P2 Top1として、EXP獲得状態の中央報酬ビートを主役化した。

- 選定理由: P1ゼロ化後の優先順位で、参照との差分が最も大きい `EXP_GAIN` から着手するため。微調整カウンタは既に上限超過済みのため、runtime装飾追加ではなく構成整理として扱った。
- 変えたもの: ステップ行を非表示化し、左右カードを圧縮。`ExpGainBanner` を高くし、中央 `ExpBurstFrame`、`+EXP`、EXPゲージを拡大。主要単行ラベルは横展開・省略禁止・前面化で実スクショの文字消失を防止。右効果カードは「次の釣行で効果！」を見出しに集約し、本文を `安全域 +10%` のような短縮表示へ変更。
- 変えていないもの: 調理/EXP/レベルアップ進行ロジック、P1短縮文言、LEVEL_UP解放説明、STATUSヘッダーEXP幅、MEAL_RESULTタブ位置、COOK_SELECT右詳細、STATUS_SUMMARYカード構成、料理/魚/背景/祝祭一点物素材、日本語PNG焼き込み。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_exp_gain_central_hierarchy_ref_current.png`, `docs/qa/evidence/cooking/2026-07-05_exp_gain_central_hierarchy_focus.png`, `docs/qa/evidence/cooking/2026-07-05_exp_gain_central_hierarchy_exp.png`, `docs/qa/evidence/cooking/2026-07-05_exp_gain_central_hierarchy_report.html`
- 判定: afterでは「食経験値を獲得！」「+38 EXP」「EXP 127 / 285 -> 165 / 285」が左右カードより先に読め、ステップ行の進行UI感が消えた。参照ほどの一点物祝祭密度は未達だが、構成改善としては完了。残差は素材/祝祭設計フェーズへ送る。
- 検証: `./tools/cooking_visual_qa.sh` green。`./tools/cooking_verify.sh` green（content/layout/input/flow）。`./tools/validate_project.sh` green。`validate_project.sh` のObjectDB/resource警告はベースライン既知。
- 固定条件: EXP_GAINで再調整する場合は、ステップ行を戻さない。タイトル/`+EXP`/EXPゲージの可読性をP1条件として先に守り、右効果本文は短縮表示を基本とする。

2026-07-05: `P1 readable-state repair` 完了。reference-uplift後のP1候補4点を、構成/素材フェーズへ進む前に解消した。

- 選定理由: `docs/19` と調理専用スキルの順序どおり、P2改善より先に見切れ・省略・重なり・読めないゲージをゼロにするため。
- 変えたもの: `EXP_GAIN` の左説明と中央メッセージを短縮し省略表示を解消。`LEVEL_UP_OVERLAY` の解放説明を短縮し全文表示へ変更。`STATUS_SUMMARY` のヘッダーEXPボックス/ゲージ/数値幅を拡張し、数値を読めるようにした。`MEAL_RESULT` の「食べる」タブを左寄せし、結果バナー本文との重なりを解消。対応して `tools/cooking_layout_audit.gd` / `tools/cooking_content_audit.gd` の新しい表示契約も更新。
- 変えていないもの: 調理/EXP/レベルアップ進行ロジック、P2 Top3の優先順位、料理/魚/背景/祝祭一点物素材、日本語PNG焼き込み、Palette定数、COOK_SELECT右詳細パネル。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_p1_fix_result.png`, `docs/qa/evidence/cooking/2026-07-05_p1_fix_exp.png`, `docs/qa/evidence/cooking/2026-07-05_p1_fix_levelup.png`, `docs/qa/evidence/cooking/2026-07-05_p1_fix_status.png`, `docs/qa/evidence/cooking/2026-07-05_p1_fix_focus_crops.png`, `docs/qa/evidence/cooking/2026-07-05_p1_fix_report.html`
- 判定: フォーカス拡大でP1対象の省略記号・重なり・空ゲージ見えが消えた。`EXP_GAIN` / `STATUS_SUMMARY` / `COOK_SELECT` のP2差分は残るが、P1修正スライスとしては完了。
- 検証: `./tools/cooking_visual_qa.sh` green。`./tools/cooking_verify.sh` green（content/layout/input/flow）。`./tools/validate_project.sh` green。`validate_project.sh` のObjectDB/resource警告はベースライン既知。
- 固定条件: 次フェーズはP2 Top1の `EXP_GAIN` 構成改善から扱う。今回短縮したP1文言やヘッダーEXP幅をP2作業で戻す場合は、実スクショで省略/空ゲージが再発しないことを先に確認する。

2026-07-05: `reference-uplift gap audit` 完了。最新の5状態visual QAを再生成し、完成イメージとの差分をP1/P2/P3で棚卸しした。

- 選定理由: ユーザー指定により、調理場画面の次ブラッシュアップ前に完成イメージと現状の差分を整理するため。
- 変えたもの: 実装・freeze値・素材は変更なし。`docs/qa/cooking_qa.md` の状態表記と現在の残ギャップを、最新スクショ基準のP1候補/P2 Top3へ更新した。
- 変えていないもの: §1 freeze値、調理/EXP/レベルアップ進行ロジック、レイアウト値、素材、表示文言、日本語PNG焼き込み、Palette定数。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_gap_audit_reference_current_sheet.png`, `docs/qa/evidence/cooking/2026-07-05_gap_audit_reference_report.html`
- 判定: `./tools/cooking_visual_qa.sh` はgreenだが、実スクショ目視で `EXP_GAIN` / `LEVEL_UP_OVERLAY` の省略表示、`STATUS_SUMMARY` のEXPゲージ可読性、`MEAL_RESULT` のラベル重なりをP1候補として分離した。P2は参照距離が大きい順に `EXP_GAIN`、`STATUS_SUMMARY`、`COOK_SELECT` とする。
- 検証: `./tools/cooking_visual_qa.sh` green。今回は差分整理のみのため、validate/smokeは未実行。
- 固定条件: 次フェーズではP1候補を先に確認・解消する。P2へ進む場合はTop1の `EXP_GAIN` から扱い、微調整済み領域へruntime装飾を足すだけのパスにしない。

2026-07-05: `RF1 complete reward visuals/status palette pass` 完了。調理報酬Visual群とSTATUS_SUMMARYのactive runtime色をPalette用途名へ移行し、RF1を閉じた。

- 選定理由: RF1-C後の最後の調理コンポーネント残件が `cooking_reward_visuals.gd` 179件と `cooking_status_panel.gd` 114件に集約され、調理5状態のvisual QAで表示同値退行を確認できるため。
- 変えたもの: `cooking_reward_visuals.gd` の人物/食卓/料理/湯気/グロー/報酬アイコン/値プレート/効果プレビュー色を `Palette.COOKING_REWARD_VISUAL_*` へ、`cooking_status_panel.gd` の背景/5カード/小アイコン/ヘッダー/フッター/注記色を `Palette.COOKING_STATUS_*` へ移行。
- 変えていないもの: §1 freeze値、調理/EXP/レベルアップ進行ロジック、レイアウト値、素材、表示文言、日本語PNG焼き込み、R5 reference-uplift済み構成。
- Palette: 新規 `Palette.COOKING_REWARD_VISUAL_*` / `Palette.COOKING_STATUS_*` を追加。理由は調理報酬VisualとSTATUS_SUMMARY固有の色責務を、表示同値のままPalette正本へ移すため。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_rf1_complete_palette_select.png`, `docs/qa/evidence/cooking/2026-07-05_rf1_complete_palette_result.png`, `docs/qa/evidence/cooking/2026-07-05_rf1_complete_palette_exp.png`, `docs/qa/evidence/cooking/2026-07-05_rf1_complete_palette_levelup.png`, `docs/qa/evidence/cooking/2026-07-05_rf1_complete_palette_status.png`, `docs/qa/evidence/cooking/2026-07-05_rf1_complete_palette_report.html`
- 判定: RF1対象7ファイルのraw color監査は0件。実スクショ5状態とcontent/layout/input/flow検証でP1なし。これは参照upliftではなくR1表示同値移行なので、cmp一致は完了条件にしていない。
- 検証: `./tools/cooking_visual_qa.sh`、`./tools/cooking_verify.sh`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`save_system_verify.sh` のJSON警告と `validate_project.sh` のObjectDB/resource警告はベースライン既知。
- 固定条件: 調理報酬Visualの色は `COOKING_REWARD_VISUAL_*`、STATUS_SUMMARYの色は `COOKING_STATUS_*` として扱い、今後の調理コンポーネント編集でraw colorを戻さない。

2026-07-05: `RF1-C level-up panel palette pass` 完了。レベルアップoverlayのactive runtime色をPalette用途名へ移行した。

- 選定理由: RF1-B後の残件から `level_up_panel.gd` は単独で87件を閉じられ、LEVEL_UP_OVERLAY状態を含む調理5状態のvisual QAで表示同値退行を確認できるため。
- 変えたもの: 王冠/ラウレル、メダル/リボン、釣り場サムネ、ステータスバッジ、解放カード、導線ミニカード、ディム/文字影のruntime色を `Palette.COOKING_LEVEL_*` へ移行。
- 変えていないもの: §1 freeze値、調理/EXP/レベルアップ進行ロジック、レイアウト値、素材、表示文言、日本語PNG焼き込み、R5 reference-uplift済み構成。
- Palette: 新規 `Palette.COOKING_LEVEL_*` を追加。理由はレベルアップoverlay固有の祝祭/解放/ステータス色責務を、表示同値のままPalette正本へ移すため。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_rf1c_level_up_palette_select.png`, `docs/qa/evidence/cooking/2026-07-05_rf1c_level_up_palette_result.png`, `docs/qa/evidence/cooking/2026-07-05_rf1c_level_up_palette_exp.png`, `docs/qa/evidence/cooking/2026-07-05_rf1c_level_up_palette_levelup.png`, `docs/qa/evidence/cooking/2026-07-05_rf1c_level_up_palette_status.png`, `docs/qa/evidence/cooking/2026-07-05_rf1c_level_up_palette_report.html`
- 判定: `src/ui/components/level_up_panel.gd` のraw color監査は0件。実スクショ5状態とcontent/layout/input/flow検証でP1なし。これは参照upliftではなくR1表示同値移行なので、cmp一致は完了条件にしていない。
- 検証: `./tools/cooking_visual_qa.sh`、`./tools/cooking_verify.sh`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`save_system_verify.sh` のJSON警告と `validate_project.sh` のObjectDB/resource警告はベースライン既知。
- 固定条件: レベルアップoverlayのruntime色は `COOKING_LEVEL_*` 系として扱い、次スライスは `cooking_status_panel.gd` / `cooking_reward_visuals.gd` のどちらかを単独で進める。

2026-07-05: `RF1-B reward panel palette pass` 完了。調理報酬オーバーレイ本体のactive runtime色をPalette用途名へ移行した。

- 選定理由: RF1-A後の残件から `cooking_reward_panel.gd` は単独で70件を閉じられ、MEAL_RESULT / EXP_GAIN / STATUS_SUMMARYの報酬オーバーレイ表示同値をvisual QAで検証できるため。
- 変えたもの: 報酬オーバーレイの暗幕、シーンカード、バナー/料理カード/EXPフレームfallback、フローステップ、OKボタン導線アイコン、EXP/効果プレビューカードのruntime色を `Palette.COOKING_REWARD_*` へ移行。
- 変えていないもの: §1 freeze値、調理/EXP/レベルアップ進行ロジック、レイアウト値、素材、表示文言、日本語PNG焼き込み、R5 reference-uplift済み構成。
- Palette: 新規 `Palette.COOKING_REWARD_OVERLAY_DIM` / `SCENE_CARD_FILL` / `DIALOG_FILL` / `PARCHMENT_FILL` / `FLOW_*` / `BUTTON_*` / `EFFECT_*` などを追加。理由は報酬オーバーレイ本体の色責務を、表示同値のままPalette正本へ移すため。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_rf1b_reward_panel_palette_select.png`, `docs/qa/evidence/cooking/2026-07-05_rf1b_reward_panel_palette_result.png`, `docs/qa/evidence/cooking/2026-07-05_rf1b_reward_panel_palette_exp.png`, `docs/qa/evidence/cooking/2026-07-05_rf1b_reward_panel_palette_levelup.png`, `docs/qa/evidence/cooking/2026-07-05_rf1b_reward_panel_palette_status.png`, `docs/qa/evidence/cooking/2026-07-05_rf1b_reward_panel_palette_report.html`
- 判定: `src/ui/components/cooking_reward_panel.gd` のraw color監査は0件。実スクショ5状態とcontent/layout/input/flow検証でP1なし。これは参照upliftではなくR1表示同値移行なので、cmp一致は完了条件にしていない。
- 検証: `./tools/cooking_visual_qa.sh`、`./tools/cooking_verify.sh`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`save_system_verify.sh` のJSON警告と `validate_project.sh` のObjectDB/resource警告はベースライン既知。
- 固定条件: 調理報酬オーバーレイ本体の色は `COOKING_REWARD_*` 系として扱い、次スライスは `level_up_panel.gd` / `cooking_status_panel.gd` / `cooking_reward_visuals.gd` のどれかを単独で進める。

2026-07-05: `RF1-A reward cards palette pass` 完了。調理報酬カード群と下部ステータスストリップのactive runtime色をPalette用途名へ移行した。

- 選定理由: 当時の全体リファクタ棚卸しでR1が未完条件として残り、RF1のうち `cooking_assets.gd` / `cooking_reward_status_strip.gd` / `cooking_reward_cards.gd` は独立して小さく切れるため。
- 変えたもの: `CookingAssets.apply_flow_button_style` のfallback button色、報酬カード/報酬グリッド/下部ステータスストリップの枠・発光・アクセント・modulate色を `Palette.COOKING_FLOW_BUTTON_*` / `Palette.COOKING_REWARD_*` へ移行。
- 変えていないもの: §1 freeze値、調理/EXP/レベルアップ進行ロジック、レイアウト値、素材、表示文言、日本語PNG焼き込み、R5 reference-uplift済み構成。
- Palette: 新規 `Palette.COOKING_FLOW_BUTTON_*` / `Palette.COOKING_REWARD_*` を追加。理由はRF1調理報酬系コンポーネントの色責務を、表示同値のままPalette正本へ移すため。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_rf1a_reward_palette_select.png`, `docs/qa/evidence/cooking/2026-07-05_rf1a_reward_palette_result.png`, `docs/qa/evidence/cooking/2026-07-05_rf1a_reward_palette_exp.png`, `docs/qa/evidence/cooking/2026-07-05_rf1a_reward_palette_levelup.png`, `docs/qa/evidence/cooking/2026-07-05_rf1a_reward_palette_status.png`, `docs/qa/evidence/cooking/2026-07-05_rf1a_reward_palette_report.html`
- 判定: 対象3ファイルのraw color監査は0件。実スクショ5状態とcontent/layout/input/flow検証でP1なし。これは参照upliftではなくR1表示同値移行なので、cmp一致は完了条件にしていない。
- 検証: `./tools/cooking_visual_qa.sh`、`./tools/cooking_verify.sh`、`cooking_content_audit.tscn`、`cooking_layout_audit.tscn`、`cooking_flow_smoke.tscn` green。
- 固定条件: 調理報酬カードと報酬ステータスストリップの色は `COOKING_REWARD_*` 系として扱い、次スライスは `cooking_reward_panel.gd` / `level_up_panel.gd` / `cooking_status_panel.gd` / `cooking_reward_visuals.gd` のどれかを単独で進める。

2026-07-05: `STATUS_SUMMARY reference-uplift` 完了。`reference/cooking_flow/05_status_summary_concept.png` へ向けて、5カードの独立画面感と主値の読みを強めた。

- 選定理由: LEVEL_UP_OVERLAY完了後、ユーザー指定の優先順で次がSTATUS_SUMMARYだったため。before比較では5カード構成はあるが、背景が下のCOOK_SELECTに透け、カードの主値と表面密度が参照より弱かった。
- 変えたもの: `status_card_frame.png` 候補を生成し、カード表面に紙目/帯を追加。STATUS_SUMMARY背景の下に不透明ベースを敷き、下のCOOK_SELECT透けを解消。5カードの主値をruntime値プレート化し、クーラー/所持金/プレイ時間の読みを強化。visual QA保存は `RenderingServer.force_draw` で同期し、状態別キャプチャの安定性を補強。プレビュー種のクーラー値は参照判断用に `19 / 20` へ調整。
- 変えていないもの: §1 freeze値、調理/EXP/レベルアップ進行ロジック、COOK_SELECT、MEAL_RESULT、EXP_GAIN、LEVEL_UP_OVERLAY、ステータス計算ロジック、セーブ仕様、R1残件、日本語PNG焼き込み。
- 素材候補: `status_card_frame.png` 候補を採用。ただし半透明描画が既存紙面を置換して下画面が透けた版は不採用。合成方式に直した不透明紙面版を採用した。
- 微調整カウンタ: `STATUS_SUMMARY カード密度/背景` 3回。3回目で値プレートと背景抜けは改善したが、半透明カードは素材品質問題と判断し、素材生成を修正して採用した。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_status_summary_before_after_ref.png`, `docs/qa/evidence/cooking/2026-07-05_status_summary_focus.png`, `docs/qa/evidence/cooking/2026-07-05_status_summary_status.png`, `docs/qa/evidence/cooking/2026-07-05_status_summary_report.html`
- 判定: afterでは背景の港/厨房帯が見え、5カードの絵+主値+説明の読みがbeforeより明確になった。参照ほどカードアートの密度やプレイヤーカードの大きな人物絵には未到達だが、独立したステータス要約画面へ前進したと第三者に判別できる。cmp一致は判定に使っていない。
- 検証: `./tools/cooking_visual_qa.sh`、`cooking_layout_audit.tscn`、`cooking_content_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`save_system_verify.sh` のJSON警告と `validate_project.sh` のObjectDB/resource警告はベースライン既知。
- 固定条件: STATUS_SUMMARYは下のCOOK_SELECTを透かさず、5カードの主値を値プレートで表示する。次のR5対象は台帳で改めて選定する。

2026-07-05: `LEVEL_UP_OVERLAY reference-uplift` 完了。`reference/cooking_flow/04_level_up_overlay_concept.png` へ向けて、上部祝祭帯の存在感を強めた。

- 選定理由: EXP_GAIN完了後、ユーザー指定の優先順で次がLEVEL_UP_OVERLAYだったため。before比較では情報契約は揃っているが、参照のcrown/laurel/金色祝祭感に比べ、上部報酬ビートが弱かった。
- 変えたもの: `tools/generate_cooking_showcase_assets.py` の `level_crown_asset()` / `level_laurel_asset()` から `level_crown.png` / `level_laurel_left.png` / `level_laurel_right.png` 候補を生成し、crown/laurelの輝きとサイズを強化。`LevelUpPanel` のダイアログ幅/高さ、title band、crown/laurel表示サイズを調整。
- 変えていないもの: §1 freeze値、調理/EXP/レベルアップ進行ロジック、COOK_SELECT、MEAL_RESULT、EXP_GAIN、STATUS_SUMMARY、ステータス値、解放文言、日本語PNG焼き込み、R1残件。
- 素材候補: `level_crown.png` / `level_laurel_*.png` 候補を採用。runtime `LEVEL UP!` 文字拡大とLv行拡大は実スクショ/監査で表示契約が落ちたため不採用。最終候補は参照ほどの巨大タイトルには届かないが、beforeよりcrown/laurelが読みやすく、祝祭overlayとして前進したと判断。
- 微調整カウンタ: `LEVEL_UP_OVERLAY 上部祝祭帯` 3回。3回目で表示契約を維持する構成へ戻し、残る巨大タイトル差分は次回以降の構造/素材フェーズへ送る。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_levelup_before_after_ref.png`, `docs/qa/evidence/cooking/2026-07-05_levelup_title_focus.png`, `docs/qa/evidence/cooking/2026-07-05_levelup_levelup.png`, `docs/qa/evidence/cooking/2026-07-05_levelup_report.html`
- 判定: afterでは上部crown/laurelとダイアログの存在感が増し、報酬overlayの第一印象がbeforeより強い。参照の巨大 `LEVEL UP!` / 大きなLv遷移には未到達だが、祝祭方向へ前進したと第三者に判別できる。cmp一致は判定に使っていない。
- 検証: `./tools/cooking_visual_qa.sh`、`cooking_layout_audit.tscn`、`cooking_content_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`save_system_verify.sh` のJSON警告と `validate_project.sh` のObjectDB/resource警告はベースライン既知。
- 固定条件: LEVEL_UP_OVERLAYの `成長の証` / `LEVEL UP!` / Lv遷移行はcontent audit契約上visibleを維持し、祝祭感はcrown/laurel素材と上部帯で強める。次スライスはSTATUS_SUMMARYへ進める。

2026-07-05: `EXP_GAIN reference-uplift` 完了。`reference/cooking_flow/03_exp_gain_concept.png` へ向けて、中央EXP演出を主役に寄せた。

- 選定理由: MEAL_RESULT完了後、ユーザー指定の優先順で次がEXP_GAINだったため。before比較では上部ステップ行と旧EXPフレームが強く、参照の巨大 `+EXP` / 中央ゲージの報酬ビートより進行UI感が勝っていた。
- 変えたもの: `tools/generate_cooking_showcase_assets.py` の `exp_burst_frame()` から `assets/showcase/cooking/exp_burst_frame.png` 候補を生成し、中央フレームの光量・ゲージ台座・粒子を強化。EXP_GAIN時のステップ行はcontent audit契約上visibleのまま、alpha 0.18で背景側へ退かせた。
- 変えていないもの: §1 freeze値、調理/EXP/レベルアップ進行ロジック、COOK_SELECT、MEAL_RESULT、LEVEL_UP_OVERLAY、STATUS_SUMMARY、R1残件、日本語PNG焼き込み。
- 素材候補: `exp_burst_frame.png` 候補を採用。透明外枠化と見出し拡大は `+EXP` / 見出しの可読性が落ちたため不採用。最終候補は、参照ほどの巨大タイトルには届かないが、beforeより中央ゲージの発光と専用EXP状態の読みが強いと判断。
- 微調整カウンタ: `EXP_GAIN 中央演出/ステップ行` 4回。3回目で表示契約を満たす改善に戻し、4回目の見出し拡大は不採用として戻した。追加の数px調整は行わず、残る巨大タイトル差分は次回以降の構造/素材フェーズへ送る。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_exp_gain_before_after_ref.png`, `docs/qa/evidence/cooking/2026-07-05_exp_gain_focus.png`, `docs/qa/evidence/cooking/2026-07-05_exp_gain_exp.png`, `docs/qa/evidence/cooking/2026-07-05_exp_gain_report.html`
- 判定: afterでは上部ステップ行が主導線から退き、中央EXPカードの光とゲージ台座が強くなった。参照の巨大 `+60 EXP` ほどの迫力は残課題だが、EXP獲得専用状態へ前進したと第三者に判別できる。cmp一致は判定に使っていない。
- 検証: `./tools/cooking_visual_qa.sh`、`cooking_layout_audit.tscn`、`cooking_content_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`save_system_verify.sh` のJSON警告と `validate_project.sh` のObjectDB/resource警告はベースライン既知。
- 固定条件: EXP_GAINのステップ行はcontent audit契約上visibleを維持するが、主役は中央EXP演出とする。次スライスはLEVEL_UP_OVERLAYへ進める。

2026-07-05: `MEAL_RESULT reference-uplift` 完了。`reference/cooking_flow/02_meal_result_concept.png` へ向けて、食事結果がフォームではなくpayoff状態に見えるように調整した。

- 選定理由: COOK_SELECT仕上げ点検後、ユーザー指定の優先順で残り4状態の先頭がMEAL_RESULTだったため。before比較では外側の暗い巨大フレームが強く、食事シーン背景よりフォーム感が勝っていた。
- 変えたもの: `tools/generate_cooking_showcase_assets.py` の `meal_dish_card_frame()` から `assets/showcase/cooking/meal_dish_card_frame.png` 候補を生成し、料理カードの料理画像窓を広げた。MEAL_RESULT時のみ `CookingRewardPanel` の外枠を透明寄りにし、EXP_GAINでは従来報酬フレームへ戻す。料理画像/料理名の配分をMEAL_RESULT専用に調整。
- 変えていないもの: §1 freeze値、COOK_SELECT、EXP_GAINの表示契約、LEVEL_UP_OVERLAY、STATUS_SUMMARY、調理/EXP/レベルアップ進行ロジック、魚/料理データ、セーブ仕様、日本語PNG焼き込み、R1残件。
- 素材候補: `meal_dish_card_frame.png` 候補を採用。1回目は画像窓を広げすぎて料理名領域が狭くなったため採用せず、2回目で画像幅/文字サイズと外枠透明化を合わせて全画面のpayoff感がbeforeに明確に勝つと判断。
- 微調整カウンタ: `MEAL_RESULT 料理カード/外枠構成` 2回。3回未満で改善したため追加の素材再生成には進まない。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_meal_result_before_after_ref.png`, `docs/qa/evidence/cooking/2026-07-05_meal_result_dish_card_focus.png`, `docs/qa/evidence/cooking/2026-07-05_meal_result_result.png`, `docs/qa/evidence/cooking/2026-07-05_meal_result_report.html`
- 判定: afterでは大きな暗色モーダルの印象が弱まり、食事シーン背景の上にバナー、料理カード、報酬カード、ステータスカードが載る読みになった。参照ほどの背景全面化や報酬値の迫力は残課題だが、食事結果のpayoff状態へ前進したと第三者に判別できる。cmp一致は判定に使っていない。
- 検証: `./tools/cooking_visual_qa.sh`、`cooking_layout_audit.tscn`、`cooking_content_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`save_system_verify.sh` のJSON警告と `validate_project.sh` のObjectDB/resource警告はベースライン既知。
- 固定条件: MEAL_RESULTは暗い巨大外枠を主役に戻さず、食事シーン背景上のpayoffカード群として扱う。次スライスはEXP_GAINへ進める。

2026-07-05: `COOK_SELECT finish precision pass` 完了。最新COOK_SELECTスクショと `reference/cooking_flow/01_cook_select_concept.png` の横並びで、指定3点を点検した。

- 選定理由: R1色移行を一旦停止し、残り4状態reference-upliftへ進む前に、COOK_SELECTの料理カードタイトル帯、右詳細3行、下部4区画の仕上げ精度を確認するため。
- 変えたもの: 料理カードタイトルを共通 `_recipe_card_title_slot` で生成し、アウトラインなし太字・帯内下寄せ・左右余白付きに変更。実カードとプレビューカードで同じ処理に統一。
- 変えていないもの: §1 freeze値、料理カード枠素材、皿画像、星ランク、素材フッター、右詳細行素材、下部4区画、背景、調理/EXP/レベルアップ進行ロジック、日本語PNG焼き込み。
- 微調整カウンタ: `COOK_SELECT 料理カードタイトル帯` 1回。1回目で改善が見えたため素材再生成には進まない。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_select_precision_before_after_ref.png`, `docs/qa/evidence/cooking/2026-07-05_select_precision_title_crop.png`, `docs/qa/evidence/cooking/2026-07-05_select_precision_select.png`, `docs/qa/evidence/cooking/2026-07-05_select_precision_report.html`
- 判定: beforeではタイトル文字が白アウトラインでにじみ、上枠ノッチと干渉して読みにくかった。afterでは濃色太字がタイトル帯内に収まり、参照のカード見出しに近づいた。右詳細3行の `12 / 1`、`初回 +20 EXP`、`1回` は値プレート内に収まり、下部4区画も見切れなし。cmp一致は判定に使っていない。
- 検証: `./tools/cooking_visual_qa.sh`、`cooking_layout_audit.tscn`、`cooking_content_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`save_system_verify.sh` のJSON警告と `validate_project.sh` のObjectDB/resource警告はベースライン既知。
- 固定条件: COOK_SELECT料理カードタイトルはruntime描画のまま、アウトラインなし太字・帯内下寄せを現行基準とする。次スライスはMEAL_RESULTへ進める。

2026-07-05: `shared GaugeBar palette R1 pass` 完了。調理フローで使う共有ゲージの描画色をPalette用途名へ移行した。

- 選定理由: `GaugeBar` は調理報酬/調理ステータス/ステータス画面で共有されるが、既定色と描画色に直書き `Color(...)` が残っており、R1残件として小さく切れるため。
- 変えたもの: `src/ui/components/gauge_bar.gd` の既定グラデーション、トラック、影、ゴースト、ハイライト、ダメージ点滅、危険域グロー、数値文字色。`src/ui/palette.gd` へ `Palette.GAUGE_*` 定数を追加。
- 変えていないもの: §1 freeze値、調理場レイアウト、料理カード、下部バー、右詳細パネル、報酬カード、ゲージの値/補間/決定的QAガード、日本語PNG焼き込み。
- Palette: 新規 `Palette.GAUGE_TRACK` / `GAUGE_TRACK_BORDER` / `GAUGE_SHADOW_CLEAR` / `GAUGE_SHADOW` / `GAUGE_GHOST` / `GAUGE_HIGHLIGHT` / `GAUGE_DAMAGE_FLASH` / `GAUGE_CRITICAL_GLOW` / `GAUGE_VALUE_OUTLINE` / `GAUGE_VALUE_TEXT` を追加。理由は共有ゲージの描画色責務をPaletteへ集約するため。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_gauge_bar_palette_select.png`, `docs/qa/evidence/cooking/2026-07-05_gauge_bar_palette_report.html`
- 判定: 実スクショでCOOK_SELECTの下部バー/右詳細パネル、および調理フロー5状態にP1なし。これは参照upliftではなくR1表示同値移行なので、cmp一致は完了条件にしていない。
- 検証: `./tools/cooking_visual_qa.sh` は透明キャプチャで1回失敗後、同一差分で再実行してgreen。`tools/cooking_content_audit.tscn`、`tools/cooking_layout_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`validate_project.sh` の ObjectDB/resource 警告はベースライン既知。
- 固定条件: 共有ゲージの描画色は `Palette.GAUGE_*` として扱い、`src/ui/components/gauge_bar.gd` へ新規 `Color(...)` を戻さない。

2026-07-05: `cooking_screen final palette R1 pass` 完了。背景fallbackと料理カードtintの残色をPalette用途名へ移行し、`src/ui/cooking_screen.gd` の `Color(` 直書きをゼロにした。

- 選定理由: 未使用detail helper削除後も背景fallbackと料理カード/素材/皿画像tintに `Color(...)` の直書きが残っており、調理場画面全体のR1完了を阻んでいたため。
- 変えたもの: 背景fallback top/bottom、料理カードlocked/unavailable/preview modulate、料理素材アイコンmuted modulate、皿画像muted modulate。
- 変えていないもの: §1 freeze値、レイアウト値、素材、表示文言、COOK_SELECT構成、調理報酬オーバーレイ、日本語PNG焼き込み。
- Palette: 新規 `Palette.COOKING_BG_FALLBACK_*` / `Palette.COOKING_RECIPE_*_MODULATE` を追加。理由は調理場画面スクリプト内の最後の直書き色を、表示同値のままPalette正本へ移すため。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_background_fallback_palette_select.png`, `docs/qa/evidence/cooking/2026-07-05_background_fallback_palette_report.html`
- 判定: `rg -n "Color\\(" src/ui/cooking_screen.gd` 該当ゼロ。実スクショでCOOK_SELECT料理カード、背景、右詳細パネルにP1なし。これは参照upliftではなくR1表示同値移行なので、cmp一致は完了条件にしていない。
- 検証: `./tools/cooking_visual_qa.sh`、`tools/cooking_content_audit.tscn`、`tools/cooking_layout_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`validate_project.sh` の ObjectDB/resource 警告はベースライン既知。
- 固定条件: 調理場画面のruntime色は `Palette.COOKING_*` 系で扱い、次回以降 `src/ui/cooking_screen.gd` へ新規 `Color(...)` を戻さない。

2026-07-05: `unused detail helper cleanup` 完了。右詳細旧helperを削除し、未使用コード由来の直書き色を消した。

- 選定理由: `_add_detail_tile` / `_add_detail_pair_tile` / `_add_detail_pair_cell` は参照uplift後の実表示から呼び出されておらず、旧構成の直書き色だけを残していたため。
- 変えたもの: 上記3関数を削除。現行右詳細行で使う `_add_detail_story_row` は維持。
- 変えていないもの: §1 freeze値、レイアウト値、素材、表示文言、右詳細パネル構成、COOK_SELECT下部4区画、料理カード、調理報酬オーバーレイ、日本語PNG焼き込み。
- Palette: 新規定数なし。未使用コード削除による直書き色解消。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_unused_detail_helper_cleanup_select.png`, `docs/qa/evidence/cooking/2026-07-05_unused_detail_helper_cleanup_report.html`
- 判定: 実スクショと5状態visual QAでP1なし。これはUI upliftではなく未使用コード削除なので、cmp一致は完了条件にしていない。
- 検証: `./tools/cooking_visual_qa.sh`、`tools/cooking_content_audit.tscn`、`tools/cooking_layout_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`validate_project.sh` の ObjectDB/resource 警告はベースライン既知。
- 固定条件: 右詳細行は `_add_detail_story_row` と `Palette.COOKING_DETAIL_*` を現行経路とする。

2026-07-05: `cooking summary card palette R1 pass` 完了。調理場の結果サマリーカード周辺のactive runtime色をPalette用途名へ追加移行した。

- 選定理由: 食事結果/ステータス要約で使う `_summary_card` と結果タイトルに直書き色が残っており、COOK_SELECT後続状態のカード質感改善時に色責務が追いづらかったため。
- 変えたもの: 結果タイトルの影/アウトライン色、サマリーカードのfill/border/inner、カードタイトル文字色、値アウトライン色。
- 変えていないもの: §1 freeze値、レイアウト値、素材、表示文言、COOK_SELECT下部4区画、右詳細パネル、料理カード、調理報酬オーバーレイ、日本語PNG焼き込み。
- Palette: 新規 `Palette.COOKING_SUMMARY_CARD_*` / `Palette.COOKING_RESULT_TITLE_OUTLINE` を追加。理由は結果サマリーのカード色を、表示同値のままPalette正本へ移すため。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_summary_card_palette_result.png`, `docs/qa/evidence/cooking/2026-07-05_summary_card_palette_status.png`, `docs/qa/evidence/cooking/2026-07-05_summary_card_palette_report.html`
- 判定: 実スクショで食事結果/ステータス要約のカードと文字にP1なし。これは参照upliftではなくR1表示同値移行なので、cmp一致は完了条件にしていない。
- 検証: `./tools/cooking_visual_qa.sh`、`tools/cooking_content_audit.tscn`、`tools/cooking_layout_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`validate_project.sh` の ObjectDB/resource 警告はベースライン既知。
- 固定条件: 結果サマリーカードは `COOKING_SUMMARY_CARD_*`、結果タイトルアウトラインは `COOKING_RESULT_TITLE_OUTLINE` として扱う。

2026-07-05: `COOK_SELECT section ribbon palette R1 pass` 完了。参照uplift済みCOOK_SELECT見出しリボンのactive runtime fallback色をPalette用途名へ追加移行した。

- 選定理由: 左魚リストと中央料理リストの主要見出しリボンに、fallback frameの直書き色が残っており、次回のリボン素材/質感改善時に色責務が追いづらかったため。
- 変えたもの: `FishSectionRibbon` / `RecipeSectionRibbon` のfallback fill/border色。
- 変えていないもの: §1 freeze値、レイアウト値、素材、表示文言、リボン上のアイコン/文字色、魚リスト、料理カード、右詳細パネル、下部バー、背景、調理報酬オーバーレイ、日本語PNG焼き込み。
- Palette: 新規 `Palette.COOKING_SECTION_RIBBON_*` を追加。理由はCOOK_SELECTの主要見出し帯fallback色を、表示同値のままPalette正本へ移すため。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_section_ribbon_palette_select.png`, `docs/qa/evidence/cooking/2026-07-05_section_ribbon_palette_report.html`
- 判定: 実スクショでCOOK_SELECT左/中央の見出しリボンにP1なし。これは参照upliftではなくR1表示同値移行なので、cmp一致は完了条件にしていない。
- 検証: `./tools/cooking_visual_qa.sh`、`tools/cooking_content_audit.tscn`、`tools/cooking_layout_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`validate_project.sh` の ObjectDB/resource 警告はベースライン既知。
- 固定条件: COOK_SELECTの主要見出し帯fallback色は `COOKING_SECTION_RIBBON_*` として扱い、見出し文字/アイコン色は別スライスで扱う。

2026-07-05: `COOK_SELECT small icon palette R1 pass` 完了。参照uplift済みCOOK_SELECTのruntime小アイコン/アクションキュー色をPalette用途名へ追加移行した。

- 選定理由: 下部4区画、右詳細行、調理導線で使う `CookingSmallIcon` / `CookActionCueVisual` に多数の直書き色が残っており、次回のアイコン質感改善時に色責務が追いづらかったため。
- 変えたもの: プレイヤー/料理/魚/コイン/クーラー/本/EXP/効果/炎のruntime小アイコン色、調理ボタンへ向かうキュー線/皿面のactive/disabled色。
- 変えていないもの: §1 freeze値、レイアウト値、素材、表示文言、各ボタンstyle、魚リスト、料理カード、右詳細パネル構成、下部バー構成、背景、調理報酬オーバーレイ、日本語PNG焼き込み。
- Palette: 新規 `Palette.COOKING_SMALL_ICON_*` / `Palette.COOKING_ACTION_CUE_*` を追加。理由はCOOK_SELECTの小さなruntime装飾色を、表示同値のままPalette正本へ移すため。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_small_icon_palette_select.png`, `docs/qa/evidence/cooking/2026-07-05_small_icon_palette_report.html`
- 判定: 実スクショでCOOK_SELECT下部バー、右詳細行、調理導線の小アイコンにP1なし。これは参照upliftではなくR1表示同値移行なので、cmp一致は完了条件にしていない。
- 検証: `./tools/cooking_visual_qa.sh`、`tools/cooking_content_audit.tscn`、`tools/cooking_layout_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`validate_project.sh` の ObjectDB/resource 警告はベースライン既知。
- 固定条件: 小アイコン群は `COOKING_SMALL_ICON_*`、調理導線キューは `COOKING_ACTION_CUE_*` として扱い、ボタン本体の `COOKING_ACTION_*` とは分けて管理する。

2026-07-05: `COOK_SELECT recipe book button palette R1 pass` 完了。参照uplift済みCOOK_SELECT料理図鑑ボタンのactive runtime色をPalette用途名へ追加移行した。

- 選定理由: 中央料理グリッド外枠と調理ボタンのR1移行後も、副導線である「料理図鑑を見る」ボタンに枠normal/hover/pressedと文字状態の直書き色が残っており、次回の料理グリッド改善時に安全に触りづらかったため。
- 変えたもの: 料理図鑑ボタンのnormal/hover/pressed fallback色、hover/pressed文字色。
- 変えていないもの: §1 freeze値、レイアウト値、素材、表示文言、調理ボタン、左魚リスト、料理カード、右詳細パネル、下部バー、背景、調理報酬オーバーレイ、日本語PNG焼き込み。
- Palette: 新規 `Palette.COOKING_RECIPE_BOOK_BUTTON_*` を追加。理由は中央列の副導線ボタン色を、表示同値のままPalette正本へ移すため。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_recipe_book_button_palette_select.png`, `docs/qa/evidence/cooking/2026-07-05_recipe_book_button_palette_report.html`
- 判定: 実スクショでCOOK_SELECTの料理図鑑ボタン、ボタン文字、中央料理グリッドにP1なし。これは参照upliftではなくR1表示同値移行なので、cmp一致は完了条件にしていない。
- 検証: `./tools/cooking_visual_qa.sh`、`tools/cooking_content_audit.tscn`、`tools/cooking_layout_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`validate_project.sh` の ObjectDB/resource 警告はベースライン既知。
- 固定条件: 料理図鑑ボタンは `COOKING_RECIPE_BOOK_BUTTON_*` 系で扱い、調理実行ボタンの `COOKING_ACTION_*` とは分けて管理する。

2026-07-05: `COOK_SELECT cook button palette R1 pass` 完了。参照uplift済みCOOK_SELECT調理ボタンのactive runtime色をPalette用途名へ追加移行した。

- 選定理由: COOK_SELECTの主導線である調理ボタンに、枠4状態・文字状態・runtime鍋アイコン色の直書きが残っており、次回のボタン質感改善時に安全に触りづらかったため。
- 変えたもの: 調理ボタンのnormal/hover/pressed/disabled fallback色、hover/pressed/disabled文字色、runtime鍋アイコンのactive/disabled色。
- 変えていないもの: §1 freeze値、レイアウト値、素材、表示文言、料理図鑑ボタン、左魚リスト、料理カード、右詳細パネル、下部バー、背景、調理報酬オーバーレイ、日本語PNG焼き込み。
- Palette: 新規 `Palette.COOKING_ACTION_BUTTON_*` / `COOKING_ACTION_ICON_*` を追加。理由は調理ボタンとruntime鍋アイコン色を、表示同値のままPalette正本へ移すため。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_cook_button_palette_select.png`, `docs/qa/evidence/cooking/2026-07-05_cook_button_palette_report.html`
- 判定: 実スクショでCOOK_SELECTの調理ボタン、ボタン文字、鍋アイコンにP1なし。これは参照upliftではなくR1表示同値移行なので、cmp一致は完了条件にしていない。
- 検証: `./tools/cooking_visual_qa.sh`、`tools/cooking_content_audit.tscn`、`tools/cooking_layout_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`validate_project.sh` の ObjectDB/resource 警告はベースライン既知。
- 固定条件: COOK_SELECTの調理実行導線は `COOKING_ACTION_*` 系で扱い、料理図鑑ボタンは別スライスで扱う。

2026-07-05: `COOK_SELECT recipe grid palette R1 pass` 完了。参照uplift済みCOOK_SELECT中央料理グリッド外枠のactive runtime色をPalette用途名へ追加移行した。

- 選定理由: 料理カード本体は `Palette.COOKING_RECIPE_*` へ移行済みだったが、中央列の `RECIPE_GRID_FRAME` fallback色が直書きで残っており、次回の料理グリッド改善時に枠とカードの色責務が分かれにくかったため。
- 変えたもの: 中央料理グリッド外枠のfallback panel色。
- 変えていないもの: §1 freeze値、レイアウト値、素材、表示文言、料理カード内部、左魚リスト、右詳細パネル、下部バー、背景、調理報酬オーバーレイ、日本語PNG焼き込み。
- Palette: 新規 `Palette.COOKING_RECIPE_GRID_FILL` / `COOKING_RECIPE_GRID_BORDER` / `COOKING_RECIPE_GRID_INNER` を追加。理由は中央料理グリッド外枠色を、表示同値のままPalette正本へ移すため。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_recipe_grid_palette_select.png`, `docs/qa/evidence/cooking/2026-07-05_recipe_grid_palette_report.html`
- 判定: 実スクショでCOOK_SELECT中央料理グリッド、料理カード、料理図鑑ボタンにP1なし。これは参照upliftではなくR1表示同値移行なので、cmp一致は完了条件にしていない。
- 検証: `./tools/cooking_visual_qa.sh`、`tools/cooking_content_audit.tscn`、`tools/cooking_layout_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`validate_project.sh` の ObjectDB/resource 警告はベースライン既知。
- 固定条件: 料理カード内部と中央料理グリッド外枠は `COOKING_RECIPE_*` 系で扱い、次の調理場直接編集でも一括置換はしない。

2026-07-05: `COOK_SELECT fish list palette R1 pass` 完了。参照uplift済みCOOK_SELECT左魚リストのactive runtime色をPalette用途名へ追加移行した。

- 選定理由: 右詳細パネルR1移行後も、COOK_SELECT左列の魚リストにパネル枠・魚行・選択状態・所有/未所持tintの直書き色が残っており、次回の魚行改善時に再利用しづらかったため。
- 変えたもの: 左魚リストのパネル色、魚アイコン所有/未所持tint、魚名/所持数テキスト色、魚行の選択/所有/未所持フレーム色。
- 変えていないもの: §1 freeze値、レイアウト値、素材、表示文言、料理カード、右詳細パネル、下部バー、背景、調理報酬オーバーレイ、日本語PNG焼き込み。
- Palette: 新規 `Palette.COOKING_FISH_PANEL_*` / `COOKING_FISH_ICON_*` / `COOKING_FISH_NAME_*` / `COOKING_FISH_AMOUNT_*` / `COOKING_FISH_ROW_*` を追加。理由は左魚リストのactive runtime色を、表示同値のままPalette正本へ移すため。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_fish_list_palette_select.png`, `docs/qa/evidence/cooking/2026-07-05_fish_list_palette_report.html`
- 判定: 実スクショでCOOK_SELECT左魚リスト、魚名、所持数、未所持行、選択行にP1なし。これは参照upliftではなくR1表示同値移行なので、cmp一致は完了条件にしていない。
- 検証: `./tools/cooking_visual_qa.sh`、`tools/cooking_content_audit.tscn`、`tools/cooking_layout_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`validate_project.sh` の ObjectDB/resource 警告はベースライン既知。
- 固定条件: 次の調理場直接編集でも一括置換はせず、触るactive部品ごとにPalette移行を続ける。

2026-07-05: `COOK_SELECT detail palette R1 pass` 完了。参照uplift済み右詳細パネルのactive runtime色をPalette用途名へ追加移行した。

- 選定理由: COOK_SELECT 4スライス完了後の次作業として、台帳で調理場R1継続が最優先になっており、右詳細パネル内に前回触ったactive runtime色の直書きが残っていたため。
- 変えたもの: 右詳細パネルのfallback panel色、料理タイトル/サブタイトル、皿枠、必要素材/EXPアクセント、アクション帯、上書き注意バッジの色参照。
- 変えていないもの: §1 freeze値、レイアウト値、素材、表示文言、料理カード、下部バー、背景、調理報酬オーバーレイ、日本語PNG焼き込み。
- Palette: 新規 `Palette.COOKING_DETAIL_PANEL_*` / `COOKING_DETAIL_TITLE_*` / `COOKING_DETAIL_SUBTITLE_TEXT` / `COOKING_DETAIL_DISH_FRAME_*` / `COOKING_DETAIL_ACTION_FILL` / `COOKING_DETAIL_NOTE_*` / `COOKING_DETAIL_MATERIAL_ACCENT` / `COOKING_DETAIL_EXP_ACCENT` を追加。理由は右詳細パネルのactive runtime色を、表示同値のままPalette正本へ移すため。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_detail_palette_select.png`, `docs/qa/evidence/cooking/2026-07-05_detail_palette_report.html`
- 判定: 実スクショでCOOK_SELECTの右詳細パネル、料理タイトル、3行詳細、アクション帯にP1なし。これは参照upliftではなくR1表示同値移行なので、cmp一致は完了条件にしていない。
- 検証: `./tools/cooking_visual_qa.sh`、`tools/cooking_content_audit.tscn`、`tools/cooking_layout_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`validate_project.sh` の ObjectDB/resource 警告はベースライン既知。
- 固定条件: 次の調理場直接編集でも一括置換はせず、触るactive部品ごとにPalette移行を続ける。

2026-07-05: `COOK_SELECT background reveal reference-uplift` 完了。COOK_SELECT本体の余白/パネル間隔/glazeを調整し、厨房背景の見え方を参照へ寄せた。

- 選定理由: 右詳細パネル完了後のafterでもパネル群が横幅をほぼ覆い、参照のような左右パネル間/外周の厨房背景と暖色奥行きが弱かったため。
- 変えたもの: COOK_SELECT本体の左右8px余白、パネル間隔12px、厨房背景glazeの色/透明度、背景glazeのPalette定数。
- 変えていないもの: §1 freeze値、料理カード、魚リスト内容、下部バー、右詳細行、ヘッダー `PlayerStatusBar`、調理報酬オーバーレイ、日本語PNG焼き込み。
- 素材候補: 新規背景素材は採用していない。既存 `CookingAssets.COOKING_BG` を使い、暗いglazeとパネル間隔が背景を殺していたため、素材差し替えではなく見せ方の調整で前進した。
- Palette: 新規 `Palette.COOKING_BG_GLAZE` を追加。理由は今回触った背景glaze色をPalette正本へ移すため。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_background_before_after_ref.png`, `docs/qa/evidence/cooking/2026-07-05_background_select.png`, `docs/qa/evidence/cooking/2026-07-05_background_report.html`
- 判定: afterではパネル外周とパネル間に厨房背景が見え、青黒い暗幕感が弱まった。参照ほど背景面積は大きくないが、freeze値に触れずに奥行きの前進が判別できる。cmp一致は判定に使っていない。
- 検証: `./tools/cooking_visual_qa.sh`、`tools/cooking_content_audit.tscn`、`tools/cooking_layout_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`validate_project.sh` の ObjectDB/resource 警告はベースライン既知。
- 固定条件: COOK_SELECT本体は左右8px余白/パネル間隔12pxを現行の参照寄せ基準とする。COOK_SELECT 4スライス（料理カード/下部バー/右詳細パネル/背景）は完了。

2026-07-05: `COOK_SELECT detail panel reference-uplift` 完了。右詳細パネルの3行を帯/アイコン/右端バッジ構成へ寄せ、詳細行素材候補を採用した。

- 選定理由: 下部バー完了後のafterでも「次の釣行で得られる効果」行の `1回` が右端に浮いて見え、必要素材行/獲得EXP行も参照の帯・アイコン質感に届いていなかったため。
- 変えたもの: `cook_detail_row_frame.png`、右詳細パネルの必要素材/獲得EXP/次の釣行効果行、右端補足値のバッジ化、行タイトルへのruntime小アイコン追加、効果行見出しの短縮、右詳細行周辺のPalette定数、`tools/cooking_content_audit.gd` の表示契約。
- 変えていないもの: §1 freeze値、料理カード、魚リスト、下部バー、背景/左右余白、ヘッダー `PlayerStatusBar`、調理報酬オーバーレイ、日本語PNG焼き込み。
- 素材候補: `tools/generate_cooking_showcase_assets.py` で詳細行フレーム候補を生成し採用。候補は左のタイトル/アイコン帯、中央値、右バッジポケットを持ち、beforeより参照の情報帯構成へ近づいたため。
- Palette: 新規 `Palette.COOKING_DETAIL_*` を追加。理由は右詳細行/バッジ/値のruntime色を、今回触った行から用途名定数へ移すため。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_detail_panel_before_after_ref.png`, `docs/qa/evidence/cooking/2026-07-05_detail_panel_select.png`, `docs/qa/evidence/cooking/2026-07-05_detail_panel_report.html`
- 判定: `1回` は右端バッジ内に整理され、必要素材/EXP/効果の各行にアイコン帯が入った。効果行の長い見出しは見切れ回避のため `次の釣行効果` に短縮し、実スクショで見切れなしを確認した。cmp一致は判定に使っていない。
- 検証: `./tools/cooking_visual_qa.sh`、`tools/cooking_content_audit.tscn`、`tools/cooking_layout_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`cooking_visual_qa.sh` は途中で透明キャプチャが1回発生したが、同一差分で再実行してgreen。`validate_project.sh` の ObjectDB/resource 警告はベースライン既知。
- 固定条件: 右詳細行の補足値（材料数、初回EXP、効果回数）は行内バッジとして扱う。次スライスは背景の見せ方に進める。

2026-07-05: `COOK_SELECT prep bar reference-uplift` 完了。下部バーを参照の4区画構成へ寄せ、下部バー素材候補を採用した。

- 選定理由: 料理カード完了後のafterでも下部は「現在の準備 / 効果中の料理 / クーラーボックス / 詳細」に留まり、参照の「プレイヤーLv / 効果中の料理 / クーラーボックス / 所持金」4区画の装飾フレーム構成へ未到達だったため。
- 変えたもの: 下部バー枠2枚（バー/カード）、COOK_SELECT下部4区画、COOK_SELECTではタイトルスロット/詳細ボタンを非表示にする状態制御、下部バー周辺のPalette定数、`tools/cooking_content_audit.gd` / `tools/cooking_layout_audit.gd` のCOOK_SELECT契約。
- 変えていないもの: §1 freeze値、料理カード、魚リスト、右詳細パネル、背景/左右余白、ヘッダー `PlayerStatusBar`、調理報酬オーバーレイ、日本語PNG焼き込み。
- 素材候補: `tools/generate_cooking_showcase_assets.py` で4区画トレイと下部カード枠候補を生成し採用。候補は4つの情報スロットと縦セパレータが読め、beforeより参照の下部バー構成へ近づいたため。
- 判断更新: 以前の「下部準備バーへLv/所持金カードを戻さない」は退行ゼロ/重複解消フェーズの暫定条件だった。今回のreference-upliftでは参照構成を優先し、4区画として小さく整理できたため再導入を採用した。
- Palette: 新規 `Palette.COOKING_PREP_*` を追加。理由は下部バー/カード/タイトル/値のruntime色を、今回触った行から用途名定数へ移すため。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_prep_bar_before_after_ref.png`, `docs/qa/evidence/cooking/2026-07-05_prep_bar_select.png`, `docs/qa/evidence/cooking/2026-07-05_prep_bar_report.html`
- 判定: afterではプレイヤーLv、効果中の料理、クーラーボックス、所持金が装飾枠で区切られ、参照の下部4区画へ前進した。所持金は `1,250 G` 表記へ合わせ、テキストの見切れなしを実スクショで確認した。cmp一致は判定に使っていない。
- 検証: `./tools/cooking_visual_qa.sh`、`tools/cooking_content_audit.tscn`、`tools/cooking_layout_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`validate_project.sh` の ObjectDB/resource 警告はベースライン既知。
- 固定条件: COOK_SELECT下部バーは4区画構成を正とする。ヘッダー `PlayerStatusBar` は維持し、次スライスは右詳細パネルへ進める。

2026-07-05: `COOK_SELECT recipe card reference-uplift` 完了。料理カードを参照の3段構成へ寄せ、カード枠素材候補を採用した。

- 選定理由: `docs/qa/evidence/cooking/2026-07-05_layout_audit_repair_select.png` と `reference/cooking_flow/01_cook_select_concept.png` の横並びで、現行はカード上部タイトル帯 / 中央皿画像 / 下部星ランク+魚アイコンの分離が弱く、docs/19の順序では素材質感フェーズに入るため。
- 変えたもの: 料理カード枠4枚（通常/選択/皿サムネ/素材フッター）、カード内タイトル・皿・星・素材行の縦配分、星ランクのruntimeポリゴン描画、料理カード周辺のPalette定数、`tools/cooking_content_audit.gd` の星ランク契約。
- 変えていないもの: §1 freeze値、魚リスト、右詳細パネル、画面下部バー、背景/左右余白、調理報酬オーバーレイ、日本語PNG焼き込み。
- 素材候補: `tools/generate_cooking_showcase_assets.py` でカード枠候補を生成し採用。候補はカード上部にタイトル帯、中央に皿窓、下部に星/素材ソケットを持ち、beforeより参照の読み方に近づいたため。
- Palette: 新規 `Palette.COOKING_RECIPE_*` を追加。理由は料理カード固有のタイトル/星/フッター/カード状態/サムネ/素材行の色を、今回触ったruntime行から用途名定数へ移すため。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_recipe_card_before_after_ref.png`, `docs/qa/evidence/cooking/2026-07-05_recipe_card_select.png`, `docs/qa/evidence/cooking/2026-07-05_recipe_card_report.html`
- 判定: beforeではタイトル文字がカード絵へ沈み、星ランクが実質読めなかった。afterではタイトル帯、皿画像、星ランク+魚アイコンの下部ソケットが分かれ、参照構成への前進が第三者に判別できる。cmp一致は判定に使っていない。
- 検証: `./tools/cooking_visual_qa.sh`、`tools/cooking_content_audit.tscn`、`tools/cooking_layout_audit.tscn`、`cooking_flow_smoke`、`./tools/save_system_verify.sh`、`./tools/validate_project.sh` green。`validate_project.sh` の ObjectDB/resource 警告はベースライン既知。
- 固定条件: COOK_SELECT料理カードの日本語タイトル・星ランク・素材数値はruntime描画のまま維持する。参照化の次スライスは下部バーで、カード幅/背景余白には波及させない。

2026-07-05: `layout audit repair` 完了。layout audit失敗を実スクショで確認し、EXP_GAIN / LEVEL_UP_OVERLAY / STATUS_SUMMARY の文字欠けP1と、visual QAの状態キャプチャ重複を修正した。

- 選定理由: `tools/cooking_layout_audit.tscn` の既存失敗が、実スクショ上でもEXPタイトル・レベルアップ詳細・ステータス文字の欠落として再現し、`docs/19` §2.1の文字見切れP1に該当したため。
- 変えたもの: 調理報酬/ステータス/レベルアップ各パネルのLabel最小高、EXP演出レイヤー、レベルアップのステータス行・解放帯のruntime文字描画、`tools/cooking_preview.gd` の状態別SubViewport更新、`tools/cooking_visual_qa_check.py` の重複キャプチャ検出。
- 変えていないもの: reference画像の採用/不採用、freeze表、料理カード構成、魚素材、`src/ui/cooking_screen.gd` 全体R1、`RarityStyles` 横展開。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_layout_audit_repair_select.png`, `docs/qa/evidence/cooking/2026-07-05_layout_audit_repair_result.png`, `docs/qa/evidence/cooking/2026-07-05_layout_audit_repair_exp.png`, `docs/qa/evidence/cooking/2026-07-05_layout_audit_repair_levelup.png`, `docs/qa/evidence/cooking/2026-07-05_layout_audit_repair_status.png`, `docs/qa/evidence/cooking/2026-07-05_layout_audit_repair_report.html`
- 判定: EXP_GAINは見出し・EXP値・進捗・メッセージが読める。LEVEL_UP_OVERLAYはタイトル、Lv遷移、4ステータス行、解放帯が読める。STATUS_SUMMARYはカード見出し・数値・本文が読める。5状態キャプチャはsha256がすべて異なり、重複/透明キャプチャなし。
- 検証: `./tools/cooking_visual_qa.sh`、`tools/cooking_layout_audit.tscn`、`tools/cooking_content_audit.tscn` green。スライス完了検証として `cooking_flow_smoke` / `save_system_verify.sh` / `validate_project.sh` はコミット前に実行する。
- 固定条件: visual QAで3状態以上が同一ハッシュになった場合はfail扱い。調理フローの表示完了は実スクショで確認し、layout audit greenだけを根拠に完了扱いしない。

2026-07-05: `status de-dup pass` 完了。COOK_SELECTヘッダーのローカルLv/EXP/所持金クラスタを共通 `PlayerStatusBar` に置き換え、下部「現在の準備」バーから重複するプレイヤーLv/EXPカード・所持金カードを撤去した。

- 変えたもの: `src/ui/cooking_screen.gd` のCOOK_SELECTヘッダーと下部準備バー。古い構成を正としていた `tools/cooking_content_audit.gd` / `tools/cooking_layout_audit.gd` のCOOK_SELECT契約。
- 変えていないもの: 料理カード、魚行、詳細カード、報酬オーバーレイ、ステータス詳細オーバーレイ、素材差し替え、`RarityStyles` 横展開、調理場全体の最終アート品質。
- Palette: 今回触ったヘッダーfallback色を `Palette.COOKING_TITLE_FALLBACK_BG` / `Palette.COOKING_WOOD_BORDER` / `Palette.COOKING_GOLD_TRIM` へ表示同値で移した。当時の `cooking_screen.gd` 全体R1は未完だったが、後続スライスで完了済み。
- 証拠画像: `docs/qa/evidence/cooking/2026-07-05_status_dedupe_before_after_select.png`, `docs/qa/evidence/cooking/2026-07-05_status_dedupe_select.png`, `docs/qa/evidence/cooking/2026-07-05_status_dedupe_report.html`
- 判定: COOK_SELECTで上部 `PlayerStatusBar` に Lv/装備/所持金がまとまり、下部は「効果中の料理」「クーラーボックス」「詳細」に整理。実スクショで重複Lv/EXP・所持金カードの撤去とP1なしを確認。
- 検証: `./tools/cooking_visual_qa.sh`、`cooking_flow_smoke`、全UI smoke、`./tools/save_system_verify.sh`、`./tools/validate_project.sh`、`tools/cooking_content_audit.tscn` green。`tools/cooking_layout_audit.tscn` は既存の報酬/ステータス詳細ラベル高さ検出で失敗するが、今回追加/撤去したCOOK_SELECT契約のgrep確認では失敗なし。
- 固定条件: COOK_SELECTのLv/装備/所持金はヘッダーの `PlayerStatusBar` を正とし、下部準備バーへ同じ情報カードを戻さない。
