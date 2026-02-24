#include <windows.h>
#include <stdio.h>

typedef BOOL (*FnLoad)(HGLOBAL, long);

int main() {
    printf("[tester] Start\n");

    const char* dll_dir = "c:\\Users\\a\\.elan\\toolchains\\leanprover--lean4---v4.29.0-rc2\\bin";
    SetDllDirectoryA(dll_dir);

    HMODULE hLib = LoadLibraryA("c:\\Users\\a\\Documents\\uka.lean\\ghost.dll");
    if (!hLib) {
        printf("[tester] LoadLibrary failed: %lu\n", GetLastError());
        return 1;
    }
    printf("[tester] Loaded ghost.dll\n");

    FnLoad f_load = (FnLoad)GetProcAddress(hLib, "load");
    if (!f_load) {
        printf("[tester] GetProcAddress failed: %lu\n", GetLastError());
        return 1;
    }
    printf("[tester] Got f_load\n");

    const char* req = "c:\\Users\\a\\Documents\\uka.lean\\";
    size_t len = strlen(req);
    HGLOBAL h = GlobalAlloc(GMEM_FIXED, len);
    char* ptr = (char*)GlobalLock(h);
    memcpy(ptr, req, len);
    GlobalUnlock(h);

    printf("[tester] Calling f_load...\n");
    fflush(stdout);

    BOOL res = f_load(h, (long)len);
    
    printf("[tester] f_load returned: %d\n", res);
    return 0;
}
