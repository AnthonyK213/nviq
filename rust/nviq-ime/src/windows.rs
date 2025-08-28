use crate::layout::*;
use winapi::um::winuser;

pub(crate) fn get_input_method() -> Layout {
    unsafe {
        let hwnd = winuser::GetForegroundWindow();
        if !hwnd.is_null() {
            let thread_id = winuser::GetWindowThreadProcessId(hwnd, std::ptr::null_mut());
            let current_layout = winuser::GetKeyboardLayout(thread_id) as usize;
            (current_layout & 0x0000FFFF) as Layout
        } else {
            0
        }
    }
}

pub(crate) fn set_input_method(layout: Layout) {
    unsafe {
        let hwnd = winuser::GetForegroundWindow();
        if !hwnd.is_null() {
            let current_layout = winapi::shared::minwindef::LPARAM::try_from(layout);
            if let Ok(lparam) = current_layout {
                winuser::PostMessageA(hwnd, winuser::WM_INPUTLANGCHANGEREQUEST, 0, lparam);
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_sets_current_input_method_to_en_us() {
        set_input_method(NVIQ_IME_LAYOUT_US);
        std::thread::sleep(std::time::Duration::from_secs(2));
        assert_eq!(NVIQ_IME_LAYOUT_US, get_input_method());
    }
}
