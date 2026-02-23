-- SampleGhost — UkaLean サンプルゴーストにゃん♪
--
-- このファスキクルスが DLL の起點になるにゃ。
-- initialize ブロックで UkaLean に處理器を登錄するにゃん。

import UkaLean
import SampleGhost.Handlers

-- ★ これがポイントにゃん！
--    initialize ブロックは DLL 初期化時（lean_initialize()）に自動で呼ばれるにゃ。
--    registraShiori に處理器一覽を渡すだけで栞の完成にゃ♪
initialize UkaLean.registraShiori SampleGhost.tractatores
