# 28. 「港へ戻る」ボタン配置統一 実装指示書

Date: 2026-07-05
状態: 未着手（Codex 実装用）
発端: 画面ごとに「港へ戻る」の位置がバラバラで、プレイヤーが毎回ボタンを探す必要がある。

## 結論（規約）

**画面右下 = 「港へ戻る」** を全画面共通の規約とする。

2026-07-05 時点の調査で、7画面中5画面はすでに右下配置に収まっており、外れているのは**魚市場**と**造船所**の2画面のみ。この2画面のボタン位置だけを右下へ移せば規約が完成する。見た目（スタイル）の共通化は本件のスコープ外（位置のみ動かす）。

## 現状調査結果（2026-07-05）

1280x720 基準。

| 画面 | 現在の位置 | 実装箇所 | 判定 |
|---|---|---|---|
| 魚図鑑 | 右下フッター | `src/ui/fish_book_screen.gd:371`（`make_return_button`） | 規約準拠。freeze済み（`docs/qa/fish_book_qa.md`）。**触らない** |
| ステータス | 右下フッター | `src/ui/status_screen.gd:243`（`make_return_button`） | 規約準拠。触らない |
| 釣具屋 | 右下 `Rect2(958, 650, 196, 44)` | `src/ui/shop_screen.gd:319` | 規約準拠。freeze済み（`docs/qa/tackle_shop_qa.md`「下部右」）。**触らない** |
| 釣り場マップ | 右側詳細パネル最下段 | `src/ui/fishing_spot_select_screen.gd:362` | 規約準拠（右下領域）。ボタン高さ50pxはfreeze。触らない |
| 調理（結果） | フッター右端 | `src/ui/components/cooking_status_panel.gd:705` | 規約準拠。触らない |
| **魚市場** | **左下** `RETURN_RECT = Rect2(52, 666, 132, 40)` | `src/ui/market_screen.gd:33` / `:371` | **移動対象（スライス1）** |
| **造船所** | **左下** アンカー `0.018–0.152 × 0.912–0.976` | `src/ui/shipyard_screen.gd:263` | **移動対象（スライス2）** |
| 釣り中 | HUDメニュー＋確認オーバーレイ | `src/ui/fishing_screen.gd` / `components/fight_hud.gd` | **対象外**。釣行中断は確認ダイアログ必須のため別系統が正 |

## スコープ外（やらないこと）

- 釣り中画面の港戻り導線の変更（確認オーバーレイの仕組みは意図的な設計）
- ボタンのスタイル・素材の共通化（市場・造船所は画面固有のボタンアートを維持する）
- 上記表で「規約準拠」の5画面への変更（freeze値に触れるため）
- `ScreenBase.make_return_button()` 本体の変更（`docs/qa/fish_book_qa.md` のfreezeで本体変更禁止）

---

## スライス1: 魚市場

### 1 concern

`MarketReturnButton` を左下から右下（「まとめて売る」ボタンの下）へ移動する。それ以外の変更をしない。

### 触ってよいファイル

- `src/ui/market_screen.gd`（`RETURN_RECT` 定数の値変更のみが理想）
- `docs/qa/fish_market_qa.md`（判断ログ・freeze表の追記）
- `docs/qa/evidence/fish_market/`（比較画像のコピー先）

### 触ってはいけないもの

- `docs/qa/fish_market_qa.md` の既存freeze値（確認オーバーレイのz-index等）
- `CART_ACTION_RECT`（まとめて売る `Rect2(1008, 612, 190, 50)`）の位置・サイズ
- ボタンのスタイル（`_market_button()` の見た目）、`name`（`MarketReturnButton`）、`set_meta("harbor_return", true)`、`navigate("harbor")` の挙動
- 他画面のファイル

### 変更内容

`src/ui/market_screen.gd:33` の定数を変更する。

```gdscript
# 変更前
const RETURN_RECT := Rect2(52.0, 666.0, 132.0, 40.0)
# 変更後（初期値。実スクショで最終判断）
const RETURN_RECT := Rect2(1066.0, 670.0, 132.0, 40.0)
```

初期値の意図: 右端を「まとめて売る」と揃え（1066+132 = 1008+190 = 1198）、上に8pxの誤タップ余白、下に10pxの画面マージン。

注意点:

