{ ... }:

{
  users.groups.adbusers = {};
  services.udev.extraRules = ''
    # Google/Android
    SUBSYSTEM=="usb", ATTR{idVendor}=="18d1", MODE="0666", GROUP="adbusers"
    # MediaTek (Mudita Kompakt)
    SUBSYSTEM=="usb", ATTR{idVendor}=="0e8d", MODE="0666", GROUP="adbusers"
  '';
}
