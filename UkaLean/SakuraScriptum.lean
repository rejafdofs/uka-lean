-- UkaLean.SakuraScriptum
-- ★ SakuraScript モナド DSL にゃん♪
-- do 記法で型安全に SakuraScript を組み立てられるにゃ

namespace UkaLean

/-- SakuraScript 構築モナドにゃん。
    文字列を蓄積する StateT で、基底モナド m を自由に選べるにゃ。
    純粹にゃ構築には `SakuraPura`、IO が要る時は `SakuraIO` を使ふにゃん -/
abbrev SakuraM (m : Type → Type) [Monad m] (α : Type) :=
  StateT String m α

/-- IO 附き SakuraScript モナドにゃん。お嬢樣の處理器はこれを使ふにゃ -/
abbrev SakuraIO (α : Type) := SakuraM IO α

/-- 純粹 SakuraScript モナドにゃん。副作用が要らにゃい時に使ふにゃ -/
abbrev SakuraPura (α : Type) := SakuraM Id α

namespace Sakura

-- ════════════════════════════════════════════════════
--  基底操作 (Operationes Fundamentales)
-- ════════════════════════════════════════════════════

/-- SakuraScript の斷片を發出するにゃん。
    これが全ての土臺にゃ -/
def emitte {m : Type → Type} [Monad m] (s : String) : SakuraM m Unit :=
  modify (· ++ s)

/-- 文字列中の特殊文字（\\、%、]）を全て遁走して表示用に安全にゃ形にするにゃん。
    loqui 等の表示系關數はこれを通すから、お嬢樣は氣にしにゃくていいにゃ♪ -/
def evadeTextus (s : String) : String :=
  s.foldl (fun acc c =>
    match c with
    | '\\' => acc ++ "\\\\"
    | '%'  => acc ++ "\\%"
    | ']'  => acc ++ "\\]"
    | _    => acc.push c
  ) ""

/-- 文字列を表示するにゃん。
    \\、%、] の特殊文字は自動的に遁走されるにゃ。
    生の SakuraScript を發出したい時は `crudus` を使ふにゃん -/
def loqui {m : Type → Type} [Monad m] (s : String) : SakuraM m Unit :=
  emitte (evadeTextus s)

-- ════════════════════════════════════════════════════
--  範圍制御 (Imperium Scopi) — 誰が喋るか
-- ════════════════════════════════════════════════════

/-- 主人格（\\h / \\0）に切り替へるにゃん -/
def sakura {m : Type → Type} [Monad m] : SakuraM m Unit := emitte "\\h"

/-- 副人格（\\u / \\1）に切り替へるにゃん -/
def kero {m : Type → Type} [Monad m] : SakuraM m Unit := emitte "\\u"

/-- 第 n 人格（\\p[n]）に切り替へるにゃん -/
def persona {m : Type → Type} [Monad m] (n : Nat) : SakuraM m Unit :=
  emitte s!"\\p[{n}]"

-- ════════════════════════════════════════════════════
--  表面制御 (Imperium Superficiei) — 表情
-- ════════════════════════════════════════════════════

/-- 表面 ID を設定する（\\s[n]）にゃん -/
def superficies {m : Type → Type} [Monad m] (n : Nat) : SakuraM m Unit :=
  emitte s!"\\s[{n}]"

/-- 表面 動畫を再生する（\\i[n]）にゃん -/
def animatio {m : Type → Type} [Monad m] (n : Nat) : SakuraM m Unit :=
  emitte s!"\\i[{n}]"

-- ════════════════════════════════════════════════════
--  文字表示 (Exhibitio Textus)
-- ════════════════════════════════════════════════════

/-- 改行（\\n）にゃん -/
def linea {m : Type → Type} [Monad m] : SakuraM m Unit := emitte "\\n"

/-- 半改行（\\n[half]）にゃん -/
def dimidiaLinea {m : Type → Type} [Monad m] : SakuraM m Unit :=
  emitte "\\n[half]"

/-- 吹出しの文字を淸掃する（\\c）にゃん -/
def purga {m : Type → Type} [Monad m] : SakuraM m Unit := emitte "\\c"

