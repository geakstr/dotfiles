{ pkgs, lib, ... }:

let
  sandbox = import ./lib.nix { inherit pkgs lib; };

  yaziSandboxed = sandbox.mkSandbox {
    name = "yazi";
    binary = "${pkgs.yazi}/bin/yazi";
    enableTerminal = true;
    enableFonts = true;
    enableWayland = true;

    binds = [
      { src = "$HOME"; dst = "$HOME"; }
    ];

    env = {
      TERM = "$TERM";
      COLORTERM = "$COLORTERM";
      SHELL = "/bin/sh";
      EDITOR = "nvim";
      XDG_RUNTIME_DIR = "$XDG_RUNTIME_DIR";
      WAYLAND_DISPLAY = "$WAYLAND_DISPLAY";
      PATH = "/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin";
    };

    preExec = ''[ -n "$TMUX" ] && ${pkgs.tmux}/bin/tmux rename-window yazi'';
    postExec = ''[ -n "$TMUX" ] && ${pkgs.tmux}/bin/tmux set-option -w automatic-rename on'';
  };
in
{
  home.file.".local/bin/yazi" = {
    executable = true;
    source = "${yaziSandboxed}/bin/yazi";
  };
}
