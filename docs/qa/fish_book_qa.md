# 魚図鑑画面 QA判断ログ

最終更新: 2026-07-08 / 状態: **docs/35 P1/P2 差し替え済み**
参照画像: `reference/07_fish_book_mockup.png`
QA更新コマンド: `./tools/fish_book_visual_qa.sh`

## 1. freeze値（正本）

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 右上ステータスバー | `PlayerStatusBar` のスロット配分を所持金優先 | `src/ui/components/`（PlayerStatusBar） | P1だった所持金省略の解消 |
| 竿名表記 | 短縮形（`港の入門竿`→`入門竿`、`外海竿・青嵐`→`青嵐`、`カジキ竿・蒼槍`→`蒼槍`） | データ表示側 | ステータスバー内の収まり |
| 発見進捗バー | 上部左の発見済みバー内 0.054/0.674–0.244/0.758 に `StyleBoxFlat` の進捗trackを配置し、`found / total` に応じて `Palette.GOLD_BRIGHT` alpha 0.78 のfillを伸縮。track は `Palette.TEXT_OUTLINE_DARK` alpha 0.48、border は `Palette.GOLD_DEEP` alpha 0.52、角丸3px | `src/ui/fish_book_screen.gd` | 発見済み表示を単なる数値ではなく、魚図鑑の収集進捗として読ませる |
| カード内レアリティチップ | 幅 0.060–0.438 | `src/ui/fish_book_screen.gd` | `アンコモン` の省略解消 |
| 長い魚名 | カード/詳細で段階的にフォントサイズを落とす | 同上 | 省略ではなく縮小で収める採用値 |
| 背景スクリム | alpha 0.42 | 同上 | docs/19 §4.5（スクリム減光型） |
| 木色バックプレート | 0.024/0.118–0.976/0.982 | 同上 | 分離パネルから「一冊の台帳」への寄せ |
| 内側ウェル | 0.031/0.135–0.969/0.970 | 同上 | 同上 |
| 魚ポートレート表示 | 透明余白をalpha bboxで実表示クロップ。左カードは一覧専用tight crop（pad x=0.012/y=0.025、alpha threshold=0.070、min pad=2）を使い、写真下地 0.070/0.190–0.930/0.615、clip 0.080/0.198–0.920/0.602 に収める。右詳細は clip 0.095/0.175–0.915/0.490 | `src/ui/fish_book_screen.gd` | 魚画像がカード名・レアリティチップ・統計行へ食い込むP1を解消し、一覧内で同じ写真枠に揃える |
| 左一覧発見済み魚ソース | 発見済みカードの魚ポートレートは `showcase_sheet` frame0 を左向きにミラーし、一覧専用tight crop（pad x=0.012/y=0.025、alpha threshold=0.070、min pad=2）で表示する。読み込み不可時は従来の `card_portrait` にフォールバック。未発見カードは従来の `card_portrait` 由来シルエットを維持 | `src/ui/fish_book_screen.gd`, `assets/showcase/fish/` | 左一覧と右詳細の魚素材ソースを揃え、カード内の魚を紙面上の標本画として見せる |
| 台帳外周フレーム | `fish_book_book_frame.png` を 0.018/0.018–0.982/0.982 に配置。ヘッダー/フッターの全面濃紺フレームは外し、ステータス/ボタンを木製レール上に載せる | `assets/showcase/fish_book/`, `src/ui/fish_book_screen.gd` | 画面全体を分離パネル群ではなく一冊の木製台帳として読ませる |
| 中央綴じ目 | 左一覧と右詳細の間に 0.586/0.150–0.616/0.885 の綴じ目レイヤーを配置。`Palette.WOOD_DARK` alpha 0.62 の革/木影、中央fold `Palette.TEXT_OUTLINE_DARK` alpha 0.42、左右に `Palette.GOLD_DEEP` alpha 0.24/0.16 の細線を入れる | `src/ui/fish_book_screen.gd` | 左右のパネルを別ウィンドウではなく、開いた一冊の台帳の左右ページとして読ませる |
| カード/詳細紙面素材 | 通常/選択/未発見カードに `fish_book_card_frame.png` / `fish_book_card_selected_frame.png` / `fish_book_card_locked_frame.png`、右詳細下地に `fish_book_detail_paper.png` を使用。カード内のruntime文字領域へ焼き込み罫線を入れない | `assets/showcase/fish_book/`, `src/ui/fish_book_screen.gd` | 汎用カード・runtime塗り紙面から、魚図鑑専用の収集カード/羊皮紙ページへ寄せる |
| 左一覧カード紙面ベース | カード枠の内側 0.038/0.040–0.962/0.958 に `StyleBoxFlat` の紙面ベースを配置。発見済みは `Palette.PARCHMENT` alpha 0.76、選択中は alpha 0.84、未発見は `Palette.PARCHMENT_DEEP` alpha 0.50、border は `Palette.WOOD_DARK` alpha 0.24/0.30、1px、角丸2px | `src/ui/fish_book_screen.gd` | カード中央に暗色台帳地が透ける状態を抑え、魚写真・名前・釣果を一枚の紙カードとして読ませる |
| 左一覧密度/ウェル | 下地色 `Palette.WOOD_DARK` alpha 0.78、スクロール領域 0.047/0.105–0.955/0.970、グリッド間隔 h=6/v=3 | `src/ui/fish_book_screen.gd` | 左一覧を冷たい暗色パネルから木製台帳内の収集面へ寄せる |
| 左一覧ページ面 | 左一覧スクロール領域の背後 0.047/0.105–0.936/0.970 に `Palette.PARCHMENT` alpha 0.34 のページ下地と `_paper_wash()` alpha 0.46 を配置。左右端に `Palette.WOOD_DARK` alpha 0.10/0.08 の端影、y=0.310/0.524/0.738/0.952 に `Palette.WOOD_DARK` alpha 0.13 の淡い横罫線、x=0.342/0.636 に alpha 0.075 の列罫線を置く。カードサイズ・魚clip・スクロール領域は変更しない | `src/ui/fish_book_screen.gd` | カード間に見える暗色UI面を抑え、魚カードが羊皮紙台帳ページ上に並ぶ状態へ寄せる |
| 左一覧ヘッダー台帳ラベル | 左一覧上部に `Palette.PARCHMENT_DEEP` alpha 0.22 の紙面wash 0.050/0.040–0.935/0.100、`Palette.WOOD_DARK` alpha 0.88 の木札 0.052/0.036–0.272/0.102、下罫線 `Palette.GOLD_DEEP` alpha 0.24 を配置。右側注記は操作説明ではなく `発見した魚の写し絵と釣果` | `src/ui/fish_book_screen.gd` | 左一覧上部を汎用UI説明ではなく、台帳内の記録ラベルとして読ませる |
| 左一覧選択ブックマーク | 選択中カードだけに左端 0.036/0.205–0.064/0.760 のブックマークPanelを重ねる。`Palette.GOLD_DEEP` alpha 0.76、border `Palette.WOOD_DARK` alpha 0.72、glint は 0.044/0.230–0.050/0.720 に `Palette.GOLD_BRIGHT` alpha 0.38。写真ウェル・No.・魚名・レアリティ・統計行には重ねない | `src/ui/fish_book_screen.gd` | 左一覧で選んだカードが右ページに開かれている状態を、台帳のしおりとして読ませる |
| 左一覧写真ウェル | 左カードの写真下地を `StyleBoxFlat` の紙面ウェル化。発見済みは `Palette.PARCHMENT` alpha 0.78、未発見は `Palette.PARCHMENT_DEEP` alpha 0.58、border は `Palette.WOOD_DARK` alpha 0.42/0.34、1px、角丸2px。座標は 0.070/0.190–0.930/0.615 | `src/ui/fish_book_screen.gd` | 魚写真が同じ矩形枠に入って並んでいる状態を明確にする |
| 魚ポートレート表示なじませ | 発見済み魚に紙色tint `Color(1.0, 0.965, 0.880, 1.0)`、左カード影 alpha 0.16 / offset 0.014,0.036、右詳細影 alpha 0.20 / offset 0.012,0.036。未発見シルエットには影を追加しない | `src/ui/fish_book_screen.gd` | 魚PNG本体を変えず、紙面へ貼っただけに見える浮きを抑える |
| 魚ポートレート印刷なじませ | 発見済み魚の下に `Palette.WOOD_DARK` のインク下刷りを4方向へ追加。左カードは alpha 0.22 / spread x=0.006 y=0.016、右詳細は alpha 0.16 / spread x=0.004 y=0.009。魚clip座標、魚cropパラメータ、カード内文字、未発見カードは変更しない | `src/ui/fish_book_screen.gd` | 魚の輪郭を紙面上の印刷/標本画として少し締め、貼り付けPNG感を弱める |
| 左カード内部再設計 | カード最小サイズ 204x106、魚名 10/12/14/16px段階、No. 12px、写真下地 0.070/0.190–0.930/0.615、ポートレートclip 0.080/0.198–0.920/0.602、レアリティ 0.060/0.610–0.438/0.765、統計行 0.070/0.765–0.930/0.945、統計文字 12px | `src/ui/fish_book_screen.gd` | 左一覧で4段目まで実用表示しつつ、魚写真をカード内の枠へ揃え、魚名・レアリティ・釣果・最大サイズを読ませる |
| 右詳細記録ラベル | 上部紙面wash `Palette.PARCHMENT_DEEP` alpha 0.92 を 0.082/0.052–0.918/0.150、No木札 `Palette.WOOD_DARK` alpha 0.88 を 0.082/0.052–0.318/0.118、場所見出し紙面wash alpha 0.90 を 0.086/0.824–0.915/0.882、場所見出し木札 alpha 0.88 を 0.090/0.834–0.545/0.884 | `src/ui/fish_book_screen.gd` | 右詳細の濃紺UI帯を、羊皮紙ページ上の記録ラベルとして読ませる |
| 釣り場カード紙面化 | 右下釣り場カードに `Palette.PARCHMENT` alpha 0.78 の1px紙枠、サムネ 0.045/0.055–0.955/0.680、サムネtint `Color(1.0, 0.965, 0.860, 0.92)`、ラベル紙面 `Palette.PARCHMENT_DEEP` alpha 0.96 を 0.045/0.700–0.955/0.955、ラベル文字13px `Palette.TEXT_OUTLINE_LIGHT` | `src/ui/fish_book_screen.gd` | 右下サムネを濃紺UIストリップから羊皮紙ページ内の記録カードへ寄せる |
| 右詳細釣果記録欄 | 大魚窓下の釣果欄を 0.090/0.518–0.500/0.596、最大欄を 0.510/0.518–0.910/0.596 の `StyleBoxFlat` 紙面スリップに分ける。各欄は `Palette.PARCHMENT_DEEP` alpha 0.48、border `Palette.WOOD_DARK` alpha 0.28、木札ラベル `Palette.WOOD_DARK` alpha 0.88、値は `Palette.TEXT_OUTLINE_LIGHT`。表示文言は値側を `12匹` / `34.2cm` に分離し、未発見は `未記録` / `--.-cm` | `src/ui/fish_book_screen.gd` | 釣果と最大サイズを単なる中央テキストではなく、羊皮紙ページ上の収集記録欄として読ませる |
| 下部索引タブ | フィルタ7件を 0.032 から x step 0.1065 / 幅 0.104、y 0.072–0.850 に配置。7件目の右端は 0.775 で「港へ戻る」レール x=0.778 と衝突しない。背面に索引レール `Palette.PARCHMENT_DEEP` alpha 0.16、上罫線 `Palette.GOLD_DEEP` alpha 0.24、下影 `Palette.TEXT_OUTLINE_DARK` alpha 0.20 を敷く。選択タブは `Palette.DARK_PANEL` alpha 0.94 + `Palette.GOLD_BRIGHT` border、非選択は `Palette.PARCHMENT_DEEP` alpha 0.88 + `Palette.WOOD_DARK` border。タブ順は 全魚 / 港内 / 砂浜 / 岩礁 / 沖 / レア / ヌシ | `src/ui/fish_book_screen.gd` | E2機能追加に伴う意図的なfreeze改訂。下部フィルタを汎用ボタン列ではなく、図鑑の収集カテゴリをめくる索引タブとして読ませる |
| 港へ戻る主導線 | 下部右 0.778/0.038–0.974/0.938 に `Palette.WOOD_DARK` alpha 0.70 の木札受け板、`Palette.GOLD_DEEP` alpha 0.58 の1px枠、上金線 0.792/0.086–0.960/0.118、下影 0.792/0.842–0.960/0.898 を配置。`FishBookReturnButton` は 0.786/0.100–0.970/0.910、ExtraBold 22px、outline 3。共通 `make_return_button()` 本体は変更しない | `src/ui/fish_book_screen.gd` | 下部右の戻る導線を完成イメージの主ボタンに近づけ、フィルタタブ列から独立した操作として読ませる |
| ヌシ記録表示 | 捕獲済みヌシがある基準魚カード右上に `Palette.GOLD_BRIGHT` の小さな金ピンと runtime文字「主」を重ねる。詳細ページは外周に `Palette.GOLD_BRIGHT` の2px金線を出し、釣果/最大欄の下に `ヌシ記録　{異名}　{最大cm}` を表示する。未捕獲の気配表示はしない | `src/ui/fish_book_screen.gd` | E2の「既存魚ページに金枠＋ヌシ記録」を、魚図鑑の台帳文法を崩さず追加する |
| 未発見カード封印紙面 | 未発見カードの魚窓下地 `Palette.PARCHMENT_DEEP` alpha 0.58、魚影 `Palette.WOOD_DARK` alpha 0.62、紙面wash `Palette.PARCHMENT` alpha 0.18、No木札 `Palette.WOOD_DARK` alpha 0.72、`？` は `Palette.GOLD_DEEP` alpha 0.88、`未発見` 札は `Palette.PARCHMENT_DEEP` alpha 0.94 + `Palette.WOOD_DARK` alpha 0.34 の罫線。魚窓内には封印コード 0.125/0.492–0.875/0.508、封印印 0.125/0.418–0.255/0.608（`Palette.GOLD_DEEP` alpha 0.84、`封` 15px）を追加。カードサイズ・既存ラベル座標は変更しない | `src/ui/fish_book_screen.gd` | 未発見カードを濃紺UIパネルではなく、まだ開いていない封印記録として読ませる |
| 右詳細魚標本窓 | 右詳細の大魚clip内に横罫線3本 `Palette.GOLD_DEEP` alpha 0.12、左測定線 `Palette.WOOD_DARK` alpha 0.10、下辺の採寸目盛り（base alpha 0.10、minor/medium/major tick alpha 0.12/0.15/0.18）、魚上の紙面wash `Palette.PARCHMENT` alpha 0.08 を追加。上部左右に紙テープ 0.060/0.060–0.210/0.145 と 0.790/0.060–0.940/0.145（`Palette.PARCHMENT_DEEP` alpha 0.46）と小さな金具を置く。魚clip座標と魚PNG本体は変更なし | `src/ui/fish_book_screen.gd` | 右詳細の大魚をPNGステッカーではなく、羊皮紙ページに留めた標本画として読ませる |
| 右詳細高解像度魚フレーム | 発見済み右詳細の大魚のみ、`showcase_sheet` frame0 を左向きにミラーし、既存alpha bboxクロップで表示する。未発見・左カード・clip座標は変更せず、読み込み不可時は `card_portrait` へフォールバック | `src/ui/fish_book_screen.gd`, `assets/showcase/fish/` | 右詳細の大魚をカード用縮小ポートレートではなく、詳細ページの主役としてより鮮明に見せる |

