use crate::keyboard::virtual_kbd::VirtualKeyboard;
use crate::keyboard::KeyboardEvent;
use crate::platform;
use evdev::{EventType, InputEvent, InputEventKind, Key};
use std::collections::HashSet;

// Keychron keyboard identification
const KEYCHRON_VENDOR_ID: u16 = 0x3434;
const KEYCHRON_PRODUCT_ID: u16 = 0xd030;

/// Tracks state for a tap-or-hold modifier key
struct TapHoldKey {
    held: bool,
    used_as_modifier: bool,
}

impl TapHoldKey {
    fn new() -> Self {
        Self {
            held: false,
            used_as_modifier: false,
        }
    }

    fn press(&mut self) {
        self.held = true;
        self.used_as_modifier = false;
    }

    fn release(&mut self) -> bool {
        let was_tap = !self.used_as_modifier;
        self.held = false;
        self.used_as_modifier = false;
        was_tap
    }

    fn mark_used(&mut self) {
        if self.held {
            self.used_as_modifier = true;
        }
    }

    fn is_held(&self) -> bool {
        self.held
    }
}

/// Tracks the state of modifier keys and handles remapping logic
pub struct Remapper {
    caps: TapHoldKey,
    left_meta: TapHoldKey,
    right_meta: TapHoldKey,
    shift_held: bool,
    /// Track if we added shift for terminal copy/paste (need to release it properly)
    added_terminal_shift: bool,
    /// Keys currently in an active CMD→CTRL combo
    cmd_combo_keys: HashSet<Key>,
    /// Keys currently in an active CMD+SHIFT→CTRL+SHIFT combo
    cmd_shift_combo_keys: HashSet<Key>,
    /// Bracket key currently in an active CMD+SHIFT+bracket combo
    cmd_shift_bracket_active: Option<Key>,
    /// Keys currently in an active CAPS+HJKL combo (for arrow key remapping)
    caps_hjkl_keys: HashSet<Key>,
    virtual_kbd: VirtualKeyboard,
}

impl Remapper {
    pub fn new(virtual_kbd: VirtualKeyboard) -> Self {
        Self {
            caps: TapHoldKey::new(),
            left_meta: TapHoldKey::new(),
            right_meta: TapHoldKey::new(),
            shift_held: false,
            added_terminal_shift: false,
            cmd_combo_keys: HashSet::new(),
            cmd_shift_combo_keys: HashSet::new(),
            cmd_shift_bracket_active: None,
            caps_hjkl_keys: HashSet::new(),
            virtual_kbd,
        }
    }

    /// Check if the event came from a Keychron keyboard
    fn is_keychron(vendor_id: u16, product_id: u16) -> bool {
        vendor_id == KEYCHRON_VENDOR_ID && product_id == KEYCHRON_PRODUCT_ID
    }

    /// Swap alt and win/meta keys for Keychron keyboard
    fn swap_alt_win(event: InputEvent) -> InputEvent {
        if let InputEventKind::Key(key) = event.kind() {
            let new_key = match key {
                Key::KEY_LEFTALT => Some(Key::KEY_LEFTMETA),
                Key::KEY_RIGHTALT => Some(Key::KEY_RIGHTMETA),
                Key::KEY_LEFTMETA => Some(Key::KEY_LEFTALT),
                Key::KEY_RIGHTMETA => Some(Key::KEY_RIGHTALT),
                _ => None,
            };
            if let Some(new_key) = new_key {
                return InputEvent::new(EventType::KEY, new_key.code(), event.value());
            }
        }
        event
    }

