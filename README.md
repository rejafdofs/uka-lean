# UkaLean

Lean 4 (v4.28.0) で實裝した伺か(Ukagaka)用 SHIORI 栞。SakuraScript モナドにより `do` 記法で型安全にスクリプトを構築でき、FFI 經由で `SHIORI.DLL` として構築可能。

## ファイル構成

```
uka.lean/
├── lean-toolchain              ← leanprover/lean4:v4.28.0
├── lakefile.toml               ← Lake 構築設定
├── UkaLean.lean                ← 根モジュール（全體を再輸出）
├── UkaLean/
│   ├── Protocollum.lean        ← SHIORI/3.0 共通型・定數
│   ├── SakuraScriptum.lean     ← ★ SakuraScript モナド DSL
│   ├── Rogatio.lean            ← SHIORI/3.0 要求構文解析器
│   ├── Responsum.lean          ← SHIORI/3.0 應答構築器
│   ├── Nuculum.lean            ← 核心骨格（Shiori 型・事象經路設定）
│   ├── Exporta.lean            ← @[export] FFI 輸出關數群
│   └── Exemplum.lean           ← 使用例
├── ffi/
│   └── shiori.c                ← C 包裝（HGLOBAL ↔ Lean 橋渡し）
└── Main.lean                   ← 模擬試驗用實行體
```

## 設計思想

使用者（ゴースト作者）は **`Rogatio → SakuraIO Unit` 型の關數を書くだけ**。SHIORI/3.0 の構文解析・應答整形・DLL 輸出は全て骨格側が擔ふ。

```
SSP (baseware)
  ↕ HGLOBAL (ffi/shiori.c が橋渡し)
Lean 4 (@[export] 關數)
  ↕ Rogatio.parse / Responsum.adProtocollum
Shiori.tracta (事象經路設定)
  ↕ 事象名で處理器を檢索
使用者定義の Tractator 關數
  ↕ SakuraScript モナド (do 記法)
SakuraScript 文字列
```

## 使ひ方

### 1. 處理器を定義する

```lean
import UkaLean.Nuculum
open UkaLean Sakura

def onBoot (_ : Rogatio) : SakuraIO Unit := do
  sakura; superficies 0
  loqui "やあ、起動したにゃん！"
  mora 500; linea
  kero; superficies 10
  loqui "いらっしゃいませ。"
  finis

def onClose (_ : Rogatio) : SakuraIO Unit := do
  sakura; superficies 3
  loqui "またにゃー！"
  finis

def onMouseDoubleClick (r : Rogatio) : SakuraIO Unit := do
  match r.ref 4 with
  | some "Head" =>
    sakura; superficies 5
    loqui "撫でてくれるのにゃ？嬉しいにゃん♪"
  | _ =>
    sakura; superficies 0
    loqui "なでなでにゃん"
  finis
```

### 2. 處理器一覽を登錄する

```lean
def meusTractatores : List (String × Tractator) := [
  ("OnBoot",             onBoot),
  ("OnClose",            onClose),
  ("OnMouseDoubleClick", onMouseDoubleClick)
]
```

### 3. 構築と試驗

```bash
# 構築
lake build

# 模擬試驗（DLL なしで動作確認）
lake exe shiori-probatio
```

### 4. DLL 構築（SHIORI.DLL）

```bash
lake build
gcc -shared -o shiori.dll ffi/shiori.c \
  -I$(lean --print-prefix)/include \
  -L.lake/build/lib -lUkaLean \
  -L$(lean --print-prefix)/lib/lean -lleanrt \
  -lws2_32 -lgmp -lpthread
```

生成された `shiori.dll` をゴーストの `ghost/master/` に配置すれば SSP が讀み込む。

## モジュール詳細

### Protocollum.lean — 共通型

| 型 | 說明 |
|---|---|
| `Methodus` | `.get` (GET: 應答期待) / `.notifica` (NOTIFY: 通知のみ) |
| `StatusCodis` | `.ok` (200) / `.noContent` (204) / `.badRequest` (400) / `.serverError` (500) |
| `shioriVersio` | `"SHIORI/3.0"` |
| `crlf` | `"\r\n"` |

### SakuraScriptum.lean — SakuraScript モナド

中核の型定義:

```lean
abbrev SakuraM (m : Type → Type) [Monad m] (α : Type) := StateT String m α
abbrev SakuraIO (α : Type) := SakuraM IO α      -- IO 附き（處理器用）
abbrev SakuraPura (α : Type) := SakuraM Id α     -- 純粹（副作用不要時）
```

基底モナド `m` に對して汎用的なので、純粹計算も IO 附き計算も同一の DSL 關數で書ける。

#### DSL 關數一覽

**基底操作:**

| 關數 | SakuraScript | 說明 |
|---|---|---|
| `emitte s` | (任意) | 生の文字列斷片を發出 |
| `loqui s` | (文字列そのまま) | 文字を表示 |

