{ ... }:

{
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  networking = {
    hostName = "nixos";
    wireless.enable = false;
    networkmanager = {
      enable = true;
      ensureProfiles = {
        profiles = {
          "USB-Ethernet" = {
            connection = {
              id = "USB-Ethernet";
              type = "ethernet";
              interface-name = "enp198s0f4u1u4";
            };
            ipv4 = {
              method = "auto";
              route-metric = "100";
            };
            ipv6.method = "auto";
          };
        };
      };
    };
  };
}
