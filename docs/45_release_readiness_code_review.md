# 45. リリース前 全体コード・UI・運用監査レポート

調査日: 2026-07-10
基準コミット: e3a4466e5bbb9140d44775810c72d81c68e37cb6
対象ブランチ: main
Godot: 4.7.stable.official.5b4e0cb0f
状態: 監査完了（基準コミット時点のスナップショット）。現行の是正進捗はdocs/30 §6を正とする
対象規模: src 配下 GDScript 32,413行、画面スクリプト12本、smoke / audit 25本、visual QAスクリプト12本

---

## 0. この文書の役割

本書は、V2をリリースへ持っていく直前に実施した横断監査の結果と、次のAIエージェントがそのまま実装へ移れるタスクキューを保存する引継ぎ文書である。

### 0.1 2026-07-11追補

本書の発見事項本文・open表記・Launch Gateチェックボックスは基準コミット時点の監査スナップショットとして維持する。監査後にRelease Gate 0、ID-01、SAVE-01〜02、UI-QUEST-01、UI-READY-01、UI-M0-01、UI-C0-01を完了した。最小export spike、SAVE-03〜04、E7、E11、release_verifyは未完。現行進捗はdocs/30 §6と対象QAを参照する。

2026-07-11の並列実装再編後は、wave・単一owner・RC Gateをdocs/30 §6、E7分割を`docs/v2/E7_difficulty.md`、E11 settings spineを`docs/v2/E11_launch_readiness.md`の正とする。本書§7〜9のbriefに残る「ゲームパッド採用時だけのinput base」「固定25本」「REL-01とQA-RELEASEの同一tool二重所有」は監査時点案であり、現行実装へそのまま使わない。

本書が扱うもの:

- コア進行、セーブ、依頼、釣行、サメ飼育のコード監査
- 全画面の実スクリーンショットによるUI監査
- smoke / audit / visual QA / 素材監査の実行結果
- export、user data / OS / storeの各識別子、入力、表示、権利、販売外周の発売準備監査
- 発見事項の優先順位、依存関係、brief、完了条件

本書が意味しないもの:

- 全ファイルの全行を同じ深さで精査したという宣言ではない
- 本書だけで仕様やfreeze値を上書きできるものではない
- exported build、実ゲームパッド、全解像度、全難易度の人手プレイを合格済みとするものではない

調査開始時点のworktreeはcleanだった。レポート保存前に reference/12_shark_pen_mockup.png の変更が別途現れたが、本監査・本レポートではユーザー所有の変更として触れていない。本書のコミットへ含めないこと。

---

## 1. 正本との関係と読み順

仕様・判断が衝突した場合は次の順で扱う。

1. AGENTS.md — プロジェクト共通の作業規約
2. docs/19_ui_production_playbook.md — UI品質、P1/P2/P3、freeze再オープン規約
3. docs/30_v2_expansion_overview.md — V2フェーズ順、横断決定、進行状況の正本
4. 当該 docs/v2/E*.md または docs/33_cooking_market_ui_uplift_plan.md — 実装仕様
5. docs/qa/<screen>_qa.md — 画面別freeze値、採否、再オープン履歴の正本
6. 本書 — 2026-07-10時点の監査証拠、優先順位、引継ぎbrief

本書と上位正本が衝突した場合、実装者は黙って都合のよい方を選ばない。まず docs/30 または当該正本を更新し、判断履歴を残してから実装する。

---

## 2. 結論

### 2.1 一文判定

ゲーム中核に全面的な作り直しが必要な兆候はない。一方で、現在の状態は「主要機能が動くV2」であり、「安全に販売できる製品」にはまだなっていない。

### 2.2 良好だった領域

- レベル1〜50の曲線と既存Lv10互換
- 時間帯別エンカウント
- 釣行イベントと海図断片
- ヌシ、サメ餌魚、奇襲、メガロドンの主要ゲート
- サメ飼育の基本ループ
- 釣りシミュレータの主要状態遷移と値クランプ
- 3スロット分離、旧単一セーブのslot 1移行
- 一時ファイルからの差し替えと、構文破損時のbackup復旧
- 88魚素材のシート契約、重複監査、素材所有監査
- 港、魚図鑑、釣具店、水中ファイト基盤など、既にfreezeを維持すべき画面

### 2.3 発売前に閉じるべき本質的な穴

1. 販売先、対象OS、入力、非16:9、正式名称が未確定
2. export preset、clean export起動、対象OS / チャネルで必要な署名・公証・配布物検証が存在しない
3. 将来版セーブの破壊、保存失敗の黙殺、意味的破損データの採用余地がある
4. 権利証拠、画像生成元、商標、AI開示、製品アイコンが未完
5. E7難易度とE11設定・入力・表示・製品外装が未実装
6. 依頼本文、READY最長名、市場M0、調理C0に実スクショ上のP1が残る
7. 現行の validate_project.sh は発売判定用の包括ゲートではない

### 2.4 直近の着手順

次の担当は、E7だけを即開始するのではなく、まずRelease Gate 0を確定する。

1. ユーザー判断5件を確定し docs/30 / E11へ反映
2. docs/31の権利証拠と商標・AI開示を棚卸し
3. 正式名称変更より先に、user data namespace、OS application / bundle ID、必要ならstore App IDを分離して確定
4. 対象OSの最小export spikeを実施
5. セーブ保護4件を直列で修正
6. E7難易度とタイトルの消去安全性を実装
7. 依頼 / READY / M0 / C0を局所修正
8. E11とrelease_verifyを完成
9. 3難易度の序盤・中盤・終盤を人手受入
10. 対象OS / チャネルで必要な署名・公証を施した最終exportで発売判定

ユーザー判断を待つ間でも、セーブ保護と独立した局所UI P1は着手できる。

---

## 3. 監査方法と確定ベースライン

### 3.1 静的監査

- src配下のGDScript構成、画面、autoload、主要コンポーネントを横断確認
- project.godot、docs/19、docs/30、docs/31、docs/33、E7、E11、画面別QAを照合
- res:// の静的参照先を確認し、欠落0件
- export_presets.cfg の有無を確認し、欠落を確認
- セーブロード、終了時保存、依頼正規化、入力focus、長文表示を重点追跡

### 3.2 自動検証

実行結果:

| 検証 | 機能結果 | ログ品質 | 判定 |
|---|---|---|---|
| ./tools/validate_project.sh | exit 0 | ObjectDB snapshots作成失敗と終了時resource / object leakを出しても通過 | 機能green、発売ゲートとして不足 |
| ./tools/save_system_verify.sh | green | 意図的な壊れたJSONで期待どおりparse errorを出す | green |
| 25本のsmoke / audit | 全assertion成功 | 3本で終了時残存を検出 | 機能green、プロセスcleanではない |
| 素材所有監査 | green | 違反0 | green |
| 魚画像重複監査 | 88魚、意図的派生1、unexpected 0 | 問題なし | green |
| 魚シート契約 | 88シート合格 | 問題なし | green |

