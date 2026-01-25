{ pkgs, lib, ... }:

let
  sandbox = import ./lib.nix { inherit pkgs lib; };

  lazygitSandboxed = sandbox.mkSandbox {
    name = "lazygit";
    binary = "${pkgs.lazygit}/bin/lazygit";
    enableTerminal = true;
    enableWayland = true;  # For clipboard access

    binds = [
      { src = "$HOME/code"; dst = "$HOME/code"; }
      { src = "$HOME/dotfiles"; dst = "$HOME/dotfiles"; }
    ];

    bindsTry = [
      { src = "$HOME/.local/state/lazygit"; dst = "$HOME/.local/state/lazygit"; }
    ];

    roBindsTry = [
      { src = "$HOME/.gitconfig"; dst = "$HOME/.gitconfig"; }
      { src = "$HOME/.config/git"; dst = "$HOME/.config/git"; }
      { src = "$HOME/.ssh"; dst = "$HOME/.ssh"; }
      { src = "$SSH_AUTH_SOCK"; dst = "$SSH_AUTH_SOCK"; }
    ];

    env = {
      TERM = "$TERM";
      COLORTERM = "$COLORTERM";
      SSH_AUTH_SOCK = "$SSH_AUTH_SOCK";
      WAYLAND_DISPLAY = "$WAYLAND_DISPLAY";
      XDG_RUNTIME_DIR = "$XDG_RUNTIME_DIR";
      PATH = "${pkgs.wl-clipboard}/bin:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin";
    };

    preExec = ''[ -n "$TMUX" ] && ${pkgs.tmux}/bin/tmux rename-window lazygit'';
    postExec = ''[ -n "$TMUX" ] && ${pkgs.tmux}/bin/tmux set-option -w automatic-rename on'';
  };
in
{
  home.file.".local/bin/lazygit" = {
    executable = true;
    source = "${lazygitSandboxed}/bin/lazygit";
  };

  home.file.".local/state/lazygit/.keep".text = "";
}
