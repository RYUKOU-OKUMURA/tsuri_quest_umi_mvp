# iPad・スマートフォン表示／入力対応計画

最終更新: 2026-07-19

状態: **全体計画は未実装（調理場の魚一覧scrollだけユーザー承認済み局所修正を実装）**

対象: Godot 4.7 / 1280×720固定UI / iPad landscape / iPhone landscape / 将来Android検討

関連:

- `docs/19_ui_production_playbook.md` — UI品質・freeze・visual QAの正本
- `docs/55_ipad_test_deployment_and_save_management.md` — iPad導入・セーブ運用の正本
- `docs/56_ipad_deployment_execution_report.md` — 実機build / install / launch runbook
- `docs/v2/E11_launch_readiness.md` — 初回macOSローンチ境界

## 0. 結論

### 0-1. 推奨判断

| 対象 | 現在の扱い | 推奨 |
|---|---|---|
| macOS 16:9 | 初回正式対象 | 1280×720 freezeを維持 |
| iPad landscape | 実機spike成功、正式対応は未決定 | **次のモバイル対応候補**。中央16:9 UIを守り、上下へ背景を拡張する |
| iPhone landscape | 現行buildは技術上起動候補だが未検証 | iPad対応後の独立フェーズ。小画面用の情報密度・操作領域・safe area対応が必要 |
| iPhone portrait | 非対応 | 画面構成を作り直す別製品規模。現計画へ含めない |
| Android phone / tablet | 未着手 | iPhone landscapeでUX成立後に、SDK・署名・端末matrixを含む別判断 |

iPadの黒帯は現行`keep`設定による正常動作であり、破綻ではない。ただしiPadを正式対応端末として外部配布するなら、黒帯を残したまま「ネイティブ対応」と案内するより、余剰領域へ背景を拡張した方が製品品質は高い。

スマートフォン対応は可能だが、iPad対応のついでには完了しない。最大の問題は解像度ではなく、**物理画面の小ささ、情報密度、指で押せる範囲、safe area、hover依存、長押し／離す操作**である。

### 0-2. 初回macOSローンチとの境界

本計画は初回itch.io / macOS Universalローンチを止めない。`docs/30`とE11で確定したmacOSの`keep`＋黒帯方針を変更せず、モバイル対応は別branch / 別QA軸として進める。

## 1. 現状の実測

### 1-1. iPad表示

2026-07-18にiPad Air（第3世代）で実機起動した。提供された原寸landscape screenshotは2224×1668（4:3）、ゲーム描画は2224×1251（16:9）で、上208px・下209pxの黒帯がある。

目視結果:

- 1280×720の全領域が中央へ収まり、左右・上下の欠けはない
- 縦横比の歪みはない
- 港画面の文字切れ、重なり、主要ボタン欠損は見当たらない
- 左右は画面幅を使用し、画面高の上下合計約25%（上約12.5%、下約12.5%）がengine描画外の黒帯になる
- 見た目は「iPad専用画面」より「16:9画面をiPadへ収めた状態」に近い

`display/window/stretch/aspect="keep"`ではengineが黒帯を追加し、その黒帯へゲーム側から描画できない。上下を背景で埋めるには、単に黒帯色を変えるのではなく、描画可能領域を異なるaspectへ拡張する基盤が必要である。

### 1-2. 現行レイアウト

現行の正本:

```text
base viewport: 1280×720
stretch mode: canvas_items
stretch aspect: keep
orientation: landscape
renderer: gl_compatibility
```

多くの画面は1280×720を前提に固定矩形で構成されている。市場と釣具店は`DESIGN_SIZE=1280×720`のdesign canvasを中央scaleする防御を個別実装済みだが、全画面共通のadaptive frameではない。

### 1-3. 現行入力

通常の`Button.pressed`はtouchからmouseへの変換で動く可能性が高い一方、次は正式なtouch契約になっていない。

- 調理場の魚一覧はrelease-only `Button`へ局所移行済みだが、recipeカードは`InputEventMouseButton`を直接判定
- 水中ファイトHUDがmouse down / upを直接判定
- 釣り場mapが左mouse clickを直接判定
- 港、設定などに`mouse_entered` / `mouse_exited`由来の説明・演出がある
- touch cancel、複数指、指がbutton外へ抜けた場合のrelease、background移行時の押下解除が未監査