/-- 前の吹出しに追記する（\\C）にゃん -/
def adscribe {m : Type → Type} [Monad m] : SakuraM m Unit := emitte "\\C"

/-- カーソル位置を指定する（\\_l[x,y]）にゃん -/
def cursor {m : Type → Type} [Monad m] (x y : String) : SakuraM m Unit :=
  emitte s!"\\_l[{evadeTextus x},{evadeTextus y}]"

-- ════════════════════════════════════════════════════
--  待機 (Mora) — テンポ制御
-- ════════════════════════════════════════════════════

/-- ミリ秒待機（\\_w[ms]）にゃん -/
def mora {m : Type → Type} [Monad m] (ms : Nat) : SakuraM m Unit :=
  emitte s!"\\_w[{ms}]"

/-- 簡易待機（\\w[1-9]、50ms × n）にゃん -/
def moraCeler {m : Type → Type} [Monad m] (n : Nat) : SakuraM m Unit :=
  emitte s!"\\w{n}"

/-- 絕對時間待機（\\__w[ms]）にゃん -/
def moraAbsoluta {m : Type → Type} [Monad m] (ms : Nat) : SakuraM m Unit :=
  emitte s!"\\__w[{ms}]"

/-- 打鍵待ち（\\x）にゃん -/
def expecta {m : Type → Type} [Monad m] : SakuraM m Unit := emitte "\\x"

/-- 打鍵待ち・淸掃にゃし（\\x[noclear]）にゃん -/
def expectaSine {m : Type → Type} [Monad m] : SakuraM m Unit :=
  emitte "\\x[noclear]"

/-- 時間制約區劃（\\t）にゃん -/
def tempusCriticum {m : Type → Type} [Monad m] : SakuraM m Unit :=
  emitte "\\t"

-- ════════════════════════════════════════════════════
--  選擇肢 (Optiones) — 使用者の選擇
-- ════════════════════════════════════════════════════

/-- 選擇肢を追加する（\\q[表題,識別子]）にゃん。
    表題(titulus)や識別子の特殊文字は自動的に遁走されるにゃ -/
def optio {m : Type → Type} [Monad m] (titulus signum : String) : SakuraM m Unit :=
  emitte s!"\\q[{evadeTextus titulus},{evadeTextus signum}]"

/-- 事象附き選擇肢（\\q[表題,OnEvent,ref0,ref1,...]）にゃん。
    表題(titulus)や事象の特殊文字は自動的に遁走されるにゃ -/
def optioEventum {m : Type → Type} [Monad m]
    (titulus eventum : String) (citationes : List String := []) : SakuraM m Unit :=
  let catenaCitationis := match citationes with
    | [] => ""
    | res => "," ++ ",".intercalate (res.map evadeTextus)
  emitte s!"\\q[{evadeTextus titulus},{evadeTextus eventum}{catenaCitationis}]"

/-- 錨（\\_a[id]...テキスト...\\_a）にゃん。
    閉ぢる時は `fineAncora` を呼ぶにゃ -/
def ancora {m : Type → Type} [Monad m] (id : String) : SakuraM m Unit :=
  emitte s!"\\_a[{evadeTextus id}]"

/-- 錨を閉ぢる（\\_a）にゃん -/
def fineAncora {m : Type → Type} [Monad m] : SakuraM m Unit :=
  emitte "\\_a"

/-- 選擇肢の時間制限を設定する（\\![set,choicetimeout,ms]）にゃん -/
def tempusOptionum {m : Type → Type} [Monad m] (ms : Nat) : SakuraM m Unit :=
  emitte s!"\\![set,choicetimeout,{ms}]"

/-- 時間切れ防止（\\*）にゃん -/
def prohibeTempus {m : Type → Type} [Monad m] : SakuraM m Unit :=
  emitte "\\*"

-- ════════════════════════════════════════════════════
--  制御 (Imperium)
-- ════════════════════════════════════════════════════

/-- スクリプト終了（\\e）にゃん。全ての SakuraScript の末尾に必ず置くにゃ -/
def finis {m : Type → Type} [Monad m] : SakuraM m Unit := emitte "\\e"

