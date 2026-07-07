# 魚素材の同一画像使い回し 調査結果と修正計画

Date: 2026-07-07

対象素材: `assets/showcase/fish/*_card_portrait.png` / `*_showcase_sheet.png`
生成パイプライン: `tools/process_underwater_fish_assets.py`
素材条件の正本: `docs/24_fish_book_portrait_asset_brief.md`
証拠画像: `docs/qa/evidence/fish_assets/2026-07-07_dup_*.png`

## 1. 事象

魚の名前が違うのに、図鑑・水中ファイト・市場・調理で同じ（またはほぼ同じ）画像が表示される魚が多数ある。

## 2. 調査方法

1. 全PNGのMD5比較 → バイト同一の重複は**なし**
2. デコード後ピクセルのSHA1比較 → ピクセル完全一致も**なし**
3. グレースケール知覚ハッシュ（dhash 16x16）で全ペアのハミング距離を計測し、portrait/sheetのいずれかが距離12以下のペアをクラスタリング
4. クラスタを横並び画像に合成して目視確認（証拠画像として保存）
5. `tools/process_underwater_fish_assets.py` の `FISH_ART_SOURCES` を解析し、生成上の由来を特定

## 3. 原因

`FISH_ART_SOURCES`（`tools/process_underwater_fish_assets.py`）には2種類のエントリがある。

- **オリジナル30種**: AI生成コンタクトシート3枚（`tools/source_assets/fish/fish_final_art_contact_sheet.png`, `fish_expansion_contact_sheet_1/2.png`）から `contact_crop` で切り出し
- **テンプレート派生40種**: `"template": "<他魚id>"` 指定。他魚の元アートに tint（色替え）・scale（伸縮）・markings（簡易模様）を適用しただけの派生

派生40種のうち大半は形状がテンプレート元と同一のため、名前が違う魚が「色違いの同じ絵」になっている。これは docs/24 §素材条件の「**魚種の識別特徴を優先する。色違いだけで別魚に見える候補は不採用**」に反する状態。

テンプレート派生の全マップ（→ の右が派生種）:

| テンプレート元 | 派生種 |
|---|---|
| akahata | nenbutsudai, houbou, oomonhata |
| aobudai | kyusen, kobudai, ira |
| fuefukidai | ojisan |
| hiramasa | tsumuburi |
| hirame | makogarei, ishigarei, shitabirame |
| isaki | takabe |
| ishidai | ishigakidai |
| iwashi | sappa, konoshiro |
| kamasu | sayori, sawara, datsu |
| kasago | kanagashira, murasoi, onikasago |
| katsuo | hirasouda, suma, kihada, binnaga, mebachi |
| kochi | mahaze, megochi |
| kue | ara |
| madai | meichidai, akamutsu, kinmedai |
| mebaru | kurosoi, takenokomebaru |
| mejina | umitanago |
| rouninaji | shimaaji, gingameaji, kaiwari, medai |
| tachiuo | maanago |

## 4. 調査結果（判定つき）

判定分類:

- **A: 種の描写自体が誤り** — 別科の魚の絵になっている、または名前の由来である識別特徴が欠けている。新規ソースアート必須
- **B: 同一ベースで判別困難** — 体型・科は近いが、ゲーム内（図鑑の隣接カード等）で見分けがつかない。新規ソースアート推奨
- **C: 当面許容** — 体型が正しく、色・シルエット差で判別できる。据え置き

距離 d はdhashハミング距離（portrait / sheet）。d が小さいほど同一。参考: 完全同一=0、無関係な魚同士はおおむね30以上。

### A: 種の描写が誤り（15種・最優先）

| 魚 | 現状の絵 | 何が誤りか |
|---|---|---|
| houbou（ホウボウ） | akahata（ハタ）の色替え。oomonhata と d=1/11 | ホウボウ科。翼状の大胸鰭・角張った頭という最大の特徴がない |
| kanagashira（カナガシラ） | kasago（カサゴ）の色替え | ホウボウ科なのにカサゴの絵 |
| kyusen（キュウセン） | aobudai（ブダイ）の縮小色替え。ira と d=8/4 | ベラ科の細身の魚なのにブダイの絵 |
| ira（イラ） | aobudai の色替え | ベラ科なのにブダイの絵 |
| kobudai（コブダイ） | aobudai の色替え＋頭部変形 | 赤褐色・額のコブが特徴なのに青緑のブダイのまま |
| ojisan（オジサン） | fuefukidai の縮小色替え。d=8/18 | ヒメジ科。名前の由来である**あごひげ**がない。タイの絵 |
| kinmedai（キンメダイ） | madai の色替え。d=4/11 | キンメダイ科。大きな金色の眼・全身深紅が特徴なのにマダイの絵 |
| akamutsu（アカムツ） | madai の色替え | 大眼・赤褐色のノドグロなのにマダイの絵 |
| medai（メダイ） | rouninaji（GT）の色替え。kaiwari と d=10/12 | イボダイ科の丸頭・黒灰色なのにヒラアジの絵 |
| sayori（サヨリ） | kamasu の変形色替え。sawara と d=12/6 | 下顎の針状突出（サヨリの識別特徴そのもの）がない |
| sawara（サワラ） | kamasu の変形色替え | サバ科の体型ではなくカマスの絵 |
| binnaga（ビンナガ） | katsuo の色替え。kihada と d=7/6 | 名前の由来である長い胸鰭がない（markings "long_fin" は機能していない） |
| mahaze（マハゼ） | kochi の色替え | ハゼ科なのにコチの絵 |
| nenbutsudai（ネンブツダイ） | akahata の縮小色替え | 小型のテンジクダイ科なのにハタの絵 |
| konoshiro（コノシロ） | iwashi の色替え。d=9/3 | 肩の黒斑・背鰭の糸状延長がない。イワシとほぼ同じ絵 |

