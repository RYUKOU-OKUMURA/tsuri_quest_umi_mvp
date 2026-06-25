# 12. 調理ショーケース QA

対象ブランチ: `codex/cooking-showcase-flow`

目的: `reference/03_cooking_levelup_mockup.png` と `reference/cooking_flow/*` を、単一画面ではなく状態分割された調理フローの品質基準として使う。

## 状態別ゲート

| 状態 | 実装 | 現在判定 | Freeze 条件 |
|---|---|---|---|
| `COOK_SELECT` | `src/ui/cooking_screen.gd` | P2: 専用カードUI・料理画像・魚アイコンは入った。headless layout auditで1280x720内のはみ出し/縦クリップなしを確認済み。視覚スクショで密度確認が必要。 | 魚/料理/詳細/調理ボタンが1280x720で衝突せず、stock listに見えない。 |
| `MEAL_RESULT` | `src/ui/components/cooking_reward_panel.gd` | P2: 専用報酬オーバーレイで料理/EXP/初回/バフを分離済み。食事/EXP/成長の進行ストリップを追加。headless layout audit通過。視覚スクショ未確認。 | 食べた料理、EXP、初回ボーナス、バフが本文を読まなくても追える。 |
| `EXP_GAIN` | `src/ui/components/cooking_reward_panel.gd` | P2: EXPゲージ演出と大きな+EXP表示を持つ。headless smokeで非レベルアップ完結パス、layout auditで1280x720収まりを確認済み。視覚スクショ未確認。 | EXPメーターが主役で、レベルアップしない場合も完結感がある。 |
| `LEVEL_UP_OVERLAY` | `src/ui/components/level_up_panel.gd` | P2: 大型報酬パネル、before/after、Lv.5解放カードあり。能力アイコンをフォント依存の記号からASCIIバッジへ置換済み。headless layout audit通過。視覚スクショ未確認。 | レベル遷移、能力上昇、ぬし解放が最も強い報酬瞬間として読める。 |
| `STATUS_SUMMARY` | `src/ui/components/cooking_status_panel.gd` | P2: 詳細ボタンから要約オーバーレイを開ける。headless layout audit通過。視覚スクショ未確認。 | Lv/EXP、能力、効果中料理、クーラー、所持金、プレイ時間がカードで読める。 |

## 検証ログ

- `HOME=/private/tmp/tsuri_home tools/validate_project.sh`
  - 結果: 成功。
  - 範囲: Godot editor import と短時間起動。GDScriptロード、autoload、シーン初期化の大枠を確認。
- `HOME=/private/tmp/tsuri_home "/Applications/Godot.app/Contents/MacOS/Godot" --headless --path ... res://tools/cooking_preview.tscn`
  - 結果: 失敗。
  - 理由: headless/dummy renderer では `SubViewport.get_texture().get_image()` が null になる既知制約。
  - 判定: 視覚スクショは未取得。通常Godot起動可能な環境で `/tmp/tsuri_cooking_*.png` を再生成して比較する。
- `HOME=/private/tmp/tsuri_home "/Applications/Godot.app/Contents/MacOS/Godot" --path ... res://tools/cooking_preview.tscn`
  - 結果: 失敗。
  - 理由: この実行環境では通常Godot起動が即時に exit 134 で終了する。
  - 判定: 通常描画スクショはこの環境では未取得。headless layout auditとsmokeで先に機械的なP1を潰す。
- `tools/cooking_flow_smoke.tscn`
  - 目的: headlessで各状態のControl構築を検証するためのスモークシーン。
  - コマンド: `HOME=/private/tmp/tsuri_home "/Applications/Godot.app/Contents/MacOS/Godot" --headless --path ... res://tools/cooking_flow_smoke.tscn`
  - 結果: 成功。
  - 範囲: `COOK_SELECT`、非レベルアップEXP報酬、レベルアップ報酬、報酬OK後の`LEVEL_UP_OVERLAY`接続、単体レベルアップ、ステータス要約のControl構築と短時間実行。
- `tools/cooking_layout_audit.tscn`
  - 目的: headlessで5状態を1280x720固定ステージに構築し、画面外はみ出し、非正サイズ、ラベル縦クリップ、欠落テクスチャを検出する。
  - コマンド: `HOME=/private/tmp/tsuri_home "/Applications/Godot.app/Contents/MacOS/Godot" --headless --path ... res://tools/cooking_layout_audit.tscn`
  - 結果: 成功。
  - 範囲: `COOK_SELECT`、`EXP_GAIN`、`MEAL_RESULT`、`LEVEL_UP_OVERLAY`、`STATUS_SUMMARY`。

## 未解決

- P1: 現時点で既知のロジック破壊はなし。headless layout audit上の画面外はみ出し/縦クリップは解消済み。ただし実スクショ未取得のため、最終的な視覚密度、ピクセル単位の重なり、装飾の見え方は未証明。
- P2: 生成アセットは実装用の差し替えスロットであり、最終本番アートではない。料理・魚・背景は後続で品質差し替え余地あり。
- P3: steam/sparkle/粒子などの小演出は、状態別スクショでP1/P2が潰れてから追加する。
