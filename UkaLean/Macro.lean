-- UkaLean.Macro
-- ゴーストDSLマクロにゃん♪
-- ghost_var / ghost_on / build_ghost の3つのマクロを提供するにゃ

import Lean
import UkaLean.StatusPermanens
import UkaLean.Exporta

open Lean Elab Command

namespace UkaLean

-- ═══════════════════════════════════════════════════
-- 環境拡張の定義にゃん
-- ═══════════════════════════════════════════════════

/-- ghost_var 宣言の情報にゃん -/
structure GhostVarDecl where
  /-- 變數名にゃ（例: `greetCount）-/
  nomen       : Name
  /-- 型の構文木にゃ。永続化の型クラス解決に使ふにゃ -/
  typusSyntax : Syntax
  /-- true なら ghost_status.dat に永続化するにゃん -/
  permanet    : Bool

/-- ghost_on 宣言の情報にゃん -/
structure GhostEventDecl where
  /-- イベント名にゃ（例: "OnBoot"）-/
  nomen          : String
  /-- 生成した處理器の完全修飾名にゃ -/
  tractatorNomen : Name

/-- ゴーストの累積宣言にゃん。build_ghost 時に全部參照するにゃ -/
structure GhostAccumulatio where
  vars   : Array GhostVarDecl   := #[]
  events : Array GhostEventDecl := #[]

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
-- ghost_var マクロにゃん
-- ═══════════════════════════════════════════════════

/-- 永続化變數を宣言するにゃん♪
    `initialize greetCount : IO.Ref Nat ← IO.mkRef 0` を生成して
    ghost_status.dat に保存・復元されるやうにするにゃ -/
elab "ghost_var" "persistent" n:ident ":" t:term ":=" v:term : command => do
  -- initialize を生成するにゃ
  elabCommand (← `(initialize $n : IO.Ref $t ← IO.mkRef $v))
  -- 環境拡張に登錄するにゃ♪
  modifyEnv fun env =>
    ghostAccumulatioExt.modifyState env fun acc =>
      { acc with vars := acc.vars.push {
          nomen := n.getId, typusSyntax := t, permanet := true } }

/-- 一時變數を宣言するにゃん。
    `initialize lastEvent : IO.Ref String ← IO.mkRef ""` を生成するにゃ。
    永続化されにゃいにゃ -/
elab "ghost_var" "transient" n:ident ":" t:term ":=" v:term : command => do
  -- initialize を生成するにゃ
  elabCommand (← `(initialize $n : IO.Ref $t ← IO.mkRef $v))
  -- 環境拡張に登錄するにゃ（permanet = false）
  modifyEnv fun env =>
    ghostAccumulatioExt.modifyState env fun acc =>
      { acc with vars := acc.vars.push {
          nomen := n.getId, typusSyntax := t, permanet := false } }

-- ═══════════════════════════════════════════════════
-- ghost_on マクロにゃん
-- ═══════════════════════════════════════════════════

/-- イベント處理器を宣言するにゃん♪
    `def _tractator_OnBoot : UkaLean.Tractator := body` を即時生成するにゃ。
    型エッロルはここで檢出されるにゃ -/
elab "ghost_on" eventName:str body:term : command => do
  let nomen := eventName.getString
  -- _tractator_OnBoot のやうな識別子を作るにゃ
  let tractatorBaseName := "_tractator_" ++ nomen
  let tractatorIdent := mkIdent (Name.mkSimple tractatorBaseName)
  -- 處理器を定義するにゃん♪
  elabCommand (← `(def $tractatorIdent : UkaLean.Tractator := $body))
  -- 現在の名前空間を加味した完全修飾名にゃ
  let ns ← getCurrNamespace
  let tractatorFullName := ns ++ Name.mkSimple tractatorBaseName
  -- 環境拡張に登錄するにゃ
  modifyEnv fun env =>
    ghostAccumulatioExt.modifyState env fun acc =>
      { acc with events := acc.events.push {
          nomen, tractatorNomen := tractatorFullName } }

-- ═══════════════════════════════════════════════════
-- build_ghost マクロにゃん
-- ═══════════════════════════════════════════════════

/-- ゴーストを組み立てて SSP に登錄するにゃん♪
    ghost_var と ghost_on の宣言を讀み取り、栞を構築・登錄するにゃ。
    永続變數がある場合は讀込・書出フックも自動生成するにゃ -/
elab "build_ghost" : command => do
  let env ← getEnv
  let acc := ghostAccumulatioExt.getState env
  let persistentVars := acc.vars.filter (·.permanet)
  let events := acc.events

  -- tractatores のペアを Syntax として組み立てるにゃ
  -- [("OnBoot", _tractator_OnBoot), ("OnClose", _tractator_OnClose)]
  let tractatoresPairs : Array (TSyntax `term) ← events.mapM fun e => do
    let tractatorIdent := mkIdent e.tractatorNomen
    let eventNameLit : TSyntax `term := ⟨Syntax.mkStrLit e.nomen⟩
    `(($eventNameLit, $tractatorIdent))

  if persistentVars.isEmpty then
    -- 永続化なし: シンプルにゃ registraShiori を使ふにゃ
    -- 括弧でくくって initialize のパーサーに正しく渡すにゃ
    elabCommand (← `(
      initialize (UkaLean.registraShiori [$tractatoresPairs,*])
    ))
  else
    -- 永続化あり: 讀込・書出フックを生成するにゃ♪

    -- 讀込フック(onerare)の要素を生成するにゃ
    -- ("greetCount", fun _s => do
    --   if let (some _v : Option Nat) := eCatena _s then greetCount.set _v)
    let loadItems : Array (TSyntax `term) ← persistentVars.mapM fun v => do
      let varIdent := mkIdent v.nomen
      let varNameLit : TSyntax `term := ⟨Syntax.mkStrLit v.nomen.toString⟩
      -- Syntax を TSyntax `term にキャストするにゃ
      let typSyn : TSyntax `term := ⟨v.typusSyntax⟩
      `(($varNameLit, fun _s => do
          if let (some _v : Option $typSyn) :=
              UkaLean.StatusPermanens.eCatena _s then
            -- ドット記法は括弧でくくって確實に展開するにゃ
            ($varIdent).set _v))

    -- 書出フック(exire)の要素を生成するにゃ
    -- ("greetCount", do return adCatenam (← greetCount.get))
    let saveItems : Array (TSyntax `term) ← persistentVars.mapM fun v => do
      let varIdent := mkIdent v.nomen
      let varNameLit : TSyntax `term := ⟨Syntax.mkStrLit v.nomen.toString⟩
      `(($varNameLit, do
          return UkaLean.StatusPermanens.adCatenam (← ($varIdent).get)))

    -- リストを先に term として組み立ててから渡すにゃん♪
    let tractatoresTerm ← `([$tractatoresPairs,*])
    let loadTerm        ← `([$loadItems,*])
    let saveTerm        ← `([$saveItems,*])

    -- 全体を一括生成するにゃん♪
    elabCommand (← `(
      initialize (UkaLean.registraShioriEx
        $tractatoresTerm
        (some (fun _domus => do
          let _via := _domus ++ "/ghost_status.dat"
          try
            let _paria ← UkaLean.legereMappam _via
            UkaLean.executareLecturam _paria $loadTerm
          catch _ => pure ()))
        (some (do
          let _domus ← UkaLean.domusObtinere
          let _via := _domus ++ "/ghost_status.dat"
          let _paria ← UkaLean.executareScripturam $saveTerm
          UkaLean.scribeMappam _via _paria)))
    ))

end UkaLean
