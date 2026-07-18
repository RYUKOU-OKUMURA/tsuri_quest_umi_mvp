# 30. V2拡張 総覧（バージョン2 台帳）

作成日: 2026-07-06
状態: 仕様確定・V2実装進行中（E0〜E7・E10、docs/35〜44の完了分、Release Gate 0/1、ID-01、REL-01最小export、SAVE-01〜04・UI-QUEST-01・UI-READY-01・docs/33 M0/C0、QA-RELEASE骨格、DOCS-RELEASE草案を前提化。E11、RIGHTS-01A、TARGET-01 / SIGN-01、固定RC検証は未完）
位置づけ: **MVP完了を前提とした「バージョン2」拡張の正本**。docs/archive/27_retention_expansion_plan.md（計画）・docs/archive/28_retention_expansion_implementation_specs.md（一枚岩の実装仕様書）を本体系へ再編した。27/28は経緯資料として保存する

## 現在地（2026-07-16）

E0〜E7・E10 は実装・検証・台帳更新まで完了済み。以後の作業者は、これらを前提実装として扱う。

| 完了フェーズ | 完了内容 | 主な完了確認 |
|---|---|---|
| E1 | 記録更新演出、称号カタログ/判定、ステータス称号表示 | `status_smoke`, `catch_fanfare_smoke`, validate |
| E0 | レベル上限50、2段ソフトキャップ成長、Lv10ロード回帰 | `level_curve_audit`, `save_system_verify.sh`, cooking smoke, validate |
| E2 | 通常7釣り場のヌシ、出現条件、初回報酬、図鑑/港/釣行接続 | `fight_envelope_audit`, `nushi_encounter_audit`, visual QA, validate |
| E3 | 3スロットセーブ、依頼掲示3件、納品/記録報告、職人仕掛け、依頼ボード画面 | `quest_board_smoke`, `market_smoke`, `save_system_verify.sh`, visual QA, validate |
| E6 | 釣行中ランダムイベント3種（鳥山・流木・ボトルメール）、海図断片、鳥山演出 | `trip_event_audit`, 釣行smoke×2, `save_system_verify.sh`, validate |
| E4 | 危険海域（Lv/船/海図3段ロック）、サメ9種+白帝、横取り抽選/演出、マップピン/サムネ、サメ素材リアル化差し替え | `fishing_spot_select_smoke`, `nushi_encounter_audit`, `shark_ambush_audit`, 釣り場マップvisual QA, validate |
| E10 | サメ飼育、生簀画面、サメなつき度、餌やりEXP、メガロドン導線 | `shark_pen_smoke`, `shark_pen_screen_smoke`, `shark_lure_audit`, visual QA, validate |
| E5 | 港で選ぶ時間帯（朝まずめ/日中/夜釣り）、時間帯別出現重み、港/釣行グレーディング、夜BGM override | `time_slot_encounter_audit`, `harbor_screen_smoke`, 港/釣行visual QA, `save_system_verify.sh`, validate |
| E7 | 新規セーブ時の3難易度、全倍率、実ファイト接続、タイトル選択・上書き確認、ステータス表示 | `difficulty_fight_audit`, `save_system_verify.sh`, title/status visual QA, release verify, validate |

残り作業のロードマップ（2026-07-12、リリース前横断監査docs/45と是正進捗を反映）:

1. **Release Gate 0・ID-01・REL-01最小export（2026-07-11完了）** — user data namespace、macOS bundle ID、itch.io page slug / store App ID、旧MVP saveのコピー移行境界を確定。macOS Universal presetへbundle IDを配線し、debug / release export、clean起動・save再読込、旧namespace移行を実成果物で確認済み
2. **Release Gate 1（2026-07-11完了）** — SAVE-01の将来版セーブ保護、SAVE-02の保存失敗伝播、SAVE-03の意味検証付きbackup選択、SAVE-04の旧依頼repairを完了。後続E7も2026-07-12に完了
3. **E7（2026-07-12完了）** — 「難易度=新規セーブ時のみ」（決定#3）を実装。core→fight→UIの順で統合し、3難易度の倍率・実ファイト・保存・タイトル導線・ステータス表示・3スロット上書き安全性を同一commit系列で確認済み
4. **E11（進行中）** — SETTINGS-AUDIO、SLOT-DELETE UI、DISPLAY、INPUT-COMMON、画面別INPUT全roundは完了。入力baselineは42件から0件へ減少し、13画面すべてfinding 0。残りはEXTERIORと最終受入。docs/33 M0/C0と依頼/READYの局所P1は完了済み
5. **Pre-RC製品文書最終同期 → 固定RC検証 ＋ 性能/soak ＋ 3難易度通し確認** — release verifier骨格と製品文書草案は完了済み。E11 / 外部判断を反映してREADME等をPre-RCでcloseしてからRCを固定し、全smoke/audit、未説明ERROR / WARNING、clean export、1280x720・60fps目標と30分soak、序盤・中盤・終盤の人手受入を行う
6. **=== ローンチ ===**（スコープは決定#18）
7. **docs/33 素材供給ライン確立（M1〜M3 → C1〜C5）→ E8 → E9** — ローンチ後。E9 はローンチ反応を見て着手判断

## 0. ドキュメント体系（この再編の目的）

実装時に巨大な仕様書全体を読むノイズをなくすため、**フェーズごとに1ドキュメント**へ分割した。

- **本doc（docs/30）** = 台帳。位置づけ・フェーズ順・依存・横断の確定事項・共通仕様・進行状況。**実装前にここの §4 共通仕様だけ読む**
- **`docs/v2/E*.md`** = フェーズ別実装仕様。**各フェーズは「本doc §4 ＋ 当該フェーズdoc」の2つだけで着手できる**
- **`docs/45_release_readiness_code_review.md`** = 2026-07-10の発売前横断監査・是正brief・Launch Gate。仕様値の正本ではないが、E7/E11/発売作業では先に読む
- ワーカー（Composer）への brief は当該フェーズdocを指定して渡す。docs/archive/27_retention_expansion_plan.md・docs/archive/28_retention_expansion_implementation_specs.md を brief に含めない

| フェーズ | ドキュメント | 内容 |
|---|---|---|
| E1 | `docs/v2/E1_records_and_titles.md` | 記録更新演出＋称号 |
| E0 | `docs/v2/E0_level_cap.md` | レベルキャップ拡張（10→**50**） |
| E2 | `docs/v2/E2_nushi_system.md` | ヌシシステム |
| E3 | `docs/v2/E3_quest_board.md` | 依頼ボード |
| E6 | `docs/v2/E6_trip_events.md` | 釣行中ランダムイベント |
| E4 | `docs/v2/E4_shark_danger_reef.md` | サメ危険海域（釣り側） |
| E10 | `docs/v2/E10_shark_raising.md` | **サメ飼育・生簀（V2の目玉。新設）** |
| E5 | `docs/v2/E5_time_slots.md` | 時間帯（朝まずめ・夜釣り） |
| E7 | `docs/v2/E7_difficulty.md` | 難易度選択 |
| E8 | `docs/v2/E8_zarigani.md` | ザリガニ釣りミニゲーム |
| E9 | `docs/v2/E9_river_area.md` | 川エリア（横展開検証） |
| E11 | `docs/v2/E11_launch_readiness.md` | **ローンチ準備（設定画面・セーブ保護・表示/入力・権利台帳・export・製品外装）** |

## 1. 設計方針 — リテンションの環（docs/archive/27_retention_expansion_plan.md §2 を継承）

釣行の動機を「レベル上げ」一本から解放し、環を閉じる:

```
「今日は何を狙うか」──→ 釣行 ──→ 「記録更新・発見」──→ 「次の目標」──┐
        ↑ 依頼ボード(E3)         記録演出・称号(E1)      ヌシ図鑑(E2)   │
        └──────────────────────────────────────────────────────────────┘
      環の最終目標 = サメ危険海域(E4) → サメ飼育コンプとメガロドン(E10)
```

- E1〜E4 がコア。この4つで環が閉じる。順序を崩さない
- **E10（サメ飼育）は環のエンドコンテンツ**。「売る／料理する／サメの餌にする」の第3の使い道を作り、低レア魚の釣行にも意味を与える。Lv30→50 の主経験値源でもある
- E5〜E6 はスパイス、E7〜E8 はポリッシュ、E9 は横展開の仮説検証。難易度・ミニゲームを先にやらない

## 2. フェーズ実施順と依存

| 順 | ID | 内容 | 前提 | 規模感 | 新素材 |
|---|---|---|---|---|---|
| 1 | E1 | 記録更新演出＋称号 | なし | 小 | 不要 |
| 2 | E0 | レベルキャップ 10→50 | なし（E1と並走可） | 小 | 不要 |
| 3 | E2 | ヌシシステム | E1 | 中 | 小（ヌシ7体素材） |
| 4 | E3 | 依頼ボード | E1 | 大 | 要（画面素材一式） |
| 5 | E6 | 釣行中ランダムイベント | なし | 中 | 小 |
| 6 | E4 | サメ危険海域 | E0・E2・E6 | 中 | 要（サメ素材。§13） |
| 7 | E10 | サメ飼育・生簀 | E4 | 大 | 要（生簀画面一式） |
| 8 | E5 | 時間帯 | E0（夜=Lv15） | 中 | 中 |
| 9 | E7 | 難易度選択 | E0〜E6・E10・Release Gate 1（SAVE-01〜04） | 小 | 小 |
| 10 | E11 | ローンチ準備（実装部。台帳運用とRelease Gate 0は前倒し完了→E11 doc §E11-0） | E7（ID-01・最小export・権利証跡は先行可） | 中 | 小 |
| 11 | E8 | ザリガニ釣り | E3 | 中 | 要 |
| 12 | E9 | 川エリア | E1〜E8 | 特大 | 特大 |

