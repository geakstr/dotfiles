{ secrets, ... }:

{
  services.resolved = {
    enable = true;
    dnsovertls = "true";
    domains = [ "~." ];
    extraConfig = ''
      DNS=45.90.28.0#${secrets.nextdnsId}.dns.nextdns.io
      DNS=2a07:a8c0::#${secrets.nextdnsId}.dns.nextdns.io
      DNS=45.90.30.0#${secrets.nextdnsId}.dns.nextdns.io
      DNS=2a07:a8c1::#${secrets.nextdnsId}.dns.nextdns.io
    '';
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  networking = {
    hostName = "nixos";
    wireless.enable = false;
    networkmanager = {
      enable = true;
      dns = "systemd-resolved";
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
