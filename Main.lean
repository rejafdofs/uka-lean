-- Main.lean
-- 試驗用實行體にゃん。模擬的に SHIORI/3.0 要求を處理して結果を表示するにゃ
-- DLL にせず手輕に動作確認できるにゃん♪

import UkaLean.Nuculum
import UkaLean.Exemplum

open UkaLean

/-- 模擬要求を構築する補助にゃん -/
def fabricaRogationem (nomen : String) (ref : List (Nat × String) := []) : String :=
  let caput := "GET SHIORI/3.0" ++ crlf ++
    "Charset: UTF-8" ++ crlf ++
    "Sender: SSP" ++ crlf ++
    s!"ID: {nomen}" ++ crlf
  let refStr := ref.foldl (fun acc (n, v) =>
    acc ++ s!"Reference{n}: {v}" ++ crlf) ""
  caput ++ refStr ++ crlf

def main : IO Unit := do
  let egressus ← IO.getStdout

  -- 栞を構築するにゃん
  let shiori ← Shiori.creare Exemplum.tractatores
  shiori.statuereDomus "."

  egressus.putStrLn "╔══════════════════════════════════════╗"
  egressus.putStrLn "║   UkaLean 栞 模擬試驗にゃん♪        ║"
  egressus.putStrLn "╚══════════════════════════════════════╝"
  egressus.putStrLn ""

  -- ① OnBoot の試驗にゃん
  egressus.putStrLn "── ① OnBoot ──"
  let responsum1 ← shiori.tractaCatenam (fabricaRogationem "OnBoot" [(0, "1")])
  egressus.putStrLn responsum1

  -- ② OnClose の試驗にゃん
  egressus.putStrLn "── ② OnClose ──"
  let responsum2 ← shiori.tractaCatenam (fabricaRogationem "OnClose")
  egressus.putStrLn responsum2

  -- ③ OnMouseDoubleClick（頭を撫でる）の試驗にゃん
  egressus.putStrLn "── ③ OnMouseDoubleClick (Head) ──"
  let responsum3 ← shiori.tractaCatenam
    (fabricaRogationem "OnMouseDoubleClick" [(3, "0"), (4, "Head")])
  egressus.putStrLn responsum3

  -- ④ OnMouseDoubleClick（顏を觸る）の試驗にゃん
  egressus.putStrLn "── ④ OnMouseDoubleClick (Face) ──"
  let responsum4 ← shiori.tractaCatenam
    (fabricaRogationem "OnMouseDoubleClick" [(3, "0"), (4, "Face")])
  egressus.putStrLn responsum4

  -- ⑤ 存在しにゃい事象の試驗にゃん
  egressus.putStrLn "── ⑤ 未登錄事象 ──"
  let responsum5 ← shiori.tractaCatenam (fabricaRogationem "OnNonExistent")
  egressus.putStrLn responsum5

  -- ⑥ SakuraScript モナドの直接試驗にゃん
  egressus.putStrLn "── ⑥ SakuraScript モナド直接試驗 ──"
  let scriptum ← Sakura.currere do
    Sakura.sakura
    Sakura.superficies 0
    Sakura.loqui "直接試驗にゃん♪"
    Sakura.mora 300
    Sakura.linea
    Sakura.kero
    Sakura.superficies 10
    Sakura.loqui "正しく動いてるにゃ。"
    Sakura.finis
  egressus.putStrLn s!"生成 SakuraScript: {scriptum}"

  egressus.putStrLn ""
  egressus.putStrLn "=== 全試驗完了にゃん♪ ==="