終了時残存を確認したscene:

- tools/catch_fanfare_smoke.tscn
- tools/fishing_harbor_return_smoke.tscn
- tools/fishing_spot_select_smoke.tscn

加えて ./tools/fight_visual_qa.sh でも ObjectDB / resources in use 系の終了ログを確認した。

重要: 「assertionがgreen」と「未説明のERRORがない」は別の合格条件である。現状の validate_project.sh は tools/validate_project.sh:19-23 の素材監査とGodot起動確認だけで、25本のsceneを列挙実行せず、Godotがexit 0ならERROR文字列を失敗にしない。

### 3.3 visual QA

今回再生成・目視した主な画面:

- タイトル現行3スロット画面
- 依頼ボード
- 魚市場
- 調理5状態
- ステータス
- サメ生簀
- 魚図鑑
- 釣り場マップ
- 釣具店
- 港
- 水中ファイト / READY

既存証拠も含めて確認したもの:

- 水上天候状態
- 朝まずめ / 日中 / 夜釣り
- 釣果ファンファーレ

今回のレビュー中に surface_weather_visual_qa.sh と fishing_time_slot_visual_qa.sh は再実行していない。既存QA証拠を確認した。見た目の修正完了判断では、各brief側で必ず同一状態のbefore / afterを再取得すること。

### 3.4 未検証

- cleanな別環境でのimportと起動
- debug / releaseのexport成果物
- Windows、macOSなど対象OS別の実機
- Steam / itch.ioの実配布パッケージ
- コード署名、公証、ストア審査
- 実ゲームパッドの全導線
- 16:10、4:3、超横長など非16:9の全画面
- 3難易度の序盤・中盤・終盤の人手バランス
- 長時間プレイ、メモリ、フレーム時間、低性能端末

---

## 4. 優先度の定義

| 区分 | 意味 | 扱い |
|---|---|---|
| GATE | 発売仕様または合否そのものを決められない | 実装順の前提。ユーザー判断または外部確認が必要 |
| P1 | データ損失、主要情報欠落、主要導線破綻、発売品質の明白な破綻 | 発売前に必ずclose |
| P2 | 条件付き発売阻害、回復性不足、入力・表示・QA不足 | 採用プラットフォームに応じ発売前にcloseまたは明示除外 |
| P3 | 低再現・将来保守・防御的改善 | リリースを止めないがbacklog化 |
| POST | 重いアート向上や追加コンテンツ | ローンチ後 |

---

## 5. 発見事項台帳

### REL-01 — export経路が存在しない

- 優先度: GATE
- 状態: open
- 証拠: export_presets.cfg が存在しない
- 影響: 対象OSのビルド成否、resource filtering、実行権限、必要な署名 / 公証、成果物内の不要ファイル混入、clean環境起動を判定できない
- 方針: 最終工程まで待たず、user data namespaceとOS application / bundle ID確定直後に最小export spikeを行う
- DoD:
  - 対象OSがdocs/30 / E11に確定
  - debugとrelease exportが再現可能
  - cleanなユーザーディレクトリで起動しタイトルまで到達
  - 新規save作成、再起動、読込が成功
  - 最終段階で対象OS / チャネルが要求する署名・公証・ストア成果物を別gateにする

### REL-02 — 発売仕様のユーザー判断が未確定

- 優先度: GATE
- 状態: open
- 正本: docs/30 §3-4、docs/v2/E11_launch_readiness.md
- 未決:
  1. 販売チャネル: Steam / itch.io / 両方
  2. 対象OS。docs/00の初期候補はmacOS Apple Silicon / Intel
  3. ゲームパッド対応の有無
  4. 非16:9: expand＋追加QA / keep＋黒帯
  5. 正式な製品名と表記。docs/00の現候補は「釣りクエスト ～海釣り編～」
- 影響: export preset、署名、設定画面、focus実装、解像度QA、ストア外装のスコープが決まらない
- DoD: 曖昧語なしでdocs/30とE11へ決定日つきで記録

### REL-03 — 権利証拠と製品外装が未完

- 優先度: GATE
- 状態: open
- 証拠:
  - docs/31:63 Suno Pro証拠がユーザー保存待ち
  - docs/31:67-82 外部生成画像節に要記入と推定行が残る
  - docs/31:94 商標調査未実施
  - assets/icon.svgは魚と釣り針のcustom SVGだが、作者・作成手段・ライセンス・製品採用判断がdocs/31で未確定
- 影響: 発売直前に素材差し替えが必要になると、全画面QAとパッケージをやり直す
- 方針: E11末尾ではなく今すぐ棚卸し。Steam採用ならAI生成コンテンツ開示も同時確認
- DoD:
  - docs/31の⚠、要記入、ユーザー保存待ちが0
  - 音源の生成時プラン証拠と規約証拠を保存
  - 各画面PNGの生成元を推定ではなく確定
  - タイトル商標を対象地域で確認
  - 製品アイコンとクレジット・AI開示方針を確定

### REL-04 — 正式名称変更と3種類の製品識別子が未分離

- 優先度: P1
- 状態: open
- 証拠: project.godot:13 のconfig/nameが「釣りクエスト ～海釣り編～ MVP」。安定したcustom user directory指定が見当たらない
- 影響: config/name依存のuser://を使っている場合、MVP表記除去後に既存テストsaveや先行配布saveが見えなくなる可能性がある
- 方針: 次の3つを「製品ID」の一語で混同しない
  1. Godotのuser data namespace（custom user directory name相当）— save所在を安定させる
  2. OS application / bundle ID — export、署名、更新識別に使う
  3. store App ID — 採用チャネルで発行された後に記録する
- DoD:
  - 安定したuser data namespaceを設定
  - 対象OSのapplication / bundle IDを設定
  - store App IDが未発行なら「未発行」、発行後は値と管理先を記録
  - 旧名称配下のsaveを検出・移行するか、移行不要の根拠を記録
  - 旧save→正式版のexported build回帰がgreen

### REL-05 — 製品ライセンスとthird-party noticeの配布契約が未確定

- 優先度: GATE
- 状態: open
- 証拠:
  - LICENSE.mdのCopyright holder名が空
  - root MITがコード、プロジェクト所有素材、AI生成物のどこまでを対象にするか明記されていない
  - LINE Seed JP / M PLUS 1pのOFL本文はrepo内にあるが、export成果物または配布物への同梱確認がない
  - Godot runtimeを含む対象OS成果物のlicense / third-party noticeをどう同梱するか未検証
