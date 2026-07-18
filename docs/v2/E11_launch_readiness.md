# V2 / E11. ローンチ準備（販売に耐える外周の構築）

正本: `docs/30_v2_expansion_overview.md`（読む順: docs/30 §4 共通仕様 → 本doc）
前提フェーズ: 実施時期は分割型（下記 §E11-0）。画面実装はE7完了後
状態: E11進行中（SETTINGS-AUDIO、SLOT-DELETE UI、DISPLAY、INPUT-COMMON、画面別INPUT全round、3スロット、素材台帳基盤、Release Gate 0、ID-01完了）。入力baselineは0件（13画面すべてfinding 0）。残りはEXTERIOR、最終受入。進行状況はdocs/30 §6、監査追加事項はdocs/45参照

目的: ローンチ対象（E0〜E7＋E10）の外周——設定・セーブ保護・表示・入力・権利・export・製品外装——を販売品質にする。2026-07-10の横断監査結果はdocs/45を正とする。

## E11-0. 実施時期（フェーズ内で時期が分かれる）

| タスク | 実施時期 | 理由 |
|---|---|---|
| E11-5 素材台帳の運用開始 | **即時**（docs/31 作成済み。以後は新素材と同コミットで追記） | 時間が経つほど出所を思い出せなくなる |
| 3スロット | **E3で完了済み** | 旧単一save→slot 1を含め実装済み。E11では回帰対象 |
| E11-7 Release Gate 0の5件 | **2026-07-11確定済み** | 決定値をexport、設定、入力、表示、製品外装へ引き渡す |
| ID-01: user data namespace / OS application ID / store識別子 / 旧save移行 | **2026-07-11完了** | 正式名称変更前に固定し、旧MVP saveを非破壊コピー |
| 最小export spike / 権利証跡 | **E7と並走または先行** | 正式名称変更と最終パッケージの手戻りを防ぐ |
| E11-4・6・EXTERIORの実装 | **E7完了後・ローンチ前** | SETTINGS-AUDIO / SLOT-DELETE UI / DISPLAY / INPUT-COMMONは完了済み。残りのEXTERIORと最終受入を締める |

## E11-1. 設定画面（新画面）

- 新画面 `src/ui/settings_screen.gd`「せってい」。導線はタイトル画面＋港画面メニュー
- 項目（最小構成）:
  1. **BGM音量 / SE音量**（スライダー。`AudioServer` のバス操作。現状バス未分離のため `default_bus_layout.tres` に `Master` 直下の `BGM` / `SE` バスを新設し、既存の再生箇所をバス指定へ寄せる）
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
4. **意味検証付き候補選択**: 先にdocs/30へversion 1の必須 / 任意key・型・意味範囲・正常な疎save fixtureを定義し、その契約でmain / backupを採用する。疎な旧saveを破損扱いしない。`load_game()`とtitleの`save_slot_summary()`は同じ候補選択結果を使い、表示要約と実ロードを一致させる
5. **旧依頼repair**: load時に未知魚・サメ・ヌシなど達成不能な旧依頼を除去し、正常依頼を維持したまま3件へ補充する
6. **3スロット（決定#17）**: E3で実装済み。`user://slots/<n>/`、旧save→slot 1、backup/tmp分離を回帰対象として維持する
7. チート対策は**しない**（シングルプレイヤー・子供向け。JSON平文を許容する方針を明記）

## E11-3. 表示・解像度

- §E11-7 の確定方針に従い、`stretch/aspect="keep"`＋黒帯へ変更する
- 1280x720に加え、16:10 / 4:3でゲーム領域が16:9のまま維持され、余剰領域が黒帯となることを実スクショで確認する。全画面スクショ比較は既存 visual QA スクリプトに解像度パラメータを足して流用する
- ID-01でGodot user data namespaceを`tsuri_quest_umi`へ固定し、旧`Godot/app_userdata/釣りクエスト ～海釣り編～ MVP`配下のsave artifactを、新側saveが空の初回だけ旧原本保持でコピーする。移行marker・tmp・hash照合により再コピーと上書きを防ぐ
- macOS bundle ID=`net.physical-balance-lab.tsuri-quest-umi`、itch.io予定slug=`tsuri-quest-umi`、store App ID=`未発行`として分離記録済み。bundle IDのpreset配線は最小export spikeで行う
- `config/name`からのMVP除去とruntime version表記は、ID-01回帰と最小export spikeを通過後、E11-EXTERIORで行う
- 正式名、runtime version表記、専用icon、ブートスプラッシュを設定（差し替え素材はdocs/31台帳へ記入）

## E11-4. 入力