/-- 即時表示切替（\\_q）にゃん -/
def celer {m : Type → Type} [Monad m] : SakuraM m Unit := emitte "\\_q"

/-- ゴースト退出（\\-）にゃん -/
def exitus {m : Type → Type} [Monad m] : SakuraM m Unit := emitte "\\-"

/-- 同期區劃切替（\\_s）にゃん -/
def synchrona {m : Type → Type} [Monad m] : SakuraM m Unit := emitte "\\_s"

/-- 隨機ゴースト切替（\\+）にゃん -/
def mutaGhost {m : Type → Type} [Monad m] : SakuraM m Unit := emitte "\\+"

-- ════════════════════════════════════════════════════
--  書體 (Forma Litterarum)
-- ════════════════════════════════════════════════════

/-- 太字の切替（\\f[bold,b]）にゃん -/
def audax {m : Type → Type} [Monad m] (b : Bool := true) : SakuraM m Unit :=
  emitte s!"\\f[bold,{if b then "true" else "false"}]"

/-- 斜體の切替（\\f[italic,b]）にゃん -/
def obliquus {m : Type → Type} [Monad m] (b : Bool := true) : SakuraM m Unit :=
  emitte s!"\\f[italic,{if b then "true" else "false"}]"

/-- 下線の切替（\\f[underline,b]）にゃん -/
def sublinea {m : Type → Type} [Monad m] (b : Bool := true) : SakuraM m Unit :=
  emitte s!"\\f[underline,{if b then "true" else "false"}]"

/-- 取消線の切替（\\f[strike,b]）にゃん -/
def deletura {m : Type → Type} [Monad m] (b : Bool := true) : SakuraM m Unit :=
  emitte s!"\\f[strike,{if b then "true" else "false"}]"

/-- 文字色の設定（\\f[color,r,g,b]）にゃん -/
def color {m : Type → Type} [Monad m] (r g b : Nat) : SakuraM m Unit :=
  emitte s!"\\f[color,{r},{g},{b}]"

/-- 文字の大きさ（\\f[height,n]）にゃん -/
def altitudoLitterarum {m : Type → Type} [Monad m] (n : Nat) : SakuraM m Unit :=
  emitte s!"\\f[height,{n}]"

/-- 書體名の設定（\\f[name,font]）にゃん -/
def nomenFontis {m : Type → Type} [Monad m] (nomen : String) : SakuraM m Unit :=
  emitte s!"\\f[name,{evadeTextus nomen}]"

/-- 文字揃へ（\\f[align,方向]）にゃん -/
def allineatio {m : Type → Type} [Monad m] (directio : String) : SakuraM m Unit :=
  emitte s!"\\f[align,{evadeTextus directio}]"

/-- 書式を既定に戾す（\\f[default]）にゃん -/
def formaPraefinita {m : Type → Type} [Monad m] : SakuraM m Unit :=
  emitte "\\f[default]"

-- ════════════════════════════════════════════════════
--  吹出し (Bulla)
-- ════════════════════════════════════════════════════

/-- 吹出し ID を變更する（\\b[n]）にゃん -/
def bulla {m : Type → Type} [Monad m] (n : Nat) : SakuraM m Unit :=
  emitte s!"\\b[{n}]"

/-- 吹出しに畫像を重ねる（\\_b[path,x,y]）にゃん -/
def imagoBullae {m : Type → Type} [Monad m]
    (via : String) (x y : Nat) : SakuraM m Unit :=
  emitte s!"\\_b[{evadeTextus via},{x},{y}]"

-- ════════════════════════════════════════════════════
--  音聲 (Sonus)
-- ════════════════════════════════════════════════════

/-- 音聲を再生する（\\_v[file]）にゃん -/
def sonus {m : Type → Type} [Monad m] (via : String) : SakuraM m Unit :=
  emitte s!"\\_v[{evadeTextus via}]"

/-- 音聲の終了を待つ（\\_V）にゃん -/
def expectaSonum {m : Type → Type} [Monad m] : SakuraM m Unit :=
  emitte "\\_V"

