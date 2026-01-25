#!/usr/bin/env rust-script
//! Simple brightness control using brightnessctl

use std::env;
use std::process::{Command, Stdio};

const STEP: u8 = 5;

fn get_brightness_pct() -> Option<u8> {
    let output = Command::new("brightnessctl")
        .args(["-m", "info"])
        .stderr(Stdio::null())
        .output()
        .ok()?;

    let stdout = String::from_utf8_lossy(&output.stdout);
    // Format: "device,class,current,percentage,max"
    let parts: Vec<&str> = stdout.trim().split(',').collect();
    if parts.len() >= 4 {
        return parts[3].trim_end_matches('%').parse().ok();
    }
    None
}

fn main() {
    let arg = match env::args().nth(1).as_deref() {
        Some("up") => format!("{}%+", STEP),
        Some("down") => format!("{}%-", STEP),
        _ => return,
    };

    Command::new("brightnessctl")
        .args(["set", &arg])
        .stderr(Stdio::null())
        .stdout(Stdio::null())
        .status()
        .ok();

    if let Some(pct) = get_brightness_pct() {
        Command::new("notify-send")
            .args([
                "-h", "string:x-canonical-private-synchronous:brightness",
                "-t", "1500",
                &format!("Brightness: {}%", pct),
            ])
            .spawn()
            .ok();
    }
}