## 2. 不採用・再試行禁止リスト

| 案 | 却下理由 | 判断日 |
|---|---|---|
| 2026-06時点での新規PNG生成 | 構成・文字収まり・スクリムのみで v1.5 目標を達成できたため、その時点では生成に着手せず | 2026-06 |
| カード高だけを112/124/132pxまで詰める案 | 一覧密度は上がるが、下部の釣果/最大サイズが窮屈になり、魚ポートレートも主役性が弱くなる。内部レイアウト再設計なしでは採用しない | 2026-07-03 |
| 既存 `card_portrait` 系の単純差し替え | 2026-07-05 の contact sheet では、現行の左カードtight crop/右詳細高解像度cropを全画面で明確に上回らない。専用描き起こし候補が来るまでは採用しない | 2026-07-05 |
| 未捕獲ヌシの「気配」表示 | E2仕様どおり今回は採用しない。未捕獲状態で基準魚ページに気配だけ出すと、通常魚の未発見/発見導線とヌシ導線が混ざるため、捕獲済みヌシの金ピン・詳細記録だけに限定する | 2026-07-06 |

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
| 右詳細釣果記録欄 | 1 | 釣果/最大サイズを木札ラベル付きの紙面スリップへ分離 | P2収集記録としてfreeze |
| 未発見カード封印紙面化 | 1 | 未発見カードの濃紺魚窓を羊皮紙色に寄せ、魚影・？・未発見札をセピア調へ変更 | P2収集導線としてfreeze |
| 右詳細魚標本窓 | 3 | 大魚clip上部左右に淡い紙テープと小さな金具を追加 | P2魚表示としてfreeze |
| 右詳細高解像度魚フレーム化 | 1 | 右詳細の大魚ソースを `card_portrait` から `showcase_sheet` frame0 mirror へ変更 | P2魚表示としてfreeze |
| 左一覧ヘッダー台帳ラベル化 | 1 | 操作説明文を記録注記へ置換し、紙面wash・木札・下罫線を追加 | P2台帳文法としてfreeze |
| 左一覧選択ブックマーク | 1 | 選択中カードの左端に小さなしおり風マーカーを追加 | P2収集導線としてfreeze |
| 左一覧魚ソース高解像度化 | 1 | 発見済みカードだけを `showcase_sheet` frame0 mirror ソースへ変更し、未発見カードは従来ソースを維持 | P2魚表示としてfreeze |
| 左一覧魚写真枠収まり修正 | 2 | 初回は写真枠分離で魚が小さすぎたため、一覧専用tight cropを追加して魚を枠内で自然な大きさに戻した | P1/P2写真収まりとしてfreeze |
| 左一覧写真ウェル明確化 | 1 | 写真下地を線付きの紙面ウェルへ変更し、全カードで同じ写真枠として見せる | P1/P2写真収まりとしてfreeze |
| 左一覧カード紙面ベース化 | 1 | カード枠内側へ紙面ベースを追加し、暗色台帳地がカード中央に透ける状態を解消 | P2台帳感としてfreeze |
| 中央綴じ目 | 1 | 左右ページ間に細い背表紙影・中央fold・金細線を追加 | P2台帳感としてfreeze |
| 下部索引タブ化 | 1 | フィルタ6件を紙/濃紺の索引タブstyleへ変更し、背面に薄い索引レールを追加 | P2収集導線としてfreeze |
| E2ヌシタブ追加 | 1 | 6件freezeを7列用 x step 0.1065 / 幅 0.104 へ意図的改訂し、戻る導線との衝突なしをvisual QAで確認 | E2機能追加としてfreeze |
| E2ヌシ記録表示 | 1 | 捕獲済みヌシの基準魚カードへ金ピン、詳細ページへ金線とヌシ記録行を追加 | E2機能追加としてfreeze |
| 発見進捗バー化 | 1 | 上部左の発見済みバー内へ `found / total` で伸縮する小さな進捗線を追加 | P2収集導線としてfreeze |
| 左一覧ページ面紙面化 | 1 | 左一覧スクロール領域の背後へ羊皮紙下地、紙面wash、淡い端影/罫線を追加 | P2台帳感としてfreeze |
| 港へ戻る主導線強化 | 1 | 下部右の戻るボタン背後へ木札受け板・金線・下影を追加し、ボタンを少し拡張 | P2主導線としてfreeze |
| 未発見カード封印サイン強化 | 1 | 未発見カードの魚窓内へ淡い封印コードと小さな封印印を追加 | P2収集導線としてfreeze |
| 魚ポートレート素材評価 | 1 | 魚図鑑の現行カードcrop、右詳細crop、既存 `card_portrait` を全魚で並べる contact sheet を追加 | 評価基盤としてfreeze |
| 魚ポートレート印刷なじませ | 2 | 初回 alpha 0.16/0.13 は全画面比較で差が弱かったため、左カード0.22/右詳細0.16へ上げて輪郭だけを締めた | P2魚表示としてfreeze |
| 専用魚ポートレート素材フェーズ設計 | 1 | `docs/24_fish_book_portrait_asset_brief.md` を追加し、候補置き場、優先魚、採用/不採用条件、contact sheet→全画面比較手順を定義 | 素材フェーズ入口としてfreeze |