依存グラフ（E10追加分）: `E4 → E10`。E10 は E0 の Lv30→50 帯の経験値供給を担うため、**E10 完了までは Lv30 以降のレベリングが実質停滞してよい**（意図された設計。E0 doc §用途を参照）。

**リリース単位の制約（決定#14）**: E4（サメ釣り）と E10（サメ飼育）は内部フェーズとしては別だが、**プレイヤーへのリリースは同時**にする。E4 単体で出すと (a) サメが一時的に売却可能になり E10 で挙動が変わる、(b) Lv30 以降の経験値供給源がない状態が露出する。

**ローンチ境界（決定#18）**: 上表の実施順は変えないが、リリースは E11 完了時点で1回切る。**ローンチスコープ = E0〜E7 + E10 + E11**（＋品質トラック docs/33 の P1掃除、docs/35、docs/36）。**E8（ザリガニ）・E9（川エリア）はローンチ後アップデート**に回す。E9 は横展開の仮説検証（特大・素材38点）のため、ローンチ後の反応を見てから着手判断する（§1「難易度・ミニゲームを先にやらない」の精神と整合）。詳細は決定#18。

## 3. 確定事項（横断）

### 3-1. ユーザー決定

docs/archive/27_retention_expansion_plan.md §7 の決定 #1〜#9（時間帯=港で選択 / 依頼リフレッシュ=達成＆帰港 / 難易度=新規セーブ時のみ / ヌシ図鑑=金枠＋ヌシタブ / サメ海域解放=告知＋海図 / 横取り=掛けた魚のロストのみ / 川=同一セーブ内エリア / サメ・川導入確定）は全て有効。以下を追加:

| # | 項目 | 決定内容 |
|---|---|---|
| 10 | レベル上限 | **MAX_LEVEL は 10→50 へ一度に拡張**（E0改訂。旧仕様の30は経由しない）。Lv30=サメ海域・飼育の解放、Lv50=メガロドンの解放条件。Lv31以降のステータス成長はほぼゼロ（純ゲート）（2026-07-06確定） |
| 11 | サメ飼育システム | **導入確定（E10新設）**。危険海域で釣ったサメを生簀で飼育・コレクションする。餌にできるのは**自分で釣った魚のみ**（本ゲームの魚入手経路は釣りのみのため自動成立。§3-3不変条件）（2026-07-06確定） |
| 12 | サメの餌の消費制 | **サメ狙いの餌魚（釣行時）とサメ飼育の餌やりの両方で、釣った魚を消費する**。決定#6「消耗品システムは導入しない」の**サメ関連のみの例外**として明示的に上書きする（2026-07-06確定）。**2026-07-07改訂**: 釣行時の餌魚は「出港前セット・釣行開始時消費」から「危険海域READYで選択・キャスト時消費＋レア度別耐久チャージ（コモン1/アンコモン2/レア3/ぬし5回）」へ変更（docs/37・docs/38） |
| 13 | メガロドン | **飼育軸の頂点**。解放条件は「Lv50 到達 ＋ 通常サメ9種の飼育完了」の複合。釣り軸の頂点であるヌシ「深海の白帝（ホホジロザメ）」とは役割を分ける（2026-07-06確定） |
| 14 | E4とE10のリリース単位 | **同時リリース**（内部フェーズは分けたまま）。§2 の制約を参照（2026-07-06確定） |
| 15 | ヌシの売却 | **許容する**（`record_catch` は現行どおりヌシもインベントリへ入れる）。メガロドンの餌（ヌシ級を捧げる）の供給源として必要。売却不可にするのは `shark: true` のサメのみ（E10）（2026-07-06確定） |
| 16 | チート対策 | **しない**。セーブはJSON平文のまま許容（シングルプレイヤー・子供向け）（2026-07-06確定） |
| 17 | セーブスロット | **3スロット**。E3のセーブスキーマ変更と同時に移行を実施（仕様は E11 doc §E11-2、実施は E3）（2026-07-06確定） |
| 18 | ローンチスコープ | **E0〜E7 + E10 + E11 でローンチを1回切る**（＋品質トラック docs/33 P1掃除・docs/35・docs/36）。E8・E9 はローンチ後アップデート。ローンチ前必須の根拠: E7「難易度=新規セーブ時のみ」（決定#3）はローンチ後追加だと初期セーブに難易度が無く体験が割れる、E5 もセーブスキーマ・港UIに触るため先に枯らす、E11 は「ゲーム内容が固まってから蓋を閉める」フェーズ。docs/33 の重い素材工事（M1〜C5）はローンチブロッカーでないためローンチ後（2026-07-07確定） |
| 19 | 基盤レイアウト原則（ゲームプレイ画面） | **釣行画面ファミリーは「シーン優先・下段スリムバー・主操作1つを大きく・フローティングカード」を基盤UIとする**。正本は `docs/19` §4.6、参照は `reference/13`（READY）/ `reference/14`（FIGHT）。実装は docs/38（READY）→ docs/39（水中ファイト）。既存freeze値の上書きはQAドキュメントの判断ログ必須。メニュー系・一覧系画面は対象外（2026-07-07確定） |
| 20 | Release Gate 0 | **初回販売チャネルはitch.io、対象OS / 配布形式はmacOS Universal（Apple Silicon＋Intel）、対応入力はマウス＋キーボード専用（ゲームパッド非対応）、非16:9は`keep`＋黒帯、正式製品名は「釣りクエスト ～海釣り編～」・製品バージョンはv1.0.0**とする（2026-07-11確定）。将来の他チャネル・他OS対応は本決定に含めない |

### 3-2. Fable 設計判断（2026-07-06。詳細は E4 / E10 doc）

| 項目 | 決定 | 理由 |
|---|---|---|
| サメのロスター | 10種確定: ネコザメ / イヌザメ / ドチザメ / ホシザメ（通常）、エポレットシャーク / ダルマザメ / フジクジラ（レア）、シュモクザメ / ホオジロザメ（大型・強敵）、メガロドン（特別）。旧E4案の**アオザメは廃止**し、ヌシ「白帝」の基準魚は hohojirozame へ変更 | ユーザー選定10種（2026-07-06）を正とする。子供が名前と姿で覚えやすい枠を優先 |
| サメの入手後の扱い | **釣ると生簀へ直行**（インベントリに入らない・売却/料理不可）。図鑑・称号は `caught_counts` で機能する | 「育てるか売るか」の板挟みを作らない。経済（売値）と飼育価値の衝突を根から断つ |
| 好物の判定 | 魚カタログの `style` × `rarity` で引くカタログ駆動の pure 関数 | 魚IDのハードコード列挙を避け、E9川魚追加時も自動で好物判定が働く |
| 大型サメ2種の出現 | **好物の餌魚をセットした釣行でのみ**抽選テーブルに乗る（E10の餌システム導入と同時に解禁。E4時点では出現しない） | 「レアな魚を釣る→餌にして大物サメを狙う」の環を作る |

### 3-3. 不変条件

- **魚がインベントリに入る経路は釣りのみを維持する**（依頼報酬はお金・称号のみ、市場は売却専用）。これが崩れると決定#11「自分で釣った魚しか餌にできない」が入手経路フラグなしで成立しなくなる。魚を配布する機能を追加する場合は本docの決定表を先に改訂すること
- **依頼（E3）の抽選対象に `shark: true` の魚とヌシを含めない**。サメはE10以降インベントリに入らないため、含めると達成不能依頼が生成される

### 3-4. Release Gate 0（2026-07-11確定。詳細は E11 doc §E11-7）

E11実装と正式名称変更に先立ち、docs/45のRelease Gate 0を次のとおり確定した。

| # | 項目 | 決定内容 | 決定日 |
|---|---|---|---|
| 1 | 初回販売チャネル | itch.io | 2026-07-11 |
| 2 | 対象OS / 配布形式 | macOS Universal（Apple Silicon＋Intel） | 2026-07-11 |
| 3 | 対応入力 | マウス＋キーボード専用（ゲームパッド非対応） | 2026-07-11 |
| 4 | 非16:9の表示方針 | `keep`＋黒帯 | 2026-07-11 |
| 5 | 正式名称 / version表記 | 「釣りクエスト ～海釣り編～」/ v1.0.0 | 2026-07-11 |

セーブスロット数は決定#17の3スロットで解消済み。

ID-01でGodotのuser data namespace、macOSのOS application / bundle ID、itch.ioのpage slug / store App IDを別々の値として確定した。詳細と移行契約は§3-5を正とする。正式名称のruntime反映は、namespace移行回帰と後続の最小export spikeを通過後、E11-EXTERIORで行う。

上表5件とは別に、PERF-RELEASE着手前の技術判断として「macOSの最低対象ハードウェア / 性能計測の基準機」を記録する。これはユーザー向け機能選択ではないため決定番号を分ける。

### 3-5. ID-01 製品識別子と旧MVP save移行（2026-07-11確定）

