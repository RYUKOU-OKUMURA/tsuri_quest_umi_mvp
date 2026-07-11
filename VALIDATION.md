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

原子的書き込み、バックアップ復元、未知save versionの非破壊guard、失敗通知、ユーザーデータ領域移行などの回帰を扱います。発売前にはSAVE-04統合後の最新版で再実行します。

### export起動

```zsh
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot \
  TSURI_EXPORT_SOURCE_REF=HEAD \
  ./tools/export_launch_verify.sh
```

REL-01の最小macOS Universal exportに対する起動確認用です。指定したGodotと同じ版のmacOS export templateが `~/Library/Application Support/Godot/export_templates/` 以下に必要です。`GODOT_BIN` の既定値は上記のアプリ内実行ファイルで、`godot` / `godot4` のPATH探索は行いません。

入力はdirty worktreeではなく、`TSURI_EXPORT_SOURCE_REF`（既定 `HEAD`）が解決するcommit treeです。未コミットの文書・実装を検証したい場合は先にcommitする必要があります。このコマンドは最終RCの署名・公証済み成果物を検証するrelease verifierではありません。

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

最終RCでは「既知だから許容」ではなく、固定した最終配布物に対してrelease verifierを実行し、未説明ERROR 0を確認します。

## 文書変更の基本確認

`git diff --check` に加え、4文書を `rg` で横断し、初期MVPの魚数、旧レベル上限、古い未実装一覧、Godotを実行できないという説明が残っていないことを確認します。履歴欄も現在の対応範囲と混同しない表現にします。

## Pre-RC / RCで追加する検証

- E7: 3難易度の保存・倍率・ファイト・タイトル/ステータス表示
- E11: 音量、slot削除、表示、全画面入力、製品アイコン・スプラッシュ
- 対象Mac: 最低macOS、最低対象Mac、Intel確認
- 権利: RIGHTS-01Aの確定と、最終成果物内のnotice・Godot license・OFL同梱（RIGHTS-01B）
- RC: source commit、Godot/export template版、unsigned hash、署名・公証後のfinal artifact/ZIP hashの固定
- 最終配布物: clean起動、save移行・再読込、性能・30分soak、easy/normal/hard × 序盤/中盤/終盤の9セル受入

RC固定後は検証対象のパッケージ入力を変更しません。修正・再export・再署名でfinal hashが変わった場合はRC番号を上げ、必要な検証を再実行します。
