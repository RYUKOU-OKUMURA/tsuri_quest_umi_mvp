# 港画面 QA判断ログ

最終更新: 2026-07-10 / 状態: 右メニューに通知バッジ＋詳細パネルのコンテキストヒントを追加
参照画像: 完成イメージ `harbor_info_board_vision_v4.png`（会話生成。`docs/43`）。右メニューはHTMLモック（会話生成、本ファイル未保存）比較で決定
QA更新コマンド: `./tools/harbor_visual_qa.sh`

## 1. freeze値（正本）

| 項目 | 値 | 場所 | 理由・備考 |
|---|---|---|---|
| 港の情報板 | 左カラム上段 **0.035〜0.305**。見出し「本日の狙い目」。3カード（`harbor_info_fish_card.png`）横並び＋ポートレート＋魚名＋理由バッジ。枠は `harbor_info_board_frame.png`。魚素材は `FightFishAssets` 経由のみ | `src/ui/harbor_screen.gd` | 掲示板へ縦を譲る（v4余白詰め） |
| 出港プラン | 左カラム中段 **0.320〜0.805**。紙面は `harbor_plan_panel.png`（AI一点物）。行UI（ガイド／天気／狙いポイント／目撃談）＋行アイコン4種。本文16px。目撃談は折り返し可。StyleBoxFlat wash / ColorRect区切りは撤去。メガロドン前兆時は行を隠し `_preparation_body_label` で全文表示 | `src/ui/harbor_screen.gd` | Phase A: 仮置きwash→紙パネル |
| 時間帯ゾーン | 左カラム下端 **0.820〜0.985**。ラベル＋3等幅ボタン（明色未選択／金選択）をゾーンに密配置し、食事効果は直下の薄行。ゾーン内の大きな上下余白は置かない | `src/ui/harbor_screen.gd` | 完成イメージどおり下端へ寄せる |
| 狙い目候補 | `_harbor_highlight_candidates(max_count)`。依頼→時間帯ブースト→未捕獲。重複排除・乱数なし | `src/ui/harbor_screen.gd` | 情報板とプランで共有 |
| 初心者ガイド | `level <= GROWTH_SOFT_CAP(10)` のみ。調理未経験→依頼未達成→なければ狙い目文言 | `src/ui/harbor_screen.gd` | プラン1行目 |
| 天気気配 | スタブ固定文＋`harbor_weather_stub_icon.png`。先読み抽選は未実装 | `src/ui/harbor_screen.gd` | docs/43 §2 UI先行 |
| 出港主導線 | 左CTAなし。右メニュー「釣り場へ向かう」primaryのみ | `src/ui/harbor_screen.gd` | v3確定 |
| ヘッダー状況行 | `時間帯：{選択中}` のみ | `src/ui/harbor_screen.gd` | |
| フッター | `クーラーボックス：N匹　｜　プレイ時間：…` | `src/ui/harbor_screen.gd` | |
| 施設ナビアイコン | `nav_*`。依頼は `nav_quest_icon.png`、ロック中は `nav_lock_icon.png` | `src/ui/harbor_screen.gd` | nav全面刷新は未着手 |
| 右メニュー構成 | A案「セクション見出し付き4グループ」。表示順: departure（見出しなし・primary・高さ約36px）→ facility見出し「施設」（依頼ボード/調理場/魚市場/釣具店/船着き場/サメの生簀）→ record見出し「記録」（ステータス/魚図鑑）→ system見出し「システム」（タイトルへ戻る・小型ボタン高さ約24px）。行位置はセクション定義（`FACILITY_MENU_SECTION_DEFS`）から動的算出。row_step*indexのハードコード禁止 | `src/ui/harbor_screen.gd` `_build_facility_menu_rows` | 2026-07-09採用。旧: 見出しなしの単一10行リスト |
| 右メニュー見出しスタイル | フォント12px・字間広め（FontVariation spacing_glyph=2）・暗ブロンズ（`Palette.HARBOR_MENU_SECTION_LABEL` #7d5a1e。クリーム地に対しコントラスト比約5:1）・アウトラインなし。見出し右側に薄い同系ヘアライン1px（`Palette.HARBOR_MENU_SECTION_HAIRLINE`） | `src/ui/harbor_screen.gd` `_build_section_heading` | 初版の淡金#e0b568はクリーム地に溶けて不可読→暗色へ修正（2026-07-09） |
| ロック行の表現 | 行内8px条件テキストは廃止。スキンのみ`self_modulate`で減光（子ノードへ伝播させない）し、メインアイコン・アクセント・アイコンプレートは個別`modulate`で減光。右端に`nav_lock_icon.png`（縦0.18-0.82、27px行で約17px、減光対象外で常時視認可）を表示。解放条件は詳細パネルのbodyへ集約 | `src/ui/harbor_screen.gd` `_build_facility_button` | 初版の`button.modulate`は錠前まで沈めた→`self_modulate`へ修正（2026-07-09）。サメの生簀のみ現状対象 |
| 詳細パネル | 位置・高さは最終行位置から動的算出（`content_bottom + FACILITY_MENU_DETAIL_GAP`(約8px)〜メニュー下端-余白）。**最終ボタンより上への食い込みは禁止**（最終ボタン下端との可視ギャップ最低約4px）。縦不足時は`_build_facility_menu_rows`がセクションギャップ→行高の順で比例圧縮して全体を枠内へ収める。本文はautowrap | `src/ui/harbor_screen.gd` `_build_facility_detail_panel` | 初版の「MIN_HEIGHT優先でパネルを上へ動かす」フォールバックは撤去（2026-07-09） |
| 右メニュー通知バッジ | 対象行（依頼ボード／魚市場）の右上角に直径11pxの丸（`Palette.HARBOR_MENU_BADGE_FILL` 朱色 + `HARBOR_MENU_BADGE_BORDER` 濃紺2px縁）。ボタンの`clip_contents`を避けるためメニュー（`parent`）側の子として配置し固定pxオフセットでボタン内側へ収める。表示条件は`_facility_menu_items()`内で計算: 依頼ボード=`_has_deliverable_quest()`（quest_board_screen.gdの納品ボタン活性条件`completed`と同じ`PlayerProgress.quest_progress(index)`を読むだけ）、魚市場=`_cooler_fish_total() > 0`。ノード名は`FacilityMenuBadge_<title>`（同名衝突時のGodot内部名`@Panel@id`化を避けるため一意化） | `src/ui/harbor_screen.gd` `_build_facility_button` | 2026-07-10新設 |
| 右メニュー詳細パネルのデフォルト表示 | 純粋関数`_facility_menu_hint()`が優先度付きで返す: 1) 納品できる依頼あり→「つぎのおすすめ／納品できる依頼がある。依頼ボードへ」 2) クーラーボックスに魚あり→「つぎのおすすめ／クーラーボックスに{N}匹。魚市場で売ろう」 3) 該当なし→従来どおり「釣り場へ向かう／狙う魚に合わせてポイントを選ぶ」。hover/focus時の`_set_facility_detail`呼び出しは不変。新しい保存状態は作らない。パネルは`clip_contents=true`で本文が想定外に折り返しても枠外へ漏れない | `src/ui/harbor_screen.gd` `_facility_menu_hint` / `_build_facility_menu` | 2026-07-10新設 |

