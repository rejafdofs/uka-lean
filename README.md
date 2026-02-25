# UkaLean — Lean 4 製 SHIORI/3.0 栞ビブリオテーカ(bibliotheca)

Lean 4 でうかがか(Ukagaka)の栞(shiori)を書くためのビブリオテーカにゃ。
`do` 記法で型安全に SakuraScriptum を組み立てられるにゃん♪

識別子はラテン語で統一されてゐるにゃ。

---

## クイックスタート (Inceptum Celer)

### 前提 (Praemissa)

- [Lean 4 / elan](https://leanprover.github.io/lean4/doc/setup.html)（Lake 附属にゃ）
- Windows 環境（代理の動的連結ビブリオテーカ `shiori.dll` を動かすのに必要にゃ）

### ① 新規 Lake プロヱクトゥム(proiectum)を作るにゃ

```bash
lake new my-ghost
cd my-ghost
```

### ② `lakefile.toml` に `require` を追記するにゃ

```lean
name = "my-ghost"
version = "0.1.0"

[[require]]
git = "https://github.com/rejafdofs/uka-lean"
rev = "master"
name = "uka-lean"

[[lean_lib]]
name = "Ghost"

[[lean_exe]]
name = "ghost"
root = "Main"
```

### ③ `Main.lean` を書くにゃ

`ghost.exe` の實行開始點(punctum initii)として、事象(eventum)と `construe`、そして `main` を記述するにゃ:

```lean
-- Main.lean
import UkaLean
open UkaLean Sakura

varia perpetua numerusSalutationum : Nat := 0

eventum "OnBoot" fun _ => do
  numerusSalutationum.modify (· + 1)
  let numerus ← numerusSalutationum.get
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

def main : IO Unit := UkaLean.loopPrincipalis
```

### ④ 構築(aedificatio)して實行體(exsecutabile) `ghost.exe` を作るにゃ

以下をゴーストのプロヱクトゥム・ルート（`lakefile.toml` がある場所）で實行するにゃ。

```bash
lake update
lake build ghost
```

完成した `.lake/build/bin/ghost.exe` の寫し(copia)を作成して次に進むにゃ！

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
                ├── ghost.exe         ← ★ 本體にゃ（Lean 構築物）
                └── ghost_status.bin  ← 永続化ダータ（自動生成にゃ）
```

---

## 代理 (Procurator) の仕組

Lean 4 は 64-bit の實行體に轉換されるにゃ。一方、SSP は 32-bit アッパラートゥス(apparatus)にゃので、そのまゝでは讀み込めにゃいにゃん…。
そのため、32-bit の動的連結ビブリオテーカとして振る舞ふ **代理 (procurator)** が必要になるにゃ。

そこで、32-bit の SSP と 64-bit の Lean 實行體を橋渡しする自前の代理ファスキクルス(fasciculus) `shiori.dll` （Rust製）を準備したにゃん♪
`shiori.dll` が SSP と通信し、そこから `ghost.exe` (Lean 製の 64-bit プロケッスス) を呼び出して標準入出力でパイプ(fistula)直結通信する仕組にゃ！これで面倒な C 言語による中繼や煩雜な構築作業の苦痛はもう存在しにゃいにゃん♪

---

## `Ghost.lean` の書き方

### `varia` — 全域變數(variabilis)の宣言

```lean
varia perpetua   名前 : 型 := 初期値   -- 終了時に保存・起動時に復元するにゃ
varia temporaria 名前 : 型 := 初期値   -- 起動中だけ使ふ（保存しにゃい）
```

| 種類 | `perpetua` | `temporaria` |
|---|---|---|
| 保存先 | `{ghost}/ghost_status.bin` | なし |
| 起動時 | ファスキクルスから復元 | 初期値から始まる |
| 用途 | 起動囘數・設定・フラグ等 | 今囘だけ使ふ情報 |

使へる型: `Nat` `Int` `Bool` `String` `Float` 等（`StatusPermanens` クラッシス(classis)の實体(instantia)にゃ）

**型安全な永続化にゃ♪**
保存時に型を識別する `typusTag`（文字列）も一緒に保存するにゃ。
更新で變數の型が變はっても、タグが不一致なら安全に讀み飛ばされるにゃん。

變數は `IO.Ref` として展開されるにゃ。處理器(tractator)の中から直接使へるにゃ:

```lean
let numerus ← numerusSalutationum.get   -- 讀取(legere)
numerusSalutationum.set 42               -- 設定(statuere)
numerusSalutationum.modify (· + 1)       -- 更新(renovare)
```

---

### `eventum` — 事象處理器(tractator)の宣言

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

### `construe` — 栞を組み立てよ

主ファスキクルス(fasciculus)の末尾に一度書くだけにゃ:

```lean
construe
```

- `eventum` で宣言した全ての處理器を自動收集して登錄するにゃ
- `perpetua` 變數がある場合は讀込・書出の呼戻(revocatio)も自動生成されるにゃん♪
- 型タグ付きで保存するので、型が變はっても安全にゃ
- 處理器内で例外(exceptio)が發生した場合は 500 Internal Server Error (內部エッロル) を返すにゃ

---

## SakuraScriptum 命令一覽 (Mandata)

`open UkaLean Sakura` してから使ふにゃ。

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

### 待機・テンポ (Mora)

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
| `ancora "signum"` … `fineAncora` | 錨（クリック可能な文字列）|

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

### その他 (Ceteri)

| 命令 | SakuraScriptum | 意味 |
|---|---|---|
| `sonus "via"` | `\_v[via]` | 音聲を再生 |
| `expectaSonum` | `\_V` | 音聲終了を待つ |
| `excita "Event"` | `\![raise,Event]` | 事象を發生させる |
| `exitus` | `\-` | ゴーストを終了させる |
| `aperi "nexus"` | `\j[nexus]` | URL を開く |
| `crudus "signum"` | (そのまま出力) | 生の SakuraScriptum を直接發出 |

便利な組合せ:

| 命令 | 意味 |
|---|---|
| `sakuraLoquitur n "文字列"` | `sakura; superficies n; loqui "..."` の一括 |
| `keroLoquitur n "文字列"` | `kero; superficies n; loqui "..."` の一括 |

---

## Reference 早見表

主要事象の `referentiam` 番號一覽にゃ:

| 事象 | ref 0 | ref 1 | ref 2 | ref 3 | ref 4 |
|---|---|---|---|---|---|
| `OnBoot` | 起動種別 (0=普通, 1=初囘, ...) | | | | |
| `OnMouseDoubleClick` | X座標 | Y座標 | スコープ番號 | 部位名 | |
| `OnMouseClick` | X座標 | Y座標 | スコープ番號 | 部位名 | |
| `OnMinuteChange` | 時 | 分 | | | |
| `OnSecondChange` | 時 | 分 | 秒 | | |
| `OnChoiceSelect` | 選擇肢ID | | | | |

---

## 永続化ファスキクルスの形式 (Forma Datorum Permanens)

`{ghost}/ghost_status.bin` に二進體(binarius)で保存されるにゃ（v2 形式）。

- `perpetua` 變數のみ保存・復元されるにゃ（`temporaria` は保存されにゃい）
- ファスキクルスが搜せにゃい場合は `:= 初期値` が使はれるにゃ
- 各定刻には `typusTag`（型の文字列識別子）が附いてゐるにゃ
  - 型が變はった變數は安全に讀み飛ばされるにゃん♪

### 使へる型（`StatusPermanens` クラッシス(classis)の實体(instantia)あり）

| 型 | `typusTag` | エンコード形式 |
|---|---|---|
| `Nat` | `"Nat"` | UInt64 LE（8バイト）|
| `Int` | `"Int"` | 二の補數 Int64 LE（8バイト）|
| `Bool` | `"Bool"` | 1バイト（0/1）|
| `String` | `"String"` | UTF-8 バイト列 |
| `Float` | `"Float"` | IEEE 754 倍精度（8バイト）|
| `UInt8/16/32/64` | `"UInt8"` 等 | 各サイズ LE |
| `Char` | `"Char"` | UInt32 として Unicode 符號點 |
| `ByteArray` | `"ByteArray"` | そのまま |
| `Option α` | `"Option(α)"` | 1バイトタグ + 中身 |
| `List α` | `"List(α)"` | 4バイト要素數 + 各要素 |
| `Array α` | `"Array(α)"` | `List α` と同じ |
| `α × β` | `"Prod(α,β)"` | フィールドの連結 |

### 自作構造體(structura)の永続化

`encodeField` と `decodeField` を使へば任意の構造體を實体(instantia)へと變換できるにゃん♪

```lean
import UkaLean
open UkaLean

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

-- あとはいつも通りにゃ
varia perpetua lusor : DatorumLusoris := { gradus := 1, nomen := "シロ", puncta := 0.0 }
```

---

## ファスキクルス構成 (Structura Fasciculorum)

```
uka.lean/
├── lakefile.toml
├── UkaLean.lean                ← 根モドゥルス(modulus)（全體を再輸出）
├── UkaLean/
│   ├── Protocollum.lean        ← SHIORI/3.0 共通型・定數
│   ├── SakuraScriptum.lean     ← SakuraScriptum モナド DSL
│   ├── Rogatio.lean            ← SHIORI/3.0 要求構文解析器
│   ├── Responsum.lean          ← SHIORI/3.0 應答構築器
│   ├── Nuculum.lean            ← 核心骨格（Shiori 型・事象經路設定）
│   ├── Exporta.lean            ← 內部用實行關數群
│   ├── StatusPermanens.lean    ← 永続化型クラッシス(classis)・補助關數・逆關數定理
│   ├── Loop.lean               ← パイプ直結通信用の小循環(circulus minor)
│   ├── Syntaxis.lean           ← varia / eventum / construe DSL 構文擴張
│   └── Exemplum.lean           ← 全事象(eventum)の網羅的實裝例
├── procurator/                 ← ★ 代理(procurator)の動的連結ビブリオテーカ( Rust 製 )
```

---

## 仕樣參照 (Referentia)

- [UKADOC Project](https://ssp.shillest.net/ukadoc/manual/index.html) — SHIORI/3.0 仕樣・SakuraScriptum 仕樣
- [SSP](http://ssp.shillest.net/) — 基底(basis)ウェア公式
