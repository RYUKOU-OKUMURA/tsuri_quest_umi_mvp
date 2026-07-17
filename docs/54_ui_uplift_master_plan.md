# 54. UIブラッシュアップ総合実行計画

- 作成日: 2026-07-14
- 基準commit: `7cbd2d793eeb8ba99c9dd579fdf0b7a35740bea8`
- 状態: 実行計画 v1。M-INPUTとVisual Wave V1を完了し、M-V1を達成。次は`C2-WIRE` / `MAP-M1` / `FIGHT-A2`のVisual Wave V2。進捗の正本は `docs/30_v2_expansion_overview.md` §6、画面ごとの採用値は `docs/qa/<screen>_qa.md` とする。

## 0. 結論

全体コードレビューとbehavior-preservingリファクタは完了しており、UIブラッシュアップを再開できる。ただし、見た目の改修へ直接入る前に、E11の必須Gateである入力・focus契約を収束させる。

推奨順は次のとおり。

1. `E11-INPUT-COMMON` を単一ownerで直列実装する（2026-07-15完了）。
2. 共通tipから、入力監査に失敗した画面を1画面1brief・最大3並列で修正する。
3. I0統合後の入力監査42件を0件にする（2026-07-16完了）。第1roundで7件、第2roundで11件、第3roundで9件、第4roundで11件、最終SHARK_PENで4件を閉じ、13画面finding 0を固定した。
4. I0統合、RIGHTS-01A U-04 close、`title` / `settings` のowner境界解消後に `E11-EXTERIOR` を開く。V1は前提にせず、残るI1と別ownerで並走できる。
5. Visual Wave V1の `調理C1-B` / `ステータスR5-B` / `水中ファイトのフローティングカード` を3並列で実装し、2026-07-17に完了する。
6. 調理は `C1-B → C2 runtime採用 → C3 → C4 → C5` を同一レーン内で直列に進め、他画面の独立upliftと並走させる。V2以降はPre-RC cutoff前に明示採用する分だけ統合し、残りは発売後Waveへ送る。

現時点で視覚上の未解決P1はなく、I1最終round統合後のfresh隔離HOME実入力probeでも13画面すべてfinding 0となった。Visual Wave V1も各独立レビューP0/P1/P2/P3 0と最終47対象release gateを通過してM-V1を達成したため、次は`C2-WIRE` / `MAP-M1` / `FIGHT-A2`を3並列で開始する。

## 1. 正本と本書の役割

| 関心 | 正本 | 本書との関係 |
|---|---|---|
| UI制作ルール、P1/P2/P3、freeze再オープン | `docs/19_ui_production_playbook.md` | 常に優先。本書は変更しない |
| V2・発売前トラックの現在地 | `docs/30_v2_expansion_overview.md` §6 | 進捗更新先。本書は順序とbrief境界を定義 |
| E11入力・外装の仕様 | `docs/v2/E11_launch_readiness.md` | INPUT-COMMON / EXTERIORの正本 |
| 画面ごとのfreeze・残ギャップ・採否 | `docs/qa/<screen>_qa.md` | 実装時に必ず再読する |
| 調理・市場の素材フェーズ | `docs/33_cooking_market_ui_uplift_plan.md` | 調理C1-B〜C5の詳細正本 |
| 目標アート方向 | `docs/10_UIクオリティ向上マスタープラン.md`、`reference/` | 目標の参照。旧フェーズ順は本書で置き換える |
| 直前のコード監査 | `docs/53_pre_ui_code_review_and_refactor.md` | 本書の開始baseline |

`docs/45_release_readiness_code_review.md` は2026-07-10時点の監査スナップショットである。同書のINPUT-BASEにある「ゲームパッド採用時のみ」という条件は後発正本で更新済みであり、現行はマウス＋キーボード専用範囲に対する必須Gateとして扱う。

## 2. 現在地

### 2.1 完了済みの横断基盤

- LINE Seed JPとAA方針、`Palette`、`ScreenBase`、`PlayerStatusBar`、`RarityStyles`、共通CTA追加variantの正本化。
- 素材所有監査、ライセンス監査、魚素材共有契約、決定的processor、decoded pixel同値時の既存PNG bytes保持。
- 市場・調理などの固定visual QA、主要screen smoke、全体`validate_project.sh`。
- UI Wave継続前の全体コードレビューと、core/save・UI/runtime・tooling/releaseの相互レビュー。

