# 検証ガイド

本書はソースツリーから再現できる検証を説明します。プロジェクトはPre-RC開発中であり、ここにあるコマンドの成功だけでは署名・公証、最終配布物、性能、対応Mac、9セル受入の完了を意味しません。

## 前提

- Godot 4.7 Standard（`godot`、`godot4`、または `/Applications/Godot.app/Contents/MacOS/Godot`）
- Python 3
- macOS / zshまたはbash

検証用Godot HOMEは既定で一時領域へ分離されます。並列実行時は衝突を避けるため個別に指定してください。

```zsh
TSURI_GODOT_HOME=/tmp/tsuri-docs-release ./tools/validate_project.sh
```

## 必須の全体検証

```zsh
./tools/validate_project.sh
```

現行スクリプトが実行する内容は次のとおりです。

1. showcase素材の所有・参照境界監査
2. 魚素材の重複監査
3. 魚スプライトシート契約監査
4. 製品識別子監査
5. ライセンス文書監査のself-testと実監査
6. Godotヘッドレスエディタによるプロジェクト・スクリプト読込
7. メインシーンの2秒起動

これは個別の `tools/*_smoke.tscn`、全visual QA、セーブ検証、export検証を網羅しません。変更領域に応じて追加検証を実行します。

## 代表的な追加検証

### セーブ保護

```zsh
./tools/save_system_verify.sh
```

原子的書き込み、バックアップ復元、未知save versionの非破壊guard、失敗通知、ユーザーデータ領域移行、旧saveの達成不能依頼repairなどの回帰を扱います。SAVE-04統合後の検証は完了しており、今後もセーブ契約へ影響する変更時と固定RCで再実行します。

### export起動

```zsh
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot \
  TSURI_EXPORT_SOURCE_REF=HEAD \
  ./tools/export_launch_verify.sh
```

REL-01の最小macOS Universal exportに対する起動確認用です。指定したGodotと同じ版のmacOS export templateが `~/Library/Application Support/Godot/export_templates/` 以下に必要です。`GODOT_BIN` の既定値は上記のアプリ内実行ファイルで、`godot` / `godot4` のPATH探索は行いません。

入力はdirty worktreeではなく、`TSURI_EXPORT_SOURCE_REF`（既定 `HEAD`）が解決するcommit treeです。未コミットの文書・実装を検証したい場合は先にcommitする必要があります。このコマンドは最終RCの署名・公証済み成果物を検証するrelease verifierではありません。

### release verifier

まず、検出・manifest分類・失敗・未説明ERROR・export証跡契約の負ケースを含むself-testを実行します。

```zsh
python3 tools/release_verify_self_test.py
```

次にskeleton modeで、30件の `*_smoke.tscn` / `*_audit.tscn` と、同stemのsceneを持たないscript-only audit 1件を自動列挙し、合計31対象を実行・委譲します。発見集合と `tools/release_test_manifest.txt` は完全一致が必須で、セーブ2件とexport 1件の特殊runner 3件は存在・分類とも必須です。manifestはsymlinkでないregular fileを単一readしてparse/hashし、source外manifestを指定した場合も含め、開始・終了hashが一致しなければ失敗します。全体validate、scene/script audit、セーブ検証委譲を実行し、機械可読レポートを生成します。

```zsh
./tools/release_verify.sh
```

既定の出力先は `/tmp/tsuri_release_verify/release_verify_report.json` です。`--output-dir` または `TSURI_RELEASE_VERIFY_OUTPUT` で変更できますが、出力先はsource root外必須です。gitignore対象であってもリポジトリ内は指定できません。使用するGodotは `GODOT_BIN` で指定でき、runnerは解決した同一engineをPATH shim経由でvalidate / saveにも強制します。隔離HOMEの親は既存の実ディレクトリを `TSURI_RELEASE_HOME_PARENT` で指定し、runnerがrun固有HOMEを作成して各testへさらに分離します。GodotのHOMEを分離してもPython監査の依存を失わないよう、起動元Pythonのユーザーベースは子processの`PYTHONUSERBASE`へ引き継ぎます。`TSURI_GODOT_HOME` はrunner内部で設定されるため、利用者がrelease verifier用に指定する変数ではありません。

Godot解決などsetupのtimeoutは `TSURI_RELEASE_SETUP_TIMEOUT_SECONDS`（既定30秒）です。全testを同じ値へ明示上書きする場合だけ `TSURI_RELEASE_TEST_TIMEOUT_SECONDS` を使います。未指定時の個別budgetは通常900秒、`tools/nushi_encounter_audit.tscn` のみ1800秒です。