    /// Process an input event and emit the appropriate remapped events
    pub fn process_event(&mut self, kbd_event: KeyboardEvent) -> std::io::Result<bool> {
        // Apply alt/win swap for all keyboards EXCEPT Keychron
        let event = if !Self::is_keychron(kbd_event.vendor_id, kbd_event.product_id) {
            Self::swap_alt_win(kbd_event.event)
        } else {
            kbd_event.event
        };

        let key = match event.kind() {
            InputEventKind::Key(k) => k,
            // Drop non-key events (EV_MSC scan codes, SYN_REPORT, etc.)
            // The virtual keyboard emits its own SYN_REPORT after each key event,
            // so forwarding these just creates fragmented event packets.
            _ => return Ok(false),
        };

        let value = event.value(); // 0 = release, 1 = press, 2 = repeat

        // On key release, check if this key is in an active combo and route to correct handler
        // This ensures proper cleanup even if modifiers were released first
        if value == 0 {
            if self.caps_hjkl_keys.contains(&key) {
                self.handle_hjkl(key, value)?;
                return Ok(true);
            }
            if self.cmd_combo_keys.contains(&key) {
                self.handle_cmd_shortcut(key, value)?;
                return Ok(true);
            }
            if self.cmd_shift_combo_keys.contains(&key) {
                self.handle_cmd_shift_key(key, value)?;
                return Ok(true);
            }
            if self.cmd_shift_bracket_active == Some(key) {
                self.handle_cmd_shift_bracket(key, value)?;
                return Ok(true);
            }
        }

        match key {
            Key::KEY_CAPSLOCK => {
                self.handle_capslck(value)?;
                Ok(true)
            }
            Key::KEY_LEFTMETA => {
                self.handle_meta(value, Key::KEY_LEFTMETA, true)?;
                Ok(true)
            }
            Key::KEY_RIGHTMETA => {
                self.handle_meta(value, Key::KEY_RIGHTMETA, false)?;
                Ok(true)
            }
            Key::KEY_LEFTSHIFT | Key::KEY_RIGHTSHIFT => {
                self.shift_held = value == 1 || value == 2;
                self.virtual_kbd.emit_raw(event)?;
                Ok(false)
            }
            Key::KEY_H | Key::KEY_J | Key::KEY_K | Key::KEY_L if self.caps.is_held() => {
                self.handle_hjkl(key, value)?;
                Ok(true)
            }
            key @ (Key::KEY_A
            | Key::KEY_B
            | Key::KEY_C
            | Key::KEY_D
            | Key::KEY_E
            | Key::KEY_F
            | Key::KEY_G
            | Key::KEY_H
            | Key::KEY_I
            | Key::KEY_J
            | Key::KEY_K
            | Key::KEY_L
            | Key::KEY_M
            | Key::KEY_N
            | Key::KEY_O
            | Key::KEY_P
            | Key::KEY_R
            | Key::KEY_S
            | Key::KEY_T
            | Key::KEY_U
            | Key::KEY_V
            | Key::KEY_W
            | Key::KEY_X
            | Key::KEY_Y
            | Key::KEY_Z
            | Key::KEY_SLASH
            | Key::KEY_DOT
            | Key::KEY_COMMA
            | Key::KEY_LEFTBRACE
            | Key::KEY_RIGHTBRACE
            | Key::KEY_ENTER)
                if (self.left_meta.is_held() || self.right_meta.is_held()) && !self.shift_held =>
            {
                self.handle_cmd_shortcut(key, value)?;
                Ok(true)
            }
            key @ (Key::KEY_A
            | Key::KEY_B
            | Key::KEY_C
            | Key::KEY_D
            | Key::KEY_E
            | Key::KEY_F
            | Key::KEY_G
            | Key::KEY_H
            | Key::KEY_I
            | Key::KEY_J
            | Key::KEY_K
            | Key::KEY_L
            | Key::KEY_M
            | Key::KEY_N
            | Key::KEY_O
            | Key::KEY_P
            | Key::KEY_R
            | Key::KEY_S
            | Key::KEY_T
            | Key::KEY_U
            | Key::KEY_V
            | Key::KEY_W
            | Key::KEY_X
            | Key::KEY_Y
            | Key::KEY_Z)
                if (self.left_meta.is_held() || self.right_meta.is_held()) && self.shift_held =>
            {
                self.handle_cmd_shift_key(key, value)?;
                Ok(true)
            }
            Key::KEY_LEFTBRACE | Key::KEY_RIGHTBRACE
                if (self.left_meta.is_held() || self.right_meta.is_held()) && self.shift_held =>
            {
                self.handle_cmd_shift_bracket(key, value)?;
                Ok(true)
            }
            // Disable physical arrow keys
            Key::KEY_UP | Key::KEY_DOWN | Key::KEY_LEFT | Key::KEY_RIGHT => {
                Ok(true) // Consume without emitting
            }
            // F-key swap: make F1-F10 send function keys by default, media keys with Fn
            // Physical F1-F10 (without Fn) send media keys → remap to F-keys
            Key::KEY_BRIGHTNESSDOWN => {
                self.emit_swapped_key(Key::KEY_F1, value)?;
                Ok(true)
            }
            Key::KEY_BRIGHTNESSUP => {
                self.emit_swapped_key(Key::KEY_F2, value)?;
                Ok(true)
            }
            Key::KEY_PREVIOUSSONG => {
                self.emit_swapped_key(Key::KEY_F7, value)?;
                Ok(true)
            }
            Key::KEY_PLAYPAUSE => {
                self.emit_swapped_key(Key::KEY_F8, value)?;
                Ok(true)
            }
            Key::KEY_NEXTSONG => {
                self.emit_swapped_key(Key::KEY_F9, value)?;
                Ok(true)
            }
            Key::KEY_MUTE => {
                self.emit_swapped_key(Key::KEY_F10, value)?;
                Ok(true)
            }
            Key::KEY_VOLUMEDOWN => {
                self.emit_swapped_key(Key::KEY_F11, value)?;
                Ok(true)
            }
            Key::KEY_VOLUMEUP => {
                self.emit_swapped_key(Key::KEY_F12, value)?;
                Ok(true)
            }
            // Physical Fn+F1-F10 send F-keys → remap to media keys
            Key::KEY_F1 => {
                self.emit_swapped_key(Key::KEY_BRIGHTNESSDOWN, value)?;
                Ok(true)
            }
            Key::KEY_F2 => {
                self.emit_swapped_key(Key::KEY_BRIGHTNESSUP, value)?;
                Ok(true)
            }
            Key::KEY_F7 => {
                self.emit_swapped_key(Key::KEY_PREVIOUSSONG, value)?;
                Ok(true)
            }
            Key::KEY_F8 => {
                self.emit_swapped_key(Key::KEY_PLAYPAUSE, value)?;
                Ok(true)
            }
            Key::KEY_F9 => {
                self.emit_swapped_key(Key::KEY_NEXTSONG, value)?;
                Ok(true)
            }
            Key::KEY_F10 => {
                self.emit_swapped_key(Key::KEY_MUTE, value)?;
                Ok(true)
            }
            Key::KEY_F11 => {
                self.emit_swapped_key(Key::KEY_VOLUMEDOWN, value)?;
                Ok(true)
            }
            Key::KEY_F12 => {
                self.emit_swapped_key(Key::KEY_VOLUMEUP, value)?;
                Ok(true)
            }
            _ => {
                if value == 1 {
                    self.left_meta.mark_used();
                    self.right_meta.mark_used();
                }
                // Skip repeat events — sway generates its own repeats at the
                // compositor level, so forwarding kernel repeats through the
                // virtual keyboard causes doubled/irregular repeat streams.
                if value != 2 {
                    self.virtual_kbd.emit_raw(event)?;
                }
                Ok(false)
            }
        }
    }

