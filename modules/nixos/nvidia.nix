{ config, pkgs, lib, ... }:

{
  options.hardware.nvidia-egpu.enable = lib.mkEnableOption "NVIDIA eGPU support";

  config = lib.mkIf config.hardware.nvidia-egpu.enable {
    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      open = true; # required for 50 series
      modesetting.enable = true;
      powerManagement.enable = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        # NVIDIA eGPU
        libva-vdpau-driver
        nvidia-vaapi-driver
      ];
    };

    boot.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
    boot.kernelParams = [
      "nvidia-drm.modeset=1"
      "nvidia-drm.fbdev=1"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      "nvidia.NVreg_OpenRmEnableUnsupportedGpus=1"
    ];

    environment.sessionVariables = {
      WLR_NO_HARDWARE_CURSORS = "1";
      NIXOS_OZONE_WL = "1";
    };

    environment.systemPackages = with pkgs; [
      nvtopPackages.nvidia
      nvidia-vaapi-driver
    ];
  };
}
