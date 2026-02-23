-- SampleGhost.Handlers
-- サンプルゴーストの事象處理器にゃん♪
-- お嬢樣はここに處理器を追加していくにゃ

import UkaLean

namespace SampleGhost

open UkaLean Sakura

-- 文字列に部分文字列が含まれるか調べる補助關數にゃん
private def includes (haystack needle : String) : Bool :=
  (haystack.splitOn needle).length > 1

-- ════════════════════════════════════════════════════
--  起動・終了 (Initium et Finis)
-- ════════════════════════════════════════════════════

/-- 起動時にゃん（OnBoot）
    Reference0: 起動理由（"0"=通常, "1"=前回異常終了）-/
def onBoot (r : Rogatio) : SakuraIO Unit := do
  sakura; superficies 0
  match r.ref 0 with
  | some "1" =>
    loqui "あれ……前回ちゃんと終了できにゃかったみたいにゃ。"
    mora 500; linea
    loqui "でも今日は大丈夫にゃん♪"
  | _ =>
    loqui "おはやうにゃん！今日も一緒にゐるにゃ♪"
    mora 300; linea
    kero; superficies 10
    loqui "よろしくお願ひいたします。"
  finis

/-- 初回起動にゃん（OnFirstBoot）-/
def onFirstBoot (_ : Rogatio) : SakuraIO Unit := do
  sakura; superficies 5
  loqui "はじめましてにゃん！"
  mora 600; linea
  loqui "ボクのこと、よろしくにゃ♪"
  mora 800; linea; linea
  kero; superficies 10
  loqui "どうぞ宜しくお願ひいたします。"
  mora 500; linea
  loqui "何かあれば氣軽に聲をかけてにゃん。"
  finis

/-- 終了時にゃん（OnClose）
    Reference0: 終了理由（"0"=通常, "1"=OS 終了）-/
def onClose (r : Rogatio) : SakuraIO Unit := do
  sakura; superficies 3
  match r.ref 0 with
  | some "1" =>
    loqui "OS が終了するにゃ。またにゃん♪"
  | _ =>
    loqui "またにゃー！"
    mora 400; linea
    kero; superficies 14
    loqui "お疲れ樣でした。"
  finis

-- ════════════════════════════════════════════════════
--  マウス操作 (Operationes Muri)
-- ════════════════════════════════════════════════════

/-- 滑鼠二重打鍵にゃん（OnMouseDoubleClick）
    Reference3: 範圍（"0"=主人格, "1"=副人格）
    Reference4: 觸れた部位名 -/
def onMouseDoubleClick (r : Rogatio) : SakuraIO Unit := do
  match r.ref 3, r.ref 4 with
  | some "0", some "Head" =>
    sakura; superficies 5
    loqui "撫でてくれるにゃ？にゃーん♪"
    finis
  | some "0", some "Face" =>
    sakura; superficies 9
    loqui "にゃっ！？ 顏は恥づかしいにゃ……"
    mora 300; linea
    loqui "……でもちょっと嬉しいにゃ。"
    finis
  | some "0", some "Bust" =>
    sakura; superficies 8
    loqui "にゃにゃっ！？ どこ觸ってるのにゃ！"
    finis
  | some "0", some "Stomach" =>
    sakura; superficies 8
    loqui "くすぐったいにゃっ！"
    finis
  | some "0", some "Hand" =>
    sakura; superficies 0
    loqui "手を握ってくれるにゃん♪"
    finis
  | some "1", _ =>
    kero; superficies 10
    loqui "あ……何ですか？"
    finis
  | _, _ =>
    sakura; superficies 0
    loqui "にゃん？"
    finis

/-- 滑鼠一重打鍵にゃん（OnMouseClick）-/
def onMouseClick (r : Rogatio) : SakuraIO Unit := do
  match r.ref 3, r.ref 4 with
  | some "0", some "Head" =>
    sakura; superficies 5
    loqui "にゃ♪"
    finis
  | _, _ => finis

-- ════════════════════════════════════════════════════
--  時刻 (Tempus)
-- ════════════════════════════════════════════════════

/-- 每分の時刻通知にゃん（OnMinuteChange）
    Reference0: 時、Reference1: 分 -/
