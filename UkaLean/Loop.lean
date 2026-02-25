-- UkaLean.Loop
-- ゴースト本體（ghost.exe）として標準入出力で中繼器と通信する小循環（loop）にゃん。

import UkaLean.Exporta

namespace UkaLean

/-- リトルエンディアン 4バイトを發信（出力）するにゃん -/
def egressusU32 (stdout : IO.FS.Stream) (n : UInt32) : IO Unit := do
  let array : ByteArray := ⟨#[
    (n &&& 0xFF).toUInt8,
    ((n >>> 8) &&& 0xFF).toUInt8,
    ((n >>> 16) &&& 0xFF).toUInt8,
    ((n >>> 24) &&& 0xFF).toUInt8
  ]⟩
  stdout.write array

/-- リトルエンディアン 4バイトを讀信するにゃん。
    讀めなかつた場合は 0 を返すにゃ -/
def ingressusU32 (stdin : IO.FS.Stream) : IO UInt32 := do
  let b ← stdin.read 4
  if b.size < 4 then return 0
  let b0 := b[0]!.toUInt32
  let b1 := b[1]!.toUInt32
  let b2 := b[2]!.toUInt32
  let b3 := b[3]!.toUInt32
  return b0 ||| (b1 <<< 8) ||| (b2 <<< 16) ||| (b3 <<< 24)

/-- 要求を讀取つて應答を返す中繼循環（loop）にゃん。
    Rust 側の proxy32_host.exe の代はりを完全に機能させるにゃ！
    - コマンド 1: LOAD (路徑讀取＋初期化後 [1] を返す)
    - コマンド 2: UNLOAD (終了後 [1] を返してループ拔ける)
    - コマンド 3: REQUEST (要求讀取＋長さと應答を返す) -/
unsafe def loopPrincipalis : IO Unit := do
  let stdin ← IO.getStdin
  let stdout ← IO.getStdout

  -- コマンドを表す1バイトを讀むにゃん
  let mandatum ← stdin.read 1
  if mandatum.size < 1 then
    return () -- EOF にゃ

  let m := mandatum[0]!
  if m == 1 then
    -- LOAD 命令にゃん: [1u8] [4bytes:len] [bytes:path] -> [1u8] を返すにゃ
    let viaLen ← ingressusU32 stdin
    if viaLen == 0 then return ()
    let viaBytes ← stdin.read viaLen.toUSize
    let viaStr := String.fromUTF8! viaBytes
    -- UkaLean 全域側の Load 處理を喚ぶにゃ
    let success ← UkaLean.exportaLoad viaStr
    stdout.write ⟨#[success.toUInt8]⟩
    stdout.flush
    loopPrincipalis

  else if m == 2 then
    -- UNLOAD 命令にゃん: [2u8] -> 拔けるにゃ
    let _ ← UkaLean.exportaUnload
    return ()

  else if m == 3 then
    -- REQUEST 命令にゃん: [3u8] [4bytes:len] [bytes:req] -> [4bytes:len] [bytes:res] を返すにゃ
    let reqLen ← ingressusU32 stdin
    if reqLen == 0 then return ()
    let reqBytes ← stdin.read reqLen.toUSize
    let reqStr := String.fromUTF8! reqBytes

    -- UkaLean 全域側の Request 處理を喚ぶにゃん♪
    let resStr ← UkaLean.exportaRequest reqStr
    let resBytes := resStr.toUTF8

    egressusU32 stdout resBytes.size.toUInt32
    stdout.write resBytes
    stdout.flush
    loopPrincipalis

  else
    -- 未知のコマンド、ひとまづ無視して繼續するにゃん
    loopPrincipalis

end UkaLean
