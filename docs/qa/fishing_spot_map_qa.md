# 釣り場マップ画面 QA判断ログ

最終更新: 2026-07-17 / 状態: **Visual Wave V2着手前baseline固定 / MAP-M1 Stage A診断待ち**（既存freeze・E11入力契約維持）
参照画像: `reference/` 内の釣り場マップモック
QA更新コマンド: `./tools/fishing_spot_map_visual_qa.sh`
入力QAコマンド: `godot --headless --path . --scene res://tools/fishing_spot_input_smoke.tscn`

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
| キーボード入力契約 | 初期focus=`ここで釣る`。マップと有効な`仕掛け切替`/`ここで釣る`/`港へ戻る`/`釣り手帳`/`メニュー`をTab/Shift+Tabの閉じたgraphへ接続し、disabled要素は`FOCUS_NONE`で除外。マップfocus中は←/↑で前、→/↓で次のspotへ`SPOT_MARKER_ORDER`を循環（ロックspotを含む全9件）。巡回は`spot_focused`、Enter/mouse決定はaccessible=`spot_selected`またはlocked=`locked_spot_pressed`の単一signalから同じ画面更新経路をechoなしexactly onceで実行する。focusは共通4px金枠、Escapeは港遷移exactly once | `src/ui/fishing_spot_select_screen.gd` / `src/ui/components/fishing_spot_map_view.gd` / `tools/fishing_spot_input_smoke.gd` | ロック・access・仕掛け所持状態は既存値を正とし、選択更新時にCTA disabled/復帰とgraphを再評価。マップfocusはロックspotでも維持し、Tabで安全に離脱できる |

## 2. 不採用・再試行禁止リスト

| 案 | 却下理由 | 判断日 |
|---|---|---|
| 初回採用サムネ（空・水平線のある風景写真調） | マップUI内で「海の写真」に見え、メインマップのイラスト航海図文法と不一致。空・水平線なしのマップアート調で再生成して置換済み | 2026-06 |
| 旧 `action_button_frame.png`（中央メダリオン付き） | 50px高で `港へ戻る` ラベルと装飾が衝突 | 2026-06 |
| 右詳細のVBoxピクセル積みレイアウト | 枠PNGの非等倍スケール時に焼き込みウェルへ追従しない | 2026-06 |

## 3. 微調整カウンタ

| パラメータ | 回数 | 直近の変更内容 | 状態 |
|---|---|---|---|
| 入力focus収束 | 2 | マップをfocus graphへ追加し、全9spotのkeyboard循環とlocked CTA fallbackを採用 | 採用・freeze |

## 4. 暫定判定・再検証TODO

（なし。2026-07-06 にE4危険海域追加後の通常/釣行継続/海図ロック状態の比較画像を再生成し、`docs/qa/evidence/fishing_spot_map/` へ保存済み）

## 5. 現在の残ギャップ

- アップリフトパスは継続中。次の候補素材は contact sheet → 全画面比較（釣行継続smokeの回帰確認込み）で判定する。

## 6. フェーズスコープ宣言（作業中のみ）

（現在作業中のフェーズなし。2026-07-15 のE11入力P1再収束ではマップfocus・既存`SPOT_MARKER_ORDER`によるkeyboard巡回・Enter signal契約だけを追加し、`DETAIL_FRAME_SOURCE_SIZE`、全ウェル座標、`狙い`行、戻るボタン高さ、9サムネイル、素材・font・palette、既存航路/マーカー/spot座標、ロック・access・trip logicは触っていない）

## 7. 判断ログ（直近パスのみ）

- 2026-07-17: Visual Wave V2の共通起点 `e297692a` で、MAP-M1着手前のnormal / continue / danger chart lockを再固定。`./tools/fishing_spot_map_visual_qa.sh` exit 0、3状態とも1280x720 RGBA・opaque比率1.000で、SHA-256は相互に異なる。証拠は `docs/qa/evidence/fishing_spot_map/2026-07-17_v2_prebaseline_{normal,continue,danger_chart_lock}.png` と `2026-07-17_v2_prebaseline_normal_reference_compare.png`。Stage Aでは製品asset/source/processor/runtime/freezeを変更せず、このbaselineと `reference/06_fishing_spot_map_mockup.png` を原寸・320x180・grayscaleで診断する。

- 2026-07-05: R5/R1スライス。通常/釣行継続の現状比較で、右詳細の`エサ`行と`仕掛け`行に省略表示が出るP1再発を確認。エサ行は餌リストだけを単行表示し、相性は仕掛け行へ`サビキ / ふつう`・`ちょい投げ / 一致`の短縮表記で移した。`src/ui/fishing_spot_select_screen.gd` と `src/ui/components/fishing_spot_map_view.gd` の釣り場マップ画面固有hexは `Palette.MAP_*` へ移行し、表示色の実値は維持した。判断根拠: `docs/qa/evidence/fishing_spot_map/2026-07-05_detail_text_p1_fix_compare.png`、`docs/qa/evidence/fishing_spot_map/2026-07-05_detail_text_p1_fix_continue_compare.png`。
- 2026-07-06: E4危険海域追加。`danger_reef` の暗い外洋サムネ、サメヒレ系ピン、海図未完成時の「？」ピン/`海図 2/3`表示、青物ルートからの航路を追加。通常/釣行継続で既存詳細レイアウトのP1再発なし、Lv30・船ランク3・海図2/3状態で右詳細の海図メッセージとボタン文言が収まることを確認。判断根拠: `docs/qa/evidence/fishing_spot_map/2026-07-06_e4_danger_reef_default_compare.png`、`docs/qa/evidence/fishing_spot_map/2026-07-06_e4_danger_reef_continue_compare.png`、`docs/qa/evidence/fishing_spot_map/2026-07-06_e4_danger_reef_chart_lock_compare.png`。
- 2026-07-15: E11入力収束。安全な主操作`ここで釣る`へ初期focusを置き、所持仕掛け・選択spotの状態に応じてdisabled操作を除外する閉じた方向/Tab graph、共通4px金focus枠、Escape港遷移exactly onceを追加。専用smokeの実`InputEventKey`/実mouse eventで、Enter単発、disabled skip、ロックspot→安全focus fallback→解放spot復帰、マップクリック回帰を固定した。E11 baselineの`fishing_spots` findingは0。原寸判断根拠: `docs/qa/evidence/fishing_spot_map/2026-07-15_input_primary_focus.png`。既存ボタンのnormal/hover/pressed、全freeze座標・素材・ゲーム状態は不動。
- 2026-07-15: E11入力P1再収束。button graphだけでは到達できなかったマップをfocus領域へ追加し、実`InputEventKey`のShift+Tabで到達、矢印で全9spot（ロック含む）を循環、accessible/lockedの詳細・CTA状態更新、Tab離脱/復帰、Enter echo無視exactly onceを専用smokeへ固定した。巡回の`spot_focused`と決定の`spot_selected`/`locked_spot_pressed`を分離し、Enter/mouse clickは排他的な決定signalから画面更新・BGM要求を1回だけ行う。原寸判断根拠: `docs/qa/evidence/fishing_spot_map/2026-07-15_keyboard_map_locked_focus.png`（危険海域選択、マップ共通4px金focus、CTA disabled）。同日visual QAの通常/釣行継続/海図ロック比較で既存freeze領域の差分なし。
