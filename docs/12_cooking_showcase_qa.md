# 12. 調理ショーケース QA

対象ブランチ: `codex/cooking-showcase-flow`

目的: `reference/03_cooking_levelup_mockup.png` と `reference/cooking_flow/*` を、単一画面ではなく状態分割された調理フローの品質基準として使う。

## 状態別ゲート

| 状態 | 実装 | 現在判定 | Freeze 条件 |
|---|---|---|---|
| `COOK_SELECT` | `src/ui/cooking_screen.gd` | P2: 専用カードUI・料理画像・魚アイコンに加え、魚行に選択マーカーと`status_card_frame.png`、料理一覧に`recipe_grid_frame.png`、料理カードに`recipe_card_frame.png`、右詳細に`dish_detail_frame.png`の9スライス枠を適用。headless layout auditで1280x720内のはみ出し/縦クリップなしを確認済み。視覚スクショで密度確認が必要。 | 魚/料理/詳細/調理ボタンが1280x720で衝突せず、stock listに見えない。魚行と料理カードの選択/未選択/ロック状態が識別できる。 |
| `MEAL_RESULT` | `src/ui/components/cooking_reward_panel.gd` | P2: 専用報酬オーバーレイで料理/基本EXP/初回/合計/バフを分離済み。食事/EXP/成長の進行ストリップと、料理が食経験値・次回効果へ変わる橋渡し文、`meal_scene_bg.png`の食事背景、湯気/きらめきの控えめな報酬演出、`meal_result_frame.png`の9スライス枠を追加。headless layout audit通過。視覚スクショ未確認。 | 食べた料理、基本EXP、初回ボーナス、合計獲得、バフが本文を読まなくても追える。 |
| `EXP_GAIN` | `src/ui/components/cooking_reward_panel.gd` | P2: EXPゲージ演出と大きな+EXP表示を持つ。基本EXP/初回/合計を分離し、レベルアップ時は報酬パネル上でも`Lv.X -> Lv.Y`を予告、Lv.5到達時は`ぬし解放`へつながることを先出しして、食事結果からEXP/成長へのつながりを強化。Lv到達時は料理名つきで食経験値が成長を後押ししたことを明示し、食事背景と小演出で選択フォームから報酬場面へ切り替わる。headless smokeで非レベルアップ完結パス、layout auditで1280x720収まりを確認済み。視覚スクショ未確認。 | EXPメーターが主役で、レベルアップしない場合も完結感がある。レベルアップする場合は次の報酬演出へ進む理由が明確に読める。 |
| `LEVEL_UP_OVERLAY` | `src/ui/components/level_up_panel.gd` | P2: 大型報酬パネル、before/after、Lv.5解放カードあり。能力アイコンをフォント依存の記号からASCIIバッジへ置換し、`level_up_frame.png`の9スライス枠を適用済み。食経験値が成長に変わった副題と、食事でLv.5到達した解放文を追加。headless layout audit通過。視覚スクショ未確認。 | レベル遷移、能力上昇、ぬし解放が最も強い報酬瞬間として読める。 |
| `STATUS_SUMMARY` | `src/ui/components/cooking_status_panel.gd` | P2: 詳細ボタンから要約オーバーレイを開ける。能力/要約カードに`status_card_frame.png`の9スライス枠を適用し、効果中料理カードに料理画像を追加済み。headless layout audit通過。視覚スクショ未確認。 | Lv/EXP、能力、効果中料理、クーラー、所持金、プレイ時間がカードで読める。効果中料理が文字だけでなく料理ビジュアルでも追える。 |

## 検証ログ

- `tools/cooking_verify.sh`
  - 目的: 調理ショーケースのheadlessゲートを一括実行する。内容監査、1280x720レイアウト監査、実フローsmokeを順に走らせる。
  - コマンド: `tools/cooking_verify.sh`
  - 結果: 成功。
  - 範囲: `tools/cooking_content_audit.tscn`、`tools/cooking_layout_audit.tscn`、`tools/cooking_flow_smoke.tscn`。
- `HOME=/private/tmp/tsuri_home tools/validate_project.sh`
  - 結果: 成功。
  - 範囲: Godot editor import と短時間起動。GDScriptロード、autoload、シーン初期化の大枠を確認。
