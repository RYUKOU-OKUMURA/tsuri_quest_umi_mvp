# 12. 調理ショーケース QA

対象ブランチ: `codex/cooking-showcase-flow`

目的: `reference/03_cooking_levelup_mockup.png` と `reference/cooking_flow/*` を、単一画面ではなく状態分割された調理フローの品質基準として使う。

## 5枚リファレンス方針

`reference/cooking_flow/` の5枚を状態別の正リファレンスとして扱う。新規に完成イメージを生成し直さず、既存の途中実装は保持したうえで、以下の差分を順に埋める。

| 状態 | 正リファレンス | 現実装との差分 | 次の実装方針 |
|---|---|---|---|
| `COOK_SELECT` | `reference/cooking_flow/01_cook_select_concept.png` | 3カラム構成とカードUIは近い。料理一覧は3列グリッドへ寄せ、選択魚に使えない料理も`素材違い`カードとして出して、参照の3x2に近い密度へ改善した。料理カードには料理画像に加えて星評価、素材魚アイコン、`RecipeMaterialBadge_*` の下部バッジを追加し、参照画像の「料理写真、星、素材魚」がカード内で読める構成へ寄せた。ヘッダーのプレイヤー/所持金カードと下部ステータス帯には、プレイヤー、コイン、料理、クーラー、料理図鑑の小アイコンを追加し、調理前の現在状態を文字だけでなく絵として読める方向へ寄せた。下部の `現在の準備` は `prep_summary_bar_frame.png` と `prep_summary_card_frame.png` を使う `CurrentPrepBar` / `PrepSummaryCard*` へ置き換え、参照01の下部ステータスバーに近い紙カード群として読ませる。右詳細の料理写真を大きくし、6タイル風の情報分断から、`必要な材料`、`獲得EXP`、`次の釣行で得られる効果`の横長リボンへ組み替えた。調理ボタン直前の注記、鍋から料理皿へ流れる小さな描画式キュー、`CookButton`を `cook_action_runway_frame.png` の `CookActionRunway` へまとめ、右詳細下部が一つの主アクション帯として読めるようにした。`cooking_room_bg.png`の生成を更新し、港の見える左右窓、調理台、棚、吊り下げ食材、ランタン光を増やして、参照01の「温かい調理場」背景に寄せた。`fish_icon_sheet.png`を魚種ごとに形・模様・色が分かる1列6行シートへ更新し、左の所持魚カラムが素材リストではなく魚アート付きカードとして読める方向へ寄せた。今回、左魚リストを6行表示へ寄せ、魚絵を横に広げて参照01の素材リスト密度に近づけた。主ボタンを`CookButton`として命名し、ボタン内に鍋、炎、食事結果へ向かう矢印を直接描画して、参照01の主アクションが文字だけに見えないようにした。選択画面から`MEAL_RESULT`へ進む流れを、説明文だけでなく視覚演出でも読めるようにする。参照画像の「大判料理写真、材料行、獲得EXP行、次回効果行、主ボタン」の縦ストーリーに近づけたが、実スクショで料理写真と各行の密度確認が必要。 | 右詳細と`RecipeMaterialBadge_*`を含む料理カードの星/素材表示、食事結果への予告、`CurrentPrepBar`、`PrepSummaryCard*`、`CookActionRunway`、`CookActionCue`、`CookButton`、背景アセットの港/調理場要素、魚シートの1列6行寸法、6行魚リストはheadless layout/content auditとアセット確認で固定し、次は実スクショで料理写真の占有率、横長行の読みやすさ、調理ボタンの主役感を確認する。3列料理グリッドと5枚以上のカード表示はlayout auditで維持する。 |
| `MEAL_RESULT` | `reference/cooking_flow/02_meal_result_concept.png` | 左に食事シーン、右上に大きな「食べた」バナー、右中に今回の料理、下に4報酬カードを置く専用食事シーンへ寄せた。報酬カードにはEXP/初回/合計/次回効果の種類別小アイコンを追加し、参照のカード単位の読み分けに近づけた。さらに下部に`プレイヤーLv.` / `効果中の料理` / `クーラーボックス` / `所持金`の4分割ステータス帯を追加し、参照の「食べた結果が今の準備へ反映された」文脈に寄せた。英字プレースホルダはなくし、左カードには食事中キャラ/椀/湯気のビジュアルを出す。上部3ステップの矢印を太くし、`食事 -> EXP`だけが金色に光る導線に加え、次カードを`2 EXP 次へ`、ボタンを`食経験値へ進む`へ変えた。さらにMEAL_RESULTの下部ステータス帯は、EXP加算前のLv/EXPスナップショットを表示するように修正し、参照02の「食事結果」から参照03の「EXP獲得」へ進む時間差を明確にした。`次の釣行`報酬カードに魚と上昇矢印の小ビジュアルを追加し、効果カードが文字説明だけでなく「次回の釣りへ効く報酬」として読めるようにした。`meal_scene_bg.png`の生成を更新し、中央の暖色グロー、棚/器、テーブル前景、皿、湯気を増やして参照02の食事シーン密度へ寄せた。今回、`player_eating_pose.png`を追加し、左の食事キャラをコード描画ではなく差し替え可能な専用素材として接続した。さらに右上の結果バナーを`meal_banner_frame.png`として分解し、魚スタンプ付きの紙バナー素材を使うことで、参照02の「食べた！」主見出しに近づけた。`cooking_icon_sheet.png`も10種の共通アイコンシートへ拡張し、報酬カードのEXP/初回/合計/効果/成長アイコンをこの素材から描くように接続した。結果パネルの主ボタンを`RewardConfirmButton`として命名し、MEAL_RESULTでは椀からEXP玉へ向かう小さな描画キューをボタン内に追加した。`食経験値へ進む`押下時に次ステップを`2 EXP 起動`へ点灯し、閉じる直前の文言もEXP移行に変えることで、食事結果からEXPゲージへ力が送られる接続感を補強した。 | 食事完了からEXP加算へ進む導線、EXP加算前ステータス表示、次回効果カードの小ビジュアル、`RewardConfirmButton`、食事背景アセット、`player_eating_pose.png`、`meal_banner_frame.png`、`cooking_icon_sheet.png`はcontent/layout auditで固定し、次は実スクショでバナー文字の収まり、矢印の光量、報酬カードからボタンへの視線誘導を確認する。下部ステータス帯はcontent/layout auditで固定する。 |
| `EXP_GAIN` | `reference/cooking_flow/03_exp_gain_concept.png` | EXP状態では右ペインを料理詳細カードからEXPフォーカスカードへ差し替え、巨大`+EXP`、before/after数値、明るいゲージ、短いキャラメッセージを主役にした。補助報酬カードは種類別小アイコン付きで横一列に圧縮し、下部に`プレイヤーLv.` / `効果中の料理` / `クーラーボックス` / `所持金`のステータス帯を追加済み。英字プレースホルダはなくし、左カードには料理から力が出る簡易ビジュアルを描画し、左の料理カードから右のEXPカードへ流れる`ExpEnergyTrail`も追加した。さらに左の食べた料理カード内にも`初回ボーナス +20 EXP`バッジを追加し、参照画像の左カード内ボーナスブロックに寄せた。EXP時だけ右側に`次の釣行で効果！`専用カードを追加し、効果名、効果説明、発動時間、魚/上昇演出を上段で読めるようにした。今回、`exp_stage_bg.png` を追加し、MEAL_RESULTの暖色食卓背景ではなく暗い厨房＋金/シアンのバースト背景へ切り替えることで、参照03の専用EXPステージとして読めるようにした。EXPフォーカスカードは`exp_burst_frame.png`を使う`ExpBurstFrame`へ分解し、放射バースト、ゲージ台座、シアンの光線を素材側に持たせたうえで、コード側のゲージフラッシュと星粒を重ねる構成にした。さらに参照03のキャラメッセージ枠に合わせ、`player_exp_message_pose.png`を使う`ExpMessagePortrait`と`ExpMessagePanel`を追加し、料理で力が入った反応をテキストだけにしない。上部3ステップの導線を修正し、通常EXPでは`食事 -> EXP`を金、`EXP -> 成長進行`をシアン、レベルアップ時は`EXP -> 成長解放`を赤金で示すようにした。`/tmp/tsuri_cooking_exp.png`、content audit、layout auditの `EXP_GAIN` は参照03に合わせ、初回ボーナスあり・非レベルアップの `+40 EXP` として固定する。非レベルアップ時は`準備へ戻る`ボタンで`現在の準備`サマリーへ戻り、レベルアップ時は`LEVEL_UP_OVERLAY`、その後`STATUS_SUMMARY`へ進む。`RewardConfirmButton`をEXP状態でも使い、非レベルアップ時はEXP玉から小さなサマリーカードへ、レベルアップ時はEXP玉から星/王冠へ進む描画キューをボタン内に出して、報酬の行き先を押下前から読めるようにした。EXPパネルを閉じる直前も非レベルアップなら`成長 保存`、レベルアップなら`成長 表示`へステップ表示を切り替え、報酬の行き先を押下時にも明示する。 | 3ステップ表示と閉じ後の遷移で、非レベルアップ時は成長進行として完結し、レベルアップ時は解放への接続が明確になる。EXP背景は`RewardStageBackground`として専用アセットへ切り替わる。左料理カード内の初回ボーナス、`ExpBurstFrame`、`ExpMessagePanel`、`ExpMessagePortrait`、`RewardConfirmButton`、非レベルアップ完了ボタン、connector mode、`EXP 80/150 -> 120/150`はcontent/layout auditで固定し、1280x720で文字クリップなしはフリーズ条件として維持する。 |
| `LEVEL_UP_OVERLAY` | `reference/cooking_flow/04_level_up_overlay_concept.png` | 2列ステータス、赤い解放リボン、王冠/メダル/釣り場サムネ風の描画ビジュアル、紙吹雪/星/金色光線を専用パネル内へ追加済み。英字プレースホルダは削除し、`成長の証`、`挑戦解放`、`新釣り場`、`港の大岩`などの和文タグに置換した。王冠付きタイトル帯を左右ラウレル付きに再構成し、`LEVEL UP!`のサイズと金装飾を強めた。赤い解放リボンとボスメダルも大きくし、Lv.5報酬がフロー最大のピークとして読める方向へ寄せた。さらにEXP報酬を閉じてLEVEL_UPへ進む直前に背面を`現在の準備`サマリーへ戻し、参照画像の「調理選択画面が暗転した上に報酬ダイアログが乗る」構成へ寄せた。OKボタンを`OK  成果確認へ`へ変更し、レベルアップ報酬を閉じると参照05の成果確認へ進むことを、720p内に収めたまま明示した。今回、タイトル帯の王冠と左右ラウレルを`level_crown.png` / `level_laurel_left.png` / `level_laurel_right.png`へ、解放カードのボスメダルと海辺サムネイルを`level_unlock_medallion.png` / `level_unlock_spot.png`へ分解し、参照04の報酬記号をコード描画だけでなく差し替え可能な素材スロットにした。解放カード内にはLv/料理/クーラー/所持金/時間の5カードへ流れる小さな`成果確認`キューを追加し、OKボタンも`LevelUpConfirmButton`として命名して、王冠から成果カードへ向かう描画キューをボタン内に追加した。参照04のピークから参照05の専用サマリーへつながる読みを補強する。OK後は`STATUS_SUMMARY`へ接続し、レベルアップの閉じアニメーション完了後に成長結果を次の準備確認へ着地させる。差分は、本番イラスト水準の王冠/金ラウレル/ボスメダル/海辺サムネイルへの差し替えと、背景選択画面が暗転越しにどの程度読めるかの実スクショ確認。 | 能力行アイコン、成果確認キュー、`LevelCrownAsset`、`LevelLaurelLeftAsset`、`LevelLaurelRightAsset`、`LevelUnlockMedallionAsset`、`LevelUnlockSpotAsset`、`LevelUpConfirmButton`、`OK  成果確認へ`文言はheadless layout/content auditで文字クリップなしを確認する。次は実スクショで中央報酬パネルの占有率、背面暗転、紙吹雪の密度、OK後のサマリー遷移を確認する。1280x720で情報が収まる現状レイアウト、LEVEL_UP背面の`現在の準備`復帰はsmoke/content auditで維持する。 |
| `STATUS_SUMMARY` | `reference/cooking_flow/05_status_summary_concept.png` | 小さな要約モーダルから、全画面の専用サマリー状態へ再構成済み。5カード内の`PLAYER`/`COOLER`/`GOLD`/`TIME`/`READY`英字プレースホルダは、プレイヤー、クーラーボックス、所持金、時計、釣り支度ビジュアルへ置換した。上部ヘッダー、5枚の大型縦カード、下部メッセージバー、`港へ戻る`導線は参照構成に寄った。レベルアップOK後の自動遷移先として接続し、Lv.5到達時はフッターで`港のぬしに挑めます`と次行動を明示する。参照05の「上部ヘッダー→5カード→下部メッセージ」の読み順に合わせ、STATUS_SUMMARY入場時にヘッダー、5カード、フッターを短い段差で表示し、LEVEL_UP後の成果確認へ着地させる。さらに`港へ戻る`はオーバーレイを閉じるだけでなく、フェードアウト完了後に実際に`harbor`へnavigateするよう接続した。ヘッダー右側のLv/EXPボックスに小さなプレイヤーバッジを追加し、参照05の「顔アイコン＋Lv/EXP」まとまりへ寄せた。`港へ戻る`ボタン内に描画式アンカーを追加し、サマリーを確認して港へ戻る最終導線も参照05の見た目へ寄せた。効果中料理カードの説明枠には剣と上昇矢印の`StatusMealEffectCue`を追加し、参照05の「料理効果が次の釣行に効く」サインをテキストだけにしない。今回、STATUS_SUMMARYでも使う`cooking_room_bg.png`を更新し、背後の港/厨房文脈がカードの後ろに残るようにした。さらに`player_status_portrait.png`を追加してプレイヤーカードの大きな肖像へ接続し、今回追加した`status_cooler_art.png`、`status_money_art.png`、`status_clock_art.png`をクーラー/所持金/プレイ時間カードの大判イラストとして接続した。プレイヤーカードの能力行はハート/剣/盾/靴/クローバーの小アイコンで成果を読めるようにした。残差分は本番アート水準への差し替えと、実スクショでの装飾と段差演出の見え方。 | ヘッダープレイヤーバッジ、料理効果アイコン、能力行アイコン、アンカー付き戻りボタン、`player_status_portrait.png`、`status_cooler_art.png`、`status_money_art.png`、`status_clock_art.png`、背景アセットの港/厨房要素はheadless layout auditとアセット確認で文字クリップなしを確認する。次は実スクショで参照密度、カード余白、レベルアップ後に5カードとフッターが報酬の余韻として読めるかを確認する。5カードの1280x720収まりとLv.5後フッター文言はcontent/layout auditで維持する。 |

