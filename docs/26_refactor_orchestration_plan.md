# リファクタ作戦台帳

最終更新: 2026-07-05 / 状態: R0/R2/R3/R6/R7/R8 完了。次候補は R4（UI共通基盤）、R5/R1（画面単位 uplift + Palette 移行の同時実施）、cooking_reward_panel 分割

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
| R0 | ベースライン計測 | — | Composer | 全 smoke + validate の結果を §ベースラインに記録 | **done (2026-07-05)** |
| R1 | palette 外ハードコード色の洗い出しと修正 | R0 | Composer | `rg` 監査 green、validate + 触った画面 smoke | pending（洗い出しのみ完了: 約932件/22ファイル。機械置換の見た目退行リスクが高く、freeze済み画面のvisual QA前提で画面単位に分割して実施する） |
| R2 | showcase 素材参照違反の修正 | R0 | Composer×画面 | `audit_showcase_asset_refs.py` green | **done（監査の結果、現状違反ゼロ。作業不要）** |
| R3 | autoload / core の pure ロジック境界抽出 | R0, Fable 設計 | Composer | 振る舞い不変、該当 smoke green | **done (2026-07-05)** `game_data.gd`（1828行）を `game_catalog_data.gd`（constテーブル15個・約1430行）と `game_data.gd`（ルール定数+エイリアス+ロジック・約430行）に分離。公開APIはconstエイリアスで不変。7テーブルの JSON md5 前後一致で証明 |
| R4 | UI 共通基盤（ScreenBase 等）の整理 | R3, Fable 設計 | Composer | Fable 承認済み設計どおり、全 smoke green | pending |
| R5 | 画面別 UI uplift | R4 | Composer×画面 | 各 `skills/ui-screen-uplift/` + visual QA | pending |
| R6 | 調理フロー4ファイルの重複抽出（定数・StyleBoxヘルパ・皿テクスチャ解決→CookingAssets） | R0 | Composer | behavior-preserving、cooking_flow smoke + visual QA 画像一致、validate green | **done (2026-07-05)** 新規 `src/ui/components/cooking_assets.gd`。STATUS スクショはピクセル一致。RESULT/EXP/LEVELUP は元コードからキャプチャ非決定（アニメーション）のため cmp は参考値、visual QA passed |
| R7 | 画面横断の重複ヘルパ統合と不要コード削除（_format_money 8重複、_load_texture_if_exists、ScreenBase未使用API、extends表記統一） | R0 | Composer | behavior-preserving、全 smoke + validate green | **done (2026-07-05)** `ScreenBase.format_money` / `_anchored_control` / `_place_control` へ統合。見送り: `_last_sfx_path`（smoke が参照）、`shipyard._format_money`（`maxi` で挙動差）、独自ロジック入り `_load_texture_if_exists` 9ファイル |
| R8 | QA決定性（`TSURI_QA_DETERMINISTIC=1` で調理visual QAをピクセル決定的に）+ cooking_flow_smoke の ok 出力 | R0 | Composer | 連続2回実行で全状態 cmp 一致、フラグOFF時のパス不変 | **done (2026-07-05)** 原因は Tween入退場・Juicer trauma/hit_stop・GaugeBar の `_process` 補間。ガードは `ScreenBase.is_qa_deterministic()` に集約。オーケストレーターが独立に2回実行し6キャプチャ全一致を追認済み |

**fan-out 向き**: R0、R1（ファイル単位）、R2（画面単位）、R5（画面単位・並列可）、R6/R7（ファイル集合が素で並列可）  
**Fable 単体向き**: R3/R4 の設計判断、サブタスクに名前を付けられない調査

### 監査で確認したが今回見送った項目（2026-07-05）

- ラベル生成ラッパー統合（`_harbor_label` / `_shipyard_label` / `_book_label` 等）: フォントAA方針は 2026-07-05 に `game_fonts.gd`（AA有効）へ統一決定済み（docs/19 §4.2、`fight_fonts.gd` 削除）。ラッパー統合自体は R4（UI共通基盤整理）で実施可能になった
- BGM 二重実装（`main.gd` の opening BGM と `ScreenBase.play_screen_bgm`）: main.gd は ScreenBase 非継承で境界設計が必要。Fable 単体向き
- `PlayerProgress` の emit-only シグナル（`progress_changed` 等）: 拡張点として温存。削除しない判断
- `fight_hud` 等 fight 系コンポーネントの hex 色: R1 へ

## ベースライン（R0 完了後に記録）

Godot v4.7.stable.official（`/Applications/Godot.app/Contents/MacOS/Godot`）で計測。

| チェック | 日付 | 結果 | 備考 |
|---|---|---|---|
| validate_project.sh | 2026-07-05 | green (exit 0) | 終了時 ObjectDB 2件リーク / resource 1件残存の警告あり |
| fishing_reveal_smoke | 2026-07-05 | green | |
| fishing_harbor_return_smoke | 2026-07-05 | green | ObjectDB 2件リーク / resource 1件残存 |
| fishing_spot_select_smoke | 2026-07-05 | green | ObjectDB 3件リーク / resource 1件残存 |
| shipyard_smoke | 2026-07-05 | green | |
| tackle_shop_smoke | 2026-07-05 | green | |
| market_smoke | 2026-07-05 | green | |
| cooking_flow_smoke | 2026-07-05 | green | 成功時の `ok` print がない唯一の smoke（観測性の改善候補） |
| fish_book_smoke | 2026-07-05 | green | |
| status_smoke | 2026-07-05 | green | |
| catch_fanfare_smoke | 2026-07-05 | green | ObjectDB 6件リーク / resource 2件残存 |

既知の警告（ベースライン時点から存在。リファクタの退行判定には使わない）: ObjectDB リーク、`Could not create ObjectDB Snapshots directory`。

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