### 2.2 完了済みの画面uplift

| 画面 | 完了内容 | 現在の扱い |
|---|---|---|
| 魚市場 | M0〜M3。backplate分解、市場背景、氷台、共通CTA | P1/P2なし。freeze維持 |
| 依頼ボード | 木面と中央ピン付き紙札のauthored素材 | freeze維持 |
| サメ生簀 | 専用水槽背景・環境光 | freeze維持。王冠等は独立した後続候補 |
| 調理 COOK_SELECT | C0、C1-A厨房背景、C1-B料理カード紙面/タイトル帯 | 次はC2-WIRE。背景・カードへ戻らない |
| ステータス | R5-A中央プレイヤーhero、R5-B木・真鍮・紙shell | R5-A/R5-Bともfreeze維持 |
| 港 | 司令盤v1.2 | freeze維持 |
| 水上READY / 水中FIGHT | 基盤レイアウト、時間帯・天候、最長餌魚名P1、FIGHT-A1右上カード | 次はFIGHT-A2の下段バーだけを別採否 |
| 魚図鑑 | 台帳構成、魚素材重複P1/P2/P3 | 新P1がなければ触らない |

### 2.3 13画面の現状と次の候補

| 画面 / 主script | 現状 | 現在のTop gap | 次の扱い | 優先度 |
|---|---|---|---|---|
| タイトル / `title_screen.gd` | E7難易度・slot確認freeze | 正式名、version、icon、splash | INPUT-TITLEとowner境界解消後にE11-EXTERIOR | 発売Gate |
| 港 / `harbor_screen.gd` | 司令盤freeze | 夜専用景観、本物の天候先読み | 新P1なしなら保留 | P3 / feature |
| 釣行 / `fishing_screen.gd` | READY/FIGHT構成freeze、FIGHT-A1完了 | 下段スリムバーのauthored質感 | V2でFIGHT-A2を別採否 | P2 |
| 釣り場マップ / `fishing_spot_select_screen.gd` | uplift継続中 | 現行実画面とreference/06のTop1を再計測 | Visual V2で1スロット監査 | P2候補 |
| 調理 / `cooking_screen.gd` | C1-Bまで完了 | C2〜C5。一点物素材の密度 | 次はC2-WIRE、以後専用直列レーン | P2 |
| 魚図鑑 / `fish_book_screen.gd` | v1採用・魚素材完了 | 現行QA上のP1/P2なし | 回帰のみ | freeze |
| ステータス / `status_screen.gd` | R5-A/R5-B完了 | 現行QA上のP1/P2なし | 回帰のみ | freeze |
| 釣具店 / `shop_screen.gd` | v1 freeze | 11商品の詳細大絵が既存切り抜き拡大 | 代表1商品でpilot後に判断 | P2候補 / 後続 |
| 船着き場 / `shipyard_screen.gd` | v1、帰港導線統一 | 専用referenceと正式visual QAがない | 先にD0設計・観測基盤 | 設計待ち |
| 魚市場 / `market_screen.gd` | M0〜M3完了 | CTA横幅比の微差のみ | 回帰のみ | P3 / freeze |
| 依頼ボード / `quest_board_screen.gd` | authored素材完了 | 依頼者/NPCの個性 | 後続1スロット | P3 |
| サメ生簀 / `shark_pen_screen.gd` | 水槽背景完了 | 好物王冠、最終全サメ演出 | アイコンとmotionを別sliceで判断 | P2候補 / 後続 |
| 設定 / `settings_screen.gd` | E11-DISPLAY freeze | 専用一点物なし | 装飾を増やさず入力/外装回帰 | P3 / freeze |

`調理C2` は、背景候補・brief・証拠・決定的processorの準備まで完了しているが、製品slotへの採用とruntime配線は未実施である。計画上も「候補準備済み / runtime未採用」を維持し、完了扱いにしない。

## 3. 品質優先順位

### 3.1 Gate A: 入力P1/P2

I1最終round統合後のfresh隔離HOME実入力probeでは、13画面すべてfinding 0となった。

| 種類 | 件数 | 重要度 |
|---|---:|---|
| 初期focusなし | 0 | P1 |
| disabled操作へfocus到達 | 0 | P1 |
| focus孤立 | 0 | P1 |
| 可視focus style不足 | 0 | P1 |
| 戻る契約未観測 | 0 | P2 |

