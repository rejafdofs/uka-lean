# uka.lean —  Lean 4 製 SHIORI

 SHIORI ビブリオテーカにゃん♪

- **型安全な永続化** — 保存→読込の往復を Lean 4 の定理として証明済みにゃ
- **型安全な Reference 変換** — `Citatio` クラッシスが `fromRef (toRef a) = a` を保証するにゃ
- **`do` 記法** — SakuraScriptum を直感的に組み立てられるにゃ
- 識別子は全てラテン語で統一されてゐるにゃ

---

## はじめに (Introductio)

### 前提 (Praemissa)

- [Lean 4 / elan](https://leanprover.github.io/lean4/doc/setup.html)（Lake 附属）
- Windows 環境（`shiori.dll` を動かすのに必要にゃ）

### ① 新規プロヱクトゥムを作るにゃ

```bash
lake new my-ghost
cd my-ghost
```

### ② `lakefile.toml` に追記するにゃ

```toml
name = "my-ghost"
version = "0.1.0"

[[require]]
git = "https://github.com/rejafdofs/uka-lean"
rev = "main"
name = "PuraShiori"

[[lean_lib]]
name = "Ghost"

[[lean_exe]]
name = "ghost"
root = "Main"
```

### ③ `Main.lean` を書くにゃ

```lean
import PuraShiori
open PuraShiori Sakura

varia perpetua   numerusSalutationum : Nat := 0
varia temporaria nomina              : String := ""

eventum "OnBoot" fun _ => do
  numerusSalutationum.renovare (· + 1)
  let numerus <- numerusSalutationum.obtinere
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
  sakura; superficies 3; loqui "またにゃー！"
  finis

construe

def main : IO Unit := PuraShiori.loopPrincipalis
```

### ④ 構築するにゃ

```bash
lake update
lake build ghost
```

### ⑤ `shiori.dll` を配置するにゃ

Releases から最新の `shiori.dll` を入手して、`ghost.exe` と同じフォルダに置くにゃ。

```
ghost/master/
├── shiori.dll        ← SSP から読まれる代理にゃ
├── ghost.exe         ← Lean 構築物にゃ
└── ghost_status.bin  ← 永続化ダータ（自動生成）にゃ
```

---

## 宣言の書き方

### `varia` — 變數の宣言

```lean
varia perpetua   名前 : 型 := 初期値   -- 終了時に保存・起動時に復元するにゃ
varia temporaria 名前 : 型 := 初期値   -- 起動中だけ使ふ一時的な變數にゃ
```

變数は `IO.Ref` として展開されるにゃ。

```lean
let n <- numerusSalutationum.obtinere   -- 読取にゃ
numerusSalutationum.statuere 42        -- 設定にゃ
numerusSalutationum.renovare (· + 1)   -- 更新にゃ
```

使へる型: `Nat` `Int` `Bool` `String` `Float` `UInt8/16/32/64` `Char` `ByteArray` `Option α` `List α` `Array α` `α × β`、および `StatusPermanens` クラッシスの実体を持つ任意の型にゃ。

**型安全な永続化にゃ♪**
型が変はつても `typusTag` が一致しにゃければ安全に読み飛ばされるにゃん。
保存→復元の往復は `serializeMappam_roundtrip` 定理として Lean 4 で証明済みにゃ（補題は一部 sorry）。

---

### `eventum` — 事象処理器の宣言

```lean
eventum "事象名" fun rogatio => do
  -- rogatio : Rogatio（SSP からの要求情報）
  ...
  finis   -- 末尾に必ず書くにゃ
```

`rogatio` から取れるもの:

| 式 | 型 | 内容 |
|---|---|---|
| `rogatio.nomen` | `String` | 事象名 |
| `rogatio.referentiam 0` | `Option String` | Reference0 |
| `rogatio.mittens` | `Option String` | Sender ヘッダ |
| `rogatio.caput "key"` | `Option String` | 任意ヘッダ |

---

### `construe` — 栞の総仕上げ

```lean
construe
```

主ファスキクルスの末尾に一度書くにゃ。`eventum` と `excita`/`insere` 識別子形で宣言した全ての処理器を自動収集して登録するにゃ♪

---

## def 関數と `excita` / `insere`

通常の `def` 関數を事象として登録できるにゃ。`excita` / `insere` の識別子形を任意の `def` 内で使ふと、`construe` 時に自動でラッパーが生成されて登録されるにゃん♪

引數は `Citatio.toRef` で文字列 Reference に変換され、呼び出し時に `Citatio.fromRef` で復元されるにゃ。

```lean
-- 通常の def で処理を定義するにゃ
def onGreet (nomen : String) (kai : Nat) : SakuraIO Unit := do
  sakura; superficies 0
  loquiEtLinea s!"こんにちは、{nomen}さん！{kai}囘目にゃ"
  finis

eventum "OnGreet" fun rogatio => do
  let nomen := (rogatio.referentiam 0).getD "ゲスト"
  let kai   := (rogatio.referentiam 1).getD "0"
  onGreet nomen kai.toNat!   -- 直接呼ぶ（インライン展開）にゃ
  finis

eventum "OnBoot" fun _ => do
  excita onGreet "れゃ" 42   -- \![raise,Ns.onGreet] + 自動登録にゃん♪
  finis

construe
```

`excita` は `\![raise,...]` に展開、`insere` は `\![embed,...]` に展開されるにゃ。
SSP 組み込み事象には文字列形 `excita "OnBoot"` を使ふにゃ。

---

## SakuraScriptum 命令一覧 (Mandata)

`open PuraShiori Sakura` してから使ふにゃ。

### 人格・表情

| 命令 | SakuraScript | 意味 |
|---|---|---|
| `sakura` | `\h` | 主人格に切り替へ |
| `kero` | `\u` | 副人格に切り替へ |
| `persona n` | `\p[n]` | 第 n 人格に切り替へ |
| `superficies n` | `\s[n]` | 表情を n 番にする |
| `animatio n` | `\i[n]` | 動画 n 番を再生 |

### 文字表示

| 命令 | 意味 |
|---|---|
| `loqui "文字列"` | 文字を表示（特殊文字自動エスケープ）にゃ |
| `loquiEtLinea "文字列"` | 表示して改行にゃ |
| `linea` / `dimidiaLinea` | 改行 / 半改行にゃ |
| `purga` | 吹き出しを消去にゃ |
| `finis` | **スクリプト終了（必須）** にゃ |

### 待機・操作

| 命令 | 意味 |
|---|---|
| `mora ms` | ms ミリ秒待機にゃ |
| `expecta` | 打鍵待ち（消去あり）にゃ |
| `expectaSine` | 打鍵待ち（消去なし）にゃ |
| `excita "Event"` | SSP 組み込み事象を発生させるにゃ（文字列形）にゃ |
| `excita f args*` | def ベース事象を発生させるにゃ（識別子形）にゃ |
| `insere f args*` | def ベース事象を埋め込むにゃ（識別子形）にゃ |
| `exitus` | ゴーストを終了させるにゃ |

### 選択肢

| 命令 | 意味 |
|---|---|
| `optio "表示名" "EventName"` | 選択肢を追加にゃ |
| `optioEventum "表示名" "EventName" ["r0","r1"]` | Reference 付き選択肢にゃ |
| `ancora "signum"` … `fineAncora` | 錨（クリック可能テキスト）にゃ |

### 書体

| 命令 | 意味 |
|---|---|
| `audax true/false` | 太字 ON/OFF にゃ |
| `obliquus true/false` | 斜体 ON/OFF にゃ |
| `color r g b` | 文字色（0〜255）にゃ |
| `altitudoLitterarum n` | 文字サイズにゃ |
| `formaPraefinita` | 書式を既定に戻すにゃ |
| `crudus "signum"` | 生の SakuraScript を直接出力にゃ |
| `sonus "via"` | 音声を再生にゃ |
| `aperi "nexus"` | URL を開くにゃ |

便利な一括命令:

```lean
sakuraLoquitur 0 "こんにちは"   -- sakura; superficies 0; loqui "..."
keroLoquitur 10 "にゃ！"        -- kero; superficies 10; loqui "..."
```

---

## 無作為選択 (Fortuita)

```lean
fortuito #["やっほー！", "こんにちは！", "おはよう！"]
-- ランダムに 1 つ選んで loqui で表示にゃ

let s <- elige #["A", "B", "C"]   -- ランダムに 1 つ選んで返すにゃ
```

---

## 即時保存 (servaStatum)

`construe` が自動生成する `servaStatum : IO Unit` を使へば、任意のタイミングで `perpetua` 變數を保存できるにゃ。

```lean
eventum "OnBoot" fun _ => do
  numerusSalutationum.renovare (· + 1)
  servaStatum           -- 即時保存にゃ！
  sakura; superficies 0
  loqui s!"起動 {<- numerusSalutationum.obtinere} 囘目にゃん♪"
  finis
```

---

## 永続化ファスキクルスの形式 (Forma Datorum Permanens)

`ghost_status.bin` にバイナリ形式 v3（マジックバイト `UKA\x03`）で保存されるにゃ。`perpetua` 變數のみ保存・復元されるにゃ。

| 型 | `typusTag` | エンコード |
|---|---|---|
| `Nat` | `"Nat"` | UInt64 LE 8バイトにゃ |
| `Int` | `"Int"` | Int64 LE 8バイトにゃ |
| `Bool` | `"Bool"` | 1バイト（0/1）にゃ |
| `String` | `"String"` | UTF-8 バイト列にゃ |
| `Float` | `"Float"` | IEEE 754 倍精度 8バイトにゃ |
| `UInt8/16/32/64` | `"UInt8"` 等 | 各サイズ LE にゃ |
| `Char` | `"Char"` | UInt32 として Unicode 符号点にゃ |
| `ByteArray` | `"ByteArray"` | そのままにゃ |
| `Option α` | `"Option(α)"` | 1バイトタグ + 中身にゃ |
| `List α` | `"List(α)"` | 4バイト要素数 + 各要素にゃ |
| `Array α` | `"Array(α)"` | `List α` と同じにゃ |
| `α × β` | `"Prod(α,β)"` | フィールドの連結にゃ |

### 自作構造体の永続化

```lean
structure DatorumLusoris where
  gradus : Nat
  nomen  : String

instance : StatusPermanens DatorumLusoris where
  typusTag := "DatorumLusoris"
  adBytes p :=
    encodeField p.gradus ++
    encodeField p.nomen
  eBytes b := do
    let (gradus, pos1) <- decodeField b 0
    let (nomen,  _)    <- decodeField b pos1
    return { gradus, nomen }
  roundtrip :=by sorry

varia perpetua lusor : DatorumLusoris := { gradus := 1, nomen := "シロ" }
```

### `Citatio` クラッシスによる Reference 変換

SHIORI Reference（文字列）への往復変換を型クラスで保証するにゃ。

```lean
class Citatio (α : Type) where
  toRef     : α -> String
  fromRef   : String -> α
  roundtrip : forall (a : α), fromRef (toRef a) = a   -- 往復が定理として保証されるにゃ
```

基本型（`Nat` `Int` `Bool` `String` `Char` `UInt8/16/32/64` `Option α` `α × β`）の実体が定義済みにゃ。

---

## 参照 (Referentia)

- [UKADOC Project](https://ssp.shillest.net/ukadoc/manual/index.html) — SHIORI/3.0・SakuraScript 仕様にゃ
- [SSP](http://ssp.shillest.net/) — 基底ウェアにゃ
