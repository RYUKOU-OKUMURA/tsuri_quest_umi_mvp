# 42. 釣行 E5 時間帯 Stage 2 素材ブリーフ

Date: 2026-07-08

対象画面: `src/ui/fishing_screen.gd` / `src/ui/components/surface_cast_view.gd` / `src/ui/components/catch_fanfare.gd`  
QA正本: `docs/qa/fishing_surface_qa.md`  
根拠: `docs/41_e5_time_slots_implementation_review.md` §3-4 / `docs/qa/fishing_surface_qa.md` §7

## 目的

E5 Stage 1のコードグレードでは、水面READYの焼き込み太陽と昼海面が残り、夜READYが夜に見えない。色alphaを上げても文字視認性だけが落ちるため、時間帯差が最も目に入るREADY水面と釣果写真ベースだけを最小素材で差し替える。

## 今回動かす範囲

- `assets/showcase/surface/surface_scene_ready_asa_mazume.png`（960x405）
- `assets/showcase/surface/surface_scene_ready_night.png`（960x405）
- `assets/showcase/underwater/catch_photo_base_asa.png`（1280x720）
- `assets/showcase/underwater/catch_photo_base_night.png`（1280x720）
- 候補ソース置き場: `tools/source_assets/fishing_time_slots/`

## 今回動かさない範囲

- 日中READYと既存の天候READY素材。
- WAITING / APPROACH / BITE の状態別プレート。
- 非晴天魚影、rain/fog overlay、既存天候grade。
- 水中背景、FIGHT HUD、READY下段バー、サメ餌魚セレクタ。
- 魚本体、魚名、記録文、報酬文、ボタン文言などのruntime描画。
- 天候別×時間帯別、状態別×時間帯別のPNG量産。
- 日本語テキストや数値のPNG焼き込み。

## 共通条件

- 既存素材と同じ構図・同じ画角・同じ解像度で、runtime UIが重なる余白を維持する。
- 生成候補はAI画像生成で作り、採用前に解像度を正規化する。
- 画面に入る文字、ラベル、UI枠、アイコン意味情報を焼き込まない。
- 現行PNGより「時間帯が読める」ことを優先する。参照級の新構図を狙わず、既存画面への違和感を小さくする。
- 採用判断はパーツ単体ではなく、`./tools/fishing_time_slot_visual_qa.sh` とファンファーレ個別キャプチャの実スクショで行う。

## 素材別条件

### `surface_scene_ready_asa_mazume.png`

- 既存 `surface_scene_ready.png` と同じ水面READY構図。
- 朝焼けの暖色空、低い太陽または太陽直前の明るみ、オレンジから薄青への空。
- 海面は日中より少し暗く、暖色反射が入る。
- 釣り人、竿、浮き、遠景の配置は既存READYに近い。

不採用条件:
- 真昼の青空・白い昼太陽に見える。
- 夕焼けが強すぎて夜釣りや警告画面に見える。
- UIの下段バーや右上カードの背後が明るすぎて文字を食う。

### `surface_scene_ready_night.png`

- 既存READYと同じ構図で、月夜の海釣りに見える。
- 空は暗い紺、月または月光の反射を入れる。昼太陽に見える円形光は避ける。
- 海面は暗い青緑で、月光の細いハイライトだけを残す。
- 釣り人と浮きはシルエット寄りでも、プレイ状態が読める程度に残す。

不採用条件:
- 日中の青海面が残り、グレードを重ねても夜に見えない。
- 暗すぎて魚影・浮き・釣り人が完全に沈む。
- 星空や月が派手すぎてHUDより主役になる。

### `catch_photo_base_asa.png`

- 既存 `catch_photo_base.png` と同じ写真ベース構図。
- 魚本体を置く中央領域は空け、runtime魚が自然に載る。
- 朝の低い暖色光、少しオレンジの紙/背景、港・水面の朝らしい色味。
- 日本語テキスト、魚名、数値、記録ラベルは入れない。

不採用条件:
- 魚や文字が焼き込まれている。
- 中央の魚配置領域に強い物体や手前マスクが入り、runtime魚を邪魔する。
- 既存ファンファーレのバナー/テキストが読みにくくなる。

### `catch_photo_base_night.png`

- 既存写真ベース構図の夜版。
- 暗い紺の環境光、月光または港灯りの控えめなハイライト。
- 中央の魚配置領域は空け、runtime魚が自然に載る。
- 日本語テキスト、魚名、数値、記録ラベルは入れない。

不採用条件:
- 真っ黒でruntime魚が沈む。
- 写真風の白フラッシュが強く、昼写真に見える。
- 焼き込み文字、魚、UIパネルが入る。

## 評価手順

1. 既存素材を参照し、AI画像生成で4枚のソース候補を作る。
2. ソースを `tools/source_assets/fishing_time_slots/` に保存する。
3. 既存解像度へクロップ/リサイズして `assets/showcase/surface/` と `assets/showcase/underwater/` に出力する。
4. コード配線前に候補4枚を目視し、明らかな文字焼き込み・構図破綻・昼戻りがあれば作り直す。
5. 採用候補だけを配線し、`./tools/fishing_time_slot_visual_qa.sh` とファンファーレ夜版キャプチャで全画面判定する。
6. 採用/不採用を `docs/qa/fishing_surface_qa.md` に記録し、証拠画像を `docs/qa/evidence/fishing_surface/` へ保存する。

## 採用条件

- 夜READYが縮小比較でも夜釣りとして読める。
- 朝READYが日中と明確に区別でき、夜とは混同しない。
- 釣果ファンファーレの朝/夜が、魚本体・記録文・報酬文を邪魔せず時間帯差を出す。
- Stage 1で採用済みのグレード/ビネット/逃走リザルトと競合しない。
- `./tools/validate_project.sh`、釣行系smoke、`./tools/save_system_verify.sh` がgreen。

