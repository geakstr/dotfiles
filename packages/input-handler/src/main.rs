#[cfg(target_os = "macos")]
use hidapi::HidApi;

#[cfg(target_os = "macos")]
mod pedal;
mod platform;

#[cfg(target_os = "linux")]
mod keyboard;

#[cfg(target_os = "macos")]
#[tokio::main]
async fn main() {
    run_pedal_controller().await;
}

#[cfg(target_os = "linux")]
fn main() {
    if let Err(e) = keyboard::run() {
        eprintln!("Keyboard remapper error: {}", e);
        std::process::exit(1);
    }
}

#[cfg(target_os = "macos")]
async fn run_pedal_controller() {
    let pedal_vendor_id = 0x0FD9;
    let pedal_product_id = 0x0086;
    let pedal_usb = HidApi::new()
        .expect("Failed to create HID API instance")
        .open(pedal_vendor_id, pedal_product_id)
        .expect("Failed to open the pedal HID device");

    let mut pedals = pedal::Pedals::new();

    let mut pedal_input_buf = [0u8; 64];
    loop {
        match pedal_usb.read(&mut pedal_input_buf) {
            Ok(_) => {
                handle_pedals_input(&mut pedals, pedal_input_buf).await;
            }
            Err(e) => {
                println!("Error reading from pedal: {}", e);
                break;
            }
        }
    }
}

#[cfg(target_os = "macos")]
async fn handle_pedals_input(pedals: &mut pedal::Pedals, pedal_input_buf: [u8; 64]) {
    let is_left_pressed = pedal_input_buf[4] == 1;
    let is_central_pressed = pedal_input_buf[5] == 1;
    let is_right_pressed = pedal_input_buf[6] == 1;

    pedals
        .start_update(is_left_pressed, is_central_pressed, is_right_pressed)
        .await;

    pedal::handle_left_pedal(pedals.left.clone()).await;
    pedal::handle_central_pedal(pedals.central.clone()).await;
    pedal::handle_right_pedal(pedals.right.clone()).await;

    pedals.finish_update().await;
}
