-- UkaLean.StatusPermanens
-- 永続化（persistentia）の型クラスと補助關數にゃん♪
-- ghost_status.bin への讀み書きを擔ふにゃ

import Std.Tactic.BVDecide

namespace UkaLean

-- ═══════════════════════════════════════════════════
-- 型クラスにゃん
-- ═══════════════════════════════════════════════════

/-- 永続化できる型の型クラスにゃん。
    `typusTag` で型の文字列識別子を提供するにゃ。
    ゴーストの更新で變數の型が變はった時でも、タグが不一致なら讀み飛ばすにゃ♪
    `adBytes` で ByteArray に直列化、`eBytes` で復元するにゃ。
    自作構造體も `encodeField`/`decodeField` を使へばインスタンスを書けるにゃん♪ -/
class StatusPermanens (α : Type) where
  /-- 型の文字列識別子にゃん。バージョン更新時の型チェックに使ふにゃ。
      例: `"Nat"`, `"String"`, `"List(Nat)"` 等にゃ -/
  typusTag : String
  /-- 値を ByteArray に直列化するにゃん -/
  adBytes  : α → ByteArray
  /-- ByteArray から値を復元するにゃん。失敗したら `none` を返すにゃ -/
  eBytes   : ByteArray → Option α

-- ═══════════════════════════════════════════════════
-- 内部補助: リトルエンディアン(LE)のエンコード/デコードにゃん
-- ═══════════════════════════════════════════════════

private def u16LE (n : UInt16) : ByteArray :=
  .mk #[(n &&& 0xFF).toUInt8,
        ((n >>> 8) &&& 0xFF).toUInt8]

private def u32LE (n : UInt32) : ByteArray :=
  .mk #[(n &&& 0xFF).toUInt8,
        ((n >>> 8)  &&& 0xFF).toUInt8,
        ((n >>> 16) &&& 0xFF).toUInt8,
        ((n >>> 24) &&& 0xFF).toUInt8]

private def u64LE (n : UInt64) : ByteArray :=
  .mk #[(n &&& 0xFF).toUInt8,
        ((n >>> 8)  &&& 0xFF).toUInt8,
        ((n >>> 16) &&& 0xFF).toUInt8,
        ((n >>> 24) &&& 0xFF).toUInt8,
        ((n >>> 32) &&& 0xFF).toUInt8,
        ((n >>> 40) &&& 0xFF).toUInt8,
        ((n >>> 48) &&& 0xFF).toUInt8,
        ((n >>> 56) &&& 0xFF).toUInt8]

-- (値, 次の位置) を返すにゃ
private def readU16LE (b : ByteArray) (positio : Nat) : Option (UInt16 × Nat) :=
  if positio + 2 > b.size then none
  else some (
    b[positio]!.toUInt16 |||
    (b[positio+1]!.toUInt16 <<< 8),
    positio + 2)

private def readU32LE (b : ByteArray) (positio : Nat) : Option (UInt32 × Nat) :=
  if positio + 4 > b.size then none
  else some (
    b[positio]!.toUInt32 |||
    (b[positio+1]!.toUInt32 <<< 8)  |||
    (b[positio+2]!.toUInt32 <<< 16) |||
    (b[positio+3]!.toUInt32 <<< 24),
    positio + 4)

private def readU64LE (b : ByteArray) (positio : Nat) : Option (UInt64 × Nat) :=
  if positio + 8 > b.size then none
  else some (
    b[positio]!.toUInt64 |||
    (b[positio+1]!.toUInt64 <<< 8)  |||
    (b[positio+2]!.toUInt64 <<< 16) |||
    (b[positio+3]!.toUInt64 <<< 24) |||
    (b[positio+4]!.toUInt64 <<< 32) |||
    (b[positio+5]!.toUInt64 <<< 40) |||
    (b[positio+6]!.toUInt64 <<< 48) |||
    (b[positio+7]!.toUInt64 <<< 56),
    positio + 8)

-- ═══════════════════════════════════════════════════
-- 公開補助: 自作構造體のインスタンス實裝に使ふにゃん♪
-- ═══════════════════════════════════════════════════

/-- 1フィールドを「4バイト長 + 本體」の形でエンコードするにゃん。
    自作構造體の `adBytes` 實裝に使ふにゃ:
    ```
    adBytes s := encodeField s.gradus ++ encodeField s.nomen
    ```
    -/
