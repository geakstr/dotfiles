use crate::pedal::state::Pedal;
use crate::platform;
use enigo::*;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::Mutex;

pub async fn handle_left_pedal(pedal: Arc<Mutex<Pedal>>) {
    let mut pedal_lock = pedal.lock().await;

    if pedal_lock.is_just_pressed() {
        let pedal_clone = pedal.clone();
        pedal_lock.set_future(Some(tokio::spawn(async move {
            println!("Waiting to select Russian keyboard layout...");

            tokio::time::sleep(Duration::from_millis(250)).await;

            // For some reason this keyboard layout appears with different names each time
            platform::select_keyboard_layout(
                "org.sil.ukelele.keyboardlayout.t.keylayout.Russian–IlyaBirmanTypography",
            )
            .unwrap_or_else(|_| {
                platform::select_keyboard_layout(
                    "org.sil.ukelele.keyboardlayout.t.russian–ilyabirmantypography",
                )
                .unwrap()
            });

            println!("Selected Russian keyboard layout");

            pedal_clone.lock().await.set_holding(true);
        })));
    }

    if pedal_lock.is_released() {
        if pedal_lock.is_holding() {
            platform::select_keyboard_layout(
                "org.sil.ukelele.keyboardlayout.t.keylayout.English–IlyaBirmanTypography",
            )
            .unwrap_or_else(|_| {
                platform::select_keyboard_layout(
                    "org.sil.ukelele.keyboardlayout.t.english–ilyabirmantypography",
                )
                .unwrap()
            });
            pedal_lock.set_holding(false);
            println!("Selected English keyboard layout");
        } else {
            platform::open_app("Firefox");
        }
        pedal_lock.set_future(None);
    }
}

pub async fn handle_central_pedal(pedal: Arc<Mutex<Pedal>>) {
    let pedals_lock = pedal.lock().await;

    if pedals_lock.is_released() {
        platform::open_app("Visual Studio Code");
    }
}

pub async fn handle_right_pedal(pedal: Arc<Mutex<Pedal>>) {
    let mut pedal_lock = pedal.lock().await;

    if pedal_lock.is_just_pressed() {
        let pedal_clone = pedal.clone();
        pedal_lock.set_future(Some(tokio::spawn(async move {
            println!("Waiting to enter Vim Insert mode...");

            tokio::time::sleep(Duration::from_millis(250)).await;

            tokio::task::spawn_blocking(move || {
                let mut enigo = Enigo::new(&Settings::default()).unwrap();
                enigo.key(Key::Escape, Direction::Click).unwrap();
                enigo.key(Key::Unicode('i'), Direction::Click).unwrap();
                println!("Entered Vim Insert mode");
            })
            .await
            .unwrap();

            pedal_clone.lock().await.set_holding(true);
        })));
    } else if pedal_lock.is_released() {
        if pedal_lock.is_holding() {
            let mut enigo = Enigo::new(&Settings::default()).unwrap();
            enigo.key(Key::Escape, Direction::Click).unwrap();
            pedal_lock.set_holding(false);
            println!("Exited Vim Insert mode");
        } else {
            platform::open_app("WezTerm");
        }
        pedal_lock.set_future(None);
    }
}
