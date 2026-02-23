-- Main.lean
-- 試驗用實行體にゃん。模擬的に SHIORI/3.0 要求を處理して結果を表示するにゃ
-- DLL にせず手輕に動作確認できるにゃん♪

import UkaLean.Nuculum
import UkaLean.Exemplum

open UkaLean

/-- 模擬要求を構築する補助にゃん -/
def fabricaRogationem (id : String) (ref : List (Nat × String) := []) : String :=
  let caput := "GET SHIORI/3.0" ++ crlf ++
    "Charset: UTF-8" ++ crlf ++
    "Sender: SSP" ++ crlf ++
    s!"ID: {id}" ++ crlf
  let refStr := ref.foldl (fun acc (n, v) =>
    acc ++ s!"Reference{n}: {v}" ++ crlf) ""
  caput ++ refStr ++ crlf

def main : IO Unit := do
  let stdout ← IO.getStdout

  -- 栞を構築するにゃん
  let shiori ← Shiori.creare Exemplum.tractatores
  shiori.statuereDomus "."

  stdout.putStrLn "╔══════════════════════════════════════╗"
  stdout.putStrLn "║   UkaLean 栞 模擬試驗にゃん♪        ║"
  stdout.putStrLn "╚══════════════════════════════════════╝"
  stdout.putStrLn ""

  -- ① OnBoot の試驗にゃん
  stdout.putStrLn "── ① OnBoot ──"
  let resp1 ← shiori.tractaCatenam (fabricaRogationem "OnBoot" [(0, "1")])
  stdout.putStrLn resp1

  -- ② OnClose の試驗にゃん
  stdout.putStrLn "── ② OnClose ──"
  let resp2 ← shiori.tractaCatenam (fabricaRogationem "OnClose")
  stdout.putStrLn resp2

  -- ③ OnMouseDoubleClick（頭を撫でる）の試驗にゃん
  stdout.putStrLn "── ③ OnMouseDoubleClick (Head) ──"
  let resp3 ← shiori.tractaCatenam
    (fabricaRogationem "OnMouseDoubleClick" [(3, "0"), (4, "Head")])
  stdout.putStrLn resp3

  -- ④ OnMouseDoubleClick（顏を觸る）の試驗にゃん
  stdout.putStrLn "── ④ OnMouseDoubleClick (Face) ──"
  let resp4 ← shiori.tractaCatenam
    (fabricaRogationem "OnMouseDoubleClick" [(3, "0"), (4, "Face")])
  stdout.putStrLn resp4

  -- ⑤ 存在しにゃい事象の試驗にゃん
  stdout.putStrLn "── ⑤ 未登錄事象 ──"
  let resp5 ← shiori.tractaCatenam (fabricaRogationem "OnNonExistent")
  stdout.putStrLn resp5

  -- ⑥ SakuraScript モナドの直接試驗にゃん
  stdout.putStrLn "── ⑥ SakuraScript モナド直接試驗 ──"
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
  stdout.putStrLn s!"生成 SakuraScript: {scriptum}"

  stdout.putStrLn ""
  stdout.putStrLn "=== 全試驗完了にゃん♪ ==="
