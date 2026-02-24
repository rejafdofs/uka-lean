/*! proxy32.c の Rust 版にゃん♪
 * 32-bit DLL として SSP に讀み込まれ、ghost.exe へパイプで仕事を丸投げするにゃ
 */
#![allow(non_snake_case)]

use std::io::{Read, Write};
use std::process::{Child, ChildStdin, ChildStdout, Command, Stdio};
use std::sync::Mutex;
use windows_sys::Win32::Foundation::{GlobalFree, BOOL};
use windows_sys::Win32::Globalization::{
    MultiByteToWideChar, WideCharToMultiByte, CP_ACP, CP_UTF8,
};
use windows_sys::Win32::System::Memory::{GlobalAlloc, GlobalLock, GlobalUnlock, GMEM_FIXED};

type HGLOBAL = *mut core::ffi::c_void;

macro_rules! log_trace {
    ($($arg:tt)*) => {
        if let Ok(mut file) = std::fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open("proxy32_trace.txt")
        {
            use std::io::Write;
            let _ = writeln!(file, $($arg)*);
        }
    };
}

// にゃ：SSP は Windows ANSI(CP_ACP) でパスを渡すにゃ。Shift_JIS 等でも正しく變換するにゃ
fn ansi_bytes_to_string(bytes: &[u8]) -> String {
    // 末尾のヌル・バックスラッシュを取り除くにゃ
    let trimmed = match bytes.iter().rposition(|&b| b != 0 && b != b'\\') {
        Some(pos) => &bytes[..=pos],
        None => return String::new(),
    };
    // CP_ACP = 0
    let wlen = unsafe {
        MultiByteToWideChar(
            CP_ACP,
            0,
            trimmed.as_ptr() as _,
            trimmed.len() as i32,
            core::ptr::null_mut(),
            0,
        )
    };
    if wlen <= 0 {
        return String::from_utf8_lossy(trimmed).into_owned();
    }
    let mut wbuf = vec![0u16; wlen as usize];
    unsafe {
        MultiByteToWideChar(
            CP_ACP,
            0,
            trimmed.as_ptr() as _,
            trimmed.len() as i32,
            wbuf.as_mut_ptr(),
            wlen,
        );
    }
    String::from_utf16_lossy(&wbuf)
}

// Windows ANSI(Shift_JIS) のバイト列を UTF-8文字列のバイト列に變換するにゃん
fn ansi_to_utf8_bytes(bytes: &[u8]) -> Vec<u8> {
    let wlen = unsafe {
        MultiByteToWideChar(
            CP_ACP,
            0,
            bytes.as_ptr() as _,
            bytes.len() as i32,
            core::ptr::null_mut(),
            0,
        )
    };
    if wlen <= 0 {
        return bytes.to_vec(); // フォールバック(代替)にゃ
    }
    let mut wbuf = vec![0u16; wlen as usize];
    unsafe {
        MultiByteToWideChar(
            CP_ACP,
            0,
            bytes.as_ptr() as _,
            bytes.len() as i32,
            wbuf.as_mut_ptr(),
            wlen,
        );
    }

    let u8len = unsafe {
        WideCharToMultiByte(
            CP_UTF8,
            0,
            wbuf.as_ptr(),
            wlen,
            core::ptr::null_mut(),
            0,
            core::ptr::null_mut(),
            core::ptr::null_mut(),
        )
    };
    if u8len <= 0 {
        return bytes.to_vec();
    }
    let mut u8buf = vec![0u8; u8len as usize];
    unsafe {
        WideCharToMultiByte(
            CP_UTF8,
            0,
            wbuf.as_ptr(),
            wlen,
            u8buf.as_mut_ptr() as _,
            u8len,
            core::ptr::null_mut(),
            core::ptr::null_mut(),
        );
    }
    u8buf
}

