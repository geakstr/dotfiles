#[cfg(target_os = "macos")]
mod macos;

#[cfg(target_os = "linux")]
mod linux;

#[cfg(target_os = "macos")]
pub use macos::{list_all_keyboard_layouts, open_app, select_keyboard_layout};

#[cfg(target_os = "linux")]
pub use linux::{is_terminal_focused, switch_to_english, switch_to_russian};
