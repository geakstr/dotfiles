{ pkgs, lib, ... }:

let
  sandbox = import ./lib.nix { inherit pkgs lib; };

  nordPaperTheme = pkgs.callPackage ../../../packages/nord-paper-theme/firefox { };

  tridactylNativeManifest = pkgs.writeText "tridactyl.json" (builtins.toJSON {
    name = "tridactyl";
    description = "Tridactyl native host";
    path = "${pkgs.tridactyl-native}/bin/native_main";
    type = "stdio";
    allowed_extensions = [ "tridactyl.vim@cmcaine.co.uk" ];
  });

  fxAutoconfig = pkgs.fetchFromGitHub {
    owner = "MrOtherGuy";
    repo = "fx-autoconfig";
    rev = "76232083171a8d609bf0258549d843b0536685e1";
    sha256 = "sha256-xiCikg8c855w+PCy7Wmc3kPwIHr80pMkkK7mFQbPCs4=";
  };

  firefoxPolicies = {
    DisplayBookmarksToolbar = "never";
    ExtensionSettings = {
      "uBlock0@raymondhill.net" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        installation_mode = "force_installed";
      };
      "{3c078156-979c-498b-8990-85f7987dd929}" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/sidebery/latest.xpi";
        installation_mode = "force_installed";
      };
      "search@kagi.com" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/kagi-search-for-firefox/latest.xpi";
        installation_mode = "force_installed";
      };
      "tridactyl.vim@cmcaine.co.uk" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/tridactyl-vim/latest.xpi";
        installation_mode = "force_installed";
      };
      "jid0-adyhmvsP91nUO8pRv0Mn2VKeB84@jetpack" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/raindropio/latest.xpi";
        installation_mode = "force_installed";
      };
      "nord-paper-theme@dotfiles" = {
        installation_mode = "blocked";
      };
      "nordpaper-theme@dotfiles" = {
        install_url = "file://${nordPaperTheme}/nord-paper-theme.xpi";
        installation_mode = "force_installed";
      };
      "team@readwise.io" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/readwise-highlighter/latest.xpi";
        installation_mode = "force_installed";
      };
      "78272b6fa58f4a1abaac99321d503a20@proton.me" = {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/proton-pass/latest.xpi";
        installation_mode = "force_installed";
      };
    };
  };

  firefoxWithConfig = pkgs.firefox.override {
    extraPrefsFiles = [ "${fxAutoconfig}/program/config.js" ];
    extraPolicies = firefoxPolicies;
  };

  firefoxSandboxed = sandbox.mkSandbox {
    name = "firefox";
    binary = "${firefoxWithConfig}/bin/firefox";

    enableWayland = true;
    enableAudio = true;
    enableDbus = true;
    enableGpu = true;
    enableFonts = true;
    enableSys = true;

    binds = [
      { src = "$HOME/.mozilla"; dst = "$HOME/.mozilla"; }
      { src = "$HOME/Downloads"; dst = "$HOME/Downloads"; }
      { src = "$HOME/.cache/aerc-open"; dst = "$HOME/.cache/aerc-open"; }  # For opening aerc attachments
    ];

    # Allow fontconfig to use/update its cache (non-sensitive, improves startup)
    bindsTry = [
      { src = "$HOME/.cache/fontconfig"; dst = "$HOME/.cache/fontconfig"; }
    ];

    roBinds = [
      { src = "$HOME/.mozilla/firefox/default/chrome"; dst = "$HOME/.mozilla/firefox/default/chrome"; }
      { src = "$HOME/.config/tridactyl"; dst = "$HOME/.config/tridactyl"; }
    ];

    env = {
      PATH = "/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin";
      XDG_RUNTIME_DIR = "$XDG_RUNTIME_DIR";
      XDG_CONFIG_HOME = "$HOME/.config";
      XDG_CACHE_HOME = "$HOME/.cache";
      DBUS_SESSION_BUS_ADDRESS = "unix:path=$XDG_RUNTIME_DIR/bus";
      WAYLAND_DISPLAY = "$WAYLAND_DISPLAY";
      XDG_SESSION_TYPE = "wayland";
      MOZ_ENABLE_WAYLAND = "1";
      TERM = "xterm-256color";
    };
  };
in
{
  programs.firefox = {
    enable = true;
    package = firefoxWithConfig;
    profiles.default = {
      extraConfig = builtins.readFile ../../../config/firefox/user.js;
    };
  };

  home.file = {
    ".mozilla/firefox/default/chrome/utils" = {
      source = "${fxAutoconfig}/profile/chrome/utils";
      recursive = true;
      force = true;
    };
    ".mozilla/firefox/default/chrome/JS/move-extensions-button.uc.js".source =
      ../../../config/firefox/chrome/JS/move-extensions-button.uc.js;
    ".mozilla/firefox/default/chrome/userChrome.css".source =
      ../../../config/firefox/chrome/userChrome.css;
    ".config/tridactyl/tridactylrc".source =
      ../../../config/tridactyl/tridactylrc;
    ".mozilla/native-messaging-hosts/tridactyl.json".source =
      tridactylNativeManifest;
    ".local/bin/firefox" = {
      executable = true;
      source = "${firefoxSandboxed}/bin/firefox";
    };
  };
}
