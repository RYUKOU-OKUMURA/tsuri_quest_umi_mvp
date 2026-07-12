# RIGHTS-01A リポジトリ側証跡監査

監査日: 2026-07-12

対象: U-01〜U-08。U-07はRCと公開フローで確定するRIGHTS-01Bとして境界だけを再確認した。判定はリポジトリと公式一次資料で検証できる範囲に限定し、一般規約、検索結果、Git著者、従前の自己申告を個別素材の権利証明へ昇格しない。この文書は2026-07-12時点の歴史的snapshotであり、将来READMEのcurrent stateが進んでも当時判定を書き換えない。

## 監査結果

| ID | 現在の主張 | 必要証拠 | 現存証拠 | 判定 | 残作業 |
|---|---|---|---|---|---|
| U-01 | 音源10件はSuno生成との従前申告がある | 各mp3とSuno曲、timezone付き生成日時の一対一対応を非公開原本で確認したsanitized attestation | mp3 10件、台帳の列挙、Suno一般条件。canonical attestationは0件 | pending。個別曲の由来と生成日時をrepoから検証不能 | 所有者が10曲の原本を提示し、確認者がU-01 attestationを作る |
| U-02 | 2026-07-06時点でPro加入との従前申告がある | U-01の最古から最新生成日を連続して覆うProまたはPremier加入期間の非公開原本確認 | Suno一般条件。Billing Historyまたは加入画面のattestationは0件 | pending。申告だけでは生成時点の有料期間を確定不能 | U-01後、確認者が加入期間原本と全生成日を照合してU-02 attestationを作る |
| U-03 | 一部画像はOpenAI生成との作業記録があり、未確定画像とsource-consuming派生物が残る | `docs/31` §2.2と§4の確定母集団全件について採否、digest、生成サービス、timezone付き生成期間、作成者、派生関係を示すmanifest | 台帳、生成スクリプト、Git履歴、既知バッチ記録。canonical attestationは0件 | pending。既知バッチ以外を推定で補完できず、母集団全件のprovenanceが未確定 | 所有者または生成担当者が全件を分類し、確認者がU-03 manifestを作る |
| U-04 | 現行iconはcommit `9a9974a`で追加されたcustom SVG | 現行採用なら作者、作成手段、法的権利者。非採用なら製品差し替えと差し替え素材の権利証拠 | SVG bytes、追加履歴、固定SHA-256。作者と権利者のattestationは0件 | pending。Git著者は作者または法的権利者の証明ではない | 所有者が採用または差し替えを決定し、該当するU-04 attestationを作る |
| U-05 | original codeはMIT予定だが法的権利者名が未確定 | コードをMITで許諾できる個人または法人の正式名と確認書 | `LICENSE.md`の適用範囲と意図的placeholder | pending。名前をGit著者等から推定不可 | 権限者が正式名を回答し、確認後にLICENSEとU-05 attestationを同時更新する |
| U-06 | 正式製品名と版は確定済み | 販売地域、対象区分、検索語・称呼・類似群コード、検索日時、全結果、必要な専門家判断 | 正式名、J-PlatPat公式検索入口と一般説明。検索attestationは0件 | pending。対象範囲未決で検索結果もなく、検索だけで法的保証にもならない | 権限者が地域と区分を決め、公式DB検索を保存し、必要性判断を含むU-06 attestationを作る |
| U-07 | 初回itch.io、macOS Universal、bundle ID等は確定済み | 正確なexport template由来notice、clean export検査、実公開質問票 | repo内決定値、Godot公式ライセンス順守手順 | RIGHTS-01A対象外。RIGHTS-01Bでpending | RC作成後に配布物と公開フローを検査する |
| U-08 | AI素材の一般規約は入力権利を利用者責任としている | Suno 10曲とU-03母集団全件の入力素材有無、必要な権利・許諾を確認したmanifest | SunoとOpenAIの一般条件、source/reference-consuming経路。canonical attestationは0件 | pending。入力権利と第三者権利をrepoから確定不能 | U-01とU-03後、作成者申告と必要な許諾原本を確認してU-08 manifestを作る |

## 公式一次資料の再確認

2026-07-12に次を再確認した。Sunoは有料期間中の生成物について条件付きの権利譲渡とゲーム利用を案内する一方、入力権利と非侵害を保証しない。OpenAIは適用法の範囲でOutputの権利を利用者へ譲渡する一方、Inputに必要な権利は利用者責任とする。GodotはMIT本文とexport templateに含まれる第三者noticeの配布を求める。J-PlatPatは公式検索手段だが、検索結果を法的保証とは扱わない。

- https://suno.com/terms/
- https://help.suno.com/en/articles/9601665
- https://openai.com/policies/terms-of-use/
- https://docs.godotengine.org/en/stable/about/complying_with_licenses.html
- https://www.j-platpat.inpit.go.jp/t0100
- https://www.j-platpat.inpit.go.jp/t1201

## 外部入力の最短チェックリスト

1. U-01: Suno 10曲の曲詳細とtimezone付き生成日時を非公開原本で提示する。
2. U-02: 10曲の全生成日を覆うProまたはPremier加入期間原本を提示する。
3. U-03: 画像母集団全件の採否、生成元、生成期間、作成者、派生関係を回答する。
4. U-04: 現行iconを採用するか決め、採用なら作者・作成手段・権利者、非採用なら差し替え素材と権利証拠を提示する。
5. U-05: MITで許諾するコードの法的権利者の正式名を回答する。
6. U-06: 販売地域と商標対象区分を決め、公式DB検索と必要な専門家判断を保存する。
7. U-08: SunoとAI画像への第三者入力の有無を作成者が回答し、使用ありなら許諾原本を提示する。

原本は非公開保管し、公開repositoryへ領収書、請求情報、個人情報、アカウント情報、秘密URL、秘密鍵を追加しない。公開側には `OWNER_EVIDENCE_REQUEST.md` のschemaを満たすsanitized attestationだけを保存する。

## 結論

リポジトリ側で可能な棚卸し、証拠受入形式、機密情報境界、状態判定は準備完了。U-01〜U-06とU-08は外部証拠待ちのためpendingを維持し、RIGHTS-01A全体は未完了である。U-07はRIGHTS-01Bとして未完了であり、この監査でcloseしない。