| 用途 | 確定値 | 適用・後続 |
|---|---|---|
| Godot user data namespace | `tsuri_quest_umi` | `project.godot`へ適用。表示名変更後も固定 |
| macOS application / bundle ID | `net.physical-balance-lab.tsuri-quest-umi` | 値は確定。最小export spikeで`export_presets.cfg`へ配線 |
| itch.io page slug | `tsuri-quest-umi` | 予定値。予約・発行済みとは扱わない |
| itch.io store App ID | `未発行` | 発行後に値と管理先を追記 |
| 旧MVP namespace | `Godot/app_userdata/釣りクエスト ～海釣り編～ MVP` | 初回の安全なコピー元。旧原本は削除・変更しない |

namespace間移行は次を不変契約とする。

- 新namespace内のsave artifact（rootの旧単一main / backup / tmp、3slotのmain / backup / tmp）が0件の場合だけ全体をコピーする。logs等の自動生成物は空判定に含めない
- 新側にsave artifactが1件でもあれば全件をskipし、欠けたslotだけ補完しない。既存ファイルは上書きしない
- 旧namespace原本はrename / removeせず、コピー前後のhashを維持する。slot 1と旧単一saveが同種で併存する場合はslot 1を優先する
- 移行marker、tmp copy、hash照合により再起動時も冪等にし、途中再開では同一hashだけを既コピー扱いする。不一致時は採用せず通知する
- 移行完了または安全なskipが確定できない間はload / save / reset / slot切替を遮断し、タイトルの3slotを「利用不可（再起動）」として表示する。部分コピーを空slotとして扱わない
- future / 不明versionはbyte copy後にSAVE-01 guardへ渡す。移行完了後も旧原本と新側main / backup / tmpを破壊しない
- `config/name`のMVP除去、runtime version、bundle IDのpreset配線は本タスクに含めず、最小export spike通過後のE11-EXTERIORへ渡す

## 4. 共通仕様（全フェーズ。着手前にここだけ読む）

### 4-1. セーブスキーマ追加の全量

すべてロード時デフォルト補完（`player_progress.gd` の `_apply_save_data()`、`owned_rigs` と同じ流儀）。`SAVE_VERSION` は 1 のまま。

| フィールド | 型 | デフォルト | 追加フェーズ | 内容 |
|---|---|---|---|---|
| `difficulty_id` | String | `"normal"` | E7 | 難易度ID |
| `quest_board` | Array[Dictionary] | `[]` | E3 | 掲示中の依頼（最大3件） |
| `quest_completed_count` | int | `0` | E3 | 依頼達成の累計 |
| `sea_chart_fragments` | int | `0` | E6 | 海図断片（0〜3） |
| `selected_time_slot_id` | String | `"daytime"` | E5 | 港で最後に選んだ時間帯 |
| `shark_bonds` | Dictionary | `{}` | E10 | shark_id → なつき度 int（0〜100） |

**保存しないもの**（統計から毎回導出）: 称号、ヌシ捕獲フラグ、記録更新歴、サメ捕獲（`caught_counts` で判る）、メガロドン解放可否（Lv＋shark_bondsから導出）。

**JSON数値の型補正**: セーブはJSONのため、読み込み時に数値は全てfloatで返る。数値フィールドは既存の流儀どおり**読み出し側で `int(...)` / `float(...)` を必ず噛ませる**（`caught_counts` 等の前例に倣う。`shark_bonds` の値・`quest_board` の `count` も同様）。

**save候補の意味検証（docs/45 SAVE-03）**: 現行version 1は欠損フィールドをデフォルト補完するため、欠損だけで破損扱いしない。意味検証を実装する前に、本節へ「必須key / 任意key / 型・範囲 / 正常な疎save fixture / 破損fixture」の契約表を追加する。その契約がない状態で `{"version": 1}` 等を独断で無効化しない。

#### version 1 save候補の意味検証契約

JSON rootが`Dictionary`で、下表の既知keyを1つ以上持つことを必須とし、**個別に必須の進行keyは設けない**。version欠損でも既知keyを持つ旧saveと、`{"version": 1}`を含む疎saveは、欠損keyをロード時デフォルト補完する正常候補である。空Dictionaryと未知keyしかないDictionaryは、正常backupより優先して全進行をdefault化しないよう意味破損とする。未知keyは既知keyと併存する場合だけ互換payloadとして無視する。

表中の「数学的な整数」は有限かつ小数部がなく、JSON floatで整数精度を保てる`0〜9,007,199,254,740,991`（`2^53-1`）以内とする。`level`等に個別上限がある場合は、さらに狭い個別範囲を優先する。

| key群 | 必須 / 任意 | 許容型・意味範囲 |
|---|---|---|
| `version` | 任意 | 数学的な整数で現行版なら`1`。非数値はSAVE-01のunknown version guard、`1`超はfuture guardへ渡す |
| `level` | 任意 | 数学的な整数、1〜`GameData.MAX_LEVEL` |
| `exp`, `money`, `quest_completed_count` | 任意 | 数学的な整数、0以上かつJSON安全整数上限以下 |
| `play_seconds` | 任意 | 数値、有限、0以上 |
| `sea_chart_fragments` | 任意 | 数学的な整数、0〜3 |
| `inventory`, `caught_counts` | 任意 | Dictionary。各valueは数学的な整数、0以上かつJSON安全整数上限以下。既存UI・称号の合算をint64範囲内に保つため、Dictionary全valueの総和もJSON安全整数上限以下 |
| `spot_caught_counts` | 任意 | `Dictionary[spot_id, Dictionary[fish_id, count]]`。spot / fish IDは空でないString、countは数学的な整数、0以上かつJSON安全整数上限以下 |
| `best_sizes` | 任意 | Dictionary。各valueは有限数値、0以上 |
| `eaten_recipes` | 任意 | Dictionary。各valueは数学的な整数、0以上かつJSON安全整数上限以下。称号・状態表示の合算を安全に保つため、Dictionary全valueの総和もJSON安全整数上限以下 |
| `owned_rods`, `owned_rigs`, `owned_boats` | 任意 | Array。各要素はString（既知IDへの絞り込みはロード正規化の責務） |
| `equipped_rod_id`, `equipped_rig_id`, `selected_time_slot_id` | 任意 | String（未知・未解放IDのfallbackはロード正規化の責務） |
| `difficulty_id` | 任意 | String。欠損・未知IDはロード時に`normal`へ補完 |
| `pending_buff` | 任意 | Dictionary。`{}`はbuffなし。非空時は`recipe_id` / `name` / `stat` / `value` / `text`を必須とし、ID・名前・statは空でないString、textはString、valueは有限数値かつ`0 < value <= 1.0`。statは`max_energy` / `bite_window` / `safe_range` / `energy_regen` / `reel_power`のいずれか。recipe_idは既知recipeで、stat / value / textはそのrecipeのbuff定義と一致すること。料理済み魚名を含むnameは非空のみ検証し、未知fieldは互換payloadとして許容 |
| `quest_board` | 任意 | Array。各要素はDictionary。既知fieldがあればID / kindはString、count / rewardは0以上かつJSON安全整数上限以下の整数、sizeは有限かつ0以上。魚IDの存在・達成可否はload時にSAVE-04のrepair契約で補正 |
| `shark_bonds` | 任意 | Dictionary。各valueは数学的な整数、0以上かつJSON安全整数上限以下（100超のclampとshark IDの絞り込みは既存ロード正規化の責務） |

- 正常な疎save fixture: `{"version": 1}`、`{"level": 7, "money": 321, "sparse_payload": "keep compatible"}`
- 意味破損fixture: `{}`、`{"unknown_only": true}`、`{"version": 1, "level": {}}`、`{"version": 1, "money": -1}`、`{"version": 1, "money": 0.5}`、`{"version": 1, "money": 1e100}`、`{"version": 1, "play_seconds": null}`、`{"version": 1, "inventory": []}`、`inventory` / `caught_counts` / `eaten_recipes`の各valueまたは全value総和がJSON安全整数上限を超えるもの、`{"version": 1, "spot_caught_counts": {"harbor_pier": []}}`、`{"version": 1, "spot_caught_counts": {"harbor_pier": {"aji": -1}}}`、非空`pending_buff`の必須field欠損・value範囲外・未知recipe / stat・recipe buff定義との不一致、`{"version": 1, "quest_board": ["broken"]}`
- 候補選択はmain、backupの順に同じ検証関数を適用する。意味破損mainは正常backupへfallbackし、`load_game()`と`save_slot_summary()`は同じ選択結果を使用する。fallback後の保存は不正mainで正常backupを上書きせず、保存失敗時も正常世代を残す。両方にartifactがあるのに正常候補がなければ、titleとcoreのsave / resetを持続的に遮断・通知して原本を変更しない
- `save_game()`は書き出すruntime dataにも同じ意味検証をtmp作成前に適用し、範囲外ならmain / backup / tmpを変更せず失敗通知する。通常操作による所持金・EXP・捕獲/所持/料理/依頼回数の加算と売却額・売却数の積算はJSON安全整数上限でsaturateする。売値×数量はint64積を作る前に上限判定し、市場の確認表示と実売却は同じpure見積を共有して、正常saveが次回loadで自己破損しない

セーブを触るフェーズのDoDには必ず `./tools/save_system_verify.sh` を含める。

### 4-2. pure関数境界（docs/26 R3 の維持）

