# ローンチ基盤コードレビューと長期リファクタ方針

最終更新: 2026-07-13

対象基準: `cdf14c79`（E11-DISPLAY統合直後）

位置づけ: ローンチ直前のbehavior-preserving整理と、ローンチ後も拡張を続けるための構造課題を分離した監査記録。発売進捗の正本は `docs/30_v2_expansion_overview.md` §6、UI判断の正本は `docs/19_ui_production_playbook.md` と `docs/qa/` のまま変更しない。

## 1. 結論

現行コードは、33件のrelease test discovery、セーブ破損・移行fixture、素材所有監査、画面別visual QAを持ち、ローンチ後の拡張を始められる水準にある。一方、長期運用上の最大リスクは `PlayerProgress` への責務集中である。状態、取引、save schema、候補選択、原子的I/O、namespace移行の接続が1ファイルに集まり、新しい保存フィールドの追加時に複数箇所を同期する必要がある。

今回の判断は次のとおり。

- 到達不能コード、重複helper、検証のfalse green、独立したpause不具合は今すぐ除去する。
- UIのfreeze値、ゲームバランス、画面構成、素材は動かさない。
- セーブcodec/repository分割と乱数domain分離は、公開APIを維持した小スライスへ分ける。一括書き換えはしない。
- E11のINPUT-COMMON / EXTERIORと固定RCを優先し、構造変更をRCへ無制限に持ち込まない。

## 2. リファクタ前ベースライン

2026-07-13、Godot `4.7.stable.official.5b4e0cb0f`、clean worktreeで確認した。

- docs/26記載のUI smoke 10件: 全green
- `./tools/save_system_verify.sh`: green
- `./tools/validate_project.sh`: green
- `src/**/*.gd`: 34,524行
- 既知の非阻害診断: headless終了時のObjectDB/resource cleanup、任意ObjectDB snapshot directory作成失敗、セーブ負fixtureの警告とJSON parse error

本番HOMEは使わず、全て `/tmp` 配下の隔離HOMEで実行した。

## 3. 今回完了したスライス

| ID | concern | commit | 結果 |
|---|---|---|---|
| LF-01 | 到達不能UIと未使用helper | `2521f39e` | 釣り場選択の旧completion UI、定義だけのprivate helper、対応する未使用Palette定数を削除。570行純減 |
| LF-02 | hit stopのpause所有権 | `6e8bc292` | 0秒をno-op化し、既存pauseを解除しない契約と重複呼出を専用smokeへ固定 |
| LF-03 | visual QA false green | `aed15646` | 1280x720 / mode / alpha / content / 分散を共通検査。透明・真黒・単色・誤サイズ・誤mode負fixtureとstale capture除去を追加 |
| LF-04 | 画面横断helper重複 | `8c4528bb` | テクスチャ59呼出を `ShowcaseAssets.load_texture()` へ統一。プレイ時間・金額formatも既存共通helperへ統合 |
| LF-05 | 調理フロー旧Visual | `3d353b03` | 現行PNGへ置換済みの未生成classと常時非表示fallbackだけを削除。調理freezeと5状態の見た目は維持 |
| LF-06 | visual QAレビュー追補 | `aaa674c6` | runtime生成referenceと釣具店expanded状態も共通検査へ接続。平均alpha / opaque比で半透明全面画像を拒否 |
| LF-07 | 魚catalog完全性 | `988d9ab9` | 固定件数を持たず全catalog魚からsheet / cardとファイト必須metadataを検証するrelease testを追加 |

実装後の `src/**/*.gd` は33,476行で、基準から1,048行減った。新しいJuicer smokeと魚catalog素材監査を加え、release manifest / discoveryは33 / 33で一致している。

## 4. 残る構造課題

### LR-01: 進行変更と保存結果の契約

優先度: **RC前に仕様判断**

`sell_fish`、`sell_fish_batch`、`feed_shark`、`deliver_quest`、`cook_and_eat`、購入、釣行開始、時間帯選択などはruntime状態を変更した後に `save_game()` を呼ぶが、その成否を操作結果へ含めない。現状も `save_failed` の共通通知と終了時再試行があるため、操作自体の成功と保存失敗は別経路でプレイヤーへ伝わる。ただし呼出側は「未保存の成功」を機械的に判別できない。

一括rollbackや同一操作の再実行は、売却・EXP・消費を二重適用する危険があるため採用しない。強化する場合は次の順にする。

1. `PlayerProgress` にdirty状態を持たせる。
2. 進行変更後の保存を1 helperへ集約し、結果Dictionaryへ後方互換な `persisted` を追加する。
3. 保存失敗fixtureで「runtime変更は1回だけ」「dirty=true」「後続save成功後のround-trip一致」を固定する。
4. UIは共通通知を維持し、操作を自動再実行しない。

### LR-02: `PlayerProgress` のschema / repository分離

優先度: **ローンチ後の最初の構造スライス**

