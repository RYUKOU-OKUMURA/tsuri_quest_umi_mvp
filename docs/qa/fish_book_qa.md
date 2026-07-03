# 魚図鑑画面 QA判断ログ

最終更新: 2026-07-03 / 状態: **v1.16 P2右詳細高解像度魚フレーム化合格・freeze中**
参照画像: `reference/07_fish_book_mockup.png`
QA更新コマンド: `./tools/fish_book_visual_qa.sh`

## 1. freeze値（正本）

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 右上ステータスバー | `PlayerStatusBar` のスロット配分を所持金優先 | `src/ui/components/`（PlayerStatusBar） | P1だった所持金省略の解消 |
| 竿名表記 | 短縮形（`港の入門竿`→`入門竿`、`外海竿・青嵐`→`青嵐`） | データ表示側 | ステータスバー内の収まり |
| カード内レアリティチップ | 幅 0.060–0.438 | `src/ui/fish_book_screen.gd` | `アンコモン` の省略解消 |
| 長い魚名 | カード/詳細で段階的にフォントサイズを落とす | 同上 | 省略ではなく縮小で収める採用値 |
| 背景スクリム | alpha 0.42 | 同上 | docs/19 §4.5（スクリム減光型） |
| 木色バックプレート | 0.024/0.118–0.976/0.982 | 同上 | 分離パネルから「一冊の台帳」への寄せ |
| 内側ウェル | 0.031/0.135–0.969/0.970 | 同上 | 同上 |
| 魚ポートレート表示 | 透明余白をalpha bboxで実表示クロップ。左カードは clip 0.055/0.165–0.945/0.670、右詳細は clip 0.095/0.175–0.915/0.490 | `src/ui/fish_book_screen.gd` | 魚画像が紙窓・カード情報帯・レアリティチップへ食い込むP1を解消 |
| 台帳外周フレーム | `fish_book_book_frame.png` を 0.018/0.018–0.982/0.982 に配置。ヘッダー/フッターの全面濃紺フレームは外し、ステータス/ボタンを木製レール上に載せる | `assets/showcase/fish_book/`, `src/ui/fish_book_screen.gd` | 画面全体を分離パネル群ではなく一冊の木製台帳として読ませる |
| カード/詳細紙面素材 | 通常/選択/未発見カードに `fish_book_card_frame.png` / `fish_book_card_selected_frame.png` / `fish_book_card_locked_frame.png`、右詳細下地に `fish_book_detail_paper.png` を使用。カード内のruntime文字領域へ焼き込み罫線を入れない | `assets/showcase/fish_book/`, `src/ui/fish_book_screen.gd` | 汎用カード・runtime塗り紙面から、魚図鑑専用の収集カード/羊皮紙ページへ寄せる |
| 左一覧密度/ウェル | 下地色 `Palette.WOOD_DARK` alpha 0.78、スクロール領域 0.047/0.105–0.955/0.970、グリッド間隔 h=6/v=3 | `src/ui/fish_book_screen.gd` | 左一覧を冷たい暗色パネルから木製台帳内の収集面へ寄せる |
| 魚ポートレート表示なじませ | 発見済み魚に紙色tint `Color(1.0, 0.965, 0.880, 1.0)`、左カード影 alpha 0.16 / offset 0.014,0.036、右詳細影 alpha 0.20 / offset 0.012,0.036。未発見シルエットには影を追加しない | `src/ui/fish_book_screen.gd` | 魚PNG本体を変えず、紙面へ貼っただけに見える浮きを抑える |
| 左カード内部再設計 | カード最小サイズ 204x106、魚名 10/12/14/16px段階、No. 12px、ポートレートclip 0.055/0.135–0.945/0.680、レアリティ 0.060/0.610–0.438/0.765、統計行 0.070/0.765–0.930/0.945、統計文字 12px | `src/ui/fish_book_screen.gd` | 左一覧で4段目まで実用表示しつつ、魚名・レアリティ・釣果・最大サイズを読ませる |
| 右詳細記録ラベル | 上部紙面wash `Palette.PARCHMENT_DEEP` alpha 0.92 を 0.082/0.052–0.918/0.150、No木札 `Palette.WOOD_DARK` alpha 0.88 を 0.082/0.052–0.318/0.118、場所見出し紙面wash alpha 0.90 を 0.086/0.824–0.915/0.882、場所見出し木札 alpha 0.88 を 0.090/0.834–0.545/0.884 | `src/ui/fish_book_screen.gd` | 右詳細の濃紺UI帯を、羊皮紙ページ上の記録ラベルとして読ませる |
| 釣り場カード紙面化 | 右下釣り場カードに `Palette.PARCHMENT` alpha 0.78 の1px紙枠、サムネ 0.045/0.055–0.955/0.680、サムネtint `Color(1.0, 0.965, 0.860, 0.92)`、ラベル紙面 `Palette.PARCHMENT_DEEP` alpha 0.96 を 0.045/0.700–0.955/0.955、ラベル文字13px `Palette.TEXT_OUTLINE_LIGHT` | `src/ui/fish_book_screen.gd` | 右下サムネを濃紺UIストリップから羊皮紙ページ内の記録カードへ寄せる |
| 未発見カード封印紙面 | 未発見カードの魚窓下地 `Palette.PARCHMENT_DEEP` alpha 0.58、魚影 `Palette.WOOD_DARK` alpha 0.62、紙面wash `Palette.PARCHMENT` alpha 0.18、No木札 `Palette.WOOD_DARK` alpha 0.72、`？` は `Palette.GOLD_DEEP` alpha 0.88、`未発見` 札は `Palette.PARCHMENT_DEEP` alpha 0.94 + `Palette.WOOD_DARK` alpha 0.34 の罫線 | `src/ui/fish_book_screen.gd` | 未発見カードを濃紺UIパネルではなく封印された紙面記録として読ませる |
| 右詳細魚標本窓 | 右詳細の大魚clip内に横罫線3本 `Palette.GOLD_DEEP` alpha 0.12、左測定線 `Palette.WOOD_DARK` alpha 0.10、魚上の紙面wash `Palette.PARCHMENT` alpha 0.08 を追加。魚clip座標と魚PNG本体は変更なし | `src/ui/fish_book_screen.gd` | 右詳細の大魚をPNGステッカーではなく紙面上の標本画として読ませる |
| 右詳細高解像度魚フレーム | 発見済み右詳細の大魚のみ、`showcase_sheet` frame0 を左向きにミラーし、既存alpha bboxクロップで表示する。未発見・左カード・clip座標は変更せず、読み込み不可時は `card_portrait` へフォールバック | `src/ui/fish_book_screen.gd`, `assets/showcase/fish/` | 右詳細の大魚をカード用縮小ポートレートではなく、詳細ページの主役としてより鮮明に見せる |

