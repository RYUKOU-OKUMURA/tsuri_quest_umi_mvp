# iPad実機導入spike 実行レポート

実施日: 2026-07-18

状態: **export / build / install / launch / プロセス継続まで完了**

対象: Godot 4.7 / Xcode 26.6 / Personal Team / iPad実機debug build

関連仕様: `docs/55_ipad_test_deployment_and_save_management.md`

## 0. このレポートの目的

この文書は、初回のiPad実機導入で実際に行った作業、詰まった点、原因、解決策、次回の短縮手順を残す実行記録である。セーブや署名境界などの運用ルールは`docs/55`を正本とし、本書は再実行時のrunbookとして使う。

このレポートには次を記録しない。

- Apple Accountのメールアドレス、password、二要素認証情報
- 証明書のprivate key、password、fingerprint
- 端末UDID、serial、provisioning profile UUID
- App Store Connect API keyなどのsecret

Team IDとBundle IDは認証secretではなく、再現可能な設定の識別子として`export_presets.cfg`に保存する。

## 1. 最終結果

| 項目 | 結果 |
|---|---|
| Godot iOS export | 成功。`iOS iPad Debug` presetからXcode projectを生成 |
| Xcode build | 成功。Debug / arm64 / 実機destination / automatic signing |
| 実機install | 成功 |
| 初回launch | 端末側でデベロッパAppを信頼後に成功 |
| 起動後確認 | `devicectl`で対象プロセスが継続していることを確認 |
| プロジェクト検証 | `./tools/validate_project.sh` exit 0 |
| タイトル目視 | 未実施。`devicectl`では判定できないため端末側で目視確認する |
| 入力・表示・セーブQA | 未完。`docs/55` §7を継続する |

今回の実機環境はiPad Air（第3世代）/ iPadOS 26.5.2。source設定の導入commitは`9cde8e2`、起動結果の記録commitは`c9b0b7c`。

## 2. 今回追加・変更した正本

| ファイル | 役割 |
|---|---|
| `export_presets.cfg` | iOS debug export、Team、Bundle ID、arm64、minimum iOS、project-only export |
| `project.godot` | landscape明示、iOS向けETC2 / ASTC texture import |
| `.gitignore` | `build/`配下の生成物をGit対象外にする |
| `build/.gdignore` | Xcode / iOS生成物をGodot resource scan対象外にする |
| `docs/55_ipad_test_deployment_and_save_management.md` | iPad導入・署名境界・セーブ運用の正本 |
| 本書 | 実行履歴、トラブルシュート、次回runbook |

`build/ios/`以下のXcode project、DerivedData、`.app`は生成物でありcommitしない。再exportで上書きされるため、生成された`.pbxproj`を設定の正本にしない。

## 3. 初回準備で行ったこと

### 3-1. Xcodeとdeveloper directory

Xcode 26.6はインストール済みだったが、最初はactive developer directoryがCommand Line Toolsを指していた。iOS SDKと実機buildを使うため、Xcode本体へ切り替えた。

確認:

```bash
xcode-select -p
xcodebuild -version
```

期待値:

```text
/Applications/Xcode.app/Contents/Developer
```

異なる場合:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

### 3-2. XcodeのiOS platform component

Xcode本体だけでは対象iOS platform componentが揃っておらず、最初の実機build準備を進められなかった。次で公式componentを導入した。

```bash
xcodebuild -downloadPlatform iOS
```

今回のdownloadは約8.5 GBだった。容量と所要時間はXcode版により変わる。次回はXcode / iPadOSの更新後だけ確認すればよい。

### 3-3. XcodeへのApple Accountログイン

ログインする場所はiPadではなくMac側のXcodeである。

```text
Xcode > Settings > Accounts
```

所有iPadへの個人テストはPersonal Teamで実施した。TestFlight、正式配布、iCloud capabilityはApple Developer Program加入後に扱う。

