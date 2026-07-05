# リファクタ作戦台帳

最終更新: 2026-07-05 / 状態: R0/R2/R3/R4/R6/R7/R8 完了。R9（cooking_reward_panel 分割）は第1段（Visual抽出）+ 第2段（ステータスストリップ component 化）完了。R5/R1 は釣り場マップ完了、魚図鑑 Palette 移行 + P2素材評価完了（専用素材P2は新規候補待ち）。次候補は R9 第3段（報酬カード節）、R5/R1 次画面

Fable オーケストレーターが本ファイルを正本としてスライス順・状態・ベースラインを管理する。
Composer ワーカーは個別 brief のみ受け取り、本ファイルの更新はオーケストレーターが行う。

関連: `AGENTS.md` §オーケストレーション、`.cursor/rules/orchestration.mdc`、`skills/project-refactor-orchestration/SKILL.md`

## 全体 Definition of Done

- [ ] `./tools/validate_project.sh` が通る
- [ ] 下記 §Smoke 一覧がすべて通る（R0 でベースライン記録済み）
- [ ] `docs/qa/*_qa.md` の freeze 値を変更していない（P1 再発時を除く）
- [ ] UI を触ったスライスは visual QA で退行なし

## Smoke 一覧（headless 実行）

Godot 4.x headless。プロジェクトルートから（`HOME` 隔離で本番セーブを保護）:

```bash
SMOKE_HOME=/tmp/tsuri-smoke-home; mkdir -p "$SMOKE_HOME"
HOME="$SMOKE_HOME" godot --headless --path . res://tools/<scene>.tscn
```

なお `PlayerProgress` は `res://tools/` 配下のシーン起動を検出してセーブ読み書きを無効化する（サンドボックスモード）ため、エディタから直接実行しても本番セーブは書き換わらない。`HOME` 隔離はその二重防護。

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
| `save_system_smoke.tscn` | セーブの原子的書き込み・バックアップ復元・サンドボックス保護（**必ず `./tools/save_system_verify.sh` 経由で実行**） |

一括実行（R0 ベースライン用）:

```bash
SMOKE_HOME=/tmp/tsuri-smoke-home; mkdir -p "$SMOKE_HOME"
for s in fishing_reveal fishing_harbor_return fishing_spot_select shipyard tackle_shop market cooking_flow fish_book status catch_fanfare; do
  echo "=== ${s}_smoke ==="
  HOME="$SMOKE_HOME" godot --headless --path . "res://tools/${s}_smoke.tscn" || exit 1
done
./tools/save_system_verify.sh
./tools/validate_project.sh
```

## スライス計画

