# ステータス画面 QA判断ログ

最終更新: 2026-07-17 / 状態: STATUS-R5B 採用・freeze（独立レビュー待ち）
参照画像: reference/08_status_screen_mockup.png
QA更新コマンド: ./tools/status_visual_qa.sh

## 1. freeze値（正本）

現在有効な値だけを書く。値を更新したら該当行を**上書き**する（追記して古い行を残さない）。

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 現在難易度 | ヘッダー左クラスタに「難易度: <name>」を1回 | `src/ui/status_screen.gd` | `PlayerProgress.difficulty()["name"]`の実値。重複情報なし |
| ヘッダー外形 | 現行矩形を維持 | `src/ui/status_screen.gd` | `PlayerStatusBar`・3ペイン・フッターを不動 |
| R5-B全画面shell | 外周18pxの木・真鍮frame。中央は透過して既存港背景を維持 | `assets/showcase/status/status_screen_shell.png` | header/3ペイン/footerを同じ外装世界へ束ねるscreen-local素材 |
| R5-B 3ペイン枠 | 共通screen-local 9-slice、texture margin 24px。3ペイン外形は不動 | `assets/showcase/status/status_panel_frame.png` | 木・真鍮・羊皮紙を1枚のauthored素材へ統合。最小幅約329px/高さ約482pxでcontent wellを維持 |
| R5-B header/footer枠 | 共通screen-local 9-slice、texture margin 18px。矩形は不動 | `assets/showcase/status/status_dark_frame.png` | 濃紺well + 木・真鍮。最小高さ約73pxのfooterでも上下margin間にcontent wellを維持 |
| 中央プレイヤーhero | `StatusSummaryBadge`内の海釣り人円形portrait。badge外形約x419–529 / y184–298、既存portrait slotを維持 | `src/ui/status_screen.gd` | 文字/UI/魚なしのscreen-local authored素材。「記録」はruntime描画を維持 |
| 入力focus契約 | 初期=`StatusTitleListButton`。Tab順=`TitleList → FishBook → Cooking → Return`の閉路。称号overlay中は`StatusTitleOverlayCloseButton`だけ | `src/ui/status_screen.gd` | Escapeは通常時harborへ1回、overlay中は閉じるだけ。Enter/Escape後はopenerへ復帰 |

## 2. 不採用・再試行禁止リスト

| 案 | 却下理由 | 判断日 |
|---|---|---|

## 3. 微調整カウンタ

| パラメータ | 回数 | 直近の変更内容 | 状態 |
|---|---|---|---|
| 難易度表示余白 | 0 | 初回採用値でnormal/hardとも収まり | freeze |
| 中央hero矩形/円形crop | 0 | 既存slotのまま初回候補を採用 | freeze |
| R5-B frame margin / 3ペイン外形 | 0 | 初回24px/18px候補を原寸normal/hardで採用。外形変更なし | freeze |

## 4. 暫定判定・再検証TODO

- なし。共通`e11_input_focus_probe`は各acceptを同じsetupのfresh画面で隔離し、STATUSの到達4件・accept 4/4・未観測0をverify自身で固定した。

## 5. 現在の残ギャップ

- P3: 参照の外周はより重厚な単一木箱だが、現行の背景可視域とheader/3ペイン/footer矩形を維持する契約上、領域間の港背景は残る。構成再設計なしの追加装飾は行わない。
- P3: 参照と現行のheader/footer情報構成差はR5-B対象外。`PlayerStatusBar`、難易度1回表示、現行3導線を維持する。

## 6. E7状態契約（freeze）

- 局所uplift: E7の現在難易度名をヘッダー左クラスタ内に小さく1回だけ表示する。
- 存在する領域: `PlayerProgress.difficulty()["name"]` を使う「難易度: <名>」。存在しない領域: 倍率詳細、ID、変更操作、他ペインへの重複表示。
- 動かす値: 左ヘッダー内の副文言領域の分割のみ。不動freeze: ヘッダー外形、`PlayerStatusBar`、3ペイン、フッター、素材、配色、フォント。
- 状態契約: normal / hardの実値が同一アンカーに表示され、見切れ・省略・重なりがないこと。

## 7. 判断ログ（直近パスのみ）

2026-07-17 STATUS-R5B局所素材upliftを採用（独立レビュー待ち）。

