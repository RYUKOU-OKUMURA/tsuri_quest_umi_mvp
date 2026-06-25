# 12. 調理ショーケース QA

対象ブランチ: `codex/cooking-showcase-flow`

目的: `reference/03_cooking_levelup_mockup.png` と `reference/cooking_flow/*` を、単一画面ではなく状態分割された調理フローの品質基準として使う。

## 5枚リファレンス方針

`reference/cooking_flow/` の5枚を状態別の正リファレンスとして扱う。新規に完成イメージを生成し直さず、既存の途中実装は保持したうえで、以下の差分を順に埋める。

| 状態 | 正リファレンス | 現実装との差分 | 次の実装方針 |
|---|---|---|---|
| `COOK_SELECT` | `reference/cooking_flow/01_cook_select_concept.png` | 3カラム構成とカードUIは近い。料理一覧は3列グリッドへ寄せ、選択魚に使えない料理も`素材違い`カードとして出して、参照の3x2に近い密度へ改善した。ヘッダーのプレイヤー/所持金カードと下部ステータス帯には、プレイヤー、コイン、料理、クーラー、料理図鑑の小アイコンを追加し、調理前の現在状態を文字だけでなく絵として読める方向へ寄せた。今回の参照再確認では、右詳細がまだ6タイルの情報カード寄りで、参照画像の「大判料理写真、材料行、獲得EXP行、次回効果行、主ボタン」の縦ストーリーに弱いことをP2差分として確認。 | 右詳細を、料理写真の額装、材料/所持数、EXP/初回、食事効果/回数の横長行へ組み直す。3列料理グリッドと5枚以上のカード表示はlayout auditで固定する。 |
| `MEAL_RESULT` | `reference/cooking_flow/02_meal_result_concept.png` | 左に食事シーン、右上に大きな「食べた」バナー、右中に今回の料理、下に4報酬カードを置く専用食事シーンへ寄せた。報酬カードにはEXP/初回/合計/次回効果の種類別小アイコンを追加し、参照のカード単位の読み分けに近づけた。さらに下部に`プレイヤーLv.` / `効果中の料理` / `クーラーボックス` / `所持金`の4分割ステータス帯を追加し、参照の「食べた結果が今の準備へ反映された」文脈に寄せた。英字プレースホルダはなくし、左カードには簡易の食事中キャラ/椀/湯気ビジュアルを描画する。差分は、本番キャラ/食卓アート、湯気や祝福演出の密度。 | 次は食卓/人物/料理/報酬カードの仮アートを専用素材へ置き換え、実スクショで参照画像との密度差を確認する。下部ステータス帯はcontent/layout auditで固定する。 |
| `EXP_GAIN` | `reference/cooking_flow/03_exp_gain_concept.png` | EXP状態では右ペインを料理詳細カードからEXPフォーカスカードへ差し替え、巨大`+EXP`、before/after数値、明るいゲージ、短いキャラメッセージを主役にした。補助報酬カードは種類別小アイコン付きで横一列に圧縮し、下部に`プレイヤーLv.` / `効果中の料理` / `クーラーボックス` / `所持金`のステータス帯を追加済み。英字プレースホルダはなくし、左カードには料理から力が出る簡易ビジュアルを描画し、左の料理カードから右のEXPカードへ流れる`ExpEnergyTrail`も追加した。さらにEXP時だけ右側に`次の釣行で効果！`専用カードを追加し、効果名、効果説明、発動時間、魚/上昇演出を上段で読めるようにした。今回の参照再確認では、中央`+EXP`とゲージ背後の放射光・瞬間的な光量がまだ弱く、参照の報酬ピークに届いていないことをP2差分として確認。 | EXPフォーカスカード内に放射バースト、ゲージフラッシュ、星粒を追加し、`+EXP`とゲージが報酬状態の主役として読めるようにする。1280x720で文字クリップなしはフリーズ条件として維持する。 |
| `LEVEL_UP_OVERLAY` | `reference/cooking_flow/04_level_up_overlay_concept.png` | 2列ステータス、赤い解放リボン、王冠/メダル/釣り場サムネ風の描画ビジュアル、紙吹雪/星/金色光線を専用パネル内へ追加済み。英字プレースホルダは削除し、`成長の証`、`挑戦解放`、`新釣り場`、`港の大岩`などの和文タグに置換した。今回、王冠付きタイトル帯を左右ラウレル付きに再構成し、`LEVEL UP!`のサイズと金装飾を強めた。赤い解放リボンとボスメダルも大きくし、Lv.5報酬がフロー最大のピークとして読める方向へ寄せた。差分は、本番王冠/金ラウレル/ボスメダル/海辺サムネイル素材の密度と、背景選択画面が暗転越しにどの程度読めるかの実スクショ確認。 | 次は実スクショで中央報酬パネルの占有率、背面暗転、紙吹雪の密度を確認し、必要なら王冠/メダル/釣り場サムネを `assets/showcase/cooking/` の専用素材へ差し替える。1280x720で情報が収まる現状レイアウトはフリーズ条件として維持する。 |
| `STATUS_SUMMARY` | `reference/cooking_flow/05_status_summary_concept.png` | 小さな要約モーダルから、全画面の専用サマリー状態へ再構成済み。5カード内の`PLAYER`/`COOLER`/`GOLD`/`TIME`/`READY`英字プレースホルダは、簡易のプレイヤー、クーラーボックス、所持金、時計、釣り支度ビジュアルへ置換した。上部ヘッダー、5枚の大型縦カード、下部メッセージバー、`港へ戻る`導線は参照構成に寄った。今回、背景に港側の明るい景色と厨房側の室内シルエットを重ね、ヘッダー左右に船舵/錨の描画装飾を追加した。差分は、5カード内の本番カードアートと背景素材そのものの密度、実スクショでの装飾の見え方。 | 次は実スクショで参照密度とカード余白を確認し、必要なら5カード内イラストとステータス背景を `assets/showcase/cooking/` の専用素材へ差し替える。5カードの1280x720収まりはフリーズ条件として維持する。 |

