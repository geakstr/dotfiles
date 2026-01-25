{ pkgs, ... }:

{
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    glib
    nss
    nspr
    atk
    at-spi2-atk
    at-spi2-core
    cups
    dbus
    libdrm
    gtk3
    pango
    cairo
    mesa
    expat
    alsa-lib
    libxkbcommon
    libGL
    libsecret
    gnome-keyring
    xorg.libX11
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXrandr
    xorg.libxcb
    xorg.libxshmfence
    xorg.libXcursor
    xorg.libXi
    xorg.libXrender
    xorg.libXtst
    xorg.libXScrnSaver
    fontconfig
    freetype
    zlib
    icu
    openssl
    curl
    systemd
    libgbm
  ];
}
