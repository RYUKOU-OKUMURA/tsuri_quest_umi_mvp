# AGENTS.md — tsuri_quest_umi_mvp

海釣りRPG（Godot 4 / GDScript / 1280x720固定）のMVP。UIは「AI生成PNG素材 + Godot runtime描画（テキスト・状態・ゲージ）」の分担で作る方針。ドキュメント・コミットメッセージ・UI文言は日本語。

## ディレクトリ地図

| パス | 役割 |
|---|---|
| `src/ui/` | 画面スクリプト（`*_screen.gd`）と `components/` |
| `src/ui/palette.gd` | 共通色パレット（**色の正本。新規ハードコードhex禁止**） |
| `src/ui/game_fonts.gd` / `fight_fonts.gd` | フォント（LINE Seed JP。AA方針が分裂中→docs/19 §4.2） |
| `assets/showcase/<screen>/` | 画面別PNG素材（`common/` は今後整備予定） |
| `tools/` | 素材生成（`generate_*.py`）、visual QA（`*_visual_qa.sh`）、smoke test、`validate_project.sh` |
| `docs/` | 仕様・振り返り・指示書（番号順） |
| `reference/` | 正式完成イメージ（`.gdignore` 済み。**ゲームに直接インポート禁止**） |
| `design-qa.md` | 水中ファイト画面のQA判断ログ（採用値・freeze値・不採用理由） |
| `skills/` | 作業手順スキル（下記） |

## 最重要参考資料

**UI実装・改善作業はすべて `docs/19_ui_production_playbook.md` に従うこと。** これがルールの正本（優先順位、P1/P2/P3トリアージ、共通キット規約、スタイルガイド、v1完了条件、既知ギャップ§8.5）。本ファイルやスキルと矛盾したら docs/19 を優先し、docs/19 側を改訂してから作業する。

## 作業種別とスキルの対応

| 作業 | 従う手順 |
|---|---|
| 新しい画面UIをゼロから実装 | `skills/ui-screen-build/SKILL.md` |
| 既存画面UIの品質向上 | `skills/ui-screen-uplift/SKILL.md` |
| 調理・食事・レベルアップフロー | `skills/tsuri-cooking-showcase-uplift/SKILL.md`（専用。上記2つより優先） |

## 検証コマンド

```bash
./tools/validate_project.sh        # プロジェクト全体検証（作業完了前に必須）
./tools/fight_visual_qa.sh         # 水中ファイトの比較スクショ再生成
./tools/cooking_visual_qa.sh       # 調理フローの比較スクショ再生成
# 魚図鑑・釣り場マップの visual_qa.sh は未整備（作業時に最初に作る。docs/19 §6.1）
```

smoke test は `tools/*_smoke.tscn` を headless Godot で実行。UI変更でも該当フローのsmoke（釣行継続・港戻り・出現監査など）を必ず回す。

## 不変ルール（要約。詳細は docs/19）

- 見た目の完了判断は必ず**実スクショ + 参照画像との横並び比較**で行う。コード上のサイズ指定やテストの green を根拠にしない。
- 作業順は「構成 → 主導線 → 情報階層 → 文字の収まり → 素材の質感 → 演出」。逆走しない。
- 数px・明度の微調整を3回繰り返して改善しないなら素材品質不足。素材フェーズへ送る。
- 合格済みのfreeze値（各画面のQAドキュメント記載）は、P1破綻の再発時以外は動かさない。
- 日本語テキストをPNG素材へ焼き込まない。
- 素材候補は「現行に全画面比較で明確に勝つ」場合だけ採用。採用/不採用の理由をQAドキュメントに残す。
- 他画面の素材フォルダを直接参照しない。共有する部品は `assets/showcase/common/` へ昇格してから使う。
- `reference/*.png` は方向性の真実だが最終アートではない。分解して本番素材に置き換える。
