import UkaLean
open UkaLean Sakura

varia perpetua numerusSalutationum : Nat := 0

eventum "OnBoot" fun _ => do
  numerusSalutationum.modify (· + 1)
  let numerus ← numerusSalutationum.get
  sakura; superficies 0
  kero; superficies 10
  sakura
  loqui s!"起動 {numerus} 囘目にゃん♪"
  finis

eventum "OnClose" fun _ => do
  sakura; superficies 0
  loqui "またにゃん！"
  finis

construe