### B: 同一ベースで判別困難（17種・第2優先）

| グループ | 距離 | 内容 |
|---|---|---|
| shimaaji / gingameaji / kaiwari（← rouninaji） | shimaaji↔gingameaji d=1/4 | 銀ヒラアジの絵の使い回し。シマアジの黄色線は細線1本の加筆のみで判別不能。3種とも新規 |
| kihada / mebachi（← katsuo） | d=2/6 | キハダに黄線を足しただけ。マグロ2種はカツオと別の体型で新規（binnaga はA） |
| hirasouda / suma（← katsuo） | d=8/7 | 相互にほぼ同一。スマ=胸鰭下の黒点、ヒラソウダ=背の虫食い模様、と判別特徴を分けて新規 |
| makogarei / ishigarei（← hirame） | hirame↔makogarei d=2/8 | ヒラメとカレイで眼の向きが逆のはずが同一の絵。2種とも新規 |
| meichidai（← madai） | d=4/7 | 灰褐色・眼帯模様のはずがマダイの色替え |
| takabe（← isaki） | d=5/3 | タカベ科。青い体に黄色帯1本のはずがイサキの色替え |
| umitanago（← mejina） | d=12/9 | 無地銀桃色のはずが縞模様のまま |
| ishigakidai（← ishidai） | d=9/49 | 石垣状の斑点のはずが縞のまま（markings "dark_spots" が機能していない） |
| oomonhata（← akahata） | akahata と目視酷似 | ハタ同士で体型は正しいが蜂の巣状斑が出ておらず判別困難 |
| onikasago / murasoi（← kasago） | d=9/8 | カサゴ系で体型は近いが3種ほぼ同一。オニカサゴは強い棘・皮弁が特徴 |
| ara（← kue） | 目視酷似 | クエとほぼ同一。アラは細身で棘が強い |

### C: 当面許容（据え置き・8種）

体型が実魚として正しく、ゲーム内でも判別できるため今回は動かさない。

- sappa（← iwashi）: 小型銀色で判別可
- shitabirame（← hirame）: 舌型に変形済みで判別可
- datsu（← kamasu）: 細長い変形で判別可
- maanago（← tachiuo）: 茶色の細身で判別可
- megochi（← kochi）: コチ科同士。d=9だがサイズ・色で判別可（境界ケース。P2完了後に再評価）
- kurosoi / takenokomebaru（← mebaru）: ソイ類同士で体型正。相互 d=12 は境界ケース。P2完了後に再評価
- tsumuburi（← hiramasa）: 青物同士で近いが帯色で判別可
- mejina（オリジナル）: 元絵自体が縞模様でイシダイ寄りに見える品質課題あり。使い回しではないため本計画の対象外とし、図鑑upliftの素材候補として別途扱う

### 対象外（意図的派生・記録済み）

- **megalodon ↔ nushi_danger_reef**（d=7/8）: E10でOpenAI生成ソースからの派生として意図的に作成（`tools/generate_megalodon_fish_assets.py`、docs/31 記録済み）。仕様どおり
- **nushi_* 7体**: 既存魚素材のプロシージャル派生（`tools/generate_nushi_fish_assets.py`、docs/31 記録済み）。ヌシは「元魚の主」なので類似は仕様

## 5. 修正方針

新規ソースアートの生成・差し替えで直す。tint・markings の追加調整で誤魔化さない（docs/19 の「微調整3回ルール」相当。既に markings による差別化が破綻していることが原因のため）。

### 手順（docs/24 の既存パイプラインに従う）

