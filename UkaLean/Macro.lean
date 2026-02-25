-- UkaLean.Macro
-- ゴーストDSLマクロにゃん♪
-- varia / eventum / construe の3つのマクロを提供するにゃ
-- 環境拡張 GhostAccumulatio に variae（變數宣言）と eventa（事象宣言）を累積するにゃ

import Lean
import UkaLean.StatusPermanens
import UkaLean.Exporta

open Lean Elab Command

namespace UkaLean

-- ═══════════════════════════════════════════════════
-- 環境拡張の定義にゃん
-- ═══════════════════════════════════════════════════

/-- varia 宣言の情報にゃん -/
structure GhostVarDecl where
  /-- 變數名にゃ（例: `greetCount）-/
  nomen       : Name
  /-- 型の構文木にゃ。永続化の型クラス解決に使ふにゃ -/
  typusSyntax : Syntax
  /-- true なら ghost_status.bin に永続化するにゃん -/
  permanet    : Bool

/-- eventum 宣言の情報にゃん -/
structure GhostEventDecl where
  /-- イベント名にゃ（例: "OnBoot"）-/
  nomen          : String
  /-- 生成した處理器の完全修飾名にゃ -/
  tractatorNomen : Name

/-- ゴーストの累積宣言にゃん。construe 時に全部參照するにゃ -/
structure GhostAccumulatio where
  variae : Array GhostVarDecl   := #[]
  eventa : Array GhostEventDecl := #[]

-- Inhabited インスタンスにゃん♪
instance : Inhabited GhostVarDecl :=
  ⟨{ nomen := .anonymous, typusSyntax := .missing, permanet := false }⟩

instance : Inhabited GhostEventDecl :=
  ⟨{ nomen := "", tractatorNomen := .anonymous }⟩

instance : Inhabited GhostAccumulatio := ⟨{}⟩

/-- 環境拡張の登錄にゃん♪ -/
initialize ghostAccumulatioExt : EnvExtension GhostAccumulatio ←
  registerEnvExtension (pure {})

-- ═══════════════════════════════════════════════════
-- varia マクロにゃん
-- ═══════════════════════════════════════════════════

/-- 永続化變數を宣言するにゃん♪
    `initialize greetCount : IO.Ref Nat ← IO.mkRef 0` を生成して
    ghost_status.bin に保存・復元されるやうにするにゃ -/
elab "varia" "perpetua" n:ident ":" t:term ":=" v:term : command => do
  -- initialize を生成するにゃ
  elabCommand (← `(initialize $n : IO.Ref $t ← IO.mkRef $v))
  -- 環境拡張に登錄するにゃ♪（variae に push するにゃ）
  modifyEnv fun env =>
    ghostAccumulatioExt.modifyState env fun acc =>
      { acc with variae := acc.variae.push {
          nomen := n.getId, typusSyntax := t, permanet := true } }

/-- 一時變數を宣言するにゃん。
    `initialize lastEvent : IO.Ref String ← IO.mkRef ""` を生成するにゃ。
    永続化されにゃいにゃ -/
elab "varia" "temporaria" n:ident ":" t:term ":=" v:term : command => do
  -- initialize を生成するにゃ
  elabCommand (← `(initialize $n : IO.Ref $t ← IO.mkRef $v))
  -- 環境拡張に登錄するにゃ（permanet = false、variae に push するにゃ）
  modifyEnv fun env =>
    ghostAccumulatioExt.modifyState env fun acc =>
      { acc with variae := acc.variae.push {
          nomen := n.getId, typusSyntax := t, permanet := false } }

-- ═══════════════════════════════════════════════════
-- eventum マクロにゃん
-- ═══════════════════════════════════════════════════

/-- 事象處理器を宣言するにゃん♪
    `def _tractator_OnBoot : UkaLean.Tractator := body` を即時生成するにゃ。
    型エッロルはここで檢出されるにゃ -/
elab "eventum" nomenEventi:str body:term : command => do
  let nomen := nomenEventi.getString
  -- _tractator_OnBoot のやうな識別子を作るにゃ
  let nomenBasisTractatorum := "_tractator_" ++ nomen
  let identTractatorum := mkIdent (Name.mkSimple nomenBasisTractatorum)
  -- 處理器を定義するにゃん♪
  elabCommand (← `(def $identTractatorum : UkaLean.Tractator := $body))
  -- 現在の名前空間を加味した完全修飾名にゃ
  let ns ← getCurrNamespace
  let nomenPlenumTractatorum := ns ++ Name.mkSimple nomenBasisTractatorum
  -- 環境拡張に登錄するにゃ（eventa に push するにゃ）
  modifyEnv fun env =>
    ghostAccumulatioExt.modifyState env fun acc =>
      { acc with eventa := acc.eventa.push {
          nomen, tractatorNomen := nomenPlenumTractatorum } }

