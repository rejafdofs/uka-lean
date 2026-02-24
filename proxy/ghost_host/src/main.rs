/*! ghost_host.c の Rust 版にゃん♪
 * 64-bit EXE として proxy32(shiori.dll) から起動され、
 * ghost.dll(Lean FFI)を讀み込んでパイプ越しに仕事を捌くにゃ
 */
use std::ffi::OsStr;
use std::io::{Read, Write};
use std::iter::once;
use std::os::windows::ffi::OsStrExt;

use windows_sys::Win32::Foundation::{GlobalFree, HMODULE};
use windows_sys::Win32::System::LibraryLoader::{GetProcAddress, LoadLibraryW};
use windows_sys::Win32::System::Memory::{GlobalAlloc, GlobalLock, GlobalUnlock, GMEM_FIXED};

type HGLOBAL = *mut core::ffi::c_void;
// ghost.dll が輸出する SHIORI 關數の型にゃ
type FnLoad = unsafe extern "C" fn(HGLOBAL, i32) -> i32;
type FnUnload = unsafe extern "C" fn() -> i32;
type FnRequest = unsafe extern "C" fn(HGLOBAL, *mut i32) -> HGLOBAL;

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
    let dll_via = std::env::current_exe()
        .ok()
        .and_then(|p| p.parent().map(|d| d.join("ghost.dll")))
        .unwrap_or_default();
    let dll_str = dll_via.to_string_lossy();
    let dll_wide = to_wide(&dll_str);

    let hlib = unsafe { LoadLibraryW(dll_wide.as_ptr()) };
    if hlib.is_null() {
        return; // 讀み込めにゃかった時は黙って終了するにゃ
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
        _ => return,
    };

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
                // ONERARE(load): [len:u32LE][via_bytes] → [result:u8]
                let len = match read_u32(&mut inn) {
                    Ok(n) => n as usize,
                    Err(_) => break,
                };
                let mut via_bytes = vec![0u8; len];
                if inn.read_exact(&mut via_bytes).is_err() {
                    break;
                }

                let result = unsafe {
                    // → ghost.dll の load() は HGLOBAL を GlobalFree するにゃ
                    let h = GlobalAlloc(GMEM_FIXED, len) as HGLOBAL;
                    let ptr = GlobalLock(h) as *mut u8;
                    core::ptr::copy_nonoverlapping(via_bytes.as_ptr(), ptr, len);
                    GlobalUnlock(h);
                    f_load(h, len as i32)
                };

                let _ = out.write_all(&[if result != 0 { 1u8 } else { 0u8 }]);
                let _ = out.flush();
            }
            2 => {
                // EXONERARE(unload): 終了にゃ
                unsafe { f_unload() };
                break;
            }
            3 => {
                // ROGARE(request): [len:u32LE][req_bytes] → [resp_len:u32LE][resp_bytes]
                let len = match read_u32(&mut inn) {
                    Ok(n) => n as usize,
                    Err(_) => break,
                };
                let mut req_bytes = vec![0u8; len];
                if inn.read_exact(&mut req_bytes).is_err() {
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
                        None
                    } else {
                        // → 返された HGLOBAL は ghost_host が GlobalFree するにゃ
                        let ptr = GlobalLock(resp_h) as *const u8;
                        let bytes = core::slice::from_raw_parts(ptr, resp_len as usize).to_vec();
                        GlobalUnlock(resp_h);
                        GlobalFree(resp_h as _);
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
            _ => break,
        }
    }
}