- 影響: コードの権利者表示と第三者ライセンスの配布条件を満たしたか発売判定できない
- 方針: 対象OS / チャネル確定後に、LICENSE.mdの権利者と適用範囲、THIRD_PARTY_NOTICES、成果物への同梱方法を確定する。具体的条件は採用版・配布形式の公式条件を確認する
- DoD:
  - LICENSE.mdに権利者名と適用範囲
  - THIRD_PARTY_NOTICES.md相当でGodot・font・その他同梱依存を列挙
  - OFL本文など必要文書が最終配布物に存在
  - clean exportを展開し、notice同梱を自動または手動チェック

### SAVE-01 — 将来版セーブを旧形式で破壊できる

- 優先度: P1
- 状態: open
- 証拠:
  - src/autoload/player_progress.gd:922-929 はversion > SAVE_VERSIONを警告だけで読込
  - 同:801-827 は既知フィールドとSAVE_VERSION=1だけで保存
  - tools/save_system_smoke.gd:112-119 は将来版を読めることしか確認しない
- 再現: version 99と未知フィールドを持つsaveを読む → 任意の自動保存または終了 → version 1と既知フィールドだけに置換
- 影響: ロールバック起動、古い配布物、誤った実行ファイルで不可逆なデータ損失
- 方針: 将来版saveは非対応として通常プレイと保存を止め、元ファイルを変更しない
- DoD:
  - future versionを持つ対象slotだけcontinue / save禁止。他2slotは通常利用可能
  - UIで「新しい版で作られたため開けない」と通知
  - 対象slotのmain / backup / tmpと未知フィールドを含む原本のhashが起動前後で同一
  - 別slotへ切り替えるとguard状態が正しく再評価され、global blockが残らない
  - regression testが旧挙動「読める」を期待しない

### SAVE-02 — 保存失敗が呼出側とユーザーへ伝わらない

- 優先度: P1
- 状態: open
- 証拠:
  - player_progress.gd:801 のsave_game()はvoid
  - 832-846のopen / backup rename / final rename失敗はpush_warning後return
  - src/main.gd:38-42 は結果を待たずquit
- 影響: 容量不足、権限、rename失敗で進行が保存されていなくても、画面遷移や終了が成功扱いになる
- 方針: E11のsave_failed signalと共通toastを前倒しし、結果契約を作る
- DoD:
  - 保存APIが成功 / 失敗を返す
  - 失敗理由をsignalと共通UIへ伝播
  - 終了時失敗は即quitせず、再試行 / 保存せず終了を選べる
  - 書込不可、tmp open失敗、rename失敗の注入テストがgreen

### SAVE-03 — save候補の意味検証契約がなく、部分破損を識別できない

- 優先度: P2。ただしデータ保護batchとして発売前推奨
- 状態: open
- 証拠:
  - player_progress.gd:849-865 はmainが空Dictionaryの時だけbackupを試す
  - 869-878 はJSONがDictionaryなら内容検証なしで返す
- 注意: {"version": 1}だけを即「壊れた」とは断定できない。現行は欠損補完を互換契約としており、疎な旧save fixtureも存在する。先にversion 1の必須 / 任意keyと許容fixtureを定義する必要がある
- 影響: JSON構文は正しい部分破損で進行が実質初期化
- 方針: docs/30へversion別の必須core key、任意key、型、意味範囲、正常な疎save fixtureを契約化してから候補採用
- DoD:
  - version 1候補契約と正常 / 破損fixtureをdocs/30へ記録
  - 構文正常・意味不正のmainでbackupへfallback
  - main / backup両方不正なら原本を維持し、ユーザーへ通知
  - 正常な旧版・欠損許容フィールドとの互換を壊さない

### SAVE-04 — 旧版の達成不能依頼が3枠を占有し続ける

- 優先度: P2
- 状態: open
- 証拠:
  - player_progress.gd:1010-1031 はfish_idの存在・サメ・ヌシ除外を検証しない
  - 473-485 は納品時に拒否するだけ
  - 454-463 はquest_board.size()が3なら補充しない
- 影響: 旧サメ依頼や削除魚依頼が永久に1枠を潰す
- 方針: load正規化で未知 / 除外 / 達成不能を除去し、安全な依頼で3件に補充
- DoD:
  - 旧サメ依頼、未知魚依頼をload時に除去
  - 正常依頼は内容と順番を維持
  - 3件へ補充
  - shark / quest / save回帰を更新

### SAVE-05 — QA sandboxが全I/Oを遮断していない

- 優先度: P3
- 状態: open
- 証拠: player_progress.gd:100-102の意図に対し、has_save_file、set_active_save_slot、save_slot_summaryは実user dataを読んだりディレクトリを作る
- 影響: visual QAやsmokeが実ユーザーsaveに依存し、個人データへ触れる可能性
- 方針: sandbox時は全save helperを遮断するか、注入可能なsave rootを使う
- DoD: sandbox test中の実user://差分0

### TITLE-01 — 製品外装がprototypeのまま

- 優先度: P1
- 状態: open
- 証拠:
  - src/ui/title_screen.gd:167 「MVP Prototype v0.1 / Godot 4.7」
  - project.godot:13 名称にMVP
  - 設定画面が存在しない
  - title専用の現行visual QAスクリプト / QA文書がない
  - tools/build_title_static_preview.py:164-182 は現行3スロット構成より古い
- 影響: 製品版として未完成に見える。静的previewを信じると現行runtimeと違う画面を評価する
- 方針: E7 / E11と一体でruntime title QAを新設し、正式名・version・settings導線を実装
- DoD: runtimeスクショ、3スロット全状態、正式版文言、設定導線、解像度別QA

### TITLE-02 — 初期化saveの成否を確認せず港へ遷移する

- 優先度: P1
- 状態: open
- 証拠: title_screen.gd:333-336 → player_progress.gd:190-194 はreset_game内のsave_game()がvoidでも、直ちにharborへ遷移
- 影響: 初期saveが失敗しても新規ゲーム開始に成功したように見え、再起動時に消える
- 方針: SAVE-02の結果契約を前提に、reset / 初回save成功後だけ港へ遷移
- DoD:
  - reset / 初回save成功後だけ遷移
  - 失敗時は元slotの扱いを曖昧にせず、通知してタイトルに留まる
  - 他slot不変、失敗注入test

### TITLE-03 — 上書き確認の強化案

- 優先度: P2提案。ユーザー承認前は必須仕様にしない
- 現状: docs/01 FR-001の「確認後に初期化」は、title_screen.gd:320-323の1回確認で満たしている
- 提案: E7モーダル設計時に、slot番号・Lv・プレイ時間・不可逆警告・安全なcancel focusを表示する。難易度選択後の最終確認にまとめるか二段階にするかは、実スクショ案を見てユーザー決定
- DoD: 採用する場合だけE7とtitle QAへ決定日・確認段数・focus契約を記録

