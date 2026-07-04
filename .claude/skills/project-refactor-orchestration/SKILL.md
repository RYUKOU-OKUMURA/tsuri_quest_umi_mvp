# Project Refactor Orchestration

プロジェクト全体の behavior-preserving リファクタを、Fable オーケストレーター + Composer ワーカーで進める手順。

## いつ使うか

- 大規模リファクタ、複数モジュールにまたがる整理、Long horizon Cloud Agent 作業
- UI uplift 単体 → `skills/ui-screen-uplift/` を使う（本スキルと混ぜない）

## 正本

1. `docs/26_refactor_orchestration_plan.md` — スライス表・ベースライン・DoD
2. `AGENTS.md` §オーケストレーション — 役割分担
3. `.cursor/rules/orchestration.mdc` — セッション常時ルール

## Fable（オーケストレーター）の手順

1. `docs/26` の次 pending スライスを選ぶ（依存を満たしていること）
2. fan-out 可能なら Composer brief を書く（テンプレは docs/26 §ワーカー brief）
3. 独立スライスは subagent を並列起動
4. 戻りを diff レビュー。不十分なら brief 修正して再投入
5. `./tools/validate_project.sh` + 該当 smoke が green なら docs/26 の状態を更新
6. UI を触った場合は visual QA も確認してから次スライスへ

## Fable 単体で進める条件

- アーキテクチャ方針の決定（ScreenBase 責務、autoload 境界など）
- 1スレッドで追うべき難バグ
- freeze 値・docs/19 との衝突判断
- **サブタスクに名前を付けられない**作業

## Composer ワーカーに渡す典型タスク

| タスク | DoD 例 |
|---|---|
| ベースライン計測 R0 | docs/26 §一括実行 が全部 green、結果を §ベースライン に記録 |
| palette 違反修正 | 指定ファイルのみ、validate + 関連 smoke |
| 素材参照監査修正 | `python3 tools/audit_showcase_asset_refs.py` green |
| pure 関数抽出 | 振る舞い不変、該当 smoke green |

## 禁止

- ワーカーに計画立案を任せる
- freeze 値の変更（P1 再発時を除く）
- コード整理と UI uplift を同一 brief に混ぜる
- validate / smoke を skip して完了扱いにする