- 「まとめて売る」は主役ボタン（gold相当）で、その直下に置くため誤タップ余白を必ずスクショで確認する。「まとめて売る」は確認オーバーレイを挟むので誤タップの実害は小さいが、8px未満に詰めない。
- カートパネルの枠素材と重なって見える場合は y を 720 側へ数px逃がしてよい（微調整は3回まで。`docs/qa/fish_market_qa.md` の微調整カウンタに記録）。
- 左下が空くことで違和感が出ないか、4状態スクショ全部で確認する。

### Definition of Done

1. `./tools/market_visual_qa.sh` を実行し、4状態（select / confirm / sold / empty）のスクショが再生成される（出力: `/tmp/tsuri_market_*.png`）
2. 4状態すべてで「港へ戻る」が右下に収まり、「まとめて売る」・カート枠・確認オーバーレイと重ならない（**実スクショの目視で判断**。コード上の座標を根拠にしない）
3. `godot --headless` で `tools/market_smoke.tscn` が pass
4. `./tools/validate_project.sh` が green
5. `docs/qa/fish_market_qa.md` に判断ログを追記し、採用した `RETURN_RECT` をfreeze表へ記載。判断根拠の比較画像を `docs/qa/evidence/fish_market/` へ日付付きファイル名でコピー（`/tmp` のみに残さない）

### 報告フォーマット

変更概要（採用した最終Rect値）/ 実行結果（DoD 1–4の結果）/ 未解決（あれば）

---

## スライス2: 造船所

### 1 concern

造船所フッターの「港へ戻る」を左下から右下へ移動する。それ以外の変更をしない。

### 触ってよいファイル

- `src/ui/shipyard_screen.gd`（`_build_footer()` 内の配置アンカーのみ）
- `docs/qa/shipyard_qa.md`（**新規作成**。書式は `docs/qa/README.md` のテンプレート）
- `docs/qa/evidence/shipyard/`（新規作成。比較画像のコピー先）

### 触ってはいけないもの

- ボタンの見た目（`_image_text_button()`）、`set_meta("shipyard_return", true)`、`navigate("harbor")` の挙動
- `_footer_label`（アンカー `0.270–0.768`）と右側の航路パネル群（`0.746–0.976 × 〜0.895`）の位置
- 他画面のファイル

### 変更内容

`src/ui/shipyard_screen.gd:263` の配置アンカーを変更する。

```gdscript
# 変更前
_place_control(root, back, 0.018, 0.912, 0.152, 0.976)
# 変更後（初期値。実スクショで最終判断）
_place_control(root, back, 0.842, 0.912, 0.976, 0.976)
```

初期値の意図: 幅 0.134（現行と同じ）を維持し、右端を航路パネル・ロックラベルの右端 0.976 に揃える。y帯は現行フッターと同じ。

注意点:

- 直上の `_route_locked_label`（`0.898–0.976 × 0.857–0.895`）と縦に近接する。ロック表示が出る状態のスクショで窮屈に見えないか確認する。
- 左下が空いて footer 全体のバランスが崩れて見える場合も、`_footer_label` は動かさない（別スライスの判断とする）。報告の「未解決」に所見を書く。

### Definition of Done

1. `godot --headless` で `tools/shipyard_preview.tscn` を実行し、`/tmp/tsuri_shipyard_screen.png` が再生成される
2. スクショ目視で「港へ戻る」が右下に収まり、航路パネル・ロックラベル・フッターラベルと重ならない
3. `godot --headless` で `tools/shipyard_smoke.tscn` が pass
4. `./tools/validate_project.sh` が green
5. `docs/qa/shipyard_qa.md` を `docs/qa/README.md` テンプレートで新規作成し、採用アンカーをfreeze表へ記載。スクショを `docs/qa/evidence/shipyard/` へ日付付きでコピー

### 報告フォーマット

変更概要（採用した最終アンカー値）/ 実行結果（DoD 1–4の結果）/ 未解決（あれば）

---

## 両スライス完了後（オーケストレーター側の作業）

1. diff レビュー（ワーカー報告を信じず実スクショと突き合わせる）
2. `docs/19_ui_production_playbook.md` のスタイルガイドへ規約を1行追記する:
   「港へ戻る導線は画面右下に置く（規約。詳細と経緯は docs/28）」
3. 本書の「状態:」を「完了（YYYY-MM-DD）」へ更新する
