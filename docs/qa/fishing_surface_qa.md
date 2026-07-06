# 水上キャスト画面 QA判断ログ

最終更新: 2026-07-06 / 状態: 非晴天魚影・ヒット演出 uplift 採用
参照画像: `reference/01_surface_fishing_mockup.png`
QA更新コマンド: `./tools/surface_weather_visual_qa.sh`

## 1. freeze値（正本）

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 晴天の状態別プレート | 変更しない | `assets/showcase/surface/surface_scene_waiting.png` / `surface_scene_approach.png` / `surface_scene_bite.png` | 晴天は焼き込み魚影の品質が高く、今回の対象外 |
| 非晴天魚影素材 | `surface_fish_shadow_soft.png` 3フレーム横並びシート、無ければ `surface_fish_shadow.png` | `src/ui/components/surface_cast_view.gd` | 新素材未import時も `ImageTexture.create_from_image()` 経由で表示、欠落時は旧素材へフォールバック |
| 非晴天魚影ステージング | WAITING=小・薄、APPROACH=拡大+alpha上昇、BITE=縮小+低alpha | `_draw_asset_fish_shadow()` | BITEで魚影を濃くせず、スプラッシュを主役にする |
| 非晴天航跡 | 固定楕円なし、進行方向V字航跡+後方リップル | `_draw_asset_fish_wake()` | 旧楕円アウトラインの照準レティクル感を解消 |
| rain/fogオーバーレイ | rain=2枚縦スクロール、fog=横ドリフト+alpha揺らぎ | `_draw_weather_texture_overlay()` | 静止合成をやめ、天候の動きを出す |

## 2. 不採用・再試行禁止リスト

| 案 | 却下理由 | 判断日 |
|---|---|---|
| 旧 `surface_fish_shadow.png` の白modulate合成を継続 | 目穴・泡・ヒレが見え、霧/雨の水面上でデカール調に浮く | 2026-07-06 |
| BITE時に魚影alphaを0.82へ上げる | ヒット時に魚影が主役化し、スプラッシュに隠れるべき演出と逆 | 2026-07-06 |
| 魚影周辺の固定楕円アウトライン | レティクルに見えるため、魚の進行方向を示す航跡に置換 | 2026-07-06 |

## 3. 微調整カウンタ

| パラメータ | 回数 | 直近の変更内容 | 状態 |
|---|---|---|---|
| 装飾パス累計 | 1 | 非晴天魚影の2パス描画、V字航跡、rain/fogオーバーレイアニメ化 | 採用 |
| 魚影tint/alpha | 2 | rainで沈みすぎたため、環境色tintを明るめの青灰へ戻しAPPROACHのみalpha/scaleを増加 | 採用・close |

## 4. 暫定判定・再検証TODO

なし。

## 5. 現在の残ギャップ

- WAITING魚影は遠景扱いでかなり控えめ。P1/P2ではなく、必要なら別フェーズで「待機時の水面反応」演出として扱う。
- 右サイドカード内の魚影図は既存UI表示で、今回の水面合成パスとは別対象。

## 6. フェーズスコープ宣言（作業中のみ）

完了済みのためなし。

## 7. 判断ログ（直近パスのみ）

2026-07-06 非晴天魚影・ヒット演出 uplift を採用。

変更したもの:
- `surface_fish_shadow_soft.png` を追加し、非晴天の WAITING / APPROACH / BITE 合成で優先使用。
- 魚影を天気別tint/alphaに変更し、同フレームを拡大低alpha + 等倍本alphaの2パスで描画。
- BITE時の `alpha=0.82` 固定を廃止し、縮小+フェードでスプラッシュに主役を渡す。
- 旧固定楕円アウトラインをV字航跡と後方リップルに置換。
- rain/fog overlay を `_time` でアニメーション化。

変えていないもの:
- 晴天の状態別プレートと晴天時の描画パス。
- 既存の晴天用PNG、他画面素材、魚ドメイン素材。

判断根拠:
- 5天気READY比較: `docs/qa/evidence/fishing_surface/2026-07-06_before_weather_ready_compare.png` / `docs/qa/evidence/fishing_surface/2026-07-06_final_after_weather_ready_compare.png`
- fog状態比較: `docs/qa/evidence/fishing_surface/2026-07-06_final_compare_fog_states.png`
- rain状態比較: `docs/qa/evidence/fishing_surface/2026-07-06_final_compare_rain_states.png`

採用理由:
- beforeの硬い魚アイコン感、白い浮き、BITE時の濃化、レティクル状楕円が解消された。
- afterは天気ごとの明度に馴染み、APPROACHでは魚影が読み取れ、BITEではスプラッシュが主役になっている。
- 比較シート上で晴天プレートの挙動に変更がない。