    fn handle_capslck(&mut self, value: i32) -> std::io::Result<()> {
        match value {
            1 => self.caps.press(),
            0 => {
                if self.caps.release() {
                    self.virtual_kbd.tap(Key::KEY_ESC)?;
                }
            }
            _ => {}
        }
        Ok(())
    }

    fn handle_meta(&mut self, value: i32, key: Key, is_left: bool) -> std::io::Result<()> {
        let meta = if is_left {
            &mut self.left_meta
        } else {
            &mut self.right_meta
        };

        match value {
            1 => {
                meta.press();
                self.virtual_kbd.press(key)?;
            }
            0 => {
                self.virtual_kbd.release(key)?;
                if meta.release() {
                    if is_left {
                        platform::switch_to_english();
                    } else {
                        platform::switch_to_russian();
                    }
                }
            }
            2 => {
                self.virtual_kbd.repeat(key)?;
            }
            _ => {}
        }
        Ok(())
    }

    fn handle_hjkl(&mut self, key: Key, value: i32) -> std::io::Result<()> {
        self.caps.mark_used();

        let arrow = match key {
            Key::KEY_H => Key::KEY_LEFT,
            Key::KEY_J => Key::KEY_DOWN,
            Key::KEY_K => Key::KEY_UP,
            Key::KEY_L => Key::KEY_RIGHT,
            _ => unreachable!(),
        };

        match value {
            1 => {
                self.caps_hjkl_keys.insert(key);
                self.virtual_kbd.press(arrow)?;
            }
            0 => {
                self.caps_hjkl_keys.remove(&key);
                self.virtual_kbd.release(arrow)?;
            }
            2 => self.virtual_kbd.repeat(arrow)?,
            _ => {}
        }
        Ok(())
    }

    fn handle_cmd_shortcut(&mut self, key: Key, value: i32) -> std::io::Result<()> {
        self.left_meta.mark_used();
        self.right_meta.mark_used();

        match value {
            1 => {
                let is_first_combo_key = self.cmd_combo_keys.is_empty();
                self.cmd_combo_keys.insert(key);

                // For C and V in terminals, use CTRL+SHIFT (terminal copy/paste)
                let needs_shift =
                    (key == Key::KEY_C || key == Key::KEY_V) && platform::is_terminal_focused();

                // Only release META and press CTRL on first combo key
                if is_first_combo_key {
                    self.virtual_kbd.release(Key::KEY_LEFTMETA)?;
                    self.virtual_kbd.release(Key::KEY_RIGHTMETA)?;
                    self.virtual_kbd.press(Key::KEY_LEFTCTRL)?;
                }
                if needs_shift {
                    self.virtual_kbd.press(Key::KEY_LEFTSHIFT)?;
                    self.added_terminal_shift = true;
                }
                self.virtual_kbd.press(key)?;
            }
            0 => {
                self.cmd_combo_keys.remove(&key);
                self.virtual_kbd.release(key)?;

                if self.added_terminal_shift {
                    self.virtual_kbd.release(Key::KEY_LEFTSHIFT)?;
                    self.added_terminal_shift = false;
                }

                // Only release CTRL and restore META when last combo key is released
                if self.cmd_combo_keys.is_empty() {
                    self.virtual_kbd.release(Key::KEY_LEFTCTRL)?;
                    // Restore META if user is still physically holding it
                    if self.left_meta.is_held() {
                        self.virtual_kbd.press(Key::KEY_LEFTMETA)?;
                    }
                    if self.right_meta.is_held() {
                        self.virtual_kbd.press(Key::KEY_RIGHTMETA)?;
                    }
                }
            }
            2 => {
                self.virtual_kbd.repeat(key)?;
            }
            _ => {}
        }
        Ok(())
    }

