{ pkgs, ... }:

{
  imports = [
    ./aerc.nix
    ./firefox.nix
    ./vscode.nix
    ./claude-code.nix
    ./lazygit.nix
    ./lazyworktree.nix
    ./syncthing.nix
    ./yazi.nix
  ];
}
