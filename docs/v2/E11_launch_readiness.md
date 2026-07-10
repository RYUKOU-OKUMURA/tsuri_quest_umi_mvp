# V2 / E11. ローンチ準備（販売に耐える外周の構築）

正本: `docs/30_v2_expansion_overview.md`（読む順: docs/30 §4 共通仕様 → 本doc）
前提フェーズ: 実施時期は分割型（下記 §E11-0）。画面実装はE7完了後
状態: 一部完了（3スロット、素材台帳基盤）。実装部はE7後。進行状況はdocs/30 §6、監査追加事項はdocs/45参照

目的: ローンチ対象（E0〜E7＋E10）の外周——設定・セーブ保護・表示・入力・権利・export・製品外装——を販売品質にする。2026-07-10の横断監査結果はdocs/45を正とする。

## E11-0. 実施時期（フェーズ内で時期が分かれる）

| タスク | 実施時期 | 理由 |
|---|---|---|
| E11-5 素材台帳の運用開始 | **即時**（docs/31 作成済み。以後は新素材と同コミットで追記） | 時間が経つほど出所を思い出せなくなる |
| 3スロット | **E3で完了済み** | 旧単一save→slot 1を含め実装済み。E11では回帰対象 |
| E11-7 Release Gate 0の5件 | **2026-07-11確定済み** | 決定値をexport、設定、入力、表示、製品外装へ引き渡す |
| user data namespace / OS application ID / 最小export spike / 権利証跡 | **E7と並走または先行** | 正式名称変更と最終パッケージの手戻りを防ぐ |
| E11-1〜4・6 の実装 | **E7完了後・ローンチ前** | ゲーム内容確定後に外周を締める |

## E11-1. 設定画面（新画面）

- 新画面 `src/ui/settings_screen.gd`「せってい」。導線はタイトル画面＋港画面メニュー
- 項目（最小構成）:
  1. **BGM音量 / SE音量**（スライダー。`AudioServer` のバス操作。現状バス未分離のため `Master` 直下に `BGM` / `SE` バスを新設し、既存の再生箇所をバス指定へ寄せる）
  2. **フルスクリーン切替**（`DisplayServer.window_set_mode`）
  3. **現在対象の1スロットを削除**（二重確認ダイアログ必須。タイトルからは選択slot、港からはactive slot。slot番号・Lv・プレイ時間を表示）
- 削除対象は当該slotのmain / backup / tmpだけ。削除後は当該runtime stateを初期化してタイトルへ戻し、他2slotと `settings.json` は変更しない。終了時auto-saveで削除slotを再生成しないこと
- 設定の保存は `user://settings.json`（セーブ本体と分離。破損してもゲーム進行に影響させない）
- 子供向けUIなので文字は大きく、項目は増やさない。キーコンフィグはやらない（§E11-7 の入力方針決定に従う）
- 新画面のため `skills/ui-screen-build/` 工程。ただし装飾は既存共通素材の流用を第一候補にし、専用素材は最小限

## E11-2. セーブの販売品質化

1. **将来版guard**: `version > SAVE_VERSION` の対象slotだけ通常ロード・保存を許可せず、そのmain / backup / tmpを変更しない。他2slotは利用可能で、slot切替時にguardを再評価する。対応版が必要なことをUI通知する
2. **セーブ失敗の伝播**: `save_game()` が成功 / 失敗を返し、tmp open・backup rename・final rename失敗を `save_failed(message)` と共通トーストへ伝える
3. **終了時失敗**: 保存失敗でも即quitせず、「再試行 / 保存せず終了」を選べる
4. **意味検証付き候補選択**: 先にdocs/30へversion 1の必須 / 任意key・型・意味範囲・正常な疎save fixtureを定義し、その契約でmain / backupを採用する。疎な旧saveを破損扱いしない
5. **旧依頼repair**: load時に未知魚・サメ・ヌシなど達成不能な旧依頼を除去し、正常依頼を維持したまま3件へ補充する
6. **3スロット（決定#17）**: E3で実装済み。`user://slots/<n>/`、旧save→slot 1、backup/tmp分離を回帰対象として維持する
7. チート対策は**しない**（シングルプレイヤー・子供向け。JSON平文を許容する方針を明記）

## E11-3. 表示・解像度

- §E11-7 の確定方針に従い、`stretch/aspect="keep"`＋黒帯へ変更する
- 1280x720に加え、16:10 / 4:3でゲーム領域が16:9のまま維持され、余剰領域が黒帯となることを実スクショで確認する。全画面スクショ比較は既存 visual QA スクリプトに解像度パラメータを足して流用する
- `config/name` から「MVP」を外す前に、Godotのuser data namespace（custom user directory name相当）を固定し、旧名称配下saveの移行要否を検証する
- user data namespace、対象OSのapplication / bundle ID、チャネル発行のstore App IDを別々に記録する。store App ID未発行時は空欄ではなく「未発行」
- 正式名、runtime version表記、専用icon、ブートスプラッシュを設定（差し替え素材はdocs/31台帳へ記入）

## E11-4. 入力

