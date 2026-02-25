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
#include <windows.h>
#include <stdint.h>
/* その他のヘッダなど */
#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#endif

/* leanc 環境では string.h が無いことがあるため明示宣言 */
void *memcpy(void *dest, const void *src, size_t n);

static size_t c_strlen(const char* s) {
    size_t len = 0;
    while (s[len] != '\0') len++;
    return len;
}

#ifdef _WIN32
/* leanc 環境では windows.h 依存を避ける */
#ifndef __cdecl
#define __cdecl
#endif
#ifndef __stdcall
#define __stdcall
#endif

typedef void* HGLOBAL;
typedef void* HANDLE;
typedef unsigned long DWORD;
typedef int   BOOL;
typedef long  LONG;
#define TRUE  1
#define FALSE 0
#define GMEM_FIXED 0x0000
#define INVALID_HANDLE_VALUE ((HANDLE)(intptr_t)-1)
#define OPEN_ALWAYS 4
#define FILE_APPEND_DATA 4
#define FILE_SHARE_READ 1
#define FILE_ATTRIBUTE_NORMAL 128

__declspec(dllimport) HGLOBAL __stdcall GlobalAlloc(unsigned int flags, size_t bytes);
__declspec(dllimport) void*   __stdcall GlobalLock(HGLOBAL hMem);
__declspec(dllimport) BOOL    __stdcall GlobalUnlock(HGLOBAL hMem);
__declspec(dllimport) HGLOBAL __stdcall GlobalFree(HGLOBAL hMem);
__declspec(dllimport) size_t  __stdcall GlobalSize(HGLOBAL hMem);

__declspec(dllimport) HANDLE __stdcall CreateFileA(const char* lpFileName, DWORD dwDesiredAccess, DWORD dwShareMode, void* lpSecurityAttributes, DWORD dwCreationDisposition, DWORD dwFlagsAndAttributes, HANDLE hTemplateFile);
__declspec(dllimport) BOOL __stdcall WriteFile(HANDLE hFile, const void* lpBuffer, DWORD nNumberOfBytesToWrite, DWORD* lpNumberOfBytesWritten, void* lpOverlapped);
__declspec(dllimport) BOOL __stdcall CloseHandle(HANDLE hObject);

#else
/* POSIX 環境での模擬にゃん（試驗用）*/
#include <stdlib.h>
typedef void* HGLOBAL;
typedef void* HANDLE;
typedef unsigned long DWORD;
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

extern lean_object* lean_shiori_load(lean_object* dir_str, lean_object* world);
extern lean_object* lean_shiori_unload(lean_object* world);
extern lean_object* lean_shiori_request(lean_object* req_str, lean_object* world);
extern lean_object* lean_io_error_to_string(lean_object* err);

/* Lean 使用者モドゥルスの初期化關數にゃん（lake build が生成するにゃ）*/
extern lean_object* initialize_Ghost(uint8_t b, lean_object* world);

/* Lean ランタイムの内部初期化關數群にゃ（lean.h には無いため自分で宣言するにゃん）*/
extern char** lean_setup_args(int argc, char ** argv);
extern void lean_initialize_runtime_module(void);
extern void lean_init_task_manager(void);
extern void lean_io_mark_end_initialization(void);

static int g_lean_initialized = 0;

/* ──────────────────────────────────────────────
 * Lean 實行時環境の初期化にゃん
 * ────────────────────────────────────────────── */
