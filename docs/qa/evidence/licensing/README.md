# 発売権利証拠インデックス

確認日: 2026-07-12

このフォルダには、公開一次情報へのリンクと、非公開原本を確認したsanitized attestationだけを記録する。このrepositoryはpublicのため、raw screenshot/PDF/email/invoice、アカウント・決済ID、カード下4桁、住所、秘密URL等は保存しない。原本はアクセス制御された非公開保管先に置き、ここには原本SHA-256、確認日、確認者、証拠種別、redaction確認、非秘密の保管参照ID、個人情報を含まない判定だけを残し、通常validateはtracked/untrackedを問わず管理文書を含む本ディレクトリ全体を走査し、公式allowlist外URLと明白なPII/決済labelを拒否する。詳細契約は `OWNER_EVIDENCE_REQUEST.md`。

## 保存済み・repoで再確認可能

| 証拠 | 状態 | 根拠 |
|---|---|---|
| LINE Seed JP OFL 1.1 | 保存済み | `assets/fonts/line_seed/OFL.txt` |
| M PLUS 1p OFL 1.1 | 保存済み | `assets/fonts/OFL-MPLUS1p.txt` |
| icon追加履歴 | 履歴あり・現行不採用回答済み | commit `9a9974a` で `assets/icon.svg` が新規追加。2026-07-18に製品不採用回答を受領したが、差し替え製品の統合と権利attestationは未完 |
| Godot開発版 | QAログあり | `docs/qa/evidence/refactor/2026-07-05_final_dod_command_log.txt` に 4.7 stable。最終export templateは未決 |

## 公式一次情報（2026-07-12確認）

| 対象 | 確認できる条件 | 公式URL |
|---|---|---|
| Suno有料プラン | Pro/Premier加入期間中に生成したOutputについて、規約遵守を条件にSunoの権利を利用者へ譲渡。公式Helpは動画ゲーム利用を含む商用利用を案内 | https://suno.com/terms/ / https://help.suno.com/en/articles/9601665 |
| Suno加入後の遡及 | 有料加入前のBasic生成物へ原則遡及しない | https://help.suno.com/en/articles/2425729 |
| OpenAI Output | 適用法で許される範囲で、利用者がOutputを所有し、OpenAIの権利を譲渡。ただし入力権利・非侵害は利用者責任 | https://openai.com/policies/terms-of-use/ |
| Godot | MIT本文等をゲームまたは配布物に含める。公式export templateの第三者ライセンスも確認が必要 | https://docs.godotengine.org/en/stable/about/complying_with_licenses.html |
| Steam AI開示 | プレイヤーが消費する開発時AI生成の画像・音源等はPre-Generated AIとしてContent Surveyで説明対象 | https://partner.steamgames.com/doc/gettingstarted/contentsurvey |
| J-PlatPat商標検索 | 商標名・称呼・商品役務（区分/類似群コード）を指定して公式の出願・登録情報を検索できる。検索対象とデータ反映時差の注意書きがあるため、検索日時・条件・結果画面を一組で保存する | https://www.j-platpat.inpit.go.jp/t0100 / https://www.j-platpat.inpit.go.jp/t1201 |

## 2026-07-11 U-01〜U-08再監査結果

リポジトリ内の保存証拠をファイル単位・証拠単位で再確認した。現時点では管理文書だけで、closeに使えるsanitized attestationは0件。アカウント所有者の画面等の原本は非公開保管も未確認である。一般規約の確認は個別素材のclearanceを意味しない。2026-07-18にU-04の現行icon不採用と、U-05の権利者名候補回答を受領したが、下表のとおりclose条件の一部だけであり、両IDを未完表に維持する。

| ID | 状態 | 再監査結果 / 次の証拠 |
|---|---|---|
| U-01 | 所有者証拠待ち | `assets/audio/*.mp3` 10件は列挙済みだが、各ファイルに対応するSuno曲と生成日時を確認したattestationが0件。確認形式は `OWNER_EVIDENCE_REQUEST.md` §1 |
| U-02 | 所有者証拠待ち | Billing History / Pro・Premier加入期間画面が0件。U-01の最古〜最新生成日時を連続して覆う証拠が必要 |
| U-03 | 所有者申告・証拠待ち | `docs/31` §2.2のsource/reference-consuming全行と§4のgenerate外画像について、既存作業記録がある一部を除き、ファイル単位のサービス・生成日・作成者・製品採否が未確定。453 PNGという母集団件数は追跡補助値であり、純粋生成・中間物・製品出力を含むため、それ自体を未clear件数とは扱わない |
| U-04 | 部分回答済み・差し替え証拠待ち | `assets/icon.svg` は2026-07-18の所有者回答で製品不採用。新規製品iconの統合、現行iconのrejected decision record、差し替え側のrights attestationは未保存 |
| U-05 | 候補回答済み・exact表記/証拠待ち | 所有者回答は `奥村 龍晃` または `OKUMURA RYUKOU`。公開表記は日本語＋ローマ字併記を推奨するがexactな単一表記は未確定で、canonical attestationも0件のため `LICENSE.md` placeholderを維持 |
| U-06 | 対象範囲決定・検索証拠待ち | 製品名は確定済み。販売地域と対象商品・役務区分が未決で、J-PlatPat検索条件・結果画面は0件。対象確定後、商標(検索用)・称呼・区分/類似群コード・検索日時・全結果を保存する |
| U-07 | **RIGHTS-01Bへ分離** | bundle ID等の決定値は保存済み。正確なexport template、clean export notice、itch.io実公開質問票はRC/公開フローでしか確定できないためRIGHTS-01Aのclose条件に含めない |
| U-08 | 作成者申告待ち | Suno 10曲とAI画像/source/referenceについて、第三者著作物・音源・画像・商標・人物素材を入力したかの作成者申告が0件。サービス一般規約だけではcloseしない |

