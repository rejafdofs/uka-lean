def main : IO Unit := do
  let stdin ← IO.getStdin
  let stdout ← IO.getStdout
  let b ← stdin.read 1
  if b.size > 0 then
    -- success
    stdout.write b
    stdout.flush
  else
    pure ()
