{ config, pkgs, lib, ... }:

{
  # DNS over HTTPS via dnscrypt-proxy → NextDNS
  services.dnscrypt-proxy = {
    enable = true;
    upstreamDefaults = false;
    settings = {
      listen_addresses = [ "127.0.0.1:53" "[::1]:53" ];
      server_names = [ "nextdns" ];
      doh_servers = true;
      ipv6_servers = true;
      require_dnssec = true;
      require_nolog = true;
      require_nofilter = false;
      bootstrap_resolvers = [ "45.90.28.0:53" "45.90.30.0:53" ];
      sources = { };
    };
  };

  # Use mutable config so activation script can inject the NextDNS stamp
  systemd.services.dnscrypt-proxy.serviceConfig.ExecStart = lib.mkForce
    "${pkgs.dnscrypt-proxy}/bin/dnscrypt-proxy -config /etc/dnscrypt-proxy/dnscrypt-proxy.toml";

  # NextDNS ID lives outside the repo: echo "your-id" > /etc/nixos/nextdns-id
  system.activationScripts.dnscrypt-nextdns.text = ''
    mkdir -p /etc/dnscrypt-proxy
    cp ${config.services.dnscrypt-proxy.configFile} /etc/dnscrypt-proxy/dnscrypt-proxy.toml
    chmod 644 /etc/dnscrypt-proxy/dnscrypt-proxy.toml
    if [ -f /etc/nixos/nextdns-id ]; then
      id=$(cat /etc/nixos/nextdns-id | tr -d '[:space:]')
      stamp=$(${pkgs.python3}/bin/python3 -c "
import base64, struct, sys
buf = bytearray([2])
buf.extend(struct.pack('<Q', 1))
buf.append(0)
buf.append(0)
h = b'dns.nextdns.io'
buf.append(len(h))
buf.extend(h)
p = ('/' + sys.argv[1]).encode()
buf.append(len(p))
buf.extend(p)
print('sdns://' + base64.urlsafe_b64encode(bytes(buf)).rstrip(b'=').decode())
" "$id")
      cat >> /etc/dnscrypt-proxy/dnscrypt-proxy.toml <<EOF

[static]
[static.'nextdns']
stamp = '$stamp'
EOF
    fi
  '';

  services.resolved.enable = false;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  networking = {
    hostName = "nixos";
    nameservers = [ "127.0.0.1" "::1" ];
    networkmanager = {
      enable = true;
      dns = "none";
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