- §E11-7 の確定方針に従い、対応入力は**マウス＋キーボード専用**とし、ゲームパッドには対応しない。ストアページと製品文書にも同じ対応範囲を明示する
- マウスでは全操作対象のクリック到達性、キーボードでは各画面の初期focus・隣接遷移・決定・戻る・disabled項目のスキップと可視focusを実操作で確認する。ゲームパッド操作は検証対象に含めない
- 釣行中の中断（ウィンドウを閉じる）は現行の「ファイト中の魚を失うだけ・進行は直前セーブ済み」を仕様として明文化（対策コード不要）
- INPUT-COMMONは2026-07-15完了。実キー8 action、共通focus / cancel契約、13画面registry、self-test / baseline / strict harnessを統合し、初期の画面別baselineは42件（P1 34 / P2 8）
- 画面別INPUT第1roundは2026-07-15完了。TITLE / FISHING / SHIPYARDを別セッションで実装・独立レビューし、専用smokeと原寸証拠を固定。3画面のfindingを0件にしてbaselineを35件（P1 27 / P2 8）へ更新した
- 画面別INPUT第2roundは2026-07-15完了。SETTINGS / FISHING_SPOTS / SHOPを別セッションで実装・独立レビューし、専用smokeと原寸証拠を固定。3画面のfindingを0件にしてbaselineを24件（P1 18 / P2 6）へ更新した
- 画面別INPUT第3roundは2026-07-16完了。HARBOR / FISH_BOOK / MARKETを別セッションで実装・独立レビューし、動的lock、88操作の図鑑閉路、modal / empty復帰を専用smokeと原寸証拠へ固定。3画面のfindingを0件にしてbaselineを15件（P1 11 / P2 4）へ更新し、release verifier 43対象もgreen
- 画面別INPUT第4roundは2026-07-16完了。STATUS / COOKING / QUEST_BOARDを別セッションで実装・独立レビューし、称号modal trap、調理5状態handoff、依頼の納品/記録報告後の即時入替を専用smokeと原寸証拠へ固定。3画面のfindingを0件にしてbaselineを4件（P1 3 / P2 1）へ更新し、release verifier 46対象もgreen
- 画面別INPUT最終roundは2026-07-16完了。SHARK_PENを単独で実装・独立レビューし、通常、last-stock、locked/empty、A→B→A、マウス/Escape一重を専用smokeと原寸証拠へ固定。13画面すべてfinding 0、入力baselineを0件へ更新し、release verifier 47対象もgreen。残りはEXTERIOR、最終受入

## E11-5. 権利・台帳（docs/31）

- RIGHTS-01A（出所・入力権利・icon・商標・権利者名）は素材差し替えへ発展し得るためRC固定前に完了する。RIGHTS-01B（notice / Godot由来license / OFL / 質問票の最終成果物確認）は固定したRC exportに対して行う
- `docs/31_asset_ledger.md` の「要記入」をゼロにする（音源10件・AI生成画像の生成手段と商用条件）
- タイトル「釣りクエスト」の商標調査
- `LICENSE.md` の権利者名と適用範囲を確定し、Godot・font・その他同梱依存を `THIRD_PARTY_NOTICES.md` 相当へ列挙。必要なlicense本文が最終配布物に含まれることを確認
- 子供向けレーティング（IARC等。チャネル決定後にそのストアの手順で）

## E11-6. チャネル固有要件（§E11-7 の決定後に確定）

- 対象OSごとの `export_presets.cfg` を追加し、debug / release exportを再現可能にする
- ID-01の確定値を使って最小export spikeを行い、bundle IDの実配線、clean user dataでの起動・新規save・再起動読込、旧MVP namespaceコピーを確認する
- launch candidateでは成果物hash、Godot版、対象OS、対象OS / チャネルで必要な署名 / 公証状態を記録する
- `tools/release_verify.sh`相当で全smoke / audit、未説明ERROR、save移行、export起動を1コマンド化する。対象は固定本数を埋め込まず、manifest / 自動列挙で追加sceneを取りこぼさない

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

セーブスロット数は決定#17の3スロットで解消済み。上表はdocs/30決定#20と同期する。ID-01ではuser data namespace=`tsuri_quest_umi`、macOS bundle ID=`net.physical-balance-lab.tsuri-quest-umi`、itch.io予定slug=`tsuri-quest-umi`、store App ID=`未発行`を正式名称とは別に固定し、旧MVP namespaceの非破壊コピー移行を実装した。`config/name`の正式名称反映は最小export spike後のE11-EXTERIORで行う。macOSの最低対象ハードウェア / 性能計測の基準機も、PERF-RELEASE着手前の別技術判断として記録する。

## E11-8. 並列実装構成

共有ハブを持つ実装は、次のsettings spineとして単一ownerが直列統合する。

`E11-SETTINGS-AUDIO → E11-SLOT-DELETE UI → E11-DISPLAY → E11-INPUT-COMMON（ここまで完了）→ E11-EXTERIOR`

