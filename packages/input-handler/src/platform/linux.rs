use std::fs;
use std::process::Command;

/// Find the Sway IPC socket path
fn find_swaysock() -> Option<String> {
    // First check environment variable
    if let Ok(sock) = std::env::var("SWAYSOCK") {
        if std::path::Path::new(&sock).exists() {
            return Some(sock);
        }
    }

    // Try to find it in /run/user/<uid>/
    let uid = unsafe { libc::getuid() };
    let user_run_dir = format!("/run/user/{}", uid);

    if let Ok(entries) = fs::read_dir(&user_run_dir) {
        for entry in entries.flatten() {
            let name = entry.file_name();
            let name_str = name.to_string_lossy();
            if name_str.starts_with("sway-ipc.") && name_str.ends_with(".sock") {
                return Some(entry.path().to_string_lossy().to_string());
            }
        }
    }

    None
}

/// Get potential paths for swaymsg binary
fn get_swaymsg_paths() -> Vec<String> {
    let mut paths = Vec::new();

    // NixOS per-user profile path
    if let Ok(user) = std::env::var("USER") {
        paths.push(format!("/etc/profiles/per-user/{}/bin/swaymsg", user));
    }

    // Common system paths
    paths.push("/run/current-system/sw/bin/swaymsg".to_string());
    paths.push("/usr/bin/swaymsg".to_string());
    paths.push("swaymsg".to_string());

    paths
}

/// Switch keyboard layout in Sway
/// index 0 = first layout (e.g., English)
/// index 1 = second layout (e.g., Russian)
pub fn switch_layout(index: u8) {
    let swaysock = match find_swaysock() {
        Some(sock) => sock,
        None => {
            eprintln!("Could not find SWAYSOCK");
            return;
        }
    };

    let swaymsg_paths = get_swaymsg_paths();

    for path in &swaymsg_paths {
        let result = Command::new(path)
            .env("SWAYSOCK", &swaysock)
            .arg("input")
            .arg("*")
            .arg("xkb_switch_layout")
            .arg(index.to_string())
            .output();

        match result {
            Ok(output) if output.status.success() => {
                return;
            }
            Ok(_) => {
                eprintln!("swaymsg failed with non-zero exit");
            }
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => {
                continue; // Try next path
            }
            Err(e) => {
                eprintln!("Failed to run swaymsg: {}", e);
            }
        }
    }

    eprintln!("Could not find working swaymsg");
}

pub fn switch_to_english() {
    switch_layout(0);
}

pub fn switch_to_russian() {
    switch_layout(1);
}

/// Check if the currently focused window is a terminal application
pub fn is_terminal_focused() -> bool {
    let swaysock = match find_swaysock() {
        Some(sock) => sock,
        None => return false,
    };

    let swaymsg_paths = get_swaymsg_paths();

    for path in &swaymsg_paths {
        let result = Command::new(path)
            .env("SWAYSOCK", &swaysock)
            .arg("-t")
            .arg("get_tree")
            .output();

        match result {
            Ok(output) if output.status.success() => {
                let json = String::from_utf8_lossy(&output.stdout);
                if let Some(focused_app) = extract_focused_app_id(&json) {
                    let terminal_apps = [
                        "foot",
                        "alacritty",
                        "kitty",
                        "wezterm",
                        "gnome-terminal",
                        "konsole",
                        "terminator",
                        "xterm",
                        "urxvt",
                        "st",
                        "tilix",
                        "terminology",
                        "ghostty",
                    ];
                    return terminal_apps
                        .iter()
                        .any(|&app| focused_app.to_lowercase().contains(app));
                }
                return false;
            }
            Ok(_) => continue,
            Err(e) if e.kind() == std::io::ErrorKind::NotFound => continue,
            Err(_) => continue,
        }
    }

    false
}

/// Extract the app_id of the focused window from sway tree JSON
fn extract_focused_app_id(json: &str) -> Option<String> {
    let bytes = json.as_bytes();
    let focused_pattern = b"\"focused\": true";

    let mut pos = 0;
    while let Some(idx) = find_subsequence(&bytes[pos..], focused_pattern) {
        let abs_pos = pos + idx;
        let search_end = (abs_pos + 2500).min(json.len());
        let search_region = &json[abs_pos..search_end];

        if let Some(app_id) = extract_string_field_forward(search_region, "app_id") {
            if !app_id.is_empty() {
                return Some(app_id);
            }
        }

        // Also check class (for X11 apps via XWayland)
        if let Some(class) = extract_string_field_forward(search_region, "class") {
            if !class.is_empty() {
                return Some(class);
            }
        }

        pos = abs_pos + focused_pattern.len();
    }

    None
}

fn find_subsequence(haystack: &[u8], needle: &[u8]) -> Option<usize> {
    haystack.windows(needle.len()).position(|window| window == needle)
}

fn extract_string_field_forward(text: &str, field: &str) -> Option<String> {
    let pattern = format!("\"{}\": \"", field);
    if let Some(start) = text.find(&pattern) {
        let value_start = start + pattern.len();
        if let Some(end) = text[value_start..].find('"') {
            return Some(text[value_start..value_start + end].to_string());
        }
    }
    None
}
