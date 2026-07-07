# 40. READY専用下段バー品質改善 — 優先指示書

作成日: 2026-07-07
状態: 未着手（Codex投入用）
位置づけ: `docs/38_shark_bait_ready_selector_spec.md` §4 のREADY UIは機能実装済みだが、参照品質・一体感とも未達。本書は品質改善作業の**優先指示書**（Codex / ワーカー brief の正本）。スキル改訂（`skills/ui-screen-uplift/SKILL.md`・`skills/ui-screen-build/SKILL.md` 2026-07-07版）の初回適用例とする。

関連: `reference/13_fishing_ready_danger_mockup.png` / `docs/39_underwater_fight_ui_redesign_spec.md` §3 / `docs/qa/fishing_surface_qa.md`

---

## 背景

docs/38 §4 のREADY専用下段バー（危険海域のサメ餌魚セレクタ＋投げるボタン＋右メニュー）は機能実装済みだが、参照 `reference/13_fishing_ready_danger_mockup.png` に対し品質未達。監査で判明した構造要因は2つ:

1. **【最重要・構造】READY状態でもFIGHT用の枠PNG `assets/showcase/underwater/fight_hud_frame.png`（ゲージ3分割の内部区画が焼き込まれた素材）を全面描画し、その上にREADYパネルを重ねている**（`fight_hud.gd` の `_draw()` L159-168 付近）。結果、READYカードの背後・隙間にFIGHT時代の紺色区画や分割線が覗き、「ファイト画面の上にREADYを貼った」ように見える。これはゲーム開発者のクオリティー基準として不合格。READYバーは独立した1枚のバーとしてデザインし直すこと。
2. **【質感】** セレクタカード・投げるボタン・◀▶矢印・右メニューがすべて StyleBoxFlat のフラット直描画で、`assets/showcase/common/` の金縁9-slice素材が未配線。

---

## 読む順

1. `skills/ui-screen-uplift/SKILL.md`（2026-07-07改訂版。素材ファーストの順序と Acceptance Gate が更新済み）
2. `docs/38_shark_bait_ready_selector_spec.md` §4・§10
3. `docs/39_underwater_fight_ui_redesign_spec.md` §3（下段バーの枠素材・高さ設計はFIGHT刷新と共通化予定。今回作るREADYバー基盤が docs/39 の3ゾーン構成と共存できる作りにする）
4. `docs/19_ui_production_playbook.md` §2.1・§3.2・§4.2・§4.6
5. `docs/qa/fishing_surface_qa.md`（freeze表・§7判断ログ）

---

## concern（1つ）

READY下段バーを「FIGHT HUDへの重ね描き」から「専用デザインの1枚バー」へ作り直し、参照13の品質へ近づける。機能・状態遷移・抽選/消費ロジックには触らない。

---

## 作業内容（優先順）

### 0. 重ね描き構造の解消

READY状態では `fight_hud_frame.png` を背景に使わない。READY専用のバー基盤（外周フレーム＋各ゾーンパネル。内部にFIGHT用区画が無いもの）を共通キット素材で構成し、その上に3ゾーンを組む。READYバーのどこにもFIGHT用HUDの区画・分割線・パネルが覗かないこと。FIGHT系状態（CASTING以降）の描画経路は現行維持。

### 1. 共通キット配線

- セレクタカード: `common/card_frame.png` + `parchment_card.png`
- 投げるボタン: `common/action_button_frame.png`（または `button_frame_primary.png`）
- ◀▶矢印・右メニュー: `common/button_frame*.png`

StyleBoxFlat による金縁・紙面・CTA の質感代替を全廃する。キットで賄えない部品（バー外周フレーム等）が出たら、勝手に専用PNGを作らず「素材待ちP2」としてQAに起票して報告する。

### 2. 投げるボタンの主役化

中央ゾーンを埋めるサイズへ拡大。「仕掛け投入」見出しを撤去。E/Enter キーチップをボタン上部中央へ。ラベルは `GameFonts` の ExtraBold（docs/19 §4.2）。

### 3. セレクタカードの情報階層

魚ポートレートを参照どおりカード左半分の主役サイズへ拡大。見出し「サメ餌魚」を金文字・中央寄せへ。表示形式は docs/38 §4-2 の「魚名 xN」1行＋ピップ◆◆◇＋「あとN回」へ寄せ、現行 freeze（`fishing_surface_qa.md` §1 の「所持 xN」「1匹で最大N回」行）を改定する。freeze改定はQAの判断ログに理由を書くこと。

---

## 触ってよいファイル

- `src/ui/components/fight_hud.gd`（READY描画部）
- `src/ui/fishing_screen.gd`（READYバー関連の受け渡しのみ）
- `docs/qa/fishing_surface_qa.md`
- `docs/qa/evidence/fishing_surface/`

---

## 触ってはいけないもの

- FIGHT系HUDの freeze 値（高さ224px・下段幅比率26.5%/17.5%・ゲージ18分割）と CASTING以降の描画経路。外枠高さ224pxはREADYでも共有する（docs/38 §4-5）
- 抽選遅延・チャージ消費ロジック、simulator、水面ビュー素材、他画面素材
- docs/38 §4-4 の不採用要素（サメ形シルエット等）を復活させない
- `reference/*.png` のゲーム内直接インポート、日本語テキストのPNG焼き込み

---

## Definition of Done

- `./tools/validate_project.sh` green（素材参照監査を含む）
- `fishing_harbor_return_smoke` / `fishing_spot_select_smoke` / `harbor_screen_smoke` green
- `tools/fishing_surface_states_preview.tscn`（**非 headless 起動**。`--headless` は SubViewport 保存が失敗する既知問題）で docs/38 §4-2 の4状態（チャージあり / チャージなし所持あり / 餌魚なし / 所持0残チャージあり）＋通常釣り場READYの実スクショを取得
- READYスクショの下段バーに、FIGHT用HUDの区画・分割線が1箇所も覗いていない（等倍で確認）
- CASTING〜FIGHT・釣果のスクショが現行と同一（重ね描き解消の回帰確認）
- 参照13との横並び比較で「バーの一体感・金縁質感・主操作の主役感・カード階層」の差分が縮んだと縮小サムネ比較で判別できる
- `docs/qa/fishing_surface_qa.md` を `skills/ui-screen-uplift` の書式で更新（差分Top3・スコープ宣言・微調整カウンタ・freeze表上書き・共通キット未配線リストの解消記録）。比較画像を `docs/qa/evidence/fishing_surface/` へ日付付き保存

---

## 報告

変更概要 / 実行した検証と結果 / 未解決（素材待ちP2を含む）を短く。