したがって「タップしたら動いた」だけでは正式対応にならない。tap / hold / release / cancelを一つの入力契約へ統合する必要がある。

## 2. 画面サイズ対応の基本方針

### 2-1. 3層に分離する

全画面を次の3層として扱う。

1. **Device viewport** — 実際の画面全体。4:3、16:10、19.5:9など可変
2. **Extended backdrop** — 余剰領域まで描画する背景。原則として操作要素を置かない
3. **Design safe canvas** — 現行1280×720 UI。既存freeze値と主導線を守る

これにより、macOS 1280×720の見た目を変えず、iPadでは上下、wide phoneでは左右へ背景だけを延長できる。

### 2-2. `expand`を単独で有効化しない

Godot公式はlandscape mobileの複数aspect対応に`canvas_items`＋`expand`＋Control anchorsを案内している。ただし現行コードは固定矩形が多いため、project settingだけを`expand`へ変更すると、画面ごとに次が起こり得る。

- 背景だけが伸び、UIが左上へ寄る
- full-rect Controlが予期せず拡張する
- modalの外押下領域と見た目が一致しない
- mouse / touch座標と固定hit矩形がずれる
- 既存の1280×720 freeze値が暗黙に変わる

先に共通adaptive frameとscreen profileを実装し、`keep`を維持したまま4:3 simulated viewportで全13画面をframeへ移行・QAする。全画面の移行後にだけ`expand`を有効化し、iPad実機の全画面QAを行う。港pilotだけを根拠にglobal settingを切り替えない。

### 2-3. 背景の拡張ルール

| 画面タイプ | 余剰領域の扱い |
|---|---|
| 港・図鑑・市場・店・調理・生簀などの密閉UI | 中央UIは1280×720のまま。背景画像のcover / edge extension / 減光で外側を埋める。余剰領域に新情報を置かない |
| タイトル | 背景アートのみcover。ロゴ、slot、主要操作はdesign safe canvas内 |
| 釣り場map | map操作領域はsafe canvas内。外側は海・空・地図台紙の延長のみ |
| 水上READY・水中ファイト | world sceneは外側へ拡張可。上部／下部HUDと主操作はsafe area内に固定 |
| modal / fanfare | scrimはdevice viewport全体、panelとボタンはsafe canvas内 |

背景拡張は、黒帯を別の派手なUIで埋める作業ではない。中央の情報階層を維持し、余剰領域は没入感の補助へ限定する。

## 3. iPad対応方針

### 3-1. 採用候補

**4:3へ全面再配置せず、1280×720 design safe canvasを中央維持し、上下各120 logical px相当へ背景を拡張する。**

1280幅基準の4:3 logical viewportは1280×960であり、16:9 safe canvasとの差は縦240。現行UIを上下120ずつ中央配置すれば、港画面の矩形や文字サイズを変えずに黒帯を描画可能背景へ置き換えられる。

### 3-2. iPadで再オープンするもの／しないもの

再オープン:

- 各画面の最外周背景
- device viewport全体のscrim
- safe area inset処理
- touch hit領域とpressed状態
- 4:3でのmodal外押下、回転復帰、座標変換

原則freeze維持:

- 1280×720内の主要矩形
- 画面内の情報順序
- フォントサイズ、行数、カード密度
- 主CTA位置
- 採用済み素材と共通キット

4:3で中央UI自体を再配置したい場合は、docs/19 §1.1の構成再設計ゲートとして別途ユーザー承認を取る。

### 3-3. iPad合格条件

- 黒帯0。余剰領域はゲーム側の背景として描画される
- 1280×720 screenshotは現行freezeとpixel-stable、または差分理由がQAへ記録される
- 4:3で中央UIの歪み、crop、文字切れ、重なり0
- Landscape Left / Rightの両方向で起動・回転し、入力座標ずれ0
- 全13画面で主導線がtapのみで閉路になる
- 水中ファイトでdown / hold / up / cancelが一重発火し、押しっぱなしが残らない
- modal scrimがdevice viewport全体を覆い、外側tapが下層へ漏れない
- background / foreground後も押下状態と音が正常
- build A→Bで3slotとsettingsを維持
- 代表画面で致命的な遅延、過熱、crashなし

### 3-4. orientationとiPadOS dynamic resizing

現在のGodot生成Info.plistは次の状態であり、初回full-screen spikeには使えたが、正式iPad対応の完成形ではない。

