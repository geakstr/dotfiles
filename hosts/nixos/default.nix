{
  config,
  pkgs,
  personal,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/boot.nix
    ../../modules/nixos/locale.nix
    ../../modules/nixos/networking.nix
    ../../modules/nixos/desktop.nix
    ../../modules/nixos/audio.nix
    ../../modules/nixos/bluetooth.nix
    ../../modules/nixos/nix-ld.nix
    ../../modules/nixos/input-handler.nix
    ../../modules/nixos/ollama.nix
    ../../modules/nixos/steam.nix
    ../../modules/nixos/android.nix
    ../../modules/nixos/nvidia.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  hardware.nvidia-egpu.enable = true;
  hardware.uinput.enable = true;
  hardware.i2c.enable = true;

  users.groups.uinput = { };
  users.users.dima = {
    isNormalUser = true;
    description = personal.userDescription;
    extraGroups = [
      "networkmanager"
      "wheel"
      "input"
      "uinput"
      "i2c"
      "adbusers"
      "video"
    ];
    packages = with pkgs; [ ];
  };
  services.udev.extraRules = ''
    KERNEL=="uinput", GROUP="uinput", MODE="0660"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{power/wakeup}="enabled"
  '';

  environment.systemPackages = with pkgs; [
    wget
    adwaita-icon-theme
    acpi
    ethtool
    glib
    magic-wormhole
    unzip
    rust-analyzer
    libinput
    ddcutil
    mosh
    opensnitch-ui
    pciutils
  ];

  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    GDK_SCALE = "2";
    XCURSOR_SIZE = "20";
    XCURSOR_THEME = "Adwaita";
  };

  services.opensnitch.enable = true;

  services.tailscale.enable = true;
  services.openssh = {
    enable = true;
    openFirewall = false; # Don't open SSH on public interfaces
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Allow SSH and mosh only via Tailscale
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchDocked = "ignore";
    IdleAction = "suspend";
    IdleActionSec = "3h";
  };

  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_BOOST_ON_BAT = 0;
      STOP_CHARGE_THRESH_BAT0 = 80;
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_BOOST_ON_AC = 1;
    };
  };

  services.xserver.enable = false;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;

  system.stateVersion = "25.11";
}