- `E11-SLOT-DELETE`のbackend（`player_progress.gd`とsave smoke）だけはstateレーンが先行できる。settings側は公開APIを消費し、同じファイルを触らない
- `E11-INPUT-COMMON`はゲームパッド採用時だけの任意briefではない。確定済みの**マウス＋キーボード**範囲に対し、全画面のinitial focus、隣接遷移、決定、戻る、disabled skip、可視focusを監査する必須sliceとする
- INPUT-COMMON後、失敗画面を1画面1briefへ分けて並列修正する。`title_screen.gd`と`settings_screen.gd`はsettings spineが保持する
- 最小export担当は `export_presets.cfg` / `export_launch_smoke.*`、release verifier担当はmanifest / runner / CIを所有する。`release_verify.sh`やexport smokeを二重所有しない
- 権利担当は配布要件を最小export担当へ渡し、`export_presets.cfg`を直接編集しない
- `project.godot`は最小export完了後にsettings spineへownerを渡し、EXTERIOR後に最終export担当へ戻す
- EXTERIORでicon / splashを追加・差し替えるcommitは、権利担当を止めて`docs/31`もsettings spineへownerを移し、素材と台帳を同じcommitへ入れる
- 共有ハブを編集しないinput audit harness、visual QA matrix、権利証跡、release verifier、製品文書草案はspineと並列化できる

詳細なwave、owner移譲、RC Gateはdocs/30 §6を正とする。

## E11-9. slice別touch / E11実装DoD

ID-01で固定した `project.godot` の `config/use_custom_user_dir=true` と `config/custom_user_dir_name="tsuri_quest_umi"` は**freeze**とし、E11では編集しない。旧namespace移行は回帰確認だけを行う。

| slice | 触ってよいファイル |
|---|---|
| E11-SETTINGS-AUDIO | `src/ui/settings_screen.gd`（新設）、`src/ui/title_screen.gd`、`src/ui/harbor_screen.gd`、`src/main.gd`、`src/ui/screen_base.gd`、`src/ui/components/catch_fanfare.gd`、`default_bus_layout.tres`（新設）、`tools/settings_smoke.gd` / `.tscn`（新設） |
| E11-SLOT-DELETE backend（state owner） | `src/autoload/player_progress.gd`、`tools/save_system_smoke.gd`、`tools/save_system_verify.sh` |
| E11-SLOT-DELETE UI（settings spine） | `src/ui/settings_screen.gd`、`src/ui/title_screen.gd`、`src/main.gd`、`tools/settings_smoke.gd` / `.tscn` |
| E11-DISPLAY | `src/ui/settings_screen.gd`、`project.godot`（表示設定だけ）、`tools/settings_smoke.gd` / `.tscn`、解像度別preview / visual QA script |
| E11-INPUT-COMMON | `project.godot`（input mapだけ）、`src/ui/screen_base.gd`、`tools/e11_input_focus_probe.gd` / `.tscn`、`tools/e11_qa_harness_verify.sh` |
| INPUT-<SCREEN> | 監査で失敗した1画面のscreen / smoke / QA / evidenceだけ。1画面1brief |
| INPUT-FISHING例外 | `src/ui/fishing_screen.gd`、画面所有の入力component（`fight_hud.gd` / `catch_fanfare.gd`）、専用input smoke、釣行QA / evidence。custom `Rect2`とFIGHT press/releaseを実viewport eventで検証するため |
| E11-EXTERIOR | `project.godot`（name / version / icon / splashだけ）、`src/ui/title_screen.gd`、製品icon / splash、title preview / visual QA / QA、owner移譲中の`docs/31_asset_ledger.md` |

REL-01の `export_presets.cfg` / export smokeと、QA-RELEASEのmanifest / runner / CIはE11実装sliceのtouch範囲に含めない。docs/30 §6の別レーンで実装し、E11 Gateでは回帰結果だけを受け取る。
QA-RELEASEのRC証跡は、全smoke完了後のdebug/release `.app` をdirectory・file・symlink・mode・file hashまで列挙したcanonical manifestとlive treeの一致を必須とする。PCK / pack manifestだけの旧証跡は再exportする。

E11実装DoD:

1. `settings_smoke`: BGM / SE音量とfullscreenの変更→保存→再起動相当→復元、破損`settings.json`の初期値復帰
2. 対象1slotの二重確認削除、main / backup / tmp削除、他slot / settings不変、削除slot非再生成
3. `save_system_verify.sh`: 3slot、旧save→slot 1、ID-01 namespace移行、future版guard、意味破損main→backup、書込失敗、旧依頼repair
4. 1280×720 / 16:10 / 4:3の全画面runtime visual QAで`keep`＋黒帯を確認
5. マウス＋キーボードのinitial focus・隣接遷移・決定・戻る・disabled skip・可視focusを全画面で確認
6. 正式名 / v1.0.0 / icon / splashをruntime titleと最小export回帰で確認。U-04のicon採否をEXTERIOR前にcloseし、新素材は台帳と同じcommit
7. SAVE-02のセーブ失敗トーストと終了時「再試行 / 保存せず終了」を回帰確認
8. settings smoke、save回帰、対象visual QA、`./tools/validate_project.sh`がgreen

release verifier最終実行、RIGHTS-01A/B全体、製品文書、性能/soak、9セル受入、署名/公証、配布はE11実装DoDへ含めない。docs/30 §6のPre-RC / RC / Launch Gateで管理する。
