# REL-01 macOS Universal 最小export spike（2026-07-11）

## 実行環境

- source commit: `0d78f2a4c104f411ff8a9a79c1df96f1396eb2ac`
- source tree: `b30d1fc722dd9860b9bb26e59cb3acf639d01577`
- Godot: `4.7.stable.official.5b4e0cb0f`
- export template: 公式 `Godot_v4.7-stable_export_templates.tpz` 内 `templates/macos.zip`
- preset: `macOS Universal`
- bundle ID: `net.physical-balance-lab.tsuri-quest-umi`
- architecture: `x86_64 arm64`（`lipo -info`でdebug / release双方を確認）
- source input: 実行時に表示するGit source commitとそのtree object（`git archive`で展開。tree単体は拒否）
- codesign / notarization: 最小spikeでは未実施。最終方針と実施証跡はSIGN-01 / RC Gateで扱う
- `application/min_macos_version=10.15`: spikeの暫定export値。TARGET-01の最低対応macOS決定や販売サポート確定を意味しない

再現コマンド:

```bash
./tools/export_launch_verify.sh
```

Godot 4.7のmacOS export templateが
`~/Library/Application Support/Godot/export_templates/4.7.stable/macos.zip`
にない場合、スクリプトは不足パスと版を表示して失敗する。入力は既定でclean `HEAD`の
tracked treeを`git archive`から展開するため、worktreeのdirty / untracked / ignored資源は
使用しない。Universal exportに必要なETC2/ASTC import設定はexport専用一時stageにだけ
追加し、freeze対象の`project.godot`は変更しない。

## 結果

- debug export: PASS
- release export: PASS
- clean HOMEでmain scene起動・title ready到達 → slot 1新規save作成: PASS
- 同じ成果物を終了・再起動 → title ready到達・`money=4242`読込: PASS
- 旧MVP namespaceのroot save → 新namespace slot 1コピー・読込: PASS
- 旧原本SHA-256不変: PASS
- debug PCK SHA-256: `228af6e30eb10a7a3ce4bcf5dba97e2b9b4402cdc871fe15926dbd45c516c542`
- release PCK SHA-256: `228af6e30eb10a7a3ce4bcf5dba97e2b9b4402cdc871fe15926dbd45c516c542`
- release pack manifest: 956件 / SHA-256 `65cd758324ef106eedb5a434ecf9c105c74acce6e52311ea008c0c1ff3056ab6`
- 成果物サイズ: debug 303MiB / release 287MiB（`du -sh`）

source commit / tree、PCK hash、manifest件数 / hashは実行時に
`$TSURI_EXPORT_BUILD_ROOT/logs/artifacts.sha256`（既定では
`/private/tmp/tsuri_quest_umi_export_spike/logs/artifacts.sha256`）へ機械保存し、stdoutにも出力する。
PCKが各appにちょうど1件でなければ検証失敗とする。

このSHA-256は最小spike成果物の追跡用であり、署名・公証・最終packageを固定するRC hashではない。
spike harnessまたはsource commitが変わるたび再生成する。

## 配布物の列挙検査

canonical preset自体が`reference/**`と`tools/**`を除外する。spike専用smokeは
Git固定treeからstage-onlyの`src/__export_spike/`へコピーし、release exportが出力する
全pack entry manifestでもdeny prefixを検査して混入がないことを確認した。検証時の
canonical manifest全件は
[`rel_01_release_pack_manifest_2026-07-11.txt`](rel_01_release_pack_manifest_2026-07-11.txt)
へ固定した。件数956、重複0、不正形式0、禁止prefix 0で、上記SHA-256と一致する。

- `reference/`
- `tools/`全体
- `.git/`
- `build/`

`export_launch_smoke.gd`は最小spike用のdormant autoloadとして一時stageだけに配線する。
通常起動では処理せず、sourceの`project.godot`にもautoloadを追加しない。最終RCでは
release verifierの方式確定後、この例外を配布物から外すこと。

stage限定の`ExportLaunchPreflight`を`PlayerProgress`より前のautoloadへ配線し、各phaseで
許可phaseと、scriptから渡したfixture user-data絶対パスと`OS.get_user_data_dir()`の完全一致をmigration / save
より前に確認する。不一致時はsandboxを立てて非ゼロ終了し、actual user-data配下にmarker / main /
backup / tmpが生成されないexpected不一致・unknown phaseの負ケースを先に実行する。通常3 phaseではmain sceneとtitle screenのreadyを
最大5秒待ち、到達しない場合やruntime
logに未説明`ERROR:`がある場合はPASSにしない。終了時のGodot既知診断
`ERROR: 1 resources still in use at exit`だけは、通常のvalidateでも再現するcleanup診断として
明示allowしている。

## RIGHTS-01Bへの引き渡し

現成果物にはGodot MIT notice、Godotがリンクする第三者ライブラリのlicense、
`THIRD_PARTY_NOTICES.md`、LINE Seed JPの`OFL.txt`、M PLUS 1pの
`OFL-MPLUS1p.txt`が独立ファイルとして同梱されていない。フォント本体がPCKへ入るため、
少なくとも次のRC packaging対応が必要。

1. Godot 4.7と同版のcopyright / license / third-party license一覧を同梱する。
2. `THIRD_PARTY_NOTICES.md`と両OFL全文を最終配布物から閲覧可能な形で同梱する。
3. `LICENSE.md`は権利者placeholder解消後の確定版を同梱する。
4. 固定RC成果物そのものに対して同梱ファイルと内容を再検査する。

これはRIGHTS-01B / RC Gateの未完事項であり、REL-01のexport可能性・save回帰結果を
偽装してcloseするものではない。

## 証跡commit境界

上記成果物は統合後のclean source commit `0d78f2a4c104f411ff8a9a79c1df96f1396eb2ac`
から生成した。本書とmanifestを追加する後続commitは`docs/**`だけを変更し、canonical presetが
`docs/**`をpack対象に含めないため、検証済みPCKの入力は変わらない。E11外装、署名・公証、
notice同梱、またはゲーム入力が変わった時点で本spikeのhashを最終RC証跡として流用せず、
release verifierで再生成する。
