# UkaLean — Lean 4 製 SHIORI/3.0 栞ビブリオテーカ

Lean 4 でうかがか(Ukagaka)ゴーストの栞を書くためのビブリオテーカにゃ。
`do` 記法で型安全に SakuraScript を組み立てられるにゃん♪

---

## 必要なもの

- [Lean 4 / elan](https://leanprover.github.io/lean4/doc/setup.html)（Lake 附属にゃ）

---

## これだけで動く最速サンプル

```lean
import UkaLean
open UkaLean Sakura

-- 永続化變數にゃ（終了時に保存・起動時に復元されるにゃ）
ghost_var persistent greetCount : Nat := 0

ghost_on "OnBoot" fun _ => do
  greetCount.modify (· + 1)
  let n ← greetCount.get
  sakura; superficies 0
  loquiEtLinea s!"起動 {n} 囘目にゃん！"
  finis

ghost_on "OnClose" fun _ => do
  sakura; superficies 3
  loquiEtLinea "またにゃー！"
  finis

build_ghost
```

```bash
lake build                 # 構築にゃ
lake exe shiori-probatio   # 模擬試驗にゃ
```

---

## 3つのキーワード

### `ghost_var` — 全域變數の宣言

```lean
ghost_var persistent 名前 : 型 := 初期値   -- 終了時に保存・起動時に復元
ghost_var transient  名前 : 型 := 初期値   -- 起動中だけ使ふ（保存しにゃい）
```

`persistent` と `transient` の違い:

| | `persistent` | `transient` |
|---|---|---|
| 保存先 | `{ghost}/ghost_status.dat` | なし |
| 起動時 | ファスキクルスから復元 | 初期値から始まる |
| 用途 | 起動回數・設定・フラグ等 | 今囘だけ使ふ情報 |

使へる型: `Nat` `Int` `Bool` `String`（`StatusPermanens` クラスのインスタンスにゃ）

變數は `IO.Ref` として展開されるにゃ。處理器の中から直接使へるにゃ:

```lean
let n ← greetCount.get      -- 讀む
greetCount.set 42            -- 書く
greetCount.modify (· + 1)    -- 更新
```

---

### `ghost_on` — 事象處理器の宣言

```lean
ghost_on "事象名" fun req => do
  -- req : Rogatio（SSP からの要求情報にゃ）
  ...
  finis   -- ★ 末尾に必ず書くにゃ
```

`req` から取れるもの:

| 式 | 型 | 内容 |
|---|---|---|
| `req.nomen` | `String` | 事象名（"OnBoot" 等）|
| `req.referentiam 0` | `Option String` | Reference0 |
| `req.referentiam 1` | `Option String` | Reference1 |
| `req.mittens` | `Option String` | Sender 頭部 |
| `req.caput "キー"` | `Option String` | 任意の頭部 |

`req.referentiamn` の使ひ方:

```lean
ghost_on "OnMouseDoubleClick" fun req => do
  match req.referentiam 4 with
  | some "Head" => sakura; superficies 5; loqui "撫でてくれるにゃ♪"
  | some "Face" => sakura; superficies 9; loqui "にゃっ！？"
  | _           => sakura; superficies 0; loqui "なでなでにゃ"
  finis
```

主要な事象の Reference 番號早見表:

| 事象 | ref 0 | ref 1 | ref 2 | ref 3 | ref 4 |
|---|---|---|---|---|---|
| `OnBoot` | 起動種別 (0=普通, 1=初囘, ...) | | | | |
| `OnMouseDoubleClick` | X座標 | Y座標 | スコープ番號 | 部位名 | |
| `OnMouseClick` | X座標 | Y座標 | スコープ番號 | 部位名 | |
| `OnMinuteChange` | 時 | 分 | | | |
| `OnSecondChange` | 時 | 分 | 秒 | | |
| `OnChoiceSelect` | 選擇肢ID | | | | |

---

### `build_ghost` — 組み立て・登錄

ファスキクルスの末尾に一度書くだけにゃ。

```lean
build_ghost
```

- `ghost_on` で宣言した全ての處理器を自動収集して登錄するにゃ
- `persistent` 變數がある場合は讀込・書出フックも自動生成されるにゃん♪

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
| `ancora "id"` … `fineAncora` | 錨（クリック可能な文字列）|

```lean
ghost_on "OnBoot" fun _ => do
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
| `aperi "url"` | `\j[url]` | URL を開く |
| `crudus "文字列"` | (そのまま出力) | 生の SakuraScript を直接發出 |

便利な組合せ:

| 命令 | 意味 |
|---|---|
| `sakuraLoquitur n "文字列"` | `sakura; superficies n; loqui "..."` の一括 |
| `keroLoquitur n "文字列"` | `kero; superficies n; loqui "..."` の一括 |

---

## 完全なサンプル（永続化・分岐・選擇肢あり）

```lean
import UkaLean
open UkaLean Sakura

ghost_var persistent greetCount : Nat  := 0
ghost_var persistent liked       : Bool := false
ghost_var transient  talkCount  : Nat  := 0   -- 今囘の起動中だけにゃ

ghost_on "OnBoot" fun _ => do
  greetCount.modify (· + 1)
  let n ← greetCount.get
  sakura; superficies 0
  if n == 1 then
    loquiEtLinea "はじめましてにゃん！"
    mora 800; linea
    kero; superficies 10
    loquiEtLinea "よろしくお願ひします。"
  else
    loquiEtLinea s!"{n} 囘目の起動にゃ♪"
  finis

ghost_on "OnClose" fun _ => do
  sakura; superficies 3
  loquiEtLinea "またにゃー！"
  mora 400; linea
  kero; superficies 14
  loquiEtLinea "お疲れ樣でした。"
  finis

ghost_on "OnMouseDoubleClick" fun req => do
  talkCount.modify (· + 1)
  match req.referentiam 4 with
  | some "Head" => sakura; superficies 5; loqui "撫でてくれるにゃ？嬉しいにゃん♪"
  | some "Face" => sakura; superficies 9; loqui "にゃっ！？ 顏は恥づかしいにゃ…"
  | _           => sakura; superficies 0; loqui "なでなでにゃ"
  finis

ghost_on "OnMinuteChange" fun req => do
  match req.referentiam 1 with
  | some "00" =>
    let h := (req.referentiam 0).getD "?"
    sakura; superficies 0
    loquiEtLinea s!"{h}時ちょうどにゃん♪"
    finis
  | _ => finis   -- 毎分は何もしにゃい

build_ghost
```

---

## 低レベル API（マクロを使はない場合）

`ghost_var`/`ghost_on`/`build_ghost` を使はずに直接書くこともできるにゃ:

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

## DLL 構築と配置（SSP で動かすまで）

### 0. ゴーストのディレクトーリウム構造（SSP の場合）

SSP で動かすには、`ghost/master/` ディレクトーリウムに `shiori.dll` を置くにゃ。
最終的に以下のやうな構成になるにゃん：

```
SSP/
└── ghost/
    └── (ゴースト名)/
        ├── descript.txt
        ├── shell/
        │   └── master/          ← シェル画像
        └── ghost/
            └── master/
                ├── shiori.dll   ← ★ ここに配置するにゃ
                ├── ghost_status.dat   ← 永続化ダータ（自動生成にゃ）
                └── (その他ゴーストファスキクルス)
```

---

### 1. Lean ビブリオテーカを構築するにゃ

```bash
# uka.lean のディレクトーリウムで実行するにゃ
lake build
```

`.lake/build/lib/` に `libUkaLean.a`（静的ビブリオテーカ）が生成されるにゃ。

---

### 2. 自分のゴーストの Lean ファスキクルスを作るにゃ

`MyGhost.lean` のやうなファスキクルスを作るにゃ：

```lean
-- MyGhost.lean
import UkaLean
open UkaLean Sakura

ghost_var persistent greetCount : Nat := 0

ghost_on "OnBoot" fun _ => do
  greetCount.modify (· + 1)
  let n ← greetCount.get
  sakura; superficies 0
  loquiEtLinea s!"起動 {n} 囘目にゃん！"
  finis

ghost_on "OnClose" fun _ => do
  sakura; superficies 3
  loquiEtLinea "またにゃー！"
  finis

build_ghost
```

---

### 3. shiori.c をゴーストの作業ディレクトーリウムにコピーするにゃ

`ffi/shiori.c` は UkaLean リポジトーリウムに含まれているにゃ。
ゴーストを作る際は、`ffi/shiori.c` を自分の作業ディレクトーリウムにコピーして使ふにゃ：

```
(自分のゴースト作業場)/
├── MyGhost.lean   ← 自分で書いたゴーストにゃ
├── shiori.c       ← uka.lean/ffi/shiori.c をコピーにゃ
└── (生成される shiori.dll など)
```

---

### 4. shiori.dll をコンパイルするにゃ

MinGW (gcc) で DLL を作るにゃ。`lake build` を先に實行しておくにゃん：

```bash
# ① Lean ビブリオテーカを構築にゃ（uka.lean のディレクトーリウムで）
cd /path/to/uka.lean
lake build

# ② DLL をコンパイルにゃ（自分の作業ディレクトーリウムで）
gcc -shared -o shiori.dll shiori.c \
  -I$(lean --print-prefix)/include \
  -L/path/to/uka.lean/.lake/build/lib -lUkaLean \
  -L$(lean --print-prefix)/lib/lean -lleanrt \
  -lws2_32 -lgmp -lpthread
```

> **Lean のパスを調べるにゃ:** `lean --print-prefix` で表示されるにゃ。
> 例: `C:/Users/(名前)/.elan/toolchains/leanprover--lean4---v4.28.0`

---

### 5. ゴーストの ghost/master/ に配置するにゃ

```bash
cp shiori.dll /path/to/SSP/ghost/(ゴースト名)/ghost/master/
```

必要にゃファスキクルスは `shiori.dll` 一つだけにゃ。
（Lean ランタイムは静的にゃリンクされているにゃ）

---

### 6. SSP で起動して確認にゃ

SSP でゴーストを起動して OnBoot が動けば成功にゃん♪
`ghost_status.dat` は `ghost/master/` に自動的に生成されるにゃ。

---

## 永続化ファスキクルスの形式

`{ghost}/ghost_status.dat` に平文で保存されるにゃ:

```
greetCount=42
liked=true
```

- 1行1變數、`=` 区切りにゃ
- `persistent` 變數のみ保存・復元されるにゃ（`transient` は保存されにゃい）
- ファスキクルスがない場合は `:= 初期値` が使はれるにゃ

---

## ファスキクルス構成

```
uka.lean/
├── lean-toolchain              ← leanprover/lean4:v4.28.0
├── lakefile.toml
├── UkaLean.lean                ← 根モドゥルス（全體を再輸出）
├── UkaLean/
│   ├── Protocollum.lean        ← SHIORI/3.0 共通型・定數
│   ├── SakuraScriptum.lean     ← SakuraScript モナド DSL
│   ├── Rogatio.lean            ← SHIORI/3.0 要求構文解析器
│   ├── Responsum.lean          ← SHIORI/3.0 應答構築器
│   ├── Nuculum.lean            ← 核心骨格（Shiori 型・事象經路設定）
│   ├── Exporta.lean            ← @[export] FFI 輸出關數群
│   ├── StatusPermanens.lean    ← 永続化型クラスと補助關數
│   ├── Macro.lean              ← ghost_var / ghost_on / build_ghost
│   └── Exemplum.lean           ← 使用例
├── ffi/
│   └── shiori.c                ← C 包裝（SSP ↔ Lean 橋渡し）
└── Main.lean                   ← 模擬試驗用實行體
```

---

## 仕樣參照

- [UKADOC Project](https://ssp.shillest.net/ukadoc/manual/index.html) — SHIORI/3.0 仕樣・SakuraScript 仕樣
- [SSP](http://ssp.shillest.net/) — ベースウェア公式