```text
iPhone orientations: LandscapeLeftのみ
iPad orientations: LandscapeRightのみ
UIRequiresFullScreen: true
```

Appleはlandscape-onlyのapp / gameでも、端末を左・右どちらへ回した場合も同等に動作することを求めている。またiPadOS 26以降、`UIRequiresFullScreen`によるmultitasking / dynamic resizingのopt-outはdeprecatedで、将来無視される予定である。

正式iPad対応では次をrelease gateへ追加する。

- Landscape Left / Rightの両方を生成Info.plistと実機で確認
- `UIRequiresFullScreen`互換モードへ依存しない
- windowをwide / compact / tallへ動的resizeしても、背景、design canvas、scrim、入力座標が追随
- resize中／完了後のsafe areaを再取得
- orientation lockを維持する場合は、Appleの現行APIとGodot 4.7 export templateでの実装方法を別spikeで確定
- 初回full-screen 4:3 screenshotだけを正式対応の根拠にしない

Godot presetだけで必要なInfo.plist / scene behaviorを再現できない場合は、生成projectの手編集ではなく、再export可能なplugin、template override、またはpost-export処理として設計する。

## 4. スマートフォン対応の評価

### 4-1. 技術的には可能

現在のiOS生成projectはiPhone / iPad両方のdevice familyを含んでおり、Godotもlandscape mobileの複数aspectをサポートする。したがってiPhoneへbuildする技術経路は近い。

ただし、**buildできることと製品として遊べることは別**である。港、図鑑、市場、調理、ステータスは情報密度が高く、16:9全体を小型画面へ縮小すると、文字が読めても指で安定して押せない可能性が高い。

### 4-2. iPadより難しい理由

| 課題 | iPad | smartphone landscape |
|---|---|---|
| 物理サイズ | 1280×720 UIを比較的大きく表示可能 | 同じUIが大幅に小さくなる |
| aspect | 4:3で上下余剰 | 18:9〜20:9で左右余剰が出やすい |
| safe area | 比較的単純 | notch / Dynamic Island / rounded corner / home indicator |
| 操作 | 大きなpanelでも届く | 小ボタン、隣接操作、長押しが厳しい |
| 情報密度 | 現行構成を維持しやすい | 一覧・詳細の同時表示を分割する可能性 |
| 手の持ち方 | 置いて操作しやすい | 両手thumb reachを考慮する必要 |

### 4-3. smartphoneの推奨scope

最初は**landscape限定**とする。portraitは対象外。

landscape-onlyでもLandscape Left / Rightの両方向をサポートする。iPadのresizable windowが縦長になった場合は、ゲームUIをportraitへ再構成せず、landscape design safe canvasを縮小して背景内へ安全に収める。

wide phoneでは高さ720 logicalを維持し、左右へworld / backgroundを拡張する。HUDと主操作はOS safe areaを除いた中央safe canvasへ置く。ただし密閉UI画面は次のcompact variantが必要になる可能性が高い。

- 港: 右menuと左情報を同時表示せず、tab / drawerへ分割
- 魚図鑑: 一覧と詳細を別stateへ分離
- 市場・釣具店: card列数削減、詳細をmodal化
- 調理: recipe一覧、詳細、結果を明確なstepへ分割
- ステータス・依頼: scroll前提で1列化
- 水中ファイト: thumb reach内へ主操作を集約し、画面端safe insetを確保

この再構成は既存freezeの局所調整ではなく、docs/19 §1.1の構成再設計である。各画面を個別に着手せず、港＋水中ファイトの2画面pilotで成立性を確認してから全画面へ展開する。

### 4-4. 操作領域

AppleはiPhone / iPadのbutton hit regionを原則44×44pt以上と案内している。Godot上のlogical pxだけでは物理pointを保証できないため、対象端末profileごとに実際のscreen pointへ換算し、見た目が小さい場合も透明hit marginで44×44pt以上を確保する。

追加条件:

- 隣接button間の誤tapがない余白
- hoverなしでも機能と選択状態が理解できる
- custom buttonにpressed状態がある
- drag / holdは指で対象を隠しても状態が読める
- touchがbutton外へ移動、OS gesture、通知、backgroundでcancelされた時に状態を解除
- multi-touchを使わない画面は2本目以降を安全に無視

### 4-5. smartphone対応の推奨判断

