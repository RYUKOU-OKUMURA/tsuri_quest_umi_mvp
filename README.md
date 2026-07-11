# 釣りクエスト ～海釣り編～

Godot 4.7で制作している、1280×720固定の海釣りRPGです。港を拠点に釣り場へ出て、魚を釣り、売却・料理・装備更新を重ねながら沖と危険海域を目指します。

> 現在は **Pre-RC開発中** です。難易度（E7）、設定・入力・製品外装（E11）、権利確認、対象Mac、署名・公証方針、最終RC検証は未完です。このリポジトリの内容を、そのまま署名・公証済み製品版とみなすことはできません。

## プレイヤー向け

正式な配布ZIPと対応環境はRC確定後に案内します。開発中のソースを試す場合は、Godot 4.7 Standardで `project.godot` を開き、プロジェクトを実行してください。

### 基本操作

| 場面 | 操作 |
|---|---|
| メニュー | マウス（キーボードによる全画面操作はE11で確定） |
| 仕掛けを投げる | 画面ボタン、Enter |
| アワセる | 画面ボタン、E、Enter |
| リールを巻く | 画面ボタン長押し、Space長押し |
| 糸を出す | 画面ボタン長押し、Shift長押し |

水中ファイトでは、テンションを安全域に保ちながら魚の体力を削ります。魚の突進・潜水中は糸を出し、動きが緩んだら巻くのが基本です。

### 現在遊べる主な内容

- 港を中心とする釣行、売却、料理、装備更新、図鑑・記録確認
- 9釣り場（通常7、危険海域1、港のぬし専用1）と3時間帯
- 通常・拡張魚80種、各地のヌシ8種（うち通常サメ9種、育成対象サメ10種）
- レベル1～50、二段階成長曲線、食経験値・初回料理ボーナス・次回釣行の食事効果
- 竿5種、仕掛け7種、船3種
- 依頼ボード、称号31件、釣行イベント、海図断片
- サメの横取り、餌魚READY選択、生簀でのサメ育成、メガロドン
- 3スロットのJSONセーブ、バックアップ復元、旧ユーザーデータ領域からの非破壊移行

魚数は `GameData.get_all_fish_ids()` が返す80種と、`GameData.get_all_nushi_fish_ids()` が返す8種を分けて表記しています。メガロドンは80種および育成対象サメ10種に含まれます。

## 開発者向け

### 必要環境

- Godot 4.7 Standard
- macOS（開発・検証の現行対象。発売時の最低macOS、最低対象Mac、Intel確認方法は未確定）
- 基準解像度 1280×720
- GL Compatibilityレンダラー

### 実行

Godotのプロジェクトマネージャーで `project.godot` を読み込み、F5で実行します。macOSでは `tools/open_on_mac.command` からも起動できます。

```zsh
chmod +x tools/open_on_mac.command
./tools/open_on_mac.command
```

### 検証

```zsh
./tools/validate_project.sh
```

このコマンドは素材参照・魚素材契約・製品識別子・ライセンス文書を監査し、Godotのヘッドレスエディタ読込とメインシーンの短時間起動を行います。全smoke、画面別visual QA、セーブ回帰、export/配布物検証を一括実行するコマンドではありません。詳しい再現コマンドと終了時cleanup診断の扱いは [VALIDATION.md](VALIDATION.md) を参照してください。

### 主な構成

```text
scenes/                 メインシーン
src/autoload/            静的カタログ、進行、セーブ
src/core/                釣りシミュレーション
src/ui/                  画面と共通UI部品
assets/showcase/         本番用UI・魚素材
tools/                   監査、smoke、visual QA、素材生成
docs/                    仕様、進行台帳、QA判断ログ
reference/               企画・比較用参照画像（配布物には含めない）
```

静的な魚・釣り場・料理・装備データは `src/autoload/game_catalog_data.gd` と `src/autoload/fish_expansion_data.gd`、公開APIとレベル上限は `src/autoload/game_data.gd`、進行とセーブは `src/autoload/player_progress.gd` にあります。

進行状況の正本は `docs/30_v2_expansion_overview.md` §6、発売阻害要因とLaunch Gateは `docs/45_release_readiness_code_review.md`、UI作業ルールは `docs/19_ui_production_playbook.md` です。

## Pre-RCで確定・再更新する項目

- E7の難易度仕様と、E11の設定・入力・製品外装の実装結果
- 最低macOS、最低対象Mac、Intel確認方法
- Developer ID署名・公証を発売条件にするかの判断
- RIGHTS-01A（素材の出所・入力権利、アイコン、商標、権利者名）
- 30対象へfreeze済みのrelease verifier骨格を固定RCで実行し、最終的な配布物構成と同梱ライセンスを確認
- RC固定後のsource commit、Godot/export template版、unsigned/final artifact/ZIP hash、最終配布物での検証結果