この数は実装briefへ固定値として焼き込まない。各画面統合後に再probeし、最新failure manifestから次の画面別briefを生成する。監査のregistryや分類を緩めて件数だけを減らす修正は禁止する。

I1最終round統合後baselineの画面別failure分類は次のとおり。

| 画面 | 現baselineで観測したfailure |
|---|---|
| title | —（0件、第1round完了） |
| harbor | —（0件、第3round完了） |
| fishing_spots | —（0件、第2round完了） |
| fishing | —（0件、第1round完了） |
| cooking | —（0件、第4round完了） |
| market | —（0件、第3round完了） |
| shop | —（0件、第2round完了） |
| shipyard | —（0件、第1round完了） |
| status | —（0件、第4round完了） |
| fish_book | —（0件、第3round完了） |
| quest_board | —（0件、第4round完了） |
| shark_pen | —（0件、最終round完了） |
| settings | —（0件、第2round完了） |

### 3.2 Gate B: 視覚P2

次の3件を最初のVisual Waveとして2026-07-17に完了した。

1. `COOK-C1B`: COOK_SELECT料理カード紙面・タイトル帯のauthored質感。
2. `STATUS-R5B`: 3ペイン全体の木・真鍮・紙のauthored枠。
3. `FIGHT-A1`: reference/14のフローティングカードだけをauthored素材化。

いずれも構成・主導線・freeze矩形を維持し、1フェーズ1仮説・1画面1concernで採用した。実装者と別のread-only reviewerによる再レビューは各sliceともP0/P1/P2/P3 0で、親のdiff・原寸/縮小evidence確認と最終gateもgreen。

### 3.3 Backlog C: 後続候補・機能寄りの演出

- 港の夜景と本物の天候先読み。
- WAITINGの水面反応、魚の接地・アニメ微ポリッシュ。
- 釣具店の全11商品高解像度詳細絵。
- 依頼者/NPCの個性、サメ王冠、メガロドン最終演出。
- 船着き場の新しい全画面方向性。

これらはP1/P2を押しのけない。専用referenceがない画面は、実装前に全画面モックのユーザー採用とsupersede範囲を確定する。

## 4. Wave構成

### 4.1 全体の依存順

| Gate / Wave | 内容 | 並列数 | 終了条件 |
|---|---|---:|---|
| G0 | 全体コードレビュー・リファクタ | 完了 | `docs/53`、export、validate green |
| I0（完了） | E11-INPUT-COMMON共通基盤 | 1 | probe self-test / baseline / strict、13画面registry、validate green |
| I1 | 画面別INPUT修正 | 最大3 | 13画面のstrict finding 0、全screen smoke、マウス回帰green |
| V0（完了） | visual baseline再固定 | 親が直列 | INPUT後の代表/高リスク実画面をcommit `6d37322b`へ保存 |
| V1（完了） | C1-B / R5-B / FIGHT-A1 | 3 | 各Top1が縮小、P0/P1/P2/P3レビュー残件0 |
| X0 | E11-EXTERIOR / releaseレーン開始 | 正本に従う | 正式外装をcloseし、Pre-RC cutoff条件を準備 |
| V2（次） | C2-WIRE / MAP-M1 / FIGHT-A2 | 3 | C2正式採否、Map 1スロット、下段スリムバーの各採否 |
| V3 | C3 / SHIPYARD-D0 / TACKLE-T1 | 3 | EXP祝祭、船着き場の採用方向とvisual QA、代表商品pilot |
| V4 | C4 / QUEST-Q2 / SHARK-S2 | 3 | LEVEL_UP祝祭、NPC個性1スロット、サメ王冠の各採否 |
| V5 | C5 / 環境演出候補 / V3〜V4採用後の展開 | 最大3 | STATUS_SUMMARYと残る採用候補の収束 |
| K0 | 共通キット収束 | 1 | 2画面以上で実証済みの部品だけcommonへ昇格 |
| X1 | Pre-RC close・固定RC・最終受入 | 正本に従う | E11 Gate、release Gateをclose |

I1中に、V1のbrief作成・reference分解・source候補生成だけを別worktreeで準備してよい。ただし `src/ui/**`、製品asset、QA freeze、共通ハブへ触れず、I1完了後のbaselineを使って仮配線・採否をやり直す。