**範圍制御（誰が喋るか）:**

| 關數 | SakuraScript | 說明 |
|---|---|---|
| `sakura` | `\h` | 主人格に切替 |
| `kero` | `\u` | 副人格に切替 |
| `persona n` | `\p[n]` | 第n人格に切替 |

**表面制御（表情）:**

| 關數 | SakuraScript | 說明 |
|---|---|---|
| `superficies n` | `\s[n]` | 表面 ID 設定 |
| `animatio n` | `\i[n]` | 表面動畫再生 |

**文字表示:**

| 關數 | SakuraScript | 說明 |
|---|---|---|
| `linea` | `\n` | 改行 |
| `dimidiaLinea` | `\n[half]` | 半改行 |
| `purga` | `\c` | 吹出し淸掃 |
| `adscribe` | `\C` | 前の吹出しに追記 |
| `cursor x y` | `\_l[x,y]` | カーソル位置指定 |

**待機（テンポ制御）:**

| 關數 | SakuraScript | 說明 |
|---|---|---|
| `mora ms` | `\_w[ms]` | ミリ秒待機 |
| `moraCeler n` | `\w[n]` | 簡易待機 (50ms×n) |
| `moraAbsoluta ms` | `\__w[ms]` | 絕對時間待機 |
| `expecta` | `\x` | 打鍵待ち |
| `expectaSine` | `\x[noclear]` | 打鍵待ち（淸掃なし） |
| `tempusCriticum` | `\t` | 時間制約區劃 |

**選擇肢:**

| 關數 | SakuraScript | 說明 |
|---|---|---|
| `optio titulus id` | `\q[titulus,id]` | 選擇肢追加 |
| `optioEventum titulus ev ref` | `\q[titulus,ev,r0,...]` | 事象附き選擇肢 |
| `ancora id` | `\_a[id]` | 錨（開始） |
| `fineAncora` | `\_a` | 錨（終了） |
| `tempusOptionum ms` | `\![set,choicetimeout,ms]` | 選擇時間制限 |
| `prohibeTempus` | `\*` | 時間切れ防止 |

**制御:**

| 關數 | SakuraScript | 說明 |
|---|---|---|
| `finis` | `\e` | スクリプト終了（**必須**） |
| `celer` | `\_q` | 即時表示切替 |
| `exitus` | `\-` | ゴースト退出 |
| `synchrona` | `\_s` | 同期區劃切替 |
| `mutaGhost` | `\+` | 隨機ゴースト切替 |

**書體:**

| 關數 | SakuraScript | 說明 |
|---|---|---|
| `audax b` | `\f[bold,b]` | 太字 |
| `obliquus b` | `\f[italic,b]` | 斜體 |
| `sublinea b` | `\f[underline,b]` | 下線 |
| `deletura b` | `\f[strike,b]` | 取消線 |
| `color r g b` | `\f[color,r,g,b]` | 文字色 |
| `altitudoLitterarum n` | `\f[height,n]` | 文字大きさ |
| `nomenFontis name` | `\f[name,name]` | 書體名 |
| `allineatio dir` | `\f[align,dir]` | 文字揃へ |
| `formaPraefinita` | `\f[default]` | 書式を既定に戾す |

**吹出し:**

| 關數 | SakuraScript | 說明 |
|---|---|---|
| `bulla n` | `\b[n]` | 吹出し ID 變更 |
| `imagoBullae via x y` | `\_b[via,x,y]` | 吹出し畫像重畳 |

**音聲:**

| 關數 | SakuraScript | 說明 |
|---|---|---|
| `sonus via` | `\_v[via]` | 音聲再生 |
| `expectaSonum` | `\_V` | 音聲終了待ち |

**事象:**

| 關數 | SakuraScript | 說明 |
|---|---|---|
| `excita ev ref` | `\![raise,ev,...]` | 事象發生 |
| `insere ev ref` | `\![embed,ev,...]` | 事象結果埋込 |
| `notifica ev ref` | `\![notify,ev,...]` | 通知事象 |

**窓制御:**

| 關數 | SakuraScript | 說明 |
|---|---|---|
| `accede` | `\5` | 近づく |
| `recede` | `\4` | 離れる |

**雜多:**

| 關數 | SakuraScript | 說明 |
|---|---|---|
| `aperi url` | `\j[url]` | URL を開く |
| `evade c` | `\\`, `\%`, `\]` | 特殊文字遁走 |
| `crudus tag` | (任意) | 生の標籤を直接發出 |

**便利關數:**

| 關數 | 說明 |
|---|---|
| `loquiEtLinea s` | 表示して改行 |
| `sakuraLoquitur sup s` | 主人格で表面設定して發言 |
| `keroLoquitur sup s` | 副人格で表面設定して發言 |

**實行:**

| 關數 | 型 | 說明 |
|---|---|---|
| `currere script initium` | `m String` | モナドを實行し SakuraScript 文字列を得る |

