# うちのこゴースト化用lean SHIORi

開發者の大切な「うちの子」を、Lean 4 の純粹（ピュア）な論理（ロギカ / logica）によって伺か（Ukagaka）の幻影（ゴースト / ghost）として受肉させる爲の栞（shiori）ビブリオテーカ(bibliotheca)にゃん♪

「うちの子とお話ししてみたい……」
そんな夢を、型安全且つ堅牢なプログランマ(programma)で葉へる爲の基盤(basis)にゃ！
`do` 記法を使ひ、直感的に SakuraScriptum を組み立てられるにゃん♪
識別子は全てラテン語で統一されてゐるにゃ。

---

## はじめに (Introductio)

### 前提 (Praemissa)

- [Lean 4 / elan](https://leanprover.github.io/lean4/doc/setup.html)（Lake 附屬にゃ）
- Windows 環境（代理の動的連結ビブリオテーカ `shiori.dll` を動かすのに必要にゃ）

### ① 新規の Lake プロヱクトゥム(proiectum)を作るにゃ

```bash
lake new my-ghost
cd my-ghost
```

### ② `lakefile.toml` に `require` を追記するにゃ

```toml
name = "my-ghost"
version = "0.1.0"

[[require]]
git = "https://github.com/rejafdofs/uka-lean"
rev = "main"
name = "うちのこゴースト化用lean SHIORi"

[[lean_lib]]
name = "Ghost"

[[lean_exe]]
name = "ghost"
root = "Main"
```

### ③ `Main.lean` でうちの子の振る舞ひを書くにゃ

`ghost.exe` の實行開始點(punctum initii)として、事象(eventum)と `construe`、そして `main` を記述するにゃ:

```lean
-- Main.lean
import PuraShiori
open PuraShiori Sakura

varia perpetua numerusSalutationum : Nat := 0

eventum "OnBoot" fun _ => do
  numerusSalutationum.renovare (· + 1)
  let numerus ← numerusSalutationum.obtinere
  sakura; superficies 0
  if numerus == 1 then
    loquiEtLinea "はじめましてにゃん！"
    mora 800; linea
    kero; superficies 10
    loquiEtLinea "よろしくお願ひします。"
  else
    loqui s!"起動 {numerus} 囘目にゃん♪"
  finis

eventum "OnClose" fun _ => do
  sakura; superficies 3
  loqui "またにゃー！"
  finis

construe

def main : IO Unit := PuraShiori.loopPrincipalis
```

### ④ 構築(aedificatio)して實行體(exsecutabile) `ghost.exe` を作るにゃ

以下をゴーストのプロヱクトゥム・ルート（`lakefile.toml` が有る場所）で實行するにゃ。

```bash
lake update
lake build ghost
```

完成した `.lake/build/bin/ghost.exe` の寫し(copia)を作成して、次に進むにゃ！

### ⑤ 代理(procurator) `shiori.dll` を入手して配置するにゃ

最新の `shiori.dll` を uka-lean の Release から取得(descensus)し、構築した `ghost.exe` と同じ場所に置くことで、SSP から讀み込めるやうになるにゃ♪

#### 配置場所の例

```
SSP/
└── ghost/
    └── (ゴースト名)/
        ├── descript.txt
        ├── shell/
        │   └── master/               ← 外觀畫像
        └── ghost/
            └── master/
                ├── shiori.dll        ← ★ SSP から直接讀まれて本體に要求(rogatio)を渡す代理にゃ
                ├── ghost.exe         ← ★ うちの子の本體にゃ（Lean 構築物）
                └── ghost_status.bin  ← 永続化ダータ（自動生成にゃ）
```

---

## `Ghost.lean` の書き方

### `varia` — 記憶（全域變數 / variabilis）の宣言

うちの子の記憶を安全に永続化させるにゃ♪

```lean
varia perpetua   名前 : 型 := 初期値   -- 終了時に保存・起動時に復元する記憶にゃ
varia temporaria 名前 : 型 := 初期値   -- 起動中だけ使ふ一時的にゃ記憶（保存しにゃい）
```

| 種類 | `perpetua` | `temporaria` |
|---|---|---|
| 保存先 | `{ghost}/ghost_status.bin` | なし |
| 起動時 | ファスキクルスから復元 | 初期値から始まる |
| 用途 | 起動囘數・親密度・フラグ等 | 今囘だけ使ふ情報 |

使へる型: `Nat` `Int` `Bool` `String` `Float` 等（`StatusPermanens` クラッシス(classis)の實体(instantia)にゃ）

**型安全にゃ永続化にゃ♪**
保存時に型を識別する `typusTag`（文字列）も一緒に保存するにゃ。
更新で變數の型が變はつても、タグが不一致なら安全に讀み飛ばされるから、うちの子の記憶が壞れる心配はにゃいにゃん。

變數は `IO.Ref` として展開されるにゃ。處理器(tractator)の中から直接使へるにゃ:

```lean
let numerus ← numerusSalutationum.obtinere   -- 讀取(legere)
numerusSalutationum.statuere 42              -- 設定(statuere)
numerusSalutationum.renovare (· + 1)         -- 更新(renovare)
```

---

### `eventum` — うちの子の反應（事象處理器 / tractator）の宣言

うちの子がどう反應するかを記述する箇所にゃ！

```lean
eventum "事象名" fun rogatio => do
  -- rogatio : Rogatio（SSP からの要求(rogatio)情報にゃ）
  ...
  finis   -- ★ 末尾に必ず書くにゃ
```

`rogatio` から取れるもの:

| 式 | 型 | 内容 |
|---|---|---|
| `rogatio.nomen` | `String` | 事象名（"OnBoot" 等）|
| `rogatio.referentiam 0` | `Option String` | Reference0 |
| `rogatio.referentiam 1` | `Option String` | Reference1 |
| `rogatio.mittens` | `Option String` | Sender 頭部(caput) |
| `rogatio.caput "clavis"` | `Option String` | 任意の頭部 |

使用例:

```lean
eventum "OnMouseDoubleClick" fun rogatio => do
  match rogatio.referentiam 4 with
  | some "Head" => sakura; superficies 5; loqui "撫でてくれるにゃ♪"
  | some "Face" => sakura; superficies 9; loqui "にゃっ！？"
  | _           => sakura; superficies 0; loqui "なでなでにゃ"
  finis
```

---

### `construe` — 栞の總仕上げ

主ファスキクルス(fasciculus)の末尾に一度書くだけで、うちの子に命が吹き込まれるにゃ:

```lean
construe
```

- `eventum` で宣言した全ての處理器を自動收集して登錄するにゃ
- `perpetua` 變數が有る場合は讀込・書出の呼戻(revocatio)も自動生成されるにゃん♪
- 處理器内で例外(exceptio)が發生した場合は 500 Internal Server Error (內部エッロル) を返すにゃ

---

## 無作爲選擇 (Fortuita) — お喋り機能支援

うちの子が多彩なお喋りをしてくれるやうに、無作爲な言葉選びを支援するにゃ。

| 關數 | 型 | 意味 |
|---|---|---|
| `elige optiones` | `Array String → IO String` | 配列からランダムに1つ選んで返すにゃ。空配列なら空文字列にゃ |
| `fortuito optiones` | `Array String → SakuraIO Unit` | ランダムに1つ選んで `loqui` で表示するにゃ（`elige` + `loqui` の便利關數にゃん） |

使用例:

```lean
eventum "OnBoot" fun _ => do
  sakura; superficies 0
  fortuito #["やっほー！", "こんにちは！", "おはよう！"]
  finis
```

---

## 即時保存 (servaStatum) — 記憶の手動保存

`construe` が自動生成する `servaStatum : IO Unit` を使へば、事象處理の途中でも何時でも `perpetua` 變數を保存できるにゃ。
SSP がクラッシュしてもうちの子の大事な記憶が保たれるやうに、適宜保存すると安心にゃん♪

```lean
eventum "OnBoot" fun _ => do
  numerusSalutationum.renovare (· + 1)
  servaStatum                    -- ← 兹で即時保存にゃ！
  sakura; superficies 0
  loqui s!"起動 {← numerusSalutationum.obtinere} 囘目にゃん♪"
  finis
```

---

## SakuraScriptum 命令一覽 (Mandata)

`open PuraShiori Sakura` してから使ふにゃ。

### 人格・表情 (Persona et Superficies)

| 命令 | SakuraScriptum | 意味 |
|---|---|---|
| `sakura` | `\h` | 主人格（さくら側）に切り替へ |
| `kero` | `\u` | 副人格（うにゅう側）に切り替へ |
| `persona n` | `\p[n]` | 第 n 人格に切り替へ |
| `superficies n` | `\s[n]` | 表情を n 番にする |
| `animatio n` | `\i[n]` | 動畫 n 番を再生 |

### 文字表示 (Textus)

| 命令 | SakuraScriptum | 意味 |
|---|---|---|
| `loqui "文字列"` | (特殊文字自動遁走) | 文字を表示 |
| `loquiEtLinea "文字列"` | 同上 + `\n` | 表示して改行 |
| `linea` | `\n` | 改行 |
| `dimidiaLinea` | `\n[half]` | 半改行 |
| `purga` | `\c` | 吹き出しを淸掃 |
| `adscribe` | `\C` | 前の吹き出しに追記 |
| `finis` | `\e` | **スクリプトゥム終了（必須）** |

### 待機・動度 (Mora)

| 命令 | SakuraScriptum | 意味 |
|---|---|---|
| `mora ms` | `\_w[ms]` | ms ミリ秒待機 |
| `moraCeler n` | `\w[n]` | 50ms × n 待機 |
| `moraAbsoluta ms` | `\__w[ms]` | 絕對時間待機 |
| `expecta` | `\x` | 打鍵待ち（淸掃あり）|
| `expectaSine` | `\x[noclear]` | 打鍵待ち（淸掃なし）|

### 選擇肢 (Optio)

| 命令 | 意味 |
|---|---|
| `optio "表示名" "EventName"` | 選擇肢を追加（クリックで事象を發生）|
| `optioEventum "表示名" "EventName" ["r0", "r1"]` | Reference 附き選擇肢 |
| `ancora "signum"` … `fineAncora` | 錨（クリック可能にゃ文字列）|

### 書體 (Stilus)

| 命令 | SakuraScriptum | 意味 |
|---|---|---|
| `audax true` | `\f[bold,true]` | 太字 ON |
| `obliquus true` | `\f[italic,true]` | 斜體 ON |
| `sublinea true` | `\f[underline,true]` | 下線 ON |
| `deletura true` | `\f[strike,true]` | 取消線 ON |
| `color r g b` | `\f[color,r,g,b]` | 文字色（0〜255）|
| `altitudoLitterarum n` | `\f[height,n]` | 文字の大きさ |
| `formaPraefinita` | `\f[default]` | 書式を既定(praefinitum)に戾す |

### 其の他 (Ceteri)

| 命令 | SakuraScriptum | 意味 |
|---|---|---|
| `sonus "via"` | `\_v[via]` | 音聲を再生 |
| `expectaSonum` | `\_V` | 音聲終了を待つ |
| `excita "Event"` | `\![raise,Event]` | 事象を發生させる |
| `exitus` | `\-` | ゴーストを終了させる |
| `aperi "nexus"` | `\j[nexus]` | URL を開く |
| `crudus "signum"` | (其のまゝ出力) | 生の SakuraScriptum を直接發出 |

便利な組合せ:

| 命令 | 意味 |
|---|---|
| `sakuraLoquitur n "文字列"` | `sakura; superficies n; loqui "..."` の一括 |
| `keroLoquitur n "文字列"` | `kero; superficies n; loqui "..."` の一括 |

---

## 永続化ファスキクルスの形式 (Forma Datorum Permanens)

`{ghost}/ghost_status.bin` に二進體(binarius)で保存されるにゃ（v2 形式）。

- `perpetua` 變數のみ保存・復元されるにゃ（`temporaria` は保存されにゃい）
- ファスキクルスが搜せにゃい場合は `:= 初期値` が使はれるにゃ
- 各定刻には `typusTag`（型の文字列識別子）が附いてゐるにゃ
  - 型が變はつた變數は安全に讀み飛ばされるにゃん♪

### 使へる型（`StatusPermanens` クラッシス(classis)の實体(instantia)あり）

| 型 | `typusTag` | 變換形式 |
|---|---|---|
| `Nat` | `"Nat"` | UInt64 LE（8バイト）|
| `Int` | `"Int"` | 二の補數 Int64 LE（8バイト）|
| `Bool` | `"Bool"` | 1バイト（0/1）|
| `String` | `"String"` | UTF-8 バイト列 |
| `Float` | `"Float"` | IEEE 754 倍精度（8バイト）|
| `UInt8/16/32/64` | `"UInt8"` 等 | 各サイズ LE |
| `Char` | `"Char"` | UInt32 として Unicode 符號點 |
| `ByteArray` | `"ByteArray"` | 其のまゝ |
| `Option α` | `"Option(α)"` | 1バイトタグ + 中身 |
| `List α` | `"List(α)"` | 4バイト要素數 + 各要素 |
| `Array α` | `"Array(α)"` | `List α` と同じ |
| `α × β` | `"Prod(α,β)"` | フィールドの連結 |

### 自作構造體(structura)の永続化

`encodeField` と `decodeField` を使へば任意の構造體を實体(instantia)へと變換できるにゃん♪

```lean
import PuraShiori
open PuraShiori

structure DatorumLusoris where
  gradus : Nat     -- 階級
  nomen  : String  -- 名前
  puncta : Float   -- 點數

instance : StatusPermanens DatorumLusoris where
  typusTag := "DatorumLusoris"
  adBytes p :=
    encodeField p.gradus ++
    encodeField p.nomen  ++
    encodeField p.puncta
  eBytes b := do
    let (gradus, pos1) ← decodeField b 0
    let (nomen,  pos2) ← decodeField b pos1
    let (puncta, _)    ← decodeField b pos2
    return { gradus, nomen, puncta }

-- あとは何時も通りにゃ
varia perpetua lusor : DatorumLusoris := { gradus := 1, nomen := "シロ", puncta := 0.0 }
```

---

## 結びに (Conclusio)

開發者の「うちの子」が、この Lean 製の栞(shiori)を經て、美しく健やかに息づくことを願つてゐるにゃん♪
何處までも純粹（ピュア）で、型安全な對話の世界を楽しんでほしいにゃ！

---

## 仕樣參照 (Referentia)

- [UKADOC Project](https://ssp.shillest.net/ukadoc/manual/index.html) — SHIORI/3.0 仕樣・SakuraScriptum 仕樣
- [SSP](http://ssp.shillest.net/) — 基底(basis)ウェア公式