この差分表は、実スクリーンショット取得前の暫定比較であり、次回以降は `/tmp/tsuri_cooking_*.png` が取れ次第、各正リファレンスと並べて更新する。

## 状態別ゲート

| 状態 | 実装 | 現在判定 | Freeze 条件 |
|---|---|---|---|
| `COOK_SELECT` | `src/ui/cooking_screen.gd` | P2: 専用カードUI・料理画像・魚アイコンに加え、魚行に選択マーカーと`status_card_frame.png`、料理一覧に`recipe_grid_frame.png`、料理カードに`recipe_card_frame.png`、右詳細に`dish_detail_frame.png`の9スライス枠を適用。料理一覧は3列化し、選択魚に非対応の料理は`素材違い`カードとして残すことで、参照の3x2料理カード密度へ近づけた。選択中カードは`選択中 / 40 EXP 初回`と表示し、右詳細の初回込みEXPと一致させた。ロック中料理は`？？？` / `未解放 Lv.5`で表示し、選択可能カードとの差を明確化。右詳細は参照画像との差分として、6タイル表示ではなく、料理写真、材料/所持数、食経験値/初回、次の釣行効果/効果回数、既存効果上書き、調理ボタンへ視線が落ちる構成へ寄せる。ヘッダーと下部ステータス帯にはプレイヤー/所持金/料理/クーラーなどの小アイコンを追加済み。headless layout auditで3列/5カード以上と1280x720内のはみ出し/縦横クリップなしを確認済み。視覚スクショで密度確認が必要。 | 魚/料理/詳細/調理ボタンが1280x720で衝突せず、stock listに見えない。魚行と料理カードの選択/未選択/素材違い/ロック状態が識別できる。 |
| `MEAL_RESULT` | `src/ui/components/cooking_reward_panel.gd` | P2: `02_meal_result_concept.png` に合わせ、左に食事シーン、右に「食べた！」バナーと今回の料理、下に基本EXP/初回/合計/次回効果の4報酬カードを置く専用レイアウトへ再構成。`MEAL_RESULT`ではEXPゲージと成長行を隠し、`EXP加算へ`で次状態へ送ることで、食事の余韻とEXP加算を別ビートに分離した。報酬カードには種類別小アイコンを追加し、下部にはプレイヤーLv/効果中料理/クーラーボックス/所持金のステータス帯を追加。左カードの`PLAYER EATING`英字プレースホルダは削除し、食事中キャラ/椀/湯気の簡易ビジュアルへ置換。headless content/layout auditでプレースホルダ非表示、ステータス帯表示、1280x720収まりを確認済み。視覚スクショ未確認。 | 食べた料理、基本EXP、初回ボーナス、合計獲得、バフ、食後の現在準備が本文を読まなくても追える。 |
| `EXP_GAIN` | `src/ui/components/cooking_reward_panel.gd` | P2: `MEAL_RESULT`後に別オーバーレイとして開くEXP加算状態。右ペインを料理詳細カードからEXPフォーカスカードへ差し替え、巨大`+EXP`、`EXP before -> after`、明るいゲージ、キャラメッセージをまとめて主役化した。左カードの`DISH POWER`英字プレースホルダは削除し、料理から食経験値の力が出る簡易ビジュアルへ置換。さらにEXP時だけ表示する`ExpEnergyTrail`を左カードと右カードの間へ追加し、料理からゲージへ力が流れる見え方を補強。右端には`次の釣行で効果！`カードを追加し、食事で得たバフが次回釣行に接続されることを上段で明示した。今回の追加方針は、中央EXPフォーカスカード内に参照画像のような放射バースト、ゲージフラッシュ、星粒を入れ、`+EXP`とゲージの報酬ピークを強めること。補助カードは種類別小アイコン付きで横一列に圧縮し、下部にプレイヤーLv/効果中料理/クーラーボックス/所持金のステータス帯を追加済み。headless content/layout/smokeでプレースホルダ非表示、1280x720収まり、実フロー接続を確認済み。視覚スクショ未確認。 | EXPメーターが主役で、レベルアップしない場合も完結感がある。レベルアップする場合は次の報酬演出へ進む理由と、食後の現在準備が明確に読める。 |
| `LEVEL_UP_OVERLAY` | `src/ui/components/level_up_panel.gd` | P2: `04_level_up_overlay_concept.png` に合わせ、パネル幅を広げ、能力上昇を2列ステータスに再構成。赤い`新たな釣り場が解放！`リボン、描画式の王冠/メダル/釣り場サムネ風カード、紙吹雪/星/強めの金色光線を追加した。タイトル帯は王冠・左右ラウレル・大型`LEVEL UP!`の一体構成へ強化し、赤リボンとボスメダルも大きくした。食経験値が成長に変わった副題、`成長の証`、`挑戦解放`、`次の目標：港のぬし`、`新釣り場`を表示し、Lv.5報酬が次の行動につながることを強めた。英字仮ラベルはcontent auditで非表示を確認済み。headless content/layout/smokeで1280x720収まりを確認済み。視覚スクショ未確認。 | レベル遷移、能力上昇、ぬし解放が最も強い報酬瞬間として読める。 |
| `STATUS_SUMMARY` | `src/ui/components/cooking_status_panel.gd` | P2: `05_status_summary_concept.png` に合わせ、中央モーダルから全画面の専用サマリー状態へ再構成。上部に`ステータス`ヘッダーとLv/EXPゲージ、中央にプレイヤー/効果中料理/クーラーボックス/所持金/プレイ時間の5大型カード、下部にメッセージバーと`港へ戻る`ボタンを配置。効果中料理は料理画像・効果名・次回発動文で表示し、他4カードとフッターの英字プレースホルダは専用描画ビジュアルへ置換した。背景には港/厨房の横長シーン描画を重ね、ヘッダー左右には船舵/錨の装飾を追加した。headless content/layout/smokeでプレースホルダ非表示、1280x720内のはみ出し/縦横クリップなしを確認済み。視覚スクショ未確認。 | 5カードが1280x720で衝突せず、Lv/EXP、能力、効果中料理、クーラー、所持金、プレイ時間が専用サマリー画面として読める。 |

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
- `HOME=/private/tmp/tsuri_home "/Applications/Godot.app/Contents/MacOS/Godot" --display-driver macos --rendering-driver dummy --audio-driver Dummy --path ... res://tools/cooking_preview.tscn`
  - 結果: 失敗。
  - 理由: 通常起動と同じく即時に exit 134 で終了する。
  - 判定: macOS display driver + dummy renderer でも `/tmp/tsuri_cooking_*.png` は生成されない。