`player_progress.gd` は1,700行超で、save fieldが宣言、reset、encode、validation、applyの複数箇所へ分散している。次の2段階だけを許可する。

1. pure `PlayerSaveCodecV1`: defaults、known keys、encode、validate、decodeを抽出する。全field round-tripと正常疎save / 破損fixtureを先に追加する。
2. `SaveRepository`: main / backup候補選択と原子的I/Oを抽出する。`PlayerProgress` の公開API、signal、autoload名は維持する。

namespace移行は既に独立しているため、この分割と同時に再設計しない。

### LR-03: 乱数streamのdomain分離

優先度: **E8 / E9着手前**

`GameData` の単一RNGを天候、依頼、釣行イベント、魚抽選、サイズ抽選が共有している。あるdomainの乱数呼出追加が別domainの再現系列を変える。カタログfaçadeは維持し、Quest / Encounter / TripEventへRNG注入またはdomain別streamを導入する。seed固定で各domainの独立性を検証する。

### LR-04: 二重起動時のsave競合

優先度: **P2調査**

namespace migratorはlockを持つが、通常のslot save / deleteはプロセス間lockを持たず共通tmp名を使う。初回販売はmacOSのシングルプレイヤーであり通常利用の再現は未確認だが、二重起動ではlost updateの可能性がある。先に2プロセスbarrier fixtureで再現性を確認し、必要ならslot単位lockまたは世代hash競合検知を追加する。

### LR-05: release meta-testの一括入口

優先度: **固定RC前**

`release_verify` 本体のself-test、E11 probe harness、settings isolation self-testは個別に存在するが、通常のrelease verify 1コマンドへ全ては接続されていない。固定RC前にpreflightとして直列実行し、runner自身のfalse greenを防ぐ。

### LR-06: QA shell runtimeの共通化

優先度: **P2保守性**

Godot解決とHOME隔離が多数のshell wrapperに重複し、`GODOT_BIN` 対応や安全強度がばらつく。`tools/lib/qa_runtime.sh` へ解決・隔離だけを抽出し、画面固有capture手順は各wrapperへ残す。macOS実画面capture依存の処理はheadless helperへ混ぜない。

### LR-07: BGM playerの二重実装

優先度: **P2保守性**

`Main` のapp BGMと `ScreenBase` のpreview fallback BGMは、load、MP3 loop、player生成、終了処理が重複する。preview単体起動を維持する必要があるためfallback自体は削除せず、E11完了後にlooping player生成のpure helperだけを共有する。

### LR-08: pause所有権の調停

優先度: **pause menu / modal pause導入前の必須Gate**

現行runtimeで `SceneTree.paused` を操作するのは `Juicer` のhit stopだけであり、今回の修正で「既にpauseされている状態を解除しない」「重複hit stopは最長期限まで保持する」契約をsmokeへ固定した。ただしboolean 1つでは、hit stop開始後に別systemがpauseを要求した所有権を区別できない。現時点では第二のpause利用者がなくproduction退行経路はないため、RCへ未使用の大規模arbiterは入れない。

pause menu、modal pause、cutscene pauseのいずれかを追加する前に、token / reason-count型のpause arbiterを導入する。各requesterは自分のtokenだけをreleaseし、全token消滅時だけ `SceneTree.paused = false` に戻す。Juicerと新requesterの取得順を入れ替えたsmokeを同じコミットへ含める。

## 5. 実施順

### 固定RC前

1. E11 INPUT-COMMON → EXTERIOR → 最終受入を完了する。
2. LR-01を「現行の共通通知＋終了時再試行でclose」か「dirty / persisted契約を追加」に決定する。
3. LR-05のrelease preflightを1コマンドへ接続する。
4. clean worktreeから固定RCを作り、release verifier、性能 / soak、3難易度通し確認を行う。

### ローンチ直後

1. LR-02をcodec、repositoryの順に実施する。
2. LR-04の二重起動fixtureで必要性を確定する。
3. LR-06、LR-07を独立コミットで進める。

### pause機能追加前

1. LR-08のpause arbiterを導入し、Juicerと第二requesterの所有権を順序違いで検証する。

### E8 / E9前

1. LR-03のdomain別RNGを導入する。
2. 新魚・新エリア追加時にsave field round-trip、素材所有、release discoveryを同じGateで確認する。

## 6. 不変条件

- `PlayerProgress` のautoload名、公開API、signalを破壊しない。
- save field追加はcodecのround-trip fixtureと同じコミットにする。
- UI共通化と画面upliftを同一コミットへ混ぜない。
- `docs/qa/*_qa.md` のfreeze値は、docs/19の再オープン条件なしに動かさない。
- visual QAは実captureを共通validatorへ通し、ファイル存在だけでgreenにしない。
- 大規模分割は「行数を減らすため」ではなく、テスト可能なpure境界が先に定義できた場合だけ行う。