- データ表は `src/autoload/game_catalog_data.gd`（量次第で `*_expansion_data.gd` 新設可。`fish_expansion_data.gd` 前例）
- 判定・抽選は `src/autoload/game_data.gd` に pure 関数（「重みテーブルを返す pure 関数」＋「それを引く roll 関数」に分け、監査はテーブル側を叩く）
- 進行状態の読み書きは `src/autoload/player_progress.gd` のみ

### 4-3. 新魚・新画面の規約

- 新魚（サメ・ザリガニ・川魚・ヌシ）は `assets/showcase/fish/` に `<id>_card_portrait.png` + `<id>_showcase_sheet.png` の2点セット。参照は `FightFishAssets` 経由
- 素材ブリーフを docs/22〜24 方式で書き、**サンプル生成→品質確認をコード実装より先に**行う
- 新画面は `skills/ui-screen-build/SKILL.md` の工程、既存画面改修は `skills/ui-screen-uplift/`。freeze値（`docs/qa/<screen>_qa.md`）は動かさない。日本語テキストのPNG焼き込み禁止

### 4-4. smoke・監査の増設一覧

| フェーズ | 新設 | 検証内容 |
|---|---|---|
| E1 | （`status_smoke` / `catch_fanfare_smoke` に追加） | 称号判定・記録演出 |
| E0 | `level_curve_audit.tscn` | Lv1〜50の必要経験値とステータス成長 |
| E2 | `fight_envelope_audit.tscn` + `nushi_encounter_audit.tscn` | ヌシ級ステータスでのファイト成立（勝率・所要時間・ライン切れ率。E2最初のスライス） / 条件成立/不成立のヌシ出現率 |
| E3 | `quest_board_smoke.tscn` | 生成→納品→リフレッシュの一巡 |
| E6 | `trip_event_audit.tscn` | イベント抽選分布・海図断片 |
| E4 | （既存smoke/監査に追加） | 海図ロック・横取り抽選・サメ出現 |
| E10 | `shark_pen_smoke.tscn` + `shark_pen_screen_smoke.tscn` + `harbor_screen_smoke.tscn` + `shark_lure_audit.tscn` | 餌やり→なつき度→経験値の一巡 / 生簀画面 / 港導線と餌魚セット / 餌魚別のサメ出現テーブル |
| E5 | `time_slot_encounter_audit.tscn` | 時間帯別テーブル、解放Lv、保存デフォルト、BGM override |
| E7 | `difficulty_fight_audit.tscn` | 3難易度のファイト指標 |
| E11 | `settings_smoke.tscn` | 設定の保存・復元、セーブ削除の二重確認 |
| E8 | `zarigani_flow_smoke.tscn` | 水路釣行→納品の一巡 |
| E9 | 既存smokeの川版一式 | — |

**監査シーンの共通ハーネス**: 最初に作る `level_curve_audit`（E0）で表出力の共通ヘルパ（見出し＋行の整形print）を `tools/` に切り出し、以後の監査シーン（nushi / trip_event / shark_lure / difficulty / fight_envelope）はそれを使い回す。監査の品質と読みやすさを揃えるため。

### 4-5. 着手前チェックリスト（オーケストレーター用）

1. ベースライン green: `./tools/validate_project.sh` + docs/26 §Smoke 全通過から始める
2. リファクタ・他フェーズと同一ファイルで並走しない
3. 数値（確率・倍率・経験値・しきい値）は**初期値**。headless監査で分布確認して調整してよいが、変更したら当該フェーズdocの表を更新する
4. 当該フェーズdocと本docが矛盾したら本docが優先。ただし本doc側を改訂してから作業する
5. 釣り場マップへの追加（E4/E8/E9）はフェーズごとに1回にまとめ、freeze値照合を先に行う

## 5. 素材ブリーフ一覧（コード実装より先に書く）

| フェーズ | 対象 | 点数 | 置き場所 |
|---|---|---|---|
| E2 | ヌシ7体（各2点） | 14 | `assets/showcase/fish/` |
| E3 | 依頼ボード画面一式 + reference | 一式 | `assets/showcase/quest_board/` + `reference/` |
| E6 | 鳥山スプライト（流用不可の場合のみ） | 1 | common/ か fishing画面 |
| E4 | サメ9種＋ヌシ白帝（各2点）+ 危険海域マップサムネ | 21 | fish/ + fishing_spot_map画面 |
| E10 | メガロドン（2点）+ 生簀画面reference（画面本体はruntime描画） | 2+reference | fish/ + `reference/` + `docs/34_shark_pen_screen_spec.md` |
| E5 | グレーディング検証後、不足画面の背景のみ | 検証後確定 | 各画面 |
| E7 | 難易度選択パネル | 1〜2 | title画面 |
| E8 | ザリガニ（2点）+ 水路背景 | 3 | fish/ + fishing画面 |
| E9 | 川魚16種（32点）+ 川背景3 + サムネ3 | 38 | fish/ + 各画面 |
| E11 | 設定画面（既存共通素材の流用を第一候補）+ 製品アイコン + ブートスプラッシュ | 最小 | common/ + `assets/`（追加素材は docs/31 台帳へ記入） |

## 6. 進行状況

**本節を発売前作業の状態・開始可否・統合順の正本とする。** `docs/45_release_readiness_code_review.md` は監査時点の発見事項・brief・Launch Gateを保存するスナップショットであり、完了状態や次の着手対象は本節を優先する。状態を変えたスライスは、実装・検証・本節更新を同じコミットへ含める。

### 6-1. 発売クリティカルパスと合流条件

クリティカルパスは次で固定する。

`SAVE-03 → SAVE-04 → E7 → E11 → RC固定 → RC検証 → itch.io配布`

~~~mermaid
flowchart LR
  S3["SAVE-03 意味検証"] --> S4["SAVE-04 旧依頼repair"]
  S4 --> E7["E7 難易度"]
  E7 --> E11A["E11 設定・削除・表示・入力"]
  E11A --> E11B["E11 製品外装"]
  E11B --> PRE["Pre-RC close"]
  PRE --> RCF["RC固定"]
  RCF --> RCV["RC検証"]
  RCV --> DIST["itch.io配布"]

  ID["ID-01 完了"] --> EX["最小export spike"]
  EX --> E11B
  ICON["RIGHTS-01A U-04 icon採否"] --> E11B
  RIGHTSA["RIGHTS-01A 出所・入力権利"] --> PRE
  RCF --> RIGHTSB["RIGHTS-01B 配布物同梱"]
  RIGHTSB --> RCV
  TARGET["対象Mac・署名方針"] --> PRE
  DOCS["製品文書"] --> PRE
  VERIFY["release verifier骨格"] --> PRE
~~~

`RC固定` は検証対象のsource commit・Godot / export template版・成果物hashを不変にする境界とする。素材差し替えへ発展し得るRIGHTS-01A、対象Mac・署名/公証方針、README等のsource-controlled製品文書、release verifier骨格はPre-RCで閉じる。RC生成時にunsigned export hashを記録し、方針上必要なら同じsourceから署名・公証済み配布物を作ってfinal artifact / ZIP hashを別々に記録する。以後のclean起動・性能・9セル受入は**最終配布物そのもの**を対象にする。修正・再export・再署名でfinal hashが変わった場合はRC番号を上げ、影響検証に加えてrelease verifier全体を再実行する。検証ログは固定したsource commit / final artifact hashを参照する証拠として後続commitへ保存できるが、パッケージ入力を変えない。

### 6-2. 並列レーンと単一owner

初動は3実装レーン＋外部判断レーンで進める。開始順と統合順は別であり、同じ集約ファイルを複数レーンが同時に編集しない。

| レーン | 直列の本線 | 主な単一owner範囲 | 合流先 |
|---|---|---|---|
| A: state / gameplay | `SAVE-03 → SAVE-04 → E7-core → E11 slot削除backend` | `player_progress.gd`、save fixture / smoke | E7 Gate、E11 Gate |
| B: release engineering | `最小export → verifier骨格 → 最終export / hash` | `export_presets.cfg`、export smoke、release manifest / runner | E11外装、RC検証 |
| C: rights / packaging | `RIGHTS-01A: U-01〜U-08の出所・入力権利・icon・商標・権利者判断 → RIGHTS-01B: notice/OFL同梱確認` | `docs/31`、`LICENSE.md`、`THIRD_PARTY_NOTICES.md`、licensing evidence | RC固定、RC検証 |
| D: external decision / acceptance | 最低macOS・最低対象Mac・Intel確認・署名/公証・itch.io設定 | ユーザー/外部サービスでしか確定できない証拠と判断 | PERF、最終配布 |
| E: E11 settings spine | `SETTINGS-AUDIO → SLOT-DELETE UI → DISPLAY → INPUT-COMMON（ここまで完了）→ EXTERIOR` | `settings_screen.gd`、`settings_smoke.gd`、共有設定の統合 | E11 Gate |

レーンBの最小export完了後、`project.godot` のownerをレーンEへ一時移譲する。E11外装まで統合後にレーンBへ戻し、最終exportを作る。レーンCは `export_presets.cfg` を直接編集せず、同梱要件をレーンBへ引き渡す。EXTERIORでicon / splashを追加・差し替えるcommitだけはレーンCを止め、`docs/31`のownerもレーンEへ一時移譲して素材と台帳を同じcommitへ入れる。

### 6-3. wave実行順

