{ pkgs, claude-code, personal, ... }:

{
  imports = [
    # Module imports
    ../../modules/home/sway
    ../../modules/home/apps
    ../../modules/home/shell
    ../../modules/home/tmux
    ../../modules/home/neovim
    ../../modules/home/services.nix

    # User config split into concerns
    ./packages.nix
    ./services.nix
    ./programs.nix
    ./terminal.nix
    ./scripts.nix
  ];

  home.stateVersion = "25.11";

  dconf.enable = true;

  gtk = {
    enable = true;
    theme.name = "Adwaita-dark";
    font = {
      name = "Inter";
      size = 11;
    };
  };
}