X0はI0統合済みを前提に、RIGHTS-01A U-04のicon採否と `title` / `settings` のowner境界を解消した時点で開始できる。M-V1は前提ではなく、残るI1やcutoff前に採用すると決めたvisual sliceと別ownerで並走できる。V2以降はfixed RCの必須条件ではない。X1のPre-RC cutoff後に未統合のvisual branchを同じRCへ追加せず、必要なら発売後の更新として扱う。

### 4.2 I0: E11-INPUT-COMMON

2026-07-15完了。実キーの8 action、共通focus / cancel契約、13画面registry、self-test / baseline / strictを統合し、最新baselineは42件（P1 34 / P2 8）となった。旧43件との差分1件は、実キー注入で既存の釣行Escape導線を正しく観測したためであり、分類は緩めていない。

単一ownerが次だけを扱う。

- `project.godot` のinput map。
- `src/ui/screen_base.gd` の共通focus / cancel契約。
- `tools/e11_input_focus_probe.gd` / `.tscn` と `tools/e11_qa_harness_verify.sh`。

`project.godot` の `config/use_custom_user_dir=true` と `config/custom_user_dir_name="tsuri_quest_umi"` はfreezeする。共通focus styleに `ui_theme.gd` や `palette.gd` の変更が必要なら、先にE11のtouch表とownerを改訂し、暗黙に範囲を広げない。

I0のDoD:

- probeのself-test、baseline、strictが別の意味を持ち、self-test失敗を製品failureで隠さない。
- 全13画面のregistryが完全一致し、追加画面の取りこぼしをfailにする。
- 初期focus、隣接到達、決定、戻る、disabled skip、可視focusを観測できる。
- `./tools/e11_qa_harness_verify.sh` と `./tools/validate_project.sh` がgreen。
- 共通tipをmainへ統合してから最新failure manifestを再生成する。

### 4.3 I1: 画面別INPUTの3レーン

各矢印は別task・別commit・別レビューとする。共通tipから3つのworktreeを作る。

| Lane | 順番 | 所有理由 |
|---|---|---|
| A: settings spine | TITLE → SETTINGS → HARBOR → STATUS → SHARK_PEN | title/settingsと外装のownerを分裂させない |
| B: gameplay / catalog | FISHING → FISHING_SPOTS → FISH_BOOK → COOKING | gameplayと複雑な一覧状態を順に検証 |
| C: facility | SHIPYARD → SHOP → MARKET → QUEST_BOARD | 施設画面の戻る・disabled・購入/売却導線 |

第1〜4roundと最終`INPUT-SHARK-PEN`を完了した。各roundで実装担当とは別のサブエージェントが結論非開示のread-onlyレビューを行い、親がdiff・実入力・原寸focusスクショを確認してmainへ統合し、strict probeを再実行した。

画面別INPUT briefで触ってよいのは、当該screen、当該smoke、当該QA/evidenceだけである。次は触らない。

`INPUT-FISHING`だけは、入力ownerがscreen内に閉じていないため、当該画面所有の `src/ui/components/fight_hud.gd` と `src/ui/components/catch_fanfare.gd`、新設する専用input smokeをtouch範囲に含める。READYのcustom `Rect2`、FIGHTのSpace press/release、overlay / fanfareのEnter、modal復帰を実viewport `InputEvent`で検証し、private handler直呼びだけを根拠にしない。

`INPUT-SHIPYARD`は `shipyard_screen.gd`、shipyard smoke、QA/evidenceだけを所有する。購入成功でfocus中の購入ボタンがdisabledへ変わる状態、資金不足、所有済み、全所有を検証し、ローカルstyleが共通focus styleを消さないことを原寸スクショで確認する。

- `project.godot`、`screen_base.gd`、`ui_theme.gd`、`palette.gd`、`main.gd`。
- 他画面、共通素材、ゲームバランス、save/economyロジック。
- 既存freeze矩形と採用済み素材。

画面別INPUTの共通DoD:

- 代表状態と最も崩れやすい高リスク状態で初期focusを確認。
- 全enabled操作へキーボードで到達し、disabled操作をskipする。
- normalと見分けられるfocus、決定、戻る1回、A→B→A復帰を実InputEventで確認。
- マウスclick、既存導線、画面固有ロジックを維持。
- 対象画面のstrict finding 0、該当smoke / visual QA / validate green。

### 4.4 V1: 最初の視覚3並列