所有者へ依頼する確認項目と公開禁止事項は [`OWNER_EVIDENCE_REQUEST.md`](OWNER_EVIDENCE_REQUEST.md) に固定した。アカウント画面等の原本は非公開保管し、公開repositoryには所定のsanitized attestationだけを置く。

2026-07-12時点の「現在の主張 / 必要証拠 / 現存証拠 / 判定 / 残作業」の全件監査と、外部入力の最短チェックリストは [`2026-07-12_RIGHTS-01A_AUDIT.md`](2026-07-12_RIGHTS-01A_AUDIT.md) に保存した。結論は、リポジトリ側の棚卸し・受入契約・検査準備は完了、RIGHTS-01A全体は7件の外部証拠待ちで未完了である。

## ユーザー入力・保存待ち（未完了）

| ID | 必要な証拠または決定 | close条件 |
|---|---|---|
| U-01 | Suno 10音源それぞれの生成日時・曲詳細を非公開原本で確認したattestation | 全ファイルとSuno生成物を一対一対応できる |
| U-02 | 生成期間を覆うSuno Billing HistoryとPro/Premier加入画面の非公開原本確認 | U-01の全生成日時が有料加入期間内に含まれ、公開repoにはsanitized attestationだけがある |
| U-03 | 各 `assets/showcase/` generate外PNG、および `tools/source_assets/**` / `reference/**` を画素入力として読むsource/reference-consuming pipeline全件の採否・生成サービス・生成日・作成者申告・製品出力先 | 全source/referenceと製品出力が一対一または派生関係で追跡でき、原本非同梱を理由に派生製品を除外せず、推定が残らない。OpenAI以外のサービス利用も記録される |
| U-04 | 現行icon不採用回答は受領済み。新規製品iconの統合と、現行iconのrejected decision record、差し替え側rights attestation | 差し替え製品のpath / bytes / 配線が確定し、decision recordとreplacement-rights recordを台帳化 |
| U-05 | 候補回答 `奥村 龍晃` / `OKUMURA RYUKOU` からexactな単一表記を確定し、非公開原本を確認したcanonical attestationを保存 | `LICENSE.md` のplaceholderを確定表記へ置換し、U-05 attestationと証拠indexを同時更新 |
| U-06 | 正式製品名「釣りクエスト ～海釣り編～」/ v1.0.0は確定済み。販売地域・商標対象区分と、公式DB検索・必要な専門家確認の証跡 | 対象範囲を確定し、J-PlatPat等の公式DBと必要地域での調査結果を保存する |
| U-08 | AI入力に第三者著作物・音源を用いたかの作成者申告 | サービス規約上必要な入力権利の確認を完了 |

## RIGHTS-01A完了済み

現時点では該当なし。証拠をcloseしたIDは、上の未完表から削除して次の表へ移し、sanitized attestationへの相対パスと確認日を記録する。raw private evidenceを記載・commitしない。

| ID | close日 | 保存証拠 / 判定 |
|---|---|---|

## RIGHTS-01B: itch.io / macOS向けの提出・保存待ち

| ID | RC / 公開時に必要な証拠 | close条件 |
|---|---|---|
| U-07 | 初回販売=itch.io、対象OS=macOS Universal、bundle ID=`net.physical-balance-lab.tsuri-quest-umi`、予定slug=`tsuri-quest-umi`、store App ID=`未発行`は確定済み。正確なGodot export preset/template、itch.io公開時のAI・年齢/コンテンツ関連入力の要否、最終配布物 | bundle IDをpresetへ配線し、実公開フローで必要項目を確認して回答控えを保存する。clean exportにGodot由来notice・`THIRD_PARTY_NOTICES.md`・2件のOFL全文が揃うことを検証する |

- itch.ioの実公開フローで、AI生成コンテンツ開示、年齢・コンテンツ区分、その他質問票の入力要否を公式手順により確認し、必要な場合は実内容に基づく回答控えを保存する。
- clean exportを展開し、`THIRD_PARTY_NOTICES.md`、Godot/export template由来の必要notice、2件のOFL全文が配布物に存在することを確認する。
- 将来Steamを採用する場合に限り、OpenAI画像とSuno音源をPre-Generated AIとしてContent Surveyへ申告し、提出控えを保存する。ゲーム内のlive生成は現状なし。