| Wave / Gate | 同時に進める作業 | 統合条件 |
|---|---|---|
| Wave 0: baseline | 親がclean worktree、全体validate、save smoke、各レーンのbranch/worktreeと担当ファイルを固定 | baseline greenと差分0を記録 |
| Wave 1: 即時3並列 | A=`SAVE-03`、B=`最小export spike`、C=`RIGHTS-01A`の既存台帳とU-01〜U-08対応表。Dは最低対象Mac・Intel確認・署名/公証方針を決定 | 各レーンを独立commit。共有ファイル競合0 |
| Wave 2: save完了待ち | A=`SAVE-04`、B=release manifest / runner骨格、C=証拠回収継続 | **SAVE Gate**: `save_system_verify.sh`、quest / shark回帰、validate green |
| Wave 3: E7 | 先にE7-coreのAPIを統合。そのcommitを基点にE7-fightとE7-UIを並列化し、core→fight→UIの順でrebase / 統合。B/C/Dは継続 | **E7 Gate**: difficulty audit、save回帰、title/status runtime visual QA、validate green |
| Wave 4A: E11 spine | `SETTINGS-AUDIO → SLOT-DELETE UI → DISPLAY → INPUT-COMMON` は完了。EXTERIORはU-04のicon採否と `title` / `settings` のowner境界解消後に開始し、残る画面別入力と並走できる | spine各sliceでsettings smoke、関連smoke / visual QA、validate green |
| Wave 4B: 画面別入力 | **完了**。INPUT-COMMON統合済みtipから、監査で失敗した画面を1画面1brief・最大3並列で修正し、最終SHARK_PENを含む13画面すべてfinding 0へ収束 | **E11 Gate**: 設定・削除・表示・全画面入力・外装・最小export回帰がgreen |
| Wave 4C: Pre-RC close | E11、REL-01、RIGHTS-01A、TARGET-01 / SIGN-01、release verifier骨格、README等4文書をclose | 全パッケージ入力がcommit済み。RCを作り直す未確定値0 |
| Wave 5A: RC固定・機械Gate | Pre-RC commitからdebug/release成果物を作り、必要な署名・公証を実施。source commit / template / unsigned hash / final artifact・ZIP hashを固定し、最終配布物でrelease verifierとclean起動を実行 | 未説明ERROR 0、全smoke / audit green、save移行・export再読込green |
| Wave 5B: 同一RCの並列受入 | 性能/30分soak、RIGHTS-01Bのnotice/OFL同梱、3難易度9セル受入を同じRCで並列実施 | Launch Gate全項目close。修正時はRCを再固定 |
| Wave 6: 最終配布 | 固定済みの最終ZIPを変更せずitch.ioへuploadし、実download、hash照合、clean環境起動 | 公開判定と配布証拠を保存 |

E7の並列境界は次のとおり。E7-coreだけが `player_progress.gd` を所有し、売却・料理・サメ餌やりを含むEXP/販売倍率と `difficulty_id` 保存を実装する。E7-fightは `fishing_screen.gd`、E7-UIは `title_screen.gd` / `status_screen.gd` / title QAを所有する。使用済みslotの上書き確認は**1回**とし、slot番号・Lv・プレイ時間・選択難易度・不可逆警告・安全なcancel focusを同じ最終確認へ表示する。二段階確認は採用しない。

E11は共有ハブを持つため、全体を複数workerへ同時に渡さない。spineの横で先行できるのは、共有ハブを編集しない入力監査harness、visual QA script、release verifier、権利証跡、製品文書草案とする。画面別入力修正はINPUT-COMMON後だけfan-outする。

### 6-4. 並列実行の衝突防止

- 各実装レーンは別branchだけでなく別worktreeを使う。1 slice = 1 concern = 1以上の小さな日本語commitとする
- `save_system_verify.sh` は `TSURI_GODOT_HOME` を破壊対象HOMEではなくrun親として扱い、その直下にmigration/save別の一時HOMEを自動生成する。並列実行でも同じ親を共有でき、各sceneはtoken付き物理path guardを通過したrun子HOME以外へ書き込まない
- visual QAの多くは固定 `/tmp/tsuri_*.png` を使う。同じvisual QA scriptは同時実行せず、親が統合後に正規証拠を再生成する
- `player_progress.gd` は `SAVE-03 → SAVE-04 → E7-core → E11 slot削除backend` の単一writer直列とする
- `project.godot`だけをレーンB→E→Bの順でowner移譲する。`export_presets.cfg`は全waveを通してレーンBが継続所有し、他レーンは編集しない
- `project.godot`のID-01値 `config/use_custom_user_dir=true` / `config/custom_user_dir_name="tsuri_quest_umi"` は全レーンでfreezeする。最小exportとE11は回帰確認だけ行う
- `title_screen.gd` は `E7-UI → settings導線 / slot削除 → EXTERIOR` の統合順を守る
- `settings_screen.gd` / `settings_smoke.gd` はE11 settings spineの単一ownerとする。slot削除backendだけはレーンAで先行実装できる
- `export_launch_smoke.*` はレーンB、`release_verify.sh` / manifest / CIはrelease verifier担当が所有し、二重所有しない
- `docs/30`の進捗欄は親が所有する。SAVE-03の§4-1契約をworkerへ渡す間だけ明示的にownerを移し、他レーンから同時更新しない
- `docs/31`は通常レーンCが所有する。EXTERIORの新素材commitだけはレーンEへownerを移し、素材追加と台帳更新を分離しない
- worker報告だけで完了扱いにしない。親がdiff・実スクショ・該当smokeを確認し、サブエージェントレビュー後に統合する

### 6-5. 発売前作業台帳

| ID | 状態 | 前提 / 現在の次アクション |
|---|---|---|
| SAVE-03 | **完了** | version 1契約に基づくmain / backup共通意味検証、load / title要約の候補選択共用、両候補不正時の通知・原本hash維持をsave smokeで確認 |
| SAVE-04 | **完了** | 未知魚・サメ・ヌシ依頼をload時に除去し、正常依頼の内容・順序を維持して現行生成規則で3件へ補充。quest / shark / save回帰green |
| E7 | **完了** | core→fight→UIの順で同一commit系列へ統合。倍率・save・実ファイト・タイトル/ステータスUI・runtime visual QAをE7 Gateで確認 |
| ID-01 | **完了** | namespace、bundle ID、itch.io slug、store App ID、旧名称save移行境界を固定済み |
| REL-01 最小export | **完了** | Godot 4.7 stable / 同版templateでmacOS Universalのdebug/releaseを生成。bundle ID、arm64+x86_64、clean save/reload、旧namespace非破壊移行、開発素材の除外を確認。署名/公証とnotice/OFL同梱はSIGN-01 / RIGHTS-01B / RC Gateで継続 |
| RIGHTS-01A | **外部証拠待ち** | リポジトリ側の全件監査・証拠入力手順・虚偽状態検査を整備し、`[RIGHTS-01A]=pending`を維持。U-01〜U-06 / U-08の出所・入力権利・icon・商標・権利者名をRC固定前に外部証拠でcloseする（U-07の成果物同梱確認はRIGHTS-01B） |
| RIGHTS-01B | RC待ち | 最終成果物でnotice・Godot由来license・OFL 2件の同梱と質問票回答控えを確認する |
| TARGET-01 / SIGN-01 | ユーザー判断待ち | 最低macOS、最低対象Mac、Intel確認方法、Developer ID署名・公証を発売条件にするかを確定 |
| E11実装 | **進行中** | SETTINGS-AUDIO、セーブ枠削除backend/UI、DISPLAY、INPUT-COMMON、画面別INPUT全roundを完了。13画面をfinding 0へ収束し、最新baselineは0件。次はowner境界とU-04解消後のEXTERIOR、最終受入へ進む |
| QA-RELEASE | **骨格完了** | 画面別input smoke 13本を含む47対象をmanifest完全一致で列挙。run固有HOME / logs、source・manifest開始終了hash、未知ERROR / WARNING拒否、fixture単位の既知警告scope、RC成果物再hashを実装し、skeleton 47対象はgreen。固定RCの`--rc`実行は未完 |
| PERF-RELEASE | TARGET-01とRC待ち | 基準機・計測法の固定後、重い代表状態と30分soak |
| DOCS-RELEASE | **草案完了** | README / VALIDATION / CHANGELOG / MANIFESTを現行Pre-RCとQA-RELEASE最終APIへ同期。E11 / RIGHTS / TARGET / SIGN確定後に再同期し、RC固定後は内容を変えない |
| ACCEPT-9CELL | RC機械Gate待ち | easy / normal / hard × 序盤 / 中盤 / 終盤を同一RCで受入 |
| DIST-ITCH | 全Launch Gate待ち | RCで固定済みの最終ZIPをupload/downloadし、hash一致、clean起動、公開判定 |

### 6-6. フェーズ進捗

