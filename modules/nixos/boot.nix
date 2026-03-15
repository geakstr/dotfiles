{ config, pkgs, lib, ... }:

{
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };
  environment.systemPackages = [ pkgs.sbctl ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelModules = [ "uinput" ];
  boot.kernelParams = [ ];
  boot.initrd.luks.devices."luks-cfffc0b1-1359-4158-b88c-53d4ebbc5a54".device = "/dev/disk/by-uuid/cfffc0b1-1359-4158-b88c-53d4ebbc5a54";
}