-- ════════════════════════════════════════════════════
--  事象 (Eventum)
-- ════════════════════════════════════════════════════

/-- 事象を發生させる（\\![raise,event,r0,...]）にゃん -/
def excita {m : Type → Type} [Monad m]
    (eventum : String) (citationes : List String := []) : SakuraM m Unit :=
  let catenaCitationis := match citationes with
    | [] => ""
    | res => "," ++ ",".intercalate (res.map evadeTextus)
  emitte s!"\\![raise,{evadeTextus eventum}{catenaCitationis}]"

/-- 事象の結果をその場に埋め込む（\\![embed,event,r0,...]）にゃん -/
def insere {m : Type → Type} [Monad m]
    (eventum : String) (citationes : List String := []) : SakuraM m Unit :=
  let catenaCitationis := match citationes with
    | [] => ""
    | res => "," ++ ",".intercalate (res.map evadeTextus)
  emitte s!"\\![embed,{evadeTextus eventum}{catenaCitationis}]"

/-- 通知事象（\\![notify,event,r0,...]）にゃん -/
def notifica {m : Type → Type} [Monad m]
    (eventum : String) (citationes : List String := []) : SakuraM m Unit :=
  let catenaCitationis := match citationes with
    | [] => ""
    | res => "," ++ ",".intercalate (res.map evadeTextus)
  emitte s!"\\![notify,{evadeTextus eventum}{catenaCitationis}]"

-- ════════════════════════════════════════════════════
--  窓制御 (Imperium Fenestrae)
-- ════════════════════════════════════════════════════

/-- 近づく（\\5）にゃん -/
def accede {m : Type → Type} [Monad m] : SakuraM m Unit := emitte "\\5"

/-- 離れる（\\4）にゃん -/
def recede {m : Type → Type} [Monad m] : SakuraM m Unit := emitte "\\4"

-- ════════════════════════════════════════════════════
--  雜多 (Varia)
-- ════════════════════════════════════════════════════

/-- URL やファスキクルスを開く（\\j[url]）にゃん -/
def aperi {m : Type → Type} [Monad m] (nexus : String) : SakuraM m Unit :=
  emitte s!"\\j[{evadeTextus nexus}]"

/-- 特殊文字の遁走(escape)にゃん -/
def evade {m : Type → Type} [Monad m] (c : Char) : SakuraM m Unit :=
  match c with
  | '\\' => emitte "\\\\"
  | '%'  => emitte "\\%"
  | ']'  => emitte "\\]"
  | _    => emitte (String.ofList [c])

/-- 任意の SakuraScript 標籤を直接發出する（高度にゃ使用向け）にゃん -/
def crudus {m : Type → Type} [Monad m] (signum : String) : SakuraM m Unit :=
  emitte signum

-- ════════════════════════════════════════════════════
--  便利にゃ組合せ (Combinationes Utiles)
-- ════════════════════════════════════════════════════

/-- 文字列を表示して改行するにゃん -/
def loquiEtLinea {m : Type → Type} [Monad m] (s : String) : SakuraM m Unit := do
  loqui s; linea

/-- 主人格で表面を設定してから喋るにゃん -/
def sakuraLoquitur {m : Type → Type} [Monad m]
    (sup : Nat) (s : String) : SakuraM m Unit := do
  sakura; superficies sup; loqui s

/-- 副人格で表面を設定してから喋るにゃん -/
def keroLoquitur {m : Type → Type} [Monad m]
    (sup : Nat) (s : String) : SakuraM m Unit := do
  kero; superficies sup; loqui s

-- ════════════════════════════════════════════════════
--  實行 (Executio)
-- ════════════════════════════════════════════════════

/-- SakuraScript モナドを實行し、蓄積された SakuraScript 文字列を得るにゃん -/
def currere {m : Type → Type} [Monad m]
    (scriptum : SakuraM m Unit) (initium : String := "") : m String := do
  let (_, resultatum) ← StateT.run scriptum initium
  return resultatum

end Sakura

end UkaLean
