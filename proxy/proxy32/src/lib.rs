/*! proxy32.c の Rust 版にゃん♪
 * 32-bit DLL として SSP に讀み込まれ、ghost.exe へパイプで仕事を丸投げするにゃ
 */
#![allow(non_snake_case)]

use std::io::{Read, Write};
use std::process::{Child, ChildStdin, ChildStdout, Command, Stdio};
use std::sync::Mutex;
use windows_sys::Win32::Foundation::{GlobalFree, BOOL};
use windows_sys::Win32::System::Memory::{GlobalAlloc, GlobalLock, GlobalUnlock, GMEM_FIXED};

type HGLOBAL = *mut core::ffi::c_void;

// にゃ：SSP は基本的に單一スレッドで SHIORI を呼ぶので Mutex で十分にゃ
struct Nexus {
    filius: Child,
    calamus: ChildStdin, // 子プロケッスス stdin
    rivus: ChildStdout,  // 子プロケッスス stdout
}

static NEXUS: Mutex<Option<Nexus>> = Mutex::new(None);

fn scribe_u32(w: &mut impl Write, v: u32) -> std::io::Result<()> {
    w.write_all(&v.to_le_bytes())
}

fn lege_u32(r: &mut impl Read) -> std::io::Result<u32> {
    let mut b = [0u8; 4];
    r.read_exact(&mut b)?;
    Ok(u32::from_le_bytes(b))
}

// SSP は HGLOBAL に格納された文字列 + 長さを渡す。戻り値は BOOL にゃ
#[unsafe(no_mangle)]
pub unsafe extern "C" fn load(h: HGLOBAL, len: i32) -> BOOL {
    // ① ディレクトーリウム文字列を取り出して HGLOBAL を開放するにゃ
    let via_bytes = {
        let ptr = GlobalLock(h) as *const u8;
        let bytes = core::slice::from_raw_parts(ptr, len as usize).to_vec();
        GlobalUnlock(h);
        GlobalFree(h);
        bytes
    };

    let via = match core::str::from_utf8(&via_bytes) {
        Ok(s) => s.trim_end_matches(['\0', '\\']).to_owned(),
        Err(_) => return 0,
    };

    // ② ghost.exe を起動するにゃ（同じディレクトーリウムにあるはずにゃ）
    let host_via = format!("{via}\\ghost.exe");
    let mut filius = match Command::new(&host_via)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
    {
        Ok(c) => c,
        Err(_) => return 0,
    };
    let mut calamus = filius.stdin.take().unwrap();
    let mut rivus = filius.stdout.take().unwrap();

    // ③ ONERARE(load) 命令を送るにゃ: [1u8][len:u32LE][bytes]
    let ok = calamus.write_all(&[1u8]).is_ok()
        && scribe_u32(&mut calamus, via_bytes.len() as u32).is_ok()
        && calamus.write_all(&via_bytes).is_ok()
        && calamus.flush().is_ok();
    if !ok {
        return 0;
    }

    // ④ 應答: [0/1: u8]
    let mut resp = [0u8; 1];
    if rivus.read_exact(&mut resp).is_err() || resp[0] == 0 {
        return 0;
    }

    *NEXUS.lock().unwrap() = Some(Nexus {
        filius,
        calamus,
        rivus,
    });
    1
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn unload() -> BOOL {
    if let Some(mut n) = NEXUS.lock().unwrap().take() {
        // ONERARE 終了命令: [2u8]
        let _ = n.calamus.write_all(&[2u8]);
        let _ = n.calamus.flush();
        let _ = n.filius.wait();
    }
    1
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn request(h: HGLOBAL, len: *mut i32) -> HGLOBAL {
    // *len は入力時に要求文字列の長さにゃ（GlobalSize ではないにゃん！）
    let rogatio_len = (*len) as usize;
    let rogatio = {
        let ptr = GlobalLock(h) as *const u8;
        let bytes = core::slice::from_raw_parts(ptr, rogatio_len).to_vec();
        GlobalUnlock(h);
        GlobalFree(h);
        bytes
    };

    let mut guard = NEXUS.lock().unwrap();
    let n = match guard.as_mut() {
        Some(n) => n,
        None => {
            *len = 0;
            return core::ptr::null_mut();
        }
    };

    // ROGARE(request) 命令: [3u8][len:u32LE][bytes]
    let ok = n.calamus.write_all(&[3u8]).is_ok()
        && scribe_u32(&mut n.calamus, rogatio.len() as u32).is_ok()
        && n.calamus.write_all(&rogatio).is_ok()
        && n.calamus.flush().is_ok();
    if !ok {
        *len = 0;
        return core::ptr::null_mut();
    }

    // 應答: [resp_len:u32LE][bytes]
    let resp_len = match lege_u32(&mut n.rivus) {
        Ok(v) => v as usize,
        Err(_) => {
            *len = 0;
            return core::ptr::null_mut();
        }
    };

    if resp_len == 0 {
        *len = 0;
        return core::ptr::null_mut();
    }

    let out_h = GlobalAlloc(GMEM_FIXED, resp_len) as HGLOBAL;
    if out_h.is_null() {
        // 捨てるにゃ
        let mut sink = vec![0u8; resp_len];
        let _ = n.rivus.read_exact(&mut sink);
        *len = 0;
        return core::ptr::null_mut();
    }

    let slice = core::slice::from_raw_parts_mut(out_h as *mut u8, resp_len);
    if n.rivus.read_exact(slice).is_err() {
        GlobalFree(out_h as _);
        *len = 0;
        return core::ptr::null_mut();
    }

    *len = resp_len as i32;
    out_h
}
