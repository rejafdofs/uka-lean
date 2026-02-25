# UkaLean — Lean 4 製 SHIORI/3.0 栞ビブリオテーカ

Lean 4 でうかがか(Ukagaka)ゴーストの栞を書くためのビブリオテーカにゃ。
`do` 記法で型安全に SakuraScript を組み立てられるにゃん♪

識別子はラテン語で統一されてゐるにゃ。

---

## クイックスタート

### 前提

- [Lean 4 / elan](https://leanprover.github.io/lean4/doc/setup.html)（Lake 附属にゃ）
- MinGW (gcc) — Windows で DLL を作るのに必要にゃ

### ① 新規 Lake プロヱクトゥムを作るにゃ

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

### ③ `Ghost.lean` を書くにゃ

```lean
-- Ghost.lean
import UkaLean
open UkaLean Sakura

varia perpetua greetCount : Nat := 0

eventum "OnBoot" fun _ => do
  greetCount.modify (· + 1)
  let numerus ← greetCount.get
  sakura; superficies 0
  loqui s!"起動 {numerus} 囘目にゃん♪"
  finis

eventum "OnClose" fun _ => do
  sakura; superficies 0
  loqui "またにゃん！"
  finis

construe
```

### ④ `Main.lean` を書くにゃ

`ghost.exe` のエントリポイント（主關數）として以下を記述するにゃ:

```lean
-- Main.lean
import UkaLean.Loop
import Ghost

def main : IO Unit := UkaLean.loopPrincipalis
```

### ⑤ 構築して `ghost.exe` を作るにゃ

以下を **ゴーストのプロジェクト 루트**（`lakefile.toml` がある場所）で實行するにゃ。

```bash
lake update
lake build ghost
```

完成した `.lake/build/bin/ghost.exe` をコピーするにゃ！

### ⑥ `shiori.dll` (代理) を入手して配置するにゃ

最新の `shiori.dll` を uka-lean の Release からダウンロードし、構築した `ghost.exe` と同じ場所に置くことで、SSP から讀み込めるやうになるにゃ♪

- `shiori.dll` (SSP から讀まれる 32-bit Rust 製代理)
- `ghost.exe` (Lean 製の眞の主人公)

---

## `Ghost.lean` の書き方

### `varia` — 全域變數の宣言

```lean
varia perpetua   名前 : 型 := 初期値   -- 終了時に保存・起動時に復元するにゃ
varia temporaria 名前 : 型 := 初期値   -- 起動中だけ使ふ（保存しにゃい）
```

| | `perpetua` | `temporaria` |
|---|---|---|
| 保存先 | `{ghost}/ghost_status.bin` | なし |
| 起動時 | ファスキクルスから復元 | 初期値から始まる |
| 用途 | 起動囘數・設定・フラグ等 | 今囘だけ使ふ情報 |

使へる型: `Nat` `Int` `Bool` `String` `Float` 等（`StatusPermanens` クラスのインスタンスにゃ）

**型安全な永続化にゃ♪**
保存時に型を識別する `typusTag`（文字列）も一緒に保存するにゃ。
ゴーストの更新で變數の型が變はっても、タグが不一致なら安全に讀み飛ばされるにゃん。

變數は `IO.Ref` として展開されるにゃ。處理器の中から直接使へるにゃ:

```lean
let numerus ← greetCount.get   -- 讀む
greetCount.set 42               -- 書く
greetCount.modify (· + 1)       -- 更新する
```

---

### `eventum` — 事象處理器の宣言

```lean
eventum "事象名" fun rogatio => do
  -- rogatio : Rogatio（SSP からの要求情報にゃ）
  ...
  finis   -- ★ 末尾に必ず書くにゃ
```

`rogatio` から取れるもの:

| 式 | 型 | 内容 |
|---|---|---|
| `rogatio.nomen` | `String` | 事象名（"OnBoot" 等）|
| `rogatio.referentiam 0` | `Option String` | Reference0 |
| `rogatio.referentiam 1` | `Option String` | Reference1 |
| `rogatio.mittens` | `Option String` | Sender 頭部 |
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

ファスキクルスの末尾に一度書くだけにゃ:

```lean
construe
```

- `eventum` で宣言した全ての處理器を自動收集して登錄するにゃ
- `perpetua` 變數がある場合は讀込・書出フックも自動生成されるにゃん♪
- 型タグ付きで保存するので、型が變はっても安全にゃ
- 處理器内で例外が發生した場合は 500 Internal Server Error を返すにゃ

---

## SakuraScript 命令一覽

`open UkaLean Sakura` してから使ふにゃ。

### 人格・表情

| 命令 | SakuraScript | 意味 |
|---|---|---|
| `sakura` | `\h` | 主人格（さくら側）に切り替へ |
| `kero` | `\u` | 副人格（うにゅう側）に切り替へ |
| `persona n` | `\p[n]` | 第 n 人格に切り替へ |
| `superficies n` | `\s[n]` | 表情を n 番にする |
| `animatio n` | `\i[n]` | 動畫 n 番を再生 |

### 文字表示

| 命令 | SakuraScript | 意味 |
|---|---|---|
| `loqui "文字列"` | (特殊文字自動遁走) | 文字を表示 |
| `loquiEtLinea "文字列"` | 同上 + `\n` | 表示して改行 |
| `linea` | `\n` | 改行 |
| `dimidiaLinea` | `\n[half]` | 半改行 |
| `purga` | `\c` | 吹き出しを淸掃 |
| `adscribe` | `\C` | 前の吹き出しに追記 |
| `finis` | `\e` | **スクリプト終了（必須）** |

### 待機・テンポ

| 命令 | SakuraScript | 意味 |
|---|---|---|
| `mora ms` | `\_w[ms]` | ms ミリ秒待機 |
| `moraCeler n` | `\w[n]` | 50ms × n 待機 |
| `moraAbsoluta ms` | `\__w[ms]` | 絕對時間待機 |
| `expecta` | `\x` | 打鍵待ち（淸掃あり）|
| `expectaSine` | `\x[noclear]` | 打鍵待ち（淸掃なし）|

### 選擇肢

| 命令 | 意味 |
|---|---|
| `optio "表示名" "EventName"` | 選擇肢を追加（クリックで事象を發生）|
| `optioEventum "表示名" "EventName" ["r0", "r1"]` | Reference 附き選擇肢 |
| `ancora "signum"` … `fineAncora` | 錨（クリック可能な文字列）|

```lean
eventum "OnBoot" fun _ => do
  sakura; superficies 0
  loquiEtLinea "何をするにゃ？"
  optio "撫でる"   "OnNaderu"
  linea
  optio "さよなら" "OnClose"
  finis
```

### 書體

| 命令 | SakuraScript | 意味 |
|---|---|---|
| `audax true` | `\f[bold,true]` | 太字 ON |
| `obliquus true` | `\f[italic,true]` | 斜體 ON |
| `sublinea true` | `\f[underline,true]` | 下線 ON |
| `deletura true` | `\f[strike,true]` | 取消線 ON |
| `color r g b` | `\f[color,r,g,b]` | 文字色（0〜255）|
| `altitudoLitterarum n` | `\f[height,n]` | 文字の大きさ |
| `formaPraefinita` | `\f[default]` | 書式を既定に戾す |

### その他

| 命令 | SakuraScript | 意味 |
|---|---|---|
| `sonus "via"` | `\_v[via]` | 音聲を再生 |
| `expectaSonum` | `\_V` | 音聲終了を待つ |
| `excita "Event"` | `\![raise,Event]` | 事象を發生させる |
| `exitus` | `\-` | ゴーストを終了させる |
| `aperi "nexus"` | `\j[nexus]` | URL を開く |
| `crudus "signum"` | (そのまま出力) | 生の SakuraScript を直接發出 |

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

## 64-bit DLL の讀込（代理・Proxy の利用）

Lean 4 は 64-bit 向けのバイナリしか出力できにゃいにゃ。一方、SSP は 32-bit アッパラートゥス(apparatus)にゃので、そのまゝでは變換した DLL を讀み込めにゃいにゃん…。
そのため、32-bit DLL として振る舞ふ **代理（proxy）** が必要になるにゃ。

そこで、32-bit の SSP と 64-bit の Lean 實体を橋渡しする自前の代理(`shiori.dll`)を準備したにゃん♪
`shiori.dll` が SSP と通信し、そこから `ghost.exe` (Lean 製の 64-bit プロケッスス) を呼び出して標準入出力でパイプ通信（直結）する仕組にゃ！C 言語レイヤーによる中繼や DLL ビルドの苦痛はもう存在しにゃいのでござる！

---

## DLL 配置場所

```
SSP/
└── ghost/
    └── (ゴースト名)/
        ├── descript.txt
        ├── shell/
        │   └── master/               ← シェル畫像
        └── ghost/
            └── master/
                ├── shiori.dll        ← ★ SSP から直接讀まれる 32-bit 代理にゃ
                ├── ghost.exe         ← ★ 代理から全件丸投げされて動くLean製の眞の主人公にゃ
                └── ghost_status.bin  ← 永続化ダータ（自動生成にゃ）
```

---

## 完全なエクセンプルム（永続化・分岐・選擇肢あり）

```lean
import UkaLean
open UkaLean Sakura

varia perpetua  greetCount : Nat  := 0
varia perpetua  liked       : Bool := false
varia temporaria talkCount  : Nat  := 0   -- 今囘の起動中だけにゃ

eventum "OnBoot" fun _ => do
  greetCount.modify (· + 1)
  let numerus ← greetCount.get
  sakura; superficies 0
  if numerus == 1 then
    loquiEtLinea "はじめましてにゃん！"
    mora 800; linea
    kero; superficies 10
    loquiEtLinea "よろしくお願ひします。"
  else
    loquiEtLinea s!"{numerus} 囘目の起動にゃ♪"
  finis

eventum "OnClose" fun _ => do
  sakura; superficies 3
  loquiEtLinea "またにゃー！"
  mora 400; linea
  kero; superficies 14
  loquiEtLinea "お疲れ樣でした。"
  finis

eventum "OnMouseDoubleClick" fun rogatio => do
  talkCount.modify (· + 1)
  match rogatio.referentiam 4 with
  | some "Head" => sakura; superficies 5; loqui "撫でてくれるにゃ？嬉しいにゃん♪"
  | some "Face" => sakura; superficies 9; loqui "にゃっ！？ 顏は恥づかしいにゃ…"
  | _           => sakura; superficies 0; loqui "なでなでにゃ"
  finis

eventum "OnMinuteChange" fun rogatio => do
  match rogatio.referentiam 0, rogatio.referentiam 1 with
  | some hora, some "00" =>
    sakura; superficies 0
    loquiEtLinea s!"{hora}時ちょうどにゃん♪"
    finis
  | _, _ => finis   -- 毎分は何もしにゃい

construe
```

---

## 低水準 API（マクロを使はない場合）

`varia`/`eventum`/`construe` を使はずに直接書くこともできるにゃ:

```lean
import UkaLean
open UkaLean Sakura

def onBoot (_ : Rogatio) : SakuraIO Unit := do
  sakura; superficies 0
  loquiEtLinea "こんにゃんにゃ！"
  finis

initialize
  UkaLean.registraShiori [("OnBoot", onBoot)]
```

永続化フック附きの場合は `registraShioriEx` を使ふにゃ:

```lean
initialize
  UkaLean.registraShioriEx
    [("OnBoot", onBoot), ("OnClose", onClose)]
    (some (fun domus => do ...))   -- load 時に呼ばれるにゃ
    (some (do ...))                -- unload 時に呼ばれるにゃ
```

---

## 永続化ファスキクルスの形式

`{ghost}/ghost_status.bin` にバイナリで保存されるにゃ（v2 形式）。

- `perpetua` 變數のみ保存・復元されるにゃ（`temporaria` は保存されにゃい）
- ファスキクルスがない場合は `:= 初期値` が使はれるにゃ
- 各エントリに `typusTag`（型の文字列識別子）が附いてゐるにゃ
  - 型が變はった變數は安全に讀み飛ばされるにゃん♪

### 使へる型（`StatusPermanens` インスタンスあり）

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

### 自作構造體の永続化

`encodeField`/`decodeField` を使へば任意の構造體をインスタンスにできるにゃん♪

```lean
import UkaLean
open UkaLean

structure PlayerData where
  gradus : Nat     -- 等級（英語 level のかはりにゃ）
  nomen  : String
  puncta : Float   -- 點數

instance : StatusPermanens PlayerData where
  typusTag := "PlayerData"
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
varia perpetua player : PlayerData := { gradus := 1, nomen := "シロ", puncta := 0.0 }
```

---

## ファスキクルス構成

```
uka.lean/
├── lean-toolchain              ← leanprover/lean4:v4.28.0
├── lakefile.toml
├── UkaLean.lean                ← 根モドゥルス（全體を再輸出）
├── UkaLean/
│   ├── Protocollum.lean        ← SHIORI/3.0 共通型・定数
│   ├── SakuraScriptum.lean     ← SakuraScript モナド DSL
│   ├── Rogatio.lean            ← SHIORI/3.0 要求構文解析器
│   ├── Responsum.lean          ← SHIORI/3.0 應答構築器
│   ├── Nuculum.lean            ← 核心骨格（Shiori 型・事象經路設定）
│   ├── Exporta.lean            ← 內部用實行關數群
│   ├── StatusPermanens.lean    ← 永続化型クラス・補助關數・逆關數定理
│   ├── Loop.lean               ← パイプ直結通信用の小循環（メインループ）
│   └── Macro.lean              ← varia / eventum / construe DSL マクロ
└── Main.lean                   ← 模擬試驗用實行體
```

---

## 仕樣參照

- [UKADOC Project](https://ssp.shillest.net/ukadoc/manual/index.html) — SHIORI/3.0 仕樣・SakuraScript 仕樣
- [SSP](http://ssp.shillest.net/) — ベースウェア公式

