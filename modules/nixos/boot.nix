{ config, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [ "uinput" ];
  boot.kernelParams = [ "amdgpu.dcdebugmask=0x10" ];
  boot.initrd.luks.devices."luks-cfffc0b1-1359-4158-b88c-53d4ebbc5a54".device = "/dev/disk/by-uuid/cfffc0b1-1359-4158-b88c-53d4ebbc5a54";
}
