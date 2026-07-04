# リファクタ作戦台帳

最終更新: 2026-07-05 / 状態: 計画策定中

Fable オーケストレーターが本ファイルを正本としてスライス順・状態・ベースラインを管理する。
Composer ワーカーは個別 brief のみ受け取り、本ファイルの更新はオーケストレーターが行う。

関連: `AGENTS.md` §オーケストレーション、`.cursor/rules/orchestration.mdc`、`skills/project-refactor-orchestration/SKILL.md`

## 全体 Definition of Done

- [ ] `./tools/validate_project.sh` が通る
- [ ] 下記 §Smoke 一覧がすべて通る（R0 でベースライン記録済み）
- [ ] `docs/qa/*_qa.md` の freeze 値を変更していない（P1 再発時を除く）
- [ ] UI を触ったスライスは visual QA で退行なし

## Smoke 一覧（headless 実行）

Godot 4.x headless。プロジェクトルートから:

```bash
godot --headless --path . res://tools/<scene>.tscn
```

| シーン | 主な確認内容 |
|---|---|
| `fishing_reveal_smoke.tscn` | 魚種公開タイミング（BITE 前は伏せ、hook 後に公開） |
| `fishing_harbor_return_smoke.tscn` | 帰港確認・キーボード導線 |
| `fishing_spot_select_smoke.tscn` | 釣り場選択・ロック・船不足 |
| `shipyard_smoke.tscn` | 船購入・再購入防止・アクセス判定 |
| `tackle_shop_smoke.tscn` | 釣具店購入導線 |
| `market_smoke.tscn` | 市場売却 |
| `cooking_flow_smoke.tscn` | 調理→食事→EXP フロー |
| `fish_book_smoke.tscn` | 魚図鑑表示 |
| `status_smoke.tscn` | ステータス画面 |
| `catch_fanfare_smoke.tscn` | 捕獲ファンファーレ |

一括実行（R0 ベースライン用）:

```bash
for s in fishing_reveal fishing_harbor_return fishing_spot_select shipyard tackle_shop market cooking_flow fish_book status catch_fanfare; do
  echo "=== ${s}_smoke ==="
  godot --headless --path . "res://tools/${s}_smoke.tscn" || exit 1
done
./tools/validate_project.sh
```

## スライス計画

| ID | concern | 依存 | 担当 | DoD | 状態 |
|---|---|---|---|---|---|
| R0 | ベースライン計測 | — | Composer | 全 smoke + validate の結果を §ベースラインに記録 | pending |
| R1 | palette 外ハードコード色の洗い出しと修正 | R0 | Composer | `rg` 監査 green、validate + 触った画面 smoke | pending |
| R2 | showcase 素材参照違反の修正 | R0 | Composer×画面 | `audit_showcase_asset_refs.py` green | pending |
| R3 | autoload / core の pure ロジック境界抽出 | R0, Fable 設計 | Composer | 振る舞い不変、該当 smoke green | pending |
| R4 | UI 共通基盤（ScreenBase 等）の整理 | R3, Fable 設計 | Composer | Fable 承認済み設計どおり、全 smoke green | pending |
| R5 | 画面別 UI uplift | R4 | Composer×画面 | 各 `skills/ui-screen-uplift/` + visual QA | pending |

**fan-out 向き**: R0、R1（ファイル単位）、R2（画面単位）、R5（画面単位・並列可）  
**Fable 単体向き**: R3/R4 の設計判断、サブタスクに名前を付けられない調査

## ベースライン（R0 完了後に記録）

| チェック | 日付 | 結果 | 備考 |
|---|---|---|---|
| validate_project.sh | | | |
| fishing_reveal_smoke | | | |
| fishing_harbor_return_smoke | | | |
| fishing_spot_select_smoke | | | |
| shipyard_smoke | | | |
| tackle_shop_smoke | | | |
| market_smoke | | | |
| cooking_flow_smoke | | | |
| fish_book_smoke | | | |
| status_smoke | | | |
| catch_fanfare_smoke | | | |

## ワーカー brief テンプレート

```markdown
## Concern
（1文）

## 触ってよいファイル
- path/to/file.gd

## 触ってはいけないもの
- docs/qa/<screen>_qa.md の freeze 値
- （その他）

## Definition of Done
- [ ] （コマンドと期待結果）

## 報告形式
- 変更概要:
- 実行結果:
- 未解決:
```

## Cloud Agent 初回プロンプト例

```
docs/26_refactor_orchestration_plan.md を正本として behavior-preserving リファクタを進めてください。

- あなた（Fable）は計画・レビュー・完了判断のみ
- 実装・監査・smoke は Composer 2.5 subagent に brief で fan-out
- 1スライス完了ごとに validate + 該当 smoke を確認してから次へ
- freeze 値・docs/19 違反があれば停止して報告

最初の作業: R0 ベースライン計測。結果を §ベースライン に追記。
```
