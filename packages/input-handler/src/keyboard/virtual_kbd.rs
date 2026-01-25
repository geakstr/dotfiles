use evdev::{uinput::VirtualDeviceBuilder, AttributeSet, EventType, InputEvent, Key, Synchronization};
use std::io;

pub struct VirtualKeyboard {
    device: evdev::uinput::VirtualDevice,
}

impl VirtualKeyboard {
    pub fn new() -> io::Result<Self> {
        // Create a set of all keys we might want to emit
        let mut keys = AttributeSet::<Key>::new();

        // Add all standard keys
        for key in Key::KEY_ESC.code()..=Key::KEY_MICMUTE.code() {
            keys.insert(Key::new(key));
        }

        // Explicitly add arrow keys to ensure they're registered
        keys.insert(Key::KEY_UP);
        keys.insert(Key::KEY_DOWN);
        keys.insert(Key::KEY_LEFT);
        keys.insert(Key::KEY_RIGHT);

        let device = VirtualDeviceBuilder::new()?
            .name("input-handler virtual keyboard")
            .with_keys(&keys)?
            .build()?;

        Ok(Self { device })
    }

    fn sync(&mut self) -> io::Result<()> {
        let sync = InputEvent::new(EventType::SYNCHRONIZATION, Synchronization::SYN_REPORT.0, 0);
        self.device.emit(&[sync])?;
        Ok(())
    }

    /// Emit a key press event
    pub fn press(&mut self, key: Key) -> io::Result<()> {
        let event = InputEvent::new(EventType::KEY, key.code(), 1);
        self.device.emit(&[event])?;
        self.sync()?;
        Ok(())
    }

    /// Emit a key release event
    pub fn release(&mut self, key: Key) -> io::Result<()> {
        let event = InputEvent::new(EventType::KEY, key.code(), 0);
        self.device.emit(&[event])?;
        self.sync()?;
        Ok(())
    }

    /// Emit a key repeat event
    pub fn repeat(&mut self, key: Key) -> io::Result<()> {
        let event = InputEvent::new(EventType::KEY, key.code(), 2);
        self.device.emit(&[event])?;
        self.sync()?;
        Ok(())
    }

    /// Emit a complete key tap (press + release)
    pub fn tap(&mut self, key: Key) -> io::Result<()> {
        self.press(key)?;
        self.release(key)?;
        Ok(())
    }

    /// Emit a raw event (for passing through events unchanged)
    pub fn emit_raw(&mut self, event: InputEvent) -> io::Result<()> {
        self.device.emit(&[event])?;
        self.sync()?;
        Ok(())
    }

}
