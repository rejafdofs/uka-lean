-- UkaLean.Nuculum
-- 栞の核心骨格にゃん。處理器の登錄と事象のルーティングを擔ふにゃ

import UkaLean.Protocollum
import UkaLean.SakuraScriptum
import UkaLean.Rogatio
import UkaLean.Responsum

namespace UkaLean

/-- 事象處理器の型にゃん。
    お嬢樣はこの型の關數を書くだけでよいにゃ。
    Rogatio を受け取って SakuraScript を do 記法で組み立てるにゃん -/
def Tractator := Rogatio → SakuraIO Unit

/-- 栞の狀態にゃん -/
structure ShioriStatus where
  /-- 家ディレクトーリウム（ゴーストのフォルダーにゃ）-/
  domus : String := ""
  deriving Repr, Inhabited

/-- 栞の本體にゃん。處理器の一覽と可變狀態を持つにゃ -/
structure Shiori where
  /-- 事象名と處理器の對應表にゃん -/
  tractatores : List (String × Tractator)
  /-- 栞の可變狀態にゃ -/
  status : IO.Ref ShioriStatus
  /-- 讀込(load)時に呼ばれるフックにゃん。domus（家ディレクトーリウム）を受け取るにゃ -/
  onOnerare : Option (String → IO Unit) := none
  /-- 書出(unload)時に呼ばれるフックにゃん -/
  onExire   : Option (IO Unit)          := none

namespace Shiori

/-- 處理器一覽から栞を構築するにゃん -/
def creare (tractatores : List (String × Tractator))
    (onOnerare : Option (String → IO Unit) := none)
    (onExire   : Option (IO Unit)          := none) : IO Shiori := do
  let status ← IO.mkRef ({} : ShioriStatus)
  return { tractatores, status, onOnerare, onExire }

/-- 家ディレクトーリウムを設定するにゃん -/
def statuereDomus (s : Shiori) (domus : String) : IO Unit := do
  s.status.modify (fun st => { st with domus })

/-- 家ディレクトーリウムを取得するにゃん -/
def obtinereDomus (s : Shiori) : IO String := do
  let st ← s.status.get
  return st.domus

/-- 要求を處理して應答を返すにゃん。
    これが栞の心臟部にゃ -/
def tracta (s : Shiori) (rogatio : Rogatio) : IO Responsum := do
  -- NOTIFY の場合、Value は無視されるにゃん
  -- でも處理器は呼ぶにゃ（副作用のために）
  match s.tractatores.lookup rogatio.id with
  | some tractator =>
    -- SakuraScript モナドを實行して文字列を得るにゃん
    let scriptum ← Sakura.currere (tractator rogatio)
    match rogatio.methodus with
    | .get => return Responsum.ok scriptum
    | .notifica => return Responsum.nihil  -- NOTIFY は Value を返さにゃいにゃ
  | none =>
    -- 處理器が見つからにゃかった場合は 204 にゃ
    return Responsum.nihil

/-- 要求文字列を受け取り、應答文字列を返す一氣通貫の處理にゃん -/
def tractaCatenam (s : Shiori) (reqStr : String) : IO String := do
  match Rogatio.parse reqStr with
  | .ok rogatio =>
    let responsum ← s.tracta rogatio
    return responsum.adProtocollum
  | .error _ =>
    return Responsum.malaRogatio.adProtocollum

end Shiori

end UkaLean
