#[cfg(target_os = "windows")]
mod windows;

mod layout;

#[unsafe(no_mangle)]
pub extern "C" fn nviq_ime_get() -> layout::Layout {
    #[cfg(target_os = "windows")]
    windows::get_input_method()
}

#[unsafe(no_mangle)]
pub extern "C" fn nviq_ime_set(layout: layout::Layout) {
    #[cfg(target_os = "windows")]
    windows::set_input_method(layout);
}