### Rogatio.lean — 要求構文解析

```lean
structure Rogatio where
  methodus    : Methodus           -- GET / NOTIFY
  id          : String             -- 事象名 (例: "OnBoot")
  referentiae : Array String       -- Reference0, Reference1, ...
  charset     : String             -- 文字符號化方式
  mittens     : Option String      -- Sender
  securitas   : Option String      -- SecurityLevel
  baseId      : Option String      -- BaseID
  cappitta    : List (String × String)  -- 全頭部（生）
```

| 關數 | 型 | 說明 |
|---|---|---|
| `Rogatio.parse s` | `Except String Rogatio` | SHIORI/3.0 要求文字列を構文解析 |
| `r.ref n` | `Option String` | Reference N を取得 |
| `r.caput clavis` | `Option String` | 任意の頭部を名前で取得 |

### Responsum.lean — 應答構築

```lean
structure Responsum where
  status   : StatusCodis                   -- 200/204/400/500
  valor    : Option String := none         -- Value (SakuraScript)
  cappitta : List (String × String) := []  -- 追加頭部
```

| 關數 | 說明 |
|---|---|
| `Responsum.ok scriptum` | 200 OK（Value 附き） |
| `Responsum.nihil` | 204 No Content |
| `Responsum.malaRogatio` | 400 Bad Request |
| `Responsum.errorInternus` | 500 Internal Server Error |
| `r.adProtocollum` | SHIORI/3.0 應答文字列に整形 |

### Nuculum.lean — 核心骨格

```lean
def Tractator := Rogatio → SakuraIO Unit

structure Shiori where
  tractatores : List (String × Tractator)
  status      : IO.Ref ShioriStatus
```

| 關數 | 說明 |
|---|---|
| `Shiori.creare tractatores` | 處理器一覽から栞を構築 |
| `s.tracta rogatio` | 要求を處理し應答を返す |
| `s.tractaCatenam reqStr` | 要求文字列 → 應答文字列（一氣通貫） |
| `s.statuereDomus domus` | 家ディレクトリ設定 |
| `s.obtinereDomus` | 家ディレクトリ取得 |

### Exporta.lean — FFI 輸出

| 輸出名 | Lean 關數 | 說明 |
|---|---|---|
| `lean_shiori_load` | `exportaLoad` | C 側 `load()` から呼ばれる |
| `lean_shiori_unload` | `exportaUnload` | C 側 `unload()` から呼ばれる |
| `lean_shiori_request` | `exportaRequest` | C 側 `request()` から呼ばれる |

| 關數 | 說明 |
|---|---|
| `registraShiori tractatores` | 處理器一覽を全域栞に登錄 |
| `estRegistrata` | 栞が登錄濟みか確認 |

## ffi/shiori.c の役割

SSP 等のベースウェアは `HGLOBAL`（Windows 全域記憶ハンドル）經由で SHIORI DLL と通信する。C 包裝は以下を擔ふ:

1. **`load(HGLOBAL h, long len)`** — Lean 實行時初期化 + 家ディレクトリ設定
2. **`unload()`** — 終了處理
3. **`request(HGLOBAL h, long *len)`** — HGLOBAL → Lean 文字列に變換 → Lean 側で處理 → 結果を HGLOBAL に複寫して返却

POSIX 環境用の模擬定義も含むため、Linux/macOS 上でも構築自體は可能。

## 模擬試驗の出力例

```
╔══════════════════════════════════════╗
║   UkaLean 栞 模擬試驗にゃん♪        ║
╚══════════════════════════════════════╝

── ① OnBoot ──
SHIORI/3.0 200 OK
Charset: UTF-8
Value: \h\s[0]やあ、起動したにゃん！\_w[500]\n\u\s[10]いらっしゃいませ。\e

── ② OnClose ──
SHIORI/3.0 200 OK
Charset: UTF-8
Value: \h\s[3]またにゃー！\_w[500]\n\u\s[14]お疲れ樣でした。\e

── ③ OnMouseDoubleClick (Head) ──
SHIORI/3.0 200 OK
Charset: UTF-8
Value: \h\s[5]撫でてくれるのにゃ？嬉しいにゃん♪\e

── ⑤ 未登錄事象 ──
SHIORI/3.0 204 No Content
Charset: UTF-8

── ⑥ SakuraScript モナド直接試驗 ──
生成 SakuraScript: \h\s[0]直接試驗にゃん♪\_w[300]\n\u\s[10]正しく動いてるにゃ。\e
```

## 依存關係

- **Lean 4 v4.28.0** — 外部ライブラリへの依存なし（mathlib 不要）
- **DLL 構築時のみ**: GCC (MinGW)、GMP

## 仕樣參照

- [UKADOC Project](https://ssp.shillest.net/ukadoc/manual/index.html) — SHIORI/3.0 仕樣・SakuraScript 仕樣
- [SSP](http://ssp.shillest.net/) — ベースウェア公式