| フェーズ | 状態 | 完了日 | 備考 |
|---|---|---|---|
| E1 | 完了 | 2026-07-06 | 記録更新演出、称号31件、Status称号表示、E1 smoke/証拠画像を追加 |
| E0 | 完了 | 2026-07-06 | MAX_LEVEL=50、Lv1〜10維持の2段成長式、level_curve_audit、Lv10セーブロード検証を追加 |
| E2 | 完了 | 2026-07-06 | 通常7釣り場のヌシ、条件4%抽選、初回報酬、素材14点、港ヒント、釣行気配、魚図鑑ヌシタブ/金枠、売却接続、監査/QAを追加 |
| E3 | 完了 | 2026-07-06 | 3スロットセーブ、依頼生成/納品/記録報告、依頼ボード画面、限定仕掛け、visual QAを追加 |
| E6 | 完了 | 2026-07-06 | イベント3種＋海図断片、鳥山の重み補正と演出素材、trip_event_audit、既存メッセージラベル不可視バグの修正を追加 |
| E4 | 完了 | 2026-07-06 | 危険海域、Lv/船/海図3段ロック、サメ9種+白帝、横取り抽選/演出、マップピン/サムネ、監査/visual QAを追加 |
| E10 | 完了 | 2026-07-07 | `shark_bonds`、生簀直行、餌やりEXP/なつき度、サメの売却/料理/依頼除外、サメ餌魚消費、メガロドン、素材/生簀画面、港導線、監査/QAを追加 |
| E5 | 完了 | 2026-07-08 | `selected_time_slot_id`、時間帯別出現重み、港セレクタ、港/釣行グレーディング、夜BGM override、監査/QAを追加。実装レビュー・改善提案は `docs/41_e5_time_slots_implementation_review.md` |
| SAVE-01（Release Gate 1） | 完了 | 2026-07-11 | 将来版を含むslotをmain / backup / tmp単位で非破壊guardし、タイトルで対応版を案内。`version`欠損の旧疎saveは互換維持、数値以外の`version`は未知形式としてguardする。guard中のタイトル要約は本文値を変換せず安全値を表示し、他slotの継続利用・slot切替再評価をsave smokeで確認。後続SAVE-02〜04も完了済み |
| SAVE-02（Release Gate 1） | 完了 | 2026-07-11 | `save_game()` / `reset_game()`を成否契約化し、tmp open・書込・backup rename・final rename失敗を`save_failed(message)`と共通通知へ伝播。終了時は即quitせず再試行 / 保存せず終了を選択可能にし、失敗注入とSAVE-01原本保護をsave smokeで確認。後続SAVE-03〜04も完了済み |
| SAVE-03（Release Gate 1） | 完了 | 2026-07-11 | version 1の必須なし・既知key型/範囲契約を固定し、main / backupへ同じ意味検証を適用。loadとtitle要約の候補を一致させ、意味破損mainから正常backupへのfallback、両候補不正時の通知・原本hash維持、旧疎save互換をsave smokeで確認。SAVE-04完了によりRelease Gate 1全体も完了 |
| SAVE-04（Release Gate 1） | 完了 | 2026-07-11 | load時に未知魚・サメ・ヌシ・boss依頼を除去。正常依頼の順序・条件・報酬・未知fieldを維持し、load済みのlevel / boat / 海図状態を使う現行生成規則で3件へ補充。main / backup / 3slotを回帰確認 |
| ID-01（製品識別子） | 完了 | 2026-07-11 | user data namespace=`tsuri_quest_umi`、macOS bundle ID、itch.io slug / store App IDを分離。旧MVP namespaceは新側saveが空の初回だけ非破壊コピーし、marker・tmp・hashで再開 / no-overwriteを保証。REL-01でexport成果物の回帰も完了 |
| REL-01（最小export spike） | 完了 | 2026-07-11 | `export_presets.cfg`へmacOS Universal / bundle IDを配線。Godot 4.7 stableのdebug/release成果物でclean save→再起動読込、旧MVP namespace移行、原本hash不変、不要開発素材の除外を確認。証拠は`docs/qa/evidence/release/rel_01_export_spike_2026-07-11.md` |
| QA-RELEASE（release verifier骨格） | 完了 | 2026-07-11 | 画面別input smoke 13本を含む47対象を自動列挙＋manifest完全一致で管理。セーブ2件・settings smoke 1件・export 1件の特殊runner 4件presence、process-group timeout、run固有HOME / logs、source・manifest安定性、未知WARNING拒否、fixture単位の既知警告scope、RC証跡開始終了再hashを実装。skeleton 47対象はgreen、固定RC evidenceは未入力 |
| DOCS-RELEASE（製品文書草案） | 草案完了 | 2026-07-11 | README / VALIDATION / CHANGELOG / MANIFESTを現行機能・Pre-RC境界・QA-RELEASE APIへ同期。E11 / 外部判断を反映する固定RC前の最終再同期（close）は継続 |
| E7 | 完了 | 2026-07-12 | coreを先行し、fight / UIを同commitから並列実装。core→fight→UIで統合し、difficulty audit、save回帰、title/status runtime visual QA、release verify、validateを通過 |
| E11 | 進行中 | — | SETTINGS-AUDIO、セーブ枠削除backend/UI、DISPLAY（fullscreen保存・起動時適用・keep＋黒帯の実runtime matrix QA）、INPUT-COMMON、画面別INPUT全roundを完了。入力は13画面finding 0。残りはEXTERIORと最終受入 |
| E8 | 未着手 | — | **ローンチ後**（決定#18）。docs/35 完了済み |
| E9 | 未着手 | — | **ローンチ後**（決定#18）。反応を見てから着手判断。docs/35 完了が前提 |

### 6-7. 品質トラック

V2フェーズ外。ローンチ品質のための欠陥修正・素材工事。進行状況は本docで一元管理する。

| トラック | 状態 | 位置づけ | 備考 |
|---|---|---|---|
| docs/36 サメ餌魚UX | 完了 | E4+E10 同時リリースの残作業（表示レイヤー） | フェーズ1・2実装済み（餌魚HUD・餌魚主語文言・好物ファンファーレ・見切れ修正） |
| docs/38 餌魚READYセレクタ＋耐久チャージ | 完了 | docs/36の消費タイミング不変前提を上書き | READYで餌魚選択・キャスト時消費・レア度チャージ・危険海域のみ抽選遅延・READY専用下段バーを実装。QA証拠は `docs/qa/fishing_surface_qa.md` |
| docs/39 水中ファイト基盤UI刷新 | 完了 | docs/38 の直後（決定#19の適用） | FIGHT/中間状態の下段スリムバー、右サイドバー廃止、フローティングカード、reference/14 QA証拠を追加 |
| docs/40 READY下段バー品質改善 | 完了 | docs/38の品質フォロー | 共通キット配線・専用バー化を採用。最長餌魚名P1の局所再オープン（UI-READY-01）も完了し、名前2行＋個数固定スロットをfreeze |
| docs/41〜42 E5時間帯ビジュアル仕上げ | 完了 | E5の品質フォロー | 時間帯READY/釣果素材4点、港/釣行QAまで完了 |
| docs/44 港の司令盤 | 完了 | 港UXフォロー | 採用モックv1.2を実装・freeze。docs/43の本物の天候先読みだけローンチ必須外backlog |
| docs/35 魚素材重複 P1（A群15種） | 完了 | E5/E7 と並走可（`tools/`・`fish/` のみ） | 再発防止監査は validate 組み込み済み。P1バッチ1+2で15種差し替え済み |
| docs/35 P2（B群17種）・P3 | 完了 | P1 の後。**E8/E9 前ゲート完了** | P2バッチ1+2で17種差し替え済み。P3 4種も新規source化し、監査はpending 0 / unexpected 0 / strict通過 |
| docs/33 M0（市場P1掃除） | 完了 | ローンチ品質 | 空状態の氷トレー・行残骸・未ロード風バーをruntime空状態表示へ置換。2026-07-11に被覆残像を再修正し、4状態QA・包含smoke・validateを実施 |
| docs/33 C0（調理P1掃除） | 完了 | ローンチ品質 | 残像wash・タイトル帯衝突・導線グリフ・金額formatを修正。構造契約はheadless `cooking_verify.sh`、実画像は独立 `cooking_visual_qa.sh` で検証 |
| docs/45 リリース前監査フォローアップ | 是正中 | **現在の最優先** | Release Gate 0/1・ID-01・REL-01最小export・SAVE-01〜04・UI-QUEST-01・UI-READY-01・M0・C0・QA-RELEASE骨格・DOCS-RELEASE草案・E7は完了。E11、RIGHTS / TARGET / SIGN、固定RC検証が残る。詳細briefはdocs/45 |
| docs/33 M1〜M3（魚市場素材工事） | 完了 | 品質トラック | backplate分解、市場背景、氷台、common CTA、4状態と実入力CTA 5状態の受入を完了 |
| `docs/46_quest_board_material_uplift_spec.md` / `docs/48_shark_pen_tank_uplift_spec.md` | 完了 | 品質トラック | authored木面/紙札と専用水槽背景・環境光を採用し、各screen QAをfreeze |
| docs/33 C1-A / docs/52 R5-A（調理背景・Status hero） | 完了 | 品質トラック | 厨房背景と中央釣り人portraitを採用。既存構成・ロジックは維持 |
| docs/51 C2素材準備・runtime採用 | 完了 / freeze | 調理品質トラック | MEAL_RESULT背景を正式採用。source→製品のpixel-stable processor、read-only check/self-test、旧generator guard、台帳・監査consumer、safe-area証拠を統合 |
| docs/33 C1-B / C2 runtime / C3〜C5 | C3完了 | visual後続 | C1-B/C2/C3を採用済み。C4/C5は発売外装close後の別slice |
| docs/54 UIブラッシュアップ総合計画 | 現行 | M-V3完了、次はE11-EXTERIOR | C3 EXP光背とT1 marlin詳細大絵を採用。SHIPYARD-D0は製品不変で4状態QA・未採用モックを固定。V4以降は外装close後に再開判断 |

フェーズ完了・仕様変更・横展開障害リストは本docに追記する。オーケストレーション様式は docs/26 と同じ（Fable が計画・レビュー、Composer に scoped brief で fan-out）。