### 3-4. Godot 4.7 export template

Godot本体は4.7だったが、iOS export templateが未導入だった。Godot本体と**完全に同じ4.7 stable版**の公式template packageを取得し、checksumを配布元のdigestと照合してから導入した。

導入後に存在すべき主なファイル:

```text
~/Library/Application Support/Godot/export_templates/4.7.stable/ios.zip
~/Library/Application Support/Godot/export_templates/4.7.stable/macos.zip
~/Library/Application Support/Godot/export_templates/4.7.stable/version.txt
```

次回、Godot 4.7を継続する限り再導入は不要。Godotを更新した場合は、同じ版のtemplateへ揃える。

### 3-5. iPad側の準備

初回だけ次を行った。

1. iPadをMacへUSB接続する。
2. iPad側で「このコンピュータを信頼」を許可する。
3. 「設定 > プライバシーとセキュリティ > デベロッパモード」を有効化する。
4. 指示に従って再起動し、デベロッパモードを確定する。
5. Xcode Device Hubでpaired / Developer Mode有効を確認する。

Developer Modeを有効にしただけではPersonal Teamアプリの初回launch許可は完了しない。install後に§6-6のデベロッパApp信頼も必要だった。

### 3-6. Apple Development証明書とmanaged provisioning

XcodeのAccounts画面ではmanual certificate作成操作が利用できなかった。生成済みXcode projectのSigning & CapabilitiesでPersonal Teamを選び、Automatically manage signingを使うことで、XcodeにApple Development証明書とprovisioning profileを作成させた。

今回有効だった順序:

1. `export_presets.cfg`へTeam IDとBundle IDを設定する。
2. GodotからXcode projectを生成する。
3. Xcodeでprojectを開く。
4. Target > Signing & CapabilitiesでPersonal Teamを選ぶ。
5. Automatically manage signingを有効にする。
6. Xcodeが証明書とprofileを用意した後、command line buildを再実行する。

以後はTeam IDがpresetにあるため、GodotでXcode projectを再生成しても署名設定を復元できる。生成projectだけを手修正すると、次回exportで消える。

## 4. 初回に詰まった点と解決策

| 症状 | 原因 | 解決策 | 次回の予防 |
|---|---|---|---|
| iOS export項目が使えない | Godot 4.7 iOS template未導入 | 同じ4.7 stable版templateを導入 | §5のtemplate存在確認を最初に行う |
| 実機platformを準備できない | XcodeのiOS component不足 | `xcodebuild -downloadPlatform iOS` | Xcode更新後にSDK / platformを先に確認 |
| Xcode CLIがiOS SDKを見ない | `xcode-select`がCommand Line Toolsを指していた | Xcode本体へswitch | preflightで`xcode-select -p`を確認 |
| certificateのmanual作成が選べない | Personal Team / Xcode UI上でmanual操作不可 | Signing & CapabilitiesでTeam選択＋automatic signing | Accounts画面だけで完結させようとしない |
| Godot exportがtexture compression要件で失敗 | iOS向けETC2 / ASTC importが無効 | `textures/vram_compression/import_etc2_astc=true` | `project.godot`の設定を維持 |
| export先がないため失敗 | `build/ios/`未作成 | `mkdir -p build/ios` | fast pathの最初に作成 |
| Xcode成果物をGodotが画像として再importし、CgBI PNG error | `build/`がGodot resource scan内だった | `build/.gdignore`を追跡 | `.gdignore`を削除しない |
| Xcode build時にCamera / Microphone / Photo usage description警告 | Godot生成Info.plistに空文字が含まれる | 今回は該当機能を使わずbuild成功のため警告として記録 | capability追加時に正しい説明文と権限設計を行う |
| install成功後のlaunchがSecurityで拒否 | Personal Team profileを端末側で未信頼 | iPadでデベロッパAppを信頼 | 初回install直後に§6-6を実施 |
| Godot GUIを開くと`project.godot`の項目順や既定値表記が変わる | Editorのcanonicalize | 意図差分だけ残るようdiffを確認 | GUI操作後は必ず`git diff -- project.godot` |