def onMinuteChange (r : Rogatio) : SakuraIO Unit := do
  -- ★ 具體的にゃケースを先に書くにゃん！
  --   Lean は上から順に照合するから、
  --   some h, some "00" より前に特殊ケースを置くにゃ
  match r.ref 0, r.ref 1 with
  | some "07", some "30" =>
    sakura; superficies 5
    loqui "おはやうにゃん！今日もがんばるにゃ♪"
    finis
  | some "12", some "00" =>
    sakura; superficies 0
    loqui "お昼にゃ！お腹空いたにゃーん。"
    finis
  | some "00", some "00" =>
    sakura; superficies 3
    loqui "もう日付が變はったにゃん。夜更かしはほどほどにゃ。"
    finis
  | some h, some "00" =>
    sakura; superficies 0
    loqui s!"{h}時ちょうどにゃん。"
    finis
  | _, _ => finis

-- ════════════════════════════════════════════════════
--  會話 (Colloquium)
-- ════════════════════════════════════════════════════

/-- 使用者のテキスト入力にゃん（OnCommunicate）
    Reference0: 入力文字列 -/
def onCommunicate (r : Rogatio) : SakuraIO Unit := do
  sakura; superficies 0
  match r.ref 0 with
  | none => finis
  | some input =>
    if includes input "ありがとう" then do
      superficies 4
      loqui "どういたしましてにゃん♪"
      finis
    else if includes input "おはよう" then do
      superficies 5
      loqui "おはやうにゃん！"
      finis
    else if includes input "さようなら" || includes input "バイバイ" then do
      superficies 3
      loqui "またにゃーん♪"
      finis
    else if includes input "にゃ" then do
      superficies 5
      loqui "にゃんにゃん♪ 同じ言葉を使ってくれるにゃん！"
      finis
    else do
      loqui s!"「{input}」にゃん……？ ボクにはよく分からにゃいにゃ。"
      finis

-- ════════════════════════════════════════════════════
--  ゴースト切替 (Mutatio Animae)
-- ════════════════════════════════════════════════════

/-- 他のゴーストへ切り替へる時にゃん（OnGhostChanging）-/
def onGhostChanging (_ : Rogatio) : SakuraIO Unit := do
  sakura; superficies 3
  loqui "いってらっしゃいにゃん。"
  finis

/-- 他のゴーストから戾ってきた時にゃん（OnGhostChanged）
    Reference3: 前のゴースト名 -/
def onGhostChanged (r : Rogatio) : SakuraIO Unit := do
  sakura; superficies 5
  match r.ref 3 with
  | some prev =>
    loqui s!"{prev} から戾ってきたにゃん♪"
    mora 300; linea
    loqui "また一緒にゐるにゃ！"
  | none =>
    loqui "おかへりにゃん♪"
  finis

-- ════════════════════════════════════════════════════
--  選擇肢の例 (Exemplum Optionis)
-- ════════════════════════════════════════════════════

/-- 選擇肢を表示する例にゃん（OnTalkGet）-/
def onTalkGet (_ : Rogatio) : SakuraIO Unit := do
  sakura; superficies 0
  loqui "今日は何をするにゃ？"
  linea; linea
  optio "おしゃべりしたい" "OnTalk"
  linea
  optio "何もしにゃい" "OnNothing"
  finis

/-- 「何もしにゃい」を選んだ時にゃん（OnNothing）-/
def onNothing (_ : Rogatio) : SakuraIO Unit := do
  sakura; superficies 0
  loqui "そっかにゃ。ではのんびりするにゃん♪"
  finis

-- ════════════════════════════════════════════════════
--  處理器一覽 (Index Tractatorum)
-- ════════════════════════════════════════════════════

/-- ゴーストが反應する事象の一覽にゃん。
    ここに (事象名, 處理器關數) の對を追加していくにゃ♪ -/
def tractatores : List (String × UkaLean.Tractator) := [
  ("OnBoot",             onBoot),
  ("OnFirstBoot",        onFirstBoot),
  ("OnClose",            onClose),
  ("OnMouseDoubleClick", onMouseDoubleClick),
  ("OnMouseClick",       onMouseClick),
  ("OnMinuteChange",     onMinuteChange),
  ("OnCommunicate",      onCommunicate),
  ("OnGhostChanging",    onGhostChanging),
  ("OnGhostChanged",     onGhostChanged),
  ("OnTalkGet",          onTalkGet),
  ("OnNothing",          onNothing),
]

end SampleGhost
