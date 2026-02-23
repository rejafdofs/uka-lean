-- UkaLean.Exemplum
-- 使用例にゃん♪ お嬢樣はこんな風に處理器を書くにゃ

import UkaLean.Nuculum

namespace UkaLean.Exemplum

open UkaLean Sakura

/-- ゴースト起動時の處理にゃん -/
def onBoot (_ : Rogatio) : SakuraIO Unit := do
  sakura; superficies 0
  loqui "やあ、起動したにゃん！"
  mora 500
  linea
  kero; superficies 10
  loqui "いらっしゃいませ。"
  finis

/-- 初回起動の處理にゃん -/
def onFirstBoot (_ : Rogatio) : SakuraIO Unit := do
  sakura; superficies 5
  loqui "はじめましてにゃん！"
  linea
  loqui "ボクのこと、よろしくにゃ♪"
  mora 800
  linea
  kero; superficies 10
  loqui "どうぞ宜しくお願ひいたします。"
  finis

/-- ゴースト終了時の處理にゃん -/
def onClose (_ : Rogatio) : SakuraIO Unit := do
  sakura; superficies 3
  loqui "またにゃー！"
  mora 500
  linea
  kero; superficies 14
  loqui "お疲れ樣でした。"
  finis

/-- 滑鼠二重打鍵の處理にゃん。Reference4 に觸られた部位名が入るにゃ -/
def onMouseDoubleClick (r : Rogatio) : SakuraIO Unit := do
  -- Reference3 = 觸られたスコープ(scopus)
  -- Reference4 = 觸られた部位名
  match r.ref 4 with
  | some "Head" =>
    sakura; superficies 5
    loqui "撫でてくれるのにゃ？嬉しいにゃん♪"
  | some "Face" =>
    sakura; superficies 9
    loqui "にゃっ！？ 顏は恥づかしいにゃ…"
  | some "Bust" =>
    sakura; superficies 8
    loqui "にゃにゃっ！？ 何するのにゃ！"
  | _ =>
    sakura; superficies 0
    loqui "なでなでにゃん"
  finis

/-- 每分の時刻通知にゃん -/
def onMinuteChange (r : Rogatio) : SakuraIO Unit := do
  -- Reference0 = 時, Reference1 = 分
  match r.ref 0, r.ref 1 with
  | some hour, some "00" =>
    sakura; superficies 0
    loqui s!"{hour}時ちょうどにゃん♪"
    finis
  | _, _ =>
    -- 每分は何も喋らにゃいにゃ
    finis

/-- 選擇肢を表示する例にゃん -/
def onBoot2 (_ : Rogatio) : SakuraIO Unit := do
  sakura; superficies 0
  loqui "何をするにゃ？"
  linea; linea
  optio "お喋りする" "OnTalk"
  linea
  optio "撫でる" "OnNaderu"
  linea
  optio "さよなら" "OnClose"
  finis

/-- お嬢樣の處理器一覽にゃん -/
def tractatores : List (String × Tractator) := [
  ("OnBoot",             onBoot),
  ("OnFirstBoot",        onFirstBoot),
  ("OnClose",            onClose),
  ("OnMouseDoubleClick", onMouseDoubleClick),
  ("OnMinuteChange",     onMinuteChange)
]

end UkaLean.Exemplum
