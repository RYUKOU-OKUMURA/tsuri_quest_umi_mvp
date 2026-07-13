# 49. 魚市場 M2 一点物素材発注仕様

作成日: 2026-07-13
対象: `docs/33_cooking_market_ui_uplift_plan.md` §3.1 M2
正式参照: `reference/10_fish_market_mockup.png`

M2は既存画面の局所upliftとして扱い、M1でfreezeした構成・主要矩形・6レイヤー順・4状態契約を変更しない。各スロットを独立した採否判断で直列に処理する。

## 1. `market_bg` — 魚市場の一点物背景

### 用途と出力

| 項目 | 仕様 |
|---|---|
| runtimeスロット | `MarketBackground` |
| source | `tools/source_assets/fish_market/market_bg_source.png` |
| 製品出力 | `assets/showcase/fish_market/market_bg.png` |
| 製品サイズ | 1280×720 px、RGBA、完全不透明 |
| 表示方式 | 全画面等倍。既存のheader / inventory / detail / ice tray / cartレイヤーを上へ合成 |

### スタイルアンカーと構図

- `reference/10_fish_market_mockup.png` の市場背景を方向性の正とする。参照画素の切り抜き・直接採用はしない。
- 港の常設魚市場。木梁と木製カウンター、空の木箱・魚箱、吊り秤、暖色ランタン、奥に見える青い海と空を配置する。
- 画面周辺に市場の物量を感じる前景小物を置き、中央は既存パネル3枚を載せても騒がしくならない密度にする。
- タイル調の精細な2Dピクセルアート。暖色ランタン光、濃紺・金・羊皮紙の既存UIと調和する色階調。写真調・3Dレンダー調にしない。
- processorで上から濃紺の減光スクリムを合成し、情報パネルの可読性を守る。

### 禁止事項

- 魚、魚の切り身、魚影、人物、キャラクターを描かない。
- UIパネル、UI枠、ボタン、アイコン、文字、数字、ロゴ、透かしを描かない。
- 日本語や可変値を焼き込まない。
- 参照画像そのものの複製、既存ゲーム固有の意匠、写真調・3D調を避ける。

### 加工契約

- sourceを中央クロップして16:9へ整形し、1280×720へLANCZOS縮小する。
- `src/ui/palette.gd` の `DARK_PANEL` を基準に色相を寄せ、上から28%の減光スクリムを決定的に合成する。
- processorは固定入力から同一bytesを出力し、他5スロットを一切書き換えない。

### 採用条件

1. 同一seedの4状態原寸比較で現行PIL背景へ明確に勝ち、UI可読性・M1レイヤー順・freeze矩形を壊さない。
2. 320×180のafter/reference比較で差分Top1「市場背景の不在」が明確に縮む。
3. 背景に魚・UI・文字がなく、空状態を含む全状態で残像に見える要素がない。

## 2. `ice_tray_hero` — 魚なしでも成立する査定トレー

### 用途と出力

| 項目 | 仕様 |
|---|---|
| runtimeスロット | `MarketIceTrayHero` |
| source | `tools/source_assets/fish_market/ice_tray_hero_source.png`（クロマキー原本） / `ice_tray_hero_cutout.png`（キー除去後） |
| 製品出力 | `assets/showcase/fish_market/ice_tray_hero.png` |
| 製品サイズ | 1280×720 px、RGBA透明レイヤー |
| 表示範囲 | M1 bbox `(738, 182)–(1119, 371)` の内側。runtime魚は `DETAIL_FISH_RECT` で上へ合成 |

### スタイルアンカーと構図

- `reference/10_fish_market_mockup.png` の右上査定台を方向性の正とする。参照画素の切り抜き・直接採用はしない。
- 低い木製の魚箱/査定トレーへ透明感のある砕氷を山盛りにし、左右へ笹葉を添える。魚を置かなくても「次の魚を待つ清潔な査定台」として自然に見える構図にする。
- 横長・やや俯瞰。木箱の前縁、側板、氷の山、葉の順で奥行きを作り、runtime魚を中央へ載せる余白を確保する。
- `market_bg` と同じ精細な2Dピクセルアート。写真調・3Dレンダー調にしない。

### 禁止事項

- 魚、魚の切り身、魚影、人物、手、キャラクターを描かない。
- UIパネル、UI枠、バッジ、文字、数字、ロゴ、透かし、床面、投影影を描かない。
- 日本語や可変値を焼き込まない。
- クロマキー色をトレー、氷、葉、木部へ混ぜない。

### 透明化・加工契約

- 生成は完全な単色 `#ff00ff` クロマキー背景で行い、背景の影・勾配・床・反射を禁止する。
- システムimagegen skillの `remove_chroma_key.py` をauto-key border、soft matte、threshold 12/220、despillで1回通し、透明四隅・alpha bbox・色縁を検証する。
- cutoutのalpha bboxを抽出し、縦横比を保って `(746, 202)–(1110, 366)` のsafe-areaへ中央配置する。LANCZOS縮小と既存市場色への10%環境ティントを決定的に適用する。
- processorは固定入力から同一bytesを出力し、他5スロットを一切書き換えない。

### 採用条件

1. 同一seedのselect/sold原寸で現行PIL氷台へ明確に勝ち、runtime魚が氷上へ自然に載る。
2. empty原寸で魚残像・空の皿・抜け殻に見えず、「魚を待つ査定台」として自然に成立する。empty→select復帰も維持する。
3. 320×180のafter/reference比較で差分Top2「hero査定トレーの氷+木箱の質感」が明確に縮む。
4. 透明bboxがM1の査定トレー範囲を越えず、detail/header/cart/panel枠と全freeze矩形を壊さない。
