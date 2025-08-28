use _ffi_util::str_util;
use jieba_rs::{Jieba, TokenizeMode};
use std::ffi::{c_char, c_int};

const NVIQ_JIEBA_ERR_NO_ERRORS: i32 = 0;
const NVIQ_JIEBA_ERR_FAILED: i32 = 1;
const NVIQ_JIEBA_ERR_INVALID_POINTER: i32 = 2;

#[unsafe(no_mangle)]
pub extern "C" fn nviq_jieba_new() -> Box<Jieba> {
    Box::new(Jieba::new())
}

#[unsafe(no_mangle)]
pub extern "C" fn nviq_jieba_pos(
    jieba: Option<&Jieba>,
    line: *const c_char,
    pos: c_int,
    start: *mut c_int,
    end: *mut c_int,
) -> c_int {
    let jb_obj = match jieba {
        Some(v) => v,
        None => return NVIQ_JIEBA_ERR_INVALID_POINTER,
    };

    let sentence = match str_util::char_buf_to_string(line) {
        Ok(s) => s,
        Err(_) => return NVIQ_JIEBA_ERR_FAILED,
    };

    let tokens = jb_obj.tokenize(&sentence, TokenizeMode::Default, false);

    for token in tokens {
        let tk_start: c_int = match token.start.try_into() {
            Ok(v) => v,
            Err(_) => return NVIQ_JIEBA_ERR_FAILED,
        };

        let tk_end: c_int = match token.end.try_into() {
            Ok(v) => v,
            Err(_) => return NVIQ_JIEBA_ERR_FAILED,
        };

        if tk_start <= pos && tk_end > pos {
            unsafe {
                start.write(tk_start);
                end.write(tk_end);
            }

            return NVIQ_JIEBA_ERR_NO_ERRORS;
        }
    }

    NVIQ_JIEBA_ERR_FAILED
}

#[unsafe(no_mangle)]
pub extern "C" fn nviq_jieba_drop(_: Option<Box<Jieba>>) {}
