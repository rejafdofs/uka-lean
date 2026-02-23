-- SampleGhost.Memoria
-- ゴーストのダータ(data)永続化と大域狀態にゃん♪
--
-- 使ひ方:
--   OnBoot で `GhostData.onerare domus` → `ghostState.set data` にゃ
--   OnClose で `ghostState.get` → `data.servare domus` にゃん

import UkaLean

namespace SampleGhost

-- ════════════════════════════════════════════════════
--  ゴーストのダータ構造 (Structura Datorum)
-- ════════════════════════════════════════════════════

/-- ゴーストが記憶するダータにゃん。
    ここにお嬢樣が好きにゃフィールドを追加してにゃ♪ -/
structure GhostData where
  /-- 起動回數にゃ。OnBoot の度に増えるにゃん -/
  visitCount  : Nat    := 0
  /-- 親密度（0〜100）にゃ。撫でたり會話したりで上がるにゃん -/
  affinity    : Nat    := 0
  /-- 最後に保存した言葉にゃ -/
  lastWords   : String := ""
  deriving Repr, Inhabited

-- ════════════════════════════════════════════════════
--  大域狀態 (Status Globalis)
-- ════════════════════════════════════════════════════

/-- 實行中のゴーストの大域狀態にゃん。
    initialize で自動的に作られるにゃ。
    `ghostState.get` で讀み、`ghostState.set` / `ghostState.modify` で書くにゃ♪ -/
initialize ghostState : IO.Ref GhostData ← IO.mkRef {}

-- ════════════════════════════════════════════════════
--  永続化 (Persistentia)
-- ════════════════════════════════════════════════════

private def datNomen : String := "ghost.dat"

/-- Nat を文字列に直す補助にゃん -/
private def natToString (n : Nat) : String := toString n

/-- 文字列を Nat に直す補助にゃん。數字以外は 0 にゃ -/
private def stringToNat (s : String) : Nat :=
  s.trimAscii.toString.foldl (fun acc c =>
    if c.isDigit then acc * 10 + (c.toNat - '0'.toNat) else acc
  ) 0

/-- ダータを key=value 形式の文字列に直すにゃん -/
private def serializare (d : GhostData) : String :=
  s!"visitCount={natToString d.visitCount}\n" ++
  s!"affinity={natToString d.affinity}\n"    ++
  -- lastWords は改行を含む可能性があるにゃ。Base64 等は省いてにゃいから
  -- 一行にゃデータだけ保存するにゃ
  s!"lastWords={d.lastWords}\n"

/-- key=value 形式の文字列からダータを復元するにゃん -/
private def deserializare (s : String) : GhostData :=
  s.splitOn "\n" |>.foldl (fun d line =>
    -- "key=value" を分割にゃ。value が "=" を含む場合に備へて先頭だけ分割するにゃん
    match line.trimAscii.toString.splitOn "=" with
    | []       => d
    | [_]      => d
    | k :: vs  =>
      let v := "=".intercalate vs  -- 値中の "=" を復元するにゃ
      match k.trimAscii.toString with
      | "visitCount" => { d with visitCount := stringToNat v }
      | "affinity"   => { d with affinity   := stringToNat v }
      | "lastWords"  => { d with lastWords  := v }
      | _            => d
  ) {}

/-- ダータをファスキクルスに保存するにゃん（OnClose で呼ぶにゃ）
    domus は UkaLean.domusObtinere で取れるにゃ♪ -/
def GhostData.servare (d : GhostData) (domus : String) : IO Unit := do
  let path : System.FilePath := ⟨domus⟩ / datNomen
  try
    IO.FS.writeFile path (serializare d)
  catch e =>
    -- 書き込みに失敗しても栞は動き續けるにゃん
    IO.eprintln s!"[SampleGhost] ダータ保存に失敗にゃ: {e}"

/-- ファスキクルスからダータを讀み込むにゃん（OnBoot で呼ぶにゃ）
    ファスキクルスが存在しにゃい場合（初回起動）は既定値を返すにゃん♪ -/
def GhostData.onerare (domus : String) : IO GhostData := do
  let path : System.FilePath := ⟨domus⟩ / datNomen
  try
    let s ← IO.FS.readFile path
    return deserializare s
  catch _ =>
    -- ファスキクルスがにゃい = 初回起動にゃ。既定値でよいにゃん
    return {}

end SampleGhost