### 4-1. Security launch errorの見分け方

installは成功しているのにlaunchだけ失敗し、次の意味のエラーが出た場合は、まず端末側の信頼を確認する。

```text
RequestDenied / Security
profile has not been explicitly trusted by the user
```

この時点で証明書を作り直したりBundle IDを変えたりしない。Bundle ID変更は別アプリ・別セーブ領域になるため、原因切り分けを悪化させる。

### 4-2. build scan問題の見分け方

`validate_project.sh`やGodot Editor起動時に、次のようなpathがresource importへ現れたら`build/.gdignore`を確認する。

```text
res://build/ios/DerivedData/...
res://build/ios/...app/AppIcon...
```

Xcodeが生成するPNGは通常のsource assetではない。Godot側へimportさせないのが正しい。

## 5. 次回のpreflight

リポジトリrootで実行する。

```bash
xcode-select -p
xcodebuild -version
/Applications/Godot.app/Contents/MacOS/Godot --version
test -f "$HOME/Library/Application Support/Godot/export_templates/4.7.stable/ios.zip"
xcrun devicectl list devices
git status --short
```

確認項目:

- developer directoryが`/Applications/Xcode.app/Contents/Developer`
- Godot本体とtemplateがどちらも4.7 stable
- 対象iPadがavailable / paired
- iPadのDeveloper Modeが有効
- 作業前のGit差分を把握している
- `export_presets.cfg`のTeam ID / Bundle IDを変更していない
- 価値のあるセーブがある場合、アプリを削除しない

## 6. 次回の最短実行手順

### 6-1. 変数を設定

端末名は`xcrun devicectl list devices`に表示された文字列へ置き換える。

```bash
GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
IPAD_NAME="<接続中のiPad名>"
IOS_PRESET="iOS iPad Debug"
IOS_PROJECT="build/ios/tsuri_quest_umi.xcodeproj"
IOS_APP="build/ios/DerivedData/Build/Products/Debug-iphoneos/tsuri_quest_umi.app"
BUNDLE_ID="net.physical-balance-lab.tsuri-quest-umi"
```

### 6-2. プロジェクト検証

```bash
./tools/validate_project.sh
```

exit 0を確認する。関連smokeに失敗している状態で実機buildを配らない。

### 6-3. GodotからXcode projectを再生成

```bash
mkdir -p build/ios
"$GODOT_BIN" --headless --path . \
  --export-debug "$IOS_PRESET" build/ios/tsuri_quest_umi
```

期待結果:

- command exit 0
- `build/ios/tsuri_quest_umi.xcodeproj`が生成される
- `build/ios/tsuri_quest_umi.pck`が生成される

### 6-4. Xcodeで実機build

```bash
xcodebuild \
  -project "$IOS_PROJECT" \
  -scheme tsuri_quest_umi \
  -configuration Debug \
  -destination "platform=iOS,name=${IPAD_NAME}" \
  -derivedDataPath build/ios/DerivedData \
  -allowProvisioningUpdates \
  build
```

期待結果:

```text
** BUILD SUCCEEDED **
```

`NSCameraUsageDescription`等の空文字warningは今回の既知警告。署名、link、compile、resource copyのerrorとは区別する。

### 6-5. iPadへ上書きinstall

```bash
xcrun devicectl device install app \
  --device "$IPAD_NAME" \
  "$IOS_APP"
```

期待結果:

```text
App installed
```

既存セーブを維持したい場合は、先にiPad上のアプリを削除しない。同じTeam / App ID / Bundle IDで上書きする。

### 6-6. 初回またはprofile更新後だけ端末側で信頼

launchがSecurityで拒否された場合、iPadで次を実行する。

