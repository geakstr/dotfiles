{ pkgs, lib, claude-code, serena, ... }:

let
  sandbox = import ./lib.nix { inherit pkgs lib; };

  rustToolchain = pkgs.rust-bin.nightly.latest.default.override {
    extensions = [ "rust-src" "rust-analyzer" "clippy" "rustfmt" "llvm-tools-preview" ];
    targets = [ "wasm32-unknown-unknown" ];
  };

  serenaPkg = serena.packages.${pkgs.stdenv.hostPlatform.system}.serena;
  claudeBinary = "${claude-code.packages.${pkgs.stdenv.hostPlatform.system}.claude-code}/bin/claude";

  claudeSandboxed = sandbox.mkSandbox {
    name = "claude";
    binary = claudeBinary;
    args = [ "--dangerously-skip-permissions" ];

    enableTerminal = true;
    enableNixLd = true;
    enableAudio = true;

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

    bindsTry = [

      { src = "/run/user/$(id -u)/tmux-$(id -u)"; dst = "/run/user/$(id -u)/tmux-$(id -u)"; }
    ];

    env = {
      TERM = "$TERM";
      COLORTERM = "$COLORTERM";
      SSH_AUTH_SOCK = "$SSH_AUTH_SOCK";
      TMUX = "$TMUX";
      TMUX_PANE = "$TMUX_PANE";
      XDG_RUNTIME_DIR = "/run/user/$(id -u)";
      PATH = "${rustToolchain}/bin:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:${pkgs.protobuf}/bin:${pkgs.just}/bin:${pkgs.llvmPackages.lld}/bin:${serenaPkg}/bin:${pkgs.tmux}/bin:${pkgs.sqlite}/bin";
      NIX_LD = "/run/current-system/sw/share/nix-ld/lib/ld.so";
      NIX_LD_LIBRARY_PATH = "/run/current-system/sw/share/nix-ld/lib";
      CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
      DISABLE_AUTOUPDATER = "1";

    };

    preExec = ''
      mkdir -p /tmp/claude
      [ -n "$TMUX" ] && ${pkgs.tmux}/bin/tmux rename-window claude
    '';
    postExec = ''[ -n "$TMUX" ] && ${pkgs.tmux}/bin/tmux set-option -w automatic-rename on'';
  };
in
{
  home.file.".local/bin/claude" = {
    executable = true;
    source = "${claudeSandboxed}/bin/claude";
  };

  home.file.".local/bin/claude-admin" = {
    executable = true;
    source = toString (pkgs.writeShellScript "claude-admin" ''
      export DISABLE_AUTOUPDATER=1
      export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1
      [ -n "$TMUX" ] && ${pkgs.tmux}/bin/tmux rename-window claude
      cleanup() { [ -n "$TMUX" ] && ${pkgs.tmux}/bin/tmux set-option -w automatic-rename on; }
      trap cleanup EXIT
      exec ${claudeBinary} --dangerously-skip-permissions "$@"
    '');
  };

  home.activation.createClaudeJson = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    [ -f "$HOME/.claude.json" ] || echo '{}' > "$HOME/.claude.json"
  '';
}
