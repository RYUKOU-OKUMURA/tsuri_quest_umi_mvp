# RIGHTS-01A アカウント所有者への証拠依頼

作成日: 2026-07-11

このファイルは未確認事項を推測で埋めないための提出チェックリスト。このrepositoryはpublicであり、**原本の画面・PDF・メール・請求書をGitへ追加してはならない**。原本はアクセス制御された非公開保管先で権利確認者だけが閲覧し、repositoryには個人情報を含まないsanitized attestation（確認書）だけを保存する。

### 公開repositoryへ保存禁止

- raw screenshot / screen recording / PDF / email / invoice / receipt
- 氏名、メールアドレス、住所、電話番号、アカウントID、請求・決済・注文・取引ID
- カード番号、下4桁、銀行・決済サービス情報、税務情報
- session token、秘密URL、共有リンク、private storageのパスワードや資格情報
- HTML tag/comment、Unicode format/control文字、Markdown装飾や表へ埋めた個人情報
- macOS / Linux / Windowsの絶対path（home以外を含む）、parent traversal、file scheme等の非公開URI、protocol-relative URL、bare IP・IDN・Unicode dotを使った宛先
- raw base64 payload（短いPNG signature付きpayload、50文字以上へ分割したwrapped payloadを含む。大小hex 64桁のSHA-256は除く）
- 上記を含むファイルの一部マスク版（復元・取り残しリスクがあるためraw由来画像/PDF自体をcommitしない）

原本は必ず非公開保管し、公開repositoryには次の全項目を持つUTF-8 Markdown attestationのみを置く。`Reviewer`は2〜64文字の`A-Z a-z 0-9 _ -`、`Private-Storage-Reference`は3〜64文字の`A-Z 0-9 _ -`だけを使う。後者は組織内の非秘密な管理番号・保管棚ID等とし、URLや認証情報を書かない。どちらもdotを使わない。

```text
Evidence-ID: U-01
Evidence-Type: suno-track-provenance
Original-SHA256: {原本ファイルbytesのsha256、小文字64桁}
Reviewed-At: YYYY-MM-DD
Reviewer: reviewer_1
Private-Storage-Reference: EVIDENCE_12345
Redaction-Checked: true
Finding: track-provenance-verified
```

U-01/U-02/U-03/U-05/U-06/U-08はIDごとにexactly one canonical attestationを作り、`docs/qa/evidence/licensing/attestations/U-XX_*.md` として保存する。U-04だけはdecision recordがexactly oneで、rejected時に限りdistinctなreplacement-rights recordをexactly one追加する。原本hashは照合用であり、原本そのものや秘密URLの代替ではない。公開前に、禁止項目が含まれないことを別の確認者が再確認し、通常validateはこのディレクトリをtracked/untrackedにかかわらず再帰走査し、privacy scan済み管理文書2件、任意の**0 byteのみ**の`attestations/.gitkeep`、契約準拠attestation以外を拒否する。日本語・英語のlabel/value、Markdown装飾と表、nested HTML entity、HTML tag/comment、Unicode format/control文字、絶対path・traversal、URL・bare destination、raw base64、カード・電話らしい数列を公開文書全体で検査する。管理文書のURLは監査内の公式一次情報allowlistだけを許可する。repo-relative pathは許可するが、attestation内のasset filename/pathはschemaが指定する母集団と実在ファイルへ限定する。未参照attestationもprivacy検査対象である。完了表から参照するattestationとU-04 replacementはGit indexへ追加済みでなければならない。complete対象のattestation・素材・音源・icon・LICENSE・状態文書はworking bytesとGit index blobのSHA-256一致も必須とし、staged後のunstaged変更を許可しない。close日・`Reviewed-At`・`Search-Date`・`Evidence-As-Of`の未来判定は実行環境のTZに依存させずAsia/Tokyoの暦日で行う。

`Finding`は自由記述ではなく、次のsafe codeのexact matchだけを許可する。個人情報や原本内容の要約は別fieldにも追加しない。

| Evidence-Type | Finding safe code |
|---|---|
| `suno-track-provenance` | `track-provenance-verified` |
| `suno-paid-period` | `paid-period-verified` |
| `ai-image-provenance` | `image-provenance-verified` |
| `icon-rights` | `icon-rights-verified` |
| `icon-replacement-rights` | `replacement-rights-verified` |
| `license-holder` | `license-holder-verified` |
| `trademark-clearance` | `trademark-clearance-reviewed` |
| `ai-input-rights` | `ai-input-rights-cleared` |

共通項目に加え、ID別に次のpayloadを必須とする。値を確認できない場合はcloseしない。

