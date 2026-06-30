# 14. オープニングタイトル看板画面

## 目的

ゲーム起動直後の主要画面を、水中ファイト画面と同じ「ラスタ素材主導」の品質ラインへ引き上げる。コード描画のグラデーションと汎用パネルだけで構成せず、背景・ロゴ枠・メニュー枠・ボタン枠を差し替え可能な PNG スロットとして扱う。

## 採用構成

- `assets/showcase/title/title_ocean_bg.png`
  - 港、海面、水中の奥行きを一枚絵で見せる 16:9 背景。
- `assets/showcase/title/title_color_grade.png`
  - 右側メニュー可読性と外周の締まりを作る重ねレイヤー。
- `assets/showcase/title/title_logo_frame.png`
  - タイトル文字用の濃紺/羊皮紙/金枠素材。文字は誤字を避けるため Godot 側で描く。
- `assets/showcase/title/title_menu_frame.png`
  - セーブ状態、開始ボタン、README ボタン用のカード枠。
- `assets/showcase/title/title_button_*.png`
  - 通常/ホバー/押下/無効のボタン状態を画像枠として持つ。
- `assets/audio/opening_bgm.mp3`
  - タイトル/港メニュー用BGM。タイトルまたは港に滞在中はループ再生し、釣り場選択など他画面へ遷移したら停止する。
- `src/ui/components/title_backdrop.gd`
  - 背景、色調、泡、光、遠景魚のタイトル専用レイヤー。
- `src/ui/title_screen.gd`
  - ロゴ、メニュー、セーブ初期化フローだけを組み立てる。
- `src/main.gd`
  - タイトル/港メニュー用BGMの再生対象画面を管理する。タイトルから港へ移動しても同じ曲を継続する。

## 生成元

`tools/source_assets/title_opening_bg_source.png` を元絵として、`tools/generate_title_showcase_assets.py` が `assets/showcase/title/` の実使用 PNG を生成する。背景だけを差し替える場合は source を更新して同スクリプトを再実行する。

## QA

- 静的タイトルプレビュー: `python3 tools/build_title_static_preview.py`
- 出力: `/tmp/tsuri_title_static_preview.png`
- プロジェクト検証: `./tools/validate_project.sh`
- 水中ファイト回帰確認: `./tools/fight_visual_qa.sh`
- 音声確認: 通常起動でタイトル表示中にBGMが流れ、開始/続きからで港へ遷移しても継続し、釣り場選択などへ移ると停止することを確認する。

## 現在の合格ライン

- 背景が第一印象になり、ロゴ/メニューが背景を過剰に覆わない。
- タイトル文字、サブタイトル、コンセプト、3つのボタンが 1280x720 で枠内に収まる。
- 画像素材は Godot import 済みで、`.import` と `title_backdrop.gd.uid` を含めて管理する。
- `ui_theme.gd` や水中ファイト UI は変更せず、既存のファイトQAが通る。