現時点では「正式対応を約束」しない。次の順で判断する。

1. iPadでadaptive frameとtouch契約を完成させる。
2. iPhone実機へ現行16:9版を入れ、文字とtap targetのbaselineを取る。
3. 港＋水中ファイトのcompact pilotを実装する。
4. 主要導線を15〜30分操作し、誤tap、疲労、情報欠落を評価する。
5. pilotが成立した場合だけ残り11画面の工数を見積もる。

スマートフォンは潜在ユーザーが多い一方、現状の画面密度ではiPadより明確に大きな改修になる。優先順位は **macOSローンチ → iPad正式対応判断 → iPhone landscape pilot → Android判断** とする。

## 5. 共通実装基盤案

名称は実装briefで確定するが、責務は次へ分離する。

### 5-1. Layout profile

model名ではなく、usable rectとaspectから分類する。

```text
desktop_16_9
tablet_tall
phone_wide
unsupported_portrait
```

profileが返すもの:

- device viewport rect
- OS safe rect
- 1280×720 design canvas rect
- background cover rect
- UI scale
- compact layoutの要否

### 5-2. Adaptive screen frame

全画面共通で次を担う。

- extended backdrop
- centered design canvas
- safe area inset
- full-device modal scrim
- viewport resize / orientation change通知
- device座標からdesign canvas座標への変換

市場・釣具店にある個別letterbox / design canvas実装は、共通frame採用後に重複を解消する。先に削除せず、共通frameの同等動作をスクショで証明してから置換する。

### 5-3. Touch action contract

画面側がmouse event型を直接判定せず、意味のあるactionを受け取る。

```text
tap
press_started
press_held
press_released
press_cancelled
drag
```

通常buttonは`pressed`を維持し、水中ファイトなどholdが必要な箇所だけ共通gesture adapterを使う。mouse、touch、将来controllerを同じ意味actionへ収束させる。

## 6. 実装フェーズ

### M0. 現行baseline固定

- iPad screenshotをQA evidenceへ保存
- 1280×720 / 4:3の現行keep表示をbaseline化
- 全13画面のtap可否を実機で記録
- build A→B save回帰を通す

DoD: 現行の問題を「黒帯」「表示」「入力」「保存」へ分離できている。

### M1. Adaptive frame基盤

- layout profile
- extended backdrop / design safe canvas
- safe area
- modal scrim
- 座標変換
- 1280×720非回帰test

pilot画面: 港。

DoD: 1280×720が非回帰。`keep`維持下の4:3 simulationで、港のextended backdrop / design canvas / full-device scrim / 座標変換が成立する。pilot段階ではglobal `expand`へ切り替えない。

### M2. iPad全画面展開

画面タイプ単位で進める。

1. タイトル・港・設定
2. 一覧／詳細（図鑑・市場・釣具店・造船所・ステータス・依頼）
3. 調理・生簀
4. 釣り場map・水上READY・水中ファイト・結果modal

各sliceで実スクショ、該当smoke、`./tools/validate_project.sh`を通す。

全13画面のframe移行とsimulation QA後に`expand`を有効化し、iPad実機で黒帯置換、Landscape Left / Right、dynamic window resize、全画面入力を回帰する。

### M3. Touch契約

2026-07-19の局所対応として、調理場の所持魚一覧だけは `MOUSE_FILTER_PASS`、release-only透明hit target、12px drag deadzoneへ移行した。desktop emulated dragの専用smokeでtap一重発火、drag時の選択cancel、wheel、keyboard focus、row寸法不変を固定済み。iPad実機の再確認と、recipeカード・他画面・cancel・multi-touchを含むM3全体は未完であり、`IPAD-INPUT-01`完了には数えない。

- direct mouse判定を意味actionへ置換
- tap / hold / release / cancel
- hover依存情報の代替
- background / foreground解除
- multi-touch guard

DoD: `docs/55`のIPAD-INPUT-01〜03を通す。

### M4. iPhone landscape pilot

対象: 港＋水中ファイト。

- wide phone background extension
- OS safe area
- 44×44pt hit region監査
- compact港menu
- thumb reachを考慮したfight操作
- 小型／標準wide phone実機matrix

DoD: pilotの主要導線に誤tap、見切れ、到達不能、押下残り0。全画面展開の工数判断ができる。

### M5. iPhone全画面または見送り判断