### E7-01 — 新規セーブ専用の難易度が未実装

- 優先度: GATE
- 状態: open
- 正本: docs/v2/E7_difficulty.md、docs/30 決定#3 / #18
- 影響: ローンチ後に追加すると既存saveと新規saveで体験・データ契約が分裂
- 方針: 次のゲーム機能として予定どおりE7を実施。ただしdocs/30の順序どおりRelease Gate 0 / 1を先に完了する
- DoD: E7仕様のdifficulty audit、旧save→normal、タイトルruntime visual、3難易度の主要係数確認

### UI-QUEST-01 — 依頼の主条件が省略される

- 優先度: P1
- 状態: open
- 証拠:
  - evidence: docs/qa/evidence/quest_board/2026-07-06_quest_board.png に「45cm以上のメジナを...」「磯の活力丼にするカサ...」
  - quest_board_screen.gd:115-120 は狭い本文領域
  - ScreenBase.make_screen_labelはclip_text=true、OVERRUN_TRIM_ELLIPSIS
- 影響: プレイヤーが依頼達成条件を読めない。docs/19の通常データ無省略条件に反する
- freeze: 3列構成、外枠、他の合格値は動かさない
- 方針: 本文領域だけ再設計し、必要なら2〜3行と文字サイズ下限を定義
- DoD:
  - 全テンプレート×現行最長魚名の組合せで本文全文表示
  - visual QAに最長ケースを固定
  - quest logicと生成率は不変

### UI-READY-01 — 最長餌魚名を10pxまで縮めてもellipsis

- 優先度: P1
- 状態: open
- 証拠:
  - evidence: docs/qa/evidence/fishing_surface/2026-07-08_ready_lure_long_name_fixed.png に「港のぬし・大岩...」
  - fight_hud.gd:611-621 は名前幅を最大176px、14→10px
  - 870-884 は収まらなければ明示的に...へ短縮
  - docs/qa/fishing_surface_qa.md §1は「最小でも収まらない場合だけ末尾を詰める」を許可している一方、docs/19:81は通常データのellipsisゼロをv1条件とする
- 影響: 選択中の餌魚を識別しにくく、上位正本docs/19と画面QAの許容条件が衝突している
- freeze: READY下段バー全体は再オープンしない。名前スロット構成だけをP1再発として開く
- 方針: docs/19を優先し、画面QAの末尾詰め許容をP1再発として明示改訂する。数px調整は3回上限到達済みなので、カード内の名前・画像・在庫の構造を局所再設計
- DoD:
  - QA判断ログへ「旧許容を上書きする理由、動かす値、不動値、同一状態before」を記録
  - 港のぬし・大岩クロダイとx99 / x101を省略なし表示
  - 通常名、在庫0、残チャージ、餌なしの重心が安定
  - FIGHT系freezeと抽選・消費ロジック不変

### UI-M0-01 — 市場の空状態が壊れた一覧に見える

- 優先度: P1
- 状態: open
- 正本: docs/33 M0
- 実スクショ: docs/qa/evidence/fish_market/2026-07-07_uplift_plan_empty_compare.png で、空の氷トレー、左下の行UI残骸、未ロード風の灰色バーを確認
- 文書矛盾: docs/qa/fish_market_qa.mdはv1採用済みだが、docs/30とdocs/33はM0未着手
- 扱い: docs/19の「P1破綻の再発」として局所再オープン。通常のfreeze再調整ではない
- DoD: docs/33 M0の4状態visual、market smoke、同一状態before / after、動かした値と不動値をQAへ記録

### UI-C0-01 — 調理結果フローに残像・衝突・グリフ潰れ

- 優先度: P1
- 状態: open
- 正本: docs/33 C0
- 実スクショ:
  - evidence: docs/qa/evidence/cooking/2026-07-07_uplift_plan_gap_sheet.png
  - MEAL_RESULTの背面に前状態のwash / panelが残る
  - STATUS_SUMMARYのタイトル帯と装飾が衝突
  - EXP_GAIN / LEVEL_UPの下部導線グリフが潰れる
- 追加: cooking_status_panel.gd:747 は %d G で、docs/19の金額3桁区切りに反する
- 文書矛盾: docs/qa/cooking_qa.mdはP1なしとする一方、docs/30とdocs/33はC0未着手
- 扱い: docs/19のP1再発としてC0だけ再オープン。C1〜C5の重い素材工事へ拡張しない
- DoD: 5状態visual、cooking_verify表示契約更新、金額format統一、ロジック不変、QA判断ログ更新

### INPUT-01 — 造船所がマウス以外で操作不能

- 優先度: P2。ゲームパッド対応を選ぶ場合はGATE
- 状態: open
- 証拠: shipyard_screen.gd:457-464 の透明Buttonは全てFOCUS_NONE
- 影響: キーボード / ゲームパッドでは船選択、購入、戻るへfocusできない
- テスト穴: shipyard smokeはmethodやsignalを直接呼び、実focus移動を保証しない
- DoD: 対応入力をdocs/30で決定後、実入力で初期focus、隣接遷移、決定、戻る、disabledを検証

### INPUT-02 — 全画面のfocus契約がない

- 優先度: P2
- 状態: open
- 証拠:
  - ScreenBase.make_return_buttonのfocus styleがnormalと同じで見分けにくい
  - 明示的な初期focus / neighborsは主に港だけ
- 影響: キーボード / ゲームパッドを対応表記しても操作可能性を証明できない
- 方針: E11で共通focus visualと画面別入力matrixを作る

### DISPLAY-01 — 非16:9方針とQAが未確定

- 優先度: P2。対応範囲を広げる場合はGATE
- 状態: open
- 証拠: project.godot:26-31 は1280x720、canvas_items、aspect=expand。市場・釣具店以外に全画面固定canvasの一貫した防御がない
- 推奨: 本作の固定1280x720前提ならkeep＋黒帯が最短で安全。expandを選ぶなら16:10 / 4:3 / 超横長の全画面QAを発売条件にする
- DoD: 方針をdocs/30へ記録し、対応解像度matrixのruntime screenshotを保存

### QA-01 — 発売判定を一括実行できない

- 優先度: P1
- 状態: open
- 証拠: validate_project.shは25本のsmoke / audit、export、save移行、解像度、入力を網羅しない
- 方針: tools/release_verify.sh相当を新設し、CIまたはclean runnerでも再現可能にする
- DoD:
  - 25 sceneを明示列挙またはmanifestから全実行
  - assertion failureと未許可ERRORの双方で非0
  - save migration / future version / write failureを含む
  - export buildの起動smokeを含む
  - 実行したGodot版と成果物hashを記録