-- ═══════════════════════════════════════════════════
-- construe マクロにゃん
-- ═══════════════════════════════════════════════════

/-- ゴーストを組み立てて SSP に登錄するにゃん♪
    varia と eventum の宣言を讀み取り、栞を構築・登錄するにゃ。
    永続變數がある場合は讀込・書出フックも自動生成するにゃ。

    **型安全な永続化にゃん♪**
    保存時に `typusTag`（型の文字列識別子）も記録するにゃ。
    復元時はタグが一致した時だけ値を讀み込むにゃ。
    ゴーストの更新で變數の型が變はっても安全にゃん！ -/
elab "construe" : command => do
  let env ← getEnv
  let acc := ghostAccumulatioExt.getState env
  let variaePermanentes := acc.variae.filter (·.permanet)
  let eventa := acc.eventa

  -- tractatores のペアを Syntax として組み立てるにゃ
  -- [("OnBoot", _tractator_OnBoot), ("OnClose", _tractator_OnClose)]
  let pariaTractatorum : Array (TSyntax `term) ← eventa.mapM fun e => do
    let identTractatorum := mkIdent e.tractatorNomen
    let signumNominis : TSyntax `term := ⟨Syntax.mkStrLit e.nomen⟩
    `(($signumNominis, $identTractatorum))

  if variaePermanentes.isEmpty then
    -- 永続化にゃし: シンプレクス(simplex)にゃ registraShiori を使ふにゃ
    elabCommand (← `(
      initialize (UkaLean.registraShiori [$pariaTractatorum,*])
      def main : IO Unit := UkaLean.loopPrincipalis
    ))
  else
    -- 永続化あり: 型タグ付き讀込・書出フックを生成するにゃ♪

    -- 讀込フック(onerare)の要素を生成するにゃ
    -- ("greetCount", fun _tag _s => do
    --   if _tag == StatusPermanens.typusTag (α := Nat) then
    --     if let (some _v : Option Nat) := eBytes _s then greetCount.set _v)
    let elementaOnerandi : Array (TSyntax `term) ← variaePermanentes.mapM fun v => do
      let identVariae := mkIdent v.nomen
      let signumNominis : TSyntax `term := ⟨Syntax.mkStrLit v.nomen.toString⟩
      let syntaxisTypi : TSyntax `term := ⟨v.typusSyntax⟩
      `(($signumNominis, fun _tag _s => do
          -- 型タグが一致した時だけ復元するにゃん♪
          if _tag == UkaLean.StatusPermanens.typusTag (α := $syntaxisTypi) then
            if let (some _v : Option $syntaxisTypi) :=
                UkaLean.StatusPermanens.eBytes _s then
              ($identVariae).set _v))

    -- 書出フック(exire)の要素を生成するにゃ
    -- ("greetCount", do
    --   let _v ← greetCount.get
    --   return (StatusPermanens.typusTag (α := Nat), adBytes _v))
    let elementaServandi : Array (TSyntax `term) ← variaePermanentes.mapM fun v => do
      let identVariae := mkIdent v.nomen
      let signumNominis : TSyntax `term := ⟨Syntax.mkStrLit v.nomen.toString⟩
      let syntaxisTypi : TSyntax `term := ⟨v.typusSyntax⟩
      `(($signumNominis, do
          let _v ← ($identVariae).get
          -- 型タグと直列化バイトの組を返すにゃん♪
          return (UkaLean.StatusPermanens.typusTag (α := $syntaxisTypi),
                  UkaLean.StatusPermanens.adBytes _v)))

    -- terminusTractatorum 等を先に組み立ててから渡すにゃん♪
    let terminusTractatorum ← `([$pariaTractatorum,*])
    let terminusOnerandi    ← `([$elementaOnerandi,*])
    let terminusServandi    ← `([$elementaServandi,*])

    -- 全體を一括生成するにゃん♪
    elabCommand (← `(
      initialize (UkaLean.registraShioriEx
        $terminusTractatorum
        (some (fun _domus => do
          let _via := _domus ++ "/ghost_status.bin"
          try
            let _paria ← UkaLean.legereMappam _via
            UkaLean.executareLecturam _paria $terminusOnerandi
          catch _ => pure ()))
        (some (do
          let _domus ← UkaLean.domusObtinere
          let _via := _domus ++ "/ghost_status.bin"
          let _paria ← UkaLean.executareScripturam $terminusServandi
          UkaLean.scribeMappam _via _paria)))

      def main : IO Unit := UkaLean.loopPrincipalis
    ))

end UkaLean
import UkaLean.Loop
