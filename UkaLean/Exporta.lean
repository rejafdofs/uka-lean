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

/-- 栞が登錄濟みか確認するにゃん -/
def estRegistrata : IO Bool := do
  let opt ← shioriGlobalis.get
  return opt.isSome

-- ═══════════════════════════════════════════════════
-- C から呼ばれる輸出關數群にゃん
-- ffi/shiori.c の load/unload/request がこれらを呼ぶにゃ
-- ═══════════════════════════════════════════════════

/-- C 側の load() から呼ばれるにゃん。
    家ディレクトーリウムを設定して初期化するにゃ -/
@[export lean_shiori_load]
unsafe def exportaLoad (dirStr : @& String) : IO UInt32 := do
  let opt ← shioriGlobalis.get
  match opt with
  | some s =>
    s.statuereDomus dirStr
    return 1  -- TRUE にゃ
  | none =>
    return 0  -- FALSE: 栞が登錄されてにゃいにゃ

/-- C 側の unload() から呼ばれるにゃん -/
@[export lean_shiori_unload]
unsafe def exportaUnload : IO UInt32 := do
  return 1  -- TRUE にゃ

/-- C 側の request() から呼ばれるにゃん。
    SHIORI/3.0 要求文字列を受け取り、應答文字列を返すにゃ -/
@[export lean_shiori_request]
unsafe def exportaRequest (reqStr : @& String) : IO String := do
  let opt ← shioriGlobalis.get
  match opt with
  | some shiori =>
    shiori.tractaCatenam reqStr
  | none =>
    return Responsum.errorInternus.adProtocollum

end UkaLean