### QA-02 — 終了時resource / ObjectDB残存

- 優先度: P2
- 状態: open
- 証拠: 3 smokeとfight visual QAで終了時残存。機能assertionは成功
- 影響: 現在はテスト終了時だけの可能性があるが、cleanup漏れ、signal、Tween、SubViewport、resource寿命の異常を隠す
- 方針: sceneごとに再現し、環境由来とコード由来を分離。allowするなら理由と正規表現をrelease verifierへ明示
- DoD: 未説明ERROR 0。やむを得ない既知ログはscene / Godot版 / 根拠つきallowlist

### QA-03 — 画面別の実状態matrix不足

- 優先度: P2
- 状態: open
- 対象:
  - サメ生簀: 大量餌、横スクロール終端、餌なし、locked、最大bond
  - 水中ファイト: WAIT / READY / BITE / FIGHT / CATCH ×代表時間帯・天候
  - 造船所: normal / owned / insufficient / max rank / 解像度
  - タイトル: empty / occupied / corrupt / backup / future version / 3slot
- DoD: 対応範囲を絞ったrisk-based matrixをQAへ保存

### PERF-01 — 60fps目標と長時間安定性の発売証拠がない

- 優先度: P2。対象ハードウェア確定後は発売前必須
- 状態: open
- 証拠: docs/01 NFR-001は1280x720・60fps目標を定めるが、今回の監査はフレーム時間、メモリ推移、長時間プレイを未実施
- 影響: 機能smokeがgreenでも、実プレイ中のstutter、resource増加、長時間後のcrashを判定できない
- 方針: 対象OS / 最低対象ハードウェアを決め、代表的に重い釣行・港・調理・サメ生簀を含む計測シナリオを固定
- DoD:
  - 対象ハードウェアと計測条件を記録
  - 1280x720で60fps目標の達否と例外場面を記録
  - 30分soakでcrash・進行不能・無制限なresource / memory増加なし
  - 不合格時は再現sceneとprofiler証拠を保存

### DOC-01 — ルートの製品文書が初期MVP時点のまま

- 優先度: P2。ストア提出・外部共有前は必須
- 状態: open
- 証拠:
  - README.mdはMVPプロトタイプ、通常魚5種＋ぬし1種、Lv1〜10と記載し、複数釣り場・天候・時間帯・依頼を未実装扱い
  - VALIDATION.mdは「Godot本体を起動できなかった」とし、現在の素材監査や25本のsceneを反映していない
  - CHANGELOG.mdは2026-06-23のv0.1.0だけ
  - MANIFEST.txtは現行の画面、素材、tool、docsの大半を含まない
- 影響: 次の開発者、テスター、配布先が、機能・検証範囲・同梱物を誤認する
- 暫定措置: README / VALIDATION / CHANGELOGの冒頭に、現行正本がdocs/30 / docs/45である警告を追加
- 方針: E7 / E11で最終機能と対象OSが固まった後、4文書を製品版へ全面更新。MANIFESTは自動生成するか廃止を明記
- DoD: 現行機能、操作、対応OS、検証コマンド、既知制約、release history、配布物が実成果物と一致

---

## 6. 画面別成熟度と扱い

数値は2026-07-10時点の監査目安であり、正式な進捗率ではない。freezeの正は各docs/qaにある。

| 画面 | 成熟目安 | 発売前の扱い |
|---|---:|---|
| 港 | 90〜95% | freeze維持。新P1がなければ触らない |
| 魚図鑑 | 約90% | freeze維持 |
| 釣具店 | 85〜90% | freeze維持 |
| 水中ファイト | 約85% | 基盤freeze維持。READY最長名だけ局所再オープン |
| 調理 | 80〜85% | C0だけ発売前。C1〜C5はPOST |
| 釣り場マップ | 80〜85% | 表示方針決定後の解像度QA |
| 魚市場 | 75〜80% | M0だけ発売前。M1〜M3はPOST |
| 造船所 | 70〜75% | 入力 / focus / 状態matrix |
| サメ生簀 | 70〜75% | 大量在庫と実入力QA。重い演出はPOST |
| ステータス | 70〜75% | 機能は成熟。見た目の大改修はPOST |
| 依頼ボード | 65〜70% | 本文省略P1だけ発売前 |
| タイトル | 55〜60% | E7、正式外装、設定、消去安全性、runtime QA |
| 設定 | 0% | E11で新設 |

freeze運用:

- 港、魚図鑑、釣具店、FIGHTは、16:9・マウス基準の合格値を維持
- 依頼本文、READY最長名、M0、C0はP1再発として対象範囲だけ開く
- 非16:9やゲームパッドを採用する場合は、新しい合格軸なので必要範囲を開く
- before / after、動かす値、不動値、新採用値を画面QAへ残す

---

## 7. 推奨ロードマップと依存

~~~mermaid
flowchart TD
  D["Gate 0: 販売先・OS・入力・表示・正式名"] --> ID["user data / OS / store の識別子"]
  D --> E11["E11 設定・入力・表示・製品外装"]
  ID --> EX["最小export spike"]
  R["権利証拠・商標・AI開示"] --> PKG["チャネル別パッケージ"]
  S1["SAVE-01 将来版guard"] --> S2["SAVE-02 失敗伝播"]
  S2 --> S3["SAVE-03 意味検証"]
  S3 --> S4["SAVE-04 旧依頼修復"]
  S4 --> E7C["E7 係数・データ・監査"]
  E7C --> E7T["E7 タイトル開始導線"]
  E7T --> E11
  U["依頼 / READY / M0 / C0"] --> RV["release_verify"]
  EX --> RV
  S4 --> RV
  E11 --> RV
  PKG --> RV
  RV --> PLAY["3難易度 序盤・中盤・終盤受入"]
  PLAY --> FINAL["必要な場合は署名・公証済み最終export / 発売判定"]
~~~

並列化:

- ユーザー判断と権利棚卸しは並列可
- export spikeはuser data namespace・OS application ID・対象OSの後
- SAVE-01〜04はplayer_progress.gdが重なるため直列
- 依頼本文とREADYは別ファイルなので並列可
- 市場M0と調理C0は並列可
- docs/30の正本どおり、Release Gate 1（SAVE-01〜04）完了後にE7へ進む。特にタイトル開始導線はSAVE-02の保存結果契約へ直接依存する

親エージェントが持つ判断:

- docs/30の決定更新
- 3種類の識別子と旧save移行境界
- freeze再オープン可否
- release verifierのERROR allowlist
- 最終launch gate

---

## 8. Brief-ready実装キュー

### DEC-01 — 未決判断を正本へ反映

