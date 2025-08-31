#[cfg(target_os = "windows")]
mod windows;

#[cfg(target_os = "macos")]
mod macos;

mod typedef;

#[unsafe(no_mangle)]
pub extern "C" fn nviq_ime_get() -> typedef::Source {
    #[cfg(target_os = "windows")]
    return windows::get_input_source();

    #[cfg(target_os = "macos")]
    return macos::get_input_source();

    #[cfg(not(any(target_os = "windows", target_os = "macos")))]
    return typedef::NVIQ_IME_LAYOUT_NONE;
}

#[unsafe(no_mangle)]
pub extern "C" fn nviq_ime_set(source: typedef::Source) {
    #[cfg(target_os = "windows")]
    windows::get_input_source(source);

    #[cfg(target_os = "macos")]
    macos::set_input_source(source);
}
