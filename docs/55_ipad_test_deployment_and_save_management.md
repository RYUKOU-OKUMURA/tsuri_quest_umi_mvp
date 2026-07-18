# iPad実機テスト導入・セーブデータ運用仕様

最終更新: 2026-07-18

状態: **初回実機導入spike進行中（install済み・初回の署名信頼待ち）**

対象: Godot 4.7 / iPad実機への開発ビルド導入 / version 1セーブ / 将来クラウド方針

## 0. この文書の位置づけ

この文書は、現在のセーブデータの内容、iPadへゲームのテスト版を入れる手順、更新時のセーブ維持確認、端末故障・アプリ削除時の扱い、将来のクラウドセーブ方針をまとめた運用の正本である。

- iPadへ入れるのは **Godotエディタではなく、GodotからiOS向けにexportした本ゲームのアプリ**
- 初回販売対象は引き続き itch.io / macOS Universal。iPad実機テストはローンチを止めない技術spike
- iPad正式対応を確定する文書ではない。タッチ操作、4:3表示、性能、配布、審査は実機検証後に別途判断する
- version 1セーブの全key・型・範囲・復旧処理の実装正本は `src/autoload/player_progress.gd`。`docs/30_v2_expansion_overview.md` §4-1はV2追加項目と意味検証方針の正本であり、ここでは両者を運用に必要な形へ要約する

## 1. 結論

### 1-1. 現在地

| 質問 | 現在の回答 |
|---|---|
| iPadへテスト導入できるか | **可能**。Personal Team署名のdebug buildを実機へinstall済み。初回のデベロッパ信頼後に起動確認する |
| 今すぐ入れて通常プレイできるか | **通常プレイは未確認**。export / build / installまでは完了し、タイトル起動・実機入力QAが未完 |
| Apple Developer Program加入は必須か | 所有するiPadへの個人テストだけならApple AccountのPersonal Teamでも可能。TestFlight配布、iCloud機能、正式配布には加入が必要 |
| ゲーム更新のたびにUSB接続が必要か | 初回の接続・信頼・ペアリングは必要。無線接続を有効化できれば、以後は同一ネットワーク上でXcodeから更新可能。ただし再export / build / installは必要 |
| 更新するとセーブは消えるか | 同じBundle IDかつ互換なTeam / App ID / 署名identityのアプリを、削除せず上書きする場合は維持される想定。配布境界ごとの更新回帰が通るまで保証扱いしない |
| MacとiPad、複数iPadでセーブは共有されるか | **現状は共有されない**。各端末のアプリ専用領域へローカル保存される |
| クラウドセーブはあるか | **未実装**。iCloud Backupは端末バックアップであり、ゲーム内のリアルタイム同期ではない |

### 1-2. 2026-07-18時点の準備状況

| 項目 | 状態 | 次の対応 |
|---|---|---|
| Godot | 4.7導入済み | 維持 |
| renderer | desktop / mobileとも`gl_compatibility` | 実機描画を確認 |
| 表示 | 1280×720、`canvas_items`、`keep` | iPad 4:3では黒帯前提で実機確認 |
| 画面向き | `window/handheld/orientation=0`でlandscapeを明示 | 端末回転・復帰後の挙動を確認 |
| Xcode | 26.6、iOS 26.5 platform component導入済み | 維持 |
| active developer directory | `/Applications/Xcode.app/Contents/Developer` | 維持 |
| Godot export template | Godot 4.7と同版のiOS / macOS template導入済み | Godot更新時は同版へ揃える |
| `export_presets.cfg` | `iOS iPad Debug` preset追加済み | 正式Team移行時に署名境界を再確認 |
| iOS署名 | Personal TeamのApple Development証明書とmanaged profileでbuild成功 | 7日失効を前提にテスト運用 |
| iOS Bundle ID | spike用に`net.physical-balance-lab.tsuri-quest-umi`を採用 | 正式Team移行前に最終freeze |
| iPad接続 | USB接続、信頼、Developer Mode、pairing、install完了 | 初回のみデベロッパAppを端末側で信頼 |
| タッチ入力 | Godot既定のtouch→mouse変換は有効だが、正式対応外・実機QA未実施 | §7でtap / drag / holdと、外付けキーボードなしで到達不能な導線がないことを確認 |
| iPad save fixture harness | 未実装 | 通常アプリのcontainerを触らないtest専用debug harnessを用意 |
| クラウド同期 | 未実装 | 当面はlocal-first |