- `HOME=/private/tmp/tsuri_home "/Applications/Godot.app/Contents/MacOS/Godot" --headless --path ... res://tools/cooking_preview.tscn`
  - 結果: 失敗。
  - 理由: headless/dummy renderer では `SubViewport.get_texture().get_image()` が null になる既知制約。`tools/cooking_preview.gd` は `DisplayServer.get_name() == "headless"` を検出して明示診断を出す。
  - 判定: 視覚スクショは未取得。通常Godot起動可能な環境で `/tmp/tsuri_cooking_*.png` を再生成して比較する。
- `HOME=/private/tmp/tsuri_home "/Applications/Godot.app/Contents/MacOS/Godot" --path ... res://tools/cooking_preview.tscn`
  - 結果: 失敗。
  - 理由: この実行環境では通常Godot起動が即時に exit 134 で終了する。
  - 判定: 通常描画スクショはこの環境では未取得。headless layout auditとsmokeで先に機械的なP1を潰す。
- `HOME=/private/tmp/tsuri_home "/Applications/Godot.app/Contents/MacOS/Godot" --headless --write-movie /tmp/tsuri_cooking_movie.png --quit-after 10 --fixed-fps 10 --path ... res://tools/cooking_preview.tscn`
  - 結果: 失敗。
  - 理由: movie makerもheadless/dummy rendererでは実フレームを生成できず、同じnull texture経路に入る。
  - 判定: `--write-movie` はこの環境での代替スクショ経路として使えない。
- `tools/cooking_flow_smoke.tscn`
  - 目的: headlessで各状態のControl構築を検証するためのスモークシーン。
  - コマンド: `HOME=/private/tmp/tsuri_home "/Applications/Godot.app/Contents/MacOS/Godot" --headless --path ... res://tools/cooking_flow_smoke.tscn`
  - 結果: 成功。
  - 範囲: `COOK_SELECT`、非レベルアップEXP報酬、レベルアップ報酬、報酬OK後の`LEVEL_UP_OVERLAY`接続、実際の`PlayerProgress.cook_and_eat()`経由での魚消費/初回料理記録/食事バフ/Lv.5到達/報酬OK後のレベルアップ接続、単体レベルアップ、ステータス要約のControl構築と短時間実行。
- `tools/cooking_layout_audit.tscn`
  - 目的: headlessで5状態を1280x720固定ステージに構築し、画面外はみ出し、非正サイズ、ラベル縦クリップ、欠落テクスチャを検出する。
  - コマンド: `HOME=/private/tmp/tsuri_home "/Applications/Godot.app/Contents/MacOS/Godot" --headless --path ... res://tools/cooking_layout_audit.tscn`
  - 結果: 成功。
  - 範囲: `COOK_SELECT`、`EXP_GAIN`、`MEAL_RESULT`、`LEVEL_UP_OVERLAY`、`STATUS_SUMMARY`。
- `tools/cooking_content_audit.tscn`
  - 目的: headlessで5状態を構築し、料理名、材料、EXP、食事効果、成長予告、Lv.5解放、ステータス要約などの必須表示テキストが画面上に存在することを検出する。
  - コマンド: `HOME=/private/tmp/tsuri_home "/Applications/Godot.app/Contents/MacOS/Godot" --headless --path ... res://tools/cooking_content_audit.tscn`
  - 結果: 成功。
  - 範囲: `COOK_SELECT`、`EXP_GAIN`、`MEAL_RESULT`、`LEVEL_UP_OVERLAY`、`STATUS_SUMMARY`。視覚スクショの代替ではなく、表示情報欠落の回帰防止。

## 未解決

- P1: 現時点で既知のロジック破壊はなし。headless layout audit上の画面外はみ出し/縦クリップは解消済み。ただし実スクショ未取得のため、最終的な視覚密度、ピクセル単位の重なり、装飾の見え方は未証明。
- P2: 生成フレーム/背景アセットの主要接続は進んだが、生成アセットは実装用の差し替えスロットであり、最終本番アートではない。料理・魚・背景は後続で品質差し替え余地あり。魚行とレシピカードは専用フレーム接続済みだが、視覚スクショで選択/ロック状態の見え方を確認する必要がある。
- P3: steam/sparkle/粒子などの小演出は、状態別スクショでP1/P2が潰れてから追加する。