- `HOME=/private/tmp/tsuri_home "/Applications/Godot.app/Contents/MacOS/Godot" --display-driver macos --rendering-driver opengl3 --rendering-method gl_compatibility --audio-driver Dummy --disable-crash-handler --log-file /tmp/tsuri_cooking_preview_godot.log --path ... res://tools/cooking_preview.tscn`
  - 結果: 失敗。
  - 理由: 即時に exit 134 で終了し、`/tmp/tsuri_cooking_preview_godot.log` も生成されなかった。
  - 判定: renderer切り替えやcrash handler無効化では、この環境の通常描画キャプチャ制約は回避できない。
- `HOME=/private/tmp/tsuri_home "/Applications/Godot.app/Contents/MacOS/Godot" --headless --write-movie /tmp/tsuri_cooking_movie.png --quit-after 10 --fixed-fps 10 --path ... res://tools/cooking_preview.tscn`
  - 結果: 失敗。
  - 理由: movie makerもheadless/dummy rendererでは実フレームを生成できず、同じnull texture経路に入る。
  - 判定: `--write-movie` はこの環境での代替スクショ経路として使えない。
- `python3 tools/cooking_reference_report.py`
  - 目的: `reference/cooking_flow/*_concept.png` と `/tmp/tsuri_cooking_*.png` を状態別に横並び表示するHTML比較レポートを生成する。
  - 結果: 成功。
  - 出力: `/tmp/tsuri_cooking_reference_report.html`。
  - 判定: この環境ではキャプチャPNGが未生成のため、レポート上では5状態すべてがmissing表示になる。通常描画可能な環境で `tools/cooking_preview.gd` 実行後に再生成すれば、参照5枚との目視比較に使える。
