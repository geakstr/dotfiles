use evdev::{Device, Key, RelativeAxisType};
use std::fs;
use std::path::PathBuf;

/// Information about a detected keyboard device
#[derive(Clone)]
pub struct KeyboardInfo {
    pub path: PathBuf,
    #[allow(dead_code)] // Useful for debugging
    pub name: String,
    pub vendor_id: u16,
    pub product_id: u16,
}

/// Find all keyboard devices in /dev/input/
pub fn find_keyboards() -> Vec<KeyboardInfo> {
    let mut keyboards = Vec::new();

    let input_dir = PathBuf::from("/dev/input");
    if let Ok(entries) = fs::read_dir(&input_dir) {
        for entry in entries.flatten() {
            let path = entry.path();
            if let Some(name) = path.file_name() {
                let name_str = name.to_string_lossy();
                // Only look at eventN devices
                if !name_str.starts_with("event") {
                    continue;
                }

                if let Ok(device) = Device::open(&path) {
                    let name = device.name().unwrap_or("Unknown").to_string();

                    // Skip our own virtual keyboard
                    if name.contains("input-handler") {
                        continue;
                    }

                    // Skip devices with mouse axes (REL_X + REL_Y) — these are
                    // mice/trackballs that happen to also expose keyboard keys
                    if let Some(rel) = device.supported_relative_axes() {
                        if rel.contains(RelativeAxisType::REL_X)
                            && rel.contains(RelativeAxisType::REL_Y)
                        {
                            continue;
                        }
                    }

                    // Check if device has key capabilities (is a keyboard)
                    if let Some(keys) = device.supported_keys() {
                        // A keyboard should have letter keys
                        if keys.contains(Key::KEY_A)
                            && keys.contains(Key::KEY_Z)
                            && keys.contains(Key::KEY_CAPSLOCK)
                        {
                            let input_id = device.input_id();
                            keyboards.push(KeyboardInfo {
                                path,
                                name,
                                vendor_id: input_id.vendor(),
                                product_id: input_id.product(),
                            });
                        }
                    }
                }
            }
        }
    }

    keyboards
}

/// Open a keyboard device with exclusive grab
pub fn open_keyboard(info: &KeyboardInfo) -> Result<Device, std::io::Error> {
    let mut device = Device::open(&info.path)?;

    // Grab the device exclusively so events don't reach other applications
    device.grab()?;

    Ok(device)
}