したがって、iOS export / build / installの最小spikeは通過した。次は**タイトル起動を確認し、入力とセーブ更新回帰を同じ実機で確認すること**である。

## 2. 現行セーブの保存場所と構成

### 2-1. 保存場所

進行データと設定はGodotの`user://`へ保存する。プロジェクトでは次のnamespaceを固定済みである。

```text
config/use_custom_user_dir = true
config/custom_user_dir_name = "tsuri_quest_umi"
```

macOS上の実体は `~/Library/Application Support/tsuri_quest_umi/`。iPadではアプリ固有の非公開コンテナ内に置かれ、通常は他アプリや「ファイル」アプリから直接操作できない。`user://`は端末ごとに別物であり、同じnamespace名だけでMacとiPadが同期されることはない。

### 2-2. ファイル構成

```text
user://
├── settings.json
└── slots/
    ├── 1/
    │   ├── tsuri_quest_save.json
    │   ├── tsuri_quest_save.json.bak
    │   └── tsuri_quest_save.json.tmp
    ├── 2/
    │   └── ...
    └── 3/
        └── ...
```

| artifact | 役割 | 通常時の扱い |
|---|---|---|
| `tsuri_quest_save.json` | 現在の進行データ | 読込の第1候補 |
| `.bak` | 直前の正常な本体1世代 | mainが破損・不正なら読込候補 |
| `.tmp` | 原子的差し替え用の一時ファイル | 同期・手動復元の対象にしない |
| `settings.json` | BGM / SE / fullscreen設定 | 進行3スロットとは分離。進行削除で消さない |

### 2-3. 保存・復旧の契約

進行セーブは次の順で安全に差し替える。

1. runtime dataをversion 1契約で意味検証する。
2. `.tmp`へJSON全体を書き切る。
3. 正常な既存mainを`.bak`へ移す。
4. `.tmp`をmainへrenameする。
5. 途中失敗時は`.tmp`を除去し、必要なら`.bak`からmainを復元する。

読込はmainを先に検証し、不正ならbackupへfallbackする。両方にartifactがあるのにどちらも不正なら、原本を変更せずロードと上書き保存を止める。`version > 1`または不明versionも、そのスロットだけ非破壊guardし、他の2スロットは利用できる。

`settings.json`は進行セーブほどの原子的書込・backupを持たない。破損や型不正時はBGM 80%、SE 80%、fullscreen offへ戻るため、将来クラウド同期の対象にはしない。

## 3. version 1セーブの内容

JSONは平文であり、秘密情報・認証情報・個人情報を格納しない。現行方針ではチート耐性や暗号化をローンチ要件にしない。

| key | 型 / 既定値 | 内容 |
|---|---|---|
| `version` | int / `1` | セーブschema版 |
| `level` | int / `1` | プレイヤーレベル |
| `exp` | int / `0` | 現在EXP |
| `money` | int / `500` | 所持金 |
| `inventory` | Dictionary / `{}` | fish_id → 所持数 |
| `caught_counts` | Dictionary / `{}` | fish_id → 累計捕獲数 |
| `spot_caught_counts` | Dictionary / `{}` | spot_id → fish_id → 捕獲数 |
| `best_sizes` | Dictionary / `{}` | fish_id → 最大サイズcm |
| `eaten_recipes` | Dictionary / `{}` | `fish_id:recipe_id`相当の記録 → 食事回数 |
| `owned_rods` | Array[String] / `["starter"]` | 所有ロッドID |
| `equipped_rod_id` | String / `"starter"` | 装備中ロッドID |
| `owned_rigs` | Array[String] / default rig | 所有仕掛けID |
| `equipped_rig_id` | String / default rig | 装備中仕掛けID |
| `owned_boats` | Array[String] / `[]` | 所有船ID |
| `pending_buff` | Dictionary / `{}` | 次の釣行に使う料理buff。recipe / name / stat / value / text |
| `play_seconds` | float / `0.0` | 累計プレイ秒数 |
| `quest_board` | Array[Dictionary] / `[]` | 掲示中依頼、最大3件 |
| `quest_completed_count` | int / `0` | 依頼達成累計 |
| `sea_chart_fragments` | int / `0` | 海図断片、0〜3 |
| `shark_bonds` | Dictionary / `{}` | shark_id → なつき度。ロード時0〜100へ補正 |
| `selected_time_slot_id` | String / daytime | 最後に選択した時間帯ID |
| `difficulty_id` | String / `"normal"` | 選択難易度ID |