// UTF-8文字列のバイト列を Windows ANSI(Shift_JIS) のバイト列に變換するにゃん
fn utf8_to_ansi_bytes(bytes: &[u8]) -> Vec<u8> {
    let wlen = unsafe {
        MultiByteToWideChar(
            CP_UTF8,
            0,
            bytes.as_ptr() as _,
            bytes.len() as i32,
            core::ptr::null_mut(),
            0,
        )
    };
    if wlen <= 0 {
        return bytes.to_vec();
    }
    let mut wbuf = vec![0u16; wlen as usize];
    unsafe {
        MultiByteToWideChar(
            CP_UTF8,
            0,
            bytes.as_ptr() as _,
            bytes.len() as i32,
            wbuf.as_mut_ptr(),
            wlen,
        );
    }

    let ansi_len = unsafe {
        WideCharToMultiByte(
            CP_ACP,
            0,
            wbuf.as_ptr(),
            wlen,
            core::ptr::null_mut(),
            0,
            core::ptr::null_mut(),
            core::ptr::null_mut(),
        )
    };
    if ansi_len <= 0 {
        return bytes.to_vec();
    }
    let mut ansi_buf = vec![0u8; ansi_len as usize];
    unsafe {
        WideCharToMultiByte(
            CP_ACP,
            0,
            wbuf.as_ptr(),
            wlen,
            ansi_buf.as_mut_ptr() as _,
            ansi_len,
            core::ptr::null_mut(),
            core::ptr::null_mut(),
        );
    }
    ansi_buf
}

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
    log_trace!("=== load called (len={}) ===", len);
    // ① ディレクトーリウム文字列を取り出して HGLOBAL を開放するにゃ
    let via_bytes = {
        let ptr = GlobalLock(h) as *const u8;
        let bytes = core::slice::from_raw_parts(ptr, len as usize).to_vec();
        GlobalUnlock(h);
        GlobalFree(h);
        bytes
    };

    let via = ansi_bytes_to_string(&via_bytes);
    if via.is_empty() {
        log_trace!("load failed: ansi_bytes_to_string empty");
        return 0;
    }
    log_trace!("load via: {}", via);

    // ② ghost.exe を起動するにゃ（同じディレクトーリウムにあるはずにゃ）
    let host_via = format!("{via}\\ghost.exe");
    let mut filius = match Command::new(&host_via)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .spawn()
    {
        Ok(c) => c,
        Err(e) => {
            log_trace!("load failed: failed to spawn ghost.exe: {}", e);
            return 0;
        }
    };
    let mut calamus = filius.stdin.take().unwrap();
    let mut rivus = filius.stdout.take().unwrap();

    // ③ ONERARE(load) 命令を送るにゃ: [1u8][len:u32LE][bytes]
    let ok = calamus.write_all(&[1u8]).is_ok()
        && scribe_u32(&mut calamus, via_bytes.len() as u32).is_ok()
        && calamus.write_all(&via_bytes).is_ok()
        && calamus.flush().is_ok();
    if !ok {
        log_trace!("load failed: pipe write error");
        return 0;
    }

    // ④ 應答: [0/1: u8]
    let mut resp = [0u8; 1];
    if rivus.read_exact(&mut resp).is_err() || resp[0] == 0 {
        log_trace!("load failed: ghost_host returned false or pipe closed");
        return 0;
    }

    log_trace!("load success");
    *NEXUS.lock().unwrap() = Some(Nexus {
        filius,
        calamus,
        rivus,
    });
    1
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn unload() -> BOOL {
    log_trace!("=== unload called ===");
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
    log_trace!("=== request called (len={}) ===", *len);
    // *len は入力時に要求文字列の長さにゃ（GlobalSize ではないにゃん！）
    let rogatio_len = (*len) as usize;
    let raw_rogatio = {
        let ptr = GlobalLock(h) as *const u8;
        let bytes = core::slice::from_raw_parts(ptr, rogatio_len).to_vec();
        GlobalUnlock(h);
        GlobalFree(h);
        bytes
    };

    // SSP から來た要求が Shift_JIS(ANSI) か UTF-8 か判定するにゃ（Charset: UTF-8 が無ければ ANSI と看做す）
    let is_utf8 = if let Ok(s) = core::str::from_utf8(&raw_rogatio) {
        s.contains("Charset: UTF-8") || s.contains("Charset: utf-8")
    } else {
        false
    };

    let rogatio = if is_utf8 {
        log_trace!("request is UTF-8");
        log_trace!("REQUEST:\n{}", String::from_utf8_lossy(&raw_rogatio));
        raw_rogatio
    } else {
        log_trace!("request is ANSI(Shift_JIS) -> converting to UTF-8");
        // Shift_JIS -> UTF-8 變換をかませるにゃ！ Lean 側は常に UTF-8 として處理できるやうになるにゃ♪
        let u8b = ansi_to_utf8_bytes(&raw_rogatio);
        log_trace!("REQUEST (UTF-8 conv):\n{}", String::from_utf8_lossy(&u8b));
        u8b
    };

    let mut guard = NEXUS.lock().unwrap();
    let n = match guard.as_mut() {
        Some(n) => n,
        None => {
            log_trace!("request failed: no NEXUS (not loaded)");
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
        log_trace!("request failed: write to ghost_host pipe failed");
        *len = 0;
        return core::ptr::null_mut();
    }

    // 應答(responsum)
    let resp_len = match lege_u32(&mut n.rivus) {
        Ok(v) => v as usize,
        Err(_) => {
            log_trace!("request failed: failed to read resp_len from ghost_host");
            *len = 0;
            return core::ptr::null_mut();
        }
    };

    if resp_len == 0 {
        log_trace!("request: resp_len was 0");
        *len = 0;
        return core::ptr::null_mut();
    }

    let mut u8_resp = vec![0u8; resp_len];
    if n.rivus.read_exact(&mut u8_resp).is_err() {
        log_trace!(
            "request failed: failed to read {} bytes from ghost_host",
            resp_len
        );
        *len = 0;
        return core::ptr::null_mut();
    }

    // ghost.dll(Lean) は UTF-8 で應答を返すにゃ。元が ANSI なら Shift_JIS に變換して返すにゃん！
    let final_resp = if is_utf8 {
        log_trace!("RESP (UTF-8 pass-through): len={}", u8_resp.len());
        u8_resp
    } else {
        let ansi_r = utf8_to_ansi_bytes(&u8_resp);
        log_trace!(
            "RESP (ANSI conv): len={} -> {}",
            u8_resp.len(),
            ansi_r.len()
        );
        ansi_r
    };
    let final_len = final_resp.len();

    let out_h = GlobalAlloc(GMEM_FIXED, final_len) as HGLOBAL;
    if out_h.is_null() {
        log_trace!("request failed: GlobalAlloc returned NULL");
        *len = 0;
        return core::ptr::null_mut();
    }

    let slice = core::slice::from_raw_parts_mut(out_h as *mut u8, final_len);
    slice.copy_from_slice(&final_resp);

    *len = final_len as i32;
    log_trace!("=== request done ===");
    out_h
}