この差分表は、実スクリーンショット取得前の暫定比較であり、次回以降は `/tmp/tsuri_cooking_*.png` が取れ次第、各正リファレンスと並べて更新する。

### 今回の追記: EXP_GAIN 次回効果アート

`reference/cooking_flow/03_exp_gain_concept.png` の右カードは、次の釣行に効果が渡ることを小さなイラストでも読ませている。途中実装では魚と上昇矢印を `EffectPreviewVisual` のコード描画で表現していたため、今回 `next_effect_art.png` を追加し、`NextEffectArt` としてEXP_GAIN/EXP_GAIN_LEVELUPの右カードに接続する。これにより、次回効果カードは文字説明だけではなく、差し替え可能な専用素材スロットとして固定する。content/layout auditでは `next_effect_art.png` の寸法と `NextEffectArt` ノードの表示サイズを検出する。

### 今回の追記: STATUS_SUMMARY 専用背景

`reference/cooking_flow/05_status_summary_concept.png` は、調理選択画面の上に小さく出る要約ではなく、5カードを主役にした独立の成果確認画面として読む。途中実装では `cooking_room_bg.png` と `StatusBackdropVisual` の重ね描きで港/厨房文脈を作っていたため、今回 `status_summary_bg.png` を追加し、`StatusSummaryBackground` としてSTATUS_SUMMARYの最背面へ接続する。背景内に上部ネイビー帯、港側の窓、厨房側の棚、5カードの着地点、下部フッター帯を持たせ、レベルアップ後の成果確認へ着地したことを画面全体で読ませる。content/layout auditでは `status_summary_bg.png` の寸法と `StatusSummaryBackground` ノードを検出する。

### 今回の追記: MEAL_RESULT 報酬カードフレーム

`reference/cooking_flow/02_meal_result_concept.png` の下段4カードは、食べた結果がEXP、初回ボーナス、合計EXP、次回効果へ分解される報酬の主役領域になっている。途中実装では `_compact_panel_box` ベースの汎用カードだったため、今回 `reward_card_frame.png` を追加し、`RewardCardBaseExp`、`RewardCardFirstBonus`、`RewardCardTotalExp`、`RewardCardNextEffect`、`RewardCardGrowth` としてMEAL_RESULT/EXP_GAINの報酬カードへ接続する。これにより、報酬カードは濃紺面、金縁、弱い放射光を持つ専用素材スロットになり、食事結果からEXP・成長へ渡るビートを文字だけでなくカードの存在感でも読ませる。content/layout auditでは `reward_card_frame.png` の寸法と各報酬カードノードの表示サイズを検出する。

### 今回の追記: MEAL_RESULT 今回の料理カード

`reference/cooking_flow/02_meal_result_concept.png` では、右側中央の「今回の料理」カードが、食べた料理をもう一度大きく見せてから報酬カードへ視線を送る中継点になっている。途中実装ではこのカードが汎用の濃紺パネルだったため、今回 `meal_dish_card_frame.png` を追加し、`MealDishCard` として接続する。左に料理写真の置き場、右に料理名と短いリアクションを置く構造を素材側へ持たせ、食事シーン、料理カード、報酬カード、EXP加算へ流れる読みを補強する。content/layout auditでは `meal_dish_card_frame.png` の寸法と `MealDishCard` の表示サイズを検出する。

### 今回の追記: LEVEL_UP 解放リボン

`reference/cooking_flow/04_level_up_overlay_concept.png` の赤い「新たな釣り場が解放！」帯は、能力上昇より一段強いアンロック報酬を示す山場になっている。途中実装では `_panel_box` ベースの赤い汎用パネルだったため、今回 `level_unlock_ribbon.png` を追加し、`LevelUnlockRibbonAsset` として接続する。左右の折り返し、金縁、星アクセントを素材側へ持たせ、Lv.5到達から港のぬし解放、さらにSTATUS_SUMMARYへ向かう報酬ピークを強める。content/layout auditでは `level_unlock_ribbon.png` の寸法と `LevelUnlockRibbonAsset` の表示サイズを検出する。

### 今回の追記: LEVEL_UP 能力上昇行フレーム

`reference/cooking_flow/04_level_up_overlay_concept.png` の能力上昇は、暗い報酬ダイアログの中でアイコン、旧値、矢印、新値が横一列に揃い、レベルアップの中核情報として読める。途中実装では能力行が `_panel_box` ベースの汎用濃紺パネルだったため、今回 `level_stat_row_frame.png` を追加し、`LevelStatRowEnergy` / `LevelStatRowReel` / `LevelStatRowTechnique` / `LevelStatRowFocus` として接続する。アイコン枠、値の区切り、矢印の着地点、増加値側の強調を素材側へ持たせ、王冠・リボン・解放カードと同じ報酬素材群として扱う。content/layout auditでは `level_stat_row_frame.png` の寸法と4行の表示サイズを検出する。

### 今回の追記: COOK_SELECT 魚行フレーム

`reference/cooking_flow/01_cook_select_concept.png` の左カラムは、所持魚が大きい魚絵、魚名、数量で横並びになり、料理素材を選ぶ導線として最初に読める。途中実装では魚行が `status_card_frame.png` の流用で、下部ステータスカードと同じ素材言語に寄っていたため、今回 `fish_row_frame.png` を追加し、`FishRowAji` / `FishRowSaba` / `FishRowKasago` / `FishRowMejina` / `FishRowIsaki` として接続する。左の選択ガター、中央の魚アート置き場、右の数量置き場を素材側へ持たせ、魚一覧を単なるデータ行ではなく調理素材カードとして扱う。content/layout auditでは `fish_row_frame.png` の寸法、6行魚リスト、表示中魚行の最小サイズを検出する。

### 今回の追記: COOK_SELECT 選択料理から詳細への矢印

`reference/cooking_flow/01_cook_select_concept.png` では、選択中の料理カードと右の大きな料理詳細カードの間に金色の矢印があり、料理カードを選んだ結果として右詳細が変わることを一目で示している。途中実装ではレシピカードの選択枠と右詳細がそれぞれ独立して見え、視線が中央から右へ流れる演出が弱かったため、今回 `recipe_to_detail_arrow.png` を追加し、`RecipeToDetailArrow` としてレシピ一覧と詳細カードの間へ接続する。選択中カードの金縁、矢印、右の料理写真をひと続きの導線として読ませ、`調理する`までの縦ストーリーを補強する。content/layout auditでは `recipe_to_detail_arrow.png` の寸法と `RecipeToDetailArrow` の表示サイズを検出する。

