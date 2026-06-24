# 11. 水中ファイト看板画面 実装仕様

## 目的

`reference/02_underwater_fight_mockup.png` を水中ファイト画面の品質基準にする。まずはクロダイ戦 1 画面だけを、背景・魚・UI 枠・ゲージ・演出が揃った看板画面として作り込む。

## 到達ライン

- 水中背景は `_draw()` の図形ではなく、専用ラスタ背景を敷く。
- 主役魚は楕円やポリゴンではなく、透明 PNG のスプライトシートで表示する。
- 釣り糸、エサ、ヒット演出、泡、魚影は背景と魚に重なるレイヤーとして扱う。
- 既存の釣りロジック、テンション、魚体力、深度、行動名は維持する。
- 本番アート到着時に、同じファイルスロットへ PNG を差し替えれば画面品質を上げられる構造にする。

## レイヤー構成

1. `underwater_battle_bg.png`
   水面光、光芒、海底、岩、海藻、遠景魚、泡を含む 16:9 背景。
2. 動的深度表示
   現在深度と目盛り。背景上に半透明で重ねる。
3. 釣り糸・エサ
   既存ロジックの位置に合わせて動的描画する。
4. `kurodai_showcase_sheet.png`
   主役魚。4 フレーム構成で、遊泳・緊張・突進・疲労を切り替える。
5. `hit_burst.png`
   アワセ直後の「ヒット！」演出。短時間だけ魚の手前に表示する。
6. HUD / 情報 UI
   下部ゲージ、右パネル、ボタンは既存 Control UI を維持しつつ、順次画像枠へ差し替える。

## 最小素材セット

| ファイル | 役割 | 現在の作り方 | 本番差し替え時の条件 |
|---|---|---|---|
| `assets/showcase/underwater/underwater_battle_bg.png` | 水中背景 | `tools/generate_underwater_showcase_assets.py` で生成 | 16:9、暗部と主役魚のコントラストを確保 |
| `assets/showcase/underwater/kurodai_showcase_sheet.png` | クロダイ | 4 フレーム PNG スプライトシート | 透明背景、横 4 フレーム、全フレーム同サイズ |
| `assets/showcase/underwater/hit_burst.png` | ヒット演出 | 透明 PNG | 中央配置して読めるサイズ、透明背景 |

## 実装方針

- `UnderwaterView` は上記 PNG が存在すれば素材版を優先する。
- PNG がない場合は既存の procedural 描画にフォールバックする。
- 魚スプライトの位置、向き、状態は `FishingSimulator.visual_position`、`visual_direction`、`action_name`、`fish_stamina_ratio()` から決める。
- 画面の完成度チェックは、Godot で `tools/fishing_fight_preview.gd` 相当のキャプチャを取り、リファレンスと横並び比較する。

## 次に本番化する素材

1. 右側の魚情報カード背景とクロダイ肖像。
2. 下部 HUD の長いウィンドウスキン。
3. セグメント式テンションゲージ、魚体力ゲージ。
4. 泡、光粒、魚影を個別スプライトまたは CPUParticles2D に分離。
5. 日本語ピクセルフォント。
