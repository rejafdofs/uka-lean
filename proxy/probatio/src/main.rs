/*! SSP を模して ghost.dll を直接讀み込み、SHIORI 通信をプロバーティオーするにゃん♪
 *  ghost.dll の load / request / unload を直接呼んで動作確認するにゃ
 */

use std::ffi::OsStr;
use std::iter::once;
use std::os::windows::ffi::OsStrExt;

use windows_sys::Win32::Foundation::HMODULE;
use windows_sys::Win32::System::LibraryLoader::{GetProcAddress, LoadLibraryW, SetDllDirectoryW};
use windows_sys::Win32::System::Memory::{GlobalAlloc, GlobalLock, GlobalUnlock, GMEM_FIXED};

type HGLOBAL = *mut core::ffi::c_void;
type FnLoad = unsafe extern "C" fn(HGLOBAL, i32) -> i32;
type FnUnload = unsafe extern "C" fn() -> i32;
type FnRequest = unsafe extern "C" fn(HGLOBAL, *mut i32) -> HGLOBAL;

fn to_wide(s: &str) -> Vec<u16> {
    OsStr::new(s).encode_wide().chain(once(0)).collect()
}

/// HGLOBAL にバイト列を詰めて返すにゃん
unsafe fn bytes_to_hglobal(data: &[u8]) -> HGLOBAL {
    let h = GlobalAlloc(GMEM_FIXED, data.len()) as HGLOBAL;
    if !h.is_null() {
        let ptr = GlobalLock(h) as *mut u8;
        core::ptr::copy_nonoverlapping(data.as_ptr(), ptr, data.len());
        GlobalUnlock(h);
    }
    h
}

fn main() {
    // ① ghost.dll のディレクトーリウムを探すにゃ
    let exe_dir = std::env::current_exe()
        .ok()
        .and_then(|p| p.parent().map(|d| d.to_path_buf()))
        .unwrap_or_default();

    // プロヱクトゥムの根元にゃ
    let project_dir = std::path::PathBuf::from(r"c:\Users\a\Documents\uka.lean");
    let dll_path = project_dir.join("ghost.dll");

    println!("[probatio] ghost.dll via: {}", dll_path.display());

    // SetDllDirectoryW で Lean ランタイムの場所を知らせるにゃ
    unsafe {
        // まず lean --print-prefix/bin を試すにゃ
        if let Ok(output) = std::process::Command::new("lean")
            .arg("--print-prefix")
            .output()
        {
            let prefix = String::from_utf8_lossy(&output.stdout).trim().to_string();
            let bin_dir = format!("{}\\bin", prefix);
            println!("[probatio] SetDllDirectoryW -> {}", bin_dir);
            SetDllDirectoryW(to_wide(&bin_dir).as_ptr());
        } else {
            // フォールバック: ghost.dll と同じディレクトーリウムにゃ
            SetDllDirectoryW(to_wide(&project_dir.to_string_lossy()).as_ptr());
        }
    }

    // ② ghost.dll を讀み込むにゃ
    let dll_wide = to_wide(&dll_path.to_string_lossy());
    let hlib = unsafe { LoadLibraryW(dll_wide.as_ptr()) };
    if hlib.is_null() {
        let err = unsafe { windows_sys::Win32::Foundation::GetLastError() };
        eprintln!("[probatio] LoadLibraryW 失敗にゃ！ GetLastError={}", err);
        return;
    }
    println!("[probatio] ghost.dll 讀込成功にゃ！");

    // ③ 關數ポインタを取得するにゃ
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
            eprintln!("[probatio] GetProcAddress 失敗にゃ！");
            return;
        }
    };
    println!("[probatio] load/unload/request 取得成功にゃ！");

    // ④ load を呼ぶにゃ — ゴーストのディレクトーリウムを UTF-8 で渡すにゃ
    let ghost_dir = project_dir.to_string_lossy().to_string();
    let ghost_dir_bytes = ghost_dir.as_bytes();
    println!("[probatio] load({}) を呼ぶにゃ...", ghost_dir);

    let load_result = unsafe {
        let h = bytes_to_hglobal(ghost_dir_bytes);
        println!("[probatio] HGLOBAL 作成完了、f_load を呼ぶにゃ...");
        f_load(h, ghost_dir_bytes.len() as i32)
    };
    println!("[probatio] load 結果: {}", load_result);

    if load_result == 0 {
        eprintln!("[probatio] load 失敗にゃ…終了するにゃ");
        return;
    }

    // ⑤ request を呼ぶにゃ — SHIORI/3.0 GET を模擬するにゃん
    let shiori_req = "GET SHIORI/3.0\r\n\
                      Charset: UTF-8\r\n\
                      Sender: SSP\r\n\
                      SecurityLevel: local\r\n\
                      ID: OnBoot\r\n\
                      Reference0: master\r\n\
                      \r\n";

    println!("[probatio] request を呼ぶにゃ...");
    println!("[probatio] 要求:\n{}", shiori_req);

    let resp = unsafe {
        let h = bytes_to_hglobal(shiori_req.as_bytes());
        let mut resp_len: i32 = shiori_req.len() as i32;
        let resp_h = f_request(h, &mut resp_len);

        if resp_h.is_null() || resp_len <= 0 {
            println!(
                "[probatio] request が NULL を返したにゃ (resp_len={})",
                resp_len
            );
            None
        } else {
            let ptr = GlobalLock(resp_h) as *const u8;
            let bytes = core::slice::from_raw_parts(ptr, resp_len as usize).to_vec();
            GlobalUnlock(resp_h);
            // GlobalFree は ghost.dll が管理するにゃ
            Some(bytes)
        }
    };

    match resp {
        Some(bytes) => {
            let text = String::from_utf8_lossy(&bytes);
            println!("[probatio] 應答 ({} bytes):\n{}", bytes.len(), text);
        }
        None => {
            println!("[probatio] 應答なしにゃ");
        }
    }

    // ⑥ unload を呼ぶにゃ
    println!("[probatio] unload を呼ぶにゃ...");
    let unload_result = unsafe { f_unload() };
    println!("[probatio] unload 結果: {}", unload_result);
    println!("[probatio] 完了にゃん♪");
}