## 2. 不採用・再試行禁止リスト

| 案 | 却下理由 | 判断日 |
|---|---|---|
| 2026-06時点での新規PNG生成 | 構成・文字収まり・スクリムのみで v1.5 目標を達成できたため、その時点では生成に着手せず | 2026-06 |
| カード高だけを112/124/132pxまで詰める案 | 一覧密度は上がるが、下部の釣果/最大サイズが窮屈になり、魚ポートレートも主役性が弱くなる。内部レイアウト再設計なしでは採用しない | 2026-07-03 |

## 3. 微調整カウンタ

| パラメータ | 回数 | 直近の変更内容 | 状態 |
|---|---|---|---|
| 魚ポートレート表示枠 | 1 | alpha bboxクロップ＋clipコンテナ化 | P1解消としてfreeze |
| カード/詳細紙面の焼き込み線 | 1 | 初回候補の罫線・傷線がruntime文字に近かったため、端の紙質表現だけに削減 | P2紙面素材としてfreeze |
| 左一覧カード密度 | 3 | 112/124/132px案を比較し、単純圧縮は不採用。後続の内部再設計で204x106へ移行 | クローズ |
| 魚ポートレート影 | 1 | 初回影が複製っぽく見えたため、左右ともalphaとoffsetを弱めた | P2表示なじませとしてfreeze |
| 左カード内部再設計 | 1 | 204x106へ圧縮後、魚窓だけを0.135–0.680へ戻して魚の主役性を確保 | P2カード再設計としてfreeze |
| 右詳細記録ラベル | 1 | 右詳細上部と場所見出しに紙面wash＋木札を追加し、濃紺バーを台帳内ラベル化 | P2詳細記録化としてfreeze |
| 釣り場カード紙面化 | 1 | 右下釣り場サムネに紙カード枠、余白、羊皮紙ラベルを追加し、青いラベル帯を撤去 | P2収集導線としてfreeze |
| 未発見カード封印紙面化 | 1 | 未発見カードの濃紺魚窓を羊皮紙色に寄せ、魚影・？・未発見札をセピア調へ変更 | P2収集導線としてfreeze |
| 右詳細魚標本窓 | 1 | 大魚clip内に淡い測定罫線と紙面washを追加 | P2魚表示としてfreeze |
| 右詳細高解像度魚フレーム化 | 1 | 右詳細の大魚ソースを `card_portrait` から `showcase_sheet` frame0 mirror へ変更 | P2魚表示としてfreeze |

## 4. 暫定判定・再検証TODO

なし。直近の判断根拠は `docs/qa/evidence/fish_book/2026-07-03_detail_hi_res_fish_frame_compare.png` に保存済み。

## 5. 現在の残ギャップ

- **P2**: 魚ポートレート素材そのものの専用描き起こし・魚ごとの見せ方、フォント全体方針は未着手。次に品質を上げる場合は1フェーズだけ選び、contact sheet → 全画面比較で判定する。
- 文字収まりの採用値（レアリティチップ幅・段階的フォント縮小）を、P1再発なしに動かさないこと。

## 6. フェーズスコープ宣言（作業中のみ）

（現在作業中のフェーズなし）

## 7. 判断ログ（直近パスのみ）

- 2026-07-03: v1.16 P2右詳細高解像度魚フレーム化フェーズ。右詳細の発見済み大魚ポートレートだけを対象に、`card_portrait` ではなく `showcase_sheet` frame0 を左向きにミラーして使うよう変更した。魚PNG本体、左カードのカード用ポートレート、alpha bboxクロップ、右詳細の魚clip座標、右詳細魚標本窓レイヤー、未発見カード、釣り場カード、ステータスバー、フィルタ/戻るボタンはfreeze値のまま維持。`./tools/fish_book_visual_qa.sh` の横並び比較で、右詳細の魚がより鮮明で主役らしい標本画に近づき、向き違い・はみ出し・視認性低下・素材未表示が再発しなかったため採用。判断根拠: `docs/qa/evidence/fish_book/2026-07-03_detail_hi_res_fish_frame_compare.png`。検証: `./tools/validate_project.sh` exit 0（Godot終了時のObjectDB/resource警告あり）、`fish_book_smoke: ok`。