## 2. 不採用・再試行禁止リスト

| 案 | 却下理由 | 判断日 |
|---|---|---|
| 時間帯ごとの港背景PNGを先に作る | E5はグレーディング検証から | 2026-07-08 |
| 左カラム「釣り場へ向かう」大ボタン維持 | 右メニューと重複 | 2026-07-09 |
| 情報板枠へのポートレートスロット焼き込み | UIとずれて二重枠になる | 2026-07-09 |
| 時間帯を出港プラン羊皮紙内に埋め込む | 完成イメージと構成がズレ、余白と埋没が起きる | 2026-07-09 |
| 情報板を高さ約22%の細い帯のままポートレートだけ拡大 | 見切れ・主役不足。面積配分を先に直す | 2026-07-09 |

## 3. 微調整カウンタ

| パラメータ | 回数 | 直近の変更内容 | 状態 |
|---|---|---|---|
| 装飾パス累計 | 1 | 時間帯グレードColorRectのみ残存。出港プランwash/行区切りはPNG化で撤去 | 採用 |
| 情報板スロット配置 | 2 | v3bでカード背景＋ポートレート拡大 | 採用 |
| 時間帯ゾーンラベル色 | 1 | 暗い地向けに明るいラベルへ変更 | 採用 |
| 時間帯未選択ボタン素材 | 1 | v4明色羊皮紙＋濃茶枠へ再生成 | 採用 |
| 右メニュー行間隔・見出し | 1 | 単一10行リスト→A案4グループ（見出し3・行高/ギャップ動的算出）へ再構築 | 採用 |