- concern: 発売対象の確定
- 触ってよい: docs/30_v2_expansion_overview.md、docs/v2/E11_launch_readiness.md
- 触らない: 実装、freeze、ゲームバランス
- input: ユーザー回答5件＋性能計測に使う最低対象ハードウェア / 基準機の技術判断
- DoD: docs/00のmacOS / 現タイトル候補を確認または拡張し、販売先、OS、入力、表示、正式名を決定日つきで記録。user data namespace、OS application / bundle ID、store App ID、最低対象ハードウェア / 基準機は技術判断として別欄に固定

### REL-01 — 製品識別子と最小export spike

- concern: 正式名変更前にsave所在を安定させ、配布可能性を早期確認
- 触ってよい: project.godot、export_presets.cfg（新設）、tools/export_launch_smoke.gd（新設）、tools/export_launch_smoke.tscn（新設）、tools/release_verify.sh（新設）、tools/save_system_smoke.gd、tools/save_system_verify.sh
- 触らない: UI品質、ゲームバランス、画面freeze
- DoD: 3識別子を分離記録し、対象OSのdebug / release export、clean user dir起動、save作成・再読込、旧名称saveの扱いを記録

### RIGHTS-01 — 権利証拠をclose

- concern: 製品同梱素材の出所と販売条件を証拠化
- 触ってよい: docs/31_asset_ledger.md、LICENSE.md、THIRD_PARTY_NOTICES.md（新設）、docs/qa/evidence/licensing/、export_presets.cfgの配布文書設定
- 触らない: 素材差し替え。問題が見つかった場合は別brief
- DoD: 要記入 / 推定 / 保存待ち0、商標・AI開示・icon方針、権利者名、third-party notice、最終成果物へのlicense同梱を記録

### SAVE-01 — future version guard

- concern: 将来版saveの破壊防止
- 触ってよい: src/autoload/player_progress.gd、src/ui/title_screen.gd、src/ui/screen_base.gd、tools/save_system_smoke.gd、tools/save_system_verify.sh
- 触らない: 難易度schema、依頼修復、UI装飾
- DoD: future版の対象slotだけ保存 / continue禁止、main / backup / tmp原本不変、他2slot利用可、slot切替でguard再評価、明示エラー、回帰green

### SAVE-02 — 保存失敗伝播

- concern: 保存成否を呼出側とユーザーへ届ける
- 触ってよい: src/autoload/player_progress.gd、src/main.gd、src/ui/screen_base.gd、tools/save_system_smoke.gd、tools/save_system_verify.sh
- 触らない: 各画面固有デザイン、ゲーム数値
- DoD: result contract、save_failed、共通toast、終了時選択、失敗注入test

### SAVE-03 — load候補の意味検証

- concern: main / backupから安全な候補だけ採用
- 触ってよい: docs/30_v2_expansion_overview.md、src/autoload/player_progress.gd、tools/save_system_smoke.gd、tools/save_system_verify.sh
- 触らない: schema追加、UI、依頼ロジック
- DoD: version 1の必須 / 任意key・型・正常な疎save fixtureを先に契約化し、意味破損main→正常backup、両方不正時原本維持、正常旧save回帰

### SAVE-04 — 旧依頼repair

- concern: 達成不能な旧依頼を安全に除去・補充
- 触ってよい: src/autoload/player_progress.gd、tools/quest_board_smoke.gd、tools/shark_pen_smoke.gd、tools/shark_pen_smoke.tscn、tools/save_system_smoke.gd、tools/save_system_verify.sh
- 触らない: 現行抽選率、報酬、画面配置
- DoD: 未知 / サメ / ヌシの不正依頼除去、正常依頼不変、3件補充、quest_board_smoke / shark_pen_smoke / save_system_verify green

### E7 — 難易度とタイトル新規ゲーム導線

- concern: docs/v2/E7_difficulty.mdの実装
- 触ってよい: src/autoload/game_catalog_data.gd、src/autoload/player_progress.gd、src/ui/title_screen.gd、src/ui/fishing_screen.gd、src/ui/status_screen.gd、tools/difficulty_fight_audit.gd / .tscn（新設）、tools/title_preview.gd / .tscn（新設）、tools/title_visual_qa.sh（新設）、docs/qa/title_qa.md（新設）、docs/qa/evidence/title/
- 触らない: E7外のバランス、既存画面freeze、save I/O実装。タイトル開始導線の接続はSAVE-02完了後
- DoD: E7 audit、旧save→normal、3slot runtime visual、初期save成功後だけ遷移、現行1回確認の維持。確認強化はTITLE-03がユーザー承認された場合だけ追加、validate

### UI-QUEST — 本文無省略

- concern: 依頼の主条件を必ず読めるようにする
- 触ってよい: src/ui/quest_board_screen.gd、tools/quest_board_preview.gd、tools/quest_board_preview.tscn、tools/quest_board_visual_qa.sh、tools/quest_board_smoke.gd、docs/qa/quest_board_qa.md、docs/qa/evidence/quest_board/
- 触らない: 依頼ロジック、3列、他freeze、素材
- DoD: 最長組合せ全文、visual + smoke + validate、QA再オープン記録

### UI-READY — 最長餌魚名

- concern: 名前スロット構造だけを再設計
- 触ってよい: src/ui/components/fight_hud.gd、tools/fishing_surface_states_preview.gd、tools/fishing_surface_states_preview.tscn、tools/fight_visual_qa.sh、tools/fishing_harbor_return_smoke.gd、tools/fishing_spot_select_smoke.gd、docs/qa/fishing_surface_qa.md、docs/qa/evidence/fishing_surface/
- 触らない: simulator、餌消費、抽選、FIGHT、魚素材、下段バー全体
- DoD: 最長名＋3桁在庫無省略、4状態visual、関連smoke / audit、validate

### M0 — 市場空状態

- concern: docs/33 M0のみ
- 触ってよい: src/ui/market_screen.gd、tools/market_preview.gd、tools/market_preview.tscn、tools/market_visual_qa.sh、tools/market_smoke.gd、docs/qa/fish_market_qa.md、docs/qa/evidence/fish_market/
- 触らない: 売却仕様、素材、M1〜M3、合格freeze
- DoD: 4状態visual、market smoke、validate、P1再発ログ

### C0 — 調理runtime破綻

- concern: docs/33 C0のみ
- 触ってよい: src/ui/components/cooking_reward_panel.gd、src/ui/components/cooking_reward_cards.gd、src/ui/components/cooking_reward_visuals.gd、src/ui/components/cooking_status_panel.gd、src/ui/components/level_up_panel.gd、tools/cooking_preview.gd、tools/cooking_preview.tscn、tools/cooking_verify.sh、tools/cooking_visual_qa.sh、docs/qa/cooking_qa.md、docs/qa/evidence/cooking/
- 触らない: 調理 / EXPロジック、素材、C1〜C5、合格freeze
- DoD: 5状態visual、表示契約、金額format、cooking test、validate、P1再発ログ

