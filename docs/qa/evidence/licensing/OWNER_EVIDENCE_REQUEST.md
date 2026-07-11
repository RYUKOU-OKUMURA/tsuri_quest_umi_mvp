# RIGHTS-01A アカウント所有者への証拠依頼

作成日: 2026-07-11

このファイルは未確認事項を推測で埋めないための提出チェックリスト。回答と画像は `docs/qa/evidence/licensing/` に保存する。決済番号、住所、カード番号はマスク可。第三者の個人情報は保存しない。

## 1. Suno 10曲（U-01 / U-02 / U-08）

次の各mp3について、対応する **Suno曲URL** と **生成日時（タイムゾーン付き）** を回答し、曲詳細画面を保存してください。

- `opening_bgm.mp3`
- `アタリ_ヒット音.mp3`
- `外海・回遊ルート.mp3`
- `岩礁・消波ブロック.mp3`
- `水中ファイト通常.mp3`
- `海辺（さざなみ）.mp3`
- `海辺（少し風が強い）.mp3`
- `港外・潮目.mp3`
- `砂浜・かけあがり.mp3`
- `逃げられた.mp3`

併せて、上記10件の最古生成日時から最新生成日時までを覆うBilling HistoryとPro/Premier加入期間画面を保存してください。10曲すべてについて、入力に第三者の楽曲、録音、歌詞、声、MIDI、stem、reference audio等を使ったかを回答してください。使った場合は、対象曲・入力物・権利者・利用許諾の証拠が必要です。

推奨ファイル名: `suno_tracks_YYYY-MM-DD.pdf`、`suno_billing_YYYY-MM-DD.png`、`suno_input_declaration_YYYY-MM-DD.md`

## 2. AI画像・source・reference（U-03 / U-08）

`docs/31_asset_ledger.md` §2.2の各source群と§4の各バッチについて、次を回答してください。

1. 作成者または生成操作を行ったアカウント所有者
2. 生成サービス（OpenAI / Cursor GenerateImage / その他。その他はサービス名と公式URL）
3. 生成日または生成セッションを特定できる日付範囲
4. 製品採用、製品への派生利用、中間物のみ、不採用のいずれか
5. 入力に第三者著作物、既存ゲーム画像、写真、ロゴ、商標、人物、他者のAI生成物を使ったか
6. 使った場合、その入力ファイル、権利者、利用許諾、派生利用可否の証拠

特に `reference/02_underwater_fight_mockup.png` と `reference/cooking_flow/01_cook_select_concept.png` は製品PNGへcrop/blendされているため、「referenceは非同梱」という回答だけではcloseできません。

推奨ファイル名: `ai_image_provenance_YYYY-MM-DD.csv`、`ai_input_declaration_YYYY-MM-DD.md`

## 3. icon（U-04）

`assets/icon.svg` について次を回答してください。

- 製品iconとして採用する / 採用しない
- 作者の法的氏名または法人名
- 作成手段（手描きSVG、生成AI、第三者素材の編集等）
- 権利者の法的氏名または法人名
- 第三者素材を使った場合の出所・ライセンス・改変可否

## 4. LICENSE権利者（U-05）

MITで公開する原創コードと文書をライセンスできる、正確な法的権利者名（個人の実名または法人登記名）を回答してください。Git表示名や屋号を自動採用しません。

## 5. 販売地域・商標（U-06）

次を回答してください。

- v1.0.0の販売地域（例: 日本のみ / 全世界。除外国があれば列挙）
- 「釣りクエスト ～海釣り編～」を使う商品・役務（downloadable game、オンライン提供、関連グッズ等）
- 専門家によるclearanceを発売条件にするか

回答後、対象地域の公式DBで、製品名、主要称呼、必要区分・類似群コードを検索し、検索日時・条件・全結果画面を保存します。日本はJ-PlatPat公式商標検索を使用します。検索結果が0件でも、条件と結果画面を保存します。

## 6. RIGHTS-01Bへ送る項目（この依頼ではcloseしない）

- RCで使用した正確なGodot export preset / template
- clean exportに含まれるGodot由来notice、`THIRD_PARTY_NOTICES.md`、OFL全文2件
- itch.io実公開フローのAI・年齢・コンテンツ質問票と回答控え
- 最終配布ZIPの内容・hash
