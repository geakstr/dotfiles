{ config, pkgs, lib, ... }:

{
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    open = true;  # required for 50 series
    modesetting.enable = true;
    powerManagement.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      libva-vdpau-driver
      nvidia-vaapi-driver
    ];
  };

  boot.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
  boot.kernelParams = [ "nvidia-drm.modeset=1" ];

  environment.sessionVariables = {
    WLR_DRM_DEVICES = "/dev/dri/card1:/dev/dri/card2";
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
  };

  environment.systemPackages = with pkgs; [
    nvtopPackages.nvidia
    nvidia-vaapi-driver
  ];
}