## 7. 更新履歴

- 2026-07-18: `b73d275c`を共通baselineにVisual Wave V3のC3 / SHIPYARD-D0 / TACKLE-T1を独立worktreeで並行実装。C3はEXP_GAINの光背1スロット、T1はmarlin詳細sheet index 4だけを正式採用し、SHIPYARD-D0は製品runtime/asset/freezeを変えず4状態visual QAと未採用「船舶司令盤」モックを確立した。独立レビューで見つかったC3 evidenceの自己修復型check、T1非対象セルの自己参照check、船着き場reference consumerの監査漏れを補正し、再レビュー問題0まで収束。正式evidence、source→processor→product、台帳・権利監査consumerをunionしてM-V3を達成し、次を発売優先のE11-EXTERIORへ戻す。U-04/U-08、TARGET/SIGNの外部判断待ちは継続
- 2026-07-17: 共通baselineをcommit `8da6d069`へ固定し、Visual Wave V2のC2-WIRE / MAP-M1 / FIGHT-A2を3つの独立worktreeで実施。C2はMEAL_RESULT背景、FIGHT-A2はFIGHT専用下段140px操作盤を正式採用した。MAP-M1は原寸・320×180・grayscale診断でmap面積、marker/chip/lock密度、右詳細域をTop1の構成原因と確定し、製品/runtime/freezeを変更せずMAP-D0へ後続化した。各sliceは実装者と別のread-onlyレビューでP0/P1/P2/P3を0件まで収束し、親もdiff・実画像・高リスク状態を確認。C2 → MAP → FIGHTの順でmainへ統合し、正式evidence、素材台帳・監査consumerをunionした。cooking/map/fight/surface visual QA、各smoke、save、E11 harness、validate、release gateがgreenとなったためM-V2を達成。U-08 pendingを維持し、次をC3 / SHIPYARD-D0 / TACKLE-T1のVisual Wave V3へ移行する
- 2026-07-17: INPUT統合後のV0 visual baselineをcommit `6d37322b`で再固定し、Visual Wave V1のCOOK-C1B / STATUS-R5B / FIGHT-A1を3つの独立worktreeで並列実装。各sliceは実装者と別のread-onlyレビューでP0/P1/P2/P3を0件まで収束し、親もdiff・原寸/縮小evidence・高リスク状態を独立確認した。COOK → STATUS → FIGHTの順でmainへ統合し、素材台帳と監査consumerをunion。cooking/status/fight visual QA、cooking verify、save、E11 harness、validate、release verifier 47対象がgreenとなったためM-V1を達成。次をC2-WIRE / MAP-M1 / FIGHT-A2のVisual Wave V2へ移行する
- 2026-07-16: 画面別INPUT最終roundを完了。INPUT-SHARK-PENを単独worktreeで実装・独立レビューし、親のdiff・実入力・原寸証拠レビューを通過してmainへ統合。通常、last-stock、locked/empty、A→B→A、マウス/Escape一重を専用smokeへ固定し、release manifestを47対象へ更新。fresh隔離HOMEの最新baselineは13画面finding 0となり、M-INPUTを達成。次をCOOK-C1B / STATUS-R5B / FIGHT-A1の3並列へ移行する
- 2026-07-16: 画面別INPUT第4roundを完了。INPUT-STATUS / COOKING / QUEST_BOARDを独立worktreeで実装・独立レビューし、指摘修正後の再レビューと親のdiff・実入力・原寸証拠レビューを通過してmainへ統合。称号modal trap、調理5状態handoff、依頼の納品/記録報告後の即時入替を専用smokeへ固定し、release manifestを46対象へ更新。fresh隔離HOMEの最新baselineは4件（P1 3 / P2 1）で、SHARK_PEN以外の12画面は0件。次をINPUT-SHARK-PEN単独roundへ移行する
- 2026-07-16: 画面別INPUT第3roundを完了。INPUT-HARBOR / FISH_BOOK / MARKETを別セッションで実装・独立レビューし、親のdiff・実入力・原寸証拠レビューを通過してmainへ直列統合。動的時間帯lock、図鑑88操作の閉路、魚市場のmodal trap / empty復帰を専用smokeへ固定し、release manifestを43対象へ更新。`e11_qa_harness_verify.sh`、release verifier 43対象、関連visual QA / smoke / save回帰 / validateがgreen。fresh隔離HOMEの最新baselineは15件（P1 11 / P2 4）、完了済み9画面はいずれも0件。次をINPUT-STATUS / COOKING / QUEST_BOARDへ移行し、その後SHARK_PENを単独でcloseする
- 2026-07-15: 画面別INPUT第2roundを完了。INPUT-SETTINGS / FISHING_SPOTS / SHOPを別セッションで実装・独立レビューし、親のdiff・実入力・原寸証拠レビューと指摘後再レビューを通過してmainへ直列統合。専用smoke 3本を追加してrelease manifestを40対象へ更新し、settings遷移同期・釣り場fixture BGM owner境界・fixture単位の既知警告scopeも独立レビューで収束。release verifier 40対象とfresh隔離HOME probeがgreen、最新baselineは24件（P1 18 / P2 6）、完了済み6画面はいずれも0件。次をINPUT-HARBOR / FISH_BOOK / MARKETへ移行
- 2026-07-15: 画面別INPUT第1roundを完了。INPUT-TITLE / FISHING / SHIPYARDを別セッションで実装・独立レビューし、親の実入力・原寸証拠レビューと指摘後再レビューを通過してmainへ直列統合。専用smoke 3本をrelease manifestへ登録し、harness release tests=37 green、最新baselineは35件（P1 27 / P2 8）、3画面はいずれも0件。次をINPUT-SETTINGS / FISHING_SPOTS / SHOPへ移行
- 2026-07-15: E11-INPUT-COMMONを完了。実キー8 action、共通focus / cancel契約、13画面registry、self-test / baseline / strict harnessを統合。最新baselineを42件（P1 34 / P2 8）へ更新し、次をINPUT-TITLE / FISHING / SHIPYARDの3並列へ移行
- 2026-07-14: UI Wave A/Bの統合状態へ品質トラックを同期。魚市場M1〜M3、依頼ボード、水槽背景、調理C1-A、Status R5-Aを完了、C2を素材準備済み・runtime未採用として分離し、以後の順をdocs/54へ定義
- 2026-07-06: 初版。docs/archive/27_retention_expansion_plan.md・docs/archive/28_retention_expansion_implementation_specs.md を V2体系（総覧＋フェーズ別doc）へ再編。決定 #10〜#13（レベル上限50・サメ飼育E10・餌の消費制・メガロドン）を追加
- 2026-07-13: E11-DISPLAY実装に同期。fullscreen保存/復元、起動時DisplayServer適用、`stretch/aspect=keep`、1280x720/16:10/4:3の実runtime黒帯matrix QAを完了し、次タスクをINPUT-COMMONへ更新
- 2026-07-06: ローンチ耐久調査の反映。E11（ローンチ準備）新設、決定 #14〜#16（E4+E10同時リリース・ヌシ売却許容・チート対策なし）、不変条件に依頼のサメ除外、§3-4 未決4件、JSON型補正の流儀、監査共通ハーネス、docs/31 素材台帳の新設
- 2026-07-06: E1完了。記録更新演出、称号カタログ/判定、ステータス称号表示、smoke拡張、証拠画像を追加
- 2026-07-06: E0完了。レベル上限を50へ拡張し、EXP_REQUIREMENTS 51要素化、Lv10/Lv30の2段ソフトキャップ成長、level_curve_audit、Lv10セーブロード検証を追加
- 2026-07-06: E2着手。E2対象を通常7体に整理し、danger_reefの白帝はE4対象として分離。DoDにfight_envelope_audit、素材台帳、魚図鑑QA、市場売却確認を明記
- 2026-07-06: E2完了。通常7釣り場にヌシを追加し、条件成立時のみ約4%で出現、初回報酬、港ヒント、釣行気配、魚図鑑ヌシタブ/金ピン/記録行、市場売却接続、E2素材14点と監査を追加
- 2026-07-06: E3完了。セーブ3スロット化、依頼テンプレート/掲示3件/納品・記録報告、職人仕掛け、依頼ボード画面、QA証拠、smokeを追加
- 2026-07-06: E6完了。TRIP_EVENTS 3種（鳥山0.06/流木0.05/ボトルメール0.03）、`sea_chart_fragments`、`encounter_weights` の任意引数、鳥山演出素材、trip_event_audit を追加。副産物として釣行画面メッセージラベルの不可視バグ（autowrap+trim で高さ潰れ。ヌシ気配文も不可視だった）を修正
- 2026-07-06: E4完了。`danger_reef`、Lv30+船ランク3+海図3/3ロック、通常/レアサメ7種、大型サメ2種の通常抽選除外、`nushi_danger_reef`、サメ横取り抽選/フラッシュ、危険海域マップピン/サムネ/海図ロックQAを追加
- 2026-07-07: E10完了。`shark_bonds` と生簀直行、好物カタログ、餌やりによるなつき度/EXP、サメ餌魚の釣行消費、大型サメ2種/メガロドン抽選接続、メガロドン素材、生簀画面、港導線、`shark_pen_smoke` / `shark_pen_screen_smoke` / `harbor_screen_smoke` / `shark_lure_audit` / visual QA を追加
- 2026-07-07: E10フォローアップ仕様 `docs/36_shark_bait_ux_visibility_spec.md` を作成（釣行中HUDへの餌魚実名表示＋魚影カード見切れ修正。**表示のみ・E10-4消費仕様は不変**。餌魚ストック制は不採用として同docに記録）
- 2026-07-07: docs/36 にフェーズ2を追加（餌魚主語のアタリ/ヒット文言、好物発見フィードバック）。ユーザー決定: 子供の体験を第一に、餌魚とサメ出現の因果・好物システムを演出レイヤーで可視化する。抽選・消費仕様は引き続き不変
- 2026-07-07: docs/36 実装完了（フェーズ1・2）。実装後のスクショレビューとユーザー指摘（サメごとに餌魚を変えるたび港へ戻るのは面倒）を受けて `docs/37_shark_bait_in_trip_management_design_note.md` を作成し、全面採用をユーザー決定。あわせてレア度別の耐久チャージ（ユーザー提案）を採用し、実装仕様を `docs/38_shark_bait_ready_selector_spec.md` に確定（READY選択・キャスト時消費・チャージはtrip_stats管理・抽選遅延は危険海域のみ・左下パネルのセレクタ化）。決定#12を改訂
- 2026-07-07: READY UI理想イメージ `reference/13` の生成を経て、ユーザー決定「この様式をゲームプレイ画面の基盤UIデザインとする」（決定#19）。`reference/14`（FIGHT）を追加生成し、原則を `docs/19` §4.6 に明文化、水中ファイト刷新仕様を `docs/39` に確定。docs/38 §4 もREADY専用下段バーへ改訂。実装順 = docs/38 → docs/39 → E5。当時の実装入口をdocs/39 §0とした（現在の入口はdocs/45）
- 2026-07-07: 残り作業の全体ロードマップを確定（決定#18 ローンチスコープ）。順序 = docs/36 → docs/35 P1（本線と並走）→ E5 → E7 → E11＋docs/33 P1掃除 → **ローンチ** → docs/33 素材工事 → E8 → E9。E8・E9 をローンチ後アップデートへ明文化。§3-4 未決3件（販売チャネル・ゲームパッド・非16:9）の決定期限到来を注記（E11着手前必須）。「現在地」にロードマップ、§2 にローンチ境界、§6 に品質トラック表を追加。旧記述「次に着手するフェーズは E10」を更新
- 2026-07-07: docs棚卸しを実施。E10-4/docs/36/QAの仕様同期、陳腐化doc5本のarchive移動、README索引の全面改訂（状態の正本をdocs/30 §6に一本化）
- 2026-07-07: docs/38 実装完了。危険海域READYの餌魚セレクタ、キャスト時消費、レア度耐久チャージ、危険海域のみ抽選遅延、READY専用下段バー、QA証拠画像を追加。現在地を docs/39 → docs/35 P1 → E5/E7 に更新
- 2026-07-07: docs/39 実装完了。水中ファイトを基盤UI原則へ合わせ、FIGHT/CASTING/WAITING/APPROACH/BITEの下段スリムバー、右サイドバー廃止、フローティングカード、reference/14 visual QA、QA freeze改定を追加。現在地を docs/35 P1 → E5/E7 に更新
- 2026-07-08: docs/35 P1バッチ1として8種（`houbou`, `kanagashira`, `kyusen`, `kobudai`, `ojisan`, `sayori`, `binnaga`, `konoshiro`）の魚素材を新規コンタクトシート由来へ差し替え。再発防止監査は validate 組み込み済みで、通常監査は pending 26→14 / unexpected 0
- 2026-07-08: docs/35 P1バッチ2として残7種（`ira`, `kinmedai`, `akamutsu`, `medai`, `sawara`, `mahaze`, `nenbutsudai`）の魚素材を新規コンタクトシート由来へ差し替え、P1 A群15種を完了。通常監査は pending 14→8 / unexpected 0
- 2026-07-08: docs/35 P2バッチ1として9種（`meichidai`, `murasoi`, `onikasago`, `kihada`, `mebachi`, `hirasouda`, `suma`, `takabe`, `makogarei`）を新規コンタクトシート由来へ差し替え。監査pending 8→0、strict通過。P2は残8種（`shimaaji`, `gingameaji`, `kaiwari`, `ishigarei`, `umitanago`, `ishigakidai`, `oomonhata`, `ara`）を継続
- 2026-07-08: docs/35 P2バッチ2として残8種（`shimaaji`, `gingameaji`, `kaiwari`, `ishigarei`, `umitanago`, `ishigakidai`, `oomonhata`, `ara`）を新規コンタクトシート由来へ差し替え、P2 B群17種を完了。監査pending 0 / strict通過を維持し、次工程として境界4種のP3判定へ進めた
- 2026-07-08: docs/35 P3として4種（`megochi`, `kurosoi`, `takenokomebaru`, `mejina`）を新規コンタクトシート由来へ差し替え、P3暫定allowlistを削除。監査は意図的派生1件のみ、pending 0 / unexpected 0 / strict通過でdocs/35完了
- 2026-07-10: docs/41〜42のE5時間帯ビジュアル仕上げ、docs/44港の司令盤v1.2まで完了。docs/43の本物の天候先読みはローンチ必須外backlog
- 2026-07-10: 全体コード・UI・発売外周監査をdocs/45へ保存。Release Gate 0/1、セーブ保護、局所UI P1、release_verifyをE7/E11前後の実行キューへ追加
- 2026-07-11: docs/45是正キューのうちSAVE-01、UI-QUEST-01、UI-READY-01、docs/33 M0/C0を完了。この時点ではRelease Gate 0、SAVE-02〜04、E7、E11、release_verifyは継続
- 2026-07-11: Release Gate 0（決定#20）を確定。初回販売=itch.io、macOS Universal、マウス＋キーボード専用、非16:9=`keep`＋黒帯、正式名「釣りクエスト ～海釣り編～」/ v1.0.0。3種類の製品識別子と最低対象ハードウェアは後続技術判断へ分離
- 2026-07-11: SAVE-02を完了。`save_game()` / `reset_game()`の成否契約、4段階の保存失敗通知、終了時の再試行 / 保存せず終了、SAVE-01原本保護の回帰確認を追加。Release Gate 0・SAVE-01〜02は完了し、SAVE-03〜04、E7、E11、release_verifyは継続
- 2026-07-11: SAVE-03を完了。version 1の意味検証契約、main / backup共通候補選択、load / title要約の一致、意味破損fallback、両候補不正時の通知・原本hash維持を追加。Release Gate 1はSAVE-04を継続
- 2026-07-11: SAVE-04を完了。旧saveの未知魚・サメ・ヌシ・boss依頼をload時に除去し、正常依頼の内容と順序を維持したまま現行生成規則で3件へ補充。quest / shark / save回帰を通過し、Release Gate 1全体を完了
- 2026-07-11: ID-01を完了。user data namespace=`tsuri_quest_umi`、macOS bundle ID=`net.physical-balance-lab.tsuri-quest-umi`、itch.io予定slug=`tsuri-quest-umi`、store App ID=`未発行`を分離記録し、旧MVP namespaceからの非破壊・再開可能なコピー移行を追加。bundle IDのpreset配線と最小export spikeは後続
- 2026-07-11: 発売前作業を3実装レーン＋外部判断レーンのwave方式へ再編。クリティカルパス、共有ファイルの単一owner、E7分割、E11 settings spine、RC固定/検証、並列worktreeのHOME/visual QA隔離を§6へ追加
- 2026-07-11: REL-01最小export spikeを完了。macOS Universal presetとbundle IDを追加し、Godot 4.7 stableのdebug/release成果物でclean save/reload、旧MVP namespace移行、原本hash不変、不要開発素材除外を確認。署名/公証とnotice/OFL同梱はSIGN-01 / RIGHTS-01B / RC Gateで継続
- 2026-07-11: QA-RELEASE骨格を完了。scene 28件＋script-only audit 1件をmanifest完全一致で管理し、run固有隔離、source / manifest安定性、未知ERROR / WARNING拒否、RC証跡再hashを実装。clean skeleton 29件はPASSし、exportは固定RCまで`pending_rc_evidence`を維持
- 2026-07-11: DOCS-RELEASE草案を完了。README / VALIDATION / CHANGELOG / MANIFESTを現行Pre-RCとQA-RELEASE最終APIへ同期。E7 / E11 / RIGHTS / TARGET / SIGNを反映する固定RC前の最終再同期（close）は継続
- 2026-07-11: E7-coreを完了。3難易度の倍率表・公開alias、`difficulty_id`のversion 1 save互換、safe帯 / line break、売値、料理EXP、サメ餌やりEXP、料理 / 生簀のEXPプレビュー一致、difficulty auditと3slot回帰を追加。release manifestを30対象へ更新し、E7-fight / E7-UIを同commitから着手可能にした
- 2026-07-12: E7を完了。core→fight→UIの順でmainへ統合し、魚スタミナ倍率の実simulator接続、タイトル3難易度選択、使用済みslotの1回確認、SAVE-02失敗時非遷移、他2slot全artifact不変、ステータス難易度表示、title/status runtime visual QAを追加。統合後E7 Gateとrelease verifyを再実行した
- 2026-07-14: save QAの固定HOME競合を解消。`save_system_verify.sh`をrun固有・migration/save別HOMEへ変更し、wrapperの安全な親pathとscene側のactual/expected/token/symlink契約をfocused self-testで固定
