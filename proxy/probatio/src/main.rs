/*! SSP を模して ghost.dll を直接讀み込み、SHIORI 通信をプロバーティオーするにゃん♪ */

use std::ffi::OsStr;
use std::iter::once;
use std::os::windows::ffi::OsStrExt;

use windows_sys::Win32::System::LibraryLoader::{GetProcAddress, LoadLibraryW, SetDllDirectoryW};
use windows_sys::Win32::System::Memory::{GlobalAlloc, GlobalLock, GlobalUnlock, GMEM_FIXED};

type HGLOBAL = *mut core::ffi::c_void;
type FnLoad = unsafe extern "C" fn(HGLOBAL, i32) -> i32;
type FnUnload = unsafe extern "C" fn() -> i32;
type FnRequest = unsafe extern "C" fn(HGLOBAL, *mut i32) -> HGLOBAL;

fn to_wide(s: &str) -> Vec<u16> {
    OsStr::new(s).encode_wide().chain(once(0)).collect()
}

unsafe fn bytes_to_hglobal(data: &[u8]) -> HGLOBAL {
    let h = GlobalAlloc(GMEM_FIXED, data.len()) as HGLOBAL;
    if !h.is_null() {
        let ptr = GlobalLock(h) as *mut u8;
        core::ptr::copy_nonoverlapping(data.as_ptr(), ptr, data.len());
        GlobalUnlock(h);
    }
    h
}

use windows_sys::Win32::Foundation::EXCEPTION_ACCESS_VIOLATION;
use windows_sys::Win32::System::Diagnostics::Debug::{
    AddVectoredExceptionHandler, EXCEPTION_POINTERS,
};

unsafe extern "system" fn exception_handler(exc_info: *mut EXCEPTION_POINTERS) -> i32 {
    if !exc_info.is_null() {
        let record = (*exc_info).ExceptionRecord;
        if !record.is_null() {
            let code = (*record).ExceptionCode;
            eprintln!("[FATAL] Windows Exception Caught! Code: {:#X}", code);
            if code == EXCEPTION_ACCESS_VIOLATION {
                eprintln!(
                    "[FATAL] Access Violation at address {:#X}",
                    (*record).ExceptionAddress as usize
                );
            }
        }
    }
    std::process::exit(1);
}

fn main() {
    unsafe {
        AddVectoredExceptionHandler(1, Some(exception_handler));
    }

    let project_dir = std::path::PathBuf::from(r"c:\Users\a\Documents\uka.lean");
    let dll_path = project_dir.join("ghost.dll");

    eprintln!("[1] ghost.dll via: {}", dll_path.display());

    // Lean ランタイム DLL の場所を設定するにゃ
    if let Ok(output) = std::process::Command::new("lean")
        .arg("--print-prefix")
        .output()
    {
        let prefix = String::from_utf8_lossy(&output.stdout).trim().to_string();
        let bin_dir = format!("{}\\bin", prefix);
        eprintln!("[2] SetDllDirectoryW -> {}", bin_dir);
        unsafe {
            SetDllDirectoryW(to_wide(&bin_dir).as_ptr());
        }
    }

    // ghost.dll を讀み込むにゃ
    let hlib = unsafe { LoadLibraryW(to_wide(&dll_path.to_string_lossy()).as_ptr()) };
    if hlib.is_null() {
        let err = unsafe { windows_sys::Win32::Foundation::GetLastError() };
        eprintln!("[ERR] LoadLibraryW failed: GetLastError={}", err);
        return;
    }
    eprintln!("[3] ghost.dll loaded OK");

    // 關數ポインタ取得するにゃ
    let f_load = unsafe {
        GetProcAddress(hlib, b"load\0".as_ptr()).map(|f| std::mem::transmute::<_, FnLoad>(f))
    };
    let f_unload = unsafe {
        GetProcAddress(hlib, b"unload\0".as_ptr()).map(|f| std::mem::transmute::<_, FnUnload>(f))
    };
    let f_request = unsafe {
        GetProcAddress(hlib, b"request\0".as_ptr()).map(|f| std::mem::transmute::<_, FnRequest>(f))
    };

    let (f_load, f_unload, f_request) = match (f_load, f_unload, f_request) {
        (Some(a), Some(b), Some(c)) => (a, b, c),
        _ => {
            eprintln!("[ERR] GetProcAddress failed");
            return;
        }
    };
    eprintln!("[4] load/unload/request resolved");

    // load を呼ぶにゃ（SSP は末尾 \ 付きにゃ）
    let ghost_dir = format!("{}\\", project_dir.to_string_lossy());
    let ghost_dir_bytes = ghost_dir.as_bytes();
    eprintln!(
        "[5] calling load({}) len={}",
        ghost_dir,
        ghost_dir_bytes.len()
    );

    let load_result = unsafe {
        let h = bytes_to_hglobal(ghost_dir_bytes);
        eprintln!("[6] calling f_load...");
        let r = f_load(h, ghost_dir_bytes.len() as i32);
        eprintln!("[7] f_load returned {}", r);
        r
    };

    if load_result == 0 {
        eprintln!("[ERR] load returned 0 (failure)");
        return;
    }
    eprintln!("[8] load succeeded");

    // request を呼ぶにゃ
    let shiori_req = "GET SHIORI/3.0\r\nCharset: UTF-8\r\nSender: SSP\r\nSecurityLevel: local\r\nID: OnBoot\r\nReference0: master\r\n\r\n";
    eprintln!("[9] calling request (OnBoot)...");

    let resp = unsafe {
        let h = bytes_to_hglobal(shiori_req.as_bytes());
        let mut resp_len: i32 = shiori_req.len() as i32;
        let resp_h = f_request(h, &mut resp_len);
        if resp_h.is_null() || resp_len <= 0 {
            eprintln!("[10] request returned NULL (resp_len={})", resp_len);
            None
        } else {
            let ptr = GlobalLock(resp_h) as *const u8;
            let bytes = core::slice::from_raw_parts(ptr, resp_len as usize).to_vec();
            GlobalUnlock(resp_h);
            Some(bytes)
        }
    };

    match resp {
        Some(bytes) => eprintln!(
            "[10] response ({} bytes):\n{}",
            bytes.len(),
            String::from_utf8_lossy(&bytes)
        ),
        None => eprintln!("[10] no response"),
    }

    // unload を呼ぶにゃ
    eprintln!("[11] calling unload...");
    unsafe {
        f_unload();
    }
    eprintln!("[12] done!");
}