| ID | concern | 依存 | 担当 | DoD | 状態 |
|---|---|---|---|---|---|
| R0 | ベースライン計測 | — | Composer | 全 smoke + validate の結果を §ベースラインに記録 | **done (2026-07-05)** |
| R1 | palette 外ハードコード色の洗い出しと修正 | R0 | Composer | `rg` 監査 green、validate + 触った画面 smoke | pending（洗い出しのみ完了: 約932件/22ファイル。機械置換の見た目退行リスクが高く、freeze済み画面のvisual QA前提で画面単位に分割して実施する。2026-07-05: 釣り場マップ2ファイル `src/ui/fishing_spot_select_screen.gd` / `src/ui/components/fishing_spot_map_view.gd` は `Palette.MAP_*` へ移行済み。魚図鑑 `src/ui/fish_book_screen.gd` は `Palette.FISH_BOOK_*` へ移行済み） |
| R2 | showcase 素材参照違反の修正 | R0 | Composer×画面 | `audit_showcase_asset_refs.py` green | **done（監査の結果、現状違反ゼロ。作業不要）** |
| R3 | autoload / core の pure ロジック境界抽出 | R0, Fable 設計 | Composer | 振る舞い不変、該当 smoke green | **done (2026-07-05)** `game_data.gd`（1828行）を `game_catalog_data.gd`（constテーブル15個・約1430行）と `game_data.gd`（ルール定数+エイリアス+ロジック・約430行）に分離。公開APIはconstエイリアスで不変。7テーブルの JSON md5 前後一致で証明 |
| R4 | UI 共通基盤（ScreenBase 等）の整理 | R3, Fable 設計 | Composer | Fable 承認済み設計どおり、全 smoke green | **done (2026-07-05)** `ScreenBase.make_screen_label` を新設し、`_harbor_label` / `_shipyard_label` / `_book_label` / `_status_label` / `_market_label` を1行委譲に統合（呼び出し約120箇所は無変更）。画面固有の shadow/outline 色は引数渡しで screen_base への新規hex持ち込みなし。`GameFontsScript` preload を ScreenBase へ昇格し、継承7画面の重複 const を削除。全10 smoke + validate green |
| R5 | 画面別 UI uplift | R4 | Composer×画面 | 各 `skills/ui-screen-uplift/` + visual QA | 釣り場マップ done (2026-07-05): 詳細`エサ`/`仕掛け`行の省略P1再発を修正し、通常/釣行継続visual QA証拠を `docs/qa/evidence/fishing_spot_map/` に保存。魚図鑑 done (2026-07-05): Palette gate後のvisual QAでP1再発なし、既存portrait候補は現行に明確勝ちせず素材採用見送り（専用素材P2は新規候補待ち）。次画面は pending |
| R6 | 調理フロー4ファイルの重複抽出（定数・StyleBoxヘルパ・皿テクスチャ解決→CookingAssets） | R0 | Composer | behavior-preserving、cooking_flow smoke + visual QA 画像一致、validate green | **done (2026-07-05)** 新規 `src/ui/components/cooking_assets.gd`。STATUS スクショはピクセル一致。RESULT/EXP/LEVELUP は元コードからキャプチャ非決定（アニメーション）のため cmp は参考値、visual QA passed |
| R7 | 画面横断の重複ヘルパ統合と不要コード削除（_format_money 8重複、_load_texture_if_exists、ScreenBase未使用API、extends表記統一） | R0 | Composer | behavior-preserving、全 smoke + validate green | **done (2026-07-05)** `ScreenBase.format_money` / `_anchored_control` / `_place_control` へ統合。見送り: `_last_sfx_path`（smoke が参照）、`shipyard._format_money`（`maxi` で挙動差）、独自ロジック入り `_load_texture_if_exists` 9ファイル |
| R9 | cooking_reward_panel（3,396行）の behavior-preserving 分割 | R8（決定的QAを退行判定に使用） | Composer | 各段で cooking visual QA 連続キャプチャが分割前と cmp 完全一致、cooking_flow smoke + validate green | **第1段 done (2026-07-05)** 内部Visualクラス17個（純描画・panel非依存）を新規 `src/ui/components/cooking_reward_visuals.gd`（1,297行）へ純移動し、panel 側は const エイリアスで参照不変（2,119行に減）。移動塊は空行差以外完全一致を diff で確認。素材監査 allowlist に抽出先を登録。6キャプチャがベースライン cmp 全一致。**第2段 done (2026-07-05)** ステータスストリップ節を `src/ui/components/cooking_reward_status_strip.gd`（296行、HBoxContainer component）へ抽出し panel は 1,796行に減。共有ヘルパ5つ+素材パス4定数を `CookingAssets` static へ昇格、`ScreenBase.make_label`/`make_body_label`/`make_shadow_label` を static 化（component からの利用を解禁、呼び出し側無変更）。panel の `_preview_state` 依存は `set_secondary(bool)` 注入に置換。6キャプチャがベースライン cmp 全一致。第3段（報酬カード節 約460行）は pending |
| R8 | QA決定性（`TSURI_QA_DETERMINISTIC=1` で調理visual QAをピクセル決定的に）+ cooking_flow_smoke の ok 出力 | R0 | Composer | 連続2回実行で全状態 cmp 一致、フラグOFF時のパス不変 | **done (2026-07-05)** 原因は Tween入退場・Juicer trauma/hit_stop・GaugeBar の `_process` 補間。ガードは `ScreenBase.is_qa_deterministic()` に集約。オーケストレーターが独立に2回実行し6キャプチャ全一致を追認済み |

**fan-out 向き**: R0、R1（ファイル単位）、R2（画面単位）、R5（画面単位・並列可）、R6/R7（ファイル集合が素で並列可）  
**Fable 単体向き**: R3/R4 の設計判断、サブタスクに名前を付けられない調査

### R5 選定ログ

- 2026-07-05: 最初のR5対象は釣り場マップ。`docs/qa/fishing_spot_map_qa.md` が「アップリフト進行中」かつ証拠画像の永続化TODOあり、`docs/19` §8.5のvisual QA継続運用対象で、`tools/fishing_spot_map_visual_qa.sh` / `fishing_spot_select_smoke.tscn` が既に揃っているため。
- 2026-07-05: 新規Palette定数は `Palette.MAP_*`（`MAP_BG_*` / `MAP_DETAIL_*` / `MAP_FOOTER_*` / `MAP_ENTRY_*` / `MAP_CHART_*` / `MAP_ROUTE_*` / `MAP_CHIP_*` など）。理由: 釣り場マップ固有の海図・羊皮紙・ロック状態・航路発光色が既存Paletteに用途名として存在せず、表示色を変えずに画面単位R1移行するため。
- 2026-07-05: 2画面目のR5対象は魚図鑑。`docs/qa/fish_book_qa.md` に残P2（専用魚ポートレート素材）と `docs/24_fish_book_portrait_asset_brief.md` の評価手順が整理済みで、`tools/fish_book_visual_qa.sh` / `fish_book_smoke.tscn` が揃っており、Palette移行対象も `src/ui/fish_book_screen.gd` 中心に限定できるため。
- 2026-07-05: 魚図鑑の新規Palette定数は `Palette.FISH_BOOK_*`。理由: 魚図鑑の台帳紙面・セピア罫線・魚ポートレートtint/影・索引ボタン色は freeze済みの画面固有値が多く、既存Paletteへ近似せず表示色同値でR1移行するため。

### 監査で確認したが今回見送った項目（2026-07-05）

- ~~ラベル生成ラッパー統合（`_harbor_label` / `_shipyard_label` / `_book_label` 等）~~: R4 として 2026-07-05 実施済み
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
