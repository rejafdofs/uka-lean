/*
 * proxy64.c - 64-bit SHIORI Host
 * 32-bit `shiori.dll` から呼び出される裏方の本体系にゃん。
 * `uka_lean.dll` を讀み込んで全ての處理を委讓するにゃ♪
 */

#include <windows.h>
#include <stdio.h>
#include <stdlib.h>

typedef BOOL (__cdecl *LOAD_FUNC)(HGLOBAL, long);
typedef BOOL (__cdecl *UNLOAD_FUNC)(void);
typedef HGLOBAL (__cdecl *REQUEST_FUNC)(HGLOBAL, long*);

int main() {
    // 緩衝を無くしてパイプ通信を安定させるにゃ
    setvbuf(stdout, NULL, _IONBF, 0);

    char szDllPath[MAX_PATH];
    GetModuleFileNameA(NULL, szDllPath, MAX_PATH);
    char* lastSlash = strrchr(szDllPath, '\\');
    if (lastSlash) {
        *lastSlash = '\0';
    }
    strcat(szDllPath, "\\ghost.dll");

    // 直に生成された眞の 64-bit 實体を讀み込むにゃ
    HMODULE hDll = LoadLibraryA(szDllPath);
    if (!hDll) return 1;

    LOAD_FUNC pLoad = (LOAD_FUNC)GetProcAddress(hDll, "load");
    UNLOAD_FUNC pUnload = (UNLOAD_FUNC)GetProcAddress(hDll, "unload");
    REQUEST_FUNC pRequest = (REQUEST_FUNC)GetProcAddress(hDll, "request");

    if (!pLoad || !pUnload || !pRequest) return 1;

    HANDLE hStdin = GetStdHandle(STD_INPUT_HANDLE);
    HANDLE hStdout = GetStdHandle(STD_OUTPUT_HANDLE);

    while (1) {
        int cmd = 0;
        DWORD readBytes;
        if (!ReadFile(hStdin, &cmd, sizeof(int), &readBytes, NULL) || readBytes == 0) {
            break;
        }

        if (cmd == 1) { // LOAD
            long len = 0;
            ReadFile(hStdin, &len, sizeof(long), &readBytes, NULL);
            HGLOBAL h = GlobalAlloc(GMEM_FIXED, len);
            if (h) ReadFile(hStdin, h, len, &readBytes, NULL);
            
            // 眞のDllへ委讓（向かふ側が HGLOBAL を開放するにゃ）
            BOOL res = pLoad(h, len);
            
            int outRes = res ? 1 : 0;
            DWORD written;
            WriteFile(hStdout, &outRes, sizeof(int), &written, NULL);
        } else if (cmd == 2) { // UNLOAD
            pUnload();
            break;
        } else if (cmd == 3) { // REQUEST
            long len = 0;
            ReadFile(hStdin, &len, sizeof(long), &readBytes, NULL);
            HGLOBAL h = GlobalAlloc(GMEM_FIXED, len);
            if (h) ReadFile(hStdin, h, len, &readBytes, NULL);
            
            // 眞のDllへ委讓（向かふ側が新しい HGLOBAL を返してくるにゃ）
            long outLen = 0;
            HGLOBAL out = pRequest(h, &outLen);
            
            DWORD written;
            WriteFile(hStdout, &outLen, sizeof(long), &written, NULL);
            if (outLen > 0 && out) {
                WriteFile(hStdout, out, outLen, &written, NULL);
                // パイプに送ったあとは不要にゃので自前で開放するにゃ
                GlobalFree(out);
            }
        }
    }

    FreeLibrary(hDll);
    return 0;
}
