# 31. 素材台帳（作者・ライセンス・入手元）

作成日: 2026-07-06
目的: `docs/08_独自性と権利メモ.md` §制作ルール「使用素材の作者、ライセンス、入手元を台帳化する」の実体。**販売（ローンチ）前に「要記入」をゼロにすることが E11 の完了条件の一つ**（docs/v2/E11_launch_readiness.md）。

運用ルール:

- 新しい素材・音源・フォントを追加したら、**同じコミットで本台帳に行を足す**
- 「入手元」は再取得できる具体性で書く（URL、生成スクリプト名、生成サービス名＋日付）
- AI生成サービスを使った場合は、サービス名・生成日・当時の商用利用規約の要点を書く

## 1. フォント — 記入済み・問題なし

| 素材 | パス | 作者/出所 | ライセンス | 同梱ライセンス文書 |
|---|---|---|---|---|
| LINE Seed JP（Rg / Bd / Eb） | `assets/fonts/line_seed/` | LY Corporation | SIL OFL 1.1（商用可） | `assets/fonts/line_seed/OFL.txt` ✓ |
| M PLUS 1p（Regular / Bold / ExtraBold） | `assets/fonts/` | The M+ FONTS Project | SIL OFL 1.1（商用可） | `assets/fonts/OFL-MPLUS1p.txt` ✓ |

## 2. プロシージャル生成PNG — 記入済み・プロジェクト所有

`tools/generate_*.py`（PIL使用・外部AI API不使用・決定的生成）で生成した素材は**プロジェクト所有**であり第三者ライセンスの問題はない。対象: `assets/showcase/cooking/`・`fish_book/`・`fish_market/`・`fishing_spot_map/`・`harbor/`・`surface/`・`tackle_shop/`・`title/` などの各 generate スクリプト出力一式。

| 生成スクリプト | 出力先 |
|---|---|
| `tools/generate_cooking_showcase_assets.py` | `assets/showcase/cooking/` |
| `tools/generate_fish_book_book_frame.py` / `generate_fish_book_paper_assets.py` | `assets/showcase/fish_book/` |
| `tools/generate_fish_market_assets.py` | `assets/showcase/fish_market/` |
| `tools/generate_fishing_spot_map_assets.py` | `assets/showcase/fishing_spot_map/` |
| `tools/generate_harbor_showcase_assets.py` | `assets/showcase/harbor/` |
| `tools/generate_surface_showcase_assets.py` | `assets/showcase/surface/` |
| `tools/generate_tackle_shop_assets.py` | `assets/showcase/tackle_shop/` |
| `tools/generate_title_showcase_assets.py` | `assets/showcase/title/` |
| `tools/generate_top_status_weather_icons.py` | `assets/showcase/common/` |

## 3. 音源（BGM / SE） — **要記入**

`assets/audio/` の10ファイル。入手元・生成手段・商用利用条件が未記録。**販売前必須**。

| ファイル | 入手元 / 生成手段 | 商用利用条件 | 記入状態 |
|---|---|---|---|
| `opening_bgm.mp3` | （要記入） | （要記入） | ❌ |
| `アタリ_ヒット音.mp3` | （要記入） | （要記入） | ❌ |
| `外海・回遊ルート.mp3` | （要記入） | （要記入） | ❌ |
| `岩礁・消波ブロック.mp3` | （要記入） | （要記入） | ❌ |
| `水中ファイト通常.mp3` | （要記入） | （要記入） | ❌ |
| `海辺（さざなみ）.mp3` | （要記入） | （要記入） | ❌ |
| `海辺（少し風が強い）.mp3` | （要記入） | （要記入） | ❌ |
| `港外・潮目.mp3` | （要記入） | （要記入） | ❌ |
| `砂浜・かけあがり.mp3` | （要記入） | （要記入） | ❌ |
| `逃げられた.mp3` | （要記入） | （要記入） | ❌ |

## 4. AI生成画像（外部サービス由来） — **要記入**

generate スクリプトの出力に**含まれない**画像素材。生成に使ったサービスと当時の商用規約を記録すること。

| 対象 | パス | 生成サービス / 日付 | 商用利用条件 | 記入状態 |
|---|---|---|---|---|
| 魚ポートレート・泳ぎシート（70種×2点） | `assets/showcase/fish/` | （要記入） | （要記入） | ❌ |
| reference 完成イメージ一式 | `reference/`（`.gdignore` 済・**製品に同梱されない**ため優先度低。ただし宣伝素材に使うなら要記入） | （要記入） | （要記入） | ⚠️ |
| 各画面の背景など generate スクリプト外のPNG | 各 `assets/showcase/<screen>/`（`git log` で追加経緯を確認して仕分ける） | （要記入） | （要記入） | ❌ |

## 5. その他

| 項目 | 状態 |
|---|---|
| ゲームタイトル「釣りクエスト」の商標調査 | 未実施（E11） |
| `assets/icon.svg`（現状Godotデフォルトの可能性） | 差し替え時に本台帳へ記入（E11） |

## 更新履歴

- 2026-07-06: 初版。フォント・プロシージャル素材を記入済み化、音源・AI生成画像を要記入として棚卸し