各実行は出力先の `logs/run_*` に固有ログを作り、過去runのログを今回の証跡として再利用しません。ERRORだけでなく、明示allowlist外の未知WARNINGも失敗にします。開始時と終了時にcommit/tree、porcelain、staged/unstaged差分とuntracked内容を含むsource content digestを取得し、run中にsourceが変化した場合も失敗します。

skeleton modeの `skeleton_passed` は、export証跡を指定しなくても31対象の骨格・source検証が成功したことを示します。このとき `export_launch_smoke.tscn` のstatusは `pending_rc_evidence` で、RC証跡による被覆済みを意味しません。RC modeで証跡を消費した場合だけ `delegated_evidence` になります。固定RC検証や最終配布証跡の完了も意味しません。

固定RCではclean worktreeと、同じsource commit/treeから `tools/export_launch_verify.sh` が生成したexport証跡・全stdoutログを指定してRC modeを実行します。

```zsh
mkdir -p /tmp/tsuri_release_evidence
set -o pipefail
./tools/export_launch_verify.sh \
  | tee /tmp/tsuri_release_evidence/export_launch_verify.log

TSURI_EXPORT_ARTIFACT_LOG=/tmp/tsuri_quest_umi_export_spike/logs/artifacts.sha256 \
  TSURI_EXPORT_VERIFY_LOG=/tmp/tsuri_release_evidence/export_launch_verify.log \
  ./tools/release_verify.sh --rc
```

上記パスは例です。`TSURI_EXPORT_VERIFY_LOG` には `export_launch_verify.sh` の全stdoutを事前に保存し、証跡のsource commit/treeを検証対象HEADと一致させます。RC modeは開始時と終了時の両方でexport evidence、export template、artifact実体、run logを再hashし、途中差し替えも失敗にします。

`rc_passed` も、署名・公証判断、final `.app` / ZIP hash、RIGHTS-01B、性能・soak、3難易度9セル受入を代替せず、最終発売Gate全体の完了を意味しません。これらの最終証跡は固定RCで別途完了させます。

### 画面別visual QA

例:

```zsh
./tools/fight_visual_qa.sh
./tools/cooking_visual_qa.sh
./tools/fish_book_visual_qa.sh
./tools/fishing_spot_map_visual_qa.sh
```

UI変更では対象画面のvisual QAとsmokeを選び、実スクリーンショットを参照画像と比較します。利用可能な検証入口は `tools/*_smoke.tscn`、`tools/*_audit.tscn`、`tools/*_visual_qa.sh` を列挙して確認してください。

```zsh
find tools -maxdepth 1 \
  \( -name '*_smoke.tscn' -o -name '*_audit.tscn' -o -name '*_visual_qa.sh' \) \
  -print | sort
```

## Godot終了時のcleanup診断

一部のヘッドレス検証では、テスト本体が成功した後のエンジン終了処理で、ObjectDBやリソース解放に関するcleanupメッセージが出ることがあります。現行ベースラインで観測済みの例は `Could not create ObjectDB Snapshots directory`、`ObjectDB instances were leaked at exit`、`resources still in use at exit` です。これは包括的な許容リストではなく、同じ文字列なら無条件で無視してよいという意味でもありません。判定は次の順で行います。

1. コマンドの終了コードを確認する
2. 各toolが定義する成功マーカーと期待したassertion件数を確認する
3. cleanupより前にscript error、assertion failure、parse error、未説明のERRORがないことを確認する
4. 既知のcleanup診断だけで成功扱いを覆さない一方、新規・未説明のERRORを「cleanup」と決めつけない

最終RCでは「既知だから許容」ではなく、固定した最終配布物に対してrelease verifierを実行し、未説明ERROR / WARNING 0を確認します。

## 文書変更の基本確認

`git diff --check` に加え、4文書を `rg` で横断し、初期MVPの魚数、旧レベル上限、古い未実装一覧、Godotを実行できないという説明が残っていないことを確認します。履歴欄も現在の対応範囲と混同しない表現にします。

## Pre-RC / RCで追加する検証

- E7（完了済み・固定RCでも再実行）: 3難易度の保存・倍率・ファイト・タイトル/ステータス表示
- E11: 音量、slot削除、表示、全画面入力、製品アイコン・スプラッシュ
- 対象Mac: 最低macOS、最低対象Mac、Intel確認
- 権利: RIGHTS-01Aの確定と、最終成果物内のnotice・Godot license・OFL同梱（RIGHTS-01B）
- RC: release verifier RC mode、source commit、Godot/export template版、unsigned hash、署名・公証後のfinal artifact/ZIP hashの固定
- 最終配布物: clean起動、save移行・再読込、性能・30分soak、easy/normal/hard × 序盤/中盤/終盤の9セル受入

RC固定後は検証対象のパッケージ入力を変更しません。修正・再export・再署名でfinal hashが変わった場合はRC番号を上げ、必要な検証を再実行します。
