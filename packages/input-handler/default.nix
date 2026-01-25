{
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "input-handler";
  version = "1.0.0";

  src = ./.;

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  meta = {
    description = "Keyboard remapper for Linux using evdev/uinput";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
