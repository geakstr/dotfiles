mod device;
mod remapper;
mod virtual_kbd;

pub use device::{find_keyboards, open_keyboard};
pub use remapper::Remapper;
pub use virtual_kbd::VirtualKeyboard;

use evdev::InputEvent;
use inotify::{Inotify, WatchMask};
use nix::poll::{poll, PollFd, PollFlags, PollTimeout};
use std::os::fd::BorrowedFd;
use std::os::unix::io::AsRawFd;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::mpsc;
use std::sync::Arc;
use std::thread;
use std::time::{Duration, Instant};

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

                    let raw_fd = keyboard.as_raw_fd();

                    loop {
                        if should_stop.load(Ordering::Relaxed) {
                            eprintln!("Reader stopping due to device change");
                            return;
                        }

                        // Block until the fd is readable or 200ms timeout (to check should_stop)
                        // SAFETY: keyboard is alive for the entire loop, fd remains valid
                        let borrowed_fd = unsafe { BorrowedFd::borrow_raw(raw_fd) };
                        let mut poll_fds = [PollFd::new(borrowed_fd, PollFlags::POLLIN)];
                        match poll(&mut poll_fds, PollTimeout::from(200u16)) {
                            Ok(0) => continue,
                            Ok(_) => {}
                            Err(nix::errno::Errno::EINTR) => continue,
                            Err(e) => {
                                eprintln!("Poll error on {:?}: {}", info.path, e);
                                return;
                            }
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
                                        return;
                                    }
                                }
                            }
                            Err(e) => {
                                eprintln!("Keyboard read error on {:?}: {}", info.path, e);
                                return;
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

            // Wait for device enumeration to settle before reconnecting
            eprintln!("Waiting for device enumeration to settle...");
            thread::sleep(Duration::from_secs(2));
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

    let raw_fd = inotify.as_raw_fd();
    let mut buffer = [0u8; 4096];
    let mut debounce_deadline: Option<Instant> = None;
    const DEBOUNCE_DURATION: Duration = Duration::from_secs(1);

    loop {
        if should_stop.load(Ordering::Relaxed) {
            return;
        }

        // Check if debounce timer expired
        if let Some(deadline) = debounce_deadline {
            if Instant::now() >= deadline {
                eprintln!("Device changes settled, signaling reconnect");
                should_stop.store(true, Ordering::Relaxed);
                return;
            }
        }

        // Wait for inotify events with poll instead of busy-waiting
        let timeout = match debounce_deadline {
            Some(deadline) => {
                let remaining = deadline.saturating_duration_since(Instant::now());
                PollTimeout::from(remaining.as_millis().min(1000) as u16)
            }
            None => PollTimeout::from(1000u16),
        };
        // SAFETY: inotify is alive for the entire loop, fd remains valid
        let borrowed_fd = unsafe { BorrowedFd::borrow_raw(raw_fd) };
        let mut poll_fds = [PollFd::new(borrowed_fd, PollFlags::POLLIN)];
        match poll(&mut poll_fds, timeout) {
            Ok(0) => continue,
            Ok(_) => {}
            Err(nix::errno::Errno::EINTR) => continue,
            Err(e) => {
                eprintln!("Inotify poll error: {}", e);
                return;
            }
        }

        match inotify.read_events(&mut buffer) {
            Ok(events) => {
                for event in events {
                    if let Some(name) = event.name {
                        let name_str = name.to_string_lossy();
                        if name_str.starts_with("event") {
                            eprintln!("Device change detected: {:?}", name);
                            debounce_deadline = Some(Instant::now() + DEBOUNCE_DURATION);
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
    }
}