```text
設定 > 一般 > VPNとデバイス管理
  > デベロッパApp
  > Apple Development
  > 信頼
```

### 6-7. launch

```bash
xcrun devicectl device process launch \
  --device "$IPAD_NAME" \
  --terminate-existing \
  "$BUNDLE_ID"
```

期待結果:

```text
Launched application with ... bundle identifier.
```

### 6-8. 起動後プロセス確認

```bash
xcrun devicectl device info processes \
  --device "$IPAD_NAME" \
  | rg "tsuri_quest_umi"
```

実行ファイルが表示されれば、確認時点ではprocessが生存している。ただし、タイトル表示、描画崩れ、タッチ操作の正しさは端末画面で目視確認する。

## 7. 失敗時の切り分け順

同時に複数設定を変えず、次の順で確認する。

1. `xcode-select -p`がXcode本体か。
2. XcodeとiOS platform componentが対象iPadOSを扱えるか。
3. iPadがavailable / pairedで、Developer Modeが有効か。
4. Godot本体とiOS templateのversionが完全一致するか。
5. Godot exportがexit 0か。
6. 生成pbxprojのTeam / Bundle ID / minimum iOSがpresetと一致するか。
7. Xcode buildがcompile errorか、signing errorか、単なるwarningか。
8. installが失敗したのか、install後のlaunchだけ失敗したのか。
9. launchだけSecurity拒否なら端末側のデベロッパApp信頼を確認する。
10. launch後すぐ消えるならprocessとdevice logを確認する。

署名問題を解決するために、最初からBundle IDを変えない。証明書・profileをむやみに削除しない。まずautomatic signingと端末側信頼を確認する。

## 8. 毎回の完了チェックリスト

- [ ] `./tools/validate_project.sh`がexit 0
- [ ] Godot headless exportがexit 0
- [ ] Xcode buildが`BUILD SUCCEEDED`
- [ ] 同じTeam / App ID / Bundle IDを維持
- [ ] 既存アプリを削除せず上書きinstall
- [ ] `devicectl` launch成功
- [ ] 数秒後もprocess生存
- [ ] iPadでタイトル表示を目視
- [ ] landscape / 黒帯 / 文字切れを確認
- [ ] 最低1本、タップで主要導線を往復
- [ ] 水中ファイトの押下・長押し・離すを確認
- [ ] 既存slotと設定が維持されていることを確認
- [ ] source commit、build番号、実施日、結果を記録

## 9. まだ完了していないQA

今回通したのは導入経路だけである。次の項目は`docs/55` §7を正本として継続する。

- `IPAD-INSTALL-01`のタイトル目視と未説明error / crash確認
- 全13画面のタップ主導線
- 水中ファイトのhold / release
- iPad 4:3での黒帯、欠け、誤タップ、文字切れ
- background / foreground / force quit
- 3slotと設定の再起動保持
- 同じidentityでのbuild A→B上書き更新
- offline、Offload、Delete Appの各境界
- 代表画面の性能確認

Delete Appは全セーブを失う破壊テストである。捨てセーブ以外では実行しない。

## 10. 今回の補足判断

### 10-1. preset名と対象device family

preset名は`iOS iPad Debug`だが、今回生成されたXcode projectはiPhone / iPad両方をtarget familyに含めていた。iPad実機spikeには影響しない。正式なiPad専用配布を決める場合は、Godot 4.7のexport optionと生成される`TARGETED_DEVICE_FAMILY`を再確認し、preset名と実設定を揃える。

### 10-2. Personal Teamの期限

Personal Teamのprovisioning profileは7日で失効する。起動できなくなった場合は、同じBundle IDのまま再build / 再installする。長期テストや複数テスター配布はTestFlightへ移行する。

### 10-3. セーブ保全

再installとDelete Appは同じではない。上書きinstallでは保持を期待できるが、Delete Appはcontainerごと削除する。正式に保持を案内する前に、同一identityのA→B更新回帰を完了する。