### 今回の追記: COOK_SELECT 選択レシピカードフレーム

`reference/cooking_flow/01_cook_select_concept.png` の選択中料理カードは、通常カードの色違いではなく外周の強い金色発光でアクティブ状態を示している。途中実装では `recipe_card_frame.png` の同一素材を色替えしていたため、今回 `recipe_selected_card_frame.png` を追加し、選択中かつ利用可能な `RecipeCard_salt_grill` へ適用する。これにより、中央グリッド内の主役カード、`RecipeToDetailArrow`、右詳細の大きな料理写真が一続きの視線導線として読める。追調整では選択カード内側の黄色い発光とGodot側の選択tintを抑え、料理写真・タイトル・星を汚さず、外周の金縁と角金具で選択状態を読ませる方針へ寄せた。content/layout auditでは `recipe_selected_card_frame.png` の寸法と `RecipeCard_salt_grill` の表示サイズを検出する。

### 今回の追記: COOK_SELECT 料理カードサムネイル額

`reference/cooking_flow/01_cook_select_concept.png` の料理カードは、カード内の料理写真が小さくても皿全体とカード額が読める。途中実装では右詳細用の横長料理画像をカード内へ直接 `STRETCH_KEEP_ASPECT_COVERED` で入れていたため、狭い縦カード内で魚や皿が大きく切れて仮配置に見えやすかった。今回 `recipe_dish_thumb_frame.png` を追加し、`RecipeDishThumb_*` / `RecipeDishImage_*` としてカード内へ接続する。横長料理写真は専用の淡い紙マット付き額に収め、カード写真、星、素材バッジの読み順を維持する。content/layout auditでは `recipe_dish_thumb_frame.png` の寸法、`RecipeDishThumb_salt_grill`、`RecipeDishImage_salt_grill`、接続テクスチャを検出する。

### 今回の追記: COOK_SELECT 料理カード素材バッジ

`reference/cooking_flow/01_cook_select_concept.png` の料理カード下部は、星評価と素材魚が小さいながらカード内の部品としてまとまっている。途中実装では素材魚アイコンと `×1` / `別素材` / `Lv.5` が紙面に直置きされ、仮UIの情報行に見えやすかった。今回 `recipe_material_strip_frame.png` を追加し、`RecipeMaterialBadge_*` として各料理カードの素材行をフレーム化する。カード下部は濃紺ソケットをやめた薄い紙スリップにして、選択可能カードでは素材魚だけを見せ、`別素材` / `Lv.5` は小さい状態表示として残す。content/layout auditでは `recipe_material_strip_frame.png` の寸法、代表カードの `RecipeMaterialBadge_*` の存在と表示サイズを検出する。

### 今回の追記: COOK_SELECT 調理ボタンフレーム

`reference/cooking_flow/01_cook_select_concept.png` の `調理する` は、右詳細カード内で最後に押す青い金縁ボタンとして明確に主役化されている。途中実装では `GoldButton` のテーマに鍋アイコンを描画していたため、周辺の木/金ボタンと同じ素材言語に見えやすかった。今回 `cook_button_frame.png` を追加し、`CookButton` の normal/hover/pressed/disabled/focus に接続する。濃紺面、金縁、左の鍋アイコン置き場を素材側へ持たせ、料理写真、材料/EXP/効果、食事結果予告、調理ボタンへ落ちる右詳細の縦ストーリーを固定する。content/layout auditでは `cook_button_frame.png` の寸法と `CookButton` の表示サイズを検出する。

### 今回の追記: COOK_SELECT 右詳細情報リボン

`reference/cooking_flow/01_cook_select_concept.png` の右詳細は、料理写真の下に `必要な材料`、`獲得EXP`、`次の釣行で得られる効果` が横長リボンとして積まれている。途中実装では `StyleBoxFlat` の行に左ラベルパネルを重ねていたため、設定フォームや入力欄のように見えやすかった。今回 `cook_detail_row_frame.png` を追加し、`CookDetailMaterialRow`、`CookDetailExpRow`、`CookDetailEffectRow` をこの素材へ接続する。左に濃色ラベルソケット、右に値が紙面へ直接乗る領域を持たせ、料理写真から材料、EXP、効果へ流れる読みを固定する。content auditでは3行が `cook_detail_row_frame.png` の `StyleBoxTexture` を使っていることまで検出する。
追調整では右側値領域の斜線と囲いを弱め、主値ラベルの白フチを外して濃いインクとして表示する。材料/EXP/効果の行が入力欄ではなく、紙面上の情報リボンとして読める状態を優先する。

### 今回の追記: COOK_SELECT 調理アクション帯

右詳細下部の注記、`CookActionCue`、`CookButton` が別々の部品に見えると、参照01の「最後に押す青い金縁CTA」へ視線が集まりにくい。今回 `cook_action_runway_frame.png` を追加し、`CookActionRunway` として右詳細下部へ接続する。上段に食事結果へ進む小キュー、下段に `CookButton` の着地点を持つ低背素材フレームにまとめ、材料/EXP/効果から調理ボタンへ落ちる縦ストーリーを固定する。content/layout auditでは `cook_action_runway_frame.png` の寸法、`CookActionRunway` の表示サイズ、`CookActionCue` と `CookButton` の存在を検出する。

### 今回の追記: COOK_SELECT 現在準備バー

`reference/cooking_flow/01_cook_select_concept.png` の下部バーは、現在のプレイヤー状態、効果中料理、クーラー/魚、所持金を紙カード群としてまとめ、画面の締めになっている。途中実装では `CurrentPrepBar` 相当の領域が平たい紙色パネルと汎用小カードに見え、完成素材の密度が弱かった。今回 `prep_summary_bar_frame.png` と `prep_summary_card_frame.png` を追加し、`CurrentPrepBar`、`CurrentPrepTitle`、`PrepSummaryCardLevel`、`PrepSummaryCardMeal`、`PrepSummaryCardFish`、`PrepSummaryCardMoney`、`CurrentPrepDetailButton` として接続する。content/layout auditでは2つの新規素材寸法、下部バー全体、4枚の準備カード、詳細ボタンの存在と表示サイズを検出する。

### 今回の追記: フロー主ボタンフレーム

`reference/cooking_flow/02_meal_result_concept.png`、`03_exp_gain_concept.png`、`04_level_up_overlay_concept.png`、`05_status_summary_concept.png` では、食事結果からEXPへ進む、EXPから成長/準備へ進む、LEVEL UPを閉じて成果確認へ進む、港へ戻る、という各状態の最後の操作が濃紺面と金縁の主ボタンとして締めになっている。途中実装では `RewardConfirmButton`、`LevelUpConfirmButton`、`StatusReturnButton` に描画式アイコンは入っているが、ボタン面そのものは汎用テーマ寄りだったため、今回 `flow_action_button_frame.png` を追加し、3種の主ボタンへ接続する。各ボタン左側の椀/EXP/王冠/アンカーの描画キューは保持しつつ、参照02〜05の「次の状態へ進む」操作を同じJRPGボタン素材で統一する。content/layout auditでは `flow_action_button_frame.png` の寸法と各主ボタンノードの表示サイズを検出する。

## 状態別ゲート

