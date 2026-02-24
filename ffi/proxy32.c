/*
 * proxy32.c - 32-bit SHIORI Proxy DLL
 * SSP から讀み込まれる `shiori.dll` として振舞ふにゃん。
 * 實際の處理は別プロケッスス(processus) (`uka_host.exe`) にパイプで丸投げするにゃ♪
 */

#include <windows.h>
#include <stdio.h>

HANDLE hChildStdinRd = NULL, hChildStdinWr = NULL;
HANDLE hChildStdoutRd = NULL, hChildStdoutWr = NULL;
PROCESS_INFORMATION piProcInfo;
char szHostPath[MAX_PATH];

BOOL APIENTRY DllMain(HMODULE hModule, DWORD ul_reason_for_call, LPVOID lpReserved) {
    if (ul_reason_for_call == DLL_PROCESS_ATTACH) {
        GetModuleFileNameA(hModule, szHostPath, MAX_PATH);
        char* lastSlash = strrchr(szHostPath, '\\');
        if (lastSlash) {
            *lastSlash = '\0';
        }
        strcat(szHostPath, "\\ghost.exe");
    }
    return TRUE;
}

#ifdef _WIN32
__declspec(dllexport)
#endif
BOOL __cdecl load(HGLOBAL h, long len) {
    SECURITY_ATTRIBUTES saAttr;
    saAttr.nLength = sizeof(SECURITY_ATTRIBUTES);
    saAttr.bInheritHandle = TRUE;
    saAttr.lpSecurityDescriptor = NULL;

    if (!CreatePipe(&hChildStdoutRd, &hChildStdoutWr, &saAttr, 0)) return FALSE;
    SetHandleInformation(hChildStdoutRd, HANDLE_FLAG_INHERIT, 0);

    if (!CreatePipe(&hChildStdinRd, &hChildStdinWr, &saAttr, 0)) return FALSE;
    SetHandleInformation(hChildStdinWr, HANDLE_FLAG_INHERIT, 0);

    STARTUPINFOA siStartInfo;
    ZeroMemory(&piProcInfo, sizeof(PROCESS_INFORMATION));
    ZeroMemory(&siStartInfo, sizeof(STARTUPINFOA));
    siStartInfo.cb = sizeof(STARTUPINFOA);
    siStartInfo.hStdError = hChildStdoutWr;
    siStartInfo.hStdOutput = hChildStdoutWr;
    siStartInfo.hStdInput = hChildStdinRd;
    siStartInfo.dwFlags |= STARTF_USESTDHANDLES | STARTF_USESHOWWINDOW;
    siStartInfo.wShowWindow = SW_HIDE;

    BOOL bSuccess = CreateProcessA(szHostPath, NULL, NULL, NULL, TRUE, CREATE_NO_WINDOW, NULL, NULL, &siStartInfo, &piProcInfo);
    if (!bSuccess) return FALSE;

    char* dir = (char*)GlobalLock(h);
    DWORD written;
    int cmd = 1; // LOAD
    WriteFile(hChildStdinWr, &cmd, sizeof(int), &written, NULL);
    WriteFile(hChildStdinWr, &len, sizeof(long), &written, NULL);
    WriteFile(hChildStdinWr, dir, len, &written, NULL);
    GlobalUnlock(h);

    int res = 0;
    DWORD readBytes;
    ReadFile(hChildStdoutRd, &res, sizeof(int), &readBytes, NULL);
    return res ? TRUE : FALSE;
}

#ifdef _WIN32
__declspec(dllexport)
#endif
BOOL __cdecl unload(void) {
    if (!piProcInfo.hProcess) return TRUE;
    int cmd = 2; // UNLOAD
    DWORD written;
    WriteFile(hChildStdinWr, &cmd, sizeof(int), &written, NULL);
    
    WaitForSingleObject(piProcInfo.hProcess, INFINITE);
    
    CloseHandle(piProcInfo.hProcess);
    CloseHandle(piProcInfo.hThread);
    CloseHandle(hChildStdinRd);
    CloseHandle(hChildStdinWr);
    CloseHandle(hChildStdoutRd);
    CloseHandle(hChildStdoutWr);
    ZeroMemory(&piProcInfo, sizeof(PROCESS_INFORMATION));
    return TRUE;
}

#ifdef _WIN32
__declspec(dllexport)
#endif
HGLOBAL __cdecl request(HGLOBAL h, long *len) {
    if (!piProcInfo.hProcess) {
        if(h) GlobalFree(h);
        *len = 0;
        return NULL;
    }
    
    long req_len = (long)GlobalSize(h);
    char* req = (char*)GlobalLock(h);
    
    int cmd = 3; // REQUEST
    DWORD written;
    WriteFile(hChildStdinWr, &cmd, sizeof(int), &written, NULL);
    WriteFile(hChildStdinWr, &req_len, sizeof(long), &written, NULL);
    WriteFile(hChildStdinWr, req, req_len, &written, NULL);
    GlobalUnlock(h);
    GlobalFree(h); // SSPが渡したhandleはここで開放するにゃん
    
    long resp_len = 0;
    DWORD readBytes;
    ReadFile(hChildStdoutRd, &resp_len, sizeof(long), &readBytes, NULL);
    if (resp_len <= 0) {
        *len = 0;
        return NULL;
    }
    
    // 結果をSSPへ返す爲にGlobalAllocするにゃん
    HGLOBAL out = GlobalAlloc(GMEM_FIXED, resp_len);
    if (out) {
        long left = resp_len;
        char* ptr = (char*)out;
        while(left > 0) {
            ReadFile(hChildStdoutRd, ptr, left, &readBytes, NULL);
            if(readBytes == 0) break;
            ptr += readBytes;
            left -= readBytes;
        }
        *len = resp_len - left;
    } else {
        char buf[1024];
        long left = resp_len;
        while(left > 0) {
            DWORD toRead = left > 1024 ? 1024 : left;
            ReadFile(hChildStdoutRd, buf, toRead, &readBytes, NULL);
            if(readBytes == 0) break;
            left -= readBytes;
        }
        *len = 0;
    }
    
    return out; // これをSSPが後で開放するにゃ
}
