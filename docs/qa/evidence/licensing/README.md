# 発売権利証拠インデックス

確認日: 2026-07-11

このフォルダには、公開一次情報へのリンクと、アカウント所有者だけが取得できる非公開証拠の保存状況を記録する。リンク先の規約は将来変更され得るため、発売候補確定時に再確認し、アカウント画面の証拠は個人情報・決済情報をマスクして保存する。

## 保存済み・repoで再確認可能

| 証拠 | 状態 | 根拠 |
|---|---|---|
| LINE Seed JP OFL 1.1 | 保存済み | `assets/fonts/line_seed/OFL.txt` |
| M PLUS 1p OFL 1.1 | 保存済み | `assets/fonts/OFL-MPLUS1p.txt` |
| icon追加履歴 | 履歴あり・作者未確定 | commit `9a9974a` で `assets/icon.svg` が新規追加。コミット著者だけでは法的な作者・権利者を確定しない |
| Godot開発版 | QAログあり | `docs/qa/evidence/refactor/2026-07-05_final_dod_command_log.txt` に 4.7 stable。最終export templateは未決 |

## 公式一次情報（2026-07-11確認）

| 対象 | 確認できる条件 | 公式URL |
|---|---|---|
| Suno有料プラン | Pro/Premier加入期間中に生成したOutputについて、規約遵守を条件にSunoの権利を利用者へ譲渡。公式Helpは動画ゲーム利用を含む商用利用を案内 | https://suno.com/terms/ / https://help.suno.com/en/articles/9601665 |
| Suno加入後の遡及 | 有料加入前のBasic生成物へ原則遡及しない | https://help.suno.com/en/articles/2425729 |
| OpenAI Output | 適用法で許される範囲で、利用者がOutputを所有し、OpenAIの権利を譲渡。ただし入力権利・非侵害は利用者責任 | https://openai.com/policies/terms-of-use/ |
| Godot | MIT本文等をゲームまたは配布物に含める。公式export templateの第三者ライセンスも確認が必要 | https://docs.godotengine.org/en/stable/about/complying_with_licenses.html |
| Steam AI開示 | プレイヤーが消費する開発時AI生成の画像・音源等はPre-Generated AIとしてContent Surveyで説明対象 | https://partner.steamgames.com/doc/gettingstarted/contentsurvey |

## ユーザー入力・保存待ち（未完了）

| ID | 必要な証拠または決定 | close条件 |
|---|---|---|
| U-01 | Suno 10音源それぞれの生成日時または曲詳細URL/画面 | 全ファイルとSuno生成物を一対一対応できる |
| U-02 | 生成期間を覆うSuno Billing HistoryとPro/Premier加入画面 | U-01の全生成日時が有料加入期間内に含まれる。決済番号・住所等はマスク可 |
| U-03 | 各 `assets/showcase/` generate外PNG、および `tools/source_assets/**` / `reference/**` を画素入力として読むsource/reference-consuming pipeline全件の採否・生成サービス・生成日・作成者申告・製品出力先 | 全source/referenceと製品出力が一対一または派生関係で追跡でき、原本非同梱を理由に派生製品を除外せず、推定が残らない。OpenAI以外のサービス利用も記録される |
| U-04 | `assets/icon.svg` の作者・作成手段・権利者、および製品採否 | 採用なら権利者申告、非採用なら差し替え側の証拠を台帳化 |
| U-05 | MITでライセンスするコードの法的権利者名 | `LICENSE.md` のplaceholderを実名または法人名へ置換 |
| U-06 | 正式製品名「釣りクエスト ～海釣り編～」/ v1.0.0は確定済み。販売地域・商標対象区分と、公式DB検索・必要な専門家確認の証跡 | 対象範囲を確定し、J-PlatPat等の公式DBと必要地域での調査結果を保存する |
| U-07 | 初回販売=itch.io、対象OS=macOS Universal、bundle ID=`net.physical-balance-lab.tsuri-quest-umi`、予定slug=`tsuri-quest-umi`、store App ID=`未発行`は確定済み。正確なGodot export preset/template、itch.io公開時のAI・年齢/コンテンツ関連入力の要否、最終配布物 | bundle IDをpresetへ配線し、実公開フローで必要項目を確認して回答控えを保存する。clean exportにGodot由来notice・`THIRD_PARTY_NOTICES.md`・2件のOFL全文が揃うことを検証する |
| U-08 | AI入力に第三者著作物・音源を用いたかの作成者申告 | サービス規約上必要な入力権利の確認を完了 |

## itch.io / macOS向けの提出・保存待ち

- itch.ioの実公開フローで、AI生成コンテンツ開示、年齢・コンテンツ区分、その他質問票の入力要否を公式手順により確認し、必要な場合は実内容に基づく回答控えを保存する。
- clean exportを展開し、`THIRD_PARTY_NOTICES.md`、Godot/export template由来の必要notice、2件のOFL全文が配布物に存在することを確認する。
- 将来Steamを採用する場合に限り、OpenAI画像とSuno音源をPre-Generated AIとしてContent Surveyへ申告し、提出控えを保存する。ゲーム内のlive生成は現状なし。
