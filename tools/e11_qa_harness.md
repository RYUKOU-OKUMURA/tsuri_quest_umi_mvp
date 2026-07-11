# E11 入力フォーカス／解像度 QA ハーネス

## 目的

E11-INPUT-COMMON と E11-DISPLAY の実装前後を同じ契約で計測する中立な probe。現行画面や `project.godot` は変更せず、製品側の不足を機械可読 `findings` として記録する。probe 自身のロード・生成・出力失敗は `harness_error` または終了コード 2 とし、製品 findings と区別する。

## 実行

```bash
./tools/e11_qa_harness_verify.sh
```

個別 probe は既定で `/tmp/e11_input_focus_probe.json` と `/tmp/e11_resolution_probe.json` に JSON を出力する。`--output <path>` で変更できる。通常モードは findings があっても終了コード 0、後続タスクで使う `--strict` は findings が1件以上なら終了コード 1となる。`--self-test` は正常・異常fixtureと幾何計算を検証する。

JSON 共通項目は `schema_version`、`probe`、`mode`、`harness_status`、`product_status`、`findings`。各 finding は `code`、`severity`、`target`、`message`、`evidence` を持つ。

## Baseline（2026-07-12、基点 `faf465331c2f9938edca3270a95edfd5487cab1b`）

基点 `faf465331c2f9938edca3270a95edfd5487cab1b` の製品状態を、修正版ハーネスと隔離HOME 3回で再計測したhistorical snapshot。現行12対象（title、harbor、釣り場選択、釣行READY、調理、市場、釣具店、造船所、ステータス、魚図鑑、依頼、生簀）を走査した。これは合格記録でも、後続製品改善後に固定件数を要求するassertでもない。

- 入力: 40 findings（隔離3回でcode/target集合一致）。初期focus未観測 11、初期focusからの孤立 10、状態契約に対する戻る未観測 9、全辺走査でdisabledへ到達 8、focus可能要素なし 2。shipyardの戻るnavigationは観測済みで、findingに含まれない。StyleBox実効値とfocusテーマ色を含む可視署名では、この基点の対象に不足findingは出なかった。
- 表示: 4 findings。設計viewportは1280x720、stretch modeは`canvas_items`だが、aspectは要求の`keep`ではなく現行`expand`。加えて3解像度すべてでruntime観測値と想定`keep`契約の不一致を報告する。
- 解像度計測: 各条件へruntime windowを実際に変更し、window size、viewport visible rect、content scale size/aspect/modeを記録する。1280x720は想定content 1280x720・黒帯なし。1280x800（16:10）は想定content 1280x720・上下40px。1024x768（4:3）は想定content 1024x576・上下96px。JSONでは計算値を `expected_black_bars` として明示する。headless probeは黒帯の実ピクセル色を証明しないため、非headless解像度visual QAへのhandoffを必須項目として出力する。
- release discovery / manifest: 件数を固定せず集合一致を検証する。`e11_*_probe.tscn` は smoke/audit 命名を避けており release gate へ自動混入しない。

入力の「戻る／決定／方向」は `InputEventAction` をruntime viewportへ送る。全visible/enabled要素から6方向の辺を作り、初期focusからBFSで到達集合・孤立・任意長の循環・disabled到達を記録し、到達可能な各Buttonへ決定を送る。戻るはfocusの有無にかかわらず送り、registryの `navigation` / 明示node-property / `none` 契約で判定する。画面全体の変化はアニメーションによる偽合格を招くため使わない。focus可視性はStyleBoxとnested built-in Resourceの実効プロパティ、テーマ色の署名で比較し、custom drawはregistryで明示しない限りunknownをpassにしない。

registryは `src/main.gd` の全screen preloadを照合する。`settings_screen.gd` が存在する統合後はsettingsを自動登録し、12画面から13画面へ増えてもverifyは固定件数を要求しない。strict終了コードは製品のlive findingsではなく専用fixtureで pass=0 / finding=1 / harness error=2 を検証する。
