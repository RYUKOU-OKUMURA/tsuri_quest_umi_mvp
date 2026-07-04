# AGENTS.md — tsuri_quest_umi_mvp

海釣りRPG（Godot 4 / GDScript / 1280x720固定）のMVP。UIは「AI生成PNG素材 + Godot runtime描画（テキスト・状態・ゲージ）」の分担で作る方針。ドキュメント・コミットメッセージ・UI文言は日本語。

## ディレクトリ地図

| パス | 役割 |
|---|---|
| `src/ui/` | 画面スクリプト（`*_screen.gd`）と `components/` |
| `src/ui/palette.gd` | 共通色パレット（**色の正本。新規ハードコードhex禁止**） |
| `src/ui/game_fonts.gd` | フォント正本（LINE Seed JP、AA有効で全画面統一。2026-07-05確定→docs/19 §4.2） |
| `assets/showcase/common/` | 共通UI素材（ステータスバー、汎用ボタン、カード/行枠、汎用アイコン） |
| `assets/showcase/fish/` | 魚ドメイン共有素材（魚ポートレート、泳ぎシート）。画面からは `FightFishAssets` 経由で参照 |
| `assets/showcase/<screen>/` | 画面別PNG素材（背景、料理、釣り場サムネ、画面専用フレームなどの一点物） |
| `tools/` | 素材生成（`generate_*.py`）、visual QA（`*_visual_qa.sh`）、smoke test、`validate_project.sh` |
| `docs/` | 仕様・振り返り・指示書（番号順） |
| `reference/` | 正式完成イメージ（`.gdignore` 済み。**ゲームに直接インポート禁止**） |
| `docs/qa/` | 画面別QA判断ログ（freeze表・不採用リスト。**1画面1ファイル**。書式は `docs/qa/README.md`、過去経過は `archive/`、証拠画像は `evidence/`） |
| `skills/` | 作業手順スキル（下記） |
| `.cursor/rules/` | Cursor 常時ルール（オーケストレーション等） |
| `docs/26_refactor_orchestration_plan.md` | 全体リファクタの作戦台帳（スライス・ベースライン・DoD） |

## 最重要参考資料

**UI実装・改善作業はすべて `docs/19_ui_production_playbook.md` に従うこと。** これがルールの正本（優先順位、P1/P2/P3トリアージ、共通キット規約、スタイルガイド、v1完了条件、既知ギャップ§8.5）。本ファイルやスキルと矛盾したら docs/19 を優先し、docs/19 側を改訂してから作業する。

## 作業種別とスキルの対応

| 作業 | 従う手順 |
|---|---|
| 新しい画面UIをゼロから実装 | `skills/ui-screen-build/SKILL.md` |
| 既存画面UIの品質向上 | `skills/ui-screen-uplift/SKILL.md` |
| 調理・食事・レベルアップフロー | `skills/tsuri-cooking-showcase-uplift/SKILL.md`（専用。上記2つより優先） |
| プロジェクト全体リファクタ | `skills/project-refactor-orchestration/SKILL.md` |

## オーケストレーション（Fable / Composer）

Cursor 常時ルール: `.cursor/rules/orchestration.mdc`  
作戦台帳: `docs/26_refactor_orchestration_plan.md`

### 役割

- **Fable（オーケストレーター）**: 計画、スライス分割、依存順、完了判断、マージ前レビュー
- **Composer 2.5（ワーカー）**: brief で渡された scoped 作業（実装・監査・チェック実行）

### Fable 単体（fan-out しない）

- アーキテクチャ方針の決定（ScreenBase 責務、autoload 境界など）
- 1スレッドで追うべき難バグ
- freeze 値・docs/19 との衝突判断
- サブタスクに名前を付けられない作業

### Composer に fan-out する典型

| サブタスク | モデル | 手順 |
|---|---|---|
| ベースライン計測・smoke 実行 | Composer | `docs/26` §Smoke |
| palette / 素材参照監査修正 | Composer | AGENTS.md 不変ルール |
| 指定ファイルの pure 関数抽出 | Composer | behavior-preserving のみ |
| 画面別 UI uplift | Composer | `skills/ui-screen-uplift/` |
| 調理フロー | Composer | `skills/tsuri-cooking-showcase-uplift/` |

独立スライスは並列起動可。ワーカーに計画を考えさせない。

### ワーカー brief 必須項目

1. **1 concern** — 複数目的を混ぜない
2. **触ってよいファイル** — 明示リスト
3. **触ってはいけないもの** — `docs/qa/*_qa.md` の freeze、他画面素材
4. **Definition of Done** — 実行コマンド + 期待結果
5. **短い報告** — 変更概要 / 実行結果 / 未解決

### マージ前（Fable）

- ワーカー報告を信じず diff をレビュー
- ズレていれば brief を書き直して再投入。些末以外は Fable が黙って直さない
- 各スライス後: `./tools/validate_project.sh` + 触った領域の smoke（UI 変更時は visual QA）

## 検証コマンド

```bash
./tools/validate_project.sh        # プロジェクト全体検証（作業完了前に必須）
./tools/fight_visual_qa.sh         # 水中ファイトの比較スクショ再生成
./tools/cooking_visual_qa.sh       # 調理フローの比較スクショ再生成
./tools/fish_book_visual_qa.sh     # 魚図鑑の比較スクショ再生成
./tools/fishing_spot_map_visual_qa.sh # 釣り場マップの比較スクショ再生成
```

`validate_project.sh` は `tools/audit_showcase_asset_refs.py` を含み、`src/ui` からの素材所有違反（他画面フォルダの直接参照、魚素材の直接参照など）を検出する。例外が必要な場合は、監査ツール内の明示allowlistに理由コメントを残す。

smoke test は `tools/*_smoke.tscn` を headless Godot で実行。UI変更でも該当フローのsmoke（釣行継続・港戻り・出現監査など）を必ず回す。

## 不変ルール（要約。詳細は docs/19）

- 見た目の完了判断は必ず**実スクショ + 参照画像との横並び比較**で行う。コード上のサイズ指定やテストの green を根拠にしない。
- 作業順は「構成 → 主導線 → 情報階層 → 文字の収まり → 素材の質感 → 演出」。逆走しない。
- 数px・明度の微調整を3回繰り返して改善しないなら素材品質不足。素材フェーズへ送る（回数はQAドキュメントの微調整カウンタで数える）。
- 合格済みのfreeze値（`docs/qa/<screen>_qa.md` のfreeze表記載）は、P1破綻の再発時以外は動かさない。
- 日本語テキストをPNG素材へ焼き込まない。
- 素材候補は「現行に全画面比較で明確に勝つ」場合だけ採用。採用/不採用の理由をQAドキュメントに残し、判断根拠の比較画像を `docs/qa/evidence/<screen>/` へコピーする（`/tmp` のみに残さない）。
- 他画面の素材フォルダを直接参照しない。共有する部品は `assets/showcase/common/` へ昇格してから使う。
- 魚素材はUI共通部品ではなく `assets/showcase/fish/` のドメイン共有素材として扱い、画面からは `FightFishAssets` 経由で参照する。
- `reference/*.png` は方向性の真実だが最終アートではない。分解して本番素材に置き換える。