| 状態 | 実装 | 現在判定 | Freeze 条件 |
|---|---|---|---|
| `COOK_SELECT` | `src/ui/cooking_screen.gd` | P2: 専用カードUI・料理画像・魚アイコンに加え、魚行に選択マーカーと`fish_row_frame.png`、料理一覧に`recipe_grid_frame.png`、通常料理カードに`recipe_card_frame.png`、選択中料理カードに`recipe_selected_card_frame.png`、料理カード下部に`recipe_material_strip_frame.png`、右詳細に`dish_detail_frame.png`、主ボタンに`cook_button_frame.png`の9スライス枠を適用。料理一覧は3列化し、選択魚に非対応の料理は`素材違い`カードとして残すことで、参照の3x2料理カード密度へ近づけた。料理カードには星評価、`RecipeMaterialIcon_*` の素材魚アイコン、`RecipeMaterialBadge_*` の素材/状態バッジを追加し、選択中カードのEXP情報は右詳細の `CookDetailExpRow` へ集約する。素材違いカードは`別素材`、ロック中料理は料理名と`Lv.5`を出し、カード全体を暗く沈めず小さな状態表示で差を示す。レシピ一覧と右詳細の間には `recipe_to_detail_arrow.png` を使う `RecipeToDetailArrow` を追加し、選択料理から大きな料理写真へ視線が流れる参照01の導線を補強した。右詳細は料理写真を大きくし、材料/所持数、`EXP`、`効果`を横長リボンとして並べる構成へ変更。右詳細下部は `cook_action_runway_frame.png` を使う `CookActionRunway` へまとめ、`調理後は食事結果へ` の注記、`CookActionCue`、`CookButton` が一つの主アクション帯として読めるようにした。主ボタンは`CookButton`として命名し、ボタン内に鍋、炎、矢印を描画しつつ、今回 `cook_button_frame.png` をnormal/hover/pressed/disabled/focusへ接続して、参照01の青い金縁ボタンとして読めるようにした。参照01のトップ左にある木製`調理場`看板に合わせ、`cooking_title_banner.png`を追加してヘッダーのタイトルカードへ接続した。参照01の`所持している魚`と`料理を選ぶ`が青い装飾リボンとして列を区切っている点に合わせ、`cooking_section_ribbon.png`を追加し、`FishSectionRibbon` / `RecipeSectionRibbon` として魚一覧・料理一覧の見出しへ接続済み。魚行は `FishRowAji` / `FishRowSaba` / `FishRowKasago` / `FishRowMejina` / `FishRowIsaki` を含む6行表示へ寄せ、魚絵を横に広げて表示中の所持魚が素材カードとして読めることを監査対象にした。`cooking_room_bg.png` は中央カードと右詳細の間に参照01由来の港窓/植物帯を合成し、選択カードから詳細へ向かう接続部の暗い板感を減らした。ヘッダーにはプレイヤー/所持金などの小アイコンを追加済み。下部ステータス帯は `prep_summary_bar_frame.png` と `prep_summary_card_frame.png` を使う `CurrentPrepBar` / `PrepSummaryCard*` へ置き換え、Lv/料理/魚/所持金が紙カード群として読めるようにした。headless content/layout auditで星/素材表示、食事結果予告、`CookingTitleBanner`、`FishSectionRibbon`、`RecipeSectionRibbon`、`RecipeCard_salt_grill`、`RecipeMaterialBadge_*`、`RecipeMaterialIcon_*`、`RecipeToDetailArrow`、`FishRow*`、`CurrentPrepBar`、`PrepSummaryCard*`、`CookActionRunway`、`CookActionCue`、`CookButton`、3列/5カード以上、1280x720内のはみ出し/縦横クリップなしを確認済み。視覚スクショで密度確認が必要。 | 魚/料理/詳細/調理ボタンが1280x720で衝突せず、stock listに見えない。魚行と料理カードの選択/未選択/素材違い/ロック状態が識別でき、選択料理カードが中央グリッド内の主役として浮き、右詳細へ視線がつながり、最後の調理ボタンが主アクションとして読め、調理後に食事結果へ進むことが読める。トップ看板、列リボン、魚行フレーム、選択カードフレーム、素材バッジ、選択矢印、調理ボタンフレーム、調理アクション帯は専用素材として調理場の第一印象と3カラム構造を作る。 |
| `MEAL_RESULT` | `src/ui/components/cooking_reward_panel.gd` | P2: `02_meal_result_concept.png` に合わせ、左に食事シーン、右に「食べた！」バナーと今回の料理、下に基本EXP/初回/合計/次回効果の4報酬カードを置く専用レイアウトへ再構成。`MEAL_RESULT`ではEXPゲージと成長行を隠し、`食経験値へ進む`で次状態へ送ることで、食事の余韻とEXP加算を別ビートに分離する。報酬カードには種類別小アイコンを追加し、`次の釣行`カードには魚と上昇矢印の描画式ビジュアルを加え、バフ報酬を文字だけでなく絵でも読ませる。下部にはプレイヤーLv/効果中料理/クーラーボックス/所持金のステータス帯を追加。左カードの`PLAYER EATING`英字プレースホルダは削除し、食事中キャラ/椀/湯気の簡易ビジュアルへ置換。上部導線は`食事 -> EXP`のみ点灯し、次ステップを`2 EXP 次へ`として報酬カードから次状態への流れを固定する。今回、実フローでは`cook_and_eat()`後の進行結果を保持したまま、MEAL_RESULT用にEXP加算前のLv/EXP、調理後の魚総数、所持金を`status_snapshot`として渡し、下部ステータス帯が`Lv.4 130/150 EXP`の食事直後状態を示すようにした。主ボタンは`RewardConfirmButton`として命名し、椀からEXP玉へ進む描画キューを表示する。追加比較では、参照02の左側が「食べる人物、テーブル、大皿料理、湯気」の一体シーンとして読めるのに対し、途中実装は人物と料理表示が分離して見えるため、`meal_table_spread.png` と `MealTableSpread` を追加して食卓前景を専用素材化する。headless content/layout auditでプレースホルダ非表示、EXP加算前ステータス、connector mode、`RewardConfirmButton`、1280x720収まりを確認済み。視覚スクショ未確認。 | 食べた料理、基本EXP、初回ボーナス、合計獲得、バフ、食後の現在準備が本文を読まなくても追える。EXPゲージ/レベルアップ表示は次状態に送られ、MEAL_RESULT内に混ざらない。左シーンは食卓の一枚絵として読める。 |
| `EXP_GAIN` | `src/ui/components/cooking_reward_panel.gd` | P2: `MEAL_RESULT`後に別オーバーレイとして開くEXP加算状態。右ペインを料理詳細カードからEXPフォーカスカードへ差し替え、巨大`+EXP`、`EXP before -> after`、明るいゲージ、キャラメッセージをまとめて主役化した。左カードの`DISH POWER`英字プレースホルダは削除し、料理から食経験値の力が出る簡易ビジュアルへ置換。さらにEXP時だけ表示する`ExpEnergyTrail`を左カードと右カードの間へ追加し、料理からゲージへ力が流れる見え方を補強。左の食べた料理カード内には初回時のみ`初回ボーナス +20 EXP`を出し、EXP報酬の原因が左カード内でも読めるようにした。右端には`次の釣行で効果！`カードを追加し、食事で得たバフが次回釣行に接続されることを上段で明示した。今回、`RewardStageBackground`を保持する構成へ変更し、MEAL_RESULTでは`meal_scene_bg.png`、EXP_GAIN/EXP_GAIN_LEVELUPでは`exp_stage_bg.png`へ切り替える。中央EXPフォーカスカードは`exp_burst_frame.png`をStyleBoxTextureとして使う`ExpBurstFrame`へ変更し、参照03の巨大`+EXP`背面にある放射バーストとゲージ台座を素材化した。EXPフォーカス内のメッセージを`ExpMessagePanel`へ組み替え、`player_exp_message_pose.png`の`ExpMessagePortrait`と一言を横並びにすることで、食べた料理がプレイヤーの成長に変わった瞬間を絵でも読めるようにした。非レベルアップEXPは`準備へ戻る`ボタンで`COOK_SELECT`の`現在の準備`サマリーへ戻るため、レベルアップしない食事も完結感を持って通常調理へ戻れる。レベルアップEXPでは`解放を見る`系ボタン内にEXP玉から星/王冠へ進む描画キューを出し、非レベルアップEXPではEXP玉からサマリーカードへ戻る描画キューを出す。上部導線は通常EXPなら`食事 -> EXP`金、`EXP -> 成長進行`シアン、レベルアップなら`EXP -> 成長解放`赤金で区別し、headless content/layout/smokeで初回ボーナス表示、完了ボタン、`RewardStageBackground`、`ExpBurstFrame`、`ExpMessagePanel`、`RewardConfirmButton`、connector modeも確認済み。視覚スクショ未確認。 | EXPメーターが主役で、レベルアップしない場合も完結感がある。レベルアップする場合は次の報酬演出へ進む理由と、食後の現在準備が明確に読める。食事結果とEXP加算は背景からも別ビートとして読める。 |
| `LEVEL_UP_OVERLAY` | `src/ui/components/level_up_panel.gd` | P2: `04_level_up_overlay_concept.png` に合わせ、パネル幅を広げ、能力上昇を2列ステータスに再構成。赤い`新たな釣り場が解放！`リボン、王冠/メダル/釣り場サムネ風カード、紙吹雪/星/強めの金色光線を追加した。タイトル帯は王冠・左右ラウレル・大型`LEVEL UP!`の一体構成へ強化し、赤リボンとボスメダルも大きくした。食経験値が成長に変わった副題、`成長の証`、`挑戦解放`、`次の目標：港のぬし`、`新釣り場`を表示し、Lv.5報酬が次の行動につながることを強めた。EXP報酬から遷移するときは背面を`現在の準備`サマリーへ戻してからLEVEL_UPを開く。OKボタン文言を`OK  成果確認へ`へ変更し、閉じた後のSTATUS_SUMMARY接続を画面内の読みとして補強した。今回、能力上昇行の`HP/PWR/TEC/FOC`文字バッジを、最大体力/巻力/技量/集中力に対応するハート/リール/剣/照準の描画アイコンへ変更し、さらに解放カード内へ5枚の小カードに流れる`LevelToSummaryCue`を追加して、レベルアップ後に成果確認へ着地する流れを視覚化した。加えて`level_crown.png`、`level_laurel_left.png`、`level_laurel_right.png`、`level_unlock_medallion.png`、`level_unlock_spot.png`を接続し、参照04の王冠/ラウレル/ボスメダル/海辺サムネイルを本番素材へ差し替えられるスロットにした。OKボタンは`LevelUpConfirmButton`として命名し、ボタン左側に王冠、矢印、成果カードを直接描画することで、通常ボタンではなくレベルアップ後の成果確認導線として固定した。英字仮ラベルはcontent auditで非表示を確認済み。headless content/layout/smokeで1280x720収まり、背面サマリー復帰、OK後導線文言、レベルアップ素材ノードを確認済み。視覚スクショ未確認。 | レベル遷移、能力上昇、ぬし解放が最も強い報酬瞬間として読める。能力上昇は文字だけでなくアイコンでも種別が分かる。閉じ操作の後に成果確認へ進むことも読める。 |
| `STATUS_SUMMARY` | `src/ui/components/cooking_status_panel.gd` | P2: `05_status_summary_concept.png` に合わせ、中央モーダルから全画面の専用サマリー状態へ再構成。上部に`ステータス`ヘッダーとLv/EXPゲージ、中央にプレイヤー/効果中料理/クーラーボックス/所持金/プレイ時間の5大型カード、下部にメッセージバーと`港へ戻る`ボタンを配置。効果中料理は料理画像・効果名・次回発動文で表示し、他4カードとフッターの英字プレースホルダは専用描画ビジュアルへ置換した。背景には港/厨房の横長シーン描画を重ね、ヘッダー左右には船舵/錨の装飾を追加した。レベルアップOK後に自動表示され、Lv.5到達時はフッターで`港のぬしに挑めます`を表示するため、成長結果の確認と次行動への着地点として機能する。入場演出をフェードのみから、ヘッダー、5カード、フッターの順に少しずつ明るく立ち上がる構成へ変更し、`港へ戻る`はフェードアウト完了後に`harbor`へnavigateするようにした。プレイヤーカードの能力行を色付き小パネルから、体力/攻撃力/防御力/素早さ/運に対応したハート/剣/盾/ブーツ/クローバーの小アイコン描画へ変更し、ヘッダー右側へ`StatusHeaderPlayerBadge`を追加して、参照05のプレイヤー顔＋Lv/EXPヘッダーに近づけた。今回、クーラーボックス、所持金、プレイ時間カードの中央絵を共通アイコンシートから専用大判アセット`StatusCoolerArt` / `StatusMoneyArt` / `StatusClockArt`へ切り替え、参照05の5カードが「成果カード」として見える密度へ寄せた。効果中料理カードの下部説明枠には剣と上昇矢印の`StatusMealEffectCue`を追加した。戻りボタンは`StatusReturnButton`として命名し、ボタン左側にアンカーを直接描画して、参照05の港帰還ボタンに近づけた。headless content/layout/smokeでプレースホルダ非表示、Lv.5後フッター文言、1280x720内のはみ出し/縦横クリップなし、harbor遷移、3つの専用大判アートノードを確認済み。視覚スクショ未確認。 | 5カードが1280x720で衝突せず、Lv/EXP、能力、効果中料理、クーラー、所持金、プレイ時間が専用サマリー画面として読める。ヘッダーにもプレイヤー顔とLv/EXPがまとまり、料理効果と能力行は文字だけでなくアイコンでも種別が分かる。LEVEL_UP後に、成果確認カードへ自然に視線が移り、港へ戻る操作で余韻を残してフローが完結する。 |

## 検証ログ