| Lane | 1 concern | 維持するもの | 必須状態 / 検証 |
|---|---|---|---|
| COK | C1-B料理カード紙面・タイトル帯 | 3列、料理情報、PlayerStatusBar、C1-A背景、全freeze | COOK_SELECT通常+locked/長文、5状態回帰、cooking visual/verify/flow smoke |
| STA | R5-B木・真鍮・紙の全画面枠 | R5-A hero、右4指標、3ペイン、header/footer | normal/hard同一seed、status visual/smoke、save verify |
| FGT | FIGHTフローティングカード専用素材 | reference/14構成、下段スリムバー、魚、背景、line anchor、READY契約 | 標準魚+大型端寄り/長いrarity、fight visual、reveal/return/fanfare smoke |

3レーンとも画面固有のscreen、assets、processor、visual QA、smoke、QA/evidenceだけを所有する。`docs/31_asset_ledger.md` と監査allowlistは素材追加commitに必要なので、各branchで素材と一緒に更新し、親が COK → STA → FGT の順で直列rebase / mergeして追記をunionする。`docs/30`は親だけが更新する。

### 4.5 V2以降

#### COOK専用直列レーン

| Slice | 内容 | 前提 | 採否の中心 |
|---|---|---|---|
| C1-B | COOK_SELECTカード質感 | C1-A完了 | 紙面/タイトル帯が背景と料理より勝ちすぎない |
| C2-WIRE | 準備済み食事シーン候補を背景slotへ仮配線 | C1-B統合 | 既存人物・料理・報酬カードを維持し、食事payoffが先に読める |
| C3 | EXP_GAIN祝祭 | C2採否完了 | 大見出し、+EXP、ゲージ台座、料理アート |
| C4 | LEVEL_UP祝祭 | C3完了 | Lv遷移と解放報酬がフロー最強のhierarchy |
| C5 | STATUS_SUMMARYアート | C4完了 | R5-Aとの重複責務を避け、5カードを短時間で読める |

C2は候補をそのまま採用しない。既存の `player_eating_pose`、料理、カード、freeze座標を動かさず同一状態runtime比較し、左ランタン/右窓が文字へ干渉する場合だけ低alpha screen scrimを検討する。明確に勝たなければ候補を非採用にし、現行製品slotを維持する。

調理の状態契約は次を最低限とする。

| Slice | 代表状態 | 高リスク状態 |
|---|---|---|
| C1-B | 現previewの通常料理選択 | selected / locked / unavailable / hover / focus、hard初回・EXP上限、魚全種scroll |
| C2 | 初回bonusあり・報酬4枚・長いbuffのMEAL_RESULT | 初回済み、長料理名/効果文、MEAL_RESULT→EXP_GAIN |
| C3 | level-upなしのEXP_GAIN | EXP_GAIN_LEVELUP、初回有無、EXP上限、長いbuff |
| C4 | Lv4→5 boss unlock | 通常level-up、大きいstat桁、modal input block、LEVEL_UP→STATUS |
| C5 | Lv5・食事効果あり | no meal、MAX level、最大金額/容量/時間、長い効果文、return focus |

C3は背景、光背/バースト、ゲージ台座、料理画像を同時採否しない。C4も王冠/月桂樹、メダル/釣り場、紙吹雪/光線、固定英字ロゴを子スライスへ分ける。C5の各カードアートも1スロットずつ進める。

#### 他画面レーン

- `MAP-M1`: 現行実画面・reference/06・縮小/grayでTop1を再計測し、1素材slotだけを採否する。構成再設計が必要なら素材作業を止め、採用モックを先に作る。
- `FIGHT-A2`: FIGHT-A1採用後の画面をbeforeとし、下段スリムバーだけをauthored素材化する。カードとバーを同一採否へ戻さない。
- `SHIPYARD-D0`: 製品UIを変えず、専用referenceまたは全画面モック、代表/高リスク状態、`shipyard_visual_qa.sh`を先に確立する。
- `TACKLE-T1`: 11点一括生成をせず、視線の高い代表商品1点の詳細大絵でpilotする。明確な全画面勝ちが出た場合だけ同じ契約でbatch化する。
- `QUEST-Q2`: 依頼者/NPC個性を1スロットだけ追加し、本文・進捗・報酬・CTAを動かさない。
- `SHARK-S2`: 好物王冠と最終演出を分ける。アイコンと全サメ演出を同一briefへ混ぜない。

### 4.6 K0: 共通キット収束

共通部品を画面別Waveと同時に編集しない。画面固有variantが2画面以上で同じ役割・状態契約として採用された後にだけ、独立Waveで `assets/showcase/common/` へ昇格する。

