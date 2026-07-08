# CLAUDE.md — tsuri_quest_umi_mvp（Claude Code 固有）

共通の指示書は下記 import で読み込む（内容の正本は `AGENTS.md`。二重管理しない）。

@AGENTS.md

本ファイルには Claude Code で実行するときの固有ルール（役割・モデル割り当て）だけを書く。`.cursor/rules/orchestration.mdc`（Cursor の Fable×Composer 運用）と対になるファイル。

## オーケストレーション（Claude Code 固有）

ツール共通の原則（fan-out 条件、brief 必須項目、マージ前検証）は `AGENTS.md` §オーケストレーション。作戦台帳は `docs/30_v2_expansion_overview.md`（V2進行中）。

### 役割

- **メイン会話（オーケストレーター）**: 計画、スライス分割、依存順、完了判断、マージ前レビュー
- **サブエージェント（ワーカー）**: brief で渡された scoped 作業のみ（実装・監査・チェック実行）

AGENTS.md の「親エージェント」= メイン会話、「ワーカー」= サブエージェントと読み替える。

### fan-out してよい条件

サブタスクに**1 concern・触るファイル・DoD**を命名できるときだけサブエージェント（Task tool）を起動する。命名できないときはメイン会話単体のまま進める。fan-out する典型と brief の必須項目は AGENTS.md の表に従う。

### ワーカーのモデル指定（必須）

- サブエージェント起動時は **必ず `model: claude-sonnet-5` を明示指定**する（Task tool の per-invocation `model` パラメータ、またはカスタムエージェント定義の frontmatter `model: claude-sonnet-5`）。未指定だとメイン会話のモデルを継承してしまう
- 修正の再投入も同様に `model: claude-sonnet-5` を毎回明示する。誤ったモデルで走ってしまったワーカーは、resume せず新規ワーカーとして brief を再投入する

### リファクタ原則

- behavior-preserving を原則。1スライス = 1 PR 相当
- UI 変更は `docs/19_ui_production_playbook.md` と freeze 値を尊重
- コード整理と UI uplift を同一ワーカーに混ぜない