- `python3 tools/generate_cooking_showcase_assets.py`
  - 目的: `assets/showcase/cooking/` の置き換え可能な料理ショーケース用アセットを再生成する。
  - 結果: 成功。
  - 範囲: `cooking_room_bg.png` と `meal_scene_bg.png` の生成ロジックを更新し、港の窓、調理台、棚、食器、ランタン光、湯気を増やした。さらに `exp_stage_bg.png` をEXP_GAIN専用の暗い厨房＋金/シアンバースト背景として追加し、参照03のEXPステージに寄せた。`fish_icon_sheet.png` をアジ/メジナ/カサゴ/イサキ/サバ/ぬしで形・色・模様が分かれる1列6行シートへ更新した。`fish_row_frame.png` をCOOK_SELECT左カラムの所持魚行フレームとして追加し、選択ガター、魚絵の置き場、数量エリアを素材側に持たせた。`cooking_title_banner.png` をCOOK_SELECT左上の木製タイトル看板として追加し、参照01の厨房入口感へ寄せた。`cooking_section_ribbon.png` は魚一覧と料理一覧の青い列見出しリボンとして追加し、参照01の3カラム見出しが通常ラベルに見えないようにする。`recipe_selected_card_frame.png` はCOOK_SELECTの選択中料理カード専用の金色発光フレームとして追加し、通常料理カードとの状態差を素材側で強める。`recipe_to_detail_arrow.png` はCOOK_SELECT中央の選択料理から右詳細へ流れる金色矢印として追加し、参照01の選択カードと詳細カードの接続を素材化する。`cook_button_frame.png` はCOOK_SELECT右詳細の主ボタン用フレームとして追加し、参照01の青い金縁ボタンと左アイコン置き場を素材側で固定する。`player_eating_pose.png` と `player_status_portrait.png` を追加し、食事結果の左キャラとステータス要約のプレイヤー肖像へ接続した。`meal_table_spread.png` はMEAL_RESULT左側の食卓前景として追加し、参照02の大皿料理、湯気、卓上小物が一体に見えるシーンへ寄せる。`player_exp_message_pose.png` はEXP_GAIN内のキャラメッセージ用素材として追加し、参照03の「料理で力が入った一言」へ寄せる。`status_cooler_art.png`、`status_money_art.png`、`status_clock_art.png` はステータス要約のクーラー/所持金/プレイ時間カード用大判素材として追加し、参照05の5カード中央絵へ寄せる。`meal_banner_frame.png` は食事結果の大見出し用の紙バナーとして追加し、参照02の主役見出しに近づける。`exp_burst_frame.png` はEXP_GAIN中央の放射バースト/ゲージ台座用素材として追加し、参照03の主役演出へ寄せる。`level_crown.png`、`level_laurel_left.png`、`level_laurel_right.png`、`level_unlock_medallion.png`、`level_unlock_spot.png` はLEVEL_UP_OVERLAY用の王冠/ラウレル/ボスメダル/海辺サムネイル素材として追加し、参照04の報酬ピークをコード描画だけにしない。`cooking_icon_sheet.png` はEXP、初回、合計、効果、プレイヤー、クーラー、所持金、時計、アンカー、成長王冠の10セル構成へ拡張し、報酬カードとステータスカードの共通素材として接続した。再生成後の背景PNGはいずれも1280x720、タイトル看板は420x110、列見出しリボンは520x72、魚シートは192x528、魚行フレームは340x82、選択カードフレームは280x220、選択矢印は96x220、調理ボタンフレームは360x82、人物アセットは360x280/240x240、食卓前景は420x190、EXPメッセージ素材は180x130、ステータス大判素材は各260x170、バナーは760x128、EXPバーストは760x220、レベルアップ王冠は220x96、ラウレルは140x120、メダルは150x150、釣り場サムネイルは260x110、共通アイコンシートは960x96で、`validate_project.sh` のGodot再インポートで読込確認済み。
  - 追記: `next_effect_art.png` をEXP_GAIN/EXP_GAIN_LEVELUP右カードの「次の釣行で効果！」用アセットとして追加。寸法は280x120で、魚、上昇矢印、緑/シアンの発光を1枚絵として持つ。`NextEffectArt` ノードとして接続し、content/layout auditで存在と最小サイズを固定する。
  - 追記: `status_summary_bg.png` をSTATUS_SUMMARY専用背景として追加。寸法は1280x720で、上部ヘッダー帯、港側の窓、厨房側の棚、5カード背面の着地点、下部フッター帯を1枚絵として持つ。`StatusSummaryBackground` ノードとして接続し、content/layout auditで存在と最小サイズを固定する。
  - 追記: `reward_card_frame.png` をMEAL_RESULT/EXP_GAINの報酬カード用フレームとして追加。寸法は360x150で、濃紺面、金縁、弱い放射光、スタッズを1枚絵として持つ。`RewardCardBaseExp`、`RewardCardFirstBonus`、`RewardCardTotalExp`、`RewardCardNextEffect`、`RewardCardGrowth` として接続し、content/layout auditで存在と最小サイズを固定する。
  - 追記: `meal_dish_card_frame.png` をMEAL_RESULTの「今回の料理」カード用フレームとして追加。寸法は760x170で、左の料理写真枠、右の料理名/リアクション領域、魚スタンプ、金縁を1枚絵として持つ。`MealDishCard` として接続し、content/layout auditで存在と最小サイズを固定する。
  - 追記: `level_unlock_ribbon.png` をLEVEL_UP_OVERLAYの解放リボン用素材として追加。寸法は760x72で、赤いリボン本体、左右の折り返し、金縁、星アクセントを1枚絵として持つ。`LevelUnlockRibbonAsset` として接続し、content/layout auditで存在と最小サイズを固定する。
  - 追記: `level_stat_row_frame.png` をLEVEL_UP_OVERLAYの能力上昇行用素材として追加。寸法は420x76で、アイコン枠、値の区切り、矢印、増加値側の強調を1枚絵として持つ。`LevelStatRowEnergy` / `LevelStatRowReel` / `LevelStatRowTechnique` / `LevelStatRowFocus` として接続し、content/layout auditで存在と最小サイズを固定する。
  - 追記: `recipe_to_detail_arrow.png` をCOOK_SELECTの選択料理から右詳細へ向かう矢印素材として追加。寸法は96x220で、金色矢印、外縁、発光、星アクセントを1枚絵として持つ。`RecipeToDetailArrow` として接続し、content/layout auditで存在と最小サイズを固定する。
  - 追記: `recipe_selected_card_frame.png` をCOOK_SELECTの選択中料理カード用素材として追加。寸法は280x220で、金色発光、強い外枠、角飾り、星アクセントを1枚絵として持つ。`RecipeCard_salt_grill` の選択状態に接続し、content/layout auditで素材と表示サイズを固定する。
  - 追記: `recipe_dish_thumb_frame.png` をCOOK_SELECT料理カード内のサムネイル額として追加。寸法は260x170で、淡い紙マット、金縁、角飾りを1枚絵として持つ。`RecipeDishThumb_*` / `RecipeDishImage_*` として接続し、カード内の料理写真が大きく切れた状態へ戻らないようcontent/layout auditで固定する。
  - 追記: `recipe_material_strip_frame.png` をCOOK_SELECTの料理カード下部素材バッジとして追加。寸法は240x54で、薄い紙スリップ、角金具、下罫線を1枚絵として持つ。`RecipeMaterialBadge_*` として接続し、content/layout auditで代表カードの存在と表示サイズを固定する。
  - 追記: `cook_detail_row_frame.png` をCOOK_SELECT右詳細の材料/EXP/効果行用素材として追加。寸法は560x46で、左ラベルソケット、右の紙面値領域、金具、紙テクスチャを1枚絵として持つ。`CookDetailMaterialRow`、`CookDetailExpRow`、`CookDetailEffectRow` として接続し、content auditでStyleBoxTexture接続まで固定する。
  - 追記: `cook_button_frame.png` をCOOK_SELECT右詳細の主ボタン用素材として追加。寸法は360x82で、濃紺面、金縁、左アイコン置き場、ハイライトを1枚絵として持つ。`CookButton` の normal/hover/pressed/disabled/focus へ接続し、content/layout auditで必須素材と表示サイズを固定する。
  - 追記: `cook_action_runway_frame.png` をCOOK_SELECT右詳細下部の調理アクション帯として追加。寸法は560x88で、上段の食事結果キュー、下段の濃紺CTAソケット、紙面/金具を1枚絵として持つ。`CookActionRunway` として接続し、content/layout auditで必須素材と表示サイズを固定する。
  - 追記: `prep_summary_bar_frame.png` と `prep_summary_card_frame.png` をCOOK_SELECT下部の現在準備バー用素材として追加。寸法は1280x92と340x62で、全体の紙/金具トレイと左アイコンポケット付き小カードを1枚絵として持つ。`CurrentPrepBar` と `PrepSummaryCard*` として接続し、content/layout auditで必須素材と表示サイズを固定する。
  - 追記: `flow_action_button_frame.png` をMEAL_RESULT/EXP_GAIN/LEVEL_UP_OVERLAY/STATUS_SUMMARYの主ボタン用素材として追加。寸法は380x88で、濃紺面、金縁、左メダリオン、ハイライトを1枚絵として持つ。`RewardConfirmButton`、`LevelUpConfirmButton`、`StatusReturnButton` の normal/hover/pressed/disabled/focus へ接続し、content/layout auditで必須素材と表示サイズを固定する。
  - 追記: content auditを強化し、`CookButton` の normal style が `cook_button_frame.png` の `StyleBoxTexture` であること、`RewardConfirmButton` / `LevelUpConfirmButton` / `StatusReturnButton` の normal style が `flow_action_button_frame.png` の `StyleBoxTexture` であることを検出する。これにより、主ボタンが存在していても汎用テーマや `StyleBoxFlat` に戻った場合はheadlessで失敗する。
  - 追記: 参照01/02/03/05で主役になる料理ビジュアルがテキストだけに戻らないよう、`SelectedDishFeatureImage`、`RewardDishFeatureImage`、`MealTableSpread.dish_texture`、`StatusMealDishImage` を名前付き契約として追加した。content auditでは `dish_feature_aji_shioyaki.png` が実際に接続されていることを検出し、layout auditでは各状態の大判料理表示が1280x720内で最小サイズを満たすことを確認する。
  - 追記: 参照02の左側にある「食べる人物＋食卓」シーンが料理皿だけに退行しないよう、食事中キャラ描画を `MealSceneActor` として名前付き契約にした。`MealTableSpread` と合わせてcontent/layout auditで存在と最小サイズを確認し、食事結果が単なる報酬フォームではなく食べる場面として読めることを維持する。
  - 追記: 参照01の右詳細カードにある横長の `必要な材料`、`獲得EXP`、`次の釣行で得られる効果` の3行が6タイル風や説明文だけに戻らないよう、`CookDetailMaterialRow`、`CookDetailExpRow`、`CookDetailEffectRow` を名前付き契約にした。content/layout auditで存在と最小サイズを確認し、さらに表示ラベルも短い `材料` / `EXP` / `効果` ではなく参照01に近い全文ラベルとして固定する。料理写真から材料、EXP、次回効果、調理ボタンへ流れる縦ストーリーを維持する。
  - 追記: `STATUS_SUMMARY` は参照05の独立成果確認画面として、`StatusCardPlayer`、`StatusCardMeal`、`StatusCardCooler`、`StatusCardMoney`、`StatusCardPlayTime` の5カードを名前付き契約にした。content auditでは `CookingStatusPanel` 内にこの5カードがちょうど存在し、`RecipeGrid`、`RecipeSectionRibbon`、`RecipeToDetailArrow`、`CookButton`、`CookActionCue`、`FishSectionRibbon` が混入していないことを検出する。背面の調理画面ノードはオーバーレイ下に残るため、監査対象は `CookingStatusPanel` 自体に限定する。
  - 追記: 参照05の上部ヘッダーを、`StatusTitle`、`StatusHeaderExpBox`、`StatusHeaderLevel`、`StatusHeaderExpBar`、`StatusHeaderExpValue` として名前付き契約にした。`StatusHeaderPlayerBadge` と合わせてcontent/layout auditで存在と最小サイズを確認し、成果確認画面の最初の読みである「ステータス」タイトルとLv/EXPヘッダーが消える退行を防ぐ。
  - 追記: `MEAL_RESULT` と `EXP_GAIN` は同じ `CookingRewardPanel` 内の切り替えだが、参照02/03を混ぜないことをcontent auditで固定した。`MEAL_RESULT` では `ExpBurstFrame`、`NextEffectArt`、`RewardCardGrowth` が可視にならないこと、`EXP_GAIN` / `EXP_GAIN_LEVELUP` では `MealDishCard` と `RewardDishFeatureImage` が可視にならないことを検出する。これにより、食事結果の料理カードとEXPゲージ演出が同時に出る退行を防ぐ。
  - 追記: `MEAL_RESULT` / `EXP_GAIN` / `EXP_GAIN_LEVELUP` の主見出しを、`MealResultBanner` / `MealResultTitle` と `ExpGainBanner` / `ExpGainTitle` として状態別に名前付き契約にした。content/layout auditで存在とサイズを確認し、参照02の「食べた！」バナーと参照03の「食経験値を獲得！」タイトルが汎用見出しや別状態の見出しへ戻る退行を防ぐ。
  - 追記: `LEVEL_UP_OVERLAY` は参照04の報酬ピークとして、暗転、中央ダイアログ、巨大タイトル、レベル遷移を名前付き契約にした。`LevelUpDimmer`、`LevelUpDialog`、`LevelUpTitleBand`、`LevelUpTitle`、`LevelUpLevelLine`、`LevelUpSourceLine` を追加し、content/layout auditで存在と最小サイズを検出する。これにより、レベルアップ演出が通常パネル相当に弱くなる退行を防ぐ。
  - 追記: `MEAL_RESULT` / `EXP_GAIN` / `EXP_GAIN_LEVELUP` 下部の現在準備帯を、`RewardStatusStrip`、`RewardStatusLevelCard`、`RewardStatusMealCard`、`RewardStatusCoolerCard`、`RewardStatusMoneyCard` として名前付き契約にした。content/layout auditで存在と最小サイズを検出し、食事結果やEXP加算がプレイヤーLv、効果中料理、クーラー、所持金へ反映されている文脈を保つ。
