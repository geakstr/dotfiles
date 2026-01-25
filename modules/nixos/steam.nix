{ pkgs, ... }:

let
  steamWrapper = pkgs.writeShellScriptBin "steam" ''
    export GDK_SCALE=1
    export STEAM_FORCE_DESKTOPUI_SCALING=1.0
    exec ${pkgs.steam}/bin/steam "$@"
  '';
in
{
  programs.steam.enable = true;
  environment.systemPackages = [ steamWrapper ];
  hardware.graphics.enable32Bit = true;
  programs.gamemode.enable = true;
}
