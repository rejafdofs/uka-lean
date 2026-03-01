# 變更記錄 (Mutationum Registrum)

## 最適化 (Optimizatio)

### `evadeTextus` の文字列構築改善 (`SakuraScriptum.lean`)
SakuraScriptum の特殊文字遁走處理で、通常文字の追加を `String.ofList [c]`（毎囘リスト生成 + 文字列變換）から `acc.push c`（1文字直接追加）に變更したにゃ。文字列が長いほど效果が出るにゃん♪

### `executareScripturam` の O(n²) → O(n) 改善 (`StatusPermanens.lean`)
永続化の書出處理で、リストの末尾に `++` で追加してゐたのを、先頭に `::` で追加して最後に `.reverse` する方式に變更したにゃ。`++` はリスト全體を毎囘コピーするので O(n²) だったのが、O(n) になったにゃん♪

### `Rogatio.lean` の配列構築簡素化
`referentiae` 配列の初期化を手動ループから `(List.replicate maximumIndex "").toArray` に變更したにゃ。すっきりにゃん♪
