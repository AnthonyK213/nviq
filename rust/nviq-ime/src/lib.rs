#[cfg(target_os = "windows")]
mod windows;

#[cfg(target_os = "macos")]
mod macos;

mod layout;

#[unsafe(no_mangle)]
pub extern "C" fn nviq_ime_get() -> layout::Layout {
    #[cfg(target_os = "windows")]
    return windows::get_input_method();

    #[cfg(target_os = "macos")]
    return macos::get_input_method();

    layout::NVIQ_IME_LAYOUT_NONE;
}

#[unsafe(no_mangle)]
pub extern "C" fn nviq_ime_set(layout: layout::Layout) {
    #[cfg(target_os = "windows")]
    windows::set_input_method(layout);

    #[cfg(target_os = "macos")]
    macos::set_input_method(layout);
}
