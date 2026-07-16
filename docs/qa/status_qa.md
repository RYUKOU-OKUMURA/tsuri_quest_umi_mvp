# ステータス画面 QA判断ログ

最終更新: 2026-07-16 / 状態: INPUT-STATUS close・freeze
参照画像: reference/08_status_screen_mockup.png
QA更新コマンド: ./tools/status_visual_qa.sh

## 1. freeze値（正本）

現在有効な値だけを書く。値を更新したら該当行を**上書き**する（追記して古い行を残さない）。

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 現在難易度 | ヘッダー左クラスタに「難易度: <name>」を1回 | `src/ui/status_screen.gd` | `PlayerProgress.difficulty()["name"]`の実値。重複情報なし |
| ヘッダー外形 | 現行矩形を維持 | `src/ui/status_screen.gd` | `PlayerStatusBar`・3ペイン・フッターを不動 |
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

## 4. 暫定判定・再検証TODO

- なし。共通`e11_input_focus_probe`は各acceptを同じsetupのfresh画面で隔離し、STATUSの到達4件・accept 4/4・未観測0をverify自身で固定した。

## 5. 現在の残ギャップ

- R5-B候補: 参照に対する全画面の木・真鍮・紙のauthored枠質感差。本R5-Aとは独立concernのため未着手。

## 6. E7状態契約（freeze）

- 局所uplift: E7の現在難易度名をヘッダー左クラスタ内に小さく1回だけ表示する。
- 存在する領域: `PlayerProgress.difficulty()["name"]` を使う「難易度: <名>」。存在しない領域: 倍率詳細、ID、変更操作、他ペインへの重複表示。
- 動かす値: 左ヘッダー内の副文言領域の分割のみ。不動freeze: ヘッダー外形、`PlayerStatusBar`、3ペイン、フッター、素材、配色、フォント。
- 状態契約: normal / hardの実値が同一アンカーに表示され、見切れ・省略・重なりがないこと。

## 7. 判断ログ（直近パスのみ）

2026-07-16 INPUT-STATUS局所upliftを採用。

- 変えたもの: defaultの4操作を共通focus契約へ登録し、Tab/Shift+Tabと方向graphをenabled候補内の閉路にした。称号一覧は閉じるButtonだけへfocusをtrapし、Enter/Escape後にopenerへ復帰する。通常Escapeはharborへpress+echoで1回だけ遷移する。
- 変えていないもの: `PlayerStatusBar`、難易度表示、3ペイン、hero、称号文言/獲得判定、釣果/所持品/料理ログ、フッター矩形、素材、配色、フォント、normal/hard実値、保存・成長ロジック。
- 状態契約: 代表=normal初期focus、高リスク=称号overlay。A→B→Aでheader/3ペイン/footer/4操作の矩形が一致し、normal/hardでも同じ入力graphとanchorを維持する。overlayは背景mouse入力を遮断する。
- 証拠: `docs/qa/evidence/status/2026-07-16_input_initial_focus.png`、`2026-07-16_input_overlay_focus.png`。各1280×720を単独で実見し、focus可視・見切れ・重なり・背景focus漏れのP1がないことを確認した。
- 回帰確認: `status_input_smoke`（旧実装red→新実装green）、`status_smoke`、`status_visual_qa.sh`（normal/hard capture green）。親統合後の共通E11はSTATUS findings 0、到達4件・accept 4/4・cancel 1・孤立0。新規smokeを含むrelease manifest 46対象と`e11_qa_harness_verify.sh`もgreen。
- 固定条件: modal trapを共通probe都合で弱めない。レイアウト・素材・表示階層の変更は本input concernへ混ぜない。
