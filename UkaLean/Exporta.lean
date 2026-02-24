-- UkaLean.Exporta
-- @[export] を用ゐた FFI 輸出關數群にゃん
-- C 包裝（ffi/shiori.c）からこれらの關數が呼ばれるにゃ

import UkaLean.Nuculum

namespace UkaLean

/-- 全域の栞參照にゃん。initialize で自動的に作られるにゃ -/
initialize shioriGlobalis : IO.Ref (Option Shiori) ← IO.mkRef none

/-- お嬢樣の處理器一覽を栞に登錄するにゃん。
    初期化時（DLL の load 前）に呼ぶにゃ -/
def registraShiori (tractatores : List (String × Tractator)) : IO Unit := do
  let s ← Shiori.creare tractatores
  shioriGlobalis.set (some s)

/-- フック付き版の登錄關數にゃん♪
    永続化ゴーストはこちらを使ふにゃ -/
def registraShioriEx
    (tractatores : List (String × Tractator))
    (onOnerare   : Option (String → IO Unit) := none)
    (onExire     : Option (IO Unit)          := none) : IO Unit := do
  let s ← Shiori.creare tractatores onOnerare onExire
  shioriGlobalis.set (some s)

/-- 栞が登錄濟みか確認するにゃん -/
def estRegistrata : IO Bool := do
  let opt ← shioriGlobalis.get
  return opt.isSome

/-- 家ディレクトーリウム（ゴーストのフォルダー）を取得するにゃん。
    OnBoot や OnClose 等の處理器からダータ保存先を知る時に使ふにゃ♪
    load() が呼ばれる前は空文字列を返すにゃ -/
def domusObtinere : IO String := do
  let opt ← shioriGlobalis.get
  match opt with
  | some s => s.obtinereDomus
  | none   => return ""

-- ═══════════════════════════════════════════════════
-- C から呼ばれる輸出關數群にゃん
-- ffi/shiori.c の load/unload/request がこれらを呼ぶにゃ
-- ═══════════════════════════════════════════════════

/-- C 側の load() から呼ばれるにゃん。
    家ディレクトーリウムを設定して初期化するにゃ -/
@[export lean_shiori_load]
unsafe def exportaLoad (catenaDominis : @& String) : IO UInt32 := do
  let opt ← shioriGlobalis.get
  match opt with
  | some s =>
    s.statuereDomus catenaDominis
    -- 讀込フックがあれば呼ぶにゃん♪（永続化ダータの復元にゃ）
    match s.onOnerare with
    | some actio => actio catenaDominis
    | none       => pure ()
    return 1  -- TRUE にゃ
  | none =>
    return 0  -- FALSE: 栞が登錄されてにゃいにゃ

/-- C 側の unload() から呼ばれるにゃん -/
@[export lean_shiori_unload]
unsafe def exportaUnload : IO UInt32 := do
  -- 書出フックがあれば呼ぶにゃん♪（永続化ダータの保存にゃ）
  let opt ← shioriGlobalis.get
  match opt with
  | some s =>
    match s.onExire with
    | some actio => actio
    | none       => pure ()
  | none => pure ()
  return 1  -- TRUE にゃ

/-- C 側の request() から呼ばれるにゃん。
    SHIORI/3.0 要求文字列を受け取り、應答文字列を返すにゃ -/
@[export lean_shiori_request]
unsafe def exportaRequest (catenaRogationis : @& String) : IO String := do
  let opt ← shioriGlobalis.get
  match opt with
  | some shiori =>
    shiori.tractaCatenam catenaRogationis
  | none =>
    return Responsum.errorInternus.adProtocollum

end UkaLean
