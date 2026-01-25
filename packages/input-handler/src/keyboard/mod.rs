mod device;
mod remapper;
mod virtual_kbd;

pub use device::{find_keyboards, open_keyboard};
pub use remapper::Remapper;
pub use virtual_kbd::VirtualKeyboard;

use evdev::InputEvent;
use inotify::{Inotify, WatchMask};
use nix::fcntl::{fcntl, FcntlArg, OFlag};
use std::os::unix::io::AsRawFd;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::mpsc;
use std::sync::Arc;
use std::thread;
use std::time::Duration;

/// An input event tagged with keyboard identity
pub struct KeyboardEvent {
    pub vendor_id: u16,
    pub product_id: u16,
    pub event: InputEvent,
}

/// Run the keyboard remapping event loop
pub fn run() -> std::io::Result<()> {
    let virtual_kbd = VirtualKeyboard::new()?;
    let mut remapper = Remapper::new(virtual_kbd);

    let (tx, rx) = mpsc::channel::<KeyboardEvent>();

    // Spawn keyboard reader threads with inotify-based reconnection
    spawn_keyboard_readers(tx);

    // Process events from all keyboards
    for kbd_event in rx {
        if let Err(e) = remapper.process_event(kbd_event) {
            eprintln!("Error processing event: {}", e);
        }
    }

    Ok(())
}

/// Spawn reader threads for all keyboards with hot-plug detection
fn spawn_keyboard_readers(tx: mpsc::Sender<KeyboardEvent>) {
    thread::spawn(move || {
        loop {
            // Flag to signal readers to stop (set when devices change)
            let should_stop = Arc::new(AtomicBool::new(false));

            let keyboards = find_keyboards();
            if keyboards.is_empty() {
                eprintln!("No keyboards found, waiting...");
                thread::sleep(Duration::from_secs(1));
                continue;
            }

            eprintln!("Found {} keyboard(s), starting readers", keyboards.len());

            // Spawn reader threads
            let mut handles = Vec::new();
            for info in keyboards {
                let tx = tx.clone();
                let should_stop = Arc::clone(&should_stop);
                let vendor_id = info.vendor_id;
                let product_id = info.product_id;
                let handle = thread::spawn(move || {
                    let mut keyboard = match open_keyboard(&info) {
                        Ok(kb) => kb,
                        Err(e) => {
                            eprintln!("Failed to open keyboard {:?}: {}", info.path, e);
                            return;
                        }
                    };

                    // Set non-blocking mode for timeout support
                    let fd = keyboard.as_raw_fd();
                    if let Err(e) = fcntl(fd, FcntlArg::F_SETFL(OFlag::O_NONBLOCK)) {
                        eprintln!("Failed to set non-blocking mode: {}", e);
                        return;
                    }

                    loop {
                        // Check if we should stop (device change detected)
                        if should_stop.load(Ordering::Relaxed) {
                            eprintln!("Reader stopping due to device change");
                            return;
                        }

                        match keyboard.fetch_events() {
                            Ok(events) => {
                                for event in events {
                                    let kbd_event = KeyboardEvent {
                                        vendor_id,
                                        product_id,
                                        event,
                                    };
                                    if tx.send(kbd_event).is_err() {
                                        return; // Channel closed
                                    }
                                }
                            }
                            Err(e) => {
                                // EAGAIN/EWOULDBLOCK means no events available (non-blocking)
                                if e.kind() == std::io::ErrorKind::WouldBlock {
                                    // Small sleep to avoid busy-waiting
                                    thread::sleep(Duration::from_millis(10));
                                    continue;
                                }
                                eprintln!("Keyboard read error on {:?}: {}", info.path, e);
                                return; // Device disconnected
                            }
                        }
                    }
                });
                handles.push(handle);
            }

            // Spawn inotify watcher thread
            let should_stop_watcher = Arc::clone(&should_stop);
            let watcher_handle = thread::spawn(move || {
                watch_device_changes(should_stop_watcher);
            });

            // Wait for either:
            // 1. All readers to finish (all devices disconnected)
            // 2. Watcher to signal device change
            loop {
                // Check if all reader threads have finished
                let all_finished = handles.iter().all(|h| h.is_finished());
                if all_finished {
                    eprintln!("All keyboard readers finished");
                    break;
                }

                // Check if watcher signaled a device change
                if should_stop.load(Ordering::Relaxed) {
                    eprintln!("Device change detected, restarting readers...");
                    // Wait for reader threads to notice the flag and exit
                    for handle in handles {
                        let _ = handle.join();
                    }
                    break;
                }

                thread::sleep(Duration::from_millis(100));
            }

            // Stop the watcher thread by setting the flag (if not already set)
            should_stop.store(true, Ordering::Relaxed);
            let _ = watcher_handle.join();

            // Brief pause before reconnecting
            thread::sleep(Duration::from_millis(500));
            eprintln!("Reconnecting to keyboards...");
        }
    });
}

/// Watch /dev/input for device changes using inotify
fn watch_device_changes(should_stop: Arc<AtomicBool>) {
    let mut inotify = match Inotify::init() {
        Ok(i) => i,
        Err(e) => {
            eprintln!("Failed to initialize inotify: {}", e);
            return;
        }
    };

    // Watch for device create/delete/attrib changes
    if let Err(e) = inotify.watches().add(
        "/dev/input",
        WatchMask::CREATE | WatchMask::DELETE | WatchMask::ATTRIB,
    ) {
        eprintln!("Failed to add inotify watch: {}", e);
        return;
    }

    let mut buffer = [0u8; 4096];

    loop {
        if should_stop.load(Ordering::Relaxed) {
            return;
        }

        // Use a short timeout to allow checking should_stop flag
        match inotify.read_events(&mut buffer) {
            Ok(events) => {
                for event in events {
                    // Only care about eventN devices
                    if let Some(name) = event.name {
                        let name_str = name.to_string_lossy();
                        if name_str.starts_with("event") {
                            eprintln!("Device change detected: {:?}", name);
                            should_stop.store(true, Ordering::Relaxed);
                            return;
                        }
                    }
                }
            }
            Err(e) => {
                if e.kind() != std::io::ErrorKind::WouldBlock {
                    eprintln!("Inotify read error: {}", e);
                    thread::sleep(Duration::from_secs(1));
                }
            }
        }

        // Small sleep between checks
        thread::sleep(Duration::from_millis(100));
    }
}
