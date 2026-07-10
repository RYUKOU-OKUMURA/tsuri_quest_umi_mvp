# 検証メモ

> **注意（2026-07-10）:** 本文は初期MVP時点の履歴で、現行の検証範囲を表しません。現在の監査結果、25本のsmoke / audit、既知の終了時ERROR、発売用release verifierの不足は `docs/45_release_readiness_code_review.md` を正とします。

## 実施済み

- `gdformat` によるGDScript整形
- `gdlint` による全 `.gd` ファイルの構文解析・静的チェック
- ZIP展開テスト
- Mac起動スクリプトと検証スクリプトのシェル構文確認

## Mac上で行う最終確認

この作業環境にはGodot本体を導入できないため、エンジンを起動した実行確認は同梱していません。Macで次を実行してください。

```zsh
cd tsuri_quest_umi_mvp
chmod +x tools/open_on_mac.command tools/validate_project.sh
./tools/validate_project.sh
```

検証スクリプトは、次の2段階を実行します。

1. ヘッドレスエディタでプロジェクトとスクリプトを読み込む
2. メインシーンを2秒間起動し、初期化時のエラーを確認する

その後、`tools/open_on_mac.command` またはGodotのプロジェクトマネージャーから起動し、`docs/07_テスト計画.md` の受け入れテストを実施してください。

## 想定環境

- Godot 4.7 Standard
- macOS（Apple Silicon / Intel）
- 基準解像度 1280 × 720
- GL Compatibilityレンダラー
