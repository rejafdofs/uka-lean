/*! ghost_host.c の Rust 版にゃん♪
 * 64-bit EXE として proxy32(shiori.dll) から起動され、
 * ghost.dll(Lean FFI)を讀み込んでパイプ越しに仕事を捌くにゃ
 */
use std::ffi::OsStr;
use std::io::{Read, Write};
use std::iter::once;
use std::os::windows::ffi::OsStrExt;

use windows_sys::Win32::Foundation::{GlobalFree, HMODULE};
use windows_sys::Win32::System::LibraryLoader::{GetProcAddress, LoadLibraryW, SetDllDirectoryW};
use windows_sys::Win32::System::Memory::{GlobalAlloc, GlobalLock, GlobalUnlock, GMEM_FIXED};

type HGLOBAL = *mut core::ffi::c_void;
// ghost.dll が輸出する SHIORI 關數の型にゃ
type FnLoad = unsafe extern "C" fn(HGLOBAL, i32) -> i32;
type FnUnload = unsafe extern "C" fn() -> i32;
type FnRequest = unsafe extern "C" fn(HGLOBAL, *mut i32) -> HGLOBAL;

macro_rules! log_trace {
    ($($arg:tt)*) => {
        if let Ok(mut file) = std::fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open("ghost_host_trace.txt")
        {
            use std::io::Write;
            let _ = writeln!(file, $($arg)*);
        }
    };
}

fn to_wide(s: &str) -> Vec<u16> {
    OsStr::new(s).encode_wide().chain(once(0)).collect()
}

fn write_u32(w: &mut impl Write, v: u32) -> std::io::Result<()> {
    w.write_all(&v.to_le_bytes())
}

fn read_u32(r: &mut impl Read) -> std::io::Result<u32> {
    let mut b = [0u8; 4];
    r.read_exact(&mut b)?;
    Ok(u32::from_le_bytes(b))
}

