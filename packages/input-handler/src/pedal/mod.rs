mod handlers;
mod state;

pub use handlers::{handle_central_pedal, handle_left_pedal, handle_right_pedal};
pub use state::{Pedal, Pedals};
