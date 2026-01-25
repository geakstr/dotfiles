{ pkgs, lib, ... }:

let
  sandbox = import ./lib.nix { inherit pkgs lib; };

  lazyworktreeSandboxed = sandbox.mkSandbox {
    name = "lazyworktree";
    binary = "${pkgs.lazyworktree}/bin/lazyworktree";
    enableTerminal = true;

    binds = [
      { src = "$HOME/code"; dst = "$HOME/code"; }
      { src = "$HOME/dotfiles"; dst = "$HOME/dotfiles"; }
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
      PATH = "/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin";
    };

    preExec = ''[ -n "$TMUX" ] && ${pkgs.tmux}/bin/tmux rename-window lazyworktree'';
    postExec = ''[ -n "$TMUX" ] && ${pkgs.tmux}/bin/tmux set-option -w automatic-rename on'';
  };
in
{
  home.file.".local/bin/lazyworktree" = {
    executable = true;
    source = "${lazyworktreeSandboxed}/bin/lazyworktree";
  };
}