## 4. 暫定判定・再検証TODO

なし。

## 5. 現在の残ギャップ

- 夜釣りの港背景は寒色グレードのみ。
- 天気気配の本物先読みは未着手。
- 右メニュー `nav_*` 本体の全面刷新は未実施（`nav_quest`・`nav_lock` のみ新設）。
- 情報板カード／枠素材の質感は完成イメージより簡素（PIL幾何）。Phase B でAI一点物へ。
- 出港プラン紙面・行アイコンは Phase A でAI一点物化済み（2026-07-09）。
- 詳細パネルの本文は1行運用（優先度2ヒントの長文が2行折り返しで枠外へ漏れたため文言を短縮し、`clip_contents`の保険を追加。2026-07-10）。

## 6. フェーズスコープ宣言（作業中のみ）

完了済みのためなし。


## 7. 判断ログ（直近パスのみ）

2026-07-09 右メニュー A案（セクション見出し付き4グループ）を採用。

スコープ宣言:
- 対象: `src/ui/harbor_screen.gd` の右メニュー（`_facility_menu_items` / `_build_facility_menu` 系）のみ。
- 対象外: 左カラム（情報板・出港プラン・時間帯）、ヘッダー、フッター、他画面素材。

変更したもの:
- 右メニューを見出しなし単一10行リストから「departure（primary・高さ約36px）→ facility見出し「施設」（6行）→ record見出し「記録」（2行）→ system見出し「システム」（小型ボタン約24px）」の4グループへ再構築。サメの生簀を施設グループ末尾へ移動。
- 行位置・行高・ギャップをセクション定義（`FACILITY_MENU_SECTION_DEFS`）から動的算出する`_build_facility_menu_rows`を新設（`row_step*index`のハードコードを撤去）。
- セクション見出しラベル（12px・字間広め・暗ブロンズ #7d5a1e・右に薄い同系ヘアライン1px）を新設。`Palette.HARBOR_MENU_SECTION_LABEL` / `HARBOR_MENU_SECTION_HAIRLINE` を追加（初版の淡金11pxはクリーム地で不可読のため同日修正）。
- ロック行（サメの生簀）の表現を変更: 行内8px条件テキストを廃止し、ボタン全体を`Palette.HARBOR_FACILITY_LOCKED_MODULATE`で減光＋右端に錠前アイコン（新規`nav_lock_icon.png`、`tools/generate_harbor_info_board_assets.py`にジェネレーター追加）を表示。解放条件は既存の詳細パネルbodyに集約。
- 詳細パネルの位置・高さを最終行位置から動的算出するよう変更（固定0.802開始→`content_bottom`起点）。本文をautowrap対応に変更。

変更していないもの:
- 左カラム（情報板・出港プラン・時間帯ゾーン）、ヘッダー、フッター、出港主導線ルール（右メニュー「釣り場へ向かう」primaryのみ）。
- `nav_*`本体（依頼/調理/魚市場/釣具店/船着き場/ステータス/魚図鑑/タイトル）の素材自体は差し替えていない。

判断根拠:
- `docs/qa/evidence/harbor/2026-07-09_menu_sections_a_asa_mazume.png`
- `docs/qa/evidence/harbor/2026-07-09_menu_sections_a_daytime.png`
- `docs/qa/evidence/harbor/2026-07-09_menu_sections_a_night.png`
- `docs/qa/evidence/harbor/2026-07-09_menu_sections_a_compare.png`
- `harbor_screen_smoke` 緑、`validate_project.sh` 緑

---

2026-07-10 右メニューに通知バッジ（依頼ボード／魚市場）と詳細パネルのコンテキストヒントを追加。

スコープ宣言:
- 対象: `src/ui/harbor_screen.gd` の右メニュー（`_facility_menu_items` / `_build_facility_button` / `_facility_menu_hint` / 詳細パネル初期表示）、`src/ui/palette.gd`（バッジ色2件追加のみ）、`tools/harbor_screen_smoke.gd`（バッジ・ヒットのケース追加）。
- 対象外: 左カラム（情報板・出港プラン・時間帯）、ヘッダー、フッター、quest_board/market画面本体、既存freeze値、既存パレット定数の変更、PNG素材の新規追加。

