# 依頼ボード QA判断ログ

最終更新: 2026-07-16 / 状態: UI-QUEST-01 / Wave A / INPUT-QUEST-BOARD close・freeze
参照画像: reference/11_quest_board_mockup.png
QA更新コマンド: ./tools/quest_board_visual_qa.sh

## 1. freeze値（正本）

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 依頼札枚数 | 3枚固定 | `src/ui/quest_board_screen.gd` | E3仕様。掲示中3件は常時進行中 |
| 札配置 | 横3列 | `QuestBoardPanel` | 1280x720で依頼文・進捗・報酬を同時に読ませるため |
| 帰港ボタン | 右下 | `QuestBoardFooter` | 他画面の右下規約に合わせる |
| 主条件本文 | 左右 `0.078–0.912`、上下 `0.375–0.570`、18px・最大3行 | `QuestText` | P1再オープン。肖像下の全幅3行を維持し、現行最長条件を省略なしで表示する |
| 肖像と下段情報 | 肖像下端 `0.370`、進捗見出し/値 `0.575–0.630`、ゲージ `0.648–0.677`、報酬 `0.681–0.736` | `QuestFishPortrait` / `QuestProgress*` / `QuestReward` | 進捗の実行高（見出し24px、値27px）がゲージに重ならず、ゲージ→報酬も実矩形で分離する |
| 行動ボタン | 上下 `0.765–0.905`、最小高54px、縦テクスチャmargin `14 + 14`、20px文字＋outline 2px | `QuestActionButton*` | 必要高52pxに2px余裕を置き、報酬・札下木枠との干渉を防ぐ |
| 画面専用素材 | 木面 `quest_board_wood_panel.png`、ピン付き無地札 `quest_notice_card.png` | `assets/showcase/quest_board/` | 3列・全文・進捗・報酬・CTA矩形を不動にしたまま、参照との差分Top1だった紙質・ピン・木目を縮小比較でも解消 |
| キーボード入力 | 初期focusは左端の達成済みCTA、全件未達成時は右下帰港。disabled CTAは`FOCUS_NONE`。enabled CTAをカード順→帰港でTab閉路、左右はenabled CTA間、CTA下→帰港、帰港上→右端enabled CTA。focused CTAがdisabledになれば次のenabled CTAへ循環し、なければ帰港へ復旧 | `QuestActionButton1..3` / `QuestBoardReturnButton` | INPUT-QUEST-BOARD。外部進捗でCTAが有効化されても有効な既存focusを奪わず、Escapeはecho込み港遷移1回 |

## 2. 不採用・再試行禁止リスト

| 案 | 却下理由 | 判断日 |
|---|---|---|

## 3. 微調整カウンタ

| パラメータ | 回数 | 直近の変更内容 | 状態 |
|---|---|---|---|
| 装飾パス累計 | 2 | runtime木板/共通紙面から、画面専用のauthored木面＋ピン付き紙札へ置換 | freeze |
| 主条件本文・下段クラスタの再配分 | 2 | 本文/肖像を上げ、進捗実行高・ゲージ・報酬・CTAを実矩形で順に分離 | freeze |

## 4. 暫定判定・再検証TODO

なし。通常・long_text_a/bの1280x720実キャプチャ、原寸/縮小/グレースケール比較、実矩形smokeで再確認済み。

## 5. 現在の残ギャップ

- 依頼者/NPCの個性付けは未実装。

## 6. フェーズスコープ宣言（作業中のみ）

INPUT-QUEST-BOARDは局所入力uplift。再オープン範囲は`QuestActionButton1..3`と`QuestBoardReturnButton`のfocus mode・隣接・初期focus・状態遷移時のfocus復旧・Escapeだけ。3列、全Label/ゲージ/CTA矩形、外枠、依頼札枚数、本文/進捗/報酬/CTA文言、素材、フォント、色、依頼生成/進捗/納品/報酬/saveロジックは不動とする。

## 7. 判断ログ（直近パスのみ）

2026-07-16:

- E11入力baselineの`INPUT_NO_INITIAL_FOCUS`、`INPUT_DISABLED_REACHED`、`INPUT_FOCUS_ISOLATED`、`INPUT_CANCEL_UNOBSERVED`を局所修正した。左から最初のenabled CTAを初期focusとし、全件未達成では帰港だけのsingleton閉路を作る。disabled CTAは`FOCUS_NONE`へ外し、refresh前のslot indexまたは帰港というsemantic identityを維持する。同枠がdisabledになったときだけ次のenabled CTAへ循環し、候補がなければ帰港へ復旧する。
- `tools/quest_board_input_smoke.tscn`を追加し、slot 1納品可能・slot 2記録報告可能・slot 3未達成、全件未達成、空boardの3件補充、外部進捗によるdisabled/enabled往復、納品/報告後の即時入替、魚を消費しない記録報告、マウス回帰を実`InputEventKey` / `InputEventMouseButton`で固定した。EnterとEscapeはpress→echo→releaseでも副作用1回、ランダムな入替依頼IDには依存しない。
- 1280x720原寸証拠は`evidence/quest_board/2026-07-16_input_initial_ready.png`（左端の納品CTA）、`..._input_all_unmet_return.png`（全件未達成の帰港）、`..._input_post_delivery.png`（納品後に右隣の報告CTAへ復旧）へ保存して個別確認した。表示構成、CTA矩形、素材、文言のfreezeは変更していない。
- 専用input smoke、既存`quest_board_smoke`（料理条件190/190を含む）、`quest_board_visual_qa.sh`、fresh E11 baseline（quest_board finding 0）をgreen確認した。`e11_qa_harness_verify.sh`は、本branchでは新規`quest_board_input_smoke.tscn`が親owner管理のrelease manifestへ未登録のため、追跡後の再実行でmissing testとしてexit 1になる。manifest自体は本スライスで触らず、親統合時の登録後にgreenを再確認する。

