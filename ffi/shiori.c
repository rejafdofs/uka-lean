/*
 * shiori.c — SHIORI DLL の C 包裝にゃん
 *
 * Windows の HGLOBAL 記憶管理と Lean 4 實行時環境の橋渡しをするにゃ。
 * SSP 等のベースウェアはこの DLL の load/unload/request を呼ぶにゃん。
 *
 * 構築方法:
 *   lake build Ghost:static UkaLean:static
 *   gcc -shared -o shiori.dll ffi/shiori.c \
 *     -I"$(lean --print-prefix)/include" \
 *     -L.lake/build/lib -lGhost \
 *     -L.lake/packages/uka-lean/.lake/build/lib -lUkaLean \
 *     -L"$(lean --print-prefix)/lib/lean" -lleanshared \
 *     -lws2_32
 */

#include <lean/lean.h>
#include <stddef.h>

/* leanc 環境では string.h が無いことがあるため明示宣言 */
void *memcpy(void *dest, const void *src, size_t n);

#ifdef _WIN32
/* leanc 環境では windows.h 依存を避ける */
#ifndef __cdecl
#define __cdecl
#endif
#ifndef __stdcall
#define __stdcall
#endif

typedef void* HGLOBAL;
typedef int   BOOL;
#define TRUE  1
#define FALSE 0
#define GMEM_FIXED 0x0000

__declspec(dllimport) HGLOBAL __stdcall GlobalAlloc(unsigned int flags, size_t bytes);
__declspec(dllimport) void*   __stdcall GlobalLock(HGLOBAL hMem);
__declspec(dllimport) BOOL    __stdcall GlobalUnlock(HGLOBAL hMem);
__declspec(dllimport) HGLOBAL __stdcall GlobalFree(HGLOBAL hMem);
__declspec(dllimport) size_t  __stdcall GlobalSize(HGLOBAL hMem);
#else
/* POSIX 環境での模擬にゃん（試驗用）*/
#include <stdlib.h>
typedef void* HGLOBAL;
typedef int   BOOL;
typedef long  LONG;
#define TRUE  1
#define FALSE 0
#define GMEM_FIXED 0x0000
static HGLOBAL GlobalAlloc(unsigned int flags, size_t bytes) {
    (void)flags;
    return malloc(bytes);
}
static void* GlobalLock(HGLOBAL h) { return h; }
static void  GlobalUnlock(HGLOBAL h) { (void)h; }
static void  GlobalFree(HGLOBAL h) { free(h); }
static size_t GlobalSize(HGLOBAL h) { (void)h; return 0; }
#endif

/* ──────────────────────────────────────────────
 * Lean 側の @[export] 關數宣言にゃん
 * UkaLean.Exporta で定義されてるにゃ
 * ────────────────────────────────────────────── */

extern uint32_t lean_shiori_load(lean_object* dir_str, lean_object* world);
extern uint32_t lean_shiori_unload(lean_object* world);
extern lean_object* lean_shiori_request(lean_object* req_str, lean_object* world);

/* Lean 使用者モドゥルスの初期化關數にゃん（lake build が生成するにゃ）*/
extern lean_object* initialize_Ghost(uint8_t builtin, lean_object* world);

/* Lean ランタイムの内部初期化關數群にゃ（lean.h には無いため自分で宣言するにゃん）*/
extern void lean_initialize_runtime_module(void);
extern void lean_init_task_manager(void);
extern void lean_io_mark_end_initialization(void);

static int g_lean_initialized = 0;

static void trace_log(const char* msg) {
    FILE* f = fopen("ghost_c_trace.txt", "a");
    if (f) {
        fprintf(f, "%s\n", msg);
        fclose(f);
    }
}

/* ──────────────────────────────────────────────
 * Lean 實行時環境の初期化にゃん
 * ────────────────────────────────────────────── */
static int ensure_lean_initialized(void) {
    if (g_lean_initialized) return 1;

    trace_log("[shiori.c] ensure_lean_initialized: start");

    /* Lean 4 の正規の初期化手順に從ふにゃ */
    trace_log("[shiori.c] calling lean_initialize_runtime_module");
    lean_initialize_runtime_module();
    
    trace_log("[shiori.c] calling initialize_Ghost(1)");
    lean_object* res = initialize_Ghost(1 /* builtin=true */, lean_io_mk_world());
    
    trace_log("[shiori.c] initialize_Ghost returned");
    if (lean_io_result_is_ok(res)) {
        lean_dec_ref(res);
        trace_log("[shiori.c] calling lean_io_mark_end_initialization");
        lean_io_mark_end_initialization();
        trace_log("[shiori.c] calling lean_init_task_manager");
        lean_init_task_manager();
        g_lean_initialized = 1;
        trace_log("[shiori.c] init OK");
        return 1;
    } else {
        trace_log("[shiori.c] init ERROR");
        lean_io_result_show_error(res);
        lean_dec_ref(res);
        return 0;
    }
}

/* ──────────────────────────────────────────────
 * SHIORI DLL 輸出關數群にゃん
 * ────────────────────────────────────────────── */

#ifdef _WIN32
__declspec(dllexport)
#endif
BOOL __cdecl load(HGLOBAL h, long len) {
    if (!ensure_lean_initialized()) {
        GlobalFree(h);
        return FALSE;
    }

    /* HGLOBAL から家ディレクトーリウム文字列を取り出すにゃん */
    char* dir = (char*)GlobalLock(h);
    lean_object* dir_obj = lean_mk_string_from_bytes(dir, (size_t)len);
    GlobalUnlock(h);
    GlobalFree(h);

    /* Lean 側の load 處理を呼ぶにゃん */
    uint32_t result = lean_shiori_load(dir_obj, lean_io_mk_world());
    return result ? TRUE : FALSE;
}

#ifdef _WIN32
__declspec(dllexport)
#endif
BOOL __cdecl unload(void) {
    if (!g_lean_initialized) return TRUE;

    lean_shiori_unload(lean_io_mk_world());
    return TRUE;
}

#ifdef _WIN32
__declspec(dllexport)
#endif
HGLOBAL __cdecl request(HGLOBAL h, long *len) {
    if (!g_lean_initialized) {
        GlobalFree(h);
        *len = 0;
        return NULL;
    }

    /* HGLOBAL から要求文字列を取り出すにゃん */
    char* req_ptr = (char*)GlobalLock(h);
    long req_len = (long)GlobalSize(h);
    lean_object* req_obj = lean_mk_string_from_bytes(req_ptr, (size_t)req_len);
    GlobalUnlock(h);
    GlobalFree(h);

    /* Lean 側の request 處理を呼ぶにゃん */
    lean_object* world = lean_io_mk_world();
    lean_object* io_res = lean_shiori_request(req_obj, world);

    if (!lean_io_result_is_ok(io_res)) {
        /* Lean 側で異常が發生したにゃ */
        lean_dec_ref(io_res);
        *len = 0;
        return NULL;
    }

    /* 結果の文字列を取り出すにゃん */
    lean_object* resp_obj = lean_io_result_get_value(io_res);
    const char* resp_cstr = lean_string_cstr(resp_obj);
    size_t resp_len = lean_string_size(resp_obj) - 1; /* 末尾の NUL を除くにゃ */

    /* HGLOBAL に複寫して返すにゃん */
    HGLOBAL out = GlobalAlloc(GMEM_FIXED, resp_len);
    if (out) {
        memcpy(out, resp_cstr, resp_len);
        *len = (long)resp_len;
    } else {
        *len = 0;
    }

    lean_dec_ref(io_res);
    return out;
}
