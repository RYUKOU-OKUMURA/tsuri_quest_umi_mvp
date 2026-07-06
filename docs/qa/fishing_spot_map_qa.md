# 釣り場マップ画面 QA判断ログ

最終更新: 2026-07-06 / 状態: **アップリフト進行中のfreeze値あり**（E4危険海域追加済み）
参照画像: `reference/` 内の釣り場マップモック
QA更新コマンド: `./tools/fishing_spot_map_visual_qa.sh`

## 1. freeze値（正本）

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 詳細枠アンカー方式 | `DETAIL_FRAME_SOURCE_SIZE = 520x760`。枠PNG座標系から各子要素をアンカー配置 | `src/ui/fishing_spot_select_screen.gd` ＋ `map_detail_frame.png` | 枠の非等倍スケールでVBoxピクセル積みが焼き込みウェルとズレる問題の恒久対応 |
| ウェル座標（PNG座標） | タイトル (44,31)-(476,91) / 解放条件 (44,88)-(476,112) / サムネ (44,112)-(476,269) / 説明 (44,287)-(476,354) / 行エリア (44,366)-(476,560) / 主アクション (38,597)-(482,669) / 戻る (38,675)-(482,752) | 同上 | |
| `狙い` 行 | 4魚を2行・省略なしで表示（専用の大きい行スロット） | 同上 | P1（省略）解消の採用値 |
| 詳細`エサ`/`仕掛け`行 | エサ行は餌リストのみを13px単行表示、仕掛け行は`仕掛け名 / 一致・ふつう`の短縮表記。対応餌リストは重複表示しない | `src/ui/fishing_spot_select_screen.gd` | エサ・仕掛け値の省略表示P1再発を防ぐ |
| `港へ戻る` ボタン | 高さ50px維持 | `ScreenBase.make_return_button()` 経由 | 共通枠PNGがラベルを潰さない高さ |
| 釣り場サムネイル | 9枚。既存8枚は Codex App 生成の俯瞰/三分の二マップアート調を `tools/source_assets/fishing_spot_thumbs/*.png` から 420x184 正規化。E4 `danger_reef` は `tools/generate_fishing_spot_map_assets.py` による暗い外洋潮筋のマップ切り出し | `assets/showcase/fishing_spots/thumbs/` | 焼き込みテキスト・UI枠・ロック標識・ランタイム状態なし。`harbor_pier`=港の情景 / `outer_tide`=潮目 / `deep_ocean`=カケアガリ / `harbor_boulder`=大岩 / `danger_reef`=暗い外洋潮筋 が判別性の核 |
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

（なし。2026-07-06 にE4危険海域追加後の通常/釣行継続/海図ロック状態の比較画像を再生成し、`docs/qa/evidence/fishing_spot_map/` へ保存済み）

## 5. 現在の残ギャップ

- アップリフトパスは継続中。次の候補素材は contact sheet → 全画面比較（釣行継続smokeの回帰確認込み）で判定する。

## 6. フェーズスコープ宣言（作業中のみ）

（現在作業中のフェーズなし。2026-07-06 のE4追加では、`danger_reef` のサムネイル・ピン・航路・海図ロック表示だけを追加し、`DETAIL_FRAME_SOURCE_SIZE`、ウェル座標、`狙い`行、戻るボタン高さ、既存サムネイル素材、既存航路/マーカー座標は触っていない）

## 7. 判断ログ（直近パスのみ）

- 2026-07-05: R5/R1スライス。通常/釣行継続の現状比較で、右詳細の`エサ`行と`仕掛け`行に省略表示が出るP1再発を確認。エサ行は餌リストだけを単行表示し、相性は仕掛け行へ`サビキ / ふつう`・`ちょい投げ / 一致`の短縮表記で移した。`src/ui/fishing_spot_select_screen.gd` と `src/ui/components/fishing_spot_map_view.gd` の釣り場マップ画面固有hexは `Palette.MAP_*` へ移行し、表示色の実値は維持した。判断根拠: `docs/qa/evidence/fishing_spot_map/2026-07-05_detail_text_p1_fix_compare.png`、`docs/qa/evidence/fishing_spot_map/2026-07-05_detail_text_p1_fix_continue_compare.png`。
- 2026-07-06: E4危険海域追加。`danger_reef` の暗い外洋サムネ、サメヒレ系ピン、海図未完成時の「？」ピン/`海図 2/3`表示、青物ルートからの航路を追加。通常/釣行継続で既存詳細レイアウトのP1再発なし、Lv30・船ランク3・海図2/3状態で右詳細の海図メッセージとボタン文言が収まることを確認。判断根拠: `docs/qa/evidence/fishing_spot_map/2026-07-06_e4_danger_reef_default_compare.png`、`docs/qa/evidence/fishing_spot_map/2026-07-06_e4_danger_reef_continue_compare.png`、`docs/qa/evidence/fishing_spot_map/2026-07-06_e4_danger_reef_chart_lock_compare.png`。