### E11-SETTINGS-AUDIO — 設定shell・音量

- concern: settings.jsonとBGM / SE音量の一巡
- 前提: DEC-01
- 触ってよい: src/ui/settings_screen.gd（新設）、src/ui/title_screen.gd、src/ui/harbor_screen.gd、src/main.gd、src/ui/screen_base.gd、src/ui/components/catch_fanfare.gd、project.godot、tools/settings_smoke.gd（新設）、tools/settings_smoke.tscn（新設）
- 触らない: save slot削除、fullscreen、input map、製品外装
- DoD: title / harbor導線、画面BGM・共通SE・釣果音のbus分離、BGM / SE個別音量、変更→settings.json保存→再起動相当→復元、破損settings fallback、settings smoke、validate

### E11-SLOT-DELETE — 対象1slotの削除

- concern: settingsから現在対象の1slotだけを安全に消す
- 前提: E11-SETTINGS-AUDIO、SAVE-02
- 触ってよい: src/ui/settings_screen.gd、src/ui/title_screen.gd、src/autoload/player_progress.gd、src/main.gd、tools/settings_smoke.gd、tools/save_system_smoke.gd、tools/save_system_verify.sh
- 触らない: 他2slot、settings.json、難易度、画面装飾
- DoD: titleのselected slot / harborのactive slotを明示、main / backup / tmp削除、runtime初期化、他slot / settings不変、終了時auto-saveで再生成しない、二重確認

### E11-DISPLAY — fullscreenと非16:9

- concern: DEC-01で選んだ表示方針を全画面へ適用
- 触ってよい: src/ui/settings_screen.gd、project.godot、tools/settings_smoke.gd、tools/settings_smoke.tscn、tools/cooking_visual_qa.sh、tools/fight_visual_qa.sh、tools/fish_book_visual_qa.sh、tools/fishing_spot_map_visual_qa.sh、tools/fishing_time_slot_visual_qa.sh、tools/harbor_visual_qa.sh、tools/market_visual_qa.sh、tools/quest_board_visual_qa.sh、tools/shark_pen_visual_qa.sh、tools/status_visual_qa.sh、tools/surface_weather_visual_qa.sh、tools/tackle_shop_visual_qa.sh、tools/title_visual_qa.sh（E7で新設）、tools/shipyard_preview.gd、tools/shipyard_preview.tscn、tools/shipyard_visual_qa.sh（新設）、tools/settings_preview.gd（新設）、tools/settings_preview.tscn（新設）、tools/settings_visual_qa.sh（新設）
- 触らない: 各画面の個別freeze。崩れが出た画面は別briefを起票
- DoD: fullscreen保存 / 復元、1280x720、16:10、4:3または黒帯のruntime screenshot matrix、settings smoke、validate

### E11-EXTERIOR — 正式版の外装

- concern: REL-01で確定した識別子と移行結果を使い、表示名・version・iconを正式版にする
- 前提: DEC-01、REL-01、E7
- 触ってよい: project.godot、src/ui/title_screen.gd、tools/title_preview.gd、tools/title_preview.tscn、tools/title_visual_qa.sh、docs/qa/title_qa.md、docs/qa/evidence/title/、docs/31_asset_ledger.md
- 触らない: settings、input、ゲームロジック
- DoD: REL-01のuser data namespace / OS application ID / store App ID / 旧save移行を再検証して利用し、正式名 / version / icon、runtime title visual、台帳更新、validate

### E11-INPUT-BASE — 共通input / focus契約

- concern: ゲームパッド対応を採用した場合の共通action map、可視focus、画面別監査harness
- 前提: DEC-01でゲームパッド対応を採用した場合のみ
- 触ってよい: project.godot、src/ui/screen_base.gd、tools/input_focus_audit.gd（新設）、tools/input_focus_audit.tscn（新設）、VALIDATION.md
- 触らない: 各画面固有のfocus graph。監査failureは画面ごとの別briefへ送る
- DoD: action map、normalと区別できる共通focus style、現行12画面＋新設settings（計13画面）のinitial focus / 到達不能 / 戻る / disabledを列挙する監査、failure一覧

E11-INPUT-BASEのfailureは1画面1briefへ分割する。INPUT-SHIPYARDは既知の最初の画面別briefであり、他画面を同じbriefへ混ぜない。

### INPUT-SHIPYARD — 造船所focus

- concern: 採用入力で造船所の全操作を到達可能にする
- 前提: DEC-01でキーボード / ゲームパッド範囲を確定
- 触ってよい: src/ui/shipyard_screen.gd、tools/shipyard_smoke.gd、tools/shipyard_smoke.tscn、docs/qa/shipyard_qa.md、docs/qa/evidence/shipyard/
- 触らない: 船価格 / 性能、素材、他画面
- DoD: initial focus、全船 / 購入 / 戻るへの隣接遷移、disabled、可視focus、実入力、smoke、runtime screenshot、validate

E11全体を1ワーカーへ渡さない。上記以外の画面で入力監査が失敗した場合は、画面ごとに「1 concern・実ファイル」を持つ追加briefを作る。

### QA-RELEASE — 一括発売検証

- concern: 1コマンドで発売候補の機械判定
- 触ってよい: tools/release_verify.sh（新設）、tools/release_test_manifest.txt（新設）、tools/export_launch_smoke.gd（新設）、tools/export_launch_smoke.tscn（新設）、VALIDATION.md、.github/workflows/release-verify.yml（新設）
- 触らない: ゲーム仕様
- DoD: 全25scene、ERROR分類、save破損 / 移行、export起動、成果物情報を1回で記録

### PERF-RELEASE — 性能・soak受入

- concern: NFR-001と長時間安定性の発売証拠
- 前提: DEC-01で対象OS / 最低対象ハードウェアを確定
- 触ってよい: tools/performance_verify.sh（新設）、tools/performance_smoke.gd（新設）、tools/performance_smoke.tscn（新設）、VALIDATION.md、docs/45_release_readiness_code_review.mdの結果欄
- 触らない: 性能修正。閾値未達は再現証拠を作り、原因別の別briefへ送る
- DoD: 1280x720・60fps目標の計測結果、重い代表状態、30分soak、resource / memory推移、対象ハードウェアを保存

### DOCS-RELEASE — ルート製品文書の更新

- concern: 初期MVP記述を発売候補の実態へ合わせる
- 触ってよい: README.md、VALIDATION.md、CHANGELOG.md、MANIFEST.txt
- 触らない: ゲーム仕様、実装、docs/qa
- 前提: DEC-01、E7、E11、対象OS / 入力 / 表示の確定
- DoD: DOC-01の4文書がrelease candidateと一致し、古い魚数・Lv10・未実装一覧・検証不能記述が0

