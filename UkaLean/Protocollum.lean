-- UkaLean.Protocollum
-- SHIORI/3.0 プロトコッルムの共通型と定數にゃん

namespace UkaLean

/-- SHIORI 要求の手法(methodus)にゃん。GET は應答を期待し、NOTIFY は通知のみにゃ -/
inductive Methodus where
  | get      -- GET: SakuraScript 等の Value を期待
  | notifica -- NOTIFY: 應答不要（Value を返しても無視される）
  deriving Repr, BEq, Inhabited

namespace Methodus

/-- 文字列に變換するにゃん -/
def adCatenam : Methodus → String
  | .get => "GET"
  | .notifica => "NOTIFY"

/-- 文字列から構文解析するにゃん -/
def exCatena (s : String) : Option Methodus :=
  match s with
  | "GET" => some .get
  | "NOTIFY" => some .notifica
  | _ => none

end Methodus

/-- SHIORI プロトコッルムの版にゃん -/
def shioriVersio : String := "SHIORI/3.0"

/-- 應答の狀態符號にゃ -/
inductive StatusCodis where
  | ok          -- 200 OK
  | noContent   -- 204 No Content
  | badRequest  -- 400 Bad Request
  | serverError -- 500 Internal Server Error
  deriving Repr, BEq

namespace StatusCodis

def adNumerum : StatusCodis → Nat
  | .ok => 200
  | .noContent => 204
  | .badRequest => 400
  | .serverError => 500

def adCatenam : StatusCodis → String
  | .ok => "OK"
  | .noContent => "No Content"
  | .badRequest => "Bad Request"
  | .serverError => "Internal Server Error"

/-- 狀態行の完全にゃ文字列表現にゃん -/
def lineaStatus (sc : StatusCodis) : String :=
  s!"{shioriVersio} {sc.adNumerum} {sc.adCatenam}"

end StatusCodis

/-- 行末の CR+LF にゃん -/
def crlf : String := "\r\n"

end UkaLean