- `tools/cooking_verify.sh`
  - 目的: 調理ショーケースのheadlessゲートを一括実行する。内容監査、1280x720レイアウト監査、実フローsmokeを順に走らせる。
  - コマンド: `tools/cooking_verify.sh`
  - 結果: 成功。
  - 範囲: `tools/cooking_content_audit.tscn`、`tools/cooking_layout_audit.tscn`、`tools/cooking_flow_smoke.tscn`。
- `HOME=/private/tmp/tsuri_home tools/validate_project.sh`
  - 結果: 成功。
  - 範囲: Godot editor import と短時間起動。GDScriptロード、autoload、シーン初期化の大枠を確認。
- `HOME=/private/tmp/tsuri_home "/Applications/Godot.app/Contents/MacOS/Godot" --headless --path ... res://tools/cooking_preview.tscn`
  - 結果: 失敗。
  - 理由: headless/dummy renderer では `SubViewport.get_texture().get_image()` が null になる既知制約。`tools/cooking_preview.gd` はdisplay driver名だけで早期拒否せず、実際に `get_image()` を試してnull/empty画像なら明示診断を出す。
  - 判定: 視覚スクショは未取得。通常Godot起動可能な環境で `/tmp/tsuri_cooking_*.png` を再生成して比較する。
- `HOME=/private/tmp/tsuri_home "/Applications/Godot.app/Contents/MacOS/Godot" --path ... res://tools/cooking_preview.tscn`
  - 結果: 失敗。
  - 理由: この実行環境では通常Godot起動が即時に exit 134 で終了する。
  - 判定: 通常描画スクショはこの環境では未取得。headless layout auditとsmokeで先に機械的なP1を潰す。
- `HOME=/private/tmp/tsuri_home "/Applications/Godot.app/Contents/MacOS/Godot" --display-driver macos --rendering-driver dummy --audio-driver Dummy --path ... res://tools/cooking_preview.tscn`
  - 結果: 失敗。
  - 理由: 通常起動と同じく即時に exit 134 で終了する。
  - 判定: macOS display driver + dummy renderer でも `/tmp/tsuri_cooking_*.png` は生成されない。
- `HOME=/private/tmp/tsuri_home "/Applications/Godot.app/Contents/MacOS/Godot" --display-driver macos --rendering-driver opengl3 --rendering-method gl_compatibility --audio-driver Dummy --disable-crash-handler --log-file /tmp/tsuri_cooking_preview_godot.log --path ... res://tools/cooking_preview.tscn`
  - 結果: 失敗。
  - 理由: 即時に exit 134 で終了し、`/tmp/tsuri_cooking_preview_godot.log` も生成されなかった。
  - 判定: renderer切り替えやcrash handler無効化では、この環境の通常描画キャプチャ制約は回避できない。
- `HOME=/private/tmp/tsuri_home "/Applications/Godot.app/Contents/MacOS/Godot" --headless --write-movie /tmp/tsuri_cooking_movie.png --quit-after 10 --fixed-fps 10 --path ... res://tools/cooking_preview.tscn`
  - 結果: 失敗。
  - 理由: movie makerもheadless/dummy rendererでは実フレームを生成できず、同じnull texture経路に入る。
  - 判定: `--write-movie` はこの環境での代替スクショ経路として使えない。
- `python3 tools/cooking_reference_report.py`
  - 目的: `reference/cooking_flow/*_concept.png` と `/tmp/tsuri_cooking_*.png` を状態別に横並び表示するHTML比較レポートを生成する。
  - 結果: 成功。
  - 出力: `/tmp/tsuri_cooking_reference_report.html`。
  - 判定: この環境ではキャプチャPNGが未生成のため、レポート上では5状態すべてがmissing表示になる。通常描画可能な環境で `tools/cooking_preview.gd` 実行後に再生成すれば、参照5枚との目視比較に使える。
- `python3 tools/cooking_visual_qa_check.py --allow-missing`
  - 目的: 参照PNGの存在/形式を確認し、キャプチャ未生成を許容したうえでHTML比較レポートを再生成する。
  - 結果: 成功。
  - 判定: この環境では5状態のキャプチャmissingを許容してツール自体を検証した。通常描画可能な環境では `--allow-missing` を外し、`/tmp/tsuri_cooking_*.png` が5枚すべて1280x720 PNGとして存在し、透明/単色/極端に色数の少ない空キャプチャではないことを最終ゲートにする。5枚が揃った場合は `/tmp/tsuri_cooking_capture_manifest.json` も検査し、各PNGが `COOK_SELECT` / `MEAL_RESULT` / `EXP_GAIN` / `LEVEL_UP_OVERLAY` / `STATUS_SUMMARY` として保存前に検証された証跡を要求する。参照PNGは原寸のまま扱い、寸法一致は要求しない。
- `python3 tools/cooking_visual_qa_check.py`
  - 結果: 失敗。
  - 理由: `/tmp/tsuri_cooking_select.png`、`/tmp/tsuri_cooking_result.png`、`/tmp/tsuri_cooking_exp.png`、`/tmp/tsuri_cooking_levelup.png`、`/tmp/tsuri_cooking_status.png` が未生成。
  - 判定: 通常描画環境でのキャプチャ生成が完了するまで、視覚QAゲートは未通過として扱う。
- `tools/cooking_visual_qa.sh`
  - 目的: 古い `/tmp/tsuri_cooking*.png` と `/tmp/tsuri_cooking_capture_manifest.json` を消してから、通常描画の `tools/cooking_preview.gd` で5状態を撮影し、成功時に `tools/cooking_visual_qa_check.py` の厳格ゲートとHTML比較レポート更新を一括実行する。
  - 結果: 失敗（exit 134）。
  - 理由: 通常Godot起動が exit 134 で終了する既知制約に当たる。失敗時も `--allow-missing` で `/tmp/tsuri_cooking_reference_report.html` を更新し、missing captureを明示することを確認した。
  - 判定: 通常描画可能な環境での最終視覚QA用コマンドとして採用する。この環境では非ゼロ終了を正しい未通過シグナルとして扱う。`tools/cooking_preview.gd` は Lv.4、EXP 130、所持金 1250G、プレイ時間 03:25:45、魚4種の固定シードから開始し、`/tmp/tsuri_cooking_result.png` をEXP加算前ステータス付きの `MEAL_RESULT`、`/tmp/tsuri_cooking_exp.png` を参照03向けの非レベルアップ `EXP_GAIN` として撮り、その後に別のレベルアップEXP報酬を閉じてLEVEL_UP、OK後にSTATUS_SUMMARYへ進む実遷移で `/tmp/tsuri_cooking_levelup.png` と `/tmp/tsuri_cooking_status.png` を撮る。保存前には `COOK_SELECT` の現在準備、`MEAL_RESULT`、`EXP_GAIN`、`LEVEL_UP_OVERLAY`、`STATUS_SUMMARY` が実際に出ているかを確認し、状態取り違えのスクショを残さない。