static void c_log(const char* msg) {
    HANDLE h = CreateFileA("C:\\Users\\a\\shiori_c_trace.txt", FILE_APPEND_DATA, FILE_SHARE_READ, NULL, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (h != INVALID_HANDLE_VALUE) {
        DWORD written;
        WriteFile(h, msg, (DWORD)c_strlen(msg), &written, NULL);
        WriteFile(h, "\n", 1, &written, NULL);
        CloseHandle(h);
    }
}

static int ensure_lean_initialized(void) {
    if (g_lean_initialized) return 1;

    /* 假の引數を渡す（これがないと Lean がクラッシュするにゃん）*/
    static char* argv[] = { "ghost", NULL };
    lean_setup_args(1, argv);

    c_log("Initializing Lean runtime...");
    lean_initialize_runtime_module();
    
    c_log("Loading Ghost module...");
    lean_object* res = initialize_Ghost(1 /* builtin=true */, lean_io_mk_world());
    if (lean_io_result_is_error(res)) {
        lean_object* err = lean_io_result_get_error(res);
        lean_object* err_str = lean_io_error_to_string(err);
        c_log("Failed to initialize Ghost module!");
        lean_dec_ref(err_str);
        lean_dec_ref(res);
        return 0;
    }
    lean_dec_ref(res);

    lean_io_mark_end_initialization();
    lean_init_task_manager();
    c_log("Lean initialized successfully.");
    g_lean_initialized = 1;
    return 1;
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
    lean_object* io_res = lean_shiori_load(dir_obj, lean_io_mk_world());
    BOOL ret = FALSE;
    if (lean_io_result_is_ok(io_res)) {
        lean_object* val_obj = lean_io_result_get_value(io_res);
        if (lean_unbox_uint32(val_obj) != 0) {
            ret = TRUE;
        }
    }
    lean_dec_ref(io_res);
    return ret;
}

#ifdef _WIN32
__declspec(dllexport)
#endif
BOOL __cdecl unload(void) {
    if (!g_lean_initialized) return TRUE;

    lean_object* io_res = lean_shiori_unload(lean_io_mk_world());
    BOOL ret = FALSE;
    if (lean_io_result_is_ok(io_res)) {
        lean_object* val_obj = lean_io_result_get_value(io_res);
        if (lean_unbox_uint32(val_obj) != 0) {
            ret = TRUE;
        }
    }
    lean_dec_ref(io_res);
    return ret;
}

#ifdef _WIN32
__declspec(dllexport)
#endif
HGLOBAL __cdecl request(HGLOBAL h, long *len) {
    c_log("shiori.c: request() entered");
    if (!g_lean_initialized) {
        c_log("shiori.c: not initialized!");
        GlobalFree(h);
        *len = 0;
        return NULL;
    }

    /* HGLOBAL から要求文字列を取り出すにゃん */
    char* req_ptr = (char*)GlobalLock(h);
    long req_len = *len; /* 引數で渡された正確な長さを變數に逃がすにゃ */
    c_log("shiori.c: calling lean_mk_string_from_bytes");
    lean_object* req_obj = lean_mk_string_from_bytes(req_ptr, (size_t)req_len);
    GlobalUnlock(h);
    GlobalFree(h);

    c_log("shiori.c: calling lean_shiori_request");
    lean_object* world = lean_io_mk_world();
    lean_object* io_res = lean_shiori_request(req_obj, world);
    lean_dec_ref(req_obj);

    if (!lean_io_result_is_ok(io_res)) {
        c_log("shiori.c: error in lean_shiori_request");
        lean_object* err_obj = lean_io_result_get_error(io_res);
        lean_object* err_str_obj = lean_io_error_to_string(err_obj);
        const char* err_cstr = lean_string_cstr(err_str_obj);
        size_t err_len = lean_string_size(err_str_obj) - 1;

        HGLOBAL out = GlobalAlloc(GMEM_FIXED, err_len + 10);
        if (out) {
            char* out_ptr = (char*)out;
            memcpy(out_ptr, "[ERROR] ", 8);
            memcpy(out_ptr + 8, err_cstr, err_len);
            *len = (long)(err_len + 8);
        } else {
            *len = 0;
        }

        lean_dec_ref(err_str_obj);
        lean_dec_ref(io_res);
        return out;
    }

    c_log("shiori.c: lean_shiori_request returned OK");
    /* 結果の文字列を取り出すにゃん */
    lean_object* resp_obj = lean_io_result_get_value(io_res);
    const char* resp_cstr = lean_string_cstr(resp_obj);
    size_t resp_len = lean_string_size(resp_obj) - 1; /* 末尾の NUL を除くにゃ */

    c_log("shiori.c: copying response bytes");
    /* HGLOBAL に複寫して返すにゃん */
    HGLOBAL out = GlobalAlloc(GMEM_FIXED, resp_len);
    if (out) {
        memcpy(out, resp_cstr, resp_len);
        *len = (long)resp_len;
    } else {
        c_log("shiori.c: GlobalAlloc failed for response");
        *len = 0;
    }

    lean_dec_ref(io_res);
    c_log("shiori.c: request() exiting successfully");
    return out;
}
