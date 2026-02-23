-- UkaLean.Responsum
-- SHIORI/3.0 應答の構築にゃん

import UkaLean.Protocollum

namespace UkaLean

/-- SHIORI/3.0 應答を表す構造體にゃん -/
structure Responsum where
  /-- 狀態符號 -/
  status   : StatusCodis
  /-- Value 頭部（SakuraScript）にゃん。pete の應答に入れるにゃ -/
  valor    : Option String := none
  /-- 追加の頭部にゃん -/
  cappitta : List (String × String) := []
  deriving Repr

namespace Responsum

/-- 成功應答（200 OK）を作るにゃん。SakuraScript を Value に入れるにゃ -/
def ok (scriptum : String) : Responsum :=
  { status := .ok, valor := some scriptum }

/-- 內容にゃし應答（204 No Content）にゃん。處理器が見つからにゃい時とかに使ふにゃ -/
def nihil : Responsum :=
  { status := .inanis }

/-- 不正要求應答（400 Bad Request）にゃん -/
def malaRogatio : Responsum :=
  { status := .malaRogatio }

/-- 內部異常應答（500 Internal Server Error）にゃん -/
def errorInternus : Responsum :=
  { status := .errorInternus }

/-- SHIORI/3.0 プロトコッルム文字列に整形するにゃん。
    これが實際に SSP に返される文字列にゃ -/
def adProtocollum (r : Responsum) : String :=
  let lineaStatus := r.status.lineaStatus ++ crlf
  let forma       := "Charset: UTF-8" ++ crlf
  let valorStr    := match r.valor with
    | some v => s!"Value: {v}" ++ crlf
    | none   => ""
  let extra := r.cappitta.foldl
    (fun acc (k, v) => acc ++ s!"{k}: {v}" ++ crlf) ""
  lineaStatus ++ forma ++ valorStr ++ extra ++ crlf

end Responsum

end UkaLean