- §E11-7 の確定方針に従い、対応入力は**マウス＋キーボード専用**とし、ゲームパッドには対応しない。ストアページと製品文書にも同じ対応範囲を明示する
- マウスでは全操作対象のクリック到達性、キーボードでは各画面の初期focus・隣接遷移・決定・戻る・disabled項目のスキップと可視focusを実操作で確認する。ゲームパッド操作は検証対象に含めない
- 釣行中の中断（ウィンドウを閉じる）は現行の「ファイト中の魚を失うだけ・進行は直前セーブ済み」を仕様として明文化（対策コード不要）

## E11-5. 権利・台帳（docs/31）

- `docs/31_asset_ledger.md` の「要記入」をゼロにする（音源10件・AI生成画像の生成手段と商用条件）
- タイトル「釣りクエスト」の商標調査
- `LICENSE.md` の権利者名と適用範囲を確定し、Godot・font・その他同梱依存を `THIRD_PARTY_NOTICES.md` 相当へ列挙。必要なlicense本文が最終配布物に含まれることを確認
- 子供向けレーティング（IARC等。チャネル決定後にそのストアの手順で）

## E11-6. チャネル固有要件（§E11-7 の決定後に確定）

- 対象OSごとの `export_presets.cfg` を追加し、debug / release exportを再現可能にする
- user data namespaceとOS application / bundle ID確定直後に最小export spikeを行い、clean user dataで起動・新規save・再起動読込を確認する
- launch candidateでは成果物hash、Godot版、対象OS、対象OS / チャネルで必要な署名 / 公証状態を記録する
- tools/release_verify.sh相当で全smoke / audit、未説明ERROR、save移行、export起動を1コマンド化する

| チャネル | 追加要件の例 |
|---|---|
| Steam | ストアページ素材、**AI生成コンテンツの開示申告**（Valveのコンテンツ調査。画像=OpenAI・音源=Suno を申告、ストアページに表示される。docs/31 §4）、実績（任意）、クラウドセーブ（任意。3slotのmain / backup / tmpとsettingsのうち同期対象を別途決定）、Steam Deck 動作確認（16:10表示と入力） |
| itch.io | ストアページ素材のみ。最小 |
| モバイル | タッチ入力対応（大工事）・ストア審査・IARC必須。**本V2スコープでは非推奨** |

## E11-7. Release Gate 0（2026-07-11確定）

| # | 項目 | 決定内容 | 決定日 |
|---|---|---|---|
| 1 | 初回販売チャネル | itch.io | 2026-07-11 |
| 2 | 対象OS / 配布形式 | macOS Universal（Apple Silicon＋Intel） | 2026-07-11 |
| 3 | 対応入力 | マウス＋キーボード専用（ゲームパッド非対応） | 2026-07-11 |
| 4 | 非16:9の表示方針 | `keep`＋黒帯 | 2026-07-11 |
| 5 | 正式名称 / version表記 | 「釣りクエスト ～海釣り編～」/ v1.0.0 | 2026-07-11 |

セーブスロット数は決定#17の3スロットで解消済み。上表はdocs/30決定#20と同期する。後続ID-01では、Godotのuser data namespace、macOSのOS application / bundle ID、itch.ioのstore App IDを正式名称とは別の値として記録する。store App IDが未発行なら「未発行」と記録し、user data namespaceと旧save移行方針を固定してから`config/name`へ正式名称を反映する。macOSの最低対象ハードウェア / 性能計測の基準機も、PERF-RELEASE着手前の別技術判断として記録する。

## E11-8. 触ってよいファイル / DoD

- 触る: `settings_screen.gd`（新設）, `title_screen.gd`・`harbor_screen.gd`（導線）, `player_progress.gd`（save hardening）, `screen_base.gd`（トースト）, `project.godot`（バス・input map・user data namespace・name・icon）, `export_presets.cfg`（OS application ID・新設）, `tools/settings_smoke.tscn`（新設）, release検証tool（新設）
- DoD:
  1. `settings_smoke`: 音量変更→保存→再起動相当→復元の一巡、対象1slotの削除二重確認、main / backup / tmp削除、他slot / settings不変、削除slot非再生成
  2. `save_system_verify.sh`: 3slot、旧save→slot 1、future版対象slotだけ非破壊 / 他slot利用可 / guard再評価、意味破損main→backup、書込失敗、旧依頼repair
  3. セーブ失敗トーストと終了時「再試行 / 保存せず終了」
  4. 表示方針に応じた全画面の解像度別runtime visual QA
  5. 対応入力の初期focus・隣接遷移・決定・戻る・disabledを実操作
  6. 対象OSのdebug / release export、clean環境起動、新規save / 再読込
  7. tools/release_verify.sh相当で全25 smoke / auditと未説明ERRORを一括判定
  8. docs/31の要記入 / 推定 / 保存待ち0、商標・AI開示・icon、LICENSE / THIRD_PARTY_NOTICESをclose
  9. 3難易度の序盤・中盤・終盤を人手受入
  10. README / VALIDATION / CHANGELOG / MANIFESTを最終成果物へ同期
  11. 対象ハードウェアで1280x720・60fps目標を計測し、30分soakでcrash・進行不能・無制限なresource増加がない
  12. validate green、対象OS / チャネルで必要な署名 / 公証を施した最終成果物を確認