昇格時は次を確認する。

- normal / hover / pressed / focus / disabledの実入力差。
- 最小使用寸法で9-sliceや枠線がcontentへ侵入しない。
- 既存consumerの全画面画素差が意図どおり。
- 旧画面専用素材と参照を削除し、所有監査と台帳を同期。

## 5. 1スライスの標準手順

### 5.1 Definition of Ready

着手前に以下を満たす。

1. `docs/19`、対象spec、対象QAのfreezeと不採用リストを読む。
2. 局所upliftか構成再設計かを判定する。
3. 代表状態と高リスク状態、固定seed、before出力を決める。
4. 変更仮説、採否条件、動かす値、触らないfreezeをQA §6へ宣言する。
5. 画面固有のvisual QA / smokeがなければ、製品変更より先に観測基盤を作る。
6. 素材slotならdocs/12形式brief、禁止要素、safe-area、source/output/processorを決める。

複数workerが新規brief/specを作るWaveでは、fan-out前に親が既存最大+1から重複しないdoc番号とファイル名を割り当て、brief骨格と `docs/README.md` 索引を先行commitする。workerは割り当て済みの固有docだけを編集し、自分で次番号を採番しない。

### 5.2 実装順

1. 構成。
2. 主導線または主対象。
3. 情報階層。
4. 文字の収まり。
5. 素材の質感。
6. 演出・juice。

構成が合格済みの画面では1〜4を再工事せず、対象の5または6だけを扱う。1フェーズは1仮説、素材フェーズは原則1スロットとする。

### 5.3 採用条件

- 同一状態の原寸before/afterで第三者が改善を判別できる。
- 320×180前後のafter/reference比較で、対象Top1の参照距離が縮む。
- 代表状態と高リスク状態の両方でP1がない。
- 既存主導線、freeze、ゲームロジック、マウス操作を壊さない。
- P0/P1/P2の独立レビュー残件が0。P3はQAへ明記すれば非阻害とできる。

条件を満たさない候補は不採用にし、候補追加を理由に製品へ残さない。

## 6. 素材パイプライン

1. `reference/` は方向性の真実として使い、画素を製品へ直接流用しない。
2. 日本語、動的数値、魚、料理名、進捗、CTA文言はruntime描画を維持する。
3. sourceは `tools/source_assets/<screen>/`、製品は `assets/showcase/<screen>/`、共有実証後だけ `common/` に置く。
4. processorは出力size/mode/decoded pixelsを比較し、画素同値なら既存PNG bytesを保持する。
5. 真の画素差だけ同一directoryのtempからatomic replaceし、失敗時に旧製品とtemp cleanupを保証する。
6. 新素材は同じcommitで `docs/31_asset_ledger.md` に作者、生成手段、日付、source/output、権利状態を記録する。
7. ownership / licensing監査のallowlistは理由コメント付き最小差分とし、動的path化などの監査回避をしない。
8. OpenAI生成素材の個別権利clearanceはU-08 pendingを虚偽にcloseしない。

## 7. Evidence・QA・検証

### 7.1 最低限の証拠

- 同一seed・同一データ・同一選択の原寸before/after。
- before/after/referenceの原寸3面と320×180比較。
- 必要な画面ではgrayscale、alpha bbox、safe-area overlay。
- 代表状態と最も崩れやすい高リスク状態。
- 操作部品はnormal / hover / pressed / focus / disabledの実入力状態。
- A→B→Aで可変矩形と主要anchorが元に戻るsmoke。

証拠は `docs/qa/evidence/<screen>/YYYY-MM-DD_<slice>_*` に保存する。`/tmp` のみの証拠で採用しない。

### 7.2 画面別の主要Gate

