-- UkaLean.Varia
-- varia 變數のためのアクセス關數（ラテン語名）にゃん♪

namespace IO.Ref

/-- `get` のラテン語名にゃん♪ -/
@[inline] def obtinere {α : Type} (ref : IO.Ref α) : IO α := ref.get

/-- `set` のラテン語名にゃん♪ -/
@[inline] def statuere {α : Type} (ref : IO.Ref α) (v : α) : IO Unit := ref.set v

/-- `modify` のラテン語名にゃん♪ -/
@[inline] def renovare {α : Type} (ref : IO.Ref α) (f : α → α) : IO Unit := ref.modify f

end IO.Ref
