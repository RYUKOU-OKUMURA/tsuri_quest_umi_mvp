# UI Wave継続前の全体コードレビューとリファクタ記録

最終更新: 2026-07-14

対象基準: `e4a1ec18`（調理generator決定性修正のmain統合直後）

位置づけ: UIの見た目をさらに改善する前に、製品コード、セーブ境界、画面遷移、QA/release toolingをbehavior-preservingで横断確認した記録。長期構造課題の正本は `docs/47_launch_foundation_code_review.md`、V2進捗は `docs/30_v2_expansion_overview.md` §6、UI判断とfreeze値は `docs/19_ui_production_playbook.md` と `docs/qa/` のまま変更しない。

## 1. 結論

製品挙動と検証基盤を3レーン（core/save、UI/runtime、tooling/release）で監査し、各レーンの実装後に担当を入れ替えてread-onlyレビューした。見つかったP1/P2は独立スライスで修正し、相互レビューで追加検出した4件も修正・再レビューまで完了した。

今回の範囲では、`project.godot`、製品PNG、画面のfreeze値、ゲームバランスを変更していない。UI Waveはこのコード基盤から継続できる。ただし、発売前の機能GateであるE11 INPUT-COMMONは別トラックとして未完了であり、固定RC前に解消する。

## 2. 完了した修正

| concern | commit | 結果 |
|---|---|---|
| 画面遷移の多重実行 | `08f3f845` | `Main._show_screen()`をfirst-winsのsingle-flight化。swap / BGM更新を1回に固定し、遷移中の入力を遮断 |
| save QAの固定HOME競合 | `6cc90c44` | run固有かつscene別HOME、token sentinel、物理path guardへ変更。実ユーザーsaveへの到達を拒否 |
| 破損した保存依頼 | `5b1274f0` | 現行5 template、kind、魚、個数/目標、料理recipe、重複をロード境界で検証し、決定的に3件へ補修 |
| 調理generator gate | `05cb3b33` | production 57 PNGを一時OUTへbyte copyして検証。製品directoryを変更しない必須gateへ統合 |
| 調理overlayの多重close | `e7456c83` | LEVEL_UP / STATUS_SUMMARYをone-shot化し、signal / tween / freeの重複を防止 |
| 破損した食事buff | `b3604f7f` | 非空buffのschemaとrecipe定義一致を検証。意味破損mainは正常backupへfallbackし、不正runtimeの保存を拒否 |
| export外部工程の無期限待機 | `721f6018` | setup / build / smokeへtimeoutとprocess-group cleanupを導入 |
| クーラー魚domainの重複集計 | `f10bb044` | 通常魚+nushi、shark除外、負数clampのpure helperを正本化。料理・ステータス・監査へ適用 |
| export証跡の不足 | `c8bfd7bb` | PCKだけでなくdebug/release `.app` 全体をtype / mode / size / hash / symlink target付きmanifestへ固定 |
| 港だけ異なるクーラー集計 | `77334ae4` | badge、誘導本文、footerを同じinventory helperへ統一 |
| export parent終了後の子process | `b4b361dd` | parentが0/非0で先に終了した場合も同一process groupのdescendantを掃除 |
| fadeの前面保証 | `fce2c5ed` | 画面内`z_index`と独立したCanvasLayerへ移し、高z画面でも描画・入力遮断を維持 |
| cold checkoutの並列import競合 | `abbe719e` | save isolation self-testの実scene並列前に直列editor warm-upを追加。全体と各commandをbounded runnerで監督 |

## 3. 相互レビューで追加検出したP2

