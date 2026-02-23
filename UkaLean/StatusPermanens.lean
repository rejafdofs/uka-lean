-- UkaLean.StatusPermanens
-- 永続化（persistentia）の型クラスと補助關數にゃん♪
-- ghost_status.dat への讀み書きを擔ふにゃ

namespace UkaLean

/-- 永続化できる型の型クラスにゃん。
    adCatenam で文字列に變換、eCatena で文字列から復元するにゃ -/
class StatusPermanens (α : Type) where
  /-- 値を文字列に直列化するにゃん -/
  adCatenam : α → String
  /-- 文字列から値を復元するにゃん。失敗したら none を返すにゃ -/
  eCatena   : String → Option α

-- String のインスタンスにゃん（そのまま使ふにゃ）
instance : StatusPermanens String where
  adCatenam s := s
  eCatena   s := some s

-- Nat のインスタンスにゃん
instance : StatusPermanens Nat where
  adCatenam n := toString n
  eCatena   s := s.toNat?

-- Int のインスタンスにゃん
instance : StatusPermanens Int where
  adCatenam n := toString n
  eCatena   s :=
    if s.startsWith "-" then
      -- "-123" → "123" → 123 → -(123) にゃん
      (s.drop 1).toNat?.map (fun n => -(Int.ofNat n))
    else
      s.toNat?.map Int.ofNat

-- Bool のインスタンスにゃん
instance : StatusPermanens Bool where
  adCatenam b := if b then "true" else "false"
  eCatena   s := match s with
    | "true"  => some true
    | "false" => some false
    | _       => none

/-- `{domus}/ghost_status.dat` から 名前=値 の對(pair)を讀み込むにゃん♪
    ファスキクルスが存在しにゃい場合は空の一覽を返すにゃ -/
def legereMappam (via : String) : IO (List (String × String)) := do
  try
    let textus ← IO.FS.readFile via
    -- Windows の \r\n にも對應するにゃん（\r を除去するにゃ）
    let lineae := textus.replace "\r" "" |>.splitOn "\n" |>.filter (· ≠ "")
    let paria := lineae.filterMap fun linea =>
      -- 最初の '=' だけを區切りにするにゃん（値に '=' が含まれてもよいにゃ）
      match linea.splitOn "=" with
      | [] | [_] => none
      | clavis :: rest => some (clavis, String.intercalate "=" rest)
    return paria
  catch _ =>
    -- ファスキクルスが存在しにゃい場合はエッロルを無視するにゃ
    return []

/-- 名前=値 の對(pair)を `{via}` に書き出すにゃん♪ -/
def scribeMappam (via : String) (paria : List (String × String)) : IO Unit := do
  let textus := paria.foldl (fun acc (k, v) => acc ++ k ++ "=" ++ v ++ "\n") ""
  IO.FS.writeFile via textus

/-- 名前→設定器(configurator)の一覽を使って一括復元するにゃん。
    保存ダータに含まれる項目だけを復元するにゃ -/
def executareLecturam
    (paria    : List (String × String))
    (tractores : List (String × (String → IO Unit))) : IO Unit := do
  for (nomen, valor) in paria do
    match tractores.lookup nomen with
    | some actio => actio valor
    | none       => pure ()  -- 知らにゃい名前は無視するにゃ

/-- 名前→取得器(acquisitor)の一覽を使って一括保存するにゃん♪ -/
def executareScripturam
    (tractores : List (String × IO String)) : IO (List (String × String)) := do
  let mut paria : List (String × String) := []
  for (nomen, actio) in tractores do
    let valor ← actio
    paria := paria ++ [(nomen, valor)]
  return paria

end UkaLean