fn main() {
    // ① ghost.dll を探すにゃ（自分と同じディレクトーリウムにゃ）
    let exe_dir = std::env::current_exe()
        .ok()
        .and_then(|p| p.parent().map(|d| d.to_path_buf()))
        .unwrap_or_default();

    let dll_via = exe_dir.join("ghost.dll");
    let dll_str = dll_via.to_string_lossy();
    let dll_wide = to_wide(&dll_str);

    // Lean ランタイム DLL を見つける爲、DLL 探索パスを自分のディレクトーリウムに設定するにゃ
    // （libleanshared.dll 等が ghost.dll と同じ場所にあれば讀み込めるにゃん）
    unsafe {
        let dir_wide = to_wide(&exe_dir.to_string_lossy());
        SetDllDirectoryW(dir_wide.as_ptr());
    }

    let hlib = unsafe { LoadLibraryW(dll_wide.as_ptr()) };
    if hlib.is_null() {
        let err_code = unsafe { windows_sys::Win32::Foundation::GetLastError() };
        log_trace!("Failed to load ghost.dll: err_code={}", err_code);

        // エッロル(error)をファスキクルス(fasciculus)に記録するにゃ（診断用にゃ）
        let log_via = exe_dir.join("ghost_host_error.txt");
        let err_code = unsafe { windows_sys::Win32::Foundation::GetLastError() };
        let _ = std::fs::write(
            &log_via,
            format!(
                "ghost.dll の讀込に失敗したにゃ (via: {dll_str}, GetLastError: {err_code})\n\
                 Lean ランタイム DLL が不足してゐる可能性があるにゃ。\n\
                 `lean --print-prefix` で示されるディレクトーリウムの `bin/*.dll` を\n\
                 ghost/master/ にコピーするにゃん♪\n"
            ),
        );
        // proxy32 に「讀込失敗」を知らせるにゃ
        let _ = std::io::stdout().write_all(&[0u8; 1]);
        let _ = std::io::stdout().flush();
        return;
    }

    // ② 關數ポインタを取得するにゃ
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
            log_trace!("Failed to GetProcAddress");
            return;
        }
    };

    log_trace!("=== ghost_host started ===");
    let stdin = std::io::stdin();
    let stdout = std::io::stdout();
    let mut inn = stdin.lock();
    let mut out = stdout.lock();

    // ③ 命令ループにゃ
    loop {
        let mut cmd = [0u8; 1];
        if inn.read_exact(&mut cmd).is_err() {
            break;
        }
        match cmd[0] {
            1 => {
                log_trace!("Cmd: LOAD");
                // ONERARE(load): [len:u32LE][via_bytes] → [result:u8]
                let len = match read_u32(&mut inn) {
                    Ok(n) => n as usize,
                    Err(e) => {
                        log_trace!("LOAD read len failed: {}", e);
                        break;
                    }
                };
                log_trace!("LOAD len={}", len);
                let mut via_bytes = vec![0u8; len];
                if let Err(e) = inn.read_exact(&mut via_bytes) {
                    log_trace!("LOAD read bytes failed: {}", e);
                    break;
                }

                let result = unsafe {
                    // → ghost.dll の load() は HGLOBAL を GlobalFree するにゃ
                    let h = GlobalAlloc(GMEM_FIXED, len) as HGLOBAL;
                    if h.is_null() {
                        log_trace!("LOAD GlobalAlloc failed");
                    }
                    let ptr = GlobalLock(h) as *mut u8;
                    core::ptr::copy_nonoverlapping(via_bytes.as_ptr(), ptr, len);
                    GlobalUnlock(h);
                    f_load(h, len as i32)
                };

                log_trace!("LOAD result={}", result);
                let _ = out.write_all(&[if result != 0 { 1u8 } else { 0u8 }]);
                let _ = out.flush();
            }
            2 => {
                log_trace!("Cmd: UNLOAD");
                // EXONERARE(unload): 終了にゃ
                unsafe { f_unload() };
                break;
            }
            3 => {
                log_trace!("Cmd: REQUEST");
                // ROGARE(request): [len:u32LE][req_bytes] → [resp_len:u32LE][resp_bytes]
                let len = match read_u32(&mut inn) {
                    Ok(n) => n as usize,
                    Err(e) => {
                        log_trace!("REQUEST read len failed: {}", e);
                        break;
                    }
                };
                log_trace!("REQUEST len={}", len);
                let mut req_bytes = vec![0u8; len];
                if let Err(e) = inn.read_exact(&mut req_bytes) {
                    log_trace!("REQUEST read bytes failed: {}", e);
                    break;
                }

                let resp = unsafe {
                    // → ghost.dll の request() は入力 HGLOBAL を GlobalFree するにゃ
                    let h = GlobalAlloc(GMEM_FIXED, len) as HGLOBAL;
                    let ptr = GlobalLock(h) as *mut u8;
                    core::ptr::copy_nonoverlapping(req_bytes.as_ptr(), ptr, len);
                    GlobalUnlock(h);
                    let mut resp_len: i32 = len as i32; // 入力: 要求文字列の長さ
                    let resp_h = f_request(h, &mut resp_len);

                    if resp_h.is_null() || resp_len <= 0 {
                        log_trace!("REQUEST ghost.dll returned NULL or resp_len<=0");
                        None
                    } else {
                        // → 返された HGLOBAL は ghost_host が GlobalFree するにゃ
                        let ptr = GlobalLock(resp_h) as *const u8;
                        let bytes = core::slice::from_raw_parts(ptr, resp_len as usize).to_vec();
                        GlobalUnlock(resp_h);
                        GlobalFree(resp_h as _);
                        log_trace!("REQUEST returning {} bytes", bytes.len());
                        Some(bytes)
                    }
                };

                match resp {
                    Some(bytes) => {
                        let _ = write_u32(&mut out, bytes.len() as u32);
                        let _ = out.write_all(&bytes);
                    }
                    None => {
                        let _ = write_u32(&mut out, 0u32);
                    }
                }
                let _ = out.flush();
            }
            c => {
                log_trace!("Unknown cmd: {}", c);
                break;
            }
        }
    }
}