`quest_board`の各依頼には、種類に応じて`template_id`、`kind`、`fish_id`、`count`、`target_size_cm`、`posted_best_cm`、`reward_money`、`text`、`recipe_id`などを含む。未知・無効な魚、サメ、ヌシ、依頼はロード時に修復し、最大3件へ補充する。

次は保存せず、保存済み統計から毎回導出する。

- 称号
- ヌシ捕獲フラグ
- 記録更新歴
- サメ捕獲状態
- メガロドン解放可否
- active slot番号そのもの

設定ファイルは別schemaである。

| key | 型 / 既定値 | 内容 |
|---|---|---|
| `version` | int / `1` | 設定schema版 |
| `bgm_volume` | int / `80` | 0〜100 |
| `se_volume` | int / `80` | 0〜100 |
| `fullscreen` | bool / `false` | 画面モード。iPadでは端末固有設定として扱う |

## 4. iPad上でのデータ寿命

| 操作 / 状況 | 進行データ | 運用判断 |
|---|---|---|
| 同じTeam / App ID / Bundle IDで上書き更新 | 維持される想定 | §7のA→B回帰が通るまで保証扱いしない |
| Xcodeから同じidentityのアプリを再build / install | 維持される想定 | アプリを先に削除しない |
| Bundle IDを変更してinstall | 別アプリ・別コンテナ扱い | 既存セーブを自動継承しない。最初の実セーブ前にIDをfreeze |
| 「Appを取り除く」/ Offload | documents and dataは保持される | 再install後の読込をspikeで確認 |
| 「Appを削除」/ Delete App | アプリと関連データを削除 | **テストセーブも失われる**。クラウド未実装中は復元を約束しない |
| iPad故障・紛失 | 端末内データへアクセス不能 | iCloud / Finder backupから端末復元できる可能性はあるが、ゲーム内同期ではない |
| iCloud Backup | 対象ならapp dataの定期snapshot | 複数端末の最新進行共有や競合解決には使わない |
| 別のiPadで起動 | 新規ローカルセーブ | クラウド実装までは自動共有しない |
| Mac版とiPad版 | 各端末に独立 | 手動コピー機能も現状なし |
| Personal Team profile期限 | アプリが起動できなくなることがある | 再build / 再installが必要。データ維持も実機で確認 |

Personal Teamは個人所有端末での試験用で、現行Apple案内ではApp ID、端末、アプリ数に制限があり、provisioning profileは7日で失効する。長期テスト、TestFlight、iCloud capability、正式配布はApple Developer Program加入後に行う。

## 5. 初回のiPad実機導入手順

### 5-1. 事前条件

- Mac、Godot 4.7、Xcode、iPad、接続ケーブル
- XcodeにサインインするApple Account
- iPadとMacの空き容量、同一ネットワーク
- 消えてもよい専用のテストセーブ
- Godot 4.7と**完全に同じ版**のiOS export template
- iOS Bundle ID。候補はmacOSと揃えた `net.physical-balance-lab.tsuri-quest-umi`

Bundle ID候補はApple側で登録可能か確認してから採用する。Personal Teamで始める最初のspikeは**捨てセーブ限定**とし、Apple Developer Program加入後に正式Team / App ID / Bundle IDの組をfreezeする。同じBundle ID文字列でもTeamやApp IDが変われば連続性を保証せず、§6-2の境界ごとに更新回帰を行う。identity変更が必要になった場合は別アプリ移行として扱い、旧データが残る前提にしない。

### 5-2. Mac / Xcodeの準備

1. Xcodeを一度起動し、licenseと必要componentの導入を完了する。
2. Xcode > Settings > AccountsでApple Accountへサインインする。
3. developer directoryを確認する。

```bash
xcode-select -p
```