2026-07-13:

- 局所upliftとして、差分Top1を「紙質・ピン留め・掲示板木目の素材感不足」に限定した。仮説・発注仕様・素材/runtime分担は `docs/46_quest_board_material_uplift_spec.md` に記録し、既存freeze値は再オープンしていない。
- OpenAI built-in image generationで、文字なしの木製掲示板sourceと、純緑背景のピン付き無地紙札sourceを生成した。`tools/generate_quest_board_assets.py` で木面を1280×512 RGB、紙札を384×432 RGBAへ再現可能に加工し、`assets/showcase/quest_board/` へ出力した。日本語、魚、進捗、報酬、CTAはruntime描画を維持した。
- 同一データ・同一viewportのbefore/after/reference原寸は `2026-07-13_wave-a-before-after-reference.png`、縮小は `...-thumbnail.png`、グレースケールは `...-grayscale.png` に保存した。afterは、beforeの縦帯状runtime木板と一様な紙面から、連続した横木面・紙の不均一な輪郭・中央ピンへ変わり、320×180でも参照の「木面上の3枚の札」へ明確に近づいたため採用した。
- 通常・long_text_a/bは `2026-07-13_wave-a-after*.png` で、主条件全文、進捗、報酬、状態CTAの非衝突を原寸確認した。`quest_board_smoke` にはauthored textureのロード/パス契約だけを追加し、依頼ロジックは不変。P1は0件。
- 不動値は、3列・カード外形・全Label/ゲージ/CTA矩形・header/footer・フォント・文言・操作状態。素材以外の収束調整は行っていない。

2026-07-11:

- `docs/45_release_readiness_code_review.md` の UI-QUEST-01 を、本文省略に加えてCTAの札下木枠干渉、進捗文字のゲージ干渉として再オープンした。3列・外枠・依頼ロジックは成立しているため、依頼札内だけを再配分した。
- 同一データ（アジ/メジナ/カサゴの3件、Lv9・12,450G・依頼達成9件）・同一preview harness（0.60秒待機、force draw、追加3 frame）・同一capture timingで、親 `a66cdbe` とafterを撮影した。before/afterとも魚肖像を含み、`evidence/quest_board/2026-07-11_ui-quest-before_after.png` で、beforeの省略とafterの全文表示、CTA下枠干渉の解消を比較した。
- 不動値は3列、外枠、札枚数、魚名領域、下段の読み順、フッター右下帰港、依頼生成/納品ロジック。比較元 `a66cdbe` からの移動値は、本文（左右 `0.340–0.912`・上下 `0.250–0.405`→左右 `0.078–0.912`・上下 `0.375–0.570`）、肖像下端（`0.395`→`0.370`）、進捗見出し/値（`0.455–0.500`→`0.575–0.630`）、ゲージ（`0.520–0.575`→`0.648–0.677`）、報酬（`0.620–0.690`→`0.681–0.736`・20→18px）、CTA（`0.785–0.900`→`0.765–0.905`・22→20px）。CTAは縦marginを `24 + 24` から `14 + 14`、最小高を54pxへ採用し、20px文字とoutlineを実高内に収めた。
- `quest_board_smoke` は本番の有効テンプレート一覧を列挙する。通常4種は本番候補カタログを絞って最長の本番出力を使い、料理は本番 `_quest_cuisine_options` の全recipe_id×fish_id期待値を固定seedで各魚へ決定的に網羅し、現行190/190の本番出力を確認する。各出力は実画面の `QuestText` で最大3行・省略なしを検証する。
- 同smokeは、進捗見出し/値の実矩形が各minimum line height以上であること、両者の末端がゲージ開始以前であること、ゲージ末端が報酬開始以前であること、報酬→CTAとCTA→札下木枠も非重なりであることを検証する。`QUEST_BOARD_SMOKE_FORCE_FAILURE=1` は即時exit 1、通常はexit 0を確認した。
- `tools/quest_board_visual_qa.sh` は通常・最長条件A/Bの各capture前に既定の専用tmp HOMEだけを初期化し、レンダラー終了を1秒待つ。`TSURI_GODOT_HOME` を指定した場合は削除せず、常に `mkdir -p` を保証する。これにより3状態とも1280x720原寸で取得し、長文A/B（`2026-07-11_ui-quest-long-text-a.png` / `...-b.png`）でも本文・進捗・ゲージ・報酬・CTAを目視確認した。