- `python3 tools/cooking_visual_qa_check.py --allow-missing`
  - 目的: 参照PNGの存在/形式を確認し、キャプチャ未生成を許容したうえでHTML比較レポートを再生成する。
  - 結果: 成功。
  - 判定: この環境では5状態のキャプチャmissingを許容してツール自体を検証した。通常描画可能な環境では `--allow-missing` を外し、`/tmp/tsuri_cooking_*.png` が5枚すべて1280x720 PNGとして存在することを最終ゲートにする。参照PNGは原寸のまま扱い、寸法一致は要求しない。
- `python3 tools/cooking_visual_qa_check.py`
  - 結果: 失敗。
  - 理由: `/tmp/tsuri_cooking_select.png`、`/tmp/tsuri_cooking_result.png`、`/tmp/tsuri_cooking_exp.png`、`/tmp/tsuri_cooking_levelup.png`、`/tmp/tsuri_cooking_status.png` が未生成。
  - 判定: 通常描画環境でのキャプチャ生成が完了するまで、視覚QAゲートは未通過として扱う。
- `tools/cooking_flow_smoke.tscn`
  - 目的: headlessで各状態のControl構築を検証するためのスモークシーン。
  - コマンド: `HOME=/private/tmp/tsuri_home "/Applications/Godot.app/Contents/MacOS/Godot" --headless --path ... res://tools/cooking_flow_smoke.tscn`
  - 結果: 成功。
  - 範囲: `COOK_SELECT`、非レベルアップEXP報酬、レベルアップ報酬、報酬OK後の`LEVEL_UP_OVERLAY`接続、実際の`PlayerProgress.cook_and_eat()`経由での魚消費/初回料理記録/食事バフ/Lv.5到達/食事結果→EXP結果→レベルアップ接続、単体レベルアップ、ステータス要約のControl構築と短時間実行。
- `tools/cooking_layout_audit.tscn`
  - 目的: headlessで5状態を1280x720固定ステージに構築し、画面外はみ出し、非正サイズ、ラベル縦クリップ、欠落テクスチャを検出する。
  - コマンド: `HOME=/private/tmp/tsuri_home "/Applications/Godot.app/Contents/MacOS/Godot" --headless --path ... res://tools/cooking_layout_audit.tscn`
  - 結果: 成功。
  - 範囲: `COOK_SELECT`、`EXP_GAIN`、`EXP_GAIN_LEVELUP`、`MEAL_RESULT`、`LEVEL_UP_OVERLAY`、`STATUS_SUMMARY`。`EXP_GAIN_LEVELUP` はLv.5到達直前のEXP加算パネルが720p内に収まることを追加確認する小状態。折り返しなしラベルの横幅不足も検出する。
- `tools/cooking_content_audit.tscn`
  - 目的: headlessで5状態を構築し、料理名、材料、EXP、食事効果、成長予告、Lv.5解放、ステータス要約などの必須表示テキストが画面上に存在することを検出する。
  - コマンド: `HOME=/private/tmp/tsuri_home "/Applications/Godot.app/Contents/MacOS/Godot" --headless --path ... res://tools/cooking_content_audit.tscn`
  - 結果: 成功。
  - 範囲: `COOK_SELECT`、`EXP_GAIN`、`EXP_GAIN_LEVELUP`、`MEAL_RESULT`、`LEVEL_UP_OVERLAY`、`STATUS_SUMMARY`。`MEAL_RESULT` にはEXPゲージ/レベルアップ文が混ざらないことも確認する。視覚スクショの代替ではなく、表示情報欠落の回帰防止。

## 未解決

- P1: 現時点で既知のロジック破壊はなし。headless layout audit上の画面外はみ出し/縦クリップは解消済み。ただし実スクショ未取得のため、最終的な視覚密度、ピクセル単位の重なり、装飾の見え方は未証明。headless、通常起動、macOS display driver + dummy/opengl3 の各経路で `/tmp/tsuri_cooking_*.png` は生成できていない。`tools/cooking_visual_qa_check.py` の通常モードはこのmissingを検出して失敗する。
- P2: 生成フレーム/背景アセットの主要接続は進んだが、生成アセットは実装用の差し替えスロットであり、最終本番アートではない。料理・魚・背景は後続で品質差し替え余地あり。魚行とレシピカードは専用フレーム接続済みだが、視覚スクショで選択/ロック状態の見え方を確認する必要がある。
- P3: steam/sparkle/粒子などの小演出は、状態別スクショでP1/P2が潰れてから追加する。
