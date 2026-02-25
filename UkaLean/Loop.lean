-- UkaLean.Loop
-- ゴースト本體（ghost.exe）として標準入出力で中繼器と通信する小循環（loop）にゃん。

import UkaLean.Exporta

namespace UkaLean

/-- ログ出力用（depurgatio）關數にゃん。現在は無效化（inactivatus）してゐるにゃ -/
def registrareVestigium (_nuntius : String) : IO Unit := do
  return ()
  -- let domus := "C:\\Users\\a\\ghost_lean_trace.txt"
  -- let scriptor ← IO.FS.Handle.mk domus IO.FS.Mode.append
  -- scriptor.putStrLn _nuntius
  -- scriptor.flush

/-- リトルエンディアン 4バイトを發信（出力）するにゃん -/
def egressusU32 (rivusEgressus : IO.FS.Stream) (numerus : UInt32) : IO Unit := do
  let series : ByteArray := ⟨#[
    (numerus &&& 0xFF).toUInt8,
    ((numerus >>> 8) &&& 0xFF).toUInt8,
    ((numerus >>> 16) &&& 0xFF).toUInt8,
    ((numerus >>> 24) &&& 0xFF).toUInt8
  ]⟩
  rivusEgressus.write series

/-- リトルエンディアン 4バイトを讀信するにゃん。
    讀めなかつた場合は 0 を返すにゃ -/
def ingressusU32 (rivusIngressus : IO.FS.Stream) : IO UInt32 := do
  let o ← rivusIngressus.read 4
  if o.size < 4 then return 0
  let o0 := o[0]!.toUInt32
  let o1 := o[1]!.toUInt32
  let o2 := o[2]!.toUInt32
  let o3 := o[3]!.toUInt32
  let numerus := o0 ||| (o1 <<< 8) ||| (o2 <<< 16) ||| (o3 <<< 24)
  return numerus

/-- 指定されたバイト數を完全に讀み切る遞歸關數にゃん -/
partial def ingressusExactus (rivusIngressus : IO.FS.Stream) (magnitudo : Nat) (accumulatum : ByteArray := ByteArray.empty) : IO ByteArray := do
  if accumulatum.size >= magnitudo then
    return accumulatum
  let reliquum := magnitudo - accumulatum.size
  let o ← rivusIngressus.read reliquum.toUSize
  if o.size == 0 then
    -- EOF か讀取エラーにゃ
    return accumulatum
  ingressusExactus rivusIngressus magnitudo (accumulatum ++ o)

/-- 要求を讀取つて應答を返す中繼循環（loop）にゃん。
    Rust 側の procurator32_host.exe の代はりを完全に機能させるにゃ！
    - コマンド 1: LOAD (路徑讀取＋初期化後 [1] を返す)
    - コマンド 2: UNLOAD (終了後 [1] を返してループ拔ける)
    - コマンド 3: REQUEST (要求讀取＋長さと應答を返す) -/
@[export uka_lean_loop_principalis]
partial def loopPrincipalis : IO Unit := do
  let rivusIngressus ← IO.getStdin
  let rivusEgressus ← IO.getStdout

  -- コマンドを表す1バイトを讀むにゃん
  let mandatum ← rivusIngressus.read 1
  if mandatum.size < 1 then
    return () -- EOF にゃ

  let m := mandatum[0]!
  if m == 1 then
    -- LOAD 命令にゃん: [1u8] [4bytes:len] [bytes:path] -> [1u8] を返すにゃ
    let longitudoViae ← ingressusU32 rivusIngressus
    if longitudoViae == 0 then
      registrareVestigium "[PERNICIES] longitudoViae est 0"
      return ()
    let octetiViae ← ingressusExactus rivusIngressus longitudoViae.toNat
    let catenaViae := String.fromUTF8! octetiViae
    registrareVestigium s!"[LOAD] via={catenaViae}, len={longitudoViae}"
    -- UkaLean 全域側の Load 處理を喚ぶにゃ
    let resSecunda ← UkaLean.exportaLoad catenaViae
    rivusEgressus.write ⟨#[resSecunda.toUInt8]⟩
    rivusEgressus.flush
    loopPrincipalis

  else if m == 2 then
    -- UNLOAD 命令にゃん: [2u8] -> 拔けるにゃ
    registrareVestigium "[UNLOAD] vocatus"
    let _ ← UkaLean.exportaUnload
    registrareVestigium "[UNLOAD] perfectus"
    return ()

  else if m == 3 then
    -- REQUEST 命令にゃん: [3u8] [4bytes:len] [bytes:req] -> [4bytes:len] [bytes:res] を返すにゃ
    let longitudoRogationis ← ingressusU32 rivusIngressus
    if longitudoRogationis == 0 then
      registrareVestigium "[PERNICIES] longitudoRogationis est 0"
      return ()
    registrareVestigium s!"[REQUEST] longitudoRogationis={longitudoRogationis}"
    let octetiRogationis ← ingressusExactus rivusIngressus longitudoRogationis.toNat
    if octetiRogationis.size.toUInt32 < longitudoRogationis then
      registrareVestigium s!"[PERNICIES] parum lectum! expectatum {longitudoRogationis}, obtentum {octetiRogationis.size}"

    let catenaRogationis := String.fromUTF8! octetiRogationis

    -- UkaLean 全域側の Request 處理を喚ぶにゃん♪
    let catenaResponsi ← UkaLean.exportaRequest catenaRogationis
    let octetiResponsi := catenaResponsi.toUTF8
    registrareVestigium s!"[REQUEST] PERFECTUM, magnitudoResponsi={octetiResponsi.size}"

    egressusU32 rivusEgressus octetiResponsi.size.toUInt32
    rivusEgressus.write octetiResponsi
    rivusEgressus.flush
    loopPrincipalis

  else
    -- 未知のコマンド、ひとまづ無視して繼續するにゃん
    registrareVestigium s!"[IGNOTUM] mandatum: {m}"
    loopPrincipalis

end UkaLean