- `tools/cooking_flow_smoke.tscn`
  - 目的: headlessで各状態のControl構築を検証するためのスモークシーン。
  - コマンド: `HOME=/private/tmp/tsuri_home "/Applications/Godot.app/Contents/MacOS/Godot" --headless --path ... res://tools/cooking_flow_smoke.tscn`
  - 結果: 成功。
  - 範囲: `COOK_SELECT`、参照03向けの初回ボーナスあり・非レベルアップ `+40 EXP` 報酬、非レベルアップEXP完了後の`現在の準備`復帰、レベルアップ報酬、報酬OK後の`LEVEL_UP_OVERLAY`接続、LEVEL_UP背面の`現在の準備`復帰、実際の`PlayerProgress.cook_and_eat()`経由での魚消費/初回料理記録/食事バフ/Lv.5到達/食事結果→EXP結果→レベルアップ→ステータス要約→港帰着、単体レベルアップ、ステータス要約のControl構築、`港へ戻る`から`harbor`へのnavigate、短時間実行。
  - 追記: `CookButton`、`RewardConfirmButton`、`LevelUpConfirmButton`、`StatusReturnButton` は `preview_accept_*` や直接メソッド呼びではなく、headless上で実際の `pressed` シグナルを発火して遷移を検証する。これにより、調理選択→食事結果、食事結果→EXP、EXP→通常準備/LEVEL_UP、LEVEL_UP→STATUS_SUMMARY、STATUS_SUMMARY→港遷移のボタン配線が切れた場合もsmokeで検出する。
  - 追記: 実調理フローでは `CookButton` 押下後に `MEAL_RESULT`、食事結果の `RewardConfirmButton` 押下後に `EXP_GAIN_LEVELUP`、EXP結果の `RewardConfirmButton` 押下後に `LEVEL_UP_OVERLAY`、`LevelUpConfirmButton` 押下後に `STATUS_SUMMARY` を踏み、最後に `StatusReturnButton` から `harbor` へnavigateし、ステータス要約オーバーレイが閉じて残留しないことを状態名、route、overlay消滅で検出する。非レベルアップ報酬は `EXP_GAIN` として完結し、`準備へ戻る`で現在準備サマリーに戻ることを検出する。
  - 追記: 報酬、レベルアップ、ステータス要約の各オーバーレイは、表示中の状態では該当スクリプトのインスタンスが1枚だけ存在し、閉じた後は0枚になることをsmokeで数える。これにより、食事結果、EXP、LEVEL_UP、STATUS_SUMMARYが重なったまま残る退行を防ぐ。
  - 追記: smokeはlayout auditと同じ1280x720固定ステージで構築し、各主ボタンの押下前に `visible`、非ゼロサイズ、1280x720ステージ内への完全な収まり、enabled状態を確認する。これにより、ボタンのシグナル配線だけでなく、リファレンス画面上で実際に押せる位置に主導線が残っていることをheadlessで固定する。
- `tools/cooking_layout_audit.tscn`
  - 目的: headlessで5状態を1280x720固定ステージに構築し、画面外はみ出し、非正サイズ、ラベル縦クリップ、欠落テクスチャを検出する。
  - コマンド: `HOME=/private/tmp/tsuri_home "/Applications/Godot.app/Contents/MacOS/Godot" --headless --path ... res://tools/cooking_layout_audit.tscn`
  - 結果: 成功。
  - 範囲: `COOK_SELECT`、`EXP_GAIN`、`EXP_GAIN_LEVELUP`、`MEAL_RESULT`、`LEVEL_UP_OVERLAY`、`STATUS_SUMMARY`。`EXP_GAIN_LEVELUP` はLv.5到達直前のEXP加算パネルが720p内に収まることを追加確認する小状態。折り返しなしラベルの横幅不足も検出する。さらに `CookingTitleBanner`、`FishSectionRibbon`、`RecipeSectionRibbon`、`RecipeToDetailArrow`、`SelectedDishFeatureImage`、`CookDetailMaterialRow`、`CookDetailExpRow`、`CookDetailEffectRow`、`FishRowAji`、`FishRowSaba`、`FishRowKasago`、`FishRowMejina`、`CookActionRunway`、`CookActionCue`、`CookButton`、`RewardStageBackground`、`MealTableSpread`、`RewardDishFeatureImage`、`ExpEnergyTrail`、`ExpBurstFrame`、`ExpMessagePanel`、`ExpMessagePortrait`、`RewardBuffSignal`、`RewardStatusStrip`、`RewardStatusLevelCard`、`RewardStatusMealCard`、`RewardStatusCoolerCard`、`RewardStatusMoneyCard`、`RewardConfirmButton`、`LevelUpDimmer`、`LevelUpDialog`、`LevelUpTitleBand`、`LevelUpTitle`、`LevelUpLevelLine`、`LevelUpSourceLine`、`LevelCrownAsset`、`LevelLaurelLeftAsset`、`LevelLaurelRightAsset`、`LevelUnlockMedallionAsset`、`LevelUnlockSpotAsset`、`LevelToSummaryCue`、`LevelUpConfirmButton`、`StatusHeaderPlayerBadge`、`StatusCardPlayer`、`StatusCardMeal`、`StatusCardCooler`、`StatusCardMoney`、`StatusCardPlayTime`、`StatusMealDishImage`、`StatusCoolerArt`、`StatusMoneyArt`、`StatusClockArt`、`StatusMealEffectCue`、`StatusReturnButton` が該当状態で可視かつ最小サイズを満たすことも確認する。
- `tools/cooking_content_audit.tscn`
  - 目的: headlessで5状態を構築し、料理名、材料、EXP、食事効果、成長予告、Lv.5解放、ステータス要約などの必須表示テキストが画面上に存在することを検出する。
  - コマンド: `HOME=/private/tmp/tsuri_home "/Applications/Godot.app/Contents/MacOS/Godot" --headless --path ... res://tools/cooking_content_audit.tscn`
  - 結果: 成功。
  - 範囲: `COOK_SELECT`、`EXP_GAIN`、`EXP_GAIN_LEVELUP`、`MEAL_RESULT`、`LEVEL_UP_OVERLAY`、`STATUS_SUMMARY`。必須料理アセットが存在し、背景/EXP専用背景/タイトル看板/列見出しリボン/選択カードフレーム/素材バッジフレーム/選択矢印/調理ボタンフレーム/調理アクション帯フレーム/フロー主ボタンフレーム/魚行フレーム/魚/料理/人物/食卓前景/EXPメッセージ素材/ステータス大判素材/バナー/EXPバースト/レベルアップ記号素材/フレーム/共通アイコンシートの期待寸法を満たすことも検出する。`COOK_SELECT` の料理カードに星評価、`RecipeMaterialBadge_*`、素材魚アイコンがあること、`COOK_SELECT` のヘッダーに `CookingTitleBanner` があること、魚一覧に `FishSectionRibbon` と表示中の `FishRow*` があること、料理一覧に `RecipeSectionRibbon`、`RecipeCard_salt_grill`、`RecipeToDetailArrow` があること、`COOK_SELECT` の右詳細に `SelectedDishFeatureImage`、`CookDetailMaterialRow`、`CookDetailExpRow`、`CookDetailEffectRow`、`CookActionRunway`、`CookActionCue` があること、`COOK_SELECT` の主ボタンが `CookButton` として存在し、`cook_button_frame.png` の `StyleBoxTexture` を使うこと、`MEAL_RESULT` にはEXPゲージ/レベルアップ文が混ざらないこと、`MEAL_RESULT` に `MealTableSpread`、`MealDishCard`、`RewardDishFeatureImage` があること、`MEAL_RESULT` では `ExpBurstFrame` / `NextEffectArt` / `RewardCardGrowth` が可視にならないこと、`EXP_GAIN`/`EXP_GAIN_LEVELUP` の `MealTableSpread.dish_texture` が料理大判画像を保持すること、`EXP_GAIN`/`EXP_GAIN_LEVELUP` では `MealDishCard` / `RewardDishFeatureImage` が可視にならないこと、`MEAL_RESULT`/`EXP_GAIN`/`EXP_GAIN_LEVELUP` の主ボタンが `RewardConfirmButton` として存在し、`flow_action_button_frame.png` の `StyleBoxTexture` を使うこと、`MEAL_RESULT`/`EXP_GAIN`/`EXP_GAIN_LEVELUP` の食べた料理カード内に初回ボーナスが出ること、`MEAL_RESULT` の次回効果カードに `RewardBuffSignal` ビジュアルがあること、`EXP_GAIN` は参照03向けに初回ボーナスあり・非レベルアップ `+40 EXP` として構築されること、`EXP_GAIN`/`EXP_GAIN_LEVELUP` に `RewardStageBackground`、`ExpEnergyTrail`、`ExpBurstFrame`、`ExpMessagePanel` があること、`LEVEL_UP_OVERLAY` の王冠/ラウレル/メダル/釣り場素材ノードと `LevelToSummaryCue` ビジュアルがあること、`LEVEL_UP_OVERLAY` の主ボタンが `LevelUpConfirmButton` として存在し、`flow_action_button_frame.png` の `StyleBoxTexture` を使うこと、`STATUS_SUMMARY` のヘッダーに `StatusHeaderPlayerBadge` があること、`STATUS_SUMMARY` の料理カードに `StatusMealDishImage` があること、`STATUS_SUMMARY` のクーラー/所持金/時計カードに専用大判素材ノードがあること、`STATUS_SUMMARY` の料理効果枠に `StatusMealEffectCue` があること、`STATUS_SUMMARY` の戻りボタンが `StatusReturnButton` として存在し、`flow_action_button_frame.png` の `StyleBoxTexture` を使うこと、`MEAL_RESULT`/`EXP_GAIN`/`EXP_GAIN_LEVELUP` の導線connector modeが正しいこと、Lv.5後の`STATUS_SUMMARY`フッターが次行動を示すことも確認する。視覚スクショの代替ではなく、表示情報欠落とフロー導線の回帰防止。

## 収束フェーズ判定

今回の完成条件は「5状態が揃い、`reference/cooking_flow/` の主要レイアウト、主役パーツ、演出意図、情報階層が反映され、headless検証と通常描画スクリーンショット確認を通ること」とする。完全なピクセル一致、本番アート品質は今回の完了条件に含めない。

- 実装状態: `COOK_SELECT`、`MEAL_RESULT`、`EXP_GAIN`、`LEVEL_UP_OVERLAY`、`STATUS_SUMMARY` は実装済み。`EXP_GAIN_LEVELUP` はレベルアップ直前の検証用サブケースとして残す。今回、`COOK_SELECT` の下部 `現在の準備` は1行サマリーへ圧縮し、`LEVEL_UP_OVERLAY` と `STATUS_SUMMARY` も1280x720内に主導線が収まるよう再調整した。
- 参照反映: 5枚のリファレンスに対する主要差分は上記表の状態別契約、名前付きノード契約、専用アセットスロット、content/layout/smoke監査で固定する。
- 追加調整方針: ここからの見た目調整は、検証失敗、またはリファレンスとの差分がP1として明確に説明できるものだけに限定する。主観的な磨き込みはこのパスでは停止する。
- 通過済み収束ゲート:
  - `HOME=/private/tmp/tsuri_home tools/cooking_verify.sh`: 成功。
  - `HOME=/private/tmp/tsuri_home tools/validate_project.sh`: 成功。
  - `tools/cooking_visual_qa.sh`: 成功。`/tmp/tsuri_cooking_select.png`、`/tmp/tsuri_cooking_result.png`、`/tmp/tsuri_cooking_exp.png`、`/tmp/tsuri_cooking_levelup.png`、`/tmp/tsuri_cooking_status.png`、`/tmp/tsuri_cooking_capture_manifest.json`、`/tmp/tsuri_cooking_reference_report.html` を生成し、厳格な `tools/cooking_visual_qa_check.py` も通過。
  - `git diff --check`: 成功。