| 領域 | visual QA | 機能 / smoke |
|---|---|---|
| 調理 | `./tools/cooking_visual_qa.sh` | `./tools/cooking_verify.sh`、`cooking_flow_smoke.tscn`、必要時`save_system_verify.sh` |
| ステータス | `./tools/status_visual_qa.sh` | `status_smoke.tscn`、`save_system_verify.sh` |
| FIGHT / READY | `./tools/fight_visual_qa.sh`、必要時`surface_weather_visual_qa.sh` | `fishing_reveal_smoke.tscn`、`fishing_harbor_return_smoke.tscn`、`catch_fanfare_smoke.tscn` |
| 釣り場マップ | `./tools/fishing_spot_map_visual_qa.sh` | `fishing_spot_select_smoke.tscn` |
| 魚図鑑 | `./tools/fish_book_visual_qa.sh` | `fish_book_smoke.tscn` |
| 魚市場 | `./tools/market_visual_qa.sh` | `market_smoke.tscn` |
| 依頼ボード | `./tools/quest_board_visual_qa.sh` | `quest_board_smoke.tscn` |
| サメ生簀 | `./tools/shark_pen_visual_qa.sh` | `shark_pen_screen_smoke.tscn`、`shark_pen_smoke.tscn` |
| 釣具店 | `./tools/tackle_shop_visual_qa.sh` | `tackle_shop_smoke.tscn` |
| 港 | `./tools/harbor_visual_qa.sh` | `harbor_screen_smoke.tscn` |
| タイトル / 設定 | `title_visual_qa.sh` / `settings_visual_qa.sh` | `title_preview_guard_smoke.tscn`、`settings_smoke.tscn`、`main_navigation_smoke.tscn` |
| 船着き場 | D0で`shipyard_visual_qa.sh`を新設 | `shipyard_smoke.tscn` |

全スライスで `./tools/validate_project.sh` と `git diff --check` を通す。既知のObjectDB/resource終了警告はexit 0かつ既知契約と一致する場合だけ非阻害とし、新しい未説明ERROR / WARNINGを許容しない。

## 8. 並列運用とowner

### 8.1 基本構成

- 親1 + 実装worker最大3。ユーザー向けセッションを立てる場合は `gpt-5.6 sol medium` を指定する。
- 各workerは同じmain commitから `codex/<slice>` branch・別worktreeを使う。
- briefは1 concern、触ってよいファイル、触ってはいけないもの、DoD、短い報告を必須とする。
- 実装完了後、実装者とは別のサブエージェントがread-onlyレビューする。
- 親はworker報告を信用せず、diff、実スクショ、QA、smokeを自分で確認する。

### 8.2 単一writerにする共有ファイル

| 共有ハブ | owner規則 |
|---|---|
| `project.godot` | I0 / EXTERIORのspineだけ |
| `screen_base.gd` / `ui_theme.gd` / `palette.gd` / `game_fonts.gd` | 独立common concernだけ |
| `assets/showcase/common/**` | K0だけ |
| `src/main.gd` | E11 spineまたは遷移専用sliceだけ |
| `docs/30_v2_expansion_overview.md` | 親だけ |
| `docs/README.md` / 新規doc番号 | 親がWave開始前に予約・索引し、workerは割当済みdocだけを編集 |
| `docs/31_asset_ledger.md` | 各asset branchで同一commit更新、親が直列union |
| ownership / licensing監査 | 素材branchで理由付き最小更新、親が直列union |
| release verifier / export関連 | E11・release ownerだけ |

同一visual QAは固定`/tmp`出力を使うため同時実行しない。workerはrun固有HOMEを使い、正式evidenceは親が統合後に直列再生成する。

### 8.3 commit・merge順

1. baseline/spec。
2. 実装または素材processor/product/ledger。
3. evidence/QA。
4. review修正。

日本語commitを小さく作る。親は各roundを固定順で直列rebase / mergeし、統合後に対象QA、全体validate、strict probeを再実行する。assetと台帳、製品参照と監査登録を別々の未完commitとしてmainへ残さない。

## 9. 独立レビュー契約

レビュー担当には実装者の採用結論を渡さず、次だけを渡す。

- base...tip diff。
- 採用reference / spec / QA freeze。
- 原寸before/after/referenceと代表・高リスク状態。
- 状態対応表、変更範囲、実行済みコマンド。

レビュー担当はP0/P1/P2/P3、freeze違反、別状態退行、素材所有、権利監査、再生成決定性を確認する。P0/P1/P2があれば同じ実装者へ戻し、修正後に同じ観点で再レビューする。親は最終tipを改めて確認し、レビュー前tipの結果を流用しない。

## 10. Stop / Revert条件

次のいずれかでそのsliceを停止またはrevertする。

- 監査registry・分類・assertを弱めてfailureを隠した。
- disabledをenabled化してfocus問題を回避した。
- 戻るが二重発火、マウスclickが退行、ゲームロジックやsave値が変わった。
- docs/19の3条件なしにfreeze矩形を動かした。
- 原寸で第三者が改善を判別できない、または縮小で参照距離が縮まらない。
- 代表状態は改善したが高リスク状態を壊した。
- 同じ測定軸を3回動かしても改善しない。
- 新しい未説明ERROR / WARNING、監査違反、権利情報欠落が出た。

