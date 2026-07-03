# 25. 釣具店画面仕様

Date: 2026-07-03

## 目的

簡易実装の `src/ui/shop_screen.gd` を、竿と仕掛けを購入・装備できる本番寄りの釣具店画面へ正式化する。質感はPNG素材、商品名・価格・所持金・装備/所持/解放状態はGodot runtime描画で扱う。

## 参照画像の分解

参照画像:

- `reference/09_tackle_shop_rod_mockup.png`: 竿タブ
- `reference/09_tackle_shop_gear_mockup.png`: 仕掛けタブ

2枚は同一画面のタブ違いとして扱う。複数画面を1枚に詰めた合成モックではない。

### 存在する領域

| 領域 | 役割 |
|---|---|
| 店内背景 | 木製の店内、棚、店主、釣具の密度で釣具店らしさを作る |
| 上部 | 画面タイトル、Lv/装備竿/所持金、装備中の仕掛け |
| 商品タブ | 竿 / 仕掛けを切り替える |
| 商品カード一覧 | 竿3種または仕掛け6種をカードで表示し、選択対象を明確にする |
| 詳細パネル | 選択商品の説明、性能、対応エサ、代表魚、購入/装備操作を集約する |
| 下部メッセージ | 購入結果、資金不足、解放条件などの結果文を1箇所に表示する |

### 存在しない領域

- エサ単体の購入・在庫・消費管理。
- 船の購入導線。船は港の船着き場で扱う。
- 商品一覧以外のおすすめランキングや広告枠。
- 参照画像に見える文字をそのままPNG化した看板。

## 操作とデータ

- 主操作: 選択中の商品を購入または装備する。
- 補助操作: 竿/仕掛けタブ切替、港へ戻る。
- runtime表示: 商品名、説明、価格、装備/所持/購入可能/資金不足/Lv不足、所持金、装備竿、装備仕掛け、竿性能、対応エサ、代表魚。
- 既存ロジック: `PlayerProgress.buy_or_equip_rod()` と `PlayerProgress.buy_or_equip_rig()` を使い、データ構造やセーブ仕様は変更しない。

## PNG / runtime分担

| 対象 | PNG | runtime |
|---|---|---|
| 店内背景 | 背景、棚、店主、カウンター | 減光スクリム |
| UI枠 | ヘッダー、看板、商品カード、詳細パネル、メッセージ枠、タブ枠 | 選択中の表示切替、ラベル、ボタンテキスト |
| 商品 | 竿/仕掛け/エサカテゴリのアイコン | 商品名、価格、状態バッジ、性能値 |
| 状態 | なし | 所持金、装備中、所持、Lv不足、資金不足 |

## 採用しない参照要素

| 要素 | 理由 |
|---|---|
| 日本語入りの看板・商品札 | docs/19のテキスト焼き込み禁止に反するためruntime描画にする |
| エサ在庫販売に見える表現 | P2のスコープ外。エサは仕掛けの対応カテゴリとして表示する |
| 商品カードごとの過剰な金縁装飾 | 行/カード階層の金縁過多を避け、選択中のみ強調する |

## 素材構成

- `assets/showcase/tackle_shop/shop_bg.png`: 店内背景。
- `assets/showcase/tackle_shop/shop_header_frame.png`: 上部ヘッダー枠。
- `assets/showcase/tackle_shop/shop_title_sign.png`: タイトル看板。文字なし。
- `assets/showcase/tackle_shop/shop_detail_frame.png`: 詳細パネル枠。
- `assets/showcase/tackle_shop/shop_notice_frame.png`: 下部メッセージ枠。
- `assets/showcase/tackle_shop/shop_card_frame.png`: 商品カード通常枠。
- `assets/showcase/tackle_shop/shop_card_selected_frame.png`: 商品カード選択枠。
- `assets/showcase/tackle_shop/shop_tab_frame.png`: 非選択タブ枠。
- `assets/showcase/tackle_shop/shop_tab_active_frame.png`: 選択タブ枠。
- `assets/showcase/tackle_shop/shop_item_icon_sheet.png`: 竿3種+仕掛け6種のアイコンシート。
- `assets/showcase/tackle_shop/shop_bait_icon_sheet.png`: 対応エサカテゴリのアイコンシート。

## v1完了条件

- 竿タブと仕掛けタブの実スクショが参照画像と横並び比較できる。
- ItemListベースの旧構成が残っていない。
- 通常preview seedで日本語の省略・見切れ・重なりがない。
- 購入、装備、資金不足、Lv不足、港戻りがsmokeで通る。
- `tools/audit_showcase_asset_refs.py` と `./tools/validate_project.sh` が通る。