- 後続ゲート: ここから再調整する場合も `tools/cooking_verify.sh`、`tools/cooking_visual_qa.sh`、`git diff --check` を同じ順序で通し、生成された5状態PNGとmanifestを確認する。

## 2026-06-29 COOK_SELECT 画面1品質パス

今回の明確な実装ゴールは、`reference/cooking_flow/01_cook_select_concept.png` と `/tmp/tsuri_cooking_select.png` を横並びで見たときに、魚リスト、料理カード、右詳細、調理ボタン、下部バーが「仮UIの枠に文字と小画像を置いた状態」ではなく、「完成素材が載った調理選択画面」として読めるところまで引き上げること。完成基準は水中ファイト画面と同じく、コード描画だけに見える要素を減らし、参照画像由来または専用生成PNGの紙・木・金具・料理/魚素材を画面上の主役として使うこと。

- 実装済み: 左魚リストは水中ファイト側と同じ高密度の魚ポートレートを使い、`fish_row_frame.png` は紙質感、濃紺ガター、金具だけを持つ1枚スリップへ簡略化した。魚名と `× n 匹` が横クリップしない幅を確保し、数量セルや写真枠を別パーツに見せないことで、魚リストを在庫表ではなく素材カードとして読ませる。
- 追記: 魚行の選択三角マーカーと強い数量区切り線を外し、選択状態は金縁と行の明るさで読ませる。魚ポートレートの横幅を少し広げ、魚名/数量は紙面に直接載せて、左カラムが表形式ではなく所持魚カード列として見えるようにした。
- 実装済み: `recipe_grid_frame.png`、`recipe_card_frame.png`、`recipe_selected_card_frame.png` は参照紙テクスチャを混ぜた素材に更新し、料理カード内の料理絵は `recipe_dish_thumb_frame.png` の淡い紙マット付き額へ収める。カード下部は `recipe_material_strip_frame.png` を使う `RecipeMaterialBadge_*` に `RecipeMaterialIcon_*` の素材魚アイコンと短い状態表示を収め、EXP情報は右詳細の `CookDetailExpRow` に集約した。追調整では `recipe_selected_card_frame.png` を通常カードの紙面に近い構造へ戻し、内側の斜めハイライトと黄色ベタを削って、選択状態は金縁・角金具・外周グローで出すようにした。さらに選択可能カードの `×1` をカード下部から外し、ロック/素材違いカードも料理写真を読める明るさにして、6枚の料理写真が並ぶ参照01の密度に近づけた。
- 追記: 選択中料理カードは外周グロー、金縁、角金具を再強化し、通常カードとの差がスクショ上でも一目で読めるようにした。料理サムネイルはカード内で料理写真が小さく沈まないよう、カード面を満たす表示へ変更し、アジの塩焼きが主役カード内で料理として読める占有率を維持する。
- 追記: 料理カード内のタイトル/星/素材バッジの縦幅を少し締め、`RecipeDishThumb_*` と `RecipeDishImage_*` の表示高さを上げた。素材魚と `Lv.*` / `別素材` は小さな状態表示へ戻し、カード内で料理写真がまず目に入る配分を優先する。
- 追記: 料理カード写真は `STRETCH_SCALE` の引き伸ばしをやめ、`STRETCH_KEEP_ASPECT_COVERED` で皿写真の比率を保つ。星と素材バッジはさらに薄くして、カード内で料理写真が縦に潰れたUI画像ではなく料理素材として読める配分を固定する。
- 実装済み: 右詳細は `dish_feature_aji_shioyaki.png` を参照01の大判料理カットから生成し、`SelectedDishFeatureImage` をやや大きくした。詳細3行は `cook_detail_row_frame.png` を使う `CookDetailMaterialRow` / `CookDetailExpRow` / `CookDetailEffectRow` へ置き換え、フォーム欄ではなく横長情報リボンとして読ませる。`dish_detail_frame.png`、`cook_button_frame.png`、`cook_action_runway_frame.png` も紙面、青い金縁CTA、下部アクション帯が読める素材に更新した。
- 追記: 右詳細3行の値領域から強い斜線と入力欄風の囲いを削り、`CookDetailMaterialRow` / `CookDetailExpRow` / `CookDetailEffectRow` の主値を濃いインクで直接載せるようにした。`cook_button_frame.png` と `cook_action_runway_frame.png` も白い斜線を抑え、調理ボタン周辺の装飾より `調理する` の読みやすさを優先する。
- 追記: `CookActionCue` は鍋から皿への大きな描画をやめ、細い金色キューへ抑えた。`CookButton` は高さと文字サイズを上げ、鍋アイコンを左ポケット内に収め、右詳細の最後に押す青い金縁CTAとして読ませる。
- 追記: 右詳細3行の表示高さと文字サイズを上げ、効果行のタイトル幅を詰めて主値が潰れないようにした。料理写真の高さを少しだけ抑えて、その分 `CookActionRunway` と `CookButton` を太くし、参照01の「材料→EXP→次回効果→調理する」へ視線が落ちる縦ストーリーを優先する。
- 追記: 右詳細3行をさらに太い情報帯へ寄せ、材料の所持数は `12 / 1` 形式にして参照01の `所持 / 必要` に近づける。効果行は見出し側に `次の釣行で得られる効果` を残し、値側は `最大体力 +5%` のように短くして、細い入力欄風ではなく読みやすい結果リボンとして扱う。
- 実装済み: 下部の `現在の準備` は `prep_summary_bar_frame.png` と `prep_summary_card_frame.png` を使う `CurrentPrepBar` / `PrepSummaryCard*` へ置き換え、参照01の下部ステータスバーに近い紙カード群へ寄せた。
- 追記: 下部バーは `PrepSummaryCard*` を横一列の小ラベル/小値テーブルから、大きめのアイコン、上段見出し、下段主要値の2段カードへ組み替えた。`CurrentPrepTitle` は食事結果文言が横クリップしない幅を維持しつつ、通常時のプレイヤーLv. / 効果中の料理 / クーラーボックス / 所持金が参照01の下部カードに近い紙カード群として読めることを優先する。
- 追記: `CurrentPrepTitle` と `CurrentPrepDetailButton` の幅を詰め、4枚の `PrepSummaryCard*` 側へ横幅を戻した。各カードはアイコンを少し大きくし、見出し/主値の文字サイズとカード高さを上げて、下部バーが小さな表ではなく現在準備HUDとして読めるようにした。
- 追記: COOK_SELECTの比較/監査シードは参照01に合わせ、効果中料理ありの `サバの味噌煮 / あと1回` を表示する。下部バーが空の `なし` 状態に戻ると、参照01の「現在の準備」HUDとしての密度が落ちるため、content auditでもこの表示を固定する。
- 追記: `tools/cooking_preview.gd` の `COOK_SELECT` キャプチャは参照01と比較しやすいアジ選択状態に固定した。スクショ用の所持魚合計は容量内の `19 / 20` に収めつつ、6行すべてを所持魚として並べ、左カラムが暗い未所持リストに見えない状態で比較する。実フロー/報酬状態の検証シードは別に維持する。
- 追記: 魚行は調理専用の小アイコンではなく、`assets/showcase/underwater/fish/*_card_portrait.png` を優先し、水中ファイト基準の魚アート密度をリスト内でも使う。数量欄は右側に確保し、`× 12 匹` などが折れずに読める状態を維持する。表示順は調理画面用に `アジ → サバ → カサゴ → メジナ → イサキ → ヒラメ` を優先し、`FishRowIsaki` もcontent/layout audit対象にして、6行密度を維持する。
- 追記: 魚ポートレートは `STRETCH_KEEP_ASPECT_COVERED` で行内へ収め、透明余白ごと縮めず魚体が紙面を横切るサイズにする。魚名/数量の幅は詰め、左カラムが表ではなく「大きい魚絵が並ぶ素材リスト」として読めることを優先する。
- 追記: ロック中レシピは灰色の南京錠だけに戻さず、料理名と料理写真を出しつつ `Lv.5` の小バッジで状態を示す。6枚目の空き枠は `RecipeCard_PreviewMeuniere` として料理プレビューカードにし、`RecipeBookButton` をグリッド下へ分離することで、参照01の「6枚の料理カード＋料理図鑑を見る」構成へ寄せた。
- 追記: `RecipeSectionRibbon` は大きな炎アイコンがカード上に強く出すぎないよう、小さな料理アイコンへ変更した。`RecipeBookButton` は横幅と高さを上げ、参照01下部の青い横長「料理図鑑を見る」CTAとして読めるようにする。
- 追記: `cooking_room_bg.png` は参照01右側の港窓/ランタン/植物の細長いサンプルを中央カードと右詳細の接続帯へ合成し、`RecipeToDetailArrow` 周辺が暗い板だけに見えないようにした。
- まだ残る差分: 中央カード下部は素材バッジ化済みだが、最終本番アートに比べると素材魚アイコンそのものの描き込みはまだ軽い。ヘッダーのリッチさ、料理カード下部のアイコン描き込み、右詳細3行を参照の太い一体型情報帯へさらに近づける最終調整は次パス候補。
- 通過ゲート: `HOME=/private/tmp/tsuri_home tools/cooking_verify.sh`、`HOME=/private/tmp/tsuri_home tools/validate_project.sh`、`HOME=/private/tmp/tsuri_home tools/cooking_visual_qa.sh`、`git diff --check`。

## 未解決

- P1: 現時点で既知のロジック破壊はなし。headless layout audit上の画面外はみ出し/縦クリップは解消済みで、smoke上の主ボタンも1280x720内に完全に収まり、押下可能な状態を確認済み。通常描画の5状態スクリーンショットも生成済みで、manifest上はすべて1280x720 PNGとして記録されている。
- P2: 生成フレーム/背景アセットの主要接続は進んだが、生成アセットは実装用の差し替えスロットであり、最終本番アートではない。料理・魚・背景は後続で水中ファイト水準の素材へ差し替える余地がある。次パスはピクセル単位の微調整ではなく、魚行、料理カード、大判料理、詳細枠、調理ボタンの素材密度と質感を優先して比較する。
- P3: steam/sparkle/粒子などの小演出は、状態別スクショでP1/P2が潰れてから追加する。
