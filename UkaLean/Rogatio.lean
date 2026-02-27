-- UkaLean.Rogatio
-- SHIORI/3.0 要求の構文解析にゃん

import UkaLean.Protocollum

namespace UkaLean

/-- SHIORI/3.0 要求を表す構造體にゃん -/
structure Rogatio where
  /-- 手法: GET または NOTIFY -/
  methodus    : Methodus
  /-- 事象名（例: "OnBoot", "OnMouseDoubleClick"）-/
  nomen       : String
  /-- Reference 頭部の配列。Reference0, Reference1, ... の順にゃ -/
  referentiae : Array String
  /-- 文字符號化形式（既定 "UTF-8"）-/
  forma       : String
  /-- 送信者（Sender 頭部）-/
  mittens     : Option String
  /-- 安全等級（SecurityLevel 頭部）-/
  securitas   : Option String
  /-- 基底事象名（BaseID 頭部）-/
  nomenBasis  : Option String
  /-- 全頭部の生ダータ(data)にゃん -/
  cappitta    : List (String × String)
  deriving Repr, Inhabited

namespace Rogatio

/-- Reference の第 n 番を取得するにゃん -/
def referentiam (r : Rogatio) (n : Nat) : Option String :=
  if h : n < r.referentiae.size then some r.referentiae[n] else none

/-- 任意の頭部を名前で取得するにゃん -/
def caput (r : Rogatio) (clavis : String) : Option String :=
  r.cappitta.lookup clavis

-- ═══════ 構文解析の內部關數群 ═══════

/-- 頭部行 "Key: Value" を分割するにゃん。
    最初の ": " で區切り、値部分に ": " が含まれても大丈夫にゃ -/
private def parseCastellum (s : String) : Option (String × String) :=
  -- ": " で最初に分割するにゃん
  match s.splitOn ": " with
  | [] => none
  | [_] =>
    -- ": " が無い場合、":" だけで試すにゃ
    match s.splitOn ":" with
    | [] => none
    | [_] => none
    | clavis :: cetera =>
      let v := ":".intercalate cetera
      some (clavis, v.trimAscii.toString)
  | clavis :: cetera =>
    -- cetera を再結合（値に ": " が含まれてゐても大丈夫にゃん）
    some (clavis, ": ".intercalate cetera)

/-- 要求行（第1行）を解析: "GET SHIORI/3.0" にゃん -/
private def parseLineaPrima (s : String) : Except String Methodus := do
  let partes := s.splitOn " "
  match partes with
  | [m, v] =>
    if v != shioriVersio then
      .error s!"未對應の版にゃ: {v}"
    else
      match Methodus.exCatena m with
      | some met => .ok met
      | none => .error s!"未知の手法にゃ: {m}"
  | _ => .error s!"不正にゃ要求行にゃ: {s}"

/-- Reference 頭部の番號を取り出す補助にゃん。
    "Reference3" → some 3 -/
private def referentiaIndex (clavis : String) : Option Nat :=
  if clavis.startsWith "Reference" then
    let catena := clavis.drop "Reference".length
    catena.toNat?
  else
    none

/-- 文字列の前後の空白を除去する補助にゃん -/
private def trimma (s : String) : String := s.trimAscii.toString

/-- SHIORI/3.0 要求文字列を完全に解釈するにゃん -/
def interpreta (s : String) : Except String Rogatio := do
  -- CR+LF で行に分割
  let lineae := s.splitOn crlf
  match lineae with
  | [] => .error "空の要求にゃ"
  | prima :: cetera =>
    -- 第1行を解析
    let methodus ← parseLineaPrima (trimma prima)

    -- 頭部を解析するにゃん
    let mut cappitta : List (String × String) := []
    for l in cetera do
      let linea := trimma l
      if linea.isEmpty then break  -- 空行で終了にゃ
      match parseCastellum linea with
      | some parElementum => cappitta := parElementum :: cappitta
      | none => pure ()  -- 解析できにゃい行は無視にゃ
    cappitta := cappitta.reverse

    -- 既知の頭部を抽出するにゃん
    let nomen := match cappitta.lookup "ID" with
      | some v => v
      | none => ""

    let forma      := (cappitta.lookup "Charset").getD "UTF-8"
    let mittens    := cappitta.lookup "Sender"
    let securitas  := cappitta.lookup "SecurityLevel"
    let nomenBasis := cappitta.lookup "BaseID"

    -- Reference 頭部を收集するにゃん
    let mut maximumIndex : Nat := 0
    let mut pariaNumerata : Array (Nat × String) := #[]
    for (k, v) in cappitta do
      match referentiaIndex k with
      | some n =>
        pariaNumerata := pariaNumerata.push (n, v)
        if n + 1 > maximumIndex then maximumIndex := n + 1
      | none => pure ()

    -- 配列を構築するにゃん
    let mut referentiae := Array.mkArray maximumIndex ""
    for (n, v) in pariaNumerata do
      if h : n < referentiae.size then
        referentiae := referentiae.set n v

    return {
      methodus
      nomen
      referentiae
      forma
      mittens
      securitas
      nomenBasis
      cappitta
    }

end Rogatio

end UkaLean
