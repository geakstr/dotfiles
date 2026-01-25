{ pkgs, lib, ... }:

let
  sandbox = import ./lib.nix { inherit pkgs lib; };

  syncthingSandboxed = sandbox.mkSandbox {
    name = "syncthing";
    binary = "${pkgs.syncthing}/bin/syncthing";
    args = [ "serve" "--no-browser" "--no-restart" ];
    enableNetwork = true;

    binds = [
      { src = "$HOME/.local/state/syncthing"; dst = "$HOME/.local/state/syncthing"; }
      { src = "$HOME/sync"; dst = "$HOME/sync"; }
      { src = "$HOME/code"; dst = "$HOME/code"; }
      { src = "$HOME/dotfiles"; dst = "$HOME/dotfiles"; }
    ];

    env = {
      HOME = "$HOME";
      XDG_STATE_HOME = "$HOME/.local/state";
    };
  };
in
{
  systemd.user.services.syncthing = {
    Unit = {
      Description = "Syncthing (Sandboxed)";
      After = [ "network.target" ];
    };
    Service = {
      ExecStart = "${syncthingSandboxed}/bin/syncthing";
      Restart = "on-failure";
      SuccessExitStatus = [ 3 4 ];
      RestartForceExitStatus = [ 3 4 ];
    };
    Install.WantedBy = [ "default.target" ];
  };

  home.file.".local/state/syncthing/.keep".text = "";
}
