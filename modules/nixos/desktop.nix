{ pkgs, ... }:

{
  programs.sway = {
    enable = true;
    extraOptions = [ "--unsupported-gpu" ];
  };
  programs.dconf.enable = true;

  fonts.fontconfig.enable = true;

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config = {
      common = {
        default = [ "gtk" "wlr" ];
        "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
      };
    };
  };

  security.polkit.enable = true;
}
