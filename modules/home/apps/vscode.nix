{ pkgs, lib, ... }:

let
  sandbox = import ./lib.nix { inherit pkgs lib; };

  rustToolchain = pkgs.rust-bin.nightly.latest.default.override {
    extensions = [ "rust-src" "clippy" "rustfmt" "llvm-tools-preview" ];
    targets = [ "wasm32-unknown-unknown" ];
  };

  vscodeUpdate = pkgs.writeShellScriptBin "code-update" ''
    set -e
    INSTALL_DIR="$HOME/.local/share/vscode"
    TMP_FILE=$(mktemp)
    trap 'rm -f "$TMP_FILE"' EXIT

    echo "Downloading latest VS Code..."
    ${pkgs.curl}/bin/curl -L "https://code.visualstudio.com/sha/download?build=stable&os=linux-x64" -o "$TMP_FILE"

    echo "Extracting to $INSTALL_DIR..."
    mkdir -p "$INSTALL_DIR"
    ${pkgs.gnutar}/bin/tar -xzf "$TMP_FILE" --strip-components=1 -C "$INSTALL_DIR"

    echo "VS Code updated successfully!"
  '';

  vscodeSandboxed = sandbox.mkSandbox {
    name = "code";
    binary = "$HOME/.local/share/vscode/bin/code";
    args = [ "--no-sandbox" "--wait" "--password-store=gnome-libsecret" ];

    enableWayland = true;
    enableDbus = true;
    enableGpu = true;
    enableFonts = true;
    enableNixLd = true;
    enableSys = true;

    binds = [
      { src = "$HOME/.local/share/vscode"; dst = "$HOME/.local/share/vscode"; }
      { src = "$HOME/.config/Code"; dst = "$HOME/.config/Code"; }
      { src = "$HOME/.vscode"; dst = "$HOME/.vscode"; }
      { src = "$HOME/code"; dst = "$HOME/code"; }
    ];

    bindsTry = [
      { src = "$HOME/.local/share/direnv"; dst = "$HOME/.local/share/direnv"; }
    ];

    roBindsTry = [
      { src = "$HOME/.nix-profile"; dst = "$HOME/.nix-profile"; }
      { src = "$HOME/.gitconfig"; dst = "$HOME/.gitconfig"; }
      { src = "$HOME/.config/git"; dst = "$HOME/.config/git"; }
      { src = "$SSH_AUTH_SOCK"; dst = "$SSH_AUTH_SOCK"; }
      { src = "$XDG_RUNTIME_DIR/keyring"; dst = "$XDG_RUNTIME_DIR/keyring"; }
    ];

    env = {
      XDG_RUNTIME_DIR = "$XDG_RUNTIME_DIR";
      DBUS_SESSION_BUS_ADDRESS = "unix:path=$XDG_RUNTIME_DIR/bus";
      WAYLAND_DISPLAY = "$WAYLAND_DISPLAY";
      XDG_SESSION_TYPE = "wayland";
      SSH_AUTH_SOCK = "$SSH_AUTH_SOCK";
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
      PATH = "$HOME/.nix-profile/bin:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:${pkgs.git}/bin:${pkgs.protobuf}/bin:${pkgs.just}/bin:${rustToolchain}/bin:${pkgs.llvmPackages.lld}/bin";
      RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
      NIX_LD = "/run/current-system/sw/share/nix-ld/lib/ld.so";
      NIX_LD_LIBRARY_PATH = "/run/current-system/sw/share/nix-ld/lib";
    };
  };
in
{
  home.file = {
    ".local/bin/code" = {
      executable = true;
      source = "${vscodeSandboxed}/bin/code";
    };
    ".local/bin/code-update" = {
      executable = true;
      source = "${vscodeUpdate}/bin/code-update";
    };
    # Ensure directories exist
    ".config/Code/.keep".text = "";
    ".vscode/.keep".text = "";
  };
}