| ID | 必須payload |
|---|---|
| U-01 | exactly one canonical attestation。`Asset-Count: 10`、`Track-01:`〜`Track-10:`を`filename;content-sha256;generated-at;mapping-id`形式で記載、`One-to-One-Mapping-Verified: true`。generated-atはtimezone付き`YYYY-MM-DDTHH:MM:SSZ`または`±HH:MM`、mapping-idは曲URLやaccount IDではない一意の非秘密管理IDで`A-Z 0-9 _ -`のみ（dot禁止）。content hashを現在のmp3 bytesと照合 |
| U-02 | exactly one canonical attestation。`Plan: Pro` または `Premier`、`Period-Start/Period-End/Evidence-As-Of: YYYY-MM-DD`、`Covers-U-01: true`。U-01完了が前提。`Evidence-As-Of`は加入期間内かつ`Reviewed-At`以下・Asia/Tokyoの監査日以下とする。自動更新中の契約では`Period-End`が未来でもよいが、加入確認済み範囲は`min(Period-End, Evidence-As-Of)`までであり、各generated-atのoffset上の暦日min/maxがこの確認済み範囲へ入らなければcloseしない |
| U-03 | exactly one canonical attestation。`Inventory-Contract: docs/31 sections 2.2 and 4`、`Population-Count:`、path+current content digestで算出する`Population-SHA256:`、`Item-0001:`以降を`path;content-sha256;disposition;provenance-id`形式で現在の`assets/showcase/**/*.png`・`tools/source_assets/**/*.png`・`reference/**/*.png`全件分。さらに`Provenance-Count:`と`Provenance-0001:`以降を`id;service;generated-start;generated-end;creator-id`形式で記録する。生成日時はtimezone付き。provenance-idは`A-Z 0-9 _ -`、service/creator-idは`A-Z a-z 0-9 _ -`のみ（すべてdot禁止）で、creatorは非秘密role/ID。バッチでprovenance ID共有可だが、全item IDが一意なrecordへ解決し、未参照recordを残さない。`Unresolved-Items: 0`、`Provenance-Complete: true` |
| U-04 | exactly one `Evidence-Type: icon-rights` decision record。どちらも`Baseline-Original-Content-SHA256: 493a29b86943751f2441343ebc347a9fa42b046032dedd7d1fcb86fd51567595`を必須とし、元icon削除後もこの既知bytesを差し替えに再利用できない。adopted: `Product-Decision: adopted`、同じdigestの`Product-Content-SHA256:`、`Author-Verified: true`、`Rights-Holder-Verified: true`だけを持ち、replacement payloadは禁止。rejected: `Product-Decision: rejected`、`Replacement-Integrated: true`、`Replacement-Product-Path:`、`Replacement-Content-SHA256:`、distinctな`Replacement-Rights-Attestation:`だけを持ち、adopted-only payloadは禁止。rights recordは別pathの`Evidence-Type: icon-replacement-rights`で`Replacement-Asset-Path:`、`Replacement-Content-SHA256:`、`Replacement-Asset-Rights-Verified: true`だけを持つ。self-reference禁止。replacementはcanonical repo-relative path、許可画像拡張子、元`assets/icon.svg`とはpath・inode・既知bytesすべてが異なること。差し替え本体・両attestationはGit index登録済み、`config/icon`配線、docs/31記載とintegration markerも監査する |
| U-05 | exactly one canonical attestation。`License-Holder-Matches-LICENSE: true` |
| U-06 | exactly one canonical attestation。`Territories:`、`Trademark-Classes:`、`Official-DB:`、`Search-Date: YYYY-MM-DD`、`Result-Count:` 非負整数、`Expert-Review: completed` または `not-required` |
| U-08 | exactly one canonical attestation。U-01/U-03完了が前提。`Covered-Media: suno-and-ai-images`、`Population-Count:`、path+current content digestの`Population-SHA256:`、`Item-0001:`以降を`asset;content-sha256;none|cleared;rights-id`形式で音源10件＋U-03確定母集団全件分、rights-idは`A-Z 0-9 _ -`のみ（dot禁止）、`Clearance-Complete: true` |

## 1. Suno 10曲（U-01 / U-02 / U-08）

次の各mp3について、非公開原本上で対応するSuno曲と生成日時（タイムゾーン付き）を確認してください。10件のファイル名、生成日時、対応確認結果は`Track-01`〜`Track-10`へ記録し、`Finding`には上表のfixed safe codeだけを書きます。

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

併せて、非公開のBilling HistoryとPro/Premier加入画面で、上記10件の最古生成日時から最新生成日時まで、`Evidence-As-Of`時点で加入確認済みの期間が連続して覆うことを確認してください。契約上の終了予定日が未来でも、その未来分だけに依存してcloseしません。10曲すべてについて、入力に第三者の楽曲、録音、歌詞、声、MIDI、stem、reference audio等を使ったかを確認します。使った場合は、対象曲・入力物・権利者・利用許諾の原本も非公開保管し、公開attestationには権利clearanceのfixed safe codeとU-08 manifestだけを記録します。

Evidence-Type: U-01=`suno-track-provenance`、U-02=`suno-paid-period`、U-08=`ai-input-rights`。U-02はU-01完了後でなければcloseできない。

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

現行原本`assets/icon.svg`のdecision baselineはSHA-256 `493a29b86943751f2441343ebc347a9fa42b046032dedd7d1fcb86fd51567595`に固定する。非採用後に原本を削除しても、このdigestと同じbytesを別pathへ置いたものは差し替えとして認めない。

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
