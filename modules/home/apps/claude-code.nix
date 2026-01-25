{ pkgs, lib, claude-code, ... }:

let
  sandbox = import ./lib.nix { inherit pkgs lib; };

  rustToolchain = pkgs.rust-bin.nightly.latest.default.override {
    extensions = [ "rust-src" "clippy" "rustfmt" "llvm-tools-preview" ];
    targets = [ "wasm32-unknown-unknown" ];
  };

  claudeBinary = "${claude-code.packages.${pkgs.stdenv.hostPlatform.system}.claude-code}/bin/claude";

  claudeSandboxed = sandbox.mkSandbox {
    name = "claude";
    binary = claudeBinary;
    args = [ "--dangerously-skip-permissions" ];

    enableTerminal = true;
    enableNixLd = true;

    binds = [
      { src = "$HOME/.claude"; dst = "$HOME/.claude"; }
      { src = "$HOME/.claude.json"; dst = "$HOME/.claude.json"; }
      { src = "$HOME/code"; dst = "$HOME/code"; }
      { src = "$HOME/dotfiles"; dst = "$HOME/dotfiles"; }
      { src = "/tmp/claude"; dst = "/tmp/claude"; }
    ];

    roBindsTry = [
      { src = "$HOME/.gitconfig"; dst = "$HOME/.gitconfig"; }
      { src = "$HOME/.config/git"; dst = "$HOME/.config/git"; }
      { src = "$SSH_AUTH_SOCK"; dst = "$SSH_AUTH_SOCK"; }
    ];

    env = {
      TERM = "$TERM";
      COLORTERM = "$COLORTERM";
      SSH_AUTH_SOCK = "$SSH_AUTH_SOCK";
      PATH = "/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:${pkgs.protobuf}/bin:${pkgs.just}/bin:${rustToolchain}/bin:${pkgs.llvmPackages.lld}/bin";
      NIX_LD = "/run/current-system/sw/share/nix-ld/lib/ld.so";
      NIX_LD_LIBRARY_PATH = "/run/current-system/sw/share/nix-ld/lib";
    };

    preExec = ''[ -n "$TMUX" ] && ${pkgs.tmux}/bin/tmux rename-window claude'';
    postExec = ''[ -n "$TMUX" ] && ${pkgs.tmux}/bin/tmux set-option -w automatic-rename on'';
  };
in
{
  home.file.".local/bin/claude" = {
    executable = true;
    source = "${claudeSandboxed}/bin/claude";
  };
}
