# 釣り場マップ画面 QA判断ログ

最終更新: 2026-07-03 / 状態: **アップリフト進行中のfreeze値あり**（2026-06〜07 判定。旧 `design-qa.md` からの分離移行）
参照画像: `reference/` 内の釣り場マップモック
QA更新コマンド: `./tools/fishing_spot_map_visual_qa.sh`

## 1. freeze値（正本）

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 詳細枠アンカー方式 | `DETAIL_FRAME_SOURCE_SIZE = 520x760`。枠PNG座標系から各子要素をアンカー配置 | `src/ui/fishing_spot_select_screen.gd` ＋ `map_detail_frame.png` | 枠の非等倍スケールでVBoxピクセル積みが焼き込みウェルとズレる問題の恒久対応 |
| ウェル座標（PNG座標） | タイトル (44,31)-(476,91) / 解放条件 (44,88)-(476,112) / サムネ (44,112)-(476,269) / 説明 (44,287)-(476,354) / 行エリア (44,366)-(476,560) / 主アクション (38,597)-(482,669) / 戻る (38,675)-(482,752) | 同上 | |
| `狙い` 行 | 4魚を2行・省略なしで表示（専用の大きい行スロット） | 同上 | P1（省略）解消の採用値 |
| `港へ戻る` ボタン | 高さ50px維持 | `ScreenBase.make_return_button()` 経由 | 共通枠PNGがラベルを潰さない高さ |
| 釣り場サムネイル | 8枚とも Codex App 生成の俯瞰/三分の二マップアート調。ソースは `tools/source_assets/fishing_spot_thumbs/*.png`、`assets/showcase/fishing_spots/thumbs/*.png` へ 420x184 正規化 | `assets/showcase/fishing_spots/thumbs/` | 焼き込みテキスト・UI枠・ロック標識・ランタイム状態なし。`harbor_pier`=港の情景 / `outer_tide`=潮目 / `deep_ocean`=カケアガリ / `harbor_boulder`=大岩 が判別性の核 |
| 共通アクションボタン枠 | 静かなネイビー/ゴールド版 `action_button_frame.png`（中央メダリオン・斜線装飾なし） | `assets/showcase/common/action_button_frame.png` | `ScreenBase.make_return_button()` 契約は維持 |

## 2. 不採用・再試行禁止リスト

| 案 | 却下理由 | 判断日 |
|---|---|---|
| 初回採用サムネ（空・水平線のある風景写真調） | マップUI内で「海の写真」に見え、メインマップのイラスト航海図文法と不一致。空・水平線なしのマップアート調で再生成して置換済み | 2026-06 |
| 旧 `action_button_frame.png`（中央メダリオン付き） | 50px高で `港へ戻る` ラベルと装飾が衝突 | 2026-06 |
| 右詳細のVBoxピクセル積みレイアウト | 枠PNGの非等倍スケール時に焼き込みウェルへ追従しない | 2026-06 |

## 3. 微調整カウンタ

| パラメータ | 回数 | 直近の変更内容 | 状態 |
|---|---|---|---|

## 4. 暫定判定・再検証TODO

- 注: これまでの証拠画像（`/tmp/tsuri_fishing_spot_map_compare.png` 等）は `/tmp` のみで失われた。次回作業時に `./tools/fishing_spot_map_visual_qa.sh` で再生成し、以後は `docs/qa/evidence/fishing_spot_map/` へコピーする。

## 5. 現在の残ギャップ

- アップリフトパスは継続中。次の候補素材は contact sheet → 全画面比較（釣行継続smokeの回帰確認込み）で判定する。

## 6. フェーズスコープ宣言（作業中のみ）

（現在作業中のフェーズなし）

## 7. 判断ログ（直近パスのみ）

- 2026-06〜07: P1レイアウト（`狙い` 省略・`港へ戻る` ラベル潰れ）を解消し、詳細枠をPNG座標アンカー方式へ移行。サムネ8枚を写真調→マップアート調の2段階で全数置換（各サムネの判別性向上を全画面比較で確認、この置換での不採用候補なし）。証拠は `./tools/fishing_spot_map_visual_qa.sh` の通常比較＋釣行継続比較の2枚で判定。