変更したもの:
- 通知バッジ: `_facility_menu_items()`で`quest_badge := _has_deliverable_quest()` / `market_badge := _cooler_fish_total() > 0`を計算し、依頼ボード・魚市場の項目dictに`"badge"`キーとして持たせる。`_build_facility_button`に`badge`引数を追加し、trueのとき直径11px・朱色塗り＋濃紺2px縁の丸（`Panel` + `StyleBoxFlat`）をボタン右上角へ配置。ボタンの`clip_contents=true`を避けるため`menu`（`parent`）側の子として追加し、固定pxオフセット（アンカー=ボタン右上角の1点、offsetでボタン内側4-15pxに収める）でボタン高さに依存せず完全可視にした。
- コンテキストヒント: 新規純粋関数`_facility_menu_hint() -> Dictionary`を追加（優先度1: 納品できる依頼あり→「つぎのおすすめ／納品できる依頼がある。依頼ボードへ」、優先度2: クーラーボックスに魚あり→「つぎのおすすめ／クーラーボックスに{N}匹。魚市場で売ろう」、優先度3: 該当なし→従来の「釣り場へ向かう／狙う魚に合わせてポイントを選ぶ」）。`_build_facility_menu`の初期`_set_facility_detail`呼び出しをこの関数の戻り値に差し替え。hover/focus時の`_set_facility_detail`呼び出し自体は無変更。
- 判定用の純粋関数を新設: `_has_deliverable_quest()`（quest_board_screen.gdの納品ボタン活性条件`button.disabled = not completed`（`src/ui/quest_board_screen.gd:253`、`progress := PlayerProgress.quest_progress(index)`, `completed := bool(progress.get("completed", false))`）と同じ`PlayerProgress.quest_progress(index).completed`を読むだけで、判定ロジックの複製はしていない）、`_cooler_fish_total()`（既存の`_refresh_labels()`内フッター用ループを関数化して共有、フッター表示側もこの関数を呼ぶよう変更。ロジック・出力は不変）。
- `Palette.HARBOR_MENU_BADGE_FILL`（朱色 #e8462c）・`Palette.HARBOR_MENU_BADGE_BORDER`（濃紺 #1c1a2e）を新設。既存パレット定数は変更していない。
- `tools/harbor_screen_smoke.gd`に`_verify_menu_badges_and_hint()`を追加（既存7ケースは無変更）。ケースA: 納品可能な依頼＋クーラーボックスに魚→両バッジ`badge=true`・ノード数2・ヒント優先度1。ケースB: 依頼なし・クーラーボックス空→両バッジ`false`・ノード数0・フォールバックヒント。ケースC: クーラーボックスのみ→魚市場バッジのみ`true`・ノード数1・ヒント優先度2（匹数を本文に含む）。

変更していないもの:
- 左カラム（情報板・出港プラン・時間帯ゾーン）、ヘッダー、フッターのレイアウト、右メニューのセクション構成・行位置算出ロジック（`_build_facility_menu_rows`）、ロック行の表現、既存パレット定数、quest_board/market画面本体。
- PNG素材は新規追加なし（バッジ・ヒントは完全runtime描画）。

判断根拠:
- `docs/qa/evidence/harbor/2026-07-10_menu_badges_daytime.png`（既定プレビュー状態＝クーラーボックス7匹・依頼なし。魚市場バッジのみ表示、ヒントは優先度2「クーラーボックスに7匹。魚市場で売ろう」を確認）
- `docs/qa/evidence/harbor/2026-07-10_menu_badges_asa_mazume.png` / `2026-07-10_menu_badges_night.png`（時間帯を変えても表示が変わらないことを確認）
- `docs/qa/evidence/harbor/2026-07-10_menu_badges_quest_supplement.png`（納品可能な依頼を追加した補足検証。依頼ボード・魚市場の両方にバッジが表示され、ヒントが優先度1「納品できる依頼がある。依頼ボードへ」に切り替わることを確認。`./tools/harbor_visual_qa.sh`本体は変更していないため、この1枚のみ検証専用の一時プレビューシーンで撮影し、リポジトリへは残していない）
- `harbor_screen_smoke` 緑（既存7ケース＋新規`_verify_menu_badges_and_hint`3ケース）、`validate_project.sh` 緑

採用理由:
- HTMLモック比較で確定していたA案（セクション見出し付き4グループ）どおりに実装。3時間帯すべてで全項目がメニュー枠内に収まり、重なり・見切れなし。primary行の高さ強調とロック行の減光＋錠前アイコンで主導線と施設グループの視認性が向上した。