| finding | 修正 | 再レビュー |
|---|---|---|
| fadeをMain直下の末尾childに置くだけでは、魚市場など高`z_index`の画面より前面にならない | `fce2c5ed` | P0/P1/P2なし。実MouseButtonで背面button非発火まで行動検証する案は任意P3 |
| 港がinventory全valueを直接加算し、nushi / shark / unknown / 負数のdomain契約と不一致 | `77334ae4` | P0/P1/P2/P3なし |
| export commandの親が正常/非正常終了した後にdescendantが残り得る | `b4b361dd` | P0/P1/P2なし。cleanup不能125分岐のmock注入は任意P3 |
| cold checkoutで2つのGodotが同じ`.godot`を初回importし、isolation self-testが停止 | `abbe719e` | cold `git archive`、通常repo、timeout / descendant cleanupを独立確認 |

## 4. 不変条件

- `project.godot`、`assets/showcase/**/*.png`、`docs/qa/`のfreeze値は変更しない。
- `PlayerProgress`のautoload名、公開API、signal、正常saveの疎payloadと未知field互換を維持する。
- nushiはクーラー表示・売却対象に含めるが、料理対象には追加しない。sharkは生簀domainのためクーラー集計から除く。
- 画面遷移は最初の要求を採用し、遷移中の後続要求を捨てる。未知画面IDの港fallbackとBGM経路を維持する。
- generator検証、save smoke、export smokeはproduction素材や実ユーザーsaveを変更しない。
- 見た目のuplift、入力機能追加、大規模なsave codec/repository分割を今回の修正へ混ぜない。

## 5. 検証

親エージェントはworker報告だけを採用せず、`e4a1ec18..HEAD`の全diffと各修正のfocused fixtureを確認した。最終受入で次を実行する。

- `git diff --check e4a1ec18..HEAD`
- Python syntax、`tools/export_command_runner_self_test.py`、`tools/release_verify_self_test.py`
- `tools/save_system_isolation_self_test.sh`、`tools/save_system_verify.sh`
- main navigation、quest board、harbor、status、cooking flowの各Godot smoke
- `tools/cooking_verify.sh`、`tools/e11_qa_harness_verify.sh`、`tools/validate_project.sh`
- cooking / market / harborのvisual QA（製品画素とfreezeに意図しない差がないこと）
- clean HEADからdebug/release macOS Universal exportを作成し、full app manifest証跡を再読込

既知の非阻害診断は、headless終了時のObjectDB/resource cleanup、任意ObjectDB snapshot directory作成失敗、save負fixtureの警告である。exit codeと説明済みwarning契約を優先し、新しい未説明ERRORは許容しない。

## 6. 別トラックへ残す課題

### E11 INPUT-COMMON（固定RC前の必須Gate）

現行13画面を隔離HOMEで実入力probeし、harness自体は`ok`、製品側は43 findings（P1 34 / P2 9）を再現した。

- P1: 初期focusなし11、disabled到達8、focus孤立10、可視focus style不足3、focus可能要素なし2
- P2: 戻る契約未観測9

これは既存のE11未完了範囲であり、behavior-preservingリファクタへ混ぜない。`docs/v2/E11_launch_readiness.md`のINPUT-COMMONで共通focus契約を先に固定し、その後に失敗画面を1画面1briefで並列修正する。

### 構造・検証のP3

- 通常slot save / deleteのmulti-process lockは未実装。`docs/47` LR-04のbarrier fixtureで必要性を確定してから設計する。
- `PlayerProgress`のsandbox commentと、smokeがguard通過後にsandboxを解除する実装の文言差を整理する。
- release / visual QAのwarning allowlistを、将来はより狭い構造化判定へ分割する。
- fadeの実MouseButton背面遮断と、process-group cleanup不能時の125分岐は任意の負fixture強化候補とする。

## 7. 次の順番

1. E11 INPUT-COMMONの共通基盤を直列実装する。
2. 監査で失敗した画面を1画面1briefで並列修正する。
3. visual UI Waveを画面別に再開する。
4. E11 EXTERIOR、最終受入、固定RCへ進む。

見た目のWaveを先に並行準備することは可能だが、fixed RCを作る前にINPUT-COMMONを必ず収束させる。