def encodeField {α : Type} [StatusPermanens α] (v : α) : ByteArray :=
  let b := StatusPermanens.adBytes v
  u32LE b.size.toUInt32 ++ b

/-- `positio` 位置から1フィールドを復元して `(値, 次の位置)` を返すにゃん。
    自作構造體の `eBytes` 實裝に使ふにゃ:
    ```
    eBytes b := do
      let (gradus, pos1) ← decodeField b 0
      let (nomen,  pos2) ← decodeField b pos1
      return { gradus, nomen }
    ```
    -/
def decodeField {α : Type} [StatusPermanens α]
    (b : ByteArray) (positio : Nat) : Option (α × Nat) := do
  let (longitudo, pos') ← readU32LE b positio
  let sectio := b.extract pos' (pos' + longitudo.toNat)
  let v ← StatusPermanens.eBytes sectio
  return (v, pos' + longitudo.toNat)

-- ═══════════════════════════════════════════════════
-- 基本型のインスタンスにゃん
-- ═══════════════════════════════════════════════════

-- String: UTF-8 バイト列そのままにゃ
instance : StatusPermanens String where
  typusTag := "String"
  adBytes s := s.toUTF8
  eBytes  b := String.fromUTF8? b

-- Nat: UInt64 LE（8バイト）にゃ。2^64 超は截斷されるにゃ
instance : StatusPermanens Nat where
  typusTag := "Nat"
  adBytes n := u64LE n.toUInt64
  eBytes  b := readU64LE b 0 |>.map (fun (v, _) => v.toNat)

-- Int: 二の補數 Int64 LE（8バイト）にゃ。範圍外は截斷されるにゃ
instance : StatusPermanens Int where
  typusTag := "Int"
  adBytes n :=
    match n with
    | Int.ofNat m   => u64LE m.toUInt64
    | Int.negSucc m => u64LE ((0 : UInt64) - (m + 1).toUInt64)
  eBytes b :=
    readU64LE b 0 |>.map fun (v, _) =>
      -- 最上位ビットが 1 なら負にゃ
      if v &&& ((1 : UInt64) <<< 63) = 0 then
        Int.ofNat v.toNat
      else
        -- 二の補數: -(0 - v) にゃ
        Int.negSucc ((0 - v).toNat - 1)

-- Bool: 1バイト (0 = false, 1 = true) にゃ
instance : StatusPermanens Bool where
  typusTag := "Bool"
  adBytes b := .mk #[if b then 1 else 0]
  eBytes  b := if b.size = 0 then none else some (b[0]! ≠ 0)

-- Float: IEEE 754 倍精度（8バイト）にゃ
instance : StatusPermanens Float where
  typusTag := "Float"
  adBytes f := u64LE f.toBits
  eBytes  b := readU64LE b 0 |>.map (fun (v, _) => Float.ofBits v)

-- UInt8: 1バイトにゃ
instance : StatusPermanens UInt8 where
  typusTag := "UInt8"
  adBytes n := .mk #[n]
  eBytes  b := if b.size = 0 then none else some b[0]!

-- UInt16: 2バイト LE にゃ
instance : StatusPermanens UInt16 where
  typusTag := "UInt16"
  adBytes n := u16LE n
  eBytes  b := readU16LE b 0 |>.map (fun (v, _) => v)

-- UInt32: 4バイト LE にゃ
instance : StatusPermanens UInt32 where
  typusTag := "UInt32"
  adBytes n := u32LE n
  eBytes  b := readU32LE b 0 |>.map (fun (v, _) => v)

-- UInt64: 8バイト LE にゃ
instance : StatusPermanens UInt64 where
  typusTag := "UInt64"
  adBytes n := u64LE n
  eBytes  b := readU64LE b 0 |>.map (fun (v, _) => v)

-- Char: UInt32 として Unicode 符号點をエンコードするにゃ
instance : StatusPermanens Char where
  typusTag := "Char"
  adBytes c := u32LE c.val
  eBytes  b := do
    let (n, _) ← readU32LE b 0
    -- 有效な Unicode 符号點かどうか確認するにゃ
    if h : n.isValidChar then some ⟨n, h⟩ else none

-- ByteArray: 中身をそのまま保存するにゃ
instance : StatusPermanens ByteArray where
  typusTag := "ByteArray"
  adBytes b := b
  eBytes  b := some b

-- Option α: 1バイトタグ(0=none, 1=some) + 中身にゃ
instance {α : Type} [StatusPermanens α] : StatusPermanens (Option α) where
  typusTag := "Option(" ++ StatusPermanens.typusTag (α := α) ++ ")"
  adBytes
    | none   => .mk #[0]
    | some v => .mk #[1] ++ StatusPermanens.adBytes v
  eBytes b :=
    if b.size = 0 then none
    else if b[0]! = 0 then some none
    else (StatusPermanens.eBytes (b.extract 1 b.size)).map some

-- List α: 4バイト要素數 + (4バイト長 + 本體) の繰り返しにゃ
private def decodeManyLoop {α : Type} [StatusPermanens α]
    (b : ByteArray) (n : Nat) (positio : Nat) : Option (List α × Nat) :=
  match n with
  | 0     => some ([], positio)
  | n + 1 => do
    let (v, pos') ← decodeField b positio
    let (residuum, positioFinalis) ← decodeManyLoop b n pos'
    return (v :: residuum, positioFinalis)

instance {α : Type} [StatusPermanens α] : StatusPermanens (List α) where
  typusTag := "List(" ++ StatusPermanens.typusTag (α := α) ++ ")"
  adBytes xs :=
    xs.foldl (fun acc x => acc ++ encodeField x) (u32LE xs.length.toUInt32)
  eBytes b := do
    let (numerus, positio) ← readU32LE b 0
    let (xs, _) ← decodeManyLoop b numerus.toNat positio
    return xs

-- Array α: List α と同じ形式にゃ
instance {α : Type} [StatusPermanens α] : StatusPermanens (Array α) where
  typusTag := "Array(" ++ StatusPermanens.typusTag (α := α) ++ ")"
  adBytes xs := StatusPermanens.adBytes xs.toList
  eBytes  b  := (StatusPermanens.eBytes b : Option (List α)).map List.toArray

-- α × β: encodeField の組合せにゃ
instance {α β : Type} [StatusPermanens α] [StatusPermanens β]
    : StatusPermanens (α × β) where
  typusTag := "Prod(" ++ StatusPermanens.typusTag (α := α) ++ "," ++
              StatusPermanens.typusTag (α := β) ++ ")"
  adBytes p := encodeField p.1 ++ encodeField p.2
  eBytes b := do
    let (a, positio) ← decodeField b 0
    let (secundum, _) ← decodeField b positio
    return (a, secundum)

-- ═══════════════════════════════════════════════════
-- バイナリファスキクルス(ghost_status.bin)の讀み書きにゃん
-- 形式 v2: magic(4) | 項目數(u32) | [鍵長|鍵|typusTag長|typusTag|值長|値]...
-- v1（magic=UKA\x01）は型タグなし・舊形式にゃ。v2 に更新されるにゃ
-- ═══════════════════════════════════════════════════

-- マジックバイト: "UKA\x02"（v2: 型タグ付き形式にゃ）
private def magicBytes : ByteArray := .mk #[0x55, 0x4B, 0x41, 0x02]

-- バイナリから (名前, 型タグ, バイト列) の三つ組を再帰的に讀むにゃ
private def legereParia
    (b : ByteArray) (n : Nat) (positio : Nat)
    : Option (List (String × String × ByteArray) × Nat) :=
  match n with
  | 0     => some ([], positio)
  | n + 1 => do
    -- キー名にゃ
    let (longitudoNominis, pos1) ← readU32LE b positio
    if pos1 + longitudoNominis.toNat > b.size then none
    else do
      let octetiNominis := b.extract pos1 (pos1 + longitudoNominis.toNat)
      let nomenEntriae  ← String.fromUTF8? octetiNominis
      let pos2          := pos1 + longitudoNominis.toNat
      -- 型タグにゃ
      let (longitudoTypi, pos3) ← readU32LE b pos2
      if pos3 + longitudoTypi.toNat > b.size then none
      else do
        let octetiTypi := b.extract pos3 (pos3 + longitudoTypi.toNat)
        let tag        ← String.fromUTF8? octetiTypi
        let pos4       := pos3 + longitudoTypi.toNat
        -- 値にゃ
        let (longitudoValorum, pos5) ← readU32LE b pos4
        if pos5 + longitudoValorum.toNat > b.size then none
        else do
          let valor      := b.extract pos5 (pos5 + longitudoValorum.toNat)
          let pos6       := pos5 + longitudoValorum.toNat
          let (residuum, positioFinalis) ← legereParia b n pos6
          return ((nomenEntriae, tag, valor) :: residuum, positioFinalis)

/-- `ghost_status.bin` から `(名前, 型タグ, ByteArray)` の三つ組を讀み込むにゃん♪
    ファスキクルスが存在しにゃい・形式が不正にゃ場合は空の一覽を返すにゃ -/
def legereMappam (via : String) : IO (List (String × String × ByteArray)) := do
  try
    let b ← IO.FS.readBinFile via
    -- 最低8バイト必要にゃ（マジック4 + エントリ數4）
    if b.size < 8 then return []
    if b.extract 0 4 != magicBytes then return []
    -- エントリ數にゃ
    let some (numerus, positio) := readU32LE b 4 | return []
    let some (paria, _)         := legereParia b numerus.toNat positio | return []
    return paria
  catch _ =>
    -- ファスキクルスが存在しにゃい場合はエッロルを無視するにゃ
    return []

/-- `(名前, 型タグ, ByteArray)` の三つ組を `ghost_status.bin` に書き出すにゃん♪ -/
def scribeMappam
    (via : String)
    (paria : List (String × String × ByteArray)) : IO Unit := do
  let numerus := u32LE paria.length.toUInt32
  let corpus  := paria.foldl (fun accumulatum elementum =>
    let (k, tag, v) := elementum
    let octetiNominis := k.toUTF8
    let octetiTypi    := tag.toUTF8
    accumulatum ++ u32LE octetiNominis.size.toUInt32 ++ octetiNominis
               ++ u32LE octetiTypi.size.toUInt32    ++ octetiTypi
               ++ u32LE v.size.toUInt32             ++ v) .empty
  IO.FS.writeBinFile via (magicBytes ++ numerus ++ corpus)

/-- 名前→設定器の一覽を使って一括復元するにゃん。
    保存ダータに含まれる項目のうち **typusTag が一致するもの** だけを復元するにゃ♪
    型が變はった變數は安全に讀み飛ばされるにゃ -/
def executareLecturam
    (paria     : List (String × String × ByteArray))
    (tractores : List (String × (String → ByteArray → IO Unit))) : IO Unit := do
  for elementum in paria do
    let (nomen, tag, valor) := elementum
    match tractores.lookup nomen with
    | some actio => actio tag valor
    | none       => pure ()  -- 知らにゃい名前は無視するにゃ

/-- 名前→取得器の一覽を使って一括保存するにゃん♪
    各項目は `(型タグ, ByteArray)` の形で保存されるにゃ -/
def executareScripturam
    (tractores : List (String × IO (String × ByteArray)))
    : IO (List (String × String × ByteArray)) := do
  let mut paria : List (String × String × ByteArray) := []
  for (nomen, actio) in tractores do
    let (tag, valor) ← actio
    paria := paria ++ [(nomen, tag, valor)]
  return paria

-- ═══════════════════════════════════════════════════
-- encodeField / decodeField 逆關數の定理にゃん♪
-- ═══════════════════════════════════════════════════

/-- `u32LE n` のサイズは常に 4 バイトにゃ -/
private theorem u32LE_size (n : UInt32) : (u32LE n).size = 4 := by
  simp [u32LE, ByteArray.size]

/-- UInt32 のリトルエンディアン分解の逆操作にゃん♪
    各バイトをマスク＆シフトで取り出してから再合成すると元に戻るにゃ -/
private theorem uint32_byte_roundtrip (n : UInt32) :
    (n &&& 0xFF).toUInt8.toUInt32 |||
    (((n >>> 8) &&& 0xFF).toUInt8.toUInt32 <<< 8) |||
    (((n >>> 16) &&& 0xFF).toUInt8.toUInt32 <<< 16) |||
    (((n >>> 24) &&& 0xFF).toUInt8.toUInt32 <<< 24) = n := by
  bv_decide

/-- `u32LE n ++ rest` の先頭 4 バイトを `readU32LE` で讀むと `n` が戻るにゃ -/
private theorem readU32LE_u32LE (n : UInt32) (rest : ByteArray) :
    readU32LE (u32LE n ++ rest) 0 = some (n, 4) := by
  unfold readU32LE u32LE
  -- サイズが 4 + rest.size であることを simp ループなしに示すにゃ
  have hsize : (ByteArray.mk #[(n &&& 0xFF).toUInt8,
      ((n >>> 8) &&& 0xFF).toUInt8, ((n >>> 16) &&& 0xFF).toUInt8,
      ((n >>> 24) &&& 0xFF).toUInt8] ++ rest).size = 4 + rest.size := by
    rw [ByteArray.size_append]; rfl
  have hsz : ¬ (0 + 4 > (ByteArray.mk #[(n &&& 0xFF).toUInt8,
      ((n >>> 8) &&& 0xFF).toUInt8, ((n >>> 16) &&& 0xFF).toUInt8,
      ((n >>> 24) &&& 0xFF).toUInt8] ++ rest).size) := by
    omega
  simp only [show 0 + 4 = 4 from rfl, hsz, ite_false]
  exact congrArg (fun x => some (x, 4)) (uint32_byte_roundtrip n)