- スコープ宣言: 動かすのは背景外周、3ペイン背景frame、header/footer背景frameだけ。不動はR5-A portraitの円形crop/矩形、右4指標、3ペイン/header/footer外形、`PlayerStatusBar`、難易度名1回表示、文字・アイコン・ゲージ・魚・数値、全導線、称号overlay/focus trap、保存・成長ロジック。
- 差分Top3: Top1=全画面がフラットな矩形の集合で木・真鍮・紙shellに見えない（R5-B対象P2）、Top2=参照の単一外周木箱との差（現行矩形維持のため残P3）、Top3=header/footer情報構成差（現行UX優先のP3）。
- 変えたもの: OpenAI built-in生成の文字/UIなしsourceを、固定crop・9-slice再構成・濃紺grade・alpha matte除去する決定的processorへ通し、screen-localの紙frame/濃紺frame/外周shellを配線した。runtime描画の質感代替は追加していない。
- 状態契約: 代表=normal、高リスク=hard/カジキ竿・蒼槍の長文最大寄り状態/称号overlay。normal/hardは同一seed・同一データで難易度実値と安全域だけが変わる。全状態でheader/3ペイン/footerとR5-A hero矩形は同じanchorを維持する。
- 採否: 原寸normal/hardでbeforeの平坦な茶枠へ明確に勝ち、320×180のbefore/after/referenceでafterは木・真鍮・紙の画面全体の反復が参照へ近づいた。grayscaleでも大ペインと濃紺header/footerの階層を維持。長文とoverlayに見切れ・枠侵入なし。
- 証拠: `docs/qa/evidence/status/2026-07-17_r5b_{before,after}_{normal,hard}.png`、`2026-07-17_r5b_after_{normal,hard}_reference_compare.png`、`2026-07-17_r5b_{thumbnail,gray}_compare.png`、`2026-07-17_r5b_long_content.png`、`2026-07-17_r5b_title_overlay.png`。
- processor契約: clean状態相当から2回実行し、2回目は3製品すべて`unchanged`。file SHA-256とdecoded-pixel SHA-256が不変で、同値時は既存bytes保持、真の差だけ同一directory tempからatomic replace。
- 固定条件: 9-slice margin 24px/18px、3ペイン/header/footer外形、R5-A heroを再調整しない。素材品質をruntime線やwashの追加で追わない。

2026-07-17: INPUT統合後のV0 visual baselineを、V1 `STATUS-R5B` 着手前状態として再固定。

- 実行: `./tools/status_visual_qa.sh`（normal / hard同一preview契約、両captureとreference比較生成 green）。
- 証拠: `docs/qa/evidence/status/2026-07-17_v1_prebaseline_{normal,hard}.png` と同名の `_reference_compare.png`。各1280x720。
- 固定条件: R5-Bは背景・3ペイン・ヘッダー/フッターのscreen-local木・真鍮・紙フレームだけを対象とし、R5-A portraitの円形crop、右4指標、3ペイン外形、`PlayerStatusBar`、難易度1回表示、導線、称号overlay、保存・成長ロジックをこのbaselineから回帰させない。

2026-07-16 INPUT-STATUS局所upliftを採用。

- 変えたもの: defaultの4操作を共通focus契約へ登録し、Tab/Shift+Tabと方向graphをenabled候補内の閉路にした。称号一覧は閉じるButtonだけへfocusをtrapし、Enter/Escape後にopenerへ復帰する。通常Escapeはharborへpress+echoで1回だけ遷移する。
- 変えていないもの: `PlayerStatusBar`、難易度表示、3ペイン、hero、称号文言/獲得判定、釣果/所持品/料理ログ、フッター矩形、素材、配色、フォント、normal/hard実値、保存・成長ロジック。
- 状態契約: 代表=normal初期focus、高リスク=称号overlay。A→B→Aでheader/3ペイン/footer/4操作の矩形が一致し、normal/hardでも同じ入力graphとanchorを維持する。overlayは背景mouse入力を遮断する。
- 証拠: `docs/qa/evidence/status/2026-07-16_input_initial_focus.png`、`2026-07-16_input_overlay_focus.png`。各1280×720を単独で実見し、focus可視・見切れ・重なり・背景focus漏れのP1がないことを確認した。
- 回帰確認: `status_input_smoke`（旧実装red→新実装green）、`status_smoke`、`status_visual_qa.sh`（normal/hard capture green）。親統合後の共通E11はSTATUS findings 0、到達4件・accept 4/4・cancel 1・孤立0。新規smokeを含むrelease manifest 46対象と`e11_qa_harness_verify.sh`もgreen。
- 固定条件: modal trapを共通probe都合で弱めない。レイアウト・素材・表示階層の変更は本input concernへ混ぜない。