1. 対象魚の新規アートを OpenAI 画像生成でコンタクトシートとして作成し、`tools/source_assets/fish/fish_dedup_<date>_contact_sheet_<n>.png` へ保存（1枚あたり8〜12種）。プロンプトには各魚の**識別特徴を明記**する（例: ホウボウ=翼状の青緑の大胸鰭、サヨリ=針状の下顎、コノシロ=肩の黒斑と糸状背鰭）
2. `tools/process_underwater_fish_assets.py` の `FISH_ART_SOURCES` で、対象魚の `"template": ...` エントリを新シートの `"source"` + `"contact_crop"` エントリへ置き換え
3. 再生成して `assets/showcase/fish/<id>_showcase_sheet.png`（2560x320・4フレーム）と `<id>_card_portrait.png`（560x310）を更新
4. 採用判定は必ず実画像比較で行う: `tools/build_fish_book_portrait_contact_sheet.py` → `./tools/fish_book_visual_qa.sh` / `./tools/fight_visual_qa.sh` の横並び比較
5. 同じコミットで `docs/31_asset_ledger.md` に生成元を追記

### フェーズ分割（brief分割の単位）

| フェーズ | 対象 | DoD |
|---|---|---|
| P1: A群 15種 | §4-A の15種 | 各魚の識別特徴が絵に出ている。dhash距離が旧ペア相手に対して13以上。fish_book/fight visual QA で現行に全画面比較で勝つ |
| P2: B群 17種 | §4-B の17種 | 同グループ内の全ペアで dhash距離13以上。図鑑の隣接カードで判別可能 |
| P3: 再評価 | megochi, kurosoi/takenokomebaru, mejina元絵 | P2完了後に再クラスタリングして判定 |

- P1/P2 の中はコンタクトシート単位（8〜12種）で独立に進められる
- freeze値（`docs/qa/*_qa.md`）・画面レイアウト・clip座標には触れない。素材の中身だけを差し替える

### 進捗メモ

- 2026-07-08: 再発防止監査 `tools/audit_fish_asset_duplicates.py` を `./tools/validate_project.sh` に組み込み済み。通常モードはdocs/35の既知pendingだけを許容し、`--strict` は全pending解消確認用として残す。
- 2026-07-08: P1バッチ1として8種（`houbou`, `kanagashira`, `kyusen`, `kobudai`, `ojisan`, `sayori`, `binnaga`, `konoshiro`）を新規OpenAI生成コンタクトシート由来に差し替え。監査結果は pending 26→14 / unexpected 0。残P1は `ira`, `kinmedai`, `akamutsu`, `medai`, `sawara`, `mahaze`, `nenbutsudai` の7種。
- 2026-07-08: P1バッチ2として残7種（`ira`, `kinmedai`, `akamutsu`, `medai`, `sawara`, `mahaze`, `nenbutsudai`）を新規OpenAI生成コンタクトシート由来に差し替え、P1 A群15種を完了。監査結果は pending 14→8 / unexpected 0。残pending 8件はP2/P3で扱う。
- 2026-07-08: P2バッチ1として9種（`meichidai`, `murasoi`, `onikasago`, `kihada`, `mebachi`, `hirasouda`, `suma`, `takabe`, `makogarei`）を新規OpenAI生成コンタクトシート由来に差し替え。監査結果は pending 8→0 / unexpected 0、`--strict` も通過。P2の `source` + `contact_crop` 化は残8種（`shimaaji`, `gingameaji`, `kaiwari`, `ishigarei`, `umitanago`, `ishigakidai`, `oomonhata`, `ara`）を次バッチで継続。P3（`megochi`, `kurosoi/takenokomebaru`, `mejina`）はP2完了後に再評価。

### 検証（各バッチ後に必須）

```bash
./tools/validate_project.sh
./tools/fish_book_visual_qa.sh
./tools/fight_visual_qa.sh
python3 tools/audit_fish_sheet_contract.py   # シート寸法・フレーム契約
```

## 6. 再発防止

- 本調査の dhash クラスタリングを `tools/audit_fish_asset_duplicates.py` として恒久化し、`validate_project.sh` に組み込む（同一クラスタの新規発生を検出したら fail。§4-C の許容ペアと意図的派生は allowlist に理由コメント付きで登録）
- `FISH_ART_SOURCES` へ新たに `template` エントリを追加する場合は、docs/24 §素材条件の「色違いだけで別魚に見える候補は不採用」に照らして、追加前に横並び比較で判別可能なことを確認する

## 7. 証拠画像

| ファイル | 内容 |
|---|---|
| `docs/qa/evidence/fish_assets/2026-07-07_dup_portrait_pairs_0〜4.png` | 疑わしい25ペアの横並び比較 |
| `docs/qa/evidence/fish_assets/2026-07-07_dup_family_grid.png` | カマス系・イシダイ系・アジ系・カツオ系・マダイ系・ハタ系の系統別グリッド |
| `docs/qa/evidence/fish_assets/2026-07-07_dup_derived_check_grid.png` | クラスタ外の派生種（mahaze, kanagashira, maanago, ara ほか）の確認グリッド |