revertはcodeだけでなくsource、product、evidence、ledger、監査登録を同じslice単位で戻し、孤立素材を残さない。

## 11. マイルストーン

| Milestone | 完了条件 |
|---|---|
| M-INPUT | 13画面strict finding 0、マウス＋キーボードの全操作契約、全screen smoke / validate green |
| M-V1（2026-07-17達成） | C1-B / R5-B / FIGHT-A1採否、各独立レビューP0/P1/P2/P3 0、最終47対象release gate green |
| M-COOKING | C1-B〜C5が状態順に採否され、5状態の参照距離と回帰が記録済み |
| M-CATALOG | Mapの現行Top1、Tackle pilot、Shipyard D0の判断が完了 |
| M-COMMON | 共有昇格部品の実証consumer 2画面以上、全consumer回帰green |
| M-EXTERIOR | 正式名、version、icon、splash、title runtime、台帳、export回帰green |
| M-RC | E11・権利・性能・9セル・成果物検証が同一RCでclose |

## 12. 直近の実行キュー

### 完了した入力セッション（2026-07-15〜16）

- I0: `E11-INPUT-COMMON`の単一writerと、`INPUT-FISHING` / `INPUT-SHIPYARD` のread-only事前棚卸しを完了し、mainへ統合した。
- I1第1round: `INPUT-TITLE` / `INPUT-FISHING` / `INPUT-SHIPYARD` を3並列で実装し、実装者とは別のread-onlyレビュー、親diff・実入力・原寸証拠レビュー、指摘修正後の再レビューを通過してmainへ直列統合した。
- I1第2round: `INPUT-SETTINGS` / `INPUT-FISHING_SPOTS` / `INPUT-SHOP` を3並列で実装し、各独立read-onlyレビューと親レビューを通過してmainへ直列統合した。設定の原寸証拠validator、既存settings smokeの遷移同期、釣り場input fixtureの実App BGM owner境界、release警告scopeも指摘後再レビューで収束した。
- I1第3round: `INPUT-HARBOR` / `INPUT-FISH-BOOK` / `INPUT-MARKET` を3並列で実装し、各独立read-onlyレビューと親レビューを通過してmainへ直列統合した。動的時間帯lock、図鑑の88操作閉路、魚市場のmodal trap / empty復帰を専用smokeと原寸証拠へ固定した。
- I1第4round: `INPUT-STATUS` / `INPUT-COOKING` / `INPUT-QUEST-BOARD` を独立worktreeで実装し、各独立read-onlyレビュー、指摘修正後の再レビュー、親のdiff・実入力・原寸証拠レビューを通過してmainへ統合した。称号modal trap、調理5状態handoff、依頼の納品/記録報告後の即時入替を専用smokeへ固定した。
- I1最終round: `INPUT-SHARK-PEN`を単独worktreeで実装し、独立read-onlyレビューと親のdiff・実入力・原寸証拠レビューを通過してmainへ統合した。通常、last-stock、locked/empty、A→B→A、マウス/Escape一重を専用smokeへ固定した。
- 専用input smoke 13本をrelease manifestへ登録し、最新baselineは42件から0件へ減少。13画面すべてfinding 0となり、M-INPUTを達成した。

### 完了したVisual Wave V1（2026-07-17）

- V0 baselineをcommit `6d37322b`へ固定後、`COOK-C1B` / `STATUS-R5B` / `FIGHT-A1`を3つの独立worktreeで並列実装した。
- 実装者とは別のread-only reviewerへdiff・spec・QA・原寸/縮小evidence・実行結果を渡し、指摘を実装者へ戻して各TIPのP0/P1/P2/P3を0件まで収束した。
- 親がCOOK → STATUS → FIGHTの順でdiffと実画像を独立確認・統合し、素材台帳と監査consumerをunion。全visual QA、cooking verify、save、E11 harness、validate、release verifier 47対象をgreenにしてM-V1を達成した。

### 次に開始する3セッション

1. `C2-WIRE`
2. `MAP-M1`
3. `FIGHT-A2`

V2も1画面1concernを維持し、C2は準備済み候補のruntime採否、Mapは現行Top1の1スロット、FIGHTはA1採用画面をbeforeに下段スリムバーだけを扱う。
