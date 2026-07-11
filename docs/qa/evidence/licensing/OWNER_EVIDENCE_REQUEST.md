# RIGHTS-01A アカウント所有者への証拠依頼

作成日: 2026-07-11

このファイルは未確認事項を推測で埋めないための提出チェックリスト。このrepositoryはpublicであり、**原本の画面・PDF・メール・請求書をGitへ追加してはならない**。原本はアクセス制御された非公開保管先で権利確認者だけが閲覧し、repositoryには個人情報を含まないsanitized attestation（確認書）だけを保存する。

### 公開repositoryへ保存禁止

- raw screenshot / screen recording / PDF / email / invoice / receipt
- 氏名、メールアドレス、住所、電話番号、アカウントID、請求・決済・注文・取引ID
- カード番号、下4桁、銀行・決済サービス情報、税務情報
- session token、秘密URL、共有リンク、private storageのパスワードや資格情報
- 上記を含むファイルの一部マスク版（復元・取り残しリスクがあるためraw由来画像/PDF自体をcommitしない）

原本は必ず非公開保管し、公開repositoryには次の全項目を持つUTF-8 Markdown attestationのみを置く。`Private-Storage-Reference` は組織内の非秘密な管理番号・保管棚ID等とし、URLや認証情報を書かない。

```text
Evidence-ID: U-01
Evidence-Type: suno-track-provenance
Original-SHA256: <原本ファイルbytesのsha256、小文字64桁>
Reviewed-At: YYYY-MM-DD
Reviewer: <確認者を識別できる非秘密の役割名または管理ID>
Private-Storage-Reference: <秘密でない保管参照ID。URL禁止>
Redaction-Checked: true
Finding: <個人情報を含まない判定要約>
```

IDごとに1つ以上のattestationを作り、`docs/qa/evidence/licensing/attestations/U-XX_*.md` として保存する。原本hashは照合用であり、原本そのものや秘密URLの代替ではない。公開前に、禁止項目が含まれないことを別の確認者が再確認する。

共通項目に加え、ID別に次のpayloadを必須とする。値を確認できない場合はcloseしない。

| ID | 必須payload |
|---|---|
| U-01 | `Asset-Count: 10`、`Covered-Assets:` に下記10ファイルを漏れなく列挙、`One-to-One-Mapping-Verified: true` |
| U-02 | `Plan: Pro` または `Premier`、`Period-Start/Period-End: YYYY-MM-DD`、`Covers-U-01: true` |
| U-03 | `Inventory-Contract: docs/31 sections 2.2 and 4`、`Unresolved-Items: 0`、`Provenance-Complete: true` |
| U-04 | `Product-Decision: adopted` または `rejected`、`Author-Verified: true`、`Rights-Holder-Verified: true` |
| U-05 | `License-Holder-Matches-LICENSE: true` |
| U-06 | `Territories:`、`Trademark-Classes:`、`Official-DB:`、`Search-Date: YYYY-MM-DD`、`Result-Count:` 非負整数、`Expert-Review: completed` または `not-required` |
| U-08 | `Covered-Media: suno-and-ai-images`、`Third-Party-Inputs: none` または `cleared`、`Clearance-Complete: true` |

## 1. Suno 10曲（U-01 / U-02 / U-08）

次の各mp3について、非公開原本上で対応するSuno曲と生成日時（タイムゾーン付き）を確認してください。公開attestationの`Finding`には曲URLそのものやアカウント情報を書かず、10件のファイル名、生成日時、対応確認結果だけを記録します。

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

併せて、非公開のBilling HistoryとPro/Premier加入画面で、上記10件の最古生成日時から最新生成日時まで加入期間が連続して覆うことを確認してください。10曲すべてについて、入力に第三者の楽曲、録音、歌詞、声、MIDI、stem、reference audio等を使ったかを確認します。使った場合は、対象曲・入力物・権利者・利用許諾の原本も非公開保管し、公開attestationには権利clearanceの判定だけを記録します。

Evidence-Type: U-01=`suno-track-provenance`、U-02=`suno-paid-period`、U-08=`ai-input-rights`

## 2. AI画像・source・reference（U-03 / U-08）

`docs/31_asset_ledger.md` §2.2の各source群と§4の各バッチについて、次を回答してください。

1. 作成者または生成操作を行ったアカウント所有者
2. 生成サービス（OpenAI / Cursor GenerateImage / その他。その他はサービス名と公式URL）
3. 生成日または生成セッションを特定できる日付範囲
4. 製品採用、製品への派生利用、中間物のみ、不採用のいずれか
5. 入力に第三者著作物、既存ゲーム画像、写真、ロゴ、商標、人物、他者のAI生成物を使ったか
6. 使った場合、その入力ファイル、権利者、利用許諾、派生利用可否の証拠

特に `reference/02_underwater_fight_mockup.png` と `reference/cooking_flow/01_cook_select_concept.png` は製品PNGへcrop/blendされているため、「referenceは非同梱」という回答だけではcloseできません。

詳細なアカウント画面・生成履歴exportは非公開保管する。公開attestationはファイル群と判定だけを記載し、プロンプトに個人情報がある場合は転記しない。

Evidence-Type: U-03=`ai-image-provenance`、U-08=`ai-input-rights`

## 3. icon（U-04）

`assets/icon.svg` について次を回答してください。

- 製品iconとして採用する / 採用しない
- 作者の法的氏名または法人名
- 作成手段（手描きSVG、生成AI、第三者素材の編集等）
- 権利者の法的氏名または法人名
- 第三者素材を使った場合の出所・ライセンス・改変可否

Evidence-Type: `icon-rights`

## 4. LICENSE権利者（U-05）

MITで公開する原創コードと文書をライセンスできる、正確な法的権利者名（個人の実名または法人登記名）を回答してください。Git表示名や屋号を自動採用しません。

個人の実名を権利者表示として公開する判断は本人が行う。非公開本人確認原本をrepositoryへ置かない。Evidence-Type: `license-holder`

## 5. 販売地域・商標（U-06）

次を回答してください。

- v1.0.0の販売地域（例: 日本のみ / 全世界。除外国があれば列挙）
- 「釣りクエスト ～海釣り編～」を使う商品・役務（downloadable game、オンライン提供、関連グッズ等）
- 専門家によるclearanceを発売条件にするか

回答後、対象地域の公式DBで、製品名、主要称呼、必要区分・類似群コードを検索し、検索日時・条件・全結果画面を非公開保管します。日本はJ-PlatPat公式商標検索を使用します。公開attestationには検索条件、検索日時、結果件数、判定を記録し、第三者の個人情報を転記しません。

Evidence-Type: `trademark-clearance`

## 6. RIGHTS-01Bへ送る項目（この依頼ではcloseしない）

- RCで使用した正確なGodot export preset / template
- clean exportに含まれるGodot由来notice、`THIRD_PARTY_NOTICES.md`、OFL全文2件
- itch.io実公開フローのAI・年齢・コンテンツ質問票と回答控え
- 最終配布ZIPの内容・hash