    fn handle_cmd_shift_key(&mut self, key: Key, value: i32) -> std::io::Result<()> {
        self.left_meta.mark_used();
        self.right_meta.mark_used();

        match value {
            1 => {
                let is_first_combo_key = self.cmd_shift_combo_keys.is_empty();
                self.cmd_shift_combo_keys.insert(key);

                // Only release META and press CTRL on first combo key
                if is_first_combo_key {
                    self.virtual_kbd.release(Key::KEY_LEFTMETA)?;
                    self.virtual_kbd.release(Key::KEY_RIGHTMETA)?;
                    self.virtual_kbd.press(Key::KEY_LEFTCTRL)?;
                }
                self.virtual_kbd.press(key)?;
            }
            0 => {
                self.cmd_shift_combo_keys.remove(&key);
                self.virtual_kbd.release(key)?;

                // Only release CTRL and restore META when last combo key is released
                if self.cmd_shift_combo_keys.is_empty() {
                    self.virtual_kbd.release(Key::KEY_LEFTCTRL)?;
                    // Restore META if user is still physically holding it
                    if self.left_meta.is_held() {
                        self.virtual_kbd.press(Key::KEY_LEFTMETA)?;
                    }
                    if self.right_meta.is_held() {
                        self.virtual_kbd.press(Key::KEY_RIGHTMETA)?;
                    }
                }
            }
            2 => {
                self.virtual_kbd.repeat(key)?;
            }
            _ => {}
        }
        Ok(())
    }

    fn emit_swapped_key(&mut self, key: Key, value: i32) -> std::io::Result<()> {
        match value {
            1 => self.virtual_kbd.press(key)?,
            0 => self.virtual_kbd.release(key)?,
            2 => self.virtual_kbd.repeat(key)?,
            _ => {}
        }
        Ok(())
    }

    fn handle_cmd_shift_bracket(&mut self, key: Key, value: i32) -> std::io::Result<()> {
        self.left_meta.mark_used();
        self.right_meta.mark_used();

        // CMD+SHIFT+[ → CTRL+SHIFT+TAB (previous tab)
        // CMD+SHIFT+] → CTRL+TAB (next tab)
        let needs_shift = key == Key::KEY_LEFTBRACE;

        match value {
            1 => {
                self.cmd_shift_bracket_active = Some(key);
                // Release all modifiers first
                self.virtual_kbd.release(Key::KEY_LEFTMETA)?;
                self.virtual_kbd.release(Key::KEY_RIGHTMETA)?;
                self.virtual_kbd.release(Key::KEY_LEFTSHIFT)?;
                self.virtual_kbd.release(Key::KEY_RIGHTSHIFT)?;
                // Now press what we need
                self.virtual_kbd.press(Key::KEY_LEFTCTRL)?;
                if needs_shift {
                    self.virtual_kbd.press(Key::KEY_LEFTSHIFT)?;
                }
                self.virtual_kbd.press(Key::KEY_TAB)?;
            }
            0 => {
                self.cmd_shift_bracket_active = None;
                self.virtual_kbd.release(Key::KEY_TAB)?;
                if needs_shift {
                    self.virtual_kbd.release(Key::KEY_LEFTSHIFT)?;
                }
                self.virtual_kbd.release(Key::KEY_LEFTCTRL)?;
                // Restore modifiers that user is still physically holding
                if self.shift_held {
                    self.virtual_kbd.press(Key::KEY_LEFTSHIFT)?;
                }
                if self.left_meta.is_held() {
                    self.virtual_kbd.press(Key::KEY_LEFTMETA)?;
                }
                if self.right_meta.is_held() {
                    self.virtual_kbd.press(Key::KEY_RIGHTMETA)?;
                }
            }
            2 => {
                self.virtual_kbd.repeat(Key::KEY_TAB)?;
            }
            _ => {}
        }
        Ok(())
    }
}