## 4. 暫定判定・再検証TODO

なし。直近の判断根拠は `docs/qa/evidence/fish_book/2026-07-06_e2_nushi_tab_compare.png`、`docs/qa/evidence/fish_book/2026-07-06_e2_nushi_record_compare.png` に保存済み。

## 5. 現在の残ギャップ

- **P2/P3**: 2026-07-08 に docs/35 P1 A群15種とP2 B群17種は採用済み。残りはP3境界ケース（`megochi`, `kurosoi/takenokomebaru`, `mejina`）の再評価。
- 文字収まりの採用値（レアリティチップ幅・段階的フォント縮小）を、P1再発なしに動かさないこと。

## 6. フェーズスコープ宣言（作業中のみ）

なし。2026-07-05 R5/R1魚図鑑スライスは完了（Palette移行 + 既存素材候補評価、素材採用なし）。

## 7. 判断ログ（直近パスのみ）

- 2026-07-03: v1.34 P2専用魚ポートレート素材フェーズ設計。現行の画面座標、魚clip、crop、文字、台帳フレームは変更せず、残P2である魚ポートレート専用描き起こしの発注/採用条件を `docs/24_fish_book_portrait_asset_brief.md` として追加した。既存 `card_portrait` の単純差し替えでは全画面で明確に勝つ根拠が弱いため、次の実装は `aji` / `saba` / `kasago` などファーストビュー魚の専用候補を作り、contact sheet→全画面比較で採用判定する。判断根拠: `docs/qa/evidence/fish_book/2026-07-03_portrait_asset_brief_current_compare.png`、`docs/qa/evidence/fish_book/2026-07-03_portrait_asset_brief_contact_sheet.png`。検証: `git diff --check` exit 0、`python3 tools/build_fish_book_portrait_contact_sheet.py` exit 0、`./tools/fish_book_visual_qa.sh` exit 0、`fish_book_smoke: ok`、`./tools/validate_project.sh` exit 0（Godot終了時のObjectDB/resource警告あり）。
- 2026-07-05: R5/R1魚図鑑スライス。`src/ui/fish_book_screen.gd` の hardcoded hex / 数値 `Color(...)` を表示色同値の `Palette.FISH_BOOK_*` へ移行し、`rg -n "#[0-9a-fA-F]{6}|Color\\([0-9]" src/ui/fish_book_screen.gd` が空であることを確認した。実スクショ比較でP1再発はなし。contact sheetでは既存 `card_portrait` 系が現行の左カードtight crop/右詳細高解像度cropを明確に上回らないため、素材採用は見送り、専用描き起こしP2は新規候補待ちとして継続。判断根拠: `docs/qa/evidence/fish_book/2026-07-05_palette_gate_compare.png`、`docs/qa/evidence/fish_book/2026-07-05_portrait_contact_sheet.png`。検証: `git diff --check` exit 0、contact sheet再生成 exit 0、`./tools/fish_book_visual_qa.sh` exit 0、`fish_book_smoke: ok`、`./tools/save_system_verify.sh` exit 0、`./tools/validate_project.sh` exit 0（Godot終了時のObjectDB Snapshots directory警告は既存ベースライン枠）。
- 2026-07-06: E2ヌシ図鑑スライス。機能追加に伴い下部索引を7列freezeへ改訂し、`ヌシ` タブを追加。捕獲済みヌシは基準魚ページへ金ピン、詳細ページへ金線と `ヌシ記録` 行を表示する。未捕獲ヌシの気配表示は不採用として記録。判断根拠: `docs/qa/evidence/fish_book/2026-07-06_e2_nushi_tab_compare.png`、`docs/qa/evidence/fish_book/2026-07-06_e2_nushi_record_compare.png`、`docs/qa/evidence/fish_book/2026-07-06_e2_nushi_record.png`。検証: `./tools/fish_book_visual_qa.sh` exit 0、`TSURI_FISH_BOOK_PREVIEW_MODE=nushi ./tools/fish_book_visual_qa.sh` exit 0、`fish_book_smoke: ok`。
- 2026-07-08: docs/35 P1バッチ1魚素材差し替え。`houbou`, `kanagashira`, `kyusen`, `kobudai`, `ojisan`, `sayori`, `binnaga`, `konoshiro` を新規OpenAI生成コンタクトシート由来へ置き換え、図鑑カード/詳細で魚種識別特徴（ホウボウ大胸鰭、コブダイ額コブ、オジサンあごひげ、サヨリ下顎、ビンナガ長胸鰭、コノシロ黒斑と背鰭糸状延長など）が読めるため採用。画面freeze値・魚clip座標・文字配置は変更なし。判断根拠: `docs/qa/evidence/fish_assets/2026-07-08_p1_batch1_before_after.png`、`docs/qa/evidence/fish_book/2026-07-08_p1_batch1_portrait_contact.png`、`docs/qa/evidence/fish_book/2026-07-08_p1_batch1_fish_book_compare.png`。検証: `./tools/fish_book_visual_qa.sh` exit 0、`python3 tools/audit_fish_asset_duplicates.py` exit 0（pending 26→14、unexpected 0）、`python3 tools/audit_fish_sheet_contract.py` exit 0。
- 2026-07-08: docs/35 P1バッチ2魚素材差し替え。`ira`, `kinmedai`, `akamutsu`, `medai`, `sawara`, `mahaze`, `nenbutsudai` を新規OpenAI生成コンタクトシート由来へ置き換え、図鑑カード/詳細で魚種識別特徴（イラの斜帯、キンメダイの大きな金眼、アカムツの赤い鰓、メダイの丸い灰色体、サワラの細長い体と斑点、マハゼの底物体型、ネンブツダイの黒線）が読めるため採用。画面freeze値・魚clip座標・文字配置は変更なし。判断根拠: `docs/qa/evidence/fish_assets/2026-07-08_p1_batch2_before_after.png`、`docs/qa/evidence/fish_assets/2026-07-08_p1_batch2_card_contact.png`、`docs/qa/evidence/fish_book/2026-07-08_p1_batch2_fish_book_compare.png`。検証: `./tools/fish_book_visual_qa.sh` exit 0、`python3 tools/audit_fish_asset_duplicates.py` exit 0（pending 14→8、unexpected 0）、`python3 tools/audit_fish_sheet_contract.py` exit 0、`./tools/validate_project.sh` exit 0。
- 2026-07-08: docs/35 P2バッチ1魚素材差し替え。`meichidai`, `murasoi`, `onikasago`, `kihada`, `mebachi`, `hirasouda`, `suma`, `takabe`, `makogarei` を新規OpenAI生成コンタクトシート由来へ置き換え、図鑑カードで魚種識別特徴（メイチダイの眼帯、ムラソイの黒褐色斑、オニカサゴの強い棘、キハダの黄色ヒレ、メバチの大眼、ヒラソウダの背中虫食い模様、スマの腹側黒点、タカベの黄帯、マコガレイの平たい砂地斑）が読めるため採用。画面freeze値・魚clip座標・文字配置は変更なし。判断根拠: `docs/qa/evidence/fish_assets/2026-07-08_p2_batch1_before_after.png`、`docs/qa/evidence/fish_assets/2026-07-08_p2_batch1_card_contact.png`、`docs/qa/evidence/fish_assets/2026-07-08_p2_batch1_source_contact.png`、`docs/qa/evidence/fish_book/2026-07-08_p2_batch1_fish_book_compare.png`。検証: `./tools/fish_book_visual_qa.sh` exit 0、`python3 tools/audit_fish_asset_duplicates.py --strict` exit 0（pending 8→0、unexpected 0）、`python3 tools/audit_fish_sheet_contract.py` exit 0。
- 2026-07-08: docs/35 P2バッチ2魚素材差し替え。`shimaaji`, `gingameaji`, `kaiwari`, `ishigarei`, `umitanago`, `ishigakidai`, `oomonhata`, `ara` を新規OpenAI生成コンタクトシート由来へ置き換え、図鑑カードで魚種識別特徴（シマアジの黄帯と頭部帯、ギンガメアジの大眼、カイワリの小型菱形体型、イシガレイの石状斑、ウミタナゴの淡桃色無地、イシガキダイの石垣斑、オオモンハタの蜂の巣斑、アラの細長いハタ型）が読めるため採用。これでP2 B群17種の `source` + `contact_crop` 化を完了。画面freeze値・魚clip座標・文字配置は変更なし。判断根拠: `docs/qa/evidence/fish_assets/2026-07-08_p2_batch2_before_after.png`、`docs/qa/evidence/fish_assets/2026-07-08_p2_batch2_card_contact.png`、`docs/qa/evidence/fish_assets/2026-07-08_p2_batch2_source_contact.png`、`docs/qa/evidence/fish_book/2026-07-08_p2_batch2_fish_book_compare.png`。検証: `./tools/fish_book_visual_qa.sh` exit 0、`python3 tools/audit_fish_asset_duplicates.py --strict` exit 0（pending 0、unexpected 0）、`python3 tools/audit_fish_sheet_contract.py` exit 0。