4. `/Library/Developer/CommandLineTools`を指している場合はXcode本体へ切り替える。

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
xcodebuild -version
```

5. Godotの Editor > Manage Export Templates から、4.7と同版のiOS templateを導入する。macOS templateだけではiOS exportできない。

### 5-3. GodotのiOS preset

1. Project > Project Settings > Display > Window > Handheld > Orientationを`landscape`へ明示する。これはiOS presetではなく`project.godot`の設定である。
2. Project > Exportを開く。
3. Add... > iOSを選ぶ。
4. 最低限、次を設定する。

| 設定 | 値 / 方針 |
|---|---|
| App Store Team ID | Xcode / Apple Developerで表示されるTeam ID。表示名ではなく英数字のID |
| Bundle Identifier | freezeしたiOS Bundle ID |
| Name | `tsuri_quest_umi`。正式外装close時に同期 |
| Version | テストbuildを識別できる値 |
| Export filter | macOS presetと同様、`reference/`と`tools/`を成果物から除外 |

5. 最初はdebug用Xcode projectをexportする。Pathには空の `build/ios/tsuri_quest_umi/`、Fileには空白を含まない `tsuri_quest_umi` を指定する。
6. 生成された`.xcodeproj`をXcodeで開く。

Team IDとBundle IDは識別子であり認証secretではないため、再現可能なpresetへ記録できる。一方、Apple Accountの認証情報、証明書のprivate key / password、App Store Connect API private key、端末UDID、provisioning profile本体はcommitしない。

### 5-4. XcodeとiPad

1. iPadをケーブルでMacへ接続する。
2. iPad側の「このコンピュータを信頼」を許可する。
3. 必要ならiPadの「設定 > プライバシーとセキュリティ > Developer Mode」を有効化し、再起動後に確認する。
4. XcodeのSigning & CapabilitiesでTeamを選び、Automatically manage signingを有効にする。
5. Xcode上部のrun destinationで接続中のiPadを選ぶ。
6. Build & Runする。
7. iPadのホーム画面に本ゲームが現れ、タイトルまで起動することを確認する。

署名エラー時は、Team、Bundle IDの重複、iPad登録、profile、Developer Mode、`xcode-select -p`を順に確認する。

### 5-5. 初回導入後に無線更新を有効化する

1. 初回の有線接続とpairingを完了する。
2. XcodeのDevices / Device HubでiPadを選び、ネットワーク接続を有効化する。
3. MacとiPadを同じネットワークへ置く。
4. ケーブルを外した状態でrun destinationにiPadが表示されることを確認する。

以後も更新そのものは自動ではない。Godot側の変更を含むbuildは再exportし、Xcodeからbuild / installする。Godot公式のproject folder link方式を採用すれば、開発中の毎回のexportを減らせるが、最初のspikeでは通常exportを正として手順を固定する。

## 6. 更新手順

### 6-1. Xcode直入れ

1. 変更をcommitし、`./tools/validate_project.sh`と関連smokeを通す。
2. build番号を上げる。
3. 同じiOS preset、Team、Bundle IDでGodotから再exportする。
4. Xcodeで同じiPadへBuild & Runする。無線pairingが有効なら通常はケーブル不要。
5. アプリを削除せず上書きする。
6. §7の短縮回帰で、既存スロット、設定、主要操作を確認する。

コード更新のたびにiPadを「繋ぎ直す」必要はないが、次の場合は再接続が必要になり得る。

- pairingが切れた
- Developer Modeや信頼設定をやり直した
- Personal Teamのprofileが失効した
- Xcode / iPadOS更新後にdevice supportを再設定した
- 無線接続でiPadを検出できない

### 6-2. 署名・配布境界とTestFlight

毎回Xcodeから入れる段階を終え、複数人・複数端末へ配るときにTestFlightへ移る。前提はApple Developer Program加入、App Store Connectのapp record、正式Bundle ID、署名、archive / upload、テスター設定である。TestFlight buildは現在のApple仕様では最大90日テストできる。

セーブ連続性は次の境界を別々に検証する。同じBundle ID文字列だけを合格根拠にしない。

| 境界 | 扱い |
|---|---|
| 同じTeam / App ID / Bundle IDのXcode build A→B | 最初の更新回帰。通過後に同系統build内の継続利用を許可 |
| Personal Team→加入済み正式Team | 初期spikeの捨てセーブで試験。失敗時は移行機能なしの新規開始として扱う |
| 正式TeamのXcode直入れ→TestFlight | 同じApp ID / Bundle IDでも別途A→B回帰を行う |
| TestFlight→App Store | release candidateで別途回帰し、通過後だけ継続性を案内 |

TestFlightへ移ってもクラウドセーブにはならない。データ共有には別途iCloud / GameKit / GameSave / CloudKitなどの実装が必要である。

## 7. 最初の実機spikeのQA

### 7-1. 合格条件

| ID | テスト | 合格条件 |
|---|---|---|
| IPAD-INSTALL-01 | clean install | タイトル起動、未説明ERROR / crash 0 |
| IPAD-SAVE-01 | 3スロット | 3枠を別内容で作成し、終了・再起動後も要約と実内容が一致 |
| IPAD-SAVE-02 | A→B上書き更新 | 同じTeam / App ID / Bundle IDでアプリを削除せず更新し、3枠と設定が維持 |
| IPAD-SAVE-03 | backup fallback | 事前にtest専用debug harnessを実装し、不正mainから正常backupを採用して原本保護。通常アプリのcontainerは直接編集しない |
| IPAD-SAVE-04 | background / force quit | 通常保存後のbackground、復帰、force quit、再起動で破損なし |
| IPAD-SAVE-05 | offline | 通信なしでも起動・ロード・保存可能 |
| IPAD-SAVE-06 | Offload | Appを取り除く→再installで進行を維持 |
| IPAD-SAVE-07 | Delete App | **捨てセーブだけ**で削除→再installし、新規状態になることを確認 |
| IPAD-ID-01 | app identity固定 | A / B buildで同じTeam / App ID / Bundle ID。異なるidentityを通常更新として扱っていない |
| IPAD-INPUT-01 | 全13画面の主導線 | タップで全主要導線が閉路になり、行き止まり0 |
| IPAD-INPUT-02 | 水中ファイト | 押下・長押し・離すが一重発火し、押しっぱなし状態が残らない |
| IPAD-INPUT-03 | 画面向き | landscapeで固定され、端末回転・復帰後に入力座標ずれ0 |
| IPAD-VIEW-01 | 4:3表示 | keep＋黒帯で欠け、誤タップ、文字切れ、modal外押下漏れ0 |
| IPAD-PERF-01 | 代表状態 | 水中ファイト、魚図鑑、調理、サメ生簀でcrash / 致命的入力遅延0 |

`IPAD-SAVE-07`は破壊テストである。対象iPad、対象アプリ、Bundle IDを確認し、**全3slot、settings、その他の関連データがすべて破棄可能**であることを画面とXcodeで再確認する。価値のあるテストデータには実施しない。

### 7-2. A→B更新回帰の具体例

1. build Aをclean installする。
2. slot 1をLv / 所持金 / プレイ時間が分かる状態まで進める。
3. slot 2、3にも別の難易度と進行を保存する。
4. BGM / SEを既定値以外へ変更する。
5. 3枠のタイトル要約をスクリーンショットへ残す。
6. build Bを**アプリ削除なし、同じTeam / App ID / Bundle ID**で上書きする。
7. タイトル要約、各slotのロード内容、設定を照合する。
8. build Bでさらに進行して保存し、再起動後に読む。

証拠を保存する場合は `docs/qa/evidence/release/ipad/` を作り、端末機種、iPadOS、Godot、Xcode、source commit、Team種別（Personal / 正式。ID値は不要）、App ID / Bundle ID、build A/B、実施者、結果を同じ記録へ残す。Apple Accountの認証情報、署名鍵、端末UDID、provisioning profileは画像やログへ残さない。

## 8. 当面の運用

- iPad実機spikeは必ず消えてもよいテストセーブで始める
- source commit、build番号、Bundle ID、iPad機種 / iPadOSを記録する
- 更新時はアプリを先に削除しない
- Bundle IDを変更しない
- 価値が出たテストセーブは、クラウド実装前は「端末backupがあるか」を別途確認する
- `iCloud Backupがある`ことを`クラウドセーブ対応`とは表記しない
- save JSONを手で編集して本番相当データへ戻さない。fixture操作は専用テスト環境だけで行う
- 保存契約を変更したら `./tools/save_system_verify.sh` と `./tools/validate_project.sh` を必ず実行する

## 9. 将来のクラウドセーブ方針

### 9-1. 推奨ロードマップ

| 段階 | 方針 |
|---|---|
| 現在〜iPad単体spike | local-first。現行3slotをそのまま使い、クラウドなしで遊べることを維持 |
| iPad正式対応の判断時 | AppleのGameKit saved games / GameSave / CloudKitを比較する技術spike |
| Steam版の判断時 | Steam Cloudを追加。端末固有settingsを除外 |
| iPad↔Steamの横断同期が必要になった時 | Apple / Steam個別cloudでは足りないため、自前account / backendを検討 |

最初から自前backendを持つ必要はない。まず端末内セーブを正とし、Apple端末間またはSteam端末間の需要が確定した時点で各platform cloudを追加する。

Appleのnative game-save APIを採用する場合、Godotから呼ぶiOS pluginまたはnative bridgeの実装・保守も見積もる。API機能だけでなく、Godot 4.7との接続方法、offline、競合、TestFlight二端末回帰までを同じ技術spikeに含める。

### 9-2. 同期するもの / しないもの

raw fileをそのまま全部同期せず、各slotでmain / backupの候補選択を通過した**正規payload**をcloud envelopeへ格納する。

同期対象:

- slot 1〜3の検証済み正規payload
- `save_version`
- slot ID
- cloud revision / 更新時刻
- install識別用のランダムな匿名ID（hardware ID / UDIDは使わない）
- payload checksum
- 削除を伝播するtombstone

同期しないもの:

- `.tmp`
- 端末内の`.bak`
- `settings.json`
- logs、QA fixture、migration lock / marker
- Apple Account、Steam tokenなどの認証情報

backupは端末内の原子的保存を守るローカル世代であり、cloud側では別のrevision historyとして設計する。同じ`.bak`を複数端末で同期すると、正常な世代を別端末の古いbackupで上書きする危険がある。

### 9-3. 競合と失敗時の原則

- オフラインでも起動・ロード・保存を止めない
- 起動時download、save後uploadを基本とし、通信失敗はローカル成功を取り消さない
- cloud payloadもversion 1意味検証を通してから採用する
- future / unknown versionを古い端末で上書きしない
- ローカルとcloudの両方が進んでいる場合は自動上書きせず、slot番号、Lv、プレイ時間、更新時刻、端末名を示して選ばせる
- 端末時刻だけを唯一の正としない。cloud revisionと競合履歴を持つ
- 削除は「ファイルがない」だけで表さずtombstoneを使い、古い端末から復活させない
- 復元・競合解決の前後で旧payloadを保持し、失敗時に原本を壊さない

## 10. 参照

### リポジトリ内

- `src/autoload/player_progress.gd` — 3slot、save / load、backup、意味検証、migration
- `src/ui/settings_screen.gd` — `settings.json`
- `project.godot` — namespace、1280×720、keep、renderer
- `export_presets.cfg` — macOS UniversalとiOS iPad Debugのexport設定
- `docs/30_v2_expansion_overview.md` §3-5 / §4-1 — IDとV2追加save項目・意味検証方針の正本
- `docs/v2/E11_launch_readiness.md` §E11-6 — モバイル正式対応のスコープ判断

### 公式資料

- [Godot: Exporting for iOS](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html)
- [Godot: File paths / `user://`](https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html)
- [Apple: Running apps on physical devices](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices)
- [Apple: Enabling Developer Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device)
- [Apple: Developer account / Personal Team](https://developer.apple.com/help/account/basics/about-your-developer-account)
- [Apple: TestFlight overview](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/)
- [Apple: OffloadとDeleteの違い](https://support.apple.com/en-au/108429)
- [Apple: iCloud Backupに含まれるもの](https://support.apple.com/en-us/108770)
- [Apple: GameKit saved games](https://developer.apple.com/documentation/gamekit/saving-the-player-s-game-data-to-an-icloud-account)
- [Apple: GameSave](https://developer.apple.com/documentation/gamesave)
- [Apple: CloudKit](https://developer.apple.com/documentation/cloudkit)
- [Steamworks: Steam Cloud](https://partner.steamgames.com/doc/features/cloud)