---

## 9. 自動検証scene manifest

release verifierへ最低限含める25本:

1. catch_fanfare_smoke
2. cooking_content_audit
3. cooking_flow_smoke
4. cooking_input_audit
5. cooking_layout_audit
6. fight_envelope_audit
7. fish_book_smoke
8. fishing_harbor_return_smoke
9. fishing_reveal_smoke
10. fishing_spot_select_smoke
11. harbor_screen_smoke
12. level_curve_audit
13. market_smoke
14. nushi_encounter_audit
15. quest_board_smoke
16. save_system_smoke
17. shark_ambush_audit
18. shark_lure_audit
19. shark_pen_screen_smoke
20. shark_pen_smoke
21. shipyard_smoke
22. status_smoke
23. tackle_shop_smoke
24. time_slot_encounter_audit
25. trip_event_audit

visual QA 12本:

- cooking_visual_qa.sh
- fight_visual_qa.sh
- fish_book_visual_qa.sh
- fishing_spot_map_visual_qa.sh
- fishing_time_slot_visual_qa.sh
- harbor_visual_qa.sh
- market_visual_qa.sh
- quest_board_visual_qa.sh
- shark_pen_visual_qa.sh
- status_visual_qa.sh
- surface_weather_visual_qa.sh
- tackle_shop_visual_qa.sh

visual QAは全てを毎commitで実行する必要はない。変更画面と共有部品の影響画面を選ぶ。ただしlaunch candidateでは全画面の対応状態を取得する。

---

## 10. Launch Gate

以下がすべて満たされるまで「発売可能」と判定しない。

### 10.1 意思決定

- [ ] 販売チャネル確定
- [ ] 対象OS確定
- [ ] ゲームパッド対応有無確定
- [ ] 非16:9方針確定
- [ ] 正式名称確定

### 10.2 権利・製品

- [ ] docs/31の要記入 / 推定 / 保存待ち0
- [ ] 商標確認
- [ ] AI生成コンテンツ開示方針
- [ ] LICENSE.mdの権利者 / 適用範囲とTHIRD_PARTY_NOTICES
- [ ] 必要な第三者licenseが最終配布物に同梱
- [ ] 製品icon / version / credit
- [ ] user data namespace / OS application ID / store App IDを分離記録
- [ ] 採用チャネルの年齢レーティング / コンテンツ質問票
- [ ] README / VALIDATION / CHANGELOG / MANIFESTが最終成果物と一致

### 10.3 データ保護

- [ ] future versionを破壊しない
- [ ] 保存失敗を通知・選択できる
- [ ] 意味破損mainからbackup復旧
- [ ] 旧単一save→slot 1
- [ ] 不正旧依頼をrepair
- [ ] 新規 / 3slot / backup / write failureの回帰

### 10.4 機能・UI

- [ ] E7
- [ ] E11
- [ ] 依頼本文
- [ ] READY最長名
- [ ] 市場M0
- [ ] 調理C0
- [ ] 対応入力の実操作
- [ ] 対応解像度の実スクショ

### 10.5 検証・配布

- [ ] 全smoke / audit assertion green
- [ ] 未説明ERROR 0
- [ ] clean export成果物の起動
- [ ] 3難易度の序盤・中盤・終盤受入
- [ ] 対象ハードウェアで1280x720・60fps目標を計測
- [ ] 30分soakでcrash・進行不能・無制限なresource増加なし
- [ ] 対象OS / チャネルで必要な署名 / 公証
- [ ] ストアまたは配布チャネルの最終成果物確認

---

## 11. ローンチ後へ送るもの

- docs/33 M1〜M3 / C1〜C5
- E8ザリガニ
- E9川エリア
- ステータス画面の大規模な見た目向上
- サメ生簀の専用背景、泡、全サメ演出
- 依頼ボードの専用素材とNPC個性
- 港、魚図鑑、釣具店、FIGHTの新P1を伴わない再調整
- SAVE-05 sandbox完全隔離
- Juicer.hit_stop(0)と既存pause復元の防御
- 起動フェード中closeの空save防御
- backup summaryのmtime精度

---

## 12. 文書上の既知矛盾と解消方針

### 12.1 docs/38 / 39 / 40の現在地

- docs/38とdocs/39は実装完了
- docs/qa/fishing_surface_qa.mdではREADY品質改善も採用・close
- docs/40は「未着手」のままだったため、本書保存と同時に「完了・履歴」へ修正
- READY最長名は、docs/40全体の再実装ではなく新しいP1再発として局所対応

### 12.2 市場M0 / 調理C0

- docs/30とdocs/33: 未着手P1
- 画面QA: v1採用、またはP1なしという古い判定
- 今回の実スクショ: docs/33記載症状を再確認

結論: docs/33を正としてP1再発で局所再オープンし、QAへ新しいbefore / afterを記録する。

### 12.3 title preview

tools/build_title_static_preview.pyは現行3スロットruntimeの正ではない。修正するまではruntimeスクショだけを判断根拠にする。

---

## 13. 次のAIエージェント向け開始手順

1. git status --shortでユーザー変更を確認する。reference/12_shark_pen_mockup.pngを戻さない・commitしない
2. docs/30 §現在地 / §3-4 / §4 / §6を読む
3. docs/30 §6の現行wave / ownerから1 concernだけ選ぶ。本書§5と§8は監査根拠として参照し、現行ownerと衝突する旧briefをそのまま使わない
4. UIならdocs/19と対象QA、E7 / E11なら当該phase docを読む
5. briefに「触る / 触らない / DoD / 検証」を明記
6. 独立作業だけ別worktreeへfan-outする。`player_progress.gd`のSAVE briefは直列、`TSURI_GODOT_HOME`はレーン別に分離する
7. 変更前に同一状態のbaselineを取得
8. 実装後に該当smoke / visual QA / validateを実行
9. 親エージェントがdiffと実スクショをレビュー
10. サブエージェントの最終レビュー後、日本語commit
11. docs/30の進捗と対象QAを同じcommitで更新

現行の安全なWave 1は、別worktreeの3並列で `SAVE-03` / 最小export spike / RIGHTS-01A証拠close。SAVE-04はSAVE-03統合後に同じstateレーンで開始する。最低対象Mac・Intel確認・署名/公証方針は外部判断レーンで同時に進める。

---

## 14. 更新履歴

- 2026-07-10: 全体コード、UI、QA、発売外周の横断監査を保存。発見事項、優先順位、brief、launch gateを確定
- 2026-07-11: 監査後の是正進捗を追補。SAVE-01、UI-QUEST-01、UI-READY-01、UI-M0-01、UI-C0-01を完了し、監査本文・open表記・Launch Gateチェックボックスは基準コミット時点の記録として維持