pilot後にユーザー承認で決める。成立しなければiPad対応だけでcloseし、iPhoneをunsupportedと明記する。

### M6. Android判断

iPhone UXを再利用できることを確認後、Android SDK / export template / signing / back gesture / safe area / 端末性能matrix / store要件を別docで計画する。

## 7. QA matrix

### 7-1. 表示profile

| profile | logical基準 | 主な確認 |
|---|---:|---|
| desktop baseline | 1280×720 | 現行freeze非回帰 |
| desktop 16:10 | 1280×800相当 | 背景拡張、中央UI |
| iPad full-screen 4:3 | 1280×960相当 | 上下背景、safe canvas、Landscape Left / Right |
| iPad resizable wide | 可変 | 左右背景、safe area再計算、scrim / 入力座標 |
| iPad resizable compact | 可変 | safe canvas縮小、文字・tap、modal |
| iPad resizable tall | 可変 | landscape UIの安全な縮小、上下背景、操作到達性 |
| phone 16:9 | 1280×720相当 | 小型物理画面、tap target |
| wide phone | 1560×720相当 | 左右背景、notch / home indicator |
| simulated inset | profile＋四辺inset | safe areaとmodal scrim |

logical値は設計比較用であり、実端末のnative pixel数を固定するものではない。

### 7-2. 全画面共通

- backgroundがdevice viewportを覆う
- design safe canvasが意図した位置・scale
- 非均一stretchなし
- 文字切れ、省略、重なり0
- 主CTAと戻る操作がsafe area内
- hit regionが見た目と一致
- modal外tap漏れ0
- hoverなしで情報欠落0
- landscape固定と復帰後座標ずれ0

### 7-3. 画面別高リスク

| 画面 | 高リスク |
|---|---|
| 港 | 右menuの密度、小ボタン、説明のhover依存 |
| 図鑑 | card grid、scroll、一覧／詳細同時表示 |
| 市場・釣具店 | 固定design canvas、数量操作、confirm modal |
| 調理 | 魚一覧scrollは局所対応済み。recipeのmouse event直判定、実touch再確認、複数step、長文は継続リスク |
| 設定 | slider、slot削除modal、fullscreen項目のmobile扱い |
| 釣り場map | 固定hit座標、locked spot |
| 水中ファイト | press / hold / release / cancel、thumb遮蔽 |
| catch / level-up | full-device scrimとsafe panel |

## 8. 非目標

- macOS初回ローンチ前にモバイル全対応を完了すること
- `ignore`で1280×720を非均一に引き伸ばすこと
- 背景をcropしてUIまで切ること
- 黒帯を理由に全画面のfreeze値を無条件で動かすこと
- smartphone portrait対応
- iPad対応と同時にAndroid配布を開始すること
- touch対応をmouse emulationだけで合格にすること
- iCloud / cross-device cloud saveを表示対応へ混ぜること

## 9. 着手ゲート

実装開始前に次をユーザー承認する。

1. iPad正式対応を目標にするか、実機テスト限定のままにするか。
2. 「中央16:9 UI維持＋上下背景拡張」を採用するか。
3. 4:3で中央UIを再配置しない方針でよいか。
4. iPhoneはlandscape pilotまで進めるか。
5. 1280×720 baselineと各画面freezeの不動範囲。

承認後、港の同一状態before / after mockupを作り、docs/19 §1.1に従って構成・主導線・動的状態・素材/runtime分担を分解してから実装する。

## 10. 公式参考資料

- [Godot: Multiple resolutions](https://docs.godotengine.org/en/stable/tutorials/rendering/multiple_resolutions.html)
- [Godot: Using Containers](https://docs.godotengine.org/en/stable/tutorials/ui/gui_containers.html)
- [Apple: Layout and safe areas](https://developer.apple.com/design/human-interface-guidelines/layout)
- [Apple: Designing for games](https://developer.apple.com/design/human-interface-guidelines/designing-for-games)
- [Apple: UI Design Dos and Don’ts](https://developer.apple.com/design/tips/)
- [Apple: UIRequiresFullScreen](https://developer.apple.com/documentation/bundleresources/information-property-list/uirequiresfullscreen)
- [Apple TN3192: Migrating from UIRequiresFullScreen](https://developer.apple.com/documentation/technotes/tn3192-migrating-your-app-from-the-deprecated-uirequiresfullscreen-key)
