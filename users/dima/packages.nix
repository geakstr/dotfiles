{ pkgs, ... }:

{
  home.packages = with pkgs; [
    wlr-randr swayidle wl-clipboard mako grim slurp
    iw usbutils brightnessctl pulsemixer libnotify
    nerd-fonts.caskaydia-cove inter (pkgs.callPackage ../../packages/etbook.nix {})
    fd ripgrep eza btop jq shellcheck glow tz fastfetch zip unzip
    rustc rustfmt cargo clippy
    gcc gnumake tree-sitter pkg-config nixfmt-rfc-style cloc rust-script inetutils asciinema
    bun nodejs
    ffmpeg
  ];

  home.sessionPath = [ "$HOME/.local/bin" ];

  home.sessionVariables = {
    RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
    TZ_LIST = "UTC;Europe/Moscow,Moscow;Europe/Astrakhan,Astrakhan;Asia/Omsk,Omsk;America/Los_Angeles,SF;Asia/Makassar,Bali";
  };
}