/-- `(a ++ b).extract a.size (a.size + b.size) = b` にゃん♪
    `ByteArray.extract_append_eq_right` で即座に解決されるにゃ -/
private theorem byteArray_extract_after_prefix (a b : ByteArray) :
    (a ++ b).extract a.size (a.size + b.size) = b :=
  ByteArray.extract_append_eq_right rfl rfl

/-- `b.size < 2^32` のとき `b.size.toUInt32.toNat = b.size` にゃ -/
private theorem size_roundTrip (b : ByteArray) (h : b.size < 2 ^ 32) :
    b.size.toUInt32.toNat = b.size := by
  simp only [UInt32.toNat, Nat.toUInt32, UInt32.ofNat]
  rw [BitVec.toNat_ofNat]
  exact Nat.mod_eq_of_lt h

/-- **主定理** にゃん♪
    `lexAequalitatis`: `eBytes (adBytes v) = some v`（インスタンスの正しさ）にゃ
    `magnitudoMinor`: 直列化サイズが 2^32 未滿（`u32LE` に收まる）にゃ -/
theorem decodeField_encodeField_eq
    {α : Type} [StatusPermanens α]
    (v : α)
    (lexAequalitatis : StatusPermanens.eBytes (StatusPermanens.adBytes v) = some v)
    (magnitudoMinor  : (StatusPermanens.adBytes v).size < 2 ^ 32) :
    decodeField (α := α) (encodeField v) 0 =
      some (v, 4 + (StatusPermanens.adBytes v).size) := by
  simp only [encodeField, decodeField]
  rw [readU32LE_u32LE]
  have hsr := size_roundTrip (StatusPermanens.adBytes v) magnitudoMinor
  have hslice :
      (u32LE (StatusPermanens.adBytes v).size.toUInt32 ++
       StatusPermanens.adBytes v).extract 4
        (4 + (StatusPermanens.adBytes v).size.toUInt32.toNat) =
      StatusPermanens.adBytes v := by
    rw [hsr]
    have h4 : (u32LE (StatusPermanens.adBytes v).size.toUInt32).size = 4 :=
      u32LE_size _
    rw [← h4]
    exact byteArray_extract_after_prefix _ _
  -- `change` で do 記法を明示的な >>= 形に変換するにゃん（定義的等価にゃ）
  change (StatusPermanens.eBytes
      ((u32LE (StatusPermanens.adBytes v).size.toUInt32 ++
        StatusPermanens.adBytes v).extract 4
        (4 + (StatusPermanens.adBytes v).size.toUInt32.toNat)) >>=
    fun w => some (w, 4 + (StatusPermanens.adBytes v).size.toUInt32.toNat)) =
    some (v, 4 + (StatusPermanens.adBytes v).size)
  rw [hslice, lexAequalitatis, hsr]
  -- `some v >>= fun w => some (w, ...)` は ι 簡約で `some (v, ...)` にゃん♪
  rfl

end UkaLean
